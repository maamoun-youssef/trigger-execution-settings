/**
 * @author ULiT
 * @date 04/09/2025
 * Controller for Connect Settings – STS + Reminder Rules
 * (Common controller with separate load/save methods per settings class)
 */
public with sharing class ConnectSettingsSTSController {
    // --- Public DTOs ---
    /*public class MainWrapper {
        @AuraEnabled public String prefix;
        @AuraEnabled public Map<String, Map<String, FieldDescribeWrapper>> fieldsMap; // <ObjectApiName,<FieldApiName,desc>>
        @AuraEnabled public STSSettings stsSettings;
        @AuraEnabled public List<FlowOption> activeScreenFlows;
    }
    public class FieldDescribeWrapper {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String inlineHelpText;
        public FieldDescribeWrapper(String apiName, String label, String inlineHelpText) {
            this.apiName = apiName; this.label = label; this.inlineHelpText = inlineHelpText;
        }
    }
    public class FlowOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public FlowOption(String value, String label) { this.value = value; this.label = label; }
    }

    // ----- LOADERS -----
    @AuraEnabled(cacheable=true)
    public static String loadSTSSettings() {
        MainWrapper w = new MainWrapper();
        // Namespace/prefix for front-end composition (same pattern used in Nego UI)
        w.prefix = (Schema.getGlobalDescribe().get('Invoice__c') != null) ? '': ''; // keep empty if no ns
        // Settings row
        w.stsSettings = STSSettings.loadSTSSettings();

        // Fields describe map for labels/help (STS__mdt only here)
        w.fieldsMap = new Map<String, Map<String, FieldDescribeWrapper>>();
        w.fieldsMap.put(String.valueOf(STS__mdt.SObjectType),
            buildFieldMap(STS__mdt.SObjectType.getDescribe().fields.getMap()));

        // Active screen flows for the Supplier Submission Flow combobox
        // w.activeScreenFlows = getActiveScreenFlows();
        return JSON.serialize(w);
    }

    @AuraEnabled(cacheable=true)
    public static String loadReminderRuleSettings() {
        // Load the single ReminderRule settings record
        ReminderRuleSettings s = ReminderRuleSettings.loadReminderRuleSettings();

        // Active Screen Flows (same source you used for STS flows)
        List<Map<String,String>> flows = new List<Map<String,String>>();
        // for (FlowDefinitionView f : [
        //     SELECT DeveloperName, MasterLabel, IsActive
        //     FROM FlowDefinitionView
        //     WHERE IsActive = true
        //     ORDER BY MasterLabel
        // ]) {
        //     flows.add(new Map<String,String>{
        //         'label' => f.MasterLabel,
        //         'value' => f.DeveloperName
        //     });
        // }

        Map<String,Object> payload = new Map<String,Object>{
            'fieldsMap'            => new Map<String,Object>(),
            'activeScreenFlows'    => flows,
            'reminderRuleSettings' => s
        };
        return JSON.serialize(payload);
    }

    // ----- SAVERS -----
    @AuraEnabled
    public static String saveSTSSettings(String stsSettingsJson) {
        STSSettings incoming = (STSSettings) JSON.deserialize(stsSettingsJson, STSSettings.class);
        // Basic validation (UI also enforces this, but keep server guard):
        if (incoming != null && incoming.salesTermsGenerationMode == 'Automatic') {
            if (incoming.salesTermsAutoPublishDay == null || incoming.salesTermsAutoPublishMonth == null) {
                throw new AuraHandledException('Auto-send Date is required when Generation Mode is Automatic.');
            }
        }
        return (new STSSettings()).save(incoming);
    }

    @AuraEnabled
    public static String saveReminderRuleSettings(String reminderRuleSettingsJson) {
        ReminderRuleSettings req =
            (ReminderRuleSettings) JSON.deserialize(reminderRuleSettingsJson, ReminderRuleSettings.class);
        String resultKey = req.save(req);
        return JSON.serialize(new Map<String,Object>{ 'result' => resultKey });
    }

    // ----- Helpers -----
    private static Map<String, FieldDescribeWrapper> buildFieldMap(Map<String, Schema.SObjectField> fmap) {
        Map<String, FieldDescribeWrapper> out = new Map<String, FieldDescribeWrapper>();
        for (String api : fmap.keySet()) {
            Schema.DescribeFieldResult d = fmap.get(api).getDescribe();
            out.put(api, new FieldDescribeWrapper(api, d.getLabel(), d.getInlineHelpText()));
        }
        return out;
    }

    /*
    private static List<FlowOption> getActiveScreenFlows() {
        List<FlowOption> opts = new List<FlowOption>();
        for (Flow f : [
            SELECT Id, DeveloperName, MasterLabel
            FROM Flow
            WHERE Status = 'Active' AND ProcessType = 'ScreenFlow'
            ORDER BY MasterLabel
        ]) {
            opts.add(new FlowOption(f.DeveloperName, f.MasterLabel));
        }
        return opts;
    }
	*/
}