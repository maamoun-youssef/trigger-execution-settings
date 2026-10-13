/**
 * @author ULiT
 * @date 06/10/2023
 * @description Mass delete records
****************************************************************************************************************************************************************************** */
public class MassDeleteBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private string query;
    public MassDeleteBatch() {}
    public MassDeleteBatch(String startedFrom, String objectName, String filter) {
        this.nb = new NegoptimBatch(MassDeleteBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.query = 'SELECT Id FROM ' + objectName;
        if(filter == null) {
            this.query += ' WHERE Id = NULL';
        } else {
            this.query += ' WHERE ' + filter;
        }
        nb.logParameter('objectName', objectName);
        nb.logParameter('filter', filter);
        nb.logParameter('query', this.query );
    }
    
    // Start method..
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    // Execute method.
    public void execute(Database.BatchableContext bc, List<Sobject> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            // delete records
            List<Database.DeleteResult> results = Database.delete(scope, true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.DeleteResult result = results.get(i);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                    nb.logError(errorMessage);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.saveLog(bc);
    }

    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        String objectName = (String)paramsMap.get('objectName');
        String filter = (String)paramsMap.get('filter');
        return new MassDeleteBatch(startedFrom, objectName, filter);
    }
}