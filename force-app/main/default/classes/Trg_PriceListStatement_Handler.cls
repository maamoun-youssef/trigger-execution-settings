/**
 * @author ULiT
 * @date 05-08-2025
 * @description handler class for custom logic in PriceListStatement__c Apex Trigger
*/
public without sharing class Trg_PriceListStatement_Handler implements MethodUtils.MethodChecker {
    
    public static final Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    public static final List<String> methodList = new List<String> {
        'getMethodNames',
        'populateFields',
        'stopUnitNeedProducts',
        'synchronisePriceListStatementDetails',
        'duplicatePriceListStatement',
        'cleanUpRelatedList',
        'generatePLSName'
    };
    
    public Boolean hasMethod(String methodName) {
        return methodList.contains(methodName);
    }
    
    public Object invoke(String methodName, List<Object> args) {
        List<PriceListStatement__c> newList = args.size() > 0 ? (List<PriceListStatement__c>) args[0] : null;
        Map<Id, PriceListStatement__c> oldMap = args.size() > 1 ? (Map<Id, PriceListStatement__c>) args[1] : null;
        switch on methodName {
            when 'getMethodNames' {
                return getMethodNames();
            }
            when 'populateFields' {
                populateFields(newList, oldMap); // BEFORE INSERT
            }
            when 'stopUnitNeedProducts' {
                stopUnitNeedProducts(newList, oldMap); // BEFORE INSERT
            }
            when 'synchronisePriceListStatementDetails' {
                synchronisePriceListStatementDetails(newList, oldMap); // BEFORE INSERT
            }
            when 'duplicatePriceListStatement' {
                duplicatePriceListStatement(newList, oldMap); // BEFORE INSERT
            }
            when 'cleanUpRelatedList' {
                cleanUpRelatedList(oldMap); // BEFORE INSERT
            }
            when 'generatePLSName' {
                generatePLSName(newList, oldMap); // BEFORE INSERT OR UPDATE
            }
            when else {
                throw new IllegalArgumentException('Method not found: ' + methodName);
            }
        }
        return '';
    }
    
    public static List<String> getMethodNames() {
        Integer getMethodNamesIndex = methodList.indexOf('getMethodNames');
        methodList.remove(getMethodNamesIndex);
        return methodList;
    }
    
    private static void populateFields(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        Set<Id> recordTypeIdsSet = new Set<Id>();
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> buSourceIdSet = new Set<Id>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> nsIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<String, Decimal> priceListStatementVersionMap = new Map<String, Decimal>();
        for (PriceListStatement__c item : newPriceListStatements) {
            if(item.RecordTypeId != null) {
                recordTypeIdsSet.add(item.RecordTypeId);
            }
            if(item.BusinessUnitTarget__c != null) {
                buTargetIdSet.add(item.BusinessUnitTarget__c);
            }
            if(item.BusinessUnitSource__c != null) {
                buSourceIdSet.add(item.BusinessUnitSource__c);
            }
            if(item.Supplier__c != null) {
                supplierIdSet.add(item.Supplier__c);
            }
            if(item.NegoScope__c != null) {
                nsIdSet.add(item.NegoScope__c);
            }
            yearSet.add(Integer.valueOf(item.ReferenceYear__c));
            // case Insert PriceListStatement__c
            if (item.Id == null) {
                item.Status__c = 'InPreparation';
                if (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') || item.RecordTypeId == priceListStatementRTIds.get('Simulation')) {
                    item.PriceEvolutionRateCalculated__c = null;
                    item.PriceEvolutionRateCalculated__c = null;
                    item.PriceEvolutionRateInclTaxCalculated__c = null;
                    /***item.UnitPriceEvolutionRateInclTaxCalculated__c__c = null;***/
                    item.TaxEvolutionRateCalculated__c = null;
                    /***item.SellIn_Total_wGrossPricePrevious__c = null;***/
                }
            }
        }
        Map<Id, BusinessUnit__c> buTargetMap = new Map<Id, BusinessUnit__c>();
        // Populate Version
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
            for (PriceListStatement__c item : priceListStatementsList) {
                String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.BusinessUnitSource__c + '-' + item.Supplier__c + '-' + item.NegoScope__c + '-' + Integer.valueOf(item.ReferenceYear__c);
                if (!priceListStatementVersionMap.containsKey(key)) {
                    Decimal lastVersion = item.Version__c == null ? 0 : item.Version__c;
                    priceListStatementVersionMap.put(key, lastVersion);
                }
            }
            for (PriceListStatement__c item : newPriceListStatements) {
                String key = item.RecordTypeId + '-' + item.BusinessUnitTarget__c + '-' + item.BusinessUnitSource__c + '-' + item.Supplier__c + '-' + item.NegoScope__c + '-' + Integer.valueOf(item.ReferenceYear__c);
                if (!priceListStatementVersionMap.containsKey(key)) {
                    priceListStatementVersionMap.put(key, 0);
                }
                Decimal lastVersion = priceListStatementVersionMap.get(key);
                lastVersion++;
                item.Version__c = lastVersion;
                priceListStatementVersionMap.put(key, lastVersion);
            }
        }
    }

    /**
     * @description ON AFTER UPDATE
     * executes for PriceListStatement__c with IsTaxesReported__c changed to TRUE
     * updates PriceListStatementDetail__c tax and discount fields respectvily from related SupplierTax__c records
     * PriceListStatementDetail__c and SupplierTax__c are related if the have the same PriceListStatement__c
     * logic is implemented following the specifications in the asset file "NEGOP - FS.STAT.07 - PriceList Statement Taxes synchro to Detail v1.0"
	*/
    private static void synchronisePriceListStatementDetails(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        Set<Id> taxReportedPriceListStatementIdSet = new Set<Id>(); // IsTaxesReported__c is modified from FALSE to TRUE
        Map<Id, List<SupplierTax__c>> netPriceSupNSTaxesStatementsMap = new Map<Id, List<SupplierTax__c>>(); // PriceListStatement__c.Id => List<SupplierTax__c>
        Map<Id, List<PriceListStatementDetail__c>> netPriceStatementDetailsMap = new Map<Id, List<PriceListStatementDetail__c>>(); // PriceListStatement__c.Id => List<PriceListStatementDetail__c>
        Map<Id, PriceListStatementDetail__c> netPriceStatementDetailToUpdateMap = new Map<Id, PriceListStatementDetail__c>();

        // loop over newPriceListStatements
        for (PriceListStatement__c item : newPriceListStatements) {
            // check if IsTaxesReported__c is modified from FALSE to TRUE
            if (item.IsTaxesReported__c
                && oldPriceListStatementsMap.containsKey(item.Id) && !oldPriceListStatementsMap.get(item.Id).IsTaxesReported__c)
            {
                // add item Id to a set taxReportedPriceListStatementIdSet of PriceListStatement__c with IsTaxesReported__c checked
                taxReportedPriceListStatementIdSet.add(item.Id);
            }
        }
        if (!System.isBatch() && !taxReportedPriceListStatementIdSet.isEmpty()) {
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'Trg_PriceListStatement_Handler',
                'priceListStatementIdSet' => taxReportedPriceListStatementIdSet
            };
            NegoptimBatch.executeBatch('PriceListStatementSynchroBatch', paramsMap, 200);
        }
    }
    /**
     * Synchronize PriceListStatement__c to PG__c upon validation
     * */
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
                if ( // Validate from PriceList = RiseRate/Tariff
                    (((item.RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff')))
                      || (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && (refRecordType == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && refRecordType == priceListStatementRTIds.get('Tariff'))))
                      || (item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (refRef_RecordTypeId == priceListStatementRTIds.get('RiseRate') || (priceListStatementRTIds.containsKey('Tariff') && refRef_RecordTypeId == priceListStatementRTIds.get('Tariff')))))
                     && (item.Status__c == 'RequestForApproval' || item.Status__c == 'Validated') && item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c)
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
            // NegoptimBatch.executeBatch(new PriceListStatementToPGSynchroBatch('Trg_PriceListStatement_Handler', priceListStatementIds, null, true), 200);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'Trg_PriceListStatement_Handler',
                'priceListStatementIds' => priceListStatementIds,
                'priceListStatementDetailIds' => null,
                'executInitPriceListStatementBatch' => true
            };
            NegoptimBatch.executeBatch('PriceListStatementToPGSynchroBatch', paramsMap, 200);
        }
    }
    
    private static void recalculateIsoParterVolume(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        List<PriceListStatement__c> hmps = new List<PriceListStatement__c>();
        for (PriceListStatement__c item : newPriceListStatements) {
            if (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && item.Status__c == 'InPreparation' && item.ReferenceYear__c > 2024 
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
     * @description ON AFTER UPDATE
     * synchro PriceListStatement__c to Nego_Plan__c
     */
    /***private static void synchroToNegoPlans(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        Set<Id> negoScopeSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Map<Id, PriceListStatement__c> priceListStmtMap = new Map<Id, PriceListStatement__c>(newPriceListStatements);
        Map<Id, PriceListStatement__c> priceListStmtRefMap = new Map<Id,PriceListStatement__c>();
        Map<String, List<PriceListStatement__c>> priceListStatementForNegoPlanMap = new Map<String, List<PriceListStatement__c>>();
        priceListStmtRefMap = new Map<Id,PriceListStatement__c>([SELECT PriceListStatementReference__c, NegoScope__r.SupplyChainType__c, PriceListStatementReference__r.PriceListStatementReference__c, PriceListStatementReference__r.RecordTypeId, PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId
                                                                       FROM PriceListStatement__c
                                                                       WHERE Id IN : priceListStmtMap.keySet()]);
        if (!priceListStmtRefMap.isEmpty()) {
            for (PriceListStatement__c item : newPriceListStatements) {
                if ((priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff'))) {
                    continue;
                }
                Id refRecordType = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.RecordTypeId;
                Id refRef_RecordTypeId = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordTypeId;
                if (((item.RecordTypeId == priceListStatementRTIds.get('RiseRate')
                      || (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && refRecordType == priceListStatementRTIds.get('RiseRate'))
                      || (item.RecordTypeId == priceListStatementRTIds.get('Simulation') && refRef_RecordTypeId == priceListStatementRTIds.get('RiseRate')))
                     && (item.Status__c == 'Request For Approval' || item.Status__c == 'Validated') && ((oldPriceListStatementsMap != null && item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c) || oldPriceListStatementsMap == null))
                    || ((item.RecordTypeId == priceListStatementRTIds.get('DepreciationRate')
                         || (item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && refRecordType == priceListStatementRTIds.get('DepreciationRate'))
                         || (item.RecordTypeId == priceListStatementRTIds.get('Simulation') && refRef_RecordTypeId == priceListStatementRTIds.get('DepreciationRate')))
                        && (item.Status__c == 'Validated' && ((oldPriceListStatementsMap != null && item.Status__c != oldPriceListStatementsMap.get(item.Id).Status__c) || oldPriceListStatementsMap == null))))
                {
                    negoScopeSet.add(item.NegoScope__c);
                    yearSet.add(Integer.valueOf(item.ReferenceYear__c));
                    String key = String.valueOf(item.NegoScope__c) + String.valueOf(Integer.valueOf(item.ReferenceYear__c));
                    if (!priceListStatementForNegoPlanMap.containsKey(key)) {
                        priceListStatementForNegoPlanMap.put(key, new List<PriceListStatement__c>());
                    }
                    priceListStatementForNegoPlanMap.get(key).add(item);
                }
            }
        }
        updateNegoPlan(priceListStatementForNegoPlanMap, negoScopeSet, yearSet, priceListStmtRefMap);
    }***/

    /***private static void updateNegoPlan(Map<String, List<PriceListStatement__c>> priceListStatementForNegoPlanMap, Set<Id> negoScopeSet, Set<Integer> yearSet, Map<Id, PriceListStatement__c> priceListStmtRefMap) {
        // update Nego_Plan__c
        if(!negoScopeSet.isEmpty() && !yearSet.isEmpty()) {
            Map<String, Nego_Plan__c> updatedNegoPlanMap = new Map<String, Nego_Plan__c>();
            Map<String, Nego_Plan__c> negoPlanMap = new Map<String, Nego_Plan__c>();
            for (Nego_Plan__c item : [SELECT Id, NegoScope__c, Nego_Year__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Depreciation_Rate_Date__c,
                                     NEGO_Depreciation_Rate_Validated_Nb__c, NEGO_Depreciation_Rate1_Validated__c, NEGO_Depreciation_Rate_Validated_YE__c,
                                     NEGO_Depreciation_Rate2_Validated__c, NEGO_Depreciation_Rate3_Validated__c, NEGO_Depreciation_Rate_Date1__c, NEGO_Depreciation_Rate_Date2__c,
                                     NEGO_Depreciation_Rate_Date3__c, NEGO_PriceEvolutionRateRequested__c, NEGO_PriceEvolutionRateValidated__c, NEGO_Rise_Rate_Status__c, NEGO_Rise_Rate_Date__c,
                                     NEGO_Rise_Rate_Negotiated_OnTop__c, NEGO_Rise_Rate_IsoPartner__c, NEGO_Rise_Rate_Requested_Date__c, NEGO_Rise_Rate_Validated_YE__c,
                                     NEGO_Rise_Rate1_Validated__c, NEGO_Rise_Rate2_Validated__c, NEGO_Rise_Rate3_Validated__c, NEGO_Rise_Rate4_Validated__c,
                                     NEGO_Rise_Rate5_Validated__c, NEGO_Rise_Rate6_Validated__c, NEGO_Rise_Rate7_Validated__c, NEGO_Rise_Rate8_Validated__c,
                                     NEGO_Rise_Rate9_Validated__c, NEGO_Rise_Rate10_Validated__c, NEGO_Rise_Rate_Validated_Nb__c
                                     FROM Nego_Plan__c
                                     WHERE NegoScope__c = :negoScopeSet
                                     AND Nego_Year__c = :yearSet])
            {
               negoPlanMap.put(String.valueOf(item.NegoScope__c) + String.valueOf(item.Nego_Year__c), item);
            }
            if (!negoPlanMap.isEmpty()) {
                Boolean isDepRateRef = false;
                for (String key : negoPlanMap.keySet()) {
                    Nego_Plan__c negoPlan = negoPlanMap.get(key);
                    if (priceListStatementForNegoPlanMap.containsKey(key)) {
                        for (PriceListStatement__c priceListStatement : priceListStatementForNegoPlanMap.get(key)) {
                            isDepRateRef = false;
                            if ((priceListStatement.RecordTypeId == priceListStatementRTIds.get('DepreciationRate')
                                 || (priceListStatement.RecordTypeId == priceListStatementRTIds.get('IsoPartner')
                                     && priceListStmtRefMap.get(priceListStatement.Id)?.PriceListStatementReference__r?.RecordTypeId == priceListStatementRTIds.get('DepreciationRate'))
                                 || (priceListStatement.RecordTypeId == priceListStatementRTIds.get('Simulation')
                                     && priceListStmtRefMap.get(priceListStatement.Id)?.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordTypeId == priceListStatementRTIds.get('DepreciationRate'))))
                            {
                                isDepRateRef = true;
                            }
                            if (priceListStatement.RecordTypeId == priceListStatementRTIds.get('Simulation') && priceListStatement.OnTop__c && !isDepRateRef) {
                                negoPlan.NEGO_Rise_Rate_Negotiated_OnTop__c	 = priceListStatement.PriceEvolutionRateCalculated__c;
                            }
                            if (priceListStatement.Status__c == 'Request for approval' || priceListStatement.Status__c == 'Validated') {
                                if (priceListStatement.RecordTypeId == priceListStatementRTIds.get('DepreciationRate') || isDepRateRef) {
                                    Integer depreciationRateCount = 3;
                                    String fieldName;
                                    //Integer depreciationRateNb = (negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c != null ? Integer.valueOf(negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c) : 0) + 1;
                                    Integer depreciationRateNb  = priceListStatement.Version__c != null ? (priceListStatement.Version__c > 3 ? 3 : Integer.valueOf(priceListStatement.Version__c)) : 1;
                                    if (depreciationRateNb <= depreciationRateCount) {
                                        fieldName = 'NEGO_Depreciation_Rate' + depreciationRateNb + '_Validated__c';
                                        negoPlan.put(fieldName, (-1 * priceListStatement.PriceEvolutionRateValidated__c));
                                        fieldName = 'NEGO_Depreciation_Rate_Date' + depreciationRateNb + '__c';
                                        negoPlan.put(fieldName, priceListStatement.ApplicationDateValidated__c);
                                        negoPlan.NEGO_PriceEvolutionRateValidated__c =  (-1 * priceListStatement.PriceEvolutionRateValidated__c);
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
                                        negoPlan.put(fieldName, priceListStatement.PriceEvolutionRateValidated__c);
                                        fieldName = 'NEGO_Rise_Rate_Date' + riseRateNb + '__c';
                                        negoPlan.put(fieldName, priceListStatement.ApplicationDateValidated__c);
                                        negoPlan.NEGO_PriceEvolutionRateValidated__c = priceListStatement.PriceEvolutionRateValidated__c;
                                        negoPlan.NEGO_Rise_Rate_Date__c = priceListStatement.ApplicationDateValidated__c;
                                    }
                                }
                            }
                            updatedNegoPlanMap.put(key, negoPlan);
                        }
                    }
                }
                if(!updatedNegoPlanMap.isEmpty()) {
                    update updatedNegoPlanMap.values();
                }
            }
        }
    }***/
    /**
     * @description ON AFTER UPDATE
     * Duplicate PriceListStatement__c (Rise_Rate to IsoPartner)
     */
    private static void duplicatePriceListStatement(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        Set<Id> priceListStatementIdSet = new Set<Id>();
        // loop over newPriceListStatements
        for (PriceListStatement__c item : newPriceListStatements) {
             if ((item.RecordTypeId == priceListStatementRTIds.get('RiseRate') || item.RecordTypeId == priceListStatementRTIds.get('DepreciationRate') || (priceListStatementRTIds.containsKey('Tariff') && item.RecordTypeId == priceListStatementRTIds.get('Tariff'))) &&
                item.SetGenerateISOPartner__c && item.SetGenerateISOPartner__c != oldPriceListStatementsMap.get(item.Id).SetGenerateISOPartner__c
                && oldPriceListStatementsMap.get(item.Id).SetGenerateISOPartner__c == false)
            {
                priceListStatementIdSet.add(item.Id);
            }
            //// TODO: Remove from patch and add in open source code
            // RT SPITM_Rise_Rate_Tentative is open source
            /***if ((priceListStatementRTIds.containsKey('SPITM_Rise_Rate_Tentative') && item.RecordTypeId == priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative'))
                && item.SetGenerateISOPartner__c
                && item.SetGenerateISOPartner__c != oldPriceListStatementsMap.get(item.Id).SetGenerateISOPartner__c)
            {
                priceListStatementIdSet.add(item.Id);
            }***/
        }
        if (!System.isBatch() && !priceListStatementIdSet.isEmpty()) {
            String selectedSellInRule = '12M';
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'Trg_PriceListStatement_Handler',
                'priceListStatementSet' => priceListStatementIdSet,
                'selectedSellInRule' => selectedSellInRule,
                'manualSellInRulesMap' => null,
                'isSimulation' => false
            };
            NegoptimBatch.executeBatch('DuplicatePriceListStatementBatch', paramsMap, 200);
        }
    }

    /**
     * Clean Up SupplierTax__c Where PriceListStatement__c = NULL
     * On After Delete
     * */
    public static void cleanUpRelatedList(Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        // delete SupplierTax__c
        delete [SELECT Id FROM SupplierTax__c WHERE PriceListStatement__c = NULL /***AND NetPrice_Statement__c = NULL***/ LIMIT 10000];
    }

    /**
     * @description ON AFTER UPDATE
     * Stop UN when Target_Product_Life_Status__c = Stop and the related product is Unit Need
    */
    public static void stopUnitNeedProducts(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        Set<Id> priceListStatementIdSet = new Set<Id>();
        for (PriceListStatement__c item : newPriceListStatements) {
            if (oldPriceListStatementsMap?.get(item.Id)?.Status__c != item.Status__c && item.Status__c == 'Validated') {
                priceListStatementIdSet.add(item.Id);
            }
        }
        if (!priceListStatementIdSet.isEmpty()) {
            List<PriceListStatementDetail__c> priceListStatementDetail = [SELECT Id, Product__c, Product__r.isActive, Product__r.Status__c, Product__r.Market_End_of_Life_Date__c FROM PriceListStatementDetail__c WHERE PriceListStatement__c IN :priceListStatementIdSet /***AND Target_Product_Life_Status__c = 'Stop'***/ AND Product__c <> NULL AND Product__r.RecordType.DeveloperName = 'Unit_Need' AND (Product__r.isActive = TRUE OR Product__r.Status__c <> 'Closed')];
            List<Product2> productsToStop = new List<Product2>();
            for (PriceListStatementDetail__c item : priceListStatementDetail) {
                Product2 product = item.Product__r;
                product.IsActive = false;
                product.Status__c = 'Closed';
                product.Market_End_of_Life_Date__c = Date.today();
                productsToStop.add(product);
            }
            if (!productsToStop.isEmpty()) {
                update productsToStop;
            }
            if (!productsToStop.isEmpty()) {
                List<PG__c> supplierPgMappingToStop = [SELECT Id FROM PG__c WHERE Product__c IN :productsToStop AND Status__c <> 'Close'];
                for (PG__c item : supplierPgMappingToStop) {
                    item.Status__c = 'Close';
                }
                if (!supplierPgMappingToStop.isEmpty()) {
                    update supplierPgMappingToStop;
                }
            }
        }
    }
    
    public static void generatePLSName(List<PriceListStatement__c> newPriceListStatements, Map<Id, PriceListStatement__c> oldPriceListStatementsMap) {
        system.debug('generatePLSName ');
        Map<Id, String> plsRTDeveloperName = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(PriceListStatement__c.SObjectType);
        Map<String, NegoSettings.NameConfigurationWrapper> plsNameConfiguration = NegoSettings.loadNegoSettings()?.priceListStatementsConfiguration?.nameConfiguration;
        Map<String, List<String>> plsNameConfigurationFields = new Map<String, List<String>>();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        if (plsNameConfiguration != null && !plsNameConfiguration.isEmpty()) {
            for (String rt : plsNameConfiguration.keySet()) {
                Pattern pattern = Pattern.compile('\\{!(.*?)\\}');
                Matcher matcher = pattern.matcher(plsNameConfiguration.get(rt).template);
                // Collect matches using a list comprehension-like approach
                List<String> matches = new List<String>();
                while (matcher.find()) {
                    matches.add(matcher.group(1)); // Add the captured group to the list
                }
                plsNameConfigurationFields.put(rt, matches);
            }
            if (!plsNameConfigurationFields.isEmpty()) {
                Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(SObjectType.PriceListStatement__c.Name).getDescribe().fields.getMap();
                for (PriceListStatement__c item : newPriceListStatements) {
                    Boolean isConcatenateNameUpdated = false;
                    String recordTypeDeveloperName = plsRTDeveloperName.get(item.RecordTypeId);
                    String template = plsNameConfiguration.get(recordTypeDeveloperName)?.template ?? plsNameConfiguration.get('DEFAULT')?.template;
                    List<String> fields = plsNameConfigurationFields.get(recordTypeDeveloperName) ?? plsNameConfigurationFields.get('DEFAULT');
                    for (String field : fields) {
                        if (!fieldsMap.containsKey(field) && !fieldsMap.containsKey(prefix + field)) {
                            continue;
                        }
                        if (oldPriceListStatementsMap == null || (oldPriceListStatementsMap != null && item.get(field) != oldPriceListStatementsMap.get(item.Id).get(field))) {
                            isConcatenateNameUpdated = true;
                        }
                        String value = String.valueOf(item.get(field));
                        template = template.replace('{!' + field + '}', value != null ? value : '');
                    }
                    Boolean allowUpdate = plsNameConfiguration.containsKey(recordTypeDeveloperName) && plsNameConfiguration.get(recordTypeDeveloperName)?.allowUpdate;
                    if (oldPriceListStatementsMap == null || (oldPriceListStatementsMap != null
                                                              && !allowUpdate
                                                              && (item.Name != oldPriceListStatementsMap.get(item.Id).Name
                                                                  || isConcatenateNameUpdated)))
                    {
                        item.Name = template;
                    }
                }
            }
        }
    }
}