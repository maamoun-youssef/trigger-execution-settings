/**
* @author ULiT
* @date 08-07-2024
* @description AssortmentMatrixCtrlTest
*******************************************************************************************************************************************
*/
@isTest
public with sharing class AssortmentMatrixCtrlTest {

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
    private static Assortment__c assortment;
    private static List<AssortmentDetail__c> details;
    private static AssortmentSettings assortSettings;

    /**
     * @description generates and initializes commun data for tests
     * calculates the current year
     * creates a country [Country_List__c]
     * Creates a region [BusinessUnit__c]
     * creates a bu [BusinessUnit__c] of type record type country
     * creates a supplier [Supplier__c] related to the bu country
     * creates clientBranch bu [BusinessUnit__c] of type record type country to represent one of the client's store groupes and assigns the related client field [BusinessUnit__c.Related_Client__c]
     * creates a tree of hierarchy elements [Hierarchy__c] of depth 4 and with 3 elements on each level
     * creates 5 starts [BusinessUnit__c] on clientBranch with category field null [BusinessUnit__c.Category__c]
     * creates 4 strats [BusinessUnit__c] on clientBranch with category field [BusinessUnit__c.Category__c] of level 3 (limit to 2 categories)
     * the total of strats is (5 w/ category null) + (8 w/ category not null) = 13 strats
     * creates 1 product [Product2] on each element [Hierarchy__c] of level 4
     * assigns 1 element [Hierarchy__c] of level 1 to a variable
     * creates an assortment [Assortment_BU__c]
     * creates an assortment detail [AssortmentDetail__c] for each product
     * sets the test current page reference to Assortment BU Matrix
	*/
    static void init() {
        try {
            assortSettings = AssortmentSettings.loadAssortmentSettings();
            Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
            Map<String, Id> assDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentDetail__c.SObjectType);
            // NegoptimCustomSettings__c negoptimCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            // negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = CommonConstantsExt.GRID_SETTINGS_DEFAULT;
            // negoptimCustomSettings.Higher_Level_Packaging_Record_Type_Id__c = productRTIds.get('Higher_Level_Packaging');
            // insert negoptimCustomSettings;
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
            insert new List<BusinessUnit__c> {buSource, buTarget};
                
            stratList = new List<BusinessUnit__c>();
            for (Integer i = 0; i < 4; i++) {
                BusinessUnit__c strat = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + i);
                strat.ExtId__c = 'Strat' + i;
                strat.Code__c = 'Strat' + i;
                stratList.add(strat);
            }
            BusinessUnit__c closedBU = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat0');
            closedBU.ClosingDate__c = System.Today().addMonths(-1);
            stratList.add(closedBU);
            insert stratList;
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                Product2 p = TestDataFactory.createProduct(false, orgaHEList[4].Id, null);
                products.add(p);
            }
            insert products;
            assortment = new Assortment__c(Name = 'Ass1', BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                           Hierarchy__c = orgaHEList[1].Id, Status__c = 'Open',
                                                           BDate__c = Date.newInstance(System.Today().year(), 1, 1),
                                                           EDate__c = Date.newInstance(System.Today().year(), 12, 31), Year__c = System.Today().year());
            insert assortment;
            details = new List<AssortmentDetail__c>();
            for (Product2 item : products) {
                details.add(new AssortmentDetail__c(Product__c = item.Id, Assortment__c = assortment.Id,
                                                              Status__c = 'InPreparation', recordTypeId = assDetailRTIds.get('Regular')));
            }
            insert details;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static testMethod void test_case_load_initial_data() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.initData(assortment.Id, assortSettings.assortmentMatrixNego);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    
    static testMethod void test_case_init_tree_grid_data() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.initTreeGridData(assortment.Id, assortSettings.assortmentMatrixNego);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_load_tree_grid_data() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.loadTreeGridData(JSON.serialize(assortment), new List<String> {'SOSNumberNego__c'});
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_load_Data() {
        init();
        String mainData = AssortmentMatrixCtrl.initData(assortment.Id, assortSettings.assortmentMatrixNego);
        System.debug('assortSettings.assortmentMatrixNego: ' + assortSettings.assortmentMatrixNego);
        System.debug('assortSettings.assortmentMatrixNego:::: ' + assortSettings.assortmentMatrixNego);
        System.debug('assortment:::: ' + assortment);
        AssortmentMatrixCtrl.staticFieldsList.addAll(Schema.getGlobalDescribe().get(SObjectType.AssortmentDetail__c.Name).getDescribe().fields.getMap().keySet());
        System.debug('AssortmentMatrixCtrl.staticFieldsList:::: ' + JSON.serialize(AssortmentMatrixCtrl.staticFieldsList));
        String staticFields = String.join(AssortmentMatrixCtrl.staticFieldsList, ',');
        String masterStaticFields = String.join(AssortmentMatrixCtrl.fieldNames, ',');
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, '', masterStaticFields, SObjectType.AssortmentDetail__c.Name, '', staticFields, assortSettings.assortmentMatrixNego);
        System.debug('gridSettingsManager:::: ' + gridSettingsManager);
        AssortmentMatrixCtrl.FilterWrapper filterWrapper = new AssortmentMatrixCtrl.FilterWrapper();
        filterWrapper.searchValue = '';
        filterWrapper.dynamicSearch = '';
        filterWrapper.productLifeStatus = new List<String>();
        filterWrapper.productTypes = new List<String>();
        filterWrapper.hideBlankStatus = false;
        filterWrapper.showIntroProducts = false;
        filterWrapper.onlyShowIntroProducts = false;
        filterWrapper.isShowHistory = false;
        Test.startTest();
        String result = AssortmentMatrixCtrl.loadData(JSON.serialize(assortment), 25, 1, JSON.serialize(gridSettingsManager), JSON.serialize(filterWrapper), '', true);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_load_filered_Data() {
        init();
        System.debug('assortSettings.assortmentMatrixNego: ' + assortSettings.assortmentMatrixNego);
        String staticFields = String.join(AssortmentMatrixCtrl.staticFieldsList, ',');
        String masterStaticFields = String.join(AssortmentMatrixCtrl.fieldNames, ',');
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, '', masterStaticFields, SObjectType.AssortmentDetail__c.Name, '', staticFields, assortSettings.assortmentMatrixNego);
        AssortmentMatrixCtrl.FilterWrapper filterWrapper = new AssortmentMatrixCtrl.FilterWrapper();
        filterWrapper.searchValue = products[0].Product_EAN__c;
        filterWrapper.dynamicSearch = '[{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.StartDate__c.Name + '","value1":"2024-07-10","value2":"2024-07-13","userFilterable":true},{"fieldName":"Id","values":["123"]}]';
        filterWrapper.productLifeStatus = new List<String>{'keep'};
        filterWrapper.productTypes = new List<String>{'Switch'};
        filterWrapper.hideBlankStatus = true;
        filterWrapper.showIntroProducts = true;
        filterWrapper.onlyShowIntroProducts = true;
        filterWrapper.isShowHistory = true;
        Test.startTest();
        String result = AssortmentMatrixCtrl.loadData(JSON.serialize(assortment), 25, 1, JSON.serialize(gridSettingsManager), JSON.serialize(filterWrapper), '', true);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_change_status() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.changeAssortmentStatus(assortment.Id, 'Validate');
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_save_data() {
        init();
        for (AssortmentDetail__c detail : details) {
            detail.SOSNumberNego__c = 10;
        }
        Test.startTest();
        String result = AssortmentMatrixCtrl.saveData(JSON.serialize(details), '[]');
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_delete_data() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.saveData('[]', JSON.serialize(details));
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_save_data2() {
        init();
        for (AssortmentDetail__c detail : details) {
            detail.SOSNumberNego__c = 10;
        }
        Test.startTest();
        String result = AssortmentMatrixCtrl.save(JSON.serialize(details));
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_get_switch_products() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.getSwitchProducts(products[0].Id);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_get_hlp_products() {
        init();
        Test.startTest();
        String result = AssortmentMatrixCtrl.getHLPProducts(assortment.Id, products[0].Id);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_import() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail = [SELECT Id, ProductGTIN__c FROM AssortmentDetail__c WHERE Id = :details[0].Id];
        AssortmentDetail__c secondDetail = [SELECT Id, ProductGTIN__c FROM AssortmentDetail__c WHERE Id = :details[1].Id];
        // 1st GTIN: valid cluster Code__c -> success path of the BusinessUnitCluster__c branch
        // 2nd GTIN: unknown code -> logError path
        String dataJson = '{'
            + '"' + assortmentDetail.ProductGTIN__c + '":['
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name + '","fieldValue":"' + assortmentDetail.ProductGTIN__c + '"},'
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.AvgWeeklySalesClient__c.Name + '","fieldValue":100},'
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name + '","fieldValue":"' + stratList[1].Code__c + '"},'
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.StartDate__c.Name + '","fieldValue":"' + assortment.BDate__c + '"}],'
            + '"' + secondDetail.ProductGTIN__c + '":['
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name + '","fieldValue":"' + secondDetail.ProductGTIN__c + '"},'
            + '{"fieldName":"' + SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name + '","fieldValue":"Strat233"}]'
            + '}';

        assortment = [SELECT Id, ExtId__c, BDate__c FROM Assortment__c WHERE Id = :assortment.Id];
        Set<String> assortmentExtIds = new Set<String>{assortment.ExtId__c};
        String result = AssortmentMatrixCtrl.importAssortmentDetails('', dataJson, JSON.serialize(assortmentExtIds));
        AssortmentMatrixCtrl.checkCompletedBatches(result);
        AssortmentMatrixCtrl.checkLogs();
        String base64Content = EncodingUtil.Base64Encode(Blob.valueOf('Testing'));
        AssortmentMatrixCtrl.uploadFile('ASD File', base64Content, '', new List<Id> { assortment.Id });
        Test.stopTest();

        assortmentDetail = [SELECT Id, StartDate__c, AvgWeeklySalesClient__c,
                            BusinessUnitCluster__c, ProductCluster__c
                            FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        System.assertEquals(100, assortmentDetail.AvgWeeklySalesClient__c);
        System.assertEquals(assortment.BDate__c, assortmentDetail.StartDate__c);
        System.assertEquals(stratList[1].Id, assortmentDetail.BusinessUnitCluster__c, 'Cluster should resolve from Code__c');
        System.assertNotEquals(null, assortmentDetail.ProductCluster__c);
        Map<String, Object> clusterMap = (Map<String, Object>)JSON.deserializeUntyped(assortmentDetail.ProductCluster__c);
        System.assert(clusterMap.containsKey('Strat'));
        System.assert(clusterMap.containsKey('Cplt'));
        System.debug('clusterMap>>>>> ' + clusterMap);
        for (Object o : (List<Object>)clusterMap.get('Strat')) {
            Map<String, Object> w = (Map<String, Object>)o;
            Integer idx = Integer.valueOf(String.valueOf(w.get('index')));
            System.assertEquals(idx >= 1, (Boolean)w.get('value'), 'Wrong flag for index ' + idx);
        }
        // unknown code -> cluster left null
        AssortmentDetail__c unresolved = [SELECT Id, BusinessUnitCluster__c FROM AssortmentDetail__c WHERE Id = :secondDetail.Id];
        System.assertEquals(null, unresolved.BusinessUnitCluster__c, 'Unknown code should not set a cluster');
    }
    /*static testMethod void test_case_fake_save() {
        init();
        for (AssortmentDetail__c detail : details) {
            detail.SOSNumberNego__c = 10;
        }
        System.debug('assortSettings.assortmentMatrixNego: ' + assortSettings.assortmentMatrixNego);
        String staticFields = String.join(AssortmentMatrixCtrl.staticFieldsList, ',');
        String masterStaticFields = String.join(AssortmentMatrixCtrl.fieldNames, ',');
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, '', masterStaticFields, SObjectType.AssortmentDetail__c.Name, '', staticFields, assortSettings.assortmentMatrixNego);
        Test.startTest();
        String result = AssortmentMatrixCtrl.fakeSave(JSON.serialize(details), new List<String> {'SOSNumberNego__c'}, assortment.Id, orgaHEList[1].Id, JSON.serialize(gridSettingsManager), true);
        Test.stopTest();
        System.debug('result: ' + result);
        System.assertNotEquals(null, result);
    }*/
}