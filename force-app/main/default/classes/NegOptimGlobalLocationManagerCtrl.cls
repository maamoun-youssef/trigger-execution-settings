public with sharing class NegOptimGlobalLocationManagerCtrl {
    @AuraEnabled
    public static String getData(string recordId) {
        try {
            ResultWrapper resultWrapper = new ResultWrapper();
            User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
            String objectName;
            String prefix = NegoptimHelper.getPackagePrefix(true);
            if (String.isNotBlank(recordId)) {
                objectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
                if (objectName == 'Supplier__c') {
                    resultWrapper.supplierId = recordId;
                }
            }
            else if (user.ContactId != null) {
                objectName = 'Supplier__c';
                recordId = user.Account.Supplier__c;
                resultWrapper.supplierId = recordId;
            }
            if (String.isNotBlank(recordId) && String.isNotBlank(objectName)) {
                OrgSettings orgSettings = OrgSettings.loadOrgSettings();
                resultWrapper.stickerSettings = orgSettings.globalLocationStickerFields;
                Set<String> fieldsToQuery = new Set<String>{
                    'Id',
                    'Name',
                    'Functions__c',
                    'Status__c',
                    'GLN__c',
                    'LongName__c',
                    'CompanyName__c',
                    'Supplier__c',
                    'BusinessUnit__c',
                    'Country__c',
                    'OwnerId',
                    'ReferenceLanguage__c',
                    'StatusBDate__c',
                    'StatusEdate__c'
                };
                if (resultWrapper.stickerSettings != null && !resultWrapper.stickerSettings.isEmpty()) {
                    for (List<String> fields : resultWrapper.stickerSettings) {
                        for (String field : fields) {
                            if (!String.isBlank(field)) {
                                Schema.DescribeFieldResult fieldDescribe = SObjectType.GlobalLocation__c.fields.getMap().get(field).getDescribe();
                                Boolean isReference = fieldDescribe.getType() == Schema.DisplayType.REFERENCE;
                                if (isReference) {
                                    fieldsToQuery.add(field.replace(prefix, '').replace('__c', '') + '__r.Name');
                                } else {
                                    fieldsToQuery.add(field.replace(prefix, ''));
                                }
                            }
                        }
                    }
                    String query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') + ' FROM GlobalLocation__c ';
                    query += 'WHERE ' + objectName + ' = \'' + recordId + '\' ';
                    query += 'ORDER BY Name ASC';
                    resultWrapper.globalLocations = Database.query(query);
                } else {
                    resultWrapper.globalLocations = new List<GlobalLocation__c>();
                }
            } else {
                resultWrapper.globalLocations = new List<GlobalLocation__c>();
            }
            resultWrapper.objectName = objectName;
            resultWrapper.prefix = prefix;
            resultWrapper.isPortalUser = user.ContactId != null;
            resultWrapper.isOrgAdmin = (user.ContactId != null && user.Contact.IsOrgAdmin__c == true);
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    @AuraEnabled
    public static String saveData(string supplierId, string globalLocationId, Boolean toDeactivate) {
        String exceptionMessage = '';
        GlobalLocation__c toUpsertGl = [SELECT Id, Status__c
                                        FROM GlobalLocation__c
                                        WHERE Id = :globalLocationId][0];
        if (toDeactivate){
            toUpsertGl.Status__c = 'Closed';
        }
        if (!toDeactivate){
            toUpsertGl.Status__c = 'Open';
        }
        if (toUpsertGl != null) {
                try {
                    upsert toUpsertGl;
                    exceptionMessage = 'SUCCESS';
                } catch(DmlException ex) {
                    exceptionMessage += ex.getMessage();
                }
            }
        return exceptionMessage;

    }
    public class ResultWrapper {
        public List<GlobalLocation__c> globalLocations;
        List<List<String>> stickerSettings;
        String objectName;
        String prefix;
        Boolean isPortalUser;
        Boolean isOrgAdmin;
        public String supplierId;
        public Map<String, Map<String, String>> picklistLabelsMap {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public ResultWrapper() {
            this.stickerSettings = new List<List<String>>();
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.GlobalLocation__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(), field.getDescribe());
                }
            }
            this.picklistLabelsMap = new Map<String, Map<String, String>>();
            this.picklistLabelsMap.put(SObjectType.GlobalLocation__c.getName() + '-' + SObjectType.GlobalLocation__c.fields.Functions__c.Name, new Map<String, String>());
            for (Schema.PicklistEntry pickListVal : GlobalLocation__c.Functions__c.getDescribe().getPicklistValues()) {
                this.picklistLabelsMap.get(SObjectType.GlobalLocation__c.getName() + '-' + SObjectType.GlobalLocation__c.fields.Functions__c.Name).put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
    }

    @AuraEnabled
    public static String upsertGlobalLocation(String globalLocationJson) {
        try {
            Map<String, Object> raw =
            (Map<String, Object>) JSON.deserializeUntyped(globalLocationJson);

            if (raw.get('StatusBDate__c') == '') {
                raw.put('StatusBDate__c', null);
            }
            if (raw.get('StatusEdate__c') == '') {
                raw.put('StatusEdate__c', null);
            }
            GlobalLocation__c gl =
                (GlobalLocation__c) JSON.deserialize(JSON.serialize(raw), GlobalLocation__c.class);
                    upsert gl;
                    System.debug('DEBUG>>> After upsert - Id: ' + gl.Id);
                    return JSON.serialize(new Map<String, Object>{
                        'success' => true,
                        'id' => gl.Id,
                        'message' => gl.Id != null ? 'Global Location updated successfully' : 'Global Location created successfully'
                    });
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }
}