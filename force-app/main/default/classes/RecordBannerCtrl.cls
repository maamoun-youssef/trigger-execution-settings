/**
 * @author ULiT
 * @date 2026
 * @description Apex controller for reusable Record Banner LWC
 */
public without sharing class RecordBannerCtrl {
    @AuraEnabled
    public static BannerDataWrapper getBannerData(Id recordId, String objectApiName, String titleFieldApiName, String detailFieldsApiNames) {
        try {
            if (recordId == null || String.isBlank(objectApiName) || String.isBlank(titleFieldApiName)) {
                throw new AuraHandledException('Record id, object api name and title field are required.');
            }
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null) {
                throw new AuraHandledException('Invalid object api name: ' + objectApiName);
            }
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            if (!fieldsMap.containsKey(titleFieldApiName)) {
                throw new AuraHandledException('Title field not found: ' + titleFieldApiName);
            }

            String safeObjectName = String.escapeSingleQuotes(objectApiName);
            String safeTitleField = String.escapeSingleQuotes(titleFieldApiName);
            String query = 'SELECT Id, ' + safeTitleField;
            List<String> detailFields = parseCsv(detailFieldsApiNames);
            for (String fieldApiName : detailFields) {
                if (!fieldsMap.containsKey(fieldApiName)) {
                    throw new AuraHandledException('Detail field not found: ' + fieldApiName);
                }
                query += ', ' + String.escapeSingleQuotes(fieldApiName);
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldApiName).getDescribe();
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE && !String.isBlank(fieldDescribe.getRelationshipName())) {
                    query += ', ' + fieldDescribe.getRelationshipName() + '.Name';
                }
            }
            query += ' FROM ' + safeObjectName + ' WHERE Id = :recordId LIMIT 1';
            SObject recordData = Database.query(query);
            BannerDataWrapper wrapper = new BannerDataWrapper();
            wrapper.recordId = (String) recordData.get('Id');
            wrapper.objectApiName = objectApiName;
            wrapper.objectLabel = describeResult.getLabel();
            wrapper.titleValue = stringifyFieldValue(recordData.get(titleFieldApiName));
            wrapper.detailFields = new List<BannerDetailFieldWrapper>();
            for (String fieldApiName : detailFields) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldApiName).getDescribe();
                BannerDetailFieldWrapper detail = new BannerDetailFieldWrapper();
                detail.apiName = fieldApiName;
                detail.label = fieldDescribe.getLabel();
                detail.value = formatFieldValue(recordData.get(fieldApiName), fieldDescribe);
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    detail.lookupRecordId = stringifyFieldValue(recordData.get(fieldApiName));
                    detail.lookupDisplayValue = resolveLookupName(recordData, fieldDescribe);
                    if (!String.isBlank(detail.lookupDisplayValue)) {
                        detail.value = detail.lookupDisplayValue;
                    }
                }
                wrapper.detailFields.add(detail);
            }
            return wrapper;
        } catch (Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<BannerActionWrapper> getObjectActions(String objectApiName) {
        try {
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object api name is required.');
            }

            List<BannerActionWrapper> actions = new List<BannerActionWrapper>();
            Set<String> uniqueKeys = new Set<String>();
            Integer indexCounter = 0;
            for (PlatformAction pAction : [SELECT ApiName, Label, Type, ActionListContext, SourceEntity, ActionTarget
                                            FROM PlatformAction
                                            WHERE SourceEntity = :objectApiName
                                            AND ActionListContext IN ('Assistant', 'BannerPhoto', 'Chatter', 'Dockable', 'FeedElement',
                                            'Flexipage', 'ListView', 'ListViewDefinition', 'ListViewRecord', 'Lookup', 'MruList',
                                            'MruRow', 'ObjectHomeChart', 'Photo', 'Record', 'RecordEdit', 'RelatedList','RelatedListRecord')
                                            ORDER BY Label])
            {
                if (String.isBlank(pAction.Label)) {
                    continue;
                }
                indexCounter++;
                BannerActionWrapper item = new BannerActionWrapper();
                item.label = pAction.Label;
                item.name = String.isBlank(pAction.ApiName) ? buildFallbackActionName(pAction.Label, indexCounter) : pAction.ApiName;
                item.type = String.isBlank(pAction.Type) ? 'quickAction' : pAction.Type;
                item.apiName = pAction.ApiName;
                item.targetUrl = pAction.ActionTarget;
                String uniqueKey = normalizeKey(item.label) + '|' + normalizeKey(item.name);
                if (!uniqueKeys.contains(uniqueKey)) {
                    uniqueKeys.add(uniqueKey);
                    actions.add(item);
                }
            }

            for (WebLink detailButton : [SELECT Id, Name, MasterLabel, DisplayType, LinkType, Url
                                        FROM WebLink
                                        WHERE PageOrSobjectType = :objectApiName])
        {
                if (detailButton == null || String.isBlank(detailButton.MasterLabel)) {
                    continue;
                }
                BannerActionWrapper buttonAction = new BannerActionWrapper();
                buttonAction.label = detailButton.MasterLabel;
                buttonAction.name = String.isBlank(detailButton.Name)
                    ? buildFallbackActionName(detailButton.MasterLabel, indexCounter + 1)
                    : detailButton.Name;
                buttonAction.type = 'detailButton';
                buttonAction.apiName = detailButton.Name;
                buttonAction.targetUrl = detailButton.Url;
                String uniqueKey = normalizeKey(buttonAction.label) + '|' + normalizeKey(buttonAction.name);
                if (!uniqueKeys.contains(uniqueKey)) {
                    uniqueKeys.add(uniqueKey);
                    actions.add(buttonAction);
                }
            }
            return actions;
        } catch (Exception e) {
            System.debug('e ' + e.getStackTraceString() + ' - ' + e.getLineNumber() + '- ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String stringifyFieldValue(Object value) {
        if (value == null) {
            return '';
        }
        return String.valueOf(value);
    }

    private static String formatFieldValue(Object value, Schema.DescribeFieldResult fieldDescribe) {
        if (value == null) {
            return '';
        }
        if (fieldDescribe != null && fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
            return ((Datetime) value).format('yyyy-MM-dd HH:mm');
        }
        if (fieldDescribe != null && fieldDescribe.getType() == Schema.DisplayType.DATE) {
            return ((Date) value).format();
        }
        return String.valueOf(value);
    }

    private static String resolveLookupName(SObject recordData, Schema.DescribeFieldResult fieldDescribe) {
        if (recordData == null || fieldDescribe == null || String.isBlank(fieldDescribe.getRelationshipName())) {
            return '';
        }
        SObject relatedRecord = recordData.getSObject(fieldDescribe.getRelationshipName());
        if (relatedRecord == null) {
            return '';
        }
        Object relatedName = relatedRecord.get('Name');
        return stringifyFieldValue(relatedName);
    }

    private static List<String> parseCsv(String csv) {
        List<String> output = new List<String>();
        if (String.isBlank(csv)) {
            return output;
        }
        for (String item : csv.split(',')) {
            String value = item == null ? '' : item.trim();
            if (!String.isBlank(value)) {
                output.add(value);
            }
        }
        return output;
    }

    private static String normalizeKey(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    private static String buildFallbackActionName(String label, Integer indexCounter) {
        String raw = String.isBlank(label) ? '' : label.trim().toLowerCase();
        String normalized = raw.replaceAll('[^a-z0-9]+', '_');
        normalized = normalized.replaceAll('^_+', '').replaceAll('_+$', '');
        if (String.isBlank(normalized)) {
            return 'dynamic_action_' + String.valueOf(indexCounter);
        }
        return normalized;
    }

    public class BannerDataWrapper {
        @AuraEnabled public String recordId { get; set; }
        @AuraEnabled public String objectApiName { get; set; }
        @AuraEnabled public String objectLabel { get; set; }
        @AuraEnabled public String titleValue { get; set; }
        @AuraEnabled public List<BannerDetailFieldWrapper> detailFields { get; set; }
    }

    public class BannerActionWrapper {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String targetUrl { get; set; }
    }

    public class BannerDetailFieldWrapper {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String lookupRecordId { get; set; }
        @AuraEnabled public String lookupDisplayValue { get; set; }
    }
}