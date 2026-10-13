/**
 * @author ULiT
 * @date 6/6/2023
 * @description Unit test class for the HierarchyTreeCtrl Apex controller
 **/
@isTest
public with sharing class HierarchyTreeCtrlTest {
    
    private static List<Hierarchy__c> hierarchyList;
    
    /**
     * @description Initializes test data on the Hierarchy__c object
     */
    static void init() {
        try {
            hierarchyList = TestDataFactory.createElementHierarchy(3, 1);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description Test case for initData method
     */
    @isTest
    static void case1_init_data() {
        init();
        Test.startTest();
        String result = HierarchyTreeCtrl.initData(hierarchyList[0].Id, new List<String>{ 'Id', 'Name' }, false);
        Test.stopTest();
        System.debug('initData result: ' + result);
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void case2_init_data_WithFields() {
        init();
        Test.startTest();
        String result = HierarchyTreeCtrl.initData(hierarchyList[0].Id, new List<String>{ 'Path__c' }, true);
        Test.stopTest();
        System.debug('initData result: ' + result);
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void case3_getHierarchyCount() {
        init();
        Test.startTest();
        Integer result = HierarchyTreeCtrl.getHierarchyCount(hierarchyList[0].Id, true);
        Test.stopTest();
        System.assert(result > 0);
    }
    
    /**
     * @description Test case for getChildrenHierarchy method
     */
    @isTest
    static void case4_get_children_hierarchy() {
        init();
        Test.startTest();
        String result = HierarchyTreeCtrl.getChildrenHierarchy(hierarchyList[0].Id, new List<String>{ 'Id', 'Name' });
        Test.stopTest();
        System.debug('getChildrenHierarchy result: ' + result);
        System.assertNotEquals(null, result);
    }
}