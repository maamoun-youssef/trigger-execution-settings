/**
 * @author ULiT
 * @date 02/12/2024
 * @description Apex Handler to handle Trg_Invoice
 * */
public with sharing class Trg_InvoiceDetail_Handler {

    public static void OnBeforeInsertOrUpdate(List<InvoiceDetail__c> nInvoiceDetails, Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        updateTaxes(nInvoiceDetails, oInvoiceDetailsMap);
    }
    
    public static void OnAfterInsertOrUpdate(List<InvoiceDetail__c> nInvoiceDetails, Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        updateInvoice(nInvoiceDetails, oInvoiceDetailsMap);
        calculateCDAlreadyInvoiced(nInvoiceDetails, oInvoiceDetailsMap);
    }

    /*
     * @description called in case Trigger.isAfter && Trigger.isDelete
	*/
    public static void OnAfterDelete(Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        updateInvoice(null, oInvoiceDetailsMap);
        calculateCDAlreadyInvoiced(null, oInvoiceDetailsMap);
    }

    /*
    * @description update VAT and global Locations fields
    * populate Invoice__c
    */
    private static void updateInvoice(List<InvoiceDetail__c> nInvoiceDetails, Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        Map<Id, Invoice__c> invoicesToUpdateMap = new Map<Id, Invoice__c> ();
        Map<Id, Contract_Discount__c> discMap = new Map<Id, Contract_Discount__c>();
        Map<String, GlobalLocation__c> glMap = new Map<String, GlobalLocation__c>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> glIdSet = new Set<Id>();
        List<InvoiceDetail__c> newInvoiceDetails = new List<InvoiceDetail__c>();
        List<InvoiceDetail__c> updateInvoiceDetailsTaxes = new List<InvoiceDetail__c>();
        Set<Id> updatedPaymentToInvoiceIdSet = new Set<Id>();
        Boolean deleteMode = nInvoiceDetails == null;
        List<InvoiceDetail__c> invoiceDetails = !deleteMode ? nInvoiceDetails : oInvoiceDetailsMap.values();
        for (InvoiceDetail__c item : invoiceDetails) {
            if(item.Invoice__c == null) continue;
            if (deleteMode) {
                // update Taxes
                updateInvoiceDetailsTaxes.add(item);
                invoicesToUpdateMap.put(item.Invoice__c, null);
            } else if(oInvoiceDetailsMap == null) {
                if (item.Invoice__c != null) {
                    invoicesToUpdateMap.put(item.Invoice__c, null);
                }
                if (item.DISCLineD__c != null) {
                    discMap.put(item.DISCLineD__c, null);
                }
                // update Global Locations
                newInvoiceDetails.add(item);
                // update Taxes
                updateInvoiceDetailsTaxes.add(item);
            } else if (oInvoiceDetailsMap.containsKey(item.Id)) {
                // update Taxes
                if(item.DetailVATCode__c != oInvoiceDetailsMap.get(item.Id).DetailVATCode__c
                   || item.DetailVATRate__c != oInvoiceDetailsMap.get(item.Id).DetailVATRate__c
                   || item.DetailAmount__c != oInvoiceDetailsMap.get(item.Id).DetailAmount__c)
                {
                    updateInvoiceDetailsTaxes.add(item);
                    invoicesToUpdateMap.put(item.Invoice__c, null);
                }
                // update Payment
                if(item.PaidAmountwVAT__c != oInvoiceDetailsMap.get(item.Id).PaidAmountwVAT__c
                   || item.PaidVATAmount__c != oInvoiceDetailsMap.get(item.Id).PaidVATAmount__c)
                {
                    updatedPaymentToInvoiceIdSet.add(item.Invoice__c);
                    invoicesToUpdateMap.put(item.Invoice__c, null);
                }
            }
        }
        if (!invoicesToUpdateMap.isEmpty()) {
            if (!discMap.isEmpty()) {
                discMap = new Map<Id, Contract_Discount__c> ([SELECT Id, GlobalLocationSeller__c, GlobalLocationPayee__c,
                                                              Product_Scope__r.GlobalLocationAccounting__c,
                                                              Product_Scope__r.GlobalLocationAdministration__c,
                                                              Product_Scope__r.GlobalLocationDelivery__c
                                                              FROM Contract_Discount__c
                                                              WHERE Id IN :discMap.keySet()]);
                for(Contract_Discount__c item : discMap.values()) {
                    if(item.Product_Scope__r.GlobalLocationAccounting__c != null) {
                        glIdSet.add(item.Product_Scope__r.GlobalLocationAccounting__c);
                    }
                    if(item.Product_Scope__r.GlobalLocationAdministration__c != null) {
                        glIdSet.add(item.Product_Scope__r.GlobalLocationAdministration__c);
                    }
                    if(item.Product_Scope__r.GlobalLocationDelivery__c != null) {
                        glIdSet.add(item.Product_Scope__r.GlobalLocationDelivery__c);
                    }
                }
            }
            for (Invoice__c item : [SELECT Id, RecordTypeId, CurrencyIsoCode, BusinessUnitSeller__c, TotalAmount__c,
                                    GlobalLocationBuyer__r.Country__c, GlobalLocationBuyer__r.Country__r.Zone__c, GlobalLocationSeller__r.Country__c,
                                    SupplierSeller__c, SupplierBuyer__c, Contract__c, Contract__r.BusinessUnitContract__r.SetInvoiceSeller__c, Contract__r.Supplier__c,
                                    GlobalLocationSeller__c, GlobalLocationSeller__r.Country__r.Zone__c, GlobalLocationPayee__c, GlobalLocationBuyer__c, GlobalLocationDelivery__c,
                                    VATAmount1__c, VATAmount2__c, VATAmount3__c, VATAmount4__c, VATAmount5__c,
                                    VATAmount6__c, VATAmount7__c, VATAmount8__c, IsManualVAT__c
                                    FROM Invoice__c
                                    WHERE Id IN :invoicesToUpdateMap.keySet()])
            {
                invoicesToUpdateMap.put(item.Id, item);
                supplierIdSet.add(item.SupplierSeller__c);
                if (item.GlobalLocationSeller__c != null) {
                    glMap.put(item.GlobalLocationSeller__c, null);
                    glIdSet.add(item.GlobalLocationSeller__c);
                }
                if (item.GlobalLocationPayee__c != null) {
                    glMap.put(item.GlobalLocationPayee__c, null);
                    glIdSet.add(item.GlobalLocationPayee__c);
                }
                if (item.GlobalLocationBuyer__c != null) {
                    glMap.put(item.GlobalLocationBuyer__c, null);
                    glIdSet.add(item.GlobalLocationBuyer__c);
                }
                if (item.GlobalLocationDelivery__c != null) {
                    glMap.put(item.GlobalLocationDelivery__c, null);
                    glIdSet.add(item.GlobalLocationDelivery__c);
                }
            }
            if (!deleteMode && !newInvoiceDetails.isEmpty() && (!glIdSet.isEmpty() || !supplierIdSet.isEmpty())) {
                List<GlobalLocation__c> globalLocations = [SELECT Id, Name, Country__c, Functions__c, Status__c, BusinessUnit__c, Supplier__c,
                                                           BusinessUnit__r.SetInvoiceSeller__c, CompanyName__c, CurrencyIsoCode, PostalCode__c, City__c,
                                                           ReferenceLanguage__c, Address1__c, Address2__c, Address3__c, Phone1__c, Phone2__c,
                                                           Identifier1__c, Identifier2__c, Identifier3__c, Identifier4__c, Identifier5__c
                                                           FROM GlobalLocation__c
                                                           WHERE (Id IN :glIdSet
                                                                  OR (Functions__c INCLUDES ('InvoiceTo', 'Administrative')
                                                                      AND Status__c = 'Open'
                                                                      AND Supplier__c IN :supplierIdSet))];
                for (GlobalLocation__c gl : globalLocations) {
                    glMap.put(gl.Id, gl);
                    if (gl.Functions__c != null) {
                        if (gl.Functions__c.containsIgnoreCase('InvoiceTo')) {
                            glMap.put(gl.Supplier__c + 'InvoiceTo', gl);
                        }
                        if (gl.Functions__c.containsIgnoreCase('Administrative')) {
                            glMap.put(gl.Supplier__c + 'Administrative',gl);
                        }
                    }
                }
            }
            for (InvoiceDetail__c item : newInvoiceDetails) {
                Invoice__c invoice = invoicesToUpdateMap.get(item.Invoice__c);
                Contract__c contract = invoice?.Contract__r;
                Contract_Discount__c disc = discMap.get(item.DISCLineD__c);
                if (invoice.Contract__c != null) {
                    InvoiceServices.setInvoiceGL(invoice, contract, disc, glMap);
                }
                InvoiceServices.setInvoiceGLCoordinates(invoice, contract, disc, glMap, null);
            }
            // update VAT fields
            if (!updateInvoiceDetailsTaxes.isEmpty()) {
                InvoiceServices.updateTaxes(updateInvoiceDetailsTaxes, invoicesToUpdateMap, true);
            }
            // update Payment
            if (!updatedPaymentToInvoiceIdSet.isEmpty()) {
                InvoiceServices.calculateInvoicePayments(invoicesToUpdateMap);
            }
            Database.update(invoicesToUpdateMap.values(), false);
        }
    }

    /*
    * @description populate InvoiceDetail__c.DetailVATCode__c, InvoiceDetail__c.DetailVATRate__c
    * populate Invoice__c fields: VATCodeX__c, VATBaseAmountX__c, VATRateX__c, VATAmountX__c, TotalVATAmount__c, TotalAmount__c, TotalAmountwVAT__c
    */
    private static void updateTaxes(List<InvoiceDetail__c> nInvoiceDetails, Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        List<InvoiceDetail__c> upsertedInvoiceDetails = new List<InvoiceDetail__c>();
        Set<Id> invoicesSet = new Set<Id>();
        for (InvoiceDetail__c item : nInvoiceDetails) {
            if(item.Invoice__c == null) continue;
            if (item.Id == null || oInvoiceDetailsMap == null
                || (oInvoiceDetailsMap.containsKey(item.Id)
                    && (item.DetailVATCode__c != oInvoiceDetailsMap.get(item.Id).DetailVATCode__c
                        || item.DetailVATRate__c != oInvoiceDetailsMap.get(item.Id).DetailVATRate__c
                        || item.DetailAmount__c != oInvoiceDetailsMap.get(item.Id).DetailAmount__c)))
            {
                invoicesSet.add(item.invoice__c);
                upsertedInvoiceDetails.add(item);
            }
        }
        if (!upsertedInvoiceDetails.isEmpty()) {
            Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([SELECT Id, CurrencyIsoCode, BusinessUnitSeller__c, TotalAmount__c,
                                                                       GlobalLocationBuyer__r.Country__c, GlobalLocationBuyer__r.Country__r.Zone__c,
                                                                       GlobalLocationSeller__c, GlobalLocationSeller__r.Country__c, GlobalLocationSeller__r.Country__r.Zone__c,
                                                                       VATAmount1__c, VATAmount2__c, VATAmount3__c, VATAmount4__c, VATAmount5__c,
                                                                       VATAmount6__c, VATAmount7__c, VATAmount8__c, isManualVAT__c
                                                                       FROM Invoice__c
                                                                       WHERE Id IN :invoicesSet
                                                                       AND BusinessUnitSeller__c <> NULL]);
            InvoiceServices.updateTaxes(upsertedInvoiceDetails, invoicesMap, false);
        }
    }
    
    /*
     * @description calculate Already_Invoiced__c
     */
    private static void calculateCDAlreadyInvoiced(List<InvoiceDetail__c> nInvoiceDetails, Map<Id, InvoiceDetail__c> oInvoiceDetailsMap) {
        Set<Id> discountIds = new Set<Id>();
        Boolean deleteMode = nInvoiceDetails == null;
        List<InvoiceDetail__c> invoiceDetails = !deleteMode ? nInvoiceDetails : oInvoiceDetailsMap.values();
        for (InvoiceDetail__c item : invoiceDetails) {
            if (deleteMode) {
                if (item.DISCLineD__c != null) {
                    discountIds.add(item.DISCLineD__c);
                } 
            } else if (item.Id == null || oInvoiceDetailsMap == null
                       || (oInvoiceDetailsMap.containsKey(item.Id) && item.DetailAmount__c != oInvoiceDetailsMap.get(item.Id).DetailAmount__c))
            {
                if (item.DISCLineD__c != null) {
                    discountIds.add(item.DISCLineD__c);
                }
            }
        }
        if (!discountIds.isEmpty()) {
            Map<Id, Contract_Discount__c> discountsToUpdate = InvoiceServices.calculateCDAlreadyInvoiced(discountIds);
            if (!discountsToUpdate.isEmpty()) {
                Database.update(discountsToUpdate.values(), false);
            }
        }
    }
}