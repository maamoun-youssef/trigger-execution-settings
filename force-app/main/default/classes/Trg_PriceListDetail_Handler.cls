/**
 * @author ULiT
 * @description Handler for the trigger Trg_PriceListDetail
 **/
public with sharing class Trg_PriceListDetail_Handler {
    
    public static void OnBeforeInsertOrUpdate(List<PriceListDetail__c> newPriceListDetail, Map<Id, PriceListDetail__c> oldPriceListDetailMap) {
        validateConstraintOnUpsertPriceListDetail(newPriceListDetail, oldPriceListDetailMap);
        populateFields(newPriceListDetail, oldPriceListDetailMap);
    }
    
    public static void OnBeforeInsert(List<PriceListDetail__c> newPriceListDetail) {
        updateOwnerIdOnInsert(newPriceListDetail);
    }
    
    /* @description make sure NOT there are PriceListDetail__c records duplication in database or amongest the upserted records
     * @param List<PriceListDetail__c> newPriceListDetail, Map<Id, PriceListDetail__c> oldPriceListDetailMap.
     * On Before Insert Or Update.
     **/
    private static void validateConstraintOnUpsertPriceListDetail(List<PriceListDetail__c> newPriceListDetail, Map<Id, PriceListDetail__c> oldPriceListDetailMap) {
        Map<String, PriceListDetail__c> priceListDetailsMap = new Map<String, PriceListDetail__c>();
        Set<Id> priceListDetailsIdSet = new Set<Id>();
        Set<Id> priceListsIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Date> startDateRequestedSet = new Set<Date>();
        for (PriceListDetail__c item : newPriceListDetail) {
            if (item.Id == null || (oldPriceListDetailMap != null && oldPriceListDetailMap.containsKey(item.Id)
                && (item.Product__c != oldPriceListDetailMap.get(item.Id).Product__c
                || item.StartDateRequested__c != oldPriceListDetailMap.get(item.Id).StartDateRequested__c)))
            {
                if(item.Id != null) {
                    priceListDetailsIdSet.add(item.Id);
                }
                priceListsIdSet.add(item.PriceList__c);
                if(item.Product__c != null) {
                    productIdSet.add(item.Product__c);
                }
                if(item.StartDateRequested__c != null) {
                    startDateRequestedSet.add(item.StartDateRequested__c);
                }
                String key = (String.valueOf(item.PriceList__c) + '' +
                    (item.Product__c != null ? String.valueOf(item.Product__c) : '') + '' +
                    (item.StartDateRequested__c != null ? String.valueOf(item.StartDateRequested__c) : ''));
                // Check duplicate priceList by key = PriceList__c + Product__c + StartDateRequested__c
                if (priceListDetailsMap.containsKey(key)) {
                    item.addError(System.Label.MSG_PLD_Duplicate_Start_Date);
                } else {
                    priceListDetailsMap.put(key, item);
                }
            }
        }
        if(!productIdSet.isEmpty() && !startDateRequestedSet.isEmpty()) {
            for (PriceListDetail__c  item : [SELECT Id, PriceList__c, Product__c, StartDateRequested__c
                                             FROM PriceListDetail__c
                                             WHERE Id NOT IN :priceListDetailsIdSet
                                             AND PriceList__c IN :priceListsIdSet
                                             AND Product__c IN :productIdSet
                                             AND StartDateRequested__c IN :startDateRequestedSet])
            {
                String key = (String.valueOf(item.PriceList__c) + '' +
                    (item.Product__c != null ? String.valueOf(item.Product__c) : '') + '' +
                    (item.StartDateRequested__c != null ? String.valueOf(item.StartDateRequested__c) : ''));
                if (priceListDetailsMap.containsKey(key)) {
                    priceListDetailsMap.get(key).addError(System.Label.MSG_PLD_Duplicate_Start_Date);
                }
            }
        }
    }
    
    /*
     * @description populate fields t_ActiveTaxes__c, t_DiscountTaxes__c, t_NetPriceTaxes__c, t_GrossPriceTaxes__c, t_InvoiceFooterTaxes__c
     * On Before-Insert
     */
    private static void populateFields(List<PriceListDetail__c> newPriceListDetail, Map<Id, PriceListDetail__c> oldPriceListDetailMap) {
        List<PriceListDetail__c> newPLDs = new List<PriceListDetail__c>();
        Set<Id> priceListsIdSet = new Set<Id>();
        for (PriceListDetail__c item : newPriceListDetail) {
            if(item.Id == null) {
                priceListsIdSet.add(item.PriceList__c);
                newPLDs.add(item);
            }
        }
        Map<Id, PriceListWrapper> priceListsMap = new Map<Id, PriceListWrapper>();
        if(!newPLDs.isEmpty()) {
            for(PriceList__c item : [SELECT Id, t_ActiveTaxesList__c
                                     FROM PriceList__c
                                     WHERE Id IN :priceListsIdSet])
            {
                String activeTaxes = '';
                String discountTaxes = '';
                String netTaxes = '';
                String grossPriceTaxes = '';
                String invoiceFooterTaxes = '';
                if (item.t_ActiveTaxesList__c != null && String.isNotBlank(item.t_ActiveTaxesList__c)) {
                    for (TaxWrapper tax : (List<TaxWrapper>) JSON.deserialize(item.t_ActiveTaxesList__c, List<TaxWrapper>.class)) {
                        activeTaxes += ('A' + tax.displayOrder + '/');
                        if(tax.isDiscountTax) {
                            discountTaxes += ('D' + tax.displayOrder + '/');
                        }
                        if(tax.isNetPriceTax) {
                            netTaxes += ('N' + tax.displayOrder + '/');
                        }
                        if(tax.isGrossPriceTax) {
                            grossPriceTaxes += ('G' + tax.displayOrder + '/');
                        }
                        if(tax.isInvoiceFooterTax) {
                            invoiceFooterTaxes += ('I' + tax.displayOrder + '/');
                        }
                    }
                }
                priceListsMap.put(item.Id, new PriceListWrapper(item, activeTaxes, discountTaxes, netTaxes, grossPriceTaxes, invoiceFooterTaxes));
            }
            for (PriceListDetail__c item : newPLDs) {
                PriceListWrapper priceListWrapper = priceListsMap.get(item.PriceList__c);
                item.t_ActiveTaxes__c = priceListWrapper.activeTaxes;
                item.t_DiscountTaxes__c = priceListWrapper.discountTaxes;
                item.t_NetPriceTaxes__c = priceListWrapper.netTaxes;
                item.t_GrossPriceTaxes__c = priceListWrapper.grossPriceTaxes;
                item.t_InvoiceFooterTaxes__c = priceListWrapper.invoiceFooterTaxes;
            }
        }
    }
    
    public class PriceListWrapper {
        public PriceList__c priceList {get; set;}
        public String activeTaxes {get; set;}
        public String discountTaxes {get; set;}
        public String netTaxes {get; set;}
        public String grossPriceTaxes {get; set;}
        public String invoiceFooterTaxes {get; set;}
        public PriceListWrapper(PriceList__c item, String activeTaxes, String discountTaxes, String netTaxes, String grossPriceTaxes, String invoiceFooterTaxes) {
            this.priceList = item;
            this.activeTaxes = activeTaxes;
            this.discountTaxes = discountTaxes;
            this.netTaxes = netTaxes;
            this.grossPriceTaxes = grossPriceTaxes;
            this.invoiceFooterTaxes = invoiceFooterTaxes;
        }
    }
    
    public class TaxWrapper {
        public String recordId {get; set;}
        public String Name {get; set;}
        public Integer displayOrder {get; set;}
        public Boolean isGrossPriceTax {get; set;}
        public Boolean isDiscountTax {get; set;}
        public Boolean isNetPriceTax {get; set;}
        public Boolean isInvoiceFooterTax {get; set;}
        public TaxWrapper(Id recordId, String Name, Integer displayOrder, Boolean isGrossPriceTax, Boolean isDiscountTax, Boolean isNetPriceTax, Boolean isInvoiceFooterTax) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.isGrossPriceTax = isGrossPriceTax;
            this.isDiscountTax = isDiscountTax;
            this.isNetPriceTax = isNetPriceTax;
            this.isInvoiceFooterTax = isInvoiceFooterTax;
        }
    }
    
    /**
     * @description Updates OwnerId before insert using the formula field OwnerIdPL__c.
     * @param List<PriceListDetail__c> newPriceListDetail
     * On before insert
     */
    private static void updateOwnerIdOnInsert(List<PriceListDetail__c> newPriceListDetail) {
        for (PriceListDetail__c pld : newPriceListDetail) {
            pld.OwnerId = pld.OwnerIdPL__c;
        }
    } 
}