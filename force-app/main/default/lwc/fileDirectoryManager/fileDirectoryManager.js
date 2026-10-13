import { LightningElement, track, api, wire } from 'lwc';
import Toast from 'lightning/toast';
import getSettings from '@salesforce/apex/FileDirectoryManagerController.getSettings';
import getDownloadedURL from '@salesforce/apex/FileDirectoryManagerController.getDownloadedURL';
import loadData from '@salesforce/apex/FileDirectoryManagerController.loadData';
import saveData from '@salesforce/apex/FileDirectoryManagerController.saveData';
import confirmShareDocs from '@salesforce/apex/FileDirectoryManagerController.confirmShareDocs';
import getUserLocale from '@salesforce/apex/FileDirectoryManagerController.getUserLocale';
import getSingleContentDocument from '@salesforce/apex/FileDirectoryManagerController.getSingleContentDocument';
import getCustomLabel from '@salesforce/apex/NegoptimLabels.getCustomLabel';
import getCustomLabels from '@salesforce/apex/NegoptimLabels.getCustomLabels';
import uploadMultipleFiles from '@salesforce/apex/FileDirectoryManagerController.uploadMultipleFiles';
import { columnsToRemove, API_NAMES, Labels } from './properties.js';
import DocumentsCenter_SimplesImage from "@salesforce/resourceUrl/DocumentsCenter_SimplesImage";
import ChangeStatus_Icon from '@salesforce/resourceUrl/ChangeStatus_Icon';
import fileDirectorySR_URL from '@salesforce/resourceUrl/fileDirectory';
import Cancelled_Icon from '@salesforce/resourceUrl/Cancelled_Icon';
import { NavigationMixin } from "lightning/navigation";
import UploadFile_Icon from '@salesforce/resourceUrl/UploadFile_Icon';
//STATIC RESOURCES
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Status__c from "@salesforce/schema/FileDirectory__c.Status__c";

const flowStatus = {
    FINISHED: 'FINISHED',
    ERROR: 'ERROR'
}
const showNotification = (self, title, message, variant, mode) => {
    Toast.show({
        label: title,
        message: message,
        variant: variant,
        mode: mode
    }, self);
}
import DISPLAY_LANG from '@salesforce/i18n/lang';
const ICON_SIZE = '22px';

const OPEN_SOURCE_LABELS = {}
export default class FileDirectoryManager extends NavigationMixin(LightningElement) {
    // @api gridKey;
    @api theme;
    @api recordId;
    @track API_NAMES = API_NAMES;
    @track columnsToRemove = columnsToRemove;
    @track isPanelFilter = true;
    changeStatusIconUrl = ChangeStatus_Icon;
    cancelledIconUrl = Cancelled_Icon;
    UploadFile_IconUrl = UploadFile_Icon
    isLoading = false;
    isPortal;
    isAllowApproveDoc;
    isAllowCancelDoc;
    //LABELS
    @track gridManager;
    @track titleWrapper = {};
    @track columns;
    @track fileDirectoryWrapperList = [];
    @track filters = [];
    @track fieldsToFilter = [];
    @track searchableFields;
    @track notLookupFields = [];
    @track lookupFields = [];
    @track appliedfilters = {
        searchValue: '',
        dynamicSearch: '',
    }
    labels = {
        ...Labels,
        ...OPEN_SOURCE_LABELS,
    };
    @track showModal = false;
    @track modalFile = {};
    @track pageSize = 5;
    @track pageNumber = 1;
    get isHomePage() {
        return location.pathname.startsWith('/lightning/page/home');
    }

    get colspanDisplayedFields() {
        let colspan = this.columns.length + 2 + (!this.isHomePage ? 1 : 0);
        return colspan;
    }

