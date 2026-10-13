/**
 * @author ULit
 * @description
 * Settings for managing File Directory configurations.
 */
global with sharing class FileDirectorySettings  extends SettingsManager implements MethodUtils.MethodChecker {

    // Properties
    public String developerName {get; set;}
    public String sectionTitle {get; set;}
    public String sectionLabel {get; set;}
    public String sectionSubTitle {get; set;}
    public String sectionIcon {get; set;}
    public String sectionColor {get; set;}
    public Integer displayOrder {get; set;}
    public Boolean isDeleted {get; set;}
    public List<ThemeWrapper> themesSettings {get; set;}
    
    public FileDirectorySettings() {
        this.developerName = '';
        this.sectionTitle = '';
        this.sectionLabel = '';
        this.sectionSubTitle = '';
        this.sectionIcon = '';
        this.displayOrder = 1;
        this.isDeleted = false;
        this.themesSettings = new List<ThemeWrapper>();
    }

    /**
     * Loads all FileDirectorySettings from custom metadata.
     *
     * @return List<FileDirectorySettings> - A list of all FileDirectorySettings records.
     */
    public static List<FileDirectorySettings> loadAllFileDirectorySettings() {
        List<FileDirectorySettings> activeFileDirectorySettings = new List<FileDirectorySettings>();
        List<FileDirectorySettings> allFileDirectorySettings = (List<FileDirectorySettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(FileDirectorySettings__mdt.SObjectType, FileDirectorySettings.class.getName())), List<FileDirectorySettings>.class);
        for (FileDirectorySettings item : allFileDirectorySettings) {
            if (!item.isDeleted) {
                activeFileDirectorySettings.add(item);
            }
        }
        return activeFileDirectorySettings;
    }
    
    global static String loadAllFileDirectorySettingsSerialized() {
        return JSON.serialize(loadAllFileDirectorySettings());
    }

    /**
     * Loads a specific FileDirectorySettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the FileDirectorySettings to load.
     * @return FileDirectorySettings - The corresponding FileDirectorySettings record.
     */
    public static FileDirectorySettings loadFileDirectorySettings(String developerName) {
        FileDirectorySettings item = (FileDirectorySettings) loadCustomMetadataSettings(FileDirectorySettings__mdt.SObjectType, developerName, FileDirectorySettings.class.getName());
        if (item != null && !item.isDeleted) {
            return item;
        }
        return null;
    }
    
    global static String loadFileDirectorySettingsSerialized(String developerName) {
        return JSON.serialize(loadFileDirectorySettings(developerName));
    }
    /**
     * Loads metadata record into the current instance.
     *
     * @param metadataRecord - The metadata record to load.
     * @return FileDirectorySettings - The current instance after loading.
     */
    public FileDirectorySettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            FileDirectorySettings__mdt fileDirectorySettingsRecord = (FileDirectorySettings__mdt) metadataRecord;
            this.developerName = fileDirectorySettingsRecord.DeveloperName;
            this.sectionTitle = fileDirectorySettingsRecord.SectionTitle__c;
            this.sectionSubTitle = fileDirectorySettingsRecord.SectionSubTitle__c;
            this.sectionColor = fileDirectorySettingsRecord.SectionColor__c;
            this.sectionIcon = fileDirectorySettingsRecord.SectionIcon__c;
            this.displayOrder = (Integer) fileDirectorySettingsRecord.DisplayOrder__c ;
            this.isDeleted = fileDirectorySettingsRecord.IsDeleted__c != null ? (Boolean) fileDirectorySettingsRecord.IsDeleted__c : false;
            this.themesSettings = String.isNotBlank(fileDirectorySettingsRecord.ThemesSettings__c) ? (List<ThemeWrapper>) JSON.deserialize(fileDirectorySettingsRecord.ThemesSettings__c, List<ThemeWrapper>.class) : new List<ThemeWrapper>();
        }
        return this;
    }

    /**
     * Saves a list of FileDirectorySettings to custom metadata.
     *
     * @param allFileDirectorySettings - The list of FileDirectorySettings to save.
     * @return String - The result of the save operation.
     */
    public String save(List<FileDirectorySettings> allfileDirectorySettings) {
        System.debug('allfileDirectorySettings: ' + JSON.serialize(allfileDirectorySettings));
        Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
        if (!allfileDirectorySettings.isEmpty()) {
            for(FileDirectorySettings fileDirectorySettings : allfileDirectorySettings){
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.FileDirectorySettings__mdt.fields.SectionTitle__c.Name => fileDirectorySettings.sectionTitle,
                    SObjectType.FileDirectorySettings__mdt.fields.SectionSubTitle__c.Name => fileDirectorySettings.sectionSubTitle,
                    SObjectType.FileDirectorySettings__mdt.fields.SectionIcon__c.Name => fileDirectorySettings.sectionIcon,
                    SObjectType.FileDirectorySettings__mdt.fields.SectionColor__c.Name => fileDirectorySettings.sectionColor,
                    SObjectType.FileDirectorySettings__mdt.fields.DisplayOrder__c.Name => (Integer) fileDirectorySettings.displayOrder,
                    SObjectType.FileDirectorySettings__mdt.fields.IsDeleted__c.Name => (Boolean) fileDirectorySettings.isDeleted,
                    SObjectType.FileDirectorySettings__mdt.fields.ThemesSettings__c.Name => JSON.serialize(fileDirectorySettings.themesSettings)
                };
                if(String.isEmpty(fileDirectorySettings.developerName)){
                    String pattern = '\\{\\!\\$Label\\.LBL_(.*?)\\}'; // Matches {!$Label.//text}
                    System.Pattern regexPattern = System.Pattern.compile(pattern);
                    System.Matcher matcher = regexPattern.matcher(fileDirectorySettings.sectionTitle.replace(' ', ''));
                    if (matcher.matches()) {
                        string label = matcher.group(1);
                        fileDirectorySettings.developerName = label;
                    } else {
                        fileDirectorySettings.developerName = fileDirectorySettings.sectionTitle;
                    }
                }
                string devName = fileDirectorySettings.developerName.replace(' ', '');
                if (devName.length() > 39) {
                    devName = devName.substring(0, 40);
                }
                if (!metadataRecordsMap.containsKey(devName)) {
                    metadataRecordsMap.put(devName, fieldsValueMap);
                }
            }
            return saveAllCustomMetadataSettings(FileDirectorySettings__mdt.SObjectType, metadataRecordsMap);
        }
        return null;
    }

    /**
     * Deletes a specific FileDirectorySettings record by DeveloperName.
     *
     * @param developerName - The DeveloperName of the FileDirectorySettings to delete.
     * @return String - The result of the save operation.
     */
    public String deleteFileDirectorySettings(String developerName) {
        if (developerName != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.FileDirectorySettings__mdt.fields.IsDeleted__c.Name => true
            };
            return saveCustomMetadataSettings(FileDirectorySettings__mdt.SObjectType, developerName, fieldsValueMap);
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
        return methodName == 'load' ?  true : false;
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
        public String theme {get; set;}
        public String themeLabel {get; set;}
        public String gridSettingsName {get; set;}
        public String smallThemeImage {get; set;}
        public String largeThemeImage {get; set;}
        public Boolean isDisplayed {get; set;}
        public Boolean isPortalDisplayed {get; set;}
        public String relatedSection {get; set;}
        public Boolean isAllowApproveDocInternal {get; set;}
        public Boolean isAllowApproveDocExternal {get; set;}
        public Boolean isAllowCancelDocInternal {get; set;}
        public Boolean isAllowCancelDocExternal {get; set;}

        public Boolean allowUpload {get; set;}
        public List<String> allowedStatusesForUpload {get; set;}
        public Boolean allowMultipleUpload {get; set;}
        public Boolean allowDelete {get; set;}
        public List<String> allowedStatusesForDelete {get; set;}
        public Boolean allowSharing {get; set;}
        public List<String> allowedStatusesForShare {get; set;}
        public Boolean allowReceiptConfirmation {get; set;}
        public List<String> allowedStatusesForReceiptConfirmation {get; set;}

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