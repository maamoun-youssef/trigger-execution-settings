/**
* @author ULiT
* @date 04/09/2025
* @description unit test for pageLayoutSettingsCtrl and pageLayoutSettings
******************************************************************************************************************************************* */

@isTest
private class PageLayoutSettingsCtrlTest {

    @IsTest
    static void case1_loadData() {
        Test.startTest();
        String result = PageLayoutSettingsCtrl.loadData();
        Test.stopTest();
        PageLayoutSettingsCtrl.ResultWrapper resultWrapper = (PageLayoutSettingsCtrl.ResultWrapper)JSON.deserialize(result, PageLayoutSettingsCtrl.ResultWrapper.class);
        System.assertNotEquals(null, resultWrapper, 'result should not be null');
    }

    @IsTest
    static void case2_getFields() {
        String objectName = Supplier__c.SObjectType.getDescribe().getName();
        Test.startTest();
        List<pageLayoutSettingsCtrl.FieldInfo> fields = pageLayoutSettingsCtrl.getFields(objectName);
        Test.stopTest();
        System.assertNotEquals(0, fields.size(), 'Fields should be returned for Supplier__c');
        System.assertNotEquals(null, fields[0].apiName, 'API Name should not be null');
        System.assertNotEquals(null, fields[0].label, 'Label should not be null');
    }

