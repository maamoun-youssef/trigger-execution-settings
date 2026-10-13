@isTest
private class Trg_Assortment_BU_Test {
	static List<Hierarchy__c> heList1;
	static List<Hierarchy__c> heList2;
	private static Assortment_BU__c assortment1;
	private static Assortment_BU__c assortment2;
	private static List <Assortment_Detail__c> assortmentDetailsList;
	private static List<Product2> products;
	private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c country;

	static void init() {
		BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
		Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
		country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
		Supplier__c client = TestDataFactory.createSupplier(true, country, false);
		buSource = TestDataFactory.createBusinessUnitChannel(false, country);
		buSource.IsMasterBU__c = true;
        buSource.Supplier__c = client.Id;
		buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
		buTarget.Mission__c = 'Offer';
		buTarget.IsMasterBU__c = false;
		buTarget.Supplier__c = client.Id;
		insert new List<BusinessUnit__c> {buSource, buTarget};
		BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(true, buTarget.Id, 'Strat0');
		List<Hierarchy__c> categoriesList = new List<Hierarchy__c>();
		Map<String, Product2> productsMap = new Map <String, Product2>();
		//init Orga HEs
		heList1 = TestDataFactory.createElementHierarchy(4, 1);
		heList2 = TestDataFactory.createElementHierarchy(4, 1);
		products = new List<Product2>();
		for (Integer i = 0; i < 1; i++) {
			products.add(TestDataFactory.createProduct(false, heList1[4].Id, null));
			products.add(TestDataFactory.createProduct(false, heList2[4].Id, null));
		}
		insert products;
		assortment1 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, heList1[1]);
		assortment2 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, heList2[1]);
		insert new List<Assortment_BU__c> {assortment1, assortment2};
		assortmentDetailsList = new List<Assortment_Detail__c>();
		for (Product2 product : products) {
			assortmentDetailsList.add(TestDataFactory.createAssortment_Detail(false, assortment1.Id, product, cluster.Id));
			assortmentDetailsList.add(TestDataFactory.createAssortment_Detail(false, assortment2.Id, product, cluster.Id));
		}
		insert assortmentDetailsList;
	}

	@isTest
	static void case5_GenerateName_Success() {
		init();
		Test.startTest();
		Assortment_BU__c clone = assortment1.clone(false,false,false,false);
		insert clone;
		clone = [SELECT Simulation_version__c, Name, Name_Prefix__c FROM Assortment_BU__c WHERE Id = :clone.Id];
		Test.stopTest();
		System.assertEquals(2, clone.Simulation_version__c);
		System.assertEquals(clone.Name_Prefix__c + '-V' + clone.Simulation_version__c, clone.Name);
	}

	@isTest
	static void case6_GenerateName_Mass_Success() {
		init();
		Test.startTest();
		Integer numberOfRecords = 50;
		List<Assortment_BU__c> clones = new List<Assortment_BU__c>();
		for (Integer i = 0; i < numberOfRecords; i++) {
			clones.add(assortment1.clone(false,false,false,false));
		}
		insert clones;
		Set<Id> assortmentBUsIdSet = new Set<Id>();
		for (Assortment_BU__c item : clones) {
			assortmentBUsIdSet.add(item.Id);
		}
		clones = [SELECT Simulation_version__c, Name, Name_Prefix__c FROM Assortment_BU__c WHERE Id = :assortmentBUsIdSet];
		Test.stopTest();
		System.assertEquals(numberOfRecords, clones.size());
		for (Integer i = 0; i < numberOfRecords; i++) {
			System.assertEquals(i + 2, clones.get(i).Simulation_version__c);
			System.assertEquals(clones.get(i).Name_Prefix__c + '-V' + clones.get(i).Simulation_version__c, clones.get(i).Name);
		}
	}
}