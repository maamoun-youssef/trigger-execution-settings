/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class DuplicateContractCmpCtrlTest {

    private static final Integer year = TestDataFactory.year;
    private static Integer yearN1;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;


    @isTest
    static void init() {
    	try {
            yearN1 = year + 1;
			// Insert Country List.
	        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	        // Insert Region.
	        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
	        // Insert Country.
	        country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            country.Status__c = 'Open';
            insert country;
	        // Insert supplier.
	        supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            NS.Status__c = 'Active';
            update NS;
	        contract = TestDataFactory.createContract(false, NS, Date.newInstance(year, 2, 17), Date.newInstance(year, 7, 18));
            contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }


    @isTest
    static void testGetData_Case001() {
        init();
        // Call the method
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(contract.Id);
        Test.stopTest();
        DuplicateContractCmpCtrl.ResultWrapper resultWrapper = (DuplicateContractCmpCtrl.ResultWrapper) JSON.deserialize(result, DuplicateContractCmpCtrl.ResultWrapper.class);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, resultWrapper.sourceContract);
    }

    @isTest
    static void testGetData_Case002() {
        init();
        Id sourceContract = contract.Id;
        contract = TestDataFactory.createContract(false, NS, Date.newInstance(yearN1, 1, 1), Date.newInstance(yearN1, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        insert contract;
        // Call the method
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(sourceContract);
        Test.stopTest();
        DuplicateContractCmpCtrl.ResultWrapper resultWrapper = (DuplicateContractCmpCtrl.ResultWrapper) JSON.deserialize(result, DuplicateContractCmpCtrl.ResultWrapper.class);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, resultWrapper.sourceContract);
        //System.assertNotEquals(null, resultWrapper.signedContractN1);
    }

    @isTest
    static void testGetData_Case003() {
        init();
        Id sourceContract = contract.Id;
        contract = TestDataFactory.createContract(false, NS, Date.newInstance(yearN1, 1, 1), Date.newInstance(yearN1, 3, 0));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Period_Extension');
        insert contract;
        // Call the method
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(sourceContract);
        Test.stopTest();
        DuplicateContractCmpCtrl.ResultWrapper resultWrapper = (DuplicateContractCmpCtrl.ResultWrapper) JSON.deserialize(result, DuplicateContractCmpCtrl.ResultWrapper.class);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, resultWrapper.sourceContract);
        System.assertNotEquals(null, resultWrapper.peContractN1);
    }

    @isTest
    static void testGetData_Case004() {
        init();
        contract.Status__c = 'Deleted';
        update contract;
        // Call the method
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(contract.Id);
        Test.stopTest();
        System.assertEquals(null, result);
    }

    @isTest
    static void testDuplicateContract() {
        init();
        Test.startTest();
        String jobId = DuplicateContractCmpCtrl.duplicateContract(
            contract.Id,
            contract.BusinessUnitContract__c,
            NS.Id,
            year,
            Date.newInstance(yearN1, 3, 1),
            Date.newInstance(yearN1, 12, 31),
            'Signed',
            null
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @isTest
    static void testCheckBatchRunning() {
        init();
        Test.startTest();
        String jobId = DuplicateContractCmpCtrl.duplicateContract(
            contract.Id,
            contract.BusinessUnitContract__c,
            NS.Id,
            year,
            Date.newInstance(yearN1, 3, 1),
            Date.newInstance(yearN1, 12, 31),
            'Signed',
            null
        );
        Test.stopTest();
        Boolean isBatchRunning = DuplicateContractCmpCtrl.checkBatchRunning(jobId);
        System.assertEquals(false, isBatchRunning);
    }

    @isTest
    static void testGetApexLogId() {
        init();
        Test.startTest();
        String jobId = DuplicateContractCmpCtrl.runDuplicateContractBatch(
            contract.Id,
            contract.BusinessUnitContract__c,
            year,
            Date.newInstance(yearN1, 3, 1),
            Date.newInstance(yearN1, 12, 31),
            'Signed',
            null
        );
        Test.stopTest();
        Map<String, Id> result = DuplicateContractCmpCtrl.getApexLogId(jobId, contract.BusinessUnitContract__c, NS.Id, year, 'Signed');
        List<Contract__c> contractList = [SELECT Id
                                            FROM Contract__c
                                            WHERE Recordtype.DeveloperName = 'Signed'
                                            AND Reference_Year__c = :yearN1];
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.get('apexJobId'));
        System.assertEquals(contractList[0].id, result.get('contractId'));
        // System.assertEquals(contract.Id, result.get('contractId'));
    }

    @isTest
    static void testGetData_StatusSpecificConfiguration() {
        init();
        contract.Status__c = 'Validated';
        update contract;
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(contract.Id);
        Test.stopTest();
        DuplicateContractCmpCtrl.ResultWrapper resultWrapper = (DuplicateContractCmpCtrl.ResultWrapper) JSON.deserialize(result, DuplicateContractCmpCtrl.ResultWrapper.class);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, resultWrapper.sourceContract);
        System.assertNotEquals(null, resultWrapper.targetContractRTs);
    }

    @isTest
    static void testGetData_MultipleMatchingConfigurations() {
        init();
        // Test case where contract has RT=Signed and Status=Signed (This should match both "any status" and "status=Signed" configurations and return merged target contract types from both)
        contract.Status__c = 'Signed';
        update contract;
        Test.startTest();
        String result = DuplicateContractCmpCtrl.getData(contract.Id);
        Test.stopTest();
        DuplicateContractCmpCtrl.ResultWrapper resultWrapper = (DuplicateContractCmpCtrl.ResultWrapper) JSON.deserialize(result, DuplicateContractCmpCtrl.ResultWrapper.class);
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, resultWrapper.sourceContract);
        System.assertNotEquals(null, resultWrapper.targetContractRTs);
        System.assert(resultWrapper.targetContractRTs.size() >= 1, 'Should have at least one target contract type');
    }
}