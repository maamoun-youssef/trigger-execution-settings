/**
 * @author ULiT
 * @date 05/05/2025
 * @desciption create CommercialPlan ServicesAgreement/SellOutAgreement
****************************************************************************************************************************************************************************** */
public with sharing class RefreshPromoAgreementsBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Boolean refreshSellOutAgreements;
    private Boolean refreshSellInAgreements;
    private Boolean refreshServicesAgreements;
    private Boolean refreshExistingCPD;
    //private Set<String> promoAgreementGroupedFields;
    public RefreshPromoAgreementsBatch() {}
    public RefreshPromoAgreementsBatch(String startedFrom, Set<Id> supplierIdSet, Set<Id> negoScopeIdSet, Set<Id> commercialPlanIdSet, Set<Id> commercialPlanDetailIdSet, Integer year, Boolean refreshSellInAgreements, Boolean refreshSellOutAgreements, Boolean refreshServicesAgreements, Boolean refreshExistingCPD)
    {
        PromoSettings promoSettings = PromoSettings.loadPromoSettings();
        //this.promoAgreementGroupedFields = promoSettings.promoAgreementConfiguration.promoAgreementGroupedFields;
        this.nb = new NegoptimBatch(RefreshPromoAgreementsBatch.class.getName(),  NegoptimBatch.BatchType.Stateless, startedFrom);
        year = year == null ? Date.today().year() : year;
        this.refreshSellInAgreements = refreshSellInAgreements == null ? true : refreshSellInAgreements;
        this.refreshSellOutAgreements = refreshSellOutAgreements == null ? true : refreshSellOutAgreements;
        this.refreshServicesAgreements = refreshServicesAgreements == null ? true : refreshServicesAgreements;
        this.refreshExistingCPD = refreshExistingCPD == null ? false : refreshExistingCPD;
        this.query = 'SELECT Id, Supplier__c, Supplier__r.Name, CommercialPlan__c, NegoScope__c, Contract__c, Contract__r.Name,';
        this.query += ' ProductDiscountStatement__c, ProductDiscountStatement__r.PromoStatementType__c, ProductDiscountStatement__r.PromoAgreementType__c,';
        this.query += ' CommercialPlan__r.Name, CommercialPlan__r.Code__c, CommercialPlan__r.Pol_Com_Condition__c, CommercialPlan__r.Pol_Com_Condition__r.SetCPDSellOut__c, CommercialPlan__r.Pol_Com_Condition__r.Proof_counterparty_requested__c,';
        this.query += ' CommercialPlan__r.Supplier__c, CommercialPlan__r.Supplier__r.Name, CommercialPlan__r.NegoScope__c, NegoScope__r.Name, CommercialPlan__r.Contract__c, CommercialPlan__r.Contract__r.Name, CommercialPlan__r.Contract_Discount__c,';
        this.query += ' CommercialPlan__r.BusinessUnitSource__c, CommercialPlan__r.BusinessUnitTarget__c, CommercialPlan__r.Hierarchy__c,';
        this.query += ' CommercialPlan__r.SellInBDate__c, CommercialPlan__r.SellInEDate__c, CommercialPlan__r.SellOutBDate__c, CommercialPlan__r.SellOutEDate__c,';
        this.query += ' SellInBDate__c, SellInEDate__c, SellOutBDate__c, SellOutEDate__c,';
        this.query += ' CommercialPlanSellIn__c, CommercialPlanSellOut__c, CommercialPlanServices__c';
        this.query += ' FROM CommercialPlanDetail__c';
        // build where
        List<String> andConditionsList = new List<String>();
        List<String> orConditions = new List<String>();
        if(this.refreshSellInAgreements || this.refreshSellOutAgreements || this.refreshServicesAgreements) {
            orConditions.add('ProductDiscountStatement__c <> NULL');
        }
        if (!this.refreshExistingCPD) {
            orConditions.add('CommercialPlanSellIn__c = NULL');
            orConditions.add('CommercialPlanSellOut__c = NULL');
            orConditions.add('CommercialPlanServices__c = NULL');
        }

        if (!orConditions.isEmpty()) {
            andConditionsList.add('(' + String.join(orConditions, ' OR ') + ')');
        }
        if(!this.refreshExistingCPD) {
            if (this.refreshSellInAgreements) {
                andConditionsList.add('CommercialPlanSellIn__c = NULL');
            }
            if (this.refreshSellOutAgreements) {
                andConditionsList.add('CommercialPlanSellOut__c = NULL');
            }
            if (this.refreshServicesAgreements) {
                andConditionsList.add('CommercialPlanServices__c = NULL');
            }
        }
        if (supplierIdSet != null && !supplierIdSet.isEmpty()) {
            andConditionsList.add('Supplier__c IN (\'' + String.join(new List<Id>(supplierIdSet), '\',\'') + '\')');
        }
        if (negoScopeIdSet != null && !negoScopeIdSet.isEmpty()) {
            andConditionsList.add('NegoScope__c IN (\'' + String.join(new List<Id>(negoScopeIdSet), '\',\'') + '\')');
        }
        if (commercialPlanIdSet != null && !commercialPlanIdSet.isEmpty()) {
            andConditionsList.add('CommercialPlan__c IN (\'' + String.join(new List<Id>(commercialPlanIdSet), '\',\'') + '\')');
        }
        if (commercialPlanDetailIdSet != null && !commercialPlanDetailIdSet.isEmpty()) {
            andConditionsList.add('Id IN (\'' + String.join(new List<Id>(commercialPlanDetailIdSet), '\',\'') + '\')');
        }
        if (year != null) {
            andConditionsList.add('CommercialPlan__r.Year__c = ' + year);
        }
        String whereClause = andConditionsList.isEmpty() ? '' : ' WHERE ' + String.join(andConditionsList, ' AND ');
        this.query += whereClause;
        nb.logParameter('query', this.query);
        nb.logParameter('refreshSellInAgreements', refreshSellInAgreements);
        nb.logParameter('refreshSellOutAgreements', refreshSellOutAgreements);
        nb.logParameter('refreshServicesAgreements', refreshServicesAgreements);
        nb.logParameter('refreshExistingCPD', refreshExistingCPD);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<CommercialPlanDetail__c> scope) {
        System.SavePoint sp = Database.setSavepoint();
        System.debug('RefreshPromoAgreementsBatch.execute - scope size: ' + scope.size());
        try {
            Set<Id> commercialPlanDetailIdSet = new Set<Id>();
            Set<Id> commercialPlanSellInIdSet = new Set<Id>();
            Set<Id> commercialPlanSellOutIdSet = new Set<Id>();
            Set<Id> commercialPlanServicesIdSet = new Set<Id>();
            Set<Id> discountIdSet = new Set<Id>();
            Set<Id> nsIdSet = new Set<Id>();
            Set<Id> cpIdSet = new Set<Id>();
            Map<String, List<CommercialPlan__c>> existingCPMap = new Map<String, List<CommercialPlan__c>>();
            Map<Id, CommercialPlan__c> commercialPlansMap = new Map<Id, CommercialPlan__c>();
            List<CommercialPlanDetail__c> commercialPlanDetailsToUpdate = new List<CommercialPlanDetail__c>();
            Map<String, List<CommercialPlanDetail__c>> commercialPlanDetailsMap = new Map<String, List<CommercialPlanDetail__c>>();
            List<String> promoAgreementGroupedFields = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.NegoScope__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.ProductDiscountStatement__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellInBDate__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellInEDate__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDate__c.Name
            };
            Set<Id> productDiscountStatementIdSet = new Set<Id>();
            for(CommercialPlanDetail__c item : scope) {
                if(item.ProductDiscountStatement__c != null) {
                    productDiscountStatementIdSet.add(item.ProductDiscountStatement__c);
                }
                if(item.NegoScope__c != null) {
                    nsIdSet.add(item.NegoScope__c);
                }
                if(item.CommercialPlan__c != null) {
                    cpIdSet.add(item.CommercialPlan__c);
                }
                if(item.CommercialPlanSellIn__c != null) {
                    commercialPlanSellInIdSet.add(item.CommercialPlanSellIn__c);
                }
                if(item.CommercialPlanSellOut__c != null) {
                    commercialPlanSellOutIdSet.add(item.CommercialPlanSellOut__c);
                }
                if(item.CommercialPlanServices__c != null) {
                    commercialPlanServicesIdSet.add(item.CommercialPlanServices__c);                    
                }
                commercialPlanDetailIdSet.add(item.Id);
                commercialPlansMap.put(item.CommercialPlan__c, item.CommercialPlan__r);
                // Build key matching aggregate query concatenation (includes null as string "null")
                String key = String.valueOf(item.CommercialPlan__c) + String.valueOf(item.NegoScope__c) + String.valueOf(item.ProductDiscountStatement__c) 
                    + String.valueOf(item.SellInBDate__c) + String.valueOf(item.SellInEDate__c) 
                    + String.valueOf(item.SellOutBDate__c) + String.valueOf(item.SellOutEDate__c);
                if(String.isNotBlank(key)) {
                    if(!commercialPlanDetailsMap.containsKey(key)) commercialPlanDetailsMap.put(key, new List<CommercialPlanDetail__c>());
                    commercialPlanDetailsMap.get(key).add(item);
                }
            }
            List<CommercialPlan__c> existingCPList = [SELECT Id, Name, NegoScope__c, CommercialPlanParent__c,
                                                      PromoStatementType__c,
                                                      SellInBDate__c, SellInEDate__c, SellOutBDate__c, SellOutEDate__c
                                                      FROM CommercialPlan__c
                                                      WHERE RecordType.DeveloperName = 'PromoAgreement'
                                                      AND NegoScope__c IN :nsIdSet
                                                      AND CommercialPlanParent__c IN :cpIdSet];
            for (CommercialPlan__c item : existingCPList) {
                String key = item.PromoStatementType__c + '' + item.CommercialPlanParent__c + '' + item.NegoScope__c;
                if (item.PromoStatementType__c == 'SellIn') {
                    key += item.SellInBDate__c + '' + item.SellInEDate__c;
                }
                key += item.SellOutBDate__c + '' + item.SellOutEDate__c;
                if (!existingCPMap.containsKey(key)) {
                    existingCPMap.put(key, new List<CommercialPlan__c>());
                }
                existingCPMap.get(key).add(item);
            }
            Map<Id, ProductDiscountStatement__c> productDiscountStatementMap = new Map<Id, ProductDiscountStatement__c>();
            if(!productDiscountStatementIdSet.isEmpty()) {
                productDiscountStatementMap = new Map<Id, ProductDiscountStatement__c>([SELECT Id, PromoStatementType__c, PromoAgreementType__c FROM ProductDiscountStatement__c WHERE Id IN :productDiscountStatementIdSet]);
            }
            Map<String, CommercialPlan__c> commercialPlansToUpsert = new Map<String, CommercialPlan__c>();
            Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(SObjectType.CommercialPlan__c.Name).getDescribe().fields.getMap();
            DescribeFieldResult dfr = objectFieldsMap.get(SObjectType.CommercialPlan__c.fields.PromoStatementType__c.Name).getDescribe();
            Map<String, String> promoStatementTypPicklistValues = new Map<String, String>();
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                promoStatementTypPicklistValues.put(pe.getValue(), pe.getLabel());
            }
            String CPDQuery = 'SELECT ' + String.join(promoAgreementGroupedFields, ',');
            CPDQuery += ' FROM CommercialPlanDetail__c';
            CPDQuery += ' WHERE Id IN (\'' + String.join(new List<Id>(commercialPlanDetailIdSet), '\', \'') + '\')';
            CPDQuery += ' AND ProductDiscountStatement__c != NULL';
            CPDQuery += ' GROUP BY ' + String.join(promoAgreementGroupedFields, ',');
            List<AggregateResult> aggregateResults = Database.query(CPDQuery);
            for(AggregateResult item : aggregateResults) {
                Id commercialPlanId = (Id) item.get(SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name);
                Id negoScopeId = (Id) item.get(SObjectType.CommercialPlanDetail__c.fields.NegoScope__c.Name);
                Id productDiscountStatementId = (Id) item.get(SObjectType.CommercialPlanDetail__c.fields.ProductDiscountStatement__c.Name);
                Date sellInBdate = (Date) item.get(SObjectType.CommercialPlanDetail__c.fields.SellInBDate__c.Name);
                Date sellInEdate = (Date) item.get(SObjectType.CommercialPlanDetail__c.fields.SellInEDate__c.Name);
                Date sellOutBdate = (Date) item.get(SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.Name);
                Date sellOutEdate = (Date) item.get(SObjectType.CommercialPlanDetail__c.fields.SellOutEDate__c.Name);
                String baseKey = String.valueOf(commercialPlanId) + String.valueOf(negoScopeId) + String.valueOf(productDiscountStatementId) + String.valueOf(sellInBdate) + String.valueOf(sellInEdate) + String.valueOf(sellOutBdate) + String.valueOf(sellOutEdate);
                // Check PromoStatementType from ProductDiscountStatement
                String promoStatementType = productDiscountStatementMap.containsKey(productDiscountStatementId) ? productDiscountStatementMap.get(productDiscountStatementId).PromoStatementType__c : null;
                String promoAgreementType = productDiscountStatementMap.containsKey(productDiscountStatementId) ? productDiscountStatementMap.get(productDiscountStatementId).PromoAgreementType__c : null;
                if(String.isNotBlank(promoStatementType) && commercialPlanDetailsMap.containsKey(baseKey)) {
                    CommercialPlanDetail__c refCPD = commercialPlanDetailsMap.get(baseKey)[0];
                    CommercialPlan__c refCommercialPlan = commercialPlansMap.get(commercialPlanId);
                    
                    // Build keys for matching existing CommercialPlans (without ProductDiscountStatement__c)
                    String existingCPKeySellIn = 'SellIn' + String.valueOf(commercialPlanId) + String.valueOf(negoScopeId) + String.valueOf(sellInBdate) + String.valueOf(sellInEdate) + String.valueOf(sellOutBdate) + String.valueOf(sellOutEdate);
                    String existingCPKeySellOut = 'SellOut' + String.valueOf(commercialPlanId) + String.valueOf(negoScopeId) + String.valueOf(sellOutBdate) + String.valueOf(sellOutEdate);
                    String existingCPKeyServices = 'Services' + String.valueOf(commercialPlanId) + String.valueOf(negoScopeId) + String.valueOf(sellOutBdate) + String.valueOf(sellOutEdate);
                    
                    // if PromoStatementType contains 'SellIn'
                    Boolean hasSellIn = promoStatementType.contains('SellIn');
                    if(hasSellIn && this.refreshSellInAgreements) {
                        String cpName = (refCommercialPlan.Name.length() > 20 ? refCommercialPlan.Name.substring(0, 20) : refCommercialPlan.Name)
                            + '-' + promoStatementTypPicklistValues.get('SellIn') + '-' + (refCPD.NegoScope__r.Name.length() > 20 ? refCPD.NegoScope__r.Name.substring(0, 20) : refCPD.NegoScope__r.Name);
                        String cpSize = existingCPMap.containsKey(existingCPKeySellIn) ? String.ValueOf(existingCPMap.get(existingCPKeySellIn).size()) : '1';
                        CommercialPlan__c newCommercialPlanSellIn = new CommercialPlan__c(
                            Name = (cpName.length() > 73 ? cpName.substring(0, 73) : cpName) + '-' + cpSize.leftPad(2, '0'),
                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.sObjectType, 'PromoAgreement'),
                            CommercialPlanParent__c = refCommercialPlan.Id,
                            Supplier__c = refCPD.Supplier__c,
                            NegoScope__c = refCPD.NegoScope__c,
                            Contract__c = refCPD.Contract__c,
                            BusinessUnitSource__c = refCommercialPlan.BusinessUnitSource__c,
                            BusinessUnitTarget__c = refCommercialPlan.BusinessUnitTarget__c,
                            Hierarchy__c = refCommercialPlan.Hierarchy__c,
                            SellInBDate__c = refCPD.SellInBDate__c,
                            SellInEDate__c = refCPD.SellInEDate__c,
                            SellOutBDate__c = refCPD.SellInBDate__c,
                            SellOutEDate__c = refCPD.SellInEDate__c,
                            Status__c = 'In preparation',
                            PromoStatementType__c = 'SellIn',
                            PromoAgreementType__c = promoAgreementType);
                        if (existingCPMap.containsKey(existingCPKeySellIn)) {
                            newCommercialPlanSellIn.Id = existingCPMap.get(existingCPKeySellIn).get(0).Id;
                        }
                        commercialPlansToUpsert.put(existingCPKeySellIn, newCommercialPlanSellIn);
                    }
                    
                    // if PromoStatementType contains 'SellOut'
                    Boolean hasSellOut = promoStatementType.contains('SellOut');
                    if(hasSellOut && this.refreshSellOutAgreements) {
                        String cpName = (refCommercialPlan.Name.length() > 20 ? refCommercialPlan.Name.substring(0, 20) : refCommercialPlan.Name)
                            + '-' + promoStatementTypPicklistValues.get('SellOut') + '-' + (refCPD.NegoScope__r.Name.length() > 20 ? refCPD.NegoScope__r.Name.substring(0, 20) : refCPD.NegoScope__r.Name);
                        String cpSize = existingCPMap.containsKey(existingCPKeySellOut) ? String.ValueOf(existingCPMap.get(existingCPKeySellOut).size()) : '1';
                        CommercialPlan__c newCommercialPlanSellOut = new CommercialPlan__c(
                            Name = (cpName.length() > 73 ? cpName.substring(0, 73) : cpName) + '-' + cpSize.leftPad(2, '0'),
                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.sObjectType, 'PromoAgreement'),
                            CommercialPlanParent__c = refCommercialPlan.Id,
                            Supplier__c = refCPD.Supplier__c,
                            NegoScope__c = refCPD.NegoScope__c,
                            Contract__c = refCPD.Contract__c,
                            BusinessUnitSource__c = refCommercialPlan.BusinessUnitSource__c,
                            BusinessUnitTarget__c = refCommercialPlan.BusinessUnitTarget__c,
                            Hierarchy__c = refCommercialPlan.Hierarchy__c,
                            SellOutBDate__c = refCPD.SellOutBDate__c,
                            SellOutEDate__c = refCPD.SellOutEDate__c,
                            Status__c = 'In preparation',
                            PromoStatementType__c = 'SellOut',
                            PromoAgreementType__c = promoAgreementType);
                        if (existingCPMap.containsKey(existingCPKeySellOut)) {
                            newCommercialPlanSellOut.Id = existingCPMap.get(existingCPKeySellOut).get(0).Id;
                        }
                        commercialPlansToUpsert.put(existingCPKeySellOut, newCommercialPlanSellOut);
                    }
                    
                    // if PromoStatementType contains 'Services'
                    Boolean hasServices = promoStatementType.contains('Services');
                    if(hasServices && this.refreshServicesAgreements) {
                        String cpName = (refCommercialPlan.Name.length() > 20 ? refCommercialPlan.Name.substring(0, 20) : refCommercialPlan.Name)
                            + '-' + promoStatementTypPicklistValues.get('Services') + '-' + (refCPD.NegoScope__r.Name.length() > 20 ? refCPD.NegoScope__r.Name.substring(0, 20) : refCPD.NegoScope__r.Name);
                        String cpSize = existingCPMap.containsKey(existingCPKeyServices) ? String.ValueOf(existingCPMap.get(existingCPKeyServices).size()) : '1';
                        CommercialPlan__c newCommercialPlanServices = new CommercialPlan__c(
                            Name = (cpName.length() > 73 ? cpName.substring(0, 73) : cpName) + '-' + cpSize.leftPad(2, '0'),
                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(CommercialPlan__c.sObjectType, 'PromoAgreement'),
                            CommercialPlanParent__c = refCommercialPlan.Id,
                            Supplier__c = refCPD.Supplier__c,
                            NegoScope__c = refCPD.NegoScope__c,
                            Contract__c = refCPD.Contract__c,
                            BusinessUnitSource__c = refCommercialPlan.BusinessUnitSource__c,
                            BusinessUnitTarget__c = refCommercialPlan.BusinessUnitTarget__c,
                            Hierarchy__c = refCommercialPlan.Hierarchy__c,
                            SellOutBDate__c = refCPD.SellOutBDate__c,
                            SellOutEDate__c = refCPD.SellOutEDate__c,
                            Status__c = 'In preparation',
                            PromoStatementType__c = 'Services',
                            PromoAgreementType__c = promoAgreementType);
                        if (existingCPMap.containsKey(existingCPKeyServices)) {
                            newCommercialPlanServices.Id = existingCPMap.get(existingCPKeyServices).get(0).Id;
                        }
                        commercialPlansToUpsert.put(existingCPKeyServices, newCommercialPlanServices);
                    }
                }
            }
            // Upsert CommercialPlans
            if(!commercialPlansToUpsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(commercialPlansToUpsert.values(), false);
                nb.logResults(results, commercialPlansToUpsert.values());
            }
            // Update CommercialPlanDetail records with new CommercialPlan IDs
            for(CommercialPlanDetail__c item : scope) {
                Boolean isUpdated = false;
                if(item.ProductDiscountStatement__c != null && productDiscountStatementMap.containsKey(item.ProductDiscountStatement__c)) {
                    String promoStatementType = productDiscountStatementMap.get(item.ProductDiscountStatement__c).PromoStatementType__c;
                    // Build keys without ProductDiscountStatement__c to match commercialPlansToUpsert keys
                    String keySellIn = 'SellIn' + String.valueOf(item.CommercialPlan__c) + String.valueOf(item.NegoScope__c) + String.valueOf(item.SellInBDate__c) + String.valueOf(item.SellInEDate__c) + String.valueOf(item.SellOutBDate__c) + String.valueOf(item.SellOutEDate__c);
                    String keySellOut = 'SellOut' + String.valueOf(item.CommercialPlan__c) + String.valueOf(item.NegoScope__c) + String.valueOf(item.SellOutBDate__c) + String.valueOf(item.SellOutEDate__c);
                    String keyServices = 'Services' + String.valueOf(item.CommercialPlan__c) + String.valueOf(item.NegoScope__c) + String.valueOf(item.SellOutBDate__c) + String.valueOf(item.SellOutEDate__c);
                    
                    if(promoStatementType != null && promoStatementType.contains('SellIn') && (this.refreshSellInAgreements || this.refreshExistingCPD) && commercialPlansToUpsert.containsKey(keySellIn)) {
                        item.CommercialPlanSellIn__c = commercialPlansToUpsert.get(keySellIn).Id;
                        isUpdated = true;
                    }
                    if(promoStatementType != null && promoStatementType.contains('SellOut') && (this.refreshSellOutAgreements || this.refreshExistingCPD) && commercialPlansToUpsert.containsKey(keySellOut)) {
                        item.CommercialPlanSellOut__c = commercialPlansToUpsert.get(keySellOut).Id;
                        isUpdated = true;
                    }
                    if(promoStatementType != null && promoStatementType.contains('Services') && (this.refreshServicesAgreements || this.refreshExistingCPD) && commercialPlansToUpsert.containsKey(keyServices)) {
                        item.CommercialPlanServices__c = commercialPlansToUpsert.get(keyServices).Id;
                        isUpdated = true;
                    }
                }
                if(isUpdated) {
                    commercialPlanDetailsToUpdate.add(item);
                }
            }
            if(!commercialPlanDetailsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(commercialPlanDetailsToUpdate, true);
                nb.logResults(results, commercialPlanDetailsToUpdate);
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
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> supplierIdSet = (Set<Id>)paramsMap.get('supplierIdSet');
        Set<Id> negoScopeIdSet = (Set<Id>)paramsMap.get('negoScopeIdSet');
        Set<Id> commercialPlanIdSet = (Set<Id>)paramsMap.get('commercialPlanIdSet');
        Set<Id> commercialPlanDetailIdSet = (Set<Id>)paramsMap.get('commercialPlanDetailIdSet');
        Integer year = (Integer)paramsMap.get('year');
        Boolean refreshSellInAgreements = (Boolean)paramsMap.get('refreshSellInAgreements');
        Boolean refreshSellOutAgreements = (Boolean)paramsMap.get('refreshSellOutAgreements');
        Boolean refreshServicesAgreements = (Boolean)paramsMap.get('refreshServicesAgreements');
        Boolean refreshExistingCPD = (Boolean)paramsMap.get('refreshExistingCPD');
        return new RefreshPromoAgreementsBatch(startedFrom, supplierIdSet, negoScopeIdSet, commercialPlanIdSet, commercialPlanDetailIdSet, year, refreshSellInAgreements, refreshSellOutAgreements, refreshServicesAgreements, refreshExistingCPD);
    }
}