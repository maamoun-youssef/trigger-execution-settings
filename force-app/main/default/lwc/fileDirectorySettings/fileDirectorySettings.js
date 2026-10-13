import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import loadFileDirectorySettings from '@salesforce/apex/FileDirectorySettingsController.loadFileDirectorySettings';
import uploadSectionImage from '@salesforce/apex/FileDirectorySettingsController.uploadSectionImage';
import save from '@salesforce/apex/FileDirectorySettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/FileDirectorySettingsController.checkDeploymentStatus';
import deleteFileDirectorySettings from '@salesforce/apex/FileDirectorySettingsController.deleteFileDirectorySettings';
import uploadImage from '@salesforce/apex/FileDirectorySettingsController.uploadImage';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
import DocumentsCenter_SimplesImage from "@salesforce/resourceUrl/DocumentsCenter_SimplesImage";
import { labels } from './properties.js';
import getCustomLabel from '@salesforce/apex/NegoptimLabels.getCustomLabel';
import getCustomLabels from '@salesforce/apex/NegoptimLabels.getCustomLabels';
import DocumentsCenter from '@salesforce/resourceUrl/DocumentsCenter'
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX.toLowerCase().replace(/__/gi, '') + '-' : 'c-'}file-directory-settings`;
import Status__c from "@salesforce/schema/FileDirectory__c.Status__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import DISPLAY_LANG from '@salesforce/i18n/lang';

const OPEN_SOURCE_LABELS = {}
export default class FileDirectorySettings extends LightningElement {

    Events = {
        handleThemesChangeStatus: 'handlethemeschangestatus'
    };
    //LABELS
    labels = {
        ...labels,
        ...OPEN_SOURCE_LABELS,
    };
    isLoading = false;
    checkRelationData = false;
    themeOptions = [];
    saveStatus = false;
    // static
    staticUrl = {
        defaultimageStyle: connect_defaults + '/modules_icons/Documents_Center.png',
        section: {
            '{!$Label.LBL_DocumentsCenter_NegotiationPreparationSectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/1.DocumentsCenterSectionIcon-NegoPreparationDocuments.png',
            '{!$Label.LBL_DocumentsCenter_ContractDocumentsSectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/2.DocumentsCenterSectionIcon-ContractDocuments.png',
            '{!$Label.LBL_DocumentsCenter_CollaborationSectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/3.DocumentsCenterSectionIcon-CollaborationDocuments.png',
            '{!$Label.LBL_DocumentsCenter_AccountingSectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/4.DocumentsCenterSectionIcon-AccountingDocuments.png',
            '{!$Label.LBL_DocumentsCenter_QualitySectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/5.DocumentsCenterSectionIcon-QualityDocuments.png',
            '{!$Label.LBL_DocumentsCenter_AdminSectionTitle}': DocumentsCenter + '/DocumentsCenter/PICTOS/6.DocumentsCenterSectionIcon-AdminDocuments.png',
        },
        theme: {
            largeImages: {
                '{!$Label.LBL_FileDirectoryTemplateTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-Templates.png',
                '{!$Label.LBL_FileDirectoryFrameworkAgreementTemplateTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-FrameworkAgreementTemplate.png',
                '{!$Label.LBL_FileDirectoryContractDocumentsTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-ContractDocuments.png',
                '{!$Label.LBL_FileDirectoryProformaInvoiceTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-ProformaInvoice.png',
                '{!$Label.LBL_FileDirectorySalesTermsTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-SalesTermsNegotiation.png',
                '{!$Label.LBL_FileDirectoryTariffTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/2.DocumentsCenterTile-Tariff.png',
                '{!$Label.LBL_FileDirectoryMarketAnalysisTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-MarketAnalysis.png',
                '{!$Label.LBL_FileDirectoryBrandingElementsTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-BrandingElements.png',
                '{!$Label.LBL_FileDirectoryDatasharingTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-Datasharing.png',
                '{!$Label.LBL_FileDirectoryAccountStatusTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-AccountStatus.png',
                '{!$Label.LBL_FileDirectoryCreditNoteTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-CreditNote.png',
                '{!$Label.LBL_FileDirectoryInvoiceTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Invoice.png',
                '{!$Label.LBL_FileDirectoryPaymentTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Payment.png',
                '{!$Label.LBL_FileDirectoryPenaltyTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/4.DocumentsCenterTile-Penalty.png',
                '{!$Label.LBL_FileDirectoryCertificationsTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-Certifications.png',
                '{!$Label.LBL_FileDirectoryComplianceAuditTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-ComplianceAudit.png',
                '{!$Label.LBL_FileDirectoryEthicalChartTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-EthicalChart.png',
                '{!$Label.LBL_FileDirectoryScorecardTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/5.DocumentsCenterTile-Scorecard.png',
                '{!$Label.LBL_FileDirectoryAdminCertificationTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/6.DocumentsCenterTile-AdminCertification.png',
                '{!$Label.LBL_FileDirectoryAdvertisingMaterialsTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/3.DocumentsCenterTile-AdvertisingMaterials.png',
                '{!$Label.LBL_FileDirectoryBankingDocumentTheme}': DocumentsCenter + '/DocumentsCenter/VIGNETTES/6.DocumentsCenterTile-BankingDocument.png',
            },
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
    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: Status__c }) statusPickListValues;
    get statusOptionsStr() {
        return JSON.stringify(this?.statusPickListValues?.data?.values || []);
    }
    @track popup = {
        visibility: false,
        title: '',
        body: '',
    };
    popupMethods = {
        open() {
            this.popup.visibility = true;
        },
        close() {
            this.popup.visibility = false;
        }

    }

    // tracked properties
    @track settingsList = [];
    @track currentThemes = [];
    @track relatedSectionOptions = [];
    @track themeOptions = {};
    @track allStatuses = [];
    @track mainPanelHeight;
    @track newThemes = [];
    currentThemeLabel;
    /*
    * helper methods
    */
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

    sortSettingsList() {
        if (Array.isArray(this.settingsList)) {
            this.settingsList.sort((a, b) => {
                return a.displayOrder - b.displayOrder;
            });
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
    //LIFECYCLE
    connectedCallback() {
        let labels = this.labels;
        Promise.all([]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
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
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item {
                background: #806BBF;
                height: 60px;
                width: 230px;
                border-bottom: 2px solid white;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item .slds-icon {
                --slds-c-icon-color-foreground: white;
            }
            ${classPrefix} .slds-vertical-tabs__link {
                color: white;
                font-size: 14px;
                height: 60px;
                font-weight: 600;
            }
            ${classPrefix} .slds-vertical-tabs__link:hover {
                background: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item:hover {
                background: white;
                color: #806BBF;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .slds-vertical-tabs__nav-item a:hover,
            .slds-vertical-tabs__nav-item a:focus {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .slds-vertical-tabs {
                border-radius: 0px 0px 0px 5px;
                border: none;
            }
            ${classPrefix} .slds-vertical-tabs__left-icon {
                --slds-c-icon-color-foreground-default: white;
            }
            ${classPrefix} lightning-tab-bar {
                width: 230px;
                background: #806BBF;
                height: auto;
            }
            ${classPrefix} .slds-vertical-tabs__nav {
                width: var(--lwc-sizeXSmall, 12rem);
                border-right: var(--lwc-borderWidthThin, 1px) solid var(--slds-g-color-border-base-1, var(--lwc-colorBorder, rgb(229, 229, 229)));
                background: var(--slds-g-color-neutral-base-95, var(--lwc-colorBackground, rgb(243, 243, 243)));
            }

            @media screen and (max-width: 980px) {
                ${classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${classPrefix} .slds-vertical-tabs__nav-item {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${classPrefix} .slds-vertical-tabs__link {
                    font-size: 13px;
                    font-weight: 400;
                    height: 60px;
                }
                ${classPrefix} lightning-tab-bar {
                    width: 190px;
                }
                .slds-vertical-tabs__nav {
                border-right: none;
                background: none;
                }
            }
        `;
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        tabStyleHover.innerText = `
            ${classPrefix} .tab-set-style a:hover {
                color: #806BBF;
                background-color: white;
                text-decoration: none;
            }
            ${classPrefix} .tab-set-style a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a {
                color: #806BBF;
                font-weight: 600;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {
                color: #806BBF;
                background: white;
            }
            ${classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${classPrefix} .slds-tabs_default__item:hover .slds-tabs_default__link {
                color: black;
            }
        `;
        document.body.appendChild(tabStyleHover);
        this.loadData();
    }

    renderedCallback() {
        if (this.template.querySelector('.settings-header')) {
            this.changeHeight();
        }
    }

    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.settings-header') != null) {
            headerHeight = this.template.querySelector('.settings-header').getBoundingClientRect().height;
        }
        let mainPanelHeight;
        if (window.innerWidth < 980) {
            mainPanelHeight = window.innerHeight - headerHeight - 170;
        } else {
            mainPanelHeight = window.innerHeight - headerHeight - 120;
        }
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
    };
    //LOAD DATA
    loadData() {
        this.isLoading = true;
        loadFileDirectorySettings().then(result => {
            let parsedResult = JSON.parse(result);
            this.themeOptions = Object.keys(parsedResult.themeOptions).map(key => ({
                value: key,
                label: parsedResult.themeOptions[key]
            }));
            this.afterload(parsedResult.settings);
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.isLoading = false;
        })
    }

    afterload(data) {
        this.settingsList = [...data];
        this.sortSettingsList()
        this.settingsList.forEach(element => {
            this.relatedSectionOptions.push(
                {
                    label: element.sectionTitle,
                    value: element.sectionTitle,
                }
            );
            this.validateImageUrl(element.sectionIcon).then(value => {
                let image = element.sectionIcon;
                if (!value) {
                    image = this.staticUrl.section[element.sectionTitle] ? this.staticUrl.section[element.sectionTitle] : this.staticUrl.defaultimageStyle;
                }
                element.sectionIconStyle = `background-image:url('${image}'); aspect-ratio: 1/1; width: 35px; background-size: cover; height:35px; translate: 0px 4px;`
            })
            element?.themesSettings?.forEach(theme => {
                Object.defineProperty(theme, "_allowedStatusesForUpload", {
                    get() {
                        return JSON.stringify(this.allowedStatusesForUpload || []);
                    },
                });
                Object.defineProperty(theme, "_allowedStatusesForDelete", {
                    get() {
                        return JSON.stringify(this.allowedStatusesForDelete || []);
                    },
                });
                Object.defineProperty(theme, "_allowedStatusesForShare", {
                    get() {
                        return JSON.stringify(this.allowedStatusesForShare || []);
                    },
                });
                Object.defineProperty(theme, "_allowedStatusesForReceiptConfirmation", {
                    get() {
                        return JSON.stringify(this.allowedStatusesForReceiptConfirmation || []);
                    },
                });
                this.validateImageUrl(theme.largeThemeImage).then(value => {
                    let image = theme.largeThemeImage;
                    if (!value) {
                        image = this.staticUrl.theme.largeImages[theme.theme] ? this.staticUrl.theme.largeImages[theme.theme] : this.staticUrl.defaultimageStyle;
                    }
                    theme.largeThemeImageStyle = `background-image:url('${image}'); aspect-ratio: 1/1; height:35px; width: 35px; background-size: cover;`
                })
                this.validateImageUrl(theme.smallThemeImage).then(value => {
                    let image = theme.smallThemeImage;
                    if (!value) {
                        image = this.staticUrl.theme.smallImages[theme.theme] ? this.staticUrl.theme.smallImages[theme.theme] : this.staticUrl.defaultimageStyle;

                        // image = this.staticUrl.defaultimageStyle;
                    }
                    theme.smallThemeImageStyle = `background-image:url('${image}'); aspect-ratio: 1/1; height:35px; width: 35px; background-size: cover;`
                });

            })
        });
        this.relatedSectionOptions = this.settingsList.map(key => ({
            value: key.sectionTitle,
            label: key.sectionTitle
        }));
        this.isLoading = false;
    }

    handleAddSection() {
        let newSection = {};
        newSection.sectionIconStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 35px; background-size: cover;height:35px; translate: 0px 4px;`
        newSection.isNew = true;
        newSection.themesSettings = [];
        newSection.displayOrder = String(this.settingsList.length + 1);
        this.settingsList.push(newSection);
        this.checkRelationData = true;
    }

    handleAddTheme() {
        this.newThemes.push({
            theme: "", // Define properties for the new theme as needed
            relatedSection: this.settingsList[this.currentThemes.index]?.sectionTitle,
            smallThemeImageStyle: `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; height:35px; width: 35px; background-size: cover;`,
            largeThemeImageStyle: `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; height:35px; width: 35px; background-size: cover;`,
            isPortalDisplayed: false,
            isDisplayed: false,
            // NEW CHECKBOXES with default false
            isAllowApproveDocInternal: true,
            isAllowApproveDocExternal: true,
            isAllowCancelDocInternal: true,
            isAllowCancelDocExternal: true,
            gridSettingsName: "", // Provide a default grid name or other default properties
            allowUpload: true,
            allowMultipleUpload: true,
            allowedStatusesForUpload: ['Requested'],
            allowSharing: true,
            allowedStatusesForShare: ['Sent'],
            allowReceiptConfirmation: true,
            allowedStatusesForReceiptConfirmation: ['Sent'],
            get _allowedStatusesForUpload() {
                return JSON.stringify(this.allowedStatusesForUpload || []);
            },
            get _allowedStatusesForDelete() {
                return JSON.stringify(this.allowedStatusesForDelete || []);
            },
            get _allowedStatusesForShare() {
                return JSON.stringify(this.allowedStatusesForShare || []);
            },
            get _allowedStatusesForReceiptConfirmation() {
                return JSON.stringify(this.allowedStatusesForReceiptConfirmation || []);
            },
        });
    }

    handleFieldsEdit(event) {
        let field = event.target.dataset.cell;
        let index = event.target.dataset.index;
        let value = event.detail.value ? event.detail.value : event.target.checked;
        if (field == 'image') {
            this.handleModuleIconChange(event, index);
        }
        else {
            this.settingsList[index][field] = value;
        }
    }

    handleModuleIconChange(event, index) {
        let inputImage = document.createElement('input');
        inputImage.type = 'file';
        inputImage.accept = 'image/*';
        inputImage.onchange = (event) => {
            let file = event.target.files[0];
            let fileName = this?.settingsList[index] ? this?.settingsList[index]?.label : file.name;
            if (!file) {
                this.showNotification('Error', 'Please select a file to upload.', 'error');
                return;
            }
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64data = reader.result.split(',')[1];
                uploadSectionImage({ base64Image: base64data, imageName: fileName }).then(result => {
                    console.log('result: ' + result)
                    // module.iconUrl = result;
                    this.settingsList[index].sectionIconStyle = `background-image:url('${result}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    this.settingsList[index].sectionIcon = result;
                }).catch(error => {
                    console.log('error.message', error)
                    this.showNotification('error :', error.message);
                });
            };
            reader.readAsDataURL(file);
        }
        inputImage.click();
    }

    handleThemeIconChange(event) {
        const isNew = event.currentTarget.dataset?.table === 'new' ? true : false;
        const index = event.currentTarget.dataset?.index;
        const themeIndex = event.currentTarget.dataset?.cell;
        const imageType = event.currentTarget.dataset?.id
        let inputImage = document.createElement('input');
        inputImage.type = 'file';
        inputImage.accept = 'image/*';
        inputImage.onchange = (event) => {
            let file = event.target.files[0];
            let fileName = file.name;
            if (!file) {
                this.showNotification('Error', 'Please select a file to upload.', 'error');
                return;
            }
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64data = reader.result.split(',')[1];
                uploadImage({ base64Image: base64data, imageName: fileName }).then(result => {
                    if (!isNew) {
                        this.settingsList[this.currentThemes.index].themesSettings[themeIndex][`${imageType}Style`] = `background-image:url('${result}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                        this.settingsList[this.currentThemes.index].themesSettings[themeIndex][imageType] = result;
                    } else {
                        this.newThemes[index][`${imageType}Style`] = `background-image:url('${result}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                        this.newThemes[index][imageType] = result;
                    }
                }).catch(error => {
                    this.showNotification('error :', error.message);
                });
            };
            reader.readAsDataURL(file);
        }
        inputImage.click();
    }
    showPopup(isTheme) {
        this.popup.visibility = true;
        this.popup.title = isTheme ? this.labels.LBL_FileDirectory_ThemeDeleteMessageTitle : this.labels.LBL_FileDirectory_SectionDeleteMessageTitle;
        this.popup.body = isTheme ? this.labels.LBL_FileDirectory_ThemeDeleteMessageDescription : this.labels.LBL_FileDirectory_SectionDeleteMessageDescription;
        return new Promise((resolve) => {
            this._resolvePopup = resolve; // Save the resolve function to call later
        });
    }

    handlePopupAction(event) {
        document.body.style.overflowY = 'hidden'
        const data = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        this.popup.visibility = false; // Hide the popup
        this._resolvePopup(data == 'confirm'); // Resolve the promise with true (if confirm) or false (if cancel)
        this._resolvePopup = null;
    }

    async deleteItem(event) {
        const isTheme = event.currentTarget.dataset.cell == 'theme';
        const newTheme = event.currentTarget.dataset.table !== undefined;
        const index = event.currentTarget.dataset.index;
        const userConfirmed = await this.showPopup(isTheme);
        document.body.style.overflowY = 'scroll'
        if (!userConfirmed) {
            this.popup.visibility = false;
            return
        }
        if (!isTheme) {
            if (this.settingsList[index].developerName == '') {
                this.settingsList.splice(index, 1);
                this.popup.visibility = false;
            }
            await deleteFileDirectorySettings({ developerName: this.settingsList[index].developerName })
                .then(res => {
                    this.settingsList.splice(index, 1);
                    this.popup.visibility = false;
                }).catch(error => {
                    this.showNotification('Error', error.body?.message, 'error');
                    this.popup.visibility = false;

                })
        } else {
            if (!newTheme) {
                // Check if the themeSettings array exists and delete the theme

                this.settingsList[this.currentThemes.index].themesSettings.splice(index, 1);

            } else {
                this.newThemes.splice(index, 1);
            }
            this.popup.visibility = false;
        }


    }


    preSave() {
        let isValid = true;
        // add new theme to settingsList
        for (const e of this.newThemes) {
            const settingsListIndex = this.settingsList.findIndex(item => item.sectionTitle == e.relatedSection);
            if (settingsListIndex !== -1) {
                e.isValid = e.gridSettingsName?.trim() && e.theme?.trim() ? true : false;
                delete e.isNew;
                if (e.isValid) {
                    if (this.settingsList[settingsListIndex].themesSettings === null) {
                        this.settingsList[settingsListIndex].themesSettings = [e];
                    } else {
                        this.settingsList[settingsListIndex].themesSettings.push(e);
                    }
                }
                else {
                    isValid = false;
                    break;
                }

            }
        };
        // delete new field and check if section title is empty
        if (this.checkRelationData) {
            for (const e of this.settingsList) {
                if (!e.sectionTitle?.trim()) {   // Checks for empty or undefined titles
                    this.showNotification('Error', labels.LBL_FileDirectory_EmptySection, 'error');
                    this.checkRelationData = true;
                    return false; // Exit the function
                }
                if (e.isNew) {
                    delete e.isNew;
                }
            }
            this.checkRelationData = false;
        }
        this.isLoading = true;
        return true && isValid;
    }

    handleSave() {
        const canProceed = this.preSave();
        if (!canProceed) {
            const invalidTheme = this.newThemes.find(e => e.isValid === false);
            if (invalidTheme !== undefined) {
                this.showNotification(this.labels.LBL_Error, this.labels.LBL_FileDirectory_EmptyTheme, 'error');
            }
            this.isLoading = false;
            return; // Stop the save process
        }
        save({
            FileDirectorySettingsJSON: JSON.stringify(this.settingsList)
        }).then(result => {
            this.newThemes = [];
            this.checkDeployementStatus(result);
            this.sortSettingsList();
        }).catch(error => {
            console.error('Error during save: ', error);
            this.showNotification('Error', error.body.message, 'error');
            this.isLoading = false;
            console.log('isLoading set to false due to error');
        });
    }

    checkDeployementStatus(idDeployment) {
        let self = this;
        let counter = 0;
        let status;
        checkDeploymentStatus({
            'idDeployment': idDeployment,
        }).then(fresult => {
            // self.isLoading = false;
            let fdone = JSON.parse(fresult).deployResult.done;
            status = JSON.parse(fresult).deployResult.status;

            if (!fdone) {
                let interval = setInterval(() => {
                    if (counter > 10) {
                        self.isLoading = false;
                        clearInterval(interval);
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Request_Timed_Out + ' ' + this.labels.MSG_Deploy_Last_Status + ' ' + status);

                    }
                    checkDeploymentStatus({
                        'idDeployment': idDeployment,
                    }).then(result => {
                        let done = JSON.parse(result).deployResult.done;
                        let success = JSON.parse(result).deployResult.success;
                        status = JSON.parse(result).deployResult.status;
                        if (done) {
                            self.loading = false;
                            clearInterval(interval);
                            if (success) {
                                this.allStatuses.push('Success');
                                this.showNotification('Success', this.labels.MSG_Successfully_Saved, 'success', 'dismissible');
                                this.isLoading = false;
                            } else {
                                this.showNotification(this.labels.LBL_Info, this.labels.MSG_Deploy_Ended_With_Status + ' ' + status, 'info');

                                this.isLoading = false;
                            }
                        }
                    });
                    counter++;
                }, 5000);
            } else {
                self.isLoading = false;
                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Save_Complete, 'success');
            }
        });
    }
    //NOTIFICATIONS
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    displayOrderSubmit(event) {
        const index = event.currentTarget.dataset.index;
        const value = event.currentTarget.value;
        const hasDisplayOrder = this.settingsList.some(e => e.displayOrder == value);
        this.saveStatus = false;
        if (this.settingsList[index].displayOrder == value) return;
        if (hasDisplayOrder) {
            event.currentTarget.value = this.settingsList[index].displayOrder;
            this.showNotification('Error', labels.LBL_FileDirectory_DuplicateDisplayOrder, 'error');
        } else {
            this.settingsList[index].displayOrder = value
        }
    }

    handleDocumentCenterSetionInput(event) {
        const index = event.currentTarget.dataset.index;
        const value = event.currentTarget.value.trim();
        const data = event.currentTarget.dataset.id;
        this.relatedSectionOptions = [];

        this.settingsList[index][data] = value;
        this.settingsList.forEach(element => {
            this.relatedSectionOptions.push(
                {
                    label: element.sectionTitle,
                    value: element.sectionTitle,
                }
            );
            element?.themesSettings?.forEach(e => {
                e.relatedSection = element.sectionTitle
            })
        })
        this.validateImageUrl(this.settingsList[index].sectionIcon).then(valid => {
            if (!valid) {
                if (this.staticUrl.section[value] != null) {
                    this.settingsList[index].sectionIconStyle = `background-image:url('${this.staticUrl.section[value]}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                } else if (this.settingsList[index].sectionIconStyle !== `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`) {
                    this.settingsList[index].sectionIconStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                }
            }
        })

    }
    displayCheck(event) {
        const isNew = event.currentTarget.dataset.table === 'new' ? true : false;
        const data = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        const themesSettingsIndex = event.target ? event.currentTarget.dataset.cell : event.target.dataset.cell;
        const value = event.target.checked ? true : false;
        const index = event.target.dataset.index;
        let item = isNew ? this.newThemes[index] : this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndex];
        item[data] = value;
        // if (!item.largeThemeImage) {
        //     this.showNotification('Error', labels.LBL_FileDirectory_DisplayDocumentsCenterWarning, 'warrning');
        // }
    }



    handleThemesInput(event) {
        const isNew = event.currentTarget.dataset.table === 'new' ? true : false;
        const index = event.currentTarget ? event.currentTarget.dataset.index : event.target.dataset.index;
        const fielName = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        const value = event.currentTarget ? event.currentTarget.value.trim() : event.target.dataset.value.trim();

        if (isNew) {
            this.newThemes[index][fielName] = value;
            if (this.staticUrl.theme.largeImages[value] != null) {
                this.newThemes[index].smallThemeImageStyle = `background-image:url('${this.staticUrl.theme.smallImages[value]}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                this.newThemes[index].largeThemeImageStyle = `background-image:url('${this.staticUrl.theme.largeImages[value]}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
            } else if (fielName === 'theme' && this.newThemes[index].largeThemeImageStyle !== `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`) {
                this.newThemes[index].largeThemeImageStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                this.newThemes[index].smallThemeImageStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;

            }
            return;
        }

        const themesSettingsIndexa = event.currentTarget ? event.currentTarget.dataset.cell : event.target.dataset.cell;
        this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa][fielName] = value;
        if (fielName == 'largeThemeImage') {
            this.validateImageUrl(this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].largeThemeImage).then(valid => {
                if (!valid) {
                    if (this.staticUrl.theme.largeImages[value] != null) {
                        this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].largeThemeImageStyle = `background-image:url('${this.staticUrl.theme.largeImages[value]}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    } else if (fielName === 'theme' && this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].largeThemeImageStyle !== `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`) {
                        this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].largeThemeImageStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    }
                }
            });
        }
        if (fielName == 'smallThemeImage') {
            this.validateImageUrl(this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].smallThemeImage).then(valid => {
                if (!valid) {
                    if (this.staticUrl.theme.smallImages[value] != null) {
                        this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].smallThemeImageStyle = `background-image:url('${this.staticUrl.theme.smallImages[value]}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    } else if (fielName === 'theme' && this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].smallThemeImageStyle !== `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`) {
                        this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa].smallThemeImageStyle = `background-image:url('${this.staticUrl.defaultimageStyle}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;
                    }
                }
            });
        }
    }

    handleThemesChangeStatus(event) {
        const isNew = event.currentTarget.dataset.table === 'new' ? true : false;
        const index = event.currentTarget ? event.currentTarget.dataset.index : event.target.dataset.index;
        const fielName = event.currentTarget ? event.currentTarget.dataset.id : event.target.dataset.id;
        const value = event?.detail?.selOptions?.filter(it => it.isSelected)?.map(it => it.value) || [];
        if (isNew) {
            this.newThemes[index][fielName] = value;
        } else {
            const themesSettingsIndexa = event.currentTarget ? event.currentTarget.dataset.cell : event.target.dataset.cell;
            this.settingsList[this.currentThemes.index].themesSettings[themesSettingsIndexa][fielName] = value;
        }
    }

    handleThemesSelection(event) {
        const index = event.currentTarget.dataset.index;
        this.template?.querySelectorAll('.themesSelectionStyle')?.forEach(element => {
            element.classList.remove('themesSelectionStyle');
        });
        if (this.currentThemes.sectionTitle === this.settingsList[index].sectionTitle) {
            this.currentThemes = {};
            this.newThemes.forEach(e => {
                e.relatedSection = '';
            })
            this.currentThemeLabel = '';
        } else {
            this.currentThemes = { ...this.settingsList[index] };
            this.currentThemes.index = index;
            event.currentTarget.closest('td').classList.add('themesSelectionStyle');
            this.newThemes.forEach(e => {
                e.relatedSection = this.currentThemes.sectionTitle;
            })
            // extract the theme from selected section title and save it in currentThemeLabel
            const extractedLabel = this.extractLabel(this.currentThemes.sectionTitle);
            if (extractedLabel != null) {
                getCustomLabel({
                    labelName: extractedLabel,
                    hardcodedLabel: this.currentThemes.sectionTitle,
                    language: DISPLAY_LANG
                }).then((res) => {
                    this.currentThemeLabel = res;
                }).catch((err) => {
                    console.log(err);
                    // Handle any errors, set a fallback action name
                    this.currentThemeLabel = this.currentThemes.sectionTitle;
                });
            } else {
                this.currentThemeLabel = this.currentThemes.sectionTitle;
            }
        }
    }

    handlesectionColorChange(event) {
        const index = event.target.dataset.index;
        this.settingsList[index].sectionColor = event.target.value;
    }
    /*
    * get mothods
    */
    get themeButtonVisibility() {
        // if we have a section and we the select a section and the section not new make the add theme button visible
        return this.settingsList.length > 0
            && this.currentThemes.sectionTitle != undefined
            && this.currentThemes.isNew != true ? true : false;
    }

    handleFocusInput() {
        this.saveStatus = true;
    }

    handleBlurInput() {
        this.saveStatus = false;
    }

}