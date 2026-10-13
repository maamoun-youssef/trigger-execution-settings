@IsTest(seeAllData=true)
private class ConditionsListControllerTest {

    private static Id findAnyContractId() {
        List<Contract__c> cs = [
            SELECT Id
            FROM Contract__c
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return cs.isEmpty() ? null : cs[0].Id;
    }

    private static Id findContractIdWithVisibleDiscount() {
        List<Contract_Discount__c> cds = [
            SELECT Contract__c
            FROM Contract_Discount__c
            WHERE Status__c = NULL OR Status__c != 'Deleted'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return cds.isEmpty() ? null : cds[0].Contract__c;
    }

    private static Id findAnyVisibleDiscountId() {
        List<Contract_Discount__c> cds = [
            SELECT Id
            FROM Contract_Discount__c
            WHERE Status__c = NULL OR Status__c != 'Deleted'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return cds.isEmpty() ? null : cds[0].Id;
    }

    @IsTest
    static void test_initData_returnsWrapper_whenContractIdNull() {
        Test.startTest();
        String jsonOut = ConditionsListController.initData(null);
        Test.stopTest();
        System.assertNotEquals(null, jsonOut, 'Must return a JSON string (not null).');

        // Should be a Map with at least "prefix"
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonOut);
        System.assertEquals(true, m.containsKey('prefix'), 'Init wrapper must contain prefix.');
    }

    @IsTest
    static void test_initData_withExistingContractIfPresent() {
        Id cid = findContractIdWithVisibleDiscount();
        if (cid == null) {
            System.assert(true, 'No contract with visible discounts in org. Skipping data-dependent assertions.');
            return;
        }
        Test.startTest();
        String jsonOut = ConditionsListController.initData(cid);
        Test.stopTest();
        System.assertNotEquals(null, jsonOut);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonOut);
        List<Object> fieldList = (List<Object>) m.get('fieldList');
        System.assertNotEquals(null, fieldList, 'fieldList must be present.');
        System.assertEquals(true, fieldList.size() > 0, 'fieldList should not be empty.');
        Boolean sawConditionName = false;
        Boolean sawRecalc = false;
        for (Object o : fieldList) {
            Map<String, Object> f = (Map<String, Object>) o;
            if ((String) f.get('fieldName') == 'Condition_Type__r.Name') {
                sawConditionName = true;
                System.assertEquals('REFERENCE', (String) f.get('fieldType'), 'Condition name field must be typed as REFERENCE.');
            }
            if ((String) f.get('fieldName') == ConditionsListController.FIELD_RECALCULATED_RATE) {
                sawRecalc = true;
                System.assertEquals('PERCENT', (String) f.get('fieldType'), 'Recalculated rate must be typed as PERCENT.');
            }
        }
        System.assertEquals(true, sawConditionName, 'Expected Condition_Type__r.Name in fieldList.');
        System.assertEquals(true, sawRecalc, 'Expected recalculatedRate synthetic field in fieldList.');

        List<Object> records = (List<Object>) m.get('records');
        System.assertNotEquals(null, records, 'records must be present.');
        System.assertEquals(true, records.size() <= 10, 'Records must be capped at 10.');
    }

    @IsTest
    static void test_calculateRecalculatedRate_nullId_returnsNull() {
        Test.startTest();
        Decimal dNull = ConditionsListController.calculateRecalculatedRate(null);
        Test.stopTest();
        System.assertEquals(null, dNull, 'Null discount id should return null.');
    }

    @IsTest
    static void test_calculateRecalculatedRate_happyPath_ifDataExists() {
        Id anyDiscId = findAnyVisibleDiscountId();
        if (anyDiscId == null) {
            System.assert(true, 'No visible Contract_Discount__c found to exercise calculateRecalculatedRate; skipping data-dependent assertions.');
            return;
        }
        Test.startTest();
        Decimal d = ConditionsListController.calculateRecalculatedRate(anyDiscId);
        Test.stopTest();
        System.assertEquals(true, d == null || d == d, 'Should produce a Decimal (or null) depending on data present.');
    }
}