/**
 * Natural Language → SOQL → Results engine.
 *
 * Translates a plain-language question into a SOQL SELECT query by calling the
 * NLQuery_SOQL_Expert Prompt Template via the Connect REST API
 * (POST /services/data/v66.0/actions/custom/generatePromptResponse/{template}).
 * This sidesteps the ConnectApi.EinsteinLLM compile dependency and works on any
 * org where the template is deployed and Einstein Generative AI is active.
 *
 * Test seam: set NLQueryController.soqlOverride before calling runNLQuery() to
 * bypass the HTTP callout entirely.
 */
public with sharing class NLQueryController {

    @TestVisible
    static String soqlOverride = null;

    private static final List<String> BANNED_KEYWORDS = new List<String>{
        'DELETE', 'INSERT', 'UPDATE', 'UPSERT', 'MERGE', 'UNDELETE'
    };

    private static final Integer DEFAULT_LIMIT = 10;
    private static final Integer MAX_LIMIT      = 50;
    private static final String  PROMPT_TEMPLATE = 'nlquery_soql_v2';

    // ── Public result type ────────────────────────────────────────────────────

    /**
     * Return type for runNLQuery. All fields are AuraEnabled for LWC consumption.
     */
    public class QueryResult {
        @AuraEnabled public String       soql;
        @AuraEnabled public List<String> columns;
        @AuraEnabled public String       recordsJson;
        @AuraEnabled public Integer      recordCount;
        @AuraEnabled public String       error;
    }

    // ── AuraEnabled entry point (LWC) ─────────────────────────────────────────

    /**
     * Translates nlQuery to SOQL, executes it, and returns a flattened result set.
     *
     * @param nlQuery  Natural language question from the user.
     * @return         QueryResult with records or an error message.
     */
    @AuraEnabled
    public static QueryResult runNLQuery(String nlQuery) {
        QueryResult result = new QueryResult();
        try {
            String soql = (Test.isRunningTest() && soqlOverride != null)
                ? soqlOverride
                : generateSOQL(nlQuery);

            result.soql = soql;

            String upperSoql = soql.toUpperCase().trim();

            if (!upperSoql.startsWith('SELECT')) {
                result.error = 'The model did not return a SELECT statement. Please rephrase your question.';
                return result;
            }

            Pattern bannedPat = Pattern.compile(
                '(?i)\\b(' + String.join(BANNED_KEYWORDS, '|') + ')\\b'
            );
            if (bannedPat.matcher(upperSoql).find()) {
                result.error = 'Prohibited DML keyword detected. Only SELECT queries are allowed.';
                return result;
            }

            soql = enforceLimitClause(soql, upperSoql);
            soql = normalizeWithUserMode(soql);
            soql = fixCalendarFunctions(soql);
            result.soql = soql;

            List<SObject> records = Database.query(soql);
            result.recordCount = records.size();

            if (records.isEmpty()) {
                result.recordsJson = '[]';
                result.columns     = new List<String>();
                return result;
            }

            result = flattenRecords(records, result);

        } catch (Exception e) {
            result.error = e.getMessage();
        }
        return result;
    }

    // ── LLM layer ─────────────────────────────────────────────────────────────

    private static String generateSOQL(String nlQuery) {
        String endpoint = Url.getOrgDomainUrl().toExternalForm()
            + '/services/data/v66.0/actions/custom/generatePromptResponse/'
            + PROMPT_TEMPLATE;

        Map<String, Object> payload = new Map<String, Object>{
            'inputs' => new List<Object>{
                new Map<String, Object>{ 'Input:userQuestion' => nlQuery }
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getApiSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        HttpResponse resp = new Http().send(req);

        if (resp.getStatusCode() != 200) {
            throw new CalloutException(
                'Prompt Template callout failed (' + resp.getStatusCode() + '): '
                + resp.getBody()
            );
        }

        List<Object> results = (List<Object>) JSON.deserializeUntyped(resp.getBody());
        Map<String, Object> first = (Map<String, Object>) results[0];
        Map<String, Object> outputValues = (Map<String, Object>) first.get('outputValues');
        String rawSoql = (String) outputValues.get('promptResponse');

        if (String.isBlank(rawSoql)) {
            throw new CalloutException('Prompt Template returned an empty response.');
        }

        return rawSoql
            .replaceAll('(?i)```sql',  '')
            .replaceAll('(?i)```soql', '')
            .replaceAll('```',         '')
            .trim();
    }

    // ── Session bridge ────────────────────────────────────────────────────────

    // @AuraEnabled context yields a UI-only session; the VF page bridge
    // produces an API-scoped session that Connect REST accepts.
    private static String getApiSessionId() {
        if (Test.isRunningTest()) { return UserInfo.getSessionId(); }
        return Page.SessionIdProvider.getContent().toString().trim();
    }

    // ── Safety helpers ────────────────────────────────────────────────────────

    // Moves WITH USER_MODE to its correct position: before GROUP BY, ORDER BY, or LIMIT
    // (whichever comes first). Placing it after GROUP BY causes "unexpected token" errors.
    private static String normalizeWithUserMode(String soql) {
        String normalized = soql.replaceAll('(?i)\\s+WITH\\s+USER_MODE', '').trim();
        Pattern groupPat = Pattern.compile('(?i)\\bGROUP\\s+BY\\b');
        Pattern orderPat = Pattern.compile('(?i)\\bORDER\\s+BY\\b');
        Pattern limitPat = Pattern.compile('(?i)\\bLIMIT\\b');
        Matcher gm = groupPat.matcher(normalized);
        Matcher om = orderPat.matcher(normalized);
        Matcher lm = limitPat.matcher(normalized);
        if (gm.find()) {
            return normalized.substring(0, gm.start()).trim()
                + ' WITH USER_MODE ' + normalized.substring(gm.start());
        }
        if (om.find()) {
            return normalized.substring(0, om.start()).trim()
                + ' WITH USER_MODE ' + normalized.substring(om.start());
        }
        if (lm.find()) {
            return normalized.substring(0, lm.start()).trim()
                + ' WITH USER_MODE ' + normalized.substring(lm.start());
        }
        return normalized + ' WITH USER_MODE';
    }

    // Strips quotes that LLMs sometimes wrap around integer arguments to CALENDAR_* functions.
    // e.g. CALENDAR_YEAR(field) = '2026'  →  CALENDAR_YEAR(field) = 2026
    private static String fixCalendarFunctions(String soql) {
        return soql.replaceAll(
            '(?i)(CALENDAR_(?:YEAR|MONTH|DATE|FISCAL_YEAR|FISCAL_QUARTER)\\s*\\([^)]+\\)\\s*(?:[=!<>]{1,2})\\s*)\'(\\d+)\'',
            '$1$2'
        );
    }

    /**
     * Appends LIMIT DEFAULT_LIMIT when absent; clamps any existing LIMIT to MAX_LIMIT.
     */
    private static String enforceLimitClause(String soql, String upperSoql) {
        Pattern limitPat = Pattern.compile('(?i)\\bLIMIT\\s+(\\d+)');
        Matcher m = limitPat.matcher(soql);
        if (!m.find()) {
            return soql + ' LIMIT ' + DEFAULT_LIMIT;
        }
        Integer requestedLimit = Integer.valueOf(m.group(1));
        if (requestedLimit > MAX_LIMIT) {
            return soql.replaceAll('(?i)\\bLIMIT\\s+\\d+', 'LIMIT ' + MAX_LIMIT);
        }
        return soql;
    }

    // ── Data flattening ───────────────────────────────────────────────────────

    private static QueryResult flattenRecords(List<SObject> records, QueryResult result) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Set<String> columnSet = new Set<String>();
        Integer rowIdx = 0;

        for (SObject record : records) {
            Map<String, Object> populated = record.getPopulatedFieldsAsMap();
            Map<String, Object> flatRow   = new Map<String, Object>();
            flatRow.put('_idx', rowIdx++);

            for (String fieldName : populated.keySet()) {
                Object val = populated.get(fieldName);
                if (!(val instanceof SObject)) {
                    flatRow.put(fieldName, val);
                    columnSet.add(fieldName);
                }
            }
            rows.add(flatRow);
        }

        List<String> sortedCols = new List<String>(columnSet);
        sortedCols.sort();
        if (sortedCols.contains('Id')) {
            sortedCols.remove(sortedCols.indexOf('Id'));
            sortedCols.add(0, 'Id');
        }

        result.columns     = sortedCols;
        result.recordsJson = JSON.serialize(rows);
        return result;
    }
}