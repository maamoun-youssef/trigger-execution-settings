public without sharing class SetUserLangCookiesCtrlExt {

    private Site connectSite {
        get {
            if(connectSite == null) {
                List<Site> siteList = [SELECT Id, UrlPathPrefix FROM Site WHERE UrlPathPrefix = 'NegoptimConnect'];
                if (!siteList.isEmpty()) {
                    connectSite = siteList[0];
                }
            }
            return connectSite;
        }
        set;
    }

    public String sitePath {
        get {
            return connectSite?.UrlPathPrefix;
        }
    }

    public String siteId {
        get {
            return connectSite?.Id;
        }
    }
    
     public String userLanguage {
        get {
            return UserInfo.getLanguage();
        }
    }

    public PageReference finishLoginFlow() {
        Auth.SessionManagement.finishLoginFlow('/');
        return new PageReference('/');
    }
}