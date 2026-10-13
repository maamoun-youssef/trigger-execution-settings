public with sharing class AgendaController {

    // @AuraEnabled(cacheable=true)
    // public static String getTaskDetails(String taskId) {
    //     Task task = [SELECT Owner.FullPhotoURL, Owner.Name, Owner.Account.Name, Owner.Title FROM Task WHERE Id = :taskId];
    // }


    // @AuraEnabled(cacheable=true)
    // public static List<Task> getTaskInfoList(Date selectedDate) {
    //     return [SELECT Id, ActivityDate, CallObject, What.Name, Subject FROM Task WHERE ActivityDate = :selectedDate];

    // }

    @AuraEnabled(cacheable=true)
    public static List<Task> getTaskInfoList(String dueDate, String selectedDate, String searchTerm) {
        System.debug('dueDate: ' + dueDate);
        System.debug('selectedDate: ' + selectedDate);
        System.debug('searchTerm: ' + searchTerm);
        String searchKey = '%' + searchTerm + '%';
        String query = 'SELECT Id, ActivityDate, Status, CallObject, What.Name, Subject';
        query += ' FROM Task';
        query += ' WHERE ActivityDate != null';
        if (String.isNotBlank(selectedDate) && String.isBlank(dueDate)) {
            System.debug('1');
            query += ' AND ActivityDate = ' + selectedDate;
        } else if (dueDate == 'TODAY') {
            System.debug('2');
            query += ' AND ActivityDate <= TODAY ';
        }else if (String.isNotBlank(selectedDate) && String.isNotBlank(dueDate)) {
            System.debug('3');
            query += ' AND ActivityDate <=' + dueDate + ' AND ActivityDate >= ' + selectedDate;
        }
        if (String.isNotBlank(searchTerm) && !String.isBlank(searchTerm)) {
            query += ' AND (CallObject LIKE \'' + searchKey + '\' OR What.Name LIKE \'' + searchKey + '\' OR Subject LIKE \'' + searchKey + '\')';
        }
        query += ' ORDER BY ActivityDate ASC';
        System.debug('query: ' + query);
        return Database.query(query);
    }
    @AuraEnabled(cacheable=true)
    public static List<Task> getCurrentMonthTasks(Integer year, Integer month) {
        // Get the current date
        Date currentDate = Date.today();
        if (year != null && month != null) {
            currentDate = Date.newInstance(year, month, 1);
        }
        
        // Get the first day of the current month
        Date firstDayOfMonth = currentDate.toStartOfMonth();
        
        // Get the last day of the current month
        Date lastDayOfMonth = firstDayOfMonth.addMonths(1).addDays(-1);
        
        // Query tasks for the current month
        List<Task> tasks = [SELECT Id, ActivityDate, CallObject, What.Name, Subject
                            FROM Task
                            WHERE ActivityDate >= :firstDayOfMonth
                            AND ActivityDate <= :lastDayOfMonth];
        
        return tasks;
    }

    public List<TaskWrapper> taskWrappers { get; set; }
    public String taskWrappersJSON { get; private set; }

    @AuraEnabled(cacheable=true)
    public static String getTaskWrappers() {
        Map<Id, Task> taskMap = new Map<Id, Task> (
            [SELECT Id, WhatId, Priority, Status, Description, Owner.Name, Owner.Title FROM Task]
            );
            TaskWrapper taskWrapper = new TaskWrapper();
            taskWrapper.taskMap = taskMap;
            return JSON.serialize(taskWrapper);
        // List<TaskWrapper> taskWrappers = new List<TaskWrapper>();
        // List<Task> tasks = [SELECT Id, WhatId, Priority, Status, Description FROM Task];
        // for (Task task : tasks) { // for ((object name) (iterator name) : (list name))
        //     TaskWrapper taskWrapper = new TaskWrapper();
        //     taskWrapper.whatId = task.WhatId;
        //     taskWrapper.priority = task.Priority;
        //     taskWrapper.status = task.Status;
        //     taskWrapper.description = task.Description;
        //     taskWrappers.add(taskWrapper);
        // }
        // return JSON.serialize(taskWrappers);
    }

    public class TaskWrapper {
        // public Id whatId { get; set; }
        // public String priority { get; set; }
        // public String status { get; set; }
        // public String description { get; set; }
        public Map<Id, Task> taskMap { get; set; }
        // public Map<String, String> statusPicklistMap {get; set;}
 
        public TaskWrapper() {
            // this.statusPicklistMap = new Map<String, String>();
            // Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Capture_Discount_Product_Level__c.getDescribe();
            // List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            // for (Schema.PicklistEntry pickListVal : picklistEntries) {
            //     this.statusPicklistMap.put(pickListVal.getValue(), pickListVal.getLabel());
            // }
        }
    }  


    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTaskDetails(Id taskId) {
        Map<String, String> taskDetails = new Map<String, String>();
        Task taskRecord = [SELECT Id, Description, Status, Priority, Owner.Name, Owner.Title FROM Task WHERE Id = :taskId LIMIT 1];
        if(taskRecord != null) {
            taskDetails.put('description', taskRecord.Description);
            taskDetails.put('status', taskRecord.Status);
            taskDetails.put('priority', taskRecord.Priority);
            taskDetails.put('ownerName', taskRecord.Owner.Name);
            taskDetails.put('ownerTitle', taskRecord.Owner.Title);
            User ownerRecord = [SELECT Id, FullPhotoUrl, Name, Account.Name, Title FROM User WHERE Id = :taskRecord.OwnerId LIMIT 1];
            if (ownerRecord != null) {
                taskDetails.put('ownerId', ownerRecord.Id);
                taskDetails.put('ownerName', ownerRecord.Name);
                taskDetails.put('ownerTitle', ownerRecord.Title);
                taskDetails.put('fullPhotoUrl', ownerRecord.FullPhotoUrl);
                taskDetails.put('accountName', ownerRecord.AccountId != null ? ownerRecord.Account.Name : null);
            }
        }
        return taskDetails;
    }
    

    @AuraEnabled(cacheable=true)
    public static String getLabels(String language) {
        LabelsWrapper wrapper = new labelsWrapper(language);
        String wrapperJSON = JSON.serialize(wrapper);
        System.debug('>>>>> wrapperJSON: ' + wrapperJSON);
        return wrapperJSON;
    } 


    public class LabelsWrapper {
        public Map<String, String> fieldLabelsMap {get; set;}
        public Map<String, String> statusPicklistMap {get; set;}
        public Map<String, String> priorityPicklistMap {get; set;}
        public LabelsWrapper() {
            this.fieldLabelsMap = new Map<String, String>();
            // Retrieve label for the Status field
            fieldLabelsMap.put(SObjectType.Task.fields.Status.Name, SObjectType.Task.fields.Status.Label);
            // Retrieve label for the Priority field
            fieldLabelsMap.put(SObjectType.Task.fields.Priority.Name, SObjectType.Task.fields.Priority.Label);
            // Retrieve label for the Description field
            fieldLabelsMap.put(SObjectType.Task.fields.Description.Name, SObjectType.Task.fields.Description.Label);
            // labels for the picklist values of status and priority fields
            this.statusPicklistMap = new Map<String, String>();
            Schema.DescribeFieldResult fieldResult = Task.Status.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : picklistEntries) {
                this.statusPicklistMap.put(pickListVal.getValue(), pickListVal.getLabel());
            }
            this.priorityPicklistMap = new Map<String, String>();
            fieldResult = Task.Priority.getDescribe();
            picklistEntries = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : picklistEntries) {
                this.priorityPicklistMap.put(pickListVal.getValue(), pickListVal.getLabel());
            }
        }
        public LabelsWrapper(String language) {
            this.fieldLabelsMap = new Map<String, String>();
            // Retrieve label for the Status field
            fieldLabelsMap.put(SObjectType.Task.fields.Status.Name, SObjectType.Task.fields.Status.Label);
            // Retrieve label for the Priority field
            fieldLabelsMap.put(SObjectType.Task.fields.Priority.Name, SObjectType.Task.fields.Priority.Label);
            // Retrieve label for the Description field
            fieldLabelsMap.put(SObjectType.Task.fields.Description.Name, SObjectType.Task.fields.Description.Label);
            // labels for the picklist values of status and priority fields
            this.statusPicklistMap = new Map<String, String>();
            this.statusPicklistMap = PicklistHelper.getPicklistValuesByLanguage(Task.SObjectType, Task.Status, null, language);
            this.priorityPicklistMap = new Map<String, String>();
            this.priorityPicklistMap = PicklistHelper.getPicklistValuesByLanguage(Task.SObjectType, Task.Priority, null, language);
        }
    }

    
}