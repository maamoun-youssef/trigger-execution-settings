/**
 * @author ULiT
 * @date 4/3/2020
 * @description This class is used to call custom labels used as "String" in the code
 * because it not being automatically included in the package.
 * */
public with sharing class NegoptimLabels {
    
    public static final String LBL_Available_Templates = System.Label.Available_Templates;
    public static final String LBL_MassPrint_PageTemplateGridTitle = System.Label.Available_Templates;
    public static final String LBL_Cancel = System.Label.Cancel;
    public static final String LBL_Clear_Selected = System.Label.Clear_Selected;
    public static final String LBL_First = System.Label.LBL_First;
    public static final String LBL_Last = System.Label.LBL_Last;
    public static final String LBL_Loading = System.Label.Loading;
    public static final String LBL_Next = System.Label.LBL_Next;
    public static final String LBL_Previous = System.Label.LBL_Previous;
    public static final String LBL_Version = System.Label.Version; // Used in AssortmentBUMatrixController

    @AuraEnabled(cacheable = true)
    public static String getCustomLabel(String labelName, String hardcodedLabel) {
        try {
            return System.Label.get('Negoptim', labelName, UserInfo.getLanguage());
        } catch (InvalidParameterValueException e1) {
            try {
                return System.Label.get('nGrid', labelName, UserInfo.getLanguage());
            } catch (InvalidParameterValueException e2) {
				try {
                    String label = System.Label.get('', labelName, UserInfo.getLanguage());
					return System.Label.get('', labelName, UserInfo.getLanguage());
				} catch (InvalidParameterValueException e3) {
					return hardcodedLabel;
				}
            }
        }
    }
    

    @AuraEnabled(cacheable = true)
    public static String getCustomLabel(String labelName, String hardcodedLabel, String language) {
        String lang = UserInfo.getLanguage();
        if (String.isNotBlank(language) && NegoptimHelper.checkLanguageValidity(language)) {
            lang = language;
        }
        try {
            return System.Label.get('Negoptim', labelName, lang);
        } catch (InvalidParameterValueException e1) {
            try {
                return System.Label.get('', labelName, lang);
            } catch (InvalidParameterValueException e2) {
                return hardcodedLabel;
            }
        }
    }

    @AuraEnabled(cacheable = true)
    public static String getCustomLabels(String labelsTranslationMapJSON, String language) {
       
        Map<String, String> customLabelTranslationMap = new Map<String, String>();
        customLabelTranslationMap.putAll((Map<String, String>)JSON.deserialize(labelsTranslationMapJSON, Map<String, String>.class));
        String lang = UserInfo.getLanguage();
        if (String.isNotBlank(language) && NegoptimHelper.checkLanguageValidity(language)) {
            lang = language;
        }
        for (String labelName : customLabelTranslationMap.keySet()) {
            try {
                customLabelTranslationMap.put(labelName, System.Label.get('Negoptim', labelName, lang));
            } catch (InvalidParameterValueException e1) {
                try {
                    customLabelTranslationMap.put(labelName, System.Label.get('', labelName, lang));
                } catch (InvalidParameterValueException e2) { }
            }
        }
        return JSON.serialize(customLabelTranslationMap);
    }

}