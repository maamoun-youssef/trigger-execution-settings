@isTest
private class SynchroASRegionCtrlTest {

    private static Integer year;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c client;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Assortment__c assortment;
    
    static void init() {
        try {
            // Root element Id.
            Id rootId = NegoptimHelper.getRootIdByRT('Product');
            year = System.Today().year();
            region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            client = TestDataFactory.createSupplier(true, country, false);
            // create HEs
            department = TestDataFactory.createHierarchyDepartment(false, rootId);
            department.SetProductLevel__c = true;
            insert department;
            section = TestDataFactory.createHierarchySection(true, department.Id);
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            insert new List<BusinessUnit__c> {buSource};
            assortment = new Assortment__c(Name = 'Ass1', BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = region.Id,
                                           Hierarchy__c = department.Id, Status__c = 'Open',
                                           BDate__c = Date.newInstance(year, 1, 1),
                                           EDate__c = Date.newInstance(year, 12, 31), Year__c = year);
            insert assortment;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest
    static void loadDataTest() {
        init();
        Test.startTest();
        String result = SynchroASRegionCtrl.loadData(assortment.Id);
        List<SynchroASRegionCtrl.BUWrapper> wrapperList = String.isNotBlank(result) ? (List<SynchroASRegionCtrl.BUWrapper>) JSON.deserialize(result, List<SynchroASRegionCtrl.BUWrapper>.class) : new List<SynchroASRegionCtrl.BUWrapper>();
        Test.stopTest();
        System.assertEquals(1, wrapperList.size());
    }
}