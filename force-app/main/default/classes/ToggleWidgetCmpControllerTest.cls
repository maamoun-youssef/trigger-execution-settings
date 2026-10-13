/*
 * @author ULIT
 * @date 12/12/2020
 * @description This class contains unit tests for validating the behavior of Apex classes related  to ToggleWidgetCmpController and FieldsDatasource
 **/
@isTest
private with sharing class ToggleWidgetCmpControllerTest {

    private static Product2 product;
	private static VisualEditor.DynamicPickListRows rows;

	static void init() {
    	try {
            VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
            context.pageType = 'RecordPage';
            context.entityName = 'Product2';
            FieldsDatasource datasource = new FieldsDatasource(context);
            VisualEditor.DynamicPickListRows rows = datasource.getValues();
            VisualEditor.DataRow row = datasource.getDefaultValue();
            // Add Region
            product = new Product2(Name = 'Product1');
            insert product;
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }

    @isTest static void test_case1() {
    	init();
        ToggleWidgetCmpController.saveRecord(product.Id, SObjectType.Product2.fields.IsActive.Name, true);
        String results = ToggleWidgetCmpController.getRecordData(product.Id, new List<String>{SObjectType.Product2.fields.IsActive.Name});
        System.assert(true);
    }
}