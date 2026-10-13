/**
 * @author ULiT
 * Helper Methods in negoptim toolkit
 **/
global with sharing class ToolkitHelper {
    /**
     * Return Component Name with/Without package prefix dependent
     * on package type (managed/unmanaged)
     * @param name: Object/Field Name without prefix
     * */
    global static String normalizeAPIName(String name) {
        List<String> standardFields = new list<String> { 'id', 'ownerid', 'name', 'currencyisocode', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid',
            'recordtypeid', 'recordtype', 'owner', 'createdby', 'lastmodifiedby', 'developername'};
        String prefix = getPackagePrefix(true);
        if(!standardFields.contains(name.toLowerCase()) && !name.toLowerCase().startsWith(prefix.toLowerCase())){
            return prefix + name;
        }
        return name;
    }
    /**
     * Return the Package prefix name if exist or empty
     * @param includeUnderscore: add the 2 underscores separator
     * */
    @AuraEnabled(cacheable=true)
    global static String getPackagePrefix(Boolean includeUnderscore) {
        String prefix = ToolkitHelper.class.getName().substringBefore('ToolkitHelper').substringBefore('.');
        if(prefix != '' && includeUnderscore) {
            prefix = prefix + '__';
        }
        return prefix;
    }
    /**
     * Check Field Level Security for reading
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public static Boolean checkAccessibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on read SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isAccessible()) {
            result = false;
            throw new NoAccessException('Insufficient access to read ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has read access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isAccessible()) {
                result = false;
                throw new NoAccessException('Insufficient access to read "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    // added the two methods: checkCreatibility(), checkUpdatibility()
    /**
     * Check Field Level Security for inserting
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    global static Boolean checkCreatibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on insert SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isCreateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to insert ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has create access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isCreateable()) {
                result = false;
                throw new NoAccessException('Insufficient access to insert "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    /**
     * Check Field Level Security for updating
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    global static Boolean checkUpdatibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on updatetrue SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isUpdateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to update ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has update access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isUpdateable()) {
                result = false;
                throw new NoAccessException('Insufficient access to update "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    /**
     * Return the Label Names of Mandatory Fields.
     * */
    global static Map<String, string> GetMandatoryFieldLabels(SObjectType sObjectType) {
        // Map<Field Name, Field Label Name>
        Map<String, string> fieldNameLabels = new Map<String, string>();
        // Describe all fields for a particular object.
        Map<String, Schema.SObjectField> fieldsByName = sObjectType.getDescribe().fields.getMap();
        for (Schema.SObjectField eachField : fieldsByName.values()) {
            Schema.DescribeFieldResult describe = eachField.getDescribe();
            fieldNameLabels.put(describe.getName(), describe.getLabel());
        }
        return fieldNameLabels;
    }
    public class NoAccessException extends Exception {}

}