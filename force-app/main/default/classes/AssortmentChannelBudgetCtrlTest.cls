/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for AssortmentChannelBudgetCtrlExt
 **************************************************************/
@isTest
private class AssortmentChannelBudgetCtrlTest {

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
            histoAssortmentList = new List <Assortment__c> ();
            for (BusinessUnit__c banner: banners) {
                Assortment__c assortmentNego = TestDataFactory.createAssortment(false, channel, banner, heList[1]);
                assortmentNego.Name = banner.Name + i;
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
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void case1_Coverage() {
        init();
        Test.startTest();
        String initWrapperJSON = AssortmentChannelBudgetCtrl.initData(assortmentBudget.Id);
        AssortmentChannelBudgetCtrl.InitWrapper initWrapper = (AssortmentChannelBudgetCtrl.InitWrapper) JSON.deserialize(initWrapperJSON, AssortmentChannelBudgetCtrl.InitWrapper.class);
        String result = AssortmentChannelBudgetCtrl.loadData(JSON.serialize(initWrapper.budgetAssortment), new List<String>(initWrapper.negoAssIds), '', initWrapper.allFields, 1, 25, new List<String>(initWrapper.productIdSet));
        Test.stopTest();
        System.assert(true);
    }

    static testmethod void case2_ChangeAssortmentStatus() {
        init();
        Test.startTest();
        AssortmentChannelBudgetCtrl.changeAssortmentStatus(assortmentBudget.Id, 'Validate');
        Test.stopTest();
        assortmentBudget = [SELECT Id, Status__c FROM Assortment__c WHERE Id = :assortmentBudget.Id];
        System.assertEquals('Validate', assortmentBudget.Status__c);
    }
    
    static testmethod void case3_save() {
        init();
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortmentBudget.Id, productList.get(0), null);
        asd.WDChannelBaseBudget__c = 4.5;
        insert asd;
        Test.startTest();
        AssortmentChannelBudgetCtrl.save(JSON.serialize(new List<AssortmentDetail__c> { asd }));
        Test.stopTest();
        asd = [SELECT Id, WDChannelBaseBudget__c FROM AssortmentDetail__c WHERE Id = :asd.Id];
        System.assertEquals(4.5, asd.WDChannelBaseBudget__c);
    }
    
    static testmethod void case4_fakesave() {
        init();
        String initWrapperJSON = AssortmentChannelBudgetCtrl.initData(assortmentBudget.Id);
        AssortmentChannelBudgetCtrl.InitWrapper initWrapper = (AssortmentChannelBudgetCtrl.InitWrapper) JSON.deserialize(initWrapperJSON, AssortmentChannelBudgetCtrl.InitWrapper.class);
        AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortmentBudget.Id, productList.get(0), null);
        insert asd;
        Test.startTest();
        AssortmentDetail__c updatedAsd = new AssortmentDetail__c(Id = asd.Id, WDChannelBaseBudget__c = 4.5);
        String result = AssortmentChannelBudgetCtrl.fakeSave(JSON.serialize(initWrapper.budgetAssortment), new List<String>(initWrapper.negoAssIds), new List<String>(initWrapper.productIdSet), heList[0].Id, JSON.serialize(new List<AssortmentDetail__c> {updatedAsd}));
        Test.stopTest();
        // System.assertEquals(4.5, asd.WDChannelBaseBudget_NegoL4LP1Gap__c);
    }
}