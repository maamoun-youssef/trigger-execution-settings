/**
 * @author ULit
 * @description
 * Settings for managing Connect Menu configurations.
 */
global with sharing class ConnectMenuSettings extends SettingsManager implements MethodUtils.MethodChecker {

    // Properties
    public String developerName { get; set; }
    public String sectionTitle { get; set; }
    public String sectionLabel { get; set; }
    public String sectionSubTitle { get; set; }
    public String sectionIcon { get; set; }
    public String sectionColor { get; set; } 
    public Integer displayOrder { get; set; }
    public Boolean isDeleted { get; set; }
    public List<ThemeWrapper> themesSettings { get; set; } 

    /**
     * Loads all ConnectMenuSettings from custom metadata.
     *
     * @return List<ConnectMenuSettings> - A list of all ConnectMenuSettings records.
     */
    public static List<ConnectMenuSettings> loadAllConnectMenuSettings() {
        List<ConnectMenuSettings> activeConnectMenuSettings = new List<ConnectMenuSettings>();
        List<ConnectMenuSettings> allConnectMenuSettings = (List<ConnectMenuSettings>) JSON.deserialize(
            JSON.serialize(loadAllCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, ConnectMenuSettings.class.getName())),
            List<ConnectMenuSettings>.class
        );
        for (ConnectMenuSettings item : allConnectMenuSettings) {
            if (!item.isDeleted) {
                activeConnectMenuSettings.add(item);
            }
        }
        return activeConnectMenuSettings;
    }
    
    global static String loadAllConnectMenuSettingsSerialized() {
        return JSON.serialize(loadAllConnectMenuSettings());
    }

    /**
     * Loads a specific ConnectMenuSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the ConnectMenuSettings to load.
     * @return ConnectMenuSettings - The corresponding ConnectMenuSettings record.
     */
    public static ConnectMenuSettings loadConnectMenuSettings(String developerName) {
        ConnectMenuSettings item = (ConnectMenuSettings) loadCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, developerName, ConnectMenuSettings.class.getName());
        if (item != null && !item.isDeleted) {
            return item;
        }
        return null;
    }
    
    global static String loadConnectMenuSettingsSerialized(String developerName) {
        return JSON.serialize(loadConnectMenuSettings(developerName));
    }

    /**
     * Loads metadata record into the current instance.
     *
     * @param metadataRecord - The metadata record to load.
     * @return ConnectMenuSettings - The current instance after loading.
     */
    public ConnectMenuSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ConnectMenuSettings__mdt connectMenuSettingsRecord = (ConnectMenuSettings__mdt) metadataRecord;
            this.developerName = connectMenuSettingsRecord.DeveloperName;
            this.sectionTitle = connectMenuSettingsRecord.SectionTitle__c;
            this.sectionSubTitle = connectMenuSettingsRecord.SectionSubTitle__c;
            this.sectionColor = connectMenuSettingsRecord.SectionColor__c;
            this.sectionIcon = connectMenuSettingsRecord.SectionIcon__c;
            this.displayOrder = (Integer) connectMenuSettingsRecord.DisplayOrder__c;
            this.isDeleted = connectMenuSettingsRecord.IsDeleted__c != null ? (Boolean) connectMenuSettingsRecord.IsDeleted__c : false;
            this.themesSettings = String.isNotBlank(connectMenuSettingsRecord.ThemesSettings__c) 
                ? (List<ThemeWrapper>) JSON.deserialize(connectMenuSettingsRecord.ThemesSettings__c, List<ThemeWrapper>.class) 
                : new List<ThemeWrapper>();
        }
        return this;
    }

    /**
     * Saves a list of ConnectMenuSettings to custom metadata.
     *
     * @param allConnectMenuSettings - The list of ConnectMenuSettings to save.
     * @return String - The result of the save operation.
     */
    public String save(List<ConnectMenuSettings> allConnectMenuSettings) {
        System.debug('allConnectMenuSettings: ' + JSON.serialize(allConnectMenuSettings));
        Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
        if (!allConnectMenuSettings.isEmpty()) {
            for(ConnectMenuSettings connectMenuSettings : allConnectMenuSettings) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionTitle__c.Name => connectMenuSettings.sectionTitle,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionSubTitle__c.Name => connectMenuSettings.sectionSubTitle,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionIcon__c.Name => connectMenuSettings.sectionIcon,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionColor__c.Name => connectMenuSettings.sectionColor,
                    SObjectType.ConnectMenuSettings__mdt.fields.DisplayOrder__c.Name => (Integer) connectMenuSettings.displayOrder,
                    SObjectType.ConnectMenuSettings__mdt.fields.IsDeleted__c.Name => (Boolean) connectMenuSettings.isDeleted,
                    SObjectType.ConnectMenuSettings__mdt.fields.ThemesSettings__c.Name => JSON.serialize(connectMenuSettings.themesSettings)
                };

                if (String.isEmpty(connectMenuSettings.developerName)) {
                    String pattern = '\\{\\!\\$Label\\.LBL_(.*?)\\}'; // Matches {!$Label.//text}
                    System.Pattern regexPattern = System.Pattern.compile(pattern);
                    System.Matcher matcher = regexPattern.matcher(connectMenuSettings.sectionTitle.replace(' ', ''));
                    if (matcher.matches()) {
                        string label = matcher.group(1);
                        connectMenuSettings.developerName = label;
                    } else {
                        connectMenuSettings.developerName = connectMenuSettings.sectionTitle;
                    }
                }
                string devName = connectMenuSettings.developerName.replace(' ', '');
                if (devName.length() > 39) {
                    devName = devName.substring(0, 40);
                }
                if (!metadataRecordsMap.containsKey(devName)) {
                    metadataRecordsMap.put(devName, fieldsValueMap);
                }
            }
            return saveAllCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, metadataRecordsMap);
        }
        return null;
    }

    /**
     * Deletes a specific ConnectMenuSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the ConnectMenuSettings to delete.
     * @return String - The result of the save operation.
     */
    public String deleteConnectMenuSettings(String developerName) {
        if (developerName != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.ConnectMenuSettings__mdt.fields.IsDeleted__c.Name => true
            };
            return saveCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, developerName, fieldsValueMap);
        }
        return null;
    }

    /**
     * Checks if a method exists.
     *
     * @param methodName - The name of the method to check.
     * @return Boolean - True if the method exists, otherwise false.
     */
    public Boolean hasMethod(String methodName) {
        return methodName == 'load' ? true : false;
    }

    /**
     * Invokes a method dynamically.
     *
     * @param methodName - The name of the method to invoke.
     * @param args - The arguments to pass to the method.
     * @return Object - The result of the method invocation.
     * @throws IllegalArgumentException - If the method does not exist.
     */
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }

    /**
     * Wrapper class for Theme settings.
     */
    public class ThemeWrapper {
        public String theme { get; set; }
        public String themeLabel { get; set; }
        public String gridSettingsName { get; set; }
        public String smallThemeImage { get; set; }
        public String largeThemeImage { get; set; }
        public Boolean isDisplayed { get; set; }
        public Boolean isPortalDisplayed { get; set; }
        public String relatedSection { get; set; }
        
        /**
         * Constructor for ThemeWrapper.
         *
         * @param theme - The name of the theme.
         * @param gridSettingsName - The name of the grid settings.
         * @param smallThemeImage - URL or identifier for the small theme image.
         * @param largeThemeImage - URL or identifier for the large theme image.
         * @param isDisplayed - Flag indicating if the theme is displayed.
         * @param isPortalDisplayed - Flag indicating if the theme is displayed in the portal.
         * @param relatedSection - The related section for the theme.
         */
        public ThemeWrapper(String theme, string themeLabel, String gridSettingsName, String smallThemeImage, String largeThemeImage, Boolean isDisplayed, Boolean isPortalDisplayed, String relatedSection) {
            this.theme = theme;
            this.themeLabel = themeLabel;
            this.gridSettingsName = gridSettingsName;
            this.smallThemeImage = smallThemeImage;
            this.largeThemeImage = largeThemeImage;
            this.isDisplayed = isDisplayed;
            this.isPortalDisplayed = isPortalDisplayed;
            this.relatedSection = relatedSection;
        }
    }
}