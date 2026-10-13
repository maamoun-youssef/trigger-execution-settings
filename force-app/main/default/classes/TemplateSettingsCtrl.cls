/**
 * @author ULit
 * @description
 * managing File Directory Settings.
 */
public with sharing class TemplateSettingsCtrl {
    
    /**
     * Loads File Directory Settings based on a provided developerName.
     * If developerName is empty, returns all settings; otherwise, returns the specified setting.
     * @param developerName Developer Name of the FileDirectorySetting record.
     * @return JSON-serialized ResultWrapper containing the settings.
     */
    @AuraEnabled
    public static string loadTemplateSettings(string developerName) {
        ResultWrapper resultWrapper;
        List<TemplateSettings> dataList;
        if (String.isEmpty(developerName)) {
            dataList = TemplateSettings.loadAllTemplateSettings();
            resultWrapper = new ResultWrapper(dataList);
        }else {
            TemplateSettings singleSetting = TemplateSettings.loadTemplateSettings(developerName);
            System.debug('singleSetting: ' + JSON.serialize(singleSetting));
            dataList = new List<TemplateSettings>{ singleSetting };
            resultWrapper = new ResultWrapper();
            resultWrapper.settings = dataList;
        }
        return JSON.serialize(resultWrapper);
    }
    
    /**
     * Saves provided FileDirectorySettings records.
     * Validates uniqueness of displayOrder and non-blank sectionTitle.
     * @param FileDirectorySettingsJSON JSON list of FileDirectorySettings to save.
     * @return A String message indicating success or failure.
     */
    @AuraEnabled
    public static String save(String FileDirectorySettingsJSON) {
        try {
            List<TemplateSettings> fileDirectorySettingsList = String.isNotBlank(FileDirectorySettingsJSON)
                ? (List<TemplateSettings>) JSON.deserialize(FileDirectorySettingsJSON, List<TemplateSettings>.class)
                : new List<TemplateSettings>();
            
            TemplateSettings fileSettingsInstance = new TemplateSettings();
            Set<Integer> displayOrderSet = new Set<Integer>();
            
            
            // Attempt to save settings
            String saveResult = fileSettingsInstance.save(fileDirectorySettingsList);
            return saveResult;
            
        } catch(AuraHandledException ahe) {
            // Re-throw AuraHandledException without modification
            throw ahe;
        } catch(Exception ex) {
            // Log the exception details for debugging
            System.debug('ERROR: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            // Throw a generic error message to avoid exposing sensitive details
            throw new AuraHandledException('An unexpected error occurred while saving File Directory Settings.');
        }
    }
    
    /**
     * Check the FileDirectorySetting deleted field of the following developerName.
     * @param developerName Developer Name of the FileDirectorySetting to delete.
     * @return ID of the deletion operation.
     */
    @AuraEnabled
    public static String deleteTemplateSettings(String developerName) {
        try {
            TemplateSettings fileSettingsInstance = new TemplateSettings();
            String jobId = fileSettingsInstance.deleteTemplateSettings(developerName);
            return jobId;
        } catch(AuraHandledException ahe) {
            throw ahe;
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            throw new AuraHandledException('An unexpected error occurred while saving File Directory Settings.');
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    
    /**
     * Wrapper class to return settings along with theme options and field metadata.
    /**
     * Wrapper class to return settings along with theme options and field metadata.
     */
    public class ResultWrapper {
        public List<TemplateSettings> settings { get; set; }
        public Map<String, String> FieldSetOptions { get; set; }
        public Map<String, String> ObjectOptions { get; set; }
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap { get; set; }
        public Map<String, String> fieldOptions { get; set; }
        public ResultWrapper(List<TemplateSettings> settings) {
            this.settings = settings;
            // 🔹 Build theme options (all objects in org)
            Map<String, String> picklistLabelsMap = new Map<String, String>();
            List<EntityDefinition> data = [
            SELECT QualifiedApiName, Label
            FROM EntityDefinition
            WHERE IsCustomizable = true
            ORDER BY Label
        ];
            for (EntityDefinition item : data) {
                if (!picklistLabelsMap.containsKey(item.QualifiedApiName)) {
                    picklistLabelsMap.put(item.QualifiedApiName, item.Label);
                }
            }
            
            this.ObjectOptions = picklistLabelsMap;
            
            Map<String, String> subtypeLabelsMap = new Map<String, String>();
            try {
                List<FieldSetMember> fsMembers = SObjectType.nTemplate__Template__c
                    .FieldSets
                    .nTemplate__AdditionalSettings
                    .getFields();
                
                for (FieldSetMember fsm : fsMembers) {
                    String fieldApiName = fsm.getFieldPath(); // raw path, e.g. 'MyField__c' or 'Related__r.Name'
                    String label = fsm.getLabel();
                    if (!subtypeLabelsMap.containsKey(fieldApiName)) {
                        subtypeLabelsMap.put(fieldApiName, label);
                    }
                    System.debug('FieldSet member -> ' + fieldApiName + ' : ' + label);
                }
                
            } catch (Exception e) {
                System.debug('Could not load Template__c field set: ' + e.getMessage());
            }
            this.FieldSetOptions = subtypeLabelsMap;
            
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.TemplateSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), dfr);
                }
            }
            this.fieldsMap = fieldsMap;
            
            
        }
        
        
        public ResultWrapper() {}
    }
    
