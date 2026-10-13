/**
 * @author ULIT
 * @date 12/12/2020
 * @description apex controller related to negOptim toggle widget LWC
 * */
public with sharing class ToggleWidgetCmpController {

    /**
     * @description method to get values and labels of the fields of current record, has aura enabled
     * @param Id recordId, String objectApiName, String[] fields to retrieve
     * @return string JSON serialized from results map: Map<String, FieldWrapper>
     * */
    @AuraEnabled
    public static string getRecordData(Id recordId, String[] fields) {
      String objectApiName = recordId.getSObjectType().getDescribe().getName();
      String columns = String.escapeSingleQuotes(string.join(fields, ','));
      Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
      //if (NegoptimHelper.checkAccessibility(Schema.getGlobalDescribe().get(objectApiName), fields)) {
        SObject item = Database.query('SELECT ' + columns + ' FROM ' + objectApiName + ' WHERE Id=\''+ recordId+ '\' LIMIT 1');
        Map<String, FieldWrapper> results = new Map<String,FieldWrapper>();
        for (String fieldName : fields) {
          DescribeFieldResult dfr = objectFieldsMap.get(fieldName).getDescribe();
          Boolean value = Boolean.valueOf(item.get(fieldName));
          String label = dfr.getLabel();
          String inlineHelpText = dfr.getInlineHelpText();
          FieldWrapper fieldWrapper = new FieldWrapper(fieldName, label, value, inlineHelpText);
          fieldWrapper.isReadable = dfr.isAccessible();
          fieldWrapper.isEditable = dfr.isUpdateable();
          results.put(fieldName, fieldWrapper);
        }
        return JSON.serialize(results);
      //}
      //return null;
    }

    /**
     * @description method to update the value of a field of current record, has aura enabled
     * @param Id recordId, String objectApiName, String fieldName and Boolean value of the field to update
     * @return void
     * */
    @AuraEnabled
    public static void saveRecord(Id recordId, String fieldName, Boolean value) {
      String objectApiName = recordId.getSObjectType().getDescribe().getName();
      fieldName = String.escapeSingleQuotes(fieldName);
      String[] fields = new String[] { fieldName };
      //if (NegoptimHelper.checkAccessibility(Schema.getGlobalDescribe().get(objectApiName), fields)
      //    && NegoptimHelper.checkUpdatibility(Schema.getGlobalDescribe().get(objectApiName), fields)) {
        SObject item = Database.query('SELECT Id FROM ' + objectApiName + ' WHERE Id=\'' + recordId + '\' LIMIT 1');
        item.put(fieldName, value);
        Database.SaveResult result = Database.update(item, false);
        String errorMessage = '';
        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                errorMessage += System.Label.MSG_Error_Occurred + ' \n' + err.getStatusCode() + ': ' + err.getMessage() + '.\n' + (err.getFields().size() > 0 ? System.Label.MSG_Error_Fields + ' '+ err.getFields() + '\n' : '' );
            }
            throw new AuraHandledException(errorMessage);
        }
        //}
    }

    // @description private class to wrap field properties as String apiName, String label and Boolean value
    // todo
    private class FieldWrapper {

      public String apiName;
      public String label;
      public String inlineHelpText;
      public Boolean value;
      public Boolean isReadable;
      public Boolean isEditable;

      public FieldWrapper(String apiName, String label, Boolean value, String inlineHelpText) {
        this.apiName = apiName;
        this.label = label;
        this.value = value;
        this.inlineHelpText = inlineHelpText;
      }

    }

}