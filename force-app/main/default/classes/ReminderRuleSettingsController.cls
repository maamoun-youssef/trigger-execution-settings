/**
 * @author ULiT
 * @date 04/09/2025
 * Controller for Reminder Rule Settings
 */
public class ReminderRuleSettingsController {

  // Normalize/process a human profile name to a safe DeveloperName key
  private static String devKey(String name) {
    String base = String.valueOf(name).trim();
    if (String.isBlank(base)) base = 'ReminderRuleSettings';
    base = base.replaceAll('\\s+', '_');
    base = base.replaceAll('[^a-zA-Z0-9_]', '');
    base = base.replaceAll('_+', '_');
    return base;
  }

    @AuraEnabled(cacheable=true)
    public static String loadAllReminderRule(String processName) {
    ResultWrapper wrapper = new ResultWrapper();
    List<ReminderRuleSettings__mdt> rows = [
      SELECT DeveloperName
      FROM ReminderRuleSettings__mdt
      ORDER BY DeveloperName
      LIMIT 1000
    ];
    wrapper.profiles = new List<SelectOption>();
    for (ReminderRuleSettings__mdt r : rows) {
      wrapper.profiles.add(new SelectOption(r.DeveloperName, r.DeveloperName));
    }
    String key = String.isBlank(processName)? (rows.isEmpty() ? null : rows[0].DeveloperName): devKey(processName);
    wrapper.processName = key;
    ReminderRuleSettings dto = new ReminderRuleSettings();
    if (key != null) {
      List<ReminderRuleSettings__mdt> selected = [
        SELECT ReminderDay1__c, ReminderMonth1__c,
               ReminderDay2__c, ReminderMonth2__c,
               ReminderDay3__c, ReminderMonth3__c,
               ReminderFlow__c
        FROM ReminderRuleSettings__mdt
        WHERE DeveloperName = :key
        LIMIT 1
      ];
      if (!selected.isEmpty()) {
        ReminderRuleSettings__mdt m = selected[0];
        dto.reminderDay1   = (Integer) m.ReminderDay1__c;
        dto.reminderMonth1 = (Integer) m.ReminderMonth1__c;
        dto.reminderDay2   = (Integer) m.ReminderDay2__c;
        dto.reminderMonth2 = (Integer) m.ReminderMonth2__c;
        dto.reminderDay3   = (Integer) m.ReminderDay3__c;
        dto.reminderMonth3 = (Integer) m.ReminderMonth3__c;
        dto.reminderFlow   = m.ReminderFlow__c;
      }
    }
    wrapper.reminderRuleSettings = dto;
    wrapper.activeFlows = JSON.serialize(NegoptimHelper.getActiveScreenFlows());
    return JSON.serialize(wrapper);
  }

    // @AuraEnabled
    // public static String save(String reminderRuleSettingsJSON) {
    //     try {
    //         ReminderRuleSettings reminderRuleSettings = String.isNotBlank(reminderRuleSettingsJSON) ? (ReminderRuleSettings) JSON.deserialize(reminderRuleSettingsJSON, ReminderRuleSettings.class) : new ReminderRuleSettings();
    //         return ReminderRuleSettings.save(reminderRuleSettings);
    //     } catch(Exception ex) {
    //         System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
    //         return ex.getMessage();
    //     }
    // }

    @AuraEnabled
    public static String save(String reminderRuleSettingsJSON) {
        try {
            // Extract profile key from raw JSON (works even if DTO lacks processName)
            Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(reminderRuleSettingsJSON);
            String key = devKey((String) (raw != null ? raw.get('processName') : null));

            // Deserialize business fields into your existing DTO
            ReminderRuleSettings dto = String.isNotBlank(reminderRuleSettingsJSON)
                ? (ReminderRuleSettings) JSON.deserialize(reminderRuleSettingsJSON, ReminderRuleSettings.class)
                : new ReminderRuleSettings();

            // Build CMDT record via Metadata API (ServiceStatement-style)
            Metadata.DeployContainer dc = new Metadata.DeployContainer();
            dc.addMetadata(buildReminderRuleCmdt(key, dto));

            // Enqueue deployment (your LWC can poll checkDeploymentStatus)
            Id asyncJobId = Metadata.Operations.enqueueDeployment(dc, null);
            return String.valueOf(asyncJobId);
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + ' @ line ' + ex.getLineNumber());
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }
    
    public class ResultWrapper {
        public ReminderRuleSettings reminderRuleSettings {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        public String prefix {get; set;}
        public String activeFlows {get; set;}
        public String processName {get; set;}
        public List<SelectOption> profiles {get; set;}
        public ResultWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.activeFlows = '';
            this.profiles = new List<SelectOption>();
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.ReminderRuleSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
            };
            for (String objectName : fieldsMap.keySet()) {
                Map<String, Schema.DescribeFieldResult> fieldMap = fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    DescribeFieldResult dfr = field.getDescribe();
                    fieldMap.put(dfr.getName(), field.getDescribe());
                }
            }
            this.fieldsMap = fieldsMap;
        }
    }
    
    public class SelectOption {
        public String value;
        public String label;
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    // --- helper (mirrors ServiceStatement controller pattern) ---
    private static Metadata.CustomMetadata buildReminderRuleCmdt(String key, ReminderRuleSettings dto) {
        String typeApi = NegoptimHelper.getPackagePrefix(true) + 'ReminderRuleSettings__mdt';

        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = typeApi + '.' + key;  // e.g., ns__ReminderRuleSettings__mdt.My_Profile
        cmd.label    = key;                   // MasterLabel

        List<Metadata.CustomMetadataValue> values = new List<Metadata.CustomMetadataValue>();

        Metadata.CustomMetadataValue v;
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderDay1__c';   v.value = dto.reminderDay1;   values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderMonth1__c'; v.value = dto.reminderMonth1; values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderDay2__c';   v.value = dto.reminderDay2;   values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderMonth2__c'; v.value = dto.reminderMonth2; values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderDay3__c';   v.value = dto.reminderDay3;   values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderMonth3__c'; v.value = dto.reminderMonth3; values.add(v);
        v = new Metadata.CustomMetadataValue(); v.field = 'ReminderFlow__c';   v.value = dto.reminderFlow;   values.add(v);

        cmd.values = values;
        return cmd;
    }
}