/**
 * @author ULiT
 * @date 04-06-2024
 * @description Unit test class for APWToASDBatch
 **************************************************************/
@isTest
public class APWToASDBatchTest {

    private static Integer year;
    static List<Hierarchy__c> heList1;
	private static Assortment__c assortment;
	private static List <AssortmentDetail__c> assortmentDetailsList;
	private static Product2 product1;
	private static Product2 product2;
	private static PG__c pg1;
	private static PG__c pg2;
	private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c country;
    private static NegoScope__c NS;
    private static Contract__c contract;

    static void init() {
        year = System.Today().year();
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
		Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
		country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
		Supplier__c client = TestDataFactory.createSupplier(true, country, true);
		buSource = TestDataFactory.createBusinessUnitChannel(false, country);
		buSource.IsMasterBU__c = true;
        buSource.Supplier__c = client.Id;
		buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
		buTarget.Mission__c = 'Offer';
		buTarget.IsMasterBU__c = false;
		buTarget.Supplier__c = client.Id;
		insert new List<BusinessUnit__c> {buSource, buTarget};
		// Create Supplier
		BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(true, buTarget.Id, 'Strat0');
		//init Orga HEs
		heList1 = TestDataFactory.createElementHierarchy(4, 1);
        product1 = TestDataFactory.createProduct(false, heList1[4].Id, null);
        product1.Last_Unit_Cost__c = 2;
        product2 = TestDataFactory.createProduct(false, heList1[4].Id, null);
        product2.Last_Unit_Cost__c = 1.5;
        insert new List<Product2>{product1, product2};
        pg1 = TestDataFactory.createPG(false, client.Id, heList1[4].Id);
        pg1.Product__c = product1.Id;
        pg1.RetailPrice__c = 1.5;
        insert pg1;
        pg2 = TestDataFactory.createPG(false, client.Id, heList1[4].Id);
        pg2.Product__c = product2.Id;
        pg2.RetailPrice__c = 2.5;
        insert pg2;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(client.Id)[0];
        assortment = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        insert assortment;
        assortmentDetailsList = new List<AssortmentDetail__c>();
        assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment.Id, product1, cluster.Id));
        assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment.Id, product2, cluster.Id));
        insert assortmentDetailsList;
        contract = new Contract__c(Name = client.Name + ' - Contract ' + year, Supplier__c = client.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Number__c = 'C0A1',
                                             Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                             Contract_Commercial_BDate__c = date.newInstance(year, 1, 1), Contract_Commercial_EDate__c = date.newInstance(year, 12, 31),
                                             Duration__c = 12, BusinessUnitContract__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Signed');
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
        insert contract;
    }
    
    @isTest static void Case1_SynchroData() {
        init();
        Assortment_BU__c assortmentBU = TestDataFactory.createAssortmentBU(true, buSource, buTarget, heList1[1]);
        Assortment_PriceWaterFall__c assortmentPriceWaterFall1 = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU.Id, product1.Id, null, null);
        assortmentPriceWaterFall1.PG__c = pg1.Id;
        assortmentPriceWaterFall1.Product_UnitCharge1__c = 2;
        assortmentPriceWaterFall1.New_CostPrice__c = 2.5;
        Assortment_PriceWaterFall__c assortmentPriceWaterFall2 = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU.Id, product2.Id, null, null);
        assortmentPriceWaterFall2.PG__c = pg2.Id;
        assortmentPriceWaterFall2.Product_UnitCharge1__c = 1;
        assortmentPriceWaterFall2.New_CostPrice__c = 1.5;
        insert new List<Assortment_PriceWaterFall__c>{assortmentPriceWaterFall1, assortmentPriceWaterFall2};
        Test.startTest();
        assortment.Contract__c = contract.Id;
        assortment.PWF__c = assortmentBU.Id;
        update assortment;
        Database.executeBatch(new APWToASDBatch(APWToASDBatch.class.getName(), new Set<Id>{assortment.Id}));
        Test.stopTest();
        AssortmentDetail__c assortmentDetail1 = [SELECT Id, UnitCost__c, GrossPrice__c, NetPricewTax__c, NetPriceTradeBase__c,
                                                           NegoPrice__c, DeadProfitPrice__c, RetailPriceTarget__c 
                                                           FROM AssortmentDetail__c
                                                           WHERE Product__c = :product1.Id];
        AssortmentDetail__c assortmentDetail2 = [SELECT Id, UnitCost__c, GrossPrice__c, NetPricewTax__c, NetPriceTradeBase__c,
                                                           NegoPrice__c, DeadProfitPrice__c, RetailPriceTarget__c
                                                           FROM AssortmentDetail__c
                                                           WHERE Product__c = :product2.Id];
        assortmentPriceWaterFall1 = [SELEct Id, New_CostPrice__c, New_NetPrice_wTax__c, New_DeadPrice__c
                                     FROM Assortment_PriceWaterFall__c
                                     WHERE Id = :assortmentPriceWaterFall1.Id];
        assortmentPriceWaterFall2 = [SELEct Id, New_CostPrice__c, New_NetPrice_wTax__c, New_DeadPrice__c
                                     FROM Assortment_PriceWaterFall__c
                                     WHERE Id = :assortmentPriceWaterFall2.Id];
        pg1 = [SELECT Id, UnitCost__c, RetailPrice__c FROM PG__c WHERE Id = :pg1.Id];
        pg2 = [SELECT Id, UnitCost__c, RetailPrice__c FROM PG__c WHERE Id = :pg2.Id];
        //System.assertEquals(assortmentDetail1.UnitCost__c, pg1.UnitCost__c);
        System.assertEquals(assortmentDetail1.GrossPrice__c, assortmentPriceWaterFall1.New_CostPrice__c);
        System.assertEquals(assortmentDetail1.NetPricewTax__c, assortmentPriceWaterFall1.New_NetPrice_wTax__c);
        System.assertEquals(assortmentDetail1.NetPriceTradeBase__c, assortmentPriceWaterFall1.New_NetPrice_wTax__c);
        //System.assertEquals(assortmentDetail1.DeadProfitPrice__c, assortmentPriceWaterFall1.New_DeadPrice__c);
        //TO BE CALCULATED IN TRIGGER
        // System.assertEquals(assortmentDetail1.RetailPriceTarget__c, pg1.RetailPrice__c);
        
        //System.assertEquals(assortmentDetail2.UnitCost__c, pg2.UnitCost__c);
        //TO ADD LATER
        // System.assertEquals(assortmentDetail2.GrossPrice__c, assortmentPriceWaterFall2.New_CostPrice__c);
        System.assertEquals(assortmentDetail2.NetPricewTax__c, assortmentPriceWaterFall2.New_NetPrice_wTax__c);
        System.assertEquals(assortmentDetail2.NetPriceTradeBase__c, assortmentPriceWaterFall2.New_NetPrice_wTax__c);
        //System.assertEquals(assortmentDetail2.DeadProfitPrice__c, assortmentPriceWaterFall2.New_DeadPrice__c);
        // System.assertEquals(assortmentDetail2.RetailPriceTarget__c, pg2.RetailPrice__c);
    }
}