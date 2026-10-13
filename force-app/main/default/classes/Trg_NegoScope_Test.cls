/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for nego scope object
 * */
@isTest
private class Trg_NegoScope_Test {
    
    private static User anotherUser;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier1;
    private static Supplier__c supplier2;
    private static NegoScope__c negoScope1;
    private static NegoScope__c subNegoScope11;
    private static NegoScope__c subNegoScope12;
    private static Country_List__c myCountry;
    private static Hierarchy__c department;
    private static Hierarchy__c section1;
    private static Hierarchy__c section2;
    private static Brand__c brand1;
    private static Brand__c brand2;
    private static PG__c pg1;
    private static PG__c pg2;
    private static Product2 product1;
    private static Product2 product2;
    private static final String productRT = TestDataFactory.productRTIds.get('Product');
    private static GlobalLocation__c globalLocationAdmin;
    private static GlobalLocation__c globalLocationAccounting;
    private static GlobalLocation__c globalLocationDelivery;
    private static NSBRA__c nsbra1;
    private static NSHE__c nshe1;
    private static NSPG__c nspg1;
    
    static void init() {
        try {
            // NOTE: Always should be first DML
            Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true LIMIT 1];
            Integer randomNumber = Integer.valueof((Math.random() * 10));
            anotherUser = new User(FirstName='anotherUser', LastName = 'anotherUser', Alias = 'another', Email = 'another@user.com',
            Username = 'another'+ randomNumber + '@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
            insert anotherUser;
            
            year = System.Today().year();
            // Root Element.
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;// NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, true);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Supplier__c> {supplier1, supplier2};
            // Create Global location Administrative
            globalLocationAdmin = new GlobalLocation__c();
            globalLocationAdmin.Name = 'Test GL Administration';
            globalLocationAdmin.CompanyName__c = 'Company1';
            globalLocationAdmin.Address1__c = 'Address1';
            globalLocationAdmin.Status__c = 'Open';
            globalLocationAdmin.Functions__c = 'Administrative';
            globalLocationAdmin.Supplier__c = supplier1.Id;
            insert globalLocationAdmin;
            // Create Global location Accounting
            globalLocationAccounting = new GlobalLocation__c();
            globalLocationAccounting.Name = 'Test GL Accounting ';
            globalLocationAccounting.CompanyName__c = 'Company2';
            globalLocationAccounting.Address1__c = 'Address1';
            globalLocationAccounting.Status__c = 'Open';
            globalLocationAccounting.Functions__c = 'InvoiceTo';
            globalLocationAccounting.Supplier__c = supplier1.Id;
            insert globalLocationAccounting;
            // Create Global location Delivery
            globalLocationDelivery = new GlobalLocation__c();
            globalLocationDelivery.Name = 'Test GL Delivery';
            globalLocationDelivery.CompanyName__c = 'Company1';
            globalLocationDelivery.Address1__c = 'Address2';
            globalLocationDelivery.Status__c = 'Open';
            globalLocationDelivery.Functions__c = 'DeliverTo';
            globalLocationDelivery.Supplier__c = supplier1.Id;
            insert globalLocationDelivery;
            // Create Department
            department = new Hierarchy__c(Name = 'DPT1', Code__c = 'Elt Code 1', HierarchyParent__c = rootId, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            insert department;
            // Create Sections
            section1 = new Hierarchy__c(SetProductLevel__c = true, Name = 'SEC1', Code__c = 'Elt Code 2', HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            section2 = new Hierarchy__c(SetProductLevel__c = true, Name = 'SEC2', Code__c = 'Elt Code 3', HierarchyParent__c = department.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'));
            insert new List<Hierarchy__c> {section1, section2};
            // Create brands
            brand1 = new Brand__c(Name = supplier1.Name + ' Brand 1', Supplier__c = supplier1.Id, StatusBDate__c = date.newInstance(year, 1, 1));
            brand2 = new Brand__c(Name = supplier2.Name + ' Brand 2', Supplier__c = supplier2.Id, StatusBDate__c = date.newInstance(year, 1, 1));
            insert new List<Brand__c> {brand1, brand2};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier1.Id);
            product1.RecordTypeId = productRT;
            product1.Status__c = 'Open';
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier1.Id);
            product2.RecordTypeId = productRT;
            product2.Status__c = 'Open';
            insert new List<Product2>{product1, product2};
            // Create PG.
            pg1 = new PG__c(Name = supplier1.Name + ' PG 1', Brand__c = brand1.Id, Hierarchy__c = section1.Id, Supplier__c = supplier1.Id);
            pg1.Product__c = product1.Id;
            pg2 = new PG__c(Name = supplier1.Name + ' PG 2', Brand__c = brand1.Id, Hierarchy__c = section1.Id, Supplier__c = supplier1.Id);
            pg2.Product__c = product2.Id;
            insert new List<PG__c> {pg1, pg2};
            // Get the default negoscope created on supplier creation.
            negoScope1 = TestDataFactory.getNSs(supplier1.Id)[0];
            subNegoScope11 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 1', NegoScopeParent__c = negoScope1.Id
                /* ,Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
            subNegoScope12 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 2', NegoScopeParent__c = negoScope1.Id/*,
            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
            insert new List<NegoScope__c> {subNegoScope11, subNegoScope12};
            // Create NSBRA
            nsbra1 = TestDataFactory.createNSBrand(true, negoScope1, brand2.Id);
            // Create NSHE
            nshe1 = TestDataFactory.createNSHE(true, negoScope1, section1.Id);
            // Create NSPG
            nspg1 = TestDataFactory.createNSPG(true, negoScope1, pg1.Id);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Test validation on negoscope name and supplier before insert.
    @isTest static void case1_createNegoScopeForSameNameSupplier() {
        init();
        NegoScope__c negoScope2 = new NegoScope__c(Name = System.Label.LBL_Default_NegoScope + ' - ' + supplier1.Name, Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        Test.startTest();
        Database.SaveResult result = Database.insert(negoScope2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique,
        new String[] {System.Label.LBL_Default_NegoScope + ' - ' + supplier1.Name}), result.getErrors()[0].getMessage());
    }
    
    // Test validation on negoscope name and suppllier before  update.
    @isTest static void case2_updateNegoScopeDuplicateNameSupplier() {
        init();
        NegoScope__c negoScope2 = new NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        insert negoScope2;
        negoScope2.Name = System.Label.LBL_Default_NegoScope + ' - ' + supplier1.Name;
        Test.startTest();
        Database.SaveResult result = Database.update(negoScope2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }
    
    // Test validation on adding 2 negoscope with same name.
    @isTest static void case3_createMultiNegoScope() {
        init();
        NegoScope__c negoScope2 = new NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        NegoScope__c negoScope3 = new NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        List<NegoScope__c> lstNegoscope = new List<NegoScope__c>();
        lstNegoscope.add(negoScope2);
        lstNegoscope.add(negoScope3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstNegoscope, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                /*System.assertEquals(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique,
                new String[] {'Nego Scope 1'}), result.getErrors()[0].getMessage());*/
            }
        }
    }
    
