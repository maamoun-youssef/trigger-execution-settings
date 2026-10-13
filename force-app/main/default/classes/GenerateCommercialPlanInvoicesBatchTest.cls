/**
 * @author ULiT
 * @date 10-09-2025
 * @description unit test for GenerateCommercialPlanInvoicesBatch
 **/
@isTest
private class GenerateCommercialPlanInvoicesBatchTest {
    
    private static Integer year = TestDataFactory.year;
    private static Supplier__c supplier;
    private static BusinessUnit__c country, region;
    private static Product2 product;
    private static Hierarchy__c department, section;
    private static NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffConditionSellIn, tariffConditionSellOut, tariffConditionServices;
    private static Contract_Discount__c discountSellIn, discountSellOut, discountServices;
    private static CommercialPlan__c cpParent, cpSellIn, cpSellOut, cpServices;
    private static CommercialPlanDetail__c cpdSellIn, cpdSellOut, cpdServices;
    private static GlobalLocation__c globalLocationSeller;
    
    static void init() {
        try {
            Id rootId = TestDataFactory.getHierarchyRootId();
            // Create Region
            region = TestDataFactory.createBusinessUnitRegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            country.Supplier__c = supplier.Id;
            country.SetInvoiceSeller__c = true;
            country.Status__c = 'Open';
            update country;
            department = TestDataFactory.createHierarchyDepartment(true, rootId);
            section = TestDataFactory.createHierarchySection(true, department.Id);
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.VATRate__c = 0.5;
            insert product;
            // Get the default NegoScope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create contract.
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.RecordTypeId = TestDataFactory.contractRTIds.get('To_Be_Signed');
            insert contract;
            // Insert Policy - Tariff conditions.
            tariffConditionSellIn = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionSellIn.SetCommercialPlanDetail1__c = true;
            tariffConditionSellIn.IsCounterpartyInvoiceable__c = true;
            tariffConditionSellIn.PromoStatementType__c = 'SellIn';
            tariffConditionSellIn.VAT_Type__c = 'Product';
            tariffConditionSellOut = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionSellOut.SetCommercialPlanDetail1__c = true;
            tariffConditionSellOut.IsCounterpartyInvoiceable__c = true;
            tariffConditionSellOut.PromoStatementType__c = 'SellOut';
            tariffConditionSellOut.VAT_Type__c = 'Product';
            tariffConditionServices = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionServices.SetCommercialPlanDetail1__c = true;
            tariffConditionServices.IsCounterpartyInvoiceable__c = true;
            tariffConditionServices.PromoStatementType__c = 'Services';
            tariffConditionServices.VAT_Type__c = 'Service';
            insert new List<Pol_Com_Condition__c> { tariffConditionSellIn, tariffConditionSellOut, tariffConditionServices };
            // Create Contract_Discount__c
            discountSellIn = TestDataFactory.createCondition(false, tariffConditionSellIn, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountSellIn.Value_per__c = 10;
            discountSellOut = TestDataFactory.createCondition(false, tariffConditionSellOut, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountSellOut.Value_per__c = 10;
            discountServices = TestDataFactory.createCondition(false, tariffConditionServices, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            discountServices.Value_per__c = 10;
            insert new List<Contract_Discount__c> { discountSellIn, discountSellOut, discountServices };
            // Create GlobalLocation__c
            globalLocationSeller = new GlobalLocation__c(Name = 'InvoiceTo',
                                                         Functions__c = 'InvoiceTo',
                                                         Status__c = 'Open',
                                                         Supplier__c = supplier.Id,
                                                         Country__c = null);
            insert new List<GlobalLocation__c> { globalLocationSeller };
            // Create CommercialPlan__c
            cpParent = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            cpParent.Name = 'ParentCP';
            cpParent.Hierarchy__c = department.Id;
            cpParent.BusinessUnitTarget__c = country.Id;
            cpParent.Supplier__c = supplier.Id;
            cpParent.Status__c = 'Validated';
            insert cpParent;
            cpSellIn = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            cpSellIn.Supplier__c = supplier.Id;
            cpSellIn.BusinessUnitTarget__c = country.Id;
            cpSellIn.CommercialPlanParent__c = cpParent.Id;
            cpSellIn.Contract__c = contract.Id;
            cpSellIn.Contract_Discount__c = discountSellIn.Id;
            cpSellIn.Pol_Com_Condition__c = tariffConditionSellIn.Id;
            cpSellIn.PromoAgreementType__c = 'CallOffAgreementSellIn';
            cpSellIn.Status__c = 'Validated';
            cpSellOut = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            cpSellOut.Supplier__c = supplier.Id;
            cpSellOut.BusinessUnitTarget__c = country.Id;
            cpSellOut.CommercialPlanParent__c = cpParent.Id;
            cpSellOut.Contract__c = contract.Id;
            cpSellOut.Contract_Discount__c = discountSellOut.Id;
            cpSellOut.Pol_Com_Condition__c = tariffConditionSellOut.Id;
            cpSellOut.PromoAgreementType__c = 'AgencyAgreement'; // SellOut
            cpSellOut.Status__c = 'Validated';
            cpServices = TestDataFactory.createCommercialPlan(false, Date.newInstance(year, 1, 1), Date.newInstance(year, 12, 31));
            cpServices.Supplier__c = supplier.Id;
            cpServices.BusinessUnitTarget__c = country.Id;
            cpServices.CommercialPlanParent__c = cpParent.Id;
            cpServices.Contract__c = contract.Id;
            cpServices.Contract_Discount__c = discountServices.Id;
            cpServices.Pol_Com_Condition__c = tariffConditionServices.Id;
            cpServices.PromoAgreementType__c = 'CallOffAgreementSellOut'; // Services
            cpServices.Status__c = 'Validated';
            insert new List<CommercialPlan__c> { cpSellIn, cpSellOut, cpServices};
            // Insert CommercialPlanDetail__c SellIn
            cpdSellIn = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
            cpdSellIn.Supplier__c = supplier.Id;
            cpdSellIn.Contract__c = contract.Id;
            cpdSellIn.BusinessUnitTarget__c = country.Id;
            cpdSellIn.Product__c = product.Id;
            cpdSellIn.Contract_Discount1__c = discountSellIn.Id;
            cpdSellIn.CommercialPlanSellIn__c = cpSellIn.Id;
            cpdSellIn.SellOutBDate__c = Date.newInstance(year, 2, 1);
            cpdSellIn.SellOutDiscountValue__c = 100;
            cpdSellIn.ServicesDiscountUAmt__c = 100;
            cpdSellIn.VolumeTarget__c = 10;
            cpdSellIn.SellInDiscountUAmtNego__c = 10;
            cpdSellIn.SellOutDiscountQtyTarget__c = 10;
            cpdSellIn.SellOutDiscountQtyFact__c = 10;
            cpdSellIn.SellOutDiscountUAmt__c = 10;
            cpdSellIn.SellOutSourceContribPerc__c = 10;
            cpdSellIn.SellOutQtyTarget__c = 10;
            cpdSellIn.ServicesDiscountFixedAmt__c = 10;
            cpdSellIn.SellInDiscountMassValueFact__c = 10;
            cpdSellIn.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
            cpdSellIn.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
            cpdSellIn.SellInDiscountPerNego__c = 10;
            // cpdSellIn.status__c = 'Realized';
            // Insert CommercialPlanDetail__c SellOut
            cpdSellOut = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
            cpdSellOut.Supplier__c = supplier.Id;
            cpdSellOut.Contract__c = contract.Id;
            cpdSellOut.BusinessUnitTarget__c = country.Id;
            cpdSellOut.Product__c = product.Id;
            cpdSellOut.Contract_Discount1__c = discountSellOut.Id;
            cpdSellOut.Contract_DiscountSellOut1__c = discountSellOut.Id;
            cpdSellOut.CommercialPlanSellOut__c = cpSellOut.Id;
            cpdSellOut.SellOutBDate__c = Date.newInstance(year, 2, 1);
            cpdSellOut.SellOutDiscountValue__c = 100;
            cpdSellOut.ServicesDiscountUAmt__c = 100;
            cpdSellOut.VolumeTarget__c = 10;
            cpdSellOut.SellInDiscountUAmtNego__c = 10;
            cpdSellOut.SellOutDiscountQtyTarget__c = 10;
            cpdSellOut.SellOutDiscountQtyFact__c = 10;
            cpdSellOut.SellOutDiscountUAmt__c = 10;
            cpdSellOut.SellOutSourceContribPerc__c = 10;
            cpdSellOut.SellOutQtyTarget__c = 10;
            cpdSellOut.ServicesDiscountFixedAmt__c = 10;
            cpdSellOut.SellInDiscountMassValueFact__c = 10;
            cpdSellOut.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
            cpdSellOut.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
            cpdSellOut.SellInDiscountPerNego__c = 10;
            // cpdSellOut.status__c = 'Realized';
            // Insert CommercialPlanDetail__c AgencyAgreement // // Services
            cpdServices = TestDataFactory.createCommercialPlanDetail(false, cpParent.Id, NS);
            cpdServices.Supplier__c = supplier.Id;
            cpdServices.Contract__c = contract.Id;
            cpdServices.BusinessUnitTarget__c = country.Id;
            cpdServices.Product__c = product.Id;
            cpdServices.Contract_Discount1__c = discountServices.Id;
            cpdServices.Contract_DiscountServices1__c = discountServices.Id;
            cpdServices.CommercialPlanServices__c = cpServices.Id;
            cpdServices.SellOutBDate__c = Date.newInstance(year, 2, 1);
            cpdServices.SellOutDiscountValue__c = 100;
            cpdServices.ServicesDiscountUAmt__c = 100;
            cpdServices.VolumeTarget__c = 10;
            cpdServices.SellInDiscountUAmtNego__c = 10;
            cpdServices.SellOutDiscountQtyTarget__c = 10;
            cpdServices.SellOutDiscountQtyFact__c = 10;
            cpdServices.SellOutDiscountUAmt__c = 10;
            cpdServices.SellOutSourceContribPerc__c = 10;
            cpdServices.SellOutQtyTarget__c = 10;
            cpdServices.ServicesDiscountFixedAmt__c = 10;
            cpdServices.SellInDiscountMassValueFact__c = 10;
            cpdServices.QuantityFact__c = 10; // SellInDiscountMassValueFact2__c = QuantityFact__c * SellInDiscountUnitValue__c
            cpdServices.PWFBeforePromoDisc__c = 10; // SellInDiscountUnitValue__c = PWFBeforePromoDisc__c * SellInDiscountPerNego__c / 100 + SellInDiscountUAmtNego__c
            cpdServices.SellInDiscountPerNego__c = 10;
            // cpdServices.status__c = 'Realized';
            insert new List<CommercialPlanDetail__c> { cpdSellIn, cpdSellOut, cpdServices };
            discountSellIn.t_IsInvoiceable__c = true;
            discountSellIn.t_invoicingMode__c = 'InvoiceableCounterparty';
            update discountSellIn;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest
    static void case1_generateInvoices() {
        init();
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => 'TEST',
            'commercialPlanIds' => new Set<Id> { cpSellIn.Id, cpSellOut.Id, cpServices.Id }
        };
        String jobId = NegoptimBatch.executeBatch('GenerateCommercialPlanInvoicesBatch', paramsMap, 200);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c WHERE CommercialPlan__c = :cpSellIn.Id]);
        //System.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c WHERE CommercialPlan__c = :cpSellOut.Id]);
        //System.assertEquals(1, [SELECT COUNT() FROM InvoiceDetail__c WHERE CommercialPlan__c = :cpServices.Id]);
        cpdSellIn = [SELECT Id, SellInDiscountMassValueInvoice__c, SellInDiscountMassValueFact2__c FROM CommercialPlanDetail__c WHERE Id = :cpdSellIn.Id];
        System.debug(JSON.serialize(cpdSellIn));
        System.assertEquals(cpdSellIn.SellInDiscountMassValueFact2__c, cpdSellIn.SellInDiscountMassValueInvoice__c);
    }
}