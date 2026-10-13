/**
 * @author ULiT
 * @date 24/02/2025
 * Maock class for Metadata Types
 **/
public with sharing class MetadataMockDataSource {
    
    public static NegoScopeSettings getNegoScopeSettings() {
        NegoScopeSettings negoScopeSettings = new NegoScopeSettings();
        try {
            // Trg_NegoScope_Test.case18_UpdateRecordTypeOnValidation
            negoScopeSettings.IsNSProjectActive = true;
            negoScopeSettings.IsNSProjectToRegularOnValidation = true;
        } catch (Exception ex) {
            System.debug('Error' + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
        }
        return negoScopeSettings;
    }

    // public static FormulaSettings getFormulaSettings() {
    //     FormulaSettings formulaSettings = new FormulaSettings();
    //     try {
    //         // Trg_NegoScope_Test.case18_UpdateRecordTypeOnValidation
    //         formulaSettings.objectName = 'Testtttt';
    //         formulaSettings.formulas = '{assormttt : 2 + 2}';
    //     } catch (Exception ex) {
    //         System.debug('Error' + ' : ' + ex.getMessage()+' - ' + ex.getLineNumber()+' - ' + ex.getStackTraceString());
    //     }
    //     return formulaSettings;
    // }

}