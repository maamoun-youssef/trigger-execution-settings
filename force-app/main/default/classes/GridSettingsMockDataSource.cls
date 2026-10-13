public with sharing class GridSettingsMockDataSource {
    private static String templatesJSON = '[]';
    private static String prefix = NegoptimHelper.getPackagePrefix(true);
    private static String productTemplateJSON = '[{"Id":"m0209000000y5VhAAI","' + prefix + 'Master_Object_Name__c":"","DeveloperName":"Product","' + prefix + 'Object_Name__c":"Product2","' + prefix + 'Icon__c":"standard:orders","' + prefix + 'Type__c":"Detail","' + prefix + 'Relationship_Name__c":"", "MasterLabel":"ProductTemplate"}]';
    private static String GridTemplateJSON = '[{"Id":"m0209000000y5VhAAI","' + prefix + 'Master_Object_Name__c":"","DeveloperName":"ContactOperationalDirectory__c","' + prefix + 'Object_Name__c":"ContactOperationalDirectory__c","' + prefix + 'Icon__c":"standard:orders","' + prefix + 'Type__c":"Detail","' + prefix + 'Relationship_Name__c":"", "MasterLabel":"CODTemplate"}]';
    private static String contactAccountTemplateJSON = '[{"Id":"m0209000000y5VhAAI","' + prefix + 'Master_Object_Name__c":"Account","DeveloperName":"Account_Contact","' + prefix + 'Object_Name__c":"Contact","' + prefix + 'Icon__c":"standard:orders","' + prefix + 'Type__c":"None-Master-Detail","' + prefix + 'Relationship_Name__c":"", "MasterLabel":"Contacts"}]';
    private static String PDSDTemplateJSON = '[{"Id":"m0209000000y5VhAAI","' + prefix + 'Master_Object_Name__c":"ProductDiscountStatement__c","DeveloperName":"PDSD","' + prefix + 'Object_Name__c":"ProductDiscountStatementDetail__c","' + prefix + 'Icon__c":"standard:orders","' + prefix + 'Type__c":"None-Master-Detail","' + prefix + 'Relationship_Name__c":"", "MasterLabel":"PDSDTemplate"}]';
    private static String contactAccountV2TemplateJSON = '[{"Id":"m0209000000y5VhAAI","' + prefix + 'Master_Object_Name__c":"Contact","DeveloperName":"Account_ContactV2","' + prefix + 'Object_Name__c":"Account","' + prefix + 'Icon__c":"standard:orders","' + prefix + 'Type__c":"None-Master-Detail","' + prefix + 'Relationship_Name__c":"", "MasterLabel":"ContactAccountV2Template"}]';
    public static List<Grid_Settings__mdt> getTemplates(String metadataDeveloperName) {
        List<Grid_Settings__mdt> templateList = new List<Grid_Settings__mdt>();
        try {
            if (metadataDeveloperName == 'Product') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(productTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"CreatedDate","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"picklistColorsMap":{},"controllerFieldActions":[{"description":"Disable Created Date","criteria":{"expression":1,"rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER_OR_EQUALS","value":"2023-02-28T13:46:00.000Z"}}},"action":"DISABLE","criteriasList":[{"fieldName":"CreatedDate","operation":"GREATER_OR_EQUALS","value":"2023-02-28T13:46:00.000Z"}]}]},{"FieldName":"Name","isInputField":true},{"FieldName":"Family","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"picklistColorsMap":{"None":"#FFDEDE"},"controllerFieldActions":[]},{"FieldName":"CreatedDate","isInputField":false},{"FieldName":"CreatedById","isInputField":false},{"FieldName":"CreatedBy.Name","isInputField":false},{"FieldName":"","separatorSettings":{"borderSize":"1px","borderColor":"#000000","borderPatern":"solid","size":"1px","color":"#000000","pattern":"solid"}},{"FieldName":"ProductCode","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"isInputField":true},{"FieldName":"IsActive","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"picklistColorsMap":{},"controllerFieldActions":[{"description":"productCode is NULL","criteria":{"expression":1,"rulesMap":{"1":{"fieldName":"ProductCode","operation":"ISBLANK","value":""}}},"action":"DISABLE","criteriasList":[{"fieldName":"ProductCode","operation":"ISBLANK","value":""}]}]},{"FieldName":"DisplayUrl","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"isInputField":true,"picklistColorsMap":{},"controllerFieldActions":[{"description":"Display URl Control","criteria":{"expression":1,"rulesMap":{"1":{"fieldName":"ProductCode","operation":"EQUALS","value":"123"}}},"action":"WARNING_MESSAGE","criteriasList":[{"fieldName":"ProductCode","operation":"EQUALS","value":"123"}]}],"URLOption":"FullURL","replaceURLWith":""},{"FieldName":"ExternalId","nonConditional":{"textStyle":{"isItalic":false,"isCenter":false,"isUnderLine":false,"isStrikeThrought":false,"color":"","size":"","align":""},"bgColor":"","width":"","style":"border-style: none;"},"picklistColorsMap":{},"controllerFieldActions":[],"defaultType":"expression","defaultExpression":"{!Name} + {!ProductCode}","isHidden":true,"isNotExportable":true,"isSortable":true}]';
                templateList[0].Filters__c = '[{"fieldName":"IsActive","values":[true]},{"fieldName":"CurrencyIsoCode","values":["GBP"]},{"fieldName":"CreatedDate","value1":"2022-10-06","value2":"2022-10-16"},{"fieldName":"Family","values":["Test"]}]';
                templateList[0].Grid_Configuration__c = '{"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":"","rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER","value":"2022-10-14T06:32:00.000Z"}}}';
                templateList[0].Master_Object_Columns__c = '[]';
            }
            if (metadataDeveloperName == 'Account_Contact') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(contactAccountTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"Name"},{"FieldName":"AccountId"},{"FieldName":"Account.Name"},{"FieldName":"Email"}]';
                templateList[0].Filters__c = '[]';
                templateList[0].Grid_Configuration__c = '{"actions":{"screenFlows":[{"value":"FlowName","label":"FlowLabel","icon":"utility:forward_up","hasRecordIds":false,"hasRecordId":true,"displayType":"Action"}],"quickActions":[]},"overrideFilter":null,"isShowFilterOnColumnHeader":null,"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":1,"rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER_OR_EQUALS","value":"2023-02-28T13:52:00.000Z"}}}';
                templateList[0].Master_Object_Columns__c = '[{"FieldName":"Name"},{"FieldName":"AccountNumber"}]';
            }
            if (metadataDeveloperName == 'Account_ContactV2') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(contactAccountTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"Name"},{"FieldName":"ExternalNumber__c"}]';
                templateList[0].Filters__c = '[]';
                templateList[0].Grid_Configuration__c = '{"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":1,"rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER_OR_EQUALS","value":"2023-02-28T13:52:00.000Z"}}}';
                templateList[0].Master_Object_Columns__c = '[{"FieldName":"Name"},{"FieldName":"Email"}]';
            }
            if (metadataDeveloperName == 'PDSD') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(PDSDTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"Name"},{"FieldName":"Contract__c"}]';
                templateList[0].Filters__c = '[]';
                templateList[0].Grid_Configuration__c = '{"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":1,"rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER_OR_EQUALS","value":"2023-02-28T13:52:00.000Z"}}}';
                templateList[0].Master_Object_Columns__c = '[{"FieldName":"Name"},{"FieldName":"NegoScope__c"}]';
            }
            if (metadataDeveloperName == 'PromoAgreementsManager') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(PDSDTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"Name"}]';
                templateList[0].Filters__c = '[]';
                templateList[0].Grid_Configuration__c = '{"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":1,"rulesMap":{}}';
                templateList[0].Master_Object_Columns__c = '[{"FieldName":"Name"}]';
            }
            if (metadataDeveloperName == 'LD_COD_Grid') {
                templateList = (List<Grid_Settings__mdt>) JSON.deserialize(GridTemplateJSON, List<Grid_Settings__mdt>.class);
                templateList[0].Columns__c = '[{"FieldName":"Supplier__c"},{"FieldName":"ContactRole__c"},{"FieldName":"Negoscope__c"},{"FieldName":"Contact__c"}]';
                templateList[0].Filters__c = '[]';
                templateList[0].Grid_Configuration__c = '{"Default_Page_Size":"50"}';
                templateList[0].ReadOnly_Criteria__c = '{"expression":"","rulesMap":{"1":{"fieldName":"CreatedDate","operation":"GREATER","value":"2022-10-14T06:32:00.000Z"}}}';
                templateList[0].Master_Object_Columns__c = '[]';
            }
        } catch (Exception ex) {
            System.debug('Error' + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
        }
        return templateList;
    }
    public static List<Grid_Settings__mdt> getAllTemplates() {
        return getTemplates('Product');
    }
}