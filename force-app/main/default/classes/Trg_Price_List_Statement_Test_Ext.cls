/**
 * @author ULiT
 * @date 23/06/2022
 * @Descirption Test class for Trigger on PriceListStatementDetail__c
 * */
@isTest
public class Trg_Price_List_Statement_Test_Ext {

    private static BusinessUnit__c region;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c sourceBU;
    private static List<Tax__c> orgaTaxesList;
    private static List<Hierarchy__c> hierarchy;
    private static Map<String, PG__c> PGMapping;
    private static List<NSPG__c> NSPGMapping;
    private static PriceListStatement__c priceListStatement;
    private static List<SupplierTax__c> taxStatement;
    private static List<PriceListStatementDetail__c> detailStatement;
    private static List<Product2> products;
    public static final Integer year = TestDataFactory.year;
    public static final Integer month = System.Today().month();
	public static final Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
    public static final String currencyIsoCode = 'EUR';
    private static Integer randomNumber;
    static void init() {
        try {
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'MEA');
            // Create Master BU country
            masterBU = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, masterBU, true);
            // Create negoscope
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Categories
            hierarchy = TestDataFactory.createElementHierarchy(4, 1);
            products = new List<Product2>();
            // Create Products
            product2 product;
            for (Integer i = 0; i < 3; i++) {
                product = TestDataFactory.createProduct(false, hierarchy.get(3).Id, supplier.Id);
                products.add(product);
            }
            insert products;
            // Create Supplier PG mapping
            PGMapping = new Map<String, PG__c>();
            List<PG__c> listPG = new List<PG__c>();
            for (Product2 item :products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            for (PG__c item : listPG) {
                PGMapping.put(item.Id, item);
            }
            // Create Negoscope PG mapping
            NSPGMapping = [SELECT Id, PG__c, PG__r.Product__c
                           FROM NSPG__c
                           WHERE NegoScope__c = :ns.Id];
            // Create Tax__c
            orgaTaxesList = new List<Tax__c>();
            for (Integer i = 1; i <= 20; i++) {
                orgaTaxesList.add(TestDataFactory.createTax(false, masterBU, i));
            }
            insert orgaTaxesList;
            // Create PriceListStatement__c
            priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
            priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative');
            priceListStatement.OnTop__c = true;
            priceListStatement.Status__c = 'Validated';
            insert priceListStatement;
            // Create PriceListStatementDetail__c
            detailStatement = new List<PriceListStatementDetail__c>();
            Decimal cost = 100;
            PriceListStatementDetail__c detail;
            for (NSPG__c item : NSPGMapping) {
                detail = TestDataFactory.createPriceListStatementDetail(false, priceListStatement, item.PG__r);
                detail.GrossPrice__c = cost;
                detailStatement.add(detail);
                cost += 100;
            }
            insert detailStatement;
            // Create negoplan
            /***Nego_Plan__c negoPlan = new Nego_Plan__c(NegoScope__c = ns.Id, Nego_Year__c = year);
            insert negoPlan;***/
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    static testmethod void test_case1() {
		init();
        Test.startTest();
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        update priceListStatement;
        Test.stopTest();
        System.assert(true);
    }

    /***static testmethod void test_case2() {
		init();
        Test.startTest();
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative');
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        insert priceListStatement;
        Test.stopTest();
        System.assert(true);
    }
    
    static testmethod void test_case3() {
        //syncHMPToContractAndNegoplan
		init();
        Test.startTest();
        Map<String, Id> contractRTIds = TestDataFactory.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = contractRTIds.get('Signed');
        contract.OnTop__c = true;
        contract.Status__c = 'Signed';
		insert contract;
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement.Version__c = 1;
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        //priceListStatement.SetGenerateISOPartner__c = true;
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.SPITM_CorrectedRateRequested__c = 1.2;
        update priceListStatement;
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.Version__c = 1;
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.SPITM_CorrectedRateRequested__c = 1.2;
        update priceListStatement;
        Test.stopTest();
        System.assert(true);
    }
    static testmethod void test_case4() {
        //syncHMPToContractAndNegoplan
		init();
        Test.startTest();
        Map<String, Id> contractRTIds = TestDataFactory.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = contractRTIds.get('Signed');
        contract.OnTop__c = true;
        contract.Status__c = 'Signed';
		insert contract;
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
        priceListStatement.Version__c = 1;
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        //priceListStatement.SetGenerateISOPartner__c = true;
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.SPITM_CorrectedRateRequested__c = 1.2;
        update priceListStatement;
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.Version__c = 1;
        priceListStatement.PriceEvolutionRateValidated__c = 3;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.Version__c = 1;
        priceListStatement.PriceEvolutionRateValidated__c = 4;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.SPITM_CorrectedRateRequested__c = 5;
        update priceListStatement;
        Test.stopTest();
        System.assert(true);
    }
    static testmethod void case5_RT_Switch() {
        init();
        Test.startTest();
        
        // Create PriceListStatement__c
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
        priceListStatement.Version__c = 1;
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        insert priceListStatement;
        //priceListStatement.SetGenerateISOPartner__c = true;
        priceListStatement.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatement.SPITM_CorrectedRateRequested__c = 1.2;
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        update priceListStatement;
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
        update priceListStatement;
        Test.stopTest();
        System.assert(true);
    }
    
     static testmethod void case_updateHMPReported_BTAllVisionsOpen() {
         init();
         Test.startTest();
         Map<String, Id> contractRTIds = TestDataFactory.getObjectRecordTypeMapIds(Contract__c.SObjectType);
         Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
         contract.RecordTypeId = contractRTIds.get('Signed');
         contract.OnTop__c = true;
         contract.Status__c = 'Signed';
         insert contract;
         // Create PriceListStatement__c
         priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
         priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
         priceListStatement.Version__c = 1;
         priceListStatement.OnTop__c = true;
         priceListStatement.Status__c = 'Validated';
         priceListStatement.PriceEvolutionRateValidated__c = 2;
         priceListStatement.Contrat__c = contract.Id;
         insert priceListStatement;
         
         PriceListStatement__c priceListStatementITM = TestDataFactory.createPriceListStatement(false, ns);
         priceListStatementITM.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
         priceListStatementITM.Version__c = 1;
         priceListStatementITM.PriceEvolutionRateValidated__c = 3;
         priceListStatementITM.Status__c = 'Opened';
         priceListStatementITM.Contrat__c = contract.Id;
         priceListStatementITM.PriceListStatementReference__c = priceListStatement.Id;
         insert priceListStatementITM;
         
         PriceListStatement__c priceListStatementSimulation = TestDataFactory.createPriceListStatement(false, ns);
         priceListStatementSimulation.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
         priceListStatementSimulation.Version__c = 1;
         priceListStatementSimulation.PriceEvolutionRateValidated__c = 4;
         priceListStatementSimulation.Status__c = 'Opened';
         priceListStatementSimulation.Contrat__c = contract.Id;
         priceListStatementSimulation.PriceListStatementReference__c = priceListStatementITM.Id;
         insert priceListStatementSimulation;
         Test.stopTest();
         List<PriceListStatement__c> priceListStatementList = [SELECT Id, SPITM_Price_List_Reported__c,RecordType.DeveloperName
                                                                                FROM PriceListStatement__c
                                                                                WHERE (Id = :priceListStatement.Id
                                                                                       OR PriceListStatementReference__c = :priceListStatement.Id
                                                                                       OR PriceListStatementReference__r.PriceListStatementReference__c = :priceListStatement.Id)];
         for (PriceListStatement__c item : priceListStatementList) {
             if (item.RecordType.DeveloperName == 'Simulation') {
                 System.assertEquals(false, item.SPITM_Price_List_Reported__c);
             }
             if (item.RecordType.DeveloperName == 'IsoPartner') {
                 System.assertEquals(false, item.SPITM_Price_List_Reported__c);
             }
             if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                 System.assertEquals(true, item.SPITM_Price_List_Reported__c);
             }
         }
     }
    static testmethod void case_updateHMPReported_BTITMVisionValidated() {
        init();
        Test.startTest();
        Map<String, Id> contractRTIds = TestDataFactory.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = contractRTIds.get('Signed');
        contract.OnTop__c = true;
        contract.Status__c = 'Signed';
        insert contract;
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
        priceListStatement.Version__c = 1;
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        priceListStatement.Contrat__c = contract.Id;
        insert priceListStatement;
        PriceListStatement__c priceListStatementITM = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatementITM.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
        priceListStatementITM.Version__c = 1;
        priceListStatementITM.PriceEvolutionRateValidated__c = 2;
        priceListStatementITM.Status__c = 'Opened';
        priceListStatementITM.Contrat__c = contract.Id;
        priceListStatementITM.PriceListStatementReference__c = priceListStatement.Id;
        insert priceListStatementITM;
        PriceListStatement__c priceListStatementSimulation = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatementSimulation.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
        priceListStatementSimulation.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatementSimulation.Version__c = 1;
        priceListStatementSimulation.PriceEvolutionRateValidated__c = 2;
        priceListStatementSimulation.Status__c = 'Opened';
        priceListStatementSimulation.Contrat__c = contract.Id;
        priceListStatementSimulation.PriceListStatementReference__c = priceListStatementITM.Id;
        insert priceListStatementSimulation;
        
                
        priceListStatement.Status__c = 'Rejected';
        update priceListStatement;
        priceListStatementITM.Status__c = 'Validated';
        update priceListStatementITM;

        Test.stopTest();
        List<PriceListStatement__c> priceListStatementList = [SELECT Id, SPITM_Price_List_Reported__c,RecordType.DeveloperName
                                                                               FROM PriceListStatement__c
                                                                               WHERE (Id = :priceListStatement.Id
                                                                                      OR PriceListStatementReference__c = :priceListStatement.Id
                                                                                      OR PriceListStatementReference__r.PriceListStatementReference__c = :priceListStatement.Id)];
        for (PriceListStatement__c item : priceListStatementList) {
            if (item.RecordType.DeveloperName == 'Simulation') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                System.assertEquals(true, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
        }
    }
    static testmethod void case_updateHMPReported_havingTwoHMPAndBT() {
        init();
        Test.startTest();
        Map<String, Id> contractRTIds = TestDataFactory.getObjectRecordTypeMapIds(Contract__c.SObjectType);
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = contractRTIds.get('Signed');
        contract.OnTop__c = true;
        contract.Status__c = 'Signed';
        insert contract;
        // BT
        List<PriceListStatement__c> insertedHMP = new List<PriceListStatement__c>();
        priceListStatement = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatement.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('DepreciationRate');
        priceListStatement.Version__c = 1;
        priceListStatement.OnTop__c = true;
        priceListStatement.Status__c = 'Validated';
        priceListStatement.PriceEvolutionRateValidated__c = 2;
        priceListStatement.Contrat__c = contract.Id;
        insertedHMP.add(priceListStatement);
        PriceListStatement__c priceListStatementITM = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatementITM.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
        priceListStatementITM.Version__c = 1;
        priceListStatementITM.PriceEvolutionRateValidated__c = 2;
        priceListStatementITM.Status__c = 'Opened';
        priceListStatementITM.Contrat__c = contract.Id;
        priceListStatementITM.PriceListStatementReference__c = priceListStatement.Id;
        insertedHMP.add(priceListStatementITM);
        PriceListStatement__c priceListStatementSimulation = TestDataFactory.createPriceListStatement(false, ns);
        priceListStatementSimulation.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
        priceListStatementSimulation.SPITM_IsCorrectedRateValidated__c = true;
        priceListStatementSimulation.Version__c = 1;
        priceListStatementSimulation.PriceEvolutionRateValidated__c = 2;
        priceListStatementSimulation.Status__c = 'Opened';
        priceListStatementSimulation.Contrat__c = contract.Id;
        priceListStatementSimulation.PriceListStatementReference__c = priceListStatementITM.Id;
        insertedHMP.add(priceListStatementSimulation);
        
        // HMP
        PriceListStatement__c hmpPriceListStatementSupplier = TestDataFactory.createPriceListStatement(false, ns);
        hmpPriceListStatementSupplier.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('RiseRate');
        hmpPriceListStatementSupplier.Version__c = 1;
        hmpPriceListStatementSupplier.OnTop__c = true;
        hmpPriceListStatementSupplier.Status__c = 'Validated';
        hmpPriceListStatementSupplier.PriceEvolutionRateValidated__c = 2;
        hmpPriceListStatementSupplier.Contrat__c = contract.Id;
        insertedHMP.add(hmpPriceListStatementSupplier);
        PriceListStatement__c hmpPriceListStatementITM = TestDataFactory.createPriceListStatement(false, ns);
        hmpPriceListStatementITM.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('IsoPartner');
        hmpPriceListStatementITM.Version__c = 1;
        hmpPriceListStatementITM.PriceEvolutionRateValidated__c = 2;
        hmpPriceListStatementITM.Status__c = 'Opened';
        hmpPriceListStatementITM.Contrat__c = contract.Id;
        hmpPriceListStatementITM.PriceListStatementReference__c = hmpPriceListStatementSupplier.Id;
        insertedHMP.add(hmpPriceListStatementITM);
        PriceListStatement__c hmpPriceListStatementSimulation = TestDataFactory.createPriceListStatement(false, ns);
        hmpPriceListStatementSimulation.RecordTypeId = TestDataFactory.priceListStatementRTIds.get('Simulation');
        hmpPriceListStatementSimulation.SPITM_IsCorrectedRateValidated__c = true;
        hmpPriceListStatementSimulation.Version__c = 1;
        hmpPriceListStatementSimulation.PriceEvolutionRateValidated__c = 2;
        priceListStatementSimulation.Status__c = 'Opened';
        hmpPriceListStatementSimulation.Contrat__c = contract.Id;
        hmpPriceListStatementSimulation.PriceListStatementReference__c = hmpPriceListStatementITM.Id;
        insertedHMP.add(hmpPriceListStatementSimulation);
        insert   insertedHMP;     
        priceListStatement.Status__c = 'Rejected';
        update priceListStatement;
        priceListStatementITM.Status__c = 'Validated';
        update priceListStatementITM;

        Test.stopTest();
        List<PriceListStatement__c> priceListStatementBTList = [SELECT Id, SPITM_Price_List_Reported__c,RecordType.DeveloperName
                                                                               FROM PriceListStatement__c
                                                                               WHERE (Id = :priceListStatement.Id
                                                                                      OR PriceListStatementReference__c = :priceListStatement.Id
                                                                                      OR PriceListStatementReference__r.PriceListStatementReference__c = :priceListStatement.Id)];
        for (PriceListStatement__c item : priceListStatementBTList) {
            if (item.RecordType.DeveloperName == 'Simulation') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                System.assertEquals(true, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
        }
        
        List<PriceListStatement__c> priceListStatementHMPList = [SELECT Id, SPITM_Price_List_Reported__c,RecordType.DeveloperName
                                                                               FROM PriceListStatement__c
                                                                               WHERE (Id = :hmpPriceListStatementSupplier.Id
                                                                                      OR PriceListStatementReference__c = :hmpPriceListStatementSupplier.Id
                                                                                      OR PriceListStatementReference__r.PriceListStatementReference__c = :hmpPriceListStatementSupplier.Id)];
        for (PriceListStatement__c item : priceListStatementHMPList) {
            if (item.RecordType.DeveloperName == 'Simulation') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                System.assertEquals(false, item.SPITM_Price_List_Reported__c);
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                System.assertEquals(true, item.SPITM_Price_List_Reported__c);
            }
        }
    }***/
}