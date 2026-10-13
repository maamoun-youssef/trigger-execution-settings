/**
 * Controller for buListManagerSettings LWC (myOrg Settings > BU List Manager Configuration)
 **/
public with sharing class BUListManagerSettingsCtrl {

    @AuraEnabled
    public static String getData() {
        try {
            ResultWrapper wrapper = new ResultWrapper();
            // Grid settings templates defined on Business Unit
            String[] gridSettingsFields = new String[] {
                SObjectType.Grid_Settings__mdt.fields.Object_Name__c.Name,
                SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
                SObjectType.Grid_Settings__mdt.fields.Label.Name
            };
            if (NegoptimHelper.checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
                for (Grid_Settings__mdt item : [SELECT DeveloperName, Label
                                                FROM Grid_Settings__mdt
                                                WHERE Object_Name__c = :SObjectType.BusinessUnit__c.Name
                                                WITH USER_MODE
                                                ORDER BY Label])
                {
                    wrapper.gridSettingsOptions.add(new GridSettingsOption(item.Label, item.DeveloperName));
                }
            }
            OrgSettings orgSettings = OrgSettings.loadOrgSettings();
            if (orgSettings != null && orgSettings.buListManagerConfiguration != null) {
                wrapper.buListManagerConfiguration = orgSettings.buListManagerConfiguration;
            }
            return JSON.serialize(wrapper);
        } catch (Exception ex) {
            throw new AuraHandledException('An error occurred while retrieving metadata: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveSettings(String buListManagerConfigurationJSON) {
        try {
            OrgSettings.BUListManagerConfiguration configuration = String.isNotBlank(buListManagerConfigurationJSON)
                ? (OrgSettings.BUListManagerConfiguration) JSON.deserialize(buListManagerConfigurationJSON, OrgSettings.BUListManagerConfiguration.class)
                : null;
            return OrgSettings.saveBUListManagerConfiguration(configuration);
        } catch (Exception ex) {
            throw new AuraHandledException('An error occurred while saving settings: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String checkDeploymentStatus(String idDeployment) {
        return SettingsManager.checkCustomMetadataDeploymentStatus(idDeployment);
    }

    public class GridSettingsOption {
        public String label;
        public String value;
        public GridSettingsOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ResultWrapper {
        public List<GridSettingsOption> gridSettingsOptions = new List<GridSettingsOption>();
        public OrgSettings.BUListManagerConfiguration buListManagerConfiguration = new OrgSettings.BUListManagerConfiguration();
    }
}