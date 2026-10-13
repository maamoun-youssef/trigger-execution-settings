/**
 * @author ULiT
 * Trigger ProductDiscountStatement__c
 * */
public class Trg_ProductDiscountStatement_Handler {

    public static void OnBeforeInsert(List<ProductDiscountStatement__c> newPDS) {
        populateFields(newPDS);
    }

    public static void OnBeforeInsertOrUpdate(List<ProductDiscountStatement__c> newPDS, Map<Id, ProductDiscountStatement__c> oldPDSMap) {
        generatePDSName(newPDS, oldPDSMap);
    }

    /**
     * @description populate fields of PDS
     * on Before Insert
	*/
    private static void populateFields(List<ProductDiscountStatement__c> newPDS) {
        Map<Id, String> pdsRTIds = NegoptimHelper.getObjectRecordTypeMapLabels(ProductDiscountStatement__c.SObjectType);
        Set<Id> nsIdSet = new Set<Id>();
        Set<Id> contractIdSet = new Set<Id>();
        Map<String, Contract__c> contractMap = new Map<String, Contract__c>();
        for (ProductDiscountStatement__c item : newPDS) {
            if (item.Contract__c != null) {
                contractIdSet.add(item.Contract__c);
            } else if (item.NegoScope__c != null) {
                nsIdSet.add(item.NegoScope__c);
            }
        }
        List<Contract__c> contractList = [SELECT Id, Supplier_Nego_Scope__c, CurrencyIsoCode
                                          FROM Contract__c
                                          WHERE (Supplier_Nego_Scope__c IN :nsIdSet AND Is_OnTop_Simulation__c = TRUE) OR Id IN :contractIdSet];
        for (Contract__c item : contractList) {
            contractMap.put(item.Supplier_Nego_Scope__c, item);
            contractMap.put(item.Id, item);
        }
        for (ProductDiscountStatement__c item : newPDS) {
            if (item.Contract__c == null && item.NegoScope__c != null && contractMap.containsKey(item.NegoScope__c)) {
                item.Contract__c = contractMap.get(item.NegoScope__c).Id;
                item.CurrencyIsoCode = contractMap.get(item.NegoScope__c).CurrencyIsoCode;
            } else if (item.Contract__c != null && contractMap.containsKey(item.Contract__c)) {
                item.CurrencyIsoCode = contractMap.get(item.Contract__c).CurrencyIsoCode;
            }
        }
    }
    
    public static void generatePDSName(List<ProductDiscountStatement__c> newPDS, Map<Id, ProductDiscountStatement__c> oldPDSMap) {
        Map<Id, String> pdsRTDeveloperName = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(ProductDiscountStatement__c.SObjectType);
        Map<String, NegoSettings.NameConfigurationWrapper> pdsNameConfiguration = NegoSettings.loadNegoSettings()?.productDiscountsConfiguration?.nameConfiguration;
        Map<String, List<String>> pdsNameConfigurationFields = new Map<String, List<String>>();
        String prefix = NegoptimHelper.getPackagePrefix(true);
        if (pdsNameConfiguration != null && !pdsNameConfiguration.isEmpty()) {
            for (String rt : pdsNameConfiguration.keySet()) {
                Pattern pattern = Pattern.compile('\\{!(.*?)\\}');
                Matcher matcher = pattern.matcher(pdsNameConfiguration.get(rt).template);
                // Collect matches using a list comprehension-like approach
                List<String> matches = new List<String>();
                while (matcher.find()) {
                    matches.add(matcher.group(1)); // Add the captured group to the list
                }
                pdsNameConfigurationFields.put(rt, matches);
            }
            if (!pdsNameConfigurationFields.isEmpty()) {
                Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(SObjectType.ProductDiscountStatement__c.Name).getDescribe().fields.getMap();
                for (ProductDiscountStatement__c item : newPDS) {
                    Boolean isConcatenateNameUpdated = false;
                    String recordTypeDeveloperName = pdsRTDeveloperName.get(item.RecordTypeId);
                    String template = pdsNameConfiguration.get(recordTypeDeveloperName)?.template ?? pdsNameConfiguration.get('DEFAULT')?.template;
                    List<String> fields = pdsNameConfigurationFields.get(recordTypeDeveloperName) ?? pdsNameConfigurationFields.get('DEFAULT');
                    for (String field : fields) {
                        if (!fieldsMap.containsKey(field) && !fieldsMap.containsKey(prefix + field)) {
                            continue;
                        }
                        if (oldPDSMap == null || (oldPDSMap != null && item.get(field) != oldPDSMap.get(item.Id).get(field))) {
                            isConcatenateNameUpdated = true;
                        }
                        String value = String.valueOf(item.get(field));
                        template = template.replace('{!' + field + '}', value != null ? value : '');
                    }
                    Boolean allowUpdate = pdsNameConfiguration.containsKey(recordTypeDeveloperName) && pdsNameConfiguration.get(recordTypeDeveloperName)?.allowUpdate;
                    if (oldPDSMap == null || (oldPDSMap != null
                                                 && !allowUpdate
                                                 && (item.Name != oldPDSMap.get(item.Id).Name
                                                     || isConcatenateNameUpdated)))
                    {
                        item.Name = template;
                    }
                }
            }
        }
    }
}