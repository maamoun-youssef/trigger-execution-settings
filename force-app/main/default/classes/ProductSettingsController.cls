/**
 * @author ULiT
 * @date 22/08/2024
 * @group Negoptim Support
 * @description load and save ProductSettings__c
 ********************************************************************************************************************************************* */
public with sharing class ProductSettingsController extends SettingsManager {
    /**
	 * @description load NegoScope Settings
	 ********************************************************************** */
    @AuraEnabled
    public static string loadProductSettings() {
        // Wrapper to store the result
        ResultWrapper wrapper = new ResultWrapper();
        //GET GRID SETTINGS OPTIONS
        Map<String, List<SelectOption>> productSettingsLayoutsMap = new Map<String, List<SelectOption>>();
        List<String> objectsList = new List<String> {
            SObjectType.PriceList__c.Name,
            SObjectType.PriceListDetail__c.Name,
            SObjectType.Product2.Name
        };
        String[] gridSettingsFields = new String[] {
            SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Name,
            SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
            SObjectType.Grid_Settings__mdt.fields.Label.Name
        };
        if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
            for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c
                                            FROM Grid_Settings__mdt
                                            WHERE Object_Name__c IN :objectsList
                                            ORDER BY DeveloperName])
            {
                if (!productSettingsLayoutsMap.containsKey(item.Object_Name__c)) {
                    productSettingsLayoutsMap.put(item.Object_Name__c, new List<SelectOption>{new SelectOption('', Label.LBL_None_Picklist_Value)});
                }
                productSettingsLayoutsMap.get(item.Object_Name__c).add(new SelectOption(item.DeveloperName, item.Label));
            }
        }
        ProductSettings productSettings = ProductSettings.loadProductSettings();
        String productObjectName = Product2.getSObjectType().getDescribe().getName();
        List<RecordType> productRecordTypes = [SELECT Id, toLabel(Name), DeveloperName, toLabel(Description)
                                               FROM RecordType
                                               WHERE SobjectType = :productObjectName AND DeveloperName <> 'Secondary'];

        //GET Import SETTINGS OPTIONS
        List<SelectOption> importSettingsList = new List<SelectOption>();
        String[] importSettingsFields = new String[] {
            SObjectType.ImportSettings__mdt.fields.ObjectName__c.Name,
            SObjectType.ImportSettings__mdt.fields.Name__c.Name,
            SObjectType.ImportSettings__mdt.fields.DeveloperName.Name,
            SObjectType.ImportSettings__mdt.fields.Label.Name
        };
        if (NegoptimHelper.checkAccessibility(ImportSettings__mdt.SObjectType, importSettingsFields)) {
            for (ImportSettings__mdt item : [SELECT DeveloperName, Name__c, Label, ObjectName__c
                                             FROM ImportSettings__mdt
                                             WHERE ObjectName__c = 'Product2'
                                             ORDER BY DeveloperName])
            {
                 importSettingsList.add(new SelectOption(item.DeveloperName, item.Label));
            }
        }                                       
        wrapper.productSettings = productSettings;
        wrapper.productSettingsLayoutsMap = productSettingsLayoutsMap;
        wrapper.productRecordTypes = productRecordTypes;
        wrapper.importSettingsList = importSettingsList;
        return JSON.serialize(wrapper);
    }
    
    /**
	 * @description Save NegoScope Settings in the cache and custom settings
	 ***************************************************************************************************************************************** */
    @AuraEnabled
	public static String save(String productSettingsJson) {
        try {
            String result = 'SUCCESS';
            ProductSettings productSettings = (ProductSettings) JSON.deserialize(productSettingsJson, ProductSettings.class);
            Set<String> errors = ProductSettings.save(productSettings);
            if(!errors.isEmpty()) {
                result = String.join(new List<String>(errors), ', ');
            }
            return result;
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public class ResultWrapper {
        public ProductSettings productSettings { get; set; }
        public Map<String, List<SelectOption>> productSettingsLayoutsMap { get; set; }
        public Map<String,  Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        String productSettingsLabel {get; set;}
        public String prefix {get; set;}
        List<RecordType> productRecordTypes {get; set;}
        public List<SelectOption> importSettingsList { get; set; }
        
        public ResultWrapper() {
            this.fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.ProductSettings__c.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.productSettingsLabel = Schema.getGlobalDescribe().get(SObjectType.ProductSettings__c.getName()).getDescribe().getLabel();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.productRecordTypes = new List<RecordType>();
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}