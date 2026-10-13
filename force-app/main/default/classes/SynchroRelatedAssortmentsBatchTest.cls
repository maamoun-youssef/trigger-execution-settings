/**
 * @author ULiT
 * @date 20/08/2026
 * @description Unit test for ExecuteBatchInvocable and SynchroRelatedAssortmentsBatch
 */
@isTest
private class SynchroRelatedAssortmentsBatchTest {
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static List<Product2> products;
    static void init() {
        Id rootId = NegoptimHelper.getRootIdByRT('Product');
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.IsMasterBU__c = true;
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        insert new List<BusinessUnit__c>{buSource, buTarget};
        department = TestDataFactory.createHierarchyDepartment(true, rootId);
        section = TestDataFactory.createHierarchySection(true, department.Id);
        products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
    }
    @isTest
    static void executeInvocable_ShouldSynchronizeRelatedAssortment() {
        init();
        Assortment__c parentAssortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        parentAssortment.Status__c = 'Validate';
        insert parentAssortment;
        Assortment__c childAssortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        childAssortment.Status__c = 'Validate';
        childAssortment.AssortmentNegotiationRef__c = parentAssortment.Id;
        insert childAssortment;
        String parentCluster = '{"Cplt":[],"Strat":[{"value":true,"index":0,"Id":"S1"}]}';
        String childCluster = '{"Cplt":[],"Strat":[{"value":true,"index":0,"Id":"S1"},{"value":true,"index":1,"Id":"S2"}]}';
        AssortmentDetail__c parentASD = TestDataFactory.createAssortmentDetail(false, parentAssortment.Id, products[0], buSource.Id);
        parentASD.ProductCluster__c = parentCluster;
        parentASD.ProductLifeStatusAss__c = 'Keep';
        parentASD.BusinessUnitCluster__c = buSource.Id;
        parentASD.NDChannelBaseNegoL4L__c = 10;
        parentASD.NDClientBaseNegoL4L__c = 30;
        parentASD.PNClientBaseNegoL4L__c = 0.50;
        parentASD.SOSNumberNegoL4L__c = 50;
        parentASD.WDChannelBaseNegoL4L__c = 60;
        parentASD.WDClientBaseNegoL4L__c = 80;
        parentASD.SOSNumberNego__c = 77;
        parentASD.Status__c = 'Validate';
        insert parentASD;
        AssortmentDetail__c childASD = TestDataFactory.createAssortmentDetail(false, childAssortment.Id, products[0], null);
        childASD.ProductCluster__c = childCluster;
        childASD.ProductLifeStatusAss__c = 'Keep';
        childASD.AssortmentDetailNegotiationRef__c = parentASD.Id;
        childASD.Version__c = null;
        insert childASD;
        childASD = new AssortmentDetail__c(Id = childASD.Id, 
                                            BusinessUnitCluster_P1__c = null, 
                                            ProductClusterASDNego__c = null, 
                                            ProductLifeStatusAss__c = 'Keep', 
                                            NDChannelBaseNegoL4L_P1__c = 0, 
                                            NDClientBaseNegoL4L_P1__c = 0, 
                                            PNClientBaseNegoL4L_P1__c = 0, 
                                            SOSNumberNegoL4L_P1__c = 0, 
                                            WDChannelBaseNegoL4L_P1__c = 0, 
                                            WDClientBaseNegoL4L_P1__c = 0, 
                                            SOSNumberNego_P1__c = 0);
        update childASD;
        parentASD = [SELECT Id, BusinessUnitCluster__c, ProductCluster__c, NDChannelBaseNegoL4L__c, 
                     NDChannelBasePanel__c, NDClientBaseNegoL4L__c, NDClientBasePanel__c, PNClientBaseNegoL4L__c, 
                     SOSNumberNegoL4L__c, WDChannelBaseNegoL4L__c, WDChannelBasePanel__c, WDClientBaseNegoL4L__c, WDClientBasePanel__c, SOSNumberNego__c
                     FROM AssortmentDetail__c 
                     WHERE Id = :parentASD.Id];
        ExecuteBatchInvocable.BatchParametersWrapper wrapper = new ExecuteBatchInvocable.BatchParametersWrapper();
        wrapper.batchName = 'SynchroRelatedAssortmentsBatch';
        wrapper.assortmentIds = new List<Id>{childAssortment.Id};
        Test.startTest();
        ExecuteBatchInvocable.execute(new List<ExecuteBatchInvocable.BatchParametersWrapper>{wrapper});
        Test.stopTest();
        childASD = [SELECT Id, ProductLifeStatusAss__c, BusinessUnitCluster_P1__c, ProductClusterASDNego__c, 
                    NDChannelBaseNegoL4L_P1__c, NDClientBaseNegoL4L_P1__c, PNClientBaseNegoL4L_P1__c, 
                    SOSNumberNegoL4L_P1__c, WDChannelBaseNegoL4L_P1__c, WDClientBaseNegoL4L_P1__c, SOSNumberNego_P1__c
                    FROM AssortmentDetail__c 
                    WHERE Id = :childASD.Id];
        System.assertEquals('Increase', childASD.ProductLifeStatusAss__c);
        System.assertEquals(parentASD.BusinessUnitCluster__c, childASD.BusinessUnitCluster_P1__c);
        System.assertEquals(parentASD.ProductCluster__c, childASD.ProductClusterASDNego__c);
        System.assertEquals(parentASD.NDChannelBaseNegoL4L__c, childASD.NDChannelBaseNegoL4L_P1__c);
        System.assertEquals(parentASD.NDClientBaseNegoL4L__c, childASD.NDClientBaseNegoL4L_P1__c);
        System.assertEquals(parentASD.PNClientBaseNegoL4L__c, childASD.PNClientBaseNegoL4L_P1__c);
        System.assertEquals(parentASD.SOSNumberNegoL4L__c, childASD.SOSNumberNegoL4L_P1__c);
        System.assertEquals(parentASD.WDChannelBaseNegoL4L__c, childASD.WDChannelBaseNegoL4L_P1__c);
        System.assertEquals(parentASD.WDClientBaseNegoL4L__c, childASD.WDClientBaseNegoL4L_P1__c);
        System.assertEquals(parentASD.SOSNumberNego__c, childASD.SOSNumberNego_P1__c);
    }
}