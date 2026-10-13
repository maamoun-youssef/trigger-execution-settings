trigger Trg_Aptt on APTT__c (before insert, before update, after insert, after update) {
    for (APTT__c item : Trigger.New) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                System.debug('start----before insert >>>> ');
            }
            if (Trigger.isUpdate) {
                System.debug('start----update>>>> ');
            }
            System.debug('start>>old status >>>' + item.Status__c);
            if (Trigger.oldMap?.get(item.Id)?.Status__c == 'Stop') {
                System.debug('old status >>>' + Trigger.oldMap?.get(item.Id)?.Status__c);
                System.debug('before>>new status1 >>>' + item.Status__c);
                item.Status__c = 'Pre-Stop';
                System.debug('before>>new status2 >>>' + item.Status__c);
            }
            if (Trigger.oldMap?.get(item.Id)?.Status__c == 'Go') {
                System.debug('old status >>>' + Trigger.oldMap?.get(item.Id)?.Status__c);
                System.debug('before>>new status1 >>>' + item.Status__c);
                item.Status__c = 'Pre-Go';
                System.debug('before>>new status2 >>>' + item.Status__c);
            }
        }
        if (Trigger.isAfter) {
            System.debug('end>>new status >>>' + item.Status__c);
            if (Trigger.isInsert) {
                System.debug('end----after insert >>>> ');
            }
            if (Trigger.isUpdate) {
                System.debug('end----after update >>>> ');
            }
        }
    }
}