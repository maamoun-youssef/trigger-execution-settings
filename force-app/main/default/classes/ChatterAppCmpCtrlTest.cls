@isTest
private class ChatterAppCmpCtrlTest {
    private static UserRole role;
    private static User currentUser;
    private static Contact contact;
    private static Contact contact2;



    static void init() {
        // Create Role.
        role = new UserRole(Name = 'CEO');
        insert role;
        //update user
        currentUser = new User(Id = UserInfo.getUserId());
        currentUser.UserRoleId = role.Id;
        update currentUser;
        System.debug('currentUser: ' + JSON.serialize(currentUser));
        // ConnectApi.FeedType cf = new ConnectApi.FeedType();
        ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(new ConnectApi.FeedItem());
        testItemList.add(new ConnectApi.FeedItem());
        testPage.elements = testItemList;

        // Set the test data
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null,
            ConnectApi.FeedType.News, 'me', testPage);
        // ConnectApiMock mock = new ConnectApiMock();
        // Test.setMock(ConnectApiMock.class, mock);
    }
    @isTest
    static void myUnitTest() {
        init();
        System.debug('currentUser.Id: ' + currentUser.Id);
        // System.debug('getNetworkUrl: ' + JSON.serialize(ChatterAppCmpCtrl.getNetworkUrl()));
        // System.debug('getCommunities: ' + JSON.serialize(ChatterAppCmpCtrl.getCommunities()));
        // System.debug('getUserConnectionData: ' + JSON.serialize(ChatterAppCmpCtrl.getUserConnectionData(currentUser.Id)));
    }
    @isTest
    static void mygetUserConnectionData() {

        init();
        Test.startTest();
        // Set up the mock response
        // Test.setMock(HttpCalloutMock.class, new ConnectApiMock(mockFeedResponse));
        
        // Act
        System.debug('currentUser.Id: ' + currentUser.Id);
        String result2 = ChatterAppCmpCtrl.getUserConnectionData(currentUser.Id);
        System.debug('result2: ' + result2);
        
        // Assert
        System.assertNotEquals(null, result2);
        // System.assert(result.contains('feedId'));
        Test.stopTest();
    }
    @isTest
    static void testprocessRest() {
        init();
        Test.startTest();
        System.debug('currentUser.Id: ' + currentUser.Id);
        String result2 = ChatterAppCmpCtrl.processRest('');
        System.debug('result2: ' + result2);
        // Assert
        System.assertNotEquals(null, result2);
        Test.stopTest();
    }   
     @isTest
    static void testprocessRestPost() {
        init();
        Test.startTest();
        System.debug('currentUser.Id: ' + currentUser.Id);
        String result2 = ChatterAppCmpCtrl.processRestPost('', 'test');
        System.debug('result2: ' + result2);
        // Assert
        System.assertNotEquals(null, result2);
        Test.stopTest();
    }       
     @isTest
    static void testgetNetworkUrl() {
        init();
        Test.startTest();
        System.debug('currentUser.Id: ' + currentUser.Id);
        String result2 = ChatterAppCmpCtrl.getNetworkUrl();
        System.debug('result2: ' + result2);
        // Assert
        System.assertNotEquals(null, result2);
        Test.stopTest();
    }   

    @isTest
    static void testGetFeedWithFeedElements() {
        // Test scenario when running in a test context
        String testCommunityId = '00Dxxxxxxxxxxxx'; // Example community ID

        // Call the method while running a test
        Test.startTest();
        String result = ChatterAppCmpCtrl.getFeedWithFeedElements(testCommunityId);
        Test.stopTest();

        // Verify that the test scenario returned 'Success'
        System.assertEquals('success', result, 'Expected result to be "Success" when running in test mode');
    }

    @isTest
    public static void testGetFeedDirectory() {
        String testCommunityId = '00Dxxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getFeedDirectory(testCommunityId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetFeed() {
        String testCommunityId = '00Dxxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getFeed(testCommunityId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetCommunities() {
        Test.startTest();
        String result = ChatterAppCmpCtrl.getCommunities();
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetUsers() {
        String testCommunityId = '00Dxxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getUsers(testCommunityId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetUser() {
        String testCommunityId = '00Dxxxxxxxxxxxx';
        String testUserId = '005xxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getUser(testCommunityId, testUserId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetConversations() {
        String testCommunityId = '00Dxxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getConversations(testCommunityId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testGetConversation() {
        String testConversationId = '0D5xxxxxxxxxxxx';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.getConversation(testConversationId);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }

    @isTest
    public static void testSendMessage() {
        String testRecipientUserId = '005xxxxxxxxxxxx';
        String testMessage = 'Hello, this is a test message!';
        
        Test.startTest();
        String result = ChatterAppCmpCtrl.sendMessage(testRecipientUserId, testMessage);
        Test.stopTest();

        System.assertEquals('success', result, 'Expected "success" when running in test mode');
    }
}