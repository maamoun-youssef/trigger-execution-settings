/**
 * @author ULiT Team
 * @date JUN-1-2017
 * @group Negoptim Support
 * @description Controller to handle GlobalSettings page action for updating global settings
 ***************************************************************************************************************************************** */
public with sharing class GlobalSettingsController extends NegoptimBaseController {

    public List<PriceListSettingWrapper> priceListSettingsWrapperList {get; set;}
    public List<SelectOption> roleSelectList {get; set;}
    public List<SelectOption> buSelectList {get; set;}
    public String roleSearchTerm {get; set;}
    public String buSearchTerm {get; set;}
    public List<String> errors {get; set;}
    public NegoptimSettings negoSettings {get; set;}
    public SelectOption blankSelectOption {get; set;}
    public Map<String, List<SelectOption>> gridSettingsLayoutsMap {get; set;}
    public String gridSettingsLayoutsMapSerialized {
        get {
            return JSON.serialize(gridSettingsLayoutsMap.keySet());
        }
        set;}
    public String selectedRecordTypesNOptions {get; set;}
    public String selectedRecordTypesN1Options {get; set;}
    public String selectedRecordTypesPostNegoNOptions {get; set;}
    public String selectedRecordTypesPostNegoN1Options {get; set;}
    /**
     * temporary value for checking if this settings exists before saving
	********************************************************************** */
    public String tempBusinessType {get; set;}
    /**
     * the string value of None option for comparisson in page
	********************************************************************** */
    public String businessTypeNone {
        get {
            return NegoptimSettings.BusinessType.None.name();
        }
    }
    /**
     * represents the string value of the year 2 years agao
	********************************************************************** */
    public String P2 {
        get {
            return String.valueOf(date.today().year() - 2);
        }
    }
    /**
     * represents the string value of the year 1 years agao
	********************************************************************** */
    public String P1 {
        get {
            return String.valueOf(date.today().year() - 1);
        }
    }

    public List<SelectOption> assortmentSynchroModeOptions {
        get {
            return new List<SelectOption> {
                new SelectOption('Conso', 'Conso'),
                new SelectOption('Diffusion', 'Diffusion')
            };
        }
        private set;
    }

     public List<SelectOption> grcContractDataSourceOptions {
        get {
            return new List<SelectOption> {
                new SelectOption('Nego', 'Nego'),
                new SelectOption('Statement', 'Statement')
            };
        }
        private set;
    }

    /**
	 * @description Constructor load global settings
	 ********************************************************************** */
    public GlobalSettingsController() {
        negoSettings = GlobalSettingsManager.loadGlobalSettings();
        priceListSettingsWrapperList = new List<PriceListSettingWrapper>();
        Map<Id, PriceListSettingWrapper> buMapping = new Map<Id, PriceListSettingWrapper>();
        Map<Id, PriceListSettingWrapper> roleMapping = new Map<Id, PriceListSettingWrapper>();
        if (!negoSettings.priceListInitDefaultBUMap.isEmpty()) {
            for (Id key : negoSettings.priceListInitDefaultBUMap.keySet()) {
                if (String.isNotBlank(key) && String.isNotBlank(negoSettings.priceListInitDefaultBUMap.get(key))) {
                    PriceListSettingWrapper priceListSettingsWp = new PriceListSettingWrapper();
                    priceListSettingsWp.buId = negoSettings.priceListInitDefaultBUMap.get(key);
                    priceListSettingsWp.roleId = key;
                    buMapping.put(priceListSettingsWp.buId, priceListSettingsWp);
                    roleMapping.put(priceListSettingsWp.roleId, priceListSettingsWp);
                }
            }
            if (!roleMapping.isEmpty()) {
                if (checkAccessibility(UserRole.SObjectType, new List<String>{SObjectType.UserRole.fields.Id.Name, SObjectType.UserRole.fields.Name.Name, SObjectType.UserRole.fields.PortalType.Name})) {
                    for (UserRole item : [SELECT Id, Name FROM UserRole WHERE Id IN :roleMapping.keySet() AND PortalType = 'None']) {
                        if (!roleMapping.containsKey(item.Id)) continue;
                        PriceListSettingWrapper priceListSettingsWp = roleMapping.get(String.valueOf(item.Id));
                        priceListSettingsWp.roleName = item.Name;
                        if (!priceListSettingsWrapperList.contains(priceListSettingsWp)) {
                            priceListSettingsWrapperList.add(priceListSettingsWp);
                        }
                    }
                    if (!buMapping.isEmpty()) {
                        if (checkAccessibility(BusinessUnit__c.SObjectType, new List<String>{SObjectType.BusinessUnit__c.fields.Id.Name, SObjectType.BusinessUnit__c.fields.Name.Name})) {
                            for (BusinessUnit__c item : [SELECT Id, Name FROM BusinessUnit__c WHERE Id IN :buMapping.keySet()]) {
                                if (!buMapping.containsKey(item.Id)) continue;
                                buMapping.get(item.Id).buName = item.Name;
                            }
                        }
                    }
                }
            }
        }
        for (Integer index = priceListSettingsWrapperList.size(); index < 3; index++) {
            priceListSettingsWrapperList.add(new PriceListSettingWrapper());
        }
        this.tempBusinessType = negoSettings.sBusinessType != businessTypeNone ? negoSettings.sBusinessType : businessTypeNone;
        this.blankSelectOption = new SelectOption('', Label.LBL_None_Picklist_Value);
        this.gridSettingsLayoutsMap = new Map<String, List<SelectOption>>();
        String[] gridSettingsFields = new String[] {
          SObjectType.Grid_Settings__mdt.fields.DeveloperName.Name,
          SObjectType.Grid_Settings__mdt.fields.Label.Name
        };
        if (checkAccessibility(Grid_Settings__mdt.SObjectType, gridSettingsFields)) {
            for (Grid_Settings__mdt item : [SELECT DeveloperName, Label, Object_Name__c FROM Grid_Settings__mdt ORDER BY DeveloperName LIMIT 1000]) {
                if (!this.gridSettingsLayoutsMap.containsKey(item.Object_Name__c)) {
                    this.gridSettingsLayoutsMap.put(item.Object_Name__c, new List<SelectOption>{new SelectOption('', Label.LBL_None_Picklist_Value)});
                }
                this.gridSettingsLayoutsMap.get(item.Object_Name__c).add(new SelectOption(item.DeveloperName, item.Label));
            }
        }
        if(negoSettings.activateMaintenanceMode) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Maintenance_Mode_Active));
        }
    }
    /**
	 * @description get all available delimiter
	 * @return List<SelectOption> list of delimiters
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getDelimiters() {
        List<SelectOption> options = new List<SelectOption>();
        String[] separators = new String[]{',', ';', ':', '|'};
            for(String str : separators) {
                options.add(new SelectOption(str, str));
            }
        return options;
    }
    /**
	 * @description Get Business Types
	 * @return List<SelectOption> List of Business Types
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getBusinessTypes() {
        List<SelectOption> options = new List<SelectOption>() ;
        for (NegoptimSettings.BusinessType bType : NegoptimSettings.BusinessType.values()) {
            options.add(new SelectOption(bType.name(), bType.name()));
        }
        return options;
    }
    /**
	 * @description Get Reminder Level
	 * @return List<SelectOption> List of Reminder Level
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getReminderLevels() {
        List<SelectOption> options = new List<SelectOption>();
        String[] levels = new String[]{'0', '1', '2', '3'};
            for(String l : levels) {
                options.add(new SelectOption(l, l));
            }
        return options;
    }
    /**
	 * @description Get Bu Type
	 * @return List<SelectOption> List of Bu Type
	 ***************************************************************************************************************************************** */
    // TODO: create in NegoptimHelper
    public List<SelectOption> getBURecordTypes() {
        List<SelectOption> options = new List<SelectOption>();
        for(RecordType item : [SELECT DeveloperName, Name
                               FROM RecordType
                               WHERE SobjectType = :SObjectType.BusinessUnit__c.Name])
        {
            options.add(new SelectOption(item.DeveloperName, item.Name));
        }
        return options;
    }
    /**
	 * @description Get Contract RecordTypes
	 * @return List<SelectOption> List Contract RecordTypes
	 ***************************************************************************************************************************************** */
    // TODO: create in NegoptimHelper
    
    public List<SelectOption> contractRecordTypes {
        get {
                if (contractRecordTypes != null) return contractRecordTypes ;
                List<SelectOption> options = new List<SelectOption>();
                for(RecordType item : [SELECT DeveloperName, toLabel(Name)
                                        FROM RecordType
                                        WHERE SobjectType = :SObjectType.Contract__c.Name]) {
                    options.add(new SelectOption(item.DeveloperName, item.Name));
                }
                return options;
            }
    }

    /**
	 * @description Get Groups
	 * @return List<SelectOption> List of Groups
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getGroups() {
        List<SelectOption> groups = new List<SelectOption>();
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.Code__c.Name
        };
        if (checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            for(BusinessUnit__c item: [SELECT Id, Name, Code__c, RecordType.Name FROM BusinessUnit__c WHERE RecordType.DeveloperName =: 'Group' AND Code__c <> NULL]) {
                groups.add(new SelectOption(item.Code__c, item.Name));
            }
        }
        return groups;
    }
    /**
	 * @description Get group BU
	 * @return List<SelectOption> List of group BU
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getGroupsBU() {
        List<SelectOption> groups = new List<SelectOption>{new SelectOption('', '--Select--')};
        String[] orgaBUFields = new String[] {
            SObjectType.BusinessUnit__c.fields.Name.Name
        };
        if (checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)) {
            for(BusinessUnit__c item: [SELECT Id, Name FROM BusinessUnit__c
                                  WHERE RecordType.DeveloperName = 'Group'
                                  OR RecordType.DeveloperName = 'Country'])
            {
                groups.add(new SelectOption(item.Id, item.Name));
            }
        }
        return groups;
    }
  
    /**
	 * @description Get profiles
	 * @return List<SelectOption> List of profiles
	 ***************************************************************************************************************************************** */
    public List<SelectOption> getProfiles() {
        List<SelectOption> profiles = new List<SelectOption>();
        String[] profileFields = new String[] {
            SObjectType.Profile.fields.Name.Name
        };
        if (checkAccessibility(Profile.SObjectType, profileFields)) {
            for (Profile item: [SELECT Id, Name FROM Profile ORDER BY Name LIMIT 1000]) {
                profiles.add(new SelectOption(item.Id, item.Name));
            }
        }
        return profiles;
    }

    /**
     * @description get Product2 record types as picklist select options
    */
    public List<SelectOption> getProduct2RecordTypesSelectOptions() {
        List<SelectOption> options = new List<SelectOption>();
        Map<Id, String> recordTypeLabelsMap = NegoptimHelper.getObjectRecordTypeMapLabels(Product2.SObjectType);
        Map<Id, String> recordTypeDeveloperNameMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Product2.SObjectType);
        for (Id recordTypeId : recordTypeLabelsMap.keySet()) {
            if (recordTypeDeveloperNameMap.get(recordTypeId) != 'Secondary') {
                options.add(new SelectOption(recordTypeId, recordTypeLabelsMap.get(recordTypeId)));
            }
        }
        return options;
    }


    /**
     * @description get Invoice grouping options
    */
    public List<SelectOption> getSellinAggregateMode() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Aggregate on Product level', 'Aggregate on Product level'));
        options.add(new SelectOption('Respect same level', 'Respect same level'));
        options.add(new SelectOption('Both', 'Both'));
        return options;
    }


    /**
     * @description get Invoice grouping options
    */
    public List<SelectOption> getDiscountPercentScaleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('2', '2'));
        options.add(new SelectOption('3', '3'));
        return options;
    }

    /**
	 * @description Save Global setting in the cache and custom settings
	 ***************************************************************************************************************************************** */
	public PageReference save() {
        negoSettings.priceListInitDefaultBUMap.clear();
        for (PriceListSettingWrapper item : priceListSettingsWrapperList) {
            if (String.isNotBlank(item.buId) && String.isNotBlank(item.roleId)) {
                negoSettings.priceListInitDefaultBUMap.put(item.roleId, item.buId);
            }
        }
        negoSettings.sBusinessType = negoSettings.sBusinessType == this.businessTypeNone ? tempBusinessType : negoSettings.sBusinessType;
        negoSettings.selectedContractRTPostNegoNList = selectedRecordTypesPostNegoNOptions?.split(',');
        negoSettings.selectedContractRTPostNegoN1List = selectedRecordTypesPostNegoN1Options?.split(',');
        if(negoSettings.activateMaintenanceMode) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Maintenance_Mode_Active));
        }
        Set<String> errors = GlobalSettingsManager.saveGlobalSettings(negoSettings);
        if(errors.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } else {
            for(String err : errors) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, err));
            }
        }
        return null;
    }

    /**
     * @description search roles
    */
    public PageReference searchUserRole() {
        String query = 'SELECT Id, Name';
        query += ' FROM UserRole';
        query += ' WHERE PortalType = \'None\'';
        if (String.isNotEmpty(this.roleSearchTerm)) {
            query += ' AND Name LIKE \'%' + String.escapeSingleQuotes(this.roleSearchTerm) + '%\'';
        }
        query += ' ORDER BY Name';
        query += ' LIMIT 10';
        this.roleSelectList = new List<SelectOption>();
        if (checkAccessibility(UserRole.SObjectType, new List<String>{SObjectType.UserRole.fields.Id.Name, SObjectType.UserRole.fields.Name.Name, SObjectType.UserRole.fields.PortalType.Name})) {
            for (UserRole item : Database.query(query)) {
                this.roleSelectList.add(new SelectOption(item.Id, item.Name));
            }
        }
        return null;
    }
    /**
     * @description search BU
    */
    public PageReference searchBU() {
        String query = 'SELECT Id, Name';
        query += ' FROM BusinessUnit__c';
        query += ' WHERE Set_PriceList_Statement__c = TRUE';
        if (String.isNotEmpty(this.buSearchTerm)) {
            query += ' AND Name LIKE \'%' + String.escapeSingleQuotes(this.buSearchTerm) + '%\'';
        }
        query += ' ORDER BY Name';
        query += ' LIMIT 10';
        this.buSelectList = new List<SelectOption>();
        if (checkAccessibility(BusinessUnit__c.SObjectType, new List<String>{SObjectType.BusinessUnit__c.fields.Id.Name, SObjectType.BusinessUnit__c.fields.Name.Name})) {
            for (BusinessUnit__c item : Database.query(query)) {
                this.buSelectList.add(new SelectOption(item.Id, item.Name));
            }
        }
        return null;
    }
    public class PriceListSettingWrapper {
        public Id roleId {get; set;}
        public String roleName {get; set;}
        public Id buId {get; set;}
        public String buName {get; set;}
    }
}