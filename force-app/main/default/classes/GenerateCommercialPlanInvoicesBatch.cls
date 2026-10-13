/**
 * @author ULiT
 * @date 01-08-2025
 * @description Generate Commercial Plan Invoices
 *******************************************************************************************************************************************/
public with sharing class GenerateCommercialPlanInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {
    private NegoptimBatch nb;
    private String query ;
    private Map<String, Id> invoiceRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Invoice__c.SObjectType);
    private List<String> commercialPlanDetailFields;
    private List<String> commercialPlanConditions;
    private Map<Id, Invoice__c> newCPInvoiceIdMap = new Map<Id, Invoice__c>();
    public GenerateCommercialPlanInvoicesBatch() {}

    public GenerateCommercialPlanInvoicesBatch(String startedFrom, Set<Id> commercialPlanIds) {
        commercialPlanIds = commercialPlanIds == null ? new Set<Id>() : commercialPlanIds;
        this.nb = new NegoptimBatch(GenerateCommercialPlanInvoicesBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        List<String> globalLocationFields = new List<String> {
            SObjectType.GlobalLocation__c.fields.CompanyName__c.Name,
            SObjectType.GlobalLocation__c.fields.Name.Name,
            SObjectType.GlobalLocation__c.fields.Id.Name,
            SObjectType.GlobalLocation__c.fields.Address1__c.Name,
            SObjectType.GlobalLocation__c.fields.Address2__c.Name,
            SObjectType.GlobalLocation__c.fields.Address3__c.Name,
            SObjectType.GlobalLocation__c.fields.PostalCode__c.Name,
            SObjectType.GlobalLocation__c.fields.City__c.Name,
            SObjectType.GlobalLocation__c.fields.Country__c.Name,
            SObjectType.GlobalLocation__c.fields.Phone1__c.Name,
            SObjectType.GlobalLocation__c.fields.Phone2__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier1__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier2__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier3__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier4__c.Name,
            SObjectType.GlobalLocation__c.fields.Identifier5__c.Name
        };
        String globalLocationSellerPrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationSeller__c.Name) + '.';
        String globalLocationPayeePrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.GlobalLocationPayee__c.Name) + '.';
        String globalLocationAccountingPrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.NegoScope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.';
        String prsglobalLocationAccountingPrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name) + '.';
        String globalLocationDeliveryPrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.NegoScope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name) + '.';
        String globalLocationAdministrationPrefix = NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.NegoScope__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name) + '.';
        List<String> commercialPlanFields = new List<String> {
            SObjectType.CommercialPlan__c.fields.Id.Name,
            SObjectType.CommercialPlan__c.fields.Name.Name,
            SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.CommercialPlan__c.fields.Pol_Com_Condition__c.Name,
            SObjectType.CommercialPlan__c.fields.Supplier__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Pol_Com_Condition__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.VAT_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Pol_Com_Condition__c.Name) + '.' + SObjectType.Pol_Com_Condition__c.fields.Acc_Document_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Reference_Year__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_Commercial_BDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_Commercial_EDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Payment_Days__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Payment_Condition__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_BDate__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.Disc_EDate__c.Name,
            SObjectType.CommercialPlan__c.fields.Contract__c.Name,
            SObjectType.CommercialPlan__c.fields.CurrencyISOCode.Name,
            SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name,
            SObjectType.CommercialPlan__c.fields.SellInDiscountMassValueFact2__c.Name,
            SObjectType.CommercialPlan__c.fields.SellInDiscountMassValueInvoice__c.Name,
            SObjectType.CommercialPlan__c.fields.SellOutDiscMassValueContribFact__c.Name,
            SObjectType.CommercialPlan__c.fields.SellOutDiscMassValueContribInvoice__c.Name,
            SObjectType.CommercialPlan__c.fields.ServicesDiscountMassValueFact__c.Name,
            SObjectType.CommercialPlan__c.fields.ServicesDiscountMassValueInvoice__c.Name,
            SObjectType.CommercialPlan__c.fields.PromoAgreementType__c.Name,
            globalLocationSellerPrefix + String.join(globalLocationFields, ', ' + globalLocationSellerPrefix),
            globalLocationPayeePrefix + String.join(globalLocationFields, ', ' + globalLocationPayeePrefix),
            globalLocationAccountingPrefix + String.join(globalLocationFields, ', ' + globalLocationAccountingPrefix),
            globalLocationDeliveryPrefix + String.join(globalLocationFields, ', ' + globalLocationDeliveryPrefix),
            globalLocationAdministrationPrefix + String.join(globalLocationFields, ', ' + globalLocationAdministrationPrefix),
            prsglobalLocationAccountingPrefix + String.join(globalLocationFields, ', ' + prsglobalLocationAccountingPrefix)
        };
        this.commercialPlanDetailFields = new List<String> {
            SObjectType.CommercialPlanDetail__c.fields.Id.Name,
            SObjectType.CommercialPlanDetail__c.fields.Name.Name,
            SObjectType.CommercialPlanDetail__c.fields.CommercialPlanSellIn__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.CommercialPlanSellOut__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.CommercialPlanServices__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.Product__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.VATRate__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellInDiscountMassValueFact2__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellInDiscountMassValueInvoice__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellOutDiscMassValueContribFact__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellOutDiscMassValueContribInvoice__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.ServicesDiscountMassValueFact__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.ServicesDiscountMassValueInvoice__c.Name
        };
        this.commercialPlanConditions = new List<String> {
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.t_IsInvoiceable__c.Name + ' = true',
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Contract_Discount__c.Name) + '.' + SObjectType.Contract_Discount__c.fields.t_invoicingMode__c.Name + ' = \'InvoiceableCounterparty\'',
            SObjectType.CommercialPlan__c.fields.Status__c.Name + ' IN (\'Printed\', \'Validated\')',
            SObjectType.CommercialPlan__c.fields.Id.Name + ' IN (\'' + String.join(commercialPlanIds, '\', \'') + '\')'
        };

        this.query = 'SELECT ' + String.join(commercialPlanFields, ',');
        this.query += ' FROM CommercialPlan__c';
        if (this.commercialPlanConditions.size() > 0) {
            this.query +=' WHERE ' + String.join(commercialPlanConditions, ' AND ');
        }
        List<SObjectType> sobjectTypes = new List<SObjectType>{Invoice__c.sObjectType};
        List<List<String>> fieldApiNames = new List<List<String>>{
            new List<String> {
                SObjectType.Invoice__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.FiscalYear__c.Name,
                //NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.Contract__c.Name,
                //NegoptimHelper.getFieldNameAsRelation(SObjectType.Invoice__c.fields.SupplierBuyer__c.Name) + '.' + SObjectType.Supplier__c.fields.Name.Name,
                SObjectType.Invoice__c.fields.SupplierBuyer__c.Name,
                SObjectType.Invoice__c.fields.AccDoc__c.Name,
                SObjectType.Invoice__c.fields.InvDate__c.Name,
                SObjectType.Invoice__c.fields.TotalAmountwVAT__c.Name,
                SObjectType.Invoice__c.fields.TotalVATAmount__c.Name,
                SObjectType.Invoice__c.fields.CurrencyIsoCode.Name
           }
        };
        this.nb.successLogResultsTable = new Datatable(sobjectTypes, fieldApiNames, true);
        nb.logParameter('query', this.query);
        nb.logParameter('commercialPlanIds', commercialPlanIds);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        system.debug(this.query);
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<CommercialPlan__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try {
            Map<Id, Invoice__c> invoicesToInsertMap = new Map<Id, Invoice__c>();
            Map<Id, List<InvoiceDetail__c>> invoiceDetailsToInsertMap = new Map<Id, List<InvoiceDetail__c>>();
            Map<Id, CommercialPlan__c> commercialPlansToUpdateMap = new Map<Id, CommercialPlan__c>();
            Map<Id, CommercialPlanDetail__c> commercialPlanDetailsToUpdateMap = new Map<Id, CommercialPlanDetail__c>();
            Set<Id> suplierIdSet = new Set<Id>();
            Set<Id> commercialPlanSellInIdSet = new Set<Id>();
            Set<Id> commercialPlanServicesIdSet = new Set<Id>();
            Set<Id> commercialPlanSellOutIdSet = new Set<Id>();
            for (CommercialPlan__c item : scope) {
                suplierIdSet.add(item.Supplier__c);
                if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') {
                    commercialPlanSellInIdSet.add(item.Id);
                } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                    commercialPlanServicesIdSet.add(item.Id);
                } else if (item.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                    commercialPlanSellOutIdSet.add(item.Id);
                }
            }
            Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>> commercialPlanDetailsMap = new Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>>();
            if(!commercialPlanSellInIdSet.isEmpty() || !commercialPlanServicesIdSet.isEmpty() || !commercialPlanSellOutIdSet.isEmpty()) {
                String CPDQuery = 'SELECT ' + String.join(this.commercialPlanDetailFields, ',');
                CPDQuery += ' FROM CommercialPlanDetail__c';
                List<String> orConditions = new List<String>();
                if(!commercialPlanSellInIdSet.isEmpty()) {
                    orConditions.add('(CommercialPlanSellIn__c IN (\'' + String.join(commercialPlanSellInIdSet, '\', \'') + '\'))');
                }
                if(!commercialPlanSellOutIdSet.isEmpty()) {
                    orConditions.add('(CommercialPlanSellOut__c IN (\'' + String.join(commercialPlanSellOutIdSet, '\', \'') + '\'))');
                }
                if(!commercialPlanServicesIdSet.isEmpty()) {
                    orConditions.add('(CommercialPlanServices__c IN (\'' + String.join(commercialPlanServicesIdSet, '\', \'') + '\'))');
                }
                CPDQuery += ' WHERE (' + String.join(orConditions, ' OR ') + ')';
                System.debug('CPDQuery >>> ' + CPDQuery);
                List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDQuery);
                for(CommercialPlanDetail__c item : commercialPlanDetails) {
                    if(item.Product__r.VATRate__c != null) {
                        Decimal varRate = item.Product__r.VATRate__c;
                        if(item.CommercialPlanSellIn__c != null && commercialPlanSellInIdSet.contains(item.CommercialPlanSellIn__c)) {
                            if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellIn__c))
                                commercialPlanDetailsMap.put(item.CommercialPlanSellIn__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                            if(!commercialPlanDetailsMap.get(item.CommercialPlanSellIn__c).containsKey(varRate))
                                commercialPlanDetailsMap.get(item.CommercialPlanSellIn__c).put(varRate, new List<CommercialPlanDetail__c>());
                            commercialPlanDetailsMap.get(item.CommercialPlanSellIn__c).get(varRate).add(item);
                        }
                        if(item.CommercialPlanSellOut__c != null && commercialPlanSellOutIdSet.contains(item.CommercialPlanSellOut__c)) {
                            if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellOut__c))
                                commercialPlanDetailsMap.put(item.CommercialPlanSellOut__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                            if(!commercialPlanDetailsMap.get(item.CommercialPlanSellOut__c).containsKey(varRate))
                                commercialPlanDetailsMap.get(item.CommercialPlanSellOut__c).put(varRate, new List<CommercialPlanDetail__c>());
                            commercialPlanDetailsMap.get(item.CommercialPlanSellOut__c).get(varRate).add(item);
                        }
                        if(item.CommercialPlanServices__c != null && commercialPlanServicesIdSet.contains(item.CommercialPlanServices__c)) {
                            if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanServices__c))
                                commercialPlanDetailsMap.put(item.CommercialPlanServices__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                            if(!commercialPlanDetailsMap.get(item.CommercialPlanServices__c).containsKey(varRate))
                                commercialPlanDetailsMap.get(item.CommercialPlanServices__c).put(varRate, new List<CommercialPlanDetail__c>());
                            commercialPlanDetailsMap.get(item.CommercialPlanServices__c).get(varRate).add(item);
                        }
                    }
                }
            }
            Map<Id, GlobalLocation__c> globalLocationInvoiceToMap = new Map<Id, GlobalLocation__c>();
            Map<Id, GlobalLocation__c> globalLocationAdministrativeMap = new Map<Id, GlobalLocation__c>();
            for (GlobalLocation__c gL : [SELECT Id, Functions__c, CompanyName__c, Name, Address1__c, Address2__c, Address3__c, PostalCode__c, City__c,
                                         Country__c, Phone1__c, Phone2__c, Identifier1__c, Identifier2__c, Identifier3__c, Identifier4__c, Identifier5__c, Supplier__c
                                         FROM GlobalLocation__c
                                         WHERE Functions__c IN ('InvoiceTo', 'Administrative')
                                         AND Status__c = 'Open'
                                         AND Supplier__c IN :suplierIdSet])
            {
                if (!globalLocationInvoiceToMap.containsKey(gL.Supplier__c) && gL.Functions__c.equals('InvoiceTo')) {
                    globalLocationInvoiceToMap.put(gL.Supplier__c, gL);
                }
                if (!globalLocationAdministrativeMap.containsKey(gL.Supplier__c) && gL.Functions__c.equals('Administrative')) {
                    globalLocationAdministrativeMap.put(gL.Supplier__c, gL);
                }
            }
            for (CommercialPlan__c item : scope) {
                //if(!commercialPlanDetailsMap.containsKey(item.Id)) continue;
                Boolean isClassicVAT = item.Pol_Com_Condition__r.VAT_Type__c != 'Product';
                // Create Invoice__c
                Invoice__c newInvoice = new Invoice__c(RecordTypeId = invoiceRTIds.get('TargetToSource'),
                                                       BusinessUnitSeller__c = item.BusinessUnitTarget__c);
                // GlobalLocationSeller
                newInvoice.GlobalLocationSeller__c = item.Contract_Discount__r.GlobalLocationSeller__c;
                newInvoice.SellerCompanyName__c = item.Contract_Discount__r.GlobalLocationSeller__r.CompanyName__c;
                newInvoice.SellerCommercialName__c = item.Contract_Discount__r.GlobalLocationSeller__r.Name;
                newInvoice.SellerAddress1__c = item.Contract_Discount__r.GlobalLocationSeller__r.Address1__c;
                newInvoice.SellerAddress2__c = item.Contract_Discount__r.GlobalLocationSeller__r.Address2__c;
                newInvoice.SellerAddress3__c = item.Contract_Discount__r.GlobalLocationSeller__r.Address3__c;
                newInvoice.SellerPostalCode__c = item.Contract_Discount__r.GlobalLocationSeller__r.PostalCode__c;
                newInvoice.SellerCity__c = item.Contract_Discount__r.GlobalLocationSeller__r.City__c;
                newInvoice.CountryListSeller__c = item.Contract_Discount__r.GlobalLocationSeller__r.Country__c;
                newInvoice.SellerPhone1__c = item.Contract_Discount__r.GlobalLocationSeller__r.Phone1__c;
                newInvoice.SellerPhone2__c = item.Contract_Discount__r.GlobalLocationSeller__r.Phone2__c;
                newInvoice.SellerIdentifier1__c = item.Contract_Discount__r.GlobalLocationSeller__r.Identifier1__c;
                newInvoice.SellerIdentifier2__c = item.Contract_Discount__r.GlobalLocationSeller__r.Identifier2__c;
                newInvoice.SellerIdentifier3__c = item.Contract_Discount__r.GlobalLocationSeller__r.Identifier3__c;
                newInvoice.SellerIdentifier4__c = item.Contract_Discount__r.GlobalLocationSeller__r.Identifier4__c;
                newInvoice.SellerIdentifier5__c = item.Contract_Discount__r.GlobalLocationSeller__r.Identifier5__c;
                // GlobalLocationPayee
                GlobalLocation__c gL = item.Contract_Discount__r.GlobalLocationPayee__c != item.Contract_Discount__r.GlobalLocationSeller__c ? item.Contract_Discount__r.GlobalLocationPayee__r : null;
                newInvoice.GlobalLocationPayee__c = gL?.Id;
                newInvoice.IsPayeeSameAsSeller__c = gL == null;
                newInvoice.PayeeCompanyName__c = gL?.CompanyName__c;
                newInvoice.PayeeCommercialName__c = gL?.Name;
                newInvoice.PayeeAddress1__c = gL?.Address1__c;
                newInvoice.PayeeAddress2__c = gL?.Address2__c;
                newInvoice.PayeeAddress3__c = gL?.Address3__c;
                newInvoice.PayeePostalCode__c = gL?.PostalCode__c;
                newInvoice.PayeeCity__c = gL?.City__c;
                newInvoice.CountryListPayee__c = gL?.Country__c;
                newInvoice.PayeePhone1__c = gL?.Phone1__c;
                newInvoice.PayeePhone2__c = gL?.Phone2__c;
                newInvoice.PayeeIdentifier1__c = gL?.Identifier1__c;
                newInvoice.PayeeIdentifier2__c = gL?.Identifier2__c;
                newInvoice.PayeeIdentifier3__c = gL?.Identifier3__c;
                newInvoice.PayeeIdentifier4__c = gL?.Identifier4__c;
                newInvoice.PayeeIdentifier5__c = gL?.Identifier5__c;
                newInvoice.SupplierBuyer__c = item.Supplier__c;
                // GlobalLocationBuyer
                gL = (item.NegoScope__r.GlobalLocationAccounting__c != null ? item.NegoScope__r.GlobalLocationAccounting__r :
                    (item.NegoScope__r.GlobalLocationAdministration__c != null ? item.NegoScope__r.GlobalLocationAdministration__r :
                    (globalLocationInvoiceToMap.containsKey(item.Supplier__c) ? globalLocationInvoiceToMap.get(item.Supplier__c) :
                    (globalLocationAdministrativeMap.containsKey(item.Supplier__c) ? globalLocationAdministrativeMap.get(item.Supplier__c) : null))));
                newInvoice.GlobalLocationBuyer__c = gL?.Id;
                newInvoice.BuyerCompanyName__c = gL?.CompanyName__c;
                newInvoice.BuyerCommercialName__c = gL?.Name;
                newInvoice.BuyerAddress1__c = gL?.Address1__c;
                newInvoice.BuyerAddress2__c = gL?.Address2__c;
                newInvoice.BuyerAddress3__c = gL?.Address3__c;
                newInvoice.BuyerPostalCode__c = gL?.PostalCode__c;
                newInvoice.BuyerCity__c = gL?.City__c;
                newInvoice.CountryListBuyer__c = gL?.Country__c;
                newInvoice.BuyerPhone1__c = gL?.Phone1__c;
                newInvoice.BuyerPhone2__c = gL?.Phone2__c;
                newInvoice.BuyerIdentifier1__c = gL?.Identifier1__c;
                newInvoice.BuyerIdentifier2__c = gL?.Identifier2__c;
                newInvoice.BuyerIdentifier3__c = gL?.Identifier3__c;
                newInvoice.BuyerIdentifier4__c = gL?.Identifier4__c;
                newInvoice.BuyerIdentifier5__c = gL?.Identifier5__c;
                // GlobalLocationDelivery
                gL = (item.NegoScope__r.GlobalLocationDelivery__c != null ? item.NegoScope__r.GlobalLocationDelivery__r :
                      (item.NegoScope__r.GlobalLocationAdministration__c != null && item.NegoScope__r.GlobalLocationAdministration__c != item.Contract_Discount__r.Product_Scope__r.GlobalLocationAccounting__c ?
                       item.NegoScope__r.GlobalLocationAdministration__r : null));
                newInvoice.GlobalLocationDelivery__c = gL?.Id;
                newInvoice.IsDeliverySameAsBuyer__c = gL == null;
                newInvoice.DeliveryCompanyName__c = gL?.CompanyName__c;
                newInvoice.DeliveryCommercialName__c = gL?.Name;
                newInvoice.DeliveryAddress1__c = gL?.Address1__c;
                newInvoice.DeliveryAddress2__c = gL?.Address2__c;
                newInvoice.DeliveryAddress3__c = gL?.Address3__c;
                newInvoice.DeliveryPostalCode__c = gL?.PostalCode__c;
                newInvoice.DeliveryCity__c = gL?.City__c;
                newInvoice.CountryListDelivery__c = gL?.Country__c;
                newInvoice.DeliveryPhone1__c = gL?.Phone1__c;
                newInvoice.DeliveryPhone2__c = gL?.Phone2__c;
                newInvoice.DeliveryIdentifier1__c = gL?.Identifier1__c;
                newInvoice.DeliveryIdentifier2__c = gL?.Identifier2__c;
                newInvoice.DeliveryIdentifier3__c = gL?.Identifier3__c;
                newInvoice.DeliveryIdentifier4__c = gL?.Identifier4__c;
                newInvoice.DeliveryIdentifier5__c = gL?.Identifier5__c;
                newInvoice.Status__c = 'Generated';
                newInvoice.AccDocType__c = 'Invoice';
                newInvoice.AccDoc__c = item.Pol_Com_Condition__r.Acc_Document_Type__c;
                newInvoice.InvDate__c = Date.today();
                newInvoice.DueDate__c = (item.Contract_Discount__r.Payment_Days__c != null && item.Contract_Discount__r.Payment_Condition__c != null ?
                    NegoptimHelper.getDueDate(newInvoice.InvDate__c, Integer.valueOf(item.Contract_Discount__r.Payment_Days__c), item.Contract_Discount__r.Payment_Condition__c) : null);
                newInvoice.FiscalYear__c = item.Contract__r.Reference_Year__c;
                newInvoice.SeqNumber__c = 1;
                newInvoice.SeqType__c = null;
                newInvoice.Contract__c = item.Contract__c;
                newInvoice.AgreementBDate__c = item.Contract__r.Contract_Commercial_BDate__c;
                newInvoice.AgreementEDate__c = item.Contract__r.Contract_Commercial_EDate__c;
                newInvoice.CurrencyIsoCode = item.CurrencyIsoCode;
                newInvoice.ExchangeRate__c = 1;
                newInvoice.isUpdatedFromYTD__c = false;
                newInvoice.isManualVAT__c = item.Pol_Com_Condition__r.VAT_Type__c == 'Product';
                newInvoice.isManualGL__c = false;
                newInvoice.isManualContact__c = false;
                // create InvoiceDetail__c
                List<InvoiceDetail__c> newInvoiceDetails = new List<InvoiceDetail__c>();
                if(isClassicVAT) {
                    Decimal amount = calculateInvoiceDetailsAmount(isClassicVAT, item, null);
                    if(amount != 0) {
                        InvoiceDetail__c invoiceDetail = addInvoiceDetail(item, amount, null);
                        invoiceDetail.LineId__c = 1;
                        newInvoiceDetails.add(invoiceDetail);
                    }
                } else if(!commercialPlanDetailsMap.isEmpty() && commercialPlanDetailsMap.containsKey(item.Id)) {
                    for(Decimal vatRate : commercialPlanDetailsMap.get(item.Id).keySet()) {
                        List<CommercialPlanDetail__c> commercialPlanDetails = commercialPlanDetailsMap.get(item.Id).get(vatRate);
                        Decimal amount = calculateInvoiceDetailsAmount(isClassicVAT, item, commercialPlanDetails);
                        if(amount != 0) {
                            InvoiceDetail__c invoiceDetail = addInvoiceDetail(item, amount, vatRate);
                            invoiceDetail.LineId__c = newInvoiceDetails.size() + 1;
                            newInvoiceDetails.add(invoiceDetail);
                        }
                    }
                }
                if(!newInvoiceDetails.isEmpty()) {
                    invoicesToInsertMap.put(item.Id, newInvoice);
                    invoiceDetailsToInsertMap.put(item.Id, newInvoiceDetails);
                    // update CommercialPlanDetail__c
                    if(!commercialPlanDetailsMap.isEmpty() && commercialPlanDetailsMap.containsKey(item.Id)) {
                        for(Decimal vatRate : commercialPlanDetailsMap.get(item.Id).keySet()) {
                            List<CommercialPlanDetail__c> commercialPlanDetails = commercialPlanDetailsMap.get(item.Id).get(vatRate);
                            for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) {
                                if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') {
                                    commercialPlanDetail.SellInDiscountMassValueInvoice__c = commercialPlanDetail.SellInDiscountMassValueFact2__c;
                                } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') {
                                    commercialPlanDetail.ServicesDiscountMassValueInvoice__c = commercialPlanDetail.ServicesDiscountMassValueFact__c;
                                } else if (item.PromoAgreementType__c == 'AgencyAgreement') {
                                    commercialPlanDetail.SellOutDiscMassValueContribInvoice__c = commercialPlanDetail.SellOutDiscMassValueContribFact__c;
                                }
                                commercialPlanDetailsToUpdateMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                            }
                        }
                    }
                    // update CommercialPlan__c
                    if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') {
                        item.SellInDiscountMassValueInvoice__c = item.SellInDiscountMassValueFact2__c;
                    } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') {
                        item.ServicesDiscountMassValueInvoice__c = item.ServicesDiscountMassValueFact__c;
                    } else if (item.PromoAgreementType__c == 'AgencyAgreement') {
                        item.SellOutDiscMassValueContribInvoice__c = item.SellOutDiscMassValueContribFact__c;
                    }
                    commercialPlansToUpdateMap.put(item.Id, item);
                }
            }
            Set<Id> newInvoiceIdSet = new Set<Id>();
            if(!invoicesToInsertMap.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.insert(invoicesToInsertMap.values(), true);
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.SaveResult result = saveResults.get(i);
                    Invoice__c newInvoice = invoicesToInsertMap.values().get(i);
                    if(saveResults[i].isSuccess()) {
                        newInvoiceIdSet.add(result.Id);
                    } else {
                        String errorMessage = newInvoice + '\n';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) {
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        this.nb.logError(errorMessage);
                    }
                }
            }
            List<InvoiceDetail__c> invoiceDetailsToInsert = new List<InvoiceDetail__c>();
            for (Id commercialPlanId : invoicesToInsertMap.keySet()) {
                for (InvoiceDetail__c invoiceDetail : invoiceDetailsToInsertMap.get(commercialPlanId)) {
                    invoiceDetail.Invoice__c = invoicesToInsertMap.get(commercialPlanId).Id;
                    invoiceDetailsToInsert.add(invoiceDetail);
                }
            }
            if(!invoiceDetailsToInsert.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.insert(invoiceDetailsToInsert, true);
                nb.logResults(saveResults, invoiceDetailsToInsert);
            }
            if(!newInvoiceIdSet.isEmpty()) {
                Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([SELECT Id, Name, FiscalYear__c, Contract__r.Name, SupplierBuyer__r.Name, AccDoc__c,InvDate__c, TotalAmountwVAT__c, TotalVATAmount__c, CurrencyIsoCode
                                                                           FROM Invoice__c
                                                                           WHERE Id IN :newInvoiceIdSet]);
                for(Invoice__c item : invoicesMap.values()) {
                    this.newCPInvoiceIdMap.put(item.Id, item);
                    this.nb.successLogResultsTable.addRow(new List<SObject>{ item }, NegoptimLabels.getCustomLabel('LBL_Success', ''), '');
                }
            }
            if(!commercialPlansToUpdateMap.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.update(commercialPlansToUpdateMap.values(), true);
                nb.logResults(saveResults, commercialPlansToUpdateMap.values());
            }
            if(!commercialPlanDetailsToUpdateMap.isEmpty()) {
                List<Database.SaveResult> saveResults = Database.update(commercialPlanDetailsToUpdateMap.values(), true);
                nb.logResults(saveResults, commercialPlanDetailsToUpdateMap.values());
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            nb.logError(e);
        }
        //nb.saveLog(bc);
        this.nb.incrementBatchIndex();
    }

    public void finish(Database.BatchableContext bc) {
        Map<String, String > resultStatusMap = new Map<String, String>{
            'Successful' => 'LBL_Batch_Successful',
            'Warning' => 'LBL_Batch_Warning',
            'Failed' => 'LBL_Batch_Failed',
            'Unknown' => 'LBL_Batch_Unknown'
        };
        String currentDateTime = System.now().format();
        this.nb.setSuccessLogResultsTable((this.nb.successLogResultsTable.hasRows()) ? this.nb.successLogResultsTable : null);
        String resultStatus = resultStatusMap.get(this.getResultStatus(this.nb, bc));
        if(resultStatus == null) { resultStatus = 'LBL_Batch_Unknown'; }
        String translatedStatus = NegoptimLabels.getCustomLabel(resultStatus, '');
        String subjectLabel = NegoptimLabels.getCustomLabel('MSG_GenerateCPInvoice_SubjectMessage', '');
        String subjectFormatedMsg = String.format(subjectLabel, new List<String>{ currentDateTime, translatedStatus });
        String bodyLabel = NegoptimLabels.getCustomLabel('MSG_GenerateCPInvoice_EmailMessage', '');
        bodyLabel = bodyLabel.replace('\n', '<br/><br/>');
        String bodyFormatedMsg = String.format(bodyLabel, new List<String>{ currentDateTime, translatedStatus });
        this.nb.logResultsTableHeader = bodyFormatedMsg;
        // send email
        this.nb.customEmailSubject = subjectFormatedMsg;
        this.nb.sendEmail(bc, 'NegoptimGenericEmail');
        // send Notification
        String notificationTitle = NegoptimLabels.getCustomLabel('MSG_GenerateCPInvoice_NotificationTitle', '');
        String notificationBodyLabel = NegoptimLabels.getCustomLabel('MSG_GenerateCPInvoice_NotificationBody', '');
        String notificationBody = String.format(notificationBodyLabel, new List<String>{ currentDateTime, String.valueOf(this.newCPInvoiceIdMap.size()) ,translatedStatus, UserInfo.getUserEmail() });
        if(this.newCPInvoiceIdMap.isEmpty()) {
            this.nb.sendNotification(bc, this.nb.getLog().Id, notificationTitle, notificationBody);
            return;
        }
        List<String> invoiceNames = new List<String>();
        for(Invoice__c invoice : this.newCPInvoiceIdMap.values()) {
            invoiceNames.add(invoice.Name);
        }
        Map<String, Object> appliedFiltersMap = new Map<String, Object> {
            'recordIds' => this.newCPInvoiceIdMap.keySet()
            //'filterDescriptions' => new List<String>{ 'Name: ' + String.join(invoiceNames, ', ') }
             //'filterDescriptions' => invoiceNames
        };
        String appliedFiltersBase64Encoded = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(appliedFiltersMap)));
        String appliedFilters = EncodingUtil.urlEncode(appliedFiltersBase64Encoded, 'UTF-8');
        String prefix = NegoptimHelper.getPackagePrefix(true);
        Map<String, Object> pageRefMap = new Map<String, Object> {
            'type' => 'standard__navItemPage',
            'attributes' => new Map<String, Object> { 'apiName' => prefix + 'InvoiceManager' },
            'state' => new Map<String, Object> { 'c__appliedfilters' => appliedFilters }
        };
        nb.sendNotification(bc, JSON.serialize(pageRefMap), notificationTitle, notificationBody);
    }

    private String getResultStatus(NegoptimBatch nb,Database.BatchableContext bc) {
        if(nb.getAsyncApexJob(bc) == null) { return 'Unknown'; }
        if(nb.getAsyncApexJob(bc).NumberOfErrors > 0) { return 'Failed'; }
        Integer nbOfWarnings = nb.getLog() == null ? nb.getNumberOfErrors() : (Integer) nb.getLog().NumberOfWarnings__c;
        if(nbOfWarnings > 0) { return 'Warning'; }
        return 'Successful';
    }

    private Decimal calculateInvoiceDetailsAmount(Boolean isClassicVAT, CommercialPlan__c item, List<CommercialPlanDetail__c> commercialPlanDetails) {
        Decimal amount = 0;
        if (isClassicVAT) {
            switch on item.PromoAgreementType__c {
                when 'CallOffAgreementSellIn' {
                    amount = (item.SellInDiscountMassValueFact2__c != null ? item.SellInDiscountMassValueFact2__c : 0);
                    amount -= (item.SellInDiscountMassValueInvoice__c != null ? item.SellInDiscountMassValueInvoice__c : 0);
                }
                when 'CallOffAgreementSellOut' {
                    amount = (item.ServicesDiscountMassValueFact__c != null ? item.ServicesDiscountMassValueFact__c : 0);
                    amount -= (item.ServicesDiscountMassValueInvoice__c != null ? item.ServicesDiscountMassValueInvoice__c : 0);
                }
                when 'AgencyAgreement' {
                    amount = (item.SellOutDiscMassValueContribFact__c != null ? item.SellOutDiscMassValueContribFact__c : 0);
                    amount -= (item.SellOutDiscMassValueContribInvoice__c != null ? item.SellOutDiscMassValueContribInvoice__c : 0);
                }
            }
        } else if(commercialPlanDetails != null) {
            for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) {
                switch on item.PromoAgreementType__c {
                    when 'CallOffAgreementSellIn' {
                        amount += (commercialPlanDetail.SellInDiscountMassValueFact2__c != null ? commercialPlanDetail.SellInDiscountMassValueFact2__c : 0);
                        amount -= (commercialPlanDetail.SellInDiscountMassValueInvoice__c != null ? commercialPlanDetail.SellInDiscountMassValueInvoice__c : 0);
                    }
                    when 'CallOffAgreementSellOut' {
                        amount += (commercialPlanDetail.ServicesDiscountMassValueFact__c != null ? commercialPlanDetail.ServicesDiscountMassValueFact__c : 0);
                        amount -= (commercialPlanDetail.ServicesDiscountMassValueInvoice__c != null ? commercialPlanDetail.ServicesDiscountMassValueInvoice__c : 0);
                        System.debug('amount 1 >>> ' + amount);
                    }
                    when 'AgencyAgreement' {
                        amount += (commercialPlanDetail.SellOutDiscMassValueContribFact__c != null ? commercialPlanDetail.SellOutDiscMassValueContribFact__c : 0);
                        amount -= (commercialPlanDetail.SellOutDiscMassValueContribInvoice__c != null ? commercialPlanDetail.SellOutDiscMassValueContribInvoice__c : 0);
                    }
                }
            }
        }
        return amount;
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> commercialPlanIds = (Set<Id>)paramsMap.get('commercialPlanIds');
        return new GenerateCommercialPlanInvoicesBatch(startedFrom, commercialPlanIds);
    }

    private InvoiceDetail__c addInvoiceDetail(CommercialPlan__c item, Decimal amount, Decimal vatRate) {
        InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(BusinessUnitSellerDetail__c = item.BusinessUnitTarget__c,
                                                              //DISCLine__c = item.Contract_Discount__c,
                                                              DISCLineD__c = item.Contract_Discount__c,
                                                              DISCNegoType__c = item.Contract_Discount__r.Nego_Discount_Type__c,
                                                              DISCBudgetCode__c = item.Pol_Com_Condition__c,
                                                              DISCBDate__c = item.Contract_Discount__r.Disc_BDate__c,
                                                              DISCEDate__c = item.Contract_Discount__r.Disc_EDate__c,
                                                              DetailAmount__c = amount,
                                                              DetailNetPrice__c = amount,
                                                              DetailGrossPrice__c = amount,
                                                              DetailVATRate__c = vatRate,
                                                              DetailQty__c = 1,
                                                              DetailQtyUnit__c = 'C62',
                                                              DetailRebatePrice__c = 0,
                                                              //DetailRebateAmount__c = 0, //Not Writeable
                                                              CommercialPlan__c = item.Id,
                                                              CurrencyIsoCode = item.CurrencyIsoCode);
        return invoiceDetail;
    }
}