public with sharing class Trg_ContentDocumentLink_Handler {
    public static void OnAfterInsert(List<ContentDocumentLink> nContentDocumentLinks) {
        createFileDirectories(nContentDocumentLinks);
    }

    /**
     * @description
     * @param List<ContentDocumentLink> nContentDocumentLinks
     * @param Map<Id, ContentDocumentLink> oContentDocumentLinksMap
     */
    public static void createFileDirectories(List<ContentDocumentLink> nContentDocumentLinks) {
        Id recordTypeId = NegoptimHelper.getObjectRecordTypeMapIds(FileDirectory__c.SObjectType).get('Financial');
        // key = invoice Id, value = cdl id
        Map<Id, Id> invoiceCdlMap = new Map<Id, Id>();
        Map<String, FileDirectory__c> fdirToInsertMap = new Map<String, FileDirectory__c>();
        for (ContentDocumentLink cdl : nContentDocumentLinks) {
            if (cdl.LinkedEntityId.getSObjectType() == Invoice__c.SObjectType) {
                invoiceCdlMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            } 
        }
        if (!invoiceCdlMap.isEmpty()) {
            Map<Id, String> dcTitleMap = new Map<Id, String>();
            for (ContentDocument cd : [SELECT Id, Title FROM ContentDocument WHERE Id IN :invoiceCdlMap.values()]) {
                dcTitleMap.put(cd.Id, cd.Title);
            }
            for (InvoiceDetail__c invDetail: [SELECT Id,Invoice__c, Invoice__r.Contract__c, Invoice__r.FiscalYear__c, Invoice__r.SupplierBuyer__c, DISCLineD__r.Product_Scope__c
                                              FROM InvoiceDetail__c
                                              WHERE Invoice__c IN :invoiceCdlMap.keySet()])
            {
                String key = invoiceCdlMap.get(invDetail.Invoice__c) + '-' + invDetail.Invoice__c;
                fdirToInsertMap.put(key, new FileDirectory__c (
                        DocumentName__c = dcTitleMap.containsKey(invoiceCdlMap.get(invDetail.Invoice__c)) ? dcTitleMap.get(invoiceCdlMap.get(invDetail.Invoice__c)) : null,
                        ReferenceYear__c = invDetail?.Invoice__r?.FiscalYear__c,
                        Supplier__c = invDetail?.Invoice__r?.SupplierBuyer__c,
                        RecordTypeId = recordTypeId,
                        ContentDocumentId__c = invoiceCdlMap.get(invDetail.Invoice__c),
                        SubType__c = 'Invoice',
                        Invoice__c = invDetail.Invoice__c,
                        Contract__c = invDetail?.Invoice__r?.Contract__c,
                        Negoscope__c = invDetail?.DISCLineD__r?.Product_Scope__c
                    )
                );
            }
            insert fdirToInsertMap.values();
        }
    }
}