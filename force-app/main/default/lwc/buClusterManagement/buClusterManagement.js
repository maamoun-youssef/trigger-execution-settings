import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";

import BU__OBJECT from '@salesforce/schema/BusinessUnit__c';
import HE__OBJECT from '@salesforce/schema/Hierarchy__c';

import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Back_To_Home_Page from "@salesforce/label/c.LBL_Back_To_Home_Page";
import LBL_No_Record_To_Display from "@salesforce/label/c.LBL_No_Record_To_Display";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_BU_Cluster_mgt from "@salesforce/label/c.LBL_BU_Cluster_mgt";
import LBL_SOS_Number from "@salesforce/label/c.LBL_SOS_Number";
import LBL_WD from "@salesforce/label/c.LBL_WD";
import LBL_WD_InnoRise from "@salesforce/label/c.LBL_WD_InnoRise";
import LBL_WD_SwitchRise from "@salesforce/label/c.LBL_WD_SwitchRise";
import LBL_WD_StopRise from "@salesforce/label/c.LBL_WD_StopRise";
import LBL_Country from "@salesforce/label/c.LBL_Country";
import LBL_Banner from "@salesforce/label/c.LBL_Banner";
import LBL_All from "@salesforce/label/c.LBL_All";

import loadCountries from '@salesforce/apex/BUClusterManagementCtrl.loadCountries';
import loadData from '@salesforce/apex/BUClusterManagementCtrl.loadData';
import saveClusters from '@salesforce/apex/BUClusterManagementCtrl.saveClusters';
import loadClusters from '@salesforce/apex/BUClusterManagementCtrl.loadClusters';
// Hierarchy Fields
import Code__c from '@salesforce/schema/Hierarchy__c.Code__c';
import Path__c from '@salesforce/schema/Hierarchy__c.Path__c';
// BU Fields
import CodeBU__c from "@salesforce/schema/BusinessUnit__c.Code__c";
import Name from "@salesforce/schema/BusinessUnit__c.Name";
import AssortmentStrat__c from "@salesforce/schema/BusinessUnit__c.AssortmentStrat__c";
import Hierarchy__c from "@salesforce/schema/BusinessUnit__c.Hierarchy__c";
import ClientCategory__c from "@salesforce/schema/BusinessUnit__c.ClientCategory__c";
import Status__c from "@salesforce/schema/BusinessUnit__c.Status__c";
import OpeningDate__c from "@salesforce/schema/BusinessUnit__c.OpeningDate__c";
import ClosingDate__c from "@salesforce/schema/BusinessUnit__c.ClosingDate__c";
import BusinessUnitCountryOrigin__c from '@salesforce/schema/BusinessUnit__c.BusinessUnitCountryOrigin__c';
import SetBULinkMaster__c from '@salesforce/schema/BusinessUnit__c.SetBULinkMaster__c';
import SiteOfSalesNumberP2__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP2__c";
import SiteOfSalesNumberP1__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP1__c";
import SiteOfSalesNumber__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumber__c";
import SiteOfSalesNumberN1__c from "@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberN1__c";
import WeightedDistributionManualP2__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionManualP2__c";
import WeightedDistributionManualP1__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionManualP1__c";
import WeightedDistributionManual__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionManual__c";
import WeightedDistributionManualN1__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionManualN1__c";
import WeightedDistributionInnovRiseM1__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM1__c";
import WeightedDistributionInnovRiseM2__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM2__c";
import WeightedDistributionInnovRiseM3__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM3__c";
import WeightedDistributionInnovRiseM4__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM4__c";
import WeightedDistributionInnovRiseM5__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM5__c";
import WeightedDistributionInnovRiseM6__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM6__c";
import WeightedDistributionInnovRiseM7__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM7__c";
import WeightedDistributionInnovRiseM8__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM8__c";
import WeightedDistributionInnovRiseM9__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM9__c";
import WeightedDistributionInnovRiseM10__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM10__c";
import WeightedDistributionInnovRiseM11__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM11__c";
import WeightedDistributionInnovRiseM12__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionInnovRiseM12__c";
import WeightedDistributionSwitchRiseM1__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM1__c";
import WeightedDistributionSwitchRiseM2__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM2__c";
import WeightedDistributionSwitchRiseM3__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM3__c";
import WeightedDistributionSwitchRiseM4__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM4__c";
import WeightedDistributionSwitchRiseM5__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM5__c";
import WeightedDistributionSwitchRiseM6__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM6__c";
import WeightedDistributionSwitchRiseM7__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM7__c";
import WeightedDistributionSwitchRiseM8__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM8__c";
import WeightedDistributionSwitchRiseM9__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM9__c";
import WeightedDistributionSwitchRiseM10__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM10__c";
import WeightedDistributionSwitchRiseM11__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM11__c";
import WeightedDistributionSwitchRiseM12__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionSwitchRiseM12__c";
import WeightedDistributionStopRiseM1__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM1__c";
import WeightedDistributionStopRiseM2__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM2__c";
import WeightedDistributionStopRiseM3__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM3__c";
import WeightedDistributionStopRiseM4__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM4__c";
import WeightedDistributionStopRiseM5__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM5__c";
import WeightedDistributionStopRiseM6__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM6__c";
import WeightedDistributionStopRiseM7__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM7__c";
import WeightedDistributionStopRiseM8__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM8__c";
import WeightedDistributionStopRiseM9__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM9__c";
import WeightedDistributionStopRiseM10__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM10__c";
import WeightedDistributionStopRiseM11__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM11__c";
import WeightedDistributionStopRiseM12__c from "@salesforce/schema/BusinessUnit__c.WeightedDistributionStopRiseM12__c";

import negOptimGlobalCSS from '@salesforce/resourceUrl/negOptimGlobalCSS';
import { showNotification } from 'c/appHelper';

export default class BuClusterManagement extends LightningElement {

