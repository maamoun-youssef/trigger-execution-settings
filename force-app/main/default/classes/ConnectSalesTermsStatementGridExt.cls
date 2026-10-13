/**
 * @author ULiT
 * @date 08/09/2025
 * @description used for manage ConnectSalesTermsStatementGrid
 **/
public class ConnectSalesTermsStatementGridExt {

    @AuraEnabled
    public static String initData() {
        try {
            Boolean isPortal = false;
            if (!Test.isRunningTest()) {
                Map<String, String> currentSession = Auth.SessionManagement.getCurrentSession();
                isPortal = currentSession != null && currentSession.get('SessionType') == 'ChatterNetworks';
            }
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.TMP_ServiceStatement__c.Name, '', '', '', '', '', 'ConnectSalesTermsStatement_Grid');
            return JSON.serialize(new MainWrapper(gridSettingsManager, isPortal));
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(String gridSettings, Integer pageSize, Integer pageNumber) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            SSWrapper wrapper = new SSWrapper();
            String query = gridSettingsManager.buildQuery(null, null, null);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setPageNumber(pageNumber);
            wrapper.records = (List<TMP_ServiceStatement__c>) setController.getRecords();
            wrapper.totalSize = setController.getResultSize();
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String save(String dataToSave) {
        String errorMessage = '';
        System.debug('dataToSave: ' + dataToSave);
        List<TMP_ServiceStatement__c> recordsToSave =
            (List<TMP_ServiceStatement__c>) JSON.deserialize(dataToSave, List<TMP_ServiceStatement__c>.class);

        if (!recordsToSave.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(recordsToSave, false);
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                }
            }
        }
        System.debug('errorMessage >>> ' + errorMessage);
        return errorMessage;
    }


    public class MainWrapper {
        public GridSettingsManager gridSettingsManager { get; set; }
        public Boolean isPortal { get; set; }
        public MainWrapper(GridSettingsManager gridSettingsManager, Boolean isPortal) {
            this.gridSettingsManager = gridSettingsManager;
            this.isPortal = isPortal;
        }
    }

    public class SSWrapper {
        @AuraEnabled public List<TMP_ServiceStatement__c> records { get; set; }
        @AuraEnabled public Integer totalSize { get; set; }
    }
}