/**
 * @author ULiT
 * @description Unit test for CPFReportController
 */ 
@isTest
private class CPFReportControllerTest {

    private static Integer year = TestDataFactory.year;
    private static CommercialPlan__c commercialPlanParent;
    private static CommercialPlan__c childCommercialPlan1;
    private static CommercialPlan__c childCommercialPlan2;
    private static Supplier__c supplier;
    private static BusinessUnit__c country;
    private static BusinessUnit__c region;
    private static Product2 product;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    
    static void init() {
        try {
            Id rootId = TestDataFactory.getHierarchyRootId();
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            supplier = TestDataFactory.createSupplier(true, country, false);
            country.Supplier__c = supplier.Id;
            country.Status__c = 'Open';
            country.Supplier__c = supplier.Id;
            update country;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            commercialPlanParent = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlanParent.Name = 'Parent CP';
            commercialPlanParent.Hierarchy__c = department.Id;
            commercialPlanParent.BusinessUnitTarget__c = country.Id;
            commercialPlanParent.Supplier__c = supplier.Id;
            insert commercialPlanParent;
            childCommercialPlan1 = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
			childCommercialPlan1.Name = 'Child CP1';
            childCommercialPlan1.Hierarchy__c = department.Id;
            childCommercialPlan1.BusinessUnitTarget__c = country.Id;
            childCommercialPlan1.Supplier__c = supplier.Id;
            childCommercialPlan1.CommercialPlanParent__c = commercialPlanParent.Id;
            childCommercialPlan2 = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
			childCommercialPlan2.Name = 'Child CP2';
            childCommercialPlan2.Hierarchy__c = department.Id;
            childCommercialPlan2.BusinessUnitTarget__c = country.Id;
            childCommercialPlan2.Supplier__c = supplier.Id;
            childCommercialPlan2.CommercialPlanParent__c = commercialPlanParent.Id;
            insert new List<CommercialPlan__c> {childCommercialPlan1, childCommercialPlan2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testMethod void case1_init_search_save_delete() {
        init();
        Test.startTest();
        CPFReportController.FilterParameter filterData = new CPFReportController.FilterParameter(department.Id, commercialPlanParent.Status__c, country.Id, supplier.Id);
        String mainWrapper_JSON  = CPFReportController.loadData(commercialPlanParent.Id, JSON.serialize(filterData));
        List<CommercialPlanFollowup__c> followUps = [SELECT Id, VolumeTarget__c, VolumeFact__c, QuantityTarget__c, QuantityPreOrder__c, QuantityFact__c
                                                     FROM CommercialPlanFollowup__c
                                                     WHERE CommercialPlan__c = :childCommercialPlan1.Id
                                                     AND RecordType.DeveloperName = 'Budget_Followup' LIMIT 1];
        if (followUps != null && !followUps.isEmpty()) {
            followUps[0].VolumeTarget__c = 10;
            CPFReportController.saveCPF(JSON.serialize(followUps));
        }
        List<Id> cpIdToDelete = new List<Id>{childCommercialPlan1.Id};
        CPFReportController.deleteCP(JSON.serialize(cpIdToDelete));
        Test.stopTest();
        system.assert(true);
    }
}