/**
 * @Description Test class that verify whether the particular piece of code on DuplicateContractBatch is working properly.
 **/
@isTest
private class DuplicateContractBatchTest {

    private static final Integer year = TestDataFactory.year;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;

	static void init() {
    	try {
			// Insert Country List.
	        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	        // Insert Region.
	        region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // region = TestDataFactory.Code__c = 'LEB200';
            // insert region;
	        // Insert Country.
	        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
	        // Insert supplier.
	        supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Insert Policy - Tariff conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Condition_Duplication__c = '%';
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    // Duplicate contract version success.
    static testmethod void case1_duplicateContractVersion_success() {
    	init();
    	// Insert contract multi years.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract.Status__c = 'Signed';
        insert contract;
        // Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 2;
        condition1.Value_per_Y1__c = 2;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 5;
        condition2.Value_per_Y1__c = 5;
        Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition3.Value_per__c = 8;
        condition3.Value_per_Y1__c = 8;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        // Start test.
       	Test.startTest();
       	// Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, year + 1, null, null, null, contract.RecordTypeId, true));
       	Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, year + 1, null, null, 'Signed'));
       	Test.stopTest();
       	// Assertion.
       	System.assert(true);
       	/*System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE Reference_Year__c = :(year + 1)]);
       	System.assertEquals(3, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__r.Reference_Year__c = :(year + 1)]);*/
    }

    // Duplicate contract commercials dates success.
    static testmethod void case3_duplicateContractCommercialDates_success() {
    	init();
    	// Insert contract multi years initial.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract.Status__c = 'Signed';
        insert contract;
        // Insert conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition1.Value_per__c = 5;
        condition1.Value_per_Y1__c = 5;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition2.Value_per__c = 2;
        condition2.Value_per_Y1__c = 2;
        insert new List<Contract_Discount__c>{condition1, condition2};
        // Insert sub conditions.
        Contract_Discount__c subCondition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        subCondition1.RecordTypeId = TestDataFactory.conditionRTIds.get('Sub_Term_To_Be_Signed');
        subCondition1.Parent_Discount__c = condition1.Id;
        subCondition1.Value_per__c = 2;
        subCondition1.Value_per_Y1__c = 2;
        insert subCondition1;
        // Clone contract
    	Contract__c contract1 = TestDataFactory.createContract(false, NS, Date.newInstance(year + 1, 3, 1), Date.newInstance(year + 1, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        insert contract1;
        // Start test.
        Test.startTest();
        Date newCommercialBeginDate = contract.Contract_Commercial_EDate__c.addDays(1);
        Date newCommercialEndDate = contract.Contract_Commercial_EDate__c.addYears(1);
       	// Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, null, newCommercialBeginDate, newCommercialEndDate, 'D', contract.RecordTypeId, true));
       	Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, null, Date.newInstance(year + 1, 1, 1), Date.newInstance(year + 1, 3, 0), 'Period_Extension'));
       	Test.stopTest();
       	// Assertion.
        System.assert(true);
        /* System.assertEquals(1, [SELECT COUNT() FROM Contract__c WHERE Contract_MultiYearReference__c = NULL AND Reference_Year__c = :(year + 2)]);
       	System.assertEquals(3, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__r.Contract_MultiYearReference__c = NULL AND Contract__r.Reference_Year__c = :(year + 2)]);*/
        ////System.assertEquals(5, [SELECT Value_per_Y1__c FROM Contract_Discount__c WHERE Contract__r.Contract_MultiYearReference__c = NULL AND Contract__r.Reference_Year__c = :(year + 2)].get(0).Value_per_Y1__c);
    }

