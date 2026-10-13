/**
 * @author ULiT
 * @date 16-10-2025
 * @description clone price lists statements test unit
 *******************************************************************************************************************************************/

@isTest
private class clonePLSBatchTest {
        private static Integer year = System.Today().year();
    private static final Integer N = 4;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static List<Tax__c> orgaTaxesList;
    static void init(){
        try {
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            ns.IsPriceListStatementRequested__c = true;
            ns.BusinessUnit__c = country.Id;
            update ns;
            // create Orga_Taxes
            orgaTaxesList = new List<Tax__c>();
            for (integer i = 0; i < N; i++) {
                orgaTaxesList.add(new Tax__c(Status__c = 'Open',
                                                    BusinessUnitTarget__c = country.Id));
            }
            insert orgaTaxesList;
            // create products for PG
            Id rootHEId = NegoptimHelper.getRootIdByRT('Product');
            Hierarchy__c root = [SELECT Id FROM Hierarchy__c WHERE Id = :rootHEId];
            update root;
            Hierarchy__c department = TestDataFactory.createHierarchyDepartment(true, rootHEId);
            Hierarchy__c section = TestDataFactory.createHierarchySection(true, department.Id);
            List<Product2> products = new List<Product2>();
            for (integer i = 0; i < N; i++) {
                Product2 product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
                product.RecordTypeId = TestDataFactory.productRTIds.get('Product');
                products.add(product);
            }
            insert products;

            // create PGs
            List<PG__c> PGs = new List<PG__c>();
            for (Product2 product : products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
                pg.Status__c = 'Open';
                pg.Product__c = product.Id;
                PGs.add(pg);
            }
            insert PGs;
            PriceListStatement__c priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
            priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
            priceListStatement.ReferenceYear__c = year;
            priceListStatement.BusinessUnitTarget__c = country.Id;
            priceListStatement.Status__c = 'Validated';
            insert priceListStatement;
            System.debug('priceListStatement: ' + priceListStatement);
           List<PriceListStatementDetail__c> details = new List<PriceListStatementDetail__c>();
            for(PG__c pg : PGs){
             PriceListStatementDetail__c detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, pg);
             details.add(detail);
           }
           insert details;

        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    @isTest
    static void testPLScloneBatch() {
        init();
        List<Id> sourceIds = new List<Id>();

        for (PriceListStatement__c pls : [SELECT Id FROM PriceListStatement__c]) {
            sourceIds.add(pls.Id);
        }
        String targetId = 'IsoPartner';
        Test.startTest();
        clonePriceListStatementBatch batch = new clonePriceListStatementBatch(sourceIds, targetId);
        Database.executeBatch(batch , 1);
        Test.stopTest();

        List<PriceListStatement__c> clonedPLS = [
            SELECT Label__c, PriceListStatementReference__c 
            FROM PriceListStatement__c 
            WHERE Id != :sourceIds
        ];

        System.assertEquals(1, clonedPLS.size(),'PLS should be cloned');
         for(PriceListStatement__c pls : clonedPLS){
            System.assert(pls.Label__c.startsWith('Clone'), 'Label should start with "Clone"');
            System.assertNotEquals(null, pls.PriceListStatementReference__c, 'Reference should point to original PLS');
        }

        List<PriceListStatementDetail__c> clonedDetails = [SELECT PriceListStatement__c FROM PriceListStatementDetail__c WHERE PriceListStatement__c IN :clonedPLS];
        System.assertEquals(4, clonedDetails.size(), 'PLS should have 4 cloned details');
    }
}