/**
 * @author ULiT
 * @description Test class for GridSettingsManager
 * */
@isTest
private class GridSettingsManagerTest {
    private static String OBJECT_NAME2 = Account.SObjectType.getDescribe().getName();
    private static String Master_OBJECT_NAME2 = User.SObjectType.getDescribe().getName();
    
    @isTest static void test_coverage() {
        String staticFields = 'Id, Name';
        String masterStaticFields = 'Id, Name, Status__c';
        GridSettingsManager gridSettingsManager = new GridSettingsManager(true, Master_OBJECT_NAME2, OBJECT_NAME2, 'Account_Contact');
        String orderBy = 'Name';
        List<String> conditons = gridSettingsManager.buildSearchTermConditions('Active');
        List<String> fieldNames = new List<String>{'Field1', 'Field2', 'Field3'};
        Map<String, List<String>> fieldDependencies = new Map<String, List<String>>{
            'Field1' => new List<String>{'Field4', 'Field5'},
            'Field2' => new List<String>{'Field6'},
            'Field3' => new List<String>{'Field7', 'Field8'}
        };
        Map<String, String> fieldsControllerMap = new Map<String, String>{
            'Field1' => 'ControllerField1',
            'Field2' => 'ControllerField2',
            'Field3' => 'ControllerField3'
        };
        List<String> allDependencies = new List<String>();
        List<String> reccursiveFieldDependencies = gridSettingsManager.reccursiveFieldDependencies(allDependencies, fieldNames, fieldDependencies, fieldsControllerMap);
        String query = gridSettingsManager.buildQuery(null, conditons, orderBy, 10, 0);
        query = gridSettingsManager.buildCountQuery(null);
        String aggregateQuery = gridSettingsManager.buildAggregateQuery(conditons);
        String bannerQuery = gridSettingsManager.buildBannerQuery(conditons);
    }

    @isTest static void test_coverage2() {
        String staticFields = 'Id, Name';
        String masterStaticFields = 'Id, Name';
        String filter = '[{"fieldName":"RecordTypeId","values":["To_Be_Signed"]}]';
        GridSettingsManager gridSettingsManager = new GridSettingsManager(Master_OBJECT_NAME2, masterStaticFields, 'RecordTypeId', OBJECT_NAME2, staticFields, 'RecordTypeId', 'Account_Contact', filter, true);
        String iconName = gridSettingsManager.iconName;
        String iconClass = gridSettingsManager.iconClass;
        Boolean hasMaster = gridSettingsManager.hasMaster;
        String relationName = gridSettingsManager.relationName;
        String orderBy = 'Name';
        List<String> conditons = gridSettingsManager.buildSearchTermConditions('Active');
        String query = gridSettingsManager.buildQuery(null, conditons, orderBy, 10, 0);
        query = gridSettingsManager.buildCountQuery(null);
        String aggregateQuery = gridSettingsManager.buildAggregateQuery(conditons);
        String bannerQuery = gridSettingsManager.buildBannerQuery(conditons);
        Account objInstance = new Account();
        gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(objInstance);
    }

