/**
 * @author ULiT
 * Controller for NegoSettings LWC
 **/
public with sharing class NegoSettingsController {
    
    @AuraEnabled
    public static string loadNegoSettings() {
        ResultWrapper wrapper = new ResultWrapper();
        try {
            //GET GRID SETTINGS OPTIONS
            Map<String, List<SelectOption>> gridSettingsLayoutsMap = new Map<String, List<SelectOption>>();
            List<String> objectsList = new List<String> {
                SObjectType.Contract_Discount__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.Name,
                SObjectType.PriceListStatementDetail__c.Name
            };
            String[] gridSettingsFields = new String[] {
                SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Name,
                SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
                SObjectType.Grid_Settings__mdt.fields.Label.Name
            };
            if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
                for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c
                                                FROM Grid_Settings__mdt
                                                WHERE Object_Name__c IN :objectsList
                                                WITH USER_MODE
                                                ORDER BY DeveloperName])
                {
                    if (!gridSettingsLayoutsMap.containsKey(item.Object_Name__c)) {
                        gridSettingsLayoutsMap.put(item.Object_Name__c, new List<SelectOption>());
                    }
                    gridSettingsLayoutsMap.get(item.Object_Name__c).add(new SelectOption(item.DeveloperName, item.Label));
                }
            }
            //GET Import SETTINGS OPTIONS
            Map<String, List<SelectOption>> importSettingsMap = new Map<String, List<SelectOption>>();
            String[] importSettingsFields = new String[] {
                SObjectType.ImportSettings__mdt.fields.ObjectName__c.Name,
                SObjectType.ImportSettings__mdt.fields.Name__c.Name,
                SObjectType.ImportSettings__mdt.fields.DeveloperName.Name,
                SObjectType.ImportSettings__mdt.fields.Label.Name
            };
            if (NegoptimHelper.checkAccessibility(ImportSettings__mdt.SObjectType, importSettingsFields)) {
                for (ImportSettings__mdt item : [SELECT DeveloperName, Name__c, Label, ObjectName__c
                                                FROM ImportSettings__mdt
                                                WHERE ObjectName__c IN :objectsList
                                                WITH USER_MODE
                                                ORDER BY DeveloperName])
                {
                    if (!importSettingsMap.containsKey(item.ObjectName__c)) {
                        importSettingsMap.put(item.ObjectName__c, new List<SelectOption>());
                    }
                    importSettingsMap.get(item.ObjectName__c).add(new SelectOption(item.DeveloperName, item.Label));
                }
            }
            wrapper.contractRTMap = getObjectRecordTypeMapDeveloperNameToLabel(Contract__c.getSObjectType());
            wrapper.productDiscountStatementRTMap = getObjectRecordTypeMapDeveloperNameToLabel(ProductDiscountStatement__c.getSObjectType());
            wrapper.priceListStatementRTMap = getObjectRecordTypeMapDeveloperNameToLabel(PriceListStatement__c.getSObjectType());
            wrapper.negoSettings = NegoSettings.loadNegoSettings();
            wrapper.gridSettingsLayoutsMap = gridSettingsLayoutsMap;
            wrapper.importSettingsMap = importSettingsMap;
        } catch(QueryException qe){ NegoptimHelper.getInaccessibleFields(qe);}
        return JSON.serialize(wrapper);
    }
    
    private static Map<String, String> getObjectRecordTypeMapDeveloperNameToLabel(SObjectType sObjectType) {
        Map<String, String> developerNameToLabelMap = new Map<String, String>();
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            if(!RT.isMaster()) {
                developerNameToLabelMap.put(RT.getDeveloperName(), RT.getName());
            }
        }
        return developerNameToLabelMap;
    }
    
    @AuraEnabled
    public static String save(String negoSettingsJSON) {
        try {
            NegoSettings negoSettingss = String.isNotBlank(negoSettingsJSON) ? (NegoSettings) JSON.deserialize(negoSettingsJSON, NegoSettings.class) : new NegoSettings();
            return NegoSettings.save(negoSettingss);
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class ResultWrapper {
        public NegoSettings negoSettings {get; set;}
        Map<String, String> contractRTMap {get; set;}
        Map<String, String> productDiscountStatementRTMap {get; set;}
        Map<String, String> priceListStatementRTMap {get; set;}
        public Map<String, List<SelectOption>> gridSettingsLayoutsMap { get; set; }
        public Map<String, List<SelectOption>> importSettingsMap { get; set; }
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        public String prefix {get; set;}
        public ResultWrapper() {
            this.contractRTMap = new Map<String, String>();
            this.productDiscountStatementRTMap = new Map<String, String>();
            this.priceListStatementRTMap = new Map<String, String>();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.NegoSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.Contract__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.ProductDiscountStatement__c.getName() => new Map<String, Schema.DescribeFieldResult>(),
                SObjectType.PriceListStatement__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}