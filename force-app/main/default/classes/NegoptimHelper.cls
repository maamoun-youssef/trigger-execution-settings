/**
 * @author ULiT
 * @date 05/06/2017
 * @description Helper Methods
 **/
global with sharing class NegoptimHelper {

    public static String FOLDER_SETTINGS_NAME = 'private';
    public static String DOCUMENT_SETTINGS_NAME = 'globalSettings';

    // constant values of colors used in myOffer to indicate if a product in old, inno, intro...
    // N is Assortment Year
    public static final String INNO_INTRO_DATE_LESS_N = '#008000';      // used for products with (isInnovation__c true or of record type unit need) market_introduction_Date__c year < N
    public static final String INNO_INTRO_DATE_GREATER_N = '#5ab403';   // used for products with (isInnovation__c true or of record type unit need) and market_introduction_Date__c year >= N
    public static final String STOP_DATE_LESS_N = '#FA5E00';            // used for products with market_end_of_life_date__c year < N
    public static final String STOP_DATE_GREATER_N = '#ff0000';         // used for products with market_end_of_life_date__c year >= N

    /**
     * @description get the number of cluster checkboxes in the object Assortment_Detail__c
    */
    global static Integer getNbClientClusterFields() {
        Integer nbClientCluster_Strat_Fields = 0;
        Integer nbClientCluster_Cplt_Fields = 0;
        String stratFieldName = normalizeAPIName('Client_Clust');
        String cpltFieldName = normalizeAPIName('Client_Clust_Cplt');
        Set<String> assortmentDetailsFieldsSet = SObjectType.Assortment_Detail__c.fields.getMap().keySet();
        for (String fieldName : assortmentDetailsFieldsSet) {
            if (fieldName.startsWithIgnoreCase(stratFieldName) && !fieldName.containsIgnoreCase('Cplt') && fieldName.endsWithIgnoreCase('__c')) {
                nbClientCluster_Strat_Fields++;
            } else if (fieldName.startsWithIgnoreCase(cpltFieldName) && fieldName.endsWithIgnoreCase('__c')) {
                nbClientCluster_Cplt_Fields++;
            }
        }
        return Math.Max(nbClientCluster_Strat_Fields, nbClientCluster_Cplt_Fields);
    }

    /**
     * Return Map of key = parent with value = Set of children BU Ids
     * if no children, value = itself
     * @param ids: Set of BU ids
     * */
    global static Map<Id, Set<Id>> getBUChildrenMap(Set<Id> ids) {
        return getBUChildrenMap(ids, new Set<String>{'Store', 'Web', 'Warehouse', 'Country', 'List', 'Group', 'Banner', 'AssortmentCluster'});
    }
    /**
     * Return Map of key = parent with value = Set of children BU Ids
     * if no children, value = itself
     * @param ids: Set of BU ids
     * @param buRecortypeList: Set of BU recordtype needed
     * */
    public static Map<Id, Set<Id>> getBUChildrenMap(Set<Id> ids, Set<String> buRecordtypeList) {
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Id.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.DeveloperNameRT__c.Name,
            SObjectType.BusinessUnit__c.fields.Status__c.Name,
            SObjectType.BusinessUnit__c.fields.RecordTypeId.Name
        };
        String[] orgaBUListDetailFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
        };
        if (checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
            && checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields))
        {
            List<BusinessUnit__c> BUList = [SELECT Id, Name, DeveloperNameRT__c,
                                            (SELECT BusinessUnitDetail__r.Id, BusinessUnitDetail__r.Name, BusinessUnitDetail__r.DeveloperNameRT__c
                                             FROM BULNKBusinessUnitMaster__r
                                             WHERE BusinessUnitDetail__r.Status__c = 'Open')
                                            FROM BusinessUnit__c
                                            WHERE RecordType.DeveloperName IN :buRecordtypeList
                                            AND Status__c = 'Open'
                                            AND Id IN :ids];
            for(BusinessUnit__c item : BUList) {
                if(!BUIdsMap.containsKey(item.Id)) {
                    BUIdsMap.put(item.Id, new Set<Id>());
                }
                if(item.BULNKBusinessUnitMaster__r.size() > 0) {
                    // Cases of DeveloperNameRT__c = 'Country' or 'List' or 'Group'
                    for(BULink__c BUDetail : item.BULNKBusinessUnitMaster__r) {
                        BUIdsMap.get(item.Id).add(BUDetail.BusinessUnitDetail__r.Id);
                    }
                } else {
                    // Cases of DeveloperNameRT__c = 'Store' or 'Web' or 'Warehouse' or 'Banner'
                    // put same Id if BU haven't children
                    BUIdsMap.get(item.Id).add(item.Id);
                }
            }
        }
        return BUIdsMap;
    }
    /**
     * Return Map of key = child with value = Set of parent BU Ids
     * if no parent, value = empty
     * @param ids: Set of BU ids
     * */
    global static Map<Id, Set<Id>> getBUParentsMap(Set<Id> ids) {
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        String[] orgaBUListDetailFields = new String[] {
            SObjectType.BULink__c.fields.BusinessUnitMaster__c.Name,
            SObjectType.BULink__c.fields.BusinessUnitDetail__c.Name
        };
        if (checkAccessibility(BULink__c.SObjectType, orgaBUListDetailFields)) {
            for(BULink__c item : [SELECT BusinessUnitMaster__c, BusinessUnitDetail__c
                                  FROM BULink__c
                                  WHERE BusinessUnitDetail__c IN :ids])
            {
                if(!BUIdsMap.containsKey(item.BusinessUnitDetail__c)) {
                    BUIdsMap.put(item.BusinessUnitDetail__c, new Set<Id>{item.BusinessUnitMaster__c});
                } else {
                    BUIdsMap.get(item.BusinessUnitDetail__c).add(item.BusinessUnitMaster__c);
                }
            }
        }
        return BUIdsMap;
    }
    /* Get folder settings */
    global static Folder getFolderSettings() {
        String[] folderFields = new String[] {
            SObjectType.Folder.fields.Id.Name,
            SObjectType.Folder.fields.Name.Name
        };
        if (checkAccessibility(Folder.SObjectType, folderFields)) {
            List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = :FOLDER_SETTINGS_NAME LIMIT 1];
            if(folders != null && folders.size() > 0) {
                return folders.get(0);
            }
        }
        return null;
    }
    /**
     * Return the Package prefix name if exist or empty
     * @param includeUnderscore: add the 2 underscores separator
     * */
    @AuraEnabled(cacheable=true)
    global static String getPackagePrefix(Boolean includeUnderscore) {
        String prefix = NegoptimHelper.class.getName().substringBefore('NegoptimHelper').substringBefore('.');
        if(prefix != '' && includeUnderscore) {
            prefix = prefix + '__';
        }
        return prefix;
    }
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
     * Check Field Level Security for reading
     * @param fieldsMap
     * */
    global static Boolean checkAccessibilityFields(Map<String, SObjectField> fieldsMap, String[] fields) {
        Boolean result = true;
        for (String field : fields) {
            // Check if the user has read access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isAccessible()) {
                result = false;
                throw new NoAccessException('Insufficient access to read ' + field);
            }
        }
        return result;
    }
    /**
     * Check Field Level Security for reading
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    global static Boolean checkAccessibility(Schema.SObjectType objType, String[] fields) {
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
     * Check SObject Level Security for Deleting
     * */
    global static Boolean checkDeletibility(Schema.SObjectType objType) {
        Boolean result = true;
        // check access on delete SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isDeletable()) {
            result = false;
            throw new NoAccessException('Insufficient access to delete ' + sObjectName);
        }
        return result;
    }
    /**
     * Get Object RecordType Id by Name
     * @param sObjectType
     * @param recordTypeName
     * @example: Id recordTypeId = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'Country');
     * */
    global static String getObjectRecordTypeId(SObjectType sObjectType, String recordTypeName) {
        // If sObjectType is wrong, then an Exception is thrown.
        Id rt;
        Map<Id, Schema.RecordTypeInfo> sObjectTypeRecordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosById();
        for (Id RTId : sObjectTypeRecordTypeInfo.keySet()) {
            if (sObjectTypeRecordTypeInfo.get(RTId).getDeveloperName() == recordTypeName) {
                rt = RTId;
            }
        }
        if (rt == null) {
            // If recordTypeName is wrong, then an Exception is thrown.
            throw new RecordTypeException('Record type "'+ recordTypeName +'" does not exist.');
        }
        //Return the record type id
        return rt;
    }

     /**
     * @description get Inaccessible Fields
     * */
    public static void getInaccessibleFields(QueryException qe) {
        Map<String, Set<String>> inaccessibleFields = qe.getInaccessibleFields();
        Set<String> errorMessages = new Set<String>();
        if(!inaccessibleFields.isEmpty()) {
            for (String objectName : inaccessibleFields.keySet()) {
                for (String fieldName : inaccessibleFields.get(objectName)) {
                    errorMessages.add(objectName + '.' + fieldName);
                }
            }
            throw new NoAccessException('Insufficient access to read "' + String.join((new List<String>(errorMessages)), ', ') + '"');
        } else {
            System.debug('ERROR: ' + qe.getMessage() + ' - ' + qe.getLineNumber());
            throw new IllegalArgumentException('ERROR: ' + qe.getMessage());
        }
    }

    /**
     * Check Field Level Security
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public static Boolean checkFLS(System.AccessType accessType, List<SObject> records) {
        Boolean result = true;
        if(records == null || records.isEmpty() || accessType == null) return true;
        Schema.SObjectType sObjectType = records[0].getSObjectType();
        String sObjectName = sObjectType.getDescribe().getName();
        // check access on read SObject
        if(accessType == System.AccessType.CREATABLE && !sObjectType.getDescribe().isCreateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to insert ' + sObjectName);
        } else if(accessType == System.AccessType.UPDATABLE && !sObjectType.getDescribe().isUpdateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to update ' + sObjectName);
        } else if(accessType == System.AccessType.UPSERTABLE && (!sObjectType.getDescribe().isCreateable() || !sObjectType.getDescribe().isUpdateable())) {
            result = false;
            throw new NoAccessException('Insufficient access to upsert ' + sObjectName);
        }
        SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);
        // Returns all fields removed because of FLS
        Set<String> removedFields = decision.getRemovedFields().containsKey(sObjectName) ? decision.getRemovedFields().get(sObjectName) : new Set<String>();
        // Create a set to store unique inaccessible field names
        Set<String> inaccessibleFields = new Set<String>();
        List<String> standardFields = new List<String> { 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'isdeleted', 'lastvieweddate', 'lastactivitydate', 'lastreferenceddate'};
        if(result && !removedFields.isEmpty()) {
            Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
            for (String fieldName : removedFields) {
                if(fieldsMap.containsKey(fieldName)) {
                    DescribeFieldResult fieldDescribeResult = fieldsMap.get(fieldName).getDescribe();
                    Boolean isMasterDetail = fieldDescribeResult.getType() == DisplayType.REFERENCE && fieldDescribeResult.getRelationshipOrder() != null;
                    if(!isMasterDetail
                       && !standardFields.contains(fieldName.toLowerCase())
                       && !fieldDescribeResult.isCalculated()
                       && !fieldDescribeResult.isAutoNumber()
                       && (accessType == System.AccessType.CREATABLE || accessType == System.AccessType.UPDATABLE || accessType == System.AccessType.UPSERTABLE))
                    {
                        inaccessibleFields.add(sObjectName + '.' + fieldName);
                    }
                }
            }
            if(!inaccessibleFields.isEmpty()) {
                result = false;
                if(accessType == System.AccessType.CREATABLE) {
                    throw new NoAccessException('Insufficient access to insert "' + String.join(new List<String>(inaccessibleFields), ', ') + '"');
                } else if(accessType == System.AccessType.UPDATABLE) {
                    throw new NoAccessException('Insufficient access to update "' + String.join(new List<String>(inaccessibleFields), ', ') + '"');
                } else if(accessType == System.AccessType.UPSERTABLE) {
                    throw new NoAccessException('Insufficient access to upsert "' + String.join(new List<String>(inaccessibleFields), ', ') + '"');
                }
            }
        }
        return result;
    }
    /**
     * Get Object RecordType Name by Id
     * @param sObjectType
     * @param recordTypeId
     * @example: String recordTypeName = NegoptimHelper.getObjectRecordTypeName(BusinessUnit__c.SObjectType, '01224000000RmMHAA0');
     * */
    global static String getObjectRecordTypeName(SObjectType sObjectType, Id recordTypeId) {
        // Generate a map of tokens for all the Record Types for the desired object
        Map<Id, Schema.RecordTypeInfo> recordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosById();

        if(!recordTypeInfo.containsKey(recordTypeId))
            throw new RecordTypeException('Record type "'+ recordTypeId +'" does not exist.');

        //Retrieve the record type id by name
        return recordTypeInfo.get(recordTypeId).getName();
    }
    /**
     * Get Object RecordType Map of Name/Id
     * @param sObjectType
     * */
    global static Map<String, Id> getObjectRecordTypeMapIds(SObjectType sObjectType) {
        Map<String, Id> rtMap = new Map<String, Id>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            rtMap.put(RT.getDeveloperName(), RT.getRecordTypeId());
        }
        //Return the record type id
        return rtMap;
    }
