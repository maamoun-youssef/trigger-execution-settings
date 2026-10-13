public without sharing class SetUserLanguageCookiesCtrl {
    String retURL;
    public SetUserLanguageCookiesCtrl() {
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        System.debug('>>>' + ApexPages.currentPage().getParameters());
    }

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
        if (String.isBlank(retURL)) {
           retURL = '/'; 
        }
        Auth.SessionManagement.finishLoginFlow(retURL);
        return new PageReference(retURL);
    }
}