/**
 * @author ULiT
 * @date 28-02-2025
 * @description Unit test class for Trg_AssortmentDetail_HandlerExt
 **************************************************************/
@isTest
public class PGClientCategoryToASDBatchTest {
    
    private static Id rootId;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Assortment__c assortment;
    private static BusinessUnit__c country;
    private static final Map<String, Id> pgRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PG__c.SObjectType);
    
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
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        product.Weight__c = 0.5;
        insert product;
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.Supplier__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.IsMultipleComplementary__c = true;
        buTarget.Supplier__c = supplier.Id;
        buTarget.Hierarchy__c = department.Id;
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        buTarget.WeightedDistributionManual__c = 45;
        buTarget.SiteOfSalesNumber__c = 185;
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('WeightedDistributionInnovRiseM' + i + '__c', i);
        }
        insert new List<BusinessUnit__c>{buTarget, buSource};
        // insert assortment_BU        
        assortment = TestDataFactory.createAssortment(false, buSource, buTarget, department);
        assortment.Status__c = 'Validate';
        assortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Negotiation');
        insert assortment;
    }

    // case autoFillAssortmentCategory/update Client_Clust(i)__c/calculate WD
    static testmethod void case1_PGClientCategoryToASDBatchExt() {
        init();
        PG__c pg = TestDataFactory.createPG(false, supplier.Id, section.Id);
        pg.Product__c = product.Id;
        pg.ClientCategory__c = 'C1';
        pg.RecordTypeId = pgRTIds.get('Regular');
        insert pg;
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortment.Id,
                                                                                           Product__c = product.Id,
                                                                                           Hierarchy__c = null,
                                                                                           ProductLifeStatusAss__c = 'New');
        insert assortmentDetail;
        System.assertEquals('C1', [SELECT ClientCategory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id].ClientCategory__c);
        Test.startTest();
        pg.ClientCategory__c = 'C2';
        update pg;
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => PGClientCategoryToASDBatchTest.class.getName(),
            'assortmentIds' => new Set<Id>{assortment.Id},
            'yearSet' => new Set<Integer>{System.today().year()}
        };
        NegoptimBatch.executeBatch('PGClientCategoryToASDBatch', paramsMap, 50);
        Test.stopTest();
        System.assertEquals('C2', [SELECT ClientCategory__c FROM AssortmentDetail__c WHERE Id = :assortmentDetail.Id].ClientCategory__c);
    }

}