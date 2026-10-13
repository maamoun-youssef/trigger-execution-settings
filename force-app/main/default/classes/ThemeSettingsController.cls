public with sharing class ThemeSettingsController {

    @AuraEnabled
    public static string loadAllData() {
        return JSON.serialize(ThemeSettings.loadAllThemeSettings());
    }

    @AuraEnabled
    public static String save(String themeSettingsListJSON) {
        ThemeSettings themeSetting = String.isNotBlank(themeSettingsListJSON) ? (ThemeSettings) JSON.deserialize(themeSettingsListJSON, ThemeSettings.class) : new ThemeSettings();
        return ThemeSettings.save(themeSetting);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    @AuraEnabled(cacheable=true)
    public static String generateThemeTokensPreview(String brandColor, String backgroundColor, String fontFamily, String borderRadius) {
        return ThemeSettings.generateTokens(new ThemeSettings.ThemeAttributeWrapper(brandColor, backgroundColor, fontFamily, borderRadius));
    }
    
    @AuraEnabled(cacheable=true)
    public static String generateThemeTokens(String themeSettingsName) {
        return ThemeSettings.generateTokens(themeSettingsName);
    }
}