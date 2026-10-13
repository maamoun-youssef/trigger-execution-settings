/**
 * @author ULiT
 * @date 13-may-2024
*/
@isTest
private class AssortmentDirectAccessPluginCtrlTest {

    private static Integer year;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c client;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<BusinessUnit__c> stratList;
    private static List<Hierarchy__c> orgaHEList;
    private static List<Product2> products;
    private static Map<String, Id> assRTIds;
    private static Hierarchy__c assortmentCategory;
    private static Assortment__c assortment;
    private static List<AssortmentDetail__c> details;
    static void init() {
        try {
            Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
            assRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
            // NegoptimCustomSettings__c negoptimCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            // negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = CommonConstants.GRID_SETTINGS_DEFAULT;
            // negoptimCustomSettings.Higher_Level_Packaging_Record_Type_Id__c = productRTIds.get('Higher_Level_Packaging');
            // insert negoptimCustomSettings;
            year = System.Today().year();
            region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            client = TestDataFactory.createSupplier(true, country, false);
            orgaHEList = TestDataFactory.createElementHierarchy(4, 1);
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = client.Id;
            buTarget.Hierarchy__c = orgaHEList[1].Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
                
            stratList = new List<BusinessUnit__c>();
            for (Integer i = 0; i < 4; i++) {
                stratList.add(TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + i));
            }
            BusinessUnit__c closedBU = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat0');
            closedBU.ClosingDate__c = System.Today().addMonths(-1);
            stratList.add(closedBU);
            insert stratList;
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                products.add(TestDataFactory.createProduct(false, orgaHEList[4].Id, null));
            }
            // assDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
            insert products;
            assortment = new Assortment__c(Name = 'Ass1', BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                     Hierarchy__c = orgaHEList[1].Id, Status__c = 'Open',
                                                     BDate__c = Date.newInstance(System.Today().year(), 1, 1),
                                                     EDate__c = Date.newInstance(System.Today().year(), 12, 31), Year__c = System.Today().year(), RecordTypeId = assRTIds.get('Negotiation') + '');
            insert assortment;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static testMethod void test_getData() {
        init();
        Test.startTest();
        AssortmentDirectAccessPluginCtrl.MainWrapper mainWrapper = (AssortmentDirectAccessPluginCtrl.MainWrapper) JSON.deserialize(AssortmentDirectAccessPluginCtrl.initData(), AssortmentDirectAccessPluginCtrl.MainWrapper.class);
        String gridsettings = JSON.serialize(mainWrapper.gridSettingsManager);
        String serializedResult = AssortmentDirectAccessPluginCtrl.getAssortments(gridsettings, 50, 1, '', null);
        AssortmentDirectAccessPluginCtrl.AssortmentWrapper result = (AssortmentDirectAccessPluginCtrl.AssortmentWrapper) JSON.deserialize(serializedResult, AssortmentDirectAccessPluginCtrl.AssortmentWrapper.class);
        System.assertEquals(1, result.numberOfRecords);
        Test.stopTest();
    }
    
    static testMethod void test_getFilteredData() {
        init();
        AssortmentDirectAccessPluginCtrl.MainWrapper mainWrapper = (AssortmentDirectAccessPluginCtrl.MainWrapper) JSON.deserialize(AssortmentDirectAccessPluginCtrl.initData(), AssortmentDirectAccessPluginCtrl.MainWrapper.class);
        String gridsettings = JSON.serialize(mainWrapper.gridSettingsManager);
        Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
        Test.startTest();
        AssortmentDirectAccessPluginCtrl.FilterWrapper filter = new AssortmentDirectAccessPluginCtrl.FilterWrapper(String.valueOf(System.Today().year()), buTarget.Id, buSource.Id, String.valueOf(orgaHEList[1].Id), new List<String>{'\'' + assortmentRTIds.get('Negotiation') + '\''});
        String serializedResult = AssortmentDirectAccessPluginCtrl.getAssortments(gridsettings, 50, 1, JSON.serialize(filter), 'Name');
        AssortmentDirectAccessPluginCtrl.AssortmentWrapper result = (AssortmentDirectAccessPluginCtrl.AssortmentWrapper) JSON.deserialize(serializedResult, AssortmentDirectAccessPluginCtrl.AssortmentWrapper.class);
        System.assertEquals(1, result.numberOfRecords);
        Test.stopTest();
    }
    @isTest static void testSendEmailSuccess() {
        init();
        // Setup test data
        String emailTo = 'test@example.com';
        String name = 'TestName';
        String emailCc = 'cc@example.com';
        String emailBcc = 'bcc@example.com';
        String emailSubject = 'Test Subject';
        String emailBody = 'Test Body';
        String recordId = assortment.Id; // Use a valid record ID
        String assortmentName = 'TestAssortment';

        // Call the method to test
        Test.startTest();
        String result = AssortmentDirectAccessPluginCtrl.sendEmail(emailTo, name, emailCc, emailBcc, emailSubject, emailBody, 'Test', recordId, assortmentName);
        Test.stopTest();

        // Verify the results
        System.assertEquals('Email sent successfully.', result, 'The email should be sent successfully.');
    }

    @isTest static void testSendEmailFailure() {
        init();
        // Setup test data with invalid email addresses to simulate failure
        String emailTo = 'invalid';
        String name = 'TestName';
        String emailCc = 'invalid';
        String emailBcc = 'invalid';
        String emailSubject = 'Test Subject';
        String emailBody = 'Test Body';
        String recordId = assortment.Id; // Use a valid record ID
        String assortmentName = 'TestAssortment';

        // Call the method to test
        Test.startTest();
        String result = AssortmentDirectAccessPluginCtrl.sendEmail(emailTo, name, emailCc, emailBcc, emailSubject, emailBody, 'Test', recordId, assortmentName);
        Test.stopTest();

        // Verify the results
        System.assertNotEquals('Email sent successfully.', result, 'The email should not be sent due to invalid addresses.');
    }
}