/**
 * @author ULiT
 * @date 23/10/2023
 * @description unit test for NegOptimCustomLookupCmpCtrl
 * */
@isTest
public class NegOptimCustomLookupCmpCtrlTest {
    @isTest
    static void getResults() {
        Test.startTest();
        Account acc1 = new Account(Name = 'acc1', Description = 'acc1', AccountNumber = '1', NumberOfEmployees = 11);
        Account acc2 = new Account(Name = 'acc2', Description = 'acc2', AccountNumber = '2', NumberOfEmployees = 12);
        insert (new List<Account>{acc1, acc2});
        String filter = 'NumberOfEmployees > 10';
        String searchTerm = 'acc';
        //NegOptimCustomLookupCmpCtrlExt.getResults('Account', 'Name',  new List<String>{'Name', 'Description'} , searchTerm, new List<String>{acc1.Id}, filter);
        List<NegOptimCustomLookupCmpCtrl.SObjectResult> results = NegOptimCustomLookupCmpCtrl.getResults('Account', 'Name',  new List<String>{'Name', 'Description'}  , searchTerm, new List<String>{acc1.Id}, new List<String>{filter});
        Test.stopTest();
        System.assertEquals(1, results.size());
    }
}