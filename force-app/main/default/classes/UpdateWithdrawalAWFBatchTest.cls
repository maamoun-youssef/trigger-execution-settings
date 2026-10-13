@isTest
public class UpdateWithdrawalAWFBatchTest {
 private static Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    private static Integer year;
    private static BusinessUnit__c country;
    private static BusinessUnit__c groupBU;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static CommercialPlan__c commercialPlan;
    private static CommercialPlanDetail__c commercialPlanDetail;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static Hierarchy__c department1;
    private static Hierarchy__c section1;
    private static Assortment_PriceWaterFall__c awf;
    private static Assortment_BU__c assortmentBu;
    private static Product2 product1;
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
            // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Insert contract.
            contract = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            insert tariffCondition;
            // Insert condition
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            condition.Value_per__c = 5;
            condition.Value_amt__c = null;
            condition.Base_TO_Nego__c = 1000;
            condition.Base_TO_Tariff_Nego__c = 1000;
            condition.Rank__c = 1;
            insert condition;
            // Create Departments & Sections.
            department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            // Insert CommercialPlan.
            commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            commercialPlan.Name = 'Marketing Media001';
            commercialPlan.Supplier__c = supplier.Id;
            insert commercialPlan;
            country.SetAssortmentNegoBUSource__c= true;
            country.IsMasterBU__c = true;
            update country;
            assortmentBu = TestDataFactory.createAssortmentBU(true, country, groupBU, department1);
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.recordTypeId = productRTIds.get('Product');
            insert product1;
            PG__c supplierPG = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
            supplierPG.Product__c = product1.Id;
            insert supplierPG;
            TestDataFactory.createNSPG(true, NS, supplierPG.Id);
            commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id);
            commercialPlanDetail.Status__c = 'Validated';
            commercialPlanDetail.Product__c = product1.Id;
            insert commercialPlanDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest
    static void case_deleteAWF() {
        init();
        Test.startTest();
        awf = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBu.Id, product1.Id, commercialPlan.Id, commercialPlanDetail.Id);
        awf.Status__c = 'In preparation';
        awf.ScheduledForWithdrawal__c = true;
        insert awf;
        UpdateWithdrawalAWFBatchScheduler updateWithdrawalAWFBatchScheduler = new UpdateWithdrawalAWFBatchScheduler();
        UpdateWithdrawalAWFBatchScheduler.run(null);
        Database.executeBatch(new UpdateWithdrawalAWFBatch(UpdateWithdrawalAWFBatchTest.class.getName(), null, null, null, null), 100);
        Test.stopTest();
        List<Assortment_PriceWaterFall__c> awfList = [SELECT Id, ScheduledForWithdrawal__c, Status__c
                                                      FROM Assortment_PriceWaterFall__c
                                                      WHERE ScheduledForWithdrawal__c = TRUE
                                                      AND Status__c <> 'Archived'];
        System.assertEquals(0, awfList.size());
    }
    
    @isTest
    static void case_updateAWF() {
        init();
        Test.startTest();
        awf = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBu.Id, product1.Id, commercialPlan.Id, commercialPlanDetail.Id);
        awf.Status__c = 'Validated';
        awf.ScheduledForWithdrawal__c = true;
        insert awf;
        UpdateWithdrawalAWFBatchScheduler updateWithdrawalAWFBatchScheduler = new UpdateWithdrawalAWFBatchScheduler();
        UpdateWithdrawalAWFBatchScheduler.run(null);
        Database.executeBatch(new UpdateWithdrawalAWFBatch(UpdateWithdrawalAWFBatchTest.class.getName(),  null, null, null, null), 100);
        Test.stopTest();
        awf = [SELECT Id, WithdrawalDate__c, Status__c, ScheduledForWithdrawal__c
               FROM Assortment_PriceWaterFall__c
               WHERE Id = :awf.Id];
        Integer y = System.now().year();
        Integer mo = System.now().month();
        Integer d = System.now().day();
        Integer h = System.now().hour();
        Integer mi = System.now().minute();
        DateTime dt = DateTime.valueOf(y + '-' + mo + '-' + d + ' ' + h + ':' + mi + ':00');
        
        Integer y1 = awf.WithdrawalDate__c.year();
        Integer mo1 = awf.WithdrawalDate__c.month();
        Integer d1 = awf.WithdrawalDate__c.day();
        Integer h1 = awf.WithdrawalDate__c.hour();
        Integer mi1 = awf.WithdrawalDate__c.minute();
        DateTime dt1 = DateTime.valueOf(y1 + '-' + mo1 + '-' + d1 + ' ' + h1 + ':' + mi1 + ':00');
        //System.assertEquals(dt, dt1);
        System.assertEquals('Archived', awf.Status__c);
        System.assertEquals(false, awf.ScheduledForWithdrawal__c);
    }
}