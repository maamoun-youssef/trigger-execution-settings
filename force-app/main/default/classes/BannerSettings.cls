public without sharing class BannerSettings extends SettingsManager implements MethodUtils.MethodChecker {
    @AuraEnabled public String developerName { get; set; }
    @AuraEnabled public String masterLabel { get; set; }
    @AuraEnabled public String objectApiName { get; set; }
    @AuraEnabled public String titleFieldApiName { get; set; }
    @AuraEnabled public String subtitleFieldApiName { get; set; }
    @AuraEnabled public String detailFieldsJson { get; set; }
    @AuraEnabled public String selectedActionsJson { get; set; }
    @AuraEnabled public String iconSource { get; set; }
    @AuraEnabled public String iconValue { get; set; }
    @AuraEnabled public String iconSize { get; set; }
    @AuraEnabled public String backgroundColor { get; set; }
    @AuraEnabled public String textColor { get; set; }
    @AuraEnabled public String displayMode { get; set; }
    @AuraEnabled public Integer numberOfFieldsDisplay { get; set; }
    @AuraEnabled public String type { get; set; }
    @AuraEnabled public Boolean isActive { get; set; }

    public BannerSettings() {
        this.detailFieldsJson = '[]';
        this.selectedActionsJson = '[]';
        this.iconSource = 'standard';
        this.iconValue = 'standard:record';
        this.iconSize = '30px';
        this.backgroundColor = '#ffffff';
        this.textColor = '#16325c';
        this.displayMode = 'horizontal';
        this.numberOfFieldsDisplay = 3;
        this.type = 'Record';
        this.isActive = true;
    }

    public BannerSettings load(Object metadataRecord) {
        BannerSettings settings = new BannerSettings();
        if (metadataRecord != null) {
            BannerSetting__mdt item = (BannerSetting__mdt) metadataRecord;
            settings.developerName = item.DeveloperName;
            settings.masterLabel = item.MasterLabel;
            settings.objectApiName = item.ObjectAPIName__c;
            settings.titleFieldApiName = item.TitleFieldAPI__c;
            settings.subtitleFieldApiName = item.SubTitleFieldAPI__c;
            settings.detailFieldsJson = String.isBlank(item.DetailFields__c) ? '[]' : item.DetailFields__c;
            settings.selectedActionsJson = String.isBlank(item.SelectedActions__c) ? '[]' : item.SelectedActions__c;
            settings.iconSource = String.isBlank(item.IconSource__c) ? 'standard' : item.IconSource__c;
            settings.iconValue = String.isBlank(item.IconValue__c) ? 'standard:record' : item.IconValue__c;
            settings.iconSize = String.isBlank(item.IconSize__c) ? '30px' : item.IconSize__c;
            settings.backgroundColor = item.BackgroundColor__c;
            settings.textColor = item.TextColor__c;
            settings.backgroundColor = String.isBlank(settings.backgroundColor) ? '#ffffff' : settings.backgroundColor;
            settings.textColor = String.isBlank(settings.textColor) ? '#16325c' : settings.textColor;
            settings.displayMode = String.isBlank(item.DisplayMode__c) ? 'horizontal' : item.DisplayMode__c;
            settings.numberOfFieldsDisplay = item.NumberOfFieldsDisplay__c == null ? 3 : Integer.valueOf(item.NumberOfFieldsDisplay__c);
            settings.type = String.isBlank(item.Type__c) ? 'Record' : item.Type__c;
            settings.isActive = item.IsActive__c == null ? true : item.IsActive__c;
        }
        return settings;
    }

    public static List<BannerSettings> loadBannerSettings() {
        List<BannerSettings> output = new List<BannerSettings>();
        for (Object item : SettingsManager.loadAllCustomMetadataSettings(BannerSetting__mdt.SObjectType, BannerSettings.class.getName())) {
            output.add((BannerSettings) item);
        }
        return output;
    }
    public static BannerSettings loadBannerSetting(String bannerDeveloperName) {
        if (String.isBlank(bannerDeveloperName)) {
            throw new AuraHandledException('Banner developer name is required.');
        }
        return (BannerSettings) SettingsManager.loadCustomMetadataSettings(BannerSetting__mdt.SObjectType, bannerDeveloperName, BannerSettings.class.getName());
    }

    public static String saveBannerSetting(String developerName, String masterLabel, String objectApiName, String titleFieldApiName, String subtitleFieldApiName,
                                        String detailFieldsJson, String selectedActionsJson, String iconSource, String iconValue, String backgroundColor,
                                        String textColor, String displayMode, Integer numberOfFieldsDisplay, String type, Boolean isActive, String iconSize)
    {
        if (String.isBlank(masterLabel)) {
            throw new AuraHandledException('Banner label is required.');
        }
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API name is required.');
        }
        String recordDeveloperName = normalizeDeveloperName(developerName, masterLabel);
        Map<String, Object> fieldsValueMap = new Map<String, Object>();
        fieldsValueMap.put(BannerSetting__mdt.ObjectAPIName__c.getDescribe().getName(), objectApiName);
        fieldsValueMap.put(BannerSetting__mdt.TitleFieldAPI__c.getDescribe().getName(), titleFieldApiName);
        fieldsValueMap.put(BannerSetting__mdt.SubTitleFieldAPI__c.getDescribe().getName(), subtitleFieldApiName);
        fieldsValueMap.put(BannerSetting__mdt.DetailFields__c.getDescribe().getName(), String.isBlank(detailFieldsJson) ? '[]' : detailFieldsJson);
        fieldsValueMap.put(BannerSetting__mdt.SelectedActions__c.getDescribe().getName(), String.isBlank(selectedActionsJson) ? '[]' : selectedActionsJson);
        fieldsValueMap.put(BannerSetting__mdt.IconSource__c.getDescribe().getName(), String.isBlank(iconSource) ? 'standard' : iconSource);
        fieldsValueMap.put(BannerSetting__mdt.IconValue__c.getDescribe().getName(), String.isBlank(iconValue) ? 'standard:record' : iconValue);
        fieldsValueMap.put(BannerSetting__mdt.IconSize__c.getDescribe().getName(), String.isBlank(iconSize) ? '30px' : iconSize);
        fieldsValueMap.put(BannerSetting__mdt.BackgroundColor__c.getDescribe().getName(), String.isBlank(backgroundColor) ? '#ffffff' : backgroundColor);
        fieldsValueMap.put(BannerSetting__mdt.TextColor__c.getDescribe().getName(), String.isBlank(textColor) ? '#16325c' : textColor);
        fieldsValueMap.put(BannerSetting__mdt.DisplayMode__c.getDescribe().getName(), String.isBlank(displayMode) ? 'horizontal' : displayMode);
        fieldsValueMap.put(BannerSetting__mdt.NumberOfFieldsDisplay__c.getDescribe().getName(), numberOfFieldsDisplay == null || numberOfFieldsDisplay < 1 ? 1 : numberOfFieldsDisplay);
        fieldsValueMap.put(BannerSetting__mdt.Type__c.getDescribe().getName(), String.isBlank(type) ? 'Record' : type);
        fieldsValueMap.put(BannerSetting__mdt.IsActive__c.getDescribe().getName(), isActive == null ? true : isActive);
        return saveCustomMetadataSettings(BannerSetting__mdt.SObjectType, recordDeveloperName, fieldsValueMap);
    }

    public Boolean hasMethod(String methodName) {
        return methodName == 'load';
    }

    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }

    private static String normalizeDeveloperName(String developerName, String masterLabel) {
        String baseName = String.isBlank(developerName) ? masterLabel : developerName;
        String normalized = baseName.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9_]', '_').replaceAll('_+', '_');
        normalized = normalized.replaceAll('^_+', '').replaceAll('_+$', '');
        if (String.isBlank(normalized)) {
            normalized = 'Banner_Setting';
        }
        if (!Pattern.matches('^[A-Za-z].*', normalized)) {
            normalized = 'B_' + normalized;
        }
        return normalized.length() > 40 ? normalized.substring(0, 40) : normalized;
    }

}