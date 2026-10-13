public with sharing class GridSettingsListViewCmpController {

    @AuraEnabled
    public static String getObjects() {
        try {
            List<String> objectNames = new List<String>();
            Map<String, String> objectNameToLabel = new Map<String, String>();
            for (Grid_Settings__mdt record : [SELECT Object_Name__c FROM Grid_Settings__mdt WHERE Type__c = 'Detail' ORDER BY Object_Name__c]) {
                objectNames.add(record.Object_Name__c);
            }
            for (String objectName : objectNames) {
                /*if (objectName.contains('__c')) {
                    Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
                    objectNameToLabel.put(objectName, objDescribe.getLabel());
                } else {
                    objectNameToLabel.put(objectName, objectName);
                }*/
                if (Schema.getGlobalDescribe().get(objectName) != null) {
                    Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
                    objectNameToLabel.put(objectName, objDescribe.getLabel());
                }
            }
            List<SelectOption> listViews = new List<SelectOption>();
            for (String key : objectNameToLabel.keySet()) {
                listViews.add(new SelectOption(objectNameToLabel.get(key), key));
            }
            return JSON.serialize(listViews);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String Templates(String objectName) {
        List<Grid_Settings__mdt> gridTemplates = [SELECT DeveloperName, MasterLabel, Grid_Configuration__c FROM Grid_Settings__mdt WHERE Type__c = 'Detail' AND Object_Name__c =: objectName ORDER BY DeveloperName];
        List<ListViewWrapper> filteredTemplates = new List<ListViewWrapper>();
        for (Grid_Settings__mdt template : gridTemplates) {
            Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(template.Grid_Configuration__c);
            filteredTemplates.add(new ListViewWrapper(template.MasterLabel, template.DeveloperName, (Integer) configMap.get('Display_Order'), (Boolean) configMap.get('Include_In_List_View')));
        }
        return JSON.serialize(filteredTemplates);
    }

    @AuraEnabled
    public static String save(String objectName, List<String> noneSelectedTemplates, List<String> selectedTemplates){
        try {
            List<Id> jobIdsList = new List<Id>();
            Id jobId = null;
            if (noneSelectedTemplates.size() > 0) {
                for (Integer i = 0; i < noneSelectedTemplates.size(); i++) {
                    List<Grid_Settings__mdt> gridConfigurationList = new List<Grid_Settings__mdt>();
                    if (Test.isRunningTest()) {
                        for (String noneSelectedTemplate : noneSelectedTemplates) {
                            gridConfigurationList.add(gridSettingsManager.loadTemplate(noneSelectedTemplate));
                        }
                        for (String selectedTemplate : selectedTemplates) {
                            gridConfigurationList.add(gridSettingsManager.loadTemplate(selectedTemplate));
                        }
                    } else {
                        gridConfigurationList = [SELECT MasterLabel, Grid_Configuration__c FROM Grid_Settings__mdt WHERE Object_Name__c =: objectName AND DeveloperName =: noneSelectedTemplates[i]];
                    }
                    for (Grid_Settings__mdt value : gridConfigurationList) {
                        Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(value.Grid_Configuration__c);
                        configMap.put('Include_In_List_View', false);
                        configMap.put('Display_Order', null);
                        value.Grid_Configuration__c = JSON.serialize(configMap);
                        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                        customMetadata.fullName = SObjectType.Grid_Settings__mdt.Name + '.' + noneSelectedTemplates[i];
                        customMetadata.label = value.MasterLabel;
                        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Grid_Settings__mdt.fields.Grid_Configuration__c.Name;
                        customField.value = value.Grid_Configuration__c;
                        customMetadata.values.add(customField);
                        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                        mdContainer.addMetadata(customMetadata);
                        CustomMetadataCallback callback = new CustomMetadataCallback();
                        if(!Test.isRunningTest()) {
                            jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
                            jobIdsList.add(jobId);
                        }
                    }
                }
            }
            if (selectedTemplates.size() > 0) {
                for (Integer i = 0; i < selectedTemplates.size(); i++) {
                    List<Grid_Settings__mdt> gridConfigurationList = new List<Grid_Settings__mdt>();
                    if (Test.isRunningTest()) {
                        for (String selectedTemplate : selectedTemplates) {
                            gridConfigurationList.add(gridSettingsManager.loadTemplate(selectedTemplate));
                        }
                    } else {
                        gridConfigurationList = [SELECT MasterLabel, Grid_Configuration__c FROM Grid_Settings__mdt WHERE Object_Name__c =: objectName AND DeveloperName =: SelectedTemplates[i]];
                    }
                    for (Grid_Settings__mdt value : gridConfigurationList) {
                        Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(value.Grid_Configuration__c);
                        configMap.put('Include_In_List_View', true);
                        configMap.put('Display_Order', i + 1);
                        value.Grid_Configuration__c = JSON.serialize(configMap);
                        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                        customMetadata.fullName = SObjectType.Grid_Settings__mdt.Name + '.' + selectedTemplates[i];
                        customMetadata.label = value.MasterLabel;
                        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Grid_Settings__mdt.fields.Grid_Configuration__c.Name;
                        customField.value = value.Grid_Configuration__c;
                        customMetadata.values.add(customField);
                        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                        mdContainer.addMetadata(customMetadata);
                        CustomMetadataCallback callback = new CustomMetadataCallback();
                        if(!Test.isRunningTest()) {
                            jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
                            jobIdsList.add(jobId);
                        }
                    }
                }
            }
            return JSON.serialize(jobIdsList);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        //return NegoptimHelper.checkDeploymentStatus(idDeployment);
        try {
            String sessionId = NegoptimHelper.getSessionId();
            if (sessionId != null) {
                Http http = new Http();
                HttpRequest httpReq = new HttpRequest();
                HttpResponse httpRes = new HttpResponse();
                httpReq.setMethod('GET');
                httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
                httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/metadata/deployRequest/' + idDeployment);
                httpRes = http.send(httpReq);
                System.debug('body :>>>>' + httpRes.getBody());
                String body = httpRes.getBody();
                return httpRes.getBody();
            }
            return 'Session Id Invalid';
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            return ex.getMessage();
        }
    }

    public class SelectOption {
        public String label;
        public String value;
        public SelectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ListViewWrapper {
		public String label;
		public String name;
		public Integer order;
        public Boolean isSelected;
        
        public ListViewWrapper(String label, String name, Integer order, Boolean isSelected) {
            this.label = label;
            this.name = name;
            this.order = order;
            this.isSelected = isSelected;
        }
	}
}