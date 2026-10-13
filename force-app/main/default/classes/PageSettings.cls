/**
 * @author ULiT
 * @date 28/04/2025
 * Advanced Settings class for Page Settings
 **/
global with sharing class PageSettings extends SettingsManager implements MethodUtils.MethodChecker {
    
    public String name {get; set;}
    public Boolean isActive {get; set;}
    public String namespacePrefix {get; set;}
    public Boolean isDeleted {get; set;}
    public String description {get; set;}
    public String headerBackground {get; set;}
    public String icon {get; set;}
    public List<SectionSettings> sections {get; set;}
    public List<ThemeSettings> themes {get; set;}
    public FlowSettings flowSettings {get; set;}
    
    public PageSettings() {
        
    }
    
    global static String loadPageSettingsSerialized(String pageSettingsName) {
        return JSON.serialize(loadPageSettings(pageSettingsName));
    }
    
    public static PageSettings loadPageSettings(String pageSettingsName) {
        return (PageSettings) loadCustomMetadataSettings(PageSettings__mdt.SObjectType, pageSettingsName, PageSettings.class.getName(), null);
    }
    
    public static List<PageSettings> loadAllPageSettings() {
        return (List<PageSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(PageSettings__mdt.SObjectType, PageSettings.class.getName(), null)), List<PageSettings>.class);
    }
    
    global static String loadAllPageSettingsSerialized() {
        return JSON.serialize(loadAllPageSettings());
    }
    
    public PageSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            PageSettings__mdt pageSettingsRecord = (PageSettings__mdt) metadataRecord;
            this.name = String.isNotBlank(pageSettingsRecord.Name__c) ? pageSettingsRecord.Name__c : '';
            this.namespacePrefix = pageSettingsRecord.NamespacePrefix;
            this.isActive = pageSettingsRecord.isActive__c == null ? false : pageSettingsRecord.isActive__c;
            this.isDeleted = pageSettingsRecord.isDeleted__c == null ? false : pageSettingsRecord.isDeleted__c;
            this.description = String.isNotBlank(pageSettingsRecord.Description__c) ? pageSettingsRecord.Description__c : '';
            this.headerBackground = String.isNotBlank(pageSettingsRecord.HeaderBackground__c) ? pageSettingsRecord.HeaderBackground__c : '';
            this.icon = String.isNotBlank(pageSettingsRecord.Icon__c) ? pageSettingsRecord.Icon__c : '';
            this.sections = String.isBlank(pageSettingsRecord.Sections__c) ? new List<SectionSettings>() : (List<SectionSettings>) JSON.deserialize(pageSettingsRecord.Sections__c, List<SectionSettings>.class);
            this.themes = String.isBlank(pageSettingsRecord.Themes__c) ? new List<ThemeSettings>() : (List<ThemeSettings>) JSON.deserialize(pageSettingsRecord.Themes__c, List<ThemeSettings>.class);
            this.flowSettings = String.isBlank(pageSettingsRecord.FlowSettings__c) ? new FlowSettings() : (FlowSettings) JSON.deserialize(pageSettingsRecord.FlowSettings__c, FlowSettings.class);
        }
        return this;
    }
    
    public static String save(List<PageSettings> pageSettings) {
        if (pageSettings != null) {
            Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
            for (PageSettings pageSetting : pageSettings) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.PageSettings__mdt.fields.Name__c.Name => pageSetting.name,
                    SObjectType.PageSettings__mdt.fields.isActive__c.Name => pageSetting.isActive,
                    SObjectType.PageSettings__mdt.fields.isDeleted__c.Name => pageSetting.isDeleted,
                    SObjectType.PageSettings__mdt.fields.Description__c.Name => pageSetting.description,
                    SObjectType.PageSettings__mdt.fields.HeaderBackground__c.Name => pageSetting.headerBackground,
                    SObjectType.PageSettings__mdt.fields.Icon__c.Name => pageSetting.icon,
                    SObjectType.PageSettings__mdt.fields.Sections__c.Name => JSON.serialize(pageSetting.sections),
                    SObjectType.PageSettings__mdt.fields.Themes__c.Name => JSON.serialize(pageSetting.themes),
                    SObjectType.PageSettings__mdt.fields.FlowSettings__c.Name => JSON.serialize(pageSetting.flowSettings)
                };
                metadataRecordsMap.put(pageSetting.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
            }
            return saveAllCustomMetadataSettings(PageSettings__mdt.SObjectType, metadataRecordsMap);
        }
        return null;
    }
    
    public Boolean hasMethod(String methodName) {
        if (methodName == 'load') {
            return true;
        }
        return false;
    }
    
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }
    
    public class SectionSettings {
        public String title { get; set; }
        public String subTitle { get; set; }
        public String icon { get; set; }
        public Integer order { get; set; }
        public String color { get; set; }
        public Boolean isActive {get; set;}

        public SectionSettings(String title, String subTitle, String icon, Integer order, String color, Boolean isActive) {
            this.title = title;
            this.subTitle = subTitle;
            this.icon = icon;
            this.order = order;
            this.color = color;
            this.isActive = isActive;
        }
    }
    
    public class ThemeSettings {
        public Integer sectionIndex { get; set; }
        public String label { get; set; }
        public String redirectionType { get; set; }
        public String redirection { get; set; }
        public String icon { get; set; }
        public Boolean isInternalDisplay { get; set; }
        public Boolean isPortalDisplay { get; set; }
        public Boolean isActive {get; set;}
        public Map<String, String> params {get; set;}

        public ThemeSettings(Integer sectionIndex, String label, String redirectionType, String redirection, String icon, Boolean isInternalDisplay, Boolean isPortalDisplay, Boolean isActive, Map<String, String> params) {
            this.sectionIndex = sectionIndex;
            this.label = label;
            this.redirectionType = redirectionType;
            this.redirection = redirection;
            this.icon = icon;
            this.isInternalDisplay = isInternalDisplay;
            this.isPortalDisplay = isPortalDisplay;
            this.isActive = isActive;
            this.params = params;
        }
    }

    public class FlowSettings {
        public String name { get; set; }
        public String buttonIcon { get; set; }
        public String buttonLabel { get; set; }
        public String flowLabel { get; set; }

        public FlowSettings() {
            this.name = '';
            this.buttonIcon = '';
            this.buttonLabel = '';
            this.flowLabel = '';
        }
    }
}