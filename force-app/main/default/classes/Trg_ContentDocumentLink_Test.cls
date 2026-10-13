/*
 * @author @ULIT
 * @description This class contains unit tests for validating the behavior of Apex classes and triggers related to conditions.
 */ 
@isTest
private class Trg_ContentDocumentLink_Test {
    private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Contract_Discount__c condition;

    static void init() {
        year = System.Today().year();
        // Create Region
        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Create Country
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.SetInvoiceSeller__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // Get the default NegoScope created on supplier creation
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        // create contract
        contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year,12, 31));
        Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 1, 1);
        condition = TestDataFactory.createCondition(true, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        Invoice__c invoice = TestDataFactory.createDownPaymentInvoice(false, contract.Id, supplier, Date.newInstance(year, 1, 1), 1);
        invoice.FiscalYear__c = 2024;
        insert invoice;
        insert new InvoiceDetail__c(Invoice__c = invoice.Id);
    }
    @IsTest
    static void testOnAfterInsert(){
        init();
        Invoice__c invoice = [SELECT Id, TotalAmount__c, Status__c, FiscalYear__c, AccDocType__c FROM Invoice__c][0];
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        contentVersion = [SELECT ContentDocumentId,Title FROM contentVersion][0];
        // Retrieve the ContentDocument ID
        ContentDocument contentDocument = [ SELECT Id FROM ContentDocument WHERE Id = :contentVersion.ContentDocumentId ];
        // Create a ContentDocumentLink linking to the Invoice
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = invoice.Id,
            ContentDocumentId = contentDocument.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert contentDocumentLink;
        Id recordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(FileDirectory__c.SObjectType).get('Financial');
        InvoiceDetail__c invoiceDetail = [SELECT Id,Invoice__c, Invoice__r.FiscalYear__c, Invoice__r.SupplierBuyer__c, DISCLineD__r.Product_Scope__c FROM InvoiceDetail__c][0];
        List<FileDirectory__c> fileDirectories = [SELECT DocumentName__c,RecordTypeId, ReferenceYear__c, Supplier__c, SubType__c, Negoscope__c FROM FileDirectory__c];
        FileDirectory__c createdDir = fileDirectories[0];
        System.assertEquals(1, fileDirectories.size());
        System.assertEquals(contentVersion.Title, createdDir.DocumentName__c);
        System.assertEquals(invoiceDetail.Invoice__r.FiscalYear__c, createdDir.ReferenceYear__c);
        System.assertEquals(invoiceDetail.Invoice__r.SupplierBuyer__c, createdDir.Supplier__c);
        System.assertEquals('Invoice', createdDir.SubType__c);
        System.assertEquals(invoiceDetail.DISCLineD__r.Product_Scope__c, createdDir.Negoscope__c);
        System.assertEquals(RecordTypeId, createdDir.RecordTypeId);
           
        
    }
}