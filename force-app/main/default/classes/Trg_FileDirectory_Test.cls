/**
 * @author ULiT
 * @date 26/11/2024
 * @description Unit test class to cover/test Trg_FileDirectory trigger
 * */
@isTest
private class Trg_FileDirectory_Test {
    public static Supplier__c supplier;
    public static Negoscope__c negoscope;
    public static List<String> subTypeList = new List<String>{'Admin Certification'};

    public static void init() {
        supplier = new Supplier__c(Name = 'Test Supplier', Code__c = 'sup2');
        insert supplier;
        negoscope = new Negoscope__c(Name = 'Test Negoscope', Supplier__c = supplier.Id, Code__c = '4');
        insert negoscope;
    }

    @isTest
    public static void testShareDocsCase0() {
        init();
        ContentVersion cv = new ContentVersion(
                                Title = 'Test File ',
                                PathOnClient = 'TestFile.txt',
                                VersionData = Blob.valueOf('This is test file content.'),
                                IsMajorVersion = true
                            );
        insert cv;
        List<ContentVersion> queriedCVList = [SELECT Id, ContentDocumentId, OwnerId FROM ContentVersion];                  
        Test.startTest();
        FileDirectory__c newFD =  new FileDirectory__c (
                                        ContentDocumentId__c = queriedCVList[0].ContentDocumentId,
                                        Supplier__c = supplier.Id,
                                        Negoscope__c = negoscope.Id,
                                        IsPortalPublished__c = true,
                                        SubType__c = subTypeList[0]);        
        insert newFD;
        Test.stopTest();
        System.assertNotEquals(null, newFD.Id, 'file directory was not inserted');
    }

    @isTest
    public static void testShareDocsCase1() {
        init();
        ContentVersion cv = new ContentVersion(
                                Title = 'Test File ',
                                PathOnClient = 'TestFile.txt',
                                VersionData = Blob.valueOf('This is test file content.'),
                                IsMajorVersion = true
                            );
        insert cv;
        List<ContentVersion> queriedCVList = [SELECT Id, ContentDocumentId, OwnerId FROM ContentVersion];           
        FileDirectory__c newFD =  new FileDirectory__c (
            ContentDocumentId__c = queriedCVList[0].ContentDocumentId,
            Supplier__c = supplier.Id,
            Negoscope__c = negoscope.Id,
            IsPortalPublished__c = true,
            Status__c = 'Receipt Confirmed',
            SubType__c = subTypeList[0]);
        insert newFD;
        Test.startTest();
        newFD.IsPortalPublished__c = false;
        update newFD;
        Test.stopTest();
        System.assertEquals(false, newFD.IsPortalPublished__c, 'file directory was not updated');
    }
}