public with sharing class Main_App_launcher_Controller {
    
    public List<AppMenuItem> appMenuItems {get; set;}
    public Main_App_launcher_Controller() {
        try {
            // check access AppMenuItem fields
            String [] appMenuItemsFields = new String [] {
                SObjectType.AppMenuItem.fields.Id.Name,
                    SObjectType.AppMenuItem.fields.Name.Name,
                    SObjectType.AppMenuItem.fields.Label.Name,
                    SObjectType.AppMenuItem.fields.ApplicationId.Name,
                    SObjectType.AppMenuItem.fields.StartUrl.Name,
                    SObjectType.AppMenuItem.fields.LogoUrl.Name,
                    SObjectType.AppMenuItem.fields.IconUrl.Name,
                    SObjectType.AppMenuItem.fields.SortOrder.Name
                    };
            if(NegoptimHelper.checkAccessibility(AppMenuItem.SObjectType, appMenuItemsFields)) {
                for (String fieldToCheck : appMenuItemsFields) {
                    this.appMenuItems = [SELECT Id, Name, Label, ApplicationId, StartUrl, LogoUrl, IconUrl
                                         FROM AppMenuItem
                                         WHERE Name IN ('myOrg','myOffer')
                                         ORDER BY SortOrder];
                }
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + ' - ' + e.getLineNumber()));
        }
    }
    
    @AuraEnabled
    public static String loadApps() {
        // check access AppMenuItem fields
        String [] appMenuItemsFields = new String [] {
            SObjectType.AppMenuItem.fields.Id.Name,
                SObjectType.AppMenuItem.fields.Name.Name,
                SObjectType.AppMenuItem.fields.Label.Name,
                SObjectType.AppMenuItem.fields.ApplicationId.Name,
                SObjectType.AppMenuItem.fields.StartUrl.Name,
                SObjectType.AppMenuItem.fields.LogoUrl.Name,
                SObjectType.AppMenuItem.fields.IconUrl.Name,
                SObjectType.AppMenuItem.fields.SortOrder.Name
                };
        if(NegoptimHelper.checkAccessibility(AppMenuItem.SObjectType, appMenuItemsFields)) {
            List<AppWrapper> appMenus = (List<AppWrapper>) JSON.deserialize(JSON.serialize([SELECT Id, Name, Label, ApplicationId, StartUrl, LogoUrl, IconUrl
                                                                         FROM AppMenuItem
                                                                         WHERE Name IN ('myOrg','myOffer')
                                                                         ORDER BY SortOrder]), List<AppWrapper>.class);
            for (AppWrapper item : appMenus) {
                item.lightningId = String.valueOf(item.ApplicationId).right(13);
            }
            return JSON.serialize(appMenus);
        }
        return null;
    }
    public class AppWrapper {
        String Name;
        String Label;
        Id ApplicationId;
        String StartUrl;
        String LogoUrl;
        String IconUrl;
        String lightningId;
    }
}