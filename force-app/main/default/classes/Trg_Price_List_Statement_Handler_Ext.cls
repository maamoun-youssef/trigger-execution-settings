/**
    * @author ULiT
    * @date 01 July 2021
    */
    public class Trg_Price_List_Statement_Handler_Ext {
    
        public static final Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
        
        /*
    * @description called in Trg_Price_List_Statement in case Trigger.isAfter && Trigger.isUpdate
    */
        public static void onAfterUpdate(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            synchroToSupplierPG(newPriceListStatements, oldPriceListStatementsMap);
            /***synchroToNegoPlans(newPriceListStatements, oldPriceListStatementsMap);***/
            /***executeProductCompetitorToProduct2Batch(newPriceListStatements, oldPriceListStatementsMap);***/
            /***syncHMPToContractAndNegoplan(newPriceListStatements, oldPriceListStatementsMap);***/
            /***updateHMPReported(newPriceListStatements, oldPriceListStatementsMap);***/
            recalculateIsoParterVolume(newPriceListStatements, oldPriceListStatementsMap);
        }
        
        public static void onBeforeUpdate(List<PriceListStatement__c> newPriceListStatement, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            populateHMPFields(newPriceListStatement, oldPriceListStatementsMap);
        }
        public static void onBeforeInsert(List<PriceListStatement__c> newPriceListStatements) {
            /***createNegoPlan(newPriceListStatements);***/
            /***setTMPreferenceYear(newPriceListStatements);***/
            updateTariffNumber(newPriceListStatements);
            /***updateHMPReported(newPriceListStatements, null);***/
        }
        
        private static void recalculateIsoParterVolume(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            List<PriceListStatement__c> hmps = new List<PriceListStatement__c>();
            for (PriceListStatement__c item : newPriceListStatements) {
                if (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && item.Status__c == 'Opened' && item.ReferenceYear__c > 2024 
                    && (item.PriceEvolutionRateCalculated__c != oldPriceListStatementsMap.get(item.Id).PriceEvolutionRateCalculated__c || item.PriceEvolutionRateCalculated__c != oldPriceListStatementsMap.get(item.Id).PriceEvolutionRateCalculated__c))
                {
                    hmps.add(item);
                }
                
                if (!hmps.isempty()) {
                    PriceListStatementService.calculateVolumeHMP(hmps);     
                }
            }
        }
        /**
        * Synchronize PriceListStatement__c to PG__c upon validation
        **/
        private static void synchroToSupplierPG(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            Set<Id> priceListStatementIds = new Set<Id>();
            Map<Id, PriceListStatement__c> priceListStmtMap = new Map<Id, PriceListStatement__c>(newPriceListStatements);
            Map<Id, PriceListStatement__c> priceListStmtRefMap = new Map<Id,PriceListStatement__c>();
            priceListStmtRefMap = new Map<Id,PriceListStatement__c>([SELECT PriceListStatementReference__r.RecordTypeId, PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId
                                                                                      FROM PriceListStatement__c
                                                                                      WHERE Id IN : priceListStmtMap.keySet()]);
            
            
            if (!priceListStmtRefMap.isEmpty()) {
                // Check records moved to VALIDATED
                for (PriceListStatement__c item : newPriceListStatements) {
                    
                    Id refRecordType = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.RecordTypeId;
                    Id refRef_RecordTypeId = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordTypeId;
                    if ( // Validate from PriceList = Rise_Rate/Tariff
                        (((item.RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff')))
                          || (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && (refRecordType == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && refRecordType == priceListStatementRTIds.get('Tariff'))))
                          || (item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (refRef_RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && refRef_RecordTypeId == priceListStatementRTIds.get('Tariff')))))
                         && (item.Status__c == 'Request For Approval' || item.Status__c == 'Validated') && item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c)
                        // Validate from PriceList = DepreciationRate
                        || ((item.RecordTypeId == priceListStatementRTIds.get('DepreciationRate')
                             || (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && refRecordType == priceListStatementRTIds.get('DepreciationRate'))
                             || (item.RecordTypeId == priceListStatementRTIds.get('Simulation') && refRef_RecordTypeId == priceListStatementRTIds.get('DepreciationRate')))
                            && (item.Status__c == 'Validated' && item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c)))
                    {
                        priceListStatementIds.add(item.Id);
                    }
                }
            }
            if (!System.isBatch() && !priceListStatementIds.isEmpty()) {
                // call PriceListStatementToPGSynchroBatch for update PGs
                // NegoptimBatch.executeBatch(new PriceListStatementToPGSynchroBatch('Trg_Price_List_Statement_Handler', priceListStatementIds, null, true), 200);
                Map<String, Object> paramsMap = new Map<String, Object>{
                    'startedFrom' => 'Trg_Price_List_Statement_Handler',
                    'priceListStatementIds' => priceListStatementIds,
                    'priceListStatementDetailIds' => null,
                    'executInitPriceListStatementBatch' => true
                };
                NegoptimBatch.executeBatch('PriceListStatementToPGSynchroBatch', paramsMap, 200);
            }
        }
        /***private static void createNegoPlan(List<PriceListStatement__c> newPriceListStatements) {
            Set<Id> nsIdSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Set<String> exitingNsYearSet = new Set<String>();
            List<Nego_Plan__c> insertedNP = new List<Nego_Plan__c>();
            
            Map<String, PriceListStatement__c> nsMap = new Map<String, PriceListStatement__c>();
            for (PriceListStatement__c item : newPriceListStatements) {
                nsIdSet.add(item.NegoScope__c);
                yearSet.add(item.ReferenceYear__c.intValue());
                //newNsyearSet.add(item.NegoScope__c + '-' + item.ReferenceYear__c.intValue());
            }
            // GET NS without negoPlan
            for (Nego_Plan__c item : [SELECT Id, NegoScope__c, Nego_Year__c
                                                     FROM Nego_Plan__c 
                                                     WHERE NegoScope__c IN :nsIdSet 
                                                     AND Nego_Year__c = :yearSet]) 
            {
                exitingNsYearSet.add(item.NegoScope__c + '-' + item.Nego_Year__c.intValue());
            }
                
            for (PriceListStatement__c item : newPriceListStatements) {
                if (!exitingNsYearSet.contains(item.NegoScope__c + '-' + item.ReferenceYear__c.intValue())) {
                    insertedNP.add(new Nego_Plan__c(NegoScope__c = item.NegoScope__c, Nego_Year__c = item.ReferenceYear__c));
                }
            }
            if (!insertedNP.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(insertedNP, false);  
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = ''; 
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) 
                            errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        system.debug('>>>> errorMessage : ' + errorMessage);
                    }
                }
            }
        }***/
        
        /***private static void setTMPreferenceYear(List<PriceListStatement__c> newPriceListStatements) {
            for (PriceListStatement__c item : newPriceListStatements) {
                if (item.ReferenceYear__c != null) {
                    item.SPITM_HMP_ReferenceYear__c = String.valueOf(Integer.valueOf(String.valueOf(item.ReferenceYear__c )));
                }
            }
        }***/
        
        private static void updateTariffNumber(List<PriceListStatement__c> newPriceListStatements) {
            Map<String, Integer> nsRiseRateCountMap = new Map<String, Integer>();
            Set<Id> nsIdSet = new Set<Id>();
            Set<Id> buIdSet = new Set<Id>();
            Set<Decimal> yearSet = new Set<Decimal>();
            for (PriceListStatement__c item : newPriceListStatements) {
                if (item.RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff'))) {
                    String Key = item.NegoScope__c + '' + item.BusinessUnitTarget__c + '' + item.ReferenceYear__c.intValue();
                    nsRiseRateCountMap.put(Key, 0);
                    nsIdSet.add(item.NegoScope__c);
                    buIdSet.add(item.BusinessUnitTarget__c);
                    yearSet.add(item.ReferenceYear__c);
                }
            }
            for (AggregateResult result : [SELECT NegoScope__c NegoScope__c, BusinessUnitTarget__c BusinessUnitTarget__c,
                                           /***SPITM_HMP_ReferenceYear__c SPITM_HMP_ReferenceYear__c,***/ MAX(Version__c) tariffNumber
                                           FROM PriceListStatement__c
                                           WHERE /*RecordType.DeveloperName = 'RiseRate' AND*/
                                           NegoScope__c IN :nsIdSet AND
                                           BusinessUnitTarget__c IN :buIdSet AND
                                           /***SPITM_PriceList_Statement_Type__c = 'RiseRate' AND***/
                                           ReferenceYear__c IN :yearSet
                                           GROUP BY NegoScope__c, BusinessUnitTarget__c/***, SPITM_HMP_ReferenceYear__c***/])
            {
                String Key = result.get('NegoScope__c') + '' + result.get('BusinessUnitTarget__c') + '' + result.get('SPITM_HMP_ReferenceYear__c');
                nsRiseRateCountMap.put(key,  (result.get('NegoScope__c') == null ? 0 : Integer.valueOf(result.get('tariffNumber'))));
            }
            for (PriceListStatement__c item : newPriceListStatements) {
                if (item.RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff'))) {
                    String Key = item.NegoScope__c + '' + item.BusinessUnitTarget__c + '' + item.ReferenceYear__c.intValue();
                    Integer nsRiseRateCount = nsRiseRateCountMap.containskey(key) && nsRiseRateCountMap.get(key) != null ? nsRiseRateCountMap.get(key) : 0;
                    // item.Name += '-' + (nsRiseRateCount + 1);
                    item.Version__c = (nsRiseRateCount + 1);
                }
            }
        }
        
        /**
        * @description ON AFTER UPDATE
        * synchro PriceListStatement__c to Nego_Plan__c
        */
        /***private static void synchroToNegoPlans(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            Set<Id> negoScopeSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            Map<Id, PriceListStatement__c> priceListStmtMap = new Map<Id, PriceListStatement__c>(newPriceListStatements);
            Map<String, List<PriceListStatement__c>> priceListStatementForNegoPlanMap = new Map<String, List<PriceListStatement__c>>();
            Set<Id> changedToRiseRateIds = new Set<Id>();
            for (PriceListStatement__c item : newPriceListStatements) {
                if ((item.RecordTypeId == priceListStatementRTIds.get('RiseRate')
                     && (item.Status__c == 'Validated' || item.Status__c == 'Rejected')
                     && (oldPriceListStatementsMap != null && oldPriceListStatementsMap.get(item.Id).RecordTypeId != item.RecordTypeId
                         && priceListStatementRTIds.containsKey('SPITM_Rise_Rate_Tentative') && oldPriceListStatementsMap.get(item.Id).RecordTypeId == priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative'))))
                {
                    changedToRiseRateIds.add(item.Id);
                    negoScopeSet.add(item.NegoScope__c);
                    yearSet.add(Integer.valueOf(item.ReferenceYear__c));
                    String key = String.valueOf(item.NegoScope__c) + String.valueOf(Integer.valueof(item.ReferenceYear__c));
                    if (!priceListStatementForNegoPlanMap.containsKey(key)) {
                        priceListStatementForNegoPlanMap.put(key, new List<PriceListStatement__c>());
                    }
                    priceListStatementForNegoPlanMap.get(key).add(item);
                }
            }
            updateNegoPlan(priceListStatementForNegoPlanMap, negoScopeSet, yearSet, changedToRiseRateIds);
        }***/
        
        /***private static void updateNegoPlan(Map<String, List<PriceListStatement__c>> priceListStatementForNegoPlanMap, Set<Id> negoScopeSet, Set<Integer> yearSet, Set<Id> changedToRiseRateIds) {
            // update Nego_Plan__c
            if(!negoScopeSet.isEmpty() && !yearSet.isEmpty()) {
                Map<String, Nego_Plan__c> updatedNegoPlanMap = new Map<String, Nego_Plan__c>();
                Map<String, Nego_Plan__c> negoPlanMap = new Map<String, Nego_Plan__c>();
                List<PriceListStatement__c> childPriceList = new List<PriceListStatement__c>();
                Map<Id,PriceListStatement__c> childISOPartnerMap = new Map<Id,PriceListStatement__c>();
                Map<Id,PriceListStatement__c> childSimulationMap = new Map<Id,PriceListStatement__c>();
                childPriceList = [SELECT Id, PriceEvolutionRateCalculated__c, RecordTypeId, RecordType.DeveloperName, PriceListStatementReference__c, PriceListStatementReference__r.PriceListStatementReference__c
                                  FROM PriceListStatement__c
                                  WHERE (PriceListStatementReference__c IN :changedToRiseRateIds AND RecordTypeId = :priceListStatementRTIds.get('IsoPartner'))
                                  OR (PriceListStatementReference__r.PriceListStatementReference__c IN :changedToRiseRateIds
                                      AND RecordTypeId = :priceListStatementRTIds.get('Simulation')
                                      AND OnTop__c = TRUE)];
                for (PriceListStatement__c pls : childPriceList) {
                    if (pls.recordType.DeveloperName == 'IsoPartner') {
                        childISOPartnerMap.put(pls.PriceListStatementReference__c, pls);
                    }
                    if (pls.recordType.DeveloperName == 'Simulation') {
                        childSimulationMap.put(pls.PriceListStatementReference__r.PriceListStatementReference__c, pls);
                    }
                }
                // check security on access Nego_Plan__c
                String[] negoPlanFields = new String[] {
                    SObjectType.Nego_Plan__c.fields.Id.Name,
                    SObjectType.Nego_Plan__c.fields.NegoScope__c.Name,
                    SObjectType.Nego_Plan__c.fields.Nego_Year__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Validated_Nb__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Validated_YE__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateValidated__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate1_Validated__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate2_Validated__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate3_Validated__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date__c.Name,
                    SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date1__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date2__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date3__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateRequested__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateValidated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Status__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Date__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_IsoPartner__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Negotiated_OnTop__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Requested_Date__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Validated_YE__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateValidated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate1_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate2_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate3_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate4_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate5_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate6_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate7_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate8_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate9_Validated__c.Name,
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate10_Validated__c.Name
                        };
                if (NegoptimHelper.checkAccessibility(Nego_Plan__c.SObjectType, negoPlanFields)) {
                    for (Nego_Plan__c item : [SELECT Id, NegoScope__c, Nego_Year__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Depreciation_Rate_Date__c,
                                                             NEGO_Depreciation_Rate_Validated_Nb__c, NEGO_Depreciation_Rate1_Validated__c, NEGO_Depreciation_Rate_Validated_YE__c,
                                                             NEGO_Depreciation_Rate2_Validated__c, NEGO_Depreciation_Rate3_Validated__c, NEGO_Depreciation_Rate_Date1__c, NEGO_Depreciation_Rate_Date2__c,
                                                             NEGO_Depreciation_Rate_Date3__c, NEGO_PriceEvolutionRateRequested__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Rise_Rate_Status__c, NEGO_Rise_Rate_Date__c,
                                                             NEGO_Rise_Rate_Negotiated_OnTop__c, NEGO_Rise_Rate_IsoPartner__c, NEGO_Rise_Rate_Requested_Date__c, NEGO_Rise_Rate_Validated_YE__c,
                                                             NEGO_Rise_Rate1_Validated__c, NEGO_Rise_Rate2_Validated__c, NEGO_Rise_Rate3_Validated__c, NEGO_Rise_Rate4_Validated__c,
                                                             NEGO_Rise_Rate5_Validated__c, NEGO_Rise_Rate6_Validated__c, NEGO_Rise_Rate7_Validated__c, NEGO_Rise_Rate8_Validated__c,
                                                             NEGO_Rise_Rate9_Validated__c, NEGO_Rise_Rate10_Validated__c, NEGO_Rise_Rate_Validated_Nb__c
                                                             FROM Nego_Plan__c
                                                             WHERE NegoScope__c IN :negoScopeSet
                                                             AND Nego_Year__c IN :yearSet])
                    {
                        negoPlanMap.put(String.valueOf(item.NegoScope__c) + String.valueOf(Integer.valueof(item.Nego_Year__c)), item);
                    }
                }
                if (!negoPlanMap.isEmpty()) {
                    for (String key : negoPlanMap.keySet()) {
                        Nego_Plan__c negoPlan = negoPlanMap.get(key);
                        if (priceListStatementForNegoPlanMap.containsKey(key)) {
                            for (PriceListStatement__c priceListStatement : priceListStatementForNegoPlanMap.get(key)) {
                                if (priceListStatement.Id != null && !changedToRiseRateIds.isEmpty() && changedToRiseRateIds.contains(priceListStatement.Id)) {
                                    negoPlan.NEGO_PriceEvolutionRateRequested__c = priceListStatement.PriceEvolutionRateCalculated__c;
                                    negoPlan.NEGO_Rise_Rate_Requested_Date__c = priceListStatement.ApplicationDateRequested__c;
                                    if (childISOPartnerMap.containsKey(priceListStatement.Id)) {
                                        negoPlan.NEGO_Rise_Rate_IsoPartner__c = childISOPartnerMap.get(priceListStatement.Id).PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.scale, System.RoundingMode.HALF_UP);
                                    }
                                    if (childSimulationMap.containsKey(priceListStatement.Id)) {
                                        negoPlan.NEGO_Rise_Rate_Negotiated_OnTop__c = childSimulationMap.get(priceListStatement.Id).PriceEvolutionRateCalculated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.scale, System.RoundingMode.HALF_UP);
                                    }
                                }
                                Integer riseRateCount = 10;
                                String fieldName;
                                //Integer riseRateNb = (negoPlan.NEGO_Rise_Rate_Validated_Nb__c != null ? Integer.valueOf(negoPlan.NEGO_Rise_Rate_Validated_Nb__c) : 0) + 1;
                                Integer riseRateNb = priceListStatement.Version__c != null ? (priceListStatement.Version__c > 10 ? 10 : Integer.valueOf(priceListStatement.Version__c)) : 1;
                                if (riseRateNb <= riseRateCount) {
                                    fieldName = 'NEGO_Rise_Rate' + riseRateNb + '_Validated__c';
                                    negoPlan.put(fieldName, priceListStatement.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP));
                                    fieldName = 'NEGO_Rise_Rate_Date' + riseRateNb + '__c';
                                    negoPlan.put(fieldName, priceListStatement.ApplicationDateRequested__c);
                                    negoPlan.NEGO_PriceEvolutionRateValidated__c = priceListStatement.PriceEvolutionRateValidated__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                                    negoPlan.NEGO_Rise_Rate_Date__c = priceListStatement.ApplicationDateRequested__c;
                                    negoPlan.NEGO_Rise_Rate_Status__c = 'Validated';
                                }
                                updatedNegoPlanMap.put(key, negoPlan);
                            }
                        }
                    }
                }
                if(!updatedNegoPlanMap.isEmpty()) {
                    // check security on update Nego_Plan__c
                    String[] negoPlanUpdatedFields = new String[] {
                        SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Negotiated_OnTop__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateRequested__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Status__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Date__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_IsoPartner__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Requested_Date__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateValidated__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Date__c.Name,
                            SObjectType.Nego_Plan__c.fields.NEGO_PriceEvolutionRateValidated__c.Name
                            };
                    if (NegoptimHelper.checkUpdatibility(Nego_Plan__c.SObjectType, negoPlanUpdatedFields)) {
                        update updatedNegoPlanMap.values();
                    }
                }
            }
        }***/
        
        /***private static void executeProductCompetitorToProduct2Batch(List<PriceListStatement__c> newPriceListStatement, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            Set<Id> validatedPriceListStatementIdSet = new Set<Id>();
            Set<Id> dddHmpIds = new Set<Id>();
            Set<Id> internalSwitchedProduict = new Set<Id>();
            List<Product2> productToUpdate = new List<Product2>();
            // loop over newPriceListStatements
            for (PriceListStatement__c item : newPriceListStatement) {
                if ((oldPriceListStatementsMap.containsKey(item.Id) &&
                     item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c &&
                     item.Status__c =='Validated'))
                {
                    validatedPriceListStatementIdSet.add(item.Id);
                    if (item.SPITM_Is_DDD__c) {
                        dddHmpIds.add(item.Id);
                    }
                }
            }
            // update product2 and product compatitiro vat
            Map<Id, PriceListStatementDetail__c> productPlsdMap = new Map<Id, PriceListStatementDetail__c>();
            Map<Id, PriceListStatementDetail__c> aditionalPlsdMap = new Map<Id, PriceListStatementDetail__c>();
            for (PriceListStatementDetail__c detail : [SELECT Id, Product__c, Additionnal_Product__c,
                                                                         SPITM_VAT_rate_DDD__c, SPITM_VAT_Rate_Correction__c,PriceListStatement__c,
                                                                         Product__r.Reference_Product__c,
                                                                         SPITM_Element_nb_DDD__c, SPITM_Element_nb_Correction__c,
                                                                         SPITM_Retail_Price_Reco_DDD__c, SPITM_Retail_Price_Reco_Correction__c
                                                                         FROM PriceListStatementDetail__c
                                                                         WHERE PriceListStatement__c IN :validatedPriceListStatementIdSet OR (
                                                                         PriceListStatement__c IN :dddHmpIds
                                                                         AND (Additionnal_Product__c != null OR (Product__c != null)))])
            {
                if (dddHmpIds.contains(detail.PriceListStatement__c) && (
                    detail.SPITM_VAT_rate_DDD__c  != detail.SPITM_VAT_Rate_Correction__c ||
                    detail.SPITM_Element_nb_DDD__c  != detail.SPITM_Element_nb_Correction__c ||
                    detail.SPITM_Retail_Price_Reco_DDD__c  != detail.SPITM_Retail_Price_Reco_Correction__c))
                {
                    if (detail.Product__c != null ) {
                        productPlsdMap.put(detail.Product__c , detail);
                    } else {
                        aditionalPlsdMap.put(detail.Additionnal_Product__c, detail);
                    }
                }
            }
            if (!productPlsdMap.isempty()) {
                List<Product2> updatedProduct = new List<Product2>();
                for (Product2 prd : [SELECT Id, VAT_Rate__c
                                     FROM Product2
                                     WHERE Id  IN :productPlsdMap.keyset()])
                {
                    Boolean isChanged = false;
                    if (productPlsdMap.get(prd.Id).SPITM_VAT_Rate_Correction__c != null) {
                        prd.VAT_Rate__c = productPlsdMap.get(prd.Id).SPITM_VAT_Rate_Correction__c;
                        isChanged = true;
                    }
                    if (productPlsdMap.get(prd.Id).SPITM_Retail_Price_Reco_Correction__c != null) {
                        prd.Retail_Price_Reco__c = productPlsdMap.get(prd.Id).SPITM_Retail_Price_Reco_Correction__c;
                        isChanged = true;
                    }
                    if (productPlsdMap.get(prd.Id).SPITM_Element_nb_Correction__c != null) {
                        prd.Element_nb__c = productPlsdMap.get(prd.Id).SPITM_Element_nb_Correction__c;
                        isChanged = true;
                    }
                    if (isChanged){
                        updatedProduct.add(prd);
                    }
                }
                update updatedProduct;
            }
            if (!aditionalPlsdMap.isempty()) {
                List<Product_Competitor__c  > updatedProductComp = new List<Product_Competitor__c  >();
                for (Product_Competitor__c prd : [SELECT Id, TMP_VAT_rate__c
                                                                 FROM Product_Competitor__c
                                                                 WHERE Id  IN :aditionalPlsdMap.keyset()])
                {
                    if (aditionalPlsdMap.get(prd.Id).SPITM_VAT_Rate_Correction__c != null) {
                        prd.TMP_VAT_rate__c = aditionalPlsdMap.get(prd.Id).SPITM_VAT_Rate_Correction__c;
                        updatedProductComp.add(prd);
                    }
                }
                update updatedProductComp;
            }
            system.debug('>>>>>> validatedPriceListStatementIdSet : ' + validatedPriceListStatementIdSet);
            if(!system.isbatch() && validatedPriceListStatementIdSet != null && !validatedPriceListStatementIdSet.isEmpty()) {
                NegoptimBatch.executeBatch(new ProductCompetitorToProduct2Batch('Trg_ULiT_Price_List_Statement_Handler', validatedPriceListStatementIdSet), 200);
            }
        }***/
    
        public static void populateHMPFields(List<PriceListStatement__c> newPriceListStatement, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            /***Set<String> years = new Set<String>();
            Set<Id> nsIds = new Set<Id>();
            Set<String> yearsForNaming = new Set<String>();
            Set<Id> nsIdsForNaming = new Set<Id>();
            Set<Id> tariffHmpIds = new Set<Id>();
            Map<Id, Decimal> hmpTariffVersionMap = new Map<Id, Decimal>();
            Map<String, PriceListStatement__c> insertedHMPMap = new Map<String, PriceListStatement__c>();
            for (PriceListStatement__c item : newPriceListStatement) {
                if (item.Id != null && oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id)
                    && oldPriceListStatementsMap.get(item.Id).SPITM_IsCorrectedRateValidated__c != item.SPITM_IsCorrectedRateValidated__c && item.SPITM_IsCorrectedRateValidated__c)
                {
                    if (item.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                        item.PriceEvolutionRateValidated__c = item.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        item.SPITM_Rate_Has_Been_Corrected__c = true;
                    }
                    if (item.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                        item.PriceEvolutionRateValidated__c = item.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        item.SPITM_Rate_Has_Been_Corrected__c = true;
                    }
                }
                if (item.Id != null && oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id)
                    && item.SPITM_PriceList_Statement_Type__c != oldPriceListStatementsMap.get(item.Id).SPITM_PriceList_Statement_Type__c)
                {
                    years.add(item.SPITM_HMP_ReferenceYear__c);
                    nsIds.add(item.NegoScope__c);
                    string key = item.NegoScope__c + '-' + item.SPITM_HMP_ReferenceYear__c + '-' + item.RecordtypeId;
                    insertedHMPMap.put(key, item);
                }
                if (item.RecordTypeId == priceListStatementRTIds.get('Tariff')) {
                    tariffHmpIds.add(item.Id);
                    years.add(item.SPITM_HMP_ReferenceYear__c);
                    nsIds.add(item.NegoScope__c);
                    string key = item.NegoScope__c + '-' + item.SPITM_HMP_ReferenceYear__c + '-' + item.RecordtypeId;
                    insertedHMPMap.put(key, item);
                }
                yearsForNaming.add(item.SPITM_HMP_ReferenceYear__c);
                nsIdsForNaming.add(item.NegoScope__c);
            }
            if (!tariffHmpIds.isEmpty()) {
                for (PriceListStatement__c item : [SELECT Id, PriceListStatementReference__r.Version__c 
                                                                    FROM PriceListStatement__c WHERE Id In:tariffHmpIds] ) 
                {
                    hmpTariffVersionMap.put(item.Id, item.PriceListStatementReference__r.Version__c);
                }
            }
            system.debug('>>>> hmpTariffVersionMap : ' + hmpTariffVersionMap);
            if(!years.isEmpty() && !nsIds.isEmpty()) {
                Map<String, Decimal> btCountMap = new Map<String, Decimal>();
                for (AggregateResult argg : [SELECT NegoScope__c NegoScope__c, RecordtypeId RecordtypeId,
                                             SPITM_HMP_ReferenceYear__c SPITM_HMP_ReferenceYear__c,
                                             MAX(Version__c) version
                                             FROM PriceListStatement__c
                                             WHERE SPITM_HMP_ReferenceYear__c IN :years
                                             AND NegoScope__c IN :nsIds
                                             AND Recordtype.Developername IN ('DepreciationRate', 'RiseRate')
                                             GROUP BY NegoScope__c, SPITM_HMP_ReferenceYear__c, RecordtypeId])
                {
                    String key = (String)argg.get('NegoScope__c') + '-' + (String)argg.get('SPITM_HMP_ReferenceYear__c') + '-' + (String)argg.get('RecordtypeId');
                    btCountMap.put(key, (Decimal)argg.get('version'));
                }
                for (String key : insertedHMPMap.keyset()) {
                    system.debug('>>>> insertedHMPMap.get(key).RecordTypeId : ' + insertedHMPMap.get(key).RecordTypeId);
                    system.debug('>>>> priceListStatementRTIds.get(Tariff) : ' + priceListStatementRTIds.get('Tariff'));
                    if (insertedHMPMap.get(key).RecordTypeId == priceListStatementRTIds.get('Tariff')) {
                        system.debug('>>>> Version__c : ' + hmpTariffVersionMap.get(insertedHMPMap.get(key).Id));
                         insertedHMPMap.get(key).Version__c = hmpTariffVersionMap.get(insertedHMPMap.get(key).Id);
                    } else {
                        if (btCountMap.containsKey(key)) {
                            insertedHMPMap.get(key).Version__c = btCountMap.get(key) + 1;
                        } else {
                            insertedHMPMap.get(key).Version__c = 1;
                        }
                    }
                }
            }
            if(!nsIdsForNaming.isEmpty() && !yearsForNaming.isEmpty()) {
                Map<Id, NegoScope__c> nsMap = new Map<Id, NegoScope__c>([SELECT Id, Name, Supplier__c, CodeLong__c,
                                                                                                                       Supplier__r.Name
                                                                                                                       FROM NegoScope__c
                                                                                                                       WHERE Id IN :nsIdsForNaming]);
                String version, recordTypeName = '';
                NegoScope__c ns;
                for (PriceListStatement__c item : newPriceListStatement) {
                    if (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner')) {
                        recordTypeName = 'Vision ITM';
                        recordTypeName += item.SPITM_PriceList_Statement_Type__c == 'DepreciationRate' ? ' (BT)' : ' (HMP)';
                        version = (item.SPITM_Corrected_Version__c == null ? (Integer)item.Version__c + '' : ((Integer)item.Version__c + '-' + (Integer)item.SPITM_Corrected_Version__c));
                        ns = nsMap.get(item.NegoScope__c);
                        if (ns != null) {
                            item.Name = ns.Supplier__r.Name.left(15) + ' - ' + ns.CodeLong__c + ' - ' + Integer.valueOf(item.ReferenceYear__c) + ' - Tarif ' + version + ' - ' + recordTypeName;
                        }
                    }
                }
            }***/
        }
        
        /***public static void syncHMPToContractAndNegoplan(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            Set<Id> contractIdSet = new Set<Id>();
            Set<Decimal> versionSet = new Set<Decimal> ();
            Set<Id> nsIdSet = new Set<Id>();
            Set<Decimal> yearSet = new Set<Decimal>();
            Map<String, NegoScope__c> nsMap = new Map<String, NegoScope__c>();
            Map<String, PriceListStatement__c> hmpMap = new Map<String, PriceListStatement__c>();
            Map<String, PriceListStatement__c> hmpMap2 = new Map<String, PriceListStatement__c>();
            Map<String, Nego_Plan__c> negoPlanMap = new Map<String, Nego_Plan__c>();
            List<PriceListStatement__c> hmpToUpdateIsCorrectedRateValidatedFalse = new List<PriceListStatement__c>();
            for (PriceListStatement__c item : newPriceListStatements) {
                if (item.Id != null && oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id) &&
                    oldPriceListStatementsMap.get(item.Id).SPITM_IsCorrectedRateValidated__c != item.SPITM_IsCorrectedRateValidated__c && item.SPITM_IsCorrectedRateValidated__c) {
                        if (item.SPITM_PriceList_Statement_Type__c == 'DepreciationRate' || item.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                            if(item.Contrat__c != null) {
                                contractIdSet.add(item.Contrat__c);
                            }
                            nsIdSet.add(item.NegoScope__c);
                            yearSet.add(item.ReferenceYear__c);
                            versionSet.add(item.Version__c);
                            String key = item.SPITM_PriceList_Statement_Type__c + item.NegoScope__c + Integer.valueOf(item.ReferenceYear__c) + Integer.valueOf((item.Version__c != null ? item.Version__c : 1));
                            hmpMap2.put(key, item);
                            key = item.NegoScope__c + '' + Integer.valueOf(item.ReferenceYear__c);
                            hmpMap.put(key, item);
                            hmpToUpdateIsCorrectedRateValidatedFalse.add(item.clone(true));
                        }
                    }
            }
            List<PriceListStatement__c> hmpToUpdate = new List<PriceListStatement__c>();
            if (!nsIdSet.isEmpty() && !yearSet.isEmpty() && !versionSet.isEmpty()) {
                List<PriceListStatement__c> relatedHMPtoUpdate = [SELECT Id, Name, NegoScope__c, ReferenceYear__c, BusinessUnitTarget__c, Version__c,
                                                                                   PriceListStatementReference__c, PriceListStatementReference__r.PriceEvolutionRateCalculated__c,
                                                                                   PriceEvolutionRateValidated__c, SPITM_CorrectedRateRequested__c, SPITM_IsCorrectedRateValidated__c,
                                                                                   PriceEvolutionRateValidated__c
                                                                                   FROM PriceListStatement__c
                                                                                   WHERE Id NOT IN :newPriceListStatements
                                                                                   AND ReferenceYear__c IN :yearSet
                                                                                   AND Version__c IN :versionSet
                                                                                   AND NegoScope__c IN :nsIdSet];
                for (PriceListStatement__c item : relatedHMPtoUpdate) {
                    String key = '' + item.NegoScope__c + Integer.valueOf(item.ReferenceYear__c) + Integer.valueOf((item.Version__c != null ? item.Version__c : 1));
                    String keyRR = 'RiseRate' + key;
                    String keyDR = 'DepreciationRate' + key;
                    Boolean hasChange = false;
                    if (hmpMap2.containsKey(keyRR)) {
                        PriceListStatement__c correctedHMP = hmpMap2.get(keyRR);
                        if (item.PriceEvolutionRateValidated__c != correctedHMP.SPITM_CorrectedRateRequested__c) {
                            item.PriceEvolutionRateValidated__c = correctedHMP.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            hasChange = true;
                        }
                    }
                    if (hmpMap2.containsKey(keyDR)) {
                        PriceListStatement__c correctedHMP = hmpMap2.get(keyDR);
                        if (item.PriceEvolutionRateValidated__c != correctedHMP.SPITM_CorrectedRateRequested__c) {
                            item.PriceEvolutionRateValidated__c = correctedHMP.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            hasChange = true;
                        }
                    }
                    if (hasChange) {
                        hmpToUpdate.add(item);
                    }
                }
                if (!hmpToUpdate.isEmpty()) {
                    Database.update(hmpToUpdate, false);
                }
            }
            if (!nsIdSet.isEmpty() && !yearSet.isEmpty()) {
                List<Nego_Plan__c> negoPlanList = [SELECT Id, NegoScope__c, Nego_Year__c, NegoScope__r.OwnerId,
                                                                  NEGO_Rise_Rate_Validated_Nb__c, NEGO_Depreciation_Rate_Validated_Nb__c,
                                                                  NEGO_Rise_Rate_Validated_YE__c,
                                                                  SPITM_Last_Corrected_RR_Nb__c,
                                                                  SPITM_Last_Corrected_DR_Nb__c,
                                                                  NEGO_Rise_Rate1_Validated__c,
                                                                  NEGO_Rise_Rate2_Validated__c,
                                                                  NEGO_Rise_Rate3_Validated__c,
                                                                  NEGO_Rise_Rate4_Validated__c,
                                                                  NEGO_Rise_Rate5_Validated__c,
                                                                  NEGO_Rise_Rate6_Validated__c,
                                                                  NEGO_Rise_Rate7_Validated__c,
                                                                  NEGO_Rise_Rate8_Validated__c,
                                                                  NEGO_Rise_Rate9_Validated__c,
                                                                  NEGO_Rise_Rate10_Validated__c,
                                                                  NEGO_Depreciation_Rate1_Validated__c,
                                                                  NEGO_Depreciation_Rate2_Validated__c,
                                                                  NEGO_Depreciation_Rate3_Validated__c,
                                                                  SPITM_Is_Corrected_Rise_Rate__c
                                                                  FROM Nego_Plan__c
                                                                  WHERE NegoScope__c IN :nsIdSet
                                                                  AND Nego_Year__c IN :yearSet];
                String fieldName;
                for (Nego_Plan__c item : negoPlanList) {
                    String key = item.NegoScope__c + '' + Integer.valueOf(item.Nego_Year__c);
                    nsMap.put(item.NegoScope__c, item.NegoScope__r);
                    if (hmpMap.containsKey(key)) {
                        PriceListStatement__c hmp = hmpMap.get(key);
                        if (hmp.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                            Integer lastIndex = hmp?.Version__c?.intValue();
                            if (lastIndex == null || lastIndex == 0) {
                                lastIndex = 1;
                            }
                            if (lastIndex > 10) {
                                lastIndex = 10;
                            }
                            if (item.NEGO_Rise_Rate_Validated_Nb__c == lastIndex) {
                                item.NEGO_PriceEvolutionRateValidated__c = hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            }
                            item.put('NEGO_Rise_Rate' + lastIndex + '_Validated__c', hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP));
                            Decimal riseRateValidatedYE = 1;
                            for (Integer i = 1 ; i <= 10 ; i++) {
                                fieldName = 'NEGO_Rise_Rate' + i + '_Validated__c';
                                riseRateValidatedYE *= (1 + (item.get(fieldName) != null ? ((Decimal)item.get(fieldName) / 100) : 0 ));
                            }
                            riseRateValidatedYE--;
                            item.NEGO_Rise_Rate_Validated_YE__c = (riseRateValidatedYE * 100).setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            if (item.SPITM_Last_Corrected_RR_Nb__c == null || item.SPITM_Last_Corrected_RR_Nb__c < lastIndex) {
                                item.SPITM_Last_Corrected_RR_Nb__c = lastIndex;
                            }
                        }
                        if (hmp.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                            Integer lastIndex = hmp?.Version__c?.intValue();
                            if (lastIndex == null || lastIndex == 0) {
                                lastIndex = 1;
                            }
                            if (lastIndex > 3) {
                                lastIndex = 3;
                            }
                            if (item.NEGO_Depreciation_Rate_Validated_Nb__c == lastIndex) {
                                item.NEGO_PriceEvolutionRateValidated__c = hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            }
                            item.put('NEGO_Depreciation_Rate' + lastIndex + '_Validated__c', hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP));
                            Decimal depreciationRateValidatedYE = 1;
                            for (Integer i = 1 ; i <= 3 ; i++) {
                                fieldName = 'NEGO_Depreciation_Rate' + i + '_Validated__c';
                                depreciationRateValidatedYE *= (1 + (item.get(fieldName) != null ? ((Decimal)item.get(fieldName) / 100) : 0));
                            }
                            depreciationRateValidatedYE--;
                            item.NEGO_Depreciation_Rate_Validated_YE__c = (depreciationRateValidatedYE * 100).setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            if (item.SPITM_Last_Corrected_DR_Nb__c == null || item.SPITM_Last_Corrected_DR_Nb__c < lastIndex) {
                                item.SPITM_Last_Corrected_DR_Nb__c = lastIndex;
                            }
                        }
                        item.SPITM_Is_Corrected_Rise_Rate__c = true;
                        negoPlanMap.put(key, item);
                    }
                }
            }
            // Map<String, Contract__c> contractsToUpdateMap = new Map<String, Contract__c>();
            Map<String, Map<Id, Contract__c>> contractsToUpdateMap = new Map<String, Map<Id, Contract__c>>();
            Set<Id> contractsToUpdateIdSet = new Set<Id>();
            if (!contractIdSet.isEmpty()) {
                List<Contract__c> contractList = [SELECT Id,
                                                                 Supplier_Nego_Scope__c,
                                                                 ReferenceYear__c,
                                                                 Supplier_Nego_Scope__r.OwnerId,
                                                                 Rise_Rate_Nb__c,
                                                                 Rise_Rate_YE__c,
                                                                 Depreciation_Rate_Nb__c,
                                                                 Rise_Rate1__c,
                                                                 Rise_Rate2__c,
                                                                 Rise_Rate3__c,
                                                                 Rise_Rate4__c,
                                                                 Rise_Rate5__c,
                                                                 Rise_Rate6__c,
                                                                 Rise_Rate7__c,
                                                                 Rise_Rate8__c,
                                                                 Rise_Rate9__c,
                                                                 Rise_Rate10__c,
                                                                 Depreciation_Rate1__c,
                                                                 Depreciation_Rate2__c,
                                                                 Depreciation_Rate3__c,
                                                                 Name,
                                                                 RecordType.DeveloperName,
                                                                 Status__c,
                                                                 BU_Source__c,
                                                                 Contract_BU__c,
                                                                 Contract_BDate__c,
                                                                 Contract_EDate__c,
                                                                 Index1_v2_perc__c,
                                                                 Index2_v2_perc__c,
                                                                 Index3_v2_perc__c,
                                                                 Index4_v2_perc__c,
                                                                 Index5_v2_perc__c,
                                                                 Index6_v2_perc__c,
                                                                 Index7_v2_perc__c,
                                                                 Index1_v2__c,
                                                                 Index2_v2__c,
                                                                 Index3_v2__c,
                                                                 Index4_v2__c,
                                                                 Index5_v2__c,
                                                                 Index6_v2__c,
                                                                 Index7_v2__c,
                                                                 Index1_perc__c,
                                                                 Index2_perc__c,
                                                                 Index3_perc__c,
                                                                 Index4_perc__c,
                                                                 Index5_perc__c,
                                                                 Index6_perc__c,
                                                                 Index7_perc__c,
                                                                 Index1__c,
                                                                 Index2__c,
                                                                 Index3__c,
                                                                 Index4__c,
                                                                 Index5__c,
                                                                 Index6__c,
                                                                 Index7__c,
                                                                 Depreciation_Rate_YE__c,
                                                                 Markdown_Rate_Break__c,
                                                                 Markdown_Rate_Promo__c,
                                                                 Markdown_Rate_Theft__c,
                                                                 Total_TO__c,
                                                                 Total_TO_Tariff_Nego__c,
                                                                 TO1__c,
                                                                 TO2__c,
                                                                 TO3__c,
                                                                 TO4__c,
                                                                 TO5__c,
                                                                 TO6__c,
                                                                 TO7__c,
                                                                 TO8__c,
                                                                 TO9__c,
                                                                 TO10__c,
                                                                 TO11__c,
                                                                 TO12__c,
                                                                 Qty1__c,
                                                                 Qty2__c,
                                                                 Qty3__c,
                                                                 Qty4__c,
                                                                 Qty5__c,
                                                                 Qty6__c,
                                                                 Qty7__c,
                                                                 Qty8__c,
                                                                 Qty9__c,
                                                                 Qty10__c,
                                                                 Qty11__c,
                                                                 Qty12__c,
                                                                 (SELECT Id,
                                                                  DisplayOrder__c,
                                                                  Contract__c,
                                                                  Parent_Discount__c,
                                                                  Product_Scope__c,
                                                                  BU_Scope__c,
                                                                  Disc_BDate__c,
                                                                  Disc_EDate__c,
                                                                  Is_Excluded_To_NegoBase__c,
                                                                  Exclusion_to_Nego_Base_Value__c,
                                                                  Is_Excluded_To_Nego_Base_F__c,
                                                                  Is_Excluded_To_Nego_Base_U__c,
                                                                  slab_calc_method__c,
                                                                  Index_perc__c,
                                                                  Index__c,
                                                                  Index_v2__c,
                                                                  Base_TO_Nego_YearBase__c,
                                                                  Is_Yearly_Condition__c,
                                                                  YTD_Nego_Computed__c,
                                                                  Index_val__c,
                                                                  Is_Tariff_Condition__c,
                                                                  Base_TO_Tariff_Nego__c,
                                                                  Rank__c,
                                                                  Status__c,
                                                                  Value_amt__c,
                                                                  unit_amount__c,
                                                                  Unit_Amount_Type__c,
                                                                  Base_Quantity_Nego__c,
                                                                  Value_Per__c,
                                                                  Base_TO_Nego__c,
                                                                  RecordTypeId,
                                                                  Condition_Type__r.Index__c,
                                                                  Condition_Type__r.Name,
                                                                  Condition_Type__r.Nego_Discount_Type__c,
                                                                  Respects_Contract_Scope__c,
                                                                  YTD_Nego__c
                                                                  FROM Contract_Discounts__r
                                                                  WHERE Parent_Discount__c = NULL AND Status__c <> 'Deleted'
                                                                  ORDER BY Contract__c,
                                                                  DisplayOrder__c ASC)
                                                                 FROM Contract__c
                                                                 WHERE Supplier_Nego_Scope__c IN :nsIdSet
                                                                 AND ReferenceYear__c IN :yearSet
                                                                 AND Status__c <> 'Deleted'
                                                                 AND OnTop__c = TRUE
                                                                 AND (Id IN :contractIdSet OR (RecordType.DeveloperName IN ('Signed', 'To_Be_Signed')))];
                for (Contract__c item : contractList) {
                    String key = item.Supplier_Nego_Scope__c + '' + Integer.valueOf(item.ReferenceYear__c);
                    nsMap.put(item.Supplier_Nego_Scope__c, item.Supplier_Nego_Scope__r);
                    if (negoPlanMap.containsKey(key)) {
                        Nego_Plan__c negoPlan = negoPlanMap.get(key);
                        item.Rise_Rate_YE__c = negoPlan.NEGO_Rise_Rate_Validated_YE__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                        if (!contractsToUpdateMap.containsKey(key)) {
                            contractsToUpdateMap.put(key, new Map<Id, Contract__c>());
                        }
                        contractsToUpdateMap.get(key).put(item.Id, item);
                        contractsToUpdateIdSet.add(item.Id);
                        item.Is_Conso_Requiered__c = true;
                    }
                    if (hmpMap.containsKey(key)) {
                        PriceListStatement__c hmp = hmpMap.get(key);
                        if (hmp.SPITM_PriceList_Statement_Type__c == 'RiseRate') {
                            Integer lastIndex = hmp?.Version__c?.intValue();
                            if (lastIndex == null || lastIndex == 0) {
                                lastIndex = 1;
                            }
                            if (lastIndex > 10) {
                                lastIndex = 10;
                            }
                            item.Rise_Rate__c = hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            //item.put('Rise_Rate' + lastIndex + '__c', hmp.SPITM_CorrectedRateRequested__c);
                        }
                        if (hmp.SPITM_PriceList_Statement_Type__c == 'DepreciationRate') {
                            Integer lastIndex = hmp?.Version__c?.intValue();
                            if (lastIndex == null || lastIndex == 0) {
                                lastIndex = 1;
                            }
                            if (lastIndex > 3) {
                                lastIndex = 3;
                            }
                            item.Depreciation_Rate__c = hmp.SPITM_CorrectedRateRequested__c?.setScale(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateValidated__c.scale, System.RoundingMode.HALF_UP);
                            //item.put('Depreciation_Rate' + lastIndex + '__c', hmp.SPITM_CorrectedRateRequested__c);
                        }
                        item.Is_Conso_Requiered__c = true;
                        if (!contractsToUpdateMap.containsKey(key)) {
                            contractsToUpdateMap.put(key, new Map<Id, Contract__c>());
                        }
                        contractsToUpdateMap.get(key).put(item.Id, item);
                        contractsToUpdateIdSet.add(item.Id);
                    }
                }
                List<Contract_Discount__c> discountsToUpdate = new List<Contract_Discount__c>();
                List<Contract__c> contractsToUpdate = new List<Contract__c>();
                if (!contractsToUpdateMap.isEmpty()) {
                    for (Map<Id, Contract__c> mapItem : contractsToUpdateMap.values()) {
                        for (Contract__c item : mapItem.values()) {
                            item.SPITM_Bypass_VR__c = true;
                            contractsToUpdate.add(item);
                        }
                    }
                    Database.update(contractsToUpdate, false);
                }
                if (!System.isBatch() && !System.isFuture()) {
                    Database.executeBatch(new CalculateContractIndexesBatch('Trg_ULiT_Price_List_Statement_Handler', new List<Id>(contractsToUpdateIdSet), null), 1);
                } else {
                    for (Contract__c item : contractsToUpdate) {
                        ContractServices contractService = new ContractServices(item, item.Contract_Discounts__r);
                        contractService.calculateContractIndex(false);
                        discountsToUpdate.addAll(item.Contract_Discounts__r);
                    }
                    Database.update(contractsToUpdate, false);
                    for (Contract__c item : contractsToUpdate) {
                        item.SPITM_Bypass_VR__c = false;
                    }
                    Database.update(contractsToUpdate, false);
                }
                if (!discountsToUpdate.isEmpty()) {
                    Database.update(discountsToUpdate, false);
                }
            }
            if (!negoPlanMap.isEmpty()) {
                Database.update(negoPlanMap.values(), false);
            }
            CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Negoptim_Batch_notifications'];
            String title = System.Label.LBL_HMP_Rate_Changed;
            String body = System.Label.MSG_HMP_Rate_Changed_Notification;
            Id userId = Userinfo.getUserId();
            if(type != null) {
                for (PriceListStatement__c item : hmpMap.values()) {
                    if (nsMap.containsKey(item.NegoScope__c)) {
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setBody(body);
                        notification.setTitle(title);
                        notification.setSenderId(userId);
                        notification.setNotificationTypeId(type.Id);
                        notification.setTargetId(item.Id); // target object id
                        notification.send(new Set<String> { nsMap.get(item.NegoScope__c).OwnerId });
                    }
                }
            }
            for (PriceListStatement__c item : hmpToUpdateIsCorrectedRateValidatedFalse) {
                item.SPITM_IsCorrectedRateValidated__c = false;
            }
            if (!hmpToUpdateIsCorrectedRateValidatedFalse.isEmpty()) {
                Database.update(hmpToUpdateIsCorrectedRateValidatedFalse, false);
            }
        }***/
        
        /***private static void updateHMPReported(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
            try{
                Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
                Id riseRate_RTId = priceListStatementRTIds.get('RiseRate');
                Id depreciationRate_RTId = priceListStatementRTIds.get('DepreciationRate');
                Id simulation_RTId = priceListStatementRTIds.get('Simulation');
                Id isoPartner12M_RTId = priceListStatementRTIds.get('IsoPartner');
                List<Id> supplier_RTIds = new List<Id>{riseRate_RTId, depreciationRate_RTId};
                List<Id> simulationITM_RTIds = new List<Id>{simulation_RTId, isoPartner12M_RTId};
                Map<String, PriceListStatement__c> hmpMap = new Map<String, PriceListStatement__c>();
                Map<String, Boolean> hmpReportedMap = new Map<String, Boolean>();
                Map<Id, PriceListStatement__c> allHmpMap = new Map<Id, PriceListStatement__c>();
                Set<Id> nsSetId = new Set<Id>();
                Set<Id> supplierHMPSetId = new Set<Id>();
                Set<Decimal> yearSetDecimal = new Set<Decimal>();
                Set<Decimal> versionSetDecimal = new Set<Decimal>();
                Set<Id> hmpSetId = new Set<Id>();
                Set<Id> itmHMPSetId = new Set<Id>();
                List<String> supplierValidatedStatus = new List<String>{'Opened'};
                    List<String> validatedStatus = new List<String>{'Validated', 'Request For Approval'};
                        for (PriceListStatement__c item : newPriceListStatements) {
                            if (oldPriceListStatementsMap == null ) {
                                if (supplier_RTIds.contains(item.recordTypeId)) {
                                    item.SPITM_Price_List_Reported__c = true;
                                } else {
                                    item.SPITM_Price_List_Reported__c = false;
                                }
                            }
                            if (oldPriceListStatementsMap != null && oldPriceListStatementsMap.containsKey(item.Id) && oldPriceListStatementsMap.get(item.Id).Status__c != item.Status__c) {
                                hmpSetId.add(item.Id);
                            }
                            
                        }
                if (!hmpSetId.isEmpty()) {
                    List<PriceListStatement__c> priceListStatementList = [SELECT Id, SPITM_Price_List_Reported__c, RecordTypeId, RecordType.DeveloperName, Status__c,
                                                                                           NegoScope__c, ReferenceYear__c, Version__c,
                                                                                           PriceListStatementReference__c, PriceListStatementReference__r.PriceListStatementReference__c
                                                                                           FROM PriceListStatement__c
                                                                                           WHERE Id IN :hmpSetId
                                                                                           AND RecordType.DeveloperName NOT IN('Tariff')
                                                                                           AND PriceListStatementReference__r.RecordType.DeveloperName NOT IN('Tariff')
                                                                                           AND PriceListStatementReference__r.PriceListStatementReference__r.RecordType.DeveloperName NOT IN('Tariff')];
                    for (PriceListStatement__c item : priceListStatementList) {
                        nsSetId.add(item.NegoScope__c);
                        versionSetDecimal.add(item.Version__c);
                        yearSetDecimal.add(item.ReferenceYear__c);
                        if (item.RecordType.DeveloperName == 'Simulation') {
                            supplierHMPSetId.add(item.PriceListStatementReference__r.PriceListStatementReference__c);
                        }
                        if (item.RecordType.DeveloperName == 'IsoPartner') {
                            supplierHMPSetId.add(item.PriceListStatementReference__c);
                        }
                        if (item.RecordType.DeveloperName != 'Simulation' && item.RecordType.DeveloperName != 'IsoPartner') {
                            supplierHMPSetId.add(item.Id);
                        }
                    }
                    
                    if (!nsSetId.isEmpty()) {
                        List<PriceListStatement__c> priceListStatementListToUpdate = [SELECT Id, SPITM_Price_List_Reported__c, RecordTypeId, Status__c,
                                                                                                       NegoScope__c, ReferenceYear__c, Version__c,
                                                                                                       PriceListStatementReference__r.PriceListStatementReference__c,
                                                                                                       PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId,
                                                                                                       (SELECT Id, SPITM_Price_List_Reported__c, RecordTypeId, Status__c,
                                                                                                        NegoScope__c, ReferenceYear__c, Version__c,
                                                                                                        PriceListStatementReference__r.PriceListStatementReference__c,
                                                                                                        PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId
                                                                                                        FROM Price_List_Statements__r)
                                                                                                       FROM PriceListStatement__c
                                                                                                       WHERE NegoScope__c IN :nsSetId
                                                                                                       AND ReferenceYear__c IN :yearSetDecimal
                                                                                                       AND Version__c IN : versionSetDecimal
                                                                                                       AND Id IN :supplierHMPSetId];
                        for (PriceListStatement__c item :priceListStatementListToUpdate) {
                            String key = item.NegoScope__c + '-' + item.ReferenceYear__c + '-' + item.Version__c;
                            //hmpMap.put(key + '-' + item.Id + '-' + item.RecordTypeId, new PriceListStatement__c(Id = item.Id, SPITM_Price_List_Reported__c = false));
                            hmpReportedMap.put(key + '-' + item.Id + '-' + item.RecordTypeId, false);
                            allHmpMap.put(item.Id, item);
                            if (validatedStatus.contains(item.Status__c)) {
                                //hmpMap.get(key + '-' + item.Id + '-' + item.recordTypeId).SPITM_Price_List_Reported__c = true;
                                hmpReportedMap.put(key + '-' + item.Id + '-' + item.recordTypeId, true);
                            } else {
                                if ( item.Price_List_Statements__r.size() == 0) {
                                    continue;
                                }
                                PriceListStatement__c itmHMP = item.Price_List_Statements__r[0];
                                //hmpMap.put(key+ '-' + itmHMP.Id + '-' + itmHMP.RecordTypeId, new PriceListStatement__c(Id = itmHMP.Id, SPITM_Price_List_Reported__c = false));
                                 allHmpMap.put(itmHMP.Id, itmHMP);
                                hmpReportedMap.put(key+ '-' + itmHMP.Id + '-' + itmHMP.RecordTypeId, false);
                                if (validatedStatus.contains(itmHMP.Status__c)) {
                                    //hmpMap.get(key + '-' + itmHMP.Id + '-' + itmHMP.recordTypeId).SPITM_Price_List_Reported__c = true;
                                    hmpReportedMap.put(key + '-' + itmHMP.Id + '-' + itmHMP.recordTypeId, true);
                                } else {
                                    if (supplierValidatedStatus.contains(item.Status__c)) {
                                        //hmpMap.get(key + '-' + item.Id + '-' + item.recordTypeId).SPITM_Price_List_Reported__c = true;
                                        hmpReportedMap.put(key + '-' + item.Id + '-' + item.recordTypeId, true);
                                    }
                                    itmHMPSetId.add(itmHMP.Id);
                                }
                            } 
                        }
                        List<PriceListStatement__c> updateHmps = new List<PriceListStatement__c>();
                        List<PriceListStatement__c> hmpSimulationToUpdate = [SELECT Id, SPITM_Price_List_Reported__c, RecordTypeId, Status__c,
                                                                                              NegoScope__c, ReferenceYear__c, Version__c,
                                                                                              PriceListStatementReference__r.PriceListStatementReference__c,
                                                                                              PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId
                                                                                              FROM PriceListStatement__c
                                                                                              WHERE NegoScope__c IN :nsSetId
                                                                                              AND ReferenceYear__c IN :yearSetDecimal
                                                                                              AND Version__c IN : versionSetDecimal
                                                                                              AND PriceListStatementReference__c IN :itmHMPSetId];
                        for (PriceListStatement__c item :hmpSimulationToUpdate) {
                            String key = item.NegoScope__c + '-' + item.ReferenceYear__c + '-' + item.Version__c ;
                            //hmpMap.put(key + '-' + item.Id + '-' + item.RecordTypeId, new PriceListStatement__c(Id = item.Id, SPITM_Price_List_Reported__c = false));
                            hmpReportedMap.put(key + '-' + item.Id + '-' + item.RecordTypeId, false);
                            allHmpMap.put(item.Id, item);
                            if (validatedStatus.contains(item.Status__c)) {
                                //hmpMap.get(key + '-' + item.Id + '-' + item.recordTypeId).SPITM_Price_List_Reported__c = true;
                                hmpReportedMap.put(key + '-' + item.Id + '-' + item.recordTypeId, true);
                               // hmpMap.get(key + '-' + item.PriceListStatementReference__r.PriceListStatementReference__c + '-' + item.PriceListStatementReference__r.PriceListStatementReference__r.recordTypeId).SPITM_Price_List_Reported__c = false;
                                hmpReportedMap.put(key + '-' + item.PriceListStatementReference__r.PriceListStatementReference__c + '-' + item.PriceListStatementReference__r.PriceListStatementReference__r.recordTypeId, false);
                            }
                        }
                        system.debug('>>>> allHmpMap.values() : ' + allHmpMap.values().size());
                        for (PriceListStatement__c hmp : allHmpMap.values()) {
                            String key = hmp.NegoScope__c + '-' + hmp.ReferenceYear__c + '-' + hmp.Version__c;
                            String key1 = key + '-' + hmp.Id + '-' + hmp.RecordTypeId;
                            String key2 = key + '-' + hmp.PriceListStatementReference__r.PriceListStatementReference__c + '-' + hmp.PriceListStatementReference__r.PriceListStatementReference__r.recordTypeId;
                            if (hmpReportedMap.containskey(key1) && hmpReportedMap.get(key1) != hmp.SPITM_Price_List_Reported__c) {
                                hmp.SPITM_Price_List_Reported__c = hmpReportedMap.get(key1);
                                hmpMap.put(hmp.Id, hmp);
                            }
                            if (hmpReportedMap.containskey(key2) && hmpReportedMap.get(key2) != hmp.SPITM_Price_List_Reported__c) {
                                hmp.SPITM_Price_List_Reported__c = hmpReportedMap.get(key2);
                                hmpMap.put(hmp.Id, hmp);
                            }
                        }
                        System.debug('hmpMap>>>> ' + JSON.serialize(hmpMap.values()));
                        if (!hmpMap.isEmpty()) {
                            update hmpMap.values();
                        }
                    }
                }
            } catch (Exception ex) {
                System.debug('++++++++++++++++++++++++++++++');
                System.debug(ex.getMessage() );
                System.debug(ex.getStackTraceString() );
                System.debug(' >>> ' + ex.getLineNumber());
                System.debug('++++++++++++++++++++++++++++++');
            }
        }***/
    }