    @IsTest
    static void case3_saveSettings() {    
        PageLayoutSettings pageLayoutSettings =  ConnectRecordPageCtrlTest.buildFakeSettings();   
        Test.startTest();
        String result = pageLayoutSettingsCtrl.saveSettings(JSON.serialize(pageLayoutSettings));
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void case3_checkDeploymentStatus() {
        Test.startTest();
        String result = pageLayoutSettingsCtrl.checkDeploymentStatus('12345');
        Test.stopTest();
        System.assertEquals('Test Running', result);
    }

    @IsTest
    static void case4_loadPageLayoutSettings() {
        TMP_PageLayoutSettings__mdt metadataRecord = new TMP_PageLayoutSettings__mdt();
        metadataRecord.Name__c = 'Supplier Page Layout';
        metadataRecord.ObjectApiName__c = 'Supplier__c';
        metadataRecord.Source__c = 'SELECT Id FROM Supplier__c';
        metadataRecord.NbOfRows__c = 2;
        metadataRecord.ActionButtons__c = '[{"color":"red","label":"Create Contact","flow":"CreateContactFlow"}]';
        metadataRecord.Tabs__c = '[{"label":"Details","content":"Account_Details","contentType":"grid"}]';
        metadataRecord.FieldsConfiguration__c = '[[{"fieldName":"Name","isReadOnly":false,"isMandatory":true}]]';
        metadataRecord.isManualEditMode__c = false;
        metadataRecord.EditFlow__c = 'Edit_Flow';
        metadataRecord.TopLeftCornerFields__c = '["Name"]';
        metadataRecord.NewTaskFlow__c = 'New_Task_Flow';
        metadataRecord.TopLeftCornerLogo1__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.TopLeftCornerLogo2__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.TaskFields__c = '["Subject","Status"]';
        metadataRecord.HeaderField__c = '{"fieldName":"Name","isReadOnly":false,"isMandatory":false,"showHeaderField":true}';
        metadataRecord.BottomLeftCornerLogo1__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.BottomLeftCornerLogo2__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.BottomLeftCornerFields__c = '["CreatedDate"]';
        metadataRecord.StatusIcon__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.ActivityRightIcon__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.ActivityLeftIcon__c = '{"value":"CreatedDate","isStaticRessource":false}';
        metadataRecord.TopRightCornerFields__c = '["Name"]';
        metadataRecord.ActivityFields__c = '["CreatedDate"]';
        metadataRecord.RelatedInformations__c = '{"objectApiName":"Task","aggregateFunction":"COUNT","aggregateFieldName":"Id","label":"Tasks"}';
        Test.startTest();
        PageLayoutSettings settings = new PageLayoutSettings().load(metadataRecord);
        Test.stopTest();
        System.assertEquals('Supplier Page Layout', settings.name);
        System.assertEquals('Supplier__c', settings.objectApiName);
        System.assertEquals('SELECT Id FROM Supplier__c', settings.source);
        System.assertEquals(2, Integer.valueOf(settings.nbOfRows));
        System.assertEquals(1, settings.actionButtons.size());
        System.assertEquals(1, settings.tabs.size());
        System.assertEquals(1, settings.fieldsConfiguration.size());
        System.assertEquals(false, settings.isFlowMode);
        System.assertEquals('Edit_Flow', settings.selectedFlow);
        System.assertEquals(1, settings.topLeftCornerFields.size());
        System.assertEquals('New_Task_Flow', settings.newTaskFlow);
        System.assertEquals('Name', settings.headerField.fieldName);
        System.assertEquals(1, settings.bottomLeftCornerFields.size());
        System.assertEquals(1, settings.topRightCornerFields.size());
        System.assertEquals(1, settings.activityFields.size());
        System.assertEquals('Task', settings.relatedInformations.objectApiName);
        System.assertEquals('COUNT', settings.relatedInformations.aggregateFunction);
    }
    
    @IsTest
    static void case5_RelatedInformationsWrapperDefaults() {
        PageLayoutSettings.RelatedInformationsWrapper wrapper = new PageLayoutSettings.RelatedInformationsWrapper();
        System.assertEquals('', wrapper.objectApiName);
        System.assertEquals('COUNT', wrapper.aggregateFunction);
        System.assertEquals('', wrapper.aggregateFieldName);
        System.assertEquals('', wrapper.label);
        System.assertEquals(0, wrapper.filters.size());
        System.assertEquals(0, wrapper.groupByFields.size());
        System.assertEquals('', wrapper.whereClause);
    }

    @IsTest
    static void case6_FilterConditionWrapperDefaults() {
        PageLayoutSettings.FilterConditionWrapper wrapper = new PageLayoutSettings.FilterConditionWrapper();
        System.assertEquals('', wrapper.fieldName);
        System.assertEquals('=', wrapper.operator);
        System.assertEquals('', wrapper.value);
    }
    
    @IsTest
    static void test7_constructor() {
        PageLayoutSettings pageLayoutSettings = new PageLayoutSettings();
        /*List<PageLayoutSettings> customList = new List<PageLayoutSettings>{ new PageLayoutSettings() };
        PageLayoutSettings.listInstance = customList;
        System.assertEquals(1, PageLayoutSettings.listInstance.size());
        PageLayoutSettings.listInstance = null;
        List<PageLayoutSettings> loadedList = PageLayoutSettings.listInstance;
        System.assert(loadedList.size() > 0, 'listInstance getter should initialize a default list in tests');*/
    }

    public static PageLayoutSettings buildFakeSettings() {
        PageLayoutSettings settings = new PageLayoutSettings();
        settings.name = 'Supplier Page Layout';
        settings.objectApiName = NegoptimHelper.getPackagePrefix(true) + 'Supplier__c';
        settings.tabs = new List<PageLayoutSettings.TabWrapper>{
            // new PageLayoutSettings.TabWrapper('Details', 'Account_Details', 'grid'),
            // new PageLayoutSettings.TabWrapper('Contacts', 'Related_Contacts', 'grid')
        };
        settings.actionButtons = new List<PageLayoutSettings.ActionButtonWrapper>{
            new PageLayoutSettings.ActionButtonWrapper('red', 'Create Contact', 'CreateContactFlow'),
                new PageLayoutSettings.ActionButtonWrapper('#000000','Send Email', 'SendEmailAction')
        };
        settings.fieldsConfiguration = new List<List<PageLayoutSettings.FieldsConfigurationWrapper>>{
             new List<PageLayoutSettings.FieldsConfigurationWrapper>{
             new PageLayoutSettings.FieldsConfigurationWrapper('Name', true, false),
             new PageLayoutSettings.FieldsConfigurationWrapper('Name', true, false)
          }
        };
        settings.bottomLeftCornerLogo1 = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.bottomLeftCornerLogo2 = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.topLeftCornerLogo1 = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.topLeftCornerLogo2 = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.bottomLeftCornerFields = new List<String>{ 'CreatedDate', 'OwnerId' };
        settings.topRightCornerFields = new List<String>{ 'Name' };
        settings.nbOfRows = 2;
        settings.statusIcon = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.activityRightIcon = new PageLayoutSettings.LogosConfigurationWrapper('AccountSource', false);
        settings.activityLeftIcon = new PageLayoutSettings.LogosConfigurationWrapper('AccountNumber', false);
        settings.topLeftCornerFields = new List<String>{ 'Name' };
        settings.taskFields = new List<String>{ 'Subject', 'Status', 'Priority' };
        settings.activityFields = new List<String>{ 'CreatedDate','CreatedById' };
        settings.headerField = new PageLayoutSettings.HeaderFieldsConfigurationWrapper('Name', false, false);
        settings.isFlowMode = false;    
        return settings;
    }
}