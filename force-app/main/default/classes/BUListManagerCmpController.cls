/*
 * @author ULiT
 * @date 04-02-2026
 * @description apex controller to manage BU List
 */ 
public with sharing class BUListManagerCmpController {
    
    public static String[] businessUnitFields = new String [] {
        SObjectType.BusinessUnit__c.fields.Id.Name,
        SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.IncludeNewBUs__c.Name,
            SObjectType.BusinessUnit__c.fields.t_BUAttributes__c.Name,
            SObjectType.BusinessUnit__c.fields.Format__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitRegion__c.Name,
            SObjectType.BusinessUnit__c.fields.Country__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
            SObjectType.BusinessUnit__c.fields.ManagementType__c.Name
            //SObjectType.BusinessUnit__c.fields.Attribute2_List__c.Name,
            //SObjectType.BusinessUnit__c.fields.Attribute3_List__c.Name
    };
    
    public static final String DEFAULT_BU_LIST_GRID = 'BUListGrid';
/**
     * @description get the grid settings template of the BU List Manager: the given layout first, then the
     * childrenBUDefaultGridSettingsTemplate of myOrg Settings (BUListManagerConfiguration__c), then the default 'BUListGrid'
     **/
    public static String getBUListGridSettingsName(String layout) {
        if (String.isNotBlank(layout)) {
            return layout;
        }
        OrgSettings orgSettings = OrgSettings.loadOrgSettings();
        if (orgSettings != null && orgSettings.buListManagerConfiguration != null
            && String.isNotBlank(orgSettings.buListManagerConfiguration.childrenBUDefaultGridSettingsTemplate)) {
            return orgSettings.buListManagerConfiguration.childrenBUDefaultGridSettingsTemplate;
        }
        return DEFAULT_BU_LIST_GRID;
    }

    @AuraEnabled
    public static String initData(String buId, String layout) {
        List<String> buFields = new List<String> {
            SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.Code__c.Name,
                SObjectType.BusinessUnit__c.fields.IncludeNewBUs__c.Name
        };
        // Create GridSettingsManager with the (potentially default) values
        layout = getBUListGridSettingsName(layout);
        GridSettingsManager gridSettingsManagerBUList = new GridSettingsManager(SObjectType.BusinessUnit__c.Name, '',  String.join(businessUnitFields, ','), layout);
        InitWrapper initWrapper = new InitWrapper();
        initWrapper.buFields = buFields;
        initWrapper.gridSettingsManagerBUList = gridSettingsManagerBUList;
        return JSON.serialize(initWrapper);
    }
    
    // This method returns the business unit information 
    @AuraEnabled
    public static string loadBURecord(String buId, List<String> buFields) {
        BusinessUnit__c bu;
        system.debug('buId >>> ' + buId);
        try {
            if (String.isNotBlank(buId)) {
                Set<String> queriedBUFields = new Set<String>();
                if (buFields != null && !buFields.isEmpty()) {
                    for (string item : buFields) {
                        queriedBUFields.add(item.toLowerCase());
                    }
                }
                if (businessUnitFields != null && !businessUnitFields.isEmpty()) {
                    for (string item : businessUnitFields) {
                        queriedBUFields.add(item.toLowerCase());
                    }
                }
                Map<String, Schema.SObjectField> mfields = Schema.getGlobalDescribe().get(SObjectType.BusinessUnit__c.Name).getDescribe().fields.getMap();
                for(String fieldName : mfields.keySet()) {
                    if (mfields.get(fieldName).getDescribe().isFilterable() && !queriedBUFields.contains(fieldName.toLowerCase())) {
                        queriedBUFields.add(fieldName.toLowerCase());
                    }
                }
                system.debug('queriedBUFields >>> ' + queriedBUFields);
                String query = 'SELECT RecordType.DeveloperName, Supplier__r.RecordTypeId, Supplier__r.Name,  Supplier__r.Code__c,';
                query += String.join(queriedBUFields, ', ');
                query += ' FROM BusinessUnit__c';
                query += ' WHERE Id = \'' + buId + '\'';
                query += ' LIMIT 1';
                system.debug('query >>> ' + query);
                bu = database.query(query);
            } else {
                // Case new Negoscope
                Map<String, Id> buRTMap = NegoptimHelper.getAvailableObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
                bu = (BusinessUnit__c) BusinessUnit__c.sObjectType.newSObject(buRTMap.get('List'), true);
                bu.RecordTypeId = buRTMap.get('List');
            }
            // Prepare MainWrapper with the appropriate values
            MainWrapper mainWrapper = new MainWrapper(bu);
            system.debug('bu >>> ' + bu);
            if (String.isNotBlank(buId)) {
                // get list of BULink__c
                for (BULink__c item : [SELECT Id, BusinessUnitDetail__c FROM BULink__c WHERE BusinessUnitMaster__c = :bu.Id WITH USER_MODE]) {
                    mainWrapper.selectedBUIds.add(item.BusinessUnitDetail__c);
                }
            }
            // Serialize and return MainWrapper
            return JSON.serialize(mainWrapper);
        } catch (DmlException ex) {
            throw new AuraHandledException(ex.getDmlMessage(0));
        } catch (QueryException qe) {
            NegoptimHelper.getInaccessibleFields(qe);
            throw new AuraHandledException(qe.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getBUList(String buJSON, Integer pageNumber, Integer pageSize, String filteredFieldsJSON, String filterAttrJSON, String layout) {
        QueriesWrapper queries = buildBUQuery(buJSON, filteredFieldsJSON, filterAttrJSON, layout);
        system.debug('queries >>>> ' + queries);
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(queries.query));
        List<Id> allBUIdList = new List<Id>((new Map<Id, BusinessUnit__c>((List<BusinessUnit__c>) Database.query(queries.query)))?.keySet());
        Map<Id, BusinessUnit__c> filteredBUMap = new Map<Id, BusinessUnit__c>((List<BusinessUnit__c>) Database.query(queries.respectFilterQuery));
        setController.setPageSize(pageSize);
        setController.setpageNumber(pageNumber);
        List<BusinessUnit__c> buList = setController.getRecords();
        List<BusinessUnitWrapper> buWrapperList = new List<BusinessUnitWrapper>();
        for (BusinessUnit__c bu : buList) {
            Boolean isUnFiltered = !filteredBUMap.containsKey(bu.Id);
            BusinessUnitWrapper buWrapper = new BusinessUnitWrapper(bu, !bu.BULNKBusinessUnitDetail__r.isEmpty(), isUnFiltered);
            buWrapperList.add(buWrapper);
        }
        BUTabWrapper buTabWrapper = new BUTabWrapper(buWrapperList, allBUIdList, setController.getResultSize());
        return JSON.serialize(buTabWrapper);
    }
    
    public static QueriesWrapper buildBUQuery(String buJSON, String filteredFieldsJSON, String filterAttrJSON, String layout) {
        BusinessUnit__c bu = (BusinessUnit__c) JSON.deserialize(buJSON, BusinessUnit__c.class);
        List<BusinessUnitServices.FieldWrapper> filteredFields = filteredFieldsJSON != null && filteredFieldsJSON != '' ? (List<BusinessUnitServices.FieldWrapper>) JSON.deserialize(filteredFieldsJSON, List<BusinessUnitServices.FieldWrapper>.class) : new List<BusinessUnitServices.FieldWrapper>();
        List<String> innerQueries = new List<String>();
        List<String> conditions = new List<String>();
        List<String> orConditions = new List<String>();
        BusinessUnitServices.BUQueryConditionsWrapper buQueryConditions = BusinessUnitServices.buildBUQueryConditions(buJSON, filteredFieldsJSON, filterAttrJSON);
        layout = getBUListGridSettingsName(layout);
        GridSettingsManager gridSettingsManagerBUList = new GridSettingsManager(SObjectType.BusinessUnit__c.Name, 'Id', layout);
        // add Inner Query
        if (bu != null && bu.Id != null) {
            List<Id> buIds = new List<Id>{ bu.Id };
            innerQueries.add('SELECT Id FROM BULNKBusinessUnitDetail__r where BusinessUnitMaster__c IN (\'' + String.join(buIds, '\',\'')+ '\')');
        }
        conditions = buQueryConditions.respectFilterQueryConditions;
        // Build Respect Filtered (Respect Filters) Query
        String respectFilterQuery = BusinessUnitServices.buildQuery(gridSettingsManagerBUList.ALL_FIELDS, innerQueries, conditions, null, buQueryConditions.filterAttributesConditions, buQueryConditions.filterAttributesLogic, '');
        // get the PGs already in NS and not matching the filters
        if (bu != null && bu.Id != null) {
            String queryBULink = 'SELECT BusinessUnitDetail__c FROM BULink__c';
            queryBULink += ' WHERE BusinessUnitMaster__c = \'' + bu.Id + '\'';
            if (filteredFields != null && filteredFields.size() > 0) {
                orConditions = new List<String>();
                for (BusinessUnitServices.FieldWrapper field : filteredFields) {
                    if (field.isEncrypted) {
                        orConditions.add('BusinessUnitDetail__r.' + (field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' = \'' + String.escapeSingleQuotes(field.filterValue) + '\'');
                    } else {
                        orConditions.add('BusinessUnitDetail__r.' + (field.fieldType == 'REFERENCE' ? field.fieldName.replace('__c', '__r') + '.Name' : field.fieldName ) + ' LIKE \'%' + String.escapeSingleQuotes(field.filterValue) + '%\'');
                    }
                }
                queryBULink += ' AND (' + String.join(orConditions, ' OR ') + ')';
            }
            List<BULink__c> buLinkList = Database.query(queryBULink);
            List<String> buIdList = new List<String>();
            if (!buLinkList.isEmpty()) {
                for (BULink__c item : buLinkList) {
                    buIdList.add(item.BusinessUnitDetail__c);
                }
            }
            orConditions = new List<String>();
            orConditions.add('(Id IN (\'' + String.join(buIdList, '\', \'') + '\'))');
        }
        // Build Query
        String query = BusinessUnitServices.buildQuery(gridSettingsManagerBUList.ALL_FIELDS, innerQueries, conditions, orConditions, buQueryConditions.filterAttributesConditions, buQueryConditions.filterAttributesLogic, '');
        QueriesWrapper queries = new QueriesWrapper(respectFilterQuery, query);
        return queries;
    }
    
    @AuraEnabled
    public static String saveBU(String buJSON, String buAttributesJSON, String buLinkListToDeleteJSON,
                                       String buLinkListToAddJSON, List<String> buFields)
    {
        System.SavePoint sp = Database.setSavepoint();
        try {
            BusinessUnit__c bu = (BusinessUnit__c) JSON.deserialize(buJSON, BusinessUnit__c.class);
            if (buFields != null && !buFields.isEmpty()) {
                for (String fieldName : buFields) {
                    bu.put(fieldName, bu.get(fieldName));
                }                
            }
            // BU Attributes
            bu.t_BUAttributes__c = buAttributesJSON;
            Database.UpsertResult resultBU = Database.upsert(bu, false);
            if (!resultBU.isSuccess()) {
                Database.Error[] errors = resultBU.getErrors();
                String errorMessage = '';
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
                System.debug('Error >>>' + errorMessage);
                AuraHandledException auraException = new AuraHandledException(errorMessage);
                auraException.setMessage(errorMessage);
                throw auraException;
            }
            // HANDLE BU Links
            List<BULink__c> insertedBULinks = new List<BULink__c>();
            List<BULink__c> updatedBULinks = new List<BULink__c>();
            List<BULink__c> deletedBULinks = new List<BULink__c>();
            Map<String, BULink__c> existingBULinksMap = new Map<String, BULink__c>();
            List<BULink__c> buLinkList = [SELECT Id, BusinessUnitMaster__c, BusinessUnitDetail__c FROM BULink__c WHERE BusinessUnitMaster__c = :bu.Id WITH USER_MODE];
            for(BULink__c item : buLinkList) {
                existingBULinksMap.put(item.BusinessUnitMaster__c + '' + item.BusinessUnitDetail__c, item);
            }
            Set<Id> buLinkListToDelete = String.isNotBlank(buLinkListToDeleteJSON) ? (Set<Id>) JSON.deserialize(buLinkListToDeleteJSON, Set<Id>.class) : new Set<Id>();
            if (!buLinkListToDelete.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(BULink__c.SObjectType)) {
                    List<BULink__c> bulinks = [SELECT Id FROM BULink__c WHERE BusinessUnitDetail__c IN :buLinkListToDelete AND BusinessUnitMaster__c = :bu.Id WITH USER_MODE];
                    List<Database.DeleteResult> results = Database.delete(bulinks, false);
                }
            }
            Set<Id> buLinkListToAdd = String.isNotBlank(buLinkListToAddJSON) ? (Set<Id>) JSON.deserialize(buLinkListToAddJSON, Set<Id>.class) : new Set<Id>();
            if (!buLinkListToAdd.isEmpty()) {
                for (Id buDetailId : buLinkListToAdd) {
                    String key = bu.Id + '' + Id.valueOf(buDetailId);
                    BULink__c BULink;
                    if (!existingBULinksMap.containsKey(key)) {
                        BULink = new BULink__c(BusinessUnitDetail__c = buDetailId, BusinessUnitMaster__c = bu.Id);
                        insertedBULinks.add(BULink);
                    } else {
                        BULink = existingBULinksMap.get(key);
                        updatedBULinks.add(BULink);
                        existingBULinksMap.remove(key);
                    }
                }
            }
            if (!insertedBULinks.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(insertedBULinks, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    BULink__c record = insertedBULinks.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = '';
                        errorMessage += (record + '\n');
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        AuraHandledException auraException = new AuraHandledException(errorMessage);
                        auraException.setMessage(errorMessage);
                        throw auraException;
                        //throw new AuraHandledException(errorMessage);
                    }
                }
            }
            if (!updatedBULinks.isEmpty()) {
                List<Database.SaveResult> results = Database.update(updatedBULinks, true);
            }
            return JSON.serialize(bu);
        } catch(DMLException ex) {
            Database.rollback(sp);
            System.debug('ERROR >>> ' + ex.getDmlMessage(0) + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getDmlMessage(0) + ' - ' + ex.getLineNumber());
        } catch(QueryException qe) {
            Database.rollback(sp);
            NegoptimHelper.getInaccessibleFields(qe);
            throw new AuraHandledException(qe.getMessage());
        } catch(AuraHandledException ex) {
            Database.rollback(sp);
            System.debug('ERROR >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            throw ex;
        } catch(Exception ex) {
            Database.rollback(sp);
            System.debug('ERROR >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber() + ' - ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }
    @AuraEnabled
    public static String selectOnlyRespectBUs(String buJSON, String filteredFieldsJSON, String filterAttrJSON, String layout) {
        try {
            BusinessUnit__c bu = (BusinessUnit__c) JSON.deserialize(buJSON, BusinessUnit__c.class);
            QueriesWrapper queries = buildBUQuery(buJSON, filteredFieldsJSON, filterAttrJSON, layout);
            Map<Id, BusinessUnit__c> filteredBULinkMap = new Map<Id, BusinessUnit__c>((List<BusinessUnit__c>) Database.query(queries.respectFilterQuery));
            List<BULink__c> BulinkList = [SELECT BusinessUnitDetail__c FROM BULink__c
                                          WHERE BusinessUnitMaster__c = :bu.Id
                                          AND BusinessUnitDetail__c NOT IN :filteredBULinkMap.keySet()
                                          WITH USER_MODE];
            List<String> buIdListToDelete = new List<String>();
            if (!BulinkList.isEmpty()) {
                for (BULink__c item : BulinkList) {
                    buIdListToDelete.add(item.BusinessUnitDetail__c);
                }
            }
            return JSON.serialize(new SelectedBUs(new List<Id>(filteredBULinkMap.keySet()), buIdListToDelete));
        } catch (QueryException qe) {
            NegoptimHelper.getInaccessibleFields(qe);
            throw new AuraHandledException(qe.getMessage());
        }
    }
    
    public class QueriesWrapper {
        public String respectFilterQuery;
        public String query;
        public QueriesWrapper(String respectFilterQuery, String query) {
            this.respectFilterQuery = respectFilterQuery;
            this.query = query;
        }
    }
    
    public class BusinessUnitWrapper {
        public BusinessUnit__c bu {get; set;}
        public Boolean selected {get; set;}
        public BULink__c buLink {get; set;}
        public Boolean isUnFiltered {get; set;}
        public BusinessUnitWrapper(BusinessUnit__c bu, Boolean selected, Boolean isUnFiltered) {
            this.buLink = null;
            this.bu = bu;
            this.selected = selected;
            this.isUnFiltered = isUnFiltered;
        }
    }
    
    public class BUTabWrapper {
        public List<BusinessUnitWrapper> buList {get; set;}
        public List<Id> allBUIdList {get; set;}
        public Integer totalNumbOfRecords {get; set;}
        public BUTabWrapper() {}
        public BUTabWrapper(List<BusinessUnitWrapper> buList, List<Id> allBUIdList, Integer totalNumbOfRecords) {
            this.buList = buList;
            this.allBUIdList = allBUIdList;
            this.totalNumbOfRecords = totalNumbOfRecords;
        }
    }
    public class SelectedBUs {
        public List<Id> busToAdd {get; set;}
        public List<Id> busToDelete {get; set;}
        
        public SelectedBUs(List<Id> busToAdd, List<Id> busToDelete) {
            this.busToAdd = busToAdd;
            this.busToDelete = busToDelete;
        }
    }
    
    public class InitWrapper {
        public GridSettingsManager gridSettingsManagerBUList {get; set;}
        public List<String> buFields {get; set;}
        
        public InitWrapper() {}
    }
    
    public class MainWrapper {
        public BusinessUnit__c bu {get; set;}
        BUTabWrapper buData {get; set;}
        String displayedBUFields {get; set;}
        public List<Id> selectedBUIds {get; set;}
        public MainWrapper(BusinessUnit__c bu) {
            this.bu = bu;
            this.buData = new BUTabWrapper();
            this.selectedBUIds = new List<Id>();
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;

        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}