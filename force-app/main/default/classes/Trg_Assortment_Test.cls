/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for Trg_Assortment_HandlerExt
 **************************************************************/
@isTest
private class Trg_Assortment_Test {
	static List<Hierarchy__c> heList1;
	static List<Hierarchy__c> heList2;
	private static Assortment__c assortment1;
	private static Assortment__c assortment2;
	private static List <AssortmentDetail__c> assortmentDetailsList;
	private static Product2 product1;
	private static Product2 product2;
	private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c country;

	static void init() {
        try {
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
            //init Orga HEs
            heList1 = TestDataFactory.createElementHierarchy(4, 1);
            heList2 = TestDataFactory.createElementHierarchy(4, 1);
            product1 = TestDataFactory.createProduct(false, heList1[4].Id, null);
            product2 = TestDataFactory.createProduct(false, heList2[4].Id, null);
            insert new List<Product2>{product1, product2};
            assortment1 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
            assortment1.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
            assortment2 = TestDataFactory.createAssortment(false, buSource, buTarget, heList2[1]);
            assortment2.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
            insert new List<Assortment__c> {assortment1, assortment2};
            assortmentDetailsList = new List<AssortmentDetail__c>();
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment1.Id, product1, cluster.Id));
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment2.Id, product2, cluster.Id));
            insert assortmentDetailsList;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

	@isTest
	static void case1_before_Update() {
		init();
		assortment1.Hierarchy__c = heList2[1].Id;
		Boolean expectedExceptionThrown;
		Test.startTest();
		try {
			update assortment1;
		} catch (Exception ex) {
			expectedExceptionThrown = ex.getMessage().contains(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch);
		}
		test.stopTest();
		System.assert (expectedExceptionThrown);
	}

	@isTest
	static void case2_before_Update_Mass() {
		init();
		assortment1.Hierarchy__c = heList2[1].Id;
		assortment2.Hierarchy__c = heList1[1].Id;
		Test.startTest();
		List<Database.SaveResult> results = Database.update(new List<Assortment__c> {assortment1, assortment2}, false);
		test.stopTest();
		for (Database.SaveResult result : results) {
			System.assert (result.getErrors().get(0).getMessage().contains(Label.Cannot_Change_Assortment_Category_To_Another_Details_Branch));
		}
	}

	@isTest
	static void case3_UpdateAssortmentDetailsStatuSingle_Success() {
		init();
		Test.startTest();
        assortment1 = [SELECT Id FROM Assortment__c WHERE Id = :assortment1.Id];
		assortment1.Status__c = 'Validate';
		update assortment1;
		Test.stopTest();
		System.assertEquals(assortmentDetailsList.size()/2, [SELECT COUNT() FROM AssortmentDetail__c WHERE Status__c = 'Validate' AND Assortment__c = : assortment1.Id]);
	}

	@isTest
	static void case4_GenerateName_Success() {
		init();
		Test.startTest();
		Assortment__c clone = assortment1.clone(false,false,false,false);
		insert clone;
		clone = [SELECT Version__c, Name, NamePrefix__c FROM Assortment__c WHERE Id = :clone.Id];
		Test.stopTest();
		System.assertEquals(2, clone.Version__c);
		System.assertEquals(clone.NamePrefix__c + '-V' + clone.Version__c, clone.Name);
	}
    
    @isTest
	static void case5_GenerateName_Mass_Success() {
		init();
		Test.startTest();
		Integer numberOfRecords = 50;
		List<Assortment__c> clones = new List<Assortment__c>();
		for (Integer i = 0; i < numberOfRecords; i++) {
			clones.add(assortment1.clone(false, false, false, false));
		}
		insert clones;
		Set<Id> assortmentBUsIdSet = new Set<Id>();
		for (Assortment__c item : clones) {
			assortmentBUsIdSet.add(item.Id);
		}
		clones = [SELECT Version__c, Name, NamePrefix__c FROM Assortment__c WHERE Id = :assortmentBUsIdSet];
		Test.stopTest();
		System.assertEquals(numberOfRecords, clones.size());
		for (Integer i = 0; i < numberOfRecords; i++) {
			System.assertEquals(i + 2, clones.get(i).Version__c);
			System.assertEquals(clones.get(i).NamePrefix__c + '-V' + clones.get(i).Version__c, clones.get(i).Name);
		}
	}
    
    @isTest
    static void case6_Add_Inno_Products_To_Cloned_Nego_Mass_Success() {
        init();
        Test.startTest();
        Integer numberOfRecords = 1;

        Assortment__c assortmentRef = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        assortmentRef.Status__c = 'Validate';
        assortmentRef.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        insert assortmentRef;

        List<Product2> products = new List<Product2>();
        for (Integer index = 0; index < numberOfRecords; index++) {
            Product2 product = TestDataFactory.createProduct(false, heList1[4].Id, null);
            product.Market_Introduction_Date__c = Date.newInstance(assortmentRef.Year__c.intValue(), 1, 1);
            products.add(product);
        }
        insert products;

        List<AssortmentDetail__c> assortmentDetailsList = new List<AssortmentDetail__c>();
        for (Product2 item : products) {
            AssortmentDetail__c assortmentDetail = TestDataFactory.createAssortmentDetail2(false, assortmentRef.Id, item, null);
            assortmentDetail.Status__c = 'Validate';
            assortmentDetailsList.add(assortmentDetail);
        }
        insert assortmentDetailsList;

        List<Product2> innoProductList = new List<Product2>();
        for (Integer index = 0; index < numberOfRecords; index++) {
            Product2 product = TestDataFactory.createProduct(false, heList1[4].Id, null);
            product.Market_Introduction_Date__c = Date.newInstance(assortmentRef.Year__c.intValue() + 1, 1, 1);
            innoProductList.add(product);
        }
        insert innoProductList;

        Assortment__c assortment = assortmentRef.clone(false);
        assortment.Year__c = assortmentRef.Year__c + 1;
        assortment.BDate__c = Date.newInstance(assortmentRef.Year__c.intValue() + 1, 1, 1);
        assortment.EDate__c = Date.newInstance(assortmentRef.Year__c.intValue() + 1, 12, 31);
        assortment.AssortmentNegotiationRef__c = assortmentRef.Id;
        insert assortment;

        Test.stopTest();
        Integer sumOfClonedNegoAssortmentDetails = [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c = :assortment.Id];
        System.assertEquals(innoProductList.size(), sumOfClonedNegoAssortmentDetails);
    }
    
	@isTest
	static void case7_ValidateTarget_Mass_Success() {
		init();
        Test.startTest();
        country.IsMasterBU__c = true;
        update country;
        List<BusinessUnit__c> clusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 1; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.WeightedDistributionManualN1__c = 3 * (i + 2) + 1; // 22, 19, 16, 13, 10, 7
            clusters.add(cluster);
        }
        insert clusters;
        Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
        Assortment__c nego1 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        nego1.Status__c = 'Validate';
        Assortment__c nego2 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        nego2.Status__c = 'Validate';
        Assortment__c budget1 = TestDataFactory.createAssortment(false, country, buSource, heList1[1]);
        budget1.RecordTypeId = assortmentRTIds.get('ChannelBudget');
        Assortment__c budget2 = TestDataFactory.createAssortment(false, country, buSource, heList1[1]);
        budget2.RecordTypeId = assortmentRTIds.get('ChannelBudget');
        insert new List<Assortment__c>{nego1, nego2, budget1, budget2};
        List<Product2> productList = new List<Product2>();
        List<AssortmentDetail__c> asdList = new List<AssortmentDetail__c>();
        Integer numberOfRecords = 2;
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, heList1[4].Id, null);
            productList.add(p);
        }
        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            AssortmentDetail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail2(false, nego1.Id, productList.get(i), clusters.get(1).Id);
            assortmentDetail1.Hierarchy__c = productList.get(i).Category__c;
            assortmentDetail1.ProductLifeStatusAss__c = 'New';
            assortmentDetail1.Status__c = 'Validate';
            assortmentDetail1.Version__c = null;
            asdList.add(assortmentDetail1);
            AssortmentDetail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail2(false, budget1.Id, productList.get(i), clusters.get(1).Id);
            assortmentDetail2.Hierarchy__c = productList.get(i).Category__c;
            assortmentDetail2.ProductLifeStatusAss__c = 'New';
            assortmentDetail2.Status__c = 'Validate';
            assortmentDetail2.Version__c = null;
            asdList.add(assortmentDetail2);
        }
        insert asdList;
        List<Assortment__c> listTargets = new List<Assortment__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Assortment__c target1 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
            target1.Status__c = 'Open';
            target1.RecordTypeId = assortmentRTIds.get('Target');
            target1.AssortmentNegotiationRef__c = nego1.Id;
            target1.AssortmentChannelBudgetRef__c = budget1.Id;
            listTargets.add(target1);
            Assortment__c target2 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
            target2.Status__c = 'Open';
            target2.RecordTypeId = assortmentRTIds.get('Target');
            target2.AssortmentNegotiationRef__c = nego2.Id;
            target2.AssortmentChannelBudgetRef__c = budget2.Id;
            listTargets.add(target2);
        }
        insert listTargets;
        for (Assortment__c target : listTargets) {
            target.Status__c = 'Validate';
        }
        update listTargets;
        Test.stopTest();
        budget1 = [SELECT Id, IsAllrelatedTargetValidated__c FROM Assortment__c WHERE Id = :budget1.Id];
        budget2 = [SELECT Id, IsAllrelatedTargetValidated__c FROM Assortment__c WHERE Id = :budget2.Id];
        System.assertEquals(true, budget1.IsAllrelatedTargetValidated__c);
        System.assertEquals(true, budget2.IsAllrelatedTargetValidated__c);
	}

    @isTest
    static void case8_updateParentAssortment_Success() {
        init();
        Integer year = System.Today().year();
        Integer month = System.Today().month();
        Integer day = System.Today().day();
        Test.startTest();
        // insert parent assortment nego for previous year
        Assortment__c parentAssortmentNego = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        parentAssortmentNego.RecordTypeId =  TestDataFactory.assortmentRTIds.get('Negotiation');
        parentAssortmentNego.Year__c = year - 1;
        parentAssortmentNego.BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentNego.EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentNego.Status__c = 'Validate';
        insert parentAssortmentNego;
        AssortmentDetail__c parentAssortmentDetailNego = TestDataFactory.createAssortmentDetail2(false, parentAssortmentNego.Id, product1, null);
        parentAssortmentDetailNego.Status__c = 'Validate';
        parentAssortmentDetailNego.ProductLifeStatusAss__c = 'New';
        parentAssortmentDetailNego.StartDate__c = Date.newInstance(year - 1, month, day);
        parentAssortmentDetailNego.RecordDate__c = Date.newInstance(year - 1, month, day);
        insert parentAssortmentDetailNego;
        assortment1.AssortmentNegotiationRef__c = parentAssortmentNego.Id;
        update assortment1;
        Test.stopTest();
        AssortmentDetail__c assortmentDetail = [SELECT Id, AssortmentDetailNegotiationRef__c FROM AssortmentDetail__c
                                                          WHERE Assortment__c = :assortment1.Id
                                                          AND Product__c = :product1.Id];
        System.assertEquals(parentAssortmentDetailNego.Id, assortmentDetail.AssortmentDetailNegotiationRef__c);
    }
    
    @isTest
    static void case9_CheckOnTopUnicity() {
        init();
        assortment1.OnTop__c = true;
        update assortment1;
        Test.startTest();
        Assortment__c assortment = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        assortment.OnTop__c = true;
        insert assortment;
        Test.stopTest();
        Map<Id, Assortment__c> assortmentMap = new Map<Id, Assortment__c>([SELECT Id, OnTop__c FROM Assortment__c WHERE Id = :assortment1.Id OR Id = :assortment.Id]);
        System.assertEquals(false, assortmentMap.get(assortment1.Id).OnTop__c);
        System.assertEquals(true, assortmentMap.get(assortment.Id).OnTop__c);
    }
    
    @isTest
    static void case10_GenerateTargetAssortment() {
        init();
        Assortment__c nego1 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        nego1.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        nego1.Status__c = 'Validate';
        Assortment__c nego2 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        nego2.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        nego2.Status__c = 'Validate';
        Assortment__c budget1 = TestDataFactory.createAssortment(false, country, buSource, heList1[1]);
        budget1.RecordTypeId = TestDataFactory.assortmentRTIds.get('ChannelBudget');
        budget1.Year__c = nego2.Year__c + 1;
        budget1.BDate__c = Date.newInstance(nego2.Year__c.intValue() + 1, 1, 1);
        budget1.EDate__c = Date.newInstance(nego2.Year__c.intValue() + 1, 12, 31);
        insert new List<Assortment__c>{nego1, nego2, budget1};
        Test.startTest();
        budget1.Status__c = 'PreValidate';
        update budget1;
        Test.stopTest();
        Map<Id, Assortment__c> assortmentMap = new Map<Id, Assortment__c>([SELECT Id, OnTop__c FROM Assortment__c WHERE RecordType.DeveloperName = 'Target']);
        System.assertEquals(2, assortmentMap.keySet().size());
    }
    
	@isTest
	static void case11_deleteASD_Success() {
		init();
        Test.startTest();
        country.IsMasterBU__c = true;
        update country;
        Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
        Assortment__c nego1 = TestDataFactory.createAssortment(false, buSource, buTarget, heList1[1]);
        nego1.Status__c = 'Validate';
        insert nego1;
        Product2 product = TestDataFactory.createProduct(false, heList1[4].Id, null);
        insert product;
        AssortmentDetail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail2(false, nego1.Id, product, null);
        assortmentDetail1.Hierarchy__c = product.Category__c;
        assortmentDetail1.ProductLifeStatusAss__c = 'New';
        assortmentDetail1.Status__c = 'Validate';
        assortmentDetail1.Version__c = null;
        insert assortmentDetail1;
        delete nego1;
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM AssortmentDetail__c WHERE Id = :assortmentDetail1.Id]);
	}
    
    @isTest
    static void case12_bottomUpValues() {
        init();
        Test.startTest();
        country.IsMasterBU__c = true;
        update country;
        List<BusinessUnit__c> clusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 1; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.WeightedDistributionManualN1__c = 3 * (i + 2) + 1; // 22, 19, 16, 13, 10, 7
            clusters.add(cluster);
        }
        insert clusters;
        Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
        Assortment__c budget1 = TestDataFactory.createAssortment(false, country, buSource, heList1[1]);
        budget1.RecordTypeId = assortmentRTIds.get('ChannelBudget');
        insert budget1;
        AssortmentDetail__c assortmentDetailBudget = TestDataFactory.createAssortmentDetail2(false, budget1.Id, product1, clusters.get(1).Id);
        assortmentDetailBudget.Hierarchy__c = product1.Category__c;
        assortmentDetailBudget.ProductLifeStatusAss__c = 'New';
        assortmentDetailBudget.Status__c = 'Validate';
        assortmentDetailBudget.Version__c = null;
        insert assortmentDetailBudget;
        assortment1.AssortmentChannelBudgetRef__c = budget1.Id;
        assortment1.OnTop__c = true;
        update assortment1;
        Test.stopTest();
        AssortmentDetail__c assortmentDetailNego = [SELECT WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Product__c = :product1.Id AND Assortment__c = :assortment1.Id LIMIT 1];
        assortmentDetailBudget = [SELECT WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetailBudget.Id];
        System.assertEquals(assortmentDetailBudget.WDChannelBaseNego__c, assortmentDetailNego.WDChannelBaseNego__c);
    }
}