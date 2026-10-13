/**
 * @author ULiT
 * @date 26/12/2017
 * Advanced Settings class
 **/
public with sharing class NegoptimSettings {

    public String sBusinessType {get; set;}
    public Boolean activateMaintenanceMode {get; set;}
    // General Settings
    public Boolean runSellinReparentingForBusinessUnit {get; set;}
    public Boolean AllowCopyProducttoPGFromSellin {get; set;}
    public Boolean contractNumberUnicity {get; set;}
    public Boolean prioritizeSortBDateNegotiate {get; set;}
    public Boolean prioritizeSortBDateNegotiateFollowup {get; set;}
    public Boolean allowContractNameNumberGeneration {get; set;}
    public String[] selectedContractRTPostNegoNList {get; set;}
    public String[] selectedContractRTPostNegoN1List {get; set;}
    public String defaultConditionCode {get; set;}
    public String delimiter {get; set;}
    public String csvDateFormat {get; set;}
    public String groupBU {get; set;}
    public Decimal tOGapTolerenceNegative {get; set;}
    public Decimal tOGapTolerencePositive {get; set;}
    public Decimal coopGapTolerenceNegative {get; set;}
    public Decimal coopGapTolerencePositive {get; set;}
    public Integer reminderLevel {get; set;}
    public Integer reminderValue1 {get; set;}
    public Integer reminderValue2 {get; set;}
    public Integer reminderValue3 {get; set;}
    public String reminderDescription1 {get; set;}
    public String reminderDescription2 {get; set;}
    public String reminderDescription3 {get; set;}
    public String marketDataColletionSource {get; set;}
    // list of BU to be used in invoice reminder
    public List<Id> reminderBUManagedList {get; set;}
    // used to get Id for specifies BU ex: AMC
    public Id profile {get; set;}
    // Control the level of date validation overlap of contracts
    public Boolean datesOverlapControlBU {get; set;}
    // control the type of BU to be used in distribution (Condition_List page)
    public String[] selectedBURTList {get; set;}
    public Boolean allowUpdatingInvoiceDateOnPrint {get; set;}
    public String sellinAggregateMode {get; set;}
    public Boolean allowUpdatingPrintDateOnPrint {get; set;}
    //closing days
    public Integer dispatchMaxClosingDay {get; set;}
    public Integer invoiceMaxClosingDay {get; set;}
    public Boolean dispatchAggregateMode {get; set;}
    public Boolean dispatchHeadOnConditionLevel {get; set;}
    public Boolean dispatchOnHLP {get; set;}
    // Price list user role settings
    public Map<Id, Id> priceListInitDefaultBUMap {get; set;}
    // Grid Settings
    public String assortmentMatrixGridLayout {get; set;}
    public String assortmentMatrixTargetGridLayout {get; set;}
    public String productSwitchGridLayout {get; set;}
    public String productInnoGridLayout {get; set;}
    public String productStopGridLayout {get; set;}
    public String assortmentBudgetSimulatorGridLayout {get; set;}
    public String assortmentMatrixComparatorGridLayout {get; set;}
    public String counterpartyFollowupGridLayout {get; set;}
    public String netPriceStatementMatrixGridLayout {get; set;}
    public String priceListStatementMatrixGridLayout {get; set;}
    public String commercialPlanGridLayout {get; set;}
    public String commercialPlanContractGridLayout {get; set;}
    public String ProductSelectionPGGridLayout {get; set;}
    public String PromoCalendarGridLayout {get; set;}
    // Grid Settings Profiles
    public String[] assortmentMatrixProfile {get; set;}
    public String[] assortmentMatrixTargetProfile {get; set;}
    public String[] productSwitchProfile {get; set;}
    public String[] productInnoProfile {get; set;}
    public String[] productStopProfile {get; set;}
    public String[] assortmentBudgetSimulatorProfile {get; set;}
    public String[] assortmentMatrixComparatorProfile {get; set;}
    // Products Management
    public String[] allowedProfilesToManageProducts {get; set;}
    // Mass batch form sections
    public Boolean MBF_Section_ContractTOProcedures {get; set;}
    public Boolean MBF_Section_ContractDuplication {get; set;}
    public Boolean MBF_Section_LastActiveContractProcedure {get; set;}
    public Boolean MBF_Section_ContractRates {get; set;}
    public Boolean MBF_Section_GroupScanAndSynchro {get; set;}
    public Boolean MBF_Section_PromoDetailProcedure {get; set;}
    public Boolean MBF_Section_MarketDataCollection {get; set;}
    public Boolean MBF_Section_AssortmentSFPlanning {get; set;}
    public Boolean MBF_Section_SellInProcedure {get; set;}
    public Boolean MBF_Section_Batches {get; set;}
    public Boolean MBF_Section_InvoiceReminder {get; set;}
    public Boolean MBF_Section_MassDistribution {get; set;}
    public Boolean MBF_Section_CallingWebServices {get; set;}
    public Boolean MBF_Section_PenaltiesProcedure {get; set;}
    public Boolean MBF_Section_ContractCounterpartyDetail {get; set;}
    public Boolean MBF_Section_RecalculateAssortmentDetail {get; set;}
    public Boolean AllowUpdateP2Clustering {get; set;}
    public Boolean AllowUpdateP1Clustering {get; set;}
    public Boolean Allow_Insert_Account_On_Insert_Supplier {get; set;}
    public Boolean Allow_Dispatching_in_Condition_List {get; set;}
    // Page Settings
    public Boolean openPagesFilterSectionByDefault {get; set;} // controls if the filter section is open or closed by default in all pages and components of the app
    public Boolean manageAssortByPersonalizedCategory {get; set;}
    public String SFPlanningConfiguration {get; set;}
    // higer level packaging Id
    public Id higherLevelPackagingRecordTypeId {get; set;}
    // synchro mode for assortment bus (conso or diffusion)
    public String assortmentSynchroMode {get; set;}
    // product Name synch with auto num
    //public Boolean overrideProductNameWithAutoNum {get; set;}
    //public Integer productAutoNumber {get; set;}
    //public String productNamePrefix {get; set;}
    // record types to include when synching PGs
    //public String[] productRecordTypesforNSPG {get; set;}
    // used for synchro ASD to PG/GRC_Contract
    public String grcContractDataSource {get; set;}
    // invoice settings
    public String invoiceBaseGeneration {get; set;}
    public Id groupBU1 {get; set;}
    public Id groupBU2 {get; set;}
    public String recordTypeForBU1 {get; set;}
    public String recordTypeForBU2 {get; set;}
	public Boolean isInvoiceAmountDistributed {get; set;}
    public Decimal buNavigationDepth {get; set;}
    public DateTime startingDayToCreateLandingOnConso {
        get {
            return startingDayToCreateLandingOnConsoDate != null ?
                DateTime.newInstance(startingDayToCreateLandingOnConsoDate.year(), startingDayToCreateLandingOnConsoDate.month(), startingDayToCreateLandingOnConsoDate.day())
                : DateTime.newInstance(Date.today().year(), 9, 1);
        }
        set;}
    public DateTime startingDayToCreateNegoBaseOnConso {
        get {
            return startingDayToCreateNegoBaseOnConsoDate != null ?
                DateTime.newInstance(startingDayToCreateNegoBaseOnConsoDate.year(), startingDayToCreateNegoBaseOnConsoDate.month(), startingDayToCreateNegoBaseOnConsoDate.day())
                : DateTime.newInstance(Date.today().year(), 9, 1);
        }
        set;}
	public Date startingDayToCreateLandingOnConsoDate {get; set;}
    public Date startingDayToCreateNegoBaseOnConsoDate {get; set;}
    public Integer discountPercentScale { get; set; }
    public NegoptimSettings() {
        this.sBusinessType = BusinessType.None.name();
        this.activateMaintenanceMode = false;
        this.delimiter = ',';
        this.csvDateFormat = 'dd/MM/yyyy';
        this.groupBU = null;
        this.tOGapTolerenceNegative = 0;
        this.tOGapTolerencePositive = 0;
        this.coopGapTolerenceNegative = 0;
        this.coopGapTolerencePositive = 0;
        this.reminderLevel = 0;
        this.reminderValue1 = 0;
        this.reminderValue2 = 0;
        this.reminderValue3 = 0;
        this.reminderBUManagedList = new List<Id>();
        this.invoiceBaseGeneration = null;
        this.groupBU1 = null;
        this.groupBU2 = null;
        this.recordTypeForBU1 = null;
        this.recordTypeForBU2 = null;
        this.profile = null;
        this.datesOverlapControlBU = false;
        this.selectedBURTList = new String[] {'Store', 'Web'};
        this.allowUpdatingInvoiceDateOnPrint = true;
        this.sellinAggregateMode = 'Aggregate on Product level';
        this.allowUpdatingPrintDateOnPrint = true;
        this.dispatchMaxClosingDay = 31;
        this.invoiceMaxClosingDay = 31;
        this.dispatchAggregateMode = true;
        this.dispatchHeadOnConditionLevel = false;
        this.dispatchOnHLP = false;
        this.priceListInitDefaultBUMap = new Map<Id, Id>();
        this.assortmentMatrixGridLayout = 'Matrix_Full';
        this.assortmentMatrixTargetGridLayout = 'Matrix_Target';
        this.productSwitchGridLayout = 'Product_Switch';
        this.productInnoGridLayout = 'Product_Inno';
        this.productStopGridLayout = 'Product_Stop';
        this.assortmentBudgetSimulatorGridLayout = 'Budget_Simulator';
        this.assortmentMatrixComparatorGridLayout = 'Matrix_Full';
        this.counterpartyFollowupGridLayout = 'Counterparty_Followup_Grid';
        this.netPriceStatementMatrixGridLayout = 'NetPrice_Statement_Grid';
        this.priceListStatementMatrixGridLayout = 'Price_List_Statement_Grid';
        this.commercialPlanGridLayout = 'Promo_management';
        this.commercialPlanContractGridLayout = 'Commercial_Plan_Grid_Contract';
        this.ProductSelectionPGGridLayout = 'Product_Selection_PG_Grid_Layout';
        this.PromoCalendarGridLayout = 'PromoCalendar';
        this.assortmentMatrixProfile = new String[]{UserInfo.getProfileId()};
        this.assortmentMatrixTargetProfile = new String[]{UserInfo.getProfileId()};
        this.productSwitchProfile = new String[]{UserInfo.getProfileId()};
        this.productInnoProfile = new String[]{UserInfo.getProfileId()};
        this.productStopProfile = new String[]{UserInfo.getProfileId()};
        this.assortmentBudgetSimulatorProfile = new String[]{UserInfo.getProfileId()};
        this.assortmentMatrixComparatorProfile = new String[]{UserInfo.getProfileId()};
        this.allowedProfilesToManageProducts = new String[]{UserInfo.getProfileId()};
        this.runSellinReparentingForBusinessUnit = true;
        this.contractNumberUnicity = true;
        this.prioritizeSortBDateNegotiate = false;
        this.prioritizeSortBDateNegotiateFollowup = false;
        this.allowContractNameNumberGeneration = true;
        this.selectedContractRTPostNegoNList = new String[] {};
        this.selectedContractRTPostNegoN1List = new String[] {};
        this.defaultConditionCode = null;
        this.MBF_Section_ContractTOProcedures = true;
        this.MBF_Section_ContractDuplication = true;
        this.MBF_Section_LastActiveContractProcedure = true;
        this.MBF_Section_ContractRates = true;
        this.MBF_Section_GroupScanAndSynchro = true;
        this.MBF_Section_PromoDetailProcedure= true;
        this.MBF_Section_MarketDataCollection = true;
        this.MBF_Section_AssortmentSFPlanning = true;
        this.MBF_Section_SellInProcedure = true;
        this.MBF_Section_Batches = true;
        this.MBF_Section_InvoiceReminder = true;
        this.MBF_Section_MassDistribution = true;
        this.MBF_Section_CallingWebServices = true;
        this.MBF_Section_PenaltiesProcedure = true;
        this.MBF_Section_ContractCounterpartyDetail = true;
        this.MBF_Section_RecalculateAssortmentDetail = true;
        this.marketDataColletionSource = null;
        this.AllowUpdateP2Clustering = false;
        this.AllowUpdateP1Clustering = false;
        this.openPagesFilterSectionByDefault = false;
        this.manageAssortByPersonalizedCategory = false;
        this.Allow_Insert_Account_On_Insert_Supplier = true;
        this.Allow_Dispatching_in_Condition_List = false;
        this.SFPlanningConfiguration = 'Configuration_1';
        Map<Id, Schema.RecordTypeInfo> productRecordTypeInfo = Product2.SObjectType.getDescribe().getRecordTypeInfosById();
        //this.productRecordTypesforNSPG = new List<String>();
        for (Id RTId : productRecordTypeInfo.keySet()) {
            if (productRecordTypeInfo.get(RTId).getDeveloperName() == 'Higher_Level_Packaging') {
                this.higherLevelPackagingRecordTypeId = RTId;
            } else {
                //this.productRecordTypesforNSPG.add(RTId);
            }
        }
        this.assortmentSynchroMode = 'Conso';
        //this.overrideProductNameWithAutoNum = false;
        //this.productAutoNumber = 0;
        //this.productNamePrefix = 'Prod';
        this.grcContractDataSource = 'Statement';
        this.AllowCopyProducttoPGFromSellin = false;
        this.isInvoiceAmountDistributed = false;
        this.buNavigationDepth = 1;
        this.startingDayToCreateLandingOnConso = null;
        this.startingDayToCreateNegoBaseOnConso = null;
        this.discountPercentScale = 2;
    }

    /**
     * for Business Type
     * */
    public enum BusinessType {None, Retailer, CPG}
}