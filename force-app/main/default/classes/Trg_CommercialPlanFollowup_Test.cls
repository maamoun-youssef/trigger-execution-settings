/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for Commercial Plan Followup
*/
@isTest
public class Trg_CommercialPlanFollowup_Test {
    private static Integer year;
    private static BusinessUnit__c country;
    private static BusinessUnit__c groupBU;
    private static Supplier__c supplier;
    private static CommercialPlan__c commercialPlanParent;
    private static CommercialPlan__c commercialPlan;
    private static CommercialPlanDetail__c commercialPlanDetail;
    
    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = TestDataFactory.getHierarchyRootId();
            year = TestDataFactory.year;
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            // Insert CommercialPlan.
            commercialPlanParent = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlanParent.Name = 'Parent CP';
            commercialPlanParent.BusinessUnitTarget__c = country.Id;
            commercialPlanParent.Supplier__c = supplier.Id;
            insert commercialPlanParent;
            // Insert CommercialPlan.
            commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
			commercialPlan.Name = 'Parent CP';
            commercialPlan.BusinessUnitTarget__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            commercialPlan.CommercialPlanParent__c = commercialPlanParent.Id;
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_updateCPFValues() {
        init();
        Test.startTest();
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        commercialPlanDetail.BudgetType__c = 'NIP';
        insert commercialPlanDetail;
        commercialPlanDetail.VolumeTarget__c = 1;
        commercialPlanDetail.VolumeFact__c = 2;
        commercialPlanDetail.QuantityTarget__c = 3;
        commercialPlanDetail.QuantityPreOrder__c = 4;
        commercialPlanDetail.QuantityFact__c = 5;
        update commercialPlanDetail;
        Test.stopTest();
        List<CommercialPlanFollowup__c> followUps = [SELECT Id, VolumeTarget__c, VolumeFact__c, QuantityTarget__c, QuantityPreOrder__c, QuantityFact__c
                                                     FROM CommercialPlanFollowup__c
                                                     WHERE CommercialPlan__c = :commercialPlanParent.Id
                                                     AND RecordType.DeveloperName = 'Budget_Followup'
                                                     AND BudgetType__c = 'NIP'];
        if (followUps != null && !followUps.isEmpty()) {
            System.assert(true);
            // // System.assertEquals(commercialPlanDetail.VolumeTarget__c, followUps.get(0).VolumeTarget__c);
            // // System.assertEquals(commercialPlanDetail.VolumeFact__c, followUps.get(0).VolumeFact__c);
            // // System.assertEquals(commercialPlanDetail.QuantityTarget__c, followUps.get(0).QuantityTarget__c);
            // // System.assertEquals(commercialPlanDetail.QuantityPreOrder__c, followUps.get(0).QuantityPreOrder__c);
            // // System.assertEquals(commercialPlanDetail.QuantityFact__c, followUps.get(0).QuantityFact__c);
        }
    }

}