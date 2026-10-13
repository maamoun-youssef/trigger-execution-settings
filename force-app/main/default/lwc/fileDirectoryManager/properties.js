//FIELDS
import FilePreview__c from "@salesforce/schema/FileDirectory__c.FilePreview__c";
import NumberOfDownloads__c from "@salesforce/schema/FileDirectory__c.NumberOfDownloads__c";
import NumberOfViews__c from "@salesforce/schema/FileDirectory__c.NumberOfViews__c";
import Status__c from "@salesforce/schema/FileDirectory__c.Status__c";
import SubType__c from "@salesforce/schema/FileDirectory__c.SubType__c";
import IsReceiptConfirmed__c from "@salesforce/schema/FileDirectory__c.IsReceiptConfirmed__c";
import ReceiptConfirmedBy__c from "@salesforce/schema/FileDirectory__c.ReceiptConfirmedBy__c";
import StatusLogoURL__c from "@salesforce/schema/FileDirectory__c.StatusLogoURL__c";
import ContentDocumentId__c from "@salesforce/schema/FileDirectory__c.ContentDocumentId__c";
import DocumentName__c from "@salesforce/schema/FileDirectory__c.DocumentName__c";
import IsPortalPublished__c from "@salesforce/schema/FileDirectory__c.IsPortalPublished__c";
import Supplier__c from "@salesforce/schema/FileDirectory__c.Supplier__c";
import Account__c from "@salesforce/schema/Supplier__c.Account__c";
// Labels Decleration
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Status from "@salesforce/label/c.LBL_Status";
import LBL_ChangeStatus from "@salesforce/label/c.LBL_ChangeStatus";
import MSG_Connect_FileUploadSuccess from "@salesforce/label/c.MSG_Connect_FileUploadSuccess";
import LBL_Download from "@salesforce/label/c.LBL_Download";
import LBL_Version from "@salesforce/label/c.LBL_Version";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Ok from "@salesforce/label/c.LBL_Ok";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";

import MSG_SuccessReset from "@salesforce/label/c.MSG_SuccessReset";
import LBL_ConfirmReset from "@salesforce/label/c.LBL_ConfirmReset";
import LBL_ViewDocument from "@salesforce/label/c.LBL_ViewDocument";
import LBL_ViewDocument_Disabled from "@salesforce/label/c.LBL_ViewDocument_Disabled";
import LBL_UploadDocument from "@salesforce/label/c.LBL_UploadDocument";
import LBL_UploadDocument_Disabled from "@salesforce/label/c.LBL_UploadDocument_Disabled";
import LBL_ReplaceDocument from "@salesforce/label/c.LBL_ReplaceDocument";
import LBL_DeleteDocument from "@salesforce/label/c.LBL_DeleteDocument";
import LBL_DeleteDocument_Disabled from "@salesforce/label/c.LBL_DeleteDocument_Disabled";
import LBL_ConfirmDelete from "@salesforce/label/c.LBL_ConfirmDelete";
import LBL_ShareDocument from "@salesforce/label/c.LBL_ShareDocument";
import LBL_UnshareDocument from "@salesforce/label/c.LBL_UnshareDocument";
import LBL_ShareDocument_Disabled from "@salesforce/label/c.LBL_ShareDocument_Disabled";
import LBL_ConfirmShare from "@salesforce/label/c.LBL_ConfirmShare";
import LBL_ConfirmUnshare from "@salesforce/label/c.LBL_ConfirmUnshare";
import LBL_ConfirmReceipt from "@salesforce/label/c.LBL_ConfirmReceipt";
import LBL_ConfirmReceipt_Disabled from "@salesforce/label/c.LBL_ConfirmReceipt_Disabled";
import LBL_ConfirmReceiptDialog from "@salesforce/label/c.LBL_ConfirmReceiptDialog";
import MSG_SuccessUpload from "@salesforce/label/c.MSG_SuccessUpload";
import MSG_SuccessDelete from "@salesforce/label/c.MSG_SuccessDelete";
import MSG_SuccessShare from "@salesforce/label/c.MSG_SuccessShare";
import MSG_SuccessUnshare from "@salesforce/label/c.MSG_SuccessUnshare";
import MSG_SuccessReceipt from "@salesforce/label/c.MSG_SuccessReceipt";


const API_NAMES = {
    FilePreview__c: FilePreview__c.fieldApiName,
    NumberOfDownloads__c: NumberOfDownloads__c.fieldApiName,
    NumberOfViews__c: NumberOfViews__c.fieldApiName,
    Status__c: Status__c.fieldApiName,
    SubType__c: SubType__c.fieldApiName,
    IsReceiptConfirmed__c: IsReceiptConfirmed__c.fieldApiName,
    ReceiptConfirmedBy__c: ReceiptConfirmedBy__c.fieldApiName,
    StatusLogoURL__c: StatusLogoURL__c.fieldApiName,
    ContentDocumentId__c: ContentDocumentId__c.fieldApiName,
    DocumentName__c: DocumentName__c.fieldApiName,
    IsPortalPublished__c: IsPortalPublished__c.fieldApiName,
    Supplier__c: Supplier__c.fieldApiName,
    Supplier__r: Supplier__c.fieldApiName.replace('__c', '__r'),
    Account__c: Account__c.fieldApiName,
}
const columnsToRemove = [
    FilePreview__c.fieldApiName,
    // NumberOfDownloads__c.fieldApiName,
    // NumberOfViews__c.fieldApiName,
    // Status__c.fieldApiName
]

const Labels = {
    LBL_No_Item_To_Display,
    LBL_Of,
    LBL_Status,
    LBL_ChangeStatus,
    MSG_Successfully_Saved,
    MSG_Connect_FileUploadSuccess,
    LBL_Download,
    LBL_Version,
    LBL_Ok,
    LBL_Cancel,
    MSG_SuccessReset,
    LBL_ConfirmReset,
    LBL_ViewDocument,
    LBL_ViewDocument_Disabled,
    LBL_UploadDocument,
    LBL_UploadDocument_Disabled,
    LBL_ReplaceDocument,
    LBL_DeleteDocument,
    LBL_DeleteDocument_Disabled,
    LBL_ConfirmDelete,
    LBL_ShareDocument,
    LBL_UnshareDocument,
    LBL_ShareDocument_Disabled,
    LBL_ConfirmShare,
    LBL_ConfirmUnshare,
    LBL_ConfirmReceipt,
    LBL_ConfirmReceipt_Disabled,
    LBL_ConfirmReceiptDialog,
    MSG_SuccessUpload,
    MSG_SuccessDelete,
    MSG_SuccessShare,
    MSG_SuccessUnshare,
    MSG_SuccessReceipt,
}

export { API_NAMES, columnsToRemove, Labels };