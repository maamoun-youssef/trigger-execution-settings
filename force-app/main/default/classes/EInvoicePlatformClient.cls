public with sharing class EInvoicePlatformClient {
    @TestVisible
    private static final String DEFAULT_NAMED_CREDENTIAL = 'EInvoice_Platform';
    @TestVisible
    private static final String INVOICE_RESOURCE_PATH = '/invoices';
    @TestVisible
    private static String baseEndpointOverride;

    public class ClientResponse {
        public Boolean isSuccess;
        public Integer statusCode;
        public String message;
        public String platformReference;
        public String requestPayload;
        public String responseBody;
    }

    public static ClientResponse postInvoice(
        Invoice__c invoiceRecord,
        List<InvoiceDetail__c> invoiceDetails,
        EInvoiceRestService.RequestWrapper requestPayload
    ) {
        HttpRequest httpRequest = buildRequest(invoiceRecord, invoiceDetails, requestPayload);
        Http httpClient = new Http();
        HttpResponse httpResponse = httpClient.send(httpRequest);
        ClientResponse clientResponse = parseResponse(httpResponse);
        clientResponse.requestPayload = httpRequest.getBody();
        clientResponse.responseBody = httpResponse != null ? httpResponse.getBody() : null;
        return clientResponse;
    }

    @TestVisible
    static HttpRequest buildRequest(
        Invoice__c invoiceRecord,
        List<InvoiceDetail__c> invoiceDetails,
        EInvoiceRestService.RequestWrapper requestPayload
    ) {
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint(resolveBaseEndpoint() + INVOICE_RESOURCE_PATH);
        httpRequest.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('invoiceId', invoiceRecord != null ? invoiceRecord.Id : null);
        payload.put('invoiceNumber', invoiceRecord != null ? (String) invoiceRecord.get('Name') : null);
        payload.put('externalReference', requestPayload != null ? requestPayload.externalReference : null);
        payload.put('invoice', invoiceRecord != null ? invoiceRecord.getPopulatedFieldsAsMap() : null);

        List<Map<String, Object>> detailList = new List<Map<String, Object>>();
        if (invoiceDetails != null) {
            for (InvoiceDetail__c detailRecord : invoiceDetails) {
                detailList.add(detailRecord.getPopulatedFieldsAsMap());
            }
        }
        payload.put('invoiceDetails', detailList);

        if (requestPayload != null) {
            if (!String.isBlank(requestPayload.ublContent)) {
                payload.put('ublFile', buildFilePayload(
                    requestPayload.ublFileName,
                    requestPayload.ublMimeType,
                    requestPayload.ublContent
                ));
            }

            if (!String.isBlank(requestPayload.reportContent)) {
                payload.put('reportFile', buildFilePayload(
                    requestPayload.reportFileName,
                    requestPayload.reportMimeType,
                    requestPayload.reportContent
                ));
            }

            payload.put('metadata', requestPayload.additionalMetadata);
        }

        httpRequest.setBody(JSON.serialize(payload));
        return httpRequest;
    }

    private static Map<String, Object> buildFilePayload(String fileName, String mimeType, String base64Content) {
        Map<String, Object> filePayload = new Map<String, Object>();
        filePayload.put('fileName', fileName);
        filePayload.put('mimeType', mimeType);
        filePayload.put('content', base64Content);
        return filePayload;
    }

    @TestVisible
    static ClientResponse parseResponse(HttpResponse httpResponse) {
        ClientResponse result = new ClientResponse();
        if (httpResponse == null) {
            result.isSuccess = false;
            result.statusCode = 500;
            result.message = 'No response received from e-invoicing platform.';
            return result;
        }

        result.statusCode = httpResponse.getStatusCode();
        Boolean isSuccess = httpResponse.getStatusCode() >= 200 && httpResponse.getStatusCode() < 300;
        result.isSuccess = isSuccess;

        String responseBody = httpResponse.getBody();
        if (String.isBlank(responseBody)) {
            result.message = isSuccess
                ? 'Invoice successfully transmitted to e-invoicing platform.'
                : httpResponse.getStatus();
            return result;
        }

        Map<String, Object> bodyMap;
        try {
            bodyMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        } catch (Exception ex) {
            result.message = isSuccess ? responseBody : httpResponse.getStatus();
            return result;
        }

        if (bodyMap != null) {
            Object referenceValue = bodyMap.get('reference');
            if (referenceValue != null) {
                result.platformReference = String.valueOf(referenceValue);
            }

            Object messageValue = bodyMap.get('message');
            if (messageValue != null) {
                result.message = String.valueOf(messageValue);
            }

            if (result.message == null && isSuccess) {
                result.message = 'Invoice successfully transmitted to e-invoicing platform.';
            } else if (result.message == null && !isSuccess) {
                result.message = responseBody;
            }
        }

        if (result.message == null) {
            result.message = isSuccess ? responseBody : httpResponse.getStatus();
        }

        return result;
    }

    @TestVisible
    public static void setBaseEndpointForTest(String endpoint) {
        baseEndpointOverride = endpoint;
    }

    private static String resolveBaseEndpoint() {
        if (baseEndpointOverride != null) {
            return baseEndpointOverride;
        }

        String namedCredentialApiName = EInvoiceConfigurationService.getEffectiveNamedCredential();
        if (String.isBlank(namedCredentialApiName)) {
            namedCredentialApiName = DEFAULT_NAMED_CREDENTIAL;
        }
        return 'callout:' + namedCredentialApiName;
    }
}