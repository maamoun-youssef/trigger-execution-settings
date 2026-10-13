/**
 * @author ULiT
 * @date 21/01/2025
 * @description Scan ProductDiscountStatementDetail__c
 * */
public with sharing class PDSDScanBatch implements Database.Batchable<SObject>, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    public Id batchId;
    public Boolean forceScan;
    private Map<String, Id> productDiscountStatementRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(ProductDiscountStatementDetail__c.SObjectType);
    
    // Empty COnstructor for the newInstance
    public PDSDScanBatch() {}
    
    public PDSDScanBatch(String startedFrom, Set<Id> productDiscountStatementIdSet, Set<Id> productDiscountStatementDetailsIdSet, Set<Id> contractIdSet, Id batchId, Boolean forceScan) {
        nb = new NegoptimBatch(PDSDScanBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.batchId = batchId;
        this.forceScan = forceScan == null ? false : forceScan;
        this.query = 'SELECT Id, ProductDiscountStatement__c, ProductDiscountStatement__r.BDate__c, ProductDiscountStatement__r.EDate__c, ProductDiscountStatement__r.RecordType.DeveloperName,';
        this.query += ' Supplier__c, ProductDiscountStatement__r.Supplier__c, ProductDiscountStatement__r.NegoScope__c, ProductDiscountStatement__r.NegoScope__r.Supplier__c,';
        this.query += ' BDate__c, EDate__c, DeclarantComment__c, ProductQtyMax__c, ProductQtyMin__c, ProductQty__c, GrossPrice__c, GrossPricePrevious__c,';
        this.query += ' ProductDiscountStatement__r.PromoStatementType__c, ProductDiscountStatement__r.PromoAgreementType__c, CurrencyIsoCode,';
        this.query += ' SellOutDiscountFixedAmt__c, SellOutDiscountUAmt__c, ServicesDiscountFixedAmt__c, ServicesDiscountUAmt__c, UAmt__c, FixedAmt__c,';
        this.query += ' Perc__c, SellOutDiscountPerc__c,';
        this.query += ' input_PRDGTIN__c, input_PRDCode__c, input_PRDName__c, input_PCCCode__c, input_PCCSellOutCode__c, input_PCCServicesCode__c,';
        this.query += ' SellOutBDate__c, SellOutEDate__c, GrossPricePromo__c, input_BUCode__c, input_BUName__c, input_CPCode__c,';
        this.query += ' PG__c, Contract__c, NegoScope__c, NegoScope__r.Supplier__c, input_SUPCode__c, input_NSCode__c, ReferenceYear__c,';
        this.query += ' ScanStatus__c, ScanLDate__c, ScanResults__c,';
        this.query += ' Contract_Discount__c, Contract_Discount__r.Contract__c, Contract_Discount__r.Condition_Type__c, Contract_Discount__r.Status__c,';
        this.query += ' Contract_Discount__r.Condition_Type__r.PromoStatementType__c, Contract_Discount__r.Condition_Type__r.PromoAgreementType__c,';
        this.query += ' Contract_Discount__r.Condition_Type__r.Capture_Discount_Product_Level__c, Contract_Discount__r.Condition_Type__r.SetCommercialPlanDetail1__c,';
        this.query += ' Contract_DiscountSellOut__c, Contract_DiscountSellOut__r.Contract__c, Contract_DiscountSellOut__r.Status__c, Contract_DiscountSellOut__r.Condition_Type__r.PromoStatementType__c, Contract_DiscountSellOut__r.Condition_Type__r.PromoAgreementType__c,';
        this.query += ' Contract_DiscountSellOut__r.Condition_Type__r.Capture_Discount_Product_Level__c, Contract_DiscountSellOut__r.Condition_Type__r.SetCommercialPlanDetail1__c,';
        this.query += ' Contract_DiscountServices__c, Contract_DiscountServices__r.Contract__c, Contract_DiscountServices__r.Status__c, Contract_DiscountServices__r.Condition_Type__r.PromoStatementType__c, Contract_DiscountServices__r.Condition_Type__r.PromoAgreementType__c,';
        this.query += ' Contract_DiscountServices__r.Condition_Type__r.Capture_Discount_Product_Level__c, Contract_DiscountServices__r.Condition_Type__r.SetCommercialPlanDetail1__c';
        this.query += ' FROM ProductDiscountStatementDetail__c WHERE ProductDiscountStatement__c <> NULL';
        if (this.forceScan) {
            this.query += ' AND t_SetForceScan__c = TRUE';
        } else {
            if (productDiscountStatementIdSet != null && !productDiscountStatementIdSet.isEmpty()) {
                this.query += ' AND ProductDiscountStatement__c IN (\'' + String.join(new List<Id>(productDiscountStatementIdSet), '\', \'') + '\')';
            }
            if (productDiscountStatementDetailsIdSet != null && !productDiscountStatementDetailsIdSet.isEmpty()) {
                this.query += ' AND Id IN (\'' + String.join(new List<Id>(productDiscountStatementDetailsIdSet), '\', \'') + '\')';
            }
            if (contractIdSet != null && !contractIdSet.isEmpty()) {
                this.query += ' AND Contract__c IN (\'' + String.join(new List<Id>(contractIdSet), '\', \'') + '\')';
            }
        }
        nb.logParameter('productDiscountStatementIdSet', productDiscountStatementIdSet);
        nb.logParameter('productDiscountStatementDetailsIdSet', productDiscountStatementDetailsIdSet);
        nb.logParameter('contractIdSet', contractIdSet);
        nb.logParameter('forceScan', this.forceScan);
        nb.logParameter('query', this.query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ProductDiscountStatementDetail__c> scope) {
        Map<Id, Map<String, String>> scanResultsMap = new Map<Id, Map<String, String>>();
        Map<Id, Set<String>> errorMessages = new Map<Id, Set<String>>();
        Map<Id, Set<String>> warningMessages = new Map<Id, Set<String>>();
        Set<String> productEANSet = new Set<String>();
        Set<String> productCodeSet = new Set<String>();
        Set<String> productNameSet = new Set<String>();
        Set<String> supplierCodeSet = new Set<String>();
        Set<String> nsCodeSet = new Set<String>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<String> polComConditionCodeSet = new Set<String>();
        Set<String> BUCodeSet = new Set<String>();
        Set<String> BUNameSet = new Set<String>();
        Set<String> commercialPlanCodeSet = new Set<String>();
        Date minDate, maxDate;
        for (ProductDiscountStatementDetail__c item : scope) {
            scanResultsMap.put(item.Id, new Map<String, String>());
            // Conditions for all RT
            if (item.BDate__c == null || item.BDate__c >= item.ProductDiscountStatement__r.EDate__c || item.BDate__c < item.ProductDiscountStatement__r.BDate__c) {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_01}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.BDate__c.Name}, 'Error');
            }
            if (item.BDate__c != null) {
                minDate = minDate == null ? item.BDate__c : (minDate > item.BDate__c ? item.BDate__c : minDate);
            }
            if (item.EDate__c == null || item.EDate__c < item.BDate__c || item.EDate__c > item.ProductDiscountStatement__r.EDate__c) {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_02}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.EDate__c.Name}, 'Error');
            }
            if (item.EDate__c != null) {
                maxDate = maxDate == null ? item.EDate__c : (maxDate < item.EDate__c ? item.EDate__c : maxDate);
            }
            if (String.isNotBlank(item.input_SUPCode__c)) {
                supplierCodeSet.add(item.input_SUPCode__c);
            }
            if (String.isNotBlank(item.input_NSCode__c)) {
                nsCodeSet.add(item.input_NSCode__c);
            }
            if (String.isBlank(item.CurrencyIsoCode)) {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_28}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.CurrencyIsoCode .Name}, 'Error');
            }
            if (item.Contract_Discount__c != null && String.isBlank(item.input_PCCCode__c) && item.Contract_Discount__r.Condition_Type__c != null) {
                if (item.Contract_Discount__r.Contract__c == item.Contract__c
                    && item.Contract_Discount__r.Status__c != 'Deleted'
                    && item.Contract_Discount__r.Condition_Type__r.PromoStatementType__c == 'SellIn'
                    && item.ProductDiscountStatement__r.PromoStatementType__c.contains(item.Contract_Discount__r.Condition_Type__r.PromoStatementType__c)
                    && item.Contract_Discount__r.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c
                    && item.Contract_Discount__r.Condition_Type__r.Capture_Discount_Product_Level__c != null
                    && item.Contract_Discount__r.Condition_Type__r.SetCommercialPlanDetail1__c)
                {
                    item.Pol_Com_Condition__c = item.Contract_Discount__r.Condition_Type__c;
                } else {
                    item.Pol_Com_Condition__c = null;
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_16}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Error');
                }
            }
            if (item.Contract_DiscountSellOut__c != null && String.isBlank(item.input_PCCSellOutCode__c) && item.Contract_DiscountSellOut__r.Condition_Type__c != null) {
                if (item.Contract_DiscountSellOut__r.Contract__c == item.Contract__c
                    && item.Contract_DiscountSellOut__r.Status__c != 'Deleted'
                    && item.Contract_DiscountSellOut__r.Condition_Type__r.PromoStatementType__c == 'SellOut'
                    && item.ProductDiscountStatement__r.PromoStatementType__c.contains(item.Contract_DiscountSellOut__r.Condition_Type__r.PromoStatementType__c)
                    && item.Contract_DiscountSellOut__r.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c
                    && item.Contract_DiscountSellOut__r.Condition_Type__r.Capture_Discount_Product_Level__c != null
                    && item.Contract_DiscountSellOut__r.Condition_Type__r.SetCommercialPlanDetail1__c)
                {
                    item.Pol_Com_ConditionSellOut__c = item.Contract_DiscountSellOut__r.Condition_Type__c;
                } else {
                    item.Pol_Com_ConditionSellOut__c = null;
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_17}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_DiscountSellOut__c.Name}, 'Error');
                }
            }
            if (item.Contract_DiscountServices__c != null && String.isBlank(item.input_PCCServicesCode__c) && item.Contract_DiscountServices__r.Condition_Type__c != null) {
                if (item.Contract_DiscountServices__r.Contract__c == item.Contract__c
                    && item.Contract_DiscountServices__r.Status__c != 'Deleted'
                    && item.Contract_DiscountServices__r.Condition_Type__r.PromoStatementType__c == 'Services'
                    && item.ProductDiscountStatement__r.PromoStatementType__c.contains(item.Contract_DiscountServices__r.Condition_Type__r.PromoStatementType__c)
                    && item.Contract_DiscountServices__r.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c
                    && item.Contract_DiscountServices__r.Condition_Type__r.Capture_Discount_Product_Level__c != null
                    && item.Contract_DiscountServices__r.Condition_Type__r.SetCommercialPlanDetail1__c)
                {
                    item.Pol_Com_ConditionServices__c = item.Contract_DiscountServices__r.Condition_Type__c;
                } else {
                    item.Pol_Com_ConditionServices__c = null;
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_18}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_DiscountServices__c.Name}, 'Error');
                }
            }
            if ((item.SellOutDiscountFixedAmt__c != null && item.SellOutDiscountFixedAmt__c < 0)
                || (item.SellOutDiscountUAmt__c != null && item.SellOutDiscountUAmt__c < 0)
                || (item.ServicesDiscountFixedAmt__c != null && item.ServicesDiscountFixedAmt__c < 0)
                || (item.ServicesDiscountUAmt__c != null && item.ServicesDiscountUAmt__c < 0)
                || (item.UAmt__c != null && item.UAmt__c < 0)
                || (item.FixedAmt__c != null && item.FixedAmt__c < 0))
            {
                List<String> fields = new List<String> {
                    SObjectType.ProductDiscountStatementDetail__c.fields.SellOutDiscountFixedAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.SellOutDiscountUAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.ServicesDiscountFixedAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.ServicesDiscountUAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.UAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.FixedAmt__c.Name
                };
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_30}', scanResultsMap, fields, 'Error');
            }
            if (item.ProductDiscountStatement__r.PromoStatementType__c != null
                && item.ProductDiscountStatement__r.PromoStatementType__c == 'SellIn'
                && (item.UAmt__c == null || item.UAmt__c == 0)
                && (item.FixedAmt__c == null || item.FixedAmt__c == 0)
                && (item.Perc__c == null || item.Perc__c == 0))
            {
                List<String> fields = new List<String> {
                    SObjectType.ProductDiscountStatementDetail__c.fields.Perc__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.UAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.FixedAmt__c.Name
                };
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_03}', scanResultsMap, fields, 'Error');
            }
            if (item.ProductDiscountStatement__r.PromoStatementType__c != null
                && item.ProductDiscountStatement__r.PromoStatementType__c == 'SellOut'
                && (item.SellOutDiscountUAmt__c == null || item.SellOutDiscountUAmt__c == 0)
                && (item.SellOutDiscountFixedAmt__c == null || item.SellOutDiscountFixedAmt__c == 0)
                && (item.SellOutDiscountPerc__c == null || item.SellOutDiscountPerc__c == 0))
            {
                List<String> fields = new List<String> {
                    SObjectType.ProductDiscountStatementDetail__c.fields.SellOutDiscountUAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.SellOutDiscountFixedAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.SellOutDiscountPerc__c.Name
                };
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_03}', scanResultsMap, fields, 'Error');
            }
            if (item.ProductDiscountStatement__r.PromoStatementType__c != null
                && item.ProductDiscountStatement__r.PromoStatementType__c == 'Services'
                && (item.ServicesDiscountUAmt__c == null || item.ServicesDiscountUAmt__c == 0)
                && (item.ServicesDiscountFixedAmt__c == null || item.ServicesDiscountFixedAmt__c == 0))
            {
                List<String> fields = new List<String> {
                    SObjectType.ProductDiscountStatementDetail__c.fields.ServicesDiscountUAmt__c.Name,
                    SObjectType.ProductDiscountStatementDetail__c.fields.ServicesDiscountFixedAmt__c.Name
                };
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_03}', scanResultsMap, fields, 'Error');
            }
            if (item.ReferenceYear__c != null) {
                yearSet.add(Integer.valueOf(item.ReferenceYear__c));
            } else {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_32}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.ReferenceYear__c.Name}, 'Error');
            }
            /*if (item.DeclarantComment__c == null) {
                addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_03);
            }
            if (item.ProductQtyMax__c == null) {
                addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_04);
            }
            if (item.ProductQtyMin__c == null) {
                addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_05);
            }
            if (item.ProductQty__c == null) {
                addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_06);
            }
            if (item.GrossPrice__c == null) {
                addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_07);
            }*/
            if (String.isBlank(item.input_PRDGTIN__c) && String.isBlank(item.input_PRDCode__c) && String.isBlank(item.input_PRDName__c)) {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_08}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDGTIN__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDCode__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDName__c.Name}, 'Error');
            } else {
                if (String.isNotBlank(item.input_PRDGTIN__c)) {
                    productEANSet.add(item.input_PRDGTIN__c);
                }
                if (String.isNotBlank(item.input_PRDCode__c)) {
                    productCodeSet.add(item.input_PRDCode__c);
                }
                if (String.isNotBlank(item.input_PRDName__c)) {
                    productNameSet.add(item.input_PRDName__c);
                }
            }
            if (String.isNotBlank(item.ProductDiscountStatement__r.Supplier__c)) {
                supplierIdSet.add(item.ProductDiscountStatement__r.Supplier__c);
            }
            // Conditions ONLY for Regular RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Regular') {
                if (item.Contract_Discount__c == null && String.isBlank(item.input_PCCCode__c)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_12}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCCode__c.Name}, 'Warning');
                } else {
                    polComConditionCodeSet.add(item.input_PCCCode__c);
                }
            }
            // Conditions ONLY for Penality RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Penality') {
                if (item.Contract_Discount__c == null && String.isBlank(item.input_PCCCode__c)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_12}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCCode__c.Name}, 'Warning');
                } else {
                    polComConditionCodeSet.add(item.input_PCCCode__c);
                }
            }
            // Conditions ONLY for Other RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Other') {
                if (item.Contract_Discount__c == null && String.isBlank(item.input_PCCCode__c)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_12}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCCode__c.Name}, 'Warning');
                } else {
                    polComConditionCodeSet.add(item.input_PCCCode__c);
                }
            }
            // Conditions ONLY for Promo RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo') {
                /*if (String.isBlank(item.input_PCCCode__c) && String.isBlank(item.input_PCCSellOutCode__c) && String.isBlank(item.input_PCCServicesCode__c)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_15}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCCode__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCSellOutCode__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCServicesCode__c.Name}, 'Warning');
                } else {*/
                    if (String.isNotBlank(item.input_PCCCode__c)) {
                        polComConditionCodeSet.add(item.input_PCCCode__c);
                    }
                    if (String.isNotBlank(item.input_PCCSellOutCode__c)) {
                        polComConditionCodeSet.add(item.input_PCCSellOutCode__c);
                    }
                    if (String.isNotBlank(item.input_PCCServicesCode__c)) {
                        polComConditionCodeSet.add(item.input_PCCServicesCode__c);
                    }
                //}
                if (item.input_PCCSellOutCode__c != null && (item.SellOutBDate__c == null || item.SellOutBDate__c < item.ProductDiscountStatement__r.BDate__c || item.SellOutBDate__c >= item.ProductDiscountStatement__r.EDate__c)) {
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_19}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.SellOutBDate__c.Name}, 'Error');
                }
                if (item.input_PCCSellOutCode__c != null && (item.SellOutEDate__c == null || item.SellOutEDate__c <= item.ProductDiscountStatement__r.BDate__c || item.SellOutEDate__c > item.ProductDiscountStatement__r.EDate__c)) {
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_20}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.SellOutEDate__c.Name}, 'Error');
                }
                // Rule ignored completely (W-008730)
                // if (item.GrossPricePromo__c == null) {
                //     addMsg(warningMessages, item.Id, '{!SCAN_PDSD_21}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.GrossPricePromo__c.Name}, 'Warning');
                // }
                if (String.isBlank(item.input_BUCode__c) && String.isBlank(item.input_BUCode__c)) {
                    //addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_22, scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_BUCode__c.Name}, 'Warning');
                } else {
                    if (String.isNotBlank(item.input_BUCode__c)) {
                        BUCodeSet.add(item.input_BUCode__c);
                    }
                    if (String.isNotBlank(item.input_BUName__c)) {
                        BUNameSet.add(item.input_BUName__c);
                    }
                }
                if (String.isNotBlank(item.input_CPCode__c)) {
                    commercialPlanCodeSet.add(item.input_CPCode__c);
                }
            }
            // Conditions ONLY for StockCompensation RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'StockCompensation') {
                if (item.Contract_Discount__c == null && String.isBlank(item.input_PCCCode__c)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_12}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PCCCode__c.Name}, 'Warning');
                } else {
                    polComConditionCodeSet.add(item.input_PCCCode__c);
                }
                if (item.GrossPricePrevious__c == null) {
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_25}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.GrossPricePrevious__c.Name}, 'Error');
                }
                if (item.GrossPrice__c == null) {
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_26}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.GrossPrice__c.Name}, 'Error');
                }
                if (String.isBlank(item.input_BUCode__c) && String.isBlank(item.input_BUCode__c)) {
                    //addMsg(warningMessages, item.Id, System.Label.SCAN_PDSD_22, scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_BUCode__c.Name}, 'Warning');
                } else {
                    if (String.isNotBlank(item.input_BUCode__c)) {
                        BUCodeSet.add(item.input_BUCode__c);
                    }
                    if (String.isNotBlank(item.input_BUName__c)) {
                        BUNameSet.add(item.input_BUName__c);
                    }
                }
            }
        }
        Map<String, Product2> productsMap = new Map<String, Product2>();
        Map<String, PG__c> pgsMap = new Map<String, PG__c>();
        Map<String, NSPG__c> nspgsMap = new Map<String, NSPG__c>();
        Map<Id, Id> pgNSMap = new Map<Id, Id>();
        Map<String, Pol_Com_Condition__c> polComConditionMap = new Map<String, Pol_Com_Condition__c>();
        Map<String, BusinessUnit__c> businessUnitMap = new Map<String, BusinessUnit__c>();
        Map<String, CommercialPlan__c> commercialPlanMap = new Map<String, CommercialPlan__c>();
        Map<String, Supplier__c> supplierMap = new Map<String, Supplier__c>();
        Map<String, List<Contract__c>> contractMap = new Map<String, List<Contract__c>>();
        Map<String, NegoScope__c> nsMap = new Map<String, NegoScope__c>();
        // matching Products
        if (!productEANSet.isEmpty() || !productCodeSet.isEmpty() || !productNameSet.isEmpty()) {
            List<Product2> productList = [SELECT Id, RecordType.DeveloperName, Name, Product_Name__c, GTIN__c, ProductCode, ProductPrimary__c,
                                          ProductPrimary__r.Name, ProductPrimary__r.Product_Name__c, ProductPrimary__r.ProductCode 
                                          FROM Product2
                                          WHERE IsActive = TRUE
                                          AND ((RecordType.DeveloperName = 'Product' AND (Name IN :productNameSet
                                                                                          OR Product_Name__c IN :productNameSet
                                                                                          OR ProductCode IN :productCodeSet
                                                                                          OR GTIN__c IN :productEANSet))
                                               OR (RecordType.DeveloperName = 'Secondary' AND (ProductPrimary__r.Name IN :productNameSet
                                                                                               OR ProductPrimary__r.Product_Name__c IN :productNameSet
                                                                                               OR ProductPrimary__r.ProductCode IN :productCodeSet
                                                                                               OR GTIN__c IN :productEANSet)))];
            for (Product2 product : productList) {
                String key1, key2, key3, key4, key5, key6, key7, key8, key9, key10, key11;
                String name, productName, productCode, productGTIN;
                if (product.recordType.DeveloperName == 'Secondary') {
                    name = product.ProductPrimary__r.Name != null ? product.ProductPrimary__r.Name : '';
                    productName = product.ProductPrimary__r.Product_Name__c != null ? product.ProductPrimary__r.Product_Name__c : '';
                    productCode = product.ProductPrimary__r.ProductCode != null ? product.ProductPrimary__r.ProductCode : '';
                    productGTIN = product.GTIN__c != null ? product.GTIN__c : '';
                } else {
                    name = product.Name != null ? product.Name : '';
                    productName = product.Product_Name__c != null ? product.Product_Name__c : '';
                    productCode = product.ProductCode != null ? product.ProductCode : '';
                    productGTIN = product.GTIN__c != null ? product.GTIN__c : '';
                }
                key1 = productCode + '' + name + '' + productGTIN;
                key2 = productCode + '' + productName + '' + productGTIN;
                key3 = productName + '' + productGTIN;
                key4 = name + '' + productGTIN;
                key5 = productCode + '' + name;
                key6 = productCode + '' + productName;
                key7 = productCode + '' + productGTIN;
                key8 = productCode + '';
                key9 = name + '';
                key10 = productName + '';
                key11 = productGTIN + '';
                productsMap.put(key1, product);
                productsMap.put(key2, product);
                productsMap.put(key3, product);
                productsMap.put(key4, product);
                productsMap.put(key5, product);
                productsMap.put(key6, product);
                productsMap.put(key7, product);
                productsMap.put(key8, product);
                productsMap.put(key9, product);
                productsMap.put(key10, product);
                productsMap.put(key11, product);
            }
            system.debug('productsMap >>>> ' + JSON.serialize(productsMap));
            if (!supplierIdSet.isEmpty()) {
                List<PG__c> pgList = [SELECT Id, Supplier__c, Product__c, (SELECT Id, NegoScope__c, NegoScope__r.Supplier__c FROM NSPGPG__r WHERE NegoScope__r.RecordType.DeveloperName <> 'SubNS')
                                      FROM PG__c
                                      WHERE (Supplier__c IN :supplierIdSet OR Supplier__r.Code__c IN :supplierCodeSet)
                                      AND Product__c IN :productList
                                      AND RecordType.DeveloperName = 'Regular'];
                system.debug('pgList >>>> ' + JSON.serialize(pgList));
                for (PG__c pg : pgList) {
                    String key = pg.Supplier__c + '' + pg.Product__c;
                    pgsMap.put(key, pg);
                    if (!pg.NSPGPG__r.isEmpty()) {
                        for (NSPG__c nspg : pg.NSPGPG__r) {
                            String nspgKey = nspg.NegoScope__c + '' + pg.Id;
                            nspgsMap.put(nspgKey, nspg);
                            pgNSMap.put(pg.Id, nspg.NegoScope__c);
                        }
                    }
                }
            }
        }
        // matching Pol Com Conditions
        if (!polComConditionCodeSet.isEmpty()) {
            List<Pol_Com_Condition__c> polComConditionList = [SELECT Id, Condition_Code__c, Is_Tariff_Condition__c, SetCommercialPlanDetail1__c,
                                                              Capture_Discount_Product_Level__c, PromoStatementType__c,
                                                              (SELECT Id, Contract__c, Disc_BDate__c, Disc_EDate__c FROM Contract_Discounts__r WHERE Contract__r.Reference_Year__c IN :yearSet)
                                                              FROM Pol_Com_Condition__c
                                                              WHERE Condition_Code__c IN :polComConditionCodeSet];
            for (Pol_Com_Condition__c budgetCode : polComConditionList) {
                polComConditionMap.put(budgetCode.Condition_Code__c, budgetCode);
            }
        }
        // matching BU
        if (!BUCodeSet.isEmpty() || !BUNameSet.isEmpty()) {
            List<BusinessUnit__c> BUList = [SELECT Id, Name, Code__c
                                            FROM BusinessUnit__c
                                            WHERE Name IN :BUNameSet
                                            AND Code__c IN :BUCodeSet];
            for (BusinessUnit__c bu : BUList) {
                String buKey = bu.Name + '' + bu.Code__c;
                businessUnitMap.put(buKey, bu);
                businessUnitMap.put(bu.Name, bu);
                businessUnitMap.put(bu.Code__c, bu);
            }
        }
        // matching CP
        if (!commercialPlanCodeSet.isEmpty()) {
            List<CommercialPlan__c> commercialPlanList = [SELECT Id, Code__c
                                                          FROM CommercialPlan__c
                                                          WHERE Code__c IN :commercialPlanCodeSet];
            for (CommercialPlan__c commercialPlan : commercialPlanList) {
                commercialPlanMap.put(commercialPlan.Code__c, commercialPlan);
            }
        }
        // matching Supplier
        if (!supplierCodeSet.isEmpty()) {
            List<Supplier__c> supplierList = [SELECT Id, Name, Code__c
                                              FROM Supplier__c
                                              WHERE Code__c IN :supplierCodeSet];
            for (Supplier__c item : supplierList) {
                supplierMap.put(item.Code__c, item);
            }
        }
        // matching NS
        if (!nsCodeSet.isEmpty()) {
            List<NegoScope__c> nsList = [SELECT Id, Name, Code__c
                                         FROM NegoScope__c
                                         WHERE Code__c IN :nsCodeSet
                                         AND RecordType.DeveloperName <> 'SubNS'];
            for (NegoScope__c item : nsList) {
                nsMap.put(item.Code__c, item);
            }
        }
        // matching Contract
        if (minDate != null && maxDate != null) {
            List<Contract__c> contracts = [SELECT Id, Supplier_Nego_Scope__c, Reference_Year__c, CurrencyIsoCode, Contract_BDate__c, Contract_EDate__c,
                                           (SELECT Id, Condition_Type__c, Condition_Type__r.PromoStatementType__c, Condition_Type__r.PromoAgreementType__c,
                                            Condition_Type__r.Capture_Discount_Product_Level__c, Condition_Type__r.SetCommercialPlanDetail1__c, Status__c, Disc_BDate__c, Disc_EDate__c
                                            FROM Contract_Discounts__r
                                            WHERE Status__c != 'Deleted'
                                            AND Condition_Type__r.Capture_Discount_Product_Level__c != null
                                            AND Condition_Type__r.SetCommercialPlanDetail1__c = true
                                            AND Condition_Type__r.PromoStatementType__c <> NULL)
                                           FROM Contract__c
                                           WHERE Is_OnTop_Simulation__c = TRUE
                                           AND Contract_BDate__c <= :minDate
                                           AND Contract_EDate__c >= :maxDate
                                           AND Status__c <> 'Deleted'];
            if (contracts != null && !contracts.isEmpty()) {
                for (Contract__c item : contracts) {
                    String contractKey = item.Supplier_Nego_Scope__c;
                    if (!contractMap.containsKey(item.Supplier_Nego_Scope__c)) {
                        contractMap.put(contractKey, new List<Contract__c>());
                    }
                    contractMap.get(contractKey).add(item);
                }
            }
        }
        for (ProductDiscountStatementDetail__c item : scope) {
            // Set NegoScope__c
            if (item.ProductDiscountStatement__r.NegoScope__c != null) {
                item.NegoScope__c = item.ProductDiscountStatement__r.NegoScope__c;
            } else if (String.isNotBlank(item.input_NSCode__c)) {
                if (nsMap.containsKey(item.input_NSCode__c)) {
                    item.NegoScope__c = nsMap.get(item.input_NSCode__c).Id;
                } else {
                    item.NegoScope__c = null;
                }
            } else {
                item.NegoScope__c = null;
            }
            // Set Supplier__c
            if (item.ProductDiscountStatement__r.Supplier__c != null) {
                item.Supplier__c = item.ProductDiscountStatement__r.Supplier__c;
            } else if (item.NegoScope__c != null) {
                item.Supplier__c = item.NegoScope__r.Supplier__c;
            } else if (String.isNotBlank(item.input_SUPCode__c)) {
                if (supplierMap.containsKey(item.input_SUPCode__c)) {
                    item.Supplier__c = supplierMap.get(item.input_SUPCode__c).Id;
                } else {
                    item.Supplier__c = null;
                }
            }
            // Set Product__c
            if (String.isNotBlank(item.input_PRDGTIN__c) || String.isNotBlank(item.input_PRDCode__c) || String.isNotBlank(item.input_PRDName__c)) {
                String productKey = '';
                if (String.isNotBlank(item.input_PRDCode__c)) {
                    productKey += item.input_PRDCode__c;
                }
                if (String.isNotBlank(item.input_PRDName__c)) {
                    productKey += item.input_PRDName__c;
                }
                if (String.isNotBlank(item.input_PRDGTIN__c)) {
                    productKey += item.input_PRDGTIN__c;
                }
                if (!productsMap.containskey(productKey)) {
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_09}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDGTIN__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDCode__c.Name, SObjectType.ProductDiscountStatementDetail__c.fields.input_PRDName__c.Name}, 'Warning');
                    item.Product__c = null;
                    item.PG__c = null;
                } else {
                    Product2 product = productsMap.get(productKey);
                    item.Product__c = product.RecordType.DeveloperName == 'Secondary' ? product.ProductPrimary__c : product.Id;
                    String pgKey = item.Supplier__c + '' + item.Product__c;
                    if (!pgsMap.containskey(pgKey)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_10}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.PG__c.Name}, 'Warning');
                        item.PG__c = null;
                    } else {
                        item.PG__c = pgsMap.get(pgKey).Id;
                    }
                }
            }
            // Fill NegoScope__c FROM Concatenation of PG__c and Supplier__c
            if (item.Supplier__c != null && item.PG__c != null && item.NegoScope__c == null) {
                String nspgKey = item.Supplier__c + '' + item.PG__c;
                if (pgNSMap.containskey(item.PG__c)) {
                    item.NegoScope__c = pgNSMap.get(item.PG__c);
                }
            }
            // Set Contract__c
            if (item.NegoScope__c != null) {
                if (contractMap.containsKey(item.NegoScope__c)) {
                    for (Contract__c contract : contractMap.get(item.NegoScope__c)) {
                        if (item.BDate__c >= contract.Contract_BDate__c && item.EDate__c <= contract.Contract_EDate__c) {
                            item.Contract__c = contract.Id;
                            item.CurrencyIsoCode = contract.CurrencyIsoCode;
                            break;
                        }
                    }
                    if (item.Contract__c == null) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_33}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract__c.Name}, 'Warning');
                    }
                } else {
                    item.Contract__c = null;
                    addMsg(warningMessages, item.Id, '{!SCAN_PDSD_33}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract__c.Name}, 'Warning');
                }
            }
            if (item.Supplier__c == null) {
                addMsg(errorMessages, item.Id, '{!SCAN_PDSD_29}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Supplier__c.Name}, 'Error');
            } else if (item.NegoScope__c == null) {
                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_31}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.NegoScope__c.Name}, 'Warning');
            } else if (item.PG__c != null) {
                String nspgKey = item.NegoScope__c + '' + item.PG__c;
                if (!nspgsMap.containskey(nspgKey)) {
                    addMsg(errorMessages, item.Id, '{!SCAN_PDSD_11}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.PG__c.Name}, 'Error');
                }
            }
            // Conditions ONLY for Regular RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Regular') {
                if (String.isNotBlank(item.input_PCCCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        item.Pol_Com_Condition__c = null;
                        item.Contract_Discount__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCCode__c);
                        if (budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_Condition__c = budgetCode.Id;
                            item.Contract_Discount__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_Discount__c = discount.Id;
                                }
                            }
                            if (item.Contract_Discount__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Warning');
                            }
                        } else {
                            item.Pol_Com_Condition__c = null;
                            item.Contract_Discount__c = null;
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_13}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        }
                    }
                }
            }
            // Conditions ONLY for Penality RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Penality') {
                if (String.isNotBlank(item.input_PCCCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        item.Pol_Com_Condition__c = null;
                        item.Contract_Discount__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCCode__c);
                        if (budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_Condition__c = budgetCode.Id;
                            item.Contract_Discount__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_Discount__c = discount.Id;
                                }
                            }
                            if (item.Contract_Discount__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Warning');
                            }
                        } else {
                            item.Pol_Com_Condition__c = null;
                            item.Contract_Discount__c = null;
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_34}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        }
                    }
                }
            }
            // Conditions ONLY for Other RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Other') {
                if (String.isNotBlank(item.input_PCCCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        item.Pol_Com_Condition__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCCode__c);
                        if (budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_Condition__c = budgetCode.Id;
                            item.Contract_Discount__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_Discount__c = discount.Id;
                                }
                            }
                            if (item.Contract_Discount__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Warning');
                            }
                        } else {
                            item.Pol_Com_Condition__c = null;
                            item.Contract_Discount__c = null;
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_34}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        }
                    }
                }
            }
            // Set BusinessUnit__c ONLY for RT Promo & StockCompensation
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo' || item.ProductDiscountStatement__r.RecordType.DeveloperName == 'StockCompensation') {
                if (String.isNotBlank(item.input_BUName__c) || String.isNotBlank(item.input_BUCode__c)) {
                    String buKey = '';
                    if (String.isNotBlank(item.input_BUName__c)) {
                        buKey += item.input_BUName__c;
                    }
                    if (String.isNotBlank(item.input_BUCode__c)) {
                        buKey += item.input_BUCode__c;
                    }
                    if (!businessUnitMap.containskey(buKey)) {
                        addMsg(errorMessages, item.Id, '{!SCAN_PDSD_23}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.BusinessUnit__c.Name}, 'Error');
                        item.BusinessUnit__c = null;
                    } else {
                        item.BusinessUnit__c = businessUnitMap.get(buKey).Id;
                    }
                }
            }
            // Conditions ONLY for Promo RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'Promo') {
                if (String.isNotBlank(item.input_PCCCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        item.Pol_Com_Condition__c = null;
                        item.Contract_Discount__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCCode__c);
                        if (budgetCode.SetCommercialPlanDetail1__c && budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_Condition__c = budgetCode.Id;
                            item.Contract_Discount__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_Discount__c = discount.Id;
                                }
                            }
                            if (item.Contract_Discount__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Warning');
                            }
                        } else {
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_16}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                            item.Pol_Com_Condition__c = null;
                            item.Contract_Discount__c = null;
                        }
                    }
                } else {
                    if (item.Contract__c != null && item.Contract_Discount__c == null) {
                        Map<Id, Contract__c> contractInfoMap = new Map<Id, Contract__c>(contractMap.get(item.NegoScope__c));
                        List<Contract_Discount__c> matches = new List<Contract_Discount__c>();
                        for (Contract_Discount__c discount : contractInfoMap.get(item.Contract__c).Contract_Discounts__r) {
                            if (item.ProductDiscountStatement__r.PromoStatementType__c.contains('SellIn')
                                && item.BDate__c >= discount.Disc_BDate__c
                                && item.EDate__c <= discount.Disc_EDate__c
                                && (discount.Condition_Type__r.PromoAgreementType__c == null || discount.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c)
                                && (discount.Condition_Type__r.PromoStatementType__c == null || discount.Condition_Type__r.PromoStatementType__c == 'SellIn'))
                            {
                                matches.add(discount);
                            }
                        }
                        if (matches.size() == 1) {
                            item.Contract_Discount__c = matches[0].Id;
                        }
                    }
                }
                if (String.isNotBlank(item.input_PCCSellOutCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCSellOutCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCSellOutCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionSellOut__c.Name}, 'Warning');
                        item.Pol_Com_ConditionSellOut__c = null;
                        item.Contract_DiscountSellOut__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCSellOutCode__c);
                        if (budgetCode.PromoStatementType__c == 'SellOut' && budgetCode.SetCommercialPlanDetail1__c && budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_ConditionSellOut__c = budgetCode.Id;
                            item.Contract_DiscountSellOut__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_DiscountSellOut__c = discount.Id;
                                }
                            }
                            if (item.Contract_DiscountSellOut__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCSellOutCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_DiscountSellOut__c.Name}, 'Warning');
                            }
                        } else {
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_17}' + ' (' + item.input_PCCSellOutCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionSellOut__c.Name}, 'Warning');
                            item.Pol_Com_ConditionSellOut__c = null;
                            item.Contract_DiscountSellOut__c = null;
                        }
                    }
                } else {
                    if (item.Contract__c != null && item.Contract_Discount__c == null) {
                        Map<Id, Contract__c> contractInfoMap = new Map<Id, Contract__c>(contractMap.get(item.NegoScope__c));
                        List<Contract_Discount__c> matches = new List<Contract_Discount__c>();
                        for (Contract_Discount__c discount : contractInfoMap.get(item.Contract__c).Contract_Discounts__r) {
                            if (item.ProductDiscountStatement__r.PromoStatementType__c.contains('SellOut')
                                && item.BDate__c >= discount.Disc_BDate__c
                                && item.EDate__c <= discount.Disc_EDate__c
                                && (discount.Condition_Type__r.PromoAgreementType__c == null || discount.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c)
                                && (discount.Condition_Type__r.PromoStatementType__c == null || discount.Condition_Type__r.PromoStatementType__c == 'SellOut'))
                            {
                                matches.add(discount);
                            }
                        }
                        if (matches.size() == 1) {
                            item.Contract_DiscountSellOut__c = matches[0].Id;
                        }
                    }
                }
                if (String.isNotBlank(item.input_PCCServicesCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCServicesCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCServicesCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionServices__c.Name}, 'Warning');
                        item.Pol_Com_ConditionServices__c = null;
                        item.Contract_DiscountServices__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCServicesCode__c);
                        if (budgetCode.PromoStatementType__c == 'Services' && budgetCode.SetCommercialPlanDetail1__c && budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_ConditionServices__c = budgetCode.Id;
                            item.Contract_DiscountServices__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_DiscountServices__c = discount.Id;
                                }
                            }
                            if (item.Contract_DiscountServices__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCServicesCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_DiscountServices__c.Name}, 'Warning');
                            }
                        } else {
                            addMsg(warningMessages, item.Id, '{!SCAN_PDSD_18}' + ' (' + item.input_PCCServicesCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionServices__c.Name}, 'Warning');
                            item.Pol_Com_ConditionServices__c = null;
                            item.Contract_DiscountServices__c = null;
                        }
                    }
                } else {
                    if (item.Contract__c != null && item.Contract_Discount__c == null) {
                        Map<Id, Contract__c> contractInfoMap = new Map<Id, Contract__c>(contractMap.get(item.NegoScope__c));
                        List<Contract_Discount__c> matches = new List<Contract_Discount__c>();
                        for (Contract_Discount__c discount : contractInfoMap.get(item.Contract__c).Contract_Discounts__r) {
                            if (item.ProductDiscountStatement__r.PromoStatementType__c.contains('Services')
                                && item.BDate__c >= discount.Disc_BDate__c
                                && item.EDate__c <= discount.Disc_EDate__c
                                && (discount.Condition_Type__r.PromoAgreementType__c == null || discount.Condition_Type__r.PromoAgreementType__c == item.ProductDiscountStatement__r.PromoAgreementType__c)
                                && (discount.Condition_Type__r.PromoStatementType__c == null || discount.Condition_Type__r.PromoStatementType__c == 'Services'))
                            {
                                matches.add(discount);
                            }
                        }
                        if (matches.size() == 1) {
                            item.Contract_DiscountServices__c = matches[0].Id;
                        }
                    }
                }
                if (String.isNotBlank(item.input_CPCode__c)) {
                    if (!commercialPlanMap.containsKey(item.input_CPCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_24}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.CommercialPlan__c.Name}, 'Warning');
                        item.CommercialPlan__c = null;
                    } else {
                        item.CommercialPlan__c = commercialPlanMap.get(item.input_CPCode__c).Id;
                    }
                } else {
                    // Rule ignored completely (W-008730)
                    // addMsg(warningMessages, item.Id, '{!SCAN_PDSD_24}', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.CommercialPlan__c.Name}, 'Warning');
                }
            }
            // Conditions ONLY for StockCompensation RT
            if (item.ProductDiscountStatement__r.RecordType.DeveloperName == 'StockCompensation') {
                if (String.isNotBlank(item.input_PCCCode__c)) {
                    if (!polComConditionMap.containsKey(item.input_PCCCode__c)) {
                        addMsg(warningMessages, item.Id, '{!SCAN_PDSD_27}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Warning');
                        item.Pol_Com_Condition__c = null;
                        item.Contract_Discount__c = null;
                    } else {
                        Pol_Com_Condition__c budgetCode = polComConditionMap.get(item.input_PCCCode__c);
                        if (budgetCode.Capture_Discount_Product_Level__c != null) {
                            item.Pol_Com_Condition__c = budgetCode.Id;
                            item.Contract_Discount__c = null;
                            for (Contract_Discount__c discount : budgetCode.Contract_Discounts__r) {
                                if (item.Contract__c == discount.Contract__c && item.BDate__c >= discount.Disc_BDate__c && item.EDate__c <= discount.Disc_EDate__c) {
                                    item.Contract_Discount__c = discount.Id;
                                }
                            }
                            if (item.Contract_Discount__c == null) {
                                addMsg(warningMessages, item.Id, '{!SCAN_PDSD_14}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Contract_Discount__c.Name}, 'Warning');
                            }
                        } else {
                            addMsg(errorMessages, item.Id, '{!SCAN_PDSD_16}' + ' (' + item.input_PCCCode__c + ')', scanResultsMap, new List<String>{SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name}, 'Error');
                            item.Pol_Com_Condition__c = null;
                            item.Contract_Discount__c = null;
                        }
                    }
                }
            }
            // Fill ScanStatus__c, ScanResults__c, ScanLDate__c
            if (errorMessages.containsKey(item.Id)) {
                item.ScanStatus__c = 'Error';
            } else if (warningMessages.containsKey(item.Id)) {
                item.ScanStatus__c = 'Warning';
            } else {
                item.ScanStatus__c = 'Success';
            }
            item.ScanResults__c = (errorMessages.containsKey(item.Id) ? '{!LBL_Error}:\n• ' + String.join(new List<String>(errorMessages.get(item.Id)), '\n• ') : '') + '\n' + (warningMessages.containsKey(item.Id) ? '{!LBL_Warning}:\n• ' + String.join(new List<String>(warningMessages.get(item.Id)), '\n• ') : '');
            item.t_ScanResultsByColumn__c = JSON.serialize(scanResultsMap.get(item.Id));
            item.ScanLDate__c = System.now();
            if (this.forceScan) {
                item.t_SetForceScan__c = false;
            }
        }
        System.SavePoint sp = Database.setSavepoint();
        try {
            List<Database.SaveResult> results = Database.update(scope, true);
            nb.logResults(results, scope);            
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    
    private void addMsg(Map<Id, Set<String>> messages, Id recordId, String msg, Map<Id, Map<String, String>> scanResultsMap, List<String> fieldNames, String status) {
        if (!messages.containsKey(recordId)) {
            messages.put(recordId, new Set<String>());
        }
        messages.get(recordId).add(msg);
        for (String fieldName : fieldNames) {
            scanResultsMap.get(recordId).put(fieldName, status);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        //nb.sendEmail;
		nb.saveLog(bc);
        if (this.batchId != null) {
            List<Batch__c> batches = [SELECT Id, Status__c 
                                      FROM Batch__c
                                      WHERE Id = :this.batchId];
            if (!batches.isEmpty()) {
                Batch__c batch = batches[0];
                batch.Status__c = nb.getAsyncApexJob(bc).Status;
                batch.RecordCount__c = Database.query(query).size();
                update batch;
            }
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> productDiscountStatementIdSet = (Set<Id>)paramsMap.get('productDiscountStatementIdSet');
        Set<Id> productDiscountStatementDetailsIdSet = (Set<Id>)paramsMap.get('productDiscountStatementDetailsIdSet');
        Set<Id> contractIdSet = (Set<Id>)paramsMap.get('contractIdSet');
        Id batchId = (Id)paramsMap.get('batchId');
        Boolean forceScan = (Boolean)paramsMap.get('forceScan');
        return new PDSDScanBatch(startedFrom, productDiscountStatementIdSet, productDiscountStatementDetailsIdSet, contractIdSet, batchId, forceScan);
    }
}