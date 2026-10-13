public with sharing class NegotiateIndexesCmpController {
    @AuraEnabled
    public static String getContracts(String nsId, Integer negoYear, String contractId, Boolean postSigned){
        List<ContractIndexMapWrapper> wIndexes = new List<ContractIndexMapWrapper>();
        try {
            Id ns = nsId;
            Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
            Map<String, schema.SObjectField> contractFieldsMap = SObjectType.Contract__c.fields.getMap();
            Set<Id> contractIds = new set<Id>();
            String query = 'SELECT Id, Name, Depreciation_Rate_YE__c, Rise_Rate_YE__c, Index1__c, Index2__c, Index3__c, Index4__c, Index5__c, Index6__c, Index7__c, Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Index6_perc__c, Index7_perc__c, ';
            query += ' Rise_Rate__c, Total_TO_Tariff_Nego__c, TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c, Total_TO__c, BusinessUnitContract__c, Supplier_Nego_Scope__c, Contract_BDate__c, Contract_EDate__c,';
            query += ' Depreciation_Rate__c, Markdown_Rate_Break__c, Markdown_Rate_Promo__c, Markdown_Rate_Theft__c, IsCalculatedIndexV2__c,';
            query += ' index1_v2__c, ';
            query += ' index2_v2__c, ';
            query += ' index3_v2__c, ';
            query += ' index4_v2__c, ';
            query += ' index5_v2__c, ';
            query += ' index6_v2__c, ';
            query += ' index7_v2__c, ';
            query += ' (';
            query += ' SELECT';
            query += ' Id, ';
            query += ' Name, ';
            query += ' RecordTypeId, ';
            query += ' RecordType.DeveloperName, ';
            query += ' Base_Quantity_Nego__c, ';
            query += ' Base_to_Nego__c, ';
            query += ' Base_TO_Nego_YearBase__c, ';
            query += ' Base_TO_Tariff_Nego__c, ';
            query += ' BusinessUnitScope__c, ';
            query += ' commercial_reference__c, ';
            query += ' Condition_Type__r.Name, ';
            query += ' Condition_Type__r.Condition_Mode__c, ';
            query += ' Condition_Type__r.Index__c, ';
            query += ' Condition_Type__r.Nego_Discount_Type__c, ';
            query += ' Condition_Type__r.Capture_Discount_Product_Level__c, ';
            query += ' Contract__c, ';
            query += ' Display_Order__c, ';
            query += ' Contract__r.Id, ';
            query += ' Contract__r.Name, ';
            query += ' Contract__r.Contract_BDate__c, ';
            query += ' Contract__r.Contract_EDate__c, ';
            query += ' Contract__r.Qty1__c, ';
            query += ' Contract__r.Qty2__c, ';
            query += ' Contract__r.Qty3__c, ';
            query += ' Contract__r.Qty4__c, ';
            query += ' Contract__r.Qty5__c, ';
            query += ' Contract__r.Qty6__c, ';
            query += ' Contract__r.Qty7__c, ';
            query += ' Contract__r.Qty8__c, ';
            query += ' Contract__r.Qty9__c, ';
            query += ' Contract__r.Qty10__c, ';
            query += ' Contract__r.Qty11__c, ';
            query += ' Contract__r.Qty12__c, ';
            query += ' Contract__r.TO1__c, ';
            query += ' Contract__r.TO2__c, ';
            query += ' Contract__r.TO3__c, ';
            query += ' Contract__r.TO4__c, ';
            query += ' Contract__r.TO5__c, ';
            query += ' Contract__r.TO6__c, ';
            query += ' Contract__r.TO7__c, ';
            query += ' Contract__r.TO8__c, ';
            query += ' Contract__r.TO9__c, ';
            query += ' Contract__r.TO10__c, ';
            query += ' Contract__r.TO11__c, ';
            query += ' Contract__r.TO12__c, ';
            query += ' Disc_BDate__c, ';
            query += ' Disc_EDate__c, ';
            query += ' Index__c, ';
            query += ' index_v2__c, ';
            query += ' Index_perc__c, ';
            query += ' Index_Val__c, ';
            query += ' Is_Excluded_To_NegoBase__c, ';
            query += ' Exclusion_to_Nego_Base_Value__c, ';
            query += ' Is_Excluded_To_Nego_Base_F__c, ';
            query += ' Is_Excluded_To_Nego_Base_U__c, ';
            query += ' slab_calc_method__c, ';
            query += ' Is_Tariff_Condition__c, ';
            query += ' Nego_Discount_Type__c, ';
            query += ' Product_Scope__c, ';
            query += ' Product_Scope__r.Name, ';
            query += ' Rank__c, ';
            query += ' Status__c, ';
            query += ' unit_amount__c, ';
            query += ' Value_amt__c, ';
            query += ' Value_per__c, ';
            query += ' YTD_Nego__c, ';
            query += ' YTD_Nego_Computed__c ';
            query += ' FROM Contract_Discounts__r';
            query += ' WHERE Status__c <>\'Deleted\' AND Parent_Discount__c = NULL AND RecordType.DeveloperName NOT IN (\'Sub_Term_To_Be_Signed\', \'Sub_Term_Signed\') ';
            
            // query += ' SELECT Id, Name, Value_per__c, Value_amt__c, unit_amount__c, Base_to_Nego__c, YTD_Nego_Computed__c, RecordTypeId, RecordType.DeveloperName, ';
            // query += ' Index_Val__c, Index_perc__c, Base_TO_Tariff_Nego__c, Is_Tariff_Condition__c, Is_Excluded_To_NegoBase__c, Nego_Discount_Type__c, ';
            // query += ' Product_Scope__c, BusinessUnitScope__c, Disc_EDate__c, Disc_BDate__c, Condition_Type__r.Index__c, Index__c, Rank__c, Contract__c, ';
            // query += ' Base_Quantity_Nego__c, YTD_Nego__c, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Name ';
            // query += ' FROM Contract_Discounts__r  ';
            // query += ' WHERE Parent_Discount__c = null AND RecordType.DeveloperName NOT IN (\'Sub_Term_To_Be_Signed\', \'Sub_Term_Signed\') AND Status__c <> \'Deleted\'  ';
            // query += ' AND ((Contract__r.RecordType.DeveloperName = \'Nego_Base_Init\') OR (Contract__r.RecordType.DeveloperName = \'Nego_Base\' AND (Is_Excluded_To_NegoBase__c IN (FALSE, NULL) OR Value_amt__c NOT IN (NULL, 0))))  ';
            // query += '  ORDER BY Contract__c, Display_Order__c ASC)  ';
            query += ' ) ';
            query += '  FROM Contract__c  ';
            if (String.isNotBlank(contractId)) {
                query += '  WHERE Id =\''+ contractId +'\' ';
            } else {
                NegoSettings negoSettings = NegoSettings.loadNegoSettings();
                 List<String> contractRTNSettings = new List<String>{'Nego_Base', 'Landing', 'Signed', 'To_Be_Signed'};
                List<String> contractRTN1Settings = new List<String>{'Period_Extension', 'Safe_Balance', 'Simulation', 'Target', 'Proposal'};
                if (negoSettings != null && negoSettings.negotiatePageConfiguration != null) {
                    if (postSigned == true) {
                        contractRTNSettings = negoSettings.negotiatePageConfiguration.addendumNegotiationRTs.current;
                        contractRTN1Settings = negoSettings.negotiatePageConfiguration.addendumNegotiationRTs.next;
                    } else {
                        contractRTNSettings = negoSettings.negotiatePageConfiguration.annualNegotiationRTs.current;
                        contractRTN1Settings = negoSettings.negotiatePageConfiguration.annualNegotiationRTs.next; 
                    }
                }
                String whereClause = 'Supplier_Nego_Scope__c = \'' + nsId + '\'';
                whereClause += ' AND (((CALENDAR_YEAR(Contract_EDate__c) = ' + (negoYear - 1) + ' OR CALENDAR_YEAR(Contract_BDate__c) = ' + (negoYear - 1) + ') AND CALENDAR_YEAR(Contract_BDate__c) >= ' + (negoYear - 1) + ' AND RecordType.DeveloperName IN (\'' + String.join(contractRTNSettings, '\',\'') +'\'))';
                whereClause += ' OR ((CALENDAR_YEAR(Contract_EDate__c) = ' + negoYear + ' OR CALENDAR_YEAR(Contract_BDate__c) = ' + negoYear + ') AND RecordType.DeveloperName IN (\'' + String.join(contractRTN1Settings, '\',\'') +'\'))';
                whereClause += ' OR (Is_OnTop_Simulation__c = TRUE AND (CALENDAR_YEAR(Contract_EDate__c) = ' + negoYear + ' OR CALENDAR_YEAR(Contract_BDate__c) = ' + negoYear + '))';
                whereClause += ' OR (RecordType.DeveloperName = \'Period_Extension\' AND (CALENDAR_YEAR(Contract_EDate__c) = ' + negoYear + ' OR CALENDAR_YEAR(Contract_BDate__c) = ' + negoYear + ')))';
                String orderBy = ' ORDER BY CreatedDate, SimulationNumber__c ASC NULLS FIRST';
                query += '  WHERE Status__c <> \'Deleted\' AND ' + whereClause;
                query += ' ' + orderBy;
            }
            System.debug('query >>>>' + query);
            for (Contract__c item : Database.query(query)) {
                System.debug('item >>>>' + item.Name);
                contractMap.put(item.Id, item);
                // ContractServices indexServices = new ContractServices(item, item.Contract_Discounts__r);
                // List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
                // // if (indexes.size() > 0) {
                //     ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(item, indexes);
                //     wContractIndex.baseIndex = indexServices.getContractBaseIndex();
                //     wIndexes.add(wContractIndex);
                // // }
                List<ContractServices.ContractIndexWrapper> indexes = new List<ContractServices.ContractIndexWrapper>();
                Integer scale = 2;
                Decimal totalTo = item.Total_TO__c;
                Decimal previousTO = item.Total_TO__c;
                // Decimal totalTOTarifNego = 0;
                for (Integer indexNumber = 1; indexNumber < 8; indexNumber++) {
                    String indexName = contractFieldsMap.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')).getDescribe().getLabel();
                    ContractServices.ContractIndexWrapper wContractIndex = new ContractServices.ContractIndexWrapper(indexName);
                    wContractIndex.indexName = 'Index' + indexNumber;
                    wContractIndex.refRate = 0;
                    wContractIndex.Index = item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')) != null ? (Decimal)item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')) : 0;
                    wContractIndex.IndexV2 = item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2__c')) != null ? (Decimal)item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2__c')) : 0;
                    wContractIndex.IndexPerc = item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_perc__c')) != null ? (Decimal)item.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_perc__c')) : 0;
                    if (indexNumber == 1) {
                        wContractIndex.TO = totalTo;
                        wContractIndex.Computed =  ((1 - wContractIndex.IndexPerc / 100) != 0 ? (totalTo / (1 - wContractIndex.IndexPerc / 100)) : 0) - totalTo;
                    }
                    Decimal computed = 0;
                    for (Contract_Discount__c discount : item.Contract_Discounts__r) {
                        if (discount.Index__c == 'Index' + indexNumber) {
                            computed += (discount.YTD_Nego_Computed__c != null ? discount.YTD_Nego_Computed__c : 0).setScale(0);
                        }
                        // if (discount.Is_Tariff_Condition__c || discount.Index__c == 'Index1') {
                        //     totalTOTarifNego += (discount.YTD_Nego_Computed__c != null ? discount.YTD_Nego_Computed__c : 0).setScale(0);
                        // }
                    }
                    wContractIndex.Computed = computed != null ? computed.setScale(0) : 0;
                    if (indexNumber != 1 && wContractIndex != null) {
                        if (wContractIndex.index != 0) {
                            wContractIndex.TO = ((previousTO != null ? previousTO : 0) - (computed != null ? computed : 0)).setScale(0);
                        }
                    }
                    indexes.add(wContractIndex);
                    previousTO = wContractIndex.TO;
                }
                Decimal baseIndex = 100;
                baseIndex -= item.Depreciation_Rate_YE__c != null ? baseIndex * item.Depreciation_Rate_YE__c / 100 : 0;
                baseIndex += item.Markdown_Rate_Break__c != null ? item.Markdown_Rate_Break__c : 0;
                baseIndex += item.Markdown_Rate_Promo__c != null ? item.Markdown_Rate_Promo__c : 0;
                baseIndex += item.Markdown_Rate_Theft__c != null ? item.Markdown_Rate_Theft__c : 0;
                baseIndex += item.Rise_Rate_YE__c != null ? baseIndex * item.Rise_Rate_YE__c / 100 : 0;
                // item.Total_TO_Tariff_Nego__c = totalTOTarifNego;
                ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(item, indexes);
                wContractIndex.baseIndex = baseIndex;
                wIndexes.add(wContractIndex);
                System.debug('wContractIndex >>>>' + JSON.serialize(wContractIndex));
            }
        } catch (Exception e) {
            System.debug('>>>>> controller execption  : ' + e.getMessage() + ' --  ' + e.getLineNumber() + ' -- ' + e.getStackTraceString());
        }
        return JSON.serialize(wIndexes);
    }
    public class ContractIndexMapWrapper {
        @AuraEnabled
        public string key {get; set;}
        @AuraEnabled
        public string contractName {get; set;}
        @AuraEnabled
        public Decimal baseIndex {get; set;}
        @AuraEnabled
        public Decimal riseRate {get; set;}
        @AuraEnabled
        public Decimal depresiationRate {get; set;}
        @AuraEnabled
        public Decimal totalToTariffNego {get; set;}
        @AuraEnabled
        public string progressTarget {get; set;}
        @AuraEnabled
        public List<ContractServices.ContractIndexWrapper> values {get; set;}
        @AuraEnabled
        public Boolean isCalculatedIndexV2 {get; set;}
        
        public ContractIndexMapWrapper(Contract__c contract, List<ContractServices.ContractIndexWrapper> values) {
            this.key = contract.Id;
            this.contractName = contract.name;
            this.riseRate = contract.Rise_Rate_YE__c;
            this.depresiationRate = contract.Depreciation_Rate_YE__c;
            this.totalToTariffNego = contract.Total_TO_Tariff_Nego__c;
            this.values = values;
            this.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
        }
    }
    public class NegoptimSettings {
        Boolean prioritizeSortBDateNegotiateFollowup;
        Boolean prioritizeSortBDateNegotiate;
        String sBusinessType;
    }
    public static NegoptimSettings loadGlobalSettings() {
        // NegoptimSettings negoptimsettings = new NegoptimSettings();
        // String serializedGlobalSettings = GlobalSettingsManager.loadGlobalSettingsSerialized();
        // System.debug('serializedGlobalSettings = ' + serializedGlobalSettings);
        // Map<String, Object> globalSettingsMap = (Map<String, Object>) JSON.deserializeUntyped(serializedGlobalSettings);
        // negoptimsettings.sBusinessType = (String)globalSettingsMap.get('sBusinessType');
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }
}