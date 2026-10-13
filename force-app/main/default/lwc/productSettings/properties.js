/**
* Custom Labels
*/
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_PRD_Stg_General_Settings from "@salesforce/label/c.LBL_PRD_Stg_General_Settings";
import LBL_PRD_Stg_ProductRecordTypes_Phrase from "@salesforce/label/c.LBL_PRD_Stg_ProductRecordTypes_Phrase";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Selected from "@salesforce/label/c.LBL_Selected";
import LBL_PRD_Stg_NumberOfUnitCharges_Phrase from "@salesforce/label/c.LBL_PRD_Stg_NumberOfUnitCharges_Phrase";
import LBL_PRD_Stg_IsAutoNumberProductName_Phrase from "@salesforce/label/c.LBL_PRD_Stg_IsAutoNumberProductName_Phrase";
import LBL_Example from "@salesforce/label/c.LBL_Example";
import LBL_Grid_Settings from "@salesforce/label/c.LBL_Grid_Settings";
import LBL_PRD_Stg_PriceList_Grid_Settings_Phrase from "@salesforce/label/c.LBL_PRD_Stg_PriceList_Grid_Settings_Phrase";
import LBL_PRD_Stg_PriceList_Manager_Settings from "@salesforce/label/c.LBL_PRD_Stg_PriceList_Manager_Settings";
import LBL_PRD_Stg_MassProductImportSettings_Phrase from "@salesforce/label/c.LBL_PRD_Stg_MassProductImportSettings_Phrase";

const labels = {
    LBL_Error,
    LBL_Save,
    MSG_Successfully_Saved,
    LBL_Success,
    LBL_PRD_Stg_General_Settings,
    LBL_PRD_Stg_ProductRecordTypes_Phrase,
    LBL_Available,
    LBL_Selected,
    LBL_PRD_Stg_NumberOfUnitCharges_Phrase,
    LBL_PRD_Stg_IsAutoNumberProductName_Phrase,
    LBL_Example,
    LBL_Grid_Settings,
    LBL_PRD_Stg_PriceList_Grid_Settings_Phrase,
    LBL_PRD_Stg_PriceList_Manager_Settings,
    LBL_PRD_Stg_MassProductImportSettings_Phrase
}

/**
* Fields
*/
import ProductSettings__c from '@salesforce/schema/ProductSettings__c';
import AutoNumberLastValue__c from '@salesforce/schema/ProductSettings__c.AutoNumberLastValue__c';
import AutoNumberPrefix__c from '@salesforce/schema/ProductSettings__c.AutoNumberPrefix__c';
import HigherLevelPackagingRTId__c from '@salesforce/schema/ProductSettings__c.HigherLevelPackagingRTId__c';
import IsAutoNumberProductName__c from '@salesforce/schema/ProductSettings__c.IsAutoNumberProductName__c';
import IsPriceListDataUpdatePGs__c from '@salesforce/schema/ProductSettings__c.IsPriceListDataUpdatePGs__c';
import NumberOfUnitCharges__c from '@salesforce/schema/ProductSettings__c.NumberOfUnitCharges__c';
import PriceListManagerPLDGrid__c from '@salesforce/schema/ProductSettings__c.PriceListManagerPLDGrid__c';
import PriceListManagerProductGrid__c from '@salesforce/schema/ProductSettings__c.PriceListManagerProductGrid__c';
import ProductManagementProfiles__c from '@salesforce/schema/ProductSettings__c.ProductManagementProfiles__c';
import ProductRecordTypes__c from '@salesforce/schema/ProductSettings__c.ProductRecordTypes__c';

const PRODUCT_SETTINGS_API = {
    ProductSettings__c: ProductSettings__c.objectApiName,
    AutoNumberLastValue__c: AutoNumberLastValue__c.fieldApiName,
    AutoNumberPrefix__c: AutoNumberPrefix__c.fieldApiName,
    HigherLevelPackagingRTId__c: HigherLevelPackagingRTId__c.fieldApiName,
    IsAutoNumberProductName__c: IsAutoNumberProductName__c.fieldApiName,
    IsPriceListDataUpdatePGs__c: IsPriceListDataUpdatePGs__c.fieldApiName,
    NumberOfUnitCharges__c: NumberOfUnitCharges__c.fieldApiName,
    PriceListManagerPLDGrid__c: PriceListManagerPLDGrid__c.fieldApiName,
    PriceListManagerProductGrid__c: PriceListManagerProductGrid__c.fieldApiName,
    ProductManagementProfiles__c: ProductManagementProfiles__c.fieldApiName,
    ProductRecordTypes__c: ProductRecordTypes__c.fieldApiName,
}

export { labels, PRODUCT_SETTINGS_API };