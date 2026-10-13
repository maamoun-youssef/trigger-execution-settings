/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for AssortmentInvocable
 **************************************************************/
@isTest
public class AssortmentInvocableTest {

    static Integer N = Date.today().year();
    static Integer nbOfProducts = 50;
    static Assortment__c assortment;
    static List<Product2> products;
    static List<Object> clientStatusValues;
    static List<AssortmentDetail__c> asdList;
    static Id HERootId;

    static void init () {
        try {
            Country_List__c countryList = TestDataFactory.createCountry(true, 'Lebanon', 'LB');
            BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            BusinessUnit__c country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Assortment BU Source
            BusinessUnit__c buSource = TestDataFactory.createBusinessUnitBanner(false, country);
            buSource.IsMasterBU__c = true;
            // Assortment BU Target
            BusinessUnit__c buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            insert new List<BusinessUnit__c> {BUSource, BUTarget};
            // Assortment Orga HE (Level 1)
            HERootId = NegoptimHelper.getRootId();
            Hierarchy__c orgaHE = TestDataFactory.createHierarchyDepartment(false, HERootId);
            orgaHE.SetAssortmentLevel__c = true;
            orgaHE.SetProductLevel__c = true;
            insert orgaHE;
            // Create Products
            products = new List<Product2>();
            for (Integer i = 0; i < nbOfProducts; i++) {
                Product2 product = TestDataFactory.createProduct(false, orgaHE.Id, null);
                products.add(product);
            }
            insert products;
            // Create Nego Assortment on year N
            assortment = TestDataFactory.createAssortment(false, buSource, buTarget, orgaHE);
            assortment.Status__c = 'Validate';
            insert assortment;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
        // Create Assortment Details manually to cover as many cases as possible
        asdList = new List<AssortmentDetail__c>();

        clientStatusValues = new List<Object>();
        clientStatusValues.add(null);
        for (Schema.PicklistEntry ple : AssortmentDetail__c.ProductLifeStatusAss__c.getDescribe().getPicklistValues()) {
            clientStatusValues.add(ple.getValue());
        }
        Integer i = 0;
        for (Object clientStatusValue : clientStatusValues) {
            // create a detail with blank movement date for each available client status
            if (i < nbOfProducts) {
                AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortment.Id, products[i], null);
                asd.ProductLifeStatusAss__c = clientStatusValue == null ? null : String.valueOf(clientStatusValue);
                asd.StartDate__c = null;
                asdList.add(asd);
                i++;
            }
            // create a detail with movement date greater than or equal to the begin date of next year's assortment
            if (i < nbOfProducts) {
                AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortment.Id, products[i], null);
                asd.ProductLifeStatusAss__c = clientStatusValue == null ? null : String.valueOf(clientStatusValue);
                asd.StartDate__c = Date.newInstance(N + 1, 1, 1);
                asdList.add(asd);
                i++;
            }
            // create a detail with movement date less than the begin date od next year's assortment
            if (i < nbOfProducts) {
                AssortmentDetail__c asd = TestDataFactory.createAssortmentDetail2(false, assortment.Id, products[i], null);
                asd.ProductLifeStatusAss__c = clientStatusValue == null ? null : String.valueOf(clientStatusValue);
                asd.StartDate__c = Date.newInstance(N, 8, 12);
                asdList.add(asd);
                i++;
            }
        }
        System.assertEquals(clientStatusValues.size() * 3, asdList.size());
        insert asdList;
    }
    
    static testmethod void Case1_createSimulationDetailsFromSourceAssortment() {
        init();
        AssortmentInvocable.AssortmentsWrapper assortmentWrapper = new AssortmentInvocable.AssortmentsWrapper();
        assortmentWrapper.sourceId = assortment.Id;
        Assortment__c cloneAssortment = assortment.clone(false, true, false, false);
        cloneAssortment.Year__c = N + 1;
        cloneAssortment.BDate__c = Date.newInstance(N + 1, 1, 1);
        cloneAssortment.EDate__c = Date.newInstance(N + 1, 12, 31);
        insert cloneAssortment;
        assortmentWrapper.recordId = cloneAssortment.Id;
        assortmentWrapper.statusASD = 'InPreparation';
        Test.startTest();
        AssortmentInvocable.createSimulationDetailsFromSourceAssortment(new List<AssortmentInvocable.AssortmentsWrapper>{assortmentWrapper});
        Test.stopTest();
        System.assertEquals(asdList.size(), [SELECT COUNT() FROM AssortmentDetail__c WHERE Assortment__c = :cloneAssortment.Id]);
    }
    
}