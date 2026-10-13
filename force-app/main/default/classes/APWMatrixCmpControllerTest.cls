/**
* @author ULiT
* @date 16/10/2023
* @description Unit test class for the class APWMatrixCmpController
*/
@isTest
private class APWMatrixCmpControllerTest {
    private static Id rootId;
    private static Supplier__c supplier;
    private static NegoScope__c ns;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static List<Product2> products;
    private static List<PG__c> pgs;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static Assortment_BU__c assortmentBU;
    private static BusinessUnit__c country;
    private static List<Hierarchy__c> orgaHEList;
    private static CommercialPlan__c comPlan;
    private static List<CommercialPlanDetail__c> commPlandetailToInsert;
    private static List<Assortment_PriceWaterFall__c> PWFToInsert;
    private static final Integer N = 4;
    private static List<Contract__c> contractList;
    private static List<Tax__c> orgaTaxesList;
    private static List<Pol_Com_Condition__c> polComConditionsList;
    private static List<Contract_Discount__c> discountList;
    
    static void init() {
        system.debug(' 1>>>> ' + Limits.getQueries());
        // Root element Id.
        rootId = NegoptimHelper.getHierarchyRootId('Product');
        system.debug(' 11>>>> ' + Limits.getQueries());
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBusinessUnitCountry(false, region.Id);
        country.IsMasterBU__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(true, country, true);
        ns = TestDataFactory.createNegoScope(true, supplier,'negoScopeTest');
        // create HEs
        department = TestDataFactory.createHierarchyDepartment(false, rootId);
        department.SetProductLevel__c = true;
        insert department;
        section = TestDataFactory.createHierarchySection(true, department.Id);
        orgaHEList = TestDataFactory.createElementHierarchy(4, 1);
        // create Source BU Channel
        buSource = TestDataFactory.createBusinessUnitChannel(false, country);
        buSource.IsMasterBU__c = true;
        buSource.Status__c = 'Open';
        // create Target BU Banner
        buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
        buTarget.Hierarchy__c = orgaHEList[1].Id;
        buTarget.SetAssortmentBudgetBUTarget__c = true;
        buTarget.IsMasterBU__c = true;
        buTarget.Status__c = 'Open';
        insert new List<BusinessUnit__c>{buTarget, buSource};
        // Create Product.
        products = new List<Product2>();
        for (Integer i = 0; i < 26; i++) {
            products.add(TestDataFactory.createProduct(false, orgaHEList[3].Id, null));
        }
        insert products;
        pgs = new List<PG__c>();
        for (Integer i = 0; i < 26; i++) {
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Status__c = 'Open';
            pg.Product__c = products[i].Id;
            pg.GrossPrice__c = 100;
            pgs.add(pg);
        }
        insert pgs;
        system.debug(' 4>>>> ' + Limits.getQueries());
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, orgaHEList[1]);
        // create banner for contract bu
        BusinessUnit__c banner = TestDataFactory.createBusinessUnitBanner(false, country);
        banner.Supplier__c = supplier.Id;
        banner.Mission__c = 'Offer';
        banner.isMasterBU__c = false;
        insert banner;
        // list of contracts for mass tests
        contractList = new List<Contract__c>();
        for (integer i = 0; i < N; i++) {
            Contract__c contract = TestDataFactory.createContract(false, banner, supplier, ns);
            contract.Name = null;
            contract.BusinessUnitSource__c = null;
            contract.Is_NetPrice_Statement_Requested__c = true;
            contract.Status__c = 'Validated';
            contractList.add(contract);
        }
        insert contractList;
        // create Orga_Taxes
        orgaTaxesList = new List<Tax__c>();
        for (integer i = 0; i < N; i++) {
            Tax__c tax = TestDataFactory.createTax(false, country, country);
            tax.DisplayOrder__c = i + 1;
            orgaTaxesList.add(tax);
        }
        insert orgaTaxesList;
        // create Pol_Com_Conditions
        polComConditionsList = new List<Pol_Com_Condition__c>();
        for (Integer i = 0; i < N; i++) {
            Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Is_NetPrice_Statement_Condition__c = true;
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.BusinessUnitMaster__c= banner.Id;
            tariffCondition.Condition_Status__c = 'Open';
            tariffCondition.Used_as_SubCondition_only__c = false;
            tariffCondition.Specific_Contract_Type_Authorization__c = 'Negotiation';
            tariffCondition.Nego_Discount_Type__c = 'Price Discount';
            tariffCondition.SetCommercialPlanDetail1__c = (i == N-1);
            if (math.mod(i, 2) == 0) {
                tariffCondition.Condition_Mode__c = 'U';
            }
            polComConditionsList.add(tariffCondition);
        }
        insert polComConditionsList;
        // create Contract_Discount__c
        discountList = new List<Contract_Discount__c>();
        for (Integer i = 0; i < N; i++) {
            Contract_Discount__c discount = TestDataFactory.createCondition(false, polComConditionsList[i], contractList[0], contractList[0].Contract_BDate__c, contractList[0].Contract_EDate__c);
            discount.Rank__c = 1;
            discount.Display_Order__c = i + 1;
            discount.Product_Scope__c = contractList[0].Supplier_Nego_Scope__c;
            discount.Is_Tariff_Condition__c = true;
            discountList.add(discount);
        }
        insert discountList;
        List<Contract_Discount__c> discounts = [SELECT Id, Name, Display_Order__c, Condition_Type__r.Condition_Mode__c FROM Contract_Discount__c WHERE ID IN :discountList];
        List<APWMatrixCmpController.StatementWrapper> statmentList =  new List<APWMatrixCmpController.StatementWrapper>();
        List<APWMatrixCmpController.StatementWrapper> statmentListTaxes =  new List<APWMatrixCmpController.StatementWrapper>();
        for(Contract_Discount__c disc : discounts){
            APWMatrixCmpController.StatementWrapper statementW = new APWMatrixCmpController.StatementWrapper(disc.Id, disc.Name,(Integer) disc.Display_Order__c);
            statementW.conditionMode = disc.Condition_Type__r.Condition_Mode__c;
            statmentList.add(statementW);
        }
        for (Tax__c taxe : orgaTaxesList) {
            APWMatrixCmpController.StatementWrapper statementW = new APWMatrixCmpController.StatementWrapper(taxe.Id, taxe.Name, 1);
            statmentListTaxes.add(statementW);
        }
        assortmentBU.Contract_Active_Discounts__c = JSON.serialize(statmentList);
        assortmentBU.Contract_Active_Taxes__c = JSON.serialize(statmentListTaxes);
        assortmentBU.Contract__c = contractList[0].Id;
        insert assortmentBU;
        PWFToInsert = new List<Assortment_PriceWaterFall__c>();
        for (Integer i = 0; i < 26; i++) {
            Assortment_PriceWaterFall__c priceWaterfall = TestDataFactory.createAssortmentPriceWaterFall(false, assortmentBU.Id, products.get(i).Id, null, null);
            priceWaterfall.PG__c = pgs[i].Id;
            priceWaterfall.Movement_Date__c = system.today();
            priceWaterfall.Status__c = 'In Preparation';
            priceWaterfall.Hierarchy__c =  orgaHEList[1].Id;
            priceWaterfall.Version__c =  NULL;
            priceWaterfall.ScheduledForWithdrawal__c = false;
            PWFToInsert.add(priceWaterfall);
        }
        insert PWFToInsert;
    }
    
    static testmethod void case1_getData() {
        init();
        Test.startTest();
        /*APWMatrixCmpController.FilterTermWrapper filterData = new APWMatrixCmpController.FilterTermWrapper();
        String recordId = (String) assortmentBU.Id;
        String prodSerialized = APWMatrixCmpController.getproductsKeys(recordId, JSON.serialize(filterData));
        String dataSerialized = APWMatrixCmpController.getInitialData(recordId, null);
        List<String> prodKeySet = (List<String>) JSON.deserialize(prodSerialized, List<String>.class);
        List<String> isUpdateList = new List<String>();
        String searchSerialized = APWMatrixCmpController.search(dataSerialized, JSON.serialize(filterData), recordId, prodKeySet, 1000, 1, true, isUpdateList);
        Map<String, Assortment_PriceWaterFall__c> updatedData = new  Map<String, Assortment_PriceWaterFall__c>();
        for(Assortment_PriceWaterFall__c pwf : PWFToInsert){
           	pwf.Acceptance_Status__c = 'Refused';
            updatedData.put((String)pwf.Id, pwf);
        }
        APWMatrixCmpController.fakeSave(dataSerialized, JSON.serialize(updatedData), JSON.serialize(filterData), recordId, new List<String>(), 10, 1);*/
        Test.stopTest();
    }
    
    static testmethod void case2_importExcel() {
        List<String> fields = new List<String>{'Id','Hierarchy__c','ProductCode','Product_EAN__c','Product__c','UC__c','Total_Weight__c','Element_nb__c','Reference_Product__c','Promo_Event__c','Code__c','Promo_Event_Detail_BDate__c','Promo_Event_Detail_EDate__c','RecordTypeId','Movement_Date__c','New_CostPrice__c','New_NetPrice_woTax__c','New_NetPrice_wTax__c','New_NetPrice_Proforma__c','New_NetPrice_Gap_Comment__c','Acceptance_Status__c','New_Disc_1__c','New_Disc_1_Rank__c','New_Disc_2__c','New_Disc_2_U__c','New_Disc_2_UType__c','New_Disc_2_Rank__c','New_Disc_3__c','New_Disc_3_U__c','New_Disc_3_UType__c','New_Disc_3_Rank__c'};
        List<String> fieldsToUpdate = new List<String>{'New_CostPrice__c','New_NetPrice_Gap_Comment__c','Acceptance_Status__c','New_Disc_2__c','New_Disc_2_U__c','New_Disc_3__c','New_Disc_3_U__c'};
        String xlsString ='[{"Id":"Id","Category": "Hierarchy__c","Product__r.ProductCode": "Code du produit","Product__r.Product_EAN__c": "EAN","Product__c": "Produit","Product__r.UC__c": "Choix unité de mesure","Product__r.Total_Weight__c": "Poids total","Product__r.Element_nb__c": "Nombre dunité dans le produit","Product__r.Reference_Product__c": "Produit de référence","Promo_Event__c": "Evènement promo","Promo_Event_Detail__c": "Ligne promo","Promo_Event_Detail_BDate__c": "Date début promo","Promo_Event_Detail_EDate__c": "Date fin promo","Status__c": "Statut","New_CostPrice__c": "Prix dachat brut","New_NetPrice_woTax__c": "PRIX FACTURE HORS TAXES","New_NetPrice_wTax__c": "prix net dont taxes","PriceBeforePromoDisc__c": "Prix avant promo","New_Disc_1__c": "PLD_YC22_Remise_Accord %","New_Disc_1_Rank__c": "PLD_YC22_Remise_Accord Rank","New_Disc_2__c": "Line_Pricing_PPD_YCC3 %","New_Disc_2_Rank__c": "Line_Pricing_PPD_YCC3 Rank","New_Disc_3__c": "PLD_YXAY_Remise_Gamme %","New_Disc_3_Rank__c": "PLD_YXAY_Remise_Gamme Rank"}]';
        APWMatrixCmpController.importRecords(fields, fieldsToUpdate, xlsString);
    }
    
    static testmethod void case3_save() {
        init();
        Map<String, Assortment_PriceWaterFall__c> updatedData = new  Map<String, Assortment_PriceWaterFall__c>();
        for(Assortment_PriceWaterFall__c pwf : PWFToInsert) {
           	pwf.Acceptance_Status__c = 'Approved';
            updatedData.put((String)pwf.Id, pwf);
        }
        APWMatrixCmpController.save(JSON.serialize(updatedData));
    }
    
    static testmethod void case4_setStatusPWF() {
        init();
        system.debug('setStatusPriceWaterFall >>>' + [SELECT Id FROM Assortment_PriceWaterFall__c WHERE Version__c = NULL AND Product__c <> NULL
                           AND Assortment_BU__r.Contract__c <> NULL AND ScheduledForWithdrawal__c = FALSE]);
        String assortmentListJson = JSON.serialize(new Set<Id>{assortmentBU.Id});
        Map<Id, Assortment_PriceWaterFall__c> PWFIDsMap = new Map<Id, Assortment_PriceWaterFall__c>([SELECT Id , Acceptance_Status__c FROM Assortment_PriceWaterFall__c WHERE ID IN :PWFToInsert]);
        String PWFIdsSerialized = JSON.serialize(PWFIDsMap.keySet());
        APWMatrixCmpController.setStatusPriceWaterFall(PWFIdsSerialized, assortmentListJson);
        NegoptimHelper.checkCompletedBatches(null);
    }

    Static testmethod void case5_filterData(){
        init();
        Test.startTest();
        APWMatrixCmpController.FilterTermWrapper filterData = new APWMatrixCmpController.FilterTermWrapper();
        filterData.dateOperator = ' >= ';
        /*filterData.calendarSearchTerm = String.valueOf(System.today());
        filterData.minMovementDate = String.valueOf(System.today()-10);
        filterData.maxMovementDate = String.valueOf(System.today());*/
        filterData.categorySearchTerm = String.valueOf(section.Id);
        //filterData.isOnlyPromo = false;
        String recordId = (String) assortmentBU.Id;
        String prodSerialized = APWMatrixCmpController.getproductsKeys(recordId, JSON.serialize(filterData));
        String dataSerialized = APWMatrixCmpController.getInitialData(recordId, null);
        List<String> prodKeySet = (List<String>) JSON.deserialize(prodSerialized, List<String>.class);
        List<String> isUpdateList = new List<String>();
        filterData.productSearchTerm = JSON.serialize(products[2].Product_EAN__c);
        String searchSerialized = APWMatrixCmpController.search(dataSerialized, JSON.serialize(filterData), recordId, prodKeySet, 1000, 1, false, isUpdateList);
        Test.stopTest();
    }
}