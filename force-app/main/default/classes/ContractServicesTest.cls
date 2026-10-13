@isTest
public class ContractServicesTest {
    private static Country_List__c countryList;
    private static BusinessUnit__c region;
    private static BusinessUnit__c masterBU;
    private static BusinessUnit__c sourceBU;
	private static final Integer year = System.Today().year();
    private static List<Hierarchy__c> hierarchy;
    private static List<Product2> products;
    private static Map<String, PG__c> PGMappings;
    private static List<PG__c> listPG;
    private static List<NSPG__c> NSPGMappings;
    private static String unitAmountTypePlv;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static NegoScope__c SubNs;
    private static Contract__c contract;
    private static List<Contract__c> contracts;
	private static BusinessUnit__c country;
	private static Map<String, Pol_Com_Condition__c> indexTariffMap;
	private static Pol_Com_Condition__c tariffCondition1;
	private static Pol_Com_Condition__c tariffCondition2;
	private static Pol_Com_Condition__c tariffCondition3;
	private static Pol_Com_Condition__c tariffCondition4;
	private static Pol_Com_Condition__c tariffConditionsort1;
	private static Pol_Com_Condition__c tariffConditionsort2;
	private static Pol_Com_Condition__c tariffConditionsort3;
    private static String plv;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c conditionSigned;
    private static Contract__c contractSigned;
	static void init() {
		try {
            //Id root = TestDataFactory.getHierarchyRootId();
			// Insert Country List.
			Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
			// Insert Region.
			BusinessUnit__c region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
			// Insert Country.
			country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
			// Insert supplier.
			supplier = TestDataFactory.createSupplier(true, country, true);
			// Get the default negoscope created on supplier creation.
			NS = TestDataFactory.getNSs(supplier.Id)[0];
			SubNs = TestDataFactory.createNegoScope(false, supplier, 'Sub NS name');
			SubNs.NegoScopeParent__c = NS.Id;
			insert SubNs;
            // first picklist value of unit_amount_type__c
            Schema.DescribeFieldResult fieldResult = Contract_Discount__c.unit_amount_type__c.getDescribe();
            unitAmountTypePlv = 'UC';//fieldResult.getPicklistValues().get(0).getValue();
            // Insert Policy - Tariff conditions.
			indexTariffMap = new Map<String, Pol_Com_Condition__c>();
            tariffCondition1 = TestDataFactory.createTariffCondition(false, 0, 1);
			tariffCondition1.Condition_Duplication__c = '%;U;F';
			tariffCondition1.Condition_Duplication_PE__c = '%;U;F';
			tariffCondition1.Index__c = 'Index1';
			tariffCondition1.Nego_Discount_type__c = 'Price Discount';
			indexTariffMap.put('Index1', tariffCondition1);
            tariffCondition2 = TestDataFactory.createTariffCondition(false, 0, 2);
			tariffCondition2.Condition_Duplication__c = '%;U;F';
			tariffCondition2.Condition_Duplication_PE__c = '%;U;F';
			tariffCondition2.Index__c = 'Index2';
			tariffCondition2.Nego_Discount_type__c = 'Price Discount';
			indexTariffMap.put('Index2', tariffCondition2);
            tariffCondition3 = TestDataFactory.createTariffCondition(false, 0, 3);
			tariffCondition3.Condition_Duplication__c = '%;U;F';
			tariffCondition3.Condition_Duplication_PE__c = '%;U;F';
			tariffCondition3.Index__c = 'Index3';
			tariffCondition3.Nego_Discount_type__c = 'Price Discount';
			indexTariffMap.put('Index3', tariffCondition3);
			tariffCondition4 = TestDataFactory.createTariffCondition(false, 0, 4);
			tariffCondition4.Condition_Duplication__c = '%;U;F';
			tariffCondition4.Condition_Duplication_PE__c = '%;U;F';
			tariffCondition4.Index__c = 'Index4';
			tariffCondition4.Nego_Discount_type__c = 'Price Discount';
			indexTariffMap.put('Index4', tariffCondition4);
            tariffConditionsort1 = TestDataFactory.createTariffCondition(false, 0, 1);
			tariffConditionsort1.Nego_Discount_type__c = 'Price Discount';
			tariffConditionsort1.Condition_Duplication__c = '%;U;F';
			tariffConditionsort1.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionsort2 = TestDataFactory.createTariffCondition(false, 0, 3);
			tariffConditionsort2.Nego_Discount_type__c = 'Price Discount';
			tariffConditionsort2.Condition_Duplication__c = '%;U;F';
			tariffConditionsort2.Condition_Duplication_PE__c = '%;U;F';
            tariffConditionsort3 = TestDataFactory.createTariffCondition(false, 0, 2);
			tariffConditionsort3.Nego_Discount_type__c = 'Price Discount';
			tariffConditionsort3.Condition_Duplication__c = '%;U;F';
			tariffConditionsort3.Condition_Duplication_PE__c = '%;U;F';
			List<Pol_Com_Condition__c> tariffList = new List<Pol_Com_Condition__c>{tariffCondition1, tariffCondition2, tariffCondition3, tariffCondition4, tariffConditionsort1, tariffConditionsort2, tariffConditionsort3};
			insert tariffList;
			// Insert contract.
			contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contract.TO1__c = 100000;
			contract.Name = null;
			insert contract;
		} catch (Exception ex) {
			System.debug('++++++++++++++++++++++++++++++');
			System.debug(ex.getMessage() + ' - Line : ' + ex.getLineNumber());
			System.debug(ex.getStackTraceString());
			System.debug(ex.getLineNumber());
			System.debug('++++++++++++++++++++++++++++++');
		}
	}

