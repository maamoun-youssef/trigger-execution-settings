/**
 * @author ULiT
 * @date JUN-4-2018
 * @group Negoptim Support
 * @description Use GlobalSettingsManager to load and save global settings. global settings are available in salesforce cache and custom settings section
 ********************************************************************************************************************************************* */

global with sharing class GlobalSettingsManager {

    /**
     * @description Used to load global settings, first, try to load global settings from custom setting, if it's not available try to load data from salesforce cache (document)
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    public static NegoptimSettings loadGlobalSettings() {
        NegoptimSettings settings = loadFromCustomSettings();
        if(settings == null) settings = loadFromCache();
        if(settings == null) settings = new NegoptimSettings();
        return settings;
    }
    // load global settings serialized
    global static String loadGlobalSettingsSerialized() {
        NegoptimSettings settings = loadFromCustomSettings();
        if(settings == null) settings = loadFromCache();
        if(settings == null) settings = new NegoptimSettings();
        return JSON.serialize(settings);
    }
    // load global settings deserialized
    public static NegoptimSettings loadGlobalSettingsManagerDeserialized(String globalSettingsManagerSerialized) {
        NegoptimSettings settings = (NegoptimSettings) JSON.deserialize(globalSettingsManagerSerialized, NegoptimSettings.class);
        return settings;
    }
    /**
     * @description load Global Settings from salesforce custom settings section
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    private static NegoptimSettings loadFromCustomSettings() {

        Map<String, NegoptimCustomSettings__c> negoptimSettingsMap = NegoptimCustomSettings__c.getAll();
        if(negoptimSettingsMap == null || negoptimSettingsMap.get('NegoptimSettings') == null){
            return null;
        }

        NegoptimCustomSettings__c negoptimCustomSettings = negoptimSettingsMap.get('NegoptimSettings');
        NegoptimSettings negoSettings = new NegoptimSettings();

        // General Settings
        negoSettings.sBusinessType = negoptimCustomSettings.Business_Type__c;
        negoSettings.activateMaintenanceMode = negoptimCustomSettings.Activate_Maintenance_Mode__c;
        negoSettings.runSellinReparentingForBusinessUnit = negoptimCustomSettings.run_Sellin_Reparenting_For_Business_Unit__c;
        negoSettings.AllowCopyProducttoPGFromSellin = negoptimCustomSettings.Allow_Copy_Product_to_PG_From_Sellin__c;
        negoSettings.contractNumberUnicity = negoptimCustomSettings.Contract_Number_Unicity__c;
        negoSettings.allowContractNameNumberGeneration = negoptimCustomSettings.Allow_Contract_Name_Number_Generation__c;
        if(negoptimCustomSettings.Contract_Record_Types_Post_Nego_N__c != null) {
            negoSettings.selectedContractRTPostNegoNList = negoptimCustomSettings.Contract_Record_Types_Post_Nego_N__c.split(',');
        }
        if(negoptimCustomSettings.Contract_Record_Types_Post_Nego_N1__c != null) {
            negoSettings.selectedContractRTPostNegoN1List = negoptimCustomSettings.Contract_Record_Types_Post_Nego_N1__c.split(',');
        }
        negoSettings.defaultConditionCode = negoptimCustomSettings.default_Condition_Code__c;
        negoSettings.delimiter = negoptimCustomSettings.CSV_Delimiter__c;
        negoSettings.csvDateFormat = negoptimCustomSettings.csv_Date_Format__c;
        negoSettings.groupBU = negoptimCustomSettings.Group_Code_BU_for_Integration__c;
        negoSettings.tOGapTolerenceNegative = negoptimCustomSettings.TO_gap_Tolerence_neg__c;
        negoSettings.tOGapTolerencePositive = negoptimCustomSettings.TO_gap_Tolerence_Pos__c;
        negoSettings.coopGapTolerenceNegative = negoptimCustomSettings.Coop_gap_Tolerence_neg__c;
        negoSettings.coopGapTolerencePositive = negoptimCustomSettings.Coop_gap_Tolerence_pos__c;
        negoSettings.reminderLevel = negoptimCustomSettings.Level_of_reminder_managed__c != null ? negoptimCustomSettings.Level_of_reminder_managed__c.intValue() : 0;
        negoSettings.reminderValue1 = negoptimCustomSettings.Reminder1__c != null ? negoptimCustomSettings.Reminder1__c.intValue() : 0;
        negoSettings.reminderValue2 = negoptimCustomSettings.Reminder2__c != null ? negoptimCustomSettings.Reminder2__c.intValue() : 0;
        negoSettings.reminderValue3 = negoptimCustomSettings.Reminder3__c != null ? negoptimCustomSettings.Reminder3__c.intValue() : 0;
        negoSettings.reminderDescription1 = negoptimCustomSettings.Reminder_Description1__c;
        negoSettings.reminderDescription2 = negoptimCustomSettings.Reminder_Description2__c;
        negoSettings.reminderDescription3 = negoptimCustomSettings.Reminder_Description3__c;
        if(negoptimCustomSettings.Reminder_BU_Managed__c != null) {
            negoSettings.reminderBUManagedList = negoptimCustomSettings.Reminder_BU_Managed__c.split(',');
        }
        negoSettings.profile = negoptimCustomSettings.Profile__c;
        negoSettings.datesOverlapControlBU = negoptimCustomSettings.Allow_contract_overlap_dates__c;
        if(negoptimCustomSettings.BU_Record_types__c != null) {
            negoSettings.selectedBURTList = negoptimCustomSettings.BU_Record_types__c.split(',');
        }
        negoSettings.allowUpdatingInvoiceDateOnPrint = negoptimCustomSettings.Allow_Updating_Invoice_Date_On_Print__c;
        if (negoptimCustomSettings.Sellin_Aggregate_Mode__c != null) {
            negoSettings.sellinAggregateMode = negoptimCustomSettings.Sellin_Aggregate_Mode__c;
        }
        negoSettings.prioritizeSortBDateNegotiate = negoptimCustomSettings.Prioritize_Sort_BDate_Negotiate__c;
        negoSettings.prioritizeSortBDateNegotiateFollowup = negoptimCustomSettings.Prioritize_Sort_BDate_Negotiate_Followup__c;
        negoSettings.allowUpdatingPrintDateOnPrint = negoptimCustomSettings.Allow_Updating_Print_Date_On_Print__c;
        negoSettings.dispatchMaxClosingDay = Integer.valueOf(negoptimCustomSettings.Dispatch_Max_Closing_Day__c);
        negoSettings.invoiceMaxClosingDay = Integer.valueOf(negoptimCustomSettings.Invoice_Max_Closing_Day__c);
        negoSettings.dispatchAggregateMode = negoptimCustomSettings.Dispatch_Aggregate_Mode__c;
        negoSettings.dispatchOnHLP = negoptimCustomSettings.Dispatch_On_Higher_Level_Packaging__c;
        negoSettings.dispatchHeadOnConditionLevel = negoptimCustomSettings.Dispatch_Head_On_Condition_Level__c;
        // Price list user role settings
        if (String.isNotBlank(negoptimCustomSettings.price_List_Init_Default_BU__c)) {
            negoSettings.priceListInitDefaultBUMap = (Map<Id, Id>)JSON.deserialize(negoptimCustomSettings.price_List_Init_Default_BU__c, Map<Id, Id>.class);
        } else {
            negoSettings.priceListInitDefaultBUMap = new Map<Id, Id>();
        }
        // Grid Layout Settings
        negoSettings.assortmentMatrixGridLayout = negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c;
        negoSettings.assortmentMatrixTargetGridLayout = negoptimCustomSettings.Assortment_Matrix_Target_Grid_Layout__c;
        negoSettings.productSwitchGridLayout = negoptimCustomSettings.Product_Switch_Grid_Layout__c;
        negoSettings.productInnoGridLayout = negoptimCustomSettings.Product_Inno_Grid_Layout__c;
        negoSettings.productStopGridLayout = negoptimCustomSettings.Product_Stop_Grid_Layout__c;
        negoSettings.assortmentBudgetSimulatorGridLayout = negoptimCustomSettings.Assortment_Budget_Simulator_Grid_Layout__c;
        negoSettings.assortmentMatrixComparatorGridLayout = negoptimCustomSettings.Assortment_Matrix_Comparator_Grid_Layout__c;
        negoSettings.counterpartyFollowupGridLayout = negoptimCustomSettings.Counterparty_Followup_Grid_Layout__c;
        negoSettings.netPriceStatementMatrixGridLayout = negoptimCustomSettings.NetPrice_Statement_Grid_Layout__c;
        negoSettings.priceListStatementMatrixGridLayout = negoptimCustomSettings.Price_List_Statement_Grid_Layout__c;
        negoSettings.commercialPlanGridLayout = String.isNotBlank(negoptimCustomSettings.Commercial_Plan_Grid_Layout__c) ? negoptimCustomSettings.Commercial_Plan_Grid_Layout__c : negoSettings.commercialPlanGridLayout;
        negoSettings.commercialPlanContractGridLayout = negoptimCustomSettings.Commercial_Plan_Contract_Grid_Layout__c;
        negoSettings.ProductSelectionPGGridLayout = negoptimCustomSettings.Product_Selection_PG_Grid_Layout__c;
        negoSettings.PromoCalendarGridLayout = String.isNotBlank(negoptimCustomSettings.Promo_Calendar_Grid_Layout__c) ? negoptimCustomSettings.Promo_Calendar_Grid_Layout__c : negoSettings.PromoCalendarGridLayout;
        // Grid Settings Profiles
        if(negoptimCustomSettings.Assortment_Matrix_Profile__c != null) {
            negoSettings.assortmentMatrixProfile = negoptimCustomSettings.Assortment_Matrix_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Assortment_Matrix_Target_Profile__c != null) {
            negoSettings.assortmentMatrixTargetProfile = negoptimCustomSettings.Assortment_Matrix_Target_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Switch_Profile__c != null) {
            negoSettings.productSwitchProfile = negoptimCustomSettings.Product_Switch_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Inno_Profile__c != null) {
            negoSettings.productInnoProfile = negoptimCustomSettings.Product_Inno_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Product_Stop_Profile__c != null) {
            negoSettings.productStopProfile = negoptimCustomSettings.Product_Stop_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c != null) {
            negoSettings.assortmentBudgetSimulatorProfile = negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c.split(';');
        }
        if(negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c != null) {
            negoSettings.assortmentMatrixComparatorProfile = negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c.split(';');
        }
        // Products Profile Management
        if(negoptimCustomSettings.Allowed_profiles_to_manage_Products__c != null) {
            negoSettings.allowedProfilesToManageProducts = negoptimCustomSettings.Allowed_profiles_to_manage_Products__c.split(';');
        }
        // Mass Batch Form Settings
        negoSettings.MBF_Section_ContractTOProcedures = negoptimCustomSettings.MBF_Section_ContractTOProcedures__c;
        negoSettings.MBF_Section_ContractDuplication = negoptimCustomSettings.MBF_Section_ContractDuplication__c;
        negoSettings.MBF_Section_LastActiveContractProcedure = negoptimCustomSettings.MBF_Section_LastActiveContractProcedure__c;
        negoSettings.MBF_Section_ContractRates = negoptimCustomSettings.MBF_Section_ContractRates__c;
        negoSettings.MBF_Section_GroupScanAndSynchro = negoptimCustomSettings.MBF_Section_GroupScanAndSynchro__c;
        negoSettings.MBF_Section_PromoDetailProcedure = negoptimCustomSettings.MBF_Section_PromoDetailProcedure__c;
        negoSettings.MBF_Section_MarketDataCollection = negoptimCustomSettings.MBF_Section_MarketDataCollection__c;
        negoSettings.MBF_Section_AssortmentSFPlanning = negoptimCustomSettings.MBF_Section_AssortmentSFPlanning__c;
        negoSettings.MBF_Section_SellInProcedure = negoptimCustomSettings.MBF_Section_SellInProcedure__c;
        negoSettings.MBF_Section_Batches = negoptimCustomSettings.MBF_Section_Batches__c;
        negoSettings.MBF_Section_InvoiceReminder = negoptimCustomSettings.MBF_Section_InvoiceReminder__c;
        negoSettings.MBF_Section_MassDistribution = negoptimCustomSettings.MBF_Section_MassDistribution__c;
        negoSettings.MBF_Section_CallingWebServices = negoptimCustomSettings.MBF_Section_CallingWebServices__c;
        negoSettings.MBF_Section_PenaltiesProcedure = negoptimCustomSettings.MBF_Section_PenaltiesProcedure__c;
        negoSettings.MBF_Section_ContractCounterpartyDetail = negoptimCustomSettings.MBF_Section_ContractCounterpartyDetail__c;
        negoSettings.MBF_Section_RecalculateAssortmentDetail = negoptimCustomSettings.MBF_Section_RecalculateAssortmentDetail__c;
        negoSettings.AllowUpdateP2Clustering = negoptimCustomSettings.Allow_Update_P2_Clustering__c;
        negoSettings.AllowUpdateP1Clustering = negoptimCustomSettings.Allow_Update_P1_Clustering__c;
        negoSettings.marketDataColletionSource = negoptimCustomSettings.Market_Data_Colletion_Source__c;
        negoSettings.openPagesFilterSectionByDefault = negoptimCustomSettings.Open_Pages_Filter_Section_by_Default__c;
        negoSettings.manageAssortByPersonalizedCategory = negoptimCustomSettings.Manage_Assort_By_Personalized_Category__c;
        negoSettings.Allow_Insert_Account_On_Insert_Supplier = negoptimCustomSettings.Allow_Insert_Account_On_Insert_Supplier__c;
        negoSettings.Allow_Dispatching_in_Condition_List = negoptimCustomSettings.Allow_Dispatching_in_Condition_List__c;
        // SF Planning Configuration
        negoSettings.SFPlanningConfiguration = negoptimCustomSettings.SF_Planning_Configuration__c;
        negoSettings.higherLevelPackagingRecordTypeId = negoptimCustomSettings.Higher_Level_Packaging_Record_Type_Id__c;
        negoSettings.assortmentSynchroMode = negoptimCustomSettings.Assortment_Synchro_Mode__c;
        // settings related to overriding Product Name with autonum
        //negoSettings.overrideProductNameWithAutoNum = negoptimCustomSettings.Override_Product_Name_with_AutoNum__c;
        //negoSettings.productAutoNumber = Integer.valueOf(negoptimCustomSettings.Product_Auto_Number__c);
        //negoSettings.productNamePrefix = negoptimCustomSettings.Product_Name_Prefix__c;
        // product Record Types for NS PG Management
        /*if(negoptimCustomSettings.Product_Record_Types_for_NS_PG__c != null) {
            negoSettings.productRecordTypesforNSPG = negoptimCustomSettings.Product_Record_Types_for_NS_PG__c.split(';');
        }*/
        negoSettings.grcContractDataSource = negoptimCustomSettings.GRC_Contract_Data_Source__c;
        // invoice settings
        negoSettings.invoiceBaseGeneration = negoptimCustomSettings.Invoice_Base_Generation__c;
        negoSettings.groupBU1 = negoptimCustomSettings.Group_BU_1__c;
        negoSettings.groupBU2 = negoptimCustomSettings.Group_BU_2__c;
        negoSettings.recordTypeForBU1 = negoptimCustomSettings.RT_for_BU_1__c;
        negoSettings.recordTypeForBU2 = negoptimCustomSettings.RT_for_BU_2__c;
        negoSettings.isInvoiceAmountDistributed = negoptimCustomSettings.Is_Invoice_Amount_Distributed__c;
        negoSettings.startingDayToCreateLandingOnConsoDate = negoptimCustomSettings?.Starting_Day_to_create_Landing_on_conso__c?.date();
        if(negoSettings.startingDayToCreateLandingOnConsoDate == null) {
            negoSettings.startingDayToCreateLandingOnConsoDate = Date.newInstance(Date.today().year(), 9, 1);
        }
        negoSettings.startingDayToCreateNegoBaseOnConsoDate = negoptimCustomSettings?.Starting_Day_to_create_NegoBase_on_conso__c?.date();
        if(negoSettings.startingDayToCreateNegoBaseOnConsoDate == null) {
            negoSettings.startingDayToCreateNegoBaseOnConsoDate = Date.newInstance(Date.today().year(), 9, 1);
        }
        negoSettings.discountPercentScale = negoptimCustomSettings.DiscountPercentScale__c != null ? negoptimCustomSettings.DiscountPercentScale__c.intValue() : negoSettings.discountPercentScale;
        return negoSettings;
    }
    /**
     * @description load Global Settings from Cache (the cache get the settings from document)
     * @return NegoptimSettings
     ***************************************************************************************************************************************** */
    private static NegoptimSettings loadFromCache() {
        try {
            return (NegoptimSettings) Cache.Org.get(GlobalSettingCache.class, NegoptimHelper.DOCUMENT_SETTINGS_NAME);
        } catch(Exception ex){
            return null;
        }
    }
    /**
     * @description save Global Settings in cache and custom settings
     * @param NegoptimSettings settings to be saved
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    public static Set<String> saveGlobalSettings(NegoptimSettings negoSettings) {
        Set<String> errors = new Set<String>();
        errors.addAll(saveCustomSettings(negoSettings));
        errors.addAll(saveGlobalSettingDocument(negoSettings));
        return errors;
    }
    /**
     * @description save Global Settings in custom settings
     * @param NegoptimSettings settings to be saved in custom settings
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    private static Set<String> saveCustomSettings(NegoptimSettings negoSettings){
        Set<String> errors = new Set<String>();

        final String settingsKey = 'NegoptimSettings';

        Map<String, NegoptimCustomSettings__c> negoptimSettingMap = NegoptimCustomSettings__c.getAll();
        NegoptimCustomSettings__c negoptimCustomSettings;
        if(negoptimSettingMap == null || negoptimSettingMap.get(settingsKey) == null){
            negoptimCustomSettings = new NegoptimCustomSettings__c(name = settingsKey);
        } else {
            negoptimCustomSettings = negoptimSettingMap.get(settingsKey);
        }
        negoptimCustomSettings.Business_Type__c = negoSettings.sBusinessType;
        negoptimCustomSettings.Activate_Maintenance_Mode__c = negoSettings.activateMaintenanceMode;
        negoptimCustomSettings.CSV_Delimiter__c = negoSettings.delimiter;
        negoptimCustomSettings.csv_Date_Format__c = negoSettings.csvDateFormat;
        negoptimCustomSettings.Group_Code_BU_for_Integration__c = negoSettings.groupBU;
        negoptimCustomSettings.TO_gap_Tolerence_neg__c = negoSettings.tOGapTolerenceNegative;
        negoptimCustomSettings.TO_gap_Tolerence_Pos__c = negoSettings.tOGapTolerencePositive;
        negoptimCustomSettings.Coop_gap_Tolerence_neg__c = negoSettings.coopGapTolerenceNegative;
        negoptimCustomSettings.Coop_gap_Tolerence_pos__c = negoSettings.coopGapTolerencePositive;
        negoptimCustomSettings.Level_of_reminder_managed__c = negoSettings.reminderLevel;
        negoptimCustomSettings.Reminder1__c = negoSettings.reminderValue1;
        negoptimCustomSettings.Reminder2__c = negoSettings.reminderValue2;
        negoptimCustomSettings.Reminder3__c = negoSettings.reminderValue3;
        negoptimCustomSettings.Reminder_Description1__c = negoSettings.reminderDescription1;
        negoptimCustomSettings.Reminder_Description2__c = negoSettings.reminderDescription2;
        negoptimCustomSettings.Reminder_Description3__c = negoSettings.reminderDescription3;
        if(!negoSettings.reminderBUManagedList.isEmpty()) {
            negoptimCustomSettings.Reminder_BU_Managed__c = String.join(negoSettings.reminderBUManagedList, ',');
        }
        negoptimCustomSettings.Profile__c = negoSettings.profile;
        negoptimCustomSettings.Allow_contract_overlap_dates__c = negoSettings.datesOverlapControlBU;
        String buRecType = '';
        if(negoSettings.selectedBURTList != null){
            for (String selected : negoSettings.selectedBURTList){
                buRecType +=selected+',';
            }
        }
        negoptimCustomSettings.BU_Record_types__c = buRecType.removeEnd(',');
        negoptimCustomSettings.Allow_Updating_Invoice_Date_On_Print__c = negoSettings.allowUpdatingInvoiceDateOnPrint;
        negoptimCustomSettings.Sellin_Aggregate_Mode__c = negoSettings.sellinAggregateMode;
        negoptimCustomSettings.Prioritize_Sort_BDate_Negotiate__c = negoSettings.prioritizeSortBDateNegotiate;
        negoptimCustomSettings.Prioritize_Sort_BDate_Negotiate_Followup__c = negoSettings.prioritizeSortBDateNegotiateFollowup;
        negoptimCustomSettings.Allow_Updating_Print_Date_On_Print__c = negoSettings.allowUpdatingPrintDateOnPrint;
        negoptimCustomSettings.Dispatch_Max_Closing_Day__c = negoSettings.dispatchMaxClosingDay;
        negoptimCustomSettings.Invoice_Max_Closing_Day__c = negoSettings.invoiceMaxClosingDay == 0 ? null : negoSettings.invoiceMaxClosingDay;
        negoptimCustomSettings.Dispatch_Aggregate_Mode__c = negoSettings.dispatchAggregateMode;
        negoptimCustomSettings.Dispatch_On_Higher_Level_Packaging__c = negoSettings.dispatchOnHLP;
        negoptimCustomSettings.Dispatch_Head_On_Condition_Level__c = negoSettings.dispatchHeadOnConditionLevel;
        // Price list user role settings
        if (negoSettings.priceListInitDefaultBUMap != null) {
            negoptimCustomSettings.price_List_Init_Default_BU__c = JSON.serialize(negoSettings.priceListInitDefaultBUMap);
        } else {
            negoptimCustomSettings.price_List_Init_Default_BU__c = '{}';
        }
        //Grid Layout settings
        negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = negoSettings.assortmentMatrixGridLayout;
        negoptimCustomSettings.Assortment_Matrix_Target_Grid_Layout__c = negoSettings.assortmentMatrixTargetGridLayout;
        negoptimCustomSettings.Product_Switch_Grid_Layout__c = negoSettings.productSwitchGridLayout;
        negoptimCustomSettings.Product_Inno_Grid_Layout__c = negoSettings.productInnoGridLayout;
        negoptimCustomSettings.Product_Stop_Grid_Layout__c = negoSettings.productStopGridLayout;
        negoptimCustomSettings.Assortment_Budget_Simulator_Grid_Layout__c = negoSettings.assortmentBudgetSimulatorGridLayout;
        negoptimCustomSettings.Assortment_Matrix_Comparator_Grid_Layout__c = negoSettings.assortmentMatrixComparatorGridLayout;
        negoptimCustomSettings.Counterparty_Followup_Grid_Layout__c = negoSettings.counterpartyFollowupGridLayout;
        negoptimCustomSettings.NetPrice_Statement_Grid_Layout__c = negoSettings.netPriceStatementMatrixGridLayout;
        negoptimCustomSettings.Price_List_Statement_Grid_Layout__c = negoSettings.priceListStatementMatrixGridLayout;
        negoptimCustomSettings.Commercial_Plan_Grid_Layout__c = negoSettings.commercialPlanGridLayout;
        negoptimCustomSettings.Commercial_Plan_Contract_Grid_Layout__c = negoSettings.commercialPlanContractGridLayout;
        negoptimCustomSettings.Product_Selection_PG_Grid_Layout__c = negoSettings.ProductSelectionPGGridLayout;
        negoptimCustomSettings.Promo_Calendar_Grid_Layout__c = negoSettings.PromoCalendarGridLayout;
        // Grid Settings Profiles
        negoptimCustomSettings.Assortment_Matrix_Profile__c = negoSettings.assortmentMatrixProfile != null ? String.join(negoSettings.assortmentMatrixProfile, ';') : '';
        negoptimCustomSettings.Assortment_Matrix_Target_Profile__c = negoSettings.assortmentMatrixTargetProfile != null ? String.join(negoSettings.assortmentMatrixTargetProfile, ';') : '';
        negoptimCustomSettings.Product_Switch_Profile__c = negoSettings.productSwitchProfile != null ? String.join(negoSettings.productSwitchProfile, ';') : '';
        negoptimCustomSettings.Product_Inno_Profile__c = negoSettings.productInnoProfile != null ? String.join(negoSettings.productInnoProfile, ';') : '';
        negoptimCustomSettings.Product_Stop_Profile__c = negoSettings.productStopProfile != null ? String.join(negoSettings.productStopProfile, ';') : '';
        negoptimCustomSettings.Assortment_Budget_Simulator_Profile__c = negoSettings.assortmentBudgetSimulatorProfile != null ? String.join(negoSettings.assortmentBudgetSimulatorProfile, ';') : '';
        negoptimCustomSettings.Assortment_Matrix_Comparator_Profile__c = negoSettings.assortmentMatrixComparatorProfile != null ? String.join(negoSettings.assortmentMatrixComparatorProfile, ';') : '';
        // Products Management
        negoptimCustomSettings.Allowed_profiles_to_manage_Products__c = negoSettings.allowedProfilesToManageProducts != null ? String.join(negoSettings.allowedProfilesToManageProducts, ';') : '';
        // General Settings
        negoptimCustomSettings.Run_Sellin_Reparenting_For_Business_Unit__c = negoSettings.runSellinReparentingForBusinessUnit;
        negoptimCustomSettings.Allow_Copy_Product_to_PG_From_Sellin__c = negoSettings.AllowCopyProducttoPGFromSellin;
        negoptimCustomSettings.Contract_Number_Unicity__c = negoSettings.contractNumberUnicity;
        negoptimCustomSettings.Allow_Contract_Name_Number_Generation__c = negoSettings.allowContractNameNumberGeneration;
        negoptimCustomSettings.Default_Condition_Code__c = negoSettings.defaultConditionCode;
        String contractPostNegoNRT = '', contractPostNegoN1RT = '';
        if(negoSettings.selectedContractRTPostNegoNList != null) {
            contractPostNegoNRT = String.join(negoSettings.selectedContractRTPostNegoNList, ',');
        }
        if(negoSettings.selectedContractRTPostNegoN1List != null) {
            contractPostNegoN1RT = String.join(negoSettings.selectedContractRTPostNegoN1List, ',');
        }
        negoptimCustomSettings.Contract_Record_Types_Post_Nego_N__c = contractPostNegoNRT;
        negoptimCustomSettings.Contract_Record_Types_Post_Nego_N1__c = contractPostNegoN1RT;
        // Mass Batch Form Settings
        negoptimCustomSettings.MBF_Section_ContractTOProcedures__c = negoSettings.MBF_Section_ContractTOProcedures;
        negoptimCustomSettings.MBF_Section_ContractDuplication__c = negoSettings.MBF_Section_ContractDuplication;
        negoptimCustomSettings.MBF_Section_LastActiveContractProcedure__c = negoSettings.MBF_Section_LastActiveContractProcedure;
        negoptimCustomSettings.MBF_Section_ContractRates__c = negoSettings.MBF_Section_ContractRates;
        negoptimCustomSettings.MBF_Section_GroupScanAndSynchro__c = negoSettings.MBF_Section_GroupScanAndSynchro;
        negoptimCustomSettings.MBF_Section_PromoDetailProcedure__c = negoSettings.MBF_Section_PromoDetailProcedure;
        negoptimCustomSettings.MBF_Section_MarketDataCollection__c = negoSettings.MBF_Section_MarketDataCollection;
        negoptimCustomSettings.MBF_Section_AssortmentSFPlanning__c = negoSettings.MBF_Section_AssortmentSFPlanning;
        negoptimCustomSettings.MBF_Section_SellInProcedure__c = negoSettings.MBF_Section_SellInProcedure;
        negoptimCustomSettings.MBF_Section_Batches__c = negoSettings.MBF_Section_Batches;
        negoptimCustomSettings.MBF_Section_InvoiceReminder__c = negoSettings.MBF_Section_InvoiceReminder;
        negoptimCustomSettings.MBF_Section_MassDistribution__c = negoSettings.MBF_Section_MassDistribution;
        negoptimCustomSettings.MBF_Section_CallingWebServices__c = negoSettings.MBF_Section_CallingWebServices;
        negoptimCustomSettings.MBF_Section_PenaltiesProcedure__c = negoSettings.MBF_Section_PenaltiesProcedure;
        negoptimCustomSettings.MBF_Section_ContractCounterpartyDetail__c = negoSettings.MBF_Section_ContractCounterpartyDetail;
        negoptimCustomSettings.MBF_Section_RecalculateAssortmentDetail__c = negoSettings.MBF_Section_RecalculateAssortmentDetail;
        negoptimCustomSettings.Market_Data_Colletion_Source__c = negoSettings.marketDataColletionSource;
        negoptimCustomSettings.Allow_Update_P2_Clustering__c = negoSettings.allowUpdateP2Clustering;
        negoptimCustomSettings.Allow_Update_P1_Clustering__c = negoSettings.AllowUpdateP1Clustering;
        negoptimCustomSettings.Open_Pages_Filter_Section_by_Default__c = negoSettings.openPagesFilterSectionByDefault;
        negoptimCustomSettings.Manage_Assort_By_Personalized_Category__c = negoSettings.manageAssortByPersonalizedCategory;
        negoptimCustomSettings.Allow_Insert_Account_On_Insert_Supplier__c = negoSettings.Allow_Insert_Account_On_Insert_Supplier;
        negoptimCustomSettings.Allow_Dispatching_in_Condition_List__c = negoSettings.Allow_Dispatching_in_Condition_List;
        negoptimCustomSettings.SF_Planning_Configuration__c = negoSettings.SFPlanningConfiguration;
        negoptimCustomSettings.Higher_Level_Packaging_Record_Type_Id__c = negoSettings.higherLevelPackagingRecordTypeId;
        negoptimCustomSettings.Assortment_Synchro_Mode__c = negoSettings.assortmentSynchroMode;
        //negoptimCustomSettings.Override_Product_Name_with_AutoNum__c = negoSettings.overrideProductNameWithAutoNum;
        //negoptimCustomSettings.Product_Auto_Number__c = negoSettings.productAutoNumber;
        //negoptimCustomSettings.Product_Name_Prefix__c = negoSettings.productNamePrefix;
        //negoptimCustomSettings.Product_Record_Types_for_NS_PG__c = negoSettings.productRecordTypesforNSPG != null ? String.join(negoSettings.productRecordTypesforNSPG, ';') : '';
        negoptimCustomSettings.GRC_Contract_Data_Source__c = negoSettings.grcContractDataSource;
        // invoice settings
        negoptimCustomSettings.Invoice_Base_Generation__c = negoSettings.invoiceBaseGeneration;
        negoptimCustomSettings.Group_BU_1__c = negoSettings.groupBU1;
        negoptimCustomSettings.Group_BU_2__c = negoSettings.groupBU2;
        negoptimCustomSettings.RT_for_BU_1__c = negoSettings.recordTypeForBU1;
        negoptimCustomSettings.RT_for_BU_2__c = negoSettings.recordTypeForBU2;
        negoptimCustomSettings.Is_Invoice_Amount_Distributed__c = negoSettings.isInvoiceAmountDistributed;
        // BU Depth

        negoptimCustomSettings.BU_Navigation_Depth__c = negoSettings.buNavigationDepth;
        negoptimCustomSettings.Starting_Day_to_create_Landing_on_conso__c = negoSettings.startingDayToCreateLandingOnConso;
        negoptimCustomSettings.Starting_Day_to_create_NegoBase_on_conso__c = negoSettings.startingDayToCreateNegoBaseOnConso;
        negoptimCustomSettings.DiscountPercentScale__c = negoSettings.discountPercentScale;
        try {
            // check security on create or update negoptimCustomSettings fields
            String [] negoptimCustomSettingsFields = new String [] {
                SObjectType.NegoptimCustomSettings__c.fields.Activate_Maintenance_Mode__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Invoice_Base_Generation__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Group_BU_1__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Group_BU_2__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.RT_for_BU_1__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.RT_for_BU_2__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.CSV_Delimiter__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.csv_Date_Format__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Group_Code_BU_for_Integration__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Business_Type__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.TO_gap_Tolerence_neg__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.TO_gap_Tolerence_Pos__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Coop_gap_Tolerence_neg__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Coop_gap_Tolerence_pos__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Level_of_reminder_managed__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder1__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder2__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder3__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder_Description1__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder_Description2__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder_Description3__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Reminder_BU_Managed__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_contract_overlap_dates__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.BU_Record_types__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Updating_Invoice_Date_On_Print__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Sellin_Aggregate_Mode__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Prioritize_Sort_BDate_Negotiate__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Prioritize_Sort_BDate_Negotiate_Followup__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Updating_Print_Date_On_Print__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Dispatch_Max_Closing_Day__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Invoice_Max_Closing_Day__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Dispatch_Aggregate_Mode__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Target_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Switch_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Inno_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Stop_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Budget_Simulator_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Comparator_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Landing__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Nego_Base__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Nego_Base_Init__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_PE__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Proposal__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_SB__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Signed__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Simulation__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_Target__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Condition_Grid_Layout_For_To_Be_Signed__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Counterparty_Followup_Grid_Layout__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Target_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Switch_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Inno_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Product_Stop_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Budget_Simulator_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Matrix_Comparator_Profile__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allowed_profiles_to_manage_Products__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Run_Sellin_Reparenting_For_Business_Unit__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Copy_Product_to_PG_From_Sellin__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Contract_Number_Unicity__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Default_Condition_Code__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_ContractTOProcedures__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_ContractDuplication__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_LastActiveContractProcedure__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_ContractRates__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_GroupScanAndSynchro__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_PromoDetailProcedure__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_MarketDataCollection__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_AssortmentSFPlanning__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_SellInProcedure__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_Batches__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_InvoiceReminder__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_MassDistribution__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_CallingWebServices__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_PenaltiesProcedure__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_ContractCounterpartyDetail__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.MBF_Section_RecalculateAssortmentDetail__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Market_Data_Colletion_Source__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Update_P2_Clustering__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Update_P1_Clustering__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Open_Pages_Filter_Section_by_Default__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Insert_Account_On_Insert_Supplier__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Allow_Dispatching_in_Condition_List__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.SF_Planning_Configuration__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Higher_Level_Packaging_Record_Type_Id__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Assortment_Synchro_Mode__c.Name,
                //SObjectType.NegoptimCustomSettings__c.fields.Override_Product_Name_with_AutoNum__c.Name,
                //SObjectType.NegoptimCustomSettings__c.fields.Product_Auto_Number__c.Name,
                //SObjectType.NegoptimCustomSettings__c.fields.Product_Name_Prefix__c.Name,
                //SObjectType.NegoptimCustomSettings__c.fields.Product_Record_Types_for_NS_PG__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.GRC_Contract_Data_Source__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Starting_Day_to_create_Landing_on_conso__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.Starting_Day_to_create_NegoBase_on_conso__c.Name,
                SObjectType.NegoptimCustomSettings__c.fields.DiscountPercentScale__c.Name
            };

            if(true || (NegoptimHelper.checkCreatibility(NegoptimCustomSettings__c.SObjectType, negoptimCustomSettingsFields)
                        && NegoptimHelper.checkUpdatibility(NegoptimCustomSettings__c.SObjectType, negoptimCustomSettingsFields)))
            {
                upsert negoptimCustomSettings;
            }
        } catch(DmlException ex){
            errors.add(Label.MSG_Error_Occurred + ' : ' + ex.getDmlMessage(0));
        }
        return errors;
    }
    /**
     * @description save Global Settings in custom settings
     * @param NegoptimSettings settings to be saved in the document
     * @return Set<String> list of errors, if no errors return an empty list
     ***************************************************************************************************************************************** */
    private static Set<String> saveGlobalSettingDocument(NegoptimSettings negoSettings){
        // check security on create or update document fields
        String [] documentFields = new String [] {
            SObjectType.Document.fields.Name.Name,
            SObjectType.Document.fields.AuthorId.Name,
            SObjectType.Document.fields.Body.Name,
            SObjectType.Document.fields.ContentType.Name,
            SObjectType.Document.fields.Type.Name,
            SObjectType.Document.fields.FolderId.Name
        };
        if(!NegoptimHelper.checkCreatibility(Document.SObjectType, documentFields) || !NegoptimHelper.checkUpdatibility(Document.SObjectType, documentFields)) {
            return new Set<String>();
        }
        Document settingsFile;
        Folder folderSetting;
        Set<String> errors = new Set<String>();
        // check security on access Folder fields
        String [] folderFields = new String [] {
            SObjectType.Folder.fields.Id.Name,
            SObjectType.Folder.fields.Name.Name
        };
        if(NegoptimHelper.checkAccessibility(Folder.SObjectType, folderFields) && NegoptimHelper.checkAccessibility(Document.SObjectType, documentFields)) {
            // Get folder settings.
            List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = :NegoptimHelper.FOLDER_SETTINGS_NAME LIMIT 1];
            if(folders != null && folders.size() > 0)
                folderSetting = folders.get(0);
            if(folderSetting == null) {
                errors.add(string.format(Label.MSG_FolderSettingsNotExist, new String[]{ NegoptimHelper.FOLDER_SETTINGS_NAME }));
            }
            // Get document settings.
            List<Document> documents = [SELECT Id, FolderId, Folder.Name, Body, AuthorId FROM Document
                                        WHERE Folder.Name = :NegoptimHelper.FOLDER_SETTINGS_NAME
                                        AND Name = :NegoptimHelper.DOCUMENT_SETTINGS_NAME LIMIT 1];
            if(documents != null && documents.size() > 0)
                settingsFile = documents.get(0);
        } else {
            errors.add(Label.MSG_Access_Denied);
        }
        if(errors.size() == 0) {
            String strJSON = JSON.serialize(negoSettings);
            try {
                Blob content = Blob.valueof(strJSON);
                Id authorId = UserInfo.getUserId();
                Boolean editContent = true;
                if (folderSetting != null) {
                    if (settingsFile != null) {
                        if (settingsFile.Body != content) {
                            settingsFile.Body = content;
                            settingsFile.AuthorId = authorId;
                        } else {
                            errors.add('Save Global Setting in Document Error: Nothing to update');
                            editContent = false;
                        }
                    } else {
                        settingsFile = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Type = 'json',
                                                    ContentType = 'application/json', //DeveloperName = NegoptimHelper.DOCUMENT_SETTINGS_NAME,
                                                    Body = content, FolderId = folderSetting.Id, AuthorId = authorId);
                    }
                } else{
                    errors.add(string.format(Label.MSG_FolderSettingsNotExist, new String[]{ NegoptimHelper.FOLDER_SETTINGS_NAME }));
                }
                if (settingsFile != null && editContent) {
                    if(NegoptimHelper.checkCreatibility(Document.SObjectType, documentFields) && NegoptimHelper.checkUpdatibility(Document.SObjectType, documentFields)) {
                           upsert settingsFile;
                       }
                    // Remove from cache to reload the new value
                    ////Cache.Org.remove(GlobalSettingCache.class, NegoptimHelper.DOCUMENT_SETTINGS_NAME);
                }
            } catch(DmlException e) {
                errors.add(Label.MSG_Error_Occurred + ' : ' + e.getDmlMessage(0));
            } catch(Exception e) {
                errors.add(Label.MSG_Error_Occurred + ' : ' + e.getMessage());
            }
        }
        return errors;
    }
    /*
     * @description this class used to handle the miss object in the cache, salesforce check for the cache if object is not available, it calls load data then return the result.
     ***************************************************************************************************************************************** */
    public class GlobalSettingCache implements Cache.CacheBuilder{

        public Object doLoad(String cacheType){

            Document settingsFile;
            NegoptimSettings negoSettings = new NegoptimSettings();
            // check security on access document fields
            String [] documentFields = new String [] {
                SObjectType.Document.fields.Id.Name,
                SObjectType.Document.fields.Body.Name,
                SObjectType.Document.fields.Name.Name
            };
            // check security on access Folder fields
            String [] folderFields = new String [] {
                SObjectType.Folder.fields.Name.Name
            };
            if(NegoptimHelper.checkAccessibility(Document.SObjectType, documentFields) && NegoptimHelper.checkAccessibility(Folder.SObjectType, folderFields)) {
                List<Document> documents = [SELECT Id, Body FROM Document WHERE Folder.Name = :NegoptimHelper.FOLDER_SETTINGS_NAME AND Name = :cacheType LIMIT 1];
                if(documents != null && documents.size() > 0) {
                    settingsFile = documents.get(0);
                    negoSettings = (NegoptimSettings) JSON.deserializeStrict(settingsFile.Body.toString(), NegoptimSettings.class);
                } else {
                    negoSettings = new NegoptimSettings();
                }
            }
            return negoSettings;
        }
    }

}