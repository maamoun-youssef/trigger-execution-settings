/**
 * @author ULit
 * @description
 * Settings for managing Trade Collaboration configurations.
 */
global with sharing class TradeCollabsSettings extends SettingsManager implements MethodUtils.MethodChecker {

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
     * Loads all TradeCollabsSettings from custom metadata.
     *
     * @return List<TradeCollabsSettings> - A list of all TradeCollabsSettings records.
     */
    public static List<TradeCollabsSettings> loadAllTradeCollabsSettings() {
        List<TradeCollabsSettings> activeTradeCollabsSettings = new List<TradeCollabsSettings>();
        List<TradeCollabsSettings> allTradeCollabsSettings = (List<TradeCollabsSettings>) JSON.deserialize(
            JSON.serialize(loadAllCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, TradeCollabsSettings.class.getName())),
            List<TradeCollabsSettings>.class
        );
        for (TradeCollabsSettings item : allTradeCollabsSettings) {
            if (!item.isDeleted) {
                activeTradeCollabsSettings.add(item);
            }
        }
        return activeTradeCollabsSettings;
    }
    
    global static String loadAllTradeCollabsSettingsSerialized() {
        return JSON.serialize(loadAllTradeCollabsSettings());
    }

    /**
     * Loads a specific TradeCollabsSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the TradeCollabsSettings to load.
     * @return TradeCollabsSettings - The corresponding TradeCollabsSettings record.
     */
    public static TradeCollabsSettings loadTradeCollabsSettings(String developerName) {
        TradeCollabsSettings item = (TradeCollabsSettings) loadCustomMetadataSettings(ConnectMenuSettings__mdt.SObjectType, developerName, TradeCollabsSettings.class.getName());
        if (item != null && !item.isDeleted) {
            return item;
        }
        return null;
    }
    
    global static String loadTradeCollabsSettingsSerialized(String developerName) {
        return JSON.serialize(loadTradeCollabsSettings(developerName));
    }

    /**
     * Loads metadata record into the current instance.
     *
     * @param metadataRecord - The metadata record to load.
     * @return TradeCollabsSettings - The current instance after loading.
     */
    public TradeCollabsSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ConnectMenuSettings__mdt tradeCollabsSettingsRecord = (ConnectMenuSettings__mdt) metadataRecord;
            this.developerName = tradeCollabsSettingsRecord.DeveloperName;
            this.sectionTitle = tradeCollabsSettingsRecord.SectionTitle__c;
            this.sectionSubTitle = tradeCollabsSettingsRecord.SectionSubTitle__c;
            this.sectionColor = tradeCollabsSettingsRecord.SectionColor__c;
            this.sectionIcon = tradeCollabsSettingsRecord.SectionIcon__c;
            this.displayOrder = (Integer) tradeCollabsSettingsRecord.DisplayOrder__c;
            this.isDeleted = tradeCollabsSettingsRecord.IsDeleted__c != null ? (Boolean) tradeCollabsSettingsRecord.IsDeleted__c : false;
            this.themesSettings = String.isNotBlank(tradeCollabsSettingsRecord.ThemesSettings__c) 
                ? (List<ThemeWrapper>) JSON.deserialize(tradeCollabsSettingsRecord.ThemesSettings__c, List<ThemeWrapper>.class) 
                : new List<ThemeWrapper>();
        }
        return this;
    }

    /**
     * Saves a list of TradeCollabsSettings to custom metadata.
     *
     * @param allTradeCollabsSettings - The list of TradeCollabsSettings to save.
     * @return String - The result of the save operation.
     */
    public String save(List<TradeCollabsSettings> allTradeCollabsSettings) {
        System.debug('allTradeCollabsSettings: ' + JSON.serialize(allTradeCollabsSettings));
        Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
        if (!allTradeCollabsSettings.isEmpty()) {
            for(TradeCollabsSettings tradeCollabsSettings : allTradeCollabsSettings) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionTitle__c.Name => tradeCollabsSettings.sectionTitle,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionSubTitle__c.Name => tradeCollabsSettings.sectionSubTitle,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionIcon__c.Name => tradeCollabsSettings.sectionIcon,
                    SObjectType.ConnectMenuSettings__mdt.fields.SectionColor__c.Name => tradeCollabsSettings.sectionColor,
                    SObjectType.ConnectMenuSettings__mdt.fields.DisplayOrder__c.Name => (Integer) tradeCollabsSettings.displayOrder,
                    SObjectType.ConnectMenuSettings__mdt.fields.IsDeleted__c.Name => (Boolean) tradeCollabsSettings.isDeleted,
                    SObjectType.ConnectMenuSettings__mdt.fields.ThemesSettings__c.Name => JSON.serialize(tradeCollabsSettings.themesSettings)
                };

                if (String.isEmpty(tradeCollabsSettings.developerName)) {
                    String pattern = '\\{\\!\\$Label\\.LBL_(.*?)\\}'; // Matches {!$Label.//text}
                    System.Pattern regexPattern = System.Pattern.compile(pattern);
                    System.Matcher matcher = regexPattern.matcher(tradeCollabsSettings.sectionTitle.replace(' ', ''));
                    if (matcher.matches()) {
                        string label = matcher.group(1);
                        tradeCollabsSettings.developerName = label;
                    } else {
                        tradeCollabsSettings.developerName = tradeCollabsSettings.sectionTitle;
                    }
                }
                string devName = tradeCollabsSettings.developerName.replace(' ', '');
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
     * Deletes a specific TradeCollabsSettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the TradeCollabsSettings to delete.
     * @return String - The result of the save operation.
     */
    public String deleteTradeCollabsSettings(String developerName) {
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