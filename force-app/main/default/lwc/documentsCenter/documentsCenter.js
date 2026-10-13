import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import loadData from '@salesforce/apex/DocumentsCenterController.loadData';
import Documents_Center from '@salesforce/resourceUrl/DocumentsCenter';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";

// OBJECT API NAMES
import NegoScope__c from "@salesforce/schema/NegoScope__c";
import Supplier__c from "@salesforce/schema/Supplier__c";

export default class DocumentsCenter extends LightningElement {
    @api recordId;
    objectApiName;
    @track fileDirectorySettings = [];

    staticUrl = {
        defaultimageStyle: connect_defaults + '/modules_icons/Documents_Center.png',
        section: {
            '{!$Label.LBL_DocumentsCenter_NegotiationPreparationSectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/1.DocumentsCenterSectionIcon-NegoPreparationDocuments.png',
            '{!$Label.LBL_DocumentsCenter_ContractDocumentsSectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/2.DocumentsCenterSectionIcon-ContractDocuments.png',
            '{!$Label.LBL_DocumentsCenter_CollaborationSectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/3.DocumentsCenterSectionIcon-CollaborationDocuments.png',
            '{!$Label.LBL_DocumentsCenter_AccountingSectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/4.DocumentsCenterSectionIcon-AccountingDocuments.png',
            '{!$Label.LBL_DocumentsCenter_QualitySectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/5.DocumentsCenterSectionIcon-QualityDocuments.png',
            '{!$Label.LBL_DocumentsCenter_AdminSectionTitle}': Documents_Center + '/DocumentsCenter/PICTOS/6.DocumentsCenterSectionIcon-AdminDocuments.png',
        },
        theme: {
            '{!$Label.LBL_FileDirectoryTemplateTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-Templates.png',
            '{!$Label.LBL_FileDirectoryFrameworkAgreementTemplateTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-FrameworkAgreementTemplate.png',
            '{!$Label.LBL_FileDirectoryContractDocumentsTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-ContractDocuments.png',
            '{!$Label.LBL_FileDirectoryProformaInvoiceTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-ProformaInvoice.png',
            '{!$Label.LBL_FileDirectorySalesTermsTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-SalesTermsNegotiation.png',
            '{!$Label.LBL_FileDirectoryTariffTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-Tariff.png',
            '{!$Label.LBL_FileDirectoryMarketAnalysisTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-MarketAnalysis.png',
            '{!$Label.LBL_FileDirectoryBrandingElementsTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-BrandingElements.png',
            '{!$Label.LBL_FileDirectoryDatasharingTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-Datasharing.png',
            '{!$Label.LBL_FileDirectoryAccountStatusTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-AccountStatus.png',
            '{!$Label.LBL_FileDirectoryCreditNoteTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-CreditNote.png',
            '{!$Label.LBL_FileDirectoryInvoiceTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Invoice.png',
            '{!$Label.LBL_FileDirectoryPaymentTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Payment.png',
            '{!$Label.LBL_FileDirectoryPenaltyTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Penalty.png',
            '{!$Label.LBL_FileDirectoryCertificationsTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-Certifications.png',
            '{!$Label.LBL_FileDirectoryComplianceAuditTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-ComplianceAudit.png',
            '{!$Label.LBL_FileDirectoryEthicalChartTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-EthicalChart.png',
            '{!$Label.LBL_FileDirectoryScorecardTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-Scorecard.png',
            '{!$Label.LBL_FileDirectoryAdminCertificationTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/6.DocumentsCenterTile-AdminCertification.png',
            '{!$Label.LBL_FileDirectoryAdvertisingMaterialsTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-AdvertisingMaterials.png',
            '{!$Label.LBL_FileDirectoryBankingDocumentTheme}': Documents_Center + '/DocumentsCenter/VIGNETTES/6.DocumentsCenterTile-BankingDocument.png',
        }
    }

    /** ENV FLAGS */
    @track isLoading = true;
    isPortalUser = false;
    @track isFlowActive = false;
    /** FLOW VARIABLES */
    @api selectedFlow;
    @track uploadFlow;
    /* Flow input variables */
    flowInputVariables = {};

