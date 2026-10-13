import DIFF_MATCH_PATCH from '@salesforce/resourceUrl/diff_match_patch';
import illustrationUrl from '@salesforce/resourceUrl/EmailReview';
import JSPDF from '@salesforce/resourceUrl/jsPDF';
import DOCX_LIB from '@salesforce/resourceUrl/docxLib';
import NEGOPTIM_ICONS from '@salesforce/resourceUrl/NegoptimIcons';
import BusinessOwnerIcon from '@salesforce/resourceUrl/BusinessOwnerIcon';

import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import LBL_Select from "@salesforce/label/c.LBL_Select";
import LBL_Placeholder_Search from "@salesforce/label/c.LBL_Placeholder_Search";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Insert from "@salesforce/label/c.LBL_Insert";
import LBL_Insert_Merge_Field from "@salesforce/label/c.LBL_Insert_Merge_Field";
import LBL_Available from "@salesforce/label/c.LBL_Available";
import LBL_Select_Object from "@salesforce/label/c.LBL_Select_Object";
import LBL_Select_Field from "@salesforce/label/c.LBL_Select_Field";
import LBL_AddClause from "@salesforce/label/c.LBL_AddClause";
import LBL_SendToSupplier from "@salesforce/label/c.LBL_SendToSupplier";
import LBL_LatestSupplierComments from "@salesforce/label/c.LBL_LatestSupplierComments";
import LBL_LatestCommentsLegal from "@salesforce/label/c.LBL_LatestCommentsLegal";
import LBL_DateOFLegalValidation from "@salesforce/label/c.LBL_DateOFLegalValidation";
import LBL_OverviewLegalClauses from "@salesforce/label/c.LBL_OverviewLegalClauses";
import LBL_SaveOrder from "@salesforce/label/c.LBL_SaveOrder";
import MSG_SaveNewOrder from "@salesforce/label/c.MSG_SaveNewOrder";
import LBL_VersionComparison from "@salesforce/label/c.LBL_VersionComparison";
import LBL_PastVersion from "@salesforce/label/c.LBL_PastVersion";
import LBL_CurrentVersion from "@salesforce/label/c.LBL_CurrentVersion";
import LBL_LD_CommentToSupp from "@salesforce/label/c.LBL_LD_CommentToSupp";
import LBL_LD_CommentToBO from "@salesforce/label/c.LBL_LD_CommentToBO";
import LBL_LD_NotEditable from "@salesforce/label/c.LBL_LD_NotEditable";
import LBL_LD_SendToBO from "@salesforce/label/c.LBL_LD_SendToBO";
import LBL_LD_PdfPreview from "@salesforce/label/c.LBL_LD_PdfPreview";
import LBL_LD_PublishDraftClauses from "@salesforce/label/c.LBL_LD_PublishDraftClauses";
import LBL_LD_AcceptClauses from "@salesforce/label/c.LBL_LD_AcceptClauses";
import LBL_LD_ApproveClauses from "@salesforce/label/c.LBL_LD_ApproveClauses";
import LBL_LD_SuppAcceptedByTwo from "@salesforce/label/c.LBL_LD_SuppAcceptedByTwo";
import LBL_LD_SupplierCardTitle from "@salesforce/label/c.LBL_LD_SupplierCardTitle";
import LBL_LD_LegalCardTitle from "@salesforce/label/c.LBL_LD_LegalCardTitle";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_LD_ValidClause from "@salesforce/label/c.LBL_LD_ValidClause";
import LBL_Close from "@salesforce/label/c.LBL_Close";
import LBL_LD_NoLegalClause from "@salesforce/label/c.LBL_LD_NoLegalClause";
import LBL_LD_AccordionNoClauseBody from "@salesforce/label/c.LBL_LD_AccordionNoClauseBody";
import LBL_LD_AddNewClause from "@salesforce/label/c.LBL_LD_AddNewClause";
import LBL_LD_EnterTextOfClause from "@salesforce/label/c.LBL_LD_EnterTextOfClause";
import LBL_Loading from "@salesforce/label/c.LBL_Loading";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_LD_ContactModalTitle from "@salesforce/label/c.LBL_LD_ContactModalTitle";
import LBL_LD_NoContacts from "@salesforce/label/c.LBL_LD_NoContacts";
import LBL_LD_DeleteConfirmation from "@salesforce/label/c.LBL_LD_DeleteConfirmation";
import MSG_LD_RemoveClause from "@salesforce/label/c.MSG_LD_RemoveClause";
import LBL_LD_HeaderCount from "@salesforce/label/c.LBL_LD_HeaderCount";
import LBL_Name from "@salesforce/label/c.LBL_Name";
import LBL_Confirm from "@salesforce/label/c.LBL_Confirm";
import MSG_LD_ErrorPdfExport from "@salesforce/label/c.MSG_LD_ErrorPdfExport";
import MSG_LD_HandlePdfPreview from "@salesforce/label/c.MSG_LD_HandlePdfPreview";
import LBL_LD_confirmationMessage from "@salesforce/label/c.LBL_LD_confirmationMessage";
import MSG_LD_CommentPublishSuccess from "@salesforce/label/c.MSG_LD_CommentPublishSuccess";
import LBL_LD_OnlyWithComment from "@salesforce/label/c.LBL_LD_OnlyWithComment";
import LBL_LDPublishAllComments from "@salesforce/label/c.LBL_LDPublishAllComments";
import LBL_LD_BOFilterLabel from "@salesforce/label/c.LBL_LD_BOFilterLabel";
import LBL_LD_ExportToWord from "@salesforce/label/c.LBL_LD_ExportToWord";
import LBL_LDComment from "@salesforce/label/c.LBL_LDComment";
import LBL_LD_PublishAll from "@salesforce/label/c.LBL_LD_PublishAll";
import LBL_LD_ApproveAll from "@salesforce/label/c.LBL_LD_ApproveAll";
import LBL_LD_ValidateAll from "@salesforce/label/c.LBL_LD_ValidateAll";
import LBL_NewVersion from "@salesforce/label/c.LBL_NewVersion";
import LBL_LD_GlobalVariables from "@salesforce/label/c.LBL_LD_GlobalVariables";
import LBL_LD_By from "@salesforce/label/c.LBL_LD_By";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import MSG_LDCommentsResolved from "@salesforce/label/c.MSG_LDCommentsResolved";
import LBL_LDLabel from "@salesforce/label/c.LBL_LDLabel";
import LBL_LDAPI from "@salesforce/label/c.LBL_LDAPI";
import LBL_Proceed from "@salesforce/label/c.LBL_Proceed";
import MSG_LD_ValidateClause from "@salesforce/label/c.MSG_LD_ValidateClause";
import LBL_LD_PublishAllBOComments from "@salesforce/label/c.LBL_LD_PublishAllBOComments";
import MSG_LD_BOPublishClauses_Alert from "@salesforce/label/c.MSG_LD_BOPublishClauses_Alert";
import MSG_LegalDocument_CursorRequired from "@salesforce/label/c.MSG_LegalDocument_CursorRequired";
import LBL_LegalDocument_CursorRequired from "@salesforce/label/c.LBL_LegalDocument_CursorRequired";
import MSG_LegalDocument_ClauseValidated from "@salesforce/label/c.MSG_LegalDocument_ClauseValidated";
import MSG_LegalDocument_SendToBusinessOwner from "@salesforce/label/c.MSG_LegalDocument_SendToBusinessOwner";
import MSG_LegalDocument_ClauseOrderSaved from "@salesforce/label/c.MSG_LegalDocument_ClauseOrderSaved";
import MSG_LegalDocument_SupplierAlreadyHasDocument from "@salesforce/label/c.MSG_LegalDocument_SupplierAlreadyHasDocument";
import MSG_LegalDocument_DraftClausesUpdated from "@salesforce/label/c.MSG_LegalDocument_DraftClausesUpdated";
import MSG_LegalDocument_GlobalVariablesSavedNoClauseAffected from "@salesforce/label/c.MSG_LegalDocument_GlobalVariablesSavedNoClauseAffected";
import MSG_LegalDocument_AllClausesApproved from "@salesforce/label/c.MSG_LegalDocument_AllClausesApproved";
import MSG_LegalDocument_AllClausesValidated from "@salesforce/label/c.MSG_LegalDocument_AllClausesValidated";
import MSG_LegalDocument_AllCommentsPublished from "@salesforce/label/c.MSG_LegalDocument_AllCommentsPublished";
import MSG_LegalDocument_AllClausesAndCommentsPublished from "@salesforce/label/c.MSG_LegalDocument_AllClausesAndCommentsPublished";
import MSG_LegalDocument_ClauseUpdatedSuccessfully from "@salesforce/label/c.MSG_LegalDocument_ClauseUpdatedSuccessfully";
import MSG_LegalDocument_NoChangesMade from "@salesforce/label/c.MSG_LegalDocument_NoChangesMade";
import MSG_LegalDocument_ClauseDeleted from "@salesforce/label/c.MSG_LegalDocument_ClauseDeleted";
import MSG_LegalDocument_ClauseMarkedForDeletion from "@salesforce/label/c.MSG_LegalDocument_ClauseMarkedForDeletion";
import MSG_LegalDocument_SentToSuppliers from "@salesforce/label/c.MSG_LegalDocument_SentToSuppliers";
import MSG_LegalDocument_SelectAtLeastOneSupplier from "@salesforce/label/c.MSG_LegalDocument_SelectAtLeastOneSupplier";
import MSG_LegalDocument_ClauseAddedSuccessfully from "@salesforce/label/c.MSG_LegalDocument_ClauseAddedSuccessfully";
import MSG_LegalDocument_EnterClauseText from "@salesforce/label/c.MSG_LegalDocument_EnterClauseText";
import MSG_LegalDocument_StartTypingNewVersion from "@salesforce/label/c.MSG_LegalDocument_StartTypingNewVersion";
import MSG_LegalDocument_NoPreviousVersion from "@salesforce/label/c.MSG_LegalDocument_NoPreviousVersion";
import MSG_LegalDocument_SelectVersion from "@salesforce/label/c.MSG_LegalDocument_SelectVersion";
import MSG_LegalDocument_PdfExportSuccess from "@salesforce/label/c.MSG_LegalDocument_PdfExportSuccess";
import MSG_LegalDocument_PdfExportError from "@salesforce/label/c.MSG_LegalDocument_PdfExportError";
import MSG_LegalDocument_PdfLibraryNotLoaded from "@salesforce/label/c.MSG_LegalDocument_PdfLibraryNotLoaded";
import MSG_LegalDocument_SentToSuppliersDocument from "@salesforce/label/c.MSG_LegalDocument_SentToSuppliersDocument";
import MSG_LegalDocument_NoContent from "@salesforce/label/c.MSG_LegalDocument_NoContent";
import LBL_LegalDocument_SuppliersContact from "@salesforce/label/c.LBL_LegalDocument_SuppliersContact";
import LBL_None from "@salesforce/label/c.LBL_None";
import MSG_LegalDocument_NewVersionCreated from "@salesforce/label/c.MSG_LegalDocument_NewVersionCreated";
// import LBL_LegalDocument_SupplierSignatory from "@salesforce/label/c.LBL_LegalDocument_SupplierSignatory";
// import LBL_LegalDocument_Signatory from "@salesforce/label/c.LBL_LegalDocument_Signatory";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_New from "@salesforce/label/c.LBL_New";
import LBL_Value from "@salesforce/label/c.LBL_Value";

