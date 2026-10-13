/**
 * @author ULiT
 * @date 03-06-2026
 * @description Apex controller for CommentManager LWC
 */
public with sharing class CommentManagerCtrl {
    private static final Datetime EXECUTION_TIME = System.now();
    @AuraEnabled
    public static String saveData(Id recordId, String comment, Id account, String currentUser, Boolean isPortalPublished, String origin, String trackActionId) {
        TrackAction__c trackAction;
        try{
            User cUser = (User) JSON.deserialize(currentUser, User.class);
            if(String.isNotBlank(trackActionId)) {
                trackAction = new TrackAction__c(Id=trackActionId, Comment__c=comment);
            } else {
                trackAction = new TrackAction__c();
                trackAction.ParentId__c = recordId;
                if(account != null) {
                    trackAction.Account__c = account;
                }
                trackAction.Assignee__c = cUser.Name;
                trackAction.AssigneeIconURL__c = cUser?.SmallPhotoUrl;
                // trackAction.Status__c = clause.Status__c;
                trackAction.Status__c = 'Open';
                trackAction.ActionDate__c = EXECUTION_TIME;
                trackAction.Comment__c = comment;
                trackAction.IsPortalPublished__c = isPortalPublished;
                trackAction.CommentOrigin__c = origin;
                trackAction.CommentStatus__c = 'Draft';
            }
            upsert trackAction;     
            List<LegalDocClause__c> clauses = [SELECT Id, LegalDoc__c, LegalDoc__r.Name FROM LegalDocClause__c WHERE Id = :recordId LIMIT 1];
            if(!clauses.isEmpty()) {
                LegalDoc__c doc = clauses[0].LegalDoc__r;
                if(doc != null) {
                    if(origin == 'Supplier')  doc.PartnerLastModifyDate__c = EXECUTION_TIME;
                    if(origin == 'Legal')  doc.LegalLastModifyDate__c = EXECUTION_TIME;
                    if(origin == 'Business Owner')  doc.BusinessOwnerLastModifyDate__c = EXECUTION_TIME;
                    update doc;
                } 
            }
        } catch(Exception e) {
            System.debug('error: ' + e.getMessage());
            System.debug('error: ' + e.getStackTraceString());
            System.debug('error: ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(trackAction);
    }
    public class ResultWrapper {
        @AuraEnabled public List<TrackAction__c> trackActivities;
        @AuraEnabled public Supplier__c currentSupplier;
        @AuraEnabled public User currentUser;

        public ResultWrapper() {}
    }
}