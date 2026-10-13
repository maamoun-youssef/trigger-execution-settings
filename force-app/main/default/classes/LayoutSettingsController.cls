public with sharing class LayoutSettingsController {
    public static final String endpoint = '/services/data/v51.0/tooling/query/?q=';
    @AuraEnabled
    public static String initData() {
        ResultWrapper wrapper = new ResultWrapper();
        List<FlowRecord> screenFlows = [SELECT Id, ApiName, FlowLabel FROM FlowRecord where FlowType = 'Screen' ORDER BY FlowLabel];
        wrapper.screenFlows = new List<Map<String, String>>();
        for (FlowRecord flow : screenFlows) {
            wrapper.screenFlows.add(new Map<String, String>{
                'label' => flow.FlowLabel,
                'value' => flow.ApiName
            });
        }
        List<Map<String, String>> objectList = new List<Map<String, String>>();
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().Values()) {
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            if (objDescribe.getName().contains('__c'))
                objectList.add(new Map<String, String>{ 'label' => objDescribe.getLabel(), 'value' => objDescribe.getName() });
        }
        objectList.sort(new LabelComparator());
        wrapper.objects = objectList;
        List<Grid_Settings__mdt> gridSettings = [SELECT Id, Label, MasterLabel, QualifiedApiName, Object_Name__c, Master_Object_Name__c FROM Grid_Settings__mdt ORDER BY Label];
        wrapper.gridSettings = gridSettings;
        wrapper.pages = queryToolingAPI();
        List<FieldInfo> taskObjectFields = getRelatedObjectFields(SObjectType.Task.Name);
        List<FieldInfo> activityObjectFields = getRelatedObjectFields(SObjectType.TMP_Activity__c.Name);
        wrapper.activityObjectFields = activityObjectFields;
        wrapper.taskObjectFields = taskObjectFields;
        List<ParamSettingWrapper> lwcparams = loadAllLWCParamSettings();
        wrapper.lwcParamsSettingsList = lwcparams;
        List<ThemeSettings__mdt> themes = [
            SELECT DeveloperName, Label, ThemeAttributes__c
            FROM ThemeSettings__mdt
            ORDER BY DeveloperName LIMIT 1000
        ];
        if(!themes.isEmpty()) {
            wrapper.themesList = new List<Map<String, String>>();
            for (ThemeSettings__mdt theme : themes) {
                wrapper.themesList.add(new Map<String, String>{
                    'label' => theme.Label,
                    'value' => theme.DeveloperName,
                    'themeAttributes' => theme.ThemeAttributes__c
                });
            }
        }
        List<StaticResource> resourceList = [SELECT Id, Name, ContentType, BodyLength, NamespacePrefix FROM StaticResource ORDER BY Name ASC];
        wrapper.staticResourceList = new List<Map<String, String>>();
        for(StaticResource resource : resourceList) {
            wrapper.staticResourceList.add(new Map<String, String>{
                'key' => resource.Name,
                'value' => '/resource/' + resource.Name
            });
        }
        return JSON.serialize(wrapper); 
    }
    @AuraEnabled
    public static List<Map<String, Object>> getLayoutPagesList() {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        List<LayoutSettings__mdt> gridLayouts = [
            SELECT NamespacePrefix, DeveloperName, MasterLabel, ObjectApiName__c, Label
            FROM LayoutSettings__mdt
            ORDER BY DeveloperName LIMIT 1000
        ];
        System.debug('layout list:' + gridLayouts);
        for (LayoutSettings__mdt item : gridLayouts) {
            results.add(new Map<String, Object>{
                'key' => (item.NamespacePrefix != null ? item.NamespacePrefix + '__' : '') + item.DeveloperName,
                'MasterLabel' => item.MasterLabel,
                'NamespacePrefix' => item.NamespacePrefix,
                'ObjectApiName__c' => item.ObjectApiName__c,
                'Label' => item.Label
            });
        }
        System.debug('results:' + results);
        return results;
    }
    @AuraEnabled
    public static String getLayoutPageByDeveloperName(String developerName) {
        LayoutSettings layoutSettings = LayoutSettings.loadPageLayoutSettings(developerName);
        Map<String, Object> fields = getFields(layoutSettings.objectApiName);
        Map<String, Object> layoutData = new Map<String, Object>{
            'layoutSettings' => layoutSettings,
            'selectedObjectFields' => fields.get('fieldList'),
            'childRelationships' => fields.get('childRelationships')
        };
        return JSON.serialize(layoutData);
    }
    @AuraEnabled
    public static String saveSettings(String pageLayoutSettingsJSON) {
        LayoutSettings pageLayoutSettings = String.isNotBlank(pageLayoutSettingsJSON) ? (LayoutSettings) JSON.deserialize(pageLayoutSettingsJSON, LayoutSettings.class) : null;
        System.debug('pageLayoutSettings: ' + JSON.serialize(pageLayoutSettings));
        return LayoutSettings.save(pageLayoutSettings);
    }
    @AuraEnabled
    public static string deleteLayoutPage(){
        try {
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Map<String,Object> getFields(String objectName) {
        List<FieldInfo> fieldList = new List<FieldInfo>();
        List<Map<String, String>> childRelationships = new List<Map<String, String>>();
        if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
            return new Map<String,Object>{
                'fieldList' => fieldList,
                'childRelationships' => childRelationships
            };
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        for (Schema.SObjectField field : fields.values()){
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldName = fieldDescribe.getName();
            fieldList.add(new FieldInfo(
                fieldDescribe.getName(),
                fieldDescribe.getLabel(),
                String.valueOf(fieldDescribe.getType()),
                isAggregateableType(fieldDescribe.getType())
            ));
        }
        fieldList.sort(new LabelComparator());
        
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get(objectName);
        if (parentType != null) {
            Set<String> seen = new Set<String>();
            for (Schema.ChildRelationship rel : parentType.getDescribe().getChildRelationships()) {
                String relationshipName = rel.getRelationshipName();
                if (String.isBlank(relationshipName) || seen.contains(relationshipName)) {
                    continue;
                }
                String currentChildObject = rel.getChildSObject().getDescribe().getName();
                String currentField = rel.getField() != null ? rel.getField().getDescribe().getName() : null;
                String dedupeKey = currentChildObject + '|' + relationshipName + '|' + currentField;
                if (seen.contains(dedupeKey)) {
                    continue;
                }
                seen.add(dedupeKey);
                childRelationships.add(new Map<String, String> {
                    'relationshipApiName' => relationshipName,
                    'childObjectApiName' => currentChildObject,
                    'foreignKeyFieldApiName' => currentField,
                    'label' => rel.getChildSObject().getDescribe().getLabel() + ' · ' + relationshipName
                });
                
            }
            System.debug('Added childRelationships: ' + childRelationships);
        }
        childRelationships.sort(new LabelComparator());
        return new Map<String,Object>{
            'fieldList' => fieldList,
            'childRelationships' => childRelationships
        };
    }
    @AuraEnabled
    public static List<FieldInfo> getRelatedObjectFields(String objectName) {
        List<FieldInfo> fieldList = new List<FieldInfo>();
        if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
            return new List<FieldInfo>();
        }
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        for (Schema.SObjectField field : fields.values()){
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldName = fieldDescribe.getName();
            fieldList.add(new FieldInfo(
                fieldDescribe.getName(),
                fieldDescribe.getLabel(),
                String.valueOf(fieldDescribe.getType()),
                isAggregateableType(fieldDescribe.getType())
            ));
        }
        fieldList.sort(new LabelComparator());
        return fieldList;
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
    public static Authwrapper getAuthLocalOrg() {
        Authwrapper authWrap = new Authwrapper();
        authWrap.SERVER_URL = URL.getOrgDomainUrl().toExternalForm();
        authWrap.SESSION_ID = NegoptimHelper.getSessionId();
        return authWrap;
    }
    private static List<ParamSettingWrapper> loadAllLWCParamSettings() {
        List<ParamSettingWrapper> allLwcParams = new List<ParamSettingWrapper>();        
        List<LWC_Param_Setting__mdt> records = [SELECT Id, Label, MasterLabel, DeveloperName,
                                                Configuration__c, QualifiedApiName
                                                FROM LWC_Param_Setting__mdt
                                                ORDER BY DeveloperName ASC];        
        for (LWC_Param_Setting__mdt rec : records) {
            List<ParamSetting> param = String.isNotBlank(rec.Configuration__c)
                                    ? (List<ParamSetting>) JSON.deserialize(rec.Configuration__c, List<ParamSetting>.class)
                                    : new List<ParamSetting>();            
                                    
            ParamSettingWrapper  paramWrapper = new ParamSettingWrapper();
            paramWrapper.paramSetting = param;
            paramWrapper.name = rec.DeveloperName;
            allLwcParams.add(paramWrapper);
        }   
        return allLwcParams;
    }
    private static Boolean isAggregateableType(Schema.DisplayType fieldType) {
        return fieldType == Schema.DisplayType.Currency
            || fieldType == Schema.DisplayType.Double
            || fieldType == Schema.DisplayType.Integer
            || fieldType == Schema.DisplayType.Percent;
    }

    public class LabelComparator implements Comparator<Object> {
        public Integer compare(Object a, Object b) {
            String labelA = getLabel(a);
            String labelB = getLabel(b);

            if (String.isBlank(labelA) && String.isBlank(labelB)) return 0;
            if (String.isBlank(labelA)) return 1;
            if (String.isBlank(labelB)) return -1;

            return labelA.toLowerCase().compareTo(labelB.toLowerCase());
        }
        private String getLabel(Object obj) {
            if (obj == null) {
                return '';
            }
            if (obj instanceof Map<String, String>) {
                return (String)((Map<String, String>)obj).get('label');
            }
            if (obj instanceof FieldInfo) {
                return ((FieldInfo)obj).label;
            }
            return '';
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
     public class ResultWrapper {
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get;set;}
        public String prefix {get;set;}
        public List<Map<String, String>> screenFlows { get; set; }
        public List<Map<String, String>> themesList { get; set; }
        public List<Map<String, String>> objects { get; set; }
        public List<FieldInfo> activityObjectFields { get; set; }
        public List<FieldInfo> taskObjectFields { get; set; }
        List<Grid_Settings__mdt> gridSettings { get;set; }
        public List<Object> pages {get; set;}
        public List<ParamSettingWrapper> lwcParamsSettingsList{ get; set; }
        public List<Map<String, String>> staticResourceList {get; set;}
        public ResultWrapper() {
           this.prefix = NegoptimHelper.getPackagePrefix(true);
           Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.PageLayoutSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
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
    public class FieldInfo {
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public Boolean isAggregateable { get; set; }
        public FieldInfo(String apiName, String label, String type, Boolean isAggregateable) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.isAggregateable = isAggregateable;
        }        
    }
    public class ParamSetting {
        public String name {get; set;}
        public String label {get; set;}
        public String type {get; set;}
        public String datasource {get; set;}
        public String defaultValue {get; set;}
        public String description {get; set;}
        public String required {get; set;}
        public Map<String, String> getDataSourceList { get {
            Map<String, String> pickListValues = new Map<String, String>();
            if (String.isNotBlank(datasource)) {
                if (datasource.startsWith('apex://')) {
                    try {
                        String className = datasource.replace('apex://', '');
                        VisualEditor.DynamicPickList instance = (VisualEditor.DynamicPickList) System.Type.forName(className).newInstance();
                        for (VisualEditor.DataRow picklistRow : instance.getValues().getDataRows()) {
                            pickListValues.put((String)picklistRow.getValue(), (String)picklistRow.getLabel());
                        }
                    } catch(Exception e) {}
                }
                if (datasource.contains(',')) {
                    for(String value : datasource.split(',')) pickListValues.put(value.trim(), value.trim());
                }
            }
            return pickListValues;
        } set;}
        public ParamSetting() {
            this.name = '';
            this.label = '';
            this.type = '';
            this.datasource = '';
            this.defaultValue = '';
            this.description = '';
            this.required = '';
        }
    }
    public class ParamSettingWrapper {
        public List<ParamSetting> paramSetting {get; set;}
        public String name {get; set;}
    }
    public class Authwrapper {
        public String SERVER_URL {get; set;}
        public String SESSION_ID {get; set;}
    }
public static Map<String, Object> getElementTypes() {
    List<Object> commonStyle = new List<Object>{
        new Map<String,Object>{ 'name'=>'width',           'label'=>'Width',            'type'=>'number'},
        new Map<String,Object>{ 'name'=>'height',          'label'=>'Height',           'type'=>'number'},
        new Map<String,Object>{ 'name'=>'backgroundColor', 'label'=>'Background Color', 'type'=>'color'},
        new Map<String,Object>{ 'name'=>'color',           'label'=>'Color',            'type'=>'color'},
        new Map<String,Object>{ 'name'=>'borderRadius',    'label'=>'Border Radius',    'type'=>'number'},
        new Map<String,Object>{ 'name'=>'font-family',    'label'=>'font family',       'type'=>'text', 'options' => new List<Object>{new Map<String, Object>{ 'label' => 'Arial', 'value' => 'Arial' }, new Map<String, Object>{ 'label' => 'Helvetica', 'value' => 'Helvetica' }, new Map<String, Object>{ 'label' => 'Georgia', 'value' => 'Georgia' }}},
        new Map<String,Object>{ 'name'=>'font-size',    'label'=>'font size',           'type'=>'text'}
    };
    return new Map<String, Object>{
        'component' => new Map<String,Object>{
            'label' => 'Component',
            'isContainer' => true,
            'props' => new List<Object>{
                new Map<String,Object>{
                    'name'=>'type',
                    'label'=>'Type',
                    'type'=>'list',
                    'options'=>new List<Object>{
                        new Map<String,Object>{'label'=>'Grid','value'=>'grid'},
                        new Map<String,Object>{'label'=>'Page','value'=>'page'}
                    }
                },
                new Map<String,Object>{
                    'name'=>'params',
                    'label'=>'Parameters',
                    'type'=>'list',
                    'itemType'=>'lwcParam'
                }
            },
            'style' => commonStyle
        },
        'icon' => new Map<String,Object>{
            'label'=>'Icon',
            'isContainer'=>false,
            'props'=>new List<Object>{
                new Map<String,Object>{
                    'name'=>'type',
                    'label'=>'Type',
                    'type'=>'list',
                    'options'=>new List<Object>{
                        new Map<String,Object>{'label'=>'Primary','value'=>'primary'},
                        new Map<String,Object>{'label'=>'Secondary','value'=>'secondary'}
                    }
                },
                new Map<String,Object>{
                    'name'=>'name',
                    'label'=>'Icon Name',
                    'type'=>'text'
                },
                new Map<String,Object>{
                    'name'=>'contentType',
                    'label'=>'Content Type',
                    'type'=>'list',
                    'options'=>new List<Object>{
                        new Map<String,Object>{'label'=>'Static Resource','value'=>'staticResource'},
                        new Map<String,Object>{'label'=>'Field','value'=>'field'}
                    }
                }
            },
            'style'=>commonStyle
        },
        'action' => new Map<String,Object>{
            'label'=>'Action',
            'isContainer'=> false,
            'props'=>new List<Object>{
                new Map<String,Object>{
                    'name'=>'label',
                    'label'=>'Label',
                    'type'=>'text'
                },
                new Map<String,Object>{
                    'name'=>'icon',
                    'label'=>'Icon',
                    'type'=>'icon'
                },
                new Map<String,Object>{
                    'name'=>'actionType',
                    'label'=>'Action Type',
                    'type'=>'list',
                    'options'=>new List<Object>{
                        new Map<String,Object>{'label'=>'Button','value'=>'button'},
                        new Map<String,Object>{'label'=>'Icon','value'=>'icon'},
                        new Map<String,Object>{'label'=>'Text','value'=>'text'},
                        new Map<String,Object>{'label'=>'On Click','value'=>'onclick'}
                    }
                },
                new Map<String,Object>{
                    'name'=>'redirectionType',
                    'label'=>'Redirection Type',
                    'type'=>'list',
                    'options'=>new List<Object>{
                        new Map<String,Object>{'label'=>'Flow','value'=>'flow'},
                        new Map<String,Object>{'label'=>'URL','value'=>'url'}
                    }
                },
                new Map<String,Object>{
                    'name'=>'redirectionValue',
                    'label'=>'Redirection Value',
                    'type'=>'text'
                }
            },
            'style'=>commonStyle
        },
        'field' => new Map<String,Object>{
            'label'=>'Field',
            'isContainer'=>false,
            'props'=>new List<Object>{
                new Map<String,Object>{
                    'name'=>'fieldName',
                    'label'=>'Field Name',
                    'type'=>'text'
                },
                new Map<String,Object>{
                    'name'=>'type',
                    'label'=>'Type',
                    'type'=>'text'
                },
                new Map<String,Object>{
                    'name'=>'showLabel',
                    'label'=>'Show Label',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'isHeaderField',
                    'label'=>'Header Field',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'isMandatory',
                    'label'=>'Mandatory',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'isReadOnly',
                    'label'=>'Read Only',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'stickyBar',
                    'label'=>'Sticky Bar',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'standard',
                    'label'=>'Standard',
                    'type'=>'boolean'
                }
            },
            'style'=> commonStyle
        },
        'form' => new Map<String,Object>{
            'label'=>'Form',
            'isContainer'=> true,
            'props'=> new List<Object>{
                new Map<String,Object>{
                    'name'=>'fields',
                    'label'=>'Fields',
                    'type'=>'list',
                    'itemType'=>'field'
                },
                new Map<String,Object>{
                    'name'=>'isEditable',
                    'label'=>'Editable',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'isManualEdit',
                    'label'=>'Manual Edit',
                    'type'=>'boolean'
                },
                new Map<String,Object>{
                    'name'=>'flow',
                    'label'=>'Flow',
                    'type'=>'text'
                },
                new Map<String,Object>{
                    'name'=>'rows',
                    'label'=>'Rows',
                    'type'=>'number'
                },
                new Map<String,Object>{
                    'name'=>'columns',
                    'label'=>'Columns',
                    'type'=>'number'
                }
            },
            'style'=> commonStyle
        },
        'tab' => new Map<String,Object>{
            'label'=>'Tab',
            'isContainer'=>true,
            'props'=>new List<Object>{
                new Map<String,Object>{
                    'name'=>'numberOfTabs',
                    'label'=>'Number Of Tabs',
                    'type'=>'number'
                }
            },
            'style'=>commonStyle
        }
    };
}
}