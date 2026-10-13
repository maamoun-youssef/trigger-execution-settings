/**
 * @author ULiT
 * @date 04/09/2025
 * Controller for ServiceStatementSettings
 */
public class ServiceStatementSettingsController {
    
    @AuraEnabled(cacheable=true)
    public static string loadServiceStatementSettings(String processName) {
        ResultWrapper wrapper = new ResultWrapper();
        // wrapper.serviceStatementSettings = ServiceStatementSettings.loadServiceStatementSettings('ServiceStatementSettings');
        String nameToLoad = String.isBlank(processName) ? 'ServiceStatementSettings' : processName;
        wrapper.serviceStatementSettings = ServiceStatementSettings.loadServiceStatementSettings(nameToLoad);
        wrapper.activeFlows = JSON.serialize(NegoptimHelper.getActiveScreenFlows());
        return JSON.serialize(wrapper);
    }
    
    @AuraEnabled
    public static String save(String serviceStatementSettingsJSON, String processName) {
        try {
            ServiceStatementSettings incoming  = String.isNotBlank(serviceStatementSettingsJSON) ? (ServiceStatementSettings) JSON.deserialize(serviceStatementSettingsJSON, ServiceStatementSettings.class) : new ServiceStatementSettings();
            ResultWrapper wrapper = new ResultWrapper();
            String nameToLoad = String.isBlank(processName) ? 'ServiceStatementSettings' : processName;
            wrapper.serviceStatementSettings = ServiceStatementSettings.loadServiceStatementSettings(nameToLoad);
            String newMode = incoming.generationMode;
            Integer newDay = incoming.autoPublishDay;
            Integer newMonth = incoming.autoPublishMonth;

            Boolean changed = (wrapper.serviceStatementSettings == null)
                || newMode != wrapper.serviceStatementSettings.generationMode
                || newDay != wrapper.serviceStatementSettings.autoPublishDay
                || newMonth != wrapper.serviceStatementSettings.autoPublishMonth;

            String saveResult = new ServiceStatementSettings().save(incoming);
            if (changed) {
                String jobName = 'InitSalesTermsStatementBatch_Auto__' + nameToLoad;
                List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName LIMIT 1];
                if (!jobs.isEmpty()) {
                    System.abortJob(jobs[0].Id);
                }
                 if (newMode == 'Automatic' && newDay != null && newMonth != null) {                  
                        String cron = '0 32 10 ' + newDay + ' ' + newMonth + ' ? *';
                        String jobId = System.schedule(jobName, cron, new InitSalesTermsStatementBatch('Schedule', null));                   
                }
            }
            return saveResult;
        } catch(Exception ex) {
            System.debug('ERROR: ' + ex.getMessage() + '' + ex.getLineNumber());
            return ex.getMessage();
        }
    }

    // Return available profile names so the combobox can be populated before a selection is made
    @AuraEnabled
    public static String listProfiles() {
        Set<String> names = new Set<String>();
        for (ServiceStatementSettings__mdt md : [
            SELECT DeveloperName, ProcessName__c
            FROM ServiceStatementSettings__mdt
        ]) {
            // Prefer the friendly field if present, else fall back on the record name
            names.add(String.isBlank(md.ProcessName__c) ? md.DeveloperName : md.ProcessName__c);
        }
        return JSON.serialize(new Map<String, Object>{ 'names' => new List<String>(names) });
    }

   @AuraEnabled(cacheable=true)
   public static String listFileDirectoryRecordTypes() {
       List<RecordType> rts = [
           SELECT Name, DeveloperName
           FROM RecordType
           WHERE SObjectType = 'FileDirectory__c' AND IsActive = TRUE
           ORDER BY Name
       ];
       List<Map<String, String>> out = new List<Map<String, String>>();
       for (RecordType rt : rts) {
           out.add(new Map<String, String>{ 'label' => rt.Name, 'value' => rt.DeveloperName });
       }
       return JSON.serialize(out);
   }

   @AuraEnabled(cacheable=true)
  public static String listFileDirectorySubTypes() {
    Schema.DescribeFieldResult dfr = Schema.SObjectType.FileDirectory__c.fields.getMap().get('SubType__c').getDescribe();
    List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
    List<Map<String, String>> out = new List<Map<String, String>>();
    for (Schema.PicklistEntry pe : entries) {
      if (pe.isActive()) {
        out.add(new Map<String, String>{ 'label' => pe.getLabel(), 'value' => pe.getValue() });
      }
    }
    out.sort(new ListMapStringSorter('label'));
    return JSON.serialize(out);
  }

  public class ListMapStringSorter implements System.Comparator<Map<String,String>> {
    String key;
    public ListMapStringSorter(String k){ key = k; }
    public Integer compare(Map<String,String> a, Map<String,String> b) {
      String av = (a != null && a.containsKey(key)) ? a.get(key) : null;
      String bv = (b != null && b.containsKey(key)) ? b.get(key) : null;
      if (av == null && bv == null) return 0;
      if (av == null) return -1;
      if (bv == null) return 1;
      return av.toLowerCase().compareTo(bv.toLowerCase());
    }
  }
    
    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        try {
            Object raw = SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
            if (raw instanceof String) {
                String s = (String) raw;
                try {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(s);
                    if (parsed != null && parsed.containsKey('deployResult')) {
                        return JSON.serialize(parsed);
                    }
                } catch (Exception ignore) {}
                return JSON.serialize(new Map<String, Object>{
                    'deployResult' => new Map<String, Object>{
                        'done'    => true,
                        'success' => s.equalsIgnoreCase('Succeeded') || s.equalsIgnoreCase('Success'),
                        'status'  => s
                    }
                });
            }
            Map<String, Object> normalized =
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(raw));

            if (normalized != null && normalized.containsKey('deployResult')) {
                return JSON.serialize(normalized);
            }
            Map<String, Object> dr = new Map<String, Object>();
            if (normalized != null) {
                if (normalized.containsKey('done'))    dr.put('done',    normalized.get('done'));
                if (normalized.containsKey('success')) dr.put('success', normalized.get('success'));
                if (normalized.containsKey('status'))  dr.put('status',  normalized.get('status'));
            }
            if (dr.isEmpty()) {
                dr.put('done', true);
                dr.put('success', false);
                dr.put('status', 'Unknown');
            }
            return JSON.serialize(new Map<String, Object>{ 'deployResult' => dr });
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ResultWrapper {
        public ServiceStatementSettings serviceStatementSettings {get; set;}
        public Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap {get; set;}
        public String prefix {get; set;}
        public String activeFlows {get; set;}
        public ResultWrapper() {
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.activeFlows = '';
            Map<String, Map<String, Schema.DescribeFieldResult>> fieldsMap = new Map<String, Map<String, Schema.DescribeFieldResult>> {
                SObjectType.ServiceStatementSettings__mdt.getName() => new Map<String, Schema.DescribeFieldResult>()
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
}