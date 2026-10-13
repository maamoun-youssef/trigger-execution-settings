/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers relaated to Product structure (HE)
 */
@isTest
private class Trg_Hierarchy_Test {

    private static Id rootId;
    private static Integer year;
    private static Hierarchy__c department1;
    private static Hierarchy__c department2;
    private static Hierarchy__c department3;
    private static Hierarchy__c section1;
    private static Hierarchy__c section2;
    private static Hierarchy__c section11;
    private static Hierarchy__c section12;

    // initial function to declare and create objects
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getHierarchyRootId('Product');
            // Create Department
            department1 = TestDataFactory.createHierarchyDepartment(false, rootId);
            department1.Name = 'DPT1'; department1.Code__c = 'DPT Code 1';
            insert department1;
            // Create Department2
            department2 = TestDataFactory.createHierarchyDepartment(false, rootId);
            department2.Name = 'DPT2'; department2.Code__c = 'DPT Code 2';
            insert department2;
            // Create Department3
            department3 = TestDataFactory.createHierarchyDepartment(false, rootId);
            department3.Name = 'DPT3'; department3.Code__c = 'DPT Code 3';
            insert department3;
            // Create Section
            section1 = TestDataFactory.createHierarchySection(false, department1.Id);
            section1.Name = 'SEC1'; section1.Code__c = 'SEC Code 1';
            insert section1;
            // Create Section
            section2 = TestDataFactory.createHierarchySection(false, department2.Id);
            section2.Name = 'SEC2'; section2.Code__c = 'SEC Code 2';
            insert section2;
            // Create Section Child
            section11 = TestDataFactory.createHierarchySection(false, section1.Id);
            section11.Name = 'SEC11';
            section11.Code__c = 'Sec11';
            insert section11;
            section12 = TestDataFactory.createHierarchySection(false, section1.Id);
            section12.Name = 'SEC12';
            section12.Code__c = 'Sec12';
            insert section12;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    // Test validation  on deletion of root : Root element can not be deleted
    @isTest static void test1_deleteRootElement() {
        init();
        Hierarchy__c selectRoot = [SELECT id FROM Hierarchy__c WHERE Id = :rootId];
        Test.startTest();
        Database.DeleteResult result = Database.delete(selectRoot, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Can_Not_Delete_Root_Element, result.getErrors()[0].getMessage());
    }

    // Test delete HE with child will not be accepted
    @isTest static void test2_DeleteHeWithChild(){
        init();
        Test.startTest();
        database.DeleteResult result = database.delete(department1, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cannot_Delete_Record, result.getErrors()[0].getMessage());
    }

    // Test validation on element : code duplication
    @isTest static void test3_checkElementCodeDuplication() {
        init();
        Hierarchy__c newElement = new Hierarchy__c(Name = 'New Element', Code__c = 'DPT Code 2', HierarchyParent__c = department1.Id, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
        Test.startTest();
        Database.SaveResult result = Database.insert(newElement, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value, result.getErrors()[0].getMessage());
    }

    // Test validation another element added with name duplication
    @isTest static void test4_checkAnotherElementNameDuplication() {
        init();
        Hierarchy__c newElement1 = new Hierarchy__c(Name = 'Element 1', Code__c = 'New Code 1', HierarchyParent__c = department1.Id, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
        Hierarchy__c newElement2 = new Hierarchy__c(Name = 'Element 1', Code__c = 'New Code 2', HierarchyParent__c = department1.Id, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
        List<Hierarchy__c> lstElement = new List<Hierarchy__c>();
        lstElement.add(newElement1);
        lstElement.add(newElement2);
        Test.startTest();
        Database.SaveResult[] results = Database.insert(lstElement, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.assert(!result.isSuccess());
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Name, result.getErrors()[0].getMessage());
            }
        }
    }

    // Test validation another element added with code duplication
    @isTest static void test5_checkAnotherElementCodeDuplication() {
        init();
        Hierarchy__c newElement1 = new Hierarchy__c(Name = 'Element 1', Code__c = 'New Code 1', HierarchyParent__c = department1.Id, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
        Hierarchy__c newElement2 = new Hierarchy__c(Name = 'Element 2', Code__c = 'New Code 1', HierarchyParent__c = department1.Id, Level__c = 1, StatusBDate__c = date.newInstance(year, 1, 1));
        List<Hierarchy__c> lstElement = new List<Hierarchy__c>();
        lstElement.add(newElement1);
        lstElement.add(newElement2);
        Test.startTest();
        Database.SaveResult[] results = Database.insert(lstElement, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.assert(!result.isSuccess());
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value, result.getErrors()[0].getMessage());
            }
        }
    }

    // Test validation on HE update : Cannot move element to another parent level
    @isTest static void test6_updateHeParentFail() {
        init();
        Hierarchy__c departmentChild = new Hierarchy__c(Name = 'DPT3-1', Code__c = 'DPT3-1', HierarchyParent__c = department3.Id, Level__c = 2, StatusBDate__c = date.newInstance(year, 1, 1));
        insert departmentChild;
        section2.HierarchyParent__c = departmentChild.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(section2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Chose_Identical_Parent_Element_Level, result.getErrors()[0].getMessage());
    }

