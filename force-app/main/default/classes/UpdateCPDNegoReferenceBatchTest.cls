@isTest
public class UpdateCPDNegoReferenceBatchTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c supplier;
    private static Hierarchy__c department;
    private static Hierarchy__c section;
    private static Product2 product;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Pol_Com_Condition__c tariffCondition;

	static void init() {
    	try {
            Id rootId = TestDataFactory.getHierarchyRootId();
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(false,  region.Id);
            ////country.Set_Invoice_Detail__c = true;
            ////country.Set_Invoice__c = true;
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            update country;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(true, section.Id, supplier.Id);
            PG__c pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            insert pg;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create NS PG
            TestDataFactory.createNSPG(true, NS, pg.Id);
            // Create sale condition.
            Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name = country.Name + ' ' + year, Status_BDate__c = date.newInstance(year, 1, 1),
                                                                            BusinessUnitMaster__c= country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,
                                                                            Buying_Payment_Condition__c = 'Net', Buying_Payment_Days__c = '90', Status__c = 'Validated');
            insert saleCondition;
	        // Create contract.
	        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Number__c = 'C0A1',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                       Contract_Commercial_BDate__c = date.newInstance(year, 1, 1), Contract_Commercial_EDate__c = date.newInstance(year, 12, 31),
                                       Duration__c = 12, BusinessUnitContract__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode,
                                       Status__c = 'Signed', D_N__c = 'N',/* Tactite_reconduction__c = True, Duration_type__c= 'Month',*/
                                       TO1__c = 10, TO2__c = 10, TO3__c = 10, TO4__c = 10,
                                    //    TO1_Fact__c = 10, TO2_Fact__c = 10, TO3_Fact__c = 10, TO4_Fact__c = 10,
                                    //    TO1_FX__c = 10, TO2_FX__c = 10, TO3_FX__c = 10, TO4_FX__c = 10,
                                       Qty1__c = 20, Qty2__c = 20, Qty3__c = 20, Qty4__c = 20, Qty5__c = 20, Qty6__c = 20,
                                       Qty7__c = 20, Qty8__c = 20, Qty9__c = 20, Qty10__c = 20,  Qty11__c = 20,  Qty12__c = 20);
                                    //    Qty1_Fact__c = 20, Qty2_Fact__c = 20, Qty3_Fact__c = 20, Qty4_Fact__c = 20, Qty5_Fact__c = 20, Qty6_Fact__c = 20,
                                    //    Qty7_Fact__c = 20, Qty8_Fact__c = 20, Qty9_Fact__c = 20, Qty10_Fact__c = 20, Qty11_Fact__c = 20, Qty12_Fact__c = 20
            contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
            insert contract;
	        // Create Policy - Tariff conditions.
	        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
	        String plv = fieldResult.getPicklistValues().get(2).getValue();
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Name = plv;
            tariffCondition.Nego_Discount_Type__c = plv;
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Proof_counterparty_requested__c = true;
            tariffCondition.Index__c = 'Index1';
            tariffCondition.Is_Conditional__c = false;
            insert tariffCondition;
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_massAttachCOntractDiscountToPromo() {
        init();
        // Insert Commercial plan
        CommercialPlan__c commercialPlan = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BusinessUnitTarget__c = country.Id;
        commercialPlan.Supplier__c = supplier.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        List<CommercialPlanDetail__c> commercialPlanDetailList = new List<CommercialPlanDetail__c>();
        for (Integer i = 0; i < 55; i++) {
            CommercialPlanDetail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.BusinessUnitTarget__c = country.Id;
            commercialPlanDetail.SellOutBDate__c = Date.newInstance(year, 2, 2).addDays(i);
            commercialPlanDetail.Product__c = product.Id;
            commercialPlanDetailList.add(commercialPlanDetail);
        }
        insert commercialPlanDetailList;
        tariffCondition.SetCommercialPlanDetail1__c = true;
        update tariffCondition;
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = Date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BusinessUnitScope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false, Value_amt__c = 100);
        insert condition;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => UpdateCPDNegoReferenceBatchTest.class.getName(),
            'commercialPlanDetailsIdSet' => null,
            'updateNSReference' => false,
            'updateContractReference' => true
        };
        NegoptimBatch.executeBatch('UpdateCPDNegoReferenceBatch', paramsMap, 100);
        Test.stopTest();
        commercialPlanDetailList = [SELECT Id, NegoScope__c, Contract__c, Contract_Discount1__c
                                    FROM CommercialPlanDetail__c WHERE Id IN :commercialPlanDetailList];
        for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetailList) {
            system.debug('INN');
            System.assertEquals(NS.Id, commercialPlanDetail.NegoScope__c);
            System.assertEquals(contract.Id, commercialPlanDetail.Contract__c);
            System.assertEquals(condition.Id, commercialPlanDetail.Contract_Discount1__c);
            
        }
    }

}