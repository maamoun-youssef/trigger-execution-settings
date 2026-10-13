/**
 * @author ULiT
 * @date 03-06-2026
 * @description Handler class for LegalDocClause__c trigger
 */
public with sharing class Trg_LegalDocClauseHandler {
    private static Map<String, String> businessOwnersTypeToIsPlayerFieldMap = new Map<String, String>{
        'Accounting' => SObjectType.LegalDocClause__c.fields.BOAccountingIsPlayer__c.Name,
        'Marketing' => SObjectType.LegalDocClause__c.fields.BOMarketingIsPlayer__c.Name,
        'Offer' => SObjectType.LegalDocClause__c.fields.BOOfferIsPlayer__c.Name,
        'Compliance' => SObjectType.LegalDocClause__c.fields.BOComplianceIsPlayer__c.Name,
        'AfterSales' => SObjectType.LegalDocClause__c.fields.BOAfterSalesIsPlayer__c.Name,
        'Quality' => SObjectType.LegalDocClause__c.fields.BOQualityIsPlayer__c.Name,
        'SupplyChain' => SObjectType.LegalDocClause__c.fields.BOSupplyChainIsPlayer__c.Name,
        'Buyer' => SObjectType.LegalDocClause__c.fields.BOBuyerIsPlayer__c.Name
    };
    private static Map<String, Id> legalDocClauseRTIds = NegoptimHelper.getObjectRecordTypeMapIds(LegalDocClause__c.SObjectType);
    
    public static void onAfterInsert(List<LegalDocClause__c> newLegalDocClauses) {
       updateParentLegalClauses(newLegalDocClauses);
    }
    
    public static void onAfterUpdate(List<LegalDocClause__c> newLegalDocClauses, Map<Id, LegalDocClause__c> oldLegalDocClausesMap) {
        createTrackActions(newLegalDocClauses, oldLegalDocClausesMap);
    }
    
    public static void updateParentLegalClauses(List<LegalDocClause__c> newLegalDocClauses) {
        Id partnerRT = legalDocClauseRTIds.get('Partner');
        Set<Id> parentLegalDocClauseIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        for (LegalDocClause__c item : newLegalDocClauses) {
            if (item.LegalDocClauseP1__c != null) {
                parentLegalDocClauseIdSet.add(item.LegalDocClauseP1__c);
            }
            if (item.CreatedById != null) {
                userIdSet.add(item.CreatedById);
            }
        }
        Map<Id, LegalDocClause__c> parentLegalDocClausesMap = new Map<Id, LegalDocClause__c>();
        if(!parentLegalDocClauseIdSet.isEmpty()) {
            parentLegalDocClausesMap = new Map<Id, LegalDocClause__c>([SELECT Id FROM LegalDocClause__c WHERE Id IN :parentLegalDocClauseIdSet]);
        }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id, BusinessOwners__c FROM User WHERE Id IN :userIdSet]);
        
        Map<Id, LegalDocClause__c> parentLegalDocClausesMapToUpdate = new Map<Id, LegalDocClause__c>();
        
        for (LegalDocClause__c item : newLegalDocClauses) {
            if (item.RecordTypeId == partnerRT && item.Status__c == 'Draft' && item.LegalDocClauseP1__c != null) {
                LegalDocClause__c parentLegalDocClause = parentLegalDocClausesMap.get(item.LegalDocClauseP1__c);
                String businessOwner = usersMap.get(item.CreatedById).BusinessOwners__c;
                for (String businessOwnersType : businessOwnersTypeToIsPlayerFieldMap.keySet()) {
                    parentLegalDocClause.put(businessOwnersTypeToIsPlayerFieldMap.get(businessOwnersType), businessOwner == businessOwnersType);
                }
                parentLegalDocClausesMapToUpdate.put(parentLegalDocClause.Id, parentLegalDocClause);
            }
        }
        if (!parentLegalDocClausesMapToUpdate.isEmpty()) {
            update parentLegalDocClausesMapToUpdate.values();
        }
    }
    
    /**
     * @description Create track action records when status changes
     * On After Update
     */
    public static void createTrackActions(List<LegalDocClause__c> newLegalDocClauses, Map<Id, LegalDocClause__c> oldLegalDocClausesMap) {
        Set<Id> supplierIdSet = new Set<Id>();
        List<LegalDocClause__c> legalDocClauses = new List<LegalDocClause__c>();
        List<TrackAction__c> trackActionsToInsert = new List<TrackAction__c>();
        for (LegalDocClause__c item : newLegalDocClauses) {
            if (item.Status__c != oldLegalDocClausesMap.get(item.Id).Status__c && item.Supplier__c != null) {
                supplierIdSet.add(item.Supplier__c);
                legalDocClauses.add(item);
            }
        }
        Map<Id, Supplier__c> suppliersMap = new Map<Id, Supplier__c>();
        User currentUser;
        if(!supplierIdSet.isEmpty()) {
            suppliersMap = new Map<Id, Supplier__c>([SELECT Id, Account__c, OwnerId FROM Supplier__c WHERE Id IN :supplierIdSet]);
            currentUser = [SELECT Id, Name, SmallPhotoUrl, FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        }
        for (LegalDocClause__c item : legalDocClauses) {
            Supplier__c supplier = suppliersMap.get(item.Supplier__c);
            TrackAction__c newTrackAction = new TrackAction__c(ParentId__c = item.Id,
                                                               Account__c = supplier?.Account__c,
                                                               Assignee__c = currentUser.Name,
                                                               AssigneeIconURL__c = currentUser?.SmallPhotoUrl);
            String status;
            switch on item.Status__c { 
                when 'legal publishing', 'Business owner publishing', 'published' {
                    status = 'Requested';
                }
                when 'Validated' {
                    status = 'Validated';
                }
                when 'Approved' {
                    status = 'Submitted';
                }
                when 'Rejected' {
                    status = 'Rejected';
                }
                when else {
                    status = 'Open';
                }
            }
            newTrackAction.Status__c = status;
            newTrackAction.ActionDate__c = System.now();
            trackActionsToInsert.add(newTrackAction);
        }          
        if (!trackActionsToInsert.isEmpty()) {
            insert trackActionsToInsert;            
        }
    }
}