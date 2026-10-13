/**
 * @author ULiT
 * @date 05/05/2025
 * @description Controller class to manage PageSettingsPlugin LWC
 * */
public with sharing class PageSettingsPluginController {
    
    @AuraEnabled
    public static String initData() {
        try {
            return JSON.serialize(new MainWrapper());
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String getFlowVariables(String flowApiName) {
        return NegoptimHelper.getFlowVariables(flowApiName);
    }
    
    @AuraEnabled
    public static String loadData(String templateName) {
        try {
            PageSettings settings = PageSettings.loadPageSettings(templateName);
            Pattern labelPattern = Pattern.compile('\\{\\!\\$Label\\.(.*?)\\}');
            if (!String.isBlank(settings.description)) {
                Matcher m = labelPattern.matcher(settings.description);
                if (m.find()) {
                    String labelKey = m.group(1);
                    settings.description = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                }
            }
            if (settings.sections != null) {
                for (PageSettings.SectionSettings section : settings.sections) {
                    if (!String.isBlank(section.title)) {
                        Matcher m = labelPattern.matcher(section.title);
                        if (m.find()) {
                            String labelKey = m.group(1);
                            section.title = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                        }
                    }
                    if (!String.isBlank(section.subTitle)) {
                        Matcher m = labelPattern.matcher(section.subTitle);
                        if (m.find()) {
                            String labelKey = m.group(1);
                            section.subTitle = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                        }
                    }
                }
            }
            if (settings.themes != null) {
                for (PageSettings.ThemeSettings theme : settings.themes) {
                    if (!String.isBlank(theme.label)) {
                        Matcher m = labelPattern.matcher(theme.label);
                        if (m.find()) {
                            String labelKey = m.group(1);
                            theme.label = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                        }
                    }
                }
            }
            if (settings.flowSettings != null && String.isNotBlank(settings.flowSettings.name)) {
                if (!String.isBlank(settings.flowSettings.buttonLabel)) {
                    Matcher m = labelPattern.matcher(settings.flowSettings.buttonLabel);
                    if (m.find()) {
                        String labelKey = m.group(1);
                        settings.flowSettings.buttonLabel = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                    }
                }
                if (!String.isBlank(settings.flowSettings.flowLabel)) {
                    Matcher m = labelPattern.matcher(settings.flowSettings.flowLabel);
                    if (m.find()) {
                        String labelKey = m.group(1);
                        settings.flowSettings.flowLabel = NegoptimLabels.getCustomLabel(labelKey, labelKey);
                    }
                }
            }
            return JSON.serialize(settings);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }
    
    public class MainWrapper {
        public String prefix { get; set; }
        public Map<String, String> currentSession { get; set; }
        public MainWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            if (Test.isRunningTest()) {
                this.currentSession = new Map<String, String>();
            } else {
                this.currentSession = Auth.SessionManagement.getCurrentSession();
            }
        }
    }
    
}