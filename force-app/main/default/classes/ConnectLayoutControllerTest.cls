@isTest
public with sharing class ConnectLayoutControllerTest {
    @isTest
    static void getCurrentUserTest() {
        User currentUser = ConnectLayoutController.getCurrentUser();
        System.debug('currentUser: ' + JSON.serialize(currentUser));
        System.assertNotEquals(null, currentUser);
    }
    @isTest
    static void getNotificationsTest() {
        String notification = ConnectLayoutController.getNotifications();
        System.assertEquals('Test', notification);
    }

    @isTest
    static void getPortalSettingsTest() {
        String settings = ConnectLayoutController.getPortalSettings();
        System.assertNotEquals(null, settings);
    }

    @isTest
    static void setNotificationReadTest() {
        string setNotification = ConnectLayoutController.setNotificationRead('');
        System.assertEquals('Test', setNotification);    
    }

    @isTest
    static void searchBarTest(){
        List<SObject> blankSearch = ConnectLayoutController.searchBar('', null);
        System.assertEquals(null, blankSearch);
        System.debug('searchBar: ' + JSON.serialize(ConnectLayoutController.searchBar('test', null)));
    }
    @isTest
    static void getContactsInfoListTest() {
        User currentUser = ConnectLayoutController.getContactsInfoList();
        System.assertNotEquals(null, currentUser);
    }
    @isTest
    static void getCommunityUrlTest() {
       String link = ConnectLayoutController.getCommunityUrl();
       System.assertNotEquals(null, link);
    }
}