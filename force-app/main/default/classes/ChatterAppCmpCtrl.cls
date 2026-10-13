public with sharing class ChatterAppCmpCtrl {

    @AuraEnabled
    public static String getFeedWithFeedElements(String communityId) {
            return ChatterManager.getFeedWithFeedElements(communityId);
    }
    @AuraEnabled
    public static String getFeedDirectory(String communityId) {
            return ChatterManager.getFeedDirectory(communityId);
    }
    
    @AuraEnabled
    public static String getFeed(String communityId) {
            return ChatterManager.getFeed(communityId);
    }

    @AuraEnabled
    public static String getCommunities() {
            return ChatterManager.getCommunities();
    }

    @AuraEnabled
    public static String getUsers(String communityId) {
            return ChatterManager.getUsers(communityId);
    }

    @AuraEnabled
    public static String getUser(String communityId, String userId) {
            return ChatterManager.getUser(communityId, userId);
    }
    
    @AuraEnabled
    public static String getConversations(String communityId) {
            return ChatterManager.getConversations(communityId);
    }

    @AuraEnabled
    public static String getConversation(String conversationId) {
            return ChatterManager.getConversation(conversationId);
    }

    @AuraEnabled
    public static String sendMessage(String recipientUserId, String message) {
            return ChatterManager.sendMessage(recipientUserId, message);
    }
    
    @AuraEnabled
    public static String processRest(String requestUrl) {
        return ChatterManager.processRest(requestUrl);
    }
    @AuraEnabled
    public static String processRestPost(String requestUrl, String body) {
        System.debug('processRestPost');
        return ChatterManager.processRestPost(requestUrl, body);
    }
    
    @AuraEnabled
    public static String getNetworkUrl() {
        String url = Test.isRunningTest() ? '' : Network.communitiesLanding().getUrl();
        System.debug('NegoptimHelper.getSessionId(): ' + NegoptimHelper.getSessionId());
        System.debug('Network.communitiesLanding().getUrl(): ' + url);
        return JSON.serialize(new Map<String, String> { 'url' => url, 'sessionId' => NegoptimHelper.getSessionId()});
        // return JSON.serialize(new Map<String, String> { 'url' => Network.communitiesLanding().getUrl(), 'sessionId' => NegoptimHelper.getSessionId()});
        // return JSON.serialize(new Map<String, String> { 'url' => URL.getSalesforceBaseUrl().toExternalForm(), 'sessionId' => NegoptimHelper.getSessionId()});
    }
    @AuraEnabled
    public static string getUserConnectionData(Id targetId){
        return ChatterManager.getUserConnectionData(targetId);
    }

}