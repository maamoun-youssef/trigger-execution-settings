/*  Code fragment 1
 * Test code related to fragment 1 of the Trg_Org_OrgaBusinessUnitListDetail trigger, concerning:
 * 1) Contract__c (dependencies)
 * 2) Contract_Discount__c (dependencies)
 * 3) Invoice__c (dependencies)
 * 4) Inv_BUDispatch_Detail__c (dependencies)
 * Code fragment 2
 * Test code related to fragment 2 of the Trg_Org_OrgaBusinessUnitListDetail trigger, concerning:
 * 5) BULink__c (duplication)
 */
@isTest
private with sharing class Trg_BULink_Test {

	private static Integer year;
    private static Id rootId;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country1;
    private static BusinessUnit__c country2;
    private static BusinessUnit__c store;
    private static BusinessUnit__c store2;
    private static BusinessUnit__c store3;
    private static Supplier__c supplier;

    // Init (Code fragment 1)
    static void init() {
    	year = System.Today().year();
		// Root Element Id.
		rootId = NegoptimHelper.getHierarchyRootId('Product');
    	// Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Countries
        country1 = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country2 = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        insert new List<BusinessUnit__c>{country1, country2};
        // Create Store
        store = TestDataFactory.createBusinessUnitStores(false, country1, 1).get(0);
        store.BusinessUnitCountryOrigin__c = null;
        insert store;
        // Create Supplier
        //supplier = TestDataFactory.createSupplier(true, country1, true);
    }

    @isTest static void case1_entityList_delete_succeed() {
        init();
        // Create Orga BU List Detail
        BULink__c linkedEntity = new BULink__c(BusinessUnitMaster__c = country2.Id, BusinessUnitDetail__c = store.Id);
        insert linkedEntity;
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }

    @isTest static void case2_duplicateEntityList_insert_succeed() {
        init();
        Test.startTest();
        // Update store BU.
        store.BusinessUnitCountryOrigin__c = country1.Id;
        update store;
        // Create store BU.
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country1, 1).get(0);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM BULink__c]);
    }

    @isTest static void case3_duplicateEntityList_insert_failed() {
        init();
        // Update store BU.
        store.BusinessUnitCountryOrigin__c = country1.Id;
        update store;
        // Create Orga BU List Detail
        BULink__c lBUList2 = new BULink__c(BusinessUnitMaster__c = country1.Id, BusinessUnitDetail__c = store.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(lBUList2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_Code_LinkedEntity_Already_Exist);
    }

    @isTest static void case4_duplicateEntityList_update_failed() {
        init();
        // Update store BU.
        store.BusinessUnitCountryOrigin__c = country1.Id;
        update store;
        // Create store BU.
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(true, country1, 1).get(0);
        BULink__c lBUList1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country1.Id AND BusinessUnitDetail__c = :store.Id];
        BULink__c lBUList2 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country1.Id AND BusinessUnitDetail__c = :store1.Id];
        lBUList2.BusinessUnitDetail__c = store.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(lBUList2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_Code_LinkedEntity_Already_Exist);
    }

    @isTest static void case5_duplicateEntityList_update_succeed() {
        init();
        // Update store BU.
        store.BusinessUnitCountryOrigin__c = country1.Id;
        update store;
        BusinessUnit__c store1 = TestDataFactory.createBusinessUnitStores(false, country1, 1).get(0);
        BusinessUnit__c store2 = TestDataFactory.createBusinessUnitStores(false, country2, 1).get(0);
        insert new List<BusinessUnit__c>{store1, store2};
        BULink__c linkedEntity1 = [SELECT Id FROM BULink__c WHERE BusinessUnitMaster__c = :country1.Id AND BusinessUnitDetail__c = :store.Id];
        BULink__c linkedEntity2 = [SELECT Id, BusinessUnitDetail__c FROM BULink__c WHERE BusinessUnitMaster__c = :country1.Id AND BusinessUnitDetail__c = :store1.Id];
        linkedEntity2.BusinessUnitDetail__c = store2.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(linkedEntity2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
}