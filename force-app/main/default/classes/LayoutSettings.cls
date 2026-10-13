public with sharing class LayoutSettings extends SettingsManager implements MethodUtils.MethodChecker{
   public static LayoutSettings instance {
        get {
            if(instance == null) {
                if (Test.isRunningTest()) {
                    instance = new LayoutSettings();
                }
            }
            return instance;
        }
        set;
    }
    public List<SectionWrapper> sections {get;set;}
    public String objectApiName {get;set;}
    public String developerName {get;set;}
    public String label {get;set;}
    public String type {get;set;}
    public List<SectionGroupTabWrapper> sectionGroupTab {get;set;}
    public String description {get;set;}
    public String theme {get;set;}
    public Boolean isActive {get;set;}
    public LayoutSettings() {
        this.sections = new List<SectionWrapper>();
        this.objectApiName = '';
        this.developerName = '';
        this.type = '';
        this.sectionGroupTab = new List<SectionGroupTabWrapper>();
        this.description = '';
        this.label = '';
        this.theme = '';
    }

    public static LayoutSettings loadPageLayoutSettings(String developerName) {
        return (LayoutSettings) SettingsManager.loadCustomMetadataSettings(LayoutSettings__mdt.SObjectType, developerName, LayoutSettings.class.getName());
    }

    public static List<LayoutSettings> loadAllPageLayoutSettings() {
        return (List<LayoutSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(LayoutSettings__mdt.SObjectType, LayoutSettings.class.getName(), null)), List<LayoutSettings>.class);
    }
    
    public LayoutSettings load(Object metadataRecord) {
        try {
            System.debug('metadataRecord: ' + JSON.serialize(metadataRecord));
            if(metadataRecord != null) {
                LayoutSettings__mdt pageLayoutSettingsRecord = (LayoutSettings__mdt) metadataRecord;
                this.type = pageLayoutSettingsRecord.Type__c;
                this.theme = pageLayoutSettingsRecord.Theme__c;
                this.objectApiName = pageLayoutSettingsRecord.ObjectApiName__c;
                this.label = pageLayoutSettingsRecord.Label;
                this.isActive = pageLayoutSettingsRecord.IsActive__c;
                this.description = pageLayoutSettingsRecord.Description__c;
                this.developerName = pageLayoutSettingsRecord.DeveloperName;
                this.sectionGroupTab = String.isNotBlank(pageLayoutSettingsRecord.SectionGroupTab__c)
                                        ? (List<SectionGroupTabWrapper>) JSON.deserialize(pageLayoutSettingsRecord.SectionGroupTab__c, List<SectionGroupTabWrapper>.class)
                                        : new List<SectionGroupTabWrapper>();
                this.sections = String.isNotBlank(pageLayoutSettingsRecord.Sections__c)
                                ? (List<SectionWrapper>) JSON.deserialize(pageLayoutSettingsRecord.Sections__c, List<SectionWrapper>.class)
                                : new List<SectionWrapper>();
            }
            return this;
        }
        catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static String save(LayoutSettings LayoutSettings) {
        if (LayoutSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                //SObjectType.LayoutSettings__mdt.fields.Label.Name => LayoutSettings.label,
                SObjectType.LayoutSettings__mdt.fields.ObjectApiName__c.Name => LayoutSettings.objectApiName,
                SObjectType.LayoutSettings__mdt.fields.Type__c.Name => LayoutSettings.type,
                SObjectType.LayoutSettings__mdt.fields.Theme__c.Name => LayoutSettings.theme,
                SObjectType.LayoutSettings__mdt.fields.IsActive__c.Name => LayoutSettings.isActive,
                SObjectType.LayoutSettings__mdt.fields.Description__c.Name => LayoutSettings.description,
                SObjectType.LayoutSettings__mdt.fields.Sections__c.Name => JSON.serialize(LayoutSettings.sections),
                SObjectType.LayoutSettings__mdt.fields.SectionGroupTab__c.Name => JSON.serialize(LayoutSettings.sectionGroupTab)
            };
            String developerName = String.isNotBlank(LayoutSettings.developerName)
                ? LayoutSettings.developerName  : LayoutSettings.label;

                //: LayoutSettings.label.replaceAll('\\s+', '_');
            System.debug('Developer Name = ' + developerName);
            return saveCustomMetadataSettings(LayoutSettings__mdt.SObjectType, developerName, fieldsValueMap);
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
    public with sharing class SectionGroupTabWrapper {
        public String Name;
        public String label;
        public String color;
    }
    public with sharing class SectionWrapper {
        public String title;
        public String name;
        public Boolean showTitle;
        public String titleStyle;
        public String styleVariant;
        public List<List<FieldWrapper>> fields;
        public FieldWrapper header;
        public List<IconWrapper> icons;
        public List<tabSetWrapper> tabset;
        public List<ComponentWrapper> components;
        public List<ActionWrapper> actions;
        public String region;
        public String sectionGroupTab;
        public Integer order;
        public List<AggregateWrapper> aggregates;
        public String themeName;

        public SectionWrapper() {
            this.fields = new List<List<LayoutSettings.FieldWrapper>>();
            this.icons = new List<IconWrapper>();
            this.components = new List<ComponentWrapper>();
            this.actions = new List<ActionWrapper>();
            this.aggregates = new List<AggregateWrapper>();
        }
    }
    public class FieldWrapper {
            public String fieldName;
            public String type;
            public Boolean isMandatory;
            public Boolean isReadOnly;
        }
        public class IconWrapper {
            public String name;
            public String type;
            public String contentType;
        }
        public class ComponentWrapper {
            public String label;
            public String name;
            public String style;
            public String type;
            public Map<String, String> params {get; set;}
        }
        public class tabSetWrapper {
            public String label;
            public ComponentWrapper component;
        }
        public class ActionWrapper {
            public String label;
            public String icon;
            public String actionType;
            public String redirectionType;
            public String redirectionValue;
            public String order;
            public String color;
        }
        public class AggregateWrapper {
            public String label {get; set;}
            public String objectApiName {get; set;}
            public String parentRelationshipApiName {get; set;}
            public String aggregateFunction {get; set;}
            public List<FilterConditionWrapper> filters {get; set;}

            public AggregateWrapper() {
                this.label = '';
                this.objectApiName = '';
                this.parentRelationshipApiName = '';
                this.aggregateFunction = 'COUNT';
                this.filters = new List<FilterConditionWrapper>();
            }
        }
        public class FilterConditionWrapper {
            public String fieldName {get; set;}
            public String operator {get; set;}
            public String value {get; set;}
            public String fieldType {get; set;}

            public FilterConditionWrapper() {
                this.fieldName = '';
                this.operator = '=';
                this.value = '';
                this.fieldType = '';
            }
        }
}