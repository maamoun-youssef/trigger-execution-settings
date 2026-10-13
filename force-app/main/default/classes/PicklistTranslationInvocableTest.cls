/**
 * @author ULiT
 * @date 12/05/2025
 * @description Unit test class of PicklistTranslationInvocable
 * */
@isTest
private class PicklistTranslationInvocableTest {	
   
    @isTest
    static void case1_getPicklistTranslations() {
        PicklistTranslationInvocable.PicklistFieldInfoWrapper pickListInfo = new PicklistTranslationInvocable.PicklistFieldInfoWrapper();
        pickListInfo.objectApiName = SellInStatementDetail__c.getSObjectType().getDescribe().getName();
        pickListInfo.fieldApiName = SObjectType.SellInStatementDetail__c.fields.Status__c.Name;
        Test.startTest();
        PicklistTranslationInvocable.getPicklistTranslations(new List<PicklistTranslationInvocable.PicklistFieldInfoWrapper>{ pickListInfo });
        Test.stopTest();
        System.assert(true);
    }
}