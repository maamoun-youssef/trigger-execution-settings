/**
 * @author ULiT
 * @date 09/05/2025
 * Class to handle the picklist value translations
 **/
global with sharing class NegoptimLabelsInvocable {
    
    @InvocableMethod(label='Get Label Translations')
    global static List<LabelWrapper> getLabelTranslations(List<LabelWrapper> labelInfos) {
        LabelWrapper labelInfo = labelInfos[0];
        String language = UserInfo.getLanguage();
        Schema.DescribeFieldResult dr = User.LanguageLocaleKey.getDescribe();
        List<Schema.PicklistEntry> allLocales = dr.getPicklistValues();
        List<String> displayedLocaleKeys = new List<String>();
        for (Schema.PicklistEntry lang : allLocales) {
            if (lang.isActive() && labelInfo.language == lang.getValue()) {
                language = lang.getValue();
            }
        }
        try {
            labelInfo.value = System.Label.get('Negoptim', labelInfo.label, language);
        } catch (InvalidParameterValueException e1) {
            try {
                labelInfo.value = System.Label.get('', labelInfo.label, language);
            } catch (InvalidParameterValueException e2) {
                labelInfo.value = labelInfo.label; // Fallback to label key
            }
        }
        return new List<LabelWrapper> {labelInfo};
    }
    
    global class LabelWrapper {
        @InvocableVariable(required=true) global String label;
        @InvocableVariable global String language;
        @InvocableVariable global String value;
    }
    
}