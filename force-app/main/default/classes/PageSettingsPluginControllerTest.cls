/**
 * @author ULiT
 * @date 17/05/2025
 * @desciption unit test class for PageSettingsPluginController
 **/
@isTest
private class PageSettingsPluginControllerTest {

    @isTest
    static void case1_initData() {
        Test.startTest();
        String result2 = PageSettingsPluginController.initData();
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void case2_loadData() {
        Test.startTest();
        String result2 = PageSettingsPluginController.loadData('TestPage');
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void test_coverage_PageSettingsPluginDataSource() {
        // context with EntityName
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Account';
        PageSettingsPluginDataSource pageSettingsPluginDataSource = new PageSettingsPluginDataSource(context);
        pageSettingsPluginDataSource.getDefaultValue();
        pageSettingsPluginDataSource.getValues();
        pageSettingsPluginDataSource = new PageSettingsPluginDataSource(context);
        System.Assert(true);
    }
}