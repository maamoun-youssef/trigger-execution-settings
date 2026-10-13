/**
* @author ULiT
* @date 04/09/2025
* @description PageLayoutSettings__mdt Wrapper
******************************************************************************************************************************************* */
public with sharing class PageLayoutSettings extends SettingsManager implements MethodUtils.MethodChecker {

    public static PageLayoutSettings instance {
        get {
            if(instance == null) {
                if (Test.isRunningTest()) {
                    instance = new PageLayoutSettings();
                }
            }
            return instance;
        }
        set;
    }
    public String name {get; set;}
    public String objectApiName {get; set;}
    public String source {get; set;}
    public List<TabWrapper> tabs {get; set;}
    public List<ActionButtonWrapper> actionButtons {get; set;}
    public List<List<FieldsConfigurationWrapper>> fieldsConfiguration {get; set;}
    public Decimal nbOfRows {get; set;}
    public Boolean isFlowMode { get; set; }
    public String selectedFlow { get; set; }
    public List<String> topLeftCornerFields { get; set; }
    public String newTaskFlow { get; set; }
    public LogosConfigurationWrapper topLeftCornerLogo1 { get; set; }
    public LogosConfigurationWrapper topLeftCornerLogo2 { get; set; }
    public List<String> taskFields { get; set; }
    public HeaderFieldsConfigurationWrapper headerField { get; set; }
    public LogosConfigurationWrapper bottomLeftCornerLogo1 { get; set; }
    public LogosConfigurationWrapper bottomLeftCornerLogo2 { get; set; }
    public List<String> bottomLeftCornerFields { get; set; }
    public LogosConfigurationWrapper statusIcon { get; set; }
    public String statusField { get; set; }
    public LogosConfigurationWrapper activityRightIcon { get; set; }
    public LogosConfigurationWrapper activityLeftIcon { get; set; }
    public List<String> topRightCornerFields { get; set; }
    public List<String> activityFields { get; set; }
    public List<RelatedInformationsWrapper> relatedInformations { get; set; }
    public List<FilterConditionWrapper> templateFilterCriteria {get; set;}
    public PageLayoutSettings() {
        this.tabs = new List<TabWrapper>();
        this.actionButtons = new List<ActionButtonWrapper>();
        this.fieldsConfiguration = new List<List<FieldsConfigurationWrapper>>();
        this.topLeftCornerFields = new List<String>();
        this.taskFields = new List<String>();
        this.bottomLeftCornerFields = new List<String>();
        this.topRightCornerFields = new List<String>();
        this.activityFields = new List<String>();
        this.templateFilterCriteria = new List<FilterConditionWrapper>();
        this.nbOfRows = 0;
        this.isFlowMode = false;
    }
    public static PageLayoutSettings loadPageLayoutSettings(String developerName) {
        return (PageLayoutSettings) SettingsManager.loadCustomMetadataSettings(PageLayoutSettings__mdt.SObjectType, developerName, PageLayoutSettings.class.getName());
    }

    public static List<PageLayoutSettings> loadAllPageLayoutSettings() {
        return (List<PageLayoutSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(PageLayoutSettings__mdt.SObjectType, PageLayoutSettings.class.getName(), null)), List<PageLayoutSettings>.class);
    }
    
    public PageLayoutSettings load(Object metadataRecord) {
        try {
            System.debug('metadataRecord: ' + JSON.serialize(metadataRecord));
            if(metadataRecord != null) {
                PageLayoutSettings__mdt pageLayoutSettingsRecord = (PageLayoutSettings__mdt) metadataRecord;
                this.name = pageLayoutSettingsRecord.Name__c;
                this.objectApiName = pageLayoutSettingsRecord.ObjectApiName__c;
                this.source = pageLayoutSettingsRecord.Source__c;
                this.nbOfRows = pageLayoutSettingsRecord.NbOfRows__c;
                this.actionButtons = String.isNotBlank(pageLayoutSettingsRecord.ActionButtons__c)
                                    ? (List<ActionButtonWrapper>) JSON.deserialize(pageLayoutSettingsRecord.ActionButtons__c, List<ActionButtonWrapper>.class)
                                    : new List<ActionButtonWrapper>();
                this.tabs = String.isNotBlank(pageLayoutSettingsRecord.Tabs__c)
                                    ? (List<TabWrapper>) JSON.deserialize(pageLayoutSettingsRecord.Tabs__c, List<TabWrapper>.class)
                                    : new List<TabWrapper>();
                this.fieldsConfiguration = String.isNotBlank(pageLayoutSettingsRecord.FieldsConfiguration__c)
                                    ? (List<List<FieldsConfigurationWrapper>>) JSON.deserialize(pageLayoutSettingsRecord.FieldsConfiguration__c, List<List<FieldsConfigurationWrapper>>.class)
                                    : new List<List<FieldsConfigurationWrapper>>();
                this.isFlowMode = pageLayoutSettingsRecord.isManualEditMode__c == null
                                    ? false
                                    : !pageLayoutSettingsRecord.isManualEditMode__c;
                this.selectedFlow = pageLayoutSettingsRecord.EditFlow__c;
                this.topLeftCornerFields = String.isNotBlank(pageLayoutSettingsRecord.TopLeftCornerFields__c)
                                        ? (List<String>) JSON.deserialize(pageLayoutSettingsRecord.TopLeftCornerFields__c, List<String>.class)
                                        : new List<String>();
                this.newTaskFlow = pageLayoutSettingsRecord.NewTaskFlow__c;
                // this.topLeftCornerLogo1 = pageLayoutSettingsRecord.TopLeftCornerLogo1__c;
                this.topLeftCornerLogo1 = String.isNotBlank(pageLayoutSettingsRecord.TopLeftCornerLogo1__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.TopLeftCornerLogo1__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                // this.topLeftCornerLogo2 = pageLayoutSettingsRecord.TopLeftCornerLogo2__c;
                this.topLeftCornerLogo2 = String.isNotBlank(pageLayoutSettingsRecord.TopLeftCornerLogo2__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.TopLeftCornerLogo2__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                this.taskFields = String.isNotBlank(pageLayoutSettingsRecord.TaskFields__c)
                                    ? (List<String>) JSON.deserialize(pageLayoutSettingsRecord.TaskFields__c, List<String>.class)
                                    : new List<String>();
                this.headerField = String.isNotBlank(pageLayoutSettingsRecord.HeaderField__c)
                                    ? (HeaderFieldsConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.HeaderField__c, HeaderFieldsConfigurationWrapper.class)
                                    : new HeaderFieldsConfigurationWrapper();
                // this.bottomLeftCornerLogo1 = pageLayoutSettingsRecord.BottomLeftCornerLogo1__c;
                this.bottomLeftCornerLogo1 = String.isNotBlank(pageLayoutSettingsRecord.BottomLeftCornerLogo1__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.BottomLeftCornerLogo1__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                // this.bottomLeftCornerLogo2 = pageLayoutSettingsRecord.BottomLeftCornerLogo2__c;
                this.bottomLeftCornerLogo2 = String.isNotBlank(pageLayoutSettingsRecord.BottomLeftCornerLogo2__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.BottomLeftCornerLogo2__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                this.bottomLeftCornerFields = String.isNotBlank(pageLayoutSettingsRecord.BottomLeftCornerFields__c)
                                    ? (List<String>) JSON.deserialize(pageLayoutSettingsRecord.BottomLeftCornerFields__c, List<String>.class)
                                    : new List<String>();
                // this.statusIcon = pageLayoutSettingsRecord.StatusIcon__c;
                this.statusIcon = String.isNotBlank(pageLayoutSettingsRecord.StatusIcon__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.StatusIcon__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                this.statusField = pageLayoutSettingsRecord.StatusField__c;
                // this.activityRightIcon = pageLayoutSettingsRecord.ActivityRightIcon__c;
                this.activityRightIcon = String.isNotBlank(pageLayoutSettingsRecord.ActivityRightIcon__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.ActivityRightIcon__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper();           
                // this.activityLeftIcon = pageLayoutSettingsRecord.ActivityLeftIcon__c;   
                this.activityLeftIcon = String.isNotBlank(pageLayoutSettingsRecord.ActivityLeftIcon__c)
                                    ? (LogosConfigurationWrapper) JSON.deserialize(pageLayoutSettingsRecord.ActivityLeftIcon__c, LogosConfigurationWrapper.class)
                                    : new LogosConfigurationWrapper(); 
                this.topRightCornerFields = String.isNotBlank(pageLayoutSettingsRecord.TopRightCornerFields__c)
                                    ? (List<String>) JSON.deserialize(pageLayoutSettingsRecord.TopRightCornerFields__c, List<String>.class)
                                    : new List<String>();
                this.activityFields = String.isNotBlank(pageLayoutSettingsRecord.ActivityFields__c)
                                    ? (List<String>) JSON.deserialize(pageLayoutSettingsRecord.ActivityFields__c, List<String>.class)
                                    : new List<String>();
                this.relatedInformations = String.isNotBlank(pageLayoutSettingsRecord.RelatedInformations__c)
                                    ? (List<RelatedInformationsWrapper>) JSON.deserialize(pageLayoutSettingsRecord.RelatedInformations__c, List<RelatedInformationsWrapper>.class)
                                    : new List<RelatedInformationsWrapper>();
                this.templateFilterCriteria = String.isNotBlank(pageLayoutSettingsRecord.TemplateFilterCriteria__c)
                                    ? (List<FilterConditionWrapper>) JSON.deserialize(pageLayoutSettingsRecord.TemplateFilterCriteria__c, List<FilterConditionWrapper>.class)
                                    : new List<FilterConditionWrapper>();
            }
            return this;
        }
        catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public String save(PageLayoutSettings PageLayoutSettings) {
        if (PageLayoutSettings != null) {
            if (PageLayoutSettings.headerField == null) {
                PageLayoutSettings.headerField = new HeaderFieldsConfigurationWrapper();
            }
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.PageLayoutSettings__mdt.fields.ActionButtons__c.Name => JSON.serialize(PageLayoutSettings.actionButtons),
                SObjectType.PageLayoutSettings__mdt.fields.Name__c.Name => PageLayoutSettings.name,
                SObjectType.PageLayoutSettings__mdt.fields.Source__c.Name => PageLayoutSettings.source,
                SObjectType.PageLayoutSettings__mdt.fields.ObjectApiName__c.Name => PageLayoutSettings.objectApiName,
                SObjectType.PageLayoutSettings__mdt.fields.NbOfRows__c.Name => PageLayoutSettings.nbOfRows,
                SObjectType.PageLayoutSettings__mdt.fields.Tabs__c.Name => JSON.serialize(PageLayoutSettings.tabs),
                SObjectType.PageLayoutSettings__mdt.fields.FieldsConfiguration__c.Name => JSON.serialize(PageLayoutSettings.fieldsConfiguration),
                SObjectType.PageLayoutSettings__mdt.fields.isManualEditMode__c.Name => !PageLayoutSettings.isFlowMode,
                SObjectType.PageLayoutSettings__mdt.fields.EditFlow__c.Name => PageLayoutSettings.selectedFlow,
                SObjectType.PageLayoutSettings__mdt.fields.TopLeftCornerFields__c.Name => JSON.serialize(PageLayoutSettings.topLeftCornerFields),
                SObjectType.PageLayoutSettings__mdt.fields.NewTaskFlow__c.Name => PageLayoutSettings.newTaskFlow,
                SObjectType.PageLayoutSettings__mdt.fields.TopLeftCornerLogo1__c.Name => JSON.serialize(PageLayoutSettings.topLeftCornerLogo1),
                SObjectType.PageLayoutSettings__mdt.fields.TopLeftCornerLogo2__c.Name => JSON.serialize(PageLayoutSettings.topLeftCornerLogo2),
                SObjectType.PageLayoutSettings__mdt.fields.HeaderField__c.Name => JSON.serialize(PageLayoutSettings.headerField),
                SObjectType.PageLayoutSettings__mdt.fields.TaskFields__c.Name => JSON.serialize(PageLayoutSettings.taskFields),
                SObjectType.PageLayoutSettings__mdt.fields.BottomLeftCornerLogo1__c.Name => JSON.serialize(PageLayoutSettings.bottomLeftCornerLogo1),
                SObjectType.PageLayoutSettings__mdt.fields.BottomLeftCornerLogo2__c.Name => JSON.serialize(PageLayoutSettings.bottomLeftCornerLogo2),
                SObjectType.PageLayoutSettings__mdt.fields.BottomLeftCornerFields__c.Name => JSON.serialize(PageLayoutSettings.bottomLeftCornerFields),
                SObjectType.PageLayoutSettings__mdt.fields.StatusIcon__c.Name => JSON.serialize(PageLayoutSettings.statusIcon),
                SObjectType.PageLayoutSettings__mdt.fields.StatusField__c.Name => PageLayoutSettings.statusField,
                SObjectType.PageLayoutSettings__mdt.fields.ActivityRightIcon__c.Name => JSON.serialize(PageLayoutSettings.activityRightIcon),
                SObjectType.PageLayoutSettings__mdt.fields.ActivityLeftIcon__c.Name => JSON.serialize(PageLayoutSettings.activityLeftIcon),
                SObjectType.PageLayoutSettings__mdt.fields.TopRightCornerFields__c.Name => JSON.serialize(PageLayoutSettings.topRightCornerFields),
                SObjectType.PageLayoutSettings__mdt.fields.ActivityFields__c.Name => JSON.serialize(PageLayoutSettings.activityFields),
                SObjectType.PageLayoutSettings__mdt.fields.RelatedInformations__c.Name => JSON.serialize(PageLayoutSettings.relatedInformations),
                SObjectType.PageLayoutSettings__mdt.fields.TemplateFilterCriteria__c.Name => JSON.serialize(PageLayoutSettings.templateFilterCriteria)
            };
            String developerName = PageLayoutSettings.name.replaceAll('\\s+', '_');
            System.debug('Developer Name = ' + developerName);
            return saveCustomMetadataSettings(PageLayoutSettings__mdt.SObjectType, developerName, fieldsValueMap);
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
    
    public class ActionButtonWrapper {
        public String color {get; set;}
        public String label {get; set;}
        public String flow {get; set;}
        // Default constructor
        public ActionButtonWrapper() {}
        // Parameterized constructor
        public ActionButtonWrapper(String color ,String label, String flow) {
            this.color = color;
            this.label = label;
            this.flow = flow;
        }
    }
    
    public virtual class FieldsConfigurationWrapper {
        public String fieldName {get; set;}
        public Boolean isReadOnly {get; set;}
        public Boolean isMandatory {get; set;}

        public FieldsConfigurationWrapper(String fieldName, Boolean isReadOnly, Boolean isMandatory) {
            this.fieldName = fieldName;
            this.isReadOnly = isReadOnly ? isReadOnly : false;
            this.isMandatory = isMandatory ? isMandatory: false;
        }
        public FieldsConfigurationWrapper(){}
    }
    
    public class HeaderFieldsConfigurationWrapper {
        public String fieldName {get; set;}
        public Boolean isReadOnly {get; set;}
        public Boolean isMandatory {get; set;}
        public Boolean showHeaderField {get; set;}

        public HeaderFieldsConfigurationWrapper(String fieldName, Boolean isReadOnly, Boolean isMandatory) {
            this.fieldName = fieldName;
            this.isReadOnly = isReadOnly ? isReadOnly : false;
            this.isMandatory = isMandatory ? isMandatory: false;
            this.showHeaderField = true;
        }
        public HeaderFieldsConfigurationWrapper(){}
    }
    
    public class TabWrapper {
        public String label {get; set;}
        public String content {get; set;}
        public String contentType {get; set;}
        public Map<String, String> params {get; set;}

        public TabWrapper(String label, String content, String contentType ) {
            this.label = label;
            this.content = content;
            this.contentType = contentType;
            this.params = params;
        }
    }

    public class RelatedInformationsWrapper {
        public String objectApiName {get; set;}
        public String parentRelationshipApiName {get; set;}
        public String aggregateFunction {get; set;}
        public String aggregateFieldName {get; set;}
        public String label {get; set;}
        public List<FilterConditionWrapper> filters {get; set;}
        public List<String> groupByFields {get; set;}
        public String whereClause {get; set;}

        public RelatedInformationsWrapper() {
            this.objectApiName = '';
            this.parentRelationshipApiName = '';
            this.aggregateFunction = 'COUNT';
            this.aggregateFieldName = '';
            this.label = '';
            this.filters = new List<FilterConditionWrapper>();
            this.groupByFields = new List<String>();
            this.whereClause = '';
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
    public class LogosConfigurationWrapper {
        public String value {get; set;}
        public Boolean isStaticRessource {get; set;}
        
        public LogosConfigurationWrapper(String value, Boolean isStaticRessource) {
            this.value = value;
            this.isStaticRessource = isStaticRessource ? isStaticRessource : false;
            
        }
        public LogosConfigurationWrapper(){}
    }
}