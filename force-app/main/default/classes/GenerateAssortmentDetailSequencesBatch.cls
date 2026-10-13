/* @author ULiT
 * @date 26-12-2019
 * @description Generate assortment details sequences and assortment matrix reviews
 */ 
global with sharing class GenerateAssortmentDetailSequencesBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> updatedAssortmentDetailsNextYearSet;
    
    // Empty constructor for BatchFactory.
    global GenerateAssortmentDetailSequencesBatch() {}

    // Constructor.
    global GenerateAssortmentDetailSequencesBatch(String startedFrom, Set<Id> buSourceIds, Set<Id> buTargetIds, Set<Id> assortmentDetailIds, Integer year) {
        this.nb = new NegoptimBatch(GenerateAssortmentDetailSequencesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.updatedAssortmentDetailsNextYearSet = new Set<Id>();
        String q = ' SELECT Id, Assortment_BU__c, Assortment_BU__r.Assortment_parent__c, Assortment_BU__r.Assortment_Parent_Objective__c, Year__c, BusinessUnitAssCluster__c, Ref_BU_Cluster__c, Product__c, Product__r.RecordType.DeveloperName, Hierarchy__c, Record_date__c, Movement_Date__c, Client_Status__c,';
        q += ' Assortment_BU__r.RecordType.DeveloperName, Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.BusinessUnitSource__c, Assortment_BU__r.BusinessUnitTarget__c, Assortment_BU__r.BusinessUnitSource__r.IsMasterBU__c, Assortment_BU__r.BusinessUnitTarget__r.IsMasterBU__c,';
        q += ' New_Client_ND_MarketBased__c, New_Client_ND_ClientBased__c, New_Client_WD_MarketBased__c, New_Client_WD_ClientBased__c, New_Client_Quantity_SEQ__c,';
        q += ' Fact_ND_MarketBased__c, Fact_ND_ClientBased__c, Fact_WD_MarketBased__c, Fact_WD_ClientBased__c, Fact_SellOut_Tone_SEQ__c, Fact_SellOut_Quantity_SEQ__c, Fact_SellOut_SEQ__c,';
        q += ' L4L_Client_ND_MarketBased__c, L4L_Client_ND_ClientBased__c, L4L_Client_WD_MarketBased__c, L4L_Client_WD_ClientBased__c,';
        q += ' Ref_Corp_Assortment__c, Ref_Corp_Assortment__r.Ref_Corp_Assortment__c, Ref_Client_Assortment__c, Ref_Client_ND_MarketBased_Nego__c, Ref_Client_ND_ClientBased_Nego__c, Ref_Client_WD_MarketBased_Nego__c, Ref_Client_WD_ClientBased_Nego__c, Last_History__c, Status__c,';
        q += ' Last_History__r.New_Client_ND_MarketBased__c, Last_History__r.New_Client_ND_ClientBased__c, Last_History__r.New_Client_WD_MarketBased__c, Last_History__r.New_Client_WD_ClientBased__c, Last_History__r.New_Client_Quantity_SEQ__c,';
        q += ' Ref_Client_Assortment__r.New_Client_ND_MarketBased__c, Ref_Client_Assortment__r.New_Client_ND_ClientBased__c, Ref_Client_Assortment__r.New_Client_WD_MarketBased__c, Ref_Client_Assortment__r.New_Client_WD_ClientBased__c, Ref_Client_Assortment__r.New_Client_Quantity_SEQ__c,';
        q += ' (SELECT Id, Product__c, Assortment_Detail__c, Assortment__c, Movement_Date__c, Record_date__c, Sequence__c, Year__c,';
        q += ' New_ND_MarketBased__c, New_ND_ClientBased__c, New_WD_MarketBased__c, New_WD_ClientBased__c, New_SellOut_Tone__c, New_SellOut_Quantity__c, New_SellOut__c,';
        q += ' Fx_ND_MarketBased__c, Fx_ND_ClientBased__c, Fx_WD_MarketBased__c, Fx_WD_ClientBased__c, Fx_SellOut_Tone__c, Fx_SellOut_Quantity__c, Fx_SellOut__c,';
        q += ' Fact_ND_MarketBased__c, Fact_ND_ClientBased__c, Fact_WD_MarketBased__c, Fact_WD_ClientBased__c, Fact_SellOut_Tone__c, Fact_SellOut_Quantity__c, Fact_SellOut__c,';
        q += ' Budget_ND_MarketBased__c, Budget_ND_ClientBased__c, Budget_WD_MarketBased__c, Budget_WD_ClientBased__c, Budget_SellOut_Tone__c, Budget_SellOut_Quantity__c, Budget_SellOut__c,';
        q += ' Target_ND_MarketBased__c, Target_ND_ClientBased__c, Target_WD_MarketBased__c, Target_WD_ClientBased__c, Target_SellOut_Tone__c, Target_SellOut_Quantity__c, Target_SellOut__c,';
        q += ' L4L_ND_MarketBased__c, L4L_ND_ClientBased__c, L4L_WD_MarketBased__c, L4L_WD_ClientBased__c, L4L_SellOut_Tone__c, L4L_SellOut_Quantity__c, L4L_SellOut__c';
        q += ' FROM Assortment_Detail_Sequences__r)';
        q += ' FROM Assortment_Detail__c';
        q += ' WHERE Assortment_BU__r.RecordType.DeveloperName IN (\'Budget\', \'Target\', \'Nego\')';
        q += ' AND Movement_Date__c <> NULL';
        q += ' AND (Client_Status__c <> NULL OR (Client_Status__c = NULL AND Assortment_BU__r.RecordType.DeveloperName = \'Budget\'))';
        q += ' AND ((Version__c = NULL AND (Status__c = \'Validated\' OR (Status__c = \'Request for Approval\' AND (Assortment_BU__r.RecordType.DeveloperName IN (\'Budget\', \'Target\') OR';
        q += ' (Assortment_BU__r.RecordType.DeveloperName = \'Nego\' AND  Assortment_BU__r.Target_Simulation__c = TRUE))))) OR';
        q += ' (Status__c = \'Previously Validated\' AND Client_Status__c = \'Substitute\'))';
        if (buSourceIds != null && !buSourceIds.isEmpty()) {
            q += ' AND Assortment_BU__r.BusinessUnitSource__c IN (\'' + String.join(new List<Id>(buSourceIds), '\',\'') +'\') ';
        }
        if (buTargetIds != null && !buTargetIds.isEmpty()) {
            q += ' AND Assortment_BU__r.BusinessUnitTarget__c IN (\'' + String.join(new List<Id>(buTargetIds), '\',\'') +'\') ';
        }
        if(assortmentDetailIds != null && assortmentDetailIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(assortmentDetailIds), '\',\'') +'\') ';
        }
        if(year != null) {
            q += ' AND Year__c =' + year;
        }
        this.query = q;
        // push inputs to log
        nb.logParameter('buSourceIds', buSourceIds);
        nb.logParameter('buTargetIds', buTargetIds);
        nb.logParameter('assortmentDetailIds', assortmentDetailIds);
        nb.logParameter('year', year);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String[] assortmentBUFields = new String[] {
            SObjectType.Assortment_BU__c.fields.Id.Name,
            SObjectType.Assortment_BU__c.fields.RecordTypeId.Name,
            SObjectType.Assortment_BU__c.fields.Assortment_parent__c.Name,
            SObjectType.Assortment_BU__c.fields.Assortment_Parent_Objective__c.Name,
            SObjectType.Assortment_BU__c.fields.Ass_BDate__c.Name,
            SObjectType.Assortment_BU__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Assortment_BU__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.Assortment_BU__c.fields.Target_Simulation__c.Name,
            SObjectType.Assortment_BU__c.fields.Year__c.Name
        };
        String[] assortmentDetailFields = new String[] {
            SObjectType.Assortment_Detail__c.fields.Id.Name,
                SObjectType.Assortment_Detail__c.fields.Assortment_BU__c.Name,
                SObjectType.Assortment_Detail__c.fields.Year__c.Name,
                SObjectType.Assortment_Detail__c.fields.BusinessUnitAssCluster__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_BU_Cluster__c.Name,
                SObjectType.Assortment_Detail__c.fields.Product__c.Name,
                SObjectType.Assortment_Detail__c.fields.Hierarchy__c.Name,
                SObjectType.Assortment_Detail__c.fields.Record_date__c.Name,
                SObjectType.Assortment_Detail__c.fields.Movement_Date__c.Name,
                SObjectType.Assortment_Detail__c.fields.Client_Status__c.Name,
                SObjectType.Assortment_Detail__c.fields.New_Client_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.New_Client_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.New_Client_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.New_Client_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.New_Client_Quantity_SEQ__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_SellOut_Tone_SEQ__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_SellOut_Quantity_SEQ__c.Name,
                SObjectType.Assortment_Detail__c.fields.Fact_SellOut_SEQ__c.Name,
                SObjectType.Assortment_Detail__c.fields.L4L_Client_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.L4L_Client_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.L4L_Client_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.L4L_Client_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Corp_Assortment__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Client_Assortment__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Client_ND_MarketBased_Nego__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Client_ND_ClientBased_Nego__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Client_WD_MarketBased_Nego__c.Name,
                SObjectType.Assortment_Detail__c.fields.Ref_Client_WD_ClientBased_Nego__c.Name,
                SObjectType.Assortment_Detail__c.fields.Last_History__c.Name,
                SObjectType.Assortment_Detail__c.fields.Status__c.Name,
                SObjectType.Assortment_Detail__c.fields.Version__c.Name
                };
        String[] assortmentSequenceFields = new String[] {
            SObjectType.Assortment_Detail_Sequence__c.fields.Id.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Product__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Assortment_Detail__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Assortment__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Movement_Date__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Record_date__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Sequence__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Year__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_MarketBased__c.Name, 
                SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_MarketBased__c.Name, 
                SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_ClientBased__c.Name, 
                SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_MarketBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_ClientBased__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut_Tone__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut_Quantity__c.Name,
                SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut__c.Name
                };
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.IsMasterBU__c.Name
                };
        if (NegoptimHelper.checkAccessibility(Assortment_BU__c.SObjectType, assortmentBUFields)
            && NegoptimHelper.checkAccessibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)
            && NegoptimHelper.checkAccessibility(Assortment_Detail_Sequence__c.SObjectType, assortmentSequenceFields)
            && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields))
        {
            return Database.getQueryLocator(query);
        } else {
            return null;
        }
    }
    
    // Start Execute
    global void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        Set<Id> refObjectiveAssortmentDetailSet = new Set<Id>();
        Set<Id> refParentAssortmentDetailSet = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        Set<Id> buTargetSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> nextYearSet = new Set<Integer>();
        Set<Id> assortmentBUSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        // get old assortment details sequences
        Map<Id, Map<Integer, Assortment_Detail_Sequence__c>> assortmentDetailSequencesMap = new Map<Id, Map<Integer, Assortment_Detail_Sequence__c>>();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = new List<Assortment_Detail_Sequence__c>();
        Map<String, Assortment_Matrix_review__c> assortmentMatrixReviewsUpdatedMap = new Map<String, Assortment_Matrix_review__c>();
        Savepoint sp = Database.setSavepoint();
        try {
            for (Assortment_Detail__c item : scope) {
                assortmentBUSet.add(item.Assortment_BU__c);
                if (item.Product__c != null && !productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                if(item.Hierarchy__c != null && !categorySet.contains(item.Hierarchy__c)) {
                    categorySet.add(item.Hierarchy__c);
                }
                // get budget for assortment Target and target for assortment Nego
                if(item.Ref_Corp_Assortment__c != null && !refObjectiveAssortmentDetailSet.contains(item.Ref_Corp_Assortment__c)) {
                    refObjectiveAssortmentDetailSet.add(item.Ref_Corp_Assortment__c);
                }
                // get parent assortments
                if(item.Ref_Client_Assortment__c != null && !refParentAssortmentDetailSet.contains(item.Ref_Client_Assortment__c)) {
                    refParentAssortmentDetailSet.add(item.Ref_Client_Assortment__c);
                }
                // get assortment sequences
                for(Assortment_Detail_Sequence__c assortmentDetailSequence : item.Assortment_Detail_Sequences__r) {
                    if(!assortmentDetailSequencesMap.containsKey(item.Id))
                        assortmentDetailSequencesMap.put(item.Id, new Map<Integer, Assortment_Detail_Sequence__c>());
                    Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = assortmentDetailSequencesMap.get(item.Id);
                    sequencesMap.put(Integer.valueOf(assortmentDetailSequence.Sequence__c), assortmentDetailSequence);
                    assortmentDetailSequencesMap.put(item.Id, sequencesMap);
                }
            }
            // get assortment details for next year
            for(Assortment_Detail__c item : [SELECT Id, (SELECT Id FROM Assortment_Detail_Sequences__r)
                                             FROM Assortment_Detail__c WHERE Ref_Client_Assortment__c IN :scope])
            {
                if(item.Assortment_Detail_Sequences__r.size() > 0) this.updatedAssortmentDetailsNextYearSet.add(item.Id);
            }
            // get assortment BU list
            Map<Id, Assortment_BU__c> assortmentBUsMap = new Map<Id, Assortment_BU__c>();
            // check access Assortment_BU__c fields
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment_BU__c.fields.Id.Name,
                SObjectType.Assortment_BU__c.fields.RecordTypeId.Name,
                SObjectType.Assortment_BU__c.fields.Assortment_parent__c.Name,
                SObjectType.Assortment_BU__c.fields.Assortment_Parent_Objective__c.Name,
                SObjectType.Assortment_BU__c.fields.Ass_BDate__c.Name,
                SObjectType.Assortment_BU__c.fields.BusinessUnitSource__c.Name,
                SObjectType.Assortment_BU__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment_BU__c.fields.Target_Simulation__c.Name,
                SObjectType.Assortment_BU__c.fields.Year__c.Name
            };
            // check access BusinessUnit__c fields
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM1__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM2__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM3__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM4__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM5__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM6__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM7__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM8__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM9__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM10__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM11__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM12__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM1__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM2__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM3__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM4__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM5__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM6__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM7__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM8__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM9__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM10__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM11__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM12__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM1__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM2__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM3__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM4__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM5__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM6__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM7__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM8__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM9__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM10__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM11__c.Name,
                    SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM12__c.Name,
                    SObjectType.BusinessUnit__c.fields.IsMasterBU__c.Name
                    };
            if (NegoptimHelper.checkAccessibility(Assortment_BU__c.SObjectType, assortmentBUFields) && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
                for(Assortment_BU__c item : [SELECT Id, BusinessUnitSource__c, BusinessUnitTarget__c, BusinessUnitSource__r.IsMasterBU__c, BusinessUnitTarget__r.IsMasterBU__c,
                                             Year__c, RecordType.DeveloperName, Assortment_parent__c, Assortment_Parent_Objective__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM1__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM2__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM3__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM4__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM5__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM6__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM7__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM8__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM9__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM10__c,
                                             BusinessUnitTarget__r.WeightedDistributionInnovRiseM11__c, BusinessUnitTarget__r.WeightedDistributionInnovRiseM12__c,
                                             
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM1__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM2__c,
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM3__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM4__c,
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM5__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM6__c,
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM7__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM8__c,
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM9__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM10__c,
                                             BusinessUnitTarget__r.WeightedDistributionSwitchRiseM11__c, BusinessUnitTarget__r.WeightedDistributionSwitchRiseM12__c,
                                             
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM1__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM2__c,
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM3__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM4__c,
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM5__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM6__c,
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM7__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM8__c,
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM9__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM10__c,
                                             BusinessUnitTarget__r.WeightedDistributionStopRiseM11__c, BusinessUnitTarget__r.WeightedDistributionStopRiseM12__c
                                             FROM Assortment_BU__c
                                             WHERE Id IN :assortmentBUSet])
                {
                    if (item.BusinessUnitSource__c != null && !buSourceSet.contains(item.BusinessUnitSource__c)) {
                        buSourceSet.add(item.BusinessUnitSource__c);
                    }
                    if (item.BusinessUnitSource__c != null && item.BusinessUnitTarget__c != null &&
                        item.BusinessUnitSource__r.IsMasterBU__c == true && item.BusinessUnitTarget__r.IsMasterBU__c == true &&
                        !buSourceSet.contains(item.BusinessUnitTarget__c))
                    {
                        buSourceSet.add(item.BusinessUnitTarget__c);
                    }
                    if (item.BusinessUnitTarget__c != null && !buTargetSet.contains(item.BusinessUnitTarget__c)) {
                        buTargetSet.add(item.BusinessUnitTarget__c);
                    }
                    if (item.Year__c != null && !yearSet.contains(Integer.valueOf(item.Year__c))) {
                        yearSet.add(Integer.valueOf(item.Year__c));
                        nextYearSet.add(Integer.valueOf(item.Year__c) + 1);
                    }
                    assortmentBUsMap.put(item.Id, item);
                }
            }
            // get reference assortment Details
            Map<Id, Assortment_Detail__c> refObjectiveAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
            Map<Id, Assortment_Detail__c> refParentAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
            Map<Id, Map<Integer, Assortment_Detail_Sequence__c>> refObjectiveAssortmentDetailSequencesMap = new Map<Id, Map<Integer, Assortment_Detail_Sequence__c>>();
            Map<Id, Map<Integer, Assortment_Detail_Sequence__c>> refParentAssortmentDetailSequencesMap = new Map<Id, Map<Integer, Assortment_Detail_Sequence__c>>();
            if(!refObjectiveAssortmentDetailSet.isEmpty() || !refParentAssortmentDetailSet.isEmpty()) {
                // check access Assortment_Detail__c fields
                String[] assortmentDetailFields = new String[] {
                    SObjectType.Assortment_Detail__c.fields.Id.Name,
                        SObjectType.Assortment_Detail__c.fields.Assortment_BU__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Year__c.Name,
                        SObjectType.Assortment_Detail__c.fields.BusinessUnitAssCluster__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Ref_BU_Cluster__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Product__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Hierarchy__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Record_date__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Movement_Date__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Client_Status__c.Name,
                        SObjectType.Assortment_Detail__c.fields.New_Client_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail__c.fields.New_Client_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail__c.fields.New_Client_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail__c.fields.New_Client_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail__c.fields.New_Client_Quantity_SEQ__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Last_History__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Status__c.Name,
                        SObjectType.Assortment_Detail__c.fields.Version__c.Name
                        };
                // check access Assortment_Detail_Sequence__c fields
                String[] assortmentSequenceFields = new String[] {
                    SObjectType.Assortment_Detail_Sequence__c.fields.Id.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Product__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Assortment_Detail__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Assortment__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Movement_Date__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Record_date__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Sequence__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Year__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_MarketBased__c.Name, 
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_MarketBased__c.Name, 
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_ClientBased__c.Name, 
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_MarketBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_ClientBased__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut_Tone__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut_Quantity__c.Name,
                        SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut__c.Name
                        };
                if (NegoptimHelper.checkAccessibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)
                    && NegoptimHelper.checkAccessibility(Assortment_Detail_Sequence__c.SObjectType, assortmentSequenceFields))
                {
                    for(Assortment_Detail__c item : [SELECT Id, Product__c, Hierarchy__c, Assortment_BU__c,
                                                     New_Client_ND_ClientBased__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, New_Client_WD_MarketBased__c, New_Client_Quantity_SEQ__c,
                                                     (SELECT Id, Product__c, Assortment_Detail__c, Assortment__c, Movement_Date__c, Record_date__c, Sequence__c, Year__c,
                                                      Budget_ND_MarketBased__c, Budget_ND_ClientBased__c, Budget_WD_MarketBased__c, Budget_WD_ClientBased__c, Budget_SellOut_Tone__c, Budget_SellOut_Quantity__c, Budget_SellOut__c,
                                                      Target_ND_MarketBased__c, Target_ND_ClientBased__c, Target_WD_MarketBased__c, Target_WD_ClientBased__c, Target_SellOut_Tone__c, Target_SellOut_Quantity__c, Target_SellOut__c,
                                                      New_ND_MarketBased__c, New_ND_ClientBased__c, New_WD_MarketBased__c, New_WD_ClientBased__c, New_SellOut_Tone__c, New_SellOut_Quantity__c, New_SellOut__c,
                                                      Fx_ND_MarketBased__c, Fx_ND_ClientBased__c, Fx_WD_MarketBased__c, Fx_WD_ClientBased__c, Fx_SellOut_Tone__c, Fx_SellOut_Quantity__c, Fx_SellOut__c,
                                                      L4L_ND_MarketBased__c, L4L_ND_ClientBased__c, L4L_WD_MarketBased__c, L4L_WD_ClientBased__c, L4L_SellOut_Tone__c, L4L_SellOut_Quantity__c, L4L_SellOut__c
                                                      FROM Assortment_Detail_Sequences__r)
                                                     FROM Assortment_Detail__c
                                                     WHERE Status__c = 'Validated' AND (Id IN :refObjectiveAssortmentDetailSet OR Id IN :refParentAssortmentDetailSet)])
                    {
                        if(refObjectiveAssortmentDetailSet.contains(item.Id)) {
                            for(Assortment_Detail_Sequence__c sequence : item.Assortment_Detail_Sequences__r) {
                                if(!refObjectiveAssortmentDetailSequencesMap.containsKey(item.Id))
                                    refObjectiveAssortmentDetailSequencesMap.put(item.Id, new Map<Integer, Assortment_Detail_Sequence__c>());
                                Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = refObjectiveAssortmentDetailSequencesMap.get(item.Id);
                                sequencesMap.put(Integer.valueOf(sequence.Sequence__c), sequence);
                                refObjectiveAssortmentDetailSequencesMap.put(item.Id, sequencesMap);
                            }
                            refObjectiveAssortmentDetailsMap.put(item.Id, item);
                        } else if(refParentAssortmentDetailSet.contains(item.Id)) {
                            for(Assortment_Detail_Sequence__c sequence : item.Assortment_Detail_Sequences__r) {
                                if(!refParentAssortmentDetailSequencesMap.containsKey(item.Id))
                                    refParentAssortmentDetailSequencesMap.put(item.Id, new Map<Integer, Assortment_Detail_Sequence__c>());
                                Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = refParentAssortmentDetailSequencesMap.get(item.Id);
                                sequencesMap.put(Integer.valueOf(sequence.Sequence__c), sequence);
                                refParentAssortmentDetailSequencesMap.put(item.Id, sequencesMap);
                            }
                            refParentAssortmentDetailsMap.put(item.Id, item);
                        }
                    }
                }
            }
            
            // get old assortment Matrix reviews
            Map<String, Map<Integer, Assortment_Matrix_review__c>> assortmentMatrixReviewMap = new Map<String, Map<Integer, Assortment_Matrix_review__c>>();
            // check access Assortment_Matrix_review__c fields
            String[] matrixReviewFields = new String[] {
                SObjectType.Assortment_Matrix_review__c.fields.Id.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.BusinessUnitSource__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.BusinessUnitTarget__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Hierarchy__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Produit__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Sequence__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Year__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Name__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.ND__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.WD__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.ND_Marketbase__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.WD_Marketbase__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.SellOut_Tone__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.SellOut__c.Name
                    };
            if (NegoptimHelper.checkAccessibility(Assortment_Matrix_review__c.SObjectType, matrixReviewFields)) {
                for(Assortment_Matrix_review__c item : [SELECT Id, BusinessUnitSource__c, BusinessUnitTarget__c, Hierarchy__c, Produit__c, Sequence__c, Year__c,
                                                        Name__c, ND__c, WD__c, ND_Marketbase__c, WD_Marketbase__c, SellOut_Quantity__c, SellOut_Tone__c, SellOut__c
                                                        FROM Assortment_Matrix_review__c
                                                        WHERE Name__c IN ('Budget', 'Target', 'Negotiated', 'Forecast', 'Like4Like', 'Budget P1', 'Target P1', 'Negotiated P1', 'Forecast P1', 'Like4Like P1')
                                                        AND BusinessUnitSource__c IN :buSourceSet AND BusinessUnitTarget__c IN :buTargetSet
                                                        AND Produit__c IN :productSet AND Year__c IN :yearSet])
                {
                    String key = item.BusinessUnitSource__c + '' + item.BusinessUnitTarget__c + '' + item.Produit__c + '' + Integer.valueOf(item.Year__c) + '' + item.Name__c;
                    if(!assortmentMatrixReviewMap.containsKey(key))
                        assortmentMatrixReviewMap.put(key, new Map<Integer, Assortment_Matrix_review__c>());
                    Map<Integer, Assortment_Matrix_review__c> assortmentMatrixMap = assortmentMatrixReviewMap.get(key);
                    assortmentMatrixMap.put(Integer.valueOf(item.Sequence__c), item);
                    assortmentMatrixReviewMap.put(key, assortmentMatrixMap);
                }
            }
            // process generate asoortment detail sequences and assortment matrix reviews
            for(Assortment_Detail__c item : scope) {
                // get assortment BU
                Assortment_BU__c assortmentBU = assortmentBUsMap.get(item.Assortment_BU__c);
                Boolean isBudgetAssortment = assortmentBU.RecordType.DeveloperName == 'Budget' ? true : false;
                Boolean isTargetAssortment = assortmentBU.RecordType.DeveloperName == 'Target' ? true : false;
                Boolean isNegoAssortment = assortmentBU.RecordType.DeveloperName == 'Nego' ? true : false;
                // get reference objective assortment details
                Assortment_Detail__c refObjectiveAssortmentDetail;
                Map<Integer, Assortment_Detail_Sequence__c> refObjectiveAssortmentSequencesMap;
                if(item.Ref_Corp_Assortment__c != null) {
                    refObjectiveAssortmentDetail = refObjectiveAssortmentDetailsMap.get(item.Ref_Corp_Assortment__c);
                    refObjectiveAssortmentSequencesMap = refObjectiveAssortmentDetailSequencesMap.containsKey(item.Ref_Corp_Assortment__c) ?
                        refObjectiveAssortmentDetailSequencesMap.get(item.Ref_Corp_Assortment__c) :  null;
                }
                // get reference parent assortment details and sequences
                Assortment_Detail__c refParentAssortmentDetail;
                Map<Integer, Assortment_Detail_Sequence__c> refParentAssortmentSequencesMap;
                if(item.Ref_Client_Assortment__c != null) {
                    refParentAssortmentDetail = refParentAssortmentDetailsMap.get(item.Ref_Client_Assortment__c);
                    refParentAssortmentSequencesMap = refParentAssortmentDetailSequencesMap.containsKey(item.Ref_Client_Assortment__c) ?
                        refParentAssortmentDetailSequencesMap.get(item.Ref_Client_Assortment__c) : null;
                }
                // get assortment detail sequences list
                Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = assortmentDetailSequencesMap.get(item.Id);
                if(sequencesMap == null) sequencesMap = new Map<Integer, Assortment_Detail_Sequence__c>();
                Integer year = item.Movement_Date__c != null ? item.Movement_Date__c.year() : Date.today().year();
                Integer month = item.Movement_Date__c != null ? item.Movement_Date__c.month() : Date.today().month();
                Integer day = item.Movement_Date__c != null ? item.Movement_Date__c.day() : Date.today().day();
                Decimal monthDays = Date.daysInMonth(year, month);
                Boolean isMovementLessThanAssortmentDate = item.Movement_Date__c < item.Assortment_BU__r.Ass_BDate__c;
                Boolean isMovementGreatherThanAssortmentDate = item.Movement_Date__c.year() > assortmentBU.Year__c;
                // generate assortment detail sequences
                Decimal refNDMarketBased = 0, refNDClientBased = 0, refWDMarketBased = 0, refWDClientBased = 0, refSellOutQuantity = 0;
                if(item.Last_History__c != null) {
                    refNDMarketBased = item.Last_History__r.New_Client_ND_MarketBased__c;
                    refNDClientBased = item.Last_History__r.New_Client_ND_ClientBased__c;
                    refWDMarketBased = item.Last_History__r.New_Client_WD_MarketBased__c;
                    refWDClientBased = item.Last_History__r.New_Client_WD_ClientBased__c;
                    refSellOutQuantity = item.Last_History__r.New_Client_Quantity_SEQ__c;
                } else if(item.Ref_Client_Assortment__c != null) {
                    refNDMarketBased = item.Ref_Client_ND_MarketBased_Nego__c;
                    refNDClientBased = item.Ref_Client_ND_ClientBased_Nego__c;
                    refWDMarketBased = item.Ref_Client_WD_MarketBased_Nego__c;
                    refWDClientBased = item.Ref_Client_WD_ClientBased_Nego__c;
                    refSellOutQuantity = item.Ref_Client_Assortment__r.New_Client_Quantity_SEQ__c;
                }
                Boolean isWDRiseCalculate = item.Client_Status__c == 'New' || item.Client_Status__c == 'Cplt' || item.Client_Status__c == 'Substitute' || item.Client_Status__c == 'Delete';
                Integer WDSequence = 1;
                for(Integer i = 1; i <= 12; i++) {
                    Decimal WDInnovRise = assortmentBU.BusinessUnitTarget__r != null && assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionInnovRiseM'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionInnovRiseM'+ WDSequence +'__c'))) : null;
                    Decimal WDSwitchRise = assortmentBU.BusinessUnitTarget__r != null && assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionSwitchRiseM'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionSwitchRiseM'+ WDSequence +'__c'))) : null;
                    Decimal WDStopRise = assortmentBU.BusinessUnitTarget__r != null && assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionStopRiseM'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BusinessUnitTarget__r.get('WeightedDistributionStopRiseM'+ WDSequence +'__c'))) : null;
                    Decimal WDRise = item.Client_Status__c == 'New' || item.Client_Status__c == 'Cplt' ? WDInnovRise :
                                     item.Client_Status__c == 'Substitute' ? WDSwitchRise :
                                     item.Client_Status__c == 'Delete' ? WDStopRise : 1;
                    if(isWDRiseCalculate && WDRise != null) WDRise = WDRise/100;
                    
                    Assortment_Detail_Sequence__c assortmentDetailSequence;
                    if(sequencesMap != null && sequencesMap.containsKey(i)) {
                        assortmentDetailSequence = sequencesMap.get(i);
                    } else {
                        // insert assortment detail sequence
                        assortmentDetailSequence = new Assortment_Detail_Sequence__c(Assortment_Detail__c = item.Id, Assortment__c = item.Assortment_BU__c, Sequence__c = i, Year__c = Integer.valueOf(assortmentBU.Year__c));
                    }
                    if(isMovementLessThanAssortmentDate) {
                        // New
                        assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                        assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                        assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                        assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                        assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                        assortmentDetailSequence.New_SellOut__c = null;
                        // Fx
                        assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                        assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                        assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                        assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                        assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                        assortmentDetailSequence.Fx_SellOut__c = null;
                    } else if(isMovementGreatherThanAssortmentDate) {
                        // New
                        assortmentDetailSequence.New_ND_MarketBased__c = null;
                        assortmentDetailSequence.New_ND_ClientBased__c = null;
                        assortmentDetailSequence.New_WD_MarketBased__c = null;
                        assortmentDetailSequence.New_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                        assortmentDetailSequence.New_SellOut_Quantity__c = null;
                        assortmentDetailSequence.New_SellOut__c = null;
                        // Fx
                        assortmentDetailSequence.Fx_ND_MarketBased__c = null;
                        assortmentDetailSequence.Fx_ND_ClientBased__c = null;
                        assortmentDetailSequence.Fx_WD_MarketBased__c = null;
                        assortmentDetailSequence.Fx_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                        assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                        assortmentDetailSequence.Fx_SellOut__c = null;
                    } else {
                        if(item.Last_History__c == null) {
                            if(item.Ref_Client_Assortment__c == null) {
                                if(i < month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = null;
                                    assortmentDetailSequence.New_ND_ClientBased__c = null;
                                    assortmentDetailSequence.New_WD_MarketBased__c = null;
                                    assortmentDetailSequence.New_WD_ClientBased__c = null;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = null;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = null;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = null;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = null;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = null;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                }
                                if(i == month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                    if(isWDRiseCalculate) WDSequence++;
                                }
                                if(i > month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                    assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                    assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                    assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise : null;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise : null;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                    if(isWDRiseCalculate) WDSequence++;
                                }
                            } else {
                                // case Ref_Client_Assortment <> NULL
                                if(i < month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = item.Ref_Client_ND_MarketBased_Nego__c;
                                    assortmentDetailSequence.New_ND_ClientBased__c = item.Ref_Client_ND_ClientBased_Nego__c;
                                    assortmentDetailSequence.New_WD_MarketBased__c = item.Ref_Client_WD_MarketBased_Nego__c;
                                    assortmentDetailSequence.New_WD_ClientBased__c = item.Ref_Client_WD_ClientBased_Nego__c;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = refSellOutQuantity;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = item.Ref_Client_ND_MarketBased_Nego__c;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = item.Ref_Client_ND_ClientBased_Nego__c;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = item.Ref_Client_WD_MarketBased_Nego__c;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = item.Ref_Client_WD_ClientBased_Nego__c;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = refSellOutQuantity;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                }
                                if(i == month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = ((refNDMarketBased != null ? refNDMarketBased * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.New_ND_ClientBased__c = ((refNDClientBased != null ? refNDClientBased * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.New_WD_MarketBased__c = ((refWDMarketBased != null ? refWDMarketBased * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.New_WD_ClientBased__c = ((refWDClientBased != null ? refWDClientBased * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = ((refSellOutQuantity != null ? refSellOutQuantity * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = ((refNDMarketBased != null ? refNDMarketBased * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = ((refNDClientBased != null ? refNDClientBased * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = ((refWDMarketBased != null ? refWDMarketBased * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = ((refWDClientBased != null ? refWDClientBased * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = ((refSellOutQuantity != null ? refSellOutQuantity * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                    if(isWDRiseCalculate) WDSequence++;
                                }
                                if(i > month) {
                                    // New
                                    assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                    assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                    assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                    assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                    // Fx
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise : null;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise : null;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise : null;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                    if(isWDRiseCalculate) WDSequence++;
                                }
                            }
                        } else {
                            // case Last_History <> NULL
                            if(i == month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = ((refNDMarketBased != null ? refNDMarketBased * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_ND_ClientBased__c = ((refNDClientBased != null ? refNDClientBased * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_WD_MarketBased__c = ((refWDMarketBased != null ? refWDMarketBased * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_WD_ClientBased__c = ((refWDClientBased != null ? refWDClientBased * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = ((refSellOutQuantity != null ? refSellOutQuantity * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_SellOut__c = null;
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = ((refNDMarketBased != null ? refNDMarketBased * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = ((refNDClientBased != null ? refNDClientBased * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = ((refWDMarketBased != null ? refWDMarketBased * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = ((refWDClientBased != null ? refWDClientBased * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = ((refSellOutQuantity != null ? refSellOutQuantity * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                if(isWDRiseCalculate) WDSequence++;
                            }
                            if(i > month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.New_SellOut__c = null;
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise : null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                if(isWDRiseCalculate) WDSequence++;
                            }
                        }
                    }
                    // case assortment budget or target
                    if(isBudgetAssortment || isTargetAssortment) {
                        // New
                        assortmentDetailSequence.New_ND_MarketBased__c = null;
                        assortmentDetailSequence.New_ND_ClientBased__c = null;
                        assortmentDetailSequence.New_WD_MarketBased__c = null;
                        assortmentDetailSequence.New_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                        assortmentDetailSequence.New_SellOut_Quantity__c = null;
                        assortmentDetailSequence.New_SellOut__c = null;
                        if(isBudgetAssortment) {
                            assortmentDetailSequence.Budget_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                            assortmentDetailSequence.Budget_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                            assortmentDetailSequence.Budget_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                            assortmentDetailSequence.Budget_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                            ////assortmentDetailSequence.Budget_SellOut_Tone__c = null;
                            assortmentDetailSequence.Budget_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                            assortmentDetailSequence.Budget_SellOut__c = null;
                        }
                        if(isTargetAssortment) {
                            // get budget for assortment Target
                            if(refObjectiveAssortmentSequencesMap != null && refObjectiveAssortmentSequencesMap.containsKey(i)) {
                                Assortment_Detail_Sequence__c refObjectiveAssortmentDetailSequence = refObjectiveAssortmentSequencesMap.get(i);
                                if(refObjectiveAssortmentDetailSequence != null) {
                                    assortmentDetailSequence.Budget_ND_MarketBased__c = refObjectiveAssortmentDetailSequence.Budget_ND_MarketBased__c;
                                    assortmentDetailSequence.Budget_ND_ClientBased__c = refObjectiveAssortmentDetailSequence.Budget_ND_ClientBased__c;
                                    assortmentDetailSequence.Budget_WD_MarketBased__c = refObjectiveAssortmentDetailSequence.Budget_WD_MarketBased__c;
                                    assortmentDetailSequence.Budget_WD_ClientBased__c = refObjectiveAssortmentDetailSequence.Budget_WD_ClientBased__c;
                                    ////assortmentDetailSequence.Budget_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Budget_SellOut_Quantity__c = refObjectiveAssortmentDetailSequence.Budget_SellOut_Quantity__c;
                                    assortmentDetailSequence.Budget_SellOut__c =  refObjectiveAssortmentDetailSequence.Budget_SellOut__c;
                                }
                            }
                            assortmentDetailSequence.Target_ND_MarketBased__c = assortmentDetailSequence.Fx_ND_MarketBased__c;
                            assortmentDetailSequence.Target_ND_ClientBased__c = assortmentDetailSequence.Fx_ND_ClientBased__c;
                            assortmentDetailSequence.Target_WD_MarketBased__c = assortmentDetailSequence.Fx_WD_MarketBased__c;
                            assortmentDetailSequence.Target_WD_ClientBased__c = assortmentDetailSequence.Fx_WD_ClientBased__c;
                            ////assortmentDetailSequence.Target_SellOut_Tone__c = null;
                            assortmentDetailSequence.Target_SellOut_Quantity__c = assortmentDetailSequence.Fx_SellOut_Quantity__c;
                            assortmentDetailSequence.Target_SellOut__c = assortmentDetailSequence.Fx_SellOut__c;
                        }
                        // Fx
                        assortmentDetailSequence.Fx_ND_MarketBased__c = null;
                        assortmentDetailSequence.Fx_ND_ClientBased__c = null;
                        assortmentDetailSequence.Fx_WD_MarketBased__c = null;
                        assortmentDetailSequence.Fx_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                        assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                        assortmentDetailSequence.Fx_SellOut__c = null;
                    }
                    // get Fact/Like4Like for assortment Nego
                    if(isNegoAssortment) {
                        // Fact
                        assortmentDetailSequence.Fact_ND_MarketBased__c = item.Fact_ND_MarketBased__c;
                        assortmentDetailSequence.Fact_ND_ClientBased__c = item.Fact_ND_ClientBased__c;
                        assortmentDetailSequence.Fact_WD_MarketBased__c = item.Fact_WD_MarketBased__c;
                        assortmentDetailSequence.Fact_WD_ClientBased__c = item.Fact_WD_ClientBased__c;
                        ////assortmentDetailSequence.Fact_SellOut_Tone__c = null;
                        assortmentDetailSequence.Fact_SellOut_Quantity__c = item.Fact_SellOut_Quantity_SEQ__c;
                        assortmentDetailSequence.Fact_SellOut__c = item.Fact_SellOut_SEQ__c;
                        // Like4Like
                        assortmentDetailSequence.L4L_ND_MarketBased__c = item.L4L_Client_ND_MarketBased__c;
                        assortmentDetailSequence.L4L_ND_ClientBased__c = item.L4L_Client_ND_ClientBased__c;
                        assortmentDetailSequence.L4L_WD_MarketBased__c = item.L4L_Client_WD_MarketBased__c;
                        assortmentDetailSequence.L4L_WD_ClientBased__c = item.L4L_Client_WD_ClientBased__c;
                        ////assortmentDetailSequence.L4L_SellOut_Tone__c = null;
                        assortmentDetailSequence.L4L_SellOut_Quantity__c = null;
                        assortmentDetailSequence.L4L_SellOut__c = null;
                    }
                    // get budget and target for assortment Nego
                    if(isNegoAssortment && refObjectiveAssortmentSequencesMap != null && refObjectiveAssortmentSequencesMap.containsKey(i)) {
                        Assortment_Detail_Sequence__c refObjectiveAssortmentDetailSequence = refObjectiveAssortmentSequencesMap.get(i);
                        if(refObjectiveAssortmentDetailSequence != null) {
                            // get target for assortment Nego
                            assortmentDetailSequence.Target_ND_MarketBased__c = refObjectiveAssortmentDetailSequence.Target_ND_MarketBased__c;
                            assortmentDetailSequence.Target_ND_ClientBased__c = refObjectiveAssortmentDetailSequence.Target_ND_ClientBased__c;
                            assortmentDetailSequence.Target_WD_MarketBased__c = refObjectiveAssortmentDetailSequence.Target_WD_MarketBased__c;
                            assortmentDetailSequence.Target_WD_ClientBased__c = refObjectiveAssortmentDetailSequence.Target_WD_ClientBased__c;
                            ////assortmentDetailSequence.Target_SellOut_Tone__c = null;
                            assortmentDetailSequence.Target_SellOut_Quantity__c = refObjectiveAssortmentDetailSequence.Target_SellOut_Quantity__c;
                            assortmentDetailSequence.Target_SellOut__c = refObjectiveAssortmentDetailSequence.Target_SellOut__c;
                            // get Budget for assortment Nego
                            assortmentDetailSequence.Budget_ND_MarketBased__c = refObjectiveAssortmentDetailSequence.Budget_ND_MarketBased__c;
                            assortmentDetailSequence.Budget_ND_ClientBased__c = refObjectiveAssortmentDetailSequence.Budget_ND_ClientBased__c;
                            assortmentDetailSequence.Budget_WD_MarketBased__c = refObjectiveAssortmentDetailSequence.Budget_WD_MarketBased__c;
                            assortmentDetailSequence.Budget_WD_ClientBased__c = refObjectiveAssortmentDetailSequence.Budget_WD_ClientBased__c;
                            ////assortmentDetailSequence.Budget_SellOut_Tone__c = null;
                            assortmentDetailSequence.Budget_SellOut_Quantity__c = refObjectiveAssortmentDetailSequence.Budget_SellOut_Quantity__c;
                            assortmentDetailSequence.Budget_SellOut__c = refObjectiveAssortmentDetailSequence.Budget_SellOut__c;
                        }
                    }
                    assortmentDetailSequence.Movement_Date__c = item.Movement_Date__c;
                    assortmentDetailSequence.Record_date__c = item.Record_date__c;
                    assortmentDetailSequences.add(assortmentDetailSequence);
                    sequencesMap.put(i, assortmentDetailSequence);
                }
                // generate assortment matrix reviews
                Set<String> matrixNameSet;
                if(isBudgetAssortment) {
                    matrixNameSet = new Set<String>{'Budget', 'Budget P1'};
                } else if(isTargetAssortment) {
                    matrixNameSet = new Set<String>{'Budget', 'Target', 'Budget P1', 'Target P1'};
                } else {
                    matrixNameSet = new Set<String>{'Budget', 'Target', 'Negotiated', 'Forecast', 'Like4Like', 'Budget P1', 'Target P1', 'Negotiated P1', 'Forecast P1', 'Like4Like P1'};
                }
                for(String matrixName : matrixNameSet) {
                    for(Integer i = 1; i <= 12; i++) {
                        Assortment_Detail_Sequence__c assortmentDetailSequence = sequencesMap.get(i);
                        Id buSourceId = assortmentBU.BusinessUnitSource__r.IsMasterBU__c == true && assortmentBU.BusinessUnitTarget__r.IsMasterBU__c == true ? assortmentBU.BusinessUnitTarget__c : assortmentBU.BusinessUnitSource__c;
                        String keyMatrix = buSourceId + '' + assortmentBU.BusinessUnitTarget__c + '' + item.Product__c + '' + Integer.valueOf(assortmentBU.Year__c) + '' + matrixName;
                        Map<Integer, Assortment_Matrix_review__c> assortmentMatrixMap = assortmentMatrixReviewMap.get(keyMatrix);
                        Assortment_Matrix_review__c assortmentMatrixReview;
                        if(assortmentMatrixMap != null && assortmentMatrixMap.containsKey(i)) {
                            assortmentMatrixReview = assortmentMatrixMap.get(i);
                        } else {
                            // insert assortment Matrix review
                            assortmentMatrixReview = new Assortment_Matrix_review__c(BusinessUnitSource__c = buSourceId,
                                                                                     BusinessUnitTarget__c = assortmentBU.BusinessUnitTarget__c,
                                                                                     Produit__c = item.Product__c,
                                                                                     Sequence__c = i,
                                                                                     Year__c = Integer.valueOf(assortmentBU.Year__c),
                                                                                     Name__c = matrixName);
                        }
                        if(matrixName == 'Budget') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.Budget_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.Budget_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.Budget_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.Budget_WD_MarketBased__c;
                        }
                        if(matrixName == 'Target') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.Target_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.Target_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.Target_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.Target_WD_MarketBased__c;
                        }
                        if(matrixName == 'Negotiated') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.New_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.New_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.New_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.New_WD_MarketBased__c;
                        }
                        if(matrixName == 'Forecast') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.Fx_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.Fx_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.Fx_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.Fx_WD_MarketBased__c;
                        }
                        if(matrixName == 'Like4Like') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.L4L_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.L4L_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.L4L_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.L4L_WD_MarketBased__c;
                        }
                        // get parent assortment detail sequences list
                        if(refParentAssortmentSequencesMap != null && refParentAssortmentSequencesMap.containsKey(i)) {
                            Assortment_Detail_Sequence__c refParentAssortmentDetailSequence = refParentAssortmentSequencesMap.get(i);
                            if(refParentAssortmentDetailSequence != null) {
                                if(matrixName == 'Budget P1') {
                                    assortmentMatrixReview.ND__c = refParentAssortmentDetailSequence.Budget_ND_ClientBased__c;
                                    assortmentMatrixReview.WD__c = refParentAssortmentDetailSequence.Budget_WD_ClientBased__c;
                                    assortmentMatrixReview.ND_Marketbase__c = refParentAssortmentDetailSequence.Budget_ND_MarketBased__c;
                                    assortmentMatrixReview.WD_Marketbase__c = refParentAssortmentDetailSequence.Budget_WD_MarketBased__c;
                                }
                                if(matrixName == 'Target P1') {
                                    assortmentMatrixReview.ND__c = refParentAssortmentDetailSequence.Target_ND_ClientBased__c;
                                    assortmentMatrixReview.WD__c = refParentAssortmentDetailSequence.Target_WD_ClientBased__c;
                                    assortmentMatrixReview.ND_Marketbase__c = refParentAssortmentDetailSequence.Target_ND_MarketBased__c;
                                    assortmentMatrixReview.WD_Marketbase__c = refParentAssortmentDetailSequence.Target_WD_MarketBased__c;
                                }
                                if(matrixName == 'Negotiated P1') {
                                    assortmentMatrixReview.ND__c = refParentAssortmentDetailSequence.New_ND_ClientBased__c;
                                    assortmentMatrixReview.WD__c = refParentAssortmentDetailSequence.New_WD_ClientBased__c;
                                    assortmentMatrixReview.ND_Marketbase__c = refParentAssortmentDetailSequence.New_ND_MarketBased__c;
                                    assortmentMatrixReview.WD_Marketbase__c = refParentAssortmentDetailSequence.New_WD_MarketBased__c;
                                }
                                if(matrixName == 'Forecast P1') {
                                    assortmentMatrixReview.ND__c = refParentAssortmentDetailSequence.Fx_ND_ClientBased__c;
                                    assortmentMatrixReview.WD__c = refParentAssortmentDetailSequence.Fx_WD_ClientBased__c;
                                    assortmentMatrixReview.ND_Marketbase__c = refParentAssortmentDetailSequence.Fx_ND_MarketBased__c;
                                    assortmentMatrixReview.WD_Marketbase__c = refParentAssortmentDetailSequence.Fx_WD_MarketBased__c;
                                }
                                if(matrixName == 'Like4Like P1') {
                                    assortmentMatrixReview.ND__c = refParentAssortmentDetailSequence.L4L_ND_ClientBased__c;
                                    assortmentMatrixReview.WD__c = refParentAssortmentDetailSequence.L4L_WD_ClientBased__c;
                                    assortmentMatrixReview.ND_Marketbase__c = refParentAssortmentDetailSequence.L4L_ND_MarketBased__c;
                                    assortmentMatrixReview.WD_Marketbase__c = refParentAssortmentDetailSequence.L4L_WD_MarketBased__c;
                                }
                            }
                        }
                        if(assortmentMatrixReview.Id == null && assortmentMatrixReview.ND__c == null && assortmentMatrixReview.WD__c == null &&
                           assortmentMatrixReview.ND_Marketbase__c == null && assortmentMatrixReview.WD_Marketbase__c == null) continue;
                        if(assortmentMatrixMap == null) assortmentMatrixMap = new Map<Integer, Assortment_Matrix_review__c>();
                        assortmentMatrixMap.put(i, assortmentMatrixReview);
                        assortmentMatrixReviewMap.put(keyMatrix, assortmentMatrixMap);
                        assortmentMatrixReviewsUpdatedMap.put(keyMatrix + '' + i, assortmentMatrixReview);
                    }
                }
            }
            // check security on update Assortment_Detail_Sequence__c fields
            String[] assortmentDetailSequenceFields = new String[] {
                SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.New_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.New_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.New_SellOut__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fx_SellOut__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Fact_SellOut__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.L4L_SellOut__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Budget_SellOut__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Target_ND_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_MarketBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Target_WD_ClientBased__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Target_SellOut_Quantity__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Record_date__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Sequence__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Year__c.Name
                    };
            String[] assortmentDetailSequenceInsertedFields = new String[] {
                SObjectType.Assortment_Detail_Sequence__c.fields.Assortment_Detail__c.Name,
                    SObjectType.Assortment_Detail_Sequence__c.fields.Assortment__c.Name
                    };
            assortmentDetailSequenceInsertedFields.addAll(assortmentDetailSequenceFields);
            // check security on update Assortment_Matrix_review__c fields
            String[] assortmentMatrixReviewFields = new String[] {
                SObjectType.Assortment_Matrix_review__c.fields.ND__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.WD__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.ND_Marketbase__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.WD_Marketbase__c.Name
                    };
            String[] assortmentMatrixReviewInsertedFields = new String[] {
                SObjectType.Assortment_Matrix_review__c.fields.BusinessUnitSource__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.BusinessUnitTarget__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Produit__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Sequence__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Year__c.Name,
                    SObjectType.Assortment_Matrix_review__c.fields.Name__c.Name
                    };
            assortmentMatrixReviewInsertedFields.addAll(assortmentMatrixReviewFields);
            if(NegoptimHelper.checkCreatibility(Assortment_Detail_Sequence__c.SObjectType, assortmentDetailSequenceInsertedFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_Detail_Sequence__c.SObjectType, assortmentDetailSequenceFields) &&
               NegoptimHelper.checkCreatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewInsertedFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewFields))
            {
                // upsert assortment detail sequences
                if(!assortmentDetailSequences.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentDetailSequences, false);
                    nb.logResults(results, assortmentDetailSequences);
                }
                // upsert assortment matrix reviews
                if(!assortmentMatrixReviewsUpdatedMap.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentMatrixReviewsUpdatedMap.values(), false);
                    nb.logResults(results, assortmentMatrixReviewsUpdatedMap.values());
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
    
    // Finish method implementation.
    global void finish(Database.BatchableContext BC) {
        if(!this.updatedAssortmentDetailsNextYearSet.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'GenerateAssortmentDetailSequencesBatch',
                'buSourceIds' => null,
                'buTargetIds' => null,
                'assortmentDetailIds' => this.updatedAssortmentDetailsNextYearSet,
                'year' => null
            };
            NegoptimBatch.executeBatch('UpdateAssortmentDetailSequencesBatch', paramsMap, 10);
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> buSourceIds = (Set<Id>)paramsMap.get('buSourceIds');
        Set<Id> buTargetIds = (Set<Id>)paramsMap.get('buTargetIds');
        Set<Id> assortmentDetailIds = (Set<Id>)paramsMap.get('assortmentDetailIds');
        Integer year = (Integer)paramsMap.get('year');
        return new GenerateAssortmentDetailSequencesBatch(startedFrom, buSourceIds, buTargetIds, assortmentDetailIds, year);
    }
}