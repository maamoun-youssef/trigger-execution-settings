/**
 * @author ULiT
 * @date 25/04/2024
 * Advanced Settings class for myOffer App
 **/
public with sharing class AssortmentSettings extends SettingsManager implements MethodUtils.MethodChecker {
    // General Settings
    public Boolean applyCalcFullYearQty_P1 {get; set;}
    public Boolean assortmentProductSelectionRespectBU {get; set;}
    public Boolean assortmentProductSelectionRespectMarket {get; set;}
    public Boolean assortmentProductSelectionRespectHierarchy {get; set;}
    public String KPI {get; set;}
    // Grid Layout Settings
    public String assortmentMatrixNego {get; set;}
    public String assortmentMatrixTarget {get; set;}
    public String assortmentMatrixBudget {get; set;}
    public String assortmentProductSelectionGrid {get; set;}
    public String assortmentProductSelectionUNGrid {get; set;}
    public String assortmentDirectAccessPluginGrid {get; set;}
    // Hypothesis report Settings
    public String salesCannibalizationRates {get; set;}
    // Import Feild Settings
    public String availableImportFields {get; set;}
    // Scope Settings
    public String scopeSettings {get; set;}
    // Scope Settings
    public Date tmpTodayDate {get; set;}
    //Assortment Simulator Settings
    public AssortmentSimulatorConfigurationWrapper assortmentSimulatorConfiguration {get; set;}
    //Assortment Bu Config 
     public AssortmentBUConfigurationWrapper assortmentBUConfiguration {get; set;}

    public AssortmentSettings() {
        // General Settings
        this.applyCalcFullYearQty_P1 = false;
        this.assortmentProductSelectionRespectBU = false;
        this.assortmentProductSelectionRespectMarket = false;
        this.assortmentProductSelectionRespectHierarchy = false;
        this.KPI = 'WD';
        // Grid Layout Settings
        this.assortmentMatrixNego = 'AssortmentMatrixNego';
        this.assortmentMatrixTarget = 'AssortmentMatrixTarget';
        this.assortmentMatrixBudget = 'AssortmentMatrixBudget';
        this.assortmentProductSelectionGrid = 'AssortmentProductSelectionGrid';
        this.assortmentProductSelectionUNGrid = 'AssortmentProductSelectionUNGrid';
        this.assortmentDirectAccessPluginGrid = 'AssortmentDirectAccessPlugin';
        // Hypothesis report Settings
        this.salesCannibalizationRates = '[]';
        // Import Feild Settings
        this.availableImportFields = JSON.serialize(new List<AssortmentSettings.ImportFieldWrapper>{new AssortmentSettings.ImportFieldWrapper(SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name, SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.label, true, true)});
        // Scope Settings
        this.scopeSettings = '[]';
        this.tmpTodayDate = Date.today();
        //Assortment Simulator Settings
        this.assortmentSimulatorConfiguration = new AssortmentSimulatorConfigurationWrapper();
        //Assortement Bu Config 
        this.assortmentBUConfiguration = new AssortmentBUConfigurationWrapper();
    }
    
    public static AssortmentSettings loadAssortmentSettings() {
        return (AssortmentSettings) SettingsManager.loadCustomMetadataSettings(AssortmentSettings__mdt.SObjectType, 'AssortmentSettings', AssortmentSettings.class.getName());
    }
    
    public AssortmentSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            AssortmentSettings__mdt assortmentSettingsRecord = (AssortmentSettings__mdt) metadataRecord;
            this.applyCalcFullYearQty_P1 = assortmentSettingsRecord.ApplyCalcFullYearQtyP1__c == null ? false : assortmentSettingsRecord.ApplyCalcFullYearQtyP1__c;
            this.assortmentProductSelectionRespectBU = assortmentSettingsRecord.AssortmentProductSelectionRespectBU__c == null ? false : assortmentSettingsRecord.AssortmentProductSelectionRespectBU__c;
            this.assortmentProductSelectionRespectMarket = assortmentSettingsRecord.ASProductSelectionRespectMarket__c == null ? false : assortmentSettingsRecord.ASProductSelectionRespectMarket__c;
            this.assortmentProductSelectionRespectHierarchy = assortmentSettingsRecord.ASProductSelectionRespectHierarchy__c == null ? false : assortmentSettingsRecord.ASProductSelectionRespectHierarchy__c;
            this.KPI = String.isBlank(assortmentSettingsRecord.KPI__c) ? 'WD' : assortmentSettingsRecord.KPI__c;
            this.assortmentMatrixNego = String.isBlank(assortmentSettingsRecord.AssortmentMatrixNego__c) ? 'AssortmentMatrixNego' : assortmentSettingsRecord.AssortmentMatrixNego__c;
            this.assortmentMatrixTarget = String.isBlank(assortmentSettingsRecord.AssortmentMatrixTarget__c) ? 'AssortmentMatrixTarget' : assortmentSettingsRecord.AssortmentMatrixTarget__c;
            this.assortmentMatrixBudget = String.isBlank(assortmentSettingsRecord.AssortmentMatrixBudget__c) ? 'AssortmentMatrixBudget' : assortmentSettingsRecord.AssortmentMatrixBudget__c;
            this.assortmentProductSelectionGrid = String.isBlank(assortmentSettingsRecord.AssortmentProductSelectionGrid__c) ? 'AssortmentProductSelectionGrid' : assortmentSettingsRecord.AssortmentProductSelectionGrid__c;
            this.assortmentProductSelectionUNGrid = String.isBlank(assortmentSettingsRecord.AssortmentProductSelectionUNGrid__c) ? 'AssortmentProductSelectionUNGrid' : assortmentSettingsRecord.AssortmentProductSelectionUNGrid__c;
            this.assortmentDirectAccessPluginGrid = String.isBlank(assortmentSettingsRecord.AssortmentDirectAccessPluginGrid__c) ? 'AssortmentDirectAccessPlugin' : assortmentSettingsRecord.AssortmentDirectAccessPluginGrid__c;
            this.salesCannibalizationRates = String.isBlank(assortmentSettingsRecord.SalesCannibalizationRates__c) ? '[]' : assortmentSettingsRecord.SalesCannibalizationRates__c;
            this.availableImportFields = String.isBlank(assortmentSettingsRecord.AvailableImportFields__c) ? JSON.serialize(new List<AssortmentSettings.ImportFieldWrapper>{new AssortmentSettings.ImportFieldWrapper(SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name, SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.label, true, true)}) : assortmentSettingsRecord.AvailableImportFields__c;
            this.scopeSettings = String.isBlank(assortmentSettingsRecord.ScopeSettings__c) ? '[]' : assortmentSettingsRecord.ScopeSettings__c;
            this.tmpTodayDate = assortmentSettingsRecord.TMP_TodayDate__c != null ? assortmentSettingsRecord.TMP_TodayDate__c : Date.today();
            this.assortmentSimulatorConfiguration = String.isNotBlank(assortmentSettingsRecord.AssortmentSimulatorConfiguration__c) ? (AssortmentSimulatorConfigurationWrapper) JSON.deserialize(assortmentSettingsRecord.AssortmentSimulatorConfiguration__c, AssortmentSimulatorConfigurationWrapper.class) : new AssortmentSimulatorConfigurationWrapper();
            this.assortmentBUConfiguration = String.isNotBlank(assortmentSettingsRecord.AssortmentBUConfiguration__c) ? (AssortmentBUConfigurationWrapper) JSON.deserialize(assortmentSettingsRecord.AssortmentBUConfiguration__c, AssortmentBUConfigurationWrapper.class) : new AssortmentBUConfigurationWrapper();
        }
        return this;
    }
    
    public String save(AssortmentSettings assortmentSettings) {
        if (assortmentSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.AssortmentSettings__mdt.fields.ApplyCalcFullYearQtyP1__c.Name => assortmentSettings.applyCalcFullYearQty_P1,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentProductSelectionRespectBU__c.Name => assortmentSettings.assortmentProductSelectionRespectBU,
                SObjectType.AssortmentSettings__mdt.fields.ASProductSelectionRespectMarket__c.Name => assortmentSettings.assortmentProductSelectionRespectMarket,
                SObjectType.AssortmentSettings__mdt.fields.ASProductSelectionRespectHierarchy__c.Name => assortmentSettings.assortmentProductSelectionRespectHierarchy,
                SObjectType.AssortmentSettings__mdt.fields.KPI__c.Name => assortmentSettings.KPI,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentMatrixNego__c.Name => assortmentSettings.assortmentMatrixNego,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentMatrixTarget__c.Name => assortmentSettings.assortmentMatrixTarget,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentMatrixBudget__c.Name => assortmentSettings.assortmentMatrixBudget,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentProductSelectionGrid__c.Name => assortmentSettings.assortmentProductSelectionGrid,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentProductSelectionUNGrid__c.Name => assortmentSettings.assortmentProductSelectionUNGrid,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentDirectAccessPluginGrid__c.Name => assortmentSettings.assortmentDirectAccessPluginGrid,
                SObjectType.AssortmentSettings__mdt.fields.SalesCannibalizationRates__c.Name => assortmentSettings.salesCannibalizationRates,
                SObjectType.AssortmentSettings__mdt.fields.AvailableImportFields__c.Name => assortmentSettings.availableImportFields,
                SObjectType.AssortmentSettings__mdt.fields.ScopeSettings__c.Name => assortmentSettings.scopeSettings,
                SObjectType.AssortmentSettings__mdt.fields.TMP_TodayDate__c.Name => assortmentSettings.tmpTodayDate,
                SObjectType.AssortmentSettings__mdt.fields.AssortmentSimulatorConfiguration__c.Name => JSON.serialize(assortmentSettings.assortmentSimulatorConfiguration),
                SObjectType.AssortmentSettings__mdt.fields.AssortmentBUConfiguration__c.Name => JSON.serialize(assortmentSettings.assortmentBUConfiguration)
            };
            return saveCustomMetadataSettings(AssortmentSettings__mdt.SObjectType, 'AssortmentSettings', fieldsValueMap);
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
    
    public class SalesCannibalizationRatesWrapper {
        public String typeHR {get; set;}
        public String label {get; set;}
        public String description {get; set;}
        public String api {get; set;}
        public String stdPerc {get; set;}
        public String clientPerc {get; set;}
    }
    
    public class ImportFieldWrapper {
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        public Boolean isAdmin {get; set;}
        public Boolean isUser {get; set;}

        public ImportFieldWrapper(String fieldName, String fieldLabel, Boolean isAdmin, Boolean isUser) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isAdmin = isAdmin;
            this.isUser = isUser;
        }
    }
    
    public class ScopeWrapper {
        public String Name {get;set;}
        public String label {get;set;}
        public Integer level {get;set;}

        public ScopeWrapper() {
            this.Name = '';
            this.label = '';
            this.level = null;
        }
        
        public ScopeWrapper(String Name, String label, Integer level) {
            this.Name = Name;
            this.label = label;
            this.level = level;
        }
    }

    public class AssortmentSimulatorConfigurationWrapper {
        public AssortmentSimulatorRecordTypesWrapper assortmentSimulatorRTs;
        public List<KPIWrapper> kpiFields {get; set;}
        public Boolean displayEvolutionArrows {get; set;}
        public AssortmentSimulatorConfigurationWrapper() {
            this.assortmentSimulatorRTs = new AssortmentSimulatorRecordTypesWrapper();
            this.kpiFields = new List<KPIWrapper>();
            this.displayEvolutionArrows = true;
        }
    }

    public class AssortmentSimulatorRecordTypesWrapper {
        public List<String> previous;
        public List<String> current;
        public List<String> next;
        public AssortmentSimulatorRecordTypesWrapper() {
            this.previous = new List<String>{'Negotiation'};
            this.current = new List<String>{'Target', 'Simulation', 'Negotiation'};
            this.next = new List<String>{'Target', 'Simulation', 'Negotiation'};
        }
    }

    public class KPIWrapper {
        public String backgroundColor {get; set;}
        public String textColor {get; set;}
        public List<String> fields {get; set;}      
    }

    public class AssortmentBUConfigurationWrapper {
        public String assortmentBuLevel {get; set;}
        public Integer periodDays {get; set;}
        public ProductLifeStatusLastCodeConfigurationWrapper LastCodeConfiguration {get; set;}

        public AssortmentBUConfigurationWrapper() {
            this.assortmentBuLevel = 'both';
            this.periodDays = 60;
            this.LastCodeConfiguration = new ProductLifeStatusLastCodeConfigurationWrapper();
        }
    }

    public class ProductLifeStatusLastCodeConfigurationWrapper {
        public String increaseBeforeStart {get; set;}
        public String increaseWithinPeriod {get; set;}
        public String increaseAfterPeriod {get; set;}
        public String decreaseBeforeStart {get; set;}
        public String decreaseWithinPeriod {get; set;}
        public String decreaseAfterPeriod {get; set;}

        public ProductLifeStatusLastCodeConfigurationWrapper() {
            this.increaseBeforeStart = 'A';
            this.increaseWithinPeriod = 'N';
            this.increaseAfterPeriod = 'R';
            this.decreaseBeforeStart = 'D';
            this.decreaseWithinPeriod = 'S';
            this.decreaseAfterPeriod = null;
        }
    }
}