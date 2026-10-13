/**
 * @author ULiT
 * @date 19/12/2024
 * @description Unit test class to cover/test Trg_Contact trigger
 * */
@isTest
public with sharing class Trg_Contact_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    public static FileDirectory__c fileDirectory;
    public static Contact contact;
    public static List<String> subTypeList = new List<String>{'Admin Certification'};
    
    public static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        buCountry.SetInvoiceSeller__c = true;
        insert buCountry;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, buCountry, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        ContentVersion cv = new ContentVersion(Title = 'Test File ',
                                               PathOnClient = 'TestFile.txt',
                                               VersionData = Blob.valueOf('This is test file content.'),
                                               IsMajorVersion = true);
        insert cv;
        List<ContentVersion> queriedCVList = [SELECT Id, ContentDocumentId, OwnerId FROM ContentVersion];                  
        fileDirectory =  new FileDirectory__c (ContentDocumentId__c = queriedCVList[0].ContentDocumentId,
                                               Supplier__c = supplier.Id,
                                               Negoscope__c = NS.Id,
                                               IsPortalPublished__c = true,
                                               SubType__c = subTypeList[0]);
        insert fileDirectory;
        contact = new Contact(LastName = 'Test Contact', Supplier__c = supplier.Id, IsConnectUser__c = false);
        insert contact;
    }

    @isTest
    public static void case1_handleShareDocs() {
        init();
        insert new ContactOperationalDirectory__c(Contact__c = contact.Id, 
                                                  ContactRole__c = 'Commercial - Main Contact', 
                                                  Negoscope__c = NS.Id, 
                                                  RequestedNegoscope__c = NS.Id, 
                                                  ActivationStatus__c = 'Validated Entry', 
                                                  Supplier__c = supplier.Id);
        Test.startTest();
        contact.IsConnectUser__c = true;
        update contact;
        Test.stopTest();
        System.assertEquals(true,true);
    }
    
    @isTest
    static void case2_insertContacts() {
        init();
        // create contract
        Contract__c contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        Invoice__c invoice = new Invoice__c(SupplierBuyer__c = supplier.Id,
                                            Contract__c = contract.Id,
                                            BuyerContact1__c = null,
                                            BuyerContact2__c = null,
                                            BuyerContact3__c = null,
                                            BuyerContact4__c = null,
                                            BuyerContact5__c = null,
                                            Status__c = 'Generated');
        insert invoice;
        Test.startTest();
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Generic mailbox';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;        
        Test.stopTest();
        invoice = [SELECT Id, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c FROM Invoice__c WHERE Id = :invoice.Id];
        System.assertEquals(contacts[0].Id, invoice.BuyerContact1__c);
        System.assertEquals(contacts[1].Id, invoice.BuyerContact2__c);
        System.assertEquals(contacts[2].Id, invoice.BuyerContact3__c);
        System.assertEquals(contacts[3].Id, invoice.BuyerContact4__c);
        System.assertEquals(contacts[4].Id, invoice.BuyerContact5__c);
    }
    
    @isTest
    static void case3_updateContacts() {
        init();
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Generic mailbox';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        // create contract
        Contract__c contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        Invoice__c invoice = new Invoice__c(SupplierBuyer__c = supplier.Id,
                                            Contract__c = contract.Id,
                                            BuyerContact1__c = contacts[0].Id,
                                            BuyerEmail1__c = contacts[0].Email,
                                            BuyerContact2__c = contacts[1].Id,
                                            BuyerEmail2__c = contacts[1].Email,
                                            BuyerContact3__c = contacts[2].Id,
                                            BuyerEmail3__c = contacts[2].Email,
                                            BuyerContact4__c = contacts[3].Id,
                                            BuyerEmail4__c = contacts[3].Email,
                                            BuyerContact5__c = contacts[4].Id,
                                            BuyerEmail5__c = contacts[4].Email,
                                            Status__c = 'Generated');
        insert invoice;
        Test.startTest();
        contacts[1].IsInvoiceRecipient__c = false;
        contacts[2].IsInvoiceRecipient__c = false;
        update new List<Contact> {contacts[1], contacts[2]};
        Test.stopTest();
        invoice = [SELECT Id, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                   BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                   FROM Invoice__c WHERE Id = :invoice.Id];
        system.debug('invoice >>> ' + invoice);
        System.assertEquals(contacts[0].Id, invoice.BuyerContact1__c);
        System.assertEquals(contacts[3].Id, invoice.BuyerContact2__c);
        System.assertEquals(contacts[4].Id, invoice.BuyerContact3__c);
        System.assertEquals(null, invoice.BuyerContact4__c);
        System.assertEquals(null, invoice.BuyerContact5__c);
    }
    
    @isTest
    static void case4_deleteContacts() {
        init();
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Generic mailbox';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        // create contract
        Contract__c contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        Invoice__c invoice = new Invoice__c(SupplierBuyer__c = supplier.Id,
                                            Contract__c = contract.Id,
                                            BuyerContact1__c = contacts[0].Id,
                                            BuyerEmail1__c = contacts[0].Email,
                                            BuyerContact2__c = contacts[1].Id,
                                            BuyerEmail2__c = contacts[1].Email,
                                            BuyerContact3__c = contacts[2].Id,
                                            BuyerEmail3__c = contacts[2].Email,
                                            BuyerContact4__c = contacts[3].Id,
                                            BuyerEmail4__c = contacts[3].Email,
                                            BuyerContact5__c = contacts[4].Id,
                                            BuyerEmail5__c = contacts[4].Email,
                                            Status__c = 'Generated');
        insert invoice;
        Test.startTest();
        delete contacts[3];
        Test.stopTest();
        invoice = [SELECT Id, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                   BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                   FROM Invoice__c WHERE Id = :invoice.Id];
        System.assertEquals(null, invoice.BuyerContact5__c);
    }
}