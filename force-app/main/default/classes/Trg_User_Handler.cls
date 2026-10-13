/**
 * @author ULiT
 *  * @date 23/07/2025
 * @description Handler for the trigger Trg_Contact
 * */
public with sharing class Trg_User_Handler {
    public static void OnAfterInsertOrUpdate(List<User> nUsers, Map<Id, User> oUserMap) {
        //updateRelatedRecords(nUsers, oUserMap);
    }
    
    public static void updateRelatedRecords(List<User> nUsers, Map<Id, User> oUserMap) {
        system.debug(JSON.serialize(nUsers));
        system.debug(JSON.serialize(oUserMap));
        List<Id> contactIds = new List<Id>();
        Boolean updateContacts = false;
        for (User user : nUsers) {
            if (user.ContactId != null) {
                contactIds.add(user.ContactId);
            }
        }
        Map<Id, Contact> contactMap = contactIds.isEmpty() ? new Map<Id, Contact>() : new Map<Id, Contact>(
            [SELECT Id, Name, Title, MobilePhone, Phone, FirstName, LastName, Email 
                                FROM Contact 
                                WHERE Id IN :contactIds]
            );
        for (User item : nUsers) {
            if ((item.IsActive && oUserMap != null && oUserMap.containsKey(item.Id) && contactMap != null
            && hasFieldMismatch(item, oUserMap.get(item.Id), contactMap.get(item.ContactId)) || (oUserMap == null && contactMap.get(item.ContactId) != null)) ) {
                system.debug('run');
                updateContacts = true;
                Contact contact = contactMap.get(item.ContactId);
                contact.LastName = item?.LastName;
                contact.FirstName = item?.FirstName;
                contact.Email = item?.Email;
                contact.Title = item?.Title;
                contact.Phone = item?.Phone;
                contact.MobilePhone = item?.MobilePhone;
            }
        }
        if (updateContacts && contactMap != null) {
            List<Database.UpsertResult> result = Database.upsert(contactMap.values(), false);
            system.debug(JSON.serialize(result));
        }
        
    }
    
    private static Boolean hasFieldMismatch(SObject newUser, SObject oldUser, SObject contact) {
        try {
            List<String> fields = new List<String>{
                'LastName','FirstName','Email',
                'Title','Phone','MobilePhone'
            };
            for ( String f : fields ) {
                Object newVal     = newUser?.get(f);
                Object oldVal     = oldUser?.get(f);
                Object contactVal = contact?.get(f);
                if ( newVal != oldVal
                && contactVal != newVal ) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    
}