/**
     * Get Available on profile Object RecordType Map of Name/Id
     * @param sObjectType
     * */
    global static Map<String, Id> getAvailableObjectRecordTypeMapIds(SObjectType sObjectType) {
        Map<String, Id> rtMap = new Map<String, Id>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            if (RT.isActive()/* && RT.isAvailable()*/) {
                rtMap.put(RT.getDeveloperName(), RT.getRecordTypeId());
            }
        }
        //Return the record type id
        return rtMap;
    }

    /**
    * Get Object RecordType Map of DeveloperName / Label
    * @param sObjectType
    * */
    global static Map<String, String> getObjectRecordTypeMapDeveloperNameToLabel(SObjectType sObjectType) {
        Map<String, String> developerNameToLabelMap = new Map<String, String>();
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs){
            developerNameToLabelMap.put(RT.getDeveloperName(), RT.getName());
        }
        return developerNameToLabelMap;
    }

    /**
     * Get Object RecordType Map of Id/DeveloperName
     * @param sObjectType
     * */
    global static Map<Id, String> getObjectRecordTypeMapDeveloperNames(SObjectType sObjectType) {
        Map<Id, String> rtMap = new Map<Id, String>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            rtMap.put(RT.getRecordTypeId(), RT.getDeveloperName());
        }
        //Return the record type id
        return rtMap;
    }
    /**
     * Get Object RecordType Map of Id/Translated Name
     * @param sObjectType
     * */
    global static Map<Id, String> getObjectRecordTypeMapLabels(SObjectType sObjectType) {
        Map<Id, String> rtMap = new Map<Id, String>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            rtMap.put(RT.getRecordTypeId(), RT.getName());
        }
        //Return the record type id
        return rtMap;
    }

    public class RecordTypeException extends Exception {}
    public class GlobalSettingsException extends Exception {}
    public class NoAccessException extends Exception {}

    /**
     * Get root element Id by DeveloperName
     * */
    global static Id getHierarchyRootId(String developerName) {
        String[] hierarchyAccessFields = new String[] {
            SObjectType.Hierarchy__c.fields.Id.Name,
            SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name
        };
        if (checkAccessibility(Hierarchy__c.SObjectType, hierarchyAccessFields)) {
            List<Hierarchy__c> elements = [SELECT Id FROM Hierarchy__c WHERE RecordType.DeveloperName = :developerName AND HierarchyParent__c = null];
            if(elements != NULL && elements.size() > 0) {
                return elements.get(0).Id;
            } else {
                Hierarchy__c root = new Hierarchy__c(Name = 'ROOT' + developerName, Code__c = 'ROOT' + developerName, HierarchyParent__c = null, Level__c = 0, StatusBDate__c = date.newInstance(System.today().year(), 1, 1), RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, developerName));
                List<String> hierarchyCreateFields = new List<String> {
                    SObjectType.Hierarchy__c.fields.Name.Name,
                    SObjectType.Hierarchy__c.fields.Code__c.Name,
                    SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
                    SObjectType.Hierarchy__c.fields.Level__c.Name,
                    SObjectType.Hierarchy__c.fields.StatusBDate__c.Name
                };
                if (checkCreatibility(Hierarchy__c.SObjectType, hierarchyCreateFields)) {
                    insert root;
                }
                return root.Id;
            }
        }
        return null;
    }

    /**
     * Get Product Hierarchy__c root element Id
     * */
    global static Id getRootId() {
        return NegoptimHelper.getHierarchyRootId('Product');
    }
    /**
     * Get root element Id by DeveloperName
     * */
    global static Id getRootIdByRT(String developerName) {
        return NegoptimHelper.getHierarchyRootId(developerName);
    }

    /**
     * Return the Corporate Currency if exist, else return ''.
     * */
    global static String getCorporateCurrency() {
        String currencyIsoCode = '';
        String[] currencyTypeField = new String[] {
            SObjectType.CurrencyType.fields.IsoCode.Name,
            SObjectType.CurrencyType.fields.IsCorporate.Name
        };
        if (checkAccessibility(CurrencyType.SObjectType, currencyTypeField)) {
            List<CurrencyType> currencies = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1];
            if(currencies != null && currencies.size() > 0) {
                currencyIsoCode = currencies.get(0).IsoCode;
            }
        }
        return currencyIsoCode;
    }
    /**
     * Return the separator of decimal number based on user locale.
     * */
    global static String getDecimalSeparator() {
        Decimal d = 1.98;
        String sD = d.format();
        return sD.contains(',') ? ',' : '.';
    }
