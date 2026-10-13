/**
 * @author ULiT
 * @date 09/05/2025
 * Class to handle the picklist value translations
 **/
global with sharing class PicklistTranslationInvocable {
    @AuraEnabled global String value;
    @AuraEnabled global String label;
    global PicklistTranslationInvocable(String value, String label) {
        this.value = value;
        this.label = label;
    }
    @InvocableMethod(label='Get Picklist Translations')
    global static PicklistTranslationWrapper[] getPicklistTranslations(List<PicklistFieldInfoWrapper> pickListInfos) {
        PicklistTranslationWrapper result = new PicklistTranslationWrapper();
        if (pickListInfos != null && !pickListInfos.isEmpty()) {
            for (PicklistFieldInfoWrapper item : pickListInfos) {
                if(String.isNotBlank(item.objectApiName)) {
                    String objectName = NegoptimHelper.normalizeAPIName(item.objectApiName);
                    SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
                    Map<String, String> pickListTranslationMap = PicklistHelper.getPicklistTranslationMap(sObjectType.getDescribe().fields.getMap().get(NegoptimHelper.normalizeAPIName(item.fieldApiName)), true);
                    List<PicklistTranslationInvocable> picklistTranslations = new List<PicklistTranslationInvocable>();
                    if(!pickListTranslationMap.isEmpty()) {
                        for(String picklistValue : pickListTranslationMap.keySet()) {
                            PicklistTranslationInvocable picklistWrapper = new PicklistTranslationInvocable(picklistValue, pickListTranslationMap.get(picklistValue));
                            picklistTranslations.add(picklistWrapper);
                        }
                    }
                    result.picklistTranslations.addAll(picklistTranslations);
                }
            }
        }
        return new PicklistTranslationWrapper[] {result};
    }
    
    global class PicklistFieldInfoWrapper {
        @InvocableVariable(required=true) global String objectApiName;
        @InvocableVariable(required=true) global String fieldApiName;
    }
    
    global class PicklistTranslationWrapper {
        @InvocableVariable global PicklistTranslationInvocable[] picklistTranslations;
        global PicklistTranslationWrapper() {
            this.picklistTranslations = new List<PicklistTranslationInvocable>();
        }
    }
}