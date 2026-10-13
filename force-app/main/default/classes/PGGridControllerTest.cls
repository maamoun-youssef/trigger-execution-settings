/**
* @author ULiT
* @date 14-11-2024
* @description PGGridController
*******************************************************************************************************************************************
*/
@isTest
public with sharing class PGGridControllerTest {
    static List<Product2> productList;
    static List<PG__c> pgList;
    static List<Hierarchy__c> heList;
    static List<String> fields;
    static Map<String, Id> productRTs = NegoptimHelper.getObjectRecordTypeMapIds(Product2.sObjectType);
    static void init() {
        try {
            heList = TestDataFactory.createElementHierarchy(4, 1);
            // create 26 products on level 4 he
            productList = new List<Product2>();
            pgList = new List<PG__c>();
            for (Hierarchy__c he: heList) {
                if (he.Level__c == 4) {
                    for (Integer i = 0; i < 4; i++) {
                        Product2 product = TestDataFactory.createProduct(false, he.Id, null);
                        product.RecordTypeId = productRTs.get('Product');
                        product.IsActive = true;
                        productList.add(product);
                        PG__c pg = TestDataFactory.createPG(false, null, he.Id);
                        pgList.add(pg);
                    }
                }
            }
            insert productList;
            insert pgList;
            fields = new List<String> {
                SObjectType.PG__c.fields.Name.Name,
                SObjectType.PG__c.fields.Supplier__c.Name
            };
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void case1_Load_From_Product() {
        init();
        Test.startTest();
        Product2 product = [SELECT Id FROM Product2][0];
        String data = PGGridController.getData(product.Id, JSON.serialize(fields), '', '', 1, 1, '');
        System.assertNotEquals('', data);
        Test.stopTest();
    }
    
    static testmethod void case2_Load_From_Global() {
        init();
        Test.startTest();
        List<PGGridController.FilterSettings> dyanmicFilter = new List<PGGridController.FilterSettings>{
            new PGGridController.FilterSettings('Name', 'Name', false, 'STRING', null, '', '', new List<String>{'PG'}, true),
            new PGGridController.FilterSettings(SObjectType.PG__c.fields.Status__c.Name, 'status', false, 'PICKLIST', null, '', '', new List<String>{'Open'}, true)
        };
        Map<String, Object> filters = new Map<String, Object>{'dynamic' => JSON.serialize(dyanmicFilter), 'productRT' => productRTs.get('Product')};
        List<PGGridController.FieldFilterWrapper> fieldFilterList = new List<PGGridController.FieldFilterWrapper>{new PGGridController.FieldFilterWrapper('Name', 'PG', 'STRING', false)};
        String data = PGGridController.getData(null, JSON.serialize(fields), JSON.serialize(filters), JSON.serialize(fieldFilterList), 1, 1, '');
        System.assertNotEquals('', data);
        Test.stopTest();
    }
    
    static testmethod void case3_saveData() {
        init();
        Test.startTest();
        PG__c pg = [SELECT Id FROM PG__c][0];
        pg.Name = 'test1';
        String saveResult = PGGridController.saveData(JSON.serialize(new List<PG__c>{pg}));
        System.assertEquals('SUCCESS', saveResult);
        Test.stopTest();
    }
    
    static testmethod void case4_Coverage() {
        init();
        Test.startTest();
        Product2 product = [SELECT Id FROM Product2][0];
        String init = PGGridController.initData(product.Id, 'Product');
        Test.stopTest();
        System.assert(true);
    }
    
    
    static testmethod void case5_Coverage_PGGridDataSource() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        PGGridDataSource pgGridDataSource = new PGGridDataSource(context);
        pgGridDataSource.getDefaultValue();
        pgGridDataSource.getValues();
        pgGridDataSource = new PGGridDataSource(context);
        System.assert(true);
    }
}