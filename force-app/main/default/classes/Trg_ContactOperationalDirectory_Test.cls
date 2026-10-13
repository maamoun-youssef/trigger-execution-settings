/**
 * @author ULiT
 * @date 5-11-2024
 * @description Unit test class to cover/test Trg_ContactOperationalDirectory trigger
*/
@isTest
public class Trg_ContactOperationalDirectory_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    public static Contact contact;

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
        contact = new Contact(LastName = 'Test Contact', Supplier__c = supplier.Id, IsConnectUser__c = true);
        insert contact;
    }

    @isTest
    public static void case1_checkUnicity() {
        init();
        Boolean errorFound = false;
        insert new ContactOperationalDirectory__c(Contact__c = contact.Id, Negoscope__c = NS.Id, RequestedNegoscope__c = NS.Id, ActivationStatus__c = 'Validated Entry', Supplier__c = supplier.Id);
        Test.startTest();
        // Simulating the behavior of OnBeforeInsertOrUpdate to insert a new cod entry with an already used negoscope
        try {
            insert new ContactOperationalDirectory__c(Contact__c = contact.Id, RequestedNegoscope__c = NS.Id, ActivationStatus__c = 'In Preparation', Supplier__c = supplier.Id);
        } catch (Exception ex) {
            errorFound = true;
        }
        Test.stopTest();
        System.assertEquals(true, errorFound, 'Two COD with sames Negoscope/RequestedNegoscope should not be allowed.');
    }
    
    @isTest
    static void case2_insertCODs() {
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
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Individual';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        Test.startTest();
        List<ContactOperationalDirectory__c> contactOperationalDirectories = new List<ContactOperationalDirectory__c>();
        for (Contact contact : contacts) {
            List<ContactOperationalDirectory__c> CODs = TestDataFactory.createContactOperationalDirectories(false, 1, supplier, NS, contact);
            for(ContactOperationalDirectory__c item : CODs) {
                item.IsInvoiceRecipient__c = true;
            }
            contactOperationalDirectories.addAll(CODs);
        }
        insert contactOperationalDirectories;
        Test.stopTest();
        invoice = [SELECT Id, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c FROM Invoice__c WHERE Id = :invoice.Id];
        System.assertEquals(contacts[0].Id, invoice.BuyerContact1__c);
        System.assertEquals(contacts[1].Id, invoice.BuyerContact2__c);
        System.assertEquals(contacts[2].Id, invoice.BuyerContact3__c);
        System.assertEquals(contacts[3].Id, invoice.BuyerContact4__c);
        System.assertEquals(contacts[4].Id, invoice.BuyerContact5__c);
    }
    
    @isTest
    static void case3_updateCODs() {
        init();
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Individual';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        List<ContactOperationalDirectory__c> contactOperationalDirectories = new List<ContactOperationalDirectory__c>();
        for (Contact contact : contacts) {
            List<ContactOperationalDirectory__c> CODs = TestDataFactory.createContactOperationalDirectories(false, 1, supplier, NS, contact);
            for(ContactOperationalDirectory__c item : CODs) {
                item.IsInvoiceRecipient__c = true;
            }
            contactOperationalDirectories.addAll(CODs);
        }
        insert contactOperationalDirectories;
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
        contactOperationalDirectories[1].IsInvoiceRecipient__c = false;
        contactOperationalDirectories[2].IsInvoiceRecipient__c = false;
        update new List<ContactOperationalDirectory__c> {contactOperationalDirectories[1], contactOperationalDirectories[2]};
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
    static void case4_deleteCODs() {
        init();
        // Create contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            //contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Individual';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        List<ContactOperationalDirectory__c> contactOperationalDirectories = new List<ContactOperationalDirectory__c>();
        for (Contact contact : contacts) {
            List<ContactOperationalDirectory__c> CODs = TestDataFactory.createContactOperationalDirectories(false, 1, supplier, NS, contact);
            for(ContactOperationalDirectory__c item : CODs) {
                item.IsInvoiceRecipient__c = true;
            }
            contactOperationalDirectories.addAll(CODs);
        }
        insert contactOperationalDirectories;
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
        delete contactOperationalDirectories[3];
        Test.stopTest();
        invoice = [SELECT Id, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                   BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                   FROM Invoice__c WHERE Id = :invoice.Id];
        System.assertEquals(null, invoice.BuyerContact5__c);
    }
}