@AuraEnabled
public static String loadOptionsForObject(String ObjectName) {
    ObjectOptionsWrapper wrapper = new ObjectOptionsWrapper();

    Map<String, String> fieldMap = new Map<String, String>();
    if (Schema.getGlobalDescribe().containsKey(ObjectName)) {
        SObjectType sObjType = Schema.getGlobalDescribe().get(ObjectName);
        Map<String, Schema.SObjectField> fields = sObjType.getDescribe().fields.getMap();

        for (String fieldName : fields.keySet()) {
            DescribeFieldResult dfr = fields.get(fieldName).getDescribe();
            String label = dfr.getLabel();

            // If it's a reference field, include the referenced object API name
            if (dfr.getType() == DisplayType.Reference) {
                List<Schema.SObjectType> refObjects = dfr.getReferenceTo();
                if (!refObjects.isEmpty()) {
                    label += ' (' + refObjects[0].getDescribe().getName() + ')';
                }
            }

           
            fieldMap.put(dfr.getName(), label);
        }
    }
    wrapper.fieldOptions = fieldMap;

    return JSON.serialize(wrapper);
}
    
    
    public class ObjectOptionsWrapper {
        @AuraEnabled public Map<String, String> fieldOptions { get; set; } // fields map
        
    }
    
    @AuraEnabled
    public static String getFirstSelectList(String objectApiName) {
        FieldsSelectList instance = new FieldsSelectList(objectApiName);
        return JSON.serialize(instance);
    }
    
    public class FieldsSelectList {
        public String sObjectApiName { get; set; }
        public Map<String,String> fieldsMap { get; set; }
        public List<String> fieldsMapKeyList { get; set; }
        public Map<String,String> referenceMap { get; set; }
        
        public FieldsSelectList(String ObjectName) {
            this.sObjectApiName = ObjectName;
            this.fieldsMap = new Map<String,String>();
            this.fieldsMapKeyList = new List<String>();
            this.referenceMap = new Map<String,String>();
            this.loadFields();
        }
        
        public void loadFields() {
            if(String.isBlank(sObjectApiName)) return;
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectApiName).getDescribe().fields.getMap();
            
            for(String key : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(key).getDescribe();
                String label = fieldDesc.getLabel();
                //String value = sObjectApiName + '.' + key;
                String value = sObjectApiName + '.' + fieldDesc.getName(); // preserves exact casing
                
                Boolean isReference = fieldDesc.getType() == DisplayType.Reference;
                
                if(isReference) {
                    List<Schema.SObjectType> refTypes = fieldDesc.getReferenceTo();
                    if(!refTypes.isEmpty()) {
                        referenceMap.put(value + ':reference', refTypes[0].getDescribe().getName()); // store the related object API name
                    }
                    value += ':reference';
                    label += ' >';
                }
                
                
                fieldsMap.put(label, value);
                fieldsMapKeyList.add(label);
            }
            fieldsMapKeyList.sort();
        }
    }
}