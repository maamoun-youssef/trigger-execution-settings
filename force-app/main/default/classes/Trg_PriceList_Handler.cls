/**
 * @author ULiT
 * @description Handler for the trigger Trg_PriceList
 **/
public with sharing class Trg_PriceList_Handler {

    public static Map<Id, String> priceListRTIds = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(PriceList__c.SObjectType);
    public static Map<Id, String> priceListRTLabels = NegoptimHelper.getObjectRecordTypeMapLabels(PriceList__c.SObjectType);
    public static void OnBeforeInsertOrUpdate(List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap) {
        validateConstraintOnUpsertPriceList(newPriceList, oldPriceListMap);
        populateFields(newPriceList, oldPriceListMap);
    }
    
    public static void OnAfterUpdate(List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap) {
        updatePLDetailOwnerId(newPriceList, oldPriceListMap);
    }
    
    /*
     * @description called in case Trigger.isAfter && Trigger.isDelete
	*/
    public static void OnAfterDelete() {
        cleanUpRelatedList();
    }
    /* @description make sure NOT there are PriceList__c records duplication in database or amongest the upserted records
     * @param List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap.
     * On Before Insert Or Update.
     **/
    private static void validateConstraintOnUpsertPriceList(List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap) {
        Map<String, PriceList__c> priceListsMap = new Map<String, PriceList__c>();
        Set<Id> priceListsIdSet = new Set<Id>();
        Set<Id> businessUnitSourceIdSet = new Set<Id>();
        Set<Id> businessUnitTargetIdSet = new Set<Id>();
        Set<Date> startDateRequestedSet = new Set<Date>();
        for (PriceList__c item : newPriceList) {
            if (item.Id == null || (oldPriceListMap != null && oldPriceListMap.containsKey(item.Id)
                                    && (item.BusinessUnitSource__c != oldPriceListMap.get(item.Id).BusinessUnitSource__c
                                        || item.BusinessUnitTarget__c != oldPriceListMap.get(item.Id).BusinessUnitTarget__c
                                        || item.StartDateRequested__c != oldPriceListMap.get(item.Id).StartDateRequested__c)))
            {
                if(item.Id != null) {
                    priceListsIdSet.add(item.Id);
                }
                if(item.BusinessUnitSource__c != null) {
                    businessUnitSourceIdSet.add(item.BusinessUnitSource__c);
                }
                if(item.BusinessUnitTarget__c != null) {
                    businessUnitTargetIdSet.add(item.BusinessUnitTarget__c);
                }
                if(item.StartDateRequested__c != null) {
                    startDateRequestedSet.add(item.StartDateRequested__c);
                }
                String key = ((item.BusinessUnitSource__c != null ? String.valueOf(item.BusinessUnitSource__c) : '') + '' + 
                              (item.BusinessUnitTarget__c != null ? String.valueOf(item.BusinessUnitTarget__c) : '') + '' +
                              (item.StartDateRequested__c != null ? String.valueOf(item.StartDateRequested__c) : ''));
                // Check duplicate priceList by key = BusinessUnitSource__c + BusinessUnitTarget__c + StartDateRequested__c
                if (priceListsMap.containsKey(key)) {
                    item.addError(System.Label.MSG_PL_Duplicate_Start_Date);
                } else {
                    priceListsMap.put(key, item);
                }
            }
        }
        if(!businessUnitSourceIdSet.isEmpty() && !businessUnitTargetIdSet.isEmpty() && !startDateRequestedSet.isEmpty()) {
            for (PriceList__c  item : [SELECT Id, BusinessUnitSource__c, BusinessUnitTarget__c, StartDateRequested__c
                                       FROM PriceList__c
                                       WHERE Id NOT IN :priceListsIdSet
                                       AND BusinessUnitSource__c IN :businessUnitSourceIdSet
                                       AND BusinessUnitTarget__c IN :businessUnitTargetIdSet
                                       AND StartDateRequested__c IN :startDateRequestedSet])
            {
                String key = ((item.BusinessUnitSource__c != null ? String.valueOf(item.BusinessUnitSource__c) : '') + '' + 
                              (item.BusinessUnitTarget__c != null ? String.valueOf(item.BusinessUnitTarget__c) : '') + '' +
                              (item.StartDateRequested__c != null ? String.valueOf(item.StartDateRequested__c) : ''));
                if (priceListsMap.containsKey(key)) {
                    priceListsMap.get(key).addError(System.Label.MSG_PL_Duplicate_Start_Date);
                }
            }
        }
    }
    
    /*
     * @description populate fields Name = Label(RecordType.Name) + IF(NOT_NULL(BusinessUnitSource__c),  " - " + BusinessUnitSource__c, "")  + " - " + Year__c + IF(NOT_NULL(BusinessUnitTarget__c),  " - " + BusinessUnitTarget__c, "") 
     * On Before-Insert
     */ 
    private static void populateFields(List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap) {
        Set<Id> businessUnitSourceIdSet = new Set<Id>();
        Set<Id> businessUnitTargetIdSet = new Set<Id>();
        List<PriceList__c> insertedPriceLists = new List<PriceList__c>();
        for (PriceList__c item : newPriceList) {
            if(item.Id == null) {
                if(item.BusinessUnitSource__c != null) {
                    businessUnitSourceIdSet.add(item.BusinessUnitSource__c);
                }
                if(item.BusinessUnitTarget__c != null) {
                    businessUnitTargetIdSet.add(item.BusinessUnitTarget__c);
                }
                insertedPriceLists.add(item);
            }
            if (item.Id == null || item.ExtId__c == null || (oldPriceListMap != null && oldPriceListMap.containsKey(item.Id)
                                                             && (item.BusinessUnitSource__c != oldPriceListMap.get(item.Id).BusinessUnitSource__c
                                                                 || item.BusinessUnitTarget__c != oldPriceListMap.get(item.Id).BusinessUnitTarget__c
                                                                 || item.StartDateRequested__c != oldPriceListMap.get(item.Id).StartDateRequested__c)))
            {
                item.ExtId__c = ((item.RecordTypeId != null ? priceListRTIds.get(item.RecordTypeId) : '') +
                                 (item.BusinessUnitSource__c != null ? '-' + item.BusinessUnitSource__c : '') +
                                 (item.BusinessUnitTarget__c != null ? '-' + item.BusinessUnitTarget__c : '') +
                                 (item.StartDateRequested__c != null ? '-' + ((Datetime)item.StartDateRequested__c).formatGMT('yyyy-MM-dd') : ''));
            }
        }
        if(!insertedPriceLists.isEmpty()) {
            Map<Id, BusinessUnit__c> businessUnitsMap = new Map<Id, BusinessUnit__c>();
            if(!businessUnitSourceIdSet.isEmpty() || !businessUnitTargetIdSet.isEmpty()) {
                businessUnitsMap = new Map<Id, BusinessUnit__c>([SELECT Id, Name, Code__c
                                                                 FROM BusinessUnit__c
                                                                 WHERE Id IN :businessUnitSourceIdSet
                                                                 OR Id IN :businessUnitTargetIdSet]);
            }
            List<Tax__c> taxes = new List<Tax__c>();
            for(Tax__c item : [SELECT Id, Name, BusinessUnitSource__c, BusinessUnitTarget__c, DisplayOrder__c, IsGrossPriceTax__c, IsDiscountTax__c, IsNetPriceTax__c, IsInvoiceFooterTax__c
                               FROM Tax__c
                               WHERE RecordType.DeveloperName = 'Regular'
                               AND Status__c = 'Open'
                               AND DisplayOrder__c <> NULL
                               AND (BusinessUnitSource__c = NULL OR BusinessUnitTarget__c = NULL OR BusinessUnitSource__c IN :businessUnitSourceIdSet OR BusinessUnitTarget__c IN :businessUnitTargetIdSet)
                               ORDER BY BusinessUnitSource__c NULLS LAST, BusinessUnitTarget__c NULLS LAST, DisplayOrder__c ASC])
            {
                taxes.add(item);
            }
            for (PriceList__c item : insertedPriceLists) {
                item.Name = ((item.RecordTypeId != null ? priceListRTLabels.get(item.RecordTypeId) : '') +
                             (item.BusinessUnitSource__c != null ? ' - ' + businessUnitsMap.get(item.BusinessUnitSource__c).Name : '') +
                             (item.StartDateRequested__c != null ? ' - ' + item.StartDateRequested__c.year() : '') +
                             (item.BusinessUnitTarget__c != null ? ' - ' + businessUnitsMap.get(item.BusinessUnitTarget__c).Name : ''));
                Map<Integer, Tax__c> priceListTaxesMap = new Map<Integer, Tax__c>();
                for(Tax__c tax : taxes) {
                    if(priceListTaxesMap.containsKey(Integer.valueOf(tax.DisplayOrder__c))) continue;
                    if((tax.BusinessUnitSource__c == item.BusinessUnitSource__c || tax.BusinessUnitSource__c == null)
                       && (tax.BusinessUnitTarget__c == item.BusinessUnitTarget__c || tax.BusinessUnitTarget__c == null))
                    {
                        priceListTaxesMap.put(Integer.valueOf(tax.DisplayOrder__c), tax);
                    }
                }
                if(!priceListTaxesMap.isEmpty()) {
                    List<TaxWrapper> taxWrapperList = new List<TaxWrapper>();
                    for(Tax__c tax : priceListTaxesMap.values()) {
                        TaxWrapper taxWrapper = new TaxWrapper(tax.Id, tax.Name, Integer.valueOf(tax.DisplayOrder__c), tax.IsGrossPriceTax__c, tax.IsDiscountTax__c, tax.IsNetPriceTax__c, tax.IsInvoiceFooterTax__c);
                        taxWrapperList.add(taxWrapper);
                    }
                    item.t_ActiveTaxesList__c = Json.serialize(taxWrapperList);
                }
            }
        }
    }
    
    /*
     * @description delete PriceListDetail__c when delete PriceList__c
    */
    private static void cleanUpRelatedList() {
        // delete all related PriceListDetail__c
        if(NegoptimHelper.checkDeletibility(PriceListDetail__c.SObjectType)) {
            Map<String, Object> paramsDelete = new Map<String, Object>{
                'startedFrom' => Trg_PriceList_Handler.class.getname(),
                'objectName' => SObjectType.PriceListDetail__c.Name,
                'filter' => 'PriceList__c = NULL'
            };
            NegoptimBatch.executeBatch('MassDeleteBatch', paramsDelete, 2000);
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
     * @description 
     * Updates the OwnerId of PriceListDetail__c when the OwnerId of their parent PriceList__c is changed.
     */
    public static void updatePLDetailOwnerId(List<PriceList__c> newPriceList, Map<Id, PriceList__c> oldPriceListMap) {
        List<Id> updatedPriceListIds = new List<Id>();
        for (PriceList__c priceList : newPriceList) {
            if (oldPriceListMap.containsKey(priceList.Id) && oldPriceListMap.get(priceList.Id).OwnerId != priceList.OwnerId) {
                updatedPriceListIds.add(priceList.Id);
            }
        }
        try {
            if (!updatedPriceListIds.isEmpty()) {
                Map<String, Object> paramsOwner = new Map<String, Object>{
                    'startedFrom' => Trg_PriceList_Handler.class.getName(),
                    'recordsIds' => updatedPriceListIds,
                    'objectName' => sObjectType.PriceListDetail__c.Name,
                    'relationName' => sObjectType.PriceList__c.Name
                };
                NegoptimBatch.executeBatch('SetOwnerIdBatch', paramsOwner, 200);
            }
        } catch (Exception e) {
            for (PriceList__c item : newPriceList) {
                item.addError(e.getMessage());
            }
        }
    }
}