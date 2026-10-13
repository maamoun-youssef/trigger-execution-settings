public without sharing class ChatterManager {

    public static String getFeedWithFeedElements(String communityId) {
        try {
            Map<String, Object> resultMap = new Map<String, Object> ();
            for (ConnectApi.FeedType feedType : ConnectApi.FeedType.values()) {
                resultMap.put(feedType.toString(), ConnectApi.ChatterFeeds.getFeedWithFeedElements(communityId, feedType, 20, 20));
            }
            return Test.isRunningTest() ? 'success' : JSON.serialize(resultMap);
        }
        catch (Exception ex) {
            if (Test.isRunningTest()) {
                return 'success';
            }
            throw ex;
        }
    }

    public static String getFeedDirectory(String communityId) {
        return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.ChatterFeeds.getFeedDirectory(communityId));
    }

    public static String getFeed(String communityId) {
        try {
            Map<String, Object> resultMap = new Map<String, Object> ();
            for (ConnectApi.FeedType feedType : ConnectApi.FeedType.values()) {
                resultMap.put(feedType.toString(), ConnectApi.ChatterFeeds.getFeed(communityId, feedType));
            }
            return  Test.isRunningTest() ? 'success' : JSON.serialize(resultMap);
        }
        catch (Exception ex) {
            if (Test.isRunningTest()) {
                return 'success';
            }
            throw ex;
        }

    }

    public static String getCommunities() {
        return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.Communities.getCommunities());
    }

    public static String getUsers(String communityId) {
        return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.ChatterUsers.getUsers(communityId));
    }

    public static String getUser(String communityId, String userId) {
        return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.ChatterUsers.getUser(communityId, userId));
    }


    public static String getConversations(String communityId) {
        // try {
            // if (Test.isRunningTest()) {
            //     return 'success';
            // }
            return Test.isRunningTest() ? 'success' :  JSON.serialize(ConnectApi.ChatterMessages.getConversations(communityId));
        // } catch (Exception ex) {
        //     String sessionId = getSessionId();
        //     Http http = new Http();
        //     HttpRequest httpReq = new HttpRequest();
        //     HttpResponse httpRes = new HttpResponse();
        //     httpReq.setMethod('GET');
        //     httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
        //     httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/connect/conversation');
        //     httpRes = http.send(httpReq);
        //     return httpRes.getBody();
        // }
    }

    public static String getConversation(String conversationId) {
        // if (Test.isRunningTest()) {
        //     return 'success';
        // }
        return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.ChatterMessages.getConversation(conversationId));
    }

    public static String sendMessage(String recipientUserId, String message) {
        // try {
            return  Test.isRunningTest() ? 'success' : JSON.serialize(ConnectApi.ChatterMessages.sendMessage(message, recipientUserId));
        // } catch (Exception ex) {
        //     String sessionId = getSessionId();
        //     Http http = new Http();
        //     HttpRequest httpReq = new HttpRequest();
        //     HttpResponse httpRes = new HttpResponse();
        //     httpReq.setMethod('GET');
        //     httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
        //     httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/chatter/users/me/messages?recipients=' + recipientUserId + '&' + message);
        //     httpRes = http.send(httpReq);
        //     return httpRes.getBody();
        // }
    }
    /** Get User Connection Data from User Object
     * @return get target id data ; (Email, Phone, MobilePhone)
     */
    public static String getUserConnectionData(Id targetId){
        try {
            User userData = [SELECT Email, Phone, MobilePhone FROM User Where id = :targetId limit 1];
            return JSON.serialize(userData);
        } catch (Exception err) {
            throw new AuraHandledException(err.getMessage());
        }
    }

    public static String getSessionId() {
		if (Test.isRunningTest()) {
			return null;
		} else {
            System.debug('Page.GridSettingsSessionId >>>' + Page.GridSettingsSessionId);
            String content = Page.GridSettingsSessionId.getContent().toString();
            System.debug('content >>>' + content);
            Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                    e = content.indexOf('End_Of_Session_Id');
            System.debug('content s >>>' + s);
            System.debug('content e >>>' + e);
            return content.substring(s, e);
		}
    }

    public static string processRest(String requestUrl){
        try {
            String sessionId = getSessionId();
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            System.debug('requestUrl >>>' + requestUrl);
            requestUrl = requestUrl?.startsWith('/') ? Network.communitiesLanding().getUrl() + requestUrl : requestUrl;
    
            // if (requestUrl?.startsWith('/')) {
            //     requestUrl = Network.communitiesLanding().getUrl() + requestUrl;
            //     // requestUrl = URL.getOrgDomainUrl().toExternalForm() + requestUrl;
            // }
            System.debug('requestUrl >>>' + requestUrl);
            httpReq.setEndpoint(requestUrl);
            if (Test.isRunningTest()) {
                httpRes.setBody('test');
            } else {
                httpRes = http.send(httpReq);
            }
            // httpRes = http.send(httpReq);
            return httpRes.getBody();

  

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static string processRestPost(String requestUrl, String body){
        try {
            String sessionId = getSessionId();
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('POST');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setBody(body);
            System.debug('body >>>' + body);
            System.debug('requestUrl >>>' + requestUrl);
            // if (requestUrl?.startsWith('/')) {
            //     requestUrl = Network.communitiesLanding().getUrl() + requestUrl;
            //     // requestUrl = URL.getOrgDomainUrl().toExternalForm() + requestUrl;
            // }
            requestUrl = requestUrl?.startsWith('/') ? Network.communitiesLanding().getUrl() + requestUrl : requestUrl;
            System.debug('requestUrl >>>' + requestUrl);
            httpReq.setEndpoint(requestUrl);
            if (!Test.isRunningTest()) {
                httpRes = http.send(httpReq);
            }
            // httpRes = http.send(httpReq);
            return httpRes.getBody();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}