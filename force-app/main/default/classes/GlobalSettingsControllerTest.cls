/**
 * Unit test class for Global Settings Controller
 * Insert/Update file settings
 * */
@isTest
private class GlobalSettingsControllerTest {

    // Insert file settings
    @isTest static void insertSettings_Success() {
        Folder folder = NegoptimHelper.getFolderSettings();
        GlobalSettingsController instance = new GlobalSettingsController();
        List<SelectOption> delimiters = instance.getDelimiters();
        List<SelectOption> groups = instance.getGroups();
        if(delimiters.size() > 0) instance.negoSettings.delimiter = delimiters.get(0).getValue();
        if(groups.size() > 0) instance.negoSettings.groupBU = groups.get(0).getValue();
        Test.startTest();
        instance.save();
        Test.stopTest();
        AggregateResult[] c = [SELECT Count(Id) c FROM Document];
        if(folder != null) {
            System.assertEquals(1, c[0].get('c'));
        }
    }
    // Update file settings
    @isTest static void updateSettings_Success() {
        // Create Document
        Folder folder = NegoptimHelper.getFolderSettings();
        Document document;
        if(folder != null) {
            String str = '{"delimiter": "," , "groupBU": "AMC"}';
            document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Body = Blob.valueof(str), FolderId = folder.Id );
            insert document;
        }
        GlobalSettingsController instance = new GlobalSettingsController();
        List<SelectOption> delimiters = instance.getDelimiters();
        List<SelectOption> groups = instance.getGroups();
        if(delimiters.size() > 0) instance.negoSettings.delimiter = delimiters.get(0).getValue();
        if(groups.size() > 0) instance.negoSettings.groupBU = groups.get(0).getValue();
        Test.startTest();
        instance.save();
        Test.stopTest();
        AggregateResult[] c = [SELECT Count(Id) c FROM Document];
        if(folder != null) {
            System.assertEquals(1, c[0].get('c'));
        }
    }

    @isTest static void testGetBusinessTypes(){
        GlobalSettingsController instance = new GlobalSettingsController();

        List<SelectOption> options = instance.getBusinessTypes();
        System.assertEquals(3, options.size());
    }

    @isTest static void testGetReminderLevel(){
        GlobalSettingsController instance = new GlobalSettingsController();

        List<SelectOption> options = instance.getReminderLevels();
        System.assertEquals(4, options.size());
    }

    @isTest static void testGetBuRecordType(){
        GlobalSettingsController instance = new GlobalSettingsController();

        List<SelectOption> options = instance.getBURecordTypes();
        System.assert(options.size() > 0);
    }

    @isTest static void testGetGroupBu() {
        BusinessUnit__c groupTest = TestDataFactory.createBusinessUnitGroup(true, 'Test');

        GlobalSettingsController instance = new GlobalSettingsController();

        List<SelectOption> options = instance.getGroupsBU();

        boolean isAvailableTest = false;
        for(SelectOption option : options) {
            if(groupTest.Name.equals(option.getLabel()))
                isAvailableTest = true;
        }

        System.assertEquals(true, isAvailableTest);
        System.assertEquals(2, options.size());
    }

    @isTest static void testGetProfile(){
        GlobalSettingsController instance = new GlobalSettingsController();

        List<SelectOption> options = instance.getProfiles();
        System.assert(options.size() > 0);
    }
}