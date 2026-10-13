/**
 * @author ULiT
 * @date 23/08/2024
 * Advanced Settings for Product and PriceList Settings 
 **/
global with sharing class ProductSettings extends SettingsManager implements MethodUtils.MethodChecker {
    public Integer autoNumberLastValue {get; set;}
    public String autoNumberPrefix {get; set;}
    public String higherLevelPackagingRTId {get; set;}
    public Boolean isAutoNumberProductName {get; set;}
    public Boolean isPriceListDataUpdatePGs {get; set;}
    public Integer numberOfUnitCharges {get; set;}
    public String priceListManagerPLDGrid {get; set;}
    public String priceListManagerProductGrid {get; set;}
    public String productManagementProfiles {get; set;}
    public String massProductImportSettings {get; set;}
    public String[] productRecordTypes {get; set;}

    public static final Id productRTId = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
    
    public ProductSettings() {
        this.autoNumberLastValue = 0;
        this.autoNumberPrefix = '';
        this.higherLevelPackagingRTId = '';
        this.isAutoNumberProductName = false;
        this.isPriceListDataUpdatePGs = true;
        this.numberOfUnitCharges = 0;
        this.priceListManagerPLDGrid = 'PriceListManagerGrid';
        this.priceListManagerProductGrid = '';
        this.productManagementProfiles = '';
        this.massProductImportSettings = '';
        this.productRecordTypes = new List<String>{productRTId};
    }
    
    public static ProductSettings loadProductSettings() {
        return (ProductSettings) SettingsManager.loadCustomSettings(ProductSettings__c.SObjectType, 'ProductSettings', ProductSettings.class.getName());
    }
    
    global static String loadProductSettingsSerialized() {
        return JSON.serialize(loadProductSettings());
    }
    
    public Set<String> save(ProductSettings productSettings) {
        try {
            if(productSettings != null) {
                Map<String, Object> fieldsValueMap = new Map<String, Object> {
                    SObjectType.ProductSettings__c.fields.AutoNumberLastValue__c.Name => productSettings.autoNumberLastValue,
                    SObjectType.ProductSettings__c.fields.AutoNumberPrefix__c.Name => productSettings.autoNumberPrefix,
                    SObjectType.ProductSettings__c.fields.HigherLevelPackagingRTId__c.Name => productSettings.higherLevelPackagingRTId,
                    SObjectType.ProductSettings__c.fields.IsAutoNumberProductName__c.Name => productSettings.isAutoNumberProductName,
                    SObjectType.ProductSettings__c.fields.IsPriceListDataUpdatePGs__c.Name => productSettings.isPriceListDataUpdatePGs,
                    SObjectType.ProductSettings__c.fields.NumberOfUnitCharges__c.Name => productSettings.numberOfUnitCharges,
                    SObjectType.ProductSettings__c.fields.PriceListManagerPLDGrid__c.Name => productSettings.priceListManagerPLDGrid,
                    SObjectType.ProductSettings__c.fields.PriceListManagerProductGrid__c.Name => productSettings.priceListManagerProductGrid,
                    SObjectType.ProductSettings__c.fields.ProductManagementProfiles__c.Name => productSettings.productManagementProfiles,
                    SObjectType.ProductSettings__c.fields.MassProductImportSettings__c.Name => productSettings.massProductImportSettings,
                    SObjectType.ProductSettings__c.fields.ProductRecordTypes__c.Name => Json.serialize(productSettings.productRecordTypes)
                };
                return saveCustomSettings(ProductSettings__c.SObjectType, 'ProductSettings', fieldsValueMap);
            }
		} catch (Exception ex) {
			System.debug('++++++++++++++++++++++++++++++');
			System.debug(ex.getMessage() + ' - Line : ' + ex.getLineNumber());
			System.debug(ex.getStackTraceString());
			System.debug(ex.getLineNumber());
			System.debug('++++++++++++++++++++++++++++++');
		}
        return null;
    }
    
    public ProductSettings load(Object customSettingsRecord) {
        try {
            if(customSettingsRecord != null) {
                ProductSettings__c promoSettingsCustomRecord = (ProductSettings__c) customSettingsRecord;
                //SET FIELDS
                this.autoNumberLastValue = promoSettingsCustomRecord.AutoNumberLastValue__c != null ? promoSettingsCustomRecord.AutoNumberLastValue__c.intValue() : 0;
                this.autoNumberPrefix = promoSettingsCustomRecord.AutoNumberPrefix__c != null ? promoSettingsCustomRecord.AutoNumberPrefix__c : '';
                this.higherLevelPackagingRTId = promoSettingsCustomRecord.HigherLevelPackagingRTId__c != null ? promoSettingsCustomRecord.HigherLevelPackagingRTId__c : '';
                this.isAutoNumberProductName = promoSettingsCustomRecord.IsAutoNumberProductName__c != null ? promoSettingsCustomRecord.IsAutoNumberProductName__c : false;
                this.isPriceListDataUpdatePGs = promoSettingsCustomRecord.IsPriceListDataUpdatePGs__c != null ? promoSettingsCustomRecord.IsPriceListDataUpdatePGs__c : true;
                this.numberOfUnitCharges = promoSettingsCustomRecord.NumberOfUnitCharges__c != null ? promoSettingsCustomRecord.NumberOfUnitCharges__c.intValue() : 0;
                this.priceListManagerPLDGrid = promoSettingsCustomRecord.PriceListManagerPLDGrid__c != null ? promoSettingsCustomRecord.PriceListManagerPLDGrid__c : '';
                this.priceListManagerProductGrid = promoSettingsCustomRecord.PriceListManagerProductGrid__c != null ? promoSettingsCustomRecord.PriceListManagerProductGrid__c : '';
                this.productManagementProfiles = promoSettingsCustomRecord.ProductManagementProfiles__c != null ? promoSettingsCustomRecord.ProductManagementProfiles__c : '';
                this.massProductImportSettings = promoSettingsCustomRecord.MassProductImportSettings__c != null ? promoSettingsCustomRecord.MassProductImportSettings__c : '';
                this.productRecordTypes = promoSettingsCustomRecord.ProductRecordTypes__c != null ? (List<String>) JSON.deserialize(promoSettingsCustomRecord.ProductRecordTypes__c, List<String>.class) : new List<String>{ productRTId };
            }
		} catch (Exception ex) {
			System.debug('++++++++++++++++++++++++++++++');
			System.debug(ex.getMessage() + ' - Line : ' + ex.getLineNumber());
			System.debug(ex.getStackTraceString());
			System.debug(ex.getLineNumber());
			System.debug('++++++++++++++++++++++++++++++');
		}
        return this;
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
}