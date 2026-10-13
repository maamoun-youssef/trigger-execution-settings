global class SaveLogBatchExample implements Database.Batchable<SObject>, Database.Stateful {

    private String query;
    private Integer errorLineCount;
    private Boolean useErrorChannel;
    private NegoptimBatch nb;
    private Integer paddingLinesLogged = 0;

    global SaveLogBatchExample() {
        this('Test startedFrom', 'This is a log param test', 0, false);
    }

    global SaveLogBatchExample(Integer errorLineCount) {
        this('Test startedFrom', 'This is a log param test', errorLineCount, false);
    }

    global SaveLogBatchExample(String startedFrom, String TestLogParam, Integer errorLineCount, Boolean useErrorChannel) {
        this.nb = new NegoptimBatch(SaveLogBatchExample.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.errorLineCount = errorLineCount;
        this.useErrorChannel = useErrorChannel;
        this.query = 'SELECT Id, Name FROM Account LIMIT 50';
        nb.logParameter('TestLogParam', TestLogParam);
        nb.logParameter('query', query);
        nb.logParameter('targetOverflowLines', errorLineCount);
        nb.logParameter('useErrorChannel', useErrorChannel);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name
            FROM Account
            LIMIT 50
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (nb == null) {
            nb = new NegoptimBatch('SaveLogBatchExample DHA', NegoptimBatch.BatchType.Stateless, 'SaveLogBatchExample');
            nb.logParameter('batchSize', scope.size());
        }
        Integer linesPerChunk = errorLineCount > 0 ? Integer.valueOf(Math.max(1, Math.ceil(errorLineCount / 50.0))) : 0;
        for (SObject recordItem : scope) {
            Account acc = (Account) recordItem;
            String line = 'Account ' + acc.Id + ' (' + acc.Name + '): DUPLICATE_VALUE on Account.Name - duplicates value on record with id: ' + acc.Id;
            if (useErrorChannel) {
                nb.logError(line);
            } else {
                nb.logMessage(line);
            }
            for (Integer i = 0; i < linesPerChunk && paddingLinesLogged < errorLineCount; i++) {
                String paddingLine = 'Row ' + paddingLinesLogged + ': VALIDATION_ERROR on AssortmentDetail__c - required field missing for product SKU-' + (100000 + paddingLinesLogged) + ' in scope NEG-2026-' + (Math.mod(paddingLinesLogged, 47) + 1);
                if (useErrorChannel) {
                    nb.logError(paddingLine);
                } else {
                    nb.logMessage(paddingLine);
                }
                paddingLinesLogged++;
            }
        }
        nb.incrementBatchIndex();
    }

    global void finish(Database.BatchableContext bc) {
        if (nb == null) {
            nb = new NegoptimBatch('SaveLogBatchExample DHA', NegoptimBatch.BatchType.Stateless, 'SaveLogBatchExample');
            nb.logParameter('query', 'SELECT Id, Name FROM Account LIMIT 50');
            nb.logParameter('batchSize', 1);
            nb.logParameter('targetOverflowLines', errorLineCount);
        }
        nb.saveLog(bc);
    }
}