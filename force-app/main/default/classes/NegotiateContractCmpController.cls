public with sharing class NegotiateContractCmpController{

    private static final String TYPE_CONTRACT {get { return 'Contract'; }}
    private static final String TYPE_TARGET {get { return 'Target'; }}
    private static final String TYPE_SIMULATION {get { return 'Simulation'; }}
    private static final String TYPE_TO_BE_SIGNED {get { return 'To_Be_Signed'; }}
    private static final String TYPE_SIGNED {get { return 'Signed'; }}
    private static final String TYPE_NEGO_BASE {get { return 'Nego_Base'; }}
    private static final String TYPE_NEGO_BASE_INIT {get { return 'Nego_Base_Init'; }}
    private static final String TYPE_SAFE_BALANCE {get { return 'Safe_Balance'; }}
    private static final String TYPE_POSTNEGO_SIMULATION {get { return 'PostNego_Simulation'; }}
    private static final String TYPE_PE {get { return 'Period_Extension'; }}

    private static String contractDiscountQuery(String contractId, List<String> conditions) {
        String query = 'SELECT ';
        query += ' Id, ';
        query += ' Name, ';
        query += ' RecordTypeId, ';
        query += ' RecordType.DeveloperName, ';
        query += ' Asynchron_Processing__c, ';
        query += ' Base_Quantity_Nego__c, ';
        query += ' Base_TO_Nego__c, ';
        query += ' Base_TO_Nego_1__c, ';
        query += ' Base_TO_Nego_YearBase__c, ';
        query += ' Base_TO_Tariff_Nego__c, ';
        query += ' BusinessUnitScope__c, ';
        query += ' BusinessUnitScope__r.Name, ';
        query += ' commercial_reference__c, ';
        query += ' Condition_Type__r.' + String.join(ContractServices.staticPolComConditionFields, ', Condition_Type__r.') + ',';
        query += ' Condition_Type__r.InvoicePlanning__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', Condition_Type__r.InvoicePlanning__r.') + ',';
        query += ' Condition_Type__r.InvoicePlanningPE__r.' + String.join(ContractServices.staticInvoicePlanningFields, ', Condition_Type__r.InvoicePlanningPE__r.') + ',';                    
        query += ' Contract__c, ';
        query += ' Contract__r.Id, ';
        query += ' Contract__r.Name, ';
        query += ' Contract__r.RecordType.DeveloperName,';
        query += ' Contract__r.Multi_Year_Index__c,';
        query += ' Contract__r.Multi_Year_Total__c,';
        query += ' Contract__r.BusinessUnitContract__c,';
        query += ' Contract__r.BusinessUnitContract__r.SetInvoiceSeller__c,';
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
        query += ' Display_Order__c, ';
        query += ' Down_Payment_YE_Coverage__c, ';
        query += ' Down_Payment_YE_Value_Reference__c, ';
        query += ' First_invoice_date__c, ';
        query += ' Fist_Provision_Date__c, ';
        query += ' Index__c, ';
        query += ' Index_V2__c, ';
        query += ' Index_perc__c, ';
        query += ' Index_Val__c, ';
        query += ' Invoice_base__c, ';
        query += ' Invoice_period__c, ';
        query += ' Invoice_sequence__c, ';
        query += ' Is_AggregatedFromMove__c, ';
        query += ' Is_Conditional__c, ';
        query += ' is_duplicable__c, ';
        query += ' Is_Duplicable_PE__c, ';
        query += ' Exclusion_to_Nego_Base_Value__c, ';
        query += ' Is_Excluded_To_Nego_Base_F__c, ';
        query += ' Is_Excluded_To_Nego_Base_U__c, ';
        query += ' Is_Excluded_To_NegoBase__c, ';
        query += ' Is_Tariff_Condition__c, ';
        query += ' Is_Yearly_Condition__c, ';
        query += ' Nego_Discount_Type__c, ';
        query += ' OriginFromMove_amt__c, ';
        query += ' OriginFromMove_Condition__c, ';
        query += ' OriginFromMove_Condition__r.Nego_Discount_Type__c, ';
        query += ' OriginFromMove_ContractDiscount__c, ';
        query += ' OriginFromMove_per__c, ';
        query += ' OriginFromMove_U__c, ';
        query += ' Payment_Condition__c, ';
        query += ' Payment_Days__c, ';
        query += ' Product_Scope__c, ';
        query += ' Product_Scope__r.Name, ';
        query += ' Prog_TO_Nego__c, ';
        query += ' Provision_base__c, ';
        query += ' Provision_period__c, ';
        query += ' Provision_Sequence__c, ';
        query += ' Provisioning_YE_Coverage__c, ';
        query += ' Rank__c, ';
        query += ' Reference_Condition__c, ';
        query += ' Respects_Contract_Scope__c, ';
        query += ' Slab_1__c, ';
        query += ' Slab_2__c, ';
        query += ' Slab_3__c, ';
        query += ' Slab_4__c, ';
        query += ' Slab_5__c, ';
        query += ' Slab_6__c, ';
        query += ' Slab_7__c, ';
        query += ' Slab_8__c, ';
        query += ' Slab_9__c, ';
        query += ' Slab_10__c, ';
        query += ' slab_calc_method__c, ';
        query += ' Slab_Calc_Method_TO_Origin__c, ';
        query += ' slab_per_1__c, ';
        query += ' slab_per_2__c, ';
        query += ' slab_per_3__c, ';
        query += ' slab_per_4__c, ';
        query += ' slab_per_5__c, ';
        query += ' slab_per_6__c, ';
        query += ' slab_per_7__c, ';
        query += ' slab_per_8__c, ';
        query += ' slab_per_9__c, ';
        query += ' slab_per_10__c, ';
        query += ' slab_reach_actual__c, ';
        query += ' Slab_Reach_Actual_Qty__c, ';
        query += ' Slab_Reach_Actual_QtyInc__c, ';
        query += ' Slab_Reach_Actual_SellOut__c, ';
        query += ' Slab_Reach_Actual_SellOutInc__c, ';
        query += ' Slab_Reach_Actual_TOInc__c, ';
        query += ' Slab_reach_nego__c, ';
        query += ' Slab_Reach_Nego_Qty__c, ';
        query += ' Slab_Reach_Nego_QtyInc__c, ';
        query += ' Slab_Reach_Nego_SellOut__c, ';
        query += ' Slab_Reach_Nego_SellOutInc__c, ';
        query += ' Slab_Reach_Nego_TOInc__c, ';
        query += ' slab_target__c, ';
        query += ' Slab_val_1__c, ';
        query += ' Slab_Val_2__c, ';
        query += ' Slab_Val_3__c, ';
        query += ' Slab_Val_4__c, ';
        query += ' Slab_Val_5__c, ';
        query += ' slab_val_6__c, ';
        query += ' slab_val_7__c, ';
        query += ' slab_val_8__c, ';
        query += ' slab_val_9__c, ';
        query += ' slab_val_10__c, ';
        query += ' Status__c, ';
        query += ' unit_amount__c, ';
        query += ' Unit_Amount_Type__c, ';
        query += ' Value_amt__c, ';
        query += ' Value_amt_Y2__c, ';
        query += ' Value_amt_Y3__c, ';
        query += ' Value_amt_Y4__c, ';
        query += ' Value_amt_Y5__c, ';
        query += ' Value_per__c, ';
        query += ' Value_per_Y2__c, ';
        query += ' Value_per_Y3__c, ';
        query += ' Value_per_Y4__c, ';
        query += ' Value_per_Y5__c, ';
        query += ' YTD_Nego__c, ';
        query += ' YTD_Nego_Computed__c ';
        query += ' FROM Contract_Discount__c';
        query += ' WHERE Status__c <>\'Deleted\' AND Contract__c = \'' + contractId + '\' ';
        query += ' AND Parent_Discount__c = NULL ';
        query += ' AND (Contract__r.RecordType.DeveloperName <> \'Nego_Base\' ';
        query += ' OR (Contract__r.RecordType.DeveloperName = \'Nego_Base\' ';
        query += ' AND (Is_Excluded_To_NegoBase__c = FALSE ';
        query += ' OR (Is_Excluded_To_NegoBase__c <> FALSE ';
        query += ' AND Value_amt__c NOT IN (NULL, 0)))))';
        if(conditions != null && !conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        return query;
    }
    
    public static String getContractDiscountQuery(String contractId) {
        String query = contractDiscountQuery(contractId, null) + ' ORDER BY Display_Order__c';
        return query;
    }

    public static String getContractQuery(String contractId) {
        String query = 'SELECT';
        query += ' Id, ';
        query += ' Ext_Id__c, ';
        query += ' Name, ';
        query += ' CurrencyIsoCode, ';
        query += ' RecordTypeId, ';
        query += ' Status__c, ';
        query += ' RecordType.DeveloperName, ';
        query += ' Contract_BDate__c, ';
        query += ' BusinessUnitContract__c, ';
        query += ' BusinessUnitContract__r.Name, ';
        query += ' BusinessUnitSource__c, ';
        query += ' Contract_EDate__c, ';
        query += ' Contract_Type__c, ';
        query += ' Depreciation_Rate__c, ';
        query += ' Depreciation_Rate_Nb__c, ';
        query += ' Depreciation_Rate_YE__c, ';
        query += ' Depreciation_Rate1__c, ';
        query += ' Depreciation_Rate2__c, ';
        query += ' Depreciation_Rate3__c, ';
        query += ' Duration__c, ';
        query += ' Index1__c, ';
        query += ' Index1_perc__c, ';
        query += ' Index2__c, ';
        query += ' Index2_perc__c, ';
        query += ' Index3__c, ';
        query += ' Index3_perc__c, ';
        query += ' Index4__c, ';
        query += ' Index4_perc__c, ';
        query += ' Index5__c, ';
        query += ' Index5_perc__c, ';
        query += ' Index6__c, ';
        query += ' Index6_perc__c, ';
        query += ' Index7__c, ';
        query += ' Index7_perc__c, ';
        query += ' Index1_V2__c, ';
        query += ' Index1_V2_perc__c, ';
        query += ' Index2_V2__c, ';
        query += ' Index2_V2_perc__c, ';
        query += ' Index3_V2__c, ';
        query += ' Index3_V2_perc__c, ';
        query += ' Index4_V2__c, ';
        query += ' Index4_V2_perc__c, ';
        query += ' Index5_V2__c, ';
        query += ' Index5_V2_perc__c, ';
        query += ' Index6_V2__c, ';
        query += ' Index6_V2_perc__c, ';
        query += ' Index7_V2__c, ';
        query += ' Index7_V2_perc__c, ';
        query += ' Is_FixCond_Recalc_AfterDateChange__c, ';
        query += ' Is_OnTop_Simulation__c, ';
        query += ' Is_TotalTo_Recalc_AfterDateChange__c, ';
        query += ' Markdown_Rate_Break__c, ';
        query += ' Markdown_Rate_Promo__c, ';
        query += ' Markdown_Rate_Theft__c, ';
        query += ' Qty1__c, ';
        query += ' Qty2__c, ';
        query += ' Qty3__c, ';
        query += ' Qty4__c, ';
        query += ' Qty5__c, ';
        query += ' Qty6__c, ';
        query += ' Qty7__c, ';
        query += ' Qty8__c, ';
        query += ' Qty9__c, ';
        query += ' Qty10__c, ';
        query += ' Qty11__c, ';
        query += ' Qty12__c, ';
        query += ' Reference_Year__c, ';
        query += ' Rise_Rate__c, ';
        query += ' Rise_Rate_Nb__c, ';
        query += ' Rise_Rate_YE__c, ';
        query += ' Rise_Rate1__c, ';
        query += ' Rise_Rate2__c, ';
        query += ' Rise_Rate3__c, ';
        query += ' Rise_Rate4__c, ';
        query += ' Rise_Rate5__c, ';
        query += ' Rise_Rate6__c, ';
        query += ' Rise_Rate7__c, ';
        query += ' Rise_Rate8__c, ';
        query += ' Rise_Rate9__c, ';
        query += ' Rise_Rate10__c, ';
        query += ' SimulationNumber__c, ';
        query += ' CompanySigned_By__c, ';
        query += ' Contract_Commercial_BDate__c, ';
        query += ' Contract_Commercial_EDate__c, ';
        query += ' Multi_Year_Index__c, ';
        query += ' Multi_Year_Total__c, ';
        query += ' Is_Managed_By_ExternalSource__c, ';
        query += ' Supplier__c, ';
        query += ' Supplier__r.Name, ';
        query += ' Supplier_Nego_Scope__c, ';
        query += ' Supplier_Nego_Scope__r.Name, ';
        query += ' Supplier_Nego_Scope__r.BrandType__c, ';
        query += ' Supplier_Nego_Scope__r.CodeLong__c, ';
        query += ' Supplier_Nego_Scope__r.SupplyChainType__c, ';
        query += ' Supplier_Nego_Scope__r.SegmentationAttribut1__c, ';
        query += ' Supplier_Nego_Scope__r.SegmentationAttribut2__c, ';
        query += ' Supplier_Nego_Scope__r.SegmentationAttribut3__c, ';
        query += ' TO1__c, ';
        query += ' TO2__c, ';
        query += ' TO3__c, ';
        query += ' TO4__c, ';
        query += ' TO5__c, ';
        query += ' TO6__c, ';
        query += ' TO7__c, ';
        query += ' TO8__c, ';
        query += ' TO9__c, ';
        query += ' TO10__c, ';
        query += ' TO11__c, ';
        query += ' TO12__c, ';
        query += ' Total_Qty__c, ';
        query += ' Total_TO__c, ';
        query += ' Total_TO_Nego_YearBase__c, ';
        query += ' Total_TO_Tariff_Nego__c, ';
        query += ' IsCalculatedIndexV2__c ';

        query += ' FROM Contract__c';
        query += ' WHERE Status__c <> \'Deleted\' AND Id = \'' + contractId + '\' ';
        return query;
    }

    @AuraEnabled
    public static Boolean unlockContract(Id contractId) {
        if(Approval.isLocked(contractId)) {
            Approval.unlock(contractId);
        }
        return Approval.isLocked(contractId);
    }

    @AuraEnabled
    public static String getContractData(String contractId) {
        Contract__c contract;
        List<Contract_Discount__c> discounts;
        String contractQuery = getContractQuery(contractId);
        List<Contract__c> contractList = Database.query(contractQuery);
        if (!contractList.isEmpty()) {
            contract = contractList[0];
        }
        String contractDiscountQuery = getContractDiscountQuery(contractId);
        System.debug(' contractDiscountQuery >>> ' + contractDiscountQuery);
        List<Contract_Discount__c> contractDiscountList = Database.query(contractDiscountQuery);
        discounts = contractDiscountList;
        ResultWrapper result = new ResultWrapper(contract, discounts);
        NegoptimSettings settings = loadGlobalSettings();
        result.sBusinessType = settings?.sBusinessType;
        result.discountPercentScale = settings?.discountPercentScale;
        result.validTariffConditionMap = new Map<Id, Pol_Com_Condition__c>((List<Pol_Com_Condition__c>)Database.query(ContractServices.buildQueryTariffCondition(contract, null, null)));
        try { result.isLockedByAprovalProcess = objectIsLocked(contractId); } catch(Exception ex) { }
        // ContractServices indexServices = new ContractServices(contract, discounts);
        // List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
        // ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(contract, indexes);
        // wContractIndex.baseIndex = indexServices.getContractBaseIndex();
        // result.wIndex = wContractIndex;
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    // run the search on BUs and return the records found.
    public static String performBUSearch(String buId, String searchString) {
        List<BusinessUnit__c> result = new List<BusinessUnit__c>();
        // Check security on BusinessUnit__c fields
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.DeveloperNameRT__c.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.Code__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitRegion__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
        };
        if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            BusinessUnit__c bu;
            if (String.isNotBlank(buId)) {
                List<BusinessUnit__c> buList = [SELECT Id, BusinessUnitGroup__c, BusinessUnitCountryOrigin__c, BusinessUnitRegion__c FROM BusinessUnit__c WHERE Id = :buId];
                bu = !buList.isEmpty() ? buList[0] : null;
            }
            String soql = 'SELECT Id, Name, Code__c, RecordTypeId, DeveloperNameRT__c';
            String soqlbody = ' FROM BusinessUnit__c ';
            // add where clause
            List<String> conditions = new List<String>{'Status__c  = \'Open\''};
            // conditions.add('RecordType.DeveloperName IN (\'Store\', \'Web\', \'Warehouse\', \'Country\', \'List\', \'Group\', \'Banner\')');
            if(String.isNotBlank(searchString)) {
                conditions.add('(Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\' OR Code__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')');
            }
            if(bu != null) {
                String whereClause = '(Id = \'' + bu.Id  +'\' OR BusinessUnitGroup__c = \'' + bu.Id  +'\' OR BusinessUnitCountryOrigin__c = \'' + bu.Id  +'\' OR BusinessUnitRegion__c = \'' + bu.Id  +'\'';
                Set<Id> buListIdSet = new Set<Id>();
                // Check security on BULink__c fields
                String[] orgaBUListDetailFields = new String[] {
                    SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                    SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                };
                if(NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
                    // get BUs of type List
                    // All related banners of the BU List must be related to the contract BU
                    // first query BU of Type List and get the count of related banner
                    for (BusinessUnit__c listBU : [SELECT Id, (SELECT Id, BusinessUnitDetail__c FROM BULNKBusinessUnitMaster__r WHERE BusinessUnitDetail__r.RecordType.DeveloperName = 'Banner')
                                                             FROM BusinessUnit__c
                                                             WHERE RecordType.DeveloperName = 'List'])
                    {
                        if (listBU.BULNKBusinessUnitMaster__r != null && listBU.BULNKBusinessUnitMaster__r.size() > 0) {
                            buListIdSet.add(listBU.Id);
                            if(listBU.Id == bu.Id) {
                                for(BULink__c item : listBU.BULNKBusinessUnitMaster__r) {
                                    buListIdSet.add(item.BusinessUnitDetail__c);
                                }
                            }
                        }
                    }
                    // get the count of bu list details that are not related to the Contract BU
                    List<AggregateResult> results = [SELECT BusinessUnitMaster__c BusinessUnitMaster__c, COUNT(Id) relatedCount
                                                     FROM BULink__c
                                                     WHERE BusinessUnitMaster__c IN :buListIdSet
                                                     AND BusinessUnitDetail__r.RecordType.DeveloperName = 'Banner'
                                                     AND BusinessUnitDetail__r.BusinessUnitGroup__c <> :bu.Id
                                                     AND BusinessUnitDetail__r.BusinessUnitCountryOrigin__c <> :bu.Id
                                                     AND BusinessUnitDetail__r.BusinessUnitRegion__c <> :bu.Id
                                                     GROUP BY BusinessUnitMaster__c];
                    // loop on results. and remove the entity Id from buListIdSet
                    // for each result in results, if the record exist then there are banners that are not related to the Contract BU
                    for (AggregateResult aggregateresult : results) {
                        Id entityId = String.valueOf(aggregateresult.get('BusinessUnitMaster__c'));
                        if (buListIdSet.contains(entityId)) {
                            buListIdSet.remove(entityId);
                        }
                    }
                    // if buListIdSet.size > 0 then include the Ids of BU Lists in the WHERE clause
                    if(buListIdSet != null && !buListIdSet.isEmpty()) {
                        whereClause += String.isNotBlank(whereClause) ? ' OR ' : '(';
                        whereClause += 'Id IN (\'' + String.join(new List<Id>(buListIdSet), '\',\'') +'\')';
                    }
                }
                whereClause += ')';
                conditions.add(whereClause);
            }
            soqlbody += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
            soqlbody += ' ORDER BY RecordType.DeveloperName, Name';
            soql += soqlbody;
            result = Database.query(soql);
        }
        return JSON.serialize(result);
    }
    @AuraEnabled
    public static String performNSSearch(String nsId, String supplierId, String searchString) {
        List<NegoScope__c> results = new List<NegoScope__c>();
        // Check fields security
        String[] negoScopeFields = new String[] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.Name.Name,
            SObjectType.NegoScope__c.fields.Status__c.Name,
            SObjectType.NegoScope__c.fields.NS_Code__c.Name,
            SObjectType.NegoScope__c.fields.Supplier__c.Name,
            SObjectType.NegoScope__c.fields.NegoScopeParent__c.Name,
            SObjectType.NegoScope__c.fields.IncludeAllBrands__c.Name,
            SObjectType.NegoScope__c.fields.IncludeAllHEs__c.Name,
            SObjectType.NegoScope__c.fields.LastModifiedDate.Name,
            SObjectType.NegoScope__c.fields.CreatedDate.Name,
            SObjectType.NegoScope__c.fields.IncludeAllProducts__c.Name
        };
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.Id.Name,
            SObjectType.Supplier__c.fields.Name.Name
        };
        if(NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields) && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)) {
            String soql = 'SELECT Id, Name, Status__c, NS_Code__c, Supplier__r.Name, NegoScopeParent__r.Name, IncludeAllBrands__c, IncludeAllHEs__c, IncludeAllProducts__c, LastModifiedDate, CreatedDate ';
            String soqlbody = ' FROM NegoScope__c ';
            soqlbody += 'WHERE Supplier__c =  \'' + supplierId +'\'';
            // if (String.isNotBlank(searchString)) {
            //     if (SObjectType.Supplier__c.fields.Name.isFilterable()) {
            //         if (!SObjectType.Supplier__c.fields.Name.isEncrypted()) {
            //             soqlbody += ' AND Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'';
            //         } else {
            //             soqlbody += ' AND Name = \'' + String.escapeSingleQuotes(searchString) + '\'';
            //         }
            //     }
            // }
            if(String.isNotBlank(nsId)) {
                soqlbody += ' AND (NegoScopeParent__c = \'' + nsId + '\' OR Id = \'' + nsId +'\')';
            }
            soql += soqlbody;
            // soql += ' LIMIT 100';
            results = Database.query(soql);
        }
        return JSON.serialize(results);
    }
    @AuraEnabled
    public static String calculateIndex(String contract_JSON, String discounts_JSON) {
        System.debug(' contract_JSON >>> ' + contract_JSON);
        System.debug(' discounts_JSON >>> ' + discounts_JSON);
        Contract__c contract = (Contract__c)JSON.deserialize(contract_JSON, Contract__c.class);
        List<Contract_Discount__c> discounts = (List<Contract_Discount__c>)JSON.deserialize(discounts_JSON, List<Contract_Discount__c>.class);
        ContractServices.calculateContractRiseDepRates(contract);
        ContractServices indexServices = new ContractServices(contract, discounts);
        List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
        ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(contract, indexes);
        wContractIndex.baseIndex = indexServices.getContractBaseIndex();
        wContractIndex.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
        // ContractServices.sort(discounts, true, true);
        return JSON.serialize(new Map<String, Object> {'wIndex' => wContractIndex, 'contract' => contract, 'discounts' => discounts});
    }
    @AuraEnabled
    public static String calculateIndexAndSave(Id contractId) {
        // System.debug(' contract_JSON >>> ' + contract_JSON);
        // System.debug(' discounts_JSON >>> ' + discounts_JSON);
        Contract__c contract = Database.query(getContractQuery(contractId));
        List<Contract_Discount__c> discounts = Database.query(getContractDiscountQuery(contractId));
        ContractServices.calculateContractRiseDepRates(contract);
        ContractServices indexServices = new ContractServices(contract, discounts);
        List<ContractServices.ContractIndexWrapper> indexes = indexServices.calculateContractIndex(true);
        ContractIndexMapWrapper wContractIndex = new ContractIndexMapWrapper(contract, indexes);
        wContractIndex.baseIndex = indexServices.getContractBaseIndex();
        wContractIndex.isCalculatedIndexV2 = contract.IsCalculatedIndexV2__c;
        Database.update(contract, false);
        Database.update(discounts, false);
        // ContractServices.sort(discounts, true, true);
        return JSON.serialize(new Map<String, Object> {'wIndex' => wContractIndex, 'contract' => contract, 'discounts' => discounts});
    }
    @AuraEnabled
    public static String generateContractSimulationName(String createcontractwrapper_JSON) {
        Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Map<String, String> contractRecordTypeDeveloperNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
        CreateContractWrapper createcontractwrapper = (CreateContractWrapper)JSON.deserialize(createcontractwrapper_JSON, CreateContractWrapper.class);
        Contract__c sourceContract = createcontractwrapper.sourceContract;
        String targetContractRTDeveloperName = createcontractwrapper.targetContractRTDeveloperName;
        Integer simulationNumber = createcontractwrapper.simulationNumber;
        Contract__c newContract = sourceContract.clone(false);
        newContract.Name = null;
        simulationNumber++;
        newContract.SimulationNumber__c = simulationNumber;
        ContractServices.generateContractName(newContract, sourceContract.Supplier__r.Name, sourceContract.Supplier_Nego_Scope__r.CodeLong__c, contractRTIds, contractRecordTypeDeveloperNameToLabelMap.get(targetContractRTDeveloperName));
        return newContract.Name;
    }
    @AuraEnabled
    public static String createContract(String createcontractwrapper_JSON) {
        System.SavePoint sp = Database.setSavepoint();
        try {
            System.debug(' createcontractwrapper_JSON >>> ' + createcontractwrapper_JSON);
            CreateContractWrapper createcontractwrapper = (CreateContractWrapper)JSON.deserialize(createcontractwrapper_JSON, CreateContractWrapper.class);
            Id nsId = createcontractwrapper.nsId;
            Integer negoYear = createcontractwrapper.negoYear;
            Contract__c refNegoBase = createcontractwrapper.refNegoBase;
            Contract__c contractPE = createcontractwrapper.contractPE;
            Contract__c sourceContract = createcontractwrapper.sourceContract;
            List<Contract_Discount__c> refDiscountsList = createcontractwrapper.refDiscountsList;
            String targetContractRTDeveloperName = createcontractwrapper.targetContractRTDeveloperName;
            String contractName = createcontractwrapper.contractName;
            Integer simulationNumber = createcontractwrapper.simulationNumber;
            Integer postSimulationNumber = createcontractwrapper.postSimulationNumber;
            Id refContractBUId = createcontractwrapper.refContractBUId;
            Id refContractSourceBUId = createcontractwrapper.refContractSourceBUId;
            String prefix = NegoptimHelper.getPackagePrefix(true);
            Integer toFieldScale = SObjectType.Contract__c.fields.TO1__c.getScale();
            Integer qtyFieldScale = SObjectType.Contract__c.fields.Qty1__c.getScale();
            String sBusinessType = loadGlobalSettings()?.sBusinessType;
            String toContractType = targetContractRTDeveloperName;
            String fromContractType = sourceContract.RecordType.DeveloperName;
            Contract__c toContract = sourceContract.clone();
            Date beginDate = toContractType == TYPE_POSTNEGO_SIMULATION ? sourceContract.Contract_BDate__c : createcontractwrapper.beginDate;
            Date endDate = toContractType == TYPE_POSTNEGO_SIMULATION ? sourceContract.Contract_EDate__c : createcontractwrapper.endDate;
            // toContract = new Contract__c(Name = contractName, Contract_BDate__c = beginDate, Contract_EDate__c = endDate);
            toContract.Name = contractName;
            toContract.Contract_BDate__c = beginDate;
            toContract.Contract_EDate__c = endDate;
            Contract__c referenceContract = sourceContract;
            Map<String, String> contractRecordTypeDeveloperNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
            Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
            Map<String, Id> contractDiscountRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
            List<Pol_Sale_Condition_Exception__c> salesConditionExceptionList;
            Set<String> validNewTariffSet = new Set<String>();
            Map<Id, Pol_Com_Condition__c> validTariffPEMapping = new Map<Id, Pol_Com_Condition__c>();
            Set<Id> validTariffSet = new Set<Id>();
            Set<Id> validTariffSetP1 = new Set<Id>();
            Map<Id, Pol_Com_Condition__c> validTariffNegoYearMap = new Map<Id, Pol_Com_Condition__c>();
            Map<Id, Pol_Com_Condition__c> validTariffPEMap = new Map<Id, Pol_Com_Condition__c>();
            Map<Id, Pol_Com_Condition__c> validFoldingMap = new Map<Id, Pol_Com_Condition__c>();
            Contract__c newContract = referenceContract.clone(false);
            List<Contract_Discount__c> newConditions = new List<Contract_Discount__c>();
            List<Pol_Sale_Condition_Exception__c> newSalesConditionExceptionList = new List<Pol_Sale_Condition_Exception__c>();
            if(toContractType == TYPE_PE && fromContractType == TYPE_NEGO_BASE && sourceContract != null) {
                // NEG-6088: stop the code
                // clone conditions PE from NBI contract
                /*List<Contract__c> refNegoBaseInits = [SELECT Id
                                                                     FROM Contract__c
                                                                     WHERE Supplier_Nego_Scope__c = :sourceContract.Supplier_Nego_Scope__c
                                                                     AND Reference_Year__c = :sourceContract.Reference_Year__c
                                                                     AND BusinessUnitContract__c = :sourceContract.BusinessUnitContract__c
                                                                     AND RecordType.DeveloperName = 'Nego_Base_Init' LIMIT 1];
                if(refNegoBaseInits != null && !refNegoBaseInits.isEmpty()) {
                    refDiscountsList = new List<Contract_Discount__c>();
                    List<Contract_Discount__c> refNegoBaseInitDiscounts = Database.query(getContractDiscountQuery(refNegoBaseInits[0].Id));
                    for(Contract_Discount__c item : refNegoBaseInitDiscounts) {
                        if(item.Reference_Condition__c != null) {
                            refDiscountsList.add(item);
                        }
                    }
                }*/
            }
            if (refNegoBase != null) {
                Contract__c negoYearRefContract = refNegoBase.clone(true);
                if (refNegoBase.Contract_BDate__c.year() != negoYear) {
                    negoYearRefContract.Contract_BDate__c = negoYearRefContract.Contract_BDate__c.addYears(1);
                    //negoYearRefContract.Contract_EDate__c = negoYearRefContract.Contract_EDate__c.addYears(1);
                }
                if (refNegoBase.BusinessUnitContract__c == null) { negoYearRefContract.BusinessUnitContract__c = refContractBUId; }
                if (refNegoBase.BusinessUnitSource__c == null) { negoYearRefContract.BusinessUnitSource__c = refContractSourceBUId; }
                // Get available tariff Conditions
                String queryNegoyear = ContractServices.buildQueryTariffCondition(negoYearRefContract, null, null);
                List<Pol_Com_Condition__c> tariffConditions = Database.query(queryNegoyear);
                for (Pol_Com_Condition__c item : tariffConditions) {
                    validNewTariffSet.add(item.Index__c + ' - ' + item.Nego_Discount_Type__c);
                    validTariffNegoYearMap.put(item.Id, item);
                    validTariffSet.add(item.Id);
                    if (item.Is_Folding_Discount__c == true) { validFoldingMap.put(item.Id, item); }
                    // PT clone
                    // if (item.Duplication_Discount_Mapping__c != null) {
                    //     validTariffPEMapping.put(item.Duplication_Discount_Mapping__c, item);
                    // }
                }
                Contract__c negoYearPEContract;
                if (contractPE == null) { negoYearPEContract = negoYearRefContract.clone(true); negoYearPEContract.RecordTypeId = contractRTIds.get(TYPE_PE); } else { negoYearPEContract = contractPE; }
                if (negoYearPEContract != null) {
                    String queryPT = ContractServices.buildQueryTariffCondition(negoYearPEContract, null, null);
                    tariffConditions = Database.query(queryPT);
                    for (Pol_Com_Condition__c item : tariffConditions) {
                        validTariffPEMap.put(item.Id, item);
                        validTariffSetP1.add(item.Id);
                        validTariffSet.add(item.Id);
                        if (item.Duplication_Discount_Mapping__c != null) {
                            validTariffSetP1.add(item.Duplication_Discount_Mapping__c);
                        }
                        if (item.Duplication_Discount_Mapping__c != null) {
                            validTariffPEMapping.put(item.Duplication_Discount_Mapping__c, item);
                        }
                    }
                }
            }
            if (fromContractType == TYPE_NEGO_BASE && toContractType == TYPE_SIMULATION
                || fromContractType == TYPE_NEGO_BASE && toContractType == TYPE_TARGET
                || fromContractType == TYPE_NEGO_BASE && toContractType == TYPE_SAFE_BALANCE
                || fromContractType == TYPE_SAFE_BALANCE && toContractType == TYPE_SIMULATION
                || fromContractType == TYPE_SIMULATION && toContractType == TYPE_SIMULATION
                || fromContractType == TYPE_SIMULATION && toContractType == TYPE_SAFE_BALANCE
                || fromContractType == TYPE_NEGO_BASE && toContractType == TYPE_PE
                || fromContractType == TYPE_SAFE_BALANCE && toContractType == TYPE_PE
                || fromContractType == TYPE_SAFE_BALANCE && toContractType == TYPE_SAFE_BALANCE
                || fromContractType == TYPE_SIGNED && toContractType == TYPE_POSTNEGO_SIMULATION)
            {
                Boolean overrideDuplication = fromContractType == toContractType || toContractType == TYPE_POSTNEGO_SIMULATION;
                Boolean alwaysFillParent = fromContractType == TYPE_NEGO_BASE;
                //toContractType always on nego year
                Boolean hasSelectionOptions = false;
                Boolean isDuplicatePE = toContractType == TYPE_PE;
                newContract.Is_OnTop_Simulation__c = false;
                // newContract.Selected_Simul_For_Approval__c = false;
                newContract.RecordTypeId = contractRTIds.get(toContractType);
                newContract.Parent_Contract__c = referenceContract.Id;
                Schema.DescribeFieldResult statusFieldDescribe = Contract__c.Status__c.getDescribe();
                String defaultStatusByRT = null;
                try{
                    // defaultStatusByRT = ((String)PicklistHelper.getPicklistDefaultValueByRecordTypeId(Contract__c.SObjectType, statusFieldDescribe, newContract.RecordTypeId));
                } catch(Exception picklistException) {

                }
                newContract.Status__c = isDuplicatePE ? 'Validated'
                                                       : (toContractType == TYPE_SAFE_BALANCE ? 'In preparation'
                                                       : (defaultStatusByRT != null ? defaultStatusByRT : ((String)statusFieldDescribe.getDefaultValue())));
                Boolean isForSimulation = false;
                newContract.Contract_BDate__c = beginDate;
                newContract.Contract_Commercial_BDate__c = beginDate;
                newContract.Contract_EDate__c = endDate;
                newContract.Contract_Commercial_EDate__c = endDate;
                if (!isDuplicatePE) {
                    Boolean fullYears = checkFullContractYears(newContract);
                    if(!fullYears) {
                        newContract.Contract_EDate__c = date.newInstance(negoYear, referenceContract.Contract_EDate__c.month(), referenceContract.Contract_EDate__c.day());
                        newContract.Contract_Commercial_EDate__c = date.newInstance(negoYear, referenceContract.Contract_Commercial_EDate__c.month(), referenceContract.Contract_Commercial_EDate__c.day());
                    }
                    newContract.Multi_Year_Total__c = 1;
                    if (toContractType == TYPE_SIMULATION || toContractType == TYPE_SAFE_BALANCE) {
                        newContract.Name = toContract.Name;
                        // newContract.Contract_Commercial_BDate__c = toContract.Contract_Commercial_BDate__c;
                        // newContract.Contract_BDate__c = toContract.Contract_Commercial_BDate__c;
                        newContract.Is_TotalTo_Recalc_AfterDateChange__c = toContract.Is_TotalTo_Recalc_AfterDateChange__c;
                        newContract.Is_FixCond_Recalc_AfterDateChange__c = toContract.Is_FixCond_Recalc_AfterDateChange__c;
                    } else {
                        newContract.Contract_Commercial_BDate__c = date.newInstance(negoYear, referenceContract.Contract_Commercial_BDate__c.month(), referenceContract.Contract_Commercial_BDate__c.day());
                    }
                    if (toContractType == TYPE_SIMULATION || toContractType == TYPE_SAFE_BALANCE) {
                        simulationNumber++;
                        newContract.SimulationNumber__c = simulationNumber;
                        if (toContractType == TYPE_SAFE_BALANCE && sBusinessType == 'CPG') { toContract.Name = referenceContract.Name.Substring(0 ,referenceContract.Name.lastIndexOf ('-') + 1);}
                        // ContractServices.generateContractName(newContract, supplier.Name, selectedNegoScope.CodeLong__c, contractRTIds, this.recordTypeMapLabels.get(contractRTIds.get(toContractType)));
                        newContract.Secure_Multiyear__c = NegoptimHelper.defaultPicklistValue(Contract__c.Secure_Multiyear__c.getDescribe());
                        if (newContract.Secure_Multiyear__c == '2 years' || newContract.Secure_Multiyear__c == '3 years') { isForSimulation = true; }
                        isForSimulation = true;
                    }
                    if (toContractType == TYPE_POSTNEGO_SIMULATION) {
                        postSimulationNumber++;
                        newContract.SimulationNumber__c = postSimulationNumber;
                    }
                }
                // update TO
                Integer newNbOfMonths = newContract.Contract_BDate__c.monthsBetween(newContract.Contract_EDate__c) + 1;
                Integer oldNbOfMonths = referenceContract.Contract_BDate__c.monthsBetween(referenceContract.Contract_EDate__c) + 1;
                Decimal totalTO = referenceContract.Total_TO__c;
                Decimal totalQty = referenceContract.Total_Qty__c;
                if (isDuplicatePE || newContract.Is_TotalTo_Recalc_AfterDateChange__c == true) {
                    totalTO = 0;
                    totalQty = 0;
                    for (Integer i = 1 ; i <= 12 ; i++) {
                        String fieldname = prefix + 'TO' + i + '__c';
                        Decimal to = referenceContract.get(fieldname) != null && oldNbOfMonths != 0 ? (Decimal.valueOf(String.valueOf(referenceContract.get(fieldname))) * newNbOfMonths)/oldNbOfMonths : 0;
                        to = to.setScale(toFieldScale, System.RoundingMode.HALF_UP);
                        newContract.put(fieldname, to);
                        totalTO += to;
                        fieldname = prefix + 'Qty' + i + '__c';
                        Decimal qty = referenceContract.get(fieldname) != null && oldNbOfMonths != 0 ? (Decimal.valueOf(String.valueOf(referenceContract.get(fieldname))) * newNbOfMonths)/oldNbOfMonths : 0;
                        qty = qty.setScale(qtyFieldScale, System.RoundingMode.HALF_UP);
                        newContract.put(fieldname, qty);
                        totalQty += qty;
                    }
                }
                newContract.Contract_Type__c = (toContractType == TYPE_SIMULATION || toContractType == TYPE_SAFE_BALANCE || toContractType == TYPE_POSTNEGO_SIMULATION) ?  TYPE_SIMULATION : TYPE_CONTRACT;
                // newContract.Contract_Numbder__c = null;
                if (sBusinessType != 'CPG' && newContract.Name != 'new Contract') {
                    newContract.Name = null;
                }
                newContract.Is_Managed_By_ExternalSource__c = false;
                // Name: *NOM DU FOURNISSEUR – NUMERO Ds’ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
                // Code: *NUMERO D’ACCORD (MN-8chiffres) – ANNEE – LIBELLE DE LA SEQUENCE *
                if (newContract.Name == null) {
                    ContractServices.generateContractName(newContract, referenceContract.Supplier__r.Name, referenceContract.Supplier_Nego_Scope__r.CodeLong__c, contractRTIds, contractRecordTypeDeveloperNameToLabelMap.get(targetContractRTDeveloperName));
                }
                // Pol Sale Condition Exception Fields to be checked
                String[] PolSaleConditionExceptionFields = new String[] {
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Rebate_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Service_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.VAT_Finance_Rate__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Days__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Days__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Condition__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc1__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc1__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc1__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.HierarchyPaymentTermExc2__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev_Exc2__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Condition_exc2__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Contract__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Buying_Payment_Term_Abbrev__c.Name,
                    SObjectType.Pol_Sale_Condition_Exception__c.fields.Services_Payment_Term_Abbrev__c.Name
                };
                // Fetch Pol_Sale_Condition_Exception__c of reference contract if exist
                if (salesConditionExceptionList == null) {
                    salesConditionExceptionList = new List<Pol_Sale_Condition_Exception__c>();
                    if (NegoptimHelper.checkAccessibility(Pol_Sale_Condition_Exception__c.SObjectType, PolSaleConditionExceptionFields)) {
                        // if not foreign supplier, clone sales exception from reference contract
                        // if foreign supplier, Sales exception will be created on contract creation from trigger
                        salesConditionExceptionList = [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                        Buying_Payment_Days__c, Buying_Payment_Condition__c,
                                                        Services_Payment_Days__c, Services_Payment_Condition__c,
                                                        HierarchyPaymentTermExc1__c, Buying_Payment_Term_Abbrev_Exc1__c, Buying_Payment_Condition_exc1__c,
                                                        HierarchyPaymentTermExc2__c, Buying_Payment_Term_Abbrev_Exc2__c, Buying_Payment_Condition_exc2__c,
                                                        Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c, Contract__c
                                                        FROM Pol_Sale_Condition_Exception__c
                                                        WHERE Contract__c = :referenceContract.Id
                                                        AND Contract__r.Is_Foreign_Supplier__c = FALSE];
                    }
                }
                if (salesConditionExceptionList.size() > 0) { Pol_Sale_Condition_Exception__c salesConditionException = salesConditionExceptionList.get(0).clone(false, true, false, false); salesConditionException.Policy_Sales_Conditions__c = null; salesConditionException.Contract__c = null; newSalesConditionExceptionList.add(salesConditionException); }
                if (refDiscountsList != null) {
                    // NEG-6382/85/88: check if code budget exist in prestation NB
                    Map<String, Contract_Discount__c> conditionsChangedInPrestationsNBMap = new Map<String, Contract_Discount__c>();
                    Map<String, Id> tariffConditionsForPrestationNBMap = new Map<String, Id>();
                    if(toContractType == TYPE_PE && fromContractType == TYPE_NEGO_BASE && sourceContract != null) {
                        Set<String> conditionTypeNamesSet = new Set<String>();
                        for (Contract_Discount__c item : refDiscountsList) {
                            if(String.isNotBlank(item.Condition_Type__c)) {
                                conditionTypeNamesSet.add(item.Condition_Type__r.Name);
                            }
                        }
                        List<Pol_Com_Condition__c> tariffConditionsForPrestationNBs = [SELECT Id, Name, Original_Name__c
                                                                                                      FROM Pol_Com_Condition__c
                                                                                                      WHERE Original_Name__c IN :conditionTypeNamesSet
                                                                                                      AND Condition_status__c <> 'Close'];
                        if(!tariffConditionsForPrestationNBs.isEmpty()) {
                            for(Pol_Com_Condition__c item : tariffConditionsForPrestationNBs) {
                                tariffConditionsForPrestationNBMap.put(item.Original_Name__c, item.Id);// Original_Name__c (JCS), Id (SCJ))
                            }
                            List<Contract__c> refNegoBaseInits = [SELECT Id
                                                                                 FROM Contract__c
                                                                                 WHERE Supplier_Nego_Scope__c = :sourceContract.Supplier_Nego_Scope__c
                                                                                 AND Reference_Year__c = :sourceContract.Reference_Year__c
                                                                                 AND BusinessUnitContract__c = :sourceContract.BusinessUnitContract__c
                                                                                 AND RecordType.DeveloperName = 'Nego_Base_Init' LIMIT 1];
                            if(refNegoBaseInits != null && !refNegoBaseInits.isEmpty()) {
                                List<Id> conditionTypeIds = tariffConditionsForPrestationNBMap.values();
                                List<Contract_Discount__c> refConditionsNBI = Database.query(contractDiscountQuery(refNegoBaseInits[0].Id, new List<String>{'Condition_Type__c IN :conditionTypeIds'}));
                                if(!refConditionsNBI.isEmpty()) {
                                    for(Contract_Discount__c item : refConditionsNBI) {
                                        conditionsChangedInPrestationsNBMap.put(item.Condition_Type__c, item);
                                    }
                                }
                            }
                        }
                    }
                    for (Contract_Discount__c item : refDiscountsList) {
                        Contract_Discount__c newCondition = item;
                        Pol_Com_Condition__c conditionDefinition = item.Condition_Type__r;
                        if (!conditionsChangedInPrestationsNBMap.isEmpty()
                            && tariffConditionsForPrestationNBMap.containsKey(item.Condition_Type__r.Name)
                            && conditionsChangedInPrestationsNBMap.containsKey(tariffConditionsForPrestationNBMap.get(item.Condition_Type__r.Name)))
                        {
                            newCondition = conditionsChangedInPrestationsNBMap.get(tariffConditionsForPrestationNBMap.get(item.Condition_Type__r.Name));
                            conditionDefinition = newCondition.Condition_Type__r;
                        }
                        Contract_Discount__c condition = addDuplicateCondition(overrideDuplication, alwaysFillParent, nsId, referenceContract, newContract, newCondition, conditionDefinition, isDuplicatePE, isForSimulation, totalTO, totalQty, null /* subConditions */, sBusinessType);
                        if (condition != null) { newConditions.add(condition); }
                    }
                }
            }
            if (newContract.RecordTypeId != contractRTIds.get(TYPE_SIMULATION) || newContract.Name == 'new Contract') {
                newContract.Name = null;
            }
            insert newContract;
            for (Contract_Discount__c item : newConditions) {
                item.Contract__c = newContract.Id;
                item.Asynchron_Processing__c = true;
                item.RecordTypeId = contractDiscountRTIds.get('To_Be_Signed');
                if (toContractType == TYPE_PE) {
                    item.Status__c = 'Valdiated';
                } else {
                    item.Status__c = 'Open';
                }
            }
            List<Database.SaveResult> results = Database.insert(newConditions, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs){
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        System.debug('err.getStatusCode() >>>' + err.getStatusCode());
                        if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                            throw new AuraHandledException(String.valueOf(err.getStatusCode()));
                        }
                    }
                    System.debug('ERRORS >>>' + errorMessage);
                }
            }
            newContract = Database.query(getContractQuery(newContract.Id));
            newConditions = Database.query(getContractDiscountQuery(newContract.Id));
            ContractServices.calculateContractRiseDepRates(newContract);
            ContractServices indexServices = new ContractServices(newContract, newConditions);
            indexServices.calculateContractIndex(true);
            Database.update(newContract, false);
            results = Database.update(newConditions, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs){
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        System.debug('err.getStatusCode() >>>' + err.getStatusCode());
                        if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
                            throw new AuraHandledException(String.valueOf(err.getStatusCode()));
                        }
                    }
                    System.debug('ERRORS >>>' + errorMessage);
                }
            }
            // Insert CGV Exception
            for (Pol_Sale_Condition_Exception__c item : newSalesConditionExceptionList) {
                item.Contract__c = newContract.Id;
                item.Ext_Id__c = newContract.Ext_Id__c;
                item.Ext_Id2__c = newContract.Ext_Id__c;
            }
            Database.insert(newSalesConditionExceptionList, false);
            return JSON.serialize(newContract);
        } catch(DMLException ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage() + ex.getLineNumber());
        } catch(AuraHandledException ex) {
            Database.rollback(sp);
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw ex;
        } catch(Exception ex) {
            Database.rollback(sp);
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ex.getLineNumber());
        }
    }
    // calculate total years of contract
    private static Boolean checkFullContractYears(Contract__c item) {
        if (item.Contract_Commercial_BDate__c != null || item.Contract_Commercial_EDate__c != null) {
            Decimal monthDiff = item.Contract_Commercial_BDate__c.monthsBetween(item.Contract_Commercial_EDate__c);
            if (item.Contract_Commercial_EDate__c.day() >= item.Contract_Commercial_BDate__c.day()) monthDiff++;
            item.Multi_Year_Total__c = Math.ceil(monthDiff/12).intValue();
            return Math.mod(Integer.valueOf(monthDiff), 12) == 0;
        }
        // return true. if the commercial dates are blank then most likely the contract is one year long
        return true;
    }
    private static Contract_Discount__c addDuplicateCondition(Boolean overrideDuplication, Boolean alwaysFillParent, Id nsId, Contract__c referenceContract, Contract__c newContract, Contract_Discount__c parentCondition, Pol_Com_Condition__c conditionDefinition,
                                                       Boolean isDuplicatePE, Boolean isForSimulation, Decimal totalTO, Decimal totalQty, List<Contract_Discount__c> subConditions, String sBusinessType)
    {
        Integer conditionValueAmtScale = SObjectType.Contract_Discount__c.fields.Value_amt__c.getScale();
        Integer conditionBaseTONegoScale = SObjectType.Contract_Discount__c.fields.Base_TO_Nego__c.getScale();
        Integer conditionBaseQtyNegoScale = SObjectType.Contract_Discount__c.fields.Base_Quantity_Nego__c.getScale();
        Boolean isDuplicable = overrideDuplication
                                || (!isDuplicatePE && parentCondition.is_duplicable__c == true)
                                || (isDuplicatePE && parentCondition.Is_Duplicable_PE__c == true);
        if (!isDuplicable) return null;
        Contract_Discount__c condition = parentCondition.clone(false, true, false, false);
        condition.Is_Excluded_To_NegoBase__c = false;
        condition.Is_Excluded_To_Nego_Base_F__c = false;
        condition.Is_Excluded_To_Nego_Base_U__c = false;
        condition.Exclusion_to_Nego_Base_Value__c = null;
        condition.Exclusion_To_NegoBase_Justif__c = null;
        // Reference_condition__c = NB Condition
        if(alwaysFillParent || condition.Reference_condition__c == null) condition.Reference_condition__c = parentCondition.Id;
        condition.Disc_BDate__c = newContract.Contract_BDate__c;
        condition.Disc_EDate__c = newContract.Contract_EDate__c;
        // Check Is_Duplicable_PE__c
        if (isDuplicatePE && parentCondition.Is_Duplicable_PE__c == true) {
            if (condition.first_invoice_date__c != null) { condition.first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(condition.Disc_BDate__c.Year(), condition.Disc_BDate__c.month()); }
            if (condition.Fist_Provision_Date__c != null) { condition.Fist_Provision_Date__c = NegoptimHelper.getLastDayOfMonth(condition.Disc_BDate__c.Year(), condition.Disc_BDate__c.month()); }
            condition.Value_per__c = parentCondition.Value_per__c;
        }
        if (isForSimulation == true) {
            condition.first_invoice_date__c = null;
        }
        // Calculate amount based on dates on refernce contracts
        Decimal amount = condition.Value_amt__c;
        Decimal baseTONego = condition.Base_TO_Nego__c;
        Decimal baseQtyNego = condition.Base_Quantity_Nego__c;
        if ((isDuplicatePE || newContract.Is_FixCond_Recalc_AfterDateChange__c == true) && !parentCondition.Condition_Type__r.Is_Yearly_Condition__c) {
            Integer newNbOfMonths = newContract.Contract_BDate__c.monthsBetween(newContract.Contract_EDate__c) + 1;
            Integer oldNbOfMonths = referenceContract.Contract_BDate__c.monthsBetween(referenceContract.Contract_EDate__c) + 1;
            amount = parentCondition.Value_amt__c != null && oldNbOfMonths != 0 ? parentCondition.Value_amt__c * newNbOfMonths/oldNbOfMonths : 0;
            amount = amount.setScale(conditionValueAmtScale, System.RoundingMode.HALF_UP);
            // calculate Base_TO_Nego__c
            if (!parentCondition.Respects_Contract_Scope__c) {
                baseTONego = parentCondition.Base_TO_Nego__c != null && oldNbOfMonths != 0 ? parentCondition.Base_TO_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                baseTONego = baseTONego.setScale(conditionBaseTONegoScale, System.RoundingMode.HALF_UP);
                condition.Base_TO_Nego__c = baseTONego;
                baseQtyNego = parentCondition.Base_Quantity_Nego__c != null && oldNbOfMonths != 0 ? parentCondition.Base_Quantity_Nego__c * newNbOfMonths/oldNbOfMonths : 0;
                baseQtyNego = baseQtyNego.setScale(conditionBaseQtyNegoScale, System.RoundingMode.HALF_UP);
                condition.Base_Quantity_Nego__c = baseQtyNego;
            }
        }
        // calculate Base_TO_Nego__c
        if (parentCondition.Respects_Contract_Scope__c) {
            condition.Base_TO_Nego__c = totalTO;
            condition.Base_Quantity_Nego__c = totalQty;
        }
        condition.Value_amt__c = amount;
        condition.Disc_BDate_Y1__c = newContract.Contract_BDate__c;
        condition.Disc_EDate_Y1__c = newContract.Contract_EDate__c;
        condition.Product_Scope__c = parentCondition.Product_Scope__c == null ? nsId : parentCondition.Product_Scope__c;
        condition.BusinessUnitScope__c = parentCondition.BusinessUnitScope__c == null ? referenceContract.Supplier__r.BusinessUnitOrigin__c : parentCondition.BusinessUnitScope__c;
        condition.Contract__c = null;
        // check exisiting valid PE mapping for condition type
        if (isDuplicatePE && conditionDefinition != null && conditionDefinition.Id != null) {
            condition.Condition_Type__c = conditionDefinition.Id;
            condition.Nego_Discount_Type__c = conditionDefinition.Nego_Discount_Type__c;
            condition.Condition_Type__r = conditionDefinition;
        }
        // Force not atteined slab conditions to have first percent and amount values of slabs by default
        if (conditionDefinition != null && conditionDefinition.Is_Conditional__c
            && (parentCondition.slab_target__c == null || parentCondition.slab_target__c == 0))
        {
            condition.slab_target__c = 1;
            condition.Value_per__c = condition.slab_per_1__c;
            condition.Value_amt__c = condition.slab_val_1__c;
        }
        condition.Value_per_Y1__c = condition.Value_per__c;
        condition.Value_amt__c = condition.Value_amt__c == 0 ? null : condition.Value_amt__c;
        condition.Value_amt_Y1__c = condition.Value_amt__c;
        condition.TargetToMove_Condition__c = null;
        condition.Proof_counterparty_description__c = null;
        // if (sBusinessType == 'CPG' && condition.Id == null) { condition.Rank__c = conditionDefinition?.Rank_Order__c; }
        // W-007048: we concluded that there is no need too add this configuration here as it's handled in getting data
        /*if ((condition.Value_per__c == 0 || condition.Value_per__c == null) && (condition.Value_amt__c == 0 || condition.Value_amt__c == null) && (condition.unit_amount__c == 0 || condition.unit_amount__c == null)) {
            return null;
        }*/
        return condition;
    }
    @AuraEnabled
    public static String populateFields(String DiscountJSON, String tarrifConditionJSON, Boolean onlyInvoiceFields) {
        Contract_Discount__c discount;
        Pol_Com_Condition__c tarrifCondition;
        try {
            discount = (Contract_Discount__c) JSON.deserialize(DiscountJSON, Contract_Discount__c.class);
            tarrifCondition = (	Pol_Com_Condition__c) JSON.deserialize(tarrifConditionJSON, Pol_Com_Condition__c.class);
            // get Global Locations
            Map<String, Id> globalLocationsMap = new Map<String, Id>();
            if (discount.Contract__r.BusinessUnitContract__c != null) {
                for (GlobalLocation__c gl : [SELECT Id, BusinessUnit__c, Functions__c
                                             FROM GlobalLocation__c  
                                             WHERE Status__c = 'Open' 
                                             AND Functions__c INCLUDES ('PaidTo', 'InvoiceBy', 'Administrative')
                                             AND BusinessUnit__c = :discount.Contract__r.BusinessUnitContract__c
                                             ORDER BY BusinessUnit__c, CreatedDate])
                {
                    if (gl.Functions__c.containsIgnoreCase('InvoiceBy')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'InvoiceBy', gl.Id);
                    }
                    if (gl.Functions__c.containsIgnoreCase('Administrative')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'Administrative', gl.Id);
                    }
                    if (gl.Functions__c.containsIgnoreCase('PaidTo')) {
                        globalLocationsMap.put(String.valueOf(gl.BusinessUnit__c) + 'PaidTo', gl.Id);
                    }
                }
            }
            if (onlyInvoiceFields) {
                ContractServices.populateInvoiceFields(discount, tarrifCondition, globalLocationsMap);
            } else {
                ContractServices.populateDiscountFields(discount, tarrifCondition, globalLocationsMap, null);
            }
        } catch(Exception ex) {
            system.debug(ex.getMessage() + ' -- ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage() + ' -- ' + ex.getLineNumber());
        }
        return JSON.serialize(discount);
    }
    // public static String buildDiscountQuery(String whereClause, String orderBy) {
    //     // Actual query
    //     String query = 'SELECT Id, ';
    //     query += ' Name, ';
    //     query += ' CurrencyIsoCode, ';
    //     query += ' RecordTypeId, ';
    //     query += ' Base_Quantity_Nego__c, ';
    //     query += ' Base_TO_Nego__c, ';
    //     query += ' Base_TO_Nego_1__c, ';
    //     query += ' BusinessUnitScope__c, ';
    //     query += ' BusinessUnitScope__r.Name, ';
    //     query += ' commercial_reference__c, ';
    //     query += ' Condition_Type__c, ';
    //     query += ' Condition_Type__r.' + String.join(ContractServices.staticPolComConditionFields, ', Condition_Type__r.') + ', ';
    //     query += ' Condition_Type__r.Duplication_Discount_Mapping__r.Name, ';
    //     query += ' Contract__c, ';
    //     query += ' Contract__r.Name, ';
    //     query += ' Contract__r.RecordType.DeveloperName, ';
    //     query += ' Contract__r.RecordTypeId, ';
    //     query += ' Contract__r.Contract_EDate__c, ';
    //     query += ' Contract__r.Contract_Type__c, ';
    //     query += ' Contract__r.Is_FixCond_Recalc_AfterDateChange__c, ';
    //     query += ' Contract__r.Is_OnTop_Simulation__c, ';
    //     query += ' Contract__r.Is_TotalTo_Recalc_AfterDateChange__c, ';
    //     query += ' Contract__r.Secure_Multiyear__c, ';
    //     query += ' Contract__r.SimulationNumber__c, ';
    //     query += ' Contract__r.Supplier_Nego_Scope__c, ';
    //     query += ' Contract__r.Supplier_Nego_Scope__r.Segmentation_attribut3__c, ';
    //     query += ' Contract__r.Total_TO__c, ';
    //     query += ' Contract__r.Total_Qty__c, ';
    //     query += ' Contract__r.Total_TO_Fact__c, ';
    //     query += ' Contract__r.Total_TO_Tariff_Nego__c, ';
    //     query += ' Disc_BDate__c, ';
    //     query += ' Disc_EDate__c, ';
    //     query += ' Discount_Terms__c, ';
    //     query += ' Discount_terms_Origin__c, ';
    //     query += ' Display_Order__c, ';
    //     query += ' Down_Payment_YE_Coverage__c, ';
    //     query += ' Down_Payment_YE_Value_Reference__c, ';
    //     query += ' financial_reference__c, ';
    //     query += ' First_invoice_date__c, ';
    //     query += ' Fist_Provision_Date__c, ';
    //     query += ' Index__c, ';
    //     query += ' Index_V2__c, ';
    //     query += ' Index_perc__c, ';
    //     query += ' Index_val__c, ';
    //     query += ' Invoice_base__c, ';
    //     query += ' Invoice_period__c, ';
    //     query += ' Invoice_sequence__c, ';
    //     query += ' Is_AggregatedFromMove__c, ';
    //     query += ' Is_Conditional__c, ';
    //     query += ' is_duplicable__c, ';
    //     query += ' Is_Duplicable_PE__c, ';
    //     query += ' Exclusion_to_Nego_Base_Value__c, ';
    //     query += ' Is_Excluded_To_Nego_Base_F__c, ';
    //     query += ' Is_Excluded_To_NegoBase__c, ';
    //     query += ' Is_Tariff_Condition__c, ';
    //     query += ' legal_reference__c, ';
    //     query += ' Nego_Discount_Type__c, ';
    //     query += ' OriginFromMove_amt__c, ';
    //     query += ' OriginFromMove_Condition__c, ';
    //     query += ' OriginFromMove_Condition__r.Name, ';
    //     query += ' OriginFromMove_Condition__r.Duplication_Discount_Mapping__c, ';
    //     query += ' OriginFromMove_Condition__r.Index__c, ';
    //     query += ' OriginFromMove_Condition__r.Is_Contract_Unicity_Requiered__c, ';
    //     query += ' OriginFromMove_Condition__r.Nego_Discount_Type__c, ';
    //     query += ' OriginFromMove_ContractDiscount__c, ';
    //     query += ' OriginFromMove_per__c, ';
    //     query += ' OriginFromMove_U__c, ';
    //     query += ' Parent_Discount__c, ';
    //     query += ' Parent_Discount__r.BusinessUnitScope__c, ';
    //     query += ' Parent_Discount__r.Condition_Type__c, ';
    //     query += ' Parent_Discount__r.Product_Scope__c, ';
    //     query += ' Payment_Condition__c, ';
    //     query += ' Payment_Days__c, ';
    //     query += ' Product_Scope__c, ';
    //     query += ' Product_Scope__r.Name, ';
    //     query += ' Prog_TO_Nego__c, ';
    //     query += ' Proof_counterparty_definition__c, ';
    //     query += ' Proof_counterparty_description__c, ';
    //     query += ' Proof_counterparty_number_total__c, ';
    //     query += ' Provision_base__c, ';
    //     query += ' Provision_period__c, ';
    //     query += ' Provision_Sequence__c, ';
    //     query += ' Provisioning_YE_Coverage__c, ';
    //     query += ' Rank__c, ';
    //     query += ' Reference_condition__c, ';
    //     query += ' Respects_Contract_Scope__c, ';
    //     query += ' slab_1__c, ';
    //     query += ' slab_2__c, ';
    //     query += ' slab_3__c, ';
    //     query += ' slab_4__c, ';
    //     query += ' slab_5__c, ';
    //     query += ' slab_6__c, ';
    //     query += ' slab_7__c, ';
    //     query += ' slab_8__c, ';
    //     query += ' slab_calc_method__c, ';
    //     query += ' Slab_Calc_Method_TO_Origin__c, ';
    //     query += ' slab_per_1__c, ';
    //     query += ' slab_per_2__c, ';
    //     query += ' slab_per_3__c, ';
    //     query += ' slab_per_4__c, ';
    //     query += ' slab_per_5__c, ';
    //     query += ' slab_per_6__c, ';
    //     query += ' slab_per_7__c, ';
    //     query += ' slab_per_8__c, ';
    //     query += ' Slab_Reach_Actual__c, ';
    //     query += ' Slab_Reach_Actual_Qty__c, ';
    //     query += ' Slab_Reach_Actual_QtyInc__c, ';
    //     query += ' Slab_Reach_Actual_SellOut__c, ';
    //     query += ' Slab_Reach_Actual_SellOutInc__c, ';
    //     query += ' Slab_Reach_Actual_TOInc__c, ';
    //     query += ' Slab_Reach_Nego__c, ';
    //     query += ' Slab_Reach_Nego_Qty__c, ';
    //     query += ' Slab_Reach_Nego_QtyInc__c, ';
    //     query += ' Slab_Reach_Nego_SellOut__c, ';
    //     query += ' Slab_Reach_Nego_SellOutInc__c, ';
    //     query += ' Slab_Reach_Nego_TOInc__c, ';
    //     query += ' slab_target__c, ';
    //     query += ' slab_val_1__c, ';
    //     query += ' slab_val_2__c, ';
    //     query += ' slab_val_3__c, ';
    //     query += ' slab_val_4__c, ';
    //     query += ' slab_val_5__c, ';
    //     query += ' slab_val_6__c, ';
    //     query += ' slab_val_7__c, ';
    //     query += ' slab_val_8__c, ';
    //     query += ' Slabs_List__c, ';
    //     query += ' unit_amount__c, ';
    //     query += ' Unit_Amount_Type__c, ';
    //     query += ' Value_amt__c, ';
    //     query += ' Value_amt_disp_M1__c, ';
    //     query += ' Value_amt_disp_M2__c, ';
    //     query += ' Value_amt_disp_M3__c, ';
    //     query += ' Value_amt_disp_M4__c, ';
    //     query += ' Value_amt_disp_M5__c, ';
    //     query += ' Value_amt_disp_M6__c, ';
    //     query += ' Value_amt_disp_M7__c, ';
    //     query += ' Value_amt_disp_M8__c, ';
    //     query += ' Value_amt_disp_M9__c, ';
    //     query += ' Value_amt_disp_M10__c, ';
    //     query += ' Value_amt_disp_M11__c, ';
    //     query += ' Value_amt_disp_M12__c, ';
    //     query += ' Value_amt_disp_M13__c, ';
    //     query += ' Value_amt_Y1__c, ';
    //     query += ' Value_amt_Y2__c, ';
    //     query += ' Value_amt_Y3__c, ';
    //     query += ' Value_amt_Y4__c, ';
    //     query += ' Value_amt_Y5__c, ';
    //     query += ' Value_per__c, ';
    //     query += ' Value_per_Y1__c, ';
    //     query += ' Value_per_Y2__c, ';
    //     query += ' Value_per_Y3__c, ';
    //     query += ' Value_per_Y4__c, ';
    //     query += ' Value_per_Y5__c, ';
    //     query += ' YTD_Nego__c, ';
    //     query += ' YTD_Nego_Computed__c ';
    //     query += ' FROM Contract_Discount__c';
    //     query += ' WHERE Status__c <> \'Deleted\'';
    //     query += ' AND ' + whereClause;
    //     query += ' ' + orderBy;
    //     return query;
    // }
    @AuraEnabled
    public static String saveContractData(String contractDataWrapperJSON) {
        Savepoint sp =  Database.setSavepoint();
        try {
            DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
            System.debug('contractDataWrapperJSON>>>> ' + contractDataWrapperJSON);
            ResultWrapper contractDataWrapper = (ResultWrapper)JSON.deserialize(contractDataWrapperJSON, ResultWrapper.class);
            // contractDataWrapper.contract.SPITM_is_edited__c = false;
            // contractDataWrapper.contract.SPITM_Job_Id__c = null;
            // System.debug('contractDataWrapper>>>> ' + contractDataWrapper);
            List<Contract_Discount__c> upsertList = new List<Contract_Discount__c>();
            List<Contract_Discount__c> deleteList = new List<Contract_Discount__c>();
            Set<Id> passedIds = new Set<Id> ();
            for (Contract_Discount__c item : contractDataWrapper.discounts) {
                Boolean isFilled = false;
                isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Value_amt__c.Name) && item.Value_amt__c != null && item.Value_amt__c != 0;
                System.debug(' item.Value_amt__c >>> ' + item.Value_amt__c);
                System.debug(' isFilled >>> ' + isFilled);
                isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Value_per__c.Name) && item.Value_per__c != null && item.Value_per__c != 0;
                System.debug(' item.Value_per__c >>> ' + item.Value_per__c);
                System.debug(' isFilled >>> ' + isFilled);
                isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name) && item.Unit_Amount_Type__c != null && item.Unit_Amount_Type__c != '' && item.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount__c.Name) && item.Unit_Amount__c != null && item.Unit_Amount__c != 0;
                System.debug(' item.Unit_Amount_Type__c >>> ' + item.Unit_Amount_Type__c);
                System.debug(' isFilled >>> ' + isFilled);
                // isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Rank__c.Name) && item.Rank__c != null && item.Rank__c != 0;
                System.debug('isFilled >>' + isFilled);
                item.Is_Edited__c = false;
                if (isFilled) {
                    if (item.Id == null) {
                        item.Asynchron_Processing__c = true;
                    }
                    if (item.Id == null || !passedIds.contains(item.Id)) {
                        upsertList.add(item);
                    }
                } else if(item.Id != null && !passedIds.contains(item.Id)) {
                    //item.Status__c = 'Deleted';
                    upsertList.add(item);
                    // deleteList.add(item);
                }
                if (item.Id != null) {
                    passedIds.add(item.Id);
                }
            }
            if (!upsertList.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(upsertList, false);
                for (Integer index = 0; index < results.size() && index < upsertList.size(); index++) {
                    Contract_Discount__c item = upsertList[index];
                    Database.UpsertResult result = results[index];
                    if (!result.isSuccess()) {
                        String errorMessage;
                        if (item.Id != null) { errorMessage = item.get('Name') + '(' + item.Id + ') : '; } else { errorMessage = /* String.valueOf(item) */ ''; }
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) { /* errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); */ errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                        System.debug('errorMessage'+ errorMessage);
                        dmlResultWrapper.errors.add(errorMessage);
                        dmlResultWrapper.isSuccess = false;
                    }
                }
            }
            if (!deleteList.isEmpty()) {
                List<Database.DeleteResult> results = Database.delete(deleteList, false);
                for (Integer index = 0; index < results.size() && index < deleteList.size(); index++) {
                    Contract_Discount__c item = deleteList[index];
                    Database.DeleteResult result = results[index];
                    if (!result.isSuccess()) {
                        String errorMessage;
                        if (item.Id != null) { errorMessage = item.get('Name') + '(' + item.Id + ') : '; } else { errorMessage = /* String.valueOf(item) */ ''; }
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) { /* errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); */ errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                        System.debug('errorMessage'+ errorMessage);
                        dmlResultWrapper.errors.add(errorMessage);
                        dmlResultWrapper.isSuccess = false;
                    }
                }
            }
            {
                Database.SaveResult result = Database.update(contractDataWrapper.contract, false);
                if (!result.isSuccess()) {
                    String errorMessage;
                    if (contractDataWrapper.contract.Id != null) { errorMessage = contractDataWrapper.contract.get('Name') + '(' + contractDataWrapper.contract.Id + ') : '; } else { errorMessage = /* String.valueOf(contractDataWrapper.contract) */ ''; }
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs) { /* errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); */ errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                    System.debug('errorMessage'+ errorMessage);
                    dmlResultWrapper.errors.add(errorMessage);
                    dmlResultWrapper.isSuccess = false;
                }
            }
            contractDataWrapper.contract = Database.query(getContractQuery(contractDataWrapper.contract.Id));
            contractDataWrapper.discounts = Database.query(getContractDiscountQuery(contractDataWrapper.contract.Id));
            ContractServices.calculateContractRiseDepRates(contractDataWrapper.contract);
            ContractServices indexServices = new ContractServices(contractDataWrapper.contract, contractDataWrapper.discounts);
            indexServices.calculateContractIndex(true);
            {
                Database.SaveResult result = Database.update(contractDataWrapper.contract, false);
                if (!result.isSuccess()) {
                    String errorMessage;
                    if (contractDataWrapper.contract.Id != null) { errorMessage = contractDataWrapper.contract.get('Name') + '(' + contractDataWrapper.contract.Id + ') : '; } else { errorMessage = /* String.valueOf(contractDataWrapper.contract) */ ''; }
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs) { /* errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); */ errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                    System.debug('errorMessage'+ errorMessage);
                    dmlResultWrapper.errors.add(errorMessage);
                    dmlResultWrapper.isSuccess = false;
                }
            }
            {
                List<Database.SaveResult> results = Database.update(contractDataWrapper.discounts, false);
                for (Integer index = 0; index < results.size() && index < contractDataWrapper.discounts.size(); index++) {
                    Contract_Discount__c item = contractDataWrapper.discounts[index];
                    Database.SaveResult result = results[index];
                    if (!result.isSuccess()) {
                        String errorMessage;
                        if (item.Id != null) { errorMessage = item.get('Name') + '(' + item.Id + ') : ' ; } else { errorMessage = /* String.valueOf(item) */ ''; }
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) { /* errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); */ errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                        System.debug('errorMessage'+ errorMessage);
                        dmlResultWrapper.errors.add(errorMessage);
                        dmlResultWrapper.isSuccess = false;
                    }
                }
            }
            System.debug('dmlResultWrapper>>>> ' + JSON.serialize(dmlResultWrapper));
            return JSON.serialize(dmlResultWrapper);
        } catch(DMLException ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage() + ex.getLineNumber());
        } catch(AuraHandledException ex) {
            Database.rollback(sp);
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw ex;
        } catch(Exception ex) {
            Database.rollback(sp);
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ex.getLineNumber());
        }
    }
    @AuraEnabled
    public static String validatePeriodExtension(Id ptContractId) {
        try {
            DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
            Contract__c ptContract = new Contract__c(Id = ptContractId, Status__c = 'Validated');
            Database.SaveResult result = Database.update(ptContract, false);
            if (!result.isSuccess()) {
                String errorMessage;
                if (ptContract.Id != null) {
                    errorMessage =  '(' + ptContract.Id + ') : ' ;
                } else {
                    errorMessage = /* String.valueOf(ptContract) */ '';
                }
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) { errorMessage += err.getStatusCode() + ' - ' + err.getMessage(); if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) { throw new AuraHandledException(String.valueOf(err.getStatusCode())); } }
                System.debug('errorMessage'+ errorMessage);
                dmlResultWrapper.errors.add(errorMessage);
                dmlResultWrapper.isSuccess = false;
            }
            System.debug('dmlResultWrapper>>>> ' + JSON.serialize(dmlResultWrapper));
            return JSON.serialize(dmlResultWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String fakeSaveContractDiscountData(String contractDiscounts_JSON){
        Savepoint sp =  Database.setSavepoint();
        DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
        List<Contract_Discount__c> upsertList = new List<Contract_Discount__c>();
        List<Contract_Discount__c> deleteList = new List<Contract_Discount__c>();
        for (Contract_Discount__c item : (List<Contract_Discount__c>)JSON.deserialize(contractDiscounts_JSON, List<Contract_Discount__c>.class))
        {
            Boolean isFilled = false;
            isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Value_amt__c.Name) && item.Value_amt__c != null && item.Value_amt__c != 0;
            isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Value_per__c.Name) && item.Value_per__c != null && item.Value_per__c != 0;
            isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount_Type__c.Name) && item.Unit_Amount_Type__c != null && item.Unit_Amount_Type__c != '' && item.isSet(SObjectType.Contract_Discount__c.fields.Unit_Amount__c.Name) && item.Unit_Amount__c != null && item.Unit_Amount__c != 0;
            // isFilled |= item.isSet(SObjectType.Contract_Discount__c.fields.Rank__c.Name) && item.Rank__c != null && item.Rank__c != 0;
            System.debug('isFilled >>' + isFilled);
            Set<Id> passedIds = new Set<Id> ();
            item.Is_Edited__c = true;
            if (isFilled) {
                if (item.Id == null) {
                    item.Asynchron_Processing__c = false;
                }
                if (item.Id == null || !passedIds.contains(item.Id)) {
                    upsertList.add(item);
                }
            } else if(item.Id != null && !passedIds.contains(item.Id)) {
                //item.Status__c = 'Deleted';
                upsertList.add(item);
                // deleteList.add(item);
            }
            if (item.Id != null) {
                passedIds.add(item.Id);
            }
        }
        if (!upsertList.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(upsertList, false);
            for (Integer index = 0; index < results.size() && index < upsertList.size(); index++) {
                Contract_Discount__c item = upsertList[index];
                Database.UpsertResult result = results[index];
                if (!result.isSuccess()) {
                    String errorMessage;
                    if (item.Id != null){ errorMessage = item.get('Name') + '(' + item.Id + ') : '; } else { errorMessage = /* String.valueOf(item) */ ''; }
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs){
                        errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage();
                    }
                    System.debug('errorMessage'+ errorMessage);
                    dmlResultWrapper.errors.add(errorMessage);
                    dmlResultWrapper.isSuccess = false;
                }
            }
        }
        if (!deleteList.isEmpty()) {
            List<Database.DeleteResult> results = Database.delete(deleteList, false);
            for (Integer index = 0; index < results.size() && index < deleteList.size(); index++) {
                Contract_Discount__c item = deleteList[index];
                Database.DeleteResult result = results[index];
                if (!result.isSuccess()) {
                    String errorMessage;
                    if (item.Id != null){ errorMessage = item.get('Name') + '(' + item.Id + ') : '; } else{ errorMessage = /* String.valueOf(item) */ ''; }
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs){ errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage(); }
                    System.debug('errorMessage'+ errorMessage);
                    dmlResultWrapper.errors.add(errorMessage);
                    dmlResultWrapper.isSuccess = false;
                }
            }
        }
        Database.rollback(sp);
        System.debug('dmlResultWrapper>>>> ' + JSON.serialize(dmlResultWrapper));
        return JSON.serialize(dmlResultWrapper);
    }
    /**
     * @description check if object is locked
     * @param objId: object Id
     * @return true/false if object is locked or no .
     * */
    private static boolean objectIsLocked(Id objId) {
        boolean isLocked = false;
        isLocked = Approval.isLocked(objId);
        return isLocked;
    }
    public class ResultWrapper {
        String sBusinessType;
        Integer discountPercentScale;
        Contract__c contract;
        List<Contract_Discount__c> discounts;
        String executiveSummaryUrl;
        public String createSimulFromNegoBaseLabel;
        public String createSafeBalanceFromNegoBaseLabel;
        public String createSimulFromSafeBalanceLabel;
        public String createSafeBalanceFromSafeBalanceLabel;
        public String createSimulFromSimulLabel;
        public String createSafeBalanceFromSimulLabel;
        public String createPostNegoSimulFromSignedLabel;
        public String duplicateNegoBasetoPE;
        public String duplicateSafeBalanceToPE;
        public String warningNegoBaseNotValidLabel;
        public String warningNegoBaseNotExistLabel;
        public Boolean isLockedByAprovalProcess;
        public Id userProfileId;
        public Map<Id, Pol_Com_Condition__c> validTariffConditionMap;
        // public ContractIndexMapWrapper wIndex;
        Map<String, String> contractRecordTypeDeveloperNameToLabelMap {get; set;}
        public ResultWrapper(Contract__c contract, List<Contract_Discount__c> discounts) {
            this.validTariffConditionMap = new Map<Id, Pol_Com_Condition__c>();
            this.isLockedByAprovalProcess = false;
            this.contract = contract;
            this.discounts = discounts;
            if (contract != null) {
                // PageReference pageRef = Page.Nego360_ExecutiveSummary;
                PageReference pageRef;
                if (contract.RecordType.DeveloperName != 'Signed') {
                    pageRef = Page.ExecutiveSummary_Simulation;
                } else {
                    pageRef = Page.ExecutiveSummary_Signed;
                }
                pageRef.getParameters().put('id', String.valueOf(contract?.Id));
                this.executiveSummaryUrl = '/one/one.app#/alohaRedirect' + pageRef.getUrl();
            }
            Map<String, String> contractRecordTypeDeveloperNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.SObjectType);
            this.contractRecordTypeDeveloperNameToLabelMap = contractRecordTypeDeveloperNameToLabelMap;
            this.createSimulFromNegoBaseLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            this.createSafeBalanceFromNegoBaseLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            this.createSimulFromSafeBalanceLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance')});
            this.createSafeBalanceFromSafeBalanceLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance'), contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance')});
            this.createSimulFromSimulLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Simulation')});
            this.createSafeBalanceFromSimulLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance'), contractRecordTypeDeveloperNameToLabelMap.get('Simulation')});
            this.createPostNegoSimulFromSignedLabel = String.format(System.Label.LBL_Create_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('PostNego_Simulation'), contractRecordTypeDeveloperNameToLabelMap.get('Signed')});
            this.duplicateNegoBasetoPE = String.format(System.Label.LBL_Duplicate_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Period_Extension'), contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            this.duplicateSafeBalanceToPE = String.format(System.Label.LBL_Duplicate_X_from_Y, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Period_Extension'), contractRecordTypeDeveloperNameToLabelMap.get('Safe_Balance')});
            this.warningNegoBaseNotValidLabel = String.format(System.Label.MSG_Contract_X_Status_Not_Validated, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            this.warningNegoBaseNotExistLabel = String.format(System.Label.MSG_X_not_exists, new List<String>{contractRecordTypeDeveloperNameToLabelMap.get('Nego_Base')});
            this.userProfileId = UserInfo.getProfileId();
        }
    }
    public class DmlResultWrapper{
        public List<String> errors{ get; set; }
        public Boolean isSuccess{ get; set; }
        public DmlResultWrapper() {
            this.errors = new List<String>();
            this.isSuccess = true;
        }
    }
    public class CreateContractWrapper {
        public Id nsId;
        public Integer negoYear;
        public Contract__c refNegoBase;
        public Contract__c contractPE;
        public Contract__c sourceContract;
        public List<Contract_Discount__c> refDiscountsList;
        public String targetContractRTDeveloperName;
        public String contractName;
        public Date beginDate;
        public Date endDate;
        public Integer simulationNumber;
        public Integer postSimulationNumber;
        public Id refContractBUId;
        public Id refContractSourceBUId;
    }
    public class NegoptimSettings {
        Boolean prioritizeSortBDateNegotiateFollowup;
        Boolean prioritizeSortBDateNegotiate;
        String sBusinessType;
        Integer discountPercentScale;
    }
    public static NegoptimSettings loadGlobalSettings() {
        // NegoptimSettings negoptimsettings = new NegoptimSettings();
        // String serializedGlobalSettings = GlobalSettingsManager.loadGlobalSettingsSerialized();
        // System.debug('serializedGlobalSettings = ' + serializedGlobalSettings);
        // Map<String, Object> globalSettingsMap = (Map<String, Object>) JSON.deserializeUntyped(serializedGlobalSettings);
        // negoptimsettings.sBusinessType = (String)globalSettingsMap.get('sBusinessType');
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }

    public class ContractIndexMapWrapper {
        public String key {get; set;}
        public String contractName {get; set;}
        public Decimal baseIndex {get; set;}
        public Decimal riseRate {get; set;}
        public Decimal depresiationRate {get; set;}
        public Decimal totalToTariffNego {get; set;}
        public String progressTarget {get; set;}
        public List<ContractServices.ContractIndexWrapper> values {get; set;}
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
}