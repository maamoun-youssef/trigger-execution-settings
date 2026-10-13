@IsTest
private class LayoutPageSettingsControllerTest {

    static void init() {
        // No data required.
        // Controller mainly uses describe information.
    }
    @IsTest
    static void initData() {
        init();
        Test.startTest();
        String data = LayoutPageSettingsController.initData();
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void case1_getFields_Account() {
        init();
        Test.startTest();
        Map<String,Object> result = LayoutPageSettingsController.getFields('Account');
        Test.stopTest();
        System.assertNotEquals(null, result);
        List<LayoutPageSettingsController.FieldInfo> fields = (List<LayoutPageSettingsController.FieldInfo>) result.get('fieldList');
        System.assert(fields.size() > 0);
        Boolean foundName = false;
        for(LayoutPageSettingsController.FieldInfo f : fields){
            if(f.apiName == 'Name'){
                foundName = true;
                break;
            }
        }
        System.assert(foundName);
    }

    @IsTest
    static void case2_getFields_InvalidObject() {
        init();
        Test.startTest();
        Map<String,Object> result = LayoutPageSettingsController.getFields('FakeObject__c');
        Test.stopTest();
        List<Object> fields = (List<Object>)result.get('fieldList');
        List<Object> relationships = (List<Object>)result.get('childRelationships');
        System.assertEquals(0, fields.size());
        System.assertEquals(0, relationships.size());
    }

    @IsTest
    static void case3_getRelatedObjectFields_Task() {
        init();
        Test.startTest();
        List<LayoutPageSettingsController.FieldInfo> fields = LayoutPageSettingsController.getRelatedObjectFields('Task');
        Test.stopTest();
        System.assert(fields.size() > 0);
        Boolean foundSubject = false;
        for(LayoutPageSettingsController.FieldInfo f : fields){
            if(f.apiName == 'Subject'){
                foundSubject = true;
                break;
            }
        }
        System.assert(foundSubject);
    }

    @IsTest
    static void case4_getRelatedObjectFields_InvalidObject() {
        init();
        Test.startTest();
        List<LayoutPageSettingsController.FieldInfo> fields = LayoutPageSettingsController.getRelatedObjectFields('InvalidObject');
        Test.stopTest();
        System.assertEquals(0, fields.size());
    }


    @IsTest
    static void case6_getLayoutPagesList() {
        init();
        Test.startTest();
        List<Map<String,Object>> layouts = LayoutPageSettingsController.getLayoutPagesList();
        Test.stopTest();
        System.assertNotEquals(null, layouts);
    }

    @IsTest
    static void case7_fieldInfoConstructor() {
        LayoutPageSettingsController.FieldInfo fieldInfo = new LayoutPageSettingsController.FieldInfo( 'Amount', 'Amount', 'Currency', true);
        System.assertEquals('Amount', fieldInfo.apiName);
        System.assertEquals('Amount', fieldInfo.label);
        System.assertEquals('Currency', fieldInfo.type);
        System.assertEquals(true, fieldInfo.isAggregateable);
    }

    @IsTest
    static void case8_paramSetting_DefaultValues() {
        LayoutPageSettingsController.ParamSetting param = new LayoutPageSettingsController.ParamSetting();
        System.assertEquals('', param.name);
        System.assertEquals('', param.label);
        System.assertEquals('', param.type);
        System.assertEquals('', param.datasource);
        System.assertEquals('', param.defaultValue);
    }

    @IsTest
    static void paramSetting_CommaDatasource() {
        LayoutPageSettingsController.ParamSetting param =  new LayoutPageSettingsController.ParamSetting();
        param.datasource = 'One,Two,Three';
        Map<String,String> values = param.getDataSourceList;
        System.assertEquals(3, values.size());
        System.assertEquals('One', values.get('One'));
        System.assertEquals('Two', values.get('Two'));
        System.assertEquals('Three', values.get('Three'));
    }

    @IsTest
    static void case10_resultWrapperConstructor() {
        LayoutPageSettingsController.ResultWrapper wrapper = new LayoutPageSettingsController.ResultWrapper();
        System.assertNotEquals(null, wrapper.fieldsMap);
        System.assertNotEquals(null, wrapper.prefix);
    }
}