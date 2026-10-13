public with sharing class EInvoiceConsoleController {
    public class SendInvoiceRequest {
        @AuraEnabled public Id invoiceId;
        @AuraEnabled public String ublXml;
        @AuraEnabled public String ublFileName;
        @AuraEnabled public String ublMimeType;
        @AuraEnabled public String externalReference;
        @AuraEnabled public String metadataJson;
        @AuraEnabled public String reportContentBase64;
        @AuraEnabled public String reportFileName;
        @AuraEnabled public String reportMimeType;
    }

    public class SendInvoiceResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String platformReference;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public Id transmissionId;
    }

    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> fetchInvoices(Integer limitSize, String searchTerm) {
        Integer safeLimit = limitSize == null || limitSize <= 0 || limitSize > 200 ? 50 : limitSize;
        if (String.isBlank(searchTerm)) {
            return [
                SELECT Id, Name, CreatedDate, LastModifiedDate
                FROM Invoice__c
                ORDER BY CreatedDate DESC
                LIMIT :safeLimit
            ];
        }

        String pattern = '%' + searchTerm.trim() + '%';
        return [
            SELECT Id, Name, CreatedDate, LastModifiedDate
            FROM Invoice__c
            WHERE Name LIKE :pattern
            ORDER BY CreatedDate DESC
            LIMIT :safeLimit
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<InvoiceDetail__c> fetchInvoiceDetails(Id invoiceId) {
        if (invoiceId == null) {
            return new List<InvoiceDetail__c>();
        }
        return [
            SELECT Id, Name, CreatedDate, LastModifiedDate
            FROM InvoiceDetail__c
            WHERE Invoice__c = :invoiceId
            ORDER BY CreatedDate ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static String generateBasicUbl(Id invoiceId) {
        if (invoiceId == null) {
            throw new AuraHandledException('invoiceId is required.');
        }

        Invoice__c invoiceRecord = [
            SELECT Id, Name, CreatedDate, LastModifiedDate
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];

        List<InvoiceDetail__c> invoiceDetails = [
            SELECT Id, Name
            FROM InvoiceDetail__c
            WHERE Invoice__c = :invoiceId
            ORDER BY CreatedDate ASC
        ];

        return buildBasicUbl(invoiceRecord, invoiceDetails);
    }

    @AuraEnabled
    public static SendInvoiceResponse sendInvoice(SendInvoiceRequest request) {
        if (request == null || request.invoiceId == null) {
            throw new AuraHandledException('invoiceId is required.');
        }
        if (String.isBlank(request.ublXml)) {
            throw new AuraHandledException('UBL XML content is required.');
        }

        Invoice__c invoiceRecord = [
            SELECT Id, Name, CreatedDate, LastModifiedDate
            FROM Invoice__c
            WHERE Id = :request.invoiceId
            LIMIT 1
        ];

        List<InvoiceDetail__c> invoiceDetails = [
            SELECT Id, Name, CreatedDate, LastModifiedDate
            FROM InvoiceDetail__c
            WHERE Invoice__c = :invoiceRecord.Id
        ];

        EInvoiceConfigurationService.ConfigDTO config = EInvoiceConfigurationService.getCachedConfig();

        EInvoiceRestService.RequestWrapper wrapper = new EInvoiceRestService.RequestWrapper();
        wrapper.invoiceId = invoiceRecord.Id;
        wrapper.ublFileName = String.isBlank(request.ublFileName)
            ? resolveDefaultUblFileName(config, invoiceRecord)
            : request.ublFileName;
        wrapper.ublMimeType = String.isBlank(request.ublMimeType)
            ? config.defaultUblMimeType
            : request.ublMimeType;
        wrapper.ublContent = EncodingUtil.base64Encode(Blob.valueOf(request.ublXml));
        wrapper.externalReference = resolveExternalReference(config, request.externalReference, invoiceRecord);
        wrapper.reportFileName = String.isBlank(request.reportFileName)
            ? (config != null ? config.defaultReportFileName : null)
            : request.reportFileName;
        wrapper.reportMimeType = String.isBlank(request.reportMimeType)
            ? (config != null ? config.defaultReportMimeType : null)
            : request.reportMimeType;
        wrapper.reportContent = request.reportContentBase64;
        wrapper.additionalMetadata = resolveMetadata(config, request.metadataJson);

        EInvoicePlatformClient.ClientResponse platformResponse =
            EInvoicePlatformClient.postInvoice(invoiceRecord, invoiceDetails, wrapper);

        EInvoiceTransmissionService.TransmissionResult transmissionResult =
            EInvoiceTransmissionService.logTransmission(invoiceRecord, wrapper, platformResponse);

        SendInvoiceResponse response = new SendInvoiceResponse();
        response.status = platformResponse.isSuccess ? 'SUCCESS' : 'ERROR';
        response.message = platformResponse.message;
        response.platformReference = platformResponse.platformReference;
        response.statusCode = platformResponse.statusCode;
        response.transmissionId = transmissionResult != null ? transmissionResult.transmissionId : null;
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<EInvoice_Transmission__c> fetchTransmissions(Id invoiceId, Integer limitSize) {
        return EInvoiceTransmissionService.fetchTransmissions(invoiceId, limitSize);
    }

    @AuraEnabled(cacheable=true)
    public static EInvoiceConfigurationService.ConfigDTO getConfiguration() {
        return EInvoiceConfigurationService.fetchConfig();
    }

    @AuraEnabled
    public static EInvoiceConfigurationService.ConfigDTO saveConfiguration(EInvoiceConfigurationService.ConfigDTO input) {
        return EInvoiceConfigurationService.saveConfig(input);
    }

    private static Map<String, Object> resolveMetadata(
        EInvoiceConfigurationService.ConfigDTO config,
        String metadataJson
    ) {
        String payload = !String.isBlank(metadataJson)
            ? metadataJson
            : config != null ? config.defaultMetadataJson : null;

        if (String.isBlank(payload)) {
            return null;
        }

        try {
            Object parsed = JSON.deserializeUntyped(payload);
            return parsed instanceof Map<String, Object>
                ? (Map<String, Object>) parsed
                : null;
        } catch (Exception ex) {
            throw new AuraHandledException('Metadata JSON is invalid.');
        }
    }

    private static String resolveExternalReference(
        EInvoiceConfigurationService.ConfigDTO config,
        String explicitReference,
        Invoice__c invoiceRecord
    ) {
        if (!String.isBlank(explicitReference)) {
            return explicitReference;
        }

        String prefix = config != null ? config.defaultExternalReferencePrefix : null;
        if (String.isBlank(prefix)) {
            return invoiceRecord.Name;
        }

        return prefix + '-' + invoiceRecord.Name;
    }

    private static String resolveDefaultUblFileName(
        EInvoiceConfigurationService.ConfigDTO config,
        Invoice__c invoiceRecord
    ) {
        if (config != null && !String.isBlank(config.defaultUblFileName)) {
            return config.defaultUblFileName;
        }
        return invoiceRecord.Name + '.xml';
    }

    private static String buildBasicUbl(Invoice__c invoiceRecord, List<InvoiceDetail__c> invoiceDetails) {
        String currencyCode = resolveCurrencyCode(invoiceRecord);
        Date issueDate = invoiceRecord.CreatedDate != null
            ? invoiceRecord.CreatedDate.date()
            : Date.today();

        List<String> xmlLines = new List<String>();
        xmlLines.add('<?xml version="1.0" encoding="UTF-8"?>\n');
        xmlLines.add('<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"\n');
        xmlLines.add('         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"\n');
        xmlLines.add('         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">\n');
        xmlLines.add('    <cbc:CustomizationID>urn:cen.eu:en16931:2017</cbc:CustomizationID>\n');
        xmlLines.add('    <cbc:ProfileID>urn:fdc:peppol.eu:poacc:billing:3.0</cbc:ProfileID>\n');
        xmlLines.add('    <cbc:ID>' + escapeXml(invoiceRecord.Name) + '</cbc:ID>\n');
        xmlLines.add('    <cbc:IssueDate>' + issueDate.format() + '</cbc:IssueDate>\n');
        xmlLines.add('    <cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>\n');
        xmlLines.add('    <cbc:DocumentCurrencyCode>' + currencyCode + '</cbc:DocumentCurrencyCode>\n');
        xmlLines.add('    <cac:AccountingSupplierParty>\n');
        xmlLines.add('        <cac:Party>\n');
        xmlLines.add('            <cbc:EndpointID schemeID="FR:SIREN">000000000</cbc:EndpointID>\n');
        xmlLines.add('            <cac:PartyName>\n');
        xmlLines.add('                <cbc:Name>Supplier Name</cbc:Name>\n');
        xmlLines.add('            </cac:PartyName>\n');
        xmlLines.add('        </cac:Party>\n');
        xmlLines.add('    </cac:AccountingSupplierParty>\n');
        xmlLines.add('    <cac:AccountingCustomerParty>\n');
        xmlLines.add('        <cac:Party>\n');
        xmlLines.add('            <cbc:EndpointID schemeID="FR:SIREN">000000001</cbc:EndpointID>\n');
        xmlLines.add('            <cac:PartyName>\n');
        xmlLines.add('                <cbc:Name>Customer Name</cbc:Name>\n');
        xmlLines.add('            </cac:PartyName>\n');
        xmlLines.add('        </cac:Party>\n');
        xmlLines.add('    </cac:AccountingCustomerParty>\n');

        Integer lineNumber = 1;
        for (InvoiceDetail__c detail : invoiceDetails) {
            xmlLines.add('    <cac:InvoiceLine>\n');
            xmlLines.add('        <cbc:ID>' + lineNumber + '</cbc:ID>\n');
            xmlLines.add('        <cbc:InvoicedQuantity unitCode="EA">1</cbc:InvoicedQuantity>\n');
            xmlLines.add('        <cbc:LineExtensionAmount currencyID="' + currencyCode + '">0.00</cbc:LineExtensionAmount>\n');
            xmlLines.add('        <cac:Item>\n');
            xmlLines.add('            <cbc:Description>' + escapeXml(detail.Name) + '</cbc:Description>\n');
            xmlLines.add('        </cac:Item>\n');
            xmlLines.add('        <cac:Price>\n');
            xmlLines.add('            <cbc:PriceAmount currencyID="' + currencyCode + '">0.00</cbc:PriceAmount>\n');
            xmlLines.add('        </cac:Price>\n');
            xmlLines.add('    </cac:InvoiceLine>\n');
            lineNumber++;
        }

        xmlLines.add('    <cac:LegalMonetaryTotal>\n');
        xmlLines.add('        <cbc:LineExtensionAmount currencyID="' + currencyCode + '">0.00</cbc:LineExtensionAmount>\n');
        xmlLines.add('        <cbc:TaxExclusiveAmount currencyID="' + currencyCode + '">0.00</cbc:TaxExclusiveAmount>\n');
        xmlLines.add('        <cbc:TaxInclusiveAmount currencyID="' + currencyCode + '">0.00</cbc:TaxInclusiveAmount>\n');
        xmlLines.add('        <cbc:PayableAmount currencyID="' + currencyCode + '">0.00</cbc:PayableAmount>\n');
        xmlLines.add('    </cac:LegalMonetaryTotal>\n');
        xmlLines.add('</Invoice>\n');
        return String.join(xmlLines, '');
    }

    private static String escapeXml(String value) {
        if (value == null) {
            return '';
        }
        String escaped = value.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&apos;');
        return escaped;
    }

    private static String resolveCurrencyCode(Invoice__c invoiceRecord) {
        if (invoiceRecord == null) {
            return 'EUR';
        }

        try {
            Object currencyValue = invoiceRecord.get('CurrencyIsoCode');
            if (currencyValue instanceof String && !String.isBlank((String) currencyValue)) {
                return (String) currencyValue;
            }
        } catch (Exception ex) {
            // Field not present or inaccessible; fall back to default.
        }

        return 'EUR';
    }
}