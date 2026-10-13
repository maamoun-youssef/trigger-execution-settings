/**
 * @author ULiT
 * @date 26/11/2024
 * @description Controller class to manage documentsCenter LWC
 * */
public with sharing class DocumentsCenterController {
    
    @AuraEnabled(cacheable = true)
    public static String loadData(String recordId,String language) {
        try {
            if (String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }
            List<FileDirectorySettings> fileDirectorySettings = FileDirectorySettings.loadAllFileDirectorySettings();
            for (FileDirectorySettings settings: fileDirectorySettings) {
                String sectionTitle = settings.sectionTitle;
                String sectionSubTitle = settings.sectionSubTitle;
                settings.sectionLabel = NegoptimLabels.getCustomLabel(extractLabel(sectionTitle), sectionTitle, language);
                settings.sectionSubTitle = NegoptimLabels.getCustomLabel(extractLabel(sectionSubTitle), sectionSubTitle, language);
                for (FileDirectorySettings.ThemeWrapper themeWrapper: settings.themesSettings) {
                    String theme= themeWrapper.theme;
                    themeWrapper.themeLabel = NegoptimLabels.getCustomLabel(extractLabel(theme), theme, language);
                }
            }
            User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
            String objectApiName = '';
            if (!String.isBlank(recordId)) {
                objectApiName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            }
            ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
            string flowApiName = user.ContactId != null ? connectSettings.connectUploadFileFlow : connectSettings.uploadFileFlow;

            List<FlowDefinitionView> flows = new List<FlowDefinitionView>();
            if (!String.isBlank(flowApiName)) {
                flows = [SELECT IsActive
                         FROM FlowDefinitionView
                         WHERE ProcessType = 'Flow' 
                         AND ApiName = :flowApiName];
            }
            ResultWrapper resultWrapper = new ResultWrapper(fileDirectorySettings,
                                                            user.ContactId != null,
                                                            flows.size() > 0 && flows[0].IsActive,
                                                            objectApiName,
                                                            flowApiName, 
                                                            language);
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }


    public static String extractLabel(String data) {
            // Validate the input
            if (String.isBlank(data)) {
                return '';
            }
            // Define the regular expression pattern
            Pattern regex = Pattern.compile('\\{\\!\\$Label\\.(.*?)\\}');
            Matcher matcher = regex.matcher(data);
            // Check if the pattern matches and return the captured group
            // Return null if no match is found
            return matcher.find() ? matcher.group(1) : '';
    }

    public class ResultWrapper {
        public List<FileDirectorySettings> fileDirectorySettings {get; set;}
        public Boolean isPortal {get; set;}
        public Boolean isFlowActive {get; set;}
        public String objectApiName {get; set;}
        Map<String, String> fieldsLabel {get; set;}
        String flowApiName {get; set;}
    
        private List<String> defaultLabels() {
            return new List<String> {
                'LBL_Connect_DocumentsCenter_Menu',
                'LBL_DocumentsCenter_AttachFile',
                'LBL_DocumentsCenter_UploadFiles',
                'LBL_DocumentsCenter_OrDropFiles',
                'LBL_Success',
                'LBL_Error',
                'LBL_Connect_Cancel',
                'LBL_Yes',
                'MSG_DocumentsCenter_FileUploadSuccess',
                'MSG_DocumentsCenter_FileUploadError'
            };
        }

        // Parameterized constructor
        public ResultWrapper(List<FileDirectorySettings> fileDirectorySettings, Boolean isPortal, Boolean isFlowActive, String objectApiName, String flowApiName, String language) {
            this.fileDirectorySettings = fileDirectorySettings;
            this.isPortal = isPortal;
            this.isFlowActive = isFlowActive;
            this.objectApiName = objectApiName;
            Map<String, String> tempFieldsLabel = new Map<String, String>();
            for (String label : defaultLabels()) {
                String value = NegoptimLabels.getCustomLabel(label, '', language);
                tempFieldsLabel.put(label, value);
            }
            this.fieldsLabel = tempFieldsLabel;
            this.flowApiName = flowApiName;
        }
    }

}