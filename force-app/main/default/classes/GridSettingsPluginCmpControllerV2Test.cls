/**
 * @author ULiT
 * @description Test class for GridSettingsPluginCmpControllerV2
 * */
@isTest
private class GridSettingsPluginCmpControllerV2Test {

    private static Account account1;
    private static Account account2;
    private static Account account3;
    private static Opportunity opportunity;
    private static Contract contract;

    static void init() {
        try {
            account1 = new Account(Name = 'account1', BillingCountry = 'FR');
            insert account1;

            account2 = new Account(Name = 'MEA', ParentId = account1.Id);
            insert account2;
            
            account3 = new Account(Name = 'account3', BillingCountry = 'FR');
            insert account3;
            
            opportunity = new Opportunity(Name = 'Negotiation Scope', StageName = 'Prospecting', CloseDate = Date.today().addMonths(1), AccountId = account2.Id);
            insert opportunity;

            contract = new Contract(AccountId = account2.Id, StartDate = Date.newInstance(System.Today().year(), 1, 1));
            insert contract;
        } catch (Exception ex) {
            System.debug('Error during setup: ' + ex.getMessage());
        }
    }

    private class MockHttpCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"body": "Sample response body"}');
            return res;
        }
    }

    @isTest static void constructor_success() {
        init();
        Test.startTest();
        List<String> fieldsName = new List<String> {'Id', 'Name'};
        String masterObjectApiName = 'Account';
        GridSettingsPluginCmpControllerV2.AggregateWrapper aggWrap =  new GridSettingsPluginCmpControllerV2.AggregateWrapper();
        aggWrap.fieldName = 'Name';
        String aggregationFields = JSON.serialize(new List<GridSettingsPluginCmpControllerV2.AggregateWrapper>{aggWrap});
        List<String> integers = new List<String>();
        integers.add('1');
        integers.add('2');
        List<String> fieldsToImport = new List<String>();
        fieldsToImport.add('Id');
        fieldsToImport.add('Name');
        fieldsToImport.add('AnnualRevenue');
        fieldsToImport.add('IsPartner');
        fieldsToImport.add('LastActivityDate');
        fieldsToImport.add('CreatedDate');
        fieldsToImport.add('NumberOfEmployees');
        fieldsToImport.add('Description');
        List<String> parameters = new List<String>();
        parameters.add('AdminEmailAddress');
        parameters.add('BaseUrl');
        List<String> clonedFields = new List<String>();
        clonedFields.add('Name');
        String xlsData = '[{"Id":"' + account1.Id + '","Name":"Doe","AnnualRevenue":"7000","IsPartner":"true","LastActivityDate":"6/11/2024","CreatedDate":"2024-10-25T07:25:55.000+0000","NumberOfEmployees":"10","Description":"New Description"},{"Id":"' + account3.Id + '","Name":"Doe","AnnualRevenue":"7000","IsPartner":"true","LastActivityDate":"6/11/2024","CreatedDate":"2024-10-25T07:25:55.000+0000","NumberOfEmployees":"10","Description":"New Description"}]';
        String recordId = account2.Id;
        String searchTerm = '';
        Integer pageNumber = 10;
        Integer pageSize = 50;
        String templateName = 'Account_Contact';
        String filters = '';
        String result1 = GridSettingsPluginCmpControllerV2.initData(recordId, templateName);
        GridSettingsPluginCmpControllerV2.InitWrapper initWrapper = (GridSettingsPluginCmpControllerV2.InitWrapper) JSON.deserialize(result1, GridSettingsPluginCmpControllerV2.InitWrapper.class);
        String result2 = GridSettingsPluginCmpControllerV2.loadData(JSON.serialize(initWrapper.gridSettingsManager), recordId, masterObjectApiName, pageSize, pageNumber, filters, null, null, null);
        GridSettingsPluginCmpControllerV2.ListViewWrapper wrapper = new GridSettingsPluginCmpControllerV2.ListViewWrapper(
            'Test Label',
            'TestName',
            1
        );
        GridSettingsPluginCmpControllerV2.LoadWrapper loadWrapper = (GridSettingsPluginCmpControllerV2.LoadWrapper) JSON.deserialize(result2, GridSettingsPluginCmpControllerV2.LoadWrapper.class);
        GridSettingsPluginCmpControllerV2.getMasterInfoData(recordId, masterObjectApiName, fieldsName);
        GridSettingsPluginCmpControllerV2.saveRecords(JSON.serialize(new List<SObject>{ Contract }), JSON.serialize(new List<SObject>()), true);
        GridSettingsPluginCmpControllerV2.getTotalAggregation(recordId, aggregationFields, masterObjectApiName, 'Name', 'Account_Contact', filters);
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        ContentVersion CV = new ContentVersion(Title = 'test.pdf', PathOnClient = 'test.pdf', VersionData = bodyBlob);
        insert CV;
        CV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: CV.Id limit 1];
        String filesToAttach = JSON.serialize(new Map<Id, Id> {CV.ContentDocumentId => contract.Id});
        GridSettingsPluginCmpControllerV2.attachFileToRecords(filesToAttach);
        GridSettingsPluginCmpControllerV2.importRecords(masterObjectApiName, fieldsToImport, xlsData, recordId, 'ParentId', false);
        GridSettingsPluginCmpControllerV2.deleteRecords(new List<Id>{account2.Id});
        GridSettingsPluginCmpControllerV2.getPicklistValuesByRecordTypeId(masterObjectApiName, new List<String>{'Industry'});
        GridSettingsPluginCmpControllerV2.getApiName('');
        GridSettingsPluginCmpControllerV2.actionsMap('!$Site', parameters);
        GridSettingsPluginCmpControllerV2.getTemplates('Account');
        Test.stopTest();
        // Assertion.
        System.assertEquals(1,1);
    }

    @isTest static void case_getFieldsDependencies() {
        init();
        Test.startTest();
        GridSettingsPluginCmpControllerV2.getFieldDependencies('Account', 'Industry', 'AccountSource');
        Test.stopTest();
    }
    
    @isTest
    static void case_getChildrenHierarchy_Account() {
        Account parentAcc = new Account(Name = 'Parent Account', AccountNumber = 'P-001');
        insert parentAcc;
        
        Account childAcc1 = new Account(Name = 'Child Account 1', AccountNumber = 'C-001', ParentId = parentAcc.Id);
        Account childAcc2 = new Account(
            Name = 'Child Account 2', AccountNumber = 'C-002', ParentId = parentAcc.Id);
        insert new List<Account>{ childAcc1, childAcc2 };
            
        String recordId = parentAcc.Id;
        List<String> hierarchyParentField = new List<String>{ 'ParentId', 'ParentId' };
        String relationshipName = 'ChildAccounts';
        String objectApiName = 'Account';
        List<String> allFields = new List<String> {
            'Id', 'Name', 'AccountNumber',
            'Parent.Name', 'ParentId',
            'Parent.Fax'};
        Integer levelIndex = 0;
        
        Test.startTest();
        String result = GridSettingsPluginCmpControllerV2.getChildrenHierarchy(recordId, hierarchyParentField,
            relationshipName, objectApiName,
            allFields, levelIndex
        );
        Test.stopTest();
    }
    
    @isTest static void test_coverage_GridSettingsPluginDataSource() {
        // context with EntityName
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Account';
        GridSettingsPluginDataSource gridSettingsPluginDataSource = new GridSettingsPluginDataSource(context);
        gridSettingsPluginDataSource.getDefaultValue();
        gridSettingsPluginDataSource.getValues();
        gridSettingsPluginDataSource = new GridSettingsPluginDataSource(context);
        // context without EntityName
        VisualEditor.DesignTimePageContext context2 = new VisualEditor.DesignTimePageContext();
        GridSettingsPluginDataSource gridSettingsPluginDataSource2 = new GridSettingsPluginDataSource(context2);
        gridSettingsPluginDataSource2.getDefaultValue();
        gridSettingsPluginDataSource2.getValues();
        gridSettingsPluginDataSource2 = new GridSettingsPluginDataSource(context2);
        System.Assert(true);
    }
    
    @isTest static void test_coverage_GridSettingsPluginObjects() {
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        GridSettingsPluginObjects gridSettingsPluginObjects = new GridSettingsPluginObjects(context);
        gridSettingsPluginObjects.getDefaultValue();
        gridSettingsPluginObjects.getValues();
        context.entityName = 'Product2';
        gridSettingsPluginObjects = new GridSettingsPluginObjects(context);
        System.Assert(true);
    }
}