@isTest
private class ExecutiveSummaryController_Test {

    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static BusinessUnit__c legal;
    private static BusinessUnit__c store;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Contract__c contract;
    private static Contract__c negoBaseContract;
    private static Contract__c topContract;
    private static Pol_Com_Condition__c tariffCondition;
    public static final Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for BusinessUnit__c SObject
            Map<String, Id> businessUnitRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Store
            store = TestDataFactory.createBusinessUnitStores(true, country, 1).get(0);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createHierarchySection(true, department.Id);
            // Create Contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.D_N__c = 'N';
            insert contract;
            // nego base nego year - 1
            negoBaseContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            negoBaseContract.Name = supplier.Name + ' Nego Base ' + year;
            negoBaseContract.Contract_Number__c = 'C002';
            negoBaseContract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Nego_Base');
            negoBaseContract.TO1__c = 1000;
            negoBaseContract.D_N__c = 'N';
            insert negoBaseContract;
            // Create Simulation Contract
            Integer nextYear = year + 1;
            topContract = TestDataFactory.createContract(false, NS, date.newInstance(nextYear, 1, 1), date.newInstance(nextYear, 12, 31));
            topContract.Name = supplier.Name + ' - Round ' + nextYear;
            topContract.Contract_Type__c = 'Simulation';
            topContract.D_N__c = 'N';
            topContract.Parent_Contract__c = contract.Id;
            topContract.RecordTypeId = contractRTIds.get('Simulation');
            topContract.Is_OnTop_Simulation__c = true;
            topContract.Rise_Rate_YE__c = 10;
            topContract.Depreciation_Rate_YE__c = 10;
            insert topContract;
            // Create Policy - Tariff Conditions
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 2);
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    //content type test
    @isTest static void test_constructor0() {
        init();
        ApexPages.currentPage().getParameters().put('id', topContract.Id);
        ApexPages.currentPage().getParameters().put('contentType', '');
        Test.startTest();
        ExecutiveSummaryController ctrlr = new ExecutiveSummaryController();
        String selectedMultiYearOption = ctrlr.selectedMultiYearOption;
        String refContractIndex1 = ctrlr.refContractIndex1;
        String refContractIndex2 = ctrlr.refContractIndex2;
        String refContractIndex3 = ctrlr.refContractIndex3;
        String refContractIndex4 = ctrlr.refContractIndex4;
        String refContractIndex5 = ctrlr.refContractIndex5;
        String refContractIndex6 = ctrlr.refContractIndex6;
        String refContractIndex7 = ctrlr.refContractIndex7;
        String refContractTotalTo = ctrlr.refContractTotalTo;
        String scontractTotalToDiff = ctrlr.scontractTotalToDiff;
        String sNegoBaseInitFormula1 = ctrlr.sNegoBaseInitFormula1;
        String sPoids = ctrlr.sPoids;
        String TargetContractDate = ctrlr.TargetContractDate;
        String TargetSignatureDate = ctrlr.TargetSignatureDate;
        String sGap_2_3net_perc = ctrlr.sGap_2_3net_perc;
        String sGap_2_3net = ctrlr.sGap_2_3net;
        String sGap_2_3_4net_perc = ctrlr.sGap_2_3_4net_perc;
        String sNegoBaseInitFormula3 = ctrlr.sNegoBaseInitFormula3;
        String sGap_5net = ctrlr.sGap_5net;
        String sGap_5net_perc = ctrlr.sGap_5net_perc;
        String sGap_4net_perc = ctrlr.sGap_4net_perc;
        String sGap_4net = ctrlr.sGap_4net;
        String sNegoBaseInit_valeurReelle_index4 = ctrlr.sNegoBaseInit_valeurReelle_index4;
        String sPLAN_Target_Index5_Nego_val = ctrlr.sPLAN_Target_Index5_Nego_val;
        String sPLAN_Target_Index4_Nego_val = ctrlr.sPLAN_Target_Index4_Nego_val;
        String sNEGO_NegoIntro_4Net_Prog_val_Last = ctrlr.sNEGO_NegoIntro_4Net_Prog_val_Last;
        String sNEGO_NegoIntro_5Net_Prog_val_Last = ctrlr.sNEGO_NegoIntro_5Net_Prog_val_Last;
        
        String back = ctrlr.back;
        String negotiateFollowUpURL = ctrlr.negotiateFollowUpURL;
        String negotiateURL = ctrlr.negotiateURL;
        String backURL = ctrlr.backURL;
        String formattedEndDate = ctrlr.formattedEndDate;
        String formattedBeginDate = ctrlr.formattedBeginDate;
        String safebalanceRTName = ctrlr.safebalanceRTName;
        
        Boolean displayPopup = ctrlr.displayPopup;
        Boolean showSendApprovalButton = ctrlr.showSendApprovalButton;
        Decimal contractTotalTO2NetDiff = ctrlr.contractTotalTO2NetDiff;
        Decimal contractTotalToDiff = ctrlr.contractTotalToDiff;
        List<Contract_Discount__c> refProgressiveConditions = ctrlr.refProgressiveConditions;
        List<Contract_Discount__c> newProgressiveConditions = ctrlr.newProgressiveConditions;
        List<Contract_Discount__c> NegoBaseInitProgressiveConditions = ctrlr.NegoBaseInitProgressiveConditions;
        List<Contract_Discount__c> safeProgressiveConditions = ctrlr.safeProgressiveConditions;
        ctrlr.showPopup();
        ctrlr.closePopup();
        ctrlr.attachPdfToObjectAndEmail(null);
        Test.stopTest();
        system.assertEquals('', ctrlr.contentType); //contentType should not be changed >> rendered as html
    }
    // Success test
    @isTest static void test_constructor1() {
        init();
        ApexPages.currentPage().getParameters().put('id', topContract.Id);
        Test.startTest();
        ExecutiveSummaryController ctrlr = new ExecutiveSummaryController();
        ctrlr.refContract = negoBaseContract;
        Contract__c c = [SELECT Id, Name, Reference_Year__c, BusinessUnitContract__c, Status__c, CreatedBy.Name,
                         Supplier_Nego_Scope__c, Supplier__c, Parent_Contract__c
                         FROM Contract__c
                         WHERE Id = :topContract.Id];
        Test.stopTest();
        system.assertEquals(c.Id, ctrlr.topContract.Id);
        system.assertEquals(c.Name, ctrlr.topContract.Name);
        system.assertEquals(c.Reference_Year__c, ctrlr.topContract.Reference_Year__c);
        system.assertEquals(c.BusinessUnitContract__c, ctrlr.topContract.BusinessUnitContract__c);
        system.assertEquals(c.Status__c, ctrlr.topContract.Status__c);
        system.assertEquals(c.CreatedById, ctrlr.topContract.CreatedById);
        system.assertEquals(c.Supplier_Nego_Scope__c, ctrlr.topContract.Supplier_Nego_Scope__c);
        system.assertEquals(c.Supplier__c, ctrlr.topContract.Supplier__c);
        system.assertEquals(c.Parent_Contract__c, ctrlr.topContract.Parent_Contract__c);
    }
    
    @isTest static void test_submitApproval() {
        init();
        Integer nextYear = year + 1;
        Test.startTest();
        // Create Condition
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(nextYear, 1, 1),
                                                                   Disc_EDate__c = date.newInstance(nextYear, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                                   BusinessUnitScope__c = country.Id, Contract__c = topContract.Id);
        insert condition2;
        Nego_Plan__c negoPlan = new Nego_Plan__c(Nego_Scope__c = topContract.Supplier_Nego_Scope__c,
                                    Nego_Year__c = nextYear,
                                    NEGO_Rise_Rate_Validated_YE__c = 10,
                                    NEGO_Depreciation_Rate_Validated_YE__c = 10);
        insert negoPlan;
        ApexPages.currentPage().getParameters().put('id', topContract.Id);
        ExecutiveSummaryController ctrlr = new ExecutiveSummaryController();
        ctrlr.submitApproval();
        Test.stopTest();
        String status = [SELECT Status__c FROM Contract__c WHERE Id = :topContract.Id].Status__c;
        system.assertEquals(status, ctrlr.topContract.Status__c);
        system.assertEquals(new List<SelectOption>(), ctrlr.getListMultiYear());
        // ctrlr.back();
    }
    // test ExecutiveSummaryPDFController
    @isTest static void test_executiveSummaryPDFController() {
        Test.startTest();
        init();
        Test.stopTest();
        ApexPages.currentPage().getParameters().put('id', topContract.Id);
        ExecutiveSummaryPDFController ctrlr = new ExecutiveSummaryPDFController();
        system.assertEquals(ctrlr.imgLeft, ctrlr.imgLeft);
        system.assertEquals(ctrlr.imgRight, ctrlr.imgRight);
        system.assertEquals(ctrlr.imgUp, ctrlr.imgUp);
        system.assertEquals(ctrlr.imgDown, ctrlr.imgDown);
    }
}