/**
 * @author ULiT
 * @date 02/04/2024
 * @description Handler for the trigger Trg_AssortmentDetail
 * */
public class Trg_AssortmentDetail_Handler {
    // holds the number of cluster fields
    private static Integer nbClientClusterFields = NegoptimHelper.getNbClientClusterFields();
    // a set of assortment detail fields to check if a dynamic field is valid
    private static Set<String> assortmentDetailsFieldsSet = SObjectType.AssortmentDetail__c.fields.getMap().keySet();
    private static NegoptimSettings negoSettings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    private static AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
    /* Assortment Wrapper Class */
    public with sharing class AssortmentWrapper {
        public Map<Id, Assortment__c> allAssortmentBUMap {get; set;}
        public Map<Id, Assortment__c> assortmentBUMap {get; set;} // excluding conso
        public List<AssortmentDetail__c> assortmentDetails {get; set;}
        public Map<String, Decimal> hypothesisReportMap {get; set;}

        public AssortmentWrapper(List<AssortmentDetail__c> newAssortmentDetails) {
            this.assortmentDetails  = new List<AssortmentDetail__c>();
            this.hypothesisReportMap = new Map<String, Decimal>();
            getNotConsolidateRecords(newAssortmentDetails);
        }

        // get not consolidate assortment details
        public void getNotConsolidateRecords(List<AssortmentDetail__c> newAssortmentDetails) {
            Set<Id> assortmentBUIdSet = new Set<Id>();
            for (AssortmentDetail__c item : newAssortmentDetails) {
                assortmentBUIdSet.add(item.Assortment__c);
            }
            this.assortmentBUMap = new Map<Id, Assortment__c>();
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.Name.Name,
                SObjectType.Assortment__c.fields.Status__c.Name,
                SObjectType.Assortment__c.fields.Hierarchy__c.Name,
                SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment__c.fields.BDate__c.Name,
                SObjectType.Assortment__c.fields.EDate__c.Name,
                SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
                SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name,
                SObjectType.Assortment__c.fields.AssortmentTargetRef__c.Name
                //SObjectType.Assortment__c.fields.Is_Detail_Recently_updated__c.Name,
                //SObjectType.Assortment__c.fields.Recent_Detail_updates__c.Name,
                //SObjectType.Assortment__c.fields.Target_Simulation__c.Name
            };
            String[] orgaHEFields = new String[] {
                SObjectType.Hierarchy__c.fields.Name.Name,
                SObjectType.Hierarchy__c.fields.Path__c.Name/*,
                SObjectType.Hierarchy__c.fields.Code__c.Name*/
            };
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.IsMasterBU__c.Name,
                SObjectType.BusinessUnit__c.fields.IsMultipleComplementary__c.Name,
                SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
                SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name,
                SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP1__c.Name,
                SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP2__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)
               && NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)
               && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields))
            {
                // Is_Detail_Recently_updated__c, Recent_Detail_updates__c, Target_Simulation__c
                this.allAssortmentBUMap = new Map<Id, Assortment__c>([SELECT Id, Name, Status__c, Hierarchy__c, Hierarchy__r.Name, Hierarchy__r.Path__c, Hierarchy__r.Code__c, BusinessUnitSource__c,
                                                                                BDate__c, EDate__c,BusinessUnitSource__r.IsMasterBU__c, BusinessUnitSource__r.Format__c, BusinessUnitSource__r.SiteOfSalesNumber__c,
                                                                                BusinessUnitTarget__r.Format__c, BusinessUnitTarget__r.t_SalesCannibalizationRates__c,
                                                                                BusinessUnitSource__r.SiteOfSalesNumberN1__c, BusinessUnitSource__r.SiteOfSalesNumberP1__c, BusinessUnitSource__r.SiteOfSalesNumberP2__c,
                                                                                AssortmentNegotiationRef__c, AssortmentNegotiationRef__r.RecordType.DeveloperName, AssortmentNegotiationRef__r.BDate__c, AssortmentNegotiationRef__r.EDate__c,
                                                                                AssortmentChannelBudgetRef__c, AssortmentTargetRef__c, AssortmentTargetRef__r.RecordType.DeveloperName, BusinessUnitTarget__c,
                                                                                BusinessUnitTarget__r.Name, BusinessUnitTarget__r.BusinessUnitCountryOrigin__c, BusinessUnitTarget__r.Supplier__c,
                                                                                BusinessUnitTarget__r.IsMasterBU__c, BusinessUnitTarget__r.IsMultipleComplementary__c,
                                                                                BusinessUnitTarget__r.WeightedDistributionManual__c, BusinessUnitTarget__r.WeightedDistributionManualN1__c, BusinessUnitTarget__r.WeightedDistributionManualP1__c, BusinessUnitTarget__r.WeightedDistributionManualP2__c,
                                                                                BusinessUnitTarget__r.SiteOfSalesNumber__c, BusinessUnitTarget__r.SiteOfSalesNumberN1__c, BusinessUnitTarget__r.SiteOfSalesNumberP1__c, BusinessUnitTarget__r.SiteOfSalesNumberP2__c,
                                                                                Year__c, RecordType.DeveloperName, ExtId__c, OnTop__c
                                                                                FROM Assortment__c
                                                                                WHERE Id IN :assortmentBUIdSet]);
                for (AssortmentDetail__c item : newAssortmentDetails) {
                    Assortment__c assortmentBU = this.allAssortmentBUMap.get(item.Assortment__c);
                    if (assortmentBU != null && assortmentBU.RecordType.DeveloperName != 'OnTopConso' && assortmentBU.RecordType.DeveloperName != 'TargetConso') {
                        this.assortmentDetails.add(item);
                        this.assortmentBUMap.put(assortmentBU.Id, assortmentBU);
                        if (String.isNotBlank(assortmentBU.BusinessUnitTarget__r.t_SalesCannibalizationRates__c)) {
                            List<AssortmentSettings.SalesCannibalizationRatesWrapper> hypothesisReportWrapperList = (List<AssortmentSettings.SalesCannibalizationRatesWrapper>) JSON.deserialize(assortmentBU.BusinessUnitTarget__r.t_SalesCannibalizationRates__c, List<AssortmentSettings.SalesCannibalizationRatesWrapper>.class);
                            for (AssortmentSettings.SalesCannibalizationRatesWrapper hypothesisReport : hypothesisReportWrapperList) {
                                this.hypothesisReportMap.put(hypothesisReport.api + '' + assortmentBU.Id,
                                                             String.isNotBlank(hypothesisReport.clientPerc) ? Decimal.ValueOf(hypothesisReport.clientPerc) : 
                                                             (String.isNotBlank(hypothesisReport.stdPerc) ? Decimal.ValueOf(hypothesisReport.stdPerc) : null));
                            }
                        }
                    }
                }
            }
        }
        
        public boolean isAssortmentUniqueAndBudget() {
            return assortmentBUMap != null && assortmentBUMap.size() == 1 && assortmentBUMap.values().get(0).RecordType.DeveloperName == 'ChannelBudget';
        }
    }
    
    //static variable to check when sync the product from a child assortment bu to master assortment bu, we dont have to run the batch and sync the same proudct to other children
    private static boolean runBatch = true;
    private static boolean syncToMaster = true;
	/* Cluster Wrapper Class */
    public class ClusterWrapper {
        public String Id {get;set;}
        public Integer index {get;set;}
        public Boolean value {get;set;}
        public ClusterWrapper(Integer index, Boolean value) {
            this.index = index;
            this.value = value;
        }
    }
    public static void OnBeforeInsert(List<AssortmentDetail__c> newAssortmentDetails) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        linkRefASD(assortmentWrapper);
        updateClientCategory(assortmentWrapper);
    }
    
    public static void OnBeforeUpdate(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        // called on before update because we can't change status in on after update
        updateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap);
        handleProductSwitch(assortmentWrapper, oldAssortmentDetailMap);
    }
    
    public static void OnAfterUpdate(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
    }
    
    public static void OnBeforeInsertOrUpdate(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        validateCategory(assortmentWrapper, oldAssortmentDetailMap);
        checkDuplicate(assortmentWrapper, oldAssortmentDetailMap);
        populateFields(assortmentWrapper, newAssortmentDetails, oldAssortmentDetailMap);
        updateAssortmentStratAndClientClusters(assortmentWrapper, oldAssortmentDetailMap);
        updateAssortmentClientStatus(assortmentWrapper, oldAssortmentDetailMap);
        updateRecordDate(newAssortmentDetails, oldAssortmentDetailMap);
        recalculateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap);
        calculateFormulaFields(assortmentWrapper, oldAssortmentDetailMap);
    }

    public static void OnAfterInsertOrUpdate(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(newAssortmentDetails);
        ////insertPGs(assortmentWrapper, oldAssortmentDetailMap);
        consolidateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap, false);
		syncProductFromMasterToChildren(newAssortmentDetails, oldAssortmentDetailMap);
        updateTargetDetailFromNego(newAssortmentDetails, oldAssortmentDetailMap);
        bottomUpAsValues(assortmentWrapper, oldAssortmentDetailMap);
        // Only on Insert
        if (oldAssortmentDetailMap == null) {
            generateHLPASD(assortmentWrapper);
        }
        // Only on Update
        if (oldAssortmentDetailMap != null) {
            calculeRelatedLinesFields(assortmentWrapper, newAssortmentDetails, oldAssortmentDetailMap);
        }
        executeGenerateAssortmentBUBatch(newAssortmentDetails, oldAssortmentDetailMap);
    }
    
    public static void OnAfterDelete(Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        AssortmentWrapper assortmentWrapper = new AssortmentWrapper(oldAssortmentDetailMap.values());
        consolidateAssortmentDetails(assortmentWrapper, oldAssortmentDetailMap, true);
    }

    private static void calculateFormulaFields(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        System.Formula.recalculateFormulas(assortmentWrapper.assortmentDetails);
        Set<Id> relatedASDIds = new Set<Id>();
        Set<Id> assortmentIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            if (item.AssortmentDetailNegotiationRef__c != null
                && (item.Id == null || (oldAssortmentDetailMap.containsKey(item.Id) && item.AssortmentDetailNegotiationRef__c != oldAssortmentDetailMap.get(item.Id).AssortmentDetailNegotiationRef__c)))
            {
                relatedASDIds.add(item.AssortmentDetailNegotiationRef__c);
            }
            if (item.AssortmentDetailBudgetRef__c != null
                && (item.Id == null || (oldAssortmentDetailMap.containsKey(item.Id) && item.AssortmentDetailBudgetRef__c != oldAssortmentDetailMap.get(item.Id).AssortmentDetailBudgetRef__c)))
            {
                relatedASDIds.add(item.AssortmentDetailBudgetRef__c);
            }
            if (item.Assortment__c != null) {
                assortmentIds.add(item.Assortment__c);
            }
            if (item.Product__c != null) {
                productIds.add(item.Product__c);
            }
        }
        Map<Id, AssortmentDetail__c> relatedAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>();
        if(!relatedASDIds.isEmpty()) {
            relatedAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>([SELECT Id, AssortmentDetailLHistory__c, AssortmentDetailLHistory__r.QtyNego__c,
                                                                                      WDChannelBaseBudget__c, NDClientBaseNegoL4L__c, NDClientBasePanel__c,
                                                                                      WDClientBaseNegoL4L__c, WDClientBasePanel__c, SOSNumberNegoL4L__c, SOSNumberNego__c, QtyPanel__c, KVolumePanel__c,
                                                                                      WDChannelBaseNegoL4L__c, WDChannelBasePanel__c, PNClientBaseNegoL4L__c, QtyNego__c, GPNego__c,
                                                                                      SellOutNego__c, SellInNego__c, NDChannelBaseNegoL4L__c, NDChannelBasePanel__c, NDChannelBaseBudget__c,
                                                                                      ProductCluster__c, SelloutPanel__c, GPNego_NegoP1Gap__c, KVolumeNego_NegoP1Gap__c, SelloutNego_NegoP1Gap__c
                                                                                      FROM AssortmentDetail__c
                                                                                      WHERE Id IN :relatedASDIds]);
        }
        if (!relatedAssortmentDetailsMap.isEmpty()) {
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                Assortment__c assortment = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ? assortmentWrapper.assortmentBUMap.get(item.Assortment__c) : new Assortment__c();        
                if (item.AssortmentDetailNegotiationRef__c != null
                    && (item.Id == null || (oldAssortmentDetailMap.containsKey(item.Id) && item.AssortmentDetailNegotiationRef__c != oldAssortmentDetailMap.get(item.Id).AssortmentDetailNegotiationRef__c)))
                {
                    Boolean negoRefChanged = item.AssortmentDetailNegotiationRef__c != null && relatedAssortmentDetailsMap.containsKey(item.AssortmentDetailNegotiationRef__c);
                    item.NDClientBaseNegoL4L_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).NDClientBaseNegoL4L__c : 0;
                    item.NDClientBasePanel_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).NDClientBasePanel__c : 0;
                    item.WDClientBaseNegoL4L_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).WDClientBaseNegoL4L__c : 0;
                    item.WDClientBasePanel_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).WDClientBasePanel__c : 0;
                    item.SelloutNego_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).SellOutNego__c : 0;
                    item.SellinNego_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).SellInNego__c : 0;
                    item.NDChannelBasePanel_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).NDChannelBasePanel__c : 0;
                    item.ProductClusterASDNego__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).ProductCluster__c : null;
                    item.PNClientBaseNegoL4L_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).PNClientBaseNegoL4L__c : 0;
                    item.SelloutPanel_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).SelloutPanel__c : 0;
                    if (assortment.RecordType.DeveloperName != 'ChannelBudget') {
                        item.WDChannelBaseNegoL4L_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).WDChannelBaseNegoL4L__c : 0;
                        item.NDChannelBaseNegoL4L_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).NDChannelBaseNegoL4L__c : 0;
                        item.WDChannelBasePanel_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).WDChannelBasePanel__c : 0;
                    }
                    if (item.Assortment__c != null
                        && assortment.RecordType.DeveloperName != 'ChannelBudget'
                        && assortment.RecordType.DeveloperName != 'OnTopConso'
                        && assortment.RecordType.DeveloperName != 'TargetConso'
                        && item.AssortmentDetailNegotiationRef__c != null
                        && relatedAssortmentDetailsMap.containsKey(item.AssortmentDetailNegotiationRef__c))
                    {
                        item.SOSNumberNegoL4L_P1__c = relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).SOSNumberNegoL4L__c;
                        item.SOSNumberNego_P1__c = relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).SOSNumberNego__c;
                        item.QtyPanel_P1__c = relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).QtyPanel__c;
                        item.KVolumePanel_P1__c = relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).KVolumePanel__c;
                    } else {
                        item.SOSNumberNegoL4L_P1__c = 0;
                        item.SOSNumberNego_P1__c = 0;
                    }
               }
                if (item.AssortmentDetailBudgetRef__c != null
                    && (item.Id == null || (oldAssortmentDetailMap.containsKey(item.Id) && item.AssortmentDetailBudgetRef__c != oldAssortmentDetailMap.get(item.Id).AssortmentDetailBudgetRef__c)))
                {
                    Boolean budgetRefChanged = item.AssortmentDetailBudgetRef__c != null && relatedAssortmentDetailsMap.containsKey(item.AssortmentDetailBudgetRef__c);
                    item.WDChannelBaseTarget_BudgetWeight__c = budgetRefChanged && relatedAssortmentDetailsMap.get(item.AssortmentDetailBudgetRef__c).WDChannelBaseBudget__c != null && relatedAssortmentDetailsMap.get(item.AssortmentDetailBudgetRef__c).WDChannelBaseBudget__c != 0 ? ((item.WDChannelBaseTarget__c != null ? item.WDChannelBaseTarget__c : 0) / relatedAssortmentDetailsMap.get(item.AssortmentDetailBudgetRef__c).WDChannelBaseBudget__c * 100).setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_BudgetWeight__c.Scale) : 0;
                    item.WDChannelBaseBudget_P1__c = budgetRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailBudgetRef__c).WDChannelBaseBudget__c : 0;
                    item.NDChannelBaseBudget_P1__c = budgetRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailBudgetRef__c).NDChannelBaseBudget__c : 0;
                }
            }
            System.Formula.recalculateFormulas(assortmentWrapper.assortmentDetails);
        }
        Map<Id, Product2> productsMap = new Map<Id, Product2>([SELECT Id, TotalKWeight__c, VATRate__c
                                                               FROM Product2
                                                               WHERE Id IN :productIds]);
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            Assortment__c assortment = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ? assortmentWrapper.assortmentBUMap.get(item.Assortment__c) : new Assortment__c();
            String KPI = String.isNotBlank(assortSettings.KPI) ? assortSettings.KPI : 'WD';
            item.PNChannelBaseNegoL4L__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L__c.Scale) : 0;
            item.PNChannelBaseNego__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNego__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNego__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego__c.Scale) : 0;
            item.PNChannelBaseTarget__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseTarget__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseTarget__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseTarget__c.Scale) : 0;
            item.PNChannelBaseBudget__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseBudget__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseBudget__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget__c.Scale) : 0;
            item.PNClientBaseNegoL4L__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseNegoL4L__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseNegoL4L__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNClientBaseNegoL4L__c.Scale) : 0;
            item.PNClientBaseNego__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseNego__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseNego__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNClientBaseNego__c.Scale) : 0;
            item.PNClientBaseTarget__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseTarget__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ClientBaseTarget__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNClientBaseTarget__c.Scale) : 0;
            item.PNChannelBaseNegoL4L_P1__c = item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) != null ? ((Decimal) item.get(NegoptimHelper.normalizeAPIName(KPI + 'ChannelBaseNegoL4L_P1__c')) / 100).setScale(SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L_P1__c.Scale) : 0;
            item.WDChannelBaseBudget_NegoL4LP1Gap__c = (item.WDChannelBaseBudget__c != null ? item.WDChannelBaseBudget__c : 0) - (item.WDChannelBaseNegoL4L_P1__c != null ? item.WDChannelBaseNegoL4L_P1__c : 0);
        	item.NDChannelBaseBudget_NegoL4LP1Gap__c = (item.NDChannelBaseBudget__c != null ? item.NDChannelBaseBudget__c : 0) - (item.NDChannelBaseNegoL4L_P1__c != null ? item.NDChannelBaseNegoL4L_P1__c : 0);
            if (item.WDchannelBasebudget__c != null && item.WDchannelBasebudget__c != 0) {
                item.PNChannelBaseBudget_NegoL4LP1Gap__c = (item.PNChannelBaseBudget__c != null ? item.PNChannelBaseBudget__c : 0) - (item.PNChannelBaseNegoL4L_P1__c != null ? item.PNChannelBaseNegoL4L_P1__c : 0);
            }
            
            Decimal productTotalKW = item.Product__c != null && productsMap.containsKey(item.Product__c) && productsMap.get(item.Product__c).TotalKWeight__c != null ? productsMap.get(item.Product__c).TotalKWeight__c : 0;
            Decimal AWS = item.AvgWeeklySalesClient__c != 0 && item.AvgWeeklySalesClient__c != null ? item.AvgWeeklySalesClient__c : (item.AvgWeeklySalesChannel__c != null ? item.AvgWeeklySalesChannel__c : 0);
            //Qté/Volume/Kvolume calculations
            // calculation of QtyNego_P1, KVolumeNego_P1
            if (item.Assortment__c != null
                && (assortment.RecordType.DeveloperName == 'Negotiation'
                    || assortment.RecordType.DeveloperName == 'Target'
                    || assortment.RecordType.DeveloperName == 'Simulation'))
                {
                if (item.AssortmentDetailNegotiationRef__c != null
                    && (item.Id == null || (oldAssortmentDetailMap.containsKey(item.Id) && item.AssortmentDetailNegotiationRef__c != oldAssortmentDetailMap.get(item.Id).AssortmentDetailNegotiationRef__c)))
                {
                    Boolean negoRefChanged = item.AssortmentDetailNegotiationRef__c != null && relatedAssortmentDetailsMap.containsKey(item.AssortmentDetailNegotiationRef__c);
                    if (!assortSettings.applyCalcFullYearQty_P1) {
                        item.QtyNego_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).QtyNego__c : 0;
                    }
                    item.GPNego_P1__c = negoRefChanged ? relatedAssortmentDetailsMap.get(item.AssortmentDetailNegotiationRef__c).GPNego__c : 0;
                }
                    if (assortSettings.applyCalcFullYearQty_P1) {
                        item.QtyNego_P1__c = ((item.SOSNumberNegoL4L_P1__c != null ? item.SOSNumberNegoL4L_P1__c : 0) * AWS * 52).setScale(SObjectType.AssortmentDetail__c.fields.QtyNego_P1__c.Scale, System.RoundingMode.HALF_UP);
                }
            }
        }
        System.Formula.recalculateFormulas(assortmentWrapper.assortmentDetails);
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            Assortment__c assortment = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ? assortmentWrapper.assortmentBUMap.get(item.Assortment__c) : new Assortment__c();
            Decimal productTotalKW = item.Product__c != null && productsMap.containsKey(item.Product__c) && productsMap.get(item.Product__c).TotalKWeight__c != null ? productsMap.get(item.Product__c).TotalKWeight__c : 0;
            Decimal AWS = item.AvgWeeklySalesClient__c != 0 && item.AvgWeeklySalesClient__c != null ? item.AvgWeeklySalesClient__c : (item.AvgWeeklySalesChannel__c != null ? item.AvgWeeklySalesChannel__c : 0);
            item.KVolumeNego_P1__c = ((item.QtyNego_P1__c != null ? item.QtyNego_P1__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeNego_P1__c.Scale, System.RoundingMode.HALF_UP);
            
            // calculation of QtyBudget, KVolumeBudget
            if (item.Assortment__c != null && assortment.RecordType.DeveloperName == 'ChannelBudget') {
                if (!item.IsAdditionalProduct__c) {
                    item.QtyBudget__c = ((item.QtyNego_P1__c != null ? item.QtyNego_P1__c : 0) * (1 + (item.WDChannelBaseNegoL4L_P1__c != null && item.WDChannelBaseNegoL4L_P1__c != 0 ? ((item.WDChannelBaseBudget_NegoL4LP1Gap__c != null ? item.WDChannelBaseBudget_NegoL4LP1Gap__c : 0) / item.WDChannelBaseNegoL4L_P1__c) : 0))).setScale(SObjectType.AssortmentDetail__c.fields.QtyBudget__c.Scale, System.RoundingMode.HALF_UP);
                }
                item.KVolumeBudget__c = ((item.QtyBudget__c != null ? item.QtyBudget__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeBudget__c.Scale, System.RoundingMode.HALF_UP);
            }
            
            // calculation of QtyTarget, KVolumeTarget
            if (item.Assortment__c != null && assortment.RecordType.DeveloperName == 'Target') {
                item.QtyTarget__c = (item.QtyNego_P1__c != null ? item.QtyNego_P1__c : 0) + ((item.SOSNumberTarget_NegoL4LP1Gap__c != null ? item.SOSNumberTarget_NegoL4LP1Gap__c : 0) * AWS * (52 - (item.StartDate_W__c != null ? item.StartDate_W__c : 0) + 1)).setScale(0);
                item.KVolumeTarget__c = ((item.QtyTarget__c != null ? item.QtyTarget__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeTarget__c.Scale, System.RoundingMode.HALF_UP);
            }
            // calculation of QtyNego, KVolumeNego
            if (item.Assortment__c != null && (assortment.RecordType.DeveloperName == 'Negotiation' || assortment.RecordType.DeveloperName == 'Simulation')) {
                item.QtyNego__c = (item.QtyNego_P1__c != null ? item.QtyNego_P1__c : 0) + ((item.SOSNumberNego_NegoL4LP1Gap__c != null ? item.SOSNumberNego_NegoL4LP1Gap__c : 0) * AWS * (52 - (item.StartDate_W__c != null ? item.StartDate_W__c : 0) + 1)).setScale(0);
                item.KVolumeNego__c = ((item.QtyNego__c != null ? item.QtyNego__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Scale, System.RoundingMode.HALF_UP);
            }
            // calculation of KVolumePanel, KVolumefact
            item.KVolumePanel__c = ((item.QtyPanel__c != null ? item.QtyPanel__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumePanel__c.Scale, System.RoundingMode.HALF_UP);
            item.KVolumeFact__c = ((item.QtyFact__c != null ? item.QtyFact__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeFact__c.Scale, System.RoundingMode.HALF_UP);
            if (item.Assortment__c != null) {
                Decimal productVatRate = item.Product__c != null && productsMap.containsKey(item.Product__c) && productsMap.get(item.Product__c).VATRate__c != null ? productsMap.get(item.Product__c).VATRate__c / 100 : 0;
                Decimal retailPriceHT = (item.RetailPriceTarget__c != null ? item.RetailPriceTarget__c : 0) / (1 + productVatRate);
                if (assortment.RecordType.DeveloperName == 'Target') {
                    item.GPUnitTarget__c = (item.DeadProfitPrice__c != null ? item.DeadProfitPrice__c : 0) - (item.UnitCost__c != null ? item.UnitCost__c : 0);
                    item.GPTarget__c = (item.GPUnitTarget__c != null ? item.GPUnitTarget__c : 0) * (item.QtyTarget__c != null ? item.QtyTarget__c : 0);
                    item.SellInTarget__c = (item.NetPriceTradeBase__c != null ? item.NetPriceTradeBase__c : 0) * (item.QtyTarget__c != null ? item.QtyTarget__c : 0);
                    item.SellOutTarget__c = retailPriceHT * (item.QtyTarget__c != null ? item.QtyTarget__c : 0);
                    item.TMTarget__c = (retailPriceHT - (item.NegoPrice__c != null ? item.NegoPrice__c : 0)) * (item.QtyTarget__c != null ? item.QtyTarget__c : 0);
                } else {
                    item.GPUnitNego__c = (item.DeadProfitPrice__c != null ? item.DeadProfitPrice__c : 0) - (item.UnitCost__c != null ? item.UnitCost__c : 0);
                    item.GPNego__c = (item.GPUnitNego__c != null ? item.GPUnitNego__c : 0) * (item.QtyNego__c != null ? item.QtyNego__c : 0);
                    item.SellInNego__c = (item.NetPriceTradeBase__c != null ? item.NetPriceTradeBase__c : 0) * (item.QtyNego__c != null ? item.QtyNego__c : 0);
                    item.SellOutNego__c = retailPriceHT * (item.QtyNego__c != null ? item.QtyNego__c : 0);
                    item.TMNego__c = (retailPriceHT - (item.NegoPrice__c != null ? item.NegoPrice__c : 0)) * (item.QtyNego__c != null ? item.QtyNego__c : 0);
                }
            }
        }
    }

    private static void calculeRelatedLinesFields(AssortmentWrapper assortmentWrapper, List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        Set<Id> modifiedIdsRefNego = new Set<Id>();
        Set<Id> modifiedIdsRefBudget = new Set<Id>();
        Set<Id> modifiedNegoIds = new Set<Id>();
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        for (AssortmentDetail__c item : newAssortmentDetails) {
            if (oldAssortmentDetailMap != null
                && oldAssortmentDetailMap.containsKey(item.Id)
                && (item.NDClientBasePanel__c != oldAssortmentDetailMap.get(item.Id).NDClientBasePanel__c
                   || item.WDClientBasePanel__c != oldAssortmentDetailMap.get(item.Id).WDClientBasePanel__c
                   || item.SellOutNego__c != oldAssortmentDetailMap.get(item.Id).SellOutNego__c
                   || item.SellInNego__c != oldAssortmentDetailMap.get(item.Id).SellInNego__c
                   || item.WDChannelBasePanel__c != oldAssortmentDetailMap.get(item.Id).WDChannelBasePanel__c
                   || item.NDChannelBasePanel__c != oldAssortmentDetailMap.get(item.Id).NDChannelBasePanel__c
                   || item.QtyNego__c != oldAssortmentDetailMap.get(item.Id).QtyNego__c
                   || item.QtyPanel__c != oldAssortmentDetailMap.get(item.Id).QtyPanel__c))
            {
                modifiedIdsRefNego.add(item.Id);
            }
            if (oldAssortmentDetailMap != null
                && oldAssortmentDetailMap.containsKey(item.Id)
                && item.WDChannelBaseBudget__c != oldAssortmentDetailMap.get(item.Id).WDChannelBaseBudget__c)
            {
                modifiedIdsRefBudget.add(item.Id);
            }
        }
        if(!modifiedIdsRefNego.isEmpty() || !modifiedIdsRefBudget.isEmpty()) {
            List<AssortmentDetail__c> assortmentDetailList = [SELECT Id, Assortment__r.RecordType.DeveloperName, AssortmentDetailNegotiationRef__c, AssortmentDetailBudgetRef__c,
                                                              NDClientBasePanel_P1__c, WDClientBasePanel_P1__c, SelloutNego_P1__c, SelloutPanel_P1__c,
                                                              SellinNego_P1__c, WDChannelBasePanel_P1__c, QtyNego_P1__c, GPNego_P1__c, KVolumePanel_P1__c, QtyPanel_P1__c, WDChannelBaseTarget_BudgetWeight__c,
                                                              WDChannelBaseBudget_P1__c, NDChannelBaseBudget_P1__c,
                                                              AssortmentDetailNegotiationRef__r.NDClientBasePanel__c,
                                                              AssortmentDetailNegotiationRef__r.WDClientBasePanel__c, NDChannelBasePanel_P1__c, AssortmentDetailNegotiationRef__r.NDChannelBasePanel__c,
                                                              AssortmentDetailNegotiationRef__r.QtyNego__c, AssortmentDetailNegotiationRef__r.GPNego__c, AssortmentDetailNegotiationRef__r.WDChannelBasePanel__c,
                                                              AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c, AssortmentDetailBudgetRef__r.NDChannelBaseBudget__c, AssortmentDetailNegotiationRef__r.QtyPanel__c, WDChannelBaseTarget__c,
                                                              AssortmentDetailNegotiationRef__r.SellOutNego__c, AssortmentDetailNegotiationRef__r.SelloutPanel__c, AssortmentDetailNegotiationRef__r.SellInNego__c,
                                                              AssortmentDetailNegotiationRef__r.GPNego_NegoP1Gap__c, AssortmentDetailNegotiationRef__r.KVolumeNego_NegoP1Gap__c, AssortmentDetailNegotiationRef__r.SelloutNego_NegoP1Gap__c,
                                                              Product__c, Product__r.TotalKWeight__c, AssortmentDetailNegotiationRef__r.KVolumePanel__c
                                                              FROM AssortmentDetail__c
                                                              WHERE (AssortmentDetailNegotiationRef__c <> NULL AND AssortmentDetailNegotiationRef__c IN :modifiedIdsRefNego)
                                                              OR (AssortmentDetailBudgetRef__c <> NULL AND AssortmentDetailBudgetRef__c IN :modifiedIdsRefBudget)];
            for (AssortmentDetail__c item : assortmentDetailList) {
                Boolean isUpdated = false;
                if ((item.AssortmentDetailNegotiationRef__c != null && modifiedIdsRefNego.contains(item.AssortmentDetailNegotiationRef__c))
                    || (item.AssortmentDetailBudgetRef__c != null && modifiedIdsRefBudget.contains(item.AssortmentDetailBudgetRef__c))) {
                        isUpdated = item.NDClientBasePanel_P1__c != item.AssortmentDetailNegotiationRef__r.NDClientBasePanel__c
                            || item.WDClientBasePanel_P1__c != item.AssortmentDetailNegotiationRef__r.WDClientBasePanel__c
                            || item.SelloutNego_P1__c != item.AssortmentDetailNegotiationRef__r.SellOutNego__c
                            || item.SelloutPanel_P1__c != item.AssortmentDetailNegotiationRef__r.SelloutPanel__c
                            || item.SellinNego_P1__c != item.AssortmentDetailNegotiationRef__r.SellInNego__c
                            || (item.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                                && (item.WDChannelBasePanel_P1__c != item.AssortmentDetailNegotiationRef__r.WDChannelBasePanel__c
                                    || item.NDChannelBasePanel_P1__c != item.AssortmentDetailNegotiationRef__r.NDChannelBasePanel__c
                                    || (item.QtyNego_P1__c != item.AssortmentDetailNegotiationRef__r.QtyNego__c
                                       || item.GPNego_P1__c != item.AssortmentDetailNegotiationRef__r.GPNego__c)))
                            || (item.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                                && item.Assortment__r.RecordType.DeveloperName != 'OnTopConso'
                                && item.Assortment__r.RecordType.DeveloperName != 'TargetConso'
                                && (item.QtyPanel_P1__c != item.AssortmentDetailNegotiationRef__r.QtyPanel__c
                                   || item.KVolumePanel_P1__c != item.AssortmentDetailNegotiationRef__r.KVolumePanel__c))
                            || (item.AssortmentDetailBudgetRef__c != null
                                && modifiedIdsRefBudget.contains(item.AssortmentDetailBudgetRef__c)
                                && (item.WDChannelBaseBudget_P1__c != item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c
                                    || item.NDChannelBaseBudget_P1__c != item.AssortmentDetailBudgetRef__r.NDChannelBaseBudget__c
                                    || item.WDChannelBaseTarget_BudgetWeight__c != (item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c != null ? ((item.WDChannelBaseTarget__c != null ? item.WDChannelBaseTarget__c : 0) / item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c * 100) : 0)));
                        if (isUpdated) {
                            AssortmentDetail__c detailToUpdate = new AssortmentDetail__c(Id = item.Id);
                            detailToUpdate.NDClientBasePanel_P1__c = item.AssortmentDetailNegotiationRef__r.NDClientBasePanel__c;
                            detailToUpdate.WDClientBasePanel_P1__c = item.AssortmentDetailNegotiationRef__r.WDClientBasePanel__c;
                            detailToUpdate.SelloutNego_P1__c = item.AssortmentDetailNegotiationRef__r.SellOutNego__c;
                            detailToUpdate.SelloutPanel_P1__c = item.AssortmentDetailNegotiationRef__r.SelloutPanel__c;
                            detailToUpdate.SellinNego_P1__c = item.AssortmentDetailNegotiationRef__r.SellInNego__c;
                            if (item.Assortment__r.RecordType.DeveloperName != 'ChannelBudget') {
                                detailToUpdate.WDChannelBasePanel_P1__c = item.AssortmentDetailNegotiationRef__r.WDChannelBasePanel__c;
                                detailToUpdate.NDChannelBasePanel_P1__c = item.AssortmentDetailNegotiationRef__r.NDChannelBasePanel__c;
                                detailToUpdate.QtyNego_P1__c = item.AssortmentDetailNegotiationRef__r.QtyNego__c;
                                detailToUpdate.GPNego_P1__c = item.AssortmentDetailNegotiationRef__r.GPNego__c;
                                Decimal productTotalKW = item.Product__c != null && item.Product__r.TotalKWeight__c != null ? item.Product__r.TotalKWeight__c : 0;
                                detailToUpdate.KVolumeNego_P1__c = ((detailToUpdate.QtyNego_P1__c != null ? detailToUpdate.QtyNego_P1__c : 0) * productTotalKW).setScale(SObjectType.AssortmentDetail__c.fields.KVolumeNego_P1__c.Scale, System.RoundingMode.HALF_UP);
                            }
                            if (item.Assortment__r.RecordType.DeveloperName != 'ChannelBudget'
                                && item.Assortment__r.RecordType.DeveloperName != 'OnTopConso'
                                && item.Assortment__r.RecordType.DeveloperName != 'TargetConso')
                            {
                                detailToUpdate.QtyPanel_P1__c = item.AssortmentDetailNegotiationRef__r.QtyPanel__c;
                                detailToUpdate.KVolumePanel_P1__c = item.AssortmentDetailNegotiationRef__r.KVolumePanel__c;
                            }
                            if (item.AssortmentDetailBudgetRef__c != null && modifiedIdsRefBudget.contains(item.AssortmentDetailBudgetRef__c)) {
                                detailToUpdate.WDChannelBaseTarget_BudgetWeight__c = item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c != null ? ((item.WDChannelBaseTarget__c != null ? item.WDChannelBaseTarget__c : 0) / item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c * 100).setScale(SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_BudgetWeight__c.Scale) : 0;
                                detailToUpdate.WDChannelBaseBudget_P1__c = item.AssortmentDetailBudgetRef__r.WDChannelBaseBudget__c;
                                detailToUpdate.NDChannelBaseBudget_P1__c = item.AssortmentDetailBudgetRef__r.NDChannelBaseBudget__c;
                            }
                            detailsToUpdate.add(detailToUpdate);
                        }
                    }
            }
            if (!detailsToUpdate.isEmpty()) {
                update detailsToUpdate;
            }
        }
        if (!System.isBatch() && !System.isFuture()) {
            Set<Id> buSourceIds = new Set<Id>();
            Set<Id> categoryIds = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Set<Integer> nextyearSet = new Set<Integer>();
            Map<String, List<Id>> negoMapkeys = new Map<String, List<Id>>();
            for (Assortment__c item : assortmentWrapper.assortmentBUMap.values()) {
                if (item.RecordType.DeveloperName == 'Negotiation') {
                    buSourceIds.add(item.BusinessUnitSource__c);
                    categoryIds.add(item.Hierarchy__c);
                    yearSet.add(Integer.valueOf(item.Year__c));
                    nextyearSet.add(Integer.valueOf(item.Year__c + 1));
                }
            }
            if (!buSourceIds.isEmpty() && !categoryIds.isEmpty() && !yearSet.isEmpty()) {
                List<Assortment__c> budgetAssortments = [SELECT Id, BusinessUnitTarget__c, Hierarchy__c, Year__c
                                                         FROM Assortment__c
                                                         WHERE BusinessUnitTarget__c IN :buSourceIds
                                                         AND Hierarchy__c IN :categoryIds
                                                         AND Year__c IN :nextyearSet
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
                                'startedFrom' => Trg_AssortmentDetail_Handler.class.getName(),
                                'budgetId' => item.Id,
                                'assortmentNegoIds' => negoMapkeys.get(key),
                                'introProductIds' => null
                            };
                            NegoptimBatch.executeBatch('GenerateAssortmentBudgetDetailsBatch', paramsMap, 20);
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Fill AssortmentDetailTargetRef__c and AssortmentDetailNegotiationRef__c on insert
     * On Before Insert
     * */
    private static void linkRefASD(AssortmentWrapper assortmentWrapper) {
        Set<Id> targetAssortmentSet = new Set<Id>();
        Set<Id> budgetAssortmentSet = new Set<Id>();
        Set<Id> negoAssortmentSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Map<String, AssortmentDetail__c> assortmentDetailKeyMap = new Map<String, AssortmentDetail__c>();
        // Load AssortmentTargetRef__c and AssortmentNegotiationRef__c Assortment IDs
        for (AssortmentDetail__c item: assortmentWrapper.assortmentDetails) {
            if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                if (assortmentBU.AssortmentTargetRef__c != null) {
                    targetAssortmentSet.add(assortmentBU.AssortmentTargetRef__c);
                }
                if (assortmentBU.AssortmentChannelBudgetRef__c != null) {
                    budgetAssortmentSet.add(assortmentBU.AssortmentChannelBudgetRef__c);
                }
                if (assortmentBU.AssortmentNegotiationRef__c != null) {
                    negoAssortmentSet.add(assortmentBU.AssortmentNegotiationRef__c);
                }
                productSet.add(item.Product__c);
            }
        }

        if (!productSet.isEmpty() && (!targetAssortmentSet.isEmpty() || !budgetAssortmentSet.isEmpty() || !negoAssortmentSet.isEmpty())) {
            // check security on access AssortmentDetail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Id.Name,
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.Version__c.Name
            };
            if(NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                for (AssortmentDetail__c item : [SELECT Id, Assortment__c, Product__c
                                                 FROM AssortmentDetail__c
                                                 WHERE Product__c IN :productSet
                                                 AND (Assortment__c IN :targetAssortmentSet OR Assortment__c IN :budgetAssortmentSet OR Assortment__c IN :negoAssortmentSet)
                                                 AND Version__c = NULL])
                {
                    String key = item.Assortment__c + '' + item.Product__c;
                    assortmentDetailKeyMap.put(Key, item);
                }
            }
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                // link to ref Target
                if (assortmentBU.AssortmentTargetRef__c != null && targetAssortmentSet.contains(assortmentBU.AssortmentTargetRef__c)) {
                    String key = assortmentBU.AssortmentTargetRef__c + '' + item.Product__c;
                    item.AssortmentDetailTargetRef__c = assortmentDetailKeyMap.containsKey(key) ? assortmentDetailKeyMap.get(key).Id : null;
                }
                // link to ref Budget
                if (assortmentBU.AssortmentChannelBudgetRef__c != null && budgetAssortmentSet.contains(assortmentBU.AssortmentChannelBudgetRef__c)) {
                    String key = assortmentBU.AssortmentChannelBudgetRef__c + '' + item.Product__c;
                    item.AssortmentDetailBudgetRef__c = assortmentDetailKeyMap.containsKey(key) ? assortmentDetailKeyMap.get(key).Id : null;
                }
                // link to ref Nego
                if (assortmentBU.AssortmentNegotiationRef__c != null && negoAssortmentSet.contains(assortmentBU.AssortmentNegotiationRef__c)) {
                    String key = assortmentBU.AssortmentNegotiationRef__c + '' + item.Product__c;
                    item.AssortmentDetailNegotiationRef__c = assortmentDetailKeyMap.containsKey(key) ? assortmentDetailKeyMap.get(key).Id : null;
                }
            }
        }
    }
	/**
     * @description creates history lines in case Status__c = 'Validate' and specific fields have changed OR in case Product__c changed (CASE SWITCH),
     * history creation process:
     * 1- assortment detail is cloned and the clone is given a new version and inserted
     * 2- the status of the detail is set to 'InPreparation' and saved
     * on Before update because we can't change status after update (fields are read only)
	*/
    private static void updateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            // add history for updating assortment details
            Map<Id, AssortmentDetail__c> assotmentDetailsHistoryMap = new Map<Id, AssortmentDetail__c>();
            Map<Id, AssortmentDetail__c> assotmentDetailsUpdatedMap = new Map<Id, AssortmentDetail__c>();
            Set<Id> assortmentBUSet = new Set<Id>();
            Set<Id> categorySet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            Set<Id> lastHistorySet = new Set<Id>();
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                String assortmentRecordType = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ?
                    assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName : '';
                if (assortmentRecordType == 'ChannelBudget') {
                    continue;
                }
                // change assortment detail status from null to InPreparation
                // TODO: we can replace by the condition (item.Id != null && item.Status__c == null) and remove the method hasChanged
                if (item.Status__c == null && hasChanged(item, oldAssortmentDetailMap.get(item.Id))) {
                    item.Status__c = 'InPreparation';
                }
                // add history for updating assortment details
                if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) && oldAssortmentDetailMap != null && oldAssortmentDetailMap.get(item.Id) != null) {
                    Boolean isRecordModifiedForHisto = item.StartDate__c != oldAssortmentDetailMap.get(item.Id).StartDate__c
                        || item.ProductLifeStatusAss__c != oldAssortmentDetailMap.get(item.Id).ProductLifeStatusAss__c
                        || item.IsNewProduct__c != oldAssortmentDetailMap.get(item.Id).IsNewProduct__c;
                    // check if clusters strats or cplt have been modified
                    Boolean isStratSerializedChanged = item.ProductCluster__c != oldAssortmentDetailMap.get(item.Id).ProductCluster__c
                        || item.ClientCategory__c != oldAssortmentDetailMap.get(item.Id).ClientCategory__c
                        || item.BusinessUnitCluster__c != oldAssortmentDetailMap.get(item.Id).BusinessUnitCluster__c;
                    
                    isRecordModifiedForHisto = isRecordModifiedForHisto || isStratSerializedChanged;
                    system.debug('isRecordModifiedForHisto >>> ' + isRecordModifiedForHisto);
                    if (item.Status__c == 'Validate'
                        && item.Status__c.equals(oldAssortmentDetailMap.get(item.Id).Status__c)
                        && item.Version__c == null
                        /*&& item.StartDate__c != null && item.ProductLifeStatusAss__c != null*/
                        && isRecordModifiedForHisto)
                    {
                        if(!assortmentBUSet.contains(item.Assortment__c)) {
                            assortmentBUSet.add(item.Assortment__c);
                        }
                        if (!categorySet.contains(item.Hierarchy__c)) {
                            categorySet.add(item.Hierarchy__c);
                        }
                        if(!productSet.contains(item.Product__c)) {
                            productSet.add(item.Product__c);
                        }
                        item.Status__c = 'InPreparation';
                        assotmentDetailsUpdatedMap.put(item.Id , item);
                    }
                    Boolean isNegoAssortment = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) && assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName == 'Negotiation';
                    if ((item.Status__c == 'Validate' && item.Version__c == null)
                        && (
                            item.Status__c != oldAssortmentDetailMap.get(item.Id).Status__c
                            || (
                                isNegoAssortment
                                && oldAssortmentDetailMap.get(item.Id).Status__c == 'InPreparation'
                                && assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Status__c == 'Validate'
                            )
                        )) {
                        // get last history
                        // TODO: remove contains checks on sets, here and in the entire class
                        if(item.AssortmentDetailLHistory__c != null && !lastHistorySet.contains(item.AssortmentDetailLHistory__c)) {
                            lastHistorySet.add(item.AssortmentDetailLHistory__c);
                        }
                        if (item.Status__c == 'Validate') {
                            item.ValidateDate__c = date.today();
                        }
                    }
                }
            }
            // add history for updating assortment details
            if(!productSet.isEmpty()) {
                Map<String, Integer> lastAssortmentDetailsMap = new Map<String, Integer>();
                // check security on access AssortmentDetail__c
                String[] assortmentDetailAccessFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Version__c.Name
                };
                if(NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailAccessFields)) {
                    // get last version
                    // TODO: check if it is possible to merge this query with the later query of last history assortment details
                    List<AggregateResult> assortmentResults = [SELECT Assortment__c Assortment__c, Hierarchy__c Hierarchy__c, Product__c Product__c, MAX(Version__c) LastVersion
                                                               FROM AssortmentDetail__c
                                                               WHERE Assortment__c IN :assortmentBUSet AND Hierarchy__c IN :categorySet
                                                               AND Product__c IN :productSet AND Version__c <> NULL
                                                               GROUP BY Assortment__c, Hierarchy__c, Product__c];
                    for(AggregateResult item :assortmentResults) {
                        Id assortmentBUId = (Id) item.get('Assortment__c');
                        Id categoryId = (Id) item.get('Hierarchy__c');
                        Id productId = (Id) item.get('Product__c');
                        Integer lastVersion = Integer.valueOf(item.get('LastVersion'));
                        String key = assortmentBUId + '' + categoryId + '' + productId;
                        lastAssortmentDetailsMap.put(key, lastVersion);
                    }
                }
                // Map to keep track of history to add errors to original record in case insert failed
                Map<String, AssortmentDetail__c> ASDtoHistoMap = new Map<String, AssortmentDetail__c>();
                for (AssortmentDetail__c item : assotmentDetailsUpdatedMap.values()) {
                    system.debug('createHistoo >>> ');
                    // update version for old assortment detail
                    AssortmentDetail__c oldAssortmentDetail = oldAssortmentDetailMap.get(item.Id).clone(false);
                    ASDtoHistoMap.put(item.Product__c + '' + item.Assortment__c, item);
                    String key = item.Assortment__c + '' + item.Hierarchy__c + '' + oldAssortmentDetailMap.get(item.Id).Product__c;
                    Integer lastVersion = lastAssortmentDetailsMap.containsKey(key) ? lastAssortmentDetailsMap.get(key) : 0;
                    oldAssortmentDetail.Version__c = lastVersion + 1;
                    oldAssortmentDetail.ExtId__c = null;
                    assotmentDetailsHistoryMap.put(item.Id, oldAssortmentDetail);
                    // get last history
                    if(item.AssortmentDetailLHistory__c != null && !lastHistorySet.contains(item.AssortmentDetailLHistory__c)) {
                        lastHistorySet.add(item.AssortmentDetailLHistory__c);
                    }
                }
                // insert history
                if(!assotmentDetailsHistoryMap.isEmpty()) {
                    // check security on update AssortmentDetail__c
                    String[] assortmentDetailFields = new String[] {
                        SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                        SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                        SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
                        SObjectType.AssortmentDetail__c.fields.Version__c.Name
                        ,SObjectType.AssortmentDetail__c.fields.ExtId__c.Name
                    };
                    if(NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                        system.debug('assotmentDetailsHistoryMap >>> ' + JSON.serialize(assotmentDetailsHistoryMap));
                        List<Database.SaveResult> results = Database.insert(assotmentDetailsHistoryMap.values(), false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            AssortmentDetail__c assortmentDetail = assotmentDetailsHistoryMap.values().get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                ASDtoHistoMap.get(assortmentDetail.Product__c + '' +  assortmentDetail.Assortment__c).addError(errorMessage);
                            }
                        }
                    }
                    for (AssortmentDetail__c item : assotmentDetailsUpdatedMap.values()) {
                        AssortmentDetail__c lastAssortmentDetail;
                        lastAssortmentDetail = assotmentDetailsHistoryMap.get(item.Id);
                        if(lastAssortmentDetail != null) item.AssortmentDetailLHistory__c = lastAssortmentDetail.Id;
                    }
                }
            }
            // update history
            if(!lastHistorySet.isEmpty()) {
                List<AssortmentDetail__c> lastHistoryAssortmentDetails = new List<AssortmentDetail__c>();
                String[] assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.Id.Name,
                    SObjectType.AssortmentDetail__c.fields.Status__c.Name
                };
                if(NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    for(AssortmentDetail__c item : [SELECT Status__c FROM AssortmentDetail__c WHERE Id IN :lastHistorySet]) {
                        item.Status__c = 'PreviouslyValidate';
                        lastHistoryAssortmentDetails.add(item);
                    }
                }
                // check security on update AssortmentDetail__c
                assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Status__c.Name
                };
                if(NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    try {
                        update lastHistoryAssortmentDetails;
                    } catch (exception ex) {
                        System.debug('ex : ' + ex.getMessage() + '--' + ex.getLineNumber());
                        System.debug('ex : ' + ex.getStackTraceString());
                    }
                }
            }
        }
    }
    
    private static boolean hasChanged(AssortmentDetail__c newDetail, AssortmentDetail__c oldDetail) {
        Map<String, Object> newValues = newDetail.getPopulatedFieldsAsMap();
        Map<String, Object> oldValues = oldDetail.getPopulatedFieldsAsMap();
        for(String key: newValues.keySet()) {
            if(newValues.get(key) != oldValues.get(key)) {
                return true;
            }
        }
        return false;
    }

    private static void handleProductSwitch(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            Set<Id> assortmentBUSet = new Set<Id>();
            Set<Id> categorySet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            Set<Id> newCategorySet = new Set<Id>();
            Set<Id> newProductSet = new Set<Id>();
            // Map that contains the assortment details that were switched
            Map<Id, AssortmentDetail__c> switchedAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>();
            // a map of the substituted assortment details data: original detail Id => the substitute detail
            Map<Id, AssortmentDetail__c> substituteAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>();
            // a map of a clone of the previous version of the assortment detail: original detail Id => historyDetail
            Map<Id, AssortmentDetail__c> historyAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>();
            // a map of a the assortment detail to update: original detail Id => new Product Assortment Detail
            List<AssortmentDetail__c> assortmentDetailsToUpdateList = new List<AssortmentDetail__c>();
            // a map of a the assortment detail to delete: original detail Id => new Product Assortment Detail
            List<AssortmentDetail__c> assortmentDetailsToDeleteList = new List<AssortmentDetail__c>();
            // map the the existing assortment details of the new product
            Map<String, AssortmentDetail__c> assortmentDetailsExistForSwitchMap = new Map<String, AssortmentDetail__c>();

            // keep track of assortment details to add errors in case of exceptions of validation rules
            // productId + assortmentBUId => assortmentDetailId
            Map<String, Id> histoToAssortmentDetailMap = new Map<String, Id>();
            Map<String, Id> substituteToAssortmentDetailMap = new Map<String, Id>();
            Map<String, Id> detailsToUpdateToAssortmentDetailMap = new Map<String, Id>();
            Map<String, Id> detailsToDeleteToAssortmentDetailMap = new Map<String, Id>();

            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                // if the assortment detail is of a budget, then ignore it
                String assortmentRecordType = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ?
                    assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName : '';
                if (assortmentRecordType == 'ChannelBudget') {
                    continue;
                }
                // check if product was switched
                if (item.Id != null // only for case update
                    && oldAssortmentDetailMap.containsKey(item.Id)
                    && item.Product__c != oldAssortmentDetailMap.get(item.Id).Product__c)
                {
                    if (item.ProductLifeStatusAss__c == 'Delist' && item.Status__c == 'Validate' && item.Version__c == null) { // CASE 3 no switch
                        item.Product__c = oldAssortmentDetailMap.get(item.Id).Product__c;
                        item.addError(Label.MSG_No_switch_client_status_deleted_status_validated);
                    }
                    // fill the id sets to query data later
                    assortmentBUSet.add(item.Assortment__c);
                    categorySet.add(oldAssortmentDetailMap.get(item.Id).Hierarchy__c);
                    productSet.add(oldAssortmentDetailMap.get(item.Id).Product__c);
                    // fill the id sets to query the new Products later
                    newCategorySet.add(item.Hierarchy__c);
                    newProductSet.add(item.Product__c);
                    // add to switchedAssortmentDetailsMap
                    switchedAssortmentDetailsMap.put(item.Id, item);
                }
            }
            if (!newProductSet.isEmpty()) {
                Map<Id, AssortmentDetail__c> assortmentDetailsMap = new Map<Id, AssortmentDetail__c> ();
                // check security on access AssortmentDetail__c
                String[] assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.Id.Name,
                    SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                    SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                    SObjectType.AssortmentDetail__c.fields.IsNewProduct__c.Name,
                    SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                    SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Version__c.Name
                };
                if(NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    // check if the new Products of the switch already exist in the assortmenents
                    for(AssortmentDetail__c item : [SELECT Id, Assortment__c, Hierarchy__c, Product__c, ProductLifeStatusAss__c, IsNewProduct__c, BusinessUnitCluster__c, Status__c,
                                                              AssortmentDetailLHistory__c, AssortmentDetailLHistory__r.Version__c, AssortmentDetailLHistory__r.ProductLifeStatusAss__c, AssortmentDetailLHistory__r.IsNewProduct__c,
                                                              AssortmentDetailLHistory__r.Status__c, AssortmentDetailLHistory__r.BusinessUnitCluster__c
                                                              FROM AssortmentDetail__c
                                                              WHERE Id IN :switchedAssortmentDetailsMap.keySet()
                                                              OR (Assortment__c IN :assortmentBUSet
                                                                  AND Hierarchy__c IN :newCategorySet
                                                                  AND Product__c IN :newProductSet
                                                                  AND Version__c = NULL)])
                    {
                        if(switchedAssortmentDetailsMap.containskey(item.Id)) {
                            assortmentDetailsMap.put(item.Id, item);
                        } else {
                            String key = item.Assortment__c + '' + item.Product__c;
                            assortmentDetailsExistForSwitchMap.put(key, item);
                        }
                    }
                }
                for (AssortmentDetail__c item : switchedAssortmentDetailsMap.values()) {
                    AssortmentDetail__c assortmentDetailWithLastHistoInfo = assortmentDetailsMap.get(item.Id);
                    Integer lastVersion = assortmentDetailWithLastHistoInfo != null && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.Version__c != null ?
                        (Integer) assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.Version__c : 0;
                    String switchKey = item.Assortment__c + '' + item.Product__c;
                    // set movement date
                    // CASE 1,2,4 :the new movement date of the assortment detail is the max between today and
                    // the current movement date of the assortment detail
                    // CASE 5: the movement date isn't changed
                    Date  mvntDate = item.StartDate__c == null || item.StartDate__c < Date.today() ? Date.today() : item.StartDate__c;
                    // in the exceptional case where the assortment's year is in the past, we should make sure that the movement date doesn't break any validation rules
                    // for that reason, the new movement date must be the min between the assortment end date and mvtDate
                    if (assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Year__c < Date.today().year()) {
                        mvntDate = mvntDate < assortmentWrapper.assortmentBUMap.get(item.Assortment__c).EDate__c ? mvntDate : assortmentWrapper.assortmentBUMap.get(item.Assortment__c).EDate__c;
                    }
                    if (item.Status__c != 'InPreparation' || item.AssortmentDetailLHistory__c != null) {
                        item.StartDate__c = mvntDate;
                    }
                    Boolean proceedInLogic = true;
                    // CASE 6.1, 6.3 => NO HISTO AND NO SUBSTITUTE
                    // case 4 with assortmentDetailsExistForSwitch => NO HISTO AND NO SUBSTITUTE
                    if(assortmentDetailsExistForSwitchMap.containsKey(switchKey)) { // case where the new product is already in the assortment
                        AssortmentDetail__c alreadyExisting = assortmentDetailsExistForSwitchMap.get(switchKey);

                        boolean case6_1 = (item.Status__c == 'InPreparation' || item.Status__c == 'RequestForApproval' || item.Status__c == null) && (alreadyExisting.Status__c == 'InPreparation' || alreadyExisting.Status__c == 'RequestForApproval' || alreadyExisting.Status__c == NULL);
                        boolean case6_3 = (item.Status__c == 'InPreparation' || item.Status__c == 'RequestForApproval' || item.Status__c == null) && alreadyExisting.Status__c == 'Validate';
                        boolean case4 = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__c != null && item.ProductLifeStatusAss__c == 'New' && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c == 'Delist';
                        if (( (case6_1 || case6_3) && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__c == null) || case4) {
                            if (!case4) {
                                item.Status__c = alreadyExisting.Status__c;
                                item.ProductLifeStatusAss__c = alreadyExisting.ProductLifeStatusAss__c;
                                item.BusinessUnitCluster__c  = alreadyExisting.BusinessUnitCluster__c;
                                item.AssortmentDetailLHistory__c = alreadyExisting.AssortmentDetailLHistory__c;
                            }
                            assortmentDetailsToDeleteList.add(alreadyExisting);
                            detailsToDeleteToAssortmentDetailMap.put(alreadyExisting.Product__c + '' + alreadyExisting.Assortment__c, item.Id);
                            proceedInLogic = false;
                        } else if (item.Status__c == 'Validate' && alreadyExisting.Status__c == 'Validate') { // CASE 6.4
                            item.Product__c = oldAssortmentDetailMap.get(item.Id).Product__c;
                            item.ProductLifeStatusAss__c = 'Delist';
                            continue; // in this case, we don't want the rest of the logic to be executed
                        }
                    }
                    // set status of existing histo to PreviouslyValidate
                    if (assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.Status__c == 'Validate') {
                        assortmentDetailsToUpdateList.add(new AssortmentDetail__c (id = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__c,
                                                                                    Status__c = 'PreviouslyValidate'));
                        detailsToUpdateToAssortmentDetailMap.put(item.Product__c + '' + item.Assortment__c, item.Id);
                    }
                    // CASE 1: Status__c is Validate, Client Status not null or delete :: create histo and substitute details
                    // CASE 2: Status__c is InPreparation, last history's client status not null or delete :: create substitute details
                    if (proceedInLogic) {
                        if ((item.Status__c == 'Validate' && item.ProductLifeStatusAss__c != null && item.ProductLifeStatusAss__c != 'Delist')
                            || ((item.Status__c == 'InPreparation' || item.Status__c == 'RequestForApproval') && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__c != null && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != 'Delist' && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != null))
                        {
                            // handle the history details for each product
                            if (item.Status__c == 'Validate' && item.ProductLifeStatusAss__c != null && item.ProductLifeStatusAss__c != 'Delist') { // create histo for CASE1
                                AssortmentDetail__c histoDetail = oldAssortmentDetailMap.get(item.Id).clone(false);
                                histoDetail.Status__c = 'PreviouslyValidate';
                                histoDetail.Version__c = ++lastVersion;
                                histoDetail.ExtId__c = null;
                                historyAssortmentDetailsMap.put(item.Id, histoDetail);
                                histoToAssortmentDetailMap.put(histoDetail.Product__c + '' + histoDetail.Assortment__c, item.Id);
                            }
                            // handle the substitute product
                            AssortmentDetail__c subDetail;
                            if(assortmentDetailsExistForSwitchMap.containsKey(switchKey)) {
                                // case where the new product is already in the assortment
                                item.Product__c = oldAssortmentDetailMap.get(item.Id).Product__c;
                                subDetail = item;
                                // handle the new Detail : this is the assortment detail that will be displayed in the matrix (not histo)
                                AssortmentDetail__c newProductAssortmentDetail;
                                // if the new product already exists, copy the info of the old assortment detail to the new one
                                newProductAssortmentDetail = assortmentDetailsExistForSwitchMap.get(switchKey);
                                newProductAssortmentDetail.ProductLifeStatusAss__c = item.ProductLifeStatusAss__c;
                                newProductAssortmentDetail.Status__c = item.Status__c;
                                newProductAssortmentDetail.AssortmentDetailLHistory__c = item.Id; // ERROR Validation Rules: AssortmentDetailLHistory__r.Version__c != null
                                newProductAssortmentDetail.BusinessUnitCluster__c = item.BusinessUnitCluster__c;
                                newProductAssortmentDetail.StartDate__c = item.StartDate__c;
                                if (item.Status__c == 'InPreparation' && assortmentDetailWithLastHistoInfo != null && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != 'Delist' && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != null) {
                                    newProductAssortmentDetail.ProductLifeStatusAss__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c;
                                    newProductAssortmentDetail.Status__c = 'Validate';
                                    newProductAssortmentDetail.BusinessUnitCluster__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.BusinessUnitCluster__c;
                                    newProductAssortmentDetail.IsNewProduct__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.IsNewProduct__c;
                                    // sub detail
                                    subDetail.BusinessUnitCluster__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.BusinessUnitCluster__c;
                                    subDetail.IsNewProduct__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.IsNewProduct__c;
                                }
                                newProductAssortmentDetail.StartDate__c = mvntDate;
                                assortmentDetailsToUpdateList.add(newProductAssortmentDetail);
                                detailsToUpdateToAssortmentDetailMap.put(newProductAssortmentDetail.Product__c + '' + newProductAssortmentDetail.Assortment__c, item.Id);
                            } else { // normal case: the new product isn't already in the assortment
                                subDetail = oldAssortmentDetailMap.get(item.Id).clone(false);
                                substituteToAssortmentDetailMap.put(subDetail.Product__c + '' + subDetail.Assortment__c, item.Id);
                                if ((item.Status__c == 'InPreparation' || item.Status__c == 'RequestForApproval') && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__c != null && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != 'Delist' && assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c != null) {
                                    item.ProductLifeStatusAss__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.ProductLifeStatusAss__c;
                                    item.BusinessUnitCluster__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.BusinessUnitCluster__c;
                                    item.IsNewProduct__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.IsNewProduct__c;
                                    item.Status__c = 'Validate';
                                    // sub detail
                                    subDetail.BusinessUnitCluster__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.BusinessUnitCluster__c;
                                    subDetail.IsNewProduct__c = assortmentDetailWithLastHistoInfo.AssortmentDetailLHistory__r.IsNewProduct__c;
                                } else {
                                    subDetail.BusinessUnitCluster__c = item.BusinessUnitCluster__c;
                                    subDetail.IsNewProduct__c = item.IsNewProduct__c;
                                }
                            }
                            subDetail.ProductLifeStatusAss__c = 'Substitute';
                            subDetail.Status__c = 'PreviouslyValidate';
                            subDetail.StartDate__c = mvntDate;
                            subDetail.Version__c = ++lastVersion;
                            subDetail.ExtId__c = null;
                            subDetail.AssortmentDetailLHistory__c = item.AssortmentDetailLHistory__c;
                            substituteAssortmentDetailsMap.put(item.Id, subDetail);
                        }
                    }
                }
            }

            try {
                String[] assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Status__c.Name,
                    SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Version__c.Name,
                    SObjectType.AssortmentDetail__c.fields.ExtId__c.Name,
                    SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name,
                    SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                    SObjectType.AssortmentDetail__c.fields.IsNewProduct__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Product__c.Name
                };
                // insert history Assortment Details if exist
                if (!historyAssortmentDetailsMap.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                        List<AssortmentDetail__c> detailsList = historyAssortmentDetailsMap.values();
                        List<Database.SaveResult> insertResults = Database.insert(detailsList, true);
                        String errorMessage;
                        for (Integer i = 0; i < insertResults.size(); i++) {
                            Database.SaveResult result = insertResults.get(i);
                            if (!result.isSuccess()) {
                                AssortmentDetail__c detail = detailsList.get(i);
                                errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage() + '\n';
                                }
                                Id assortmentId = histoToAssortmentDetailMap.get(detail.Product__c + '' + detail.Assortment__c);
                                if (switchedAssortmentDetailsMap.containsKey(assortmentId)) {
                                    switchedAssortmentDetailsMap.get(assortmentId).addError(errorMessage);
                                }
                            }
                        }
                        // assign last histo to substitues
                        for (Id detailId : historyAssortmentDetailsMap.keySet()) {
                            Id histoId = historyAssortmentDetailsMap.get(detailId).Id;
                            if (substituteAssortmentDetailsMap.containsKey(detailId)) {
                                substituteAssortmentDetailsMap.get(detailId).AssortmentDetailLHistory__c = histoId;
                            }
                        }
                    }
                }
                // insert substitute Assortment Details if exist
                if (!substituteAssortmentDetailsMap.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                        List<AssortmentDetail__c> detailsList = new List<AssortmentDetail__c>();
                        for (AssortmentDetail__c subDetail : substituteAssortmentDetailsMap.values()) {
                            if (subDetail.Id == null) {
                                detailsList.add(subDetail);
                            }
                        }
                        List<Database.SaveResult> insertResults = Database.insert(detailsList, true);
                        String errorMessage;
                        for (Integer i = 0; i < insertResults.size(); i++) {
                            Database.SaveResult result = insertResults.get(i);
                            if (!result.isSuccess()) {
                                AssortmentDetail__c detail = detailsList.get(i);
                                errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage() + '\n';
                                }
                                Id assortmentId = substituteToAssortmentDetailMap.get(detail.Product__c + '' + detail.Assortment__c);
                                if (switchedAssortmentDetailsMap.containsKey(assortmentId)) {
                                    switchedAssortmentDetailsMap.get(assortmentId).addError(errorMessage);
                                }
                            }
                        }
                        // assign last histo to the original details
                        for (Id detailId : substituteAssortmentDetailsMap.keySet()) {
                            Id histoId = substituteAssortmentDetailsMap.get(detailId).Id;
                            if (switchedAssortmentDetailsMap.containsKey(detailId) && switchedAssortmentDetailsMap.get(detailId).Id != histoId) {
                                switchedAssortmentDetailsMap.get(detailId).AssortmentDetailLHistory__c = histoId;
                            }
                        }
                    }
                }
                // update details
                if (!assortmentDetailsToUpdateList.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                        List<Database.SaveResult> updateResults = Database.update(assortmentDetailsToUpdateList, true);
                        String errorMessage;
                        for (Integer i = 0; i < updateResults.size(); i++) {
                            Database.SaveResult result = updateResults.get(i);
                            if (!result.isSuccess()) {
                                AssortmentDetail__c detail = assortmentDetailsToUpdateList.get(i);
                                errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage() + '\n';
                                }
                                Id assortmentId = detailsToUpdateToAssortmentDetailMap.get(detail.Product__c + '' + detail.Assortment__c);
                                if (switchedAssortmentDetailsMap.containsKey(assortmentId)) {
                                    switchedAssortmentDetailsMap.get(assortmentId).addError(errorMessage);
                                }
                            }
                        }
                    }
                }
                // delete details
                if (!assortmentDetailsToDeleteList.isEmpty()) {
                    if (NegoptimHelper.checkDeletibility(AssortmentDetail__c.SObjectType)) {
                        List<Database.DeleteResult> deleteResults = Database.delete(assortmentDetailsToDeleteList, true);
                        String errorMessage;
                        for (Integer i = 0; i < deleteResults.size(); i++) {
                            Database.DeleteResult result = deleteResults.get(i);
                            if (!result.isSuccess()) {
                                AssortmentDetail__c detail = assortmentDetailsToDeleteList.get(i);
                                errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage() + '\n';
                                }
                                Id assortmentId = detailsToDeleteToAssortmentDetailMap.get(detail.Product__c + '' + detail.Assortment__c);
                                if (switchedAssortmentDetailsMap.containsKey(assortmentId)) {
                                    switchedAssortmentDetailsMap.get(assortmentId).addError(errorMessage);
                                }
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                System.debug('exception >> ' + ex.getMessage() + ' - - ' + ex.getLineNumber());
                System.debug('exception >> ' + ex.getStackTraceString());
            }
        }
    }
 	/**
     * @description validates if the assortment detail category is a sub-cateogry of the assortment bu's category
     * @param newAssortmentDetails a list of new assortment details to insert
     * @param oldAssortmentDetailMap a map of the old assortment details values (case update)
     * on Before Insert or Update
	*/
    private static void validateCategory(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            Set<Id> categoriesIdSet = new Set<Id>();
            List<AssortmentDetail__c> newAssortmentDetails = new List<AssortmentDetail__c>();
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                String assortmentRecordType = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ?
                    assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName : '';
                if (assortmentRecordType == 'Budget') {
                    continue;
                }
                if (item.Hierarchy__c != null
                    && (item.Id == null // case insert and category filled already
                        || (oldAssortmentDetailMap.containsKey(item.Id) && item.Hierarchy__c != oldAssortmentDetailMap.get(item.Id).Hierarchy__c))) // case update and category has changed
                {
                    categoriesIdSet.add(item.Hierarchy__c);
                    newAssortmentDetails.add(item);
                }
            }
            if (!newAssortmentDetails.isEmpty()) {
                // check security on access Hierarchy__c fields
                String[] orgaHEFields = new String[] {
                    SObjectType.Hierarchy__c.fields.Id.Name,
                    SObjectType.Hierarchy__c.fields.Path__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields)) {
                    Map<Id, Hierarchy__c> categoriesMap = new Map<Id, Hierarchy__c>([SELECT Path__c FROM Hierarchy__c WHERE Id IN :categoriesIdSet]);
                    for (AssortmentDetail__c item : newAssortmentDetails) {
                        if (assortmentWrapper.assortmentBUMap != null && assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) && item.Hierarchy__c != null
                            && categoriesMap.get(item.Hierarchy__c).Path__c != null
                            && assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Hierarchy__c != null
                            && !categoriesMap.get(item.Hierarchy__c).Path__c.contains('|' + assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Hierarchy__r.Code__c + '|')
                            && !categoriesMap.get(item.Hierarchy__c).Path__c.contains(assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Hierarchy__r.Code__c + '|')
                            && !categoriesMap.get(item.Hierarchy__c).Path__c.contains('|' + assortmentWrapper.assortmentBUMap.get(item.Assortment__c).Hierarchy__r.Code__c))
                        {
                            // TODO: add label
                            item.addError('Assortment Detail Category is not a sub-category of the Assortment Category.');
                        }
                    }
                }
            }
        }
    }
	
    /**
     * @description check duplicate details records
     * duplication criteria: Assortment__c, Product__c, Version__c
     * On Before Insert or Update
     * */
    private static void checkDuplicate(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        Set<Id> productsIdset = new Set<Id>();
        Set<Id> assortmentsIdSet = new Set<Id>();
        Map<String, AssortmentDetail__c> productAssortmentDetailMap = new Map<String, AssortmentDetail__c>();
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            if ((item.Id == null ||
                 (oldAssortmentDetailsMap.containsKey(item.Id) && (item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c
                                                                   || item.Version__c != oldAssortmentDetailsMap.get(item.Id).Version__c)))
                && item.Version__c == null)
            {
                String key = item.Assortment__c + '' + item.Product__c;
                if (!productAssortmentDetailMap.containsKey(key)) {
                    productAssortmentDetailMap.put(key, item);
                    assortmentsIdSet.add(item.Assortment__c);
                    productsIdset.add(item.Product__c);
                } else {
                    item.adderror(Label.MSG_Product_already_exist_in_List);
                }
            }
        }
        if (!productsIdset.isEmpty()) {
            // check security on access AssortmentDetail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                SObjectType.AssortmentDetail__c.fields.Version__c.Name
            };
            // check security on access Product2 fields
            String[] productFields = new String[] {
                SObjectType.Product2.fields.Name.Name
            };
            if(NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields) &&
               NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields))
            {
                // put in Map<Id Assortment + Id product>
                for (AssortmentDetail__c item : [SELECT Assortment__c, Product__c, Product__r.Name
                                                  FROM AssortmentDetail__c
                                                  WHERE Product__c IN :productsIdset
                                                  AND Assortment__c IN :assortmentsIdSet
                                                  AND Version__c = NULL])
                {
                    String key = item.Assortment__c + '' + item.Product__c;
                    if (productAssortmentDetailMap.containsKey(key)) {
                        productAssortmentDetailMap.get(key).adderror(item.Product__r.Name + ': ' + Label.MSG_Product_already_exist_in_assortment);
                    }
                }
            }
        }
    }
 	
    /**
     * @description: Fill Hierarchy__c from product category on insert if NULL or on update if product changed
     * generates and fill ExtId__c on insert or on update if product changed
     * populate AVG
     * calculate Contract_Nego_Disc_(i)_Corr__c fields
     * On Before Insert or Update
     * */
    private static void populateFields(AssortmentWrapper assortmentWrapper, List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        Map<Id, List<AssortmentDetail__c>> productAssortmentDetailMap = new Map<Id, List<AssortmentDetail__c>>();
        for (AssortmentDetail__c item : newAssortmentDetails) {
            if(assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                if (/*item.Id != null // in case update, always update ExtId__c*/
                    String.isBlank(item.ExtId__c) // in case insert and ExtId__c is empty, populate ExtId__c
                    || item.Hierarchy__c == null // always populate Hierarchy__c if empty
                    || (item.Id != null && item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c) // update category and AVG if product changed
                    || (item.Id == null && (item.AvgWeeklySalesClient__c == null || item.AvgWeeklySalesChannel__c == null || item.ProductRanking__c == null || item.ProductPriority__c == null))) // update AVG on insert ASD
                {
                    if(!productAssortmentDetailMap.containsKey(item.Product__c))
                        productAssortmentDetailMap.put(item.Product__c, new List<AssortmentDetail__c>());
                    productAssortmentDetailMap.get(item.Product__c).add(item);
                }
                if ((item.Id == null && item.SalesCannibalizationType__c != null && item.SalesCannibalizationRate__c == null)
                    || (oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.containsKey(item.Id) 
                        && item.SalesCannibalizationType__c != oldAssortmentDetailsMap.get(item.Id).SalesCannibalizationType__c
                        && item.SalesCannibalizationRate__c == oldAssortmentDetailsMap.get(item.Id).SalesCannibalizationRate__c)) // update Correction rate on insert / update ASD
                {
                    if (item.SalesCannibalizationType__c != null && assortmentWrapper.hypothesisReportMap.containsKey(item.SalesCannibalizationType__c + '' + item.Assortment__c)) {
                        item.SalesCannibalizationRate__c = assortmentWrapper.hypothesisReportMap.get(item.SalesCannibalizationType__c + '' + item.Assortment__c);
                    } else {
                        item.SalesCannibalizationRate__c = null;
                    }
                }
            }
        }
        if (!productAssortmentDetailMap.isEmpty()) {
            // check security on Product2 fields
            String[] productFields = new String[] {
                SObjectType.Product2.fields.Id.Name,
                    SObjectType.Product2.fields.Ext_id__c.Name,
                    SObjectType.Product2.fields.Hierarchy__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Hyper__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Super__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_CashAndCarry__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Drive__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Hard__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Web__c.Name,
                    SObjectType.Product2.fields.Average_Weekly_Sales_Convenience__c.Name,
                    SObjectType.Product2.fields.RankingHyper__c.Name,
                    SObjectType.Product2.fields.RankingSuper__c.Name,
                    SObjectType.Product2.fields.RankingCash__c.Name,
                    SObjectType.Product2.fields.RankingDrive__c.Name,
                    SObjectType.Product2.fields.RankingHard__c.Name,
                    SObjectType.Product2.fields.RankingWeb__c.Name,
                    SObjectType.Product2.fields.RankingConvenience__c.Name,
                    SObjectType.Product2.fields.PriorityHM__c.Name,
                    SObjectType.Product2.fields.Priority_SM__c.Name,
                    SObjectType.Product2.fields.PriorityCashCarry__c.Name,
                    SObjectType.Product2.fields.PriorityDrive__c.Name,
                    SObjectType.Product2.fields.PriorityHard__c.Name,
                    SObjectType.Product2.fields.PriorityWeb__c.Name,
                    SObjectType.Product2.fields.PriorityConv__c.Name,
                    SObjectType.Product2.fields.UV__c.Name,
                    SObjectType.Product2.fields.Weight__c.Name
            };
            if(NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields)) {
                for (Product2 product : [SELECT Id, Ext_id__c, Hierarchy__c, Average_Weekly_Sales_Hyper__c,
                                         Average_Weekly_Sales_Super__c, Average_Weekly_Sales_CashAndCarry__c, Average_Weekly_Sales_Drive__c,
                                         Average_Weekly_Sales_Hard__c, Average_Weekly_Sales_Web__c, Average_Weekly_Sales_Convenience__c,
                                         RankingHyper__c, RankingSuper__c, RankingCash__c, RankingDrive__c,
                                         RankingHard__c, RankingWeb__c, RankingConvenience__c,
                                         toLabel(PriorityHM__c), toLabel(Priority_SM__c), toLabel(PriorityCashCarry__c), toLabel(PriorityDrive__c),
                                         toLabel(PriorityHard__c), toLabel(PriorityWeb__c), toLabel(PriorityConv__c)
                                         FROM Product2 WHERE Id IN : productAssortmentDetailMap.keySet()])
                {
                    Assortment__c assortmentBUForExtId = null;
                    for (AssortmentDetail__c item : productAssortmentDetailMap.get(product.Id)) {
                        Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                        // populate category
                        if (item.Hierarchy__c == null || (item.Id != null && oldAssortmentDetailsMap != null && item.Product__c != oldAssortmentDetailsMap.get(item.Id).Product__c)) {
                            item.Hierarchy__c = product.Hierarchy__c;
                        }
                        // populate external id
                        // if (item.Id != null || (item.Id == null && String.isBlank(item.ExtId__c))) {
                        //     String version = item.Version__c != null ? String.valueOf((Integer) item.Version__c) : '';
                        //     assortmentBUForExtId = assortmentWrapper.allAssortmentBUMap.get(item.Assortment__c);
                        //     item.ExtId__c = assortmentBUForExtId.ExtId__c  + '-' + (product.Ext_Id__c == null ? String.valueOf(product.Id) : product.Ext_Id__c)  + '-V' + version;
                        //     system.debug('item.ExtId__c >>> ' + item.ExtId__c);
                        // }
                        if (item.Id != null || (item.Id == null && String.isBlank(item.ExtId__c))) {
                            String version = item.Version__c != null ? String.valueOf((Integer) item.Version__c) : '0';
                            assortmentBUForExtId = assortmentWrapper.allAssortmentBUMap.get(item.Assortment__c);
                            String baseExtId = assortmentBUForExtId.ExtId__c != null ? assortmentBUForExtId.ExtId__c : String.valueOf(assortmentBUForExtId.Id);
                            item.ExtId__c = baseExtId + '-' + (product.Ext_Id__c == null ? String.valueOf(product.Id) : product.Ext_Id__c) + '-V' + version;
                            system.debug('item.ExtId__c >>> ' + item.ExtId__c);
                        }
                        // populate AVG
                        if(item.Id == null) {
                            Decimal vmh;
                            switch on assortmentBU.BusinessUnitTarget__r.Format__c?.split(';')[0] {
                                when 'Hypermarket' {
                                    vmh = product.Average_Weekly_Sales_Hyper__c;
                                    item.ProductRanking__c = (product.RankingHyper__c != null ? product.RankingHyper__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityHM__c;
                                }	
                                when 'Supermarket' {
                                    vmh = product.Average_Weekly_Sales_Super__c;
                                    item.ProductRanking__c = (product.RankingSuper__c != null ? product.RankingSuper__c : 0) + '';
                                    item.ProductPriority__c = product.Priority_SM__c;
                                }
                                when 'HMSM' {
                                    vmh = product.Average_Weekly_Sales_Hyper__c;
                                    item.ProductRanking__c = (product.RankingHyper__c != null ? product.RankingHyper__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityHM__c + '';
                                }
                                when 'Cash&Carry' {
                                    vmh = product.Average_Weekly_Sales_CashAndCarry__c;
                                    item.ProductRanking__c = (product.RankingCash__c != null ? product.RankingCash__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityCashCarry__c;
                                }
                                when 'Drive' {
                                    vmh = product.Average_Weekly_Sales_Drive__c;
                                    item.ProductRanking__c = (product.RankingDrive__c != null ? product.RankingDrive__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityDrive__c;
                                }
                                when 'Harddiscount' {
                                    vmh = product.Average_Weekly_Sales_Hard__c;
                                    item.ProductRanking__c = (product.RankingHard__c != null ? product.RankingHard__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityHard__c + '';
                                }
                                when 'Web' {
                                    vmh = product.Average_Weekly_Sales_Web__c;
                                    item.ProductRanking__c = (product.RankingWeb__c != null ? product.RankingWeb__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityWeb__c;
                                }
                                when 'Citymarket' {
                                    vmh = product.Average_Weekly_Sales_Convenience__c;
                                    item.ProductRanking__c = (product.RankingConvenience__c != null ? product.RankingConvenience__c : 0) + '';
                                    item.ProductPriority__c = product.PriorityConv__c;
                                }
                                when else {
                                    vmh = null;
                                    item.ProductRanking__c = 0 + '';
                                    item.ProductPriority__c = null;
                                }
                            }
                            item.AvgWeeklySalesChannel__c = vmh;
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description change strat position (BusinessUnitCluster__c) based on Client_Clust(i)__c fields,
     * than it calculates and assigns the KPIs and other calculated fields using assortmentServices.assignKPI
     * On Before Insert or Update
     * @description changes the values of Client_clust(i)__c depending on the value of BusinessUnitCluster__c
     * if Client_Status__c is 'New' then change Client_Ass__c to true
     * On Before Insert
	*/
    public static void updateAssortmentStratAndClientClusters(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            List<AssortmentDetail__c> updatedAssortmentDetailsClientClusterList = new List<AssortmentDetail__c>();
            Set<Id> categoriesIdSet = new Set<Id>();
            Set<String> updatedAssortmentDetailsIds = new Set<String>();
            AssortmentServices assortServices;
            // record type id of orga bu list
            Id orgaBUListDetailAssortmentLinkRecordTypeId = NegoptimHelper.getObjectRecordTypeId(BULink__c.SObjectType, 'AssortmentBULink');
            // get last history data needed to calculate the new formula for field New_Client_Quantity_YE__c in assortmentServices
            Set<Id> lastHistoryIdSet = new Set<Id>();
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                // don't apply the logic in this method if the assortment bu of the assortment detail (item) is a of recordtype budget or conso
                String assortmentRecordType = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ?
                    assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName : '';
                if (assortmentRecordType == 'ChannelBudget' || assortmentRecordType == 'OnTopConso' || assortmentRecordType == 'TargetConso') {
                    continue;
                }
                String key = item.Assortment__c + '' + item.Product__c;
                // case insert or update AND ProductLifeStatusAss__c = 'Delist'
                if (item.ProductLifeStatusAss__c == 'Delist'
                    && (item.Id == null || (oldAssortmentDetailsMap != null && item.ProductLifeStatusAss__c != oldAssortmentDetailsMap.get(item.Id).ProductLifeStatusAss__c)))
                {
                    item.ProductCluster__c = '';
                    item.BusinessUnitCluster__c = null;
                    updatedAssortmentDetailsIds.add(key);
                }
                // case update ProductCluster__c
                if (!updatedAssortmentDetailsIds.contains(key)) {
                    Boolean isInsertAndNotSubstitute = item.Id == null && item.ProductLifeStatusAss__c != 'Substitute';
                    Boolean isStratChecked = false;
                    Map<String, List<ClusterWrapper>> productClustersMap = String.isNotBlank(item.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(item.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                    if (productClustersMap.containsKey('Strat')) {
                        for (ClusterWrapper strat : productClustersMap.get('Strat')) {
                            if (strat.value) {
                                isStratChecked = true;
                                break;
                            }
                        }
                    }
                    if ((isInsertAndNotSubstitute && isStratChecked)
                        || (item.Id != null && oldAssortmentDetailsMap != null && oldAssortmentDetailsMap.containsKey(item.Id)
                            && item.ProductCluster__c != oldAssortmentDetailsMap.get(item.Id).ProductCluster__c))
                    {
                        if (item.Hierarchy__c != null && !categoriesIdSet.contains(item.Hierarchy__c)) {
                            categoriesIdSet.add(item.Hierarchy__c);
                        }
                        if (item.AssortmentDetailLHistory__c != null) {
                            lastHistoryIdSet.add(item.AssortmentDetailLHistory__c);
                        }
                        updatedAssortmentDetailsClientClusterList.add(item);
                    }
                }
            }
            if (!updatedAssortmentDetailsClientClusterList.isEmpty()) {
                Map<Id, Hierarchy__c> categoriesMap = new Map<Id, Hierarchy__c>([SELECT Path__c FROM Hierarchy__c WHERE Id IN :categoriesIdSet]);
                Map<Id, AssortmentDetail__c> lastHistoryMap = new Map<Id, AssortmentDetail__c>();
                if(!lastHistoryIdSet.isEmpty()) {
                    lastHistoryMap = new Map<Id, AssortmentDetail__c>([SELECT Id, SOSNumberNego__c FROM AssortmentDetail__c WHERE Id IN :lastHistoryIdSet]);
                }
                for (AssortmentDetail__c item : updatedAssortmentDetailsClientClusterList) {
                    if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                        item.Assortment__r = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                        item.Hierarchy__r = categoriesMap.get(item.Hierarchy__c);
                        if (item.AssortmentDetailLHistory__c != null && lastHistoryMap.containsKey(item.AssortmentDetailLHistory__c)) {
                            item.AssortmentDetailLHistory__r = lastHistoryMap.get(item.AssortmentDetailLHistory__c);
                        }
                    }
                }
                assortServices = new AssortmentServices(updatedAssortmentDetailsClientClusterList);
                // update BusinessUnitCluster__c based on Client_ClustX__c OR Client_Clust_CpltX__c
                for (AssortmentDetail__c item : updatedAssortmentDetailsClientClusterList) {
                    if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                        Id buTargetId = assortmentWrapper.assortmentBUMap.get(item.Assortment__c).BusinessUnitTarget__c;
                        item.BusinessUnitCluster__c = null;
                        assortmentServices.ResultWrapper rw = assortServices.getResultWrapperForAssortment(buTargetId);
                        if (rw != null) {
                            Set<String> stratClientCategoryMap = assortServices.getStratClientCategoriesClusters(item);
                            Boolean clustersFound = stratClientCategoryMap.contains(item.ClientCategory__c);
                            Map<String, BusinessUnit__c> clusterStratsMap = rw.categoryClientCategoryStratMap.get(item.Hierarchy__c);
                            if ((clusterStratsMap == null || clusterStratsMap.isEmpty())) continue;
                            Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(item.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(item.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                            List<ClusterWrapper> productCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<ClusterWrapper>();
                            for(ClusterWrapper strat : productCluster) {
                                if (strat.value) {
                                    if (clustersFound && clusterStratsMap.containsKey(strat.index + '' + item.ClientCategory__c)) {
                                        item.BusinessUnitCluster__c = clusterStratsMap.get(strat.index + '' + item.ClientCategory__c)?.Id;
                                        break;
                                    } else if (!clustersFound && clusterStratsMap.containsKey(strat.index + 'null')) {
                                        item.BusinessUnitCluster__c = clusterStratsMap.get(strat.index + 'null')?.Id;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     * @description manage Client_Status__c when client_Clusti__c/ BusinessUnitCluster__c changes
     * if the new number of selected clusters is greater than the old number of selected clusters, then change client status to increase
     * if the new number of selected clusters is smaller than the old number of selected clusters, then change client status to decrease
     * if the new number of selected clusters is 0, then change client status to delete
     * in the case of force update, if the new number of selected clusters is equal to the old number of selected clusters, then change client status to old client status
     *
	*/
    public static void updateAssortmentClientStatus(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            Map<Id, AssortmentDetail__c> changedAssortmentDetailsMap = new Map<Id, AssortmentDetail__c>();
            // Client_Status__c values to exclude from change
            List<String> clientStatusToExclude = new List<String> {'Opportunity', 'Delist', 'Probably deleted'};
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                String assortmentRecordType = assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c) ?
                assortmentWrapper.assortmentBUMap.get(item.Assortment__c).RecordType.DeveloperName : '';
                if (assortmentRecordType == 'ChannelBudget' || assortmentRecordType == 'OnTopConso' || assortmentRecordType == 'TargetConso') {
                    continue;
                }
                if (item.Id != null
                    && oldAssortmentDetailsMap != null
                    && oldAssortmentDetailsMap.containsKey(item.Id)
                    && item.Status__c != 'PreviouslyValidate'
                    && (item.ProductCluster__c != oldAssortmentDetailsMap.get(item.Id).ProductCluster__c
                        || item.ProductClusterASDNego__c != oldAssortmentDetailsMap.get(item.Id).ProductClusterASDNego__c
                        || item.BusinessUnitCluster_P1__c != oldAssortmentDetailsMap.get(item.Id).BusinessUnitCluster_P1__c
                        || item.BusinessUnitCluster__c != oldAssortmentDetailsMap.get(item.Id).BusinessUnitCluster__c))
                {
                    changedAssortmentDetailsMap.put(item.Id, item);
                }
            }
            if(!changedAssortmentDetailsMap.isEmpty()) {
                // check security on AssortmentDetail__c fields
                String[] assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name,
                    SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
                    SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                    SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name
                };
                String lastHistoryQuery = 'SELECT ProductCluster__c,';
                lastHistoryQuery += ' AssortmentDetailLHistory__r.ProductCluster__c, AssortmentDetailNegotiationRef__r.ProductCluster__c,';
                lastHistoryQuery += ' AssortmentDetailLHistory__r.BusinessUnitCluster__c, AssortmentDetailNegotiationRef__r.BusinessUnitCluster__c,';
                lastHistoryQuery += ' AssortmentDetailLHistory__r.ProductLifeStatusAss__c, AssortmentDetailNegotiationRef__r.ProductLifeStatusAss__c';
                lastHistoryQuery += ' FROM AssortmentDetail__c';
                lastHistoryQuery += ' WHERE Id IN (\'' + String.join(new List<Id> (changedAssortmentDetailsMap.KeySet()), '\',\'') + '\')';
                if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                    Map<Id, AssortmentDetail__c> assortmentDetailsMap = new Map<Id, AssortmentDetail__c>((List<AssortmentDetail__c>) Database.query(lastHistoryQuery));
                    for (Id key : changedAssortmentDetailsMap.keySet()) {
                        AssortmentDetail__c oldAssortmentDetail = assortmentDetailsMap.get(key);
                        AssortmentDetail__c lastHistory = String.isNotBlank(oldAssortmentDetail.AssortmentDetailLHistory__c) ? oldAssortmentDetail.AssortmentDetailLHistory__r : oldAssortmentDetail.AssortmentDetailNegotiationRef__r;
                        String currentClientStatus = changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c;
                        String lastValidClientStatus;
                        Integer lastValidStratCount = 0;
                        Integer currentStratCount = 0;
                        Integer currentCpltCount = 0;
                        Map<String, List<ClusterWrapper>> productClusterOldMap = oldAssortmentDetailsMap != null &&  oldAssortmentDetailsMap.containsKey(key) ? String.isNotBlank(oldAssortmentDetailsMap.get(key).ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(oldAssortmentDetailsMap.get(key).ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>() : new Map<String, List<ClusterWrapper>>();
                        List<ClusterWrapper> productClusterStratOld = productClusterOldMap.containsKey('Strat') ? productClusterOldMap.get('Strat') : new List<ClusterWrapper>();
                        Map<Integer, Boolean> productClusterStratOMap = new Map<Integer, Boolean>();
                        for (ClusterWrapper strat : productClusterStratOld) {
                            productClusterStratOMap.put(strat.index, strat.value);
                        }
                        Map<String, List<ClusterWrapper>> productClusterHistoryMap = String.isNotBlank(lastHistory?.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(lastHistory?.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                        List<ClusterWrapper> productClusterStratHistroy = productClusterHistoryMap.containsKey('Strat') ? productClusterHistoryMap.get('Strat') : new List<ClusterWrapper>();
                        Map<Integer, Boolean> productClusterStratHistoMap = new Map<Integer, Boolean>();
                        for (ClusterWrapper strat : productClusterStratHistroy) {
                            productClusterStratHistoMap.put(strat.index, strat.value);
                        }
                        Map<String, List<ClusterWrapper>> productClusterChangedMap = String.isNotBlank(changedAssortmentDetailsMap.get(key).ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(changedAssortmentDetailsMap.get(key).ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                        List<ClusterWrapper> productClusterStratChanged = productClusterChangedMap.containsKey('Strat') ? productClusterChangedMap.get('Strat') : new List<ClusterWrapper>();
                        for (ClusterWrapper strat : productClusterStratChanged) {
                            Boolean isCurrentStratIndexWasLastChecked = (Boolean) productClusterStratOMap.containsKey(strat.index) ? productClusterStratOMap.get(strat.index) : false;
                            Boolean isCurrentStratIndexCheckedForHistory = lastHistory != null && (Boolean) productClusterStratHistoMap.containsKey(strat.index) ? productClusterStratHistoMap.get(strat.index) : false;
                            // last valid strat count
                            if (oldAssortmentDetailsMap.get(key).Status__c == 'Validate') {
                                if (isCurrentStratIndexWasLastChecked) {
                                    lastValidStratCount++;
                                }
                            } else if (isCurrentStratIndexCheckedForHistory) {
                                lastValidStratCount++;
                            }
                            // current start count
                            if (strat.value) {
                                currentStratCount++;
                            }
                        }
                        List<ClusterWrapper> productClusterCpltChanged = productClusterChangedMap.containsKey('Cplt') ? productClusterChangedMap.get('Cplt') : new List<ClusterWrapper>();
                        for (ClusterWrapper cplt : productClusterCpltChanged) {
                             // current cplt count
                             if (cplt.value) {
                                currentCpltCount++;
                            }
                        }
                        if (oldAssortmentDetailsMap.get(key).Status__c == 'Validate') {
                            lastValidClientStatus = oldAssortmentDetailsMap.get(key).ProductLifeStatusAss__c;
                        } else if (lastHistory != null) {
                            lastValidClientStatus = lastHistory.ProductLifeStatusAss__c;
                        }
                        // if assortment detail status was delete, the only available client status is New
                        if ((/*oldAssortmentDetailsMap.get(key).ProductLifeStatusAss__c == 'Delist' || */lastValidClientStatus == 'Delist') && currentStratCount > 0) {
                            changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'New';
                        } else if (lastValidClientStatus == null) {
                            if (currentStratCount == 0) {
                                if (currentCpltCount > 0) {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Complement';
                                } else {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = '';
                                }
                                changedAssortmentDetailsMap.get(key).IsNewProduct__c = false;
                            } else if ((String.isBlank(oldAssortmentDetailsMap.get(key).ProductLifeStatusAss__c)
                                        || oldAssortmentDetailsMap.get(key).ProductLifeStatusAss__c == 'Complement')
                                       && (String.isBlank(currentClientStatus) || currentClientStatus == 'Complement'))
                            {
                                changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'New';
                                changedAssortmentDetailsMap.get(key).IsNewProduct__c = true;
                            }
                        } else {
                            changedAssortmentDetailsMap.get(key).IsNewProduct__c = false;
                            if (currentStratCount == 0) {
                                if (currentCpltCount > 0) {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Complement';
                                } else {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Delist';
                                }
                            } else if (!clientStatusToExclude.contains(currentClientStatus) && !clientStatusToExclude.contains(lastValidClientStatus)) {
                                if (currentStratCount > lastValidStratCount) {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Increase';
                                } else if (currentStratCount < lastValidStratCount) {
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Decrease';
                                } else {
                                    Boolean isNegoN1 = String.isBlank(oldAssortmentDetail.AssortmentDetailLHistory__c) && String.isNotBlank(oldAssortmentDetail.AssortmentDetailNegotiationRef__c);
                                    changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = isNegoN1 ? 'Keep' : lastValidClientStatus;
                                }
                            } else if (currentClientStatus != 'Opportunity') {
                                Boolean hasHistory = String.isNotBlank(oldAssortmentDetail.AssortmentDetailLHistory__c) || String.isNotBlank(oldAssortmentDetail.AssortmentDetailNegotiationRef__c);
                                if (!hasHistory) {
                                changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'New';
                                } else {
                                    if (currentStratCount > lastValidStratCount) {
                                        changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Increase';
                                    } else if (currentStratCount < lastValidStratCount) {
                                        changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = 'Decrease';
                                    } else {
                                        Boolean isNegoN1 = String.isBlank(oldAssortmentDetail.AssortmentDetailLHistory__c) && String.isNotBlank(oldAssortmentDetail.AssortmentDetailNegotiationRef__c);
                                        changedAssortmentDetailsMap.get(key).ProductLifeStatusAss__c = isNegoN1 ? 'Keep' : lastValidClientStatus;
                                    }
                                }
                            } 
                        }
                    }
                }
            }
        }
    }
     
 	
    /**
     * @description set RecordDate__c to now
     * when there is a change in BusinessUnitCluster__c and Status__c != 'Validate' or a change in AssortmentDetailLHistory__c and Status__c == 'Validate' on AssortmentDetail__c
     * On Before Insert or Update
	*/
    private static void updateRecordDate(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        for (AssortmentDetail__c item : newAssortmentDetails) {
            AssortmentDetail__c oldAssortmentDetail = oldAssortmentDetailsMap != null ? (oldAssortmentDetailsMap.containsKey(item.Id) ? oldAssortmentDetailsMap.get(item.Id) : null) : null;
            Id oldAssBUCluster = oldAssortmentDetail != null ? oldAssortmentDetail.BusinessUnitCluster__c : null;
            Id oldLastHistory = oldAssortmentDetail != null ? oldAssortmentDetail.AssortmentDetailLHistory__c : null;
            if ((item.Status__c != 'Validate' && oldAssBUCluster != item.BusinessUnitCluster__c) || (item.Status__c == 'Validate' && oldLastHistory != item.AssortmentDetailLHistory__c)) {
                item.RecordDate__c = Date.today();
            }
        }
    }
    
    /**
     * @description recalculate KPIs by utilizing assortmentServices class
     * the method checks for changes in client clusters, cplt clusters, client status, movement date, Avg sales OR IF Force_Update__c is TRUE
     * the method queries and assigns required lookup fields necessary for calculations such as Assortment__r fields and Last_History__r fields
	*/
    public static void recalculateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            // loop on assortment details and construct a list of modified details that must be recalculated
            // create sets of category Ids, assortment Ids and last history ids to query data and create maps
            List<AssortmentDetail__c> modifiedAssortmentDetails = new List<AssortmentDetail__c>();
            Set<Id> categoriesIdSet = new Set<Id>();
            Set<Id> lastHistoryIdSet = new Set<Id>();
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                Boolean isCpltChecked = false;
                Map<String, List<ClusterWrapper>> productClusterMap = String.isNotBlank(item.ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(item.ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                List<ClusterWrapper> productClusterCplt = productClusterMap.containsKey('Cplt') ? productClusterMap.get('Cplt') : new List<ClusterWrapper>();
                for (ClusterWrapper cplt : productClusterCplt) {
                    if (cplt.value) {
                        isCpltChecked = true;
                        break;
                    }
                }
                if ((item.Id == null && (item.BusinessUnitCluster__c != null || isCpltChecked)) // new record
                    || (item.Id != null // updated record
                        && (//item.Force_Update__c||
                            item.StartDate__c != oldAssortmentDetailsMap.get(item.Id).StartDate__c
                            || item.BusinessUnitCluster__c != oldAssortmentDetailsMap.get(item.Id).BusinessUnitCluster__c // BusinessUnitCluster__c has changed means that client cluster has changed
                            || item.ProductLifeStatusAss__c != oldAssortmentDetailsMap.get(item.Id).ProductLifeStatusAss__c
                            || item.AvgWeeklySalesClient__c != oldAssortmentDetailsMap.get(item.Id).AvgWeeklySalesClient__c
                            || item.AvgWeeklySalesChannel__c != oldAssortmentDetailsMap.get(item.Id).AvgWeeklySalesChannel__c
                            || item.Status__c != oldAssortmentDetailsMap.get(item.Id).Status__c)))
                {
                    modifiedAssortmentDetails.add(item);
                    if (item.Hierarchy__c != null) {
                        categoriesIdSet.add(item.Hierarchy__c);
                    }
                    if (item.AssortmentDetailLHistory__c != null) {
                        lastHistoryIdSet.add(item.AssortmentDetailLHistory__c);
                    }
                } else if (item.Id != null) { // if nothing has changed, we must check if cplt clusters changed because modification in cplts doesn't always effect Ass_BU_Cluster__c
                    Map<Integer, Boolean> clustersCpltMap = new Map<Integer, Boolean>();
                    for (ClusterWrapper cplt : productClusterCplt) {
                        clustersCpltMap.put(cplt.index, cplt.value);
                    }
                    Map<String, List<ClusterWrapper>> productClusterOldMap = String.isNotBlank(oldAssortmentDetailsMap.get(item.Id).ProductCluster__c) ? (Map<String, List<ClusterWrapper>>) JSON.deserialize(oldAssortmentDetailsMap.get(item.Id).ProductCluster__c, Map<String, List<ClusterWrapper>>.class) : new Map<String, List<ClusterWrapper>>();
                    List<ClusterWrapper> productClusterOldCplt = productClusterOldMap.containsKey('Cplt') ? productClusterOldMap.get('Cplt') : new List<ClusterWrapper>();
                    Map<Integer, Boolean> clustersCpltOldMap = new Map<Integer, Boolean>();
                    for (ClusterWrapper cplt : productClusterOldCplt) {
                        clustersCpltOldMap.put(cplt.index, cplt.value);
                    }
                    for (ClusterWrapper cplt : productClusterCplt) {
                        // check if field exist and field has changed
                        if (clustersCpltMap.get(cplt.index) != clustersCpltOldMap.get(cplt.index)) {
                            modifiedAssortmentDetails.add(item);
                            if (item.Hierarchy__c != null) {
                                categoriesIdSet.add(item.Hierarchy__c);
                            }
                            if (item.AssortmentDetailLHistory__c != null) {
                                lastHistoryIdSet.add(item.AssortmentDetailLHistory__c);
                            }
                            break; // it is enough that 1 cplt cluster has changed to recalcualtion
                        }
                    }
                }
            }
            if(!modifiedAssortmentDetails.isEmpty()) {
                // query the assortment details' categories, assortments and last history data
                Map<Id, Hierarchy__c> categoriesMap = new Map<Id, Hierarchy__c>();
                if(!categoriesIdSet.isEmpty()) {
                    categoriesMap = new Map<Id, Hierarchy__c> ([SELECT Path__c FROM Hierarchy__c WHERE Id IN :categoriesIdSet]);
                }
                Map<Id, AssortmentDetail__c> lastHistoryMap = new Map<Id, AssortmentDetail__c>();
                if(!lastHistoryIdSet.isEmpty()) {
                    lastHistoryMap = new Map<Id, AssortmentDetail__c> ([SELECT SOSNumberNego__c FROM AssortmentDetail__c WHERE Id IN :lastHistoryIdSet]);
                }
                for (AssortmentDetail__c item : modifiedAssortmentDetails) {
                    if (assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                        item.Assortment__r = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                    }
                    if (categoriesMap.containsKey(item.Hierarchy__c)) {
                        item.Hierarchy__r = categoriesMap.get(item.Hierarchy__c);
                    }
                    if (lastHistoryMap.containsKey(item.AssortmentDetailLHistory__c)) {
                        item.AssortmentDetailLHistory__r = lastHistoryMap.get(item.AssortmentDetailLHistory__c);
                    }
                }
                // Create an instance of assortmentServices
                AssortmentServices assortServices = new AssortmentServices(modifiedAssortmentDetails);
                
                // recalculate fields
                assortServices.assignKPI(modifiedAssortmentDetails);
            }
        }
    }
    

    private static void consolidateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap, Boolean afterDelete) {
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            List<AssortmentDetail__c> assortmentDetails = new List<AssortmentDetail__c>();
            Set<Id> countryOriginSet = new Set<Id>();
            Set<Id> buSourceSet = new Set<Id>();
            Set<Id> categorySet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            if(!afterDelete) {
                for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                    Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                    String recordType = assortmentBU.RecordType.DeveloperName;
                    if ((recordType == 'Negotiation' || recordType == 'Target' || recordType == 'Simulation') &&
                        ((item.Version__c == null && (item.Status__c == 'Validate' || item.Status__c == 'RequestForApproval' )) ||
                         (item.Status__c == 'PreviouslyValidate' && item.ProductLifeStatusAss__c == 'Substitute')) &&
                        (oldAssortmentDetailsMap == null || (oldAssortmentDetailsMap.get(item.Id) != null && item.Status__c != oldAssortmentDetailsMap.get(item.Id).Status__c)))
                    {
                        assortmentDetails.add(item);
                    }
                }
            } else {
                assortmentDetails.addAll(oldAssortmentDetailsMap.values());
            }
            if (!assortmentDetails.isEmpty()) {
                for (AssortmentDetail__c item : assortmentDetails) {
                    if(assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                        Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                        if(assortmentBU.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c != null && !countryOriginSet.contains(assortmentBU.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c)) {
                            countryOriginSet.add(assortmentBU.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c);
                        }
                        if(assortmentBU.BusinessUnitSource__c != null && !buSourceSet.contains(assortmentBU.BusinessUnitSource__c)) {
                            buSourceSet.add(assortmentBU.BusinessUnitSource__c);
                        }
                        if(assortmentBU.Hierarchy__c != null && !categorySet.contains(assortmentBU.Hierarchy__c)) {
                            categorySet.add(assortmentBU.Hierarchy__c);
                        }
                        if(item.Product__c != null && !productSet.contains(item.Product__c)) {
                            productSet.add(item.Product__c);
                        }
                        if(assortmentBU.Year__c != null && !yearSet.contains(Integer.valueOf(assortmentBU.Year__c))) {
                            yearSet.add(Integer.valueOf(assortmentBU.Year__c));
                        }
                    }
                }
                if(!System.isBatch() && !countryOriginSet.isEmpty() && !buSourceSet.isEmpty() && !categorySet.isEmpty() && !productSet.isEmpty() && !yearSet.isEmpty() && negoSettings.assortmentSynchroMode == 'Conso') {
                    // call batch ConsolidateAssortmentBatch
                    Map<String, Object> consolidateParamsMap = new Map<String, Object>{
                        'startedFrom' => Trg_AssortmentDetail_Handler.class.getName(),
                        'countryIds' => countryOriginSet,
                        'buSourceIds' => buSourceSet,
                        'categoryIds' => categorySet,
                        'productIds' => productSet,
                        'years' => yearSet
                    };
                    NegoptimBatch.executeBatch('ConsolidateAssortmentsBatch', consolidateParamsMap, 200);
                }
            }
        }
    }
	/**
     * @description
     * 1- sync all the products loaded into a Master Assortment BU to all the Children Assortment BU
     * 2- sync all the products loaded into a Child Assortment BU to its related Master Assortment BU
     * @param List<AssortmentDetail__c> newAssortmentDetails new created assortment detail
	*/
    private static void syncProductFromMasterToChildren(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        //when the global setting is not diffusion, no need to proceed
        if (negoSettings.assortmentSynchroMode != 'Diffusion') {
            return;
        }
        Set<Id> allAssBuIdSet = new Set<Id>();
        //set for all the master assortment bu that meet specific conditions
        Set<Id> filteredMasterAssBuSet = new Set<Id>();
        //map of all the children assortment bu with its master assortment bu that meet specific conditions
        //key: child assortment bu
        //value: master assortment bu
        Map<Id, Id> filteredChildAssBuToMasterAssBuMap = new Map<Id, Id>();
        //all the master assortment detail that we want to difuse to the children assortment detail
        Set<Id> masterAssortmentDetailIdSet= new Set<Id>();
        //assortment detail of children assortment bu
        List<AssortmentDetail__c> childAssortmentDetailList = new List<AssortmentDetail__c>();
        //add all business unit
        for (AssortmentDetail__c asd : newAssortmentDetails) {
            allAssBuIdSet.add(asd.Assortment__c);
        }
        String[] assortmentBUFields = new String[] {
            SObjectType.Assortment__c.fields.Id.Name,
            SObjectType.Assortment__c.fields.RecordTypeId.Name,
            SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.Assortment__c.fields.AssortmentParent__c.Name
        };
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.LayerNegoConso__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)
           && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields))
        {
            //fill the filteredMasterAssBuSet, filteredChildAssBuToMasterAssBuMap with data
            for (Assortment__c item : [SELECT Id, BusinessUnitTarget__r.LayerNegoConso__c, AssortmentParent__c, RecordType.DeveloperName
                                       FROM Assortment__c
                                       WHERE Id IN :allAssBuIdSet
                                       AND ((BusinessUnitTarget__r.LayerNegoConso__c = TRUE AND AssortmentParent__c = NULL AND RecordType.DeveloperName = 'OnTopConso')
                                            OR (BusinessUnitTarget__r.LayerNegoConso__c = FALSE AND AssortmentParent__c <> NULL AND RecordType.DeveloperName = 'Negotiation'))])
            {
                if (item.BusinessUnitTarget__r.LayerNegoConso__c == true && item.AssortmentParent__c == null && item.RecordType.DeveloperName == 'OnTopConso') {
                    filteredMasterAssBuSet.add(item.Id);
                } else if (item.BusinessUnitTarget__r.LayerNegoConso__c == false && item.AssortmentParent__c != null && item.RecordType.DeveloperName == 'Negotiation') {
                    filteredChildAssBuToMasterAssBuMap.put(item.Id, item.AssortmentParent__c);
                }
            }
        }
        //specifiy what are the master assortment detail and children assortment detail
        for (AssortmentDetail__c asd : newAssortmentDetails) {
            if (filteredMasterAssBuSet.contains(asd.Assortment__c)) {
                masterAssortmentDetailIdSet.add(asd.Id);
            } else if (filteredChildAssBuToMasterAssBuMap.containsKey(asd.Assortment__c)) {
                childAssortmentDetailList.add(asd);
            }
        }
        //when the list of master assortment detail is not empty and the statis variable which called runBatch is true we should execute hte batch
        //to sync all the master assortment detail to the children assortment bu
        if(!masterAssortmentDetailIdSet.isEmpty() && runBatch) {
            syncToMaster = false;
            Map<String, Object> diffusionParamsMap = new Map<String, Object>{
                'startedFrom' => Trg_AssortmentDetail_Handler.class.getName(),
                'assortmentDetailIds' => masterAssortmentDetailIdSet,
                'initialize' => oldAssortmentDetailMap == null
            };
            NegoptimBatch.executeBatch('MasterAssortmentProductDiffusionBatch', diffusionParamsMap, 100);
        }
        // when a product is loaded into a child asosrtment bu, we should add this product to the master assortment bu
        if(!childAssortmentDetailList.isEmpty() && syncToMaster && oldAssortmentDetailMap == null) {
            //products that should be added to the master assortment bu
            //key: master Assortment bu + proudct
            //value: assortment detail of the product
            Map<String, AssortmentDetail__c> masterAssortmentBuProductToAsdMap = new Map<String, AssortmentDetail__c>();
            //products that actually exist in the master assortment bu
            //value: master Assortment bu + proudct
            Set<String> masterAssortmentBUProductExistingSet = new Set<String>();
            // all the product that we should retrieve
            Set<Id> childProductsIdSet = new Set<Id>();
            List<AssortmentDetail__c> masterAssortmentDetailToInsertList = new List<AssortmentDetail__c>();
            //iterate over the children assortment detail to see what products should we add to the master assortment bu
            for (AssortmentDetail__c asd : childAssortmentDetailList) {
                String masterAssortmentIdProdutId = '' + filteredChildAssBuToMasterAssBuMap.get(asd.Assortment__c) + asd.Product__c;
                if (filteredChildAssBuToMasterAssBuMap.containsKey(asd.Assortment__c)) {
                    if (!masterAssortmentBuProductToAsdMap.containsKey(masterAssortmentIdProdutId)) {
                        masterAssortmentBuProductToAsdMap.put(masterAssortmentIdProdutId, asd);
                    }
                    childProductsIdSet.add(asd.Product__c);
                }
            }
            assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.AssortmentParent__c.Name
            };
            String[] assortmentDetailFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Id.Name,
                SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                SObjectType.AssortmentDetail__c.fields.Product__c.Name
            };
           //get all the existinig product in the master assortment bu
           if (!childProductsIdSet.isEmpty() && !filteredChildAssBuToMasterAssBuMap.isEmpty()) {
               if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)
                   && NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields))
               {
                   for (AssortmentDetail__c asd : [SELECT Id, Assortment__c, Assortment__r.AssortmentParent__c, Product__c
                                                    FROM AssortmentDetail__c
                                                    WHERE Assortment__c IN :filteredChildAssBuToMasterAssBuMap.values()
                                                    AND Product__c IN :childProductsIdSet
                                                    AND Version__c = NULL])
                   {
                       masterAssortmentBUProductExistingSet.add('' + asd.Assortment__c + asd.Product__c);
                   }
                   //add the missing product to the master assortment bu
                   if (!masterAssortmentBuProductToAsdMap.isEmpty()) {
                       AssortmentDetail__c asdClone;
                       for (String masterAssBuIdroductId : masterAssortmentBuProductToAsdMap.keySet()) {
                           if (!masterAssortmentBUProductExistingSet.contains(masterAssBuIdroductId)) {
                               asdClone = masterAssortmentBuProductToAsdMap.get(masterAssBuIdroductId).clone(false, true, false, false);
                               asdClone.ExtId__c = null;
                               asdClone.Assortment__c = filteredChildAssBuToMasterAssBuMap.get(masterAssortmentBuProductToAsdMap.get(masterAssBuIdroductId).Assortment__c);
                               masterAssortmentDetailToInsertList.add(asdClone);
                           }
                       }
                   }
               }
               assortmentDetailFields = new String[] {
                    SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                    SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
               };
               if (!masterAssortmentDetailToInsertList.isEmpty()) {
                   runBatch = false;
                   if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                       List<Database.SaveResult> results = Database.insert(masterAssortmentDetailToInsertList, false);
                   }
               }
           }
        }
    }

    
    /**
    * @description update Ref Client Assortment of Target Assortment When the creation Date of Nego detail > creation date of Target detail
    * */
    private static void updateTargetDetailFromNego(List<AssortmentDetail__c> newAssortmentDetailList, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        Set<Id> BUIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        //Set<Integer> yearSet = new Set<Integer>();
        Map<String, AssortmentDetail__c> assortmentDetailMap = new Map<String, AssortmentDetail__c>();
        List<AssortmentDetail__c> detailsToUpdate = new List<AssortmentDetail__c>();
        Set<Id> validatedAssortmentDetailsIds = new Set<Id>();
        for (AssortmentDetail__c item : newAssortmentDetailList) {
            if (item.Version__c == null && item.Status__c == 'Validate'
                && (oldAssortmentDetailMap == null || (oldAssortmentDetailMap.containsKey(item.Id) && oldAssortmentDetailMap.get(item.Id).Status__c != 'Validate')))
            {
                validatedAssortmentDetailsIds.add(item.Id);
            }
        }
        if (!validatedAssortmentDetailsIds.isEmpty()) {
            Map<Id, AssortmentDetail__c> detailsMap = new Map<Id, AssortmentDetail__c>([SELECt Id, Assortment__r.BusinessUnitTarget__c, Product__c,
                                                                                                            ProductLifeStatusAss__c, BusinessUnitCluster__c, StartDate__c
                                                                                                            FROM AssortmentDetail__c
                                                                                                            WHERE Id IN :validatedAssortmentDetailsIds
                                                                                                            AND Assortment__r.RecordType.DeveloperName = 'Negotiation']);
            if (!detailsMap.isEmpty()) {
                for (AssortmentDetail__c detail : detailsMap.values()) {
                    BUIdSet.add(detail.Assortment__r.BusinessUnitTarget__c);
                    productIdSet.add(detail.Product__c);
                    //yearSet.add((Integer) (detail.Year__c + 1));
                    String key = detail.Product__c + '' + detail.Assortment__r.BusinessUnitTarget__c + '' ;
                    //+  detail.Year__c;
                    assortmentDetailMap.put(key, detail);
                }
                Map<Id, AssortmentDetail__c> targetDetailsMap = new Map<Id, AssortmentDetail__c>([SELECt Id, Assortment__r.BusinessUnitTarget__c, Product__c, 
                                                                                                                      ProductLifeStatusAss__c, BusinessUnitCluster__c, Assortment__r.BDate__c
                                                                                                                      FROM AssortmentDetail__c
                                                                                                                      WHERE Assortment__r.BusinessUnitTarget__c IN :BUIdSet
                                                                                                                      AND Product__c IN :productIdSet
                                                                                                                      //AND Year__c IN :yearSet
                                                                                                                      AND Assortment__r.RecordType.DeveloperName = 'Target'
                                                                                                                      AND AssortmentDetailNegotiationRef__c = NULL
                                                                                                                      AND Version__c = NULL]);
                if (!targetDetailsMap.isEmpty()) {
                    for (AssortmentDetail__c detail : targetDetailsMap.values()) {
                        String key = detail.Product__c + '' + detail.Assortment__r.BusinessUnitTarget__c + '' ;
                        //+  (detail.Year__c - 1);
                        if (assortmentDetailMap.containsKey(key)) {
                            AssortmentDetail__c negoDetail = assortmentDetailMap.get(key);
                            Assortment__c assortmentTarget = detail.Assortment__r;
                            // Fill Ref client with Nego detail validated
                            detail.AssortmentDetailNegotiationRef__c = negoDetail.Id;
                            // Fill client status And Ass Bu Cluster is they empty with the data of Nego detail validated
                            if (detail.ProductLifeStatusAss__c == null && detail.BusinessUnitCluster__c == null) {
                                if (assortmentTarget.BDate__c != null) {
                                    if (negoDetail.ProductLifeStatusAss__c == null || negoDetail.ProductLifeStatusAss__c == 'Complement' || negoDetail.ProductLifeStatusAss__c == 'Opportunity'
                                        || (negoDetail.StartDate__c != null && assortmentTarget.BDate__c <= negoDetail.StartDate__c))
                                    {
                                        detail.ProductLifeStatusAss__c = negoDetail.ProductLifeStatusAss__c;
                                    } else if (negoDetail.StartDate__c == null || assortmentTarget.BDate__c > negoDetail.StartDate__c) {
                                        if (negoDetail.ProductLifeStatusAss__c != 'Delist') {
                                            detail.ProductLifeStatusAss__c = 'Keep';
                                        } else {
                                            detail.ProductLifeStatusAss__c = null;
                                        }
                                    }
                                }
                                detail.BusinessUnitCluster__c = negoDetail.BusinessUnitCluster__c;
                            }
                            detailsToUpdate.add(detail);
                        }
                    }
                    if (!detailsToUpdate.isEmpty()) {
                        // check security on update AssortmentDetail__c
                        String[] assortmentDetailFields = new String[] {
                            SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name
                        };
                        if (NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                            update detailsToUpdate;
                        }
                    }
                }
            }
        }
    }
    
    public class NegoptimSettings {
        public String assortmentSynchroMode {get; set;}
    }

    /**
    * @description bottom up values field on AS from ASD
    * */
    private static void bottomUpAsValues(AssortmentWrapper assortmentWrapper, Map<Id, AssortmentDetail__c> oldAssortmentDetailMap) {
        Set<Id> assortmentIds = new Set<Id>();
        Set<Id> rollupAssortmentIdsWithConditions = new Set<Id>();
        Set<Id> assortmentBudgetIds = new Set<Id>();
        Set<Id> assortmentTargetIds = new Set<Id>();
        Set<Id> assortmentDetailBudgetIds = new Set<Id>();
        Set<Id> assortmentDetailTargetIds = new Set<Id>();
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
            Boolean isChangedPNClientBaseNego = false;
            if (item.Assortment__c != null
                && (oldAssortmentDetailMap == null
                    || (oldAssortmentDetailMap != null
                        && oldAssortmentDetailMap.containsKey(item.Id)
                        && (item.NDClientBaseNego_NegoL4LP1Gap__c != oldAssortmentDetailMap.get(item.Id).NDClientBaseNego_NegoL4LP1Gap__c
                            || item.WDClientBaseNego_NegoL4LP1Gap__c != oldAssortmentDetailMap.get(item.Id).WDClientBaseNego_NegoL4LP1Gap__c
                            || item.WDChannelBaseNego_NegoL4LP1Gap__c != oldAssortmentDetailMap.get(item.Id).WDChannelBaseNego_NegoL4LP1Gap__c
                            || item.NDChannelBaseNego_NegoL4LP1Gap__c != oldAssortmentDetailMap.get(item.Id).NDChannelBaseNego_NegoL4LP1Gap__c
                            || item.WDChannelBaseNego_TargetGap__c != oldAssortmentDetailMap.get(item.Id).WDChannelBaseNego_TargetGap__c
                            || item.QtyNego_NegoP1Gap__c != oldAssortmentDetailMap.get(item.Id).QtyNego_NegoP1Gap__c
                            || item.KVolumeNego_NegoP1Gap__c != oldAssortmentDetailMap.get(item.Id).KVolumeNego_NegoP1Gap__c
                            || item.KVolumeNego_TargetGap__c != oldAssortmentDetailMap.get(item.Id).KVolumeNego_TargetGap__c
                            || item.SellinNego_NegoP1Gap__c != oldAssortmentDetailMap.get(item.Id).SellinNego_NegoP1Gap__c
                            || item.SelloutNego_NegoP1Gap__c != oldAssortmentDetailMap.get(item.Id).SelloutNego_NegoP1Gap__c
                            || item.GPNego_NegoP1Gap__c != oldAssortmentDetailMap.get(item.Id).GPNego_NegoP1Gap__c
                            || item.GPNego_TargetGap__c != oldAssortmentDetailMap.get(item.Id).GPNego_TargetGap__c))))
            {
                assortmentIds.add(item.Assortment__c);
            }
            // check if any field for On Top AS was changed to bottom up it to the Channel Budget & target Assortment
            if (assortmentBU.OnTop__c && (oldAssortmentDetailMap == null
                                                    || (oldAssortmentDetailMap != null
                                                        && oldAssortmentDetailMap.containsKey(item.Id)
                                                        && (item.WDChannelBaseNego__c != oldAssortmentDetailMap.get(item.Id).WDChannelBaseNego__c
                                                            || item.NDChannelBaseNego__c != oldAssortmentDetailMap.get(item.Id).NDChannelBaseNego__c
                                                            || item.PNChannelBaseNego__c != oldAssortmentDetailMap.get(item.Id).PNChannelBaseNego__c
                                                            || item.WDChannelBaseNegoL4L__c != oldAssortmentDetailMap.get(item.Id).WDChannelBaseNegoL4L__c
                                                            || item.NDChannelBaseNegoL4L__c != oldAssortmentDetailMap.get(item.Id).NDChannelBaseNegoL4L__c
                                                            || item.PNChannelBaseNegoL4L__c != oldAssortmentDetailMap.get(item.Id).PNChannelBaseNegoL4L__c
                                                            || item.QtyNego__c != oldAssortmentDetailMap.get(item.Id).QtyNego__c
                                                            || item.KVolumeNego__c != oldAssortmentDetailMap.get(item.Id).KVolumeNego__c
                                                            || item.SalesCannibalizationRate__c != oldAssortmentDetailMap.get(item.Id).SalesCannibalizationRate__c))))
            {
                if (item.AssortmentDetailBudgetRef__c != null) {
                    assortmentBudgetIds.add(assortmentBU.AssortmentChannelBudgetRef__c);
                    assortmentDetailBudgetIds.add(item.AssortmentDetailBudgetRef__c);
                }
                if (item.AssortmentDetailTargetRef__c != null) {
                    assortmentTargetIds.add(assortmentBU.AssortmentTargetRef__c);
                    assortmentDetailTargetIds.add(item.AssortmentDetailTargetRef__c);
                }
            }
        }
        Map<Id, Assortment__c> assortmentsToUpdateMap = new Map<Id, Assortment__c>();
        if (!assortmentIds.isEmpty()) {
            // Others RollUp-Summary
            List<AggregateResult> results = [SELECT Assortment__c assortmentId, SUM(NDClientBaseNego_NegoL4LP1Gap__c) NDClientBaseNego_NegoL4LP1Gap__c, SUM(WDClientBaseNego_NegoL4LP1Gap__c) WDClientBaseNego_NegoL4LP1Gap__c,
                                             SUM(WDChannelBaseNego_NegoL4LP1Gap__c) WDChannelBaseNego_NegoL4LP1Gap__c, SUM(WDChannelBaseNego_TargetGap__c) WDChannelBaseNego_TargetGap__c, SUM(QtyNego_NegoP1Gap__c) QtyNego_NegoP1Gap__c,
                                             SUM(KVolumeNego_NegoP1Gap__c) KVolumeNego_NegoP1Gap__c, SUM(KVolumeNego_TargetGap__c) KVolumeNego_TargetGap__c, SUM(GPNego_NegoP1Gap__c) GPNego_NegoP1Gap__c,
                                             SUM(GPNego_TargetGap__c) GPNego_TargetGap__c, SUM(SellinNego_NegoP1Gap__c) SellinNego_NegoP1Gap__c, SUM(SelloutNego_NegoP1Gap__c) SelloutNego_NegoP1Gap__c,
                                             SUM(NDChannelBaseNego_NegoL4LP1Gap__c) NDChannelBaseNego_NegoL4LP1Gap__c, SUM(PNClientBaseNego_NegoL4LP1Gap__c) PNClientBaseNego_NegoL4LP1Gap__c,
                                             SUM(KVolumeNego_P1__c) KVolumeNego_P1__c, SUM(SelloutNego_P1__c) SelloutNego_P1__c, SUM(GPNego_P1__c) GPNego_P1__c
                                             FROM AssortmentDetail__c
                                             WHERE Assortment__c IN :assortmentIds
                                             AND Version__c = NULL
                                             GROUP BY Assortment__c];
            for (AggregateResult result : results) {
                Id assortmentId = (Id) result.get('assortmentId');
                Assortment__c assortment = new Assortment__c(Id = assortmentId);
                if(assortmentsToUpdateMap.containsKey(assortmentId)) assortment = assortmentsToUpdateMap.get(assortmentId);
                assortment.NDClientBaseNego_NegoL4LP1Gap__c = (Decimal) result.get('NDClientBaseNego_NegoL4LP1Gap__c');
                assortment.WDClientBaseNego_NegoL4LP1Gap__c = (Decimal) result.get('WDClientBaseNego_NegoL4LP1Gap__c');
                assortment.WDChannelBaseNego_NegoL4LP1Gap__c = (Decimal) result.get('WDChannelBaseNego_NegoL4LP1Gap__c');
                assortment.WDChannelBaseNego_TargetGap__c = (Decimal) result.get('WDChannelBaseNego_TargetGap__c');
                assortment.QtyNego_NegoP1Gap__c = (Decimal) result.get('QtyNego_NegoP1Gap__c');
                assortment.KVolumeNego_NegoP1Gap__c = (Decimal) result.get('KVolumeNego_NegoP1Gap__c');
                assortment.KVolumeNego_TargetGap__c = (Decimal) result.get('KVolumeNego_TargetGap__c');
                assortment.GPNego_NegoP1Gap__c = (Decimal) result.get('GPNego_NegoP1Gap__c');
                assortment.GPNego_TargetGap__c = (Decimal) result.get('GPNego_TargetGap__c');
                assortment.SellinNego_NegoP1Gap__c = (Decimal) result.get('SellinNego_NegoP1Gap__c');
                assortment.SelloutNego_NegoP1Gap__c = (Decimal) result.get('SelloutNego_NegoP1Gap__c');
                assortment.NDChannelBaseNego_NegoL4LP1Gap__c = (Decimal) result.get('NDChannelBaseNego_NegoL4LP1Gap__c');
                assortmentsToUpdateMap.put(assortmentId, assortment);
            }
            if ( !assortmentsToUpdateMap.isEmpty()) {
                update assortmentsToUpdateMap.values();
            }
        }
        if (!System.isBatch() && !System.isFuture() && (!assortmentDetailBudgetIds.isEmpty() || !assortmentDetailTargetIds.isEmpty())) {
            Map<String, Object> calcRefParamsMap = new Map<String, Object>{
                'startedFrom' => Trg_AssortmentDetail_Handler.class.getName(),
                'assortmentBudgetIds' => assortmentBudgetIds,
                'assortmentTargetIds' => assortmentTargetIds,
                'assortmentDetailBudgetIds' => assortmentDetailBudgetIds,
                'assortmentDetailTargetIds' => assortmentDetailTargetIds,
                'productIds' => null
            };
            NegoptimBatch.executeBatch('CalculateRefAssortmentBatch', calcRefParamsMap, 20);
        }
    }
    
    /**
     * @description change the category of Assortment Detail Based on the Category defined in ProductBannerCategory__c
     * executes 
     * On Before Insert or Update
    * */
    private static void updateClientCategory(AssortmentWrapper assortmentWrapper) {
        Set<Id> productIdsSet = new Set<Id>();
        Set<Id> clientIdsSet = new Set<Id>();
        Set<Id> buIdsSet = new Set<Id>();
        Set<Id> countryOriginIdsSet = new Set<Id>();
        Map<String, String> productBUCategMap = new Map<String, String>();	
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            if(item.Id == null && item.Version__c == null && assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                Assortment__c assortment = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                if (item.Product__c != null) {
                    productIdsSet.add(item.Product__c);
                }
                if (assortment.BusinessUnitTarget__c != null) {
                    buIdsSet.add(assortment.BusinessUnitTarget__c);
                }
                if (assortment.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c != null) {
                    countryOriginIdsSet.add(assortment.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c);
                }
                if (assortment.BusinessUnitTarget__r.Supplier__c != null) {
                    clientIdsSet.add(assortment.BusinessUnitTarget__r.Supplier__c);
                }
            }
        }
        if (!productIdsSet.isEmpty()) {
            List<PG__c> pgList = [SELECT Id, Hierarchy__c, Product__c, Supplier__c, BusinessUnit__c, ClientCategory__c
                                  FROM PG__c 
                                  WHERE Product__c IN :productIdsSet
                                  AND (Supplier__c IN :clientIdsSet
                                       OR BusinessUnit__c IN :buIdsSet
                                       OR BusinessUnit__c IN :countryOriginIdsSet)];
            if (pgList != null && !pgList.isEmpty()) {
                for (PG__c pg : pgList) {
                    String key = pg.Product__c + '' + pg.Supplier__c + '' + (pg.BusinessUnit__c != null ? pg.BusinessUnit__c + '' : '');
                    productBUCategMap.put(key, pg.ClientCategory__c);
                }
            }
            for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
                if(assortmentWrapper.assortmentBUMap.containsKey(item.Assortment__c)) {
                    Assortment__c assortment = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
                    String key = item.Product__c + '' + assortment.BusinessUnitTarget__r.Supplier__c + '' + assortment.BusinessUnitTarget__c;
                    String key2 = item.Product__c + '' + assortment.BusinessUnitTarget__r.Supplier__c + '' + assortment.BusinessUnitTarget__r.BusinessUnitCountryOrigin__c;
                    String key3 = item.Product__c + '' + assortment.BusinessUnitTarget__r.Supplier__c + '';
                    if (productBUCategMap.containsKey(key)) {
                        item.ClientCategory__c = productBUCategMap.get(key);
                    } else if (productBUCategMap.containsKey(key2)) {
                        item.ClientCategory__c = productBUCategMap.get(key2);
                    } else if (productBUCategMap.containsKey(key3)) {
                        item.ClientCategory__c = productBUCategMap.get(key3);
                    } else {
                        item.ClientCategory__c = null;
                    }
                }
            }
        }
    }
    /**
     * @description change the category of Assortment Detail Based on the Category defined in ProductBannerCategory__c
     * executes 
     * On Before Insert or Update
    * */
    private static void generateHLPASD(AssortmentWrapper assortmentWrapper) {
        Id regularAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'Regular');
        Id hlpAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'HigherLevelPackaging');
        Map<Id, Set<Id>> productASMap = new Map<Id, Set<Id>>();
        Map<String, AssortmentDetail__c> hlpProductMap = new Map<String, AssortmentDetail__c>();
        Set<Id> productIds = new Set<Id>();
        List<AssortmentDetail__c> assortmentDetailsListToInsert = new List<AssortmentDetail__c>();
        for (AssortmentDetail__c item : assortmentWrapper.assortmentDetails) {
            Assortment__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Assortment__c);
            if (assortmentBU.RecordType.DeveloperName != 'ChannelBudget'
                && assortmentBU.RecordType.DeveloperName != 'OnTopConso'
                && assortmentBU.RecordType.DeveloperName != 'TargetConso'
                && item.Version__c == null
                && item.Product__c != null
                && item.RecordTypeId == regularAssortmentDetailRecordType)
            {
                if (!productASMap.containsKey(item.Assortment__c)) {
                    productASMap.put(item.Product__c, new Set<Id>());
                }
                productASMap.get(item.Product__c).add(item.Assortment__c);
                productIds.add(item.Product__c);
                hlpProductMap.put(item.Product__c + '' + item.Assortment__c, item);
            }
        }
        if (!productIds.isEmpty()) {
            String[] productFields = new String[] {
                SObjectType.Product2.fields.Id.Name,
                SObjectType.Product2.fields.Hierarchy__c.Name,
                SObjectType.Product2.fields.Consumer_Trade_Item__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields)) {
                List<Product2> productsHLP = [SELECT Id, Hierarchy__c, Consumer_Trade_Item__c
                                              FROM Product2
                                              WHERE Consumer_Trade_Item__c IN :productIds
                                              AND Hierarchy__c <> NULL];
                for (Product2 item : productsHLP) {
                    if (productASMap.containsKey(item.Consumer_Trade_Item__c)) {
                        for (Id assortmentId : productASMap.get(item.Consumer_Trade_Item__c)) {
                            AssortmentDetail__c asd = new AssortmentDetail__c();
                            asd.Assortment__c = assortmentId;
                            asd.Product__c = item.Id;
                            asd.Hierarchy__c = item.Hierarchy__c;
                            asd.StartDate__c = assortmentWrapper.assortmentBUMap.get(assortmentId).BDate__c;
                            asd.RecordTypeId = hlpAssortmentDetailRecordType;
                            assortmentDetailsListToInsert.add(asd);
                        }
                    }
                }
                // insert HLP ASD
                if(!assortmentDetailsListToInsert.isEmpty()) {
                    // check security on update AssortmentDetail__c
                    String[] assortmentDetailFields = new String[] {
                        SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
                        SObjectType.AssortmentDetail__c.fields.Product__c.Name,
                        SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
                        SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
                        SObjectType.AssortmentDetail__c.fields.RecordTypeId.Name
                    };
                    if(NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
                        List<Database.SaveResult> results = Database.insert(assortmentDetailsListToInsert, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            AssortmentDetail__c assortmentDetail = assortmentDetailsListToInsert.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                system.debug('errorMessage >>>> ' + errorMessage);
                                hlpProductMap.get(assortmentDetail.Product__c + '' +  assortmentDetail.Assortment__c).addError(errorMessage);
                            }
                        }
                    }
                }
            }
        }
    }

    private static void executeGenerateAssortmentBUBatch(List<AssortmentDetail__c> newAssortmentDetails, Map<Id, AssortmentDetail__c> oldAssortmentDetailsMap) {
        Set<Id> validatedASDIds = new Set<Id>();
        for (AssortmentDetail__c item : newAssortmentDetails) {
            if (item.Status__c == 'Validate' && (oldAssortmentDetailsMap == null || item.Status__c != oldAssortmentDetailsMap.get(item.Id).Status__c)) {
                validatedASDIds.add(item.Id);
            }
        }
        if (!validatedASDIds.isEmpty() && !System.isBatch() && !System.isFuture()) {
            Map<String, Object> params = new Map<String, Object>();
            params.put('startedFrom', Trg_AssortmentDetail_Handler.class.getName());
            params.put('assortmentDetailIdSet', validatedASDIds);
            params.put('assortmentIdSet', null);
            NegoptimBatch.executeBatch('GenerateAssortmentBUBatch', params,1);
        }
    }
}