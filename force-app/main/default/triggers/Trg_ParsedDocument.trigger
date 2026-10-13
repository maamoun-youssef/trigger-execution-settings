trigger Trg_ParsedDocument on nTemplate__ParsedDocument__c (before insert) {
    for (nTemplate__ParsedDocument__c item : Trigger.new) {
        System.debug('nTemplate__IsFileShared__c>>> ' + item.nTemplate__IsFileShared__c);
        System.debug('nTemplate__ContentVersion__c>>> ' + item.nTemplate__ContentVersion__c);
        System.debug('nTemplate__ParentRecordId__c>>> ' + item.nTemplate__ParentRecordId__c);
    }
}