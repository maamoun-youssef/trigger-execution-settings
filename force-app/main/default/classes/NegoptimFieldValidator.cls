/*
*  Public class that handle all validation logic
*  along with trigger for custom button ( save , submit ) 
*/
public with sharing class NegoptimFieldValidator {

    /**
     * Check negoscope name and supplier field validation
     * String name : negoscope Name
     * String supplier : supplier that belong to negoscope
     */
    public Boolean negoScopeCheckDuplication(String name, String supplier, Id negoScopeId) {
        NegoScope__c NS;
        try {
            // check security on NegoScope__c fields
            String[] negoScopeFields = new String[] {
                SObjectType.NegoScope__c.fields.Id.Name,
                SObjectType.NegoScope__c.fields.Name.Name,
                SObjectType.NegoScope__c.fields.Supplier__c.Name
            };
            if(NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)) {
                String query = 'SELECT Name ';
                query += ' FROM ' + SObjectType.NegoScope__c.Name;
                List<String> conditions = new List<String>();
                if (SObjectType.NegoScope__c.fields.Name.isFilterable()) {
                    conditions.add(SObjectType.NegoScope__c.fields.Name.Name + ' = \'' + String.escapeSingleQuotes(name) + '\'');
                }
                conditions.add(SObjectType.NegoScope__c.fields.Supplier__c.Name + ' = \'' + String.escapeSingleQuotes(supplier) + '\'');
                conditions.add(SObjectType.NegoScope__c.fields.Id.Name + ' <> \'' + String.escapeSingleQuotes(negoScopeId) + '\'');
                query += conditions != null && !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
                query += ' LIMIT 1';
                NS = Database.query(query);
            }
        } catch(Exception e) {
            NS = null;
        }
        if(NS != null) {
            NS.addError(System.Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique);
            return false;
        }
        return true;
    }
}