const Labels = {
    LBL_Edit,
    LBL_None,
    LBL_AddClause,
    LBL_SendToSupplier,
    LBL_LatestSupplierComments,
    LBL_LatestCommentsLegal,
    LBL_DateOFLegalValidation,
    LBL_OverviewLegalClauses,
    LBL_SaveOrder,
    MSG_SaveNewOrder,
    LBL_VersionComparison,
    LBL_PastVersion,
    LBL_CurrentVersion,
    LBL_Cancel,
    LBL_Save,
    LBL_Next,
    LBL_Error,
    LBL_Add,
    LBL_Name,
    LBL_New,
    LBL_Confirm,
    LBL_NewVersion,
    LBL_LD_CommentToSupp,
    LBL_LD_CommentToBO,LBL_Value,
    LBL_LD_NotEditable,
    LBL_LD_SendToBO,
    LBL_LD_PdfPreview,
    LBL_LD_PublishDraftClauses,
    LBL_LD_AcceptClauses,
    LBL_LD_ApproveClauses,
    LBL_LD_SuppAcceptedByTwo,
    LBL_LD_SupplierCardTitle,
    LBL_LD_LegalCardTitle,
    LBL_Delete,
    LBL_LD_ValidClause,
    LBL_Close,
    LBL_Warning,
    LBL_LD_NoLegalClause,
    LBL_LD_AccordionNoClauseBody,
    LBL_LD_AddNewClause,
    LBL_LD_EnterTextOfClause,
    LBL_Loading,
    LBL_LD_confirmationMessage,
    LBL_LD_OnlyWithComment,
    MSG_LD_CommentPublishSuccess,
    LBL_LD_ExportToWord,
    LBL_LDComment,
    LBL_LD_PublishAll,
    LBL_LD_ApproveAll,
    LBL_LD_ValidateAll,
    LBL_Insert,
    LBL_Insert_Merge_Field,
    LBL_Available,
    LBL_Select_Field,
    LBL_LegalDocument_SuppliersContact,
    LBL_Select_Object,
    LBL_LD_GlobalVariables,
    LBL_LD_By, MSG_LDCommentsResolved, LBL_Success,
    LBL_Select, LBL_No_Item_To_Display, MSG_LD_RemoveClause, LBL_LD_HeaderCount,
    LBL_LD_ContactModalTitle, LBL_Placeholder_Search, LBL_LD_NoContacts, LBL_LD_DeleteConfirmation,
    MSG_LD_ErrorPdfExport, MSG_LD_HandlePdfPreview,
    LBL_LDPublishAllComments, LBL_LD_BOFilterLabel,
    LBL_LDAPI,
    LBL_LDLabel,
    LBL_Proceed,
    MSG_LD_ValidateClause,
    LBL_LD_PublishAllBOComments,
    MSG_LD_BOPublishClauses_Alert,
    MSG_LegalDocument_CursorRequired,
    LBL_LegalDocument_CursorRequired,
    MSG_LegalDocument_ClauseValidated, MSG_LegalDocument_SendToBusinessOwner, MSG_LegalDocument_ClauseOrderSaved,
    MSG_LegalDocument_DraftClausesUpdated,
    MSG_LegalDocument_GlobalVariablesSavedNoClauseAffected,
    MSG_LegalDocument_AllClausesApproved,
    MSG_LegalDocument_AllClausesValidated,
    MSG_LegalDocument_AllCommentsPublished,
    MSG_LegalDocument_AllClausesAndCommentsPublished,
    MSG_LegalDocument_SupplierAlreadyHasDocument,
    MSG_LegalDocument_ClauseUpdatedSuccessfully,
    MSG_LegalDocument_NoChangesMade,
    MSG_LegalDocument_ClauseDeleted,
    MSG_LegalDocument_ClauseMarkedForDeletion,
    MSG_LegalDocument_SentToSuppliers,
    MSG_LegalDocument_SelectAtLeastOneSupplier,
    MSG_LegalDocument_ClauseAddedSuccessfully,
    MSG_LegalDocument_EnterClauseText,
    MSG_LegalDocument_StartTypingNewVersion,
    MSG_LegalDocument_NoPreviousVersion,
    MSG_LegalDocument_SelectVersion,
    MSG_LegalDocument_PdfExportSuccess,
    MSG_LegalDocument_PdfExportError,
    MSG_LegalDocument_PdfLibraryNotLoaded,
    MSG_LegalDocument_SentToSuppliersDocument,
    MSG_LegalDocument_NoContent, MSG_LegalDocument_NewVersionCreated,
    // LBL_LegalDocument_SupplierSignatory,
    // LBL_LegalDocument_Signatory,
    LBL_Of
}

