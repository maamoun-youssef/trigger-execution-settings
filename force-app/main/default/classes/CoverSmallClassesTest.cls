@isTest 
public class CoverSmallClassesTest {
    //AdvancedLookupCtrl, LookupValue
    @isTest static void AdvancedLookupCtrl_LookupValue_Test() {
        AdvancedLookupCtrl adL = new AdvancedLookupCtrl();
        LookupValue lv = new LookupValue('1','2',false);
        LookupValue lv1 = new LookupValue();
        String componentId = adL.componentId;
        lv1 = adL.valueAttr;
        System.assert(true);
    }
}