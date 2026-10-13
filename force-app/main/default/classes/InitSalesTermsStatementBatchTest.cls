@IsTest
private class InitSalesTermsStatementBatchTest {
    private static Integer yearNext;
    private static BusinessUnit__c regionBU;
    private static BusinessUnit__c countryBU;
    private static Supplier__c supplier;

    static void init() {
        yearNext = Date.today().year() + 1;
        regionBU = TestDataFactory.createBusinessUnitRegion(true, 'EU');
        countryBU = TestDataFactory.createBusinessUnitCountry(true, regionBU.Id);
        supplier = TestDataFactory.createSupplier(true, countryBU, true);
    }

    @IsTest
    static void case1_nsLevel_true_createsStmtWithNegoScopeAndSupplier() {
        init();
        Id expectedNsId = null;
        NegoScope__c expectedNs = [SELECT Id
                                   FROM NegoScope__c
                                   WHERE Supplier__c = :supplier.Id
                                   AND Status__c = 'Active'
                                   ORDER BY CreatedDate DESC
                                   LIMIT 1];
        System.assertNotEquals(null, expectedNs, 'Expected an auto-created active NegoScope for the supplier');
        expectedNsId = expectedNs.Id;

        InitSalesTermsStatementBatch.TEST_ForceNSLevel = true;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => '',
            'supplierId' => supplier.Id
        };
        NegoptimBatch.executeBatch('InitSalesTermsStatementBatch', paramsMap, 200);
        Test.stopTest();

        List<TMP_ServiceStatement__c> stmts = [SELECT Id, Supplier__c, NegoScope__c, BusinessUnitTarget__c, Year__c, Status__c
                                               FROM TMP_ServiceStatement__c
                                               WHERE Year__c = :yearNext
                                               AND Supplier__c = :supplier.Id
                                               AND NegoScope__c = :expectedNsId
                                               LIMIT 1];
        System.assertEquals(1, stmts.size());
        TMP_ServiceStatement__c stmt = stmts[0];
        System.assertEquals(supplier.Id, stmt.Supplier__c);
        System.assertEquals(expectedNsId, stmt.NegoScope__c);
        System.assertEquals(countryBU.Id, stmt.BusinessUnitTarget__c);
        System.assertEquals(yearNext, stmt.Year__c);
        System.assertEquals('Requested', stmt.Status__c);
        
        List<FileDirectory__c> fds = [SELECT Id 
                                      FROM FileDirectory__c 
                                      WHERE TMP_ServiceStatement__c = :stmt.Id 
                                      AND Status__c = 'Requested'];
        Id accId = [SELECT Account__c 
                    FROM Supplier__c 
                    WHERE Id = :supplier.Id 
                    LIMIT 1].Account__c;
        List<User> users = accId == null ? new List<User>() : [SELECT Id 
                                                               FROM User 
                                                               WHERE ContactId != null 
                                                               AND IsActive = true 
                                                               AND Contact.AccountId = :accId];
        Integer expected = fds.size() * users.size();
        List<FileDirectory__Share> shares = fds.isEmpty() ? new List<FileDirectory__Share>() : [SELECT Id 
                                                                                                FROM FileDirectory__Share 
                                                                                                WHERE ParentId IN :fds 
                                                                                                AND RowCause = 'Manual' 
                                                                                                AND AccessLevel = 'Edit'];
        System.assertEquals(expected, shares.size());

        InitSalesTermsStatementBatch.TEST_ForceNSLevel = null;
    }

    @IsTest
    static void case2_nsLevel_false_createsStmtWithSupplierOnly() {
        init();
        InitSalesTermsStatementBatch.TEST_ForceNSLevel = false;
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => '',
            'supplierId' => supplier.Id
        };
        NegoptimBatch.executeBatch('InitSalesTermsStatementBatch', paramsMap, 200);
        Test.stopTest();
        List<TMP_ServiceStatement__c> stmts = [SELECT Id, Supplier__c, NegoScope__c, BusinessUnitTarget__c, Year__c, Status__c
                                               FROM TMP_ServiceStatement__c
                                               WHERE Year__c = :yearNext AND Supplier__c = :supplier.Id
                                               LIMIT 1];
        System.assertEquals(1, stmts.size());
        TMP_ServiceStatement__c stmt = stmts[0];
        System.assertEquals(supplier.Id, stmt.Supplier__c);
        System.assertEquals(null, stmt.NegoScope__c);
        System.assertEquals(countryBU.Id, stmt.BusinessUnitTarget__c);
        System.assertEquals(yearNext, stmt.Year__c);
        System.assertEquals('Requested', stmt.Status__c);
        InitSalesTermsStatementBatch.TEST_ForceNSLevel = null;
    }
    @IsTest
    static void case3_existingRecord_noDuplication() {
        init();
        InitSalesTermsStatementBatch.TEST_ForceNSLevel = false;
        
        Id stmtRt = NegoptimHelper.getObjectRecordTypeId(TMP_ServiceStatement__c.SObjectType, 'SalesTerms');
        TMP_ServiceStatement__c existing = new TMP_ServiceStatement__c(RecordTypeId = stmtRt,
                                                                       Supplier__c = supplier.Id,
                                                                       BusinessUnitTarget__c = countryBU.Id,
                                                                       Year__c = yearNext,
                                                                       Status__c = 'Open',
                                                                       BusinessProcess__c = 'SalesTermsStatement',
                                                                       Step__c = 'Pending Supplier Input');
        insert existing;
        
        Test.startTest();
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => '',
            'supplierId' => supplier.Id
        };
        NegoptimBatch.executeBatch('InitSalesTermsStatementBatch', paramsMap, 200);
        Test.stopTest();
        
        List<TMP_ServiceStatement__c> stmts = [SELECT Id, Status__c
                                               FROM TMP_ServiceStatement__c
                                               WHERE Supplier__c = :supplier.Id
                                               AND BusinessUnitTarget__c = :countryBU.Id
                                               AND Year__c = :yearNext
                                               AND RecordType.DeveloperName = 'SalesTerms'
                                               AND Status__c NOT IN ('Closed','Validated')];
        
        System.assertEquals(1, stmts.size(), 'Batch should not insert a duplicate when an existing ServiceStatement is already present');
        System.assertEquals('Open', stmts[0].Status__c, 'Batch should not overwrite existing record status');
        InitSalesTermsStatementBatch.TEST_ForceNSLevel = null;
    }
}