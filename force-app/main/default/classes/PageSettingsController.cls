/**
 * @author ULiT
 * @date 28-04-2025
 * @description Controller to handle PageSettings page action for updating PageSettings settings
 *************************************************************************************************************/
public with sharing class PageSettingsController {

    @AuraEnabled
    public static string loadAllData() {
        List<SelectOption> gridSettingsLayouts = new List<SelectOption>();
        List<SelectOption> pages = new List<SelectOption>();
        String[] gridSettingsFields = new String[] {
            SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
            SObjectType.Grid_Settings__mdt.fields.Label.Name
        };
        if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
            for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c FROM Grid_Settings__mdt ORDER BY DeveloperName LIMIT 1000]) {
                gridSettingsLayouts.add(new SelectOption(item.Label, item.DeveloperName));
            }
        }
        List<Object> lightningComponentList = queryToolingAPI();
        List<LWCParamSettings> lwcParamsSettingsList = LWCParamSettings.loadAllLWCParamSettings();
        String activeFlows = JSON.serialize(NegoptimHelper.getActiveScreenFlows());
        return JSON.serialize(new PageSettingsWrapper(PageSettings.loadAllPageSettings(), gridSettingsLayouts, lightningComponentList, lwcParamsSettingsList, activeFlows));
    }

    /**
     * publish uploaded image into "Asset Library" and return url
     * Generates ContentAsset/ContentDocument/ContentVersion
     * @param base64Image The content of file.
     * @param imageName the name of file.
     * @return The URL of asset file.
     */
    @AuraEnabled
    public static String uploadImage(String base64Image, String imageName) {
        try {
            return NegoptimHelper.uploadAssetFileBase64(base64Image, imageName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Generates or updates a ContentDocumentLink to a given Network, ensuring visibility is 'AllUsers'.
     * @param contentDocumentId The ID of the ContentDocument.
     * @param networkId The ID of the Network.
     */
    public static void generateDocumentLink(string contentDocumentId, string networkId){
        List<ContentDocumentLink> existingLinks = [SELECT Id, Visibility
                                                   FROM ContentDocumentLink
                                                   WHERE ContentDocumentId = :contentDocumentId
                                                   AND LinkedEntityId = :networkId
                                                   LIMIT 1];
        if (existingLinks.isEmpty()) {
            // Create a new ContentDocumentLink to share with the Network
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = networkId;
            cdl.ShareType = 'V'; // Viewer
            cdl.Visibility = 'AllUsers'; // Allowed when linking to a Network
            insert cdl;
        } else {
            // Update the existing ContentDocumentLink's visibility if necessary
            ContentDocumentLink cdl = existingLinks[0];
            if (cdl.Visibility != 'AllUsers') {
                cdl.Visibility = 'AllUsers';
                update cdl;
            }
        }
    }

    @AuraEnabled
    public static String save(String pageSettingsListJSON) {
        List<PageSettings> pageSettingsList = String.isNotBlank(pageSettingsListJSON) ? (List<PageSettings>) JSON.deserialize(pageSettingsListJSON, List<PageSettings>.class) : new List<PageSettings>();
        return PageSettings.save(pageSettingsList);
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    // Executes a query against the Salesforce Tooling API and returns the HTTP response.
    public static final String endpoint = '/services/data/v51.0/tooling/query/?q=';
    /**
     * @description method to get the server Url and session Id of local Org
     * @return Authwrapper: that contains the server Url and the session Id
     * */
    public static Authwrapper getAuthLocalOrg() {
        Authwrapper authWrap = new Authwrapper();
        authWrap.SERVER_URL = URL.getOrgDomainUrl().toExternalForm();
        authWrap.SESSION_ID = NegoptimHelper.getSessionId();
        return authWrap;
    }

    public static List<Object> queryToolingAPI() {
        List<Object> recordsOfMetadata = new List<Object>();
        String packagePrefix = NegoptimHelper.getPackagePrefix(false);
        String query = 'SELECT Id, MasterLabel, DeveloperName FROM LightningComponentBundle WHERE (NamespacePrefix = null OR NamespacePrefix = \'Negoptim\')';
        String urlString = endpoint + EncodingUtil.urlEncode(query, 'UTF-8');
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        Authwrapper authwrapper = getAuthLocalOrg();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(baseUrl + urlString);
        request.setMethod('GET');
        if (!Test.isRunningTest() && authwrapper.SESSION_ID != null) {
            request.setHeader('Authorization', 'Bearer ' + authwrapper.SESSION_ID);
            request.setHeader('Sforce-Query-Options', 'batchSize=750');
            request.setHeader('Content-Type', 'application/json');
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                String responseBody = response.getBody();
                if (!String.isEmpty(responseBody)) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    if (responseMap.containsKey('records')) {
                        recordsOfMetadata = (List<Object>) responseMap.get('records');
                    }
                }
            }
        }
        return recordsOfMetadata;
    }

    public class PageSettingsWrapper {
        public String prefix;
        public List<PageSettings> pageSettingsList;
        Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap;
        public List<SelectOption> templates {get; set;}
        public List<Object> pages {get; set;}
        public List<LWCParamSettings> lwcParamsSettingsList {get; set;}
        public String activeFlows {get; set;}

        public PageSettingsWrapper(List<PageSettings> pageSettingsList, List<SelectOption> templates, List<Object> pages, List<LWCParamSettings> lwcParamsSettingsList, String activeFlows) {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.pageSettingsList = pageSettingsList;
            this.templates = templates;
            this.pages = pages;
            this.activeFlows = activeFlows;
            this.lwcParamsSettingsList = lwcParamsSettingsList;
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.PageSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
        }
    }

    public class SelectOption {
        public String label {get; set;}
        public String value {get; set;}

        public SelectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    /**
     * @description wrapper to save the data of connection Org
    * */
    public class Authwrapper {
        public String SERVER_URL {get; set;}
        public String SESSION_ID {get; set;}
    }
}