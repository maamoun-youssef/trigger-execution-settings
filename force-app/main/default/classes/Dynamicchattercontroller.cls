public with sharing class Dynamicchattercontroller {

    private static final String  CHAT_TEMPLATE  = 'dynamic_screen_chat_v1';
    private static final Integer MAX_TOOL_CALLS = 3;
    private static final Integer MAX_CONTEXT    = 30000;
    public  static final Integer MAX_ROWS       = 50;

    private static final Pattern QUERY_PATTERN = Pattern.compile('(?is)<<<\\s*QUERY\\s*>>>(.*?)<<<\\s*END\\s*>>>');
    private static final Pattern FIELD_PATTERN = Pattern.compile('^[A-Za-z0-9_]+(\\.[A-Za-z0-9_]+){0,3}$');

    public class ChatResponse {
        @AuraEnabled public String answer;
        @AuraEnabled public String error;
    }

    public class ChatException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getScreenConfig(String screenKey) {
        Map<String, Object> cfg = new Map<String, Object>();
        Screen_Chat_Context__mdt def = loadDef(screenKey, false);
        if (def != null) {
            cfg.put('heading',     def.MasterLabel);
            cfg.put('suggestions', parseJsonOrEmptyList(def.Suggested_Questions_Json__c));
        }
        return cfg;
    }

    @AuraEnabled
    public static ChatResponse askAboutScreen(String screenKey, String liveDataJson, String conversationHistory, String userQuestion) {
        ChatResponse resp = new ChatResponse();
        try {
            if (String.isBlank(userQuestion)) { resp.error = 'Please type a question.'; return resp; }
            if (String.isBlank(screenKey))    { resp.error = 'This screen is not configured yet.'; return resp; }
            Screen_Chat_Context__mdt def = loadDef(screenKey, true);
            Map<String, Object> live = safeMap(liveDataJson);
            Map<String, Object> queryContext = (Map<String, Object>) live.get('queryContext');
            live.remove('queryContext');
            String screenContextJson = buildScreenContext(def, live);
            String history = String.isBlank(conversationHistory) ? '' : conversationHistory;
            Callable provider = getProvider(def);
            List<Object> toolResults = new List<Object>();
            String output = callPromptTemplate(screenContextJson, history, userQuestion, '');
            for (Integer i = 0; i < MAX_TOOL_CALLS; i++) {
                Map<String, Object> request = extractToolRequest(output);
                if (request == null) break;
                toolResults.add(executeTool(request, queryContext, def, provider));
                output = callPromptTemplate(screenContextJson, history, userQuestion, JSON.serialize(toolResults));
            }
            if (extractToolRequest(output) != null) {
                output = callPromptTemplate(screenContextJson, history,
                    userQuestion + '\n\n(Answer now from the data already supplied. Do not request more data.)',
                    JSON.serialize(toolResults));
            }
            String answer = cleanAnswer(output);
            resp.answer = String.isNotBlank(answer)
                ? answer
                : 'I could not find an answer for that. Try rephrasing it, or tell me the product or supplier name you are looking for.';
        } catch (Exception e) {
            System.debug('askAboutScreen: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            resp.error = 'Something went wrong while reading this screen. Please try again.';
        }
        return resp;
    }

    private static Callable getProvider(Screen_Chat_Context__mdt def) {
        if (def == null || String.isBlank(def.Tool_Provider_Class__c)) return null;
        Type t = Type.forName(def.Tool_Provider_Class__c.trim());
        if (t == null) return null;
        Object inst = t.newInstance();
        return (inst instanceof Callable) ? (Callable) inst : null;
    }

    private static Map<String, Object> extractToolRequest(String modelOutput) {
        if (String.isBlank(modelOutput)) return null;
        String raw;
        Matcher m = QUERY_PATTERN.matcher(modelOutput);
        if (m.find()) {
            raw = m.group(1).trim();
        } else {
            String t = modelOutput.trim();
            if (t.startsWith('{') && t.endsWith('}') && t.containsIgnoreCase('"tool"')) raw = t;
        }
        if (String.isBlank(raw)) return null;
        raw = raw.replaceAll('(?i)```[a-z]*', '').trim();
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(raw);
        } catch (Exception e) {
            return null;
        }
    }

    private static Map<String, Object> executeTool(Map<String, Object> req, Map<String, Object> queryContext,
                                                   Screen_Chat_Context__mdt def, Callable provider) {
        Map<String, Object> wrapper = new Map<String, Object>{ 'request' => req };
        try {
            String tool = String.valueOf(req.get('tool')).toLowerCase();
            if (tool == 'db') {
                wrapper.put('result', runDb(req, def));
            } else if (provider != null) {
                wrapper.put('result', provider.call(tool, new Map<String, Object>{
                    'request'      => req,
                    'queryContext' => queryContext,
                    'def'          => def
                }));
            } else {
                wrapper.put('error', 'Unknown tool.');
            }
        } catch (Exception e) {
            wrapper.put('error', e.getMessage());
        }
        return wrapper;
    }

    private static Object runDb(Map<String, Object> req, Screen_Chat_Context__mdt def) {
        String obj = safeField((String) req.get('object'));
        if (String.isBlank(obj)) throw new ChatException('No object supplied.');
        if (!allowedObjects(def).contains(obj.toUpperCase())) {
            throw new ChatException('That data is not available from this screen.');
        }
        List<String> fields = safeFieldList(req.get('fields'));
        String cond = safeCondition((String) req.get('where'));
        Integer lim = intOf(req.get('limit'), 25);
        String q = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + obj;
        if (String.isNotBlank(cond)) q += ' WHERE ' + cond;
        q += ' WITH USER_MODE LIMIT ' + lim;
        List<SObject> rows = Database.query(q);
        return new Map<String, Object>{ 'found' => rows.size(), 'rows' => strip(rows) };
    }

    private static Set<String> allowedObjects(Screen_Chat_Context__mdt def) {
        Set<String> s = new Set<String>();
        if (def != null && String.isNotBlank(def.Allowed_Objects__c)) {
            for (String o : def.Allowed_Objects__c.split(',')) {
                if (String.isNotBlank(o)) s.add(o.trim().toUpperCase());
            }
        }
        return s;
    }

    public static String safeField(String f) {
        if (String.isBlank(f)) return '';
        String v = f.trim();
        if (!FIELD_PATTERN.matcher(v).matches()) throw new ChatException('Unsupported field: ' + v);
        return v;
    }

    public static List<String> safeFieldList(Object raw) {
        List<String> out = new List<String>{ 'Id' };
        if (raw instanceof List<Object>) {
            for (Object o : (List<Object>) raw) {
                String f = safeField(String.valueOf(o));
                if (String.isNotBlank(f) && !out.contains(f)) out.add(f);
            }
        }
        if (out.size() == 1) out.add('Name');
        return out;
    }

    public static String safeCondition(String c) {
        if (String.isBlank(c)) return '';
        String v = c.trim();
        String u = ' ' + v.toUpperCase() + ' ';
        for (String bad : new List<String>{ ';', '/*', '--', ' INSERT ', ' UPDATE ', ' DELETE ',
                                            ' UPSERT ', ' MERGE ', ' TRUNCATE ', ' SELECT ' }) {
            if (u.contains(bad)) throw new ChatException('Unsupported condition.');
        }
        if (v.length() > 800) throw new ChatException('Condition too long.');
        return v;
    }

    public static Integer intOf(Object o, Integer fallback) {
        try {
            Integer i = Integer.valueOf(String.valueOf(o));
            return (i == null || i <= 0 || i > MAX_ROWS) ? fallback : i;
        } catch (Exception e) { return fallback; }
    }

    public static Integer boundedInt(Object o, Integer fallback, Integer minVal, Integer maxVal) {
        try {
            Integer i = Integer.valueOf(String.valueOf(o));
            if (i == null || i < minVal) return fallback;
            return i > maxVal ? maxVal : i;
        } catch (Exception e) { return fallback; }
    }

    public static List<Object> strip(List<SObject> records) {
        List<Object> raw = (List<Object>) JSON.deserializeUntyped(JSON.serialize(records));
        List<Object> out = new List<Object>();
        for (Object o : raw) out.add(stripMap((Map<String, Object>) o));
        return out;
    }

    public static Map<String, Object> stripMap(Map<String, Object> m) {
        Map<String, Object> clean = new Map<String, Object>();
        for (String k : m.keySet()) {
            if (k == 'attributes') continue;
            Object v = m.get(k);
            clean.put(k, (v instanceof Map<String, Object>) ? stripMap((Map<String, Object>) v) : v);
        }
        return clean;
    }

    public static String resolveLookup(String objName, String field) {
        if (String.isBlank(field) || field.contains('.') || field.equalsIgnoreCase('Id')) return field;
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objName.toLowerCase());
        if (t == null) return field;
        Schema.SObjectField f = t.getDescribe().fields.getMap().get(field.toLowerCase());
        if (f == null) return field;
        Schema.DescribeFieldResult d = f.getDescribe();
        return (d.getType() == Schema.DisplayType.REFERENCE && d.getRelationshipName() != null)
            ? d.getRelationshipName() + '.Name'
            : d.getName();
    }

    public static List<String> describeFields(String objName, List<String> wanted) {
        List<String> out = new List<String>{ 'Id' };
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objName.toLowerCase());
        if (t == null) return out;
        Map<String, Schema.SObjectField> fm = t.getDescribe().fields.getMap();
        for (String w : wanted) {
            Schema.SObjectField f = fm.get(w.toLowerCase());
            if (f == null) continue;
            String resolved = resolveLookup(objName, f.getDescribe().getName());
            if (!out.contains(resolved)) out.add(resolved);
        }
        return out;
    }

    public static List<Object> safeList(String jsonStr) {
        if (String.isBlank(jsonStr)) return new List<Object>();
        try {
            Object o = JSON.deserializeUntyped(jsonStr);
            return (o instanceof List<Object>) ? (List<Object>) o : new List<Object>();
        } catch (Exception e) { return new List<Object>(); }
    }

    public static String str(Map<String, Object> m, String key) {
        Object v = (m == null) ? null : m.get(key);
        return v == null ? '' : String.valueOf(v);
    }

    private static String callPromptTemplate(String screenContext, String history, String question, String results) {
        Map<String, Object> inputMap = new Map<String, Object>{
            'Input:screenContext'       => screenContext,
            'Input:conversationHistory' => history,
            'Input:userQuestion'        => question,
            'Input:databaseResults'     => String.isBlank(results) ? '' : results
        };
        Map<String, Object> payload = new Map<String, Object>{ 'inputs' => new List<Object>{ inputMap } };
        String endpoint = Url.getOrgDomainUrl().toExternalForm()
            + '/services/data/v66.0/actions/custom/generatePromptResponse/' + CHAT_TEMPLATE;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getApiSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        req.setTimeout(60000);
        HttpResponse httpResp = new Http().send(req);
        if (httpResp.getStatusCode() != 200) {
            throw new CalloutException('Prompt call failed (' + httpResp.getStatusCode() + ')');
        }
        List<Object> results2 = (List<Object>) JSON.deserializeUntyped(httpResp.getBody());
        if (results2.isEmpty()) return '';
        Map<String, Object> first = (Map<String, Object>) results2[0];
        Map<String, Object> outputValues = (Map<String, Object>) first.get('outputValues');
        return outputValues != null ? (String) outputValues.get('promptResponse') : '';
    }

    private static String cleanAnswer(String s) {
        if (String.isBlank(s)) return '';
        String a = QUERY_PATTERN.matcher(s).replaceAll('');
        a = a.replaceAll('(?i)```[a-z]*', '');
        a = a.replaceAll('(?i)\\bthanks? you? for your prompt\\.?', '');
        a = a.replaceAll('(?i)\\bthank you for your prompt\\.?', '');
        a = a.replaceAll('(?i)\\b(the )?SCREEN CONTEXT\\b', 'this screen');
        a = a.replaceAll('(?i)\\b(the )?(DATABASE|TOOL) RESULTS\\b', 'the data');
        a = a.replaceAll('(?i)\\bsample ?rows\\b', 'the visible rows');
        List<String> keep = new List<String>();
        for (String line : a.split('\n')) {
            String u = line.toUpperCase();
            if (u.contains('SOQL') || u.contains('<<<') || u.contains('"TOOL"')) continue;
            keep.add(line);
        }
        return String.join(keep, '\n').replaceAll('\n{3,}', '\n\n').trim();
    }

    private static Screen_Chat_Context__mdt loadDef(String screenKey, Boolean required) {
        List<Screen_Chat_Context__mdt> defs = [
            SELECT MasterLabel, Suggested_Questions_Json__c, Allowed_Objects__c,
                   Tool_Provider_Class__c, Tool_Instructions__c
            FROM Screen_Chat_Context__mdt
            WHERE DeveloperName = :screenKey
            LIMIT 1
        ];
        if (defs.isEmpty()) {
            if (required) throw new ChatException('This screen is not configured for chat yet.');
            return null;
        }
        return defs[0];
    }

    private static String buildScreenContext(Screen_Chat_Context__mdt def, Map<String, Object> live) {
        Map<String, Object> context = new Map<String, Object>();
        if (String.isNotBlank(def.Tool_Instructions__c)) context.put('toolInstructions', def.Tool_Instructions__c);
        if (live != null) context.putAll(live);
        String payload = JSON.serialize(context);
        return payload.length() > MAX_CONTEXT ? payload.substring(0, MAX_CONTEXT) : payload;
    }

    private static Map<String, Object> safeMap(String jsonStr) {
        if (String.isBlank(jsonStr)) return new Map<String, Object>();
        try { return (Map<String, Object>) JSON.deserializeUntyped(jsonStr); }
        catch (Exception e) { return new Map<String, Object>(); }
    }

    private static Object parseJsonOrEmptyList(String jsonStr) {
        if (String.isBlank(jsonStr)) return new List<Object>();
        try { return JSON.deserializeUntyped(jsonStr); } catch (Exception e) { return new List<Object>(); }
    }

    private static String getApiSessionId() {
        if (Test.isRunningTest()) return UserInfo.getSessionId();
        return Page.SessionIdProvider.getContent().toString().trim();
    }
}