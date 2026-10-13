/**
* @author ULiT
* @date 04/09/2025
* @description PageLayoutSettingsCtrl
******************************************************************************************************************************************* */
public with sharing class PageLayoutSettingsCtrl {
    @AuraEnabled
    public static string loadData() {
        try {
            ResultWrapper result = new ResultWrapper();
            List<FlowRecord> screenFlows = [SELECT Id, Name, ApiName, Type, FlowType, FlowLabel, Description FROM FlowRecord where FlowType = 'Screen' ORDER BY Name];
            result.screenFlows = screenFlows;
            List<Map<String, String>> objectList = new List<Map<String, String>>();
            for (Schema.SObjectType objType : Schema.getGlobalDescribe().Values()) {
                Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
                if (objDescribe.getName().contains('__c'))
                    objectList.add(new Map<String, String>{ 'label' => objDescribe.getLabel(), 'apiname' => objDescribe.getName() });
            }
            result.objects = objectList;
            List<Grid_Settings__mdt> gridSettings = [SELECT Id, Label, MasterLabel, QualifiedApiName, Object_Name__c, Master_Object_Name__c FROM Grid_Settings__mdt ORDER BY Label];
            result.gridSettings = gridSettings;
            result.pageLayoutSettingsList = PageLayoutSettings.loadAllPageLayoutSettings();
            result.fileDirectoryData = getFileDirectoryData();
            // Replaced due to open-source deployment; restore when preparing for packaging.           
            List<ParamSettingWrapper> lwcparams = loadAllLWCParamSettings();
            result.lwcParamsSettingsList = lwcparams;
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('ERROR>>>' + e.getMessage() + '>>>' + e.getLineNumber() + '>>>' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<ParamSettingWrapper> loadAllLWCParamSettings() {
        List<ParamSettingWrapper> allLwcParams = new List<ParamSettingWrapper>();        
        List<LWC_Param_Setting__mdt> records = [SELECT Id, Label, MasterLabel, DeveloperName,
                                                Configuration__c, QualifiedApiName
                                                FROM LWC_Param_Setting__mdt
                                                ORDER BY DeveloperName ASC];        
        for (LWC_Param_Setting__mdt rec : records) {
            List<ParamSetting> param = String.isNotBlank(rec.Configuration__c)
                                    ? (List<ParamSetting>) JSON.deserialize(rec.Configuration__c, List<ParamSetting>.class)
                                    : new List<ParamSetting>();            
            ParamSettingWrapper  paramWrapper = new ParamSettingWrapper();
            paramWrapper.paramSetting = param;
            paramWrapper.name = rec.DeveloperName;
            allLwcParams.add(paramWrapper);
        }   
        return allLwcParams;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Map<String, String>> getChildRelationships(String parentObjectApiName) {
        List<Map<String, String>> rows = new List<Map<String, String>>();
        if (String.isBlank(parentObjectApiName)) return rows;
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(parentObjectApiName);
        if (parentType == null) return rows;
        Set<String> seen = new Set<String>();
        for (Schema.ChildRelationship rel : parentType.getDescribe().getChildRelationships()) {
            String relationshipName = rel.getRelationshipName();
            String currentChildObject = rel.getChildSObject().getDescribe().getName();
            String currentField = rel.getField() != null ? rel.getField().getDescribe().getName() : null;
            String dedupeKey = currentChildObject + '|' + relationshipName + '|' + currentField;
            if (seen.contains(dedupeKey)) {
                continue;
            }
            seen.add(dedupeKey);
            rows.add(new Map<String, String> {
                'relationshipApiName' => relationshipName,
                'childObjectApiName' => currentChildObject,
                'foreignKeyFieldApiName' => currentField,
                'label' => rel.getChildSObject().getDescribe().getLabel() + ' · ' + relationshipName
            });
        }
        return rows;
    }

    @AuraEnabled(cacheable = true)
    public static List<FieldInfo> getFields(String objectName){
        List<FieldInfo> fieldList = new List<FieldInfo>();
        if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
            return fieldList;
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        for (Schema.SObjectField field : fields.values()){
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldName = fieldDescribe.getName();
            fieldList.add(new FieldInfo(
                fieldDescribe.getName(),
                fieldDescribe.getLabel(),
                String.valueOf(fieldDescribe.getType()),
                isAggregateableType(fieldDescribe.getType())
            ));
        }
        return fieldList;
    }

    private static Boolean isAggregateableType(Schema.DisplayType fieldType) {
        return fieldType == Schema.DisplayType.Currency
            || fieldType == Schema.DisplayType.Double
            || fieldType == Schema.DisplayType.Integer
            || fieldType == Schema.DisplayType.Percent;
    }
    
    @AuraEnabled(cacheable = false)
    public static String saveSettings(String pageLayoutSettingsJSON) {
        PageLayoutSettings pageLayoutSettings = String.isNotBlank(pageLayoutSettingsJSON) ? (PageLayoutSettings) JSON.deserialize(pageLayoutSettingsJSON, PageLayoutSettings.class) : null;
        System.debug('pageLayoutSettings: ' + JSON.serialize(pageLayoutSettings));
        return PageLayoutSettings.save(pageLayoutSettings);
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    private static List<Map<String, String>> getFileDirectoryData(){
        FileDirectoryDataSource ds = new  FileDirectoryDataSource();
        VisualEditor.DynamicPickListRows values = ds.getValues();
        List<Map<String, String> > options = new List<Map<String, String>>();
        for(Integer i=0; i < values.size(); i++){
            Map<String, String> option = new Map<String, String> {
                'label' => values.get(i).getLabel(),
                'value' => (String)values.get(i).getValue()
            };
            options.add(option);              
        }
        return options;
    }

    public class FieldInfo{
        @AuraEnabled
        public String apiName{ get; set; }

        @AuraEnabled
        public String label{ get; set; }

        @AuraEnabled
        public String type{ get; set; }

        @AuraEnabled
        public Boolean isAggregateable{ get; set; }
        
        public FieldInfo(String apiName, String label, String type, Boolean isAggregateable){
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.isAggregateable = isAggregateable;
        }        
    }
    
    public class ResultWrapper{
        @AuraEnabled
        public List<FlowRecord> screenFlows{ get; set; }
        
        @AuraEnabled
        public List<Map<String, String>> objects{ get; set; }
        
        @AuraEnabled
        public List< Grid_Settings__mdt> gridSettings{ get; set; }
        
        @AuraEnabled
        public List<PageLayoutSettings> pageLayoutSettingsList{ get; set; }
        
        @AuraEnabled
        public List<Map<String, String>> fileDirectoryData{ get; set; }

        @AuraEnabled
        public List<ParamSettingWrapper> lwcParamsSettingsList{ get; set; }
    }
    
    public class ParamSetting {
        public String name {get; set;}
        public String label {get; set;}
        public String type {get; set;}
        public String datasource {get; set;}
        public String defaultValue {get; set;}
        public String description {get; set;}
        public String required {get; set;}
        public Map<String, String> getDataSourceList { get {
            Map<String, String> pickListValues = new Map<String, String>();
            if (String.isNotBlank(datasource)) {
                if (datasource.startsWith('apex://')) {
                    try {
                        String className = datasource.replace('apex://', '');
                        VisualEditor.DynamicPickList instance = (VisualEditor.DynamicPickList) System.Type.forName(className).newInstance();
                        for (VisualEditor.DataRow picklistRow : instance.getValues().getDataRows()) {
                            pickListValues.put((String)picklistRow.getValue(), (String)picklistRow.getLabel());
                        }
                    } catch(Exception e) {}
                }
                if (datasource.contains(',')) {
                    for(String value : datasource.split(',')) pickListValues.put(value.trim(), value.trim());
                }
            }
            return pickListValues;
        } set;}
        
        public ParamSetting() {
            this.name = '';
            this.label = '';
            this.type = '';
            this.datasource = '';
            this.defaultValue = '';
            this.description = '';
            this.required = '';
        }
    }

    public class ParamSettingWrapper {
        public List<ParamSetting> paramSetting {get; set;}
        public String name {get; set;}
    }
}