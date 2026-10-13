/**
 * @author ULiT
 * @date 23/08/2024
 * @description Use SettingsManager to load and save CustomSettings/MetadataSettings Objects
 ********************************************************************************************************************************************* */
public with sharing virtual class SettingsManager {
    
    //===================
    // #region Services
    /**
     * @description load CustomSettings
     * @return CustomSettings
     ** */
    public static Object loadCustomSettings(SObjectType sObjectType, String settingsKey, String settingsClass) {
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        String query = 'SELECT ';
        query += !objectFieldsMap.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(objectFieldsMap.keySet()), ',')) : 'Id';
        query += ' FROM ' + String.escapeSingleQuotes(sObjectName);
        query += ' WHERE Name = \'' + settingsKey +'\'';
        if (objectFieldsMap.containsKey('isDeleted__c')) {
            query += ' AND isDeleted__c <> true';
        }
        if (objectFieldsMap.containsKey('Negoptim__isDeleted__c')) {
            query += ' AND Negoptim__isDeleted__c <> true';
        }
        List<SObject> records = Database.query(query);
        SObject customSettingsRecord = records != null && !records.isEmpty() ? records.get(0) : sObjectType.newSObject();
        customSettingsRecord.put('Name', settingsKey);
        //Boolean doesClassExist = MethodUtils.doesClassExist(settingsClass);
        Boolean doesMethodExist = MethodUtils.doesMethodExist(settingsClass, 'load');
        //if (doesClassExist) {
            if (doesMethodExist && !records.isEmpty()) {
                return MethodUtils.invokeMethod(settingsClass, 'load', new List<Object> { customSettingsRecord });
            } else {
                Type classType = Type.forName(settingsClass);
                Object instance = (Object)classType.newInstance();
                return instance;
            }
        /*} else {
            return null;
        }*/
    }
    
    /**
     * @description save CustomSettings
     * @param sObjectType custom settings object
     * @param settingsKey custom settings key
     * @param fieldsValueMap to be saved in custom settings
     * @return Set<String> list of errors, if no errors return an empty list
     **/
    public static Set<String> saveCustomSettings(SObjectType sObjectType, String settingsKey, Map<String, Object> fieldsValueMap) {
        Set<String> errors = new Set<String>();
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, Schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        List<String> customSettingsFields = new List<String>();
        for (String fieldName : objectFieldsMap.keySet()) {
            if (objectFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                customSettingsFields.add(fieldName);
            }
        }
        String query = 'SELECT Id FROM ' + String.escapeSingleQuotes(sObjectName) + ' WHERE Name = \'' + settingsKey +'\'';
        List<SObject> records = Database.query(query);
        SObject customSettingsRecord = sObjectType.newSObject();
        customSettingsRecord.put('Name', settingsKey);
        if (!records.isEmpty()) {
            customSettingsRecord.put('Id', records[0].Id);
        }
        for (String fieldName : fieldsValueMap.keySet()) {
            customSettingsRecord.put(fieldName, fieldsValueMap.get(fieldName));
        }
        try {
            if (NegoptimHelper.checkCreatibility(sObjectType, customSettingsFields)
                && NegoptimHelper.checkUpdatibility(sObjectType, customSettingsFields))
            {
                upsert customSettingsRecord;
            }
        } catch(DmlException ex) {
            errors.add(Label.MSG_Error_Occurred + ' : ' + ex.getDmlMessage(0));
        }
        return errors;
    }
    
    public static String loadCustomSettingsSerialized(SObjectType sObjectType, String settingsKey, String settingsClass) {
        Object settings = loadCustomSettings(sObjectType, settingsKey, settingsClass);
        return JSON.serialize(settings);
    }

    public static Object loadCustomSettingsDeserialized(String settingsSerialized) {
        Object settings = (Object) JSON.deserialize(settingsSerialized, Object.class);
        return settings;
    }
    
    /**
     * @description load all Custom Metadata Records
     * @return List of CustomMetadataSettings
     **/
    public static List<Object> loadAllCustomMetadataSettings(SObjectType sObjectType, String settingsClass) {
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        String query = 'SELECT ';
        query += !objectFieldsMap.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(objectFieldsMap.keySet()), ',')) : 'Id';
        query += ' FROM ' + String.escapeSingleQuotes(sObjectName);
        query += ' WHERE DeveloperName <> NULL';
        if (objectFieldsMap.containsKey('isDeleted__c')) {
            query += ' AND isDeleted__c <> true';
        }
        if (objectFieldsMap.containsKey('Negoptim__isDeleted__c')) {
            query += ' AND Negoptim__isDeleted__c <> true';
        }
        query += ' ORDER BY NamespacePrefix NULLS LAST';
        List<SObject> listMetadataRecords = Database.query(query);
        Map<String, SObject> listMetadataRecordsMap = new Map<String, SObject>();
        for(SObject record : listMetadataRecords) {
            listMetadataRecordsMap.put(String.valueOf(record.get('DeveloperName')), record);
        }
        //Boolean doesClassExist = MethodUtils.doesClassExist(settingsClass);
        Boolean doesMethodExist = MethodUtils.doesMethodExist(settingsClass, 'load');
        List<Object> allRecordsCustomMetadataSettings = new List<Object>();
        if (doesMethodExist && !listMetadataRecordsMap.isEmpty() && !Test.isRunningTest()) {
            for (SObject record : listMetadataRecordsMap.values()) {
                allRecordsCustomMetadataSettings.add(MethodUtils.invokeMethod(settingsClass, 'load', new List<Object> { record }));
            }
        } else {
            return new List<Object>();
        }
        return allRecordsCustomMetadataSettings;
    }
    
    /**
     * @description load all Custom Metadata Records with conditions
     * @return List of CustomMetadataSettings
     **/
    public static List<Object> loadAllCustomMetadataSettings(SObjectType sObjectType, String settingsClass, List<String> conditions) {
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        String query = 'SELECT ';
        query += !objectFieldsMap.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(objectFieldsMap.keySet()), ',')) : 'Id';
        query += ' FROM ' + String.escapeSingleQuotes(sObjectName);
        query += ' WHERE DeveloperName <> NULL';
        if (conditions != null && !conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        if (objectFieldsMap.containsKey('isDeleted__c')) {
            query += ' AND isDeleted__c <> true';
        }
        if (objectFieldsMap.containsKey('Negoptim__isDeleted__c')) {
            query += ' AND Negoptim__isDeleted__c <> true';
        }
        query += ' ORDER BY NamespacePrefix NULLS LAST';
        List<SObject> listMetadataRecords = Database.query(query);
        Map<String, SObject> listMetadataRecordsMap = new Map<String, SObject>();
        for(SObject record : listMetadataRecords) {
            listMetadataRecordsMap.put(String.valueOf(record.get('DeveloperName')), record);
        }
        //Boolean doesClassExist = MethodUtils.doesClassExist(settingsClass);
        Boolean doesMethodExist = MethodUtils.doesMethodExist(settingsClass, 'load');
        List<Object> allRecordsCustomMetadataSettings = new List<Object>();
        if (doesMethodExist && !listMetadataRecordsMap.isEmpty() && !Test.isRunningTest()) {
            for (SObject record : listMetadataRecordsMap.values()) {
                allRecordsCustomMetadataSettings.add(MethodUtils.invokeMethod(settingsClass, 'load', new List<Object> { record }));
            }
        } else {
            return new List<Object>();
        }
        return allRecordsCustomMetadataSettings;
    }
    
    /**
     * @description load CustomMetadataSettings
     * @return CustomMetadataSettings
     **/
    public static Object loadCustomMetadataSettings(SObjectType sObjectType, String settingsKey, String settingsClass) {
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        String query = 'SELECT ';
        query += !objectFieldsMap.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(objectFieldsMap.keySet()), ',')) : 'Id';
        query += ' FROM ' + String.escapeSingleQuotes(sObjectName);
        query += ' WHERE DeveloperName = \'' + settingsKey + '\'';
        if (objectFieldsMap.containsKey('isDeleted__c')) {
            query += ' AND isDeleted__c <> true';
        }
        if (objectFieldsMap.containsKey('Negoptim__isDeleted__c')) {
            query += ' AND Negoptim__isDeleted__c <> true';
        }
        query += ' ORDER BY NamespacePrefix NULLS FIRST';
        List<SObject> listMetadataRecords = Database.query(query);
        SObject metadataRecord = listMetadataRecords != null && !listMetadataRecords.isEmpty() ? listMetadataRecords.get(0) : sObjectType.newSObject();
        metadataRecord.put('DeveloperName', settingsKey);
        //Boolean doesClassExist = MethodUtils.doesClassExist(settingsClass);
        Boolean doesMethodExist = MethodUtils.doesMethodExist(settingsClass, 'load');
        //if (doesClassExist) {
            if (doesMethodExist && !listMetadataRecords.isEmpty() && !Test.isRunningTest()) {
                return MethodUtils.invokeMethod(settingsClass, 'load', new List<Object> { metadataRecord });
            } else {
                Type classType = Type.forName(settingsClass);
                Object instance = (Object)classType.newInstance();
                return instance;
            }
        /*} else {
            return null;
        }*/
    }
    /**
     * @description load CustomMetadataSettings with conditions
     * @return CustomMetadataSettings
     **/
    public static Object loadCustomMetadataSettings(SObjectType sObjectType, String settingsKey, String settingsClass, List<String> conditions) {
        String sObjectName = sObjectType.getDescribe().getName();
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        String query = 'SELECT ';
        query += !objectFieldsMap.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(objectFieldsMap.keySet()), ',')) : 'Id';
        query += ' FROM ' + String.escapeSingleQuotes(sObjectName);
        query += ' WHERE DeveloperName = \'' + settingsKey + '\'';
        if (conditions != null && !conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        if (objectFieldsMap.containsKey('isDeleted__c')) {
            query += ' AND isDeleted__c <> true';
        }
        if (objectFieldsMap.containsKey('Negoptim__isDeleted__c')) {
            query += ' AND Negoptim__isDeleted__c <> true';
        }
        query += ' ORDER BY NamespacePrefix NULLS FIRST';
        List<SObject> listMetadataRecords = Database.query(query);
        SObject metadataRecord = listMetadataRecords != null && !listMetadataRecords.isEmpty() ? listMetadataRecords.get(0) : sObjectType.newSObject();
        metadataRecord.put('DeveloperName', settingsKey);
        //Boolean doesClassExist = MethodUtils.doesClassExist(settingsClass);
        Boolean doesMethodExist = MethodUtils.doesMethodExist(settingsClass, 'load');
        //if (doesClassExist) {
            if (doesMethodExist && !listMetadataRecords.isEmpty() && !Test.isRunningTest()) {
                return MethodUtils.invokeMethod(settingsClass, 'load', new List<Object> { metadataRecord });
            } else {
                Type classType = Type.forName(settingsClass);
                Object instance = (Object)classType.newInstance();
                return instance;
            }
        /*} else {
            return null;
        }*/
    }
    
    /**
     * @description save CustomMetadataSettings
     * @return Id
     **/
    public static String saveCustomMetadataSettings(SObjectType sObjectType, String settingsKey, Map<String, Object> fieldsValueMap) {
        try {
            // Set up custom metadata to be created in the subscriber org.
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = sObjectType.getDescribe().getName() + '.' + (settingsKey.length() > 40 ? settingsKey.subString(0, 40) : settingsKey);
            customMetadata.label = settingsKey;
            // Add all the field values
            Metadata.CustomMetadataValue customField;
            for (String fieldName : fieldsValueMap.keySet()) {
                customField = new Metadata.CustomMetadataValue();
                customField.field = fieldName;
                customField.value = fieldsValueMap.get(fieldName);
                customMetadata.values.add(customField);
            }
            Id jobId = null;
            if (!Test.isRunningTest()) {
                System.debug('Full Name: ' + customMetadata.fullName);
                System.debug('Label: ' + customMetadata.label);
                System.debug(JSON.serializePretty(customMetadata));
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(customMetadata);
                // Setup deploy callback, MyDeployCallback implements
                // the Metadata.DeployCallback interface
                CustomMetadataCallback callback = new CustomMetadataCallback();
                // Enqueue custom metadata deployment
                // jobId is the deployment ID
                jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            }
            return jobId;
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    /**
     * @description save CustomMetadataSettings
     * @return Id
     **/
    public static String saveAllCustomMetadataSettings(SObjectType sObjectType, Map<String, Map<String, Object>> metadataRecordsMap) {
        try {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            Metadata.CustomMetadata customMetadata;
            for (String settingsKey : metadataRecordsMap.keySet()) {
                // Set up custom metadata to be created in the subscriber org.
                customMetadata = new Metadata.CustomMetadata();
                customMetadata.fullName = sObjectType.getDescribe().getName() + '.' + (settingsKey.length() > 40 ? settingsKey.subString(0, 40) : settingsKey);
                customMetadata.label = settingsKey;
                // Add all the field values
                Metadata.CustomMetadataValue customField;
                for (String fieldName : metadataRecordsMap.get(settingsKey).keySet()) {
                    customField = new Metadata.CustomMetadataValue();
                    customField.field = fieldName;
                    customField.value = metadataRecordsMap.get(settingsKey).get(fieldName);
                    customMetadata.values.add(customField);
                }
                mdContainer.addMetadata(customMetadata);
            }
            Id jobId = null;
            if (!Test.isRunningTest()) {
                // Setup deploy callback, MyDeployCallback implements
                // the Metadata.DeployCallback interface
                CustomMetadataCallback callback = new CustomMetadataCallback();
                // Enqueue custom metadata deployment
                // jobId is the deployment ID
                jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            }
            return jobId;
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    public static String checkCustomMetadataDeploymentStatus(String idDeployment) {
        if (!Test.isRunningTest()) {
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
        return 'Test Running';
    }
}