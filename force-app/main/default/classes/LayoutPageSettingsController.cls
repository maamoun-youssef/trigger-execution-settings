/**
* @author ULiT
* @date 04/09/2025
* @description PageLayoutSettingsCtrl
******************************************************************************************************************************************* */
public with sharing class LayoutPageSettingsController {
    @AuraEnabled
    public static String initData() {
        ResultWrapper wrapper = new ResultWrapper();
        List<FlowRecord> screenFlows = [SELECT Id, ApiName, FlowLabel FROM FlowRecord where FlowType = 'Screen' ORDER BY FlowLabel];
        wrapper.screenFlows = new List<Map<String, String>>();
        for (FlowRecord flow : screenFlows) {
            wrapper.screenFlows.add(new Map<String, String>{
                'label' => flow.FlowLabel,
                'value' => flow.ApiName
            });
        }
        List<Map<String, String>> objectList = new List<Map<String, String>>();
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().Values()) {
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            if (objDescribe.getName().contains('__c'))
                objectList.add(new Map<String, String>{ 'label' => objDescribe.getLabel(), 'value' => objDescribe.getName() });
        }
        objectList.sort(new LabelComparator());
        wrapper.objects = objectList;
        List<Grid_Settings__mdt> gridSettings = [SELECT Id, Label, MasterLabel, QualifiedApiName, Object_Name__c, Master_Object_Name__c FROM Grid_Settings__mdt ORDER BY Label];
        wrapper.gridSettings = gridSettings;
        wrapper.fileDirectoryData = getFileDirectoryData();
        List<FieldInfo> taskObjectFields = getRelatedObjectFields(SObjectType.Task.Name);
        List<FieldInfo> activityObjectFields = getRelatedObjectFields(SObjectType.TMP_Activity__c.Name);
        wrapper.activityObjectFields = activityObjectFields;
        wrapper.taskObjectFields = taskObjectFields;
        List<ParamSettingWrapper> lwcparams = loadAllLWCParamSettings();
        wrapper.lwcParamsSettingsList = lwcparams;
        return JSON.serialize(wrapper);
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getLayoutPagesList() {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<PageLayoutSettings__mdt> gridLayouts = [
            SELECT NamespacePrefix, DeveloperName, MasterLabel, ObjectApiName__c
            FROM PageLayoutSettings__mdt 
            ORDER BY DeveloperName LIMIT 1000
        ];
        for (PageLayoutSettings__mdt item : gridLayouts) {
            results.add(new Map<String, Object>{
                'key' => (item.NamespacePrefix != null ? item.NamespacePrefix + '__' : '') + item.DeveloperName,
                'MasterLabel' => item.MasterLabel,
                'NamespacePrefix' => item.NamespacePrefix,
                'ObjectApiName__c' => item.ObjectApiName__c
            });
        }
        return results;
    }
    
    @AuraEnabled
    public static String getLayoutPageByDeveloperName(String developerName) {
        PageLayoutSettings layoutSettings = PageLayoutSettings.loadPageLayoutSettings(developerName);
        Map<String, Object> fields = getFields(layoutSettings.objectApiName);
        System.debug('>>>>>>>>>>>>>>> layoutSettings: ' + layoutSettings);
        Map<String, Object> layoutData = new Map<String, Object>{
            'layoutSettings' => layoutSettings,
            'selectedObjectFields' => fields.get('fieldList'),
            'childRelationships' => fields.get('childRelationships')
        };
        return JSON.serialize(layoutData);
    }
    
    @AuraEnabled
    public static Map<String,Object> getFields(String objectName) {
        List<FieldInfo> fieldList = new List<FieldInfo>();
        List<Map<String, String>> childRelationships = new List<Map<String, String>>();
        if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
            return new Map<String,Object>{
                'fieldList' => fieldList,
                'childRelationships' => childRelationships
            };
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
        fieldList.sort(new LabelComparator());
        
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(objectName);
        if (parentType != null) {
            Set<String> seen = new Set<String>();
            for (Schema.ChildRelationship rel : parentType.getDescribe().getChildRelationships()) {
                String relationshipName = rel.getRelationshipName();
                if (String.isBlank(relationshipName) || seen.contains(relationshipName)) {
                    continue;
                }
                String currentChildObject = rel.getChildSObject().getDescribe().getName();
                String currentField = rel.getField() != null ? rel.getField().getDescribe().getName() : null;
                String dedupeKey = currentChildObject + '|' + relationshipName + '|' + currentField;
                if (seen.contains(dedupeKey)) {
                    continue;
                }
                seen.add(dedupeKey);
                childRelationships.add(new Map<String, String> {
                    'relationshipApiName' => relationshipName,
                    'childObjectApiName' => currentChildObject,
                    'foreignKeyFieldApiName' => currentField,
                    'label' => rel.getChildSObject().getDescribe().getLabel() + ' · ' + relationshipName
                });
                
            }
            System.debug('Added childRelationships: ' + childRelationships);
        }
        childRelationships.sort(new LabelComparator());
        return new Map<String,Object>{
            'fieldList' => fieldList,
            'childRelationships' => childRelationships
        };
    }
    @AuraEnabled
    public static List<FieldInfo> getRelatedObjectFields(String objectName) {
        List<FieldInfo> fieldList = new List<FieldInfo>();
        if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
            return new List<FieldInfo>();
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
        fieldList.sort(new LabelComparator());
        return fieldList;
    }
    private static List<Map<String, String>> getFileDirectoryData() {
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
    
    @AuraEnabled
    public static String saveSettings(String pageLayoutSettingsJSON) {
        PageLayoutSettings pageLayoutSettings = String.isNotBlank(pageLayoutSettingsJSON) ? (PageLayoutSettings) JSON.deserialize(pageLayoutSettingsJSON, PageLayoutSettings.class) : null;
        System.debug('pageLayoutSettings: ' + JSON.serialize(pageLayoutSettings));
        return PageLayoutSettings.save(pageLayoutSettings);
    }
    
    private static Boolean isAggregateableType(Schema.DisplayType fieldType) {
        return fieldType == Schema.DisplayType.Currency
            || fieldType == Schema.DisplayType.Double
            || fieldType == Schema.DisplayType.Integer
            || fieldType == Schema.DisplayType.Percent;
    }

    public class LabelComparator implements Comparator<Object> {
        public Integer compare(Object a, Object b) {
            String labelA = getLabel(a);
            String labelB = getLabel(b);

            if (String.isBlank(labelA) && String.isBlank(labelB)) return 0;
            if (String.isBlank(labelA)) return 1;
            if (String.isBlank(labelB)) return -1;

            return labelA.toLowerCase().compareTo(labelB.toLowerCase());
        }
        private String getLabel(Object obj) {
            if (obj == null) {
                return '';
            }
            if (obj instanceof Map<String, String>) {
                return (String)((Map<String, String>)obj).get('label');
            }
            if (obj instanceof FieldInfo) {
                return ((FieldInfo)obj).label;
            }
            return '';
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class FieldInfo {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public Boolean isAggregateable { get; set; }
        public FieldInfo(String apiName, String label, String type, Boolean isAggregateable) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.isAggregateable = isAggregateable;
        }        
    }
    
    public class ResultWrapper {
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get;set;}
        public String prefix {get;set;}
        public List<Map<String, String>> screenFlows { get; set; }
        public List<Map<String, String>> objects { get; set; }
        public List<FieldInfo> activityObjectFields { get; set; }
        public List<FieldInfo> taskObjectFields { get; set; }
        List<Grid_Settings__mdt> gridSettings { get;set; }
        List<Map<String, String>> fileDirectoryData { get;set; }
        public List<ParamSettingWrapper> lwcParamsSettingsList{ get; set; }
        public ResultWrapper() {
           this.prefix = NegoptimHelper.getPackagePrefix(true);
           Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.PageLayoutSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
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