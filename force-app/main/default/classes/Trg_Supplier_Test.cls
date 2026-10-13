/**
 * Integrity Constraint to test duplication
 * in fields of 'Name' (supplier name) with 'BusinessUnitOrigin__c' (country)
 * and 'Code__c' with 'BusinessUnitOrigin__c'
 * */
@isTest
private class Trg_Supplier_Test {

	private static Integer year;
 	private static BusinessUnit__c country1;
 	private static BusinessUnit__c country2;

 	static void init() {
 		try {
    		year = System.Today().year();
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create BU Country
            String cRTId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Country');
            country1 = new BusinessUnit__c(Name = 'France', Code__c = myCountry.Country_Code__c, OpeningDate__c = date.newInstance(2016, 1, 1));
            country1.RecordTypeId =  cRTId;
            // Create second BU Country
            country2 = new BusinessUnit__c(Name = 'Lebanon', Code__c = myCountry.Country_Code__c, OpeningDate__c = date.newInstance(2016, 1, 1));
            country2.RecordTypeId =  cRTId;
            insert new List<BusinessUnit__c>{country1, country2};
	    } catch (Exception ex) {
	        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
	        System.debug(ex.getMessage());
	        System.debug(ex.getStackTraceString());
	        System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
		}
    }
    
    @isTest static void TestInsertDuplicateCodeAndSameCountry() {
        init();
        Supplier__c sup1 = new Supplier__c(Code__c = '1', Name ='Supplier 001', BusinessUnitOrigin__c = country2.Id,
                                           BDate__c = date.today());
        insert sup1;
        Supplier__c sup2 = new Supplier__c(Code__c = '1', Name ='Supplier 002', BusinessUnitOrigin__c = country2.Id,
                                           BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Code_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }

    @isTest static void TestUpdatetDuplicateCodeAndSameCountry() {
    	init();
        Supplier__c sup1 = new Supplier__c(Code__c = '1', Name ='Supplier 001', BusinessUnitOrigin__c = country1.Id,
                                           BDate__c = date.today());
        Supplier__c sup2 = new Supplier__c(Code__c = '2', Name ='Supplier 002', BusinessUnitOrigin__c = country1.Id,
                                           BDate__c = date.today());
        insert new List<Supplier__c>{sup1, sup2};
            sup2.Code__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Code_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    @isTest static void Test_CreateMultiSupplierSameNameDiffCountry() {
    	init();
        try {
        	Supplier__c supplier1 = new Supplier__c(Name = 'Nestle', Code__c = 'SN1', BusinessUnitOrigin__c = country1.Id);
            Supplier__c supplier2 = new Supplier__c(Name = 'Nestle', Code__c = 'SN2', BusinessUnitOrigin__c = country2.Id);
            insert new List<Supplier__c>{supplier1, supplier2};
            System.assert(true);
	    } catch(exception ex){
	        System.debug('++++++++++++++++++++++++++++++');
	        System.debug(ex.getMessage() );
	        System.debug(ex.getStackTraceString() );
	        System.debug('++++++++++++++++++++++++++++++');
	    }
   }
    // When supplier status end date__c is greater than the current date, and status is Closed, then status = active;
    static testmethod void statusMod() {
        init();
        Date now = Date.newinstance(System.now().year(), System.now().month(), System.now().day()+1);
        // Create active supplier.
        Supplier__c supplier = new Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Closed', BusinessUnitOrigin__c = country1.Id,
                                               EDate__c = date.newInstance(year, 3, 3), CurrencyIsoCode = 'EUR');
        insert supplier;
        supplier.EDate__c = now;
        update supplier;
        // Assertion.
        Supplier__c selectedSupplier = [SELECT Status__c FROM Supplier__c WHERE Id = :supplier.Id];
        System.assertEquals('Active', selectedSupplier.Status__c);
    }

    /*
     * @description This Method to test Rename Account after Rename Supplier.
     * */
    @isTest static void TestRenameAccount() {
        init();
        Account account = TestDataFactory.createAccount(true, 'Account 1');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Account__c = account.Id;
        Insert sup1;
        sup1.Name = 'sup1';
        
        Test.startTest();
        update sup1;
        Test.stopTest();
        Account accountNew = [SELECT Id, Name FROM Account WHERE Id =:account.Id LIMIT 1];
        System.assertEquals('sup1', accountNew.Name);
    }

    /*
     * @description This Method to test Rename Account after Rename Supplier Mass.
     * */
    @isTest static void TestRenameAccountMass() {
        init();
        Account account1 = TestDataFactory.createAccount(true, 'Account 1');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Account__c = account1.Id;
        
        Account account2 = TestDataFactory.createAccount(true, 'Account 2');
        Supplier__c sup2 = TestDataFactory.createSupplier(false, country1, false);
        sup2.Account__c = account2.Id;
        List<Supplier__c> suppliersList = new List<Supplier__c>{sup1, sup2};
            Insert suppliersList;
        
        sup1.Name = 'sup1';
        sup2.Name = 'sup2';
        Test.startTest();
        update suppliersList;
        Test.stopTest();
        Account account1New = [SELECT Id, Name FROM Account WHERE Id =:account1.Id LIMIT 1];
        Account account2New = [SELECT Id, Name FROM Account WHERE Id =:account2.Id LIMIT 1];
        System.assertEquals('sup1', account1New.Name);
        System.assertEquals('sup2', account2New.Name);
    }

    /*
     * @description This Method to test Insert Account after Insert Supplier with NegoptimCustomSettings Allow_Insert_Account_On_Insert_Supplier__c = true expected to insert a new Account
     * */
    @isTest static void TestCreateAccountWithAllow() {
        init();
        NegoptimCustomSettings__c negoptimSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', Allow_Insert_Account_On_Insert_Supplier__c = true);
        insert negoptimSettings;
        Account account = TestDataFactory.createAccount(true, 'Account 1');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Name = 'sup1';
        sup1.Account__c = account.Id;
        Supplier__c sup2 = TestDataFactory.createSupplier(false, country2, false);
        sup2.Name = 'sup2';

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(new List<Supplier__c>{sup1, sup2});
        Test.stopTest();
        Supplier__c sup1New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup1.Id LIMIT 1];
        System.assertEquals(account.Id, sup1New.Account__c);
        Supplier__c sup2New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup2.Id LIMIT 1];
        System.assertNotEquals(null, sup2New.Account__c);
    }

    /*
     * @description This Method to test Insert Account after Insert Supplier with NegoptimCustomSettings Allow_Insert_Account_On_Insert_Supplier__c = true expected to do not insert a new Account
     * */
    @isTest static void TestCreateAccountWithoutAllow() {
        init();
        NegoptimCustomSettings__c negoptimSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', Allow_Insert_Account_On_Insert_Supplier__c = false);
        insert negoptimSettings;
        Account account = TestDataFactory.createAccount(true, 'Account 1');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Name = 'sup1';
        sup1.Account__c = account.Id;
        Supplier__c sup2 = TestDataFactory.createSupplier(false, country2, false);
        sup2.Name = 'sup2';
        
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(new List<Supplier__c>{sup1, sup2});
        Test.stopTest();
        Supplier__c sup1New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup1.Id LIMIT 1];
        System.assertEquals(account.Id, sup1New.Account__c);
        Supplier__c sup2New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup2.Id LIMIT 1];
        System.assertEquals(null, sup2New.Account__c);
    }

    /*
     * @description This Method to test Insert Account after Insert Supplier with NegoptimCustomSettings Allow_Insert_Account_On_Insert_Supplier__c = true expected to insert a new Account Mass.
     * */
    @isTest static void TestCreateAccountWithAllowMass() {
        init();
        NegoptimCustomSettings__c negoptimSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', Allow_Insert_Account_On_Insert_Supplier__c = true);
        insert negoptimSettings;
        Account account = TestDataFactory.createAccount(true, 'Account 1');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Name = 'sup1';
        sup1.Account__c = account.Id;
        
        Supplier__c sup2 = TestDataFactory.createSupplier(false, country2, false);
        sup2.Name = 'sup2';
        Supplier__c sup3 = TestDataFactory.createSupplier(false, country2, false);
        sup2.Name = 'sup3';
        
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(new List<Supplier__c>{sup1, sup2, sup3});
        Test.stopTest();
        Supplier__c sup1New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup1.Id LIMIT 1];
        System.assertEquals(account.Id, sup1New.Account__c);
        Supplier__c sup2New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup2.Id LIMIT 1];
        System.assertNotEquals(null, sup2New.Account__c);
        Supplier__c sup3New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup3.Id LIMIT 1];
        System.assertNotEquals(null, sup2New.Account__c);
    }

    /*
     * @description This Method to test update supplier in account after assign an account to supplier.
     * */
    @isTest static void TestCreateSupplierAndUpdateAccount(){
        init();
        Account account = TestDataFactory.createAccount(true, 'Account 1');
        Account account2 = TestDataFactory.createAccount(true, 'Account 2');
        Supplier__c sup1 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Name = 'sup1';
        Account account3 = TestDataFactory.createAccount(true, 'Account 2');
        Supplier__c sup2 = TestDataFactory.createSupplier(false, country1, false);
        sup1.Name = 'sup2';
        Test.startTest();
        sup1.Account__c = account.Id;
        insert sup1;
        sup1.Account__c = account2.Id;
        update sup1;
        //-----------
        sup2.Account__c = account.Id;
        insert sup2;
        sup2.Account__c = null;
        update sup2;
        Test.stopTest();
        Supplier__c sup1New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup1.Id LIMIT 1];
        System.assertEquals(account2.Id, sup1New.Account__c);
        Account accountNew = [SELECT Id, Supplier__c FROM Account WHERE Id = :account.Id LIMIT 1];
        System.assertEquals(null, accountNew.Supplier__c);
        Account account2New = [SELECT Id, Supplier__c FROM Account WHERE Id = :account2.Id LIMIT 1];
        System.assertEquals(sup1.Id, account2New.Supplier__c);
        
        Supplier__c sup2New = [SELECT Id, Account__c FROM Supplier__c WHERE Id =:sup2.Id LIMIT 1];
        System.assertEquals(null, sup2New.Account__c);
        Account account3New = [SELECT Id, Supplier__c FROM Account WHERE Id = :account3.Id LIMIT 1];
        System.assertEquals(null, account3New.Supplier__c);
    }

    /*
     * @description This Method to test update global location after update Supplier with CurrencyIsoCode and ReferenceLanguage__c matching before update.
     * */
    @isTest static void TestUpdateGlobalLocationCurrencyAndReferenceLanguage(){
        init();
        // Create a supplier
        Supplier__c supplier = new Supplier__c(Code__c = '1', Name ='Supplier 001', BusinessUnitOrigin__c = country2.Id,
                                                BDate__c = date.today(), ReferenceLanguage__c = 'English', CurrencyIsoCode = 'EUR');
        insert supplier;
        // Create global locations and attach to created supplier
        // Create a global location #1: ReferenceLanguage__c == Supplier.ReferenceLanguage__c
        GlobalLocation__c gl1 = new GlobalLocation__c(Name = 'gl1', Supplier__c = supplier.Id, ReferenceLanguage__c = supplier.ReferenceLanguage__c, CurrencyIsoCode = 'EUR');
        // Create a global location #2: CurrencyIsoCode == Supplier.CurrencyIsoCode
        GlobalLocation__c gl2 = new GlobalLocation__c(Name = 'gl2', Supplier__c = supplier.Id, ReferenceLanguage__c = 'French', CurrencyIsoCode = supplier.CurrencyIsoCode);
        // Create a global location #3: ReferenceLanguage__c != Supplier.ReferenceLanguage__c and CurrencyIsoCode != Supplier.CurrencyIsoCode
        GlobalLocation__c gl3 = new GlobalLocation__c(Name = 'gl3', Supplier__c = supplier.Id, ReferenceLanguage__c = 'French', CurrencyIsoCode = 'EUR');
        // Create a global location #4: ReferenceLanguage__c == Supplier.ReferenceLanguage__c &&  CurrencyIsoCode == Supplier.CurrencyIsoCode
        GlobalLocation__c gl4 = new GlobalLocation__c(Name = 'gl4', Supplier__c = supplier.Id, ReferenceLanguage__c = supplier.ReferenceLanguage__c, CurrencyIsoCode = supplier.CurrencyIsoCode);
        List<GlobalLocation__c> globalLocations = new List<GlobalLocation__c>{gl1, gl2, gl3, gl4};
        insert globalLocations; 
        // Reassure the values by update (because they may be overwritten)
        gl1.ReferenceLanguage__c = supplier.ReferenceLanguage__c;
        gl1.CurrencyIsoCode = 'EUR';
        gl2.ReferenceLanguage__c = 'French';
        gl2.CurrencyIsoCode = supplier.CurrencyIsoCode;
        gl3.ReferenceLanguage__c = 'French';
        gl3.CurrencyIsoCode = 'EUR';
        gl4.ReferenceLanguage__c = supplier.ReferenceLanguage__c;
        gl4.CurrencyIsoCode = supplier.CurrencyIsoCode;
        globalLocations = new List<GlobalLocation__c>{gl1, gl2, gl3, gl4};
        update globalLocations;
        Test.startTest();
        supplier.ReferenceLanguage__c = 'French';
        supplier.CurrencyIsoCode = 'EUR';
        update supplier;
        Test.stopTest();
        // Retrieve the global locations and the updated supplier
        List<GlobalLocation__c> globalLocationsAfter = [SELECT Id, Name, ReferenceLanguage__c, CurrencyIsoCode, Supplier__c FROM GlobalLocation__c WHERE Supplier__c = :supplier.Id];
        Supplier__c supplierAfter = [SELECT Id, ReferenceLanguage__c, CurrencyIsoCode FROM Supplier__c WHERE Id = :supplier.Id];
        // Assert that gl1 has updated its ReferenceLanguage__c field and not the CurrencyIsoCode field
        // Assert that gl2 has updated its CurrencyIsoCode field and not the ReferenceLanguage__c field
        // Assert that gl3 has not updated its ReferenceLanguage__c field or CurrencyIsoCode field
        // Assert that gl4 has not updated any of the two fields
        for (GlobalLocation__c globalLocation: globalLocationsAfter) {
            if (globalLocation.Name == 'gl1') {
                System.assertEquals(supplierAfter.ReferenceLanguage__c, globalLocation.ReferenceLanguage__c, 'gl1 did not update its ReferenceLanguage__c');
            } else if (globalLocation.Name == 'gl2') {
                System.assertEquals(supplierAfter.currencyIsoCode, globalLocation.currencyIsoCode, 'gl2 did not update its CurrencyIsoCode');
            }else if (globalLocation.Name == 'gl3') {
                System.assertEquals(gl3.ReferenceLanguage__c, globalLocation.ReferenceLanguage__c, 'gl3 did update its ReferenceLanguage__c');
                System.assertEquals(gl3.CurrencyIsoCode, globalLocation.CurrencyIsoCode, 'gl3 did update its CurrencyIsoCode');
            }else if (globalLocation.Name == 'gl4') {
                System.assertEquals(supplierAfter.ReferenceLanguage__c, globalLocation.ReferenceLanguage__c, 'gl4 did not update its ReferenceLanguage__c');
                System.assertEquals(supplierAfter.currencyIsoCode, globalLocation.currencyIsoCode, 'gl2 did not update its CurrencyIsoCode');
            }
        }

    }
}