/* Static Resources */
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
import xlsx from '@salesforce/resourceUrl/xlsxLib';

// ContractSellIn__c fields
import ContractSellin_NegoScope from '@salesforce/schema/ContractSellIn__c.NegoScope__c';
import ContractSellin_SellInBaseName from '@salesforce/schema/ContractSellIn__c.SellInBaseName__c';
import ContractSellin_Year from '@salesforce/schema/ContractSellIn__c.Year__c';
import ContractSellin_ContractSellInP1 from '@salesforce/schema/ContractSellIn__c.ContractSellInP1__c';
import ContractSellin_NegoSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotal__c';
import ContractSellin_BOSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.BOSellInDiscTotal__c';
import ContractSellin_BOSellInDiscAdditional from '@salesforce/schema/ContractSellIn__c.BOSellInDiscAdditional__c';
import ContractSellin_NegoInitSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotal__c';

// NegoScope__c fields
import NegoScope_Supplier from '@salesforce/schema/NegoScope__c.Supplier__c';
import NegoScope_Status from '@salesforce/schema/NegoScope__c.Status__c';
import NegoScope_Name from '@salesforce/schema/NegoScope__c.Name';
import NegoScope_OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';

// Supplier__c fields
import Supplier_Code__c from '@salesforce/schema/Supplier__c.Code__c';
import Supplier_Name from '@salesforce/schema/Supplier__c.Name';

// Object apiName
import ContractSellin_OBJECT from '@salesforce/schema/ContractSellIn__c';
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
import Supplier_OBJECT from '@salesforce/schema/Supplier__c';

// Labels
import LBL_Save from '@salesforce/label/c.Save';
import LBL_Cancel from '@salesforce/label/c.Cancel';
import LBL_SellIn_Mass_Update from '@salesforce/label/c.LBL_SellIn_Mass_Update';
import LBL_SellIn_BO_Total from '@salesforce/label/c.LBL_SellIn_BO_Total';
import LBL_SellIn_Evol1 from '@salesforce/label/c.LBL_SellIn_Evol1';
import LBL_SellIn_Evol2 from '@salesforce/label/c.LBL_SellIn_Evol2';
import LBL_SellIn_Nego_New from '@salesforce/label/c.LBL_SellIn_Nego_New';
import LBL_SellIn_Evol3 from '@salesforce/label/c.LBL_SellIn_Evol3';
import LBL_SellIn_Evol4 from '@salesforce/label/c.LBL_SellIn_Evol4';
import LBL_SellIn_ContractStatus from '@salesforce/label/c.LBL_SellIn_ContractStatus';
import LBL_Error from '@salesforce/label/c.LBL_Error';
import LBL_Success from '@salesforce/label/c.LBL_Success';
import LBL_Import from '@salesforce/label/c.LBL_Import';
import LBL_Export from '@salesforce/label/c.LBL_Export';
import LBL_Ok from '@salesforce/label/c.LBL_Ok';
import LBL_Import_Finish from '@salesforce/label/c.LBL_Import_Finish';
import LBL_No_Item_To_Display from '@salesforce/label/c.LBL_No_Item_To_Display';


const labels = {
    ContractSellin__c: {},
    NegoScope__c: {},
    LBL_Save,
    LBL_Cancel,
    LBL_SellIn_Mass_Update,
    LBL_SellIn_BO_Total,
    LBL_SellIn_Evol1,
    LBL_SellIn_Evol2,
    LBL_SellIn_Nego_New,
    LBL_SellIn_Evol3,
    LBL_SellIn_Evol4,
    LBL_SellIn_ContractStatus,
    LBL_Error,
    LBL_Success,
    LBL_Import,
    LBL_Export,
    LBL_Ok,
    LBL_Import_Finish,
    LBL_No_Item_To_Display,
}

