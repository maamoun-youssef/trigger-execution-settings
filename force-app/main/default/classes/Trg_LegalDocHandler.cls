/**
 * @author ULiT
 * @date 03-06-2026
 * @description Handler class for LegalDocClause__c trigger
 */
public with sharing class Trg_LegalDocHandler {
    private static Map<String, Id> legalDocClauseRTIds = NegoptimHelper.getObjectRecordTypeMapIds(LegalDocClause__c.SObjectType);
    
    public static void onAfterInsert(List<LegalDoc__c> nLegalDocList) {
        cloneLegalDocWithClauses(nLegalDocList);
    }
    
    public static void onAfterInsertOrUpdate(List<LegalDoc__c> nLegalDocList, Map<Id, LegalDoc__c> oLegalDocMap) {
        setLegalDocName(nLegalDocList, oLegalDocMap);
    }

    public static void onAfterDelete(Map<Id, LegalDoc__c> oLegalDocMap) {
        cleanUpRelatedList(oLegalDocMap);
    }
    
    public static void cloneLegalDocWithClauses(List<LegalDoc__c> nLegalDocList) {
        Id regularRTId = legalDocClauseRTIds.get('Regular');
        Id partnerRTId = legalDocClauseRTIds.get('Partner');
        Set<Id> sourceLegalDocIdSet = new Set<Id>();
        Map<Id, List<LegalDoc__c>> sourceLegalDocsMap = new Map<Id, List<LegalDoc__c>>();
        Map<Id, LegalDoc__c> clonedLegalDocMap = new Map<Id, LegalDoc__c>();
        List<LegalDoc__c> sourceLegalDocsToUpdate = new List<LegalDoc__c>();
        List<LegalDocClause__c> legalDocClauseToInsert = new List<LegalDocClause__c>();
        for (LegalDoc__c item : nLegalDocList) {
            clonedLegalDocMap.put(item.Id, item);
            if (item.IsClone()) {
                sourceLegalDocIdSet.add(item.getCloneSourceId());
                if (!sourceLegalDocsMap.containsKey(item.getCloneSourceId())) {
                    sourceLegalDocsMap.put(item.getCloneSourceId(), new List<LegalDoc__c>());
                }
                sourceLegalDocsMap.get(item.getCloneSourceId()).add(item);
            }
        }
        if (!sourceLegalDocsMap.isEmpty()) {
            List<LegalDocClause__c> sourceLegalDocClauses = [SELECT Id, LegalDoc__c, LegalDoc__r.Year__c, LegalDocClause__c, Supplier__c, ClauseL1__c, ClauseL2__c, 
                                                             DisplayOrder__c, IsNegotiable__c, LegalDocClauseP1__c, Clause__c, 
                                                             ClauseType__c, UpdateOrigin__c, Updatedby__c, Status__c, 
                                                             LegalStatus__c, PartnerStatus__c, BusinessStatus__c, BusinessOwners__c,
                                                             Version__c, LegalComment__c, LegalNote__c, PartnerComment__c, BusinessOwnerComment__c
                                                             FROM LegalDocClause__c 
                                                             WHERE LegalDoc__c IN :sourceLegalDocIdSet
                                                             AND RecordTypeId = :regularRTId
                                                             AND Version__c = 0];
            for (Id legalDocId : sourceLegalDocsMap.keySet()) {
                for (LegalDoc__c sourceLegalDoc : sourceLegalDocsMap.get(legalDocId)) {
                    LegalDoc__c updatedLegalDoc = new LegalDoc__c(Id = sourceLegalDoc.Id);
                    if (sourceLegalDoc.Supplier__c != null) {
                        updatedLegalDoc.DateSentToSupplier__c = System.now();
                        updatedLegalDoc.LegalDoc__c = legalDocId;
                    } else {
                        updatedLegalDoc.LegalDoc__c = null;
                    }
                    sourceLegalDocsToUpdate.add(updatedLegalDoc);
                }
            }
            if (!sourceLegalDocsToUpdate.isEmpty()) {
                update sourceLegalDocsToUpdate;
            }
            if (!sourceLegalDocClauses.isEmpty()) {
                for (LegalDocClause__c item : sourceLegalDocClauses) {
                    if (!sourceLegalDocsMap.containsKey(item.LegalDoc__c)) continue;
                    for (LegalDoc__c clonedLegalDoc : sourceLegalDocsMap.get(item.LegalDoc__c)) {
                        LegalDocClause__c newLegalDocClause = item.clone(false, true, false, false);
                        //newLegalDocClause.Id = null;
                        newLegalDocClause.LegalDoc__c = clonedLegalDoc.Id;
                        newLegalDocClause.LegalDocClause__c = item.Id;
                        newLegalDocClause.LegalDocClauseP1__c = item.Id;
                        newLegalDocClause.Supplier__c = clonedLegalDoc.Supplier__c;
                        newLegalDocClause.UpdateOrigin__c = null;
                        if(clonedLegalDoc.Supplier__c != null) {
                            newLegalDocClause.Status__c = item.IsNegotiable__c ? 'legal publishing' : null;
                            newLegalDocClause.LegalStatus__c = 'Validated';
                            newLegalDocClause.PartnerStatus__c = item.IsNegotiable__c ? 'Open' : 'Validated';
                            newLegalDocClause.BusinessStatus__c = item.IsNegotiable__c ? 'Open' : 'Validated';
                            newLegalDocClause.RecordTypeId = partnerRTId;
                        }
                        newLegalDocClause.Version__c = 0;
                        newLegalDocClause.BusinessOwners__c = item.BusinessOwners__c;
                        newLegalDocClause.Updatedby__c = UserInfo.getUserId();
                        legalDocClauseToInsert.add(newLegalDocClause);
                    }
                }
                if (!legalDocClauseToInsert.isEmpty()) {
                    Set<Id> supplierIdSet = new Set<Id>();
                    Map<Id, GlobalLocation__c> globalLocationsMap = new Map<Id, GlobalLocation__c>();
                    Map<Id, Contact> contactMap = new Map<Id, Contact>();
                    for (LegalDocClause__c item : legalDocClauseToInsert) {
                        if (item.Supplier__c != null && String.isNotBlank(item.Clause__c)) {
                            supplierIdSet.add(item.Supplier__c);
                        }
                    }
                    if (!supplierIdSet.isEmpty()) {
                        Map<Id, Supplier__c> supplierMap = new Map<Id, Supplier__c>([SELECT Id, Signatory__r.FirstName, Signatory__r.LastName, Signatory__r.Title
                                                                                     FROM Supplier__c
                                                                                     WHERE Id IN :supplierIdSet]);
                        List<GlobalLocation__c> globalLocations = [SELECT CompanyName__c, Identifier1__c, Identifier2__c, Identifier3__c, Identifier4__c, LegalForm__c,
                                                                   Address1__c, Address2__c, PostalCode__c, City__c, Country__r.Name,  Supplier__c 
                                                                   FROM GlobalLocation__c
                                                                   WHERE Supplier__c IN :supplierIdSet AND Functions__c INCLUDES ('Administrative') ORDER BY CreatedDate DESC LIMIT 1];
                        List<Contact> contactList = [SELECT FirstName, LastName, Title, Supplier__c
                                                     FROM Contact
                                                     WHERE Supplier__c IN :supplierIdSet
                                                     AND MainFrameworkSignatory__c = TRUE];
                        for (GlobalLocation__c item : globalLocations) {
                            globalLocationsMap.put(item.Supplier__c, item);
                        }
                        for (Contact item : contactList) {
                            contactMap.put(item.Supplier__c, item);
                        }
                        for (LegalDocClause__c item : legalDocClauseToInsert) {
                            if (item.Supplier__c != null && String.isNotBlank(item.Clause__c)) {
                                GlobalLocation__c globalLocation = globalLocationsMap.containsKey(item.Supplier__c) ? globalLocationsMap.get(item.Supplier__c) : null;
                                Contact contact = contactMap.containsKey(item.Supplier__c) ? contactMap.get(item.Supplier__c) : null;
                                Supplier__c supplier = supplierMap.containsKey(item.Supplier__c) ? supplierMap.get(item.Supplier__c) : null;
                                LegalDoc__c clauseLegalDoc = clonedLegalDocMap.get(item.LegalDoc__c);
                                item.Clause__c = replaceMergeFields(item.Clause__c, globalLocation, contact, supplier, clauseLegalDoc);
                            }
                        }
                    }
                    insert legalDocClauseToInsert;
                }
            }
        }
    }
    
    public static String replaceMergeFields(String clauseContent, GlobalLocation__c globalLocation, Contact cont, Supplier__c supplier, LegalDoc__c legalDoc) {
        List<LegalClauseManagerCtrl.ObjectWrapper> mergeObjects = LegalClauseManagerCtrl.getMergeObjects();
        String updatedClause = clauseContent;
        for (LegalClauseManagerCtrl.ObjectWrapper objWrap : mergeObjects) {
            SObject record;
            if (objWrap.fieldValue == SObjectType.GlobalLocation__c.Name) record = globalLocation;
            else if (objWrap.fieldValue == SObjectType.Contact.Name) record = cont;
            else if (objWrap.fieldValue == SObjectType.Supplier__c.Name) record = supplier;
            else if (objWrap.fieldValue == SObjectType.LegalDoc__c.Name) record = legalDoc;
            else continue;
            for (LegalClauseManagerCtrl.FieldWrapper fWrap : objWrap.wFieldWrapperList) {
                Integer firstDotIndex = fWrap.fieldValue.indexOf('.');
                String fieldPath = firstDotIndex != -1 ? fWrap.fieldValue.substring(firstDotIndex + 1) : fWrap.fieldValue;
                String value = getFieldValue(record, fieldPath);
                String selectedField = '{!' + objWrap.fieldValue + '.' + fieldPath + '}';
                String htmlValue = '<a href="#MergeField' + selectedField + '" data-field="${'+ selectedField + '}" > ' + value + '</a>';
                updatedClause = updatedClause.replace('{!' + objWrap.fieldValue + '.' + fieldPath + '}', htmlValue);
            }
        }
        // updatedClause = updatedClause.replace('{!TMP_LegalDoc__r.Year__c}', year != null ? String.valueOf(year) : '');
        return updatedClause;
    }
    
     public static String getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) return '';
        try {
            Object val;
            if (fieldPath.contains('.')) {
                String[] parts = fieldPath.split('\\.');
                String relationshipName = parts[0];
                String fieldName = parts[1];
                SObject rel = record.getSObject(relationshipName);
                if (rel != null) {
                    val = rel.get(fieldName);
                }
            } else {
                val = record.get(fieldPath);
            }
            if (val == null) return '';
            if (val instanceof Double || val instanceof Decimal) {
                Decimal decValue = (Decimal) val;
                if (decValue == decValue.intValue()) {
                    return String.valueOf(decValue.intValue());
                }
            }
            return String.valueOf(val);
        } catch (Exception e) {
            System.debug('>getFieldValue ERROR - fieldPath: ' + fieldPath + ', Error: ' + e.getMessage() + ', StackTrace: ' + e.getStackTraceString());
            return '';
        }
    }
    
    public static void setLegalDocName(List<LegalDoc__c> nLegalDocList, Map<Id, LegalDoc__c> oLegalDocMap) {
        Id regularRTId = legalDocClauseRTIds.get('Regular');
        Id partnerRTId = legalDocClauseRTIds.get('Partner');
        List<LegalDoc__c> legalDocList = new List<LegalDoc__c>();
        List<LegalDoc__c> legalDocListToUpdate = new List<LegalDoc__c>();
        Map<Id, Id> legalDocSuppliersMap = new Map<Id, Id>();
        Map<Id, Supplier__c> suppliersMap = new Map<Id, Supplier__c>();
        for (LegalDoc__c item : nLegalDocList) {
            if (oLegalDocMap == null || (oLegalDocMap.containsKey(item.Id) && item.Name != oLegalDocMap.get(item.Id).Name)) {
                if (item.Supplier__c != null) {
                    legalDocSuppliersMap.put(item.Id, item.Supplier__c);
                }
                legalDocList.add(item);
            }
        }
        if (!legalDocSuppliersMap.isEmpty()){
            suppliersMap = new Map<Id, Supplier__c>([SELECT Id, Name, Code__c
                                                     FROM Supplier__c 
                                                     WHERE Id IN :legalDocSuppliersMap.values()]);
        }
        String name = '';
        if(!legalDocList.isEmpty()) {
            for (LegalDoc__c item : legalDocList) {
                name = item.Name != null ? item.Name.split(' - ')[0] : '';
                if (legalDocSuppliersMap.containsKey(item.Id)) {
                    Id supplierId = legalDocSuppliersMap.get(item.Id);
                    if (suppliersMap.containsKey(supplierId)) {
                        name += ' - ' + suppliersMap.get(supplierId).Code__c + ' ' + suppliersMap.get(supplierId).Name; 
                    }
                }
                legalDocListToUpdate.add(new LegalDoc__c(Id = item.Id, Name = name));
            }
            if (!legalDocListToUpdate.isEmpty()) {
                update legalDocListToUpdate;
            }
        }
    }
    
    public static void cleanUpRelatedList(Map<Id, LegalDoc__c> oLegalDocMap) {
        Map<Id, LegalDocClause__c> legalDocClausesMapToDelete = new Map<Id, LegalDocClause__c>([SELECT Id 
                                                                                                FROM LegalDocClause__c
                                                                                                WHERE LegalDoc__c IN :oLegalDocMap.values()]);
        if(!legalDocClausesMapToDelete.isEmpty()) {
            List<TrackAction__c> trackActions = [SELECT Id
                                                 FROM TrackAction__c
                                                 WHERE ParentId__c IN :legalDocClausesMapToDelete.keySet()
                                                 AND CommentStatus__c <> 'Deleted'
                                                 ORDER BY ActionDate__c ASC];
            if(!trackActions.isEmpty()) {
                for(TrackAction__c trackAct : trackActions) {
                    trackAct.CommentStatus__c = 'Deleted';
                }
                update trackActions;
            }
            delete legalDocClausesMapToDelete.values();
        }
    }
}