/**
     * Return a string for a number with format percentage.
     * */
    global static String formatPercentageValue(Decimal d, Boolean wildcard) {
        String decimalSeparator = getDecimalSeparator();
        String sPercent = d != null ? d.setScale(2).format() : '';
        if (sPercent != null && sPercent.trim() != '' && !sPercent.contains(decimalSeparator)) {
            sPercent += decimalSeparator + '00';
        }
        else if(sPercent != null && sPercent.contains(decimalSeparator)) {
            decimalSeparator = decimalSeparator == '.' ? '\\.' : decimalSeparator;
            if (sPercent.split(decimalSeparator)[1].length() < 2) {
                sPercent += '0';
            }
        }
        if(wildcard) {
            sPercent += '%';
        }
        return sPercent;
    }
    /**
     * Return a string for a decimal with format.
     * */
    global static String formatDecimalValue(Decimal d, Integer places) {
        decimal value = d != null ? d : 0;
        String rightValue = '';
        rightValue = rightValue.rightPad(places, '0') + '1';
        String sValue = (value.setScale(places) + Decimal.valueOf('0.' + rightValue)).format();
        return sValue.substring(0, sValue.length() -1);
    }
    /**
     * get default value from picklist.
     * @param dFR: the describing field result
     * */
    global static String defaultPicklistValue(Schema.DescribeFieldResult dFR) {
        String defaultVal = '';
        List<Schema.PicklistEntry> pickVals = dFR.getPicklistValues();
        for (Schema.PicklistEntry pv: pickVals) {
            if (pv.isDefaultValue()) {
                defaultVal = pv.getValue();
                break;
            }
        }
        return defaultVal;
    }
    /**
     * get last day date in month of a given month and year
     * */
    global static Date getLastDayOfMonth(Integer year, Integer month) {
        return Date.newInstance(year, month, Date.daysInMonth(year, month));
    }
    /**
     * get last day date in month of a given date
     * */
    global static Date getLastDayOfMonth(Date aDate) {
        if(aDate == null) {
            return Date.newInstance(1000, 1, 1);
        }
        return Date.newInstance(aDate.year(), aDate.month(), Date.daysInMonth(aDate.year(), aDate.month()));
    }
    /**
     * @param numerator
     * @param denominator
     * @param decimalPlaces
     * return list of decimals number with the safe rest
     * Ex: 1000/3 = 333.33 + 333.33 + 333.34
     * */
    global static List<Decimal> smartDivision(Decimal numerator, Integer denominator, Integer decimalPlaces, System.RoundingMode roundingMode) {
        List<Decimal> listOfDecimals = new List<Decimal>();
        if(numerator == null || denominator == 0) {
            return listOfDecimals;
        }
        Decimal divisionResult, diff = 0, total = 0;
        divisionResult = roundingMode != null ? numerator.divide(denominator, decimalPlaces, roundingMode) : numerator.divide(denominator, decimalPlaces);
        Integer remainder = math.mod(Integer.valueOf(numerator), denominator);
        if(remainder != 0) {
            for(Integer index = 1 ; index < denominator; index++) {
                listOfDecimals.add(divisionResult);
                total += divisionResult;
            }
            diff = numerator - total;
            if(roundingMode != null) {
                listOfDecimals.add(diff.setScale(decimalPlaces, roundingMode));
            } else {
                listOfDecimals.add(diff.setScale(decimalPlaces));
            }
        } else { // no gap
            for(Integer index = 1; index <= denominator; index++) {
                listOfDecimals.add(divisionResult);
            }
        }
        return listOfDecimals;
    }
    /**
     * This method validates an Id length (15 or 18) and validates
     * the possible characters that should exist within an Id using regular expressions.
     * */
    static global Boolean validateId(String Idparam) {
        String id = String.escapeSingleQuotes(Idparam);
        if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
            return true;
        }
        return false;
    }

    /**
     * @param objectName Object API Name
     * @param the fields a list of lookup relationships that end with a field name: lookup1__r.lookup2__r.field__c
     * or objectName.lookup1__r.lookup2__r.field__c
    */
    global static Schema.SObjectField validateField(String objectName, List<String> theFields) {
        SObjectField result = null;
        String prefix = getPackagePrefix(true);
        if (!objectName.startsWith(prefix) && objectName.contains('__c')) {
            objectName = prefix + objectName;
        }
        // Get SObject of the object name string value.
        SObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject();
        // Check if the field name is validated or not and return.
        Map<String, Schema.SObjectField> fieldMap = sObj.getSobjectType().getDescribe().fields.getMap();
        if (theFields[0].equalsIgnoreCase(objectName)) {
            theFields.remove(0);
        }
        if(theFields.size() == 1) {
            result = fieldMap.get(normalizeAPIName(theFields.get(0)));
        }
        else if (theFields.size() != 0) {
            String lookupField = theFields.get(0).replace('_r', '_c');
            // Special cases
            if(lookupField == 'Owner' || lookupField == 'CreatedBy' || lookupField == 'LastModifiedBy' || lookupField == 'RecordType' || lookupField == 'Parent') {
                lookupField += 'Id';
            } else {
                lookupField = normalizeAPIName(lookupField);
            }
            if(fieldMap.containsKey(lookupField)) {
                Schema.SObjectField field = fieldMap.get(lookupField);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                List<Schema.sObjectType> sObjectTypeList = fieldDescribe.getReferenceTo();
                if (sObjectTypeList.size() > 0) {
                    theFields.remove(0);
                    if(sObjectTypeList.size() == 2) {
                        result = validateField(sObjectTypeList.get(1).getDescribe().getName(), theFields);
                    } else {
                        result = validateField(sObjectTypeList.get(0).getDescribe().getName(), theFields);
                    }
                }
            }
        }
        return result;
    }

    global static String addFieldPrefix(String objectName, List<String> theFields) {
        String fieldName = '';
        String prefix = getPackagePrefix(true);
        if (!objectName.startsWith(prefix) && objectName.contains('__c')) {
            objectName = prefix + objectName;
        }
        // Get SObject of the object name string value.
        SObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject();
        // Check if the field name is validated or not and return.
        Map<String, Schema.SObjectField> fieldMap = sObj.getSobjectType().getDescribe().fields.getMap();
        if (theFields[0].equalsIgnoreCase(objectName)) {
            theFields.remove(0);
        }
        if(theFields.size() == 1) {
            fieldName = normalizeAPIName(theFields.get(0));
        }
        else if (theFields.size() != 0) {
            String lookupField = theFields.get(0).replace('__r', '__c');
            String[] standardFields = new String[] {'owner', 'createdby', 'lastmodifiedby', 'recordtype'};
            // Special cases
            if(standardFields.contains(lookupField.toLowerCase())) {
                fieldName = lookupField;
                lookupField += 'Id';
            } else {
                fieldName = normalizeAPIName(theFields.get(0));
                lookupField = normalizeAPIName(lookupField);
            }
            if(fieldMap.containsKey(lookupField)) {
                Schema.SObjectField field = fieldMap.get(lookupField);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                List<Schema.sObjectType> sObjectTypeList = fieldDescribe.getReferenceTo();
                if (sObjectTypeList.size() > 0) {
                    theFields.remove(0);
                    if(sObjectTypeList.size() == 2) {
                        fieldName =  fieldName + '.' + addFieldPrefix(sObjectTypeList.get(1).getDescribe().getName(), theFields);
                    }
                    fieldName =  fieldName + '.' + addFieldPrefix(sObjectTypeList.get(0).getDescribe().getName(), theFields);
                }
            }
        }
        return fieldName;
    }
    // Check if trigger is disabled or not
    static global Boolean isTriggerDisabled(String triggerName) {
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        if (negoSettings.activateMaintenanceMode) {
            String trgName = String.escapeSingleQuotes(triggerName);
            // List<Triggers_Settings__c> TS = [SELECT Is_Disabled__c FROM Triggers_Settings__c WHERE Trigger_Name__c = :trgName];
            Triggers_Settings__c TS;
            for (Triggers_Settings__c item : Triggers_Settings__c.getAll().values()) {
                if (item.Trigger_Name__c == triggerName) {
                    TS = item;
                }
            }
            // if (!TS.IsEmpty() && TS.get(0).Is_Disabled__c) {
            if (TS != null && TS.Is_Disabled__c == true) {
                System.debug('*** WARNING ***');
                System.debug('*** The Trigger ' + trgName + ' is disabled. ***');
                return true;
            }
        }
        return false;
    }
    /**
     * get Picklist Translation.
     * @param dFR: the describing field result
     * @param onlyActive: flag only active picklist values
     * */
    global static Map<String, String> getPicklistTranslationMap(Schema.DescribeFieldResult dFR, Boolean onlyActive) {
        Map<String, String> pickListTranslationMap = new Map<String, String>();
        if (dFR != null) {
            for (Schema.PicklistEntry pv: dFR.getPicklistValues()) {
                if (!onlyActive || onlyActive && pv.isActive()) {
                    pickListTranslationMap.put(pv.getValue(), pv.getLabel());
                }
            }
        }
        return pickListTranslationMap;
    }
    /**
     * change __c to __r
     * @param fielName: Field API Name
     * */
    global static String getFieldNameAsRelation(String fielName) {
        return fielName.replace('__c', '__r');
    }

