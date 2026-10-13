/**
 * @author ULiT
 * @date 16/3/2019
 * @description Manages the settings for pages with daynamic grids
 * specify in the constructor the Sobject ApiName, the static fields that are mandaory for the back-end controller, and the developerName of the metadata record
 * that registers the fields to be dispalyed in the dynamic grid
 * the constructors does the necessary validations and fills the attributes
 */
global with sharing class GridSettingsManager {
	public String OBJECT_NAME;
	private String STATIC_FIELDS;
	public static final String SUM = 'SUM';
	public static final String AVG = 'AVG';
	public static final String COUNT = 'COUNT';
	public static final String ISNULL = 'ISNULL';
	public static final String ISBLANK = 'ISBLANK';
	public static final String EQUALS = 'EQUALS';
	public static final String NOT_EQUALS = 'NOT_EQUALS';
	public static final String BETWEEN = 'BETWEEN';
	public static final String GREATER = 'GREATER';
	public static final String GREATER_OR_EQUALS = 'GREATER_OR_EQUALS';
	public static final String LESS = 'LESS';
	public static final String LESS_OR_EQUALS = 'LESS_OR_EQUALS';
	public static final String CONTAINS = 'CONTAINS';
	public static final String NOT_CONTAINS = 'NOT_CONTAINS';
	public Grid_Settings__mdt gridLayout { get; set; }
	public static final Map<String, String> operations = new Map<String, String>{GridSettingsManager.EQUALS => '==', GridSettingsManager.NOT_EQUALS => '!=', GridSettingsManager.GREATER => '>', GridSettingsManager.GREATER_OR_EQUALS => '>=', GridSettingsManager.LESS => '<', GridSettingsManager.LESS_OR_EQUALS => '<='};
	global List<String> ALL_FIELDS { get; set; }
	private List<String> SEARCHABLE_FIELDS { get; set; }
	private Criteria readOnlyCriteria { get; set; }
	global List<FieldWrapper> GRID_FIELDS { get; set; }
	global List<FilterSettings> FILTERS { get; set; }
	global List<FilterSettings> USERFILTERS { get; set; }

	public List<FilterSettings> FILTER_FIELDS { get; set; }
	public CalendarSettingsWrapper CALENDAR_SETTINGS { get; set; }
	public TimeLineSettingsWrapper TIME_LINE_SETTINGS { get; set; }
	global List<String> ERRORS { get; set; }
	global List<String> WARNINGS { get; set; }
	global Map<String, Map<String, String>> picklistValuesMap { get; set; }
	public Map<String, String> objectReferenceMap { get; set; }
	public Boolean isReadOnly { get; set; }
    
    // Grid Configuration Variables
	global Boolean isShowFilterOnColumnHeader { get; set; }
    public Integer Default_Page_Size = 50;
	public ActionWrapper actions;
	public Boolean Include_In_List_View = false;
	public Integer Display_Order;
    public Boolean overrideFilter = false;
    public List<String> hierarchyParentField = new List<String>();
    public String groupedField;
    public String gridTypeValue;
    public String importSettingsTemplate;
	// Banners
	public String Master_OBJECT_NAME;
	private String Master_OBJECT_STATIC_FIELDS;
	global List<String> ALL_BANNER_FIELDS { get; set; }
	public List<FieldWrapper> BANNER_FIELDS { get; set; }
    
    // Label of layout
    public String layoutLabel;
    public String layoutSlogan;
	public String objectLabel;
    public String templateType;
    
	public static Grid_Settings__mdt loadTemplate(String metadataDeveloperName) {
		try {
			// return [SELECT Id, DeveloperName, MasterLabel, Columns__c, Object_Name__c, Custom_JS__c, Master_Object_Columns__c, Master_Object_Name__c, Icon__c, Filters__c, Type__c, Relationship_Name__c
			if(String.isNotBlank(metadataDeveloperName)) {
				List<Grid_Settings__mdt> templates = [SELECT Id, Compiled_Grid_JSON__c, Calendar_Setting__c, Time_Line_Settings__c, Grid_Slogan__c,
													DeveloperName, MasterLabel, Columns__c, Object_Name__c, Master_Object_Columns__c, Master_Object_Name__c, Icon__c, Filters__c,
													ReadOnly_Criteria__c, Type__c, Relationship_Name__c, Grid_Configuration__c, NamespacePrefix
													FROM Grid_Settings__mdt
													WHERE DeveloperName = :metadataDeveloperName
                                                    WITH USER_MODE
													ORDER BY NamespacePrefix NULLS FIRST];
				if(templates != null && !templates.isEmpty()) {
					return templates[0];
				} else if (Test.isRunningTest()) {
					templates = GridSettingsMockDataSource.getTemplates(metadataDeveloperName);
					if(templates != null && !templates.isEmpty()) {
						return templates[0];
					}
				}
			}
		} catch (QueryException qe) { 
			NegoptimHelper.getInaccessibleFields(qe); 
        } catch (Exception e) {
			System.debug('Error FakeSaveResult ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
		return null;

	}
    
    global static String loadGridSettingsManagerSerialized(GridSettingsManager gridSettingManager) {
        return JSON.serialize(gridSettingManager);
    }
    
    global static GridSettingsManager loadGridSettingsManagerDeserialized(String gridSettingsManagerSerialized) {
        GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettingsManagerSerialized, GridSettingsManager.class);
        return gridSettingsManager;
	}
    
	global GridSettingsManager(String objectName, String staticFields, String metadataDeveloperName) {
		populateFields(null, '', '', objectName, staticFields, '', metadataDeveloperName, null, false, false);
	}
	global GridSettingsManager(String objectName, String staticFields, String metadataDeveloperName, Boolean loadAllFilters) {
		populateFields(null, '', '', objectName, staticFields, '', metadataDeveloperName, null, loadAllFilters == true, false);
	}
	global GridSettingsManager(String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName) {
		populateFields(null, '', '', objectName, staticFields, safeStaticFields, metadataDeveloperName, null, false, false);
	}
	global GridSettingsManager(String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName, Boolean loadAllFilters) {
		populateFields(null, '', '', objectName, staticFields, safeStaticFields, metadataDeveloperName, null, loadAllFilters == true, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String objectName, String staticFields, String metadataDeveloperName) {
		populateFields(masterObjectName, masterStaticFields, '', objectName, staticFields, '', metadataDeveloperName, null, false, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String objectName, String staticFields, String metadataDeveloperName, Boolean loadAllFilters) {
		populateFields(masterObjectName, masterStaticFields, '', objectName, staticFields, '', metadataDeveloperName, null, loadAllFilters == true, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String safeMasterStaticFields, String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName) {
		populateFields(masterObjectName, masterStaticFields, safeMasterStaticFields, objectName, staticFields, safeStaticFields, metadataDeveloperName, null, false, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String safeMasterStaticFields, String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName, Boolean loadAllFilters) {
		populateFields(masterObjectName, masterStaticFields, safeMasterStaticFields, objectName, staticFields, safeStaticFields, metadataDeveloperName, null, loadAllFilters == true, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String safeMasterStaticFields, String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName, String filter) {
		populateFields(masterObjectName, masterStaticFields, safeMasterStaticFields, objectName, staticFields, safeStaticFields, metadataDeveloperName, filter, false, false);
	}
	global GridSettingsManager(String masterObjectName, String masterStaticFields, String safeMasterStaticFields, String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName, String filter, Boolean loadAllFilters) {
		populateFields(masterObjectName, masterStaticFields, safeMasterStaticFields, objectName, staticFields, safeStaticFields, metadataDeveloperName, filter, loadAllFilters == true, false);
	}
	public GridSettingsManager(Boolean doCompile, String masterObjectName, String objectName, String metadataDeveloperName) {
		populateFields(masterObjectName, '', '', objectName, '', '', metadataDeveloperName, null, true, doCompile);
	}
	public List<String> reccursiveFieldDependencies (List<String> allDependencies, List<String> fieldNames, Map<String, List<String>> fieldDependencies, Map<String, String> fieldsControllerMap) {
		List<String> currentDependencies = new List<String>();
		for (String fieldName : fieldNames) {
			if(!allDependencies.contains(fieldName)) {
				allDependencies.add(fieldName);
			}
			if (fieldsControllerMap != null && fieldsControllerMap.containsKey(fieldName) && !currentDependencies.contains(fieldsControllerMap.get(fieldName)) /*&& !allDependencies.contains(fieldsControllerMap.get(fieldName))*/) {
				currentDependencies.add(fieldsControllerMap.get(fieldName));
			}
			if (fieldDependencies != null && fieldDependencies.containsKey(fieldName) ) {
				for (String fd : fieldDependencies.get(fieldName)) {
					if(!currentDependencies.contains(fd) /*&& !allDependencies.contains(fd)*/) {
						currentDependencies.add(fd);
					}
				}
				//allDependencies.addAll(fieldDependencies.get(fieldName));
			}
		}
		if (!currentDependencies.isEmpty()) {
			allDependencies.addAll(currentDependencies);
			reccursiveFieldDependencies(allDependencies, currentDependencies, fieldDependencies, fieldsControllerMap);
		}
		return allDependencies;
	}
	private void populateFields(String masterObjectName, String masterStaticFields, String safeMasterStaticFields, String objectName, String staticFields, String safeStaticFields, String metadataDeveloperName, String filterJSON, Boolean loadAllFilters, Boolean doCompile) {
        this.ERRORS = new List<String>();
        this.isReadOnly = false;
        this.OBJECT_NAME = objectName;
        this.STATIC_FIELDS = staticFields != null ? staticFields.replaceAll('(\\s+)', '') : '';
        this.picklistValuesMap = new Map<String, Map<String, String>>();
        this.objectReferenceMap = new Map<String, String>();
        this.ALL_FIELDS = new List<String>{'id'};
        this.Master_OBJECT_NAME = masterObjectName;
        this.Master_OBJECT_STATIC_FIELDS = masterStaticFields != null ? masterStaticFields.replaceAll('(\\s+)', '') : '';
        safeMasterStaticFields = safeMasterStaticFields != null && String.isNotBlank(safeMasterStaticFields) ? safeMasterStaticFields.replaceAll('(\\s+)', '') : '';
        safeStaticFields = safeStaticFields != null && String.isNotBlank(safeStaticFields) ? safeStaticFields.replaceAll('(\\s+)', '') : '';
        this.ALL_BANNER_FIELDS = new List<String>{'id'};
        this.WARNINGS = new List<String>();
        this.GRID_FIELDS = new List<FieldWrapper>();
        this.BANNER_FIELDS = new List<FieldWrapper>();
        this.FILTERS = new List<FilterSettings>();
        this.USERFILTERS = new List<FilterSettings>();
        this.FILTER_FIELDS = new List<FilterSettings>();
        this.CALENDAR_SETTINGS = new CalendarSettingsWrapper();
        this.TIME_LINE_SETTINGS = new TimeLineSettingsWrapper();
		this.gridLayout = loadTemplate(metadataDeveloperName);
        if(this.gridLayout != null && String.isNotBlank(this.gridLayout.MasterLabel)) {
            this.layoutLabel = NegoptimLabels.getCustomLabel(this.gridLayout.MasterLabel, this.gridLayout.MasterLabel);
        }
        if (this.gridLayout != null && String.isNotBlank(this.gridLayout.Grid_Slogan__c)) {
            this.layoutSlogan = NegoptimLabels.getCustomLabel(this.gridLayout.Grid_Slogan__c, this.gridLayout.Grid_Slogan__c);
        }
        if (this.gridLayout != null && String.isNotBlank(this.gridLayout.Object_Name__c)) {
            this.objectLabel = NegoptimHelper.getSObjectLabel(this.gridLayout.Object_Name__c);
        }
        if (this.gridLayout != null && String.isNotBlank(this.gridLayout.Type__c)) {
            this.templateType = NegoptimLabels.getCustomLabel(this.gridLayout.Type__c, this.gridLayout.Type__c);
        }
        if (this.gridLayout == null) {
            this.ERRORS.add(System.Label.MSG_Template_Not_Found);
            return;
        }
		if (String.isBlank(this.gridLayout.Compiled_Grid_JSON__c) || doCompile) {
            try {
                if (String.isNotBlank(this.STATIC_FIELDS)) {
                    for (String fieldname : STATIC_FIELDS.split(',')) {
                        if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
                            this.ALL_FIELDS.add(fieldname.toLowerCase());
                            continue;
                        }
                        List<String> fields = fieldname.split('\\.');
                        String result = NegoptimHelper.addFieldPrefix(this.OBJECT_NAME, fields.clone());
                        if (result != null && !this.ALL_FIELDS.contains(NegoptimHelper.normalizeAPIName(result).toLowerCase())) {
                            this.ALL_FIELDS.add(NegoptimHelper.normalizeAPIName(result).toLowerCase());
                        }
                    }
                }
				if (String.isNotBlank(safeStaticFields)) {
					this.STATIC_FIELDS = String.isNotBlank(this.STATIC_FIELDS) ? this.STATIC_FIELDS + ',' + safeStaticFields : safeStaticFields;
					for (String fieldname : safeStaticFields.split(',')) {
						if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
							this.ALL_FIELDS.add(fieldname.toLowerCase());
							continue;
						}
						if (fieldname != null && !this.ALL_FIELDS.contains(fieldname.toLowerCase())) {
							this.ALL_FIELDS.add(fieldname.toLowerCase());
						}
					}
				}
				if (String.isNotBlank(this.Master_OBJECT_STATIC_FIELDS)) {
					for (String fieldname : Master_OBJECT_STATIC_FIELDS.split(',')) {
						if (fieldname.equalsIgnoreCase('id')) {
							continue;
						}
						if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
							this.ALL_BANNER_FIELDS.add(fieldname.toLowerCase());
							continue;
						}
						List<String> fields = fieldname.split('\\.');
						String result = NegoptimHelper.addFieldPrefix(this.Master_OBJECT_NAME, fields.clone());
						if (result != null && !this.ALL_BANNER_FIELDS.contains(NegoptimHelper.normalizeAPIName(result).toLowerCase())) {
							this.ALL_BANNER_FIELDS.add(NegoptimHelper.normalizeAPIName(result).toLowerCase());
						}
					}
				}
				if (String.isNotBlank(safeMasterStaticFields)) {
					this.Master_OBJECT_STATIC_FIELDS = String.isNotBlank(this.Master_OBJECT_STATIC_FIELDS) ? this.Master_OBJECT_STATIC_FIELDS + ',' + safeMasterStaticFields : safeMasterStaticFields;
					for (String fieldname : safeMasterStaticFields.split(',')) {
						if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
							this.ALL_BANNER_FIELDS.add(fieldname.toLowerCase());
							continue;
						}
						if (fieldname != null && !this.ALL_BANNER_FIELDS.contains(fieldname.toLowerCase())) {
							this.ALL_BANNER_FIELDS.add(fieldname.toLowerCase());
						}
					}
				}
				if (String.isNotBlank(metadataDeveloperName)) {
					// load fields of the selected grid from custom metadata type
					// List<Grid_Settings__mdt> gridLayouts = [SELECT Id, Master_Object_Name__c, Master_Object_Columns__c, Columns__c, DeveloperName, Object_Name__c, Custom_Js__c, Icon__c, Filters__c, Type__c, Relationship_Name__c
					Map<String, FilterSettings> filtersMap = new Map<String, FilterSettings>();
                    if ((this.gridLayout.Object_Name__c != null && this.OBJECT_NAME != null && !this.OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Object_Name__c)) || (this.gridLayout.Master_Object_Name__c != null && this.Master_OBJECT_NAME != null && !this.Master_OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Master_Object_Name__c))) {
                        this.ERRORS.add(System.Label.MSG_Template_Objects_Missmatch);
                    }
                    this.isReadOnly = this.OBJECT_NAME != null && String.isNotBlank(this.OBJECT_NAME) && Schema.getGlobalDescribe().containsKey(this.OBJECT_NAME) ? !Schema.getGlobalDescribe().get(this.OBJECT_NAME).getDescribe().isUpdateable() : true;
                    // grid_conf
                    if (String.isNotBlank(this.gridLayout.Grid_Configuration__c)){
                        GridConfigurationWrapper gridConfs = (GridConfigurationWrapper)JSON.deserialize(this.gridLayout.Grid_Configuration__c, GridConfigurationWrapper.class);
                        if (gridConfs.Default_Page_Size != null) {
                            this.Default_Page_Size = gridConfs.Default_Page_Size;
                        }
                        if (gridConfs.isShowFilterOnColumnHeader != null) {
                            this.isShowFilterOnColumnHeader = gridConfs.isShowFilterOnColumnHeader;
                        }
						if (gridConfs.actions != null) {
							this.actions = gridConfs.actions;
						}
						if (gridConfs!= null && gridConfs.Include_In_List_View == true) {
							this.Include_In_List_View = gridConfs.Include_In_List_View;
						} else {
							this.Include_In_List_View = false;
						}
						if (gridConfs.Display_Order != null) {
							this.Display_Order = gridConfs.Display_Order;
						} else {
							this.Display_Order = null;
						}
						if (gridConfs.hierarchyParentField != null) {
                            this.hierarchyParentField = gridConfs.hierarchyParentField;
                        }
						if (gridConfs.groupedField != null) {
                            this.groupedField = gridConfs.groupedField;
                        }
						if (gridConfs.gridTypeValue != null) {
                            this.gridTypeValue = gridConfs.gridTypeValue;
                        }
						if (gridConfs.importSettingsTemplate != null) {
                            this.importSettingsTemplate = gridConfs.importSettingsTemplate;
                        }
                        this.overrideFilter = false;
                    }
                    if (String.isNotBlank(this.gridLayout.Calendar_Setting__c)){
                        CalendarSettingsWrapper calendarSettings = (CalendarSettingsWrapper)JSON.deserialize(this.gridLayout.Calendar_Setting__c, CalendarSettingsWrapper.class);
                        if (calendarSettings!= null) {
                            this.CALENDAR_SETTINGS = calendarSettings;
                        }
                    }
                    if (String.isNotBlank(this.gridLayout.Time_Line_Settings__c)){
                        TimeLineSettingsWrapper timeLine = (TimeLineSettingsWrapper)JSON.deserialize(this.gridLayout.Time_Line_Settings__c, TimeLineSettingsWrapper.class);
                        if (timeLine!= null) {
                            this.TIME_LINE_SETTINGS = timeLine;
                        }
                    }
                    // Fill Banner Fields
                    if (this.Master_OBJECT_NAME != null && this.gridLayout.Master_Object_Name__c != null && this.gridLayout.Master_Object_Columns__c != null && String.isNotBlank(this.gridLayout.Master_Object_Name__c) && String.isNotBlank(this.Master_OBJECT_NAME) && String.isNotBlank(this.gridLayout.Master_Object_Columns__c) && this.Master_OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Master_Object_Name__c)) {
                        List<FieldWrapper> bannerFields = (List<FieldWrapper>)JSON.deserialize(this.gridLayout.Master_Object_Columns__c, List<FieldWrapper>.class);
                        Map<String, String> developerNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Schema.getGlobalDescribe().get(this.gridLayout.Master_Object_Name__c));
                        for (FieldWrapper field : bannerFields) {
                            try {
                                if (!field.fieldName.equals('')) {
                                    //List<String> fields = NegoptimHelper.normalizeAPIName(field.fieldName).split('\\.');
                                    List<String> fields = field.fieldName.split('\\.');
                                    Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.Master_OBJECT_NAME, fields.clone());
                                    if (fieldResult != null) {
										DescribeFieldResult dfr = fieldResult.getDescribe();
                                        if (!dfr.isAccessible()) {
                                            this.WARNINGS.add(Label.MSG_No_Read_Access + ' "' + Master_OBJECT_NAME + '.' + field.fieldName + '"');
                                            throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + Master_OBJECT_NAME + '.' + field.fieldName + '"');
                                        } else {
											field.fieldName = dfr.getName();
											field.fieldLabel = dfr.getLabel();
                                            field.fieldType = dfr.getType();
                                            field.isCalculated = dfr.isCalculated() && field.stringFieldType != 'ID';
                                            field.isEncrypted = dfr.isEncrypted();
                                            field.isFilterable = dfr.isFilterable();
                                            field.scale = dfr.getScale();
                                            field.isAccessible = dfr.isAccessible();
                                            field.isCreateable = dfr.isCreateable();
                                            field.isUpdateable = dfr.isUpdateable();
                                            field.isReference = fields.size() > 1;
                                            field.helpText = dfr.getInlinehelptext();
                                            field.isHTMLFormatted = dfr.isHtmlFormatted();
                                            // insert fields to query
                                            if (!this.ALL_BANNER_FIELDS.contains(field.fieldName.toLowerCase())) {
                                                this.ALL_BANNER_FIELDS.add(field.fieldName.toLowerCase());
                                            }
											// picklist values
											if (field.fieldType == DisplayType.Picklist || field.fieldType == DisplayType.MultiPicklist) {												
												field.pickListValues = new List<SelectOption>();
												for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
													field.pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
												}
											}
											if (field.fieldName.equalsIgnoreCase('RecordTypeId')) {
												field.pickListValues = new List<SelectOption>();
												for (String key : developerNameToLabelMap.keySet()) {
													field.pickListValues.add(new SelectOption(key, developerNameToLabelMap.get(key)));
												}
                                            }
                                            if (field.fieldType.name() == 'REFERENCE') {
                                                String referenceFieldName = field.fieldName;
                                                if (referenceFieldName.endsWithIgnoreCase('__c')) {
                                                    referenceFieldName = referenceFieldName.replace('__c', '__r.Name').toLowerCase();
                                                } else if(referenceFieldName.endsWithIgnoreCase('id')){
                                                    Integer lastIndexOfId = referenceFieldName.toLowerCase().lastIndexOf('id');
                                                    if (lastIndexOfId != -1) {
                                                        referenceFieldName = (referenceFieldName.subString(0, lastIndexOfId) + '.Name').toLowerCase();
                                                    }
                                                }
                                                if (!this.ALL_BANNER_FIELDS.contains(referenceFieldName.toLowerCase())) {
                                                    this.ALL_BANNER_FIELDS.add(referenceFieldName.toLowerCase().endsWith('recordtype.name') ? 'tolabel(' + referenceFieldName.toLowerCase() + ')' : referenceFieldName.toLowerCase());
                                                }
                                            }
                                            this.BANNER_FIELDS.add(field);
                                        }
                                    } else {
                                        this.WARNINGS.add(Label.MSG_No_Read_Access + ' "' + Master_OBJECT_NAME + '.' + field.fieldName + '"');
                                        throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + Master_OBJECT_NAME + '.' + field.fieldName + '"');
                                    }
                                }
                            } catch (Exception ex) {
                                this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
                            }
                        }
                    }
                    // Fill Grid Fields
                    if (this.OBJECT_NAME != null && this.gridLayout.Object_Name__c != null && this.gridLayout.Columns__c != null && String.isNotBlank(this.gridLayout.Object_Name__c) && String.isNotBlank(this.OBJECT_NAME) && String.isNotBlank(this.gridLayout.Columns__c) && this.OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Object_Name__c) && Schema.getGlobalDescribe().containsKey(this.gridLayout.Object_Name__c)) {
                        Map<Id, String> recordTypeIdMap = /*NegoptimHelper.*/getObjectRecordTypeMapLabels(Schema.getGlobalDescribe().get(this.gridLayout.Object_Name__c));
                        Map<Id, String> recordTypeDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Schema.getGlobalDescribe().get(this.gridLayout.Object_Name__c));
                        if (!filtersMap.containsKey('RecordTypeId')) {
                            FieldWrapper field = new FieldWrapper('RecordTypeId', false);
                            field.fieldName = 'RecordTypeId';
                            List<String> fields = NegoptimHelper.normalizeAPIName('RecordTypeId').split('\\.');
                            Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.gridLayout.Object_Name__c, fields.clone());
                            if (fieldResult != null) {
                                DescribeFieldResult dfr = fieldResult.getDescribe();
                                if (dfr.isAccessible()) {
                                    field.pickListValues = new List<SelectOption>();
                                    field.fieldLabel = dfr.getLabel();
                                    for (String recordtype : recordTypeIdMap.keySet()) {
                                        field.pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                                    }
                                    FilterSettings filterSetting = new FilterSettings(field);
                                    filterSetting.objectName = OBJECT_NAME;
                                    filtersMap.put(field.fieldName, filterSetting);
                                }
                            }
                        }
                        List<FieldWrapper> savedGridFields = (List<FieldWrapper>)JSON.deserialize(this.gridLayout.Columns__c, List<FieldWrapper>.class);
						Map<String, FieldWrapper> fieldsMap = new Map<String, FieldWrapper>();
						for (FieldWrapper fw : savedGridFields) {
							fieldsMap.put(fw.fieldName, fw);
						}
                        String previousFieldvalue = savedGridFields.isEmpty() ? '' : savedGridFields.get(0).fieldName;
                        FieldWrapper previousField = savedGridFields.isEmpty() ? null : savedGridFields.get(0);
                        Map<String, List<String>> picklistDependenciesMap = new Map<String, List<String>>();
                        Map<String, String> picklistControllersMap = new Map<String,String>();
                        if (loadAllFilters == true && this.OBJECT_NAME != null && this.gridLayout.Object_Name__c != null && String.isNotBlank(this.gridLayout.Object_Name__c) && String.isNotBlank(this.OBJECT_NAME) && this.OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Object_Name__c) && Schema.getGlobalDescribe().containsKey(this.gridLayout.Object_Name__c)) {
                            Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(this.OBJECT_NAME).getDescribe().fields.getMap();
                            for (String key : objectFieldsMap.keySet()) {
                                DescribeFieldResult dfr = objectFieldsMap.get(key).getDescribe();
                                FieldWrapper field = new FieldWrapper();
                                field.fieldName = dfr.getName();
                                field.fieldLabel = dfr.getLabel();
                                field.fieldType = dfr.getType();
                                field.isCalculated = dfr.isCalculated();
                                field.isEncrypted = dfr.isEncrypted();
                                field.isFilterable = dfr.isFilterable();
                                field.helpText = dfr.getInlinehelptext();
                                FieldWrapper matchingField = fieldsMap.get(field.fieldName);
								field.scale = matchingField != null && matchingField.scale != null ? matchingField.scale : dfr.getScale();
                                field.isAccessible = dfr.isAccessible();
                                field.isCreateable = dfr.isCreateable();
                                field.isUpdateable = dfr.isUpdateable();
                                field.isHTMLFormatted = dfr.isHtmlFormatted();
                                if (field.fieldType.name() == 'REFERENCE' && !field.fieldName.endsWithIgnoreCase('RecordTypeId')) {
                                    String referenceFieldName = field.fieldName;
                                    if (referenceFieldName.endsWithIgnoreCase('__c')) {
                                        referenceFieldName = referenceFieldName.replace('__c', '__r.Name').toLowerCase();
                                    } else {
                                        Integer lastIndexOfId = referenceFieldName.toLowerCase().lastIndexOf('id');
                                        if (lastIndexOfId != -1) {
                                            referenceFieldName = (referenceFieldName.subString(0, lastIndexOfId) + '.Name').toLowerCase();
                                        }
                                    }
                                    if (!this.ALL_FIELDS.contains(referenceFieldName.toLowerCase())) {
                                        this.ALL_FIELDS.add(referenceFieldName.toLowerCase().endsWith('recordtype.name') ? 'tolabel(' + referenceFieldName.toLowerCase() + ')' : referenceFieldName.toLowerCase());
                                    }
                                }
                                if(field.fieldName != null && dfr.getReferenceTo() != null && !dfr.getReferenceTo().isEmpty()) {
                                    this.objectReferenceMap.put(field.fieldName,  dfr.getReferenceTo().get(0).getDescribe().getName());
                                }
                                if (field.fieldType == DisplayType.Picklist || field.fieldType == DisplayType.MultiPicklist) {
                                    field.controllerName = dfr.getController()?.getDescribe().getName();
                                    
                                    if (String.isNotBlank(field.controllerName)) {
                                        picklistControllersMap.put(field.fieldName, field.controllerName);
                                        if(!picklistDependenciesMap.containsKey(field.controllerName)) {
                                            picklistDependenciesMap.put(field.controllerName, new List<String>());
                                        }
                                        picklistDependenciesMap.get(field.controllerName).add(field.fieldName);
                                    }
                                    if (field.controllerName != null) {
                                        if (!this.ALL_FIELDS.contains(field.controllerName.toLowerCase())) {
                                            this.ALL_FIELDS.add(field.controllerName.toLowerCase());
                                        }
                                    }
                                    if (field.controlledByFields != null && !field.controlledByFields.isEmpty()) {
                                        for(String controlledfield : field.controlledByFields) {
                                            if (!this.ALL_FIELDS.contains(controlledfield.toLowerCase())) {
                                                this.ALL_FIELDS.add(controlledfield.toLowerCase());
                                            }
                                        }
                                    }
                                    // TODO add the controller by to the All_Fields
                                    this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                                    field.pickListValues = new List<SelectOption>();
                                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                                        field.pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                                        this.picklistValuesMap.get(field.fieldName).put(pe.getValue(), pe.getLabel());
                                    }
                                }
                                if (field.fieldName.equalsIgnoreCase('RecordTypeId')) {
                                    this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                                    field.pickListValues = new List<SelectOption>();
                                    for (String recordtype : recordTypeIdMap.keySet()) {
                                        field.pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                                        this.picklistValuesMap.get(field.fieldName).put(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype));
                                    }
                                }
                                if (field.isFilterable) {
                                    FilterSettings filterSetting = new FilterSettings(field);
                                    filterSetting.objectName = OBJECT_NAME;
                                    filtersMap.put(field.fieldName, filterSetting);
                                }
                            }
                        }
                        for (FieldWrapper field : savedGridFields) {
                            try {
                                field.controlledByFields = new List<String>();
                                if (picklistControllersMap.containsKey(field.fieldName)) {
                                    field.controlledByFields.addAll(reccursiveFieldDependencies(new List<String>(), new List<String>{picklistControllersMap.get(field.fieldName)}, null, picklistControllersMap));
                                }
                                if (picklistDependenciesMap.containsKey(field.fieldName)) {
                                    field.controlledByFields.addAll(reccursiveFieldDependencies(new List<String>(), picklistDependenciesMap.get(field.fieldName), picklistDependenciesMap, null));
                                    if (field.controlledByFields.contains(field.fieldName)) {
                                        field.controlledByFields.remove(field.controlledByFields.indexOf(field.fieldName));
                                    }
                                }
                                field.isBorderColumn = previousFieldvalue.equals('') || previousFieldvalue.equals('');
                                if (!field.hasConditionalFormating && field.nonConditional != null && field.nonConditional.bgColor != null) {
                                    field.bgColor = field.nonConditional.bgColor;
                                }
                                if (field.bgColor == null || field.bgColor == '') {
                                    field.bgColor = '#FFFFFF';
                                }
                                if (field.isBorderColumn) {
                                    field.separatorSettings = previousField.separatorSettings;
                                    field.borderColor = previousField.bgColor != null && !String.isBlank(previousField.bgColor) ? previousField.bgColor : '#FFFFFF';
                                }
                                previousFieldvalue = String.isNotBlank(field.fieldName) ? NegoptimHelper.normalizeAPIName(field.fieldName) : '';
                                if (field.isPersonalised || (field.isFormula != null && field.isFormula)) {
                                    field.fieldLabel = field.fieldLabel;
                                    field.isInputField = false;
                                    if (field.isFormula != null && field.isFormula) {
                                        Pattern p = Pattern.compile('\\b[a-zA-Z0-9_]+__c\\b');
                                        Matcher m = p.matcher(field.equation);
                                        while (m.find()) {
                                            if (!ALL_FIELDS.contains(m.group().toLowerCase())) {
                                                ALL_FIELDS.add(m.group().toLowerCase());
                                            }
                                        }
                                    }
                                    this.GRID_FIELDS.add(field);
                                } else if (!field.fieldName.equals('')) {
                                    //List<String> fields = NegoptimHelper.normalizeAPIName(field.fieldName).split('\\.');
                                    List<String> fields = field.fieldName.split('\\.');
                                    /*List<String> normalizedFields = new List<String>();
                                     for (String f : fields) {
                                          normalizedFields.add(NegoptimHelper.normalizeAPIName(f));
                                     }*/
                                    Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.gridLayout.Object_Name__c, /*normalizedFields*/fields.clone());
                                    if (fieldResult != null) {
                                        DescribeFieldResult dfr = fieldResult.getDescribe();
                                        if (!dfr.isAccessible()) {
                                            this.WARNINGS.add(Label.MSG_No_Read_Access + ' "' + OBJECT_NAME + '.' + field.fieldName + '"');
                                            throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + OBJECT_NAME + '.' + field.fieldName + '"');
                                        } else {
                                            ////field.fieldLabel = NegoptimHelper.getReferenceFieldLabel(this.gridLayout.Object_Name__c, this.gridLayout.Object_Name__c, fields.clone());
                                            field.pickListValues = new List<SelectOption>();
                                            List<Schema.PicklistEntry> ple = dfr.getPicklistValues();
                                            for (Schema.PicklistEntry pickListVal : ple) {
                                                field.pickListValues.add(new SelectOption(pickListVal.value, pickListVal.label));
                                            }
                                            field.fieldLabel = dfr.getLabel();
                                            field.fieldType = dfr.getType();
                                            field.isCalculated = dfr.isCalculated();
                                            field.isEncrypted = dfr.isEncrypted();
                                            field.isFilterable = dfr.isFilterable();
                                            field.helpText = dfr.getInlinehelptext();
											FieldWrapper matchingField = fieldsMap.get(field.fieldName);
											field.scale = matchingField != null && matchingField.scale != null ? matchingField.scale : dfr.getScale();
                                            field.isAccessible = dfr.isAccessible();
                                            field.isCreateable = dfr.isCreateable();
                                            field.isUpdateable = dfr.isUpdateable();
                                            field.isHTMLFormatted = dfr.isHtmlFormatted();
                                            if (field.fieldType.name() == 'REFERENCE'/* && !field.fieldName.endsWithIgnoreCase('RecordTypeId')*/) {
                                                String referenceFieldName = field.fieldName;
                                                if (referenceFieldName.endsWithIgnoreCase('__c')) {
                                                    referenceFieldName = referenceFieldName.replace('__c', '__r.Name').toLowerCase();
                                                } else if(referenceFieldName.endsWithIgnoreCase('id')){
                                                    Integer lastIndexOfId = referenceFieldName.toLowerCase().lastIndexOf('id');
                                                    if (lastIndexOfId != -1) {
                                                        referenceFieldName = (referenceFieldName.subString(0, lastIndexOfId) + '.Name').toLowerCase();
                                                    }
                                                }
                                                if (!STATIC_FIELDS.containsIgnoreCase(referenceFieldName)) {
                                                    STATIC_FIELDS += (STATIC_FIELDS != '' ? ', ' : '')+referenceFieldName.toLowerCase();
                                                }
                                                if (!ALL_FIELDS.contains(referenceFieldName.toLowerCase())) {
                                                    ALL_FIELDS.add(referenceFieldName.toLowerCase().endsWith('recordtype.name') ? 'tolabel(' + referenceFieldName.toLowerCase() + ')' : referenceFieldName.toLowerCase());
                                                }
                                            }
                                            field.isReference = fields.size() > 1;
                                            if (field.fieldType == DisplayType.Picklist || field.fieldType == DisplayType.MultiPicklist) {
                                                field.controllerName = dfr.getController()?.getDescribe().getName();
                                                if (field.controllerName != null) {
                                                    if (!this.ALL_FIELDS.contains(field.controllerName.toLowerCase())) {
                                                        if (!field.isReference) {
                                                            this.ALL_FIELDS.add(field.controllerName.toLowerCase());
                                                        }
                                                    }
                                                }
                                                this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                                                for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                                                    this.picklistValuesMap.get(field.fieldName).put(pe.getValue(), pe.getLabel());
                                                }
                                            }
                                            if (field.fieldName.equalsIgnoreCase('RecordTypeId')) {
                                                this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                                                field.pickListValues = new List<SelectOption>();
                                                for (String recordtype : recordTypeIdMap.keySet()) {
                                                    field.pickListValues.add(new SelectOption(recordtype, recordTypeIdMap.get(recordtype)));
                                                    this.picklistValuesMap.get(field.fieldName).put(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype));
                                                }
                                            }
                                            // insert fields to query
                                            if (!this.ALL_FIELDS.contains(field.fieldName.toLowerCase())) {
                                                this.ALL_FIELDS.add(field.fieldName.toLowerCase() == 'recordtype.name' ? 'tolabel(' + field.fieldName.toLowerCase() + ')' : field.fieldName.toLowerCase());
                                            }
                                            // all fields that aren't updateable must be displayed as output
                                            if (this.isReadOnly || !dfr.isUpdateable() || !dfr.isCreateable() || field.isPersonalised || field.isReference || field.isCalculated) {
                                                field.isInputField = false;
                                            }
                                            this.GRID_FIELDS.add(field);
                                            if (field.isFilterable) {
                                                FilterSettings filterSetting = new FilterSettings(field);
                                                filterSetting.objectName = OBJECT_NAME;
                                                filtersMap.put(field.fieldName, filterSetting);
                                            }
                                        }
                                        if (String.isNotBlank(field.defaultExpression)) {
                                            String builder = '';
                                            Boolean hasOpen = false;
                                            Boolean hasExclamation = false;
                                            for (String character : field.defaultExpression.split('')) {
                                                if (character == '{') {
                                                    builder = '';
                                                    hasOpen = true;
                                                } else if (hasOpen && character == '!') {
                                                    hasExclamation = true;
                                                } else if (hasOpen && hasExclamation && character == '}') {
                                                    hasOpen = false;
                                                    hasExclamation = false;
                                                    if (String.isNotBlank(builder) && !builder.contains('.') && !this.ALL_FIELDS.contains(builder.toLowerCase())) {
                                                        List<String> expfields = builder.split('\\.');
                                                        String result = NegoptimHelper.addFieldPrefix(this.OBJECT_NAME, expfields.clone());
                                                        if (result != null && !this.ALL_FIELDS.contains(NegoptimHelper.normalizeAPIName(result).toLowerCase())) {
                                                            this.ALL_FIELDS.add(NegoptimHelper.normalizeAPIName(result).toLowerCase());
                                                        }
                                                        // this.ALL_FIELDS.add(builder.toLowerCase());
                                                    }
                                                    builder = '';
                                                } else if (hasOpen && hasExclamation && character != '!' && character != '{' && character != '}') {
                                                    builder += character;
                                                }
                                            }
                                        }
                                    } else {
                                        // throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + OBJECT_NAME + '.' + field.fieldName + '"');
                                        this.WARNINGS.add(Label.MSG_No_Read_Access + ' "' + OBJECT_NAME + '.' + field.fieldName + '"');
                                    }
                                }
                                if (field.conditionalRules != null) {
                                    for (ConditionalRule conditionalRule : field.conditionalRules) {
                                        if (conditionalRule.criteria?.rulesMap != null) {
                                            for (Rule rule : conditionalRule.criteria.rulesMap.values()) {
                                                if (String.isNotBlank(rule.fieldName)) {
                                                    //List<String> fields = NegoptimHelper.normalizeAPIName(rule.fieldName).split('\\.');
                                                    List<String> fields = rule.fieldName.split('\\.');
                                                    Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.OBJECT_NAME, fields.clone());
                                                    if (fieldResult != null) {
                                                        rule.fieldType = fieldResult.getDescribe().getType();
                                                        if (!this.ALL_FIELDS.contains(rule.fieldName.toLowerCase())) {
                                                            this.ALL_FIELDS.add(rule.fieldName.toLowerCase());
                                                        }
                                                    } else {
                                                        throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + OBJECT_NAME + '.' + rule.fieldName + '"');
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch (Exception ex) {
                                this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
                            }
                            previousField = field;
                        }
                        if (gridLayout.Type__c != 'Detail' && String.isNotBlank(this.Master_OBJECT_NAME) && String.isNotBlank(this.gridLayout.ReadOnly_Criteria__c)) {
                            readOnlyCriteria = (Criteria)JSON.deserialize(this.gridLayout.ReadOnly_Criteria__c, Criteria.class);
                            if (readOnlyCriteria?.rulesMap != null) {
                                for (Rule item : readOnlyCriteria.rulesMap.values()) {
                                    if (String.isNotBlank(item.fieldName)) {
                                        //List<String> fields = NegoptimHelper.normalizeAPIName(item.fieldName).split('\\.');
                                        List<String> fields = item.fieldName.split('\\.');
                                        Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.Master_OBJECT_NAME, fields.clone());
                                        if (fieldResult != null) {
                                            if (!this.ALL_BANNER_FIELDS.contains(item.fieldName.toLowerCase())) {
                                                this.ALL_BANNER_FIELDS.add(item.fieldName.toLowerCase());
                                            }
                                        } else {
                                            throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + Master_OBJECT_NAME + '.' + item.fieldName + '"');
                                        }
                                    }
                                }
                            }
                        }
                        if (String.isNotBlank(this.gridLayout.Filters__c) || (String.isNotBlank(filterJSON) && filterJSON != '[]')) {
                            if (!filtersMap.containsKey('RecordTypeId')) {
                                FieldWrapper field = new FieldWrapper('RecordTypeId', false);
                                field.fieldName = 'RecordTypeId';
                                List<String> fields = NegoptimHelper.normalizeAPIName('RecordTypeId').split('\\.');
                                Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.gridLayout.Object_Name__c, fields.clone());
                                if (fieldResult != null) {
                                    DescribeFieldResult dfr = fieldResult.getDescribe();
                                    if (dfr.isAccessible()) {
                                        field.pickListValues = new List<SelectOption>();
                                        field.fieldLabel = dfr.getLabel();
                                        for (String recordtype : recordTypeIdMap.keySet()) {
                                            field.pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                                        }
                                        FilterSettings filterSetting = new FilterSettings(field);
                                        filterSetting.objectName = OBJECT_NAME;
                                        filtersMap.put(field.fieldName, filterSetting);	
                                    }
                                }
                            }
							if(String.isNotBlank(this.gridLayout.Filters__c)){
								Object filtersd = JSON.deserializeUntyped(this.gridLayout.Filters__c);
								List<Object> filters = (List<Object>)filtersd;
								for (Object objt : filters) {
									Map<String, Object> item = (Map<String, Object>)objt;
									String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
									if (fieldName != null) {
										String fieldLabel = filtersMap.containsKey(fieldName) ? filtersMap.get(fieldName).fieldLabel : null;
										Boolean isEncrypted = filtersMap.containsKey(fieldName) ? filtersMap.get(fieldName).isEncrypted : null;
										String stringFieldType = fieldName.endsWithIgnoreCase('RecordTypeId') ? 'RECORDTYPE' : (filtersMap.containsKey(fieldName) ? filtersMap.get(fieldName).stringFieldType : null);
										List<SelectOption> filteredPickListValues = filtersMap.containsKey(fieldName) ? filtersMap.get(fieldName).pickListValues : null;
										List<SelectOption> pickListValues = new List<SelectOption>();
										String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : '';
										String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : '';
										List<String> values = new List<String>();
										if (item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
											List<Object> tempValues = (List<Object>) item.get('values');
											for (Object val : tempValues) {
												values.add(String.valueOf(val));
											}
										}
										Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
										if (stringFieldType != null) {
											if (filteredPickListValues != null && values != null && !values.isEmpty() && filtersMap.containsKey(fieldName)) {
												for(SelectOption option : /*filtersMap.get(fieldName).*/filteredPickListValues) {
													if(values.contains(option.value)) {
														pickListValues.add(option);
													}
												}
											} else {
												pickListValues = filtersMap.containsKey(fieldName) ? filtersMap.get(fieldName).pickListValues : null;
											}
											FilterSettings filterSetting = new FilterSettings(fieldName, fieldLabel, isEncrypted, stringFieldType, pickListValues, value1, value2, values, userFilterable);
											filterSetting.objectName = String.escapeSingleQuotes(OBJECT_NAME);
											this.FILTERS.add(filterSetting);
										}
									}
								}
							}
                            if (String.isNotBlank(filterJSON)) {
                                fillUserFilters(filterJSON);
                            }
                        }
                    }
                    if (this.GRID_FIELDS.isEmpty() && this.BANNER_FIELDS.isEmpty()) {
                        this.WARNINGS.add(System.Label.MSG_Template_Has_No_Fields);
                    }
                    if (!this.ALL_FIELDS.contains('CurrencyIsoCode'.toLowerCase())
						&& Schema.getGlobalDescribe().get(objectName) != null && Schema.getGlobalDescribe().get(objectName).newSObject().getSobjectType().getDescribe().fields.getMap().containsKey('CurrencyIsoCode'))
                    {
                        this.ALL_FIELDS.add('CurrencyIsoCode'.toLowerCase());
                    }
                    // this.FILTER_FIELDS = filtersMap.values();
                    /*} else {
						this.ERRORS.add(System.Label.MSG_Template_Not_Found);
					}*/
				} else {
					this.ERRORS.add(System.Label.MSG_Template_Not_Found);
				}
			} catch (Exception ex) {
				this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage() +' - ' + ex.getLineNumber() +' - ' + ex.getStackTraceString());
			}
		} else {
			GridSettingsManager gridSettingsManager;
            try {
				gridSettingsManager = (GridSettingsManager) JSON.deserialize(this.gridLayout.Compiled_Grid_JSON__c, GridSettingsManager.class);			
			} catch (Exception e) {
                System.debug('EX:::: ' + e.getmessage()+ '--' + e.getlinenumber());
            }
			System.debug('retrieve');
			this.OBJECT_NAME = gridSettingsManager.OBJECT_NAME;
			this.gridLayout = gridSettingsManager.gridLayout;
			this.readOnlyCriteria = gridSettingsManager.readOnlyCriteria;
			this.ALL_FIELDS = gridSettingsManager.ALL_FIELDS;
			this.SEARCHABLE_FIELDS = gridSettingsManager.SEARCHABLE_FIELDS;
			this.GRID_FIELDS = gridSettingsManager.GRID_FIELDS;
			// banner fields
			this.Master_OBJECT_NAME = gridSettingsManager.Master_OBJECT_NAME;
			this.ALL_BANNER_FIELDS = gridSettingsManager.ALL_BANNER_FIELDS;
			this.BANNER_FIELDS = gridSettingsManager.BANNER_FIELDS;	
            Schema.DescribeSObjectResult sObjectDescribe = Schema.getGlobalDescribe().get(this.OBJECT_NAME).getDescribe();
            Map<Id, String> recordTypeIdMap = getObjectRecordTypeMapLabels(Schema.getGlobalDescribe().get(this.gridLayout.Object_Name__c));
            Map<Id, String> recordTypeDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Schema.getGlobalDescribe().get(this.gridLayout.Object_Name__c));
            Set<String> gridFieldNames = new Set<String>();
            for (FieldWrapper field : this.GRID_FIELDS) {
                if(field.isFormula != null && field.isFormula) continue;
				if (String.isNotBlank(field.fieldName)) {
                    gridFieldNames.add(field.fieldName.toLowerCase());
                }
                List<String> fields = field.fieldName.split('\\.');
                Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.OBJECT_NAME, fields.clone());
				DescribeFieldResult dfr = fieldResult.getDescribe();
				field.fieldLabel = dfr.getLabel();
				field.helpText = dfr.getInlineHelpText();
				field.hasHelpText = String.isNotBlank(field.helpText);
				if (field.fieldType == DisplayType.Picklist || field.fieldType == DisplayType.MultiPicklist) {
					field.pickListValues = new List<SelectOption>();
					for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
						field.pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                        if (!this.picklistValuesMap.containsKey(field.fieldName)) {
                            this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                        }
                        this.picklistValuesMap.get(field.fieldName).put(pe.getValue(), pe.getLabel());
					}
                }
                
                if (field.fieldName.equalsIgnoreCase('RecordTypeId')) {
                    this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                    List<SelectOption> pickListValues = new List<SelectOption>();
                    for (String recordtype : recordTypeIdMap.keySet()) {
                        pickListValues.add(new SelectOption(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype)));
                        this.picklistValuesMap.get(field.fieldName).put(recordTypeDeveloperNameMap.get(recordtype), recordTypeIdMap.get(recordtype));
                    }
                    if (!pickListValues.isEmpty()) {
                        field.pickListValues = pickListValues;
                    }
                }
            }

            // Fill Banner Fields
            if (this.Master_OBJECT_NAME != null && this.gridLayout.Master_Object_Name__c != null && this.gridLayout.Master_Object_Columns__c != null && String.isNotBlank(this.gridLayout.Master_Object_Name__c) && String.isNotBlank(this.Master_OBJECT_NAME) && String.isNotBlank(this.gridLayout.Master_Object_Columns__c) && this.Master_OBJECT_NAME.equalsIgnoreCase(this.gridLayout.Master_Object_Name__c)) {
                Map<String, String> developerNameToLabelMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNameToLabel(Schema.getGlobalDescribe().get(this.gridLayout.Master_Object_Name__c));
                for (FieldWrapper field : this.BANNER_FIELDS) {
                    List<String> fields = field.fieldName.split('\\.');
                    Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.Master_OBJECT_NAME, fields.clone());
                    DescribeFieldResult dfr = fieldResult.getDescribe();
                    field.fieldLabel = dfr.getLabel();
                    field.helpText = dfr.getInlineHelpText();
					field.hasHelpText = String.isNotBlank(field.helpText);
                    if (field.fieldType == DisplayType.Picklist || field.fieldType == DisplayType.MultiPicklist) {
                        field.pickListValues = new List<SelectOption>();
                        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                            field.pickListValues.add(new SelectOption(pe.getValue(), pe.getLabel()));
                        }
                    }
                    if (field.fieldName.equalsIgnoreCase('RecordTypeId')) {
                        field.pickListValues = new List<SelectOption>();
                        for (String key : developerNameToLabelMap.keySet()) {
                            field.pickListValues.add(new SelectOption(key, developerNameToLabelMap.get(key)));
                        }
                    }
                }
            }
            this.FILTERS = gridSettingsManager.FILTERS;
            List<FilterSettings> keptFilters = new List<FilterSettings>();
			for (FilterSettings filterSetting : this.FILTERS) {
				if (loadAllFilters != true && !gridFieldNames.contains(filterSetting.fieldName.toLowerCase())) {
					continue;
				}
				Schema.SObjectField field = Schema.getGlobalDescribe().get(filterSetting.objectName).getDescribe().fields.getMap().get(filterSetting.fieldName);
				if (field != null) {
					filterSetting.fieldLabel = field.getDescribe().getLabel();
				}
				keptFilters.add(filterSetting);
			}
            this.FILTERS = keptFilters;
			this.FILTER_FIELDS = gridSettingsManager.FILTER_FIELDS;
			this.CALENDAR_SETTINGS = gridSettingsManager.CALENDAR_SETTINGS;
			this.TIME_LINE_SETTINGS = gridSettingsManager.TIME_LINE_SETTINGS;
			this.ERRORS = gridSettingsManager.ERRORS;
			this.WARNINGS = gridSettingsManager.WARNINGS;
			this.objectReferenceMap = gridSettingsManager.objectReferenceMap;
			this.isReadOnly = gridSettingsManager.isReadOnly;
			this.isShowFilterOnColumnHeader = gridSettingsManager.isShowFilterOnColumnHeader;
			this.Default_Page_Size = gridSettingsManager.Default_Page_Size;
			this.hierarchyParentField = gridSettingsManager.hierarchyParentField;
			this.groupedField = gridSettingsManager.groupedField;
			this.gridTypeValue = gridSettingsManager.gridTypeValue;
			this.importSettingsTemplate = gridSettingsManager.importSettingsTemplate;
			// load actions from Grid Configuration field because of flow label
            if (String.isNotBlank(this.gridLayout.Grid_Configuration__c)){
                GridConfigurationWrapper gridConfs = (GridConfigurationWrapper)JSON.deserialize(this.gridLayout.Grid_Configuration__c, GridConfigurationWrapper.class);
                if (gridConfs.actions != null) {
                    this.actions = gridConfs.actions;
                }
            }
			this.overrideFilter = gridSettingsManager.overrideFilter;
			this.Master_OBJECT_NAME = gridSettingsManager.Master_OBJECT_NAME;
			this.ALL_BANNER_FIELDS = gridSettingsManager.ALL_BANNER_FIELDS;
			this.BANNER_FIELDS = gridSettingsManager.BANNER_FIELDS;
			if (String.isNotBlank(safeMasterStaticFields)) {
				this.Master_OBJECT_STATIC_FIELDS = String.isNotBlank(this.Master_OBJECT_STATIC_FIELDS) ? this.Master_OBJECT_STATIC_FIELDS + ',' + safeMasterStaticFields : safeMasterStaticFields;
				for (String fieldname : safeMasterStaticFields.split(',')) {
					if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
						this.ALL_BANNER_FIELDS.add(fieldname.toLowerCase());
						continue;
					}
					if (fieldname != null && !this.ALL_BANNER_FIELDS.contains(fieldname.toLowerCase()) && !this.ALL_BANNER_FIELDS.contains(fieldname) && !this.ALL_BANNER_FIELDS.contains(('tolabel(' + fieldname + ')').toLowerCase())) {
						this.ALL_BANNER_FIELDS.add(fieldname.toLowerCase());
					}
				}
			}
			if (String.isNotBlank(safeStaticFields)) {
				this.STATIC_FIELDS = String.isNotBlank(this.STATIC_FIELDS) ? this.STATIC_FIELDS + ',' + safeStaticFields : safeStaticFields;
				for (String fieldname : safeStaticFields.split(',')) {
					if (fieldname.endsWithIgnoreCase('recordtype.developername')) {
						this.ALL_FIELDS.add(fieldname.toLowerCase());
						continue;
					}
					if (fieldname != null && !this.ALL_FIELDS.contains(fieldname.toLowerCase()) && !this.ALL_FIELDS.contains(fieldname) && !this.ALL_FIELDS.contains(('tolabel(' + fieldname + ')').toLowerCase())) {
						this.ALL_FIELDS.add(fieldname.toLowerCase());
					}
				}
			}
            
            if (String.isNotBlank(filterJSON)) {
                fillUserFilters(filterJSON);
            }
		}
        if (this.actions != null && this.actions.screenFlows != null && this.actions.screenFlows.size() > 0) {
            for (FlowOption flow : this.actions.screenFlows) {
                flow.label = NegoptimLabels.getCustomLabel(flow.label, flow.label);
            }
        }
		if (this.GRID_FIELDS != null && this.GRID_FIELDS.size() > 0) {
			for (FieldWrapper field : this.GRID_FIELDS) {
				if(field.isFormula != null && field.isFormula) {
					field.fieldLabel = NegoptimLabels.getCustomLabel(field.fieldLabel, field.fieldLabel);
				}
			}
		}
	}
    
    public void fillUserFilters(String filterJSON) {
        Object filtersd = JSON.deserializeUntyped(filterJSON);
        List<Object> filters = (List<Object>)filtersd;
        for (Object objt : filters) {
            Map<String, Object> item = (Map<String, Object>)objt;
            String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
            if (fieldName != null) {
                List<String> fields = fieldName.split('\\.');
                Schema.SObjectField fieldResult = NegoptimHelper.validateField(this.gridLayout.Object_Name__c, fields.clone());
                DescribeFieldResult dfr = fieldResult.getDescribe();
                String fieldLabel = dfr.getLabel();
                Boolean isEncrypted = dfr.isEncrypted();
                String stringFieldType = fieldName.endsWithIgnoreCase('RecordTypeId') ? 'RECORDTYPE' : String.valueOf(dfr.getType());
                String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                List<String> values = new List<String>();
                if (item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                    List<Object> tempValues = (List<Object>) item.get('values');
                    for (Object val : tempValues) {
                        values.add(String.valueOf(val));
                    }
                }
                Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                if (stringFieldType != null) {
                    FilterSettings filterSetting = new FilterSettings(fieldName, fieldLabel, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable);
                    filterSetting.objectName = String.escapeSingleQuotes(OBJECT_NAME);
                    this.USERFILTERS.add(filterSetting);
                }
            }
        }
    }
	public String iconName {
		get {
			if (this.gridLayout != null && this.gridLayout.Icon__c != null && this.gridLayout.Icon__c != '' && this.gridLayout.Icon__c.split(':').size() == 2) {
				return this.gridLayout.Icon__c.split(':')[1];
			}
			return 'orders';
		}
		set;
	}
	public String iconClass {
		get {
			if (String.isNotBlank(gridLayout?.Icon__c) && gridLayout.Icon__c.split(':').size() == 2) {
				return (gridLayout.Icon__c.split(':')[0].containsIgnoreCase('utility') ? 'slds-icon-text-default ' : '')+'slds-icon-' + gridLayout.Icon__c.split(':')[0]+'-' + gridLayout.Icon__c.split(':')[1].replaceAll('_', '-');
			}
			return 'slds-icon-standard-orders';
		}
		set;
	}
	public String iconSection {
		get {
			if (String.isNotBlank(gridLayout?.Icon__c) && gridLayout.Icon__c.split(':').size() == 2) {
				return gridLayout.Icon__c.split(':')[0];
			}
			return 'standard';
		}
		set;
	}
	public Boolean hasMaster {
		get {
			return String.isNotBlank(gridLayout?.Type__c) && gridLayout.Type__c != 'Master' && gridLayout.Type__c != 'Detail' && String.isNotBlank(gridLayout.Master_Object_Name__c);
		}
		set;
	}
	public String relationName {
		get {
            return hasMaster && String.isNotBlank(gridLayout?.Relationship_Name__c) ? gridLayout.Relationship_Name__c : null;
		}
	}
	/**
	 * @param innerQueries a list of String each string represents a well-constructed inner query(without the parantheses)
	 * @param whereClause a string of conditions for the query
	 * @param order BY a string of the order by clause (without ORDER BY)
	 * @return String a well constructed query
	 * @description builds a string query including the static fields and dynamic fields and the inner queries
	 */
	global String buildQuery(List<String> innerQueries, List<String> conditions, String orderBy) {
		List<String> userFilterConditions = new List<String>();
		List<String> adminFilters = new List<String>();
		List<String> allFilters = new List<String>();
		if (conditions == null) {
			conditions = new List<String>();
		}
		if (FILTERS!= null && !FILTERS.isEmpty()) {
			for (FilterSettings item : FILTERS) {
				try {
					adminFilters.addAll(item.getQueryConditions());
				} catch (Exception ex) {
					this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
					System.debug(System.Label.MSG_Error_Occured + ' :::::::::: ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
				}
			}
		}
		if (!adminFilters.isEmpty()) {
			allFilters.add('(' + String.join(adminFilters, ' AND ') + ')');
		}
		if (USERFILTERS!= null && !USERFILTERS.isEmpty()) {
			for (FilterSettings item : USERFILTERS) {
				try {
					userFilterConditions.addAll(item.getQueryConditions());
				} catch (Exception ex) {
					this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
					System.debug(System.Label.MSG_Error_Occured + ' :::::::::: ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
				}
			}
		}
		if (!userFilterConditions.isEmpty()) {
			allFilters.add('(' + String.join(userFilterConditions, ' AND ') + ')');
        }
        if (!allFilters.isEmpty()) {
            conditions.add('(' + String.join(allFilters, (this.overrideFilter ? ' OR ' : ' AND ')) + ')');
        }
		String query = 'SELECT ';
		query += !this.ALL_FIELDS.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(this.ALL_FIELDS), ',')) : 'Id';
		query += !this.ALL_FIELDS.isEmpty() && innerQueries != null && !innerQueries.isEmpty() ? ',' : '';
		query += (innerQueries != null && !innerQueries.isEmpty()) ? ' (' + String.join(innerQueries, '),(')+')' : '';
		query += ' FROM ' + String.escapeSingleQuotes(this.OBJECT_NAME);
		query += conditions != null && !conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')': '';
		//query += userFilterConditions != null && !userFilterConditions.isEmpty() ? ' OR (' + String.join(userFilterConditions, ' AND ') + ')' : '';
		orderBy = String.isNotBlank(orderBy) && orderBy.containsIgnoreCase('ORDER BY') ? orderBy.removeStart('').removeStartIgnoreCase('order by') : orderBy;
		query += String.isNotBlank(orderBy) ? ' ORDER BY ' + String.escapeSingleQuotes(orderBy) : '';
		query += ' LIMIT 10000';
		return query;
	}
    
    public String buildQueryWithUserFilters(List<String> innerQueries, List<String> conditions, String orderBy, String filters) {
        Map<String, String> filtersMap = String.isNotBlank(filters) ? (Map<String, String>) JSON.deserialize(filters, Map<String, String>.class) : new Map<String, String>();
        if (filtersMap.containsKey('dynamic') && filtersMap.get('dynamic') != '[]' && filtersMap.get('dynamic') != null && filtersMap.get('dynamic') != '') {
            String filterJSON = filtersMap.get('dynamic');
            fillUserFilters(filterJSON);
        }
		if (filtersMap.containsKey('searchTerm') && filtersMap.get('searchTerm') != '[]' && filtersMap.get('searchTerm') != null && filtersMap.get('searchTerm') != '') {
            String searchTerm = filtersMap.get('searchTerm');
			List<String> searchTermConditions = buildSearchTermConditions(searchTerm);
			if (!searchTermConditions.isEmpty()) {
				if (conditions == null) {
					conditions = new List<String>();
				}
				conditions.add('(' + String.join(searchTermConditions, ' OR ')+')');
			}
        }
        return buildQuery(innerQueries, conditions, orderBy);
    }
	public String buildBannerQuery(List<String> conditions) {
		String fields = String.escapeSingleQuotes(!this.ALL_BANNER_FIELDS.isEmpty() ? String.join(this.ALL_BANNER_FIELDS, ',') : 'id');
		String objName = String.escapeSingleQuotes(this.Master_OBJECT_NAME);
		if (!Pattern.matches('(?i)([\\w.]+|tolabel\\([\\w.]+\\))(,([\\w.]+|tolabel\\([\\w.]+\\)))*', fields) || !Pattern.matches('\\w+', objName)) {
			throw new IllegalArgumentException('Invalid query input');
		}
		String query = 'SELECT ' + fields + ' FROM ' + objName;
		query += conditions != null && !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
		return query + ' LIMIT 1';
	}
	public String buildCountQuery(List<String> conditions) {
		List<String> userFilterConditions = new List<String>();
		List<String> adminFilters = new List<String>();
		List<String> allFilters = new List<String>();
		if (conditions == null) {
			conditions = new List<String>();
		}
		if (!FILTERS.isEmpty()) {
			for (FilterSettings item : FILTERS) {
				adminFilters.addAll(item.getQueryConditions());
			}
		}
		if (!adminFilters.isEmpty()) {
			allFilters.add('(' + String.join(adminFilters, ' AND ') + ')');
		}
		if (!USERFILTERS.isEmpty()) {
			for (FilterSettings item : USERFILTERS) {
				userFilterConditions.addAll(item.getQueryConditions());
			}
		}
		if (!userFilterConditions.isEmpty()) {
			allFilters.add('(' + String.join(userFilterConditions, ' AND ') + ')');
		}
        if (!allFilters.isEmpty()) {
            conditions.add('(' + String.join(allFilters, (this.overrideFilter ? ' OR ' : ' AND ')) + ')');
        }
		String objName = String.escapeSingleQuotes(this.OBJECT_NAME);
		if (!Pattern.matches('\\w+', objName)) throw new IllegalArgumentException('Invalid object: ' + objName);
		String query = 'SELECT COUNT(Id) objectCount FROM ' + objName;
		return query + (!conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')' : '');
	}
	public String buildQuery(List<String> innerQueries, List<String> conditions, String orderBy, Integer pageSize, Integer offset) {
		List<String> userFilterConditions = new List<String>();
		List<String> adminFilters = new List<String>();
		List<String> allFilters = new List<String>();
		if (conditions == null) {
			conditions = new List<String>();
		}
		if (!FILTERS.isEmpty()) {
			for (FilterSettings item : FILTERS) {
				adminFilters.addAll(item.getQueryConditions());
			}
		}
		if (!adminFilters.isEmpty()) {
			allFilters.add('(' + String.join(adminFilters, ' AND ') + ')');
		}
		if (!USERFILTERS.isEmpty()) {
			for (FilterSettings item : USERFILTERS) {
				userFilterConditions.addAll(item.getQueryConditions());
			}
		}
		if (!userFilterConditions.isEmpty()) {
			allFilters.add('(' + String.join(userFilterConditions, ' AND ') + ')');
		}
        if (!allFilters.isEmpty()) {
			conditions.add('(' + String.join(allFilters, (this.overrideFilter ? ' OR ' : ' AND ')) + ')');
        }
		String fields = String.escapeSingleQuotes(!this.ALL_FIELDS.isEmpty() ? String.join(this.ALL_FIELDS, ',') : 'Id');
		String objName = String.escapeSingleQuotes(this.OBJECT_NAME);
		orderBy = String.isBlank(orderBy) ? '' : String.escapeSingleQuotes(orderBy.trim().removeStartIgnoreCase('order by').trim());
		if (!Pattern.matches('(?i)([\\w.]+|tolabel\\([\\w.]+\\))(,([\\w.]+|tolabel\\([\\w.]+\\)))*', fields) || !Pattern.matches('\\w+', objName)
			|| (orderBy != '' && !Pattern.matches('(?i)[\\w.]+(\\s+(ASC|DESC))?(\\s+NULLS\\s+(FIRST|LAST))?(\\s*,\\s*[\\w.]+(\\s+(ASC|DESC))?(\\s+NULLS\\s+(FIRST|LAST))?)*', orderBy))) {
			throw new IllegalArgumentException('Invalid query input');
		}
		String query = 'SELECT ' + fields;
		query += (innerQueries != null && !innerQueries.isEmpty()) ? ', (' + String.join(innerQueries, '),(') + ')' : '';
		query += ' FROM ' + objName;
		query += !conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')' : '';
		query += orderBy != '' ? ' ORDER BY ' + orderBy : '';
		query += pageSize != null ? ' LIMIT ' + pageSize : '';
		return query + (offset != null ? ' OFFSET ' + offset : '');
	}
	public String buildAggregateQuery(List<String> conditionList) {
		List<String> conditions = new List<String>();
		List<String> userFilterConditions = new List<String>();
		List<String> adminFilters = new List<String>();
		List<String> allFilters = new List<String>();
		conditions.addAll(conditionList);
		if (!FILTERS.isEmpty()) {
			for (FilterSettings item : FILTERS) {
				try {
					adminFilters.addAll(item.getQueryConditions());
				} catch (Exception ex) {
					this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
					System.debug(System.Label.MSG_Error_Occured + ' :::::::::: ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
				}
			}
		}
		if (!adminFilters.isEmpty()) {
			allFilters.add('(' + String.join(adminFilters, ' AND ') + ')');
		}
		if (!USERFILTERS.isEmpty()) {
			for (FilterSettings item : USERFILTERS) {
				try {
					userFilterConditions.addAll(item.getQueryConditions());
				} catch (Exception ex) {
					this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
					System.debug(System.Label.MSG_Error_Occured + ' :::::::::: ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
				}
			}
		}
		if (!userFilterConditions.isEmpty()) {
			allFilters.add('(' + String.join(userFilterConditions, ' AND ') + ')');
		}
        if (!allFilters.isEmpty()) {
			conditions.add('(' + String.join(allFilters, (this.overrideFilter ? ' OR ' : ' AND ')) + ')');
        }
		String query = '';
		List<String> totalsFields = new List<String>();
		for (FieldWrapper fieldWrap : this.GRID_FIELDS) {
			if (fieldWrap.showInTotal && fieldWrap.isNumberField) {
				String fn = String.escapeSingleQuotes(fieldWrap.fieldName), tt = String.escapeSingleQuotes(fieldWrap.totalType);
				if (!Pattern.matches('[\\w.]+', fn) || !Pattern.matches('(?i)SUM|AVG|MIN|MAX|COUNT|COUNT_DISTINCT', tt)) {
					throw new IllegalArgumentException('Invalid total field: ' + fn);
				}
				totalsFields.add(tt + '(' + fn + ') ' + fn);
			}
		}
		String objName = String.escapeSingleQuotes(this.OBJECT_NAME);
		if (!totalsFields.isEmpty()) {
			if (!Pattern.matches('\\w+', objName)) throw new IllegalArgumentException('Invalid object: ' + objName);
			query = 'SELECT ' + String.join(totalsFields, ',') + ' FROM ' + objName;
			query += !conditions.isEmpty() ? ' WHERE (' + String.join(conditions, ' AND ') + ')' : '';
		}
		return query;
	}
	public List<String> buildSearchTermConditions(String searchTerm) {
		List<String> conditions = new List<String>();
		if (searchTerm != null && String.isNotBlank(searchTerm)) {
			String escapedSearctTerm = String.escapeSingleQuotes(searchTerm);
			for (FieldWrapper item : GRID_FIELDS) {
				if (item.isSearchable) {
					if (!Pattern.matches('[\\w.]+', String.escapeSingleQuotes(item.fieldName))) continue;
					if (item.fieldType != DisplayType.Multipicklist) {
						if (item.fieldType == DisplayType.Reference) {
							String refFieldName = (item.fieldName.endsWithIgnoreCase('__c') ? item.fieldName.replace('__c', '__r') : item.fieldName.replace('Id', '').replace('id', '')) + '.Name ';
							conditions.add(' ' + refFieldName + ' LIKE \'%' + escapedSearctTerm + '%\' ');
						} else {
							conditions.add(' ' + item.fieldName + ' LIKE \'%' + escapedSearctTerm + '%\' ');
						}
					} else {
						conditions.add(' ' + item.fieldName + ' INCLUDES (\'' + escapedSearctTerm + '\') ');
					}
				}
			}
		}
		return conditions;
	}
	global void refreshGridFieldBaseOnReadOnlyCriteria(SObject obj) {
		try {
			if (this.gridLayout != null && this.gridLayout.Type__c != 'Detail' && String.isNotBlank(this.Master_OBJECT_NAME) && String.isNotBlank(this.gridLayout.ReadOnly_Criteria__c)) {
				if (this.GRID_FIELDS != null && !this.GRID_FIELDS.isEmpty()) {
					if (this.readOnlyCriteria != null && this.readOnlyCriteria.evaluate(Master_OBJECT_NAME, obj)) {
						for (FieldWrapper item : this.GRID_FIELDS) {
							item.isInputField = false;
						}
						this.isReadOnly = true;
					}
				}
			}
		} catch(Exception ex) {
			this.ERRORS.add(System.Label.MSG_Error_Occured + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber());
			System.debug(System.Label.MSG_Error_Occured + ' >>>> ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
		}
	}
	public class FieldWrapper {
        public FieldWrapper(){}
		//++++
		public Boolean isPersonalised {
			get {
				return isPersonalised != null && isPersonalised;
			}
			set;
		}
		public String controllerName { get; set; }
		public List<String> controlledByFields { get; set; }
		public List<ConditionalRule> conditionalRules { get; set; }
		public Map<String, String> picklistColorsMap { get; set; }
		public Boolean hasFileInput { get; set; }
		public Boolean displayFullURL { get; set; }
		public String URLOption { get; set; }
		public String newLabel {get; set;}
		public String replaceURLWith { get; set; }
		public String fieldName { get; set; }
		public String fieldLabel {
			get {
				return String.isNotBlank(newLabel) ? NegoptimLabels.getCustomLabel(newLabel, newLabel) : fieldLabel;
			}
			set;
		}
		public Boolean hasHelpText { get { return helpText != null && !String.isBlank(helpText); } set; }
		public String helpText { get; set; }
		// qa2 dep
		public String borderColor { get; set; }
        public String defaultType { get; set; }
        public String defaultValue { get; set; }
        public String defaultExpression { get; set; }
        public Boolean isHidden { get; set; }
        public Boolean isNotExportable { get; set; }
		public Boolean clearOnClone { get; set; }
		public Boolean isSortable { get; set; }
		public Boolean isFormula { get; set; }
		public String equation {get; set;}
		public Boolean isMassUpdate { get; set; }
		public Boolean isDefaultSortable { get; set; }
		public String defaultSortDirection { get; set; }
		// qa2 dep
        public String bgColor { get {return bgColor != null && bgColor != '' ? bgColor : '#FFFFFF';} set; }
		public List<SelectOption> pickListValues { get; set; }
		public String style {
			get {
				String styleString = '';
				if (!hasConditionalFormating) {
					styleString += nonConditional != null ? nonConditional.style : '';
				}
				styleString += separatorSettings != null ? separatorSettings.style : '';
				// return styleString;
				return styleString != '' ? styleString + ' ' + widthStyle : widthStyle ;
			}
			set;
		}
		public String widthStyle {
			get {
                String maxwidth = '';
                if (isInputField) {
                    if (isNumberField) {
                        maxwidth = 'min-width: 85px; max-width: 85px; width: 85px;';
                    } else if (stringFieldType == 'PICKLIST'){
                        if (pickListValues != null && !pickListValues.isEmpty()){
                            Integer maxPicklistLabelSize = 0;
                            for (SelectOption so : pickListValues) {
                                if (so.label.length() > maxPicklistLabelSize) {
                                    maxPicklistLabelSize = so.label.length();
                                }
                            }
                            Integer width = maxPicklistLabelSize * 8 + 80;
                            maxwidth = 'min-width: ' + width + 'px; max-width: ' + width + 'px; width: ' + width + 'px;';
                        }
                    } else if (stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'DATE' || stringFieldType == 'DATETIME' || stringFieldType == 'TIME'){
                        maxwidth = '';
                    } else if (stringFieldType != 'REFERENCE'){
                        maxwidth = 'min-width: 200px; max-width: 200px; width: 200px;';
                    }
                }
				return nonConditional != null && String.isNotBlank(nonConditional.widthStyle) ? nonConditional.widthStyle : maxwidth;
			}
			set;
		}
		public String nonConditionalStyle {
			get {
				return nonConditional != null ? nonConditional.style : '';
			}
			set;
		}
		public String getStyleDynamicJS(String fieldValue) {
			String styleString = '';
			if (hasConditionalFormating) {
				String content = getStyleContentJS(fieldValue);
				if (!String.isBlank(content)) {
					styleString += content;
				}
			} else {
				styleString += nonConditional != null ? ' style += `' + nonConditional.style + '`;' : '';
			}
			styleString += separatorSettings != null ? ' style += `' + separatorSettings.style + '`;' : '';
			return styleString;
		}
		public String getStyleDynamicTable(String fieldValue) {
			String styleString = '';
			if (hasConditionalFormating) {
				String content = getStyleContentVF(fieldValue);
				if (!String.isBlank(content)) {
					styleString += '{!' + content + '}';
				}
			} else {
				styleString += nonConditional != null ? '{!\'' + nonConditional.style + '\'}' : '';
			}
			styleString += separatorSettings != null ? '{!\'' + separatorSettings.style + '\'}' : '';
			return styleString;
		}
		public Boolean showInTotal {
			get {
				return showInTotal != null && showInTotal;
			}
			set;
		}
		public Boolean internallyCalculated {
			get {
				return internallyCalculated != null && internallyCalculated;
			}
			set;
		}
		public String totalType {
			get {
				if (totalType == null && this.showInTotal) {
                    return this.fieldType == DisplayType.Boolean ? GridSettingsManager.COUNT : GridSettingsManager.SUM;
				} else {
					return totalType;
				}
			}
			set;
		}
		public StyleSettings nonConditional { get; set; }
		public HeaderStyleSettings headerStyle { get; set; }
        public String stringHeaderStyle { get {
            String style = '';
            style += headerStyle != null ? headerStyle.style : '';
            style += separatorSettings != null ? separatorSettings.style : '';
            // return styleString;
            return style;
        } set; }
		// public String customJS { get; set; }
		public Boolean hasConditionalFormating {
			get {
				return hasConditionalFormating != null && hasConditionalFormating;
			}
			set;
		}
		public List<FormattingRules> formattingRulesList { get; set; }
		public Schema.DisplayType fieldType { get; set; }
		public String stringFieldType {
			get {
				return stringFieldType != null ? stringFieldType : String.valueOf(fieldType);
			}
			set;
		}
		public String action { get; set; }
		public String rerender { get; set; }
		public Boolean isSortableType {
			get {
				return fieldType == DisplayType.Date || fieldType == DisplayType.Time || fieldType == DisplayType.DateTime || fieldType == DisplayType.Double || fieldType == DisplayType.Integer || fieldType == DisplayType.Long || fieldType == DisplayType.Percent || fieldType == DisplayType.Currency || fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist || fieldType == DisplayType.String;
			}
			set;
		}
		public Boolean isReference { get; set; }
		public Boolean isAccessible { get; set; }
		public Boolean isCreateable { get; set; }
		public Boolean isUpdateable { get; set; }
		public Boolean isCustom {
			get {
				return fieldName.endsWithIgnoreCase('__c');
			}
			set;
		}
		public Boolean isInputField {
			get {
				return isInputField != null && isInputField;
			}
			set;
		}
		// public Criteria isInputFieldCriteria { get; set; }
		public Boolean isCalculated { get; set; }
		public Boolean isEncrypted { get; set; }
		public Boolean isFilterable { get; set; }
		public Boolean isSearchable {
			get {
				// return isSearchable != null ? isSearchable : isFilterable == true && !(isCalculated == true) && (fieldType == DisplayType.String || fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist);
				return isSearchable != null ? isSearchable : isFilterable == true && (fieldType == DisplayType.String || fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist || fieldType == DisplayType.Reference);
			}
			set;
		}
		public Boolean isHTMLFormatted { get; set; }
		public Boolean isRichText {
			get {
				return	fieldType == Schema.DisplayType.TEXTAREA && isHTMLFormatted == true;
			}
			set;
		}
		public Boolean isBorderColumn { get; set; }
		public SeparatorSettings separatorSettings { get; set; }
		public Integer scale { get; set; }
		public Boolean isNumberField {
			get {
				return fieldType == DisplayType.Double || fieldType == DisplayType.Integer || fieldType == DisplayType.Long || fieldType == DisplayType.Percent || fieldType == DisplayType.Currency;
			}
			set;
		}
		public FieldWrapper(String fieldName, Boolean isInputField) {
			this.fieldName = fieldName;
			this.isInputField = isInputField;
		}
		/**
		 * @param var represents the name of the variable used while iterating grid fields. example: item
		 */
		public String getStyle(String var) {
			if (hasConditionalFormating) {
				List<String> conditions = new List<String>();
				for (FormattingRules rule : formattingRulesList) {
					conditions.add(rule.getstyleExpression(var, fieldName, fieldType));
				}
				return String.JOIN(conditions, ' ');
			} else {
				return nonConditional != null ? nonConditional.style : '';
			}
		}
		/**
		 * @param var represents the name of the variable used while iterating grid fields. example: item
		 */
		public String getStyleContentVF(String var) {
			if (hasConditionalFormating && formattingRulesList != null) {
				List<String> conditions = new List<String>();
				for (FormattingRules rule : formattingRulesList) {
					conditions.add(rule.getStyleExpressionContentVF(var, fieldName, fieldType));
				}
				return String.JOIN(conditions, '} {!');
			} else {
				return '';
			}
		}
		/**
		 * @param var represents the name of the variable used while iterating grid fields. example: item
		 */
		public String getStyleContentJS(String var) {
			if (hasConditionalFormating && formattingRulesList != null) {
				List<String> conditions = new List<String>();
				for (FormattingRules rule : formattingRulesList) {
					conditions.add(rule.getStyleExpressionContentJS(var, fieldName, fieldType));
				}
				return String.JOIN(conditions, ' ');
			} else {
				return '';
			}
		}
	}
	class Expression{
		String exp;
		Boolean isDone;
		List<Expression> childExpressions;
		public Expression(){
			this.exp = '';
			this.isDone = false;
			this.childExpressions = new List<Expression> ();
		}
		public Expression(String exp){
			this.exp = exp;
			this.isDone = false;
			this.childExpressions = new List<Expression> ();
		}
		public void addExp(Expression exp){
			if (!childExpressions.contains(exp)) {
				childExpressions.add(exp);
			}
		}
		public void append(String exp){
			this.exp += ' ' + exp;
		}
		public Boolean eval(){
			String evalExp = this.exp;
			for (Expression expChild : childExpressions) {
				Boolean childResult = expChild.eval();
				evalExp = evalExp.replace(expChild.exp, String.valueOf(childResult));
			}
			evalExp = evalExp.subString(1,evalExp.length() -1);
			Boolean resultOr = false;
			for (String subExpOr : evalExp.split('(?i) OR')) {
				Boolean resultAnd = true;
				for (String subExpAnd : subExpOr.split('(?i) AND')) {
					resultAnd &= Boolean.valueOf(subExpAnd.trim());
				}
				resultOr |= resultAnd;
			}
			return resultOr;
		}
	}
	class SyntaxException extends Exception{
	}
	public class Criteria {
		public String objectName { get; set; }
		public SObject obj { get; set; }
		public String expression { get; set; }
		public Map<Integer, Rule> rulesMap { get; set; }
		public Map<Integer, Boolean> getEvaluatedRulesMap(String objectName, SObject obj) {
			Map<Integer, Boolean> evalMap = new Map<Integer, Boolean>();
			if (rulesMap != null) {
				for (Integer ruleIndex : rulesMap.keySet()) {
					Rule rule = rulesMap.get(ruleIndex);
					if (String.isNotBlank(rule.fieldName)) {
						List<String> fields = NegoptimHelper.normalizeAPIName(rule.fieldName).split('\\.');
						Schema.SObjectField fieldResult = NegoptimHelper.validateField(objectName, fields.clone());
						if (fieldResult != null) {
							evalMap.put(ruleIndex, rule.evaluate(fieldResult.getDescribe().getType(), obj));
						} else {
							throw new NegoptimHelper.NoAccessException(Label.MSG_No_Read_Access + ' "' + objectName + '.' + rule.fieldName + '"');
						}
					}
				}
			}
			return evalMap;
		}
		public Boolean evaluate {
			get {
				return String.isNotBlank(this.objectName) && this.obj != null ? evaluate(this.objectName, this.obj) : false;
			}
			set;
		}
		public Boolean evaluate(String objectName, SObject obj) {
			if (String.isBlank(this.expression)) {
				if (rulesMap != null) {
					List<String> rulesIndexs = new List<String>();
					for (Integer ruleIndex : rulesMap.keySet()) {
						rulesIndexs.add(String.valueOf(ruleIndex));
					}
					this.expression = String.join(rulesIndexs, ' AND ');
				}
			}
			Boolean result = false;
			if (String.isNotBlank(this.expression)) {
				result |= evalExpression(this.expression, getEvaluatedRulesMap(objectName, obj));
			}
			return result;
		}
		public Boolean evalExpression(String value, Map<Integer, Boolean> valuesMap){
			value = '(' + value + ')';
			Map<Integer, List<Expression>> expressionLevelsMap = new Map<Integer, List<Expression>>();
			String CHARS_TO_MATCH = '(?i) AND|OR|[0-9]+|[\\(]|[\\)]';
			Pattern p = Pattern.compile(CHARS_TO_MATCH);
			Matcher matcher = p.matcher(value);
			String discardCharsValue = value;
			List<String> splitedP = new List<String>();
			Integer level = 0;
			Integer maxLevel = 0;
			while (matcher.find()){
				String s = matcher.group(0);
				if (s == '('){
					level++;
					if (maxLevel < level){
						maxLevel = level;
					}
					splitedP.add(s);
				}
				for (Integer index = 0; index <= level; index++){
					if (!expressionLevelsMap.containsKey(index)){
						expressionLevelsMap.put(index, new List<Expression>());
					}
					Boolean added = false;
					for (Expression exp : expressionLevelsMap.get(index)){
						if (!exp.isDone){
							if (s.isNumeric()) {
								Integer ruleIndex = Integer.valueOf(s);
								if (valuesMap.containsKey(ruleIndex)) {
									exp.append(String.valueOf(valuesMap.get(ruleIndex)));
								} else {
									throw new SyntaxException('Rule ' + ruleIndex + ' not defined');
								}
							} else {
								exp.append(s);
							}
							added = true;
							if (index == level && s == ')'){
								exp.isDone = true;
							}
						}
					}
					if (!added){
						Expression exp = new Expression(s);
						expressionLevelsMap.get(index).add(exp);
						if (expressionLevelsMap.containsKey(index-1)) {
							for (Expression parentExp : expressionLevelsMap.get(index - 1)) {
								if (!parentExp.isDone) {
									parentExp.addExp(exp);
								}
							}
						}
					}
				}
				if (s == ')'){
					if (!splitedP.isEmpty() && splitedP.get(splitedP.size()-1) == '('){
						splitedP.remove(splitedP.size()-1);
						level--;
					} else{
						throw new SyntaxException('using ) without (');
					}
				}
				if (s == ')' || s == '(') {
					discardCharsValue = discardCharsValue.replaceAll('\\' + s, '');
				} else {
					discardCharsValue = discardCharsValue.replaceAll(s, '');
				}
			}
			discardCharsValue = discardCharsValue.trim();
			if (discardCharsValue.length() != 0){
				throw new SyntaxException('unrecognized symbol ' + discardCharsValue.split(' ')[0]);
			}
			if (!splitedP.isEmpty()){
				throw new SyntaxException('using ( without )');
			}
			return expressionLevelsMap.get(1).get(0).eval();
		}
	}
	public class Rule {
		public String fieldName { get; set; }
		public String operation { get; set; }
		public String value { get; set; }
		public Schema.DisplayType fieldType { get; set; }
		public Boolean evaluate(Schema.DisplayType fieldType, SObject obj) {
			if (operation.equals(GridSettingsManager.ISNULL)) {
				return obj.get(fieldName) == null;
			}
			if (operation.equals(GridSettingsManager.ISBLANK)) {
				return String.isBlank(String.valueOf(obj.get(fieldName)));
			}
			if (fieldType == DisplayType.Boolean) {
				if (String.isBlank(value)) {
					value = 'false';
				}
				if (operation.equals(GridSettingsManager.EQUALS)) {
					return (Boolean)obj.get(fieldName) == Boolean.valueOf(value);
				} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
					return (Boolean)obj.get(fieldName) != Boolean.valueOf(value);
				}
			} else if (fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist || fieldType == DisplayType.String || fieldType == DisplayType.Reference) {
				if (operation.equals(GridSettingsManager.CONTAINS)) {
					return ((String)(obj.get(fieldName))).contains(value);
				} else if (operation.equals(GridSettingsManager.NOT_CONTAINS)) {
					return !((String)(obj.get(fieldName))).contains(value);
				} else if (operation.equals(GridSettingsManager.EQUALS)) {
					return obj.get(fieldName) == value;
				} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
					return obj.get(fieldName) != value;
				}
			} else if (fieldType == DisplayType.CURRENCY || fieldType == DisplayType.INTEGER || fieldType == DisplayType.DOUBLE || fieldType == DisplayType.LONG) {
				if (operation.equals(GridSettingsManager.GREATER)) {
					return (Decimal)(obj.get(fieldName)) > Decimal.valueOf(value);
				} else if (operation.equals(GridSettingsManager.GREATER_OR_EQUALS)) {
					return (Decimal)(obj.get(fieldName)) >= Decimal.valueOf(value);
				} else if (operation.equals(GridSettingsManager.LESS)) {
					return (Decimal)(obj.get(fieldName)) < Decimal.valueOf(value);
				} else if (operation.equals(GridSettingsManager.LESS_OR_EQUALS)) {
					return (Decimal)(obj.get(fieldName)) <= Decimal.valueOf(value);
				} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
					return (Decimal)(obj.get(fieldName)) != Decimal.valueOf(value);
				} else if (operation.equals(GridSettingsManager.EQUALS)) {
					return (Decimal)(obj.get(fieldName)) == Decimal.valueOf(value);
				}
			} else if (fieldType == DisplayType.DATETIME) {
				if (String.isNotBlank(value)) {
					String SPECIAL_CHAR_PATTERN = '[0-9]+';
					Pattern p = Pattern.compile(SPECIAL_CHAR_PATTERN);
					Matcher matcher = p.matcher(value);
					List<String> splitedDate = new List<String>();
					while (matcher.find()) {
						splitedDate.add(matcher.group(0));
					}
					Datetime valueDateTime = Datetime.newInstanceGmt(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]), Integer.valueOf(splitedDate[3]), Integer.valueOf(splitedDate[4]), Integer.valueOf(splitedDate[5]));
					if (operation.equals(GridSettingsManager.GREATER)) {
						return (Datetime)(obj.get(fieldName)) > valueDateTime;
					} else if (operation.equals(GridSettingsManager.GREATER_OR_EQUALS)) {
						return (Datetime)(obj.get(fieldName)) >= valueDateTime;
					} else if (operation.equals(GridSettingsManager.LESS)) {
						return (Datetime)(obj.get(fieldName)) < valueDateTime;
					} else if (operation.equals(GridSettingsManager.LESS_OR_EQUALS)) {
						return (Datetime)(obj.get(fieldName)) <= valueDateTime;
					} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
						return (Datetime)(obj.get(fieldName)) != valueDateTime;
					} else if (operation.equals(GridSettingsManager.EQUALS)) {
						return (Datetime)(obj.get(fieldName)) == valueDateTime;
					}
				}
			} else if (fieldType == DisplayType.DATE) {
				if (String.isNotBlank(value)) {
					String SPECIAL_CHAR_PATTERN = '[0-9]+';
					Pattern p = Pattern.compile(SPECIAL_CHAR_PATTERN);
					Matcher matcher = p.matcher(value);
					List<String> splitedDate = new List<String>();
					while (matcher.find()) {
						splitedDate.add(matcher.group(0));
					}
					Date valueDate = Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]));
					if (operation.equals(GridSettingsManager.GREATER)) {
						return (Date)(obj.get(fieldName)) > valueDate;
					} else if (operation.equals(GridSettingsManager.GREATER_OR_EQUALS)) {
						return (Date)(obj.get(fieldName)) >= valueDate;
					} else if (operation.equals(GridSettingsManager.LESS)) {
						return (Date)(obj.get(fieldName)) < valueDate;
					} else if (operation.equals(GridSettingsManager.LESS_OR_EQUALS)) {
						return (Date)(obj.get(fieldName)) <= valueDate;
					} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
						return (Date)(obj.get(fieldName)) != valueDate;
					} else if (operation.equals(GridSettingsManager.EQUALS)) {
						return (Date)(obj.get(fieldName)) == valueDate;
					}
				}
			} else if (fieldType == DisplayType.TIME) {
				if (String.isNotBlank(value)) {
					String SPECIAL_CHAR_PATTERN = '[0-9]+';
					Pattern p = Pattern.compile(SPECIAL_CHAR_PATTERN);
					Matcher matcher = p.matcher(value);
					List<String> splitedDate = new List<String>();
					while (matcher.find()) {
						splitedDate.add(matcher.group(0));
					}
					Time valueTime = Time.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]), Integer.valueOf(splitedDate[3]));
					if (operation.equals(GridSettingsManager.GREATER)) {
						return (Time)(obj.get(fieldName)) > valueTime;
					} else if (operation.equals(GridSettingsManager.GREATER_OR_EQUALS)) {
						return (Time)(obj.get(fieldName)) >= valueTime;
					} else if (operation.equals(GridSettingsManager.LESS)) {
						return (Time)(obj.get(fieldName)) < valueTime;
					} else if (operation.equals(GridSettingsManager.LESS_OR_EQUALS)) {
						return (Time)(obj.get(fieldName)) <= valueTime;
					} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
						return (Time)(obj.get(fieldName)) != valueTime;
					} else if (operation.equals(GridSettingsManager.EQUALS)) {
						return (Time)(obj.get(fieldName)) == valueTime;
					}
				}
			}
			return false;
		}
	}
	/**
     * Get Object RecordType Map of Id/Translated Name based on profile accessibility
     * @param sObjectType
     * */
    public Map<Id, String> getObjectRecordTypeMapLabels(SObjectType sObjectType) {
        Map<Id, String> rtMap = new Map<Id, String>();
        Schema.DescribeSObjectResult R = SObjectType.getDescribe(SObjectDescribeOptions.FULL);
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
			if (RT.isAvailable() && RT.getName() != 'Master') {
				rtMap.put(RT.getRecordTypeId(), RT.getName());
			}
        }
        return rtMap;
    }
	public class FormattingRules {
		public String operation { get; set; }
		public String value1 { get; set; }
		public String value2 { get; set; }
		public StyleSettings style { get; set; }
		public StyleSettings oppositeStyle { get; set; }
		public String getStyleExpression(String var, String fieldName, DisplayType fieldType) {
			String field = var + '.' + fieldName;
			String condition = '';
			if (fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist || fieldType == DisplayType.String || fieldType == DisplayType.Reference) {
				if (operation.equals(GridSettingsManager.ISNULL)) {
					condition = '{!if (ISNULL(' + field + '),"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				} else if (operation.equals(GridSettingsManager.ISBLANK)) {
					condition = '{!if (ISBLANK(' + field + '),"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				} else if ((operation.equals(GridSettingsManager.CONTAINS) || operation.equals(GridSettingsManager.NOT_CONTAINS))) {
					condition = '{!';
					condition += operation.equals(GridSettingsManager.NOT_CONTAINS) ? '!' : '';
					condition += 'if (CONTAINS(' + field + ', "' + value1 + '"), "' + (style != null ? style.style : '')+'", "' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				} else if (operation.equals(GridSettingsManager.EQUALS) || operation.equals(GridSettingsManager.NOT_EQUALS)) {
					condition = '{!if (' + field + ' ' + GridSettingsManager.operations.get(operation)+' "' + value1 + '", "' + (style != null ? style.style : '')+'", "' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				}
			} else {
				String str2 = field + '==null';
				String str3 = field + '!=null';
				if (operation.equals(GridSettingsManager.BETWEEN)) {
					String str1 = field + '>' + value1 + ',' + field + '<' + value2;
					if (0 > Decimal.valueOf(value1) && 0 < Decimal.valueOf(value1)) {
						condition = 'OR(' + str2 + 'AND(' + str1 + '))';
					} else {
						condition = 'AND(' + str3 + ',' + str1 + ')';
					}
					condition = '{!if (' + condition + ',"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				} else {
					String str1 = field + ' ' + GridSettingsManager.operations.get(operation)+' ' + value1;
					if ((operation.equals(GridSettingsManager.GREATER) && 0 > Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.GREATER_OR_EQUALS) && 0 >= Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.LESS) && 0 < Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.LESS_OR_EQUALS) && 0 <= Decimal.valueOf(value1))) {
						condition = 'OR(' + str2 + ',' + str1 + ')';
					} else {
						condition = 'AND(' + str3 + ',' + str1 + ')';
					}
					condition = '{!if (' + condition + ',"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")}';
				}
			}
			return condition;
		}
		public String getStyleExpressionContentVF(String var, String fieldName, DisplayType fieldType) {
			String field = var + '.' + fieldName;
			String condition = '';
			if (fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist || fieldType == DisplayType.String || fieldType == DisplayType.Reference) {
				if (operation.equals(GridSettingsManager.ISNULL)) {
					condition = 'if (ISNULL(' + field + '),"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				} else if (operation.equals(GridSettingsManager.ISBLANK)) {
					condition = 'if (ISBLANK(' + field + '),"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				} else if ((operation.equals(GridSettingsManager.CONTAINS) || operation.equals(GridSettingsManager.NOT_CONTAINS))) {
					condition = '';
					condition += operation.equals(GridSettingsManager.NOT_CONTAINS) ? '!' : '';
					condition += 'if (CONTAINS(' + field + ', "' + value1 + '"), "' + (style != null ? style.style : '')+'", "' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				} else if (operation.equals(GridSettingsManager.EQUALS) || operation.equals(GridSettingsManager.NOT_EQUALS)) {
					condition = 'if (' + field + ' ' + GridSettingsManager.operations.get(operation)+' "' + value1 + '", "' + (style != null ? style.style : '')+'", "' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				}
			} else {
				String str2 = field + '==null';
				String str3 = field + '!=null';
				if (operation.equals(GridSettingsManager.BETWEEN)) {
					String str1 = field + '>' + value1 + ',' + field + '<' + value2;
					if (0 > Decimal.valueOf(value1) && 0 < Decimal.valueOf(value1)) {
						condition = 'OR(' + str2 + 'AND(' + str1 + '))';
					} else {
						condition = 'AND(' + str3 + ',' + str1 + ')';
					}
					condition = 'if (' + condition + ',"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				} else {
					String str1 = field + ' ' + GridSettingsManager.operations.get(operation)+' ' + value1;
					if ((operation.equals(GridSettingsManager.GREATER) && 0 > Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.GREATER_OR_EQUALS) && 0 >= Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.LESS) && 0 < Decimal.valueOf(value1)) || (operation.equals(GridSettingsManager.LESS_OR_EQUALS) && 0 <= Decimal.valueOf(value1))) {
						condition = 'OR(' + str2 + ',' + str1 + ')';
					} else {
						condition = 'AND(' + str3 + ',' + str1 + ')';
					}
					condition = 'if (' + condition + ',"' + (style != null ? style.style : '')+'","' + (oppositeStyle != null ? oppositeStyle.style : '')+';")';
				}
			}
			return condition;
		}
		public String getStyleExpressionContentJS(String var, String fieldName, DisplayType fieldType) {
			String condition = '';
			String str1 = '';
			if (fieldName.endsWith('RecordTypeId')) {
				if (operation.equals(GridSettingsManager.ISNULL)) {
					str1 = '!' + var;
				} else if (operation.equals(GridSettingsManager.ISBLANK)) {
					str1 = '!' + var;
				} else if ((operation.equals(GridSettingsManager.CONTAINS) || operation.equals(GridSettingsManager.NOT_CONTAINS))) {
					str1 = var + ' && ';
					str1 += operation.equals(GridSettingsManager.NOT_CONTAINS) ? '!' : '';
					str1 += ' ' + var + '.includes("' + value1 + '")';
				} else if (operation.equals(GridSettingsManager.EQUALS)) {
					str1 = '"' + value1 + '".includes(' + var + ')';
				} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
					str1 = '!"' + value1 + '".includes(' + var + ')';
				}
			} else if (fieldType == DisplayType.String || fieldType == DisplayType.Reference) {
				if (operation.equals(GridSettingsManager.ISNULL)) {
					str1 = '!' + var;
				} else if (operation.equals(GridSettingsManager.ISBLANK)) {
					str1 = '!' + var;
				} else if ((operation.equals(GridSettingsManager.CONTAINS) || operation.equals(GridSettingsManager.NOT_CONTAINS))) {
					str1 = var + ' && ';
					str1 += operation.equals(GridSettingsManager.NOT_CONTAINS) ? '!' : '';
					str1 += ' ' + var + '.includes("' + value1 + '")';
				} else if (operation.equals(GridSettingsManager.EQUALS) || operation.equals(GridSettingsManager.NOT_EQUALS)) {
					str1 = var + ' ' + GridSettingsManager.operations.get(operation)+' "' + value1 + '"';
				}
			} else if (fieldType == DisplayType.Picklist || fieldType == DisplayType.Multipicklist) {
				if (operation.equals(GridSettingsManager.ISNULL)) {
					str1 = '!' + var;
				} else if (operation.equals(GridSettingsManager.ISBLANK)) {
					str1 = '!' + var;
				} else if ((operation.equals(GridSettingsManager.CONTAINS) || operation.equals(GridSettingsManager.NOT_CONTAINS))) {
					str1 = var + ' && ';
					str1 += operation.equals(GridSettingsManager.NOT_CONTAINS) ? '!' : '';
					str1 += ' ' + var + '.includes("' + value1 + '")';
				} else if (operation.equals(GridSettingsManager.NOT_EQUALS)) {
					str1 = var + ' ' + GridSettingsManager.operations.get(operation)+' "' + value1 + '"';
				} else if (operation.equals(GridSettingsManager.EQUALS)) {
					str1 = var + ' ' + GridSettingsManager.operations.get(operation)+' "' + value1 + '"' + (fieldType == DisplayType.Multipicklist ? ' || ' + var + '.includes("' + value1 + '")' : '');
				}
			} else {
				if (operation.equals(GridSettingsManager.BETWEEN)) {
					str1 = var + '>' + value1 + ' && ' + var + '<' + value2;
				} else {
					str1 = var + ' ' + GridSettingsManager.operations.get(operation)+' ' + value1;
				}
			}
			condition += 'if (' + str1 + ') style+=`' + (style != null ? style.style : '')+'`; else style +=`' + (oppositeStyle != null ? oppositeStyle.style : '')+'`;';
			return condition;
		}
	}
	public class BorderStyle {
		public String pattern { get; set; }
		public String color { get; set; }
		public String size { get; set; }
		public String style {
			get {
				String prefix = 'border-';
				String content = '';
				content += size != null && String.isNotBlank(size) ? prefix + 'width: ' + size + ';' : '';
				content += color != null && String.isNotBlank(color) ? prefix + 'color: ' + color + ';' : '';
				content += pattern != null && String.isNotBlank(pattern) ? prefix + 'style: ' + pattern + ';' : '';
				return content;
			}
			set;
		}
	}
	public class SeparatorSettings {
		public String pattern { get; set; }
		public String color { get; set; }
		public String size { get; set; }
		public String style {
			get {
				String prefix = 'border-left-';
				String content = '';
				content += size != null && String.isNotBlank(size) ? prefix + 'width: ' + size + ';' : '';
				content += color != null && String.isNotBlank(color) ? prefix + 'color: ' + color + ';' : '';
				content += pattern != null && String.isNotBlank(pattern) ? prefix + 'style: ' + pattern + ';' : '';
				return content;
			}
			set;
		}
	}
	public class StyleSettings {
		public Boolean isAdvanced { get; set; }
		public String advancedStyle { get; set; }
		public TextStyle textStyle { get; set; }
		public BorderStyle borderStyle { get; set; }
		public String bgColor { get; set; }
		public String width { get; set; }
		public String style {
			get {
				String content = '';
				if (isAdvanced != null && isAdvanced) {
					content += advancedStyle != null ? advancedStyle : '';
				} else {
					content += widthStyle;
					content += bgColor != null && String.isNotBlank(bgColor) ? 'background-color: ' + bgColor + ';' : '';
					content += textStyle != null ? textStyle.style : '';
					content += borderStyle != null ? borderStyle.style : '';
				}
				return content;
			}
			set;
		}
		public String widthStyle {
			get {
				return width != null && String.isNotBlank(width) ? 'min-width: ' + width + '; max-width: ' + width + '; width: ' + width + ';' : '';
			}
			set;
		}
	}
	public class HeaderStyleSettings {
		public String bgColor { get; set; }
		public String color { get; set; }
		public String style {
			get {
				String content = '';
				content += bgColor != null && String.isNotBlank(bgColor) ? 'background-color: ' + bgColor + ';' : '';
				content += color != null && String.isNotBlank(color) ? 'color: ' + color + ';' : '';
				return content;
			}
			set;
		}
	}
	public class TextStyle {
		public Boolean isItalic { get; set; }
		public Boolean isBold { get; set; }
		public Boolean isUnderLine { get; set; }
		public Boolean isStrikeThrought { get; set; }
		public String align { get; set; }
		public String color { get; set; }
		public String size { get; set; }
		public String style {
			get {
				String content = '';
				content += align != null && String.isNotBlank(align) ? 'text-align:' + align + ';' : '';
				content += isItalic != null && isItalic ? 'font-style: italic;' : '';
				content += isBold != null && isBold ? 'font-weight: bold;' : '';
				content += (isUnderLine != null && isUnderLine) || (isStrikeThrought != null && isStrikeThrought) ? 'text-decoration: ' + (isUnderLine != null && isUnderLine ? ' underline ' : '')+(isStrikeThrought != null && isStrikeThrought ? ' line-through ' : '')+';' : '';
				content += color != null && String.isNotBlank(color) ? 'color: ' + color + ';' : '';
				content += size != null && String.isNotBlank(size) ? 'font-size: ' + size + ';' : '';
				return content;
			}
			set;
		}
	}
	public class FilterSettings {
		public String fieldName { get; set; }
		public String fieldLabel { get; set; }
		public Boolean isEncrypted { get; set; }
		public String stringFieldType { get; set; }
		public String objectName { get; set; }
		public List<SelectOption> pickListValues { get; set; }
		public String value1 { get; set; }
		public String value2 { get; set; }
		public List<String> values { get; set; }
		public Boolean userFilterable { get; set; }

		public List<String> getQueryConditions() {
			List<String> conditions = new List<String>();
			fieldName = String.escapeSingleQuotes(fieldName);
			if (!Pattern.matches('[\\w.]+', fieldName) || (stringFieldType == 'TIME' && !Pattern.matches('[\\d:.Z]*', (value1 == null ? '' : value1) + (value2 == null ? '' : value2)))) {
				throw new IllegalArgumentException('Invalid filter: ' + fieldName);
			}
			if (values != null && !values.isEmpty()) {
                if (stringFieldType == 'REFERENCE') {
                    if (fieldName.toLowerCase() == 'recordtypeid') {
                        List<String> stringifiedValues = (List<String>) JSON.deserialize(JSON.serialize(values), List<String>.class);
                        List<String> escapedStringifiedValues = new List<String>();
                        for (String value : stringifiedValues) {
							value = value == 'Principal' || value == 'Master' ? '' : value;
                            escapedStringifiedValues.add(String.escapeSingleQuotes(value).trim());
                        }
                        conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.DeveloperName IN (\'' + String.join(escapedStringifiedValues, '\', \'') + '\')');
                    } else {
                        if (isEncrypted == null || isEncrypted) {
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                        } else {
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                        }
                    }
                }
				if (stringFieldType == 'ID') {
					List<Id> fieldpicklistValues = new List<Id>();
					for (Object item : values) {
						try {
							fieldpicklistValues.add(Id.valueOf(String.escapeSingleQuotes(String.valueOf(item).trim())));
						} catch (Exception e) {
							System.debug('Error FilterSettings ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
							throw new AuraHandledException(e.getMessage());
						}
					}
					conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
				}
				if (stringFieldType == 'PICKLIST' || stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'COMBOBOX' || stringFieldType == 'RECORDTYPE' || stringFieldType == 'BOOLEAN') {
					List<String> fieldpicklistValues = new List<String>();
					for (Object item : values) {
						fieldpicklistValues.add(String.escapeSingleQuotes(String.valueOf(item)));
					}
					if (stringFieldType == 'BOOLEAN') {
						conditions.add(fieldName + ' IN (' + String.join(fieldpicklistValues, ', ')+')');
					} else if (stringFieldType == 'RECORDTYPE') {
						conditions.add('RecordType.DeveloperName IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
					} else if (stringFieldType == 'PICKLIST' || stringFieldType == 'COMBOBOX') {
						conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
					} else {
						conditions.add(fieldName + ' INCLUDES (\'' + String.join(fieldpicklistValues, ';')+'\')');
					}
				}
				if (stringFieldType == 'STRING') {
					if (isEncrypted == null || isEncrypted) {
						conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
					} else {
						conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
					}
				}
			}
			if (value1 != null || value2 != null) {
				if (stringFieldType == 'CURRENCY' || stringFieldType == 'INTEGER' || stringFieldType == 'DOUBLE' || stringFieldType == 'LONG' || stringFieldType == 'PERCENT' ) {
					if (value1 != null && value1 != '') {
						conditions.add(fieldName + ' >= ' + value1);
					}
					if (value2 != null && value2 != '') {
						conditions.add(fieldName + ' <= ' + value2);
					}
				}
				if (stringFieldType == 'DATETIME') {
					if (value1 != null && value1 != '') {
						List<String> splitedDate = String.valueOf(value1).split('-');
						conditions.add(fieldName + ' >= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
					}
					if (value2 != null && value2 != '') {
						List<String> splitedDate = String.valueOf(value2).split('-');
						conditions.add(fieldName + ' <= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
					}
				}
				if (stringFieldType == 'DATE') {
					if (value1 != null && value1 != '') {
						conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
					}
					if (value2 != null && value2 != '') {
						conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
					}
				}
				if (stringFieldType == 'TIME') {
					if (value1 != null && value1 != '') {
						conditions.add(fieldName + ' >= ' + value1);
					}
					if (value2 != null && value2 != '') {
						conditions.add(fieldName + ' <= ' + value2);
					}
				}
			}
			return conditions;
		}
		public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values) {
			this.fieldName = fieldName;
			this.fieldLabel = fieldLabel;
			this.isEncrypted = isEncrypted;
			this.stringFieldType = stringFieldType;
			this.pickListValues = pickListValues;
			this.value1 = value1;
			this.value2 = value2;
			this.values = values;
		}
		public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values, Boolean userFilterable) {
			this.fieldName = fieldName;
			this.fieldLabel = fieldLabel;
			this.isEncrypted = isEncrypted;
			this.stringFieldType = stringFieldType;
			this.pickListValues = pickListValues;
			this.value1 = value1;
			this.value2 = value2;
			this.values = values;
			this.userFilterable = userFilterable;
		}
		public FilterSettings(FieldWrapper field) {
			this.fieldName = field.fieldName;
			this.fieldLabel = field.fieldLabel;
			this.stringFieldType = field.fieldName.endsWithIgnoreCase('RecordTypeId') ? 'RECORDTYPE' : field.stringFieldType;
			this.isEncrypted = field.isEncrypted;
			this.pickListValues = field.pickListValues;
			this.userFilterable = false;
		}
	}
	public class SelectOption {
		@AuraEnabled
		public String value;
		@AuraEnabled
		public String label;
		public SelectOption(String value, String label) {
			this.value = value;
			this.label = label;
		}
	}
	public class FlowOption {
		@AuraEnabled
		public String value;
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String icon;
		@AuraEnabled
		public String displayType;
		@AuraEnabled
		public Boolean hasRecordId;
		@AuraEnabled
		public Boolean hasRecordIds;
		public FlowOption(String value, String label, String icon, String displayType, Boolean hasRecordId, Boolean hasRecordIds) {
			this.value = value;
			this.label = label;
			this.icon = icon;
			this.displayType = displayType;
			this.hasRecordId = hasRecordId;
			this.hasRecordIds = hasRecordIds;
		}
	}
	public class EmptyExpresionException extends Exception{}
    public class GridConfigurationWrapper {
        public Integer Default_Page_Size;
        public Boolean isShowFilterOnColumnHeader;
		public ActionWrapper actions;
		public Boolean Include_In_List_View;
		public Integer Display_Order;
        // List of fields of hierarchy tree
        public List<String> hierarchyParentField;
        // Field of grouping Data
        public String groupedField;
        // Grid Type : Normal / Grouped / Tree
        public String gridTypeValue;
        // Import Settings Template Name
        public String importSettingsTemplate;
    }
	public class ActionWrapper {
		public List<SObject> quickActions;
		public List<FlowOption> screenFlows;
	}
	public class ConditionalRule {
		public String description;
		public Criteria criteria;
		public String action;
		public String message;
	}
	public class CalendarSettingsWrapper {
		public String startDate;
		public String endDate;
		public String pickListValue;
		public Boolean showCalendarSettings;
	}
	public class TimeLineSettingsWrapper {
		public String masterLookupParent;
		public String masterLookup;
		public Integer levelControl;
		public Boolean isTimeLineSettings;
	}
}