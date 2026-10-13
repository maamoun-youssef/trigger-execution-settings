/**
 * @author ULiT
 * @date 21/09/2026
 * @description Unit test class for W-010754 (negOptim Logs - Enhance tracing if log is too long).
 * Tests NegoptimLog.mapToLog and the trace log logic of NegoptimBatch (Stateful and Stateless):
 * when the trace log exceeds the threshold, a summary is stored in Log__c.TraceLog__c and the full raw trace
 * is attached as an .html file through a FileDirectory__c record, linked back through Log__c.FileDirectory__c.
 * */
@isTest
private class NegoptimBatchTest {

    /**
     * @description produce a real, completed AsyncApexJob for NegoptimBatch.saveLog.
     */
    private class DummyJob implements Queueable {
        public void execute(QueueableContext qc) {
        }
    }

    /**
     * @description Batch context passed to NegoptimBatch.saveLog, returning the Id of the completed job.
     */
    private class FakeBatchContext implements Database.BatchableContext {
        private Id jobId;
        FakeBatchContext(Id jobId) { this.jobId = jobId; }
        public Id getJobId() { return jobId; }
        public Id getChildJobId() { return null; }
    }

    /**
     * @description Enqueues DummyJob n times and lets them complete.
     * @param n number of jobs to create
     * @return the Ids of the completed jobs
     */
    private static List<Id> createCompletedJobs(Integer n) {
        List<Id> enqueuedIds = new List<Id>();
        Test.startTest();
        for (Integer i = 0; i < n; i++) {
            enqueuedIds.add(System.enqueueJob(new DummyJob()));
        }
        Test.stopTest();
        // enqueueJob returns a 15-character Id, while Log__c.Apex_Job_ID__c stores the 18-character one: normalize it
        List<Id> jobIds = new List<Id>();
        for (AsyncApexJob job : [SELECT Id FROM AsyncApexJob WHERE Id IN :enqueuedIds ORDER BY CreatedDate, Id]) {
            jobIds.add(job.Id);
        }
        return jobIds;
    }

    /**
     * @description Logs lineCount lines in a NegoptimBatch of the given type and saves its log for the given job.
     * @param jobId the completed job the log is saved for
     * @param batchType Stateful or Stateless
     * @param lineCount number of lines logged
     * @param useErrorChannel true to log through logError(), false to log through logMessage()
     */
    private static void saveLogFor(Id jobId, NegoptimBatch.BatchType batchType, Integer lineCount, Boolean useErrorChannel) {
        NegoptimBatch nb = new NegoptimBatch('NegoptimBatchTest', batchType, 'UnitTest');
        nb.logParameter('TestLogParam', 'unit test param');
        nb.logParameter('query', 'SELECT Id, Name FROM Account LIMIT 50');
        for (Integer i = 0; i < lineCount; i++) {
            String line = 'Row ' + i + ': VALIDATION_ERROR on AssortmentDetail__c - required field missing for product SKU-' + (100000 + i);
            if (useErrorChannel) {
                nb.logError(line);
            } else {
                nb.logMessage(line);
            }
        }
        Log__c returned = nb.saveLog(new FakeBatchContext(jobId));
        System.assertNotEquals(null, returned.Id, 'The Log__c must be saved');
    }

    /**
     * @description Runs the Stateful path and returns the Apex job Id the log was saved for.
     */
    private static Id runStateful(Integer lineCount, Boolean useErrorChannel) {
        Id jobId = createCompletedJobs(1)[0];
        saveLogFor(jobId, NegoptimBatch.BatchType.Stateful, lineCount, useErrorChannel);
        return jobId;
    }

    /**
     * @description Runs the Stateless path and returns the Apex job Id the log was saved for.
     */
    private static Id runStateless(Integer lineCount, Boolean useErrorChannel) {
        Id jobId = createCompletedJobs(1)[0];
        saveLogFor(jobId, NegoptimBatch.BatchType.Stateless, lineCount, useErrorChannel);
        return jobId;
    }

    private static Log__c getLog(Id jobId) {
        List<Log__c> logs = [
            SELECT Id, Name, Class_Name__c, Started_From__c, Status__c, JobType__c, NumberOfWarnings__c,
                   TraceLog__c, FileDirectory__c
            FROM Log__c
            WHERE Apex_Job_ID__c = :String.valueOf(jobId)
        ];
        System.assertEquals(1, logs.size(), 'Exactly one Log__c must be created for the job');
        return logs[0];
    }