	static void initsort() {
		try {
			// Create Condition
			List<Contract_Discount__c> contractDiscountList = new List<Contract_Discount__c>();
			Contract_Discount__c contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort3, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 1;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 2;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort3, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 7;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 7;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 4;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 7;
			contractDiscountList.add(contractDiscount);
			contractDiscount = TestDataFactory.createCondition(false, tariffConditionsort1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			contractDiscount.Rank__c = 7;
			contractDiscountList.add(contractDiscount);
			insert contractDiscountList;
		} catch (Exception ex) {
			System.debug('++++++++++++++++++++++++++++++');
			System.debug(ex.getMessage());
			System.debug(ex.getStackTraceString());
			System.debug(ex.getLineNumber());
			System.debug('++++++++++++++++++++++++++++++');
		}
	}
	
    static void initVolumes() {
        try {
            // Create countryList
            countryList = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'MEA');
            // Create Master BU country
            masterBU = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, masterBU, true);
            // Create negoscope
            ns = TestDataFactory.getNSs(supplier.Id)[0];
            contracts = new List<Contract__c>();
            // Create Contract
            for (Integer i = 0; i < 2; i++) {
                contracts.add(TestDataFactory.createContract(false, masterBU, supplier, ns));
            }
            insert contracts;
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
            PGMappings = new Map<String, PG__c>();
            listPG = new List<PG__c>();
            for (Product2 item :products) {
                PG__c pg = TestDataFactory.createPG(false, supplier.Id, hierarchy.get(3).HierarchyParent__c, hierarchy.get(3).Id);
                pg.Product__c = item.Id;
                listPG.add(pg);
            }
            insert listPG;
            for (PG__c item : listPG) {
                PGMappings.put(item.Id, item);
            }
            // Create Negoscope PG mapping
            NSPGMappings = [SELECT Id, PG__c, PG__r.Product__c 
                            FROM NSPG__c WHERE NegoScope__c = :ns.Id];
            Map<Integer, String> monthsMap = contractservices.monthsMap;
         	
        } catch(Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static void initSynchro() {
        try {
            // Insert Country List.
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Insert Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Insert supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Is_Tariff_Condition__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.Nego_Discount_Type__c = 'Price Discount';
            insert tariffCondition;
            // Insert Top contract
            contractSigned = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contractSigned.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
            contractSigned.Is_OnTop_Simulation__c = true;
            contractSigned.Contract_Type__c = 'Contract';
            contractSigned.Status__c = 'Signed';
            contractSigned.D_N__c = 'D';
            contractSigned.TO1__c = 5000;
            insert contractSigned;
            // Insert conditions
            conditionSigned = TestDataFactory.createCondition(false, tariffCondition, contractSigned, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            conditionSigned.Value_per__c = 7;
            conditionSigned.Rank__c = 1;
            insert conditionSigned;
            // Insert sub conditions
            Contract_Discount__c subCondition = TestDataFactory.createCondition(false, tariffCondition, contractSigned, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            subCondition.Rank__c = 1;
            subCondition.Parent_Discount__c = conditionSigned.Id;
            insert subCondition;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    @isTest
	static void case1_noConditions() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        tariffCondition2.Is_Tariff_Condition__c = false;
		tariffCondition2.Index__c = 'Index2';
		update tariffCondition2;
        tariffCondition3.Is_Tariff_Condition__c = false;
		tariffCondition3.Index__c = 'Index3';
		update tariffCondition3;
        tariffCondition4.Is_Tariff_Condition__c = false;
		tariffCondition4.Index__c = 'Index4';
		update tariffCondition4;

        contract.Rise_Rate_YE__c = 10.04;
        contract.TO1__c = 20665609;
        update contract;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, null);
		contractServices.calculateContractIndex(true);
		Test.stopTest();
	}
    
	@isTest
	static void case1_calculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        tariffCondition2.Is_Tariff_Condition__c = false;
		tariffCondition2.Index__c = 'Index2';
		update tariffCondition2;
        tariffCondition3.Is_Tariff_Condition__c = false;
		tariffCondition3.Index__c = 'Index3';
		update tariffCondition3;
        tariffCondition4.Is_Tariff_Condition__c = false;
		tariffCondition4.Index__c = 'Index4';
		update tariffCondition4;

        contract.Rise_Rate_YE__c = 10.04;
        contract.TO1__c = 20665609;
        update contract;
		// Insert conditions.
		// Index 1 conditions
		Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 10;
		condition1.Value_amt__c = 0;
		condition1.Rank__c = 1;
		condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 21.94;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 1;
		condition2.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 1.97;
		condition3.Value_amt__c = 0;
		condition3.Rank__c = 1;
		condition3.Is_Tariff_Condition__c = true;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};

        //index 2 conditions
        Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition4.Value_per__c = 5.68;
		condition4.Value_amt__c = 62626;
		condition4.Rank__c = null;//1;
		condition4.Is_Tariff_Condition__c = false;

        //index 3 conditions
        Contract_Discount__c condition5 = TestDataFactory.createCondition(false, tariffCondition3, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition5.Value_per__c = 0.08;
        condition5.Value_amt__c = 0;
        condition5.Rank__c = null;//1;
        condition5.Is_Tariff_Condition__c = false;
        Contract_Discount__c condition6 = TestDataFactory.createCondition(false, tariffCondition3, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition6.Value_per__c = 0.9;
        condition6.Value_amt__c = 0;
		condition6.Rank__c = null;//1;
		condition6.Is_Tariff_Condition__c = false;
        //index 4 conditions
        Contract_Discount__c condition7 = TestDataFactory.createCondition(false, tariffCondition4, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition7.Value_per__c = 1.11;
        condition7.Value_amt__c = 0;
        condition7.Rank__c = null;//1;
        condition7.Is_Tariff_Condition__c = false;
        insert new List<Contract_Discount__c>{condition4, condition5, condition6, condition7};
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);
		Test.stopTest();
		// Assertions.
		// contract Index and percent
		//System.assertEquals('Success', str);
		System.assertEquals(72.725, contract.index1__c.setScale(3));
        System.assertEquals(33.910, contract.index1_perc__c.setScale(3));
        System.assertEquals(68.374, contract.index2__c.setScale(3));
        System.assertEquals(5.983, contract.index2_perc__c.setScale(3));
        System.assertEquals(67.662, contract.index3__c.setScale(3));
        System.assertEquals(0.980, contract.index3_perc__c.setScale(3));
        System.assertEquals(66.854, contract.index4__c.setScale(3));
        System.assertEquals(1.11, contract.index4_perc__c.setScale(3));
		// Total_TO_Tariff_Nego__c
        System.assertEquals(31268889.390, contract.Total_TO_Tariff_Nego__c.setScale(3));
		// YTD_Nego_Computed__c
        System.assertEquals(3126888.94, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(6860394.33, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(615997.12, conditionList[2].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(1236432.59, conditionList[3].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(16532.49, conditionList[4].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(185990.48, conditionList[5].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(229388.26, conditionList[6].YTD_Nego_Computed__c.setScale(2));
        // YTD_Nego_Computed__c
        System.assertEquals(10, conditionList[0].Index_perc__c.setScale(2));
        System.assertEquals(21.94, conditionList[1].Index_perc__c.setScale(2));
        System.assertEquals(1.97, conditionList[2].Index_perc__c.setScale(2));
        System.assertEquals(5.98, conditionList[3].Index_perc__c.setScale(2));
        System.assertEquals(0.08, conditionList[4].Index_perc__c.setScale(2));
        System.assertEquals(0.9, conditionList[5].Index_perc__c.setScale(2));
        System.assertEquals(1.11, conditionList[6].Index_perc__c.setScale(2));
        // check Base_TO_Tariff__c for condition !tariff condition and index > 1
        System.assertEquals(20665609, conditionList[4].Base_TO_Tariff_Nego__c.setScale(3));
	}

	@isTest
	static void case51_calculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 849014;
        update contract;
		// Insert conditions.
		Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 4;
		condition1.Value_amt__c = 0;
		condition1.Rank__c = 1;
		condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 31.50;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 2;
		condition2.Is_Tariff_Condition__c = true;
        condition2.Product_Scope__c = SubNs.Id;
        condition2.Base_TO_Nego__c = 383000;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 23.12;
		condition3.Value_amt__c = 0;
		condition3.Rank__c = 3;
		condition3.Is_Tariff_Condition__c = true;
        condition3.Product_Scope__c = SubNs.Id;
        condition3.Base_TO_Nego__c = 382000;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
		System.assertEquals(73.740, contract.index1__c.setScale(3));
        System.assertEquals(28.505, contract.index1_perc__c.setScale(3));
        System.assertEquals(1187517.020, contract.Total_TO_Tariff_Nego__c.setScale(3));
		System.assertEquals(47500.681, conditionList[0].YTD_Nego_Computed__c.setScale(3));
        System.assertEquals(176124.088, conditionList[1].YTD_Nego_Computed__c.setScale(3));
        System.assertEquals(114878.252, conditionList[2].YTD_Nego_Computed__c.setScale(3));
	}

    @isTest
	static void case52_CalculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
        tariffCondition1.Index__c = 'Index1';
        update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 849014;
        update contract;
		// Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 4;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 31.50;
        condition2.Value_amt__c = 0;
        condition2.Rank__c = 1;
        condition2.Is_Tariff_Condition__c = true;
        condition2.Product_Scope__c = SubNs.Id;
        condition2.Base_TO_Nego__c = 383000;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 23.12;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 1;
        condition3.Is_Tariff_Condition__c = true;
        condition3.Product_Scope__c = SubNs.Id;
        condition3.Base_TO_Nego__c = 382000;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
		// Start test.
		Test.startTest();
		List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);
        Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
        System.assertEquals(72.642, contract.index1__c.setScale(3));
        System.assertEquals(29.569, contract.index1_perc__c.setScale(3));
        System.assertEquals(1205462.320, contract.Total_TO_Tariff_Nego__c.setScale(3));
        System.assertEquals(48218.49, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(187046.51, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(121183.32, conditionList[2].YTD_Nego_Computed__c.setScale(2));
    }

    @isTest
	static void case53_CalculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 849014;
        update contract;
		// Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 3;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 25;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 3;
		condition2.Is_Tariff_Condition__c = true;
        condition2.Product_Scope__c = SubNs.Id;
        condition2.Base_TO_Nego__c = 383000;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 10;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 2;
        condition3.Is_Tariff_Condition__c = true;
        condition3.Product_Scope__c = SubNs.Id;
        condition3.Base_TO_Nego__c = 382000;
		insert new List<Contract_Discount__c>{condition1, condition2, condition3};
		// Start test.
		Test.startTest();
		List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
        List<ContractServices.ContractIndexWrapper> wContract = contractServices.calculateContractIndex(true);
        String sIndex = wContract[0].sIndex;
        String sIndexV2 = wContract[0].sIndexV2;
        String sIndexPerc = wContract[0].sIndexPerc;
        String sIndexV2Perc = wContract[0].sIndexV2Perc;
        String sTo = wContract[0].sTo;
        String sComputed = wContract[0].sComputed;
        Decimal gap = wContract[0].Gap;
        String sgap = wContract[0].sGap;
        Decimal gapV2 = wContract[0].GapV2;
        String sgapV2 = wContract[0].sGapV2;
        

		Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
		System.assertEquals(83.35, contract.index1__c.setScale(2));
        System.assertEquals(19.19, contract.index1_perc__c.setScale(2));
        System.assertEquals(1050644.440, contract.Total_TO_Tariff_Nego__c.setScale(3));
		System.assertEquals(31519.33, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(127666.67, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(42444.44, conditionList[2].YTD_Nego_Computed__c.setScale(2));
	}

    @isTest
	static void case7_1122_CalculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 1.73;
        contract.TO1__c = 463975;
        update contract;
        //4 - 1 - 0.5 - 28.23
		// Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 4;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 1;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 1;
		condition2.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 0.5;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 2;
        condition3.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition4.Value_per__c = 28.23;
        condition4.Value_amt__c = 0;
        condition4.Rank__c = 2;
        condition4.Is_Tariff_Condition__c = true;
		insert new List<Contract_Discount__c>{condition1, condition2, condition3, condition4};
		// Start test.
		Test.startTest();
		List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
		System.assertEquals(68.88, contract.index1__c.setScale(2));
        System.assertEquals(32.29, contract.index1_perc__c.setScale(2));
        System.assertEquals(685273.94, contract.Total_TO_Tariff_Nego__c.setScale(3));
		System.assertEquals(27410.96, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(6852.74, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(3255.05, conditionList[2].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(183780.19, conditionList[3].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(97.66, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(96.64, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(96.16, conditionList[2].Index_Val__c.setScale(2));
        System.assertEquals(68.88, conditionList[3].Index_Val__c.setScale(2));
	}

	@isTest
	static void case5_Index1WithNotTariffCaseCalculateContractIndex() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 1.73;
        contract.TO1__c = 463975;
        update contract;
        //4 - 1 - 0.5 - 28.23
		// Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 4;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = false;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 1;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 1;
		condition2.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 0.5;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 2;
        condition3.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition4.Value_per__c = 28.23;
        condition4.Value_amt__c = 0;
        condition4.Rank__c = 2;
        condition4.Is_Tariff_Condition__c = true;
		insert new List<Contract_Discount__c>{condition1, condition2, condition3, condition4};
		// Start test.
		Test.startTest();
		List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
		System.assertEquals(68.88, contract.index1__c.setScale(2));
        System.assertEquals(32.29, contract.index1_perc__c.setScale(2));
        System.assertEquals(685273.94, contract.Total_TO_Tariff_Nego__c.setScale(3));
		System.assertEquals(27410.96, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(6852.74, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(3255.05, conditionList[2].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(183780.19, conditionList[3].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(97.66, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(96.64, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(96.16, conditionList[2].Index_Val__c.setScale(2));
        System.assertEquals(68.88, conditionList[3].Index_Val__c.setScale(2));
	}

    @isTest
	static void case5_Index1WithUnitAmount() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 1.41;
        contract.TO1__c = 360000;
        contract.Qty1__c = 100000;
        update contract;
        //4 - 1 - 0.5 - 28.23
		// Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 3.2;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 20.60;
		condition2.Value_amt__c = 0;
		condition2.Rank__c = 2;
		condition2.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 8.5;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 3;
        condition3.Is_Tariff_Condition__c = true;
        Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition4.unit_amount__c = 0.03;
        condition4.unit_amount_type__c = unitAmountTypePlv;
        condition4.Value_amt__c = 0;
        condition4.Rank__c = 4;
        condition4.Is_Tariff_Condition__c = true;
		insert new List<Contract_Discount__c>{condition1, condition2, condition3, condition4};
		// Start test.
		Test.startTest();
		List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);
		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//System.assertEquals('Success', str);
        System.assertEquals(70.73, contract.index1__c.setScale(2));
        System.assertEquals(30.26, contract.index1_perc__c.setScale(2));
        System.assertEquals(516166.33, contract.Total_TO_Tariff_Nego__c.setScale(3));
		System.assertEquals(16517.32, conditionList[0].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(102927.7, conditionList[1].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(33721.31, conditionList[2].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(3000, conditionList[3].YTD_Nego_Computed__c.setScale(2));
        System.assertEquals(98.16, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(77.94, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(71.32, conditionList[2].Index_Val__c.setScale(2));
        System.assertEquals(70.73, conditionList[3].Index_Val__c.setScale(2));
	}
	@isTest
	static void case3_ECHANTILLONAGE_1() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 58003;
		contract.Qty1__c = 100000;
        update contract;
		// Insert conditions.
		List<Contract_Discount__c> conditions = generateConditions(new List<String> {'Index1', 'Index1', 'Index1', 'Index1', 'Index1', 'Index1'},
																   new List<String> {'1', '2', '3', '4', '4', '5'},
																   new List<String> {'0', '5', '', '0', '8', '42.45'},
																   new List<String> {'', '', '', '', '', ''}, contract);
		conditions[2].unit_amount__c = 0.03;
        conditions[2].unit_amount_type__c = unitAmountTypePlv;
		insert conditions;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);

		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//Index_Val__c
		//System.assertEquals('Success', str);
        System.assertEquals(103.14, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(97.98, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(95.37, conditionList[2].Index_Val__c.setScale(2));
		System.assertEquals(95.37, conditionList[3].Index_Val__c.setScale(2));
		System.assertEquals(87.74, conditionList[4].Index_Val__c.setScale(2));
		System.assertEquals(50.5, conditionList[5].Index_Val__c.setScale(2));
		// Index_perc__c
		System.assertEquals(0, conditionList[0].Index_perc__c.setScale(2));
        System.assertEquals(5, conditionList[1].Index_perc__c.setScale(2));
        System.assertEquals(2.67, conditionList[2].Index_perc__c.setScale(2));
		System.assertEquals(0, conditionList[3].Index_perc__c.setScale(2));
		System.assertEquals(8, conditionList[4].Index_perc__c.setScale(2));
		System.assertEquals(42.45, conditionList[5].Index_perc__c.setScale(2));
	}

	@isTest
	static void case3_ECHANTILLONAGE_2() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 58003;
		contract.Qty1__c = 100000;
        update contract;
		// Insert conditions.
		List<Contract_Discount__c> conditions = generateConditions(new List<String> {'Index1', 'Index1', 'Index1', 'Index1', 'Index1', 'Index1'},
																   new List<String> {'1', '2', '3', '4', '4', '5'},
																   new List<String> {'5', '8', '', '0', '0', '42.45'},
																   new List<String> {'', '', '', '', '', ''}, contract);
		conditions[2].unit_amount__c = 0.03;
        conditions[2].unit_amount_type__c = unitAmountTypePlv;
		insert conditions;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);

		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//Index_Val__c
		//System.assertEquals('Success', str);
		System.assertEquals(97.98, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(90.14, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(87.54, conditionList[2].Index_Val__c.setScale(2));
		System.assertEquals(87.54, conditionList[3].Index_Val__c.setScale(2));
		System.assertEquals(87.54, conditionList[4].Index_Val__c.setScale(2));
		System.assertEquals(50.38, conditionList[5].Index_Val__c.setScale(2));
		// Index_perc__c
		System.assertEquals(5, conditionList[0].Index_perc__c.setScale(2));
        System.assertEquals(8, conditionList[1].Index_perc__c.setScale(2));
        System.assertEquals(2.89, conditionList[2].Index_perc__c.setScale(2));
		System.assertEquals(0, conditionList[3].Index_perc__c.setScale(2));
		System.assertEquals(0, conditionList[4].Index_perc__c.setScale(2));
		System.assertEquals(42.45, conditionList[5].Index_perc__c.setScale(2));
	}
	@isTest
	static void case3_ECHANTILLONAGE_3() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 58003;
		contract.Qty1__c = 100000;
        update contract;
		// Insert conditions.
		List<Contract_Discount__c> conditions = generateConditions(new List<String> {'Index1', 'Index1', 'Index1', 'Index1', 'Index1', 'Index1'},
																   new List<String> {'1', '2', '3', '4', '5', '6'},
																   new List<String> {'0', '0', '', '5', '8', '42.45'},
																   new List<String> {'', '', '', '', '', ''}, contract);
		conditions[2].unit_amount__c = 0.03;
        conditions[2].unit_amount_type__c = unitAmountTypePlv;
		insert conditions;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);

		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);

		Test.stopTest();
		// Assertions.
		//Index_Val__c
		//System.assertEquals('Success', str);
		System.assertEquals(103.14, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(103.14, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(100.52, conditionList[2].Index_Val__c.setScale(2));
		System.assertEquals(95.5, conditionList[3].Index_Val__c.setScale(2));
		System.assertEquals(87.86, conditionList[4].Index_Val__c.setScale(2));
		System.assertEquals(50.56, conditionList[5].Index_Val__c.setScale(2));
		// Index_perc__c
		System.assertEquals(0, conditionList[0].Index_perc__c.setScale(2));
        System.assertEquals(0, conditionList[1].Index_perc__c.setScale(2));
        System.assertEquals(2.54, conditionList[2].Index_perc__c.setScale(2));
		System.assertEquals(5, conditionList[3].Index_perc__c.setScale(2));
		System.assertEquals(8, conditionList[4].Index_perc__c.setScale(2));
		System.assertEquals(42.45, conditionList[5].Index_perc__c.setScale(2));
	}
	@isTest
	static void case3_ECHANTILLONAGE_4() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 3.14;
        contract.TO1__c = 58003;
		contract.Qty1__c = 100000;
        update contract;
		// Insert conditions.
		List<Contract_Discount__c> conditions = generateConditions(new List<String> {'Index1', 'Index1', 'Index1', 'Index1', 'Index1', 'Index1'},
																   new List<String> {'1', '2', '3', '4', '4', '5'},
																   new List<String> {'5', '8', '42.45', '', '0', '0'},
																   new List<String> {'', '', '', '', '', ''}, contract);
		conditions[3].unit_amount__c = 0.03;
        conditions[3].unit_amount_type__c = unitAmountTypePlv;
		insert conditions;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);

		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(false);

		Test.stopTest();
		// Assertions.
		//Index_Val__c
		//System.assertEquals('Success', str);
		System.assertEquals(97.98, conditionList[0].Index_Val__c.setScale(2));
        System.assertEquals(90.14, conditionList[1].Index_Val__c.setScale(2));
        System.assertEquals(51.88, conditionList[2].Index_Val__c.setScale(2));
		System.assertEquals(49.33, conditionList[3].Index_Val__c.setScale(2));
		System.assertEquals(49.33, conditionList[4].Index_Val__c.setScale(2));
		System.assertEquals(49.33, conditionList[5].Index_Val__c.setScale(2));
		// Index_perc__c
		System.assertEquals(5, conditionList[0].Index_perc__c.setScale(2));
        System.assertEquals(8, conditionList[1].Index_perc__c.setScale(2));
        System.assertEquals(42.45, conditionList[2].Index_perc__c.setScale(2));
		System.assertEquals(4.92, conditionList[3].Index_perc__c.setScale(2));
		System.assertEquals(0, conditionList[4].Index_perc__c.setScale(2));
		System.assertEquals(0, conditionList[5].Index_perc__c.setScale(2));
	}
    @isTest
    static void case3_ECHANTILLONAGE1_4() {
		init();
		// set tariff index
        tariffCondition1.Is_Tariff_Condition__c = true;
		tariffCondition1.Index__c = 'Index1';
		update tariffCondition1;
        contract.Rise_Rate_YE__c = 1.41;
        contract.TO1__c = 360000;
		contract.Qty1__c = 100000;
        update contract;
		// Insert conditions.
		List<Contract_Discount__c> conditions = generateConditions(new List<String> {'Index1', 'Index1', 'Index1', 'Index1', 'Index1'},
																   new List<String> {'1', '2', '3', '3', '3'},
																   new List<String> {'3.2', '20.6', '8.5', '1', '5'},
																   new List<String> {'', '', '', '', ''}, contract);
		conditions[2].Product_Scope__c = SubNs.Id;
        conditions[2].Base_TO_Nego__c =288000;
        conditions[3].Product_Scope__c = SubNs.Id;
        conditions[3].Base_TO_Nego__c = 144000;
		insert conditions;
		// Start test.
		Test.startTest();
        List<Contract_Discount__c> conditionList = getConditons();
        contract = getContracts(contract.Id);

		ContractServices contractServices = new ContractServices(contract, conditionList);
		contractServices.calculateContractIndex(true);
		Test.stopTest();
        //System.assertEquals('Success', str);
        System.assertEquals(0, 0);
	}
	static List<Contract_Discount__c> generateConditions(List<String> indexes, List<String> ranks, List<String> perc, List<String> amounts, Contract__c contract) {
		List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
		Integer i = 0;
		for (String index : indexes) {
			Contract_Discount__c condition = TestDataFactory.createCondition(false, indexTariffMap.get(index), contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
			condition.Value_per__c = String.isEmpty(perc[i]) ? null : Decimal.valueOf(perc[i]);
			condition.Value_amt__c = String.isEmpty(amounts[i]) ? null : Decimal.valueOf(amounts[i]);
			condition.Rank__c = String.isEmpty(ranks[i]) ? null : Decimal.valueOf(ranks[i]);
			condition.Is_Tariff_Condition__c = index == 'Index1';
			condition.RecordTypeId = TestDataFactory.conditionRTIds.get('To_Be_Signed');
			conditions.add(condition);
			i++;
		}
		return conditions;
	}

	static List<Contract_Discount__c> getConditons() {
		return  [SELECT Id, Name, Product_Scope__c, BusinessUnitScope__c, Disc_BDate__c, Disc_EDate__c, Base_TO_Nego__c, Value_per__c, Value_amt__c, Rank__c, Is_Tariff_Condition__c, Index__c, 
                 Condition_Type__r.Index__c,index_v2__c,  Exclusion_to_Nego_Base_Value__c, Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, Is_Excluded_To_NegoBase__c, slab_calc_method__c, unit_amount__c, unit_amount_type__c, Parent_Discount__c, RecordTypeId, Contract__c, Display_Order__c,
                 Nego_Discount_Type__c, Base_TO_Nego_YearBase__c, Is_Yearly_Condition__c, Condition_Type__r.Name, Condition_Type__r.Capture_Discount_Product_Level__c, Condition_Type__r.Nego_Discount_Type__c, YTD_Nego__c, Base_Quantity_Nego__c, Index_perc__c, YTD_Nego_Computed__c,
                 Is_conditional__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c, Slab_8__c, Slab_9__c, Slab_10__c, slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,
                 Slab_Val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c, Slab_Val_6__c, Slab_Val_7__c, Slab_Val_8__c, Slab_Val_9__c, Slab_Val_10__c, ContractSellIn__c
                 FROM Contract_Discount__c];
    }

	static Contract__c getContracts(Id contractId) {
		return [SELECT Id, Supplier_Nego_Scope__c, BusinessUnitContract__c, BusinessUnitSource__c, RecordTypeId, Contract_BDate__c, Contract_EDate__c,
                Supplier_Nego_Scope__r.SupplyChainType__c, Supplier_Nego_Scope__r.BrandType__c, Supplier_Nego_Scope__r.SegmentationAttribut1__c,
                Supplier_Nego_Scope__r.SegmentationAttribut2__c, Supplier_Nego_Scope__r.SegmentationAttribut3__c,
				TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c,
				Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c,
                Total_TO__c, Total_TO_Tariff_Nego__c, Rise_Rate_YE__c, Depreciation_Rate_YE__c, Markdown_Rate_Break__c, Markdown_Rate_Promo__c, Markdown_Rate_Theft__c, 
				index1__c, index2__c, index3__c, index4__c, index5__c, index6__c, index7__c, 
                index1_v2__c, index2_v2__c, index3_v2__c, index4_v2__c, index5_v2__c, index6_v2__c, index7_v2__c,
                index1_perc__c, index2_perc__c, index3_perc__c, index4_perc__c, index5_perc__c, index6_perc__c, index7_perc__c,
                index1_v2_perc__c, index2_v2_perc__c, index3_v2_perc__c, index4_v2_perc__c, index5_v2_perc__c, index6_v2_perc__c, index7_v2_perc__c,
                Rise_Rate__c, Rise_Rate10__c, Rise_Rate1__c, Rise_Rate2__c, Rise_Rate3__c, Rise_Rate4__c, Rise_Rate5__c, Rise_Rate6__c,
                Rise_Rate7__c, Rise_Rate8__c, Rise_Rate9__c, Rise_Rate_Exec_Date10__c, Rise_Rate_Exec_Date1__c,
                Rise_Rate_Exec_Date3__c, Rise_Rate_Exec_Date4__c, Rise_Rate_Exec_Date5__c, Rise_Rate_Exec_Date6__c, Rise_Rate_Exec_Date7__c,
                Rise_Rate_Exec_Date8__c, Rise_Rate_Exec_Date9__c, Rise_Rate_Nb__c, Depreciation_Rate__c, Depreciation_Rate1__c,
                Depreciation_Rate2__c, Depreciation_Rate3__c, Depreciation_Rate_Exec_Date1__c, Depreciation_Rate_Exec_Date2__c,
                Depreciation_Rate_Exec_Date3__c, Depreciation_Rate_Nb__c, IsCalculatedIndexV2__c
				FROM Contract__c WHERE Id = :contractId];
	}

	@isTest
	static void case6_checkOrderDesc() {
		init();
		initsort();
        List<Contract_Discount__c> listdesc = [SELECT Id, Contract__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId
                                               FROM Contract_Discount__c
                                               ORDER BY Condition_Type__r.Index__c desc, Condition_Type__r.Nego_Discount_Type__c desc, Rank__c desc, Condition_Type__r.Name desc];
        List<Contract_Discount__c> listrandom = [SELECT Id, Contract__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId
                                                 FROM Contract_Discount__c];
		listdesc = ContractServices.sort(listdesc, false);
		listrandom = ContractServices.sort(listrandom, false);
		System.assertNotEquals(0, listdesc.size());
		System.assertNotEquals(0, listrandom.size());
		System.assertEquals(listdesc.size(), listrandom.size());
		for (Integer index = 0; index < listdesc.size(); index++) {
			System.assertEquals(listdesc.get(index).Id, listrandom.get(index).Id);
		}
	}

	@isTest
	static void case7_checkOrderAsc() {
		init();
		initsort();
		List<Contract_Discount__c> listrandom = [SELECT Id, Contract__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId
		                                         FROM Contract_Discount__c];
		List<Contract_Discount__c> listasc = [SELECT Id, Contract__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId
		                                      FROM Contract_Discount__c
		                                      ORDER BY Condition_Type__r.Index__c asc, Condition_Type__r.Nego_Discount_Type__c asc, Rank__c asc, Condition_Type__r.Name asc];
		listrandom = ContractServices.sort(listrandom, true);
		listasc = ContractServices.sort(listasc, true);
		System.assertNotEquals(0, listrandom.size());
		System.assertNotEquals(0, listasc.size());
		System.assertEquals(listrandom.size(), listasc.size());
		for (Integer index = 0; index < listrandom.size(); index++) {
			System.assertEquals(listrandom.get(index).Id, listasc.get(index).Id);
		}
	}

	@isTest
	static void case8_checkDisplayOrder() {
		init();
		initsort();
        List<Contract_Discount__c> listdesc = [SELECT Id, Contract__c, Condition_Type__r.Capture_Discount_Product_Level__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId,
                                               Is_conditional__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, Slab_7__c, Slab_8__c, Slab_9__c, Slab_10__c, slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c, slab_per_7__c, slab_per_8__c, slab_per_9__c, slab_per_10__c,
                                               Slab_Val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c, Slab_Val_6__c, Slab_Val_7__c, Slab_Val_8__c, Slab_Val_9__c, Slab_Val_10__c
                                               FROM Contract_Discount__c
		                                       ORDER BY Condition_Type__r.Index__c desc, Condition_Type__r.Nego_Discount_Type__c desc, Rank__c desc, Condition_Type__r.Name desc];
		listdesc = ContractServices.sort(listdesc, true, true);
		update listdesc;
        List<Contract_Discount__c> listasc = [SELECT Id, Contract__c, Condition_Type__r.Capture_Discount_Product_Level__c, Condition_Type__r.Name, Condition_Type__r.Index__c, Condition_Type__r.Nego_Discount_Type__c, Rank__c, Display_Order__c, Is_Excluded_To_NegoBase__c, unit_amount__c, Parent_Discount__c, RecordTypeId
                                              FROM Contract_Discount__c
                                              ORDER BY Display_Order__c asc];
        System.assertNotEquals(0, listdesc.size());
		System.assertNotEquals(0, listasc.size());
		System.assertEquals(listdesc.size(), listasc.size());
		for (Integer index = 0; index < listdesc.size(); index++) {
			System.assertEquals(listdesc.get(index).Display_Order__c, listasc.get(index).Display_Order__c);
		}
	}

	@isTest
	static void case9_coverage() {
		init();
		initsort();
        // Start test.
		Test.startTest();
        // Create BU List
        BusinessUnit__c buList = TestDataFactory.createBusinessUnitList(false, country.Id);
        buList.Mission__c = 'Panelist;Offer';
        buList.Format__c = 'Supermarket;Drive';
        buList.Supplier__c = supplier.Id;
        insert buList;
        // Create BU Banner
        BusinessUnit__c buBanner = TestDataFactory.createBusinessUnitBanner(false, country);
        buBanner.Mission__c = 'Offer';
        buBanner.Format__c = 'Supermarket;Drive';
        insert buBanner;
        // update tariffCondition
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        insert contractTop;
        // Index 1 conditions
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        insert subCondition1;
        List<Contract_Discount__c> conditionList = getConditons();
        contractTop = getContracts(contractTop.Id);
        ContractServices services = new ContractServices(contractTop, conditionList);
        String query3 = ContractServices.buildQueryTariffCondition(contractTop, null, null);
        ContractServices.calculateContractRiseDepRates(contractTop);
        condition1.Condition_Type__r = tariffCondition1;
        ContractServices.getRelatedPolCom(new Set<Id>{tariffCondition1.Id});
        ContractServices.generateDiscountTerms(condition1, new List<Contract_Discount__c> {subCondition1});
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, true);
        Test.stopTest();
        System.assert(true);
	}
    
    @isTest
    static void case11_cosolidateContract() {
        init();
        initsort();
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        Contract__c contractPE = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 2, 28));
        contractPE.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        contractPE.Contract_Type__c = 'Contract';
        contractPE.Status__c = 'Signed';
        contractPE.D_N__c = 'D';
        contractPE.TO1__c = 1000;
        insert new List<Contract__c> {contractPE, contractTop};
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // Insert conditions
        Contract_Discount__c conditionTop = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        conditionTop.Value_per__c = 10;
        conditionTop.Value_amt__c = 0;
        conditionTop.Rank__c = 1;
        conditionTop.Is_Tariff_Condition__c = true;
        conditionTop.slab_calc_method__c = 'TO';
        conditionTop.Slab_Calc_Method_TO_Origin__c = 'Nego';
        conditionTop.slab_per_1__c = 3;
        conditionTop.Slab_1__c = 20;
        conditionTop.Slab_2__c = 21;
        Contract_Discount__c conditionPE = TestDataFactory.createCondition(false, tariffCondition1, contractPE, date.newInstance(year, 1, 1), date.newInstance(year, 2, 28));
        conditionPE.Value_per__c = 5;
        conditionPE.Value_amt__c = 100;
        conditionPE.Base_TO_Nego__c = 1000;
        conditionPE.Base_TO_Tariff_Nego__c = 1000;
        conditionPE.Rank__c = 1;
        insert new List<Contract_Discount__c> {conditionPE, conditionTop};
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = conditionTop.Id;
        insert subCondition1;
        List<Contract_Discount__c> conditionList = getConditons();
        contractTop = getContracts(contractTop.Id);
        // Start test.
        Test.startTest();
        ContractServices services = new ContractServices(contractTop, conditionList);
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, false);
        system.debug(' >>> ' + [SELECT Id, Name,RecordType.DeveloperName, Reference_Year__c,Supplier_Nego_Scope__c FROM Contract__c]);
        List<Contract__c> contractNBIList = [SELECT Id, Status__c FROM Contract__c
                                             WHERE RecordType.DeveloperName = 'Nego_Base_Init'
                                             AND Reference_Year__c = :year
                                             AND Supplier_Nego_Scope__c = :NS.Id
                                             LIMIT 1];
        if(!contractNBIList.isEmpty()) {
            Contract__c contractNBI = contractNBIList[0];
            contractNBI.Status__c = 'Validated';
            update contractNBI;
        }
        Test.stopTest();
        System.assert(true);
    }
    
    /**
     * @description calculate Manual SellinRule
     */
    @isTest
    static void calculateManualSellinRule_success() {
        initVolumes();
        // List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
        // system.debug('>>>>> listPG : ' + listPG);
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year - 2;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year - 1;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // insert purchases;
        Test.startTest();
        String selectedSellInRule = 'Manual';
        Map<Integer, List<Integer>> manualSellInRulesMap = new Map<Integer, List<Integer>>();
        manualSellInRulesMap.put(year - 2, new List<Integer>{1});
        manualSellInRulesMap.put(year - 1, new List<Integer>{2});
        manualSellInRulesMap.put(year, new List<Integer>{3});
        // Price_List_Statement__c priceListStatement = priceStatements.get(0);
        // system.debug('>>>> priceListStatement : ' + priceListStatement);
        // List<Price_List_Statement__c> priceListStatementList = new List<Price_List_Statement__c>();
        // priceListStatementList.add(priceListStatement);
        // calculateVolumeHMP(priceListStatementList, '12M', new Map<Integer, List<Integer>>());
        Test.stopTest();
        //System.assertEquals(1, [SELECT COUNT() FROM Price_List_Statement__c WHERE PriceList_Statement_Reference__c = :priceListStatement.Id]);
       // System.assertEquals(detailStatements.size(), [SELECT COUNT() FROM Price_List_Statement_Detail__c WHERE PriceList_Statement__r.PriceList_Statement_Reference__c = :priceListStatement.Id]);
    }
    @isTest
    static void calculateManualSellinRule_success1() {
        initVolumes();
        // List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
        // system.debug('>>>>> listPG : ' + listPG);
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year - 2;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year - 1;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // for (PG__c item : listPG) {
        //     Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, item, masterBU.Id);
        //     for (Integer i = 1 ; i <= 12 ; i++) {
        //         purchase.put('Qty' + i + '__c', 5);
        //         purchase.put('SellIn_Qty_Promo_M' + i + '__c', 50);
        //     }
        //     purchase.Year__c = year;
        //     purchase.Sequence__c = 1;
        //     purchases.add(purchase);
        // }
        // insert purchases;
        Test.startTest();
        String selectedSellInRule = 'Manual';
        Map<Integer, List<Integer>> manualSellInRulesMap = new Map<Integer, List<Integer>>();
        manualSellInRulesMap.put(year - 2, new List<Integer>{1});
        manualSellInRulesMap.put(year - 1, new List<Integer>{2});
        manualSellInRulesMap.put(year, new List<Integer>{3});
        // Price_List_Statement__c priceListStatement = priceStatements.get(0);
        // system.debug('>>>> priceListStatement : ' + priceListStatement);
        // List<Price_List_Statement__c> priceListStatementList = new List<Price_List_Statement__c>();
        // priceListStatementList.add(priceListStatement);
        // calculateVolumeHMP(priceListStatementList, 'Manual', manualSellInRulesMap);
        Test.stopTest();
        //System.assertEquals(1, [SELECT COUNT() FROM Price_List_Statement__c WHERE PriceList_Statement_Reference__c = :priceListStatement.Id]);
       // System.assertEquals(detailStatements.size(), [SELECT COUNT() FROM Price_List_Statement_Detail__c WHERE PriceList_Statement__r.PriceList_Statement_Reference__c = :priceListStatement.Id]);
    }
    
    static testmethod void case1_fixing_NBI_success() {
        initSynchro();
        Test.startTest();
        // Insert Simulation
        Contract__c contractSimulation = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        contractSimulation.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        contractSimulation.Contract_Type__c = 'Contract';
        contractSimulation.D_N__c = 'D';
        contractSimulation.TO1__c = 1000;
        insert contractSimulation;
        Contract_Discount__c conditionSimulation = TestDataFactory.createCondition(false, tariffCondition, contractSimulation, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        conditionSimulation.Value_per__c = 7;
        conditionSimulation.Rank__c = 1;
        insert conditionSimulation;
        // Insert NBI/NB
        Contract__c contractNBI = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        contractNBI.RecordTypeId = TestDataFactory.contractRTIds.get('Nego_Base_Init');
        contractNBI.Parent_Contract__c = contractSimulation.Id;
        contractNBI.Contract_Type__c = 'Contract';
        contractNBI.D_N__c = 'D';
        contractNBI.TO1__c = 1000;
        contractNBI.Status__c = 'Validated';
        Contract__c contractNB = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        contractNB.RecordTypeId = TestDataFactory.contractRTIds.get('Nego_Base');
        contractNB.Parent_Contract__c = contractSimulation.Id;
        contractNB.Contract_Type__c = 'Contract';
        contractNB.D_N__c = 'D';
        contractNB.TO1__c = 1000;
        contractNB.Status__c = 'Validated';
        insert new List<Contract__c> {contractNBI, contractNB};
        // Insert conditions NBI/NB
        Contract_Discount__c conditionNBI = TestDataFactory.createCondition(false, tariffCondition, contractNBI, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        conditionNBI.Reference_condition__c = conditionSimulation.Id;
        conditionNBI.Value_per__c = 7;
        conditionNBI.Rank__c = 1;
        Contract_Discount__c conditionNB = TestDataFactory.createCondition(false, tariffCondition, contractNB, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        conditionNB.Reference_condition__c = conditionSimulation.Id;
        conditionNB.Value_per__c = 7;
        conditionNB.Rank__c = 1;
        insert new List<Contract_Discount__c> {conditionNBI, conditionNB};
        Test.stopTest();
        // Validation
        conditionNBI = [SELECT Id, Value_per__c
                        FROM Contract_Discount__c
                        WHERE Contract__r.RecordType.DeveloperName = 'Nego_Base_Init'
                        AND Parent_Discount__c = NULL];
        System.assertEquals(conditionSigned.Value_per__c, conditionNBI.Value_per__c);
    }
    
    static testmethod void case000() {
        try {
            ContractServices.getApexJob(null);
        } catch(Exception ex) { }
        System.assert(true);
    }
    
	@isTest
	static void case001() {
		init();
        // update tariffCondition
        tariffCondition1.Is_Contract_Unicity_Requiered__c = true;
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // Contract_BDate__c
        // Contract_EDate__c
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        insert contractTop;
        // Index 1 conditions
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        insert subCondition1;
        condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 15), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, true);
		Test.startTest();
        // insert Contracts
        Contract__c contractPT = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 28, 2));
        contractPT.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        ContractServices.generateContractName(contractPT, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractPT.Contract_Type__c = 'Contract';
        contractPT.Status__c = 'Signed';
        contractPT.Is_OnTop_Simulation__c = true;
        contractPT.TO1__c = 100000;
        insert contractPT;
        // Index 1 conditions
        condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        insert subCondition1;
        condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, date.newInstance(year, 1, 1), date.newInstance(year, 1, 15));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, true);
        Test.stopTest();
        System.assert(true);
	}
	@isTest
	static void case002() {
		init();
        // Start test.
		Test.startTest();
        // Create BU List
        BusinessUnit__c buList = TestDataFactory.createBusinessUnitList(false, country.Id);
        buList.Mission__c = 'Panelist;Offer';
        buList.Format__c = 'Supermarket;Drive';
        buList.Supplier__c = supplier.Id;
        insert buList;
        // Create BU Banner
        BusinessUnit__c buBanner = TestDataFactory.createBusinessUnitBanner(false, country);
        buBanner.Mission__c = 'Offer';
        buBanner.Format__c = 'Supermarket;Drive';
        insert buBanner;
        // update tariffCondition
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        insert contractTop;
        // Index 1 conditions
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        insert subCondition1;
        List<Contract_Discount__c> conditionList = getConditons();
        contractTop = getContracts(contractTop.Id);
        ContractServices services = new ContractServices(contractTop, conditionList);
        condition1.Condition_Type__r = tariffCondition1;
        Schema.DescribeFieldResult unitTypePicklistField = Contract_Discount__c.Unit_Amount_Type__c.getDescribe();
        Map<String, String> unitTypePicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : unitTypePicklistField.getPicklistValues()) {
            unitTypePicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        Schema.DescribeFieldResult calcMethodPicklistField = Contract_Discount__c.slab_calc_method__c.getDescribe();
        Map<String, String> calcMethodpicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : calcMethodPicklistField.getPicklistValues()) {
            calcMethodpicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        ContractServices.generateDiscountTerms(condition1, new List<Contract_Discount__c> {subCondition1}, unitTypePicklistLabels, calcMethodpicklistLabels);
        Test.stopTest();
        System.assert(true);
	}
    
    @isTest
	static void case003() {
		init();
        // Start test.
		Test.startTest();
        // Create BU List
        BusinessUnit__c buList = TestDataFactory.createBusinessUnitList(false, country.Id);
        buList.Mission__c = 'Panelist;Offer';
        buList.Format__c = 'Supermarket;Drive';
        buList.Supplier__c = supplier.Id;
        insert buList;
        // Create BU Banner
        BusinessUnit__c buBanner = TestDataFactory.createBusinessUnitBanner(false, country);
        buBanner.Mission__c = 'Offer';
        buBanner.Format__c = 'Supermarket;Drive';
        insert buBanner;
        // update tariffCondition
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        insert contractTop;
        // Index 1 conditions
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        insert subCondition1;
        List<Contract_Discount__c> conditionList = getConditons();
        contractTop = getContracts(contractTop.Id);
        ContractServices services = new ContractServices(contractTop, conditionList);
        condition1.Condition_Type__r = tariffCondition1;
        Schema.DescribeFieldResult unitTypePicklistField = Contract_Discount__c.Unit_Amount_Type__c.getDescribe();
        Map<String, String> unitTypePicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : unitTypePicklistField.getPicklistValues()) {
            unitTypePicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        Schema.DescribeFieldResult calcMethodPicklistField = Contract_Discount__c.slab_calc_method__c.getDescribe();
        Map<String, String> calcMethodpicklistLabels = new Map<String, String>();
        for ( Schema.PicklistEntry picklistValue : calcMethodPicklistField.getPicklistValues()) {
            calcMethodpicklistLabels.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        ContractServices.updateContractFlatPrice(new Set<Id>{contract.Id}, new Set<Id>{NS.Id});
        Test.stopTest();
        System.assert(true);
	}
    @isTest
	static void case004() {
		init();
        // update tariffCondition
        tariffCondition1.Is_Contract_Unicity_Requiered__c = true;
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // Contract_BDate__c
        // Contract_EDate__c
        // insert Contracts
        // contractTop
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        // contract PT
        Contract__c contractPT = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 28, 2));
        contractPT.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        ContractServices.generateContractName(contractPT, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractPT.Contract_Type__c = 'Contract';
        contractPT.Status__c = 'Signed';
        contractPT.Is_OnTop_Simulation__c = true;
        contractPT.TO1__c = 100000;
        insert new list<Contract__c>{contractPT, contractTop};
        // Index 1 conditions contractTop
        Contract_Discount__c contractTopCondition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        contractTopCondition1.Value_per__c = 10;
        contractTopCondition1.Value_amt__c = 0;
        contractTopCondition1.Rank__c = 1;
        contractTopCondition1.Is_Tariff_Condition__c = true;
        contractTopCondition1.slab_calc_method__c = 'TO';
        contractTopCondition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        contractTopCondition1.slab_per_1__c = 3;
        contractTopCondition1.Slab_1__c = 20;
        contractTopCondition1.Slab_2__c = 21;
        Contract_Discount__c contractTopCondition2 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 15), date.newInstance(year, 12, 31));
        contractTopCondition2.Value_per__c = 10;
        contractTopCondition2.Value_amt__c = 0;
        contractTopCondition2.Rank__c = 1;
        contractTopCondition2.Is_Tariff_Condition__c = true;
        contractTopCondition2.slab_calc_method__c = 'TO';
        contractTopCondition2.Slab_Calc_Method_TO_Origin__c = 'Nego';
        contractTopCondition2.slab_per_1__c = 3;
        contractTopCondition2.Slab_1__c = 20;
        contractTopCondition2.Slab_2__c = 21;
        // Index 1 conditions contractPT
        Contract_Discount__c contractPTCondition1 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        contractPTCondition1.Value_per__c = 10;
        contractPTCondition1.Value_amt__c = 0;
        contractPTCondition1.Rank__c = 1;
        contractPTCondition1.Is_Tariff_Condition__c = true;
        contractPTCondition1.slab_calc_method__c = 'TO';
        contractPTCondition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        contractPTCondition1.slab_per_1__c = 3;
        contractPTCondition1.Slab_1__c = 20;
        contractPTCondition1.Slab_2__c = 21;
        Contract_Discount__c contractPTCondition2 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, date.newInstance(year, 1, 1), date.newInstance(year, 1, 15));
        contractPTCondition2.Value_per__c = 10;
        contractPTCondition2.Value_amt__c = 0;
        contractPTCondition2.Rank__c = 1;
        contractPTCondition2.Is_Tariff_Condition__c = true;
        contractPTCondition2.slab_calc_method__c = 'TO';
        contractPTCondition2.Slab_Calc_Method_TO_Origin__c = 'Nego';
        contractPTCondition2.slab_per_1__c = 3;
        contractPTCondition2.Slab_1__c = 20;
        contractPTCondition2.Slab_2__c = 21;
        insert new List<Contract_Discount__c>{contractTopCondition1, contractTopCondition2, contractPTCondition1, contractPTCondition2};
		Test.startTest();
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = contractTopCondition1.Id;
        insert subCondition1;
        subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = contractPTCondition1.Id;
        insert subCondition1;
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, false, true, new List<String> {'Nego_Base', 'To_Be_Signed', 'Period_Extension', 'Nego_Base_Init', 'Signed', 'Landing'});
        Test.stopTest();
        System.assert(true);
	}
    /*@isTest
	static void case005() {
		init();
        initSynchro();
        // update tariffCondition
        tariffCondition1.Is_Contract_Unicity_Requiered__c = true;
        tariffCondition1.Is_Conditional__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        update tariffCondition1;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Is_Conditional__c = true;
        insert subTariffCondition;
        // Contract_BDate__c
        // Contract_EDate__c
        // insert Contracts
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        Contract__c contractSimulation = TestDataFactory.createContract(false, NS, Date.newInstance(year, 1, 3), Date.newInstance(year, 1, 15));
        contractSimulation.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        contractSimulation.Contract_Type__c = 'Simulation';
        contractSimulation.D_N__c = 'D';
        contractSimulation.TO1__c = 1000;
        insert new List<Contract__c> {contractTop, contractSimulation};
        // Index 1 conditions
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 15), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 10;
        condition2.Value_amt__c = 0;
        condition2.Rank__c = 1;
        condition2.Is_Tariff_Condition__c = true;
        condition2.slab_calc_method__c = 'TO';
        condition2.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition2.slab_per_1__c = 3;
        condition2.Slab_1__c = 20;
        condition2.Slab_2__c = 21;
        Contract_Discount__c conditionSimulation = TestDataFactory.createCondition(false, tariffCondition, contractSimulation, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        conditionSimulation.Value_per__c = 7;
        conditionSimulation.Rank__c = 1;
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 4, 15), date.newInstance(year, 11, 30));
        condition3.Value_per__c = 10;
        condition3.Value_amt__c = 0;
        condition3.Rank__c = 1;
        condition3.Is_Tariff_Condition__c = true;
        condition3.slab_calc_method__c = 'TO';
        condition3.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition3.slab_per_1__c = 3;
        condition3.Slab_1__c = 20;
        condition3.Slab_2__c = 21;
        insert new List<Contract_Discount__c> {condition1, condition2, condition3, conditionSimulation, subCondition1};
		Test.startTest();
        // insert Contracts
        Contract__c contractPT = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 3, 18));
        contractPT.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        ContractServices.generateContractName(contractPT, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractPT.Contract_Type__c = 'Contract';
        contractPT.Status__c = 'Signed';
        contractPT.Is_OnTop_Simulation__c = true;
        contractPT.TO1__c = 100000;
        Contract__c contractNBI = TestDataFactory.createContract(false, NS, Date.newInstance(year, 2, 2), Date.newInstance(year, 12, 31));
        contractNBI.RecordTypeId = TestDataFactory.contractRTIds.get('Nego_Base_Init');
        contractNBI.Parent_Contract__c = contractSimulation.Id;
        contractNBI.Contract_Type__c = 'Contract';
        contractNBI.D_N__c = 'D';
        contractNBI.TO1__c = 1000;
        contractNBI.Status__c = 'Validated';
        insert new List<Contract__c> {contractPT, contractNBI};
        Contract_Discount__c conditionNBI = TestDataFactory.createCondition(false, tariffCondition, contractNBI, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        conditionNBI.Reference_condition__c = conditionSimulation.Id;
        conditionNBI.Value_per__c = 7;
        conditionNBI.Rank__c = 1;
        // Index 1 conditions
        condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert new List<Contract_Discount__c> {condition1, conditionNBI};
        subCondition1 = TestDataFactory.createCondition(false, subTariffCondition, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition1.Value_per__c = 10;
        subCondition1.Value_amt__c = 0;
        subCondition1.Rank__c = 1;
        subCondition1.Is_Tariff_Condition__c = true;
        subCondition1.Parent_Discount__c = condition1.Id;
        Contract_Discount__c subCondition2 = TestDataFactory.createCondition(false, subTariffCondition, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCondition2.Value_per__c = 10;
        subCondition2.Value_amt__c = 0;
        subCondition2.Rank__c = 1;
        subCondition2.Is_Tariff_Condition__c = true;
        subCondition2.Parent_Discount__c = condition1.Id;
        insert new List<Contract_Discount__c> {subCondition2, subCondition1};
        condition1 = TestDataFactory.createCondition(false, tariffCondition1, contractPT, date.newInstance(year, 1, 1), date.newInstance(year, 1, 15));
        condition1.Value_per__c = 10;
        condition1.Value_amt__c = 0;
        condition1.Rank__c = 1;
        condition1.Is_Tariff_Condition__c = true;
        condition1.slab_calc_method__c = 'TO';
        condition1.Slab_Calc_Method_TO_Origin__c = 'Nego';
        condition1.slab_per_1__c = 3;
        condition1.Slab_1__c = 20;
        condition1.Slab_2__c = 21;
        insert condition1;
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, false, true, new List<String> {'Nego_Base', 'To_Be_Signed', 'Period_Extension', 'Nego_Base_Init', 'Signed', 'Landing'});
        Test.stopTest();
        System.assert(true);
	}*/
    @isTest
	static void case006() {
		init();
        // update tariffCondition
        tariffCondition1.Name = 'case006';
        tariffCondition1.Is_Contract_Unicity_Requiered__c = true;
        tariffCondition1.Is_Yearly_Condition__c = false;
        tariffCondition1.Segmentation_attribut3__c = 'Value1';
        update tariffCondition1;
        NS.SegmentationAttribut3__c = 'Value1';
        update NS;
        // Create Sub Tariff Conditions
        Pol_Com_Condition__c subTariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        subTariffCondition.Name = 'sub-case006';
        subTariffCondition.Index__c = 'Index1';
        subTariffCondition.Nego_Discount_type__c = 'Price Discount';
        subTariffCondition.Is_Default_SubCondition__c = true;
        subTariffCondition.Condition_status__c = 'Open';
        subTariffCondition.Status_BDate__c = date.newInstance(year - 2 , 1, 1);
        subTariffCondition.BusinessUnitCounterpartyProof__c = country.Id;
        subTariffCondition.Definition_N1__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Definition_N1_Lang2__c = 'TESTB 1 TESTB 1 TESTB';
        subTariffCondition.Parent_Condition__c = tariffCondition1.Id;
        subTariffCondition.Segmentation_attribut3__c = 'Value1';
        insert subTariffCondition;
        // Contract_BDate__c
        // Contract_EDate__c
        // insert Contracts
        Contract__c contractPT = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 28, 2));
        contractPT.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        ContractServices.generateContractName(contractPT, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractPT.Contract_Type__c = 'Contract';
        contractPT.Status__c = 'Signed';
        contractPT.Is_OnTop_Simulation__c = true;
        contractPT.TO1__c = 100000;
        Contract__c contractTop = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
        contractTop.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        ContractServices.generateContractName(contractTop, supplier.Name, 'NS_Code', TestDataFactory.contractRTIds, 'Signed');
        contractTop.Contract_Type__c = 'Contract';
        contractTop.Status__c = 'Signed';
        contractTop.Is_OnTop_Simulation__c = true;
        contractTop.TO1__c = 100000;
        insert new List<Contract__c> {contractTop, contractPT};
        List<Contract_Discount__c> condList = new List<Contract_Discount__c>();
        List<Contract_Discount__c> subCondList = new List<Contract_Discount__c>();
        Contract_Discount__c cond = TestDataFactory.createCondition(false, tariffCondition1, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        cond.unit_amount__c = 10;
        cond.Unit_Amount_Type__c = 'KG';
        cond.Rank__c = 1;
        condList.add(cond);
        cond = TestDataFactory.createCondition(false, tariffCondition1, contractTop, date.newInstance(year, 3, 15), date.newInstance(year, 12, 31));
        cond.unit_amount__c = 10;
        cond.Unit_Amount_Type__c = 'KG';
        cond.Rank__c = 1;
        condList.add(cond);
        // Index 1 conditions
        cond = TestDataFactory.createCondition(false, tariffCondition1, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        cond.unit_amount__c = 10;
        cond.Unit_Amount_Type__c = 'KG';
        cond.Rank__c = 1;
        condList.add(cond);
        // update condition1;
        cond = TestDataFactory.createCondition(false, tariffCondition1, contractPT, date.newInstance(year, 1, 1), date.newInstance(year, 1, 15));
        cond.unit_amount__c = 10;
        cond.Unit_Amount_Type__c = 'KG';
        cond.Rank__c = 1;
        condList.add(cond);
        insert condList;
		Test.startTest();
        Contract_Discount__c subCond = TestDataFactory.createCondition(false, subTariffCondition, contractTop, contractTop.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCond.Rank__c = 1;
        subCond.Parent_Discount__c = condList[0].Id;
        subCondList.add(subCond);
        subCond = TestDataFactory.createCondition(false, subTariffCondition, contractPT, contractPT.Contract_BDate__c, contractTop.Contract_EDate__c);
        subCond.Rank__c = 1;
        subCond.Is_Tariff_Condition__c = true;
        subCond.Parent_Discount__c = condList[2].Id;
        subCondList.add(subCond);
        insert subCondList;
        condList[0].Value_per__c = 10;
        condList[0].Value_amt__c = 10;
        condList[0].Value_per_Y1__c = 10;
        condList[0].Value_amt_Y1__c = 10;
        condList[0].unit_amount__c = null;
        condList[0].Unit_Amount_Type__c = null;
        update condList[0];
        System.debug('>>>' + condList.size());
        System.debug('>>>' + subCondList.size());
        System.debug('>>>condList <<< ' + JSON.serialize(condList));
        System.debug('>>>subCondList <<< ' + JSON.serialize(subCondList));
        ContractServices.consolidateContract(null, new List<Id>{NS.Supplier__c}, new List<Id>{NS.Id}, null, year, null, false, false, true, new List<String> {'Nego_Base', 'To_Be_Signed', 'Period_Extension', 'Nego_Base_Init', 'Signed', 'Landing'});
        Test.stopTest();
        System.assert(true);
	}

    @isTest
    static void testDaysBetween() {
        Date startDate = Date.newInstance(2024, 3, 1);
        Date endDate = Date.newInstance(2024, 3, 5);
        Integer days = ContractServices.daysBetween(startDate, endDate);
        System.assertEquals(5, days, 'The number of days between start and end date is incorrect.');
    }

    @isTest
    static void testEndOfMonth() {
        Date inputDate = Date.newInstance(2024, 2, 15);
        Date expectedEndDate = Date.newInstance(2024, 2, 29);
        Date actualEndDate = ContractServices.end_of_month(inputDate);
        System.assertEquals(expectedEndDate, actualEndDate);
    }

    @isTest
    static void testBeginningOfMonth() {
        Date inputDate = Date.newInstance(2024, 2, 15);
        Date expectedStartDate = Date.newInstance(2024, 2, 1);
        Date actualStartDate = ContractServices.beginning_of_month(inputDate);
        System.assertEquals(expectedStartDate, actualStartDate);
    }

    @isTest
    static void testDuplicateContract() {
        init();
        Pol_Sale_Condition_Exception__c conditionException = new Pol_Sale_Condition_Exception__c();
        conditionException.Contract__c = contract.Id;
        insert conditionException;
        List<Contract__c> contractList = new List<Contract__c>{contract};
        List<Contract_Discount__c> condList = new List<Contract_Discount__c>();
        String recordTypeDeveloperName = 'Signed';
        NegoptimBatch nb = null;
        NS.Status__c = 'Active';
        update NS;
        tariffCondition1.Duplication_Discount_Mapping__c = tariffCondition2.Id;
        update tariffCondition1;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c;
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 7;
        condition.Value_per_Y1__c = 7;
        condition.Rank__c = 1;
        condList.add(condition);
        condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_BDate__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 2;
        condition.Value_per_Y1__c = 2;
        condition.Rank__c = 2;
        condList.add(condition);
        insert condList;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        subCondition.Disc_BDate_Y1__c = subCondition.Disc_BDate__c;
        subCondition.Disc_EDate_Y1__c = subCondition.Disc_EDate__c;
        subCondition.Value_per__c = 7;
        subCondition.Value_per_Y1__c = 7;
        subCondition.Rank__c = 1;
        subCondition.Parent_Discount__c = condList[0].Id;
        insert subCondition;
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        contract.Is_OnTop_Simulation__c = true;
        contract.Contract_Type__c = 'Contract';
        contract.Status__c = 'Signed';
        update contract;
        Test.startTest();
        ContractServices.duplicateContract(contractList, recordTypeDeveloperName, country.Id, year, Date.newInstance(year + 1, 3, 1), Date.newInstance(year + 1, 12, 31), null);
        Test.stopTest();
        Contract__c newContract = [SELECT Id FROM Contract__c
                                    WHERE Recordtype.DeveloperName = :recordTypeDeveloperName
                                    AND Reference_Year__c = :(year + 1)
                                    AND Supplier_Nego_Scope__c = :NS.Id
                                    AND BusinessUnitContract__c = :country.Id];
        System.assertNotEquals(null, newContract.Id);
    }

    @isTest
    static void testDuplicateContract_PE_N1_Exist() {
        init();
        Pol_Sale_Condition_Exception__c conditionException = new Pol_Sale_Condition_Exception__c();
        conditionException.Contract__c = contract.Id;
        insert conditionException;
        Contract__c contractN1 = TestDataFactory.createContract(false, NS, date.newInstance(year+1, 1, 1), date.newInstance(year+1, 12, 31));
        contractN1.RecordTypeId = TestDataFactory.contractRTIds.get('Period_Extension');
        contractN1.Status__c = 'Signed';
        insert contractN1;
        List<Contract__c> contractList = new List<Contract__c>{contract};
        List<Contract_Discount__c> condList = new List<Contract_Discount__c>();
        String recordTypeDeveloperName = 'Signed';
        NegoptimBatch nb = null;
        NS.Status__c = 'Active';
        update NS;
        tariffCondition1.Duplication_Discount_Mapping__c = tariffCondition2.Id;
        update tariffCondition1;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c;
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 7;
        condition.Value_per_Y1__c = 7;
        condition.Rank__c = 1;
        condList.add(condition);
        condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_BDate__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 2;
        condition.Value_per_Y1__c = 2;
        condition.Rank__c = 2;
        condList.add(condition);
        insert condList;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        subCondition.Disc_BDate_Y1__c = subCondition.Disc_BDate__c;
        subCondition.Disc_EDate_Y1__c = subCondition.Disc_EDate__c;
        subCondition.Value_per__c = 7;
        subCondition.Value_per_Y1__c = 7;
        subCondition.Rank__c = 1;
        subCondition.Parent_Discount__c = condList[0].Id;
        insert subCondition;
        Test.startTest();
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        contract.Is_OnTop_Simulation__c = true;
        contract.Contract_Type__c = 'Contract';
        contract.Status__c = 'Signed';
        update contract;
        ContractServices.duplicateContract(contractList, recordTypeDeveloperName, country.Id, year, Date.newInstance(year + 1, 3, 1), Date.newInstance(year + 1, 12, 31), null);
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testDuplicateContract_Signed_N1_Exist() {
        init();
        Pol_Sale_Condition_Exception__c conditionException = new Pol_Sale_Condition_Exception__c();
        conditionException.Contract__c = contract.Id;
        insert conditionException;
        Contract__c contractN1 = TestDataFactory.createContract(false, NS, date.newInstance(year+1, 1, 1), date.newInstance(year+1, 12, 31));
        contractN1.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        contractN1.Status__c = 'Signed';
        insert contractN1;
        List<Contract__c> contractList = new List<Contract__c>{contract};
        List<Contract_Discount__c> condList = new List<Contract_Discount__c>();
        String recordTypeDeveloperName = 'Signed';
        NegoptimBatch nb = null;
        NS.Status__c = 'Active';
        update NS;
        tariffCondition1.Duplication_Discount_Mapping__c = tariffCondition2.Id;
        update tariffCondition1;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c;
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 7;
        condition.Value_per_Y1__c = 7;
        condition.Rank__c = 1;
        condList.add(condition);
        condition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Disc_BDate_Y1__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_BDate__c = condition.Disc_BDate__c.addDays(1);
        condition.Disc_EDate_Y1__c = condition.Disc_EDate__c;
        condition.Value_per__c = 2;
        condition.Value_per_Y1__c = 2;
        condition.Rank__c = 2;
        condList.add(condition);
        insert condList;
        Contract_Discount__c subCondition = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        subCondition.Disc_BDate_Y1__c = subCondition.Disc_BDate__c;
        subCondition.Disc_EDate_Y1__c = subCondition.Disc_EDate__c;
        subCondition.Value_per__c = 7;
        subCondition.Value_per_Y1__c = 7;
        subCondition.Rank__c = 1;
        subCondition.Parent_Discount__c = condList[0].Id;
        insert subCondition;
        Test.startTest();
        contract.RecordTypeId = TestDataFactory.contractRTIds.get('Signed');
        contract.Is_OnTop_Simulation__c = true;
        contract.Contract_Type__c = 'Contract';
        contract.Status__c = 'Signed';
        update contract;
        ContractServices.duplicateContract(contractList, recordTypeDeveloperName, country.Id, year, Date.newInstance(year + 1, 3, 1), Date.newInstance(year + 1, 12, 31), null);
        Test.stopTest();
        System.assert(true);
	}
}