/**
     * Get Object RecordType Map of Name/Id
     * @param sObjectType
     * */
    global static Id getObjectDefaultRecordTypeId(String objectName) {
        String prefix = getPackagePrefix(true);
        if (!objectName.startsWith(prefix) && objectName.contains('__c')) {
            objectName = prefix + objectName;
        }
        return getObjectDefaultRecordTypeId(Schema.getGlobalDescribe().get(objectName));
    }

    /**
     * Get Object RecordType Map of Name/Id
     * @param sObjectType
     * */
    global static Id getObjectDefaultRecordTypeId(SObjectType sObjectType) {
        Schema.DescribeSObjectResult dsr = sObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
            }
        }
        return defaultRecordType != null ? defaultRecordType.getRecordTypeId() : null;
    }
    /**
     * Get Object Label
     * @param sObjectType Name
     * */
    global static String getSObjectLabel(String objectName) {
        if (Schema.getGlobalDescribe().containsKey(NegoptimHelper.normalizeAPIName(objectName))) {
            return Schema.getGlobalDescribe().get(NegoptimHelper.normalizeAPIName(objectName)).getDescribe().getLabel();
        }
        return null;
    }
    /**
     * Parse CSV File.
     * @param contents: the content is a string.
     * @param skipHeaders: skip first line.
     * */
    global static List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
        // Replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field.
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        // Now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote.
        contents = contents.replaceAll('""','DBLQT');
        // We are not attempting to handle fields with a newline inside of them.
        // So, split on newline to get the spreadsheet rows.
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
        }
        for(String line : lines) {
            // Check for blank CSV lines (only commas).
            if (line.replaceAll(',','').trim().length() == 0) break;
            List<String> fields = line.split(',');
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields;
    }
    /**
     * Parse CSV File.
     * @param contents: the content is a list of lines.
     * @param skipHeaders: skip first line.
     * @param separator: CSV columns separator.
     * */
    global static List<List<String>> parseCSV(List<String> lines, Boolean skipHeaders, String separator) {
        // set default separator to comma
        // TODO: get CSV separator from user settings1
        separator = separator != '' && separator != null ? String.escapeSingleQuotes(separator) : null;
        if(separator == '' || separator == null) {
            separator = ',';
        }
        if(separator == '|') separator = '\\|';
        List<List<String>> allFields = new List<List<String>>();
        for(String line : lines) {
            // Check for blank CSV lines (only commas).
            if (line.replaceAll(separator,'').trim().length() == 0) break;
            List<String> fields = line.split(separator);
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                field = String.escapeSingleQuotes(field);
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += separator + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField += separator + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields;
    }

    /**
     * Parse CSV File, Header not skipped, should be used in import csv batchs
     * @param contents: the content is a list of lines.
     * @param separator: CSV columns separator.
     * */
    global static List<List<String>> parseCSV(List<String> lines, String separator){
        return parseCSV(lines, false, separator);
    }

        /**
     * Return the calculate due date based on conditions
     * @param originDate: date origin
     * @param days: days to be added based on condition
     * @param condition: condition to be transformed depend on signification
     * */
    static public Date getDueDate(Date originDate, Integer days, String condition) {
        if(days == null || condition == null) {
            return originDate;
        }
        Integer paymentDays = Integer.valueOf(days);
        Date d;
        if(condition == 'End of Month') {
            d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays);
        }
        else if(condition == 'End of Month, the 15') {
            d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays) + 15;
        }
        else if(condition == 'Net') {
            d = originDate + paymentDays;
        }
        else if(condition == 'The 10') {
            d = setOnFixDay(originDate + paymentDays, 10);
        }
        else if(condition == 'The 15') {
            d = setOnFixDay(originDate + paymentDays, 15);
        }
        else if(condition == 'The 20') {
            d = setOnFixDay(originDate + paymentDays, 20);
        }
        else if(condition == 'Twice the Month') {
            d = originDate + paymentDays;
            if(d.day() <= 15) {
                d = setOnFixDay(originDate + paymentDays, 15);
            }
            else {
                d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays);
            }
        }
        else {
            d = originDate;
        }
        return d;
    }
    static private Date setOnFixDay(Date d, Integer i) {
        if(d.day() > i) {
            d = Date.newInstance(d.year(), d.month() + 1, i);
        }
        else {
            d = Date.newInstance(d.year(), d.month(), i);
        }
        return d;
    }
    public static String cachedSessionId;

    @AuraEnabled
    public static String getSessionId() {
        if (Trigger.isExecuting || Test.isRunningTest()) {
            return UserInfo.getSessionId();
        } else if (cachedSessionId != null) {
            return cachedSessionId;
        } else {
            String content = Page.GridSettingsSessionId.getContent().toString();
            Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(), e = content.indexOf('End_Of_Session_Id');
            cachedSessionId = content.substring(s, e);
            return cachedSessionId;
        }
    }

    @AuraEnabled
    public static String getInternalSessionId() {
        return UserInfo.getSessionId();
    }

    @AuraEnabled
    public static String getUserContext(){
        try {
            Map<String, String> userContext = new Map<String, String>();
            if (String.isNotBlank(Network.getNetworkId())) userContext.put('networkId', Network.getNetworkId());
            if (String.isNotBlank(UserInfo.getUserId())) userContext.put('userId', UserInfo.getUserId());
            if (String.isNotBlank(UserInfo.getLanguage())) userContext.put('userLanguage', UserInfo.getLanguage());
            if (String.isNotBlank(UserInfo.getLocale())) userContext.put('userLocale', UserInfo.getLocale());
            List<Site> siteList = [SELECT Id, UrlPathPrefix FROM Site WHERE UrlPathPrefix = 'NegoptimConnect'];
            if (!siteList.isEmpty()) {
                userContext.put('siteId', siteList[0].Id);
                userContext.put('sitePath', '/' + siteList[0].UrlPathPrefix);
            }
            return JSON.serialize(userContext);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description fetches the editable fields of an SObject by checking if each of it's fields isn't a calculated formule or an autonum, etc...
     *
     * @param Schema.SObjectType the SObject to which the editable fields are needed
     * @return List<String> the names of editable fields of the SObject
    */
    global static List<String> getObjectEditableFields(Schema.SObjectType sObjectType) {
        List<String> editableFields = new List<String>();
        for (Schema.SObjectField field : sObjectType.getDescribe().fields.getMap().values()) {
            DescribeFieldResult dfr = field.getDescribe();
            if ((dfr.isCustom() || dfr.isNameField() || dfr.getName().equals('CurrencyIsoCode'))
                && !dfr.isCalculated()
                && !dfr.isAutoNumber()
                && dfr.getRelationshipOrder() == null)
            {
                editableFields.add(dfr.getName());
            }
        }

        return editableFields;
    }

    public static FlowWrapper getActiveScreenFlows() {
        try {
            // 1. Query active flows via Tooling API
            String toolingQuery = 'SELECT Id, processType, MasterLabel FROM flow where Status = \'Active\' and ProcessType = \'Flow\'';
            String queryUrl = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query/?q=' + EncodingUtil.urlEncode(toolingQuery, 'UTF-8');

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(queryUrl);
            req.setMethod('GET');
            // Use session ID for authentication
            req.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
            req.setHeader('Content-Type', 'application/json');

            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200) {
                System.debug('Failed to query flows: ' + res.getBody());
                return null;
            }

            // Parse JSON response to get flows
            Map<String, Object> jsonRes = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> flowRecords = (List<Object>) jsonRes.get('records');

            // 1. Query FlowDefinition via Tooling API
            toolingQuery = 'SELECT Id, DeveloperName, ActiveVersionId, NamespacePrefix FROM FlowDefinition';
            queryUrl = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query/?q=' + EncodingUtil.urlEncode(toolingQuery, 'UTF-8');
            http = new Http();
            req = new HttpRequest();
            req.setEndpoint(queryUrl);
            req.setMethod('GET');
            // Use session ID for authentication
            req.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
            req.setHeader('Content-Type', 'application/json');

            res = http.send(req);
            if (res.getStatusCode() != 200) {
                System.debug('Failed to query FlowDefinition: ' + res.getBody());
                return null;
            }

            // Parse JSON response to get flows
            jsonRes = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> flowDefinitionRecords = (List<Object>) jsonRes.get('records');

            return new FlowWrapper(JSON.serialize(flowRecords), JSON.serialize(flowDefinitionRecords));
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
        return null;
    }

    public static String getFlowVariables(String flowApiName) {
        String prefix = flowApiName.split('__').size() > 1 ? flowApiName.split('__')[0] : null;
        String flowName = flowApiName.split('__').size() > 1 ? flowApiName.split('__')[1] : flowApiName.split('__')[0];
        List<FlowVariable> variables = new List<FlowVariable>();
        try {
            // Step 1: Query FlowDefinition to get ActiveVersionId
            String query = 'SELECT Id, ApiName, ActiveVersionId, NamespacePrefix FROM FlowDefinitionView WHERE ApiName = \'' + flowName + '\'';
            if (prefix != null) {
                query += ' AND NamespacePrefix = \'' + prefix + '\'';
            }
            List<FlowDefinitionView > records = Database.query(query);
            if (records.isEmpty()) {
                System.debug('No flow found with DeveloperName: ' + flowApiName);
                return JSON.serialize(variables);
            }
            String activeVersionId = records[0].ActiveVersionId;

            if (activeVersionId == null) {
                System.debug('Flow has no active version.');
                return JSON.serialize(variables);
            }

            // Step 2: Retrieve the flow metadata using the ActiveVersionId
            String flowMetadataUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v58.0/tooling/sobjects/Flow/' + activeVersionId;

            HttpRequest metadataReq = new HttpRequest();
            metadataReq.setEndpoint(flowMetadataUrl);
            metadataReq.setMethod('GET');
            metadataReq.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
            metadataReq.setHeader('Content-Type', 'application/json');
            Http http = new Http();
            HttpResponse metadataRes = http.send(metadataReq);

            if (metadataRes.getStatusCode() != 200) {
                System.debug('Failed to retrieve flow metadata: ' + metadataRes.getBody());
                return JSON.serialize(variables);
            }
            Map<String, Object> flowMetadata = (Map<String, Object>) JSON.deserializeUntyped(metadataRes.getBody());

            // Step 3: Parse the Definition field to get variables
            Map<String, Object> metadataMap = (Map<String, Object>) flowMetadata.get('Metadata');
            if (metadataMap.containsKey('variables')) {
                List<Object> vars = (List<Object>) metadataMap.get('variables');
                for (Object varObj : vars) {
                    Map<String, Object> varMap = (Map<String, Object>) varObj;
                    FlowVariable variable = new FlowVariable();
                    variable.name = (String) varMap.get('name');
                    variable.dataType = (String) varMap.get('dataType');
                    variable.isInput = (Boolean) varMap.get('isInput');
                    variable.isOutput = (Boolean) varMap.get('isOutput');
                    variables.add(variable);
                }
            }

        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage() + ' >> ' + ex.getLineNumber());
        }

        return JSON.serialize(variables);
    }

    public static void sendNotification(Id objectId, String title, String body) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        Id userId = Userinfo.getUserId();
        notification.setBody(body);
        notification.setTitle(title);
        notification.setSenderId(userId);
        CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'BatchNotification'];
        if(type != null) {
            notification.setNotificationTypeId(type.Id);
            notification.setTargetId(objectId);
            notification.send(new Set<String> { userId });
        }
    }

    /**
     * Publish an uploaded file (image, video, etc.) into "Asset Library" and return a stable File Asset URL.
     * Generates/updates ContentAsset + ContentDocument + ContentVersion.
     * Uses DeveloperName derived from filename (via getDevNameofFile) so links are org-agnostic:
     *   returns "/file-asset/<DeveloperName>
     * NOTE: This method is when LWC uses a standard <input type="file"> HTML block"
     * @param base64File Base64 content of the file (any type).
     * @param fileName   Original file name (used to detect MIME via extension).
     * @return           The File Asset URL ("/file-asset/<DeveloperName>").
     */
    public static String uploadAssetFileBase64(String base64File, String fileName) {
        try {
            String devName = getDevNameofFile(fileName);
            Id libraryId = [SELECT Id FROM ContentWorkspace WHERE DeveloperName  = 'sfdc_asset_company_assets' LIMIT 1]?.Id;
            Blob fileBody = EncodingUtil.base64Decode(base64File);
            ContentAsset asset;
            List<ContentAsset> assets = [SELECT Id, DeveloperName FROM ContentAsset WHERE DeveloperName = :devName LIMIT 1];
            asset = assets.isEmpty() ? null : assets[0];
            if (asset == null) {
                asset = new ContentAsset(DeveloperName = devName, MasterLabel = devName);
                insert asset;
            }
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE ContentAssetId = :asset.Id LIMIT 1];
            if (!docs.isEmpty()) {
                ContentDocument existingDoc = docs[0];
                ContentVersion newVersion = new ContentVersion(ContentDocumentId = existingDoc.Id, VersionData = fileBody, Title = devName, PathOnClient = '/' + fileName);
                insert newVersion;
            } else {
                ContentVersion createV = new ContentVersion(VersionData = fileBody, Title = devName, PathOnClient = '/' + fileName, FirstPublishLocationId = libraryId);
                insert createV;
                ContentVersion v = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :createV.Id LIMIT 1];
                update new ContentDocument(Id = v.ContentDocumentId, ContentAssetId = asset.Id);
            }
            return '/file-asset/' + devName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Publish an uploaded file (image, video, etc.) into "Asset Library" and return a stable File Asset URL.
     * Generates/updates ContentAsset + ContentDocument + ContentVersion.
     * Uses DeveloperName derived from filename (via getDevNameofFile) so links are org-agnostic:
     *   returns "/file-asset/<DeveloperName>
     * NOTE: This method is when LWC uses a Lightning File Upload component (<lightning-file-upload>)"
     * @param contentDocumentId ContentDocumentId of the file (any type).
     * @param fileName   Original file name (used to detect MIME via extension).
     * @return           The File Asset URL ("/file-asset/<DeveloperName>").
     */
    public static String uploadAssetFile(String contentDocumentId, String fileName) {
        try {
            List<ContentVersion> cvList = [SELECT VersionData, Title, PathOnClient
                                           FROM ContentVersion
                                           WHERE ContentDocumentId = :contentDocumentId
                                           ORDER BY VersionNumber DESC
                                           LIMIT 1];
            if (cvList != null && !cvList.isEmpty()) {
                ContentVersion original = cvList[0];
                String devName = getDevNameofFile(fileName);
                List<ContentAsset> assets = [SELECT Id, DeveloperName, ContentDocumentId FROM ContentAsset WHERE DeveloperName = :devName LIMIT 1];
                ContentAsset asset = assets.isEmpty() ? null : assets[0];
                // Asset already exists AND is already bound to a ContentDocument -> add new version to existing ContentDocument
                if (asset != null && asset.ContentDocumentId != null) {
                    ContentVersion newVersion = new ContentVersion();
                    newVersion.Title = original.Title;
                    newVersion.PathOnClient = original.PathOnClient;
                    newVersion.VersionData = original.VersionData;
                    newVersion.ContentDocumentId = asset.ContentDocumentId;
                    insert newVersion;
                    return '/file-asset/' + devName;
                }
                // No asset or exists but no file -> create new ContentDocument & link to asset
                Id libraryId = [SELECT Id FROM ContentWorkspace WHERE DeveloperName  = 'sfdc_asset_company_assets' LIMIT 1]?.Id;
                ContentVersion newVersionForNewDoc = new ContentVersion();
                newVersionForNewDoc.Title = original.Title;
                newVersionForNewDoc.PathOnClient = original.PathOnClient;
                newVersionForNewDoc.VersionData = original.VersionData;
                if (libraryId != null) {
                    newVersionForNewDoc.FirstPublishLocationId = libraryId;
                }
                insert newVersionForNewDoc;
                ContentVersion v = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newVersionForNewDoc.Id LIMIT 1];
                if (asset == null) {
                    asset = new ContentAsset(DeveloperName = devName, MasterLabel = devName);
                    insert asset;
                }
                update new ContentDocument(Id = v.ContentDocumentId, ContentAssetId = asset.Id);
                return '/file-asset/' + devName;
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Sanitize filename into ContentAsset DeveloperName
    private static String getDevNameofFile(String fileName) {
        if (String.isBlank(fileName)) return 'Asset_' + String.valueOf(Datetime.now().getTime());
        String base = fileName;
        Integer dot = base.lastIndexOf('.');
        if (dot > 0) base = base.substring(0, dot);
        // keep letters, digits, underscores; collapse others into underscores
        base = base.replaceAll('[^A-Za-z0-9_]+','_');
        base = base.replaceAll('_{2,}','_');
        base = base.trim();
        if (base.endsWith('_')) base = base.substring(0, base.length()-1);
        // DeveloperName rules: begin with a letter, <=40 chars
        if (!Pattern.matches('^[A-Za-z].*', base)) base = 'A_' + base;
        if (base.length() > 40) base = base.substring(0, 40);
        if (base.length() == 0) base = 'Asset_' + String.valueOf(Datetime.now().getTime());
        return base;
    }

    public static Boolean checkLanguageValidity(String language) {
         Schema.DescribeFieldResult dr = User.LanguageLocaleKey.getDescribe();
        List<Schema.PicklistEntry> allLocales = dr.getPicklistValues();
        for (Schema.PicklistEntry availablelang : allLocales) {
            if (availablelang.isActive() && language == availablelang.getValue()) {
                return true;
            }
        }
        return false;
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        String sessionId = getSessionId();
        if (sessionId != null) {
            Http http = new Http();
            HttpRequest httpReq = new HttpRequest();
            HttpResponse httpRes = new HttpResponse();
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
            httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/metadata/deployRequest/' + idDeployment);
            if (!Test.isRunningTest()) {
                try {
                    httpRes = http.send(httpReq);
                    String body = httpRes.getBody();
                    return httpRes.getBody();
                } catch(Exception ex) {
                    System.debug(ex.getMessage());
                    System.debug(ex.getStackTraceString());
                    return ex.getMessage();
            }
        }
            return 'Test Running';
        }
        return 'Session Id Invalid';
    }

    @AuraEnabled
    public static Boolean checkCompletedBatches(String batchJobId) { 
        List<AsyncApexJob> batchJobList = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchJobId LIMIT 1];
        if (!batchJobList.isEmpty()) {
            String st = batchJobList[0].Status;
            return (st == 'Completed' || st == 'Failed' || st == 'Aborted');
        }
        return false;
    }

    public static Map<String, Object> getImportOutcome(Id jobId) {
        // Defensive defaults
        Map<String, Object> res = new Map<String, Object>{
            'hasError' => false,
            'logName' => null,
            'logId' => null
        };
        if (String.isBlank(jobId)) return res;
        try {
            // Ensure Name is INCLUDED to avoid “SObject row… Name” errors
            List<Log__c> logList = [SELECT Id, Name, NumberOfErrors__c, NumberOfWarnings__c
                                    FROM Log__c
                                    WHERE Apex_Job_ID__c = :jobId
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];
            if (logList == null || logList.isEmpty()) return res;
            res.put('hasError', logList.get(0).NumberOfErrors__c > 0 || logList.get(0).NumberOfWarnings__c > 0);
            res.put('logName', logList.get(0).Name);
            res.put('logId', logList.get(0).Id);
            return res;
        } catch (Exception e) {
            // Keep it graceful instead of a hard exception
            return new Map<String, Object>{
                'hasError' => false,
                'logName' => null,
                'logId' => null
            };
        }
    }

    public static Boolean isUserAdmin() { 
        User u = [SELECT Id, Profile.PermissionsModifyAllData,
                  (SELECT PermissionSet.PermissionsModifyAllData FROM PermissionSetAssignments)
                  FROM User
                  WHERE Id = :UserInfo.getUserId()];
        return u.Profile.PermissionsModifyAllData;
    }

    public class FlowWrapper {
        public String flowsSerialized;
        public String flowDefinitionSerialized;

        public FlowWrapper(String flowsSerialized, String flowDefinitionSerialized) {
            this.flowsSerialized = flowsSerialized;
            this.flowDefinitionSerialized = flowDefinitionSerialized;
        }
    }

    public class FlowVariable {
        public String name;
        public String dataType;
        public Boolean isInput;
        public Boolean isOutput;
    }
}