const API_NAMES = {
    ContractSellin__c: {
        objectApiName: ContractSellin_OBJECT.objectApiName,
        ContractSellInP1__r: ContractSellin_ContractSellInP1.fieldApiName.replace(/__c$/, "__r"),
        NegoSellInDiscTotal__c: ContractSellin_NegoSellInDiscTotal.fieldApiName,
        NegoInitSellInDiscTotal__c: ContractSellin_NegoInitSellInDiscTotal.fieldApiName,
        BOSellInDiscTotal__c: ContractSellin_BOSellInDiscTotal.fieldApiName,
        Year__c: ContractSellin_Year.fieldApiName,
        BOSellInDiscAdditional__c: ContractSellin_BOSellInDiscAdditional.fieldApiName,
    },
    NegoScope__c: {
        objectApiName: NegoScope_OBJECT.objectApiName,
        Status__c: NegoScope_Status.fieldApiName,
        Supplier__c: NegoScope_Supplier.fieldApiName,
    },
    Supplier__c: {
        objectApiName: Supplier_OBJECT.objectApiName,
        Name: Supplier_Name.fieldApiName,
    }
}
// FIELDS DESCRIPTION
const tableFields = {
    fields: [
        {
            fieldName: ContractSellin_NegoScope.fieldApiName.replace('__c', '__r') + '.' + NegoScope_Supplier.fieldApiName.replace('__c', '__r') + '.' + Supplier_Code__c.fieldApiName,
            objectName: Supplier_OBJECT.objectApiName,
            headerColor: '#3c7d22',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_NegoScope.fieldApiName.replace('__c', '__r') + '.' + NegoScope_Supplier.fieldApiName.replace('__c', '__r') + '.' + Supplier_Name.fieldApiName,
            objectName: Supplier_OBJECT.objectApiName,
            headerColor: '#3c7d22',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_NegoScope.fieldApiName.replace('__c', '__r') + '.' + NegoScope_Name.fieldApiName,
            objectName: NegoScope_OBJECT.objectApiName,
            headerColor: '#3c7d22',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_NegoScope.fieldApiName.replace('__c', '__r') + '.' + NegoScope_OwnerId.fieldApiName,
            objectName: NegoScope_OBJECT.objectApiName,
            headerColor: '#3c7d22',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_SellInBaseName.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#3c7d22',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_Year.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#393939',
            bodyColor: '#ffffff',
        },
        {
            fieldName: ContractSellin_ContractSellInP1.fieldApiName.replace('__c', '__r') + '.' + ContractSellin_NegoSellInDiscTotal.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#4d93d9',
            bodyColor: '#dae9f8'
        },
        {
            fieldName: ContractSellin_BOSellInDiscTotal.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#4d93d9',
            bodyColor: '#dae9f8'
        },
        {
            fieldName: ContractSellin_BOSellInDiscAdditional.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            isInput: true,
            headerColor: '#4d93d9',
            bodyColor: '#dae9f8'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldType": "DOUBLE",
            "fieldName": "LBL_SellIn_BO_Total",
            "fieldLabel": LBL_SellIn_BO_Total,
            preDefined: true,
            headerColor: '#4d93d9',
            bodyColor: '#dae9f8'
        },
        {
            fieldName: ContractSellin_NegoInitSellInDiscTotal.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#d86dcd',
            bodyColor: '#f2ceef'
        },
        {
            fieldName: ContractSellin_NegoSellInDiscTotal.fieldApiName,
            objectName: ContractSellin_OBJECT.objectApiName,
            headerColor: '#d86dcd',
            bodyColor: '#f2ceef'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldType": "isPercent",
            "fieldName": "LBL_SellIn_Evol1",
            "fieldLabel": LBL_SellIn_Evol1,
            preDefined: true,
            headerColor: '#d86dcd',
            bodyColor: '#fcf2fb'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldType": "isPercent",
            "fieldName": "LBL_SellIn_Evol2",
            "fieldLabel": LBL_SellIn_Evol2,
            preDefined: true,
            headerColor: '#d86dcd',
            bodyColor: '#fcf2fb'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldName": ContractSellin_NegoSellInDiscTotal.fieldApiName,
            "fieldLabel": LBL_SellIn_Nego_New,
            isInput: true,
            headerColor: '#d86dcd',
            bodyColor: '#fcf2fb'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldType": "DOUBLisPercentE",
            "fieldName": "LBL_SellIn_Evol3",
            "fieldLabel": LBL_SellIn_Evol3,
            preDefined: true,
            headerColor: '#d86dcd',
            bodyColor: '#fcf2fb'
        },
        {
            "objectName": ContractSellin_OBJECT.objectApiName,
            "fieldType": "isPercent",
            "fieldName": "LBL_SellIn_Evol4",
            "fieldLabel": LBL_SellIn_Evol4,
            preDefined: true,
            headerColor: '#d86dcd',
            bodyColor: '#fcf2fb'
        },
    ],
}

const BATCH_SIZE = 200;
// const BATCH_SIZE_EXCEL = 700;

const RESOURCES = {
    ExcelJSScript,
    xlsx
}

export { API_NAMES, tableFields, labels, BATCH_SIZE, RESOURCES }