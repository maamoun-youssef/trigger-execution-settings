@IsTest
public class PageLayoutControllerTest {
    public static PageLayoutSettings buildFakeSettings() {
        PageLayoutSettings settings = new PageLayoutSettings();
        settings.name = 'Account Page Layout';
        settings.objectApiName = 'Account';
        settings.tabs = new List<PageLayoutSettings.TabWrapper>{
            new PageLayoutSettings.TabWrapper(
                'Details',
                'Account_Details',
                'grid'
            ),
            new PageLayoutSettings.TabWrapper(
                'Tasks',
                'Related_Tasks',
                'grid'
            )
        };
        settings.actionButtons = new List<PageLayoutSettings.ActionButtonWrapper>{
                new PageLayoutSettings.ActionButtonWrapper(
                    'red',
                    'Create Task',
                    'CreateTaskFlow'
                ),
                new PageLayoutSettings.ActionButtonWrapper(
                    '#000000',
                    'Send Email',
                    'SendEmailAction'
                )
            };
        settings.fieldsConfiguration = new List<List<PageLayoutSettings.FieldsConfigurationWrapper>>{
                new List<PageLayoutSettings.FieldsConfigurationWrapper>{
                    new PageLayoutSettings.FieldsConfigurationWrapper('Name', true, false),
                    new PageLayoutSettings.FieldsConfigurationWrapper('Phone', true, false)
                }
            };
        settings.bottomLeftCornerLogo1 =new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate', false);
        settings.bottomLeftCornerLogo2 = new PageLayoutSettings.LogosConfigurationWrapper('LastModifiedDate',false);
        settings.topLeftCornerLogo1 = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate',false);
        settings.topLeftCornerLogo2 = new PageLayoutSettings.LogosConfigurationWrapper('LastModifiedDate', false);
        settings.bottomLeftCornerFields = new List<String>{'CreatedDate','OwnerId'};
        settings.topRightCornerFields = new List<String>{'Name','Phone'};
        settings.topLeftCornerfields = new List<String>{'Name'};
        settings.nbOfRows = 2;
        settings.statusField = 'Type';
        settings.statusIcon = new PageLayoutSettings.LogosConfigurationWrapper('CreatedDate',false);
        settings.activityRightIcon = new PageLayoutSettings.LogosConfigurationWrapper('CreatedById', false);
        settings.activityLeftIcon = new PageLayoutSettings.LogosConfigurationWrapper('LastModifiedById', false);
        settings.taskFields = new List<String>{'Subject', 'Status', 'Priority'};
        settings.activityFields = new List<String>{ 'CreatedDate', 'CreatedById'};
        settings.headerField = new PageLayoutSettings.HeaderFieldsConfigurationWrapper('Name', false, false);
        PageLayoutSettings.RelatedInformationsWrapper taskCount = new PageLayoutSettings.RelatedInformationsWrapper();
        taskCount.label = 'Task Count';
        taskCount.parentRelationshipApiName = 'Tasks';
        PageLayoutSettings.FilterConditionWrapper filter = new PageLayoutSettings.FilterConditionWrapper();
        filter.fieldName = 'Status';
        filter.operator = 'IN';
        filter.fieldType = 'STRING';
        filter.value = 'Not Started,Completed';
        taskCount.filters = new List<PageLayoutSettings.FilterConditionWrapper>{filter};
        settings.relatedInformations = new List<PageLayoutSettings.RelatedInformationsWrapper>{ taskCount };
        settings.source = null;
        return settings;
    }

    @IsTest
    static void testLoadData() {
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '123456'
        );
        insert acc;
        Task t = new Task(
            Subject = 'Follow Up',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = acc.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;
        Test.startTest();
        String result = PageLayoutController.loadData(acc.Id, 'TEST_TEMPLATE');
        Test.stopTest();
        System.assertNotEquals(null, result);
        Map<String,Object> wrapper = (Map<String,Object>)JSON.deserializeUntyped(result);
        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.containsKey('record'));
        List<Object> fields =(List<Object>)wrapper.get('fields');
        System.assert(fields.size() > 0);
        List<Object> taskRecords = (List<Object>)wrapper.get('taskRecords');
        System.assertEquals(1, taskRecords.size());
    }

    @IsTest
    static void testCloneTask() {
        Account acc = new Account(Name = 'Clone Test');
        insert acc;
        Task sourceTask = new Task(
            Subject = 'Original Task',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = acc.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert sourceTask;
        Test.startTest();
        Id clonedId = PageLayoutController.cloneTask(sourceTask.Id);
        Test.stopTest();
        Task clonedTask = [
            SELECT Id, Subject
            FROM Task
            WHERE Id = :clonedId
        ];
        System.assertEquals(sourceTask.Subject,clonedTask.Subject);
    }

    @IsTest
    static void testDeleteTask() {
        Account acc = new Account(Name = 'Delete Test');
        insert acc;
        Task taskToDelete = new Task(
            Subject = 'Delete Me',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = acc.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert taskToDelete;
        Test.startTest();
        PageLayoutController.deleteTask(taskToDelete.Id);
        Test.stopTest();
        Integer countTasks = [
            SELECT COUNT()
            FROM Task
            WHERE Id = :taskToDelete.Id
        ];
        System.assertEquals(0, countTasks);
    }

    @IsTest
    static void testGetCustomLabelFallback() {
        Test.startTest();
        String result =PageLayoutController.getCustomLabel('THIS_LABEL_DOES_NOT_EXIST','Fallback Value');
        Test.stopTest();
        System.assertEquals('Fallback Value',result);
    }
}