    /** FILE DIRECTORY MANAGER VARIABLES */
    @track gridKey;

    /* MODAL FLAGS */
    @track showModal = false;
    @track showFlowModal = false;
    @track showFdmModal = false;

    /** LABELS*/
    labels = {};

    /** IMAGES */
    images = {
        headerImg: Documents_Center + '/DocumentsCenter/HEADER.png'
    }

    /** STYLES */
    @track modalContainerStyle = '';
    @track modalContentStyle = '';
    /** CONST */
    flowStatus = {
        FINISHED: 'FINISHED',
        ERROR: 'ERROR'
    }
    flowInput = {
        recordId: { name: 'recordId', type: 'String' }
    }
    flowModalContainerStyle = 'margin: auto; padding: 30px; width: fit-content; min-width: 50%;';
    modalContext = {
        flow: {
            value: 'flow',
            fullScreenModalContainerStyle: '',
            fullScreenModalContentStyle: ''
        },
        fdm: {
            value: 'fileDirectoryManager',
            fullScreenModalContainerStyle: 'margin: 0px; padding: 30px; width: 100%; min-width: 100%;',
            fullScreenModalContentStyle: 'height: 100%'
        }
    }
    scrollOffset = 150;
    scrollBehavior = {
        smooth: 'smooth'
    }
    toastEventMode = {
        dismissable: 'dismissable',
        sticky: 'sticky'
    }
    toastEventVariant = {
        error: 'error',
        success: 'success'
    }

