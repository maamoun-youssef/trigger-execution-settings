public with sharing class MetadataBridgeCmpController {


    // Contains all the data we need for initialization
    @AuraEnabled
    public static String initData(){
        try {
            MainWrapper wMain = new MainWrapper();
            wMain.displayedObjects = getObjects();
            return JSON.serialize(wMain);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Contains the records and total to use them on initialization
    @AuraEnabled
    public static String loadData(String filters, Integer pageSize, Integer pageNumber){
        try {
            FilterWrapper wFilter = String.isNotBlank(filters) ? (FilterWrapper)JSON.deserialize(filters, FilterWrapper.class) : new FilterWrapper();
            MainWrapper wMain = new MainWrapper();
            ResultWrapper resultWrapper = new ResultWrapper();
            List<String> fields = new List<String>();
            List<String> conditions = new List<String>();
            for (FieldWrapper wField : wMain.wFields) {
                fields.add(wField.fieldName);
            }
            if (!fields.contains('DeveloperName')) {
                fields.add('DeveloperName');
            }
            String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Grid_Settings__mdt';
            if (String.isNotBlank(wFilter.objectName)) {
                conditions.add('Object_Name__c = \'' + String.escapeSingleQuotes(wFilter.objectName) + '\'');
            }
            if (String.isNotBlank(wFilter.searchTerm)) {
                conditions.add('MasterLabel LIKE \'%' + String.escapeSingleQuotes(wFilter.searchTerm) + '%\'');
            }
            if (String.isNotBlank(wFilter.type)) {
                conditions.add('Type__c = \'' + String.escapeSingleQuotes(wFilter.type) + '\'');
            }
            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }
            query += ' ORDER BY Masterlabel ASC ';
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize);
            // setController.setPageNumber(pageNumber != null && pageNumber > 0 ? (pageNumber/pageSize)+1 : 1);
            setController.setPageNumber(pageNumber != null && pageNumber > 0 ? pageNumber : 1);
            resultWrapper.records = setController.getRecords();
            resultWrapper.total = setController.getResultSize();
            return JSON.serialize(resultWrapper);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String getObjects() {
        try {
            Map<String, String> objectLabels = new Map<String, String>();
            for (Grid_Settings__mdt record : [SELECT Object_Name__c FROM Grid_Settings__mdt ORDER BY Object_Name__c]) {
                Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(record.Object_Name__c)?.getDescribe();
                if (objDescribe != null) {
                    objectLabels.put(record.Object_Name__c, objDescribe.getLabel());
                }
            }
            List<SelectOption> displayedObjects = new List<SelectOption>();
            for (String key : objectLabels.keySet()) {
                displayedObjects.add(new SelectOption(objectLabels.get(key), key));
            }
            return JSON.serialize(displayedObjects);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Generate XML File
    @AuraEnabled
    public static List<String> generateXML(List<String> layoutsName, String prefix) {
        try {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(SObjectType.Grid_Settings__mdt.Name).getDescribe().fields.getMap();
            List<String> generatedXML = new List<String>();
            List<String> unwantedFieldsInXml = new List<String>{'Id', 'DeveloperName', 'NamespacePrefix', 'Language', 'Label', 'QualifiedApiName', 'SystemModstamp', 'MasterLabel'};
            String query = 'SELECT ' + String.join(new List<String>(fields.keySet()), ', ') + ' FROM Grid_Settings__mdt WHERE DeveloperName IN (\'' + String.join(layoutsName, '\', \'') + '\')';
            List<Grid_Settings__mdt> xmlSettings = Database.query(query);
            if (xmlSettings == null || xmlSettings.isEmpty()) {
                throw new AuraHandledException('No metadata found for the given object name: ' + layoutsName);
            }
            String targetNs = normalizeTargetPrefix(prefix);
            for (Grid_Settings__mdt metadata : xmlSettings) {
                Dom.Document doc = new Dom.Document();
                Dom.XmlNode root = doc.createRootElement('CustomMetadata', 'http://soap.sforce.com/2006/04/metadata', null);

                root.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
                root.setAttribute('xmlns:xsd', 'http://www.w3.org/2001/XMLSchema');
                // root.addChildElement('label', null, null).addTextNode(xmlSettings[0].MasterLabel);
                root.addChildElement('label', null, null).addTextNode(metadata.MasterLabel);
                root.addChildElement('protected', null, null).addTextNode('false');
                for (String field : fields.keySet()) {
                    String fieldApiName = fields.get(field).getDescribe().getName();
                    if (!unwantedFieldsInXml.contains(fieldApiName)) {
                        String updatedField = processColumns((String) metadata.get(fieldApiName), prefix);
                        String exportFieldApiName = fieldApiName;
                        if (exportFieldApiName.endsWith('__c')) {
                            exportFieldApiName = rewriteCustomFieldNamespaces(exportFieldApiName, targetNs);
                        }
                        addValuesNode(root, exportFieldApiName, updatedField);
                    }
                }
                generatedXML.add(doc.toXmlString());
            }
            return generatedXML;
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    // To add the children elements while generating the Xml file
    private static void addValuesNode(Dom.XmlNode root, String fieldName, Object value) {
        if (value != null) {
            Dom.XmlNode valuesNode = root.addChildElement('values', null, null);

            Dom.XmlNode fieldNode = valuesNode.addChildElement('field', null, null);
            fieldNode.addTextNode(fieldName);

            Dom.XmlNode valueNode = valuesNode.addChildElement('value', null, null);
            valueNode.setAttribute('xsi:type', 'xsd:string');
            valueNode.addTextNode(String.valueOf(value));
        }
    }

    // // Adjusts field names in the JSON data by processing and updating prefixes accordingly.
    // private static String processColumns(String columnsJson, String prefix) {
    //     try {
    //         if (String.isEmpty(columnsJson)) {
    //             return columnsJson;
    //         }

    //         String regex = '(?<!' + prefix + ')[a-zA-Z][a-zA-Z0-9_]{0,36}__[cr]';

    //         Pattern pattern = Pattern.compile(regex);
    //         Matcher matcher = pattern.matcher(columnsJson);
    //         String result = '';
    //         Integer lastEnd = 0;

    //         while (matcher.find()) {
    //             result += columnsJson.substring(lastEnd, matcher.start());
    //             String fullFieldName = matcher.group(0);
    //             List<String> fieldSplit = fullFieldName.split('__');
    //             String currentPrefix = fieldSplit.size() >= 2 ? fieldSplit[0] + '__' : '';
    //             if (currentPrefix.equals(prefix) || currentPrefix.equals(prefix.toLowerCase())) {
    //                 result += fullFieldName;
    //             } else if (currentPrefix != '') {
    //                 String modifiedPrefix = fullFieldName.equals(fullFieldName.toLowerCase()) ? prefix.toLowerCase() : prefix;
    //                 String modifiedFieldName = fullFieldName.replace(currentPrefix, modifiedPrefix);
    //                 result += modifiedFieldName;
    //             } else {
    //                 String modifiedFieldName = fullFieldName.equals(fullFieldName.toLowerCase()) ? prefix.toLowerCase() + fullFieldName : prefix + fullFieldName;
    //                 result += modifiedFieldName;
    //             }

    //             lastEnd = matcher.end();
    //         }

    //         result += columnsJson.substring(lastEnd);
    //         return result;
    //     } catch (Exception e) {
    //         System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    private static String processColumns(String columnsJson, String selectedPrefix) {
        try {
            if (String.isBlank(columnsJson)) {
                return columnsJson;
            }
            // Normalize user-chosen prefix to '', 'negoptim__', 'nGrid__'
            String targetNs = normalizeTargetPrefix(selectedPrefix);
            return rewriteCustomFieldNamespaces(columnsJson, targetNs);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String normalizeTargetPrefix(String selectedPrefix) {
        String p = selectedPrefix == null ? '' : selectedPrefix.trim();
        if (p.equalsIgnoreCase('none') || p.equalsIgnoreCase('no prefix') || p.equalsIgnoreCase('without prefix') || p.equalsIgnoreCase('without a prefix') || String.isBlank(p)) {
            return '';
        }
        return p.endsWith('__') ? p : p + '__';
    }

    private static String rewriteCustomFieldNamespaces(String text, String targetNs) {
        String regex = '(?i)\\b([a-z0-9_]+__)?([a-z0-9_]{1,80}__(?:c|r))\\b';
        Pattern pattern = Pattern.compile(regex);
        Matcher m = pattern.matcher(text);
        Integer lastEnd = 0;
        String out = '';
        while (m.find()) {
            out += text.substring(lastEnd, m.start());
            String core = m.group(2); 
            out += (String.isBlank(targetNs) ? '' : targetNs) + core;
            lastEnd = m.end();
        }
        out += text.substring(lastEnd);
        return out;
    }

    @AuraEnabled
    public static String importFiles(Map<String, Map<String, String>> xmlFileContent, String prefix) {
        try {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(SObjectType.Grid_Settings__mdt.Name).getDescribe().fields.getMap();
            List<Id> jobIdsList = new List<Id>();
            System.debug('xmlFileContent::: ' + JSON.serialize(xmlFileContent));
            for (String fileName : xmlFileContent.keySet()) {

                Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                customMetadata.fullName = SObjectType.Grid_Settings__mdt.Name + '.' + fileName;
                customMetadata.label = xmlFileContent.get(fileName).containsKey('label') ? xmlFileContent.get(fileName).get('label') : fileName;
                Map<String, String> mapValues = xmlFileContent.get(fileName);
                for (String key : mapValues.keySet()) {
                    if (key != 'label') {
                        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                        customField.field = fields.get(key).getDescribe().getName();
                        customField.value = processColumns(mapValues.get(key), prefix);
                        customMetadata.values.add(customField);
                    }
                }

                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(customMetadata);
                if (!Test.isRunningTest()) {
                    Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, new CustomMetadataCallback());
                    jobIdsList.add(jobId);
                }
            }
            return JSON.serialize(jobIdsList);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            throw new AuraHandledException('Error processing XML files: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        try {
            String sessionId = NegoptimHelper.getSessionId();
            if (sessionId != null) {
                Http http = new Http();
                HttpRequest httpReq = new HttpRequest();
                HttpResponse httpRes = new HttpResponse();
                httpReq.setMethod('GET');
                httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
                httpReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v51.0/metadata/deployRequest/' + idDeployment);
                httpRes = http.send(httpReq);
                String body = httpRes.getBody();
                return httpRes.getBody();
            }
            return 'Session Id Invalid';
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            return ex.getMessage();
        }
    }

    public class MainWrapper {
        public List<FieldWrapper> wFields {get; set;}
        public String displayedObjects { get; set; }
        public MainWrapper() {
            // Grid_Settings__mdt fields
            this.wFields = new List<FieldWrapper>();
            this.wFields.add(new FieldWrapper(SObjectType.Grid_Settings__mdt.fields.MasterLabel.Label, SObjectType.Grid_Settings__mdt.fields.MasterLabel.Name, true));
            this.wFields.add(new FieldWrapper(SObjectType.Grid_Settings__mdt.fields.DeveloperName.Label, SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name, true));
            this.wFields.add(new FieldWrapper(SObjectType.Grid_Settings__mdt.fields.Type__c.Label, SObjectType.Grid_Settings__mdt.fields.Type__c.Name, true));
            this.wFields.add(new FieldWrapper(SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Label, SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Name, true));
            this.wFields.add(new FieldWrapper(SObjectType.Grid_Settings__mdt.fields.Master_Object_Name__c.Label, SObjectType.Grid_Settings__mdt.fields.Master_Object_Name__c.Name, true));
        }
    }

    public class SelectOption {
        public String label;
        public String value;
        public SelectOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class FieldWrapper {
        public String fieldLabel;
        public String fieldName;
        public Boolean isDisplayed;

        public FieldWrapper(String fieldLabel, String fieldName, Boolean isDisplayed) {
            this.fieldLabel = fieldLabel;
            this.fieldName = fieldName;
            this.isDisplayed = isDisplayed;
        }
    }

    public class FilterWrapper {
        public String searchTerm;
        public String objectName;
        public String type;
        public FilterWrapper() {
            this.searchTerm = '';
            this.objectName = '';
            this.type = '';
        }
    }

    public class ResultWrapper {
        public List<SObject> records;
        public Integer total;
    }
}