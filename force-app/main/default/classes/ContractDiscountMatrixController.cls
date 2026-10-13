/**
 * @author ULiT
 * @date 22/09/2025
 * @description used for manage ProductDiscountStatement__c
 **/
public with sharing class ContractDiscountMatrixController {

    @AuraEnabled
    public static String initData(Id recordId, String gridLayout) {
        try {
            String query = 'SELECT Id, Name, RecordType.DeveloperName FROM Contract__c WHERE Id = \'' + recordId + '\'';
            Contract__c contract = Database.query(query);
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            // get fields from Grid Settings
            if (String.isBlank(gridLayout)) {
                if (negoSettings.conditionManagerPageConfiguration != null && negoSettings.conditionManagerPageConfiguration.gridsConfiguration != null) {
                    if(negoSettings.conditionManagerPageConfiguration.gridsConfiguration.containsKey(contract.RecordType.DeveloperName)) {
                        gridLayout = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get(contract.RecordType.DeveloperName).mainGridSettings;
                    } else {
                        gridLayout = negoSettings.conditionManagerPageConfiguration.gridsConfiguration.get('DEFAULT').mainGridSettings;
                    }
                }
            }
            List<String> safeMasterStaticFields = new List<String> {
                SObjectType.Contract__c.fields.Name.Name
            };
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Contract__c.Name, '', String.join(safeMasterStaticFields, ', '), SObjectType.Contract_Discount__c.Name, '', '', gridLayout);
            MainWrapper mainWrapper = new MainWrapper(gridSettingsManager);
            if (gridSettingsManager.hasMaster) {
                /*List<String> bannerFields = new List<String>();
                for (GridSettingsManager.FieldWrapper bannerField : gridSettingsManager.BANNER_FIELDS) {
                    bannerFields.add(bannerField.fieldName.toLowerCase());
                    if (bannerField.stringFieldType == 'REFERENCE') {
                        String relationField = NegoptimHelper.getFieldNameAsRelation(bannerField.fieldName);
                        bannerFields.add((relationField + '.Name').toLowerCase());
                    }
                }
                for (String fieldName : gridSettingsManager.ALL_BANNER_FIELDS) {
                    if (!bannerFields.contains(fieldName.toLowerCase())) {
                        bannerFields.add(fieldName.toLowerCase());
                    }
                }*/
                String bannerQuery = 'SELECT ';
                bannerQuery += !gridSettingsManager.ALL_BANNER_FIELDS.isEmpty() ? String.escapeSingleQuotes(String.join(gridSettingsManager.ALL_BANNER_FIELDS, ',')) : 'id';
                bannerQuery += ' FROM ' + gridSettingsManager.Master_OBJECT_NAME;
                bannerQuery += ' WHERE Id = \'' + recordId + '\'';
                system.debug('bannerQuery >>> ' + bannerQuery);
                List<SObject> bannerList = Database.query(bannerQuery);
                SObject bannerRecord = (bannerList != null && !bannerList.isEmpty()) ? bannerList.get(0) : null;
                if (bannerRecord != null) {
                    gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(bannerRecord);
                }
                mainWrapper.bannerRecord = JSON.serialize(bannerRecord);
            } else {
                gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(contract);
                mainWrapper.bannerRecord = JSON.serialize(contract);
            }
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(Id recordId, String gridSettings, Integer pageSize, Integer pageNumber, String filters) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId);
            ConditionsWrapper conditionsWrapper = new ConditionsWrapper();
            String orderBy = 'Display_Order__c ASC NULLS FIRST';
            String query = gridSettingsManager.buildQueryWithUserFilters(null, conditions, orderBy, filters);
            system.debug('query >>> ' + query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            conditionsWrapper.records = setController.getRecords();
            conditionsWrapper.totalSize = setController.getResultSize();
            return JSON.serialize(conditionsWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String save(String recordsToUpdate, String recordsToInsert) {
        List<Contract_Discount__c> recordsToUpsert = new List<Contract_Discount__c>();
        if (String.isNotBlank(recordsToUpdate)) {
            recordsToUpsert.addAll((List<Contract_Discount__c>) JSON.deserialize(recordsToUpdate, List<Contract_Discount__c>.class));
        }
        if (String.isNotBlank(recordsToInsert)) {
            recordsToUpsert.addAll((List<Contract_Discount__c>) JSON.deserialize(recordsToInsert, List<Contract_Discount__c>.class));
        }
        return upsertWithErrors(recordsToUpsert);
    }
    
    public static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }

    public static List<String> getConditions(Id recordId) {
        try {
            List<String> conditions = new List<String>();
            if (recordId != null) {
                conditions.add('Contract__c = \'' + recordId + '\'');
            }
            conditions.add('Status__c <> \'Deleted\'');
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static String deleteConditions(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return 'No records provided to delete.';
        List<Contract_Discount__c> recordsToDelete = [SELECT Id, Status__c 
                                                      FROM Contract_Discount__c 
                                                      WHERE Id IN :recordIds];
        for (Contract_Discount__c rec : recordsToDelete) {
            rec.Status__c = 'Deleted';     
        }
        return upsertWithErrors(recordsToDelete);
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public String bannerRecord;
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
        }
    }

    public class ConditionsWrapper {
        public Integer totalSize {get; set;}
        public List<Contract_Discount__c> records {get; set;}
    }
}