const RESOURCES = {
    DIFF_MATCH_PATCH,
    JSPDF,
    DOCX_LIB,
}
const ICONS = {
    boIconStyle: 'width:40px;height:40px;background-image: url(' + BusinessOwnerIcon + ');background-size: contain;background-position: left;background-repeat: no-repeat;',
    addIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/PlusIconEmpty.png`,
    bellIcon: `${NEGOPTIM_ICONS}/NegoptimIcons/BellIcon.png`,
    sendIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/send.png`,
    validationIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/Validation.png`,
    editIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/edit.png`,
    deleteIconWoBgURL: `${NEGOPTIM_ICONS}/NegoptimIcons/DeleteIconWoBg.png`,
    previewIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/Eye_Icon_1.png`,
    wordIconUrl: `${NEGOPTIM_ICONS}/NegoptimIcons/Document.png`,
    illustrationUrl: illustrationUrl,
}

//objects
import LegalDoc_c from '@salesforce/schema/LegalDoc__c';
import LegalDocClause__c from '@salesforce/schema/LegalDocClause__c';
import TrackAction__c from '@salesforce/schema/TrackAction__c';
import Supplier_OBJ from '@salesforce/schema/Supplier__c';
import Contact_OBJ from '@salesforce/schema/Contact';
import GlobalLocation_OBJ from '@salesforce/schema/GlobalLocation__c';
import ContactOperationalDirectory_OBJ from '@salesforce/schema/ContactOperationalDirectory__c';
/**
* LegalDoc__c Fields
*/
import Type__c from '@salesforce/schema/LegalDoc__c.Type__c';
import Market__c from '@salesforce/schema/LegalDoc__c.Market__c';
import Language__c from '@salesforce/schema/LegalDoc__c.Language__c';
import LegalDocStatus__c from '@salesforce/schema/LegalDoc__c.Status__c';
import LegalDocPartnerStatus__c from '@salesforce/schema/LegalDoc__c.PartnerStatus__c';
import Name from '@salesforce/schema/LegalDoc__c.Name';
import Year__c from '@salesforce/schema/LegalDoc__c.Year__c';
import CreatedDate from '@salesforce/schema/LegalDoc__c.CreatedDate';
import CreatedById from '@salesforce/schema/LegalDoc__c.CreatedById';
import LastModifiedDate from '@salesforce/schema/LegalDoc__c.LastModifiedDate';
import Supplier__c from '@salesforce/schema/LegalDoc__c.Supplier__c';
import DateSentToSupplier__c from '@salesforce/schema/LegalDoc__c.DateSentToSupplier__c';
import LegalLastPublishDate__c from '@salesforce/schema/LegalDoc__c.LegalLastPublishDate__c';
import PartnerLastModifyDate__c from '@salesforce/schema/LegalDoc__c.PartnerLastModifyDate__c';
import PartnerLastPublishDate__c from '@salesforce/schema/LegalDoc__c.PartnerLastPublishDate__c';
import PartnerValidateDate__c from '@salesforce/schema/LegalDoc__c.PartnerValidateDate__c';
import PartnerApproveDate__c from '@salesforce/schema/LegalDoc__c.PartnerApproveDate__c';
import LegalLastModifyDate__c from '@salesforce/schema/LegalDoc__c.LegalLastModifyDate__c';
import LegalValidateDate__c from '@salesforce/schema/LegalDoc__c.LegalValidateDate__c';
import LegalApproveDate__c from '@salesforce/schema/LegalDoc__c.LegalApproveDate__c';
import BusinessOwnerLastModifyDate__c from '@salesforce/schema/LegalDoc__c.BusinessOwnerLastModifyDate__c';
import BusinessOwnerLastPublishDate__c from '@salesforce/schema/LegalDoc__c.BusinessOwnerLastPublishDate__c';
import BusinessOwnerValidateDate__c from '@salesforce/schema/LegalDoc__c.BusinessOwnerValidateDate__c';
import BusinessOwnerApproveDate__c from '@salesforce/schema/LegalDoc__c.BusinessOwnerApproveDate__c';
import HasNoSalesTerms__c from '@salesforce/schema/LegalDoc__c.HasNoSalesTerms__c';
import WhoValidated__c from '@salesforce/schema/LegalDoc__c.WhoValidated__c';
import ValidationDate__c from '@salesforce/schema/LegalDoc__c.ValidationDate__c';
import WhoApproved__c from '@salesforce/schema/LegalDoc__c.WhoApproved__c';
import ApproveDate__c from '@salesforce/schema/LegalDoc__c.ApproveDate__c';
import LegalIsPlayer__c from '@salesforce/schema/LegalDoc__c.LegalIsPlayer__c';
import PartnerIsPlayer__c from '@salesforce/schema/LegalDoc__c.PartnerIsPlayer__c';
import DocBOAccountingIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOAccountingIsPlayer__c';
import DocBOMarketingIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOMarketingIsPlayer__c';
import DocBOOfferIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOOfferIsPlayer__c';
import DocBOComplianceIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOComplianceIsPlayer__c';
import DocBOAfterSalesIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOAfterSalesIsPlayer__c';
import DocBOQualityIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOQualityIsPlayer__c';
import DocBOSupplyChainIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOSupplyChainIsPlayer__c';
import DocBOBuyerIsPlayer__c from '@salesforce/schema/LegalDoc__c.BOBuyerIsPlayer__c';
/**
* LegalDocClause__c Fields
*/
import Status__c from '@salesforce/schema/LegalDocClause__c.Status__c';
import LegalStatus__c from '@salesforce/schema/LegalDocClause__c.LegalStatus__c';
import PartnerStatus__c from '@salesforce/schema/LegalDocClause__c.PartnerStatus__c';
import BusinessStatus__c from '@salesforce/schema/LegalDocClause__c.BusinessStatus__c';
import UpdateOrigin__c from '@salesforce/schema/LegalDocClause__c.UpdateOrigin__c';
import ClauseType__c from '@salesforce/schema/LegalDocClause__c.ClauseType__c';
import BusinessOwners__c from '@salesforce/schema/LegalDocClause__c.BusinessOwners__c';
import Clause__c from '@salesforce/schema/LegalDocClause__c.Clause__c';
import DisplayOrder__c from '@salesforce/schema/LegalDocClause__c.DisplayOrder__c';
import IsNegotiable__c from '@salesforce/schema/LegalDocClause__c.IsNegotiable__c';
import LegalDocClauseP1__c from '@salesforce/schema/LegalDocClause__c.LegalDocClauseP1__c';
import LegalDocClauseField__c from '@salesforce/schema/LegalDocClause__c.LegalDocClause__c';
import Updatedby__c from '@salesforce/schema/LegalDocClause__c.Updatedby__c';
import ClauseL1__c from '@salesforce/schema/LegalDocClause__c.ClauseL1__c';
import ClauseL2__c from '@salesforce/schema/LegalDocClause__c.ClauseL2__c';
import LegalDoc__c from '@salesforce/schema/LegalDocClause__c.LegalDoc__c';
import Version__c from '@salesforce/schema/LegalDocClause__c.Version__c';
import LegalClauseSupplier__c from '@salesforce/schema/LegalDocClause__c.Supplier__c';
import OwnerId from '@salesforce/schema/LegalDocClause__c.OwnerId';
import ClauseBOAccountingIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOAccountingIsPlayer__c';
import ClauseBOMarketingIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOMarketingIsPlayer__c';
import ClauseBOOfferIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOOfferIsPlayer__c';
import ClauseBOComplianceIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOComplianceIsPlayer__c';
import ClauseBOAfterSalesIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOAfterSalesIsPlayer__c';
import ClauseBOQualityIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOQualityIsPlayer__c';
import ClauseBOSupplyChainIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOSupplyChainIsPlayer__c';
import ClauseBOBuyerIsPlayer__c from '@salesforce/schema/LegalDocClause__c.BOBuyerIsPlayer__c';
import ClausePartnerLastPublishDate__c from '@salesforce/schema/LegalDocClause__c.PartnerLastPublishDate__c';
import ClauseLegalLastPublishDate__c from '@salesforce/schema/LegalDocClause__c.LegalLastPublishDate__c';

/*
*
* TrackAction__c fields 
*/
import CommentStatus__c from '@salesforce/schema/TrackAction__c.CommentStatus__c';
import IsPortalPublished__c from '@salesforce/schema/TrackAction__c.IsPortalPublished__c';
import Comment__c from '@salesforce/schema/TrackAction__c.Comment__c';
import CommentOrigin__c from '@salesforce/schema/TrackAction__c.CommentOrigin__c';
import ParentId__c from '@salesforce/schema/TrackAction__c.ParentId__c';
/*
*
* Supplier__c fields 
*/
import Account__c from '@salesforce/schema/Supplier__c.Account__c';
import Signatory__c from '@salesforce/schema/Supplier__c.Signatory__c';
/*
*
* GlobalLocation__c fields 
*/
import Country__c from '@salesforce/schema/GlobalLocation__c.Country__c';
/*
* Contact__c fields 
*/
import Contact__c from '@salesforce/schema/ContactOperationalDirectory__c.Contact__c';
/*
* ContactOperationalDirectory__c fields 
*/
import MainFrameworkSignatory__c from '@salesforce/schema/Contact.MainFrameworkSignatory__c';

const LegalDoc_API = {
    LegalDoc_c: LegalDoc_c.objectApiName,
    Type__c: Type__c.fieldApiName,
    Market__c: Market__c.fieldApiName,
    Language__c: Language__c.fieldApiName,
    Status__c: LegalDocStatus__c.fieldApiName,
    PartnerStatus__c: LegalDocPartnerStatus__c.fieldApiName,
    Name: Name.fieldApiName,
    Year__c: Year__c.fieldApiName,
    CreatedDate: CreatedDate.fieldApiName,
    CreatedById: CreatedById.fieldApiName,
    LastModifiedDate: LastModifiedDate.fieldApiName,
    Supplier__c: Supplier__c.fieldApiName,
    DateSentToSupplier__c: DateSentToSupplier__c.fieldApiName,
    LegalLastPublishDate__c: LegalLastPublishDate__c.fieldApiName,
    PartnerLastModifyDate__c: PartnerLastModifyDate__c.fieldApiName,
    PartnerLastPublishDate__c: PartnerLastPublishDate__c.fieldApiName,
    PartnerValidateDate__c: PartnerValidateDate__c.fieldApiName,
    PartnerApproveDate__c: PartnerApproveDate__c.fieldApiName,
    LegalLastModifyDate__c: LegalLastModifyDate__c.fieldApiName,
    LegalValidateDate__c: LegalValidateDate__c.fieldApiName,
    LegalApproveDate__c: LegalApproveDate__c.fieldApiName,
    BusinessOwnerLastModifyDate__c: BusinessOwnerLastModifyDate__c.fieldApiName,
    BusinessOwnerLastPublishDate__c: BusinessOwnerLastPublishDate__c.fieldApiName,
    BusinessOwnerValidateDate__c: BusinessOwnerValidateDate__c.fieldApiName,
    BusinessOwnerApproveDate__c: BusinessOwnerApproveDate__c.fieldApiName,
    HasNoSalesTerms__c: HasNoSalesTerms__c.fieldApiName,
    WhoValidated__c: WhoValidated__c.fieldApiName,
    ValidationDate__c: ValidationDate__c.fieldApiName,
    WhoApproved__c: WhoApproved__c.fieldApiName,
    ApproveDate__c: ApproveDate__c.fieldApiName,
    LegalIsPlayer__c: LegalIsPlayer__c.fieldApiName,
    PartnerIsPlayer__c: PartnerIsPlayer__c.fieldApiName,
    Supplier__r: Supplier__c.fieldApiName.replace(/__c$/, '__r'),
    WhoValidated__r: WhoValidated__c.fieldApiName.replace(/__c$/, '__r'),
}

const LegalDocClause_API = {
    LegalDocClause__c: LegalDocClause__c.objectApiName,
    Status__c: Status__c.fieldApiName,
    LegalStatus__c: LegalStatus__c.fieldApiName,
    PartnerStatus__c: PartnerStatus__c.fieldApiName,
    BusinessStatus__c: BusinessStatus__c.fieldApiName,
    UpdateOrigin__c: UpdateOrigin__c.fieldApiName,
    ClauseType__c: ClauseType__c.fieldApiName,
    BusinessOwners__c: BusinessOwners__c.fieldApiName,
    Updatedby__c: Updatedby__c.fieldApiName,
    Clause__c: Clause__c.fieldApiName,
    ClauseL2__c: ClauseL2__c.fieldApiName,
    ClauseL1__c: ClauseL1__c.fieldApiName,
    DisplayOrder__c: DisplayOrder__c.fieldApiName,
    Supplier__c: LegalClauseSupplier__c.fieldApiName,
    IsNegotiable__c: IsNegotiable__c.fieldApiName,
    Version__c: Version__c.fieldApiName,
    LegalDoc__c: LegalDoc__c.fieldApiName,
    LegalDocClauseP1__c: LegalDocClauseP1__c.fieldApiName,
    LegalDocClauseField__c: LegalDocClauseField__c.fieldApiName,
    LegalLastPublishDate__c: ClauseLegalLastPublishDate__c.fieldApiName,
    PartnerLastPublishDate__c: ClausePartnerLastPublishDate__c.fieldApiName,
    OwnerId: OwnerId.fieldApiName,
    Updatedby__r: Updatedby__c.fieldApiName.replace(/__c$/, '__r')
}
const TrackAction_API = {
    TrackAction__c: TrackAction__c.objectApiName,
    CommentStatus__c: CommentStatus__c.fieldApiName,
    IsPortalPublished__c: IsPortalPublished__c.fieldApiName,
    Comment__c: Comment__c.fieldApiName,
    CommentOrigin__c: CommentOrigin__c.fieldApiName,
    ParentId__c: ParentId__c.fieldApiName
}

const Supplier_API = {
    Supplier__c: Supplier_OBJ.objectApiName,
    Account__c: Account__c.fieldApiName,
    Signatory__c: Signatory__c.fieldApiName,
}
const COD_API = {
    ContactOperationalDirectory__c: ContactOperationalDirectory_OBJ.objectApiName,
    Contact__c: Contact__c.fieldApiName,
}
const Contact_API = {
    Contact__c: Contact_OBJ.objectApiName,
    MainFrameworkSignatory__c: MainFrameworkSignatory__c.fieldApiName,
}
const GlobalLocation_API = {
    GlobalLocation_OBJ: GlobalLocation_OBJ.objectApiName,
    Country__c: Country__c.fieldApiName,
    Country__r: Country__c.fieldApiName.replace(/__c$/, '__r'),
}

const clauseBoFieldMap = {
    Accounting: ClauseBOAccountingIsPlayer__c.fieldApiName,
    Marketing: ClauseBOMarketingIsPlayer__c.fieldApiName,
    Offer: ClauseBOOfferIsPlayer__c.fieldApiName,
    Compliance: ClauseBOComplianceIsPlayer__c.fieldApiName,
    AfterSales: ClauseBOAfterSalesIsPlayer__c.fieldApiName,
    Quality: ClauseBOQualityIsPlayer__c.fieldApiName,
    SupplyChain: ClauseBOSupplyChainIsPlayer__c.fieldApiName,
    Buyer: ClauseBOBuyerIsPlayer__c.fieldApiName
};

const docBoFieldMap = {
    Accounting: DocBOAccountingIsPlayer__c.fieldApiName,
    Marketing: DocBOMarketingIsPlayer__c.fieldApiName,
    Offer: DocBOOfferIsPlayer__c.fieldApiName,
    Compliance: DocBOComplianceIsPlayer__c.fieldApiName,
    AfterSales: DocBOAfterSalesIsPlayer__c.fieldApiName,
    Quality: DocBOQualityIsPlayer__c.fieldApiName,
    SupplyChain: DocBOSupplyChainIsPlayer__c.fieldApiName,
    Buyer: DocBOBuyerIsPlayer__c.fieldApiName
};
const docBoFieldList = [
    DocBOAccountingIsPlayer__c.fieldApiName,
    DocBOMarketingIsPlayer__c.fieldApiName,
    DocBOOfferIsPlayer__c.fieldApiName,
    DocBOComplianceIsPlayer__c.fieldApiName,
    DocBOAfterSalesIsPlayer__c.fieldApiName,
    DocBOQualityIsPlayer__c.fieldApiName,
    DocBOSupplyChainIsPlayer__c.fieldApiName,
    DocBOBuyerIsPlayer__c.fieldApiName
]
export { Labels, RESOURCES, ICONS, clauseBoFieldMap, docBoFieldMap, docBoFieldList, LegalDoc_API, LegalDocClause_API, TrackAction_API, Supplier_API, GlobalLocation_API, COD_API, Contact_API }