    private static List<FileDirectory__c> getFileDirectories(Log__c log) {
        return [
            SELECT Id, Comment__c, ContentDocumentId__c, DocumentName__c, IsPortalPublished__c,
                   ParentId__c, SubType__c, RecordType.DeveloperName, DownloadURL__c
            FROM FileDirectory__c
            WHERE ParentId__c = :log.Id
        ];
    }

    private static ContentVersion getFile(FileDirectory__c fd) {
        List<ContentVersion> versions = [
            SELECT Title, PathOnClient, FileType, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :fd.ContentDocumentId__c AND IsLatest = true
        ];
        System.assertEquals(1, versions.size(), 'The attached ContentVersion must exist');
        return versions[0];
    }

    private static Integer maxSummarySize() {
        return Log__c.TraceLog__c.getDescribe().getLength();
    }

    /**
     * @description Verifies that a small Stateful log (messages) is stored inline in TraceLog__c,
     * with no file attached and no FileDirectory__c on the Log__c.
     */
    @isTest
    static void Case1_testSmallStatefulMessages() {
        Id jobId = runStateful(50, false);
        Log__c log = getLog(jobId);

        System.assertEquals('NegoptimBatchTest', log.Class_Name__c, 'Class name was not logged');
        System.assertEquals('UnitTest', log.Started_From__c, 'Started From was not logged');
        System.assertEquals('Completed', log.Status__c, 'Job status was not logged');
        System.assertEquals('BatchApex', log.JobType__c, 'Job type was not logged');
        System.assert(log.TraceLog__c.contains('Batch Messages'), 'The real content must be stored inline');
        System.assert(!log.TraceLog__c.contains(Label.MSG_TraceLogTooLong_CheckFile), 'No overflow note expected');
        System.assert(getFileDirectories(log).isEmpty(), 'No file must be attached for a small log');
        System.assertEquals(null, log.FileDirectory__c, 'Log__c.FileDirectory__c must stay empty');
    }

    /**
     * @description Verifies that a small Stateful log (errors) is stored inline in TraceLog__c,
     * with the warnings counted and no file attached.
     */
    @isTest
    static void Case2_testSmallStatefulErrors() {
        Id jobId = runStateful(50, true);
        Log__c log = getLog(jobId);

        System.assertEquals(50, log.NumberOfWarnings__c, 'One warning per logged line is expected');
        System.assert(log.TraceLog__c.contains('Warning messages:'), 'The warnings must be stored inline');
        System.assert(getFileDirectories(log).isEmpty(), 'No file must be attached for a small log');
        System.assertEquals(null, log.FileDirectory__c, 'Log__c.FileDirectory__c must stay empty');
    }

    /**
     * @description Verifies that a small Stateless log is stored inline in TraceLog__c, with no file attached.
     */
    @isTest
    static void Case3_testSmallStateless() {
        Id jobId = runStateless(10, false);
        Log__c log = getLog(jobId);

        System.assertEquals('NegoptimBatchTest', log.Class_Name__c, 'Class name was not logged');
        System.assert(log.TraceLog__c.contains('Row 9:'), 'The real content must be stored inline');
        System.assert(getFileDirectories(log).isEmpty(), 'No file must be attached for a small log');
        System.assertEquals(null, log.FileDirectory__c, 'Log__c.FileDirectory__c must stay empty');
    }

