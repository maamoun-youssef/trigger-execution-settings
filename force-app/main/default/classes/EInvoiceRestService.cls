@RestResource(urlMapping='/eInvoicing/v1/*')
global with sharing class EInvoiceRestService {
    global class RequestWrapper {
        public Id invoiceId;
        public String ublFileName;
        public String ublMimeType;
        public String ublContent;
        public String reportFileName;
        public String reportMimeType;
        public String reportContent;
        public String externalReference;
        public Map<String, Object> additionalMetadata;
    }

    global class ResponseWrapper {
        public String status;
        public String message;
        public String platformReference;
    }

    private class ProcessingException extends Exception {
        public Integer statusCode;
        private String customMessage;

        public ProcessingException(Integer statusCode, String messageText) {
            this.statusCode = statusCode;
            this.customMessage = messageText;
        }

        public override String getMessage() {
            return customMessage;
        }
    }

    @HttpPost
    global static ResponseWrapper submitInvoice() {
        return handleSubmission(null);
    }

    @TestVisible
    static ResponseWrapper submitInvoice(RequestWrapper requestPayload) {
        return handleSubmission(requestPayload);
    }

    private static ResponseWrapper handleSubmission(RequestWrapper requestPayload) {
        ResponseWrapper responseWrapper = new ResponseWrapper();

        RestResponse restResponse = RestContext.response;
        if (restResponse == null) {
            restResponse = new RestResponse();
            RestContext.response = restResponse;
        }
        restResponse.addHeader('Cache-Control', 'no-store, no-cache, must-revalidate');

        Invoice__c invoiceRecord;
        RequestWrapper payload;
        EInvoicePlatformClient.ClientResponse platformResponse;

        try {
            payload = coerceRequest(requestPayload);
            validateRequest(payload);

            invoiceRecord = [
                SELECT Id, Name, CreatedDate, LastModifiedDate
                FROM Invoice__c
                WHERE Id = :payload.invoiceId
                LIMIT 1
            ];

            List<InvoiceDetail__c> invoiceDetails = [
                SELECT Id, Name, CreatedDate, LastModifiedDate
                FROM InvoiceDetail__c
                WHERE Invoice__c = :invoiceRecord.Id
            ];

            platformResponse =
                EInvoicePlatformClient.postInvoice(invoiceRecord, invoiceDetails, payload);

            responseWrapper.status = platformResponse.isSuccess ? 'SUCCESS' : 'ERROR';
            responseWrapper.message = platformResponse.message;
            responseWrapper.platformReference = platformResponse.platformReference;

            restResponse.statusCode = platformResponse.statusCode != null
                ? platformResponse.statusCode
                : (platformResponse.isSuccess ? 200 : 500);

            EInvoiceTransmissionService.logTransmission(invoiceRecord, payload, platformResponse);
        } catch (ProcessingException pe) {
            responseWrapper.status = 'ERROR';
            responseWrapper.message = pe.getMessage();
            restResponse.statusCode = pe.statusCode != null ? pe.statusCode : 400;
            if (invoiceRecord != null) {
                EInvoiceTransmissionService.logFailure(invoiceRecord, payload, restResponse.statusCode, pe.getMessage());
            }
        } catch (QueryException qe) {
            responseWrapper.status = 'ERROR';
            responseWrapper.message = 'Invoice not found';
            restResponse.statusCode = 404;
        } catch (Exception ex) {
            responseWrapper.status = 'ERROR';
            responseWrapper.message = 'An unexpected error occurred while processing the invoice payload.';
            restResponse.statusCode = 500;
            System.debug(LoggingLevel.ERROR, 'EInvoiceRestService unexpected error: ' + ex.getMessage());
            if (invoiceRecord != null) {
                EInvoiceTransmissionService.logFailure(invoiceRecord, payload, restResponse.statusCode, ex.getMessage());
            }
        }

        return responseWrapper;
    }

    private static RequestWrapper coerceRequest(RequestWrapper input) {
        if (input != null) {
            return input;
        }

        RestRequest restRequest = RestContext.request;
        if (restRequest == null || restRequest.requestBody == null) {
            throw new ProcessingException(400, 'The request body is required.');
        }

        try {
            return (RequestWrapper) JSON.deserialize(restRequest.requestBody.toString(), RequestWrapper.class);
        } catch (Exception ex) {
            throw new ProcessingException(400, 'The request body could not be parsed. Ensure it is valid JSON.');
        }
    }

    private static void validateRequest(RequestWrapper payload) {
        if (payload.invoiceId == null) {
            throw new ProcessingException(400, 'invoiceId is required.');
        }

        if (String.isBlank(payload.ublContent)) {
            throw new ProcessingException(400, 'ublContent is required and must be Base64 encoded.');
        }

        if (!String.isBlank(payload.ublContent)) {
            try {
                EncodingUtil.base64Decode(payload.ublContent);
            } catch (Exception ex) {
                throw new ProcessingException(400, 'ublContent must be a valid Base64 encoded string.');
            }
        }

        if (!String.isBlank(payload.reportContent)) {
            try {
                EncodingUtil.base64Decode(payload.reportContent);
            } catch (Exception ex) {
                throw new ProcessingException(400, 'reportContent must be a valid Base64 encoded string.');
            }
        }
    }
}