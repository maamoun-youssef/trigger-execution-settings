/**
 * @author ULiT
 * @date 16-10-2025
 * @description clone price lists statements
 *******************************************************************************************************************************************/

public with sharing class clonePriceListStatementBatch implements Database.Batchable<SObject> , Database.Stateful{
    private NegoptimBatch nb;
    private List<Id> sourceIds;
    private String targetRT;
    private Map<Id , PriceListStatement__c> oldToNewPls = new Map<Id, PriceListStatement__c>();
    private String query;
    private String detailsQuery;
    private Trg_PriceListStatement_Handler handler;
     Set<Id> recordTypeIdsSet = new Set<Id>();
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> buSourceIdSet = new Set<Id>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<String, Decimal> priceListStatementVersionMap = new Map<String, Decimal>();
    
    public clonePriceListStatementBatch(List<Id> sourceIds, String targetRT) {
        if(sourceIds == null || sourceIds.isEmpty()) {
        throw new AuraHandledException('sourceIds cannot be null or empty');
    }
        this.nb = new NegoptimBatch(clonePriceListStatementBatch.class.getName(), NegoptimBatch.BatchType.Stateful , 'Clone Price List Statements');
        nb.logParameter('sourceIds ', sourceIds);
        nb.logParameter('targetRT ', targetRT);
        this.sourceIds = sourceIds;
        this.targetRT = targetRT;
        this.query = 'SELECT Id, Label__c, Account__c, Supplier__c, NegoScope__c, '
             + 'BusinessUnitTarget__c, BusinessUnitSource__c, t_ActiveTaxesList__c, '
             + 'SellInRule__c, RoundingMethod__c, NetPriceRoundingScale__c, '
             + 'GrossPriceRoundingScale__c, TaxesRoundingScale__c, '
             + 'isPromoSellInIncluded__c, Comment__c, CommentLong__c, ReferenceYear__c  '
             + 'FROM PriceListStatement__c '
             + 'WHERE Id IN (\'' + String.join(sourceIds, '\',\'') + '\')';
             System.debug('TESTTTTTT'+ this.query);

        List<String> detailFields = new List<String>();
        Map<String, Schema.SObjectField> detailtFieldsMap = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap();
        for (String fieldName : detailtFieldsMap.keySet()) {
            if (detailtFieldsMap.get(fieldName).getDescribe().isCreateable()) {
                detailFields.add(fieldName);
            }
        }
        this.detailsQuery = 'SELECT ' + (!detailFields.isEmpty() ? String.join(detailFields, ',') : 'Id')
                            +' FROM PriceListStatementDetail__c '
                            + 'WHERE PriceListStatement__c IN (\'' + String.join(sourceIds, '\',\'') + '\')';
        

        nb.logParameter('sourceIds ', this.sourceIds);
        nb.logParameter('targetTD ', this.targetRT);
        nb.logParameter('query ', this.query);
        nb.logParameter('Details query ', this.detailsQuery);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<PriceListStatement__c> scope) {
        SavePoint sp = Database.setSavepoint();
        try{
        Id targetId = NegoptimHelper.getObjectRecordTypeId(PriceListStatement__c.SObjectType, targetRT);
        for (PriceListStatement__c src : scope) {
            PriceListStatement__c pls = new PriceListStatement__c();
            pls.RecordTypeId = targetId;
            pls.OnTop__c = false;
            pls.Label__c = 'Clone ' + src.Label__c; 
            pls.Account__c = src.Account__c;
            pls.Supplier__c = src.Supplier__c;
            pls.NegoScope__c = src.NegoScope__c;
            pls.BusinessUnitTarget__c = src.BusinessUnitTarget__c;
            pls.BusinessUnitSource__c = src.BusinessUnitSource__c;
            pls.t_ActiveTaxesList__c = src.t_ActiveTaxesList__c;
            pls.SellInRule__c = src.SellInRule__c;
            pls.RoundingMethod__c = src.RoundingMethod__c;
            pls.NetPriceRoundingScale__c = src.NetPriceRoundingScale__c;
            pls.GrossPriceRoundingScale__c = src.GrossPriceRoundingScale__c;
            pls.TaxesRoundingScale__c = src.TaxesRoundingScale__c;
            pls.isPromoSellInIncluded__c = src.isPromoSellInIncluded__c;
            pls.Comment__c = src.Comment__c;
            pls.CommentLong__c = src.CommentLong__c;
            pls.PriceListStatementReference__c = src.Id;
            recordTypeIdsSet.add(targetId);
            buTargetIdSet.add(src.BusinessUnitTarget__c);
            buSourceIdSet.add(src.BusinessUnitSource__c);
            supplierIdSet.add(src.Supplier__c);
            nsIdSet.add(src.NegoScope__c);
            yearSet.add(Integer.valueOf(src.ReferenceYear__c));
            oldToNewPls.put(src.Id, pls);
        }
        String[] priceListStatementFields = new String[] {
            SObjectType.PriceListStatement__c.fields.Version__c.Name,
            SObjectType.PriceListStatement__c.fields.RecordTypeId.Name,
            SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.PriceListStatement__c.fields.BusinessUnitSource__c.Name,
            SObjectType.PriceListStatement__c.fields.Supplier__c.Name,
            SObjectType.PriceListStatement__c.fields.NegoScope__c.Name,
            SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name
        };
        if (NegoptimHelper.checkAccessibility(PriceListStatement__c.SObjectType, priceListStatementFields)) {
            List<PriceListStatement__c> priceListStatementsList = [SELECT Version__c, RecordTypeId, BusinessUnitTarget__c,
                                                                   BusinessUnitSource__c, Supplier__c, NegoScope__c, ReferenceYear__c
                                                                   FROM PriceListStatement__c
                                                                   WHERE BusinessUnitTarget__c IN :buTargetIdSet
                                                                   AND BusinessUnitSource__c IN :buSourceIdSet
                                                                   AND Supplier__c IN :supplierIdSet
                                                                   AND NegoScope__c IN :nsIdSet
                                                                   AND ReferenceYear__c IN :yearSet
                                                                   AND RecordTypeId IN :recordTypeIdsSet
                                                                   AND Version__c <> NULL
                                                                   ORDER BY Version__c DESC];
            for(PriceListStatement__c item : priceListStatementsList){
                String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.BusinessUnitSource__c + '-' + item.Supplier__c + '-' + item.NegoScope__c + '-' + Integer.valueOf(item.ReferenceYear__c);
                if (!priceListStatementVersionMap.containsKey(key)) {
                    Decimal lastVersion = item.Version__c == null ? 0 : item.Version__c;
                    priceListStatementVersionMap.put(key, lastVersion);
                }
            }
            for (PriceListStatement__c item : oldToNewPls.values() ){
                String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.BusinessUnitSource__c + '-' + item.Supplier__c + '-' + item.NegoScope__c + '-' + Integer.valueOf(item.ReferenceYear__c);
                if (!priceListStatementVersionMap.containsKey(key)) {
                    priceListStatementVersionMap.put(key, 0);
                }
                Decimal lastVersion = priceListStatementVersionMap.get(key);
                lastVersion++;
                item.Version__c = lastVersion;
                item.Label__c +=lastVersion;
                priceListStatementVersionMap.put(key, lastVersion);
            }
        }
        
            if(!oldToNewPls.isEmpty()){
                List<Database.SaveResult> results = Database.insert(oldToNewPls.values());
                this.nb.logResults(results, oldToNewPls.values());
            }
            
            List<PriceListStatementDetail__c> srcDetails = Database.query(this.detailsQuery);

            List<PriceListStatementDetail__c> newDetails = new List<PriceListStatementDetail__c>();
            for(PriceListStatementDetail__c detail : srcDetails){
                PriceListStatementDetail__c newDetail = detail.clone(false , true , false , false);
                newDetail.PriceListStatement__c = oldToNewPls.get(detail.PriceListStatement__c).Id;
                newDetails.add(newDetail);
            }
            if(!newDetails.isEmpty()){
             List<Database.SaveResult> results = Database.insert(newDetails);
                this.nb.logResults(results, newDetails);
            }
        }
        catch(DMLException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            system.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);   
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed. Total PLS cloned: ' + oldToNewPLS.size());
        nb.saveLog(bc);
    }
    
}