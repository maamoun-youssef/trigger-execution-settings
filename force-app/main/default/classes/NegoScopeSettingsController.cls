/**
 * @author ULiT
 * @date 22/08/2024
 * @group Negoptim Support
 * @description load and save NegoscopeSettings__c
 ********************************************************************************************************************************************* */
public with sharing class NegoScopeSettingsController {
    /**
	 * @description load NegoScope Settings
	 ********************************************************************** */
    @AuraEnabled
    public static string loadNegoScopeSettings() {
        // Wrapper to store the result
        ResultWrapper wrapper = new ResultWrapper();
        NegoScopeSettings negoScopeSettings = NegoScopeSettings.loadNegoScopeSettings();
        List<String> objectsList = new List<String> {
            BRADistributor__c.getSObjectType().getDescribe().getName(),
            PG__c.getSObjectType().getDescribe().getName(),
            NegoScope__c.getSObjectType().getDescribe().getName()
        };
        Map<String, List<SelectOption>> negoScopeSettingsLayoutsMap = new Map<String, List<SelectOption>>();
        String[] gridSettingsFields = new String[] {
          SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
          SObjectType.Grid_Settings__mdt.fields.Label.Name
        };
        if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
            for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c
                                            FROM Grid_Settings__mdt
                                            WHERE Object_Name__c IN :objectsList
                                            ORDER BY DeveloperName])
            {
                if (!negoScopeSettingsLayoutsMap.containsKey(item.Object_Name__c)) {
                    negoScopeSettingsLayoutsMap.put(item.Object_Name__c, new List<SelectOption>{new SelectOption('', Label.LBL_None_Picklist_Value)});
                }
                negoScopeSettingsLayoutsMap.get(item.Object_Name__c).add(new SelectOption(item.DeveloperName, item.Label));
            }
        }
        String negoScopeObjectName = NegoScope__c.getSObjectType().getDescribe().getName();
        List<RecordType> recordTypes = [SELECT Id, toLabel(Name), DeveloperName, toLabel(Description) FROM RecordType WHERE SobjectType = :negoScopeObjectName];
        wrapper.negoScopeSettings = negoScopeSettings;
        wrapper.negoScopeSettingsLayoutsMap = negoScopeSettingsLayoutsMap;
        wrapper.recordTypes = recordTypes;
        return JSON.serialize(wrapper);
    }

    /**
	 * @description Save NegoScope Settings in the cache and custom settings
	 ***************************************************************************************************************************************** */
    @AuraEnabled
	public static String save(String negoScopeSettingsJson) {
        try {
            NegoScopeSettings negoScopeSettings = (NegoScopeSettings) JSON.deserialize(negoScopeSettingsJson, NegoScopeSettings.class);
            Id jobId = NegoScopeSettings.save(negoScopeSettings);
            return jobId;
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment){
        try {
            String status = NegoScopeSettings.ckeckNSDeploymentStatus(idDeployment);
            return status;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResultWrapper {
        public NegoScopeSettings negoScopeSettings { get; set; }
        public Map<String, List<SelectOption>> negoScopeSettingsLayoutsMap { get; set; }
        public Map<String,  Map<String,  Schema.DescribeFieldResult>> fieldsMap { get; set; }
        public Map<String, Map<String,  Map<String,  String>>> picklistLabelsMap { get; set; }
        String negoSettingsLabel {get; set;}
        public String prefix {get; set;}
        List<RecordType> recordTypes {get; set;}

        public ResultWrapper() {
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.NSSettings__mdt.getName() => new Map<String,  Schema.DescribeFieldResult>()
            };
            this.picklistLabelsMap = new Map<String, Map<String, Map<String, String>>>();
            for (String objectName : this.fieldsMap.keySet()) {
                this.picklistLabelsMap.put(objectName, new Map<String, Map<String, String>>());
                Map<String,  Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), dfr);
                    if (dfr.type == DisplayType.Picklist || dfr.type == DisplayType.MultiPicklist) {
                        this.picklistLabelsMap.get(objectName).put(dfr.getName(), new Map<String, String>());
                        List<SelectOption> pickListValues = new List<SelectOption>();
                        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                            pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                            this.picklistLabelsMap.get(objectName).get(dfr.getName()).put(pe.getValue(), pe.getLabel());
                        }
                    }
                }
            }
            this.negoSettingsLabel = Schema.getGlobalDescribe().get(SObjectType.NSSettings__mdt.getName()).getDescribe().getLabel();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
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