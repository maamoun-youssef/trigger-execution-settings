/**
 * @author ULiT
 * @date 28/01/2025
 * @description Apex class to View SellinStatements
 * */
public with sharing class SellinCollaborativeRestitutionController {

    @AuraEnabled
    public static String initData() {
        List<FieldWrapper> fields = new List<FieldWrapper>();
        FieldWrapper field;
        Schema.DescribeFieldResult dfr;
        dfr = SObjectType.SellinStatement__c.fields.PeriodNumber__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.SellInStatement__c.Name) + '.' +
         SObjectType.SellInStatement__c.fields.PeriodNumber__c.Name, dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        dfr = SObjectType.BusinessUnit__c.fields.Name;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.BusinessUnit__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name, dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        dfr = SObjectType.SellInStatementDetail__c.fields.Status__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field); 
        dfr = SObjectType.SellInStatementDetail__c.fields.Status__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, 'LBL_RequiredAction', NegoptimLabels.getCustomLabel('LBL_RequiredAction', ''), null, 'FORMULA', new List<Schema.PicklistEntry> ());
        fields.add(field);
        dfr = SObjectType.SellInStatement__c.fields.PeriodType__c;
        field = new FieldWrapper(SObjectType.SellInStatement__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        List<String> staticFieldsList = new List<String> {
            SObjectType.SellInStatementDetail__c.fields.BusinessUnit__c.Name,
            SObjectType.SellInStatementDetail__c.fields.NegoScopeReference__c.Name,
            SObjectType.SellInStatementDetail__c.fields.Status__c.Name,
            SObjectType.SellInStatementDetail__c.fields.SellInStatement__c.Name,
            SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name,
            SObjectType.SellInStatementDetail__c.fields.CustomBDate__c.Name,
            SObjectType.SellInStatementDetail__c.fields.CustomEDate__c.Name,
            SObjectType.SellInStatementDetail__c.fields.IsCustomDateRange__c.Name
        };
        List<String> sellInRevenueOptions = connectSettings.sellInRevenueOptions;
        List<String> discFieldsList = new List<String> ();
        // SellIn Disc Regular
        if(sellInRevenueOptions.contains('LBL_Connect_RegularDiscountableRevenue')) {
            discFieldsList.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularP__c.Name);
            discFieldsList.add(SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularP__c.Name);
            discFieldsList.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularYTD__c.Name);
            discFieldsList.add(SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularYTD__c.Name);
            discFieldsList.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularTTM__c.Name);
            discFieldsList.add(SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularTTM__c.Name);
            discFieldsList.add(SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularSfx__c.Name);
        }
        // SellIn Disc Promo
        if (sellInRevenueOptions.contains('LBL_Connect_PromoDiscountableRevenue')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoSfx__c.Name
            );
        }
        // SellIn Disc Total
        if (sellInRevenueOptions.contains('LBL_Connect_TotalDiscountableRevenue')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalSfx__c.Name
            );
        }
        // SellIn Non Disc
        if (sellInRevenueOptions.contains('LBL_Connect_NonDiscountableRevenue')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscSfx__c.Name
            );
        }
        // SellIn Disc Regular Qty
        if (sellInRevenueOptions.contains('LBL_Connect_RegularDiscountableQuantity')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtySfx__c.Name
            );
        }
        // SellIn Disc Promo Qty
        if (sellInRevenueOptions.contains('LBL_Connect_PromoDiscountableQuantity')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtySfx__c.Name
            );
        }
        // SellIn Disc Total Qty
        if (sellInRevenueOptions.contains('LBL_Connect_TotalDiscountableQuantity')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtySfx__c.Name
            );
        }
        // SellIn Non Disc Qty
        if (sellInRevenueOptions.contains('LBL_Connect_NonDiscountableQuantity')) {
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyP__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyP__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyYTD__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyYTD__c.Name
            );
            discFieldsList.add(
                NegoptimHelper.getFieldNameAsRelation(
                    SObjectType.SellInStatementDetail__c.fields.SellInStatementDetail_P1__c.Name
                ) + '.' + SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyTTM__c.Name
            );
            discFieldsList.add(
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtySfx__c.Name
            );
        }
        // build wrapper
        ResultWrapper result = new ResultWrapper();
        result.sellInRevenueOptions = sellInRevenueOptions;
        result.discFields = discFieldsList;
        result.fields = fields;
        result.staticFieldsList = staticFieldsList;
        User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
        result.isPortal = user.ContactId != null;
        result.prefix = NegoptimHelper.getPackagePrefix(true);
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static String loadData(String resultWrapperJson, Integer pageNumber, Integer pageSize, List<String> conditions, String orderBy) {
        try {
            system.debug('resultWrapperJson: ' + resultWrapperJson);
            ResultWrapper resultWrapper = (ResultWrapper) JSON.deserialize(resultWrapperJson, ResultWrapper.class);
            String sellinStatementQuery = 'SELECT Id, SellInStatement__r.Name, SellInStatement__r.NegoScope__c, SellInStatement__r.NegoScope__r.Name, ';
            sellinStatementQuery += ' SellInStatement__r.ReferenceYear__c, SellInStatement__r.PeriodType__c, SellInStatement__r.PeriodNumber__c,';
            sellinStatementQuery += ' NegoScopeReference__r.Name,  BusinessUnit__r.Name, StatusLogo__c,';
            sellinStatementQuery += String.join(resultWrapper.staticFieldsList, ', ');
            sellinStatementQuery += ', ' + String.join(resultWrapper.discFields, ', ');
            sellinStatementQuery += ' FROM SellInStatementDetail__c ';
            sellinStatementQuery += ' WHERE SellInStatement__r.IsLastVersion__c = TRUE';
            if (!resultWrapper.isPortal) {
                sellinStatementQuery += ' AND Status__c <> \'In Preparation\'';
            }
            sellinStatementQuery += conditions != null && !conditions.isEmpty() ? ' AND (' + String.join(conditions, ' AND ') + ')': '';
            sellinStatementQuery += ' ORDER BY IsCustomDateRange__c, NegoScopeReference__c, CustomBDate__c, CustomEDate__c, SellInStatement__r.PeriodNumber__c';
            System.debug('sellinStatementQuery: ' + sellinStatementQuery);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(sellinStatementQuery));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            resultWrapper.totalSize = setController.getResultSize();
            resultWrapper.records = setController.getRecords();
            String SellinName = conditions != null && !conditions.isEmpty() && !resultWrapper.records.isEmpty()
                                ? resultWrapper.records[0].SellInStatement__r.NegoScope__r.Name + ' - ' + resultWrapper.records[0].SellInStatement__r.ReferenceYear__c
                                : null ;
            System.debug('SellinName: ' + SellinName);
            System.debug('resultWrapper: ' + JSON.serialize(resultWrapper));
            resultWrapper.sellinStatementName = SellinName;
            return JSON.serialize(resultWrapper);

        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String objectName;
        public String fieldName;
        public String fieldLabel;
        public String fieldHelpText;
        public String fieldType;
        public List<Map<String, String>> picklistValues;
        public FieldWrapper(String objectName, String fieldName, String fieldLabel, String fieldHelpText, String fieldType, List<Schema.PicklistEntry> picklistValues) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldHelpText = fieldHelpText;
            this.fieldType = fieldType;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
    }
    public class ResultWrapper {
        public Boolean isPortal {get; set;}
        public String prefix {get; set;}
        public List<FieldWrapper> fields { get; set; }
        public List<String> staticFieldsList { get; set; }
        public List<String> discFields { get; set; }
        public List<String> sellInRevenueOptions { get; set;}
        public Integer totalSize {get;set;}
        List<SellInStatementDetail__c> records {get; set;}
        public String sellinStatementName {get; set;}
        public ResultWrapper() {
            this.fields = new List<FieldWrapper>();
            this.staticFieldsList = new List<String>();
            this.discFields = new List<String>();
            this.sellInRevenueOptions = new List<String>();
        }
    }
}