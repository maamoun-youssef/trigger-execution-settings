@isTest
private class CPDAggregatorTest {
    @isTest
    static void testAggregateToParentCPs() {
        Supplier__c supplier = new Supplier__c(
            Name = 'Test Supplier',
            Code__c = 'SUPP-001' // ✅ REQUIRED
        );
        insert supplier;

        CommercialPlan__c parentCP = new CommercialPlan__c(
            Name = 'Parent CP',
            Supplier__c = supplier.Id,
            SellInBDate__c = Date.today(),
            SellInEDate__c = Date.today().addDays(30)
        );
        insert parentCP;

        CommercialPlan__c childCP = new CommercialPlan__c(
            Name = 'Child CP',
            CommercialPlanParent__c = parentCP.Id,
            Supplier__c = supplier.Id,
            SellInBDate__c = Date.today(),
            SellInEDate__c = Date.today().addDays(20)
        );
        insert childCP;

        CommercialPlanDetail__c cpd = new CommercialPlanDetail__c(
            Name = 'Child CPD',
            CommercialPlan__c = childCP.Id,
            CommercialPlanSellIn__c = 'GroupA',
            CommercialPlanSellOut__c = 'GroupB',
            CommercialPlanServices__c = 'GroupC'
        );
        insert cpd;

        Test.startTest();
        cpd.Name = 'Updated CPD';
        update cpd;
        Test.stopTest();

        System.assertEquals('Parent CP', [
            SELECT Name FROM CommercialPlan__c WHERE Id = :parentCP.Id
        ].Name);
    }
}