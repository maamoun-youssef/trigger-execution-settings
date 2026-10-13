@isTest
private class FileDirectorySubTypeSelectorCtrlTest {

    @isTest
    private static void initDataTest() {
        Test.startTest();
        String data = FileDirectorySubTypeSelectorCtrl.initData();
        FileDirectorySubTypeSelectorCtrl.resultWrapper result = (FileDirectorySubTypeSelectorCtrl.resultWrapper) JSON.deserialize(data, FileDirectorySubTypeSelectorCtrl.resultWrapper.class);
        System.assertNotEquals(null, result.SubTypePicklist, 'SubTypePicklist should not be null');
        System.assertNotEquals(null, result.fdLabels, 'fdLabels should not be null');
        Test.stopTest();
    }

}