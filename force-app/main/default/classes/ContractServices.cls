/**
 * @author ULiT
 * @date 17-01-2021
 * */
public with sharing class ContractServices {

    public static NegoSettings myNegoSettings = NegoSettings.loadNegoSettings();
    public Contract__c contract;
    public List<Contract_Discount__c> conditions;
    public Decimal totalTo;
    public Decimal totalQty;
    public Map<String, Decimal> refRateMap {get; set;}
    public Integer maxCalculatedIndex {get; set;}
    // public Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
	// Month map names
    public static Map<Integer, String> monthsMap {
        get {
            Map<Integer, String> monthsMap = new Map<Integer, String>{
                1 => Label.LBL_January,
                2 => Label.LBL_February,
                3 => Label.LBL_March,
                4 => Label.LBL_April,
                5 => Label.LBL_May,
                6 => Label.LBL_June,
                7 => Label.LBL_July,
                8 => Label.LBL_August,
                9 => Label.LBL_September,
                10 => Label.LBL_October,
                11 => Label.LBL_November,
                12 => Label.LBL_December
            };
            return monthsMap;
        }
    }

    public static List<String> staticPolComConditionFields = new List<String> {
        SObjectType.Pol_Com_Condition__c.fields.Id.Name,
        SObjectType.Pol_Com_Condition__c.fields.Name.Name,
        SObjectType.Pol_Com_Condition__c.fields.RecordTypeId.Name,
        SObjectType.Pol_Com_Condition__c.fields.Rank_Order__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Parent_Condition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Acc_Document_Type__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Accounting_Document_Type_Balance__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Brand_Type__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Comment__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Folding_Discount__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_International_Discount__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Comment_AMEND__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Comment_Change_Authorization__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Comment_PE__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Condition_Status__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Conditional_Slab_Method__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Definition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Definition_Change_Authorization__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.definition_Lang2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Definition_N1__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.definition_N1_Lang2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Definition_P1__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.definition_P1_Lang2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Definition_P2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.definition_P2_Lang2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Duplication_Discount_Mapping__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Conditional__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Contract_Unicity_Requiered__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Default_SubCondition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Free_Product_Discount__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Required_SubRate_Statement__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Tariff_Condition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Yearly_Condition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.BusinessUnitMaster__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Name_Com__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Name_Fi__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Name_Leg__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Index_Target__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.BusinessUnitCounterpartyProof__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_definition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_requested_PE__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Proof_counterparty_type__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut1__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut2__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut3__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Specific_Contract_Type_Authorization__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Status_BDate__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Status_EDate__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Supply_flow__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.VAT_Type__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Original_Name__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Original_code__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.LimitUsage_ToProfile__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Condition_Code__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Proof_Counterparty_Execution_Agreement__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Force_RightToChange_InStatus__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_Valid_ByDefault__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_FlatPrice_Condition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Is_TransferPrice_Condition__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Condition_Duplication__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.Condition_Duplication_PE__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.InvoicePlanningPE__c.Name,
        SObjectType.Pol_Com_Condition__c.fields.InvoicePlanning__c.Name
    };
    
    public static List<String> staticInvoicePlanningFields = new List<String> {
        SObjectType.InvoicePlanning__c.fields.Id.Name,
        SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageP__c.Name,
        SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageF__c.Name,
        SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageU__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesBaseP__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesBaseF__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesBaseU__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesPeriodP__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesPeriodF__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesPeriodU__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesSequenceP__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesSequenceF__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesSequenceU__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesStartDateP__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesStartDateF__c.Name,
        SObjectType.InvoicePlanning__c.fields.SeriesStartDateU__c.Name
    };
    //Record Types
    public static Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    public static String TYPE_CONTRACT = 'Contract';
    public static String TYPE_TARGET = 'Target';
    public static String TYPE_SIMULATION = 'Simulation';
    public static String TYPE_NEGO_BASE = 'Nego_Base';
    public static String TYPE_NEGO_BASE_INIT = 'Nego_Base_Init';
    public static String TYPE_SAFE_BALANCE = 'Safe_Balance';
    public static String TYPE_PE = 'Period_Extension';
    public static String TYPE_SIGNED = 'Signed';
    public static String TYPE_OBJECTIVE = 'Objective';
    public static String TYPE_POST_NEGO_SIMULATION = 'PostNego_Simulation';
    public static String TYPE_PROPOSAL = 'Proposal';
    public static String TYPE_TO_BE_SIGNED = 'To_Be_Signed';
    public static String TYPE_LANDING = 'Landing';
    public static String TYPE_SIGNED_COPY = 'Signed_Copy';
    public static String proposalRecordTypeId = contractRTIds.get(TYPE_PROPOSAL);
    public static String landingRecordTypeId = contractRTIds.get(TYPE_LANDING);
    public static String toBeSignedRecordTypeId = contractRTIds.get(TYPE_TO_BE_SIGNED);
    public static String signedRecordTypeId = contractRTIds.get(TYPE_SIGNED);
    public static String objectiveRecordTypeId = contractRTIds.get(TYPE_OBJECTIVE);
    public static String peRecordTypeId = contractRTIds.get(TYPE_PE);
    public static String negoBaseRecordTypeId = contractRTIds.get(TYPE_NEGO_BASE);
    public static String negoBaseInitRecordTypeId = contractRTIds.get(TYPE_NEGO_BASE_INIT);
    public static String simulationRecordTypeId = contractRTIds.get(TYPE_SIMULATION);
    public static String safeBalanceRecordTypeId = contractRTIds.get(TYPE_SAFE_BALANCE);
    public static String targetRecordTypeId = contractRTIds.get(TYPE_TARGET);
    public static String postNegoSimulationRecordTypeId = contractRTIds.get(TYPE_POST_NEGO_SIMULATION);
    public static String signedCopyRecordTypeId = contractRTIds.get(TYPE_SIGNED_COPY);
    
    public static NegoptimSettings negoptimSettings {
        get {
            if(negoptimSettings == null) {
                negoptimSettings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
            }
            return negoptimSettings;
        }
        private set;
    }
    
    public ContractServices(Contract__c contract, List<Contract_Discount__c> conditions) {
        this.contract = contract;
        this.conditions = conditions;
        this.totalTo = 0;
        this.totalQty = 0;
        for (Integer i = 1; i < 13; i++) {
            this.totalTo +=  contract.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c')) != null ? Decimal.valueOf(String.ValueOf(contract.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c')))) : 0;
            this.totalQty += this.contract.get(NegoptimHelper.normalizeAPIName('Qty' + i +'__c')) != null ? (Decimal)this.contract.get(NegoptimHelper.normalizeAPIName('Qty' + i +'__c')) : 0;
        }
        this.maxCalculatedIndex = 0;
        this.refRateMap = new Map<String, Decimal>();
    }

    public List<ContractIndexWrapper> calculateContractIndex(Boolean displayContractIndex) {
        // Decimal previousTO = 0;
        Map<String, schema.SObjectField> contractFieldsMap = SObjectType.Contract__c.fields.getMap();
        List<ContractIndexWrapper> wContractIndexList = new List<ContractIndexWrapper>();
        if (this.conditions == null || this.conditions.isEmpty()) {
            Decimal baseIndex = getContractBaseIndex();
            for (Integer i = 1; i < 8 ; i++) {
                Integer scale = 2;
                String indexName = contractFieldsMap.get(NegoptimHelper.normalizeAPIName('Index' + i + '__c')).getDescribe().getLabel();
                ContractIndexWrapper wContractIndex = new ContractIndexWrapper(indexName);
                wContractIndex.contractId = this.contract.Id;
                wContractIndex.indexName = 'Index' + i;
                // Assign ref rate of refContract to 0
                //wContractIndex.refRate = 0;
                wContractIndex.refRate = this.refRateMap.containsKey(wContractIndex.indexName) ? this.refRateMap.get(wContractIndex.indexName) : 0;
                wContractIndex.Index = baseIndex;
                wContractIndex.IndexV2 = baseIndex;
                this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '__c'), baseIndex);
                this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_perc__c'), 0);
                wContractIndex.IndexPerc = 0;
                if (i > this.maxCalculatedIndex) {
                    wContractIndex.TO = (this.totalTo ).setScale(0);
                    wContractIndex.Computed = 0;
                } else {
                    if (i == 1) {
                        wContractIndex.TO = totalTo;
                        wContractIndex.Computed =  0;
                    }
                }
                wContractIndexList.add(wContractIndex);
            }
            return wContractIndexList;
        }
		List<Integer> availableIndexes = new List<Integer>();
        for (Schema.PicklistEntry item : Pol_Com_Condition__c.Index__c.getDescribe().getPicklistValues()) {
            if (item.isActive()) {
                availableIndexes.add(Integer.valueOf(item.getValue().right(1)));
            }
        }
        // sort conditions by Display order
        this.conditions = sort(conditions, true, true);
        Map<Integer, Map<Integer, ConditionWrapper>> conditionRanksMap = new Map<Integer, Map<Integer, ConditionWrapper>>();
        Map<String, List<ConditionWrapper>> conditionIndexesMap = new Map<String, List<ConditionWrapper>>();
        Map<String, Decimal> percentTotalsMap = new  Map<String, Decimal>();
		Map<String, Decimal> rankFixedAmountMap = new  Map<String, Decimal>();
        Map<Integer, Decimal> rankRespectScopePercentTotals = new Map<Integer, Decimal>();
        Map<Integer, List<String>> rankIndexMap = new Map<Integer, List<String>>();
        List<Integer> ranksList = new List<Integer>();
        Integer counter = 100;
        for (Contract_Discount__c item : this.conditions) {
            // reset conditions indexes
            item.Index_perc__c = null;
            item.YTD_Nego_Computed__c = null;
            item.Index_val__c = null;
            if (item.Is_Tariff_Condition__c) {
				item.Base_TO_Tariff_Nego__c = null;
            }
            if (item.Is_Excluded_To_NegoBase__c == true
                || (item.isSet(SObjectType.Contract_Discount__c.fields.Status__c.Name) && item.Status__c == 'Deleted')
                || (item.Id == null
                    && (item.Value_Per__c == null || item.Value_Per__c == 0)
                    && (item.Value_amt__c == null || item.Value_amt__c == 0)
                    && (item.Unit_Amount__c == null || item.Unit_Amount__c == 0 || item.Unit_Amount_Type__c == null || item.Unit_Amount_Type__c == '')))
            {
                continue;
            }
            // fill condition wrapper
            ConditionWrapper wCondition = new ConditionWrapper(this.contract, item, this.totalTO);
            if (wCondition.index == null || wCondition.Rank == null) {
                continue;
            }
            if (wCondition.isRespectsContractScope && wCondition.condition.ContractSellIn__c == NULL) {
                item.Base_TO_Nego__c = this.totalTo;
                item.Base_Quantity_Nego__c = this.totalQty;
                wCondition.baseToNego = this.totalTo;
            }
            Integer rank = wCondition.Rank;
            rankRespectScopePercentTotals.put(rank, 0);
            Integer order = item.Display_Order__c != null ? Integer.valueOf(item.Display_Order__c) : counter;
            counter++;
            if (!ranksList.contains(rank)) {
				ranksList.add(rank);
            }
            if (!conditionRanksMap.containsKey(rank)) {
				conditionRanksMap.put(rank, new Map<Integer, ConditionWrapper>());
            }
            conditionRanksMap.get(rank).put(order, wCondition);
            if (!conditionIndexesMap.containsKey(wCondition.index)) {
				conditionIndexesMap.put(wCondition.index, new List<ConditionWrapper>());
            }
            conditionIndexesMap.get(wCondition.index).add(wCondition);
            if (!percentTotalsMap.containsKey(rank + '' + wCondition.index)) {
				percentTotalsMap.put(rank + '' + wCondition.index, 0);
			}
			if (!rankFixedAmountMap.containsKey(rank + '' + wCondition.index)) {
                rankFixedAmountMap.put(rank + '' + wCondition.index, 0);
            }
            if ((item.Is_Tariff_Condition__c == true || (wCondition.index != null && wCondition.index == 'Index1')) && wCondition.baseToNego == this.totalTo) {
                Decimal percent = (item.Value_Per__c != null ? item.Value_Per__c / 100 : 0);
                if (percentTotalsMap.containsKey(rank + '' + wCondition.index)) {
                    percent += percentTotalsMap.get(rank + '' + wCondition.index);
                }
                percentTotalsMap.put(rank + '' + wCondition.index, percent);
				//Decimal fixedAmount = wCondition.fixedAmount;
                Decimal fixedAmount = rankFixedAmountMap.containskey(rank + '' + wCondition.index) ? rankFixedAmountMap.get(rank + '' + wCondition.index) : 0;
                rankFixedAmountMap.put(rank + '' + wCondition.index, fixedAmount + wCondition.fixedAmount);
            }
            if (wCondition.baseToNego == this.totalTo) {
                Decimal oldValue = rankRespectScopePercentTotals.get(rank);
                rankRespectScopePercentTotals.put(rank, oldValue + (item.Value_Per__c != null ? item.Value_Per__c / 100 : 0));
            }
            if (!rankIndexMap.containsKey(rank)) rankIndexMap.put(rank, new List<String>());
            rankIndexMap.get(rank).add(wCondition.index);
        }
        ranksList.sort();
        Map<Integer, Decimal> computedRanksTotalsMap = new Map<Integer, Decimal>(); // Ranks ==> [0] computed for last ranks totals, [1] computed rank total
        Map<Integer, Decimal> notRespectComputedRanksTotalsMap = new Map<Integer, Decimal>(); // Ranks ==> [0] computed for last ranks totals, [1] computed rank total
        Map<Integer, Decimal> rankToAfterContractMap = new Map<Integer, Decimal>(); // Ranks ==> [0] to After contract for last ranks totals
        List<Integer> orderSortList = new List<Integer>();
        // calculate computed(YTD_Nego_Computed__c)
        // reset contract index
        for (Integer i = 1; i <= 7; i++) {
            if (!availableIndexes.contains(i)) {
                continue;
            }
            this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_perc__c'), 0);
            this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '__c'), 0);
        }
        //Decimal computedTotal = 0, percent = 0, computedRanks = 0;
        Decimal percent = 0;
        Decimal totalTOTarifNego = this.totalTO;
        Decimal total_PercentPreviousRespectScope = 0;
        Decimal percentTotal = 0, baseIndex = getContractBaseIndex();
        // List<ContractIndexWrapper> wContractIndexList = new List<ContractIndexWrapper>();
        wContractIndexList = new List<ContractIndexWrapper>();

        // Map<String, schema.SObjectField> contractFieldsMap = SObjectType.Contract__c.fields.getMap();
        Integer oldRank = 0;
        Decimal lastCondBaseIndex = baseIndex;
        Decimal condBaseIndex = baseIndex;
        Decimal previousTO = 0;
        Decimal rankPercentTotal = 0;
        for (Integer i = ranksList.size() - 1; i >= 0; i--) {
            //computedRanks = 0;
            Integer rank = ranksList[i];
            if (!computedRanksTotalsMap.containsKey(rank)) {
                computedRanksTotalsMap.put(rank, 0);
            }
            if (!notRespectComputedRanksTotalsMap.containsKey(rank)) {
                notRespectComputedRanksTotalsMap.put(rank, 0);
            }
            if (!rankToAfterContractMap.containsKey(rank)) {
                rankToAfterContractMap.put(rank, 0);
            }
            Map<Integer, ConditionWrapper> conditionsMap = conditionRanksMap.get(rank);
            orderSortList = new List<Integer>();
            for (Integer order : conditionsMap.keySet()) {
                if (orderSortList.size() == 0) {
                    orderSortList.add(order);
                } else {
                    orderSortList.add(0, order);
                }
            }
			// get computed for not respect conditions
            for (Integer order : orderSortList) {
                ConditionWrapper item = conditionsMap.get(order);
                if ((item.condition.Is_Tariff_Condition__c || item.index == 'Index1') && (item.baseToNego != this.totalTo /*&& item.isOnlyPercentCondition*/)) {
                    Decimal percentTotalForRespectScope = percentTotalsMap.get(rank + '' + item.index);
                    total_PercentPreviousRespectScope = rankRespectScopePercentTotals.get(rank);
                    Decimal devidedPercent;
                    Decimal totalCalcPercent;
                    for (Integer nextRank : ranksList) {
                        if (nextRank > rank && rankIndexMap.get(nextRank).contains('Index1')) {
                            Map<Integer, ConditionWrapper> previousConditionsMap = conditionRanksMap.get(nextRank);
                            totalCalcPercent = 0;
                            devidedPercent = null;
                            for (Integer rKey : previousConditionsMap.keyset()) {
                                if (previousConditionsMap.get(rKey).baseToNego == this.totalTo && previousConditionsMap.get(rKey).index == 'Index1') {
                                    totalCalcPercent = totalCalcPercent == null ? previousConditionsMap.get(rKey).recalc / 100 : totalCalcPercent + previousConditionsMap.get(rKey).recalc / 100;
                                }
                            }
                            devidedPercent = devidedPercent == null ? (1 - totalCalcPercent) : devidedPercent / (1 - totalCalcPercent) ;
                        }
                    }
                    devidedPercent = devidedPercent == null ? 1 : devidedPercent;
                    percent = (item.condition.Value_Per__c != null ? item.condition.Value_Per__c / 100 : 0);
                    Decimal baseTo = 0;
                    if(this.totalTo != 0) {
                        baseTo = item.baseToNego + (rankFixedAmountMap.containsKey(rank + '' + item.index) ? (rankFixedAmountMap.get(rank + '' + item.index) * item.baseToNego / this.totalTo) : 0);
                    }
                    Decimal value1 = devidedPercent != 0 ? (baseTo * percent) / devidedPercent : (baseTo * percent);
                    item.computedValue = item.fixedAmount + (1 - percent - percentTotalForRespectScope) != 0 ? (value1 / (1 - percent - percentTotalForRespectScope)): 0;
                    notRespectComputedRanksTotalsMap.put(rank, notRespectComputedRanksTotalsMap.get(rank) + item.computedValue);
                }
            }
            //Decimal purcentCumul = 0;
            for (Integer order : orderSortList) {
                ConditionWrapper item = conditionsMap.get(order);
                item.condition.Base_TO_Tariff_Nego__c = null;
                percent = (item.condition.Value_Per__c != null ? item.condition.Value_Per__c / 100 : 0);
                item.percent = percent;
                if (item.condition.Is_Tariff_Condition__c || item.index == 'Index1') {
                    Decimal percentTotalForRespectScope = percentTotalsMap.get(ranksList[i] + '' + item.index);
                    if (item.baseToNego == this.totalTo /*&& item.isOnlyPercentCondition*/) {
                        Decimal value = 0;
                        for (Integer nextRank : computedRanksTotalsMap.keySet()) {
                            if (nextRank > rank) {
                                value += (computedRanksTotalsMap.containsKey(nextRank) ? computedRanksTotalsMap.get(nextRank) : 0);
                            }
                        }
                        value += notRespectComputedRanksTotalsMap.containsKey(rank) ? notRespectComputedRanksTotalsMap.get(rank) : 0;
                        value += rankFixedAmountMap.get(ranksList[i] + '' + item.index);
                        item.computedValue = item.fixedAmount + ((1 - percentTotalForRespectScope) != 0 ? (item.baseToNego + value) * (percent / (1 - percentTotalForRespectScope)) : 0);
                        //total_PercentPreviousRespectScope += percent;
                    } else {
                        /*if (item.isOnlyPercentCondition) {
                            item.computedValue = (1 - percent - percentTotalForRespectScope - total_PercentPreviousRespectScope) != 0 ? item.baseToNego * (percent / (1 - percent - percentTotalForRespectScope - total_PercentPreviousRespectScope)) : 0;
                        } else {
                            item.computedValue = item.condition.YTD_Nego__c != null ? item.condition.YTD_Nego__c : 0;
                        }
                        notRespectComputedRanksTotalsMap.put(rank, notRespectComputedRanksTotalsMap.get(rank) + item.computedValue);*/
                    }
                    computedRanksTotalsMap.put(rank, computedRanksTotalsMap.get(rank) + item.computedValue);
                    totalTOTarifNego += item.computedValue;
                    item.toAfterContract = totalTOTarifNego;
                    rankToAfterContractMap.put(rank, item.toAfterContract);
                    if (item.isOnlyPercentCondition) {
                        item.condition.Base_TO_Tariff_Nego__c = percent != 0 ? (item.computedValue / percent) : 0;
                    } else {
                        item.condition.Base_TO_Tariff_Nego__c = item.toAfterContract;
                    }
                } else {
                    if (item.isOnlyPercentCondition) {
                        item.computedValue = item.baseToNego * percent;
                    } else {
                        // item.computedValue = item.condition.YTD_Nego__c != null ? item.condition.YTD_Nego__c : 0;
                        item.computedValue = item.ytdNego; //item.condition.YTD_Nego__c != null ? item.condition.YTD_Nego__c : 0;
                    }
                    item.recalc = this.totalTO != null && this.totalTO != 0 ? ((item.computedValue / this.totalTO) * 100) : 0;
                    item.condition.Base_TO_Tariff_Nego__c = this.totalTo;
                }
                // get max index calculated
                Integer index = Integer.valueOf(item.index.replace('Index', ''));
                if (this.maxCalculatedIndex < index) {
                    this.maxCalculatedIndex = index;
                }
            }
            // calculate Recalc(Index_perc__c)/Index_val__c
            for (String index : rankIndexMap.get(rank) ) {
                Integer j = Integer.valueOf(index.replace('Index', ''));
                if (!availableIndexes.contains(j)) {
                    continue;
                }
                if (conditionIndexesMap.containsKey('Index' + j)) {
                    for (ConditionWrapper item : conditionIndexesMap.get('Index' + j)) {
                        if (item.rank != rank) {
                            continue;
                        }
                        if (item.condition.Is_Tariff_Condition__c || item.Index == 'Index1') {
                            item.recalc = rankToAfterContractMap.get(rank) != 0 ? (item.computedValue / rankToAfterContractMap.get(rank)) * 100 : 0;
                            item.condition.YTD_Nego_Computed__c = item.computedValue;
                        } else {
                            item.recalc = this.totalTO != null && this.totalTO != 0 ? ((item.computedValue / this.totalTO) * 100) : 0;
                            item.condition.YTD_Nego_Computed__c = item.computedValue;
                        }
                    }
                }
            }
        }
        Decimal perc1Cumul = 0;
        for (Integer i = 1; i <= 7; i++) {
			if (!availableIndexes.contains(i)) {
                continue;
            }
            if (i > this.maxCalculatedIndex) {
                this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '__c'), (baseIndex * (1 - percentTotal)));
            } else {
                Decimal indexPercentTotal = 0;
                Decimal excludedIndexPercentTotal = 0;
                if (conditionIndexesMap.containsKey('Index' + i)) {
                    for (ConditionWrapper item : conditionIndexesMap.get('Index' + i)) {
                        indexPercentTotal += item.recalc;
                        item.condition.Index_perc__c = item.recalc;
                        if (oldRank != 0 && item.rank != oldRank) {
                            if (item.baseToNego == this.totalTo && item.isOnlyPercentCondition) {
                                rankPercentTotal = Item.percent != null && Item.percent != 0  ? Item.percent : (item.condition.Index_perc__c / 100);
                            } else {
                                rankPercentTotal = item.condition.Index_perc__c / 100;
                                item.condition.Base_TO_Tariff_Nego__c = item.condition.Index_perc__c != 0 ? (item.computedValue / (item.condition.Index_perc__c / 100)) : 0;
                            }
                            condBaseIndex = lastCondBaseIndex;
                        } else {
                            if (item.baseToNego == this.totalTo && item.isOnlyPercentCondition) {
                                rankPercentTotal += Item.percent != null && Item.percent != 0  ? Item.percent : item.condition.Index_perc__c / 100;
                            } else {
                                rankPercentTotal += item.condition.Index_perc__c / 100;
                                item.condition.Base_TO_Tariff_Nego__c = item.condition.Index_perc__c != 0 ? (item.computedValue / (item.condition.Index_perc__c / 100)) : 0;
                            }
                            //rankPercentTotal += Item.percent != null && Item.percent != 0 ? Item.percent : item.condition.Index_perc__c / 100;
                        }
                        item.condition.Index_val__c = (condBaseIndex * (1 - rankPercentTotal));
                        lastCondBaseIndex = item.condition.Index_val__c;
                        oldRank = item.rank;
                    }
                }
                // get last indexPercentTotal <> 0 When the indexPercentTotal(i) = 0
                if (i == 1) {
                    indexPercentTotal = totalTOTarifNego != null && totalTOTarifNego != 0 ? ((totalTOTarifNego - this.totalTO) / totalTOTarifNego) * 100 : 0;
                    this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_perc__c'), indexPercentTotal);
                    this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '__c'), (baseIndex * (1 - (indexPercentTotal / 100))));
                    baseIndex = (baseIndex * (1 - (indexPercentTotal / 100)));
                } else {
                    percentTotal += indexPercentTotal / 100;
                    this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_perc__c'), indexPercentTotal);
                    perc1Cumul += indexPercentTotal;
                    this.contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '__c'), (baseIndex * (1 - perc1Cumul / 100)));
                }
            }
            if (displayContractIndex) {
                ContractIndexWrapper wConractIndex = populateContractIndexWrapper(i, this.contract, contractFieldsMap, conditionIndexesMap, previousTO);
                wContractIndexList.add(wConractIndex);
                if (wConractIndex.indexPerc == 0) {
                    if (i == 1) {
                        wConractIndex.TO = this.totalTO;
                    } else {
                        wConractIndex.TO = previousTO;
                    }
                    wConractIndex.Computed = 0;
                }
                previousTO = wConractIndex != null && wConractIndex.TO != null ? wConractIndex.TO : 0;
            }
        }
        this.contract.Total_TO_Tariff_Nego__c = totalTOTarifNego != null ? totalTOTarifNego.setScale(2) : 0;
        if (contract.IsCalculatedIndexV2__c) {
            calculateContractIndexV2(displayContractIndex, wContractIndexList, contract, conditions);
        }
        for (integer i = 1; i < 8; i++) {
            string indexFieldName = NegoptimHelper.normalizeAPIName('Index' + i + '__c');
            string indexV2FieldName = NegoptimHelper.normalizeAPIName('Index' + i + '_v2__c');
            string indexPercFieldName = NegoptimHelper.normalizeAPIName('Index' + i + '_perc__c');
            string indexV2PercFieldName = NegoptimHelper.normalizeAPIName('Index' + i + '_v2_perc__c'); //Index4_v2_perc__c
            decimal index = (decimal)contract.get(indexFieldName);
            index = index >= 1000 ? 999.99 : (index <= -1000 ? -999.99 : index);
            contract.put(indexFieldName, index);
            decimal indexV2 = (decimal)contract.get(indexV2FieldName);
            indexV2 = indexV2 >= 1000 ? 999.99 : (indexV2 <= -1000 ? -999.99 : indexV2);
            contract.put(indexV2FieldName, indexV2);
            decimal indexPercent = (decimal)contract.get(indexPercFieldName);
            indexPercent = indexPercent >= 1000 ? 999.99 : (indexPercent <= -1000 ? -999.99 : indexPercent);
            contract.put(indexPercFieldName, indexPercent);
            decimal indexPercentV2 = (decimal)contract.get(indexV2PercFieldName);
            indexPercentV2 = indexPercentV2 >= 1000 ? 999.99 : (indexPercentV2 <= -1000 ? -999.99 : indexPercentV2);
            contract.put(indexV2PercFieldName, indexPercentV2);
        }
        for (Contract_Discount__c disc : conditions)  {
            disc.Index_perc__c = disc.Index_perc__c >= 1000 ? 999.99 : (disc.Index_perc__c <= -1000 ? -999.99 : disc.Index_perc__c);    
            disc.Index_Val__c = disc.Index_Val__c >= 1000 ? 999.99 : (disc.Index_Val__c <= -1000 ? -999.99 : disc.Index_Val__c);    
        }
        
        return wContractIndexList;
    }
    private void calculateContractIndexV2(Boolean displayContractIndex, List<ContractIndexWrapper> wContractIndexList, Contract__c contract, List<Contract_Discount__c> discounts) {
        Map<String, List<Contract_Discount__c>> indexDiscountMap = new Map<String, List<Contract_Discount__c>>();
        Map<String, Decimal> indexV2Values = new Map<String, Decimal>{
            'Index1' => 0,
            'Index2' => 0,
            'Index3' => 0,
            'Index4' => 0,
            'Index5' => 0,
            'Index6' => 0,
            'Index7' => 0
        };
        Boolean index1Calculated = false;
        for (Contract_Discount__c discount : discounts) {
            String indexv2 = (discount.Is_Tariff_Condition__c ? 'Index1' : (String.isNotBlank(discount.index_v2__c) ? discount.index_v2__c : 
                                                                            (discount.index__c != null ? discount.index__c : discount.Condition_Type__r.Index__c)));
            if(indexv2 == 'Index1') {
                if(index1Calculated) continue;
                // ((totalTOTarifNego - this.totalTO) / totalTOTarifNego) * 100 : 0;
                indexV2Values.put(indexv2, (discount.Base_TO_Tariff_Nego__c != null ? ((discount.Base_TO_Tariff_Nego__c - this.totalTO) / discount.Base_TO_Tariff_Nego__c ) * 100 : 0));
                index1Calculated = true;
            } else {
                String index = discount.Is_Tariff_Condition__c ? 'Index1' : discount.index__c;
                if(indexv2 != null) {
                    Decimal oldValue = indexV2Values.get(indexv2);
                    Decimal newValue = discount.Index_perc__c != null ? discount.Index_perc__c : 0;
                    indexV2Values.put(indexv2, oldValue + newValue);
                }
            }
        }
		List<Integer> availableIndexes = new List<Integer>();
        for (Schema.PicklistEntry item : Pol_Com_Condition__c.Index__c.getDescribe().getPicklistValues()) {
            if (item.isActive()) {
                availableIndexes.add(Integer.valueOf(item.getValue().right(1)));
            }
        }
        Decimal baseIndex = getContractBaseIndex(contract);
        Decimal indexPercentTotal = 0;
        Decimal percCumul = 0;
        for (Integer i : availableIndexes) {
            indexPercentTotal = indexV2Values.get('Index' + i);
            if (i == 1) {
                contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_v2_perc__c'), indexPercentTotal);
                contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_v2__c'), (baseIndex * (1 - (indexPercentTotal / 100))));
                baseIndex = (baseIndex * (1 - (indexPercentTotal / 100)));
            } else {
                contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_v2_perc__c'), indexPercentTotal);
                percCumul += indexPercentTotal;
                contract.put(NegoptimHelper.normalizeAPIName('Index' + i + '_v2__c'), (baseIndex * (1 - percCumul / 100)));
            }
        }
        if (displayContractIndex) {
            wContractIndexList.get(0).indexV2Perc = contract.Index1_v2_perc__c;
            wContractIndexList.get(1).indexV2Perc = contract.Index2_v2_perc__c;
            wContractIndexList.get(2).indexV2Perc = contract.Index3_v2_perc__c;
            wContractIndexList.get(3).indexV2Perc = contract.Index4_v2_perc__c;
            wContractIndexList.get(4).indexV2Perc = contract.Index5_v2_perc__c;
            wContractIndexList.get(5).indexV2Perc = contract.Index6_v2_perc__c;
            wContractIndexList.get(6).indexV2Perc = contract.Index7_v2_perc__c;
            wContractIndexList.get(0).IndexV2 = contract.Index1_v2__c;
            wContractIndexList.get(1).IndexV2 = contract.Index2_v2__c;
            wContractIndexList.get(2).IndexV2 = contract.Index3_v2__c;
            wContractIndexList.get(3).IndexV2 = contract.Index4_v2__c;
            wContractIndexList.get(4).IndexV2 = contract.Index5_v2__c;
            wContractIndexList.get(5).IndexV2 = contract.Index6_v2__c;
            wContractIndexList.get(6).IndexV2 = contract.Index7_v2__c;
        }
    }
    public void setRefRateMap (Map<String, Decimal> refRateMap) {
        this.refRateMap = refRateMap;
    }

    private ContractIndexWrapper populateContractIndexWrapper(Integer indexNumber, Contract__c contract, Map<String, schema.SObjectField> contractFieldsMap, Map<String, List<ConditionWrapper>> conditionIndexesMap, Decimal previousTO) {
        try {
            Integer scale = 2;
            String indexName = contractFieldsMap.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')).getDescribe().getLabel();
            ContractIndexWrapper wContractIndex = new ContractIndexWrapper(indexName);
            wContractIndex.indexName = 'Index' + indexNumber;
            // Assign ref rate of refContract to 0
            //wContractIndex.refRate = 0;
            wContractIndex.refRate = this.refRateMap.containsKey(wContractIndex.indexName) ? this.refRateMap.get(wContractIndex.indexName) : 0;
            wContractIndex.Index = this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')) != null ? (Decimal)this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '__c')) : 0;
            wContractIndex.IndexPerc = this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_perc__c')) != null ? (Decimal)this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_perc__c')) : 0;
            wContractIndex.IndexV2 = this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2__c')) != null ? (Decimal)this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2__c')) : 0;
            wContractIndex.indexV2Perc = this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2_perc__c')) != null ? (Decimal)this.contract.get(NegoptimHelper.normalizeAPIName('Index' + indexNumber + '_v2_perc__c')) : 0;
            if (indexNumber > this.maxCalculatedIndex) {
                wContractIndex.TO = (totalTo * (1 - wContractIndex.IndexPerc / 100)).setScale(0);
                wContractIndex.Computed = 0;
                wContractIndex.TO = PreviousTO;
            } else {
                if (indexNumber == 1) {
                    wContractIndex.TO = totalTo;
                    wContractIndex.Computed =  ((1 - wContractIndex.IndexPerc / 100) != 0 ? (totalTo / (1 - wContractIndex.IndexPerc / 100)) : 0) - totalTo;
                }
                Decimal computed = 0;
                if (conditionIndexesMap.get(wContractIndex.indexName) != null) {
                    for (ConditionWrapper discount : conditionIndexesMap.get(wContractIndex.indexName)) {
                        computed += (discount.condition.YTD_Nego_Computed__c != null ? discount.condition.YTD_Nego_Computed__c : 0).setScale(0);
                    }
                    wContractIndex.Computed = computed != null ? computed : 0;
                    if (indexNumber != 1 && wContractIndex != null) {
                        if (wContractIndex.index != 0) {
                            wContractIndex.TO = (PreviousTO != null ? PreviousTO : 0) - (wContractIndex.Computed != null ? wContractIndex.Computed : 0);
                        }
                    }
                }
            }
            return wContractIndex;
        } catch (Exception ex) {
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage() + ' - ' + ex.getLineNumber()));
            }
            System.debug('ERRORS >>>> ' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        return null;
    }

    public Decimal getContractBaseIndex() {
        return getContractBaseIndex(this.contract);
    }
    public static Decimal getContractBaseIndex(Contract__c contract) {
        Decimal index0 = 100;
        index0 -= contract.Depreciation_Rate_YE__c != null ? index0 * contract.Depreciation_Rate_YE__c / 100 : 0;
        index0 += contract.Markdown_Rate_Break__c != null ? contract.Markdown_Rate_Break__c : 0;
        index0 += contract.Markdown_Rate_Promo__c != null ? contract.Markdown_Rate_Promo__c : 0;
        index0 += contract.Markdown_Rate_Theft__c != null ? contract.Markdown_Rate_Theft__c : 0;
        index0 += contract.Rise_Rate_YE__c != null ? index0 * contract.Rise_Rate_YE__c / 100 : 0;
        return index0.setScale(2);
    }

    // sort list Contract_Discount__c with option to setting Display_Order__c
    public static List<Contract_Discount__c> sort(List<Contract_Discount__c> contractDiscountList, Boolean isAsc, Boolean setOrder) {
        Map<String, Id> discountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
        Map<Id, List<Contract_Discount__c>> contractDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
        for (Contract_Discount__c item : contractDiscountList) {
            if (!contractDiscountsMap.containsKey(item.Contract__c)) {
                contractDiscountsMap.put(item.Contract__c, new List<Contract_Discount__c>());
            }
            contractDiscountsMap.get(item.Contract__c).add(item);
        }
        Map<String, Integer> negoDiscountTypeSortMap = new Map<String, Integer>();
        Integer index = 0;
        for (Schema.PicklistEntry item : Contract_Discount__c.Nego_Discount_Type__c.getDescribe().getPicklistValues()) {
            negoDiscountTypeSortMap.put(item.getValue(), index++);
        }
        List<Contract_Discount__c> finalContractDiscountList = new List<Contract_Discount__c>();
        for (List<Contract_Discount__c> conditionsListForContract : contractDiscountsMap.values()) {
            List<ConditionSortWrapper> wrapperList = new List<ConditionSortWrapper>();
            for (Contract_Discount__c item : conditionsListForContract) {
                wrapperList.add(new ConditionSortWrapper(item, isAsc ? 1 : -1, discountRTIds, negoDiscountTypeSortMap));
            }
            wrapperList.sort();
            Integer countParent = 1, countSub = 100;
            for (ConditionSortWrapper item : wrapperList) {
                if (setOrder != null && setOrder) {
                    Boolean isFilled = false;
                    Boolean isSlabs = false;
                    isFilled |= item.discount.isSet(SObjectType.Contract_Discount__c.fields.Value_amt__c.Name) && item.discount.Value_amt__c != null && item.discount.Value_amt__c != 0;
                    isFilled |= item.discount.isSet(SObjectType.Contract_Discount__c.fields.Value_Per__c.Name) && item.discount.Value_Per__c != null && item.discount.Value_Per__c != 0;
                    isFilled |= item.discount.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name) && item.discount.Unit_Amount_Type__c != null && item.discount.Unit_Amount_Type__c != '' && item.discount.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount__c.Name) && item.discount.Unit_Amount__c != null && item.discount.Unit_Amount__c != 0;
                    isFilled |= item.discount.condition_Type__r.Capture_Discount_Product_Level__c != null;
                    // isFilled |= item.discount.condition_Type__r.isSet(SObjectType.Pol_Com_Condition__c.fields.Capture_Discount_Product_Level__c.Name) && item.discount.condition_Type__r.Capture_Discount_Product_Level__c != null;
                    // if (item.discount.Parent_Discount__c != null) {
                    //     item.discount.Display_Order__c = countSub++;
                    // }
                    isSlabs = (item.discount.is_conditional__c
                               && ((item.discount.Slab_1__c != null && item.discount.Slab_1__c != 0)
                                   || (item.discount.Slab_2__c == null && item.discount.Slab_2__c == 0)
                                   || (item.discount.Slab_3__c == null && item.discount.Slab_3__c == 0)
                                   || (item.discount.Slab_4__c == null && item.discount.Slab_4__c == 0)
                                   || (item.discount.Slab_5__c == null && item.discount.Slab_5__c == 0)
                                   || (item.discount.Slab_6__c == null && item.discount.Slab_6__c == 0)
                                   || (item.discount.Slab_7__c == null && item.discount.Slab_7__c == 0)
                                   || (item.discount.Slab_8__c == null && item.discount.Slab_8__c == 0)
                                   || (item.discount.Slab_9__c == null && item.discount.Slab_9__c == 0)
                                   || (item.discount.Slab_10__c == null && item.discount.Slab_10__c == 0)
                                   || (item.discount.slab_per_1__c == null && item.discount.slab_per_1__c == 0)
                                   || (item.discount.slab_per_2__c == null && item.discount.slab_per_2__c == 0)
                                   || (item.discount.slab_per_3__c == null && item.discount.slab_per_3__c == 0)
                                   || (item.discount.slab_per_4__c == null && item.discount.slab_per_4__c == 0)
                                   || (item.discount.slab_per_5__c == null && item.discount.slab_per_5__c == 0)
                                   || (item.discount.slab_per_6__c == null && item.discount.slab_per_6__c == 0)
                                   || (item.discount.slab_per_7__c == null && item.discount.slab_per_7__c == 0)
                                   || (item.discount.slab_per_8__c == null && item.discount.slab_per_8__c == 0)
                                   || (item.discount.slab_per_9__c == null && item.discount.slab_per_9__c == 0)
                                   || (item.discount.slab_per_10__c == null && item.discount.slab_per_10__c == 0)
                                   || (item.discount.Slab_Val_1__c == null && item.discount.Slab_Val_1__c == 0)
                                   || (item.discount.Slab_Val_2__c == null && item.discount.Slab_Val_2__c == 0)
                                   || (item.discount.Slab_Val_3__c == null && item.discount.Slab_Val_3__c == 0)
                                   || (item.discount.Slab_Val_4__c == null && item.discount.Slab_Val_4__c == 0)
                                   || (item.discount.Slab_Val_5__c == null && item.discount.Slab_Val_5__c == 0)
                                   || (item.discount.Slab_Val_6__c == null && item.discount.Slab_Val_6__c == 0)
                                   || (item.discount.Slab_Val_7__c == null && item.discount.Slab_Val_7__c == 0)
                                   || (item.discount.Slab_Val_8__c == null && item.discount.Slab_Val_8__c == 0)
                                   || (item.discount.Slab_Val_9__c == null && item.discount.Slab_Val_9__c == 0)
                                   || (item.discount.Slab_Val_10__c == null && item.discount.Slab_Val_10__c == 0)));
                    if (item.discount.RecordTypeId == item.discountRTIds.get('Sub_Term_Signed') || item.discount.RecordTypeId == item.discountRTIds.get('Sub_Term_To_Be_Signed')) {
                        item.discount.Display_Order__c = countSub++;
                    } else if (isFilled || isSlabs) {
                        item.discount.Display_Order__c = countParent++;
                    } else {
                        item.discount.Display_Order__c = null;
                    }
                }
                finalContractDiscountList.add(item.discount);
            }
        }
        return finalContractDiscountList;
    }

	// sort list Contract_Discount__c without setting Display_Order__c
	public static List<Contract_Discount__c> sort (List<Contract_Discount__c> contractDiscountList, Boolean isAsc) {
		return sort (contractDiscountList, isAsc, false);
	}
    // build Tariff condition query
    public static String buildQueryTariffCondition(Contract__c contract, String conditionType, String index, Set<Id> condIds) {
        return buildQueryTariffCondition(contract, conditionType, index);
    }
    // build Tariff condition query
    public static String buildQueryTariffCondition(Contract__c contract, String conditionType, String index) {
        // Check fields security
        List<String> tarrifConditionFields = new List<String> {
            SObjectType.Pol_Com_Condition__c.fields.Id.Name,
            SObjectType.Pol_Com_Condition__c.fields.Name.Name,
            SObjectType.Pol_Com_Condition__c.fields.Nego_Discount_Type__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Condition_Mode__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Index__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Is_Conditional__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Definition__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Long_Name__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Comment__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Is_Index_Target__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Used_as_SubCondition_only__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Brand_Type__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut1__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut2__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Segmentation_attribut3__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Supply_flow__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Is_Folding_Discount__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.InvoicePlanning__c.Name,
            SObjectType.Pol_Com_Condition__c.fields.Is_International_Discount__c.Name
        };
        List<String> planningFields = new List<String> {
            SObjectType.InvoicePlanning__c.fields.Id.Name,
            SObjectType.InvoicePlanning__c.fields.SeriesPeriodP__c.Name,
            SObjectType.InvoicePlanning__c.fields.SeriesPeriodU__c.Name,
            SObjectType.InvoicePlanning__c.fields.SeriesPeriodF__c.Name,
            SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageP__c.Name,
            SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageU__c.Name,
            SObjectType.InvoicePlanning__c.fields.DownPaymentYECoverageF__c.Name
        };
        String query = '';
        if (NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionFields)
            && NegoptimHelper.checkAccessibility(InvoicePlanning__c.SObjectType, planningFields))
        {
            query = 'SELECT RecordType.DeveloperName, BusinessUnitMaster__r.Name,';
            query += ' InvoicePlanning__r.' + String.join(staticInvoicePlanningFields, ', InvoicePlanning__r.') + ',';
            query += ' InvoicePlanningPE__r.' + String.join(staticInvoicePlanningFields, ', InvoicePlanningPE__r.') + ',';
            query += ' ' + String.join(ContractServices.staticPolComConditionFields, ',');
            query += ' FROM Pol_Com_Condition__c';
            List<String> conditions = buildQueryTariffConditions(null, contract, contract.Supplier_Nego_Scope__r, conditionType, index);
            if (conditions != null && !conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            query += ' ORDER BY Display_Order__c, Name';
            System.debug('buildQueryTariffCondition >>> ' + query);
        }
        return query;
    }
    
    public static List<String> buildQueryTariffConditions(String searchString, Contract__c contract, NegoScope__c ns, String conditionType, String index) {
        String[] buLinkFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name,
            SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name
        };
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        // Main Conditions
        conditions.add('Nego_Discount_Type__c <> NULL');
        conditions.add('Used_as_SubCondition_only__c = FALSE');
        if (conditionType != null) {
            conditions.add('Nego_Discount_Type__c = \'' + String.escapeSingleQuotes(conditionType) + '\'');
        }
        if (index != null) {
            conditions.add('Index__c = \'' + String.escapeSingleQuotes(index) + '\'');
        }
        // Conditions related to NS
        if (ns != null) {
            if (ns.BrandType__c != null) {
                conditions.add('(Brand_Type__c = NULL OR Brand_Type__c = \'' + ns.BrandType__c + '\')');
            }
            if (ns.SupplyChainType__c != null && ns.SupplyChainType__c != 'All') {
                conditions.add('(Supply_flow__c = NULL OR Supply_flow__c = \'' + ns.SupplyChainType__c + '\')');
            }
            if (ns.SegmentationAttribut1__c != null) {
                conditions.add('(Segmentation_attribut1__c INCLUDES (\'' + String.escapeSingleQuotes(ns.SegmentationAttribut1__c) + '\') OR Segmentation_attribut1__c = NULL)');
            }
            if (ns.SegmentationAttribut2__c != null) {
                conditions.add('(Segmentation_attribut2__c INCLUDES (\'' + String.escapeSingleQuotes(ns.SegmentationAttribut2__c) + '\') OR Segmentation_attribut2__c = NULL)');
            }
            if (ns.SegmentationAttribut3__c != null) {
                conditions.add('(Segmentation_attribut3__c = \'' + String.escapeSingleQuotes(ns.SegmentationAttribut3__c) + '\' OR Segmentation_attribut3__c = NULL)');
            }
        }
        // Conditions related to Contract
        if (contract != null) {
            // Date & Status Conditions
            {
                orConditions = new List<String>();
                String formatGMTBdate = ((Datetime)contract.Contract_BDate__c).formatGMT('yyyy-MM-dd');
                String formatGMTEdate = ((Datetime)contract.Contract_EDate__c).formatGMT('yyyy-MM-dd');
                orConditions.add('(Condition_Status__c  = \'Open\' AND Status_BDate__c <= ' + formatGMTEdate + ')');
                if (contract.RecordTypeId != simulationRecordTypeId && contract.RecordTypeId != signedRecordTypeId && contract.RecordTypeId != toBeSignedRecordTypeId) {
                    orConditions.add('(Condition_Status__c = \'PreClosed\' AND Status_BDate__c <= ' + formatGMTEdate + ')');
                }
                orConditions.add('(Condition_Status__c  = \'Close\' AND Status_BDate__c >= ' + formatGMTBdate + ' AND Status_BDate__c <= ' + formatGMTEdate + ')');
                orConditions.add('(Condition_Status__c  = \'Close\' AND Status_EDate__c >= ' + formatGMTBdate + ' AND Status_EDate__c <= ' + formatGMTEdate + ')');
                orConditions.add('(Condition_Status__c  = \'Close\' AND Status_BDate__c <= ' + formatGMTBdate + ' AND Status_EDate__c >= ' + formatGMTEdate + ')');
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            // Specific Contract Type Auth Conditions
            {
                orConditions = new List<String>();
                orConditions.add('Specific_Contract_Type_Authorization__c = NULL');
                if (contract.RecordTypeId == targetRecordTypeId || contract.RecordTypeId == safeBalanceRecordTypeId || contract.RecordTypeId == proposalRecordTypeId || contract.RecordTypeId == simulationRecordTypeId || contract.RecordTypeId == toBeSignedRecordTypeId) {
                    orConditions.add('Specific_Contract_Type_Authorization__c IN (\'Negotiation\',\'Negotiation + Amendment\',\'All - Amendment\')');
                }
                if (contract.RecordTypeId == signedRecordTypeId) {
                    orConditions.add('Specific_Contract_Type_Authorization__c IN (\'Amendment\',\'Negotiation + Amendment\')');
                }
                if (contract.RecordTypeId == landingRecordTypeId || contract.RecordTypeId == negoBaseInitRecordTypeId || contract.RecordTypeId == negoBaseRecordTypeId) {
                    orConditions.add('Specific_Contract_Type_Authorization__c IN (\'Negotiation\',\'Amendment\',\'Negotiation + Amendment\',\'All - Amendment\')');
                }
                if (contract.RecordTypeId == peRecordTypeId) {
                    orConditions.add('Specific_Contract_Type_Authorization__c IN (\'Period Extension\',\'All - Amendment\')');
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')'); 
            }
            // BU Source Conditions
            {
                orConditions = new List<String>();
                orConditions.add('BusinessUnitSource__c = NULL');
                if (contract.BusinessUnitSource__c != null && NegoptimHelper.checkAccessibility(BULink__c.SObjectType, buLinkFields)) {
                    Set<Id> buSourceSet = new Set<Id>();
                    buSourceSet.add(contract.BusinessUnitSource__c);
                    List<AggregateResult> buSourceBULinks = [SELECT BusinessUnitMaster__c BusinessUnitMaster__c, BusinessUnitDetail__c BusinessUnitDetail__c
                                                             FROM BULink__c
                                                             WHERE BusinessUnitMaster__c = :contract.BusinessUnitSource__c OR BusinessUnitDetail__c = :contract.BusinessUnitSource__c
                                                             GROUP BY BusinessUnitMaster__c, BusinessUnitDetail__c];
                    for (AggregateResult result : buSourceBULinks) {
                        Id buMaster = (Id) result.get('BusinessUnitMaster__c');
                        Id buDetail = (Id) result.get('BusinessUnitDetail__c');
                        buSourceSet.add(buMaster);
                        buSourceSet.add(buDetail);
                    }
                    if (buSourceSet != null && !buSourceSet.isEmpty()) {
                        orConditions.add('BusinessUnitSource__c IN (\'' + String.join(new List<Id>(buSourceSet), '\', \'') + '\')');
                    }
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            // BU Contract Conditions
            {
                orConditions = new List<String>();
                orConditions.add('BusinessUnitMaster__c = NULL');
                if (contract.BusinessUnitContract__c != null && NegoptimHelper.checkAccessibility(BULink__c.SObjectType, buLinkFields)) {
                    Set<Id> buContractSet = new Set<Id>();
                    buContractSet.add(contract.BusinessUnitContract__c);
                    List<AggregateResult> buSourceBULinks = [SELECT BusinessUnitMaster__c BusinessUnitMaster__c, BusinessUnitDetail__c BusinessUnitDetail__c
                                                             FROM BULink__c
                                                             WHERE BusinessUnitMaster__c = :contract.BusinessUnitContract__c OR BusinessUnitDetail__c = :contract.BusinessUnitContract__c
                                                             GROUP BY BusinessUnitMaster__c, BusinessUnitDetail__c];
                    for (AggregateResult result : buSourceBULinks) {
                        Id buMaster = (Id) result.get('BusinessUnitMaster__c');
                        Id buDetail = (Id) result.get('BusinessUnitDetail__c');
                        buContractSet.add(buMaster);
                        buContractSet.add(buDetail);
                    }
                    if (buContractSet != null && !buContractSet.isEmpty()) {
                        orConditions.add('BusinessUnitMaster__c IN (\'' + String.join(new List<Id>(buContractSet), '\', \'') + '\')');
                    }
                }
                conditions.add('(' + String.join(orConditions, ' OR ') + ')'); 
            }
        }
        // Profile Condition
        conditions.add('(LimitUsage_ToProfile__c = NULL OR LimitUsage_ToProfile__c INCLUDES (\'' + UserInfo.getProfileId() + '\'))');
        return conditions;
    }
    // Calculate Rise/Dep rate YE for Contract
    public static void calculateContractRiseDepRates(Contract__c contract) {
        Integer riseRateCount = 10, depreciationRateCount = 3;
        Integer riseRateNb = (contract.Rise_Rate_Nb__c != null ? Integer.valueOf(contract.Rise_Rate_Nb__c) : 0);
        Integer depreciationRateNb = (contract.Depreciation_Rate_Nb__c != null ? Integer.valueOf(contract.Depreciation_Rate_Nb__c) : 0) + 1;
        String fieldName;
        // Calculate Rise_Rate_YE__c = (1 + Rise_Rate__c) * (1 + Rise_Rate1__c) * ... (1 + Rise_Rate10__c) - 1
        Decimal riseRateYE = 0;
        // NEG-9600
        Boolean hasRate = contract.Rise_Rate__c != null;
        riseRateYE = (1 + (contract.Rise_Rate__c != null ? (contract.Rise_Rate__c / 100) : 0));
        if (riseRateNb > 0 && riseRateNb <= riseRateCount) {
            for (Integer i = 1; i <= riseRateNb; i++) {
                fieldName = 'Rise_Rate' + i + '__c';
                riseRateYE *= (1 + (contract.get(fieldName) != null ? ((Decimal)contract.get(fieldName) / 100) : 0));
                // NEG-9600
                hasRate |= contract.get(fieldName) != null;
            }
        }
        riseRateYE--;
        // NEG-9600
        // contract.Rise_Rate_YE__c = (riseRateYE * 100).setScale(2);
        // NEG-9600
        contract.Rise_Rate_YE__c = hasRate ? (riseRateYE * 100).setScale(2) : null;
        // Calculate Depreciation_Rate_YE__c = (1 + Depreciation_Rate__c) * (1 + Depreciation_Rate1__c) * ... (1 + Depreciation_Rate10__c) - 1
        Decimal depreciationRateYE = 0;
        // NEG-9600
        hasRate = contract.Depreciation_Rate__c != null;
        depreciationRateYE = (1 + (contract.Depreciation_Rate__c != null ? (contract.Depreciation_Rate__c / 100) : 0));
        if (depreciationRateNb > 0 && depreciationRateNb <= depreciationRateCount) {
            for (Integer i = 1; i <= depreciationRateNb; i++) {
                fieldName = 'Depreciation_Rate' + i + '__c';
                depreciationRateYE *= (1 + (contract.get(fieldName) != null ? ((Decimal)contract.get(fieldName) / 100) : 0));
                // NEG-9600
                hasRate |= contract.get(fieldName) != null;
            }
        }
        depreciationRateYE--;
        // NEG-9600
        // contract.Depreciation_Rate_YE__c = (depreciationRateYE * 100).setScale(2);
        // NEG-9600
        contract.Depreciation_Rate_YE__c = hasRate ? (depreciationRateYE * 100).setScale(2) : null;
    }

    // Generate contract name
    public static void generateContractName(Contract__c contract, String supplierName, String negoScopeCode, Map<String, Id> contractRTIds, String recordTypeLabel) {
        if (contractRTIds == null) {
            contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        }
        Set<String> contractTypeContract = new Set<String> {
            negoBaseRecordTypeId,
            negoBaseInitRecordTypeId,
            peRecordTypeId,
            signedRecordTypeId,
            toBeSignedRecordTypeId,
            landingRecordTypeId,
            objectiveRecordTypeId
        };
        if (contract.Contract_BDate__c != null && contract.RecordTypeId != null) {
            Integer year = contract.RecordTypeId != negoBaseRecordTypeId ? contract.Contract_BDate__c.year() : contract.Contract_BDate__c.year() + 1;
            // Name: *NOM DU FOURNISSEUR – NUMERO D’ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
            if ((contract.Is_Managed_By_ExternalSource__c == false && (contract.RecordTypeId != simulationRecordTypeId || contract.Name == null)) || contract.Name == null) {
                contract.Name = (supplierName + ' - ' + negoScopeCode + ' - ' + year + ' - ' + recordTypeLabel);
                if (contract.Name.length() > 80) {
                    contract.Name = contract.Name.substring(0, 80);
                }
                if (contract.SimulationNumber__c != null && (contract.RecordTypeId == simulationRecordTypeId || contract.RecordTypeId == safeBalanceRecordTypeId || contract.RecordTypeId == postNegoSimulationRecordTypeId || contract.RecordTypeId == signedCopyRecordTypeId)) {
                    contract.Name += ' ' + contract.SimulationNumber__c;
                }
            }
            // Code: *NUMERO D’ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
            if (contract.Is_Managed_By_ExternalSource__c == false || contract.Contract_Number__c == null) {
                contract.Contract_Number__c = negoScopeCode + ' - ' + year + ' - ' + recordTypeLabel;
                if (contract.Contract_Number__c.length() > 100) {
                    contract.Contract_Number__c = contract.Contract_Number__c.substring(0, 100);
                }
            }
            // Ext Id: *LIBELLE DE LA SEQUENCE/ANNEE/NUMERO D'ACCORD (MN-8chiffres)*
            if (contract.Is_Managed_By_ExternalSource__c == false || contract.Ext_id__c == null) {
                contract.Ext_id__c = recordTypeLabel + '/' + year + '/' + negoScopeCode;
				if (contract.SimulationNumber__c != null && (contract.RecordTypeId == simulationRecordTypeId || contract.RecordTypeId == safeBalanceRecordTypeId || contract.RecordTypeId == postNegoSimulationRecordTypeId || contract.RecordTypeId == signedCopyRecordTypeId)) {
                    contract.Ext_id__c += '/' + contract.SimulationNumber__c;
                }
            }
            if (contract.RecordTypeId == simulationRecordTypeId || contract.RecordTypeId == safeBalanceRecordTypeId || contract.RecordTypeId == postNegoSimulationRecordTypeId || contract.RecordTypeId == signedCopyRecordTypeId) {
                contract.Contract_Type__c = 'Simulation';
            }
            if (contract.RecordTypeId == targetRecordTypeId) {
                contract.Contract_Type__c = 'Target';
            }
            if (contractTypeContract.contains(contract.RecordTypeId)) {
                contract.Contract_Type__c = 'Contract';
            }
        }
    }

    public static List<Pol_Com_Condition__c> getRelatedPolCom(Set<Id> parentIds) {
        List<Pol_Com_Condition__c> tariffConditionsList = new List<Pol_Com_Condition__c>();
        if (NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, staticPolComConditionFields)) {
            String query = '';
            query += ' SELECT RecordType.DeveloperName, BusinessUnitCounterpartyProof__r.Name, ' + String.join(staticPolComConditionFields, ',') + ',';
            query += ' (SELECT RecordType.DeveloperName, BusinessUnitCounterpartyProof__r.Name, ' + String.join(staticPolComConditionFields, ',') + ' FROM Pol_Com_Conditions__r ORDER BY Name)';
            query += ' FROM Pol_Com_Condition__c';
            query += ' WHERE Id IN (\'' + String.join(new List<Id>(parentIds), '\',\'') +'\')';
            tariffConditionsList = Database.query(query);
        }
        return tariffConditionsList;
    }

    /**
     * generateDiscountTerms Description
     * Fill Discount terms of parent discount with an HTML table containing details about sub discounts
     * @param parentDiscount (Contract_Discount__c)
     * @param subDiscounts (List<Contract_Discount__c>)
     */
    public static void generateDiscountTerms(Contract_Discount__c parentDiscount, List<Contract_Discount__c> subDiscounts) {
        if(subDiscounts.isEmpty()) return;
        List<String> negoTypesWithoutSubdiscountValues = new List<String> {
            'Price Discount',
            'Advertising fees',
            'Advertising Fees 2'
        };
        Boolean displaySubDiscountsWithValues = !negoTypesWithoutSubdiscountValues.contains(parentDiscount.Nego_Discount_Type__c)
                                      && parentDiscount.Contract__c != null
                                      && parentDiscount.Contract__r.Supplier_Nego_Scope__c != null
                                      && parentDiscount.Contract__r.Supplier_Nego_Scope__r.SegmentationAttribut3__c == 'Value1'
                                    ? true
                                    : false;
        Schema.DescribeFieldResult unitTypePicklistField = Contract_Discount__c.Unit_Amount_Type__c.getDescribe();
        Map<String, String> unitTypePicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : unitTypePicklistField.getPicklistValues()) {
            unitTypePicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        Schema.DescribeFieldResult calcMethodPicklistField = Contract_Discount__c.slab_calc_method__c.getDescribe();
        Map<String, String> calcMethodpicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : calcMethodPicklistField.getPicklistValues()) {
            calcMethodpicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        String HTMLTable = '<table class="subDiscounts" border="1" style="font-family: Arial Unicode MS,Arial,Helvetica,sans-serif; font-size: 8px; width: 100%;"><tbody>';
        String subDiscountsRows = '';
        String slabsListRow = '';
        String strSlabsLines;
        String dispatchLine;
        String dispatchValues = '';
        if (!subDiscounts.IsEmpty() && parentDiscount.Condition_Type__r.Is_Conditional__c && String.isNotBlank(parentDiscount.slab_calc_method__c)) {
            String strSlabMethod;
            Boolean isTranche = false;
            Boolean isProg = false;
            Boolean isTO = false;
            String unitType = '';
            if ( parentDiscount.slab_calc_method__c.contains('TO')) {
                strSlabMethod = 'CA est supérieure ou égale à ';
                if (parentDiscount.slab_calc_method__c == 'TO') {
                    strSlabMethod = 'CA est supérieur ou égal à ';
                }
                isTO = true;
                unitType = ' ' + (parentDiscount.CurrencyIsoCode != null ? parentDiscount.CurrencyIsoCode : '');
            } else {
                strSlabMethod = 'Quantité est supérieure ou égale à ';
                unitType = ' ' + (parentDiscount.Unit_Amount_Type__c != null ? unitTypePicklistLabels.get(parentDiscount.Unit_Amount_Type__c) : '');
            }
            if (parentDiscount.slab_calc_method__c.contains('Inc')) {
                strSlabMethod = 'sur la tranche';
                if (isTO) {
                    if (parentDiscount.slab_calc_method__c != 'Inc TO') {
                        unitType = '%';
                        isProg = true;
                    }
                } else {
                    if (parentDiscount.slab_calc_method__c.contains('Prog')) {
                        unitType = '%' + unitType;
                        isProg = true;
                    }
                }
                isTranche = true;
            } else if (parentDiscount.slab_calc_method__c.contains('Prog')) {
                strSlabMethod = 'si la progression ' + strSlabMethod;
                if (isTO) {
                    unitType = '%';
                } else {
                    unitType = '%' + unitType;
                }
                isProg = true;
            } else {
                strSlabMethod = 'si ' + strSlabMethod;
            }
            String strSlabsValue = '';
            for (Integer i = 1; i <= 10; i ++) {
                String slab = parentDiscount.get('Slab_' + i + '__c') != null ? parentDiscount.get('Slab_' + i + '__c') + '' : '0';
                String slabper = parentDiscount.get('slab_per_' + i + '__c') != null ? parentDiscount.get('slab_per_' + i + '__c') + '' : '0';
                String slabamt = parentDiscount.get('Slab_val_' + i + '__c') != null ? parentDiscount.get('Slab_val_' + i + '__c') + '' : '0';
                strSlabsValue += String.valueOf( slab + '/' + slabper + '/' + slabamt + (i != 10 ? '/' : ''));
            }
            List<String> strSlabsValues = strSlabsValue.split('/');
            if (!strSlabsValues.isEmpty()) {
                String slabThreshold, slabPer, slabAmt, nextSlabThreshold;
                strSlabsLines = 'Calcul des paliers selon : <strong>' + calcMethodpicklistLabels.get(parentDiscount.slab_calc_method__c) + '</strong>';
                for (Integer i = 0; i < strSlabsValues.size() - 1; i += 3) {
                    if (!(Decimal.ValueOf(strSlabsValues[i]) == 0 && Decimal.ValueOf(strSlabsValues[i + 1]) == 0 && Decimal.ValueOf(strSlabsValues[i + 2]) == 0)) {
                        slabThreshold = Decimal.ValueOf(strSlabsValues[i]).format();
                        slabPer = Decimal.ValueOf(strSlabsValues[i + 1]).format();
                        slabAmt = Decimal.ValueOf(strSlabsValues[i + 2]).format();
                        strSlabsLines += '<br> • ' + slabPer + '% '+ strSlabMethod;
                        if (!isTranche) {
                            strSlabsLines += slabThreshold ;
                            strSlabslines += /* (isProg ? '%' : '') +  */ unitType;
                        } else if (isTranche && ((i + 3) <= strSlabsValues.size() - 1) && Decimal.ValueOf(strSlabsValues[i + 3]) != 0) {
                            nextSlabThreshold = Decimal.ValueOf(strSlabsValues[i + 3]).format();
                            strSlabsLines += ' entre ' + slabThreshold +/*  '%' + */ unitType + ' et ' + nextSlabThreshold /* + '%' */ + unitType;
                        } else {
                            strSlabsLines += ' supérieure ou égale à ' + slabThreshold /* + '%' */ + ' ' + unitType;
                            strSlabsLines += '<br> <strong>La rémunération se fait par les paliers de tranche ' + (isProg ? 'de progression ' : '');
                            strSlabsLines += parentDiscount.slab_calc_method__c.contains('TO') ? 'CA' : 'Quantité';
                            strSlabsLines += ' atteints</strong>';
                        }
                    } else {
                        break;
                    }
                }
            }
        }
        for (Integer i = 1; i <= 13; i++) {
            if (parentDiscount.get('Value_amt_disp_M' + i + '__c') != null) {
                dispatchValues +=  '<br>Fin ' + (i < 13 ? monthsMap.get(i) : Label.LBL_Month + ' 13') + ': ' + String.ValueOf(parentDiscount.get('Value_amt_disp_M' + i + '__c')) + ' ' + parentDiscount.CurrencyIsoCode;
            }
        }
        if (dispatchValues != '') {
            dispatchLine = 'A répartir uniquement sur les produits en promotion comme suit, chaque acompte périodique pourra faire l\'objet d\'un avoir de solde par période :';
            dispatchLine += dispatchValues;
            dispatchLine += '<br>+ solde fin d\'année';
        }
        Boolean oneSubOnly = subDiscounts.size() == 1;
        Boolean slashValues = false;
        for (Integer i = 0; i < subDiscounts.size(); i++) {
            slashValues = false;
            Contract_Discount__c subDiscount = subDiscounts.get(i);
            if (subDiscount.Condition_Type__r != null && (subDiscount.Condition_Type__r.Segmentation_attribut3__c != 'Value1' || oneSubOnly)) {
                slashValues = true;
            }
            subDiscountsRows += !(i == subDiscounts.size() - 1)? '<tr>' : '<tr class="lastRow">';
            String counterpartynumbertotal = subDiscount.Proof_counterparty_number_total__c != null ? String.valueOf((Integer)subDiscount.Proof_counterparty_number_total__c) : '';
            if (displaySubDiscountsWithValues) {
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 46%; text-align: justify;">' + (subDiscount.Discount_Terms__c != null ? subDiscount.Discount_Terms__c : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 5%; background-color: #DCDCDC;">' + counterpartynumbertotal +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 10%; text-align: center;">' + ((subDiscount.Value_Per__c != null && subDiscount.Value_Per__c != 0 && !slashValues ? NegoptimHelper.formatDecimalValue(subDiscount.Value_per__c, negoptimSettings.discountPercentScale) : '/')) + '</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 13%; text-align: center;">' + ((subDiscount.Value_amt__c != null && subDiscount.Value_amt__c != 0 && !slashValues ? subDiscount.Value_amt__c.format() : '/')) + '</td>';
                subDiscountsRows += '<td class="lastCol" colspan="1" rowspan="1" style="width: 26%; text-align: center; white-space: pre-wrap;">' + (String.isNotBlank(subDiscount.Proof_counterparty_description__c) ? subDiscount.Proof_counterparty_description__c : '');
            } else {
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 60%; text-align: justify;">' + (subDiscount.Discount_Terms__c != null ? subDiscount.Discount_Terms__c : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 10%; background-color: #DCDCDC;">' + counterpartynumbertotal +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 30%; text-align: center; white-space: pre-wrap;">' + (String.isNotBlank(subDiscount.Proof_counterparty_description__c) ? subDiscount.Proof_counterparty_description__c : '');
            }
            if (i == subDiscounts.size() - 1) {
                if (String.isNotBlank(subDiscount.Proof_counterparty_description__c)) {
                    subDiscountsRows += '<br>';
                }
                if (String.isNotBlank(strSlabsLines)) {
                    subDiscountsRows += strSlabsLines;
                }
                if (String.isNotBlank(dispatchLine)) {
                    if (String.isNotBlank(strSlabsLines)) {
                        subDiscountsRows += '<br>';
                    }
                    subDiscountsRows += dispatchLine;
                }
            }
            subDiscountsRows += '</td></tr>';
            //This is dumb we know, we need to clear conditin_Type__r from subdiscounts so they can pass when inserted through conditionsList and negotiate
            if (subDiscount.Id == null) {
                subDiscount.Condition_Type__r = null;
            }
        }
        HTMLTable += subDiscountsRows;
        HTMLTable += slabsListRow;
        HTMLTable += '</tbody></table>';
        parentDiscount.Discount_Terms__c = HTMLTable;
    }
    
    /**
     * generateDiscountTerms Description
     * Fill Discount terms of parent discount with an HTML table containing details about sub discounts
     * @param parentDiscount (Contract_Discount__c)
     * @param subDiscounts (List<Contract_Discount__c>)
     */
    public static void generateDiscountTerms(Contract_Discount__c parentDiscount, List<Contract_Discount__c> subDiscounts, Map<String, String> unitTypePicklistLabels, Map<String, String> calcMethodpicklistLabels) {
        List<String> negoTypesWithoutSubdiscountValues = new List<String> {
            'Price Discount',
            'Advertising fees',
            'Advertising Fees 2'
        };
        Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Boolean isSignedContract = parentDiscount.Contract__r != null && parentDiscount.Contract__r.RecordTypeId == contractRTIds.get('Signed');
        Boolean displaySubDiscountsWithValues = !negoTypesWithoutSubdiscountValues.contains(parentDiscount.Nego_Discount_Type__c)
                                      && parentDiscount.Contract__c != null
                                      && parentDiscount.Contract__r.Supplier_Nego_Scope__c != null
                                      && parentDiscount.Contract__r.Supplier_Nego_Scope__r.SegmentationAttribut3__c == 'Value1'
                                    ? true
                                    : false;
        String HTMLTable = '<table class="subDiscounts" border="1" style="font-family: Arial Unicode MS,Arial,Helvetica,sans-serif; font-size: 8px; width: 100%;"><tbody>';
        String subDiscountsRows = '';
        String slabsListRow = '';
        String strSlabsLines;
        String dispatchLine;
        String dispatchValues = '';
        if (!subDiscounts.IsEmpty() && parentDiscount.Condition_type__r.Is_Conditional__c && String.isNotBlank(parentDiscount.slab_calc_method__c)) {
            String strSlabMethod;
            Boolean isTranche = false;
            Boolean isProg = false;
            Boolean isTO = false;
            String unitType = '';
            if ( parentDiscount.slab_calc_method__c.contains('TO')) {
                strSlabMethod = 'CA est supérieure ou égale à ';
                if (parentDiscount.slab_calc_method__c == 'TO') {
                    strSlabMethod = 'CA est supérieur ou égal à ';
                }
                isTO = true;
                unitType = '' + parentDiscount.CurrencyIsoCode;
            } else {
                strSlabMethod = 'Quantité est supérieure ou égale à ';
                unitType = ' ' + (parentDiscount.Unit_Amount_Type__c != null ? unitTypePicklistLabels.get(parentDiscount.Unit_Amount_Type__c) : '');
            }
            if (parentDiscount.slab_calc_method__c.contains('Inc')) {
                strSlabMethod = 'sur la tranche';
                if (isTO) {
                    if (parentDiscount.slab_calc_method__c != 'Inc TO') {
                        unitType = '%';
                        isProg = true;
                    }
                } else {
                    if (parentDiscount.slab_calc_method__c.contains('Prog')) {
                        unitType = '%' + unitType;
                        isProg = true;
                    }
                }
                isTranche = true;
            } else if (parentDiscount.slab_calc_method__c.contains('Prog')) {
                strSlabMethod = 'si la progression ' + strSlabMethod;
                if (isTO) {
                    unitType = '%';
                } else {
                    unitType = '%' + unitType;
                }
                isProg = true;
            } else {
                strSlabMethod = 'si ' + strSlabMethod;
            }
            String strSlabsValue = '';
            for (Integer i = 1; i <= 10; i ++) {
                String slab = parentDiscount.get('Slab_' + i + '__c') != null ? parentDiscount.get('Slab_' + i + '__c') + '' : '0';
                String slabper = parentDiscount.get('slab_per_' + i + '__c') != null ? parentDiscount.get('slab_per_' + i + '__c') + '' : '0';
                String slabamt = parentDiscount.get('Slab_val_' + i + '__c') != null ? parentDiscount.get('Slab_val_' + i + '__c') + '' : '0';
                strSlabsValue += String.valueOf( slab + '/' + slabper + '/' + slabamt + (i != 10 ? '/' : ''));
            }
            List<String> strSlabsValues = strSlabsValue.split('/');
            if (!strSlabsValues.isEmpty()) {
                String slabThreshold, slabPer, slabAmt, nextSlabThreshold;
                strSlabsLines = 'Calcul des paliers selon : <strong>' + calcMethodpicklistLabels.get(parentDiscount.slab_calc_method__c) + '</strong>';
                for (Integer i = 0; i < strSlabsValues.size() - 1; i += 3) {
                    if (!(Decimal.ValueOf(strSlabsValues[i]) == 0 && Decimal.ValueOf(strSlabsValues[i + 1]) == 0 && Decimal.ValueOf(strSlabsValues[i + 2]) == 0)) {
                        slabThreshold = Decimal.ValueOf(strSlabsValues[i]).format();
                        slabPer = Decimal.ValueOf(strSlabsValues[i + 1]).format();
                        slabAmt = Decimal.ValueOf(strSlabsValues[i + 2]).format();
                        strSlabsLines += '<br> • ' + slabPer + '% '+ strSlabMethod;
                        if (!isTranche) {
                            strSlabsLines += slabThreshold ;
                            strSlabslines += /* (isProg ? '%' : '') +  */ unitType;
                        } else if (isTranche && ((i + 3) <= strSlabsValues.size() - 1) && Decimal.ValueOf(strSlabsValues[i + 3]) != 0) {
                            nextSlabThreshold = Decimal.ValueOf(strSlabsValues[i + 3]).format();
                            strSlabsLines += ' entre ' + slabThreshold +/*  '%' + */ unitType + ' et ' + nextSlabThreshold /* + '%' */ + unitType;
                        } else {
                            strSlabsLines += ' supérieure ou égale à ' + slabThreshold /* + '%' */ + unitType;
                            strSlabsLines += '<br> <strong>La rémunération se fait par les paliers de tranche ' + (isProg ? 'de progression ' : '');
                            strSlabsLines += parentDiscount.slab_calc_method__c.contains('TO') ? 'CA' : 'Quantité';
                            strSlabsLines += ' atteints</strong>';
                        }
                    } else {
                        break;
                    }
                }
            }
        }
        for (Integer i = 1; i <= 13; i++) {
            if (parentDiscount.get('Value_amt_disp_M' + i + '__c') != null) {
                dispatchValues +=  '<br>Fin ' + (i < 13 ? monthsMap.get(i) : Label.LBL_Month + ' 13') + ': ' + String.ValueOf(parentDiscount.get('Value_amt_disp_M' + i + '__c')) + ' ' + parentDiscount.CurrencyIsoCode;
            }
        }
        if (dispatchValues != '') {
            dispatchLine = 'A répartir uniquement sur les produits en promotion comme suit, chaque acompte périodique pourra faire l\'objet d\'un avoir de solde par période :';
            dispatchLine += dispatchValues;
            dispatchLine += '<br>+ solde fin d\'année';
        }
        Boolean oneSubOnly = subDiscounts.size() == 1;
        Boolean slashValues = false;
        for (Integer i = 0; i < subDiscounts.size(); i++) {
            slashValues = false;
            Contract_Discount__c subDiscount = subDiscounts.get(i);
            if (subDiscount.Condition_Type__r != null && (subDiscount.Condition_Type__r.Segmentation_attribut3__c != 'Value1' || oneSubOnly)) {
                slashValues = true;
            }
            subDiscountsRows += !(i == subDiscounts.size() - 1)? '<tr>' : '<tr class="lastRow">';
            if (displaySubDiscountsWithValues && !isSignedContract) {
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 46%; text-align: justify;">' + (subDiscount.Discount_Terms__c != null ? subDiscount.Discount_Terms__c : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 5%; background-color: #DCDCDC;">' + (subDiscount.Proof_counterparty_number_total__c != null ? String.valueOf(subDiscount.Proof_counterparty_number_total__c) : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 10%; text-align: center;">' + ((subDiscount.Value_per__c != null && subDiscount.Value_per__c != 0 && !slashValues ? NegoptimHelper.formatDecimalValue(subDiscount.Value_per__c, negoptimSettings.discountPercentScale) : '/')) + '</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 13%; text-align: center;">' + ((subDiscount.Value_amt__c != null && subDiscount.Value_amt__c != 0 && !slashValues ? subDiscount.Value_amt__c.format() : '/')) + '</td>';
                subDiscountsRows += '<td class="lastCol" colspan="1" rowspan="1" style="width: 26%; text-align: center; white-space: pre-wrap;">' + (String.isNotBlank(subDiscount.Proof_counterparty_description__c) ? subDiscount.Proof_counterparty_description__c : '');
            } else if (isSignedContract || (!displaySubDiscountsWithValues && !isSignedContract)){
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 60%; text-align: justify;">' + (subDiscount.Discount_Terms__c != null ? subDiscount.Discount_Terms__c : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 10%; background-color: #DCDCDC;">' + (subDiscount.Proof_counterparty_number_total__c != null ? String.valueOf(subDiscount.Proof_counterparty_number_total__c) : '') +'</td>';
                subDiscountsRows += '<td colspan="1" rowspan="1" style="width: 30%; text-align: center; white-space: pre-wrap;">' + (String.isNotBlank(subDiscount.Proof_counterparty_description__c) ? subDiscount.Proof_counterparty_description__c : '');
            }
            if (i == subDiscounts.size() - 1) {
                if (String.isNotBlank(subDiscount.Proof_counterparty_description__c)) {
                    subDiscountsRows += '<br>';
                }
                if (String.isNotBlank(strSlabsLines)) {
                    subDiscountsRows += strSlabsLines;
                }
                if (String.isNotBlank(dispatchLine)) {
                    if (String.isNotBlank(strSlabsLines)) {
                        subDiscountsRows += '<br>';
                    }
                    subDiscountsRows += dispatchLine;
                }
            }
            subDiscountsRows += '</td></tr>';
            //This is dumb we know, we need to clear conditin_Type__r from subdiscounts so they can pass when inserted through conditionsList and negotiate
            if (subDiscount.Id == null) {
                subDiscount.Condition_Type__r = null;
            }
        }
        HTMLTable += subDiscountsRows;
        HTMLTable += slabsListRow;
        HTMLTable += '</tbody></table>';
        parentDiscount.Discount_Terms__c = HTMLTable;
    }
    /*
     * @description Roll-up FlatPrice_Rate_Promo_Correction__c intro Contract__c
     **/
    public static Map<Id, Contract__c> updateContractFlatPrice(Set<Id> contractIdSet, Set<Id> NSIdSet) {
        Map<Id, Contract__c> contractsToUpdate = new Map<Id, Contract__c>();
        for (Contract_Discount__c item : [SELECT Id, FlatPrice_Rate_Correction__c, FlatPrice_Rate_Promo_Correction__c, X2015_Nego_p__c,
                                          Contract__c, Contract__r.FlatPrice_Rate_Correction__c,
                                          Contract__r.FlatPrice_Rate_Promo_Correction__c,
                                          Contract__r.Supplier_Nego_Scope__r.ManagePromoFlatPriceRate__c
                                          FROM Contract_Discount__c
                                          WHERE Contract__r.Is_Managed_By_ExternalSource__c = FALSE
                                          AND Parent_Discount__c = NULL
                                          AND (Contract__c IN :contractIdSet OR Contract__r.Supplier_Nego_Scope__c IN :NSIdSet)
                                          AND Status__c <> 'Deleted'
                                          AND Contract__r.RecordType.DeveloperName <> 'Signed_Copy'])
        {
            // update +/- SRP on contract
            Contract__c contract = (contractsToUpdate.containsKey(item.Contract__c)
                                    ? contractsToUpdate.get(item.Contract__c)
                                    : new Contract__c(Id = item.Contract__c,
                                                      FlatPrice_Rate_Correction__c = 0,
                                                      FlatPrice_Rate_Promo_Correction__c = 0,
                                                      FlatPrice_Rate_Exec_Date__c = date.today()));
            Decimal contractFlatPriceRateCorrection = contract.FlatPrice_Rate_Correction__c != null ? contract.FlatPrice_Rate_Correction__c : 0;
            Decimal contractFlatPriceRatePromo = contract.FlatPrice_Rate_Promo_Correction__c != null ? contract.FlatPrice_Rate_Promo_Correction__c : 0;
            Decimal discountFlatPriceRateCorrection = item.FlatPrice_Rate_Correction__c != null ? item.FlatPrice_Rate_Correction__c : 0;
            Decimal discountFlatPriceRatePromo = item.FlatPrice_Rate_Promo_Correction__c != null ? item.FlatPrice_Rate_Promo_Correction__c : 0;
            if(item.Contract__r.Supplier_Nego_Scope__r.ManagePromoFlatPriceRate__c == false) {
                contract.FlatPrice_Rate_Correction__c = contractFlatPriceRateCorrection + discountFlatPriceRateCorrection;
                contract.FlatPrice_Rate_Promo_Correction__c = contractFlatPriceRateCorrection + discountFlatPriceRateCorrection;
            } else {
                contract.FlatPrice_Rate_Correction__c = contractFlatPriceRateCorrection + discountFlatPriceRateCorrection;
                contract.FlatPrice_Rate_Promo_Correction__c = contractFlatPriceRatePromo + discountFlatPriceRatePromo;
            }
            contractsToUpdate.put(contract.Id, contract);
        }
        return contractsToUpdate;
    }
    /*
     * @description build query for contracts conso
     */
    public static String buildQueryForConsolidateContract(List<Id> supplierBUIds, List<Id> supplierIds, List<Id> negoScopeIds, List<Id> contractBUIds, Integer year,
                                                          Boolean isConsoNegoBaseExit, List<String> consoRecordTypes)
    {
        String q = 'SELECT Id, Name, Supplier__c, Supplier__r.Name,';
        if(isConsoNegoBaseExit) {
            consoRecordTypes = new List<String>{'Period_Extension', 'Nego_Base_Exit'};
        } else {
            ////consoRecordTypes = new List<String>{'Period_Extension', 'Nego_Base_Init', 'Nego_Base', 'Landing'};
            consoRecordTypes.add('Period_Extension');
        }
        List<String> contractRecordTypes = new List<String>(consoRecordTypes);
        if(consoRecordTypes.contains('Nego_Base')) {
            contractRecordTypes.add('Nego_Base_Init');
        }
        q += ' (SELECT Id, Name, Ext_id__c, Status__c, Contract_Number__c, Contract_Type__c, Supplier__c, CurrencyIsoCode, Contract_BDate__c, Contract_EDate__c, BusinessUnitSource__c, BusinessUnitContract__c, BusinessUnitContract__r.Name,';
        q += ' Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, D_N__c, Parent_Contract__c, Supplier__r.Name, Supplier__r.Status__c, Supplier_Nego_Scope__r.Status__c,';
        q += ' TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c, Total_TO__c, Total_TO_Tariff_Nego__c, ';
        // q += ' TO1_Fact__c, TO2_Fact__c, TO3_Fact__c, TO4_Fact__c, TO5_Fact__c, TO6_Fact__c, TO7_Fact__c, TO8_Fact__c, TO9_Fact__c, TO10_Fact__c, TO11_Fact__c, TO12_Fact__c, Total_TO_Fact__c,';
        // q += ' TO1_FX__c, TO2_FX__c, TO3_FX__c, TO4_FX__c, TO5_FX__c, TO6_FX__c, TO7_FX__c, TO8_FX__c, TO9_FX__c, TO10_FX__c, TO11_FX__c, TO12_FX__c,';
        q += ' Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c,';
        // q += ' Qty1_Fact__c, Qty2_Fact__c, Qty3_Fact__c, Qty4_Fact__c, Qty5_Fact__c, Qty6_Fact__c, Qty7_Fact__c, Qty8_Fact__c, Qty9_Fact__c, Qty10_Fact__c, Qty11_Fact__c, Qty12_Fact__c,';
        q += ' Markdown_Rate_Break__c, Markdown_Rate_Promo__c, Markdown_Rate_Theft__c,';
        q += ' Rise_Rate_YE__c, Rise_Rate__c, Rise_Rate1__c, Rise_Rate2__c, Rise_Rate3__c, Rise_Rate4__c, Rise_Rate5__c, Rise_Rate6__c, Rise_Rate7__c, Rise_Rate8__c, Rise_Rate9__c, Rise_Rate10__c,';
        q += ' Depreciation_Rate_YE__c, Depreciation_Rate__c, Depreciation_Rate1__c, Depreciation_Rate2__c, Depreciation_Rate3__c,';
        q += ' Reference_Year__c, RecordType.DeveloperName, Is_Conso_Requiered__c, Is_OnTop_Simulation__c, Supplier_Nego_Scope__c,';
        q += ' Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c,';
        q += ' Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c, CompanySigned_By__c';
        q += ' FROM Contracts1__r WHERE BusinessUnitContract__c <> NULL';
        q += ' AND (Is_OnTop_Simulation__c = TRUE OR RecordType.DeveloperName IN (\'' + String.join(contractRecordTypes, '\',\'') +'\'))';
        q += ' AND Status__c <> \'Deleted\'';
        if (contractBUIds != null && !contractBUIds.isEmpty()) {
            q += ' AND BusinessUnitContract__c IN (\'' + String.join(contractBUIds, '\',\'') +'\')';
        }
        if (year != null) {
            q += ' AND Reference_Year__c = ' + year;
        }
        q += ')';
        q += ' FROM NegoScope__c';
        q += ' WHERE Supplier__r.Status__c = \'Active\'' ;
        if (negoScopeIds != null && negoScopeIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(negoScopeIds, '\',\'') +'\')';
        }
        if (supplierIds != null && supplierIds.size() > 0) {
            q += ' AND Supplier__c IN (\'' + String.join(supplierIds, '\',\'') +'\')';
        }
        if (supplierBUIds != null && !supplierBUIds.isEmpty()) {
            q += ' AND Supplier__r.BusinessUnitOrigin__c IN (\'' + String.join(supplierBUIds, '\',\'') +'\')';
        }
        return q;
    }
    /*
     * @description Consolide Nego_Base_Init/Nego_Base/Landing/Nego_Base_Exist
     */
    public static List<String> consolidateContract(List<Id> supplierBUIds, List<Id> supplierIds, List<Id> negoScopeIds, List<Id> contractBUIds, Integer year, List<NegoScope__c> negoscopes,
                                                   Boolean startedFromBatch, Boolean isConsoNegoBaseExit)
    {
        if(isConsoNegoBaseExit) {
            return consolidateContract(supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, negoscopes,
                                       startedFromBatch, isConsoNegoBaseExit, false, new List<String>());
        } else {
            Map<String, NegoSettings.ContractConsolidationConfigurationWrapper> contractConsolidationConfiguration = myNegoSettings.contractConsolidationConfiguration;
            NegoSettings.ContractConsolidationConfigurationWrapper landingConsoSettings = contractConsolidationConfiguration.containsKey('Landing') ? contractConsolidationConfiguration.get('Landing') : null;
            NegoSettings.ContractConsolidationConfigurationWrapper negoBaseConsoSettings = contractConsolidationConfiguration.containsKey('Nego_Base') ? contractConsolidationConfiguration.get('Nego_Base') : null;
            NegoSettings.ContractConsolidationConfigurationWrapper negoBaseInitConsoSettings = contractConsolidationConfiguration.containsKey('Nego_Base_Init') ? contractConsolidationConfiguration.get('Nego_Base_Init') : null;
            Date startingDayToCreateLandingOnConso = landingConsoSettings != null && landingConsoSettings.executionDate != null ? Date.newInstance(year, landingConsoSettings.executionDate.month(), landingConsoSettings.executionDate.day()) : null;
            Date startingDayToCreateNegoBaseOnConso = negoBaseConsoSettings != null && negoBaseConsoSettings.executionDate != null ? Date.newInstance(year, negoBaseConsoSettings.executionDate.month(), negoBaseConsoSettings.executionDate.day()) : null;
            Date startingDayToCreateNegoBaseInitOnConso = negoBaseInitConsoSettings != null && negoBaseInitConsoSettings.executionDate != null ? Date.newInstance(year, negoBaseInitConsoSettings.executionDate.month(), negoBaseInitConsoSettings.executionDate.day()) : null;
            Date startingConsoDay = Date.newInstance(year, Date.today().month(), Date.today().day());
            Boolean isConsoNegoBase = negoBaseConsoSettings != null
                && negoBaseConsoSettings.isActive
                && (startingDayToCreateNegoBaseOnConso != null && startingDayToCreateNegoBaseOnConso.daysBetween(startingConsoDay) >= 0);
            Boolean isConsoLanding = landingConsoSettings != null
                && landingConsoSettings.isActive
                && startingDayToCreateLandingOnConso != null
                && startingDayToCreateLandingOnConso.daysBetween(startingConsoDay) >= 0;
            Boolean isConsoNegoBaseInit = negoBaseInitConsoSettings != null
                && negoBaseInitConsoSettings.isActive
                && startingDayToCreateNegoBaseInitOnConso != null
                && startingDayToCreateNegoBaseInitOnConso.daysBetween(startingConsoDay) >= 0;
            List<String> errorMessages = new List<String>();
            if (isConsoNegoBase) {
                System.enqueueJob(new ConsolidateContractQueueable(ContractServices.class.getName(), supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, new List<String>{'Nego_Base'}));
            }
            if (isConsoLanding) {
                System.enqueueJob(new ConsolidateContractQueueable(ContractServices.class.getName(), supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, new List<String>{'Landing'}));
            }
            if (isConsoNegoBaseInit) {
                errorMessages = consolidateContract(supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, negoscopes,
                                                             startedFromBatch, isConsoNegoBaseExit, false, new List<String>{'Nego_Base_Init'});
            }
            /*List<String> consoRecordTypes = new List<String>{'Nego_Base_Init'};
                List<String> errorMessages = consolidateContract(supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, negoscopes,
                                                             startedFromBatch, isConsoNegoBaseExit, false, consoRecordTypes);
            System.enqueueJob(new ConsolidateContractQueueable(ContractServices.class.getName(), supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, new List<String>{'Nego_Base'}));*/
            return errorMessages;
        }
    }
    /*
     * @description Consolide the contracts PT and TOP for generate contracts Landing/NB/NBI
     */
    public static List<String> consolidateContract(List<Id> supplierBUIds, List<Id> supplierIds, List<Id> negoScopeIds, List<Id> contractBUIds, Integer year, List<NegoScope__c> negoscopes,
                                                   Boolean startedFromBatch, Boolean isConsoNegoBaseExit, Boolean isValidatedNegoBaseInit, List<String> consoRecordTypes)
    {
        List<String> errorMessages = new List<String>();
        Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Map<String, Id> availableContractRTIds = NegoptimHelper.getAvailableObjectRecordTypeMapIds(Contract__c.SObjectType);
        Map<String, Id> discountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
        year = year == null ? System.today().year() : year;
        Map<String, NegoSettings.ContractConsolidationConfigurationWrapper> contractConsolidationConfiguration = myNegoSettings.contractConsolidationConfiguration;
        NegoSettings.ContractConsolidationConfigurationWrapper landingConsoSettings = contractConsolidationConfiguration.containsKey('Landing') ? contractConsolidationConfiguration.get('Landing') : null;
        NegoSettings.ContractConsolidationConfigurationWrapper negoBaseConsoSettings = contractConsolidationConfiguration.containsKey('Nego_Base') ? contractConsolidationConfiguration.get('Nego_Base') : null;
        NegoSettings.ContractConsolidationConfigurationWrapper negoBaseInitConsoSettings = contractConsolidationConfiguration.containsKey('Nego_Base_Init') ? contractConsolidationConfiguration.get('Nego_Base_Init') : null;
        Date startingDayToCreateLandingOnConso = landingConsoSettings != null && landingConsoSettings.executionDate != null ? Date.newInstance(year, landingConsoSettings.executionDate.month(), landingConsoSettings.executionDate.day()) : null;
        Date startingDayToCreateNegoBaseOnConso = negoBaseConsoSettings != null && negoBaseConsoSettings.executionDate != null ? Date.newInstance(year, negoBaseConsoSettings.executionDate.month(), negoBaseConsoSettings.executionDate.day()) : null;
        Date startingDayToCreateNegoBaseInitOnConso = negoBaseInitConsoSettings != null && negoBaseInitConsoSettings.executionDate != null ? Date.newInstance(year, negoBaseInitConsoSettings.executionDate.month(), negoBaseInitConsoSettings.executionDate.day()) : null;
        Date startingConsoDay = Date.newInstance(year, Date.today().month(), Date.today().day());
        Boolean isConsoNegoBase = negoBaseConsoSettings != null
                                && negoBaseConsoSettings.isActive
                                && consoRecordTypes.contains('Nego_Base')
                                && (isValidatedNegoBaseInit || (startingDayToCreateNegoBaseOnConso != null && startingDayToCreateNegoBaseOnConso.daysBetween(startingConsoDay) >= 0));
        Boolean isConsoLanding = landingConsoSettings != null
                                && landingConsoSettings.isActive
                                && consoRecordTypes.contains('Landing')
                                && startingDayToCreateLandingOnConso != null
                                && startingDayToCreateLandingOnConso.daysBetween(startingConsoDay) >= 0;
        Boolean isConsoNegoBaseInit = negoBaseInitConsoSettings != null
                                    && negoBaseInitConsoSettings.isActive
                                    && consoRecordTypes.contains('Nego_Base_Init')
                                    && startingDayToCreateNegoBaseInitOnConso != null
                                    && startingDayToCreateNegoBaseInitOnConso.daysBetween(startingConsoDay) >= 0;
        if(!startedFromBatch) {
            String q = buildQueryForConsolidateContract(supplierBUIds, supplierIds, negoScopeIds, contractBUIds, year, isConsoNegoBaseExit, consoRecordTypes);
            System.debug('q <<<<<<' + q);
            negoscopes = Database.query(q);
        }
        // Map<Reference_Year__c + Supplier_Nego_Scope__c + BusinessUnitContract__c, ALL Contracts>
        Map<String, ContractConsoWrapper> wContractsMap = new Map<String, ContractConsoWrapper>();
        // Origin discounts from PE
        Set<Id> originFromMoveContractDiscountSet = new Set<Id>();
        // contract Id set
        Set<Id> contractSet = new Set<Id>();
        List<String> conditionsFields = new List<String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        for (String fieldName : conditionFieldsMap.keySet()) {
            if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                conditionsFields.add(fieldName);
            }
        }
        List<String> polSaleConditionExceptionFields = new List<String>();
        Map<String, Schema.SObjectField> polSaleConditionExceptionFieldsMap = Schema.SObjectType.Pol_Sale_Condition_Exception__c.fields.getMap();
        for (String fieldName : polSaleConditionExceptionFieldsMap.keySet()) {
            if (polSaleConditionExceptionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                polSaleConditionExceptionFields.add(fieldName);
            }
        }
        Set<Id> contractsNBConsoExistSet = new Set<Id>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            if (negoscopes != null && !negoscopes.isEmpty()) {
                for (NegoScope__c item : negoscopes) {
                    for (Contract__c contract : item.Contracts1__r) {
                        String key = Integer.valueOf(contract.Reference_Year__c) + '' + item.Id + '' + contract.BusinessUnitContract__c;
                        ContractConsoWrapper wContract = wContractsMap.containsKey(key) ? wContractsMap.get(key) : new ContractConsoWrapper(contractRTIds, availableContractRTIds, discountRTIds, isConsoNegoBaseExit, isConsoLanding, isConsoNegoBase, isConsoNegoBaseInit, isValidatedNegoBaseInit);
                        if(isConsoNegoBaseExit) {
                            if (wContract.contractNegoBaseExit == null && contract.RecordType.DeveloperName == 'Nego_Base_Exit') {
                                wContract.contractNegoBaseExit = contract;
                                contractSet.add(contract.Id);
                            }
                        } else {
                            if (consoRecordTypes.contains(contract.RecordType.DeveloperName) && contract.RecordType.DeveloperName == 'Landing') {
                                wContract.isConsoLanding = true;
                                wContract.contractLanding = contract;
                                contractSet.add(contract.Id);
                            }
                            if(consoRecordTypes.contains(contract.RecordType.DeveloperName) && contract.RecordType.DeveloperName == 'Nego_Base') {
                                contractsNBConsoExistSet.add(contract.Id);
                                wContract.isConsoNegoBase = true;
                                wContract.contractNegoBase = contract;
                                contractSet.add(contract.Id);
                            }
                            if (consoRecordTypes.contains(contract.RecordType.DeveloperName) && wContract.contractNegoBaseInit == null && contract.RecordType.DeveloperName == 'Nego_Base_Init') {
                                wContract.isConsoNegoBaseInit = true;
                                wContract.contractNegoBaseInit = contract;
                                contractSet.add(contract.Id);
                            }
                            // case conso NB, get all NBI for check excluded discounts
                            if(consoRecordTypes.contains('Nego_Base') && contract.RecordType.DeveloperName == 'Nego_Base_Init') {
                                contractSet.add(contract.Id);
                            }
                        }
                        if (wContract.contractPT == null && contract.RecordType.DeveloperName == 'Period_Extension') {
                            wContract.contractPT = contract;
                            contractSet.add(contract.Id);
                        }
                        if (wContract.contractNego == null && contract.Is_OnTop_Simulation__c == true) {
                            wContract.contractNego = contract;
                            contractSet.add(contract.Id);
                        }
                        wContractsMap.put(key, wContract);
                    }
                }
            }
       		// check security on NegoScope__c fields
        	String[] negoscopeFields = new String[] {
           		SObjectType.NegoScope__c.fields.NegoScopeParent__c.Name
        	};
       		// check security on Contract__c fields
        	String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Is_Conso_Requiered__c.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.RecordtypeId.Name,
                SObjectType.Contract__c.fields.Total_TO__c.Name,
                SObjectType.Contract__c.fields.Total_TO_Tariff_Nego__c.Name
            };
       		// check security on Contract_Discount__c fields
            String[] contractDiscountFields = new String[] {
               SObjectType.Contract_Discount__c.fields.Id.Name,
               SObjectType.Contract_Discount__c.fields.Name.Name,
               SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name,
               SObjectType.Contract_Discount__c.fields.CurrencyIsoCode.Name,
               SObjectType.Contract_Discount__c.fields.Respects_Contract_Scope__c.Name,
               SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name,
               SObjectType.Contract_Discount__c.fields.Is_Tariff_Condition__c.Name,
               SObjectType.Contract_Discount__c.fields.Index__c.Name,
               SObjectType.Contract_Discount__c.fields.all_BU__c.Name,
               SObjectType.Contract_Discount__c.fields.all_items__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_Calculation_Model__c.Name,
               SObjectType.Contract_Discount__c.fields.comments__c.Name,
               SObjectType.Contract_Discount__c.fields.YTD_Nego__c.Name,
               //SObjectType.Contract_Discount__c.fields.Y_Actu__c.Name,
               //SObjectType.Contract_Discount__c.fields.Value_per_fact__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Calc_Method_TO_Origin__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_Redistribution_Model__c.Name,
               SObjectType.Contract_Discount__c.fields.RecordTypeId.Name,
               SObjectType.Contract_Discount__c.fields.Prog_TO_Nego__c.Name,
               SObjectType.Contract_Discount__c.fields.Prog_TO_Actu__c.Name,
               SObjectType.Contract_Discount__c.fields.Maximum_Guarantee__c.Name,
               SObjectType.Contract_Discount__c.fields.Is_Prenego_Envelop__c.Name,
               SObjectType.Contract_Discount__c.fields.Invoicing_plan_generated__c.Name,
               SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
               SObjectType.Contract_Discount__c.fields.commercial_reference__c.Name,
               SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
               SObjectType.Contract_Discount__c.fields.OriginFromMove_Condition__c.Name,
               SObjectType.Contract_Discount__c.fields.Contract__c.Name,
               SObjectType.Contract_Discount__c.fields.Reference_Condition__c.Name,
               SObjectType.Contract_Discount__c.fields.Contract_Group__c.Name,
               //SObjectType.Contract_Discount__c.fields.Contract_Group_Reference__c.Name,
               SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
               SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
               SObjectType.Contract_Discount__c.fields.financial_reference__c.Name,
               SObjectType.Contract_Discount__c.fields.first_invoice_date__c.Name,
               SObjectType.Contract_Discount__c.fields.Fist_Provision_Date__c.Name,
               SObjectType.Contract_Discount__c.fields.Invoice_base__c.Name,
               SObjectType.Contract_Discount__c.fields.Invoice_period__c.Name,
               SObjectType.Contract_Discount__c.fields.Is_Conditional__c.Name,
               SObjectType.Contract_Discount__c.fields.is_Duplicable__c.Name,
               SObjectType.Contract_Discount__c.fields.Is_Duplicable_PE__c.Name,
               SObjectType.Contract_Discount__c.fields.legal_reference__c.Name,
               SObjectType.Contract_Discount__c.fields.Minimum_Guarantee__c.Name,
               SObjectType.Contract_Discount__c.fields.Name.Name,
               SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
               SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name,
               SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
               SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
               SObjectType.Contract_Discount__c.fields.Provision_base__c.Name,
               SObjectType.Contract_Discount__c.fields.Provision_period__c.Name,
               SObjectType.Contract_Discount__c.fields.Provision_Sequence__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M12__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M11__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M10__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M9__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M8__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M7__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M6__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M5__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M4__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M3__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M2__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_disp_M1__c.Name,
               SObjectType.Contract_Discount__c.fields.Rank__c.Name,
               SObjectType.Contract_Discount__c.fields.Reference_Contract__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_1__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_2__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_3__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_4__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_5__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_6__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_calc_method__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_1__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_2__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_3__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_4__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_5__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_per_6__c.Name,
               SObjectType.Contract_Discount__c.fields.slab_target__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_1__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_2__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_3__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_4__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_5__c.Name,
               SObjectType.Contract_Discount__c.fields.Slab_Val_6__c.Name,
               SObjectType.Contract_Discount__c.fields.Status__c.Name,
               SObjectType.Contract_Discount__c.fields.Status_BDate__c.Name,
               SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
               SObjectType.Contract_Discount__c.fields.Valid__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_Per__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_per_Y2__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_per_Y3__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_per_Y4__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_per_Y5__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_Y2__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_Y3__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_Y4__c.Name,
               SObjectType.Contract_Discount__c.fields.Value_amt_Y5__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_TO_Actual__c.Name,
               SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
               SObjectType.Contract_Discount__c.fields.Invoice_sequence__c.Name
             };
            if (!contractSet.isEmpty()) {
                if (NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, contractDiscountFields) &&
                    NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, staticPolComConditionFields) &&
                    NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoscopeFields) &&
                    NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields))
                {
                    if (isConsoNegoBase || !contractsNBConsoExistSet.isEmpty()) {
                        if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionFields)) {
                            String polSalesConditionExceptionQuery = 'SELECT Id, Name, Contract__r.Reference_Year__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.BusinessUnitContract__c,';
                            polSalesConditionExceptionQuery += ' ' + String.join(polSaleConditionExceptionFields, ',') + ' FROM Pol_Sale_Condition_Exception__c';
                            polSalesConditionExceptionQuery += ' WHERE Contract__c IN (\'' + String.join(new List<Id>(contractSet), '\',\'') +'\')';
                            polSalesConditionExceptionQuery += ' AND (Contract__r.Is_OnTop_Simulation__c = TRUE OR Contract__r.RecordType.DeveloperName = \'Nego_Base\')';
                            for (Pol_Sale_Condition_Exception__c item : Database.query(polSalesConditionExceptionQuery)) {
                                String contractKey = Integer.valueOf(item.Contract__r.Reference_Year__c) + '' + item.Contract__r.Supplier_Nego_Scope__c + '' + item.Contract__r.BusinessUnitContract__c;
                                if (wContractsMap.containsKey(contractKey)) {
                                    ContractConsoWrapper wContract = wContractsMap.get(contractKey);
                                    wContract.polSalesConditionExceptionsMap.put(item.Contract__c, item);
                                }
                            }
                        }
                    }
                    ////DateTime topContractEndDate = DateTime.newInstance(year, 12, 31);
                    // get all Conditions PT/Nego/Landing
                    String conditionQuery = 'SELECT Id, Name, YTD_Nego__c, Index__c, Respects_Contract_Scope__c, Contract__c, Product_Scope__r.SegmentationAttribut3__c,';
                    conditionQuery += ' Condition_Type__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.') + ',';
                    conditionQuery += ' Condition_Type__r.Duplication_Discount_Mapping__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.Duplication_Discount_Mapping__r.') + ',';
                    conditionQuery += ' OriginFromMove_Condition__r.' + String.join(staticPolComConditionFields, ', OriginFromMove_Condition__r.') + ',';
                    conditionQuery += ' OriginFromMove_Condition__r.Duplication_Discount_Mapping__r.' + String.join(staticPolComConditionFields, ', OriginFromMove_Condition__r.Duplication_Discount_Mapping__r.') + ',';
                    conditionQuery += ' TargetToMove_Condition__r.' + String.join(staticPolComConditionFields, ', TargetToMove_Condition__r.') + ',';
                    conditionQuery += ' TargetToMove_Condition__r.Duplication_Discount_Mapping__r.' + String.join(staticPolComConditionFields, ', TargetToMove_Condition__r.Duplication_Discount_Mapping__r.') + ',';
                    conditionQuery += ' Contract__r.Reference_Year__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.BusinessUnitContract__c, Contract__r.RecordType.DeveloperName, Contract__r.Total_TO__c, Contract__r.Total_TO_Tariff_Nego__c,';
                    conditionQuery += ' Contract__r.Name, Contract__r.Supplier_Nego_Scope__r.Name, Contract__r.Is_OnTop_Simulation__c, Is_conditional__c,';
                    conditionQuery += ' ' + String.join(conditionsFields, ',');
                    conditionQuery += ' FROM Contract_Discount__c';
                    conditionQuery += ' WHERE Parent_Discount__c = NULL AND Product_Scope__c <> NULL AND BusinessUnitScope__c <> NULL';
                    conditionQuery += ' AND Contract__c IN (\'' + String.join(new List<Id>(contractSet), '\',\'') +'\')';
                    conditionQuery += ' AND (Contract__r.RecordType.DeveloperName <> \'Period_Extension\' OR Condition_Type__r.Is_Yearly_Condition__c = FALSE)';
                    ////conditionQuery += ' AND (Contract__r.Is_OnTop_Simulation__c = FALSE OR Disc_EDate__c = ' + topContractEndDate.format('yyyy-MM-dd') +')';
                    conditionQuery += ' AND Status__c <> \'Deleted\'';
                    conditionQuery += ' ORDER BY Contract__c, Display_Order__c, Disc_BDate__c';
                    System.debug('conditionQuery >>> ' + conditionQuery);
                    List<Contract_Discount__c> discountsList = Database.query(conditionQuery);
                    Map<Id, Pol_Com_Condition__c> discountsEGA1Map = new Map<Id, Pol_Com_Condition__c>();
                    Map<String, List<Id>> tariffConditionEGA1Map = new Map<String, List<Id>>();
                    Set<String> tariffConditionEGA1IdsSet = new Set<String>();
                    Set<String> tariffConditionEGA1CodesSet = new Set<String>();
                    Map<Id, List<Pol_Com_Condition__c>> parentTariffConditionEGA1Map = new Map<Id, List<Pol_Com_Condition__c>> ();
                    Map<String, String> tariffConditionsForPrestationNBMap = new Map<String, String>(); // list of code cudget changing in prestation NB
                    Set<Id> parentDiscountSet = new Set<Id>();
                    for (Contract_Discount__c item : discountsList) {
                        // check EGA1
                        if(item.Product_Scope__r.SegmentationAttribut3__c == 'Value2'
                           && item.Condition_Type__r.isSet(SObjectType.Pol_Com_Condition__c.fields.Original_code__c.Name)
                           && String.isNotBlank(item.Condition_Type__r.Original_code__c))
                        {
                            if(!tariffConditionEGA1Map.containsKey(item.Condition_Type__r.Original_code__c)) tariffConditionEGA1Map.put(item.Condition_Type__r.Original_code__c, new List<Id>());
                            tariffConditionEGA1Map.get(item.Condition_Type__r.Original_code__c).add(item.Id);
                            if(NegoptimHelper.validateId(item.Condition_Type__r.Original_code__c)) {
                                tariffConditionEGA1IdsSet.add(item.Condition_Type__r.Original_code__c);
                            } else {
                                tariffConditionEGA1CodesSet.add(item.Condition_Type__r.Original_code__c);
                            }
                        }
                        // get list of code budget changing in prestation NB (Original_Name__c (JCS), Id (SCJ))
                        if(String.isNotBlank(item.Condition_Type__r.Original_Name__c) && item.Contract__r.Is_OnTop_Simulation__c) { // NEG-9373
                            tariffConditionsForPrestationNBMap.put(item.Condition_Type__r.Original_Name__c, item.Condition_Type__r.Name); // JCS => SCJ
                        }
                        parentDiscountSet.add(item.Id);
                    }
                    Map<Id, List<Contract_Discount__c>> subDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
                    if(!parentDiscountSet.isEmpty()) {
                        // get all Sub Conditions
                        String subConditionQuery = ' SELECT Id, Name, Contract__c,';
                        subConditionQuery += ' Condition_Type__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.') + ',';
                        subConditionQuery += ' Condition_Type__r.Duplication_Discount_Mapping__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.Duplication_Discount_Mapping__r.') + ',';
                        subConditionQuery += ' ' + String.join(conditionsFields, ',') + ', Is_conditional__c';
                        subConditionQuery += ' FROM Contract_Discount__c';
                        subConditionQuery += ' WHERE Status__c <> \'Deleted\'';
                        subConditionQuery += ' AND Parent_Discount__c IN (\'' + String.join(new List<Id>(parentDiscountSet), '\',\'') +'\')';
                        subConditionQuery += ' AND (Contract__r.RecordType.DeveloperName <> \'Period_Extension\' OR Condition_Type__r.Is_Yearly_Condition__c = FALSE)';
                        List<Contract_Discount__c> subDiscountsList = Database.query(subConditionQuery);
                        for (Contract_Discount__c item : subDiscountsList) {
                            if(!subDiscountsMap.containsKey(item.Parent_Discount__c)) subDiscountsMap.put(item.Parent_Discount__c, new List<Contract_Discount__c>());
                            subDiscountsMap.get(item.Parent_Discount__c).add(item);
                        }
                    }
                    if(!tariffConditionEGA1Map.isEmpty()) {
                        String tariffConditionQuery = 'SELECT ' + String.join(staticPolComConditionFields, ',') + ',';
                        tariffConditionQuery += ' (SELECT ' + String.join(staticPolComConditionFields, ',') + ' FROM Pol_Com_Conditions__r ORDER BY Name)';
                        tariffConditionQuery += ' FROM Pol_Com_Condition__c';
                        tariffConditionQuery += ' WHERE Condition_status__c <> \'Close\'';
                        tariffConditionQuery += ' AND (Id IN (\'' + String.join(new List<String>(tariffConditionEGA1IdsSet), '\',\'') +'\')';
                        tariffConditionQuery += ' OR Condition_Code__c IN (\'' + String.join(new List<String>(tariffConditionEGA1CodesSet), '\',\'') +'\'))';
                        System.debug('tariffConditionQuery >>> ' + tariffConditionQuery);
                        for(Pol_Com_Condition__c item : Database.query(tariffConditionQuery)) {
                            if(tariffConditionEGA1Map.containsKey(item.Id)) {
                                for(Id discountId : tariffConditionEGA1Map.get(item.Id)) {
                                    discountsEGA1Map.put(discountId, item);
                                }
                            }
                            if(String.isNotBlank(item.Condition_Code__c) && tariffConditionEGA1Map.containsKey(item.Condition_Code__c)) {
                                for(Id discountId : tariffConditionEGA1Map.get(item.Condition_Code__c)) {
                                    discountsEGA1Map.put(discountId, item);
                                }
                            }
                            for (Pol_Com_Condition__c child : item.Pol_Com_Conditions__r) {
                                if (!parentTariffConditionEGA1Map.containsKey(item.Id)) parentTariffConditionEGA1Map.put(item.Id, new List<Pol_Com_Condition__c>());
                                parentTariffConditionEGA1Map.get(item.Id).add(child);
                            }
                        }
                    }
                    for (Contract_Discount__c item : discountsList) {
                        String contractKey = Integer.valueOf(item.Contract__r.Reference_Year__c) + '' + item.Contract__r.Supplier_Nego_Scope__c + '' + item.Contract__r.BusinessUnitContract__c;
                        if (wContractsMap.containsKey(contractKey)) {
                            ContractConsoWrapper wContract = wContractsMap.get(contractKey);
                            Pol_Com_Condition__c tariffCondition = (discountsEGA1Map.containsKey(item.Id) ? discountsEGA1Map.get(item.Id)
                                                                                   : item.Condition_Type__r.Duplication_Discount_Mapping__c != null ? item.Condition_Type__r.Duplication_Discount_Mapping__r
                                                                                   : item.Condition_Type__r);
                            if (wContract.contractPT != null && wContract.contractPT.Id == item.Contract__c) {
                                /*if (item.TargetToMove_Condition__c != null) {
                                    tariffCondition = item.TargetToMove_Condition__r.Duplication_Discount_Mapping__c != null ? item.TargetToMove_Condition__r.Duplication_Discount_Mapping__r : item.TargetToMove_Condition__r;
                                } else if (item.OriginFromMove_Condition__c != null) {
                                    tariffCondition = item.OriginFromMove_Condition__r.Duplication_Discount_Mapping__c != null ? item.OriginFromMove_Condition__r.Duplication_Discount_Mapping__r : item.OriginFromMove_Condition__r;
                                }*/
                            } else if (wContract.contractNegoBase != null && wContract.contractNegoBase.Id == item.Contract__c && item.OriginFromMove_Condition__c != null) {
                                // check move conditions from Nego_Base_Init to Nego_Base
                                ////tariffCondition = item.OriginFromMove_Condition__r.Duplication_Discount_Mapping__c != null ? item.OriginFromMove_Condition__r.Duplication_Discount_Mapping__r : item.OriginFromMove_Condition__r;
                            }
                            Boolean isUnicity = tariffCondition.Is_Contract_Unicity_Requiered__c;
                            String conditionKey = tariffCondition.Id + '' + item.BusinessUnitScope__c + '' + item.Product_Scope__c;
                            ConditionConsoWrapper wCondition;
                            if (!wContract.conditionsMap.containskey(conditionKey)) {
                                wCondition = new ConditionConsoWrapper(wContract, conditionsFields, tariffCondition, isUnicity);
                                wCondition.subDiscountsMap = subDiscountsMap;
                            } else {
                                wCondition = wContract.conditionsMap.get(conditionKey);
                            }
                            if(discountsEGA1Map.containsKey(item.Id)) {
                                wCondition.isEGA1 = true;
                                if(parentTariffConditionEGA1Map.containsKey(tariffCondition.Id)) {
                                    for (Pol_Com_Condition__c child : parentTariffConditionEGA1Map.get(tariffCondition.Id)) {
                                        wCondition.subTariffConditionEGA1Map.put(child.Id, child);
                                        if(child.Condition_Code__c != null) wCondition.subTariffConditionEGA1Map.put(child.Condition_Code__c, child);
                                    }
                                }
                            }
                            if(isConsoNegoBaseExit) {
                                // get existing NegoBaseExit conditions
                                if (wContract.contractNegoBaseExit != null && wContract.contractNegoBaseExit.Id == item.Contract__c) {
                                    wCondition.conditionNegoBaseExits.add(new ConditionWrapper(item));
                                    wCondition.conditionConsosMap.put(item.Id, false);
                                }
                            } else {
                                // get existing Landing conditions
                                if (wContract.isConsoLanding && wContract.contractLanding != null && wContract.contractLanding.Id == item.Contract__c) {
                                    wCondition.conditionLandings.add(new ConditionWrapper(item));
                                    wCondition.conditionConsosMap.put(item.Id, false);
                                }
                                // get existing NegoBase conditions
                                if (wContract.isConsoNegoBase && wContract.contractNegoBase != null) {
                                    if(wContract.contractNegoBase.Id == item.Contract__c) {
                                        // check Move Conditions
                                        if (item.OriginFromMove_Condition__c != null) {
                                            wCondition.isMoveNB = true;
                                            if (isUnicity) {
                                                wContract.conditionUnicityForNBSet.add(item.Condition_Type__c + '' + item.BusinessUnitScope__c + '' + item.Product_Scope__c);
                                            }
                                        } else if(!tariffConditionsForPrestationNBMap.isEmpty()
                                                  && tariffConditionsForPrestationNBMap.containsKey(tariffCondition.Name)) // => check if JCS exist in NegoBase
                                        {
                                            // check if code budget exist in prestation NB
                                            wContract.tariffCoditionChangedInPrestationsNBSet.add(tariffCondition.Name);
                                            wContract.tariffCoditionChangedInPrestationsNBSet.add(tariffConditionsForPrestationNBMap.get(tariffCondition.Name));
                                        } else if(item.Exclusion_to_Nego_Base_Value__c != null) {
                                            wCondition.isExcludedToNegoBaseInit = true;
                                        } else if (item.Reference_condition__c == null) {
                                            wCondition.isNewNB = true;
                                        } else {
                                            wCondition.conditionNegoBases.add(new ConditionWrapper(item));
                                            wCondition.conditionConsosMap.put(item.Id, false);
                                        }
                                    } else if(item.Contract__r.RecordType.DeveloperName == 'Nego_Base_Init'
                                              && (item.Is_Excluded_To_NegoBase__c == true || item.Is_Excluded_To_Nego_Base_F__c == true || item.Is_Excluded_To_Nego_Base_U__c == true))
                                    {
                                        // case conso NB, get all NBI for check excluded discounts
                                        wCondition.isExcludedToNegoBaseInit = true;
                                    }
                                }
                                // get existing NegoBaseInit conditions
                                if (wContract.isConsoNegoBaseInit && wContract.contractNegoBaseInit != null && wContract.contractNegoBaseInit.Id == item.Contract__c) {
                                    if (item.Is_TargetToMove__c == true && item.TargetToMove_Condition__c != null) {
                                        wCondition.isMoveNBI = true;
                                    } else if(item.Is_Excluded_To_NegoBase__c == true || item.Is_Excluded_To_Nego_Base_F__c == true || item.Is_Excluded_To_Nego_Base_U__c == true) {
                                        wCondition.isExcludedToNegoBaseInit = true;
                                    } else if (item.Reference_condition__c == null) {
                                        wCondition.isNewNBI = true;
                                    } else {
                                        wCondition.conditionNegoBaseInits.add(new ConditionWrapper(item));
                                        wCondition.conditionConsosMap.put(item.Id, false);
                                    }
                                }
                            }
                            // get all PT conditions
                            if (wContract.contractPT != null && wContract.contractPT.Id == item.Contract__c) {
                                wCondition.conditionPTList.add(item);
                                // Fill origin set for PT
                                /*if (item.OriginFromMove_ContractDiscount__c != null) {
                                    originFromMoveContractDiscountSet.add(item.OriginFromMove_ContractDiscount__c);
                                }*/
                            }
                            // get all Nego conditions
                            if (wContract.contractNego != null && wContract.contractNego.Id == item.Contract__c) {
                                wCondition.conditionNegoList.add(item);
                            }
                            wContract.conditionsMap.put(conditionKey, wCondition);
                        }
                    }
                    //AZ
                    for (String contractKey : wContractsMap.keySet()) {
                        ContractConsoWrapper wContract = wContractsMap.get(contractKey);
                        for (String conditionKey : wContract.conditionsMap.keySet()) {
                            ConditionConsoWrapper wCondition = wContract.conditionsMap.get(conditionKey);
                            List<Contract_Discount__c> hasMappingConditions = new List<Contract_Discount__c>();
                            for (Integer index = 0; index < wCondition.conditionNegoList.size(); index++) {
                                Contract_Discount__c item = wCondition.conditionNegoList[index];
                                if (item.Condition_Type__r.Duplication_Discount_Mapping__c != null) {
                                    wCondition.conditionNegoList.remove(index);
                                    index--;
                                    hasMappingConditions.add(item);
                                }
                            }
                            wCondition.conditionNegoList.addAll(hasMappingConditions);
                        }
                    }
                    /*if (!originFromMoveContractDiscountSet.isEmpty()) {
                        // get all conditions
                        string originConditionQuery = 'SELECT Id, Contract__c, Respects_Contract_Scope__c, Index__c, YTD_Nego__c,';
                        originConditionQuery += ' Contract__r.Reference_Year__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.BusinessUnitContract__c,';
                        originConditionQuery += ' Condition_Type__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.') + ',';
                        originConditionQuery += ' OriginFromMove_Condition__r.' + String.join(staticPolComConditionFields, ', OriginFromMove_Condition__r.') + ',';
                        originConditionQuery += ' ' + String.join(conditionsFields, ',') + ',';
                        originConditionQuery += ' (SELECT Id, Respects_Contract_Scope__c,';
                        originConditionQuery += ' ' + String.join(conditionsFields, ',') + ',';
                        originConditionQuery += ' Condition_Type__r.' + String.join(staticPolComConditionFields, ', Condition_Type__r.');
                        originConditionQuery += ' FROM Children_Contract_Discount__r WHERE Status__c <> \'Deleted\')';
                        originConditionQuery += ' FROM Contract_Discount__c WHERE Status__c <> \'Deleted\' AND Product_Scope__r.Status__c = \'Active\' AND BusinessUnitScope__r.Status__c = \'Open\'';
                        originConditionQuery += ' AND Id IN (\'' + String.join(new List<Id>(originFromMoveContractDiscountSet), '\',\'') +'\')';
                        for (Contract_Discount__c item : Database.query(originConditionQuery)) {
                            String contractKey = Integer.valueOf(item.Contract__r.Reference_Year__c + 1) + '' + item.Contract__r.Supplier_Nego_Scope__c + '' + item.Contract__r.BusinessUnitContract__c;
                            if (wContractsMap.containsKey(contractKey)) {
                                ContractConsoWrapper wContract = wContractsMap.get(contractKey);
                                wContract.originFromMoveContractDiscountMap.put(item.Id, item);
                            }
                        }
                    }*/
                }
            }
            List<Contract__c> contractUpsertedList = new List<Contract__c>();
            List<ConditionWrapper> parentConditionWrapperList = new List<ConditionWrapper>();
            List<Contract_Discount__c> parentConditionUpsertedList = new List<Contract_Discount__c>();
            List<Contract_Discount__c> parentConditionDeletedList = new List<Contract_Discount__c>();
            List<Contract_Discount__c> subConditionDeletedList = new List<Contract_Discount__c>();
            List<Pol_Sale_Condition_Exception__c> polSalesConditionExceptionUpsertedList = new List<Pol_Sale_Condition_Exception__c>();
            // consolidate PT and Nego Contracts
            for (String key : wContractsMap.keySet()) {
                ContractConsoWrapper wContract = wContractsMap.get(key);
                wContract.consolidateContract();
                if(isConsoNegoBaseExit) {
                    // upsert NegoBase Exit contract
                    if (wContract.contractNegoBaseExit != null) {
                        contractUpsertedList.add(wContract.contractNegoBaseExit);
                    }
                } else {
                    // upsert Landing contract
                    if (wContract.isConsoLanding && wContract.contractLanding != null) {
                        contractUpsertedList.add(wContract.contractLanding);
                    }
                    // upsert NegoBase contract
                    if (wContract.isConsoNegoBase && wContract.contractNegoBase != null) {
                        contractUpsertedList.add(wContract.contractNegoBase);
                    }
                    // upsert NegoBase Init contract
                    if (wContract.isConsoNegoBaseInit && wContract.contractNegoBaseInit != null) {
                        contractUpsertedList.add(wContract.contractNegoBaseInit);
                    }
                }
                if (wContract.contractLanding != null
                    || wContract.contractNegoBase != null
                    || wContract.contractNegoBaseInit != null
                    || wContract.contractNegoBaseExit != null)
                {
                    if(!isConsoNegoBaseExit) {
                        if (wContract.contractNego != null && wContract.contractNego.Is_Conso_Requiered__c == true && !contractUpsertedList.contains(wContract.contractNego)) {
                            wContract.contractNego.Is_Conso_Requiered__c = false;
                            contractUpsertedList.add(wContract.contractNego);
                        }
                        if (wContract.contractPT != null && wContract.contractPT.Is_Conso_Requiered__c == true && !contractUpsertedList.contains(wContract.contractPT)) {
                            wContract.contractPT.Is_Conso_Requiered__c = false;
                            contractUpsertedList.add(wContract.contractPT);
                        }
                    }
                    /*if ((wContract.contractNegoBaseInit != null && wContract.contractNegoBaseInit.Status__c == 'Validated')
                        || (wContract.contractNegoBase != null && wContract.contractNegoBase.Status__c == 'Validated'))
                        continue;*/
                    // consolidate conditions
                    wContract.consolidateConditions();
                    // check deleted parent conditions
                    if (!wContract.parentConditionsDeletedList.isEmpty()) {
                        parentConditionDeletedList.addAll(wContract.parentConditionsDeletedList);
                    }
                    // check deleted sub conditions
                    if (!wContract.subConditionsDeletedList.isEmpty()) {
                        subConditionDeletedList.addAll(wContract.subConditionsDeletedList);
                    }
                }
            }
            // save Consolidated Contracts
            Set<Id> contractUpsertedSet = new Set<Id>();
            List<Contract__c> contractNBs = new List<Contract__c>();
            if (!contractUpsertedList.isEmpty()) {
                // check security on upsert Contract__c fields
                String[] contractUpsertFields = new String[] {
                    SObjectType.Contract__c.fields.Name.Name,
                    SObjectType.Contract__c.fields.RecordTypeId.Name,
                    SObjectType.Contract__c.fields.Parent_Contract__c.Name,
                    SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                    SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                    SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                    SObjectType.Contract__c.fields.Contract_EDate__c.Name,
					SObjectType.Contract__c.fields.BusinessUnitSource__c.Name,
                    SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                    SObjectType.Contract__c.fields.Contract_Type__c.Name,
                    SObjectType.Contract__c.fields.Status__c.Name,
                    SObjectType.Contract__c.fields.Supplier__c.Name,
                    SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                    SObjectType.Contract__c.fields.CompanySigned_By__c.Name,
                    SObjectType.Contract__c.fields.TO1__c.Name,
                    SObjectType.Contract__c.fields.TO2__c.Name,
                    SObjectType.Contract__c.fields.TO3__c.Name,
                    SObjectType.Contract__c.fields.TO4__c.Name,
                    SObjectType.Contract__c.fields.TO5__c.Name,
                    SObjectType.Contract__c.fields.TO6__c.Name,
                    SObjectType.Contract__c.fields.TO7__c.Name,
                    SObjectType.Contract__c.fields.TO8__c.Name,
                    SObjectType.Contract__c.fields.TO9__c.Name,
                    SObjectType.Contract__c.fields.TO10__c.Name,
                    SObjectType.Contract__c.fields.TO11__c.Name,
                    SObjectType.Contract__c.fields.TO12__c.Name,
                    // SObjectType.Contract__c.fields.TO1_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO2_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO3_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO4_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO5_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO6_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO7_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO8_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO9_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO10_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO11_Fact__c.Name,
                    // SObjectType.Contract__c.fields.TO12_Fact__c.Name,
                    SObjectType.Contract__c.fields.Qty1__c.Name,
                    SObjectType.Contract__c.fields.Qty2__c.Name,
                    SObjectType.Contract__c.fields.Qty3__c.Name,
                    SObjectType.Contract__c.fields.Qty4__c.Name,
                    SObjectType.Contract__c.fields.Qty5__c.Name,
                    SObjectType.Contract__c.fields.Qty6__c.Name,
                    SObjectType.Contract__c.fields.Qty7__c.Name,
                    SObjectType.Contract__c.fields.Qty8__c.Name,
                    SObjectType.Contract__c.fields.Qty9__c.Name,
                    SObjectType.Contract__c.fields.Qty10__c.Name,
                    SObjectType.Contract__c.fields.Qty11__c.Name,
                    SObjectType.Contract__c.fields.Qty12__c.Name,
                    // SObjectType.Contract__c.fields.Qty1_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty2_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty3_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty4_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty5_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty6_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty7_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty8_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty9_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty10_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty11_Fact__c.Name,
                    // SObjectType.Contract__c.fields.Qty12_Fact__c.Name,
                    SObjectType.Contract__c.fields.Total_TO_Nego_YearBase__c.Name,
                    SObjectType.Contract__c.fields.Is_Conso_Requiered__c.Name,
                    SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name
                };
                if (NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractUpsertFields) &&
                    NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpsertFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(contractUpsertedList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Contract__c contract = contractUpsertedList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += (startedFromBatch ? contract + '\n' : '');
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                errorMessages.add(errorMessage);
                                System.debug('errorMessage >>> ' + errorMessage);
                            }
                        } else {
                            contractUpsertedSet.add(contract.Id);
                            String key = contract.Contract_BDate__c.year() + '' + contract.Supplier_Nego_Scope__c + '' + contract.BusinessUnitContract__c;
                            if (wContractsMap.containsKey(key)) {
                                ContractConsoWrapper wContract = wContractsMap.get(key);
                                // assign Contract Id to parent Condition
                                if (wContract.parentConditionConsoMap.containsKey(contract.RecordTypeId)) {
                                    Map<String, List<ConditionWrapper>> parentConditionsMap = wContract.parentConditionConsoMap.get(contract.RecordTypeId);
                                    for (String conditionKey : parentConditionsMap.keySet()) {
                                        List<ConditionWrapper> parentConditions = parentConditionsMap.get(conditionKey);
                                        for (ConditionWrapper item : parentConditions) {
                                            if (item.conditionConso.Contract__c == null) {
                                                item.conditionConso.Contract__c = contract.Id;
                                            }
                                            parentConditionUpsertedList.add(item.conditionConso);
                                            parentConditionWrapperList.add(item);
                                        }
                                    }
                                }
                                // upsert Pol_Sale_Condition_Exception__c
                                if (wContract.isConsoNegoBase && contract.RecordTypeId == contractRTIds.get('Nego_Base') && wContract.polSalesConditionExceptionForNegoBase != null) {
                                    if (wContract.polSalesConditionExceptionForNegoBase.Contract__c == null) {
                                        wContract.polSalesConditionExceptionForNegoBase.Contract__c = contract.Id;
                                    }
                                    wContract.polSalesConditionExceptionForNegoBase.Ext_id__c = contract.Ext_id__c;
                                    wContract.polSalesConditionExceptionForNegoBase.Ext_Id2__c = contract.Ext_id__c;
                                    polSalesConditionExceptionUpsertedList.add(wContract.polSalesConditionExceptionForNegoBase);
                                }
                                // synchro NBI to NB
                                if (isValidatedNegoBaseInit && contract.RecordTypeId == contractRTIds.get('Nego_Base')) {
                                    contractNBs.add(contract);
                                }
                            }
                        }
                    }
                }
            }
            // upsert Pol_Sale_Condition_Exception__c
            if (!polSalesConditionExceptionUpsertedList.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionFields)
                   && NegoptimHelper.checkUpdatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(polSalesConditionExceptionUpsertedList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Pol_Sale_Condition_Exception__c polSalesConditionException = polSalesConditionExceptionUpsertedList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += (startedFromBatch ? polSalesConditionException + '\n' : '');
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                errorMessages.add(errorMessage);
                            }
                        }
                    }
                }
            }
            Map<Id, List<Contract_Discount__c>> parentConditionsUpsertedMap = new Map<Id, List<Contract_Discount__c>>();
            Set<Id> parentConditionsSet = new Set<Id>();
            // save consolidated Conditions
            if (!parentConditionUpsertedList.isEmpty() || !parentConditionDeletedList.isEmpty()) {
                // check security on upsert Contract_Discount__c fields
                String[] conditionUpdatedFields = new String[] {
                    SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
                    SObjectType.Contract_Discount__c.fields.BusinessUnitScope__c.Name,
                    SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                    SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
                    SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
                    SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                    SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
                    SObjectType.Contract_Discount__c.fields.Value_Per__c.Name,
                    SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
                    SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.Name,
                    SObjectType.Contract_Discount__c.fields.unit_amount__c.Name,
                    SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
                    SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.Name,
                    SObjectType.Contract_Discount__c.fields.Base_TO_Tariff_Nego__c.Name,
                    SObjectType.Contract_Discount__c.fields.Rank__c.Name
                };
                String[] conditionInsertedFields = new String[] {
                    SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                    SObjectType.Contract_Discount__c.fields.Parent_Discount__c.Name
                };
                conditionInsertedFields.addAll(conditionUpdatedFields);
                if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionInsertedFields) &&
                    NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdatedFields))
                {
                    if (!parentConditionUpsertedList.isEmpty()) {
                        List<Contract_Discount__c> subConditionUpsertedList = new List<Contract_Discount__c>();
                        ////List<Contract_Discount__c> parentConditionSortList = ContractServices.sort(parentConditionUpsertedList, true, true);
                        List<Database.UpsertResult> results = Database.upsert(parentConditionUpsertedList, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.UpsertResult result = results.get(i);
                            Contract_Discount__c parentCondition = parentConditionUpsertedList.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                errorMessage += (startedFromBatch ? parentCondition + '\n' : '');
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    String msg = '' + err.getStatusCode();
                                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                        errorMessage += err.getMessage();
                                    } else {
                                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                    }
                                }
                                errorMessages.add(errorMessage);
                                System.debug('errorMessage >>> ' + errorMessage);
                            } else {
                                parentConditionsSet.add(parentCondition.Id);
                            }
                        }
                        // upsert sub conditions
                        for (ConditionWrapper item : parentConditionWrapperList) {
                            if (item.conditionConso.Id != null && !item.subConditions.isEmpty()) {
                                for (Contract_Discount__c subCondition : item.subConditions) {
                                    if (subCondition.Contract__c == null) {
                                        subCondition.Contract__c = item.conditionConso.Contract__c;
                                    }
                                    if (subCondition.Parent_Discount__c == null) {
                                        subCondition.Parent_Discount__c = item.conditionConso.Id;
                                    }
                                    subConditionUpsertedList.add(subCondition);
                                }
                            }
                        }
                        if (!subConditionUpsertedList.isEmpty()) {
                            List<Contract_Discount__c> subConditionsSortList = ContractServices.sort(subConditionUpsertedList, true, true);
                            results = Database.upsert(subConditionsSortList, false);
                            for (Integer i = 0; i < results.size(); i++) {
                                Database.UpsertResult result = results.get(i);
                                Contract_Discount__c subCondition = subConditionsSortList.get(i);
                                if (!result.isSuccess()) {
                                    String errorMessage = '';
                                    errorMessage += (startedFromBatch ? subCondition + '\n' : '');
                                    Database.Error[] errors = result.getErrors();
                                    for (Database.Error err : errors) {
                                        String msg = '' + err.getStatusCode();
                                        if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                            errorMessage += err.getMessage();
                                        } else {
                                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                        }
                                        errorMessages.add(errorMessage);
                                        System.debug('errorMessage >>> ' + errorMessage);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // synchro NBI to NB when NBI is validated
            if(isValidatedNegoBaseInit) {
                synchroContractNegoBaseInitToNegoBase(contractNBs);
            }
            // calculate contract and conditions Indexes
            contractUpsertedList = new List<Contract__c>();
            parentConditionUpsertedList = new List<Contract_Discount__c>();
            if (!contractUpsertedSet.isEmpty()) {
                for (Contract__c item : [SELECT Id, Name, RecordType.DeveloperName, Status__c, Supplier_Nego_Scope__c, BusinessUnitSource__c, BusinessUnitContract__c, Contract_BDate__c, Contract_EDate__c,
                                         Index1_v2_perc__c, Index2_v2_perc__c, Index3_v2_perc__c, Index4_v2_perc__c, Index5_v2_perc__c, Index6_v2_perc__c, Index7_v2_perc__c,
                                         Index1_v2__c, Index2_v2__c, Index3_v2__c, Index4_v2__c, Index5_v2__c, Index6_v2__c, Index7_v2__c,
                                         Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Index6_perc__c, Index7_perc__c,
                                         Index1__c, Index2__c, Index3__c, Index4__c, Index5__c, Index6__c, Index7__c, Depreciation_Rate_YE__c, Markdown_Rate_Break__c,
                                         Markdown_Rate_Promo__c, Markdown_Rate_Theft__c, Rise_Rate_YE__c, Total_TO__c, Total_TO_Tariff_Nego__c,
                                         TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c,
                                         Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c, IsCalculatedIndexV2__c,
                                         (SELECT Id, Display_Order__c, Contract__c, Parent_Discount__c, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c, Disc_EDate__c, Is_Excluded_To_NegoBase__c, Exclusion_to_Nego_Base_Value__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c,
                                          Index_perc__c, Index__c, Index_v2__c, Base_TO_Nego_YearBase__c, Is_Yearly_Condition__c, YTD_Nego_Computed__c, Index_val__c, Is_Tariff_Condition__c, Base_TO_Tariff_Nego__c,
                                          Rank__c, Status__c, Value_amt__c, unit_amount__c, Unit_Amount_Type__c, Base_Quantity_Nego__c, Value_Per__c, Base_TO_Nego__c, RecordTypeId, Condition_Type__r.Capture_Discount_Product_Level__c,
                                          Condition_Type__r.Index__c, Condition_Type__r.Name, Condition_Type__r.Nego_Discount_Type__c, Respects_Contract_Scope__c, YTD_Nego__c, slab_calc_method__c,
                                          Is_conditional__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c, Slab_8__c, Slab_9__c, Slab_10__c, slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,
                                          Slab_Val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c, Slab_Val_6__c, Slab_Val_7__c, Slab_Val_8__c, Slab_Val_9__c, Slab_Val_10__c, ContractSellIn__c
                                          FROM Contract_Discounts__r
                                          WHERE Parent_Discount__c = NULL
                                          AND Status__c <> 'Deleted'
                                          ORDER BY Contract__c, Display_Order__c ASC)
                                         FROM Contract__c
                                         WHERE Id IN :contractUpsertedSet
                                         AND RecordType.DeveloperName IN ('Landing', 'Nego_Base_Init', 'Nego_Base', 'Nego_Base_Exit')])
                {
                    if (item.RecordType.DeveloperName == 'Nego_Base_Exit') {
                        item.Status__c = 'Signed';
                    }
                    List<Contract_Discount__c> parentConditionsList = parentConditionsUpsertedMap.get(item.Id);
                    ContractServices contractService = new ContractServices(item, item.Contract_Discounts__r);
                    contractService.calculateContractIndex(false);
                    parentConditionUpsertedList.addAll(item.Contract_Discounts__r);
                    contractUpsertedList.add(item);
                }
                if (!contractUpsertedList.isEmpty() && !parentConditionUpsertedList.isEmpty()) {
                    //todo check updatability
                    List<Database.SaveResult> resultsIndex = Database.update(parentConditionUpsertedList, false);
                    for (Integer i = 0; i < resultsIndex.size(); i++) {
                        Database.SaveResult result = resultsIndex.get(i);
                        Contract_Discount__c condition = parentConditionUpsertedList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += (startedFromBatch ? condition + '\n' : '');
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                            }
                            errorMessages.add(errorMessage);
                            System.debug('errorMessage 1 >>> ' + errorMessage);
                        }
                    }
                    resultsIndex = Database.update(contractUpsertedList, false);
                    for (Integer i = 0; i < resultsIndex.size(); i++) {
                        Database.SaveResult result = resultsIndex.get(i);
                        Contract__c contract = contractUpsertedList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += (startedFromBatch ? contract + '\n' : '');
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                            }
                            errorMessages.add(errorMessage);
                            System.debug('errorMessage 2 >>> ' + errorMessage);
                        }
                    }
                }
            }
            if (!parentConditionDeletedList.isEmpty()) {
                List<Database.SaveResult> results = Database.update(parentConditionDeletedList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Contract_Discount__c condition = parentConditionDeletedList.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        errorMessage += (startedFromBatch ? condition + '\n' : '');
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            String msg = '' + err.getStatusCode();
                            if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                errorMessage += err.getMessage();
                            } else {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                        }
                        errorMessages.add(errorMessage);
                    }
                }
            }
            if (!subConditionDeletedList.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(Contract_Discount__c.SObjectType)) {
                    Database.DeleteResult[] results = Database.delete(subConditionDeletedList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.DeleteResult result = results.get(i);
                        Contract_Discount__c condition = subConditionDeletedList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            errorMessage += 'Error deleting condition (Id=' + condition.Id + ', Name=' + condition.Name + ') : ';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                            }
                            errorMessages.add(errorMessage);
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        System.debug('errorMessages >>> ' + errorMessages);
        return errorMessages;
    }
    /*
     * @description
     * Set status of Nego_Base Validated when Nego_Base_Init status validated
     * Update Value_amt__c in Contracts Discounts of Nego_Base_Init when validated
    */
    public static List<String> synchroContractNegoBaseInitToNegoBase(List<Contract__c> contractNBs) {
        List<String> errorMessages = new List<String>();
        List<Contract__c> contractsList = new List<Contract__c>();
        Map<String, Contract__c> negoBaseToUpdateMap = new Map<String, Contract__c>();
        // conditions of Nego_Base_Init contract
        Set<Id> negoBaseIdSet = new Set<Id>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        //key: scope, value: Contract Nego_Base_Init
        Map<String, Contract__c> negoBaseMap = new Map<String, Contract__c>();
        Map<String, Contract_Discount__c> negoBaseInitConditionsMap = new Map<String, Contract_Discount__c>();
        //key: scope, value: Contract Discount Nego_Base
        Map<String, Contract_Discount__c> negoBaseConditionsMap = new Map<String, Contract_Discount__c>();
        Map<Id, List<Contract_Discount__c>> subNegoBaseConditionsMap = new Map<Id, List<Contract_Discount__c>>();
        Map<Id, Integer> subNegoBaseConditionsWithAmountMap = new Map<Id, Integer>();
        //List of conditions to upsert
        List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
        List<Contract_Discount__c> conditionsToInsert = new List<Contract_Discount__c>();
        for (Contract__c item : contractNBs) {
            String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + item.Contract_BDate__c.year();
            negoBaseMap.put(key, item);
            negoBaseIdSet.add(item.Id);
            buIdSet.add(item.BusinessUnitContract__c);
            nsIdSet.add(item.Supplier_Nego_Scope__c);
            yearSet.add(item.Contract_BDate__c.year());
        }
        if (!buIdSet.isEmpty() && !nsIdSet.isEmpty() && !yearSet.isEmpty()) {
            List<String> conditionsFields = new List<String>();
            Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
            for (String fieldName : conditionFieldsMap.keySet()) {
                if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    conditionsFields.add(fieldName);
                }
            }
            List<String> contractReadFields = new List<String> {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Reference_Year__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractReadFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields))
            {
                String query = 'SELECT Id, RecordType.DeveloperName, BusinessUnitContract__c, Supplier_Nego_Scope__c, Reference_Year__c, Contract_BDate__c, Contract_EDate__c,';
                query += ' (SELECT Id, Condition_Type__r.Name, ' + String.join(conditionsFields, ',') + ',';
                query += ' Contract__r.BusinessUnitContract__c, Contract__r.Supplier_Nego_Scope__c, Contract__r.Reference_Year__c';
                query += ' FROM Contract_Discounts__r WHERE is_Duplicable__c = TRUE OR Parent_Discount__r.is_Duplicable__c = TRUE)';
                query += ' FROM Contract__c';
                query += ' WHERE (Id IN (\'' + String.join(new List<Id>(negoBaseIdSet), '\',\'') +'\') AND RecordType.DeveloperName = \'Nego_Base\')';
                query += ' OR (BusinessUnitContract__c IN (\'' + String.join(new List<Id>(buIdSet), '\',\'') +'\')';
                query += ' AND Supplier_Nego_Scope__c IN (\'' + String.join(new List<Id>(nsIdSet), '\',\'') +'\')';
                query += ' AND Reference_Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
                query += ' AND RecordType.DeveloperName = \'Nego_Base_Init\')';
                contractsList = Database.query(query);
                if (!contractsList.isEmpty()) {
                    for (Contract__c item : contractsList) {
                        if (item.RecordType.DeveloperName == 'Nego_Base') {
                            String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                            item.Status__c = 'Validated';
                            negoBaseToUpdateMap.put(key, item);
                        }
                        for (Contract_Discount__c condition : item.Contract_Discounts__r) {
                            String key = condition.BusinessUnitScope__c + '' + condition.Product_Scope__c + '' + condition.Reference_condition__c;
                            if (item.RecordType.DeveloperName == 'Nego_Base_Init') {
                                key += condition.Condition_Type__c;
                                if(condition.Parent_Discount__c == null) negoBaseInitConditionsMap.put(key, condition);
                            } else if (item.RecordType.DeveloperName == 'Nego_Base') {
                                key += (condition.OriginFromMove_Condition__c != null ? condition.OriginFromMove_Condition__c : condition.Condition_Type__c);
                                if(condition.Parent_Discount__c == null) {
                                    negoBaseConditionsMap.put(key, condition);
                                } else {
                                    if(!subNegoBaseConditionsMap.containsKey(condition.Parent_Discount__c)) subNegoBaseConditionsMap.put(condition.Parent_Discount__c, new List<Contract_Discount__c>());
                                    subNegoBaseConditionsMap.get(condition.Parent_Discount__c).add(condition);
                                    if(condition.Value_amt__c != null && condition.Value_amt__c != 0) {
                                        if(!subNegoBaseConditionsWithAmountMap.containsKey(condition.Parent_Discount__c)) subNegoBaseConditionsWithAmountMap.put(condition.Parent_Discount__c, 0);
                                        subNegoBaseConditionsWithAmountMap.put(condition.Parent_Discount__c, subNegoBaseConditionsWithAmountMap.get(condition.Parent_Discount__c) + 1);
                                    }
                                }
                            }
                        }
                    }
                    if (!negoBaseToUpdateMap.isEmpty()) {
                        List<String> contractUpdateFields = new List<String> {
                            SObjectType.Contract__c.fields.Status__c.Name
                        };
                        if (NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractUpdateFields)) {
                            List<Database.SaveResult> results = Database.update(negoBaseToUpdateMap.values(), false);
                            for (Integer i = 0; i < results.size(); i++) {
                                Database.SaveResult result = results.get(i);
                                if (!result.isSuccess()) {
                                    String errorMessage = '';
                                    Database.Error[] errors = result.getErrors();
                                    for (Database.Error err : errors) {
                                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                    }
                                    Contract__c contract = negoBaseToUpdateMap.values().get(i);
                                    String key = contract.BusinessUnitContract__c + '' + contract.Supplier_Nego_Scope__c + '' + Integer.valueOf(contract.Reference_Year__c);
                                    if (negoBaseMap.containsKey(key)) {
                                        errorMessages.add(errorMessage);
                                    }
                                }
                            }
                        }
                    }
                    if (!negoBaseInitConditionsMap.isEmpty()) {
                        for (String key : negoBaseInitConditionsMap.keySet()) {
                            Contract_Discount__c negoBaseInitCondition = negoBaseInitConditionsMap.get(key);
                            Decimal exclusionToNegoBaseValue = (negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c == null || negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c == 0 ?
                                                                (negoBaseInitCondition.Value_amt__c != null ? negoBaseInitCondition.Value_amt__c :0) :
                                                                negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c);
                            if (negoBaseConditionsMap.containsKey(key)) {
                                Contract_Discount__c negoBaseCondition = negoBaseConditionsMap.get(key);
                                if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c) {
                                    negoBaseCondition.Value_per__c = 0;
                                    negoBaseCondition.Value_per_Y1__c = 0;
                                } else {
                                    negoBaseCondition.Value_per__c = negoBaseInitCondition.Value_per__c;
                                    negoBaseCondition.Value_per_Y1__c = negoBaseInitCondition.Value_per_Y1__c;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c) {
                                    negoBaseCondition.unit_amount__c = null;
                                    negoBaseCondition.Unit_Amount_Type__c = null;
                                } else {
                                    negoBaseCondition.unit_amount__c = negoBaseInitCondition.unit_amount__c;
                                    negoBaseCondition.Unit_Amount_Type__c = negoBaseInitCondition.Unit_Amount_Type__c;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c) {
                                    Decimal oldAmount = negoBaseCondition.Value_amt__c != null ? negoBaseCondition.Value_amt__c : 0;
                                    negoBaseCondition.Value_amt__c = exclusionToNegoBaseValue < oldAmount ? oldAmount - exclusionToNegoBaseValue : 0;
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseCondition.Value_amt__c;
                                    negoBaseCondition.Exclusion_to_Nego_Base_Value__c = exclusionToNegoBaseValue;
                                } else {
                                    negoBaseCondition.Value_amt__c = negoBaseInitCondition.Value_amt__c;
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseInitCondition.Value_amt_Y1__c;
                                }
                                negoBaseCondition.Discount_Terms_Origin__c = negoBaseInitCondition.Discount_Terms_Origin__c;
                                negoBaseCondition.Discount_Terms__c = negoBaseInitCondition.Discount_Terms__c;
                                negoBaseCondition.Proof_counterparty_description__c = negoBaseInitCondition.Proof_counterparty_description__c;
                                negoBaseCondition.Proof_counterparty_number_total__c = negoBaseInitCondition.Proof_counterparty_number_total__c;
                                negoBaseCondition.legal_reference__c = negoBaseInitCondition.legal_reference__c;
                                negoBaseCondition.financial_reference__c = negoBaseInitCondition.financial_reference__c;
                                if (negoBaseCondition.commercial_reference__c == null) negoBaseCondition.commercial_reference__c = negoBaseInitCondition.commercial_reference__c;
                                negoBaseCondition.Proof_counterparty_definition__c = negoBaseInitCondition.Proof_counterparty_definition__c;
                                conditionsToUpdate.add(negoBaseCondition);
                                if(subNegoBaseConditionsMap.containsKey(negoBaseCondition.Id)) {
                                    Integer amountCount = subNegoBaseConditionsWithAmountMap.containsKey(negoBaseCondition.Id) ? subNegoBaseConditionsWithAmountMap.get(negoBaseCondition.Id) : 0;
                                    List<Decimal> listOfSubConditionAmount = NegoptimHelper.smartDivision(negoBaseCondition.Value_amt__c, amountCount, 0, null);
                                    Boolean isSubDiscountUpdated = false;
                                    Integer index = 0;
                                    for(Contract_Discount__c subDiscount : subNegoBaseConditionsMap.get(negoBaseCondition.Id)) {
                                        if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c && subDiscount.Value_per__c != null && subDiscount.Value_per__c != 0) {
                                            subDiscount.Value_per__c = 0;
                                            subDiscount.Value_per_Y1__c = 0;
                                            isSubDiscountUpdated = true;
                                        }
                                        if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c) {
                                            subDiscount.unit_amount__c = null;
                                            subDiscount.Unit_Amount_Type__c = null;
                                            isSubDiscountUpdated = true;
                                        }
                                        if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c && amountCount > 0 && subDiscount.Value_amt__c != null && subDiscount.Value_amt__c != 0) {
                                            subDiscount.Value_amt__c = listOfSubConditionAmount.get(index++);
                                            subDiscount.Value_amt_Y1__c = subDiscount.Value_amt__c;
                                            isSubDiscountUpdated = true;
                                        }
                                        if(isSubDiscountUpdated) {
                                            conditionsToUpdate.add(subDiscount);
                                        }
                                    }
                                }
                            } else if (negoBaseToUpdateMap.get(negoBaseInitCondition.Contract__r.BusinessUnitContract__c + '' + negoBaseInitCondition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(negoBaseInitCondition.Contract__r.Reference_Year__c)) != null) {
                                String contractKey = negoBaseInitCondition.Contract__r.BusinessUnitContract__c + '' + negoBaseInitCondition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(negoBaseInitCondition.Contract__r.Reference_Year__c);
                                Contract__c negoBase = negoBaseToUpdateMap.get(contractKey);
                                //Date bDate = negoBase.Contract_BDate__c, eDate = negoBase.Contract_EDate__c;
                                //clone(preserveId, deepClone, preserveTimeStamps, preserveAutoNumber)
                                Contract_Discount__c negoBaseCondition = negoBaseInitCondition.clone(false, true, false, false);
                                negoBaseCondition.Contract__c = negoBase.Id;
                                if (negoBaseInitCondition.Is_Excluded_To_NegoBase__c) {
                                    negoBaseCondition.Value_per__c = 0;
                                    negoBaseCondition.Value_per_Y1__c = 0;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_U__c) {
                                    negoBaseCondition.unit_amount__c = null;
                                    negoBaseCondition.Unit_Amount_Type__c = null;
                                }
                                if (negoBaseInitCondition.Is_Excluded_To_Nego_Base_F__c) {
                                    Decimal oldAmount = negoBaseCondition.Value_amt__c != null ? negoBaseCondition.Value_amt__c : 0;
                                    negoBaseCondition.Value_amt__c = exclusionToNegoBaseValue < oldAmount ? oldAmount - exclusionToNegoBaseValue : 0;
                                    negoBaseCondition.Value_amt_Y1__c = negoBaseCondition.Value_amt__c;
                                    negoBaseCondition.Exclusion_to_Nego_Base_Value__c = negoBaseInitCondition.Exclusion_to_Nego_Base_Value__c;
                                }
                                negoBaseConditionsMap.put(key, negoBaseCondition);
                                conditionsToInsert.add(negoBaseCondition);
                            }
                        }
                        // insert conditions
                        String[] conditionsInsertFields = new String[] {
                            SObjectType.Contract_Discount__c.fields.Contract__c.Name
                        };
                        conditionsInsertFields.addAll(conditionsFields);
                        if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsInsertFields)
                            && NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionsFields))
                        {
                            if(!conditionsToUpdate.isEmpty()) {
                                List<Database.SaveResult> results = Database.update(conditionsToUpdate, false);
                                for (Integer i = 0; i < results.size(); i++) {
                                    Database.SaveResult result = results.get(i);
                                    if (!result.isSuccess()) {
                                        String errorMessage = '';
                                        Database.Error[] errors = result.getErrors();
                                        for (Database.Error err : errors) {
                                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                        }
                                        Contract_Discount__c condition = conditionsToUpdate.get(i);
                                        String key = condition.Contract__r.BusinessUnitContract__c + '' + condition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(condition.Contract__r.Reference_Year__c);
                                        if (negoBaseMap.containsKey(key)) {
                                            errorMessages.add(errorMessage);
                                        }
                                    }
                                }
                            }
                            if(!conditionsToInsert.isEmpty()) {
                                List<Database.SaveResult> results = Database.insert(conditionsToInsert, false);
                                for (Integer i = 0; i < results.size(); i++) {
                                    Database.SaveResult result = results.get(i);
                                    if (!result.isSuccess()) {
                                        String errorMessage = '';
                                        Database.Error[] errors = result.getErrors();
                                        for (Database.Error err : errors) {
                                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                        }
                                        Contract_Discount__c condition = conditionsToInsert.get(i);
                                        String key = condition.Contract__r.BusinessUnitContract__c + '' + condition.Contract__r.Supplier_Nego_Scope__c + '' + Integer.valueOf(condition.Contract__r.Reference_Year__c);
                                        if (negoBaseMap.containsKey(key)) {
                                            errorMessages.add(errorMessage);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return errorMessages;
    }

    public static void updateConditionDefaultValues(Contract__c contract, Contract_Discount__c item, Contract_Discount__c referenceDiscount, Pol_Com_Condition__c tarrifCondition, Boolean copyFromPolComCondition) {
        item.Discount_Terms_Origin__c = referenceDiscount.Discount_Terms_Origin__c;
        item.Discount_Terms__c = referenceDiscount.Discount_Terms__c;
        item.legal_reference__c = referenceDiscount.legal_reference__c;
        item.financial_reference__c = referenceDiscount.financial_reference__c;
        item.Proof_counterparty_description__c = referenceDiscount.Proof_counterparty_description__c;
        item.Proof_counterparty_definition__c = referenceDiscount.Proof_counterparty_definition__c;
        if (item.Proof_counterparty_number_total__c == null) {
            item.Proof_counterparty_number_total__c = referenceDiscount.Proof_counterparty_number_total__c;
        }
        if (item.commercial_reference__c == null) {
            item.commercial_reference__c = referenceDiscount.commercial_reference__c;
        }
    }

    public static DuplicateContractResultWrapper duplicateContract(List<Contract__c> contractList, String recordTypeDeveloperName, Id country, Integer year, Date commercialBDate, Date commercialEDate, NegoptimBatch nb) {
        NegoptimSettings settings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
        Boolean contractNumberUnicity = settings.contractNumberUnicity;
        String sBusinessType = settings.sBusinessType;
        List<String> conditionsFields = new List<String>();
        Map<String, Schema.SObjectField> conditionFieldsMap = Schema.SObjectType.Contract_Discount__c.fields.getMap();
        for (String fieldName : conditionFieldsMap.keySet()) {
            if (conditionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                conditionsFields.add(fieldName);
            }
        }
        List<String> polSaleConditionExceptionFields = new List<String>();
        Map<String, Schema.SObjectField> polSaleConditionExceptionFieldsMap = Schema.SObjectType.Pol_Sale_Condition_Exception__c.fields.getMap();
        for (String fieldName : polSaleConditionExceptionFieldsMap.keySet()) {
            if (polSaleConditionExceptionFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                polSaleConditionExceptionFields.add(fieldName);
            }
        }
        Map<String, Integer> contractFieldsScaleMap = new Map<String, Integer>();
        Set<String> contractFieldsSet = Schema.SObjectType.Contract__c.fields.getMap().keySet();
        for (SObjectField item : Contract__c.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = item.getDescribe();
            contractFieldsScaleMap.put(dfr.getName(), dfr.getScale());
        }
        Integer conditionValueAmtScale = SObjectType.Contract_Discount__c.fields.Value_amt__c.getScale();
        Integer conditionBaseTONegoScale = SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.getScale();
        Integer conditionBaseTONegoYearBaseScale = SObjectType.Contract_Discount__c.fields.Base_TO_Nego_YearBase__c.getScale();
        Integer conditionBaseQtyNegoScale = SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.getScale();
        /*String q = 'SELECT Id, Name, Ext_id__c, BusinessUnitContract__c, BusinessUnitSource__c, BusinessUnitContract__r.Name, Contract_BDate__c, Contract_EDate__c, Reference_Year__c,';
        q += ' Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, Contract_MultiYearReference__c, Multi_Year_Index__c, Multi_Year_Total__c,';
        q += ' Contract_Type__c, CurrencyIsoCode, Duration__c, Parent_Contract__c, Status__c,';
        q += ' Supplier__c, Supplier__r.Name, Supplier_Nego_Scope__c, RecordType.DeveloperName, RecordTypeId,';
        q += ' Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c,';
        q += ' Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c,';
        q += ' TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c,';
        q += ' Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c,';
        q += ' IsCalculatedIndexV2__c,';*/
        String q = 'SELECT ' + (contractFieldsSet.isEmpty() ? 'Id ' : String.join(new List<String>(contractFieldsSet), ', ')) + ',';
        q += 'BusinessUnitContract__r.Name, Supplier__r.Name, RecordType.DeveloperName, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.CodeLong__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SupplyChainType__c,';
        q += 'Supplier_Nego_Scope__r.SegmentationAttribut1__c, Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c,';
        // get all Pol_Sale_Condition_Exception__c
        q += ' (SELECT Id, ' + String.join(polSaleConditionExceptionFields, ',') + ' FROM Sales_Conditions_Exception__r),';
        // get all conditions
        q += ' (SELECT Id, Name, Contract__c, Respects_Contract_Scope__c, Index__c, YTD_Nego__c, Product_Scope__r.SegmentationAttribut3__c, Is_conditional__c,';
        q += ' Condition_Type__r.' + String.join(ContractServices.staticPolComConditionFields, ', Condition_Type__r.') + ',';
        q += ' ' + String.join(conditionsFields, ',');
        q += ' FROM Contract_Discounts__r WHERE Status__c <> \'Deleted\' AND Product_Scope__r.Status__c = \'Active\' AND BusinessUnitScope__r.Status__c = \'Open\'';
        if (recordTypeDeveloperName == 'Period_Extension') {
            q += ' AND ((Parent_Discount__c = NULL AND Is_Duplicable_PE__c = TRUE) OR Parent_Discount__r.Is_Duplicable_PE__c = TRUE)';
        } else /*if (recordTypeDeveloperName == 'Signed')*/ {
            q += ' AND ((Parent_Discount__c = NULL AND is_Duplicable__c = TRUE) OR Parent_Discount__r.is_Duplicable__c = TRUE)';
        }
        q += ' )';
        q += ' FROM Contract__c';
        q += ' WHERE Supplier__r.Status__c = \'Active\' AND Supplier_Nego_Scope__r.Status__c = \'Active\' AND BusinessUnitContract__r.Status__c = \'Open\'';
        if (country != null) {
            q += ' AND BusinessUnitContract__c = \'' + country + '\'';
        }
        if (contractList != null && !contractList.isEmpty()) {
            q += ' AND Id IN :contractList ';
        }
        if (year != null) {
            q += ' AND Reference_Year__c = ' + year;
        }
        List<Contract__c> scope = Database.query(q);
        Id recordTypeId = String.isNotBlank(recordTypeDeveloperName) ? NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, recordTypeDeveloperName) : null;
        List<ContractWrapper> contractWrapperList = new List<ContractWrapper>();
        // List for duplicated contracts to be insert.
        List<Contract__c> duplicatedContractList = new List<Contract__c>();
        Map<String, Contract__c> existingContractMap = new Map<String, Contract__c>();
        // List of tariff condition duplication mapping
        Map<Id, Pol_Com_Condition__c> tariffConditionMappingMap = new Map<Id, Pol_Com_Condition__c>();
        Map<Id, String> tariffConditionInfoMap = new Map<Id, String>();
        Set<Id> tariffConditionForDuplicationMappingSet = new Set<Id>();
        Map<Id, Set<Id>> parentTariffConditionMap = new Map<Id, Set<Id>>();
        Map<Id, List<Contract_Discount__c>> parentConditionsMap = new Map<Id, List<Contract_Discount__c>>();
        Map<Id, List<Contract_Discount__c>> subConditionsMap = new Map<Id, List<Contract_Discount__c>>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        List<String> errorMessages = new List<String>();
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        List<NegoSettings.ContractDuplicationWrapper> contractDuplicationConfigurationList = (List<NegoSettings.ContractDuplicationWrapper>) negoSettings.contractDuplicationConfiguration;
        Set<Id> contractInsertedIds = new Set<Id>();
        for (Contract__c item : scope) {
            buIdSet.add(item.BusinessUnitContract__c);
            nsIdSet.add(item.Supplier_Nego_Scope__c);
            // get year N + 1
            yearSet.add(Integer.valueOf(item.Reference_Year__c) + 1);
            if (recordTypeDeveloperName == 'Simulation') {
                yearSet.add(Integer.valueOf(item.Reference_Year__c));
            }
            // Add commercialBDate year to ensure we find existing Simulations for the target year
            if (commercialBDate != null) {
                yearSet.add(commercialBDate.year());
            }
            parentTariffConditionMap.put(item.Id, new Set<Id>());
            for (Contract_Discount__c condition : item.Contract_Discounts__r) {
                if (condition.Condition_Type__c != null && !tariffConditionForDuplicationMappingSet.contains(condition.Condition_Type__c)) {
                    tariffConditionForDuplicationMappingSet.add(condition.Condition_Type__c);
                }
                // get all parent and sub conditions
                if (!parentConditionsMap.containsKey(item.Id)) {
                    parentConditionsMap.put(item.Id, new List<Contract_Discount__c>());
                }
                if (condition.Parent_Discount__c == null) {
                    parentConditionsMap.get(item.Id).add(condition);
                    parentTariffConditionMap.get(item.Id).add(condition.Condition_Type__c);
                } else {
                    if (!subConditionsMap.containsKey(condition.Parent_Discount__c)) {
                        subConditionsMap.put(condition.Parent_Discount__c, new List<Contract_Discount__c>());
                    }
                    subConditionsMap.get(condition.Parent_Discount__c).add(condition);
                }
            }
        }
        // check existing Period Extension contract
        String[] contractFields = new String[] {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Supplier__c.Name,
            SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name,
            SObjectType.Contract__c.fields.RecordTypeId.Name,
            SObjectType.Contract__c.fields.Parent_Contract__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.BusinessUnitSource__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
            SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
            SObjectType.Contract__c.fields.Contract_BDate__c.Name,
            SObjectType.Contract__c.fields.Contract_EDate__c.Name,
            SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
            SObjectType.Contract__c.fields.Status__c.Name
        };
        Map<String, Integer> lastSimulationNumberMap = new Map<String, Integer>();
        if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
            for (Contract__c item : [SELECT Id, Name, RecordType.DeveloperName, SimulationNumber__c, Parent_Contract__c, BusinessUnitContract__c, BusinessUnitSource__c, Supplier__c, Supplier_Nego_Scope__c, Reference_Year__c,
                                     Contract_Commercial_BDate__c, Contract_Commercial_EDate__c, Contract_BDate__c, Contract_EDate__c
                                     FROM Contract__c
                                     WHERE RecordType.DeveloperName IN ('Simulation', 'Period_Extension', 'Signed', 'Objective', 'To_Be_Signed', 'Safe_Balance', 'PostNego_Simulation')
                                     AND BusinessUnitContract__c IN :buIdSet
                                     AND Supplier_Nego_Scope__c IN :nsIdSet
                                     AND Reference_Year__c IN :yearSet
                                     AND Status__c <> 'Deleted'
                                     ORDER BY SimulationNumber__c])
            {
                String key = item.RecordType.DeveloperName + item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c);
                existingContractMap.put(key, item);
                if (item.SimulationNumber__c != null) {
                    if(!lastSimulationNumberMap.containsKey(key)) lastSimulationNumberMap.put(key, 0);
                    lastSimulationNumberMap.put(key, item.SimulationNumber__c.intValue());
                }
            }
        }
        // get tariff condition duplication mapping
                system.debug('tariffConditionForDuplicationMappingSet >>> ' + tariffConditionForDuplicationMappingSet);
        if (!tariffConditionForDuplicationMappingSet.isEmpty()) {
            // check security on access Pol_Com_Condition__c fields
            if (NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, ContractServices.staticPolComConditionFields)) {
                String tariffConditionQuery = 'SELECT ' + String.join(ContractServices.staticPolComConditionFields, ',') + ',';
                tariffConditionQuery += ' (SELECT ' + String.join(ContractServices.staticPolComConditionFields, ',') + ' FROM Pol_Com_Conditions__r ORDER BY Name)';
                tariffConditionQuery += ' FROM Pol_Com_Condition__c';
                tariffConditionQuery += ' WHERE Condition_status__c <> \'Close\'';
                tariffConditionQuery += ' AND Duplication_Discount_Mapping__c IN (\'' + String.join(new List<Id>(tariffConditionForDuplicationMappingSet), '\',\'') +'\')';
                system.debug('tariffConditionQuery >>> ' + tariffConditionQuery);
                for (Pol_Com_Condition__c item : Database.query(tariffConditionQuery)) {
                    if(tariffConditionForDuplicationMappingSet.contains(item.Duplication_Discount_Mapping__c)) {
                        tariffConditionMappingMap.put(item.Duplication_Discount_Mapping__c, item);
                    }
                }
            }
        }
        for (Contract__c item : scope) {
            String key = item.BusinessUnitContract__c + '' + item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.Reference_Year__c + 1);
            String sourceRT = item.RecordType != null ? item.RecordType.DeveloperName : null;
            String sourceStatus = item.Status__c;
            String targetRT = recordTypeDeveloperName;
            String targetStatus = null;
            Boolean found = false;
            for(NegoSettings.ContractDuplicationWrapper contractDuplicationConfiguration : contractDuplicationConfigurationList) {
                if (contractDuplicationConfiguration.recordType != sourceRT || (String.isNotBlank(contractDuplicationConfiguration.status) && contractDuplicationConfiguration.status != sourceStatus)) continue;
                if (contractDuplicationConfiguration.targetContracts == null) continue;
                for(NegoSettings.ContractDuplicationWrapper targetRule: contractDuplicationConfiguration.targetContracts) {
                    if(targetRule.recordType == targetRT) {
                        targetStatus = targetRule.status;
                        found = true;
                        break;
                    }
                }
                if(found) break;
            }
            if(String.isBlank(targetStatus) && !Test.isRunningTest()) continue;
            ContractWrapper contractWrapper = new ContractWrapper(item, commercialBDate, commercialEDate, recordTypeId, recordTypeDeveloperName, targetStatus, contractNumberUnicity);
            contractWrapper.signedContract = existingContractMap.get('Signed' + key);
            contractWrapper.peContract = existingContractMap.get('Period_Extension' + key);
            if (String.isBlank(recordTypeDeveloperName)) {
                contractWrapper.recordTypeDeveloperName = contractWrapper.peContract == null ? 'Period_Extension' : 'Signed';
                contractWrapper.recordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, contractWrapper.recordTypeDeveloperName);
            }
            if (contractWrapper.commercialBDate == null) {
                if (contractWrapper.recordTypeDeveloperName == 'Period_Extension') {
                    if (contractWrapper.recordTypeDeveloperName == 'Period_Extension' && contractWrapper.signedContract == null) {
                        contractWrapper.commercialBDate = Date.newInstance(Integer.valueOf(item.Reference_Year__c + 1), 1, 1);
                    }
                } else if (contractWrapper.recordTypeDeveloperName == 'Simulation' || contractWrapper.recordTypeDeveloperName == 'To_be_Signed' || contractWrapper.recordTypeDeveloperName == 'Signed') {
                    if (contractWrapper.peContract != null) {
                        contractWrapper.commercialBDate = contractWrapper.peContract.Contract_EDate__c.addDays(1);
                    } else {
                        contractWrapper.commercialBDate = item.Contract_Commercial_BDate__c.addYears(1);
                    }
                } else {
                    contractWrapper.commercialBDate = item.Contract_Commercial_BDate__c.addYears(1);
                }
            }
            if (contractWrapper.commercialEDate == null) {
                if (contractWrapper.recordTypeDeveloperName == 'Period_Extension') {
                    if (contractWrapper.signedContract != null) {
                        contractWrapper.commercialEDate = contractWrapper.signedContract.Contract_BDate__c.addDays(-1);
                    } else {
                        contractWrapper.commercialEDate = Date.newInstance(Integer.valueOf(item.Reference_Year__c + 1), 3, 0);
                    }
                } else if (contractWrapper.recordTypeDeveloperName == 'Simulation' || contractWrapper.recordTypeDeveloperName == 'To_be_Signed' || contractWrapper.recordTypeDeveloperName == 'Signed') {
                    contractWrapper.commercialEDate = Date.newInstance(Integer.valueOf(item.Reference_Year__c + 1), 12, 31);
                } else {
                    contractWrapper.commercialEDate = item.Contract_Commercial_EDate__c.addYears(1);
                }
            }
            if (contractWrapper.commercialBDate != null && contractWrapper.commercialEDate != null && contractWrapper.commercialBDate != contractWrapper.commercialEDate) {
                contractWrapper.addDuplicatedContract(contractFieldsScaleMap);
                if (parentConditionsMap.containsKey(item.Id)) {
                    for (Contract_Discount__c parentCondition : parentConditionsMap.get(item.Id)) {
                        if (parentCondition.Disc_EDate_Y1__c == contractWrapper.contract.Contract_Commercial_EDate__c
                            && (parentCondition.is_Duplicable__c && contractWrapper.recordTypeDeveloperName != 'Period_Extension')
                            || (parentCondition.Is_Duplicable_PE__c && contractWrapper.recordTypeDeveloperName == 'Period_Extension'))
                        {
                            List<Contract_Discount__c> subConditions = new List<Contract_Discount__c>();
                            if (subConditionsMap.containsKey(parentCondition.Id)) {
                                subConditions = subConditionsMap.get(parentCondition.Id);
                            }
                            ContractConditionWrapper newConditionWrapper = new ContractConditionWrapper();
                            newConditionWrapper.parentCondition = newConditionWrapper.addDuplicatedCondition(contractWrapper, parentCondition, tariffConditionMappingMap, conditionsFields, conditionValueAmtScale, conditionBaseTONegoScale, conditionBaseTONegoYearBaseScale, conditionBaseQtyNegoScale);
                            if (!subConditions.isEmpty()) {
                                for (Contract_Discount__c subCondition : subConditions) {
                                    newConditionWrapper.subConditionList.add(newConditionWrapper.addDuplicatedCondition(contractWrapper, subCondition, tariffConditionMappingMap, conditionsFields, conditionValueAmtScale, conditionBaseTONegoScale, conditionBaseTONegoYearBaseScale, conditionBaseQtyNegoScale));
                                }
                            }
                            contractWrapper.conditionsWrapperList.add(newConditionWrapper);
                        }
                    }
                }
                // insert Pol_Sale_Condition_Exception__c to parent contract
                contractWrapper.addPolSaleConditionException();
            }
            if (contractWrapper.duplicatedContract != null) {
                contractWrapperList.add(contractWrapper);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            for (ContractWrapper item : contractWrapperList) {
                if (item.duplicatedContract.Contract_Type__c == 'Simulation') {
                    String key = item.recordTypeDeveloperName + item.duplicatedContract.BusinessUnitContract__c + '' + item.duplicatedContract.Supplier_Nego_Scope__c + '' + item.duplicatedContract.Contract_BDate__c.year();
                    Integer nextSimNumber = lastSimulationNumberMap.containsKey(key) ? lastSimulationNumberMap.get(key) + 1 : 1;
                    item.duplicatedContract.SimulationNumber__c = nextSimNumber;
                    lastSimulationNumberMap.put(key, nextSimNumber);
                } else {
                    item.duplicatedContract.SimulationNumber__c = null;
                }
                duplicatedContractList.add(item.duplicatedContract);
                // calculate indexes
                List<Contract_Discount__c> validConditions = new List<Contract_Discount__c>();
                if (!item.conditionsWrapperList.isEmpty()) {
                    Map<Id, Pol_Com_Condition__c> tariffConditionsValidMap;
                    String query = ContractServices.buildQueryTariffCondition(item.duplicatedContract, null, null, null);
                    if (query != null) {
                        List<Pol_Com_Condition__c> tariffConditionsList = (List<Pol_Com_Condition__c>)Database.query(query);
                        if (tariffConditionsList != null) {
                            tariffConditionsValidMap = new Map<Id, Pol_Com_Condition__c>(tariffConditionsList);
                            for (Pol_Com_Condition__c tariff : tariffConditionsList) {
                                tariffConditionInfoMap.put(tariff.Id, tariff.Name);
                            }
                        }
                    }
                    List<ContractConditionWrapper> validParentConditions = new List<ContractConditionWrapper>();
                    for (ContractConditionWrapper conditionWrapper : item.conditionsWrapperList) {
                        if (tariffConditionsValidMap != null && tariffConditionsValidMap.containsKey(conditionWrapper.parentCondition.Condition_Type__c)) {
                            validConditions.add(conditionWrapper.parentCondition);
                            validParentConditions.add(conditionWrapper);
                        }
                    }
                    item.conditionsWrapperList = validParentConditions;
                }
                ContractServices contractService = new ContractServices(item.duplicatedContract, validConditions);
                contractService.calculateContractIndex(false);
            }
            contractFields = new String[] {
                SObjectType.Contract__c.fields.Name.Name,
                SObjectType.Contract__c.fields.Status__c.Name,
                SObjectType.Contract__c.fields.Parent_Contract__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                SObjectType.Contract__c.fields.Duration__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.TO1__c.Name,
                SObjectType.Contract__c.fields.TO2__c.Name,
                SObjectType.Contract__c.fields.TO3__c.Name,
                SObjectType.Contract__c.fields.TO4__c.Name,
                SObjectType.Contract__c.fields.TO5__c.Name,
                SObjectType.Contract__c.fields.TO6__c.Name,
                SObjectType.Contract__c.fields.TO7__c.Name,
                SObjectType.Contract__c.fields.TO8__c.Name,
                SObjectType.Contract__c.fields.TO9__c.Name,
                SObjectType.Contract__c.fields.TO10__c.Name,
                SObjectType.Contract__c.fields.TO11__c.Name,
                SObjectType.Contract__c.fields.TO12__c.Name,
                SObjectType.Contract__c.fields.Qty1__c.Name,
                SObjectType.Contract__c.fields.Qty2__c.Name,
                SObjectType.Contract__c.fields.Qty3__c.Name,
                SObjectType.Contract__c.fields.Qty4__c.Name,
                SObjectType.Contract__c.fields.Qty5__c.Name,
                SObjectType.Contract__c.fields.Qty6__c.Name,
                SObjectType.Contract__c.fields.Qty7__c.Name,
                SObjectType.Contract__c.fields.Qty8__c.Name,
                SObjectType.Contract__c.fields.Qty9__c.Name,
                SObjectType.Contract__c.fields.Qty10__c.Name,
                SObjectType.Contract__c.fields.Qty11__c.Name,
                SObjectType.Contract__c.fields.Qty12__c.Name
            };
            List<ContractWrapper> contractWrapperInsertedList = new List<ContractWrapper>();
            if (NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractFields)) {
                List<Database.SaveResult> results = Database.insert(duplicatedContractList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    ContractWrapper contractWrapper = contractWrapperList.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                        }
                        errorMessages.add(errorMessage);
                        if (nb != null) {
                            nb.logError(errorMessage);
                        }
                    } else {
                        contractWrapperInsertedList.add(contractWrapper);
                        contractInsertedIds.add(contractWrapper.duplicatedContract.Id);
                    }
                }
                // insert parent and sub conditions
                List<Contract_Discount__c> parentConditionsList = new List<Contract_Discount__c>();
                List<Contract_Discount__c> subConditionsList = new List<Contract_Discount__c>();
                // insert Pol_Sale_Condition_Exception__c
                List<Pol_Sale_Condition_Exception__c> polSaleConditionExceptionInsertedList = new List<Pol_Sale_Condition_Exception__c>();
                for (ContractWrapper item : contractWrapperInsertedList) {
                    if (!item.conditionsWrapperList.isEmpty()) {
                        for (ContractConditionWrapper conditionWrapper : item.conditionsWrapperList) {
                            if (conditionWrapper.parentCondition != null) {
                                conditionWrapper.parentCondition.Contract__c = item.duplicatedContract.Id;
                                parentConditionsList.add(conditionWrapper.parentCondition);
                            }
                        }
                    }
                    if (!item.polSalesConditionExceptionList.isEmpty()) {
                        for (Pol_Sale_Condition_Exception__c polSaleConditionException : item.polSalesConditionExceptionList) {
                            polSaleConditionException.Contract__c =  item.duplicatedContract.Id;
                            polSaleConditionException.Ext_id__c = item.duplicatedContract.Ext_id__c;
                            polSaleConditionException.Ext_Id2__c = item.duplicatedContract.Ext_id__c;
                            polSaleConditionExceptionInsertedList.add(polSaleConditionException);
                        }
                    }
                }
                // insert parent and sub conditions
                if (!parentConditionsList.isEmpty()) {
                    conditionsFields.add(SObjectType.Contract_Discount__c.fields.Contract__c.Name);
                    if (NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionsFields)) {
                        List<Contract_Discount__c> parentConditionsSortList = ContractServices.sort(parentConditionsList, true, true);
                        system.debug('tariffConditionInfoMap >>>> ' + JSON.serialize(tariffConditionInfoMap));
                        results = Database.insert(parentConditionsSortList, false);
                        system.debug('results >>>> ' + JSON.serialize(results));
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            Contract_Discount__c discount = parentConditionsList.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                Database.Error[] errors = result.getErrors();
                                system.debug('discount.Condition_Type__c >>> ' + discount.Condition_Type__c);
                                for (Database.Error err : errors) {
                                    errorMessage += (tariffConditionInfoMap != null && tariffConditionInfoMap.containsKey(discount.Condition_Type__c) ? tariffConditionInfoMap.get(discount.Condition_Type__c) + ' - ' : '') + err.getMessage();
                                }
                                errorMessages.add(errorMessage);
                            }
                        }
                        if (nb != null) {
                            nb.logResults(results, parentConditionsSortList);
                        }
                        for (ContractWrapper item : contractWrapperInsertedList) {
                            if (!item.conditionsWrapperList.isEmpty()) {
                                for (ContractConditionWrapper conditionWrapper : item.conditionsWrapperList) {
                                    if (conditionWrapper.parentCondition != null && conditionWrapper.parentCondition.Id != null) {
                                        if (conditionWrapper.subConditionList != null && !conditionWrapper.subConditionList.isEmpty()) {
                                            for (Contract_Discount__c subCondition : conditionWrapper.subConditionList) {
                                                subCondition.Contract__c = item.duplicatedContract.Id;
                                                subCondition.Parent_Discount__c = conditionWrapper.parentCondition.Id;
                                                subConditionsList.add(subCondition);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if (!subConditionsList.isEmpty()) {
                            List<Contract_Discount__c> subConditionsSortList = ContractServices.sort(subConditionsList, true, true);
                            results = Database.insert(subConditionsSortList, false);
                            if (nb != null) {
                                nb.logResults(results, subConditionsSortList);
                            }
                        }
                    }
                }
                // insert Pol_Sale_Condition_Exception__c
                if (!polSaleConditionExceptionInsertedList.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, polSaleConditionExceptionFields)) {
                        results = Database.insert(polSaleConditionExceptionInsertedList, false);
                        if (nb != null) {
                            nb.logResults(results, polSaleConditionExceptionInsertedList);
                        }
                    }
                }
                // execute InitContractSellInBatch
                /*if (!contractInsertedIds.isEmpty() && !System.isBatch()) {
                    Map<String, Object> paramsMap = new Map<String, Object> {
                        'startedFrom' => DuplicateContractCmpCtrl.class.getName(),
                        'contractIds' => contractInsertedIds
                    };
                    NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 1);                    
                }*/
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            if (nb != null) {
                nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            }
        } catch(Exception e) {
            Database.rollback(sp);
            if (nb != null) {
                nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            }
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        if (nb != null) {
            nb.incrementBatchIndex();
        }
        return new DuplicateContractResultWrapper(contractInsertedIds, errorMessages);
    }

    public static void populateDiscountFields(Contract_Discount__c item, Pol_Com_Condition__c tarrifCondition,
                                              Map<String, Id> globalLocationsMap, Contract_Discount__c referenceCondition)
    {
        item.Proof_Counterparty_Execution_Agreement__c = tarrifCondition.Proof_Counterparty_Execution_Agreement__c;
        item.Is_Yearly_Condition__c = tarrifCondition.Is_Yearly_Condition__c;
        item.Force_RightToChange_InStatus__c = tarrifCondition.Force_RightToChange_InStatus__c;
        item.Valid__c = tarrifCondition.Is_Valid_ByDefault__c;
        item.Is_Tariff_Condition__c = tarrifCondition.Is_Tariff_Condition__c;
        item.Is_FlatPrice_Condition__c = tarrifCondition.Is_FlatPrice_Condition__c;
        item.Is_TransferPrice_Condition__c = tarrifCondition.Is_TransferPrice_Condition__c;
        // ## index_v2 is the same as tarrifCondition.Index__c because the business logic isn't complete in the standard yet
        item.index_v2__c = tarrifCondition.Index__c;
        if(item.Rank__c == null) item.Rank__c = tarrifCondition.Rank_Order__c;
        Contract__c contract = item.Contract__r;
        // populate Is_Duplicable__c
        if (referenceCondition != null) {
            item.Is_Duplicable__c = referenceCondition.Is_Duplicable__c;
            item.Is_Duplicable_PE__c = referenceCondition.Is_Duplicable_PE__c;
            String conditionDuplication = contract != null
                && contract.RecordType.DeveloperName == 'Period_Extension'
                && item.Is_Duplicable_PE__c
                && tarrifCondition.Condition_Duplication_PE__c != null
                && tarrifCondition.Condition_Duplication_PE__c != '' ?
                tarrifCondition.Condition_Duplication_PE__c : tarrifCondition.Condition_Duplication__c;
            if (conditionDuplication != null) {
                Integer currentYearIndex = contract.Multi_Year_Index__c != null ? Integer.valueOf(contract.Multi_Year_Index__c) : null;
                List<String> duplicationList = conditionDuplication.split(';');
                if (!duplicationList.contains('%')) {
                    item.Value_per__c = null;
                    if (currentYearIndex != null && contract.Multi_Year_Total__c != null) {
                        for (Integer i = currentYearIndex; i <= Integer.valueOf(contract.Multi_Year_Total__c) && i <= 5; i++) {
                            item.put('Value_per_Y' + i + '__c', null);
                        }
                    }
                }
                if (!duplicationList.contains('F')) {
                    item.Value_amt__c = null;
                    if (currentYearIndex != null && contract.Multi_Year_Total__c != null) {
                        for (Integer i = currentYearIndex; i <= Integer.valueOf(contract.Multi_Year_Total__c) && i <= 5; i++) {
                            item.put('Value_amt_Y' + i + '__c',  null);
                        }
                    }
                }
                if (!duplicationList.contains('U')) {
                    item.unit_amount__c = null;
                }
            }
        } else {
            if (tarrifCondition.Condition_Duplication__c != null) {
                List<String> duplicationList = tarrifCondition.Condition_Duplication__c.split(';');
                if ((duplicationList.contains('%') && item.Value_per__c != null)
                    || (duplicationList.contains('F') && item.Value_amt__c != null)
                    || (duplicationList.contains('U') && item.unit_amount__c != null))
                {
                    item.Is_Duplicable__c = true;
                }
            } else {
                item.Is_Duplicable__c = false;
            }
            if (tarrifCondition.Condition_Duplication_PE__c != null) {
                List<String> duplicationList = tarrifCondition.Condition_Duplication_PE__c.split(';');
                if ((duplicationList.contains('%') && item.Value_per__c != null)
                    || (duplicationList.contains('F') && item.Value_amt__c != null)
                    || (duplicationList.contains('U') && item.unit_amount__c != null))
                {
                    item.Is_Duplicable_PE__c = true;
                }
            } else {
                item.Is_Duplicable_PE__c = false;
            }
        }
        populateInvoiceFields(item, tarrifCondition, globalLocationsMap);
    }
    
    public static void populateInvoiceFields(Contract_Discount__c item, Pol_Com_Condition__c tarrifCondition, Map<String, Id> globalLocationsMap) {
        // populate Invoices Fields
        Contract__c contract = item.Contract__r;
        if (item.Parent_Discount__c == null) {
            InvoicePlanning__c invoicePlanning;
            if(contract != null) {
                if(contract.RecordType.DeveloperName == 'Period_Extension' && tarrifCondition.InvoicePlanningPE__r != null) {
                    invoicePlanning = tarrifCondition.InvoicePlanningPE__r;
                } else {
                    invoicePlanning = tarrifCondition.InvoicePlanning__r;
                }
            }
            String mode = 'P';
            if (tarrifCondition.Condition_Mode__c == '%') {
                mode = 'P';
            } else if (tarrifCondition.Condition_Mode__c == 'F') {
                mode = 'F';
            } else if (tarrifCondition.Condition_Mode__c == 'U') {
                mode = 'U';
            } else {
                mode = item.Value_per__c != null ? 'P' : (item.Value_amt__c != null ? 'F' : (item.Unit_amount__c != null ? 'U' : 'P'));
            }
            if (invoicePlanning != null) {
                item.put('Down_Payment_YE_Coverage__c', invoicePlanning.get( 'DownPaymentYECoverage' + mode + '__c'));
                item.put('Invoice_base__c', invoicePlanning.get( 'SeriesBase' + mode + '__c'));
                item.put('Invoice_period__c', invoicePlanning.get( 'SeriesPeriod' + mode + '__c'));
                item.put('Invoice_sequence__c', invoicePlanning.get( 'SeriesSequence' + mode + '__c'));
                Date seriesStartDate = invoicePlanning.get( 'SeriesStartDate' + mode + '__c') != null ? (Date)invoicePlanning.get( 'SeriesStartDate' + mode + '__c') : null;
                if (seriesStartDate != null && item.Disc_BDate__c != null) {
                    Integer day = seriesStartDate.day();
                    Integer month = item.Disc_BDate__c.month();
                    Integer year = item.Disc_BDate__c.year();
                    if (item.Disc_BDate__c.day() <= day) {
                        month = month < seriesStartDate.month() ? seriesStartDate.month() : item.Disc_BDate__c.month() ;
                    } else {
                        if (month < seriesStartDate.month() ) {
                            // Increment month, wrap around if December
                            if (SeriesStartDate.month() == 12) {
                                month = 1;
                                year = year + 1;
                            } else {
                                month = SeriesStartDate.month() + 1;
                            }
                        } else {
                            // Increment month, wrap around if December
                            if (month == 12) {
                                month = 1;
                                year = year + 1;
                            } else {
                                month = month + 1;
                            }
                        }
                    }
                    Date firstDate =  Date.newInstance(year, month, day);
                    item.first_invoice_date__c = firstDate;
                }
                item.Is_Manual_Invoicing_Planning__c = false;
            }
            // set Global locations
            if (globalLocationsMap != null && !globalLocationsMap.isEmpty() && contract.BusinessUnitContract__c != null && contract.BusinessUnitContract__r.SetInvoiceSeller__c) {
                item.BusinessUnitSeller__c = contract.BusinessUnitContract__c;
                String keyInvoiceBy = String.valueOf(contract.BusinessUnitContract__c) + 'InvoiceBy';
                String keyPaidTo = String.valueOf(contract.BusinessUnitContract__c) + 'PaidTo';
                String keyAdmin = String.valueOf(contract.BusinessUnitContract__c) + 'Administrative';
                item.GlobalLocationSeller__c = globalLocationsMap.containsKey(keyInvoiceBy) ? globalLocationsMap.get(keyInvoiceBy) : globalLocationsMap.get(keyAdmin);
                item.GlobalLocationPayee__c = globalLocationsMap.containsKey(keyPaidTo) ? globalLocationsMap.get(keyPaidTo) : globalLocationsMap.get(keyAdmin);
            }
        }
    }
    
    public class ContractWrapper {
        public Contract__c contract {get; set;}
        public Contract__c duplicatedContract {get; set;}
        public Decimal duplicatedTotalTO {get; set;}
        public Decimal duplicatedTotalQty {get; set;}
        public Contract__c peContract {get; set;}
        public Contract__c signedContract {get; set;}
        public List<ContractConditionWrapper> conditionsWrapperList {get; set;}
       /* public List<Contract_Services__c> contractServicesList {get; set;}*/
        public List<Pol_Sale_Condition_Exception__c> polSalesConditionExceptionList {get; set;}
        public Date commercialBDate {get; set;}
        public Date commercialEDate {get; set;}
        public String recordTypeDeveloperName {get; set;}
        public String targetStatus {get; set;}
        public Id recordTypeId {get; set;}
        public Boolean contractNumberUnicity {get; set;}
        private List<String> rtContract = new List<String> {
            'Nego_Base',
            'Nego_Base_Init',
            'Period_Extension',
            'Signed',
            'To_Be_Signed',
            'Landing',
            'Objective'
        };
        private List<String> rtSimulation = new List<String> {
            'Simulation',
            'Safe_Balance',
            'PostNego_Simulation',
            'Signed_Copy'
        };
        public ContractWrapper(Contract__c contract, Date commercialBDate, Date commercialEDate, Id recordTypeId, String recordTypeDeveloperName, String targetStatus, Boolean contractNumberUnicity/*, Boolean isMultiYear*/) {
            this.contract = contract;
            this.commercialBDate = commercialBDate;
            this.commercialEDate = commercialEDate;
            this.recordTypeId = recordTypeId;
            this.recordTypeDeveloperName = recordTypeDeveloperName;
            this.targetStatus = targetStatus;
            this.contractNumberUnicity = contractNumberUnicity;
            // this.isMultiYear = isMultiYear;
            this.conditionsWrapperList = new List<ContractConditionWrapper>();
            /*this.contractServicesList = new List<Contract_Services__c>();*/
            this.polSalesConditionExceptionList = new List<Pol_Sale_Condition_Exception__c>();
            this.duplicatedTotalTO = 0;
            this.duplicatedTotalQty = 0;
        }
        
        public void addDuplicatedContract(Map<String, Integer> contractFieldsScaleMap) {
            // case duplicate contract commercials dates
            if (commercialBDate != null && commercialEDate != null) {
                duplicatedContract = contract.clone(false, true, false, false);
                duplicatedContract.Parent_Contract__c = this.contract.Id;
                System.debug('duplicatedContract>>>' + duplicatedContract.Parent_Contract__c);
                System.debug('this.contract.Id>>>' + this.contract.Id);
                duplicatedContract.Contract_Number__c = null;
                duplicatedContract.SimulationNumber__c = null;
                duplicatedContract.Is_OnTop_Simulation__c = false;
                duplicatedContract.ContractP1__c = null;
                duplicatedContract.Name = null;
                duplicatedContract.Ext_id__c = null;
                duplicatedContract.RecordTypeId = this.recordTypeId;
                duplicatedContract.Contract_BDate__c = commercialBDate;
                duplicatedContract.Contract_EDate__c = commercialEDate;
                duplicatedContract.Contract_Commercial_BDate__c = commercialBDate;
                duplicatedContract.Contract_Commercial_EDate__c = commercialEDate;
                duplicatedContract.Multi_Year_Index__c = 1;
                /*duplicatedContract = new Contract__c(BusinessUnitContract__c = contract.BusinessUnitContract__c,
                                                     BusinessUnitSource__c = contract.BusinessUnitSource__c,
                                                     CurrencyIsoCode = contract.CurrencyIsoCode,
                                                     Supplier__c = contract.Supplier__c,
                                                     Supplier_Nego_Scope__c = contract.Supplier_Nego_Scope__c,
                                                     Supplier_Nego_Scope__r = contract.Supplier_Nego_Scope__r,
                                                     RecordTypeId = this.recordTypeId,
                                                     Contract_BDate__c = commercialBDate,
                                                     Contract_EDate__c = commercialEDate,
                                                     Contract_Commercial_BDate__c = commercialBDate,
                                                     Contract_Commercial_EDate__c = commercialEDate,
                                                     TO1__c = contract.TO1__c, TO2__c = contract.TO2__c, TO3__c = contract.TO3__c, TO4__c = contract.TO4__c,
                                                     TO5__c = contract.TO5__c, TO6__c = contract.TO6__c, TO7__c = contract.TO7__c, TO8__c = contract.TO8__c,
                                                     TO9__c = contract.TO9__c, TO10__c = contract.TO10__c, TO11__c = contract.TO11__c, TO12__c = contract.TO12__c,
                                                     Qty1__c = contract.Qty1__c, Qty2__c = contract.Qty2__c, Qty3__c = contract.Qty3__c, Qty4__c = contract.Qty4__c,
                                                     Qty5__c = contract.Qty5__c, Qty6__c = contract.Qty6__c, Qty7__c = contract.Qty7__c, Qty8__c = contract.Qty8__c,
                                                     Qty9__c = contract.Qty9__c, Qty10__c = contract.Qty10__c, Qty11__c = contract.Qty11__c, Qty12__c = contract.Qty12__c,
                                                     Multi_Year_Index__c = 1);*/
                // update TO
                Date bdateFebruary = Date.newInstance(commercialBDate.year(), 2, 1);
                Date edateFebruary = Date.newInstance(commercialEDate.year(), 3, 0);
                Boolean fullMonthFeb = duplicatedContract.Contract_Commercial_BDate__c <= bdateFebruary && duplicatedContract.Contract_Commercial_EDate__c >= edateFebruary;
                for (Integer i = 1 ; i <= 12 ; i++) {
                    String fieldname = NegoptimHelper.normalizeAPIName('TO' + i + '__c');
                    Decimal to = (Decimal)this.contract.get(fieldname);
                    Integer daysInMonth = Date.daysInMonth(duplicatedContract.Contract_Commercial_BDate__c.year(), i);
                    if (i < duplicatedContract.Contract_Commercial_BDate__c.month() || i > duplicatedContract.Contract_Commercial_EDate__c.month()) {
                        to = 0;
                    } else if(fullMonthFeb && i == 2) {
                        to = to != null ? to : 0;
                    } else if (i == duplicatedContract.Contract_Commercial_BDate__c.month()) {
                        to = (to != null) ? ((to / daysInMonth) * daysBetween(duplicatedContract.Contract_Commercial_BDate__c, end_of_month(duplicatedContract.Contract_Commercial_BDate__c))) : 0;
                    } else if (i == duplicatedContract.Contract_Commercial_EDate__c.month()) {
                        to = (to != null) ? ((to / daysInMonth) * daysBetween(beginning_of_month(duplicatedContract.Contract_Commercial_EDate__c), duplicatedContract.Contract_Commercial_EDate__c)) : 0;
                    } else {
                        to = to != null ? to : 0;
                    }
                    to = to.setScale(contractFieldsScaleMap.get(fieldname), System.RoundingMode.HALF_UP);
                    duplicatedContract.put(fieldname, to);
                    duplicatedTotalTO += to;
                    fieldname = NegoptimHelper.normalizeAPIName('Qty' + i + '__c');
                    Decimal qty = (Decimal)this.contract.get(fieldname);
                    if (i < duplicatedContract.Contract_Commercial_BDate__c.month() || i > duplicatedContract.Contract_Commercial_EDate__c.month()) {
                        qty = 0;
                    } else if(fullMonthFeb && i == 2) {
                        qty = qty != null ? qty : 0;
                    } else if (i == duplicatedContract.Contract_Commercial_BDate__c.month()) {
                        qty = (qty != null) ? (qty / daysInMonth) * daysBetween(duplicatedContract.Contract_Commercial_BDate__c, end_of_month(duplicatedContract.Contract_Commercial_BDate__c)) : 0;
                    } else if (i == duplicatedContract.Contract_Commercial_EDate__c.month()) {
                        qty = (qty != null) ? (qty / daysInMonth) * daysBetween(beginning_of_month(duplicatedContract.Contract_Commercial_EDate__c), duplicatedContract.Contract_Commercial_EDate__c) : 0;
                    } else {
                        qty = qty != null ? qty : 0;
                    }
                    qty = qty.setScale(contractFieldsScaleMap.get(fieldname), System.RoundingMode.HALF_UP);
                    duplicatedContract.put(fieldname, qty);
                    duplicatedTotalQty += qty;
                }
                duplicatedContract.Name = null;
                duplicatedContract.Contract_MultiYearReference__c = null;
                duplicatedContract.Status__c = String.isBlank(this.targetStatus) ? 'In preparation' : this.targetStatus;
                if (rtSimulation.contains(recordTypeDeveloperName)) {
                    duplicatedContract.Contract_Type__c = 'Simulation';
                }
                if (recordTypeDeveloperName == 'Target') {
                    duplicatedContract.Contract_Type__c = 'Target';
                }
                if (rtContract.contains(recordTypeDeveloperName)) {
                    duplicatedContract.Contract_Type__c = 'Contract';
                }
            }
        }

        public void addPolSaleConditionException() {
            // insert Pol_Sale_Condition_Exception__c to parent contract
            for (Pol_Sale_Condition_Exception__c item : this.contract.Sales_Conditions_Exception__r) {
                Pol_Sale_Condition_Exception__c newPolSaleConditionException = item.clone(false);
                this.polSalesConditionExceptionList.add(newPolSaleConditionException);
            }
        }
    }

    public static Date end_of_month(Date inputDate) {
        return inputDate.toStartOfMonth().addMonths(1).addDays(-1);
    }

    public static Date beginning_of_month(Date inputDate) {
        return inputDate.toStartOfMonth();
    }

    public static Integer daysBetween(Date startDate, Date endDate) {
        return startDate.daysBetween(endDate) + 1;
    }

    public class ContractConditionWrapper {
        public Contract_Discount__c parentCondition {get; set;}
        public List<Contract_Discount__c> subConditionList {get; set;}
        public ContractConditionWrapper() {
            this.subConditionList = new List<Contract_Discount__c>();
        }
        public Contract_Discount__c addDuplicatedCondition(ContractWrapper contractWrapper, Contract_Discount__c condition, Map<Id, Pol_Com_Condition__c> tariffConditionMappingMap, List<String> conditionsUpdatedFields, Integer conditionValueAmtScale, Integer conditionBaseTONegoScale, Integer conditionBaseTONegoYearBaseScale, Integer conditionBaseQtyNegoScale) {
            Contract_Discount__c newCondition = condition.clone(false);
            if (condition.Condition_Type__c != null) {
                if(tariffConditionMappingMap.containsKey(condition.Condition_Type__c)) { // get mapping tariff condition
                    newCondition.Condition_Type__c = tariffConditionMappingMap.get(condition.Condition_Type__c).Id;
                    newCondition.Condition_Type__r = tariffConditionMappingMap.get(condition.Condition_Type__c);
                    newCondition.Nego_Discount_Type__c = tariffConditionMappingMap.get(condition.Condition_Type__c).Nego_Discount_Type__c;
                } else {
                    newCondition.Condition_Type__r = condition.Condition_Type__r;
                }
            }
            // Increment start and end dates.
            newCondition.Disc_BDate__c = contractWrapper.duplicatedContract.Contract_BDate__c;
            newCondition.Disc_EDate__c = contractWrapper.duplicatedContract.Contract_EDate__c;
            newCondition.Disc_BDate_Y1__c = contractWrapper.duplicatedContract.Contract_BDate__c;
            newCondition.Disc_EDate_Y1__c = contractWrapper.duplicatedContract.Contract_EDate__c;
            if (condition.Disc_BDate_Y1__c == contractWrapper.contract.Contract_Commercial_BDate__c) {
                newCondition.Disc_BDate_Y1__c = contractWrapper.duplicatedContract.Contract_Commercial_BDate__c;
                newCondition.Disc_BDate__c = contractWrapper.duplicatedContract.Contract_Commercial_BDate__c;
            } else if (contractWrapper.duplicatedContract.Contract_Commercial_BDate__c < condition.Disc_BDate_Y1__c.addYears(1) && condition.Disc_BDate_Y1__c.addYears(1) < contractWrapper.duplicatedContract.Contract_Commercial_EDate__c) {
                newCondition.Disc_BDate_Y1__c = condition.Disc_BDate_Y1__c;
                newCondition.Disc_BDate__c = condition.Disc_BDate_Y1__c;
            } else if (condition.Disc_BDate_Y1__c < contractWrapper.duplicatedContract.Contract_Commercial_EDate__c) {
                newCondition.Disc_BDate_Y1__c = contractWrapper.duplicatedContract.Contract_Commercial_BDate__c;
                newCondition.Disc_BDate__c = contractWrapper.duplicatedContract.Contract_Commercial_BDate__c;
            }
            if (!condition.Condition_Type__r.Is_Yearly_Condition__c) {
                // Calculate amount
                Integer diffConditionDays = daysBetween(condition.Disc_BDate_Y1__c, condition.Disc_EDate_Y1__c);
                // Integer diffNewConditionDays = daysBetween(contractWrapper.commercialBDate, contractWrapper.commercialEDate);
                Integer diffNewConditionDays = daysBetween(newCondition.Disc_BDate_Y1__c, newCondition.Disc_EDate_Y1__c);
                Decimal amount = condition.Value_amt__c != null ? condition.Value_amt__c * diffNewConditionDays / diffConditionDays : null;
                amount = amount?.setScale(conditionValueAmtScale, System.RoundingMode.HALF_UP);
                newCondition.Value_per__c = condition.Value_per__c;
                newCondition.Value_per_Y1__c = condition.Value_per__c;
                newCondition.Value_amt__c = amount;
                newCondition.Value_amt_Y1__c = amount;
                if (!condition.Respects_Contract_Scope__c && condition.ContractSellIn__c == NULL) {
                    // calculate Base_TO_Nego__c, Base_Quantity_Nego__c
                    Decimal baseTONego = newCondition.Base_TO_Nego__c;
                    Decimal baseToYearBaseNego = newCondition.Base_TO_Nego_YearBase__c;
                    Decimal baseQtyNego = newCondition.Base_Quantity_Nego__c;
                    baseTONego = condition.Base_TO_Nego__c != null ? condition.Base_TO_Nego__c * diffNewConditionDays / diffConditionDays : null;
                    baseTONego = baseTONego?.setScale(conditionBaseTONegoScale, System.RoundingMode.HALF_UP);
                    newCondition.Base_TO_Nego__c = baseTONego;
                    baseToYearBaseNego = condition.Base_TO_Nego_YearBase__c != null ? condition.Base_TO_Nego_YearBase__c * diffNewConditionDays / diffConditionDays : null;
                    baseToYearBaseNego = baseToYearBaseNego?.setScale(conditionBaseTONegoYearBaseScale, System.RoundingMode.HALF_UP);
                    newCondition.Base_TO_Nego_YearBase__c = baseToYearBaseNego;
                    baseQtyNego = condition.Base_Quantity_Nego__c != null ? condition.Base_Quantity_Nego__c * diffNewConditionDays / diffConditionDays : null;
                    baseQtyNego = baseQtyNego?.setScale(conditionBaseQtyNegoScale, System.RoundingMode.HALF_UP);
                    newCondition.Base_Quantity_Nego__c = baseQtyNego;
                }
            }
            if (condition.Respects_Contract_Scope__c && condition.ContractSellIn__c == NULL) {
                newCondition.Base_TO_Nego__c = contractWrapper.duplicatedTotalTO;
                newCondition.Base_TO_Nego_YearBase__c = contractWrapper.duplicatedTotalTO;
                newCondition.Base_Quantity_Nego__c = contractWrapper.duplicatedTotalQty;
            }
            newCondition.Reference_condition__c = condition.Id;
            if (newCondition.first_invoice_date__c != null) {
                newCondition.first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
            }
            if (newCondition.Fist_Provision_Date__c != null) {
                newCondition.Fist_Provision_Date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
            }
            newCondition.Status__c = 'Open';
           /* Trg_Nego360_Contract_Discount_Handler.updateConditionDefaultValues(contractWrapper.duplicatedContract, newCondition, condition, newCondition.Condition_Type__r, false);*/
            return newCondition;
        }
    }
    /*
     * calculate sell_in for Promo details or Price_List details
     */
    /*public static Map<String, List<Decimal>> calculateSellin(Set<Id> pgSet, Set<Id> buSet, Set<Id> supplierSet,
                                                             Integer referenceYear, Set<Integer> yearSet, Set<Integer> yearP1Set, Set<Integer> yearP2Set, Set<Integer> yearP3Set,
                                                             String selectedSellInRule, Map<Integer, List<Integer>> manualSellInRulesMap)
    {
        // check security on access Purchases_Flow_PG__c fields
        String[] purchaseFlowPGAccessFields = new String[] {
            SObjectType.Purchases_Flow_PG__c.fields.Id.Name,
            SObjectType.Purchases_Flow_PG__c.fields.BusinessUnit__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.PG__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Supplier__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Year__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.YTD_QTY__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.YTD_SellIn_Qty_Promo__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.YE_SellIn_Qty__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty1__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty2__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty3__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty4__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty5__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty6__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty7__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty8__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty9__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty10__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty11__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.Qty12__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M1__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M2__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M3__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M4__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M5__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M6__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M7__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M8__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M9__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M10__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M11__c.Name,
            SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M12__c.Name
        };
        Map<String, List<Decimal>> calculatedSellinMap = new Map<String, List<Decimal>>();
        if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && selectedSellInRule != null && (selectedSellInRule == '12M' || selectedSellInRule == 'Manual')) {
            Integer beginMonth, endMonth, beginYear, endYear, P2, P1, N;
            P2 = referenceYear - 2;
            P1 = referenceYear - 1;
            N = referenceYear;
            if (selectedSellInRule == '12M') {
                Date previous12MDate = System.today().addMonths(-12), previousMonthDate = System.today().addMonths(-1);
                beginMonth = previous12MDate.month();
                beginYear = previous12MDate.year();
                endMonth = previousMonthDate.month();
                endYear = previousMonthDate.year();
            }
            Map<String, Map<Integer, Map<String, Decimal>>> totalsMap = new Map<String, Map<Integer, Map<String, Decimal>>>();
            String aggregateQuery = 'SELECT BusinessUnit__c BusinessUnit__c, PG__c PG__c, Supplier__c Supplier__c,';
            aggregateQuery += ' SUM(Qty1__c) Qty1__c, SUM(Qty2__c) Qty2__c, SUM(Qty3__c) Qty3__c, SUM(Qty4__c) Qty4__c, SUM(Qty5__c) Qty5__c,SUM(Qty6__c) Qty6__c,';
            aggregateQuery += ' SUM(Qty7__c) Qty7__c, SUM(Qty8__c) Qty8__c, SUM(Qty9__c) Qty9__c, SUM(Qty10__c) Qty10__c, SUM(Qty11__c) Qty11__c, SUM(Qty12__c) Qty12__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M1__c) SellIn_Qty_Promo_M1__c, SUM(SellIn_Qty_Promo_M2__c) SellIn_Qty_Promo_M2__c, SUM(SellIn_Qty_Promo_M3__c) SellIn_Qty_Promo_M3__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M4__c) SellIn_Qty_Promo_M4__c, SUM(SellIn_Qty_Promo_M5__c) SellIn_Qty_Promo_M5__c, SUM(SellIn_Qty_Promo_M6__c) SellIn_Qty_Promo_M6__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M7__c) SellIn_Qty_Promo_M7__c, SUM(SellIn_Qty_Promo_M8__c) SellIn_Qty_Promo_M8__c, SUM(SellIn_Qty_Promo_M9__c) SellIn_Qty_Promo_M9__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M10__c) SellIn_Qty_Promo_M10__c, SUM(SellIn_Qty_Promo_M11__c) SellIn_Qty_Promo_M11__c, SUM(SellIn_Qty_Promo_M12__c) SellIn_Qty_Promo_M12__c';
            aggregateQuery += ' FROM Purchases_Flow_PG__c';
            aggregateQuery += ' WHERE BusinessUnit__r.Status__c = \'Open\'';
            aggregateQuery += ' AND PG__c IN (\'' + String.join(new List<Id>(pgSet), '\', \'') + '\')';
            aggregateQuery += ' AND BusinessUnit__c IN (\'' + String.join(new List<Id>(buSet), '\', \'') + '\')';
            aggregateQuery += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\', \'') + '\')';
            if (NegoptimHelper.checkAccessibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGAccessFields)) {
                String aggregateQueryP2 = aggregateQuery + ' AND Year__c = ' + P2 + ' GROUP BY BusinessUnit__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryP2)) {
                    fillPurchasesTotals(totalsMap, P2, item);
                }
                String aggregateQueryP1 = aggregateQuery + ' AND Year__c = ' + P1 + ' GROUP BY BusinessUnit__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryP1)) {
                    fillPurchasesTotals(totalsMap, P1, item);
                }
                String aggregateQueryN = aggregateQuery + ' AND Year__c = ' + N + ' GROUP BY BusinessUnit__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryN)) {
                    fillPurchasesTotals(totalsMap, N, item);
                }
            }
            Boolean isExistMonthP2 = false, isExistMonthP1 = false, isExistMonthN = false;
            List<Integer> monthsP2, monthsP1, monthsN;
            if (selectedSellInRule == 'Manual' && !manualSellInRulesMap.isEmpty()) {
                monthsP2 = manualSellInRulesMap.get(P2);
                monthsP1 = manualSellInRulesMap.get(P1);
                monthsN = manualSellInRulesMap.get(N);
                if (monthsP2 != null && !monthsP2.isEmpty()) {
                    isExistMonthP2 = true;
                }
                if (monthsP1 != null && !monthsP1.isEmpty()) {
                    isExistMonthP1 = true;
                }
                if (monthsN != null && !monthsN.isEmpty()) {
                    isExistMonthN = true;
                }
            }
            for (String key : totalsMap.keySet()) {
                Map<Integer, Map<String, Decimal>> totalsYearMap = totalsMap.get(key);
                Decimal calculatedSellin = 0, calculateSellinPromo = 0;
                if (selectedSellInRule == '12M') {
                    if (totalsYearMap.containsKey(beginYear)) {
                        for (Integer i = beginMonth; i <= 12; i++) {
                            calculatedSellin += totalsYearMap.get(beginYear).containsKey('Qty' + i +'__c') ? totalsYearMap.get(beginYear).get('Qty' + i +'__c') : 0;
                            calculateSellinPromo += totalsYearMap.get(beginYear).containsKey('SellIn_Qty_Promo_M' + i +'__c') ? totalsYearMap.get(beginYear).get('SellIn_Qty_Promo_M' + i +'__c') : 0;
                        }
                    }
                    if (totalsYearMap.containsKey(endYear) && beginYear != endYear) {
                        for (Integer i = 1; i <= endMonth; i++) {
                            calculatedSellin += totalsYearMap.get(endYear).containsKey('Qty' + i +'__c') ? totalsYearMap.get(endYear).get('Qty' + i +'__c') : 0;
                            calculateSellinPromo += totalsYearMap.get(endYear).containsKey('SellIn_Qty_Promo_M' + i +'__c') ? totalsYearMap.get(endYear).get('SellIn_Qty_Promo_M' + i +'__c') : 0;
                        }
                    }
                } else if (selectedSellInRule == 'Manual') {
                    if (isExistMonthP2) {
                        if (totalsYearMap.containsKey(P2)) {
                            for (Integer monthP2 : monthsP2) {
                                calculatedSellin += totalsYearMap.get(P2).containsKey('Qty' + monthP2 +'__c') ? totalsYearMap.get(P2).get('Qty' + monthP2 +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(P2).containsKey('SellIn_Qty_Promo_M' + monthP2 +'__c') ? totalsYearMap.get(P2).get('SellIn_Qty_Promo_M' + monthP2 +'__c') : 0;
                            }
                        }
                    }
                    if (isExistMonthP1) {
                        if (totalsYearMap.containsKey(P1)) {
                            for (Integer monthP1 : monthsP1) {
                                calculatedSellin += totalsYearMap.get(P1).containsKey('Qty' + monthP1 +'__c') ? totalsYearMap.get(P1).get('Qty' + monthP1 +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(P1).containsKey('SellIn_Qty_Promo_M' + monthP1 +'__c') ? totalsYearMap.get(P1).get('SellIn_Qty_Promo_M' + monthP1 +'__c') : 0;
                            }
                        }
                    }
                    if (isExistMonthN) {
                        if (totalsYearMap.containsKey(N)) {
                            for (Integer monthN : monthsN) {
                                calculatedSellin += totalsYearMap.get(N).containsKey('Qty' + monthN +'__c') ? totalsYearMap.get(N).get('Qty' + monthN +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(N).containsKey('SellIn_Qty_Promo_M' + monthN +'__c') ? totalsYearMap.get(N).get('SellIn_Qty_Promo_M' + monthN +'__c') : 0;
                            }
                        }
                    }
                }
                calculatedSellinMap.put(key, new List<Decimal>{calculatedSellin, calculateSellinPromo});
            }
        } else if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && selectedSellInRule != null) {
            String query = 'SELECT Id, Year__c, BusinessUnit__c, PG__c, Supplier__c, YTD_QTY__c, YTD_SellIn_Qty_Promo__c, YE_SellIn_Qty__c';
            query += ' FROM Purchases_Flow_PG__c';
            query += ' WHERE BusinessUnit__r.Status__c = \'Open\'';
            query += ' AND PG__c IN (\'' + String.join(new List<Id>(pgSet), '\', \'') + '\')';
            query += ' AND BusinessUnit__c IN (\'' + String.join(new List<Id>(buSet), '\', \'') + '\')';
            query += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\', \'') + '\')';
            if (selectedSellInRule == 'YTD') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP1Set), ',') +')';
            } else if (selectedSellInRule == 'YE') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP1Set), ',') +')';
            } else if (selectedSellInRule == 'YE P1') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP2Set), ',') +')';
            } else if (selectedSellInRule == 'YE P2') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP3Set), ',') +')';
            } else if (selectedSellInRule == 'YE N1') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
            }
            if (NegoptimHelper.checkAccessibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGAccessFields)) {
                for (Purchases_Flow_PG__c item : Database.query(query)) {
                    String key = item.BusinessUnit__c + '' + item.PG__c + '' + item.Supplier__c;
                    if (selectedSellInRule == 'YTD') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YE_SellIn_Qty__c, null});
                    } else if (selectedSellInRule == 'YE P1') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE P2') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE N1') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YE_SellIn_Qty__c, null});
                    }
                }
            }
        }
        return calculatedSellinMap;
    }*/
    /**
     * calculate totals
     */
    /*private static void fillPurchasesTotals(Map<String, Map<Integer, Map<String, Decimal>>> totalsMap, Integer year, AggregateResult item) {
        String key = (Id) item.get('BusinessUnit__c') + '' + (Id) item.get('PG__c') + '' + (Id) item.get('Supplier__c');
        if (!totalsMap.containsKey(key)) {
            totalsMap.put(key, new Map<Integer, Map<String, Decimal>>());
        }
        if (!totalsMap.get(key).containsKey(year)) {
            totalsMap.get(key).put(year, new Map<String, Decimal>());
        }
        totalsMap.get(key).get(year).put('Qty1__c', item.get('Qty1__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty1__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty2__c', item.get('Qty2__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty2__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty3__c', item.get('Qty3__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty3__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty4__c', item.get('Qty4__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty4__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty5__c', item.get('Qty5__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty5__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty6__c', item.get('Qty6__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty6__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty7__c', item.get('Qty7__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty7__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty8__c', item.get('Qty8__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty8__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty9__c', item.get('Qty9__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty9__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty10__c', item.get('Qty10__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty10__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty11__c', item.get('Qty11__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty11__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty12__c', item.get('Qty12__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty12__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M1__c', item.get('SellIn_Qty_Promo_M1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M1__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M2__c', item.get('SellIn_Qty_Promo_M2__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M2__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M3__c', item.get('SellIn_Qty_Promo_M3__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M3__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M4__c', item.get('SellIn_Qty_Promo_M4__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M4__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M5__c', item.get('SellIn_Qty_Promo_M5__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M5__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M6__c', item.get('SellIn_Qty_Promo_M6__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M6__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M7__c', item.get('SellIn_Qty_Promo_M7__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M7__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M8__c', item.get('SellIn_Qty_Promo_M8__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M8__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M9__c', item.get('SellIn_Qty_Promo_M9__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M9__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M10__c', item.get('SellIn_Qty_Promo_M10__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M10__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M11__c', item.get('SellIn_Qty_Promo_M11__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M11__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M12__c', item.get('SellIn_Qty_Promo_M12__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M12__c'))) : 0);
    }*/

    
    public static Map<String, Map<String, Map<String, String>>> slabCalculationMapping = new Map<String, Map<String, Map<String, String>>>{
        'Nego' => new Map<String, Map<String, String>>{
            'TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_reach_nego__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONego__c.Name
            },
            'Prog TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_reach_nego__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONegoP1__c.Name
            },
            'Inc TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_TOInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONego__c.Name
            },
            'Inc Prog TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_TOInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseTONegoP1__c.Name
            },
            'Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_Qty__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNego__c.Name
            },
            'Prog Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_Qty__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNegoP1__c.Name
            },
            'Inc Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_QtyInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNego__c.Name
            },
            'Inc Prog Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_QtyInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyNegoP1__c.Name
            },
            'Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOut__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNego__c.Name
            },
            'Prog Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOut__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNegoP1__c.Name
            },
            'Inc Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOutInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNego__c.Name
            },
            'Inc Prog Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Nego_SellOutInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNego__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutNegoP1__c.Name
            }
        },
        'Actual'=> new Map<String, Map<String, String>>{
            'TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.slab_reach_actual__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFact__c.Name
            },
            'Prog TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.slab_reach_actual__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFactP1__c.Name
            },
            'Inc TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_TOInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFact__c.Name
            },
            'Inc Prog TO'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_TOInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseTOFactP1__c.Name
            },
            'Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_Qty__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFact__c.Name
            },
            'Prog Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_Qty__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFactP1__c.Name
            },
            'Inc Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_QtyInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFact__c.Name
            },
            'Inc Prog Qty'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_QtyInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseQtyFactP1__c.Name
            },
            'Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOut__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFact__c.Name
            },
            'Prog Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOut__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFactP1__c.Name
            },
            'Inc Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOutInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFact__c.Name
            },
            'Inc Prog Sell Out'=> new Map<String, String>{
                'res'=> SObjectType.Contract_Discount__c.fields.Slab_Reach_Actual_SellOutInc__c.Name,
                'v1'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFact__c.Name,
                'v2'=> SObjectType.Contract_Discount__c.fields.SlabBaseSellOutFactP1__c.Name
            }
        }
    };
    /**
     * Reach progressive slab Single/Bulk.
     * @param List<Contract_Discount__c> nConditions
     * On Before Insert or Update.
     **/
	public static void reachProgressiveSlab(List<Contract_Discount__c> nConditions, Map<Id, Pol_Com_Condition__c> tarrifConditionMap, Map<Id, Contract__c> contractsMap) {
        if (tarrifConditionMap == null && contractsMap == null) {
            Set<Id> contractIdSet = new Set<Id>();
            Set<Id> tarrifConditionIdSet = new Set<Id>();
            for (Contract_Discount__c item : nConditions) {
                if (item.Contract_DiscountAdvancedOrigin__c != null) {
                    continue;
                }
                contractIdSet.add(item.Contract__c);
                if (item.Condition_Type__c != null) {
                    tarrifConditionIdSet.add(item.Condition_Type__c);
                }
            }
            tarrifConditionMap = new Map<Id, Pol_Com_Condition__c>();
            if (!tarrifConditionIdSet.isEmpty()) {
                String[] tarrifConditionFields = new String[] {
                    SObjectType.Pol_Com_Condition__c.fields.Id.Name,
                    SObjectType.Pol_Com_Condition__c.fields.Is_Conditional__c.Name,
                    SObjectType.Pol_Com_Condition__c.fields.Parent_Condition__c.Name
                 };
                 if (NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionFields)) {
                     tarrifConditionMap = new Map<Id, Pol_Com_Condition__c> ([SELECT Is_Conditional__c, Parent_Condition__c, Capture_Discount_Product_Level__c
                                                                              FROM Pol_Com_Condition__c
                                                                              WHERE Id IN :tarrifConditionIdSet
                                                                              AND Parent_Condition__c = NULL]);
                 }
            }
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
                SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Index__c.Name,
                SObjectType.Contract__c.fields.Multi_Year_Total__c.Name,
                SObjectType.Contract__c.fields.Is_Managed_By_ExternalSource__c.Name
            };
            contractsMap = new Map<Id, Contract__c>();
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                contractsMap = new Map<Id, Contract__c>([SELECT Id, RecordType.DeveloperName, Contract_Commercial_BDate__c, Contract_Commercial_EDate__c,
                                                         Multi_Year_Index__c, Multi_Year_Total__c, Is_Managed_By_ExternalSource__c,
                                                         Total_TO__c, TO1__c/*, Linked_Contract_Group__r.Negotiated_TO__c*/
                                                         FROM Contract__c
                                                         WHERE Id IN :contractIdSet
                                                         AND RecordType.DeveloperName <> 'Signed_Copy']);
            }
        }
        Integer slabCount = 10;
        for (Contract_Discount__c item : nConditions) {
            if (item.Contract_DiscountAdvancedOrigin__c != null) {
                continue;
            }
            Contract__c contract = contractsMap.get(item.Contract__c);
            if (contract == null || item.Condition_Type__c == null || (item.Id == null && contract != null && contract.Is_Managed_By_ExternalSource__c == true)) {
                continue;
            }
            if (item.IsSlabRespectConditionScope__c) {
                item.NegoScopeSlab__c = item.Product_Scope__c;
                item.BusinessUnitSlab__c = item.BusinessUnitScope__c;
                item.SlabBDate__c = item.Disc_BDate__c;
                item.SlabEDate__c = item.Disc_EDate__c;
                item.SlabBaseTONegoP1__c = item.Base_TO_Nego_1__c;
                item.SlabBaseTONego__c = item.Base_TO_Nego__c;
                item.SlabBaseTOFactP1__c = item.Base_TO_Actual_1__c;
                item.SlabBaseTOFact__c = item.Base_TO_Actual__c;
                item.SlabBaseQtyNegoP1__c = item.Base_Quantity_Nego_1__c;
                item.SlabBaseQtyNego__c = item.Base_Quantity_Nego__c;
                item.SlabBaseQtyFactP1__c = item.Base_Quantity_Actual_1__c;
                item.SlabBaseQtyFact__c = item.Base_Quantity_Actual__c;
            }
            Pol_Com_Condition__c tarrifCondition = tarrifConditionMap.get(item.Condition_Type__c);
            if (tarrifCondition.Is_Conditional__c == true && tarrifCondition.Parent_Condition__c == null) {
	        	Decimal slab, incCalculatedRate = 0, slabPer = 0;
                Boolean isByBu = item.slab_calc_method__c != null && item.slab_calc_method__c.containsIgnoreCase('byBU');
                if(isByBu) continue;
                Boolean incCalculation = item.slab_calc_method__c != null && item.slab_calc_method__c.startsWith('Inc');
                Boolean isProgCalculation = item.slab_calc_method__c != null && item.slab_calc_method__c == 'Inc Prog TO';
                Boolean isTOForContractTO = item.slab_calc_method__c != null && item.slab_calc_method__c == 'TO forContractTO';
                //Boolean isTOGroupForBaseTO = item.slab_calc_method__c != null && item.slab_calc_method__c == 'TOGroup forBaseTO';
                Map<String, Decimal> slabCalMap = new Map<String, Decimal>();
                if (item.slab_target__c != null && item.Slab_Calc_Method_TO_Origin__c == 'Target') {
                    //TODO: Check For This Case
                    slab = item.slab_target__c;
                } else if (slabCalculationMapping.containsKey(item.Slab_Calc_Method_TO_Origin__c)) {
                    if (slabCalculationMapping.get(item.Slab_Calc_Method_TO_Origin__c).containsKey(item.slab_calc_method__c)) {
                        Map<String, String> slabCalculationUnitMap = slabCalculationMapping.get(item.Slab_Calc_Method_TO_Origin__c).get(item.slab_calc_method__c);
                        Boolean calcV2 = slabCalculationUnitMap.containsKey('v2');
                        Decimal v1 = (Decimal)item.get(slabCalculationUnitMap.get('v1'));
                        v1 = v1 != null ? v1 : 0;
                        Decimal v2 = calcV2 ? (Decimal)item.get(slabCalculationUnitMap.get('v2')) : 0;
                        v2 = v2 != null ? v2 : 0;
                        Decimal v3 = (v2 != null && v2 != 0 ? (v1 - v2) / v2 : 0) * 100;
                        Decimal diff = calcV2 ? v3 : v1;
                        for (Integer index = 1; index <= slabCount; index++) {
                            if (item.get('Slab_' + index + '__c') != null && diff >= (Decimal)item.get('Slab_' + index + '__c')) {
                                slab = index;
                            }
                        }
                    }
                }
                System.debug('slab >>' + slab);
                // Populate SlabReach__c field with the reached slab index
                if (slab != null) {
                    item.SlabReach__c = slab;
                } else {
                    item.SlabReach__c = null;
                }
                /*if (item.Slab_Calc_Method_TO_Origin__c == 'Actual') {
                    if (item.slab_calc_method__c == 'TO' || item.slab_calc_method__c == 'Prog TO') {
                        slab = item.slab_reach_actual__c;
                    } else if (item.slab_calc_method__c == 'Qty' || item.slab_calc_method__c == 'Prog Qty') {
                        slab = item.Slab_Reach_Actual_Qty__c;
                    } else if (item.slab_calc_method__c == 'Sell Out' || item.slab_calc_method__c == 'Prog Sell Out') {
                        slab = item.Slab_Reach_Actual_SellOut__c;
                    } else if (item.slab_calc_method__c == 'Inc Qty' || item.slab_calc_method__c == 'Inc Prog Qty') {
                        slab = item.Slab_Reach_Actual_QtyInc__c;
                    } else if (item.slab_calc_method__c == 'Inc Sell Out' || item.slab_calc_method__c == 'Inc Prog Sell out') {
                        slab = item.Slab_Reach_Actual_SellOutInc__c;
                    } else if (item.slab_calc_method__c == 'Inc TO' || item.slab_calc_method__c == 'Inc Prog TO') {
                        slab = item.Slab_Reach_Actual_TOInc__c;
                    }
                } else if (item.Slab_Calc_Method_TO_Origin__c == 'Nego') {
                    if (item.slab_calc_method__c == 'TO' || item.slab_calc_method__c == 'Prog TO') {
                        slab = item.Slab_reach_nego__c;
                    } else if (item.slab_calc_method__c == 'Qty' || item.slab_calc_method__c == 'Prog Qty') {
                        slab = item.Slab_Reach_Nego_Qty__c;
                    } else if (item.slab_calc_method__c == 'Sell Out' || item.slab_calc_method__c == 'Prog Sell Out') {
                        slab = item.Slab_Reach_Nego_SellOut__c;
                    } else if (item.slab_calc_method__c == 'Inc Qty' || item.slab_calc_method__c == 'Inc Prog Qty') {
                        slab = item.Slab_Reach_Nego_QtyInc__c;
                    } else if (item.slab_calc_method__c == 'Inc Sell Out' || item.slab_calc_method__c == 'Inc Prog Sell out') {
                        slab = item.Slab_Reach_Nego_SellOutInc__c;
                    } else if (item.slab_calc_method__c == 'Inc TO' || item.slab_calc_method__c == 'Inc Prog TO') {
                        slab = item.Slab_Reach_Nego_TOInc__c;
                    }
                } else if (item.slab_target__c != null && item.Slab_Calc_Method_TO_Origin__c == 'Target') {
                    //TODO: Check For This Case
                    slab = item.slab_target__c;
                }*/
                if (incCalculation || isProgCalculation) {
                    Decimal TONego;
                    Decimal progMultiplier = 1;
                    Decimal percentMultiplier = 1;
                    if (incCalculation) {
                        TONego = item.Base_TO_Nego__c != null ? (Decimal) item.Base_TO_Nego__c : 0;
                    }
                    if (isProgCalculation) {
                        percentMultiplier = 0.01;
                        TONego = item.Prog_TO_Nego__c != null ? (Decimal) item.Prog_TO_Nego__c : 0;
                        progMultiplier = item.Base_TO_Nego_1__c != null ? item.Base_TO_Nego_1__c : 1;
                    }
                    for (Integer i = 1; i <= slabCount; i++) {
                        if (item.get('Slab_' + i + '__c') != null && item.get('Slab_per_' + i + '__c') != null) {
                            Decimal currentSlabPer = (Decimal) item.get('Slab_per_' + i + '__c');
                            Decimal currentSlab = (Decimal) item.get('Slab_' + i + '__c');
                            if (i != slabCount) {
                                Decimal nextSlab = (Decimal) item.get('Slab_' + (i + 1) + '__c');
                                if (nextSlab != null && (TONego - nextSlab) >= 0) {
                                    Decimal diffWithNextSlab = (nextSlab - currentSlab) * percentMultiplier;
                                    incCalculatedRate += progMultiplier * (currentSlabPer / 100) * diffWithNextSlab;
                                } else {
                                    Decimal currentDiffWithBaseNego = (TONego - currentSlab) * percentMultiplier;
                                    if (currentDiffWithBaseNego >= 0) {
                                        incCalculatedRate += progMultiplier * (currentSlabPer / 100) * currentDiffWithBaseNego;
                                    }
                                }
                            } else {
                                Decimal currentDiffWithBaseNego = TONego - currentSlab;
                                if (currentDiffWithBaseNego >= 0) {
                                    incCalculatedRate += progMultiplier * (currentSlabPer / 100) * currentDiffWithBaseNego;
                                }
                            }
                        } else {
                            break;
                        }
                    }
                    incCalculatedRate = item.Base_TO_Nego__c != null && item.Base_TO_Nego__c != 0 ? incCalculatedRate / item.Base_TO_Nego__c * 100 : 0;
                }
                if (/*isTOGroupForBaseTO ||*/ isTOForContractTO) {
                    //Contract_Group__c contractGroup = item.Contract_Group_Reference__c != null ? contractGroupReferencesMap.get(item.Contract_Group_Reference__c) : null;
                    Decimal TONego = (/*isTOGroupForBaseTO ?
                                      (contractGroup != null && contractGroup.Negotiated_TO__c != null ? contractGroup.Negotiated_TO__c : 0)
                                      :*/ (item.Base_TO_Nego__c != null ? item.Base_TO_Nego__c : 0));
                    for (Integer i = 1; i <= slabCount; i++) {
                        if (item.get('Slab_' + i + '__c') != null && item.get('Slab_per_' + i + '__c') != null) {
                            Decimal currentSlabPer = (Decimal) item.get('Slab_per_' + i + '__c');
                            Decimal currentSlab = (Decimal) item.get('Slab_' + i + '__c');
                            if (i != slabCount) {
                                Decimal nextSlab = (Decimal) item.get('Slab_' + (i + 1) + '__c');
                                if (nextSlab != null && (TONego - nextSlab) < 0) {
                                    slabPer = currentSlabPer;
                                    break;
                                } else if (nextSlab == null) {
                                    slabPer = currentSlabPer;
                                    break;
                                }
                            } else {
                                slabPer = currentSlabPer;
                            }
                        } else {
                            break;
                        }
                    }
                }
                if (slab != null && slab <= slabCount) {
                    //TODO: Fill unit_amount__c instead of Value_amt__c
                    item.Value_amt__c = (Decimal)item.get('Slab_val_' + Integer.valueOf(slab) + '__c');
                    if (/*isTOGroupForBaseTO ||*/ isTOForContractTO) {
                        item.Value_per__c = slabPer.setScale(SObjectType.Contract_Discount__c.fields.Value_per__c.Scale);
                    } else if (!incCalculation) {
                        item.Value_per__c = (Decimal)item.get('Slab_per_' + Integer.valueOf(slab) + '__c');
                    } else {
                        item.Value_per__c = incCalculatedRate.setScale(SObjectType.Contract_Discount__c.fields.Value_per__c.Scale);
                    }
                } else {
                    item.Value_amt__c = null;
                    if (/*isTOGroupForBaseTO ||*/ isTOForContractTO) {
                        item.Value_per__c = slabPer.setScale(SObjectType.Contract_Discount__c.fields.Value_per__c.Scale);
                    } else if (!incCalculation) {
                        item.Value_per__c = null;
                    } else {
                        item.Value_per__c = incCalculatedRate.setScale(SObjectType.Contract_Discount__c.fields.Value_per__c.Scale);
                    }
                }
                // fill target slabs for all conditions years
                if (contract != null &&
                    contract.Contract_Commercial_BDate__c != null && contract.Contract_Commercial_EDate__c != null &&
                    contract.Multi_Year_Index__c != null && contract.Multi_Year_Total__c != null)
                {
                    Integer yearIndex = Integer.valueOf(contract.Multi_Year_Index__c);
                    for (Integer i = yearIndex; i <= Integer.valueOf(contract.Multi_Year_Total__c) && i <= 5; i++) {
                        item.put('Value_per_Y' + i + '__c', item.Value_per__c);
                        item.put('Value_amt_Y' + i + '__c',  item.Value_amt__c);
                    }
                }
                System.debug(' affter item.Value_per__c >>>' + item.Value_per__c);
            }
	    }
	}

    /**
     * populate Contract__c t_invoicingMode__c/t_IsInvoiceable__c
     * On Before Insert or Update.
     **/
    public static void updateContractInvoicingMode(NegoScope__c negoScope,
                                                   Contract__c item,
                                                   Boolean isUpdateValues,
                                                   InvoiceSettings ins_invoiceSettings,
                                                   Map<Id, String> contractRTIdsToDeveloperNameMap)
    {
        // NS "Advanced" invoicingMode management
        // Case 1 : NS "Advanced"
        Boolean checkInvoiceSettingForGeneration = false;
        if(negoScope.RecordType.DeveloperName == 'Advanced') {
            if (negoScope.InvoicingLevel__c == 'PartnerOnly' || negoScope.InvoicingLevel__c == null) {
                item.t_IsInvoiceable__c = false;
                item.t_invoicingMode__c = 'NotInvoiceable';
            } else {
                // myCash Settings - Invoice generation settings
                checkInvoiceSettingForGeneration = true;
            }
        } else {
            //Case 2 : NS <> "Advanced"
            if(!negoScope.NSLNKNegoScopeDetail__r.isEmpty()) {
                Integer countNSA = 0;
                for(NSLink__c nsLink : negoScope.NSLNKNegoScopeDetail__r) {
                    if(nsLink.NegoScopeMaster__r.InvoicingLevel__c == 'PartnerOnly' || nsLink.NegoScopeMaster__r.InvoicingLevel__c == 'AdvancedAndPartner') {
                        countNSA++;
                    }
                }
                if(countNSA > 0) {
                    // myCash Settings - Invoice generation settings
                    checkInvoiceSettingForGeneration = true;
                } else {
                    item.t_IsInvoiceable__c = false;
                    item.t_invoicingMode__c = 'NotInvoiceable';
                }
            } else {
                // myCash Settings - Invoice generation settings
                checkInvoiceSettingForGeneration = true;
            }
        }
        if(checkInvoiceSettingForGeneration && (item.Id == null || isUpdateValues)) {
            String recordTypeDeveloperName = contractRTIdsToDeveloperNameMap.get(item.RecordTypeId);
            if (ins_invoiceSettings.contractRecordTypesForGeneration != null
                && ins_invoiceSettings.contractStatusesForGeneration != null
                && ins_invoiceSettings.contractRecordTypesForGeneration.contains(recordTypeDeveloperName)
                && ins_invoiceSettings.contractStatusesForGeneration.get(recordTypeDeveloperName) != null
                && ins_invoiceSettings.contractStatusesForGeneration.get(recordTypeDeveloperName).contains(item.Status__c))
            {
                item.t_IsInvoiceable__c = true;
                item.t_invoicingMode__c = ins_invoiceSettings.invoiceGenerationMode == 'Automatic' ? 'InvoiceableAutomatic' : 'InvoiceableManual';
            } else {
                item.t_IsInvoiceable__c = false;
                item.t_invoicingMode__c = 'NotInvoiceable';
            }
        }
    }
    /**
     * populate Contract_Discount__c t_invoicingMode__c/t_IsInvoiceable__c
     * On After Update Contract__c | ON Before Insert or Update Contract_Discount__c.
     **/
    public static Boolean updateDiscountInvoicingMode(Contract__c contract,
                                                      Contract_Discount__c item,
                                                      Pol_Com_Condition__c tarrifCondition,
                                                      InvoiceSettings ins_invoiceSettings)
    {
        Boolean isUpdated = false;
        Boolean checkInvoiceSettingForGeneration = false;
        if ((tarrifCondition != null && !tarrifCondition.IsInvoiceable__c) || !contract.t_IsInvoiceable__c) {
            item.t_invoicingMode__c = 'NotInvoiceable';
            item.t_IsInvoiceable__c = false;
            isUpdated = true;
        } else if(contract.t_IsInvoiceable__c) {
                    //myCash Settings - Invoice generation settings
                    checkInvoiceSettingForGeneration = true;
                }
        if(checkInvoiceSettingForGeneration) {
            if (ins_invoiceSettings.generateDiscountsWoSettings == true) {
                if (item.t_invoicingMode__c != contract.t_invoicingMode__c || item.t_IsInvoiceable__c != contract.t_IsInvoiceable__c) {
                    item.t_invoicingMode__c = contract.t_invoicingMode__c;
                    item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                    isUpdated = true;
                }
            } else if(!ins_invoiceSettings.discountStatusesForGeneration.contains(item.Status__c)) {
                if (item.t_invoicingMode__c != 'NotInvoiceable') {
                    item.t_invoicingMode__c = 'NotInvoiceable';
                    item.t_IsInvoiceable__c = false;
                    isUpdated = true;
                }
            } else if (ins_invoiceSettings.generateAllValidatedDiscounts == true) {
                if (item.Valid__c == true) {
                    if (item.t_invoicingMode__c != contract.t_invoicingMode__c || item.t_IsInvoiceable__c != contract.t_IsInvoiceable__c) {
                        item.t_invoicingMode__c = contract.t_invoicingMode__c;
                        item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                        isUpdated = true;
                    }
                } else {
                    if (item.t_invoicingMode__c != 'NotInvoiceable') {
                        item.t_invoicingMode__c = 'NotInvoiceable';
                        item.t_IsInvoiceable__c = false;
                        isUpdated = true;
                    }
                }
            } else {
                if (item.t_invoicingMode__c != contract.t_invoicingMode__c || item.t_IsInvoiceable__c != contract.t_IsInvoiceable__c) {
                    item.t_invoicingMode__c = contract.t_invoicingMode__c;
                    item.t_IsInvoiceable__c = contract.t_IsInvoiceable__c;
                    isUpdated = true;
                }
            }
        }
        if(item.t_IsInvoiceable__c && tarrifCondition.IsCounterpartyInvoiceable__c == true) {
            item.t_invoicingMode__c = 'InvoiceableCounterparty';
            isUpdated = true;
        }
        return isUpdated;
    }

    /* Class ContractConsoWrapper */
    public class ContractConsoWrapper {
        // Period extension contract
        public Contract__c contractPT {get; set;}
        // Nego contract
        public Contract__c contractNego {get; set;}
        // Landing contract
        public Contract__c contractLanding {get; set;}
        // Nego_Base contract
        public Contract__c contractNegoBase {get; set;}
        // Nego_Base_Init contract
        public Contract__c contractNegoBaseInit {get; set;}
        // Nego_Base_Exit contract
        public Contract__c contractNegoBaseExit {get; set;}
        public Boolean isConsoNegoBaseExit {get; set;}
        public Boolean isConsoLanding {get; set;}
        public Boolean isConsoNegoBase {get; set;}
        public Boolean isConsoNegoBaseInit {get; set;}
        public Boolean isValidatedNegoBaseInit {get; set;}
        // Map<Condition key: Condition_Type + BusinessUnitScope__c + Product_Scope__c, All Conditions>
        public Map<String, ConditionConsoWrapper> conditionsMap {get; set;}
        public Set<String> conditionUnicityForNBSet {get; set;}
        // Map<Contract RecordType Id, Map<Condition key: Condition_Type + BusinessUnitScope__c + Product_Scope__c, All Conditions>>
        public Map<Id, Map<String, List<ConditionWrapper>>> parentConditionConsoMap {get; set;}
        public List<Contract_Discount__c> parentConditionsDeletedList {get; set;}
        public List<Contract_Discount__c> subConditionsDeletedList {get; set;}
        public Map<Id, Pol_Sale_Condition_Exception__c> polSalesConditionExceptionsMap {get; set;}
        public Pol_Sale_Condition_Exception__c polSalesConditionExceptionForNegoBase {get; set;}
        ////public Map<Id, Contract_Discount__c> originFromMoveContractDiscountMap {get; set;}
        public Map<String, Id> availableContractRTIds {get; set;}
        public Map<String, Id> contractRTIds {get; set;}
        public Map<String, Id> discountRTIds {get; set;}
        public Date topContractEndDate {
            get {
                if(topContractEndDate == null) {
                    if(this.contractNego != null && this.isConsoNegoBase) {
                        topContractEndDate = this.contractNego.Contract_EDate__c;
                    } else {
                        Integer negoYear = this.contractNego != null ? Integer.valueOf(this.contractNego.Reference_Year__c) : Integer.valueOf(this.contractPT.Reference_Year__c);
                        topContractEndDate = Date.newInstance(negoYear, 12, 31);
                    }
                }
                return topContractEndDate;
            }
            set;
        }
        public Set<String> tariffCoditionChangedInPrestationsNBSet {get; set;} // list of code budget changing in prestation NB

        public ContractConsoWrapper(Map<String, Id> contractRTIds, Map<String, Id> availableContractRTIds, Map<String, Id> discountRTIds,
                                    Boolean isConsoNegoBaseExit, Boolean isConsoLanding, Boolean isConsoNegoBase, Boolean isConsoNegoBaseInit, Boolean isValidatedNegoBaseInit)
        {
            this.conditionsMap = new Map<String, ConditionConsoWrapper>();
            this.conditionUnicityForNBSet = new Set<String>();
            this.parentConditionConsoMap = new Map<Id, Map<String, List<ConditionWrapper>>>();
            this.parentConditionsDeletedList = new List<Contract_Discount__c>();
            this.subConditionsDeletedList = new List<Contract_Discount__c>();
            this.polSalesConditionExceptionsMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
            ////this.originFromMoveContractDiscountMap = new Map<Id, Contract_Discount__c>();
            this.contractRTIds = contractRTIds;
            this.availableContractRTIds = availableContractRTIds;
            this.discountRTIds = discountRTIds;
            this.isConsoNegoBaseExit = isConsoNegoBaseExit;
            this.isConsoLanding = isConsoLanding;
            this.isConsoNegoBase = isConsoNegoBase;
            this.isConsoNegoBaseInit = isConsoNegoBaseInit;
            this.isValidatedNegoBaseInit = isValidatedNegoBaseInit;
            this.tariffCoditionChangedInPrestationsNBSet = new Set<String>();
        }

        // consolidate contracts PT/Nego
        private void consolidateContract() {
            if (this.contractPT != null || this.contractNego != null) {
                if (this.isConsoNegoBaseExit) {
                    if (availableContractRTIds.get('Nego_Base_Exit') != null) {
                        this.contractNegoBaseExit = upsertContract('Nego_Base_Exit', this.contractNegoBaseExit);
                    }
                } else {
                    if (this.isConsoLanding && availableContractRTIds.get('Landing') != null) {
                        this.contractLanding = upsertContract('Landing', this.contractLanding);
                    }
                    if (this.isConsoNegoBase) {
                        this.contractNegoBase = upsertContract('Nego_Base', this.contractNegoBase);
                        this.upsertPolSaleConditionException();
                    }
                    if (this.isConsoNegoBaseInit && availableContractRTIds.get('Nego_Base_Init') != null) {
                        this.contractNegoBaseInit = upsertContract('Nego_Base_Init', this.contractNegoBaseInit);
                    }
                }
            }
        }

        // upsert contracts Landing/Nego_Base/Nego_Base_Init
        private Contract__c upsertContract(String recordType, Contract__c contractConso) {
            Integer year = this.contractPT != null ? this.contractPT.Contract_BDate__c.year() : this.contractNego.Contract_BDate__c.year();
            Date beginDate = Date.newInstance(year, 1, 1);
            Date endDate = Date.newInstance(year, 12, 31);
            if(recordType == 'Nego_Base' && this.contractNego != null && this.contractPT == null) {
                beginDate = this.contractNego.Contract_BDate__c;
                endDate = this.contractNego.Contract_EDate__c;
            }
            if (contractConso == null) {
                contractConso = new Contract__c (Contract_Commercial_BDate__c = beginDate,
                                                 Contract_Commercial_EDate__c = endDate,
                                                 Contract_BDate__c = beginDate,
                                                 Contract_EDate__c = endDate,
												 BusinessUnitSource__c = this.contractNego != null ? this.contractNego.BusinessUnitSource__c : this.contractPT.BusinessUnitSource__c,
                                                 BusinessUnitContract__c = this.contractNego != null ? this.contractNego.BusinessUnitContract__c : this.contractPT.BusinessUnitContract__c,
                                                 Contract_Type__c = 'Contract',
                                                 Status__c = 'In preparation',
                                                 Supplier__c = this.contractNego != null ? this.contractNego.Supplier__c : this.contractPT.Supplier__c,
                                                 Supplier_Nego_Scope__c = this.contractNego != null ? this.contractNego.Supplier_Nego_Scope__c : this.contractPT.Supplier_Nego_Scope__c,
                                                 Supplier_Nego_Scope__r = this.contractNego != null ? this.contractNego.Supplier_Nego_Scope__r : this.contractPT.Supplier_Nego_Scope__r,
                                                 CompanySigned_By__c = this.contractNego != null ? this.contractNego.CompanySigned_By__c : this.contractPT.CompanySigned_By__c,
                                                 RecordTypeId = contractRTIds.get(recordType));
            }
            if (recordType == 'Landing' || recordType == 'Nego_Base_Init' || recordType == 'Nego_Base_Exit') {
                // if (recordType == 'Nego_Base_Exit') {
                //     contractConso.Status__c = 'Signed';
                // }
                contractConso.Markdown_Rate_Break__c = this.contractNego != null ? this.contractNego.Markdown_Rate_Break__c : this.contractPT.Markdown_Rate_Break__c;
                contractConso.Markdown_Rate_Promo__c = this.contractNego != null ? this.contractNego.Markdown_Rate_Promo__c : this.contractPT.Markdown_Rate_Promo__c;
                contractConso.Markdown_Rate_Theft__c = this.contractNego != null ? this.contractNego.Markdown_Rate_Theft__c : this.contractPT.Markdown_Rate_Theft__c;
                contractConso.Rise_Rate_YE__c = this.contractNego != null ? this.contractNego.Rise_Rate_YE__c : this.contractPT.Rise_Rate_YE__c;
                contractConso.Rise_Rate__c = this.contractNego != null ? this.contractNego.Rise_Rate__c : this.contractPT.Rise_Rate__c;
                contractConso.Depreciation_Rate_YE__c = this.contractNego != null ? this.contractNego.Depreciation_Rate_YE__c : this.contractPT.Depreciation_Rate_YE__c;
                contractConso.Depreciation_Rate__c = this.contractNego != null ? this.contractNego.Depreciation_Rate__c : this.contractPT.Depreciation_Rate__c;
                Integer riseRateCount = 10, depreciationRateCount = 3;
                for (Integer i = 1; i <= riseRateCount; i++) {
                    String fieldName = NegoptimHelper.normalizeAPIName('Rise_Rate' + i + '__c');
                    contractConso.put(fieldName, (this.contractNego != null ? this.contractNego.get(fieldName) : this.contractPT.get(fieldName)));
                }
                for (Integer i = 1; i <= depreciationRateCount; i++) {
                    String fieldName = NegoptimHelper.normalizeAPIName('Depreciation_Rate' + i + '__c');
                    contractConso.put(fieldName, (this.contractNego != null ? this.contractNego.get(fieldName) : this.contractPT.get(fieldName)));
                }
            }
            Decimal to, toFact, totalTO = 0, qty, qtyFact;
            for (integer i = 1; i <= 12 ; i++) {
                // calculate TO(i)/TO(i)_Fact/Qty(i)/Qty(i)_Fact
                to = (this.contractPT != null && this.contractPT.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c')) != null ? Decimal.valueOf(String.valueof((this.contractPT.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c'))))) : 0)
                    + (this.contractNego != null && this.contractNego.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c')) != null ? Decimal.valueOf(String.valueof((this.contractNego.get(NegoptimHelper.normalizeAPIName('TO' + i + '__c'))))) : 0);
                // toFact = (this.contractPT != null && this.contractPT.get('TO' + i + '_Fact__c') != null ? Decimal.valueOf(String.valueof((this.contractPT.get('TO' + i + '_Fact__c')))) : 0)
                //     + (this.contractNego != null && this.contractNego.get('TO' + i + '_Fact__c') != null ? Decimal.valueOf(String.valueof((this.contractNego.get('TO' + i + '_Fact__c')))) : 0);
                qty = (this.contractPT != null && this.contractPT.get(NegoptimHelper.normalizeAPIName('Qty' + i + '__c')) != null ? Decimal.valueOf(String.valueof((this.contractPT.get(NegoptimHelper.normalizeAPIName('Qty' + i + '__c'))))) : 0)
                    + (this.contractNego != null && this.contractNego.get(NegoptimHelper.normalizeAPIName('Qty' + i + '__c')) != null ? Decimal.valueOf(String.valueof((this.contractNego.get(NegoptimHelper.normalizeAPIName('Qty' + i + '__c'))))) : 0);
                // qtyFact = (this.contractPT != null && this.contractPT.get('Qty' + i + '_Fact__c') != null ? Decimal.valueOf(String.valueof((this.contractPT.get('Qty' + i + '_Fact__c')))) : 0)
                //     + (this.contractNego != null && this.contractNego.get('Qty' + i + '_Fact__c') != null ? Decimal.valueOf(String.valueof((this.contractNego.get('Qty' + i + '_Fact__c')))) : 0);
                totalTO += to != null ? to : 0;
                contractConso.put(NegoptimHelper.normalizeAPIName('TO' + i + '__c'), to);
                // contractConso.put('TO' + i + '_Fact__c', toFact);
                contractConso.put(NegoptimHelper.normalizeAPIName('Qty' + i + '__c'), qty);
                // contractConso.put('Qty' + i + '_Fact__c', qtyFact);
            }
            contractConso.Total_TO_Nego_YearBase__c = totalTO;
            contractConso.Parent_Contract__c = this.contractNego != null ? this.contractNego.Id : this.contractPT.Id;
            contractConso.Is_OnTop_Simulation__c = false;
            return contractConso;
        }

        public void upsertPolSaleConditionException() {
            // upsert Pol_Sale_Condition_Exception__c for contract Nego_Base
            Pol_Sale_Condition_Exception__c sourcePolSalesConditionException;
            if (this.contractNegoBase != null && this.contractNego != null && this.polSalesConditionExceptionsMap.containsKey(this.contractNego.Id)) {
                sourcePolSalesConditionException = this.polSalesConditionExceptionsMap.get(this.contractNego.Id);
                this.polSalesConditionExceptionForNegoBase = sourcePolSalesConditionException.clone(false);
                this.polSalesConditionExceptionForNegoBase.Contract__c = null;
                if (this.contractNegoBase.Id != null && this.polSalesConditionExceptionsMap.containsKey(this.contractNegoBase.Id)) {
                    this.polSalesConditionExceptionForNegoBase.Contract__c = this.contractNegoBase.Id;
                    this.polSalesConditionExceptionForNegoBase.Id = this.polSalesConditionExceptionsMap.get(this.contractNegoBase.Id).Id;
                    this.polSalesConditionExceptionForNegoBase.Ext_id__c = this.polSalesConditionExceptionsMap.get(this.contractNegoBase.Id).Ext_id__c;
                    this.polSalesConditionExceptionForNegoBase.Ext_Id2__c = this.polSalesConditionExceptionsMap.get(this.contractNegoBase.Id).Ext_id__c;
                }
            }
        }

        // consolidate conditions
        private void consolidateConditions() {
            List<ConditionWrapper> conditionDeletedList = new List<ConditionWrapper>();
            for (String conditionKey : this.conditionsMap.keySet()) {
                ConditionConsoWrapper wCondition = this.conditionsMap.get(conditionKey);
                if (!wCondition.conditionPTList.isEmpty() || !wCondition.conditionNegoList.isEmpty()) {
                    Boolean isMergePTAndNego = wCondition.conditionPTList.size() == 1 && wCondition.conditionNegoList.size() == 1;
                    if (isMergePTAndNego || wCondition.isUnicity) {
                        Contract_Discount__c ptCondition, negoCondition;
                        Decimal ptAmount = 0, ptPercent = 0, ptUnitAmount = 0, ptQty = 0, negoAmount = 0, negoPercent = 0, negoUnitAmount = 0, negoQty = 0;
                        Integer ptRank, negoRank;
                        if (wCondition.isUnicity && (wCondition.conditionPTList.size() > 1 || wCondition.conditionNegoList.size() > 1)) {
                            // conso Landing conditions
                            if (this.isConsoLanding && availableContractRTIds.get('Landing') != null) {
                                if (!wCondition.conditionPTList.isEmpty()) {
                                    for (Contract_Discount__c conditionPT : wCondition.conditionPTList) {
                                        wCondition.generateConditions(conditionKey, conditionPT, null, this.contractLanding, wCondition.conditionLandings, false);
                                    }
                                }
                                if (!wCondition.conditionNegoList.isEmpty()) {
                                    for (Contract_Discount__c conditionNego : wCondition.conditionNegoList) {
                                        wCondition.generateConditions(conditionKey, null, conditionNego, this.contractLanding, wCondition.conditionLandings, false);
                                    }
                                }
                            }
                            // conso NegoBaseInit
                            ptCondition = null; negoCondition = null;
                            wCondition.ptYTDNego = null;
                            wCondition.negoYTDNego = null;
                            wCondition.subDiscountsPTUnicityList = null;
                            wCondition.subDiscountsNegoUnicityList = null;
                            if (!wCondition.conditionPTList.isEmpty()) {
                                ptCondition = calculateDiscountValues(wCondition, wCondition.conditionPTList, true, false, true);
                            }
                            if (!wCondition.conditionNegoList.isEmpty()) {
                                negoCondition = calculateDiscountValues(wCondition, wCondition.conditionNegoList, true, false, false);
                                // check if discount EDate <= 31/12
                                if(negoCondition != null && negoCondition.Disc_EDate__c < this.topContractEndDate) {
                                    negoCondition = null;
                                }
                            }
                            if (ptCondition != null || negoCondition != null) {
                                if(this.isConsoNegoBaseExit) {
                                    if(availableContractRTIds.get('Nego_Base_Exit') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBaseExit, wCondition.conditionNegoBaseExits, true);
                                    }
                                } else {
                                    if(this.isConsoNegoBaseinit && !wCondition.isMoveNBI && !wCondition.isNewNBI && !wCondition.isExcludedToNegoBaseInit && availableContractRTIds.get('Nego_Base_Init') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBaseInit, wCondition.conditionNegoBaseInits, true);
                                    }
                                    // conso NegoBase
                                    ptCondition = null; negoCondition = null;
                                    if (!wCondition.conditionPTList.isEmpty()) {
                                        ptCondition = calculateDiscountValues(wCondition, wCondition.conditionPTList, true, true, true);
                                    }
                                    if (!wCondition.conditionNegoList.isEmpty()) {
                                        negoCondition = calculateDiscountValues(wCondition, wCondition.conditionNegoList, true, true, false);
                                        // check if discount EDate <= 31/12
                                        if(negoCondition != null && negoCondition.Disc_EDate__c < this.topContractEndDate) {
                                            negoCondition = null;
                                        }
                                    }
                                    if (ptCondition != null || negoCondition != null) {
                                        Id productScopeId = negoCondition != null ? negoCondition.Product_Scope__c : ptCondition.Product_Scope__c;
                                        Id buScopeId = negoCondition != null ? negoCondition.BusinessUnitScope__c : ptCondition.BusinessUnitScope__c;
                                        String conditionUnicityKey = wCondition.tariffCondition.Id + '' + buScopeId + '' + productScopeId;
                                        // check if code budget changed in prestation NB
                                        Boolean isCodeBudgetChangedInPrestationsNB = (!this.tariffCoditionChangedInPrestationsNBSet.isEmpty()
                                                                                      && negoCondition != null
                                                                                      && negoCondition.Condition_Type__c != null
                                                                                      && this.tariffCoditionChangedInPrestationsNBSet.contains(negoCondition.Condition_Type__r.Name));
                                        if(this.isConsoNegoBase && !wCondition.isMoveNB && !wCondition.isNewNB && !wCondition.isExcludedToNegoBaseInit && !isCodeBudgetChangedInPrestationsNB
                                           && !this.conditionUnicityForNBSet.contains(conditionUnicityKey))
                                        {
                                            // check duplicable
                                            if(ptCondition != null && !ptCondition.is_Duplicable__c) {
                                                ptCondition = null;
                                            }
                                            if(negoCondition != null && !negoCondition.is_Duplicable__c) {
                                                negoCondition = null;
                                            }
                                            if (ptCondition != null || negoCondition != null) {
                                                wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBase, wCondition.conditionNegoBases, true);
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            ptCondition = !wCondition.conditionPTList.isEmpty() ? wCondition.conditionPTList[0] : null;
                            negoCondition = !wCondition.conditionNegoList.isEmpty() ? wCondition.conditionNegoList[0] : null;
                            wCondition.ptYTDNego = ptCondition != null && ptCondition.YTD_Nego__c != null ? ptCondition.YTD_Nego__c : null;
                            wCondition.negoYTDNego = negoCondition != null && negoCondition.YTD_Nego__c != null ? negoCondition.YTD_Nego__c : null;
                            if(this.isConsoNegoBaseExit) {
                                if(availableContractRTIds.get('Nego_Base_Exit') != null) {
                                    wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBaseExit, wCondition.conditionNegoBaseExits, true);
                                }
                            } else {
                                if (this.isConsoLanding && availableContractRTIds.get('Landing') != null) {
                                    // conso Landing conditions
                                    ptAmount = ptCondition != null && ptCondition.Value_amt__c != null && ptCondition.Value_amt__c != 0 ? ptCondition.Value_amt__c : null;
                                    ptPercent = ptCondition != null && ptCondition.Value_per__c != null && ptCondition.Value_per__c != 0 ? ptCondition.Value_per__c : null;
                                    ptUnitAmount = ptCondition != null && ptCondition.Unit_amount__c != null && ptCondition.Unit_amount__c != 0 ? ptCondition.Unit_amount__c : null;
                                    ptRank = ptCondition != null && ptCondition.Rank__c != null && ptCondition.Rank__c != 0 ? Integer.valueOf(ptCondition.Rank__c) : null;
                                    negoAmount = negoCondition != null && negoCondition.Value_amt__c != null && negoCondition.Value_amt__c != 0 ? negoCondition.Value_amt__c : null;
                                    negoPercent = negoCondition != null && negoCondition.Value_per__c != null && negoCondition.Value_per__c != 0 ? negoCondition.Value_per__c : null;
                                    negoUnitAmount = negoCondition != null && negoCondition.Unit_amount__c != null && negoCondition.Unit_amount__c != 0 ? negoCondition.Unit_amount__c : null;
                                    negoRank = negoCondition != null && negoCondition.Rank__c != null && negoCondition.Rank__c != 0 ? Integer.valueOf(negoCondition.Rank__c) : null;
                                    if((ptCondition != null && !ptCondition.Respects_Contract_Scope__c)
                                       || (negoCondition != null && !negoCondition.Respects_Contract_Scope__c)
                                       || ptPercent != negoPercent
                                       || ptAmount != null || negoAmount != null
                                       || ptUnitAmount != null || negoUnitAmount != null
                                       || (ptPercent == negoPercent && ptRank != negoRank))
                                    {
                                        if(ptCondition != null) wCondition.generateConditions(conditionKey, ptCondition, null, this.contractLanding, wCondition.conditionLandings, false);
                                        if(negoCondition != null) wCondition.generateConditions(conditionKey, null, negoCondition, this.contractLanding, wCondition.conditionLandings, false);
                                    } else {
                                        wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractLanding, wCondition.conditionLandings, false);
                                    }
                                }
                                // check if discount EDate <= 31/12 for NB/NBI
                                if(negoCondition != null && negoCondition.Disc_EDate__c < this.topContractEndDate) {
                                    negoCondition = null;
                                }
                                if (ptCondition != null || negoCondition != null) {
                                    if(this.isConsoNegoBaseinit && !wCondition.isMoveNBI && !wCondition.isNewNBI && !wCondition.isExcludedToNegoBaseInit && availableContractRTIds.get('Nego_Base_Init') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBaseInit, wCondition.conditionNegoBaseInits, true);
                                    }
                                    Id productScopeId = negoCondition != null ? negoCondition.Product_Scope__c : ptCondition.Product_Scope__c;
                                    Id buScopeId = negoCondition != null ? negoCondition.BusinessUnitScope__c : ptCondition.BusinessUnitScope__c;
                                    String conditionUnicityKey = wCondition.tariffCondition.Id + '' + buScopeId + '' + productScopeId;
                                    // check if code budget changed in prestation NB
                                    Boolean isCodeBudgetChangedInPrestationsNB = (!this.tariffCoditionChangedInPrestationsNBSet.isEmpty()
                                                                                  && negoCondition != null
                                                                                  && this.tariffCoditionChangedInPrestationsNBSet.contains(negoCondition.Condition_Type__r.Name));
                                    if(this.isConsoNegoBase && !wCondition.isMoveNB && !wCondition.isNewNB && !wCondition.isExcludedToNegoBaseInit && !isCodeBudgetChangedInPrestationsNB
                                       && !this.conditionUnicityForNBSet.contains(conditionUnicityKey))
                                    {
                                           // check duplicable
                                           if(ptCondition != null && !ptCondition.is_Duplicable__c) {
                                               ptCondition = null;
                                           }
                                           if(negoCondition != null && !negoCondition.is_Duplicable__c) {
                                            negoCondition = null;
                                        }
                                        if (ptCondition != null || negoCondition != null) {
                                            wCondition.generateConditions(conditionKey, ptCondition, negoCondition, this.contractNegoBase, wCondition.conditionNegoBases, true);
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (!wCondition.conditionPTList.isEmpty()) {
                            for (Contract_Discount__c ptCondition : wCondition.conditionPTList) {
                                if(this.isConsoNegoBaseExit) {
                                    if(availableContractRTIds.get('Nego_Base_Exit') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, null, this.contractNegoBaseExit, wCondition.conditionNegoBaseExits, true);
                                    }
                                } else {
                                    if (this.isConsoLanding && availableContractRTIds.get('Landing') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, null, this.contractLanding, wCondition.conditionLandings, false);
                                    }
                                    if(this.isConsoNegoBaseinit && !wCondition.isMoveNBI && !wCondition.isNewNBI && !wCondition.isExcludedToNegoBaseInit && availableContractRTIds.get('Nego_Base_Init') != null) {
                                        wCondition.generateConditions(conditionKey, ptCondition, null, this.contractNegoBaseInit, wCondition.conditionNegoBaseInits, true);
                                    }
                                    String conditionUnicityKey = wCondition.tariffCondition.Id + '' + ptCondition.BusinessUnitScope__c + '' + ptCondition.Product_Scope__c;
                                    if(this.isConsoNegoBase && !wCondition.isMoveNB && !wCondition.isNewNB && !wCondition.isExcludedToNegoBaseInit && !this.conditionUnicityForNBSet.contains(conditionUnicityKey)) {
                                        // check duplicable
                                        if(!ptCondition.is_Duplicable__c) continue;
                                        wCondition.generateConditions(conditionKey, ptCondition, null, this.contractNegoBase, wCondition.conditionNegoBases, true);
                                    }
                                }
                            }
                        }
                        if (!wCondition.conditionNegoList.isEmpty()) {
                            for (Contract_Discount__c negoCondition : wCondition.conditionNegoList) {
                                if(this.isConsoNegoBaseExit) {
                                    if(availableContractRTIds.get('Nego_Base_Exit') != null) {
                                        wCondition.generateConditions(conditionKey, null, negoCondition, this.contractNegoBaseExit, wCondition.conditionNegoBaseExits, true);
                                    }
                                } else {
                                    if (this.isConsoLanding && availableContractRTIds.get('Landing') != null) {
                                        wCondition.generateConditions(conditionKey, null, negoCondition, this.contractLanding, wCondition.conditionLandings, false);
                                    }
                                    // check if discount EDate <= 31/12
                                    if(negoCondition.Disc_EDate__c < this.topContractEndDate) continue;
                                    if(this.isConsoNegoBaseinit && !wCondition.isMoveNBI && !wCondition.isNewNBI && !wCondition.isExcludedToNegoBaseInit && availableContractRTIds.get('Nego_Base_Init') != null) {
                                        wCondition.generateConditions(conditionKey, null, negoCondition, this.contractNegoBaseInit, wCondition.conditionNegoBaseInits, true);
                                    }
                                    String conditionUnicityKey = wCondition.tariffCondition.Id + '' + negoCondition.BusinessUnitScope__c + '' + negoCondition.Product_Scope__c;
                                    // check if code budget changed in prestation NB
                                    Boolean isCodeBudgetChangedInPrestationsNB = (!this.tariffCoditionChangedInPrestationsNBSet.isEmpty() && negoCondition != null
                                                                                  && this.tariffCoditionChangedInPrestationsNBSet.contains(negoCondition.Condition_Type__r.Name));
                                    if(this.isConsoNegoBase && !wCondition.isMoveNB && !wCondition.isNewNB && !wCondition.isExcludedToNegoBaseInit && !isCodeBudgetChangedInPrestationsNB
                                       && !this.conditionUnicityForNBSet.contains(conditionUnicityKey))
                                    {
                                        // check duplicable
                                        if(!negoCondition.is_Duplicable__c) continue;
                                        wCondition.generateConditions(conditionKey, null, negoCondition, this.contractNegoBase, wCondition.conditionNegoBases, true);
                                    }
                                }
                            }
                        }
                    }
                    // delete existing condition conso not updated
                    if(this.isConsoNegoBaseExit) {
                        if (!wCondition.conditionNegoBaseExits.isEmpty()) {
                            for (ConditionWrapper item : wCondition.conditionNegoBaseExits) {
                                if (item.conditionConso.Id != null && wCondition.conditionConsosMap.containsKey(item.conditionConso.Id)) {
                                    conditionDeletedList.add(item);
                                }
                            }
                        }
                    } else {
                        if (this.isConsoLanding && !wCondition.conditionLandings.isEmpty()) {
                            for (ConditionWrapper item : wCondition.conditionLandings) {
                                if (item.conditionConso.Id != null && wCondition.conditionConsosMap.containsKey(item.conditionConso.Id)) {
                                    conditionDeletedList.add(item);
                                }
                            }
                        }
                        if (this.isConsoNegoBase && !wCondition.conditionNegoBases.isEmpty()) {
                            for (ConditionWrapper item : wCondition.conditionNegoBases) {
                                if (item.conditionConso.Id != null && wCondition.conditionConsosMap.containsKey(item.conditionConso.Id)) {
                                    conditionDeletedList.add(item);
                                }
                            }
                        }
                        if (this.isConsoNegoBaseinit && !wCondition.conditionNegoBaseInits.isEmpty()) {
                            for (ConditionWrapper item : wCondition.conditionNegoBaseInits) {
                                if (item.conditionConso.Id != null && wCondition.conditionConsosMap.containsKey(item.conditionConso.Id)) {
                                    conditionDeletedList.add(item);
                                }
                            }
                        }
                    }
                } else {
                    if(this.isConsoNegoBaseExit) {
                        if (!wCondition.conditionNegoBaseExits.isEmpty()) {
                            conditionDeletedList.addAll(wCondition.conditionNegoBaseExits);
                        }
                    } else {
                        // check deleted conditions
                        if (this.isConsoLanding && !wCondition.conditionLandings.isEmpty()) {
                            conditionDeletedList.addAll(wCondition.conditionLandings);
                        }
                        if (this.isConsoNegoBase && !wCondition.conditionNegoBases.isEmpty()) {
                            conditionDeletedList.addAll(wCondition.conditionNegoBases);
                        }
                        if (this.isConsoNegoBaseinit && !wCondition.conditionNegoBaseInits.isEmpty()) {
                            conditionDeletedList.addAll(wCondition.conditionNegoBaseInits);
                        }
                    }
                }
            }
            if (!conditionDeletedList.isEmpty()) {
                for (ConditionWrapper item : conditionDeletedList) {
                    item.conditionConso.Value_amt__c = null;
                    item.conditionConso.Value_amt_Y1__c = null;
                    item.conditionConso.Value_Per__c = null;
                    item.conditionConso.Value_per_Y1__c = null;
                    item.conditionConso.unit_amount__c = null;
                    item.conditionConso.Status__c = 'Deleted';
                    this.parentConditionsDeletedList.add(item.conditionConso);
                }
            }
        }

        private Contract_Discount__c calculateDiscountValues(ConditionConsoWrapper wCondition, List<Contract_Discount__c> conditionList, Boolean isConsoNBI_NB_NBE, Boolean isNegoBase, Boolean isPE) {
            Decimal amount = 0, percent = 0, unitAmount = 0, qty = 0, YTDNego = 0, ptAmount, ptPercent, ptUnitAmount;
            Contract_Discount__c condition;
            Set<Id> subConditionTypeSet = new Set<Id>();
            if (isPE && wCondition.subDiscountsPTUnicityList == null) {
                wCondition.subDiscountsPTUnicityList = new List<Contract_Discount__c>();
            } else if(wCondition.subDiscountsNegoUnicityList == null) {
                wCondition.subDiscountsNegoUnicityList = new List<Contract_Discount__c>();
            }
            for (Contract_Discount__c item : conditionList) {
                // check if discount EDate <= 31/12
                if (isConsoNBI_NB_NBE && (item.Is_Excluded_To_NegoBase__c || (!isPE && item.Disc_EDate__c < this.topContractEndDate))) {
                    continue;
                }
                // check duplicable
                if(isNegoBase && !item.is_Duplicable__c) {
                    continue;
                }
                if (isPE) {
                    ptAmount = item.Value_amt__c != null && item.Value_amt__c != 0 ? item.Value_amt__c : null;
                    ptPercent = item.Value_Per__c != null && item.Value_Per__c != 0 ? item.Value_Per__c : null;
                    ptUnitAmount = item.unit_amount__c != null && item.unit_amount__c != 0 ? item.unit_amount__c : null;
                    if (isConsoNBI_NB_NBE && ptAmount == null && ptUnitAmount == null) {
                        continue;
                    }
                }
                if(!isNegoBase && wCondition.subDiscountsMap.containsKey(item.Id)) {
                    for (Contract_Discount__c subCondition : wCondition.subDiscountsMap.get(item.Id)) {
                        String subConditionType = subCondition.Condition_Type__r.Duplication_Discount_Mapping__c != null ? subCondition.Condition_Type__r.Duplication_Discount_Mapping__c : subCondition.Condition_Type__c;
                        if(wCondition.isEGA1
                           && String.isNotBlank(subCondition.Condition_Type__r.Original_code__c)
                           && wCondition.subTariffConditionEGA1Map.containsKey(subCondition.Condition_Type__r.Original_code__c))
                        {
                            subConditionType = wCondition.subTariffConditionEGA1Map.get(subCondition.Condition_Type__r.Original_code__c).Id;
                        }
                        if(!subConditionTypeSet.contains(subConditionType)) {
                            subConditionTypeSet.add(subConditionType);
                            if (isPE) {
                                wCondition.subDiscountsPTUnicityList.add(subCondition);
                            } else {
                                wCondition.subDiscountsNegoUnicityList.add(subCondition);
                            }
                        }
                    }
                }
                if (condition == null) {
                    condition = item.clone(true);
                }
                amount += item.Value_amt__c != null ? item.Value_amt__c : 0;
                percent += item.Value_Per__c != null ? item.Value_Per__c : 0;
                unitAmount += item.unit_amount__c != null ? item.unit_amount__c : 0;
                qty += item.Base_Quantity_Nego__c != null ? item.Base_Quantity_Nego__c : 0;
                YTDNego += item.YTD_Nego__c != null ? item.YTD_Nego__c : 0;
                // calculate Proof_counterparty_number_total__c
                wCondition.calculateSubConditionsValues(item, isConsoNBI_NB_NBE, isNegoBase, isPE);
            }
            if (condition != null) {
                condition.Value_amt__c = amount != 0 ? amount : null;
                condition.Value_Per__c = percent != 0 ? percent : null;
                condition.unit_amount__c = unitAmount != 0 ? unitAmount : null;
                condition.Base_Quantity_Nego__c = qty != 0 ? qty : null;
                if (isPE) {
                    wCondition.ptYTDNego = YTDNego;
                } else {
                    wCondition.negoYTDNego = YTDNego;
                }
            }
            return condition;
        }
    }

    /* Class ConditionConsoWrapper */
    public class ConditionConsoWrapper {
        public ContractConsoWrapper wContract {get; set;}
        // Period_Extension condition
        public List<Contract_Discount__c> conditionPTList {get; set;}
        public List<Contract_Discount__c> subDiscountsPTUnicityList {get; set;}
        // Nego condition
        public List<Contract_Discount__c> conditionNegoList {get; set;}
        public List<Contract_Discount__c> subDiscountsNegoUnicityList {get; set;}
        // Landing condition
        public List<ConditionWrapper> conditionLandings {get; set;}
        // Nego_Base condition
        public List<ConditionWrapper> conditionNegoBases {get; set;}
        // Nego_Base_Init condition
        public List<ConditionWrapper> conditionNegoBaseInits {get; set;}
        // Nego_Base_Exit condition
        public List<ConditionWrapper> conditionNegoBaseExits {get; set;}
        Map<Id, Boolean> conditionConsosMap {get; set;}
        public List<String> conditionsFields {get; set;}
        public Pol_Com_Condition__c tariffCondition {get; set;}
        public Boolean isUnicity {get; set;}
        public Decimal ptYTDNego {get; set;}
        public Decimal negoYTDNego {get; set;}
        public Decimal ptBaseTONego {get; set;}
        public Decimal ptBaseTOTariffNego {get; set;}
        public Boolean isMoveNBI {get; set;}
        public Boolean isMoveNB {get; set;}
        public Boolean isExcludedToNegoBaseInit {get; set;}
        public Boolean isExcludedToNegoBase {get; set;}
        public Boolean isNewNBI {get; set;}
        public Boolean isNewNB {get; set;}
        // Map for calculate Proof_counterparty_number_total__c on sub conditions
        public Map<String, Contract_Discount__c> subConditionsCalculationMap {get; set;}
        public Boolean isEGA1 {get; set;}
        public Map<String, Pol_Com_Condition__c> subTariffConditionEGA1Map {get; set;}
        public Map<Id, List<Contract_Discount__c>> subDiscountsMap {get; set;}

        public ConditionConsoWrapper (ContractConsoWrapper wContract, List<String> conditionsFields, Pol_Com_Condition__c tariffCondition, Boolean isUnicity) {
            this.wContract = wContract;
            this.conditionsFields = conditionsFields;
            this.conditionPTList = new List<Contract_Discount__c>();
            this.conditionNegoList = new List<Contract_Discount__c>();
            this.conditionLandings = new List<ConditionWrapper>();
            this.conditionNegoBases = new List<ConditionWrapper>();
            this.conditionNegoBaseInits = new List<ConditionWrapper>();
            this.conditionNegoBaseExits = new List<ConditionWrapper>();
            this.conditionConsosMap = new Map<Id, Boolean>();
            this.tariffCondition = tariffCondition;
            this.isUnicity = isUnicity;
            this.isMoveNBI = false;
            this.isMoveNB = false;
            this.isExcludedToNegoBaseInit = false;
            this.isExcludedToNegoBase = false;
            this.isNewNBI = false;
            this.isNewNB = false;
            this.subConditionsCalculationMap = new Map<String, Contract_Discount__c>();
            this.isEGA1 = false;
            this.subTariffConditionEGA1Map = new Map<String, Pol_Com_Condition__c>();
            this.subDiscountsMap = new Map<Id, List<Contract_Discount__c>>();
        }

        // generate condition Landing/Nego_Base/Nego_Base_Init/Nego_Base_Exit
        private List<ConditionWrapper> generateConditions(String conditionKey, Contract_Discount__c conditionPT, Contract_Discount__c conditionNego,
                                                          Contract__c contract, List<ConditionWrapper> conditionsConsos, Boolean isConsoNBI_NB_NBE)
        {
            Contract_Discount__c ptCondition = conditionPT, negoCondition = conditionNego;
            Decimal ptAmount, ptPercent, ptUnitAmount, negoAmount, negoPercent, negoUnitAmount;
            Integer ptRank, negoRank;
            ptAmount = ptCondition != null && ptCondition.Value_amt__c != null && ptCondition.Value_amt__c != 0 ? ptCondition.Value_amt__c : null;
            ptPercent = ptCondition != null && ptCondition.Value_Per__c != null && ptCondition.Value_Per__c != 0 ? ptCondition.Value_Per__c : null;
            ptUnitAmount = ptCondition != null && ptCondition.unit_amount__c != null && ptCondition.unit_amount__c != 0 ? ptCondition.unit_amount__c : null;
            ptRank = ptCondition != null && ptCondition.Rank__c != null && ptCondition.Rank__c != 0 ? Integer.valueOf(ptCondition.Rank__c) : null;
            negoAmount = negoCondition != null && negoCondition.Value_amt__c != null && negoCondition.Value_amt__c != 0 ? negoCondition.Value_amt__c : null;
            negoPercent = negoCondition != null && negoCondition.Value_Per__c != null && negoCondition.Value_Per__c != 0 ? negoCondition.Value_Per__c : null;
            negoUnitAmount = negoCondition != null && negoCondition.unit_amount__c != null && negoCondition.unit_amount__c != 0 ? negoCondition.unit_amount__c : null;
            negoRank = negoCondition != null && negoCondition.Rank__c != null && negoCondition.Rank__c != 0 ? Integer.valueOf(negoCondition.Rank__c) : null;
            if (isConsoNBI_NB_NBE) {
                ptCondition = conditionPT != null && !conditionPT.Is_Excluded_To_NegoBase__c ? conditionPT : null;
                negoCondition = conditionNego != null && !conditionNego.Is_Excluded_To_NegoBase__c ? conditionNego : null;
            }
            // Keep condition PT when contract is NB/NBI and percent/amount is null
            if (negoCondition == null && (ptCondition == null || (isConsoNBI_NB_NBE && ptAmount == null && ptUnitAmount == null))) {
                return new List<ConditionWrapper>();
            }
            Boolean isMergePT = false;
            if (ptCondition != null && negoCondition != null) {
                if(isConsoNBI_NB_NBE) {
                    if (ptPercent == null &&
                        ((ptAmount != null || ptUnitAmount != null) && (negoPercent != null || negoAmount != null || negoUnitAmount != null)))
                    {
                        isMergePT = true;
                    } else if (ptAmount != null || ptUnitAmount != null) {
                        ptCondition.Value_per__c = null;
                        ptCondition.Rank__c = negoCondition.Rank__c;
                        isMergePT = true;
                    }
                } else {
                    // case Landing
                    if(ptPercent != null && (ptPercent == negoPercent && ptRank == negoRank) && ptAmount == null && negoAmount == null && ptUnitAmount == null && negoUnitAmount == null) {
                        ptCondition.Value_per__c = null;
                        isMergePT = true;
                    }
                }
                if (!isMergePT) {
                    this.ptBaseTONego = (ptCondition != null && ptCondition.Base_TO_Nego__c != null ? ptCondition.Base_TO_Nego__c : 0);
                    this.ptBaseTOTariffNego = (ptCondition != null && ptCondition.Base_TO_Tariff_Nego__c != null ? ptCondition.Base_TO_Tariff_Nego__c : 0);
                    ptCondition = null;
                }
                // calculate Proof_counterparty_number_total__c
                if (ptCondition != null) {
                    if (!this.isUnicity || (this.conditionPTList.size() == 1 && this.conditionNegoList.size() == 1)) {
                        Boolean isNegoBase = contract.RecordTypeId == this.wContract.contractRTIds.get('Nego_Base');
                        this.calculateSubConditionsValues(ptCondition, isConsoNBI_NB_NBE, isNegoBase, true);
                        this.calculateSubConditionsValues(negoCondition, isConsoNBI_NB_NBE, isNegoBase, false);
                    }
                }
            }
            if (isConsoNBI_NB_NBE && ptCondition != null && ptCondition.Value_per__c != null) {
                ptCondition.Value_per__c = null;
            }
            // upsert condition
            ConditionWrapper conditionConsoWrapper;
            if (!conditionsConsos.isEmpty()) {
                ConditionWrapper unicityCondition;
                for (ConditionWrapper item : conditionsConsos) {
                    if (this.conditionConsosMap.containsKey(item.conditionConso.Id) && this.conditionConsosMap.get(item.conditionConso.Id) == false) {
                        conditionConsoWrapper = item;
                        conditionConsoWrapper.isUpdated = true;
                        this.conditionConsosMap.remove(item.conditionConso.Id);
                    }
                    if (isConsoNBI_NB_NBE && this.isUnicity && item.conditionConso.Condition_Type__c == this.tariffCondition.Id) {
                        unicityCondition = item;
                    }
                    if (conditionConsoWrapper != null || unicityCondition != null) {
                        break;
                    }
                }
                if (conditionConsoWrapper == null && unicityCondition != null) {
                    conditionConsoWrapper = unicityCondition;
                    conditionConsoWrapper.isUpdated = true;
                    this.conditionConsosMap.remove(unicityCondition.conditionConso.Id);
                }
            }
            if (conditionConsoWrapper == null) {
                conditionConsoWrapper = new ConditionWrapper(null);
            }
            conditionConsoWrapper.conditionConso = upsertCondition(contract, ptCondition, negoCondition, conditionConsoWrapper.conditionConso, isConsoNBI_NB_NBE);
            // generate sub conditions
            conditionConsoWrapper.subConditions = generateSubConditions(contract, ptCondition, negoCondition, conditionConsoWrapper.conditionConso, isConsoNBI_NB_NBE);
            conditionsConsos = new List<ConditionWrapper> {conditionConsoWrapper};
            if (!wContract.parentConditionConsoMap.containsKey(contract.RecordTypeId)) {
                this.wContract.parentConditionConsoMap.put(contract.RecordTypeId, new Map<String, List<ConditionWrapper>>());
            }
            if (!this.wContract.parentConditionConsoMap.get(contract.RecordTypeId).containsKey(conditionKey)) {
                this.wContract.parentConditionConsoMap.get(contract.RecordTypeId).put(conditionKey, new List<ConditionWrapper>());
            }
            this.wContract.parentConditionConsoMap.get(contract.RecordTypeId).get(conditionKey).addAll(conditionsConsos);
            return conditionsConsos;
        }

        // upsert conditions Landing/Nego_Base/Nego_Base_Init/Nego_Base_Exit
        private Contract_Discount__c upsertCondition(Contract__c contract, Contract_Discount__c ptCondition, Contract_Discount__c negoCondition, Contract_Discount__c conditionConso,
                                                                    Boolean isConsoNBI_NB_NBE)
        {
            Decimal totalTO, ptTotalTO, negoTotalTO, amount, percent, ptQty, negoQty, unitAmount, ptAmount, negoAmount;
            // calculate Total TO
            if (!this.isUnicity) {
                ptTotalTO = (ptCondition != null ? (ptCondition.Is_Tariff_Condition__c ? (ptCondition.Base_TO_Tariff_Nego__c != null ? ptCondition.Base_TO_Tariff_Nego__c : 0) : (ptCondition.Base_TO_Nego__c != null ? ptCondition.Base_TO_Nego__c : 0))
                             : (this.wContract.contractPT != null ? this.wContract.contractPT.Total_TO__c : 0));
                negoTotalTO = (negoCondition != null ? (negoCondition.Is_Tariff_Condition__c ? (negoCondition.Base_TO_Tariff_Nego__c != null ? negoCondition.Base_TO_Tariff_Nego__c : 0) : (negoCondition.Base_TO_Nego__c != null ? negoCondition.Base_TO_Nego__c : 0))
                               : (this.wContract.contractNego != null ? this.wContract.contractNego.Total_TO__c : 0));
            } else {
                ptTotalTO = this.wContract.contractPT != null ? this.wContract.contractPT.Total_TO__c : 0;
                negoTotalTO = this.wContract.contractNego != null ? this.wContract.contractNego.Total_TO__c : 0;
            }
            totalTO = ptTotalTO + negoTotalTO;
            // calculate Amount
            if ((ptCondition != null && (ptCondition.Value_amt__c != null /*|| ptCondition.unit_amount__c != null*/)) || (negoCondition != null && (negoCondition.Value_amt__c != null /*|| negoCondition.unit_amount__c != null*/)) /*|| this.ptYTDNego != null || this.negoYTDNego != null*/) {
                if (!this.isUnicity) {
                    ptAmount = (ptCondition != null ? (ptCondition.Value_amt__c != null ? ptCondition.Value_amt__c : 0 /*(ptCondition.unit_amount__c != null ? (ptCondition.YTD_Nego__c != null ? ptCondition.YTD_Nego__c : 0) : 0)*/) : 0);
                    negoAmount = (negoCondition != null ? (negoCondition.Value_amt__c != null ? negoCondition.Value_amt__c : 0 /*(negoCondition.unit_amount__c != null ? (negoCondition.YTD_Nego__c != null ? negoCondition.YTD_Nego__c : 0) : 0)*/) : 0);
                    amount = ptAmount + negoAmount;
                } else {
                    ptAmount = (ptCondition != null ? (ptCondition.Value_amt__c != null ? ptCondition.Value_amt__c : 0 /*(ptCondition.unit_amount__c != null ? (this.ptYTDNego != null ? this.ptYTDNego : 0) : 0)*/) : 0);
                    negoAmount = (negoCondition != null ? (negoCondition.Value_amt__c != null ? negoCondition.Value_amt__c : 0 /*(negoCondition.unit_amount__c != null ? (this.negoYTDNego != null ? this.negoYTDNego : 0) : 0)*/) : 0);
                    amount = ptAmount + negoAmount;
                }
            }
            // calculate Percent
            if (!isConsoNBI_NB_NBE) {
                // case condition for contract Landing
                percent = (negoCondition != null && negoCondition.Value_per__c != null ? negoCondition.Value_per__c :
                           (ptCondition != null && ptCondition.Value_per__c != null ? ptCondition.Value_per__c : null));
            } else {
                // case condition for contract Nego_Base/Nego_Base_Init/Nego_Base_Exit
                if ((negoCondition != null && negoCondition.Value_Per__c != null) || (totalTO > 0 && ptCondition != null && ptCondition.Value_Per__c != null  && ptCondition.YTD_Nego__c != null) || this.ptYTDNego != null) {
                    if (!this.isUnicity) {
                        percent = (negoCondition != null && negoCondition.Value_Per__c != null ? negoCondition.Value_Per__c :
                                   (ptCondition != null && ptCondition.Value_Per__c != null && ptCondition.YTD_Nego__c != null && totalTO > 0 ? ptCondition.YTD_Nego__c*100/totalTO : 0));
                    } else {
                        percent = (negoCondition != null && negoCondition.Value_Per__c != null ? negoCondition.Value_Per__c :
                                   (ptCondition != null && ptCondition.Value_Per__c != null && this.ptYTDNego != null && totalTO > 0 ? this.ptYTDNego/totalTO : 0));
                    }
                }
            }
            // calculate Unit Amount
            ptQty = (ptCondition != null && ptCondition.Base_Quantity_Nego__c != null ? ptCondition.Base_Quantity_Nego__c : 0);
            negoQty = (negoCondition != null && negoCondition.Base_Quantity_Nego__c != null ? negoCondition.Base_Quantity_Nego__c : 0);
            if (!isConsoNBI_NB_NBE) {
                if ((ptCondition != null && ptCondition.Base_Quantity_Nego__c != null && ptCondition.unit_amount__c != null) || (negoCondition != null && negoCondition.Base_Quantity_Nego__c != null && negoCondition.unit_amount__c != null)) {
                    unitAmount = (ptQty + negoQty) > 0 ? (ptQty * (ptCondition != null && ptCondition.unit_amount__c != null ? ptCondition.unit_amount__c : 0)
                                                          + (negoQty * (negoCondition != null && negoCondition.unit_amount__c != null ? negoCondition.unit_amount__c : 0)))/(ptQty + negoQty) : 0;
                }
            } else {
                if ((negoCondition != null && negoCondition.unit_amount__c != null) || (ptCondition != null && ptCondition.unit_amount__c != null && ptQty > 0)) {
                    unitAmount = (negoCondition != null && negoCondition.unit_amount__c != null ? negoCondition.unit_amount__c :
                                  (ptCondition != null && ptCondition.unit_amount__c != null && ptQty > 0 ? ptCondition.unit_amount__c/ptQty : 0));
                }
            }
            String[] excludeUpdatedFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Is_TargetToMove__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_Condition__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_per__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_amt__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_U__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_Justif__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.TargetToMove_per__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Is_AggregatedFromMove__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.OriginFromMove_Condition__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.OriginFromMove_ContractDiscount__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.OriginFromMove_U__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.OriginFromMove_amt__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.OriginFromMove_per__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Ext_id__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Status__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Is_Excluded_To_NegoBase__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_F__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Is_Excluded_To_Nego_Base_U__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Exclusion_to_Nego_Base_Value__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Exclusion_To_NegoBase_Justif__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Asynchron_Processing__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.First_invoice_date__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Is_FlatPrice_Condition__c.Name.ToLowerCase()
            };
            if (negoCondition != null) {
                if (conditionConso != null) {
                    for (String fieldname : this.conditionsFields) {
                        if(!excludeUpdatedFields.contains(fieldname.toLowerCase())) {
                            conditionConso.put(fieldname, negoCondition.get(fieldname));
                        }
                    }
                } else {
                    conditionConso = negoCondition.clone(false);
                    conditionConso.Ext_id__c = null;
                    conditionConso.Contract__c = contract.Id;
                    conditionConso.Is_TargetToMove__c = false;
                    conditionConso.TargetToMove_Condition__c = null;
                    conditionConso.TargetToMove_per__c = null;
                    conditionConso.TargetToMove_amt__c = null;
                    conditionConso.TargetToMove_U__c = null;
                    conditionConso.TargetToMove_Justif__c = null;
                    conditionConso.Is_AggregatedFromMove__c = false;
                    conditionConso.OriginFromMove_Condition__c = null;
                    conditionConso.OriginFromMove_ContractDiscount__c = null;
                    conditionConso.OriginFromMove_U__c = null;
                    conditionConso.OriginFromMove_amt__c = null;
                    conditionConso.OriginFromMove_per__c = null;
                    conditionConso.Is_Excluded_To_NegoBase__c = false;
                    conditionConso.Is_Excluded_To_Nego_Base_F__c = false;
                    conditionConso.Is_Excluded_To_Nego_Base_U__c = false;
                    conditionConso.Exclusion_to_Nego_Base_Value__c = null;
                    conditionConso.Exclusion_To_NegoBase_Justif__c = null;
                    conditionConso.Asynchron_Processing__c = false;
                }
            } else {
                if (conditionConso != null) {
                    for (String fieldname : this.conditionsFields) {
                        if(!excludeUpdatedFields.contains(fieldname.toLowerCase())) {
                            conditionConso.put(fieldname, ptCondition.get(fieldname));
                        }
                    }
                } else {
                    conditionConso = ptCondition.clone(false);
                    conditionConso.Ext_id__c = null;
                    conditionConso.Contract__c = contract.Id;
                    conditionConso.Contract__c = contract.Id;
                    conditionConso.Is_TargetToMove__c = false;
                    conditionConso.TargetToMove_Condition__c = null;
                    conditionConso.TargetToMove_per__c = null;
                    conditionConso.TargetToMove_amt__c = null;
                    conditionConso.TargetToMove_U__c = null;
                    conditionConso.TargetToMove_Justif__c = null;
                    conditionConso.Is_AggregatedFromMove__c = false;
                    conditionConso.OriginFromMove_Condition__c = null;
                    conditionConso.OriginFromMove_ContractDiscount__c = null;
                    conditionConso.OriginFromMove_U__c = null;
                    conditionConso.OriginFromMove_amt__c = null;
                    conditionConso.OriginFromMove_per__c = null;
                    conditionConso.Is_Excluded_To_NegoBase__c = false;
                    conditionConso.Is_Excluded_To_Nego_Base_F__c = false;
                    conditionConso.Is_Excluded_To_Nego_Base_U__c = false;
                    conditionConso.Exclusion_to_Nego_Base_Value__c = null;
                    conditionConso.Exclusion_To_NegoBase_Justif__c = null;
                    conditionConso.Asynchron_Processing__c = false;
                }
            }
            conditionConso.Reference_Condition__c = negoCondition != null ? negoCondition.Id : ptCondition.Id;
            conditionConso.Product_Scope__c = negoCondition != null ? negoCondition.Product_Scope__c : ptCondition.Product_Scope__c;
            conditionConso.BusinessUnitScope__c = negoCondition != null ? negoCondition.BusinessUnitScope__c : ptCondition.BusinessUnitScope__c;
            conditionConso.Value_amt__c = amount != null && amount != 0 ? amount : null;
            conditionConso.Value_amt_Y1__c = amount != null && amount != 0 ? amount : null;
            conditionConso.Value_Per__c = percent != null && percent != 0 ? percent : null;
            conditionConso.Value_per_Y1__c = percent != null && percent != 0 ? percent : null;
            conditionConso.Base_Quantity_Nego__c = (ptQty + negoQty) != 0 ? (ptQty + negoQty) : null;
            conditionConso.unit_amount__c = unitAmount != null && unitAmount != 0 ? unitAmount : null;
            conditionConso.Unit_Amount_Type__c = (negoCondition != null && negoCondition.Unit_Amount_Type__c != null ? negoCondition.Unit_Amount_Type__c : (ptCondition != null ? ptCondition.Unit_Amount_Type__c : null));
            conditionConso.Base_TO_Nego__c = null;
            conditionConso.Base_TO_Tariff_Nego__c = null;
          if ((ptCondition != null && ptCondition.Base_TO_Nego__c != null) || (negoCondition != null && negoCondition.Base_TO_Nego__c != null)) {
                if (!isConsoNBI_NB_NBE) {
                    if(negoCondition != null && ptCondition == null) {
                        conditionConso.Base_TO_Nego__c = negoCondition.Base_TO_Nego__c;
                    } else if(ptCondition != null && negoCondition == null) {
                        conditionConso.Base_TO_Nego__c = ptCondition.Base_TO_Nego__c;
                    } else {
                        conditionConso.Base_TO_Nego__c = totalTO;
                    }
                } else {
                    Decimal negoBaseTONego = (negoCondition != null && negoCondition.Base_TO_Nego__c != null ? negoCondition.Base_TO_Nego__c : 0);
                    if(ptCondition == null && this.ptBaseTONego == null) {
                        if (negoCondition.Respects_Contract_Scope__c == true) {
                            conditionConso.Base_TO_Nego__c = negoTotalTO != 0 ? negoBaseTONego * totalTO/negoTotalTO : 0;
                        } else {
                            conditionConso.Base_TO_Nego__c = negoBaseTONego;
                        }
                    } else {
                        conditionConso.Base_TO_Nego__c = ((ptCondition != null ? (ptCondition.Base_TO_Nego__c != null ? ptCondition.Base_TO_Nego__c : 0)
                                                                          : (this.ptBaseTONego != null ? this.ptBaseTONego : 0)) + negoBaseTONego);
                    }
                }
            }
            if ((ptCondition != null && ptCondition.Base_TO_Tariff_Nego__c != null) || (negoCondition != null && negoCondition.Base_TO_Tariff_Nego__c != null)) {
                Decimal negoBaseTOTariffNego = (negoCondition != null && negoCondition.Base_TO_Tariff_Nego__c != null ? negoCondition.Base_TO_Tariff_Nego__c : 0);
                if(ptCondition == null && this.ptBaseTOTariffNego == null) {
                    conditionConso.Base_TO_Tariff_Nego__c = negoTotalTO != 0 ? negoBaseTOTariffNego * totalTO/negoTotalTO : 0;
                } else {
                    conditionConso.Base_TO_Tariff_Nego__c = ((ptCondition != null ? (ptCondition.Base_TO_Tariff_Nego__c != null ? ptCondition.Base_TO_Tariff_Nego__c : 0)
                                                              : (this.ptBaseTOTariffNego != null ? this.ptBaseTOTariffNego : 0)) + negoBaseTOTariffNego);
                }
            }
            conditionConso.Rank__c = (negoCondition != null && negoCondition.Rank__c != null ? negoCondition.Rank__c : (ptCondition != null && ptCondition.Rank__c != null ? ptCondition.Rank__c : null));
            Date bDate = contract.Contract_BDate__c, eDate = contract.Contract_EDate__c;
            if (!isConsoNBI_NB_NBE) {
                if(negoCondition != null && ptCondition == null) {
                    bDate = negoCondition.Disc_BDate__c;
                    eDate = negoCondition.Disc_EDate__c;
                } else if(ptCondition != null && negoCondition == null) {
                    bDate = ptCondition.Disc_BDate__c;
                    eDate = ptCondition.Disc_EDate__c;
                }
            }
            // consolidate Base_TO_Nego_YearBase__c
            if (isConsoNBI_NB_NBE
               && negoCondition != null
               && negoCondition.Respects_Contract_Scope__c == false
               && negoCondition.Disc_BDate__c > wContract.contractNego.Contract_BDate__c
               && negoCondition.Product_Scope__c != wContract.contractNego.Supplier_Nego_Scope__c)
            {
                conditionConso.Base_TO_Nego__c = negoCondition.Base_TO_Nego_YearBase__c;
            }
            conditionConso.Disc_BDate__c = bDate;
            conditionConso.Disc_BDate_Y1__c = bDate;
            conditionConso.Disc_EDate__c = eDate;
            conditionConso.Disc_EDate_Y1__c = eDate;
            conditionConso.Condition_Type__c = this.tariffCondition.Id;
            conditionConso.Condition_Type__r = this.tariffCondition;
            conditionConso.Nego_Discount_Type__c = this.tariffCondition.Nego_Discount_Type__c;
            conditionConso.Is_Tariff_Condition__c = (negoCondition != null ? negoCondition.Is_Tariff_Condition__c : ptCondition.Is_Tariff_Condition__c);
            // IF Contract_Discount_c.EDate__c <> 31/12
            // Condition Name de la  ligne de condition à l'origine
            // & ' 'NEGO '  &  'IF RT  d ela ligne d 'origine = PE, 'PT' ELSE 'ECHUE'
            // & 'Value_Perc / Value_amt de la  ligne de condiition à l'origine
            // &' du ' & Bdate & ' au ' EDate de la  ligne de condiition à l'origine
            // & IF RespectContractScope = False, 'CA ' & NS Name & ' de ' BaseTONego de la  ligne de condiition à l'origine
            String commercialReference = '';
            // get origin tarrif condition
            Pol_Com_Condition__c originTariffCondition = negoCondition != null ? negoCondition.Condition_Type__r : ptCondition.Condition_Type__r;
            Contract_Discount__c originCondition;
            if (ptCondition != null && negoCondition != null) {
                originCondition = ptCondition;
            } else {
                originCondition = negoCondition != null ? negoCondition : ptCondition;
            }
            if (originCondition.Disc_EDate__c != null && originCondition.Disc_EDate__c.month() == 12 && originCondition.Disc_EDate__c.day() == 31) {
                commercialReference = originTariffCondition.Name;
            } else {
                commercialReference = originTariffCondition.Name + ' NEGO ';
                if (ptCondition != null && negoCondition != null) {
                    commercialReference += 'PT ';
                } else {
                    commercialReference += ptCondition != null ? 'PT ' : 'ECHUE ';
                }
                commercialReference += (originCondition.Value_Per__c != null ? originCondition.Value_Per__c.format() : '');
                commercialReference += (originCondition.Value_Per__c != null && originCondition.Value_amt__c != null ? ' / ' : '');
                commercialReference += (originCondition.Value_amt__c != null ? originCondition.Value_amt__c.format() : '');
                if (originCondition.Disc_BDate__c != null && originCondition.Disc_EDate__c != null) {
                    commercialReference += ' du ' + originCondition.Disc_BDate__c.format() + ' au ' + originCondition.Disc_EDate__c.format();
                }
                if (!originCondition.Respects_Contract_Scope__c) {
                    commercialReference += ' CA ' + originCondition.Contract__r.Supplier_Nego_Scope__r.Name;
                    commercialReference += (originCondition.Base_TO_Nego__c != null ? ' de ' + originCondition.Base_TO_Nego__c.format() : '');
                }
            }
            conditionConso.commercial_reference__c = commercialReference;
            if (contract.RecordTypeId == wContract.contractRTIds.get('Nego_Base_Exit')) {
                conditionConso.Status__c = 'Signed';
                conditionConso.RecordTypeId = wContract.discountRTIds.get('Signed');
            } else if(conditionConso.Id == null) {
                conditionConso.Status__c = 'Open';
                conditionConso.RecordTypeId = wContract.discountRTIds.get('To_Be_Signed');
            }
            return conditionConso;
        }

        // generate Sub Conditions Landing/Nego_Base/Nego_Base_Init/Nego_Base_Exit
        private List<Contract_Discount__c> generateSubConditions(Contract__c contract, Contract_Discount__c ptCondition, Contract_Discount__c negoCondition, Contract_Discount__c conditionConso, Boolean isConsoNBI_NB_NBE) {
            Boolean isNegoBase = contract.RecordTypeId == this.wContract.contractRTIds.get('Nego_Base');
            Map<String, List<Contract_Discount__c>> subConditionsPTNegoMap = new Map<String, List<Contract_Discount__c>>();
            Map<String, List<Contract_Discount__c>> subConditionConsoMap = new Map<String, List<Contract_Discount__c>>();
            List<Contract_Discount__c> subConditionConsoList = new List<Contract_Discount__c>();
            Set<String> conditionTypeSet = new Set<String>();
            if (negoCondition != null && (this.subDiscountsMap.containsKey(negoCondition.Id) || this.subDiscountsNegoUnicityList != null)) {
                List<Contract_Discount__c> subDiscountsNegoList = this.subDiscountsMap.containsKey(negoCondition.Id) ? this.subDiscountsMap.get(negoCondition.Id) : new List<Contract_Discount__c>();
                if(this.subDiscountsNegoUnicityList != null) subDiscountsNegoList = this.subDiscountsNegoUnicityList;
                Integer subDiscountsCount = subDiscountsNegoList.size();
                for (Contract_Discount__c subCondition : subDiscountsNegoList) {
                    // check suplicable
                    if(isNegoBase && !subCondition.is_Duplicable__c) continue;
                    Pol_Com_Condition__c subConditionType = subCondition.Condition_Type__r.Duplication_Discount_Mapping__c != null ? subCondition.Condition_Type__r.Duplication_Discount_Mapping__r : subCondition.Condition_Type__r;
                    if(this.isEGA1
                       && String.isNotBlank(subCondition.Condition_Type__r.Original_code__c)
                       && this.subTariffConditionEGA1Map.containsKey(subCondition.Condition_Type__r.Original_code__c))
                    {
                        subConditionType = this.subTariffConditionEGA1Map.get(subCondition.Condition_Type__r.Original_code__c);
                    }
                    if(subDiscountsCount == 1
                       && negoCondition.Product_Scope__r.SegmentationAttribut3__c == 'Value1'
                       && subConditionType.Segmentation_attribut3__c == 'Value1')
                    {
                        if(negoCondition.Value_amt__c != null && negoCondition.Value_amt__c != 0
                           && (subCondition.Value_amt__c == null || subCondition.Value_amt__c == 0))
                        {
                            subCondition.Value_amt__c = negoCondition.Value_amt__c;
                            subCondition.Value_amt_Y1__c = negoCondition.Value_amt__c;
                        }
                        if(negoCondition.Value_per__c != null && negoCondition.Value_per__c != 0
                           && (subCondition.Value_per__c == null || subCondition.Value_per__c == 0))
                        {
                            subCondition.Value_per__c = negoCondition.Value_per__c;
                            subCondition.Value_per_Y1__c = negoCondition.Value_per__c;
                        }
                    }
                    String key = subConditionType.Id /*+ '' + subCondition.Id*/;
                    conditionTypeSet.add(subConditionType.Id);
                    if (!subConditionsPTNegoMap.containsKey(key)) {
                        subConditionsPTNegoMap.put(key, new List<Contract_Discount__c>());
                    }
                    subConditionsPTNegoMap.get(key).add(subCondition);
                }
            }
            if (ptCondition != null && (this.subDiscountsMap.containsKey(ptCondition.Id) || this.subDiscountsPTUnicityList != null)) {
                /*Contract_Discount__c ptParentDiscount = ptCondition;
                if (ptCondition.OriginFromMove_Condition__c != null && ptCondition.OriginFromMove_ContractDiscount__c != null && originFromMoveContractDiscountMap.containsKey(ptCondition.OriginFromMove_ContractDiscount__c)) {
                    ptParentDiscount = originFromMoveContractDiscountMap.get(ptCondition.OriginFromMove_ContractDiscount__c);
                }*/
                List<Contract_Discount__c> subDiscountsPTList = this.subDiscountsMap.containsKey(ptCondition.Id) ? this.subDiscountsMap.get(ptCondition.Id) : new List<Contract_Discount__c>();
                if(this.subDiscountsPTUnicityList != null) subDiscountsPTList = this.subDiscountsPTUnicityList;
                Integer subDiscountsCount = subDiscountsPTList.size();
                for (Contract_Discount__c subCondition : subDiscountsPTList) {
                    // check duplicable
                    if(isNegoBase && !subCondition.is_Duplicable__c) continue;
                    Pol_Com_Condition__c subConditionType = subCondition.Condition_Type__r.Duplication_Discount_Mapping__c != null ? subCondition.Condition_Type__r.Duplication_Discount_Mapping__r : subCondition.Condition_Type__r;
                    if(this.isEGA1
                       && String.isNotBlank(subCondition.Condition_Type__r.Original_code__c)
                       && this.subTariffConditionEGA1Map.containsKey(subCondition.Condition_Type__r.Original_code__c))
                    {
                        subConditionType = this.subTariffConditionEGA1Map.get(subCondition.Condition_Type__r.Original_code__c);
                    }
                    if(subDiscountsCount == 1
                       && ptCondition.Product_Scope__r.SegmentationAttribut3__c == 'Value1'
                       && subConditionType.Segmentation_attribut3__c == 'Value1'
                       && ptCondition.Value_amt__c != null && ptCondition.Value_amt__c != 0
                       && (subCondition.Value_amt__c == null || subCondition.Value_amt__c == 0))
                    {
                        subCondition.Value_amt__c = ptCondition.Value_amt__c;
                        subCondition.Value_amt_Y1__c = ptCondition.Value_amt__c;
                    }
                    if (!conditionTypeSet.contains(subConditionType.Id)) {
                        String key = subConditionType.Id /*+ '' + subCondition.Id*/;
                        if (!subConditionsPTNegoMap.containsKey(key)) {
                            subConditionsPTNegoMap.put(key, new List<Contract_Discount__c>());
                        }
                        subConditionsPTNegoMap.get(key).add(subCondition);
                    }
                }
            }
            if (conditionConso.Id != null && this.subDiscountsMap.containsKey(conditionConso.Id)) {
                for (Contract_Discount__c subCondition : this.subDiscountsMap.get(conditionConso.Id)) {
                    String key = subCondition.Condition_Type__c /*+ '' + subCondition.Reference_Condition__c*/;
                    if (!subConditionsPTNegoMap.containsKey(key)) {
                        // delete Sub Conditions not exist in Condition PT or Nego
                        this.wContract.subConditionsDeletedList.add(subCondition);
                    } else {
                        if (!subConditionConsoMap.containsKey(key)) {
                            subConditionConsoMap.put(key, new List<Contract_Discount__c>());
                        }
                        subConditionConsoMap.get(key).add(subCondition);
                    }
                }
            }
            String[] excludeUpdatedFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Ext_id__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.Status__c.Name.toLowerCase(),
                SObjectType.Contract_Discount__c.fields.RecordTypeId.Name.toLowerCase()
            };
            for (String key : subConditionsPTNegoMap.keySet()) {
                Integer index = 0;
                for (Contract_Discount__c subCondition : subConditionsPTNegoMap.get(key)) {
                    Contract_Discount__c subConditionConso;
                    if (!subConditionConsoMap.containsKey(key)) {
                        subConditionConso = subCondition.clone(false);
                        subConditionConso.RecordTypeId = wContract.discountRTIds.get('Sub_Term_To_Be_Signed');
                        subConditionConso.Contract__c = conditionConso.Contract__c;
                        subConditionConso.Ext_id__c = null;
                        subConditionConso.Status__c = 'Open';
                    } else {
                        if(subConditionConsoMap.get(key).size() == index) continue;
                        subConditionConso = subConditionConsoMap.get(key)[index];
                        for (String fieldname : this.conditionsFields) {
                            if(!excludeUpdatedFields.contains(fieldname.toLowerCase())) {
                                subConditionConso.put(fieldname, subCondition.get(fieldname));
                            }
                        }
                        index++;
                    }
                    Pol_Com_Condition__c tariffCondition = subCondition.Condition_Type__r.Duplication_Discount_Mapping__c != null ? subCondition.Condition_Type__r.Duplication_Discount_Mapping__r : subCondition.Condition_Type__r;
                    if(this.isEGA1
                       && String.isNotBlank(subCondition.Condition_Type__r.Original_code__c)
                       && this.subTariffConditionEGA1Map.containsKey(subCondition.Condition_Type__r.Original_code__c))
                    {
                        tariffCondition = this.subTariffConditionEGA1Map.get(subCondition.Condition_Type__r.Original_code__c);
                    }
                    subConditionConso.Condition_Type__r = tariffCondition;
                    subConditionConso.Is_Tariff_Condition__c = subCondition.Is_Tariff_Condition__c;
                    subConditionConso.BusinessUnitScope__c = subCondition.BusinessUnitScope__c;
                    subConditionConso.Product_Scope__c = subCondition.Product_Scope__c;
                    subConditionConso.Parent_Discount__c = conditionConso.Id;
                    subConditionConso.Condition_Type__c = tariffCondition.Id;
                    subConditionConso.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
                    subConditionConso.Disc_BDate__c = conditionConso.Disc_BDate__c;
                    subConditionConso.Disc_EDate__c = conditionConso.Disc_EDate__c;
                    subConditionConso.Reference_Condition__c = subCondition.Id;
                    // recalculate Amount/Percent/Proof_counterparty_number_total__c
                    String subConditionkey = subConditionConso.Condition_Type__c + '' + (isNegoBase ? 'NB' : (isConsoNBI_NB_NBE ? 'NBIE' : 'LANDING'));
                    if (this.subConditionsCalculationMap.containsKey(subConditionkey)) {
                        subConditionConso.Value_amt__c = this.subConditionsCalculationMap.get(subConditionkey).Value_amt__c;
                        if(subConditionConso.Value_amt__c == 0) subConditionConso.Value_amt__c = null;
                        subConditionConso.Value_amt_Y1__c = subConditionConso.Value_amt__c;
                        subConditionConso.Value_per__c = this.subConditionsCalculationMap.get(subConditionkey).Value_per__c;
                        if(subConditionConso.Value_per__c == 0) subConditionConso.Value_per__c = null;
                        subConditionConso.Value_per_Y1__c = subConditionConso.Value_per__c;
                        subConditionConso.Proof_counterparty_number_total__c = this.subConditionsCalculationMap.get(subConditionkey).Proof_counterparty_number_total__c;
                        if(subConditionConso.Proof_counterparty_number_total__c == 0) subConditionConso.Proof_counterparty_number_total__c = null;
                    }
                    updateConditionDefaultValues(contract, subConditionConso, subCondition, tariffCondition, false);
                    if (contract.RecordTypeId == wContract.contractRTIds.get('Nego_Base_Exit')) {
                        subConditionConso.Status__c = 'Signed';
                        subConditionConso.RecordTypeId = wContract.discountRTIds.get('Sub_Term_Signed');
                    } else if (subConditionConso.Id == null) {
                        subConditionConso.Status__c = 'Open';
                    }
                    subConditionConsoList.add(subConditionConso);
                }
            }
            return subConditionConsoList;
        }

        // calculate Proof_counterparty_number_total__c
        private void calculateSubConditionsValues(Contract_Discount__c item, Boolean isConsoNBI_NB_NBE, Boolean isNegoBase, Boolean isPE) {
            if (this.subDiscountsMap.containsKey(item.Id)) {
                Integer subDiscountsCount = this.subDiscountsMap.get(item.Id).size();
                for (Contract_Discount__c subCondition : this.subDiscountsMap.get(item.Id)) {
                    // check duplicable
                    if(isNegoBase && !subCondition.is_Duplicable__c) continue;
                    Pol_Com_Condition__c subConditionType = subCondition.Condition_Type__r.Duplication_Discount_Mapping__c != null ? subCondition.Condition_Type__r.Duplication_Discount_Mapping__r : subCondition.Condition_Type__r;
                    if(this.isEGA1
                       && String.isNotBlank(subCondition.Condition_Type__r.Original_code__c)
                       && this.subTariffConditionEGA1Map.containsKey(subCondition.Condition_Type__r.Original_code__c))
                    {
                        subConditionType = this.subTariffConditionEGA1Map.get(subCondition.Condition_Type__r.Original_code__c);
                    }
                    if(subDiscountsCount == 1
                       && item.Product_Scope__r.SegmentationAttribut3__c == 'Value1'
                       && subConditionType.Segmentation_attribut3__c == 'Value1')
                    {
                        if(item.Value_amt__c != null && item.Value_amt__c != 0
                           && (subCondition.Value_amt__c == null || subCondition.Value_amt__c == 0))
                        {
                            subCondition.Value_amt__c = item.Value_amt__c;
                            subCondition.Value_amt_Y1__c = item.Value_amt__c;
                        }
                        if(item.Value_per__c != null && item.Value_per__c != 0
                           && (subCondition.Value_per__c == null || subCondition.Value_per__c == 0))
                        {
                            subCondition.Value_per__c = item.Value_per__c;
                            subCondition.Value_per_Y1__c = item.Value_per__c;
                        }
                    }
                    String key = subConditionType.Id + '' + (isNegoBase ? 'NB' : (isConsoNBI_NB_NBE ? 'NBIE' : 'LANDING'));
                    if (!this.subConditionsCalculationMap.containsKey(key)) {
                        this.subConditionsCalculationMap.put(key, new Contract_Discount__c(Proof_counterparty_number_total__c = 0, Value_amt__c = 0, Value_per__c = 0));
                    }
                    Contract_Discount__c calculatedSubCondition = this.subConditionsCalculationMap.get(key);
                    Decimal counterpartyTotal = subCondition.Proof_counterparty_number_total__c != null ? subCondition.Proof_counterparty_number_total__c : 0;
                    Decimal amount = subCondition.Value_amt__c != null ? subCondition.Value_amt__c : 0;
                    Decimal percent = !isPE && subCondition.Value_per__c != null ? subCondition.Value_per__c : 0;
                    calculatedSubCondition.Proof_counterparty_number_total__c += counterpartyTotal;
                    calculatedSubCondition.Value_amt__c += amount;
                    calculatedSubCondition.Value_per__c += percent;
                    this.subConditionsCalculationMap.put(key, calculatedSubCondition);
                }
            }
        }
    }

	public class ContractIndexWrapper {
        public String indexName {get; set;}
        public String contractId {get; set;}
        public String Name {get; set;}
        public Decimal Index {get; set;}
        public Decimal IndexV2 {get; set;}
        public String sIndex {get {
            return NegoptimHelper.formatPercentageValue(this.Index, false);
        } set;}
        public String sIndexV2 {get {
            return NegoptimHelper.formatPercentageValue(this.IndexV2, false);
        } set;}
        public Decimal IndexPerc {get; set;}
        public Decimal indexV2Perc {get; set;}
        public String sIndexPerc {get {
             return NegoptimHelper.formatPercentageValue(this.IndexPerc, false);
        } set;}
        public String sindexV2Perc {get {
            return NegoptimHelper.formatPercentageValue(this.indexV2Perc, false);
        } set;}
        public Decimal To {get; set;}
        public String sTo {get {
            return this.To != null ? this.To.format() : '';
        } set;}
        public Decimal Computed {get; set;}
        public String sComputed {get {
            return this.Computed != null ? this.Computed.format() : '';
        } set;}
        public Decimal refRate {get; set;}
        public Decimal Gap {get {
            if (this.refRate != null && this.Index != null) {
                Decimal d = this.refRate != 0 ? (this.Index - this.refRate) / this.refRate * 100 : 0;
                return d;
            }
            return null;
        } set;}
        public String sGap {get {
            if (this.Gap != null) {
                return NegoptimHelper.formatPercentageValue(this.Gap, false);
            }
            return '';
        } set;}
        public Decimal GapV2 {get {
            if (this.refRate != null && this.IndexPerc != null) {
                Decimal d = this.refRate != 0 ? (this.IndexPerc - this.refRate) / this.refRate * 100 : 0;
                return d;
            }
            return null;
        } set;}
        public String sGapV2 {get {
            if (this.Gap != null) {
                return NegoptimHelper.formatPercentageValue(this.GapV2, false);
            }
            return '';
        } set;}
        public ContractIndexWrapper(String name) {
            this.Name = name;
        }
    }

    public class ConditionWrapper {
        public Contract_Discount__c condition;
        public String index;
        public Integer rank;
        public Decimal baseToNego;
        public Decimal computedValue;
        public Decimal recalc;
        public Decimal toAfterContract;
        public Boolean isRespectsContractScope;
        public Boolean isOnlyPercentCondition;
        public Decimal percent;
		public Decimal calcPercent {get { return this.condition.Index_perc__c != null ? (1 - (this.condition.Index_perc__c / 100)) : 0; }}
        public Decimal fixedAmount;
        public Decimal ytdNego;
        // Conso params
        public Contract_Discount__c conditionConso {get; set;}
        public List<Contract_Discount__c> subConditions {get; set;}
        public Id referenceCondition {get; set;}
        public Boolean isUpdated {get; set;}

        public conditionWrapper(Contract__c contract, Contract_Discount__c condition, Decimal totalTO) {
            this.condition = condition;
            this.percent = 0;
            this.index = (this.condition.Index__c != null ? this.condition.Index__c : (this.condition.Condition_Type__r != null ? this.condition.Condition_Type__r.Index__c : null));
            if (this.index == 'Index1') {
                this.rank = this.condition.Rank__c == null ? null : Integer.valueOf(String.valueOf(this.condition.Rank__c));
            } else {
                this.rank = -1;
            }
            //this.rank = this.condition.Rank__c != null ? Integer.valueOf(this.condition.Rank__c) : 1;
            /*Decimal totalTo = 0;
            for (Integer i = 1; i <= 12; i++) {
                totalTo +=  contract.get('TO' + i + '__c') != null ? Decimal.valueOf(String.ValueOf(contract.get('TO' + i + '__c'))) : 0;
            }*/
            if(this.condition.slab_calc_method__c == 'TO forContractTO') {
                this.baseToNego = totalTO != null ? totalTO : 0;
            } else {
                this.baseToNego = this.condition.Base_TO_Nego__c != null ? this.condition.Base_TO_Nego__c : 0;
            }
            this.recalc = 0;
            this.computedValue = 0;
            Decimal excludedFixedAmount = (this.condition.Is_Excluded_To_Nego_Base_F__c == true ?
                                           ((this.condition.Exclusion_to_Nego_Base_Value__c == null || this.condition.Exclusion_to_Nego_Base_Value__c == 0) ?
                                            (this.condition.Value_amt__c != null ? this.condition.Value_amt__c : 0) : this.condition.Exclusion_to_Nego_Base_Value__c) : 0);
            Decimal unitAmount = this.condition.Is_Excluded_To_Nego_Base_U__c == true ? 0 : this.condition.unit_amount__c;
            this.toAfterContract = 0;//this.condition.Contract__r.Total_TO__c;
            this.isRespectsContractScope = (this.condition.Product_Scope__c == contract.Supplier_Nego_Scope__c
                                            && this.condition.BusinessUnitScope__c == contract.BusinessUnitContract__c
                                            && this.condition.Disc_BDate__c == contract.Contract_BDate__c
                                            && this.condition.Disc_EDate__c == contract.Contract_EDate__c
                                            && ((unitAmount == null || unitAmount == 0)
                                                || (this.condition.Unit_Amount_Type__c == 'Piece' || this.condition.Unit_Amount_Type__c == 'UC')));
            this.isOnlyPercentCondition = (this.condition.Value_amt__c == null || this.condition.Value_amt__c == 0) && (unitAmount == null || unitAmount == 0);
            this.fixedAmount = (this.condition.Value_amt__c != null ? (this.condition.Value_amt__c - excludedFixedAmount) : 0) +
                (unitAmount != null && this.condition.Base_Quantity_Nego__c != null ? this.condition.Base_Quantity_Nego__c * unitAmount : 0);
            this.ytdNego = 0;
            if (this.condition.Is_Tariff_Condition__c) {
                this.ytdNego = ((this.condition.Base_TO_Tariff_Nego__c != null ? this.condition.Base_TO_Tariff_Nego__c : 0) * (this.condition.Value_per__c != null ? this.condition.Value_per__c : 0)) / 100;
            } else {
                this.ytdNego = (/*(this.condition.Base_TO_Nego__c != null ? this.condition.Base_TO_Nego__c : 0)*/ this.baseToNego * (this.condition.Value_per__c != null ? this.condition.Value_per__c : 0)) / 100;
            }
            this.ytdNego += (this.condition.Value_amt__c != null ? (this.condition.Value_amt__c - excludedFixedAmount) : 0) *
                ((this.condition.Base_TO_Nego_YearBase__c != null && this.condition.Base_TO_Nego_YearBase__c != 0 && this.condition.Is_Yearly_Condition__c) ?
                 /*(this.condition.Base_TO_Nego__c != null ? this.condition.Base_TO_Nego__c : 0)*/ this.baseToNego / this.condition.Base_TO_Nego_YearBase__c : 1);
            this.ytdNego += (this.condition.Base_Quantity_Nego__c != null ? this.condition.Base_Quantity_Nego__c : 0)  * (unitAmount != null ? unitAmount : 0);
            this.ytdNego = this.ytdNego.setScale(2);
        }

        public ConditionWrapper (Contract_Discount__c conditionConso) {
            // init conso params
            this.conditionConso = conditionConso;
            this.subConditions = new List<Contract_Discount__c>();
            this.isUpdated = false;
        }
    }

	public class ConditionSortWrapper implements Comparable {
		Contract_Discount__c discount;
		Map<String, Integer> negoDiscountTypeSortMap;
		Integer coef;
		Map<String, Id> discountRTIds;
		public ConditionSortWrapper(Contract_Discount__c discount, Integer coef, Map<String, Id> discountRTIds, Map<String, Integer> negoDiscountTypeSortMap) {
			this.discount = discount;
			this.coef = coef;
            this.discountRTIds = discountRTIds;
            this.negoDiscountTypeSortMap = negoDiscountTypeSortMap;
		}

        // compare on RecordTypeId, put Sub_Term_Signed AND Sub_Term_To_Be_Signed at the end
        public Integer compareToParent(ConditionSortWrapper compareToObj) {
            if (this.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_Signed') && this.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_To_Be_Signed')
                && compareToObj.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_Signed') && compareToObj.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_To_Be_Signed')) {
                return 0;
            } else if (this.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_Signed') && this.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_To_Be_Signed')) {
                return -1;
            } else if (compareToObj.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_Signed') && compareToObj.discount.RecordTypeId != this.discountRTIds.get('Sub_Term_To_Be_Signed')) {
                return 1;
            }
			return 0;
		}

		// compare on Condition_Type__r.Index__c
		public Integer compareToindex(ConditionSortWrapper compareToObj) {
			if (this.discount.Condition_Type__r.Index__c != null && compareToObj.discount.Condition_Type__r.Index__c != null) {
				return coef * this.discount.Condition_Type__r.Index__c.compareTo(compareToObj.discount.Condition_Type__r.Index__c);
			} else if (this.discount.Condition_Type__r.Index__c == null && compareToObj.discount.Condition_Type__r.Index__c == null) {
				return 0;
			} else if (this.discount.Condition_Type__r.Index__c != null) {
				return 1;
			} else if (compareToObj.discount.Condition_Type__r.Index__c != null) {
				return - 1;
			}
			return 0;
		}

		// compare on Condition_Type__r.Index__c
        public Integer compareTonegoDiscountType(ConditionSortWrapper compareToObj) {
            if (this.discount.Condition_Type__r.Nego_Discount_Type__c != null && compareToObj.discount.Condition_Type__r.Nego_Discount_Type__c != null) {
                Integer Index = negoDiscountTypeSortMap.containsKey(this.discount.Condition_Type__r.Nego_Discount_Type__c) ? negoDiscountTypeSortMap.get(this.discount.Condition_Type__r.Nego_Discount_Type__c) : 0;
                Integer compareToIndex = negoDiscountTypeSortMap.containsKey(compareToObj.discount.Condition_Type__r.Nego_Discount_Type__c) ? negoDiscountTypeSortMap.get(compareToObj.discount.Condition_Type__r.Nego_Discount_Type__c) : 0;
				if (Index == compareToIndex) {
					return 0;
				} else if (Index > compareToIndex) {
					return coef * 1;
				} else if (Index < compareToIndex) {
					return coef * -1;
				}
            } else if (this.discount.Condition_Type__r.Nego_Discount_Type__c == null && compareToObj.discount.Condition_Type__r.Nego_Discount_Type__c == null) {
                return 0;
            } else if (this.discount.Condition_Type__r.Nego_Discount_Type__c != null) {
                return 1;
            } else if (compareToObj.discount.Condition_Type__r.Nego_Discount_Type__c != null) {
                return - 1;
            }
            return 0;
        }

		// compare on Condition_Type__r.Name
		public Integer compareToconditionTypeName(ConditionSortWrapper compareToObj) {
			if (this.discount.Condition_Type__r.Name != null && compareToObj.discount.Condition_Type__r.Name != null) {
				return coef * this.discount.Condition_Type__r.Name.compareTo(compareToObj.discount.Condition_Type__r.Name);
			} else if (this.discount.Condition_Type__r.Name == null && compareToObj.discount.Condition_Type__r.Name == null) {
				return 0;
			} else if (this.discount.Condition_Type__r.Name != null) {
				return 1;
			} else if (compareToObj.discount.Condition_Type__r.Name != null) {
				return - 1;
			}
			return 0;
		}

		// comppare on Id
		public Integer compareToId(ConditionSortWrapper compareToObj) {
			if (this.discount.Id != null && compareToObj.discount.Id != null) {
				return coef * String.valueOf(this.discount.Id).compareTo(String.valueOf(compareToObj.discount.Id));
			} else if (this.discount.Id == null && compareToObj.discount.Id == null) {
				return 0;
			} else if (this.discount.Id != null) {
				return 1;
			} else if (compareToObj.discount.Id != null) {
				return - 1;
			}
			return 0;
		}

		// compare on Rank__c
		public Integer compareTorank(ConditionSortWrapper compareToObj) {
			if (this.discount.Rank__c == compareToObj.discount.Rank__c) {
				return 0;
			} else if (this.discount.Rank__c != null && compareToObj.discount.Rank__c != null) {
				if (this.discount.Rank__c > compareToObj.discount.Rank__c) {
					return coef * 1;
				} else if (this.discount.Rank__c < compareToObj.discount.Rank__c) {
					return coef * -1;
				}
			} else if (this.discount.Rank__c != null) {
				return 1;
			} else if (compareToObj.discount.Rank__c != null) {
				return - 1;
			}
			return 0;
		}

		// compare on Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Condition_Type__r.Name, Id
		public Integer compareTo(Object compareTo) {
			ConditionSortWrapper compareToObj = (ConditionSortWrapper)compareTo;
            Integer res = 0;
			if (this.discount != null && compareToObj.discount != null) {
                res = compareToParent(compareToObj);
                if (res == 0) {
                    res = compareToindex(compareToObj);
                    if (res == 0) {
                        res = compareTonegoDiscountType(compareToObj);
                        if (res == 0) {
                            res = compareTorank(compareToObj);
                            if (res == 0) {
                                res = compareToconditionTypeName(compareToObj);
                                if (res == 0) {
                                    res = compareToId(compareToObj);
                                }
                            }
                        }
                    }
                }
            }
			return res;
		}
	}

    // TODO: Move to Helper class on package
    @AuraEnabled
    public static AsyncApexjob getApexJob(Id asyncApexjobId) {
        List<AsyncApexjob> asyncApexjobList;
        String[] asyncApexJobFields = new String[] {
            SObjectType.AsyncApexJob.fields.Id.Name,
            SObjectType.AsyncApexJob.fields.Status.Name,
            SObjectType.AsyncApexJob.fields.JobItemsProcessed.Name,
            SObjectType.AsyncApexJob.fields.TotalJobItems.Name,
            SObjectType.AsyncApexJob.fields.NumberOfErrors.Name,
            SObjectType.AsyncApexJob.fields.ExtendedStatus.Name
        };
        if (NegoptimHelper.checkAccessibility(AsyncApexJob.SObjectType, asyncApexJobFields)) {
            asyncApexjobList = [SELECT Id, ApexClass.Name, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus FROM AsyncApexjob WHERE Id = :asyncApexjobId];
        }
        if (asyncApexjobList != null && !asyncApexjobList.isEmpty()) {
            return asyncApexjobList[0];
        } else {
            throw new AuraHandledException('No AsyncApexjob found for Id ' + asyncApexjobId);
        }
    }
    class NegoptimSettings {
        public Date startingDayToCreateNegoBaseOnConsoDate {get;set;}
        public Date startingDayToCreateLandingOnConsoDate {get;set;}
        public Boolean contractNumberUnicity {get;set;}
        public String sBusinessType {get;set;}
        public Integer discountPercentScale {get; set;}
    }
    public class DuplicateContractResultWrapper {
        public Set<Id> contractInsertedIds {get;set;}
        public List<String> errorMessages {get;set;}
        
        public DuplicateContractResultWrapper(Set<Id> contractInsertedIds, List<String> errorMessages) {
            this.contractInsertedIds = contractInsertedIds;
            this.errorMessages = errorMessages;
        }
    }
}