/**
 * @author ULiT
 * @date 02/12/2024
 * @description Apex Handler to handle Trg_Invoice
 * */
public with sharing class Trg_Invoice_Handler {
    public static Map<String, Id> invoiceRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Invoice__c.SObjectType);
    
    public static InvoiceSettings invoiceSettingsRecord {
        get {
            if (invoiceSettingsRecord == null) {
                invoiceSettingsRecord = InvoiceSettings.loadInvoiceSettings();
            }
            return invoiceSettingsRecord;
        }
        set;
    }
    
    public static void OnBeforeInsertOrUpdate(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        populateFields(nInvoices, oInvoicesMap);
    }
    
    public static void OnBeforeInsert(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        populateContactFields(nInvoices, oInvoicesMap);
    }
    
    public static void OnBeforeUpdate(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        validateConstraintOnUpdateInvoice(nInvoices, oInvoicesMap);
        generateInvoiceNumber(nInvoices, oInvoicesMap);
        validateConstraintOnDeleteInvoice(nInvoices, oInvoicesMap);
    }
    
    public static void OnBeforeDelete(Map<Id, Invoice__c> oInvoicesMap) {
        validateConstraintOnDeleteInvoice(null, oInvoicesMap);
        unpublishInvoiceFiles(oInvoicesMap.keySet());
    }
    
    /*
     * @description called in case Trigger.isBefore && Trigger.isDelete
     */
    public static void OnAfterDelete(Map<Id, Invoice__c> oInvoicesMap) {
        cleanUpRelatedList();
    }
    
    public static void OnAfterUpdate(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        updateRelatedRecords(nInvoices, oInvoicesMap);
    }
    
    private static void validateConstraintOnUpdateInvoice(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        InvoiceSettings.InvoiceValidationRules invoiceValidationRules = invoiceSettingsRecord.invoiceValidationRules;
        List<String> statusToCheck = new List<String>{'Validated', 'NotValidated'};
        if(invoiceValidationRules != null) {
            for(Invoice__c item : nInvoices) {
                String oldStatus = oInvoicesMap != null && oInvoicesMap.containsKey(item.Id) ? oInvoicesMap.get(item.Id).Status__c : null;
                if(statusToCheck.contains(item.Status__c)
                    || (statusToCheck.contains(oldStatus)
                    || (oInvoicesMap != null && oInvoicesMap.containsKey(item.Id) && item.TotalAmountwVAT__c != oInvoicesMap.get(item.Id)?.TotalAmountwVAT__c)))
                {
                    Boolean intervalStatus = invoiceValidationRules.intervalStatus;
                    Double min = invoiceValidationRules.intervalStart;
                    Double max = invoiceValidationRules.intervalEnd;
                    if(intervalStatus != null && min != null && max != null && item.TotalAmountwVAT__c != null) {
                        if (item.Status__c == 'Validated' && intervalStatus && (item.TotalAmountwVAT__c >= min && item.TotalAmountwVAT__c <= max)) {
                            item.Status__c = 'NotValidated';
                            //item.addError(NegoptimLabels.getCustomLabel('MSG_InvoiceSettings_Validation_Error', 'Document not validated due to configuration.'));
                        } else if(item.Status__c == 'NotValidated' && intervalStatus && !(item.TotalAmountwVAT__c >= min && item.TotalAmountwVAT__c <= max)) {
                            item.Status__c = 'Validated';
                        }
                    }
                }
            }
        }
    }
    
    private static void validateConstraintOnDeleteInvoice(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        Map<String, String> invoiceDeletionRulesAccDoc = invoiceSettingsRecord.invoiceDeletionRulesAccDoc;
        Map<String, List<String>> invoiceDeletionRulesAccDocMap = new Map<String, List<String>>();
        if(invoiceDeletionRulesAccDoc != null && !invoiceDeletionRulesAccDoc.isEmpty()) {
            for(String accDoc : invoiceDeletionRulesAccDoc.keySet()) {
                List<String> invoiceStatusList = invoiceDeletionRulesAccDoc.get(accDoc).Split(',');
                invoiceDeletionRulesAccDocMap.put(accDoc, invoiceStatusList);
            }
        }
        Boolean isDelete = nInvoices == null;
        List<Invoice__c> invoiceListToValidate = nInvoices == null ? oInvoicesMap.values() : nInvoices;
        for (Invoice__c item : invoiceListToValidate) {
            String oldStatus = oInvoicesMap != null && oInvoicesMap.containsKey(item.Id) ? oInvoicesMap.get(item.Id).Status__c : item.Status__c;
            if((isDelete
                || (oldStatus != 'Deleted' && item.Status__c == 'Deleted'))
                && item.Status__c != null
                && item.AccDoc__c != null
                && (!invoiceDeletionRulesAccDocMap.containsKey(item.AccDoc__c)
                || !invoiceDeletionRulesAccDocMap.get(item.AccDoc__c).contains(oldStatus)))
            {
                item.addError(NegoptimLabels.getCustomLabel('MSG_InvoiceSettings_Delete_Error', ''));
            }
        }
    }
    
    public static void populateFields(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        final Integer NB_BUYER_CONTACTS = 5;
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> invoiceIdToUpdateGLSet = new Set<Id>();
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        Map<Id, Contract_Discount__c> discMaps = new Map<Id, Contract_Discount__c>();
        Set<Id> glIdSet = new Set<Id>();
        Map<String, GlobalLocation__c> glMap = new Map<String, GlobalLocation__c>();
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        // contact
        Map<String, Integer> contactsChangedMap = new Map<String, Integer>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Invoice__c> invoicesToUpdateContact = new Map<Id, Invoice__c>();
        Map<Id, Invoice__c> invoicesToUpdateDueDates = new Map<Id, Invoice__c>();
        //loop on new list
        for (Invoice__c item : nInvoices) {
            if (item.Id == null
                || item.GlobalLocationSeller__c != oInvoicesMap.get(item.Id).GlobalLocationSeller__c
                || item.GlobalLocationPayee__c != oInvoicesMap.get(item.Id).GlobalLocationPayee__c
                || item.GlobalLocationBuyer__c != oInvoicesMap.get(item.Id).GlobalLocationBuyer__c
                || item.GlobalLocationDelivery__c != oInvoicesMap.get(item.Id).GlobalLocationDelivery__c
                || item.Contract__c != oInvoicesMap.get(item.Id).Contract__c
                || item.SupplierSeller__c != oInvoicesMap.get(item.Id).SupplierSeller__c)
            {
                if(item.GlobalLocationSeller__c != null && (item.Id == null || item.GlobalLocationSeller__c != oInvoicesMap.get(item.Id).GlobalLocationSeller__c)) {
                    glIdSet.add(item.GlobalLocationSeller__c);
                }
                if(item.GlobalLocationPayee__c != null && (item.Id == null || item.GlobalLocationPayee__c != oInvoicesMap.get(item.Id).GlobalLocationPayee__c)) {
                    glIdSet.add(item.GlobalLocationPayee__c);
                }
                if(item.GlobalLocationBuyer__c != null && (item.Id == null || item.GlobalLocationBuyer__c != oInvoicesMap.get(item.Id).GlobalLocationBuyer__c)) {
                    glIdSet.add(item.GlobalLocationBuyer__c);
                }
                if(item.GlobalLocationDelivery__c != null && (item.Id == null || item.GlobalLocationDelivery__c != oInvoicesMap.get(item.Id).GlobalLocationDelivery__c)) {
                    glIdSet.add(item.GlobalLocationDelivery__c);
                }
                if(item.SupplierSeller__c != null) {
                    supplierIdSet.add(item.SupplierSeller__c);
                }
                if(item.Contract__c != null) {
                    contractsMap.put(item.Contract__c, null);
                }
                if(item.Id != null) {
                    invoiceIdToUpdateGLSet.add(item.Id);
                }
                invoicesToUpdate.add(item);
            }
            if (item.Id != null) {
                for (Integer i = 1; i <= NB_BUYER_CONTACTS; i++) {
                    Id buyerContactId = item.get('BuyerContact' + i + '__c') != null ? (Id) item.get('BuyerContact' + i + '__c') : null;
                    Id oldBuyerContactId = oInvoicesMap.get(item.Id).get('BuyerContact' + i + '__c') != null ? (Id) oInvoicesMap.get(item.Id).get('BuyerContact' + i + '__c') : null;
                    if (buyerContactId != oldBuyerContactId) {
                        if (buyerContactId == null) {
                            item.put('BuyerEmail' + i + '__c', null);
                        } else {
                            String key = item.Id + '' +  buyerContactId;
                            contactsChangedMap.put(key, i);
                            contactIds.add(buyerContactId);
                            invoicesToUpdateContact.put(item.Id, item);
                        }
                    }
                }
            }
            // update DueDate__c
            if (item.Id != null && oInvoicesMap != null && oInvoicesMap.containsKey(item.Id)
                && item.Status__c == 'Printed' && item.Status__c != oInvoicesMap.get(item.Id).Status__c)
            {
                invoicesToUpdateDueDates.put(item.Id, item);
            }
            // update Status__c on update PaidAmountwVAT__c
            if(item.Id != null && oInvoicesMap != null && oInvoicesMap.containsKey(item.Id)
                && (item.PaidAmountwVAT__c != oInvoicesMap.get(item.Id).PaidAmountwVAT__c)
                && (item.Status__c == 'Printed' || item.Status__c == 'Paid' || item.Status__c == 'PartiallyPaid'))
            {
                // SET Invoice__c.Status = "Paid" IF (ABS(Invoice__c.PaidAmountwVAT__c) >= ABS(Invoice__c.TotalAmountwVAT__c))
                // SET Invoice__c.Status = "PartiallyPaid" IF (0 < ABS(Invoice__c.PaidAmountwVAT__c) < ABS(Invoice__c.TotalAmountwVAT__c))
                // SET Invoice__c.Status = "Printed" IF (ABS(Invoice__c.PaidAmountwVAT__c)=0)
                Decimal totalAmountwVAT = item.TotalAmountwVAT__c != null ? Math.abs(item.TotalAmountwVAT__c) : null;
                Decimal paidAmountwVAT = item.PaidAmountwVAT__c != null ? Math.abs(item.PaidAmountwVAT__c) : null;
                if(totalAmountwVAT != null && paidAmountwVAT != null) {
                    if(paidAmountwVAT >= totalAmountwVAT) {
                        item.Status__c = 'Paid';
                    } else if (paidAmountwVAT > 0 && paidAmountwVAT < totalAmountwVAT) {
                        item.Status__c = 'PartiallyPaid';
                    } else if(paidAmountwVAT == 0) {
                        item.Status__c = 'Printed';
                    }
                }
            }
        }
        if (!contractsMap.isEmpty()) {
            contractsMap = new Map<Id, Contract__c> ([SELECT Id, BusinessUnitContract__c, BusinessUnitContract__r.SetInvoiceSeller__c, Supplier__c
                                                      FROM Contract__c
                                                      WHERE Id IN :contractsMap.keySet()]);
        }
        if (!invoiceIdToUpdateGLSet.isEmpty() || !invoicesToUpdateDueDates.isEmpty()) {
            Map<Id, Contract_Discount__c> invoiceToDiscountsMap = new Map<Id, Contract_Discount__c>();
            for (InvoiceDetail__c item : [SELECT Id, Invoice__c, DISCLineD__c, DISCLineD__r.Payment_Condition__c, DISCLineD__r.Payment_Days__c,
                                          DISCLineD__r.GlobalLocationSeller__c, DISCLineD__r.GlobalLocationPayee__c,
                                          DISCLineD__r.Product_Scope__r.GlobalLocationAccounting__c,
                                          DISCLineD__r.Product_Scope__r.GlobalLocationAdministration__c,
                                          DISCLineD__r.Product_Scope__r.GlobalLocationDelivery__c
                                          FROM InvoiceDetail__c
                                          WHERE (Invoice__c IN :invoiceIdToUpdateGLSet OR Invoice__c IN :invoicesToUpdateDueDates.keySet())
                                          AND DISCLineD__c <> NULL])
            {
                if(invoiceIdToUpdateGLSet.contains(item.Invoice__c)) {
                    discMaps.put(item.Invoice__c, item.DISCLineD__r);
                    if(item.DISCLineD__r.Product_Scope__r.GlobalLocationAccounting__c != null) {
                        glIdSet.add(item.DISCLineD__r.Product_Scope__r.GlobalLocationAccounting__c);
                    }
                    if(item.DISCLineD__r.Product_Scope__r.GlobalLocationAdministration__c != null) {
                        glIdSet.add(item.DISCLineD__r.Product_Scope__r.GlobalLocationAdministration__c);
                    }
                    if(item.DISCLineD__r.Product_Scope__r.GlobalLocationDelivery__c != null) {
                        glIdSet.add(item.DISCLineD__r.Product_Scope__r.GlobalLocationDelivery__c);
                    }
                }
                if(invoicesToUpdateDueDates.containsKey(item.Invoice__c)) {
                    invoiceToDiscountsMap.put(item.Invoice__c, new Contract_Discount__c(Id = item.DISCLineD__c, Payment_Condition__c = item.DISCLineD__r.Payment_Condition__c,
                    Payment_Days__c = item.DISCLineD__r.Payment_Days__c));
                }
            }
            // case update DueDate__c
            if (!invoicesToUpdateDueDates.isEmpty()) {
                for (Invoice__c item : invoicesToUpdateDueDates.values()) {
                    if(invoiceToDiscountsMap.containsKey(item.Id)) {
                        Contract_Discount__c discount = invoiceToDiscountsMap.get(item.Id);
                        item.DueDate__c = (discount.Payment_Days__c != null && discount.Payment_Condition__c != null && item.PrintDate__c != null ?
                            NegoptimHelper.getDueDate(item.PrintDate__c, Integer.valueOf(discount.Payment_Days__c), discount.Payment_Condition__c) : null);
                    }
                }
            }
        }
        if (!glIdSet.isEmpty() || !supplierIdSet.isEmpty()) {
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
                        glMap.put(gl.Supplier__c + 'Administrative', gl);
                    }
                }
            }
        }
        if (!contactIds.isEmpty()) {
            List<Contact> contacts = [SELECT Id, Email
                                      FROM Contact
                                      WHERE Id IN :contactIds];
            for (Invoice__c invoice : invoicesToUpdateContact.values()) {
                for (Contact contact : contacts) {
                    String key = invoice.Id + '' + contact.Id;
                    if (contactsChangedMap.containsKey(key)) {
                        Integer index = contactsChangedMap.get(key);
                        invoice.put('BuyerEmail' + index + '__c', contact.Email);
                    }
                }
            }
        }
        Map<String, Boolean> updatedGLMap = new Map<String, Boolean>();
        for (Invoice__c item : invoicesToUpdate) {
            updatedGLMap = new Map<String, Boolean> {
                SObjectType.Invoice__c.fields.GlobalLocationSeller__c.Name => false,
                SObjectType.Invoice__c.fields.GlobalLocationPayee__c.Name => false,
                SObjectType.Invoice__c.fields.GlobalLocationBuyer__c.Name => false,
                SObjectType.Invoice__c.fields.GlobalLocationDelivery__c.Name => false
            };
            Contract__c contract = contractsMap.get(item.Contract__c);
            Contract_Discount__c disc = discMaps.get(item.Id);
            if (item.Contract__c != null
                && (item.Id == null || (item.Contract__c != oInvoicesMap.get(item.Id).Contract__c
                || item.SupplierSeller__c != oInvoicesMap.get(item.Id).SupplierSeller__c)))
            {
                InvoiceServices.setInvoiceGL(item, contract, disc, glMap);
            }
            if(item.Id == null || item.GlobalLocationSeller__c != oInvoicesMap.get(item.Id).GlobalLocationSeller__c) {
                updatedGLMap.put(SObjectType.Invoice__c.fields.GlobalLocationSeller__c.Name, true);
            }
            if(item.Id == null || item.GlobalLocationPayee__c != oInvoicesMap.get(item.Id).GlobalLocationPayee__c) {
                updatedGLMap.put(SObjectType.Invoice__c.fields.GlobalLocationPayee__c.Name, true);
            }
            if(item.Id == null || item.GlobalLocationBuyer__c != oInvoicesMap.get(item.Id).GlobalLocationBuyer__c) {
                updatedGLMap.put(SObjectType.Invoice__c.fields.GlobalLocationBuyer__c.Name, true);
            }
            if(item.Id == null || item.GlobalLocationDelivery__c != oInvoicesMap.get(item.Id).GlobalLocationDelivery__c) {
                updatedGLMap.put(SObjectType.Invoice__c.fields.GlobalLocationDelivery__c.Name, true);
            }
            InvoiceServices.setInvoiceGLCoordinates(item, contract, disc, glMap, updatedGLMap);
        }
    }
    
    public static void populateContactFields(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        for (Invoice__c item : nInvoices) {
            if (item.SupplierBuyer__c != null
                && (item.BuyerContact1__c == null || item.BuyerContact2__c == null || item.BuyerContact3__c == null || item.BuyerContact4__c == null || item.BuyerContact5__c == null
                || item.BuyerEmail1__c == null || item.BuyerEmail2__c == null || item.BuyerEmail3__c == null || item.BuyerEmail4__c == null || item.BuyerEmail5__c == null))
            {
                invoicesToUpdate.add(item);
            }
        }
        if(!invoicesToUpdate.isEmpty()) {
            InvoiceServices.fillContacts(invoicesToUpdate);
        }
    }
    
    public static void generateInvoiceNumber(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        List<Invoice__c> printedInvoices = new List<Invoice__c>();
        for (Invoice__c invoice : nInvoices) {
            if (invoice.Status__c == 'Printed' && invoice.InvNumber__c == null) {
                printedInvoices.add(invoice);
            }
        }
        if (!printedInvoices.isEmpty()) {
            // Generate invoice number
            Map<String, Integer> invoicesNumberPrefixMap = new Map<String, Integer>();
            // formula
            FormulaEval.FormulaInstance instance;
            if (String.isNotBlank(invoiceSettingsRecord.numberPrefixFormula)) {
                instance = Formula.builder()
                    .withReturnType(FormulaEval.FormulaReturnType.String)
                    .withType(Invoice__c.SObjectType)
                    .withFormula(invoiceSettingsRecord.numberPrefixFormula)
                    .build();
            }
            // Push distinct prefixes in a map.
            for (Invoice__c invoice : printedInvoices) {
                if (instance != null) {
                    String key = (String) instance.evaluate(invoice);
                    invoice.InvNumberPrefix__c = key;
                    if (!invoicesNumberPrefixMap.containsKey(key)) {
                        invoicesNumberPrefixMap.put(key != null ? key : 'NOPREFIX', 1);
                    }
                } else {
                    invoicesNumberPrefixMap.put('NOPREFIX', 1);
                }
            }
            // Loop over prefixes to find the correponding max counter.
            for (String prefix : invoicesNumberPrefixMap.keySet()) {
                List<Invoice__c> invoices = new List<Invoice__c>();
                String query = 'SELECT InvNumber__c, t_Autonum__c';
                query += ' FROM Invoice__c';
                query += ' WHERE t_Autonum__c <> null';
                if (prefix != 'NOPREFIX') {
                    query += ' AND InvNumberPrefix__c = \'' + String.escapeSingleQuotes(prefix) + '\'';
                } else {
                    query += ' AND InvNumberPrefix__c = NULL';
                }
                query += ' ORDER BY t_Autonum__c DESC';
                query += ' LIMIT 1';
                String[] invoiceFields = new String[] {
                    SObjectType.Invoice__c.Fields.InvNumber__c.Name,
                    SObjectType.Invoice__c.Fields.t_Autonum__c.Name,
                    SObjectType.Invoice__c.Fields.InvNumberPrefix__c.Name
                };
                if (NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceFields)) {
                    invoices = Database.query(query);
                }
                if (!invoices.isEmpty()) {
                    Integer max = Integer.valueOf(String.valueOf(invoices.get(0).t_Autonum__c));
                    invoicesNumberPrefixMap.put(prefix, max + 1);
                }
            }
            for (Invoice__c invoice : printedInvoices) {
                // Set an auto invoice number based on the max for each prefix.
                String prefix = invoice.InvNumberPrefix__c != null ? invoice.InvNumberPrefix__c : '';
                Integer count = invoicesNumberPrefixMap.get(invoice.InvNumberPrefix__c != null ? invoice.InvNumberPrefix__c : 'NOPREFIX');
                Integer autonumLength = invoiceSettingsRecord.autonumLength != null ? invoiceSettingsRecord.autonumLength : 6;
                invoice.InvNumber__c = prefix + String.valueof(count).leftPad(autonumLength, '0');
                invoice.t_Autonum__c = count;
                // Increment the counter and update related value in the map.
                count++;
                invoicesNumberPrefixMap.put(invoice.InvNumberPrefix__c, count);
            }
        }
    }
    
    /*
     * @description calculate iunvoice values
     */
    private static void updateRelatedRecords(List<Invoice__c> nInvoices, Map<Id, Invoice__c> oInvoicesMap) {
        Set<String> updatedInvoiceStatuses = new Set<String> { 'Generated', 'NotValidated', 'Validated', 'ReadyToPrint' };
        Set<String> deletedInvoiceStatuses = new Set<String> { 'Generated', 'NotValidated', 'Validated', 'ReadyToPrint', 'Printed', 'Paid', 'PartiallyPaid', 'Gained', 'Loosed', 'Cancelled' };
        Set<Id> invoiceIds = new Set<Id>();
        Set<Id> invoiceCreditNoteToPrintIds = new Set<Id>();
        Set<Id> invoicesWithDeleteChanged = new Set<Id>();
        Set<Id> commercialPlanInvoicesIdSet = new Set<Id>();
        Set<Id> invoicesToUnpublishFiles = new Set<Id>();
        Set<Id> discountIds = new Set<Id>();
        List<InvoiceDetail__c> invoiceDetailsToUpdate = new List<InvoiceDetail__c>();
        for (Invoice__c invoice : nInvoices) {
            // 2. Already_Invoiced_Edited__c update management
            if ((invoice.Status__c == 'Printed' || invoice.Status__c == 'Validated' || invoice.Status__c == 'NotValidated')
                && oInvoicesMap.get(invoice.Id).Status__c != null
                && invoice.Status__c != oInvoicesMap.get(invoice.Id).Status__c
                && updatedInvoiceStatuses.contains(oInvoicesMap.get(invoice.Id).Status__c))
            {
                invoiceIds.add(invoice.Id);
            }
            // 2.1 Deletion management
            if (invoice.Status__c == 'Deleted'
                && oInvoicesMap.get(invoice.Id).Status__c != null
                && deletedInvoiceStatuses.contains(oInvoicesMap.get(invoice.Id).Status__c))
            {
                invoiceIds.add(invoice.Id);
            }
            // Deleted/Undeleted
            if (invoice.Status__c != oInvoicesMap.get(invoice.Id).Status__c
                && (invoice.Status__c == 'Deleted' || oInvoicesMap.get(invoice.Id).Status__c == 'Deleted'))
            {
                Boolean isDeleteRelatedRecords = invoice.Status__c == 'Deleted';
                invoicesWithDeleteChanged.add(invoice.Id);
            }
            // After delete or cancel, unpublish files
            if ((invoice.Status__c == 'Deleted' || invoice.Status__c == 'Cancelled')
                && oInvoicesMap.get(invoice.Id).Status__c != 'Deleted'
                && oInvoicesMap.get(invoice.Id).Status__c != 'Cancelled')
            {
                invoicesToUnpublishFiles.add(invoice.Id);
            }
            // 2. Already_Invoiced_Edited__c update management
            if (invoice.Status__c == 'Printed'
                && invoice.RecordTypeId == invoiceRTIds.get('TargetToSource')
                && invoice.AccDoc__c != null
                && (invoice.AccDoc__c == 'CreditNote' || invoice.AccDoc__c == 'CNCancelRequest')
                && oInvoicesMap.get(invoice.Id).Status__c != null
                && invoice.Status__c != oInvoicesMap.get(invoice.Id).Status__c
                && updatedInvoiceStatuses.contains(oInvoicesMap.get(invoice.Id).Status__c))
            {
                invoiceCreditNoteToPrintIds.add(invoice.Id);
            }
            // Cancelled/Deleted Invoice
            if ((invoice.Status__c == 'Cancelled' || invoice.Status__c == 'Deleted')
                && oInvoicesMap.get(invoice.Id).Status__c != 'Cancelled'
                && oInvoicesMap.get(invoice.Id).Status__c != 'Deleted')
            {
                commercialPlanInvoicesIdSet.add(invoice.Id);
                invoiceIds.add(invoice.Id);
            }
        }
        
        // case after delete or cancel, unpublish files
        if (!invoicesToUnpublishFiles.isEmpty()) {
            unpublishInvoiceFiles(invoicesToUnpublishFiles);
        }
        
        // case Deleted/Undeleted
        if (!invoicesWithDeleteChanged.isEmpty()) {
            InvoiceServices.updateDeletedRelatedRecords(invoicesWithDeleteChanged);
        }
        // case update invoices amounts
        if (!invoiceIds.isEmpty()) {
            /*for (InvoiceDetail__c item : [SELECT Id, DISCLineD__c
                                          FROM InvoiceDetail__c
                                          WHERE Invoice__c IN :invoiceIds])
            {
                if (item.DISCLineD__c != null) {
                    // re-aggreagte the amounts
                    discountIds.add(item.DISCLineD__c);
                }
            }*/
            List<InvoiceDetail__c> invoiceDetailsForCommercialPlanList = new List<InvoiceDetail__c>();
            for (InvoiceDetail__c item : [SELECT Id, DetailAmount__c, DetailVATRate__c, DISCLineD__r.YTDFact__c, DISCLineD__r.Already_Invoiced_Edited__c, DISCLineD__r.YTDRestToInvoice__c,
                                          Invoice__r.IsUpdatedFromYTD__c, DISCLineD__r.Status__c, Invoice__r.Status__c, Invoice__c, CommercialPlan__c
                                          FROM InvoiceDetail__c
                                          WHERE Invoice__c IN :invoiceIds
                                          /*AND DISCLineD__c <> NULL
                                          AND Invoice__r.IsUpdatedFromYTD__c = true
                                          AND DISCLineD__r.Status__c <> 'Deleted'
                                          AND Invoice__r.Status__c IN ('Validated', 'NotValidated')*/])
            {
                if (item.DISCLineD__c != null) {
                    // re-aggreagte the amounts
                    discountIds.add(item.DISCLineD__c);
                    if(item.Invoice__r.IsUpdatedFromYTD__c && item.DISCLineD__r.Status__c != 'Deleted' && (item.Invoice__r.Status__c == 'Validated' || item.Invoice__r.Status__c == 'NotValidated')) {
                        //Decimal detailAmount = item.DISCLineD__r.YTDRestToInvoice__c;
                        Decimal detailAmount = (item.DISCLineD__r.YTDFact__c != null ? item.DISCLineD__r.YTDFact__c : 0) - (item.DISCLineD__r.Already_Invoiced_Edited__c != null ? item.DISCLineD__r.Already_Invoiced_Edited__c : 0);
                        detailAmount = detailAmount.setScale(2, System.RoundingMode.HALF_UP);
                        item.DetailAmount__c = detailAmount;
                        item.DetailNetPrice__c = detailAmount;
                        item.DetailGrossPrice__c = detailAmount;
                        invoiceDetailsToUpdate.add(item);
                    }
                    if(item.CommercialPlan__c != null && commercialPlanInvoicesIdSet.contains(item.Invoice__c)) {
                        invoiceDetailsForCommercialPlanList.add(item);
                    }
                }
            }
            if (!invoiceDetailsToUpdate.isEmpty()) {
                Database.update(invoiceDetailsToUpdate, false);
            }
            if (!discountIds.isEmpty()) {
                Map<Id, Contract_Discount__c> discountsToUpdate = InvoiceServices.calculateCDAlreadyInvoiced(discountIds);
                if (!discountsToUpdate.isEmpty()) {
                    Database.update(discountsToUpdate.values(), false);
                }
            }
            if (!System.isBatch() && !System.isFuture() && !invoiceCreditNoteToPrintIds.isEmpty()) {
                Map<String, Object> paramsMap = new Map<String, Object>{
                    'startedFrom' => Trg_Invoice_Handler.class.getName(),
                    'invoiceIds' => invoiceCreditNoteToPrintIds,
                    'paymentMode' => InvoiceServices.PaymentMode.CreditNotePayment
                };
                NegoptimBatch.executeBatch('GeneratePaymentsBatch', paramsMap, 100);
            }
            // case Deleted/Canceled Invoice__c
            if (!invoiceDetailsForCommercialPlanList.isEmpty()) {
                InvoiceServices.updateCommercialPlanRelatedRecords(invoiceDetailsForCommercialPlanList);
            }
        }
    }
    
    /**
     * Unpublish files from portal when invoice is Deleted or Cancelled
     * On beofre delete
     * */
    private static void unpublishInvoiceFiles(Set<Id> invoiceIds) {
    if (invoiceIds == null || invoiceIds.isEmpty()) return;
    List<FileDirectory__c> filesToUpdate = [SELECT Id, IsPortalPublished__c
                                            FROM FileDirectory__c 
                                            WHERE Invoice__c IN :invoiceIds 
                                            AND IsPortalPublished__c = TRUE];
    if (!filesToUpdate.isEmpty()) {
        for (FileDirectory__c file : filesToUpdate) {
            file.IsPortalPublished__c = false;
        }
        Database.update(filesToUpdate, false);
    }
}
    
    /**
     * Delete Invoice details line and Invoices head
     * On before delete
     * */
    private static void cleanUpRelatedList() {
        if (NegoptimHelper.checkDeletibility(InvoiceDetail__c.SObjectType)) {
            delete [SELECT Id FROM InvoiceDetail__c WHERE Invoice__c = NULL];
        }
        if (NegoptimHelper.checkDeletibility(InvoiceLink__c.SObjectType)) {
            delete [SELECT Id FROM InvoiceLink__c WHERE Invoice__c = NULL OR InvoiceLinked__c = NULL];
        }
    }
}