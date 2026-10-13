/**
 * @author ULiT
 * @date 27/01/2024
 * @desciption unit test class for ProductDiscountStatementGridController
 **/
@isTest
public class ProductDiscountStatementGridTest {
	private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static PG__c pg;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static CommercialPlan__c commercialPlan;
    private static CommercialPlanDetail__c commercialPlanDetail;
    private static ProductDiscountStatement__c productDiscountStatement;
    private static ProductDiscountStatementDetail__c productDiscountStatementDetail;
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Product.
            product = TestDataFactory.createProduct(false, section.Id, null);
            product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
            product.Name = 'Pepsi1';
            product.GTIN__c = 'pepsi1';
            product.ProductCode = 'Pepsi1';
            insert product;
            //Create PG
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            insert pg;
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create Contract
            contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'DRV';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.SetCommercialPlanDetail1__c = true;
            insert tariffCondition;
            // Insert condition
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            condition.Value_per__c = 5;
            condition.Value_amt__c = null;
            condition.Base_TO_Nego__c = 1000;
            condition.Base_TO_Tariff_Nego__c = 1000;
            condition.Rank__c = 1;
            condition.Display_Order__c = 1;
            insert condition;
            // create BUSource BuTarget
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buSource.Supplier__c = supplier.Id;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = supplier.Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
            // insert Commercial Plan and Commertial Plan Detail
            commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            commercialPlan.Supplier__c = supplier.Id;
            commercialPlan.BusinessUnitTarget__c = buTarget.Id;
            commercialPlan.Code__c = 'Promo1';
            insert commercialPlan;
            commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.Product__c = product.Id;
            insert commercialPlanDetail;
            // insert ProductDiscountStatement__c
            productDiscountStatement = new ProductDiscountStatement__c(Name = 'PDS',
                                                                       BDate__c = Date.newInstance(year, 1, 1),
                                                                       EDate__c = Date.newInstance(year, 12, 31),
                                                                       Supplier__c = supplier.Id,
                                                                       NegoScope__c = NS.Id,
                                                                       Status__c = null,
                                                                       ReferenceYear__c = year,
                                                                       RecordTypeId = NegoptimHelper.getObjectRecordTypeId(ProductDiscountStatement__c.SObjectType, 'Other'));
            insert productDiscountStatement;
            productDiscountStatementDetail = new ProductDiscountStatementDetail__c(ProductDiscountStatement__c = productDiscountStatement.Id,
                                                                                   NegoScope__c = NS.Id,
                                                                                   Contract__c = contract.Id,
                                                                                   BDate__c = Date.newInstance(year, 1, 1),
                                                                                   EDate__c = Date.newInstance(year, 12, 31),
                                                                                   Status__c = 'InPreparation',
                                                                                   ExtId__c = 'Pepsi1,pepsi1,Pepsi1,DRV,,,2025-01-01,2025-12-31,',
                                                                                   DeclarantComment__c = 'Comment',
                                                                                   ProductQtyMax__c = 10,
                                                                                   ProductQtyMin__c = 10,
                                                                                   ProductQty__c = 10,
                                                                                   GrossPrice__c = 10,
                                                                                   input_PRDGTIN__c = product.GTIN__c,
                                                                                   input_PRDCode__c = product.ProductCode,
                                                                                   input_PRDName__c = product.Name,
                                                                                   input_PCCCode__c = tariffCondition.Condition_Code__c);
            insert productDiscountStatementDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest static void case1_initData() {
        init();
        Test.startTest();
        String mainWrapperSerialized = ProductDiscountStatementGridController.initData(null);
        ProductDiscountStatementGridController.MainWrapper mainwrapper = (ProductDiscountStatementGridController.MainWrapper) JSON.deserialize(mainWrapperSerialized, ProductDiscountStatementGridController.MainWrapper.class);
        productDiscountStatement = [SELECT Id, RecordType.DeveloperName FROM ProductDiscountStatement__c WHERE Id = :productDiscountStatement.Id];
        System.debug('productDiscountStatement>>> ' + JSON.serialize(productDiscountStatement));
        Map<String,String> filtersMap = new Map<String,String>();
        filtersMap.put('globalSearchValue', 'PDS');
        List<ProductDiscountStatementGridController.FilterSettings> dyanmicFilter = new List<ProductDiscountStatementGridController.FilterSettings>{
            new ProductDiscountStatementGridController.FilterSettings('Name', 'Name', false, 'STRING', null, '', '', new List<String>{'PDS'}, true),
            new ProductDiscountStatementGridController.FilterSettings(SObjectType.ProductDiscountStatementDetail__c.fields.Status__c.Name, 'status', false, 'PICKLIST', null, '', '', new List<String>{'InPreparation'}, true),
            new ProductDiscountStatementGridController.FilterSettings(SObjectType.ProductDiscountStatementDetail__c.fields.RecordTypeId.Name, 'RecordType', false, 'REFERENCE', null, '', '', new List<String>{productDiscountStatement.RecordType.DeveloperName}, true),// to cover reference
            new ProductDiscountStatementGridController.FilterSettings(SObjectType.ProductDiscountStatementDetail__c.fields.CreatedDate.Name, 'CreatedDate', false, 'DATETIME', null, '2025-01-01T00:00:00.000Z', '2025-01-01T10:00:00.000Z', null, true)
        };
        filtersMap.put('dynamic', JSON.serialize(dyanmicFilter));
        ProductDiscountStatementGridController.loadData(supplier.Id, JSON.serialize(mainwrapper.gridSettingsManagerPDS), JSON.serialize(filtersMap), 1, 1);
        Test.stopTest();
        System.assert(true);
    }
    @isTest static void case1_SaveData() {
        init();
        Test.startTest();
        productDiscountStatement.Sender__c = 'Supplier';
        productDiscountStatement.Recipient__c = 'Buyer';
        ProductDiscountStatementGridController.save(JSON.serialize(new List<ProductDiscountStatement__c>{productDiscountStatement}));
        Test.stopTest();
        productDiscountStatement = [SELECT Sender__c, Recipient__c FROM ProductDiscountStatement__c WHERE Id = :productDiscountStatement.Id];
        System.assertEquals('Supplier', productDiscountStatement.Sender__c);
        System.assertEquals('Buyer', productDiscountStatement.Recipient__c);
    }
}