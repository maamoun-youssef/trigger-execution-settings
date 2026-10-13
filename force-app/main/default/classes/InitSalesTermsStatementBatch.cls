/**
 * @author ULiT
 * @date 01/09/2025
 * @description Initialize Sales Terms Statement records (NS-level or Supplier-level)
 */
public class InitSalesTermsStatementBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable, BatchFactory {
    
    private NegoptimBatch nb;
    private String query;
    private Boolean isNSLevel;
    private ServiceStatementSettings serviceStatementSetting;
    private static Id salesTermsStmtRecordTypeId = NegoptimHelper.getObjectRecordTypeId(TMP_ServiceStatement__c.SObjectType, 'SalesTerms');
 
    @testVisible private static Boolean TEST_ForceNSLevel;
    @testVisible private static Boolean TEST_ForceSchedulerRun;
    
    public InitSalesTermsStatementBatch() {}

    public InitSalesTermsStatementBatch(String startedFrom, Id supplierId) {
        nb = new NegoptimBatch(InitSalesTermsStatementBatch.class.getName(), NegoptimBatch.BatchType.Stateful, startedFrom);
        this.serviceStatementSetting = ServiceStatementSettings.loadServiceStatementSettings('SalesTerms');
        this.isNSLevel = (serviceStatementSetting != null && serviceStatementSetting.isNSLevel == true);
        if (Test.isRunningTest() && TEST_ForceNSLevel != null) {
            this.isNSLevel = TEST_ForceNSLevel;
        }
        if (this.isNSLevel) {
            this.query  = 'SELECT Id, Status__c, RecordType.DeveloperName, ContractingLevel__c, ';
            this.query += 'Supplier__c, Supplier__r.ReferenceLanguage__c, BusinessUnit__c, Supplier__r.BusinessUnitOrigin__c, Supplier__r.Account__c, ';
            this.query += '(SELECT Id, NegoScopeDetail__c FROM NSLNKNegoScopeMaster__r), ';
            this.query += '(SELECT Id, NegoScopeMaster__c FROM NSLNKNegoScopeDetail__r) ';
            this.query += 'FROM NegoScope__c ';
            this.query += 'WHERE Status__c = \'Active\' ';
            this.query += 'AND ( (RecordType.DeveloperName = \'Advanced\' AND ContractingLevel__c = \'AdvancedOnly\') ';
            this.query += ' OR (RecordType.DeveloperName = \'Regular\') )';
            if (supplierId != null) {
                this.query += ' AND Supplier__c = \'' + String.valueOf(supplierId) + '\'';
            }
        } else {
            this.query  = 'SELECT Id, Status__c, Name, BusinessUnitOrigin__c, ReferenceLanguage__c, Account__c ';
            this.query += 'FROM Supplier__c ';
            this.query += 'WHERE Status__c = \'Active\'';
            if (supplierId != null) {
                this.query += ' AND Id = \'' + String.valueOf(supplierId) + '\'';
            }
        }
        
        nb.logParameter('query', this.query);
        nb.logParameter('supplierId', supplierId);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Integer nextYear = Date.today().year() + 1;
        Date closingDate;
        Integer m = (serviceStatementSetting.annualClosingMonth == null) ? 12 : Integer.valueOf(serviceStatementSetting.annualClosingMonth);
        Integer d = (serviceStatementSetting.annualClosingDay == null) ? 31 : Integer.valueOf(serviceStatementSetting.annualClosingDay);
        Integer maxDay = Date.daysInMonth(nextYear, m);
        if (d > maxDay) d = maxDay;
        closingDate = Date.newInstance(nextYear, m, d);
        System.SavePoint ssp = Database.setSavepoint();
        try {   
            List<TMP_ServiceStatement__c> serviceStatementListToUpsert = new List<TMP_ServiceStatement__c>();
            Map<Id, Id> supplierToAccount = new Map<Id, Id>();
            Set<Id> accountIds = new Set<Id>();
            if (this.isNSLevel) {
                List<NegoScope__c> negoScopesInScope = (List<NegoScope__c>) scope;
                List<NegoScope__c> targetNsRecords = new List<NegoScope__c>();
                Set<Id> supplierIds = new Set<Id>();
                for (NegoScope__c ns : negoScopesInScope) {
                    if ((ns.RecordType.DeveloperName == 'Advanced' && ns.NSLNKNegoScopeDetail__r.size() > 0)
                        || (ns.RecordType.DeveloperName == 'Regular' && ns.NSLNKNegoScopeMaster__r.size() == 0))
                    {
                        targetNsRecords.add(ns);
                        if (ns.Supplier__c != null) {
                            supplierIds.add(ns.Supplier__c);
                        }
                    }
                }
                if (targetNsRecords.isEmpty()) return;
                List<TMP_ServiceStatement__c> existingServiceStatementList = [SELECT Id, Supplier__c, NegoScope__c, BusinessUnitTarget__c, Year__c, RecordTypeId, Status__c
                                                                              FROM TMP_ServiceStatement__c
                                                                              WHERE Year__c = :nextYear
                                                                              AND RecordTypeId = :salesTermsStmtRecordTypeId
                                                                              AND NegoScope__c IN :targetNsRecords
                                                                              AND Supplier__c IN :supplierIds
                                                                              AND Status__c NOT IN ('Closed', 'Validated')];
                Map<String, TMP_ServiceStatement__c> existingServiceStatementMap = new Map<String, TMP_ServiceStatement__c>();
                for (TMP_ServiceStatement__c item : existingServiceStatementList) {
                    String key = item.Supplier__c + '' + item.BusinessUnitTarget__c + '' + salesTermsStmtRecordTypeId + '' + item.Year__c + '' + item.NegoScope__c;
                    existingServiceStatementMap.put(key, item);
                }
                
                for (NegoScope__c ns : targetNsRecords) {
                    String key = ns.Supplier__c + '' + (ns.BusinessUnit__c != null ? ns.BusinessUnit__c : ns.Supplier__r.BusinessUnitOrigin__c) + '' + salesTermsStmtRecordTypeId + '' + nextYear + '' + ns.Id;
                    TMP_ServiceStatement__c serviceStatement;
                    if (existingServiceStatementMap.containsKey(key)) {
                        serviceStatement = existingServiceStatementMap.get(key);
                    } else {
                        serviceStatement = new TMP_ServiceStatement__c(Status__c = 'Requested',
                                                                       BusinessProcess__c = 'SalesTermsStatement',
                                                                       Step__c = 'Pending Supplier Input');
                    }
                    serviceStatement.RecordTypeId = salesTermsStmtRecordTypeId;
                    serviceStatement.Supplier__c = ns.Supplier__c;
                    serviceStatement.NegoScope__c = ns.Id;
                    serviceStatement.BusinessUnitTarget__c = ns.BusinessUnit__c != null ? ns.BusinessUnit__c : ns.Supplier__r.BusinessUnitOrigin__c;
                    serviceStatement.Year__c = nextYear;
                    serviceStatement.ClosingDate__c = closingDate;
                    serviceStatement.Description__c = ns.Supplier__r.ReferenceLanguage__c == 'French' ? serviceStatementSetting.descriptionFR : serviceStatementSetting.descriptionEN;
                    serviceStatementListToUpsert.add(serviceStatement);
                    if (ns.Supplier__r.Account__c != null) {
                        accountIds.add(ns.Supplier__r.Account__c);
                    }
                }
            } else {
                List<Supplier__c> suppliers = (List<Supplier__c>) scope;
                List<TMP_ServiceStatement__c> existingServiceStatementList = [SELECT Id, Supplier__c, BusinessUnitTarget__c, Year__c, RecordTypeId, Status__c
                                                                              FROM TMP_ServiceStatement__c
                                                                              WHERE Year__c = :nextYear
                                                                              AND RecordTypeId = :salesTermsStmtRecordTypeId
                                                                              AND Supplier__c IN :suppliers
                                                                              AND Status__c NOT IN ('Closed', 'Validated')];
                Map<String, TMP_ServiceStatement__c> existingServiceStatementMap = new Map<String, TMP_ServiceStatement__c>();
                for (TMP_ServiceStatement__c item : existingServiceStatementList) {
                    String key = item.Supplier__c + '' + item.BusinessUnitTarget__c + '' + salesTermsStmtRecordTypeId + '' + item.Year__c;
                    existingServiceStatementMap.put(key, item);
                }
                
                for (Supplier__c supplier : suppliers) {
                    String key = supplier.Id + '' + supplier.BusinessUnitOrigin__c + '' + salesTermsStmtRecordTypeId + '' + nextYear;
                    TMP_ServiceStatement__c serviceStatement;
                    if (supplier.Account__c != null) {
                        accountIds.add(supplier.Account__c);
                    }
                    if (existingServiceStatementMap.containsKey(key)) {
                        serviceStatement = existingServiceStatementMap.get(key);
                    } else {
                        serviceStatement = new TMP_ServiceStatement__c(Status__c = 'Requested',
                                                                       BusinessProcess__c = 'SalesTermsStatement',
                                                                       Step__c = 'Pending Supplier Input');
                    }
                    serviceStatement.RecordTypeId = salesTermsStmtRecordTypeId;
                    serviceStatement.Supplier__c = supplier.Id;
                    serviceStatement.BusinessUnitTarget__c = supplier.BusinessUnitOrigin__c;
                    serviceStatement.Year__c = nextYear;
                    serviceStatement.Description__c = supplier.ReferenceLanguage__c == 'French' ? serviceStatementSetting.descriptionFR : serviceStatementSetting.descriptionEN;
                    serviceStatementListToUpsert.add(serviceStatement);
                }
            }
            
            if (!serviceStatementListToUpsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(serviceStatementListToUpsert, false);
                nb.logResults(results, serviceStatementListToUpsert);
                
                //insert related File Directory
                List<ServiceStatementSettings.RequestedDocumentWrapper> requestedDocuments = serviceStatementSetting.requestedDocuments;
                if (requestedDocuments != null && !requestedDocuments.isEmpty()) {
                    List<FileDirectory__c> fileDirectoryList = [SELECT Id, TMP_ServiceStatement__c, RecordTypeId, SubType__c, DocumentName__c, Status__c, Supplier__c
                                                                FROM FileDirectory__c
                                                                WHERE TMP_ServiceStatement__c IN :serviceStatementListToUpsert];
                    Map<String, FileDirectory__c> fileDirectoryMap = new Map<String, FileDirectory__c>();            
                    List<FileDirectory__c> fileDirectoryListToInsert = new List<FileDirectory__c>();
                    for (FileDirectory__c fd : fileDirectoryList) {
                        String key = fd.TMP_ServiceStatement__c + '' + fd.RecordTypeId + '' + fd.SubType__c + '' + fd.DocumentName__c;
                        fileDirectoryMap.put(key, fd);
                    }
                    for (TMP_ServiceStatement__c item : serviceStatementListToUpsert) {
                        for (ServiceStatementSettings.RequestedDocumentWrapper requestedDocument : requestedDocuments) {
                            String key = item.Id + '' + requestedDocument.documentType + '' + requestedDocument.documentSubType + '' + requestedDocument.documentName;
                            if (!fileDirectoryMap.containsKey(key)) {
                                FileDirectory__c fd = new FileDirectory__c();
                                fd.TMP_ServiceStatement__c = item.Id;
                                fd.NegoScope__c = item.NegoScope__c;
                                fd.Supplier__c = item.Supplier__c;
                                fd.ReferenceYear__c = nextYear;
                                fd.DocumentName__c = requestedDocument.documentName;
                                fd.SubType__c = requestedDocument.documentSubType;
                                fd.Status__c = 'Requested';
                                fd.IsPortalPublished__c = true;
                                fd.NumberOfViews__c = 0;
                                fd.NumberOfDownloads__c = 0;
                                fd.IsToBeSigned__c = true;
                                fd.PortalPublishDate__c = System.now();
                                fd.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, requestedDocument.documentType);
                                fileDirectoryListToInsert.add(fd);
                            }
                        }
                    }
                    if (!fileDirectoryListToInsert.isEmpty()) {
                        List<Database.SaveResult> saveResults = Database.insert(fileDirectoryListToInsert, false);
                        nb.logResults(saveResults, fileDirectoryListToInsert);
                             
                        List<FileDirectory__c> files = new List<FileDirectory__c>();
                        files.addAll(fileDirectoryList);
                        files.addAll(fileDirectoryListToInsert);
                                                            
                        if (accountIds.isEmpty()) return;

                        List<User> users = [SELECT Id, Contact.AccountId
                                            FROM User
                                            WHERE ContactId != null
                                            AND Contact.AccountId IN :accountIds
                                            AND IsActive = true];
                        if (users.isEmpty()) return;                    

                        Map<Id, List<Id>> accToUsers = new Map<Id, List<Id>>();
                        for (User u : users) {
                            List<Id> l = accToUsers.get(u.Contact.AccountId);
                            if (l == null) { 
                                l = new List<Id>();
                                accToUsers.put(u.Contact.AccountId, l); 
                            }
                            l.add(u.Id);
                        }

                        List<FileDirectory__Share> existing = [SELECT ParentId, UserOrGroupId
                                                               FROM FileDirectory__Share
                                                               WHERE ParentId IN :files
                                                               AND RowCause = 'Manual'];
                        Set<String> seen = new Set<String>();
                        for (FileDirectory__Share sh : existing) {
                             seen.add(sh.ParentId + '_' + sh.UserOrGroupId);
                        } 

                        List<FileDirectory__Share> toInsert = new List<FileDirectory__Share>();
                        for (FileDirectory__c f : files) {
                            Id accId = (f.Supplier__r != null ? f.Supplier__r.Account__c : null);
                            if (accId == null) continue;
                            List<Id> ulist = accToUsers.get(accId);
                            if (ulist == null || ulist.isEmpty()) continue;
                            for (Id uid : ulist) {
                                String k = f + '_' + uid;
                                if (!seen.contains(k)) {
                                    FileDirectory__Share sh = new FileDirectory__Share();
                                    sh.ParentId = f.Id;
                                    sh.UserOrGroupId = uid;
                                    sh.AccessLevel = 'Edit';
                                    sh.RowCause = 'Manual';
                                    toInsert.add(sh);
                                }
                            }
                        }
                        if (!toInsert.isEmpty()) {
                            List<Database.SaveResult> sr = Database.insert(toInsert, false);
                            nb.logResults(sr, toInsert);
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(ssp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(ssp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
		nb.saveLog(bc);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new InitSalesTermsStatementBatch('Schedule', null), 200);
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Id supplierId = (Id)paramsMap.get('supplierId');
        return new InitSalesTermsStatementBatch(startedFrom, supplierId);
    }
}