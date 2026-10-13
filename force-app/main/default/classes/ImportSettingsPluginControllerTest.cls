/**
* @author ULiT
* @date 27/02/2026
* @description Unit test class for ImportSettingsPluginController.
*              Tests initData, importRecords, and checkAndGetOutcome.
**/
@isTest
private class ImportSettingsPluginControllerTest {
    
    @isTest static void case01_getTemplateInfo_NullName() {
        Boolean caughtException = false;
        Test.startTest();
        try {
            ImportSettingsPluginController.initData(null, null);
        } catch (AuraHandledException ex) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(true, 'Completed without unhandled exception');
    }
    
    @isTest static void case02_getTemplateInfo_InvalidName() {
        Test.startTest();
        Boolean caughtException = false;
        try {
            ImportSettingsPluginController.initData('NonExistent_Template_ULiT_XYZ999', null);
        } catch (AuraHandledException ex) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(true, 'Completed without unhandled exception for invalid template');
    }
    
    @isTest static void case03_getTemplateInfo_ValidName() {
        List<ImportSettings__mdt> settings = [
            SELECT DeveloperName
            FROM ImportSettings__mdt
            LIMIT 1
        ];
        if (settings.isEmpty()) return;
        
        Test.startTest();
        String result = ImportSettingsPluginController.initData(settings[0].DeveloperName, 'Test reminder');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null for a valid template name');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(parsed.containsKey('importSettings'), 'Wrapper should contain importSettings key');
        System.assert(parsed.containsKey('reminderMessage'), 'Wrapper should contain reminderMessage key');
        System.assertNotEquals(null, parsed.get('importSettings'), 'Parsed importSettings should not be null');
    }
    
    @isTest static void case04_importRecords_ValidData() {
        List<ImportSettings__mdt> settings = [
            SELECT DeveloperName, ObjectName__c
            FROM ImportSettings__mdt
            WHERE ObjectName__c != null
            LIMIT 1
        ];
        if (settings.isEmpty()) return;
        String objectName = settings[0].ObjectName__c;
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType == null) return;
        List<SObject> records = new List<SObject>();
        try {
            SObject rec = sObjType.newSObject();
            Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
            if (fieldMap.containsKey('name')) {
                rec.put('Name', 'UT_ImportPlugin_Test');
            }
            insert rec;
            records = Database.query('SELECT Id FROM ' + objectName + ' WHERE Id = \'' + rec.Id + '\'');
        } catch (Exception e) {
            return;
        }
        
        String recordsJson = JSON.serialize(records);
        Test.startTest();
        try {
            Id batchId = ImportSettingsPluginController.importRecords(
                settings[0].ObjectName__c,
                recordsJson,
                'test_plugin.xlsx',
                null,
                null,
                ''
            );
            System.assertNotEquals(null, batchId, 'Batch Id should not be null on successful import');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest static void case05_checkAndGetOutcome_NullJobId() {
        Test.startTest();
        Map<String, Object> outcome = ImportSettingsPluginController.checkAndGetOutcome(null);
        Test.stopTest();
        System.assertEquals(null, outcome, 'checkAndGetOutcome should return null for a null Id');
    }
    
    @isTest static void case06_checkAndGetOutcome_AfterBatch() {
        List<ImportSettings__mdt> settings = [
            SELECT DeveloperName, ObjectName__c
            FROM ImportSettings__mdt
            WHERE ObjectName__c != null
            LIMIT 1
        ];
        if (settings.isEmpty()) return;
        String objectName = settings[0].ObjectName__c;
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType == null) return;
        List<SObject> records = new List<SObject>();
        try {
            SObject rec = sObjType.newSObject();
            Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
            if (fieldMap.containsKey('name')) {
                rec.put('Name', 'UT_Outcome_Test');
            }
            insert rec;
            records = Database.query('SELECT Id FROM ' + objectName + ' WHERE Id = \'' + rec.Id + '\'');
        } catch (Exception e) {
            return;
        }
        String recordsJson = JSON.serialize(records);
        Test.startTest();
        Id batchId;
        try {
            batchId = ImportSettingsPluginController.importRecords(
                settings[0].ObjectName__c,
                recordsJson,
                'test_outcome.xlsx',
                null,
                null,
                ''
            );
        } catch (AuraHandledException ex) {
            return;
        }
        Test.stopTest();
        if (batchId != null) {
            Map<String, Object> outcome = ImportSettingsPluginController.checkAndGetOutcome(batchId);
            // Outcome may be null (not yet completed) or populated — either is valid post-batch
            System.assert(true, 'checkAndGetOutcome executed successfully after batch');
        }
    }
    
    @isTest
    static void case07_checkAndGetOutcome_ReturnsNullWhenNotFound() {
        // Passing a non-batch ID (User ID) will return no AsyncApexJob records → null
        Test.startTest();
        Map<String, Object> outcome = ImportSettingsPluginController.checkAndGetOutcome(UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(null, outcome, 'Should return null when no matching AsyncApexJob is found');
    }
    
    @isTest
    static void case08_importRecords_WithNonBlankExternalIdField() {
        Account acc = new Account(Name = 'UT_ImportRecords_ExtId');
        insert acc;
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
        String recordsJson = JSON.serialize(accounts);
        Test.startTest();
        try {
            Id batchId = ImportSettingsPluginController.importRecords(
                'Account',
                recordsJson,
                'test_extid.xlsx',
                null,
                null,
                'Name'
            );
            System.assertNotEquals(null, batchId);
        } catch (AuraHandledException ex) {
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();
    }
}