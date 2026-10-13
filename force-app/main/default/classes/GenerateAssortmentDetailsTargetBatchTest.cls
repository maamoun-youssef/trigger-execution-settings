/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for GenerateAssortmentTargetDetailsBatch
 **************************************************************/
@isTest
private class GenerateAssortmentDetailsTargetBatchTest {

    static Integer year;
    static BusinessUnit__c buCountry;
    static List <Supplier__c> clientList;
    static BusinessUnit__c mainBU;
    static BusinessUnit__c channel;
    static List <BusinessUnit__c> banners;
    static List <Hierarchy__c> heList;
    static List <Product2> productList;
    static List <Assortment__c> histoAssortmentList;
    static List <AssortmentDetail__c> histoDetailList;
    static Assortment__c assortmentBudget;
    static Map <String, Id> Product2recordTypes;

    static void init() {
        try {
            Product2recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Product2.sObjectType);
            year = Date.today().year();
            Country_List__c country = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            buCountry = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // create 4 clients
            clientList = new List <Supplier__c> ();
            for (Integer i = 0; i < 2; i++) {
                clientList.add(TestDataFactory.createSupplier(false, buCountry, false));
            }
            insert clientList;
            List <BusinessUnit__c> buList = new List <BusinessUnit__c> ();
            // create mainBU
            mainBU = TestDataFactory.createBusinessUnitCountry(false, region.Id);
            mainBU.Code__c = 'MAIN';
            mainBU.IsMasterBU__c = true;
            buList.add(mainBU);
            // create channel BU
            channel = TestDataFactory.createBusinessUnitChannel(false, mainBU);
            channel.IsMasterBU__c = true;
            buList.add(channel);
            // create clients banners
            banners = new List <BusinessUnit__c> ();
            for (Supplier__c supplier: clientList) {
                BusinessUnit__c banner = TestDataFactory.createBusinessUnitBanner(false, buCountry);
                banner.Name += supplier.Name;
                banner.Supplier__c = supplier.Id;
                banner.Mission__c = 'Offer';
                banner.LayerBudgetDisplay__c = true;
                banner.ExtId__c = banner.Name;
                banners.add(banner);
            }
            buList.addAll(banners);
            insert buList;
            heList = TestDataFactory.createElementHierarchy(4, 1);
            // create 26 products on level 4 he
            productList = new List <Product2>();
            for (Hierarchy__c he: heList) {
                if (he.Level__c == 4) {
                    for (Integer i = 0; i < 4; i++) {
                        Product2 product = TestDataFactory.createProduct(false, he.Id, null);
                        product.RecordTypeId = Product2recordTypes.get('Product');
                        product.IsActive = true;
                        productList.add(product);
                    }
                }
            }
            insert productList;
            // histo assortments
            Integer i = 1;
            histoAssortmentList = new List <Assortment__c>();
            for (BusinessUnit__c banner: banners) {
                Assortment__c assortmentNego = TestDataFactory.createAssortment(false, channel, banner, heList[1]);
                assortmentNego.Name = banner.Name + i;
                assortmentNego.ExtId__c = 'HISTO-NEGO-' + i;
                assortmentNego.Status__c = 'Validate';
                assortmentNego.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
                histoAssortmentList.add(assortmentNego);
                i++;
            }
            insert histoAssortmentList;
            // create histoAssortmentDetails
            histoDetailList = new List <AssortmentDetail__c> ();
            for (Assortment__c assortment: histoAssortmentList) {
                for (Product2 product: productList) {
                    AssortmentDetail__c ad = TestDataFactory.createAssortmentDetail2(false, assortment.Id, product, null);
                    ad.Status__c = 'Validate';
                    histoDetailList.add(ad);
                }
            }
            insert histoDetailList;
            // create budget Assortment
            assortmentBudget = TestDataFactory.createAssortment(false, mainBU, channel, heList[1]);
            assortmentBudget.Name = 'BUDGET-' + (year + 1);
            assortmentBudget.BDate__c = Date.newInstance(year + 1, 1, 1);
            assortmentBudget.EDate__C = Date.newInstance(year + 1, 12, 31);
            assortmentBudget.Year__c = year + 1;
            assortmentBudget.RecordTypeId = TestDataFactory.assortmentRTIds.get('ChannelBudget');
            insert assortmentBudget;
            // fetch fields for assortmentBudget
            assortmentBudget = [SELECT AssortmentNegotiationRef__c, BusinessUnitSource__c, BusinessUnitSource__r.Code__c, BusinessUnitTarget__c, Hierarchy__c, LongName__c,
                                BusinessUnitTarget__r.Format__c, Hierarchy__r.Path__c, Hierarchy__r.Name, Year__c, BDate__c, EDate__c, Status__c
                                FROM Assortment__c WHERE Id =: assortmentBudget.Id];
        } catch (Exception ex) {
            throw new TestSetupException('init() failed: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }

    /**
     * Builds and inserts Target assortments (linked to budget) and one Simulation per Target.
     * Returns a two-element list: [0] = targets, [1] = simulations.
     */
    private static List<List<Assortment__c>> createSyncAssortments(String extIdPrefix) {
        List<Assortment__c> targets = new List<Assortment__c>();
        Integer idx = 1;
        for (Assortment__c assortment : histoAssortmentList) {
            Assortment__c t = assortment.clone(false, true, false, false);
            t.ExtId__c = extIdPrefix + '-TARGET-' + idx++;
            t.Year__c = year + 1;
            t.BDate__c = Date.newInstance(year + 1, 1, 1);
            t.EDate__c = Date.newInstance(year + 1, 12, 31);
            t.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
            t.BusinessUnitSource__c = channel.Id;
            t.Status__c = 'Open';
            t.AssortmentChannelBudgetRef__c = assortmentBudget.Id;
            t.AssortmentNegotiationRef__c = assortment.Id;
            targets.add(t);
        }
        insert targets;
        List<Assortment__c> sims = new List<Assortment__c>();
        idx = 1;
        for (Assortment__c t : targets) {
            Assortment__c s = t.clone(false, true, false, false);
            s.ExtId__c = extIdPrefix + '-SIM-' + idx++;
            s.RecordTypeId = TestDataFactory.assortmentRTIds.get('Simulation');
            s.Status__c = 'Open';
            s.AssortmentChannelBudgetRef__c = null;
            s.AssortmentNegotiationRef__c = null;
            s.AssortmentTargetRef__c = t.Id;
            sims.add(s);
        }
        insert sims;
        return new List<List<Assortment__c>>{ targets, sims };
    }

    class TestSetupException extends Exception {}

    static testmethod void case1_Coverage() {
        init();
        List<Assortment__c> targetAssortments = new List<Assortment__c>();
        Integer tIdx = 1;
        for (Assortment__c assortment: histoAssortmentList) {
            Assortment__c cloneAssortment = assortment.clone(false, true, false, false);
            cloneAssortment.ExtId__c = 'TARGET-' + tIdx++;
            cloneAssortment.Year__c = year + 1;
            cloneAssortment.BDate__c = Date.newInstance(year + 1, 1, 1);
            cloneAssortment.EDate__c = Date.newInstance(year + 1, 12, 31);
            cloneAssortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
            cloneAssortment.Hierarchy__c = heList[1].Id;
            cloneAssortment.BusinessUnitSource__c = channel.Id;
            cloneAssortment.AssortmentChannelBudgetRef__c = assortmentBudget.Id;
            cloneAssortment.AssortmentNegotiationRef__c = assortment.Id;
            targetAssortments.add(cloneAssortment);
        }
        insert targetAssortments;
        List<AssortmentDetail__c> budgetASdList = new List<AssortmentDetail__c>();
        for (Product2 product: productList) {
            budgetASdList.add(TestDataFactory.createAssortmentDetail2(false, assortmentBudget.Id, product, null));
        }
        insert budgetASdList;
        Test.startTest();
        Map<String, Object> targetParamsMap1 = new Map<String, Object>{
            'startedFrom' => GenerateAssortmentDetailsTargetBatchTest.class.getName(),
            'dVBudgetId' => assortmentBudget.Id
        };
        NegoptimBatch.executeBatch('GenerateAssortmentDetailsTargetBatch', targetParamsMap1, 20);
        Test.stopTest();
        System.assertEquals(productList.size() * targetAssortments.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c IN :targetAssortments]);
    }

    /**
     * isSync = true: verifies that the batch creates new ASD lines with WDChannelBaseTarget__c
     * on both Target and Simulation assortments when none exist yet.
     */
    static testmethod void case2_Sync_CreateNewASDs() {
        init();
        List<List<Assortment__c>> syncAssortments = createSyncAssortments('C2');
        List<Assortment__c> syncTargetAssortments = syncAssortments[0];
        List<Assortment__c> syncSimAssortments    = syncAssortments[1];
        List<AssortmentDetail__c> budgetASDList = new List<AssortmentDetail__c>();
        for (Product2 product : productList) {
            AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortmentBudget.Id, product, null);
            asd.WDChannelBaseBudget__c = 50.0;
            budgetASDList.add(asd);
        }
        insert budgetASDList;
        Test.startTest();
        Map<String, Object> targetParamsMap2 = new Map<String, Object>{
            'startedFrom' => GenerateAssortmentDetailsTargetBatchTest.class.getName(),
            'dVBudgetId' => assortmentBudget.Id,
            'isSync' => true
        };
        NegoptimBatch.executeBatch('GenerateAssortmentDetailsTargetBatch', targetParamsMap2, 20);
        Test.stopTest();
        System.assertEquals(productList.size() * syncTargetAssortments.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c IN :syncTargetAssortments], 'Expected ASD lines created for all products in Target assortments');
        System.assertEquals(productList.size() * syncSimAssortments.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c IN :syncSimAssortments], 'Expected ASD lines created for all products in Simulation assortments');
        for (AssortmentDetail__c asd : [SELECT WDChannelBaseTarget__c FROM AssortmentDetail__c WHERE Assortment__c IN :syncTargetAssortments]) {
            System.assertEquals(50.0, asd.WDChannelBaseTarget__c, 'WDChannelBaseTarget__c should equal budget WDChannelBaseBudget__c');
        }
    }

    /**
     * isSync = true: verifies that the batch updates WDChannelBaseTarget__c on existing ASDs
     * and creates new ASD lines for products newly added to the budget.
     */
    static testmethod void case3_Sync_UpdateExistingAndCreateNew() {
        init();
        List<List<Assortment__c>> syncAssortments = createSyncAssortments('C3');
        List<Assortment__c> syncTargetAssortments = syncAssortments[0];
        List<Assortment__c> syncSimAssortments    = syncAssortments[1];
        List<AssortmentDetail__c> budgetASDList = new List<AssortmentDetail__c>();
        for (Product2 product : productList) {
            AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortmentBudget.Id, product, null);
            asd.WDChannelBaseBudget__c = 75.0;
            budgetASDList.add(asd);
        }
        insert budgetASDList;
        // Pre-existing Target and Simulation ASDs for only the first two products (old value 10)
        List<AssortmentDetail__c> preExistingList = new List<AssortmentDetail__c>();
        List<Product2> existingProducts = new List<Product2>{ productList[0], productList[1] };
        for (Assortment__c targetAss : syncTargetAssortments) {
            for (Product2 product : existingProducts) {
                AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, targetAss.Id, product, null);
                asd.WDChannelBaseTarget__c = 10.0;
                preExistingList.add(asd);
            }
        }
        for (Assortment__c simAss : syncSimAssortments) {
            for (Product2 product : existingProducts) {
                AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, simAss.Id, product, null);
                asd.WDChannelBaseTarget__c = 10.0;
                preExistingList.add(asd);
            }
        }
        insert preExistingList;
        Test.startTest();
        Map<String, Object> targetParamsMap3 = new Map<String, Object>{
            'startedFrom' => GenerateAssortmentDetailsTargetBatchTest.class.getName(),
            'dVBudgetId' => assortmentBudget.Id,
            'isSync' => true
        };
        NegoptimBatch.executeBatch('GenerateAssortmentDetailsTargetBatch', targetParamsMap3, 20);
        Test.stopTest();
        System.assertEquals(productList.size() * syncTargetAssortments.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c IN :syncTargetAssortments], 'Expected all products covered in Target assortments after sync');
        System.assertEquals(productList.size() * syncSimAssortments.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c IN :syncSimAssortments], 'Expected all products covered in Simulation assortments after sync');
        for (AssortmentDetail__c asd : [SELECT WDChannelBaseTarget__c FROM AssortmentDetail__c WHERE Assortment__c IN :syncTargetAssortments]) {
            System.assertEquals(75.0, asd.WDChannelBaseTarget__c, 'WDChannelBaseTarget__c should be updated to 75.0');
        }
        for (AssortmentDetail__c asd : [SELECT WDChannelBaseTarget__c FROM AssortmentDetail__c WHERE Assortment__c IN :syncSimAssortments]) {
            System.assertEquals(75.0, asd.WDChannelBaseTarget__c, 'WDChannelBaseTarget__c should be updated to 75.0');
        }
    }
}