/**
 * @author ULiT
 * @description Helper class for common picklist methods
 *
 * */
global class PicklistHelper {

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
     * get Picklist Translation.
     * @param field: SObject Field
     * @param onlyActive: flag only active picklist values
     * */
    global static Map<String, String> getPicklistTranslationMap(Schema.sObjectField field, Boolean onlyActive) {
        if (field != null) {
            return getPicklistTranslationMap(field.getDescribe(), onlyActive);
        }
        return new Map<String, String>();
    }

    /**
     * get Picklist Translation.
     * @param sObj: SObject to which the field is related to
     * @param fieldName: field api name
     * @param onlyActive: flag only active picklist values
     * */
    global static Map<String, String> getPicklistTranslationMap(Schema.SObjectType sObj, String fieldName, Boolean onlyActive) {
        Map<String, Schema.SObjectField> fieldsMap = sObj.getDescribe().fields.getMap();
        if (sObj != null && fieldName != null && fieldName != '' && fieldsMap.containsKey(NegoptimHelper.normalizeAPIName(fieldName))) {
            return getPicklistTranslationMap(sObj.getDescribe().fields.getMap().get(NegoptimHelper.normalizeAPIName(fieldName)), onlyActive);
        }
        return new Map<String, String>();
    }

    /**
     * get Picklist Default value by record type Id.
     * @param sObj: SObject to which the field is related to
     * @param field: field: SObject Field
     * @param recordTypeId: RecordType Id
     * */
    global static Object getPicklistDefaultValueByRecordTypeId(Schema.SObjectType sObj, Schema.DescribeFieldResult field, Id recordTypeId) {
        Id rtId = recordTypeId != null ? recordTypeId : NegoptimHelper.getObjectDefaultRecordTypeId(sObj.getDescribe().getName());
        return sObj.newSObject(rtId, true).get(field.getName());
    }

    /**
     * get Picklist Translation by Record Type Id.
     * @param sObj: SObject to which the field is related to
     * @param field: field: SObject Field
     * @param recordTypeId: RecordType Id
     * */
    public static List<SelectOption> getPicklistOptionListByRecordTypeId(Schema.SObjectType sObj, Schema.sObjectField field, Id recordTypeId){
        system.debug('sObj >> ' + sObj.getDescribe().getName());
        system.debug('recordTypeId >> ' + recordTypeId);
        system.debug('field >> ' + field.getDescribe().getName());
        List<SelectOption> pickListOptionList = new List<SelectOption>();
        String sessionId = NegoptimHelper.getSessionId();
        if (sessionId != null) {
            try {
                Http http = new Http();
                HttpRequest httpReq = new HttpRequest();
                HttpResponse httpRes = new HttpResponse();
                httpReq.setMethod('GET');
                httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
                httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/ui-api/object-info/' + sObj.getDescribe().getName() + '/picklist-values/' + recordTypeId + '/' + field.getDescribe().getName());
                httpRes = http.send(httpReq);
                System.debug('body :>>>>' + httpRes.getBody());
                String body = httpRes.getBody();
                if (body.containsIgnoreCase('errorCode')) {
                    List<ResultWrapper> rwList = (List<ResultWrapper>)JSON.deserialize(body, List<ResultWrapper>.class);
                    for (ResultWrapper rw : rwList) {
                        if (rw.message != null && String.isNotBlank(rw.message)) {
                            if (ApexPages.currentPage() != null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rw.message));
                            } else {
                                System.debug('Error:>>>>' + rw.message);
                            }
                        }
                    }
                } else {
                    try {
                        ResultWrapper rw = (ResultWrapper)JSON.deserialize(httpRes.getBody(), ResultWrapper.class);
                        if (rw.values != null) {
                            for (SelectOption plvw : rw.values) {
                                pickListOptionList.add(new SelectOption(plvw.value.unescapeHtml4(), plvw.label.unescapeHtml4()));
                            }
                        }
                    } catch (Exception ex2) {
                        System.debug('ERROR:>>>>>'+ex2.getMessage() + '>>>>>>>' + ex2.getStackTraceString());
                        if (ApexPages.currentPage() != null)
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex2.getMessage() + ' - ' + ex2.getLineNumber()));
                    }
                }
            } catch (Exception ex) {
                System.debug('ERROR:>>>>>'+ex.getMessage() + '>>>>>>>' + ex.getStackTraceString());
                if (ApexPages.currentPage() != null)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' - ' + ex.getLineNumber()));
            }
        }
        return pickListOptionList;
    }

    /**
     * get Picklist Translation by Record Type Id.
     * @param sObj: SObject to which the field is related to
     * @param field: field: SObject Field
     * @param recordTypeId: RecordType Id
     * */
    global static Map<String, String> getPicklistValuesByRecordTypeId(Schema.SObjectType sObj, Schema.sObjectField field, Id recordTypeId){
        system.debug('sObj >> ' + sObj.getDescribe().getName());
        system.debug('recordTypeId >> ' + recordTypeId);
        system.debug('field >> ' + field.getDescribe().getName());
        Map<String, String> pickListTranslationMap = new Map<String, String>();
        String sessionId = NegoptimHelper.getSessionId();
        if (sessionId != null) {
            try {
                Http http = new Http();
                HttpRequest httpReq = new HttpRequest();
                HttpResponse httpRes = new HttpResponse();
                httpReq.setMethod('GET');
                httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
                httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/ui-api/object-info/' + sObj.getDescribe().getName() + '/picklist-values/' + recordTypeId + '/' + field.getDescribe().getName());
                httpRes = http.send(httpReq);
                System.debug('body :>>>>' + httpRes.getBody());
                String body = httpRes.getBody();
                if (body.containsIgnoreCase('errorCode')) {
                    List<ResultWrapper> rwList = (List<ResultWrapper>)JSON.deserialize(body, List<ResultWrapper>.class);
                    for (ResultWrapper rw : rwList) {
                        if (rw.message != null && String.isNotBlank(rw.message)) {
                            if (ApexPages.currentPage() != null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rw.message));
                            } else {
                                System.debug('Error:>>>>' + rw.message);
                            }
                        }
                    }
                } else {
                    try {
                        ResultWrapper rw = (ResultWrapper)JSON.deserialize(httpRes.getBody(), ResultWrapper.class);
                        if (rw.values != null) {
                            for (SelectOption plvw : rw.values) {
                                pickListTranslationMap.put(plvw.value.unescapeHtml4(), plvw.label.unescapeHtml4());
                            }
                        }
                    } catch (Exception ex2) {
                        System.debug('ERROR:>>>>>'+ex2.getMessage() + '>>>>>>>' + ex2.getStackTraceString());
                        if (ApexPages.currentPage() != null)
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex2.getMessage() + ' - ' + ex2.getLineNumber()));
                    }
                }
            } catch (Exception ex) {
                System.debug('ERROR:>>>>>'+ex.getMessage() + '>>>>>>>' + ex.getStackTraceString());
                if (ApexPages.currentPage() != null)
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' - ' + ex.getLineNumber()));
            }
        }
        return pickListTranslationMap;
    }
    public static  Map<Id, Map<String, Map<String, String>>> getPicklistValuesByRecordTypeIds(Schema.SObjectType sObj, List<Schema.SObjectField> fields, List<Id> recordTypeIds) {
        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        Map<Id, Map<String, Map<String, String>>> picklistValuesPerRT = new Map<Id, Map<String, Map<String, String>>>();
        String sessionId = NegoptimHelper.getSessionId();

        if (sessionId == null || fields == null || fields.isEmpty()) {
            return picklistValuesPerRT;
        }

        Http http = new Http();

        for (Id RTId : recordTypeIds) {
            for (Schema.SObjectField field : fields) {
                Map<String, String> pickListTranslationMap = new Map<String, String>();
                try {
                    HttpRequest httpReq = new HttpRequest();
                    HttpResponse httpRes = new HttpResponse();
                    httpReq.setMethod('GET');
                    httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
                    httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/ui-api/object-info/' + sObj.getDescribe().getName() + '/picklist-values/' + RTId + '/' + field.getDescribe().getName());
                    httpRes = http.send(httpReq);
                    String body = httpRes.getBody();
                    if (body.containsIgnoreCase('errorCode')) {
                        List<ResultWrapper> rwList = (List<ResultWrapper>)JSON.deserialize(body, List<ResultWrapper>.class);
                        for (ResultWrapper rw : rwList) {
                            if (rw.message != null && String.isNotBlank(rw.message)) {
                                if (ApexPages.currentPage() != null) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, rw.message));
                                } else {
                                    System.debug('Error:>>>>' + rw.message);
                                }
                            }
                        }
                    } else {
                        try {
                            ResultWrapper rw = (ResultWrapper)JSON.deserialize(httpRes.getBody(), ResultWrapper.class);
                            if (rw.values != null) {
                                for (SelectOption plvw : rw.values) {
                                    pickListTranslationMap.put(plvw.value.unescapeHtml4(), plvw.label.unescapeHtml4());
                                }
                            }
                        } catch (Exception ex2) {
                            System.debug('ERROR:>>>>>'+ex2.getMessage() + '>>>>>>>' + ex2.getStackTraceString());
                            if (ApexPages.currentPage() != null)
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex2.getMessage() + ' - ' + ex2.getLineNumber()));
                        }
                    }

                } catch (Exception ex) {
                    System.debug('ERROR field ' + field.getDescribe().getName() +' : ' + ex.getMessage());
                }

                result.put(field.getDescribe().getName(), pickListTranslationMap);
                picklistValuesPerRT.put(RTId, result);
            }
        }

        return picklistValuesPerRT;
    }

    /**
     * get picklist dependencies
     * @param depend: the describing field result of the dependee
     * @return: Map for each Picklist and the list of dependant picklists
     * */
    global static Map<String, List<String>> getDependentPicklistChildrens(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }

    /**
     * get picklist dependencies
     * @param depend: the describing field result of the dependee
     * @return: Map for each Picklist and parent dependant picklist
     * */
    global static Map<String, String> getDependentPicklistParents(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, String>();
        }
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String, String> dependentPicklistValues = new Map<String, String>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    dependentPicklistValues.put(entry.getValue(), (String) controlValue);
                }
            }
        }
        return dependentPicklistValues;
    }

    public class PickListEntryWrapper {
        public SelectOption pickListEntry;
        public List<SelectOption> dependeeEntriesList;
        public PickListEntryWrapper(SelectOption pickListEntry, List<SelectOption> dependeeEntriesList) {
            this.pickListEntry = pickListEntry;
            this.dependeeEntriesList = dependeeEntriesList;
        }
    }

    private class ResultWrapper {
        public List<SelectOption> values;
        public String errorCode;
        public String message;
    }

    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}