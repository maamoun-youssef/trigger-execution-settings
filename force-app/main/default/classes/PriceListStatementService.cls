public class PriceListStatementService {

    public static Map<String, List<PriceListStatement__c>> getRelatedHMP(List<PriceListStatement__c> priceListStatements, Integer year) {
        Map<String, List<PriceListStatement__c>> relatedHmpMap = new Map<String, List<PriceListStatement__c>>();
        // get related HMPs
        Set<Id> nsIds = new Set<Id>();
        Set<Decimal> versionSets = new Set<Decimal>();
        Set<Id> refHmpIds = new Set<Id>();
        Set<Id> refHmpRT = new Set<Id>();
        for (PriceListStatement__c item : priceListStatements) {
            nsIds.add(item.NegoScope__c);
            versionSets.add(item.Version__c);
            if (item.RecordType.DeveloperName == 'Simulation') {
                refHmpIds.add(item.PriceListStatementReference__r.PriceListStatementReference__c);
                refHmpRT.add(item.PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId);
            }
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                refHmpIds.add(item.PriceListStatementReference__c);
                refHmpRT.add(item.PriceListStatementReference__r.RecordTypeId);
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                 refHmpIds.add(item.Id);
                 refHmpRT.add(item.RecordTypeId);
            }
        }
        for (PriceListStatement__c item : [SELECT Id, NegoScope__c, Version__c, /***SPITM_PriceList_Statement_Type__c,***/
                                                            PriceListStatementReference__c,Recordtype.developername,Recordtypeid,
                                                            PriceListStatementReference__r.Recordtype.developername,
                                                            PriceListStatementReference__r.Recordtypeid,
                                                            PriceListStatementReference__r.PriceListStatementReference__r.Recordtype.developername,
                                                            PriceListStatementReference__r.PriceListStatementReference__r.Recordtypeid
                                                            FROM PriceListStatement__c
                                                            WHERE NegoScope__c IN :nsIds
                                                            AND Version__c IN :versionSets
                                                            AND ReferenceYear__c = :year])
        {
            string key = item.NegoScope__c
                + '' + (string.valueof(item.Version__c != null ? (Integer)item.Version__c : 1))
                /***+ '' + item.SPITM_PriceList_Statement_Type__c***/;
            if (item.RecordType.DeveloperName == 'IsoPartner') {
               key += + '' + item.PriceListStatementReference__r.Recordtypeid;
            }
            if (item.RecordType.DeveloperName == 'Simulation') {
                key += + '' + item.PriceListStatementReference__r.PriceListStatementReference__r.Recordtypeid;
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                key += + '' + item.Recordtypeid;
            }
            if (!relatedHmpMap.containskey(key)) relatedHmpMap.put(key, new List<PriceListStatement__c>());
            relatedHmpMap.get(key).add(item);
        }
        return relatedHmpMap;
    }
    /**
     * @Description Get all related HMP for the supplied list of price lists, if you choose to manually supply the field make sure to include negoscope__c, id and recordtypeId
     * */
    public static Map<String, List<PriceListStatement__c>> getRelatedHMP(List<PriceListStatement__c> priceListStatements, List<String> fields) {
        Map<String, List<PriceListStatement__c>> relatedHmpMap = new Map<String, List<PriceListStatement__c>>();
        // get related HMPs
        Set<Id> refHmpIds = new Set<Id>();
        Set<Id> refHmpRT = new Set<Id>();
        for (PriceListStatement__c item : priceListStatements) {
            if (item.RecordType.DeveloperName == 'Simulation') {
                refHmpIds.add(item.PriceListStatementReference__r.PriceListStatementReference__c);
                refHmpRT.add(item.PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId);
            }
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                refHmpIds.add(item.PriceListStatementReference__c);
                refHmpRT.add(item.PriceListStatementReference__r.RecordTypeId);
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                refHmpIds.add(item.Id);
                refHmpRT.add(item.RecordTypeId);
            }
        }
        if (fields == null || fields.isEmpty()) {
            fields = new List<String>(Schema.getGlobalDescribe().get('PriceListStatement__c').getDescribe().fields.getMap().keyset());
        }
        String query = 'SELECT Recordtype.DeveloperName, ' + String.join(fields, ' , ');
        query += ' ,PriceListStatementReference__r.Recordtype.developername,';
        query += ' PriceListStatementReference__r.Recordtypeid,';
        query += ' PriceListStatementReference__r.PriceListStatementReference__r.Recordtype.developername,';
        query += ' PriceListStatementReference__r.PriceListStatementReference__r.Recordtypeid';
        query += ' FROM PriceListStatement__c';
        query += ' WHERE Id IN :refHmpIds';
        query += ' OR PriceListStatementReference__c IN :refHmpIds';
        query += ' OR PriceListStatementReference__r.PriceListStatementReference__c IN :refHmpIds';
        System.debug('query >> ' + query);
        for (PriceListStatement__c item : Database.query(query)) {
            string key = item.NegoScope__c
                + '' + (string.valueof(item.Version__c != null ? (Integer)item.Version__c : 1))
                /***+ '' + item.SPITM_PriceList_Statement_Type__c***/;
            if (item.RecordType.DeveloperName == 'IsoPartner') {
                key += + '' + item.PriceListStatementReference__r.Recordtypeid;
            }
            if (item.RecordType.DeveloperName == 'Simulation') {
                key += + '' + item.PriceListStatementReference__r.PriceListStatementReference__r.Recordtypeid;
            }
            if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                key += + '' + item.Recordtypeid;
            }
            if (!relatedHmpMap.containskey(key)) relatedHmpMap.put(key, new List<PriceListStatement__c>());
            relatedHmpMap.get(key).add(item);
        }
        return relatedHmpMap;
    }
    public static Map<Id, PriceListStatement__c> synchroRateWithRelatedHmp(PriceListStatement__c pricelistStatement, Map<String, List<PriceListStatement__c>> relatedHmpMap, Map<Id, PriceListStatement__c> updatedReatedHMP) {
        /*
            Vision fr	BT Vision Fournisseur	PriceEvolutionRateRequested__c
                        BT Vision ITM	SPITM_Reference_Depreciation_Rate_BT__c
                        BT Validee CG	PriceEvolutionRateValidated__c
                        BT Retenus Achats	SPITM_Depreciation_Rate_Negotiated__c

            			hMP Vision Fournisseur	PriceEvolutionRateRequested__c
                        HMP Vision ITM	SPITM_Reference_Rise_Rate__c
                        HMP Validee CG	PriceEvolutionRateValidated__c
                        HMP Retenue Achats	PriceEvolutionRateNegotiated__c

            vision ITM	BT vision Fournisseur	PriceEvolutionRateRequested__c
                        BT Vision ITM	SPITM_Reference_Depreciation_Rate_BT__c
                        BT Validée CG	PriceEvolutionRateValidated__c
                        BT Retenue Achats	SPITM_Depreciation_Rate_Negotiated__c

                        HMP Vision Fournisseur	PriceEvolutionRateRequested__c
                        HMP Vision ITM	SPITM_Reference_Rise_Rate__c
                        HMP valide CG	PriceEvolutionRateValidated__c
                        hmp retenue achat	PriceEvolutionRateNegotiated__c

            simualtion	BT Vision Fournisseur	PriceEvolutionRateRequested__c
                        BT Vision ITM	SPITM_Reference_Depreciation_Rate_BT__c
                        BT Validee CG	PriceEvolutionRateValidated__c
                        BT Retenus Achats	SPITM_Depreciation_Rate_Negotiated__c

                        HMP Vision Fournisseur	PriceEvolutionRateRequested__c
                        HMP Vision ITM	SPITM_Reference_Rise_Rate__c
                        HMP valide CG	PriceEvolutionRateValidated__c
                        hmp retenue achat	PriceEvolutionRateNegotiated__c
        */

        string key = pricelistStatement.NegoScope__c + '' + (string.valueof(pricelistStatement.Version__c != null ? (Integer)pricelistStatement.Version__c : 1)) /***+ '' + pricelistStatement.SPITM_PriceList_Statement_Type__c***/;
        if (pricelistStatement.RecordType.DeveloperName == 'IsoPartner') {
            key += + '' + pricelistStatement.PriceListStatementReference__r.Recordtypeid;
        }
        if (pricelistStatement.RecordType.DeveloperName == 'Simulation') {
            key += + '' + pricelistStatement.PriceListStatementReference__r.PriceListStatementReference__r.Recordtypeid;
        }
        if (pricelistStatement.RecordType.DeveloperName != 'Simulation' && pricelistStatement.RecordType.DeveloperName != 'IsoPartner') {
            key += + '' + pricelistStatement.Recordtypeid;
        }
        if (pricelistStatement.RecordType.Developername == 'DepreciationRate') {
            pricelistStatement.PriceEvolutionRateRequested__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                    //if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        hmpToUpdate.PriceEvolutionRateRequested__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                   // }
                }
            }
        }
        if (pricelistStatement.RecordType.Developername == 'RiseRate' || pricelistStatement.RecordType.Developername == 'Tariff' || pricelistStatement.RecordType.Developername == 'SPITM_Rise_Rate_Tentative') {
            pricelistStatement.PriceEvolutionRateRequested__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                    //if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        hmpToUpdate.PriceEvolutionRateRequested__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                    //}
                }
            }
        }
        if (pricelistStatement.RecordType.Developername == 'IsoPartner' /***&& pricelistStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate'***/) {
            /***pricelistStatement.SPITM_Reference_Depreciation_Rate_BT__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);***/
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                   // if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        /***hmpToUpdate.SPITM_Reference_Depreciation_Rate_BT__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);***/
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                   // }
                }
            }
        }
        if (pricelistStatement.RecordType.Developername == 'IsoPartner' /***&& pricelistStatement.SPITM_PriceList_Statement_Type__c == 'RiseRate'***/) {
            /***pricelistStatement.SPITM_Reference_Rise_Rate__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);***/
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                    //if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        /***hmpToUpdate.SPITM_Reference_Rise_Rate__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);***/
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                    //}
                }
            }
        }
        // TODO ADD SPITM_PriceList_Statement_Type__c
        /***if (pricelistStatement.Status__c == 'Validated') {
            if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                pricelistStatement.PriceEvolutionRateValidated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            }
            if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                pricelistStatement.PriceEvolutionRateValidated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            }
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                    //if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                            hmpToUpdate.PriceEvolutionRateValidated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        } else {
                            hmpToUpdate.PriceEvolutionRateValidated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        }
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                   // }
                }
            }
        }
        if (pricelistStatement.Status__c == 'Request For Approval') {
            if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                pricelistStatement.SPITM_Depreciation_Rate_Negotiated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            }
            if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                pricelistStatement.PriceEvolutionRateNegotiated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
            }
            if (relatedhmpMap.containskey(key)) {
                for (PriceListStatement__c related : relatedhmpMap.get(key)) {
                   // if (pricelistStatement.Id != related.Id) {
                        PriceListStatement__c hmpToUpdate =  updatedReatedHMP.Containskey(related.Id) ? updatedReatedHMP.get(related.Id) : related;
                        if (pricelistStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                            hmpToUpdate.SPITM_Depreciation_Rate_Negotiated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        } else {
                            hmpToUpdate.PriceEvolutionRateNegotiated__c = pricelistStatement.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        }
                        updatedReatedHMP.put(related.Id, hmpToUpdate);
                   // }
                }
            }
        }***/
        return updatedReatedHMP;
    }
    /**
        * @description ON AFTER UPDATE
        * calculate PriceEvolutionRateCalculated__c and PriceEvolutionRateCalculated__c
    */
    public static void calculateRate(List<PriceListStatement__c> scope, Integer year) {
        Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
        Set<Id> riseRateRecordtypeIdSet = new Set<Id>();
        Set<Id> depreciationRateRecordtypeIdSet = new Set<Id>();
        Map<Id, PriceListStatement__c> updatedReatedHMP = new Map<Id, PriceListStatement__c>();

        Map<String, List<PriceListStatement__c>> relatedHmpMap = getRelatedHMP(scope, year);
        Id tariff_RTId = priceListStatementRTIds.containsKey('Tariff') ? priceListStatementRTIds.get('Tariff') : null;
        Id tentative_RTId = priceListStatementRTIds.containsKey('SPITM_Rise_Rate_Tentative') ? priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative') : null;
        riseRateRecordtypeIdSet.add(priceListStatementRTIds.get('RiseRate'));
        if (tariff_RTId != null) {
            riseRateRecordtypeIdSet.add(tariff_RTId);
        }
        if (tentative_RTId != null) {
            riseRateRecordtypeIdSet.add(tentative_RTId);
        }
        depreciationRateRecordtypeIdSet.add(priceListStatementRTIds.get('DepreciationRate'));
        // calculate Depreciation_Rate/Rise_Rate = SUM(SellIn * CostPrice_GAP__c)/SUM(Sellin*GrossPricePrevious__c)
        Map<Id, Map<String, List<Decimal>>> totalRatesMap = new Map<Id, Map<String, List<Decimal>>>();
        List<AggregateResult> results = [SELECT PriceListStatement__c PriceListStatement__c,
                                         SUM(SellInTotalQtywUnitGrossPriceGap__c) SellInTotalQtywUnitGrossPriceGap__c, SUM(SellInTotalQtywUnitGrossPriceP1__c) SellInTotalQtywUnitGrossPriceP1__c,
                                         SUM(SellInTotalQtywGrossPricewNetTaxGap__c) SellInTotalQtywGrossPricewNetTaxGap__c, SUM(SellInTotalQtywGrossPricewNetTaxP1__c) SellInTotalQtywGrossPricewNetTaxP1__c,
                                         SUM(SellInTotalQtywUnitGrossPricewNetTaxGap__c) SellInTotalQtywUnitGrossPricewNetTaxGap__c, SUM(SellInTotalQtywUnitGrossPricewNetTaxP1__c) SellInTotalQtywUnitGrossPricewNetTaxP1__c,
                                         SUM(SellInTotalQtyTaxesGap__c) SellInTotalQtyTaxesGap__c, SUM(SellInTotalQtyTaxesP1__c) SellInTotalQtyTaxesP1__c, SUM(SellInTotalQtywGrossPriceP1__c) SellInTotalQtywGrossPriceP1__c
                                         FROM PriceListStatementDetail__c
                                         WHERE PriceListStatement__c IN :scope
                                         AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)
                                         GROUP BY PriceListStatement__c];
        for (AggregateResult item : results) {
            Id priceListStatementId = (Id) item.get('PriceListStatement__c');
            if (!totalRatesMap.containsKey(priceListStatementId)) {
                totalRatesMap.put(priceListStatementId, new Map<String, List<Decimal>>());
                totalRatesMap.get(priceListStatementId).put('Rise_PriceEvolutionRateCalculated__c', new List<Decimal>{0, 0});
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name, new List<Decimal>{0, 0});
                ////totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.ULiT_Negoptim__SellIn_Total_wCostPrice_P1__c.Name, new List<Decimal>{0, 0});
            }
            Map<String, List<Decimal>> totalsMap = totalRatesMap.get(priceListStatementId);
            totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[0] += item.get('SellInTotalQtywUnitGrossPriceGap__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPriceGap__c') : 0;
            totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[1] += item.get('SellInTotalQtywUnitGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPriceP1__c') : 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywGrossPricewNetTaxGap__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPricewNetTaxGap__c') : 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellInTotalQtywGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPricewNetTaxP1__c'): 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') : 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') : 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0] += item.get('SellInTotalQtyTaxesGap__c') != null ? (Decimal)item.get('SellInTotalQtyTaxesGap__c') : 0;
            totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1] += item.get('SellInTotalQtyTaxesP1__c') != null ? (Decimal)item.get('SellInTotalQtyTaxesP1__c') : 0;
            ////totalsMap.get(SObjectType.PriceListStatement__c.fields.ULiT_Negoptim__SellIn_Total_wCostPrice_P1__c.Name)[0] += item.get('SellInTotalQtywGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPriceP1__c') : 0;
            totalRatesMap.put(priceListStatementId, totalsMap);
        }
        if (!totalRatesMap.isEmpty()) {
            for (PriceListStatement__c item : scope) {
                Map<String, List<Decimal>> totalsMap = totalRatesMap.get(item.Id);
                if(totalsMap == null) continue;
                Decimal sellInTotalUnitGap = 0, sellInTotalUnitP1 = 0, sellInTotalwNetTaxGap = 0, sellInTotalwNetTaxP1 = 0, sellInTotalUnitwNetTaxGap = 0, sellInTotalUnitwNetTaxP1 = 0, sellInTotalTaxesGap = 0, sellInTotalTaxesP1 = 0, SellInTotalwCostPriceP1 = 0;
                sellInTotalUnitGap = totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[0];
                sellInTotalUnitP1 = totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[1];
                sellInTotalwNetTaxGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0];
                sellInTotalwNetTaxP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1];
                sellInTotalUnitwNetTaxGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0];
                sellInTotalUnitwNetTaxP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1];
                sellInTotalTaxesGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0];
                sellInTotalTaxesP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1];
                ////SellInTotalwCostPriceP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.ULiT_Negoptim__SellIn_Total_wCostPrice_P1__c.Name)[0];
                Decimal riseDepreciationRateCalculated = sellInTotalUnitP1 != 0 ? (sellInTotalUnitGap/sellInTotalUnitP1) * 100 : 0;
                Decimal riseRateCostPricewNetTaxCalculated = sellInTotalwNetTaxP1 != 0 ? (sellInTotalwNetTaxGap/sellInTotalwNetTaxP1) * 100 : 0;
                Decimal riseRateCostPriceUnitwNetTaxCalculated = sellInTotalUnitwNetTaxP1 != 0 ? (sellInTotalUnitwNetTaxGap/sellInTotalUnitwNetTaxP1) * 100 : 0;
                Decimal riseRateTaxCalculated = sellInTotalTaxesP1 != 0 ? (sellInTotalTaxesGap/sellInTotalTaxesP1) * 100 : 0;
                Id refRecordTypeId = item.PriceListStatementReference__r?.RecordTypeId;
                Id refRef_RecordTypeId = item.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordTypeId;
                Boolean isRiseRate = riseRateRecordtypeIdSet.contains(item.RecordTypeId);
                Boolean isDepreciationRate = depreciationRateRecordtypeIdSet.contains(item.RecordTypeId);
                Boolean isoPartner_From_RiseRate = item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && riseRateRecordtypeIdSet.contains(refRecordTypeId);
                Boolean isoPartner_From_Depreciation_Rate = item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && depreciationRateRecordtypeIdSet.contains(refRecordTypeId);
                Boolean simulation_From_RiseRate = item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (riseRateRecordtypeIdSet.contains(refRef_RecordTypeId) || riseRateRecordtypeIdSet.contains(refRecordTypeId));
                Boolean simulation_From_Depreciation_Rate = item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (depreciationRateRecordtypeIdSet.contains(refRef_RecordTypeId) || depreciationRateRecordtypeIdSet.contains(refRecordTypeId));
                if (isDepreciationRate || isoPartner_From_Depreciation_Rate || simulation_From_Depreciation_Rate) {
                    if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                        Integer commentLength =  Schema.SObjectType.PriceListStatement__c.fields.getMap().get(SObjectType.PriceListStatement__c.fields.Comment__c.Name).getDescribe().getLength();
                        item.Comment__c = item.Comment__c != null && item.Comment__c.Length() < (commentLength - 700) ? item.Comment__c + ' \n ' : '';
                        Decimal depTop = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                        item.PriceEvolutionRateCalculated__c = (riseDepreciationRateCalculated < depTop && riseDepreciationRateCalculated > -depTop) ? riseDepreciationRateCalculated : (riseDepreciationRateCalculated > 0 ? depTop - 1 : -depTop + 1);
                        if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                            item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to ' + item.PriceEvolutionRateCalculated__c + ' \n';
                        }
                    }
                }
                if (isRiseRate || isoPartner_From_RiseRate || simulation_From_RiseRate) {
                    Integer commentLength =  Schema.SObjectType.PriceListStatement__c.fields.getMap().get(SObjectType.PriceListStatement__c.fields.Comment__c.Name).getDescribe().getLength();
                    item.Comment__c = item.Comment__c != null && item.Comment__c.Length() < (commentLength - 700) ? item.Comment__c + ' \n ' : '';
                    Decimal top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                    if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                        item.PriceEvolutionRateCalculated__c = (riseDepreciationRateCalculated < top && riseDepreciationRateCalculated > -top) ? riseDepreciationRateCalculated : (riseDepreciationRateCalculated > 0 ? top - 1 : -top + 1);
                        if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                            item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to ' + item.PriceEvolutionRateCalculated__c + ' \n';
                        }
                    }
                    top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                    if (item.PriceEvolutionRateInclTaxCalculated__c != riseRateCostPricewNetTaxCalculated) {
                        item.PriceEvolutionRateInclTaxCalculated__c = (riseRateCostPricewNetTaxCalculated < top && riseRateCostPricewNetTaxCalculated > -top) ? riseRateCostPricewNetTaxCalculated : (riseRateCostPricewNetTaxCalculated > 0 ? top - 1 : -top + 1);
                        if (item.PriceEvolutionRateInclTaxCalculated__c != riseRateCostPricewNetTaxCalculated) {
                            item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name + ') result : ' + String.valueOf(riseRateCostPricewNetTaxCalculated)  + ' Adjusted to with ' +item.PriceEvolutionRateInclTaxCalculated__c + ' \n';
                        }
                    }
                    top = (10.0).pow(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.scale);
                    if (item.UnitPriceEvolutionRateInclTaxCalculated__c != riseRateCostPriceUnitwNetTaxCalculated) {
                        item.UnitPriceEvolutionRateInclTaxCalculated__c = (riseRateCostPriceUnitwNetTaxCalculated < top && riseRateCostPriceUnitwNetTaxCalculated > -top) ? riseRateCostPriceUnitwNetTaxCalculated : (riseRateCostPriceUnitwNetTaxCalculated > 0 ? top - 1 : -top + 1);
                        if (item.UnitPriceEvolutionRateInclTaxCalculated__c != riseRateCostPriceUnitwNetTaxCalculated) {
                            item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name + ') result : ' + String.valueOf(riseRateCostPriceUnitwNetTaxCalculated)  + ' Adjusted to with ' +item.UnitPriceEvolutionRateInclTaxCalculated__c + ' \n';
                        }
                    }
                    top = (10.0).pow(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.scale);
                    if (item.TaxEvolutionRateCalculated__c != riseRateTaxCalculated) {
                        item.TaxEvolutionRateCalculated__c = (riseRateTaxCalculated < top && riseRateTaxCalculated > -top) ? riseRateTaxCalculated : (riseRateTaxCalculated > 0 ? top - 1 : -top + 1);
                        if (item.TaxEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                            item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to with ' + item.TaxEvolutionRateCalculated__c + ' \n';
                        }
                    }
                }
                ////item.ULiT_Negoptim__SellIn_Total_wCostPrice_P1__c = SellInTotalwCostPriceP1;
                updatedReatedHMP = synchroRateWithRelatedHmp(item, relatedHmpMap, updatedReatedHMP);
            }
            Database.update(scope, false);
            if (updatedReatedHMP.size() > 0) {
                Database.update(updatedReatedHMP.values(), false);
            }
        }
    }
    
    /**
        * @description ON AFTER UPDATE
        * calculate PriceEvolutionRateCalculated__c and PriceEvolutionRateCalculated__c
    */
    public static List<PriceListStatement__c> calculateSellInFields(List<PriceListStatement__c> scope) {
        Map<Id, Map<String, Decimal>> totalRatesMap = new Map<Id, Map<String, Decimal>>();
        List<AggregateResult> results = [SELECT PriceListStatement__c PriceListStatement__c,
                                         SUM(SellInTotalQtywUnitGrossPriceP1__c) SellInTotalQtywUnitGrossPriceP1__c,
                                         SUM(SellInTotalQtywGrossPricewNetTaxP1__c) SellInTotalQtywGrossPricewNetTaxP1__c,
                                         SUM(SellInTotalQtywUnitGrossPricewNetTaxP1__c) SellInTotalQtywUnitGrossPricewNetTaxP1__c,
                                         SUM(SellInTotalQtyTaxesP1__c) SellInTotalQtyTaxesP1__c, SUM(SellInTotalQtywGrossPriceP1__c) SellInTotalQtywGrossPriceP1__c
                                         FROM PriceListStatementDetail__c
                                         WHERE PriceListStatement__c IN :scope
                                         AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)
                                         GROUP BY PriceListStatement__c];
        for (AggregateResult item : results) {
            Id priceListStatementId = (Id) item.get('PriceListStatement__c');
            if (!totalRatesMap.containsKey(priceListStatementId)) {
                totalRatesMap.put(priceListStatementId, new Map<String, Decimal>());
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name, item.get('SellInTotalQtywGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPriceP1__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPricewNetTaxP1__c.Name, item.get('SellInTotalQtywGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPricewNetTaxP1__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPriceP1__c.Name, item.get('SellInTotalQtywUnitGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPriceP1__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtyTaxesP1__c .Name, item.get('SellInTotalQtyTaxesP1__c') != null ? (Decimal)item.get('SellInTotalQtyTaxesP1__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPricewNetTaxP1__c .Name, item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') : 0);
            }
        }
        if (!totalRatesMap.isEmpty()) {
            for (PriceListStatement__c item : scope) {
                Map<String, Decimal> totalsMap = totalRatesMap.get(item.Id);
                if(totalsMap == null) continue;
                item.SellInTotalQtywGrossPriceP1__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name);
                item.SellInTotalQtywGrossPricewNetTaxP1__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPricewNetTaxP1__c.Name);
                item.SellInTotalQtywUnitGrossPriceP1__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPriceP1__c.Name);
                item.SellInTotalQtyTaxesP1__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtyTaxesP1__c.Name);
                item.SellInTotalQtywUnitGrossPricewNetTaxP1__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywUnitGrossPricewNetTaxP1__c.Name);
            }
            return scope;
            //Database.update(scope, false);
        }
        return null;
    }
    
    /**
        * @description ON AFTER UPDATE
        * calculate PriceEvolutionRateCalculated__c and PriceEvolutionRateCalculated__c
    */
    public static List<PriceListStatement__c> calculateEvolutions(List<PriceListStatement__c> scope) {
        Map<Id, Map<String, Decimal>> totalRatesMap = new Map<Id, Map<String, Decimal>>();
        List<AggregateResult> results = [SELECT PriceListStatement__c PriceListStatement__c,
                                         SUM(PriceEvolutionRateCalculated__c) PriceEvolutionRateCalculated__c,
                                         SUM(PriceEvolutionRateInclTaxCalculated__c) PriceEvolutionRateInclTaxCalculated__c,
                                         SUM(UnitPriceEvolutionRateCalculated__c) UnitPriceEvolutionRateCalculated__c,
                                         SUM(UnitPriceEvolutionRateInclTaxCalculated__c) UnitPriceEvolutionRateInclTaxCalculated__c,
                                         SUM(TaxEvolutionRateCalculated__c) TaxEvolutionRateCalculated__c
                                         FROM PriceListStatementDetail__c
                                         WHERE PriceListStatement__c IN :scope
                                         AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)
                                         GROUP BY PriceListStatement__c];
        for (AggregateResult item : results) {
            Id priceListStatementId = (Id) item.get('PriceListStatement__c');
            if (!totalRatesMap.containsKey(priceListStatementId)) {
                totalRatesMap.put(priceListStatementId, new Map<String, Decimal>());
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name, item.get('PriceEvolutionRateCalculated__c') != null ? (Decimal)item.get('PriceEvolutionRateCalculated__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name, item.get('PriceEvolutionRateInclTaxCalculated__c') != null ? (Decimal)item.get('PriceEvolutionRateInclTaxCalculated__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateCalculated__c.Name, item.get('UnitPriceEvolutionRateCalculated__c') != null ? (Decimal)item.get('UnitPriceEvolutionRateCalculated__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name, item.get('UnitPriceEvolutionRateInclTaxCalculated__c') != null ? (Decimal)item.get('UnitPriceEvolutionRateInclTaxCalculated__c') : 0);
                totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c .Name, item.get('TaxEvolutionRateCalculated__c') != null ? (Decimal)item.get('TaxEvolutionRateCalculated__c') : 0);
            }
        }
        if (!totalRatesMap.isEmpty()) {
            for (PriceListStatement__c item : scope) {
                Map<String, Decimal> totalsMap = totalRatesMap.get(item.Id);
                if(totalsMap == null) continue;
                item.PriceEvolutionRateCalculated__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name);
                item.PriceEvolutionRateInclTaxCalculated__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name);
                item.UnitPriceEvolutionRateCalculated__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateCalculated__c.Name);
                item.UnitPriceEvolutionRateInclTaxCalculated__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name);
                item.TaxEvolutionRateCalculated__c = totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name);
            }
            return scope;
            //Database.update(scope, false);
        }
        return null;
    }

    /***public static void synchroToNegoPlan(List<PriceListStatement__c> validatedHMPList, Integer year) {
        Set<Id> nsIds = new Set<Id>();
        for(PriceListStatement__c item : validatedHMPList) {
            nsIds.add(item.NegoScope__c);
        }
        Map<Id, Nego_Plan__c> negoPlanMap = new Map<Id, Nego_Plan__c>();
        for (Nego_Plan__c item : [SELECT Id, NegoScope__c, Nego_Year__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Depreciation_Rate_Date__c,
                                                 NEGO_Depreciation_Rate_Validated_Nb__c, NEGO_Depreciation_Rate1_Validated__c, NEGO_Depreciation_Rate_Validated_YE__c,
                                                 NEGO_Depreciation_Rate2_Validated__c, NEGO_Depreciation_Rate3_Validated__c, NEGO_Depreciation_Rate_Date1__c, NEGO_Depreciation_Rate_Date2__c,
                                                 NEGO_Depreciation_Rate_Date3__c, NEGO_PriceEvolutionRateRequested__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Rise_Rate_Status__c, NEGO_Rise_Rate_Date__c,
                                                 NEGO_Rise_Rate_Negotiated_OnTop__c, NEGO_Rise_Rate_IsoPartner__c, NEGO_Rise_Rate_Requested_Date__c, NEGO_Rise_Rate_Validated_YE__c,
                                                 NEGO_Rise_Rate1_Validated__c, NEGO_Rise_Rate2_Validated__c, NEGO_Rise_Rate3_Validated__c, NEGO_Rise_Rate4_Validated__c,
                                                 NEGO_Rise_Rate5_Validated__c, NEGO_Rise_Rate6_Validated__c, NEGO_Rise_Rate7_Validated__c, NEGO_Rise_Rate8_Validated__c,
                                                 NEGO_Rise_Rate9_Validated__c, NEGO_Rise_Rate10_Validated__c, NEGO_Rise_Rate_Validated_Nb__c
                                                 FROM Nego_Plan__c
                                                 WHERE NegoScope__c = :nsIds
                                                 AND Nego_Year__c = :year])
        {
            negoPlanMap.put(item.NegoScope__c, item);
        }
        for(PriceListStatement__c priceListStatement : validatedHMPList) {
            Nego_Plan__c negoPlan = negoPlanMap.get(priceListStatement.NegoScope__c);
            if (priceListStatement.Status__c == 'Request for approval' || priceListStatement.Status__c == 'Validated') {
                if (priceListStatement.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                    Integer depreciationRateCount = 3;
                    String fieldName;
                    //Integer depreciationRateNb = (negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c != null ? Integer.valueOf(negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c) : 0) + 1;
                    Integer depreciationRateNb  = priceListStatement.Version__c != null ? (priceListStatement.Version__c > 3 ? 3 : Integer.valueOf(priceListStatement.Version__c)) : 1;
                    if (depreciationRateNb <= depreciationRateCount) {
                        fieldName = 'NEGO_Depreciation_Rate' + depreciationRateNb + '_Validated__c';
                        negoPlan.put(fieldName, (-1 * priceListStatement.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP)));
                        fieldName = 'NEGO_Depreciation_Rate_Date' + depreciationRateNb + '__c';
                        negoPlan.put(fieldName, priceListStatement.ApplicationDateValidated__c);
                        negoPlan.NEGO_PriceEvolutionRateValidated__c =  (-1 * priceListStatement.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP));
                        negoPlan.NEGO_Depreciation_Rate_Date__c = priceListStatement.ApplicationDateValidated__c;
                    }
                } else {
                    Integer riseRateCount = 10;
                    String fieldName;
                    //Integer riseRateNb = (negoPlan.NEGO_Rise_Rate_Validated_Nb__c != null ? Integer.valueOf(negoPlan.NEGO_Rise_Rate_Validated_Nb__c) : 0) + 1;
                    Integer riseRateNb = priceListStatement.Version__c != null ? (priceListStatement.Version__c > 10 ? 10 : Integer.valueOf(priceListStatement.Version__c)) : 1;
                    if (riseRateNb <= riseRateCount) {
                        // Fill Rise_Rate(i)__c = Rise_Rate__c and Rise_Rate_Exec_Date(i)__c Where i = Rise_Rate_Nb__c + 1
                        fieldName = 'NEGO_Rise_Rate' + riseRateNb + '_Validated__c';
                        negoPlan.put(fieldName, priceListStatement?.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP));
                        fieldName = 'NEGO_Rise_Rate_Date' + riseRateNb + '__c';
                        negoPlan.put(fieldName, priceListStatement.ApplicationDateValidated__c);
                        negoPlan.NEGO_PriceEvolutionRateValidated__c = priceListStatement.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        negoPlan.NEGO_Rise_Rate_Date__c = priceListStatement.ApplicationDateValidated__c;
                    }
                }
                negoPlanMap.put(priceListStatement.NegoScope__c, negoPlan);
            }
        }
        if(negoPlanMap.size() > 0) {
            update negoPlanMap.values();
        }
    }***/

    /***public static void riseRateTONegoPlan(List<PriceListStatement__c> hmpList, Integer year) {
        Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
        ID tariff_RTId = priceListStatementRTIds.get('Tariff');

        Set<Id> nsIds = new Set<Id>();
        Map<Id, Decimal> negoScopeTOVersionMap = new Map<Id, Decimal>();
        for(PriceListStatement__c item : hmpList) {
            nsIds.add(item.NegoScope__c);
        }
        Map<Id, Nego_Plan__c> negoPlanMap = new Map<Id, Nego_Plan__c>();
        Map<Id, Nego_Plan__c> negoPlanMapToUpdate = new Map<Id, Nego_Plan__c>();
        for (Nego_Plan__c item : [SELECT Id, NegoScope__c, Nego_Year__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Depreciation_Rate_Date__c,
                                                 NEGO_Depreciation_Rate_Validated_Nb__c, NEGO_Depreciation_Rate1_Validated__c, NEGO_Depreciation_Rate_Validated_YE__c,
                                                 NEGO_Depreciation_Rate2_Validated__c, NEGO_Depreciation_Rate3_Validated__c, NEGO_Depreciation_Rate_Date1__c, NEGO_Depreciation_Rate_Date2__c,
                                                 NEGO_Depreciation_Rate_Date3__c, NEGO_PriceEvolutionRateRequested__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Rise_Rate_Status__c, NEGO_Rise_Rate_Date__c,
                                                 NEGO_Rise_Rate_Negotiated_OnTop__c, NEGO_Rise_Rate_IsoPartner__c, NEGO_Rise_Rate_Requested_Date__c, NEGO_Rise_Rate_Validated_YE__c,
                                                 NEGO_Rise_Rate1_Validated__c, NEGO_Rise_Rate2_Validated__c, NEGO_Rise_Rate3_Validated__c, NEGO_Rise_Rate4_Validated__c,
                                                 NEGO_Rise_Rate5_Validated__c, NEGO_Rise_Rate6_Validated__c, NEGO_Rise_Rate7_Validated__c, NEGO_Rise_Rate8_Validated__c,
                                                 NEGO_Rise_Rate9_Validated__c, NEGO_Rise_Rate10_Validated__c, NEGO_Rise_Rate_Validated_Nb__c
                                                 FROM Nego_Plan__c
                                                 WHERE NegoScope__c = :nsIds
                                                 AND Nego_Year__c = :year])
        {
            negoPlanMap.put(item.NegoScope__c, item);
        }
        AggregateResult[] aggregateResultList = [SELECT NegoScope__c NegoScope__c, MAX(Version__c) Version__c
                                                 FROM PriceListStatement__c
                                                 WHERE NegoScope__c IN :nsIds
                                                 AND ReferenceYear__c = :year
                                                 AND RecordTypeId <>: tariff_RTId
                                                 GROUP BY NegoScope__c];

        if (!aggregateResultList.isEmpty()) {
            for (AggregateResult item : aggregateResultList) {
                Id NSId = (Id) item.get('NegoScope__c');
                Decimal versionNumber = (Decimal) item.get('Version__c');
                negoScopeTOVersionMap.put(NSId, versionNumber);
            }
            Map<Id, Set<String>> negoPlanStatusMap = new Map<Id, Set<String>>();
            List<PriceListStatement__c> lastPriceListStatement = [SELECT Id, NegoScope__c, OnTop__c,
                                                                                   PriceEvolutionRateCalculated__c, RecordType.DeveloperName, ApplicationDateValidated__c,
                                                                                   PriceListStatementReference__r.RecordType.DeveloperName,Status__c
                                                                                   FROM PriceListStatement__c
                                                                                   WHERE NegoScope__c IN :negoScopeTOVersionMap.keyset()
                                                                                   AND ReferenceYear__c = :year
                                                                                   AND Version__c IN: negoScopeTOVersionMap.values()
                                                                                   AND RecordTypeId <>: tariff_RTId
                                                                                   AND PriceListStatementReference__r.RecordTypeId <> :tariff_RTId];
            if (!lastPriceListStatement.isEmpty()) {
                for (PriceListStatement__c item : lastPriceListStatement) {
                    Id nsId = item.NegoScope__c;
                    Nego_Plan__c negoPlan = negoPlanMap.get(nsId);
                    if (!negoPlanStatusMap.containskey(negoPlan.Id)) {
                        negoPlanStatusMap.put(negoPlan.Id, new Set<String>());
                    }
                    negoPlanStatusMap.get(negoPlan.Id).add(item.Status__c);
                    if (item.RecordType.DeveloperName == 'IsoPartner' && negoPlan.NEGO_Rise_Rate_IsoPartner__c != item.PriceEvolutionRateCalculated__c) {
                        if (!negoPlanMapToUpdate.containsKey(negoPlan.Id)) {
                            negoPlanMapToUpdate.put(negoPlan.Id, negoPlan);
                        }
                        negoPlanMapToUpdate.get(negoPlan.Id).NEGO_Rise_Rate_IsoPartner__c = item.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        if (item.PriceListStatementReference__r.RecordType.DeveloperName == 'Rise_Rate') {
                            negoPlanMapToUpdate.get(negoPlan.Id).NEGO_Rise_Rate_Requested_Date__c = item.ApplicationDateValidated__c;
                        }
                    }
                    if (item.RecordType.DeveloperName == 'Rise_Rate' && negoPlan.NEGO_PriceEvolutionRateRequested__c != item.PriceEvolutionRateCalculated__c) {
                        if (!negoPlanMapToUpdate.containsKey(negoPlan.Id)) {
                            negoPlanMapToUpdate.put(negoPlan.Id, negoPlan);
                        }
                        negoPlanMapToUpdate.get(negoPlan.Id).NEGO_Rise_Rate_Status__c = item.Status__c;
                        negoPlanMapToUpdate.get(negoPlan.Id).NEGO_PriceEvolutionRateRequested__c = item.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                    }
                    if (item.OnTop__c && item.RecordType.DeveloperName == 'Simulation'
                         && negoPlan.NEGO_Rise_Rate_Negotiated_OnTop__c != item.PriceEvolutionRateCalculated__c)
                    {
                        if (!negoPlanMapToUpdate.containsKey(negoPlan.Id)) {
                            negoPlanMapToUpdate.put(negoPlan.Id, negoPlan);
                        }
                        negoPlanMapToUpdate.get(negoPlan.Id).NEGO_Rise_Rate_Negotiated_OnTop__c = item.PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                    }
                    if (negoPlanStatusMap.get(negoPlan.Id).Contains('Opened')) {
                        negoPlan.NEGO_Rise_Rate_Status__c = 'Opened';
                    }
                    if (negoPlanStatusMap.get(negoPlan.Id).Contains('Validated')) {
                        negoPlan.NEGO_Rise_Rate_Status__c = 'Validated';
                    }
                    if (!negoPlanStatusMap.get(negoPlan.Id).Contains('Validated') && !negoPlanStatusMap.get(negoPlan.Id).Contains('Opened')) {
                        negoPlan.NEGO_Rise_Rate_Status__c = 'Rejected';
                    }
                }
            }
        }
        if(!negoPlanMapToUpdate.isEmpty()) {
            update negoPlanMapToUpdate.values();
        }
    }***/

    public static void calculateVolumeHMP(List<PriceListStatement__c> scope) {
        Set<Id> pgSet = new Set<Id>();
        Set<Id> buSet = new Set<Id>();
        Set<Id> supplierSet = new Set<Id>();
        Set<Id> negoScopeSet = new Set<Id>();
        Set<Id> referenceProductSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> yearP1Set = new Set<Integer>();
        Set<Integer> yearP2Set = new Set<Integer>();
        Set<Integer> yearP3Set = new Set<Integer>();
        Map<Id, Id> refProductMap = new Map<Id, Id>();
        Map<Integer, List<Integer>> manualSellInRulesMap = new Map<Integer, List<Integer>>();
        Map<String, List<Decimal>> calculatedSellinMap = new Map<String, List<Decimal>>();
        String selectedSellInRule = '12M';
        PriceListStatement__c priceListStatement = scope[0];
        List <PriceListStatementDetail__c> priceListStatementDetailList = [SELECT Id, PG__c, PriceListStatement__c,PriceListStatementDetailLastHistory__c,
                                                                                             PriceListStatementDetailLastHistory__r.PG__c,
                                                                                             PriceListStatement__r.Supplier__c, PriceListStatement__r.NegoScope__c,
                                                                                             PriceListStatement__r.BusinessUnitTarget__c, Product__r.Reference_Product__c, ProductReference__c,
                                                                                             /***Additionnal_Product__r.Internal_Product_Reference__c,***/ PriceListStatement__r.ReferenceYear__c
                                                                                             FROM PriceListStatementDetail__c
                                                                                             WHERE PriceListStatement__c = :priceListStatement.Id];
        for (PriceListStatementDetail__c item : priceListStatementDetailList) {
            if (item.PG__c != null && !pgSet.contains(item.PG__c)) {
                pgSet.add(item.PG__c);
            }
            if (item.PriceListStatement__r.Supplier__c != null && !supplierSet.contains(item.PriceListStatement__r.Supplier__c)) {
                supplierSet.add(item.PriceListStatement__r.Supplier__c);
            }
            if (item.PriceListStatement__r.NegoScope__c != null && !negoScopeSet.contains(item.PriceListStatement__r.NegoScope__c)) {
                negoScopeSet.add(item.PriceListStatement__r.NegoScope__c);
            }
            if (item.PriceListStatement__r.BusinessUnitTarget__c != null && !buSet.contains(item.PriceListStatement__r.BusinessUnitTarget__c)) {
                buSet.add(item.PriceListStatement__r.BusinessUnitTarget__c);
            }
            if (item.ProductReference__c != null && !referenceProductSet.contains(item.ProductReference__c)) {
                referenceProductSet.add(item.ProductReference__c);
            }
            /***if (item.Additionnal_Product__r.Internal_Product_Reference__c != null && !referenceProductSet.contains(item.Additionnal_Product__r.Internal_Product_Reference__c)) {
                referenceProductSet.add(item.Additionnal_Product__r.Internal_Product_Reference__c);
            }***/
            yearSet.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c));
            yearP1Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 1);
            yearP2Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 2);
            yearP3Set.add(Integer.valueOf(item.PriceListStatement__r.ReferenceYear__c) - 3);
        }
        Map<String, Id> referencePGMap = new Map<String, Id>();
        Map<Id, Id> productPGMap = new Map<Id, Id>();
        for (Set<Id> buId : NegoptimHelper.getBUChildrenMap(buSet).Values()) {
            buSet.addAll(buId);
        }
        if (!referenceProductSet.isEmpty()) {
            for (NSPG__c item : [SELECT Id, PG__c, NegoScope__c, PG__r.Product__c, PG__r.Product__r.Reference_Product__c
                                                     FROM NSPG__c
                                                     WHERE PG__r.Product__c <> NULL
                                                     AND (PG__r.Product__c IN :referenceProductSet OR  PG__r.Product__r.Reference_Product__c IN :referenceProductSet OR PG__r.Product__c IN :referenceProductSet)
                                                     AND NegoScope__c IN :negoScopeSet])
            {
                if (referenceProductSet.contains(item.PG__r.Product__c)) {
                    pgSet.add(item.PG__c);
                }
                productPGMap.put(item.PG__r.Product__c, item.PG__r.Id);
                if (referenceProductSet.contains(item.PG__r.Product__c)) {
                    pgSet.add(item.PG__c);
                    referencePGMap.put(String.valueOf(item.NegoScope__c) + String.valueOf(item.PG__r.Product__c), item.PG__c);
                }
                if (referenceProductSet.contains(item.PG__r.Product__c)) {
                    pgSet.add(item.PG__c);
                }
                if (item.PG__r.Product__r.Reference_Product__c != null && referenceProductSet.contains(item.PG__r.Product__r.Reference_Product__c)) {
                    refProductMap.put(item.PG__r.Product__r.Reference_Product__c, item.PG__r.Product__c);
                }
            }
        }
        if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && selectedSellInRule != null) {
            Integer referenceYear = priceListStatement.CreatedDate.year();//System.today().year();
            /***calculatedSellinMap = calculateSellinService(pgSet, buSet, supplierSet, referenceYear, yearSet, yearP1Set, yearP2Set, yearP3Set, selectedSellInRule, manualSellInRulesMap, priceListStatement.CreatedDate.date());***/
            for (PriceListStatementDetail__c item : priceListStatementDetailList) {
                String keyDetail = '';
                /***if (item.Additionnal_Product__c != null && item.PriceListStatementDetailLastHistory__c != null && item.PriceListStatementDetailLastHistory__r.PG__c != null) {
                    keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PriceListStatementDetailLastHistory__r.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                } else {
                    if (item.Additionnal_Product__r.Internal_Product_Reference__c != null && productPGMap.containsKey(item.Additionnal_Product__r.Internal_Product_Reference__c)) {
                        keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + productPGMap.get(item.Additionnal_Product__r.Internal_Product_Reference__c) + '' + item.PriceListStatement__r.Supplier__c;
                        //newPriceListStatementDetail.Warning_Type__c = item.EAN_Switch_Proposal__c != null ? 'ForceSellIn' : 'ForceNoSellIn';
                    } else {
                        keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                    }
                }***/
                keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + item.PG__c + '' + item.PriceListStatement__r.Supplier__c;
                if(/*!referenceProductsSet.contains(item.Product__c) &&*/ calculatedSellinMap.containsKey(keyDetail)) {
                    /***item.SellInRegularQty__c = calculatedSellinMap.get(keyDetail)[0] - (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0);
                    item.SellInPromoQty__c = calculatedSellinMap.get(keyDetail)[1];
                    // check existing reference products
                    if (item.Product__r.Reference_Product__c != null) {
                        String keyReferencePG = String.valueOf(item.PriceListStatement__r.NegoScope__c) + String.valueOf(item.Product__r.Reference_Product__c);
                        if (referencePGMap.containsKey(keyReferencePG)) {
                            keyDetail = item.PriceListStatement__r.BusinessUnitTarget__c + '' + referencePGMap.get(keyReferencePG) + '' + item.PriceListStatement__r.Supplier__c;
                            if (calculatedSellinMap.containsKey(keyDetail)) {
                                if (item.SellInRegularQty__c == null) item.SellInRegularQty__c = 0;
                                if (item.SellInPromoQty__c == null) item.SellInPromoQty__c = 0;
                                item.SellInRegularQty__c += (calculatedSellinMap.get(keyDetail)[0] - (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0));
                                item.SellInPromoQty__c += (calculatedSellinMap.get(keyDetail)[1] != null ? calculatedSellinMap.get(keyDetail)[1] : 0);
                            }
                        }
                    }***/
                } else {
                    /***item.SellInRegularQty__c = 0;
                    item.SellInPromoQty__c = 0;***/
                }
            }
            List<Database.SaveResult> results = Database.update(priceListStatementDetailList, false);
        }
    }

    /*
    * calculate sell_in for Promo details or Price_List details
    */
    /***public static Map<String, List<Decimal>> calculateSellinService(Set<Id> pgSet, Set<Id> buSet, Set<Id> supplierSet,
                                                                    Integer referenceYear, Set<Integer> yearSet, Set<Integer> yearP1Set, Set<Integer> yearP2Set, Set<Integer> yearP3Set,
                                                                    String selectedSellInRule, Map<Integer, List<Integer>> manualSellInRulesMap, Date hmpCreatedDate)
    {
        // check security on access Purchases_Flow_PG__c fields
        String[] purchaseFlowPGAccessFields = new String[] {
            SObjectType.Purchases_Flow_PG__c.fields.Id.Name,
                SObjectType.Purchases_Flow_PG__c.fields.BU__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.PG__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Supplier__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Year__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.YTD_QTY__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.YTD_SellIn_Qty_Promo__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.YE_SellIn_Qty__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty1__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty2__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty3__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty4__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty5__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty6__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty7__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty8__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty9__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty10__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty11__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.Qty12__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M1__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M2__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M3__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M4__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M5__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M6__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M7__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M8__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M9__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M10__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M11__c.Name,
                SObjectType.Purchases_Flow_PG__c.fields.SellIn_Qty_Promo_M12__c.Name
                };
                    Map<String, List<Decimal>> calculatedSellinMap = new Map<String, List<Decimal>>();
        if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && selectedSellInRule != null && (selectedSellInRule == '12M' || selectedSellInRule == 'Manual')) {
            Integer beginMonth, endMonth, beginYear, endYear, P2, P1, N;
            P2 = referenceYear - 2;
            P1 = referenceYear - 1;
            N = referenceYear;
            if (selectedSellInRule == '12M') {
                //Date previous12MDate = System.today().addMonths(-12), previousMonthDate = System.today().addMonths(-1);
                Date previous12MDate = hmpCreatedDate.addMonths(-12), previousMonthDate = hmpCreatedDate.addMonths(-1);
                beginMonth = previous12MDate.month();
                beginYear = previous12MDate.year();
                endMonth = previousMonthDate.month();
                endYear = previousMonthDate.year();
            }
            Map<String, Map<Integer, Map<String, Decimal>>> totalsMap = new Map<String, Map<Integer, Map<String, Decimal>>>();
            String aggregateQuery = 'SELECT BU__c BU__c, PG__c PG__c, Supplier__c Supplier__c,';
            aggregateQuery += ' SUM(Qty1__c) Qty1__c, SUM(Qty2__c) Qty2__c, SUM(Qty3__c) Qty3__c,';
            aggregateQuery += ' SUM(Qty4__c) Qty4__c, SUM(Qty5__c) Qty5__c,SUM(Qty6__c) Qty6__c,';
            aggregateQuery += ' SUM(Qty7__c) Qty7__c, SUM(Qty8__c) Qty8__c, SUM(Qty9__c) Qty9__c, SUM(Qty10__c) Qty10__c, SUM(Qty11__c) Qty11__c, SUM(Qty12__c) Qty12__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M1__c) SellIn_Qty_Promo_M1__c, SUM(SellIn_Qty_Promo_M2__c) SellIn_Qty_Promo_M2__c, SUM(SellIn_Qty_Promo_M3__c) SellIn_Qty_Promo_M3__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M4__c) SellIn_Qty_Promo_M4__c, SUM(SellIn_Qty_Promo_M5__c) SellIn_Qty_Promo_M5__c, SUM(SellIn_Qty_Promo_M6__c) SellIn_Qty_Promo_M6__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M7__c) SellIn_Qty_Promo_M7__c, SUM(SellIn_Qty_Promo_M8__c) SellIn_Qty_Promo_M8__c, SUM(SellIn_Qty_Promo_M9__c) SellIn_Qty_Promo_M9__c,';
            aggregateQuery += ' SUM(SellIn_Qty_Promo_M10__c) SellIn_Qty_Promo_M10__c, SUM(SellIn_Qty_Promo_M11__c) SellIn_Qty_Promo_M11__c, SUM(SellIn_Qty_Promo_M12__c) SellIn_Qty_Promo_M12__c';
            aggregateQuery += ' FROM Purchases_Flow_PG__c';
            aggregateQuery += ' WHERE BU__r.Status__c = \'Open\'';
            aggregateQuery += ' AND PG__c IN (\'' + String.join(new List<Id>(pgSet), '\', \'') + '\')';
            aggregateQuery += ' AND BU__c IN (\'' + String.join(new List<Id>(buSet), '\', \'') + '\')';
            aggregateQuery += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\', \'') + '\')';
            if (NegoptimHelper.checkAccessibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGAccessFields)) {
                String aggregateQueryP2 = aggregateQuery + ' AND Year__c = ' + P2 + ' GROUP BY BU__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryP2)) {
                    fillPurchasesTotals(totalsMap, P2, item);
                }
                String aggregateQueryP1 = aggregateQuery + ' AND Year__c = ' + P1 + ' GROUP BY BU__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryP1)) {
                    fillPurchasesTotals(totalsMap, P1, item);
                }
                String aggregateQueryN = aggregateQuery + ' AND Year__c = ' + N + ' GROUP BY BU__c, PG__c, Supplier__c';
                for (AggregateResult item : Database.query(aggregateQueryN)) {
                    fillPurchasesTotals(totalsMap, N, item);
                }
            }
            Boolean isExistMonthP2 = false, isExistMonthP1 = false, isExistMonthN = false;
            List<Integer> monthsP2, monthsP1, monthsN;
            if (selectedSellInRule == 'Manual' && !manualSellInRulesMap.isEmpty()) {
                monthsP2 = manualSellInRulesMap.get(P2);
                monthsP1 = manualSellInRulesMap.get(P1);
                monthsN = manualSellInRulesMap.get(N);
                if (monthsP2 != null && !monthsP2.isEmpty()) {
                    isExistMonthP2 = true;
                }
                if (monthsP1 != null && !monthsP1.isEmpty()) {
                    isExistMonthP1 = true;
                }
                if (monthsN != null && !monthsN.isEmpty()) {
                    isExistMonthN = true;
                }
            }
            for (String key : totalsMap.keySet()) {
                Map<Integer, Map<String, Decimal>> totalsYearMap = totalsMap.get(key);
                Decimal calculatedSellin = 0, calculateSellinPromo = 0;
                if (selectedSellInRule == '12M') {
                    if (totalsYearMap.containsKey(beginYear)) {
                        for (Integer i = beginMonth; i <= 12; i++) {
                            calculatedSellin += totalsYearMap.get(beginYear).containsKey('Qty' + i +'__c') ? totalsYearMap.get(beginYear).get('Qty' + i +'__c') : 0;
                            calculateSellinPromo += totalsYearMap.get(beginYear).containsKey('SellIn_Qty_Promo_M' + i +'__c') ? totalsYearMap.get(beginYear).get('SellIn_Qty_Promo_M' + i +'__c') : 0;
                        }
                    }
                    if (totalsYearMap.containsKey(endYear) && beginYear != endYear) {
                        for (Integer i = 1; i <= endMonth; i++) {
                            calculatedSellin += totalsYearMap.get(endYear).containsKey('Qty' + i +'__c') ? totalsYearMap.get(endYear).get('Qty' + i +'__c') : 0;
                            calculateSellinPromo += totalsYearMap.get(endYear).containsKey('SellIn_Qty_Promo_M' + i +'__c') ? totalsYearMap.get(endYear).get('SellIn_Qty_Promo_M' + i +'__c') : 0;
                        }
                    }
                } else if (selectedSellInRule == 'Manual') {
                    if (isExistMonthP2) {
                        if (totalsYearMap.containsKey(P2)) {
                            for (Integer monthP2 : monthsP2) {
                                calculatedSellin += totalsYearMap.get(P2).containsKey('Qty' + monthP2 +'__c') ? totalsYearMap.get(P2).get('Qty' + monthP2 +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(P2).containsKey('SellIn_Qty_Promo_M' + monthP2 +'__c') ? totalsYearMap.get(P2).get('SellIn_Qty_Promo_M' + monthP2 +'__c') : 0;
                            }
                        }
                    }
                    if (isExistMonthP1) {
                        if (totalsYearMap.containsKey(P1)) {
                            for (Integer monthP1 : monthsP1) {
                                calculatedSellin += totalsYearMap.get(P1).containsKey('Qty' + monthP1 +'__c') ? totalsYearMap.get(P1).get('Qty' + monthP1 +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(P1).containsKey('SellIn_Qty_Promo_M' + monthP1 +'__c') ? totalsYearMap.get(P1).get('SellIn_Qty_Promo_M' + monthP1 +'__c') : 0;
                            }
                        }
                    }
                    if (isExistMonthN) {
                        if (totalsYearMap.containsKey(N)) {
                            for (Integer monthN : monthsN) {
                                calculatedSellin += totalsYearMap.get(N).containsKey('Qty' + monthN +'__c') ? totalsYearMap.get(N).get('Qty' + monthN +'__c') : 0;
                                calculateSellinPromo += totalsYearMap.get(N).containsKey('SellIn_Qty_Promo_M' + monthN +'__c') ? totalsYearMap.get(N).get('SellIn_Qty_Promo_M' + monthN +'__c') : 0;
                            }
                        }
                    }
                }
                calculatedSellinMap.put(key, new List<Decimal>{calculatedSellin, calculateSellinPromo});
            }
        } else if (!pgSet.isEmpty() && !buSet.isEmpty() && !supplierSet.isEmpty() && selectedSellInRule != null) {
            String query = 'SELECT Id, Year__c, BU__c, PG__c, Supplier__c, YTD_QTY__c, YTD_SellIn_Qty_Promo__c, YE_SellIn_Qty__c';
            query += ' FROM Purchases_Flow_PG__c';
            query += ' WHERE BU__r.Status__c = \'Open\'';
            query += ' AND PG__c IN (\'' + String.join(new List<Id>(pgSet), '\', \'') + '\')';
            query += ' AND BU__c IN (\'' + String.join(new List<Id>(buSet), '\', \'') + '\')';
            query += ' AND Supplier__c IN (\'' + String.join(new List<Id>(supplierSet), '\', \'') + '\')';
            if (selectedSellInRule == 'YTD') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP1Set), ',') +')';
            } else if (selectedSellInRule == 'YE') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP1Set), ',') +')';
            } else if (selectedSellInRule == 'YE P1') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP2Set), ',') +')';
            } else if (selectedSellInRule == 'YE P2') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearP3Set), ',') +')';
            } else if (selectedSellInRule == 'YE N1') {
                query += ' AND Year__c IN (' + String.join(new List<Integer>(yearSet), ',') +')';
            }
            if (NegoptimHelper.checkAccessibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGAccessFields)) {
                for (Purchases_Flow_PG__c item : Database.query(query)) {
                    String key = item.BU__c + '' + item.PG__c + '' + item.Supplier__c;
                    if (selectedSellInRule == 'YTD') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YE_SellIn_Qty__c, null});
                    } else if (selectedSellInRule == 'YE P1') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE P2') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YTD_QTY__c, item.YTD_SellIn_Qty_Promo__c});
                    } else if (selectedSellInRule == 'YE N1') {
                        calculatedSellinMap.put(key, new List<Decimal>{item.YE_SellIn_Qty__c, null});
                    }
                }
            }
        }
        return calculatedSellinMap;
    }***/

    /**
    * calculate totals
    */
    /***private static void fillPurchasesTotals(Map<String, Map<Integer, Map<String, Decimal>>> totalsMap, Integer year, AggregateResult item) {
        String key = (Id) item.get('BU__c') + '' + (Id) item.get('PG__c') + '' + (Id) item.get('Supplier__c');
        if (!totalsMap.containsKey(key)) {
            totalsMap.put(key, new Map<Integer, Map<String, Decimal>>());
        }
        if (!totalsMap.get(key).containsKey(year)) {
            totalsMap.get(key).put(year, new Map<String, Decimal>());
        }
        totalsMap.get(key).get(year).put('Qty1__c', item.get('Qty1__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty1__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty2__c', item.get('Qty2__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty2__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty3__c', item.get('Qty3__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty3__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty4__c', item.get('Qty4__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty4__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty5__c', item.get('Qty5__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty5__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty6__c', item.get('Qty6__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty6__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty7__c', item.get('Qty7__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty7__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty8__c', item.get('Qty8__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty8__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty9__c', item.get('Qty9__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty9__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty10__c', item.get('Qty10__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty10__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty11__c', item.get('Qty11__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty11__c'))) : 0);
        totalsMap.get(key).get(year).put('Qty12__c', item.get('Qty12__c') != null ? Decimal.valueOf(String.valueOf(item.get('Qty12__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M1__c', item.get('SellIn_Qty_Promo_M1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M1__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M2__c', item.get('SellIn_Qty_Promo_M2__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M2__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M3__c', item.get('SellIn_Qty_Promo_M3__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M3__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M4__c', item.get('SellIn_Qty_Promo_M4__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M4__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M5__c', item.get('SellIn_Qty_Promo_M5__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M5__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M6__c', item.get('SellIn_Qty_Promo_M6__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M6__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M7__c', item.get('SellIn_Qty_Promo_M7__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M7__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M8__c', item.get('SellIn_Qty_Promo_M8__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M8__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M9__c', item.get('SellIn_Qty_Promo_M9__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M9__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M10__c', item.get('SellIn_Qty_Promo_M10__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M10__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M11__c', item.get('SellIn_Qty_Promo_M11__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M11__c'))) : 0);
        totalsMap.get(key).get(year).put('SellIn_Qty_Promo_M12__c', item.get('SellIn_Qty_Promo_M12__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Qty_Promo_M12__c'))) : 0);
    }***/
}