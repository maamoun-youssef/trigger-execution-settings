/* (A) MAF1.6 Update Format list detail when store creation [After-Insert trigger.]
 * The current BUs are: Country or List.
 * Add BU list detail (as detail (child) record on the current BU, as parent record on Store OR Web Or DC).
 *
 ** (B) MAF1.5 Update Country list detail when store / Web / DC creation [on After-Update trigger]
 * The current BUs are: Store, Web or DC. If country origin in a store is related to a country,
 * then a detail record (entity or child) is inserted/updated in the list detail of the corresponding country,
 * and a parent record is inserted/updated in the list parent of the corresponding store.
 *
 ** (C) MAF15.5 Update Country detail list when status begin open [on After-Update trigger]
 * The current BU is: Country. When the current BU's status is open, so all children BUs should be related to the current BU.
 *
 ** (D) MAF21.2 List can't be close if active contract (before update) [on Before-Update trigger]
 * The current BUs are: Country or List. If the current BU is in relation with a contract, contract discount or invoice,
 * so the status of the current BU can not be closed.
 *
 ** (E) MAF16.2 Close Country will close all linked Stores / DC / Web / List
 * The current BU is: Country. When the current status is closed, so all related BU's status (store, dc, web, list)
 * will be also closed.
 *
 ** (F) MAF17.1 Country can change his allocation country zone if no contract as been defined to its country zone
 * The current BU is: Country. If a contract is related to a region BU and a country BU is related also to the same region BU,
 * then there is no possibility to move the region BU of the corresponding country BU.
 */

