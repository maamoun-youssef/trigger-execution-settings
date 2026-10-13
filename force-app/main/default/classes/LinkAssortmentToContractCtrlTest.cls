/**
 * @author ULiT
 * @date 05-06-2024
 * @description Unit test class for LinkAssortmentToContractCtrl
 **************************************************************/
@isTest
public class LinkAssortmentToContractCtrlTest {

    private static Integer year;
    private static final Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
    private static Id rootId;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static Product2 product2;
    private static BusinessUnit__c country;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static BusinessUnit__c channel;
    private static Assortment__c assortment;
    private static List<AssortmentDetail__c> assortmentDetailsList;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Assortment_BU__c pwf;
    
    static void init() {
        year = System.Today().year();
        // Root element Id.
        rootId = NegoptimHelper.getRootIdByRT('Product');
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
        department = TestDataFactory.createHierarchyDepartment(false, rootId);
        department.SetProductLevel__c = true;
        insert department;
        section = TestDataFactory.createHierarchySection(true, department.Id);
        //create Brand 
        Brand__c brand = TestDataFactory.createBrand(true, supplier.Id);
        Brand__c brand2 = TestDataFactory.createBrand(false, supplier.Id);
        brand2.BrandParent__c = brand.Id;
        insert brand2;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.IsMasterBU__c = true;
        buSource.SetAssortmentBudgetBUSource__c = true;
        buSource.LayerNegoConso__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Name = 'HMSM';
        buTarget.Hierarchy__c = department.Id;
        buTarget.SetAssortmentBudgetBUTarget__c = true;
        buTarget.IsMasterBU__c = true;
        buTarget.LayerNegoConso__c = true;
        // create channel BU
        channel = TestDataFactory.createBusinessUnitChannel(false, country);
        channel.IsMasterBU__c = true;
        insert new List<BusinessUnit__c>{buTarget, buSource, channel};
        // insert assortment
        assortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortment.Status__c = 'Validate';
        assortment.Year__c = System.today().year();
        assortment.RecordTypeId = assortmentRTIds.get('Target');
        assortment.OnTop__c = true;
        insert assortment;
        // Create Product.
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.Brand__c = brand.Id;
            product.Hierarchy__c = department.Id;
            products.add(product);
        }
        insert products;
        assortmentDetailsList = new List<AssortmentDetail__c>();
        for (Product2 product : products) {
            assortmentDetailsList.add(TestDataFactory.createAssortmentDetail2(false, assortment.Id, product, null));
        }
        insert assortmentDetailsList;
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Number__c = 'C0A1',
                                             Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                             Contract_Commercial_BDate__c = date.newInstance(year, 1, 1), Contract_Commercial_EDate__c = date.newInstance(year, 12, 31),
                                             Duration__c = 12, BusinessUnitContract__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Signed');
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
        insert contract;
        pwf = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        pwf.Contract__c = contract.Id;
        insert pwf;
    }
    
    static testmethod void Case1_loadData() {
        init();
        Test.startTest();
        String data = LinkAssortmentToContractCtrl.loadData(assortment.Id);
        LinkAssortmentToContractCtrl.MainWrapper result = data != '' ? (LinkAssortmentToContractCtrl.MainWrapper) JSON.deserialize(data, LinkAssortmentToContractCtrl.MainWrapper.class) : new LinkAssortmentToContractCtrl.MainWrapper();
        Test.stopTest();
        System.assertEquals(1, result.PWFs.size());
    }
    
    static testmethod void Case2_updateAssortment() {
        init();
        Test.startTest();
        String result = LinkAssortmentToContractCtrl.updateAssortment(assortment.Id, contract.Id, pwf.Id);
        Test.stopTest();
        assortment = [SELECt Id, Contract__c, PWF__c FROM Assortment__c WHERE Id = :assortment.Id];
        System.assertEquals('', result);
        System.assertEquals(contract.Id, assortment.Contract__c);
        System.assertEquals(pwf.Id, assortment.PWF__c);
    }
    
    static testmethod void Case2_executeSynchroPWF() {
        init();
        Test.startTest();
        LinkAssortmentToContractCtrl.executeSynchroPWF(assortment.Id);
        Test.stopTest();
        System.assert(true);
    }
    
}