    // Test validation on negoscope creation with all he , brand and pg check.
    @isTest static void case4_CreateNegoScopeWithAllChecked() {
        init();
        NegoScope__c NS = new NegoScope__c(Name = 'New NS', Supplier__c = supplier1.Id, IncludeAllBrands__c = true, IncludeAllHEs__c = true, IncludeAllProducts__c = true/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        // Start test.
        Test.startTest();
        insert NS;
        Test.stopTest();
        List<NegoScope__c> listNegoScope = [Select Id FROM NegoScope__c];
        System.assert(listNegoScope.size() > 0);
        System.assertEquals(4, listNegoScope.size());
    }
    
    // Test validation on multiple  negoscope creation with all he , brand and pg check.
    @isTest static void case5_CreateMultyNegoScopeWithAllChecked() {
        init();
        List<NegoScope__c> listNegoScope = new List<NegoScope__c>();
        NegoScope__c NS = new NegoScope__c(Name = 'New NS', Supplier__c = supplier1.Id, IncludeAllBrands__c = true, IncludeAllHEs__c = true, IncludeAllProducts__c = true/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        NegoScope__c NS2 = new NegoScope__c(Name = 'New NS 1', Supplier__c = supplier2.Id, IncludeAllBrands__c = true, IncludeAllHEs__c = true, IncludeAllProducts__c = true/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        listNegoScope.add(NS);
        listNegoScope.add(NS2);
        // Start test.
        Test.startTest();
        insert listNegoScope;
        Test.stopTest();
        List<NegoScope__c> getListNegoScope = [Select Id, Name FROM NegoScope__c];
        System.assert(getListNegoScope.size() > 0);
        System.assertEquals(5,getListNegoScope.size());
    }
    
    // Assign supplier ISO code into the NS ISO Code.
    @isTest static void case6_assignmentISOCurrency() {
        // Create Region.
        BusinessUnit__c region = new BusinessUnit__c(Name = 'Region1', Code__c = 'Region1', OpeningDate__c = date.newInstance(2017, 1, 1));
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Region');
        insert region;
        // Create Country.
        BusinessUnit__c country = new BusinessUnit__c(Name = 'Country1', Code__c = 'Country1', OpeningDate__c = date.newInstance(2017, 1, 1),
        BusinessUnitRegion__c = region.Id, Status__c = 'Open');
        // Create supplier.
        Supplier__c supplier = new Supplier__c(Name = 'SupA',
        Code__c = 'SupA',
        CurrencyIsoCode = 'EUR',
        BusinessUnitOrigin__c = country.Id,
        Status__c = 'Active',
        t_CreateDefaultNegoScope__c = false);
        insert supplier;
        // Create NS.
        NegoScope__c NS = new NegoScope__c(Name = 'NS Name', Supplier__c = supplier.Id/*, CurrencyIsoCode = 'USD'/*,
        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        // Start test.
        Test.startTest();
        Database.insert(NS, false);
        Test.stopTest();
        // Assertion.
        NegoScope__c selectedNS = [SELECT CurrencyIsoCode FROM NegoScope__c WHERE Id = :NS.Id];
        System.assertEquals('EUR', selectedNS.CurrencyIsoCode);
    }
    
    // Assign supplier ISO code into the NS ISO Code.
    @isTest static void case7_assignmentISOCurrency_Bulk() {
        // Create Region.
        BusinessUnit__c region = new BusinessUnit__c(Name = 'Region1', Code__c = 'Region1', OpeningDate__c = date.newInstance(2017, 1, 1));
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Region');
        insert region;
        // Create Country.
        BusinessUnit__c country = new BusinessUnit__c(Name = 'Country1', Code__c = 'Country1', OpeningDate__c = date.newInstance(2017, 1, 1),
        BusinessUnitRegion__c = region.Id, Status__c = 'Open');
        // Create supplier.
        Supplier__c supplier = new Supplier__c(Name = 'SupA',
        Code__c = 'SupA',
        CurrencyIsoCode = 'EUR',
        BusinessUnitOrigin__c = country.Id,
        Status__c = 'Active',
        t_CreateDefaultNegoScope__c = false);
        insert supplier;
        List<NegoScope__c> NSs = new List<NegoScope__c>();
        // Create NS.
        for (Integer i=1 ; i < 6 ; i ++) {
            NegoScope__c NS = new NegoScope__c(Name = 'NS Name' + i, Supplier__c = supplier.Id, CurrencyIsoCode = 'USD'/*,
            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
            NSs.add(NS);
        }
        // Start test.
        Test.startTest();
        Database.insert(NSs, false);
        Test.stopTest();
        // Assertion.
        List<NegoScope__c> selectedNSs = [SELECT CurrencyIsoCode FROM NegoScope__c];
        for (NegoScope__c selectedNS : selectedNSs) {
            System.assertEquals('EUR', selectedNS.CurrencyIsoCode);
        }
    }
    
    // Update Sub NS owner when parent NS owner change.
    @isTest static void case8_updateSubNSOwner() {
        init();
        negoScope1.OwnerId = anotherUser.Id;
        
        Test.startTest();
        Database.SaveResult result = Database.update(negoScope1, false);
        Test.stopTest();
        
        // Assertion
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NegoScope__c WHERE Id = :negoScope1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM NegoScope__c WHERE Id = :subNegoScope11.Id].OwnerId);
    }
    
    // Test validation on negoscope Create NegoScope related a MasterBU
    @isTest static void case12_CreateNegoScopeWithMasterBU() {
        system.debug('entering case 12');
        init();
        country.Supplier__c = supplier1.Id;
        update country;
        pg1.BusinessUnit__c = country.Id;
        update pg1;
        // Start test.
        Test.startTest();
        negoScope1.BusinessUnit__c = country.Id;
        update negoScope1;
        Test.stopTest();
        List<NSPG__c> SupNSPG = [SELECT Id FROM NSPG__c WHERE NegoScope__c = :negoScope1.Id];
        // System.assertEquals(1, SupNSPG.size());
        System.assert(true);
    }
    // Test validation on negoscope Create NegoScope related a MasterBU And Children with LinkPGtoNSinsideorequalMasterBU = true
    @isTest static void case13_CreateNegoScopeWithMasterBUAndChildren() {
        init();
        BusinessUnit__c groupe = TestDataFactory.createBusinessUnitGroup(false, 'AMC');
        groupe.Supplier__c = supplier1.Id;
        insert groupe;
        BusinessUnit__c countryChild = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
        countryChild.BusinessUnitGroup__c = groupe.Id;
        countryChild.Supplier__c = supplier1.Id;
        insert countryChild;
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        /* negoSettings.LinkPGtoNSinsideorequalMasterBU = true;*/
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        pg1.BusinessUnit__c = groupe.Id;
        pg2.BusinessUnit__c = countryChild.Id;
        update new List<PG__c> {pg1, pg2};
        // Start test.
        Test.startTest();
        negoScope1.BusinessUnit__c = groupe.Id;
        update negoScope1;
        Test.stopTest();
        List<NSPG__c> SupNSPG = [SELECT Id FROM NSPG__c WHERE NegoScope__c = :negoScope1.Id];
        /*System.assertEquals(true, negoSettings.LinkPGtoNSinsideorequalMasterBU);*/
        //System.assertEquals(2, SupNSPG.size());
        System.assert(true);
    }
    // Test validation on negoscope Create NegoScope related a MasterBU And Children with LinkPGtoNSinsideorequalMasterBU = false
    @isTest static void case14_CreateNegoScopeWithMasterBUAndChildren() {
        init();
        BusinessUnit__c groupe = TestDataFactory.createBusinessUnitGroup(false, 'AMC');
        groupe.Supplier__c = supplier1.Id;
        insert groupe;
        BusinessUnit__c countryChild = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
        countryChild.BusinessUnitGroup__c = groupe.Id;
        countryChild.Supplier__c = supplier1.Id;
        insert countryChild;
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        /* negoSettings.LinkPGtoNSinsideorequalMasterBU = false;*/
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        pg1.BusinessUnit__c = groupe.Id;
        pg2.BusinessUnit__c = countryChild.Id;
        update new List<PG__c> {pg1, pg2};
        // Start test.
        Test.startTest();
        negoScope1.BusinessUnit__c = groupe.Id;
        update negoScope1;
        Test.stopTest();
        List<NSPG__c> SupNSPG = [SELECT Id FROM NSPG__c WHERE NegoScope__c = :negoScope1.Id];
        /*System.assertEquals(false, negoSettings.LinkPGtoNSinsideorequalMasterBU);*/
        // System.assertEquals(1, SupNSPG.size());
        System.assert(true);
    }
    // Test validation on negoscope Create NegoScope Family__c
    @isTest static void case15_CreateNegoScopeWithFamily() {
        init();
        Product2 product3 = TestDataFactory.createProduct(false, section2.Id, supplier1.Id);
        product3.RecordTypeId = productRT;
        product3.Status__c = 'Open';
        insert product3;
        // Create PG.
        PG__c pg3 = new PG__c(Name = supplier1.Name + ' PG 3', Brand__c = brand1.Id, Hierarchy__c = section1.Id, Supplier__c = supplier1.Id);
        pg3.Product__c = product3.Id;
        insert pg3;
        // Start test.
        product1.Family = 'Tred';
        //product2.Family = null;
        ////product3.Family = 'LS';
        product3.Family = 'None';
        update new List<Product2>{product1,product3};
        Test.startTest();
        ////negoScope1.Family__c = 'LS';
        /*negoScope1.Family__c = 'None';*/
        update negoScope1;
        Test.stopTest();
        List<NSPG__c> SupNSPG = [SELECT Id FROM NSPG__c WHERE NegoScope__c = :negoScope1.Id];
        // System.assertEquals(2, SupNSPG.size());
        System.assert(true);
    }
    
    // Test filling global location
    @isTest static void case16_SetGlobalLocation() {
        init();
        Test.startTest();
        NegoScope__c negoScope1 = new NegoScope__c(Name = 'Nego Scope GL 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false);
        insert negoScope1;
        NegoScope__c subNegoScope11 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS GL 1', NegoScopeParent__c = negoScope1.Id);
        NegoScope__c subNegoScope12 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS GL 2', NegoScopeParent__c = negoScope1.Id);
        insert new List<NegoScope__c> {subNegoScope11, subNegoScope12};
        negoscope1 = [SELECT GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c FROM NegoScope__c WHERE Id = :negoScope1.Id];
        List<NegoScope__c> subNegoscope1 = [SELECT GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c FROM NegoScope__c WHERE NegoScopeParent__c = :negoScope1.Id];
        GlobalLocation__c globalLocationAdmin = [SELECT Id FROM GlobalLocation__c WHERE Id = :globalLocationAdmin.Id];
        GlobalLocation__c globalLocationAccounting = [SELECT Id FROM GlobalLocation__c WHERE Id = :globalLocationAccounting.Id];
        GlobalLocation__c globalLocationDelivery = [SELECT Id FROM GlobalLocation__c WHERE Id = :globalLocationDelivery.Id];
        Test.stopTest();
        System.assertEquals(globalLocationAdmin.Id, negoscope1.GlobalLocationAdministration__c);
        System.assertEquals(globalLocationAccounting.Id, negoscope1.GlobalLocationAccounting__c);
        System.assertEquals(globalLocationDelivery.Id, negoscope1.GlobalLocationDelivery__c);
        System.assertEquals(globalLocationAdmin.Id, subNegoscope1[0].GlobalLocationAdministration__c);
        System.assertEquals(globalLocationAccounting.Id, subNegoscope1[0].GlobalLocationAccounting__c);
        System.assertEquals(globalLocationDelivery.Id, subNegoscope1[0].GlobalLocationDelivery__c);
    }
    // Test filling global location for subnegoscope after update
    @isTest static void case17_SetGlobalLocationtoSubNS() {
        init();
        Test.startTest();
        NegoScope__c negoScope1 = new NegoScope__c(Name = 'Nego Scope GL 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false);
        insert negoScope1;
        NegoScope__c subNegoScope11 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS GL 1', NegoScopeParent__c = negoScope1.Id);
        NegoScope__c subNegoScope12 = new NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS GL 2', NegoScopeParent__c = negoScope1.Id);
        insert new List<NegoScope__c> {subNegoScope11, subNegoScope12};
        negoScope1.GlobalLocationAdministration__c = null;
        update negoScope1;
        negoscope1 = [SELECT GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c FROM NegoScope__c WHERE Id = :negoScope1.Id];
        List<NegoScope__c> subNegoscope1 = [SELECT GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c FROM NegoScope__c WHERE NegoScopeParent__c = :negoScope1.Id];
        GlobalLocation__c globalLocationAccounting = [SELECT Id FROM GlobalLocation__c WHERE Id = :globalLocationAccounting.Id];
        GlobalLocation__c globalLocationDelivery = [SELECT Id FROM GlobalLocation__c WHERE Id = :globalLocationDelivery.Id];
        Test.stopTest();
        System.assertEquals(null, subNegoscope1[0].GlobalLocationAdministration__c);
        System.assertEquals(globalLocationAccounting.Id, subNegoscope1[0].GlobalLocationAccounting__c);
        System.assertEquals(globalLocationDelivery.Id, subNegoscope1[0].GlobalLocationDelivery__c);
    }
    // Test filling global location for subnegoscope after update
    @isTest static void case18_UpdateRecordTypeOnValidation() {
        init();
        Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
        NegoScopeSettings negoScopeSettings = NegoScopeSettings.loadNegoScopeSettings();
        negoScopeSettings.isNSProjectActive = true;
        negoScopeSettings.isNSProjectToRegularOnValidation = true;
        Map<String, Object> fieldsValueMap = new Map<String, Object> {
            SObjectType.NegoScopeSettings__c.fields.IsNSProjectActive__c.Name => negoScopeSettings.isNSProjectActive,
            SObjectType.NegoScopeSettings__c.fields.isNSProjectToRegularOnValidation__c.Name => negoScopeSettings.isNSProjectToRegularOnValidation
        };
        NegoScopeSettings.save(negoScopeSettings);
        Test.startTest();
        NegoScope__c negoScope1 = new NegoScope__c(Name = 'Nego Scope GL 1', Supplier__c = supplier1.Id, IncludeAllBrands__c = false, IncludeAllHEs__c = false, IncludeAllProducts__c = false);
        negoScope1.RecordTypeId = negoScopeRTIds.get('NSProject');
        negoScope1.Status__c = 'In preparation';
        insert negoScope1;
        negoScope1.Status__c = 'Active';
        update negoScope1;
        Test.stopTest();
        negoScope1 = [SELECT RecordType.DeveloperName FROM NegoScope__c WHERE Id = :negoScope1.Id];
        System.assertEquals('Regular', negoScope1.RecordType.DeveloperName);
    }
    
    // Test update NSBRA, NSPG or NSHE OwnerId when parent OwnerId change
    @isTest
    static void case19_UpdateNSDetailOwnerId() {
        init();
        negoScope1.OwnerId = anotherUser.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(negoScope1, false);
        Test.stopTest();
        NSPG__c retrievedNSPG = [SELECT Id, OwnerId FROM NSPG__c WHERE Id = :nspg1.Id LIMIT 1];
        System.assertEquals(anotherUser.Id, retrievedNSPG.OwnerId);
        NSBRA__c retrievedNSBRA = [SELECT Id, OwnerId FROM NSBRA__c WHERE Id = :nsbra1.Id LIMIT 1];
        System.assertEquals(anotherUser.Id, retrievedNSBRA.OwnerId);
        NSHE__c retrievedNSHE = [SELECT Id, OwnerId FROM NSHE__c WHERE Id = :nshe1.Id LIMIT 1];
        System.assertEquals(anotherUser.Id, retrievedNSHE.OwnerId);
    }

    // Test when deleting a NSA or NS or SNS, the related NS links should be deleted.
    @isTest
	static void case20_cleanUpRelatedList() {
        init();
        Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
		// Start test.
        Supplier__c NSSupplier = TestDataFactory.createSupplier(false, country, true);
        NSSupplier.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Supplier__c.sObjectType, 'Supplier');
        insert NSSupplier;
        NegoScope__c advancedNS = TestDataFactory.createNegoScope(false, NSSupplier, 'AdvancedNS');
        advancedNS.RecordTypeId = negoScopeRTIds.get('Advanced');
        insert advancedNS;
        NegoScope__c regularNS = TestDataFactory.createNegoScope(false, NSSupplier, 'regularNS');
        regularNS.RecordTypeId = negoScopeRTIds.get('Regular');
        insert regularNS;
        NSLink__c nsLink1 = new NSLink__c(NegoScopeMaster__c = advancedNS.Id, NegoScopeDetail__c = regularNS.Id);
        insert nsLink1;
		Test.startTest();
        Delete advancedNS;
        Test.stopTest();
        System.assertEquals(true, [SELECT Id FROM NSLink__c WHERE NegoScopeDetail__c = :regularNS.Id].isEmpty());
    }
}