public with sharing class testWorkflowPageSettingsCtrl {
    @AuraEnabled
    public static List<Map<String, Object>> getLayoutPagesList() {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<LayoutSettings__mdt> gridLayouts = [
            SELECT NamespacePrefix, DeveloperName, MasterLabel, ObjectApiName__c, Label
            FROM LayoutSettings__mdt
            ORDER BY DeveloperName LIMIT 1000
        ];
        System.debug('layout list:' + gridLayouts);
        for (LayoutSettings__mdt item : gridLayouts) {
            results.add(new Map<String, Object>{
                'key' => (item.NamespacePrefix != null ? item.NamespacePrefix + '__' : '') + item.DeveloperName,
                'MasterLabel' => item.MasterLabel,
                'NamespacePrefix' => item.NamespacePrefix,
                'ObjectApiName__c' => item.ObjectApiName__c,
                'Label' => item.Label
            });
        }
        System.debug('results:' + results);
        return results;
    }
}