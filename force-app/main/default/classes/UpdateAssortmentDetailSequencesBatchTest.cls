@isTest
private class UpdateAssortmentDetailSequencesBatchTest {

    /*private static Integer year;
    private static Integer month;
    private static Integer day;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c country;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c cluster1;
    private static BusinessUnit__c cluster2;
    private static BusinessUnit__c refCluster;
    private static Supplier__c client;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static Assortment_BU__c assortmentBU;
    private static Map<String, Id> assDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_Detail__c.SObjectType);

    static void init() {
        year = System.Today().year();
        month = System.Today().month();
        day = System.Today().day();
        // Root element Id.
        rootId = NegoptimHelper.getRootId();
        // Get the Corporate Currency.
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.IsMasterBU__c = true;
        insert country;
        // Create Supplier
        client = TestDataFactory.createSupplier(false, country, true);
        insert client;
        // Create Departments & Sections.
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        insert product;
        // Create Master BU
        masterBU = TestDataFactory.createBusinessUnitChannel(false, country);
        masterBU.Mission__c = 'Panelist;Offer';
        masterBU.Format__c = CommonConstants.HMSM;
        masterBU.Supplier__c = client.Id;
        masterBU.IsMasterBU__c = true;
        masterBU.SiteOfSalesNumber__c = 100;
        for(Integer i = 1; i <= 12; i++) {
            masterBU.put('WeightedDistributionInnovRiseM'+ i +'__c', i);
            masterBU.put('WeightedDistributionSwitchRiseM'+ i +'__c', i);
            masterBU.put('WeightedDistributionStopRiseM'+ i +'__c', i);
        }
        insert masterBU;
        // Create BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.Format__c = CommonConstants.HMSM;
        buTarget.Supplier__c = client.Id;
        buTarget.Hierarchy__c = department.Id;
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('WeightedDistributionInnovRiseM'+ i +'__c', i);
            buTarget.put('WeightedDistributionSwitchRiseM'+ i +'__c', i);
            buTarget.put('WeightedDistributionStopRiseM'+ i +'__c', i);
        }
        insert buTarget;
        // Create BU Cluster
        cluster1 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat0');
        cluster1.Hierarchy__c = department.Id;
        cluster1.WeightedDistributionManual__c = 10;
        cluster1.SiteOfSalesNumber__c = 1;
        cluster2 = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat1');
        cluster2.Hierarchy__c = department.Id;
        cluster2.WeightedDistributionManual__c = 10;
        cluster2.SiteOfSalesNumber__c = 9;
        insert new List<BusinessUnit__c>{cluster1,cluster2};
            // insert assortment_BU
            assortmentBU = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmentBU.Status__c = 'Validated';
        insert assortmentBU;
    }
   
    @isTest static void case1_AssortmentTarget_Success() {
        init();
        Test.startTest();
        // insert assortment budget and target
        Assortment_BU__c assortmentBudget = TestDataFactory.createAssortmentBU(false, country, masterBU, department);
        assortmentBudget.RecordTypeId = TestDataFactory.assortmentBURTIds.get('Budget');
        assortmentBudget.Status__c = 'Validated';
        assortmentBudget.Assortment_type__c = 'In';
        insert assortmentBudget;
        Assortment_BU__c assortmenttarget = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmenttarget.RecordTypeId =  TestDataFactory.assortmentBURTIds.get('Target');
        assortmenttarget.Status__c = 'Validated';
        assortmenttarget.Assortment_Parent_Objective__c = assortmentBudget.Id;
        insert assortmenttarget;
        // insert Assortment_Detail__c budget and target
        Assortment_Detail__c assortmentDetailBudget = TestDataFactory.createAssortment_Detail(false, assortmentBudget.Id, product, null);
        assortmentDetailBudget.Status__c = 'Validated';
        assortmentDetailBudget.Client_Status__c = 'New';
        assortmentDetailBudget.New_Client_ND_MarketBased__c = 10;
        assortmentDetailBudget.New_Client_ND_ClientBased__c = 10;
        assortmentDetailBudget.New_Client_WD_MarketBased__c = 40;
        assortmentDetailBudget.New_Client_WD_ClientBased__c = 40;
        assortmentDetailBudget.RecordTypeId = assDetailRTIds.get('Regular');
        insert assortmentDetailBudget;
        Assortment_Detail__c assortmentDetailTarget = TestDataFactory.createAssortment_Detail(false, assortmenttarget.Id, product, null);
        assortmentDetailTarget.Status__c = 'Validated';
        assortmentDetailTarget.Client_Status__c = 'New';
        assortmentDetailTarget.New_Client_ND_MarketBased__c = 10;
        assortmentDetailTarget.New_Client_ND_ClientBased__c = 10;
        assortmentDetailTarget.New_Client_WD_MarketBased__c = 40;
        assortmentDetailTarget.New_Client_WD_ClientBased__c = 40;
        assortmentDetailTarget.Ref_Corp_Assortment__c = assortmentDetailBudget.Id;
        assortmentDetailTarget.RecordTypeId = assDetailRTIds.get('Regular');
        insert assortmentDetailTarget;
        Test.stopTest();
        NegoptimBatch.executeBatch(new UpdateAssortmentDetailSequencesBatch('Test', null, null, new Set<Id>{assortmentDetailTarget.Id}, null), 50);
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        Integer month = Date.today().month();
        assortmentDetailTarget = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetailTarget.Id];
        List<Assortment_Detail_Sequence__c> assortmentDetailTargetSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                               New_WD_ClientBased__c, Fx_WD_ClientBased__c, Target_ND_MarketBased__c, Sequence__c
                                                                               FROM Assortment_Detail_Sequence__c
                                                                               WHERE Assortment_Detail__c = :assortmentDetailTarget.Id];
        if(!assortmentDetailTargetSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailTargetSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('WeightedDistributionInnovRiseM'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(null, item.Target_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetailTarget.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays, item.Target_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetailTarget.New_Client_ND_MarketBased__c * WDRise, item.Target_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailTargetSequences.size());
    }
    
    @isTest static void case2_ProductInno_Success() {
        init();
        Test.startTest();
        // insert parent assortment nego for previous year
        Assortment_BU__c parentAssortmentNego = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        parentAssortmentNego.RecordTypeId =  TestDataFactory.assortmentBURTIds.get('Nego');
        parentAssortmentNego.Year__c = year - 1;
        parentAssortmentNego.Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentNego.Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentNego.Status__c = 'Validated';
        insert parentAssortmentNego;
        Assortment_Detail__c parentAssortmentDetailNego = TestDataFactory.createAssortment_Detail(false, parentAssortmentNego.Id, product, null);
        parentAssortmentDetailNego.Status__c = 'Validated';
        parentAssortmentDetailNego.Client_Status__c = 'New';
        parentAssortmentDetailNego.Movement_Date__c = Date.newInstance(year - 1, month, day);
        parentAssortmentDetailNego.Record_date__c = Date.newInstance(year - 1, month, day);
        parentAssortmentDetailNego.New_Client_ND_MarketBased__c = 10;
        parentAssortmentDetailNego.New_Client_ND_ClientBased__c = 10;
        parentAssortmentDetailNego.New_Client_WD_MarketBased__c = 40;
        parentAssortmentDetailNego.New_Client_WD_ClientBased__c = 40;
        insert parentAssortmentDetailNego;
        // insert assortment budget, target and nego
        Assortment_BU__c assortmentBudget = TestDataFactory.createAssortmentBU(false, country, masterBU, department);
        assortmentBudget.RecordTypeId = TestDataFactory.assortmentBURTIds.get('Budget');
        assortmentBudget.Status__c = 'Validated';
        assortmentBudget.Assortment_type__c = 'In';
        insert assortmentBudget;
        Assortment_BU__c assortmentTarget = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmentTarget.RecordTypeId =  TestDataFactory.assortmentBURTIds.get('Target');
        assortmentTarget.Status__c = 'Validated';
        assortmentTarget.Assortment_type__c = 'In';
        assortmentTarget.Assortment_Parent_Objective__c = assortmentBudget.Id;
        insert assortmentTarget;
        Assortment_BU__c assortmentNego = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmentNego.RecordTypeId =  TestDataFactory.assortmentBURTIds.get('Nego');
        assortmenttarget.Status__c = 'Validated';
        assortmentNego.Assortment_Parent_Objective__c = assortmentTarget.Id;
        insert assortmentNego;
        // insert Assortment_Detail__c budget, target and nego
        Assortment_Detail__c assortmentDetailBudget = TestDataFactory.createAssortment_Detail(false, assortmentBudget.Id, product, null);
        assortmentDetailBudget.Status__c = 'Validated';
        assortmentDetailBudget.Client_Status__c = 'New';
        assortmentDetailBudget.New_Client_ND_MarketBased__c = 10;
        assortmentDetailBudget.New_Client_ND_ClientBased__c = 10;
        assortmentDetailBudget.New_Client_WD_MarketBased__c = 40;
        assortmentDetailBudget.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetailBudget;
        Assortment_Detail__c assortmentDetailTarget = TestDataFactory.createAssortment_Detail(false, assortmentTarget.Id, product, null);
        assortmentDetailTarget.Status__c = 'Validated';
        assortmentDetailTarget.Client_Status__c = 'New';
        assortmentDetailTarget.New_Client_ND_MarketBased__c = 10;
        assortmentDetailTarget.New_Client_ND_ClientBased__c = 10;
        assortmentDetailTarget.New_Client_WD_MarketBased__c = 40;
        assortmentDetailTarget.New_Client_WD_ClientBased__c = 40;
        assortmentDetailTarget.Ref_Corp_Assortment__c = assortmentDetailBudget.Id;
        assortmentDetailTarget.Ref_Client_Assortment__c = parentAssortmentDetailNego.Id;
        insert assortmentDetailTarget;
        Assortment_Detail__c assortmentDetailNego = TestDataFactory.createAssortment_Detail(false, assortmentNego.Id, product, null);
        assortmentDetailNego.Status__c = 'Validated';
        assortmentDetailNego.Client_Status__c = 'New';
        assortmentDetailNego.New_Client_ND_MarketBased__c = 10;
        assortmentDetailNego.New_Client_ND_ClientBased__c = 10;
        assortmentDetailNego.New_Client_WD_MarketBased__c = 40;
        assortmentDetailNego.New_Client_WD_ClientBased__c = 40;
        assortmentDetailNego.Ref_Corp_Assortment__c = assortmentDetailTarget.Id;
        assortmentDetailNego.Ref_Client_Assortment__c = parentAssortmentDetailNego.Id;
        insert assortmentDetailNego;
        Test.stopTest();
        NegoptimBatch.executeBatch(new UpdateAssortmentDetailSequencesBatch('Test', null, null, new Set<Id>{assortmentDetailNego.Id}, null), 50);
        assortmentDetailNego = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, Ref_Client_ND_MarketBased_Nego__c
                                FROM Assortment_Detail__c WHERE Id = :assortmentDetailNego.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetailNego.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('WeightedDistributionInnovRiseM'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(assortmentDetailNego.Ref_Client_ND_MarketBased_Nego__c, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetailNego.Ref_Client_ND_MarketBased_Nego__c, item.Fx_ND_MarketBased__c);
                }
                if(sequence == month) {
                    ////System.assertEquals((parentAssortmentDetailNego.New_Client_ND_MarketBased__c * (day-1) + assortmentDetailNego.New_Client_ND_MarketBased__c*(monthDays - day + 1))/monthDays, item.New_ND_MarketBased__c);
                    ////System.assertEquals((parentAssortmentDetailNego.New_Client_ND_MarketBased__c * (day-1) + assortmentDetailNego.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1))/monthDays, item.Fx_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(assortmentDetailNego.New_Client_ND_MarketBased__c, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetailNego.New_Client_ND_MarketBased__c * WDRise, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
    
    @isTest static void case3_ProductStop_Success() {
        init();
        Test.startTest();
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortment_Detail(false, assortmentBU.Id, product, null);
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.Client_Status__c = 'Delete';
        assortmentDetail.Version__c = null;
        assortmentDetail.New_Client_ND_MarketBased__c = 0;
        assortmentDetail.New_Client_WD_ClientBased__c = 0;
        insert assortmentDetail;
        Test.stopTest();
        NegoptimBatch.executeBatch(new UpdateAssortmentDetailSequencesBatch('Test', null, null, new Set<Id>{assortmentDetail.Id}, null), 50);
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, Ref_Client_ND_MarketBased_Nego__c
                            FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('WeightedDistributionInnovRiseM'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(null, item.Fx_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays, item.Fx_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
    
    @isTest static void case4_ProductIncrease_Success() {
        init();
        Test.startTest();
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortment_Detail(false, assortmentBU.Id, product, cluster2.Id);
        assortmentDetail.Status__c = 'In preparation';
        assortmentDetail.Client_Status__c = 'New';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        ////assortmentDetail.Movement_Date__c = Date.newInstance(year, 3, 1);
        insert assortmentDetail;
        // insert history assortment details
        assortmentDetail.BusinessUnitAssCluster__c = cluster1.Id;
        assortmentDetail.Client_Status__c = 'Increase';
        assortmentDetail.Status__c = 'Validated';
        ////assortmentDetail.Movement_Date__c = Date.newInstance(year, 7, 12);
        update assortmentDetail;
        // generate assortment details sequences
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        Test.stopTest();
        NegoptimBatch.executeBatch(new UpdateAssortmentDetailSequencesBatch('Test', null, null, new Set<Id>{assortmentDetail.Id}, null), 50);
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, Last_History__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                if(sequence > month) {
                    System.assertEquals(10, item.New_ND_MarketBased__c);
                    System.assertEquals(10, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
    
    @isTest static void case5_UpdateAssortmentSequences_Success() {
        init();
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortment_Detail(false, assortmentBU.Id, product, cluster2.Id);
        assortmentDetail.Client_Status__c = 'Increase';
        assortmentDetail.BusinessUnitAssCluster__c = cluster1.Id;
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        Test.startTest();
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        // update sequences
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_ClientBased__c, New_WD_ClientBased__c, New_ND_MarketBased__c, New_WD_MarketBased__c,
                                                                         Fx_ND_ClientBased__c, Fx_WD_ClientBased__c, Fx_ND_MarketBased__c, Fx_WD_MarketBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                item.New_ND_MarketBased__c = null;
                item.New_ND_ClientBased__c = null;
                item.New_WD_MarketBased__c = null;
                item.New_WD_ClientBased__c = null;
                item.Fx_ND_MarketBased__c = null;
                item.Fx_ND_ClientBased__c = null;
                item.Fx_WD_MarketBased__c = null;
                item.Fx_WD_ClientBased__c = null;
            }
        }
        update assortmentDetailSequences;
        List<Assortment_Matrix_review__c> assortmentReviews = [SELECT Id, ND__c, WD__c, ND_Marketbase__c, WD_Marketbase__c, Sequence__c
                                                               FROM Assortment_Matrix_review__c WHERE Name__c = 'Negotiated'];
        if(!assortmentReviews.isEmpty()) {
            for(Assortment_Matrix_review__c item : assortmentReviews) {
                item.ND__c = null;
                item.WD__c = null;
                item.ND_Marketbase__c = null;
                item.WD_Marketbase__c = null;
            }
        }
        update assortmentReviews;
        NegoptimBatch.executeBatch(new UpdateAssortmentDetailSequencesBatch('Test', null, null, new Set<Id>{assortmentDetail.Id}, null), 50);
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, Last_History__c
                            FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        assortmentDetailSequences = [SELECT Id, New_ND_ClientBased__c, New_WD_ClientBased__c, New_ND_MarketBased__c, New_WD_MarketBased__c,
                                     Fx_ND_MarketBased__c, Fx_WD_ClientBased__c, Sequence__c
                                     FROM Assortment_Detail_Sequence__c
                                     WHERE Assortment_Detail__c = :assortmentDetail.Id ORDER BY Sequence__c];
        Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = new Map<Integer, Assortment_Detail_Sequence__c>();
        if(!assortmentDetailSequences.isEmpty()) {
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                if(sequence < month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(null, item.Fx_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays, item.New_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(10, item.New_ND_MarketBased__c);
                    System.assertEquals(10, item.Fx_ND_MarketBased__c);
                }
                sequencesMap.put(sequence, item);
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
        assortmentReviews = [SELECT Id, ND__c, WD__c, ND_Marketbase__c, WD_Marketbase__c, Sequence__c
                             FROM Assortment_Matrix_review__c WHERE Name__c = 'Negotiated' ORDER BY Sequence__c];
        if(!assortmentReviews.isEmpty()) {
            for(Assortment_Matrix_review__c item : assortmentReviews) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                System.assertEquals(sequencesMap.get(sequence).New_ND_ClientBased__c, item.ND__c);
                System.assertEquals(sequencesMap.get(sequence).New_ND_MarketBased__c, item.ND_Marketbase__c);
            }
        }
    }*/
}