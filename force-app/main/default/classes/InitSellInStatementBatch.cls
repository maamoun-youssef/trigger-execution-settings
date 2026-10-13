/**
 * @author ULiT
 * @date 14-01-2025
 * @description Generate sellin statement, sellin Stmt Detail
******************************************************************************************************************************************* */
public with sharing class InitSellInStatementBatch implements Database.Batchable<SObject>, BatchFactory {
    private NegoptimBatch nb;
    private String query;
    private Set<Id> negoScopeIdSet;
    private Integer year;
    private String periodType;
    private Integer periodNumber;
    private Map<String, Id> sellinStatementDetailRecordTypeMap = NegoptimHelper.getObjectRecordTypeMapIds(SellInStatementDetail__c.SObjectType);
    private List<String> sellInStatementDetailUpdatableFields = new List<String>();
    private String sellinStatementRecodType;
    private Map<String, String> periodTypePicklistMap;
    
    public InitSellInStatementBatch() {}
    public InitSellInStatementBatch(String startedFrom, Set<Id> negoScopeIds, Integer year, String periodType, Integer periodNumber) {
        nb = new NegoptimBatch(InitSellInStatementBatch.class.getName(), NegoptimBatch.BatchType.Stateless, startedFrom);
        this.negoScopeIdSet = negoScopeIds == null ? new Set<Id>() : negoScopeIds;
        this.year = year;
        this.periodType = periodType;
        this.periodNumber = periodNumber;
        this.sellInStatementDetailUpdatableFields = new List<String>();
        Map<String, schema.SObjectField> sellInStatementDetailFieldsMap = Schema.SObjectType.SellInStatementDetail__c.fields.getMap();
        for (String fieldName : sellInStatementDetailFieldsMap.keySet()) {
            if (sellInStatementDetailFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                this.sellInStatementDetailUpdatableFields.add(fieldName);
            }
        }
        this.query = 'SELECT Id, ExtId__c FROM BusinessUnit__c';
        this.query += ' WHERE SetSellInStatementDetail__c = TRUE';
        System.debug('query: ' + query);
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        this.sellinStatementRecodType = connectSettings.sellinStatementRevenueType;
        this.periodTypePicklistMap = NegoptimHelper.getPicklistTranslationMap(SObjectType.SellInStatement__c.fields.PeriodType__c, true);
        nb.logParameter('negoScopeIds', negoScopeIds);
        nb.logParameter('year', year);
        nb.logParameter('periodType', periodType);
        nb.logParameter('periodNumber', periodNumber);
        nb.logParameter('query', query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<BusinessUnit__c> scope) {
        // Map of new SellIn Statements on NS + current year, (Key = NS, Value = SellIn)
        Map<String, SellInStatement__c> sellInStatementToUpsertMap = new Map<String, SellInStatement__c>();
        List<SellInStatementWrapper> sellInStatementWrapperList = new List<SellInStatementWrapper>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> buIdList = new Set<Id>();
            for(BusinessUnit__c item : scope) {
                buIdList.add(item.Id);
            }
            DateTime bDateRange, eDateRange;
            if(this.periodType == 'Month') {
                bDateRange = DateTime.newInstance(this.year, this.periodNumber, 1);
                eDateRange = NegoptimHelper.getLastDayOfMonth(this.year, this.periodNumber);
            } else if(this.periodType == 'Semester') {
                Integer month = this.periodNumber == 1 ? 1 : 6;
                bDateRange = DateTime.newInstance(this.year, month, 1);
                eDateRange = NegoptimHelper.getLastDayOfMonth(this.year, this.periodNumber * 6);
            } else if(this.periodType == 'Trimester') {
                Integer month = (this.periodNumber == 1 ? 1 : (this.periodNumber == 2 ? 4 : (this.periodNumber == 3 ? 7 : 10)));
                bDateRange = DateTime.newInstance(this.year, month, 1);
                eDateRange = NegoptimHelper.getLastDayOfMonth(this.year, this.periodNumber * 3);
            } else if(this.periodType == 'Annual') {
                bDateRange = DateTime.newInstance(this.year, 1, 1);
                eDateRange = NegoptimHelper.getLastDayOfMonth(this.year, this.periodNumber * 12);
            }
            String bDateRangeFilter = bDateRange.format('yyyy-MM-dd');
            String eDateRangeFilter = eDateRange.format('yyyy-MM-dd');
            String discountQuery = 'SELECT Id, Name, Contract__c, Disc_BDate__c, Disc_EDate__c,';
            discountQuery += ' Contract__r.Supplier_Nego_Scope__c, Contract__r.Contract_BDate__c, Contract__r.Contract_EDate__c, Contract__r.RecordType.DeveloperName,';
            discountQuery += ' Product_Scope__c, Product_Scope__r.RecordType.DeveloperName, Product_Scope__r.Name, Product_Scope__r.ExtId__c, BusinessUnitScope__c, BusinessUnitScope__r.Name, BusinessUnitScope__r.ExtId__c, Base_To_Nego__c, Product_Scope__r.NegoscopeParent__c';
            discountQuery += ' FROM Contract_Discount__c';
            discountQuery += ' WHERE Product_Scope__c <> NULL';
            //discountQuery += ' AND BusinessUnitScope__c IN (\'' + String.join(buIdList, '\',\'') + '\')';
            //discountQuery += ' AND (Product_Scope__r.NegoscopeParent__c IN (\'' + String.join(this.negoScopeIdSet, '\',\'') + '\')';
            //discountQuery += ' OR Contract__r.Supplier_Nego_Scope__c IN (\'' + String.join(this.negoScopeIdSet, '\',\'') + '\')';
            //discountQuery += ' OR Product_Scope__c IN (\'' + String.join(this.negoScopeIdSet, '\',\'') + '\'))';
            discountQuery += ' AND Contract__r.Supplier_Nego_Scope__c IN (\'' + String.join(this.negoScopeIdSet, '\',\'') + '\')';
            discountQuery += ' AND (Contract__r.Is_OnTop_Simulation__c = TRUE OR Contract__r.RecordType.DeveloperName = \'Period_Extension\')';
            discountQuery += ' AND Parent_Discount__c = NULL';
            discountQuery += ' AND (CALENDAR_YEAR(Contract__r.Contract_BDate__c) = ' + this.year + ' OR CALENDAR_YEAR(Contract__r.Contract_EDate__c) = ' + this.year + ')';
            discountQuery += ' AND Contract__r.Status__c <> \'Deleted\'';
            discountQuery += ' AND Status__c <> \'Deleted\'';
            discountQuery += ' AND Respects_Contract_Scope__c = FALSE';
            discountQuery += ' AND ((Disc_BDate__c >= ' + bDateRangeFilter + ' AND Disc_BDate__c <= ' + eDateRangeFilter + ')';
            discountQuery += ' OR (Disc_EDate__c >= ' + bDateRangeFilter + ' AND Disc_EDate__c <= ' + eDateRangeFilter + ')';
            discountQuery += ' OR (Disc_BDate__c <= ' + bDateRangeFilter + ' AND Disc_EDate__c >= ' + eDateRangeFilter + '))';
            discountQuery += ' AND Respects_Contract_Scope__c = FALSE';            
            system.debug('discountQuery >>> ' + discountQuery);
            List<Contract_Discount__c> discounts = Database.query(discountQuery);
            Map<Id, List<Contract_Discount__c>> discountsMap = new Map<Id, List<Contract_Discount__c>>();
            Set<Id> negoScopeIds = new Set<Id>(this.negoScopeIdSet);
            if(!discounts.isEmpty()) {
                for(Contract_Discount__c item : discounts) {
                    //Id nsId = item.Product_Scope__r.NegoscopeParent__c != null ? item.Product_Scope__r.NegoscopeParent__c : item.Product_Scope__c;
                    Id nsId = item.Contract__r.Supplier_Nego_Scope__c;
                    if(!discountsMap.containsKey(nsId)) discountsMap.put(nsId, new List<Contract_Discount__c>());
                    discountsMap.get(nsId).add(item);
                    negoScopeIds.add(item.Product_Scope__c);
                }
            }
            // get Negoscpes
            Map<Id, NegoScope__c> negoScopesMap = new Map<Id, NegoScope__c>([SELECT Id, Name, ExtId__c, RecordType.DeveloperName, Supplier__c, Supplier__r.Account__c,
                                                                             (SELECT Id, NegoScopeMaster__c, NegoScopeDetail__c, NegoScopeDetail__r.Name, NegoScopeDetail__r.ExtId__c,
                                                                              NegoScopeDetail__r.Supplier__c, NegoScopeDetail__r.Supplier__r.Account__c
                                                                              FROM NSLNKNegoScopeMaster__r
                                                                              WHERE NegoScopeDetail__r.Status__c = 'Active'
                                                                              AND NegoScopeDetail__r.RecordType.DeveloperName <> 'SubNS')
                                                                             FROM NegoScope__c
                                                                             WHERE Id IN :negoScopeIds]);
            // get last existing SellInStatement__c/SellInStatementDetail__c
            Map<String, Integer> maxSellInStatementsPeriodMap = new Map<String, Integer>();
            List<AggregateResult> sellInStatementResults = [SELECT NegoScope__c NegoScope__c, Max(PeriodNumber__c) MaxPeriodNumber__c
                                                            FROM SellInStatement__c
                                                            WHERE NegoScope__c IN :this.negoScopeIdSet
                                                            AND ReferenceYear__c = :this.year
                                                            GROUP BY NegoScope__c];
            for(AggregateResult item : sellInStatementResults) {
                Id negoScopeId = (Id)item.get('NegoScope__c');
                maxSellInStatementsPeriodMap.put(String.valueOf(negoScopeId) + Integer.valueOf(this.year), (item.get('MaxPeriodNumber__c') != null ? Integer.valueOf(item.get('MaxPeriodNumber__c')) : 0));
            }
            Map<String, List<SellInStatement__c>> relatedSellInStatementsMap = new Map<String, List<SellInStatement__c>>();
            List<SellInStatement__c> relatedSellInStatements =  [SELECT Id, ReferenceYear__c, NegoScope__c, PeriodType__c, PeriodNumber__c, IsLastPeriod__c
                                                                 FROM SellInStatement__c
                                                                 WHERE NegoScope__c IN :this.negoScopeIdSet
                                                                 AND ReferenceYear__c = :this.year
                                                                 AND IsLastPeriod__c = TRUE];
            for(SellInStatement__c item : relatedSellInStatements) {
                String key = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c);
                if(!relatedSellInStatementsMap.containsKey(key)) relatedSellInStatementsMap.put(key, new List<SellInStatement__c>());
                relatedSellInStatementsMap.get(key).add(item);
            }
            Map<String, SellInStatement__c> existingSellInStatementsMap = new Map<String, SellInStatement__c>();
            Map<String, SellInStatementDetail__c> sellInStatementDetailsMap = new Map<String, SellInStatementDetail__c>();
            List<SellInStatement__c> sellInStatementList = [SELECT Id, ExtId__c, NegoScope__c, ReferenceYear__c, PeriodType__c, PeriodNumber__c,
                                                            (SELECT Id, SellInStatement__c, BusinessUnit__c, NegoScopeReference__c, IsCustomDateRange__c, CustomBDate__c, CustomEDate__c
                                                             FROM SSDSellInStatement__r)
                                                            FROM SellInStatement__c
                                                            WHERE NegoScope__c IN :this.negoScopeIdSet
                                                            AND (ReferenceYear__c = :this.year OR ReferenceYear__c = : (this.year - 1))
                                                            AND PeriodType__c = :this.periodType
                                                            AND PeriodNumber__c = :this.periodNumber
                                                            ORDER BY Version__c DESC];
            for(SellInStatement__c item : sellInStatementList) {
                String key = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c) + item.PeriodNumber__c + item.PeriodType__c;
                if(!existingSellInStatementsMap.containsKey(key)) {
                    existingSellInStatementsMap.put(key, item);
                    for(SellInStatementDetail__c sellInStatementDetail : item.SSDSellInStatement__r) {
                        String detailKey = (key
                                            + String.valueOf(sellInStatementDetail.BusinessUnit__c)
                                            + (sellInStatementDetail.NegoScopeReference__c != null ? String.valueOf(sellInStatementDetail.NegoScopeReference__c) : '')
                                            + (sellInStatementDetail.IsCustomDateRange__c != null ? String.valueOf(sellInStatementDetail.IsCustomDateRange__c) : '')
                                            + (sellInStatementDetail.CustomBDate__c != null ? String.valueOf(sellInStatementDetail.CustomBDate__c) : '')
                                            + (sellInStatementDetail.CustomEDate__c != null ? String.valueOf(sellInStatementDetail.CustomEDate__c) : ''));
                        sellInStatementDetailsMap.put(detailKey, sellInStatementDetail);
                    }
                }
            }
            for(Id negoScopeId : this.negoScopeIdSet) {
                NegoScope__c negoScope = negoScopesMap.get(negoScopeId);
                String keyMaxPeriod = String.valueOf(negoScopeId) + Integer.valueOf(this.year);
                SellInStatement__c sellInStatement;
                SellInStatementWrapper sellInStatementWrapper = new SellInStatementWrapper(negoScope, this.year, this.periodType, this.periodNumber, this.periodTypePicklistMap,
                                                                                           maxSellInStatementsPeriodMap, this.sellinStatementRecodType);
                if(!existingSellInStatementsMap.containsKey(sellInStatementWrapper.sellInStatementKey)) {
                    sellInStatement = sellInStatementWrapper.insertSellInStatement(existingSellInStatementsMap);
                    if(sellInStatement.IsLastPeriod__c && relatedSellInStatementsMap.containsKey(keyMaxPeriod)) {
                        for(SellInStatement__c relatedSellInStatement : relatedSellInStatementsMap.get(keyMaxPeriod)) {
                            relatedSellInStatement.IsLastPeriod__c = false;
                            sellInStatementToUpsertMap.put(keyMaxPeriod, relatedSellInStatement);
                        }
                    }
                } else {
                    sellInStatement = existingSellInStatementsMap.get(sellInStatementWrapper.sellInStatementKey);
                    sellInStatementWrapper.sellInStatement = sellInStatement;
                }
                sellInStatementToUpsertMap.put(sellInStatementWrapper.sellInStatementKey, sellInStatement);
                if(negoScope.RecordType.DeveloperName == 'Advanced') {
                    for(NSLink__c nsLink : negoScope.NSLNKNegoScopeMaster__r) {
                        for(BusinessUnit__c item : scope) {
                            sellInStatementWrapper.insertSellInStatementDetail(nsLink.NegoScopeDetail__r, item, sellInStatementDetailsMap, null);
                        }
                    }
                } else {
                    for(BusinessUnit__c item : scope) {
                        sellInStatementWrapper.insertSellInStatementDetail(negoScope, item, sellInStatementDetailsMap, null);
                    }
                }
                // Case2: Insert details based on sub negoscopes and/or custom date ranges  (optional) 
                if(discountsMap.containsKey(negoScopeId)) {
                    for(Contract_Discount__c discount : discountsMap.get(negoScopeId)) {
                        if(discount.Product_Scope__r.RecordType.DeveloperName == 'Advanced') {
                            if(negoScopesMap.containsKey(discount.Product_Scope__c)) {
                                negoScope = negoScopesMap.get(discount.Product_Scope__c);
                                for(NSLink__c nsLink : negoScope.NSLNKNegoScopeMaster__r) {
                                    for(BusinessUnit__c item : scope) {
                                        sellInStatementWrapper.insertSellInStatementDetail(nsLink.NegoScopeDetail__r, item, sellInStatementDetailsMap, discount);
                                    }
                                }
                            }
                        } else {
                            for(BusinessUnit__c item : scope) {
                                sellInStatementWrapper.insertSellInStatementDetail(discount.Product_Scope__r, item, sellInStatementDetailsMap, discount);
                            }
                        }
                    }
                }
                sellInStatementWrapperList.add(sellInStatementWrapper);
            }
            List<SellInStatement__c> sellInStatementsToInsert = new List<SellInStatement__c>();
            List<SellInStatementDetail__c> sellInStatementDetailsToInsert = new List<SellInStatementDetail__c>();
            if (!sellInStatementToUpsertMap.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(sellInStatementToUpsertMap.values(), true);
                this.nb.logResults(results, sellInStatementToUpsertMap.values());
            }
            // List of SellIn statement details to be inserted
            if(!sellInStatementWrapperList.isEmpty()) {
                for (SellInStatementWrapper sellInStatementWrapper : sellInStatementWrapperList) {
                    if(sellInStatementWrapper.sellInStatement != null && !sellInStatementWrapper.sellInStatementDetails.isEmpty()) {
                        for (SellInStatementDetail__c detail : sellInStatementWrapper.sellInStatementDetails) {
                            detail.SellInStatement__c = sellInStatementWrapper.sellInStatement.Id;
                            sellInStatementDetailsToInsert.add(detail);
                        }
                    }
                }
                if (!sellInStatementDetailsToInsert.isEmpty()) {
                    List<Database.UpsertResult> saveResults = Database.upsert(sellInStatementDetailsToInsert, true);
                    this.nb.logResults(saveResults, sellInStatementDetailsToInsert);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('ERROR >>>' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
		nb.saveLog(bc);
    }
    
    public class SellInStatementWrapper {
        public NegoScope__c negoScope {get; set;}
        public Integer referenceYear {get; set;}
        public String periodType {get; set;}
        public Integer periodNumber {get; set;}
        public SellInStatement__c sellInStatement {get; set;}
        public List<SellInStatementDetail__c> sellInStatementDetails {get; set;}
        public Map<String, String> periodTypePicklistMap {get; set;}
        public Map<String, Integer> maxSellInStatementsPeriodMap {get; set;}
        public Id sellinStatementRecodType {get; set;}
        public  String sellInStatementKey {
            get {
                if (sellInStatementKey == null) {
                    return String.valueOf(this.negoScope.Id) + Integer.valueOf(this.referenceYear) + this.periodNumber + this.periodType;
                }
                return sellInStatementKey;
            }
            set;
        }
        public  String sellInStatementHistoryKey {
            get {
                if (sellInStatementHistoryKey == null) {
                    return String.valueOf(this.negoScope.Id) + Integer.valueOf(this.referenceYear - 1) + this.periodNumber + this.periodType;
                }
                return sellInStatementHistoryKey;
            }
            set;
        }
        private Map<Integer, String> monthsMap = new Map<Integer, String> {
            1 => Label.LBL_January,
            2 => Label.LBL_February,
            3 => Label.LBL_March,
            4 => Label.LBL_April,
            5 => Label.LBL_May,
            6 => Label.LBL_June,
            7 => Label.LBL_July,
            8 => Label.LBL_August,
            9 => Label.LBL_September,
            10 => Label.LBL_October,
            11 => Label.LBL_November,
            12 => Label.LBL_December
        };
        public SellInStatementWrapper(NegoScope__c negoScope, Integer referenceYear, String periodType, Integer periodNumber, Map<String, String> periodTypePicklistMap,
                                      Map<String, Integer> maxSellInStatementsPeriodMap, Id sellinStatementRecodType)
        {
            this.negoScope = negoScope;
            this.referenceYear = referenceYear;
            this.periodType = periodType;
            this.periodNumber = periodNumber;
            this.periodTypePicklistMap = periodTypePicklistMap;
            this.maxSellInStatementsPeriodMap = maxSellInStatementsPeriodMap;
            this.sellinStatementRecodType = sellinStatementRecodType;
            this.sellInStatementDetails = new List<SellInStatementDetail__c>();
        }
        
        public SellInStatement__c insertSellInStatement(Map<String, SellInStatement__c> existingSellInStatementsMap) {
            String periodNumberLabel = '';
            if(this.periodType == 'Month') {
                periodNumberLabel = this.monthsMap.get(this.periodNumber);
            } else if(this.periodType == 'Trimester') {
                periodNumberLabel = Label.LBL_Trimester + ' ' + this.periodNumber;
            } else if(this.periodType == 'Semester') {
                periodNumberLabel = Label.LBL_Semester + ' ' + this.periodNumber;
            } else if(this.periodType == 'Annual') {
                periodNumberLabel = String.valueOf(this.periodNumber);
            }
            String name = this.negoScope.Name + ' - ' + this.referenceYear + ' - ' + this.periodTypePicklistMap.get(this.periodType) + ' - ' + periodNumberLabel + ' - (1)';
            String keyMaxPeriod = String.valueOf(negoScope.Id) + Integer.valueOf(this.referenceYear);
            sellInStatement = new SellInStatement__c(Account__c = this.negoScope.Supplier__r.Account__c,
                                                     ExtId__c = ((this.negoScope.ExtId__c != null ? this.negoScope.ExtId__c + '-' : '') +
                                                                 this.referenceYear + '-' + this.negoScope.RecordType.DeveloperName + '-' + this.periodType + '-' + this.periodNumber + '-' + '1'),
                                                     LastRequestDate__c = System.today(),
                                                     LastSentDate__c = null,
                                                     Name = name.length() > 80 ? name.substring(0, 80) : name,
                                                     NegoScope__c = negoScope.Id,
                                                     PeriodNumber__c = this.periodNumber,
                                                     PeriodType__c = this.periodType,
                                                     RecordTypeId = this.sellinStatementRecodType,
                                                     ReferenceYear__c = this.referenceYear,
                                                     SellInStatement_PV1__c = existingSellInStatementsMap.containsKey(this.sellInStatementKey) ? existingSellInStatementsMap.get(this.sellInStatementKey).Id: null,
                                                     Status__c = 'Requested',
                                                     Supplier__c = this.negoScope.Supplier__c,
                                                     ExtractLDate__c = null,
                                                     ExtractLId__c = null,
                                                     ExtractStatus__c = null,
                                                     IntegLDate__c = null,
                                                     IntegLId__c = null,
                                                     SupportBy__c = null,
                                                     SupportLDate__c = null,
                                                     SupportNote__c = null,
                                                     Version__c = 1,
                                                     IsLastVersion__c = true,
                                                     IsLastPeriod__c = this.maxSellInStatementsPeriodMap.containsKey(keyMaxPeriod) ? this.periodNumber > this.maxSellInStatementsPeriodMap.get(keyMaxPeriod) : true);
            return sellInStatement;
        }
        
        public void insertSellInStatementDetail(NegoScope__c negoScope, BusinessUnit__c bu, Map<String, SellInStatementDetail__c> sellInStatementDetailsMap, Contract_Discount__c discount) {
            NegoScope__c negoScopeReference = negoScope;
            Boolean isCustomDateRange = false;
            if (discount != null) {
                if(discount.Disc_BDate__c != discount.Contract__r.Contract_BDate__c || discount.Disc_EDate__c != discount.Contract__r.Contract_EDate__c) {
                    isCustomDateRange = true;
                } else if(discount.Product_Scope__c != sellInStatement.Negoscope__c && discount.Product_Scope__r.RecordType.DeveloperName != 'SubNS') {
                    return;
                }
            }
            String currentDetailKey = (this.sellInStatementKey
                                       + String.valueOf(bu.Id)
                                       + String.valueOf(negoScopeReference.Id)
                                       + String.valueOf(isCustomDateRange)
                                       + (isCustomDateRange ? String.valueOf(discount.Disc_BDate__c) : '')
                                       + (isCustomDateRange ? String.valueOf(discount.Disc_EDate__c) : ''));
            String historyDetailKey = (this.sellInStatementHistoryKey
                                       + String.valueOf(bu.Id)
                                       + String.valueOf(negoScopeReference.Id)
                                       + String.valueOf(isCustomDateRange)
                                       + (isCustomDateRange ? String.valueOf(discount.Disc_BDate__c) : '')
                                       + (isCustomDateRange ? String.valueOf(discount.Disc_EDate__c) : ''));
            if (sellInStatementDetailsMap.containsKey(currentDetailKey)) return;
            SellInStatementDetail__c newSellInStatementDetail = new SellInStatementDetail__c(BusinessUnit__c = bu.Id,
                                                                                             ClientComment__c = null,
                                                                                             CustomBDate__c = isCustomDateRange ? discount.Disc_BDate__c : null,
                                                                                             CustomEDate__c = isCustomDateRange ? discount.Disc_EDate__c : null,
                                                                                             ExtId__c = (this.sellInStatement.ExtId__c + '-' +
                                                                                                         (bu.ExtId__c != null ? bu.ExtId__c : '') +
                                                                                                         (negoScopeReference.ExtId__c != null ? + '-' + negoScopeReference.ExtId__c : '') +
                                                                                                         (isCustomDateRange ? + '-' + String.valueOf(discount.Disc_BDate__c) : '') +
                                                                                                         (isCustomDateRange ? + '-' + String.valueOf(discount.Disc_EDate__c) : '')),
                                                                                             SellInNonDiscQtySFx__c = null,
                                                                                             SellInNonDiscSFx__c = null,
                                                                                             SellInDiscPromoQtySFx__c = null,
                                                                                             SellInDiscPromoSFx__c = null,
                                                                                             SellInDiscRegularQtySFx__c = null,
                                                                                             SellInDiscRegularSFx__c = null,
                                                                                             SellInDiscTotalQtySFx__c = null,
                                                                                             SellInDiscTotalSFx__c = null,
                                                                                             IsCustomDateRange__c = isCustomDateRange,
                                                                                             ExtractLDate__c = null,
                                                                                             ExtractLId__c = null,
                                                                                             ExtractStatus__c = null,
                                                                                             IntegLDate__c = null,
                                                                                             IntegLId__c = null,
                                                                                             SupportLDate__c = null,
                                                                                             SellInNonDiscQtyP__c = null,
                                                                                             SellInNonDiscP__c = null,
                                                                                             SellInDiscPromoQtyP__c = null,
                                                                                             SellInDiscPromoP__c = null,
                                                                                             SellInDiscRegularQtyP__c = null,
                                                                                             SellInDiscRegularP__c = null,
                                                                                             SellInDiscTotalQtyP__c = null,
                                                                                             SellInDiscTotalP__c = null,
                                                                                             NegoScopeReference__c = negoScopeReference.Id,
                                                                                             SellInStatementDetail_P1__c = sellInStatementDetailsMap.containsKey(historyDetailKey) ? sellInStatementDetailsMap.get(historyDetailKey).Id : null,
                                                                                             SellInStatementDetail_PV1__c = sellInStatementDetailsMap.containsKey(currentDetailKey) ? sellInStatementDetailsMap.get(currentDetailKey).Id : null,
                                                                                             Status__c = 'In Preparation',
                                                                                             SupplierComment__c = null,
                                                                                             SupportBy__c = null,
                                                                                             SupportNote__c = null,
                                                                                             SellInNonDiscQtyTTM__c = null,
                                                                                             SellInNonDiscTTM__c = null,
                                                                                             SellInDiscPromoQtyTTM__c = null,
                                                                                             SellInDiscPromoTTM__c = null,
                                                                                             SellInDiscRegularQtyTTM__c = null,
                                                                                             SellInDiscRegularTTM__c = null,
                                                                                             SellInDiscTotalQtyTTM__c = null,
                                                                                             SellInDiscTotalTTM__c = null);
            sellInStatementDetailsMap.put(currentDetailKey, newSellInStatementDetail);
            this.sellInStatementDetails.add(newSellInStatementDetail);
        }
    }

    // BatchFactory implementation
    public Database.Batchable<SObject> getBatchInstance(Map<String, Object> paramsMap) {
        system.debug('getBatchInstance');
        String startedFrom = (String)paramsMap.get('startedFrom');
        Set<Id> negoScopeIds = (Set<Id>)paramsMap.get('negoScopeIds');
        Integer year = (Integer)paramsMap.get('year');
        String periodType = (String)paramsMap.get('periodType');
        Integer periodNumber = (Integer)paramsMap.get('periodNumber');
        return new InitSellInStatementBatch(startedFrom, negoScopeIds, year, periodType, periodNumber);
    }
}