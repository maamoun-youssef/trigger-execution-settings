/**
 * @author ULiT
 * Control Batch Classes Cmp Controller
 **/
public with sharing class BatchesControlCmpController {
    
    /**
     * @description gets all the Batch ApexClass
     * to get all the batch ApexClasses set datalimit = 0 and offset = 0
     * @return map : key = ApexClass Name, value = ApexClass
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, ApexClass> getBatchClasses(Integer datalimit, Integer offset) {
        String query = '';
        query += 'SELECT Id, NamespacePrefix, Name'
                + ' FROM ApexClass'
                + ' WHERE Name LIKE \'%Batch\'';
        String nameSpacePrefix = '';
        nameSpacePrefix = NegoptimHelper.getPackagePrefix(true);
        if (nameSpacePrefix != '') {
            query += ' AND NamespacePrefix = \'' + nameSpacePrefix.remove('__') + '\'';
        }
        query += ' AND NAME <> \'' + 'NegoptimBatch' + '\'';
        query += ' ORDER BY Name ASC';
        if (datalimit == 0 && offset == 0) {
            query += ' LIMIT 1000';
        } else {
            query += ' LIMIT ' + datalimit
                    + ' OFFSET ' + offset;
        }
        //TODO get all classes? in and out pavkage?
        System.debug('query>>>>>>>: ' + query);
        List<ApexClass> batchClasses = new List<ApexClass> ();
         String[] fields = new String[] {
            SObjectType.ApexClass.fields.Id.Name,
            SObjectType.ApexClass.fields.Name.Name,
            SObjectType.ApexClass.fields.NamespacePrefix.Name
        };
        if (NegoptimHelper.checkAccessibility(ApexClass.SObjectType, fields)) {
            batchClasses = Database.query(query);
        }
        Map<String, ApexClass> batchesMap = new Map<String, ApexClass>();
        for (ApexClass item : batchClasses) {
            batchesMap.put(item.Name, item);

        }
        return batchesMap;
    }    

    /**
     * @description gets the number of all the batchClasses
     * @return Integer of the number
     */
    @AuraEnabled
    public static Integer getNumberOfBatchSettings() {
        return getBatchClasses(0,0).values().size();
    }
    
    /**
     * @description gets all the profiles
     * @return List of profiles
     */
    @AuraEnabled(cacheable=true)
    public static List<Profile> getAllProfiles() {
        List<Profile> profiles = new List<Profile>();
         String[] profileFields = new String[] {
            SObjectType.Profile.fields.Id.Name,
            SObjectType.Profile.fields.Name.Name
        };
        if (NegoptimHelper.checkAccessibility(Profile.SObjectType, profileFields)) {
            profiles = [SELECT Id, Name FROM Profile ORDER BY Name ASC LIMIT 1000];
        }
        return profiles;
    }

    /**
     * @description gets the Batch_Settings__mdt fields for the columns of the tables
     * @return List of the fields labels
     */
    @AuraEnabled
    public static List<String> getBatchSettingsFields() {
        return new List<String> {SObjectType.Batch_Settings__mdt.fields.MasterLabel.Label,
            SObjectType.Batch_Settings__mdt.fields.Active__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Description__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email_Technical__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Notification__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Sender__c.Label,
            SObjectType.Batch_Settings__mdt.fields.Email_Subject__c.Label};
    }

    /**
     * @description gets all the OrgWideEmailAddress 
     * @return List of OrgWideEmailAddress
     */
    @AuraEnabled
    public static List<OrgWideEmailAddress> getOrganizationWideAddresses() {
        List<OrgWideEmailAddress> orgWideEmailAddresses = new List<OrgWideEmailAddress>();
         String[] orgWideEmailAddressesFields = new String[] {
            SObjectType.OrgWideEmailAddress.fields.Id.Name,
            SObjectType.OrgWideEmailAddress.fields.Address.Name,
            SObjectType.OrgWideEmailAddress.fields.DisplayName.Name,
            SObjectType.OrgWideEmailAddress.fields.IsAllowAllProfiles.Name
        };
        if (NegoptimHelper.checkAccessibility(OrgWideEmailAddress.SObjectType, orgWideEmailAddressesFields)) {
            orgWideEmailAddresses = [SELECT Id, Address, DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress LIMIT 1000];
        }
        return orgWideEmailAddresses;
    }

    /**
     * @description gets all the Batch_Settings__mdt for a certain profile
     * it gets all the BatchSettings existing in the database then it constructs the rest of the values depending 
     * on the default values (Active__c = true, MasterLabel = ClassName, Allow_Sending_Email__c = true, 
     * Allow_Sending_Email_Technical__c = false, Allow_Sending_Notification__c = true, Profile_Id__c = profileId, Description__c = '' ) and it merges them 
     * @return List of Batch_Settings__mdt
     */
    @AuraEnabled
    public static List<BatchSettingsValuesWrapper> getBatchSettings(Id profileId) {
        Map<String, BatchSettingsValuesWrapper> batchSettingsMap = new Map<String, BatchSettingsValuesWrapper>();
        Map<String, ApexClass> allBatches = getBatchClasses(0, 0);
        for (String key: allBatches.keyset()) {
            String metadataRecordName = allBatches.get(key).Id + '_' + profileId;
            metadataRecordName = metadataRecordName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll('\\s+', '_');
            Batch_Settings__mdt batchSettings = new Batch_Settings__mdt(DeveloperName = 'Bth_' + metadataRecordName, Active__c = true, MasterLabel = key,
                                                                        Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = false, Allow_Sending_Notification__c = true, Profile_Id__c = profileId, Sender__c = '', Email_Subject__c = '');
            BatchSettingsValuesWrapper batchSettinsWrapper = new BatchSettingsValuesWrapper(batchSettings);
            batchSettingsMap.put('Bth_' + metadataRecordName, batchSettinsWrapper);
        }
        String[] batchSettingsFields = new String[] {
            SObjectType.Batch_Settings__mdt.fields.Id.Name,
            SObjectType.Batch_Settings__mdt.fields.DeveloperName.Name,
            SObjectType.Batch_Settings__mdt.fields.Active__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email_Technical__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Notification__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Profile_Id__c.Name,
            SObjectType.Batch_Settings__mdt.fields.MasterLabel.Name,
            SObjectType.Batch_Settings__mdt.fields.Description__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Sender__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Email_Subject__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Batch_Settings__mdt.SObjectType, batchSettingsFields)) {
            for (Batch_Settings__mdt item : [SELECT Id, DeveloperName, Sender__c, Email_Subject__c, Active__c, Allow_Sending_Email__c, Allow_Sending_Email_Technical__c, Allow_Sending_Notification__c, Profile_Id__c, MasterLabel, Description__c
                                            FROM Batch_Settings__mdt
                                            WHERE Profile_Id__c = :profileId
                                            ORDER BY MasterLabel ASC
                                            LIMIT 1000])
            {
                if(batchSettingsMap.containsKey(item.DeveloperName) && batchSettingsMap.get(item.DeveloperName).MasterLabel == item.MasterLabel) {
                    BatchSettingsValuesWrapper wrapperItem = new BatchSettingsValuesWrapper(item);
                    batchSettingsMap.put(item.DeveloperName, wrapperItem);
                }
            }
        }
        List<BatchSettingsValuesWrapper> metadataList = batchSettingsMap.values();
        metadataList.sort();
        return metadataList;
    }

    /**
     * @description gets a number = datalimit of Batch_Settings__mdt for all the profiles
     * @return List of BatchSettingsWrapper
     */
    @AuraEnabled
    public static List <BatchSettingsWrapper> getAllBatchSettings(Integer datalimit, Integer offset) {
        Map<String, ApexClass> allBatches = getBatchClasses(datalimit, offset);
        Map<String, Map<Profile, BatchSettingsValuesWrapper>> batchSettingsMap = new Map<String, Map<Profile, BatchSettingsValuesWrapper>>();
        List<Profile> profiles = getAllProfiles();
        for (String key: allBatches.keySet()) {
            Map<Profile, BatchSettingsValuesWrapper> batchesForProfileMap = new Map<Profile, BatchSettingsValuesWrapper>();
            for (Profile profile : profiles) {
                String metadataRecordName = allBatches.get(key).Id + '_' + profile.Id;
                metadataRecordName = metadataRecordName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll('\\s+', '_');
                Batch_Settings__mdt batchSettings = new Batch_Settings__mdt(DeveloperName = 'Bth_' + metadataRecordName, Active__c = true, MasterLabel = key,
                                                                            Allow_Sending_Email__c = true, Allow_Sending_Email_Technical__c = false, Allow_Sending_Notification__c = true, Profile_Id__c = profile.Id,
                                                                            Sender__c = '', Email_Subject__c = '');
                BatchSettingsValuesWrapper batchSettingsValueWrapper = new BatchSettingsValuesWrapper(batchSettings);
                batchesForProfileMap.put(profile, batchSettingsValueWrapper);
            }
            batchSettingsMap.put(key, batchesForProfileMap);
        }
        String[] batchSettingsFields = new String[] {
            SObjectType.Batch_Settings__mdt.fields.Id.Name,
            SObjectType.Batch_Settings__mdt.fields.DeveloperName.Name,
            SObjectType.Batch_Settings__mdt.fields.Active__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email_Technical__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Notification__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Profile_Id__c.Name,
            SObjectType.Batch_Settings__mdt.fields.MasterLabel.Name,
            SObjectType.Batch_Settings__mdt.fields.Description__c.Name,
            SObjectType.Batch_Settings__mdt.fields.Sender__c.Name
        }; 
        List<BatchSettingsValuesWrapper> batchSettingsList = new List<BatchSettingsValuesWrapper>();
        if (NegoptimHelper.checkAccessibility(Batch_Settings__mdt.SObjectType, batchSettingsFields)) {
            for (Batch_Settings__mdt item : [SELECT Id, DeveloperName, Sender__c, Email_Subject__c, Active__c, Allow_Sending_Email__c, Allow_Sending_Email_Technical__c, Allow_Sending_Notification__c, Profile_Id__c, MasterLabel, Description__c
                                            FROM Batch_Settings__mdt
                                            WHERE MasterLabel IN :batchSettingsMap.keySet()
                                            ORDER BY MasterLabel ASC
                                            LIMIT 1000])
            {
                BatchSettingsValuesWrapper wrapperItem = new BatchSettingsValuesWrapper(item);
                batchSettingsList.add(wrapperItem);
                for (Profile profile: profiles) {
                    if (profile.Id == wrapperItem.ProfileId) {
                        if (batchSettingsMap.get(wrapperItem.MasterLabel) != null)
                            batchSettingsMap.get(wrapperItem.MasterLabel).put(profile, wrapperItem);
                    }
                }
                batchSettingsMap.put(wrapperItem.MasterLabel, batchSettingsMap.get(item.MasterLabel));
            }
        }
        List<BatchSettingsWrapper> batchSettingsWrapperList = new List <BatchSettingsWrapper>();
        Integer total = getBatchClasses(0,0).values().size();
        for (String key : allBatches.keySet()) {
            if (batchSettingsMap.get(key) != null) {
                BatchSettingsWrapper batchWrapper = new BatchSettingsWrapper(key, batchSettingsMap.get(key).values(), total);
                batchSettingsWrapperList.add(batchWrapper);
            }
        }
        return batchSettingsWrapperList;
    }

    /**
     * @description save Batch Settings Metadata
     * @param jsonBatchesSettings list of batch Settings to save
     */
    @AuraEnabled
    public static String saveMetadata(String jsonBatchesSettings) {
        Id jobId = null;
        try {
            List<BatchSettingsValuesWrapper> BatchSettingsList = (List<BatchSettingsValuesWrapper>)JSON.deserialize(jsonBatchesSettings, List<BatchSettingsValuesWrapper>.class);
            
            Map<String, ApexClass> batchesMap = getBatchClasses(0, 0);
            if (BatchSettingsList.size() > 0) {
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                for (BatchSettingsValuesWrapper item : BatchSettingsList) {
                    Batch_Settings__mdt mdtItem = item.toBatcheSettings();
                    ApexClass batch = batchesMap.get(mdtItem.MasterLabel);
                    System.debug('to save ' +JSON.serialize(batch));
                    if (batch != null) {
                        String metadataRecordName = batch.Id + '_' + mdtItem.Profile_Id__c;
                        metadataRecordName = metadataRecordName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll('\\s+', '_');
                        // Set up custom metadata to be created in the subscriber org.
                        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                        customMetadata.fullName = SObjectType.Batch_Settings__mdt.Name+'.Bth_' + metadataRecordName;
                        customMetadata.label = batch.Name;
                        //Active__c
                        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Active__c.Name;
                        customField.value = mdtItem.Active__c;
                        customMetadata.values.add(customField);
                        //Allow_Sending_Email__c
                        customField = new Metadata.CustomMetadataValue();  
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email__c.Name;
                        customField.value = mdtItem.Allow_Sending_Email__c;
                        customMetadata.values.add(customField);
                        //Allow_Sending_Email_Technical__c
                        customField = new Metadata.CustomMetadataValue();  
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Email_Technical__c.Name;
                        customField.value = mdtItem.Allow_Sending_Email_Technical__c;
                        customMetadata.values.add(customField);
                        //Allow_Sending_Notification__c
                        customField = new Metadata.CustomMetadataValue();  
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Allow_Sending_Notification__c.Name;
                        customField.value = mdtItem.Allow_Sending_Notification__c;
                        customMetadata.values.add(customField);
                        //Description__c
                        customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Description__c.Name;
                        customField.value = mdtItem.Description__c;
                        customMetadata.values.add(customField);
                        //Profile_Id__c
                        customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Profile_Id__c.Name;
                        customField.value = mdtItem.Profile_Id__c;
                        customMetadata.values.add(customField);
                        //Sender__c
                        customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Sender__c.Name;
                        customField.value = String.isNotEmpty(mdtItem.Sender__c) ? mdtItem.Sender__c : null;
                        customMetadata.values.add(customField);
                        //Email_Subject__c
                        customField = new Metadata.CustomMetadataValue();
                        customField.field = SObjectType.Batch_Settings__mdt.fields.Email_Subject__c.Name;
                        customField.value = String.isNotEmpty(mdtItem.Email_Subject__c) ? mdtItem.Email_Subject__c : null;
                        customMetadata.values.add(customField);
                        mdContainer.addMetadata(customMetadata);
                    }
                }
                if (!Test.isRunningTest()) {
                    // Setup deploy callback, MyDeployCallback implements
                    // the Metadata.DeployCallback interface
                    CustomMetadataCallback callback = new CustomMetadataCallback();
                    // Enqueue custom metadata deployment
                    // jobId is the deployment ID
                    jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
                }
            }
        } catch (DMLException ex) {
            System.debug('Exception>>>' + ex.getStackTraceString());
        } catch (Exception ex) {
            System.debug('Exception>>>' + ex.getStackTraceString());
        }
        return jobId;
    }

    /**
     * @description wrapper class for batch Settings for the matrix view
     */
    public class BatchSettingsWrapper {
        @AuraEnabled public Integer total;
        @AuraEnabled public String key;
        //@AuraEnabled public String className;
        @AuraEnabled public List<BatchSettingsValuesWrapper> value;
        /**
         * @description constructer for the BatchSettingsWrapper class
         * @param key MasterLabel of the batch class
         * @param value list of all the batches having MasterLabel = key (for all the Profiles)
         * @param total number of all the batches having MasterLabel = key
         */
        public BatchSettingsWrapper (String key, List<BatchSettingsValuesWrapper> value, Integer total) {
            this.key = key;
            this.value = value;
            this.total = total;
        }
    }
    
    /**
     * @description wrapper class for batch Settings fields for the matrix view
     */
    public class BatchSettingsValuesWrapper implements Comparable{
        @AuraEnabled public String DeveloperName;
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String ProfileId;
        @AuraEnabled public String Sender;
        @AuraEnabled public String EmailSubject;
        @AuraEnabled public String Description;
        @AuraEnabled public Boolean Active;
        @AuraEnabled public Boolean AllowSendingEmail;
        @AuraEnabled public Boolean AllowSendingEmailTechnical;
        @AuraEnabled public Boolean AllowSendingNotification;
        
        public BatchSettingsValuesWrapper(Batch_Settings__mdt batcheSettings) {
            this.DeveloperName = batcheSettings.DeveloperName;
            this.MasterLabel = batcheSettings.MasterLabel;
            this.ProfileId = batcheSettings.Profile_Id__c;
            this.Sender = batcheSettings.Sender__c;
            this.EmailSubject = batcheSettings.Email_Subject__c;
            this.Description = batcheSettings.Description__c;
            this.Active = batcheSettings.Active__c;
            this.AllowSendingEmail = batcheSettings.Allow_Sending_Email__c;
            this.AllowSendingEmailTechnical = batcheSettings.Allow_Sending_Email_Technical__c;
            this.AllowSendingNotification = batcheSettings.Allow_Sending_Notification__c;
        }
        
        public Batch_Settings__mdt toBatcheSettings() {
            Batch_Settings__mdt batcheSettings = new Batch_Settings__mdt();
            batcheSettings.DeveloperName = DeveloperName;
            batcheSettings.MasterLabel = MasterLabel;
            batcheSettings.Profile_Id__c = ProfileId;
            batcheSettings.Sender__c  = Sender;
            batcheSettings.Email_Subject__c = EmailSubject;
            batcheSettings.Active__c = Active;
            batcheSettings.Allow_Sending_Email__c = AllowSendingEmail;
            batcheSettings.Allow_Sending_Email_Technical__c = AllowSendingEmailTechnical;
            batcheSettings.Allow_Sending_Notification__c = AllowSendingNotification;
            batcheSettings.Description__c = Description;
            return batcheSettings;
        }
        
        public Integer compareTo(Object objToCompare) {
            BatchSettingsValuesWrapper batchSetting = (BatchSettingsValuesWrapper)objToCompare;
            if (MasterLabel == batchSetting.MasterLabel) {
                return 0;
            } else if (MasterLabel > batchSetting.MasterLabel) {
                return 1;
            } else {
                return -1;
            }
        }
    }
}