    /**
     * @description Verifies that a Stateful log (messages) exceeding the threshold stores a summary in TraceLog__c
     * (Batch Name, Started From, Source, Result, params and query, too-long note) within the field length,
     * attaches the full raw trace as an .html file through a FileDirectory__c populated as specified,
     * and fills Log__c.FileDirectory__c.
     */
    @isTest
    static void Case4_testBigStatefulMessages() {
        Id jobId = runStateful(1500, false);
        Log__c log = getLog(jobId);

        // The summary stored in the field
        String summary = log.TraceLog__c;
        System.assert(summary.length() <= maxSummarySize(), 'The summary must fit in the field');
        System.assert(summary.contains('Batch Name'), 'Batch Name is missing from the summary');
        System.assert(summary.contains('NegoptimBatchTest'), 'The batch name value is missing from the summary');
        System.assert(summary.contains('Started From'), 'Started From is missing from the summary');
        System.assert(summary.contains('UnitTest'), 'The started from value is missing from the summary');
        System.assert(summary.contains('Source'), 'Source is missing from the summary');
        System.assert(summary.contains('Result'), 'Result is missing from the summary');
        System.assert(summary.contains('Log Summary'), 'Params and query section is missing from the summary');
        System.assert(summary.contains('TestLogParam'), 'The logged parameter is missing from the summary');
        System.assert(summary.contains('SELECT Id, Name FROM Account LIMIT 50'), 'The query is missing from the summary');
        System.assert(summary.contains(Label.MSG_TraceLogTooLong_CheckFile), 'The too-long note is missing from the summary');
        System.assert(!summary.contains('Row 1499:'), 'The raw trace must not be stored in the field');

        // The FileDirectory__c record
        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        FileDirectory__c fd = fds[0];
        System.assertEquals(Label.MSG_TraceLogTooLong_FileComment, fd.Comment__c, 'Comment__c is wrong');
        System.assertNotEquals(null, fd.ContentDocumentId__c, 'ContentDocumentId__c must be filled');
        System.assertEquals(log.Name, fd.DocumentName__c, 'DocumentName__c must be the log name');
        System.assertEquals(false, fd.IsPortalPublished__c, 'IsPortalPublished__c must be false');
        System.assertEquals(log.Id, fd.ParentId__c, 'ParentId__c must be the log Id');
        System.assertEquals('Other', fd.RecordType.DeveloperName, 'The record type must be Other');
        System.assertEquals('Other', fd.SubType__c, 'SubType__c must be Other');

        // The attached file is an .html holding the full raw trace
        ContentVersion file = getFile(fd);
        System.assert(file.Title.endsWith('.html'), 'The file must be an .html file');
        System.assert(file.PathOnClient.endsWith('.html'), 'The file path must end with .html');
        String html = file.VersionData.toString();
        System.assert(html.contains('Batch Name'), 'The file must hold the header');
        System.assert(html.contains('Batch Messages'), 'The file must hold the messages');
        System.assert(html.contains('Row 0:'), 'The first row is missing from the file');
        System.assert(html.contains('Row 1499:'), 'The file must hold the full raw trace');
        System.assert(!html.contains('omitted (volume exceeds'), 'Nothing must be omitted below the entry cap');

        // The Log__c is linked to the FileDirectory__c
        System.assertEquals(fd.Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');
        if (String.isNotBlank(fd.DownloadURL__c)) {
            System.assert(summary.contains('Download full trace log'), 'The link to the file must be appended to the summary');
        }
    }

    /**
     * @description Verifies that a Stateful log (errors) exceeding the threshold stores a summary in TraceLog__c,
     * attaches the full .html file and keeps the warnings count.
     */
    @isTest
    static void Case5_testBigStatefulErrors() {
        Id jobId = runStateful(1500, true);
        Log__c log = getLog(jobId);

        System.assertEquals(1500, log.NumberOfWarnings__c, 'One warning per logged line is expected');
        System.assert(log.TraceLog__c.length() <= maxSummarySize(), 'The summary must fit in the field');
        System.assert(log.TraceLog__c.contains(Label.MSG_TraceLogTooLong_CheckFile), 'The too-long note is missing from the summary');
        System.assert(!log.TraceLog__c.contains('Row 1499:'), 'The raw trace must not be stored in the field');

        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        System.assertEquals(fds[0].Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');
        String html = getFile(fds[0]).VersionData.toString();
        System.assert(html.contains('Warning messages:'), 'The file must hold the warnings');
        System.assert(html.contains('Row 1499:'), 'The file must hold the full raw trace');
    }

    /**
     * @description Verifies that a Stateless log (messages) exceeding the threshold stores a summary in TraceLog__c
     * and attaches the full .html file through a FileDirectory__c (RecordType and SubType Other).
     */
    @isTest
    static void Case6_testBigStatelessMessages() {
        Id jobId = runStateless(1500, false);
        Log__c log = getLog(jobId);

        System.assert(log.TraceLog__c.contains(Label.MSG_TraceLogTooLong_CheckFile), 'The too-long note is missing from the summary');
        System.assert(log.TraceLog__c.length() <= maxSummarySize(), 'The summary must fit in the field');
        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        System.assertEquals('Other', fds[0].RecordType.DeveloperName, 'The record type must be Other');
        System.assertEquals('Other', fds[0].SubType__c, 'SubType__c must be Other');
        System.assertEquals(fds[0].Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');
        System.assert(getFile(fds[0]).VersionData.toString().contains('Row 1499:'), 'The file must hold the full raw trace');
    }

    /**
     * @description Verifies that a Stateless log (errors) exceeding the threshold attaches the full .html file
     * and keeps the exact warnings count.
     */
    @isTest
    static void Case7_testBigStatelessErrors() {
        Id jobId = runStateless(1500, true);
        Log__c log = getLog(jobId);

        System.assertEquals(1500, log.NumberOfWarnings__c, 'The warnings count is wrong');
        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        System.assertEquals(fds[0].Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');
        System.assert(getFile(fds[0]).VersionData.toString().contains('Row 1499:'), 'The file must hold the full raw trace');
    }

    /**
     * @description Verifies that a Stateful log (messages) beyond the 5000-entry cap still gets its Log__c and its file,
     * that the file holds the exact number of omitted messages and ends with properly closed markup.
     */
    @isTest
    static void Case8_testExtremeStatefulMessages() {
        Id jobId = runStateful(7000, false);
        Log__c log = getLog(jobId);

        System.assert(log.TraceLog__c.length() <= maxSummarySize(), 'The summary must fit in the field');
        System.assert(log.TraceLog__c.contains(Label.MSG_TraceLogTooLong_CheckFile), 'The too-long note is missing from the summary');
        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'The Log must still get its file');
        System.assertEquals(fds[0].Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');

        String html = getFile(fds[0]).VersionData.toString();
        System.assert(html.contains('2000 message(s) omitted (volume exceeds'), 'The omitted count must be exact: 7000 logged - 5000 kept');
        System.assert(html.endsWith('</table>'), 'The file must end with properly closed markup');
        System.assert(html.countMatches('<tr>') <= 5002, 'The rows must be capped');
    }

    /**
     * @description Verifies that a Stateful log (errors) beyond the 5000-entry cap keeps the true warnings count
     * in NumberOfWarnings__c while the file is capped with an exact omitted note.
     */
    @isTest
    static void Case9_testExtremeStatefulErrors() {
        Id jobId = runStateful(7000, true);
        Log__c log = getLog(jobId);

        System.assertEquals(7000, log.NumberOfWarnings__c, 'The true count must be kept even when the stored entries are capped');
        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        String html = getFile(fds[0]).VersionData.toString();
        System.assert(html.contains('2000 warning message(s) omitted (volume exceeds'), 'The omitted count must be exact: 7000 logged - 5000 kept');
        System.assert(html.endsWith('<hr/>'), 'The file must end with properly closed markup');
    }

    /**
     * @description Verifies that a Stateless log (messages) beyond the 5000-entry cap gets its file
     * with the exact number of omitted messages.
     */
    @isTest
    static void Case10_testExtremeStatelessMessages() {
        Id jobId = runStateless(7000, false);
        Log__c log = getLog(jobId);

        List<FileDirectory__c> fds = getFileDirectories(log);
        System.assertEquals(1, fds.size(), 'One FileDirectory__c is expected');
        String html = getFile(fds[0]).VersionData.toString();
        System.assert(html.contains('2000 message(s) omitted (volume exceeds'), 'The omitted count must be exact: 7000 logged - 5000 kept');
        System.assertEquals(fds[0].Id, log.FileDirectory__c, 'Log__c.FileDirectory__c must be the new FileDirectory__c');
    }

    /**
     * @description Verifies that every job creates exactly one Log__c, and one FileDirectory__c only when it overflows.
     */
    @isTest
    static void Case11_testOneLogPerJob() {
        List<Id> jobIds = createCompletedJobs(2);
        Id smallJob = jobIds[0];
        Id bigJob = jobIds[1];
        saveLogFor(smallJob, NegoptimBatch.BatchType.Stateful, 50, false);
        saveLogFor(bigJob, NegoptimBatch.BatchType.Stateful, 1500, false);

        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE Apex_Job_ID__c = :String.valueOf(smallJob)], 'One Log__c is expected for the small job');
        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE Apex_Job_ID__c = :String.valueOf(bigJob)], 'One Log__c is expected for the big job');
        Log__c bigLog = getLog(bigJob);
        System.assertEquals(1, [SELECT COUNT() FROM FileDirectory__c WHERE ParentId__c = :bigLog.Id], 'One FileDirectory__c is expected for the big job');
    }
}