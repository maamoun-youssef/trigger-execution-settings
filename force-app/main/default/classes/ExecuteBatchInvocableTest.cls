@isTest
private class ExecuteBatchInvocableTest {

    static testMethod void case1_execute_ProductToASDBatch() {
        List<ExecuteBatchInvocable.BatchParametersWrapper> batchParamsList = new List<ExecuteBatchInvocable.BatchParametersWrapper>();
        ExecuteBatchInvocable.BatchParametersWrapper batchParams = new ExecuteBatchInvocable.BatchParametersWrapper();
        batchParams.batchName = 'ProductToASDBatch';
        batchParams.years = new List<Integer>{System.today().Year()};
        batchParams.assortmentIds = new List<Id>();
        batchParamsList.add(batchParams);
        Test.startTest();
        ExecuteBatchInvocable.execute(batchParamsList);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob]);
    }

    static testMethod void case2_execute_PGClientCategoryToASDBatch() {
        List<ExecuteBatchInvocable.BatchParametersWrapper> batchParamsList = new List<ExecuteBatchInvocable.BatchParametersWrapper>();
        ExecuteBatchInvocable.BatchParametersWrapper batchParams = new ExecuteBatchInvocable.BatchParametersWrapper();
        batchParams.batchName = 'PGClientCategoryToASDBatch';
        batchParams.years = new List<Integer>{System.today().year()};
        batchParams.assortmentIds = new List<Id>();
        batchParamsList.add(batchParams);
        Test.startTest();
        ExecuteBatchInvocable.execute(batchParamsList);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob]);
    }
    
    static testMethod void case3_execute_InitSalesTermsStatementBatch() {
        List<ExecuteBatchInvocable.BatchParametersWrapper> batchParamsList = new List<ExecuteBatchInvocable.BatchParametersWrapper>();
        ExecuteBatchInvocable.BatchParametersWrapper batchParams = new ExecuteBatchInvocable.BatchParametersWrapper();
        batchParams.batchName = 'InitSalesTermsStatementBatch';
        batchParams.years = new List<Integer>();
        batchParams.assortmentIds = new List<Id>();
        batchParams.recordId = null;
        batchParamsList.add(batchParams);
        Test.startTest();
        ExecuteBatchInvocable.execute(batchParamsList);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob]);
    }
}