    totalPagesCount = 0;
    @track totalNumbOfRecords = 0;
    fieldsToFilterMap = {};
    // Popup
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        isUploadFilePopup: false,
        fdir: null,
    };
    popupMethods = {
        open() {
            this.popup.visibility = true;
        },
        close() {
            this.popup.visibility = false;
        }
    }
    showPopup() {
        return new Promise((resolve) => {
            this._resolvePopup = resolve; // Save the resolve function to call later
        });
    }
    handlePopupAction(event) {
        const data = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        this._resolvePopup(data == 'confirm'); // Resolve the promise with true (if confirm) or false (if cancel)
        this._resolvePopup = null;
    }

    // defaultimageStyle = `background-image:url('/resource/1727781957000/connect_defaults/modules_icons/Documents_Center.png'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
    defaultimageStyle = 'background-image:url(' + connect_defaults + '/modules_icons/Documents_Center.png' + '); aspect-ratio: 1/1; width: 100%; background-size: cover;';
    firstHeaderStyle = 'background-color: #08484B;color:#FFFFFF;text-align:left;font-weight:bold;width:200px;';
    secondHeaderStyle = 'background-color: #08484B;color:#FFFFFF;text-align:center;font-weight:bold;width:200px;';
    firstColumnsStyle = 'background-color: #FFFFFF;color:#262626;width:200px;text-align:left;'
    secondColumnsStyle = 'background-color: #FFFFFF;color:#262626;'
    checkStyle = 'background-color: #08484B;';
    pageSizeOptions = [
        { label: '5', value: 5, isSelected: false },
        { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        { label: '75', value: 75, isSelected: false },
        { label: '100', value: 100, isSelected: false }
    ];
    icons = {
        uploadFile: {
            active: fileDirectorySR_URL + '/UploadFile_Icon2.png',
            inactive: fileDirectorySR_URL + '/InactiveUploadFile_Icon.png',
            activeStyle: `background-image: url("${fileDirectorySR_URL + '/UploadFile_Icon2.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
            inactiveStyle: `background-image: url("${fileDirectorySR_URL + '/InactiveUploadFile_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
        },
        delete: {
            active: fileDirectorySR_URL + '/Delete_Icon.png',
            inactive: fileDirectorySR_URL + '/InactiveDelete_Icon.png',
            activeStyle: `background-image: url("${fileDirectorySR_URL + '/Delete_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
            inactiveStyle: `background-image: url("${fileDirectorySR_URL + '/InactiveDelete_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
        },
        eye: {
            active: fileDirectorySR_URL + '/Eye_Icon.png',
            inactive: fileDirectorySR_URL + '/InactiveEye_Icon.png',
            activeStyle: `background-image: url("${fileDirectorySR_URL + '/Eye_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
            inactiveStyle: `background-image: url("${fileDirectorySR_URL + '/InactiveEye_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
        },
        share: {
            active: fileDirectorySR_URL + '/Share_Icon.png',
            inactive: fileDirectorySR_URL + '/InactiveShare_Icon.png',
            activeStyle: `background-image: url("${fileDirectorySR_URL + '/Share_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
            inactiveStyle: `background-image: url("${fileDirectorySR_URL + '/InactiveShare_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
        },
        confirmation: {
            active: fileDirectorySR_URL + '/Confirmation_Icon.png',
            inactive: fileDirectorySR_URL + '/InactiveConfirmation_Icon.png',
            activeStyle: `background-image: url("${fileDirectorySR_URL + '/Confirmation_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
            inactiveStyle: `background-image: url("${fileDirectorySR_URL + '/InactiveConfirmation_Icon.png'}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`,
        },
    }

    staticUrl = {
        defaultimageStyle: connect_defaults + '/modules_icons/Documents_Center.png',
        theme: {
            smallImages: {
                '{!$Label.LBL_FileDirectoryTemplateTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/1.DocumentsCenterIcon-Templates.png',
                '{!$Label.LBL_FileDirectoryFrameworkAgreementTemplateTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/1.DocumentsCenterIcon-FrameworkAgreementTemplate.png',
                '{!$Label.LBL_FileDirectoryContractDocumentsTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/2.DocumentsCenterIcon-ContractDocument.png',
                '{!$Label.LBL_FileDirectoryProformaInvoiceTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/2.DocumentsCenterIcon-ProformaInvoice.png',
                '{!$Label.LBL_FileDirectorySalesTermsTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/2.DocumentsCenterIcon-SalesTerms.png',
                '{!$Label.LBL_FileDirectoryTariffTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/2.DocumentsCenterIconTariff.png',
                '{!$Label.LBL_FileDirectoryMarketAnalysisTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/3.DocumentsCenterIcon-MarketAnalysis.png',
                '{!$Label.LBL_FileDirectoryBrandingElementsTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/3.DocumentsCenterIcon-BrandingElements.png',
                '{!$Label.LBL_FileDirectoryDatasharingTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/3.DocumentsCenterIcon-Datasharing.png',
                '{!$Label.LBL_FileDirectoryAccountStatusTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/4.DocumentsCenterIcon-AccountStatus.png',
                '{!$Label.LBL_FileDirectoryCreditNoteTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/4.DocumentsCenterIcon-CreditNote.png',
                '{!$Label.LBL_FileDirectoryInvoiceTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/4.DocumentsCenterIcon-Invoice.png',
                '{!$Label.LBL_FileDirectoryPaymentTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/4.DocumentsCenterIcon-Payment.png',
                '{!$Label.LBL_FileDirectoryPenaltyTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/4.DocumentsCenterIcon-Penalty.png',
                '{!$Label.LBL_FileDirectoryCertificationsTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/5.DocumentsCenterIcon-Certifications.png',
                '{!$Label.LBL_FileDirectoryComplianceAuditTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/5.DocumentsCenterIcon-ComplianceAudit.png',
                '{!$Label.LBL_FileDirectoryEthicalChartTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/5.DocumentsCenterIcon-EthicalChart.png',
                '{!$Label.LBL_FileDirectoryScorecardTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/5.DocumentsCenterIconScorecard.png',
                '{!$Label.LBL_FileDirectoryAdminCertificationTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/6.DocumentsCenterIcon-AdminCertification.png',
                '{!$Label.LBL_FileDirectoryAdvertisingMaterialsTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/3.DocumentsCenterIcon-AdvertisingMaterials.png',
                '{!$Label.LBL_FileDirectoryBankingDocumentTheme}': DocumentsCenter_SimplesImage + '/DocumentsCenter-SimplesImage/6.DocumentsCenterIcon-BankingDocument.png',
            }
        }
    }
    //WIRES
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Status__c }) statusPickListValues({ error, data }) {
        if (data) {
            for (let item of data.values) {
                this.statusesMap[item.value] = item.label;
            }
        } else {
            console.log(error);
        }
    }
    validateImageUrl(url) {
        return new Promise((resolve) => {
            const image = document.createElement('img');
            image.style.display = 'none';

            image.onload = () => {
                document.body.removeChild(image);
                resolve(true);
            };

            image.onerror = () => {
                document.body.removeChild(image);
                resolve(false);
            };

            image.src = url;
            document.body.appendChild(image);
        });
    }
    // GETTERS
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }
    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }
    uploadIconStyle = `background-image: url("${UploadFile_Icon}"); background-repeat: no-repeat; background-size: contain; background-position: center; width:${ICON_SIZE}; height:${ICON_SIZE};`;
    connectedCallback() {
        let labels = this.labels;
        getUserLocale().then(locale => {
            this.userLocale = locale;
        }).catch(error => {
            console.error('Failed to fetch locale', error);
            this.userLocale = 'en_US';
        });
        if (Object.keys(OPEN_SOURCE_LABELS).length) {
            getCustomLabels({
                labelsTranslationMapJSON: JSON.stringify(OPEN_SOURCE_LABELS),
                language: DISPLAY_LANG
            }).then((res) => {
                if (res) {
                    res = JSON.parse(res);
                    Object.keys(res).forEach(labelApiName => {
                        labels[labelApiName] = res[labelApiName];
                    });
                }
            }).catch((err) => {
                console.log('%c' + err.message, 'color : red');
            });
        }
        this.initData();
    }

    renderedCallback() {
        this.setPageSize();
        const content = this.template.querySelector('.custom-modal');
        const header = this.template.querySelector('.custom-header');
        const modalContent = this.template.querySelector('.custom-content');

        if (content && header) {
            content.onscroll = () => {
                const scrollTop = content.scrollTop;
                header.style.backgroundColor = scrollTop > 0 ? '#000000BF' : '#000000';
            };
        }
        if (header && modalContent) {
            const headerHeight = header.offsetHeight;
            const windowHeight = window.innerHeight;
            const contentHeight = windowHeight - headerHeight;
            modalContent.style.height = `${contentHeight}px`;
            modalContent.style.backgroundColor = `#686868D9`;
        }
    }
    initData() {
        let labels = this.labels;
        this.isLoading = true;
        getSettings({
            gridKey: this.theme,
            recordId: this.recordId,
            language: DISPLAY_LANG
        }).then(result => {
            let parsedResult = JSON.parse(result);
            Object.keys(parsedResult.fieldsLabel).forEach(labelApiName => {
                labels[labelApiName] = parsedResult.fieldsLabel[labelApiName];
            });
            this.titleWrapper.themeTitle = this.extractLabel(parsedResult.theme) ? this.handleGetCustomLabel(parsedResult.theme) : parsedResult.theme;
            this.validateImageUrl(parsedResult.image).then(value => {
                if (!value) {
                    parsedResult.image = this.staticUrl.theme.smallImages[parsedResult.themeLabel] ? this.staticUrl.theme.smallImages[parsedResult.themeLabel] : this.staticUrl.defaultimageStyle;
                }
                this.titleWrapper.image = parsedResult.image ? `background-image:url('${parsedResult.image}'); aspect-ratio: 1/1; width: 100%; background-size: cover;` : this.defaultimageStyle
            })
            this.isPortal = parsedResult.isPortal;
            this.isAllowApproveDoc = parsedResult.isAllowApproveDoc;
            this.isAllowCancelDoc = parsedResult.isAllowCancelDoc;
            this.allowUpload = parsedResult.allowUpload;
            this.allowedStatusesForUpload = parsedResult.allowedStatusesForUpload;
            this.allowMultipleUpload = parsedResult.allowMultipleUpload;
            this.allowDelete = parsedResult.allowDelete;
            this.allowedStatusesForDelete = parsedResult.allowedStatusesForDelete;
            this.allowSharing = parsedResult.allowSharing;
            this.allowedStatusesForShare = parsedResult.allowedStatusesForShare;
            this.allowReceiptConfirmation = parsedResult.allowReceiptConfirmation;
            this.allowedStatusesForReceiptConfirmation = parsedResult.allowedStatusesForReceiptConfirmation;
            this.loadData(parsedResult.dataWrapper.gridSettingsManager)
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }
    statusesMap = {};
    loadData(gridManager) {
        let statusesMap = this.statusesMap;
        this.gridManager = gridManager;
        this.pageSize = parseInt(this.gridManager.Default_Page_Size);
        this.columns = this.gridManager.GRID_FIELDS.map(item => ({
            ...item,
            fieldName: item.fieldName.replace(/^negoptim__/, 'Negoptim__'),
        }));
        this.columns.forEach(element => {
            element.headerCssStyle = element.widthStyle + (element.headerStyle ? element.headerStyle.style : 'background: #f3f3f3;')
            element.headerTitle = element.fieldName == "RecordType.Name" ? this.labels.LBL_Record_Type : element.fieldLabel
            if (element.fieldName == API_NAMES.Status__c && element.pickListValues && element.pickListValues.length > 0) {
                element.pickListValues.forEach(picklist => {
                    statusesMap[picklist.value] = picklist.label;
                });
            }
        });
        this.columns.filter(element => element.isSearchable).forEach(element => {
            if (element.stringFieldType == 'REFERENCE') {
                if (!this.lookupFields.includes(element.fieldName)) {
                    this.lookupFields.push(element.fieldName)
                }
            }
            else {
                if (!this.notLookupFields.includes(element.fieldName)) {
                    this.notLookupFields.push(element.fieldName)
                }
            }
        });
        this.notLookupFields.push(API_NAMES.FilePreview__c);
        this.columns = this.columns.filter(column => !this.columnsToRemove.includes(column.fieldName));
        let names = this.columns.map(field => field.fieldName);

        let file_field = this.gridManager?.FILTERS?.map(item => ({
            ...item,
            fieldName: item.fieldName.replace(/^negoptim__/, 'Negoptim__'),
        })).find(filter => filter.fieldName == API_NAMES.FilePreview__c);
        if (file_field) {
            file_field.userFilterable = true;

            file_field.fieldLabel = this.labels.LBL_FileDirectoryFileName;
            file_field.values = [];
            this.filters.push(file_field)
        }
        // Status label handling
        let status_field = this.gridManager?.FILTERS?.map(item => ({
            ...item,
            fieldName: item.fieldName.replace(/^negoptim__/, 'Negoptim__'),
        })).find(filter => filter.fieldName == API_NAMES.Status__c);
        if (status_field) {
            status_field.userFilterable = true;
            status_field.fieldLabel = this.labels.LBL_Status__c;
            status_field.values = [];
            this.filters.push(status_field);
        }

        this.gridManager?.FILTERS.map(item => ({
            ...item,
            fieldName: item.fieldName.replace(/^negoptim__/, 'Negoptim__'),
        })).forEach(filter_field => {
            if (names.includes(filter_field.fieldName)) {
                this.filters.push(filter_field)
            }
        });
        this.populateFiltersMap(this.filters);
        this.afterLoad(false);
    }
    afterLoad(isSearch) {
        this.fileDirectoryWrapperList = [];
        loadData({
            recordId: this.recordId,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            gridsettingsJSON: JSON.stringify(this.gridManager),
            filtersJSON: JSON.stringify(this.appliedfilters),
            isSearch: isSearch,
            lookupFields: this.lookupFields,
            notLookupFields: this.notLookupFields,
            language: DISPLAY_LANG
        }).then((result) => {
            try {
                let parsedResult = JSON.parse(result);
                this.fileDirectoryWrapperList = this.buildDataWrapper(parsedResult.fileDirectoryrecords);
                this.selectedPageSize = this.pageSizeOptions.find(element => element.value == this.pageSize).value;
                this.totalPagesCount = Math.ceil((parsedResult.totalSize / this.pageSize));
                this.totalNumbOfRecords = parsedResult.totalSize;
                this.isLoading = false;
            } catch (error) {
                console.log('ERROR: ' + error?.body?.message || error?.message || error);
                showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            }
        }).catch(error => {
            console.error(error);
            console.log('ERROR: ' + error?.body?.message || error?.message || error);
            // showNotification(this,LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.isLoading = false;
        });
    }
    buildDataWrapper(data) {
        data.forEach(fdir => {
            fdir.statusOptions = [];
            if (fdir[API_NAMES.Status__c] == 'Sent' /*|| fdir[API_NAMES.Status__c] == 'Requested'*/) {
                fdir.statusOptions.push({ label: this.statusesMap['Receipt Confirmed'], value: 'Receipt Confirmed' })
            }
            if (fdir[API_NAMES.Status__c] != 'Rejected' && this.isAllowApproveDoc) {
                fdir.statusOptions.push({ label: this.statusesMap['Rejected'], value: 'Rejected' })
            }
            if (fdir[API_NAMES.Status__c] != 'Validated' && this.isAllowApproveDoc) {
                fdir.statusOptions.push({ label: this.statusesMap['Validated'], value: 'Validated' })
            }
            if (fdir[API_NAMES.Status__c] != 'Cancelled' && this.isAllowCancelDoc) {
                fdir.statusOptions.push({ label: this.statusesMap['Cancelled'], value: 'Cancelled' })
            }
            fdir.canPreview = fdir[API_NAMES.ContentDocumentId__c] ? true : false;
            // fdir.shareIconStyle = fdir[API_NAMES.IsPortalPublished__c] == true ? '--slds-c-icon-color-foreground-default: red;' : ' --slds-c-icon-color-foreground-default: green;';
            fdir.helpIconText = fdir[API_NAMES.IsPortalPublished__c] == true ? this.labels.LBL_FileDirectory_UnshareWithSupplierTitle : this.labels.LBL_FileDirectory_shareWithSupplierTitle;
            fdir.isSelected = false;
            fdir.canUpload = this.allowUpload
                && (this.allowedStatusesForUpload || []).includes(fdir[API_NAMES.Status__c]);
            fdir.canDelete = fdir.canPreview
                && this.allowUpload
                && (this.allowedStatusesForUpload || []).includes(fdir[API_NAMES.Status__c]);
            fdir.NumberOfDownloads__c = fdir[API_NAMES.NumberOfDownloads__c] ?? 0;
            fdir.NumberOfViews__c = fdir[API_NAMES.NumberOfViews__c] ?? 0;
            // fdir.FilePreview__c = this.isPortal ? fdir[API_NAMES.FilePreview__c] : `<div class = "slds-text-link">${fdir[API_NAMES.DocumentName__c]}</div>`;
            fdir.FilePreview__c = fdir[API_NAMES.FilePreview__c];
            fdir.StatusLogoURL__c = fdir[API_NAMES.StatusLogoURL__c];
            fdir._Status__c = this.statusesMap[fdir[API_NAMES.Status__c]] || fdir[API_NAMES.Status__c];
            fdir.isShared = fdir[API_NAMES.IsPortalPublished__c] == true;
            fdir.canShare = !this.isPortal
                && this.allowSharing
                && (this.allowedStatusesForShare || []).includes(fdir[API_NAMES.Status__c]);
            fdir.canShareOrConfirmReceipt = ![
                'Framework Agreement Template',
                'Other',
                'RSE',
                'Admin Certification',
                'Certifications',
                'Tariff',
                'Sales Terms'
            ].includes(fdir[API_NAMES.SubType__c]);
            fdir.canConfirm = (fdir[API_NAMES.ContentDocumentId__c] ? true : false)
                && this.allowReceiptConfirmation
                && (this.allowedStatusesForReceiptConfirmation || []).includes(fdir[API_NAMES.Status__c])
                && ((fdir[API_NAMES.ReceiptConfirmedBy__c] == 'Retailer' && !this.isPortal) || (fdir[API_NAMES.ReceiptConfirmedBy__c] == 'Supplier' && this.isPortal));
            fdir.handleUploadFinished = async (event) => {
                this.popup.body = null;
                this.popup.visibility = false;
                this.popup.isUploadFilePopup = false;
                const fileIds = event?.detail?.files?.filter(it => it.documentId)?.map(it => it.documentId) || [];
                if (fileIds.length) {
                    // Get the list of uploaded files
                    uploadMultipleFiles({
                        fileListJson: JSON.stringify(fileIds),
                        parentId: fdir.Id
                    }).then(async result => {
                        this.popup.body = this.labels.MSG_SuccessUpload;
                        this.popup.submitBtn = this.labels.LBL_Ok;
                        this.popup.cancelBtn = null;
                        this.popup.visibility = true;
                        await this.showPopup();
                        this.popup.visibility = false;
                        showNotification(this, this.labels.LBL_Success, this.labels.MSG_Connect_FileUploadSuccess, 'success');
                        this.afterLoad(true);
                    });
                }
            }
            fdir.handleMultiUploadClick = async (event) => {
                const index = event.target.dataset.index;
                let _fdir = this.fileDirectoryWrapperList[index];
                if (_fdir.canPreview) {
                    this.popup.body = this.labels.LBL_ReplaceDocument.replace('{0}', _fdir[API_NAMES.DocumentName__c]);
                    this.popup.submitBtn = this.labels.LBL_Ok;
                    this.popup.submitBtnClass = 'slds-button slds-button_brand';
                    this.popup.cancelBtn = this.labels.LBL_Cancel;
                    this.popup.visibility = true;
                    const confirmed = await this.showPopup();
                    this.popup.visibility = false;
                    if (!confirmed) {
                        return;
                    }
                }
                setTimeout(async () => {
                    this.popup.body = null;
                    this.popup.submitBtn = this.labels.LBL_Ok;
                    this.popup.submitBtnClass = 'slds-button slds-button_brand';
                    this.popup.cancelBtn = this.labels.LBL_Cancel;
                    this.popup.fdir = _fdir;
                    this.popup.isUploadFilePopup = true;
                    this.popup.visibility = true;
                    const confirmed = await this.showPopup();
                    this.popup.visibility = false;
                    this.popup.isUploadFilePopup = false;
                    if (!confirmed) {
                        return;
                    }
                }, 5);
            };

            let fields = [];
            this.columns.forEach(element => {
                fields.push({
                    label: element.fieldLabel,
                    value: null,
                    name: element.fieldName,
                    isHTMLFormatted: element.isHTMLFormatted,
                    isNumberField: element.fieldType == 'NUMBER' || element.fieldType == 'DOUBLE' || element.isNumberField,
                    isReference: element.fieldType == 'REFERENCE',
                    isDate: element.fieldType == 'DATE' || element.fieldType == 'DATETIME',
                    isPicklist: element.fieldType == 'PICKLIST',
                    isBoolean: element.fieldType == 'BOOLEAN',
                    isReferenceText: element.fieldType == 'STRING' && element.isReference,
                    isText: element.fieldType == 'STRING' && !element.isReference,
                    cellstyle: element.style,
                    translatedOptions: element.fieldType == 'PICKLIST' ? element.pickListValues : null
                })
            });
            fields.forEach(field => {
                if (field.isReference) {
                    if (field.name.endsWith('Id')) {
                        field.value = fdir[field.name.replace('Id', '')]?.Name;
                    } else {
                        field.value = fdir[field.name.replace('__c', '__r')]?.Name;
                    }
                    field.link = '/' + fdir[field.name];
                }
                else if (field.isPicklist) {
                    let found = field.translatedOptions.find(item => item.value === fdir[field.name]);
                    field.value = found?.label;

                }
                else if (field.isReferenceText) {
                    let splitted_Field = field.name.split('.');
                    field.value = fdir[splitted_Field[0]]?.[splitted_Field[1]];
                } else if (field.isNumberField) {
                    field.value = fdir[field.name] ? fdir[field.name] : 0;
                }
                else {
                    field.value = fdir[field.name];
                }
            });
            fdir.columns = fields;
        });
        return data;
    }
    populateFiltersMap(fields) {
        this.fieldsToFilterMap = {};
        for (let field of fields) {
            let fieldToFilter = {};
            if (SUPPORTED_TYPES.includes(field.stringFieldType)
                || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
                || field.hasOwnProperty('userFilterable')) {
                fieldToFilter.fieldLabel = field.fieldLabel;
                fieldToFilter.fieldName = field.fieldName;
                fieldToFilter.stringFieldType = field.stringFieldType;
                fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
                if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
                if (field.stringFieldType === 'ID') {
                    if (field.values) fieldToFilter.displayVal = field.values.join(';');
                    fieldToFilter.isId = true;
                }
                fieldToFilter.isText = field.stringFieldType == 'STRING';
                fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
                fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType === 'PICKLIST' || field.stringFieldType === 'MULTIPICKLIST' || field.stringFieldType === 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
                if (fieldToFilter.isCheckboxGroup) {
                    fieldToFilter.options = field.stringFieldType === 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
                }
                fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
                if (fieldToFilter.isNumber) {
                    if (field.stringFieldType === 'DOUBLE') {
                        fieldToFilter.formatter = 'decimal';
                    }
                    if (field.stringFieldType === 'CURRENCY') {
                        fieldToFilter.formatter = 'currency';
                    }
                    if (field.stringFieldType === 'PERCENT') {
                        fieldToFilter.formatter = 'percent-fixed';
                    }
                    let step = '.';
                    for (let i = 0; i < field.scale; i++) {
                        if (i == field.scale - 1) {
                            step += '1';
                            break;
                        }
                        step += '0';
                    }
                    fieldToFilter.step = step;
                }
                fieldToFilter.isDate = field.stringFieldType == 'DATE' || field.stringFieldType == 'DATETIME';
                fieldToFilter.isTime = field.stringFieldType == 'TIME';
                if (field.hasOwnProperty('isEncrypted')) {
                    fieldToFilter.isEncrypted = field.isEncrypted;
                }
                if (SUPPORTED_VALUES_TYPES.includes(field.stringFieldType)
                    || (field.stringFieldType === 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
                    if (field.values) {
                        if (fieldToFilter.isText || fieldToFilter.isReference) {
                            fieldToFilter.value = (field.values[0]) ? field.values[0] : '';
                            fieldToFilter.values = field.values;
                        } else {
                            fieldToFilter.values = field.values;
                        }
                    } else {
                        fieldToFilter.values = '';
                    }
                }
                if (SUPPORTED_RANGE_TYPES.includes(field.stringFieldType)) {
                    fieldToFilter.value1 = (field.value1) ? field.value1 : '';
                    fieldToFilter.value2 = (field.value2) ? field.value2 : '';
                }
                //list to display
                if (Object.keys(fieldToFilter).length !== 0) {
                    this.fieldsToFilterMap[fieldToFilter.fieldName] = fieldToFilter;
                }
            }
        }
        this.populateLists(this.fieldsToFilterMap);
    }
    populateLists(filtersMap) {
        this.fieldsToFilter = [];
        if (Object.keys(filtersMap).length !== 0) {
            this.fieldsToFilter = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //get record type field
            var recordTypeField = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === false && filtersMap[fieldName].stringFieldType === 'RECORDTYPE')
                .map(fieldName => { return filtersMap[fieldName]; });
            //add record type fields always to the top
            if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
            this.multilevelFields = Object.keys(filtersMap)
                .filter(fieldName => filtersMap[fieldName].isMultiLevel === true)
                .map(fieldName => { return filtersMap[fieldName]; });
            this.fieldsToFilter.forEach(item => {
                if (item.isText || item.isReference) {
                    item.value = item.values.length != 0 ? item.values[0] : '';
                }
            })
        }
    }
    handleSaveData(item, notification, callback, errCallback) {
        saveData({
            FileDirectoryJSON: JSON.stringify(item)
        }).then(result => {
            if (notification && result == 'SUCCESS') {
                showNotification(this, this.labels.LBL_Success, notification, 'success');
            }
            if (callback && typeof callback === 'function') {
                callback();
            }
            this.afterLoad(true);
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            if (errCallback && typeof errCallback === 'function') {
                errCallback();
            }
            this.isLoading = false;
        })
    }
    async handleConfirmReceipt(event) {
        let index = event.target.dataset.index;
        this.popup.body = this.labels.LBL_ConfirmReceiptDialog;
        this.popup.submitBtn = this.labels.LBL_Ok;
        this.popup.submitBtnClass = 'slds-button slds-button_brand';
        this.popup.cancelBtn = this.labels.LBL_Cancel;
        this.popup.visibility = true;
        const confirmed = await this.showPopup();
        if (!confirmed) {
            this.popup.visibility = false;
            return;
        }
        this.popup.visibility = false;
        this.fileDirectoryWrapperList[index][API_NAMES.Status__c] = 'Receipt Confirmed';
        this.fileDirectoryWrapperList[index][API_NAMES.IsReceiptConfirmed__c] = true;
        let item = {
            Id: this.fileDirectoryWrapperList[index].Id,
            [API_NAMES.Status__c]: 'Receipt Confirmed',
            [API_NAMES.IsReceiptConfirmed__c]: true,
        }
        const successCallback = async () => {
            this.popup.body = this.labels.MSG_SuccessReceipt;
            this.popup.submitBtn = this.labels.LBL_Ok;
            this.popup.cancelBtn = null;
            this.popup.visibility = true;
            await this.showPopup();
            this.popup.visibility = false;
        }
        const errCallback = async () => {
            // handle err
        }
        this.handleSaveData(item, this.labels.MSG_DocumentsCenter_ConfirmReceiptSuccess, successCallback, errCallback);
    }

    async handleTruncateDocument(event) {
        let selectedRecordIndex = event.target.dataset.index;
        this.popup.body = this.labels.LBL_ConfirmReset;
        this.popup.submitBtn = this.labels.LBL_Ok;
        this.popup.submitBtnClass = 'slds-button slds-button_brand';
        this.popup.cancelBtn = this.labels.LBL_Cancel;
        this.popup.visibility = true;
        const confirmed = await this.showPopup();
        if (!confirmed) {
            this.popup.visibility = false;
            return;
        }
        this.popup.visibility = false;

        let item = {
            Id: this.fileDirectoryWrapperList[selectedRecordIndex].Id,
            [API_NAMES.ContentDocumentId__c]: null
        }
        const successCallback = async () => {
            this.popup.body = this.labels.MSG_SuccessReset;
            this.popup.submitBtn = this.labels.LBL_Ok;
            this.popup.cancelBtn = null;
            this.popup.visibility = true;
            await this.showPopup();
            this.popup.visibility = false;
        }
        const errCallback = async () => {
            // handle err
        }
        // this.handleSaveData(item, this.labels.MSG_Successfully_Saved, successCallback, errCallback);
        this.handleSaveData(item, null, successCallback, errCallback);
    }

    async handleShareDocs(event) {
        let index = event.target.dataset.index;
        let isPortalPublished = this.fileDirectoryWrapperList[index][API_NAMES.IsPortalPublished__c];
        let item = {
            Id: this.fileDirectoryWrapperList[index].Id,
            [API_NAMES.ContentDocumentId__c]: this.fileDirectoryWrapperList[index][API_NAMES.ContentDocumentId__c],
            [API_NAMES.IsPortalPublished__c]: this.fileDirectoryWrapperList[index][API_NAMES.IsPortalPublished__c]
        }
        // let msgTitle = this.fileDirectoryWrapperList[index][API_NAMES.IsPortalPublished__c] ? this.labels.MSG_DocumentsCenterUnshareFileConfirmation :
        //     this.labels.MSG_DocumentsCentershareFileConfirmation;
        // let confirm = window.confirm(msgTitle);
        this.popup.body = !isPortalPublished ? this.labels.LBL_ConfirmShare : this.labels.LBL_ConfirmUnshare;
        this.popup.submitBtn = this.labels.LBL_Ok;
        this.popup.submitBtnClass = 'slds-button slds-button_brand';
        this.popup.cancelBtn = this.labels.LBL_Cancel;
        this.popup.visibility = true;
        const confirmed = await this.showPopup();
        if (!confirmed) {
            this.popup.visibility = false;
            return;
        }
        this.popup.visibility = false;
        const successCallback = async () => {
            this.popup.body = !isPortalPublished ? this.labels.MSG_SuccessShare : this.labels.MSG_SuccessUnshare;
            this.popup.submitBtn = this.labels.LBL_Ok;
            this.popup.cancelBtn = null;
            this.popup.visibility = true;
            await this.showPopup();
            this.popup.visibility = false;
        }
        confirmShareDocs({
            FileDirectoryJSON: JSON.stringify(item)
        }).then(result => {
            let errormsg = result;
            this.afterLoad(true);
            if (isPortalPublished) {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_DocumentsCenter_UnshareFileSuccess, 'success')
            } else if (!isPortalPublished) {
                showNotification(this, this.labels.LBL_Success, this.labels.MSG_DocumentsCenter_ShareFileSuccess, 'success')
            }
            successCallback();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.isLoading = false;
        })
    }
    registerViewCount(event) {
        let index = event.target.dataset.index;
        let fileDirectory = this.fileDirectoryWrapperList[index];
        let contentDocumentId = fileDirectory[API_NAMES.ContentDocumentId__c];
        if (!contentDocumentId) return;
        fileDirectory.NumberOfViews__c++;
        fileDirectory.columns.find(element => element.name == API_NAMES.NumberOfViews__c).value++;
        this.handleSaveData({ Id: fileDirectory.Id, [API_NAMES.NumberOfViews__c]: fileDirectory.NumberOfViews__c }, null);
    }
    openFileDirectory(event) {
        let index = event.target.dataset.index;
        let fileDirectory = this.fileDirectoryWrapperList[index];
        let contentDocumentId = fileDirectory[API_NAMES.ContentDocumentId__c];
        if (!contentDocumentId) return;
        this.fetchAndShowDocument(contentDocumentId);
        fileDirectory.NumberOfViews__c++;
        fileDirectory.columns.find(element => element.name == API_NAMES.NumberOfViews__c).value++;
        this.handleSaveData({ Id: fileDirectory.Id, [API_NAMES.NumberOfViews__c]: fileDirectory.NumberOfViews__c }, null);
    }
    @track isImage = false;
    fetchAndShowDocument(contentDocumentId) {
        getSingleContentDocument({
            contentDocumentId
        }).then(doc => {
            this.isImage = ['JPG', 'JPEG', 'PNG', 'GIF', 'SVG', 'PNG'].includes(doc.FileType);
            let file = {
                ...doc,
                thumbnail: `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${doc.Id}&operationContext=CHATTER&contentId=${doc.ContentDocumentId}`,
                url: `/sfc/servlet.shepherd/document/download/${doc.ContentDocumentId}`,
                iconName: this.mapFileTypeToIcon(doc.FileType),
                size: this.fileSizeToString(doc.ContentSize)
            };
            this.modalFile = file;
            this.showModal = true;
        }).catch(error => {
            console.error('Error fetching document: ', error);
        });
    }

    get modalContentClass() {
        let baseClass = 'slds-modal__content custom-content';
        return this.isImage ? `${baseClass} slds-align_absolute-center` : baseClass;
    }

    closeModal() {
        this.showModal = false;
    }

    mapFileTypeToIcon(type) {
        const map = new Map([
            ['WORD_X', 'doctype:word'],
            ['EXCEL_X', 'doctype:excel'],
            ['PDF', 'doctype:pdf'],
            ['CSV', 'doctype:csv'],
            ['JPG', 'doctype:image'],
            ['SVG', 'doctype:image']
        ]);
        return map.get(type) || 'doctype:attachment';
    }

    fileSizeToString(value) {
        if (value < 1024) return `${value} Bytes`;
        else if (value < 1024 * 1024) return `${(value / 1024).toFixed(2)} KB`;
        else if (value < 1024 * 1024 * 1024) return `${(value / (1024 * 1024)).toFixed(2)} MB`;
        else return `${(value / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }

    navigateToFiles(contentDocumentId) {
        if (!this.isPortal) {
            this[NavigationMixin.Navigate]({
                type: "standard__namedPage",
                attributes: {
                    pageName: "filePreview",
                },
                state: {
                    selectedRecordId: contentDocumentId,
                },
            });
        }
    }

    setSearchTerm(event) {
        this.appliedfilters.searchValue = event.detail.value;
        this.afterLoad(true);
    }

    toggleFilter() {
        let filterSecion = this.template.querySelector('.filter-section');
        if (filterSecion) {
            filterSecion.classList.toggle('slds-hide');
        }
    }
    setSelectedValues(event) {
        var value = event.detail.value;
        if (event.target.dataset.checkbox) {
            value = event.detail.checked;
        }
        var fieldName = event.target.name;
        var modeValue = event.target.dataset.mode;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field.values = [];
            if (modeValue === 'multiple') {
                let withoutSpace = value.replaceAll(' ', '');
                field.displayVal = withoutSpace;
                let idList = withoutSpace.split(';');
                for (let id of idList) {
                    if (id !== '') {
                        field.values.push(id);
                    }
                }
            } else {
                field.values = (Array.isArray(value)) ? value : [value];
            }
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }

    }
    setSelectedRangeValue(event) {
        var value = event.detail.value;
        var fieldName = event.target.name;
        var rangeValue = event.target.dataset.range;
        if (this.fieldsToFilterMap[fieldName]) {
            let field = this.fieldsToFilterMap[fieldName];
            field[rangeValue] = value;
            this.fieldsToFilterMap[fieldName] = field;
            this.populateLists(this.fieldsToFilterMap);
        }
    }
    confirmFilter() {
        let selection = [];
        try {
            selection = Object.keys(this.fieldsToFilterMap).filter(fieldName =>
            (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable') ||
                (this.fieldsToFilterMap[fieldName].values &&
                    (this.fieldsToFilterMap[fieldName].values.length > 1
                        || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== '')))
                || (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '')
                || (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '')))
                .map(fieldName => {
                    let item = {};
                    item.fieldName = fieldName;
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('stringFieldType')) {
                        item.stringFieldType = this.fieldsToFilterMap[fieldName].stringFieldType;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('userFilterable')) {
                        item.userFilterable = this.fieldsToFilterMap[fieldName].userFilterable;
                    }
                    if (this.fieldsToFilterMap[fieldName].hasOwnProperty('isEncrypted')) {
                        item.isEncrypted = this.fieldsToFilterMap[fieldName].isEncrypted;
                    }
                    if (this.fieldsToFilterMap[fieldName].values &&
                        (this.fieldsToFilterMap[fieldName].values.length > 1
                            || (this.fieldsToFilterMap[fieldName].values.length == 1 && this.fieldsToFilterMap[fieldName].values[0] !== ''))) {
                        item.values = this.fieldsToFilterMap[fieldName].values;
                        return item;
                    }
                    if (this.fieldsToFilterMap[fieldName].value1 && this.fieldsToFilterMap[fieldName].value1 !== '') {
                        item.value1 = this.fieldsToFilterMap[fieldName].value1;
                    }
                    if (this.fieldsToFilterMap[fieldName].value2 && this.fieldsToFilterMap[fieldName].value2 !== '') {
                        item.value2 = this.fieldsToFilterMap[fieldName].value2;
                    }
                    return item;
                }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('userFilterable')));
            this.appliedfilters.dynamicSearch = JSON.stringify(selection);
            this.afterLoad(false);
        } catch (error) {
            console.log(error);
        }
    }
    handleReset() {
        this.appliedfilters = {
            searchValue: '',
            dynamicSearch: '',
        };
        this.afterLoad(false);
        this.populateFiltersMap(this.filters);
    }

    handleChangePage(event) {
        this.isLoading = true;
        try {
            let type = event.target.dataset.type;
            if (type == 'Previous') {
                this.pageNumber--;
            } else if (type == 'Next') {
                this.pageNumber++;
            } else if (type == 'First') {
                this.pageNumber = 1;
            } else if (type == 'Last') {
                this.pageNumber = this.totalPagesCount;
            }
            this.afterLoad(false);
        } catch (error) {
            console.error(error)
        }
    }
    handleChangePageSize(event) {
        try {
            this.pageSize = parseInt(event.target.value);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value == this.pageSize;
            }
            this.pageNumber = 1;
            this.afterLoad(false);
        }
        catch (error) {
            console.error('error: ' + error);
        }
    }

    get pagesBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + (this.fileDirectoryWrapperList?.length > 0 ? 1 : 0) - pageSize) + '-' + (this.pageNumber * pageSize > this.totalNumbOfRecords ? this.totalNumbOfRecords : this.pageNumber * pageSize) + ' ' + this.labels.LBL_Of + ' ' + this.totalNumbOfRecords;
    }

    selectFileDirectory(event) {
        try {
            let index = event.target.dataset.index;
            let value = event.target.checked;
            this.fileDirectoryWrapperList[index].isSelected = value;
        } catch (error) {
            console.error('error: ' + error);
        }
    }
    handleDownloadFile() {
        let contentDocumentIdList = [];
        let filesToBeDownloaded = this.fileDirectoryWrapperList?.filter(el => el.isSelected);
        if (filesToBeDownloaded.length != 0) {
            filesToBeDownloaded.forEach(file => {
                if (file[API_NAMES.ContentDocumentId__c] != null) {
                    file.NumberOfDownloads__c++;
                    file.columns.find(element => element.name == API_NAMES.NumberOfDownloads__c).value++;
                    this.handleSaveData({ Id: file.Id, [API_NAMES.NumberOfDownloads__c]: file.NumberOfDownloads__c }, null)
                    contentDocumentIdList.push(file[API_NAMES.ContentDocumentId__c])
                }
            });
            if (contentDocumentIdList.length != 0) {
                let url;
                getDownloadedURL({
                    contentDocumentIdList_serialized: JSON.stringify(contentDocumentIdList)
                }).then(result => {
                    url = result;
                    if (url) {
                        // Create an anchor element to trigger the download
                        const link = document.createElement('a');
                        link.href = url;
                        link.target = '_blank'; // Open the file in a new tab (optional)
                        // Append the link to the document body (required for click to work in some browsers)
                        document.body.appendChild(link);

                        // Trigger the download
                        link.click();

                        // Remove the link after triggering the download
                        document.body.removeChild(link);
                    }
                }).catch(error => {
                    console.log('%c' + error.message, 'color : red');
                    console.log('%c' + error.body?.message, 'color : red');
                    this.isLoading = false;
                })
            }
            else {
                showNotification(this, this.labels.LBL_Warning, 'No assigned files', 'Warning')
            }
        }
        else {
            showNotification(this, this.labels.LBL_Warning, this.labels.LBL_selectFileToDownload, 'Warning')
        }
    }

    // action flow
    @track openFlow = false;
    @track currentFlow = {
        header: '',
        flowApiName: '',
        flowVariables: [],
    }

    closeFlow() {
        this.openFlow = false;
    }

    toggleFlow(event) {
        let flowName = event.target.dataset.flowName;
        let flowLabel = event.target.dataset.flowLabel;
        this.isLoading = true;
        let selectedIds = this.fileDirectoryWrapperList?.filter(el => el.isSelected)?.map(f => f.Id) || [];
        this.currentFlow = {
            header: flowLabel,
            flowApiName: flowName,
            flowVariables: []
        }
        let matchedFlow = this.gridManager?.actions?.screenFlows?.find(flow => flow.value == flowName);
        if (matchedFlow) {
            if (matchedFlow.hasRecordId) {
                this.currentFlow.flowVariables.push({
                    name: 'recordId',
                    type: 'String',
                    value: this.recordId
                });
            }
            if (matchedFlow.hasRecordIds) {
                this.currentFlow.flowVariables.push({
                    name: 'recordIds',
                    type: 'String',
                    value: selectedIds
                });
            }
            this.openFlow = !this.openFlow;
        }
        this.isLoading = false;
    }

    get flowActions() {
        return (this.gridManager
            && this.gridManager.actions
            && this.gridManager.actions.screenFlows) || [];
    }

    get iconFlows() {
        return this.flowActions.filter(f => f.value && f.displayType === 'Icon');
    }

    get buttonFlows() {
        return this.flowActions.filter(f => f.value && f.displayType === 'Button');
    }

    get actionFlows() {
        return this.flowActions.filter(f => f.value && f.displayType === 'Action');
    }

    get hasMenu() {
        return this?.actionFlows?.length ? true : false;
    }

    handleflowStatusChange(event) {
        try {
            let status = event?.detail?.status;
            if ([flowStatus.FINISHED, flowStatus.ERROR].includes(status)) {
                if (status == flowStatus.ERROR) {
                    showNotification(this, this.labels.LBL_Error, '', 'error', 'sticky');
                }
                this.openFlow = false;
                this.afterLoad(true);
            }
        } catch (error) {
            showNotification(this, this.labels.LBL_Error, error, 'error', 'sticky');
        }
    }
    extractLabel(data) {
        // Define the regular expression to match the pattern and capture the data after "SLabel."
        const regex = /\{\!\$Label\.(.*?)\}/;
        // Apply the regex to the input string and extract the desired part
        const match = data.match(regex);
        // Check if there's a match and return the captured group
        return match ? match[1] : null;
    }
    handleGetCustomLabel(extractedLabel) {
        getCustomLabel({
            labelName: extractedLabel,
            hardcodedLabel: 'Invalid Data',
            language: DISPLAY_LANG,
        }).then((res) => {
            return res;
        }).catch((error) => {
            showNotification(this, this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
        });
    }
    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".header");
            let pageBody = this.template.querySelector(".bodyDiv");
            let footerDiv = this.template.querySelector(".footerDiv");
            let filterPanelDiv = this.template.querySelector(".filterPanelDiv");
            if (mainContainer != null && pageHeader != null && filterPanelDiv != null && footerDiv != null && pageBody != null) {
                pageBody.style.height = mainContainer.offsetHeight - (pageHeader.offsetHeight + footerDiv.offsetHeight) - 10 + 'px';
                filterPanelDiv.style.height = pageBody.offsetHeight + footerDiv.offsetHeight + 12 + 'px';
            }

        }
        catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }
}