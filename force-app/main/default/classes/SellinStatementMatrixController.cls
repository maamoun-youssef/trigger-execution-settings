/**
 * @author ULiT
 * @date 28/01/2025
 * @description Apex class to View SellinStatements
 * */
public with sharing class SellinStatementMatrixController {

    @AuraEnabled
    public static String initData() {
        List<FieldWrapper> fields = new List<FieldWrapper>();
        FieldWrapper field;
        Schema.DescribeFieldResult dfr;
        Map<String, schema.SObjectField> sellInStatementDetailFieldsMap = SellInStatementDetail__c.SObjectType.getDescribe().fields.getMap();
        dfr = SObjectType.SellInStatementDetail__c.fields.ExtId__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        //fields.add(field);
        dfr = SObjectType.SellInStatementDetail__c.fields.SellInStatementBase__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        dfr = SObjectType.NegoScope__c.fields.Comment__c;
        field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, NegoptimHelper.getFieldNameAsRelation(SObjectType.SellInStatementDetail__c.fields.NegoScopeReference__c.Name) + '.' +
                                SObjectType.NegoScope__c.fields.Comment__c.Name, dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        List<String> sellInStatementDetailFields = new List<String> {
            SObjectType.SellInStatementDetail__c.fields.BusinessUnit__c.Name,
            SObjectType.SellInStatementDetail__c.fields.Status__c.Name,
            SObjectType.SellInStatementDetail__c.fields.CurrencyIsoCode.Name
        };
        for(String fieldName : sellInStatementDetailFields) {
            dfr = sellInStatementDetailFieldsMap.get(fieldName).getDescribe();
            field = new FieldWrapper(SObjectType.SellInStatementDetail__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
            fields.add(field);
        }
        dfr = SObjectType.SellInStatement__c.fields.Status__c;
        field = new FieldWrapper(SObjectType.SellInStatement__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        dfr = SObjectType.SellInStatement__c.fields.PeriodType__c;
        field = new FieldWrapper(SObjectType.SellInStatement__c.Name, dfr.getName(), dfr.getLabel(), dfr.getInlineHelpText(), dfr.getType().Name(), dfr.getPicklistValues());
        fields.add(field);
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        // build wrapper
        ResultWrapper result = new ResultWrapper();
        result.prefix = NegoptimHelper.getPackagePrefix(true);
        result.fields = fields;
        result.warningMsg = NegoptimLabels.getCustomLabel('MSG_Warning_SellInDiscRegularP_Empty', 'Attention, il y a des périmètres où le CA n\'est pas déclaré ou à 0. Veuillez confirmer votre sauvegarde ou retourner à l\'étape précédente.');
        result.stepMismatchMsg = NegoptimLabels.getCustomLabel('LBL_SellinStepMismatchMsg', 'Dans l\'écran \"Restitution Collaborative\", l\'affichage sera arrondi');
        result.sellInWelcomeMessage = connectSettings.sellInWelcomeMessage;
        result.sellInRevenueOptions = connectSettings.sellInRevenueOptions;
        result.sellInSubmissionFlow = connectSettings.sellInSubmissionFlow;
        User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
        result.isPortal = user.ContactId != null;
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String loadData(Integer pageNumber, Integer pageSize, String negoScopeId, Integer referenceYear, String periodType, Integer periodNumber, List<String> conditions)
    {
        try {
            string periodFields = getPeriodFields();
            ResultWrapper result = new ResultWrapper();
            String sellinStatementQuery = 'SELECT Id, SellInStatement__r.Name, SellInStatement__r.NegoScope__c, SellInStatement__r.NegoScope__r.Name, SellInStatement__r.NegoScope__r.Supplier__c, SellInStatement__r.NegoScope__r.Supplier__r.Name, SellInStatement__r.NegoScope__r.Owner.Name, IsCustomDateRange__c, CustomBDate__c, CustomEDate__c,';
            sellinStatementQuery += ' SellInStatement__r.ReferenceYear__c, SellInStatement__r.PeriodType__c, SellInStatement__r.PeriodNumber__c, SellInStatement__r.Status__c, SellInStatement__r.StatusLogo__c, Status__c,';
            sellinStatementQuery += ' ExtId__c, SellInStatementBase__c, NegoScopeReference__c, BusinessUnit__c, NegoScopeReference__r.Name, NegoScopeReference__r.Comment__c, BusinessUnit__r.Name, CurrencyIsoCode, StatusLogo__c ,';
            sellinStatementQuery += periodFields;
            sellinStatementQuery += ' FROM SellInStatementDetail__c';
            sellinStatementQuery += ' WHERE SellInStatement__r.IsLastVersion__c = TRUE';
            if(String.isNotBlank(negoScopeId)) {
                sellinStatementQuery += ' AND SellInStatement__r.NegoScope__c = \'' + String.escapeSingleQuotes(negoScopeId) + '\'';
            }
            if(String.isNotBlank(periodType)) {
                sellinStatementQuery += ' AND SellInStatement__r.PeriodType__c = \'' + String.escapeSingleQuotes(periodType) + '\'';
            }
            if(referenceYear != null) {
                sellinStatementQuery += ' AND SellInStatement__r.ReferenceYear__c = ' + referenceYear;
            }
            if(periodNumber != null) {
                sellinStatementQuery += ' AND SellInStatement__r.PeriodNumber__c = ' + periodNumber;
            } else {
                sellinStatementQuery += ' AND SellInStatement__r.IsLastPeriod__c = TRUE';
            }
            sellinStatementQuery += conditions != null && !conditions.isEmpty() ? ' AND (' + String.join(conditions, ' AND ') + ')': '';
            sellinStatementQuery += ' ORDER BY BusinessUnit__r.Name ASC, NegoScopeReference__r.Name';
            System.debug('sellinStatementQuery >>> ' + sellinStatementQuery);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(sellinStatementQuery));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            result.totalSize = setController.getResultSize();
            result.records = setController.getRecords();
            String sellinStatementName = !result.records.isEmpty() && conditions != null && !conditions.isEmpty() ? result.records[0].SellInStatement__r.Name : null;
            result.sellinStatementName = sellinStatementName;
            if(!result.records.isEmpty()) {
                SellInStatement__c currentSellinStatement = result.records[0].SellInStatement__r;
                result.sellInStatementRecords = [SELECt Id, NegoScope__c, ReferenceYear__c, PeriodType__c, PeriodNumber__c, Status__c
                                                 FROM SellInStatement__c
                                                 WHERE NegoScope__c = :currentSellinStatement.NegoScope__c
                                                 AND ReferenceYear__c = :currentSellinStatement.ReferenceYear__c
                                                 AND PeriodType__c = :currentSellinStatement.PeriodType__c
                                                 ORDER BY PeriodNumber__c];
            }
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<string, List<string>> getPeriodFieldFromLabels() {
        return new Map<string, List<string>>{
            'LBL_Connect_RegularDiscountableRevenue' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularSfx__c.Name
            },
            'LBL_Connect_PromoDiscountableRevenue' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoSfx__c.Name
            },
            'LBL_Connect_TotalDiscountableRevenue' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalSfx__c.Name
            },
            'LBL_Connect_NonDiscountableRevenue' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscSfx__c.Name
            },
            'LBL_Connect_RegularDiscountableQuantity' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtyP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscRegularQtySfx__c.Name
            },
            'LBL_Connect_PromoDiscountableQuantity' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtyP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscPromoQtySfx__c.Name
            },
            'LBL_Connect_TotalDiscountableQuantity' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtyP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInDiscTotalQtySfx__c.Name
            },
            'LBL_Connect_NonDiscountableQuantity' => new List<string>{
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtyP__c.Name,
                SObjectType.SellInStatementDetail__c.fields.SellInNonDiscQtySfx__c.Name
            }
        };
    }

    private static string getPeriodFields () {
        string result ;
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        Map<string, List<string>> PeriodFieldFromLabels = getPeriodFieldFromLabels();
        list<string> fields = new list<string>();
        for (String key : connectSettings.sellInRevenueOptions) {
            fields.addAll(PeriodFieldFromLabels.get(key));
        }
        for(String field : fields){
            result = String.join(fields, ', ');
        }
        return result;
    }

    @AuraEnabled
    public static void savePeriods(string jsonString) {
        try {
            List<SellInStatementDetail__c> recordToUpdate = (List<SellInStatementDetail__c>) JSON.deserialize(jsonString, List<SellInStatementDetail__c>.class);
            if (!recordToUpdate.isEmpty()) {
                Database.update(recordToUpdate, true);
            }
        } catch (Exception e) {
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
        String negoScopeId {get; set;}
        Integer referenceYear {get; set;}
        String periodType {get; set;}
        Integer periodNumber {get; set;}
        List<FieldWrapper> fields { get; set; }
        string sellInWelcomeMessage { get; set;}
        List<String> sellInRevenueOptions { get; set;}
        string sellInSubmissionFlow {get; set;}
        public Integer totalSize {get;set;}
        public String warningMsg {get;set;}
        public String stepMismatchMsg {get;set;}
        List<SellInStatementDetail__c> records {get; set;}
        public String sellinStatementName {get; set;}
        List<SellInStatement__c> sellInStatementRecords {get; set;}
    }
}