    // Test validation on root element : check if root element exist
    @isTest static void test7_checkRootNodeExist() {
        init();
        Hierarchy__c root2 = new Hierarchy__c(Name = 'ROOT2', Code__c = 'ROOT2', HierarchyParent__c = null, Level__c = 0, StatusBDate__c = date.newInstance(year, 1, 1));
        root2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.SObjectType, 'Product');
        Test.startTest();
        Database.SaveResult result = Database.insert(root2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level, result.getErrors()[0].getMessage());
    }

    // Test validation on root element : check if root element exist on bulk
    @isTest static void test8_checkMultiRootNodeExist() {
        init();
        List<Hierarchy__c> listRoot = new List<Hierarchy__c>();
        for(Integer i = 0; i <= 5; i++){
            Hierarchy__c root2 = new Hierarchy__c(Name = 'ROOT' + i, Code__c = 'ROOT' + i, HierarchyParent__c = null, Level__c = 0, StatusBDate__c = date.newInstance(year, 1, 1));
            listRoot.add(root2);
        }
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(listRoot, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level, result.getErrors()[0].getMessage());
            }
        }
    }
    //test Fill Path Field before insert
    @isTest
    static void test9_Fill_Path() {
        init();
        Hierarchy__c newElement1 = new Hierarchy__c(Name = 'Element 1', Code__c = 'New_Code_1', HierarchyParent__c = department1.Id , Level__c = 2);
        Hierarchy__c newElement2 = new Hierarchy__c(Name = 'Element 2', Code__c = 'New_Code_2', HierarchyParent__c = section1.Id , Level__c = 3);
        List<Hierarchy__c> lstElement = new List<Hierarchy__c>{newElement1, newElement2};
            Test.startTest();
        insert lstElement;
        Test.stopTest();
        Hierarchy__c dep1 = [Select id, path__c from Hierarchy__c where Id = :department1.Id];
        Hierarchy__c elt1 = [Select id, path__c, Code__c from Hierarchy__c where Id = :newElement1.Id];
        Hierarchy__c sec1 = [Select id, path__c from Hierarchy__c where Id = :section1.Id];
        Hierarchy__c elt2 = [Select id, path__c, Code__c from Hierarchy__c where Id = :newElement2.Id];
        System.assert(elt1.Path__c != null);
        System.assertEquals(elt1.Path__c, dep1.Path__c + '|' + elt1.Code__c);
        System.assert(elt2.Path__c != null);
        System.assertEquals(elt2.Path__c, sec1.Path__c + '|' + elt2.Code__c);
    }
    //test Update Childs Paths After Update
    @isTest
    static void test10_Update_Path() {
        init();
        Hierarchy__c root = [SELECT Id, Path__c FROM Hierarchy__c WHERE Id = :rootId];
        //change Paths
        root.Code__c = 'Root_Code';
        department1.Code__c = 'Dept1';
        department3.Code__c = 'Dept3';
        section1.Code__c = 'Sec1';
        //add elements to list
        List<Hierarchy__c> listToUpdate =  new List<Hierarchy__c>{root, department1,department3,section1};
        //update list
        Test.startTest();
        update listToUpdate;
        Test.stopTest();
        //assertion
        Map<Id, Hierarchy__c> OrgaHeMap = new Map<Id, Hierarchy__c>([Select Id, path__c, Code__c, HierarchyParent__r.Path__c FROM Hierarchy__c]);
        System.assertEquals(OrgaHeMap.get(department1.Id).Path__c, 'Root_Code|Dept1');
        System.assertEquals(OrgaHeMap.get(department2.Id).Path__c, 'Root_Code|DPT Code 2');
        System.assertEquals(OrgaHeMap.get(department3.Id).Path__c, 'Root_Code|Dept3');
        System.assertEquals(OrgaHeMap.get(section1.Id).Path__c, 'Root_Code|Dept1|Sec1');
        System.assertEquals(OrgaHeMap.get(section11.Id).Path__c, 'Root_Code|Dept1|Sec1|Sec11');
        System.assertEquals(OrgaHeMap.get(section12.Id).Path__c, 'Root_Code|Dept1|Sec1|Sec12');
    }

    // Test validation on root element : check if root element exist
    @isTest static void test11_checkRootNodeWithDiffRT() {
        init();
        Hierarchy__c root2 = new Hierarchy__c(Name = 'ROOT2', Code__c = 'ROOT2', HierarchyParent__c = null, Level__c = 0, StatusBDate__c = date.newInstance(year, 1, 1));
        root2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.SObjectType, 'Purchasing');
        Test.startTest();
        Database.SaveResult result = Database.insert(root2, false);
        Test.stopTest();
        List<Hierarchy__c> roots = [SELECT Id FROM Hierarchy__c WHERE Level__c = 0];
        System.assertEquals(2, roots.size());
    }
}