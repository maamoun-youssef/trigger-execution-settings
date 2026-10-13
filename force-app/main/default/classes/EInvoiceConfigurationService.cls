public with sharing class EInvoiceConfigurationService {
    public class ConfigDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String namedCredentialDeveloperName;
        @AuraEnabled public String defaultUblMimeType;
        @AuraEnabled public String defaultUblFileName;
        @AuraEnabled public String defaultReportMimeType;
        @AuraEnabled public String defaultReportFileName;
        @AuraEnabled public String defaultMetadataJson;
        @AuraEnabled public String defaultExternalReferencePrefix;
    }

    private static EInvoice_Config__c cachedConfig;

    @AuraEnabled(cacheable=true)
    public static ConfigDTO fetchConfig() {
        return toDto(getOrCreateConfigRecord(false));
    }

    @AuraEnabled
    public static ConfigDTO saveConfig(ConfigDTO input) {
        if (input == null) {
            throw new AuraHandledException('Configuration payload is required.');
        }

        EInvoice_Config__c configRecord = getOrCreateConfigRecord(true);
        if (configRecord.Id == null) {
            configRecord.Name = String.isBlank(input.name) ? 'Default' : input.name;
        } else if (!String.isBlank(input.name)) {
            configRecord.Name = input.name;
        }

        configRecord.NamedCredential__c = normalize(input.namedCredentialDeveloperName);
        configRecord.DefaultUblMimeType__c = normalize(input.defaultUblMimeType);
        configRecord.DefaultUblFileName__c = normalize(input.defaultUblFileName);
        configRecord.DefaultReportMimeType__c = normalize(input.defaultReportMimeType);
        configRecord.DefaultReportFileName__c = normalize(input.defaultReportFileName);
        configRecord.DefaultMetadata__c = String.isBlank(input.defaultMetadataJson)
            ? null
            : input.defaultMetadataJson.trim();
        configRecord.DefaultExternalReferencePrefix__c = normalize(input.defaultExternalReferencePrefix);

        if (configRecord.Id == null) {
            insert configRecord;
        } else {
            update configRecord;
        }

        cachedConfig = null;
        return toDto(getOrCreateConfigRecord(false));
    }

    public static String getEffectiveNamedCredential() {
        EInvoice_Config__c configRecord = getOrCreateConfigRecord(false);
        if (configRecord != null && !String.isBlank(configRecord.NamedCredential__c)) {
            return configRecord.NamedCredential__c.trim();
        }
        return null;
    }

    public static ConfigDTO getCachedConfig() {
        return toDto(getOrCreateConfigRecord(false));
    }

    @TestVisible
    public static void clearCache() {
        cachedConfig = null;
    }

    private static EInvoice_Config__c getOrCreateConfigRecord(Boolean forUpdate) {
        if (cachedConfig == null) {
            List<EInvoice_Config__c> records = [
                SELECT Id,
                    Name,
                    NamedCredential__c,
                    DefaultUblMimeType__c,
                    DefaultUblFileName__c,
                    DefaultReportMimeType__c,
                    DefaultReportFileName__c,
                    DefaultMetadata__c,
                    DefaultExternalReferencePrefix__c
                FROM EInvoice_Config__c
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];

            if (!records.isEmpty()) {
                cachedConfig = records[0];
            }
        }

        if (cachedConfig == null && forUpdate) {
            cachedConfig = new EInvoice_Config__c();
        }

        return cachedConfig;
    }

    private static ConfigDTO toDto(EInvoice_Config__c record) {
        ConfigDTO dto = new ConfigDTO();
        if (record == null) {
            dto.name = 'Default';
            dto.defaultUblMimeType = 'application/xml';
            dto.defaultReportMimeType = 'application/pdf';
            return dto;
        }

        dto.id = record.Id;
        dto.name = record.Name;
        dto.namedCredentialDeveloperName = record.NamedCredential__c;
        dto.defaultUblMimeType = defaultIfBlank(record.DefaultUblMimeType__c, 'application/xml');
        dto.defaultUblFileName = record.DefaultUblFileName__c;
        dto.defaultReportMimeType = defaultIfBlank(record.DefaultReportMimeType__c, 'application/pdf');
        dto.defaultReportFileName = record.DefaultReportFileName__c;
        dto.defaultMetadataJson = record.DefaultMetadata__c;
        dto.defaultExternalReferencePrefix = record.DefaultExternalReferencePrefix__c;
        return dto;
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? null : value.trim();
    }

    private static String defaultIfBlank(String value, String defaultValue) {
        return String.isBlank(value) ? defaultValue : value;
    }
}