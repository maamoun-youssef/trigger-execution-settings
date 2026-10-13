/* Static Resources */
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
import xlsx from '@salesforce/resourceUrl/xlsxLib';

// ContractSellIn__c fields
import ContractSellin_NegoScope from '@salesforce/schema/ContractSellIn__c.NegoScope__c';
import ContractSellin_Contract from '@salesforce/schema/ContractSellIn__c.Contract__c';
import ContractSellin_SellInBaseName from '@salesforce/schema/ContractSellIn__c.SellInBaseName__c';
import ContractSellin_MainBase from '@salesforce/schema/ContractSellIn__c.MainBase__c';
import ContractSellin_LineType from '@salesforce/schema/ContractSellIn__c.LineType__c';
import ContractSellin_ContractSellInMaster from '@salesforce/schema/ContractSellIn__c.ContractSellInMaster__c';
import ContractSellin_Year from '@salesforce/schema/ContractSellIn__c.Year__c';
import ContractSellin_ContractSellInP1 from '@salesforce/schema/ContractSellIn__c.ContractSellInP1__c';
import ContractSellin_NegoSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.NegoSellInDiscTotal__c';
import ContractSellin_BOSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.BOSellInDiscTotal__c';
import ContractSellin_BOSellInDiscAdditional from '@salesforce/schema/ContractSellIn__c.BOSellInDiscAdditional__c';
import ContractSellin_NegoInitSellInDiscTotal from '@salesforce/schema/ContractSellIn__c.NegoInitSellInDiscTotal__c';
import ContractSellin_ReviewDate from '@salesforce/schema/ContractSellIn__c.ReviewDate__c';
import ContractSellin_StatedSellInLastPeriod from '@salesforce/schema/ContractSellIn__c.StatedSellInLastPeriod__c';
import ContractSellin_Review from '@salesforce/schema/ContractSellIn__c.Review__c';
import ContractSellin_StatedSellInDiscTotal__c from '@salesforce/schema/ContractSellIn__c.StatedSellInDiscTotal__c';

// Contract__c fields
import Contract_Status from '@salesforce/schema/Contract__c.Status__c';
import Contract_RecordTypeId from '@salesforce/schema/Contract__c.RecordTypeId';

// RecordType fields
import RecordType_DeveloperName from '@salesforce/schema/RecordType.DeveloperName';


// NegoScope__c fields
import NegoScope_Supplier from '@salesforce/schema/NegoScope__c.Supplier__c';
import NegoScope_Status from '@salesforce/schema/NegoScope__c.Status__c';
import NegoScope_Name from '@salesforce/schema/NegoScope__c.Name';
import NegoScope_OwnerId from '@salesforce/schema/NegoScope__c.OwnerId';

// Supplier__c fields
import Supplier_Code__c from '@salesforce/schema/Supplier__c.Code__c';
import Supplier_Name from '@salesforce/schema/Supplier__c.Name';

// User fields
import User_Name from '@salesforce/schema/User.Name';

// Object apiName
import ContractSellin_OBJECT from '@salesforce/schema/ContractSellIn__c';
import NegoScope_OBJECT from '@salesforce/schema/NegoScope__c';
import Contract_OBJECT from '@salesforce/schema/Contract__c';
import Supplier_OBJECT from '@salesforce/schema/Supplier__c';
import User_OBJECT from '@salesforce/schema/User';

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
import LBL_Total from '@salesforce/label/c.LBL_Total';
import LBL_Search from '@salesforce/label/c.LBL_Search';
import LBL_SellIn_ContractSequence from '@salesforce/label/c.LBL_SellIn_ContractSequence';
import LBL_SellIn_Apply from '@salesforce/label/c.LBL_SellIn_Apply';
import LBL_SellIn_DISCTO_N1 from '@salesforce/label/c.LBL_SellIn_DISCTO_N1';
import LBL_First from '@salesforce/label/c.LBL_First';
import LBL_Previous from '@salesforce/label/c.LBL_Previous';
import LBL_Next from '@salesforce/label/c.LBL_Next';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_Of from '@salesforce/label/c.LBL_Of';


