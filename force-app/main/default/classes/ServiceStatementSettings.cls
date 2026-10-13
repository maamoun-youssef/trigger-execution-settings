/**
 * @author ULiT
 * @date 03/09/2025
 * Advanced Settings class for Sales Terms Statements (serviceStatementSettings)
 **/
global with sharing class ServiceStatementSettings extends SettingsManager implements MethodUtils.MethodChecker {
    //General
    public String processName { get; set; }
    //Section 1
    public String generationMode { get; set; } // 'Automatic' | 'Manual'
    public Integer autoPublishDay { get; set; } // required if mode = Automatic
    public Integer autoPublishMonth { get; set; } // required if mode = Automatic
    public Boolean isNSLevel { get; set; } // false => Supplier lvl, true => Negoscope lvl
    public Boolean allowSelfSubmit { get; set; } // default = true
    public String descriptionFR { get; set; } // Text(5000)
    public String descriptionEN { get; set; } // Text(5000)
    public String creationFlow { get; set; } // Text
    
    // Section 2
    public Integer annualClosingDay { get; set; } // 1..31
    public Integer annualClosingMonth { get; set; } // 1..12
    public String submissionFlow { get; set; } // Text
    public String reminderRule { get; set; } // Text(255)
    public List<RequestedDocumentWrapper> requestedDocuments { get; set; } // JSON field for List<RequestedDocumentWrapper>
    
    //Section 3
    public String reminderFlow { get; set; } // Text
    public String validationFlow { get; set; } // Text
    public Boolean addFrameworkAgreementTemplate { get; set; } // Boolean
    public Boolean addPurchasingTerms { get; set; } // Boolean

    // --- Defaults per functional spec (other fields default to null) ---
    public ServiceStatementSettings() {
        this.generationMode = 'Automatic';
        this.isNSLevel = false;
        this.allowSelfSubmit = true;
        this.addFrameworkAgreementTemplate = true;
        this.addPurchasingTerms = true;
    }
    
    global static String loadServiceStatementSettingsSerialized(String processName) {
        return JSON.serialize(loadServiceStatementSettings(processName));
    }

    // --- Static loader (fetches the single ServiceStatementSettings record) ---
    public static ServiceStatementSettings loadServiceStatementSettings(String processName) {
        return (ServiceStatementSettings) SettingsManager.loadCustomMetadataSettings(ServiceStatementSettings__mdt.SObjectType, processName, ServiceStatementSettings.class.getName());
    }

    public ServiceStatementSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ServiceStatementSettings__mdt serviceStatementSettings = (ServiceStatementSettings__mdt) metadataRecord;
            this.processName = String.isNotBlank(serviceStatementSettings.ProcessName__c) ? serviceStatementSettings.ProcessName__c : 'ServiceStatementSettings';
            //Section 1
            this.generationMode = String.isNotBlank(serviceStatementSettings.GenerationMode__c) ? serviceStatementSettings.GenerationMode__c : 'Automatic';
            this.autoPublishDay   = (serviceStatementSettings.AutoPublishDay__c   == null) ? null : Integer.valueOf(serviceStatementSettings.AutoPublishDay__c);
            this.autoPublishMonth = (serviceStatementSettings.AutoPublishMonth__c == null) ? null : Integer.valueOf(serviceStatementSettings.AutoPublishMonth__c);
            // toggles
            this.isNSLevel = serviceStatementSettings.IsNSLevel__c == null ? false : serviceStatementSettings.IsNSLevel__c;
            this.allowSelfSubmit = serviceStatementSettings.AllowSelfSubmit__c == null ? true : serviceStatementSettings.AllowSelfSubmit__c;
            // descriptions
            this.descriptionFR = serviceStatementSettings.DescriptionFR__c;
            this.descriptionEN = serviceStatementSettings.DescriptionEN__c;
            this.creationFlow = serviceStatementSettings.CreationFlow__c;
            // annual closing
            this.annualClosingDay   = (serviceStatementSettings.AnnualClosingDay__c   == null) ? null : Integer.valueOf(serviceStatementSettings.AnnualClosingDay__c);
            this.annualClosingMonth = (serviceStatementSettings.AnnualClosingMonth__c == null) ? null : Integer.valueOf(serviceStatementSettings.AnnualClosingMonth__c);
            // reminder / requested doc / flow
            this.reminderFlow = serviceStatementSettings.ReminderFlow__c;
            this.submissionFlow = serviceStatementSettings.SubmissionFlow__c;
            this.reminderRule = serviceStatementSettings.ReminderRule__c;
            this.requestedDocuments = String.isNotBlank(serviceStatementSettings.RequestedDocuments__c)
                                    ? (List<RequestedDocumentWrapper>) JSON.deserialize(serviceStatementSettings.RequestedDocuments__c, List<RequestedDocumentWrapper>.class)
                                    : new List<RequestedDocumentWrapper>();
            // Section 3
            this.validationFlow = serviceStatementSettings.ValidationFlow__c;
            this.addFrameworkAgreementTemplate = serviceStatementSettings.AddFrameworkAgreementTemplate__c == null ? false : serviceStatementSettings.AddFrameworkAgreementTemplate__c;
            // this.addPurchasingTerms = serviceStatementSettings.AllowSelfSubmit__c == null ? true : serviceStatementSettings.AllowSelfSubmit__c;
            this.addPurchasingTerms = serviceStatementSettings.AddPurchasingTerms__c == null ? true : serviceStatementSettings.AddPurchasingTerms__c;
        }
        return this;
    }

    public String save(ServiceStatementSettings serviceStatementSettings) {
        if (serviceStatementSettings == null) return null;
        // Ensure we always have a consistent process name for both the record id and the ProcessName__c field
        String safeName = String.isBlank(serviceStatementSettings.processName) ? 'ServiceStatementSettings' : serviceStatementSettings.processName;
        String sanitized = safeName.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_');
        Map<String, Object> fieldsValueMap = new Map<String, Object>{
            SObjectType.ServiceStatementSettings__mdt.fields.ProcessName__c.Name => safeName, //serviceStatementSettings.processName,
            SObjectType.ServiceStatementSettings__mdt.fields.GenerationMode__c.Name => serviceStatementSettings.generationMode,
            SObjectType.ServiceStatementSettings__mdt.fields.AutoPublishDay__c.Name => serviceStatementSettings.autoPublishDay,
            SObjectType.ServiceStatementSettings__mdt.fields.AutoPublishMonth__c.Name => serviceStatementSettings.autoPublishMonth,
            SObjectType.ServiceStatementSettings__mdt.fields.IsNSLevel__c.Name => serviceStatementSettings.isNSLevel,
            SObjectType.ServiceStatementSettings__mdt.fields.AllowSelfSubmit__c.Name => serviceStatementSettings.allowSelfSubmit,
            SObjectType.ServiceStatementSettings__mdt.fields.DescriptionFR__c.Name => serviceStatementSettings.descriptionFR,
            SObjectType.ServiceStatementSettings__mdt.fields.DescriptionEN__c.Name => serviceStatementSettings.descriptionEN,
            SObjectType.ServiceStatementSettings__mdt.fields.CreationFlow__c.Name => serviceStatementSettings.creationFlow,
            SObjectType.ServiceStatementSettings__mdt.fields.AnnualClosingDay__c.Name => serviceStatementSettings.annualClosingDay,
            SObjectType.ServiceStatementSettings__mdt.fields.AnnualClosingMonth__c.Name => serviceStatementSettings.annualClosingMonth,
            SObjectType.ServiceStatementSettings__mdt.fields.ReminderRule__c.Name => serviceStatementSettings.reminderRule,
            SObjectType.ServiceStatementSettings__mdt.fields.RequestedDocuments__c.Name => JSON.serialize(serviceStatementSettings.requestedDocuments == null ? new List<RequestedDocumentWrapper>() : serviceStatementSettings.requestedDocuments),
            SObjectType.ServiceStatementSettings__mdt.fields.SubmissionFlow__c.Name => serviceStatementSettings.submissionFlow,
            SObjectType.ServiceStatementSettings__mdt.fields.ReminderFlow__c.Name => serviceStatementSettings.reminderFlow,
            SObjectType.ServiceStatementSettings__mdt.fields.ValidationFlow__c.Name => serviceStatementSettings.validationFlow,
            SObjectType.ServiceStatementSettings__mdt.fields.AddFrameworkAgreementTemplate__c.Name => serviceStatementSettings.addFrameworkAgreementTemplate,
            SObjectType.ServiceStatementSettings__mdt.fields.AddPurchasingTerms__c.Name => serviceStatementSettings.addPurchasingTerms
        };
        return saveCustomMetadataSettings(ServiceStatementSettings__mdt.SObjectType, sanitized, fieldsValueMap);
    }
    
    public Boolean hasMethod(String methodName) {
        if (methodName == 'load') {
            return true;
        }
        return false;
    }
    
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }
    
    public class RequestedDocumentWrapper {
        public String documentName;
        public String documentType;
        public String documentSubType;
        public Boolean isMandatory;
        
        public RequestedDocumentWrapper() {
        }
    }
}