/**
 * @author ULiT
 * @date 26/11/2024
 * @description Test class to test DocumentsCenterController class
 * */
@IsTest
public class DocumentsCenterControllerTest {

    @IsTest
    static void testLoadData() {
        Test.startTest();
        String result = DocumentsCenterController.loadData('','');
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }

    @IsTest
    static void testExtractLabel() {
        Test.startTest();
        String result1 = DocumentsCenterController.extractLabel('fake label');
        String result2 = DocumentsCenterController.extractLabel('');  
        Test.stopTest();

        System.assertEquals('', result1, 'The result should be empty');
        System.assertEquals('', result2, 'The result should be empty');

    }

}