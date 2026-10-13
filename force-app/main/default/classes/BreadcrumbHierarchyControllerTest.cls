/**
* @author ULiT
* @date 14/07/2025
* @desciption unit test class for BreadcrumbHierarchyController
**/
@isTest
public class BreadcrumbHierarchyControllerTest {
    
    @isTest
    static void Case1_loadData_MultiRecords() {
        try {
            Hierarchy__c parent = new Hierarchy__c(Name = 'Parent',
                                                   Code__c = 'TEST_CODE_PARENT');
            insert parent;
            
            Hierarchy__c child = new Hierarchy__c(Name = 'Child',
                                                  Code__c = 'TEST_CODE_CHILD',
                                                  HierarchyParent__c = parent.Id);
            insert child;
            Test.startTest();
            List<Hierarchy__c> result = BreadcrumbHierarchyController.loadData(child.Id);
            Test.stopTest();
            
            System.assertEquals(2, result.size());
        } catch (Exception e) {
            System.debug('❌ INSERT ERROR: ' + e.getMessage());
            System.assert(false, 'Insert failed: ' + e.getMessage());
        }
    }
    
    @isTest
    static void Case2_loadData_OneRecord() {
        Hierarchy__c root = new Hierarchy__c(Name = 'Root');
        insert root;
        
        Test.startTest();
        List<Hierarchy__c> result = BreadcrumbHierarchyController.loadData(root.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'The breadcrumb path should have 1 record (root only)');
        System.assertEquals('Root', result[0].Name, 'The only record should be the root');
    }
    
}