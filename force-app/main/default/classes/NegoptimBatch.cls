/**
 * @author ULiT
 * @date feb-27-2018
 * @group Negoptim Support
 * @description Initiate an instance of this class in a batch to ease logging and sending emails of the batch's summary.
********************************************************************************************************************************************* */

global with sharing class NegoptimBatch {

    public final String BATCH_SUMMARY = 'Batch_Summary_Email_Template';
    public final String EMAIL_TEMPLATE_2 = 'Unavailable';
    public final String EMAIL_TEMPLATE_3 = 'Unavailable';
    public final String EMAIL_TEMPLATE_4 = 'Unavailable';

	/**
	 * @description The name of the batch where an instance of this class is initiated
	***************************************************************************************************************************************** */
    private String batchName;
	/**
	 * @description store Batch Metadata Settings.
	***************************************************************************************************************************************** */
    private Batch_Settings__mdt batchMetadata;
    /**
     * @description identifies where the batch started from, it could be another batch or a scheduler or other
	***************************************************************************************************************************************** */
    private String startedFrom = 'Undefined';
    /**
     * @description A map that holds the batch index as key and a set of error strings as value.
     * It is used to keep track of error messages per batch
	***************************************************************************************************************************************** */
    private Map<Integer, Set<String>> errorByBatchIndex;
    /**
     * @description a map take batch index as key and set of message as value.
     ************************************************************************************/
    private List<MessageWrapper> messages;
    /**
     * @description True counts of everything ever passed to logError()/logMessage(), independent of how much was actually kept in errorByBatchIndex/messages
	***************************************************************************************************************************************** */
    private Integer totalErrorsLogged = 0;
    private Integer capturedErrorCount = 0;
    private Integer totalMessagesLogged = 0;
    /**
     * @description 'Stateful' or 'Stateless'
	***************************************************************************************************************************************** */
    private BatchType bt;
    /**
     * @description The AsyncApexJob of the batch where an instance of this class is initiated
	***************************************************************************************************************************************** */
    private AsyncApexJob asyncApexJob;
    /**
     * @description A map to keep track of relevent information and input data helpful in debug. Example: the query
	***************************************************************************************************************************************** */
    private Map<String, Object> parameters;
    /**
     * @description succeed and failed log results
	***************************************************************************************************************************************** */
    public Datatable successLogResultsTable;
    public Datatable failedLogResultsTable;
    public String logResultsTableHeader;
    public String customEmailSubject;
    /**
     * @description The index of the current batch of the current apex job
	***************************************************************************************************************************************** */
    private Integer batchIndex = 0;
    /**
	 * @description A Boolean to check if notification is sent
	***************************************************************************************************************************************** */
    private Boolean IsNotificationSent = FALSE;

    /**
     * @description Used to keep track of the Log__c object to avoid inserting 2 logs for the same Job
	***************************************************************************************************************************************** */
	private Log__c log;
    /**
     * @description Set by NegoptimLog.mapToLog when the raw trace log was too long to fit in TraceLog__c and got replaced with a summary
	***************************************************************************************************************************************** */
    private String pendingFullTraceLog;
    /**
     * @description Set true when getWarningTraceLog()/getMessageTraceLog()'s heap safety guard cuts a loop short
     * happened, regardless of the resulting string's length.
	***************************************************************************************************************************************** */
    private Boolean traceLogTruncatedByHeapGuard = false;
    /**
     * @description Hard, deterministic cap on how many warning/message entries getWarningTraceLog()/getMessageTraceLog() will ever render in a single call, regardless of heap/CPU percentage checks.
	***************************************************************************************************************************************** */
    private static final Integer MAX_TRACE_LOG_ENTRIES = 5000;
    /**
     * @param batchName The name of the batch where an instance of this class is being initiated
     * @param batchType The batch type of the batch where an instance of this class is being initiated (Stateful or Stateless)
     * @example NegoptimBatch negoptimBatch = new NegoptimBatch('Mass Distribution','Stateful');
	***************************************************************************************************************************************** */
    global NegoptimBatch(String batchName, BatchType batchType, String startedFrom) {
        this.batchName = batchName;
        this.bt = batchType;
        this.startedFrom = startedFrom;
        this.errorByBatchIndex = new Map<Integer, Set<String>>();
        this.messages = new List<MessageWrapper>();
        this.parameters = new Map<String, Object>();
        String pref = NegoptimBatch.class.getName().replace('NegoptimBatch', '');
        batchName = batchName.replace(pref, '');
        // Load batch metadata settings
        Map<Id, Map<String, Batch_Settings__mdt>> batchSettingsMap = loadBatchSettings(new List<String> {batchName}, new List<Id> {UserInfo.getProfileId()});
        if (batchSettingsMap.containsKey(UserInfo.getProfileId()) && batchSettingsMap.get(UserInfo.getProfileId()).containsKey(batchName)) {
            batchMetadata = batchSettingsMap.get(UserInfo.getProfileId()).get(batchName);
        } else {
            batchMetadata = new Batch_Settings__mdt(Active__c = true, Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = false, Allow_Sending_Notification__c = true, Email_Subject__c='');
        }
    }

    /**
     * @param batchNameList [List<String>] a list of batch names, NULL means All
     * @param profileIdList, NULL means All
     * @return a map: profileId => map: batchName => Batch_Settings__mdt
     * if the map doesn't have an entry for a batchName then it doesn't have a Batch_Settings__mdt record for the specified profileId
     */
    public static Map<Id, Map<String, Batch_Settings__mdt>> loadBatchSettings(List<String> batchNameList, List<Id> profileIdList) {
        Map<Id, Map<String, Batch_Settings__mdt>> profileIdToBatchSettingsMap = new Map<Id, Map<String, Batch_Settings__mdt>>();
        List<Batch_Settings__mdt> batchSettings = Batch_Settings__mdt.getAll().values();
        if (!batchSettings.isEmpty()) {
            for(Batch_Settings__mdt item : batchSettings) {
                if (batchNameList != null && batchNameList.contains(item.MasterLabel) && profileIdList != null && profileIdList.contains(item.Profile_Id__c)) {
                    if (!profileIdToBatchSettingsMap.containsKey(item.Profile_Id__c)) {
                        profileIdToBatchSettingsMap.put(item.Profile_Id__c, new Map<String, Batch_Settings__mdt>());
                    }
                    profileIdToBatchSettingsMap.get(item.Profile_Id__c).put(item.MasterLabel, item);
                }
            }
        }
        /*String query = 'SELECT Id, DeveloperName, Profile_Id__c, Active__c, Allow_Sending_Email__c, Allow_Sending_Email_Technical__c, Sender__c, MasterLabel, Allow_Sending_Notification__c, Email_Subject__c';
        query += ' FROM Batch_Settings__mdt';
        List<String> conditions = new List<String>();
        List<String> batchNameList_escaped = new List<String>();
        for (String batchName : batchNameList) {
            batchNameList_escaped.add(String.escapeSingleQuotes(batchName));
        }
        if (batchNameList != null) {
            conditions.add('MasterLabel In (\'' + String.join(batchNameList_escaped, '\',\'') + '\')');
        }
        if (profileIdList != null) {
            conditions.add('Profile_Id__c IN (\'' + String.join(profileIdList, '\',\'') + '\')');
        }
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        String[] batchSettingsFields = new String[] {
          SObjectType.Batch_Settings__mdt.fields.Id.Name,
          SObjectType.Batch_Settings__mdt.fields.DeveloperName.Name,
          SObjectType.Batch_Settings__mdt.fields.Profile_Id__c.Name,
          SObjectType.Batch_Settings__mdt.fields.Active__c.Name,
          SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email__c.Name,
          SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email_Technical__c.Name,
          SObjectType.Batch_Settings__mdt.fields.Sender__c.Name,
          SObjectType.Batch_Settings__mdt.fields.MasterLabel.Name
        };
        ////if (NegoptimHelper.checkAccessibility(Batch_Settings__mdt.SObjectType, batchSettingsFields)) {
        for (Batch_Settings__mdt item : Database.query(query)) {
            if (!profileIdToBatchSettingsMap.containsKey(item.Profile_Id__c)) {
                profileIdToBatchSettingsMap.put(item.Profile_Id__c, new Map<String, Batch_Settings__mdt>());
            }
            profileIdToBatchSettingsMap.get(item.Profile_Id__c).put(item.MasterLabel, item);
        }
        //// }*/
        return profileIdToBatchSettingsMap;
    }

  	/**
     * @param results A list of Database.SaveResults
     * @param records A list of sObject representing updated or inserted records
     * @return void 
     * @description logs the failed results of an insert or update DML method
	***************************************************************************************************************************************** */
    global void logResults(List<Database.SaveResult> results, List<sObject> records) {
        for (Integer index = 0; records != null && index < records.size() && results != null && index < results.size(); index++) {
            sObject record = records[index];
            Database.SaveResult result = results[index];
            if (!result.isSuccess()) {
                String errorMessage;
                if (record.Id != null) {
                    errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                } else {
                    errorMessage = String.valueOf(record);
                }
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }

    /**
     * @param results A list of Database.UndeleteResult
     * @param records A list of sObject representing updated or inserted records
     * @return void
     * @description logs the failed results of an undelete DML method
	***************************************************************************************************************************************** */
    global void logResults(List<Database.UndeleteResult> results, List<sObject> records) {
        for (Integer index = 0; records != null && index < records.size() && results != null && index < results.size(); index++) {
            sObject record = records[index];
            Database.UndeleteResult result = results[index];
            if (!result.isSuccess()) {
                String errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }

    /**
     * @param results A list of Database.UpsertResult
     * @param records A list of sObject representing updated or inserted records
     * @return void
     * @description logs the failed results of an upsert DML method
	***************************************************************************************************************************************** */
    global void logResults(List<Database.UpsertResult> results, List<sObject> records) {
        for (Integer index = 0; records != null && index < records.size() && results != null && index < results.size(); index++) {
            sObject record = records[index];
            Database.UpsertResult result = results[index];
            if (!result.isSuccess()) {
                String errorMessage;
                if (record.Id != null) {
                    errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                } else {
                    errorMessage = String.valueOf(record);
                }
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }
    /**
     * @return void
     * @description increments the batch count.
     * It is CRITICAL to call this method at the end of a batch execute method
	***************************************************************************************************************************************** */
    global void incrementBatchIndex() {
        batchIndex++;
    }

    /**
     * @param error String representing an error message
     * @return void
     * @description Add the error message passed as parameter to the set of errors of the current batch
	***************************************************************************************************************************************** */
    global void logError(String error) {
        totalErrorsLogged++;
        if (capturedErrorCount >= MAX_TRACE_LOG_ENTRIES) {
            return;
        }
        if (errorByBatchIndex.containsKey(batchIndex)) {
            errorByBatchIndex.get(batchIndex).add(error);
        } else {
            errorByBatchIndex.put(batchIndex, new Set<string> {error});
        }
        capturedErrorCount++;
    }
    /**
     * method that return string represent the message of current batch
     */
     global void logMessage(String body) {
         totalMessagesLogged++;
         if (messages.size() >= MAX_TRACE_LOG_ENTRIES) {
             return;
         }
         DateTime timestamp = DateTime.now();
         messages.add(new MessageWrapper(body, timestamp));
    }

    /**
     * @param error String representing an Exception message
     * @return void
     * @description Add the Exception message passed as parameter to the set of Exceptions
	***************************************************************************************************************************************** */
    global void logError(Exception ex) {
        String errorString = '';
        errorString = ex instanceof DmlException ? ('<span style="color: red;">Line: ' + ex.getLineNumber() + ' -  ' + ex.getDmlMessage(0)+'</span>')
            : ('<span style="color: red;">Line: ' + ex.getLineNumber() + ' -  ' + ex.getMessage()+'</span>');

        errorString += '<span style="color: red;"> Stack Trace ' + ex.getStackTraceString() + '</span>';
        this.logError(errorString);
    }

    /**
     * @param parameterName
     * @param value
     * @return void
     * @description adds a new parameter to the map of parameters to be logged
	***************************************************************************************************************************************** */
    global void logParameter(String parameterName, Object value) {
        this.parameters.put(parameterName, value);
    }

    global void setSuccessLogResultsTable(Datatable successLogResultsTable) {
        this.successLogResultsTable = successLogResultsTable;
    }
    
    global void setFailedLogResultsTable(Datatable failedLogResultsTable) {
        this.failedLogResultsTable = failedLogResultsTable;
    }
    
    global void setLogResultsTableHeader(String logResultsTableHeader) {
        this.logResultsTableHeader = logResultsTableHeader;
    }
    /**
     * @param bc Database.BatchableContext
     * @return void
     * @description inserts a new log to the database by using NegoptimLog.saveApexBatchLog
     * This method is called in the finish method of the batch where an instance of this class is being initiated
	***************************************************************************************************************************************** */
    global Log__c saveLog(Database.BatchableContext bc) {
        this.asyncApexJob = getAsyncApexJob(bc);
        if (this.bt == NegoptimBatch.BatchType.Stateless) {
            // check security on access Log__c
            List<Log__c> logList = new List<Log__c>();
            try {
                logList = [SELECT NumberOfWarnings__c, TraceLog__c
                            FROM Log__c
                            WHERE Apex_Job_ID__c = :this.asyncApexJob.Id
                            WITH USER_MODE];
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                if (!logList.isEmpty()) {
                this.log = logList[0];
            }
        }
        this.log = NegoptimLog.mapToLog(this);
        try {
            Database.UpsertResult result;
            if (NegoptimHelper.checkFLS(AccessType.UPSERTABLE, new List<Log__c>{this.log})) {
                result = Database.upsert(this.log, false);
            }
            if (result == null) {
                System.debug('Log upsert failed: ' + (result != null ? result.getErrors()[0].getMessage() : 'No permission'));
                return this.log;
            }
            this.log.Id = result.getId();
            if (!result.isSuccess()) {
                String errorSummary = '';
                for (Database.Error err : result.getErrors()) {
                    errorSummary += err.getStatusCode() + ': ' + err.getMessage() + '; ';
                }
                log.TraceLog__c = 'Failed to save full trace log (' + errorSummary + ')';
                Database.UpsertResult fallbackResult = Database.upsert(log, false);
                if (!fallbackResult.isSuccess()) {
                    String fallbackErrorSummary = '';
                    for (Database.Error err : fallbackResult.getErrors()) {
                        fallbackErrorSummary += err.getStatusCode() + ': ' + err.getMessage() + '; ';
                    }
                    System.debug('Fallback Log__c save also failed for Apex Job ' + log.Apex_Job_ID__c + ' - ' + fallbackErrorSummary);
                    }
                }
        } catch (DMLException ex) {
            System.debug('Exception upserting log' + ex + '- cause: ' + ex.getCause());
        }
        if (String.isNotBlank(this.pendingFullTraceLog) && log.Id != null) {
            try {
                attachFullTraceLogFile(log, this.pendingFullTraceLog);
            } catch (Exception ex) {
                System.debug('Failed to attach full trace log file for Log__c ' + log.Id + ' - ' + ex.getMessage());
            }
        }
        return this.log;
    }

    /**
     * @description Saves fullContent as an .html ContentVersion and links it to log via a FileDirectory__c record
	***************************************************************************************************************************************** */
    private void attachFullTraceLogFile(Log__c log, String fullContent) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TraceLog_' + log.Submitted_Date__c + '_' + log.Apex_Job_ID__c + '.html';
        cv.PathOnClient = 'TraceLog_' + log.Submitted_Date__c + '.html';
        cv.VersionData = Blob.valueOf(fullContent);
        cv.IsMajorVersion = true;
        if (NegoptimHelper.checkFLS(System.AccessType.CREATABLE, new List<ContentVersion>{ cv })) {
            Database.SaveResult result = Database.insert(cv);
        }
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Log__c freshLog = [SELECT Id, Name FROM Log__c WHERE Id = :log.Id];

        FileDirectory__c fd = new FileDirectory__c();
        fd.RecordTypeId = Schema.SObjectType.FileDirectory__c.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();
        fd.Comment__c = Label.MSG_TraceLogTooLong_FileComment;
        fd.ContentDocumentId__c = cv.ContentDocumentId;
        fd.DocumentName__c = freshLog.Name;
        fd.IsPortalPublished__c = false;
        fd.ParentId__c = log.Id;
        fd.SubType__c = 'Other';
        if (NegoptimHelper.checkFLS(System.AccessType.CREATABLE, new List<FileDirectory__c>{ fd })) {
            Database.SaveResult result = Database.insert(fd);
        }
        // DownloadURL__c, InternalPreviewURL__c still not confirmed (?) - Trg_FileDirectory_Handler auto-derives them from ContentDocumentId__c
        if (NegoptimHelper.checkFLS(System.AccessType.UPDATABLE, new List<FileDirectory__c>{ fd })) {
            fd.DocumentName__c = freshLog.Name;
            Database.SaveResult result = Database.update(fd);
        }
        fd = [SELECT Id, DownloadURL__c FROM FileDirectory__c WHERE Id = :fd.Id WITH SYSTEM_MODE];
        String traceLogWithLink = log.TraceLog__c;
        if (String.isNotBlank(fd.DownloadURL__c)) {
            String absoluteDownloadUrl = URL.getOrgDomainUrl().toExternalForm() + fd.DownloadURL__c;
            traceLogWithLink += '<br/><a href="' + absoluteDownloadUrl + '" target="_blank">Download full trace log</a>';
        }
        log.FileDirectory__c = fd.Id;
        log.TraceLog__c = traceLogWithLink;        
        if (NegoptimHelper.checkFLS(System.AccessType.UPDATABLE, new List<Log__c>{ log })) {
            Database.SaveResult result = Database.update(log);
        }
    }
    /**
     * @param bc Passed from the finish method of the batch where an instance of this class was initiated
     * @param params params passed dynamically
     * @return void
     * @description Uses the provided email template to send an email of the Batch Process.
    ***************************************************************************************************************************************** */
    global void sendEmail(Database.BatchableContext bc, Map<String, Object> params) {
        if (params.containsKey('emailTemplateName')) {
            sendEmail(bc, (String)params.get('emailTemplateName'));
        } else if (params.containsKey('customHtmlBody') && params.containsKey('customSubject')) {
            sendEmail(bc, (String)params.get('customHtmlBody'), (String)params.get('customSubject'));
        } else if (params.containsKey('mail')) {
            sendEmail((Messaging.SingleEmailMessage)params.get('mail'));
        }
    }

    /**
     * @param bc Passed from the finish method of the batch where an instance of this class was initiated
     * @param templateUniqueName the unique name of the email template to be used. The developer can use the predefined template names. (see class properties)
     * @return void
     * @description Uses the provided email template to send an email of the Batch Process.
     * if the name of the template passed as parameter is invalid, an email with be send with the body as
     * the batch's trace log as body and the batch name followed by 'Batch Summary' as subject.
    ***************************************************************************************************************************************** */
    public void sendEmail(Database.BatchableContext bc, String emailTemplateName) {
        saveLog(bc);
        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        if (batchMetadata.Sender__c != null) {
            // fetch Org Wide Email Address
            try {
                owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress
                    WHERE Address = :batchMetadata.Sender__c
                    WITH SYSTEM_MODE];
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
        }
        if (this.batchMetadata.Allow_Sending_Email__c) {
            // check security on access EmailTemplate
            Id emailTemplateId;
            if (String.isNotBlank(emailTemplateName)) {
                List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
                try {
                    emailTemplateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :emailTemplateName WITH SYSTEM_MODE];
                } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
                emailTemplateId = !emailTemplateList.isEmpty() ? emailTemplateList[0].Id : null; //TODO: Make field in NegoptimHelper
            }
            Messaging.SingleEmailMessage mail;
            if (emailTemplateId != null) {
                mail = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), log.Id);
            } else {
                mail = new Messaging.SingleEmailMessage();
                //mail.setTemplateId(emailTemplateId);
                mail.setTargetObjectId(this.getFakeContactId());
            }
            // Set Sender
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            } else {
                mail.setSenderDisplayName('Negoptim By ULiT');
            }
            mail.setReplyTo('no-reply@negoptim.com');
            mail.setToAddresses(new String[] {UserInfo.getUserId()});
            try {
                mail.setWhatId(log.Id);
                mail.setSaveAsActivity(false);
                if (String.isNotBlank(this.customEmailSubject)) {
                    mail.setSubject(this.customEmailSubject);
                }
            } catch (Exception ex) {
                mail.setSubject(this.BatchName + ' Batch Summary');
                mail.setHtmlBody(this.generateTraceLog(false));
            }
            sendEmail(mail);
        }
        if (this.batchMetadata.Allow_Sending_Email_Technical__c) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Set Sender
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            } else {
                mail.setSenderDisplayName('Negoptim By ULiT');
            }
            mail.setReplyTo('no-reply@negoptim.com');
            mail.setToAddresses(new String[] {UserInfo.getUserId()});
            try {
                Id emailTemplateId;
                try {
                    emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :emailTemplateName WITH SYSTEM_MODE].Id; //TODO: Make field in NegoptimHelper
                } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                mail.setTargetObjectId(this.getFakeContactId());
                mail.setTemplateId(emailTemplateId);
                mail.setWhatId(log.Id);
                mail.setSaveAsActivity(false);
            } catch (Exception ex) {
                mail.setSubject(this.BatchName + ' Batch Summary');
                mail.setHtmlBody(this.generateTraceLog(true));
            }
            sendEmail(mail);
        }
    }
    
    /**
     * @param bc Passed from the finish method of the batch where an instance of this class was initiated
     * @param customHtmlBody The body of the email in HTML markup. If null it will be subtituted with the trace log of the batch where an instance of this class was initiated
     * @param customSubject The subject of the email. If null it will be substituted with the name of the batch followed by 'Batch Summary'
     * @return void
     * @description Use this method to send a custom email of the batch results in the finish method.
     * This method saves a log in the database, therefor there is no need to call saveLog().
	***************************************************************************************************************************************** */
    global void sendEmail(Database.BatchableContext bc, String customHtmlBody, String customSubject) {
        saveLog(bc);
        String initialCustomHtmlBody = customHtmlBody;
        String initialCustomSubject = customSubject;
        if (this.batchMetadata.Allow_Sending_Email__c || this.batchMetadata.Allow_Sending_Email_Technical__c) {
            List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
            if (batchMetadata.Sender__c != null) {
                    // fetch Org Wide Email Address
                try {
                    owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress
                        WHERE Address = :batchMetadata.Sender__c
                        WITH SYSTEM_MODE];
                } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
            }
            if (this.batchMetadata.Allow_Sending_Email__c) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                // Set Sender
                if (!owea.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } else {
                    mail.setSenderDisplayName('Negoptim By ULiT');
                }
                mail.setReplyTo('no-reply@negoptim.com');
                mail.setToAddresses(new String[] {UserInfo.getUserId()});
                if (customHtmlBody == null) {
                    customHtmlBody = this.generateTraceLog(false);
                }
                if (customSubject == null) {
                    customSubject = this.batchName + ' Batch Summary';
                }
                mail.setHtmlBody(customHtmlBody);
                mail.setSubject(customSubject);
                sendEmail(mail);
            }
            customHtmlBody = initialCustomHtmlBody;
            customSubject = initialCustomSubject;
            if (this.batchMetadata.Allow_Sending_Email_Technical__c) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                // Set Sender
                if (!owea.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } else {
                    mail.setSenderDisplayName('Negoptim By ULiT');
                }
                mail.setReplyTo('no-reply@negoptim.com');
                mail.setToAddresses(new String[] {UserInfo.getUserId()});
                if (customHtmlBody == null) {
                    customHtmlBody = this.generateTraceLog(true);
                }
                if (customSubject == null) {
                    customSubject = this.batchName + ' Batch Summary';
                }
                mail.setHtmlBody(customHtmlBody);
                mail.setSubject(customSubject);
                sendEmail(mail);
            }
        }
        // send notification
        Boolean isFinish = (asyncApexJob.Status.equals('Completed') ||asyncApexJob.Status.equals('Failed') || asyncApexJob.Status.equals('Aborted'));
        if (batchMetadata.Allow_Sending_Notification__c && isFinish && !IsNotificationSent)
            this.sendNotification(bc, this.log.Id,
                                  String.isBlank(batchMetadata.Email_Subject__c) ? this.log.Class_Name__c + ' - ' + this.log.Status__c : batchMetadata.Email_Subject__c,
                                  'The batch Apex job processed ' + this.log.TotalJobItems__c +  ' batches with ' +  this.log.NumberOfErrors__c + ' failures \n' +
                                  'Warning Messages (' + this.log.NumberOfWarnings__c + ' messages)');

    }

    public void sendMessages(Database.BatchableContext bc) {
        String subject = this.batchName + ' Messages';
        sendEmail(bc, this.getMessageTraceLog(), subject);
    }

    private void sendEmail(Messaging.SingleEmailMessage mail) {
        Integer used = Limits.getEmailInvocations();
        Integer emailLimit = Limits.getLimitEmailInvocations();
        if (used >= emailLimit) {
            System.debug('Email limit was exceeded.');
        } else {
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            } catch(System.EmailException ex) {
                System.debug('Caught Email Exception: ' + ex);
            }
        }
    }

    /**
     * @return an HTML String of the batch's trace log
     * @description generates an HTML markup of the batch information and status including error messages
	***************************************************************************************************************************************** */
    public String generateTraceLog(Boolean isTechnical) {
        String traceLog = generateTraceLogHeader(isTechnical);//updateHeaderTraceLog(getHeaderTraceLog(), getNumberOfErrors());
        if (isTechnical) {
            traceLog += getWarningTraceLog();
        }
        if (!this.messages.isEmpty()) traceLog += getMessageTraceLog();
        return traceLog;
    }

    /**
     * @return trace log header
     * @description generate log header
	***************************************************************************************************************************************** */
    public String generateTraceLogHeader(Boolean isTechnical) {
        String LineSeparator = '<hr/>';
        String newLine = '<br/>';
        String traceLog = lineSeparator;
        traceLog += '<b>Batch Name: </b>' + batchName + newLine;
        traceLog += '<b>Started From: </b>' + startedFrom + newLine;
        traceLog += '<b>Source: </b>' + UserInfo.getOrganizationName() + newLine;
        traceLog += '<b>Result: </b>';
        //display results in colors depending on the job status
        Integer nbOfErrors = this.log == null ? this.getNumberOfErrors() : (Integer) this.log.NumberOfWarnings__c;
        traceLog += '<span style="font-weight: bold;color: ';
        if (this.asyncApexJob.NumberOfErrors == 0 && nbOfErrors == 0) {
            traceLog += 'green;">Successful';
        } else if (this.asyncApexJob.NumberOfErrors > 0) {
            traceLog += 'red;">Failed';
        } else if (nbOfErrors > 0) {
            traceLog += 'orange;">Warning';
        }
        traceLog += '</span>';
        traceLog += lineSeparator;
        if (isTechnical) {
            //Insert Parameters
            if (parameters != null && !parameters.isEmpty()) {
                traceLog += '<u>Log Summary</u>' + newLine;
                traceLog += '<ul>';
                for(String key : parameters.keySet()) {
                    String param = '';
                    if (parameters.get(key) != null)
                        param = String.valueOf(parameters.get(key)).escapeHtml4();
                    traceLog += '<li>' + '<b>' + key + '</b>' +  ': ' +  param  + '</li>';
                }
                traceLog += '</ul>';
                traceLog += lineSeparator;
            }
        }
        //Log details and warning messages
        traceLog += '<u>Trace Log</u>' + newLine;
        traceLog += 'The batch Apex job processed ' + asyncApexJob.TotalJobItems + ' batches with '+ asyncApexJob.NumberOfErrors + ' failures.' + newLine;
        if (isTechnical) {
            if (!String.isEmpty(this.asyncApexJob.ExtendedStatus)) {
                traceLog += '<div style="color: red;"><b>Failure Details: ' + this.asyncApexJob.ExtendedStatus + '</b></div>';
            }
            traceLog += 'Warning Messages (' + nbOfErrors + ' messages)' + newLine;
        }
        return traceLog;
    }
    
    /**
     * @return an HTML String of the STATLESS batch's trace log
     * @description generates an HTML markup of the Statless batch error messages
	***************************************************************************************************************************************** */
    public String getWarningTraceLog() {
        if (this.bt == NegoptimBatch.BatchType.Stateless) {
            this.batchIndex = this.getAsyncApexJob().JobItemsProcessed;
            if (!errorByBatchIndex.isEmpty() && this.batchIndex != 0) {
                Set<String> errorMessage = errorByBatchIndex.get(0);
                errorByBatchIndex.put(this.batchIndex, errorMessage);
                errorByBatchIndex.remove(0);
            }
        }
        String LineSeparator = '<hr/>';
        String newLine = '<br/>';
        List<String> parts = new List<String>();
        Integer heapSafetyLimit = (Limits.getLimitHeapSize() * 7) / 10;
        Integer cpuSafetyLimit = (Limits.getLimitCpuTime() * 7) / 10;
        Boolean warningsTruncated = false;
        Integer entriesRendered = 0;
        for(Integer key : errorByBatchIndex.keySet()) {
            if (entriesRendered >= MAX_TRACE_LOG_ENTRIES || Limits.getHeapSize() > heapSafetyLimit || Limits.getCpuTime() > cpuSafetyLimit) {
                warningsTruncated = true;
                break;
            }
            Set<String> errors = errorByBatchIndex.get(key);
            if (!errors.isEmpty()) {
                parts.add('<u>' + 'Batch ' + key + '</u>' + newLine);

                parts.add('Warning messages:' + newLine);
                parts.add('<ol>');

                for(String warning : errors) {
                    if (entriesRendered >= MAX_TRACE_LOG_ENTRIES) {
                        warningsTruncated = true;
                        break;
                    }
                    parts.add('<li>' + warning + '</li>');
                    entriesRendered++;
                }
                parts.add('</ol>');
                parts.add(LineSeparator);
            }
            if (warningsTruncated) {
                break;
            }
        }
        Integer droppedAtSource = totalErrorsLogged - capturedErrorCount;
        if (warningsTruncated || droppedAtSource > 0) {
            parts.add('<i>... ' + (droppedAtSource > 0 ? String.valueOf(droppedAtSource) : 'additional') + ' warning message(s) omitted (volume exceeds the ' + MAX_TRACE_LOG_ENTRIES + '-entry cap for this file)</i>' + LineSeparator);
            this.traceLogTruncatedByHeapGuard = true;
        }
        return String.join(parts, '');
    }
    /**
     * get the trace log of message.
     *****/
    public String getMessageTraceLog() {
        if (this.messages.isEmpty()) {
            return '';
        }
        //String LineSeparator = '<hr/>';
        //String newLine = '<br/>';
        List<String> parts = new List<String>();
        parts.add('<b>Batch Messages</b><br/>');
        parts.add('<table width="100%">');
        parts.add('<tr>');
        parts.add('<td>timestamp</td>');
        parts.add('<td>body</td>');
        parts.add('</tr>');
        Integer heapSafetyLimit = (Limits.getLimitHeapSize() * 7) / 10;
        Integer cpuSafetyLimit = (Limits.getLimitCpuTime() * 7) / 10;
        Boolean messagesTruncated = false;
        Integer entriesRendered = 0;
        for (MessageWrapper item : this.messages) {
            if (entriesRendered >= MAX_TRACE_LOG_ENTRIES || Limits.getHeapSize() > heapSafetyLimit || Limits.getCpuTime() > cpuSafetyLimit) {
                messagesTruncated = true;
                break;
            }
            parts.add('<tr>');
            parts.add('<td>' + item.timestamp + '</td>');
            parts.add('<td>' + item.body + '</td>');
            parts.add('</tr>');
            entriesRendered++;
        }
        Integer droppedMessagesAtSource = totalMessagesLogged - messages.size();
        if (messagesTruncated || droppedMessagesAtSource > 0) {
            parts.add('<tr><td colspan="2"><i>... ' + (droppedMessagesAtSource > 0 ? String.valueOf(droppedMessagesAtSource) : 'additional') + ' message(s) omitted (volume exceeds the ' + MAX_TRACE_LOG_ENTRIES + '-entry cap for this file)</i></td></tr>');
            this.traceLogTruncatedByHeapGuard = true;
        }
        parts.add('</table>');
        return String.join(parts, '');
    }

    /**
     * @description True if getWarningTraceLog()/getMessageTraceLog()'s heap safety
     * guard has cut a loop short at any point during this instance's lifetime.
	***************************************************************************************************************************************** */
    public Boolean wasTraceLogTruncatedByHeapGuard() {
        return this.traceLogTruncatedByHeapGuard;
    }

     /**
     * @return a count of all Errors
     * @description loop over error map and calculate the number of errors
	***************************************************************************************************************************************** */
    public Integer getNumberOfErrors() {
        return totalErrorsLogged;
    }
    /**
    * @description get number of messages
	*/
    public Integer getNumberOfMessages() {
        return totalMessagesLogged;
    }

    /**
    * @description returns the batch messages
	*/
    public List<MessageWrapper> getMessages() {
        return this.messages;
    }

    global String getBatchName() {
    	return this.batchName;
    }

    global AsyncApexJob getAsyncApexJob() {
        return this.asyncApexJob;
    }
    //Make sure that the profile running the batch has access to AsyncApexJob
    global AsyncApexJob getAsyncApexJob(Database.BatchableContext bc) {
        if (this.asyncApexJob == null) {
            List<AsyncApexJob> jobs = getAsyncApexByJobId(bc.getJobId());
            if (!jobs.isEmpty()) {
                this.asyncApexJob = jobs.get(0);
            }
        }
        return this.asyncApexJob;
    }

    private static List<AsyncApexJob> getAsyncApexByJobId(Id jobId) {
        List<AsyncApexJob> jobResults = new List<AsyncApexJob>();
        try {
            jobResults = [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
                          CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
                          FROM AsyncApexJob WHERE Id = :jobId
                          WITH SYSTEM_MODE];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
        return jobResults;
    }

    public void resetAsyncApexJob(Database.BatchableContext bc) {
        this.asyncApexJob = null;
        this.getAsyncApexJob(bc);
    }

    public integer getErrorNumberByBatchIndex() {
        if (this.errorByBatchIndex.containsKey(batchIndex)) {
            return this.errorByBatchIndex.get(batchIndex).size();
        } else {
            return 0;
        }
    }

    global String getStartedFrom() {
        return this.startedFrom;
    }

    public Log__c getLog() {
        return log;
    }

    public String getPendingFullTraceLog() {
        return pendingFullTraceLog;
    }

    public void setPendingFullTraceLog(String pendingFullTraceLog) {
        this.pendingFullTraceLog = pendingFullTraceLog;
    }

    public NegoptimBatch.BatchType getBatchType() {
        return this.bt;
    }

    private Id getFakeContactId() {//TODO: move to NegoptimHelper
        Contact fakeContact;
        id contactId;
        String fakeContactName = '**DONT DELETE**';
        try {
            try {
                fakeContact = [SELECT Id FROM Contact WHERE Name = :fakeContactName WITH SYSTEM_MODE];
            } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                contactId = fakeContact.Id;
                fakeContact.Email = UserInfo.getUserEmail();
        } catch (Exception ex) {
            fakeContact = new Contact(FirstName='**DONT', LastName='DELETE**', Email=UserInfo.getUserEmail());
            contactId = fakeContact.Id;
        }
        if (NegoptimHelper.checkFLS(AccessType.UPSERTABLE, new List<Contact>{fakeContact})) {
            Database.UpsertResult fakeContactUpsertResults = Database.upsert(fakeContact);
        }
        return fakeContact.Id;
    }

    /**
     * @description run safely a batch
     * @batchable the class batch instance
     * @batchSize the batch size
     **/
    global static Id executeBatch(Database.Batchable<SObject> batchClass, Integer batchSize) {
        String className = String.valueOf(batchClass).substring(0, String.valueOf(batchClass).indexOf(':')); // TODO: check on managed package
        Batch_Settings__mdt batchMetadata;
        Map<Id, Map<String, Batch_Settings__mdt>> batchSettingsMap = loadBatchSettings(new List<String> {className}, new List<Id> {UserInfo.getProfileId()});
        if (batchSettingsMap.containsKey(UserInfo.getProfileId()) && batchSettingsMap.get(UserInfo.getProfileId()).containsKey(className)) {
            batchMetadata = batchSettingsMap.get(UserInfo.getProfileId()).get(className);
        } else {
            batchMetadata = new Batch_Settings__mdt(Active__c = true, Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = true);
        }
        Id batchProcessId;
        // check if not running from future method or another batch and is active
        if (batchMetadata.Active__c) {
            Id userId = UserInfo.getUserId();
            Integer jobsProcessing = 0, jobsScheduled = 0;
            if (!Test.isRunningTest()) {
                
                
                    String scheduleName = className + '-' + userId;
                try {
                    jobsProcessing = [SELECT COUNT() FROM AsyncApexJob
                                      WHERE CreatedById = :userId
                                      AND ApexClass.Name LIKE :className
                                    AND Status NOT IN ('Aborted', 'Completed', 'Failed') AND JobType = 'BatchApex'
                                    WITH SYSTEM_MODE];
                    jobsScheduled = [SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :scheduleName + '%' WITH SYSTEM_MODE];
                } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
            }
            if (jobsProcessing > 0) {
                Integer delay = (jobsScheduled + 1) * 1; // 1 min delay
                System.scheduleBatch(batchClass, className + '-' + userId + '-Schedule' + System.now() + Math.random() * 10, delay, batchSize);
            } else {
                batchProcessId = Database.executeBatch((Database.Batchable<SObject>) batchClass, batchSize);
            }
        }
        return batchProcessId;
    }

    /**
     * @description run safely a batch
     * @className the Name of Batch
     * @params the Parameters of Batch
     * @batchSize the batch size
     **/
    global static Id executeBatch(String className, Map<String, Object> params, Integer batchSize) {
        String openSourceClassName = className + 'Ext';
        List<AggregateResult> results = new List<AggregateResult>();
        try {
            results = [SELECT COUNT(Id) apexClassCount
                                         FROM ApexClass
                                         WHERE Name = :openSourceClassName
                                         AND NamespacePrefix = NULL
                                         WITH SYSTEM_MODE];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
        if (results != null && !results.isEmpty()) {
            Integer openSourceClassExist = (Integer) results.get(0).get('apexClassCount');
            if (openSourceClassExist > 0) {
                className = openSourceClassName;
            }
        }
        Batch_Settings__mdt batchMetadata;
        Map<Id, Map<String, Batch_Settings__mdt>> batchSettingsMap = loadBatchSettings(new List<String> {className}, new List<Id> {UserInfo.getProfileId()});
        if (batchSettingsMap.containsKey(UserInfo.getProfileId()) && batchSettingsMap.get(UserInfo.getProfileId()).containsKey(className)) {
            batchMetadata = batchSettingsMap.get(UserInfo.getProfileId()).get(className);
        } else {
            batchMetadata = new Batch_Settings__mdt(Active__c = true, Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = true);
        }
        Id batchProcessId;
        // check if not running from future method or another batch and is active
        if (batchMetadata.Active__c) {
                Id userId = UserInfo.getUserId();
                Integer jobsProcessing = 0, jobsScheduled = 0;
                if (!Test.isRunningTest()) {
                        String scheduleName = className + '-' + userId;
                try {
                    jobsProcessing = [SELECT COUNT() FROM AsyncApexJob
                                        WHERE CreatedById = :userId
                                        AND ApexClass.Name LIKE :className
                                        AND Status NOT IN ('Aborted', 'Completed', 'Failed') AND JobType = 'BatchApex'
                                        WITH SYSTEM_MODE];
                    jobsScheduled = [SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :scheduleName + '%' WITH SYSTEM_MODE];
                    } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe); }
                }
                if (jobsProcessing > 0) {
                    Integer delay = (jobsScheduled + 1) * 1; // 1 min delay
                 System.scheduleBatch(getBatchInstanceByName(className, params), className + '-' + userId + '-Schedule' + System.now() + Math.random() * 10, delay, batchSize);
                } else {
                batchProcessId = Database.executeBatch((Database.Batchable<SObject>) getBatchInstanceByName(className, params), batchSize);
            }
        }
        return batchProcessId;
    }
    
    public static Database.Batchable<SObject> getBatchInstanceByName(String className, Map<String, Object> params) {
        try {
            Type t = Type.forName(className);
            if (t == null) throw new IllegalArgumentException('Class not found: ' + className);
            Object obj = t.newInstance();
            if (!(obj instanceof BatchFactory)) {
                throw new IllegalArgumentException(className + ' must implement BatchFactory');
            }
            BatchFactory factory = (BatchFactory)obj;
            Database.Batchable<SObject> batch = factory.getBatchInstance(params);
            return batch;
        } catch (Exception e) {
            System.debug('Error executing batch: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * @description run safely a batch
     * @batchable the class batch instance
     * @batchSize the batch size
     **/
    public static Id executeBatchImmediat(Database.Batchable<SObject> batchClass, Integer batchSize) {
        String className = String.valueOf(batchClass).substring(0, String.valueOf(batchClass).indexOf(':')); // TODO: check on managed package
        Batch_Settings__mdt batchMetadata;
        Map<Id, Map<String, Batch_Settings__mdt>> batchSettingsMap = loadBatchSettings(new List<String> {className}, new List<Id> {UserInfo.getProfileId()});
        if (batchSettingsMap.containsKey(UserInfo.getProfileId()) && batchSettingsMap.get(UserInfo.getProfileId()).containsKey(className)) {
            batchMetadata = batchSettingsMap.get(UserInfo.getProfileId()).get(className);
        } else {
            batchMetadata = new Batch_Settings__mdt(Active__c = true, Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = true);
        }
        Id batchProcessId;
        // check if not running from future method or another batch and is active
        if (batchMetadata.Active__c) {
            batchProcessId = Database.executeBatch((Database.Batchable<SObject>) batchClass, batchSize);
        }
        return batchProcessId;
    }

    global void sendNotification(Database.BatchableContext bc, Map<String, Object> params) {
        if (params.containsKey('objectId') && params.containsKey('title') && params.containsKey('body')) {
            sendNotification(bc, (Id)params.get('objectId'), (String)params.get('title'), (String)params.get('body'));
        } else if (params.containsKey('useLogId') && ((Boolean)params.get('useLogId')) == true && params.containsKey('title') && params.containsKey('body')) {
            sendNotification(bc, log.Id, (String)params.get('title'), (String)params.get('body'));
        } else if (params.containsKey('pageRef') && params.containsKey('title') && params.containsKey('body')) {
            sendNotification(bc, (String)params.get('pageRef'), (String)params.get('title'), (String)params.get('body'));
        }
    }
    
    public void sendNotification(Database.BatchableContext bc, Id objectId, String title, String body) {

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        Id userId = Userinfo.getUserId();
        notification.setBody(body);
        notification.setTitle(title);
        notification.setSenderId(userId);
        CustomNotificationType type;
        try {
            type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'BatchNotification' WITH SYSTEM_MODE];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
        if (type != null) {
            notification.setNotificationTypeId(type.Id);
            notification.setTargetId(objectId); // target object id
            notification.send(new Set<String> { userId });
            IsNotificationSent = true;
        }
    }

    public void sendNotification(Database.BatchableContext bc, String pageRef, String title, String body) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        Id userId = Userinfo.getUserId();
        notification.setBody(body);
        notification.setTitle(title);
        notification.setSenderId(userId);
        CustomNotificationType type;
        try {
            type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'BatchNotification' WITH SYSTEM_MODE];
        } catch (QueryException qe) { NegoptimHelper.getInaccessibleFields(qe);}
        if (type != null) {
            notification.setNotificationTypeId(type.Id);
            notification.setTargetPageRef(pageRef);
            notification.send(new Set<String> { userId });
            IsNotificationSent = true;
        }
    }

    global enum BatchType {
        Stateless,
        Stateful
    }

    public class MessageWrapper {
        public String body;
        public DateTime timestamp;

        public MessageWrapper(String body, DateTime timestamp) {
            this.body = body;
            this.timestamp = timestamp;
        }
    }
}