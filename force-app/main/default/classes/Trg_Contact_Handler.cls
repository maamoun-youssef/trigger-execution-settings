/**
 * @author ULiT
 *  * @date 19/12/2024
 * @description Handler for the trigger Trg_Contact
 * */
public with sharing class Trg_Contact_Handler {
    public static void OnAfterInsertOrUpdate(List<Contact> nContacts, Map<Id, Contact> oContactMap) {
        updateRelatedRecords(nContacts, oContactMap);
    }
    
    public static void OnAfterUpdate(List<Contact> nContacts, Map<Id, Contact> oContactMap) {
        generateFileDirectorySharing(nContacts, oContactMap);
    }
    
    public static void OnAfterDelete(Map<Id, Contact> oContactMap) {
        updateRelatedRecords(null, oContactMap);
    }
    
    /**
     * @description collect Contact Ids where IsConnectUser has been updated
     * then launch FileDirectorySharingBatch
     * @param List<Contact> nContacts
     * @param List<Contact> oContactMap
     * Triggered on After Update.
     */
    public static void generateFileDirectorySharing(List<Contact> nContacts, Map<Id, Contact> oContactMap) {
        Set<Id> contactIdSet = new Set<Id>();
        for (Contact item: nContacts) {
            if (oContactMap != null
                && oContactMap.containsKey(item.Id)
                && item.IsConnectUser__c != oContactMap.get(item.Id).IsConnectUser__c
                && item.IsConnectUser__c == true
                && item.Supplier__c != null)
            {
                contactIdSet.add(item.Id);
            }
        }
        if (!System.isBatch() && !System.isFuture() && !contactIdSet.isEmpty()) {
            Set<Id> supplierIdSet = new Set<Id>();
            Set<Id> negoScopeIdSet = new Set<Id>();
            for (Contact item : [SELECT Id, Supplier__c
                                 FROM Contact 
                                 WHERE Id IN :contactIdSet
                                 AND Supplier__c <> NULL])
            {
                supplierIdSet.add(item.Supplier__c);
            }
            Map<String, Object> fdsParamsMap = new Map<String, Object>{
                'startedFrom' => Trg_Contact_Handler.class.getName(),
                'fileDirectoryIdSet' => null,
                'negoScopeIdSet' => null,
                'supplierIdSet' => supplierIdSet,
                'contactIdSet' => contactIdSet,
                'subTypeSet' => null,
                'isGenerateContentDocumentLink' => false,
                'updateFileDirectorySharing' => false
            };
            NegoptimBatch.executeBatch('FileDirectorySharingBatch', fdsParamsMap, 200);
        }
    }
    
    /**
     * @description update related records
     * @param List<Contact> nContacts
     * @param List<Contact> oContactMap
     * Triggered on After Update.
     */
    public static void updateRelatedRecords(List<Contact> nContacts, Map<Id, Contact> oContactMap) {
        final Integer NB_BUYER_CONTACTS = 5;
        Boolean deleteMode = nContacts == null;
        List<Contact> contacts = !deleteMode ? nContacts : oContactMap.values();
        List<Id> contactIds = new List<Id>();
        for (Contact item : contacts) {
            contactIDs.add(item.Id);
        }
        Set<Id> supplierIdSet = new Set<Id>();
        Map<Id, String> updatedContactEmailsMap = new Map<Id, String>();
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        Map<Id, List<Contact>> newContactsToInvoicesMap = new Map<Id, List<Contact>>();
        Set<Id> deletedContactsFromInvoiceIdSet = new Set<Id>();
        Map<Id, User> userMap = new Map<Id, User>();
        if(!contactIds.isEmpty()) {
            for (User user : [SELECT Id, ContactId, Name, MobilePhone, Title, Phone, FirstName, LastName, Email FROM User
                                WHERE ContactId IN :contactIds
                                AND IsActive = true]) {
                userMap.put(user.ContactId, user);
            }
        }
        for (Contact item : contacts) {
            if ( oContactMap != null && oContactMap.containsKey(item.Id) && userMap != null
            && hasFieldMismatch(item, oContactMap.get(item.Id), userMap.get(item.Id)) && userMap.get(item.Id) != null ) {
                System.debug('comtact run');
                User user = userMap.get(item.Id);
                system.debug(json.serialize(userMap));
                system.debug(json.serialize(item));
                user.LastName = item?.LastName;
                user.FirstName = item?.FirstName;
                user.Email = item?.Email;
                user.Title = item?.Title;
                user.Phone = item?.Phone;
                user.MobilePhone = item?.MobilePhone;
            }
            // update invoices emails
            if (item.Id != null && oContactMap != null && oContactMap.containsKey(item.Id) && item.Email != oContactMap.get(item.Id).Email) {
                updatedContactEmailsMap.put(item.Id, item.Email);
            }
            // update invoices contacts and emails
            if (item.Type__c == 'Generic mailbox' && item.Supplier__c != null) {
                if((oContactMap == null && item.IsInvoiceRecipient__c == true)
                    || (oContactMap != null && oContactMap.containsKey(item.Id)
                    && item.IsInvoiceRecipient__c == true && item.IsInvoiceRecipient__c != oContactMap.get(item.Id).IsInvoiceRecipient__c))
                {
                    supplierIdSet.add(item.Supplier__c);
                    if (!newContactsToInvoicesMap.containsKey(item.Supplier__c)) newContactsToInvoicesMap.put(item.Supplier__c, new List<Contact>());
                    newContactsToInvoicesMap.get(item.Supplier__c).add(item);
                }
                if((oContactMap != null && oContactMap.containsKey(item.Id)
                    && ((item.IsInvoiceRecipient__c == false && oContactMap.get(item.Id).IsInvoiceRecipient__c == true)
                    || (item.IsInvoiceRecipient__c == true && item.IsDeleted == false && oContactMap.get(item.Id).IsDeleted == true)))
                    || (deleteMode && item.IsInvoiceRecipient__c == true))
                {
                    supplierIdSet.add(item.Supplier__c);
                    deletedContactsFromInvoiceIdSet.add(item.Id);
                }
            }
        }
        Database.upsert(userMap.values(), false);
        if (!updatedContactEmailsMap.isEmpty() || !newContactsToInvoicesMap.isEmpty() || !deletedContactsFromInvoiceIdSet.isEmpty()) {
            List<Invoice__c> invoicesToUpdateAllContacts = new List<Invoice__c>();
            for (Invoice__c item : [SELECT Id, SupplierBuyer__c, Contract__c, Contract__r.Supplier_Nego_Scope__c,
                                    BuyerContact1__c, BuyerContact2__c, BuyerContact3__c, BuyerContact4__c, BuyerContact5__c,
                                    BuyerEmail1__c, BuyerEmail2__c, BuyerEmail3__c, BuyerEmail4__c, BuyerEmail5__c
                                    FROM Invoice__c
                                    WHERE Status__c IN ('inPreparation', 'Generated', 'Validated', 'ReadyToPrint')
                                    AND SupplierBuyer__c <> NULL
                                    AND (SupplierBuyer__c IN :supplierIdSet
                                         OR ((BuyerContact1__c <> NULL AND (BuyerContact1__c IN :updatedContactEmailsMap.keySet() OR BuyerContact1__c IN :deletedContactsFromInvoiceIdSet))
                                             OR (BuyerContact2__c <> NULL AND (BuyerContact2__c IN :updatedContactEmailsMap.keySet() OR BuyerContact2__c IN :deletedContactsFromInvoiceIdSet))
                                             OR (BuyerContact3__c <> NULL AND (BuyerContact3__c IN :updatedContactEmailsMap.keySet() OR BuyerContact3__c IN :deletedContactsFromInvoiceIdSet))
                                             OR (BuyerContact4__c <> NULL AND (BuyerContact4__c IN :updatedContactEmailsMap.keySet() OR BuyerContact4__c IN :deletedContactsFromInvoiceIdSet))
                                             OR (BuyerContact5__c <> NULL AND (BuyerContact5__c IN :updatedContactEmailsMap.keySet() OR BuyerContact5__c IN :deletedContactsFromInvoiceIdSet))))])
            {
                Boolean isUpdateAllContacts = newContactsToInvoicesMap.containsKey(item.SupplierBuyer__c) || deleteMode;
                for (Integer i = 1; i <= NB_BUYER_CONTACTS; i++) {
                    if (item.get('BuyerContact' + i + '__c') != null) {
                        Id contactId = (Id)item.get('BuyerContact' + i + '__c');
                        // Fixing emails
                        if (updatedContactEmailsMap.containsKey(contactId)) {
                            item.put('BuyerEmail' + i + '__c', updatedContactEmailsMap.get(contactId));
                        }
                        // delete contacts
                        if (deletedContactsFromInvoiceIdSet.contains(contactId)) {
                            item.put('BuyerContact' + i + '__c', null);
                            item.put('BuyerEmail' + i + '__c', null);
                            isUpdateAllContacts = true;
                        }
                    } else if (item.get('BuyerEmail' + i + '__c') != null) {
                        // case delete Contact
                        item.put('BuyerEmail' + i + '__c', null);
                    }
                }
                if(isUpdateAllContacts) {
                    invoicesToUpdateAllContacts.add(item);
                } else {
                    invoicesToUpdate.add(item);
                }
            }
            if(!invoicesToUpdateAllContacts.isEmpty()) {
                invoicesToUpdateAllContacts = InvoiceServices.fillContacts(invoicesToUpdateAllContacts);
                invoicesToUpdate.addAll(invoicesToUpdateAllContacts);
            }
            if (!invoicesToUpdate.isEmpty()) {
                update invoicesToUpdate;
            }
        }
    }
    
    private static Boolean hasFieldMismatch(SObject newContact, SObject oldContact, SObject user) {
        try {
            List<String> fields = new List<String>{
                'LastName','FirstName','Email',
                'Title','Phone','MobilePhone'
            };
            for ( String f : fields ) {
                Object newVal     = newContact?.get(f);
                Object oldVal     = oldContact?.get(f);
                Object userVal = user?.get(f);
                if ( newVal != oldVal
                && userVal != newVal ) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
}