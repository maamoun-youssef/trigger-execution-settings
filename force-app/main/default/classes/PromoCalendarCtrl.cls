/**
 * @author ULiT
 * @date 12/11/2023
 * @description controls the functionalities of the promo calendar screen
 * includes search, filter and save functions
 * use grid settings selected in global settings
 */
public with sharing class PromoCalendarCtrl {
    
    @AuraEnabled(cacheable=false)
    public static String initGridSettings() {
        try {
            List<String> masterStaticFieldsList = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.Name.Name
            };
            List<String> staticFieldsList = new List<String> {
            };
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            String template = settings.PromoCalendarGridLayout;
            // GridSettingsManager gridSettingsManager = new GridSettingsManager(String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(masterStaticFieldsList, ','), String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(staticFieldsList, ','), template);
            // GridSettingsManager gridSettingsManager = new GridSettingsManager(String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(masterStaticFieldsList, ','), String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(staticFieldsList, ','), template);
            GridSettingsManager gridSettingsManager = new GridSettingsManager(String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(masterStaticFieldsList, ','), String.escapeSingleQuotes(SObjectType.CommercialPlanDetail__c.Name), '', String.join(staticFieldsList, ','), template, null, true);
            List<FieldWrapper> wFieldWrapperList = new List<FieldWrapper>();
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlanDetail__c.fields.Name.getLabel(), 'Id', 'LOOKUP', false));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlan__c.fields.Name.getLabel(), SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.getName(), 'LOOKUP', true));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlan__c.fields.getMap().get(SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName()).getDescribe().getLabel(),  SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName().replace('__c', '__r') + '.' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName(), 'STRING-LOOKUP', true));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlan__c.fields.getMap().get(SObjectType.CommercialPlan__c.fields.SellOutEDate__c.getName()).getDescribe().getLabel(),  SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName().replace('__c', '__r') + '.' + SObjectType.CommercialPlan__c.fields.SellOutEDate__c.getName(), 'STRING-LOOKUP', true));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlanDetail__c.fields.getMap().get(SObjectType.CommercialPlanDetail__c.fields.Status__c.getName()).getDescribe().getLabel(), SObjectType.CommercialPlanDetail__c.fields.Status__c.getName(), 'STRING', false));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.Product2.fields.getMap().get('Name').getDescribe().getLabel(), SObjectType.CommercialPlanDetail__c.fields.Product__c.getName(), 'LOOKUP', true));
            // wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlanDetail__c.fields.getMap().get('Even__c').getDescribe().getLabel(), 'Even__c', 'STRING', false));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.CommercialPlanDetail__c.fields.getMap().get(SObjectType.CommercialPlanDetail__c.fields.IsFromAgreementLinePrenego__c.getName()).getDescribe().getLabel(), SObjectType.CommercialPlanDetail__c.fields.IsFromAgreementLinePrenego__c.getName(), 'BOOLEAN', false));
            wFieldWrapperList.add(new FieldWrapper(SObjectType.Supplier__c.fields.getMap().get('Name').getDescribe().getLabel(), SObjectType.CommercialPlanDetail__c.fields.Supplier__c.getName(), 'LOOKUP', true));
            wFieldWrapperList.add(new FieldWrapper('IMAGE', 'IMAGE', 'Img', false));
            MainWrapper wMainWrapper = new MainWrapper(gridSettingsManager, wFieldWrapperList);
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            wMainWrapper.numberOfMonthN1 = promoSettings.numberOfMonthN1;
            return JSON.serialize(wMainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }

    @AuraEnabled(cacheable=false)
    public static string getCommercialPlanData(Integer pageSize, Integer pageNumber, String cpIdList, String cpdWhereClause, Integer year) {
        try {
            List<CommercialPlan__c> commercialPlanList = new List<CommercialPlan__c>();
            List<String> cpIds = cpIdList != null ? (List<String>) JSON.deserialize(cpIdList, List<String>.class) : new List<String>();
            string query;
            string comPlanRT = 'TradeMarketingCampaign';
            List<String> fields = new List<String> {
                SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName(),
                SObjectType.CommercialPlan__c.fields.SellOutEDate__c.getName(),
                SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName(),
                SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName().replace('__c', '__r') + '.' + SObjectType.CommercialPlan__c.fields.Name.getName(),
                SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName().replace('__c', '__r') + '.' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName(),
                SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName().replace('__c', '__r') + '.' + SObjectType.CommercialPlan__c.fields.SellOutEDate__c.getName()
            };
            if (String.isNotBlank(cpdWhereClause)) {
                String aggQuery = 'SELECT CommercialPlan__r.CommercialPlanParent__c parentId FROM CommercialPlanDetail__c ';
                aggQuery += cpdWhereClause;
                aggQuery += ' GROUP BY CommercialPlan__r.CommercialPlanParent__c';
                for (AggregateResult cpd : Database.query(aggQuery)) {
                    cpIds.add((String) String.valueOf(cpd.get('parentId')));
                }
            }
            year = year != null ? year : System.today().year();
            query = 'SELECT Id, Name,' + String.join(fields, ',');
            query += ' FROM ' + SObjectType.CommercialPlan__c.getName();
            query += ' WHERE CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
            query += ' AND ' + SObjectType.CommercialPlan__c.fields.CommercialPlanParent__c.getName() + ' = NULL';
            if (String.isNotBlank(cpdWhereClause) || (cpIds != null && !cpIds.isEmpty())) {
                query += ' AND Id IN (\'' + String.join(cpIds, '\',\'') + '\')';
            }
            query += ' ORDER BY ' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName();
            system.debug('query >>> ' + query);
            ApexPages.StandardSetController cpLocator = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            Integer totalSize = cpLocator.getResultSize();
            cpLocator.setPageSize(pageSize);
            cpLocator.setPageNumber(pageNumber);
            commercialPlanList = cpLocator.getRecords();
            CommercialPlanWrapper wCommercialPlan = new CommercialPlanWrapper(commercialPlanList, totalSize);
            return JSON.serialize(wCommercialPlan);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    @AuraEnabled(cacheable=false)
    public static string getOperation(Id campaginId, String filtered) {
        try {
            string query;
            string comPlanRT = 'SalesFloorEvent';
            query = 'SELECT Id, CommercialPlanParent__c, Name';
            List<CommercialPlan__c> commercialPlanList = new List<CommercialPlan__c>();
            List<String> conditions = new List<String>();
            if (filtered != null && String.isNotBlank(filtered)) {
                conditions.addAll(getConditionsofUserFilterData(filtered));
                if (conditions != null && !conditions.isEmpty()) {
                    query += ', (SELECT Id FROM CommercialPlanDetailsCP__r';
                    query += ' WHERE ' + String.join(conditions, ' AND ');
                    query += ')';
                }
            }
            query += ' FROM CommercialPlan__c';
            query += ' WHERE CommercialPlanParent__c = \'' + campaginId + '\'';
            query += ' ORDER BY Name';
            if (conditions != null && !conditions.isEmpty()) {
                List<CommercialPlan__c> commercialPlans = Database.query(query);
                for (CommercialPlan__c item : commercialPlans) {
                    if (item.CommercialPlanDetailsCP__r.size() > 0) {
                        commercialPlanList.add(item);
                    }
                }
            } else {
                commercialPlanList = Database.query(query);
            }
            return JSON.serialize(commercialPlanList);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    @AuraEnabled
    public static string getName(Id selectedId) {
        Schema.SObjectType sobjectType = selectedId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        
        SObject record = Database.query('SELECT Id, Name FROM ' + sobjectName + ' WHERE Id = :selectedId');
        return JSON.serialize(record);
    }
    @AuraEnabled(cacheable=false)
    public static string getFilteredOperation(Integer pageSize, Integer pageNumber, String filtered, String cpId, String filterData, Integer year) {
        try {
            List<CommercialPlanDetail__c> commercialPlanDetailList = new List<CommercialPlanDetail__c>();
            List<CommercialPlan__c> cpList = new List<CommercialPlan__c>();
            string query;
            String WhereClause = ''; 
            string comPlanRT = 'SalesFloorEvent';
            query = 'SELECT Id, CommercialPlanParent__c, Name,';
            query += ' (SELECT Id, Name, CreatedById, CreatedBy.Name, toLabel(Status__c), SellOutBDate__c, OpName__c, SellOutEDate__c,';
            query += ' CommercialPlan__r.Name,CommercialPlan__r.Id, Supplier__r.Name, Supplier__c,';
            query += ' NegoScope__r.Name, CommercialPlan__r.SellOutBDate__c, Product__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__c, CommercialPlan__c,';
            query += ' CommercialPlan__r.SellOutEDate__c, IsFromAgreementLinePrenego__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.Name, CommercialPlan__r.CommercialPlanParent__r.Id,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutBDate__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutEDate__c,';
            query += ' Product__r.Name';
            query += ' FROM CommercialPlanDetailsCP__r';
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            year = year != null ? year : System.today().year();
            if (promoSettings.numberOfMonthN1 != null) {
            WhereClause += ' WHERE (CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
                WhereClause += ' OR (' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' >= ' + String.valueOf(Date.newInstance(year, 1, 1)).removeEnd(' 00:00:00');
                WhereClause += ' AND ' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' <= ' + String.valueOf(Date.newInstance(year + 1, promoSettings.numberOfMonthN1, Date.daysInMonth(year + 1, promoSettings.numberOfMonthN1))).removeEnd(' 00:00:00') + '))';
            } else {
                WhereClause += ' WHERE CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
            }
            if (cpId != null) {
                WhereClause += ' AND CommercialPlan__c = \'' + cpId + '\'';
            }
            List<String> conditions = new List<String>();
            if (filtered != null && String.isNotBlank(filtered)) {
                conditions.addAll(getConditionsofUserFilterData(filtered));
            }
            conditions.addAll(getConditionsofFilterData(filterData));
            if (conditions != null && !conditions.isEmpty()) {
                WhereClause += ' AND ' + String.join(conditions, ' AND ');
            }
            query += WhereClause;
            query += ' ORDER BY ' + SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName();
            query += cpId == null ? ' LIMIT 2 )' : ' )';
            query += ' FROM CommercialPlan__c';
            query += ' ORDER BY Name';
            system.debug('query inside filtered is ' + query);
            List<CommercialPlan__c> commercialPlanList = Database.query(query);
            Schema.DescribeSObjectResult parentDescribe = Schema.getGlobalDescribe().get(SObjectType.CommercialPlan__c.Name).getDescribe();
            List<Id> productIds = new List<Id>();
            Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
            List<CommercialPlanDetail__c> cpdList = new List<CommercialPlanDetail__c>();
            List<String> parentCPIdList = new List<String>();
            for (CommercialPlan__c cp : commercialPlanList) {
                if (cp.CommercialPlanDetailsCP__r.size() != 0) {
                    parentCPIdList.add(String.valueOf(cp.Id));
                    Set<Id> contentDocsLinksIds = new Set<Id>();
                    for (CommercialPlanDetail__c item : cp.CommercialPlanDetailsCP__r) {
                        if (item.Product__c != null) {
                            productIds.add(item.Product__c);
                        }
                    }
                    cpList.add(cp);
                    cpdList.addAll(cp.CommercialPlanDetailsCP__r);
                }
            }
            String queryCount = 'SELECT Count(Id) cpdCount, CommercialPlan__r.Id FROM CommercialPlanDetail__c ';
            queryCount += WhereClause;
            queryCount += ' AND CommercialPlan__r.Id IN (\'' + String.join(parentCPIdList, '\',\'') +'\') GROUP BY CommercialPlan__r.Id';
            List<AggregateResult> CPDCount = Database.query(queryCount);
            Map<String, Integer> cpdCountMap = new Map<String, Integer>();
            String parentFieldName = SObjectType.CommercialPlan__c.fields.Id.getName();
            for (AggregateResult cpd : CPDCount) {
                cpdCountMap.put(String.valueOf(cpd.get(parentFieldName)), Integer.valueOf(cpd.get('cpdCount')));
            }
            if(!productIds.isEmpty()) {
                srcImagesMap = getSrcImagesMap(productIds);
            }
            Integer totalCPSize = 0;
            if (cpId == null) {
                CommercialPlanWrapper wCommercialPlan = (CommercialPlanWrapper) JSON.deserialize(getCommercialPlanData(pageSize, pageNumber, null, WhereClause, year), CommercialPlanWrapper.class);
                cpList.addAll(wCommercialPlan.commercialPlanList);
                totalCPSize = wCommercialPlan.total;
            }
            filteredMainWrapper result = new filteredMainWrapper(cpList, new CPDMainWrapper(cpdList, JSON.serialize(srcImagesMap), cpdList.size()), cpdCountMap);
            result.total = totalCPSize;
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }

    @AuraEnabled(cacheable=false)
    public static string getCPData(String comPlanId) {
        try {
            List<String> fields = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDate__c.getName()
            };
            string query;
            query = 'SELECT Id, Name, SellOutBDate__c, SellOutEDate__c ';
            query += ' FROM CommercialPlan__c';
            query += ' WHERE Id = \'' + comPlanId + '\'';
            CommercialPlan__c commericalPlan = Database.query(query);
            return JSON.serialize(commericalPlan);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static string getCommercialPlanDetailData(String comPlanId, Integer pageSize, Integer pageNumber, String filtered, String filterData, Integer year) {
        try {
            List<CommercialPlanDetail__c> commercialPlanDetailList = new List<CommercialPlanDetail__c>();
            Integer cpdCount = 0;
            List<String> fields = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDate__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.Status__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDateCP__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDateCP__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.Supplier__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.OpType__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.IsFromAgreementLinePrenego__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.NegoScope__c.getName()
            };
            string query;
            query = 'SELECT Id, Name, SellOutEDate__c, SellOutBDate__c, CreatedById, CreatedBy.Name, toLabel(Status__c), SellOutBDateCP__c, SellOutEDateCP__c,';
            query += ' CommercialPlan__r.Name,CommercialPlan__r.Id, Supplier__r.Name, Supplier__c,Product__c,';
            query += ' NegoScope__r.Name, CommercialPlan__r.SellOutBDate__c,';
            query += ' CommercialPlan__r.SellOutEDate__c, toLabel(OpType__c), IsFromAgreementLinePrenego__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.Name, CommercialPlan__r.CommercialPlanParent__r.Id,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutBDate__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutEDate__c,';
            query += ' Product__r.Name';
            query += ' FROM CommercialPlanDetail__c';
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            year = year != null ? year : System.today().year();
            if (promoSettings.numberOfMonthN1 != null) {
                query += ' WHERE (CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
                query += ' OR (' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' >= ' + String.valueOf(Date.newInstance(year, 1, 1)).removeEnd(' 00:00:00');
                query += ' AND ' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' <= ' + String.valueOf(Date.newInstance(year + 1, promoSettings.numberOfMonthN1, Date.daysInMonth(year + 1, promoSettings.numberOfMonthN1))).removeEnd(' 00:00:00') + '))';
            } else {
                query += ' WHERE CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
            }
            if (String.isNotBlank(comPlanId)) {
                query += ' AND CommercialPlan__r.CommercialPlanParent__c = \'' + comPlanId + '\'';
            }
            List<String> conditions = new List<String>();
            if (filtered != null && String.isNotBlank(filtered)) {
                conditions.addAll(getConditionsofUserFilterData(filtered));
            }
            conditions.addAll(getConditionsofFilterData(filterData));
            if (conditions != null && !conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            /*else {
                query += ' ORDER BY CommercialPlanParent__r.Name';
            }*/
            query += ' ORDER BY ' + SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName();
            query += ' LIMIT 10000';
            system.debug('getCommercialPlanDetailData query>> ' + query);
            ApexPages.StandardSetController cpdLocator = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            cpdCount = cpdLocator.getResultSize();
            cpdLocator.setPageSize(pageSize);
            cpdLocator.setPageNumber(pageNumber);//pageNumber
            commercialPlanDetailList = cpdLocator.getRecords();
            // img
            Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
            Set<Id> contentDocsLinksIds = new Set<Id>();
            List<Id> productIds = new List<Id>();

            for (CommercialPlanDetail__c item : commercialPlanDetailList) {
                if (item.Product__c != null) {
                    productIds.add(item.Product__c);
                }
            }
            List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink> ();
            if(!productIds.isEmpty()) {
                srcImagesMap = getSrcImagesMap(productIds);
            }
            CPDMainWrapper wCPDMainWrapper = new CPDMainWrapper(commercialPlanDetailList, JSON.serialize(srcImagesMap), cpdCount);
            return JSON.serialize(wCPDMainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static string getCampaginCPDData(String comPlanId, String filtered, String filterData, Integer year) {
        try {
            List<CommercialPlanDetail__c> commercialPlanDetailList = new List<CommercialPlanDetail__c>();
            Integer cpdCount = 0;
            string query;
            List<String> fields = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDate__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.Status__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutBDateCP__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.SellOutEDateCP__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.Supplier__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.OpType__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.IsFromAgreementLinePrenego__c.getName(),
                SObjectType.CommercialPlanDetail__c.fields.NegoScope__c.getName()
            };
            query = 'SELECT Id, Name, CreatedById, CreatedBy.Name, toLabel(Status__c), SellOutBDate__c, SellOutEDate__c,';
            query += ' Supplier__r.Name, Supplier__c, NegoScope__r.Name, IsFromAgreementLinePrenego__c, Product__c, OpName__c,';
            query += ' CommercialPlanParent__r.Name,CommercialPlanParent__r.Id, CommercialPlanParent__r.SellOutBDate__c, CommercialPlanParent__r.SellOutEDate__c, Product__r.Name';
            query += ' FROM CommercialPlanDetail__c WHERE ';
            if (comPlanId != null) {
                query += 'CommercialPlanParent__c = \'' + comPlanId + '\' AND ';
            }
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            year = year != null ? year : System.today().year();
            if (promoSettings.numberOfMonthN1 != null) {
                query += ' (CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
                query += ' OR (' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' >= ' + String.valueOf(Date.newInstance(year, 1, 1)).removeEnd(' 00:00:00');
                query += ' AND ' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' <= ' + String.valueOf(Date.newInstance(year + 1, promoSettings.numberOfMonthN1, Date.daysInMonth(year + 1, promoSettings.numberOfMonthN1))).removeEnd(' 00:00:00') + '))';
            } else {
                query += ' CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
            }
            List<String> conditions = new List<String>();
            if (filtered != null && String.isNotBlank(filtered)) {
                conditions.addAll(getConditionsofUserFilterData(filtered));
            }
            conditions.addAll(getConditionsofFilterData(filterData));
            if (conditions != null && !conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            /*else {
                query += ' ORDER BY CommercialPlan__r.Name';
            }*/
            query += ' ORDER BY ' + SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName();
            query += ' LIMIT 10000';
            System.debug('>>>query ' + query);
            commercialPlanDetailList = Database.query(query);

            // img
            Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
            Set<Id> contentDocsLinksIds = new Set<Id>();
            List<Id> productIds = new List<Id>();

            for (CommercialPlanDetail__c item : commercialPlanDetailList) {
                if (item.Product__c != null) {
                    productIds.add(item.Product__c);
                }
            }
            List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink> ();

            if(!productIds.isEmpty()) {
                srcImagesMap = getSrcImagesMap(productIds);
            }
            CPDMainWrapper wCPDMainWrapper = new CPDMainWrapper(commercialPlanDetailList, JSON.serialize(srcImagesMap), cpdCount);
            return JSON.serialize(wCPDMainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static string getOperationCPD(String comPlanId, String operationId, String filtered, String filterData, Integer year) {
        try {
            List<CommercialPlanDetail__c> commercialPlanDetailList = new List<CommercialPlanDetail__c>();
            Integer cpdCount = 0;
            string query;
            query = 'SELECT Id, Name, CreatedById, CreatedBy.Name, toLabel(Status__c), SellOutBDate__c, OpName__c, SellOutEDate__c,';
            query += ' CommercialPlan__r.Name,CommercialPlan__r.Id, Supplier__r.Name, Supplier__c,';
            query += ' NegoScope__r.Name, CommercialPlan__r.SellOutBDate__c, Product__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__c, CommercialPlan__c,';
            query += ' CommercialPlan__r.SellOutEDate__c, IsFromAgreementLinePrenego__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.Name, CommercialPlan__r.CommercialPlanParent__r.Id,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutBDate__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutEDate__c,';
            query += ' Product__r.Name';
            query += ' FROM CommercialPlanDetail__c';
            PromoSettings promoSettings = PromoSettings.loadPromoSettings();
            year = year != null ? year : System.today().year();
            if (promoSettings.numberOfMonthN1 != null) {
                query += ' WHERE (CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
                query += ' OR (' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' >= ' + String.valueOf(Date.newInstance(year, 1, 1)).removeEnd(' 00:00:00');
                query += ' AND ' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ' <= ' + String.valueOf(Date.newInstance(year + 1, promoSettings.numberOfMonthN1, Date.daysInMonth(year + 1, promoSettings.numberOfMonthN1))).removeEnd(' 00:00:00') + '))';
            } else {
                query += ' WHERE CALENDAR_YEAR(' + SObjectType.CommercialPlan__c.fields.SellOutBDate__c.getName() + ') =' + year;
            }
            query += ' AND CommercialPlan__r.CommercialPlanParent__c = \'' + comPlanId + '\'';
            query += ' AND CommercialPlan__c = \'' + operationId + '\'';
            List<String> conditions = new List<String>();
            if (filtered != null && String.isNotBlank(filtered)) {
                conditions.addAll(getConditionsofUserFilterData(filtered));
            }
            conditions.addAll(getConditionsofFilterData(filterData));
            if (conditions != null && !conditions.isEmpty()) {
                query += ' AND ' + String.join(conditions, ' AND ');
            }
            /*else {
                query += ' ORDER BY CommercialPlan__r.Name';
            }*/
            query += ' ORDER BY ' + SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName();
            query += ' LIMIT 10000';
            system.debug('query >>> ' + query);
            commercialPlanDetailList = Database.query(query);
            // img
            Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
            Set<Id> contentDocsLinksIds = new Set<Id>();
            List<Id> productIds = new List<Id>();

            for (CommercialPlanDetail__c item : commercialPlanDetailList) {
                if (item.Product__c != null) {
                    productIds.add(item.Product__c);
                }
            }
            List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink> ();

            if(!productIds.isEmpty()) {
                srcImagesMap = getSrcImagesMap(productIds);
            }
            CPDMainWrapper wCPDMainWrapper = new CPDMainWrapper(commercialPlanDetailList, JSON.serialize(srcImagesMap), cpdCount);
            return JSON.serialize(wCPDMainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    private static List<String> getConditionsofUserFilterData(String filtered) {
        List<FilterWrapper> wFilterWrapperList = filtered != null && String.isNotBlank(filtered) ? (List<FilterWrapper>) JSON.deserialize(filtered, List<FilterWrapper>.class) : new List<FilterWrapper>();
        List<String> conditions = new List<String>();
        if (!wFilterWrapperList.isEmpty()) {
            for (FilterWrapper wFilterWrapper : wFilterWrapperList) { 
                if (wFilterWrapper.isPicklist && !wFilterWrapper.picklistValue.isEmpty()) {
                    if (wFilterWrapper.fieldApiName == 'RecordTypeId') {
                        conditions.add('RecordType.DeveloperName IN (\'' + String.join(wFilterWrapper.picklistValue, '\',\'') +'\')');
                    } else {
                        conditions.add(wFilterWrapper.fieldApiName + ' IN (\'' + String.join(wFilterWrapper.picklistValue, '\',\'') +'\')');
                    }
                }
                if (wFilterWrapper.isBoolean) {
                    conditions.add(wFilterWrapper.fieldApiName + ' = ' + wFilterWrapper.value);
                }
                if ((wFilterWrapper.isReference) && String.isNotBlank(wFilterWrapper.value)) {
                    conditions.add(wFilterWrapper.fieldApiName + ' IN (\'' + String.join(wFilterWrapper.value.split(','), '\',\'') +'\')');
                }
                if (wFilterWrapper.isText && String.isNotBlank(wFilterWrapper.value)) {
                    if (wFilterWrapper.isEncrypted) {
                        conditions.add(wFilterWrapper.fieldApiName + ' = \'' + wFilterWrapper.value + '\'');
                    } else {
                        conditions.add(wFilterWrapper.fieldApiName + ' LIKE \'%' + wFilterWrapper.value + '%\'');
                    }
                }
                String value0 = wFilterWrapper.values != null && !wFilterWrapper.values.isEmpty() ? wFilterWrapper.values[0] : null;
                String value1 = wFilterWrapper.values != null && !wFilterWrapper.values.isEmpty() ? wFilterWrapper.values[1] : null;
                if ((wFilterWrapper.isPercent || wFilterWrapper.isDouble || wFilterWrapper.isDate || wFilterWrapper.isDateTime) 
                    && String.isNotBlank(value0) && String.isNotBlank(value1))
                {
                    String conditon = wFilterWrapper.fieldApiName + ' >= ' + value0 + ' AND ' + wFilterWrapper.fieldApiName + ' <= ' + value1;
                    conditions.add(conditon);
                }
                else if ((wFilterWrapper.isPercent || wFilterWrapper.isDouble || wFilterWrapper.isDate || wFilterWrapper.isDateTime)
                    && String.isNotBlank(value0) && String.isBlank(value1))
                {
                    String conditon = wFilterWrapper.fieldApiName + ' >= ' + value0;
                    conditions.add(conditon);
                }
                else if ((wFilterWrapper.isPercent || wFilterWrapper.isDouble || wFilterWrapper.isDate || wFilterWrapper.isDateTime)
                    && String.isBlank(value0) && String.isNotBlank(value1) )
                {
                    String conditon = wFilterWrapper.fieldApiName + ' <= ' +value1;
                    conditions.add(conditon);
                }
            }
        }
        return conditions;
    }
    
    private static List<String> getConditionsofFilterData(String filterData) {
        List<String> conditions = new List<String>();
        if (filterData != null && String.isNotBlank(filterData)) {
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            Object filterObject = JSON.deserializeUntyped(filterData);
            List<Object> filtersObjectsList = (List<Object>) filterObject;
            for (Object objt : filtersObjectsList) {
                Map<String, Object> item = (Map<String, Object>)objt;
                String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                if (fieldName != null) {
                    String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                    String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                    boolean isEncrypted = item.containsKey('isEncrypted') ? Boolean.valueOf(item.get('isEncrypted')) : null;
                    String stringFieldType = item.containsKey('stringFieldType') ? String.valueOf(item.get('stringFieldType')) : null;
                    List<String> values = new List<String>();
                    if(item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                        List<Object> tempValues = (List<Object>) item.get('values');
                        for (Object val : tempValues) {
							values.add(String.valueOf(val));
						}
                    }
                    Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                    if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                        filterSettings.add(new FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                    }
                }
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for (FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
        }
        return conditions;
    }
    
    @AuraEnabled(cacheable=false)
    public static string getSpecificCPD(String cpdId) {
        try {
            string query;
            query = 'SELECT Id, Name, CreatedById, CreatedBy.Name, toLabel(Status__c), SellOutBDate__c, SellOutEDate__c,';
            query += ' CommercialPlan__r.Name,CommercialPlan__r.Id, Supplier__r.Name, Supplier__c,';
            query += ' NegoScope__r.Name, CommercialPlan__r.SellOutBDate__c, Product__c,';
            query += ' CommercialPlan__r.SellOutEDate__c, IsFromAgreementLinePrenego__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.Name, CommercialPlan__r.CommercialPlanParent__r.Id,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutBDate__c,';
            query += ' CommercialPlan__r.CommercialPlanParent__r.SellOutEDate__c,';
            query += ' Product__r.Name';
            query += ' FROM CommercialPlanDetail__c';
            query += ' WHERE Id = \'' + cpdId + '\'';
            query += ' ORDER BY ' + SObjectType.CommercialPlanDetail__c.fields.SellOutBDate__c.getName();
            System.debug('>>>>>>getSpecificCPD ' + query);
            List<CommercialPlanDetail__c> commercialPlanDetailList = Database.query(query);
            // img
            Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
            Set<Id> contentDocsLinksIds = new Set<Id>();
            List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink> ();
            Id productId = commercialPlanDetailList[0].Product__c;
            if (productId != null) {
                srcImagesMap = getSrcImagesMap(new List<Id>{productId});
            }
            CPDMainWrapper wCPDMainWrapper = new CPDMainWrapper(commercialPlanDetailList, JSON.serialize(srcImagesMap), 0);
            return JSON.serialize(wCPDMainWrapper);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }
    
    private static Map<Id, List<String>> getSrcImagesMap(List<Id> productIds) {
        Map<Id, List<Id>> CDLinkMap = new Map<Id, List<Id>> ();
        List<ContentDocumentLink> ContentDocumentLinkList = new List<ContentDocumentLink>();
        Map<Id, String> CDLinkStrMap = new Map<Id, String>();
        String SERVER_URL = URL.getOrgDomainUrl().toExternalForm();
        Map<Id, List<String>> srcImagesMap = new Map<Id, List<String>>();
        for (ContentDocumentLink link : [SELECT Id, LinkedEntityId, ContentDocumentId
                                         FROM ContentDocumentlink
                                         WHERE LinkedEntityId IN :productIds
                                         AND ContentDocument.FileType IN ('JPG' ,'png' ,'GIF' ,'WEBP' ,'TIFF' ,'PSD' ,'RAW' ,'BMP' ,'HEIF' ,'INDD' ,'JPEG 2000')
                                         ORDER BY ContentDocument.CreatedDate])
        {
            if (!CDLinkMap.containsKey(link.LinkedEntityId)) {
                CDLinkMap.put(link.LinkedEntityId, new List<Id> ());
            }
            CDLinkMap.get(link.LinkedEntityId).add(link.ContentDocumentId);
            ContentDocumentLinkList.add(link);
        }
        for (Id cdl : CDLinkMap.keySet()) {
            CDLinkStrMap.put(cdl, String.join(CDLinkMap.get(cdl), ','));// cpd => list of cd link
        }
        for (ContentDocumentLink link : ContentDocumentLinkList) {
            if (!srcImagesMap.containsKey(link.LinkedEntityId)) {
                // cpd, list of cds Sting, cd[0] , link url
                srcImagesMap.put(link.LinkedEntityId, new List<String> {CDLinkStrMap.get(link.LinkedEntityId), (String)link.ContentDocumentId, SERVER_URL + '/sfc/servlet.shepherd/document/download/' + link.ContentDocumentId});
            }
        }
        return srcImagesMap;
    }
    
    public class FieldWrapper {
        public String fieldLabel {get;set;}
        public String fieldName {get;set;}
        public String fieldType {get;set;}
        public Boolean isLookUp {get;set;}

        public FieldWrapper(String fieldLabel, String fieldName, String fieldType, Boolean isLookUp) {
            this.fieldLabel = fieldLabel;
            this.fieldName = fieldName;
            this.fieldType = fieldType;
            this.isLookUp = isLookUp;
        }
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public Integer numberOfMonthN1 {get; set;}
        public List<FieldWrapper> wFieldWrapperList {get; set;}

        public MainWrapper(GridSettingsManager gridSettingsManager, List<FieldWrapper> wFieldWrapperList) {
            this.gridSettingsManager = gridSettingsManager;
            this.wFieldWrapperList = wFieldWrapperList;

        }
    }
    
    public class CommercialPlanWrapper {
        public List<CommercialPlan__c> commercialPlanList {get; set;}
        public Integer total {get; set;}
        public CommercialPlanWrapper(List<CommercialPlan__c> commercialPlanList, Integer total) {
            this.commercialPlanList = commercialPlanList;
            this.total = total;
        }
    }

    public class CPDMainWrapper {
        public Integer cpdSize {get; set;}
        public List<CommercialPlanDetail__c> commercialDetailList {get; set;}
        public String srcImagesMap {get; set;}
        public CPDMainWrapper(List<CommercialPlanDetail__c> commercialDetailList, String srcImagesMap, Integer cpdSize) {
            this.commercialDetailList = commercialDetailList;
            this.srcImagesMap = srcImagesMap;
            this.cpdSize = cpdSize;
        }
    }
    public class filteredMainWrapper {
        public List<commercialPlan__c> commercialPlanList {get; set;}
        public Integer total {get; set;}
        public CPDMainWrapper CPDMainWrapper {get; set;}
        public Map<String,Integer> cpdCountMap {get; set;}
        public filteredMainWrapper(List<commercialPlan__c> commercialPlanList, CPDMainWrapper CPDMainWrapper, Map<String,Integer> cpdCountMap) {
            this.commercialPlanList = commercialPlanList;
            this.CPDMainWrapper = CPDMainWrapper;
            this.cpdCountMap = cpdCountMap;
        }
    }

    public class FilterWrapper {
        public String fieldApiName {get;set;}
        public String fieldLabel {get;set;}
        public Boolean isEncrypted {get;set;}
        public Boolean isPicklist {get;set;}
        public Boolean isDouble {get;set;}
        public Boolean isBoolean {get;set;}
        public Boolean isPercent {get;set;}
        public Boolean isText {get;set;}
        public Boolean isReference {get;set;}
        public Boolean isRT {get;set;}
        public Boolean isDate {get;set;}
        public Boolean isDateTime {get;set;}
        public String value {get;set;}
        public List<String> values {get;set;}
        public List<String> picklistValue {get;set;}
        
        public FilterWrapper() {
            
        }
    }
    public class FilterSettings {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean isEncrypted { get; set; }
        public String stringFieldType { get; set; }
        public List<SelectOption> pickListValues { get; set; }
        public String value1 { get; set; }
        public String value2 { get; set; }
        public List<String> values { get; set; }
        Boolean userFilterable { get; set; }
        public List<String> getQueryConditions() {
            try {
                List<String> conditions = new List<String>();
                if (values != null && !values.isEmpty()) {
                    if (stringFieldType == 'REFERENCE') {
                        if (fieldName.toLowerCase() == 'recordtypeid') {
                            List<String> stringifiedValues = (List<String>) JSON.deserialize(JSON.serialize(values), List<String>.class);
                            List<String> escapedStringifiedValues = new List<String>();
                            for (String value : stringifiedValues) {
                                value = value == 'Principal' || value == 'Master' ? '' : value;
                                escapedStringifiedValues.add(String.escapeSingleQuotes(value).trim());
                            }
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.DeveloperName IN (\'' + String.join(escapedStringifiedValues, '\', \'') + '\')');
                        } else {
                            if (isEncrypted == null || isEncrypted) {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                            } else {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                            }
                        }
                    }
                    if (stringFieldType == 'ID') {
                        List<Id> fieldpicklistValues = new List<Id>();
                        for (Object item : values) {
                            try {
                                fieldpicklistValues.add(Id.valueOf(String.escapeSingleQuotes(String.valueOf(item).trim())));
                            } catch (Exception ex) {
                            }
                        }
                        conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                    }
                    if (stringFieldType == 'PICKLIST' || stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'COMBOBOX' || stringFieldType == 'RECORDTYPE' || stringFieldType == 'BOOLEAN') {
                        List<String> fieldpicklistValues = new List<String>();
                        for (Object item : values) {
                            fieldpicklistValues.add(String.escapeSingleQuotes(String.valueOf(item)));
                        }
                        if (stringFieldType == 'BOOLEAN') {
                            conditions.add(fieldName + ' IN (' + String.join(fieldpicklistValues, ', ')+')');
                        } else if (stringFieldType == 'RECORDTYPE') {
                            conditions.add('RecordType.DeveloperName IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else if (stringFieldType == 'PICKLIST' || stringFieldType == 'COMBOBOX') {
                            conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else {
                            conditions.add(fieldName + ' INCLUDES (\'' + String.join(fieldpicklistValues, ';')+'\')');
                        }
                    }
                    if (stringFieldType == 'STRING') {
                        if (isEncrypted == null || isEncrypted) {
                            conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                        } else {
                            conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                        }
                    }
                }
                if (value1 != null || value2 != null) {
                    if (stringFieldType == 'CURRENCY' || stringFieldType == 'INTEGER' || stringFieldType == 'DOUBLE' || stringFieldType == 'LONG' || stringFieldType == 'PERCENT') {
                        if (value1 != null) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                    if (stringFieldType == 'DATETIME') {
                        if (value1 != null) {
                            List<String> splitedDate = String.valueOf(value1).split('-');
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                        if (value2 != null) {
                            List<String> splitedDate = String.valueOf(value2).split('-');
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                    }
                    if (stringFieldType == 'DATE') {
                        if (value1 != null && value1 != '') {
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
                        }
                        if (value2 != null && value2 != '') {
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
                        }
                    }
                    if (stringFieldType == 'TIME') {
                        if (value1 != null && value1 != '') {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null && value2 != '') {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                }
                return conditions;
            }catch (Exception ex) {
                System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
        }
        public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values, Boolean userFilterable) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isEncrypted = isEncrypted;
            // Get the SObject Describe for the object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.CommercialPlanDetail__c.Name).getDescribe();
            // Get the field describe for the specified field
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            // Get the data type of the field
            Schema.DisplayType fieldType = fieldDescribe.getType();
            this.stringFieldType = fieldType + '';
            this.pickListValues = pickListValues;
            this.value1 = value1;
            this.value2 = value2;
            this.values = values;
            this.userFilterable = userFilterable;
        }
    }
}