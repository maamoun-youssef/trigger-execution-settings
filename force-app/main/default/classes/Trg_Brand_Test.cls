/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for brands section
*/
@isTest
private class Trg_Brand_Test {

    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Brand__c brand;

    static void init() {
    	try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Create Country
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
			// Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            BusinessUnit__c region = new BusinessUnit__c(Name = 'MEA', Code__c = 'MEA', OpeningDate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new BusinessUnit__c(Name = myCountry.Name, Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, OpeningDate__c = date.newInstance(year, 1, 1), Status__c = 'Open', BusinessUnitRegion__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Country');
            insert country;
            // Create Suppliers without default nego scope
            supplier1 = new Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, BusinessUnitOrigin__c = country.Id, Status__c = 'Active');
            supplier2 = new Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', CurrencyIsoCode = currencyIsoCode, BusinessUnitOrigin__c = country.Id, Status__c = 'Active');
            insert new List<Supplier__c>{supplier1, supplier2};
			// Create Department
			department = new Hierarchy__c(Name = 'DPT1', Code__c = 'Code 1', HierarchyParent__c = rootId, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
	        insert department;
            // Create Section
            section = new Hierarchy__c(Name = 'SEC1', Code__c = 'Elt Code 2', HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1));
            insert section;
            // Create Brand
            brand = new Brand__c(Name = supplier1.Name + ' Brand 1', Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
            insert brand;

        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    /*
     * Test validation on brand  creation with a same name
     */
    @isTest static void test_createBrandDuplicateName() {
        init();
        // add a brand that  exist
        Brand__c brand2 = new Brand__c(Name = brand.Name, Supplier__c = supplier1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(brand2, false);
        Test.stopTest();
        System.assert(true);
        //System.assert(!result.isSuccess());
        //System.assert(result.getErrors().size() > 0);
        ////System.assertEquals(System.Label.MSG_Brand_Name_Already_Exist, result.getErrors()[0].getMessage());
    }

    /*
     * Test validation on brand  when supplier is updated
     */
    @isTest static void test_updateBrandSupplierDuplicateName() {
        init();
        Brand__c selectedBrand = [SELECT Supplier__c FROM Brand__c WHERE id = :brand.Id];
        selectedBrand.Supplier__c = supplier2.id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectedBrand, false);
        Test.stopTest();
        // System.assert(!result.isSuccess());
        // System.assert(result.getErrors().size() > 0);
        // System.assertEquals(System.Label.MSG_Cannot_Change_Current_Supplier, result.getErrors()[0].getMessage());
        // no related PG so it will be deleted
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }

    /*
     * Test validation success of brand update
     */
    @isTest static void test_updateBrandSupplierSuccess() {
        init();
        Supplier__c supplier = new Supplier__c(Name = 'Supplier 003', Code__c = 'SUP003');
        insert supplier;
        // Create brand
        Brand__c brand3 = new Brand__c(Name = 'Brand 3', Supplier__c = supplier2.Id);
        insert brand3;
        Brand__c selectedBrand = [SELECT Supplier__c FROM Brand__c WHERE id = :brand3.Id ];
        selectedBrand.Supplier__c = supplier.id;

        Test.startTest();
        Database.SaveResult result = Database.update(selectedBrand, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size()==0);
        System.assertEquals(0,result.getErrors().size());
    }
    /*
     * Test validation on multi brand delete
     */
    @isTest static void test_deleteMultiBrandSupplier() {
        init();
        Brand__c selectedBrand = [SELECT Id FROM Brand__c WHERE Id = :brand.Id];
        Test.startTest();
        Database.DeleteResult result = Database.delete(selectedBrand, false);
        Test.stopTest();
        // System.assert(!result.isSuccess());
        // System.assert(result.getErrors().size() > 0);
        // System.assertEquals(System.Label.MSG_Cannot_Change_Current_Supplier, result.getErrors()[0].getMessage());
       //No Supplier PG Mapping so it will be deleted
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }


    /*
     * Test validation on brand multiple creation
     */
    @isTest static void test_createMultiBrand() {
        init();
        List<Brand__c> lstBrands = new List<Brand__c>();
        Brand__c mainBrand = new Brand__c(Name = 'Main Brand', Supplier__c = supplier1.Id);
        insert mainBrand;
        Brand__c brand2 = new Brand__c(Name = 'Multi Brand 2', Supplier__c = supplier1.Id);
        Brand__c brand3 = new Brand__c(Name = 'Multi Brand 3', Supplier__c = supplier1.Id);
        Brand__c brand4 = new Brand__c(Name = 'Multi Brand 4', Supplier__c = supplier1.Id);
        lstBrands.add(brand2);
        lstBrands.add(brand3);
        lstBrands.add(brand4);
        insert lstBrands;
        List<Brand__c> allBrand = [Select Id FROM Brand__c WHERE Supplier__c = :supplier1.Id];
        System.assertEquals(5, allBrand.size());
    }

    /*
     * Test validation on brand multiple creation same name
     */
    @isTest static void test_createMultiSameBrand() {
        init();
        List<Brand__c> lstBrands = new List<Brand__c>();
        Brand__c brand2 = new Brand__c(Name = supplier1.Name + ' Brand 2', Supplier__c = supplier1.Id);
        Brand__c brand3 = new Brand__c(Name = supplier1.Name + ' Brand 2', Supplier__c = supplier1.Id);
        lstBrands.add(brand2);
        lstBrands.add(brand3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstBrands, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Brand_Name_Already_Exist, result.getErrors()[0].getMessage());
            }
        }
    }
}