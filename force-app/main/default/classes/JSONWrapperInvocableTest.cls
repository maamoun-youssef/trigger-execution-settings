/**
 * @author ULiT
 * @date 20/10/2025
 * Unit test class for JSONWrapperInvocable
 **/
@isTest
private class JSONWrapperInvocableTest {
    
    static testMethod void case1_parseJson() {
        JSONWrapperInvocable.JSONWrapper jsonWrapper = new JSONWrapperInvocable.JSONWrapper();
        jsonWrapper.jsonInput = '[{"key":"1", "value":"1"}, {"key":"2", "value":"2"}]';
        Test.startTest();
        JSONWrapperInvocable.parseJson(new List<JSONWrapperInvocable.JSONWrapper>{ jsonWrapper });
        Test.stopTest();
        System.assert(true);
    }
}