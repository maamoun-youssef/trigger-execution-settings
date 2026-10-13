/**
* This class contains unit tests for validating the behavior of ConsolidatePromoAgreementsBatch
*/
@isTest
public class ConsolidatePromoAgreementsBatchTest {
    private static Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    private static Map<String, Id> commercialPlanRTIds = NegoptimHelper.getObjectRecordTypeMapIds(CommercialPlan__c.SObjectType);
    private static Integer year;
    private static BusinessUnit__c country;
    private static BusinessUnit__c groupBU;
    private static Supplier__c supplier;
    private static Hierarchy__c section1;
    private static Product2 product1;
    private static CommercialPlan__c commercialPlan;
    
    static void init() {
        try {
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getHierarchyRootId('Product');
            year = TestDataFactory.year;
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Insert Region.
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert group BU.
            groupBU = TestDataFactory.createBusinessUnitGroup(false, 'EMC');
            groupBU.BusinessUnitRegion__c = region.Id;
            insert groupBU;
            // Insert Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            // Create Departments & Sections.
            Hierarchy__c department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.recordTypeId = productRTIds.get('Product');
            insert product1;
            // Insert CommercialPlan.
            commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlan.Name = 'Marketing Media001';
            commercialPlan.RecordTypeId = commercialPlanRTIds.get('CommercialEvent');
            commercialPlan.BusinessUnitTarget__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void case1_consolidatePromoAgreements() {
        init();
        // Insert CommercialPlan__c
        CommercialPlan__c cpSellin = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellin.Supplier__c = supplier.Id;
        cpSellin.BusinessUnitTarget__c = country.Id;
        cpSellin.CommercialPlanParent__c = commercialPlan.Id;
        cpSellin.PromoAgreementType__c = 'CallOffAgreementSellIn';
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = country.Id;
        cpSellOut.CommercialPlanParent__c = commercialPlan.Id;
        cpSellOut.PromoAgreementType__c = 'CallOffAgreementSellOut';
        CommercialPlan__c cpServices = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpServices.Supplier__c = supplier.Id;
        cpServices.BusinessUnitTarget__c = country.Id;
        cpServices.CommercialPlanParent__c = commercialPlan.Id;
        cpServices.PromoAgreementType__c = 'AgencyAgreement';
        insert new List<CommercialPlan__c> { cpSellin, cpSellOut, cpServices};        
        // Insert CommercialPlanDetail__c
        CommercialPlanDetail__c cpd = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
        cpd.Supplier__c = supplier.Id;
        cpd.BusinessUnitTarget__c = country.Id;
        cpd.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpd.Product__c = product1.Id;
        cpd.SellOutDiscountValue__c = 100;
        cpd.ServicesDiscountUAmt__c = 100;
        cpd.CommercialPlanSellIn__c = cpSellin.Id;
        cpd.CommercialPlanSellOut__c = cpSellOut.Id;
        cpd.CommercialPlanServices__c = cpServices.Id;
        cpd.VolumeTarget__c = 10;
        cpd.SellInDiscountUAmtNego__c = 10;
        cpd.SellOutDiscountQtyTarget__c = 10;
        cpd.SellOutDiscountQtyFact__c = 10;
        cpd.SellOutDiscountUAmt__c = 10;
        cpd.SellOutSourceContribPerc__c = 10;
        cpd.SellOutQtyTarget__c = 10;
        cpd.ServicesDiscountFixedAmt__c = 10;
        cpd.SellInDiscountMassValueFact__c = 10;
        insert cpd;
        cpSellin.SellInDiscountMassValueFact__c = 20;
        update cpSellin;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => ConsolidatePromoAgreementsBatchTest.class.getName(),
            'commercialPlanSellInIds' => new Set<Id>{cpSellin.Id},
            'commercialPlanSellOutIds' => null,
            'commercialPlanServicesIds' => null
        };
        NegoptimBatch.executeBatch('ConsolidatePromoAgreementsBatch', paramsMap, 20);
        Test.stopTest();
        cpSellin = [SELECT Id, SellInDiscountMassValueFact__c, CommercialPlanParent__r.recordtype.developerName FROM CommercialPlan__c WHERE Id = :cpSellin.Id];
        System.assertEquals(10, cpSellin.SellInDiscountMassValueFact__c);
    }
}