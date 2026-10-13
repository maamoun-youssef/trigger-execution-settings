/**
 * @author ULIT
 * @description Handler Class for NegoScope__c triggers
 * */
public with sharing class Trg_NegoScope_Handler {
    public static Map<String, Id> negoScopeRTIds = NegoptimHelper.getObjectRecordTypeMapIds(NegoScope__c.SObjectType);
    
    public static void OnBeforeInsertOrUpdate(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        populateFields(nNSs, oNSMap);
    }
    
    public static void OnBeforeUpdate(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        updateRecordTypeOnValidation(nNSs, oNSMap);
    }
    
    public static void OnBeforeInsert(List<NegoScope__c> nNSs) {
        initGlobalLocation(nNSs);
    }
    
    public static void OnAfterUpdate(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        // Call this method everytime after update but before calling setAllRelations
        //cleanUpRelatedList(nNSs, oNSMap);
        updateSubNSOwner(nNSs, oNSMap);
        updateNSDetailOwnerId(nNSs, oNSMap);
        updateSubNSGlobalLocation(nNSs, oNSMap);
    }
     
    public static void OnAfterInsertOrUpdate(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        //setAllRelations(nNSs, oNSMap);
    }
    
    public static void OnAfterDelete() {
        cleanUpRelatedList();
    }
    
    /**
     * @description
     * 1-avoidNSDup: Check unique NS Name + Supplier
     * 2-avoidSetParentWhenRelatedToContract: Do Not Allow To Put Parent Of NS If This NS Is Attached To One Or More Contract
     * 3-selectNSRecordType: update negoscope record Type when ns has parent
     * 4-assignSupCurrencyISOCode: assign the supplier currency ISO code into the NS currency ISO code
     * @param List<Sup_sup_NegoScope__c>
     * On Before Insert or Update
     **/
    private static void populateFields(List<NegoScope__c> nNSs,  Map<Id, NegoScope__c> oNSMap) {
        Map<Id, NegoScope__c> nNSMap = new Map<Id, NegoScope__c>();
        String subNSRecordType = NegoptimHelper.getObjectRecordTypeId(NegoScope__c.SObjectType, 'SubNS');
        Set<Id> nsIdSet = new Set<Id>();
        Set<Id> supplierIds = new Set<Id>();
        //@todo : Might use a inner class to handle more the negoscope management
        Set<String> negoScopeNamesSet = new Set<String>();
        Set<Id> negoScopeSuppliersSet = new Set<Id>();
        Map<String, NegoScope__c> negoScopeKeysMap = new Map<String, NegoScope__c>();
        for (NegoScope__c item : nNSs) {
            // check unique NS Name + Supplier
            if (item.Id == null ||
                (oNSMap != null && oNSMap.containsKey(item.Id) && (item.Name != oNSMap.get(item.Id).Name || item.Supplier__c != oNSMap.get(item.Id).Supplier__c)))
            {
                negoScopeNamesSet.add(item.Name);
                negoScopeSuppliersSet.add(item.Supplier__c);
                String key = item.Name + '' + item.Supplier__c;
                if (negoScopeKeysMap.containsKey(key)) {
                    item.addError(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique, new String[]{ item.Name }));
                } else {
                    negoScopeKeysMap.put(key, item);
                }
            }
            // Do Not Allow To Put Parent Of NS If This NS Is Attached To One Or More Contract
            if(item.Id != null && oNSMap != null && oNSMap.containsKey(item.Id) && item.NegoScopeParent__c != null && oNSMap.get(item.Id).NegoScopeParent__c == null) {
                nsIdSet.add(item.Id);
                nNSMap.put(item.Id, item);
            }
            // update negoscope record Type when ns has parent
            // assign the supplier currency ISO code into the NS currency ISO code
            if(item.Id == null) {
                if (item.NegoScopeParent__c != null && item.RecordTypeId != subNSRecordType) {
                    item.RecordTypeId = subNSRecordType;
                }
                if (item.Supplier__c != null) {
                    supplierIds.add(item.Supplier__c);
                }
            }
        }
        // 1- check unique NS Name + Supplier
        if(!negoScopeNamesSet.isEmpty() && !negoScopeSuppliersSet.isEmpty()) {
            // check security on access NegoScope__c fields
            List<String> nsFields = new List<String> {
                SObjectType.NegoScope__c.fields.Name.Name,
                SObjectType.NegoScope__c.fields.Supplier__c.Name
            };
            if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, nsFields)) {
                // Using a single database query, find all the nNSs in the database that have the same name as any of the NSs being inserted or updated.
                for (NegoScope__c item : [SELECT Name, Supplier__c
                                          FROM NegoScope__c
                                          WHERE Name IN :negoScopeNamesSet
                                          AND Supplier__c IN :negoScopeSuppliersSet])
                {
                    String key = item.Name + '' + item.Supplier__c;
                    if (negoScopeKeysMap.containsKey(key)) {
                        negoScopeKeysMap.get(key).addError(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique, new String[]{ item.Name }));
                    }
                }
            }
        }
        // 2- Do Not Allow To Put Parent Of NS If This NS Is Attached To One Or More Contract
        if(!nsIdSet.isEmpty()) {
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                List<Contract__c> contracts = [SELECT Id, Supplier_Nego_Scope__c FROM Contract__c WHERE Supplier_Nego_Scope__c IN :nsIdSet];
                if(!contracts.isEmpty()) {
                    for(Contract__c item : contracts) {
                        nNSMap.get(item.Supplier_Nego_Scope__c).addError(System.Label.MSG_Cannot_Set_Parent_NegoScope);
                    }
                }
            }
        }
        // 3- update negoscope record Type when ns has parent
        // 4- assign the supplier currency ISO code into the NS currency ISO code
        if(!supplierIds.isEmpty()) {
            String[] supplierFields = new String[] {
                SObjectType.Supplier__c.fields.Id.Name,
                SObjectType.Supplier__c.fields.CurrencyIsoCode.Name
            };
            if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)) {
                Map<Id, Supplier__c> supplierCurrencyMap = new Map<Id, Supplier__c>([SELECT Id, CurrencyIsoCode FROM Supplier__c WHERE Id IN :supplierIds]);
                for (NegoScope__c item : nNSs) {
                    if(supplierCurrencyMap.containsKey(item.Supplier__c)) {
                        item.CurrencyIsoCode = supplierCurrencyMap.get(item.Supplier__c).CurrencyIsoCode;
                    }
                }
            }
        }
    }
    
    /**
     * Update Sub NS owner when parent NS owner change.
     * @param List<NegoScope__c>
     * On After Update.
     **/
    private static void updateSubNSOwner(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        Map<Id, Id> ownerIdMap = new Map<Id, Id>();
        for (NegoScope__c item : nNSs) {
            if (item.OwnerId != oNSMap.get(item.Id).OwnerId) {
                ownerIdMap.put(item.Id, item.OwnerId);
            }
        }
        if (!ownerIdMap.isEmpty()) {
            String[] negoscopeAcessFields = new String[] {
                SObjectType.NegoScope__c.fields.Id.Name,
                SObjectType.NegoScope__c.fields.NegoScopeParent__c.Name
            };
            if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoscopeAcessFields)) {
                List<NegoScope__c> subNSList = [SELECT Id, NegoScopeParent__c
                                                FROM NegoScope__c
                                                WHERE NegoScopeParent__c IN :ownerIdMap.keySet()];
                if (!subNSList.isEmpty()) {
                    for (NegoScope__c item : subNSList) {
                        if(ownerIdMap.containsKey(item.NegoScopeParent__c)) {
                            item.OwnerId = ownerIdMap.get(item.NegoScopeParent__c);
                        }
                    }
                    // check security on NegoScope__c update fields
                    String[] negoscopeUpdateFields = new String[] {
                        SObjectType.NegoScope__c.fields.OwnerId.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(NegoScope__c.SObjectType, negoscopeUpdateFields)) {
                        update subNSList;
                    }
                }
            }
        }
    }

    /**
     * @description 
     * Updates the OwnerId of NSHE__c, NSBRA__c, NSPG__c when the OwnerId of their parent NegoScope__c is changed.
     * Verifies user permissions before executing the batch.
     */
    public static void updateNSDetailOwnerId(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        List<Id> updatedNegoScopeIds = new List<Id>();
        for (NegoScope__c negoScope : nNSs) {
            if (oNSMap.containsKey(negoScope.Id) && oNSMap.get(negoScope.Id).OwnerId != negoScope.OwnerId) {
                updatedNegoScopeIds.add(negoScope.Id);
            }
        }
        try {
            if (!updatedNegoScopeIds.isEmpty()) {
                String startedFrom = Trg_NegoScope_Handler.class.getName();
                Map<String, Object> paramsNSHE = new Map<String, Object>{
                    'startedFrom' => startedFrom,
                    'recordsIds' => updatedNegoScopeIds,
                    'objectName' => SObjectType.NSHE__c.Name,
                    'relationName' => SObjectType.NSHE__c.fields.NegoScope__c.Name
                };
                NegoptimBatch.executeBatch('SetOwnerIdBatch', paramsNSHE, 200);
                Map<String, Object> paramsNSBRA = new Map<String, Object>{
                    'startedFrom' => startedFrom,
                    'recordsIds' => updatedNegoScopeIds,
                    'objectName' => SObjectType.NSBRA__c.Name,
                    'relationName' => SObjectType.NSBRA__c.fields.NegoScope__c.Name
                };
                NegoptimBatch.executeBatch('SetOwnerIdBatch', paramsNSBRA, 200);
                Map<String, Object> paramsNSPG = new Map<String, Object>{
                    'startedFrom' => startedFrom,
                    'recordsIds' => updatedNegoScopeIds,
                    'objectName' => SObjectType.NSPG__c.Name,
                    'relationName' => SObjectType.NSPG__c.fields.NegoScope__c.Name
                };
                NegoptimBatch.executeBatch('SetOwnerIdBatch', paramsNSPG, 200);
            }
        } catch (Exception e) {
            for (NegoScope__c item : nNSs) {
                item.addError(e.getMessage());
            }
        }
    }
    
    /**
     * Remove relations of NS with brands, PGs and HE
     * in cases of related ALL field is true
     * @param List<NegoScope__c>
     * On After Update
     **/
    private static void cleanUpRelatedList() {
        if (NegoptimHelper.checkDeletibility(NSBRA__c.SObjectType)) {
            DELETE[SELECT Id FROM NSBRA__c WHERE NegoScope__c = NULL];
        }
        if (NegoptimHelper.checkDeletibility(NSHE__c.SObjectType)) {
            DELETE[SELECT Id FROM NSHE__c WHERE NegoScope__c = NULL];
        }
        if (NegoptimHelper.checkDeletibility(NSBU__c.SObjectType)) {
            DELETE[SELECT Id FROM NSBU__c WHERE NegoScope__c = NULL];
        }
        if (NegoptimHelper.checkDeletibility(NSLink__c.SObjectType)) {
            DELETE[SELECT Id FROM NSLink__c WHERE NegoScopeMaster__c = NULL OR NegoScopeDetail__c = NULL];
        }
        if (NegoptimHelper.checkDeletibility(NSPG__c.SObjectType)) {
            Map<String, Object> paramsDelete = new Map<String, Object>{
                'startedFrom' => Trg_NegoScope_Handler.class.getName(),
                'objectName' => SObjectType.NSPG__c.Name,
                'filter' => 'NegoScope__c = NULL'
            };
            NegoptimBatch.executeBatch('MassDeleteBatch', paramsDelete, 200);
        }
    }
    
    /**
     * Set relations of NS with brands, PGs and HE
     * in cases of related ALL field is true
     * @param List<NegoScope__c>
     * On After Insert Or After Update
     **/
    private static void setAllRelations(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        /*Id rootId = NegoptimHelper.getHierarchyRootId('Product');
        List<NegoScope__c> negoScopeBrands = new List<NegoScope__c>();
        Set<Id> supIdBrands = new Set<Id>();
        Set<Id> NSIdHEs = new Set<Id>();
        Map<Id, List<Id>> supplierBrandsMap = new Map<Id, List<Id>>();
        Set<Id> negoScopeIds = new Set<Id>();
        // this variable checks if there are midifications on the product scope checkboxes,
        // while excluding the conditions considered in NegoScopeEditController.saveNegoScope+
        boolean isNSProductScopeChanged;
        boolean refreshNegoscopePGs;
        // Add all negoscope id and supplier id  in set.
        for (NegoScope__c item : nNSs) {
            if (item.Is_Managed_By_ExternalSource__c) {
                continue;
            }
            refreshNegoscopePGs = (oNSMap == null && item.IncludeAllProducts__c && item.IncludeAllHEs__c && item.IncludeAllBrands__c)
                || (oNSMap != null && oNSMap.containsKey(item.Id)
                && item.IncludeAllProducts__c && ((item.IncludeAllBrands__c && !oNSMap.get(item.Id).IncludeAllBrands__c && item.IncludeAllHEs__c)
                || (item.IncludeAllHEs__c && !oNSMap.get(item.Id).IncludeAllHEs__c && item.IncludeAllBrands__c)
                || !oNSMap.get(item.Id).IncludeAllProducts__c
                || item.BusinessUnit__c != oNSMap.get(item.Id).BusinessUnit__c));
            if (refreshNegoscopePGs) {
                negoScopeIds.add(item.Id);
            }
            if(item.IncludeAllBrands__c && (oNSMap == null || (oNSMap.containsKey(item.Id) && !oNSMap.get(item.Id).IncludeAllBrands__c))) {
                negoScopeBrands.add(item);
                supIdBrands.add(item.Supplier__c);
            }
            if(item.IncludeAllHEs__c == true && (oNSMap == null || (oNSMap.containsKey(item.Id) && oNSMap.get(item.Id).IncludeAllHEs__c == false))) {
                NSIdHEs.add(item.Id);
            }
        }
        // Attach brands to NS
        if(!supIdBrands.isEmpty()) {
            // check security on BRADistributor__c fields
            String[] supBrandDistFields = new String [] {
                SObjectType.BRADistributor__c.fields.Id.Name,
                SObjectType.BRADistributor__c.fields.Brand__c.Name,
                SObjectType.BRADistributor__c.fields.Supplier__c.Name
            };
            String[] supBrandFields = new String [] {
                SObjectType.Brand__c.fields.Name.Name,
                SObjectType.Brand__c.fields.Supplier__c.Name
            };
            if (NegoptimHelper.checkAccessibility(BRADistributor__c.SObjectType, supBrandDistFields)
                && NegoptimHelper.checkAccessibility(Brand__c.SObjectType, supBrandFields)
            && NegoptimHelper.checkAccessibility(User.SObjectType, new String[]{SObjectType.User.fields.Name.Name})
            && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, new String[]{SObjectType.Supplier__c.fields.Name.Name}))
            {
                // Fill map of supplier Id with its related brands Id
                for(BRADistributor__c item : [SELECT Name, Brand__r.Id, Brand__r.Name, Brand__r.Supplier__r.Name, Supplier__r.Name
                                                   FROM BRADistributor__c
                                                   WHERE BRADistributor__c.Supplier__c IN :supIdBrands
                                                   ORDER BY NAME ASC])
                {
                    // Group brand in a map by supplier id
                    if(supplierBrandsMap.containsKey(item.Supplier__c)) {
                        supplierBrandsMap.get(item.Supplier__c).add(item.Brand__r.Id);
                    } else {
                        supplierBrandsMap.put(item.Supplier__c, new List<Id>{item.Brand__r.Id});
                    }
                }
                // Loop on negoscope to get brand that belong to the supplier of this negoscope
                if(!supplierBrandsMap.isEmpty()) {
                    NSBRA__c NSBrand;
                    List<NSBRA__c> NSBrands = new List<NSBRA__c>();
                    for (NegoScope__c item : negoScopeBrands) {
                        if(supplierBrandsMap.containsKey(item.Supplier__c)) {
                            for (Id brandId : supplierBrandsMap.get(item.Supplier__c)) {
                                NSBrand = new NSBRA__c(Brand__c = brandId, NegoScope__c = item.Id);
                                NSBrands.add(NSBrand);
                            }
                        }
                    }
                    if(!NSBrands.isEmpty()) {
                        // check security on NSBRA__c fields
                        String[] NSBrandFields = new String[] {
                            SObjectType.NSBRA__c.fields.NegoScope__c.Name,
                            //SObjectType.NSBRA__c.fields.Supplier__c.Name,
                            SObjectType.NSBRA__c.fields.Brand__c.Name
                        };
                        if(NegoptimHelper.checkCreatibility(NSBRA__c.SObjectType, NSBrandFields)) {
                            insert NSBrands;
                        }
                    }
                }
            }
        }
        // Attach HE to NS
        if(!NSIdHEs.isEmpty()) {
            List<NSHE__c> NSElements = new List<NSHE__c>();
            // Get root element id and add it to the negoscope.
            for (Id id : NSIdHEs) {
                NSHE__c NSElement = new NSHE__c(Hierarchy__c = rootId, Choice__c = 'Include', NegoScope__c = id);
                NSElements.add(NSElement);
            }
            if(!NSElements.isEmpty()) {
                String[] supplierNSHEFields = new String[] {
                    SObjectType.NSHE__c.fields.Hierarchy__c.Name,
                    SObjectType.NSHE__c.fields.Choice__c.Name,
                    SObjectType.NSHE__c.fields.NegoScope__c.Name
                };
                if (NegoptimHelper.checkCreatibility(NSHE__c.SObjectType, supplierNSHEFields)) {
                    insert NSElements;
                }
            }
        }
        // Attach PGs to NS
        if (!system.isBatch() && !negoScopeIds.isEmpty()) {
            NegoptimBatch.executeBatch(new RefreshNegoScopePGBatch('Trg_NegoScope_Handler', new List<Id>(negoScopeIds), null, null, null), 2);
        }*/
    }
    /**
     * Set Global Location of NS
     * if status is Open and function matches
     * @param List<NegoScope__c>
     * On Before Insert
     **/
    private static void initGlobalLocation(List<NegoScope__c> nNSs) {
        //Id regularRTId = negoScopeRTIds.get('Regular');
        Id subNSRTId = negoScopeRTIds.get('SubNS');
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> parentNegoScopeIdSet = new Set<Id>();
        for (NegoScope__c item : nNSs) {
            if(item.Supplier__c != null) {
                supplierIdSet.add(item.Supplier__c);
            }
            if (item.RecordTypeId == subNSRTId) {
                parentNegoScopeIdSet.add(item.NegoscopeParent__c);
            }
        }
        // Consolidated query to retrieve all relevant GlobalLocation records in one call
        Map<String, GlobalLocation__c> globalLocationMap = new Map<String, GlobalLocation__c>();
        if(!supplierIdSet.isEmpty()) {
            for (GlobalLocation__c globalLocation : [SELECT Id, Supplier__c, Functions__c
                                                     FROM GlobalLocation__c
                                                     WHERE Functions__c INCLUDES ('Administrative', 'InvoiceTo', 'DeliverTo')
                                                     AND Status__c = 'Open'
                                                     AND Supplier__c IN :supplierIdSet
                                                     ORDER BY Supplier__c, CreatedDate])
            {
                if(globalLocation.Functions__c.contains('Administrative')) {
                    globalLocationMap.put(String.valueOf(globalLocation.Supplier__c) + 'Administrative', globalLocation);
                }
                if(globalLocation.Functions__c.contains('InvoiceTo')) {
                    globalLocationMap.put(String.valueOf(globalLocation.Supplier__c) + 'InvoiceTo', globalLocation);
                }
                if(globalLocation.Functions__c.contains('DeliverTo')) {
                    globalLocationMap.put(String.valueOf(globalLocation.Supplier__c) + 'DeliverTo', globalLocation);
                }
            }
        }
        Map<Id, NegoScope__c> parentNegoscopeMap = new Map<Id, NegoScope__c>();
        if(!parentNegoScopeIdSet.isEmpty()) {
            for (NegoScope__c item : [SELECT Id, GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c
                                      FROM NegoScope__c
                                      WHERE Id IN :parentNegoScopeIdSet])
            {
                parentNegoscopeMap.put(item.Id, item);
            }
        }
        for (NegoScope__c item : nNSs) {
            // update parent Negoscope
            if (item.NegoscopeParent__c == null) {
                String key = String.valueOf(item.Supplier__c) + 'Administrative';
                if (globalLocationMap.containsKey(key)) {
                    item.GlobalLocationAdministration__c = globalLocationMap.get(key).Id;
                }
                key = String.valueOf(item.Supplier__c) + 'InvoiceTo';
                if (globalLocationMap.containsKey(key)) {
                    item.GlobalLocationAccounting__c = globalLocationMap.get(String.valueOf(item.Supplier__c) + 'InvoiceTo').Id;
                }
                key = String.valueOf(item.Supplier__c) + 'DeliverTo';
                if (globalLocationMap.containsKey(key)) {
                    item.GlobalLocationDelivery__c = globalLocationMap.get(key).Id;
                }
            } else if(item.RecordTypeId == subNSRTId && parentNegoscopeMap.containsKey(item.NegoscopeParent__c)) {
                // update sub Negoscope
                NegoScope__c parentNegoscope = parentNegoscopeMap.get(item.NegoscopeParent__c);
                item.GlobalLocationAdministration__c = parentNegoscope.GlobalLocationAdministration__c;
                item.GlobalLocationAccounting__c = parentNegoscope.GlobalLocationAccounting__c;
                item.GlobalLocationDelivery__c = parentNegoscope.GlobalLocationDelivery__c;
            }
        }
    }
    
    /**
     * Set Global Location of Sub NS
     * in cases of any update on the parent global location
     * @param List<NegoScope__c>
     * On After Update
     **/
    private static void updateSubNSGlobalLocation(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        //Id regularRTId = negoScopeRTIds.get('Regular');
        Id subNSRTId = negoScopeRTIds.get('SubNS');
        Set<Id> parentNegoScopeIds = new Set<Id>();
        Map<Id, NegoScope__c> nNSMap = new Map<Id, NegoScope__c>(nNSs);
        for (NegoScope__c item : nNSs) {
            if(item.NegoscopeParent__c == null
                && (item.GlobalLocationAdministration__c != oNSMap.get(item.Id).GlobalLocationAdministration__c
                || item.GlobalLocationAccounting__c != oNSMap.get(item.Id).GlobalLocationAccounting__c
                || item.GlobalLocationDelivery__c != oNSMap.get(item.Id).GlobalLocationDelivery__c))
            {
                parentNegoScopeIds.add(item.Id);
            }
        }
        List<NegoScope__c> subNSListToUpdate = new List<NegoScope__c>();
        if(!parentNegoScopeIds.isEmpty()) {
            Map<Id, List<NegoScope__c>> parentToSubNegoscopesMap = new Map<Id, List<NegoScope__c>>();
            List<NegoScope__c> subNSList = [SELECT Id, NegoscopeParent__c, GlobalLocationAdministration__c, GlobalLocationAccounting__c, GlobalLocationDelivery__c
                                            FROM NegoScope__c
                                            WHERE RecordType.DeveloperName = 'SubNS'
                                            AND NegoscopeParent__c IN :parentNegoScopeIds];
            for (NegoScope__c subNs : subNSList) {
                NegoScope__c parentNS = nNSMap.get(subNs.NegoscopeParent__c);
                Boolean isUpdate = false;
                if (subNs.GlobalLocationAdministration__c == oNSMap.get(parentNS.Id).GlobalLocationAdministration__c) {
                    subNs.GlobalLocationAdministration__c = parentNS.GlobalLocationAdministration__c;
                    isUpdate = true;
                }
                if (subNs.GlobalLocationAccounting__c == oNSMap.get(parentNS.Id).GlobalLocationAccounting__c) {
                    subNs.GlobalLocationAccounting__c = parentNS.GlobalLocationAccounting__c;
                    isUpdate = true;
                }
                if (subNs.GlobalLocationDelivery__c == oNSMap.get(parentNS.Id).GlobalLocationDelivery__c) {
                    subNs.GlobalLocationDelivery__c = parentNS.GlobalLocationDelivery__c;
                    isUpdate = true;
                }
                if (isUpdate) {
                    subNSListToUpdate.add(subNs);
                }
            }
            if(!subNSListToUpdate.isEmpty()) {
                // check security on NegoScope__c fields
                String[] negoscopeUpdateFields = new String[] {
                    SObjectType.NegoScope__c.fields.GlobalLocationAdministration__c.Name,
                    SObjectType.NegoScope__c.fields.GlobalLocationAccounting__c.Name,
                    SObjectType.NegoScope__c.fields.GlobalLocationDelivery__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(NegoScope__c.SObjectType, negoscopeUpdateFields)) {
                    update subNSListToUpdate;
                }
            }
        }
    }
    
    /**
     * Set RT = NS Project when status is Validate
     * in cases of update the status to Validate
     * @param List<NegoScope__c>
     * On Before Update
     **/
    private static void updateRecordTypeOnValidation(List<NegoScope__c> nNSs, Map<Id, NegoScope__c> oNSMap) {
        NegoScopeSettings negoScopeSettings = NegoScopeSettings.loadNegoScopeSettings();
        Id nsProjectRT = negoScopeRTIds.get('NSProject');
        Id regularRT = negoScopeRTIds.get('Regular');
        if (negoScopeSettings.isNSProjectActive && negoScopeSettings.isNSProjectToRegularOnValidation) {
            for (NegoScope__c item : nNSs) {
                if (oNSMap != null
                    && oNSMap.containsKey(item.Id)
                    && item.RecordTypeId == nsProjectRT
                    && item.Status__c == 'Active'
                    && item.Status__c != oNSMap.get(item.Id).Status__c)
                {
                    item.RecordTypeId = regularRT;
                }
            }
        }
    }
}