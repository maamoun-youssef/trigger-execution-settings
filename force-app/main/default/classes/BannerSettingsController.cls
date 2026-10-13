public without sharing class BannerSettingsController {
    @AuraEnabled
    public static String getManagerInitData() {
        ManagerInitWrapper wrapper = new ManagerInitWrapper();
        wrapper.objectOptions = getObjectOptions();
        wrapper.iconOptions = getIconOptions();
        wrapper.displayModeOptions = getDisplayModeOptions();
        wrapper.gridOptions = getGridTemplateOptions();
        wrapper.pageOptions = getPageOptions();
        wrapper.activeScreenFlows = JSON.serialize(NegoptimHelper.getActiveScreenFlows());
        wrapper.savedSettings = BannerSettings.loadBannerSettings();
        return JSON.serialize(wrapper);
    }

    @AuraEnabled
    public static String getObjectSetupData(String objectApiName, String developerName) {
        try {
            BannerSettingEditorDataWrapper wrapper = new BannerSettingEditorDataWrapper();
            if (String.isNotBlank(developerName)) {
                wrapper.setting = BannerSettings.loadBannerSetting(developerName);
                objectApiName = wrapper.setting.objectApiName;
            }
            wrapper.fieldOptions = getFieldOptions(objectApiName);
            wrapper.actionOptions = getActionOptions(objectApiName);
            return JSON.serialize(wrapper);
        } catch (Exception ex) {
            System.debug('error : ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            throw new AuraHandledException('Error retrieving object setup data: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getDetailFieldExplorerOptions(String objectApiName, String currentPath) {
        DetailFieldExplorerWrapper wrapper = new DetailFieldExplorerWrapper();
        wrapper.options = getDetailExplorerOptions(objectApiName, currentPath);
        wrapper.currentPath = String.isBlank(currentPath) ? '' : currentPath;
        return JSON.serialize(wrapper);
    }
    @AuraEnabled
    public static BannerSettings getBannerSetting(String developerName) {
        return BannerSettings.loadBannerSetting(developerName);
    }

    @AuraEnabled
    public static String saveBannerSetting(String developerName, String masterLabel, String objectApiName, String titleFieldApiName, 
                                            String subtitleFieldApiName, String detailFieldsJson, String selectedActionsJson, String iconSource,
                                             String iconValue, String backgroundColor, String textColor, String displayMode,
                                             Integer numberOfFieldsDisplay, String type, Boolean isActive, String iconSize) {
        return BannerSettings.saveBannerSetting(developerName, masterLabel, objectApiName, titleFieldApiName, subtitleFieldApiName,
            detailFieldsJson, selectedActionsJson, iconSource, iconValue, backgroundColor, textColor, displayMode, numberOfFieldsDisplay, type, isActive, iconSize);
    }

    private static List<OptionWrapper> getGridTemplateOptions() {
        List<OptionWrapper> options = new List<OptionWrapper>();
        for (Grid_Settings__mdt item : [SELECT MasterLabel, DeveloperName
                                            FROM Grid_Settings__mdt
                                            ORDER BY MasterLabel
                                            LIMIT 1000])
        {
            options.add(new OptionWrapper(item.MasterLabel, item.DeveloperName));
        }
        return options;
    }

    private static List<OptionWrapper> getPageOptions() {
        List<OptionWrapper> options = new List<OptionWrapper>();
        for (ApexPage item : [SELECT MasterLabel, Name
                                FROM ApexPage
                                ORDER BY MasterLabel
                                LIMIT 1000])
        {
            options.add(new OptionWrapper(item.MasterLabel, item.Name));
        }
        return options;
    }

    @AuraEnabled
    public static String uploadBannerImage(String fileName, String base64Data) {
        if (String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('A file name and image payload are required.');
        }
        ContentVersion version = new ContentVersion();
        version.Title = fileName;
        version.PathOnClient = '/' + fileName;
        version.VersionData = EncodingUtil.base64Decode(base64Data);
        insert version;
        version = [SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :version.Id
                    LIMIT 1];
        return '/sfc/servlet.shepherd/document/download/' + version.ContentDocumentId;
    }

    private static List<OptionWrapper> getObjectOptions() {
        List<OptionWrapper> output = new List<OptionWrapper>();
        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = sObjType.getDescribe();
            String objectName = objResult.getName();
            if (objResult.isAccessible()
                && objResult.isQueryable()
                && (objResult.isCreateable() || objResult.isUpdateable())
                && !objResult.isCustomSetting()
                && !objectName.endsWithIgnoreCase('History')
                && !objectName.endsWithIgnoreCase('Feed')
                && !objectName.endsWithIgnoreCase('ChangeEvent')
                && !objectName.endsWithIgnoreCase('__e')
                && !objectName.endsWithIgnoreCase('__x')
                && !objectName.containsIgnoreCase('__mdt')
                && !objectName.containsIgnoreCase('Share'))
            {
                output.add(new OptionWrapper(objResult.getLabel(), objectName));
            }
        }
        output.sort();
        return output;
    }

    private static List<OptionWrapper> getIconOptions() {
        List<OptionWrapper> output = new List<OptionWrapper>();
        List<Object> values = (List<Object>) JSON.deserializeUntyped(GridSettingsCmpController.getIconsNamePicklist());
        for (Object item : values) {
            String iconName = String.valueOf(item);
            output.add(new OptionWrapper(iconName, iconName));
        }
        return output;
    }

    private static List<OptionWrapper> getDisplayModeOptions() {
        List<OptionWrapper> output = new List<OptionWrapper>();
        for (Schema.PicklistEntry item : BannerSetting__mdt.DisplayMode__c.getDescribe().getPicklistValues()) {
            output.add(new OptionWrapper(item.getLabel(), item.getValue()));
        }
        return output;
    }

    private static List<OptionWrapper> getFieldOptions(String objectApiName) {
        List<OptionWrapper> options = new List<OptionWrapper>();
        if (!Schema.getGlobalDescribe().containsKey(objectApiName)) {
            return options;
        }
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();
            options.add(new OptionWrapper(dfr.getLabel() + ' (' + dfr.getName() + ')', dfr.getName()));
        }
        options.sort();
        return options;
    }

    private static List<OptionWrapper> getDetailExplorerOptions(String objectApiName, String currentPath) {
        List<OptionWrapper> options = new List<OptionWrapper>();
        if (!Schema.getGlobalDescribe().containsKey(objectApiName)) {
            return options;
        }
        String targetObject = resolveTargetObjectForPath(objectApiName, currentPath);
        if (String.isBlank(targetObject) || !Schema.getGlobalDescribe().containsKey(targetObject)) {
            return options;
        }

        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(targetObject).getDescribe().fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();
            String fullFieldPath = String.isBlank(currentPath) ? dfr.getName() : currentPath + '.' + dfr.getName();
            String displayLabel = dfr.getLabel();
            options.add(new OptionWrapper(displayLabel, fullFieldPath, false));

            if (dfr.getType() == Schema.DisplayType.Reference && String.isNotBlank(dfr.getRelationshipName())) {
                String nextPath = String.isBlank(currentPath) ? dfr.getRelationshipName() : currentPath + '.' + dfr.getRelationshipName();
                options.add(new OptionWrapper(displayLabel + ' >', nextPath, true));
            }
        }
        options.sort();
        return options;
    }

    private static String resolveTargetObjectForPath(String rootObjectApiName, String currentPath) {
        if (String.isBlank(currentPath)) {
            return rootObjectApiName;
        }
        String currentObject = rootObjectApiName;
        for (String segment : currentPath.split('\\.')) {
            if (!Schema.getGlobalDescribe().containsKey(currentObject)) {
                return null;
            }
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(currentObject).getDescribe().fields.getMap();
            Schema.DescribeFieldResult matchingReference;
            for (Schema.SObjectField fieldRef : fieldsMap.values()) {
                Schema.DescribeFieldResult dfr = fieldRef.getDescribe();
                if (dfr.getType() == Schema.DisplayType.Reference && dfr.getRelationshipName() == segment) {
                    matchingReference = dfr;
                    break;
                }
            }
            if (matchingReference == null || matchingReference.getReferenceTo().isEmpty()) {
                return null;
            }
            currentObject = matchingReference.getReferenceTo()[0].getDescribe().getName();
        }
        return currentObject;
    }

    private static List<OptionWrapper> getActionOptions(String objectApiName) {
        List<OptionWrapper> options = new List<OptionWrapper>();
        for (BannerSettingsPluginCmpController.BannerActionWrapper item : BannerSettingsPluginCmpController.getObjectActionsList(objectApiName)) {
            String actionValue = String.isNotBlank(item.apiName) ? item.apiName : item.name;
            options.add(new OptionWrapper(item.label + ' (' + actionValue + ')', actionValue));
        }
        return options;
    }

    public class OptionWrapper implements Comparable {
        public String label { get; set; }
        public String value { get; set; }
        public Boolean isNavigation { get; set; }
        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
            this.isNavigation = false;
        }
        public OptionWrapper(String label, String value, Boolean isNavigation) {
            this.label = label;
            this.value = value;
            this.isNavigation = isNavigation;
        }

        public Integer compareTo(Object obj) {
            OptionWrapper other = (OptionWrapper) obj;
            return String.valueOf(label).toLowerCase().compareTo(String.valueOf(other.label).toLowerCase());
        }
    }

    public class ManagerInitWrapper {
        public List<OptionWrapper> objectOptions { get; set; }
        public List<OptionWrapper> iconOptions { get; set; }
        public List<OptionWrapper> displayModeOptions { get; set; }
        public List<OptionWrapper> gridOptions { get; set; }
        public List<OptionWrapper> pageOptions { get; set; }
        public String activeScreenFlows { get; set; }
        public Map<String, List<OptionWrapper>> picklistMap { get; set; }
        public List<BannerSettings> savedSettings { get; set; }
        public Map<String, String> fieldLabels { get; set; }
        public ManagerInitWrapper() {
            this.objectOptions = new List<OptionWrapper>();
            this.iconOptions = new List<OptionWrapper>();
            this.displayModeOptions = new List<OptionWrapper>();
            this.gridOptions = new List<OptionWrapper>();
            this.pageOptions = new List<OptionWrapper>();
            this.activeScreenFlows = '';
            this.picklistMap = new Map<String, List<OptionWrapper>>();
            this.fieldLabels = new Map<String, String>();
            this.savedSettings = new List<BannerSettings>();
            this.fieldLabels.put('masterLabel', System.Label.LBL_Name);
            this.fieldLabels.put('developerName', BannerSetting__mdt.DeveloperName.getDescribe().getLabel());
            this.fieldLabels.put('objectApiName', BannerSetting__mdt.ObjectAPIName__c.getDescribe().getLabel());
            this.fieldLabels.put('isActive', BannerSetting__mdt.IsActive__c.getDescribe().getLabel());
            this.fieldLabels.put('backgroundColor', BannerSetting__mdt.BackgroundColor__c.getDescribe().getLabel());
            this.fieldLabels.put('textColor', BannerSetting__mdt.TextColor__c.getDescribe().getLabel());
            this.fieldLabels.put('titleFieldApiName', BannerSetting__mdt.TitleFieldAPI__c.getDescribe().getLabel());
            this.fieldLabels.put('subtitleFieldApiName', BannerSetting__mdt.SubTitleFieldAPI__c.getDescribe().getLabel());
            this.fieldLabels.put('displayMode', BannerSetting__mdt.DisplayMode__c.getDescribe().getLabel());
            this.fieldLabels.put('numberOfFieldsDisplay', BannerSetting__mdt.NumberOfFieldsDisplay__c.getDescribe().getLabel());
            this.fieldLabels.put('iconSource', BannerSetting__mdt.IconSource__c.getDescribe().getLabel());
            this.fieldLabels.put('iconValue', BannerSetting__mdt.IconValue__c.getDescribe().getLabel());
            this.fieldLabels.put('iconSize', BannerSetting__mdt.IconSize__c.getDescribe().getLabel());
            this.picklistMap.put('DisplayMode__c', getDisplayModeOptions());

         }

    }

    public class BannerSettingEditorDataWrapper {
        public BannerSettings setting { get; set; }
        public List<OptionWrapper> fieldOptions { get; set; }
        public List<OptionWrapper> actionOptions { get; set; }
        public BannerSettingEditorDataWrapper() {
            setting = new BannerSettings();
            fieldOptions = new List<OptionWrapper>();
            actionOptions = new List<OptionWrapper>();
        }
    }

    public class DetailFieldExplorerWrapper {
        public List<OptionWrapper> options { get; set; }
        public String currentPath { get; set; }
        public DetailFieldExplorerWrapper() {
            options = new List<OptionWrapper>();
            currentPath = '';
        }
    }
}