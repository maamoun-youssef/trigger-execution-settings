/**
 * @author ULiT
 * @date 02/12/2023
 * Advanced Settings class for myPromo App
 **/
global with sharing class PromoSettings extends SettingsManager implements MethodUtils.MethodChecker  {
    // CPF Report Screen Settings
    public List<StatusWrapper> CPStatusColors {get; set;}
    public Integer CPLayerNumbers {get; set;}
    public Integer numberOfMonthN1 {get; set;}
    public List<KPISetupWrapper> kpiSetups {get; set;}
    public PromoAgreementConfigurationWrapper promoAgreementConfiguration {get; set;}
    
    public PromoSettings() {
        this.CPStatusColors = new List<StatusWrapper>();
        for (Schema.PicklistEntry ple : CommercialPlan__c.Status__c.getDescribe().getPicklistValues()) {
            if (ple.isActive()) {
                this.CPStatusColors.add(new StatusWrapper(ple.getValue(), '#FFFFFF', '#000000'));
            }
        }
        this.CPLayerNumbers = 2;
        this.numberOfMonthN1 = null;
        this.kpiSetups = new List<KPISetupWrapper>();
        this.promoAgreementConfiguration = new PromoAgreementConfigurationWrapper();
    }
    
    public static PromoSettings loadPromoSettings() {
        return (PromoSettings) loadCustomMetadataSettings(PromoSettings__mdt.SObjectType, 'PromoSettings', PromoSettings.class.getName());
    }
    
    global static String loadPromoSettingsSerialized() {
        return JSON.serialize(loadPromoSettings());
    }
    
    public PromoSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            PromoSettings__mdt promoSettingsRecord = (PromoSettings__mdt) metadataRecord;
            // CPF Screen Settings
            this.CPStatusColors = String.isNotBlank(promoSettingsRecord.CPStatusColors__c) ? (List<StatusWrapper>) JSON.deserialize(promoSettingsRecord.CPStatusColors__c, List<StatusWrapper>.class) : new List<StatusWrapper>();
            this.CPLayerNumbers = promoSettingsRecord.CPLayerNumbers__c != null ? Integer.valueOf(promoSettingsRecord.CPLayerNumbers__c) : 2;
            this.kpiSetups = String.isNotBlank(promoSettingsRecord.KPISetup__c) ? (List<KPISetupWrapper>) JSON.deserialize(promoSettingsRecord.KPISetup__c, List<KPISetupWrapper>.class) : new List<KPISetupWrapper>();
            this.numberOfMonthN1 = promoSettingsRecord.NumberOfMonthN1__c != null ? Integer.valueOf(promoSettingsRecord.NumberOfMonthN1__c) : null;
            this.promoAgreementConfiguration = String.isNotBlank(promoSettingsRecord.PromoAgreementConfiguration__c)
            ? (PromoAgreementConfigurationWrapper) JSON.deserialize(promoSettingsRecord.PromoAgreementConfiguration__c, PromoAgreementConfigurationWrapper.class)
            : new PromoAgreementConfigurationWrapper();
        }
        return this;
    }
    
    public String save(PromoSettings promoSettings) {
        if (promoSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.PromoSettings__mdt.fields.CPLayerNumbers__c.Name => promoSettings.CPLayerNumbers,
                SObjectType.PromoSettings__mdt.fields.CPStatusColors__c.Name => JSON.serialize(promoSettings.CPStatusColors),
                SObjectType.PromoSettings__mdt.fields.NumberOfMonthN1__c.Name => promoSettings.numberOfMonthN1,
                SObjectType.PromoSettings__mdt.fields.KPISetup__c.Name => JSON.serialize(promoSettings.kpiSetups),
                SObjectType.PromoSettings__mdt.fields.PromoAgreementConfiguration__c.Name => JSON.serialize(promoSettings.promoAgreementConfiguration)
            };
            return saveCustomMetadataSettings(PromoSettings__mdt.SObjectType, 'PromoSettings', fieldsValueMap);
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
    
    public class StatusWrapper {
        public String name {get; set;}
        public String bgColor {get; set;}
        public String color {get; set;}
        
        public StatusWrapper(String name, String bgColor, String color) {
            this.name = name;
            this.bgColor = bgColor;
            this.color = color;
        }
    }
    
    public class KPISetupWrapper {
        public String CPFBudgetType {get; set;}
        public List<String> availableCPDBudgetTypes {get; set;}
        public List<FieldCPFWrapper> availableCPFFields {get; set;}
    }
    
    public class FieldCPFWrapper {
        public String key {get; set;}
        public Boolean isSelected {get; set;}
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        public Boolean isInput {get; set;}
        public List<String> CPDStatus {get; set;}
        public String multiStatusSelectSerialized {get; set;}
        public String CPDFieldConso {get; set;}
    }
    
    public class PromoAgreementConfigurationWrapper {
        public Set<String> promoAgreementGroupedFields {get; set;}
        public String promoAgreementsGrid {get; set;}
        public Map<String, String> promoAgreementsManagerGrid {get; set;}
        public PromoAgreementConfigurationWrapper () {
            this.promoAgreementGroupedFields = new Set<String> { SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Supplier__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.NegoScope__c.Name,
                //NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name) + '.' + SObjectType.CommercialPlan__c.fields.Pol_Com_Condition__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Contract__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Contract_Discount1__c.Name };
          this.promoAgreementsGrid = 'PromoAgreementsGrid';
          this.promoAgreementsManagerGrid = new Map<String, String>();
      }
    }
}