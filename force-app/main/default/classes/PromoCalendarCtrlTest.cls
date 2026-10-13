/**
 * @author ULiT
 * @date 12/11/2023
 * @description tests the functionalities of the promo calendar controller
 * includes testing of the search, filter and save functions
 */
@isTest
public class PromoCalendarCtrlTest {
    public static Integer year;
    public static BusinessUnit__c region;
    public static BusinessUnit__c buCountry;
    public static Supplier__c supplier;
    public static Product2 product1;
    public static Product2 product3;
    public static Product2 product4;
    public static CommercialPlan__c CommercialPlanParent;
    public static CommercialPlan__c commercialPlan1;
    public static CommercialPlanDetail__c commercialPlanDetail1;
    public static CommercialPlanDetail__c commercialPlanDetail2;
    public static CommercialPlanDetail__c commercialPlanDetail3;
    public static CommercialPlanDetail__c commercialPlanDetail4;
    public static Hierarchy__c department1;
    public static Hierarchy__c section1;
    public static Hierarchy__c department2;
    public static Hierarchy__c section2;
    
    static void init() {
        try {
            year = System.Today().year();
            // Get Root Element Id.
            Id rootId = TestDataFactory.getHierarchyRootId();
            // Insert Region.
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country.
            buCountry = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert supplier.
            supplier = TestDataFactory.createSupplier(true, buCountry, true);
            // Create Departments & Sections.
            department1 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section1 = TestDataFactory.createHierarchySection(true, department1.Id);
            department2 = TestDataFactory.createHierarchyDepartment(true, rootId);
            section2 = TestDataFactory.createHierarchySection(true, department2.Id);
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product1.VATRate__c = 3;
            product3 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product3.VATRate__c = 4;
            product4 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product4.VATRate__c = 1;
            insert new List<Product2>{product1, product3, product4};
            CommercialPlanParent = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            insert CommercialPlanParent;
            commercialPlan1 = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            commercialPlan1.CommercialPlanParent__c = CommercialPlanParent.Id;
            insert commercialPlan1;
            commercialPlanDetail1 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan1.Id, null);
            // commercialPlanDetail1.SPHENKELSalesExecutionRateTargCorrected__c = 2;
            commercialPlanDetail1.SellOutDiscountValue__c = 20;
            commercialPlanDetail1.QuantityTarget__c = 5000;
            // commercialPlanDetail1.Status__c  = 'Proposée';
            commercialPlanDetail1.Product__c = product1.Id;
            commercialPlanDetail1.RetailPricePromowTax__c = 40;
            commercialPlanDetail1.Name = 'CPD1';
            commercialPlanDetail1.SellOutBDate__c = Date.newInstance(year, 1, 1);
            commercialPlanDetail1.SellOutEDate__c = Date.newInstance(year, 12, 31);
            commercialPlanDetail2 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan1.Id, null);
            // commercialPlanDetail2.Status__c  = 'Facturée et close';
            commercialPlanDetail2.Name = 'CPD2';
            commercialPlanDetail2.SellOutBDate__c = Date.newInstance(year, 1, 1);
            commercialPlanDetail2.SellOutEDate__c = Date.newInstance(year, 12, 31);
            commercialPlanDetail3 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan1.Id, null);
            commercialPlanDetail3.SellOutDiscountValue__c = 40;
            commercialPlanDetail3.QuantityPreOrder__c = 600;
            // commercialPlanDetail3.Status__c  = 'Retenue';
            commercialPlanDetail3.Product__c = product3.Id;
            commercialPlanDetail3.SalesExecutionRateTarget__c = 3;
            commercialPlanDetail3.RetailPricePromowTax__c = 5; 
            commercialPlanDetail3.Name = 'CPD3';
            commercialPlanDetail3.SellOutBDate__c = Date.newInstance(year, 1, 1);
            commercialPlanDetail3.SellOutEDate__c = Date.newInstance(year, 12, 31);
            commercialPlanDetail4 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan1.Id, null);
            commercialPlanDetail4.SellOutDiscountValue__c = 60;
            commercialPlanDetail4.QuantityFact__c  = 400;
            // commercialPlanDetail4.Status__c  = 'Non envoyée';
            commercialPlanDetail4.Product__c = product4.Id;
            commercialPlanDetail4.SalesExecutionRateTarget__c = 2;
            commercialPlanDetail4.RetailPricePromowTax__c = 22; 
            commercialPlanDetail4.Name = 'CPD4';
            commercialPlanDetail4.SellOutBDate__c = Date.newInstance(year, 1, 1);
            commercialPlanDetail4.SellOutEDate__c = Date.newInstance(year, 12, 31);
            insert new List<CommercialPlanDetail__c>{commercialPlanDetail1, commercialPlanDetail2, commercialPlanDetail3, commercialPlanDetail4};
           
            } catch (Exception ex) {
               System.debug('++++++++++++++++++++++++++++++');
               System.debug(ex.getMessage());
               System.debug(ex.getStackTraceString());
               System.debug('++++++++++++++++++++++++++++++');
            }
        
    }
    
    @isTest static void Case1_Coverage() {
        init();
        PromoCalendarCtrl.FilterWrapper filter = new PromoCalendarCtrl.FilterWrapper();
        filter.fieldApiName = 'Name';
        filter.isPicklist = false;
        filter.isEncrypted = true;
        filter.isDouble = false;
        filter.isBoolean = false;
        filter.isPercent = false;
        filter.isText = true;
        filter.isReference = false;
        filter.isDate = false;
        filter.isDateTime = false;
        filter.value = 'CPD1';
        PromoCalendarCtrl.initGridSettings();
        String commercialPlanWrapperSerialized = PromoCalendarCtrl.getCommercialPlanData(1, 25, null, null, year);
        String CommercialPlanParentSerialized = PromoCalendarCtrl.getOperation(CommercialPlanParent.Id, null);
        String commericalPlanSerialized = PromoCalendarCtrl.getCPData(commercialPlan1.Id);
        String wCPDMainWrapperSerialized = PromoCalendarCtrl.getCommercialPlanDetailData(CommercialPlanParent.Id, 1, 25, JSON.serialize(new List<PromoCalendarCtrl.FilterWrapper>{filter}), null, year);
        String CPDMainWrapperSerialized = PromoCalendarCtrl.getCampaginCPDData(commercialPlan1.Id, JSON.serialize(new List<PromoCalendarCtrl.FilterWrapper>{filter}), null, year);
        String CPDcampaignMainWrapperSerialized = PromoCalendarCtrl.getOperationCPD(CommercialPlanParent.Id, commercialPlanDetail1.Id, JSON.serialize(new List<PromoCalendarCtrl.FilterWrapper>{filter}), null, year);
        String specificCPDSerialized = PromoCalendarCtrl.getSpecificCPD(commercialPlanDetail4.Id);
        String filteredOperationSerializedTest1 = PromoCalendarCtrl.getFilteredOperation(25, 1, JSON.serialize(new List<PromoCalendarCtrl.FilterWrapper>{filter}), null, null, year);
        String filteredOperationSerializedTest2 = PromoCalendarCtrl.getFilteredOperation(25, 1, JSON.serialize(new List<PromoCalendarCtrl.FilterWrapper>{filter}), commercialPlan1.Id, null, year);
        System.assertEquals(1, ((PromoCalendarCtrl.filteredMainWrapper)JSON.deserialize(filteredOperationSerializedTest1, PromoCalendarCtrl.filteredMainWrapper.class)).CPDMainWrapper.commercialDetailList.size());
        System.assertEquals(1, ((PromoCalendarCtrl.filteredMainWrapper)JSON.deserialize(filteredOperationSerializedTest2, PromoCalendarCtrl.filteredMainWrapper.class)).CPDMainWrapper.commercialDetailList.size());
        System.assertEquals(1, ((PromoCalendarCtrl.commercialPlanWrapper)JSON.deserialize(commercialPlanWrapperSerialized, PromoCalendarCtrl.commercialPlanWrapper.class)).commercialPlanList.size());
        System.assertEquals(1, ((List<CommercialPlan__c>)JSON.deserialize(CommercialPlanParentSerialized, List<CommercialPlan__c>.class)).size());
        System.assertEquals(commercialPlan1.Id, ((CommercialPlan__c)JSON.deserialize(commericalPlanSerialized, CommercialPlan__c.class)).Id);
        
    }

}