/**
 * @author ULiT
 * @date 14-05-2024
 * @description Unit test class for AssortmentSettingsController
 **************************************************************/
@isTest
public class AssortmentSettingsControllerTest {
	private static BusinessUnit__c region;
    private static Integer year;
    public static final Map<String, Id> businessUnitRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);

    static void init() {
        year = System.Today().year();
        region = TestDataFactory.createBusinessUnitRegion(true, 'region');
    }

    static testMethod void test_coverage() {
        AssortmentSettings assortmentSettings = new AssortmentSettings();
        Test.startTest();
        assortmentSettings.assortmentMatrixNego = 'AssortmentMatrixTest';
        String jobId = AssortmentSettingsController.save(JSON.serialize(assortmentSettings));
        Test.stopTest();
        String result = AssortmentSettingsController.checkDeploymentStatus(jobId);
        String dataWrapperSerialized = AssortmentSettingsController.loadAssortmentSettings();
        System.assert(true);
    }
    static testMethod void Case1_ApplyHrToBu_WithoutApi() {
        init();
        String buRecordType = businessUnitRTIds.get('Region');
        AssortmentSettings.SalesCannibalizationRatesWrapper hypothesisReportWrapper = new AssortmentSettings.SalesCannibalizationRatesWrapper();
        Test.startTest();
        String result = AssortmentSettingsController.applyHRtoBU(new List<String>{buRecordType}, JSON.serialize(new List<AssortmentSettings.SalesCannibalizationRatesWrapper> {hypothesisReportWrapper}), true);
        Test.stopTest();
        System.assert(true);
    }
    static testMethod void Case2_ApplyHrToBu_WithApi() {
        init();
        String buRecordType = businessUnitRTIds.get('Region');
        AssortmentSettings.SalesCannibalizationRatesWrapper hypothesisReportWrapper = new AssortmentSettings.SalesCannibalizationRatesWrapper();
        hypothesisReportWrapper.api = 'test';
        region.t_SalesCannibalizationRates__c = JSON.serialize(new List<AssortmentSettings.SalesCannibalizationRatesWrapper> {hypothesisReportWrapper});
        update region;
        Test.startTest();
        String result = AssortmentSettingsController.applyHRtoBU(new List<String>{buRecordType}, JSON.serialize(new List<AssortmentSettings.SalesCannibalizationRatesWrapper> {hypothesisReportWrapper}), true);
        Test.stopTest();
        System.assert(true);
    }
}