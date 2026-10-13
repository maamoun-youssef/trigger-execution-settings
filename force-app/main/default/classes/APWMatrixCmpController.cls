/**
* @author ULiT
* @date 11-10-2023
* @description apex controller to manage Assortment Price WaterFall page
*/
public with sharing class APWMatrixCmpController {
    public static String prefix = NegoptimHelper.getPackagePrefix(true);
    public static Set<String> masterStaticFieldsList = new Set<String> {
        SObjectType.Assortment_BU__c.fields.Id.Name,
        SObjectType.Assortment_BU__c.fields.Name.Name,
        SObjectType.Assortment_BU__c.fields.Long_Name__c.Name,
        SObjectType.Assortment_BU__c.fields.Contract__c.Name,
        SObjectType.Assortment_BU__c.fields.Hierarchy__c.Name,
        SObjectType.Assortment_BU__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.Assortment_BU__c.fields.Assortment__c.Name,
        SObjectType.Assortment_BU__c.fields.Ass_BDate__c.Name,
        SObjectType.Assortment_BU__c.fields.Ass_EDate__c.Name,
        SObjectType.Assortment_BU__c.fields.Status__c.Name,
        SObjectType.Assortment_BU__c.fields.Year__c.Name,
        SObjectType.Assortment_BU__c.fields.Contract_Active_Taxes__c.Name,
        SObjectType.Assortment_BU__c.fields.Contract_Active_Discounts__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_BDate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name
    };
    public static List<String> staticFieldsList = new List<String>{
        // Assortment fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Contract__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Hierarchy__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Ass_BDate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Ass_EDate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Status__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name) + '.' + SObjectType.Assortment_BU__c.fields.Year__c.Name,
        // category fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Level__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name,
        // product fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Product_Name__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.ProductCode.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Product_EAN__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.UC__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Total_Weight__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Element_nb__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Reference_Product__c.Name,
        // linked product fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product_linked__c.Name) + '.' + SObjectType.Product2.fields.Product_Name__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product_linked__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Product_linked__c.Name) + '.' + SObjectType.Product2.fields.Product_EAN__c.Name,
        // promo event fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event__c.Name) + '.' + SObjectType.CommercialPlan__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event__c.Name) + '.' + SObjectType.CommercialPlan__c.fields.Code__c.Name,
        // promo details fields (reference)
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + SObjectType.CommercialPlanDetail__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Display_Order__c.Name,
        // assortment price waterfall fields
        SObjectType.Assortment_PriceWaterFall__c.fields.RecordTypeId.Name,
        'RecordType.DeveloperName',
        SObjectType.Assortment_PriceWaterFall__c.fields.Last_History__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Assortment_BU__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Product__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Movement_Date__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Status__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Record_date__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Version__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Product_linked__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail_BDate__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event_Detail_EDate__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.Promo_Event__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_CostPrice__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_NetPrice_woTax__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_NetPrice_wTax__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.PriceBeforePromoDisc__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.IsIncludeAProductDiscount__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.PG__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_Active_Taxes__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_Discount_Taxes__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_Active_Discounts__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_Type_perc_Discounts__c.Name,
        SObjectType.Assortment_PriceWaterFall__c.fields.New_Type_U_Discounts__c.Name
    };
    @AuraEnabled
    public static Assortment_BU__c getAssortmentBU(Id recordId, List<String> fields) {
        String query = 'SELECT ';
        if (fields == null || fields.isEmpty()) {
            query += 'Id, Name, Long_Name__c, Contract__r.RecordType.DeveloperName, Contract__r.Name, Contract__c, Contract__r.Contract_BDate__c, BusinessUnitTarget__c,';
            query += 'Assortment__c, Hierarchy__r.Name, Hierarchy__c, Ass_BDate__c, Ass_EDate__c, Status__c, Year__c, Contract_Active_Taxes__c, Contract_Active_Discounts__c';
        } else {
            query += '' + String.join(fields, ',');
        }
        query += ' FROM Assortment_BU__c';
        query += ' WHERE Id = \'' + recordId + '\'';
        List<Assortment_BU__c> assortmentBUs = Database.query(query);
        if (!assortmentBUs.isEmpty()) {
            return assortmentBUs[0];
        }
        return null;
    }
    /**
     * @description Load initial data
     */
    @AuraEnabled
    public static string getInitialData(String recordId, String gridLayout) {
        try {
            NegoSettings settings = NegoSettings.loadNegoSettings();
            List<String> dynamicTaxesFields = new List<String>(), dynamicDiscountsFields = new List<String>();
            for (Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i; i++) {
                dynamicTaxesFields.add(prefix + 'New_Tax_' + i + '__c');
            }
            for(Integer i = 1; i <= CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i; i++) {
                dynamicDiscountsFields.add(prefix + 'New_Disc_' + i + '__c');
                dynamicDiscountsFields.add(prefix + 'New_Disc_' + i + '_U__c');
                dynamicDiscountsFields.add(prefix + 'New_Disc_' + i + '_UType__c');
                dynamicDiscountsFields.add(prefix + 'New_Disc_' + i + '_Rank__c');
            }
            staticFieldsList.addAll(dynamicTaxesFields);
            staticFieldsList.addAll(dynamicDiscountsFields);
            String staticFields = String.join(staticFieldsList, ',');
            String masterStaticFields = String.join(masterStaticFieldsList, ',');
            String priceWaterFallGrid = String.isBlank(gridLayout) ? settings.priceWaterfallMatrixGrid : gridLayout;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment_BU__c.Name, '', masterStaticFields, SObjectType.Assortment_PriceWaterFall__c.Name, '', staticFields, priceWaterFallGrid, true);
            Assortment_BU__c assortmentBU = getAssortmentBU(recordId, gridSettingsManager.ALL_BANNER_FIELDS);
            AssortmentDataWrapper mainWrapper = new AssortmentDataWrapper(assortmentBU, gridSettingsManager);
            Schema.DescribeFieldResult dfr;
            Map<String, schema.SObjectField> objectFieldsMap = Assortment_PriceWaterFall__c.SObjectType.getDescribe().fields.getMap();
            if (assortmentBU.Contract_Active_Discounts__c != null && String.isNotBlank(assortmentBU.Contract_Active_Discounts__c)) {
                List<StatementWrapper> statementList = (List<StatementWrapper>) JSON.deserialize(assortmentBU.Contract_Active_Discounts__c, List<StatementWrapper>.class);
                Set<Id> conditionIds = new Set<Id>();
                for (StatementWrapper item : statementList) {
                    conditionIds.add(item.recordId);
                }
                Map<Id, Pol_Com_Condition__c> conditionList = new Map<Id, Pol_Com_Condition__c>([SELECT Id, SetCommercialPlanDetail1__c
                                                                                                 FROM Pol_Com_Condition__c
                                                                                                 WHERE Id IN :conditionIds
                                                                                                 AND Capture_Discount_Product_Level__c IN ('Optional', 'Mandatory')]);
                for (StatementWrapper item : statementList) {
                    if (item.displayOrder > CommonConstants.FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i) continue;
                    DynamicFieldsWrapper dynamicField = new DynamicFieldsWrapper();
                    dynamicField.isFieldGroup = true;
                    dynamicField.groupFieldName = item.Name;
                    dynamicField.url = '/' + item.recordId;
                    dynamicField.displayOrder = item.displayOrder;
                    String[] conditionModes = item.conditionMode.split(';');
                    String fieldApiName;
                    for (Integer i = 0; i < conditionModes.size(); i++) {
                        if (conditionModes[i] == '%') {
                            fieldApiName = prefix + 'New_Disc_' + item.displayOrder + '__c';
                            dfr = objectFieldsMap.get(fieldApiName).getDescribe();
                            FieldWrapper field = new FieldWrapper(dfr.getName(), Label.LBL_Disc_Percent, dfr.getType().Name(), dfr.getPicklistValues(), conditionList.containsKey(item.recordId), item.displayOrder, (conditionList.containsKey(item.recordId) ? 'background-color:#EEDBF0;' : 'background-color:#EFFEFF;') + 'min-width:80px;', dfr.getScale(), conditionList.containsKey(item.recordId) && !conditionList.get(item.recordId).SetCommercialPlanDetail1__c);
                            dynamicField.subFieldsList.add(field);
                        }
                        if (conditionModes[i] == 'U') {
                            fieldApiName = prefix + 'New_Disc_' + item.displayOrder + '_U__c';
                            dfr = objectFieldsMap.get(fieldApiName).getDescribe();
                            FieldWrapper field = new FieldWrapper(dfr.getName(), Label.LBL_Disc_Unit, dfr.getType().Name(), dfr.getPicklistValues(), conditionList.containsKey(item.recordId), item.displayOrder, (conditionList.containsKey(item.recordId) ? 'background-color:#EEDBF0;' : 'background-color:#EFFEFF;') + 'min-width:80px;', dfr.getScale(), conditionList.containsKey(item.recordId) && !conditionList.get(item.recordId).SetCommercialPlanDetail1__c);
                            dynamicField.subFieldsList.add(field);
                            fieldApiName = prefix + 'New_Disc_' + item.displayOrder + '_UType__c';
                            dfr = objectFieldsMap.get(fieldApiName).getDescribe();
                            field = new FieldWrapper(dfr.getName(), Label.LBL_Disc_UType, dfr.getType().Name(), dfr.getPicklistValues(), conditionList.containsKey(item.recordId), item.displayOrder, (conditionList.containsKey(item.recordId) ? 'background-color:#EEDBF0;' : 'background-color:#EFFEFF;') + 'max-width: 9rem;', dfr.getScale(), conditionList.containsKey(item.recordId) && !conditionList.get(item.recordId).SetCommercialPlanDetail1__c);
                            dynamicField.subFieldsList.add(field);
                        }
                    }
                    fieldApiName = prefix + 'New_Disc_' + item.displayOrder + '_Rank__c';
                    dfr = objectFieldsMap.get(fieldApiName).getDescribe();
                    FieldWrapper field = new FieldWrapper(dfr.getName(), Label.LBL_Disc_Rank, dfr.getType().Name(), dfr.getPicklistValues(), false, item.displayOrder, 'background-color:#EFFEFF;max-width: 6rem;', dfr.getScale(), false);
                    dynamicField.subFieldsList.add(field);
                    mainWrapper.displayedDynamicFields.add(dynamicField);
                }
            }
            if (assortmentBU.Contract_Active_Taxes__c != null && String.isNotBlank(assortmentBU.Contract_Active_Taxes__c)) {
                for (StatementWrapper item : (List<StatementWrapper>) JSON.deserialize(assortmentBU.Contract_Active_Taxes__c, List<StatementWrapper>.class)) {
                    DynamicFieldsWrapper dynamicField = new DynamicFieldsWrapper();
                    dynamicField.groupFieldName = item.Name;
                    dynamicField.url = '/' + item.recordId;
                    dynamicField.displayOrder = item.displayOrder;
                    item.fieldApiName = prefix + 'New_Tax_' + item.displayOrder + '__c';
                    dfr = objectFieldsMap.get(item.fieldApiName).getDescribe();
                    FieldWrapper field = new FieldWrapper(dfr.getName(), item.Name, dfr.getType().Name(), dfr.getPicklistValues(), false, item.displayOrder, 'background-color:#FEFFE7;max-width: 6rem;', dfr.getScale(), false);
                    dynamicField.subFieldsList.add(field);
                    mainWrapper.displayedDynamicFields.add(dynamicField);
                }
            }
            mainWrapper.dynamicTaxesFields = dynamicTaxesFields;
            mainWrapper.dynamicDiscountsFields = dynamicDiscountsFields;
            return JSON.serialize(mainWrapper);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getproductsKeys(String recordId, String filterTerms) {
        try {
            List<String> conditions = getConditions(filterTerms, recordId, null, null, null, false, null, true, false);
            List<String> keyList = new List<String>();
            String query;
            query = 'SELECT Product__c productId, Product__r.Name productName, Movement_Date__c Movement_Date__c, Promo_Event_Detail__c promoDetailId, Hierarchy__r.Name category FROM Assortment_PriceWaterFall__c';
            query += ' WHERE ' + String.join(conditions, ' AND ');
            query += ' AND Version__c = NULL';
            query += ' GROUP BY Product__c, Product__r.Name, Movement_Date__c, Promo_Event_Detail__c, Hierarchy__r.Name ';
            query += ' ORDER BY Hierarchy__r.Name, Product__r.Name';
            system.debug('query >>> ' + query);
            List<AggregateResult> aggregateResults = Database.query(query);
            for (AggregateResult result : aggregateResults){
                Id productId = Id.valueOf(String.valueOf(result.get('productId')));
                Id promoDetailId = result.get('promoDetailId') != null ? Id.valueOf(String.valueOf(result.get('promoDetailId'))) : null;
                Date movementDate = result.get('Movement_Date__c') != null ? date.valueOf(String.valueOf(result.get('Movement_Date__c'))) : null;
                String key = productId + ';' + movementDate + (promoDetailId != null ? ';' + promoDetailId : '');
                keyList.add(key);
            }
            return JSON.serialize(keyList);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static String buildQuery(GridSettingsManager gridSettingsManager, String filterTerms, String recordId, List<String> prodPromoKey, Integer pageSize, Integer pageNumber, boolean isExport, List<String> recordsIdsList) {
        try {
            List<String> conditions = getConditions(filterTerms, recordId, prodPromoKey, pageSize, pageNumber, isExport, recordsIdsList, false, false);
            String orderBy = 'Hierarchy__r.Name, Hierarchy__r.Path__c ASC, Product__r.Name ASC, Product__r.ProductCode ASC, Version__c DESC, Movement_Date__c, RecordType.DeveloperName ASC, Promo_Event__c NULLS FIRST';
            String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
            system.debug('query >>>> ' + query);
            return query;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() ); 
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static List<String> getConditions(String filterTerms,String recordId, List<String> prodPromoKey, Integer pageSize, Integer pageNumber, boolean isExport, List<String> recordsIdsList, Boolean isAggregation, Boolean calculateTotalSize) {
        try {
            List<String> conditions = new List<String>();
            conditions.add('Hierarchy__c <> NULL AND Movement_Date__c <> NULL AND (Product__c <> NULL OR Promo_Event_Detail__c <> NULL)');
            conditions.add('ScheduledForWithdrawal__c = FALSE');
            FilterTermWrapper wFilterWrapper = !String.isBlank(filterTerms) ? (FilterTermWrapper)JSON.deserialize(filterTerms, FilterTermWrapper.class) :  new FilterTermWrapper();
            Map<Id, Id> promoDetailIdMap = new Map<Id, Id>();
            Map<String, Set<Id>> productMovementDatesMap = new Map<String, Set<Id>>();
            List<String> rts = new List<String>{'Nego'}; //Only Nego WO Statement
            List<String> historyRts = new List<String>();
            if (pageNumber != null && pageSize != null) {
                Integer startIndex = isExport ? 0 : pageNumber*pageSize;
                Integer stopIndex = isExport ? prodPromoKey.size() : pageSize*(pageNumber + 1);
                if (!isExport) {
                    for (integer i = startIndex ; i < stopIndex; i++) {
                        if (i < prodPromoKey.size()) {
                            List<String> results = prodPromoKey[i].split(';');
                            Id productId = (Id) results[0];
                            String movementDate = DateTime.valueOf(results[1]).format('yyyy-MM-dd');
                            if(results.size() == 2) {
                                if(!productMovementDatesMap.containsKey(movementDate)) productMovementDatesMap.put(movementDate, new Set<Id>());
                                productMovementDatesMap.get(movementDate).add(productId);
                            } else {
                                Id commercialPlanDetailId = (Id) results[2];
                                promoDetailIdMap.put(commercialPlanDetailId, productId);
                            }
                        }
                    }
                }
            }
            if (calculateTotalSize) {
                for (integer i = 0 ; i < prodPromoKey.size(); i++) {
                    List<String> results = prodPromoKey[i].split(';');
                    Id productId = (Id) results[0];
                    String movementDate = DateTime.valueOf(results[1]).format('yyyy-MM-dd');
                    if(results.size() == 2) {
                        if(!productMovementDatesMap.containsKey(movementDate)) productMovementDatesMap.put(movementDate, new Set<Id>());
                        productMovementDatesMap.get(movementDate).add(productId);
                    } else {
                        Id commercialPlanDetailId = (Id) results[2];
                        promoDetailIdMap.put(commercialPlanDetailId, productId);
                    }
                }
            }
            if (wFilterWrapper.isShowHistoryNego != null && wFilterWrapper.isShowHistoryNego && !isExport) {
                historyRts.add('Nego');
            }
            if (wFilterWrapper.productSearchTerm != null && String.isNotBlank(wFilterWrapper.productSearchTerm.trim())) {
                wFilterWrapper.productSearchTerm = wFilterWrapper.productSearchTerm.trim();
                String productSearchTerm = '('; 
                if (!SObjectType.Product2.fields.ProductCode.isEncrypted()) {
                    productSearchTerm += ' Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                } else {
                    productSearchTerm += ' Product__r.ProductCode = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.ProductCode = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                }
                if (!SObjectType.Product2.fields.Product_EAN__c.isEncrypted()) {
                    productSearchTerm += ' OR Product__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                } else {
                    productSearchTerm += ' OR Product__r.Product_EAN__c = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Product_EAN__c = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                }
                if (!SObjectType.Product2.fields.Product_Name__c.isEncrypted()) {    
                    productSearchTerm += ' OR Product__r.Product_Name__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Product_Name__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                } else {
                    productSearchTerm += ' OR Product__r.Product_Name__c = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Product_Name__c = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                }
                if (!SObjectType.Product2.fields.Product_Name__c.isEncrypted()) {    
                    productSearchTerm += ' OR Product__r.Name LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Name LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                } else {
                    productSearchTerm += ' OR Product__r.Name = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                    productSearchTerm += ' OR Product__r.Reference_Product__r.Name = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                }
                if (!SObjectType.Product2.fields.Product_EAN__c.isEncrypted()) {
                    productSearchTerm += ' OR Product_linked__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '%\'';
                } else {
                    productSearchTerm += ' OR Product_linked__r.Product_EAN__c = \'' + String.escapeSingleQuotes(wFilterWrapper.productSearchTerm) + '\'';
                }
                productSearchTerm += ')';
                conditions.add(productSearchTerm);
            }
            if (!wFilterWrapper.isShowRegularOfPromo || (isAggregation && !isExport) || !wFilterWrapper.isOnlyPromo) {
                if (wFilterWrapper.promoSearchTerm != null && String.isNotBlank(wFilterWrapper.promoSearchTerm)) {
                    wFilterWrapper.promoSearchTerm = wFilterWrapper.promoSearchTerm.trim();
                    String promoSearchTerm = '(';
                    if (!SObjectType.CommercialPlan__c.fields.Name.isEncrypted()) {
                        promoSearchTerm += ' (Promo_Event__r.Name LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '%\'';
                    } else {
                        promoSearchTerm += ' (Promo_Event__r.Name = \'' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '\'';
                    }
                    if (!SObjectType.CommercialPlan__c.fields.Name.isEncrypted()) {
                        promoSearchTerm += ' OR Promo_Event__r.Code__c LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '%\'';
                    } else {
                        promoSearchTerm += ' OR Promo_Event__r.Code__c = \'' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '\'';
                    }
                    if (!SObjectType.CommercialPlanDetail__c.fields.OpName__c.isEncrypted()) {
                        promoSearchTerm += ' OR Promo_Event_Detail__r.Name LIKE \'%' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '%\')';
                    } else {
                        promoSearchTerm += ' OR Promo_Event_Detail__r.Name = \'' + String.escapeSingleQuotes(wFilterWrapper.promoSearchTerm) + '\')';
                    }
                    promoSearchTerm += ')';
                    conditions.add(promoSearchTerm);
                }
            }
            if (wFilterWrapper.selectedCategoryId != null && String.isNotBlank(wFilterWrapper.selectedCategoryId)) {
                if (!SObjectType.Assortment_PriceWaterFall__c.fields.Hierarchy__c.isEncrypted()) {
                    Hierarchy__c selectedCateg = [SELECT Path__c FROM Hierarchy__c WHERE Id = :wFilterWrapper.selectedCategoryId];
                    conditions.add('(Hierarchy__r.Path__c LIKE \'' + String.escapeSingleQuotes(selectedCateg.Path__c.trim()) + '%\')');
                }
            }
            if (wFilterWrapper.minMovementDate != null && String.isNotBlank(wFilterWrapper.minMovementDate)) {
                conditions.add('(Movement_Date__c >=' + wFilterWrapper.minMovementDate + ')');
            }
            if (wFilterWrapper.maxMovementDate != null && String.isNotBlank(wFilterWrapper.maxMovementDate)) {
                conditions.add('(Movement_Date__c <=' + wFilterWrapper.maxMovementDate + ')');
            }
            if (!wFilterWrapper.isShowRegularOfPromo || (isAggregation && !isExport) || !wFilterWrapper.isOnlyPromo) {
                if (wFilterWrapper.minPromoDate != null && String.isNotBlank(wFilterWrapper.minPromoDate) /*&& wFilterWrapper.dateOperator != null && String.isNotBlank(wFilterWrapper.dateOperator)*/) {
                    Date mvtDate = Date.valueOf(wFilterWrapper.minPromoDate);
                    conditions.add('(Promo_Event_Detail_BDate__c >= ' + wFilterWrapper.minPromoDate + ')');
                }
                if (wFilterWrapper.maxPromoDate != null && String.isNotBlank(wFilterWrapper.maxPromoDate) /*&& wFilterWrapper.dateOperator != null && String.isNotBlank(wFilterWrapper.dateOperator)*/) {
                    Date mvtDate = Date.valueOf(wFilterWrapper.maxPromoDate);
                    conditions.add('(Promo_Event_Detail_EDate__c <= ' + wFilterWrapper.maxPromoDate + ')');
                }
            }
            if (wFilterWrapper.isOnlySwitchProduct != null && wFilterWrapper.isOnlySwitchProduct) {
                conditions.add('Product__r.Reference_Product__c <> NULL');
            }
            List<String> subcondition = new List<String>();
            if (!wFilterWrapper.isShowRegularOfPromo || (isAggregation && !isExport) || !wFilterWrapper.isOnlyPromo) {
                if (wFilterWrapper.isOnlyProduct != null && !wFilterWrapper.isOnlyProduct && wFilterWrapper.isOnlyPromo != null && !wFilterWrapper.isOnlyPromo) {
                    conditions.add(' Promo_Event_Detail__c = NULL AND Product__c = NULL');
                }
                if (wFilterWrapper.isOnlyProduct != null && wFilterWrapper.isOnlyProduct) {
                    subcondition.add('(Promo_Event_Detail__c = NULL )');
                }
                if (wFilterWrapper.isOnlyPromo != null && wFilterWrapper.isOnlyPromo) {
                    subcondition.add('(Promo_Event_Detail__c <> NULL)');
                }
                if(!subcondition.isEmpty()) {
                    conditions.add('(' + String.join(subcondition, ' OR ') + ')');
                }
            }
            if (String.isNotBlank(recordId)) {
                conditions.add('Assortment_BU__c = \'' + String.escapeSingleQuotes(recordId) + '\'');
            }
            if (recordsIdsList != null && !recordsIdsList.isEmpty()) {
                conditions.add('(Id IN (\'' + String.join(recordsIdsList, '\',\'') + '\'))');
            }
            List<String> orConditions = new List<String> ();
            if (!rts.isEmpty()) {
                orConditions.add('(Version__c = NULL AND RecordType.DeveloperName IN (\'' + String.join(rts, '\',\'') + '\') AND Status__c <> \'Archived\')');
            }
            if (!historyRts.isEmpty() && wFilterWrapper.multiStatusSelect != null && !wFilterWrapper.multiStatusSelect.isEmpty()) {
                orConditions.add('(Status__c IN (\'' + String.join(new List<String>(wFilterWrapper.multiStatusSelect) , '\',\'') +'\'))');
            }
            if (!orConditions.isEmpty()) {
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            orConditions = new List<String> ();
            if (promoDetailIdMap != null && !promoDetailIdMap.isEmpty()) {
                orConditions.add('(Promo_Event_Detail__c IN (\'' + String.join(new List<Id>(promoDetailIdMap.keySet()), '\',\'') + '\') AND Product__c IN (\'' + String.join(new List<Id>(promoDetailIdMap.values()), '\',\'') + '\'))');
            }
            if(productMovementDatesMap != null && !productMovementDatesMap.isEmpty()) {
                for(String movementDate : productMovementDatesMap.keySet()) {
                    orConditions.add('(Movement_Date__c = ' + movementDate + ' AND Product__c IN (\'' + String.join(new List<Id>(productMovementDatesMap.get(movementDate)), '\',\'') + '\') AND Promo_Event_Detail__c = NULL)');
                }
            }
            if (!orConditions.isEmpty()) {
                conditions.add('(' + String.join(orConditions, ' OR ') + ')');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id setStatusPriceWaterFall(String pwfListJson, String assortmentListJson) {
        try {
            Set<Id> PWFIds = (Set<Id>) JSON.deserialize(pwfListJson, Set<Id>.class);
            Set<Id> assortmentIds = (Set<Id>) JSON.deserialize(assortmentListJson, Set<Id>.class);
            // return NegoptimBatch.executeBatch(new APWToPGBatch(APWMatrixCmpController.class.getName(), assortmentIds, PWFIds, null, null), 50);
            Map<String, Object> params = new Map<String, Object>{
                'startedFrom' => APWMatrixCmpController.class.getName(),
                'assortmentBUIds' => assortmentIds,
                'assortmentPriceWaterFallsIds' => PWFIds
            };
            params.put('productIds', null);
            params.put('years', null);
            return NegoptimBatch.executeBatch('APWToPGBatch', params, 50);

        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String search(String assortmentDataWrapper_JSON, String filterTerms, String recordId, List<String> prodPromoKey, Integer pageSize, Integer pageNumber, Boolean isExport, List<String> recordsIdsList) {
        AssortmentDataWrapper assortmentDataWrapper = (AssortmentDataWrapper)JSON.deserialize(assortmentDataWrapper_JSON, AssortmentDataWrapper.class);
        try {
            String query = buildQuery(assortmentDataWrapper.gridSettingsManager, filterTerms, recordId, prodPromoKey, pageSize, pageNumber, isExport, recordsIdsList);
            system.debug('buildQuery >>> ' + query);
            Integer totalSize = getDataSize(filterTerms, recordId, prodPromoKey, pageSize, pageNumber, isExport, recordsIdsList, false, true);
            List<Assortment_PriceWaterFall__c> aspw = Database.query(query);  // list of assortment price waterFall
            Map<String, ProductWrapper> productWrapperMap = new Map<String, ProductWrapper>();
            List<Assortment_PriceWaterFall__c> assortmentPriceWaterFallsNegoList = new List<Assortment_PriceWaterFall__c>();
            List<Assortment_PriceWaterFall__c> assortmentPriceWaterFallsHistoryListNego = new List<Assortment_PriceWaterFall__c>();
            Map <Id,CategoryWrapper> categoryWrapperMap = new Map<Id, CategoryWrapper>();
            for (Assortment_PriceWaterFall__c item : aspw) {
                if (item.Version__c == null) {
                    assortmentPriceWaterFallsNegoList.add(item);
                } else {
                    assortmentPriceWaterFallsHistoryListNego.add(item);
                }
            }
            fillCategoryWrapper(assortmentDataWrapper, categoryWrapperMap, assortmentPriceWaterFallsNegoList, false, productWrapperMap);
            fillCategoryWrapper(assortmentDataWrapper, categoryWrapperMap, assortmentPriceWaterFallsHistoryListNego, false, productWrapperMap);
            assortmentDataWrapper.wCategoryList = categoryWrapperMap.values();
            assortmentDataWrapper.totalSize = totalSize;
            return JSON.serialize(assortmentDataWrapper);
        } catch (DmlException ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception e) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(e.getMessage() );
            System.debug(e.getStackTraceString() );
            System.debug(' >>> ' + e.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Integer getDataSize(String filterTerms,String recordId, List<String> prodPromoKey, Integer pageSize, Integer pageNumber, boolean isExport, List<String> recordsIdsList, Boolean isAggregation, Boolean calculateTotalSize) {
        List<String> conditions = getConditions(filterTerms, recordId, prodPromoKey, null, null, false, recordsIdsList, false, calculateTotalSize);
        String query = 'SELECT count(Id) aswfCount';
        query += ' FROM Assortment_PriceWaterFall__c';
        query += ' WHERE ' + String.join(conditions, ' AND ');
        query += ' AND ScheduledForWithdrawal__c = FALSE';
        Integer aswfCount = 0;
        AggregateResult[] aggregateResultList = Database.query(query);
        for (AggregateResult item : aggregateResultList) {
            aswfCount = (Integer) item.get('aswfCount');
        }
        return aswfCount;
    }
    
    private static void fillCategoryWrapper(AssortmentDataWrapper assortmentDataWrapper, Map <Id,CategoryWrapper> categoryWrapperMap, List<Assortment_PriceWaterFall__c> assortmentPriceWaterFalls, Boolean isSatement, Map<String, ProductWrapper> productWrapperMap) {
        String key;
        for (Assortment_PriceWaterFall__c item : assortmentPriceWaterFalls) {
            Assortment_PriceWaterFall__c initialAssortmentPWF = item.Clone(true);
            CategoryWrapper categoryWrapper; ProductWrapper productWrapper;
            key = initialAssortmentPWF.Product__c + ';' + initialAssortmentPWF.Movement_Date__c + ';' + initialAssortmentPWF.Promo_Event_Detail__c;
            if (!categoryWrapperMap.containsKey(initialAssortmentPWF.Hierarchy__c)) {
                categoryWrapper = new CategoryWrapper(initialAssortmentPWF.Hierarchy__c, initialAssortmentPWF.Hierarchy__r.Name);
            } else {
                categoryWrapper = categoryWrapperMap.get(initialAssortmentPWF.Hierarchy__c);
            }
            categoryWrapperMap.put(initialAssortmentPWF.Hierarchy__c, categoryWrapper);
            // fill product wrapper
            if (!productWrapperMap.containsKey(key)) {
                productWrapper = new ProductWrapper();
                categoryWrapper.productWrapperList.add(productWrapper);
                productWrapperMap.put(key, productWrapper);
            } else {
                productWrapper = productWrapperMap.get(key);
            }
            if (initialAssortmentPWF.Version__c == null) {
                productWrapper.assortmentPWFNegoWrapper = initialAssortmentPWF;
            } else {
                productWrapper.historyList.add(initialAssortmentPWF);
                productWrapper.historyList.sort();
            }
        }
    }
    
    /*
     * @description import records from excel imported
     */ 
    @AuraEnabled
    public static List<String> importRecords(List<String> fields, List<String> fieldsToUpdate, String xlsData) {
        try {
            String objectName = prefix + 'Assortment_PriceWaterFall__c';
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            List<String> scope = new List<String>();
            List<List<String>> records = new List<List<String>>();
            String dateFormat = settings.csvDateFormat;
            Map<Id, Sobject> pwfUpsertedRecords = new Map<Id, Sobject>();
            Map<String, Schema.SObjectField> pwfFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            if (String.isNotBlank(xlsData)) {
                scope = xlsAsScope(xlsData, settings.delimiter);
            }
            records = NegoptimHelper.parseCSV(scope, settings.delimiter);
            for (Integer index = 2 ; index < records.size() ; index++) {
                List<String> row = records[index];
                if (row.size() < fields.size()) {
                    for (Integer i = row.size() ; i < fields.size(); i++) {
                        row.add('');
                    }
                }
            }
            List<String> eanList = new List<String>();
            Map<Id, Id> prodPGMap = new Map<Id, Id>();
            Map<Id, String> prodCategMap = new Map<Id, String>();
            Map<Id, String> pgCategMap = new Map<Id, String>();
            for (Integer index = 2 ; index < records.size() ; index++) {
                sObject pwf = Schema.getGlobalDescribe().get(objectName).newSObject();
                DescribeFieldResult dfr;
                List<String> row = records[index];
                for (Integer i = 0; i < fields.size(); i++) {
                    String field = fields[i];
                    if (field == SObjectType.Product2.fields.Product_EAN__c.Name && String.isNotBlank(row[i])) {
                        eanList.add(row[i]);
                    }
                    if (field == 'Id' && String.isNotBlank(row[i])) {
                        pwf.Id = row[i];
                    }
                    if (!fieldsToUpdate.contains(field)) {
                        continue;
                    }
                    String fieldType;
                    
                    fieldType = String.valueOf(pwfFields.get(field).getDescribe().getType()) ;
                    dfr =  pwfFields.get(field).getDescribe();
                    if (!dfr.isUpdateable()) {
                        continue;
                    }
                    if(pwfFields.containsKey(field)) {
                        if (fieldType == 'BOOLEAN') {
                            pwf.put(field, String.isNotBlank(row[i]) ? Boolean.valueOf(row[i]) : false);
                        } else if (fieldType == 'PICKLIST') {
                            String pickVal = null;
                            if (String.isNotBlank(row[i])) {
                                for (Schema.PicklistEntry item : dfr.getPicklistValues()) {
                                    if (row[i] == item.getValue() || row[i] == item.getLabel()) {
                                        pickVal = item.getValue();
                                    }
                                }
                            }
                            pwf.put(field, pickVal);
                        } else if (fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT') {
                            Decimal decimalValue = String.isNotBlank(row[i]) ? Decimal.valueOf(row[i].replace('"', '').replace('%', '').trim()) : null;
                            pwf.put(field, decimalValue != null ? decimalValue.setScale(dfr.getscale()) : decimalValue);
                        } else if (fieldType == 'DATE') {
                            pwf.put(field, String.isNotBlank(row[i]) ? NegoptimDate.parseDate(Date.valueOf(row[i]).format(), dateFormat) : null);
                        } else if(fieldType == 'DATETIME') {
                            pwf.put(field, String.isNotBlank(row[i]) ? DateTime.Valueof(row[i].replace('T', ' ')): null);
                        } else if (fieldType == 'INTEGER') {
                            pwf.put(field, String.isNotBlank(row[i]) ? Integer.valueOf(row[i]) : null);
                        } else if (fieldType == 'STRING' || fieldType == 'TEXTAREA') {
                            pwf.put(field, String.isNotBlank(row[i]) ? String.valueOf(row[i]).unescapeJava() : null);
                        } else {
                            pwf.put(field, String.isNotBlank(row[i]) ? String.valueOf(row[i]) : null);
                        }
                    }
                }
                pwfUpsertedRecords.put(pwf.Id, pwf);
            }
            String errorMessage = '';
            List<String> errorMessages = new List<String>();
            if (!pwfUpsertedRecords.isEmpty()) {
                List<Database.SaveResult> results = Database.update(pwfUpsertedRecords.values(), false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (!result.isSuccess()) {
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessages.add(eanList.get(i) + ' : ' + err.getMessage());
                        }
                    }
                }
            }
            return errorMessages;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //TO DO : add this method inside import services
    private static List<String> xlsAsScope (String xlsData, String delimiter) {
        String errorMessage = '';
        List<String> scope = new List<String>();
        try {
            List<Object> input = (List<Object>)JSON.deserializeUntyped(xlsData);
            Integer index = 0;
            List<String> fieldsList;
            for (Object obj : input/*.Values()*/) {
                String row;
                Map<String, Object> importedMap = (Map<String, Object>)obj;
                if (fieldsList == null) {
                    fieldsList = new List<String>(importedMap.keySet());
                }
                if (index == 0) {
                    for (String key : importedMap.keySet()) {
                        row += key + delimiter;
                    }
                    scope.add(row);
                }
                row = '';
                for(String field : fieldsList) {
                    if (importedMap.containsKey(field)) {
                        row += importedMap.get(field) + delimiter;
                    } else {
                        row += '' + delimiter;
                    }
                }
                scope.add(row);
                index++;
            }
            return scope;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String save(String recordsMap) {
        Map<String, Assortment_PriceWaterFall__c> changedData = (Map<String, Assortment_PriceWaterFall__c>)JSON.deserialize(recordsMap, Map<String, Assortment_PriceWaterFall__c>.class);
        Savepoint sp = Database.setSavepoint();
        try {
            List<Assortment_PriceWaterFall__c> records = changedData.values();
            Database.UpsertResult[] saveResult = Database.upsert(records);
            DmlResultWrapper dmlResultWrapper = new DmlResultWrapper();
            for (Integer index = 0; index < saveResult.size() && index < records.size();  index++) {
                Database.UpsertResult result = saveResult[index];
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    for (Database.Error error : result.getErrors()) {
                        errorMessage += error.getStatusCode() + ' - ' + error.getFields() + ' - ' + error.getMessage();
                    }
                    dmlResultWrapper.errors.add(errorMessage);
                    dmlResultWrapper.isSuccess = false;
                }
            }
            return JSON.serialize(dmlResultWrapper);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug(' >>> ' + ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String fakeSave(String assortmentDataWrapper_JSON, String recordsMap, String filterTerms, String recordId, list<String> prodPromoKey, Integer pageSize, Integer pageNumber) {
        Savepoint sp = Database.setSavepoint();
        AssortmentDataWrapper assortmentDataWrapper = (AssortmentDataWrapper)JSON.deserialize(assortmentDataWrapper_JSON, AssortmentDataWrapper.class);
        Map<String, Assortment_PriceWaterFall__c> changedData = (Map<String, Assortment_PriceWaterFall__c>)JSON.deserialize(recordsMap, Map<String, Assortment_PriceWaterFall__c>.class);
        List<String> apwIdsList = new List<String>();
        Map<String, String> errorMessages = new Map<String, String>();
        Map<Integer, String> indexesMap = new Map<Integer, String>();
        Map<String, SObject> newRecords = new Map<String, SObject>();
        List<String> recordsIdsList = new List<String>();
        List<Sobject> records = new List<Sobject>();
        List<String> mapKeySet = new List<String> (changedData.keySet());
        for (Integer i = 0 ; i < mapKeySet.size() ; i++ ) {
            indexesMap.put(i,mapKeySet[i]);
            records.add(changedData.get(mapKeySet[i]));
        }
        Database.UpsertResult[] saveResult = Database.upsert(records);
        for (Integer index = 0; index < saveResult.size() && index < records.size();  index++) {
            Database.UpsertResult result = saveResult[index];
            if (!result.isSuccess()) {
                List<String> errors = new List<String>();
                for (Database.Error error : result.getErrors()) {
                    errors.add(error.getStatusCode() + ' - ' + error.getFields() + ' - ' + error.getMessage());
                }
                errorMessages.put(indexesMap.get(index), String.join(errors, ', '));
            } else {
                newRecords.put(indexesMap.get(index), changedData.get(indexesMap.get(index)));
            }
        }
        for (String key : newRecords.keySet()) {
            recordsIdsList.add(key);
        }
        String results = search(assortmentDataWrapper_JSON, filterTerms, recordId, prodPromoKey, pageSize, pageNumber, false, recordsIdsList);
        Database.rollback(sp);
        return results;
    }
    
    /** Wrapper class for assortmentBu. */
    public class AssortmentDataWrapper {
        public Assortment_BU__c assortmentBU;
        public GridSettingsManager gridSettingsManager {get;set;}
        public Boolean readOnlyUser;
        public List<FieldWrapper> displayedFields { get; set; }
        public List<String> dynamicDiscountsFields { get; set; }
        public List<String> dynamicTaxesFields { get; set; }
        public List<DynamicFieldsWrapper> displayedDynamicFields { get; set; }
        public List<CategoryWrapper> wCategoryList { get; set; }
        public Map<String, String> assortmentPriceWaterFallRTLabels {get; set;}
        public Integer totalSize {get; set;}
        Integer discountPercentScale;
        public AssortmentDataWrapper(Assortment_BU__c assortmentBU, GridSettingsManager gridSettingsManager) {
            this.assortmentBU = assortmentBU;
            this.gridSettingsManager = gridSettingsManager;
            this.dynamicDiscountsFields = new List<String>();
            this.dynamicTaxesFields = new List<String>();
            this.displayedDynamicFields = new List<DynamicFieldsWrapper>();
            this.wCategoryList = new List<CategoryWrapper>();
            // Check read Only User
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            this.discountPercentScale = settings.discountPercentScale;
            List<String> matrixProfiles = settings.assortmentMatrixProfile;
            this.readOnlyUser = matrixProfiles == null || matrixProfiles.isEmpty() || !matrixProfiles.contains(UserInfo.getProfileId()) || this.assortmentBU.Status__c == 'Closed';
            this.assortmentPriceWaterFallRTLabels = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Assortment_PriceWaterFall__c.SObjectType);
        }
    }
    public class DynamicFieldsWrapper {
        String groupFieldName { get; set; }
        String url { get; set; }
        Boolean isFieldGroup;
        Integer displayOrder;
        List<FieldWrapper> subFieldsList { get; set; }
        public DynamicFieldsWrapper() {
            this.isFieldGroup = false;
            this.subFieldsList = new List<FieldWrapper>();
        }
    }
    /** Wrapper class for Category */
    public class CategoryWrapper {
        public Id categoryId { get; set; }
        public String categoryName { get; set; }
        public List<ProductWrapper> productWrapperList { get; set; }
        public CategoryWrapper(Id categoryId, String categoryName) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            this.productWrapperList = new List<ProductWrapper>();
        }
    }
    
    // /** Wrapper class for Product */
    public class ProductWrapper {
        public Assortment_PriceWaterFall__c assortmentPWFNegoWrapper { get; set; }
        public List<Assortment_PriceWaterFall__c> historyList {get; set;}
        public String productKey {
            get {
                return assortmentPWFNegoWrapper?.Id + '_';
            }
            set;
        }
        public ProductWrapper() {
            historyList = new List<Assortment_PriceWaterFall__c>();
        }
    }
    /**
     * @author ULiT
     * @description wrapper class used to serialize and deserialize active taxes on the level of Assortment BUs/Net Price Statement
     */
    public class StatementWrapper {
        public String recordId {get; set;}
        // the name of the Tax__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Tax__c / 1-9 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        // statement type for discont statements (U, %)
        public String conditionMode {get; set;}
        public String fieldApiName {get; set;}
        public StatementWrapper(Id recordId, String Name, Integer displayOrder, String conditionMode,String fieldApiName) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.conditionMode = conditionMode;
            this.fieldApiName = fieldApiName;
        }
        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this(recordId, Name, displayOrder, '', '');
        }
    }
    
    public class FilterTermWrapper {
        public String productSearchTerm {get; set;}
        public String promoSearchTerm {get; set;}
        public String minMovementDate {get; set;}
        public String maxMovementDate {get; set;}
        public String minPromoDate {get; set;}
        public String maxPromoDate {get; set;}
        public String categorySearchTerm {get; set;}
        public String selectedCategoryId {get; set;}
        public String dateOperator {get; set;}
        public List<String> multiStatusSelect {get; set;}
        public Boolean isOnlySwitchProduct {get; set;}
        public Boolean isOnlyProduct {get; set;}
        public Boolean isOnlyPromo {get; set;}
        public Boolean isShowHistoryNego {get; set;}
        public Boolean isShowRegularOfPromo {get; set;}
        public Boolean isNego {get; set;}
        public FilterTermWrapper() {
            this.productSearchTerm = '';
            this.promoSearchTerm = '';
            this.minMovementDate = '';
            this.maxMovementDate = '';
            this.categorySearchTerm = '';
            this.selectedCategoryId = '';
            this.dateOperator = '';
            this.multiStatusSelect = new List<String>();
            this.isShowHistoryNego = true;
            this.isShowRegularOfPromo = true;
            this.isOnlySwitchProduct = false;
            this.isOnlyProduct = true;
            this.isOnlyPromo = true;
            this.isNego = true;
        }
    }
    
    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public List<Schema.PicklistEntry> picklistValues;
        public Boolean isInputField;
        public Integer displayOrder;
        public String url;
        public String style;
        public Integer scale;
        public Boolean applyValue;
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, List<Schema.PicklistEntry> picklistValues, Boolean isInputField, Integer displayOrder, String style, Integer scale, Boolean applyValue) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.picklistValues = picklistValues;
            this.isInputField = isInputField;
            this.displayOrder = displayOrder;
            this.style = style;
            this.scale = scale;
            this.applyValue = applyValue;
        }
    }
    
    class DmlResultWrapper {
        public List<String> errors { get; set; }
        public Boolean isSuccess { get; set; }
        public DmlResultWrapper() {
            this.errors = new List<String>();
            this.isSuccess = true;
        }
    }
}