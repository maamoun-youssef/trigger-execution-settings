@IsTest
public class NegoptimLabelsInvocableTest {

    @IsTest
    static void testLabelTranslationValidLanguage() {
        NegoptimLabelsInvocable.LabelWrapper labelInfo = new NegoptimLabelsInvocable.LabelWrapper();
        labelInfo.label = 'LBL_Add';
        labelInfo.language = 'fr';
        Test.startTest();
        List<NegoptimLabelsInvocable.LabelWrapper> value = NegoptimLabelsInvocable.getLabelTranslations(new List<NegoptimLabelsInvocable.LabelWrapper>{labelInfo});
        Test.stopTest();
        System.assert(String.isNotBlank(value[0].value), 'value shouldn\'t be blank');
    }

    @IsTest
    static void testLabelTranslationUnsupportedLanguage() {
        NegoptimLabelsInvocable.LabelWrapper labelInfo = new NegoptimLabelsInvocable.LabelWrapper();
        labelInfo.label = 'LBL_Add';
        labelInfo.language = 'frs';
        Test.startTest();
        List<NegoptimLabelsInvocable.LabelWrapper> value = NegoptimLabelsInvocable.getLabelTranslations(new List<NegoptimLabelsInvocable.LabelWrapper>{labelInfo});
        Test.stopTest();
        System.assert(String.isNotBlank(value[0].value), 'value shouldn\'t be blank');
    }

}