public with sharing class EInvoiceTransmissionService {
    public class TransmissionResult {
        public Id transmissionId;
    }

    public static TransmissionResult logTransmission(
        Invoice__c invoiceRecord,
        EInvoiceRestService.RequestWrapper requestPayload,
        EInvoicePlatformClient.ClientResponse platformResponse
    ) {
        if (invoiceRecord == null || platformResponse == null) {
            return null;
        }

        EInvoice_Transmission__c record = new EInvoice_Transmission__c();
        record.Invoice__c = invoiceRecord.Id;
        record.Status__c = platformResponse.isSuccess ? 'SUCCESS' : 'ERROR';
        record.Message__c = platformResponse.message;
        record.PlatformReference__c = platformResponse.platformReference;
        record.StatusCode__c = platformResponse.statusCode;
        record.RequestPayload__c = platformResponse.requestPayload;
        record.ResponseBody__c = platformResponse.responseBody;
        record.SentAt__c = System.now();
        record.ExternalReference__c = requestPayload != null ? requestPayload.externalReference : null;

        insert record;

        TransmissionResult result = new TransmissionResult();
        result.transmissionId = record.Id;
        return result;
    }

    public static TransmissionResult logFailure(
        Invoice__c invoiceRecord,
        EInvoiceRestService.RequestWrapper requestPayload,
        Integer statusCode,
        String message
    ) {
        if (invoiceRecord == null) {
            return null;
        }

        EInvoice_Transmission__c record = new EInvoice_Transmission__c();
        record.Invoice__c = invoiceRecord.Id;
        record.Status__c = 'ERROR';
        record.Message__c = message;
        record.StatusCode__c = statusCode;
        record.SentAt__c = System.now();
        record.ExternalReference__c = requestPayload != null ? requestPayload.externalReference : null;

        insert record;

        TransmissionResult result = new TransmissionResult();
        result.transmissionId = record.Id;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<EInvoice_Transmission__c> fetchTransmissions(Id invoiceId, Integer limitSize) {
        Integer safeLimit = limitSize == null || limitSize <= 0 || limitSize > 200 ? 50 : limitSize;

        if (invoiceId == null) {
            return [
                SELECT Id, Name, Status__c, Message__c, PlatformReference__c, StatusCode__c, SentAt__c, ExternalReference__c
                FROM EInvoice_Transmission__c
                ORDER BY SentAt__c DESC, CreatedDate DESC
                LIMIT :safeLimit
            ];
        }

        return [
            SELECT Id, Name, Status__c, Message__c, PlatformReference__c, StatusCode__c, SentAt__c, ExternalReference__c
            FROM EInvoice_Transmission__c
            WHERE Invoice__c = :invoiceId
            ORDER BY SentAt__c DESC, CreatedDate DESC
            LIMIT :safeLimit
        ];
    }
}