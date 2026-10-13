trigger Trg_Print_event on PrintInvoice__e (after insert) {
    // forward mode
    List<String> forwardModes = new List<String>{
        'initPrint',
        'printPdf',
        'printEinvoice',
        'sendNotifications',
        'DonePrinting'
    };

    List<String> backwardModes = new List<String>{
        'RB_sendNotifications',
        'RB_printEinvoice',
        'RB_printPdf',
        'RB_initPrint',
        'RB_init'
    };

    Map<String, Integer> mfmMap = new Map<String, Integer>();
    Map<String, Integer> mbmMap = new Map<String, Integer>();
    Integer index = 0;
    for (String mode : forwardModes) {
        mfmMap.put(mode, (index + 1) == forwardModes.size() ? -1 : (index + 1));
        index++;
        System.debug('mfmMap >>> ' + index + '/' + forwardModes.size() + ' >>> ' + JSON.serialize(mfmMap));
    }
    index = 0;
    for (String mode : backwardModes) {
        mbmMap.put(mode, (index + 1) == backwardModes.size() ? -1 : (index + 1));
        index++;
        System.debug('mbmMap >>> ' + index + '/' + backwardModes.size() + ' >>> ' + JSON.serialize(mbmMap));
    }

    System.debug('hello from Trg_Print_event');
    System.debug('Trigger.new >>> ' + JSON.serialize(Trigger.New));
    if(Trigger.isInsert && Trigger.isAfter) {
        List<PrintInvoice__e> events = new List<PrintInvoice__e>();
        List<Aptt__c> apttTpUpdate = new List<Aptt__c>();
        for (PrintInvoice__e item : Trigger.New) {
            System.debug('item.Mode__c >>> ' + item.Mode__c);
            System.debug('item.RecordId__c >>> ' + item.RecordId__c);
            String mode;
            if (mfmMap.containsKey(item.Mode__c) && mfmMap.get(item.Mode__c) != -1) {
                mode = forwardModes[mfmMap.get(item.Mode__c)];
            }
            if (mbmMap.containsKey(item.Mode__c) && mbmMap.get(item.Mode__c) != -1) {
                mode = backwardModes[mbmMap.get(item.Mode__c)];
            }
            System.debug('next mode >>> ' + mode);
            if (String.isNotBlank(mode)) {
                events.add(new PrintInvoice__e(Mode__c = mode, RecordId__c = item.RecordId__c));
                apttTpUpdate.add(new Aptt__c(Id = item.RecordId__c, Status__c = mode));
            }
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
        if (!apttTpUpdate.isEmpty()) {
            update apttTpUpdate;
        }
    }
}