    @api recordId;
    @track tableLoading = true;
    @track isEditModeActive = false;
    @track isAddClusterActive = false;
    @track isEmptyList = false;
    @track labels = {
        LBL_Filter,
        LBL_Cancel,
        LBL_Search,
        LBL_No_Item_To_Display,
        LBL_Back_To_Home_Page,
        LBL_No_Record_To_Display,
        MSG_Successfully_Saved,
        LBL_Success,
        LBL_Save,
        LBL_Reset,
        LBL_BU_Cluster_mgt,
        LBL_SOS_Number,
        LBL_WD,
        LBL_WD_InnoRise,
        LBL_WD_SwitchRise,
        LBL_WD_StopRise,
        LBL_Country,
        LBL_Banner,
        Hierarchy__c: '',
        ClientCategory__c: '',
        AssortmentStrat__c: '',
    }
    resultsData = [];
    buData = [];
    BuFields = [];
    assortmentClusterRT = '';
    BuWFields = [];
    API_NAMES = {
        BusinessUnit__c: {
            objectApiName: BU__OBJECT.objectApiName,
            objectLabel: '',
            Code__c: CodeBU__c.fieldApiName,
            AssortmentStrat__c: AssortmentStrat__c.fieldApiName,
            Hierarchy__c: Hierarchy__c.fieldApiName,
            ClientCategory__c: ClientCategory__c.fieldApiName,
            Status__c: Status__c.fieldApiName,
            OpeningDate__c: OpeningDate__c.fieldApiName,
            ClosingDate__c: ClosingDate__c.fieldApiName,
            SiteOfSalesNumberP2__c: SiteOfSalesNumberP2__c.fieldApiName,
            SiteOfSalesNumberP1__c: SiteOfSalesNumberP1__c.fieldApiName,
            SiteOfSalesNumber__c: SiteOfSalesNumber__c.fieldApiName,
            SiteOfSalesNumberN1__c: SiteOfSalesNumberN1__c.fieldApiName,
            WeightedDistributionManualP2__c: WeightedDistributionManualP2__c.fieldApiName,
            WeightedDistributionManualP1__c: WeightedDistributionManualP1__c.fieldApiName,
            WeightedDistributionManual__c: WeightedDistributionManual__c.fieldApiName,
            WeightedDistributionManualN1__c: WeightedDistributionManualN1__c.fieldApiName,
            WeightedDistributionInnovRiseM1__c: WeightedDistributionInnovRiseM1__c.fieldApiName,
            WeightedDistributionInnovRiseM2__c: WeightedDistributionInnovRiseM2__c.fieldApiName,
            WeightedDistributionInnovRiseM3__c: WeightedDistributionInnovRiseM3__c.fieldApiName,
            WeightedDistributionInnovRiseM4__c: WeightedDistributionInnovRiseM4__c.fieldApiName,
            WeightedDistributionInnovRiseM5__c: WeightedDistributionInnovRiseM5__c.fieldApiName,
            WeightedDistributionInnovRiseM6__c: WeightedDistributionInnovRiseM6__c.fieldApiName,
            WeightedDistributionInnovRiseM7__c: WeightedDistributionInnovRiseM7__c.fieldApiName,
            WeightedDistributionInnovRiseM8__c: WeightedDistributionInnovRiseM8__c.fieldApiName,
            WeightedDistributionInnovRiseM9__c: WeightedDistributionInnovRiseM9__c.fieldApiName,
            WeightedDistributionInnovRiseM10__c: WeightedDistributionInnovRiseM10__c.fieldApiName,
            WeightedDistributionInnovRiseM11__c: WeightedDistributionInnovRiseM11__c.fieldApiName,
            WeightedDistributionInnovRiseM12__c: WeightedDistributionInnovRiseM12__c.fieldApiName,
            WeightedDistributionSwitchRiseM1__c: WeightedDistributionSwitchRiseM1__c.fieldApiName,
            WeightedDistributionSwitchRiseM2__c: WeightedDistributionSwitchRiseM2__c.fieldApiName,
            WeightedDistributionSwitchRiseM3__c: WeightedDistributionSwitchRiseM3__c.fieldApiName,
            WeightedDistributionSwitchRiseM4__c: WeightedDistributionSwitchRiseM4__c.fieldApiName,
            WeightedDistributionSwitchRiseM5__c: WeightedDistributionSwitchRiseM5__c.fieldApiName,
            WeightedDistributionSwitchRiseM6__c: WeightedDistributionSwitchRiseM6__c.fieldApiName,
            WeightedDistributionSwitchRiseM7__c: WeightedDistributionSwitchRiseM7__c.fieldApiName,
            WeightedDistributionSwitchRiseM8__c: WeightedDistributionSwitchRiseM8__c.fieldApiName,
            WeightedDistributionSwitchRiseM9__c: WeightedDistributionSwitchRiseM9__c.fieldApiName,
            WeightedDistributionSwitchRiseM10__c: WeightedDistributionSwitchRiseM10__c.fieldApiName,
            WeightedDistributionSwitchRiseM11__c: WeightedDistributionSwitchRiseM11__c.fieldApiName,
            WeightedDistributionSwitchRiseM12__c: WeightedDistributionSwitchRiseM12__c.fieldApiName,
            WeightedDistributionStopRiseM1__c: WeightedDistributionStopRiseM1__c.fieldApiName,
            WeightedDistributionStopRiseM2__c: WeightedDistributionStopRiseM2__c.fieldApiName,
            WeightedDistributionStopRiseM3__c: WeightedDistributionStopRiseM3__c.fieldApiName,
            WeightedDistributionStopRiseM4__c: WeightedDistributionStopRiseM4__c.fieldApiName,
            WeightedDistributionStopRiseM5__c: WeightedDistributionStopRiseM5__c.fieldApiName,
            WeightedDistributionStopRiseM6__c: WeightedDistributionStopRiseM6__c.fieldApiName,
            WeightedDistributionStopRiseM7__c: WeightedDistributionStopRiseM7__c.fieldApiName,
            WeightedDistributionStopRiseM8__c: WeightedDistributionStopRiseM8__c.fieldApiName,
            WeightedDistributionStopRiseM9__c: WeightedDistributionStopRiseM9__c.fieldApiName,
            WeightedDistributionStopRiseM10__c: WeightedDistributionStopRiseM10__c.fieldApiName,
            WeightedDistributionStopRiseM11__c: WeightedDistributionStopRiseM11__c.fieldApiName,
            WeightedDistributionStopRiseM12__c: WeightedDistributionStopRiseM12__c.fieldApiName,
            SetBULinkMaster__c: SetBULinkMaster__c.fieldApiName,
            BusinessUnitCountryOrigin__c: BusinessUnitCountryOrigin__c.fieldApiName,
            BusinessUnitCountryOrigin__r: BusinessUnitCountryOrigin__c.fieldApiName.replace(/__c$/, '__r'),
        },
        Hierarchy__c: {
            objectApiName: HE__OBJECT.objectApiName,
            Code__c: Code__c.fieldApiName,
            Path__c: Path__c.fieldApiName,
        },
    }
    @track countryParam = '';
    @track bannerParam = '';
    @track categoryParam = '';
    @track clientCategParam = '';
    @track stratParam = '';
    // BuCountryFilter = [' RecordType.DeveloperName = \'Country\'']
    BuCountryFilter = {
        criteria: [
            {
                fieldPath: 'RecordType.DeveloperName',
                operator: 'eq',
                value: 'Country',
            }
        ],
        filterLogic: '1',
    };
    // BuBannerFilter = [' RecordType.DeveloperName = \'Banner\'']
    @track BuBannerFilter = {
        criteria: [
            {
                fieldPath: 'RecordType.DeveloperName',
                operator: 'eq',
                value: 'Banner',
            }
        ],
        filterLogic: '1',
    };
    buDisplayInfo = {
        primaryField: 'Name',
        additionalFields: [CodeBU__c.fieldApiName],
    };
    buMatchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: CodeBU__c.fieldApiName }],
    };
    heDisplayInfo = {
        primaryField: 'Name',
        additionalFields: [Code__c.fieldApiName],
    };
    heMatchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: Code__c.fieldApiName }],
    };
    // BuStratFilter = []
    // searchBUfields = ['Name'];
    searchCategoryFields = [
        'Name',
        this.API_NAMES.Hierarchy__c.Code__c,
        this.API_NAMES.Hierarchy__c.Path__c,
    ];
    Events = {
        selectCountry: 'selectcountry',
        selectBanner: 'selectbanner',
        selectCategory: 'selectcategory'
    }

    get isDisplaySaveBtn() {
        return this.isEditModeActive || this.isAddClusterActive
    }

    get isNotBannerPage() {
        return this.resultsData.bannerId == '' || this.resultsData.bannerId == null;
    }

    newInputFields = [
        this.API_NAMES.BusinessUnit__c.Code__c,
        'Name',
        this.API_NAMES.BusinessUnit__c.AssortmentStrat__c,
        this.API_NAMES.BusinessUnit__c.Hierarchy__c,
        this.API_NAMES.BusinessUnit__c.ClientCategory__c,
        this.API_NAMES.BusinessUnit__c.Status__c,
        this.API_NAMES.BusinessUnit__c.OpeningDate__c,
        this.API_NAMES.BusinessUnit__c.ClosingDate__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP1__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumber__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManual__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c,
    ]
    bannerFields = [
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP1__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumber__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManual__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c,
    ]
    inputFields = [
        this.API_NAMES.BusinessUnit__c.ClientCategory__c,
        this.API_NAMES.BusinessUnit__c.Status__c,
        this.API_NAMES.BusinessUnit__c.ClosingDate__c,
        this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionManualN1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM12__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM2__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM3__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM4__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM5__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM6__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM7__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM8__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM9__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM10__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM11__c,
        this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c,
    ];
    @wire(getObjectInfo, { objectApiName: BU__OBJECT }) objectInfoCP({ error, data }) {
        if (data) {
            this.BuFields = data.fields;
            this.labels.Hierarchy__c = data.fields[this.API_NAMES.BusinessUnit__c.Hierarchy__c].label;
            this.labels.ClientCategory__c = data.fields[this.API_NAMES.BusinessUnit__c.ClientCategory__c].label;
            this.labels.AssortmentStrat__c = data.fields[this.API_NAMES.BusinessUnit__c.AssortmentStrat__c].label;
            this.API_NAMES.BusinessUnit__c.objectLabel = data.label;
            this.loadData(this);
        } else if (error) {
            showNotification(this, 'ERROR', error, 'error');
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: BU__OBJECT,
        recordTypeId: "012000000000000AAA",
    })
    propertyOrFunction;

    connectedCallback() {
        Promise.all([
            loadStyle(this, negOptimGlobalCSS),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style >> ' + error)
        });
        this.changeHeight();
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if (currentPageReference.state.hasOwnProperty('c__recordId')) {
            this.recordId = this.currentPageReference.state.c__recordId;
        }
    }
    newLoad = true;
    loadAllData = false;
    eventExecuted = false;
    renderedCallback() {
        this.setnumberOfFixedColumns();
        if (this.newLoad && this.template.querySelector('.main-header') && this.template.querySelector('.main-table')) {
            this.changeHeight();
            this.newLoad = false;
        }
        if (!this.loadAllData && this.template.querySelector('.table-div')) {
            let myDiv = this.template.querySelector('.table-div');
            setTimeout(() => {
                myDiv.addEventListener("scroll", () => {
                    if (!this.eventExecuted && this.totalSize != this.totalRecordsLoadedNB && (myDiv.scrollTop + myDiv.clientHeight >= myDiv.scrollHeight - 100)) {
                        this.eventExecuted = true;
                        this.loadData(this);
                    }
                }, { passive: true });
            }, 2000);
        }
        window.addEventListener('resize', this.changeHeight);
    }
    // disconnectedCallback() {
    //     // Remove event listener when the component is removed from the DOM
    //     window.removeEventListener('scroll', this.handleScroll);
    // }

    pageNumber = 0;
    totalRecordsLoadedNB = 0;
    totalSize = 0;
    loadData(self) {
        self = self || this;
        self.pageNumber++;
        console.log('self.pageNumber: ' + self.pageNumber)
        console.log('this.clientCategParam: ' + this.clientCategParam)
        let filterWrapper = {
            countryParam: this.countryParam,
            bannerParam: this.bannerParam,
            categoryParam: this.categoryParam,
            clientCategParam: this.clientCategParam,
            stratParam: this.stratParam
        }
        console.log('filterWrapper: ' + JSON.stringify(filterWrapper))
        loadCountries({
            recordId: this.recordId,
            pageNumber: parseInt(self.pageNumber),
            filterWrapper: JSON.stringify(filterWrapper)
        }).then((result) => {
            self.resultsData = JSON.parse(result);
            if (self.resultsData.countryList.length == 0) {
                self.isEmptyList = true;
                this.tableLoading = false;
            } else {
                self.totalRecordsLoadedNB += self.resultsData.countryList.length;
                self.totalSize = self.resultsData.totalNumbOfRecords;
                if (this.totalSize == this.totalRecordsLoadedNB) {
                    this.loadAllData = true;
                }
                self.assortmentClusterRT = self.resultsData.assortmentClusterRT;
                console.log('2pageNumber: ' + self.pageNumber)
                console.log('2filterWrapper: ' + filterWrapper)
                loadData({
                    bannerId: self.resultsData.bannerId,
                    countryIds: self.resultsData.countryList.map(country => country.Id),
                    filterWrapper: JSON.stringify(filterWrapper),
                }).then((result) => {
                    let records = JSON.parse(result);
                    self.buData = records;
                    self.initialData(records);
                    if (self.resultsData.bannerId) {
                        const bannerW = this.dataArray[0] && this.dataArray[0].bannerWrapperList[0];
                        if (bannerW) {
                            this.loadClusters(bannerW, filterWrapper);
                        } else {
                            this.isEmptyList = true;
                            this.tableLoading = false;
                        }
                    }
                    this.tableLoading = false;
                }).catch(error => {
                    console.log('error loadData');
                    console.error(error.message);
                    self.isEmptyList = true;
                    this.tableLoading = false;
                    showNotification(this, 'Error', error, 'error', 'sticky');
                });
            }
        }).catch(error => {
            console.log('error loadCountries');
            console.error(error.message);
            self.isEmptyList = true;
            this.tableLoading = false;
        });
    }
    isLastLoad = false;


    countryIdNameMap = new Map();
    bannerIdNameMap = new Map();
    @track loadmore = false;
    @track firstHeader = [];
    @track yearsValueHeader = ['N-2', 'N-1', 'N', 'N+1'];
    @track monthsValueHeader = ['M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8', 'M9', 'M10', 'M11', 'M12'];
    @track stratOptions = [];
    @track selectedStrat = '';
    initialData(buData) {
        let stratOptionsTmp = [{ label: LBL_All, value: '' }];
        let countryMap = new Map();
        let bannerMap = new Map();
        for (let Bu of buData) {
            if (Bu.RecordType.DeveloperName == 'Banner' && Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__r].RecordType.DeveloperName == 'Country') {
                if (!countryMap.has(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c])) {
                    countryMap.set(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c], new Set());
                    this.countryIdNameMap.set(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c], Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__r].Name);
                }
                countryMap.get(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]).add(Bu);
            }
            if (Bu.RecordType.DeveloperName == 'AssortmentCluster' && Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__r].RecordType.DeveloperName == 'Banner') {
                if (!bannerMap.has(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c])) {
                    bannerMap.set(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c], new Array());
                }
                bannerMap.get(Bu[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c]).push(Bu);
            }
            if (Bu.RecordType.DeveloperName == 'Banner') {
                this.bannerIdNameMap.set(Bu.Id, Bu.Name);
            }
        }
        if (this.BuWFields.length == 0) {
            for (let field of this.resultsData.BuFields) {
                let fieldW = {
                    fieldApiName: field,
                    fieldLabel: this.BuFields[field].label,
                    fieldType: this.BuFields[field].dataType.toUpperCase(),
                    scale: this.BuFields[field].scale,
                    isText: false,
                    isDate: false,
                    isPicklist: false,
                    isReference: false,
                    fieldOptions: [],
                    bgColor: 'ffffff',
                    fieldStyle: '',
                    fieldClass: 'main-th',
                    step: '',
                }
                if (fieldW.scale) {
                    let step = '.';
                    for (let i = 0; i < field.scale; i++) {
                        if (i == field.scale - 1) {
                            step += '1';
                            break;
                        }
                        step += '0';
                    }
                    fieldW.step = step;
                }

                switch (this.BuFields[field].dataType) {
                    case 'String':
                        fieldW.isText = true;
                        break;
                    case 'Date':
                        fieldW.isDate = true;
                        break;
                    case 'Picklist':
                        fieldW.isPicklist = true;
                        this.propertyOrFunction.data.picklistFieldValues[field].values.forEach((item) => {
                            fieldW.fieldOptions.push({ label: item.label, value: item.value, isSelected: false });
                        });
                        break;
                    case 'Reference':
                        fieldW.isReference = true;
                        break;
                }
                if (fieldW.fieldApiName == this.API_NAMES.BusinessUnit__c.AssortmentStrat__c) {
                    for (let option of fieldW.fieldOptions) {
                        stratOptionsTmp.push({ label: option.label, value: option.value });
                    }
                }
                if (field.includes('SiteOfSales')) {
                    fieldW.bgColor = 'fbe2d5';
                    fieldW.fieldClass = 'number-td';
                } else if (field.includes('WeightedDistributionManual')) {
                    fieldW.bgColor = 'c1f0c8';
                    fieldW.fieldClass = 'number-td';
                } else if (field.includes('WeightedDistributionSwitchRise')) {
                    fieldW.bgColor = 'faecf9';
                    fieldW.fieldClass = 'number-td';
                } else if (field.includes('WeightedDistributionInnovRise')) {
                    fieldW.bgColor = 'faecf9';
                    fieldW.fieldClass = 'number-td';
                } else if (field.includes('WeightedDistributionStopRise')) {
                    fieldW.bgColor = 'faecf9';
                    fieldW.fieldClass = 'number-td';
                } else {
                    this.firstHeader.push(fieldW);
                }

                fieldW.fieldStyle += 'background-color: #' + fieldW.bgColor + ';';
                this.BuWFields.push(fieldW);
            }
            this.stratOptions = [...stratOptionsTmp];
        }
        // countryMap.forEach((value2, key2) => {
        //     console.log('hello isnide map countryyy')
        //     console.log(key2 + '>>>>>>>>>>>>>>>.' + JSON.stringify(value2));
        // });
        this.buildData(countryMap, bannerMap);

    }

    @track dataArray = [];
    buildData(countryMap, bannerMap) {
        let self = this;
        // let dataArrayLoaded = [];
        for (let country of countryMap.keys()) {
            let countryW = {
                Name: this.countryIdNameMap.get(country),
                Id: country,
                link: '/' + country,
                isDisplayedBanner: true,
                isShowCountry: true,
                bannerWrapperList: [],
            }
            if (countryMap.has(country)) {
                for (let banner of countryMap.get(country)) {
                    if (this.stratParam != '' || this.categoryParam != '' || this.clientCategParam != '') {
                        let BUBusinessUnitCountryOrigin = this.resultsData.prefix ? `${this.resultsData.prefix}BUBusinessUnitCountryOrigin__r` : 'BUBusinessUnitCountryOrigin__r';
                        if (banner[BUBusinessUnitCountryOrigin] == null && !this.resultsData.bannerId) {
                            continue;
                        }
                    }
                    let bannerW = {
                        Name: this.bannerIdNameMap.has(banner.Id) ? this.bannerIdNameMap.get(banner.Id) : '',
                        Id: banner.Id,
                        link: '/' + banner.Id,
                        isDisplayedBU: false,
                        isShowBanner: true,
                        clustersLoaded: false,
                        BuWrapperList: [],
                        newBuWrapperList: [],
                        values: [],
                    }
                    for (let field of this.BuWFields) {
                        if (this.bannerFields.includes(field.fieldApiName)) {
                            let fieldObj = {
                                id: banner.Id,
                                fieldApiName: field.fieldApiName,
                                fieldLabel: field.fieldLabel,
                                fieldValue: banner[field.fieldApiName] ? banner[field.fieldApiName] : '',
                                fieldOutputValue: banner[field.fieldApiName] ? banner[field.fieldApiName] : '',
                                fieldType: field.fieldType,
                                isText: field.isText,
                                isDate: field.isDate,
                                isNumber: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                                isPicklist: field.isPicklist,
                                isReference: field.isReference,
                                fieldOptions: JSON.parse(JSON.stringify(field.fieldOptions)),
                                isName: false,
                                link: '',
                                scale: field.scale,
                                step: field.step,
                                style: '',
                                fieldStyle: '',
                                styleClass: field.fieldClass,
                                isInput: self.inputFields.includes(field.fieldApiName),
                            }
                            fieldObj.fieldStyle += fieldObj.isNumber ? 'text-align:right;' : '';
                            if (fieldObj.isReference) {
                                fieldObj.fieldValue = banner[field.fieldApiName.replace("__c", "__r")]?.Name;
                            }
                            if (field.fieldApiName == 'Name') {
                                fieldObj.isName = true;
                                fieldObj.isText = false;
                                fieldObj.link = '/' + banner.Id;
                            }
                            if (fieldObj.isPicklist) {
                                if (fieldObj.fieldValue != '') {
                                    fieldObj.fieldOutputValue = fieldObj.fieldOptions.filter((op) => op.value == fieldObj.fieldValue)[0].label;
                                    fieldObj.fieldOptions.forEach(item => {
                                        item.isSelected = item.value == fieldObj.fieldValue;
                                    })
                                }
                            }
                            if (fieldObj.isDate && fieldObj.fieldOutputValue) {
                                const locale = this.resultsData.local;
                                const parts = fieldObj.fieldOutputValue?.split('-');
                                fieldObj.fieldOutputValue = parts && parts.length != 0 ? new Date(parts[0], parts[1] - 1, parts[2]).toLocaleDateString(locale.replace('_', '-')) : '';
                            }
                            if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c
                                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP2__c
                                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c
                                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c
                                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c) {
                                fieldObj.styleClass += ' borderSeparatorLeft';
                            } else if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c) {
                                fieldObj.styleClass += ' borderSeparatorRight';
                            } else if (field.fieldApiName == 'Name') {
                                fieldObj.styleClass += ' name-link';
                            }
                            fieldObj.styleClass += ' head-td-Style';
                            bannerW.values.push(fieldObj);
                        }
                    }
                    if (bannerMap.has(banner.Id)) {
                        bannerW.BuWrapperList = this.buildClusterWrappers(bannerMap.get(banner.Id));
                        bannerW.clustersLoaded = true;
                    }
                    countryW.bannerWrapperList.push(bannerW);
                }
            }
            // dataArrayLoaded.push(countryW);
            if (countryW.bannerWrapperList.length != 0) {
                this.dataArray.push(countryW);
            }
        }
        //this.dataArray = [...dataArrayLoaded];
        console.log('this.dataArray >>>> ' + JSON.stringify(this.dataArray))
        this.tableLoading = false;

        if (self.totalRecordsLoadedNB != self.totalSize) {
            this.loadmore = true;
            setTimeout(() => {
                let div = this.template.querySelector('.table-div');
                if (div && div.scrollHeight <= div.clientHeight) {
                    this.loadData(this);
                }
            }, 150);
        } else {
            this.loadmore = false;
        }
        this.eventExecuted = false;
    }

    buildClusterWrappers(clusterList) {
        let self = this;
        let wrappers = [];
        for (let Bu of clusterList) {
            let BuW = {
                values: []
            };
            for (let field of this.BuWFields) {
                let fieldObj = {
                    id: Bu.Id,
                    fieldApiName: field.fieldApiName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: Bu[field.fieldApiName] ? Bu[field.fieldApiName] : '',
                    fieldOutputValue: Bu[field.fieldApiName] ? Bu[field.fieldApiName] : '',
                    fieldType: field.fieldType,
                    isText: field.isText,
                    isDate: field.isDate,
                    isNumber: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                    isPicklist: field.isPicklist,
                    isReference: field.isReference,
                    fieldOptions: JSON.parse(JSON.stringify(field.fieldOptions)),
                    isName: false,
                    link: '',
                    scale: field.scale,
                    step: field.step,
                    style: '',
                    isInput: self.inputFields.includes(field.fieldApiName),
                    fieldStyle: field.fieldStyle,
                    styleClass: field.fieldClass,
                };
                fieldObj.fieldStyle += fieldObj.isNumber ? 'text-align:right;' : '';
                if (fieldObj.isReference) {
                    fieldObj.fieldValue = Bu[field.fieldApiName.replace("__c", "__r")]?.Name;
                }
                if (field.fieldApiName == 'Name') {
                    fieldObj.isName = true;
                    fieldObj.isText = false;
                    fieldObj.link = '/' + Bu.Id;
                }
                if (fieldObj.isPicklist) {
                    if (fieldObj.fieldValue != '') {
                        fieldObj.fieldOutputValue = fieldObj.fieldOptions.filter((op) => op.value == fieldObj.fieldValue)[0].label;
                        fieldObj.fieldOptions.forEach(item => {
                            item.isSelected = item.value == fieldObj.fieldValue;
                        });
                    }
                }
                if (fieldObj.isDate && fieldObj.fieldOutputValue) {
                    const locale = this.resultsData.local;
                    const parts = fieldObj.fieldOutputValue?.split('-');
                    fieldObj.fieldOutputValue = parts && parts.length != 0
                        ? new Date(parts[0], parts[1] - 1, parts[2]).toLocaleDateString(locale.replace('_', '-'))
                        : '';
                }
                if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c
                    || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP2__c
                    || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c
                    || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c
                    || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c) {
                    fieldObj.styleClass += ' borderSeparatorLeft';
                } else if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c) {
                    fieldObj.styleClass += ' borderSeparatorRight';
                } else if (field.fieldApiName == 'Name') {
                    fieldObj.styleClass += ' name-link';
                }
                BuW.values.push(fieldObj);
            }
            wrappers.push(BuW);
        }
        return wrappers;
    }

    get bannerColspan() {
        return this.firstHeader.length - 3;
    }

    handleCollapseBanner(event) {
        this.tableLoading = true;
        let countryIndex = event.target.dataset.countryIndex;
        this.dataArray[countryIndex].isDisplayedBanner = !this.dataArray[countryIndex].isDisplayedBanner;
        this.tableLoading = false;
    }

    handleCollapseBU(event) {
        let countryIndex = event.target.dataset.countryIndex;
        let bannerIndex = event.target.dataset.bannerIndex;
        let bannerW = this.dataArray[countryIndex].bannerWrapperList[bannerIndex];
        if (bannerW.isDisplayedBU) {
            bannerW.isDisplayedBU = false;
            this.dataArray = [...this.dataArray];
            return;
        } else {
            if (bannerW.clustersLoaded) {
                bannerW.isDisplayedBU = true;
                this.dataArray = [...this.dataArray];
            } else {
                this.tableLoading = true;
                let filterWrapper = {
                    countryParam: this.countryParam,
                    bannerParam: this.bannerParam,
                    categoryParam: this.categoryParam,
                    clientCategParam: this.clientCategParam,
                    stratParam: this.stratParam,
                };
                this.loadClusters(bannerW, filterWrapper);
            }
        }
    }

    loadClusters(bannerW, filterWrapper) {
        loadClusters({
            bannerId: bannerW.Id,
            filterWrapper: JSON.stringify(filterWrapper),
        }).then(result => {
            bannerW.BuWrapperList = this.buildClusterWrappers(JSON.parse(result));
            bannerW.clustersLoaded = true;
            bannerW.isDisplayedBU = true;
            this.dataArray = [...this.dataArray];
            this.tableLoading = false;
        }).catch(error => {
            this.tableLoading = false;
            console.error(error);
            showNotification(this, 'Error', 'Failed to load clusters', 'error', 'sticky');
        });
    }

    @track newClusters = [];
    addNewCluster(event) {
        let countryIndex = event.target.dataset.countryIndex;
        let bannerIndex = event.target.dataset.bannerIndex;
        this.isAddClusterActive = true;
        this.tableLoading = true;
        let defaultValues = {};
        let cluster = {
            values: []
        }
        for (let field of this.BuWFields) {
            let fieldObj = {
                fieldApiName: field.fieldApiName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                fieldType: field.fieldType,
                isText: field.isText,
                isDate: field.isDate,
                isPicklist: field.isPicklist,
                isReference: field.isReference,
                fieldOptions: JSON.parse(JSON.stringify(field.fieldOptions)),
                isInput: this.newInputFields.includes(field.fieldApiName),
                isNumber: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY',
                scale: field.scale,
                step: field.step,
                style: '',
                fieldStyle: field.fieldStyle,
                styleClass: field.fieldClass,
            }
            if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.SiteOfSalesNumberP2__c
                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionManualP2__c
                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionInnovRiseM1__c
                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionSwitchRiseM1__c
                || field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM1__c) {
                fieldObj.styleClass += ' borderSeparatorLeft';
            } else if (field.fieldApiName == this.API_NAMES.BusinessUnit__c.WeightedDistributionStopRiseM12__c) {
                fieldObj.styleClass += ' borderSeparatorRight';
            }
            if (field.isPicklist && field.fieldOptions.length != 0) {
                defaultValues[field.fieldApiName] = field.fieldOptions[0].value;
                fieldObj.fieldValue = field.fieldOptions[0].value;
            }
            cluster.values.push(fieldObj);
        }
        this.dataArray[countryIndex].bannerWrapperList[bannerIndex].newBuWrapperList.push(cluster);
        let clusterIndex = this.dataArray[countryIndex].bannerWrapperList[bannerIndex].newBuWrapperList.length - 1 + "";
        if (defaultValues != {}) {

            if (!this.newBuMap.has(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id)) {
                this.newBuMap.set(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id, new Map());
            }
            let obj;
            if (!this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).has(clusterIndex)) {
                obj = {
                    attributes: {
                        type: BU__OBJECT.objectApiName,
                    },
                    RecordTypeId: this.assortmentClusterRT
                };
                obj[this.API_NAMES.BusinessUnit__c.SetBULinkMaster__c] = true;
                this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).set(clusterIndex, obj);
            }
            obj = this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).get(clusterIndex)
            for (let field of Object.keys(defaultValues)) {
                obj[field] = defaultValues[field];
            }
            this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).set(clusterIndex, obj)
        }
        // console.log('this.dataArray >>>>> ' + JSON.stringify(this.dataArray));
        setInterval(() => {
            this.tableLoading = false;
        }, 2000);
    }

    toUpdateClusters = [];
    changedIds = [];
    handleEditCluster(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let isCategory = event.target.dataset.isCategory;
        let value = isCategory ? event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : event.target.value : event.target.value;
        let obj;
        if (this.changedIds.includes(id)) {
            obj = this.toUpdateClusters.filter(item => item.Id == id)[0];
        } else {
            obj = {
                attributes: {
                    type: BU__OBJECT.objectApiName,
                },
                Id: id
            };
        }
        obj[field] = value;
        if (!this.changedIds.includes(id)) {
            this.toUpdateClusters.push(obj);
            this.changedIds.push(id);
        }
    }
    handleEditBanner(event) {
        let id = event.target.dataset.id;
        let field = event.target.dataset.field;
        let value = event.target.value;
        let obj;
        if (this.changedIds.includes(id)) {
            obj = this.toUpdateClusters.filter(item => item.Id == id)[0];
        } else {
            obj = {
                attributes: {
                    type: BU__OBJECT.objectApiName,
                },
                Id: id
            };
        }
        obj[field] = value;
        if (!this.changedIds.includes(id)) {
            this.toUpdateClusters.push(obj);
            this.changedIds.push(id);
        }
    }
    newBuMap = new Map();
    handleChangeFieldsNewCluster(event) {
        let field = event.target.dataset.field;
        let isCategory = event.target.dataset.isCategory;
        let value = isCategory ? event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : event.target.value : event.target.value;
        let countryIndex = event.target.dataset.countryIndex;
        let bannerIndex = event.target.dataset.bannerIndex;
        let clusterIndex = event.target.dataset.clusterIndex;
        let fieldIndex = event.target.dataset.fieldIndex;

        if (!this.newBuMap.has(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id)) {
            this.newBuMap.set(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id, new Map());
        }
        let obj;
        if (!this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).has(clusterIndex)) {
            obj = {
                attributes: {
                    type: BU__OBJECT.objectApiName,
                },
                RecordTypeId: this.assortmentClusterRT
            };
            obj[this.API_NAMES.BusinessUnit__c.SetBULinkMaster__c] = true;
            this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).set(clusterIndex, obj);
        }
        obj = this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).get(clusterIndex)
        obj[field] = value;
        this.newBuMap.get(this.dataArray[countryIndex].bannerWrapperList[bannerIndex].Id).set(clusterIndex, obj)
        console.log('this.newBuMap >>> ' + this.newBuMap)
    }

    checkNewClusters() {
        this.newBuMap.forEach((value, key) => {
            value.forEach((value2, key2) => {
                value2[this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c] = key;
                this.toUpdateClusters.push(value2);
            });
        });
    }

    handleSave() {
        this.tableLoading = true;
        this.checkNewClusters();
        saveClusters({ clustersToSave: JSON.stringify(this.toUpdateClusters) }).then((result) => {
            showNotification(this, this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
            this.toUpdateClusters = [];
            this.changedIds = [];
            this.dataArray = [];
            this.pageNumber = 0;
            this.totalRecordsLoadedNB = 0;
            this.totalSize = 0;
            this.newBuMap = new Map();
            this.isEditModeActive = false;
            this.loadmore = false;
            this.loadData();
        }).catch(error => {
            this.tableLoading = false;
            console.log('error save Data >> ' + error.message);
            showNotification(this, 'error', 'saving error', 'error', 'sticky');
            console.error(error);
        });
    }
    toggleEditMode() {
        this.tableLoading = true;
        this.isEditModeActive = !this.isEditModeActive;
        setTimeout(() => {
            this.tableLoading = false;
        }, 2000);
    }

    //return to home page
    handleBackToHomePage() {
        window.open('/lightning/page/home', '_self');
    }

    toggleFilter() {
        let mainPanel = this.template.querySelector('.main-panel');
        let filterPanel = this.template.querySelector('.filter-panel');
        mainPanel.classList.toggle('slds-size_9-of-12');
        mainPanel.classList.toggle('slds-size_1-of-1');
        filterPanel.classList.toggle('slds-size_3-of-12');
        filterPanel.classList.toggle('slds-hide');
    } catch(error) {
        console.log('error toggleFilter');
        console.error(error);
    }
    fillFilterParam(event) {
        try {
            let filterParam = event.target.dataset.field;
            console.log('filterParam: ' + filterParam)
            console.log('this[filterParam]: ' + this[filterParam])
            let value = filterParam != 'stratParam' && filterParam != 'clientCategParam' ? event.detail.recordId : event.target.value;
            console.log('value: ' + value)
            this[filterParam] = value;
            if (filterParam == 'stratParam') {
                this.selectedStrat = value;
            }
            if (filterParam == 'countryParam' && this[filterParam]) {
                this.BuBannerFilter = {
                    criteria: [
                        { fieldPath: 'RecordType.DeveloperName', operator: 'eq', value: 'Banner' },
                        { fieldPath: this.API_NAMES.BusinessUnit__c.BusinessUnitCountryOrigin__c, operator: 'eq', value: value },
                    ],
                    filterLogic: '1 AND 2',
                };
            } else if (filterParam == 'countryParam') {
                this.BuBannerFilter = {
                    criteria: [
                        {
                            fieldPath: 'RecordType.DeveloperName',
                            operator: 'eq',
                            value: 'Banner',
                        }
                    ],
                    filterLogic: '1',
                };
            }
            console.log('this.BuBannerFilter: ' + JSON.stringify(this.BuBannerFilter))
        } catch (error) {
            console.log('error fillFilterParam');
            console.log('%c' + error.message ? error.message : error.body?.message);
            console.error(error.message)
        }
    }

    filterData() {
        try {
            this.dataArray = [];
            this.pageNumber = 0;
            this.totalRecordsLoadedNB = 0;
            this.totalSize = 0;
            this.tableLoading = true;
            this.loadData(this);
        } catch (error) {
            console.log('error loadCountries');
            console.error(error);
        }
    }
    handleReset() {
        try {
            console.log('handleReset')
            //made them empty so they dont trigger the clusters filter again
            this.countryParam = '';
            this.bannerParam = '';
            this.categoryParam = '';
            this.clientCategParam = '';
            this.stratParam = '';
            this.tableLoading = true;
            this.filterData();
        } catch (error) {
            console.log('error loadCountries');
            console.error(error);
        }
    }

    changeHeight = () => {
        let headerHeight = 0, filterHeaderHeight = 0, navigateheight = 0;
        if (this.template.querySelector('.main-header')) {
            headerHeight = this.template.querySelector('.main-header').getBoundingClientRect().height;
        }
        let tableHeight = window.innerHeight - headerHeight - 160;
        if (this.template.querySelector('.table-div')) {
            this.template.querySelector('.table-div').style.height = tableHeight + 'px';
        }
        /*if (this.template.querySelector('.main-table')) {
            this.template.querySelector('.main-table').style.height = tableHeight + 'px';
            this.template.querySelector('.main-table').style.width = 100 + '%';
            this.template.querySelector('.main-table').style.overflow = 'auto';
        }*/
        if (this.template.querySelector('filter-header')) {
            filterHeaderHeight = this.template.querySelector('.filter-header').getBoundingClientRect().height;
        }
        if (this.template.querySelector('.filter-panel')) {
            this.template.querySelector('.filter-panel').style.height = tableHeight + 'px';
        }

        // this.template.querySelector('.filter-section').style.height = (tableHeight - filterHeaderHeight - 120) + 'px';
    };

    setnumberOfFixedColumns() {
        if (this.template.querySelector('.main-table')) {
            let tableTrs = this.template.querySelector('.main-table').rows;
            let nbOfFixedColumns = 3;
            for (let index = 0; tableTrs && index < tableTrs.length; index++) {
                let childrens = tableTrs[index].children;
                let left = 0;
                if (tableTrs[index].classList?.contains('country') || tableTrs[index].classList?.contains('banner')) {
                    nbOfFixedColumns = 2;
                } else {
                    nbOfFixedColumns = 3;
                }
                for (let index2 = 0; childrens && index2 < childrens.length; index2++) {
                    if (index != 1 && index2 < nbOfFixedColumns) {
                        childrens[index2].style.position = 'sticky';
                        childrens[index2].style.left = left + 'px';
                        childrens[index2].style.zIndex = index == 0 ? 5 : 3;
                        left += childrens[index2].offsetWidth;
                        childrens[index2].style.backgroundColor = childrens[index2].style.backgroundColor ? childrens[index2].style.backgroundColor : '';
                    } else {
                        childrens[index2].style.position = 'unset';
                        childrens[index2].style.left = 'unset';
                        childrens[index2].style.zIndex = 'unset';
                    }
                }
            }
            let firstHeader = tableTrs[0].children;
            for (let index2 = 0; firstHeader && index2 < firstHeader.length; index2++) {
                firstHeader[index2].style.position = 'sticky';
                firstHeader[index2].style.top = '0px';
                firstHeader[index2].style.zIndex = index2 < 3 ? 5 : 4;
                firstHeader[index2].style.backgroundColor = firstHeader[index2].style.backgroundColor ? firstHeader[index2].style.backgroundColor : '';
            }
            let secondHeader = tableTrs[1].children;
            for (let index2 = 0; secondHeader && index2 < secondHeader.length; index2++) {
                secondHeader[index2].style.position = 'sticky';
                secondHeader[index2].style.top = tableTrs[0].offsetHeight + 'px';
                secondHeader[index2].style.zIndex = 4;
                secondHeader[index2].style.backgroundColor = secondHeader[index2].style.backgroundColor ? secondHeader[index2].style.backgroundColor : '';
            }
        }
    }
}