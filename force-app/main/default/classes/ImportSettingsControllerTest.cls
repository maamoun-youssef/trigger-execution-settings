/**
 * @author ULiT
 * @date 27/01/2024
 * @desciption unit test class for ImportSettingsController
 **/
@isTest
private class ImportSettingsControllerTest {
   
    @isTest static void case1_loadImportSettings() {
        Test.startTest();
        ImportSettingsController.loadImportSettings(null);
        Test.stopTest();
    }

    @isTest static void case2_loadAllData() {
        Test.startTest();
        ImportSettingsController.loadAllData();
        Test.stopTest();
    }

    @isTest static void case3_getAllObject() {
        Test.startTest();
        ImportSettingsController.getAllObject();
        Test.stopTest();
    }

    @isTest static void case4_getRelatedObjectExtIdFields() {
        Test.startTest();
        List<String> objectNames = new List<String>();
        objectNames.add(SObjectType.Supplier__c.Name);
        objectNames.add(SObjectType.Contract__c.Name);
        objectNames.add(SObjectType.Product2.Name);
        objectNames.add(SObjectType.PG__c.Name);
        ImportSettingsController.getRelatedObjectExtIdFields(objectNames);
        Test.stopTest();
    }

    @isTest static void case7_save() {
        Test.startTest();
        ImportSettings importSettings = new ImportSettings();
        String recordsToUpsertJSON = '[{"name":"PDSD_Import_Regular_Settings","extIdSeparator":",",';
        recordsToUpsertJSON += '"objectName":"ProductDiscountStatementDetail__c","status":"Open","fields":[{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_PRDName__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_PRDGTIN__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_PRDCode__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_PCCCode__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_BUName__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_BUCode__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"BDate__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"EDate__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"input_CPCode__c","isUser":true,"isRequired":true,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"ProductQty__c","isUser":false,"isRequired":false,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"ProductQtyMax__c","isUser":false,"isRequired":false,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"ProductQtyMin__c","isUser":false,"isRequired":false,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"DeclarantComment__c","isUser":false,"isRequired":false,"isAdmin":true},{"referenceExtIdOrder":null,"referenceExtId":null,"name":"GrossPrice__c","isUser":false,"isRequired":false,"isAdmin":true}]}]';
        String idDeployment = ImportSettingsController.save(recordsToUpsertJSON);
        ImportSettingsController.checkDeploymentStatus(idDeployment);
        Test.stopTest();
    }
    
    @isTest static void case8_uploadFile() {
        Account p = new Account(Name = 'Import Parent');
        insert p;
        String b64 = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        Test.startTest();
        Id fileDirectoryId = ImportSettingsController.uploadFile(p.Id, 'test.txt', b64, 'text/plain');
        Test.stopTest();
        System.assertNotEquals(null, FileDirectoryId);
        FileDirectory__c fd = [SELECT DocumentName__c, ContentDocumentId__c, ParentId__c
                               FROM FileDirectory__c
                               WHERE Id = :fileDirectoryId];
        System.assertEquals('test.txt', fd.DocumentName__c);
        System.assertEquals(p.Id, fd.ParentId__c);
        ContentVersion cv = [SELECT Title
                             FROM ContentVersion
                             WHERE ContentDocumentId = :fd.ContentDocumentId__c
                             LIMIT 1];
        System.assertEquals('test.txt', cv.Title);
        ContentDocumentLink cdl = [SELECT ShareType
                                   FROM ContentDocumentLink
                                   WHERE ContentDocumentId = :fd.ContentDocumentId__c
                                   AND LinkedEntityId = :p.Id
                                   LIMIT 1];
        System.assertEquals('V', cdl.ShareType);
    }
}