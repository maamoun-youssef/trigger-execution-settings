/*
 * @author ULiT
 * @description Recalculate L4L/WD(ClientBased,MarketBased)/ND
 **/
public with sharing class RecalculateAssortmentDetailsBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    private String query;
    private Boolean L4LOnly;
    private Set<Id> assortmentNegoIds;
    private Set<Id> assortmentDetailValidatedIds;

    public RecalculateAssortmentDetailsBatch(){}

    public RecalculateAssortmentDetailsBatch(String startedFrom, List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly, List<String> recordTypes) {
        this.nb = new NegoptimBatch(RecalculateAssortmentDetailsBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.assortmentNegoIds = new Set<Id>();
        this.assortmentDetailValidatedIds = new Set<Id>();
        this.L4LOnly = L4LOnly != null ? L4LOnly : false;
        query = buildQuery(assortmentBUIds, assortmentDetailIds, buSourceList, buTargetList, year, false, inPreparationOnly, recordTypes);
        nb.logParameter('assortmentBUIds', assortmentBUIds);
        nb.logParameter('buSourceList', buSourceList);
        nb.logParameter('buTargetList', buTargetList);
        nb.logParameter('year', year);
        nb.logParameter('L4LOnly', L4LOnly);
        nb.logParameter('inPreparationOnly', inPreparationOnly);
        nb.logParameter('recordTypes', recordTypes);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<AssortmentDetail__c> scope) {
        List<AssortmentDetail__c> assortmentDetails = new List<AssortmentDetail__c>();
        Savepoint sp = Database.setSavepoint();
        try {
            AssortmentServices assortmentServices = new AssortmentServices(scope);
            for (AssortmentDetail__c item : scope) {
                Id buId = item.Assortment__r.BusinessUnitTarget__c;
                AssortmentServices.ResultWrapper rw = assortmentServices.getResultWrapperForAssortment(buId);
                Id categoryId = item.Hierarchy__c;
                system.debug('categoryId >>>> ' + categoryId);
                system.debug('item.Assortment__r.RecordType.DeveloperName >>>> ' + item.Assortment__r.RecordType.DeveloperName);
                system.debug(JSON.serialize(rw.categoryClientCategoryStratMap));
                if (rw != null && (rw.categoryClientCategoryStratMap.containsKey(categoryId) || rw.categoryClientCategoryCpltMap.containsKey(categoryId))) {
                    if (L4LOnly && item.Assortment__r.RecordType.DeveloperName == 'Negotiation') {
                        item.WDChannelBaseNegoL4L__c = item.Status__c == 'Validate' || item.Status__c == 'PreviouslyValidate' ? assortmentServices.getL4LWDMarketBased(item).setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Scale) : 0;
                        item.WDClientBaseNegoL4L__c = item.Status__c == 'Validate' || item.Status__c == 'PreviouslyValidate' ? assortmentServices.getL4LWDClientBased(item).setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseNegoL4L__c.Scale) : 0;
                        item.NDClientBaseNegoL4L__c = item.Status__c == 'Validate' || item.Status__c == 'PreviouslyValidate' ? assortmentServices.getL4LNDClientBased(item).setScale(SObjectType.AssortmentDetail__c.fields.NDClientBaseNegoL4L__c.Scale) : 0;
                        item.SOSNumberNegoL4L__c = item.Status__c == 'Validate' || item.Status__c == 'PreviouslyValidate' ? assortmentServices.getL4LOffsetCumul(item).setScale(SObjectType.AssortmentDetail__c.fields.SOSNumberNegoL4L__c.Scale) : 0;
                    } else {
                        assortmentServices.assignKPI(new List<AssortmentDetail__c>{item});
                    }
                    assortmentDetails.add(item);
                    if (item.StartDate__c != null && item.ProductLifeStatusAss__c != null &&
                        ((item.Version__c == null && (item.Status__c == 'Validate' || (item.Status__c == 'RequestForApproval' && item.Assortment__r.OnTop__c == true))) ||
                         (item.Status__c == 'PreviouslyValidate' && item.ProductLifeStatusAss__c == 'Substitute')))
                    {
                        this.assortmentDetailValidatedIds.add(item.Id);
                    }
                    if (item.Assortment__r.RecordType.DeveloperName == 'Negotiation') {
                        this.assortmentNegoIds.add(item.Assortment__c);
                    }
                }
            }
            // check security on AssortmentDetail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.NDClientBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNClientBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseNegoL4L__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNClientBaseNegoL4L__c.Name,
                SObjectType.AssortmentDetail__c.fields.NDClientBaseNegoL4L__c.Name,
                SObjectType.AssortmentDetail__c.fields.SOSNumberNegoL4L__c.Name,
                SObjectType.AssortmentDetail__c.fields.NDClientBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Name
            };
            // update assortment details
            if(!assortmentDetails.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    List<Database.SaveResult> results = Database.update(assortmentDetails, false);
                    nb.logResults(results, assortmentDetails);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());

        } catch(Exception e) {
            Database.rollback(sp);
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        if (this.assortmentNegoIds != null && !this.assortmentNegoIds.isEmpty()) {
            Set<Id> buSourceIds = new Set<Id>();
            Set<Id> categoryIds = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Set<Integer> nextYearSet = new Set<Integer>();
            Map<String, List<Id>> negoMapkeys = new Map<String, List<Id>>();
            List<Assortment__c> negoAssortments = [SELECT Id, BusinessUnitSource__c, Hierarchy__c, Year__c
                                                             FROM Assortment__c
                                                             WHERE Id IN :this.assortmentNegoIds
                                                             AND RecordType.DeveloperName = 'Negotiation'];
            for (Assortment__c item : negoAssortments) {
                buSourceIds.add(item.BusinessUnitSource__c);
                categoryIds.add(item.Hierarchy__c);
                yearSet.add(Integer.valueOf(item.Year__c));
                nextYearSet.add(Integer.valueOf(item.Year__c + 1));
            }
            List<Assortment__c> budgetAssortments = [SELECT Id, BusinessUnitTarget__c, Hierarchy__c, Year__c
                                                     FROM Assortment__c
                                                     WHERE BusinessUnitTarget__c IN :buSourceIds
                                                     AND Hierarchy__c IN :categoryIds
                                                     AND Year__c IN :nextYearSet
                                                     AND RecordType.DeveloperName = 'ChannelBudget'];
            if (budgetAssortments != null && !budgetAssortments.isEmpty()) {
                List<Assortment__c> negoAssortmentsList = [SELECT Id, BusinessUnitSource__c, Hierarchy__c, Year__c
                                                           FROM Assortment__c
                                                           WHERE BusinessUnitSource__c IN :buSourceIds
                                                           AND Hierarchy__c IN :categoryIds
                                                           AND Status__c = 'Validate'
                                                           AND Year__c IN :yearSet
                                                           AND BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE
                                                           AND RecordType.DeveloperName IN ('Negotiation', 'OnTopConso')];
                for (Assortment__c item : negoAssortmentsList) {
                    String key = item.BusinessUnitSource__c + '' + item.Hierarchy__c + Integer.valueOf(item.Year__c);
                    if (!negoMapkeys.containsKey(key)) {
                        negoMapkeys.put(key, new List<Id>());
                    }
                    negoMapkeys.get(key).add(item.Id);
                }
                for (Assortment__c item : budgetAssortments) {
                    String key = item.BusinessUnitTarget__c + '' + item.Hierarchy__c + Integer.valueOf(item.Year__c - 1);
                    if (negoMapkeys.containsKey(key)) {
                        Map<String, Object> paramsMap = new Map<String, Object>{
                            'startedFrom' => RecalculateAssortmentDetailsBatch.class.getName(),
                            'budgetId' => item.Id,
                            'assortmentNegoIds' => negoMapkeys.get(key),
                            'introProductIds' => null
                        };
                        NegoptimBatch.executeBatch('GenerateAssortmentBudgetDetailsBatch', paramsMap, 20);
                    }
                }
            }
        }
        // Get the Job.
        String customSubject = RecalculateAssortmentDetailsBatch.class.getName() + ': ' + [SELECT Status
                                                                                            FROM AsyncApexJob WHERE Id = :bc.getJobId()].Status;
        nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        List<Id> assortmentBUIds = (List<Id>)paramsMap.get('assortmentBUIds');
        List<Id> assortmentDetailIds = (List<Id>)paramsMap.get('assortmentDetailIds');
        List<Id> buSourceList = (List<Id>)paramsMap.get('buSourceList');
        List<Id> buTargetList = (List<Id>)paramsMap.get('buTargetList');
        Integer year = (Integer)paramsMap.get('year');
        Boolean L4LOnly = (Boolean)paramsMap.get('L4LOnly');
        Boolean inPreparationOnly = (Boolean)paramsMap.get('inPreparationOnly');
        List<String> recordTypes = (List<String>)paramsMap.get('recordTypes');
        return new RecalculateAssortmentDetailsBatch(startedFrom, assortmentBUIds, assortmentDetailIds, buSourceList, buTargetList, year, L4LOnly, inPreparationOnly, recordTypes);
    }

    private String buildQuery(List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly, List<String> recordTypes) {
        String q = 'SELECT Id, Name, Assortment__r.RecordType.DeveloperName, Product__c, Hierarchy__c, Hierarchy__r.Path__c, Assortment__c, Assortment__r.BDate__c, Assortment__r.EDate__c, AssortmentDetailLHistory__c,';
        q += ' Assortment__r.BusinessUnitSource__c, Assortment__r.BusinessUnitTarget__c, Assortment__r.BusinessUnitTarget__r.IsMultipleComplementary__c, Assortment__r.Hierarchy__c, Assortment__r.Hierarchy__r.Path__c, Assortment__r.Hierarchy__r.Name, Assortment__r.OnTop__c,';
        q += ' BusinessUnitCluster__c, Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberN1__c, Assortment__r.BusinessUnitSource__r.SiteOfSalesNumber__c,';
        q += ' Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP1__c, Assortment__r.BusinessUnitSource__r.SiteOfSalesNumberP2__c, SOSNumberNegoL4L_P1__c,';
        q += ' SOSNumberNego__c, AvgWeeklySalesClient__c, AvgWeeklySalesChannel__c, Product__r.TotalKWeight__c,';
        q += ' SOSNumberNegoL4L__c, StartDate__c, ProductLifeStatusAss__c, Status__c, Version__c,';
        q += ' Assortment__r.AssortmentNegotiationRef__c, Assortment__r.AssortmentNegotiationRef__r.BDate__c, Assortment__r.AssortmentNegotiationRef__r.EDate__c, Assortment__r.Year__c,';
        q += ' AssortmentDetailLHistory__r.SOSNumberNego__c, Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualN1__c, Assortment__r.BusinessUnitTarget__r.WeightedDistributionManual__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP1__c, Assortment__r.BusinessUnitTarget__r.WeightedDistributionManualP2__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumber__c, Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberN1__c,';
        q += ' Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP1__c, Assortment__r.BusinessUnitTarget__r.SiteOfSalesNumberP2__c,';
        q += ' StartDate_W__c, ProductCluster__c, ClientCategory__c';
        q += ' FROM AssortmentDetail__c WHERE Version__c = NULL AND ProductLifeStatusAss__c <> NULL';
        if((assortmentBUIds != null && !assortmentBUIds.isEmpty()) || (assortmentDetailIds != null && !assortmentDetailIds.isEmpty())) {
            if(assortmentBUIds != null && !assortmentBUIds.isEmpty()) {
                q += ' AND Assortment__c IN (\'' + String.join(assortmentBUIds, '\',\'') +'\')';
            }
            if(assortmentDetailIds != null && !assortmentDetailIds.isEmpty()) {
                q += ' AND Id IN (\'' + String.join(assortmentDetailIds, '\',\'') +'\')';
            }
        } else {
            if (recordTypes == null || recordTypes.isEmpty()) {
                recordTypes = new List<String>{'Negotiation'};
            }
            q += ' AND Assortment__r.RecordType.DeveloperName IN (\'' + String.join(recordTypes, '\', \'') + '\')';
            if(year != null) {
                q += ' AND Assortment__r.Year__c = ' + year;
            } else {
                q += ' AND Assortment__r.Year__c = ' + Date.today().year();
            }
            if(buSourceList != null && !buSourceList.isEmpty()) {
                q += ' AND Assortment__r.BusinessUnitSource__c IN (\'' + String.join(buSourceList, '\',\'') +'\')';
            }
            if(buTargetList != null && !buTargetList.isEmpty()) {
                q += ' AND Assortment__r.BusinessUnitTarget__c IN (\'' + String.join(buTargetList, '\',\'') +'\')';
            }
            if (inPreparationOnly) {
                q += ' AND Status__c = \'InPreparation\'';
            }
        }
        return q;
    }
}