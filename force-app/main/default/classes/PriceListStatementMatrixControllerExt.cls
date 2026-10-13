/**
 * PriceListStatementMatrixController
 */
public with sharing class PriceListStatementMatrixControllerExt extends NegoptimBaseController {
    // private Map<String, Map<String,String>> availablePickListValues {get;set;}
    // public String availablePickListValues_JSON {get { return JSON.serialize(availablePickListValues);} set;}
    public PriceListStatement__c priceListStatement {get; set;}
    private Id priceListStatementCategoryId;
    //private HierarchyElementTree het;
    /* Assortment BU Id */
    public String recordId {get; set;}
    private String priceListStatementName;
    public ApexPages.StandardSetController priceListStatementStdSetCtrl {get; set;}
    public String prefix {get; set;}
    // fields to display from settings
    public final String OBJECT_NAME {get {return SObjectType.PriceListStatementDetail__c.Name;} set;}
    public final String MASTER_OBJECT_NAME  {get {return SObjectType.PriceListStatement__c.Name;} set;}
    public String batchId {get; set;}
    public Boolean pollerEnabled {get; set;}
    private String staticFields;
    private String masterStaticFields;
    private NegoptimSettings settings {get; set;}
    public GridSettingsManager gridSettingsManager {get; set;}
    public Map<Id, CategoryWrapper> categoryWrapperMap {get; set;} // categoryId => all price list statement categories
    public PriceListStatementDetail__c priceListStatementDetail {get;set;} // to filter categories
    public String searchTerm {get; set;} // search key word to filter product category name
    public Boolean hasCategories {get; set;}
    public Map<Id, PriceListStatementDetail__c> priceListStatementDetailsUpdatedMap {get; set;}
    public Map<Id, PriceListStatementDetail__c> initialPriceListStatementDetailsMap {get; set;}
    public List<CategoryWrapper> wPriceListStatementDetailsCategoryList {get; set;} // iterated in view to display records
    public List<Id> categoryWrapperMap_KeySet {get; set;}
    public Map<Id, String> categoryNamesMap {get; set;}
    public String categoryNamesMap_JSON {get {return categoryNamesMap != null ? JSON.serialize(categoryNamesMap.keySet()) : '';} set;}
    public String picklistValuesMap_JSON {get {return this.gridSettingsManager != null && this.gridSettingsManager.picklistValuesMap != null ? JSON.serialize(this.gridSettingsManager.picklistValuesMap.keySet()) : '';} set;}
    public Map<Id, Map<String, Integer>> counts {get; set;}
    public Map<Id, Map<String, Decimal>> sums {get; set;}
    public Map<Id, Map<String, String>> sumsFormated {get {
        Map<Id, Map<String, String>> formatedMap = new Map<Id, Map<String, String>>();
        for (String key : sums.keySet()) {
            Map<String, String> formatedMapValue = formatedMap.containsKey(key) ? formatedMap.get(key) : new Map<String, String>();
            for (String fieldName : sums.get(key).keySet()) {
                String value = sums.get(key).get(fieldName).setScale(gridFieldsScaleMap.get(fieldName)).format();
                formatedMapValue.put(fieldName, value);
            }
            formatedMap.put(key, formatedMapValue);
        }
        return formatedMap;
    } set;}
    private Map<String, Integer> gridFieldsScaleMap;
    private List<String> fieldsToCountList;
    private List<String> fieldsDateList;
    private List<String> fieldsToSumList;
    private List<String> fieldsInputList {get; set;}
    private List<String> fieldsPicklistList {get; set;}
    public String logoFields {get; set;}
    public String logoFields_serialized {get; set;}
    public String fieldsScaleMap_serialized {get; set;}
    public String xmlheader {get { return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>'; } }
    public String numberFormatExcelString {get { return '<NumberFormat ss:Format="@"/>'; } }
    public String dateTimeFormatExcelString {get { return '<NumberFormat ss:Format="Short Date"/>'; } }
    public String filename { get { return /***Label.LBL_Price_List_Export_Name + ' - ' +***/ (this.priceListStatement?.Name != null ? this.priceListStatement?.Name : '') ; } set;}
    public String delimiter {get; set;}
    public List<String> csvFields {get; set;}
    public List<String> exportedFields {get; set;}
    public Map<String, String> csvFieldsMap {get; set;}
    public String csvFieldsJson {get{
        return csvFields != null ? JSON.serialize(csvFields) : '';
    } set;}
    public String exportRecords_JSON {
        get {
            return JSON.serialize(this.exportedData);
        }
    }
    public String settings_JSON {
        get {
            return JSON.serialize(this.settings);
        }
    }
    public String csvDateFormat {get; set;}
    public String fields_JSON {
        get {
            return JSON.serialize(exportedFields);
        }
    }
    Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    /* Totals */
    public String jsonCategoryTree {get; set;}
    public Map<Id, CategoryTreeWrapper> categoryTreeMap {get; set;}
    public String gridFields_serialized {get; set;}
    public List<GridSettingsManager.FieldWrapper> totalFields {get; set;} // total fields ordered as loaded
    public String totalFields_serialized {get; set;}
    public String fieldsToCountList_serialized {get; set;}
    public String fieldsDateList_serialized {get; set;}
    public String fieldsToSumList_serialized {get; set;}
    public String fieldsInputList_serialized {get; set;}
    public String fieldsPicklistList_serialized {get; set;}
    private Set<Id> categorySet {get; set;}
    private Set<String> categoryPathSet {get; set;}
    public Boolean displayUploadpopup {get; set;}
    public String headerXML {get; set;} // used for excel export
    public Map<String, GridSettingsManager.FieldWrapper> gridFieldsMap {get; set;} // used for excel export
    public String gridFieldsMap_JSON {get { return gridFieldsMap != null ? JSON.serialize(gridFieldsMap) : '{}';} set;} // used for excel export
    public Boolean isDoneLoading { get; set;}
    public String gridFieldsMap_keySetJSON {get { return gridFieldsMap != null ? JSON.serialize(gridFieldsMap.keySet()) : '';} set;} // used for excel export
    public Map<String, String> fieldStyleMap {get; set;} // used for excel export
    public String localeDecimalSeparator { get; set; } // used for excel export
    public String inputFields {get; set;}
    private Integer fStyleIndex = 1;
    public Set<String> disbledRows;
    public String disbledRows_JSON {get {return disbledRows != null ? JSON.serialize(disbledRows) : '';} set;}
    private Map<String, Map<String, String>> pickListTranslateMap;
    /* Pagination */
    public Integer pageSize {get; set;}
    public Integer noOfRecords {get; set;}
    private List<Integer> pageSizesOptions = new List<Integer> {5, 10, 25, 50, 75, 100};
    public List<SelectOption> pageSizes {
        get {
            List<SelectOption> newpageSizes = new List<SelectOption>();
            for (Integer pagesizeItem : pageSizesOptions) {
                newpageSizes.add(new SelectOption(String.valueOf(pagesizeItem), String.valueOf(pagesizeItem)));
            }
            return newpageSizes;
        }
        set;
    }
    /* Active Taxes Statements */
    public String activeTaxDisplayOrder_str {get; private set;}
    public Map<Integer, StatementWrapper> activeTaxesMap {get; private set;}
    private String priceListStatementMatrixGridLayout;
    public Boolean isActionsActive {get { return this.priceListStatement.RecordTypeId != NegoptimHelper.getObjectRecordTypeId(PriceListStatement__c.SObjectType, 'Iso_Partner_12M') &&  (this.gridSettingsManager != null && this.gridSettingsManager.ERRORS != null && this.gridSettingsManager.ERRORS.isEmpty() && !(this.gridSettingsManager.isReadOnly == true) && String.isNotBlank(this.inputFields) /*&& !this.wPriceListStatementDetailsCategoryList.isEmpty()*/); }}
    public Boolean enableImport {get { return this.priceListStatement.RecordTypeId != NegoptimHelper.getObjectRecordTypeId(PriceListStatement__c.SObjectType, 'Iso_Partner_12M') &&  (this.gridSettingsManager != null && this.gridSettingsManager.ERRORS != null && this.gridSettingsManager.ERRORS.isEmpty() && !(this.gridSettingsManager.isReadOnly == true) && String.isNotBlank(this.inputFields) /*&& !this.wPriceListStatementDetailsCategoryList.isEmpty()*/); }}
    public List<Integer> list100Iteration { get; set; }
    public Boolean enableDDDOrWareHouse { get { return this.priceListStatement?.NegoScope__r?.SupplyChainType__c == 'Direct to Store' || this.priceListStatement?.NegoScope__r?.SupplyChainType__c == 'DDD' /* || this.priceListStatement?.NegoScope__r?.SupplyChainType__c == 'To Warehouse' || this.priceListStatement?.NegoScope__r?.SupplyChainType__c == 'Entrepot'*/; } }
    /** Constructor. */
    public PriceListStatementMatrixControllerExt(ApexPages.StandardController stdController) {
        // this.availablePickListValues = new Map<String, Map<String, String>>();
        this.pollerEnabled = false;
        String isExport = ApexPages.currentPage().getParameters().get('isExport');
        // load custom settings
        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        String csvDatefrmt = settings.csvDateFormat.remove(' ');
        csvDateFormat = csvDatefrmt.trim();
        this.pageSize = 50;
        this.list100Iteration = new List<Integer>();
        for (Integer index = 0; index < 100; index++) {
            this.list100Iteration.add(index);
        }
        this.headerXML = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        localeDecimalSeparator = NegoptimHelper.getDecimalSeparator();
        // Get record Id
        String priceListStatementId = stdController.getId();
        this.prefix = NegoptimHelper.getPackagePrefix(true);
        this.gridFieldsScaleMap = new Map<String, Integer>();
        for (SObjectField item : PriceListStatementDetail__c.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = item.getDescribe();
            gridFieldsScaleMap.put(dfr.getName(), dfr.getScale());
        }
        if (String.isNotBlank(priceListStatementId)) {
            try {
                this.recordId = Id.valueOf(priceListStatementId);
                this.initialPriceListStatementDetailsMap = new Map<Id, PriceListStatementDetail__c>();
                this.priceListStatementDetailsUpdatedMap = new Map<Id, PriceListStatementDetail__c>();
                this.priceListStatementDetail = new PriceListStatementDetail__c();
                this.categoryNamesMap = new Map<Id, String>();
                // Load Hierarchy Element Tree based on Root Category
                //this.het = new HierarchyElementTree(new Set<Id>{NegoptimHelper.getRootIdByRT('Product')});
                this.hasCategories = false;
                this.delimiter = settings.delimiter;
                // get fields from Grid Settings
                this.priceListStatementMatrixGridLayout = settings.priceListStatementMatrixGridLayout;
                String layoutParam = ApexPages.currentPage().getParameters().get('layout');
                this.priceListStatementMatrixGridLayout = String.isBlank(layoutParam) ? priceListStatementMatrixGridLayout : layoutParam;
                System.debug(' this.priceListStatementMatrixGridLayout >>> ' + this.priceListStatementMatrixGridLayout);
                this.masterStaticFields = '';
                this.staticFields = '';
                // fill master static fields
                List<String> masterStaticFieldsList = new List<String> {
                    SObjectType.PriceListStatement__c.fields.Name.Name,
                    SObjectType.PriceListStatement__c.fields.Supplier__c.Name,
                    SObjectType.PriceListStatement__c.fields.NegoScope__c.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatement__c.fields.NegoScope__c.Name) + '.' + SObjectType.NegoScope__c.fields.SupplyChainType__c.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatement__c.fields.PriceListStatementReference__c.Name) + '.' + SObjectType.PriceListStatement__c.fields.RecordtypeId.Name,
                    /***SObjectType.PriceListStatement__c.fields.Contrat__c.Name,***/
                    SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
                    SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name,
                    SObjectType.PriceListStatement__c.fields.Status__c.Name,
                    SObjectType.PriceListStatement__c.fields.RecordTypeId.Name,
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name,
                    /***SObjectType.PriceListStatement__c.fields.SellIn_Total_wGrossPriceP1__c.Name,***/
                    SObjectType.PriceListStatement__c.fields.t_ActiveTaxesList__c.Name
                };
                List<String> staticFieldsList = new List<String> {
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName1__c.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.PG__c.Name) + '.' + SObjectType.PG__c.fields.Name.Name,
                    /***NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Promo_Event__c.Name) + '.' + SObjectType.Commercial_Plan__c.fields.Name.Name,
                    NegoptimHelper.getFieldNameAsRelation(SObjectType.PriceListStatementDetail__c.fields.Promo_Event_Detail__c.Name) + '.' + SObjectType.Commercial_Plan_Detail__c.fields.Name.Name,***/
                    // SObjectType.PriceListStatementDetail__c.fields.Id.Name,
                    /***SObjectType.PriceListStatementDetail__c.fields.Product_EAN__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Product_Name__c.Name,***/
                    SObjectType.PriceListStatementDetail__c.fields.Name.Name,
                    SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Hierarchy__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.PG__c.Name,
                    /***SObjectType.PriceListStatementDetail__c.fields.Promo_Event__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.Promo_Event_Detail__c.Name,***/
                    SObjectType.PriceListStatementDetail__c.fields.SellInRegularQty__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.GrossPriceGap__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.GrossPriceP1__c.Name,
                    /***SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Name,***/
                    SObjectType.PriceListStatementDetail__c.fields.PriceListStatementDetailLastHistory__c.Name
                    /***SObjectType.PriceListStatementDetail__c.fields.Is_switched__c.Name,
                    SObjectType.PriceListStatementDetail__c.fields.EAN_Switch_Proposal__c.Name***/
                };
                Map<String, Schema.SObjectField> priceListStatementDetailFieldsMap = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap();
                List<String> outsidePackageFields = new List<String> {
                    'SPITM_Supplier_Product_Code__c',
                    'SPITM_Product_Brand_DDD__c',
                    'SPITM_BIO_DDD__c',
                    'SPITM_UC_DDD__c',
                    'SPITM_PCB_DDD__c',
                    'SPITM_Element_nb_DDD__c',
                    'SPITM_New_Product_Statement_Date__c',
                    'TMP_Family__c'
                    // 'SPITM_Raw_Material_Origin__c',
                    // 'SPITM_Manufacturing_Country__c',
                    // 'SPITM_Production_Country__c',
                    // 'SPITM_Processing_Country__c',
                    // 'IsInnovation__c'
                };
                for (String fieldApiName : outsidePackageFields) {
                    if (priceListStatementDetailFieldsMap.containsKey(fieldApiName)) {
                        staticFieldsList.add(fieldApiName);
                    }
                }
                this.gridSettingsManager = new GridSettingsManager(String.escapeSingleQuotes(this.MASTER_OBJECT_NAME), this.masterStaticFields, String.join(masterStaticFieldsList, ','), String.escapeSingleQuotes(this.OBJECT_NAME), this.staticFields, String.join(staticFieldsList, ','), String.escapeSingleQuotes(priceListStatementMatrixGridLayout));
                for (String errorMessage : this.gridSettingsManager.ERRORS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                }
                if (this.gridSettingsManager.Default_Page_Size != null && this.pageSizesOptions.contains(this.gridSettingsManager.Default_Page_Size)) {
                   this.pageSize = this.gridSettingsManager.Default_Page_Size;
                }
                // get price list statement header
                String query = gridSettingsManager.buildBannerQuery(new List<String>{'Id = \''  + priceListStatementId + '\''});
                if (query == null || query == '') {
                    query = 'SELECT ' + (masterStaticFieldsList != null && !masterStaticFieldsList.isEmpty() ? String.join(masterStaticFieldsList, ', ') : ' Id, RecordTypeId ') + ', PriceListStatementReference__c, PriceListStatementReference__r.RecordTypeId FROM PriceListStatement__c WHERE Id =\''  + String.escapeSingleQuotes(priceListStatementId )  +  '\'';
                }
                this.priceListStatement = Database.query(query);
                this.priceListStatementName = this.priceListStatement.Name;
                this.gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(this.priceListStatement);
                for (String errorMessage : this.gridSettingsManager.ERRORS) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                }
                // get the statement's active Taxes
                this.activeTaxesMap = new Map<Integer, StatementWrapper>();
                if (this.priceListStatement.t_ActiveTaxesList__c != null && String.isNotBlank(this.priceListStatement.t_ActiveTaxesList__c)) {
                    for (StatementWrapper item : (List<StatementWrapper>) JSON.deserialize(this.priceListStatement.t_ActiveTaxesList__c, List<StatementWrapper>.class)) {
                        this.activeTaxesMap.put(item.displayOrder, item);
                    }
                }
                this.activeTaxDisplayOrder_str = '[-' + String.join(new List<Integer>(this.activeTaxesMap.keySet()), '-') + '-]';
                // populate GridSettings fields and initialize totals
                this.counts = new Map<Id, Map<String, Integer>>();
                this.sums = new Map<Id, Map<String, Decimal>>();
                this.categorySet = new Set<Id>();
                this.categoryPathSet = new Set<String>();
                this.fieldsToCountList = new List<String>();
                this.fieldsDateList = new List<String>();
                this.fieldsToSumList = new List<String>();
                this.fieldsInputList = new List<String>();
                this.fieldsPicklistList = new List<String>();
                this.totalFields = new List<GridSettingsManager.FieldWrapper>();
                this.gridFieldsMap = new Map<String, GridSettingsManager.FieldWrapper>();
                List<String> logoFieldsList = new List<String>();
                Map<String, Integer> fieldsScaleMap = new Map<String, Integer>();
                this.csvFieldsMap = new Map<String, String>();
                this.csvFields = new List<String>();
                this.fieldStyleMap = new Map<String, String>();
				this.pickListTranslateMap = new Map<String, Map<String, String>>();
                Map<String, Schema.SObjectField> priceListDetailFieldsMap = Schema.getGlobalDescribe().get(this.OBJECT_NAME).getDescribe().fields.getMap();
                this.inputFields = '';
                this.exportedFields = new List<String>();
                fieldsDateList.add('SPITM_New_Product_Statement_Date__c');
                if (this.gridSettingsManager.ERRORS.size() == 0) {
                    for (GridSettingsManager.FieldWrapper field : this.gridSettingsManager.GRID_FIELDS) {
                        gridFieldsMap.put(field.fieldName, field);
                        // get all taxes fields
                        Boolean isTaxField = field.fieldName.startsWith(this.prefix + 'Tax_');
                        String taxOrder = field.fieldName.Replace(this.prefix + 'Tax_', '').Replace('__c', '');
                        Boolean isTaxActive = isTaxField && this.activeTaxesMap.containsKey(Integer.valueOf(taxOrder));
                        Boolean addFieldToExcel = false;
                        if (isTaxField && isTaxActive) {
                            if (activeTaxesMap.containsKey(Integer.valueOf(taxOrder))) {
                                this.csvFieldsMap.put(field.fieldName, activeTaxesMap.get(Integer.valueOf(taxOrder)).name);
                                field.fieldlabel = activeTaxesMap.get(Integer.valueOf(taxOrder)).name;
                                this.csvFields.add(field.fieldName);
                                this.fieldStyleMap.put(field.fieldName, 'f' + String.valueOf(fStyleIndex++));
                                if (!inputFields.contains(field.fieldName) && field.isInputField) {
                                    inputFields += field.fieldName + ',';
                                }
                                // if (field.isNotExportable != true) {
                                addFieldToExcel = true;
                                // }
                            }
                        } else if (!isTaxField && String.isNotBlank(field.fieldName)) {
                            if (field.isNotExportable != true) {
                                addFieldToExcel = true;
                            }
                            this.csvFieldsMap.put(field.fieldName, field.fieldlabel);
                            this.csvFields.add(field.fieldName);
                            this.fieldStyleMap.put(field.fieldName, 'f' + String.valueOf(fStyleIndex++));
                            if (!inputFields.contains(field.fieldName) && field.isInputField) {
                                inputFields += field.fieldName + ',';
                            }
                            if (priceListStatementDetailFieldsMap.containsKey(field.fieldName)) {
                                Schema.DisplayType fielddataType = priceListStatementDetailFieldsMap.get(field.fieldName).getDescribe().getType();
                                if (fielddataType == Schema.DisplayType.Reference) {
                                    gridFieldsMap.put(field.fieldName.replace('__c', '__r.Name'), field);
                                    this.csvFieldsMap.put(field.fieldName.replace('__c', '__r.Name'), field.fieldlabel + ' Name');
                                    if (isExport == 'true') {
                                        this.csvFields.add(field.fieldName.replace('__c', '__r.Name'));
                                    }
                                    this.fieldStyleMap.put(field.fieldName.replace('__c', '__r.Name'), 'f' + String.valueOf(fStyleIndex++));
                                    if (!inputFields.contains(field.fieldName) && field.isInputField) {
                                        inputFields += field.fieldName + ',';
                                    }
                                }
                            }
                            // if (field.fieldName == SObjectType.PriceListStatementDetail__c.fields.IsInnovation__c.Name) {
                            //     if (!inputFields.contains(field.fieldName)) {
                            //         inputFields += field.fieldName + ',';
                            //         field.isInputField = true;
                            //     }
                            // }
                        }
                        if (addFieldToExcel) {
                            this.exportedFields.add(field.fieldName);
                            // try {
                            //     if (priceListStatementDetailFieldsMap.containsKey(field.fieldName)) {
                            //         Schema.DisplayType fielddataType = priceListStatementDetailFieldsMap.get(field.fieldName).getDescribe().getType();
                            //         if (fielddataType == Schema.DisplayType.PICKLIST || fielddataType == Schema.DisplayType.MULTIPICKLIST) {
                            //             this.availablePickListValues.put(field.fieldName, PicklistHelper.getPicklistValuesByRecordTypeId(PriceListStatementDetail__c.SObjectType, priceListStatementDetailFieldsMap.get(field.fieldName), NegoptimHelper.getObjectRecordTypeId(PriceListStatementDetail__c.SObjectType, 'Regular')));
                            //         }
                            //     }
                            // } catch(Exception ex) {

                            // }
                        }
                        // get input fields
                        if (field.isInputField) {
                            fieldsInputList.add(field.fieldName);
                        }
                        if (String.isNotBlank(field.fieldName) && !field.isReference && field.fieldName.endsWithIgnoreCase('__c')
                            && (field.isNumberField || field.fieldType == DisplayType.Boolean))
                        {
                            if (field.fieldType == DisplayType.Boolean) {
                                fieldsToCountList.add(field.fieldName);
                            } else if (isTaxField && isTaxActive) {
                                fieldsToSumList.add(field.fieldName);
                            } else if (!isTaxField) {
                                fieldsToSumList.add(field.fieldName);
                            }
                            continue;
                        }
                        // get all Logo fields
                        if (String.isNotBlank(field.fieldName) && field.fieldName.endsWithIgnoreCase('__c') && !field.fieldName.contains('.')) {
                            Schema.SObjectField fd = priceListStatementDetailFieldsMap.get(field.fieldName);
                            Schema.DescribeFieldResult dfr = fd.getDescribe();
                            if (dfr.isCalculated() && dfr.getCalculatedFormula() != null) {
                                if (dfr.getCalculatedFormula().contains('IMAGE')) logoFieldsList.add(field.fieldName);
                            }
                            fieldsScaleMap.put(field.fieldName, (Integer) priceListStatementDetailFieldsMap.get(field.fieldName.toLowerCase()).getDescribe().scale);
                        }
                        // get all picklist fields
                        if (String.isNotBlank(field.fieldName) && field.fieldName.endsWithIgnoreCase('__c') && !field.fieldName.contains('.') &&
                            field.isInputField && field.fieldType == DisplayType.Picklist)
                        {
                            this.fieldsPicklistList.add(field.fieldName);
                        }

                        if (field.fieldType == DisplayType.Picklist) {
                            DescribeFieldResult dfr = priceListDetailFieldsMap.get(field.fieldName).getDescribe();
                            Map<String, String> pickListTranslationMap = new Map<String, String>();
                            for (Schema.PicklistEntry pv: dfr.getPicklistValues()) {
                                if (pv.isActive()) {
                                    pickListTranslationMap.put(pv.getValue(), pv.getLabel());
                                }
                            }
                            this.pickListTranslateMap.put(field.fieldName, pickListTranslationMap);
                        }
                    }
                    // if (!this.fieldStyleMap.containsKey(SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Name)) {
                    //     this.fieldStyleMap.put(SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Name, 'f' + String.valueOf(fStyleIndex++));
                    //     this.csvFieldsMap.put(SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Name, SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Label);
                    //     this.gridFieldsMap.put(SObjectType.PriceListStatementDetail__c.fields.Product_Code__c.Name, this.gridFieldsMap.get(SObjectType.PriceListStatementDetail__c.fields.Product_Name__c.Name));
                    // }
                } else {
                    for (String errorMessage : gridSettingsManager.ERRORS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                    }
                }
                system.debug('>>>>>> inputFields : ' + this.inputFields);
                this.fieldsScaleMap_serialized = JSON.serialize(fieldsScaleMap);
                if (!logoFieldsList.isEmpty()) this.logoFields = String.join(logoFieldsList, ',');
                this.logoFields_serialized = JSON.serialize(logoFieldsList);
                this.gridFields_serialized = JSON.serialize(gridFieldsMap);
                this.totalFields_serialized = JSON.serialize(this.totalFields);
                this.fieldsToCountList_serialized = JSON.serialize(this.fieldsToCountList);
                this.fieldsDateList_serialized = JSON.serialize(this.fieldsDateList);
                this.fieldsToSumList_serialized = JSON.serialize(this.fieldsToSumList);
                this.fieldsInputList_serialized = JSON.serialize(this.fieldsInputList);
                this.fieldsPicklistList_serialized = JSON.serialize(this.fieldsPicklistList);
                if (gridSettingsManager.ERRORS.isEmpty()) {
                    this.search();
                } else {
                    for (String errorMessage : gridSettingsManager.ERRORS) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                    }
                }
                String isLite = ApexPages.currentPage().getParameters().get('isLite');
                if (isExport == 'true') {
                    this.prepareDataToExport(Boolean.valueof(isLite));
                }
                // System.debug(' availablePickListValues_JSON >>> ' + availablePickListValues_JSON);
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' - ' + ex.getLineNumber()));
            }
            this.displayUploadpopup = false;
        } else {
            String errorMessage = 'Selected Id is Null';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
    }
    public PageReference renderMessage() {
        String status, message;
        status = ApexPages.currentPage().getParameters().get('status');
        message = ApexPages.currentPage().getParameters().get('message');
        System.debug('renderMessage ::: ' + status + '-' + message );
        if (status == 'ERROR') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
        } else if (status == 'SUCCESS') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
        } else if (status == 'WARNING') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
        }
        return null;
    }
    public void setBatchIdAndRunPoller() {
        this.pollerEnabled = batchId != null;
        if (this.pollerEnabled) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,  string.format(Label.MSG_Job_In_Progress, new String[]{'Import', batchId})));
        }
        this.displayUploadpopup = false;
    }

    /***public PageReference checkPoller() {
        this.pollerEnabled = false;
        // check access AsyncApexJob fields
        String[] apexJobFields = new String[] {
            SObjectType.AsyncApexJob.fields.Id.Name,
            SObjectType.AsyncApexJob.fields.CreatedDate.Name,
            SObjectType.AsyncApexJob.fields.Status.Name,
            SObjectType.AsyncApexJob.fields.JobType.Name,
            SObjectType.AsyncApexJob.fields.ApexClassId.Name
        };
        // check access ApexClass fields
        String[] apexClassFields = new String[] {
            SObjectType.ApexClass.fields.Name.Name
        };
        List<AsyncApexJob> batchJob = new List<AsyncApexJob>();
        if (checkAccessibility(AsyncApexJob.SObjectType, apexJobFields) && checkAccessibility(ApexClass.SObjectType, apexClassFields)) {
            batchJob = batchId != null
                        ? [SELECT Id, Status FROM AsyncApexJob
                                             WHERE ApexClass.Name = :ImportBatch.class.getName()
                                             AND JobType != 'BatchApexWorker'
                                             AND Id = :batchId
                                             ORDER BY CreatedDate DESC LIMIT 20]
                        : [SELECT Id, Status FROM AsyncApexJob
                                             WHERE ApexClass.Name = :ImportBatch.class.getName()
                                             AND JobType != 'BatchApexWorker'
                                             ORDER BY CreatedDate DESC LIMIT 20];
        }
        // Activate the poller if theare are a job holding or in process
        for(AsyncApexJob job : batchJob) {
            if(job.Status != 'Completed' && job.Status != 'Aborted' && job.Status != 'Failed') {
                this.pollerEnabled = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,  string.format(Label.MSG_Job_In_Progress, new String[]{'Import', batchId})));
                break;
            }
        }
        if (!this.pollerEnabled) {
            this.initialPriceListStatementDetailsMap.clear();
            this.priceListStatementDetailsUpdatedMap.clear();
            this.wPriceListStatementDetailsCategoryList.clear();
            this.categoryWrapperMap.clear();
            this.search();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,  System.Label.MSG_Batch_Executed +': Import'));
        }
        return null;
    }***/
    // generate Dynamic compoment to show table matrix
    public Component.Apex.OutputText getDateInput() {
        Component.Apex.OutputText outputText = new Component.Apex.OutputText();
        //<apex:outputText rendered="{!OR(gridFieldsMap[field].stringFieldType == 'DATE',gridFieldsMap[field].stringFieldType == 'DATETIME')}"  value="{0, date,yyyy'-'MM'-'dd' 'HH':'mm':'ss}"><apex:param value="{!item[field]}" /></apex:outputText>
        outputText.expressions.rendered = '{!item[field] != null && OR(gridFieldsMap[field].stringFieldType == \'DATE\',gridFieldsMap[field].stringFieldType == \'DATETIME\')}';
        outputText.expressions.value = '{!TEXT(1900 + item[field].YEAR) & \'-\' & TEXT(item[field].MONTH) & \'-\' & TEXT(item[field].DAY)}';
        //NegoptimDate.parseDate(fieldValue, settings.csvDateFormat)
        String dateSeperator = '';
        String dateSeperatorAdd = '';
        // load custom settings
        if (settings == null) settings = GlobalSettingsManager.loadGlobalSettings();
        if (String.isNotBlank(settings.csvDateFormat)) {
            if (settings.csvDateFormat.contains('/')) { dateSeperator = '/'; dateSeperatorAdd = '& \'/\' &';}
            if (settings.csvDateFormat.contains('.')) { dateSeperator = '.'; dateSeperatorAdd = '& \'.\' &';}
            if (settings.csvDateFormat.contains('-')) { dateSeperator = '-'; dateSeperatorAdd = '& \'-\' &';}
            List<String> splitedFormat = settings.csvDateFormat.split(dateSeperator);
            List<String> format = new List<String>();
            String dateData = '';
            for (String cell: splitedFormat) {
                if (cell.containsignorecase('y')) { format.add('TEXT(YEAR(item[field]))'); }
                if (cell.containsignorecase('m')) { format.add('TEXT(MONTH(item[field]))'); }
                if (cell.containsignorecase('d')) { format.add('TEXT(DAY(item[field]))'); }
            }
            if (!format.isEmpty()) {
                outputText.expressions.value = '{!' + String.join(format, dateSeperatorAdd) + '}';
            }
        }
        //outputText.expressions.value = '{!item[field].YEAR()}';
        /*Component.Apex.Param valuePram = new Component.Apex.Param();
        valuePram.expressions.value = '';*/
        return outputText;
    }
    public Component.Apex.PageBlockTable getDynamicPageBlockTable() {
       // return null;
        if (recordId == null) return null;
        if (wPriceListStatementDetailsCategoryList == null || wPriceListStatementDetailsCategoryList.isEmpty()) return null;
        Component.Apex.PageBlockTable dynamicBlockTable = new Component.Apex.PageBlockTable();
        dynamicBlockTable.expressions.value = '{!group.priceListStatementDetails}';
        dynamicBlockTable.var = 'item';
        dynamicBlockTable.styleClass = 'slds-table slds-no-row-hover slds-table_bordered';
        for (String fieldName : this.csvFields) {
            ColumnWrapper matrixCol = new ColumnWrapper();
            GridSettingsManager.FieldWrapper fieldWrapper = this.gridFieldsMap.get(fieldName);
            System.debug(' fieldName >>> ' + fieldName);
            System.debug(' fieldWrapper?.isHidden >>> ' + fieldWrapper?.isHidden);
            if (fieldWrapper?.isHidden != true) {
                System.debug(' fieldName display >>> ' + fieldName);
                if ((logoFields == null || (logoFields != null && !logoFields.contains(fieldName)))) {
                    dynamicBlockTable.childComponents.add(matrixCol.getColumn(fieldWrapper, this.fieldsToSumList));
                }
                if (logoFields != null && logoFields.contains(fieldName)) {
                    dynamicBlockTable.childComponents.add(matrixCol.getLogoColumn(fieldWrapper));
                }
            }
        }
        return dynamicBlockTable;
    }

    public class ColumnWrapper {

        public Component.Apex.Column getColumn(GridSettingsManager.FieldWrapper field, List<String> fieldsToSumList) {
            Component.Apex.Column column = new Component.Apex.Column();
            column.footerClass = 'slds-text-align_right';
            Component.Apex.OutputText footerText = new Component.Apex.OutputText();
            if (field.isNumberFIeld && !field.fieldName.contains('__r') && fieldsToSumList.contains(field.fieldName)) {
                footerText.expressions.value = '{!sumsFormated[group.categoryId][\'' + field.fieldName +'\']}';
            }
            footerText.expressions.styleClass = 'text-center {!group.categoryId}' + field.fieldName;
            column.facets.footer = footerText;
            column.expressions.styleClass = (field.stringFieldType == 'BOOLEAN' || field.isNumberField ? ' slds-text-align_center ' : '') + 'slds-truncate dataCell wrap-td slds-border_left text-center cell_{!item.Id}_' + field.fieldName;
            if (String.isNotBlank(field.bgColor)) {
                column.style = 'background-color: ' + field.bgColor + ';';
            }
            column.expressions.styleClass += '{!IF(Contains(disbledRows_JSON, item.Id), " specific slds-theme_alert-texture", "")}';
            if (field.widthStyle != null && field.widthStyle != '' && !field.isInputField) {
                column.style += field.widthStyle;
            } else {
                if (field.stringFieldType == 'REFERENCE' || field.stringFieldType == 'TEXTAREA' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'MULTIPICKLIST') {
                    column.expressions.styleClass += ' limit-width-medium ';
                } else {
                    column.expressions.styleClass += ' limit-width ';
                }
            }
            //Tax & Discount managemenet
            Boolean isTaxField = false;
            String taxOrder;
            Boolean isPriceDiscountField = false;
            String priceDiscountOrder;
            if (field.fieldName.startsWith(NegoptimHelper.normalizeAPIName('Tax_'))) {
                isTaxField = true;
                taxOrder = field.fieldName.replaceFirst(NegoptimHelper.normalizeAPIName('Tax_'), '').replace('__c', '');
            }
            if (field.fieldName.startsWith(NegoptimHelper.normalizeAPIName('Disc_'))) {
                isPriceDiscountField = true;
                priceDiscountOrder = field.fieldName.replaceFirst(NegoptimHelper.normalizeAPIName('Disc_'), '').substring(0,1);
            }
            if (isTaxField) {
                Component.Apex.OutputLink header = new Component.Apex.OutputLink();
                header.expressions.value = '/{!activeTaxesMap[' + taxOrder + '].recordId}';
                header.target = '_blank';
                header.expressions.rendered = '{!CONTAINS(activeTaxDisplayOrder_str, "-"&"' + taxOrder + '"&"-")}';
                Component.Apex.OutputText headerText = new Component.Apex.OutputText();
                headerText.expressions.value = '{!activeTaxesMap[' + taxOrder + '].name}';
                header.childComponents.add(headerText);
                column.facets.header = header;
            } else {
                column.headerValue = field.fieldLabel;
            }
            column.headerClass = 'inner-th text-center headerRow slds-truncate';
            String fieldName = '"' + field.fieldName + '"';
            String left = field.fieldName.contains('.') ? '"' + field.fieldName.split('\\.').get(0) + '"' : '';
            String right = field.fieldName.contains('.') ? '"' + field.fieldName.split('\\.').get(1) + '"' : '';
            if (right != '') {
                Component.Apex.OutputField outputField = new Component.Apex.OutputField();
                outputField.expressions.rendered = '{!item[' + left + '] != null}';
                outputField.styleClass =  'slds-m-around_small';
                outputField.expressions.value = '{!item[' + left + '][' + right + ']}';
                column.childComponents.add(outputField);
            }
            if (field.fieldName.equalsIgnoreCase('Name') && !field.isInputField) {
                Component.Apex.OutputLink nameLink = new Component.Apex.OutputLink();
                nameLink.expressions.value = '/{!item.Id}';
                nameLink.target = '_blank';
                Component.Apex.OutputText nameText = new Component.Apex.OutputText();
                nameText.expressions.value = '{!item[' + fieldName + ']}';
                nameLink.childComponents.add(nameText);
                column.childComponents.add(nameLink);
            }
            //field name = Product__c
            if (!field.isInputField
                && ((field.fieldName.equalsIgnoreCase(SObjectType.PriceListStatementDetail__c.fields.Product__c.Name)
                    /***|| field.fieldName.equalsIgnoreCase(SObjectType.PriceListStatementDetail__c.fields.Additionnal_Product__c.Name)***/)))
            {
                Component.Apex.OutputField outputField = new Component.Apex.OutputField();
                // outputField.expressions.styleClass = '{!item.Id}_' + field.fieldName;
                outputField.expressions.value = '{!item[' + fieldName + ']}';
                column.childComponents.add(outputField);
            }

            if (!fieldName.contains('.')) {
                // filed tyde = currency
                if (field.isNumberField && (!field.isInputField || field.isCalculated)) {
                    Component.Apex.OutputText OutputText = new Component.Apex.OutputText();
                    OutputText.expressions.value = '{!item[' + fieldName + ']}';
                    OutputText.expressions.styleClass = '{!item.Id}_' + field.fieldName + ' slds-text-align_right noCurrencyCode';
                    OutputText.Id = 'noCurrencyCode-' + field.fieldName;
                    column.childComponents.add(OutputText);
                }
                if (!field.isNumberField && field.fieldName != SObjectType.PriceListStatementDetail__c.fields.Product__c.Name /***&& field.fieldName != SObjectType.PriceListStatementDetail__c.fields.Additionnal_Product__c.Name***/ && (!field.isInputField || field.isCalculated)) {
                    if (field.stringFieldType == 'REFERENCE' || field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'BOOLEAN' || field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME' || field.stringFieldType == 'TIME' || field.isCalculated) {
                        Component.Apex.OutputPanel outputpanel = new Component.Apex.OutputPanel();
                        outputpanel.layout = 'block';
                        outputpanel.expressions.styleClass = '{!item.Id}_' + field.fieldName + ' slds-m-around_small' + (field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME' ? 'dateInput' : '');
                        Component.Apex.OutputField outputfield = new Component.Apex.OutputField();
                        outputfield.expressions.value = '{!item[' + fieldName + ']}';
                        outputpanel.childComponents.add(outputfield);
                        column.childComponents.add(outputpanel);
                    } else {
                        Component.Apex.OutputText outputText = new Component.Apex.OutputText();
                        outputText.expressions.value = '{!item[' + fieldName + ']}';
                        outputText.expressions.styleClass = '{!item.Id}_' + field.fieldName + ' slds-m-around_small';
                        column.childComponents.add(outputText);
                    }
                }
            }

            if (field.isInputField && !field.isCalculated && field.stringFieldType != 'TEXTAREA') {
                if (field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME') {

                    /*<apex:input label="datePicker" value="{!searchDateMain}" type="date" styleClass="inputNoEnter slds-input"
                    style="width: 100% !important; text-align: left;"
                    html-placeholder="{!$ObjectType.Sell_in_Flow__c.fields.Invoice_Date__c.Label}" onkeypress="enterPress(event);" />
                    */
                    Component.Apex.Input input = new Component.Apex.Input();
                    input.expressions.value = '{!item[' + fieldName + ']}';
                    input.expressions.styleClass = 'input-date inputNoEnter {!item.Id}_' + field.fieldName + ' ' + field.fieldName + (field.isNumberField ? ' slds-text-align_right ' : '' ) + (field.stringFieldType != 'BOOLEAN' && field.stringFieldType != 'REFERENCE' ? ' slds-input ': '');
                    input.expressions.onblur = 'updateTotals(this, ' + fieldName + ', "{!item.Id}", "{!group.categoryId}", "{!item.PriceListStatement__c}")';
                    input.type = 'date';
                    column.childComponents.add(input);
                } else {
                    Component.Apex.InputField inputField = new Component.Apex.InputField();
                    inputField.expressions.value = '{!item[' + fieldName + ']}';
                    if (field.stringFieldType != 'BOOLEAN') {
                        inputField.style = field.widthStyle;
                    }
                    inputField.expressions.styleClass = 'inputNoEnter {!item.Id}_' + field.fieldName + ' ' + field.fieldName + (field.isNumberField ? ' slds-text-align_right ' : '' ) + (field.stringFieldType != 'BOOLEAN' && field.stringFieldType != 'REFERENCE' ? ' slds-input ': '');
                    inputField.expressions.onchange = 'updateTotals(this, ' + fieldName + ', "{!item.Id}", "{!group.categoryId}", "{!item.PriceListStatement__c}")';
                    column.childComponents.add(inputField);
                }
            }

            if (field.isInputField && !field.isCalculated && field.stringFieldType == 'TEXTAREA') {
                Component.Apex.InputTextarea inputField = new Component.Apex.InputTextarea();
                inputField.rows = 1;
                inputField.expressions.value = '{!item[' + fieldName + ']}';
                inputField.style = field.widthStyle;
                inputField.expressions.styleClass = 'inputNoEnter slds-textarea {!item.Id}_' + field.fieldName + ' ' + field.fieldName ;
                inputField.expressions.onchange = 'updateTotals(this, ' + field.fieldName + ', "{!item.Id}", "{!group.categoryId}", "{!item.PriceListStatement__c}")';

                column.childComponents.add(inputField);

            }

            // add hidden input to keep first loaded value
            Component.Apex.OutputText hidden = new Component.Apex.OutputText();
            hidden.expressions.styleClass = '{!item.Id}initial' + field.fieldName;
            hidden.expressions.value = '{!IF(item["' + field.fieldName + '"] == null, 0, item["' + field.fieldName + '"])}';
            hidden.style = 'display:none';
            column.childComponents.add(hidden);

            return column;
        }

        public Component.Apex.Column getLogoColumn(GridSettingsManager.FieldWrapper field) {
            Component.Apex.Column column = new Component.Apex.Column();
            column.expressions.styleClass = 'dataCell wrap-td slds-border_left text-center cell_{!item.Id}_' + field.fieldName + (field.isNumberField ? ' slds-text-align_right ' : '');
            if (String.isNotBlank(field.bgColor)) {
                column.style = 'background-color: ' + field.bgColor + ';';
            }
            column.headerClass = 'text-center headerRow';
            column.headerValue = field.fieldLabel;
            String fieldName = '"' + field.fieldName + '"';
            Component.Apex.OutputText outputText = new Component.Apex.OutputText();
            outputText.expressions.value = '{!item[' + fieldName + ']}';
            //outputText.expressions.styleClass = '{!item.Id}_' + field.fieldName;
            outputText.expressions.styleClass = '{!item.Id}' + field.fieldName;
            outputText.escape = false;
            column.childComponents.add(outputText);
            return column;
        }
    }

    // generate Excel
    public String ExcelFullUrl {
        get {
            /***PageReference pageRef = Page.PriceListStatementExportExcel;
            pageRef.getParameters().put('Id', this.recordID);
            pageRef.getParameters().put('layout', this.priceListStatementMatrixGridLayout);
            pageRef.getParameters().put('isExport', 'true');
            pageRef.getParameters().put('isLite', 'false');
            return pageRef.getUrl();***/
            return null;
        }
    }

    // generate Excel lite
    public String ExcelLiteUrl {
        get {
            /***PageReference pageRef = Page.PriceListStatementExportExcel;
            pageRef.getParameters().put('Id', this.recordID);
            pageRef.getParameters().put('layout', this.priceListStatementMatrixGridLayout);
            pageRef.getParameters().put('isExport', 'true');
            pageRef.getParameters().put('isLite', 'true');
            return pageRef.getUrl();***/
            return null;
        }
    }

    // generate CSV
    public String CSVURL {
        get {
            /***PageReference pageRef = Page.PriceListStatementExportExcel;
            pageRef.getParameters().put('Id', this.recordID);
            pageRef.getParameters().put('layout', this.priceListStatementMatrixGridLayout);
            pageRef.getParameters().put('isExport', 'true');
            pageRef.getParameters().put('isLite', 'false');
            return pageRef.getUrl();***/
            return null;
        }
    }

    public List<PriceListStatementDetail__c> exportedData { get { return this.exportDataLazyStandardSetController.getRecords(); } set; }
    public ApexPages.StandardSetController exportDataLazyStandardSetController { get; set; }

    public void loadMore() {
        if (this.exportDataLazyStandardSetController.getHasNext()) {
            this.exportDataLazyStandardSetController.next();
        } else {
            isDoneLoading = true;
        }
    }

    public void prepareDataToExport(Boolean isLite) {
        this.isDoneLoading = false;
        Integer exportPageSize = 1000;
        delimiter = this.localeDecimalSeparator == ',' ? ';' : ',';
        String query = this.buildPriceStatementDetailsQuery();
        this.exportDataLazyStandardSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        this.exportDataLazyStandardSetController.setPageSize(exportPageSize);
        this.categoryNamesMap = new Map<Id, String>();
        for (PriceListStatementDetail__c item : this.exportedData) {
            if (!this.categoryNamesMap.containsKey(item.Hierarchy__c)) {
                this.categoryNamesMap.put(item.Hierarchy__c, item.Hierarchy__r.LongName1__c != null ? item.Hierarchy__r.LongName1__c : item.Hierarchy__r.Name);
            }
        }
    }

    /**
     * Show Import Popup
     */
    public void displayImportPopUp() {
        try {
            this.displayUploadpopup = true;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
    }

    public void closeImportPopUp() {
        this.displayUploadpopup = false;
        this.search();
    }

    public PageReference search() {
        this.priceListStatementStdSetCtrl = new ApexPages.StandardSetController(new List<PriceListStatementDetail__c>());
        String query = this.buildPriceStatementDetailsQuery();
        String[] priceListStatementDetailsFields = new String[] {};
        for (String field : this.gridSettingsManager.ALL_FIELDS) {
            if (!field.contains('.')) priceListStatementDetailsFields.add(getFieldName(field));
        }
        if (checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailsFields)) {
            this.priceListStatementStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        }
        this.noOfRecords = this.priceListStatementStdSetCtrl.getResultSize();
        this.priceListStatementStdSetCtrl.setPageSize(this.pageSize);
        this.fillCategoryTotals();
        this.getHierarchies();
        this.jsonCategoryTree = JSON.serialize(this.categoryTreeMap.values());
        getPriceListStatementDetails();
        return null;
    }

    /**
     * @description resets search filters
     */
    public PageReference resetFilters() {
        this.searchTerm = '';
        return this.search();
    }

    public void first() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.priceListStatementStdSetCtrl.first();
        this.getPriceListStatementDetails();
    }

    public void previous() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.priceListStatementStdSetCtrl.previous();
        this.getPriceListStatementDetails();
    }

    public void next() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.priceListStatementStdSetCtrl.next();
        this.getPriceListStatementDetails();
    }

    public void last() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.priceListStatementStdSetCtrl.last();
        this.getPriceListStatementDetails();
    }

    public void refreshPageSize() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.priceListStatementStdSetCtrl.setPageSize(this.pageSize);
        this.getPriceListStatementDetails();
    }

    private String buildPriceStatementDetailsQuery() {
        List<String> innerQueries = new List<String>();
        List<String> conditions = this.getConditions();
        String orderBy = 'Hierarchy__r.Path__c, Name';
        String query = this.gridSettingsManager.buildQuery(innerQueries, conditions, orderBy);
        system.debug('query >>>' + query);
        return query;
    }

    private List<String> getConditions() {
        List<String> conditions = new List<String>();
        conditions.add('Hierarchy__c <> NULL');
        /***conditions.add('Is_switched__c = FALSE');***/
        if (String.isNotBlank(this.recordId))
            conditions.add('PriceListStatement__c = \'' + String.escapeSingleQuotes(this.recordId) + '\'');
        if (String.isNotBlank(this.searchTerm)) {
            String searchString = String.escapeSingleQuotes(this.searchTerm);
            List<String> conditionsLines = new List<String>();
            Map<String, List<DescribeFieldResult>> objectFieldMap = new Map<String, List<DescribeFieldResult>>();
            objectFieldMap.put('', new List<DescribeFieldResult>{SObjectType.PriceListStatementDetail__c.fields.Name});
            objectFieldMap.put('Product__r.', new List<DescribeFieldResult>{SObjectType.Product2.fields.Name, SObjectType.Product2.fields.Product_EAN__c, SObjectType.Product2.fields.ProductCode});
            objectFieldMap.put('Product__r.Category__r.', new List<DescribeFieldResult>{SObjectType.Hierarchy__c.fields.Name});
            /***objectFieldMap.put('Additionnal_Product__r.', new List<DescribeFieldResult>{SObjectType.Product_Competitor__c.fields.Name, SObjectType.Product_Competitor__c.fields.Product_EAN__c, SObjectType.Product_Competitor__c.fields.Product_Code__c});***/
            /***objectFieldMap.put('Additionnal_Product__r.Hierarchy__r.', new List<DescribeFieldResult>{SObjectType.Hierarchy__c.fields.Name});***/
            conditions.add(getFieldCondition(objectFieldMap, searchString, ' OR '));
        }

        return conditions;
    }
    private String getFieldCondition(Map<String, List<DescribeFieldResult>> objectFieldMap, String searchTerm, String separator) {
        String condition = '';
        List<String> conditionsLines = new List<String>();
        for (String relationNamePrefix : objectFieldMap.keySet()) {
            for (DescribeFieldResult objectField : objectFieldMap.get(relationNamePrefix)) {
                condition = getFieldCondition(objectField, searchTerm, relationNamePrefix);
                if (!String.isEmpty(condition)) conditionsLines.add(condition);
            }
        }
        return '( ' + String.join(conditionsLines, separator) + ' )';
    }
    private String getFieldCondition(DescribeFieldResult objectField, String searchString, String relationNamePrefix) {
        String condition = '';
        if (objectField.isFilterable()) {
            if (!objectField.isEncrypted()) {
                condition += ' ' + relationNamePrefix + objectField.getName() + ' LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
            } else {
                condition += ' ' + relationNamePrefix + objectField.getName() + ' = \'' + String.escapeSingleQuotes(searchTerm) + '\'';
            }
        }
        return condition;
    }

    /**
     * @param conditions
     * @description constructs the where clause of an SOQL query by returning 'WHERE' followed by each condition in conditions seperated by 'AND'
     * @return String a well structured WHERE clause
     */
    private String buildWhere(List<String> conditions) {
        return ' WHERE ' + String.join(conditions, ' AND ');
    }

    public void getPriceListStatementDetails() {
        Set<Id> categoryIds = new Set<Id>();
        this.disbledRows = new Set<String>();
        this.categoryWrapperMap_KeySet = new List<Id>();
        this.wPriceListStatementDetailsCategoryList = new List<CategoryWrapper>();
        this.initialPriceListStatementDetailsMap = new Map<Id, PriceListStatementDetail__c>();
        this.categoryWrapperMap = new Map<Id, CategoryWrapper>();
        List<PriceListStatementDetail__c> priceListStatementDetailsList = (List<PriceListStatementDetail__c>) this.priceListStatementStdSetCtrl.getRecords();
        Map<String, PriceListStatementDetail__c> historyPriceListDetailMap = new Map<String, PriceListStatementDetail__c>();
        List<String> conditionsLines = new List<String>();
        /***conditionsLines.add('Is_switched__c = TRUE');***/
        if (String.isNotBlank(this.recordId))
        conditionsLines.add('PriceListStatement__c = \'' + String.escapeSingleQuotes(this.recordId) + '\'');
        String histoQuery = this.gridSettingsManager.buildQuery(null, conditionsLines,'');
        // System.debug(' histoQuery >>> ' + histoQuery);
        // try {
            for (PriceListStatementDetail__c hsito : Database.query(histoQuery)) {
                historyPriceListDetailMap.put(hsito.Id, hsito);
                disbledRows.add(hsito.Id);
            }
        // } catch(Exception ex) {

        // }
        if (!priceListStatementDetailsList.isEmpty()) {
            for (PriceListStatementDetail__c item : priceListStatementDetailsList) {
                if (item.Hierarchy__c == null) continue;
                categoryIds.add(item.Hierarchy__c);
                this.initialPriceListStatementDetailsMap.put(item.Id, item);
                PriceListStatementDetail__c initialPriceListStatementDetail = item.Clone(true);
                CategoryWrapper wCategory;
                // fill category wrapper
                initialPriceListStatementDetail = fillPriceListStatementCategory(initialPriceListStatementDetail);
                if (!categoryWrapperMap.containsKey(initialPriceListStatementDetail.Hierarchy__c)) {
                    wCategory = new CategoryWrapper(initialPriceListStatementDetail.Hierarchy__c, initialPriceListStatementDetail.Hierarchy__r.Name, initialPriceListStatementDetail);
                    if (historyPriceListDetailMap.containsKey(initialPriceListStatementDetail.PriceListStatementDetailLastHistory__c)) {
                        wCategory.priceListStatementDetails.add(historyPriceListDetailMap.get(initialPriceListStatementDetail.PriceListStatementDetailLastHistory__c));
                    }
                } else {
                    wCategory = categoryWrapperMap.get(initialPriceListStatementDetail.Hierarchy__c);
                    wCategory.priceListStatementDetails.add(initialPriceListStatementDetail);
                    if (historyPriceListDetailMap.containsKey(initialPriceListStatementDetail.PriceListStatementDetailLastHistory__c)) {
                        wCategory.priceListStatementDetails.add(historyPriceListDetailMap.get(initialPriceListStatementDetail.PriceListStatementDetailLastHistory__c));
                    }
                }
                if (!categoryWrapperMap.containsKey(initialPriceListStatementDetail.Hierarchy__c)) {
                    categoryWrapperMap.put(initialPriceListStatementDetail.Hierarchy__c, wCategory);
                    this.wPriceListStatementDetailsCategoryList.add(wCategory);
                    this.categoryWrapperMap_KeySet.add(initialPriceListStatementDetail.Hierarchy__c);
                }
                if (!this.categoryNamesMap.containsKey(item.Hierarchy__c)) {
                    this.categoryNamesMap.put(item.Hierarchy__c, item.Hierarchy__r.LongName1__c != null ? item.Hierarchy__r.LongName1__c : item.Hierarchy__r.Name);
                }
            }
            //this.wPriceListStatementDetailsCategoryList = categoryWrapperMap.values();
        }
        this.hasCategories = this.categoryWrapperMap.values().size() > 0;
    }

    public Map<String, Decimal> calculatedRateMap {get; set;}
    private Map<Id, Map<String, Decimal>> totalRatesForCategoryMap = new Map<Id, Map<String, Decimal>>();
    public void calculateRate() {
        // check security on access PriceListStatementDetail__c fields
        String[] priceListStatementDetailsFields = new String[] {
            SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
            /***SObjectType.PriceListStatementDetail__c.fields.SellIn_Total_wUnitGrossPriceGap__c.Name,***/
            /***SObjectType.PriceListStatementDetail__c.fields.SellIn_Total_wUnitGrossPriceP1__c.Name,***/
            SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywGrossPricewNetTaxGap__c.Name,
            /***SObjectType.PriceListStatementDetail__c.fields.SellIn_Total_wGrossPricewNetTaxPrevious__c.Name,***/
            SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPricewNetTaxP1__c.Name,
            SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPricewNetTaxGap__c.Name,
            SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtyTaxesGap__c.Name,
            SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtyTaxesP1__c.Name
        };
        // calculate Depreciation_Rate/Rise_Rate = SUM(SellIn * GrossPriceGap__c)/SUM(Sellin*GrossPriceP1__c)
        Map<String, Map<String, List<Decimal>>> totalRatesToCategoryMap = new Map<String, Map<String, List<Decimal>>>();
        Decimal sellInTotalUnitGap = 0, sellInTotalUnitP1 = 0, sellInTotalwNetTaxGap = 0, sellInTotalwNetTaxP1 = 0, sellInTotalUnitwNetTaxGap = 0, sellInTotalUnitwNetTaxP1 = 0, sellInTotalTaxesGap = 0, sellInTotalTaxesP1 = 0;
        if (NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailsFields)) {
            Decimal costPrice_unit_new_wTax = 0;
            Decimal costPrice_unit_P1_wTax = 0;
            Decimal riseRate_wTax = 0;
            Decimal taxes = 0;
            List<PriceListStatementDetail__c> details = [SELECT Hierarchy__r.Path__c , SellInTotalQty__c , UnitGrossPriceGap__c, UnitGrossPriceP1__c, UnitGrossPrice__c,
                                                            Tax1__c, Tax2__c, Tax3__c, Tax4__c, Tax5__c, Tax6__c, Tax7__c, Tax8__c,
                                                            Tax9__c, Tax10__c, t_NetPriceTaxes__c
                                                            FROM PriceListStatementDetail__c
                                                            WHERE PriceListStatement__c = :this.recordId
                                                            AND Hierarchy__r.Path__c <> NULL /***AND Target_Product_Life_Status__c = 'KEEP'***/
                                                            AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)];
            for (PriceListStatementDetail__c detail : details) {
                for (Integer i = 1; i <= 20; i++) {
                    if (detail.t_NetPriceTaxes__c != null && detail.t_NetPriceTaxes__c.contains('N' + i + '/') && detail.get('Tax_' + i + '__c') != null) {
                        taxes += (Decimal)detail.get('Tax_' + i + '__c');
                    }
                }
                costPrice_unit_new_wTax += (detail.UnitGrossPrice__c != null ? detail.UnitGrossPrice__c : 0) + taxes;
                riseRate_wTax += (detail.UnitGrossPriceP1__c != null && detail.UnitGrossPriceP1__c !=0) ? ((costPrice_unit_new_wTax - detail.UnitGrossPriceP1__c) / detail.UnitGrossPriceP1__c) : 0;
            }
            List<AggregateResult> results = [SELECT Hierarchy__r.Path__c Path__c,
                                             /***SUM(SellIn_Total_wUnitGrossPriceGap__c) SellIn_Total_wUnitGrossPriceGap__c, SUM(SellIn_Total_wUnitGrossPriceP1__c) SellIn_Total_wUnitGrossPriceP1__c,***/
                                             SUM(SellInTotalQtywGrossPricewNetTaxGap__c) SellInTotalQtywGrossPricewNetTaxGap__c, /***SUM(SellIn_Total_wGrossPricewNetTaxPrevious__c) SellIn_Total_wGrossPricewNetTaxPrevious__c,***/
                                             SUM(SellInTotalQtywUnitGrossPricewNetTaxGap__c) SellInTotalQtywUnitGrossPricewNetTaxGap__c, SUM(SellInTotalQtywUnitGrossPricewNetTaxP1__c) SellInTotalQtywUnitGrossPricewNetTaxP1__c,
                                             SUM(SellInTotalQtyTaxesGap__c) SellInTotalQtyTaxesGap__c, SUM(SellInTotalQtyTaxesP1__c) SellInTotalQtyTaxesP1__c
                                             FROM PriceListStatementDetail__c
                                             WHERE PriceListStatement__c = :this.recordId
                                             AND Hierarchy__r.Path__c <> NULL
                                             AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)
                                             GROUP BY Hierarchy__r.Path__c];
            for (AggregateResult item : results) {
                String path = item.get('Path__c') != null ? String.valueOf(item.get('Path__c')) : '';
                if (!totalRatesToCategoryMap.containsKey(path)) {
                    totalRatesToCategoryMap.put(path, new Map<String, List<Decimal>>());
                    totalRatesToCategoryMap.get(path).put('Rate_Calculated__c', new List<Decimal>{0, 0});
                    totalRatesToCategoryMap.get(path).put(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                    totalRatesToCategoryMap.get(path).put(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                    totalRatesToCategoryMap.get(path).put(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name, new List<Decimal>{0, 0});
                }
                Map<String, List<Decimal>> totalsMap = totalRatesToCategoryMap.get(path);
                /***sellInTotalUnitGap += item.get('SellIn_Total_wUnitGrossPriceGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wUnitGrossPriceGap__c'))) : 0;***/
                sellInTotalUnitP1 += item.get('SellIn_Total_wUnitGrossPriceP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wUnitGrossPriceP1__c'))) : 0;
                sellInTotalwNetTaxGap += item.get('SellInTotalQtywGrossPricewNetTaxGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywGrossPricewNetTaxGap__c'))) : 0;
                sellInTotalwNetTaxP1 += item.get('SellIn_Total_wGrossPricewNetTaxPrevious__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wGrossPricewNetTaxPrevious__c'))) : 0;
                sellInTotalUnitwNetTaxGap += item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c'))) : 0;
                sellInTotalUnitwNetTaxP1 += item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c'))) : 0;
                sellInTotalTaxesGap += item.get('SellInTotalQtyTaxesGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtyTaxesGap__c'))) : 0;
                sellInTotalTaxesP1 += item.get('SellInTotalQtyTaxesP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtyTaxesP1__c'))) : 0;
                /***totalsMap.get('Rate_Calculated__c')[0] += item.get('SellIn_Total_wUnitGrossPriceGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wUnitGrossPriceGap__c'))) : 0;***/
                totalsMap.get('Rate_Calculated__c')[1] += item.get('SellIn_Total_wUnitGrossPriceP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wUnitGrossPriceP1__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywGrossPricewNetTaxGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywGrossPricewNetTaxGap__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellIn_Total_wGrossPricewNetTaxPrevious__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellIn_Total_wGrossPricewNetTaxPrevious__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0] += item.get('SellInTotalQtyTaxesGap__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtyTaxesGap__c'))) : 0;
                totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1] += item.get('SellInTotalQtyTaxesP1__c') != null ? Decimal.valueOf(String.valueOf(item.get('SellInTotalQtyTaxesP1__c'))) : 0;
                totalRatesToCategoryMap.put(path, totalsMap);
            }
        }
        Decimal top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.scale);
        Decimal rateCalculated = sellInTotalUnitP1 != 0 ? ((sellInTotalUnitGap / sellInTotalUnitP1) * 100).setScale(2) : 0;
        rateCalculated = (rateCalculated < top && rateCalculated > -top) ? rateCalculated : (rateCalculated > 0 ? top - 1 : -top +1);

        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
        Decimal riseRateCostPricewNetTaxCalculated = sellInTotalwNetTaxP1 != 0 ? ((sellInTotalwNetTaxGap / sellInTotalwNetTaxP1) * 100).setScale(2) : 0;
        riseRateCostPricewNetTaxCalculated = (riseRateCostPricewNetTaxCalculated < top && riseRateCostPricewNetTaxCalculated > -top) ? riseRateCostPricewNetTaxCalculated : (riseRateCostPricewNetTaxCalculated > 0 ? top - 1 : -top + 1);

        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.scale);
        Decimal riseRateCostPriceUnitwNetTaxCalculated = sellInTotalUnitwNetTaxP1 != 0 ? ((sellInTotalUnitwNetTaxGap / sellInTotalUnitwNetTaxP1) * 100).setScale(2) : 0;
        riseRateCostPriceUnitwNetTaxCalculated = (riseRateCostPriceUnitwNetTaxCalculated < top && riseRateCostPriceUnitwNetTaxCalculated > -top) ? riseRateCostPriceUnitwNetTaxCalculated : (riseRateCostPriceUnitwNetTaxCalculated > 0 ? top - 1 : -top + 1);

        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.scale);
        Decimal riseRateTaxCalculated = sellInTotalTaxesP1 != 0 ? ((sellInTotalTaxesGap / sellInTotalTaxesP1) * 100).setScale(2) : 0;
        riseRateTaxCalculated = (riseRateTaxCalculated < top && riseRateTaxCalculated > -top) ? riseRateTaxCalculated : (riseRateTaxCalculated > 0 ? top - 1 : -top + 1);

        this.calculatedRateMap = new Map<String, Decimal> {
            'Rate_Calculated__c' => rateCalculated,
            SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name => riseRateCostPricewNetTaxCalculated,
            SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name => riseRateCostPriceUnitwNetTaxCalculated,
            SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name => riseRateTaxCalculated
        };
        /* commented TODO find good solution to filter orga bu
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id>{NegoptimHelper.getRootIdByRT('Product')});
        // calculate rates for all categories
        if (!het.allElementsList.isEmpty()) {
            for (Hierarchy__c item : het.allElementsList) {
                sellInTotalUnitGap = 0; sellInTotalUnitP1 = 0; sellInTotalwNetTaxGap = 0; sellInTotalwNetTaxP1 = 0; sellInTotalUnitwNetTaxGap = 0; sellInTotalUnitwNetTaxP1 = 0; sellInTotalTaxesGap = 0; sellInTotalTaxesP1 = 0;
                for (String categoryKey : totalRatesToCategoryMap.KeySet()) {
                    if (categoryKey.startsWith(item.Path__c)) {
                        Map<String, List<Decimal>> totalsMap = totalRatesToCategoryMap.get(categoryKey);
                        sellInTotalUnitGap += totalsMap.get('Rate_Calculated__c')[0];
                        sellInTotalUnitP1 += totalsMap.get('Rate_Calculated__c')[1];
                        sellInTotalwNetTaxGap += totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0];
                        sellInTotalwNetTaxP1 += totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1];
                        sellInTotalUnitwNetTaxGap += totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0];
                        sellInTotalUnitwNetTaxP1 += totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1];
                        sellInTotalTaxesGap += totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0];
                        sellInTotalTaxesP1 += totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1];
                    }
                }
                top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.scale);
                rateCalculated = sellInTotalUnitP1 != 0 ? ((sellInTotalUnitGap/sellInTotalUnitP1)*100).setScale(2) : 0;
                rateCalculated = (rateCalculated < 1000 && rateCalculated > -1000) ? rateCalculated : (rateCalculated > 0 ? 999 : -999);

                top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                riseRateCostPricewNetTaxCalculated = sellInTotalwNetTaxP1 != 0 ? ((sellInTotalwNetTaxGap/sellInTotalwNetTaxP1)*100).setScale(2) : 0;
                riseRateCostPricewNetTaxCalculated = (riseRateCostPricewNetTaxCalculated < 1000 && riseRateCostPricewNetTaxCalculated > -1000) ? riseRateCostPricewNetTaxCalculated : (riseRateCostPricewNetTaxCalculated > 0 ? 999 : -999);

                top = (10.0).pow(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.scale);
                riseRateCostPriceUnitwNetTaxCalculated = sellInTotalUnitwNetTaxP1 != 0 ? ((sellInTotalUnitwNetTaxGap/sellInTotalUnitwNetTaxP1)*100).setScale(2) : 0;
                riseRateCostPriceUnitwNetTaxCalculated = (riseRateCostPriceUnitwNetTaxCalculated < 1000 && riseRateCostPriceUnitwNetTaxCalculated > -1000) ? riseRateCostPriceUnitwNetTaxCalculated : (riseRateCostPriceUnitwNetTaxCalculated > 0 ? 999 : -999);


                top = (10.0).pow(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.scale);
                riseRateTaxCalculated = sellInTotalTaxesP1 != 0 ? ((sellInTotalTaxesGap/sellInTotalTaxesP1)*100).setScale(2) : 0;
                riseRateTaxCalculated = (riseRateTaxCalculated < 1000 && riseRateTaxCalculated > -1000) ? riseRateTaxCalculated : (riseRateTaxCalculated > 0 ? 999 : -999);

                totalRatesForCategoryMap.put(item.Id, new Map<String, Decimal> {
                    'Rate_Calculated__c' => rateCalculated,
                     SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name => riseRateCostPricewNetTaxCalculated,
                     SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name => riseRateCostPriceUnitwNetTaxCalculated,
                     SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name => riseRateTaxCalculated
               });
            }
        }
        */
    }

    private PriceListStatementDetail__c fillPriceListStatementCategory(PriceListStatementDetail__c item) {
        // check if price list statement detail already updated
        if (this.priceListStatementDetailsUpdatedMap.containsKey(item.Id)) {
            PriceListStatementDetail__c updatedPriceListStatementCategory = this.priceListStatementDetailsUpdatedMap.get(item.Id);
            item = updatedPriceListStatementCategory.clone(true);
        }
        return item;
    }

    private void fillCategoryTotals() {
        this.categorySet.clear();
        this.categoryPathSet.clear();
        this.counts.clear();
        this.sums.clear();
        String[] priceListStatementFields = new String[] { };
        List<String> sumAggregations = new List<String>();
        for (String field : this.fieldsToSumList) {
            if (!priceListStatementFields.contains(field)) priceListStatementFields.add(field);
            String field_escaped = String.escapeSingleQuotes(field);
            sumAggregations.add('SUM(' + field_escaped + ') ' + field_escaped);
        }
        String aggregateQuery = 'SELECT Hierarchy__c Category__c, Hierarchy__r.Path__c Path__c';
        if (!sumAggregations.isEmpty()) aggregateQuery += ',' + String.join(sumAggregations, ',');
        aggregateQuery += ' FROM PriceListStatementDetail__c';
        List<String> conditions = this.getConditions();
        aggregateQuery += this.buildWhere(conditions);
        aggregateQuery += ' Group By Hierarchy__c, Hierarchy__r.Path__c';
        // to garantee that all categories are in counts and sums maps
        if (checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementFields)) {
            for (AggregateResult item : Database.query(aggregateQuery)) {
                Id categoryId = (Id) item.get('Category__c');
                if (categoryId == null) continue;
                initTotals(categoryId);
                Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
                if (categorySumMap != null) {
                    for (String fieldname : categorySumMap.keySet()) {
                        Decimal value = item.get(fieldname) != null ? Decimal.valueOf(String.valueOf((item.get(fieldname)))) : 0;
                        categorySumMap.put(fieldname, value);
                    }
                    this.categorySet.add(categoryId);
                    this.categoryPathSet.add(String.valueOf(item.get('Path__c')));
                }
            }
            // fill counts by category
            // querying counts (24 aggregate queries)
            List<Map<String, List<AggregateResult>>> aggregateMapList = new List<Map<String, List<AggregateResult>>>();
            String key;
            List<AggregateResult> value;

            for (String field : this.fieldsToCountList) {
                value = this.getCountByCategory(field);
                aggregateMapList.add(new Map<String, List<AggregateResult>> {field => value});
            }
            for (Map<String, List<AggregateResult>> item : aggregateMapList) {
                for (String fieldname : item.keySet()) {
                    for (AggregateResult ar : item.get(fieldname)) {
                        Id categoryId = (Id) String.valueOf(ar.get('Category__c'));
                        Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                        Integer count = ar.get(fieldname) != null ? Integer.valueOf(String.valueOf(ar.get(fieldname))) : 0;
                        categoryCountMap.put(fieldname, count);
                        this.categorySet.add(categoryId);
                        this.categoryPathSet.add(String.valueOf(item.get('Path__c')));
                    }
                }
            }
        }
    }
    private List<AggregateResult> getCountByCategory(String fieldName) {
        String fieldName_escaped = String.escapeSingleQuotes(fieldName);
        String[] priceListStatementFields = new String[] { fieldName_escaped };
        if (checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementFields)) {
            String query = 'SELECT Hierarchy__c Category__c, Hierarchy__r.Path__c Path__c, COUNT(Id) ' + fieldName_escaped + ' FROM PriceListStatementDetail__c ';
            List<String> conditions = this.getConditions();
            conditions.add(fieldName_escaped + ' = TRUE');
            query += this.buildWhere(conditions);
            query += ' Group BY Hierarchy__c, Hierarchy__r.Path__c';
            return Database.query(query);}
        else{return null;}
    }

    private void initTotals (Id categoryId) {
        Map<String, Integer> categoryCountMap = new Map<String, Integer>();
        Map<String, Decimal> categorySumMap = new Map<String, Decimal>();
        // initial Count fields
        for (String str : this.fieldsToCountList) {
            categoryCountMap.put(str, 0);
        }
        // initial Sums fields
        for (String str : this.fieldsToSumList) {
            categorySumMap.put(str, 0);
        }
        this.counts.put(categoryId, categoryCountMap);
        this.sums.put(categoryId, categorySumMap);
    }

    // Get category hierarchies
    public void getHierarchies() {
        calculateRate();
        this.categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
        Map<Id, Hierarchy__c> parentCategories = new Map<Id, Hierarchy__c>();
        Set<Id> relatedCategoryIds = new Set<Id>();
        Map<Id, Id> parentChildMap = new Map<Id, Id>();
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id>{NegoptimHelper.getRootIdByRT('Product')});
        if (!het.allElementsList.isEmpty()) {
            Map<Id, Boolean> existCategoryLevelMap = new Map<Id, Boolean>();
            for (Hierarchy__c item : het.allElementsList) {
                for (String categoryKey : categoryPathSet) {
                    if (categoryKey != null && categoryKey.startsWith(item.Path__c)) {
                        existCategoryLevelMap.put(item.Id, true);
                        break;
                    }
                }
                if (!existCategoryLevelMap.containsKey(item.Id)) continue;
                fillParentCategoriesTotal(item.HierarchyParent__c, item.Id);
            }
            // navigate inversely from top level
            Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Hierarchy__c item = het.allElementsList.get(i);
                if (item.Level__c != rootLevel && !existCategoryLevelMap.containsKey(item.Id)) continue;
                CategoryTreeWrapper node = new CategoryTreeWrapper();
                CategoryTreeWrapper parentNode = hierarchyTree.get(item.HierarchyParent__c);
                node.title = item.Level__c == rootLevel ? 'TOTAL' : item.Name;
                node.key = item.Id;
                node.folder = item.Level__c <= rootLevel + 1;
                node.counts = this.counts.get(item.Id);
                node.sums = this.sums.get(item.Id);
                if (parentNode != null) {
                    node.path = parentNode.path + '' + item.Id;
                    node.parentId = item.HierarchyParent__c;
                } else {
                    node.path = item.Id;
                    this.categoryTreeMap.put(item.Id, node);
                }
                if (this.totalRatesForCategoryMap.containsKey(item.Id)) {
                    node.rateCalculated = this.totalRatesForCategoryMap.get(item.Id).get('Rate_Calculated__c');
                    node.riseRateCostPricewNetTaxCalculated = this.totalRatesForCategoryMap.get(item.Id).get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name);
                    node.riseRateCostPriceUnitwNetTaxCalculated = this.totalRatesForCategoryMap.get(item.Id).get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name);
                    node.riseRateTaxCalculated = this.totalRatesForCategoryMap.get(item.Id).get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name);
                }
		    if (this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Iso_Partner_12M') && item.Level__c == rootLevel) {
                    node.rateCalculated = this.priceListStatement.PriceListStatementReference__r.RecordTypeId == this.priceListStatementRTIds.get('Depreciation_Rate') ? this.priceListStatement.PriceEvolutionRateCalculated__c : this.priceListStatement.PriceEvolutionRateCalculated__c;
                    node.riseRateCostPricewNetTaxCalculated = this.priceListStatement.PriceEvolutionRateInclTaxCalculated__c;
                    node.riseRateCostPriceUnitwNetTaxCalculated = this.priceListStatement.UnitPriceEvolutionRateInclTaxCalculated__c;
                    node.riseRateTaxCalculated = this.priceListStatement.TaxEvolutionRateCalculated__c;
                }
                hierarchyTree.put(item.Id, node);
            }
            for (Hierarchy__c item : het.allElementsList) {
                if (item.Level__c != rootLevel && !existCategoryLevelMap.containsKey(item.Id)) continue;
                if (hierarchyTree.containsKey(item.HierarchyParent__c)) {
                    hierarchyTree.get(item.HierarchyParent__c).children.add(hierarchyTree.get(item.Id));
                }
            }
        }
    }

    private void fillParentCategoriesTotal(Id parentCategoryId, Id subCategoryId) {
        if (!this.counts.containsKey(parentCategoryId)) {
            initTotals(parentCategoryId);
        }
        if (!this.counts.containsKey(subCategoryId)) {
            initTotals(subCategoryId);
        }
        // fill total sum
        Map<String, Decimal> parentCategorySumMap = this.sums.get(parentCategoryId);
        Map<String, Decimal> subCategorySumMap = this.sums.get(subCategoryId);
        for (String fieldname : parentCategorySumMap.keySet()) {
            Decimal total = parentCategorySumMap.get(fieldname) != null ? parentCategorySumMap.get(fieldname) : 0;
            Decimal value = subCategorySumMap.get(fieldname) != null ? subCategorySumMap.get(fieldname) : 0;
            parentCategorySumMap.put(fieldname, total + value);
        }
        // fill total count
        Map<String, Integer> parentCategoryCountMap = this.counts.get(parentCategoryId);
        Map<String, Integer> subCategoryCountMap = this.counts.get(subCategoryId);
        for (String fieldname : parentCategoryCountMap.keySet()) {
            Integer total = parentCategoryCountMap.get(fieldname) != null ? parentCategoryCountMap.get(fieldname) : 0;
            total = total + (subCategoryCountMap.get(fieldname) != null ? subCategoryCountMap.get(fieldname) : 0);
            parentCategoryCountMap.put(fieldname, total);
        }
    }

    public PageReference save() {
        Boolean hasChangedHeader = false, hasChangedDetails = false;
        this.processAfterUpdate(this.processBeforeUpdate().values());
        Map<Id, PriceListStatementDetail__c> updatedResultsMap = this.priceListStatementDetailsUpdatedMap;
        Savepoint sp = Database.setSavepoint();
        String[] priceListStatementDetailsFields = new String[]{};
        for (String fieldName : fieldsInputList){
            priceListStatementDetailsFields.add(fieldName);
        }
        try {
            if (!updatedResultsMap.isEmpty()) {
                hasChangedDetails = true;
                if (NegoptimHelper.checkUpdatibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailsFields)) {
                    List<Database.SaveResult> results = Database.update(updatedResultsMap.values(), false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        PriceListStatementDetail__c priceListStatementDetail = updatedResultsMap.values().get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = /***priceListStatementDetail.Product_Name__c +***/ ' : ';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                if (!err.getFields().isEmpty() && err.getFields().contains('SPITM_New_Product_Statement_Date__c')) {

                                } else {
                                    String msg = err.getStatusCode() != null ? '' + err.getStatusCode() : '';
                                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                        //errorMessage += err.getMessage();
                                    } else {
                                        errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                    }
                                }
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                            }
                        }
                    }
                }
                // clear updated record
                this.priceListStatementDetailsUpdatedMap.clear();
                this.search();
            }
            // update priceListStatement
            /*if (this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Depreciation_Rate')) {
                if (this.priceListStatement.PriceEvolutionRateCalculated__c != this.calculatedRateMap.get('Rate_Calculated__c')) {
                    this.priceListStatement.PriceEvolutionRateCalculated__c = this.calculatedRateMap.get('Rate_Calculated__c');
                    hasChangedHeader = true;
                }
            }
            if (this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Rise_Rate') ||
                (this.priceListStatementRTIds.containskey('Tariff') && this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Tariff')) ||
                this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Iso_Partner_12M') ||
                this.priceListStatement.RecordTypeId == this.priceListStatementRTIds.get('Simulation'))
            {
                if (this.priceListStatement.PriceEvolutionRateCalculated__c != this.calculatedRateMap.get('Rate_Calculated__c')) {
                    this.priceListStatement.PriceEvolutionRateCalculated__c = this.calculatedRateMap.get('Rate_Calculated__c');
                    hasChangedHeader = true;
                }
                if (this.priceListStatement.PriceEvolutionRateInclTaxCalculated__c != this.calculatedRateMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)) {
                    this.priceListStatement.PriceEvolutionRateInclTaxCalculated__c = this.calculatedRateMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name);
                    hasChangedHeader = true;
                }
                if (this.priceListStatement.TaxEvolutionRateCalculated__c != this.calculatedRateMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)) {
                    this.priceListStatement.TaxEvolutionRateCalculated__c = this.calculatedRateMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name);
                    hasChangedHeader = true;
                }
                if (hasChangedHeader) {
                    // check security on access PriceListStatement__c fields
                    String[] priceListStatementDetailsUpdateFields = new String[] {
                        SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                        SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                        SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name,
                        SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(PriceListStatement__c.SObjectType, priceListStatementDetailsUpdateFields)) {
                        Database.update(this.priceListStatement);
                    }
                }
            }*/
            if (hasChangedHeader || hasChangedDetails) {
                if (!ApexPages.hasMessages()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_Nothing_To_Update));
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
        } catch (Exception ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
            System.debug('Error:' + ex.getMessage() + ' - ' + ex.getLineNumber());
        }
        return null;
    }

    @RemoteAction
    public static String calculate(String priceListStatementDetail_JSON, List<String> fieldsToSumList, List<String> logoFieldsList, List<String> fieldsInputList) {
        PriceListStatementDetail__c priceListStatementDetail = (PriceListStatementDetail__c)JSON.deserialize(priceListStatementDetail_JSON, PriceListStatementDetail__c.class);
        System.SavePoint sp = Database.setSavepoint();
        String errorMessage;
        String returnObjJson;
        try {
            String[] priceListStatementFields = new String[]{};
            for (String fieldName : fieldsInputList) {
                priceListStatementFields.add(fieldName);
            }
            /*List<PriceListStatementDetail__c> priceListStatementDetails = new List<PriceListStatementDetail__c>{priceListStatementDetail};
            List<FormulaRecalcResult> results = Formula.recalculateFormulas(priceListStatementDetails);
            return JSON.serialize(results[0].getSObject());*/
            if (NegoptimHelper.checkUpdatibility(PriceListStatementDetail__c.SObjectType, priceListStatementFields)) {
                Database.SaveResult result = Database.update(priceListStatementDetail, false);
                if (!result.isSuccess()) {
                    /*errorMessage = '';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getMessage() + '\n';
                    }*/
                    errorMessage = /***priceListStatementDetail.Product_Name__c +***/ ' : ';
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        if (!err.getFields().isEmpty() && err.getFields().contains('SPITM_New_Product_Statement_Date__c')) {
                            errorMessage += err.getMessage();
                        } else {
                            String msg = err.getStatusCode() != null ? '' + err.getStatusCode() : '';
                            if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                errorMessage += err.getMessage();
                            } else {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                    }
                }
            }
            if (String.isBlank(errorMessage) && NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementFields)) {
                String query = 'SELECT Id, PriceListStatement__c, Hierarchy__c';
                if (!fieldsToSumList.isEmpty() && fieldsToSumList != null) {
                    query += ',' + String.join(fieldsToSumList, ',');
                }
                if (!logoFieldsList.isEmpty() && logoFieldsList != null) {
                    query += ',' + String.join(logoFieldsList, ',');
                }
                query += ' FROM PriceListStatementDetail__c';
                query += ' WHERE Id = \'' + priceListStatementDetail.Id + '\'';
                PriceListStatementDetail__c savedRecord = Database.query(query);
                returnObjJson = JSON.serialize(savedRecord);
            }
        } catch (DmlException ex) {
            errorMessage = ex.getDmlMessage(0);
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        Database.rollback(sp);
        return String.isNotBlank(errorMessage) ? errorMessage : returnObjJson;
    }

    /**
     * @description checks if the record has changed since it has been loaded
     * by comparing it with it's clone created on load
     * */
    private boolean hasChanged(PriceListStatementDetail__c initialRecord, PriceListStatementDetail__c updatedRecord) {
        if (initialRecord == null || updatedRecord == null) {
            return false;
        }
        Map<String, Object> initialValues = initialRecord.getPopulatedFieldsAsMap();
        Map<String, Object> updatedValues = updatedRecord.getPopulatedFieldsAsMap();
        for (String key: updatedValues.keySet()) {
            if (initialValues.get(key) != updatedValues.get(key)) {
                return true;
            }
        }
        return false;
    }

    private Map<Id, PriceListStatementDetail__c> processBeforeUpdate() {
        Map<Id, PriceListStatementDetail__c> updatedResultsMap = new Map<Id, PriceListStatementDetail__c>();
        for (CategoryWrapper item : this.categoryWrapperMap.values()) {
            for (PriceListStatementDetail__c detail : item.priceListStatementDetails) {
                /***if (detail.Is_switched__c) continue;***/
                PriceListStatementDetail__c priceListStatementDetail;
                if (this.priceListStatementDetailsUpdatedMap.containsKey(detail.Id)) {
                    priceListStatementDetail = this.priceListStatementDetailsUpdatedMap.get(detail.Id);
                } else {
                    priceListStatementDetail = this.initialPriceListStatementDetailsMap.get(detail.Id);
                }
                // fill updated priceListStatement details
                if (hasChanged(priceListStatementDetail, detail)) {
                    updatedResultsMap.put(detail.Id, detail);
                }
            }
        }
        return updatedResultsMap;
    }

    private void processAfterUpdate(List<PriceListStatementDetail__c> updatedResults) {
        if (!updatedResults.isEmpty()) {
            Map<Id, PriceListStatementDetail__c> updatedResultsMap = new Map<Id, PriceListStatementDetail__c>();
            for (PriceListStatementDetail__c item : updatedResults) {
                updatedResultsMap.put(item.Id, item);
            }
            // fill total after update formula
            for (CategoryWrapper item : this.categoryWrapperMap.values()) {
                Id categoryId = item.categoryId;
                Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
                for (PriceListStatementDetail__c detail : item.priceListStatementDetails) {
                    PriceListStatementDetail__c currentPriceListStatementDetail, oldPriceListStatementDetail;
                    if (updatedResultsMap.containsKey(detail.Id)) {
                        currentPriceListStatementDetail = updatedResultsMap.get(detail.Id);
                        if (this.priceListStatementDetailsUpdatedMap.containsKey(detail.Id)) {
                            oldPriceListStatementDetail = this.priceListStatementDetailsUpdatedMap.get(detail.Id);
                        } else {
                            oldPriceListStatementDetail = this.initialPriceListStatementDetailsMap.get(detail.Id);
                        }
                        // add record to map
                        PriceListStatementDetail__c clonedItem = currentPriceListStatementDetail.clone(true, true, true, true);
                        this.priceListStatementDetailsUpdatedMap.put(currentPriceListStatementDetail.Id, clonedItem);
                    }
                }
            }
        }
    }

    /** Wrapper class for Category Tree. */
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Integer> counts {get; set;}
        private Map<String, Decimal> sums {get; set;}
        private Decimal rateCalculated {get; set;}
        private Decimal riseRateCostPriceUnitCalculated {get; set;}
        private Decimal riseRateCostPricewNetTaxCalculated {get; set;}
        private Decimal riseRateCostPriceUnitwNetTaxCalculated {get; set;}
        private Decimal riseRateTaxCalculated {get; set;}

        public CategoryTreeWrapper() {
            this.children = new List<CategoryTreeWrapper>();
            this.counts = new Map<String, Integer>();
            this.sums = new Map<String, Decimal>();
            this.rateCalculated = 0;
            this.riseRateCostPriceUnitCalculated = 0;
            this.riseRateCostPricewNetTaxCalculated = 0;
            this.riseRateCostPriceUnitwNetTaxCalculated = 0;
            this.riseRateTaxCalculated = 0;
        }
    }

    /** Wrapper class for Category. */
    public class CategoryWrapper {
        public Id categoryId {get; set;}
        public String categoryName {get; set;}
        public List<PriceListStatementDetail__c> priceListStatementDetails {get; set;}

        public CategoryWrapper(Id categoryId, String categoryName, PriceListStatementDetail__c item) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            this.priceListStatementDetails = new List<PriceListStatementDetail__c>{item};
        }
    }

    public class StatementWrapper {
        // the Id of the Tax__c record or the Pol_Com_Condition__c record
        public Id recordId {get; set;}
        // the name of the Tax__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Tax__c / 1-9 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        // statement type for discont statements (U, %)
        public String conditionMode {get; set;}

        public StatementWrapper(Id recordId, String Name, Integer displayOrder, String conditionMode) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.conditionMode = conditionMode;
        }

        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this(recordId, Name, displayOrder, '');
        }
    }
}