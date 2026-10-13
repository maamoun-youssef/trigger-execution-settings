/**
 * @author ULiT
 * @date 05/06/2017
 * @description Base Controller
 **/
public with sharing virtual class NegoptimBaseController {
    
    public static final String NAMESPACE = '';
    public String prefix { get; set; }
    public String auraPrefix { get; set; }
    public String locale { get; set; }
    public String localeDecimalSeparator { get; set; }
public NegoptimFieldValidator nfv { get; set; }
    public String log { get; set; } // used for debug
    
    public NegoptimBaseController() {
        prefix = NegoptimHelper.getPackagePrefix(true);
        auraPrefix = NegoptimHelper.getPackagePrefix(false);
        if (auraPrefix == '') {
            auraPrefix = 'c';
        }
		locale = UserInfo.getLocale();
        localeDecimalSeparator = NegoptimHelper.getDecimalSeparator();
        nfv = new NegoptimFieldValidator();
    }
    /**
     * Get field name with/without prefix dependent
     * on the type of package managed/unmanaged
     * */
    public String getFieldName(String field) {
        Boolean isManaged, isUserLicensed;
        try {
            isUserLicensed = userinfo.isCurrentUserLicensed(NAMESPACE);
            isManaged = true;
        } catch(exception e) {
            isManaged = false;
        }
        List<String> standardFields = new list<String> { 'id', 'ownerid', 'name', 'currencyisocode', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid',
            'recordtypeid', 'recordtype', 'owner', 'createdby', 'lastmodifiedby', 'developername'};
        if(isManaged && !standardFields.contains(field.toLowerCase()) && field.toLowerCase().endsWith('__c') && !field.toLowerCase().startsWith(prefix.toLowerCase())) {
            return NAMESPACE + field;
        } else {
            return field;
        }
    }
    /**
     * Check Field Level Security for reading
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public Boolean checkAccessibility(Schema.SObjectType objType, String[] fields) {
        // check access on read SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isAccessible()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to read ' + sObjectName));
            return false;
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has read access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isAccessible()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to read "' + sObjectName + '.' + field + '"'));
                return false;
            }
        }
        return true;
    }
    /**
     * Check Field Level Security for inserting
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public Boolean checkCreatibility(Schema.SObjectType objType, String[] fields) {
        // check access on insert SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isCreateable()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to insert ' + sObjectName));
            return false;
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has create access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isCreateable()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to insert "' + sObjectName + '.' + field + '"'));
                return false;
            }
        }        
        return true;
    }
    /**
     * Check Field Level Security for updating
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public Boolean checkUpdatibility(Schema.SObjectType objType, String[] fields) {
        // check access on update SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isUpdateable()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update ' + sObjectName));
            return false;
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has update access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isUpdateable()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update "' + sObjectName + '.' + field + '"'));
                return false;
            }
        }
        return true;
    }
    /**
     * Check SObject Level Security for Deleting
     * */
    public static Boolean checkDeletibility(Schema.SObjectType objType) {
        // check access on delete SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isDeletable()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete ' + sObjectName));
            return false;
        }
        return true;
    }
}