public with sharing class Trg_BusinessUnit_Handler {

    static final String STORE_RECORD_TYPE_NAME_CONST = 'Store';
	static final String WEB_RECORD_TYPE_NAME_CONST = 'Web';
	static final String WAREHOUSE_RECORD_TYPE_NAME_CONST = 'Warehouse';
	static final String COUNTRY_RECORD_TYPE_NAME_CONST = 'Country';
	static final String LIST_RECORD_TYPE_NAME_CONST = 'List';
    static final String ASSORTMENT_RECORD_TYPE_NAME_CONST = 'AssortmentCluster';
    static final String LEGALFORM_RECORD_TYPE_NAME_CONST = 'Legal';
    static final String BANNER_RECORD_TYPE_NAME_CONST = 'Banner';
    static final String OPEN_STATUS_VALUE_CONST = 'Open';
    static final String CLOSED_STATUS_VALUE_CONST = 'Closed';
    static final Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(BusinessUnit__c.SObjectType);

    // Action(s) on Before-Insert trigger.
    public static void OnBeforeInsert(List<BusinessUnit__c> listOfNewBU) {
        // Check if Country origin BU is Closed and set Legal if empty for countries and banners
        checkValidationRulesBeforeInsert(listOfNewBU);
    }
    // Action(s) on After-Insert trigger.
    public static void OnAfterInsert(List<BusinessUnit__c> listOfNewBU) {
        // (A) Add BU list detail on country BU AND/OR on list BU, and add BU list detail on store BU, web BU Or dc BU.
        addbuLink(listOfNewBU);
    }
    // Actions on After-Update trigger.
    public static void OnAfterUpdate(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        // (B) Modify list detail according to the country origin.
        modifybuLink(listOfNewBU, listOfOldBUMap);
        // (C) Add BU List detail when the country status is modified to "Open".
        addbuLinkWhenStatusEqualOpen(listOfNewBU, listOfOldBUMap);
        // (E) When the status is equal to "Closed" in a BU Country, all related BU (store, dc, web, list) will be also closed.
        closedBUEvent(listOfNewBU, listOfOldBUMap);
        // update assortment details based on BU (cluster/IsMasterBU) and updating SiteOfSalesNumber_N1__c OR WeightedDistributionManual_N1__c
        recalculateAssortmentDetails(listOfNewBU, listOfOldBUMap);
        checkBuConfigurationsMatchAfterUpdate(listOfNewBU, listOfOldBUMap);
    }
    // Actions on Before-Update trigger.
    public static void OnBeforeUpdate(List<BusinessUnit__c> listOfNewBU, Map<Id, BusinessUnit__c> listOfOldBUMap) {
        // (D) Cannot "Closed" Country BU or List BU if there is relation with the corresponding Country BU.
        // (F) Cannot detach a country zone origin (Region) in which a contract is related to it.
    }
    public static void OnBeforeInsertOrUpdate(List<BusinessUnit__c> listOfNewBU, Map<Id, BusinessUnit__c> listOfOldBUMap) {
        // Check if Country origin BU is Closed
        updateReferenceCountryBU(listOfNewBU, listOfOldBUMap);
        populateFields(listOfNewBU, listOfOldBUMap);
    }

    // Actions on After-Insert or Update trigger.
    public static void OnAfterInsertOrUpdate(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        // update assortment details based on BU (cluster/IsMasterBU) and updating SiteOfSalesNumber_N1__c OR WeightedDistributionManual_N1__c
        //bottomUpSOS(listOfNewBU, listOfOldBUMap);
    }

    private static void populateFields(List<BusinessUnit__c> newBUs, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        for (BusinessUnit__c orgaBU : newBUs) {
            if ((orgaBU.Id == null && orgaBU.ClosingDate__c != null)
                || (orgaBU.Id != null && orgaBU.ClosingDate__c != null && listOfOldBUMap.containsKey(orgaBU.Id) && orgaBU.ClosingDate__c != listOfOldBUMap.get(orgaBU.Id).ClosingDate__c))
            {
                orgaBU.Status__c = 'Closed';
            }
        }
    }

    // set country reference for Store and Legal BU
    private static void updateReferenceCountryBU(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        Set<String> refCountrySet = new Set<String>();
        Set<String> refCountryNameSet = new Set<String>();
        Map<String, String> refCountryCodeMap = new Map<String, String>();
        String recordTypeName;
        // Define and create a map to hold record type name with the related Orga BU.
        Set<BusinessUnit__c> orgaBUSet = new Set<BusinessUnit__c>();
        // Record type name and BU mapping.
        for (BusinessUnit__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            // REMOVE_FROM_PKG2
            /*if (currentBU.Country__c != null &&
                (recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == LEGALFORM_RECORD_TYPE_NAME_CONST)) {
                    refCountrySet.add(currentBU.Country__c);
                    orgaBUSet.add(currentBU);
                }*/
        }
        // fetch countries
        String[] countryListFields = new String[] {
            SObjectType.Country_List__c.fields.Name.Name,
            SObjectType.Country_List__c.fields.Country_Code__c.Name
    	};
    	if (NegoptimHelper.checkAccessibility(Country_List__c.SObjectType, countryListFields)) {
            for(Country_List__c country : [SELECT Name, Country_Code__c
                                           FROM Country_List__c
                                           WHERE Name LIKE :refCountrySet OR Country_Code__c LIKE :refCountrySet])
            {
                refCountryNameSet.add(country.Name.toUpperCase());
                refCountryCodeMap.put(country.Country_Code__c.toUpperCase(), country.Name);
            }
        }
        for(BusinessUnit__c currentBU : listOfNewBU) {
            // REMOVE_FROM_PKG2
            /*if(orgaBUSet.contains(currentBU) && (currentBU.Id == null || (currentBU.Id != null && (currentBU.Country__c != listOfOldBUMap.get(currentBU.Id).Country__c)))) {
                if(refCountryNameSet.contains(currentBU.Country__c.toUpperCase())) {
                    // Do nothings
                } else if(refCountryCodeMap.containsKey(currentBU.Country__c.toUpperCase())) {
                    currentBU.Country__c = refCountryCodeMap.get(currentBU.Country__c.toUpperCase());
                } else {
                    currentBU.Country__c.addError('Ref Country not exist.');
                }
            }*/
        }
    }

    // Check if Country origin BU is Closed
    private static void checkValidationRulesBeforeInsert(List<BusinessUnit__c> listOfNewBU) {
        // Define and create a map to hold record type name with the related Orga BU.
        Map<BusinessUnit__c, String> recordTypeNameMap = new Map<BusinessUnit__c, String>();
        // Define record type name variable.
        String recordTypeName;
        // Define Map country origin of the current BUs.
        Map<Id, List<BusinessUnit__c>> countryOriginMap = new Map<Id, List<BusinessUnit__c>>();
        // List of countries and banners to be filled with default legal form
        List<BusinessUnit__c> missingLegalFormRecords = new List<BusinessUnit__c>();
        for (BusinessUnit__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            recordTypeNameMap.put(currentBU, recordTypeName);
            if((recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                || recordTypeName == WEB_RECORD_TYPE_NAME_CONST) && currentBU.BusinessUnitCountryOrigin__c != NULL)
            {
                if(countryOriginMap.containsKey(currentBU.BusinessUnitCountryOrigin__c))
                    countryOriginMap.get(currentBU.BusinessUnitCountryOrigin__c).add(currentBU);
                else countryOriginMap.put(currentBU.BusinessUnitCountryOrigin__c, new List<BusinessUnit__c>{currentBU});
            }
            // get records with RT = countries and Banne
            if((recordTypeName == BANNER_RECORD_TYPE_NAME_CONST || recordTypeName == COUNTRY_RECORD_TYPE_NAME_CONST))
            {
                missingLegalFormRecords.add(currentBU);
            }
        }
        String[] buFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Id.Name,
            SObjectType.BusinessUnit__c.fields.Status__c.Name,
            SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
    	};
    	if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
            List<BusinessUnit__c> countryOriginList = [SELECT Id, Status__c, BusinessUnitCountryOrigin__c
                                                       FROM BusinessUnit__c
                                                       WHERE Id IN:countryOriginMap.keySet()
                                                       AND Status__c = :CLOSED_STATUS_VALUE_CONST];
            if(!countryOriginList.isEmpty()) {
                for(BusinessUnit__c countryBU : countryOriginList) {
                    for(BusinessUnit__c itemBU : countryOriginMap.get(countryBU.Id)) {
                        itemBU.BusinessUnitCountryOrigin__c.addError('Error: Connot insert '+ itemBU.Name +'. Country origin is closed.');
                    }
                }
            }
        }
    }

    // (A) Add BU list detail on country BU AND/OR on list BU, and add BU list detail on store BU, web BU Or dc BU.
    private static void addbuLink(List<BusinessUnit__c> listOfNewBU) {
        Map<Id, BusinessUnit__c> buMap = new Map<Id, BusinessUnit__c>();
        // Define entity variable.
        Boolean isLinkedToList = false, isLinkedToAssortment = false;
        // Define country origin set.
        Set<Id> countryOriginSet = new Set<Id>();
        // Define format origin set.
        Set<String> formatOriginSet = new Set<String>();
        // Define Assortment Strat set.
        Set<String> assortmentStratSet = new Set<String>();
        // Define a list of the List BU.
        List<BusinessUnit__c> listBUs;
        // Define a list of the BU List Details.
        List<BULink__c> buLinks = new List<BULink__c>();
        // Define record type name variable.
        String recordTypeName;
        for (BusinessUnit__c item : listOfNewBU) {
            buMap.put(item.Id, item);
            recordTypeName = recordTypeMap.get(item.recordtypeid);
			// Check if the current BU is a store.
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST) {
                // check if the store linked to assortment
                // AssortmentStrat__c REMOVE_FROM_PKG2
                /*if(item.AssortmentStrat__c != null) {
                    isLinkedToAssortment = true;
                    assortmentStratSet.add(item.AssortmentStrat__c);
                }*/
            }
            // Check if the current BU is a Store, Warehouse or Banner.
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                isLinkedToList = true;
                if(item.BusinessUnitCountryOrigin__c != null) {
                    countryOriginSet.add(item.BusinessUnitCountryOrigin__c);
                }
                if (item.Format__c != null) {
                    formatOriginSet.addAll(item.Format__c.split(';'));
                }
            }
            // Adding BU List Detail to the Country BU or Group BU.
            // When the current BU is a store, web, warehouse or banner, so we are concerned to the Country BU or Group BU
            // Check if there are existing Country BU for the same country origin
            if((item.BusinessUnitCountryOrigin__c != null || item.BusinessUnitGroup__c != null) &&
               (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST
                || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                || recordTypeName == WEB_RECORD_TYPE_NAME_CONST
                || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST
                || recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST))
            {
                if(item.BusinessUnitCountryOrigin__c != null) {
                    // Create BU list detail.
                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.BusinessUnitCountryOrigin__c, BusinessUnitDetail__c = item.Id);
                    // Fill the list of the BU list detail for insertion.
                    buLinks.add(buLink);
                }
                if(item.BusinessUnitGroup__c != null) {
                    // Create BU list detail.
                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.BusinessUnitGroup__c, BusinessUnitDetail__c = item.Id);
                    // Fill the list of the BU list detail for insertion.
                    buLinks.add(buLink);
                }
            }
        }
        // Adding to bu List with automatic update
        Set<String> buLinkKeys = new Set<String>();
        if (isLinkedToList) {
            // check security on access BusinessUnit__c fields
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitGroup__c.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.Format__c.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitRegion__c.Name,
                //SObjectType.BusinessUnit__c.fields.Reference_Country__c.Name, // Reference_Country__c REMOVE_FROM_PKG2
                //SObjectType.BusinessUnit__c.fields.Country__c.Name, // Country__c REMOVE_FROM_PKG2
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
            };
            // check security on access BULink__c
            String[] buLinkAccessFields = new String[] {
                SObjectType.BULink__c.fields.Id.Name,
                SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
            };
        }
        // Adding BU List Type Detail to the List BU.
        if (isLinkedToList && !countryOriginSet.isEmpty() && !formatOriginSet.isEmpty()) {
            Map<String, List<BusinessUnit__c>> buListMap = new Map<String, List<BusinessUnit__c>>();
            // check security on access BusinessUnit__c fields
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Format__c.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
                // Get all List BU for the same country origin and country format of the current Store BU.
                listBUs = Database.query(buildQuery(countryOriginSet, formatOriginSet));
            }
            if(listBUs != null && !listBUs.isEmpty()) {
                for(BusinessUnit__c item : listBUs) {
                    String key = item.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(item.Format__c);
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<BusinessUnit__c>{item});
                    } else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and country format.
                for (Id buId : buMap.keySet()) {
                    BusinessUnit__c currentBU = buMap.get(buId);
                    if(currentBU.BusinessUnitCountryOrigin__c != null && currentBU.Format__c != null) {
                        String key = currentBU.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(currentBU.Format__c);
                        if(buListMap.containsKey(key)) {
                            for(BusinessUnit__c item : buListMap.get(key)) {
                                // check if bu linked to automatic update List
                                if(buLinkKeys.contains(buId + '' + item.Id)) continue;
                                // Create BU list detail.
                                BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.Id, BusinessUnitDetail__c = buId);
                                // Fill the list of the BU list detail for insertion.
                                buLinks.add(buLink);
                            }
                        }
                    }
                }
            }
        }
        // Adding to bu List with automatic update
        Set<String> buListDetailKeys = new Set<String>();
        if (isLinkedToList) {
            // get all BU List with automatic update
            List<BusinessUnit__c> buListIncludeNewBUs = [SELECT Id, Name, t_BUAttributes__c,
                                                         (SELECT Id, BusinessUnitMaster__c FROM BULNKBusinessUnitDetail__r)
                                                         FROM BusinessUnit__c
                                                         WHERE RecordType.DeveloperName = 'List'
                                                         AND IncludeNewBUs__c = TRUE];
            for(BusinessUnit__c bu : buListIncludeNewBUs) {
                if(String.isBlank(bu.t_BUAttributes__c)) continue;
                String buJSON = Json.serialize(bu);
                BusinessUnitServices.BUAttributeWrapper filterAttrJSON = (BusinessUnitServices.BUAttributeWrapper)JSON.deserialize(bu.t_BUAttributes__c, BusinessUnitServices.BUAttributeWrapper.class);
                BusinessUnitServices.BUQueryConditionsWrapper buQueryConditions = BusinessUnitServices.buildBUQueryConditions(buJSON, null, Json.serialize(filterAttrJSON));
                List<String> conditions = buQueryConditions.respectFilterQueryConditions;
                String respectFilterQuery = BusinessUnitServices.buildQuery(new List<String> {'Id'}, null, conditions, null, buQueryConditions.filterAttributesConditions, buQueryConditions.filterAttributesLogic, '');
                Map<Id, BusinessUnit__c> filteredBUMap = new Map<Id, BusinessUnit__c>((List<BusinessUnit__c>) Database.query(respectFilterQuery));
                for (BusinessUnit__c item : listOfNewBU) {
                    if(filteredBUMap.containsKey(item.Id)) {
                        BULink__c buLink = new BULink__c(BusinessUnitMaster__c = bu.Id, BusinessUnitDetail__c = item.Id);
                        buLinks.add(buLink);
                    }
                }
            }
        }
        // Adding BU Assortment Type List to the List BU.
        // AssortmentStrat__c REMOVE_FROM_PKG2
        /*if (isLinkedToAssortment && countryOriginSet.size() > 0 && assortmentStratSet.size() > 0) {
            Map<String, List<BusinessUnit__c>> buListMap = new Map<String, List<BusinessUnit__c>>();
            // check security on access BusinessUnit__c fields
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                //SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name,// REMOVE_FROM_PKG2
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
                // Get all List BU linking all the store with Ass_cluster__c = S(i)
                // to the BU with same country_origin & where record_type = 'Assortment cluster' & Ass_cluster = 'S(i)'
                listBUs = [SELECT Id, BusinessUnitCountryOrigin__c, AssortmentStrat__c
                           FROM BusinessUnit__c WHERE BusinessUnitCountryOrigin__c IN :countryOriginSet
                           AND AssortmentStrat__c IN :assortmentStratSet
                           AND RecordType.DeveloperName = :ASSORTMENT_RECORD_TYPE_NAME_CONST];
            }
            if(listBUs != null && !listBUs.isEmpty()) {
                for(BusinessUnit__c item : listBUs) {
                    String key = item.BusinessUnitCountryOrigin__c + '' + item.AssortmentStrat__c;
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<BusinessUnit__c>{item});
                    } else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and assotment.
                for (Id buId : buMap.keySet()) {
                    BusinessUnit__c currentBU = buMap.get(buId);
                    if(currentBU.BusinessUnitCountryOrigin__c != null && currentBU.AssortmentStrat__c != null) {
                        String key = currentBU.BusinessUnitCountryOrigin__c + '' + currentBU.AssortmentStrat__c;
                        if(buListMap.containsKey(key)){
                            for(BusinessUnit__c item : buListMap.get(key)) {
                                // Create BU list detail.
                                BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.Id, BusinessUnitDetail__c = buId);
                                buLink.Ass_Clust__c = currentBU.AssortmentStrat__c;
                                // Fill the list of the BU list detail for insertion.
                                buLinks.add(buLink);
                            }
                        }
                    }
                }
            }
        }*/
        if (buLinks != null && !buLinks.isEmpty()) {
            // Check governor limits.
            if (buLinks.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Id buId : buMap.keySet()) {
                    BusinessUnit__c currentBU = buMap.get(buId);
                    currentBU.addError('You are attempting to insert the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            } else {
                try {
                    // check security on insert BULink__c
                    String[] buLinkFields = new String[] {
                        //SObjectType.BULink__c.fields.Ass_Clust__c.Name, // Ass_Clust__c REMOVE_FROM_PKG2
                        SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                        SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                    };
                    if(NegoptimHelper.checkCreatibility(BULink__c.SObjectType, buLinkFields)) {
                        insert buLinks;
                    }
                }
                catch(DmlException e) {
                    for (Id buId : buMap.keySet()) {
                        BusinessUnit__c currentBU = buMap.get(buId);
                        currentBU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }

    // (B) Modify list detail according to the country origin.
    private static void modifybuLink(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        Map<Id, BusinessUnit__c> buMap = new Map<Id, BusinessUnit__c>();
        Map<Id, BusinessUnit__c> oldBUMap = new Map<Id, BusinessUnit__c>();
        // Define entity variable.
        Boolean isDeletedLinkedCountry = false, isDeletedLinkedGroup = false, isDeletedLinkedList = false, isDeletedLinkedAssortment = false,
            isLinkedToList = false, isLinkedToAssortment = false;
        // Define country origin of the current BUs.
        Set<Id> countryOriginSet = new Set<Id>();
         // Define old country origin of the current BUs.
        Set<Id> oldCountryOriginSet = new Set<Id>();
         // Define old Group origin of the current BUs.
        Set<Id> oldGroupOriginSet = new Set<Id>();
        // Define format origin of the current BUs.
        Set<String> formatOriginSet = new Set<String>();
        // Define old format origin of the current BUs.
        Set<String> oldFormatOriginSet = new Set<String>();
        // Define Assortment Strat of the current Store BUs.
        Set<String> assortmentStratSet = new Set<String>();
        // Define old Assortment Strat of the current Store BUs.
        Set<String> oldAssortmentStratSet = new Set<String>();
        // Define a list of the List BU.
        Set<Id> updatedBUSet = new Set<Id>();
        List<BusinessUnit__c> listBUs;
        List<BULink__c> buLinks = new List<BULink__c>();
        List<BULink__c> BUListToDelete = new List<BULink__c>();
        // Define record type name variable.
        String recordTypeName;
        for (BusinessUnit__c item : listOfNewBU) {
            buMap.put(item.Id, item);
            oldBUMap.put(item.Id, listOfOldBUMap.get(item.Id));
            recordTypeName = recordTypeMap.get(item.recordtypeid);
            Id oldCountryOrigin = listOfOldBUMap.get(item.Id).BusinessUnitCountryOrigin__c;
            String oldFormatOrigin = listOfOldBUMap.get(item.Id).Format__c;
            //String oldAssortmentStrat = listOfOldBUMap.get(item.Id).AssortmentStrat__c;// AssortmentStrat__c REMOVE_FROM_PKG2
            // Check if the current BU is a Store.
            // AssortmentStrat__c REMOVE_FROM_PKG2
            /*if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST) {
                // When the current BU is a Store, so we are concerned to the List BU.
                if(item.AssortmentStrat__c != null && oldAssortmentStrat != null && item.AssortmentStrat__c != oldAssortmentStrat) {
                    oldAssortmentStratSet.add(oldAssortmentStrat);
                    assortmentStratSet.add(item.AssortmentStrat__c);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedAssortment = true;
                    isLinkedToAssortment = true;
                } else if(item.AssortmentStrat__c != null && oldAssortmentStrat == null) {
                    assortmentStratSet.add(item.AssortmentStrat__c);
                    isLinkedToAssortment = true;
                } else if(item.AssortmentStrat__c == null && oldAssortmentStrat != null) {
                    oldAssortmentStratSet.add(oldAssortmentStrat);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedAssortment = true;
                }
            }*/
            // Check if the current BU is a Warehouse.
            if (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                if(item.BusinessUnitCountryOrigin__c != null && oldCountryOrigin != null && item.BusinessUnitCountryOrigin__c != oldCountryOrigin) {
                    oldCountryOriginSet.add(oldCountryOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedList = true;
                    isDeletedLinkedCountry = true;
                    isLinkedToList = true;
                }
                if(listOfOldBUMap.get(item.Id).BusinessUnitGroup__c != null && item.BusinessUnitGroup__c != listOfOldBUMap.get(item.Id).BusinessUnitGroup__c) {
                    oldGroupOriginSet.add(listOfOldBUMap.get(item.Id).BusinessUnitGroup__c);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedGroup = true;
                }
                if (item.Format__c != null && !equalFormatOrigin(item.Format__c, oldFormatOrigin)) {
                    oldFormatOriginSet.add(oldFormatOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedList = true;
                    isLinkedToList = true;
                }
            }
            // Check if the current BU is a Web.
            if (recordTypeName == WEB_RECORD_TYPE_NAME_CONST) {
                if(item.BusinessUnitCountryOrigin__c != null && oldCountryOrigin != null && item.BusinessUnitCountryOrigin__c != oldCountryOrigin){
                    oldCountryOriginSet.add(oldCountryOrigin);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedCountry = true;
                }
                if(listOfOldBUMap.get(item.Id).BusinessUnitGroup__c != null && item.BusinessUnitGroup__c != listOfOldBUMap.get(item.Id).BusinessUnitGroup__c) {
                    oldGroupOriginSet.add(listOfOldBUMap.get(item.Id).BusinessUnitGroup__c);
                    updatedBUSet.add(item.Id);
                    isDeletedLinkedGroup = true;
                }
            }
            if(isLinkedToList || isLinkedToAssortment) {
                if(item.BusinessUnitCountryOrigin__c != null) {
                    countryOriginSet.add(item.BusinessUnitCountryOrigin__c);
                }
                if (item.Format__c != null) {
                    formatOriginSet.addAll(item.Format__c.split(';'));
                }
            }
            if (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                || recordTypeName == WEB_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST)
            {
                if(item.BusinessUnitCountryOrigin__c != null && item.BusinessUnitCountryOrigin__c != oldCountryOrigin) {
                    // Create BU list detail.
                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.BusinessUnitCountryOrigin__c, BusinessUnitDetail__c = item.Id);
                    // Fill the list of the BU list detail for insertion.
                    buLinks.add(buLink);
                }
                if(item.BusinessUnitGroup__c != null && item.BusinessUnitGroup__c != listOfOldBUMap.get(item.Id).BusinessUnitGroup__c) {
                    // Create BU list detail.
                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.BusinessUnitGroup__c, BusinessUnitDetail__c = item.Id);
                    // Fill the list of the BU list detail for insertion.
                    buLinks.add(buLink);
                }
            }
        }
        String[] buLinkFields = new String[] {
            SObjectType.BULink__c.fields.Id.Name,
            SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
        };
        if (isDeletedLinkedList && (!oldCountryOriginSet.isEmpty() || !oldFormatOriginSet.isEmpty())) {
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.Format__c.Name,
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
            };
            if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, buLinkFields)
               && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields))
            {
                List<BULink__c> oldListBUDetailToDelete = [SELECT Id FROM BULink__c
                                                                        WHERE BusinessUnitMaster__c IN (SELECT Id FROM BusinessUnit__c
                                                                                            WHERE (BusinessUnitCountryOrigin__c IN :oldCountryOriginSet OR Format__c IN :oldFormatOriginSet)
                                                                                            AND RecordType.DeveloperName =: LIST_RECORD_TYPE_NAME_CONST)
                                                                        AND BusinessUnitDetail__c IN :updatedBUSet];
                BUListToDelete.addAll(oldListBUDetailToDelete);
            }
        }
        if ((isDeletedLinkedCountry && !oldCountryOriginSet.isEmpty()) || (isDeletedLinkedGroup && !oldGroupOriginSet.isEmpty())) {
            if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, buLinkFields)) {
                List<BULink__c> oldListBUDetailToDelete = [SELECT Id FROM BULink__c
                                                                        WHERE (BusinessUnitMaster__c IN :oldCountryOriginSet OR BusinessUnitMaster__c IN :oldGroupOriginSet)
                                                                        AND BusinessUnitDetail__c IN :updatedBUSet];
                BUListToDelete.addAll(oldListBUDetailToDelete);
            }
        }
        if (isDeletedLinkedAssortment && (!oldCountryOriginSet.isEmpty() || !oldAssortmentStratSet.isEmpty())) {
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name
                //SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name // AssortmentStrat__c REMOVE_FROM_PKG2
            };
            if (NegoptimHelper.checkAccessibility(BULink__c.SObjectType, buLinkFields)
               && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields))
            {
                List<BULink__c> oldListBUDetailToDelete = [SELECT Id FROM BULink__c
                                                                        WHERE BusinessUnitMaster__c IN (SELECT Id FROM BusinessUnit__c
                                                                                            WHERE (BusinessUnitCountryOrigin__c IN :oldCountryOriginSet /*OR AssortmentStrat__c IN :oldAssortmentStratSet*/) // AssortmentStrat__c REMOVE_FROM_PKG2
                                                                                            AND RecordType.DeveloperName =: ASSORTMENT_RECORD_TYPE_NAME_CONST)
                                                                        AND BusinessUnitDetail__c IN :updatedBUSet];
                BUListToDelete.addAll(oldListBUDetailToDelete);
            }
        }
        if (BUListToDelete != null && !BUListToDelete.isEmpty()) {
            if (BUListToDelete.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (BusinessUnit__c currentBU: listOfNewBU) {
                    currentBU.addError('You are attempting to delete the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            } else {
                try {
                    if (NegoptimHelper.checkDeletibility(BULink__c.SObjectType)) {
                        delete BUListToDelete;
                    }
                } catch(DmlException e){
                    for (BusinessUnit__c currentBU: listOfNewBU) {
                        currentBU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
        // Adding BU List Detail to the List BU.
        if (isLinkedToList && !countryOriginSet.isEmpty() && !formatOriginSet.isEmpty()) {
            Map<String, List<BusinessUnit__c>> buListMap = new Map<String, List<BusinessUnit__c>>();
            // check security on access BusinessUnit__c fields
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Format__c.Name,
                    SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                    SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
                    };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
                // Get all List BU for the same country origin and country format of the current Store BU.
                listBUs = Database.query(buildQuery(countryOriginSet, formatOriginSet));
            }
            if(listBUs != null && !listBUs.isEmpty()) {
                for(BusinessUnit__c item : listBUs) {
                    String key = item.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(item.Format__c);
                    if(!buListMap.containsKey(key)) {
                        buListMap.put(key, new List<BusinessUnit__c>{item});
                    } else {
                        buListMap.get(key).add(item);
                    }
                }
                // Check if there are existing List BU for the same country origin and format origin.
                for (Id buId : buMap.keySet()) {
                    BusinessUnit__c currentBU = buMap.get(buId);
                    BusinessUnit__c oldBU = oldBUMap.get(buId);
                    if(currentBU.BusinessUnitCountryOrigin__c != null && currentBU.Format__c != null &&
                       (currentBU.BusinessUnitCountryOrigin__c != oldBU.BusinessUnitCountryOrigin__c || !equalFormatOrigin(currentBU.Format__c, oldBU.Format__c))
                       && (recordTypeName == WAREHOUSE_RECORD_TYPE_NAME_CONST || recordTypeName == STORE_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == WEB_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST
                                                       || recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST))
                    {
                        String key = currentBU.BusinessUnitCountryOrigin__c + '' + getSortedFormatOrigin(currentBU.Format__c);
                        if(buListMap.containsKey(key)) {
                            for(BusinessUnit__c item : buListMap.get(key)) {
                                if(item.Id != buId) {
                                    // Create BU list detail.
                                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.Id, BusinessUnitDetail__c = buId);
                                    // Fill the list of the BU list detail for insertion.
                                    buLinks.add(buLink);
                                }
                            }
                        }
                    }
                }
            }
        }
        // Adding BU Assortment Type List to the List BU.
        // AssortmentStrat__c REMOVE_FROM_PKG2
        /*if (isLinkedToAssortment && countryOriginSet.size() > 0 && assortmentStratSet.size() > 0) {
            Map<String, List<BusinessUnit__c>> buListMap = new Map<String, List<BusinessUnit__c>>();
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name
                SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name
            };
            if(NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
                // Get all List BU linking all the store with Ass_cluster__c = S(i)
                // to the BU with same country_origin & where record_type = 'Assortment cluster' & Ass_cluster = 'S(i)'
                listBUs = [SELECT Id, BusinessUnitCountryOrigin__c, AssortmentStrat__c
                           FROM BusinessUnit__c WHERE BusinessUnitCountryOrigin__c IN :countryOriginSet
                           AND AssortmentStrat__c IN :assortmentStratSet
                           AND RecordType.DeveloperName = :ASSORTMENT_RECORD_TYPE_NAME_CONST];
                if(listBUs != null && listBUs.size() > 0) {
                    for(BusinessUnit__c item : listBUs) {
                        String key = item.BusinessUnitCountryOrigin__c + '' + item.AssortmentStrat__c;
                        if(!buListMap.containsKey(key)) {
                            buListMap.put(key, new List<BusinessUnit__c>{item});
                        } else {
                            buListMap.get(key).add(item);
                        }
                    }
                    // Check if there are existing List BU for the same country origin and assortment.
                    for (Id buId : buMap.keySet()) {
                        BusinessUnit__c currentBU = buMap.get(buId);
                        BusinessUnit__c oldBU = oldBUMap.get(buId);
                        if(currentBU.BusinessUnitCountryOrigin__c != null && currentBU.AssortmentStrat__c != null &&
                           (currentBU.BusinessUnitCountryOrigin__c != oldBU.BusinessUnitCountryOrigin__c || currentBU.AssortmentStrat__c != oldBU.AssortmentStrat__c))
                        {
                            String key = currentBU.BusinessUnitCountryOrigin__c + '' + currentBU.AssortmentStrat__c;
                            if(buListMap.containsKey(key)) {
                                for(BusinessUnit__c item : buListMap.get(key)) {
                                    // Create BU list detail.
                                    BULink__c buLink = new BULink__c(BusinessUnitMaster__c = item.Id, BusinessUnitDetail__c = buId);
                                    // Fill the list of the BU list detail for insertion.
                                    buLinks.add(buLink);
                                }
                            }
                        }
                    }
                }
            }
        }*/
        if (buLinks != null && !buLinks.isEmpty()) {
            // Check governor limits.
            if (buLinks.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (Id buId : buMap.keySet()) {
                    BusinessUnit__c currentBU = buMap.get(buId);
                    currentBU.addError('You are attempting to insert the addresses of too many BU List Details at once. Please try again with fewer BU List Details.');
                }
            } else {
                try {
                    // Insert the BU list detail list records related to the List BU.
                    String[] buLinkInsertedFields = new String[] {
                        //SObjectType.BULink__c.fields.Ass_Clust__c.Name, // Ass_Clust__c REMOVE_FROM_PKG2
                        SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                        SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                    };
                    if(NegoptimHelper.checkCreatibility(BULink__c.SObjectType, buLinkInsertedFields)) {
                        insert buLinks;
                    }
                } catch(DmlException e) {
                    for (Id buId : buMap.keySet()) {
                        BusinessUnit__c currentBU = buMap.get(buId);
                        currentBU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }

    private static void checkBuConfigurationsMatchAfterUpdate(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> mapOfOldBU) {
        Set<Id> buLinkIdsToDelete = new Set<Id>();
        List<BULink__c> listBuLinksToAdd = new List<BULink__c>();
        Set<Id> buIdSet = new Set<Id>();
        String recordTypeName;
        for (BusinessUnit__c item : listOfNewBU) {
            recordTypeName = recordTypeMap.get(item.RecordTypeId);
            if (recordTypeName == STORE_RECORD_TYPE_NAME_CONST || recordTypeName == BANNER_RECORD_TYPE_NAME_CONST) {
                buIdSet.add(item.Id);
            }
        }
        if(!buIdSet.isEmpty()) {
            //retrieve Bu Lists that are connected to banners
            List<BULink__c> buDetailsResultsList = [SELECT Id, BusinessUnitDetail__c, BusinessUnitMaster__c, BusinessUnitMaster__r.t_BUAttributes__c
                                                    FROM BULink__c
                                                    WHERE BusinessUnitDetail__c IN :buIdSet
                                                    AND BusinessUnitMaster__r.RecordType.DeveloperName = 'List'
                                                    AND BusinessUnitMaster__r.IncludeNewBUs__c = TRUE];
            Map<String, Id> buLinksMap = new Map<String, Id>();
            if(!buDetailsResultsList.isEmpty()) {
                for (BULink__c item : buDetailsResultsList) {
                    String key = item.BusinessUnitMaster__c + '' + item.BusinessUnitDetail__c;
                    buLinksMap.put(key, item.Id);
                }
            }
            //retrieve connect BU Lists information
            // get all BU List with automatic update
            List<BusinessUnit__c> buListIncludeNewBUs = [SELECT Id, Name, t_BUAttributes__c,
                                                         (SELECT Id, BusinessUnitMaster__c FROM BULNKBusinessUnitDetail__r)
                                                         FROM BusinessUnit__c
                                                         WHERE RecordType.DeveloperName = 'List'
                                                         AND IncludeNewBUs__c = TRUE];
            
            for(BusinessUnit__c bu : buListIncludeNewBUs) {
                if(String.isBlank(bu.t_BUAttributes__c)) continue;
                String buJSON = Json.serialize(bu);
                BusinessUnitServices.BUAttributeWrapper filterAttrJSON = (BusinessUnitServices.BUAttributeWrapper)JSON.deserialize(bu.t_BUAttributes__c, BusinessUnitServices.BUAttributeWrapper.class);
                BusinessUnitServices.BUQueryConditionsWrapper buQueryConditions = BusinessUnitServices.buildBUQueryConditions(buJSON, null, Json.serialize(filterAttrJSON));
                List<String> conditions = buQueryConditions.respectFilterQueryConditions;
                String respectFilterQuery = BusinessUnitServices.buildQuery(new List<String> {'Id'}, null, conditions, null, buQueryConditions.filterAttributesConditions, buQueryConditions.filterAttributesLogic, '');
                Map<Id, BusinessUnit__c> filteredBUMap = new Map<Id, BusinessUnit__c>((List<BusinessUnit__c>) Database.query(respectFilterQuery));
                for (BusinessUnit__c item : listOfNewBU) {
                    String key = bu.Id + '' + item.Id;
                    if(filteredBUMap.containsKey(item.Id)) {
                        if(!buLinksMap.containsKey(key)) {
                            BULink__c buLink = new BULink__c(BusinessUnitMaster__c = bu.Id, BusinessUnitDetail__c = item.Id);
                            listBuLinksToAdd.add(buLink);
                        }
                    } else if (buLinksMap.containsKey(key)) {
                        buLinkIdsToDelete.add(buLinksMap.get(key));
                    }
                }
            }
        }
        if (!buLinkIdsToDelete.isEmpty()) {
            Delete [SELECT Id FROM BULink__c WHERE Id IN :buLinkIdsToDelete];
        }
        if (!listBuLinksToAdd.isEmpty()) {
            Insert listBuLinksToAdd; 
        }
    }
    // Add BU List Detail record in the current country BU when the country BU status is equal to "Open" (If the BU List Detail does not exist).
    private static void addbuLinkWhenStatusEqualOpen(List<BusinessUnit__c> listOfNewBU, Map<ID, BusinessUnit__c> listOfOldBUMap) {
        // Define a list of the List BU.
        List<BusinessUnit__c> listBUs;
        BULink__c buLink;
        List<BULink__c> buLinks = new List<BULink__c>();
        List<String> recordTypeList = new List<String>{STORE_RECORD_TYPE_NAME_CONST, WEB_RECORD_TYPE_NAME_CONST, WAREHOUSE_RECORD_TYPE_NAME_CONST, BANNER_RECORD_TYPE_NAME_CONST};
        Set<Id> BUIdSet = new Set<Id>();
        for (BusinessUnit__c item : listOfNewBU) {
            if (item.Status__c == OPEN_STATUS_VALUE_CONST && (item.Status__c != listOfOldBUMap.get(item.Id).Status__c)) {
                BUIdSet.add(item.Id);
            }
        }
        if(!BUIdSet.isEmpty()) {
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name,
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
            };
            String[] orgabuLinkFields = new String[] {
                SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)
                && NegoptimHelper.checkAccessibility(BULink__c.SObjectType, orgabuLinkFields))
            {
                for (BusinessUnit__c item : [SELECT Id, BusinessUnitCountryOrigin__c FROM BusinessUnit__c
                                        WHERE RecordType.DeveloperName IN :recordTypeList
                                        AND BusinessUnitCountryOrigin__c <> NULL
                                        AND BusinessUnitCountryOrigin__c IN :BUIdSet
                                        AND Id NOT IN (SELECT BusinessUnitDetail__c FROM BULink__c WHERE BusinessUnitMaster__c IN :BUIdSet)])
                {
                    buLink = new BULink__c(BusinessUnitMaster__c = item.BusinessUnitCountryOrigin__c, BusinessUnitDetail__c = item.Id);
                    buLinks.add(buLink);
                }
            }
        }
        // Check governor limits.
        if(!buLinks.isEmpty()) {
            if (buLinks.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                for (BusinessUnit__c orgaBU : listOfNewBU) {
                    orgaBU.addError('You are attempting to insert the addresses of too many BU children at once. Please try again with fewer BU children.');
                }
            } else {
                try {
                    String[] buLinkFields = new String[] {
                        SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
                        SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
                    };
                    if(NegoptimHelper.checkCreatibility(BULink__c.SObjectType, buLinkFields)){
                        insert buLinks;
                    }
                }
                catch(DmlException e){
                    for (BusinessUnit__c BU : listOfNewBU) {
                        BU.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }

    private static void closedBUEvent(List<BusinessUnit__c> listOfNewBU, Map<Id, BusinessUnit__c> listOfOldBUMap) {
         // (E) When the current status is closed, so all related BU's status (store, dc, web, list) will be also closed.
        // Define and create a map to hold record type name with the related Orga BU.
        // 1. Declaration
        // Map<BU Id, BusinessUnit__c(database)>
        Map<Id, BusinessUnit__c> closedCountryBUMap = new Map<Id, BusinessUnit__c>();
        Boolean isClosedCountryBU = False;
        List<String> recordTypeList = new List<String>{STORE_RECORD_TYPE_NAME_CONST, WEB_RECORD_TYPE_NAME_CONST, WAREHOUSE_RECORD_TYPE_NAME_CONST, LIST_RECORD_TYPE_NAME_CONST, BANNER_RECORD_TYPE_NAME_CONST};
        // Map<RecordTypeId, Developer_Name>
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(BusinessUnit__c.SObjectType);
        // Define record type name variable.
        String recordTypeName;
        // 2. Load Data
        // Mapping Record type name and BU mapping.
        for (BusinessUnit__c currentBU : listOfNewBU) {
            recordTypeName = recordTypeMap.get(currentBU.recordtypeid);
            // Check if the current BU is a country.
            if (recordTypeName == COUNTRY_RECORD_TYPE_NAME_CONST) {
                if (currentBU.Status__c != listOfOldBUMap.get(currentBU.Id).Status__c && currentBU.Status__c == CLOSED_STATUS_VALUE_CONST) {
                    isClosedCountryBU = true;
                    // Add the current BUs in the corresponding list.
                    closedCountryBUMap.put(currentBU.Id, currentBU);
                }
            }
        }
        if (isClosedCountryBU){
            // (F) When the Status is equal to "Closed" in a BU Country, all related BU (store, dc, web, list) will be also closed.
            // List of BU which are related to the current Country BU.
            String[] buFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Id.Name,
                SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.RecordTypeId.Name,
                SObjectType.BusinessUnit__c.fields.BusinessUnitCountryOrigin__c.Name
            };
            if (NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, buFields)) {
                List<BusinessUnit__c> listOfRelatedBU = [SELECT Id, Name FROM BusinessUnit__c
                                                    WHERE RecordType.DeveloperName IN :recordTypeList
                                                    AND BusinessUnitCountryOrigin__c <> NULL
                                                    AND BusinessUnitCountryOrigin__c IN :closedCountryBUMap.keySet()];
                if (listOfRelatedBU != NULL && listOfRelatedBU.size() > 0) {
                    for(BusinessUnit__c item : listOfRelatedBU) {
                        item.Status__c = CLOSED_STATUS_VALUE_CONST;
                    }
                    if (listOfRelatedBU.size() + Limits.getDMLRows() > Limits.getLimitDMLRows()) {
                        for (BusinessUnit__c orgaBU : listOfNewBU) {
                            orgaBU.addError('You are attempting to update the addresses of too many related BU at once. Please try again with fewer related BU.');
                        }
                    } else {
                        try {
                            // check security on BusinessUnit__c update fields
                            String[] updatedBUFields = new String[] {
                                SObjectType.BusinessUnit__c.fields.Status__c.Name
                             };
                            if(NegoptimHelper.checkUpdatibility(BusinessUnit__c.SObjectType, updatedBUFields)) {
                                update listOfRelatedBU;
                            }
                        } catch(DmlException e) {
                            for (BusinessUnit__c currentBU : listOfNewBU) {
                                currentBU.addError(e.getDmlMessage(0));
                            }
                        }
                    }
                }
            }
        }
    }

    // Re-calculate WD(ClientBased,MarketBased)/ND/L4L
    // On After Update
    private static void recalculateAssortmentDetails(List<BusinessUnit__c> newBUs, Map<Id, BusinessUnit__c> oldBUMap) {
        Set<Id> buTargetNSet = new Set<Id>();
        Set<Id> buTargetNL4LSet = new Set<Id>();
        Set<Id> buTargetN1Set = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
        String recordTypeName;
        for (BusinessUnit__c item : newBUs) {
            recordTypeName = recordTypeMap.get(item.RecordTypeId);
            if (recordTypeName == ASSORTMENT_RECORD_TYPE_NAME_CONST && item.BusinessUnitCountryOrigin__c != null) {
                if (item.SiteOfSalesNumber__c != oldBUMap.get(item.Id).SiteOfSalesNumber__c
                    || item.WeightedDistributionManual__c != oldBUMap.get(item.Id).WeightedDistributionManual__c)
                {
                    buTargetNSet.add(item.BusinessUnitCountryOrigin__c);
                }
                if (item.SiteOfSalesNumberN1__c != oldBUMap.get(item.Id).SiteOfSalesNumberN1__c
                   || item.WeightedDistributionManualN1__c != oldBUMap.get(item.Id).WeightedDistributionManualN1__c)
                {
                    buTargetNL4LSet.add(item.BusinessUnitCountryOrigin__c);
                    buTargetN1Set.add(item.BusinessUnitCountryOrigin__c);
                }
                if(item.IsMasterBU__c == true) buSourceSet.add(item.Id);
            }
        }
        if (!System.isBatch()) {
            if (!buTargetNSet.isEmpty() || !buSourceSet.isEmpty()) {
                Map<String, Object> paramsMapN = new Map<String, Object>{
                    'startedFrom' => Trg_BusinessUnit_Handler.class.getName(),
                    'assortmentBUIds' => null,
                    'assortmentDetailIds' => null,
                    'buSourceList' => new List<Id>(buSourceSet),
                    'buTargetList' => new List<Id>(buTargetNSet),
                    'year' => System.today().year(),
                    'L4LOnly' => false,
                    'inPreparationOnly' => false,
                    'recordTypes' => new List<String>{'Negotiation', 'Simulation', 'Target'}
                };
                NegoptimBatch.executeBatch('RecalculateAssortmentDetailsBatch', paramsMapN, 200);
            }
            if (!buTargetNL4LSet.isEmpty() || !buSourceSet.isEmpty()) {
                Map<String, Object> paramsMapNL4L = new Map<String, Object>{
                    'startedFrom' => Trg_BusinessUnit_Handler.class.getName(),
                    'assortmentBUIds' => null,
                    'assortmentDetailIds' => null,
                    'buSourceList' => new List<Id>(buSourceSet),
                    'buTargetList' => new List<Id>(buTargetNL4LSet),
                    'year' => System.today().year(),
                    'L4LOnly' => true,
                    'inPreparationOnly' => false,
                    'recordTypes' => new List<String>{'Negotiation', 'Simulation'}
                };
                NegoptimBatch.executeBatch('RecalculateAssortmentDetailsBatch', paramsMapNL4L, 200);
            }
            if (!buTargetN1Set.isEmpty() || !buSourceSet.isEmpty()) {
                Map<String, Object> paramsMapN1 = new Map<String, Object>{
                    'startedFrom' => Trg_BusinessUnit_Handler.class.getName(),
                    'assortmentBUIds' => null,
                    'assortmentDetailIds' => null,
                    'buSourceList' => new List<Id>(buSourceSet),
                    'buTargetList' => new List<Id>(buTargetN1Set),
                    'year' => System.today().year() + 1,
                    'L4LOnly' => false,
                    'inPreparationOnly' => false,
                    'recordTypes' => new List<String>{'Negotiation', 'Simulation', 'Target'}
                };
                NegoptimBatch.executeBatch('RecalculateAssortmentDetailsBatch', paramsMapN1, 200);
            }
        }
    }

    // Re-calculate WD(ClientBased,MarketBased)/ND/L4L
    // On After Update
    private static void bottomUpSOS(List<BusinessUnit__c> newBUs, Map<Id, BusinessUnit__c> oldBUMap) {
        Map<Id, List<BusinessUnit__c>> countryClustersMap = new Map<Id, List<BusinessUnit__c>>();
        Set<String> formatOriginSet = new Set<String>();
        Map<String, Id> buRTs = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
        Id clusterRTId = buRTs.get('AssortmentCluster');
        for (BusinessUnit__c item : newBUs) {
            if (item.RecordTypeId == clusterRTId && item.BusinessUnitCountryOrigin__c != null
                && ((oldBUMap == null && (item.SiteOfSalesNumber__c != null || item.SiteOfSalesNumberN1__c != null))
                    || (oldBUMap != null && oldBUMap.containsKey(item.Id) && (item.SiteOfSalesNumber__c != oldBUMap.get(item.Id).SiteOfSalesNumber__c
                                                                              || item.SiteOfSalesNumberN1__c != oldBUMap.get(item.Id).SiteOfSalesNumberN1__c
                                                                              || item.Status__c != oldBUMap.get(item.Id).Status__c))))
            {
                if (item.Format__c != null) {
                    formatOriginSet.addAll(item.Format__c.split(';'));
                }
                if (!countryClustersMap.containsKey(item.BusinessUnitCountryOrigin__c)) {
                    countryClustersMap.put(item.BusinessUnitCountryOrigin__c, new List<BusinessUnit__c>());
                }
                countryClustersMap.get(item.BusinessUnitCountryOrigin__c).add(item);
            }
        }
        if (countryClustersMap != null && !countryClustersMap.KeySet().isEmpty()) {
            List<BusinessUnit__c> BUsToUpdate = new List<BusinessUnit__c>();
            List<Aggregateresult> aggResults = [SELECT BusinessUnitCountryOrigin__c BusinessUnitCountryOrigin__c,
                                                SUM(SiteOfSalesNumber__c) SiteOfSalesNumber__c,
                                                SUM(SiteOfSalesNumberN1__c) SiteOfSalesNumberN1__c
                                                FROM BusinessUnit__c
                                                WHERE Status__c = 'Open'
                                                AND RecordTypeId = :clusterRTId
                                                AND AssortmentStrat__c LIKE 'Strat%'
                                                AND BusinessUnitCountryOrigin__c IN :countryClustersMap.KeySet()
                                                GROUP BY BusinessUnitCountryOrigin__c];
            for (Aggregateresult result : aggResults) {
                Id countryId = (Id) result.get('BusinessUnitCountryOrigin__c');
                Decimal SOSn = (Decimal) result.get('SiteOfSalesNumber__c');
                Decimal SOSn1 = (Decimal) result.get('SiteOfSalesNumberN1__c');
                BUsToUpdate.add(new BusinessUnit__c(Id = countryId, SiteOfSalesNumber__c = SOSn, SiteOfSalesNumberN1__c = SOSn1));
            }
            if (BUsToUpdate != null && !BUsToUpdate.isEmpty()) {
                // check security on update Assortment__c fields
                String[] BUUpdateFields = new String[] {
                    SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
                    SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(BusinessUnit__c.SObjectType, BUUpdateFields)) {
                    List<Database.SaveResult> results = Database.update(BUsToUpdate, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        BusinessUnit__c countryBU = BUsToUpdate.get(i);
                        if (!result.isSuccess()) {
                            Database.Error[] errors = result.getErrors();
                            String errorMessage = '';
                            for (Database.Error err : errors) {
                                errorMessage += err.getMessage();
                            }
                            for (BusinessUnit__c item : countryClustersMap.get(countryBU.Id)) {
                                item.addError(errorMessage);
                            }
                        }
                    }
                }
            }
            if (formatOriginSet != null && !formatOriginSet.isEmpty()) {
                
                List<String> FormatConditions = new List<String>();
                for (String format : formatOriginSet) {
                    FormatConditions.add('Format__c INCLUDES (\'' + format + '\')');
                }
                
                String queryBannerBUs = 'SELECT Format__c,';
                queryBannerBUs += ' SiteOfSalesNumber__c, SiteOfSalesNumberN1__c';
                queryBannerBUs += ' FROM BusinessUnit__c';
                queryBannerBUs += ' WHERE Status__c = \'Open\'';
                queryBannerBUs += ' AND RecordType.DeveloperName = \'Banner\'';
                queryBannerBUs += ' AND (' + String.join(FormatConditions, ' OR ') + ')';
                List<BusinessUnit__c> bannerList = Database.query(queryBannerBUs);
                Map<String, Map<String, Decimal>> formatSOSValuesMap = new Map<String, Map<String, Decimal>>();
                for (BusinessUnit__c banner : bannerList) {
                    Decimal SOSn = banner.SiteOfSalesNumber__c != null ? banner.SiteOfSalesNumber__c : 0;
                    Decimal SOSn1 = banner.SiteOfSalesNumberN1__c != null ? banner.SiteOfSalesNumberN1__c : 0;
                    for (String splittedFormat : banner.Format__c.split(';')) {
                        if (!formatSOSValuesMap.containsKey(splittedFormat)) {
                            formatSOSValuesMap.put(splittedFormat, new Map<String, Decimal>());
                        }
                        if (!formatSOSValuesMap.get(splittedFormat).containsKey('SOSn')) {
                            formatSOSValuesMap.get(splittedFormat).put('SOSn', 0);
                        }
                        if (!formatSOSValuesMap.get(splittedFormat).containsKey('SOSn1')) {
                            formatSOSValuesMap.get(splittedFormat).put('SOSn1', 0);
                        }
                        formatSOSValuesMap.get(splittedFormat).put('SOSn', formatSOSValuesMap.get(splittedFormat).get('SOSn') + SOSn);
                        formatSOSValuesMap.get(splittedFormat).put('SOSn1', formatSOSValuesMap.get(splittedFormat).get('SOSn1') + SOSn1);
                    }
                }
                // clear list of BU
                BUsToUpdate.clear();
                String queryChannelBUs = 'SELECT Id, Name, Format__c, SiteOfSalesNumber__c, SiteOfSalesNumberN1__c';
                queryChannelBUs += ' FROM BusinessUnit__c';
                queryChannelBUs += ' WHERE RecordType.DeveloperName = \'Channel\'';
                if (FormatConditions != null && !FormatConditions.isEmpty()) {
                    queryChannelBUs += ' AND (' + String.join(FormatConditions, ' OR ') + ')';
                }
                List<BusinessUnit__c> channelBUs = Database.query(queryChannelBUs);
                for (BusinessUnit__c channel : channelBUs) {
                    Decimal SOSn = 0;
                    Decimal SOSn1 = 0;
                    for (String splittedFormat : channel.Format__c.split(';')) {
                        if (formatSOSValuesMap.containsKey(splittedFormat)) {
                            SOSn += formatSOSValuesMap.get(splittedFormat).get('SOSn');
                            SOSn1 += formatSOSValuesMap.get(splittedFormat).get('SOSn1');
                        }
                    }
                    BUsToUpdate.add(new BusinessUnit__c(Id = channel.Id, SiteOfSalesNumber__c = SOSn, SiteOfSalesNumberN1__c = SOSn1));
                }
                if (BUsToUpdate != null && !BUsToUpdate.isEmpty()) {
                    // check security on update Assortment__c fields
                    String[] BUUpdateFields = new String[] {
                        SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
                        SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(BusinessUnit__c.SObjectType, BUUpdateFields)) {
                        List<Database.SaveResult> results = Database.update(BUsToUpdate, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            BusinessUnit__c countryBU = BUsToUpdate.get(i);
                            if (!result.isSuccess()) {
                                Database.Error[] errors = result.getErrors();
                                String errorMessage = '';
                                for (Database.Error err : errors) {
                                    errorMessage += err.getMessage();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Check if 2 Format Origin are equals
    private static Boolean equalFormatOrigin(String newFormatOrigin, String oldFormatOrigin) {
        if (newFormatOrigin == null || oldFormatOrigin == null)
            return false;
        Set<String> newFormatOriginSet = new Set<String>(newFormatOrigin.split(';'));
        Set<String> oldFormatOriginSet = new Set<String>(oldFormatOrigin.split(';'));
        return newFormatOriginSet.containsAll(oldFormatOriginSet) && oldFormatOriginSet.containsAll(newFormatOriginSet);
    }

    private static String buildQuery(Set<Id> countriesSet, Set<String> formatOriginsSet) {
        List<Id> countriesList = new List<Id>(countriesSet);
        List<String> formatOriginsList = new List<String>(formatOriginsSet);
        String query = 'SELECT Id, BusinessUnitCountryOrigin__c, Format__c';
        query += ' FROM BusinessUnit__c';
        query += ' WHERE BusinessUnitCountryOrigin__c IN (\'' + String.join(countriesList, '\',\'')+ '\')';
        query += ' AND Format__c INCLUDES (\'' + String.join(formatOriginsList, '\',\'')+ '\')';
        query += ' AND RecordType.DeveloperName = \'' + LIST_RECORD_TYPE_NAME_CONST + '\'';
        return query;
    }

    private static String getSortedFormatOrigin(String formatOrigin) {
        if (formatOrigin == null) return null;
        List<String> sortedList = formatOrigin.split(';');
        sortedList.sort();
        return String.join(sortedList, ';');
    }

    private class BUListConfiguration {
        List<String> groupOptions;
        List<String> typeOptions;
        List<String> entityOptions;
        List<String> zoneCountryOptions;
        List<String> groupCountryOptions;
        List<String> countryOptions;
    }
}