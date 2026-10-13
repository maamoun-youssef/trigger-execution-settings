/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for Trg_AssortmentDetail_Handler
 **************************************************************/
@isTest
private class Trg_AssortmentDetail_HandlerTest {

    private static Id rootId;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Hierarchy__c section2;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<BusinessUnit__c> clusters;
    private static List<BusinessUnit__c> cpltClusters;
    private static Assortment__c assortmentBU, assortmentBUTop;
    private static BusinessUnit__c country;
    
    static void init() {
        // Root element Id.
        rootId = NegoptimHelper.getRootId();
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.IsMasterBU__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // create HEs
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        section2 = TestDataFactory.createHierarchySection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        product.UV__c = 'KG';
        product.Weight__c = 0.5;
        product.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
        insert product;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.Supplier__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        buSource.ExtId__c = buSource.Code__c;
        system.debug('buSource.Code__c >>> ' + buSource.Code__c);
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.IsMultipleComplementary__c = true;
        buTarget.Supplier__c = supplier.Id;
        buTarget.Hierarchy__c = department.Id;
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        buTarget.WeightedDistributionManual__c = 45;
        buTarget.SiteOfSalesNumber__c = 185;
        buTarget.ExtId__c = buTarget.Code__c;
        system.debug('buTarget.Code__c >>> ' + buTarget.Code__c);
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('WeightedDistributionInnovRiseM' + i + '__c', i);
        }
        insert new List<BusinessUnit__c>{buTarget, buSource};
        clusters = new List<BusinessUnit__c>();
        cpltClusters = new List<BusinessUnit__c>();
        for (Integer i = 5; i >= 0; i--) {
            BusinessUnit__c cluster = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            cluster.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.SiteOfSalesNumber__c = 30 * (i + 2); // 210, 180, 150, 120, 90, 60
            cluster.SiteOfSalesNumberP1__c = 35 * (i + 2); // 245, 210, 175, 140, 105, 70
            cluster.Hierarchy__c = department.Id;
            clusters.add(cluster);
            BusinessUnit__c clusterCplt = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Cplt' + (5 - i));
            clusterCplt.OpeningDate__c = Date.newInstance(Date.today().year() - 5, 1, 1);
            clusterCplt.WeightedDistributionManual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            cluster.Hierarchy__c = department.Id;
            cpltClusters.add(clusterCplt);
        }
        List<BusinessUnit__c> allClusters = new List<BusinessUnit__c>();
        allClusters.addAll(clusters);
        allClusters.addAll(cpltClusters);
        insert allClusters;
        // insert assortment_BU        
        assortmentBU = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortmentBU.Status__c = 'Validate';
        assortmentBU.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        insert assortmentBU;
    }

    // case autoFillAssortmentCategory/update Client_Clust(i)__c/calculate WD
    static testmethod void case1_InsertAssortmentDetail_Success() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                         BusinessUnitCluster__c = clusters[1].Id, ProductLifeStatusAss__c = 'New');
        insert assortmentDetail;
        Test.stopTest();
        // Assertion.
        assortmentDetail = [SELECT ProductCluster__c, Hierarchy__c, WDChannelBaseNego__c, WDClientBaseNego__c
                            FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
		Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(assortmentDetail.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(assortmentDetail.ProductCluster__c, Map<String, List<AssortmentServices.ClusterWrapper>>.class) : new Map<String, List<AssortmentServices.ClusterWrapper>>();
        List<AssortmentServices.clusterWrapper> productCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<AssortmentServices.clusterWrapper>();
        Map<Integer, Boolean> productclustersMap = new Map<Integer, Boolean>();
        for (AssortmentServices.clusterWrapper strat : productCluster) {
            productclustersMap.put(strat.index, strat.value);
        }
        System.assertEquals(product.Hierarchy__c, assortmentDetail.Hierarchy__c);
        for (Integer stratIndex : productclustersMap.keySet()) {
            if (stratIndex == 0) {
                System.assertEquals(false, productclustersMap.get(stratIndex));                
            } else {
                System.assertEquals(true, productclustersMap.get(stratIndex));
            }
        }
        System.assertEquals(60, assortmentDetail.WDChannelBaseNego__c);
        System.assertEquals((60/81.0*100).setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Scale), assortmentDetail.WDClientBaseNego__c); // sum WD Clusters = 81
    }

    static testmethod void case1_MassInsertAssortment_Success() {
        init();
        Test.startTest();
        Integer count = 80;
        // insert Products
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < count; i++) {
            product = TestDataFactory.createProduct(false, section.Id, null);
            products.add(product);
        }
        insert products;
        // insert Assortment_Detail__c list
        List<AssortmentDetail__c> assortmentDetails = new List<AssortmentDetail__c>();
        for(Integer i = 0; i < count; i++) {
            AssortmentDetail__c assortmentDetail = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, products[i], null);
            assortmentDetail.Status__c = 'InPreparation';
            assortmentDetail.ProductLifeStatusAss__c = 'New';
            assortmentDetails.add(assortmentDetail);
        }
        insert assortmentDetails;
        Assortment__c assortmentBUCloned = assortmentBU.clone(false);
        insert assortmentBUCloned;
        Test.stopTest();
        // Assertion.
        System.assertEquals(count, [SELECT COUNT() FROM AssortmentDetail__c]);
    }

    // case update BusinessUnitCluster__c
    static testmethod void case2_UpdateAssortmentDetail_Success() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, StartDate__c = Date.today(),
                                                                         BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate');
        insert assortmentDetail;
        assortmentDetail.ProductLifeStatusAss__c = 'Keep';
        assortmentDetail = [SELECT ProductCluster__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        List<AssortmentServices.clusterWrapper> productCluster = new List<AssortmentServices.clusterWrapper>();
        productCluster.add(new AssortmentServices.clusterWrapper(0, false));
        productCluster.add(new AssortmentServices.clusterWrapper(1, true));            
        Map<String, List<AssortmentServices.ClusterWrapper>> newProdCluster = new Map<String, List<AssortmentServices.ClusterWrapper>>();
        newProdCluster.put('Strat', productCluster);
        assortmentDetail.ProductCluster__c = JSON.serialize(newProdCluster);
        assortmentDetail.RecordDate__c = System.today();
        update assortmentDetail;
        // Assertion.
        assortmentDetail = [SELECT BusinessUnitCluster__c, AssortmentDetailLHistory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals(clusters[1].Id, assortmentDetail.BusinessUnitCluster__c);
    }

    static testmethod void case4_ValidateAssortmentCategory_Failure() {
        init();
        // Create Departments & Sections.
        Hierarchy__c department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
        Hierarchy__c section1 = TestDataFactory.createHierarchySection(true, department1.Id);
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = section1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(assortmentDetail, false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }

    static testmethod void case5_InsertAssortmentDetailOneByOne_Failure() {
        init();
        AssortmentDetail__c assortmentDetail1 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                          BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'New', Version__c = null);
        AssortmentDetail__c assortmentDetail2 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                          BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'New', Version__c = null);
        Test.startTest();
        Database.SaveResult sr1 = Database.insert(assortmentDetail1, false);
        Database.SaveResult sr2 = Database.insert(assortmentDetail2, false);
        Test.stopTest();
        // Assertion.
        System.assertEquals(0, sr1.getErrors().size());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr2.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, sr2.getErrors()[0]);
    }

    static testmethod void case6_UpdateAssortmentDetail_SwitchProduct_Failure() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail1 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = product.Hierarchy__c,
                                                                          BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
        insert assortmentDetail1;
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        AssortmentDetail__c assortmentDetail2 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = p1.Id, Hierarchy__c = product.Hierarchy__c,
                                                                          BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
        insert assortmentDetail2;
        assortmentDetail2.Product__c = product.Id;
        Database.SaveResult result = Database.update(assortmentDetail2,false);
        Test.stopTest();
        System.assertEquals(0, result.getErrors().size());
    }

    static testmethod void case7_InsertAssortmentDetailList_Failure() {
        init();
        AssortmentDetail__c assortmentDetail1 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                          BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'New', Version__c = null);
        AssortmentDetail__c assortmentDetail2 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                          BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'New', Version__c = null);
        Test.startTest();
        List<Database.SaveResult> lsr = Database.insert(new List<AssortmentDetail__c>{assortmentDetail1,assortmentDetail2}, false);
        Test.stopTest();
        // Assertion.
        System.assertEquals(0, lsr.get(0).getErrors().size());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, lsr.get(1).getErrors()[0].getStatusCode());
        System.assertNotEquals(null, lsr.get(1).getErrors()[0]);
    }

    /*static testmethod void case8_GenerateAssortmentDetailSequencesAndMatrix_Success() {
        init();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         BusinessUnitCluster__c = clusters[0].Id,
                                                                         StartDate__c = Date.today(),
                                                                         RecordDate__c = Date.today(),
                                                                         ProductLifeStatusAss__c = 'Keep');
        insert assortmentDetail;
        Test.startTest();
        assortmentDetail.Status__c = 'Validate';
        update assortmentDetail;
        Test.stopTest();
        System.assertEquals(12, [SELECT COUNT() FROM Assortment_Detail_Sequence__c WHERE Assortment_Detail__c = :assortmentDetail.Id]);
    }*/

    static testmethod void case9_generateExternalId_Single_Product_With_NO_Ext_Id () {
        init();
        Test.startTest();
        Product2 p1 = TestDataFactory.createProduct(true, section.Id, null);
        p1.Ext_id__c = null;
        update p1;
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = p1.Id, Hierarchy__c = p1.Hierarchy__c,
                                                                         BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
        Database.SaveResult result = Database.insert(assortmentDetail,false);
        assortmentDetail = [SELECT Id, ExtId__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        Test.stopTest();
        System.assert(assortmentDetail.ExtId__c.contains(p1.Id));
    }

    static testmethod void case10_generateExternalId_Mass_success() {
        init();
        Map<String, Id> recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Product2.sObjectType);
        Integer numberOfRecords = 1;
        Test.startTest();
        List<Product2> productList = new List<Product2>();
        List<AssortmentDetail__c> asdList = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            p.recordTypeId = recordTypes.get('Product');
            p.Ext_id__c = p.Product_EAN__c + '-' + p.ProductCode;
            productList.add(p);
        }
        insert productList;
        // Product2.Id => Product2
        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        for (Product2 item : productList) {
            productsMap.put(item.Id, item);
        }
        for (Integer i = 0; i < numberOfRecords; i++) {
            AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = productList.get(i).Id, Hierarchy__c = productList.get(i).Hierarchy__c,
                                                                             BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
            asdList.add(assortmentDetail);
        }
        List<Database.SaveResult> resultList = Database.insert(asdList, false);
        Test.stopTest();
        asdList = [SELECT Product__c, Assortment__r.ExtId__c, Version__c, ExtId__c FROM AssortmentDetail__c WHERE Id IN :asdList];
        System.assertEquals(numberOfRecords, asdList.size());
        for (AssortmentDetail__c item : asdList) {
            Product2 product = productsMap.get(item.Product__c);
            String version = item.Version__c != null ? String.valueOf(item.Version__c) : '';
            String externalID = item.Assortment__r.ExtId__c + '-' + (product.Ext_Id__c == null ? String.valueOf(product.Id) : product.Ext_Id__c) + '-V' + version;
            System.assertEquals(externalID, item.ExtId__c);
        }
    }

    static testmethod void case11_linkRefASD_success() {
        init();
        Test.startTest();
        Assortment__c nego = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        nego.Status__c = 'Validate';
        nego.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        Assortment__c budget = TestDataFactory.createAssortment(false, country, buSource, department);
        Map<String, Id> assortmentRTsIds = TestDataFactory.assortmentRTIds;
        budget.RecordTypeId = assortmentRTsIds.get('ChannelBudget');
        insert new List<Assortment__c>{nego, budget};
        Integer numberOfRecords = 1;
        List<Product2> productList = new List<Product2>();
        List<AssortmentDetail__c> asdList = new List<AssortmentDetail__c>();
        List<AssortmentDetail__c> asdList2 = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            p.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
            productList.add(p);
        }
        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            AssortmentDetail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail2(false, nego.Id, productList.get(i), null);
            assortmentDetail1.Hierarchy__c = productList.get(i).Hierarchy__c;
            assortmentDetail1.ProductLifeStatusAss__c = 'New';
            assortmentDetail1.Status__c = 'Validate';
            assortmentDetail1.Version__c = null;
            asdList.add(assortmentDetail1);
            AssortmentDetail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail2(false, budget.Id, productList.get(i), null);
            assortmentDetail2.Hierarchy__c = productList.get(i).Hierarchy__c;
            assortmentDetail2.ProductLifeStatusAss__c = 'New';
            assortmentDetail2.Status__c = 'Validate';
            assortmentDetail2.Version__c = null;
            asdList2.add(assortmentDetail2);
        }
        List<AssortmentDetail__c> asdLists = new List<AssortmentDetail__c>(asdList);
        asdLists.addAll(asdList2);
        system.debug('asdLists >>> ' + JSON.serialize(asdLists));
        insert asdLists;
        Assortment__c target = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        target.Status__c = 'Validate';
        target.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        target.AssortmentNegotiationRef__c = nego.Id;
        target.AssortmentChannelBudgetRef__c = budget.Id;
        insert target;
        Test.stopTest();
        List<AssortmentDetail__c> targetASDsList = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            AssortmentDetail__c assortmentDetail = TestDataFactory.createAssortmentDetail2(false, target.Id, productList.get(i), null);
            assortmentDetail.Hierarchy__c = productList.get(i).Hierarchy__c;
            assortmentDetail.ProductLifeStatusAss__c = 'New';
            assortmentDetail.Status__c = 'Validate';
            assortmentDetail.Version__c = null;
            targetASDsList.add(assortmentDetail);
        }
        insert targetASDsList;
        targetASDsList = [SELECT Id, AssortmentDetailBudgetRef__c, AssortmentDetailNegotiationRef__c FROM AssortmentDetail__c WHERE Assortment__c = :target.Id];
        for (Integer i = 0; i < numberOfRecords; i++) {
            System.assertEquals(asdList.get(i).Id, targetASDsList.get(i).AssortmentDetailNegotiationRef__c);
            System.assertEquals(asdList2.get(i).Id, targetASDsList.get(i).AssortmentDetailBudgetRef__c);
        }
    }

    /*static testmethod void case12_CreateAssortmentDetailsFromParentTarget_success() {
        init();
        Test.startTest();
        Map<String, Id> assortmentRTsIds = TestDataFactory.assortmentRTsIds;
        Assortment__c target = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        target.Status__c = 'Validate';
        insert target;
        Integer numberOfRecords = 1;
        List<Product2> productList = new List<Product2>();
        List<AssortmentDetail__c> asdList = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            productList.add(p);
        }

        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            AssortmentDetail__c assortmentDetail = TestDataFactory.createAssortmentDetail2(false, target.Id, productList.get(i), null);
            assortmentDetail.Hierarchy__c = productList.get(i).Hierarchy__c;
            assortmentDetail.ProductLifeStatusAss__c = 'New';
            assortmentDetail.Status__c = 'Validate';
            assortmentDetail.Version__c = null;
            asdList.add(assortmentDetail);
        }
        insert asdList;
        Assortment__c nego1 = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        nego1.Status__c = 'Validate';
        nego1.AssortmentNegotiationRef__c = target.Id;
        insert nego1;
        Assortment__c nego2 = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        nego2.Status__c = 'Validate';
        nego2.AssortmentNegotiationRef__c = target.Id;
        insert nego2;
        ///// insert new List<Assortment_BU__c> {nego1, nego2};
        Test.stopTest();
        List<AssortmentDetail__c> nego1ASDsList = [SELECT Id, AssortmentDetailTargetRef__c, AssortmentDetailNegotiationRef__c FROM AssortmentDetail__c WHERE Assortment__c = :nego1.Id];
        List<AssortmentDetail__c> nego2ASDsList = [SELECT Id, AssortmentDetailTargetRef__c, AssortmentDetailNegotiationRef__c FROM AssortmentDetail__c WHERE Assortment__c = :nego2.Id];

        for (Integer i = 0; i < numberOfRecords; i++) {
            System.assertEquals(asdList.get(i).Id, nego1ASDsList.get(i).AssortmentDetailNegotiationRef__c);
            System.assertEquals(null, nego1ASDsList.get(i).AssortmentDetailTargetRef__c);
            System.assertEquals(asdList.get(i).Id, nego2ASDsList.get(i).AssortmentDetailNegotiationRef__c);
            System.assertEquals(null, nego2ASDsList.get(i).AssortmentDetailTargetRef__c);
        }
    }*/

    /*static testmethod void case13_updateClientClusters_insert_single() {
        init();
        test.startTest();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        AssortmentDetail__c detail = TestDataFactory.createAssortmentDetail2(true, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        test.stopTest();
        detail = [SELECT ProductCluster__c
                  FROM AssortmentDetail__c WHERE Id = :detail.Id];
        Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(detail.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(detail.ProductCluster__c, Map<String, List<AssortmentServicesExt.ClusterWrapper>>.class) : new Map<String, List<AssortmentServicesExt.ClusterWrapper>>();
        List<AssortmentServices.clusterWrapper> productCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<AssortmentServices.clusterWrapper>();
        Map<Integer, Boolean> productclustersMap = new Map<Integer, Boolean>();
        for (AssortmentServices.clusterWrapper strat : productCluster) {
            productclustersMap.put(strat.index, strat.value);
        }
        System.assertEquals(true, productclustersMap.get(clusters.size() - 1));
        for (Integer i = clusters.size() - 1 ; i > 0; i--) {
            System.assertEquals(false, productclustersMap.get(i - 1));
        }
    }*/

    /*static testmethod void case14_updateClientClusters_insert_mass() {
        init();
        test.startTest();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        List<AssortmentDetail__c> details = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        for (Product2 product : products) {
            AssortmentDetail__c tempASD = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
            List<AssortmentServices.clusterWrapper> productCluster = new List<AssortmentServices.clusterWrapper>();
            for(Integer i = 0; i< clusters.size(); i++){
                productCluster.add(new AssortmentServices.clusterWrapper(i, false));
                if(i == clusters.size()){
                    productCluster.add(new AssortmentServices.clusterWrapper(i, true));  
                }
            }
            Map<String, List<AssortmentServices.ClusterWrapper>> newProdCluster = new Map<String, List<AssortmentServices.ClusterWrapper>>();
            newProdCluster.put('Strat', productCluster);
            tempASD.ProductCluster__c = JSON.serialize(newProdCluster);
            details.add(tempASD);
        }
        insert details;
        test.stopTest();
        
        details = [SELECT ProductCluster__c FROM AssortmentDetail__c WHERE Id = :details];
        for (AssortmentDetail__c detail : details) {
            Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(detail.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(detail.ProductCluster__c, Map<String, List<AssortmentServicesExt.ClusterWrapper>>.class) : new Map<String, List<AssortmentServicesExt.ClusterWrapper>>();
            List<AssortmentServices.clusterWrapper> selectedCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<AssortmentServices.clusterWrapper>();
            Map<Integer, Boolean> productclustersMap = new Map<Integer, Boolean>();
            for (AssortmentServices.clusterWrapper strat : selectedCluster) {
                productclustersMap.put(strat.index, strat.value);
            }
            for (Integer i = clusters.size() - 1 ; i > 0; i--) {
                if(i == clusters.size() - 1) {
                    System.assertEquals(true, productclustersMap.get(i));
                } else {
                    System.assertEquals(false, productclustersMap.get(i));
                }
            }
            /*System.assertEquals(true, detail.get('Client_Clust' + clusters.size() + '__c'));
            for (Integer i = clusters.size() - 1 ; i > 0; i--) {
                System.assertEquals(false, detail.get('Client_Clust' + i + '__c'));
            }
        }
    }*/

    /*static testmethod void case15_updateClientClusters_update_single() {
        init();
        test.startTest();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        AssortmentDetail__c detail = TestDataFactory.createAssortmentDetail2(true, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        detail.BusinessUnitCluster__c = clusters[0].Id;
        update detail;
        test.stopTest();
        /*detail = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                  FROM Assortment_Detail__c WHERE Id = :detail.Id];
        for (Integer i = 1 ; i <= clusters.size(); i++) {
            System.assertEquals(true, detail.get('Client_Clust' + i + '__c'));
        }
        detail = [SELECT ProductCluster__c FROM AssortmentDetail__c WHERE Id = :detail.Id];
        Map<String, List<AssortmentServices.ClusterWrapper>> productClusterMap = String.isNotBlank(detail.ProductCluster__c) ? (Map<String, List<AssortmentServices.ClusterWrapper>>) JSON.deserialize(detail.ProductCluster__c, Map<String, List<AssortmentServicesExt.ClusterWrapper>>.class) : new Map<String, List<AssortmentServicesExt.ClusterWrapper>>();
        
        List<AssortmentServices.clusterWrapper> selectedCluster = productClusterMap.containsKey('Strat') ? productClusterMap.get('Strat') : new List<AssortmentServices.clusterWrapper>();
        Map<Integer, Boolean> productclustersMap = new Map<Integer, Boolean>();
        for (AssortmentServices.clusterWrapper strat : selectedCluster) {
            productclustersMap.put(strat.index, strat.value);
        }
        for (Integer i = clusters.size() - 1 ; i > 0; i--) {
           System.assertEquals(true, productclustersMap.get(i));
        }
    }*/

    static testmethod void case16_updateClientClusters_update_mass() {
        init();
        test.startTest();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        List<AssortmentDetail__c> details = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        for (Product2 product : products) {
            details.add(TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id));
        }
        insert details;
        for (AssortmentDetail__c detail : details) {
            detail.BusinessUnitCluster__c = clusters[0].Id;
        }
        update details;
        test.stopTest();
        /*details = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                   FROM Assortment_Detail__c WHERE Id = :details];
        for (Assortment_Detail__c detail : details) {
            for (Integer i = 1 ; i <= clusters.size(); i++) {
                System.assertEquals(true, detail.get('Client_Clust' + i + '__c'));
            }
        }*/
    }

    /*static testmethod void case17_updateClientStatus_single_increase() {
        init();
        test.startTest();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        AssortmentDetail__c detail = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        detail.ProductLifeStatusAss__c = 'Keep';
        detail.Status__c = 'Validate';
        insert detail;
        detail.BusinessUnitCluster__c = clusters[0].Id;
        update detail;
        test.stopTest();
        detail = [SELECT ProductLifeStatusAss__c FROM AssortmentDetail__c WHERE Id = :detail.Id];
        System.assertEquals('Increase', detail.ProductLifeStatusAss__c);
    }*/

    /*static testmethod void case18_updateClientStatus_single_decrease() {
        init();
        test.startTest();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        AssortmentDetail__c detail = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, clusters[0].Id);
        detail.ProductLifeStatusAss__c = 'Keep';
        detail.Status__c = 'Validate';
        insert detail;
        detail.BusinessUnitCluster__c = clusters[1].Id;
        update detail;
        test.stopTest();
        detail = [SELECT ProductLifeStatusAss__c FROM AssortmentDetail__c WHERE Id = :detail.Id];
        System.assertEquals('Decrease', detail.ProductLifeStatusAss__c);
    }*/

    /*static testmethod void case19_updateClientStatus_single_delete() {
        init();
        test.startTest();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        AssortmentDetail__c detail = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        detail.ProductLifeStatusAss__c = 'Keep';
        detail.Status__c = 'Validate';
        insert detail;
        detail.BusinessUnitCluster__c = null;
        update detail;
        test.stopTest();
        detail = [SELECT ProductLifeStatusAss__c FROM AssortmentDetail__c WHERE Id = :detail.Id];
        System.assertEquals('Delete', detail.ProductLifeStatusAss__c);
    }*/

    /*static testmethod void case20_updateClientStatus_mass() {
        init();
        test.startTest();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        AssortmentDetail__c detail1, detail2, detail3;
        List<AssortmentDetail__c> details = new List<AssortmentDetail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        detail1 = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, products[0], clusters[clusters.size() - 1].Id);
        detail1.ProductLifeStatusAss__c = 'Keep';
        detail1.Status__c = 'Validate';
        details.add(detail1);
        insert details;
        detail1.BusinessUnitCluster__c = clusters[0].Id;
        update details;
        test.stopTest();
        details = [SELECT ProductLifeStatusAss__c FROM AssortmentDetail__c WHERE Id = :details];
        for (AssortmentDetail__c detail : details) {
            if (detail.Id == detail1.Id) detail1 = detail;
        }
        System.assertEquals('Increase', detail1.ProductLifeStatusAss__c);
    }*/

    static testmethod void case21_UpdateRecentlyDetailsAssortmentBUNego_Success() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         BusinessUnitCluster__c = null,
                                                                         StartDate__c = Date.today(),
                                                                         RecordDate__c = Date.today(),
                                                                         ProductLifeStatusAss__c = 'Keep',
                                                                         Status__c = 'Validate');
        insert assortmentDetail;
        assortmentDetail.ProductLifeStatusAss__c = 'Keep';
        assortmentDetail.ProductCluster__c = '{"Strat":[{"index":0,"value":false},{"index":1,"value":true},{"index":2,"value":true},{"index":3,"value":true},{"index":4,"value":true}],"Cplt":[]}';
        assortmentDetail.RecordDate__c = System.today();
        update assortmentDetail;
        Test.stopTest();
        assortmentDetail = [SELECT BusinessUnitCluster__c, AssortmentDetailLHistory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals(clusters[1].Id, assortmentDetail.BusinessUnitCluster__c);
        //assortmentBU = [SELECT Is_Detail_Recently_updated__c, Recent_Detail_updates__c, Status__c FROM Assortment__c WHERE Id = :assortmentBU.Id];
        //System.assertNotEquals(null, assortmentBU.Recent_Detail_updates__c);
    }

    static testmethod void case22_UpdateRecentlyDetailsAssortmentBUBudget_Success() {
        init();
        Test.startTest();
        Assortment__c assortmentBUBudget = TestDataFactory.createAssortment(false, country, buSource, department);
        assortmentBUBudget.RecordTypeId = TestDataFactory.assortmentRTIds.get('ChannelBudget');
        assortmentBUBudget.Status__c = 'RequestForApproval';
        insert assortmentBUBudget;
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBUBudget.Id,
                                                                         Product__c = product.Id,
                                                                         BusinessUnitCluster__c = null,
                                                                         StartDate__c = Date.today(),
                                                                         RecordDate__c = Date.today(),
                                                                         ProductLifeStatusAss__c = 'New',
                                                                         WDChannelBaseNego__c = 20,
                                                                         Status__c = 'RequestForApproval');
        insert assortmentDetail;
        assortmentDetail.WDChannelBaseNego__c = 100;
        update assortmentDetail;
        Test.stopTest();
        //assortmentBUBudget = [SELECT Is_Detail_Recently_updated__c, Recent_Detail_updates__c, Status__c FROM Assortment_BU__c WHERE Id = :assortmentBUBudget.Id];
        ////System.assertEquals(true, assortmentBUBudget.Is_Detail_Recently_updated__c);
        //System.assertNotEquals(null, assortmentBUBudget.Recent_Detail_updates__c);
    }
    /*static testmethod void case23_consolidateAssortmentDetails_Success() {
        init();
        Test.startTest();
        Integer year = System.Today().year();
        // Create Products
        Product2 product1 = TestDataFactory.createProduct(false, section.Id, null);
        product1.Name = 'product1';
        product1.Ext_id__c = '1';
        Product2 product2 = TestDataFactory.createProduct(false, section.Id, null);
        product2.Name = 'product2';
        product2.Ext_id__c = '2';
        insert new List<Product2>{product1,product2};
        // Create Master BU
        BusinessUnit__c masterBU = TestDataFactory.createBUChannel(false, country);
        masterBU.Mission__c = 'Panelist;Offer';
        masterBU.Format_Origin__c = CommonConstants.HMSM;
        masterBU.Related_Client__c = supplier.Id;
        masterBU.IsMasterBU__c = true;
        // Create Conso BU
        BusinessUnit__c buConsoHMSM = TestDataFactory.createBUBanner(false, country);
        buConsoHMSM.Mission__c = 'Panelist;Offer';
        buConsoHMSM.Format_Origin__c = CommonConstants.HMSM;
        buConsoHMSM.Related_Client__c = supplier.Id;
        buConsoHMSM.Layer_Nego_Conso__c = true;
        buConsoHMSM.Hierarchy__c = department.Id;
        buConsoHMSM.Weighted_Distribution_Manual__c = 50;
        // Create Target BUs
        BusinessUnit__c buBannerHM = TestDataFactory.createBUBanner(false, country);
        buBannerHM.Mission__c = 'Offer';
        buBannerHM.Format_Origin__c = CommonConstants.HMSM;
        buBannerHM.Related_Client__c = supplier.Id;
        buBannerHM.Hierarchy__c = department.Id;
        buBannerHM.Weighted_Distribution_Manual__c = 10;
        BusinessUnit__c buBannerSM = TestDataFactory.createBUBanner(false, country);
        buBannerSM.Mission__c = 'Offer';
        buBannerSM.Format_Origin__c = CommonConstants.HMSM;
        buBannerSM.Related_Client__c = supplier.Id;
        buBannerSM.Hierarchy__c = department.Id;
        buBannerSM.Weighted_Distribution_Manual__c = 20;
        insert new List<BusinessUnit__c>{masterBU,buConsoHMSM,buBannerHM,buBannerSM};
        // insert assortment_BU
        Assortment__c assortment1 = TestDataFactory.createAssortment(false, masterBU, buBannerHM, department);
        assortment1.Status__c = 'Validate';
        assortment1.onTop__c = true;
        Assortment__c assortment2 = TestDataFactory.createAssortment(false, masterBU, buBannerSM, department);
        assortment2.Status__c = 'Validate';
        assortment2.onTop__c = true;
        insert new List<Assortment__c>{assortment1,assortment2};
        AssortmentDetail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail2(false, assortment1.Id, product2, null);
        assortmentDetail2.Status__c = 'Validate';
        assortmentDetail2.ProductLifeStatusAss__c = 'New';
        assortmentDetail2.WDClientBaseNego__c = 22;
        //assortmentDetail2.WD_Conso__c = false;
        insert new List<AssortmentDetail__c>{assortmentDetail2};
        Test.stopTest();
        AssortmentDetail__c assortmentDetailConso1 = [SELECT WDClientBaseNego__c FROM AssortmentDetail__c
                                                                WHERE Product__c = :product2.Id AND Assortment__r.BusinessUnitTarget__c = :buConsoHMSM.Id
                                                                AND Assortment__r.RecordType.DeveloperName = 'OnTopConso' ];
        //AND Year__c = :year
        // case Conso HM/SM
        Decimal weightedDistributionManual_HMSM = 100;
        Decimal DV = 22*20/weightedDistributionManual_HMSM;
        System.assertEquals(DV.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso1.WDClientBaseNego__c);
    }*/

    static testmethod void case24_SwitchProduct_Success() {
        init();
        Test.startTest();
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        AssortmentDetail__c assortmentDetail2 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = p1.Id, Hierarchy__c = product.Hierarchy__c,
                                                                          WDChannelBaseNego__c = 10, WDClientBaseNego__c = 20,
                                                                          BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
        insert assortmentDetail2;
        assortmentDetail2.Product__c = product.Id;
        Database.SaveResult result = Database.update(assortmentDetail2,false);
        Test.stopTest();
        AssortmentDetail__c switchedAssortmentDetail = [SELECT Id, ProductLifeStatusAss__c, Status__c, Version__c, AssortmentDetailLHistory__c, WDChannelBaseNego__c, WDClientBaseNego__c
                                                         FROM AssortmentDetail__c WHERE Status__c = 'PreviouslyValidate' AND ProductLifeStatusAss__c = 'Substitute'];
        System.assertEquals(2, switchedAssortmentDetail.Version__c);
    }

    // case update Client_Clust_Cplt(i)__c/calculate WD
    /*static testmethod void case25_InsertAssortmentDetail_Cplt_Success() {
        init();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                         BusinessUnitCluster__c = cpltClusters[3].Id, ProductLifeStatusAss__c = 'Complement');
        Test.startTest();
        insert assortmentDetail;
        Test.stopTest();
        assortmentDetail = [SELECT Hierarchy__c, WDChannelBaseNego__c, WDClientBaseNego__c
                            FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];

        System.assertEquals(product.Hierarchy__c, assortmentDetail.Hierarchy__c);
        System.assertEquals(12, assortmentDetail.WDChannelBaseNego__c);
        System.assertEquals((12/buTarget.WeightedDistributionManual__c*100).setScale(SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Scale), assortmentDetail.WDClientBaseNego__c);
    }*/

    // case update BusinessUnitCluster__c
    /*static testmethod void case26_Update_Ass_BU_Cluster_Cplt_Success() {
        init();
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, StartDate__c = Date.today(),
                                                                         BusinessUnitCluster__c = null, ProductLifeStatusAss__c = NULL);
        insert assortmentDetail;
        // update Client_Clust__c
        assortmentDetail.ProductLifeStatusAss__c = 'Complement';
        //assortmentDetail.Client_Clust_Cplt2__c = true;
        //assortmentDetail.Client_Clust_Cplt1__c = true;
        update assortmentDetail;
        Test.stopTest();
        // Assertion.
        assortmentDetail = [SELECT BusinessUnitCluster__r.RecordType.DeveloperName FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals('Assortment_Cluster_List', assortmentDetail.BusinessUnitCluster__r.RecordType.DeveloperName);
    }*/

    // case update Client_ClustX__c to Client_Clust_CpltX__c
    /*static testmethod void case27_Update_ClientCluster_Strat_ToCplt_Success() {
        init();
        Test.startTest();
        //Client_Clust3__c = true,
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, StartDate__c = Date.today(),
                                                                          BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New');
        insert assortmentDetail;
        //, Client_Clust_Cplt1__c, Client_Clust_Cplt2__c, Client_Clust_Cplt3__c,
        //  Client_Clust_Cplt4__c, Client_Clust_Cplt5__c, Client_Clust_Cplt6__c
        assortmentDetail = [SELECT BusinessUnitCluster__c, WDChannelBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals(clusters[2].Id, assortmentDetail.BusinessUnitCluster__c);
        System.assertEquals(15+12+9+6, assortmentDetail.WDChannelBaseNego__c);
        //for (Integer i = 1; i <= 6; i++) {
            //System.assertEquals(false, assortmentDetail.get('Client_Clust_Cplt' + i + '__c'));
        //}
        // update Client_Clust__c
        assortmentDetail.ProductLifeStatusAss__c = 'Complement';
        //assortmentDetail.Client_Clust_Cplt2__c = true;
        //assortmentDetail.Client_Clust3__c = false;
        update assortmentDetail;
        Test.stopTest();
        // Assertion.
        // , Client_Clust1__c, Client_Clust2__c, Client_Clust3__c,
        //  Client_Clust4__c, Client_Clust5__c, Client_Clust6__c 
        assortmentDetail = [SELECT BusinessUnitCluster__c, WDChannelBaseNego__c, WDClientBaseNego__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals(cpltClusters[1].Id, assortmentDetail.BusinessUnitCluster__c);
        System.assertEquals(18, assortmentDetail.WDChannelBaseNego__c);
        System.assertEquals(18/buTarget.Weighted_Distribution_Manual__c*100, assortmentDetail.WDClientBaseNego__c);
        //for (Integer i = 1; i <= 6; i++) {
        //    System.assertEquals(false, assortmentDetail.get('Client_Clust' + i + '__c'));
        //}
    }*/

    static testmethod void case28_SwitchExistingProductInAssortment_Success() {
        init();
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        AssortmentDetail__c assortmentDetail2 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = p1.Id, Hierarchy__c = product.Hierarchy__c,
                                                                                            BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = 'Validate', Version__c = null);
        //,Client_Clust1__c = true
        AssortmentDetail__c assortmentDetail1 = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = product.Hierarchy__c,
                                                                                            BusinessUnitCluster__c = null, ProductLifeStatusAss__c = 'New', Status__c = null, Version__c = null);
        insert new List<AssortmentDetail__c> {assortmentDetail1, assortmentDetail2};
        Test.startTest();
        // switch assortment
        assortmentDetail2.Product__c = product.Id;
        Database.SaveResult result = Database.update(assortmentDetail2,false);
        assortmentDetail1 = [SELECT Id, ProductLifeStatusAss__c, Status__c, Version__c, AssortmentDetailLHistory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail1.Id];
        System.assertEquals('Validate', assortmentDetail1.Status__c);
        System.assertEquals(null, assortmentDetail1.Version__c);
        System.assertEquals(assortmentDetail2.Id, assortmentDetail1.AssortmentDetailLHistory__c);
        assortmentDetail2 = [SELECT Id, ProductLifeStatusAss__c, Status__c, Version__c, AssortmentDetailLHistory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail2.Id];
        Test.stopTest();
        System.assertEquals('PreviouslyValidate', assortmentDetail2.Status__c);
        System.assertEquals('Substitute', assortmentDetail2.ProductLifeStatusAss__c);
        System.assertEquals(2, assortmentDetail2.Version__c);
    }

    // case update Weekly Sales
    static testmethod void case29_updateWeeklySales_Success() {
        init();
        Test.startTest();
        buSource.Format__c = CommonConstants.HMSM;
        update buSource;
        product.Average_Weekly_Sales_Hyper__c = 100;
        update product;
        AssortmentDetail__c assortmentDetail = TestDataFactory.createAssortmentDetail2(false, assortmentBU.Id, product, null);
        assortmentDetail.Hierarchy__c = null;
        assortmentDetail.BusinessUnitCluster__c = clusters[1].Id;
        assortmentDetail.ProductLifeStatusAss__c = 'New';
        insert assortmentDetail;
        Test.stopTest();
        // Assertion.
        assortmentDetail = [SELECT StartDate__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id];
        //System.assertEquals(product.Average_Weekly_Sales_Hyper__c, assortmentDetail.StartDate__c);
    }

    // static testmethod void case30_AVG_Test_Without_AVG_InProduct() {
    //     init();
    //     AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id);
    //     Test.startTest();
    //     insert assD;
    //     Test.stopTest();
    //     assD = [SELECT Id, StartDate__c,AvgWeeklySalesClient__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
    //     System.assertEquals(null, assD.StartDate__c);
    // }

    static testmethod void case31_AVG_Test_With_AVG_Super_InProduct() {
        init();
        product.Average_Weekly_Sales_Super__c = 100;
        //Supermarket nd Hypermarket are disabled so we used HMSM instead, so we need to fill Average_Weekly_Sales_Hyper__c
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        product.Average_Weekly_Sales_Hyper__c = 100;
        update product;
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id);
        Test.startTest();
        insert assD;
        Test.stopTest();
        assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(product.Average_Weekly_Sales_Super__c, assD.AvgWeeklySalesChannel__c);
    }

    static testmethod void case32_AVG_Test_With_AVG_Super_Hyper_InProduct(){
        init();
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        product.Average_Weekly_Sales_Super__c = 8;
        product.Average_Weekly_Sales_Hyper__c = 8;
        update product;
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,Product__c = product.Id);
        Test.startTest();
        insert assD;
        Test.stopTest();
        assD = [SELECT Id, AvgWeeklySalesChannel__c,AvgWeeklySalesClient__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(product.Average_Weekly_Sales_Super__c, assD.AvgWeeklySalesChannel__c);
    }

    // SP CCEP / COCA
    /*static testmethod void case33_AVG_Test_With_Changing_Product(){
        init();
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        product.Average_Weekly_Sales_Super__c = 5;
        product.Average_Weekly_Sales_Hyper__c = 5;
        update product;
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,Product__c = product.Id);
        Test.startTest();
        insert assD;
        assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c, Product__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
       System.assertEquals(5, assD.AvgWeeklySalesChannel__c);
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        p1.Average_Weekly_Sales_Super__c = 9;
        p1.Average_Weekly_Sales_Hyper__c = 9;
        insert p1;
        assD.Product__c = p1.Id;
        update assD;
        Test.stopTest();
		assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c, Product__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(9, assD.AvgWeeklySalesChannel__c);
    }*/

    static testmethod void case34_AVG_Test_With_UpdatingAVG_InProduct() {
        init();
        Test.startTest();
        product.Average_Weekly_Sales_Super__c = 5;
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        product.Average_Weekly_Sales_Hyper__c = 5;
        System.debug('Update Product 1');
        update product;
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id);
        insert assD;
        assD = [SELECT Id, AvgWeeklySalesChannel__c, AvgWeeklySalesClient__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        System.assertEquals(product.Average_Weekly_Sales_Super__c, assD.AvgWeeklySalesChannel__c);
        product.Average_Weekly_Sales_Super__c = 6;
        //Trg_Assortment_Detail_Handler => LINE-1845 => HMSM will take the Average_Weekly_Sales_Hyper__c
        product.Average_Weekly_Sales_Hyper__c = 6;
        update product;
        //assD = [SELECT Id, Avg_Weekly_Sales_Ext_MarketBased__c,Avg_Weekly_Sales_Ext_ClientBased__c,year__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        //System.assertEquals(product.Average_Weekly_Sales_Super__c, assD.Avg_Weekly_Sales_Ext_MarketBased__c);
         //check if the assortment is from this year or next
        /*if((assD.Year__c - System.today().year() == 0) ||(assD.Year__c - System.today().year() == 1)  ) {
            System.assert(true);
        } else {
            System.assert(false);
        }*/
        Test.stopTest();
    }

    // test New_Client_Quantity_YE__c calculations in assortment services
    // case assortment detail has a ref parent and does not have a history
    static testmethod void case35_NewClientQuantityYE_ref_no_histo(){
        init();
        Integer year = Date.today().year();
        // create ref assortment on previous year
        Assortment__c refAssortmentBU = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        refAssortmentBU.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        refAssortmentBU.BDate__c = Date.newInstance(year - 1, 1, 1);
        refAssortmentBU.EDate__c = Date.newInstance(year - 1, 12, 31);
        refAssortmentBU.Year__c = year - 1;
        insert refAssortmentBU;
        // create product
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        // create Ref Assortment Detail
        AssortmentDetail__c refAssD = new AssortmentDetail__c(Assortment__c = refAssortmentBU.Id,
                                                                Product__c = p1.Id,
                                                                StartDate__c = Date.newInstance(year - 1, 1, 1),
                                                                BusinessUnitCluster__c = clusters[2].Id, ProductLifeStatusAss__c = 'New',
                                                                Status__c = 'Validate'); // New_Client_ProductNumber__c = 175 + 140 + 105 + 70 = 490
        // create Assortment Detail
        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                             Product__c = product.Id,
                                                             StartDate__c = Date.newInstance(year, 1, 1),
                                                             BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'Keep'); // New_Client_ProductNumber__c = 210 + 180 + 150 + 120 + 90 + 60 = 810

        assD.AvgWeeklySalesClient__c = 12.5;
        //start test
        Test.startTest();
        insert refAssD;
        assD.AssortmentDetailNegotiationRef__c = refAssD.Id;
        insert assD;
        Test.stopTest();
        // fetch data
        //assD = [SELECT Id, New_Client_Quantity_YE__c FROM AssortmentDetail__c WHERE Id = :assD.Id];
        Integer remainingWeeks = 52;
        double expectedValue = 12.5 * (810 - 490) * remainingWeeks;
        //System.assertEquals(expectedValue, assD.New_Client_Quantity_YE__c);
    }

    // test New_Client_Quantity_YE__c calculations in assortment services
    // case assortment detail has a history
    static testmethod void case36_NewClientQuantityYE_histo(){
        init();
        Integer year = Date.today().year();
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        AssortmentDetail__c histoDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                                    Product__c = p1.Id,
                                                                    StartDate__c = Date.newInstance(year, 1, 1),
                                                                    BusinessUnitCluster__c = clusters[2].Id, ProductLifeStatusAss__c = 'New',
                                                                    Status__c = 'Validate'); // New_Client_ProductNumber__c = 150 + 120 + 90 + 60 = 420

        AssortmentDetail__c assD = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                             Product__c = product.Id,
                                                             StartDate__c = Date.newInstance(year, 1, 1),
                                                             BusinessUnitCluster__c = clusters[0].Id, ProductLifeStatusAss__c = 'New'); // New_Client_ProductNumber__c = 210 + 180 + 150 + 120 + 90 + 60 = 810
        assD.AvgWeeklySalesClient__c = 12.5;

        Test.startTest();
        insert histoDetail;
        assD.AssortmentDetailLHistory__c = histoDetail.Id;
        insert assD;
        Test.stopTest();
        // fetch data
        //assD = [SELECT Id, New_Client_Quantity_YE__c FROM AssortmentDetail__c WHERE Id = :assD.Id];

        Integer remainingWeeks = 56;
        double expectedValue = 12.5 * (810 - 420) * remainingWeeks;
        //System.assertEquals(expectedValue, assD.New_Client_Quantity_YE__c);
    }
    /*static testmethod void case37_InsertAssortmentDetail_updateCategory() {
        init();
        Supplier_PG_Mapping__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section2.Id);
        pg.Product__c = product.Id;
        pg.BU__c = buTarget.Id;
        insert pg;
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         Hierarchy__c = null);
        insert assortmentDetail;
        Test.stopTest();
        // Assertion.
        assortmentDetail = [SELECT Hierarchy__c, Client_Category__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        System.assertEquals(product.Hierarchy__c, assortmentDetail.Hierarchy__c);
        System.assertEquals(pg.Section__c, assortmentDetail.Client_Category__c);
    }*/
    static testmethod void case38_updateTargetDetailFromNego() {
        init();
        Assortment__c targetAssortmentBU = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        targetAssortmentBU.Status__c = 'Validate';
        targetAssortmentBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment__c.SObjectType, 'Target');
        targetAssortmentBU.BDate__c = Date.newInstance(System.today().year() + 1, 1, 1);
        targetAssortmentBU.EDate__c = Date.newInstance(System.today().year() + 1, 12, 31);
        targetAssortmentBU.Year__c = System.today().year() + 1;
        insert targetAssortmentBU;
        AssortmentDetail__c targetAssortmentDetail = new AssortmentDetail__c(Assortment__c = targetAssortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                               BusinessUnitCluster__c = clusters[1].Id, ProductLifeStatusAss__c = 'New');
        insert targetAssortmentDetail;
        Test.startTest();
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id, Product__c = product.Id, Hierarchy__c = null,
                                                                         BusinessUnitCluster__c = clusters[1].Id, ProductLifeStatusAss__c = 'New', Status__c = 'Validate');
        insert assortmentDetail;
        Test.stopTest();
        targetAssortmentDetail = [SELECT Id, AssortmentDetailNegotiationRef__c FROM AssortmentDetail__c WHERE Id = :targetAssortmentDetail.Id];
        System.assertEquals(assortmentDetail.Id, targetAssortmentDetail.AssortmentDetailNegotiationRef__c);
    }
    
    static testmethod void case39_GenerateHLPProduct() {
        init();
        // Create Product.
        Product2 hlpProduct = TestDataFactory.createProduct(false, section.Id, null);
        hlpProduct.UV__c = 'KG';
        hlpProduct.Weight__c = 0.5;
        hlpProduct.RecordTypeId = TestDataFactory.productRTIds.get('Higher_Level_Packaging');
        hlpProduct.Consumer_Trade_Item__c = product.Id;
        insert hlpProduct;
        Test.startTest();
        Id regularAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'Regular');
        Id hlpAssortmentDetailRecordType = NegoptimHelper.getObjectRecordTypeId(AssortmentDetail__c.sObjectType,'HigherLevelPackaging');
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBU.Id,
                                                                                           Product__c = product.Id,
                                                                                           Hierarchy__c = null,
                                                                                           RecordTypeId = regularAssortmentDetailRecordType);
        insert assortmentDetail;
        Test.stopTest();
        AssortmentDetail__c hlpAssortmentDetail = [SELECT Id, RecordType.DeveloperName FROM AssortmentDetail__c WHERE Product__c = :hlpProduct.Id];
        System.assertEquals('HigherLevelPackaging', hlpAssortmentDetail.RecordType.DeveloperName);
    }
}