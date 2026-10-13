/**
 * @description Apex controller for Banner Settings Plugin LWC.
 */
public without sharing class BannerSettingsPluginCmpController {
    @AuraEnabled
    public static String getBannerData(Id recordId, String objectApiName, String titleFieldApiName, String detailFieldsApiNames) {
        try {
            List<BannerFieldConfig> fieldConfigs = new List<BannerFieldConfig>();
            for (String fieldApiName : parseCsv(detailFieldsApiNames)) {
                BannerFieldConfig item = new BannerFieldConfig();
                item.fieldApiName = fieldApiName;
                item.labelPosition = 'above';
                fieldConfigs.add(item);
            }
            return JSON.serialize(buildBannerData(recordId, objectApiName, titleFieldApiName, null, fieldConfigs, null, null, null));
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getConfiguredBannerData(Id recordId, String bannerConfigName) {
        try {
            if (String.isBlank(bannerConfigName)) {
                throw new AuraHandledException('Banner configuration name is required.');
            }
            List<BannerSetting__mdt> configs = [SELECT DeveloperName, MasterLabel, ObjectAPIName__c, TitleFieldAPI__c, SubTitleFieldAPI__c,
                                                DetailFields__c, SelectedActions__c, IconSource__c, IconValue__c, IconSize__c, DisplayMode__c, NumberOfFieldsDisplay__c,
                                                BackgroundColor__c, TextColor__c, IsActive__c
                                                FROM BannerSetting__mdt
                                                WHERE DeveloperName = :bannerConfigName
                                                LIMIT 1];
            if (configs.isEmpty()) {
                throw new AuraHandledException('Banner setting not found: ' + bannerConfigName);
            }
            BannerSetting__mdt metadataItem = configs[0];
            if (String.isBlank(metadataItem.ObjectAPIName__c)) {
                throw new AuraHandledException('Object API name is missing in banner setting: ' + bannerConfigName);
            } 
            BannerDataWrapper wrapper = buildBannerData(recordId, metadataItem.ObjectAPIName__c, metadataItem.TitleFieldAPI__c, metadataItem.SubTitleFieldAPI__c,
                                                        parseDetailFieldConfigsFromJson(metadataItem.DetailFields__c), String.join(parseJsonStringList(metadataItem.SelectedActions__c), ','),
                                                        metadataItem.IconSource__c, metadataItem.IconValue__c);
            wrapper.selectedActionsJson = metadataItem.SelectedActions__c;
            wrapper.screenFlows = parseScreenFlows(metadataItem.SelectedActions__c);
            wrapper.displayMode = String.isBlank(metadataItem.DisplayMode__c) ? 'horizontal' : metadataItem.DisplayMode__c;
            wrapper.iconSize = String.isBlank(metadataItem.IconSize__c) ? '30px' : metadataItem.IconSize__c;
            wrapper.backgroundColor = String.isBlank(metadataItem.BackgroundColor__c) ? '#ffffff' : metadataItem.BackgroundColor__c;
            wrapper.textColor = String.isBlank(metadataItem.TextColor__c) ? '#16325c' : metadataItem.TextColor__c;
            wrapper.isActive = metadataItem.IsActive__c == null ? true : metadataItem.IsActive__c;
            Integer fieldsPerLine = metadataItem.NumberOfFieldsDisplay__c == null ? 1 : Integer.valueOf(metadataItem.NumberOfFieldsDisplay__c);
            wrapper.numberOfFieldsDisplay = fieldsPerLine < 1 ? 1 : fieldsPerLine;
            wrapper.configurationName = metadataItem.DeveloperName;
            wrapper.configurationLabel = metadataItem.MasterLabel;
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getObjectActions(String objectApiName) {
        return JSON.serialize(getObjectActionsList(objectApiName));
    }

    public static List<BannerActionWrapper> getObjectActionsList(String objectApiName) {
        try {
            Boolean isLayoutable = [SELECT IsLayoutable FROM EntityDefinition WHERE QualifiedApiName = :objectApiName LIMIT 1].IsLayoutable;
            List<BannerActionWrapper> actions = new List<BannerActionWrapper>();
            Set<String> uniqueKeys = new Set<String>();
            Integer indexCounter = 0;
            if (isLayoutable) {
                for (PlatformAction pAction : [SELECT ApiName, Label, Type, ActionListContext, SourceEntity, ActionTarget
                                                FROM PlatformAction
                                                WHERE SourceEntity = :objectApiName
                                                AND ActionListContext IN ('Assistant', 'BannerPhoto', 'Chatter', 'Dockable', 'FeedElement',
                                                'Flexipage', 'ListView', 'ListViewDefinition', 'ListViewRecord', 'Lookup', 'MruList',
                                                'MruRow', 'ObjectHomeChart', 'Photo', 'Record', 'RecordEdit', 'RelatedList','RelatedListRecord')
                                                ORDER BY Label]) {
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
                                            WHERE PageOrSobjectType = :objectApiName]) {
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
            }
            return actions;
        } catch (Exception e) {
            System.debug('error : ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static BannerDataWrapper buildBannerData(Id recordId, String objectApiName, String titleFieldApiName, String subtitleFieldApiName, List<BannerFieldConfig> detailFieldConfigs,
                                                     String selectedActionApiNames, String iconType, String iconValue)
    {
        if (recordId == null || String.isBlank(objectApiName) || String.isBlank(titleFieldApiName)) {
            throw new AuraHandledException('Record id, object api name and title field are required.');
        }
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjectType == null) {
            throw new AuraHandledException('Invalid object api name: ' + objectApiName);
        }
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        System.debug('>objectApiName ' + objectApiName);
        System.debug('>fieldsMap ' + json.serialize(fieldsMap.keySet()));
        System.debug('>titleFieldApiName ' + titleFieldApiName);
        if (!validateFieldExists(describeResult, titleFieldApiName, 'Title')) {
            throw new AuraHandledException('Title field not found: ' + titleFieldApiName);
        }
        if (String.isNotBlank(subtitleFieldApiName)) {
            if (!validateFieldExists(describeResult, subtitleFieldApiName, 'Subtitle')) {
                subtitleFieldApiName = null;
            }
        }
        Set<String> selectFields = new Set<String>{ 'Id', titleFieldApiName };
        Set<String> relationshipFields = new Set<String>();
        if (String.isNotBlank(subtitleFieldApiName)) {
            selectFields.add(subtitleFieldApiName);
            addLookupNameField(fieldsMap, subtitleFieldApiName, relationshipFields);
        }
        for (BannerFieldConfig fieldConfig : detailFieldConfigs) {
            if (fieldConfig == null || String.isBlank(fieldConfig.fieldApiName)) {
                continue;
            }
            if (!validateFieldExists(describeResult, fieldConfig.fieldApiName, 'Detail')) {
                continue;
            }
            selectFields.add(fieldConfig.fieldApiName);
            addLookupNameField(fieldsMap, fieldConfig.fieldApiName, relationshipFields);
        }

        List<String> queryParts = new List<String>();
        queryParts.addAll(selectFields);
        queryParts.addAll(relationshipFields);
        String query = 'SELECT ' + String.join(queryParts, ', ') + ' FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
        System.debug('>query ' + query);    
        SObject recordData = Database.query(query);
        BannerDataWrapper wrapper = new BannerDataWrapper();
        wrapper.recordId = (String) recordData.get('Id');
        wrapper.objectApiName = objectApiName;
        wrapper.objectLabel = describeResult.getLabel();
        wrapper.titleValue = stringifyFieldValue(getFieldValueByPath(recordData, titleFieldApiName));
        wrapper.selectedActionApiNames = selectedActionApiNames;
        wrapper.iconType = String.isBlank(iconType) ? 'standard' : iconType;
        wrapper.iconValue = iconValue;
        wrapper.iconSize = '30px';
        wrapper.backgroundColor = '#ffffff';
        wrapper.textColor = '#16325c';
        wrapper.isActive = true;
        if (String.isNotBlank(subtitleFieldApiName)) {
            wrapper.subtitleField = buildBannerField(recordData, describeResult, subtitleFieldApiName, new BannerFieldConfig());
        }
        wrapper.detailFields = new List<BannerDetailFieldWrapper>();
        for (BannerFieldConfig fieldConfig : detailFieldConfigs) {
            if (fieldConfig == null || String.isBlank(fieldConfig.fieldApiName)) {
                continue;
            }
            if (!validateFieldExists(describeResult, fieldConfig.fieldApiName, 'Detail')) {
                continue;
            }
            wrapper.detailFields.add(buildBannerField(recordData, describeResult, fieldConfig.fieldApiName, fieldConfig));
        }
        return wrapper;
    }

    private static List<String> parseJsonStringList(String jsonValue) {
        List<String> output = new List<String>();
        if (String.isBlank(jsonValue)) {
            return output;
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonValue);
            if (parsed instanceof List<Object>) {
                for (Object item : (List<Object>) parsed) {
                    output.add(String.valueOf(item));
                }
            } else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> parsedMap = (Map<String, Object>) parsed;
                if (parsedMap.containsKey('quickActions') && parsedMap.get('quickActions') instanceof List<Object>) {
                    for (Object item : (List<Object>) parsedMap.get('quickActions')) {
                        output.add(String.valueOf(item));
                    }
                }
            }
        } catch (Exception ex) {
            output.addAll(parseCsv(jsonValue));
        }
        return output;
    }

    private static List<Object> parseScreenFlows(String jsonValue) {
        List<Object> output = new List<Object>();
        if (String.isBlank(jsonValue)) {
            return output;
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonValue);
            if (parsed instanceof Map<String, Object>) {
                Map<String, Object> parsedMap = (Map<String, Object>) parsed;
                if (parsedMap.containsKey('screenFlows') && parsedMap.get('screenFlows') instanceof List<Object>) {
                    output.addAll((List<Object>) parsedMap.get('screenFlows'));
                }
            }
        } catch (Exception ex) {
            // ignore invalid json payload
        }
        return output;
    }

    private static List<BannerFieldConfig> parseDetailFieldConfigsFromJson(String jsonValue) {
        if (String.isBlank(jsonValue)) {
            return new List<BannerFieldConfig>();
        }
        try {
            Object parsed = JSON.deserializeUntyped(jsonValue);
            if (parsed instanceof List<Object>) {
                return parseDetailFieldConfigs((List<Object>) parsed);
            }
        } catch (Exception ex) {
            return new List<BannerFieldConfig>();
        }
        return new List<BannerFieldConfig>();
    }

    private static BannerDetailFieldWrapper buildBannerField(SObject recordData, Schema.DescribeSObjectResult rootDescribe, String fieldApiName,BannerFieldConfig fieldConfig) {
        FieldPathDescribe pathDescribe = describeFieldPath(rootDescribe, fieldApiName);
        Schema.DescribeFieldResult fieldDescribe = pathDescribe != null ? pathDescribe.fieldDescribe : null;
        BannerDetailFieldWrapper detail = new BannerDetailFieldWrapper();
        detail.apiName = fieldApiName;
        detail.label = fieldDescribe != null ? fieldDescribe.getLabel() : fieldApiName;
        detail.value = formatFieldValue(getFieldValueByPath(recordData, fieldApiName), fieldDescribe);
        detail.color = fieldConfig != null ? fieldConfig.color : null;
        detail.bold = fieldConfig != null ? fieldConfig.bold : false;
        detail.italic = fieldConfig != null ? fieldConfig.italic : false;
        detail.underline = fieldConfig != null ? fieldConfig.underline : false;
        detail.labelPosition = fieldConfig != null && String.isNotBlank(fieldConfig.labelPosition) ? fieldConfig.labelPosition : 'above';
        detail.labelMode = fieldConfig != null && String.isNotBlank(fieldConfig.labelMode) ? fieldConfig.labelMode : 'fieldLabel';
        detail.customLabel = fieldConfig != null ? fieldConfig.customLabel : null;
        detail.labelIcon = fieldConfig != null && String.isNotBlank(fieldConfig.labelIcon) ? fieldConfig.labelIcon : 'utility:info';
        if (fieldDescribe != null && fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
            detail.lookupRecordId = stringifyFieldValue(getFieldValueByPath(recordData, fieldApiName));
            detail.lookupDisplayValue = resolveLookupName(recordData, fieldDescribe);
            if (!String.isBlank(detail.lookupDisplayValue)) {
                detail.value = detail.lookupDisplayValue;
            }
        }
        if (String.isBlank(detail.lookupRecordId)) {
            detail.lookupRecordId = resolveRelatedRecordId(recordData, fieldApiName);
        }
        return detail;
    }

    private static Boolean validateFieldExists(Schema.DescribeSObjectResult describeResult, String fieldApiName, String fieldRole) {
        if (String.isBlank(fieldApiName)) {
            return false;
        }
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        if (fieldsMap.containsKey(fieldApiName)) {
            return true;
        }
        if (fieldApiName.contains('.')) {
            FieldPathDescribe pathDescribe = describeFieldPath(describeResult, fieldApiName);
            return pathDescribe != null && pathDescribe.fieldDescribe != null;
        }
        return false;
    }

    private static void addLookupNameField(Map<String, Schema.SObjectField> fieldsMap, String fieldApiName, Set<String> relationshipFields) {
        if (String.isBlank(fieldApiName) || fieldsMap == null) {
            return;
        }
        String rootFieldApiName = fieldApiName;
        if (!fieldsMap.containsKey(rootFieldApiName) && fieldApiName.contains('.')) {
            rootFieldApiName = fieldApiName.split('\\.')[0];
        }
        if (!fieldsMap.containsKey(rootFieldApiName)) {
            return;
        }
        Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(rootFieldApiName).getDescribe();
        if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE && String.isNotBlank(fieldDescribe.getRelationshipName())) {
            relationshipFields.add(fieldDescribe.getRelationshipName() + '.Name');
        }
    }

    private static List<BannerFieldConfig> parseDetailFieldConfigs(List<Object> rawFieldConfigs) {
        List<BannerFieldConfig> output = new List<BannerFieldConfig>();
        if (rawFieldConfigs == null) {
            return output;
        }
        for (Object rawItem : rawFieldConfigs) {
            if (!(rawItem instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> item = (Map<String, Object>) rawItem;
            BannerFieldConfig config = new BannerFieldConfig();
            config.fieldApiName = stringValue(item, new List<String>{ 'fieldApiName', 'fieldName', 'apiName', 'name' });
            config.color = (String) item.get('color');
            config.bold = booleanValue(item.get('bold'));
            config.italic = booleanValue(item.get('italic'));
            config.underline = booleanValue(item.get('underline'));
            config.labelPosition = (String) item.get('labelPosition');
            config.labelMode = (String) item.get('labelMode');
            config.customLabel = (String) item.get('customLabel');
            config.labelIcon = (String) item.get('labelIcon');
            output.add(config);
        }
        return output;
    }

    private static String stringifyFieldValue(Object value) {
        return value == null ? '' : String.valueOf(value);
    }

    private static String stringValue(Map<String, Object> item, List<String> keys) {
        for (String key : keys) {
            if (item.containsKey(key) && item.get(key) != null) {
                String value = String.valueOf(item.get(key)).trim();
                if (String.isNotBlank(value)) {
                    return value;
                }
            }
        }
        return null;
    }

    private static Boolean booleanValue(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        String txt = String.valueOf(value).trim().toLowerCase();
        return txt == 'true' || txt == '1' || txt == 'yes';
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
        return stringifyFieldValue(relatedRecord.get('Name'));
    }

    private static Object getFieldValueByPath(SObject recordData, String fieldPath) {
        if (recordData == null || String.isBlank(fieldPath)) {
            return null;
        }
        if (!fieldPath.contains('.')) {
            return recordData.get(fieldPath);
        }
        List<String> parts = fieldPath.split('\\.');
        SObject current = recordData;
        for (Integer index = 0; index < parts.size(); index++) {
            String part = parts[index];
            Boolean isLast = index == parts.size() - 1;
            if (isLast) {
                return current != null ? current.get(part) : null;
            }
            current = current != null ? current.getSObject(part) : null;
            if (current == null) {
                return null;
            }
        }
        return null;
    }

    private static String resolveRelatedRecordId(SObject recordData, String fieldPath) {
        if (recordData == null || String.isBlank(fieldPath) || !fieldPath.contains('.')) {
            return '';
        }
        List<String> parts = fieldPath.split('\\.');
        SObject current = recordData;
        for (Integer index = 0; index < parts.size() - 1; index++) {
            current = current != null ? current.getSObject(parts[index]) : null;
            if (current == null) {
                return '';
            }
        }
        return stringifyFieldValue(current.get('Id'));
    }

    private static FieldPathDescribe describeFieldPath(Schema.DescribeSObjectResult rootDescribe, String fieldPath) {
        if (rootDescribe == null || String.isBlank(fieldPath)) {
            return null;
        }
        List<String> parts = fieldPath.split('\\.');
        Schema.DescribeSObjectResult currentDescribe = rootDescribe;
        Schema.DescribeFieldResult finalFieldDescribe = null;
        for (Integer index = 0; index < parts.size(); index++) {
            String segment = parts[index];
            Boolean isLast = index == parts.size() - 1;
            if (isLast) {
                Map<String, Schema.SObjectField> fieldMap = currentDescribe.fields.getMap();
                if (!fieldMap.containsKey(segment)) {
                    return null;
                }
                finalFieldDescribe = fieldMap.get(segment).getDescribe();
                break;
            }
            Schema.DescribeFieldResult relationFieldDescribe = getFieldDescribeByRelationshipName(currentDescribe, segment);
            if (relationFieldDescribe == null || relationFieldDescribe.getReferenceTo().isEmpty()) {
                return null;
            }
            currentDescribe = relationFieldDescribe.getReferenceTo()[0].getDescribe();
        }
        if (finalFieldDescribe == null) {
            return null;
        }
        FieldPathDescribe output = new FieldPathDescribe();
        output.fieldDescribe = finalFieldDescribe;
        return output;
    }

    private static Schema.DescribeFieldResult getFieldDescribeByRelationshipName(Schema.DescribeSObjectResult describeResult, String relationshipName) {
        if (describeResult == null || String.isBlank(relationshipName)) {
            return null;
        }
        for (Schema.SObjectField fieldRef : describeResult.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = fieldRef.getDescribe();
            if (dfr.getType() == Schema.DisplayType.REFERENCE && dfr.getRelationshipName() == relationshipName) {
                return dfr;
            }
        }
        return null;
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
        public String recordId { get; set; }
        public String objectApiName { get; set; }
        public String objectLabel { get; set; }
        public String titleValue { get; set; }
        public String selectedActionApiNames { get; set; }
        public String selectedActionsJson { get; set; }
        public String iconType { get; set; }
        public String iconValue { get; set; }
        public String iconSize { get; set; }
        public String configurationName { get; set; }
        public String configurationLabel { get; set; }
        public String displayMode { get; set; }
        public Integer numberOfFieldsDisplay { get; set; }
        public String backgroundColor { get; set; }
        public String textColor { get; set; }
        public Boolean isActive { get; set; }
        public List<Object> screenFlows { get; set; }
        public BannerDetailFieldWrapper subtitleField { get; set; }
        public List<BannerDetailFieldWrapper> detailFields { get; set; }
    }

    public class BannerActionWrapper {
        public String label { get; set; }
        public String name { get; set; }
        public String type { get; set; }
        public String apiName { get; set; }
        public String targetUrl { get; set; }
    }

    public class BannerDetailFieldWrapper {
        public String apiName { get; set; }
        public String label { get; set; }
        public String value { get; set; }
        public String lookupRecordId { get; set; }
        public String lookupDisplayValue { get; set; }
        public String color { get; set; }
        public Boolean bold { get; set; }
        public Boolean italic { get; set; }
        public Boolean underline { get; set; }
        public String labelPosition { get; set; }
        public String labelMode { get; set; }
        public String customLabel { get; set; }
        public String labelIcon { get; set; }
    }

    public class BannerFieldConfig {
        public String fieldApiName { get; set; }
        public String color { get; set; }
        public Boolean bold { get; set; }
        public Boolean italic { get; set; }
        public Boolean underline { get; set; }
        public String labelPosition { get; set; }
        public String labelMode { get; set; }
        public String customLabel { get; set; }
        public String labelIcon { get; set; }
    }

    public class FieldPathDescribe {
        public Schema.DescribeFieldResult fieldDescribe { get; set; }
    }
}