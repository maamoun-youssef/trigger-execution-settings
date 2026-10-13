@isTest
private class ContractIndexesSummaryCmpCtrlTest {
    @testSetup
    static void setupTestData() {
        Account supplier = new Account(Name = 'Test Supplier');
        insert supplier;
        Contract__c parentContract = new Contract__c(
            Name = 'Parent Contract',
            RecordTypeId = getRecordTypeId('Contract__c', 'Signed'),
            Index1__c = 100,
            Index2__c = 200,
            Supplier__c = supplier.Id,
            Supplier_Nego_Scope__c = ''
        );
        insert parentContract;

        Contract__c childContract = new Contract__c(
            Name = 'Child Contract',
            Parent_Contract__c = parentContract.Id,
            RecordTypeId = getRecordTypeId('Contract__c', 'Signed'),
            Index1__c = 110,
            Index2__c = 210,
            Supplier__c = supplier.Id,
            Supplier_Nego_Scope__c = ''
        );
        insert childContract;
    }

    static Id getRecordTypeId(String sObjectApiName, String developerName) {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = :sObjectApiName AND DeveloperName = :developerName LIMIT 1];
        if (!rts.isEmpty()) {
            return rts[0].Id;
        }
        return null;
    }
    

    @isTest
    static void testInitComponentData() {
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE Parent_Contract__c != null LIMIT 1];
        Test.startTest();
        String resultJson = ContractIndexesSummaryCmpCtrl.initComponentData(testContract.Id);
        Test.stopTest();
        System.assertNotEquals(null, resultJson, 'Result JSON should not be null');
        System.assert(resultJson.contains(testContract.Id), 'Result JSON should contain the contract Id');
    }

    @isTest
    static void testGetContracts() {
        Contract__c testContract = [SELECT Id FROM Contract__c WHERE Parent_Contract__c != null LIMIT 1];

        Test.startTest();
        String contractJson = ContractIndexesSummaryCmpCtrl.getContracts(testContract.Id);
        Test.stopTest();

        System.assertNotEquals(null, contractJson, 'Contract JSON should not be null');
        System.assert(contractJson.contains('baseIndex'), 'Contract JSON should contain baseIndex');
    }
}