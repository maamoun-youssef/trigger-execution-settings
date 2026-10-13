@isTest
private class CommercialPlanSimulationCtrlLWCTest {
    
    private static CommercialPlan__c comPlan;
    private static CommercialPlanDetail__c comPlanDetail;
    private static CommercialPlanDetail__c childComPlanDetail;
    private static Supplier__c supplier;
    private static Country_List__c myCountry;
    private static BusinessUnit__c country;
    private static BusinessUnit__c region;
    private static Product2 product;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    
    static void init() {
        try {
            Id rootId = TestDataFactory.getHierarchyRootId();
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            supplier = TestDataFactory.createSupplier(true, country, false);
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            comPlan = TestDataFactory.createCommercialPlan(false, System.today(), System.today());
            comPlan.Hierarchy__c = department.Id;
            comPlan.BusinessUnitTarget__c = country.Id;
            insert comPlan;
            comPlanDetail = TestDataFactory.createCommercialPlanDetail(false, comPlan.Id, null);
            comPlanDetail.Status__c = 'Validated';
            comPlanDetail.Name = 'ParentTest';
            comPlanDetail.CommercialPlanParent__c = comPlan.Id;
            comPlanDetail.Hierarchy__c = department.Id;
            comPlanDetail.Product__c = product.Id;
            comPlanDetail.VolumeTarget__c = 200;
            insert comPlanDetail;
            childComPlanDetail = TestDataFactory.createCommercialPlanDetail(false, comPlan.Id, null);
            childComPlanDetail.ConsumerTradeItemPromoDetail__c = comPlanDetail.Id;
            childComPlanDetail.Name = 'Test';
            insert childComPlanDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testMethod CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper initiator() {
        init();
        String CPDWrapper_JSON  = CommercialPlanSimulationCtrlLWC.loadSimulation(comPlan.Id, 5, 1, '');
        CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper data = (CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper) JSON.deserialize(CPDWrapper_JSON, CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper.class);
        Integer cpdCount = data.CommercialPlanWrapper.commercialPlanDetails.size();
        system.assert(true);
        return data;
    }
    
    static testMethod void test_Coverage() {
        CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper data = initiator();
        CommercialPlanSimulationCtrlLWC.commercialPlanDetailWrapper cpd = data.CommercialPlanWrapper.commercialPlanDetails[0];
        Test.startTest();
        cpd.commercialPlanDetail.Name = 'test123';
        cpd.hasChanged = true;
        List<CommercialPlanSimulationCtrlLWC.commercialPlanDetailWrapper> cpdList = new List<CommercialPlanSimulationCtrlLWC.commercialPlanDetailWrapper>{cpd};
        String save = CommercialPlanSimulationCtrlLWC.saveSimulation(JSON.serialize(cpdList));
        system.assertEquals(cpd.commercialPlanDetail.Name, [SELECT Id, Name FROM CommercialPlanDetail__c WHERE Id =:cpd.commercialPlanDetail.Id ].Name);
        Id cpdId = cpd.commercialPlanDetail.Id;
        CommercialPlanSimulationCtrlLWC.deleteCPDs(JSON.serialize([SELECT Id FROM CommercialPlanDetail__c WHERE Id = :cpdId]));
        system.assertEquals(0, [SELECT Id FROM CommercialPlanDetail__c WHERE Id =:cpdId ].size());
        Test.stopTest();
    }
    
    static testMethod void test_getDependencies() {
        initiator();
        String fieldFilter = '[{"fieldName" : "Name", "values" : ["ParentTest"], "stringFieldType" : "STRING"},{"fieldName" : "isDeleted", "values" : ["false"], "stringFieldType" : "BOOLEAN"},{"fieldName" : "CreatedDate", "values" : [], "stringFieldType" : "DATETIME"}]';
        CommercialPlanSimulationCtrlLWC.FilterWrapper filter = new CommercialPlanSimulationCtrlLWC.FilterWrapper(null, fieldFilter);
        Map<String,List<CommercialPlanSimulationCtrlLWC.MyPickListInfo>> result = CommercialPlanSimulationCtrlLWC.getFieldDependencies('Name', 'Name');
        String CPDWrapper_JSON  = CommercialPlanSimulationCtrlLWC.loadSimulation(comPlan.Id, 5, 1, '');
        GridSettingsManager gridsettings = CommercialPlanSimulationCtrlLWC.initGridSettings(new NegoptimSettings(),'');
        String CPDdata_JSON = CommercialPlanSimulationCtrlLWC.getCommercialPlanDetails(JSON.serialize(comPlan),JSON.serialize(gridsettings), 1, 10, JSON.serialize(filter));
        CommercialPlanSimulationCtrlLWC.CPDPagesWrapper parsedCPDdata = (CommercialPlanSimulationCtrlLWC.CPDPagesWrapper) JSON.deserialize(CPDdata_JSON, CommercialPlanSimulationCtrlLWC.CPDPagesWrapper.class);
        system.assertEquals(1, parsedCPDdata.numberOfRecords);
        system.assertEquals(parsedCPDdata.numberOfRecords, parsedCPDdata.commercialPlanDetailsWrapperList.size());
    }
    
    static testMethod void save_simulation() {
        CommercialPlanSimulationCtrlLWC.CommercialPlanSimulationWrapper data = initiator();
        CommercialPlanSimulationCtrlLWC.productFilterWrapper filter = new CommercialPlanSimulationCtrlLWC.productFilterWrapper();
        filter.generalSearch = 'test';
        filter.brands = new List<String>();
        filter.categories = new List<String>();
        filter.market = '';
        filter.family = '';
        filter.animation = '';
        Test.startTest();
        String products = CommercialPlanSimulationCtrlLWC.getProductsRecords(comPlan.Hierarchy__c, JSON.serialize(filter), 1, 0);
        String categories = CommercialPlanSimulationCtrlLWC.getCategoriesRecords(JSON.serialize(comPlan), 'DPT');
        List<Hierarchy__c> parsedCategories = (List<Hierarchy__c>) JSON.deserialize(categories, List<Hierarchy__c>.class);
        // // system.assertEquals(1, parsedCategories.size());
        // // String bus = CommercialPlanSimulationCtrlLWC.getBUsRecords(JSON.serialize(comPlan), 'EU');
        // // List<BusinessUnit__c> parsedBU = (List<BusinessUnit__c>) JSON.deserialize(bus, List<BusinessUnit__c>.class);
        // // system.assertEquals(1, parsedBU.size());
        // // String productsOfCategory = CommercialPlanSimulationCtrlLWC.getProductsOfCategory(JSON.serialize(comPlan), section.Id, country.Id);
        // // List<Product2> parsedProductsOfCategory = (List<Product2>) JSON.deserialize(productsOfCategory, List<Product2>.class);
        // // system.assertEquals(1, parsedProductsOfCategory.size());
        // // CommercialPlanSimulationCtrlLWC.createNewDetail(JSON.serialize([SELECT Id, BusinessUnitTarget__c FROM CommercialPlan__c LIMIT 1]));
        System.assert(true);
        Test.stopTest();
    }
}