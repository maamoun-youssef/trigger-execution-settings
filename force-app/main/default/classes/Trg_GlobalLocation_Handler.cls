public with sharing class Trg_GlobalLocation_Handler {
    public static void OnBeforeInsert(List<GlobalLocation__c> nglobalLocations) {
        populateFields(nglobalLocations);
    }
    public static void populateFields(List<GlobalLocation__c> nglobalLocations){
        Set<Id> supplierIds = new Set<Id>();
        List<GlobalLocation__c> globalLocationsWithSuppliers = new List<GlobalLocation__c>();
        // Collect Supplier IDs from the records being inserted
        for (GlobalLocation__c gl : nglobalLocations) {
            if (gl.Supplier__c != null) {
                supplierIds.add(gl.Supplier__c);
                globalLocationsWithSuppliers.add(gl);
            }
        }
           // Map to hold Supplier Ids and its Infos
        Map<Id, Supplier__c> supplierInfosMap = new Map<Id, Supplier__c>();
        if (!supplierIds.isEmpty()) {
            supplierInfosMap = new Map<Id, Supplier__c> ([SELECT Id, ReferenceLanguage__c, CurrencyIsoCode FROM Supplier__c  WHERE Id IN :supplierIds]);
        }
        for (GlobalLocation__c gl : globalLocationsWithSuppliers) {
            gl.CurrencyIsoCode = supplierInfosMap.get(gl.Supplier__c).CurrencyIsoCode;
            gl.ReferenceLanguage__c = supplierInfosMap.get(gl.Supplier__c).ReferenceLanguage__c;
        }
       
    }
}