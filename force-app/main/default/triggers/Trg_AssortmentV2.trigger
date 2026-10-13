trigger Trg_AssortmentV2 on Assortment__c (before insert, before update, after insert, after update, after delete) {
    /*Map<String, Map<Integer, Map<String, String>>> metadataMap = TriggerHandlerManager.getMethodExecutions();
    List<Assortment__c> newList = Trigger.new;
    Map<Id, Assortment__c> oldMap = Trigger.oldMap;
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsBeforeInsert = metadataMap.containskey(String.valueOf(TriggerOperation.BEFORE_INSERT)) ? metadataMap.get(String.valueOf(TriggerOperation.BEFORE_INSERT)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsBeforeInsert.size() > 0) {
                execute(triggerExecutionSettingsBeforeInsert, newList, oldMap);
            }
        }
        if (Trigger.isUpdate) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsBeforeUpdate = metadataMap.containskey(String.valueOf(TriggerOperation.BEFORE_UPDATE)) ? metadataMap.get(String.valueOf(TriggerOperation.BEFORE_UPDATE)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsBeforeUpdate.size() > 0) {
                execute(triggerExecutionSettingsBeforeUpdate, newList, oldMap);
            }
        }
        if (Trigger.isDelete) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsBeforeDelete = metadataMap.containskey(String.valueOf(TriggerOperation.BEFORE_DELETE)) ? metadataMap.get(String.valueOf(TriggerOperation.BEFORE_DELETE)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsBeforeDelete.size() > 0) {
                execute(triggerExecutionSettingsBeforeDelete, newList, oldMap);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsAfterInsert = metadataMap.containskey(String.valueOf(TriggerOperation.AFTER_INSERT)) ? metadataMap.get(String.valueOf(TriggerOperation.AFTER_INSERT)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsAfterInsert.size() > 0) {
                execute(triggerExecutionSettingsAfterInsert, newList, oldMap);
            }
        }
        if (Trigger.isUpdate) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsAfterUpdate = metadataMap.containskey(String.valueOf(TriggerOperation.AFTER_UPDATE)) ? metadataMap.get(String.valueOf(TriggerOperation.AFTER_UPDATE)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsAfterUpdate.size() > 0) {
                execute(triggerExecutionSettingsAfterUpdate, newList, oldMap);
            }
        }
        if (Trigger.isDelete) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsAfterDelete = metadataMap.containskey(String.valueOf(TriggerOperation.AFTER_DELETE)) ? metadataMap.get(String.valueOf(TriggerOperation.AFTER_DELETE)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsAfterDelete.size() > 0) {
                execute(triggerExecutionSettingsAfterDelete, newList, oldMap);
            }
        }
        if (Trigger.isUnDelete) {
            Map<Integer, Map<String, String>> triggerExecutionSettingsAfterUndelete = metadataMap.containskey(String.valueOf(TriggerOperation.AFTER_UNDELETE)) ? metadataMap.get(String.valueOf(TriggerOperation.AFTER_UNDELETE)) : new Map<Integer, Map<String, String>>();
            if (triggerExecutionSettingsAfterUndelete.size() > 0) {
                execute(triggerExecutionSettingsAfterUndelete, newList, oldMap);
            }
        }
    }
    
    public void execute(Map<Integer, Map<String, String>> triggerExecutionSettings, List<Assortment__c> newList, Map<Id, Assortment__c> oldMap) {
        List<Integer> executionsList = new List<Integer>(triggerExecutionSettings.keySet());
        executionsList.sort();
        for (Integer order : executionsList) {
            for (String handlerName : triggerExecutionSettings.get(order).keySet()) {
                String methodName = triggerExecutionSettings.get(order).get(handlerName);
                switch on methodName {
                    when 'populateFields' {
                        Trg_Assortment_Handler.populateFields(newList); // BEFORE INSERT
                    }
                    when 'validateCategory' {
                        Trg_Assortment_Handler.validateCategory(newList, oldMap); // BEFORE UPDATE
                    }
                    when 'populateLongName' {
                        Trg_Assortment_Handler.populateLongName(newList, oldMap); // BEFORE INSERT OR UPDATE
                    }
                    when 'AddIntroDetails' {
                        Trg_Assortment_Handler.AddIntroDetails(newList); // AFTER INSERT
                    }
                    when 'createAssortmentsFromMaster' {
                        Trg_Assortment_Handler.createAssortmentsFromMaster(newList); // AFTER INSERT
                    }
                    when 'createBudgetAssortmentDetails' {
                        Trg_Assortment_Handler.createBudgetAssortmentDetails(newList); // AFTER INSERT
                    }
                    when 'generateASDTargetAssortment' {
                        Trg_Assortment_Handler.generateASDTargetAssortment(newList); // AFTER INSERT
                    }
                    when 'generateTargetAssortment' {
                        Trg_Assortment_Handler.generateTargetAssortment(newList, oldMap); // AFTER UPDATE
                    }
                    when 'checkForValidTargetAssortments' {
                        Trg_Assortment_Handler.checkForValidTargetAssortments(newList, oldMap); // AFTER UPDATE
                    }
                    when 'updateParentAssortment' {
                        Trg_Assortment_Handler.updateParentAssortment(newList, oldMap); // AFTER UPDATE
                    }
                    when 'CheckOnTopUnicity' {
                        Trg_Assortment_Handler.CheckOnTopUnicity(newList, oldMap); // AFTER INSERT OR AFTER UPDATE
                    }
                    when 'validateAssortmentDetails' {
                        Trg_Assortment_Handler.validateAssortmentDetails(newList, oldMap); // AFTER INSERT OR AFTER UPDATE
                    }
                    when 'deleteASD' {
                        Trg_Assortment_Handler.deleteASD(); // AFTER DELETE
                    }
                    when else {
                        throw new IllegalArgumentException('Method not found: ' + methodName);
                    }
                }
            }
        }
    }*/
}