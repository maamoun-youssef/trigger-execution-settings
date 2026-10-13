/**
 * @author ULiT
 * @date 17/05/2018
 * The aim of NegoptimLog is to save all Controllers/Batches/ Log Result in the database
 * */
public with sharing class NegoptimLog {

    private static final Integer SAFETY_MARGIN = 5000;

    // Convert NegoptimBatch format to NegoptimLog Format
    public static Log__c mapToLog(NegoptimBatch nb) {
        Integer maxSize = Log__c.TraceLog__c.getDescribe().getLength() - SAFETY_MARGIN;
        Boolean stateless = nb.getBatchType() == NegoptimBatch.BatchType.Stateless;
        // return the log if exist for stateful batches
        if (!stateless && nb.getLog() != null && nb.getLog().Id != null) {
            return nb.getLog();
        }
        
        String asyncJobStatus = nb.getAsyncApexJob().Status;
        Boolean isFinish = (asyncJobStatus.equals('Completed') ||asyncJobStatus.equals('Failed') || asyncJobStatus.equals('Aborted'));
        Log__c log = new Log__c(
            Apex_Job_ID__c = nb.getAsyncApexJob().Id,
            Class_Name__c = nb.getBatchName(),
            Started_From__c = nb.getStartedFrom(),
            JobItemsProcessed__c = nb.getAsyncApexJob().JobItemsProcessed,
            CompletedDate__c = nb.getAsyncApexJob().CompletedDate,
            NumberOfErrors__c = nb.getAsyncApexJob().NumberOfErrors,
            JobType__c = NegoApexLogTypesEnum.BatchApex.name(),
            MethodName__c = nb.getAsyncApexJob().MethodName,
            NumberOfWarnings__c = nb.getNumberOfErrors(),
            Status__c = nb.getAsyncApexJob().Status,
            Submitted_Date__c = nb.getAsyncApexJob().CreatedDate,
            TotalJobItems__c = nb.getAsyncApexJob().TotalJobItems,
            Status_Detail__c = nb.getAsyncApexJob().extendedStatus,
            SuccessResultSummary__c = nb?.successLogResultsTable?.renderToHtml() ,
            FailureResultSummary__c = nb?.failedLogResultsTable?.renderToHtml(),
            SummaryHeader__c = nb?.logResultsTableHeader
        );
        if (stateless) {
            String loggedWarnings = (nb.getLog() != null && nb.getLog().TraceLog__c != null) ? nb.getLog().TraceLog__c : '';
            Integer loggedNumberOfWarnings = nb.getLog() != null ? Integer.valueOf(nb.getLog().NumberOfWarnings__c) : 0;

            String content = loggedWarnings + nb.getWarningTraceLog() + nb.getMessageTraceLog();
            String header = isFinish ? nb.generateTraceLogHeader(true) : '';
            String body = header + content;

            if (body.length() > maxSize || nb.wasTraceLogTruncatedByHeapGuard()) {
                String fullHeader = isFinish ? header : nb.generateTraceLogHeader(true);
                String summary = fullHeader + '<br/>' + Label.MSG_TraceLogTooLong_CheckFile;
                if (summary.length() > maxSize) {
                    summary = summary.substring(0, maxSize);
                }
                body = summary;
                nb.setPendingFullTraceLog(fullHeader + content);
            } else {
                nb.setPendingFullTraceLog(null);
            }

            log.TraceLog__c = body;
            log.NumberOfWarnings__c = loggedNumberOfWarnings + nb.getNumberOfErrors();
            if (nb.getLog() != null && nb.getLog().Id != null) {
                log.Id = nb.getLog().Id;
            }
        } else {
            String content = nb.generateTraceLog(true);
            if (content.length() > maxSize || nb.wasTraceLogTruncatedByHeapGuard()) {
                String header = nb.generateTraceLogHeader(true);
                String summary = header + '<br/>' + Label.MSG_TraceLogTooLong_CheckFile;
                if (summary.length() > maxSize) {
                    summary = summary.substring(0, maxSize);
                }
                log.TraceLog__c = summary;
                nb.setPendingFullTraceLog(content);
            } else {
                log.TraceLog__c = content;
                nb.setPendingFullTraceLog(null);
            }
        }
        return log;
    }

    public enum NegoApexLogTypesEnum {
        Future,
        SharingRecalculation,
        ScheduledApex,
        BatchApex,
        BatchApexWorker,
        TestRequest,
        TestWorker,
        ApexToken,
        Queueable
    }
}