/**
 * @author ULiT
 * @date 05/11/2024
 * Advanced Settings class for myNego App
 **/
global with sharing class NegoSettings extends SettingsManager implements MethodUtils.MethodChecker {
    public List<ContractDuplicationWrapper> contractDuplicationConfiguration {get; set;}
    public Map<String, NameConfigurationWrapper> contractNameConfiguration {get; set;}
    public ConditionManagerPageConfigurationWrapper conditionManagerPageConfiguration {get; set;}
    public ProductDiscountConfigurationWrapper productDiscountsConfiguration {get; set;}
    public PriceListStatementsConfigurationWrapper priceListStatementsConfiguration {get; set;}
    public String priceWaterfallMatrixGrid {get; set;}
    public NegotiatePageConfigurationWrapper negotiatePageConfiguration {get; set;}
    public List<SellInConfigurationWrapper> sellInConfiguration {get; set;}
    public Map<String, ContractConsolidationConfigurationWrapper> contractConsolidationConfiguration {get; set;}
    
    public NegoSettings() {
        // Define Default Duplicate Contract Settings
        ContractDuplicationWrapper defaultContractDuplicationWrapper = new ContractDuplicationWrapper('Signed', '');
        defaultContractDuplicationWrapper.targetContracts.add(new ContractDuplicationWrapper('Period_Extension', 'In Preparation'));
        this.contractDuplicationConfiguration = new List<ContractDuplicationWrapper>{defaultContractDuplicationWrapper};
        this.contractNameConfiguration = new Map<String, NameConfigurationWrapper>();
        this.conditionManagerPageConfiguration = new ConditionManagerPageConfigurationWrapper();
        this.productDiscountsConfiguration = new ProductDiscountConfigurationWrapper();
        this.priceListStatementsConfiguration = new PriceListStatementsConfigurationWrapper();
        this.priceWaterfallMatrixGrid = 'PriceWaterfallGrid';
        this.negotiatePageConfiguration = new NegotiatePageConfigurationWrapper();
        this.sellInConfiguration = new List<SellInConfigurationWrapper>();
        Map<String, String> sellInNamesMap = new Map<String, String> {
            'SummaryNego' => Label.LBL_SummaryNego,
            'SummaryExitNego' => Label.LBL_SummaryExitNego,
            'SummaryProvision' => Label.LBL_SummaryProvision,
            'SummarySupplier' => Label.LBL_SummarySupplier,
            'SummaryInvoicing' => Label.LBL_SummaryInvoicing,
            'SummaryBalanced' => Label.LBL_SummaryBalanced
        };
        Integer colNumber = 1;
        for(String sellInKey : sellInNamesMap.keySet()) {
            this.sellInConfiguration.add(new SellInConfigurationWrapper(colNumber, sellInKey, sellInNamesMap.get(sellInKey), true, true));
            colNumber++;
        }
        this.contractConsolidationConfiguration = new Map<String, ContractConsolidationConfigurationWrapper> {
            'Nego_Base_Init' => new ContractConsolidationConfigurationWrapper(true, Date.newInstance(Date.today().year(), 01, 01))
        };
    }
    
    public static NegoSettings loadNegoSettings() {
        return (NegoSettings) SettingsManager.loadCustomMetadataSettings(NegoSettings__mdt.SObjectType, 'NegoSettings', NegoSettings.class.getName(), null);
    }
    
    global static String loadNegoSettingsSerialized() {
        return JSON.serialize(loadNegoSettings());
    }
    
    public NegoSettings load(Object metadataRecord) {
        if(metadataRecord != null) {
            NegoSettings__mdt negoSettingsRecord = (NegoSettings__mdt) metadataRecord;
            this.contractDuplicationConfiguration = String.isNotBlank(negoSettingsRecord.ContractDuplicationConfiguration__c) ? (List<ContractDuplicationWrapper>) JSON.deserialize(negoSettingsRecord.ContractDuplicationConfiguration__c, List<ContractDuplicationWrapper>.class) : new List<ContractDuplicationWrapper>();
            this.contractNameConfiguration = String.isNotBlank(negoSettingsRecord.ContractNameConfiguration__c) ? (Map<String, NameConfigurationWrapper>) JSON.deserialize(negoSettingsRecord.ContractNameConfiguration__c, Map<String, NameConfigurationWrapper>.class) : new Map<String, NameConfigurationWrapper>();
            this.conditionManagerPageConfiguration = String.isNotBlank(negoSettingsRecord.ConditionManagerPageConfiguration__c) ? (ConditionManagerPageConfigurationWrapper) JSON.deserialize(negoSettingsRecord.ConditionManagerPageConfiguration__c, ConditionManagerPageConfigurationWrapper.class) : new ConditionManagerPageConfigurationWrapper();
            this.productDiscountsConfiguration = String.isNotBlank(negoSettingsRecord.ProductDiscountsConfiguration__c) ? (ProductDiscountConfigurationWrapper) JSON.deserialize(negoSettingsRecord.ProductDiscountsConfiguration__c, ProductDiscountConfigurationWrapper.class) : new ProductDiscountConfigurationWrapper();
            this.priceListStatementsConfiguration = String.isNotBlank(negoSettingsRecord.PriceListStatementsConfiguration__c) ? (PriceListStatementsConfigurationWrapper) JSON.deserialize(negoSettingsRecord.PriceListStatementsConfiguration__c, PriceListStatementsConfigurationWrapper.class) : new PriceListStatementsConfigurationWrapper();
            if (this.priceListStatementsConfiguration.nameConfiguration == null) {
                this.priceListStatementsConfiguration.nameConfiguration = new Map<String, NameConfigurationWrapper>();
            }
            if (!this.priceListStatementsConfiguration.nameConfiguration.containsKey('DEFAULT')) {
                this.priceListStatementsConfiguration.nameConfiguration.put('DEFAULT', new NameConfigurationWrapper());
            }
            this.priceWaterfallMatrixGrid = negoSettingsRecord.PriceWaterfallMatrixGrid__c != null ? negoSettingsRecord.PriceWaterfallMatrixGrid__c : 'PriceWaterfallGrid';
            this.negotiatePageConfiguration = String.isNotBlank(negoSettingsRecord.NegotiatePageConfiguration__c) ? (NegotiatePageConfigurationWrapper) JSON.deserialize(negoSettingsRecord.NegotiatePageConfiguration__c, NegotiatePageConfigurationWrapper.class) : new NegotiatePageConfigurationWrapper();
            this.sellInConfiguration = String.isNotBlank(negoSettingsRecord.SellInConfiguration__c) ? (List<SellInConfigurationWrapper>) JSON.deserialize(negoSettingsRecord.SellInConfiguration__c, List<SellInConfigurationWrapper>.class) : new List<SellInConfigurationWrapper>();
            if(String.isNotBlank(negoSettingsRecord.ContractConsolidationConfiguration__c)) {
                this.contractConsolidationConfiguration = (Map<String, ContractConsolidationConfigurationWrapper>) JSON.deserialize(negoSettingsRecord.ContractConsolidationConfiguration__c, Map<String, ContractConsolidationConfigurationWrapper>.class);
            } else {
                this.contractConsolidationConfiguration = new Map<String, ContractConsolidationConfigurationWrapper> {
                    'Nego_Base_Init' => new ContractConsolidationConfigurationWrapper(true, Date.newInstance(Date.today().year(), 01, 01))
                };
            }
        }
        return this;
    }
    
    public static String save(NegoSettings negoSettings) {
        if (negoSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.NegoSettings__mdt.fields.ContractDuplicationConfiguration__c.Name => JSON.serialize(negoSettings.contractDuplicationConfiguration),
                SObjectType.NegoSettings__mdt.fields.ContractNameConfiguration__c.Name => JSON.serialize(negoSettings.contractNameConfiguration),
                SObjectType.NegoSettings__mdt.fields.ConditionManagerPageConfiguration__c.Name => JSON.serialize(negoSettings.conditionManagerPageConfiguration),
                SObjectType.NegoSettings__mdt.fields.ProductDiscountsConfiguration__c.Name => JSON.serialize(negoSettings.productDiscountsConfiguration),
                SObjectType.NegoSettings__mdt.fields.PriceListStatementsConfiguration__c.Name => JSON.serialize(negoSettings.priceListStatementsConfiguration),
                SObjectType.NegoSettings__mdt.fields.SellInConfiguration__c.Name => JSON.serialize(negoSettings.sellInConfiguration),
                SObjectType.NegoSettings__mdt.fields.ContractConsolidationConfiguration__c.Name => JSON.serialize(negoSettings.contractConsolidationConfiguration),
                SObjectType.NegoSettings__mdt.fields.NegotiatePageConfiguration__c.Name => JSON.serialize(negoSettings.negotiatePageConfiguration)
            };
            return saveCustomMetadataSettings(NegoSettings__mdt.SObjectType, 'NegoSettings', fieldsValueMap);
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
    
    public class ContractDuplicationWrapper {
        public String recordType {get; set;}
        public String status {get; set;}
        public List<ContractDuplicationWrapper> targetContracts {get; set;}
        public ContractDuplicationWrapper(String recordType, String status) {
            this.recordType = recordType;
            this.status = status;
            this.targetContracts = new List<ContractDuplicationWrapper>();
        }
    }
    
    public class NameConfigurationWrapper {
        public String template {get; set;}
        public Boolean allowUpdate {get; set;}
        public NameConfigurationWrapper() {
            this.allowUpdate = false;
        }
    }
    
    public class RecordTypeGridConfiguration {
        public String recordType {get; set;}
        public String promoStatementType {get; set;}
        public String promoAgreementType {get; set;}
        public String gridSettings {get; set;}
        public String communityGridSettings {get; set;}
        public String importSettings {get; set;}
        public String communityImportSettings {get; set;}
    }
    
    public class ProductDiscountConfigurationWrapper {
        public Map<String, NameConfigurationWrapper> nameConfiguration { get; set; }
        public String loadPreferencePromoStatement;
        public String communityPDSMatrixURL;
        public Boolean showScanButton;
        public Boolean showSynchroButton;
        // toggles for CommercialPlanServices
        public Boolean enableContractReferenceUpdate;
        public Boolean enableNegoScopeReferenceUpdate;

        public Map<String, RecordTypeGridConfiguration> productDiscountsConfigurationMap;
        public ProductDiscountConfigurationWrapper() {
            this.nameConfiguration = new Map<String, NameConfigurationWrapper>();
            this.productDiscountsConfigurationMap = new Map<String, RecordTypeGridConfiguration>();
            // default values: false
            this.enableContractReferenceUpdate = false;
            this.enableNegoScopeReferenceUpdate = false;
        }
    }

    public class PriceListStatementsConfigurationWrapper {
        public Map<String, RecordTypeGridConfiguration> priceListStatementsConfigurationMap;
        public Map<String, NameConfigurationWrapper> nameConfiguration { get; set; }
        public PriceListStatementsConfigurationWrapper() {
            this.priceListStatementsConfigurationMap = new Map<String, RecordTypeGridConfiguration>();
            this.nameConfiguration = new Map<String, NameConfigurationWrapper>();
        }
    }
    
    public class SellInConfigurationWrapper {
        public Integer colNumber;
        public String sellInKey;
        public String sellInName;
        public Boolean isActive;
        public Boolean isEdit;
        public SellInConfigurationWrapper(Integer colNumber, String sellInKey, String sellInName, Boolean isActive, Boolean isEdit) {
            this.colNumber = colNumber;
            this.sellInKey = sellInKey;
            this.sellInName = sellInName;
            this.isActive = isActive;
            this.isEdit = isEdit;
        }
    }
    
    public class ContractConsolidationConfigurationWrapper {
        public Boolean isActive;
        public Date executionDate;
        public ContractConsolidationConfigurationWrapper(Boolean isActive, Date executionDate) {
            this.isActive = isActive;
            this.executionDate = executionDate;
        }
        public ContractConsolidationConfigurationWrapper() {
            this.isActive = false;
            this.executionDate = null;
        }
    }

    public class NegotiatePageConfigurationWrapper {
        public NegotiationRecordTypesWrapper annualNegotiationRTs;
        public NegotiationRecordTypesWrapper addendumNegotiationRTs;
        public NegotiatePageConfigurationWrapper() {
            this.annualNegotiationRTs = new NegotiationRecordTypesWrapper();
            this.addendumNegotiationRTs = new NegotiationRecordTypesWrapper();
        }
    }

    public class NegotiationRecordTypesWrapper {
        public List<String> current;
        public List<String> next;
        public NegotiationRecordTypesWrapper() {
            this.current = new List<String>{'Nego_Base', 'Nego_Base_Init', 'Nego_Base_Exit'};
            this.next = new List<String>{'Nego_Base', 'Nego_Base_Init', 'Nego_Base_Exit', 'Simulation', 'Period_Extension', 'To_Be_Signed'};
        }
    }

    public class ConditionManagerPageConfigurationWrapper {
        public Map<String, ConditionManagerGridWrapper> gridsConfiguration;
        
        public ConditionManagerPageConfigurationWrapper() {
            this.gridsConfiguration = new Map<String, ConditionManagerGridWrapper> {
                'DEFAULT' => new ConditionManagerGridWrapper()
            };
        }
    }

    public class ConditionManagerGridWrapper {
        public String mainGridSettings;
        public String subDiscountGridSettings;
        public Boolean showSubDiscountColumn;
        public ConditionManagerGridWrapper() {
            this.mainGridSettings = 'Condition_Grid';
            this.subDiscountGridSettings = '';
            this.showSubDiscountColumn = false;
        }
    }
}