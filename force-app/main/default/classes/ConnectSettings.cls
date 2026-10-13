/**
 * @author ULiT
 * @date 28/10/2024
 * Advanced Settings class for NegoptimConnect
 **/
global with sharing class ConnectSettings extends SettingsManager implements MethodUtils.MethodChecker {
    public List<String> additionalFields {get; set;} //todo
    public List<String> approvalProfiles {get; set;} //todo
    public List<String> cardHeaderFields {get; set;} //todo
    public String connectLogoIcon {get; set;}
    public String connectUserGroup {get; set;}
    public String connectUserPermissionSetGroup {get; set;}

    public String LanguageLocaleKey  {get; set;}
    public String LocaleSidKey{get; set;}

    public String connectUploadFileFlow {get; set;}
    public String uploadFileFlow {get; set;}
    public String connectUserProfile {get; set;}
    public String directoryManager {get; set;}
    public Boolean enableSelfOnboarding {get; set;}
    public Boolean enableUserSettings {get; set;}
    public MenuWrapper rolePermissions { get; set; }
    public String image {get; set;}
    public LicenseQuotasWrapper licenseQuotas {get; set;} //todo
    public List<ModulesConfigurationWrapper> modulesConfiguration  {get; set;} //todo
    public List<String> nonApprovalProfiles {get; set;} //todo
    public String onboardingVideoUrl {get; set;}
    public String guideDocUrl {get; set;}
    public List<String> searchableObjects {get; set;} //todo
    public List<String> summaryFields {get; set;} //todo
    // Sell-in
    public String sellinStatementRevenueType {get; set;}
    public String statementGenerationMode {get; set;}
    public List<String> sellInRevenueOptions {get; set;}
    public String sellInWelcomeMessage {get; set;}
    public String sellInSubmissionFlow {get; set;}
    
    public ConnectSettings() {
        this.enableSelfOnboarding = false;
        this.enableUserSettings = false;
        this.statementGenerationMode = 'Manual';
        this.sellinStatementRevenueType = NegoptimHelper.getObjectRecordTypeMapIds(SellInStatement__c.SObjectType).get('SSPeriod');
        this.sellInRevenueOptions = new List<String>{
            'LBL_Connect_RegularDiscountableRevenue',
            'LBL_Connect_RegularDiscountableQuantity',
            'LBL_Connect_PromoDiscountableQuantity'
        };
        this.sellInWelcomeMessage = '{!$label.LBL_Connect_Statement_Welcome_Message}';
        this.sellInSubmissionFlow = 'SCREEN_SellIn_Statement_Statement_Submission';
        this.connectUploadFileFlow = 'SCREEN_Connect_File_Directory_Upload';
        this.uploadFileFlow = 'SCREEN_File_Directory_Upload';
        this.summaryFields = new List<String>{
            'Phone',
            'MobilePhone',
            'Email',
            'ReportsToId'
        };
        this.cardHeaderFields = new List<String>{
            'Phone',
            'MobilePhone',
            'Email'
        };
        this.additionalFields = new List<String>{
            'Title',
            'ReportsToId',
            SObjectType.Contact.fields.IsOrgAdmin__c.Name
        };
        this.connectUserPermissionSetGroup = 'negOptimConnectPermissionSetGroup';
        this.licenseQuotas = new LicenseQuotasWrapper();
        this.rolePermissions = new MenuWrapper();
        this.LanguageLocaleKey = 'fr';
        this.LocaleSidKey = 'fr_FR';
    }
    
    public static ConnectSettings loadConnectSettings() {
        return (ConnectSettings) SettingsManager.loadCustomMetadataSettings(ConnectSettings__mdt.SObjectType, 'ConnectSettings', ConnectSettings.class.getName());
    }
    
    global static String loadConnectSettingsSerialized() {
        return JSON.serialize(loadConnectSettings());
    }
    
    public ConnectSettings load(Object metadataRecord) {
        try {
            if(metadataRecord != null) {
                ConnectSettings__mdt connectSettingsRecord = (ConnectSettings__mdt) metadataRecord;
                this.additionalFields = String.isNotBlank(connectSettingsRecord.AdditionalFields__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.AdditionalFields__c, List<String>.class)
                    : this.additionalFields;
                this.approvalProfiles = String.isNotBlank(connectSettingsRecord.ApprovalProfiles__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.ApprovalProfiles__c, List<String>.class)
                    : new List<String>();
                this.cardHeaderFields = String.isNotBlank(connectSettingsRecord.CardHeaderFields__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.CardHeaderFields__c, List<String>.class)
                    : this.cardHeaderFields;
                this.connectLogoIcon = connectSettingsRecord.ConnectLogoIcon__c;
                this.connectUserGroup = connectSettingsRecord.ConnectUserGroup__c;
                this.connectUploadFileFlow = String.isNotBlank(connectSettingsRecord.ConnectUploadFileFlow__c)
                    ? connectSettingsRecord.ConnectUploadFileFlow__c
                    : this.connectUploadFileFlow;
                this.uploadFileFlow = String.isNotBlank(connectSettingsRecord.UploadFileFlow__c)
                    ? connectSettingsRecord.UploadFileFlow__c
                    : this.uploadFileFlow;
                this.connectUserProfile = connectSettingsRecord.ConnectUserProfile__c;
                this.directoryManager = connectSettingsRecord.DirectoryManager__c;
                this.enableSelfOnboarding = connectSettingsRecord.EnableSelfOnboarding__c;
                this.enableUserSettings = connectSettingsRecord.EnableUserSettings__c;
                this.image = connectSettingsRecord.Image__c;
                this.licenseQuotas = String.isNotBlank(connectSettingsRecord.LicenseQuotas__c)
                    ? (LicenseQuotasWrapper) JSON.deserialize(connectSettingsRecord.LicenseQuotas__c, LicenseQuotasWrapper.class)
                    : new LicenseQuotasWrapper();
                if (String.isNotBlank(connectSettingsRecord.ModulesConfiguration__c)) {
                    this.modulesConfiguration = (List<ModulesConfigurationWrapper>) JSON.deserialize(connectSettingsRecord.ModulesConfiguration__c, List<ModulesConfigurationWrapper>.class);
                } else {
                    this.modulesConfiguration = new List<ModulesConfigurationWrapper>();
                    for (Integer i = 1; i < 9; i++) {
                        this.modulesConfiguration.add(new ModulesConfigurationWrapper('', '', ''/*, true*/, true, '', i));
                    }
                }
                this.nonApprovalProfiles = String.isNotBlank(connectSettingsRecord.NonApprovalProfiles__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.NonApprovalProfiles__c, List<String>.class)
                    : new List<String>();
                this.onboardingVideoUrl = connectSettingsRecord.OnboardingVideoUrl__c;
                this.guideDocUrl = connectSettingsRecord.GuideDocURL__c;
                this.searchableObjects = String.isNotBlank(connectSettingsRecord.SearchableObjects__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.SearchableObjects__c, List<String>.class)
                    : new List<String>();
                this.summaryFields = String.isNotBlank(connectSettingsRecord.SummaryFields__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.SummaryFields__c, List<String>.class)
                    : this.summaryFields;
                this.rolePermissions = String.isNotBlank(connectSettingsRecord.RolePermissions__c)
                    ? (MenuWrapper) JSON.deserialize(connectSettingsRecord.RolePermissions__c, MenuWrapper.class)
                    : new MenuWrapper();
                // Sell-in
                this.sellinStatementRevenueType = String.isNotBlank(connectSettingsRecord.SellinStatementRevenueType__c)
                    ? connectSettingsRecord.SellinStatementRevenueType__c
                    : this.sellinStatementRevenueType;
                this.statementGenerationMode = String.isNotBlank(connectSettingsRecord.StatementGenerationMode__c)
                    ? connectSettingsRecord.StatementGenerationMode__c
                    : this.statementGenerationMode;
                this.sellInRevenueOptions = String.isNotBlank(connectSettingsRecord.SellInRevenueOptions__c)
                    ? (List<String>) JSON.deserialize(connectSettingsRecord.SellInRevenueOptions__c, List<String>.class)
                    : this.sellInRevenueOptions;
                this.sellInWelcomeMessage = String.isNotBlank(connectSettingsRecord.SellInWelcomeMessage__c)
                    ? connectSettingsRecord.SellInWelcomeMessage__c
                    : this.sellInWelcomeMessage;
                this.sellInSubmissionFlow = String.isNotBlank(connectSettingsRecord.SellInSubmissionFlow__c)
                    ? connectSettingsRecord.SellInSubmissionFlow__c
                    : this.sellInSubmissionFlow;
                this.connectUserPermissionSetGroup = String.isNotBlank(connectSettingsRecord.ConnectUserPermissionSetGroup__c)
                    ? connectSettingsRecord.ConnectUserPermissionSetGroup__c
                    : 'negOptimConnectPermissionSetGroup';
                    this.LanguageLocaleKey = String.isNotBlank(connectSettingsRecord.LanguageLocaleKey__c)
                    ? connectSettingsRecord.LanguageLocaleKey__c
                    :'fr' ;
                    this.LocaleSidKey = String.isNotBlank(connectSettingsRecord.LocaleSidKey__c)
                    ? connectSettingsRecord.LocaleSidKey__c
                    :'fr_FR' ;
            }
            return this;
        } catch (Exception err) {
            System.debug(err.getMessage());
            throw new AuraHandledException(err.getMessage());
        }
    }
    
    public String save(ConnectSettings connectSettings) {
        if (connectSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                // Welcome page
                SObjectType.ConnectSettings__mdt.fields.SearchableObjects__c.Name => JSON.serialize(connectSettings.searchableObjects),
                SObjectType.ConnectSettings__mdt.fields.ConnectLogoIcon__c.Name => connectSettings.connectLogoIcon,
                SObjectType.ConnectSettings__mdt.fields.OnboardingVideoUrl__c.Name => connectSettings.onboardingVideoUrl,
                SObjectType.ConnectSettings__mdt.fields.GuideDocURL__c.Name => connectSettings.guideDocUrl,
                SObjectType.ConnectSettings__mdt.fields.ModulesConfiguration__c.Name => JSON.serialize(connectSettings.modulesConfiguration),
                SObjectType.ConnectSettings__mdt.fields.Image__c.Name => connectSettings.image,
                SObjectType.ConnectSettings__mdt.fields.EnableSelfOnboarding__c.Name => connectSettings.enableSelfOnboarding,
                SObjectType.ConnectSettings__mdt.fields.EnableUserSettings__c.Name => connectSettings.enableUserSettings,
                // COD
                SObjectType.ConnectSettings__mdt.fields.ApprovalProfiles__c.Name => JSON.serialize(connectSettings.approvalProfiles),
                SObjectType.ConnectSettings__mdt.fields.NonApprovalProfiles__c.Name => JSON.serialize(connectSettings.nonApprovalProfiles),
                SObjectType.ConnectSettings__mdt.fields.SummaryFields__c.Name => JSON.serialize(connectSettings.summaryFields),
                SObjectType.ConnectSettings__mdt.fields.CardHeaderFields__c.Name => JSON.serialize(connectSettings.cardHeaderFields),
                SObjectType.ConnectSettings__mdt.fields.AdditionalFields__c.Name => JSON.serialize(connectSettings.additionalFields),
                SObjectType.ConnectSettings__mdt.fields.LicenseQuotas__c.Name => JSON.serialize(connectSettings.licenseQuotas),
                SObjectType.ConnectSettings__mdt.fields.ConnectUserProfile__c.Name => connectSettings.connectUserProfile,
                SObjectType.ConnectSettings__mdt.fields.ConnectUserGroup__c.Name => connectSettings.connectUserGroup,
                SObjectType.ConnectSettings__mdt.fields.ConnectUserPermissionSetGroup__c.Name => connectSettings.connectUserPermissionSetGroup,
                SObjectType.ConnectSettings__mdt.fields.LanguageLocaleKey__c.Name => connectSettings.LanguageLocaleKey,
                SObjectType.ConnectSettings__mdt.fields.LocaleSidKey__c.Name => connectSettings.LocaleSidKey,
                SObjectType.ConnectSettings__mdt.fields.ConnectUploadFileFlow__c.Name => connectSettings.connectUploadFileFlow,
                SObjectType.ConnectSettings__mdt.fields.UploadFileFlow__c.Name => connectSettings.uploadFileFlow,
                SObjectType.ConnectSettings__mdt.fields.DirectoryManager__c.Name => connectSettings.directoryManager,
                SObjectType.ConnectSettings__mdt.fields.RolePermissions__c.Name => JSON.serialize(connectSettings.rolePermissions),
                //Sell-in
                SObjectType.ConnectSettings__mdt.fields.SellinStatementRevenueType__c.Name => connectSettings.sellinStatementRevenueType,
                SObjectType.ConnectSettings__mdt.fields.StatementGenerationMode__c.Name => connectSettings.statementGenerationMode,
                SObjectType.ConnectSettings__mdt.fields.SellInRevenueOptions__c.Name => JSON.serialize(connectSettings.sellInRevenueOptions),
                SObjectType.ConnectSettings__mdt.fields.SellInWelcomeMessage__c.Name => connectSettings.sellInWelcomeMessage,
                SObjectType.ConnectSettings__mdt.fields.SellInSubmissionFlow__c.Name => connectSettings.sellInSubmissionFlow
            };
            return saveCustomMetadataSettings(ConnectSettings__mdt.SObjectType, 'ConnectSettings', fieldsValueMap);
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
    
    public class ModulesConfigurationWrapper {
        public String iconUrl {get; set;}
        public String redirectionType {get; set;}
        public String redirection {get; set;}
        // public Boolean isDisplayed {get; set;}
        public Boolean isActive {get; set;}
        public String name {get; set;}
        public Integer index {get; set;}
        public ModulesConfigurationWrapper(String iconUrl, String redirectionType, String redirection/* , Boolean isDisplayed */, Boolean isActive, String name, Integer index) {
            this.iconUrl = iconUrl;
            this.redirectionType = redirectionType;
            this.redirection = redirection;
            // this.isDisplayed = isDisplayed;
            this.isActive = isActive;
            this.name = name;
            this.index = index;
            
        }
    }
    
    public class LicenseQuotasWrapper {
        public Boolean activation {get; set;}
        public Integer licensePerSupplier {get; set;}
        // Default constructor
        public LicenseQuotasWrapper() {
            this.activation = false;
            this.licensePerSupplier = 0;
        }
        // Parameterized constructor
        public LicenseQuotasWrapper(Boolean activation, Integer licensePerSupplier) {
            this.activation = activation;
            this.licensePerSupplier = licensePerSupplier;
        }
    }
    
    public class MenuWrapper {
        // Properties matching the JSON structure
        public String name { get; set; }
        public List<PermissionWrapper> roles { get; set; }
        public List<String> headers { get; set; }
        MenuWrapper() {
            this.name = 'LBL_Connect_DocumentsCenter_Menu';
            Map<String, String> contactRole = ConnectSettingsCtrl.getPicklistValues(SObjectType.ContactOperationalDirectory__c.getName(), SObjectType.ContactOperationalDirectory__c.fields.ContactRole__c.Name);
            this.headers = new List<String> (contactRole.keySet());
            List<PermissionDetailWrapper> permissionDetails = new List<PermissionDetailWrapper>();
            for (String header : this.headers) {
                permissionDetails.add(new PermissionDetailWrapper(header, false, false));
            }
            List<PermissionWrapper> roles = new List<PermissionWrapper>();
            Schema.DescribeFieldResult fDesc = FileDirectory__c.SubType__c.getDescribe();
            Map<String, Id> FDRTMap = NegoptimHelper.getObjectRecordTypeMapIds(FileDirectory__c.SObjectType);
            for (String FDRTKey : FDRTMap.keySet()) {
                if(FDRTKey == null || FDRTKey == 'Master') {
                    continue;
                }
                List<PermissionRoles> permissionRoles = new List<PermissionRoles>();
                Map<String, String> pe;
                if (!Test.isRunningTest() && !Trigger.isExecuting) {
                    pe = PicklistHelper.getPicklistValuesByRecordTypeId(FileDirectory__c.SObjectType, FileDirectory__c.SubType__c, FDRTMap.get(FDRTKey));
                } else {
                    pe = new Map<String, String>();
                    for (Schema.PicklistEntry pickListVal : FileDirectory__c.SubType__c.getDescribe().getPicklistValues()) {
                        pe.put(pickListVal.getValue(), pickListVal.getLabel());
                    }
                }
                for (String value : pe.keySet()) {
                    permissionRoles.add(new PermissionRoles(value, permissionDetails));
                }
                roles.add(new PermissionWrapper(FDRTKey, permissionRoles));
            }
            this.roles = roles;
        }
        // Parameterized constructor
        public MenuWrapper(String name, String type, List<PermissionWrapper> roles, List<String> headers) {
            this.name = name;
            this.roles = roles;
            this.headers= headers;
        }
    }
    public class PermissionWrapper {
        // Properties matching the JSON structure
        public String type { get; set; }
        public List<PermissionRoles> permissionRoles { get; set; }
        
        // Parameterized constructor
        public PermissionWrapper(String type, List<PermissionRoles> permissionRoles) {
            this.type = type;
            this.permissionRoles = permissionRoles;
        }
        // Parameterized constructor
        public PermissionWrapper() {
            this.type = '';
            this.permissionRoles = new List<PermissionRoles>();
        }
    }
    public class PermissionRoles {
        // Properties matching the JSON structure
        public String title { get; set; }
        public List<PermissionDetailWrapper> permissionDetails { get; set; }
        
        // Parameterized constructor
        public PermissionRoles(String title, List<PermissionDetailWrapper> permissionDetails) {
            this.title = title;
            this.permissionDetails = permissionDetails;
        }
        public PermissionRoles() {
            this.title = '';
            this.permissionDetails = new List<PermissionDetailWrapper>();
        }
    }
    
    public class PermissionDetailWrapper  {
        public String name { get; set; }
        public Boolean hasAccessToFile { get; set; }
        public Boolean canUploadFile { get; set; }
        
        public PermissionDetailWrapper (String name, Boolean canUploadFile, Boolean hasAccessToFile) {
            this.name = name;
            this.canUploadFile = canUploadFile;
            this.hasAccessToFile = hasAccessToFile;
        }
        
        // Default constructor
        public PermissionDetailWrapper () {
            this.name = '';
            this.canUploadFile = false;
            this.hasAccessToFile = false;
        }
    }
}