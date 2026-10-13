@isTest
private class Trg_UserTest {
    private static User    accountOwner;
    private static Account acct;
    private static Contact contact;
    private static User    communityUser;
    private static UserRole role;
    private static UserRole managerRole;
    
    static void init() {
        // 1) Create an internal UserRole and a real “runner” user to own the Account
        role = new UserRole(Name = 'CEO');
        insert role;
        managerRole = new UserRole(Name = 'COO', ParentRoleId = role.Id);
        insert managerRole;
        Profile internalProfile = [
            SELECT Id 
            FROM Profile 
            WHERE Name = 'Standard User' 
            LIMIT 1
        ];
        accountOwner = new User(
            Username          = 'acctOwner' + Math.random() + '@test.com',
        Alias             = 'acOwner',
        Email             = 'acctOwner@test.com',
        EmailEncodingKey  = 'UTF-8',
        LastName          = 'Owner',
        LocaleSidKey      = 'en_US',
        LanguageLocaleKey = 'en_US',
        TimeZoneSidKey    = 'GMT',
        ProfileId         = internalProfile.Id,
        UserRoleId        = role.Id
            );
        insert accountOwner;
        System.runAs(accountOwner) {
            for (Profile p : [SELECT Name 
                  FROM Profile 
                  WHERE Name LIKE '%Community%' 
                  ORDER BY Name]) {
                System.debug(p.Name);
            }
            acct = new Account(Name = 'Portal Test Acct', OwnerId = accountOwner.Id);
            insert acct;
            contact = new Contact(
                LastName    = 'User',
            AccountId   = acct.Id,
            Email       = 'test.user@acme.com'
                );
            insert contact;
            
        }
    }
    
    @isTest
    static void updateUser() {
        init();
        Profile commProfile = [
                SELECT Id 
                FROM Profile 
                WHERE Name = 'Community Profile' 
                LIMIT 1
            ];
        communityUser = new User(
            Username = 'comm' + Math.random() + '@test.com',
        Alias = 'cUser',
        Email = 'commuser@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Portal',
        FirstName = 'Test',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        TimeZoneSidKey = 'GMT',
        ProfileId = commProfile.Id,
        ContactId = contact.Id
            );
        insert communityUser;
        communityUser.FirstName = 'dev';
        Test.startTest();
        update communityUser;
        Test.stopTest();
        contact = [SELECT FirstName FROM Contact WHERE Id = :contact.Id];
        System.debug(contact.FirstName);
        System.debug(communityUser.FirstName);
        System.assertEquals(communityUser.FirstName, contact.FirstName, 'Contact.Title should mirror the Community User FirstName'
            );
    }
}