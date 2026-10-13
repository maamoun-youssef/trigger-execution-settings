public with sharing class NegoScopeChatToolProvider implements Callable {

    private static final Integer MAX_GROUPS = 200;

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> req      = (Map<String, Object>) args.get('request');
        Map<String, Object> qc       = (Map<String, Object>) args.get('queryContext');
        String tool = (action == null) ? '' : action.toLowerCase();
        if (tool == 'scope')    return runScope(req, qc);
        if (tool == 'find')     return runFind(req, qc);
        if (tool == 'diagnose') return runDiagnose(qc);
        throw new Dynamicchattercontroller.ChatException('Unknown tool.');
    }

    private Object runScope(Map<String, Object> req, Map<String, Object> qc) {
        if (qc == null || qc.isEmpty()) throw new Dynamicchattercontroller.ChatException('This screen does not expose a live scope.');
        String objName = SObjectType.PG__c.getName();
        String whereClause = buildScopeWhere(qc, objName);
        String extra = Dynamicchattercontroller.safeCondition((String) req.get('where'));
        if (String.isNotBlank(extra)) {
            whereClause = String.isBlank(whereClause) ? extra : '(' + whereClause + ') AND (' + extra + ')';
        }
        String whereStr = String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause;
        String groupBy = Dynamicchattercontroller.safeField((String) req.get('groupBy'));
        if (String.isNotBlank(groupBy)) groupBy = Dynamicchattercontroller.resolveLookup(objName, groupBy);
        Boolean countOnly = req.get('countOnly') == true;
        if (countOnly || (String.isBlank(groupBy) && req.get('fields') == null)) {
            AggregateResult ar = (AggregateResult) Database.query(
                'SELECT COUNT(Id) cnt FROM ' + objName + whereStr)[0];
            return new Map<String, Object>{ 'totalInScope' => ar.get('cnt') };
        }
        if (String.isNotBlank(groupBy)) {
            String alias = groupBy.contains('.') ? groupBy.substringAfterLast('.') : groupBy;
            String q = 'SELECT COUNT(Id) cnt, ' + groupBy + ' FROM ' + objName + whereStr +
                       ' GROUP BY ' + groupBy + ' ORDER BY COUNT(Id) DESC LIMIT ' + MAX_GROUPS;
            List<Map<String, Object>> values = new List<Map<String, Object>>();
            Integer total = 0;
            for (AggregateResult ar : (List<AggregateResult>) Database.query(q)) {
                Object v = ar.get(alias);
                Integer c = (Integer) ar.get('cnt');
                total += c;
                values.add(new Map<String, Object>{ 'value' => (v == null ? '(empty)' : v), 'count' => c });
            }
            return new Map<String, Object>{
                'groupedBy' => groupBy, 'distinctValues' => values.size(),
                'totalInScope' => total, 'values' => values
            };
        }
        List<String> fields = new List<String>();
        for (String f : Dynamicchattercontroller.safeFieldList(req.get('fields'))) fields.add(Dynamicchattercontroller.resolveLookup(objName, f));
        Integer lim = Dynamicchattercontroller.intOf(req.get('limit'), Dynamicchattercontroller.MAX_ROWS);
        Integer offset = Dynamicchattercontroller.boundedInt(req.get('offset'), 0, 0, 2000);
        String orderBy = req.get('orderBy') != null ? Dynamicchattercontroller.safeField((String) req.get('orderBy')) : 'Name';
        String q = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objName + whereStr +
                   ' ORDER BY ' + orderBy + ' NULLS LAST LIMIT ' + lim +
                   (offset > 0 ? ' OFFSET ' + offset : '');
        return new Map<String, Object>{ 'rows' => Dynamicchattercontroller.strip(Database.query(q)) };
    }

    private String buildScopeWhere(Map<String, Object> qc, String objName) {
        NegoScopeManagerController.QueriesWrapper qw = NegoScopeManagerController.buildPGQuery(
            Dynamicchattercontroller.str(qc, 'negoScopeJSON'),
            Dynamicchattercontroller.str(qc, 'filteredFieldsJSON'),
            Dynamicchattercontroller.str(qc, 'filterAttrJSON'),
            Dynamicchattercontroller.str(qc, 'brandListJSON'),
            Dynamicchattercontroller.str(qc, 'hierarchyJSON')
        );
        NegoScope__c ns = (NegoScope__c) JSON.deserialize(Dynamicchattercontroller.str(qc, 'negoScopeJSON'), NegoScope__c.class);
        String base = ns.IncludeAllProducts__c ? qw.respectFilterQuery : qw.query;
        return extractWhere(base, objName);
    }

    private String extractWhere(String query, String objName) {
        if (String.isBlank(query)) return '';
        Integer fromIdx = query.toUpperCase().indexOf(' FROM ' + objName.toUpperCase());
        if (fromIdx < 0) return '';
        String tail = query.substring(fromIdx);
        Integer whereIdx = tail.toUpperCase().indexOf(' WHERE ');
        if (whereIdx < 0) return '';
        String w = tail.substring(whereIdx + 7);
        for (String stop : new List<String>{ ' ORDER BY ', ' GROUP BY ', ' LIMIT ' }) {
            Integer i = w.toUpperCase().indexOf(stop);
            if (i > -1) w = w.substring(0, i);
        }
        return w.trim();
    }

    private Object runDiagnose(Map<String, Object> qc) {
        Map<String, Object> out = new Map<String, Object>();
        if (qc == null || qc.isEmpty()) { out.put('reason', 'noSupplierChosen'); return out; }
        NegoScope__c ns = (NegoScope__c) JSON.deserialize(Dynamicchattercontroller.str(qc, 'negoScopeJSON'), NegoScope__c.class);
        out.put('currentScopeClient', currentSupplierName(qc));
        if (ns.Supplier__c == null) { out.put('reason', 'noSupplierChosen'); return out; }
        Integer supplierPGs = Database.countQuery(
            'SELECT COUNT() FROM PG__c WHERE Supplier__c = \'' + ns.Supplier__c + '\'');
        out.put('productGroupsForThisClientInDatabase', supplierPGs);
        if (supplierPGs == 0) { out.put('reason', 'noProductsExistForThisClient'); return out; }
        Integer inScope = 0;
        try {
            String whereClause = buildScopeWhere(qc, SObjectType.PG__c.getName());
            inScope = Database.countQuery('SELECT COUNT() FROM PG__c' +
                (String.isBlank(whereClause) ? '' : ' WHERE ' + whereClause));
        } catch (Exception e) { System.debug('diagnose scope count: ' + e.getMessage()); }
        out.put('productsMatchingCurrentFilters', inScope);
        Integer visibleTotal = intFromLive(qc, 'visibleTotalRecords');
        if (visibleTotal != null) out.put('productsCurrentlyShownInGrid', visibleTotal);
        if (inScope > 0) {
            out.put('reason', (visibleTotal != null && visibleTotal > 0)
                ? 'productsAreShowingNothingIsWrong'
                : 'productsExistButAreOnAnotherPageOrColumnSearchHidesThem');
            return out;
        }
        List<String> activeFilters = new List<String>();
        List<Object> hes    = Dynamicchattercontroller.safeList(Dynamicchattercontroller.str(qc, 'hierarchyJSON'));
        List<Object> brands = Dynamicchattercontroller.safeList(Dynamicchattercontroller.str(qc, 'brandListJSON'));
        List<Object> attrs  = new List<Object>();
        try {
            Map<String, Object> fa = (Map<String, Object>) JSON.deserializeUntyped(Dynamicchattercontroller.str(qc, 'filterAttrJSON'));
            if (fa != null && fa.get('productAttributes') instanceof List<Object>) {
                attrs = (List<Object>) fa.get('productAttributes');
            }
        } catch (Exception e) { /* ignore */ }
        if (!hes.isEmpty())    activeFilters.add('hierarchies');
        if (!brands.isEmpty()) activeFilters.add('brands');
        if (!attrs.isEmpty())  activeFilters.add('productAttributes');
        out.put('reason', 'filtersRemoveEverything');
        out.put('activeFilters', activeFilters);
        return out;
    }

    private Integer intFromLive(Map<String, Object> qc, String key) {
        try {
            Object v = (qc == null) ? null : qc.get(key);
            return v == null ? null : Integer.valueOf(String.valueOf(v));
        } catch (Exception e) { return null; }
    }

    private Object runFind(Map<String, Object> req, Map<String, Object> qc) {
        String term = String.valueOf(req.get('name'));
        if (String.isBlank(term)) throw new Dynamicchattercontroller.ChatException('No product name supplied.');
        term = term.trim();
        String objName = SObjectType.PG__c.getName();
        Boolean hasProductLookup = SObjectType.PG__c.getSObjectType().getDescribe().fields.getMap().containsKey('product__c');
        List<String> fields = Dynamicchattercontroller.describeFields(objName, new List<String>{
            'Name','GTINPRD__c','Status__c','ClientCategory__c',
            'Supplier__c','Brand__c','Hierarchy__c','Product__c','BusinessUnit__c'
        });
        String asciiPrefix = asciiLeadingChunk(term);
        String likePattern = '%' + String.escapeSingleQuotes(asciiPrefix) + '%';
        String likeWhere = 'Name LIKE \'' + likePattern + '\''
            + (hasProductLookup ? ' OR Product__r.Name LIKE \'' + likePattern + '\'' : '');
        List<SObject> raw = Database.query(
            'SELECT ' + String.join(fields, ', ') + ' FROM ' + objName +
            ' WHERE (' + likeWhere + ') LIMIT 500');
        String wanted = foldKey(term);
        List<SObject> matches = new List<SObject>();
        for (SObject r : raw) {
            String pgName = (String) r.get('Name');
            String prodName = hasProductLookup ? nameOf(r, 'Product__r') : null;
            if (foldKey(pgName) == wanted || (prodName != null && foldKey(prodName) == wanted)) matches.add(r);
        }
        Boolean matchedExactly = !matches.isEmpty();
        if (!matchedExactly) {
            matches = new List<SObject>();
            for (Integer i = 0; i < Math.min(raw.size(), 10); i++) matches.add(raw[i]);
        }
        if (matches.isEmpty()) {
            String p2Like = '%' + String.escapeSingleQuotes(asciiPrefix) + '%';
            List<Product2> rawProds = Database.query(
                'SELECT Id, Name, ProductCode, IsActive FROM Product2 WHERE Name LIKE \'' + p2Like + '\' LIMIT 50');
            List<Product2> prods = new List<Product2>();
            for (Product2 p : rawProds) { if (foldKey(p.Name) == wanted) prods.add(p); }
            if (prods.isEmpty()) {
                for (Integer i = 0; i < Math.min(rawProds.size(), 5); i++) prods.add(rawProds[i]);
            }
            if (prods.isEmpty()) {
                return new Map<String, Object>{ 'found' => 0, 'note' => 'No product with that name exists anywhere in the system.' };
            }
            List<Object> pOut = new List<Object>();
            for (Product2 p : prods) {
                Map<String, Object> row = Dynamicchattercontroller.stripMap((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(p)));
                row.put('existsAsProductButHasNoProductGroup', true);
                row.put('inCurrentScreenScope', false);
                pOut.add(row);
            }
            return new Map<String, Object>{ 'found' => pOut.size(), 'matchedExactly' => false, 'matches' => pOut };
        }
        Set<Id> ids = new Map<Id, SObject>(matches).keySet();
        String idList = '(\'' + String.join(new List<Id>(ids), '\',\'') + '\')';
        Set<Id> inScope = new Set<Id>();
        Boolean scopeChecked = false;
        try {
            String scopeWhere = buildScopeWhere(qc, objName);
            String q = 'SELECT Id FROM ' + objName + ' WHERE Id IN ' + idList +
                       (String.isBlank(scopeWhere) ? '' : ' AND (' + scopeWhere + ')');
            for (SObject s : Database.query(q)) inScope.add((Id) s.get('Id'));
            scopeChecked = true;
        } catch (Exception e) { System.debug('find/scope check: ' + e.getMessage()); }
        Set<String> seenSuppliers = new Set<String>();
        List<String> supplierNames = new List<String>();
        for (SObject m : matches) {
            String sup = nameOf(m, 'Supplier__r');
            if (String.isNotBlank(sup) && !seenSuppliers.contains(sup)) { seenSuppliers.add(sup); supplierNames.add(sup); }
        }
        List<Object> out = new List<Object>();
        for (SObject m : matches) {
            Map<String, Object> row = Dynamicchattercontroller.stripMap((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(m)));
            if (scopeChecked) row.put('inCurrentScreenScope', inScope.contains((Id) m.get('Id')));
            out.add(row);
        }
        return new Map<String, Object>{
            'found' => out.size(), 'matchedExactly' => matchedExactly,
            'suppliersForThisProduct' => supplierNames,
            'currentScopeClient' => currentSupplierName(qc),
            'matches' => out
        };
    }

    private String asciiLeadingChunk(String s) {
        if (String.isBlank(s)) return s;
        String chunk = '';
        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i + 1);
            if (ch.isAlphanumeric() || ch == ' ') chunk += ch; else break;
        }
        chunk = chunk.trim();
        if (chunk.length() < 2) {
            String folded = foldKey(s);
            chunk = folded.contains(' ') ? folded.substringBefore(' ') : folded;
        }
        return chunk;
    }

    private String foldKey(String s) {
        return s == null ? '' : s.toLowerCase().trim().replaceAll('\\s+', ' ');
    }

    private String nameOf(SObject rec, String rel) {
        try {
            SObject parent = rec.getSObject(rel);
            return parent == null ? null : (String) parent.get('Name');
        } catch (Exception e) { return null; }
    }

    private String currentSupplierName(Map<String, Object> qc) {
        try {
            NegoScope__c ns = (NegoScope__c) JSON.deserialize(Dynamicchattercontroller.str(qc, 'negoScopeJSON'), NegoScope__c.class);
            if (ns.Supplier__c == null) return null;
            List<Supplier__c> sups = [SELECT Name FROM Supplier__c WHERE Id = :ns.Supplier__c LIMIT 1];
            return sups.isEmpty() ? null : sups[0].Name;
        } catch (Exception e) { return null; }
    }
}