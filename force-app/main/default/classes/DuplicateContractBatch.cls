/**
 * Batchable class used to duplicate contracts.
 * Works for single or multiple contract duplication procedure.
 **/
public with sharing class DuplicateContractBatch implements Database.Batchable<SObject>, Database.Stateful, BatchFactory {

    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final Set<Id> contractInsertedIds;
    public final Integer year;
    // public final Boolean isMultiYear;
    // variables to use internally
	public Date commercialBDate;
	public Date commercialEDate;
    public Id recordTypeId;
    public String recordTypeDeveloperName;
    private static Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);

    // Empty constructor for BatchFactory
    public DuplicateContractBatch(){}
    // Constructor
    public DuplicateContractBatch(String startedFrom, Id countryId, List<Id> contractIds, Integer year, Date commercialBeginDate, Date commercialEndDate, String recordTypeDeveloperName) {
        this.nb = new NegoptimBatch(DuplicateContractBatch.class.getName(), NegoptimBatch.BatchType.stateful, startedFrom);
        this.country = countryId;
        this.contractIds = contractIds;
        this.contractInsertedIds = new Set<Id>();
        // this.year = year == null ? Date.today().year() : year;
        this.year = year;
        this.commercialBDate = commercialBeginDate;
        this.commercialEDate = commercialEndDate;
        this.recordTypeDeveloperName = recordTypeDeveloperName;
        this.recordTypeId = contractRTIds.get(recordTypeDeveloperName);
        NegoSettings negoSettings = NegoSettings.loadNegoSettings();
        List<NegoSettings.ContractDuplicationWrapper> contractDuplicationConfigurationList = (List<NegoSettings.ContractDuplicationWrapper>) negoSettings.contractDuplicationConfiguration;
        List<String> orConditions = new List<String>();
        String q = 'SELECT Id';
        q += ' FROM Contract__c';
        q += ' WHERE Supplier__r.Status__c = \'Active\' ';
        q += ' AND Supplier_Nego_Scope__r.Status__c = \'Active\' ';
        q += ' AND BusinessUnitContract__r.Status__c = \'Open\'';
        if(contractDuplicationConfigurationList != null && !contractDuplicationConfigurationList.isEmpty()) {
            for (NegoSettings.ContractDuplicationWrapper contractDuplicationConfiguration : contractDuplicationConfigurationList) { 
                List<String> conditions = new List<String>();
                if (String.isNotBlank(contractDuplicationConfiguration.status)) {
                    conditions.add('Status__c = \'' + String.escapeSingleQuotes(contractDuplicationConfiguration.status) + '\'');
                }
                if (String.isNotBlank(contractDuplicationConfiguration.recordType)) {
                    conditions.add('RecordType.DeveloperName = \'' + String.escapeSingleQuotes(contractDuplicationConfiguration.recordType) + '\'');
                }
                if (!conditions.isEmpty()) {
                    orConditions.add('( ' + String.join(conditions, ' AND ') + ' )');
                }
            }
            if (!orConditions.isEmpty()) {
                q += ' AND ( ' + String.join(orConditions, ' OR ') + ' )';
            }     
        }
        //q += ' AND Status__c IN (\'Balanced\', \'Signed\')';
        //q += ' AND RecordType.DeveloperName = \'Signed\'';
        if (country != null) {
            q += ' AND BusinessUnitContract__c = \'' + country + '\'';
        }
        if (contractIds != null && !contractIds.isEmpty()) {
            q += ' AND Id IN (\'' + String.join(contractIds, '\',\'') +'\')';
        }
        if (year != null) {
            q += ' AND Reference_Year__c = ' + year;
        }
        // Set the final variable.
        query = q;
        System.debug('query >>> ' + query);
        nb.logParameter('country', country);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('year', year);
        nb.logParameter('commercialBDate', commercialBDate);
        nb.logParameter('commercialEDate', commercialEDate);
        nb.logParameter('recordTypeDeveloperName', recordTypeDeveloperName);
        nb.logParameter('recordTypeId', recordTypeId);
        nb.logParameter('query', query);
    }

	// Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String[] contractFields = new String[] {
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
            SObjectType.Contract__c.fields.Status__c.Name,
            SObjectType.Contract__c.fields.Supplier__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name,
            SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name
        };
        String[] negoScopeFields = new String[] {
            SObjectType.NegoScope__c.fields.Id.Name,
            SObjectType.NegoScope__c.fields.Status__c.Name
        };
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Id.Name,
            SObjectType.BusinessUnit__c.fields.Status__c.Name
        };
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.Id.Name,
            SObjectType.Supplier__c.fields.Status__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
           && NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)
           && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
           && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields))
        {
            return Database.getQueryLocator(query);
        } else {
            return null;
        }
    }

    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        ContractServices.DuplicateContractResultWrapper duplicateContractResultWrapper = ContractServices.duplicateContract(scope, this.recordTypeDeveloperName, this.country, this.year, this.commercialBDate, this.commercialEDate, this.nb);
        this.contractInsertedIds.addAll(duplicateContractResultWrapper.contractInsertedIds);
    }

    // Finish method.
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        try {
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                SObjectType.BusinessUnit__c.fields.Name.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
                if (country != null) {
                    countryName = [SELECT Id, Name FROM BusinessUnit__c WHERE Id = :country LIMIT 1]?.Name;
                }
            }
        } catch(DmlException e) {
            System.debug('e >>' + e.getMessage() + '  >>>  ' + e.getStackTraceString());
            nb.logError(e);
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ this.year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, '', customSubject);
        // execute InitContractSellInBatch
        if (!this.contractInsertedIds.isEmpty() && !Test.isRunningTest()) {
            // check duplicated Contracts NS RT
            List<Contract__c> insertedContracts = [SELECT Id, RecordType.DeveloperName
                                                   FROM Contract__c
                                                   WHERE Id IN :this.contractInsertedIds];
            Set<Id> advancedContractIds = new Set<Id>();
            Set<Id> regularContractIds = new Set<Id>();
            for (Contract__c item : insertedContracts) {
                if (item.RecordType.DeveloperName == 'Advanced') {
                    advancedContractIds.add(item.Id);
                } else {
                    regularContractIds.add(item.Id);                    
                }
            }
            if (!advancedContractIds.isEmpty()) {
                // execute AdvancedContractSynchroBatch
                NegoptimBatch.executeBatch(new AdvancedContractSynchroBatch(DuplicateContractBatch.class.getName(), advancedContractIds), 1);
            }
            if (!regularContractIds.isEmpty()) {
                Map<String, Object> paramsMap = new Map<String, Object> {
                    'startedFrom' => DuplicateContractBatch.class.getName(),
                    'contractIds' => regularContractIds
                };
                NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 1);
            }
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Id countryId = (Id)paramsMap.get('countryId');
        List<Id> contractIds = (List<Id>)paramsMap.get('contractIds');
        Integer year = (Integer)paramsMap.get('year');
        Date commercialBeginDate = (Date)paramsMap.get('commercialBeginDate');
        Date commercialEndDate = (Date)paramsMap.get('commercialEndDate');
        String recordTypeDeveloperName = (String)paramsMap.get('recordTypeDeveloperName');
        return new DuplicateContractBatch(startedFrom, countryId, contractIds, year, commercialBeginDate, commercialEndDate, recordTypeDeveloperName);
    }
}