const labels = {
    ContractSellin__c: {},
    NegoScope__c: {},
    Contract__c: {},
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
    LBL_Total,
    LBL_Search,
    LBL_SellIn_ContractSequence,
    LBL_SellIn_Apply,
    LBL_SellIn_DISCTO_N1,
    LBL_First,
    LBL_Previous,
    LBL_Next,
    LBL_Last,
    LBL_Of,
}

const API_NAMES = {
    ContractSellin__c: {
        objectApiName: ContractSellin_OBJECT.objectApiName,
        ContractSellInP1__r: ContractSellin_ContractSellInP1.fieldApiName.replace(/__c$/, "__r"),
        NegoScope__c: ContractSellin_NegoScope.fieldApiName,
        NegoScope__r: ContractSellin_NegoScope.fieldApiName.replace(/__c$/, '__r'),
        Contract__r: ContractSellin_Contract.fieldApiName.replace(/__c$/, '__r'),
        NegoSellInDiscTotal__c: ContractSellin_NegoSellInDiscTotal.fieldApiName,
        NegoInitSellInDiscTotal__c: ContractSellin_NegoInitSellInDiscTotal.fieldApiName,
        BOSellInDiscTotal__c: ContractSellin_BOSellInDiscTotal.fieldApiName,
        Year__c: ContractSellin_Year.fieldApiName,
        BOSellInDiscAdditional__c: ContractSellin_BOSellInDiscAdditional.fieldApiName,
        SellInBaseName__c: ContractSellin_SellInBaseName.fieldApiName,
        MainBase__c: ContractSellin_MainBase.fieldApiName,
        LineType__c: ContractSellin_LineType.fieldApiName,
        ContractSellInMaster__c: ContractSellin_ContractSellInMaster.fieldApiName,
        ReviewDate__c: ContractSellin_ReviewDate.fieldApiName,
        StatedSellInLastPeriod__c: ContractSellin_StatedSellInLastPeriod.fieldApiName,
        Review__c: ContractSellin_Review.fieldApiName,
        StatedSellInDiscTotal__c: ContractSellin_StatedSellInDiscTotal__c.fieldApiName,
    },
    NegoScope__c: {
        objectApiName: NegoScope_OBJECT.objectApiName,
        Status__c: NegoScope_Status.fieldApiName,
        Supplier__c: NegoScope_Supplier.fieldApiName,
        Supplier__r: NegoScope_Supplier.fieldApiName.replace(/__c$/, '__r'),
        OwnerId: NegoScope_OwnerId.fieldApiName,
        Owner: NegoScope_OwnerId.fieldApiName.replace(/Id$/, ''),
        Name: NegoScope_Name.fieldApiName,
    },
    Contract__c: {
        objectApiName: Contract_OBJECT.objectApiName,
        Status__c: Contract_Status.fieldApiName,
        RecordTypeId: Contract_RecordTypeId.fieldApiName,
        RecordType: Contract_RecordTypeId.fieldApiName.replace(/Id$/, ''),
    },
    RecordType: {
        DeveloperName: RecordType_DeveloperName.fieldApiName,
    },
    Supplier__c: {
        objectApiName: Supplier_OBJECT.objectApiName,
        Code__c: Supplier_Code__c.fieldApiName,
        Name: Supplier_Name.fieldApiName,
    },
    User: {
        objectApiName: User_OBJECT.objectApiName,
        Name: User_Name.fieldApiName,
    }
}

const BATCH_SIZE = 200;
// const BATCH_SIZE_EXCEL = 700;

const RESOURCES = {
    ExcelJSScript,
    xlsx
}

export { API_NAMES, labels, BATCH_SIZE, RESOURCES }