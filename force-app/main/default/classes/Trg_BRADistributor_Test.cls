/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for BRADistributor__c object
 * */
@isTest
private class Trg_BRADistributor_Test {
	
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static Supplier__c supplier3;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static PG__c pg1;
    private static PG__c pg2;
    
    static void init() {
    	try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, true);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            supplier3 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c> {supplier1, supplier2, supplier3};
            // Get the default NegoScope created on supplier creation
            NS = [SELECT Id FROM NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createHierarchySection(false, department.Id);
            // Create Brand that automatically related to NS due to trigger
            brand1 = TestDataFactory.createBrand(false, supplier1.Id);
            brand2 = TestDataFactory.createBrand(false, supplier2.Id);
    		insert new List<Brand__c> {brand1, brand2};
            // Create PG that automatically related to NS due to trigger
            pg1 = TestDataFactory.createPG(false, supplier1.Id, section.Id);
            pg1.Brand__c = brand1.Id;
            pg2 = TestDataFactory.createPG(false, supplier2.Id, section.Id);
            pg2.Brand__c = brand2.Id;
            insert new List<PG__c> {pg1, pg2};
    	  } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

	/*
     * Test validation on deletion of brand distribution from brand page   
     */
    @isTest static void test1_deleteBrandDistribution() {
    	init();
        BRADistributor__c selectBrandDistributor = [SELECT Id FROM BRADistributor__c WHERE Brand__c = :brand1.Id];
        Test.startTest();
        Database.DeleteResult result = Database.delete(selectBrandDistributor, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cant_Delete_Brand, result.getErrors()[0].getMessage());
    }
    
	/*
     * Test validation on deletion of multi brand distribution from brand page   
     */
    @isTest static void test2_deleteMultiBrandDistribution() {
    	init();
        List<BRADistributor__c> brandDistList = new List<BRADistributor__c>();
        BRADistributor__c selectDistributor = [SELECT Id FROM BRADistributor__c WHERE Brand__c = :brand1.Id];
        BRADistributor__c selectDistributor2 = [SELECT Id FROM BRADistributor__c WHERE Brand__c = :brand2.Id];
        brandDistList.add(selectDistributor);
        brandDistList.add(selectDistributor2);
        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(brandDistList, false);
        Test.stopTest();
        for (Database.DeleteResult result : deleteResults) {
            if(!result.isSuccess()){
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Cant_Delete_Brand, result.getErrors()[0].getMessage());
            }
        }
    }
    
    /*
     * Test Validate if a distributor supplier is already linked to a brand
     */
    @isTest static void test3_supplierAlreadyLinkedOnCreate() {
    	init();
        BRADistributor__c brandDist = new BRADistributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id, Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
        Test.startTest();
        Database.SaveResult result = Database.insert(brandDist, false);
        Test.stopTest();
        Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
        System.assertEquals(true,expectedError);
    }
    
 	/*
     * Test Validate if a distributor supplier is already linked to a brand on update
     */
    @isTest static void test4_supplierAlreadyLinkedOnUpdate() {
    	init();
        BRADistributor__c brandDist = new BRADistributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id, Supplier__c = supplier2.Id, StatusBDate__c = date.newInstance(year, 1, 1));
		insert brandDist;
        BRADistributor__c selectDistributor = [SELECT id FROM BRADistributor__c WHERE Brand__c = :brand1.Id AND Supplier__c = :supplier2.Id];
       	selectDistributor.Supplier__c = supplier1.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectDistributor, false);
        Test.stopTest();
        Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
        System.assertEquals(true,expectedError);
    }
  	
  	/*
     * Test Validate if a distributor supplier is already linked to a brand
     */
    @isTest static void test5_supplierAlreadyLinkedOnMultiCreate() {
    	init();
        List<BRADistributor__c> lstBrandDist = new List<BRADistributor__c>();
        BRADistributor__c brandDist = new BRADistributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id, Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
        BRADistributor__c brandDist2 = new BRADistributor__c(Name = supplier1.Name + 'New Brand dist 2', Brand__c = brand1.Id, Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
        BRADistributor__c brandDist3 = new BRADistributor__c(Name = supplier1.Name + 'New Brand dist 3', Brand__c = brand2.Id, Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
        lstBrandDist.add(brandDist);
        lstBrandDist.add(brandDist2);
        lstBrandDist.add(brandDist3);
        Test.startTest();
        List<Database.Saveresult>  insertResults = Database.insert(lstBrandDist, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
        	if(!result.isSuccess()){
           		 Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
           		 System.assertEquals(true,expectedError);
			}
		}
    }
}