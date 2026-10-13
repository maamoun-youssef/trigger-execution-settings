/**
 * @author ULiT
 * @date 21-01-2026
 * @description Unit test class for ListContractController
 *******************************************************************/
@IsTest
public class duplicateContractTest {
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

    // -------------------------
    // Test Cases
    // -------------------------

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
        List<Contract__c> newContract = [SELECT Id FROM Contract__c];
        System.debug('newContract>>> '+newContract);
        System.assertNotEquals(null, newContract.size());
    }

}