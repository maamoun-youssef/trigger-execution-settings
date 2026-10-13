/**
 * @author ULiT
 * @date 01/06/2022
 * @description unit test class for NegotiateCmpController / NegotiateContractCmpController / NegotiateIndexesCmpController / FollowUpNegotiateCmpController / FollowUpNegotiateContractCmpController
******************************************************************************************************************************************* */
@isTest
public class NegotiateCmpControllerTest {
 	private static Integer year;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country1;
    private static BusinessUnit__c country2;
    private static Supplier__c supplier;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffConditions;
    
    static Contract__c negoBaseContractP1;
    static Contract__c negoBaseContract;
    static Contract__c signedContract;
    static Contract__c negoBaseInitContract;
    static Contract__c toBeSignedContract;
    static Contract__c peContract;
    static Contract__c simulationContract1;
    static Contract__c simulationContract2;
    static Map<String, Id> contractRTIds;

    static void init() {
        try {
            year = System.Today().year();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country1 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            country2 = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country1, true);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
            List<Pol_Com_Condition__c> tariffConditions = new List<Pol_Com_Condition__c>();
            Integer tariffNb = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe().getPicklistValues().size();
            tariffConditions.addAll(TestDataFactory.createTariffConditions(false, 1, tariffNb));
            tariffConditions.addAll(TestDataFactory.createTariffConditions(false, 2, tariffNb));
            tariffConditions.addAll(TestDataFactory.createTariffConditions(false, 3, tariffNb));
            tariffConditions[0].Is_Conditional__c = true;
            Id mainTermRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Pol_Com_Condition__c.SObjectType, 'Main_Term');
            System.debug(' mainTermRecordTypeId >>> ' + JSON.serialize(mainTermRecordTypeId));
            for (Pol_Com_Condition__c item : tariffConditions) {
                item.Condition_Duplication_PE__c = '%;F;U';
                item.Condition_Duplication__c = '%;F;U';
                item.Condition_Mode__c = '%;F;U';
                item.RecordTypeId = mainTermRecordTypeId;
            }
            Database.insert(tariffConditions, false);
            // System.debug(' Database.insert(tariffConditions, false) >>> ' + JSON.serialize(Database.insert(tariffConditions, false)));
            for (Integer index = 0; index < tariffConditions.size(); index++) {
                if (tariffConditions[index].Id == null) {
                    tariffConditions.remove(index);
                    index--;
                }
            }
            // Create Contract
            // Nego Base
            List<Contract__c> contracts = new List<Contract__c>();
            negoBaseInitContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            negoBaseInitContract.Name = supplier.Name + ' - Contract ' + year;
            negoBaseInitContract.TO1__c = 1000;
            // negoBaseInitContract.Contract_Number_Prefix__c = 'CCC';
            negoBaseInitContract.Contract_Type__c = 'Contract';
            negoBaseInitContract.Status__c = 'In preparation';
            negoBaseInitContract.RecordTypeId = contractRTIds.get('Nego_Base_Init');
            negoBaseInitContract.Ext_id__c = 'C000';
            negoBaseInitContract.RecordType = (RecordType)JSON.deserialize('{"DeveloperName": "Nego_Base_Init", "Id":"' + contractRTIds.get('Nego_Base_Init') + '"}', RecordType.class);
            contracts.add(negoBaseInitContract);
            negoBaseContract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            negoBaseContract.Name = supplier.Name + ' - Contract ' + year;
            negoBaseContract.TO1__c = 1000;
            // negoBaseContract.Contract_Number_Prefix__c = 'CCC';
            negoBaseContract.Contract_Type__c = 'Contract';
            negoBaseContract.Status__c = 'In preparation';
            negoBaseContract.RecordTypeId = contractRTIds.get('Nego_Base');
            negoBaseContract.Ext_id__c = 'C001';
            negoBaseContract.RecordType = (RecordType)JSON.deserialize('{"DeveloperName": "Nego_Base", "Id":"' + contractRTIds.get('Nego_Base') + '"}', RecordType.class);
            contracts.add(negoBaseContract);
            // Create Contract - Simulation
            simulationContract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 12, 31));
            simulationContract1.Name = supplier.Name + ' - Contract ' + year;
            simulationContract1.TO1__c = 1000;
            // simulationContract1.Contract_Number_Prefix__c = 'CCC';
            simulationContract1.Contract_Type__c = 'Simulation';
            simulationContract1.Status__c = 'In preparation';
            simulationContract1.Is_OnTop_Simulation__c = true;
            // simulationContract1.SPITM_AftSales_Service_LastResponse_Date__c = date.newInstance(year, 3, 1);
            // simulationContract1.SPITM_AftSales_Service_Last_Request_Date__c = date.newInstance(year, 3, 1);
            // simulationContract1.SPITM_Is_Annex3_Sent_By_Partner__c = true;
            simulationContract1.RecordTypeId = contractRTIds.get('Simulation');
            simulationContract1.Ext_id__c = 'C005';
            contracts.add(simulationContract1);
            insert contracts;
            List<Contract_Discount__c> conditionList = new List<Contract_Discount__c>();
            Integer counter = 0;
            for (Contract__c contract : contracts) {
                for (Pol_Com_Condition__c tariffCondition : tariffConditions) {
                    Contract_Discount__c cond = TestDataFactory.createCondition(false, tariffCondition, contract, contract.Contract_Commercial_BDate__c, contract.Contract_Commercial_EDate__c);
                    cond.Is_Duplicable__c = true;
                    cond.Is_Duplicable_PE__c = true;
                    cond.Is_Excluded_To_NegoBase__c = math.mod(counter, 5) == 2;
                    cond.Is_Tariff_Condition__c = cond.Index__c != 'Index1' ? math.mod(counter, 5) == 3 : false;
                    cond.Is_Yearly_Condition__c = math.mod(counter, 5) == 4;
                    cond.Rank__c = math.mod(counter, 10) != 0 ? math.mod(counter, 10) : 1;
                    cond.Value_amt__c = 1;
                    conditionList.add(cond);
                    counter++;
                }
            }
            // System.debug(' conditionList >>> ' + JSON.serialize(conditionList));
            // System.debug(' Database.insert(conditionList, false) >>> ' + JSON.serialize(Database.insert(conditionList, false)));
            Database.insert(conditionList, false);
            for (Integer index = 0; index < conditionList.size(); index++) {
                if (conditionList[index].Id == null) {
                    conditionList.remove(index);
                    index--;
                }
                if (index > 0) {
                    conditionList[index].Is_AggregatedFromMove__c = math.mod(index, 2) == 0;
                    conditionList[index].Reference_condition__c = conditionList[index - 1]?.Id;
                    conditionList[index].OriginFromMove_ContractDiscount__c = conditionList[index - 1]?.Id;
                    conditionList[index].OriginFromMove_Condition__c = conditionList[index - 1]?.Condition_Type__c;
                }
            }
            System.debug(' conditionList >>> ' + JSON.serialize(conditionList));
            // for (Integer index = 0; index < conditionList.size(); index++) {
            //     if (index > 0) {
            //         conditionList[index].Reference_condition__c = conditionList[index - 1]?.Id;
            //         conditionList[index].OriginFromMove_ContractDiscount__c = conditionList[index - 1]?.Id;
            //         conditionList[index].OriginFromMove_Condition__c = conditionList[index - 1]?.Condition_Type__c;
            //     }
            // }
            update conditionList;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    @isTest static void case00_Search() {
        init();
        Test.startTest();
        NegotiateIndexesCmpController.getContracts(NS.Id, year, null, false);
        NegotiateIndexesCmpController.getContracts(NS.Id, year, negoBaseContract.Id, false);
		Test.stopTest();
    }
    @isTest static void case01_Search() {
        init();
        Test.startTest();
        NegotiateCmpController.getNegoScopes(NS.Name);
        NegotiateCmpController.getNegoScopesBySupplier(supplier.Id);
        NegotiateCmpController.getSuppliers(supplier.Name);
        NegotiateCmpController.getContracts(year, NS.Id, false);
        // NegotiateCmpController.NegoPlanWrapper negoplanWrapper = (NegotiateCmpController.NegoPlanWrapper)JSON.deserialize(NegotiateCmpController.getNegoPlan(year + 1, NS.Id), NegotiateCmpController.NegoPlanWrapper.class);
        NegotiateCmpController.getObjectLabels();
        NegotiateCmpController.consolidateContract(NS.Supplier__c, NS.Id, year, true);
        // NegotiateCmpController.saveNegoPlan(JSON.serialize(negoplanWrapper.negoPlan));
        NegotiateCmpController.deleteContract(negoBaseContract.Id);
		Test.stopTest();
    }
    @isTest static void case02_Search() {
        init();
        Test.startTest();
        NegotiateContractCmpController.getContractData(negoBaseContract.Id);
        Test.stopTest();
    }
    @isTest static void case02_Search_BU() {
        Test.startTest();
        init();
        NegotiateContractCmpController.performBUSearch(null, '');
        NegotiateContractCmpController.performBUSearch(region.Id, country1.Name);
        Test.stopTest();
    }
    @isTest static void case02_Search_NS() {
        init();
        Test.startTest();
        NegotiateContractCmpController.performNSSearch(supplier.Id, NS.Id, '');
        Test.stopTest();
    }
    @isTest static void case03_CreateContract() {
        init();
        Test.startTest();
        System.debug(' NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id) >>> ' + NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        negoBaseContract = Database.query(NegotiateContractCmpController.getContractQuery(negoBaseContract.Id));
        simulationContract1 = Database.query(NegotiateContractCmpController.getContractQuery(simulationContract1.Id));
        NegotiateContractCmpController.CreateContractWrapper newContract = new NegotiateContractCmpController.CreateContractWrapper();
        newContract.refNegoBase = negoBaseContract;
        newContract.sourceContract = negoBaseContract;
        newContract.contractPE = peContract;
        // newContract.targetContractRTDeveloperName = contractRTIds.get('Simulation');
        newContract.targetContractRTDeveloperName = 'Simulation';
        newContract.contractName = 'new Contract simul';
        newContract.refDiscountsList = Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        newContract.negoYear = Date.today().year();
        newContract.beginDate = simulationContract1.Contract_Commercial_BDate__c;
        newContract.EndDate = simulationContract1.Contract_Commercial_EDate__c;
        simulationContract1.BusinessUnitContract__c = null;
        newContract.simulationNumber = 2;
        // newContract.refContractBUId = negoBaseContract.BusinessUnitContract__c;
        newContract.refContractBUId = country2.Id;
        newContract.refContractSourceBUId = simulationContract1.BusinessUnitContract__c;
        NegotiateContractCmpController.createContract(JSON.serialize(newContract));
        Test.stopTest();
    }
    @isTest static void case04_CreateContract() {
        init();
        Test.startTest();
        System.debug(' NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id) >>> ' + NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        negoBaseContract = Database.query(NegotiateContractCmpController.getContractQuery(negoBaseContract.Id));
        NegotiateContractCmpController.CreateContractWrapper newContract2 = new NegotiateContractCmpController.CreateContractWrapper();
        newContract2.refNegoBase = negoBaseContract;
        newContract2.sourceContract = negoBaseContract;
        newContract2.contractPE = peContract;
        newContract2.targetContractRTDeveloperName = 'Period_Extension';
        newContract2.contractName = 'new Contract';
        newContract2.refDiscountsList = Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        newContract2.negoYear = Date.today().year();
        newContract2.beginDate = negoBaseContract.Contract_Commercial_BDate__c;
        newContract2.EndDate = negoBaseContract.Contract_Commercial_EDate__c;
        newContract2.simulationNumber = 1;
        newContract2.refContractBUId = country2.Id;
        newContract2.refContractSourceBUId = negoBaseContract.BusinessUnitContract__c;
        NegotiateContractCmpController.createContract(JSON.serialize(newContract2));
        Test.stopTest();
    }
    @isTest static void case05_CreateContract() {
        init();
        Test.startTest();
        System.debug(' NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id) >>> ' + NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        negoBaseContract = Database.query(NegotiateContractCmpController.getContractQuery(negoBaseContract.Id));
        NegotiateContractCmpController.CreateContractWrapper newContract3 = new NegotiateContractCmpController.CreateContractWrapper();
        newContract3.refNegoBase = negoBaseContract;
        newContract3.sourceContract = negoBaseContract;
        newContract3.contractPE = peContract;
        newContract3.targetContractRTDeveloperName = 'Safe_Balance';
        newContract3.contractName = 'new Contract';
        newContract3.refDiscountsList = Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        newContract3.negoYear = Date.today().year();
        newContract3.beginDate = negoBaseContract.Contract_Commercial_BDate__c;
        newContract3.EndDate = negoBaseContract.Contract_Commercial_EDate__c;
        newContract3.simulationNumber = 1;
        newContract3.refContractBUId = country2.Id;
        newContract3.refContractSourceBUId = negoBaseContract.BusinessUnitContract__c;
        NegotiateContractCmpController.createContract(JSON.serialize(newContract3));
        Test.stopTest();
    }
    @isTest static void case06_calculateIndex() {
        init();
        Test.startTest();
        negoBaseContract = Database.query(NegotiateContractCmpController.getContractQuery(negoBaseContract.Id));
        List<Contract_Discount__c> discounts = Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        NegotiateContractCmpController.calculateIndex(JSON.serialize(negoBaseContract), JSON.serialize(discounts));
        Test.stopTest();
    }
    @isTest static void case06_calculateIndex_and_save() {
        init();
        Test.startTest();
        NegotiateContractCmpController.calculateIndexAndSave(negoBaseContract.Id);
        Test.stopTest();
    }
    @isTest static void case06_fake_save() {
        init();
        Test.startTest();
        NegotiateContractCmpController.fakeSaveContractDiscountData(JSON.serialize(Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id))));
        Test.stopTest();
    }
    @isTest static void case07_lock_unlock() {
        init();
        Test.startTest();
        Approval.lock(negoBaseContract.Id);
        NegotiateContractCmpController.unlockContract(negoBaseContract.Id);
        Test.stopTest();
    }
    @isTest static void case08_save() {
        init();
        Test.startTest();
        negoBaseContract = Database.query(NegotiateContractCmpController.getContractQuery(negoBaseContract.Id));
        List<Contract_Discount__c> discounts = Database.query(NegotiateContractCmpController.getContractDiscountQuery(negoBaseContract.Id));
        if (!discounts.isEmpty()) {
            for (Contract_Discount__c item : discounts) {
                item.Value_amt__c = (Math.random() * 10).intValue();
                item.Value_per__c = (Math.random() * 10).intValue();
                item.Rank__c = (Math.random() * 10).intValue();
            }
            discounts[0].Value_amt__c = 0;
            discounts[0].Value_per__c = 0;
            discounts[0].Rank__c = 0;
            discounts.add(discounts[1].clone());
        }
        NegotiateContractCmpController.saveContractData(JSON.serialize(new Map<String, Object>{'contract' => negoBaseContract, 'discounts'=> discounts}));
        Test.stopTest();
    }
    @isTest static void case09_save_get_NegoPlan() {
        init();
        Test.startTest();
        negoBaseContractP1 = TestDataFactory.createContract(false, NS, date.newInstance(year - 1, 1, 1), date.newInstance(year - 1, 12, 31));
        negoBaseContractP1.Name = supplier.Name + ' - Contract ' + (year - 1);
        negoBaseContractP1.TO1__c = 1000;
        negoBaseContractP1.Contract_Type__c = 'Contract';
        negoBaseContractP1.Status__c = 'Validated';
        negoBaseContractP1.RecordTypeId = contractRTIds.get('Nego_Base');
        negoBaseContractP1.Ext_id__c = 'C001' + (year - 1);
        negoBaseContractP1.RecordType = (RecordType)JSON.deserialize('{"DeveloperName": "Nego_Base", "Id":"' + contractRTIds.get('Nego_Base') + '"}', RecordType.class);
        insert negoBaseContractP1;
        Nego_Plan__c negoPlan = new Nego_Plan__c(Nego_Year__c = year,
                                                 Nego_Scope__c = NS.Id,
                                                 NEGO_Rise_Rate1_Validated__c = 4,
                                                 NEGO_Depreciation_Rate1_Validated__c = 2);
        insert negoPlan;
        NegotiateCmpController.saveNegoPlan(JSON.serialize(negoPlan));
        NegotiateCmpController.getNegoPlan(year, NS.Id);
        Test.stopTest();
        System.assert(true);
    }
}