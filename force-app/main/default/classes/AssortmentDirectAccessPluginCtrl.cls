/*
 * @author ULiT
 * @date 15-05-2024
 * @description controller class for the LWC assortmentDirectAccessPluginLWC
 */
public with sharing class AssortmentDirectAccessPluginCtrl {
    private static final Map<String, Integer> RECORD_TYPE_ORDER = new Map<String, Integer>{
        'Negotiation' => 0,
        'Simulation' => 1,
        'Target' => 2
    };

    @AuraEnabled(cacheable=false)
    public static String initData() {
        try {
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            List<String> staticFields = new List<String> {
                'RecordType.name',
                'RecordType.DeveloperName',
                SObjectType.Assortment__c.fields.OnTop__c.Name,
                SObjectType.Assortment__c.fields.IsBreakingScenario__c.Name,
                SObjectType.Assortment__c.fields.Version__c.Name,
                SObjectType.Assortment__c.fields.Year__c.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(Assortment__c.SObjectType.getDescribe().getName(), '', String.join(staticFields, ', '), assortSettings.assortmentDirectAccessPluginGrid) ;
            return JSON.serialize(new MainWrapper(gridSettingsManager));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getCause());
            System.debug(' >>> ' + e.getLineNumber());
            System.debug(' >>> ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + '-' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String getAssortments(String gridSettingsManagerSerialized, Integer pageSize, Integer pageNumber, String assortmentFilter, String sortField) {
        system.debug('assortmentFilter is ' + assortmentFilter);
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManagerSerialized, GridSettingsManager.class);
        FilterWrapper filter = String.isNotBlank(assortmentFilter) ? (FilterWrapper) JSON.deserialize(assortmentFilter, FilterWrapper.class) : new FilterWrapper();
        List<String> conditions = new List<String>();
        if (filter.Year != null) {
            conditions.add('Year__c IN (' + filter.Year + ')');
        }
        if (String.isNotBlank(filter.buTarget)) {
            conditions.add('BusinessUnitTarget__c = \'' + filter.buTarget + '\'');
        }
        if (String.isNotBlank(filter.buSource)) {
            conditions.add('BusinessUnitSource__c = \'' + filter.buSource + '\'');
        }
        if (String.isNotBlank(filter.hierarchy)) {
            List<String> orConditions = new List<String>();
            orConditions.add('Hierarchy__c = \'' + filter.hierarchy + '\'');
            orConditions.add('Hierarchy__r.HierarchyParent__c  = \'' + filter.hierarchy + '\'');
            orConditions.add('Hierarchy__r.HierarchyParent__r.HierarchyParent__c  = \'' + filter.hierarchy + '\'');
            orConditions.add('Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + filter.hierarchy + '\'');
            orConditions.add('Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + filter.hierarchy + '\'');
            conditions.add('(' + String.join(orConditions, ' OR ') + ')');
        }
        if (filter.recordTypes != null && !filter.recordTypes.isEmpty()) {
            conditions.add('RecordTypeId IN (' + String.join(filter.recordTypes, ', ') + ')');
        }
        String effectiveSortField = String.isBlank(sortField) ? 'Year__c ASC, BusinessUnitTarget__r.Name ASC, Hierarchy__r.Name ASC, Version__c ASC' : sortField;
        String query = gridSettingsManager.buildQuery(null, conditions, effectiveSortField);
        System.debug('query is ' + query);
        ApexPages.StandardSetController assormtentStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        assormtentStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
        assormtentStdSetCtrl.setPageNumber(pageNumber);
        List<Assortment__c> assortmentsList = new List<Assortment__c>((List<Assortment__c>) assormtentStdSetCtrl.getRecords());
        // for (SObject sob : assormtentStdSetCtrl.getRecords()) {
        //     assortmentsList.add((Assortment__c) sob);
        // }
        if (String.isBlank(sortField)) {
            assortmentsList.sort(new AssortmentComparator());
        }
        AssortmentWrapper assortmentResult = new AssortmentWrapper(assortmentsList, assormtentStdSetCtrl.getResultSize());
        return JSON.serialize(assortmentResult);
    }

    private class AssortmentComparator implements System.Comparator<SObject> {
        public Integer compare(SObject a, SObject b) {
            Assortment__c first  = (Assortment__c) a;
            Assortment__c second = (Assortment__c) b;
            Decimal firstYear  = first.Year__c;
            Decimal secondYear = second.Year__c;
            if (firstYear != secondYear) {
                if (firstYear == null)  return 1;
                if (secondYear == null) return -1;
                return firstYear < secondYear ? -1 : 1;
            }
            String firstRT  = first.RecordType  != null ? first.RecordType.DeveloperName  : null;
            String secondRT = second.RecordType != null ? second.RecordType.DeveloperName : null;
            Integer firstOrder  = RECORD_TYPE_ORDER.containsKey(firstRT)  ? RECORD_TYPE_ORDER.get(firstRT)  : 999;
            Integer secondOrder = RECORD_TYPE_ORDER.containsKey(secondRT) ? RECORD_TYPE_ORDER.get(secondRT) : 999;
            if (firstOrder == secondOrder) return 0;
            return firstOrder < secondOrder ? -1 : 1;
        }
    }

    @AuraEnabled
    public static String sendEmail(String emailTo, String Name, String emailCc, String emailBcc, String emailSubject, String emailBody, String excelBlob, String recordId, String assortmentName) {
        // Parse email addresses
        String[] toList = getEmailAddresses(emailTo);
        String[] ccList = getEmailAddresses(emailCc);
        String[] bccList = getEmailAddresses(emailBcc);

        // Decode The Excel
        Blob contentBody = EncodingUtil.base64Decode(excelBlob);
        // ... Excel generation logic ...

        // Create the email attachment
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setBody(contentBody);
        emailAttachment.setFileName(Name + '.xlsx');
        emailAttachment.setContentType('application/vnd.ms-excel');
        emailAttachment.setInline(false);

        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toList);
        system.debug('ccList '+JSON.serialize(ccList));
        system.debug('ccList.size() is '+ccList.size());
        system.debug('ccList.size() is '+(ccList.size() != 0));
        system.debug('ccList.size() is '+(ccList.size() > 0));
        if(ccList.size() != 0){
            system.debug('hello');
            email.setCcAddresses(ccList);
        }
        if(bccList.size() != 0){
            email.setBccAddresses(bccList);
        }
        system.debug('toList is '+JSON.serialize(toList));
        system.debug('toList is '+emailTo);
        // email.setCcAddresses(ccList);
        // email.setBccAddresses(bccList);
        email.setSubject(emailSubject);
        email.setHtmlBody(emailBody);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });
        String descriptionText = 'Email\nto :' + String.join(toList, ';') + '\n';
        descriptionText += 'cc :' + String.join(ccList, ';') + '\n';
        descriptionText += 'bcc :' + String.join(bccList, ';') + '\n';
        descriptionText += 'subject :' + emailSubject + '\n';
        descriptionText += 'body :' + emailBody + '\n';
        Attachment attachmentExcel = new Attachment(ParentId = recordId, Name = Name + '_'+ system.now() + '.xls',
        ContentType = 'application/vnd.ms-excel', Body = contentBody,
        Description = descriptionText);
        Database.insert(attachmentExcel);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            return 'Email sent successfully.';
        } catch (Exception e) {
            return 'Error sending email: ' + e.getMessage();
        }
    }
    
    private static String[] getEmailAddresses(String emails) {
        // Split the emails string by semicolon and return as a list
        if(emails == '' || emails == null){
            return new String[]{};
        }else{
            return emails.split(';');
        }
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get;set;}
        public Map<String, Id> ASRecordTypes {get;set;}
        public String prefix {get; set;}
        
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
            this.ASRecordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SobjectType);
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    
    public class AssortmentWrapper {
        public List<Assortment__c> assortments {get;set;}
        public Integer numberOfRecords {get;set;}
        public AssortmentWrapper (List<Assortment__c> assortments, Integer numberOfRecords) {
            this.assortments = assortments;
            this.numberOfRecords = numberOfRecords;
        }
    }
    
    public class FilterWrapper {
        public String year {get;set;}
        public String buTarget {get;set;}
        public String buSource {get;set;}
        public String hierarchy {get;set;}
        public List<String> recordTypes {get;set;}
        
        public FilterWrapper () {
            this.year = null;
            this.buTarget = null;
            this.buSource = null;
            this.hierarchy = null;
            this.recordTypes = null;
        }
        
        public FilterWrapper (String year, String buTarget, String buSource, String hierarchy, List<String> recordTypes) {
            this.year = year;
            this.buTarget = buTarget;
            this.buSource = buSource;
            this.hierarchy = hierarchy;
            this.recordTypes = recordTypes;
        }
    }
}