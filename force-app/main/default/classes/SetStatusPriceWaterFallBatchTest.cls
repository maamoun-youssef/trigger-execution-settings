@isTest
public class SetStatusPriceWaterFallBatchTest {

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
    private static Hierarchy__c assortmentCategory;
    private static Assortment_BU__c assortment;
    private static CommercialPlan__c comPlan;
    private static List<CommercialPlanDetail__c> commPlandetailToInsert;
    
    static void init() {
        try {
            Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
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
            buTarget.Supplier__c = client.Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                products.add(TestDataFactory.createProduct(false, orgaHEList[4].Id, null));
            }
            insert products;
            comPlan = TestDataFactory.createCommercialPlan(false, System.today(), System.today());
            comPlan.Supplier__c = client.Id;
            comPlan.Hierarchy__c = orgaHEList[1].Id;
            comPlan.BusinessUnitTarget__c = buTarget.Id;
            insert comPlan;
            commPlandetailToInsert = new List<CommercialPlanDetail__c>();
            for (Integer i = 0; i < 26; i++) {
                CommercialPlanDetail__c detail = TestDataFactory.createCommercialPlanDetail(false, comPlan.Id);
                detail.Product__c = products.get(i).Id;
                commPlandetailToInsert.add(detail);
            }
            insert commPlandetailToInsert;
            assortment = TestDataFactory.createAssortmentBU(true, buSource, buTarget, orgaHEList[1]);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description the single record case to test if NetPrice_Statement__c, Sup_NS_Taxes_Statement__c, Sup_NS_PriceDiscount_Statement__c, and NetPrice_Statement_Detail__c
     * the contract satus is Validated and is_NetPrice_Statement_Requested is True
    */
    static testmethod void case1_Set_Status_To_Validated() {
        init();
        List<Assortment_PriceWaterFall__c> PWFToInsert = new List<Assortment_PriceWaterFall__c>();
        for (Integer i = 0; i < 26; i++) {
            Assortment_PriceWaterFall__c priceWaterfall = TestDataFactory.createAssortmentPriceWaterFall(false, assortment.Id, products.get(i).Id, comPlan.Id, commPlandetailToInsert.get(i).Id);
            priceWaterfall.Status__c = 'In Preparation';
            PWFToInsert.add(priceWaterfall);
        }
        insert PWFToInsert;
        Test.startTest();
        Database.executeBatch(new SetStatusPriceWaterFallBatch('SetStatusPriceWaterFallBatchTest', new Set<Id> {PWFToInsert.get(3).Id, PWFToInsert.get(8).Id, PWFToInsert.get(15).Id, PWFToInsert.get(20).Id}, new Set<Id>{assortment.Id}));
        Test.stopTest();
        PWFToInsert = [SELECT Id, Status__c FROM Assortment_PriceWaterFall__c WHERE Id IN :PWFToInsert];
        System.assertEquals('Validated', PWFToInsert.get(3).Status__c);
        System.assertEquals('Validated', PWFToInsert.get(8).Status__c);
        System.assertEquals('Validated', PWFToInsert.get(15).Status__c);
        System.assertEquals('Validated', PWFToInsert.get(20).Status__c);
        System.assertNotEquals('Validated', PWFToInsert.get(1).Status__c);
    }
}