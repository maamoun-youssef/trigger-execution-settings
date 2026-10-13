/**
 * @author ULiT
 * @date 20/01/2025
 * @description Apex Handler to handle Trg_SellInStatementDetail
 * */
public with sharing class Trg_SellInStatementDetail_Handler {

    public static void OnAfterInsertOrUpdate(List<SellInStatementDetail__c> nSellInStatementDetails, Map<Id, SellInStatementDetail__c> oSellInStatementDetailsMap) {
        calculateYTDAndTTMValues(nSellInStatementDetails, oSellInStatementDetailsMap);
    }
    
    public static void OnAfterUpdate(List<SellInStatementDetail__c> nSellInStatementDetails, Map<Id, SellInStatementDetail__c> oSellInStatementDetailsMap) {
        executeSSDtoCSISynchroBatchOnValidation(nSellInStatementDetails, oSellInStatementDetailsMap);
    }

     /*
     * @description populate 
     */
    private static void calculateYTDAndTTMValues(List<SellInStatementDetail__c> nSellInStatementDetails, Map<Id, SellInStatementDetail__c> oSellInStatementDetailsMap) {
        Set<Id> sellInStatementsSet = new Set<Id>();
        Map<Id, SellInStatementDetail__c> sellInStatementDetailsToUpdateMap = new Map<Id, SellInStatementDetail__c>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> negoScopeReferenceIdSet = new Set<Id>();
        for (SellInStatementDetail__c item : nSellInStatementDetails) {
            if(item.IsCustomDateRange__c == false &&
               (oSellInStatementDetailsMap == null
                || (oSellInStatementDetailsMap.containsKey(item.Id)
                    && (item.SellInNonDiscQtyP__c != oSellInStatementDetailsMap.get(item.Id).SellInNonDiscQtyP__c
                        || item.SellInNonDiscP__c != oSellInStatementDetailsMap.get(item.Id).SellInNonDiscP__c
                        || item.SellInDiscPromoQtyP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscPromoQtyP__c
                        || item.SellInDiscPromoP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscPromoP__c
                        || item.SellInDiscRegularQtyP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscRegularQtyP__c
                        || item.SellInDiscRegularP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscRegularP__c
                        || item.SellInDiscTotalQtyP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscTotalQtyP__c
                        || item.SellInDiscTotalP__c != oSellInStatementDetailsMap.get(item.Id).SellInDiscTotalP__c))))
            {
                sellInStatementsSet.add(item.SellInStatement__c);
                if(item.BusinessUnit__c != null) {
                    buIdSet.add(item.BusinessUnit__c);
                }
                SellInStatementDetail__c updatedSellInStatementDetail = item.clone(true);
                updatedSellInStatementDetail.SellInDiscRegularYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscPromoYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscTotalYTD__c = 0;
                updatedSellInStatementDetail.SellInNonDiscYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscRegularQtyYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscPromoQtyYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscTotalQtyYTD__c = 0;
                updatedSellInStatementDetail.SellInNonDiscQtyYTD__c = 0;
                updatedSellInStatementDetail.SellInDiscRegularTTM__c = 0;
                updatedSellInStatementDetail.SellInDiscPromoTTM__c = 0;
                updatedSellInStatementDetail.SellInDiscTotalTTM__c = 0;
                updatedSellInStatementDetail.SellInNonDiscTTM__c = 0;
                updatedSellInStatementDetail.SellInDiscRegularQtyTTM__c = 0;
                updatedSellInStatementDetail.SellInDiscPromoQtyTTM__c = 0;
                updatedSellInStatementDetail.SellInDiscTotalQtyTTM__c = 0;
                updatedSellInStatementDetail.SellInNonDiscQtyTTM__c = 0;
                sellInStatementDetailsToUpdateMap.put(item.Id, updatedSellInStatementDetail);
            }
        }
        if(!sellInStatementsSet.isEmpty()) {
            Set<Id> negoscopesSet = new Set<Id>();
            Set<String> periodTypesSet = new Set<String>();
            Set<Integer> yearsSet = new Set<Integer>();
            Set<Integer> previousYearsSet = new Set<Integer>();
            Map<String, Integer> sellInStatementPeriodNumbersMap = new Map<String, Integer>();
            Map<String, Integer> firstSellInStatementPeriodNumberMap = new Map<String, Integer>();
            Map<Id, SellInStatement__c> sellInStatementsMap = new Map<Id, SellInStatement__c>([SELECT Id, NegoScope__c, ReferenceYear__c, PeriodType__c, PeriodNumber__c
                                                                                               FROM SellInStatement__c
                                                                                               WHERE Id IN :sellInStatementsSet
                                                                                               AND IsLastVersion__c = TRUE
                                                                                               AND NegoScope__c <> NULL
                                                                                               AND ReferenceYear__c <> NULL
                                                                                               AND PeriodType__c <> NULL
                                                                                               AND PeriodNumber__c <> NULL
                                                                                               ORDER BY ReferenceYear__c, PeriodNumber__c]);
            for(SellInStatement__c item : sellInStatementsMap.values()) {
                negoscopesSet.add(item.NegoScope__c);
                periodTypesSet.add(item.PeriodType__c);
                yearsSet.add(Integer.valueOf(item.ReferenceYear__c));
                previousYearsSet.add(Integer.valueOf(item.ReferenceYear__c - 1));
                String sellInStatementKey = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c) + item.PeriodType__c;
                if(!firstSellInStatementPeriodNumberMap.containsKey(sellInStatementKey)) {
                    firstSellInStatementPeriodNumberMap.put(sellInStatementKey, Integer.valueOf(item.PeriodNumber__c));
                }
            }
            sellInStatementsMap = new Map<Id, SellInStatement__c>([SELECT Id, NegoScope__c, ReferenceYear__c, PeriodType__c, PeriodNumber__c,
                                                                   (SELECT Id, SellInStatement__c, BusinessUnit__c, NegoScopeReference__c, IsCustomDateRange__c, CustomBDate__c, CustomEDate__c,
                                                                    SellInNonDiscQtyP__c, SellInNonDiscP__c, SellInDiscPromoQtyP__c, SellInDiscPromoP__c, SellInDiscRegularQtyP__c,
                                                                    SellInDiscRegularP__c, SellInDiscTotalQtyP__c, SellInDiscTotalP__c,
                                                                    SellInNonDiscQtyYTD__c, SellInNonDiscYTD__c, SellInDiscPromoQtyYTD__c, SellInDiscPromoYTD__c, SellInDiscRegularQtyYTD__c,
                                                                    SellInDiscRegularYTD__c, SellInDiscTotalQtyYTD__c, SellInDiscTotalYTD__c
                                                                    FROM SSDSellInStatement__r
                                                                    WHERE BusinessUnit__c IN :buIdSet
                                                                    AND IsCustomDateRange__c = FALSE)
                                                                   FROM SellInStatement__c
                                                                   WHERE NegoScope__c IN :negoscopesSet
                                                                   AND (ReferenceYear__c IN :yearsSet OR ReferenceYear__c IN :previousYearsSet)
                                                                   AND PeriodType__c IN :periodTypesSet
                                                                   AND IsLastVersion__c = TRUE
                                                                   AND PeriodNumber__c <> NULL
                                                                   ORDER BY ReferenceYear__c, PeriodNumber__c]);
            Map<String, Map<Integer, Map<String, SellInStatementDetail__c>>> sellInStatementDetailsMap = new Map<String, Map<Integer, Map<String, SellInStatementDetail__c>>>();
            for (SellInStatement__c item : sellInStatementsMap.values()) {
                String sellInStatementKey = String.valueOf(item.NegoScope__c) + Integer.valueOf(item.ReferenceYear__c) + item.PeriodType__c;
                Integer currentPeriodNumber = Integer.valueOf(item.PeriodNumber__c);
                if(!sellInStatementDetailsMap.containsKey(sellInStatementKey)) sellInStatementDetailsMap.put(sellInStatementKey, new Map<Integer, Map<String, SellInStatementDetail__c>>());
                sellInStatementDetailsMap.get(sellInStatementKey).put(currentPeriodNumber, new Map<String, SellInStatementDetail__c>());
                for(SellInStatementDetail__c sellInStatementDetail : item.SSDSellInStatement__r) {
                    String sellInStatementDetailKey = (sellInStatementKey
                                                       + String.valueOf(sellInStatementDetail.BusinessUnit__c)
                                                       + (sellInStatementDetail.NegoScopeReference__c != null ? String.valueOf(sellInStatementDetail.NegoScopeReference__c) : '')
                                                       + (sellInStatementDetail.IsCustomDateRange__c != null ? String.valueOf(sellInStatementDetail.IsCustomDateRange__c) : '')
                                                       + (sellInStatementDetail.CustomBDate__c != null ? String.valueOf(sellInStatementDetail.CustomBDate__c) : '')
                                                       + (sellInStatementDetail.CustomEDate__c != null ? String.valueOf(sellInStatementDetail.CustomEDate__c) : ''));
                    sellInStatementDetailsMap.get(sellInStatementKey).get(currentPeriodNumber).put(sellInStatementDetailKey, sellInStatementDetail);
                    // update next SellInStatementDetail__c
                    if(firstSellInStatementPeriodNumberMap.containsKey(sellInStatementKey) && firstSellInStatementPeriodNumberMap.get(sellInStatementKey) < currentPeriodNumber) {
                        SellInStatementDetail__c updatedSellInStatementDetail = sellInStatementDetail.clone(true);
                        updatedSellInStatementDetail.SellInDiscRegularYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscPromoYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscTotalYTD__c = 0;
                        updatedSellInStatementDetail.SellInNonDiscYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscRegularQtyYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscPromoQtyYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscTotalQtyYTD__c = 0;
                        updatedSellInStatementDetail.SellInNonDiscQtyYTD__c = 0;
                        updatedSellInStatementDetail.SellInDiscRegularTTM__c = 0;
                        updatedSellInStatementDetail.SellInDiscPromoTTM__c = 0;
                        updatedSellInStatementDetail.SellInDiscTotalTTM__c = 0;
                        updatedSellInStatementDetail.SellInNonDiscTTM__c = 0;
                        updatedSellInStatementDetail.SellInDiscRegularQtyTTM__c = 0;
                        updatedSellInStatementDetail.SellInDiscPromoQtyTTM__c = 0;
                        updatedSellInStatementDetail.SellInDiscTotalQtyTTM__c = 0;
                        updatedSellInStatementDetail.SellInNonDiscQtyTTM__c = 0;
                        sellInStatementDetailsToUpdateMap.put(sellInStatementDetail.Id, updatedSellInStatementDetail);
                    }
                }
            }
            for (SellInStatementDetail__c item : sellInStatementDetailsToUpdateMap.values()) {
                SellInStatement__c sellInStatement = sellInStatementsMap.get(item.SellInStatement__c);
                if(sellInStatement == null) continue;
                Integer currentPeriodNumber = Integer.valueOf(sellInStatement.PeriodNumber__c);
                String sellInStatementKey = String.valueOf(sellInStatement.NegoScope__c) + Integer.valueOf(sellInStatement.ReferenceYear__c) + sellInStatement.PeriodType__c;
                String sellInStatementDetailKey = (sellInStatementKey
                                                   + String.valueOf(item.BusinessUnit__c)
                                                   + (item.NegoScopeReference__c != null ? String.valueOf(item.NegoScopeReference__c) : '')
                                                   + (item.IsCustomDateRange__c != null ? String.valueOf(item.IsCustomDateRange__c) : '')
                                                   + (item.CustomBDate__c != null ? String.valueOf(item.CustomBDate__c) : '')
                                                   + (item.CustomEDate__c != null ? String.valueOf(item.CustomEDate__c) : ''));
                String sellInStatementHistoryKey = String.valueOf(sellInStatement.NegoScope__c) + Integer.valueOf(sellInStatement.ReferenceYear__c - 1) + sellInStatement.PeriodType__c;
                String sellInStatementDetailHistoryKey = (sellInStatementHistoryKey
                                                          + String.valueOf(item.BusinessUnit__c)
                                                          + (item.NegoScopeReference__c != null ? String.valueOf(item.NegoScopeReference__c) : '')
                                                          + (item.IsCustomDateRange__c != null ? String.valueOf(item.IsCustomDateRange__c) : '')
                                                          + (item.CustomBDate__c != null ? String.valueOf(item.CustomBDate__c) : '')
                                                          + (item.CustomEDate__c != null ? String.valueOf(item.CustomEDate__c) : ''));
                // calculate YTD values
                if(sellInStatementDetailsMap.containsKey(sellInStatementKey)) {
                    Map<Integer, Map<String, SellInStatementDetail__c>> sellInStatementDetailsByPeriodNumberMap = sellInStatementDetailsMap.get(sellInStatementKey);
                    for(Integer periodNumber : sellInStatementDetailsByPeriodNumberMap.keySet()) {
                        if(periodNumber <= currentPeriodNumber && sellInStatementDetailsByPeriodNumberMap.get(periodNumber).containsKey(sellInStatementDetailKey)) {
                            SellInStatementDetail__c sellInStatementDetail = sellInStatementDetailsByPeriodNumberMap.get(periodNumber).get(sellInStatementDetailKey);
                            item.SellInDiscRegularYTD__c += (sellInStatementDetail.SellInDiscRegularP__c != null ? sellInStatementDetail.SellInDiscRegularP__c : 0);
                            item.SellInDiscPromoYTD__c += (sellInStatementDetail.SellInDiscPromoP__c != null ? sellInStatementDetail.SellInDiscPromoP__c : 0);
                            item.SellInDiscTotalYTD__c += (sellInStatementDetail.SellInDiscTotalP__c != null ? sellInStatementDetail.SellInDiscTotalP__c : 0);
                            item.SellInNonDiscYTD__c += (sellInStatementDetail.SellInNonDiscP__c != null ? sellInStatementDetail.SellInNonDiscP__c : 0);
                            item.SellInDiscRegularQtyYTD__c += (sellInStatementDetail.SellInDiscRegularQtyP__c != null ? sellInStatementDetail.SellInDiscRegularQtyP__c : 0);
                            item.SellInDiscPromoQtyYTD__c += (sellInStatementDetail.SellInDiscPromoQtyP__c != null ? sellInStatementDetail.SellInDiscPromoQtyP__c : 0);
                            item.SellInDiscTotalQtyYTD__c += (sellInStatementDetail.SellInDiscTotalQtyP__c != null ? sellInStatementDetail.SellInDiscTotalQtyP__c : 0);
                            item.SellInNonDiscQtyYTD__c += (sellInStatementDetail.SellInNonDiscQtyP__c != null ? sellInStatementDetail.SellInNonDiscQtyP__c : 0);
                        }
                    }
                }
                // calculate TTM values
                item.SellInDiscRegularTTM__c = item.SellInDiscRegularYTD__c;
                item.SellInDiscPromoTTM__c = item.SellInDiscPromoYTD__c;
                item.SellInDiscTotalTTM__c = item.SellInDiscTotalYTD__c;
                item.SellInNonDiscTTM__c = item.SellInNonDiscYTD__c;
                item.SellInDiscRegularQtyTTM__c = item.SellInDiscRegularQtyYTD__c;
                item.SellInDiscPromoQtyTTM__c = item.SellInDiscPromoQtyYTD__c;
                item.SellInDiscTotalQtyTTM__c = item.SellInDiscTotalQtyYTD__c;
                item.SellInNonDiscQtyTTM__c = item.SellInNonDiscQtyYTD__c;
                if(sellInStatementDetailsMap.containsKey(sellInStatementHistoryKey)) {
                    Map<Integer, Map<String, SellInStatementDetail__c>> sellInStatementDetailsByPeriodNumberMap = sellInStatementDetailsMap.get(sellInStatementHistoryKey);
                    for(Integer periodNumber : sellInStatementDetailsByPeriodNumberMap.keySet()) {
                        if(periodNumber > currentPeriodNumber && sellInStatementDetailsByPeriodNumberMap.get(periodNumber).containsKey(sellInStatementDetailHistoryKey)) {
                            SellInStatementDetail__c sellInStatementDetail = sellInStatementDetailsByPeriodNumberMap.get(periodNumber).get(sellInStatementDetailHistoryKey);
                            item.SellInDiscRegularTTM__c += (sellInStatementDetail.SellInDiscRegularP__c != null ? sellInStatementDetail.SellInDiscRegularP__c : 0);
                            item.SellInDiscPromoTTM__c += (sellInStatementDetail.SellInDiscPromoP__c != null ? sellInStatementDetail.SellInDiscPromoP__c : 0);
                            item.SellInDiscTotalTTM__c += (sellInStatementDetail.SellInDiscTotalP__c != null ? sellInStatementDetail.SellInDiscTotalP__c : 0);
                            item.SellInNonDiscTTM__c += (sellInStatementDetail.SellInNonDiscP__c != null ? sellInStatementDetail.SellInNonDiscP__c : 0);
                            item.SellInDiscRegularQtyTTM__c += (sellInStatementDetail.SellInDiscRegularQtyP__c != null ? sellInStatementDetail.SellInDiscRegularQtyP__c : 0);
                            item.SellInDiscPromoQtyTTM__c += (sellInStatementDetail.SellInDiscPromoQtyP__c != null ? sellInStatementDetail.SellInDiscPromoQtyP__c : 0);
                            item.SellInDiscTotalQtyTTM__c += (sellInStatementDetail.SellInDiscTotalQtyP__c != null ? sellInStatementDetail.SellInDiscTotalQtyP__c : 0);
                            item.SellInNonDiscQtyTTM__c += (sellInStatementDetail.SellInNonDiscQtyP__c != null ? sellInStatementDetail.SellInNonDiscQtyP__c : 0);
                        }
                    }
                }
            }
        }
        if (!sellInStatementDetailsToUpdateMap.isEmpty()) {
            Database.update(sellInStatementDetailsToUpdateMap.values(), false);
        }
    }
    
    /*
     * @description Execute SSDtoCSISynchroBatch when SellInStatementDetail status is changed to Validated
     */
    private static void executeSSDtoCSISynchroBatchOnValidation(List<SellInStatementDetail__c> nSellInStatementDetails, Map<Id, SellInStatementDetail__c> oSellInStatementDetailsMap) {
        Set<Id> lstSSId = new Set<Id>();
        for (SellInStatementDetail__c item : nSellInStatementDetails) {
            if (oSellInStatementDetailsMap != null
                && oSellInStatementDetailsMap.containsKey(item.Id)
                && item.Status__c == 'Validated'
                && item.Status__c != oSellInStatementDetailsMap.get(item.Id).Status__c)
            {
                lstSSId.add(item.SellInStatement__c);
            }
        }
        if (!lstSSId.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object> {
                'startedFrom' => Trg_SellInStatementDetail_Handler.class.getName(),
                'sellInStatementIds' => lstSSId,
                'contractIds' => null
            };
            NegoptimBatch.executeBatch('SSDtoCSISynchroBatch', paramsMap, 100);
        }
    }
}