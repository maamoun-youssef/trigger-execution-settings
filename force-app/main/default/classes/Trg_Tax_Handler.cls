public with sharing class Trg_Tax_Handler {
    private static Map<String, Id> taxRTIdMap = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);

    public static void OnBeforeInsertOrUpdate(Map<Id, Tax__c> oTaxesMap, List<Tax__c> nTaxes) {
        // filter and Group new active taxes by bu
        Map<Id, List<Tax__c>> newTaxes = new Map<Id, List<Tax__c>>();
        Set<Id> newTaxesId = new Set<Id>();
        for (Tax__c tax : nTaxes) {
            if ((tax.Id == null || tax.ListingOrder__c != oTaxesMap.get(tax.Id).ListingOrder__c
                               || tax.EDate__c != oTaxesMap.get(tax.Id).EDate__c
                               || tax.BusinessUnitVAT__c != oTaxesMap.get(tax.Id).BusinessUnitVAT__c)
                && tax.EDate__c == null && tax.RecordTypeId == taxRTIdMap.get('VAT'))
            {
                if (!newTaxes.containsKey(tax.BusinessUnitVAT__c)) {
                    newTaxes.put(tax.BusinessUnitVAT__c, new List<Tax__c> { tax });
                } else {
                    newTaxes.get(tax.BusinessUnitVAT__c).add(tax);
                }
                if (tax.Id != null) {
                    newTaxesId.add(tax.Id);
                }
            }
        }
        // Process each group in new taxes to check for ListingOrder__c duplicates
        for (Id bu: newTaxes.keySet()) {
            Set<String> listingOrderSet = new Set<String>();
            // Check for duplicates in new taxes
            for (Tax__c tax : newTaxes.get(bu)) {
                if (listingOrderSet.contains(tax.ListingOrder__c)) {
                    // Duplicate found
                    // You can throw an error or take any other action here
                    tax.addError(Label.MSG_VATOrderControl);
                } else {
                    listingOrderSet.add(tax.ListingOrder__c);
                }
            }
        }
        // Collect the active taxes query params
        Set<Id> buList = new Set<Id>();
        for (Tax__c tax : nTaxes) {
            buList.add(tax.BusinessUnitVAT__c);
        }
        // Query all existing active taxes
        List<Tax__c> activeTaxes = [SELECT Id, ListingOrder__c, EDate__c, BusinessUnitVAT__c
                                    FROM Tax__c
                                    WHERE RecordType.DeveloperName = 'VAT'
                                    AND Id NOT In :newTaxesId
                                    AND EDate__c = null
                                    AND Category__c = null
                                    AND BusinessUnitVAT__c in :buList];
        // Group existing taxes by bu
        Map<Id, List<Tax__c>> existingTaxes = new Map<Id, List<Tax__c>>();
        for (Tax__c tax : activeTaxes) {
            if (!existingTaxes.containsKey(tax.BusinessUnitVAT__c)) {
                existingTaxes.put(tax.BusinessUnitVAT__c, new List<Tax__c> { tax });
            } else {
                existingTaxes.get(tax.BusinessUnitVAT__c).add(tax);
            }
        }
        // Process each tax group to ensure no duplicates in ListingOrder__c
        for (Id bu : newTaxes.keySet()) {
            Set<String> listingOrderSet = new Set<String>();

            // Add existing taxes' ListingOrder__c to the set
            if (existingTaxes.containsKey(bu)) {
                for (Tax__c tax : existingTaxes.get(bu)) {
                    listingOrderSet.add(tax.ListingOrder__c);
                }
            }
            // Check for duplicates in new taxes
            for (Tax__c tax : newTaxes.get(bu)) {
                if (listingOrderSet.contains(tax.ListingOrder__c)) {
                    // Duplicate found
                    // You can throw an error or take any other action here
                    tax.addError(Label.MSG_VATOrderControl);
                } else {
                    listingOrderSet.add(tax.ListingOrder__c);
                }
            }
        }
    }
}