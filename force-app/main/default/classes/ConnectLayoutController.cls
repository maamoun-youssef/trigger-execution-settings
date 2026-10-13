/**
 * @author ULiT
 * @date 5/27/2025
 * Advanced Settings class for NegoptimConnect
 **/

public with sharing class ConnectLayoutController {

    @AuraEnabled
    public static String initData() {
        try {
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            MainWrapper result = new MainWrapper(connectSettings);
            return JSON.serialize(result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static User getContactsInfoList() {
        // Get the current user's ID
        String currentUserId = UserInfo.getUserId();
        // Query users where user is the current user
        return [SELECT Id, Name, Contact.SelfOnboardingSteps__c FROM User  WHERE Id = :currentUserId];
    }

    @AuraEnabled(cacheable = true)
    public static User getCurrentUser() {
        return [SELECT Id,
                       Name,
                       FullPhotoUrl
                FROM User
                WHERE Id = :UserInfo.getUserId()];
    }

    @AuraEnabled(cacheable = true)
    public static String getCommunityUrl() {
       // String customPath = '/s/profile/';
        //String internalBaseUrl = URL.getOrgDomainUrl().toExternalForm().replace('.my.salesforce.com', '.my.site.com') + customPath;
        return URL.getOrgDomainUrl().toExternalForm().replace('.my.salesforce.com', '.my.site.com') + '/';
    }

    private static String sendHttpRequest(String sessionId, String endpointUrl, String method) {
        Http h = new Http();
        HttpRequest webReq = new HttpRequest();
        HttpResponse res = new HttpResponse();
        webReq.setMethod(method);
        if (sessionId != null) {
            webReq.setHeader('Authorization', 'Bearer ' + sessionId);
        }
        webReq.setEndpoint(endpointUrl);
        if (!Test.isRunningTest()) {
            res = h.send(webReq);
        } else {
            res.setBody('Test');
        }
        return res.getBody();
    }

    @AuraEnabled
    public static String getNotifications() {
        string endpointUrl = URL.getOrgDomainURL().toExternalForm() + '/services/data/v52.0/connect/notifications';
        try {
            string sessionId = NegoptimHelper.getSessionId();
            return sendHttpRequest(sessionId, endpointUrl,'GET');
        } catch (Exception ex) {
            return sendHttpRequest(UserInfo.getSessionId(), endpointUrl,'GET');
        }
    }

    @AuraEnabled
    public static String setNotificationRead(String notificationId) {
        string endpointUrl = URL.getOrgDomainURL().toExternalForm() + '/services/data/v52.0/connect/notifications/' + notificationId + '?read=true';
        try {
            return sendHttpRequest(NegoptimHelper.getSessionId(), endpointUrl, 'PATCH');
        } catch (Exception ex) {
            return sendHttpRequest(UserInfo.getSessionId(), endpointUrl, 'PATCH');
        }
    }

    @AuraEnabled(cacheable = true)
    public static String getPortalSettings() {
        try {
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            return JSON.serialize(connectSettings);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> isPageSettingActive(List<String> developerNames) {
        Map<String, Boolean> activeSettingsMap = new Map<String, Boolean>();
        if (developerNames != null && !developerNames.isEmpty()) {
            for (PageSettings__mdt setting : [
                SELECT DeveloperName, isActive__c
                FROM PageSettings__mdt
                WHERE DeveloperName IN :developerNames
            ]) {
                activeSettingsMap.put(setting.DeveloperName, setting.isActive__c);
            }
        }
        return activeSettingsMap;
    }

    @AuraEnabled(cacheable = true)
    public static List<SObject> searchBar(String searchTerm, List<String> searchableObjects) {
        if(String.isNotBlank(searchTerm)){
            String searchKey = '%' + searchTerm + '%';
            List<SObject> results = new List<SObject>();
            if(Test.isRunningTest()){
                searchableObjects = new List<String>{'ContactOperationalDirectory__c','Contact','Task','testHistory'};
            }
            for (String objName : searchableObjects) {
                try {
                    String target = objName == 'Task' ? 'Task' : (objName.endsWith('History') || objName != null  ? objName : null);
                    String field = objName == 'Task' ? 'CallObject' : (objName.endsWith('History') ? 'Field' : (objName != null ? 'Name' : null ));
                    if(target != null){
                    	String queryStr = 'SELECT Id, ' + field + ' FROM ' + target + ' WHERE ' + field + ' LIKE :searchKey';
                        List<SObject> objRecords = Database.query(queryStr);
                        results.addAll(objRecords);
                    }
                } catch (Exception ex) {
                    System.debug(ex.getMessage() + ' >>> ' + ex.getStackTraceString());
                }
            }
            return results;
        } else return null;
    }
    public class MainWrapper {
        public String prefix { get; set; }
        public Map<String, String> currentSession { get; set; }
        public ConnectSettings connectSettings { get; set; }

        public MainWrapper(ConnectSettings connectSettings) {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.connectSettings =  connectSettings;
            if (Test.isRunningTest()) {
                this.currentSession = new Map<String, String>();
            } else {
                this.currentSession = Auth.SessionManagement.getCurrentSession();
            }
        }
    }
}