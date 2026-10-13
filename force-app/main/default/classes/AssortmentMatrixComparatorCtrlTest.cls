/**
* @author ULiT
* @date 26-06-2024
* @description AssortmentMatrixComparatorCtrlTest
*******************************************************************************************************************************************
*/
@isTest
public with sharing class AssortmentMatrixComparatorCtrlTest {

    private static Integer year;
    private static String currencyIsoCode;
    private static BusinessUnit__c region;
    private static BusinessUnit__c country;
    private static Supplier__c client;
    private static BusinessUnit__c buSource;
    private static BusinessUnit__c buTarget;
    private static List<BusinessUnit__c> stratList;
    private static List<Hierarchy__c> orgaHEList;
    private static List<Product2> products;
    private static Hierarchy__c assortmentCategory;
    private static Assortment__c assortment;
    private static List<AssortmentDetail__c> details;
    public static final Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
    /**
     * @description generates and initializes commun data for tests
     * calculates the current year
     * creates a country [Country_List__c]
     * Creates a region [BusinessUnit__c]
     * creates a bu [BusinessUnit__c] of type record type country
     * creates a supplier [Supplier__c] related to the bu country
     * creates clientBranch bu [BusinessUnit__c] of type record type country to represent one of the client's store groupes and assigns the related client field [BusinessUnit__c.Supplier__c]
     * creates a tree of hierarchy elements [Hierarchy__c] of depth 4 and with 3 elements on each level
     * creates 5 starts [BusinessUnit__c] on clientBranch with category field null [BusinessUnit__c.Category__c]
     * creates 4 strats [BusinessUnit__c] on clientBranch with category field [BusinessUnit__c.Category__c] of level 3 (limit to 2 categories)
     * the total of strats is (5 w/ category null) + (8 w/ category not null) = 13 strats
     * creates 1 product [Product2] on each element [Hierarchy__c] of level 4
     * assigns 1 element [Hierarchy__c] of level 1 to a variable
     * creates an assortment [Assortment_BU__c]
     * creates an assortment detail [AssortmentDetail__c] for each product
	*/
    static void init() {
        try {
            Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
            Map<String, Id> assDetailRTIds = NegoptimHelper.getObjectRecordTypeMapIds(AssortmentDetail__c.SObjectType);
            // NegoptimCustomSettings__c negoptimCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            // negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = CommonConstants.GRID_SETTINGS_DEFAULT;
            // negoptimCustomSettings.Higher_Level_Packaging_Record_Type_Id__c = productRTIds.get('Higher_Level_Packaging');
            // insert negoptimCustomSettings;
            year = System.Today().year();
            region = TestDataFactory.createBusinessUnitRegion(true, 'region');
            Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
            country = TestDataFactory.createBusinessUnitCountry(true, region.Id);
            client = TestDataFactory.createSupplier(true, country, false);
            orgaHEList = TestDataFactory.createElementHierarchy(4, 1);
            buSource = TestDataFactory.createBusinessUnitChannel(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBusinessUnitBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Supplier__c = client.Id;
            buTarget.ClientCategory__c = orgaHEList[1].Id;
            insert new List<BusinessUnit__c> {buSource, buTarget};
                
                stratList = new List<BusinessUnit__c>();
            for (Integer i = 0; i < 4; i++) {
                stratList.add(TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat' + i));
            }
            BusinessUnit__c closedBU = TestDataFactory.createBusinessUnitAssortCluster(false, buTarget.Id, 'Strat0');
            closedBU.ClosingDate__c = System.Today().addMonths(-1);
            stratList.add(closedBU);
            insert stratList;
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                products.add(TestDataFactory.createProduct(false, orgaHEList[4].Id, null));
            }
            insert products;
            assortment = new Assortment__c(Name = 'Ass1', BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                        Hierarchy__c = orgaHEList[1].Id, Status__c = 'Open',
                                                        BDate__c = Date.newInstance(System.Today().year(), 1, 1),
                                                        EDate__c = Date.newInstance(System.Today().year(), 12, 31), Year__c = System.Today().year());
            insert assortment;
            details = new List<AssortmentDetail__c>();
            for (Product2 item : products) {
                details.add(new AssortmentDetail__c(Product__c = item.Id, Assortment__c = assortment.Id, ProductLifeStatusAss__c = 'Keep',
                                                                Status__c = 'InPreparation', recordTypeId = assDetailRTIds.get('Regular')));
            }
            insert details;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    static testMethod void test_case_load_initial_data() {
        init();
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.initData();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_load_tree_grid_data() {
        init();
        AssortmentMatrixComparatorCtrl.FilterWrapper filterWrapper = new AssortmentMatrixComparatorCtrl.FilterWrapper(null, true, buRTIds.get('Banner'), products[0].Name + year, buTarget.Id, orgaHEList[1].Id, new List<String>{CommonConstants.HMSM}, false);
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.getData(JSON.serialize(filterWrapper), 25);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_load_data() {
        init();
        AssortmentMatrixComparatorCtrl.FilterWrapper filterWrapper = new AssortmentMatrixComparatorCtrl.FilterWrapper(null, true, buRTIds.get('Banner'), products[0].Name + year, buTarget.Id, orgaHEList[1].Id, new List<String>{CommonConstants.HMSM}, false);
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.getAssortmentData('Negotiation', JSON.serialize(filterWrapper));
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_get_details() {
        init();
        List<Id> productsIdList = new List<Id>();
        for (Product2 item : products) {
            productsIdList.add(item.Id);
        }
        List<Id> assortmentsIdList = new List<Id>{assortment.Id};
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.getDetails(productsIdList, assortmentsIdList, 25, 1);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_request_for_approval() {
        init();
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.requestForApproval(assortment.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_validate() {
        init();
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.validate(assortment.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_recalculate_formula() {
        init();
        List<AssortmentDetail__c> changeSets = new List<AssortmentDetail__c>{new AssortmentDetail__c(Id = details[0].Id, WDChannelBaseNego__c = 100)};
        String changeSetsJSON = JSON.serialize(changeSets);
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.recalculateFormula(changeSetsJSON, new List<String>{assortment.Id}, 'Negotiation');
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_save_data() {
        init();        
        List<AssortmentDetail__c> changeSets = new List<AssortmentDetail__c>{new AssortmentDetail__c(Id = details[0].Id, WDChannelBaseNego__c = 100)};
        String changeSetsJSON = JSON.serialize(changeSets);
        Test.startTest();
        String result = AssortmentMatrixComparatorCtrl.saveData(changeSetsJSON);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static testMethod void test_case_process_rest() {
        init();  
        String responseBody = createResponseBody();
        HTTPRestRequestMockFactory mock = new HTTPRestRequestMockFactory(200, 'OK', responseBody, new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();      
        String result = AssortmentMatrixComparatorCtrl.processRestForExcel(new List<Id> {assortment.Id}, 'test', false, null);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    static String createResponseBody() {
        String responseBody = '';
        responseBody += '{';
        responseBody += '  "d": {';
        responseBody += '    "results": [';
        responseBody += '{';
        responseBody += '  "totalSize": 1,';
        responseBody += '  "done": true,';
        responseBody += '  "records": [';
        responseBody += '    {';
        responseBody += '      "attributes": {';
        responseBody += '        "type": "AssortmentDetail__c",';
        responseBody += '        "url": "/services/data/v50.0/sobjects/AssortmentDetail__c/a0eG5000000turBIAQ"';
        responseBody += '      },';
        responseBody += '      "Id": "a0eG5000000turBIAQ",';
        responseBody += '      "TMP_ClientCategory__c": null,';
        responseBody += '      "BusinessUnitCluster__c": "a0HG5000004dpd3MAA",';
        responseBody += '      "BusinessUnitCluster__r": {';
        responseBody += '        "attributes": {';
        responseBody += '          "type": "BusinessUnit__c",';
        responseBody += '          "url": "/services/data/v50.0/sobjects/BusinessUnit__c/a0HG5000004dpd3MAA"';
        responseBody += '        },';
        responseBody += '        "Name": "T1"';
        responseBody += '      },';
        responseBody += '      "ProductLifeStatusAss__c": "Keep",';
        responseBody += '      "Assortment__c": "a0fG50000014wUfIAI",';
        responseBody += '      "Assortment__r": {';
        responseBody += '        "attributes": {';
        responseBody += '          "type": "Assortment__c",';
        responseBody += '          "url": "/services/data/v50.0/sobjects/Assortment__c/a0fG50000014wUfIAI"';
        responseBody += '        },';
        responseBody += '        "Name": "Negotiation-Auchan HM-GAP-2024-V1",';
        responseBody += '        "LongName__c": "Negotiation &#124; Auchan HM &#124; Validated &#124; 2024.0",';
        responseBody += '        "BusinessUnitSource__c": "a0HG5000004bpOwMAI",';
        responseBody += '        "BusinessUnitSource__r": {';
        responseBody += '          "attributes": {';
        responseBody += '            "type": "BusinessUnit__c",';
        responseBody += '            "url": "/services/data/v50.0/sobjects/BusinessUnit__c/a0HG5000004bpOwMAI"';
        responseBody += '          },';
        responseBody += '          "SiteOfSales_Number__c": null,';
        responseBody += '          "SiteOfSales_Number_N1__c": null,';
        responseBody += '          "SiteOfSales_Number_P1__c": null,';
        responseBody += '          "SiteOfSales_Number_P2__c": null';
        responseBody += '        },';
        responseBody += '        "BusinessUnitTarget__c": "a0HG5000004bpcUMAQ",';
        responseBody += '        "BusinessUnitTarget__r": {';
        responseBody += '          "attributes": {';
        responseBody += '            "type": "BusinessUnit__c",';
        responseBody += '            "url": "/services/data/v50.0/sobjects/BusinessUnit__c/a0HG5000004bpcUMAQ"';
        responseBody += '          },';
        responseBody += '          "Multiple_Complementary__c": false';
        responseBody += '        },';
        responseBody += '        "Hierarchy__c": "a0IG5000000fbYtMAI",';
        responseBody += '        "HierarchyElement__r": {';
        responseBody += '          "attributes": {';
        responseBody += '            "type": "Hierarchy__c",';
        responseBody += '            "url": "/services/data/v50.0/sobjects/Hierarchy__c/a0IG5000000fbYtMAI"';
        responseBody += '          },';
        responseBody += '          "Path__c": "A0&#124;GMS&#124;GAP",';
        responseBody += '          "Name": "GAP"';
        responseBody += '        },';
        responseBody += '        "Year__c": 2024.0,';
        responseBody += '        "BDate__c": "2024-01-01",';
        responseBody += '        "EDate__c": "2024-12-31",';
        responseBody += '        "AssortmentNegotiationRef__c": null,';
        responseBody += '        "AssortmentNegotiationRef__r": null';
        responseBody += '      },';
        responseBody += '      "Hierarchy__c": "a0IG5000000fdaBMAQ",';
        responseBody += '      "HierarchyElement__r": {';
        responseBody += '        "attributes": {';
        responseBody += '          "type": "Hierarchy__c",';
        responseBody += '          "url": "/services/data/v50.0/sobjects/Hierarchy__c/a0IG5000000fdaBMAQ"';
        responseBody += '        },';
        responseBody += '        "Path__c": "A0&#124;GMS&#124;GAP&#124;AUTRESGAP&#124;GATBRET4&#124;GATBRET5",';
        responseBody += '        "Long_Name__c": "..GATEAUX BRETONS"';
        responseBody += '      },';
        responseBody += '      "Product__c": "01tG5000004UqNUIA0",';
        responseBody += '      "Product__r": {';
        responseBody += '        "attributes": {';
        responseBody += '          "type": "Product2",';
        responseBody += '          "url": "/services/data/v50.0/sobjects/Product2/01tG5000004UqNUIA0"';
        responseBody += '        },';
        responseBody += '        "Name": "1/2 LUNE 400G PRUNEAU",';
        responseBody += '        "IsInnovation__c": false,';
        responseBody += '        "VIP__c": "--/--/--/--",';
        responseBody += '        "ProductCode": "Big 3/Ciblée/Ciblée/Drive 1",';
        responseBody += '        "Product_EAN__c": "3259422743010",';
        responseBody += '        "RecordType": {';
        responseBody += '          "attributes": {';
        responseBody += '            "type": "RecordType",';
        responseBody += '            "url": "/services/data/v50.0/sobjects/RecordType/01206000000x3e3AAA"';
        responseBody += '          },';
        responseBody += '          "DeveloperName": "Product"';
        responseBody += '        },';
        responseBody += '        "Market_End_of_Life_Date__c": null,';
        responseBody += '        "Market_Introduction_Date__c": null,';
        responseBody += '        "Category__c": "a0IG5000000fdaBMAQ",';
        responseBody += '        "Category__r": {';
        responseBody += '          "attributes": {';
        responseBody += '            "type": "Hierarchy__c",';
        responseBody += '            "url": "/services/data/v50.0/sobjects/Hierarchy__c/a0IG5000000fdaBMAQ"';
        responseBody += '          },';
        responseBody += '          "Name": "GATEAUX BRETONS"';
        responseBody += '        }';
        responseBody += '      },';
        responseBody += '      "AssortmentDetailLHistory__c": "a0eG5000000yfgDIAQ",';
        responseBody += '      "WDClientBaseNego__c": 100.0,';
        responseBody += '      "WDChannelBaseNego__c": 8.5,';
        responseBody += '      "StartDate__c": "2024-01-03",';
        responseBody += '      "Status__c": "InPreparation",';
        responseBody += '      "SOSNumberNego__c": 100.0';
        responseBody += '    }';
        responseBody += '  ]';
        responseBody += '}';
        responseBody += '    ]';
        responseBody += '  }';
        responseBody += '}';
        return responseBody;
    }
}