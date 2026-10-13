/**
 * @author ULiT
 * @date 20/01/2025
 * @description used for manage ProductDiscountStatement__c
 **/
public with sharing class ProductDiscountStatementMatrixCtrl {

    @AuraEnabled
    public static String initData(Id recordId) {
        ResponseWrapper response = new ResponseWrapper();
        try {
            String query = 'SELECT RecordType.DeveloperName, Name, PromoStatementType__c, PromoAgreementType__c, Sender__c, Recipient__c, Supplier__c FROM ProductDiscountStatement__c WHERE Id = \'' + recordId + '\'';
            ProductDiscountStatement__c productDiscountStatement = Database.query(query);
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            response.showScan = negoSettings.productDiscountsConfiguration?.showScanButton;
            response.showSynchro = negoSettings.productDiscountsConfiguration?.showSynchroButton;
            String configKey;
            if (productDiscountStatement.RecordType.DeveloperName == 'Promo') {
                configKey = productDiscountStatement.RecordType.DeveloperName + '_' + productDiscountStatement.PromoStatementType__c + '_' + productDiscountStatement.PromoAgreementType__c;
            } else {
                configKey = productDiscountStatement.RecordType.DeveloperName;
            }
            NegoSettings.RecordTypeGridConfiguration recordTypeGridConfiguration = (negoSettings.productDiscountsConfiguration != null
                                                                            && negoSettings.productDiscountsConfiguration.productDiscountsConfigurationMap != null ?
                                                                            negoSettings.productDiscountsConfiguration.productDiscountsConfigurationMap.get(configKey) : null);
            if (Test.isRunningTest()) {
                recordTypeGridConfiguration = new NegoSettings.RecordTypeGridConfiguration();
                recordTypeGridConfiguration.gridSettings = 'PDSD';
            } else if (recordTypeGridConfiguration == null || String.isBlank(recordTypeGridConfiguration.gridSettings) || String.isBlank(recordTypeGridConfiguration.importSettings)) {
                response.errorMessage = System.Label.MSG_Error_Occured + ' : grid Configuration empty';
                return JSON.serialize(response);
            }
            // GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.ProductDiscountStatementDetail__c.Name, 'Id', recordTypeGridConfiguration.gridSettings);
            List<String> safeStaticFields = new List<String> {
                SObjectType.ProductDiscountStatementDetail__c.fields.Product__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.t_ScanResultsByColumn__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Status__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.ScanResults__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.SynchroResults__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.ScanStatus__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Contract__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.IsResponseSent__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.BDate__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.EDate__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_Condition__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionSellOut__c.Name,
                SObjectType.ProductDiscountStatementDetail__c.fields.Pol_Com_ConditionServices__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.ProductDiscountStatementDetail__c.fields.ProductDiscountStatement__c.Name) + '.' + SObjectType.ProductDiscountStatement__c.fields.PromoStatementType__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.ProductDiscountStatementDetail__c.fields.ProductDiscountStatement__c.Name) + '.' + SObjectType.ProductDiscountStatement__c.fields.PromoAgreementType__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.ProductDiscountStatementDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Hierarchy__c.Name,
                NegoptimHelper.getFieldNameAsRelation(SObjectType.ProductDiscountStatementDetail__c.fields.Product__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name
            };
            List<String> safeMasterStaticFields = new List<String> {
                SObjectType.ProductDiscountStatement__c.fields.PromoStatementType__c.Name,
                SObjectType.ProductDiscountStatement__c.fields.Sender__c.Name,
                SObjectType.ProductDiscountStatement__c.fields.Recipient__c.Name
            };
            Boolean isPortal = false;
            if (!Test.isRunningTest()) {
                Map<String, String> currentSession = Auth.SessionManagement.getCurrentSession();
                isPortal = currentSession != null && currentSession.get('SessionType') == 'ChatterNetworks';
            }
            response.isPortal = isPortal;
            Map<String, Schema.SObjectField> userFieldsMap = Schema.SObjectType.User.fields.getMap();
            if (userFieldsMap.containsKey('IsPortalEnabled')) {
                User currentUser = Database.query('SELECT IsPortalEnabled, Contact.Supplier__c FROM User WHERE Id = \'' + UserInfo.getUserId() + '\' LIMIT 1');
                response.isUserPortalEnabled = (Boolean) currentUser.get('IsPortalEnabled');
            } else {
                response.isUserPortalEnabled = false;
            }
            if (productDiscountStatement.Sender__c == 'Buyer') {
                response.havingRequestedLines = [SELECT COUNT() FROM ProductDiscountStatementDetail__c WHERE ProductDiscountStatement__c = :recordId AND Status__c = 'Requested'] > 0;
            }
            response.productDiscountStatement = productDiscountStatement;
            response.supplierContactUserId = [SELECT Id FROM User WHERE Contact.Supplier__c = :productDiscountStatement.Supplier__c LIMIT 1]?.Id;
            String layoutGrid = isPortal && String.isNotBlank(recordTypeGridConfiguration.communityGridSettings) ? recordTypeGridConfiguration.communityGridSettings : recordTypeGridConfiguration.gridSettings;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.ProductDiscountStatement__c.Name, '', String.join(safeMasterStaticFields, ', '), SObjectType.ProductDiscountStatementDetail__c.Name, '', String.join(safeStaticFields, ', '), layoutGrid);
            
            response.name = productDiscountStatement.Name;
            response.data = JSON.serialize(new MainWrapper(gridSettingsManager, isPortal ? recordTypeGridConfiguration.communityImportSettings : recordTypeGridConfiguration.importSettings));
            if (gridSettingsManager.hasMaster) {
                List<String> bannerFields = new List<String>();
                for (GridSettingsManager.FieldWrapper bannerField : gridSettingsManager.BANNER_FIELDS) {
                    bannerFields.add(bannerField.fieldName);
                    if (bannerField.stringFieldType == 'REFERENCE') {
                        String relationField = NegoptimHelper.getFieldNameAsRelation(bannerField.fieldName);
                        bannerFields.add(relationField + '.Name');
                    }
                }
                String bannerQuery = 'SELECT ';
                bannerQuery += !bannerFields.isEmpty() ? String.escapeSingleQuotes(String.join(bannerFields, ',')) : 'id';
                bannerQuery += ' FROM ' + gridSettingsManager.Master_OBJECT_NAME;
                bannerQuery += ' WHERE Id = \'' + recordId + '\'';
                List<SObject> bannerList = Database.query(bannerQuery);
                response.bannerRecord = JSON.serialize(bannerList != null && !bannerList.isEmpty() ? bannerList.get(0) : null);
                response.productDiscountStatement = bannerList != null && !bannerList.isEmpty() ? (ProductDiscountStatement__c) bannerList.get(0) : null;
            }
            return JSON.serialize(response);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            response.errorMessage += '\n' + e.getMessage();
            return JSON.serialize(response);
            //throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(Id recordId, String gridSettings, Integer pageSize, Integer pageNumber, String filters) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId, filters);
            PDSWrapper pdsWrapper = new PDSWrapper();
            NegoSettings negoSettings = NegoSettings.loadNegoSettings();
            String orderBy = 'Product__r.Hierarchy__c ASC NULLS FIRST, ';
            orderBy += 'Product__r.Name ASC NULLS FIRST, ';
            orderBy += 'Supplier__r.Name ASC NULLS FIRST, ';
            orderBy += 'NegoScope__c ASC NULLS FIRST, ';
            orderBy += 'Contract__c ASC NULLS FIRST, ';
            orderBy += 'ScanStatus__c ASC NULLS FIRST, ';
            orderBy += 'SynchroStatus__c ASC NULLS FIRST';
            String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
            system.debug('query >>> ' + query);
            List<ProductDiscountStatementDetail__c> PDSRecords = Database.query(query);
            Map<String, String> filtersMap = String.isNotBlank(filters) ? (Map<String, String>) JSON.deserialize(filters, Map<String, String>.class) : new Map<String, String>();
            Boolean isUserPortalEnabled = filtersMap.containsKey('isUserPortalEnabled') ? Boolean.valueOf(filtersMap.get('isUserPortalEnabled')) : false;
            String sender = filtersMap.containsKey('sender') ? filtersMap.get('sender') : null;
            //if (!isUserPortalEnabled) {
                for (ProductDiscountStatementDetail__c item : PDSRecords) {
                    pdsWrapper.allRecordIds.add(item.Id);
                    if (item.Status__c == 'Submitted' || (!isUserPortalEnabled && sender == 'Buyer' && (item.Status__c == 'InPreparation' || item.Status__c == 'InProcess') && (item.ScanStatus__c == 'Success' || item.ScanStatus__c == 'Warning'))) {
                        pdsWrapper.recordIdsToValidate.add(item.Id);
                    }
                    if (item.Status__c == 'Submitted') {
                        pdsWrapper.recordIdsToReject.add(item.Id);
                    }
                    if (!item.IsResponseSent__c && (item.Status__c == 'Validated' || item.Status__c == 'Rejected')) {
                        pdsWrapper.recordIdsToRespond.add(item.Id);
                    }
                    if ((item.ScanStatus__c == 'Success' || item.ScanStatus__c == 'Warning')
                        && (item.Status__c == 'InPreparation' || item.Status__c == 'Rejected' || item.Status__c == 'Updated' || (sender == 'Buyer' && item.Status__c == 'Requested'))) {
                        pdsWrapper.recordIdsToSubmit.add(item.Id);
                    }
                }
            //}
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            setController.setpageNumber(pageNumber);
            pdsWrapper.records = setController.getRecords();
            for (ProductDiscountStatementDetail__c item : pdsWrapper.records) {
                if (String.isNotBlank(item.ScanResults__c)) {
                    item.ScanResults__c = resolveLabels(item.ScanResults__c);
                }
                if (String.isNotBlank(item.SynchroResults__c)) {
                    item.SynchroResults__c = resolveLabels(item.SynchroResults__c);
                }
            }
            pdsWrapper.totalSize = setController.getResultSize();
            return JSON.serialize(pdsWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static String resolveLabels(String input) {
        Pattern p = Pattern.compile('\\{!([a-zA-Z0-9_]+)\\}');
        if (p != null) {
            Matcher m = p.matcher(input);
            String result = input;
            while (m.find()) {
                String key = m.group(1);
                String labelValue = NegoptimLabels.getCustomLabel(key, key);
                result = result.replace('{!'+key+'}', labelValue);
            }
            return result;
        }
        return input;
    }

    @AuraEnabled
	public static void updatePDSDStatus(List<Id> recordIdsToValidateOrReject, String status) {
        if (recordIdsToValidateOrReject != null && status != null) {
            List<ProductDiscountStatementDetail__c> recordsToUpdate = new List<ProductDiscountStatementDetail__c>();
            for (Id recordId : recordIdsToValidateOrReject) {
                recordsToUpdate.add(new ProductDiscountStatementDetail__c(Id = recordId, Status__c = status));
            }
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        }
    }

    @AuraEnabled
	public static String processRestForExcel(Id recordId, String gridSettings, String restURL) {
        String detailQuery = '';
        if (String.isBlank(restURL)) {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            List<String> conditions = getConditions(recordId, null);
            String orderBy = 'Product__r.Hierarchy__c ASC NULLS FIRST, ';
            orderBy += 'Product__r.Name ASC NULLS FIRST, ';
            orderBy += 'Supplier__r.Name ASC NULLS FIRST, ';
            orderBy += 'NegoScope__c ASC NULLS FIRST, ';
            orderBy += 'Contract__c ASC NULLS FIRST, ';
            orderBy += 'ScanStatus__c ASC NULLS FIRST, ';
            orderBy += 'SynchroStatus__c ASC NULLS FIRST';
            detailQuery = gridSettingsManager.buildQuery(null, conditions, orderBy);
        }
        String resultString = DataLoaderHelper.processRestForExcel(detailQuery, restURL, null, SObjectType.ProductDiscountStatementDetail__c.Name);
        DataLoaderHelper.RestResponseBody result = (DataLoaderHelper.RestResponseBody) JSON.deserialize(resultString, DataLoaderHelper.RestResponseBody.class);
        for (SObject record : result.records) {
            ProductDiscountStatementDetail__c item = (ProductDiscountStatementDetail__c) record;
            if (String.isNotBlank(item.ScanResults__c)) {
                item.ScanResults__c = resolveLabels(item.ScanResults__c);
            }
            if (String.isNotBlank(item.SynchroResults__c)) {
                item.SynchroResults__c = resolveLabels(item.SynchroResults__c);
            }
        }
        return JSON.serialize(result);
	}

    @AuraEnabled
	public static String deletePDSD(List<Id> selectedIds) {
        String recordsToDeleteError = 'SUCCESS';
        recordsToDeleteError = deleteWithErrors([SELECT Id FROM ProductDiscountStatementDetail__c WHERE Id IN :selectedIds], 'Id');
        return recordsToDeleteError;
    }

    public static List<String> getConditions(Id recordId, String filters) {
        try {
            List<String> conditions = new List<String>();
            Map<String, String> filtersMap = String.isNotBlank(filters) ? (Map<String, String>) JSON.deserialize(filters, Map<String, String>.class) : new Map<String, String>();
            Boolean isUserPortalEnabled = filtersMap.containsKey('isUserPortalEnabled') ? Boolean.valueOf(filtersMap.get('isUserPortalEnabled')) : false;
            String sender = filtersMap.containsKey('sender') ? filtersMap.get('sender') : null;
            List<FilterSettings> filterSettings = new List<FilterSettings>();
            if (filtersMap.containsKey('dynamic') && filtersMap.get('dynamic') != '[]' && filtersMap.get('dynamic') != null && filtersMap.get('dynamic') != '') {
                Object filterObject = JSON.deserializeUntyped(filtersMap.get('dynamic'));
                List<Object> filtersObjectsList = (List<Object>)filterObject;
                for (Object objt : filtersObjectsList) {
                    Map<String, Object> item = (Map<String, Object>)objt;
                    String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                    if (fieldName != null) {
                        String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                        String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                        boolean isEncrypted = item.containsKey('isEncrypted') ? Boolean.valueOf(item.get('isEncrypted')) : null;
                        String stringFieldType = item.containsKey('stringFieldType') ? String.valueOf(item.get('stringFieldType')) : null;
                        List<String> values = new List<String>();
                        if(item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                            List<Object> tempValues = (List<Object>) item.get('values');
                            for (Object val : tempValues) {
                                values.add(String.valueOf(val));
                            }
                        }
                        Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                        if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                            filterSettings.add(new FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                        }
                    }
                }
            }
            if (filtersMap.containsKey('scanStatus') && filtersMap.get('scanStatus') != '[]') {
                Object filterObject = JSON.deserializeUntyped(filtersMap.get('scanStatus'));
                List<Object> filtersObjectsList = (List<Object>)filterObject;
                List<String> scanStatusValues = new List<String>();
                for (Object objt : filtersObjectsList) {
                    scanStatusValues.add(String.valueOf(objt));
                }
                conditions.add('ScanStatus__c IN (\'' + String.join(scanStatusValues, '\', \'') + '\')');
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            if (recordId != null) {
                conditions.add('ProductDiscountStatement__c = \'' + recordId + '\'');
            }
            if ((isUserPortalEnabled && sender == 'Buyer') || (!isUserPortalEnabled && sender == 'Supplier')) {
                conditions.add('(IsResponseSent__c = true OR IsLineSubmitted__c = true)');
            }
            return conditions;
        } catch (Exception ex) {
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            return null;
        }
    }

    @AuraEnabled
    public static String loadBatchesHistory(Id recordId) {
        try {
            List<String> fieldNames = new List<String>{
                SObjectType.Batch__c.fields.JobName__c.Name,
                SObjectType.Batch__c.fields.Mode__c.Name,
                SObjectType.Batch__c.fields.RecordCount__c.Name,
                SObjectType.Batch__c.fields.DataSourceType__c.Name,
                SObjectType.Batch__c.fields.TaskType__c.Name,
                SObjectType.Batch__c.fields.Status__c.Name,
                SObjectType.Batch__c.fields.CreatedDate.Name
            };
            Schema.DescribeFieldResult dfr;
            Map<String, schema.SObjectField> batchFieldsMap = Batch__c.SObjectType.getDescribe().fields.getMap();
            List<HistoryBatchFieldWrapper> historyBatchFields = new List<HistoryBatchFieldWrapper>();
            for (String fieldName : fieldNames) {
                if (batchFieldsMap.containsKey(fieldName)) {
                    dfr = batchFieldsMap.get(fieldName).getDescribe();
                    historyBatchFields.add(new HistoryBatchFieldWrapper(dfr.getName(), dfr.getLabel(), dfr.getType().Name(), dfr.getScale(), dfr.isHtmlFormatted(), dfr.getPicklistValues()));
                    if (dfr.getType().Name() == 'REFERENCE') {
                        fieldNames.add(dfr.getName().replace('__c', '__r.Name').replace('Id', '.Name'));
                    }
                }
            }
            List<String> jobNames = new List<String>{
                PDSDSynchroBatch.class.getName(),
                PDSDScanBatch.class.getName(),
                ImportSettingsBatch.class.getName()
            };
            String query = 'SELECT ' + String.join(fieldNames, ', ');
            query += ' FROM Batch__c';
            query += ' WHERE JobName__c IN (\'' + String.join(jobNames, '\', \'') + '\')';
            query += ' AND ParentId__c = \'' + String.valueOf(recordId) + '\'';
            query += ' ORDER BY CreatedDate DESC';

            List<Batch__c> batches = Database.query(query);
            return JSON.serialize(new HistoryBatchWrapper(historyBatchFields, batches));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getImportOutcome(Id jobId) {
        // Defensive defaults
        Map<String, Object> res = new Map<String, Object>{
            'hasError' => false,
            'logName' => null,
            'logId' => null
        };
        if (String.isBlank(jobId)) return res;
        try {
            // Ensure Name is INCLUDED to avoid “SObject row… Name” errors
            List<Log__c> logList = [SELECT Id, Name, NumberOfErrors__c, NumberOfWarnings__c
                                    FROM Log__c
                                    WHERE Apex_Job_ID__c = :jobId
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];
            if (logList == null || logList.isEmpty()) return res;
            res.put('hasError', logList.get(0).NumberOfErrors__c > 0 || logList.get(0).NumberOfWarnings__c > 0);
            res.put('logName', logList.get(0).Name);
            res.put('logId', logList.get(0).Id);
            return res;
        } catch (Exception e) {
            // Keep it graceful instead of a hard exception
            return new Map<String, Object>{
                'hasError' => false,
                'logName' => null,
                'logId' => null
            };
        }
    }

    @AuraEnabled
    public static String saveData(Id recordId, String recordsToUpsertJSON) {
        List<ProductDiscountStatementDetail__c> PDSDsToUpdate = (List<ProductDiscountStatementDetail__c>) JSON.deserialize(recordsToUpsertJSON, List<ProductDiscountStatementDetail__c>.class);
        String message = upsertWithErrors(PDSDsToUpdate);
        Set<Id> PDSDIdSet = new Set<Id>();
        for (ProductDiscountStatementDetail__c item : PDSDsToUpdate) {
            PDSDIdSet.add(item.Id);
        }
        //scanPDSD(JSON.serialize(PDSDIdSet), recordId, false);
        if (message == 'SUCCESS') {
            return JSON.serialize(PDSDIdSet);
        } else {
        return message;
    }
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
    
    public static String deleteWithErrors(List<SObject> sObjectList, String identifier) {
        String errorMessage = 'SUCCESS';
        List<Database.DeleteResult> Results = Database.delete(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.DeleteResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                String sObjectIdentifier = (String) sObjectList[j]?.get(identifier);
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

    @AuraEnabled
    public static Id scanPDSD(String PDSDListJson, Id recordId, Boolean forceScan) {
        try {
            Set<Id> productDiscountStatementDetailsIdSet = (Set<Id>) JSON.deserialize(PDSDListJson, Set<Id>.class);
            // Set<Id> productDiscountStatementIdSet = (Set<Id>) JSON.deserialize(PDSListJson, Set<Id>.class);
            Batch__c batch = new Batch__c(JobName__c = PDSDScanBatch.class.getName(),
                                          Mode__c = 'Mass',
                                          RecordCount__c = 0,
                                          DataSourceType__c = 'Batch Apex',
                                          TaskType__c = 'Asynchron_Batch',
                                          Status__c = 'In Progress',
                                          ParentId__c = String.valueOf(recordId));
            insert batch;
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => ProductDiscountStatementMatrixCtrl.class.getName(),
                'productDiscountStatementIdSet' => new Set<Id> {recordId},
                'productDiscountStatementDetailsIdSet' => productDiscountStatementDetailsIdSet,
                'contractIdSet' => null,
                'batchId' => batch.Id,
                'forceScan' => forceScan
            };
            return NegoptimBatch.executeBatch('PDSDScanBatch', paramsMap, 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Id synchroPDSD(String PDSDListJson, Id recordId) {
        try {
            Set<Id> productDiscountStatementDetailsIdSet = (Set<Id>) JSON.deserialize(PDSDListJson, Set<Id>.class);
            // Set<Id> productDiscountStatementIdSet = (Set<Id>) JSON.deserialize(PDSListJson, Set<Id>.class);
            Batch__c batch = new Batch__c(JobName__c = PDSDSynchroBatch.class.getName(),
                                          Mode__c = 'Mass',
                                          RecordCount__c = 0,
                                          DataSourceType__c = 'Batch Apex',
                                          TaskType__c = 'Asynchron_Batch',
                                          Status__c = 'In Progress',
                                          ParentId__c = String.valueOf(recordId));
            insert batch;
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => ProductDiscountStatementMatrixCtrl.class.getName(),
                'productDiscountStatementIdSet' => new Set<Id> {recordId},
                'productDiscountStatementDetailsIdSet' => productDiscountStatementDetailsIdSet,
                'contractIdSet' => null,
                'batchId' => batch.Id
            };
            return NegoptimBatch.executeBatch('PDSDSynchroBatch', paramsMap, 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Id importPDSD(Id recordId, String recordsToUpsert, String fileName, String base64Data, String fileType, Id fileDirectoryId) {
        try {          
            List<SObject> upsertedRecords = (List<SObject>) JSON.deserialize(recordsToUpsert, List<SObject>.class);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => ProductDiscountStatementMatrixCtrl.class.getName(),
                'records' => upsertedRecords,
                'externalIDField' => ProductDiscountStatementDetail__c.ExtId__c,
                'fileName' => fileName,
                'recordId' => recordId,
                'fileDirectoryId' => fileDirectoryId
            };
            return NegoptimBatch.executeBatch('ImportSettingsBatch', paramsMap, 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + '-' + ex.getLineNumber());
        }
    }
    
    public class MainWrapper {
        public GridSettingsManager gridSettingsManagerPDS {get; set;}
        public String importSettings {get; set;}
        public MainWrapper(GridSettingsManager gridSettingsManagerPDS, String importSettings) {
            this.gridSettingsManagerPDS = gridSettingsManagerPDS;
            this.importSettings = importSettings;
        }
    }

    public class PDSWrapper {
        public Integer totalSize {get; set;}
        public List<Id> allRecordIds {get; set;}
        public List<Id> recordIdsToValidate {get; set;}
        public List<Id> recordIdsToReject {get; set;}
        public List<Id> recordIdsToRespond {get; set;}
        public List<Id> recordIdsToSubmit {get; set;}
        public List<ProductDiscountStatementDetail__c> records {get; set;}
        
        public PDSWrapper() {
            this.allRecordIds = new List<Id>();
            this.recordIdsToValidate = new List<Id>();
            this.recordIdsToReject = new List<Id>();
            this.recordIdsToRespond = new List<Id>();
            this.recordIdsToSubmit = new List<Id>();
            this.records = new List<ProductDiscountStatementDetail__c>();
        }
    }

    public class ResponseWrapper {
        public String name;
        public String data;
        public String bannerRecord;
        public ProductDiscountStatement__c productDiscountStatement;
        public Boolean isPortal;
        public Boolean showScan;
        public Boolean showSynchro;
        public Boolean isUserPortalEnabled;
        public String supplierContactUserId;
        public String errorMessage;
        public String prefix;
        public Boolean havingRequestedLines;
        public Boolean isAdmin;
        
        public ResponseWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.isAdmin = NegoptimHelper.isUserAdmin();
        }
    }

    public class HistoryBatchWrapper {
        public List<HistoryBatchFieldWrapper> fields;
        public List<Batch__c> records;
        
        public HistoryBatchWrapper(List<HistoryBatchFieldWrapper> fields, List<Batch__c> records) {
            this.fields = fields;
            this.records = records;
        }
    }

    public class HistoryBatchFieldWrapper {
        public String fieldName;
        public String fieldLabel;
        public String fieldType;
        public Integer scale;
        public Boolean isHTMLFormatted;
        public List<Map<String, String>> picklistValues;
        
        public HistoryBatchFieldWrapper(String fieldName, String fieldLabel, String fieldType, Integer scale, Boolean isHTMLFormatted, List<Schema.PicklistEntry> picklistValues) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.scale = scale;
            this.isHTMLFormatted = isHTMLFormatted;
            List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
            for (Schema.PicklistEntry entry : picklistValues) {
                Map<String, String> option = new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                };
                picklistOptions.add(option);
            }
            this.picklistValues = picklistOptions;
        }
    }
    
    public class FilterSettings {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean isEncrypted { get; set; }
        public String stringFieldType { get; set; }
        public List<SelectOption> pickListValues { get; set; }
        public String value1 { get; set; }
        public String value2 { get; set; }
        public List<String> values { get; set; }
        Boolean userFilterable { get; set; }
        public List<String> getQueryConditions() {
            try {
                List<String> conditions = new List<String>();
                if (values != null && !values.isEmpty()) {
                    if (stringFieldType == 'REFERENCE') {
                        if (fieldName.toLowerCase() == 'recordtypeid') {
                            List<String> stringifiedValues = (List<String>) JSON.deserialize(JSON.serialize(values), List<String>.class);
                            List<String> escapedStringifiedValues = new List<String>();
                            for (String value : stringifiedValues) {
                                value = value == 'Principal' || value == 'Master' ? '' : value;
                                escapedStringifiedValues.add(String.escapeSingleQuotes(value).trim());
                            }
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.DeveloperName IN (\'' + String.join(escapedStringifiedValues, '\', \'') + '\')');
                        } else {
                            if (isEncrypted == null || isEncrypted) {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                            } else {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                            }
                        }
                    }
                    if (stringFieldType == 'ID') {
                        List<Id> fieldpicklistValues = new List<Id>();
                        for (Object item : values) {
                            try {
                                fieldpicklistValues.add(Id.valueOf(String.escapeSingleQuotes(String.valueOf(item).trim())));
                            } catch (Exception ex) {
                            }
                        }
                        conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                    }
                    if (stringFieldType == 'PICKLIST' || stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'COMBOBOX' || stringFieldType == 'RECORDTYPE' || stringFieldType == 'BOOLEAN') {
                        List<String> fieldpicklistValues = new List<String>();
                        for (Object item : values) {
                            fieldpicklistValues.add(String.escapeSingleQuotes(String.valueOf(item)));
                        }
                        if (stringFieldType == 'BOOLEAN') {
                            conditions.add(fieldName + ' IN (' + String.join(fieldpicklistValues, ', ')+')');
                        } else if (stringFieldType == 'RECORDTYPE') {
                            conditions.add('RecordType.DeveloperName IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else if (stringFieldType == 'PICKLIST' || stringFieldType == 'COMBOBOX') {
                            conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else {
                            conditions.add(fieldName + ' INCLUDES (\'' + String.join(fieldpicklistValues, ';')+'\')');
                        }
                    }
                    if (stringFieldType == 'STRING') {
                        if (isEncrypted == null || isEncrypted) {
                            conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                        } else {
                            conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                        }
                    }
                }
                if (value1 != null || value2 != null) {
                    if (stringFieldType == 'CURRENCY' || stringFieldType == 'INTEGER' || stringFieldType == 'DOUBLE' || stringFieldType == 'LONG' || stringFieldType == 'PERCENT') {
                        if (value1 != null) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                    if (stringFieldType == 'DATETIME') {
                        if (value1 != null) {
                            List<String> splitedDate = String.valueOf(value1).split('-');
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                        if (value2 != null) {
                            List<String> splitedDate = String.valueOf(value2).split('-');
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                    }
                    if (stringFieldType == 'DATE') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
                        }
                    }
                    if (stringFieldType == 'TIME') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                }
                return conditions;
            }catch (Exception ex) {
                System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
        }
        public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values, Boolean userFilterable) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isEncrypted = isEncrypted;
            // Get the SObject Describe for the object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.ProductDiscountStatementDetail__c.Name).getDescribe();
            // Get the field describe for the specified field
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            // Get the data type of the field
            Schema.DisplayType fieldType = fieldDescribe.getType();
            this.stringFieldType = fieldType + '';
            this.pickListValues = pickListValues;
            this.value1 = value1;
            this.value2 = value2;
            this.values = values;
            this.userFilterable = userFilterable;
        }
    }
}