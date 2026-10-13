/**
 * @author ULiT
 * @date 29-01-2025
 * @description insert/delete NSPG__c
 **/
global with sharing class RefreshNegoScopePGBatch implements Database.Batchable<sObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Map<Id, Set<Id>> supplierPGsMap;
    ProductSettings prodSettings;
    Boolean isNewPGs;
    global RefreshNegoScopePGBatch() {}

    public RefreshNegoScopePGBatch(String startedFrom, List<Id> negoScopeIds, Boolean isNewPGs, Map<Id, Set<Id>> supplierPGsMap) {
        this.nb = new NegoptimBatch(RefreshNegoScopePGBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.isNewPGs = isNewPGs != null ? isNewPGs : false;
        this.supplierPGsMap = supplierPGsMap == null ? new Map<Id, Set<Id>>() : supplierPGsMap;
        Set<String> queriedNSFields = new Set<String>();
        String[] negoScopeFields = new String [] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.Name.Name,
            SObjectType.NegoScope__c.fields.Supplier__c.Name,
            SObjectType.NegoScope__c.fields.IncludeAllBrands__c.Name,
            SObjectType.NegoScope__c.fields.IncludeAllHEs__c.Name,
            SObjectType.NegoScope__c.fields.IncludeAllProducts__c.Name,
            SObjectType.NegoScope__c.fields.t_ProductAttributes__c.Name
        };
        if (negoScopeFields != null && !negoScopeFields.isEmpty()) {
            for (string item : negoScopeFields) {
                queriedNSFields.add(item.toLowerCase());
            }
        }
        Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.NegoScope__c.Name).getDescribe().fields.getMap();
        for(String fieldName : mfields.keySet()) {
            if (mfields.get(fieldName).getDescribe().isFilterable() && !queriedNSFields.contains(fieldName.toLowerCase())) {
                queriedNSFields.add(fieldName.toLowerCase());
            }
        }
        this.query = 'SELECT ';
        this.query += (!queriedNSFields.isEmpty() ? String.join(queriedNSFields, ', ') : 'Id ') + ',';
        this.query += ' (SELECT NegoScope__c, Hierarchy__c, Choice__c FROM NSHENegoScope__r),';
        this.query += ' (SELECT NegoScope__c, Brand__c FROM NSBRANegoScope__r)';
        this.query += ' FROM NegoScope__c';
        this.query += ' WHERE Status__c = \'Active\'';
        if(this.isNewPGs) {
            this.query += ' AND (IncludeNewProducts__c = TRUE OR IncludeAllProducts__c = TRUE)';
            this.query += ' AND Supplier__c IN (\'' + String.join(supplierPGsMap.keySet(), '\',\'') +'\')';
        } else {
            this.query += ' AND IncludeAllProducts__c = TRUE';
        }
        if (negoScopeIds != null && !negoScopeIds.isEmpty()) {
            this.query += ' AND Id IN (\'' + String.join(negoScopeIds, '\',\'') + '\')';
        }
        this.prodSettings = ProductSettings.loadProductSettings();
        system.debug('query' + this.query);
        this.nb.logParameter('negoScopeIds', negoScopeIds);
        this.nb.logParameter('isNewPGs', isNewPGs);
        this.nb.logParameter('supplierPGsMap', supplierPGsMap);
        this.nb.logParameter('query', this.query);
    }
    
    global RefreshNegoScopePGBatch(String startedFrom, List<Id> negoScopeIds, String mode) {
        //this(startedFrom, negoScopeIds, null, null);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<NegoScope__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            List<NSPG__c> NSPGListToInsert = new List<NSPG__c>();
            List<NSPG__c> NSPGListToDelete = new List<NSPG__c>();
            Set<Id> pgIds;
            List<NegoScopeServices.NSHEWrapper> NSHEs;
            Set<Id> brandIds;
            Set<Id> nsIdSet = new Set<Id>();
            Map<Id, NegoScope__c> negoScopesMap = new Map<Id, NegoScope__c>(scope);
            List<NSPG__c> nspgList = [SELECT NegoScope__c, PG__c FROM NSPG__c WHERE NegoScope__c IN :negoScopesMap.keySet()];
            Map<Id, Set<Id>> nsPGMap = new Map<Id, Set<Id>>();
            Map<Id, Set<NSPG__c>> nsNSPGMap = new Map<Id, Set<NSPG__c>>();
            for(NSPG__c item : nspgList) {
                if(!nsPGMap.containsKey(item.NegoScope__c)) {
                    nsPGMap.put(item.NegoScope__c, new Set<Id>());
                    nsNSPGMap.put(item.NegoScope__c, new Set<NSPG__c>());
                }
                nsPGMap.get(item.NegoScope__c).add(item.PG__c);
                nsNSPGMap.get(item.NegoScope__c).add(item);
            }
            for (NegoScope__c item : scope) {
                pgIds = nsPGMap.containsKey(item.Id) ? nsPGMap.get(item.Id) : new Set<Id>();
                NSHEs = new List<NegoScopeServices.NSHEWrapper>();
                if (!item.NSHENegoScope__r.isEmpty()) {
                    for (NSHE__c NSHE : item.NSHENegoScope__r) {
                        NSHEs.add(new NegoScopeServices.NSHEWrapper(NSHE.Hierarchy__c, NSHE.Choice__c));
                    }
                }
                brandIds = new Set<Id>();
                if (!item.NSBRANegoScope__r.isEmpty()) {
                    for (NSBRA__c NSBra : item.NSBRANegoScope__r) {
                        brandIds.add(NSBra.Brand__c);
                    }
                }
                NegoScopeServices.PGQueryConditionsWrapper pgQueryConditions = NegoScopeServices.buildPGQueryConditions(JSON.serialize(item), null, item.t_ProductAttributes__c, JSON.serialize(brandIds), JSON.serialize(NSHEs), this.prodSettings.productRecordTypes);
                String respectFilterQuery = NegoScopeServices.buildQuery(null, null, pgQueryConditions.respectFilterQueryConditions, null, pgQueryConditions.filterAttributesConditions, pgQueryConditions.filterAttributesLogic, '');
                system.debug('respectFilterQuery >>> ' + respectFilterQuery);
                Map<Id, PG__c> pgMap = new Map<Id, PG__c>((List<PG__c>) Database.query(respectFilterQuery));
                // case new PGs
                if(this.isNewPGs) {
                    for(Id pgId : this.supplierPGsMap.get(item.Supplier__c)) {
                        if(pgMap.containsKey(pgId) && !pgIds.contains(pgId)) {
                            NSPGListToInsert.add(new NSPG__c(PG__c = pgId, NegoScope__c = item.Id, Status__c = 'Open'));
                        }
                    }
                } else {
                    for(Id pgId : pgMap.keySet()) {
                        if(!pgIds.contains(pgId)) {
                            NSPGListToInsert.add(new NSPG__c(PG__c = pgId, NegoScope__c = item.Id, Status__c = 'Open'));
                        }
                    }
                    if(nsNSPGMap.containsKey(item.Id)) {
                        for(NSPG__c nsPG : nsNSPGMap.get(item.Id)) {
                            if(!pgMap.containsKey(nsPG.PG__c)) {
                                NSPGListToDelete.add(nsPG);
                            }
                        }
                    }
                }
            }
            if (!NSPGListToDelete.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(NSPG__c.SObjectType)) {
                    List<Database.DeleteResult> results = Database.delete(NSPGListToDelete, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.DeleteResult result = results.get(i);
                        NSPG__c nspg = NSPGListToDelete.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += nspg + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            this.nb.logError(errorMessage);
                        }
                    }
                }
            }
            if (!NSPGListToInsert.isEmpty()) {
                // check security on insert NSPG__c fields
                String[] NSPGFields = new String[] {
                    SObjectType.NSPG__c.fields.NegoScope__c.Name,
                    SObjectType.NSPG__c.fields.PG__c.Name,
                    SObjectType.NSPG__c.fields.Status__c.Name
                };
                if (NegoptimHelper.checkCreatibility(NSPG__c.SObjectType, NSPGFields)) {
                    List<Database.SaveResult> results = Database.insert(NSPGListToInsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        NSPG__c nspg = NSPGListToInsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += nspg + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            this.nb.logError(errorMessage);
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> negoScopeIds = (List<Id>)paramsMap.get('negoScopeIds');
        Boolean isNewPGs = (Boolean)paramsMap.get('isNewPGs');
        Map<Id, Set<Id>> supplierPGsMap = (Map<Id, Set<Id>>)paramsMap.get('supplierPGsMap');
        return new RefreshNegoScopePGBatch(startedFrom, negoScopeIds, isNewPGs, supplierPGsMap);
    }
}