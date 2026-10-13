/**
 * @Description Class used in unit test to create common data
 **/
@isTest
public class TestDataFactory {
    
    // Declaration of private static variable in order to use access them via a method from the Unit Test classes.
    private static Integer randomNumber;
    // Declaration of public static variable in order to use them directly from the Unit Test classes.
    public static final Integer year = System.Today().year();
    public static final Integer month = System.Today().month();
    public static final String currencyIsoCode = NegoptimHelper.getCorporateCurrency();
    public static final Map<String, Id> assortmentRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment__c.SObjectType);
    public static final Map<String, Id> assortmentBURTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.SObjectType);
    public static final Map<String, Id> productRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
    public static final Map<String, Id> contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
    public static final Map<String, Id> conditionRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract_Discount__c.SObjectType);
    public static final Map<String, Id> commercialPlanRTIds = NegoptimHelper.getObjectRecordTypeMapIds(CommercialPlan__c.SObjectType);
    public static final Map<String, Id> assortmentPriceWaterFallRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_PriceWaterFall__c.sObjectType);
    public static final Map<String, Id> priceListRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceList__c.SObjectType);
    public static final Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Tax__c.SObjectType);
    public static final Map<String, Id> supplierRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Supplier__c.SObjectType);
    public static final Map<String, Id> invoiceRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Invoice__c.SObjectType);
    public static final Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    /**********************************************************************************************************/
    /** PKG2 **/
    public static final Map<String, Id> businessUnitRTIds = NegoptimHelper.getObjectRecordTypeMapIds(BusinessUnit__c.SObjectType);
    
    // Region creation.
    public static BusinessUnit__c createBusinessUnitRegion(Boolean doInsert, String name) {
        BusinessUnit__c region = new BusinessUnit__c(Name = name, Code__c = name,
                                                     OpeningDate__c = date.newInstance(year, 1, 1),
                                                     Format__c = CommonConstants.HMSM,
                                                     Status__c = 'Open',
                                                     SetAssortmentBudgetBUSource__c = true,
                                                     SetAssortmentBudgetBUTarget__c = true,
                                                     SetAssortmentNegoBUSource__c = true,
                                                     SetAssortmentNegoBUTarget__c = true,
                                                     SetAssortmentTargetBUSource__c = true,
                                                     SetAssortmentTargetBUTarget__c = true,
                                                     SetBULinkMaster__c = true,
                                                     SetComConditionCounterparty__c = true,
                                                     SetComConditionMasterBU__c = true,
                                                     SetAgreementBUSource__c = true,
                                                     SetAgreementBUTarget__c = true,
                                                     // SetAgreementLineBUScope__c = true,
                                                     SetAgreementLineMainTerm__c = true,
                                                     SetAgreementLineSubTerm__c = true,
                                                     SetInvoiceBUDispatchDetail__c = true,
                                                     SetInvoiceDetail__c = true,
                                                     SetInvoicePayment__c = true,
                                                     SetInvoice__c = true,
                                                     // SetProductListing__c = true,
                                                     SetSFDataCollection__c = true,
                                                     SetSFPlanning__c = true,
                                                     // SetBudgetMakerDetail__c = true,
                                                     // SetBudgetMaker__c = true,
                                                     SetNetPriceStatement__c = true,
                                                     SetPriceListStatement__c = true);
        region.RecordTypeId = businessUnitRTIds.get('Region');
        if (doInsert) insert region;
        System.assert(true);
        return region;
    }
  
    // Group creation.
    public static BusinessUnit__c createBusinessUnitGroup(Boolean doInsert, String name) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c groupBU = new BusinessUnit__c(Name = 'Group ' + rdm,
                                                      Code__c = 'G' + rdm,
                                                      //ISOCountryCode__c = 'LBN',,
                                                      Format__c = CommonConstants.HMSM,
                                                      OpeningDate__c = date.newInstance(year, 1, 1),
                                                      Status__c = 'Open',
                                                      SetAssortmentBudgetBUSource__c = true,
                                                      SetAssortmentBudgetBUTarget__c = true,
                                                      SetAssortmentNegoBUSource__c = true,
                                                      SetAssortmentNegoBUTarget__c = true,
                                                      SetAssortmentTargetBUSource__c = true,
                                                      SetAssortmentTargetBUTarget__c = true,
                                                      SetBULinkMaster__c = true,
                                                      SetComConditionCounterparty__c = true,
                                                      SetComConditionMasterBU__c = true,
                                                      SetAgreementBUSource__c = true,
                                                      SetAgreementBUTarget__c = true,
                                                      // SetAgreementLineBUScope__c = true,
                                                      SetAgreementLineMainTerm__c = true,
                                                      SetAgreementLineSubTerm__c = true,
                                                      SetInvoiceBUDispatchDetail__c = true,
                                                      SetInvoiceDetail__c = true,
                                                      SetInvoicePayment__c = true,
                                                      SetInvoice__c = true,
                                                      // SetProductListing__c = true,
                                                      SetSFDataCollection__c = true,
                                                      SetSFPlanning__c = true,
                                                      // SetBudgetMakerDetail__c = true,
                                                      // SetBudgetMaker__c = true,
                                                      SetNetPriceStatement__c = true,
                                                      SetPriceListStatement__c = true,
                                                      SetCommercialPlanTask__c = true,
                                                      CurrencyIsoCode = currencyIsoCode);
        groupBU.RecordTypeId = businessUnitRTIds.get('Group');
        if (doInsert) insert groupBU;
        System.assert(true);
        return groupBU;
    }
    
    // List BU creation.
    public static BusinessUnit__c createBusinessUnitList(Boolean doInsert, Id countryId) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c listBU = new BusinessUnit__c(Name = 'List ' + rdm,
                                                     Code__c = 'L' + rdm,
                                                     BusinessUnitCountryOrigin__c = countryId,
                                                     Format__c = CommonConstants.HMSM,
                                                     //ISOCountryCode__c = 'LBN',
                                                     OpeningDate__c = date.newInstance(year, 1, 1),
                                                     Status__c = 'Open',
                                                     SetAssortmentBudgetBUSource__c = true,
                                                     SetAssortmentBudgetBUTarget__c = true,
                                                     SetAssortmentNegoBUSource__c = true,
                                                     SetAssortmentNegoBUTarget__c = true,
                                                     SetAssortmentTargetBUSource__c = true,
                                                     SetAssortmentTargetBUTarget__c = true,
                                                     SetBULinkMaster__c = true,
                                                     SetComConditionCounterparty__c = true,
                                                     SetComConditionMasterBU__c = true,
                                                     SetAgreementBUSource__c = true,
                                                     SetAgreementBUTarget__c = true,
                                                     // SetAgreementLineBUScope__c = true,
                                                     SetAgreementLineMainTerm__c = true,
                                                     SetAgreementLineSubTerm__c = true,
                                                     SetInvoiceBUDispatchDetail__c = true,
                                                     SetInvoiceDetail__c = true,
                                                     SetInvoicePayment__c = true,
                                                     SetInvoice__c = true,
                                                     // SetProductListing__c = true,
                                                     SetSFDataCollection__c = true,
                                                     SetSFPlanning__c = true,
                                                     // SetBudgetMakerDetail__c = true,
                                                     // SetBudgetMaker__c = true,
                                                     SetNetPriceStatement__c = true,
                                                     SetPriceListStatement__c = true,
                                                     CurrencyIsoCode = currencyIsoCode);
        listBU.RecordTypeId = businessUnitRTIds.get('List');
        if (doInsert) insert listBU;
        System.assert(true);
        return listBU;
    }
    
    // Country creation.
    public static BusinessUnit__c createBusinessUnitCountry(Boolean doInsert, Id regionId) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c country = new BusinessUnit__c(Name = 'Country ' + rdm,
                                                      Code__c = 'Country ' + rdm,
                                                      //ISOCountryCode__c = 'LBN',
                                                      //Country__c = '',
                                                      BusinessUnitRegion__c = regionId,
                                                      Format__c = CommonConstants.HMSM,
                                                      OpeningDate__c = date.newInstance(year, 1, 1),
                                                      Status__c = 'Open',
                                                      SetAssortmentBudgetBUSource__c = true,
                                                      SetAssortmentBudgetBUTarget__c = true,
                                                      SetAssortmentNegoBUSource__c = true,
                                                      SetAssortmentNegoBUTarget__c = true,
                                                      SetAssortmentTargetBUSource__c = true,
                                                      SetAssortmentTargetBUTarget__c = true,
                                                      SetBULinkMaster__c = true,
                                                      SetComConditionCounterparty__c = true,
                                                      SetComConditionMasterBU__c = true,
                                                      SetAgreementBUSource__c = true,
                                                      SetAgreementBUTarget__c = true,
                                                      // SetAgreementLineBUScope__c = true,
                                                      SetAgreementLineMainTerm__c = true,
                                                      SetAgreementLineSubTerm__c = true,
                                                      SetInvoiceBUDispatchDetail__c = true,
                                                      SetInvoiceDetail__c = true,
                                                      SetInvoicePayment__c = true,
                                                      SetInvoice__c = true,
                                                      // SetProductListing__c = true,
                                                      SetSFDataCollection__c = true,
                                                      SetSFPlanning__c = true,
                                                      // SetBudgetMakerDetail__c = true,
                                                      // SetBudgetMaker__c = true,
                                                      SetNetPriceStatement__c = true,
                                                      SetPriceListStatement__c = true,
                                                      CurrencyIsoCode = currencyIsoCode);
        country.RecordTypeId = businessUnitRTIds.get('Country');
        if (doInsert) insert country;
        System.assert(true);
        return country;
    }
    
    // Banner creation.
    public static BusinessUnit__c createBusinessUnitBanner(Boolean doInsert, BusinessUnit__c country) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c banner = new BusinessUnit__c(Name = 'Banner ' + rdm,
                                                     Code__c = 'B' + rdm,
                                                     //Country__c = country.Name,
                                                     BusinessUnitCountryOrigin__c = country.Id,
                                                     Format__c = CommonConstants.HMSM,
                                                     OpeningDate__c = date.newInstance(year, 1, 1),
                                                     Status__c = 'Open',
                                                     SetAssortmentBudgetBUSource__c = true,
                                                     SetAssortmentBudgetBUTarget__c = true,
                                                     SetAssortmentNegoBUSource__c = true,
                                                     SetAssortmentNegoBUTarget__c = true,
                                                     SetAssortmentTargetBUSource__c = true,
                                                     SetAssortmentTargetBUTarget__c = true,
                                                     SetBULinkMaster__c = true,
                                                     SetComConditionCounterparty__c = true,
                                                     SetComConditionMasterBU__c = true,
                                                     SetAgreementBUSource__c = true,
                                                     SetAgreementBUTarget__c = true,
                                                     // SetAgreementLineBUScope__c = true,
                                                     SetAgreementLineMainTerm__c = true,
                                                     SetAgreementLineSubTerm__c = true,
                                                     SetInvoiceBUDispatchDetail__c = true,
                                                     SetInvoiceDetail__c = true,
                                                     SetInvoicePayment__c = true,
                                                     SetInvoice__c = true,
                                                     // SetProductListing__c = true,
                                                     SetSFDataCollection__c = true,
                                                     SetSFPlanning__c = true,
                                                     // SetBudgetMakerDetail__c = true,
                                                     // SetBudgetMaker__c = true,
                                                     SetNetPriceStatement__c = true,
                                                     SetPriceListStatement__c = true,
                                                     CurrencyIsoCode = currencyIsoCode);
        banner.RecordTypeId = businessUnitRTIds.get('Banner');
        if (doInsert) insert banner;
        System.assert(true);
        return banner;
    }
    
    // Channel creation.
    public static BusinessUnit__c createBusinessUnitChannel(Boolean doInsert, BusinessUnit__c country) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c channel = new BusinessUnit__c(Name = 'Channel ' + rdm,
                                                      Code__c = 'CH' + rdm,
                                                      //Country__c = country.Name,
                                                      BusinessUnitCountryOrigin__c = country.Id,
                                                      Format__c = CommonConstants.HMSM,
                                                      OpeningDate__c = date.newInstance(year, 1, 1),
                                                      Status__c = 'Open',
                                                      SetAssortmentBudgetBUSource__c = true,
                                                      SetAssortmentBudgetBUTarget__c = true,
                                                      SetAssortmentNegoBUSource__c = true,
                                                      SetAssortmentNegoBUTarget__c = true,
                                                      SetAssortmentTargetBUSource__c = true,
                                                      SetAssortmentTargetBUTarget__c = true,
                                                      SetBULinkMaster__c = true,
                                                      SetComConditionCounterparty__c = true,
                                                      SetComConditionMasterBU__c = true,
                                                      SetAgreementBUSource__c = true,
                                                      SetAgreementBUTarget__c = true,
                                                      // SetAgreementLineBUScope__c = true,
                                                      SetAgreementLineMainTerm__c = true,
                                                      SetAgreementLineSubTerm__c = true,
                                                      SetInvoiceBUDispatchDetail__c = true,
                                                      SetInvoiceDetail__c = true,
                                                      SetInvoicePayment__c = true,
                                                      SetInvoice__c = true,
                                                      // SetProductListing__c = true,
                                                      SetSFDataCollection__c = true,
                                                      SetSFPlanning__c = true,
                                                      // SetBudgetMakerDetail__c = true,
                                                      // SetBudgetMaker__c = true,
                                                      SetNetPriceStatement__c = true,
                                                      SetPriceListStatement__c = true,
                                                      CurrencyIsoCode = currencyIsoCode);
        channel.RecordTypeId = businessUnitRTIds.get('Channel');
        if (doInsert) insert channel;
        System.assert(true);
        return channel;
    }
    
    // Assortment Cluster creation.
    public static BusinessUnit__c createBusinessUnitAssortCluster(Boolean doInsert, Id countryId, String strat) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c assort = new BusinessUnit__c(Name = 'Assort Cluster' + rdm,
                                                     Code__c = rdm,
                                                     BusinessUnitCountryOrigin__c = countryId,
                                                     Format__c = CommonConstants.HMSM,
                                                     AssortmentStrat__c = strat,
                                                     OpeningDate__c = date.newInstance(year, 1, 1),
                                                     Status__c = 'Open',
                                                     SetAssortmentBudgetBUSource__c = true,
                                                     SetAssortmentBudgetBUTarget__c = true,
                                                     SetAssortmentNegoBUSource__c = true,
                                                     SetAssortmentNegoBUTarget__c = true,
                                                     SetAssortmentTargetBUSource__c = true,
                                                     SetAssortmentTargetBUTarget__c = true,
                                                     SetBULinkMaster__c = true,
                                                     SetComConditionCounterparty__c = true,
                                                     SetComConditionMasterBU__c = true,
                                                     SetAgreementBUSource__c = true,
                                                     SetAgreementBUTarget__c = true,
                                                     // SetAgreementLineBUScope__c = true,
                                                     SetAgreementLineMainTerm__c = true,
                                                     SetAgreementLineSubTerm__c = true,
                                                     SetInvoiceBUDispatchDetail__c = true,
                                                     SetInvoiceDetail__c = true,
                                                     SetInvoicePayment__c = true,
                                                     SetInvoice__c = true,
                                                     // SetProductListing__c = true,
                                                     SetSFDataCollection__c = true,
                                                     SetSFPlanning__c = true,
                                                     // SetBudgetMakerDetail__c = true,
                                                     // SetBudgetMaker__c = true,
                                                     SetNetPriceStatement__c = true,
                                                     SetPriceListStatement__c = true,
                                                     CurrencyIsoCode = currencyIsoCode);
        assort.RecordTypeId = businessUnitRTIds.get('AssortmentCluster');
        if (doInsert) insert assort;
        System.assert(true);
        return assort;
    }
    
    // Warehouse creation.
    public static BusinessUnit__c createBusinessUnitWarehouse(Boolean doInsert, Id countryId) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c warehouse = new BusinessUnit__c(Name = 'Warehouse' + rdm,
                                                        Code__c = rdm,
                                                        BusinessUnitCountryOrigin__c = countryId,
                                                        Format__c = CommonConstants.HMSM,
                                                        OpeningDate__c = date.newInstance(year, 1, 1),
                                                        Status__c = 'Open',
                                                        SetAssortmentBudgetBUSource__c = true,
                                                        SetAssortmentBudgetBUTarget__c = true,
                                                        SetAssortmentNegoBUSource__c = true,
                                                        SetAssortmentNegoBUTarget__c = true,
                                                        SetAssortmentTargetBUSource__c = true,
                                                        SetAssortmentTargetBUTarget__c = true,
                                                        SetBULinkMaster__c = true,
                                                        SetComConditionCounterparty__c = true,
                                                        SetComConditionMasterBU__c = true,
                                                        SetAgreementBUSource__c = true,
                                                        SetAgreementBUTarget__c = true,
                                                        // SetAgreementLineBUScope__c = true,
                                                        SetAgreementLineMainTerm__c = true,
                                                        SetAgreementLineSubTerm__c = true,
                                                        SetInvoiceBUDispatchDetail__c = true,
                                                        SetInvoiceDetail__c = true,
                                                        SetInvoicePayment__c = true,
                                                        SetInvoice__c = true,
                                                        // SetProductListing__c = true,
                                                        SetSFDataCollection__c = true,
                                                        SetSFPlanning__c = true,
                                                        // SetBudgetMakerDetail__c = true,
                                                        // SetBudgetMaker__c = true,
                                                        SetNetPriceStatement__c = true,
                                                        SetPriceListStatement__c = true,
                                                        CurrencyIsoCode = currencyIsoCode);
        warehouse.RecordTypeId = businessUnitRTIds.get('Warehouse');
        if (doInsert) insert warehouse;
        System.assert(true);
        return warehouse;
    }
    
    // Web creation.
    public static BusinessUnit__c createBusinessUnitWeb(Boolean doInsert, Id countryId) {
        String rdm = String.valueOf(getRandomNumber());
        BusinessUnit__c warehouse = new BusinessUnit__c(Name = 'Web' + rdm,
                                                        Code__c = rdm,
                                                        BusinessUnitCountryOrigin__c = countryId,
                                                        Format__c = CommonConstants.HMSM,
                                                        OpeningDate__c = date.newInstance(year, 1, 1),
                                                        Status__c = 'Open',
                                                        SetAssortmentBudgetBUSource__c = true,
                                                        SetAssortmentBudgetBUTarget__c = true,
                                                        SetAssortmentNegoBUSource__c = true,
                                                        SetAssortmentNegoBUTarget__c = true,
                                                        SetAssortmentTargetBUSource__c = true,
                                                        SetAssortmentTargetBUTarget__c = true,
                                                        SetBULinkMaster__c = true,
                                                        SetComConditionCounterparty__c = true,
                                                        SetComConditionMasterBU__c = true,
                                                        SetAgreementBUSource__c = true,
                                                        SetAgreementBUTarget__c = true,
                                                        // SetAgreementLineBUScope__c = true,
                                                        SetAgreementLineMainTerm__c = true,
                                                        SetAgreementLineSubTerm__c = true,
                                                        SetInvoiceBUDispatchDetail__c = true,
                                                        SetInvoiceDetail__c = true,
                                                        SetInvoicePayment__c = true,
                                                        SetInvoice__c = true,
                                                        // SetProductListing__c = true,
                                                        SetSFDataCollection__c = true,
                                                        SetSFPlanning__c = true,
                                                        // SetBudgetMakerDetail__c = true,
                                                        // SetBudgetMaker__c = true,
                                                        SetNetPriceStatement__c = true,
                                                        SetPriceListStatement__c = true,
                                                        CurrencyIsoCode = currencyIsoCode);
        warehouse.RecordTypeId = businessUnitRTIds.get('Web');
        if (doInsert) insert warehouse;
        System.assert(true);
        return warehouse;
    }
    
    // List of stores creation.
    public static List<BusinessUnit__c> createBusinessUnitStores(Boolean doInsert, BusinessUnit__c country, Integer nbr) {
        List<BusinessUnit__c> stores = new List<BusinessUnit__c>();
        for(Integer i = 0; i < nbr; i++) {
            BusinessUnit__c store = new BusinessUnit__c(Name = 'Store ' + i,
                                                        Code__c = 'Store ' + i,
                                                        Format__c = CommonConstants.HMSM,
                                                        BusinessUnitCountryOrigin__c = country.Id,
                                                        BusinessUnitRegion__c = country.BusinessUnitRegion__c,
                                                        //Country__c = country.Name,
                                                        OpeningDate__c = date.newInstance(year, 1, 1),
                                                        Status__c = 'Open',
                                                        CurrencyIsoCode = currencyIsoCode,
                                                        SetBULinkMaster__c = true);
            store.RecordTypeId = businessUnitRTIds.get('Store');
            stores.add(store);
        }
        if (doInsert) insert stores;
        System.assert(true);
        return stores;
    }
    
    // List of warehouses creation.
    public static List<BusinessUnit__c> createBusinessUnitWarehouses(Boolean doInsert, BusinessUnit__c country, String n, Integer nbr) {
        List<BusinessUnit__c> warehouses = new List<BusinessUnit__c>();
        for(Integer i = 0; i < nbr; i++) {
            BusinessUnit__c warehouse = new BusinessUnit__c(Name = 'WareH ' + i,
                                                            Code__c = 'WareH ' + i,
                                                            BusinessUnitCountryOrigin__c = country.Id,
                                                            OpeningDate__c = date.newInstance(year, 1, 1),
                                                            Status__c = 'Open',
                                                            CurrencyIsoCode = currencyIsoCode,
                                                            SetBULinkMaster__c = true);
            warehouse.RecordTypeId = businessUnitRTIds.get('Warehouse');
            warehouses.add(warehouse);
        }
        if (doInsert) insert warehouses;
        System.assert(true);
        return warehouses;
    }
    
    /* HIERARCHY ELEMENT + BRAND + PRODUCT + SELL IN */
    // Department creation.
    public static Hierarchy__c createHierarchyDepartment(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Hierarchy__c department = new Hierarchy__c(Name = 'DPT ' + rdm, Code__c = 'D' + rdm, HierarchyParent__c = parentId, Level__c = 1,
                                               //SetDispatchStartingPoint__c = false, SetPurchasesStartingPoint__c = true,
                                               SetAssortmentLevel__c = true, StatusBDate__c = date.newInstance(year, 1, 1), Status__c = 'Active',
                                               /*Set_Market_Review_level__c = true,*/
                                               RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'),
                                               SetAssortmentClusterLevel__c = true);
        if (doInsert) insert department;
        System.assert(true);
        return department;
    }
    // Section creation.
    public static Hierarchy__c createHierarchySection(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Hierarchy__c section = new Hierarchy__c(Name = 'SEC ' + rdm, Code__c = 'S' + rdm, HierarchyParent__c = parentId, Level__c = 2,
                                            //SetDispatchStartingPoint__c = true, SetPurchasesStartingPoint__c = false,
                                            StatusBDate__c = date.newInstance(year, 1, 1), Status__c = 'Active', SetProductLevel__c = true,
                                            /*Set_Market_Review_level__c = true,*/
                                            RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Hierarchy__c.sObjectType, 'Product'),
                                            SetAssortmentClusterLevel__c = true);
        if (doInsert) insert section;
        System.assert(true);
        return section;
    }
    /* PRODUCT GROUP + PURCHASE */
    // Supplier PG Mapping creation.
    public static PG__c createPG(Boolean doInsert, Id supplierId, Id hierarchyId) {
        String rdm = String.valueOf(getRandomNumber());
        PG__c pg = new PG__c(Supplier__c = supplierId, Hierarchy__c = hierarchyId,
                             Name = 'PG' + rdm, CurrencyIsoCode = currencyIsoCode);
        if (doInsert) Database.insert(pg);
        System.assert(true);
        return pg;
    }
    /* SUPPLIER + NEGOSCOPE */
    // Supplier creation.
    public static Supplier__c createSupplier(Boolean doInsert, BusinessUnit__c country, Boolean withNS) {
        String rdm = String.valueOf(getRandomNumber());
        Supplier__c supplier = new Supplier__c(Name = 'SUP ' + rdm, Code__c = rdm, BusinessUnitOrigin__c = country.Id,
                                               t_CreateDefaultNegoScope__c = withNS, Status__c = 'Active', CurrencyIsoCode = currencyIsoCode);
        if (doInsert) insert supplier;
        System.assert(true);
        return supplier;
    }
    /**********************************************************************************************************/
    // Method to increment randomNumber
    private static Integer getRandomNumber() {
        if (randomNumber == null)
            randomNumber = (Integer)(Math.random()*9999);
        return randomNumber++;
    }    
    /**
     * Single creations.
     *******************/
     
    /* BUSINESS UNIT */
    // Country List creation.
    public static Country_List__c createCountry(Boolean doInsert, String name, String code) {
        Country_List__c myCountry = new Country_List__c(Name = name, Country_Code__c = code);
        if (doInsert) insert myCountry;
        System.assert(true);
        return myCountry;
    }
    
    //Country creation.
    public static Country__c createCountry_TMP(Boolean doInsert, String name, String code) {
        Country__c myCountry = new Country__c(Name = name, Code__c = code);
        if (doInsert) insert myCountry;
        System.assert(true);
        return myCountry;
    }
    
    // Create an instance of Sup_sup_NegoScope__c
    public static NegoScope__c createNegoScope(Boolean doInsert, Supplier__c supplier, String name) {
        NegoScope__c negoScope = new NegoScope__c(Supplier__c = supplier.id, Name = name);
        if (doInsert) insert negoScope;
        return negoScope;
    }


    public static List<ContactOperationalDirectory__c> createContactOperationalDirectories(Boolean doInsert, Integer numberOfRecords, Supplier__c supplier, NegoScope__c negoScope, Contact contact) {
        List<ContactOperationalDirectory__c> codList = new List<ContactOperationalDirectory__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            ContactOperationalDirectory__c cod = new ContactOperationalDirectory__c(
                Supplier__c = supplier.Id,
                Negoscope__c = negoScope.Id,
                Contact__c = contact.Id
            );
            codList.add(cod);
        }
        if (doInsert) {
            insert codList;
        }
        return codList;
    }

     // Commercial Plan creation.
    public static CommercialPlan__c createCommercialPlan(Boolean doInsert, Date beginDate, Date endDate) {
        String rdm = String.valueOf(getRandomNumber());
        CommercialPlan__c commercialPlan = new CommercialPlan__c(Name = 'Comm' + rdm, SellOutBDate__c = beginDate, SellOutEDate__c = endDate,
                                                                 /*Event_Type__c = 'Collection', Event_Support__c = 'Front path',*/ Status__c = 'In Preparation',
                                                                 CurrencyIsoCode = currencyIsoCode);
        /*commercialPlan.RecordTypeId = commercialPlanRTIds.get('Sales_Floor_Event');*/
        if (doInsert) Database.insert(commercialPlan);
        System.assert(true);
        return commercialPlan;
    }
     // Commercial Plan Detail creation.
    public static CommercialPlanDetail__c createCommercialPlanDetail(Boolean doInsert, Id commercialPlanId/*, Sup_sup_NegoScope__c NS*/) {
        CommercialPlanDetail__c commercialPlanDetail = new CommercialPlanDetail__c(CommercialPlan__c = commercialPlanId/*, Nego_Scope__c = NS.Id,
                                                                                   Supplier__c = NS.Supplier__c, Contribution_Unit_Quantity__c = 1*/, SellInDiscountUAmtNego__c = 1,
                                                                                   Status__c = 'Demande de capa',/* Temp_Contract_Reference__c = 'Temp Ref Contract...',*/
                                                                                   CurrencyIsoCode = currencyIsoCode);
   		if (doInsert) Database.insert(commercialPlanDetail);
   		System.assert(true);
        return commercialPlanDetail;
    }
    public static Id getHierarchyRootId() {
        return NegoptimHelper.getHierarchyRootId('Product');
    }
   
    // Brand creation.
    public static Brand__c createBrand(Boolean doInsert, Id supplierId) {
        String rdm = String.valueOf(getRandomNumber());
        String name = 'BRAND ' + rdm;
        Brand__c brand = new Brand__c(Name = name, Supplier__c = supplierId, StatusBDate__c = date.newInstance(year, 1, 1));
        if (doInsert) insert brand;
        System.assert(true);
        return brand;
    }
    // Product creation.
    public static Product2 createProduct(Boolean doInsert, Id sectionId, Id supplierId) {
        String rdm = String.valueOf(getRandomNumber());
        Product2 product = new Product2(Name = 'PRD ' + rdm, ProductCode = 'P' + rdm, GTIN__c = '10000' + rdm,
                                        Hierarchy__c = sectionId, Product_MasterSupplier__c = supplierId, IsActive = true,
                                        Ext_id__c = '10000' + rdm + '_' + 'P' + rdm);
        if (doInsert) insert product;
        System.assert(true);
        return product;
    }
    
    // Get the list of NS related to the supplier passed by parameter.
    public static List<NegoScope__c> getNSs(Id SupplierId) {
        System.assert(true);
        return [SELECT Id, Name, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.BusinessUnitOrigin__c,
                OwnerId, NS_Code__c, CodeLong__c
                FROM NegoScope__c
                WHERE Supplier__c = :supplierId];
    }
    // NS creation.
    public static NegoScope__c createNS(Boolean doInsert, Id SupplierId) {
        String rdm = String.valueOf(getRandomNumber());
        NegoScope__c NS = new NegoScope__c(Name = 'NS' + rdm, Supplier__c = supplierId, Status__c = 'Active'/*,
Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false*/);
        if (doInsert) insert NS;
        System.assert(true);
        return NS;
    }
    // NS Brand creation.
    public static NSBra__c createNSBrand(Boolean doInsert, NegoScope__c NS, Id brandId) {
        NSBra__c NSBrand = new NSBra__c(Brand__c = brandId, NegoScope__c = NS.Id);
        if (doInsert) insert NSBrand;
        System.assert(true);
        return NSBrand;
    }
    
    // NS HE creation.
    public static NSHE__c createNSHE(Boolean doInsert, NegoScope__c NS, Id sectionId) {
        NSHE__c NSHE = new NSHE__c(NegoScope__c = NS.Id, Hierarchy__c = sectionId);
        if (doInsert) insert NSHE;
        System.assert(true);
        return NSHE;
    }
    
    // NS PG creation.
    public static NSPG__c createNSPG(Boolean doInsert, NegoScope__c NS, Id PGId) {
        NSPG__c NSPG = new NSPG__c(PG__c = PGId, NegoScope__c = NS.Id, Status__c = 'Open');
        if (doInsert) insert NSPG;
        System.assert(true);
        return NSPG;
    }
    
    /* CONTRACT + CONDITION */
    // Contract creation.
    public static Contract__c createContract(Boolean doInsert, NegoScope__c NS, Date beginDate, Date endDate) {
        String rdm = String.valueOf(getRandomNumber());
        Contract__c contract = new Contract__c(Name = NS.Supplier__r.Name + ' - Contract ' + year, Supplier__c = NS.Supplier__c,
                                               Supplier_Nego_Scope__c = NS.Id, BusinessUnitContract__c = NS.Supplier__r.BusinessUnitOrigin__c,
                                               BusinessUnitSource__c = NS.Supplier__r.BusinessUnitOrigin__c, Contract_BDate__c = beginDate,
                                               Contract_EDate__c = endDate, Duration__c = beginDate.monthsBetween(endDate) + 1,
                                               Contract_Commercial_BDate__c = beginDate, Contract_Commercial_EDate__c = endDate,
                                               Contract_Type__c = 'Contract', Status__c = 'Signed', Ext_id__c = rdm, D_N__c = 'N',
                                               /*Duration_type__c = 'Month', Contract_Numbder__c = 'c' + rdm,*/
                                               RecordTypeId = contractRTIds.get('To_Be_Signed'), Is_Managed_By_ExternalSource__c = false);
        if (doInsert) Database.insert(contract);
        System.assert(true);
        return contract;
    }
    public static Contract__c createContract(Boolean doInsert, BusinessUnit__c country, Supplier__c supplier, NegoScope__c NS) {
        String rdm = String.valueOf(getRandomNumber());
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id,
                                               Supplier_Nego_Scope__c = NS.Id, BusinessUnitContract__c = country.Id,
                                               BusinessUnitSource__c = country.Id, Contract_BDate__c = Date.newInstance(year, 1, 1),
                                               Contract_EDate__c = Date.newInstance(year, 12, 31), Duration__c = 12,
                                               Contract_Commercial_BDate__c =  Date.newInstance(year, 1, 1),
                                               Contract_Commercial_EDate__c = Date.newInstance(year, 12, 31),
                                               Contract_Type__c = 'Contract', Status__c = 'Signed', Ext_id__c = rdm, D_N__c = 'N',
                                               /*Duration_type__c = 'Month', Contract_Numbder__c = 'c' + rdm,*/
                                               RecordTypeId = contractRTIds.get('To_Be_Signed'), Is_Managed_By_ExternalSource__c = false);
        if (doInsert) Database.insert(contract);
        System.assert(true);
        return contract;
    }
    
    // Tarrif Condition creation.
    public static Pol_Com_Condition__c createTariffCondition(Boolean doInsert, Integer pickListValue, Integer indexValue) {
        String rdm = String.valueOf(getRandomNumber());
        // Get field describe.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        // Get the picklist value.
        String plv = fieldResult.getPicklistValues().get(pickListValue).getValue();
        // Create an instance of Tarrif Condition.
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Index__c = 'Index' + indexValue,
                                                                        Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = rdm,
                                                                        Abrev__c = 'TC', Gen_Name_com__c = 'TC', Name_Com__c = 'TC', Name_Fi__c = 'TC', Name_Leg__c = 'TC',
                                                                        Gen_Name_Fi__c = 'TC', Gen_Name_Leg__c = 'TC', VAT_Type__c = 'Rebate', Acc_Document_Type__c = 'CreditNoteRequest',
                                                                        Is_Tariff_Condition__c = true);
        // Do insertion.
        if (doInsert) insert tariffCondition;
        System.assert(true);
        return tariffCondition;
    }
    
    // Condition creation.
    public static Contract_Discount__c createCondition(Boolean doInsert, Pol_Com_Condition__c tariffCondition, Contract__c contract, Date beginDate, Date endDate) {
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                  Contract__c = contract.Id, Product_Scope__c = contract.Supplier_Nego_Scope__c, BusinessUnitScope__c = contract.BusinessUnitSource__c,
                                                                  Disc_BDate__c = beginDate, Disc_EDate__c = endDate, CurrencyIsoCode = currencyIsoCode,
                                                                  RecordTypeId = TestDataFactory.conditionRTIds.get('To_Be_Signed'));
        if (doInsert) Database.insert(condition);
        System.assert(true);
        return condition;
    }

    /* INVOICING */
    public static Invoice__c createDownPaymentInvoice(Boolean doInsert, Id contractId, Supplier__c supplierBuyer, Date invDate, Integer seqNumber) {
        Invoice__c invoice = new Invoice__c(SupplierBuyer__c = supplierBuyer.Id,
                                            AccDoc__c = 'DownPaymentInvoice',
                                            Status__c = 'Generated',
                                            Contract__c = contractId,
                                            BusinessUnitSeller__c = supplierBuyer.BusinessUnitOrigin__c,
                                            InvDate__c = invDate,
                                            SeqNumber__c = seqNumber,
                                            RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource'));
        if (doInsert) Database.insert(invoice);
        System.assert(true);
        return invoice;
    }
    public static Invoice__c createCreditNote(Boolean doInsert, Id contractId, Supplier__c supplierBuyer, Date invDate, Integer seqNumber) {
        Invoice__c invoice = new Invoice__c(SupplierBuyer__c = supplierBuyer.Id,
                                            AccDoc__c = 'CreditNote',
                                            Status__c = 'Generated',
                                            Contract__c = contractId,
                                            BusinessUnitSeller__c = supplierBuyer.BusinessUnitOrigin__c,
                                            InvDate__c = invDate,
                                            SeqNumber__c = seqNumber,
                                            RecordTypeId = TestDataFactory.invoiceRTIds.get('TargetToSource'));
        if (doInsert) Database.insert(invoice);
        System.assert(true);
        return invoice;
    }

    public static InvoiceDetail__c createInvoiceDetail(Boolean doInsert, Id invoiceId, Id conditionId, Id businessUnitSellerId, Decimal amount) {
        InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(Invoice__c = invoiceId,
                                                              BusinessUnitSellerDetail__c = businessUnitSellerId,
                                                              DISCLineD__c = conditionId,
                                                              DetailAmount__c = amount);
        if (doInsert) Database.insert(invoiceDetail);
        System.assert(true);
        return invoiceDetail;
    }
    
    public static Payment__c createPayment(Boolean doInsert, Supplier__c supplierBuyer, Date paymentDate) {
        Payment__c payment = new Payment__c(SupplierBuyer__c = supplierBuyer.Id,
                                            PaymentType__c = 'Deduction',
                                            Status__c = 'Validated',
                                            BusinessUnitSeller__c = supplierBuyer.BusinessUnitOrigin__c,
                                            PaymentDate__c = paymentDate);
        if (doInsert) Database.insert(payment);
        System.assert(true);
        return payment;
    }
    
    public static PaymentDetail__c createPaymentDetail(Boolean doInsert, Id paymentId, Id invoiceDetailId, Decimal amount) {
        PaymentDetail__c paymentDetail = new PaymentDetail__c(Payment__c = paymentId,
                                                              LetteringType__c = 'PaidInvoiceLettering',
                                                              Status__c = 'Validated',
                                                              InvoiceDetail__c = invoiceDetailId,
                                                              AmountwVAT__c = amount);
        if (doInsert) Database.insert(paymentDetail);
        System.assert(true);
        return paymentDetail;
    }
    
    /* PRODUCT GROUP + PURCHASE */
    // Supplier PG Mapping creation.
    public static PG__c createPG(Boolean doInsert, Id supplierId, Id departmentId, Id sectionId) {
        String rdm = String.valueOf(getRandomNumber());
        PG__c PG = new PG__c(Supplier__c = supplierId, Hierarchy__c = departmentId,
                                                               Name = 'PG' + rdm, CurrencyIsoCode = currencyIsoCode);
        if (doInsert) Database.insert(PG);
        System.assert(true);
        return PG;
    }
    // Commercial Plan Detail creation.
    public static CommercialPlanDetail__c createCommercialPlanDetail(Boolean doInsert, Id commercialPlanId, NegoScope__c NS) {
        CommercialPlanDetail__c commercialPlanDetail = new CommercialPlanDetail__c(CommercialPlan__c = commercialPlanId, NegoScope__c = NS?.Id,
                                                                                   Supplier__c = NS?.Supplier__c, /*Contribution_Unit_Quantity__c = 1,*/ SellInDiscountUAmtNego__c = 1,
                                                                                   Status__c = 'Demande de capa',/* Temp_Contract_Reference__c = 'Temp Ref Contract...',*/
                                                                                   CurrencyIsoCode = currencyIsoCode);
        if (doInsert) Database.insert(commercialPlanDetail);
        System.assert(true);
        return commercialPlanDetail;
    }
    /* SETTINGS + OTHERS */
    // Negoptim Custom Settings creation.
    public static NegoptimCustomSettings__c createNegoptimCustomSettings(Boolean doInsert) {
        NegoptimCustomSettings__c negoCustomSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', CSV_Delimiter__c = ',',
                                                                                     Group_Code_BU_for_Integration__c = 'AMC',
                                                                                     Allowed_profiles_to_manage_Products__c = UserInfo.getProfileId());
        if (doInsert) Database.insert(negoCustomSettings);
        System.assert(true);
        return negoCustomSettings;
    }
    // Document creation.
    public static Document createDocument(Boolean doInsert, Id folderId, String content) {
        Document document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, FolderId = folderId, Body = Blob.valueof(content));
        if (doInsert) insert document;
        System.assert(true);
        return document;
    }
        
    /* SUPPLIERS */
    // List of suppliers creation.
    public static List<Supplier__c> createSuppliers(Boolean doInsert, BusinessUnit__c country, Boolean withNS, Integer nb) {
        String rdm = String.valueOf(getRandomNumber());
        List<Supplier__c> suppliers = new List<Supplier__c>();
        for (Integer i = 0; i < nb; i++) {
            suppliers.add(new Supplier__c(Name = rdm + i, Code__c = rdm + i, BusinessUnitOrigin__c = country.Id,
                                          t_CreateDefaultNegoScope__c = withNS, Status__c = 'Active', CurrencyIsoCode = currencyIsoCode));
        }
        if (doInsert) insert suppliers;
        System.assert(true);
        return suppliers;
    }

    /* CONTRACTS + CONDITIONS */
    // List of tarrif conditions creation.
    public static List<Pol_Com_Condition__c> createTariffConditions(Boolean doInsert, Integer ndx, Integer nbr) {
        String rdm = String.valueOf(getRandomNumber());
        List<Pol_Com_Condition__c> tariffConditions = new List<Pol_Com_Condition__c>();
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        for(Integer i = 0; i < nbr; i++) {
            String plv = fieldResult.getPicklistValues().get(i).getValue();
            Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Index__c = 'Index' + ndx,
                                                                            Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'T' + rdm + i, Abrev__c = 'TC', Gen_Name_com__c = 'TC',
                                                                            Name_Com__c = 'TC', Name_Fi__c = 'TC', Name_Leg__c = 'TC', Gen_Name_Fi__c = 'TC', Gen_Name_Leg__c = 'TC',
                                                                            VAT_Type__c = 'Rebate', Acc_Document_Type__c = 'CreditNoteRequest');
            tariffConditions.add(tariffCondition);
        }
        if (doInsert) insert tariffConditions;
        System.assert(true);
        return tariffConditions;
    }
    // Create contract with one or more condition(s). // TODO: Add Begin and End Dates.
    public static List<SObject> createContractWithConditions(Boolean doInsert, Supplier__c supplier, Id NSId, Pol_Com_Condition__c tariffCondition, Integer nbrOfConditions) {
        String rdm = String.valueOf(getRandomNumber());
        List<SObject> contractWithConditions = new List<SObject>();
        String extCode = 'c' + rdm;
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, BusinessUnitContract__c = supplier.BusinessUnitOrigin__c,
                                               Supplier_Nego_Scope__c = NSId, Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                               Duration__c = 12, Contract_Type__c = 'Contract', Ext_id__c = extCode,
                                               Contract_Commercial_BDate__c =  Date.newInstance(year, 1, 1), Contract_Commercial_EDate__c = Date.newInstance(year, 12, 31),
                                               Is_Managed_By_ExternalSource__c = false);
        contractWithConditions.add(contract);
        if (nbrOfConditions > 0) {
            Contract__c contractReference = new Contract__c(Ext_id__c = extCode);
            for (Integer i = 1; i < nbrOfConditions; i++) {
                Decimal percentage = Math.round(Math.random()*i / (i+1));
                Decimal amount = Math.round(Math.random()*9999 * i);
                Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
                                                                          Condition_Type__c = tariffCondition.Id, Disc_BDate__c = contract.Contract_BDate__c,
                                                                          Disc_EDate__c = contract.Contract_EDate__c, Product_Scope__c = contract.Supplier_Nego_Scope__c,
                                                                          BusinessUnitScope__c = contract.BusinessUnitContract__c, Value_per__c = percentage, Value_amt__c = amount,
                                                                          Is_Prenego_Envelop__c = true);
                condition.Contract__r = contractReference;
                contractWithConditions.add(condition);
            }
        }
        if (doInsert) Database.insert(contractWithConditions);
        System.assert(true);
        return contractWithConditions;
    }
    
    /* PRODUCT GROUPS + PURCHASES */
    // List of Supplier PG Mapping creation.
    public static List<PG__c> createPGs(Boolean doInsert, Id supplierId, Id departmentId, Id sectionId, Integer nb) {
        String rdm = String.valueOf(getRandomNumber());
        List<PG__c> PGs = new List<PG__c>();
        for (Integer i = 1; i <= nb; i++) {
            PG__c PG = new PG__c(Name = 'PG' + rdm, Supplier__c = supplierId, Hierarchy__c = departmentId, CurrencyIsoCode = currencyIsoCode);
            PGs.add(PG);
        }
        if (doInsert) Database.insert(PGs);
        System.assert(true);
        return PGs;
    }
    /**
     * @description creates an Element Heirarchy Tree starting from the root
     * Note: the method executes (2 + depth) DMLs
     * @param depth the pepth of the tree
     * @param elementsPerLevel how many elements per level
    */
    public static List<Hierarchy__c> createElementHierarchy(Integer depth, Integer elementsPerLevel) {
        Id rootId = NegoptimHelper.getHierarchyRootId('Product');
        Hierarchy__c root = [SELECT Id, Level__c FROM Hierarchy__c WHERE Id = :rootId];
        Integer currentLevel = 1;
        List<Hierarchy__c> tempList = new List<Hierarchy__c>();
        List<Hierarchy__c> orgaHEList = new List<Hierarchy__c> {root};
            
            for (currentLevel = 1; currentLevel <= depth; currentLevel++) {
                for (Hierarchy__c parent : orgaHEList) {
                    if (parent.Level__c == currentLevel - 1) {
                        for (Integer index = 0; index < elementsPerLevel; index++) {
                            Hierarchy__c element = createHierarchyDepartment(false, parent.Id);
                            element.Level__c = currentLevel;
                            element.SetProductLevel__c = true;
                            element.SetAssortmentClusterLevel__c = true;
                            tempList.add(element);
                        }
                    }
                }
                insert tempList;
                orgaHEList.addAll(tempList);
                tempList.clear();
            }
        return orgaHEList;
    }
    
    // Create assortment BU with default record type = Nego
    public static Assortment__c createAssortment(Boolean doInsert, BusinessUnit__c buSource, BusinessUnit__c buTarget, Hierarchy__c category) {
        String rdm = String.valueOf(getRandomNumber());
        Assortment__c assortment = new Assortment__c(Name = rdm, BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                           Hierarchy__c = category.Id, Status__c = 'Open',
                                                           CurrencyIsoCode = currencyIsoCode, BDate__c = Date.newInstance(year, 1, 1),
                                                           EDate__c = Date.newInstance(year, 12, 31), Year__c = year);
        assortment.RecordTypeId = assortmentRTIds.get('Simulation');
        if (doInsert) {
            insert assortment;
        }
        return assortment;
    }

    
    // Create assortment BU with default record type = Nego
    public static Assortment_BU__c createAssortmentBU(Boolean doInsert, BusinessUnit__c buSource, BusinessUnit__c buTarget, Hierarchy__c category) {
        String rdm = String.valueOf(getRandomNumber());
        Assortment_BU__c assortmentbu = new Assortment_BU__c(Name = rdm, BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                           Hierarchy__c = category.Id, Status__c = 'Open (in bulding process)',
                                                           CurrencyIsoCode = currencyIsoCode, Ass_BDate__c = Date.newInstance(year, 1, 1),
                                                           Ass_EDate__c = Date.newInstance(year, 12, 31), Year__c = year);
        assortmentbu.RecordTypeId = assortmentBURTIds.get('Nego');
        if (doInsert) {
            insert assortmentbu;
        }
        return assortmentbu;
    }
    
    public static AssortmentDetail__c createAssortmentDetail(Boolean doInsert, Id assortmentId, Product2 product, Id clusterId) {
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentId, Product__c = product.Id, Hierarchy__c = product.Hierarchy__c,
                                                                         StartDate__c = Date.today(), RecordDate__c = Date.today(), ProductLifeStatusAss__c = 'New',
                                                                         BusinessUnitCluster__c = clusterId, Status__c = 'InPreparation');
        if (doInsert) Database.insert(assortmentDetail);
        System.assert(true);
        return assortmentDetail;
    }

    public static Assortment_Detail__c createAssortment_Detail(Boolean doInsert, Id assortmentBUId, Product2 product, Id clusterId) {
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBUId, Product__c = product.Id, Hierarchy__c = product.Hierarchy__c,
                                                                         Movement_Date__c = Date.today(), Record_date__c = Date.today(), Client_Status__c = 'New',
                                                                         BusinessUnitAssCluster__c = clusterId, Status__c = 'In preparation');
        if (doInsert) Database.insert(assortmentDetail);
        System.assert(true);
        return assortmentDetail;
    }

    // Assortment Detail creation.
    public static AssortmentDetail__c createAssortmentDetail2(Boolean doInsert, Id assortmentBUId, Product2 product, Id clusterId) {
        AssortmentDetail__c assortmentDetail = new AssortmentDetail__c(Assortment__c = assortmentBUId, Product__c = product.Id, Hierarchy__c = product.Category__c,
                                                                                           StartDate__c = Date.today(), RecordDate__c = Date.today(), ProductLifeStatusAss__c = 'New',
                                                                                           BusinessUnitCluster__c = clusterId, Status__c = 'InPreparation');
        if (doInsert) Database.insert(assortmentDetail);
        System.assert(true);
        return assortmentDetail;
    }
   
    //create Assortment_PriceWaterFall__c
    public static Assortment_PriceWaterFall__c createAssortmentPriceWaterFall(Boolean doInsert, Id assortmentBUId, Id productId, Id promoId, Id promoDetailId) {
        Assortment_PriceWaterFall__c assortmentPriceWaterFall = new Assortment_PriceWaterFall__c(Assortment_BU__c = assortmentBUId, Product__c = productId, Promo_Event__c = promoId, Promo_Event_Detail__c = promoDetailId);
        if (doInsert) insert assortmentPriceWaterFall;
        System.assert(true);
        return assortmentPriceWaterFall;
    }
    
    // Account creation.
    public static Account createAccount(Boolean doInsert, String accountName) {
        Account account = new Account(Name = accountName);
        if (doInsert) insert account;
        System.assert(true);
        return account;
    }
    
    // User creation.
    public static User createUser(Boolean doInsert, String userName, String lastName, String Email, Id ProfileId) {
        User user = new User();
        user.UserName = userName;
        user.LastName = lastName;
        user.Alias = lastName;
        user.Email = 'user@hot.com';
        Organization organization = [SELECT Id, TimeZoneSidKey, LanguageLocaleKey, DefaultLocaleSidKey FROM Organization];
        user.TimeZoneSidKey =  organization.TimeZoneSidKey;
        user.LocaleSidKey = organization.DefaultLocaleSidKey;
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = organization.LanguageLocaleKey;
        user.ProfileId = ProfileId;
        
        if (doInsert) insert user;
        System.assert(true);
        return user;
    }
    
    // contact creation.
    public static Contact createContact(Boolean doInsert, String lastName) {
        Contact contact = new Contact();
        contact.LastName = lastName;
        if (doInsert) insert contact;
        System.assert(true);
        return contact;
    }
    
    // Create PriceList__c
    public static PriceList__c createPriceList(Boolean doInsert, BusinessUnit__c buSource, BusinessUnit__c buTarget) {
        String rdm = String.valueOf(getRandomNumber());
        PriceList__c priceList = new PriceList__c(Name = rdm, CommercialName__c = rdm, BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id,
                                                  Status__c = 'In preperation', StartDateRequested__c = Date.newInstance(year, 1, 1), Year__c = year);
        priceList.RecordTypeId = priceListRTIds.get('InternalPriceList');
        if (doInsert) {
            insert priceList;
        }
        return priceList;
    }
    
    // Create PriceListDetail__c
    public static PriceListDetail__c createPriceListDetail(Boolean doInsert, PriceList__c priceList, Product2 product) {
        String rdm = String.valueOf(getRandomNumber());
        PriceListDetail__c priceListDetail = new PriceListDetail__c(PriceList__c = priceList.Id, Product__c = product.Id,
                                                                    Status__c = 'In preperation', StartDateRequested__c = Date.newInstance(year, 1, 1));
        if (doInsert) {
            insert priceListDetail;
        }
        return priceListDetail;
    }
    
    // Create Tax__c
    public static Tax__c createTax(Boolean doInsert, BusinessUnit__c buSource, BusinessUnit__c buTarget) {
        String rdm = String.valueOf(getRandomNumber());
        Tax__c tax = new Tax__c(Name = rdm, DisplayOrder__c = 1, BusinessUnitSource__c = buSource.Id, BusinessUnitTarget__c = buTarget.Id, Status__c = 'Open',
                                IsGrossPriceTax__c = true, IsDiscountTax__c = true, IsNetPriceTax__c = true, IsInvoiceFooterTax__c = true);
        tax.RecordTypeId = taxRTIds.get('Regular');
        if (doInsert) {
            insert tax;
        }
        return tax;
    }
    
    // create Taxes
    public static Tax__c createTax(Boolean doInsert, BusinessUnit__c buTarget, Decimal rank) {
        String rdm = String.valueOf(getRandomNumber());
        Tax__c tax = new Tax__c(Name = rdm, BusinessUnitTarget__c = buTarget.Id, DisplayOrder__c = rank);
        if (doInsert) {
            insert tax;
        }
        System.assert(true);
        return tax;
    }
    
    //create SupplierTax__c
    public static SupplierTax__c createTaxStatement(Boolean doInsert, PriceListStatement__c priceListStatement, Tax__c tax) {
        SupplierTax__c supNSTaxesStatement = new SupplierTax__c(Tax__c = tax.Id, Supplier__c = priceListStatement.Supplier__c, NegoScope__c = priceListStatement.NegoScope__c,
                                                                /*Account__c = priceListStatement.Account__c,*/ ReferenceYear__c = priceListStatement.ReferenceYear__c,
                                                                IsActive__c = true);
        if (doInsert) {
            insert supNSTaxesStatement;
        }
        System.assert(true);
        return supNSTaxesStatement;
    }
    
    // create PriceListStatement__c
    public static PriceListStatement__c createPriceListStatement(Boolean doInsert, NegoScope__c ns) {
        PriceListStatement__c priceListStatement = new PriceListStatement__c(Name = ns.CodeLong__c + ' - ' + year, Supplier__c = ns.Supplier__c,
                                                                             NegoScope__c = ns.Id, ReferenceYear__c = year);
        if (doInsert) {
            insert priceListStatement;
        }
        System.assert(true);
        return priceListStatement;
    }
    // create PriceListStatementDetail__c
    public static PriceListStatementDetail__c createPriceListStatementDetail(Boolean doInsert, PriceListStatement__c priceListStatement, PG__c pg) {
        PriceListStatementDetail__c detail = new PriceListStatementDetail__c(PriceListStatement__c = priceListStatement.Id , PG__c = pg.Id,
                                                                             Product__c = pg.Product__c);
        if (doInsert) {
            insert detail;
        }
        System.assert(true);
        return detail;
    }
    
    // create AssortmentBU__c
    public static AssortmentBU__c createAssortmentBu(Boolean doInsert, Id recordTypeId, AssortmentDetail__c asd, Id clusterId, Id storeId, String status, Date startDate) {
        AssortmentBU__c assortmentBu = new AssortmentBU__c(RecordTypeId = recordTypeId,
                                                            AssortmentDetail__c = asd.Id,
                                                            Assortment__c = asd.Assortment__c,
                                                            Product__c = asd.Product__c,
                                                            BusinessUnitCluster__c = clusterId,
                                                            BusinessUnitSOS__c = storeId,
                                                            StartDate__c = startDate,
                                                            IsLast__c = true,
                                                            ExtractStatus__c = 'ToExtract',
                                                            ProductLifeStatusAss__c = status);
        if (doInsert) insert assortmentBu;
        System.assert(true);
        return assortmentBu;
    }
}