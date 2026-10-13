/**
 * @author ULiT
 * @description Common class to be used for constant properties and values.
 * Prefixes
 * RT = Record Type
 * PLV = PickList Value
 * FC = Field Count
* */
public class CommonConstants {

    // Constants for the number of SObjectFields that are of the same functionallity
    // Assortment_Detail__c
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_TAX_i = 20;
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_DISC_i_RANK = 9;
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_DISC_i = 9;
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_DISC_i_U = 9;
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_DISC_i_UTYPE = 9;
    public static final Integer FC_ASSORTMENT_DETAIL_STATEMENT_DISC_i_CORR = 9;
    public static final Integer FC_ASSORTMENT_DETAIL_CONTRACT_NEGO_i_NETINDEX = 7;
    public static final Integer FC_ASSORTMENT_DETAIL_CONTRACT_NEGO_DISC_i = 9;

    // ULiT_Assortment_PRICEWATERFALL__c
    //public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i = 20;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_TAX_i = 10;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i_RANK = 19;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i = 19;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i_U = 19;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i_UTYPE = 19;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_STATEMENT_DISC_i_CORR = 19;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_NEW_i_NETINDEX = 7;
    public static final Integer FC_ASSORTMENT_PRICEWATERFALL_NEW_DISC_i = 19;
    
    // Record Types Developer Name
    // Orga_BU__c
    public Static final String RT_ORGA_BU_ASSORTMENT_CLUSTER = 'AssortmentCluster';
    // Assortment_Detail__c
    public Static final String RT_ASSORTMENT_DETAIL_REGULAR = 'Regular';
    public Static final String RT_ASSORTMENT_DETAIL_HIGHER_LEVEL_PACKAGING = 'Higher_Level_Packaging';
    // Product2
    public Static final String RT_PRODUCT2_UNIT_NEED = 'Unit_Need';
    public Static final String RT_PRODUCT2_HIGHER_LEVEL_PACKAGING = 'Higher_Level_Packaging';
    public Static final String RT_PRODUCT2_COMPETITOR = 'Competitor';
    // Picklist Values
    public static final String PLV_ORGA_BU_STATUS_OPEN = 'Open';
    public static final String PLV_ASSORTMENT_BU_STATUS_CLOSED = 'Closed';
    public static final String PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_PROBABLY_DELETED = 'Probably deleted';
    public static final String PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_OPPORTUNITY = 'Opportunity';
    public static final String PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_CPLT = 'Cplt';
    public static final String PLV_ASSORTMENT_DETAIL_STATUS_IN_PREPARATION = 'In preparation';
    public static final String PLV_ASSORTMENT_DETAIL_STATUS_REQUEST_FOR_APPROVAL = 'Request for Approval';
    public static final String PLV_ASSORTMENT_DETAIL_STATUS_VALIDATED = 'Validated';
    public static final String PLV_PRODUCT_ASSORTMENT_INTRODUCTION_HISTORY_LOAD_STATUS_YES = 'Yes';
    //Assortment
    public static final String PLV_ASSORTMENT_STATUS_CLOSE = 'Close';
    
    //AssortmentDetail
    public static final String PLV_ASSORTMENTDETAIL_STATUS_VALIDATE = 'Validate';
    public static final String PLV_ASSORTMENTDETAIL_STATUS_REQUEST_FOR_APPROVAL = 'RequestForApproval';
    public static final String PLV_ASSORTMENTDETAIL_STATUS_IN_PREPARATION = 'InPreparation';
    public static final String PLV_ASSORTMENTDETAIL_CLIENT_STATUS_OPPORTUNITY = 'Opportunity';
    public static final String PLV_ASSORTMENTDETAIL_CLIENT_STATUS_PROBABLY_DELETED = 'Probably deleted';
    public static final String PLV_ASSORTMENTDETAIL_CLIENT_STATUS_CPLT = 'Complement';
    public Static final String RT_ASSORTMENTDETAIL_REGULAR = 'Regular';
    public Static final String RT_ASSORTMENTDETAIL_HIGHER_LEVEL_PACKAGING = 'HigherLevelPackaging';
    //Product2
    public static final String PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_SWITCH = 'Switch';
    public static final String PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_RENO = 'Reno';
    //Default Grid Settings 
    public static final String GRID_SETTINGS_DEFAULT = 'AssortmentMatrixWD';
    //Default Format Origin
    public static final String HMSM = 'HMSM';
    public static final String DRIVE = 'Drive';

    
}