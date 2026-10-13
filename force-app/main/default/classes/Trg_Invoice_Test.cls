/**
 * @author ULiT
 * @date 02/12/2024
 * @description Unit test class to test all cases of Trg_Invoice
 * */
@isTest
private class Trg_Invoice_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c buCountry;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static List<Invoice__c> invoices;
    private static List<InvoiceDetail__c> invoiceDetails;
    private static GlobalLocation__c globalLocation;
    private static List<Contact> contacts;
    private static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(true, buCountry, true);
        buCountry.Supplier__c = supplier.Id;
        buCountry.SetInvoiceSeller__c = true;
        buCountry.Status__c = 'Open';
        update buCountry;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        List<NegoScope__c> nsList = new List<NegoScope__c> {
            TestDataFactory.createNS(false, supplier.Id),
            TestDataFactory.createNS(false, supplier.Id),
            TestDataFactory.createNS(false, supplier.Id),
            TestDataFactory.createNS(false, supplier.Id),
            TestDataFactory.createNS(false, supplier.Id)
        };
        insert nsList;
        // create contract
        contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        contract.t_IsInvoiceable__c = true;
        contract.t_invoicingMode__c = 'InvoiceableAutomatic';
        insert contract;
        contract.t_invoicingMode__c = 'InvoiceableAutomatic';
        contract.t_IsInvoiceable__c = true;
        update contract;
        // Create contacts
        contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact contact = TestDataFactory.createContact(false, null);
            contact.FirstName = 'Contact' + i;
            contact.LastName = 'Test';
            contact.Email = 'contact' + i + '@example.com';
            contact.Supplier__c = supplier.Id;
            contact.Type__c = 'Generic mailbox';
            contact.IsInvoiceRecipient__c = true;
            contacts.add(contact);
        }
        insert contacts;
        // Create NegoScope
        //NegoScope__c negoScope = TestDataFactory.createNegoScope(true, supplier, 'Negoscope1');
        // Create ContactOperationalDirectories
        List<ContactOperationalDirectory__c> contactOperationalDirectories = new List<ContactOperationalDirectory__c>();
        Map<String, NegoScope__c> NSrolesMap = new Map<String, NegoScope__c> {
            'Commercial - Main Contact' => NS,
            'Commercial - Secondary Contact' => nsList.get(0),
            'Legal - Main Contact' => nsList.get(1),
            'Legal - Secondary Contact' => nsList.get(2),
            'Accounting - Main Contact' => nsList.get(3),
            'Accounting - Secondary Contact' => nsList.get(4)
        };
        for (Contact contact : contacts) {
            for (String roleName : NSrolesMap.keySet()) {
                ContactOperationalDirectory__c cod = TestDataFactory.createContactOperationalDirectories(false, 1, supplier, NSrolesMap.get(roleName), contact)[0];
                cod.ContactRole__c = roleName;
                contactOperationalDirectories.add(cod);
            }
        }
        insert contactOperationalDirectories;
        InvoicePlanning__c invPlanning = new InvoicePlanning__c();
        invPlanning.RecordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(InvoicePlanning__c.SObjectType).get('Invoice');
        invPlanning.Name = 'PCIP2';
        invPlanning.SeriesPeriodP__c = 'Month';
        invPlanning.SeriesBaseP__c = 'ActualYTD';
        invPlanning.SeriesSequenceP__c = 1;
        invPlanning.SeriesStartDateP__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodF__c = 'Month';
        invPlanning.SeriesBaseF__c = 'ActualYTD';
        invPlanning.SeriesSequenceF__c = 1;
        invPlanning.SeriesStartDateF__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageP__c = 100;
        invPlanning.SeriesPeriodU__c = 'Month';
        invPlanning.SeriesBaseU__c = 'ActualYTD';
        invPlanning.SeriesSequenceU__c = 1;
        invPlanning.SeriesStartDateU__c = Date.newInstance(2020, 1, 1);
        invPlanning.DownPaymentYECoverageU__c = 100;
        insert invPlanning;
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffCondition.VAT_Type__c = 'Rebate';
        Pol_Com_Condition__c tariffCondition2 = TestDataFactory.createTariffCondition(false, 1, 1);
        tariffCondition2.VAT_Type__c = 'Rebate';
        tariffCondition2.InvoicePlanning__c = invPlanning.Id;
        tariffCondition2.Acc_Document_Type__c = 'DownPaymentInvoice';
        tariffCondition2.Is_Tariff_Condition__c = false;
        insert new List<Pol_Com_Condition__c> {tariffCondition, tariffCondition2};
        // Create Country__c
        Country__c country = new Country__c(Name = 'France', Code__c = 'FR', Zone__c = 'None');
        insert country;
        // Create GlobalLocation__c
        globalLocation = new GlobalLocation__c(Name = 'Administrative',
                                               Functions__c = 'Administrative',
                                               Status__c = 'Open',
                                               Supplier__c = contract.Supplier__c,
                                               BusinessUnit__c = contract.BusinessUnitContract__c,
                                               Country__c = country.Id);
        insert globalLocation;
        Tax__c VAT1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VAT1.RecordTypeId = taxRTIds.get('VAT');
        VAT1.BusinessUnitVAT__c = buCountry.Id;
        VAT1.Name = 'VAT0';
        VAT1.Code__c = 'VAT0';
        VAT1.TaxRate__c = 20;
        VAT1.ListingOrder__c = '1';
        insert VAT1;
        Tax__c VATRule1 = TestDataFactory.createTax(false, buCountry, buCountry);
        VATRule1.RecordTypeId = taxRTIds.get('VATRule');
        VATRule1.TaxApplied__c = VAT1.Id;
        VATRule1.BusinessUnitVAT__c = buCountry.Id;
        VATRule1.Name = 'VATFR20';
        VATRule1.Code__c = 'VATFR20';
        VATRule1.Category__c = 'Rebate';
        VATRule1.TaxRate__c = 20;
        VATRule1.IsForeignSupplier__c = true;
        VATRule1.Zone__c = 'None';
        insert VATRule1;
        // insert condition;
        condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.YTDFact__c = 1000;
        condition.value_per__c = 20;
        condition.Valid__c = true;
        condition.Invoice_base__c = 'ActualYTD';
        condition.Invoice_period__c = 'Month';
        condition.Invoice_sequence__c = 1;
        condition.t_IsInvoiceable__c = true;
        condition.t_invoicingMode__c = 'InvoiceableAutomatic';
        condition.Base_TO_Actual__c = 5000;
        insert condition;
        /*condition.t_IsInvoiceable__c = true;
        condition.t_invoicingMode__c = 'InvoiceableAutomatic';
        update condition;*/
        invoices = [SELECT Id, TotalAmount__c, TotalAmountwVAT__c, Status__c, FiscalYear__c, AccDocType__c FROM Invoice__c];
        invoiceDetails = [SELECT Id, DetailAmount__c, DISCLineD__c FROM InvoiceDetail__c];
    }
    @isTest
    static void case1_validateInvoice() {
        init();
        Test.StartTest();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        firstInvoice.Status__c = 'Validated';
        update firstInvoice;
        Test.StopTest();
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c,Invoice_base__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        InvoiceDetail__c invDetail1 = [SELECT Id, Invoice__r.TotalAmount__c,invoice__r.status__c,Invoice__r.AccDoc__c,Invoice__r.AccDocType__c, DetailAmount__c from InvoiceDetail__c where Id =: firstInvoiceDetail.Id];
        System.assertEquals(invDetail1.DetailAmount__c, condition.Already_Invoiced__c);
        System.assertEquals(0, condition.Already_Invoiced_Edited__c);
    }
    @isTest
    static void case2_massValidateInvoice() {
        init();
        Test.StartTest();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        firstInvoice.Status__c = 'Validated';
        Invoice__c secondInvoice = invoices.get(1);
        secondInvoice.Status__c = 'Validated';
        InvoiceDetail__c secondInvoiceDetail = invoiceDetails.get(1);
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        Test.StopTest();
        System.debug(' InvoiceDetail__c >>>> ' + [SELECT Id, DetailAmount__c, Invoice__r.Status__c from InvoiceDetail__c]);
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        InvoiceDetail__c invDetail1 = [SELECT Id, Invoice__r.TotalAmount__c,invoice__r.status__c,Invoice__r.AccDoc__c,Invoice__r.AccDocType__c, DetailAmount__c from InvoiceDetail__c where Id =: firstInvoiceDetail.Id];
        InvoiceDetail__c invDetail2 = [SELECT Id, Invoice__r.TotalAmount__c,invoice__r.status__c,Invoice__r.AccDoc__c,Invoice__r.AccDocType__c, DetailAmount__c from InvoiceDetail__c where Id =: secondInvoiceDetail.Id];
        System.assertEquals(0, condition.Already_Invoiced_Edited__c);
        System.assertEquals(invDetail1.DetailAmount__c + invDetail2.DetailAmount__c, condition.Already_Invoiced__c);
    }
    @isTest
    static void case3_printInvoice() {
        init();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        firstInvoice.Status__c = 'Validated';
        update firstInvoice;
        Test.startTest();
        firstInvoice.Status__c = 'Printed';
        update firstInvoice;
        Test.stopTest();
        Map<Id, InvoiceDetail__c> invDetailMap = new Map<Id, InvoiceDetail__c>([SELECT Id, invoice__r.TotalAmount__c, DetailAmount__c from InvoiceDetail__c where Id = :firstInvoiceDetail.Id]);
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced_Edited__c);
    }
    @isTest
    static void case4_massPrintInvoice() {
        init();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        Invoice__c secondInvoice = invoices.get(1);
        InvoiceDetail__c secondInvoiceDetail = invoiceDetails.get(1);
        firstInvoice.Status__c = 'Validated';
        secondInvoice.Status__c = 'Validated';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        Test.StartTest();
        firstInvoice.Status__c = 'Printed';
        secondInvoice.Status__c = 'Printed';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        Test.StopTest();
        condition = [SELECT Id, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        Map<Id, InvoiceDetail__c> invDetailMap = new Map<Id, InvoiceDetail__c>([SELECT Id, Invoice__r.TotalAmount__c, DetailAmount__c from InvoiceDetail__c where Id IN (:firstInvoiceDetail.Id, :secondInvoiceDetail.Id)]);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c + invDetailMap.get(secondInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced_Edited__c);
    }
    @isTest
    static void case5_cancelInvoice() {
        init();
        Test.StartTest();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        firstInvoice.Status__c = 'Validated';
        update firstInvoice; 
        firstInvoice.Status__c = 'Printed';
        update firstInvoice;
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        Map<Id, InvoiceDetail__c> invDetailMap = new Map<Id, InvoiceDetail__c>([SELECT Id, invoice__r.TotalAmount__c, DetailAmount__c from InvoiceDetail__c where Id = :firstInvoiceDetail.Id]);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced__c);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced_Edited__c);
        firstInvoice.Status__c = 'Cancelled';
        update firstInvoice;
        Test.stopTest();
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        invDetailMap = new Map<Id, InvoiceDetail__c>([SELECT Id, invoice__r.TotalAmount__c, DetailAmount__c from InvoiceDetail__c where Id = :firstInvoiceDetail.Id]);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced__c);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced_Edited__c);
    }
    @isTest
    static void case6_massCancelInvoice() {
        init();
        Test.StartTest();
        Invoice__c firstInvoice = invoices.get(0);
        Invoice__c secondInvoice = invoices.get(1);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        InvoiceDetail__c secondInvoiceDetail = invoiceDetails.get(1);
        firstInvoice.Status__c = 'Validated';
        secondInvoice.Status__c = 'Validated';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        firstInvoice.Status__c = 'Printed';
        secondInvoice.Status__c = 'Printed';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        firstInvoice.Status__c = 'Cancelled';
        secondInvoice.Status__c = 'Cancelled';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
        Test.StopTest();
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        Map<Id, InvoiceDetail__c> invDetailMap = new Map<Id, InvoiceDetail__c>([SELECT Id, Invoice__r.TotalAmount__c, DetailAmount__c from InvoiceDetail__c where Id IN (:firstInvoiceDetail.Id, :secondInvoiceDetail.Id)]);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c + invDetailMap.get(secondInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced__c);
        System.assertEquals(invDetailMap.get(firstInvoiceDetail.Id).DetailAmount__c + invDetailMap.get(secondInvoiceDetail.Id).DetailAmount__c, condition.Already_Invoiced_Edited__c);
    }
    @isTest
    static void case7_creditNote() {
        init();
        Test.startTest();
        Invoice__c firstInvoice = invoices.get(0);
        Invoice__c secondInvoice = invoices.get(1);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        InvoiceDetail__c secondInvoiceDetail = invoiceDetails.get(1);
        firstInvoice.Status__c = 'Validated';
        secondInvoice.Status__c = 'Validated';
        update new List<Invoice__c> {firstInvoice, secondInvoice};
            condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        Invoice__c creditNote = TestDataFactory.createCreditNote(true, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        InvoiceDetail__c creditNoteDetail = TestDataFactory.createInvoiceDetail(true, creditNote.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        creditNote.Status__c = 'Validated';
        update creditNote;
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        creditNote.Status__c = 'Printed';
        creditNote.FiscalYear__c = 2025;
        creditNote.AccDocType__c = 'CreditNote';
        update creditNote;
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        creditNote.Status__c = 'Cancelled';
        update creditNote;
        Test.stopTest();
        condition = [SELECT Id, Already_Invoiced__c, Already_Invoiced_Edited__c FROM Contract_Discount__c WHERE Id = :condition.Id];
    }
    @isTest
    static void case8_printActualInvoices() {
        init();
        Invoice__c firstInvoice = invoices.get(0);
        InvoiceDetail__c firstInvoiceDetail = invoiceDetails.get(0);
        firstInvoiceDetail.DetailAmount__c = 0;
        update firstInvoiceDetail;
        Test.startTest();
        firstInvoice.Status__c = 'Validated';
        update firstInvoice;
        Test.stopTest();
        firstInvoiceDetail = [SELECT Id, DISCLineD__r.YTDRestToInvoice__c, DISCLineD__r.Already_Invoiced__c, Invoice__r.TotalAmount__c,
                              DetailAmount__c, DetailNetPrice__c, DetailGrossPrice__c
                              FROM InvoiceDetail__c
                              WHERE Id = :firstInvoiceDetail.Id];
        System.assertEquals(1000, firstInvoiceDetail.DISCLineD__r.Already_Invoiced__c);
        System.assertEquals(1000, firstInvoiceDetail.Invoice__r.TotalAmount__c);
        System.assertEquals(1000, firstInvoiceDetail.DetailAmount__c);
        System.assertEquals(1000, firstInvoiceDetail.DetailNetPrice__c);
        System.assertEquals(1000, firstInvoiceDetail.DetailGrossPrice__c);
    }
    @isTest
    static void case9_generateInvoiceNumber() {
        init();
        Invoice__c invoiceBefore = invoices.get(0);
        invoiceBefore.Status__c = 'Printed';
        invoiceBefore.FiscalYear__c = 2025;
        invoiceBefore.AccDocType__c = 'CreditNote';
        Test.startTest();
        update invoiceBefore;
        Test.stopTest();
        Invoice__c invoiceAfter = [SELECT Id, TotalAmount__c, Status__c, FiscalYear__c, AccDocType__c, InvNumberPrefix__c
                                   FROM Invoice__c
                                   WHERE Id = :invoiceBefore.Id
                                   LIMIT 1];
        InvoiceSettings invoiceSettings = InvoiceSettings.loadInvoiceSettings();
        FormulaEval.FormulaInstance instance = Formula.builder()
                                                .withReturnType(FormulaEval.FormulaReturnType.String)
                                                .withType(Invoice__c.SObjectType)
                                                .withFormula(invoiceSettings.numberPrefixFormula)
                                                .build();
        System.assertEquals(invoiceAfter.InvNumberPrefix__c, (String) instance.evaluate(invoiceBefore));
    }
    @isTest
    static void case10_afterDelete() {
        init();
        Invoice__c invoiceToDelete = invoices.get(0);
        InvoiceLink__c invoiceLink = new InvoiceLink__c(Invoice__c = invoiceToDelete.Id, InvoiceLinked__c = invoices.get(1).Id);
        insert invoiceLink;
        Test.startTest();
        delete invoiceToDelete;
        Test.stopTest();
        List<InvoiceDetail__c> invoiceDetails = [SELECT Id FROM InvoiceDetail__c WHERE Invoice__c = :invoiceToDelete.Id];
        List<InvoiceLink__c> invoiceLinks = [SELECT Id FROM InvoiceLink__c WHERE Invoice__c = :invoiceToDelete.Id];
        System.assertEquals(0, invoiceDetails.size());
        System.assertEquals(0, invoiceLinks.size());
    }
    @isTest
    static void case11_updateDelete() {
        init();
        Invoice__c invoiceToDelete = invoices.get(0);
        InvoiceLink__c invoiceLink = new InvoiceLink__c(Invoice__c = invoiceToDelete.Id, InvoiceLinked__c = invoices.get(1).Id);
        insert invoiceLink;
        Test.startTest();
        invoiceToDelete.Status__c = 'Deleted';
        update invoiceToDelete;
        Test.stopTest();
        List<InvoiceLink__c> invoiceLinks = [SELECT Id, Status__c FROM InvoiceLink__c WHERE Invoice__c = :invoiceToDelete.Id];
        for (InvoiceLink__c item : invoiceLinks) {
            System.assertEquals('Deleted', item.Status__c);
        }
        invoiceToDelete.Status__c = 'Generated';
        update invoiceToDelete;
        invoiceLinks = [SELECT Id, Status__c FROM InvoiceLink__c WHERE Invoice__c = :invoiceToDelete.Id];
        for (InvoiceLink__c item : invoiceLinks) {
            System.assertEquals('Open', item.Status__c);
        }
    }

    @isTest
    static void case12_updateContacts() {
        init();
        // List<Contact> contacts = new List<Contact>();
        // for (Integer i = 0; i < 5; i++) {
        //     Contact contact = TestDataFactory.createContact(false, null);
        //     contact.FirstName = 'Contact' + i;
        //     contact.LastName = 'Test';
        //     contact.Email = 'contact' + i + '@example.com';
        //     contact.Supplier__c = supplier.Id;
        //     contact.Type__c = 'Generic mailbox';
        //     contact.IsInvoiceRecipient__c = true;
        //     contacts.add(contact);
        // }
        // insert contacts;
        // NegoScope__c negoScope = TestDataFactory.createNegoScope(true, supplier, 'Negoscope1');
        // for (Contact contact : contacts) {
        //     TestDataFactory.createContactOperationalDirectories(
        //         true,
        //         5,
        //         supplier,
        //         negoScope,
        //         contact
        //     );
        // }
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            Invoice__c inv = new Invoice__c(
                SupplierBuyer__c = supplier.Id,
                Contract__c = contract.Id,
                BuyerContact1__c = null,
                BuyerContact2__c = null,
                BuyerContact3__c = null,
                BuyerContact4__c = null,
                BuyerContact5__c = null,
                BuyerEmail1__c = null,
                BuyerEmail2__c = null,
                BuyerEmail3__c = null,
                BuyerEmail4__c = null,
                BuyerEmail5__c = null
            );
            invoicesToInsert.add(inv);
        }
        insert invoicesToInsert;
        Test.startTest();
        Trg_Invoice_Handler.OnBeforeInsert(invoicesToInsert, new Map<Id, Invoice__c>());
        Test.stopTest();
        List<Invoice__c> updatedInvoices = [SELECT Id, Contract__c, BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                                            BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                                            FROM Invoice__c
                                            WHERE Id IN :invoicesToInsert];
        for (Invoice__c inv : updatedInvoices) {
            System.assertNotEquals(null, inv.BuyerContact1__c, 'BuyerContact1 should be populated');
            System.assertNotEquals(null, inv.BuyerContact2__c, 'BuyerContact2 should be populated');
            System.assertNotEquals(null, inv.BuyerContact3__c, 'BuyerContact3 should be populated');
            System.assertNotEquals(null, inv.BuyerContact4__c, 'BuyerContact4 should be populated');
            System.assertNotEquals(null, inv.BuyerContact5__c, 'BuyerContact5 should be populated');
            System.assertNotEquals(null, inv.BuyerEmail1__c, 'BuyerEmail1 should be populated');
            System.assertNotEquals(null, inv.BuyerEmail2__c, 'BuyerEmail2 should be populated');
            System.assertNotEquals(null, inv.BuyerEmail3__c, 'BuyerEmail3 should be populated');
            System.assertNotEquals(null, inv.BuyerEmail4__c, 'BuyerEmail4 should be populated');
            System.assertNotEquals(null, inv.BuyerEmail5__c, 'BuyerEmail5 should be populated');
            System.assertNotEquals(null, inv.Contract__c, 'Contract should be populated in the invoice');
            System.assertEquals(contract.Id, inv.Contract__c, 'The contract ID should be correctly set');
        }
    }
    
    @isTest
    static void case13_printInvoice_CreditNote() {
        init();
        // Create Invoice
        Invoice__c invoice = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.PrintDate__c = Date.today();
        invoice.Status__c = 'Printed';
        invoice.AccDoc__c = 'DownPaymentInvoice';
        invoice.BusinessUnitSeller__c = buCountry.Id;
        invoice.TotalAmount__c = 1000;
        invoice.TotalAmountwVAT__c = 1000;
        // Create CreditNote
        Invoice__c invoiceCreditNote = invoice.clone(false);
        invoiceCreditNote.Status__c = 'Generated';
        invoiceCreditNote.AccDoc__c = 'CreditNote';
        invoiceCreditNote.InvDate__c = Date.today();
        insert new List<Invoice__c>{invoice, invoiceCreditNote};
        // Create invoiceDetail
        InvoiceDetail__c invoiceDetail = TestDataFactory.createInvoiceDetail(false, invoice.Id, condition.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetail.DetailAmount__c = 1000;
        invoiceDetail.DetailVATRate__c = 1;
        // Create invoiceDetailCreditNote
        InvoiceDetail__c invoiceDetailCreditNote = invoiceDetail.clone(false);
        invoiceDetailCreditNote.Invoice__c = invoiceCreditNote.Id;
        insert new List<InvoiceDetail__c>{invoiceDetail, invoiceDetailCreditNote};
        // Create InvoiceLink__c
        InvoiceLink__c invoiceLink = new InvoiceLink__c(Invoice__c = invoiceCreditNote.Id, InvoiceLinked__c = invoice.Id);
        insert invoiceLink;
        Test.startTest();
        invoiceCreditNote.Status__c = 'Printed';
        update invoiceCreditNote;
        Test.stopTest();
        system.assertEquals(2, [SELECT COUNT() FROM Payment__c WHERE PaymentType__c = 'Lettering']);
        system.assertEquals(2, [SELECT COUNT() FROM PaymentDetail__c WHERE LetteringType__c = 'PaidInvoiceLettering']);
    }

    @IsTest
    static void case14_validateInvoiceStatus_error() {
        init();
        InvoiceSettings.InvoiceValidationRules invoiceValidationRules = Trg_Invoice_Handler.invoiceSettingsRecord.invoiceValidationRules;
        invoiceValidationRules.intervalStatus = true;
        invoiceValidationRules.intervalStart = 5;
        invoiceValidationRules.intervalEnd = 500;
        Invoice__c firstInvoice = invoices.get(0);
        firstInvoice.TotalAmountwVAT__c = 7;
        firstInvoice.Status__c = 'Generated';
        firstInvoice.IsUpdatedFromYTD__c = false;
        update firstInvoice;
        Test.startTest();
        firstInvoice.Status__c = 'Validated';
        update firstInvoice;
        Test.stopTest();
        firstInvoice = [SELECT Id, Status__c FROM Invoice__c WHERE Id = :firstInvoice.Id LIMIT 1];
        System.assertEquals('NotValidated', firstInvoice.Status__c, 'Status should become NotValidated');
    }
    
    @IsTest
    static void case15_updateCommercialPlansForDeletedInvoice() {
        //init();
        year = System.Today().year();
        Id rootId = TestDataFactory.getHierarchyRootId();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        buCountry = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        // Create Supplier
        supplier = TestDataFactory.createSupplier(true, buCountry, true);
        buCountry.Supplier__c = supplier.Id;
        buCountry.SetInvoiceSeller__c = true;
        buCountry.Status__c = 'Open';
        update buCountry;
        Hierarchy__c department = TestDataFactory.createHierarchyDepartment(true, rootId);
        Hierarchy__c section = TestDataFactory.createHierarchySection(true, department.Id);
        Product2 product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        product.VATRate__c = 0;
        insert product;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Create contract.
        contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
        insert contract;
        // Insert Policy - Tariff conditions.
        Pol_Com_Condition__c tariffConditionSellIn = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffConditionSellIn.SetCommercialPlanDetail1__c = true;
        tariffConditionSellIn.IsCounterpartyInvoiceable__c = true;
        //tariffConditionSellIn.PromoStatementType__c = 'SellIn';
        tariffConditionSellIn.VAT_Type__c = 'Finance';
        Pol_Com_Condition__c tariffConditionSellOut = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffConditionSellOut.SetCommercialPlanDetail1__c = true;
        tariffConditionSellOut.IsCounterpartyInvoiceable__c = true;
        //tariffConditionSellOut.PromoStatementType__c = 'SellOut';
        tariffConditionSellOut.VAT_Type__c = 'Product';
        Pol_Com_Condition__c tariffConditionServices = TestDataFactory.createTariffCondition(false, 0, 1);
        tariffConditionServices.SetCommercialPlanDetail1__c = true;
        tariffConditionServices.IsCounterpartyInvoiceable__c = true;
        //tariffConditionServices.PromoStatementType__c = 'Services';
        tariffConditionServices.VAT_Type__c = 'Service';
        insert new List<Pol_Com_Condition__c> { tariffConditionSellIn, tariffConditionSellOut, tariffConditionServices };
        // Create Contract_Discount__c
        Contract_Discount__c discountSellIn = TestDataFactory.createCondition(false, tariffConditionSellIn, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discountSellIn.Value_per__c = 10;
        Contract_Discount__c discountSellOut = TestDataFactory.createCondition(false, tariffConditionSellOut, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discountSellOut.Value_per__c = 10;
        Contract_Discount__c discountServices = TestDataFactory.createCondition(false, tariffConditionServices, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        discountServices.Value_per__c = 10;
        insert new List<Contract_Discount__c> { discountSellIn, discountSellOut, discountServices };
        // Create CommercialPlan__c
        CommercialPlan__c cpParent = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpParent.Name = 'ParentCP';
        cpParent.Hierarchy__c = department.Id;
        cpParent.BusinessUnitTarget__c = buCountry.Id;
        cpParent.Supplier__c = supplier.Id;
        cpParent.Status__c = 'Validated';
        insert cpParent;
        CommercialPlan__c cpSellIn = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellIn.Supplier__c = supplier.Id;
        cpSellIn.BusinessUnitTarget__c = buCountry.Id;
        cpSellIn.CommercialPlanParent__c = cpParent.Id;
        cpSellIn.Contract__c = contract.Id;
        cpSellIn.Contract_Discount__c = discountSellIn.Id;
        cpSellIn.Pol_Com_Condition__c = tariffConditionSellIn.Id;
        cpSellIn.PromoAgreementType__c = 'CallOffAgreementSellIn';
        cpSellIn.Status__c = 'Validated';
        cpSellIn.SellInDiscountMassValueInvoice__c = 1000;
        CommercialPlan__c cpSellOut = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpSellOut.Supplier__c = supplier.Id;
        cpSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpSellOut.CommercialPlanParent__c = cpParent.Id;
        cpSellOut.Contract__c = contract.Id;
        cpSellOut.Contract_Discount__c = discountSellOut.Id;
        cpSellOut.Pol_Com_Condition__c = tariffConditionSellOut.Id;
        cpSellOut.PromoAgreementType__c = 'AgencyAgreement'; // SellOut
        cpSellOut.Status__c = 'Validated';
        cpSellOut.SellOutDiscMassValueContribInvoice__c = 1000;
        CommercialPlan__c cpServices = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        cpServices.Supplier__c = supplier.Id;
        cpServices.BusinessUnitTarget__c = buCountry.Id;
        cpServices.CommercialPlanParent__c = cpParent.Id;
        cpServices.Contract__c = contract.Id;
        cpServices.Contract_Discount__c = discountServices.Id;
        cpServices.Pol_Com_Condition__c = tariffConditionServices.Id;
        cpServices.PromoAgreementType__c = 'CallOffAgreementSellOut'; // Services
        cpServices.Status__c = 'Validated';
        cpServices.ServicesDiscountMassValueInvoice__c = 1000;
        insert new List<CommercialPlan__c> { cpSellIn, cpSellOut, cpServices};
        // Insert CommercialPlanDetail__c SellIn
        CommercialPlanDetail__c cpdSellIn = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
        cpdSellIn.NegoScope__c = null;
        cpdSellIn.Supplier__c = supplier.Id;
        cpdSellIn.Contract__c = contract.Id;
        cpdSellIn.BusinessUnitTarget__c = buCountry.Id;
        cpdSellIn.Product__c = product.Id;
        cpdSellIn.Contract_Discount1__c = discountSellIn.Id;
        cpdSellIn.CommercialPlanSellIn__c = cpSellIn.Id;
        cpdSellIn.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdSellIn.SellOutDiscountValue__c = 100;
        cpdSellIn.ServicesDiscountUAmt__c = 100;
        cpdSellIn.VolumeTarget__c = 10;
        cpdSellIn.SellInDiscountUAmtNego__c = 10;
        cpdSellIn.SellOutDiscountQtyTarget__c = 10;
        cpdSellIn.SellOutDiscountQtyFact__c = 10;
        cpdSellIn.SellOutDiscountUAmt__c = 10;
        cpdSellIn.SellOutSourceContribPerc__c = 10;
        cpdSellIn.SellOutQtyTarget__c = 10;
        cpdSellIn.ServicesDiscountFixedAmt__c = 10;
        cpdSellIn.SellInDiscountMassValueFact__c = 10;
        cpdSellIn.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
        cpdSellIn.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
        cpdSellIn.SellInDiscountPerNego__c = 10;
        cpdSellIn.status__c = 'Realized';
        cpdSellIn.SellInDiscountMassValueInvoice__c = 1000;
        CommercialPlanDetail__c cpdSellIn2 = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
        cpdSellIn2.NegoScope__c = null;
        cpdSellIn2.Supplier__c = supplier.Id;
        cpdSellIn2.Contract__c = contract.Id;
        cpdSellIn2.BusinessUnitTarget__c = buCountry.Id;
        cpdSellIn2.Product__c = product.Id;
        cpdSellIn2.Contract_Discount1__c = discountSellIn.Id;
        cpdSellIn2.CommercialPlanSellIn__c = cpSellIn.Id;
        cpdSellIn2.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdSellIn2.SellOutDiscountValue__c = 100;
        cpdSellIn2.ServicesDiscountUAmt__c = 100;
        cpdSellIn2.VolumeTarget__c = 10;
        cpdSellIn2.SellInDiscountUAmtNego__c = 10;
        cpdSellIn2.SellOutDiscountQtyTarget__c = 10;
        cpdSellIn2.SellOutDiscountQtyFact__c = 10;
        cpdSellIn2.SellOutDiscountUAmt__c = 10;
        cpdSellIn2.SellOutSourceContribPerc__c = 10;
        cpdSellIn2.SellOutQtyTarget__c = 10;
        cpdSellIn2.ServicesDiscountFixedAmt__c = 10;
        cpdSellIn2.SellInDiscountMassValueFact__c = 10;
        cpdSellIn2.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
        cpdSellIn2.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
        cpdSellIn2.SellInDiscountPerNego__c = 10;
        cpdSellIn2.status__c = 'Realized';
        cpdSellIn2.SellInDiscountMassValueInvoice__c = 1500;
        // Insert CommercialPlanDetail__c SellOut
        CommercialPlanDetail__c cpdSellOut = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
        cpdSellOut.NegoScope__c = null;
        cpdSellOut.Supplier__c = supplier.Id;
        cpdSellOut.Contract__c = contract.Id;
        cpdSellOut.BusinessUnitTarget__c = buCountry.Id;
        cpdSellOut.Product__c = product.Id;
        cpdSellOut.Contract_Discount1__c = discountSellOut.Id;
        cpdSellOut.Contract_DiscountSellOut1__c = discountSellOut.Id;
        cpdSellOut.CommercialPlanSellOut__c = cpSellOut.Id;
        cpdSellOut.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdSellOut.SellOutDiscountValue__c = 100;
        cpdSellOut.ServicesDiscountUAmt__c = 100;
        cpdSellOut.VolumeTarget__c = 10;
        cpdSellOut.SellInDiscountUAmtNego__c = 10;
        cpdSellOut.SellOutDiscountQtyTarget__c = 10;
        cpdSellOut.SellOutDiscountQtyFact__c = 10;
        cpdSellOut.SellOutDiscountUAmt__c = 10;
        cpdSellOut.SellOutSourceContribPerc__c = 10;
        cpdSellOut.SellOutQtyTarget__c = 10;
        cpdSellOut.ServicesDiscountFixedAmt__c = 10;
        cpdSellOut.SellInDiscountMassValueFact__c = 10;
        cpdSellOut.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
        cpdSellOut.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
        cpdSellOut.SellInDiscountPerNego__c = 10;
        cpdSellOut.status__c = 'Realized';
        cpdSellOut.SellOutDiscMassValueContribInvoice__c = 1000;
        // Insert CommercialPlanDetail__c AgencyAgreement // // Services
        CommercialPlanDetail__c cpdServices = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
        cpdServices.NegoScope__c = null;
        cpdServices.Supplier__c = supplier.Id;
        cpdServices.Contract__c = contract.Id;
        cpdServices.BusinessUnitTarget__c = buCountry.Id;
        cpdServices.Product__c = product.Id;
        cpdServices.Contract_Discount1__c = discountServices.Id;
        cpdServices.Contract_DiscountServices1__c = discountServices.Id;
        cpdServices.CommercialPlanServices__c = cpServices.Id;
        cpdServices.SellOutBDate__c = Date.newInstance(year, 2, 1);
        cpdServices.SellOutDiscountValue__c = 100;
        cpdServices.ServicesDiscountUAmt__c = 100;
        cpdServices.VolumeTarget__c = 10;
        cpdServices.SellInDiscountUAmtNego__c = 10;
        cpdServices.SellOutDiscountQtyTarget__c = 10;
        cpdServices.SellOutDiscountQtyFact__c = 10;
        cpdServices.SellOutDiscountUAmt__c = 10;
        cpdServices.SellOutSourceContribPerc__c = 10;
        cpdServices.SellOutQtyTarget__c = 10;
        cpdServices.ServicesDiscountFixedAmt__c = 10;
        cpdServices.SellInDiscountMassValueFact__c = 10;
        cpdServices.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
        cpdServices.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
        cpdServices.SellInDiscountPerNego__c = 10;
        cpdServices.status__c = 'Realized';
        cpdServices.ServicesDiscountMassValueInvoice__c = 1000;
        insert new List<CommercialPlanDetail__c> { cpdSellIn, cpdSellIn2, cpdSellOut, cpdServices };
        Invoice__c invoiceSellIn = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoiceSellIn.RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource');
        invoiceSellIn.BusinessUnitSeller__c = buCountry.Id;
        invoiceSellIn.TotalAmount__c = 1000;
        invoiceSellIn.TotalAmountwVAT__c = 1000;
        invoiceSellIn.Status__c = 'Generated';
        invoiceSellIn.AccDocType__c = 'Invoice';
        invoiceSellIn.isUpdatedFromYTD__c = false;
        invoiceSellIn.IsManualVAT__c = tariffConditionSellIn.VAT_Type__c == 'Product';
        invoiceSellIn.isManualGL__c = false;
        invoiceSellIn.isManualContact__c = false;
        Invoice__c invoiceSellIn2 = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoiceSellIn2.RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource');
        invoiceSellIn2.BusinessUnitSeller__c = buCountry.Id;
        invoiceSellIn2.TotalAmount__c = 1000;
        invoiceSellIn2.TotalAmountwVAT__c = 1000;
        invoiceSellIn2.Status__c = 'Generated';
        invoiceSellIn2.AccDocType__c = 'Invoice';
        invoiceSellIn2.isUpdatedFromYTD__c = false;
        invoiceSellIn2.IsManualVAT__c = tariffConditionSellIn.VAT_Type__c == 'Product';
        invoiceSellIn2.isManualGL__c = false;
        invoiceSellIn2.isManualContact__c = false;
        Invoice__c invoiceSellOut = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoiceSellOut.RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource');
        invoiceSellOut.BusinessUnitSeller__c = buCountry.Id;
        invoiceSellOut.TotalAmount__c = 1000;
        invoiceSellOut.TotalAmountwVAT__c = 1000;
        invoiceSellOut.Status__c = 'Generated';
        invoiceSellOut.AccDocType__c = 'Invoice';
        invoiceSellOut.isUpdatedFromYTD__c = false;
        invoiceSellOut.IsManualVAT__c = tariffConditionSellOut.VAT_Type__c == 'Product';
        invoiceSellOut.isManualGL__c = false;
        invoiceSellOut.isManualContact__c = false;        
        Invoice__c invoiceServices = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoiceServices.RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource');
        invoiceServices.BusinessUnitSeller__c = buCountry.Id;
        invoiceServices.TotalAmount__c = 1000;
        invoiceServices.TotalAmountwVAT__c = 1000;
        invoiceServices.Status__c = 'Generated';
        invoiceServices.AccDocType__c = 'Invoice';
        invoiceServices.isUpdatedFromYTD__c = false;
        invoiceServices.IsManualVAT__c = tariffConditionServices.VAT_Type__c == 'Product';
        invoiceServices.isManualGL__c = false;
        invoiceServices.isManualContact__c = false;
        insert new List<Invoice__c> { invoiceSellIn, invoiceSellIn2, invoiceSellOut, invoiceServices };
        InvoiceDetail__c invoiceDetailSellIn = TestDataFactory.createInvoiceDetail(false, invoiceSellIn.Id, discountSellIn.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetailSellIn.DISCBudgetCode__c = tariffConditionSellIn.Id;
        invoiceDetailSellIn.DetailAmount__c = 1200;
        invoiceDetailSellIn.DetailVATRate__c = 0;
        invoiceDetailSellIn.CommercialPlan__c = cpSellIn.Id;
        InvoiceDetail__c invoiceDetailSellIn2 = TestDataFactory.createInvoiceDetail(false, invoiceSellIn2.Id, discountSellIn.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetailSellIn2.DISCBudgetCode__c = tariffConditionSellIn.Id;
        invoiceDetailSellIn2.DetailAmount__c = 1300;
        invoiceDetailSellIn2.DetailVATRate__c = 0;
        invoiceDetailSellIn2.CommercialPlan__c = cpSellIn.Id;
        InvoiceDetail__c invoiceDetailSellOut = TestDataFactory.createInvoiceDetail(false, invoiceSellOut.Id, discountSellOut.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetailSellOut.DISCBudgetCode__c = tariffConditionSellOut.Id;
        invoiceDetailSellOut.DetailAmount__c = 1000;
        invoiceDetailSellOut.DetailVATRate__c = 0;
        invoiceDetailSellOut.CommercialPlan__c = cpSellOut.Id;
        InvoiceDetail__c invoiceDetailServices = TestDataFactory.createInvoiceDetail(false, invoiceServices.Id, discountServices.Id, supplier.BusinessUnitOrigin__c, 1000);
        invoiceDetailServices.DISCBudgetCode__c = tariffConditionServices.Id;
        invoiceDetailServices.DetailAmount__c = 1000;
        invoiceDetailServices.DetailVATRate__c = 0;
        invoiceDetailServices.CommercialPlan__c = cpServices.Id;
        insert new List<InvoiceDetail__c> { invoiceDetailSellIn, invoiceDetailSellIn2, invoiceDetailSellOut, invoiceDetailServices };
        Test.startTest();
        invoiceSellIn2.Status__c = 'Deleted';
        invoiceSellOut.Status__c = 'Deleted';
        invoiceServices.Status__c = 'Deleted';
        update new List<Invoice__c> { invoiceSellIn2, invoiceSellOut, invoiceServices };
        Test.stopTest();
        cpdSellIn = [SELECT Id, SellInDiscountMassValueInvoice__c, SellInDiscountMassValueFact2__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellIn.Id];
        System.assertEquals(1000, cpdSellIn.SellInDiscountMassValueInvoice__c);
        cpdSellIn2 = [SELECT Id, SellInDiscountMassValueInvoice__c, SellInDiscountMassValueFact2__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellIn2.Id];
        invoiceDetailSellIn2 = [SELECT Id, DetailAmount__c FROM InvoiceDetail__c WHERE Id = :invoiceDetailSellIn2.Id];
        Decimal amount = (invoiceDetailSellIn2.DetailAmount__c != null ? invoiceDetailSellIn2.DetailAmount__c : 0);
        System.assertEquals(1500 - amount, cpdSellIn2.SellInDiscountMassValueInvoice__c);
    }
   @isTest
    static void case16_unpublishInvoiceFiles() {
        init();
        Test.startTest();
        // Case : Status = Deleted
        Invoice__c invoiceDeleted = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoiceDeleted.PrintDate__c = Date.today();
        invoiceDeleted.Status__c = 'Generated';
        invoiceDeleted.AccDoc__c = 'DownPaymentInvoice';
        invoiceDeleted.BusinessUnitSeller__c = buCountry.Id;
        invoiceDeleted.TotalAmount__c = 1000;
        invoiceDeleted.TotalAmountwVAT__c = 1000;
        insert invoiceDeleted;
        FileDirectory__c fileDeleted = new FileDirectory__c(
            Invoice__c = invoiceDeleted.Id,
            IsPortalPublished__c = true
        );
        insert fileDeleted;
        invoiceDeleted.Status__c = 'Deleted';
        update invoiceDeleted;
        fileDeleted = [SELECT Id, IsPortalPublished__c FROM FileDirectory__c WHERE Id = :fileDeleted.Id];
        System.assertEquals(false, fileDeleted.IsPortalPublished__c);

        // Case : Status = Cancelled
        Invoice__c invoiceCancelled = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 2), 2);
        invoiceCancelled.PrintDate__c = Date.today();
        invoiceCancelled.Status__c = 'Generated';
        invoiceCancelled.AccDoc__c = 'DownPaymentInvoice';
        invoiceCancelled.BusinessUnitSeller__c = buCountry.Id;
        invoiceCancelled.TotalAmount__c = 1000;
        invoiceCancelled.TotalAmountwVAT__c = 1000;
        insert invoiceCancelled;
        FileDirectory__c fileCancelled = new FileDirectory__c(
            Invoice__c = invoiceCancelled.Id,
            IsPortalPublished__c = true
        );
        insert fileCancelled;
        invoiceCancelled.Status__c = 'Cancelled';
        update invoiceCancelled;
        fileCancelled = [SELECT Id, IsPortalPublished__c FROM FileDirectory__c WHERE Id = :fileCancelled.Id];
        System.assertEquals(false, fileCancelled.IsPortalPublished__c);

        // Case : Delete invoice
        Invoice__c invoiceToDelete = TestDataFactory.createCreditNote(false, contract.Id, supplier, Date.newInstance(year, 1, 3), 3);
        invoiceToDelete.PrintDate__c = Date.today();
        invoiceToDelete.Status__c = 'Generated';
        invoiceToDelete.AccDoc__c = 'DownPaymentInvoice';
        invoiceToDelete.BusinessUnitSeller__c = buCountry.Id;
        invoiceToDelete.TotalAmount__c = 1000;
        invoiceToDelete.TotalAmountwVAT__c = 1000;
        insert invoiceToDelete;
        FileDirectory__c fileToDelete = new FileDirectory__c(
            Invoice__c = invoiceToDelete.Id,
            IsPortalPublished__c = true
        );
        insert fileToDelete;
        delete invoiceToDelete;
        List<FileDirectory__c> filesAfterDelete = [SELECT Id, IsPortalPublished__c FROM FileDirectory__c WHERE Id = :fileToDelete.Id];
        if (!filesAfterDelete.isEmpty()) {
            System.assertEquals(false, filesAfterDelete[0].IsPortalPublished__c);
        } else {
            System.assert(true);
        }
        Test.stopTest();
    }
}