@isTest
private class INVCreateSCNControllerTest {
    
    @isTest
    static void testCreateSupplierCreditNote_success() {
        // Create a mock Supplier (Client/Supplier)
        Supplier__c supplier = new Supplier__c(
            Name = 'Test Supplier',
            CurrencyIsoCode = 'LBP',
            Code__c='as12'
        );
        insert supplier;
		NegoScope__c negoScope = new NegoScope__c(
          Name = 'Test Scope',
          Supplier__c = supplier.Id,
          CurrencyIsoCode = 'LBP', // assuming this is relevant
          Status__c = 'Active' // assuming this is a valid picklist value
        );
         insert negoScope;

        // Create a mock Contract
        Contract__c contract = new Contract__c(
            Name = 'Test Contract',
            Supplier_Nego_Scope__c=negoScope.Id,
            Supplier__c = supplier.Id
        );
        insert contract;

        // Create the form input map
        Map<String, Object> formData = new Map<String, Object>{
            'InvNumber__c' => 'INV-2025-001',
            'InvDate__c' => Date.today().addDays(5),
            'Contract__c' => contract.Id,
            'CurrencyIsoCode' => 'LBP',
            'ExchangeRate__c' => 1.15,
            'PaymentType__c' => 'Cheque',
            'TotalAmount__c' => 1000.00,
            'TotalVATAmount__c' => 200.00,
            'TotalAmountwVAT__c' => 1200.00,
            'VATRate1__c' => 20.00
        };

        // Wrap in the input structure
        Map<String, Object> inputMap = new Map<String, Object>{
            'invoicedata' => formData,
            'supplierId' => supplier.Id
        };

        // Serialize input
        String serializedInput = JSON.serialize(inputMap);

        // Call the controller method
        Test.startTest();
        Id invoiceId = INVCreateSCNController.createSupplierCreditNote(serializedInput);
        Test.stopTest();

        // Assert the invoice is created correctly
        Invoice__c result = [SELECT Id, InvNumber__c, InvDate__c, Contract__c, CurrencyIsoCode,
                             ExchangeRate__c, PaymentType__c, TotalAmount__c,
                             TotalVATAmount__c, TotalAmountwVAT__c, VATRate1__c,
                             Status__c, AccDoc__c, SupplierSeller__c, RecordType.Name
                             FROM Invoice__c
                             WHERE Id = :invoiceId];

        System.assertNotEquals(null, result);
        System.assertEquals('INV-2025-001', result.InvNumber__c);
        System.assertEquals(contract.Id, result.Contract__c);
        System.assertEquals('LBP', result.CurrencyIsoCode);
        System.assertEquals(1.15, result.ExchangeRate__c);
        System.assertEquals('Cheque', result.PaymentType__c);
        System.assertEquals(1000.00, result.TotalAmount__c);
        System.assertEquals(200.00, result.TotalVATAmount__c);
        System.assertEquals(1200.00, result.TotalAmountwVAT__c);
        System.assertEquals(20.00, result.VATRate1__c);
        System.assertEquals('Listed', result.Status__c);
        System.assertEquals('CreditNote', result.AccDoc__c);
        System.assertEquals(supplier.Id, result.SupplierSeller__c);
        System.assertEquals('SourceToTarget', result.RecordType.Name);
    }
}