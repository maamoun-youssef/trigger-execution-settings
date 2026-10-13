/**
 * @author ULiT
 * @date 12/09/2025
 * @description unit test class for ConnectSalesTermsStatementGridExt
 **/
@IsTest
private class ConnectSalesTermsStatementGridTestExt {

    static void init() {
        try {
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
            System.assert(false, 'Init failed: ' + ex.getMessage());
        }
    }

    @IsTest static void case1_initData() {
        init();
        Test.startTest();
        String initJson = ConnectSalesTermsStatementGridExt.initData();
        Test.stopTest();
        System.assertNotEquals(null, initJson, 'initData should return JSON');
        ConnectSalesTermsStatementGridExt.MainWrapper mw = (ConnectSalesTermsStatementGridExt.MainWrapper) JSON.deserialize(initJson, ConnectSalesTermsStatementGridExt.MainWrapper.class);
        System.assert(mw != null, 'Wrapper must not be null');
        System.assert(mw.gridSettingsManager != null, 'GridSettingsManager must not be null');
    }

    @IsTest static void case2_loadData() {
        init();
        String initJson = ConnectSalesTermsStatementGridExt.initData();
        ConnectSalesTermsStatementGridExt.MainWrapper mw = (ConnectSalesTermsStatementGridExt.MainWrapper) JSON.deserialize(initJson, ConnectSalesTermsStatementGridExt.MainWrapper.class);
        Test.startTest();
        String loadJson = ConnectSalesTermsStatementGridExt.loadData(JSON.serialize(mw.gridSettingsManager), 50, 1);
        Test.stopTest();
        ConnectSalesTermsStatementGridExt.SSWrapper sw = (ConnectSalesTermsStatementGridExt.SSWrapper) JSON.deserialize(loadJson, ConnectSalesTermsStatementGridExt.SSWrapper.class);
        System.assertNotEquals(null, sw, 'SSWrapper should not be null');
        System.assert(sw.records != null, 'Records list must not be null');
        System.assert(sw.totalSize >= 0, 'Total size should be non-negative');
    }
}