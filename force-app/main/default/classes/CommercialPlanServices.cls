/**
 * @author ULiT
 * @date 15/09/2023
 * @description a services class that contains reuasable code related to the negOptim promo module
 * without sharing model to be able to retreive data even if not shared with user
 */
public without sharing class CommercialPlanServices {
    
    /**
     * @description update the field NegoScope__c on CommercialPlanDetail records based on Product__c and Supplier__c
     * the method uses the product and supplier to find NS_PG records , then uses the NS PG records to determine the right
     * negoscope for the CommercialPlanDetail
     * 
     * @param commercialPlanDetails the list of CommercialPlanDetail__c for which the nego scope should be updated
     * @return void
     */
    public static void updateCPDNegoScopeReference(List<CommercialPlanDetail__c> commercialPlanDetails, Map<Id, CommercialPlanDetail__c> oldCommercialDetailsMap) {
        // a set that contains the Ids of the commercial plan details suppliers
        Set<Id> supplierIdSet = new Set<Id>();
        // a set that contains the Ids of the commercial plan details products
        Set<Id> productIdSet = new Set<Id>();
        // a set that contains the Ids of the commercial plan details BU Targets
        Set<Id> buTargetIdSet = new Set<Id>();
        // key = commercialPlanDetail.supplierId + commercialPlanDetail.productId => value = commercialPlanDetail
        Map<String, NSCPDWrapper> commercialPlanDetailsMap = new Map<String, NSCPDWrapper>();

        for (CommercialPlanDetail__c item : commercialPlanDetails) {
            if (item.Product__c != null) {
                productIdSet.add(item.Product__c);
            }
            if (item.BusinessUnitTarget__c != null) {
                buTargetIdSet.add(item.BusinessUnitTarget__c);
            }
        }
        // query products to get the RecordType.DeveloperName & Consumer_Trade_Item__c values
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id, RecordType.DeveloperName, Consumer_Trade_Item__c
                                                            FROM Product2
                                                            WHERE Id IN :productIdSet
                                                            AND RecordType.DeveloperName <> 'Secondary']);
        // clear productIdSet to be able to re-use it later in the code
        productIdSet.clear();
        String key = '';
        NSCPDWrapper NSCPDWrapperItem;
        for (CommercialPlanDetail__c item : commercialPlanDetails) {
            NSCPDWrapperItem = new NSCPDWrapper();
            if (item.Product__c != null) {
                if (item.CommercialPlan__c != null) {
                    Product2 product = products.get(item.Product__c);
                    item.Supplier__c = item.CommercialPlan__r.Supplier__c;
                    key = item.Supplier__c;
                    NSCPDWrapperItem.supplierId = item.Supplier__c;
                    supplierIdSet.add(item.Supplier__c);
                    // the second part of the key should be the product in the nego scope
                    // this statement should be reconsidered as the in the standard Higher_Level_Packaging products could technically 
                    // be included in the nego scope
                    if (product.RecordType.DeveloperName == 'Higher_Level_Packaging' && product.Consumer_Trade_Item__c != null) {
                        productIdSet.add(product.Consumer_Trade_Item__c);
                        key += product.Consumer_Trade_Item__c;
                        NSCPDWrapperItem.productId = product.Consumer_Trade_Item__c;
                    }
                    // Add Logic to get all the RT of NS PG 
                    else {
                        productIdSet.add(product.Id);
                        key += product.Id + '';
                        NSCPDWrapperItem.productId = product.Id;
                    }
                    key += item.BusinessUnitTarget__c + '';
                    NSCPDWrapperItem.buTargetId = item.BusinessUnitTarget__c;
                    // check if the key already exists in the map
                    if (!commercialPlanDetailsMap.containsKey(key)) {
                        commercialPlanDetailsMap.put(key, NSCPDWrapperItem);
                    }
                    commercialPlanDetailsMap.get(key).addCPD(item);
                }
            } else {
                if ((oldCommercialDetailsMap == null && item.NegoScope__c != null)
                    || (oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(item.Id) && item.NegoScope__c != oldCommercialDetailsMap.get(item.Id).NegoScope__c))
                {
                    item.addError(System.Label.MSG_Attached_NS_to_CPD_Wrong);
                } else if (oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(item.Id) && item.Product__c != oldCommercialDetailsMap.get(item.Id).Product__c &&  item.NegoScope__c == oldCommercialDetailsMap.get(item.Id).NegoScope__c) {
                    item.NegoScope__c = null;
                }
            }
        }
        Map<String, Id> nsPgsMap = new Map<String, Id>();
        // get NSPG__c based on the collected supplier Ids and product Ids
        List<NSPG__c> nsPgs = [SELECT Id, NegoScope__c, PG__c,
                               PG__r.Supplier__c, PG__r.Product__c, NegoScope__r.BusinessUnit__c
                               FROM NSPG__c
                               WHERE PG__r.Supplier__c IN :supplierIdSet
                               AND PG__r.Product__c IN :productIdSet
                               AND (NegoScope__r.BusinessUnit__c IN :buTargetIdSet OR NegoScope__r.BusinessUnit__c = NULL)
                               AND Status__c = 'Open'
                               AND NegoScope__r.RecordType.DeveloperName IN ('NSProject', 'Regular')
                               AND NegoScope__r.Status__c = 'Active'
                               ORDER BY NegoScope__r.StatusBDate__c ASC];
        for (NSPG__c nsPg : nsPgs) {
            // reconstruct the key using NSPG__c data
            key = nsPg.PG__r.Supplier__c + '' + nsPg.PG__r.Product__c + '' + (nsPg.NegoScope__r.BusinessUnit__c != null ? nsPg.NegoScope__r.BusinessUnit__c+'' : '');
            nsPgsMap.put(key, nsPg.NegoScope__c);
           
        }

        String keyWithBU = '';
        String keyWithoutBU = '';
        Id negoscopeId = null;
        // loop through the commercialPlanDetailsMap to update the NegoScope__c field
        for (NSCPDWrapper NSCPDWItem : commercialPlanDetailsMap.values()) {

            keyWithBU = NSCPDWItem.supplierId + '' + NSCPDWItem.productId + '' + NSCPDWItem.buTargetId;
            keyWithoutBU = NSCPDWItem.supplierId + '' + NSCPDWItem.productId;

            List<CommercialPlanDetail__c> commercialPlanDetailsList = NSCPDWItem.cpdList;

            negoscopeId = nsPgsMap.containsKey(keyWithBU) ? nsPgsMap.get(keyWithBU) : nsPgsMap.containsKey(keyWithoutBU) ? nsPgsMap.get(keyWithoutBU) : null;
            for (CommercialPlanDetail__c item : commercialPlanDetailsList) {
                if ((oldCommercialDetailsMap == null && item.NegoScope__c != null && item.NegoScope__c != negoscopeId)
                        || (oldCommercialDetailsMap != null && oldCommercialDetailsMap.containsKey(item.Id) && item.NegoScope__c != oldCommercialDetailsMap.get(item.Id).NegoScope__c && item.NegoScope__c != negoscopeId))
                {
                    item.addError(System.Label.MSG_Attached_NS_to_CPD_Wrong);
                } else {
                    item.NegoScope__c = negoscopeId;
                }
            }
        }
    }
    
    /**
     * @description update the fields Contract__c and Contract_Discount1__c on CommercialPlanDetail records based on the year of SellInBDate__c,
     * NegoScope__c, and BusinessUnitTarget__c of the commercial paln detail
     * the method will surch for PE, To Be Signed or Signed contracts to link to the commercial plan detail
     * and find in those contract the Contract Discount with Condition_Type__r.SetCommercialPlanDetail1__c = TRUE
     * 
     * @param commercialPlanDetails the list of CommercialPlanDetail__c for which the contract and contract discount should be updated
     * @return void
	*/
    public static void updateCPDContractReference(List<CommercialPlanDetail__c> commercialPlanDetails) {
        // a set of commercial plan detail nego scope ids
        Set<Id> negoScopeIdSet = new Set<Id>();
        // a set of commercial plan detail target business unit ids
        Set<Id> cpdBUTargetIdSet = new Set<Id>();
        // a set of integers containing the year of the commercial plan details
        Set<Integer> currentYearSet = new Set<Integer>();
        // a set of integers containing the (year - 1) of the commercial plan details
        Set<Integer> previsousYearSet = new Set<Integer>();
        // Map of negoscope => (map of BU => List of contracts of the same year as the promo)
        Map<Id, Map<Id, List<Contract__c>>> currentYearContractsMap = new Map<Id, Map<Id, List<Contract__c>>>();
        // Map of negoscope => (map of BU => List of contracts of the previous year to year of the promo)
        Map<Id, Map<Id, List<Contract__c>>> previousYearContractsMap = new Map<Id, Map<Id, List<Contract__c>>>();
        // SA CHANGES
        Map<Integer, Map<String, List<Contract__c>>> yearsContractsMap = new Map<Integer, Map<String, List<Contract__c>>>();

        for (CommercialPlanDetail__c item : commercialPlanDetails) {
            // check if commercial plan detail with .....
            if (item.NegoScope__c != null && item.SellInBDate__c != null) {
                negoScopeIdSet.add(item.NegoScope__c);
                currentYearSet.add((Integer) item.SellInBDate__c.year());
                previsousYearSet.add((Integer) item.SellInBDate__c.year() - 1);
            }
            if (item.BusinessUnitTarget__c != null) {
                cpdBUTargetIdSet.add(item.BusinessUnitTarget__c);
            }
        }
        // Get all contract related to Nego Scope
        if(!negoScopeIdSet.isEmpty()) {
            List<Contract__c> contractsList = [SELECT Id, Supplier_Nego_Scope__c, BusinessUnitContract__c,
                                               Reference_Year__c, Contract_BDate__c, Contract_EDate__c,
                                               (SELECT Id
                                                FROM Contract_Discounts__r
                                                WHERE Condition_Type__r.SetCommercialPlanDetail1__c = TRUE
                                                AND Status__c <> 'Deleted'
                                                LIMIT 1)
                                               FROM Contract__c
                                               WHERE Supplier_Nego_Scope__c IN :negoScopeIdSet
                                               AND (Reference_Year__c IN :currentYearSet OR Reference_Year__c IN :previsousYearSet)
                                               AND Contract_Type__c = 'Contract'
                                               AND RecordType.DeveloperName IN ('Period_Extension', 'To_Be_Signed', 'Signed')
                                               AND Status__c NOT IN ('Closed', 'Deleted')
                                               ORDER BY Contract_EDate__c DESC];

            
            for (Contract__c item : contractsList) {
                String key = item.Supplier_Nego_Scope__c + '' + item.BusinessUnitContract__c;
                if (!yearsContractsMap.containsKey((Integer) item.Reference_Year__c)) {
                    yearsContractsMap.put((Integer) item.Reference_Year__c, new Map<String, List<Contract__c>>());
                }
                if (!yearsContractsMap.get((Integer) item.Reference_Year__c).containsKey(key)) {
                    yearsContractsMap.get((Integer) item.Reference_Year__c).put(key, new List<Contract__c>());
                }
                yearsContractsMap.get((Integer) item.Reference_Year__c).get(key).add(item);
            }
        }
        //
        Map<Id, Id> entityListToEntityMap = new Map<Id, Id>();
        if (!cpdBUTargetIdSet.isEmpty()) {
            List<BULink__c> buListDetails = [SELECT Id, BusinessUnitMaster__c, BusinessUnitDetail__c
                                                         FROM BULink__c
                                                         WHERE BusinessUnitDetail__c IN :cpdBUTargetIdSet
                                                         AND BusinessUnitMaster__r.SetAgreementBUTarget__c = TRUE];
            for (BULink__c item : buListDetails) {
                if (!entityListToEntityMap.containsKey(item.BusinessUnitDetail__c)) {
                    entityListToEntityMap.put(item.BusinessUnitDetail__c, item.BusinessUnitMaster__c);
                }
            }
        }
        for (CommercialPlanDetail__c item : commercialPlanDetails) {
            if (item.SellInBDate__c != null) {
                List<Contract__c> contracts;
                Integer currentYear = item.SellInBDate__c.year();
                Integer previousYear = item.SellInBDate__c.year();
                String mainKey = item.NegoScope__c + '' + item.BusinessUnitTarget__c;
                String subKey = item.NegoScope__c + '' + entityListToEntityMap.get(item.BusinessUnitTarget__c);
                if (item.NegoScope__c != null) {
                    if (yearsContractsMap.containsKey(currentYear)
                        && (yearsContractsMap.get(currentYear).containsKey(mainKey) || yearsContractsMap.get(currentYear).containsKey(subKey)))
                    {
                        contracts = yearsContractsMap.get(currentYear).containsKey(mainKey) ? yearsContractsMap.get(currentYear).get(mainKey) : yearsContractsMap.get(currentYear).get(subKey);
                    } else if (yearsContractsMap.containsKey(previousYear)
                               && (yearsContractsMap.get(previousYear).containsKey(mainKey) || yearsContractsMap.get(previousYear).containsKey(subKey)))
                    {
                        contracts = yearsContractsMap.get(previousYear).containsKey(mainKey) ? yearsContractsMap.get(previousYear).get(mainKey) : yearsContractsMap.get(previousYear).get(subKey);
                    }
                }
                if (contracts != null) {
                    for (Contract__c contract : contracts) {
                        if (contract.Contract_BDate__c <= item.SellInBDate__c && contract.Contract_EDate__c >= item.SellInBDate__c) {
                            item.Contract__c = contract.Id;
                            if (!contract.Contract_Discounts__r.isEmpty()) {
                                item.Contract_Discount1__c = contract.Contract_Discounts__r[0].Id;
                            }
                            break;
                        }
                    }
                }
            }
        }
    }
    /**
     * @description get KPIs setup
     */ 
    public static KPIResultWrapper getKPISetup() {
        PromoSettings promoSettings = PromoSettings.loadPromoSettings();
        KPIResultWrapper kpiResultWrapper = new KPIResultWrapper();
        if (promoSettings != null ) {
            if (promoSettings.kpiSetups != null && !promoSettings.kpiSetups.isEmpty()) {
                for (PromoSettings.KPISetupWrapper item : promoSettings.kpiSetups) {
                    if (String.isNotBlank(item.CPFBudgetType)) {
                        kpiResultWrapper.CPFBudgetTypeSet.add(item.CPFBudgetType);
                    }
                    if (item.availableCPDBudgetTypes != null && !item.availableCPDBudgetTypes.isEmpty()) {
                        kpiResultWrapper.CPDBudgetTypeSet.addAll(item.availableCPDBudgetTypes);
                    }
                    if (item.availableCPFFields != null && !item.availableCPFFields.isEmpty()) {
                        for (PromoSettings.FieldCPFWrapper fieldCPFWrapper : item.availableCPFFields) {
                            if (String.isNotBlank(fieldCPFWrapper.fieldName)) {
                                kpiResultWrapper.CPFFieldsSUM.add(NegoptimHelper.normalizeAPIName(fieldCPFWrapper.fieldName));
                            }
                            if (!fieldCPFWrapper.isInput && String.isNotBlank(fieldCPFWrapper.fieldName) && String.isNotBlank(fieldCPFWrapper.CPDFieldConso)) {
                                kpiResultWrapper.CPFFieldsConso.add(NegoptimHelper.normalizeAPIName(fieldCPFWrapper.fieldName));
                                kpiResultWrapper.CPDFieldsConso.add(NegoptimHelper.normalizeAPIName(fieldCPFWrapper.CPDFieldConso));
                                if (fieldCPFWrapper.CPDStatus != null && !fieldCPFWrapper.CPDStatus.isEmpty()) {
                                    kpiResultWrapper.CPDStatusList.addAll(new Set<String>(fieldCPFWrapper.CPDStatus));
                                }
                            }
                        }
                    }
                    kpiResultWrapper.kpiSetupMap.put(item.CPFBudgetType, item);
                }
            }
        } else {
            // TODO ERROR
            kpiResultWrapper.errorMessages.add('KPIs set up not found.');
        }
        return kpiResultWrapper;
    }
    
    /**
     * @description 
     * 1- get KPIs setup
     * 2- consolidate CPF fields from available CPD fields in metadata KPI setup
     */ 
    public static List<String> consolidatePromoKPISetup(KPIResultWrapper kpiResultWrapper,
                                                        Map<Id, Map<String, CommercialPlanFollowup__c>> calculatedCPFMap,
                                                        Set<Id> commercialPlanIdSet)
    {
        List<String> errorMessages = new List<String>();
        try {
            if(kpiResultWrapper == null) {
                kpiResultWrapper = getKPISetup();
            }
            if(calculatedCPFMap == null) {
                calculatedCPFMap = new Map<Id, Map<String, CommercialPlanFollowup__c>>();
            }
            if(commercialPlanIdSet == null) {
                commercialPlanIdSet = new Set<Id>();
            }
            if (!commercialPlanIdSet.isEmpty() && !kpiResultWrapper.CPFFieldsConso.isEmpty() && !kpiResultWrapper.CPDFieldsConso.isEmpty() && !kpiResultWrapper.CPFBudgetTypeSet.isEmpty() && !kpiResultWrapper.CPDBudgetTypeSet.isEmpty()) {
                List<String> sumAggregations = new List<String>();
                for (String field : kpiResultWrapper.CPDFieldsConso) {
                    String field_escaped = String.escapeSingleQuotes(field);
                    sumAggregations.add('SUM(' + field_escaped + ') ' + field_escaped);
                }
                String CPDAggregateQuery = 'SELECT CommercialPlan__c CommercialPlan__c, BudgetType__c BudgetType__c, Status__c Status__c';
                CPDAggregateQuery += ',' + String.join(sumAggregations, ',');
                CPDAggregateQuery += ' FROM CommercialPlanDetail__c';
                CPDAggregateQuery += ' WHERE CommercialPlan__c IN (\'' + String.join(new List<Id>(commercialPlanIdSet), '\',\'') +'\')';
                CPDAggregateQuery += ' AND BudgetType__c IN (\'' + String.join(new List<String>(kpiResultWrapper.CPDBudgetTypeSet), '\',\'') +'\')';
                CPDAggregateQuery += ' GROUP BY CommercialPlan__c, BudgetType__c, Status__c';
                CPDAggregateQuery += ' ORDER BY CommercialPlan__c, BudgetType__c';
                Map<String, Map<String, Map<String, Decimal>>> CPDAggregateMap = new Map<String, Map<String, Map<String, Decimal>>>();
                for (AggregateResult item : Database.query(CPDAggregateQuery)) {
                    Id commercialPlanId = (Id) item.get('CommercialPlan__c');
                    String budgetType = String.valueOf(item.get('BudgetType__c'));
                    String CPDStatus = String.valueOf(item.get('Status__c'));
                    String key = commercialPlanId + '' + budgetType;
                    if(!CPDAggregateMap.containsKey(key)) CPDAggregateMap.put(key, new Map<String, Map<String, Decimal>>());
                    if(!CPDAggregateMap.get(key).containsKey(CPDStatus)) CPDAggregateMap.get(key).put(CPDStatus, new Map<String, Decimal>());
                    for (String fieldname : kpiResultWrapper.CPDFieldsConso) {
                        Decimal value = item.get(fieldname) != null ? Decimal.valueOf(String.valueOf((item.get(fieldname)))) : 0;
                        CPDAggregateMap.get(key).get(CPDStatus).put(fieldname, value);
                    }
                }
                String CPFQuery = 'SELECT Id, CommercialPlan__c, CommercialPlan__r.CommercialPlanParent__c, BudgetType__c,';
                CPFQuery += ' ' + String.join(kpiResultWrapper.CPFFieldsConso, ',') + ' FROM CommercialPlanFollowup__c';
                CPFQuery += ' WHERE CommercialPlan__c IN (\'' + String.join(new List<Id>(commercialPlanIdSet), '\',\'') +'\')';
                CPFQuery += ' AND BudgetType__c IN (\'' + String.join(new List<String>(kpiResultWrapper.CPFBudgetTypeSet), '\',\'') +'\')';
                Map<String, Map<String, Decimal>> commercialPlanDetailsMap;
                for (CommercialPlanFollowup__c item : Database.query(CPFQuery)) {
                    PromoSettings.KPISetupWrapper kpiSetupWrapper = kpiResultWrapper.kpiSetupMap.get(item.BudgetType__c);
                    if(!calculatedCPFMap.containsKey(item.CommercialPlan__c)) calculatedCPFMap.put(item.CommercialPlan__c, new Map<String, CommercialPlanFollowup__c>());
                    if(!calculatedCPFMap.get(item.CommercialPlan__c).containsKey(item.BudgetType__c)) {
                        calculatedCPFMap.get(item.CommercialPlan__c).put(item.BudgetType__c, item);
                        for(String fieldName : kpiResultWrapper.CPFFieldsConso) {
                            item.put(fieldName, null);
                        }
                    }
                    commercialPlanDetailsMap = new Map<String, Map<String, Decimal>>();
                    if(kpiSetupWrapper.availableCPDBudgetTypes != null && !kpiSetupWrapper.availableCPDBudgetTypes.isEmpty()) {
                        for(String CPDBudgetType : kpiSetupWrapper.availableCPDBudgetTypes) {
                            String key = item.CommercialPlan__c + '' + CPDBudgetType;
                            if(CPDAggregateMap.containskey(key)) {
                                Map<String, Map<String, Decimal>> CPDStatusMap = CPDAggregateMap.get(key);
                                for(String CPDStatus : CPDStatusMap.keySet()) {
                                    if(!commercialPlanDetailsMap.containsKey(CPDStatus)) commercialPlanDetailsMap.put(CPDStatus, new Map<String, Decimal>());
                                    for(String fieldName : CPDStatusMap.get(CPDStatus).keySet()) {
                                        Decimal value = commercialPlanDetailsMap.get(CPDStatus).containsKey(fieldName) ? commercialPlanDetailsMap.get(CPDStatus).get(fieldName) : null;
                                        Decimal newValue = CPDStatusMap.get(CPDStatus).get(fieldName) != null ? (Decimal)CPDStatusMap.get(CPDStatus).get(fieldName) : null;
                                        value = (value == null ? newValue : (newValue != null ? (value + newValue) : value));
                                        commercialPlanDetailsMap.get(CPDStatus).put(fieldName, value);
                                    }
                                }
                            }
                        }
                    }
                    if(kpiSetupWrapper.availableCPFFields != null && !kpiSetupWrapper.availableCPFFields.isEmpty()) {
                        for(PromoSettings.FieldCPFWrapper fieldCPFWrapper : kpiSetupWrapper.availableCPFFields) {
                            String CPFFieldName = String.isNotBlank(fieldCPFWrapper.fieldName) ? NegoptimHelper.normalizeAPIName(fieldCPFWrapper.fieldName) : null;
                            String CPDFieldConso = String.isNotBlank(fieldCPFWrapper.CPDFieldConso) ? NegoptimHelper.normalizeAPIName(fieldCPFWrapper.CPDFieldConso) : null;
                            for(String CPDStatus : commercialPlanDetailsMap.keySet()) {
                                Boolean isValidStatus = ((fieldCPFWrapper.CPDStatus != null && !fieldCPFWrapper.CPDStatus.isEmpty() && fieldCPFWrapper.CPDStatus.contains(CPDStatus))
                                                         || fieldCPFWrapper.CPDStatus == null
                                                         || fieldCPFWrapper.CPDStatus.isEmpty());
                                if(!fieldCPFWrapper.isInput && isValidStatus && String.isNotBlank(CPFFieldName) && String.isNotBlank(CPDFieldConso)) {
                                    Decimal value = item.get(CPFFieldName) != null ? (Decimal)item.get(CPFFieldName) : null;
                                    if(commercialPlanDetailsMap.get(CPDStatus).get(CPDFieldConso) != null) {
                                        Decimal CPDSumValue = commercialPlanDetailsMap.get(CPDStatus).get(CPDFieldConso);
                                        value = (value == null ? CPDSumValue : (CPDSumValue != null ? (value + CPDSumValue) : value));
                                    }
                                    item.put(CPFFieldName, value);
                                    calculatedCPFMap.get(item.CommercialPlan__c).put(item.BudgetType__c, item);
                                }
                            }
                        }
                    }
                }
            }
        } catch (DMLException ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getLineNumber());
            errorMessages.add(ex.getMessage());
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getLineNumber());
            errorMessages.add(ex.getMessage());
        }
        return errorMessages;
    }
    /**
     * @description cosolidate CPF for parent CommercialPlan
     */ 
    public static List<CommercialPlanFollowup__c> consolidateParentCPF(KPIResultWrapper kpiResultWrapper, Set<Id> parentCommercialPlanIdSet) {
        Map<String, Map<String, Decimal>> parentCommercialPlanMap = new Map<String, Map<String, Decimal>>();
        if(kpiResultWrapper == null) {
            kpiResultWrapper = getKPISetup();
        }
        List<CommercialPlanFollowup__c> CPFToUpsert = new List<CommercialPlanFollowup__c>();
        if (!parentCommercialPlanIdSet.isEmpty() && !kpiResultWrapper.CPFBudgetTypeSet.isEmpty() && !kpiResultWrapper.CPFFieldsSUM.isEmpty()) {
            List<String> sumAggregations = new List<String>();
            for (String field : kpiResultWrapper.CPFFieldsSUM) {
                String field_escaped = String.escapeSingleQuotes(field);
                sumAggregations.add('SUM(' + field_escaped + ') ' + field_escaped);
            }
            String aggregateQuery = 'SELECT CommercialPlan__r.CommercialPlanParent__c CommercialPlanParent__c, BudgetType__c BudgetType__c';
            aggregateQuery += ',' + String.join(sumAggregations, ',');
            aggregateQuery += ' FROM CommercialPlanFollowup__c';
            aggregateQuery += ' WHERE CommercialPlan__r.CommercialPlanParent__c IN (\'' + String.join(new List<Id>(parentCommercialPlanIdSet), '\',\'') +'\')';
            aggregateQuery += ' AND CommercialPlan__r.CommercialPlanParent__c <> NULL';
            aggregateQuery += ' GROUP BY CommercialPlan__r.CommercialPlanParent__c, BudgetType__c';
            for (AggregateResult item : Database.query(aggregateQuery)) {
                Id parentCommercialPlanId = (Id) item.get('CommercialPlanParent__c');
                String budgetType = String.valueOf(item.get('BudgetType__c'));
                String key = parentCommercialPlanId + '' + budgetType;
                if(!parentCommercialPlanMap.containsKey(key)) parentCommercialPlanMap.put(key, new Map<String, Decimal>());
                for (String fieldname : kpiResultWrapper.CPFFieldsSUM) {
                    Decimal value = item.get(fieldname) != null ? Decimal.valueOf(String.valueOf((item.get(fieldname)))) : 0;
                    parentCommercialPlanMap.get(key).put(fieldname, value);
                }
            }
            String CPFQuery = 'SELECT Id, CommercialPlan__c, BudgetType__c,';
            CPFQuery += ' ' + String.join(kpiResultWrapper.CPFFieldsSUM, ',') + ' FROM CommercialPlanFollowup__c';
            CPFQuery += ' WHERE CommercialPlan__c IN (\'' + String.join(new List<Id>(parentCommercialPlanIdSet), '\',\'') +'\')';
            CPFQuery += ' AND BudgetType__c IN (\'' + String.join(new List<String>(kpiResultWrapper.CPFBudgetTypeSet), '\',\'') +'\')';
            Map<String, CommercialPlanFollowup__c> CPFParentMap = new Map<String, CommercialPlanFollowup__c>();
            for (CommercialPlanFollowup__c item : Database.query(CPFQuery)) {
                String key = item.CommercialPlan__c + '' + item.BudgetType__c;
                CPFParentMap.put(key, item);
            }
            CommercialPlanFollowup__c commercialPlanFollowup;
            for(String key : parentCommercialPlanMap.keySet()) {
                if(CPFParentMap.containsKey(key)) {
                    commercialPlanFollowup = CPFParentMap.get(key);
                } else {
                    commercialPlanFollowup = new CommercialPlanFollowup__c();
                }
                for (String fieldname : kpiResultWrapper.CPFFieldsSUM) {
                    commercialPlanFollowup.put(fieldname, parentCommercialPlanMap.get(key).get(fieldname));
                }
                CPFToUpsert.add(commercialPlanFollowup);
            }
        }
        return CPFToUpsert;
    }
    
    /**
     * @description cosolidate Promo Agreement Detail for CommercialPlanSellIn / CommercialPlanSellOut / CommercialPlanServices
     */ 
    public static List<Database.SaveResult> consolidatePromoAgreements(Set<Id> commercialPlanSellInIds, Set<Id> commercialPlanSellOutIds, Set<Id> commercialPlanServicesIds) {
        Map<Id, CommercialPlan__c> CPMapToUpdate = new Map<Id, CommercialPlan__c>();
        if (!commercialPlanSellInIds.isEmpty() || !commercialPlanSellOutIds.isEmpty() || !commercialPlanServicesIds.isEmpty()) {
            String query = 'SELECT CommercialPlanSellIn__c CommercialPlanSellIn__c, CommercialPlanSellOut__c CommercialPlanSellOut__c, CommercialPlanServices__c CommercialPlanServices__c,';
            query += ' SUM(SellInDiscountMassValueTarget__c) SellInDiscountMassValueTarget__c, SUM(SellInDiscountMassValueFact__c) SellInDiscountMassValueFact__c, SUM(SellInDiscountMassValueFact2__c) SellInDiscountMassValueFact2__c,';
            query += ' SUM(SellOutDiscMassValueContribTarget__c) SellOutDiscMassValueContribTarget__c, SUM(SellOutDiscMassValueContribTargetwTax__c) SellOutDiscMassValueContribTargetwTax__c, SUM(SellOutDiscMassValueContribFact__c) SellOutDiscMassValueContribFact__c, SUM(SellOutDiscMassValueContribFactwTax__c) SellOutDiscMassValueContribFactwTax__c,';
            query += ' SUM(ServicesDiscountMassValueTarget__c) ServicesDiscountMassValueTarget__c, SUM(ServicesDiscountMassValueFact__c) ServicesDiscountMassValueFact__c';
            query += ' FROM CommercialPlanDetail__c';
            List<String> conditions = new List<String>();
            if (!commercialPlanSellInIds.isEmpty()) {
                conditions.add('CommercialPlanSellIn__c IN (\'' + String.join(commercialPlanSellInIds, '\', \'') + '\')');
            }
            if (!commercialPlanSellOutIds.isEmpty()) {
                conditions.add('CommercialPlanSellOut__c IN (\'' + String.join(commercialPlanSellOutIds, '\', \'') + '\')');
            }
            if (!commercialPlanServicesIds.isEmpty()) {
                conditions.add('CommercialPlanServices__c IN (\'' + String.join(commercialPlanServicesIds, '\', \'') + '\')');
            }
            query += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' OR ') : '';
            query += ' GROUP BY CommercialPlanSellIn__c, CommercialPlanSellOut__c, CommercialPlanServices__c';
            for (AggregateResult result : Database.query(query)) {
                Id commercialPlanSellInId = result.get('CommercialPlanSellIn__c') != null ? (Id) result.get('CommercialPlanSellIn__c') : null;
                Id commercialPlanSellOutId = result.get('CommercialPlanSellOut__c') != null ? (Id) result.get('CommercialPlanSellOut__c') : null;
                Id commercialPlanServicesId = result.get('CommercialPlanServices__c') != null ? (Id) result.get('CommercialPlanServices__c') : null;
                if (commercialPlanSellInId != null && !commercialPlanSellInIds.isEmpty() && commercialPlanSellInIds.contains(commercialPlanSellInId)) {
                    CommercialPlan__c commercialPlanSellIn;
                    if (!CPMapToUpdate.containsKey(commercialPlanSellInId)) {
                        commercialPlanSellIn = new CommercialPlan__c(Id = commercialPlanSellInId,
                                                                     SellInDiscountMassValueTarget__c = 0,
                                                                     SellInDiscountMassValueFact__c = 0,
                                                                     SellInDiscountMassValueFact2__c = 0);
                        CPMapToUpdate.put(commercialPlanSellInId, commercialPlanSellIn);
                    }
                    commercialPlanSellIn = CPMapToUpdate.get(commercialPlanSellInId);
                    commercialPlanSellIn.SellInDiscountMassValueTarget__c += (Decimal) result.get('SellInDiscountMassValueTarget__c') != null ? (Decimal) result.get('SellInDiscountMassValueTarget__c') : 0;
                    commercialPlanSellIn.SellInDiscountMassValueFact__c += (Decimal) result.get('SellInDiscountMassValueFact__c') != null ? (Decimal) result.get('SellInDiscountMassValueFact__c') : 0;
                    commercialPlanSellIn.SellInDiscountMassValueFact2__c += (Decimal) result.get('SellInDiscountMassValueFact2__c') != null ? (Decimal) result.get('SellInDiscountMassValueFact2__c') : 0;
                }
                if (commercialPlanSellOutId != null && !commercialPlanSellOutIds.isEmpty() && commercialPlanSellOutIds.contains(commercialPlanSellOutId)) {
                    CommercialPlan__c commercialPlanSellOut;
                    if (!CPMapToUpdate.containsKey(commercialPlanSellOutId)) {
                        commercialPlanSellOut = new CommercialPlan__c(Id = commercialPlanSellOutId,
                                                                      SellOutDiscMassValueContribTarget__c = 0,
                                                                      SellOutDiscMassValueContribTargetwTax__c = 0,
                                                                      SellOutDiscMassValueContribFact__c = 0,
                                                                      SellOutDiscMassValueContribFactwTax__c = 0);
                        CPMapToUpdate.put(commercialPlanSellOutId, commercialPlanSellOut);
                    }
                    commercialPlanSellOut = CPMapToUpdate.get(commercialPlanSellOutId);
                    commercialPlanSellOut.SellOutDiscMassValueContribTarget__c += (Decimal) result.get('SellOutDiscMassValueContribTarget__c') != null ? (Decimal) result.get('SellOutDiscMassValueContribTarget__c') : 0;
                    commercialPlanSellOut.SellOutDiscMassValueContribTargetwTax__c += (Decimal) result.get('SellOutDiscMassValueContribTargetwTax__c') != null ? (Decimal) result.get('SellOutDiscMassValueContribTargetwTax__c') : 0;
                    commercialPlanSellOut.SellOutDiscMassValueContribFact__c += (Decimal) result.get('SellOutDiscMassValueContribFact__c') != null ? (Decimal) result.get('SellOutDiscMassValueContribFact__c') : 0;
                    commercialPlanSellOut.SellOutDiscMassValueContribFactwTax__c += (Decimal) result.get('SellOutDiscMassValueContribFactwTax__c') != null ? (Decimal) result.get('SellOutDiscMassValueContribFactwTax__c') : 0;
                }
                if (commercialPlanServicesId != null && !commercialPlanServicesIds.isEmpty() && commercialPlanServicesIds.contains(commercialPlanServicesId)) {
                    CommercialPlan__c commercialPlanServices;
                    if (!CPMapToUpdate.containsKey(commercialPlanServicesId)) {
                        commercialPlanServices = new CommercialPlan__c(Id = commercialPlanServicesId,
                                                                       ServicesDiscountMassValueTarget__c = 0,
                                                                       ServicesDiscountMassValueFact__c = 0);
                        CPMapToUpdate.put(commercialPlanServicesId, commercialPlanServices);
                    }
                    commercialPlanServices = CPMapToUpdate.get(commercialPlanServicesId);
                    commercialPlanServices.ServicesDiscountMassValueTarget__c += (Decimal) result.get('ServicesDiscountMassValueTarget__c') != null ? (Decimal) result.get('ServicesDiscountMassValueTarget__c') : 0;
                    commercialPlanServices.ServicesDiscountMassValueFact__c += (Decimal) result.get('ServicesDiscountMassValueFact__c') != null ? (Decimal) result.get('ServicesDiscountMassValueFact__c') : 0;
                }
            }
            if (!CPMapToUpdate.isEmpty()) {
                return Database.update(CPMapToUpdate.values(), false);
            }
        }
        return null;
    }
    
    public class KPIResultWrapper {
        public Map<String, PromoSettings.KPISetupWrapper> kpiSetupMap {get; set;}
        public Set<String> CPFBudgetTypeSet {get; set;}
        public Set<String> CPDBudgetTypeSet {get; set;}
        public Set<String> CPFFieldsConso {get; set;}
        public Set<String> CPFFieldsSUM {get; set;}
        public Set<String> CPDFieldsConso {get; set;}
        public Set<String> CPDStatusList {get; set;}
        public Set<String> errorMessages {get; set;}
        public KPIResultWrapper() {
            this.kpiSetupMap = new Map<String, PromoSettings.KPISetupWrapper>();
            this.CPFBudgetTypeSet = new Set<String>();
            this.CPDBudgetTypeSet = new Set<String>();
            this.CPFFieldsConso = new Set<String>();
            this.CPFFieldsSUM = new Set<String>();
            this.CPDFieldsConso = new Set<String>();
            this.CPDStatusList = new Set<String>();
            this.errorMessages = new Set<String>();
        }
    }

    public class NSCPDWrapper {
        public Id supplierId {get; set;}
        public Id productId {get; set;}
        public Id buTargetId {get; set;}

        public List<CommercialPlanDetail__c> cpdList {get; set;}
        
        public NSCPDWrapper() {
            this.cpdList = new List<CommercialPlanDetail__c>();
        }

        public void addCPD(CommercialPlanDetail__c cpd) {
            if (cpd != null) {
                this.cpdList.add(cpd);
            }
        }
    }
}