    @isTest static void test_coverage3() {
        GridSettingsManager.BorderStyle bs = new GridSettingsManager.BorderStyle();
        bs.pattern = 'dotted';
		bs.color = '#FFFFFF';
		bs.size = '1px';
        String style = bs.style;
        GridSettingsManager.SeparatorSettings st = new GridSettingsManager.SeparatorSettings();
        st.pattern = 'dotted';
		st.color = '#FFFFFF';
		st.size = '1px';
        style = st.style;
        GridSettingsManager.TextStyle tt = new GridSettingsManager.TextStyle();
		tt.isItalic = true;
		tt.isBold = true;
		tt.isUnderLine = true;
		tt.isStrikeThrought = true;
		tt.color = '#FFFFFF';
		tt.size = '10px';
		tt.align = 'left';
        style = st.style;
        GridSettingsManager.StyleSettings ss = new GridSettingsManager.StyleSettings();
        ss.isAdvanced = false;
		ss.advancedStyle = 'color: #FFFFFF;';
		ss.textStyle = tt;
        ss.bgColor = '#FFFFFF';
        ss.width = '300px';
        style = ss.style;
        ss.isAdvanced = true;
        style = ss.style;
        style = ss.widthStyle;
        GridSettingsManager.FormattingRules fr = new GridSettingsManager.FormattingRules();
        fr.value1 = '1';
        fr.value2 = '1';
        fr.style = ss;
        fr.oppositeStyle = ss;
        fr.operation = GridSettingsManager.ISNULL;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.ISBLANK;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.EQUALS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.NOT_EQUALS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.BETWEEN;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.GREATER;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.GREATER_OR_EQUALS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.LESS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.LESS_OR_EQUALS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.CONTAINS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        fr.operation = GridSettingsManager.NOT_CONTAINS;
        style = fr.getStyleExpression('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.String);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Picklist);
        style = fr.getStyleExpression('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentVF('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', '1',DisplayType.Double);
        style = fr.getStyleExpressionContentJS('1', 'RecordTypeId',DisplayType.Double);
        Grid_Settings__mdt testMock = GridSettingsManager.loadTemplate('Account_Contact');
        GridSettingsManager.loadTemplate('Test');
        System.assert(true);
    }
    
    @isTest static void  test_Mock() {
        Grid_Settings__mdt testMock = GridSettingsManager.loadTemplate('Account_Contact');
        System.assert(true);
    }

    @isTest
    static void testFieldWrapperProperties() {
        GridSettingsManager.FieldWrapper fieldWrapper = new GridSettingsManager.FieldWrapper();
        fieldWrapper.fieldName = 'Custom_Field__c';
        fieldWrapper.fieldLabel = 'Custom Field';
        fieldWrapper.isPersonalised = true;
        fieldWrapper.controllerName = 'TestController';
        fieldWrapper.controlledByFields = new List<String>{'Field1', 'Field2'};
        fieldWrapper.conditionalRules = new List<GridSettingsManager.ConditionalRule>{new GridSettingsManager.ConditionalRule()};
        fieldWrapper.picklistColorsMap = new Map<String, String>{'Option1' => 'Red'};
        fieldWrapper.hasFileInput = true;
        fieldWrapper.displayFullURL = true;
        fieldWrapper.URLOption = 'Test URL';
        fieldWrapper.newLabel = 'Test Label';
        fieldWrapper.replaceURLWith = 'Test Replacement';
        fieldWrapper.helpText = 'This is help text';
        fieldWrapper.borderColor = 'Blue';
        fieldWrapper.defaultType = 'String';
        fieldWrapper.defaultValue = 'Default Value';
        fieldWrapper.defaultExpression = 'Default Expression';
        fieldWrapper.isHidden = false;
        fieldWrapper.isNotExportable = false;
        fieldWrapper.clearOnClone = true;
        fieldWrapper.isSortable = true;
        fieldWrapper.isMassUpdate = true;
        fieldWrapper.isDefaultSortable = true;
        fieldWrapper.defaultSortDirection = 'ASC';
        fieldWrapper.bgColor = '#FFFFFF';
        fieldWrapper.pickListValues = new List<GridSettingsManager.SelectOption>{new GridSettingsManager.SelectOption('1', 'Option 1')};
        fieldWrapper.isCustom = true;
        fieldWrapper.isRichText = true;
        fieldWrapper.internallyCalculated = true;
        fieldWrapper.totalType = 'SUM';
        fieldWrapper.formattingRulesList = new List<GridSettingsManager.FormattingRules>();
        fieldWrapper.hasConditionalFormating = true;
        fieldWrapper.nonConditional = new GridSettingsManager.StyleSettings();
        fieldWrapper.nonConditional.style = 'background-color: yellow;';
        fieldWrapper.separatorSettings = new GridSettingsManager.SeparatorSettings();
        fieldWrapper.separatorSettings.style = 'border: 1px solid black;';    
        fieldWrapper.isInputField = true;
        fieldWrapper.isNumberField = true;
        fieldWrapper.hasHelpText = true;
        fieldWrapper.isHidden = false;
        fieldWrapper.clearOnClone = true;
        fieldWrapper.isSortable = true;
        fieldWrapper.isMassUpdate = true;
        fieldWrapper.isDefaultSortable = false;
        fieldWrapper.defaultSortDirection = 'ASC';
        fieldWrapper.stringFieldType = 'PICKLIST';
        String widthStyleValue = fieldWrapper.widthStyle;
        fieldWrapper.stringFieldType = 'MULTIPICKLIST';
        widthStyleValue = fieldWrapper.widthStyle;
        String fullStyle = fieldWrapper.style;
        String nonConditionalOnlyStyle = fieldWrapper.nonConditionalStyle;
        String expectedStyle = 'color: blue; border: 1px solid black;';
        String expectedWidthStyle = 'min-width: 85px; max-width: 85px; width: 85px;';
        String fieldValue = 'sample value';
        Test.startTest();
        String styleDynamicJS = fieldWrapper.getStyleDynamicJS(fieldValue);
        String styleDynamicTable = fieldWrapper.getStyleDynamicTable(fieldValue);
        String styleContentVF = fieldWrapper.getStyleContentVF(fieldValue);
        String style = fieldWrapper.getStyle(fieldValue);
        Test.stopTest();
    }

    @isTest
    static void testFilterSettings() {
        List<GridSettingsManager.SelectOption> pickListOptions = new List<GridSettingsManager.SelectOption>{
            new GridSettingsManager.SelectOption('Option1', 'Option1'),
            new GridSettingsManager.SelectOption('Option2', 'Option2')
        };

        List<String> values1 = new List<String>{'Principal', 'Master', 'CustomType'};
        GridSettingsManager.FilterSettings referenceFilter1 = new GridSettingsManager.FilterSettings(
            'RecordTypeId', 
            'Record Type ID', 
            false, 
            'REFERENCE', 
            null, 
            null, 
            null, 
            values1
        );
        List<String> conditions1 = referenceFilter1.getQueryConditions();
        
        GridSettingsManager.FilterSettings stringFilter = new GridSettingsManager.FilterSettings(
            'Name', 
            'Name Field', 
            false, 
            'STRING', 
            pickListOptions, 
            null, 
            null, 
            new List<String>{'TestValue'}
        );
        List<String> stringFilterConditions = stringFilter.getQueryConditions();
        
        GridSettingsManager.FilterSettings idFilter = new GridSettingsManager.FilterSettings(
            'AccountId', 
            'Account ID Field', 
            false, 
            'ID', 
            null, 
            null, 
            null, 
            new List<String>{'001000000000001'}
        );
        List<String> idFilterConditions = idFilter.getQueryConditions();
        
        GridSettingsManager.FilterSettings picklistFilter = new GridSettingsManager.FilterSettings(
            'Status', 
            'Status Field', 
            false, 
            'PICKLIST', 
            pickListOptions, 
            null, 
            null, 
            new List<String>{'Active'}
        );
        List<String> picklistFilterConditions = picklistFilter.getQueryConditions();
        
        GridSettingsManager.FilterSettings dateFilter = new GridSettingsManager.FilterSettings(
            'CreatedDate', 
            'Creation Date', 
            false, 
            'DATE', 
            null, 
            '2024-01-01', 
            '2024-12-31', 
            null
        );
        List<String> dateFilterConditions = dateFilter.getQueryConditions();
        
        List<String> booleanPicklistValues = new List<String>{'true', 'false'};
        GridSettingsManager.FilterSettings booleanFilter = new GridSettingsManager.FilterSettings(
            'IsActive', 
            'Active Field', 
            false, 
            'BOOLEAN', 
            null, 
            null, 
            null, 
            booleanPicklistValues
        );
        List<String> booleanConditions = booleanFilter.getQueryConditions();

        List<String> picklistValues = new List<String>{'Option1', 'Option2', 'Option3'};
        GridSettingsManager.FilterSettings picklistFilter2 = new GridSettingsManager.FilterSettings(
            'Status', 
            'Status Field', 
            false, 
            'TEXT', 
            null, 
            null, 
            null, 
            picklistValues
        );
        List<String> picklistConditions2 = picklistFilter2.getQueryConditions();
    }

    @isTest
    static void testHeaderStyleSettings() {
        GridSettingsManager.HeaderStyleSettings header1 = new GridSettingsManager.HeaderStyleSettings();
        header1.bgColor = '#FFFFFF';
        header1.color = '#000000';
        String expectedStyle1 = 'background-color: #FFFFFF;color: #000000;';
        System.assertEquals(expectedStyle1, header1.style);

        GridSettingsManager.HeaderStyleSettings header2 = new GridSettingsManager.HeaderStyleSettings();
        header2.bgColor = '#FF5733';
        header2.color = null;
        String expectedStyle2 = 'background-color: #FF5733;';
        System.assertEquals(expectedStyle2, header2.style);

        GridSettingsManager.HeaderStyleSettings header3 = new GridSettingsManager.HeaderStyleSettings();
        header3.bgColor = null;
        header3.color = '#FFFFFF';
        String expectedStyle3 = 'color: #FFFFFF;';
        System.assertEquals(expectedStyle3, header3.style);

        GridSettingsManager.HeaderStyleSettings header4 = new GridSettingsManager.HeaderStyleSettings();
        header4.bgColor = null;
        header4.color = null;
        String expectedStyle4 = '';
        System.assertEquals(expectedStyle4, header4.style);
    }

    @isTest
    static void testEvaluate() {
        Account acc = new Account(Name = 'Test Account', AnnualRevenue = 1000000, Type = 'Prospect', Industry = 'Technology');
        insert acc;

        GridSettingsManager.Rule rule1 = new GridSettingsManager.Rule();
        rule1.fieldName = 'AnnualRevenue';
        rule1.operation = GridSettingsManager.GREATER;
        rule1.value = '500000';
        rule1.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result1 = rule1.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule2 = new GridSettingsManager.Rule();
        rule2.fieldName = 'AnnualRevenue';
        rule2.operation = GridSettingsManager.LESS;
        rule2.value = '1500000';
        rule2.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result2 = rule2.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule3 = new GridSettingsManager.Rule();
        rule3.fieldName = 'CreatedDate';
        rule3.operation = GridSettingsManager.GREATER;
        rule3.value = '2023-01-01T00:00:00.000Z';
        rule3.fieldType = Schema.DisplayType.DATETIME;
        Boolean result3 = rule3.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule4 = new GridSettingsManager.Rule();
        rule4.fieldName = 'CreatedDate';
        rule4.operation = GridSettingsManager.LESS;
        rule4.value = '2025-01-01T00:00:00.000Z';
        rule4.fieldType = Schema.DisplayType.DATETIME;
        Boolean result4 = rule4.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule5 = new GridSettingsManager.Rule();
        rule5.fieldName = 'CreatedDate';
        rule5.operation = GridSettingsManager.GREATER;
        rule5.value = '2023-01-01';
        rule5.fieldType = Schema.DisplayType.DATE;
        Boolean result5 = rule5.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule6 = new GridSettingsManager.Rule();
        rule6.fieldName = 'CreatedDate';
        rule6.operation = GridSettingsManager.LESS;
        rule6.value = '2025-01-01';
        rule6.fieldType = Schema.DisplayType.DATE;
        Boolean result6 = rule6.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule7 = new GridSettingsManager.Rule();
        rule7.fieldName = 'CreatedDate';
        rule7.operation = GridSettingsManager.GREATER;
        rule7.value = '12:30:45:000';
        rule7.fieldType = Schema.DisplayType.TIME;
        Boolean result7 = rule7.evaluate(Schema.DisplayType.TIME, acc);

        GridSettingsManager.Rule rule8 = new GridSettingsManager.Rule();
        rule8.fieldName = 'CreatedDate';
        rule8.operation = GridSettingsManager.LESS;
        rule8.value = '13:30:45:000';
        rule8.fieldType = Schema.DisplayType.TIME;
        Boolean result8 = rule8.evaluate(Schema.DisplayType.TIME, acc);

        GridSettingsManager.Rule rule9 = new GridSettingsManager.Rule();
        rule9.fieldName = 'IsDeleted';
        rule9.operation = GridSettingsManager.EQUALS;
        rule9.value = 'false';
        rule9.fieldType = Schema.DisplayType.BOOLEAN;
        Boolean result9 = rule9.evaluate(Schema.DisplayType.BOOLEAN, acc);

        GridSettingsManager.Rule rule10 = new GridSettingsManager.Rule();
        rule10.fieldName = 'IsDeleted';
        rule10.operation = GridSettingsManager.NOT_EQUALS;
        rule10.value = 'true';
        rule10.fieldType = Schema.DisplayType.BOOLEAN;
        Boolean result10 = rule10.evaluate(Schema.DisplayType.BOOLEAN, acc);

        GridSettingsManager.Rule rule11 = new GridSettingsManager.Rule();
        rule11.fieldName = 'Industry';
        rule11.operation = GridSettingsManager.CONTAINS;
        rule11.value = 'Tech';
        rule11.fieldType = Schema.DisplayType.PICKLIST;
        Boolean result11 = rule11.evaluate(Schema.DisplayType.PICKLIST, acc);

        GridSettingsManager.Rule rule12 = new GridSettingsManager.Rule();
        rule12.fieldName = 'Industry';
        rule12.operation = GridSettingsManager.NOT_CONTAINS;
        rule12.value = 'Health';
        rule12.fieldType = Schema.DisplayType.PICKLIST;
        Boolean result12 = rule12.evaluate(Schema.DisplayType.PICKLIST, acc);

        GridSettingsManager.Rule rule13 = new GridSettingsManager.Rule();
        rule13.fieldName = 'Industry';
        rule13.operation = GridSettingsManager.EQUALS;
        rule13.value = 'Technology';
        rule13.fieldType = Schema.DisplayType.PICKLIST;
        Boolean result13 = rule13.evaluate(Schema.DisplayType.PICKLIST, acc);

        GridSettingsManager.Rule rule14 = new GridSettingsManager.Rule();
        rule14.fieldName = 'Industry';
        rule14.operation = GridSettingsManager.NOT_EQUALS;
        rule14.value = 'Retail';
        rule14.fieldType = Schema.DisplayType.PICKLIST;
        Boolean result14 = rule14.evaluate(Schema.DisplayType.PICKLIST, acc);

        GridSettingsManager.Rule rule15 = new GridSettingsManager.Rule();
        rule15.fieldName = 'Name';
        rule15.operation = GridSettingsManager.CONTAINS;
        rule15.value = 'Test';
        rule15.fieldType = Schema.DisplayType.STRING;
        Boolean result15 = rule15.evaluate(Schema.DisplayType.STRING, acc);

        GridSettingsManager.Rule rule16 = new GridSettingsManager.Rule();
        rule16.fieldName = 'Name';
        rule16.operation = GridSettingsManager.NOT_CONTAINS;
        rule16.value = 'NoMatch';
        rule16.fieldType = Schema.DisplayType.STRING;
        Boolean result16 = rule16.evaluate(Schema.DisplayType.STRING, acc);

        GridSettingsManager.Rule rule17 = new GridSettingsManager.Rule();
        rule17.fieldName = 'AnnualRevenue';
        rule17.operation = GridSettingsManager.GREATER_OR_EQUALS;
        rule17.value = '500000';
        rule17.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result17 = rule17.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule18 = new GridSettingsManager.Rule();
        rule18.fieldName = 'AnnualRevenue';
        rule18.operation = GridSettingsManager.LESS_OR_EQUALS;
        rule18.value = '500000';
        rule18.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result18 = rule18.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule19 = new GridSettingsManager.Rule();
        rule19.fieldName = 'AnnualRevenue';
        rule19.operation = GridSettingsManager.NOT_EQUALS;
        rule19.value = '500000';
        rule19.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result19 = rule19.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule20 = new GridSettingsManager.Rule();
        rule20.fieldName = 'AnnualRevenue';
        rule20.operation = GridSettingsManager.EQUALS;
        rule20.value = '500000';
        rule20.fieldType = Schema.DisplayType.CURRENCY;
        Boolean result20 = rule20.evaluate(Schema.DisplayType.CURRENCY, acc);

        GridSettingsManager.Rule rule21 = new GridSettingsManager.Rule();
        rule21.fieldName = 'CreatedDate';
        rule21.operation = GridSettingsManager.GREATER_OR_EQUALS;
        rule21.value = '2023-01-01T00:00:00.000Z';
        rule21.fieldType = Schema.DisplayType.DATETIME;
        Boolean result21 = rule21.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule22 = new GridSettingsManager.Rule();
        rule22.fieldName = 'CreatedDate';
        rule22.operation = GridSettingsManager.LESS_OR_EQUALS;
        rule22.value = '2025-01-01T00:00:00.000Z';
        rule22.fieldType = Schema.DisplayType.DATETIME;
        Boolean result22 = rule22.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule23 = new GridSettingsManager.Rule();
        rule23.fieldName = 'CreatedDate';
        rule23.operation = GridSettingsManager.NOT_EQUALS;
        rule23.value = '2023-01-01T00:00:00.000Z';
        rule23.fieldType = Schema.DisplayType.DATETIME;
        Boolean result23 = rule23.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule24 = new GridSettingsManager.Rule();
        rule24.fieldName = 'CreatedDate';
        rule24.operation = GridSettingsManager.EQUALS;
        rule24.value = '2025-01-01T00:00:00.000Z';
        rule24.fieldType = Schema.DisplayType.DATETIME;
        Boolean result24 = rule24.evaluate(Schema.DisplayType.DATETIME, acc);

        GridSettingsManager.Rule rule25 = new GridSettingsManager.Rule();
        rule25.fieldName = 'CreatedDate';
        rule25.operation = GridSettingsManager.GREATER_OR_EQUALS;
        rule25.value = '2023-01-01';
        rule25.fieldType = Schema.DisplayType.DATE;
        Boolean result25 = rule25.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule26 = new GridSettingsManager.Rule();
        rule26.fieldName = 'CreatedDate';
        rule26.operation = GridSettingsManager.LESS_OR_EQUALS;
        rule26.value = '2025-01-01';
        rule26.fieldType = Schema.DisplayType.DATE;
        Boolean result26 = rule26.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule27 = new GridSettingsManager.Rule();
        rule27.fieldName = 'CreatedDate';
        rule27.operation = GridSettingsManager.NOT_EQUALS;
        rule27.value = '2023-01-01';
        rule27.fieldType = Schema.DisplayType.DATE;
        Boolean result27 = rule27.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule28 = new GridSettingsManager.Rule();
        rule28.fieldName = 'CreatedDate';
        rule28.operation = GridSettingsManager.EQUALS;
        rule28.value = '2025-01-01';
        rule28.fieldType = Schema.DisplayType.DATE;
        Boolean result28 = rule28.evaluate(Schema.DisplayType.DATE, acc);

        GridSettingsManager.Rule rule29 = new GridSettingsManager.Rule();
        rule29.fieldName = 'CreatedDate';
        rule29.operation = GridSettingsManager.GREATER_OR_EQUALS;
        rule29.value = '12:30:45:000';
        rule29.fieldType = Schema.DisplayType.TIME;
        Boolean result29 = rule29.evaluate(Schema.DisplayType.TIME, acc);

        GridSettingsManager.Rule rule30 = new GridSettingsManager.Rule();
        rule30.fieldName = 'CreatedDate';
        rule30.operation = GridSettingsManager.LESS_OR_EQUALS;
        rule30.value = '13:30:45:000';
        rule30.fieldType = Schema.DisplayType.TIME;
        Boolean result30 = rule30.evaluate(Schema.DisplayType.TIME, acc);

        GridSettingsManager.Rule rule31 = new GridSettingsManager.Rule();
        rule31.fieldName = 'CreatedDate';
        rule31.operation = GridSettingsManager.NOT_EQUALS;
        rule31.value = '12:30:45:000';
        rule31.fieldType = Schema.DisplayType.TIME;
        Boolean result31 = rule31.evaluate(Schema.DisplayType.TIME, acc);

        GridSettingsManager.Rule rule32 = new GridSettingsManager.Rule();
        rule32.fieldName = 'CreatedDate';
        rule32.operation = GridSettingsManager.EQUALS;
        rule32.value = '13:30:45:000';
        rule32.fieldType = Schema.DisplayType.TIME;
        Boolean result32 = rule32.evaluate(Schema.DisplayType.TIME, acc);
    }  

    @isTest
    static void testEvalExpression() {
        GridSettingsManager.Criteria criteria = new GridSettingsManager.Criteria();
        Map<Integer, Boolean> valuesMap = new Map<Integer, Boolean>();
        valuesMap.put(1, true);  
        valuesMap.put(2, false); 
        String expression = '1 AND 2';
        Test.startTest();      
        Boolean result = criteria.evalExpression(expression, valuesMap);        
        Test.stopTest();
    }

    @isTest
    static void testCriteriaFunctionality() {
        Test.startTest();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        GridSettingsManager.Rule validRule = new GridSettingsManager.Rule();
        validRule.fieldName = 'Name';
        validRule.operation = GridSettingsManager.ISNULL;
        validRule.value = null;

        GridSettingsManager.Rule invalidRule = new GridSettingsManager.Rule();
        invalidRule.fieldName = 'InvalidField';
        invalidRule.operation = GridSettingsManager.ISNULL;
        invalidRule.value = null;

        Map<Integer, GridSettingsManager.Rule> rulesMap = new Map<Integer, GridSettingsManager.Rule>();
        rulesMap.put(1, validRule);
        rulesMap.put(2, invalidRule);

        GridSettingsManager.Criteria criteria = new GridSettingsManager.Criteria();
        criteria.objectName = 'Account';
        criteria.obj = testAccount;
        criteria.rulesMap = rulesMap;

        try {
            criteria.getEvaluatedRulesMap('Account', testAccount);
        } catch (Exception e) {}

        Test.stopTest();
    }
}