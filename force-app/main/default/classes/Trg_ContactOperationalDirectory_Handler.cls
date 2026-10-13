/**
 * @author ULiT
 * @date 5/11/2024
 * @description Handler for the trigger Trg_ContactOperationalDirectory
 **/
public with sharing class Trg_ContactOperationalDirectory_Handler {

    public static void OnBeforeInsertOrUpdate(List<ContactOperationalDirectory__c> newCODs, Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        validateConstraint(newCODs, oldCODMap);
    }

    public static void OnAfterInsertOrUpdate(List<ContactOperationalDirectory__c> newCODs, Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        updateRelatedRecords(newCODs, oldCODMap);
        generateFileDirectorySharing(newCODs, oldCODMap);
    }

    public static void OnAfterDelete(Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        updateRelatedRecords(null, oldCODMap);
    }

    /*
    * @description Ensure that each ContactOperationalDirectory__c (COD) record associated
    * with the same Contact has a unique value for the RequestedNegoscope__c field.
    * @param List<ContactOperationalDirectory__c> newCODs.
    * @param List<ContactOperationalDirectory__c> oldCODMap.
    * On Before Insert Or Update.
    **/
    public static void validateConstraint(List<ContactOperationalDirectory__c> newCODs, Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        // 1- Collect Contact__c from newCODs
        Map<String, ContactOperationalDirectory__c> CODsMap = new Map<String, ContactOperationalDirectory__c>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> requestedNegoscopeIdSet = new Set<Id>();
        Set<Id> CODIdSet = new Set<Id>();
        for (ContactOperationalDirectory__c item : newCODs) {
            if (item.Contact__c != null
                && (item.Id == null || (oldCODMap != null && oldCODMap.containsKey(item.Id)
                                        && ((item.Contact__c != oldCODMap.get(item.Id).Contact__c
                                             || item.RequestedNegoscope__c != oldCODMap.get(item.Id).RequestedNegoscope__c
                                             || item.Negoscope__c != oldCODMap.get(item.Id).Negoscope__c)))))
            {
                if(item.Id != null) {
                    CODIdSet.add(item.Id);
                }
                String key = String.valueOf(item.Contact__c) + (String.isNotBlank(item.Negoscope__c) ? String.valueOf(item.Negoscope__c) : (String.isNotBlank(item.RequestedNegoscope__c) ? String.valueOf(item.RequestedNegoscope__c) : ''));
                if (CODsMap.containsKey(key)) {
                    item.addError(Label.LBL_Connect_DuplicateCODError);
                } else {
                    CODsMap.put(key, item);
                }
                contactIdSet.add(item.Contact__c);
                requestedNegoscopeIdSet.add(item.RequestedNegoscope__c);
            }
        }
        // 2- Query all cod grouping by Contact__c/RequestedNegoscope__c
        if(!contactIdSet.isEmpty() && !requestedNegoscopeIdSet.isEmpty()) {
            List<ContactOperationalDirectory__c> existingCODList = [SELECT Id, Contact__c, RequestedNegoscope__c, Negoscope__c
                                                                    FROM ContactOperationalDirectory__c
                                                                    WHERE Id NOT IN :CODIdSet
                                                                    AND Contact__c IN :contactIdSet];
            for (ContactOperationalDirectory__c item : existingCODList) {
                String key = String.valueOf(item.Contact__c) + ((String.isNotBlank(item.Negoscope__c) ? String.valueOf(item.Negoscope__c) : (String.isNotBlank(item.RequestedNegoscope__c) ? String.valueOf(item.RequestedNegoscope__c) : '')));
                if (CODsMap.containsKey(key)) {
                    CODsMap.get(key).addError(Label.LBL_Connect_DuplicateCODError);
                }
            }
        }
    }

    /**
     * @description collects Negoscope__c and Supplier__c of records where ContactRole__c was updated
     * then launch FileDirectorySharingBatch
     * @param List<ContactOperationalDirectory__c> newCODs
     * @param List<ContactOperationalDirectory__c> oldCODMap
     * Triggered on After Insert/Update.
     */
    public static void generateFileDirectorySharing(List<ContactOperationalDirectory__c> newCODs, Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        Set<Id> contactIdSet = new Set<Id>();
        for (ContactOperationalDirectory__c item: newCODs) {
            contactIdSet.add(item.Contact__c);
        }
        Set<Id> connectContactIdSet = new Set<Id>();
        for (Contact contact: [SELECT Id FROM Contact WHERE Id IN :contactIdSet AND IsConnectUser__c = TRUE]) {
            connectContactIdSet.add(contact.Id);
        }
        Set<Id> supplierIdSet = new Set<Id>();
        if(!connectContactIdSet.isEmpty()) {
            for (ContactOperationalDirectory__c item : newCODs) {
                if (item.Negoscope__c != null && item.Supplier__c != null
                    && (oldCODMap == null || !oldCODMap.containsKey(item.Id) || (item.ContactRole__c != oldCODMap.get(item.Id).ContactRole__c) || (item.ActivationStatus__c != oldCODMap.get(item.Id).ActivationStatus__c) ))
                {
                    supplierIdSet.add(item.Supplier__c);
                }
            }
        }
        // if (!System.isBatch() && !System.isFuture() && !supplierIdSet.isEmpty()) {
        //     NegoptimBatch.executeBatch(new FileDirectorySharingBatch(Trg_ContactOperationalDirectory_Handler.class.getName(), null, null, supplierIdSet, null, null, false, false), 200);
        // }
    }

    /**
     * @description update related records
     * @param List<Contact> nContacts
     * @param List<Contact> oContactMap
     * Triggered on After Update.
     */
    public static void updateRelatedRecords(List<ContactOperationalDirectory__c> newCODs, Map<Id, ContactOperationalDirectory__c> oldCODMap) {
        final Integer NB_BUYER_CONTACTS = 5;
        Boolean deleteMode = newCODs == null;
        List<ContactOperationalDirectory__c> CODs = !deleteMode ? newCODs : oldCODMap.values();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> negoScopeIdSet = new Set<Id>();
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        List<ContactOperationalDirectory__c> updatedCODs = new List<ContactOperationalDirectory__c>();
        Map<String, List<Contact>> newContactsToInvoicesMap = new Map<String, List<Contact>>();
        Set<Id> newContactsToInvoiceIdSet = new Set<Id>();
        Set<Id> deletedContactsFromInvoiceIdSet = new Set<Id>();
        List<ContactOperationalDirectoryEvent__e> codEvents = new List<ContactOperationalDirectoryEvent__e>();
        for (ContactOperationalDirectory__c item : CODs){
            // add event if supplier is not null
            if (item.Supplier__c != null) {
                String mode;
                if (Trigger.isUpdate) {
                    mode = 'Update';
                } else if (Trigger.isInsert) {
                    mode = 'Insert';
                } else if (Trigger.isDelete) {
                    mode = 'Delete';
                }
                codEvents.add(new ContactOperationalDirectoryEvent__e(
                    Supplier__c = item.Supplier__c,
                    Contact__c = item.Contact__c,
                    ContactOperationalDirectory__c = item.Id,
                    Mode__c = mode
                ));
            }
            // update invoices contacts and emails
            if (item.Contact__c != null && item.Supplier__c != null && item.NegoScope__c != null) {
                if((oldCODMap != null && oldCODMap.containsKey(item.Id)
                    && ((item.IsInvoiceRecipient__c == false && oldCODMap.get(item.Id).IsInvoiceRecipient__c == true)
                        || (item.IsInvoiceRecipient__c == true && item.IsDeleted == false && oldCODMap.get(item.Id).IsDeleted == true)))
                   || (deleteMode && item.IsInvoiceRecipient__c == true))
                {
                    deletedContactsFromInvoiceIdSet.add(item.Contact__c);
                }
                if((oldCODMap == null && item.IsInvoiceRecipient__c == true)
                   || (oldCODMap != null && oldCODMap.containsKey(item.Id)
                       && item.IsInvoiceRecipient__c == true && item.IsInvoiceRecipient__c != oldCODMap.get(item.Id).IsInvoiceRecipient__c))
                {
                    newContactsToInvoiceIdSet.add(item.Contact__c);
                    updatedCODs.add(item);
                }
            }
        }
        Map<Id, Contact> codContactsMap = new Map<Id, Contact>();
        if(!updatedCODs.isEmpty()) {
            codContactsMap = new Map<Id, Contact> ([SELECT Id, Email, Supplier__c
                                                    FROM Contact
                                                    WHERE Type__c = 'Individual'
                                                    AND Id IN :newContactsToInvoiceIdSet]);
            for (ContactOperationalDirectory__c item : updatedCODs) {
                if(codContactsMap.containskey(item.Contact__c)) {
                    Contact contact = codContactsMap.get(item.Contact__c);
                    String key = String.valueOf(item.Supplier__c) + String.valueOf(item.Negoscope__c);
                    supplierIdSet.add(item.Supplier__c);
                    negoScopeIdSet.add(item.Negoscope__c);
                    if (!newContactsToInvoicesMap.containsKey(key)) newContactsToInvoicesMap.put(key, new List<Contact>());
                    newContactsToInvoicesMap.get(key).add(contact);
                }
            }
        }
        if (!newContactsToInvoicesMap.isEmpty() || !deletedContactsFromInvoiceIdSet.isEmpty()) {
            invoicesToUpdate = [SELECT Id, SupplierBuyer__c, Contract__c, Contract__r.Supplier_Nego_Scope__c,
                                BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                                BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                                FROM Invoice__c
                                WHERE Status__c IN ('inPreparation', 'Generated', 'Validated', 'ReadyToPrint')
                                AND SupplierBuyer__c <> NULL
                                AND Contract__r.Supplier_Nego_Scope__c <> NULL
                                AND ((SupplierBuyer__c IN :supplierIdSet AND Contract__r.Supplier_Nego_Scope__c IN :negoScopeIdSet
                                      AND (BuyerContact1__c = NULL OR BuyerContact2__c = NULL OR BuyerContact3__c = NULL OR BuyerContact4__c = NULL OR BuyerContact5__c = NULL))
                                     OR ((BuyerContact1__c <> NULL AND BuyerContact1__c IN :deletedContactsFromInvoiceIdSet)
                                         OR (BuyerContact2__c <> NULL AND BuyerContact2__c IN :deletedContactsFromInvoiceIdSet)
                                         OR (BuyerContact3__c <> NULL AND BuyerContact3__c IN :deletedContactsFromInvoiceIdSet)
                                         OR (BuyerContact4__c <> NULL AND BuyerContact4__c IN :deletedContactsFromInvoiceIdSet)
                                         OR (BuyerContact5__c <> NULL AND BuyerContact5__c IN :deletedContactsFromInvoiceIdSet)))];
            InvoiceServices.fillContacts(invoicesToUpdate);
            if (!invoicesToUpdate.isEmpty()) {
                update invoicesToUpdate;
            }
        }
        // fire ContactOperationalDirectoryEvent__e Event
        if (!codEvents.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(codEvents);
        }
    }
}