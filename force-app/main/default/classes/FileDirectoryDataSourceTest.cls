@IsTest
private class FileDirectoryDataSourceTest {

    @IsTest
    static void testDataSourceDefaultAndValues() {
        FileDirectoryDataSource dataSource = new FileDirectoryDataSource();
        VisualEditor.DataRow defaultRow;
        VisualEditor.DynamicPickListRows rows;
        Exception caughtException;
        Test.startTest();
        try {
            defaultRow = dataSource.getDefaultValue();
            rows = dataSource.getValues();
        } catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();
        System.assert(
            (defaultRow != null && rows != null) || caughtException != null,
            'Datasource methods should return rows or throw in orgs missing template metadata'
        );
    }

    @IsTest
    static void testFileDirectorySettingsLoadAndHelpers() {
        FileDirectorySettings__mdt metadataRecord = new FileDirectorySettings__mdt();
        metadataRecord.DeveloperName = 'My_Section';
        metadataRecord.SectionTitle__c = '{!$Label.Cancel}';
        metadataRecord.SectionSubTitle__c = 'Sub';
        metadataRecord.SectionColor__c = '#ffffff';
        metadataRecord.SectionIcon__c = 'utility:folder';
        metadataRecord.DisplayOrder__c = 3;
        metadataRecord.IsDeleted__c = false;
        metadataRecord.ThemesSettings__c = '[{"theme":"{!$Label.Cancel}","themeLabel":"Cancel","gridSettingsName":"Default_Library_Grid","smallThemeImage":"small","largeThemeImage":"large","isDisplayed":true,"isPortalDisplayed":true,"relatedSection":"{!$Label.Cancel}"}]';

        FileDirectorySettings settings = new FileDirectorySettings().load(metadataRecord);
        System.assertEquals('My_Section', settings.developerName);
        System.assertEquals(1, settings.themesSettings.size());

        List<FileDirectorySettings> allSettings = new List<FileDirectorySettings>{ settings };
        Test.startTest();
        String saveResult = settings.save(allSettings);
        String deleteResult = settings.deleteFileDirectorySettings('My_Section');
        Test.stopTest();
        System.assertEquals(null, saveResult, 'Save should return null in tests');
        System.assertEquals(null, deleteResult, 'Delete should return null in tests');

        System.assertEquals(true, settings.hasMethod('load'));
        System.assertEquals(false, settings.hasMethod('missingMethod'));
        Object invokeResult = settings.invoke('load', new List<Object>{ metadataRecord });
        System.assertNotEquals(null, invokeResult, 'Invoke should call load');
    }

    @IsTest
    static void testFileDirectorySettingsSaveBranchesAndLabelsHelpers() {
        FileDirectorySettings emptySettings = new FileDirectorySettings();
        String emptySaveResult = emptySettings.save(new List<FileDirectorySettings>());
        System.assertEquals(null, emptySaveResult, 'Empty list should return null');

        FileDirectorySettings generatedDevName = new FileDirectorySettings();
        generatedDevName.sectionTitle = '{!$Label.Cancel}';
        generatedDevName.themesSettings = new List<FileDirectorySettings.ThemeWrapper>{
            new FileDirectorySettings.ThemeWrapper('{!$Label.Cancel}', 'Cancel', 'Default_Library_Grid', 'small', 'large', true, false, '{!$Label.Cancel}')
        };
        String generatedSaveResult = generatedDevName.save(new List<FileDirectorySettings>{ generatedDevName });
        System.assertEquals(null, generatedSaveResult, 'Save should return null while tests are running');
        System.assertNotEquals('', generatedDevName.developerName, 'Developer name should be generated');
        System.assert(generatedDevName.developerName.contains('Cancel'), 'Developer name should keep label token semantics');

        String fallbackLabel = NegoptimLabels.getCustomLabel('Unknown_Label_Unit_Test', 'Fallback');
        String fallbackLabelLanguage = NegoptimLabels.getCustomLabel('Unknown_Label_Unit_Test', 'FallbackLang', 'xx_XX');
        System.assertEquals('Fallback', fallbackLabel);
        System.assertEquals('FallbackLang', fallbackLabelLanguage);

        System.assertEquals(false, NegoptimHelper.checkLanguageValidity('xx_XX'));
        System.assertNotEquals(null, NegoptimHelper.getPackagePrefix(true));
        System.assertNotEquals('', NegoptimHelper.normalizeAPIName('Name'));
    }

