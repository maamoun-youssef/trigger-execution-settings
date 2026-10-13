/**
 * @author ULiT
 * @date 28-05-2024
 * @description Unit test class for BUClusterManagementCtrl
 **************************************************************/
@IsTest
public class BUClusterManagementCtrlTest {
    private static BusinessUnit__c country;
    private static List<BusinessUnit__c> banners = new List<BusinessUnit__c>();
    private static List<BusinessUnit__c> clustersList = new List<BusinessUnit__c>();

    static void init() {
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'region');
        Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        for (Integer i = 0; i < 10; i++) {
            banners.add(TestDataFactory.createBusinessUnitBanner(false, country));
        }
        insert banners;
        clustersList = new List<BusinessUnit__c>();
        for (BusinessUnit__c banner : banners) {
            for (Integer i = 0; i < 3; i++) {
                clustersList.add(TestDataFactory.createBusinessUnitAssortCluster(false, banner.Id, 'Strat' + i));
            }
        }
        insert clustersList;
    }

    private static String emptyFilter() {
        return JSON.serialize(new BUClusterManagementCtrl.FilterWrapper('', '', '', '', ''));
    }

    static testmethod void Case1_loadData() {
        init();
        Test.startTest();
        String results = BUClusterManagementCtrl.loadCountries('', 1, emptyFilter());
        BUClusterManagementCtrl.ResultsWrapper countryData = results != '' ? (BUClusterManagementCtrl.ResultsWrapper) JSON.deserialize(results, BUClusterManagementCtrl.ResultsWrapper.class) : new BUClusterManagementCtrl.ResultsWrapper();
        String bannerIdParam = countryData.bannerId != null ? String.valueOf(countryData.bannerId) : '';
        String bannerResults = BUClusterManagementCtrl.loadData(bannerIdParam, new List<Id>{ country.Id }, emptyFilter());
        List<BusinessUnit__c> bannerData = bannerResults != '' ? (List<BusinessUnit__c>) JSON.deserialize(bannerResults, List<BusinessUnit__c>.class) : new List<BusinessUnit__c>();
        Test.stopTest();
        System.assertEquals(1, countryData.countryList.size());
        System.assertEquals(banners.size(), bannerData.size());
    }

    static testmethod void Case2_loadDataWithBannerId() {
        init();
        Test.startTest();
        String results = BUClusterManagementCtrl.loadCountries(banners[0].Id, 1, emptyFilter());
        BUClusterManagementCtrl.ResultsWrapper countryData = results != '' ? (BUClusterManagementCtrl.ResultsWrapper) JSON.deserialize(results, BUClusterManagementCtrl.ResultsWrapper.class) : new BUClusterManagementCtrl.ResultsWrapper();
        String bannerResults = BUClusterManagementCtrl.loadData(String.valueOf(countryData.bannerId), new List<Id>{ country.Id }, emptyFilter());
        List<BusinessUnit__c> bannerData = bannerResults != '' ? (List<BusinessUnit__c>) JSON.deserialize(bannerResults, List<BusinessUnit__c>.class) : new List<BusinessUnit__c>();
        Test.stopTest();
        System.assertEquals(1, countryData.countryList.size());
        System.assertEquals(1, bannerData.size());
    }

    static testmethod void Case3_insertCluster() {
        init();
        Test.startTest();
        List<BusinessUnit__c> clustersToInsert = new List<BusinessUnit__c>();
        for (Integer i = 5; i < 7; i++) {
            clustersToInsert.add(TestDataFactory.createBusinessUnitAssortCluster(false, banners.get(0).Id, 'Strat' + i));
        }
        BUClusterManagementCtrl.insertCluster(JSON.serialize(clustersToInsert));
        Test.stopTest();
        String bannerResults = BUClusterManagementCtrl.loadData('', new List<Id>{ country.Id }, emptyFilter());
        List<BusinessUnit__c> bannerData = bannerResults != '' ? (List<BusinessUnit__c>) JSON.deserialize(bannerResults, List<BusinessUnit__c>.class) : new List<BusinessUnit__c>();
        System.assertEquals(banners.size(), bannerData.size());
    }

    static testmethod void Case4_saveClusters() {
        init();
        Test.startTest();
        clustersList[0].SiteOfSalesNumberP1__c = 65;
        clustersList[1].WeightedDistributionInnovRiseM1__c = 112;
        List<BusinessUnit__c> clustersToUpdate = new List<BusinessUnit__c>{ clustersList[0], clustersList[1] };
        BUClusterManagementCtrl.saveClusters(JSON.serialize(clustersToUpdate));
        Test.stopTest();
        Map<Id, BusinessUnit__c> clusters = new Map<Id, BusinessUnit__c>([
            SELECT Id, SiteOfSalesNumberP1__c, WeightedDistributionInnovRiseM1__c
            FROM BusinessUnit__c
            WHERE Id = :clustersList[0].Id OR Id = :clustersList[1].Id
        ]);
        System.assertEquals(65, clusters.get(clustersList[0].Id).SiteOfSalesNumberP1__c);
        System.assertEquals(112, clusters.get(clustersList[1].Id).WeightedDistributionInnovRiseM1__c);
    }

    static testmethod void Case5_loadClusters() {
        init();
        Test.startTest();
        String clusterResults = BUClusterManagementCtrl.loadClusters(banners[0].Id, emptyFilter());
        List<BusinessUnit__c> clusterData = clusterResults != '' ? (List<BusinessUnit__c>) JSON.deserialize(clusterResults, List<BusinessUnit__c>.class) : new List<BusinessUnit__c>();
        String filteredResults = BUClusterManagementCtrl.loadClusters(
            banners[0].Id,
            JSON.serialize(new BUClusterManagementCtrl.FilterWrapper('', '', banners[0].Id, 'Cat', 'Strat0'))
        );
        List<BusinessUnit__c> filteredData = filteredResults != '' ? (List<BusinessUnit__c>) JSON.deserialize(filteredResults, List<BusinessUnit__c>.class) : new List<BusinessUnit__c>();
        Test.stopTest();
        System.assertEquals(3, clusterData.size());
        System.assertNotEquals(null, filteredData);
    }

    static testmethod void Case6_filters() {
        init();
        Test.startTest();
        String cRes = BUClusterManagementCtrl.loadCountries('', 1, JSON.serialize(new BUClusterManagementCtrl.FilterWrapper(country.Id, '', '', '', '')));
        BUClusterManagementCtrl.ResultsWrapper cData = (BUClusterManagementCtrl.ResultsWrapper) JSON.deserialize(cRes, BUClusterManagementCtrl.ResultsWrapper.class);
        String bRes = BUClusterManagementCtrl.loadData('', new List<Id>{ country.Id }, JSON.serialize(new BUClusterManagementCtrl.FilterWrapper('', banners[0].Id, '', '', '')));
        List<BusinessUnit__c> bData = (List<BusinessUnit__c>) JSON.deserialize(bRes, List<BusinessUnit__c>.class);
        Test.stopTest();
        System.assertEquals(1, cData.countryList.size());
        System.assertEquals(1, bData.size());
    }
}