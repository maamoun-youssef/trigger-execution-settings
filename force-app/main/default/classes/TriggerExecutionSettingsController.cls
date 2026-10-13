/**
 * @author ULiT
 * @date 30/12/2024
 * Controller class for Trigger Execution Settings LWC
 **/
public class TriggerExecutionSettingsController {

    @AuraEnabled
    public static String getObjectNames() {
        List<ObjectWrapper> objectWrapperList = new List<ObjectWrapper>();
        List<AggregateResult> results = [SELECT TableEnumOrId objectName FROM ApexTrigger GROUP BY TableEnumOrId];
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (AggregateResult result : results) {
            String objectName = (String) result.get('objectName');
            Schema.SObjectType sObjectType = globalDescribe.get(objectName);
            if (sObjectType != null) {
                String objectLabel = sObjectType.getDescribe().getLabel();
                objectWrapperList.add(new ObjectWrapper(objectName, objectLabel));
            }
        }
        return JSON.serialize(objectWrapperList);
    }
    
    @AuraEnabled
    public static String initData(String objectName) {
        Map<String, List<String>> results = new Map<String, List<String>>();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        String handlerSearchTerm = 'Trg_' + objectName.replace(prefix, '').replace('__c', '') + '_Handler%';
        List<ApexClass> classes = [SELECT Id, Name, NamespacePrefix FROM ApexClass WHERE Name LIKE :handlerSearchTerm AND (NOT Name LIKE '%Test')];        
        String methodName = 'getMethodNames';
        for (ApexClass apexClass : classes) {
            Boolean doesClassExist = MethodUtils.doesClassExist((String.isNotBlank(apexClass.NamespacePrefix) ? apexClass.NamespacePrefix + '.' : '') + apexClass.Name);
            Boolean doesMethodExist = MethodUtils.doesMethodExist(apexClass.Name, methodName);
            List<String> methodNames = new List<String>();
            if (doesClassExist && doesMethodExist) {
                List<String> methods = (List<String>) MethodUtils.invokeMethod(apexClass.Name, methodName, new List<Object>());
                if (methods != null) {
                    methodNames = methods;
                }
            }
            results.put(apexClass.Name, methodNames);
        }
        return JSON.serialize(results);
    }
    
    @AuraEnabled
    public static String loadData(String objectName) {
        return JSON.serialize(TriggerSettings.loadTriggerSettingsByObjectName(objectName));
    }
    
    @AuraEnabled
    public static String save(String triggerSettingsListSerialized) {
        List<TriggerSettings> triggerSettingsList = String.isNotBlank(triggerSettingsListSerialized) ? (List<TriggerSettings>) JSON.deserialize(triggerSettingsListSerialized, List<TriggerSettings>.class) : new List<TriggerSettings>();
        return TriggerSettings.save(triggerSettingsList.get(0));
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class ObjectWrapper {
        public String objectName {get; set;}
        public String objectLabel {get; set;}
        
        public ObjectWrapper(String objectName, String objectLabel) {
            this.objectName = objectName;
            this.objectLabel = objectLabel;
        }
    }
}