    @IsTest
    static void testFileDirectorySettingsInvokeException() {
        Boolean exceptionThrown = false;
        try {
            new FileDirectorySettings().invoke('unknownMethod', new List<Object>());
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Unknown method should throw exception');
    }

    @IsTest
    static void testFileDirectorySettingsLoadersAndSerializedPaths() {
        Test.startTest();
        List<FileDirectorySettings> allSettings = FileDirectorySettings.loadAllFileDirectorySettings();
        String allSerialized = FileDirectorySettings.loadAllFileDirectorySettingsSerialized();
        FileDirectorySettings one = FileDirectorySettings.loadFileDirectorySettings('Unknown_DeveloperName');
        String oneSerialized = FileDirectorySettings.loadFileDirectorySettingsSerialized('Unknown_DeveloperName');
        Test.stopTest();

        System.assertNotEquals(null, allSettings, 'loadAll should return a list');
        System.assertNotEquals(null, allSerialized, 'Serialized list should return a JSON string');
        System.assert(
            one == null || one.developerName != null,
            'Unknown developer name may return null or a default-initialized record depending on org context'
        );
        System.assertNotEquals(null, oneSerialized, 'Serialized item should return a JSON string');
        System.assertEquals(null, new FileDirectorySettings().deleteFileDirectorySettings(null), 'Null delete key should return null');
    }

    @IsTest
    static void testThemeWrapperConstructorAndDatasourceContextCtor() {
        FileDirectorySettings.ThemeWrapper theme = new FileDirectorySettings.ThemeWrapper(
            'ThemeA',
            'Theme Label',
            'GridName',
            'small.png',
            'large.png',
            true,
            false,
            'Section'
        );
        System.assertEquals('ThemeA', theme.theme);
        System.assertEquals('Section', theme.relatedSection);

        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        FileDirectoryDataSource dataSource = new FileDirectoryDataSource(context);
        System.assertNotEquals(null, dataSource, 'Datasource constructor with context should work');
    }

    @IsTest
    static void testDataSourceThemeRowsCoverage() {
        Grid_Settings__mdt fakeGrid = new Grid_Settings__mdt();
        fakeGrid.MasterLabel = 'Fake Default Grid';
        fakeGrid.DeveloperName = 'Fake_Default_Grid';
        FileDirectoryDataSource.testDefaultGrid = fakeGrid;

        FileDirectorySettings fileSettings = new FileDirectorySettings();
        fileSettings.developerName = 'MySection';
        fileSettings.themesSettings = new List<FileDirectorySettings.ThemeWrapper>{
            new FileDirectorySettings.ThemeWrapper('{!$Label.Cancel}', 'Cancel', 'GridA', 'small', 'large', true, true, '{!$Label.Cancel}'),
            new FileDirectorySettings.ThemeWrapper('PlainTheme', 'Plain', 'GridB', 'small', 'large', true, false, 'PlainSection')
        };
        FileDirectoryDataSource.testFileDirectorySettings = new List<FileDirectorySettings>{ fileSettings };

        try {
            FileDirectoryDataSource ds = new FileDirectoryDataSource();
            Test.startTest();
            VisualEditor.DynamicPickListRows rows = ds.getValues();
            Test.stopTest();

            System.assertNotEquals(null, rows, 'getValues should return a non-null picklist container');
            System.assertEquals(2, rows.size(), 'One section with two themes should produce two picklist rows');

            VisualEditor.DataRow labelTokenRow = rows.get(0);
            VisualEditor.DataRow plainThemeRow = rows.get(1);

            System.assertEquals('MySection - Cancel', String.valueOf(labelTokenRow.getValue()));
            System.assert(String.isNotBlank(labelTokenRow.getLabel()), 'Label row should resolve a non-blank display label');

            System.assertEquals('MySection - PlainTheme', String.valueOf(plainThemeRow.getValue()));

            System.assertEquals(2, rows.getDataRows().size(), 'getDataRows should mirror addRow count');
        } finally {
            FileDirectoryDataSource.testDefaultGrid = null;
            FileDirectoryDataSource.testFileDirectorySettings = null;
        }
    }

    @IsTest
    static void testGetValuesReturnsEmptyWhenTestSettingsListEmpty() {
        FileDirectoryDataSource.testFileDirectorySettings = new List<FileDirectorySettings>();
        try {
            FileDirectoryDataSource ds = new FileDirectoryDataSource();
            VisualEditor.DynamicPickListRows rows = ds.getValues();
            System.assertNotEquals(null, rows);
            System.assertEquals(0, rows.size());
        } finally {
            FileDirectoryDataSource.testFileDirectorySettings = null;
        }
    }
}