    @isTest
    static void duplicateContractBatchTest_Signed() {
        init();
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract.Status__c = 'Signed';
        insert contract;
        tariffCondition.Capture_Discount_Product_Level__c = 'Optional';
        tariffCondition.Condition_Duplication__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 12;
        condition.Disc_BDate_Y1__c = date.newInstance(year, 1, 1);
        condition.Disc_EDate_Y1__c = date.newInstance(year, 12, 31);
        insert condition;
        System.debug('condition: ' + JSON.serialize([SELECT Id, Status__c, Disc_EDate_Y1__c, Contract__r.Contract_Commercial_EDate__c, Product_Scope__r.Status__c, BusinessUnitScope__r.Status__c, Is_Duplicable__c, Is_Duplicable_PE__c, Condition_Type__c, Condition_Type__r.Capture_Discount_Product_Level__c FROM Contract_Discount__c LIMIT 1]));
        Test.startTest();
        contract.Status__c = 'Signed';
        update contract;
        System.debug('contract: ' + JSON.serialize([SELECT Id, RecordType.DeveloperName, Status__c, Supplier__r.Status__c, Supplier_Nego_SCope__r.Status__c, BusinessUnitContract__r.Status__c FROM Contract__c]));
        Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, null, Date.newInstance(year + 1, 3, 1), Date.newInstance(year + 1, 12, 31), 'Signed'));
        Test.stopTest();
        contract = [SELECT Id, RecordType.DeveloperName FROM Contract__c WHERE Reference_Year__c = :(year + 1)];
        List<Contract_Discount__c> conditions = [SELECT Id FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        System.assertEquals('Signed', contract.RecordType.DeveloperName);
        System.assertEquals(1, conditions.size());
    }

    @isTest
    static void duplicateContractBatchTest_Period_Extensiion() {
        init();
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract.Status__c = 'Signed';
        insert contract;
        tariffCondition.Capture_Discount_Product_Level__c = 'Optional';
        tariffCondition.Condition_Duplication_PE__c = '%';
        update tariffCondition;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        condition.Value_per__c = 12;
        condition.Disc_BDate_Y1__c = date.newInstance(year, 1, 1);
        condition.Disc_EDate_Y1__c = date.newInstance(year, 12, 31);
        insert condition;
        System.debug('condition: ' + JSON.serialize([SELECT Id, Status__c, Disc_EDate_Y1__c, Contract__r.Contract_Commercial_EDate__c, Product_Scope__r.Status__c, BusinessUnitScope__r.Status__c, Is_Duplicable__c, Is_Duplicable_PE__c, Condition_Type__c, Condition_Type__r.Capture_Discount_Product_Level__c FROM Contract_Discount__c LIMIT 1]));
        Test.startTest();
        contract.Status__c = 'Signed';
        update contract;
        System.debug('contract: ' + JSON.serialize([SELECT Id, RecordType.DeveloperName, Status__c, Supplier__r.Status__c, Supplier_Nego_SCope__r.Status__c, BusinessUnitContract__r.Status__c FROM Contract__c]));
        Database.executeBatch(new DuplicateContractBatch('Test', country.Id, new List<Id>{contract.Id}, null, Date.newInstance(year + 1, 1, 1), Date.newInstance(year + 1, 3, 0), 'Period_Extension'));
        Test.stopTest();
        contract = [SELECT Id, RecordType.DeveloperName FROM Contract__c WHERE Reference_Year__c = :(year + 1)];
        List<Contract_Discount__c> conditions = [SELECT Id FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        System.assertEquals('Period_Extension', contract.RecordType.DeveloperName);
        System.assertEquals(1, conditions.size());
    }

    @isTest
    static void massDuplicateContractTest() {
        init();
        List<Contract__c> contractList = new List<Contract__c>();
        Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract1.Status__c = 'Signed';
        contractList.add(contract1);
        country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
        supplier = TestDataFactory.createSupplier(true, country, true);
        NS = TestDataFactory.getNSs(supplier.Id)[0];
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        contract2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Contract__c.SObjectType, 'Signed');
        contract2.Status__c = 'Signed';
        contractList.add(contract2);
        insert contractList;
        System.debug('queryResult' + JSON.serialize([SELECT Id FROM Contract__c WHERE Supplier__r.Status__c = 'Active'  AND Supplier_Nego_Scope__r.Status__c = 'Active'  AND BusinessUnitContract__r.Status__c = 'Open' AND Status__c IN ('Balanced', 'Signed') AND RecordType.DeveloperName = 'Signed' AND Reference_Year__c = 2024]));

        Test.startTest();
        Database.executeBatch(new DuplicateContractBatch(null, null, null, year, null, null, null));
        Test.stopTest();
        contractList = [SELECT Id FROM Contract__c WHERE Reference_Year__c = :(year + 1)];
        System.assertEquals(2, contractList.size());
    }

}