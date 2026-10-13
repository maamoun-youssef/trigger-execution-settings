/*
 * @author ULiT
 * @date 28-03-2024
 * @description
 * 1- case consolidate assortment details by Assortment__r.Hierarchy__c + BusinessUnitTarget__r.Supplier__c + BusinessUnitTarget__r.Country_Origin + BusinessUnitTarget__r.Format__c
 * 2- case reset assortment details
 */
public with sharing class ConsolidateAssortmentsBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Set<Id> countrySet;
    private Set<Id> buSourceSet;
    private Set<Id> categorySet;
    private Set<Id> productSet;
    private Set<Integer> yearSet;
    private Set<Id> assortmentDetailConsoIds;
    private List<String> assortmentDetailsCalculateFields;

    public ConsolidateAssortmentsBatch(){}
    public ConsolidateAssortmentsBatch(String startedFrom, Set<Id> countryIds, Set<Id> buSourceIds, Set<Id> categoryIds, Set<Id> productIds, Set<Integer> years) {
        this.nb = new NegoptimBatch(ConsolidateAssortmentsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.countrySet = countryIds;
        this.yearSet = years;
        this.buSourceSet = buSourceIds;
        this.categorySet = categoryIds;
        this.productSet = productIds;
        this.yearSet = years;
        this.assortmentDetailConsoIds = new Set<Id>();
        this.assortmentDetailsCalculateFields = new List<String>();
        Map<String, Schema.SObjectField> assortmentDetailFieldsMap = Schema.SObjectType.AssortmentDetail__c.fields.getMap();
        List<Schema.DisplayType> numberTypes = new List<Schema.DisplayType>{DisplayType.Double, DisplayType.Integer, DisplayType.Long, DisplayType.Percent, DisplayType.Currency};
        for (String fieldName : assortmentDetailFieldsMap.keySet()) {
            if (assortmentDetailFieldsMap.get(fieldName).getDescribe().isCreateable()
                && assortmentDetailFieldsMap.get(fieldName).getDescribe().isUpdateable()
                && numberTypes.contains(assortmentDetailFieldsMap.get(fieldName).getDescribe().getType())
                && fieldName != SObjectType.AssortmentDetail__c.fields.Version__c.Name)
            {
                assortmentDetailsCalculateFields.add(fieldName);
            }
        }
        String q = 'SELECT Id, Assortment__r.RecordType.DeveloperName, Product__c, Hierarchy__c, Assortment__c, StartDate__c, Version__c, Status__c, ProductLifeStatusAss__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.Supplier__c, Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c, Assortment__r.BusinessUnitSource__c,';
        q += ' Assortment__r.Hierarchy__c, Assortment__r.Year__c, Assortment__r.BusinessUnitTarget__r.Format__c,';
        q += ' Assortment__r.BDate__c, Assortment__r.EDate__c';
        if (!assortmentDetailsCalculateFields.isEmpty()) {
            q += ', ' + String.join(assortmentDetailsCalculateFields, ', ');
        }
        q += ' FROM AssortmentDetail__c';
        q += ' WHERE Assortment__r.Hierarchy__c <> NULL AND Assortment__r.BusinessUnitTarget__r.Format__c <> NULL AND Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c <> NULL';
        q += ' AND Assortment__r.BusinessUnitTarget__r.LayerNegoConso__c = FALSE';
        q += ' AND StartDate__c <> NULL AND Version__c = NULL';
        q += ' AND ((Assortment__r.RecordType.DeveloperName IN (\'Nego\', \'Simulation\') AND Assortment__r.OnTop__c = TRUE) OR Assortment__r.RecordType.DeveloperName IN (\'Target\'))';
        if (this.countrySet != null) {
            q += ' AND Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c IN (\'' + String.join(new List<Id>(countrySet), '\',\'') +'\') ';
        }
        if (this.buSourceSet != null) {
            q += ' AND Assortment__r.BusinessUnitSource__c IN (\'' + String.join(new List<Id>(buSourceSet), '\',\'') +'\') ';
        }
        if (this.categorySet != null) {
            q += ' AND Assortment__r.Hierarchy__c IN (\'' + String.join(new List<Id>(categorySet), '\',\'') +'\') ';
        }
        if (this.productSet != null) {
            q += ' AND Product__c IN (\'' + String.join(new List<Id>(productSet), '\',\'') +'\') ';
        }
        if (this.yearSet != null) {
            q += ' AND Assortment__r.Year__c  IN (' + String.join(new List<Integer>(this.yearSet), ',') + ')';
        }
        q += ' ORDER BY Status__c ASC, StartDate__c DESC, Product__c';
        this.query = q;
        nb.logParameter('query', query);
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        Set<Id> clientSet = new Set<Id>();
        Set<Id> countryOriginSet = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        Set<String> recordTypeSet = new Set<String>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> previousYearSet = new Set<Integer>();
        Map<String, BusinessUnit__c> buConsoMap = new Map<String, BusinessUnit__c>();
        Map<String, Assortment__c> assortmentBUConsoMap = new Map<String, Assortment__c>();
        Map<String, Assortment__c> parentAssortmentBUConsoMap = new Map<String, Assortment__c>();
        Map<String, AssortmentDetail__c> assortmentDetailConsoMap = new Map<String, AssortmentDetail__c>();
        Map<String, AssortmentDetail__c> parentAssortmentDetailConsoMap = new Map<String, AssortmentDetail__c>();
        Map<String, List<AssortmentDetail__c>> assortmentDetailsMap = new Map<String, List<AssortmentDetail__c>>();
        List<AssortmentConsoWrapper> assortmentConsoWrapperList = new List<AssortmentConsoWrapper>();
        List<Assortment__c> assortmentConsoList = new List<Assortment__c>();
        List<AssortmentDetail__c> assortmentDetailsUpdatedList = new List<AssortmentDetail__c>();
        
        for (AssortmentDetail__c item : scope) {
            if (!clientSet.contains(item.Assortment__r.BusinessUnitTarget__r.Supplier__c)) {
                clientSet.add(item.Assortment__r.BusinessUnitTarget__r.Supplier__c);
            }
            if (item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c != null && !countryOriginSet.contains(item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c)) {
                countryOriginSet.add(item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c);
            }
            if (!buSourceSet.contains(item.Assortment__r.BusinessUnitSource__c)) {
                buSourceSet.add(item.Assortment__r.BusinessUnitSource__c);
            }
            if (!categorySet.contains(item.Assortment__r.Hierarchy__c)) {
                categorySet.add(item.Assortment__r.Hierarchy__c);
            }
            if (!productSet.contains(item.Product__c)) {
                productSet.add(item.Product__c);
            }
            if ((item.Assortment__r.RecordType.DeveloperName == 'Nego' || item.Assortment__r.RecordType.DeveloperName == 'Simulation') && !recordTypeSet.contains('onTopConso')) {
                recordTypeSet.add('onTopConso');
            } else if (item.Assortment__r.RecordType.DeveloperName == 'Target' && !recordTypeSet.contains('TargetConso')) {
                recordTypeSet.add('TargetConso');
            }
            if (!yearSet.contains(Integer.valueOf(item.Assortment__r.Year__c))) {
                yearSet.add(Integer.valueOf(item.Assortment__r.Year__c));
                previousYearSet.add(Integer.valueOf(item.Assortment__r.Year__c) - 1);
            }
            String key = (item.Assortment__r.RecordType.DeveloperName == 'Target' ? item.Assortment__r.RecordType.DeveloperName : '') + item.Assortment__r.BusinessUnitSource__c + '' + item.Assortment__r.Hierarchy__c + '' + item.Assortment__r.BusinessUnitTarget__r.Supplier__c + '' +
                item.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(item.Assortment__r.BusinessUnitTarget__r.Format__c) + '' + Integer.valueOf(item.Assortment__r.Year__c);
            if (!assortmentDetailsMap.containsKey(key)) {
                assortmentDetailsMap.put(key, new List<AssortmentDetail__c>{item});
            } else {
                assortmentDetailsMap.get(key).add(item);
            }
        }
        // get BU conso
        if(!clientSet.isEmpty() && !countryOriginSet.isEmpty()) {
            // check security on BusinessUnit__c fields
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.Supplier__c.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.Format__c.Name,
                SObjectType.BusinessUnit__c.fields.LayerNegoConso__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP2__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP1__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
                for (BusinessUnit__c item : [SELECT Id, Name, BusinessUnitCountryOrigin__c, Format__c, Supplier__c,
                                                       WeightedDistributionManualP2__c, WeightedDistributionManualP1__c, WeightedDistributionManual__c, WeightedDistributionManualN1__c
                                                       FROM BusinessUnit__c
                                                       WHERE Supplier__c IN :clientSet
                                                       AND BusinessUnitCountryOrigin__c IN : countryOriginSet
                                                       AND LayerNegoConso__c = TRUE
                                                       AND Format__c <> NULL])
                {
                    String keyBU = item.Supplier__c + '' + item.BusinessUnitCountryOrigin__c  + '' + getSortedFormatOrigin(item.Format__c);
                    buConsoMap.put(keyBU, item);
                }
            }
        }
        
        // get Assortment conso
        if(!buSourceSet.isEmpty() && !yearSet.isEmpty()) {
            Set<Id> assortmentBUConsoSet = new Set<Id>();
            for(Assortment__c item : [SELECT Id, BusinessUnitSource__c, BusinessUnitTarget__c, Hierarchy__c, BusinessUnitSource__r.Supplier__c,
                                      BusinessUnitSource__r.BusinessUnitCountryOrigin__c, RecordType.DeveloperName, BusinessUnitTarget__r.Supplier__c, BusinessUnitTarget__r.BusinessUnitCountryOrigin__c,
                                      BusinessUnitTarget__r.Format__c, Year__c,
                                      (SELECT Id, Product__c
                                       FROM ASDAssortment__r
                                       WHERE Product__c IN :productSet)
                                      FROM Assortment__c
                                      WHERE BusinessUnitSource__c IN :buSourceSet
                                      AND Hierarchy__c IN :categorySet
                                      AND (Year__c IN :yearSet OR Year__c IN :previousYearSet)
                                      AND RecordType.DeveloperName IN :recordTypeSet
                                      AND Status__c = 'Validate'])
            {
                String recordType = item.RecordType.DeveloperName == 'TargetConso' ? 'Target' : '';
                String key = recordType + '' + item.BusinessUnitSource__c + '' + item.Hierarchy__c + '' + item.BusinessUnitTarget__r.Supplier__c + '' +
                    item.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(item.BusinessUnitTarget__r.Format__c) + '' + Integer.valueOf(item.Year__c);
                if (yearSet.contains(Integer.valueOf(item.Year__c))) {
                    assortmentBUConsoMap.put(key, item);
                    // get assortment details conso
                    for (AssortmentDetail__c detail : item.ASDAssortment__r) {
                        String keyDetail = key + '' + detail.Product__c;
                        assortmentDetailConsoMap.put(keyDetail, detail);
                    }
                } else if (previousYearSet.contains(Integer.valueOf(item.Year__c))) {
                    // get parent assortment conso
                    parentAssortmentBUConsoMap.put(key, item);
                    for (AssortmentDetail__c detail : item.ASDAssortment__r) {
                        String keyDetail = key + '' + detail.Product__c;
                        parentAssortmentDetailConsoMap.put(keyDetail, detail);
                    }
                }
            }
        }
        
        for (String key : assortmentDetailsMap.keySet()) {
            AssortmentConsoWrapper wAssortmentConso = new AssortmentConsoWrapper();
            // insert assortment BU Conso
            Assortment__c assortmentBUConso;
            AssortmentDetail__c firstAssortmentDetail = assortmentDetailsMap.get(key)[0];
            String recordType = firstAssortmentDetail.Assortment__r.RecordType.DeveloperName;
            // Parent always the ontopConso N - 1
            String keyParentAssortment = firstAssortmentDetail.Assortment__r.BusinessUnitSource__c + '' + firstAssortmentDetail.Assortment__r.Hierarchy__c + '' +
                firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.Supplier__c + '' + firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c + '' +
                getSortedFormatOrigin(firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.Format__c) + '' + (Integer.valueOf(firstAssortmentDetail.Assortment__r.Year__c) - 1);
            // get BU Conso
            String keyBU = firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.Supplier__c + '' + firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c + '' +
                getSortedFormatOrigin(firstAssortmentDetail.Assortment__r.BusinessUnitTarget__r.Format__c);
            if(!buConsoMap.containsKey(keyBU)) continue;
            BusinessUnit__c buConso = buConsoMap.get(keyBU);
            Id recordTypeId = recordType == 'Nego' || recordType == 'Simulation' ? NegoptimHelper.getObjectRecordTypeId(Assortment__c.SObjectType, 'OnTopConso') : NegoptimHelper.getObjectRecordTypeId(Assortment__c.SObjectType, 'TargetConso');
            String name = recordType == 'Nego' || recordType == 'Simulation' ? 'OnTopConso - ' : 'TargetConso - ';
            if(!assortmentBUConsoMap.containsKey(key)) {
                assortmentBUConso = new Assortment__c(Name = name + buConso.Name + ' - ' + firstAssortmentDetail.Assortment__r.Year__c,
                                                      BusinessUnitSource__c = firstAssortmentDetail.Assortment__r.BusinessUnitSource__c,
                                                      BusinessUnitTarget__c = buConso.Id,
                                                      Hierarchy__c = firstAssortmentDetail.Assortment__r.Hierarchy__c,
                                                      BDate__c = firstAssortmentDetail.Assortment__r.BDate__c,
                                                      EDate__c = firstAssortmentDetail.Assortment__r.EDate__c,
                                                      Year__c = firstAssortmentDetail.Assortment__r.Year__c,
                                                      Status__c = 'Validate',
                                                      RecordTypeId = recordTypeId);
                assortmentBUConso.AssortmentNegotiationRef__c = parentAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentAssortmentBUConsoMap.get(keyParentAssortment).Id : null;
                assortmentBUConsoMap.put(key, assortmentBUConso);
            } else {
                assortmentBUConso = assortmentBUConsoMap.get(key);
                if(assortmentBUConso.AssortmentNegotiationRef__c == null) {
                    assortmentBUConso.AssortmentNegotiationRef__c = parentAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentAssortmentBUConsoMap.get(keyParentAssortment).Id : null;
                    wAssortmentConso.isUpdated = true;
                }
            }
            // insert assortment detail conso
            for(AssortmentDetail__c assortmentDetail : assortmentDetailsMap.get(key)) {
                String keyDetail = key + '' + assortmentDetail.Product__c;
                String keyParentAssortmentDetail = assortmentDetail.Assortment__r.BusinessUnitSource__c + '' + assortmentDetail.Assortment__r.Hierarchy__c + '' + assortmentDetail.Assortment__r.BusinessUnitTarget__r.Supplier__c + '' + 
                    assortmentDetail.Assortment__r.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(assortmentDetail.Assortment__r.BusinessUnitTarget__r.Format__c) + '' + (Integer.valueOf(assortmentDetail.Assortment__r.Year__c) - 1) + '' + 
                    assortmentDetail.Product__c;
                AssortmentDetail__c assortmentDetailConso;
                if(!assortmentDetailConsoMap.containsKey(keyDetail)) {
                    assortmentDetailConso = new AssortmentDetail__c(Assortment__c = assortmentBUConso.Id,
                                                                    Hierarchy__c = assortmentDetail.Hierarchy__c,
                                                                    Product__c = assortmentDetail.Product__c,
                                                                    StartDate__c = assortmentDetail.StartDate__c,
                                                                    ProductLifeStatusAss__c = assortmentDetail.ProductLifeStatusAss__c);
                    assortmentDetailConso.AssortmentDetailNegotiationRef__c = parentAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                } else {
                    assortmentDetailConso = assortmentDetailConsoMap.get(keyDetail);
                    if(assortmentDetailConso.AssortmentDetailNegotiationRef__c == null)
                        assortmentDetailConso.AssortmentDetailNegotiationRef__c = parentAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                }
                // reset assortment details conso in first load
                if (assortmentDetailConso.Id != null && !this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                    for (String field : assortmentDetailsCalculateFields) {
                        if (assortmentDetailConso.get(field) != null) {
                            assortmentDetailConso.put(field, null);
                        }
                    }
                    // clear movement date case status=In Preparation
                    assortmentDetailConso.StartDate__c = null;
                    assortmentDetailConso.ProductLifeStatusAss__c = null;
                    this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                }
                if (assortmentDetail.StartDate__c != null && (assortmentDetailConso.StartDate__c == null || assortmentDetailConso.StartDate__c < assortmentDetail.StartDate__c)) {
                    // add max movement date in assortment detail conso
                    assortmentDetailConso.StartDate__c = assortmentDetail.StartDate__c;
                    assortmentDetailConso.ProductLifeStatusAss__c = assortmentDetail.ProductLifeStatusAss__c;
                }
                // calculate new values
                for (String fieldName : assortmentDetailsCalculateFields) {
                    decimal value = 0;
                    if (assortmentDetailConso.get(fieldName) != null) {
                        value = Decimal.valueOf(String.valueOf(assortmentDetailConso.get(fieldName)));
                    }
                    if (assortmentDetail.get(fieldName) != null) {
                        value += Decimal.valueOf(String.valueOf(assortmentDetail.get(fieldName)));
                        assortmentDetailConso.put(fieldName, value);
                    }
                }
                if (!wAssortmentConso.assortmentDetailsLinkedMap.containsKey(assortmentDetail.Product__c)) {
                    wAssortmentConso.assortmentDetailsLinkedMap.put(assortmentDetail.Product__c, new List<AssortmentDetail__c>{assortmentDetail});
                } else {
                    wAssortmentConso.assortmentDetailsLinkedMap.get(assortmentDetail.Product__c).add(assortmentDetail);
                }
                assortmentDetailConsoMap.put(keyDetail, assortmentDetailConso);
                wAssortmentConso.assortmentDetailsConsoMap.put(assortmentDetail.Product__c, assortmentDetailConso);
            }
            wAssortmentConso.assortmentBUConso = assortmentBUConso;
            assortmentConsoWrapperList.add(wAssortmentConso);
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on Assortment__c fields
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Name.Name,
                    SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
                    SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
                    SObjectType.Assortment__c.fields.Hierarchy__c.Name,
                    SObjectType.Assortment__c.fields.BDate__c.Name,
                    SObjectType.Assortment__c.fields.EDate__c.Name,
                    SObjectType.Assortment__c.fields.Year__c.Name,
                    SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name,
                    SObjectType.Assortment__c.fields.Status__c.Name
                    };
            // check security on AssortmentDetail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                    SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name,
                    SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
                    };
            String[] assortmentDetailInsertFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name
                    };
            assortmentDetailFields.addAll(assortmentDetailsCalculateFields);
            assortmentDetailInsertFields.addAll(assortmentDetailFields);

            for (AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                if(item.assortmentBUConso.Id == null || item.isUpdated) {
                    assortmentConsoList.add(item.assortmentBUConso);
                }
            }
            if(NegoptimHelper.checkCreatibility(Assortment__c.SObjectType, assortmentBUFields) &&
               NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailInsertFields) &&
               NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields))
            {
                // upsert assortment BU conso
                if(!assortmentConsoList.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentConsoList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Assortment__c assortmentBUConso = assortmentConsoList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = result.Id != null ? assortmentBUConso.Name + '(' + result.Id + ') : ' : String.valueOf(assortmentBUConso) + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        }
                    }
                }
                // upsert assortment details conso
                Map<Id, AssortmentConsoWrapper> assortmentConsoWrapperMap = new Map<Id, AssortmentConsoWrapper>();
                List<AssortmentDetail__c> assortmentDetailConsoList = new List<AssortmentDetail__c>();
                for(AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                    if(item.assortmentBUConso.Id != null) {
                        for(AssortmentDetail__c assortmentDetailConso : item.assortmentDetailsConsoMap.values()) {
                            for(String field : assortmentDetailsCalculateFields) {
                                decimal value = 0;
                                if(assortmentDetailConso.get(field) != null) {
                                    value = Decimal.valueOf(String.valueOf(assortmentDetailConso.get(field)));
                                    value = value.setScale(1, System.RoundingMode.HALF_DOWN);
                                    assortmentDetailConso.put(field, value);
                                }
                            }
                            if(assortmentDetailConso.Assortment__c == null) assortmentDetailConso.Assortment__c = item.assortmentBUConso.Id;
                        }
                        assortmentConsoWrapperMap.put(item.assortmentBUConso.Id, item);
                        assortmentDetailConsoList.addAll(item.assortmentDetailsConsoMap.values());
                    }
                }
                if(!assortmentDetailConsoList.isEmpty()) {
                    List<Database.UpsertResult> resultsDetail = Database.upsert(assortmentDetailConsoList, false);
                    for (Integer i = 0; i < resultsDetail.size(); i++) {
                        Database.UpsertResult result = resultsDetail.get(i);
                        AssortmentDetail__c assortmentDetailConso = assortmentDetailConsoList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        } else {
                            AssortmentConsoWrapper assortmentConsoWrapper = assortmentConsoWrapperMap.get(assortmentDetailConso.Assortment__c);
                            assortmentDetailsUpdatedList.addAll(assortmentConsoWrapper.assortmentDetailsLinkedMap.get(assortmentDetailConso.Product__c));
                            if(!this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                                this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                            }
                        }
                    }
                }
                // update assortment details
                if(!assortmentDetailsUpdatedList.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(assortmentDetailsUpdatedList, false);
                    nb.logResults(results, assortmentDetailsUpdatedList);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }

    /* Assortment Conso Wrapper Class */
    public class AssortmentConsoWrapper {
        private Assortment__c assortmentBUConso {get; set;}
        private Map<Id, AssortmentDetail__c> assortmentDetailsConsoMap {get; set;}
        private Map<Id, List<AssortmentDetail__c>> assortmentDetailsLinkedMap {get; set;}
        private Boolean isUpdated {get; set;}
        public AssortmentConsoWrapper() {
            this.assortmentDetailsConsoMap = new Map<Id, AssortmentDetail__c>();
            this.assortmentDetailsLinkedMap = new Map<Id, List<AssortmentDetail__c>>();
            this.isUpdated = false;
        }
    }

    private String getSortedFormatOrigin(String formatOrigin) {
        List<String> formatsList = formatOrigin.split(';');
        formatsList.sort();
        return String.join(formatsList, ';');
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> countryIds = (Set<Id>)paramsMap.get('countryIds');
        Set<Id> buSourceIds = (Set<Id>)paramsMap.get('buSourceIds');
        Set<Id> categoryIds = (Set<Id>)paramsMap.get('categoryIds');
        Set<Id> productIds = (Set<Id>)paramsMap.get('productIds');
        Set<Integer> years = (Set<Integer>)paramsMap.get('years');
        return new ConsolidateAssortmentsBatch(startedFrom, countryIds, buSourceIds, categoryIds, productIds, years);
    }

}