    /**LIFE CYCLE */
    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        console.log('this.uploadFlow: ' + this.uploadFlow)
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                this.recordId = pageRef.state.c__recordId != null ? pageRef.state.c__recordId : this.recordId;
                this.init();
            }
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }

    init() {
        try {
            this.loadData();
        } catch (error) {
            this.handleError(error, 'init');
        }
    }

    loadData() {
        try {
            console.log('loading data')
            this.isLoading = true;
            loadData({ recordId: this.recordId }).then((result) => {
                let parsedResult = JSON.parse(result);
                this.labels = { ...this.labels, ...parsedResult.fieldsLabel };
                console.log('parsedResult: ' + JSON.stringify(parsedResult));
                this.afterLoad(parsedResult);
                this.isLoading = false;
            }).catch(error => {
                this.handleError(error, 'loadData (apex)');
            });
        } catch (error) {
            this.handleError(error, 'loadData');
        }
    }

    afterLoad(parsedResult) {
        try {
            this.isPortalUser = parsedResult.isPortal;
            this.uploadFlow = parsedResult.flowApiName;
            console.log('this.uploadFlow: ' + this.uploadFlow)
            console.log('this.isPortalUser: ' + this.isPortalUser)
            this.isFlowActive = parsedResult.isFlowActive;
            console.log('this.isFlowActive: ' + this.isFlowActive)
            this.objectApiName = parsedResult.objectApiName;
            console.log('this.objectApiName: ' + this.objectApiName)
            if (Array.isArray(parsedResult.fileDirectorySettings)) {
                parsedResult.fileDirectorySettings.sort((a, b) => {
                    return a.displayOrder - b.displayOrder;
                });
            }
            parsedResult.fileDirectorySettings.forEach(section => {
                // Handle section icon
                if (!section.sectionIcon) {
                    if (Object.keys(this.staticUrl.section).includes(section.sectionTitle)) {
                        section.sectionIcon = this.staticUrl.section[section.sectionTitle];
                    } else {
                        section.sectionIcon = this.staticUrl.defaultimageStyle;
                    }
                }
                // Handle section themes
                section.themesSettings.forEach(theme => {
                    // Handle theme visibilty
                    theme.showTheme = this.isPortalUser ? theme.isPortalDisplayed : theme.isDisplayed;
                    // Handle theme icon
                    if (!theme.largeThemeImage) {
                        if (Object.keys(this.staticUrl.theme).includes(theme.theme)) {
                            theme.largeThemeImage = this.staticUrl.theme[theme.theme];
                        } else {
                            theme.largeThemeImage = this.staticUrl.defaultimageStyle;
                        }
                    }
                    theme.themeKey = theme.theme.replace('{!$Label.', '').replace('}', '');
                });
                // Handle section visibility
                section.showSection = section.themesSettings.some(theme => theme.showTheme);
            });

            this.fileDirectorySettings = parsedResult.fileDirectorySettings;

            console.log('this.fileDirectorySettings: ' + JSON.stringify(this.fileDirectorySettings))
            console.table(this.fileDirectorySettings);
        } catch (error) {
            this.handleError(error, 'afterLoad');
        }
    }


    /** HANDLERS */
    handleSectionBtnClick(event) {
        try {
            const sectionId = event.target.dataset.sectionId;
            const sections = this.template.querySelectorAll(`[data-section-target-id="${sectionId}"]`);
            if (sections.length > 0) {
                const sectionElement = sections[0];
                const rect = sectionElement.getBoundingClientRect();
                window.scrollTo({
                    top: rect.top + window.scrollY - this.scrollOffset,
                    behavior: this.scrollBehavior.smooth
                });
            }
        } catch (error) {
            this.handleError(error, 'handleSectionBtnClick');
        }
    }

    handleOpenModal(event) {
        try {
            let context = event.target.dataset.context;
            if (context == this.modalContext.flow.value && this.isFlowActive) {
                this.modalContainerStyle = this.modalContext.flow.fullScreenModalContainerStyle;
                this.modalContentStyle = this.modalContext.flow.fullScreenModalContentStyle;
                this.showFlowModal = true;
                this.showFdmModal = false;
                this.flowInputVariables = [
                    {
                        name: this.flowInput.recordId.name,
                        type: this.flowInput.recordId.type,
                        value: this.recordId ?? ''
                    }
                ];
                console.log('this.flowInputVariables: ' + JSON.stringify(this.flowInputVariables))
                this.showModal = true;
            }

            if (context == this.modalContext.fdm.value) {
                this.gridKey = event.detail.gridKey;
                console.log('this.gridKey: ' + this.gridKey);
                this.modalContainerStyle = this.modalContext.fdm.fullScreenModalContainerStyle;
                this.modalContentStyle = this.modalContext.fdm.fullScreenModalContentStyle;
                this.showFlowModal = false;
                this.showFdmModal = true;
                this.showModal = true;
            }
        } catch (error) {
            this.handleError(error, 'handleOpenModal');
        }

    }

    handleCloseModal() {
        this.showModal = false;
        this.showFdmModal = false;
        this.showFlowModal = false;
    }

    handleflowStatusChange(event) {
        try {
            let status = event.detail.status;
            if (status == this.flowStatus.FINISHED) {
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_DocumentsCenter_FileUploadSuccess, this.toastEventVariant.success);
                this.handleCloseModal();
            } else if (status == this.flowStatus.ERROR) {
                this.showNotification(this.labels.LBL_Error, this.labels.MSG_DocumentsCenter_FileUploadError, this.toastEventVariant.error);
                this.handleCloseModal();
            }
        } catch (error) {
            this.handleError(error, 'handleflowStatusChange');
        }
    }

    /** UTILS */
    showNotification(title, message, variant, mode) {
        try {
            let evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode ? mode : this.toastEventMode.dismissable
            });
            this.dispatchEvent(evt);
        } catch (error) {
            this.handleError(error, 'showNotification');
        }
    }

    handleError(error, location) {
        try {
            const errorMessage = error && typeof error === 'object'
                ? error?.body?.message || error?.message || JSON.stringify(error)
                : error;
            this.showNotification(this.labels.LBL_Error, errorMessage, this.toastEventVariant.error, this.toastEventMode.sticky);
            const logStyle = 'color: white; background-color: red; padding: 4px 8px; border-radius: 4px; font-weight: bold;';
            console.error('%cError: ' + location, logStyle, errorMessage);
        } catch (internalError) {
            console.error('Error in handleError: ' + internalError);
            console.error('Error in handleError: ' + JSON.stringify(internalError));
        }
    }


}