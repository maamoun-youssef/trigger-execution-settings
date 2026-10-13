/**
 * @author ULiT
 * @date 23-12-2025
 * @description: Controller class to the LWC ProductMassImport
 * */
public with sharing class ProductMassImportController {

    @AuraEnabled(cacheable=true)
    public static String init() {
        ProductSettings productSettings = ProductSettings.loadProductSettings();
        return productSettings != null ? productSettings.massProductImportSettings : null;
    }

    @AuraEnabled(cacheable=false)
    public static Id importProduct(Id recordId, String recordsToUpsert, String fileName, String base64Data, String fileType, Id fileDirectoryId) {
        try {
            List<SObject> upsertedRecords = (List<SObject>) JSON.deserialize(recordsToUpsert, List<SObject>.class);
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => ProductMassImportController.class.getName(),
                'records' => upsertedRecords,
                'externalIDField' => Product2.Ext_id__c,
                'fileName' => fileName,
                'recordId' => recordId,
                'fileDirectoryId' => fileDirectoryId
            };
            return NegoptimBatch.executeBatch('ImportSettingsBatch', paramsMap, 200);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + '-' + ex.getLineNumber());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getImportOutcome(Id jobId) {
       return NegoptimHelper.getImportOutcome(jobId);
    }
}