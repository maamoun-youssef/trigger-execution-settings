import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//APEX
import getData from "@salesforce/apex/GLStickersSettingsCtrl.getData";
import saveSettings from "@salesforce/apex/GLStickersSettingsCtrl.saveSettings";
import checkDeploymentStatus from "@salesforce/apex/GLStickersSettingsCtrl.checkDeploymentStatus";
//OBJECTS
import GlobalLocation__c from '@salesforce/schema/GlobalLocation__c';
//FIELDS
import CompanyName__c from "@salesforce/schema/GlobalLocation__c.CompanyName__c";
import Address1__c from "@salesforce/schema/GlobalLocation__c.Address1__c";
import Address2__c from "@salesforce/schema/GlobalLocation__c.Address2__c";
import Address3__c from "@salesforce/schema/GlobalLocation__c.Address3__c";
import PostalCode__c from "@salesforce/schema/GlobalLocation__c.PostalCode__c";
import City__c from "@salesforce/schema/GlobalLocation__c.City__c";
import Country__c from "@salesforce/schema/GlobalLocation__c.Country__c";
import Phone1__c from "@salesforce/schema/GlobalLocation__c.Phone1__c";
import Phone2__c from "@salesforce/schema/GlobalLocation__c.Phone2__c";
import Identifier1__c from "@salesforce/schema/GlobalLocation__c.Identifier1__c";
import Identifier2__c from "@salesforce/schema/GlobalLocation__c.Identifier2__c";
import Identifier3__c from "@salesforce/schema/GlobalLocation__c.Identifier3__c";
import Identifier4__c from "@salesforce/schema/GlobalLocation__c.Identifier4__c";
import Identifier5__c from "@salesforce/schema/GlobalLocation__c.Identifier5__c";
import Identifier6__c from "@salesforce/schema/GlobalLocation__c.Identifier6__c";
import Identifier7__c from "@salesforce/schema/GlobalLocation__c.Identifier7__c";
import Identifier8__c from "@salesforce/schema/GlobalLocation__c.Identifier8__c";
import Identifier9__c from "@salesforce/schema/GlobalLocation__c.Identifier9__c";
import Identifier10__c from "@salesforce/schema/GlobalLocation__c.Identifier10__c";
//LABELS
import LBL_GLStickersSettings from "@salesforce/label/c.LBL_GLStickersSettings";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Warning from "@salesforce/label/c.LBL_Warning";
import MSG_Successfully_Saved from "@salesforce/label/c.MSG_Successfully_Saved";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_GLField from "@salesforce/label/c.LBL_GLField";
import LBL_Column from "@salesforce/label/c.LBL_Column";
import LBL_Line from "@salesforce/label/c.LBL_Line";
import LBL_GLStickersMsgCancel from "@salesforce/label/c.LBL_GLStickersMsgCancel";
import LBL_GLStickersMsgMandatoryFields from "@salesforce/label/c.LBL_GLStickersMsgMandatoryFields";
import LBL_GLStickersMsgUnicityFields from "@salesforce/label/c.LBL_GLStickersMsgUnicityFields";
import LBL_GLStickersMsgDeleteWarning from "@salesforce/label/c.LBL_GLStickersMsgDeleteWarning";
import LBL_Add from "@salesforce/label/c.LBL_Add";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Please_Select_A_Record from "@salesforce/label/c.LBL_Please_Select_A_Record";
import MSG_No_Changes_To_Save from "@salesforce/label/c.MSG_No_Changes_To_Save";
import LBL_Actions from '@salesforce/label/c.LBL_Actions';
export default class GLStickersSettings extends LightningElement {
    //Ids
    jobId;
    //Text
    @track requiredFieldMsg = '';
    @track messages = {
        success: [

        ],
        error: [

        ],
        warning: [

        ]
    }
    //Maps
    @track fieldsMap = {};

    //BOOLEANS
    @track isLoading = false;
    cancel = false;
    showDeleteWarning = true;
    hasDeletedRows = false;

    //LABELS
    @track labels = {
        LBL_GLStickersSettings,
        LBL_Error,
        LBL_Success,
        LBL_Warning,
        MSG_Successfully_Saved,
        LBL_GLStickersMsgUnicityFields,
        LBL_GLStickersMsgMandatoryFields,
        LBL_GLStickersMsgCancel,
        LBL_GLStickersMsgDeleteWarning,
        LBL_Please_Select_A_Record,
        MSG_No_Changes_To_Save,
        LBL_Line,
        LBL_Column,
        LBL_GLField,
        LBL_Add,
        LBL_Delete,
        LBL_Save,
        LBL_Actions,
        GlobalLocation__c: {}
    }
    //API_NAMES
    API_NAMES = {
        GlobalLocation__c: {
            objectApiName: GlobalLocation__c.objectApiName,
            CompanyName__c: CompanyName__c.fieldApiName,
            Address1__c: Address1__c.fieldApiName,
            Address2__c: Address2__c.fieldApiName,
            Address3__c: Address3__c.fieldApiName,
            PostalCode__c: PostalCode__c.fieldApiName,
            City__c: City__c.fieldApiName,
            Country__c: Country__c.fieldApiName,
            Phone1__c: Phone1__c.fieldApiName,
            Phone2__c: Phone2__c.fieldApiName,
            Identifier1__c: Identifier1__c.fieldApiName,
            Identifier2__c: Identifier2__c.fieldApiName,
            Identifier3__c: Identifier3__c.fieldApiName,
            Identifier4__c: Identifier4__c.fieldApiName,
            Identifier5__c: Identifier5__c.fieldApiName,
            Identifier6__c: Identifier6__c.fieldApiName,
            Identifier7__c: Identifier7__c.fieldApiName,
            Identifier8__c: Identifier8__c.fieldApiName,
            Identifier9__c: Identifier9__c.fieldApiName,
            Identifier10__c: Identifier10__c.fieldApiName
        }
    }
    //OPTIONS
    @track lineOptions = [
        { label: '1', value: '1', check: false },
        { label: '2', value: '2', check: false },
        { label: '3', value: '3', check: false },
        { label: '4', value: '4', check: false },
        { label: '5', value: '5', check: false },
        { label: '6', value: '6', check: false }
    ];
    @track columnOptions = [
        { label: '1', value: '1', check: false },
        { label: '2', value: '2', check: false },
    ];
    @track fieldOptions = [];
    //SETTINGS
    @track settings = [
    ];
    //SELECTED
    @track selectedRowIndex;

    connectedCallback() {
        document.addEventListener('click', this.handleDocumentClick.bind(this));
        addEventListener('resize', this.setPageSize);
        try {
            this.loadData();
        } catch (error) {
            console.error('connectedCallback', error);
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    disconnectedCallback() {
        // Remove the event listener when the component is removed
        document.removeEventListener('click', this.handleDocumentClick.bind(this));
    }

    renderedCallback() {
        try {
            this.setPageSize();
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');

        }
    }

    setPageSize = () => {
        try {
            const mainContainer = this.template.querySelector(".mainContainer");
            const pageHeader = this.template.querySelector(".pageHeader");
            const pageBodyDiv = this.template.querySelector(".pageBody");
            if (mainContainer && pageHeader && pageBodyDiv) {
                const windowHeight = window.innerHeight;
                const headerHeight = pageHeader.offsetHeight;
                const remainingHeight = windowHeight - headerHeight - 260;
                pageBodyDiv.style.height = remainingHeight + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };

    // Close all dropdowns
    closeAllDropdowns() {
        const dropdowns = this.template.querySelectorAll('.slds-is-open');
        dropdowns.forEach(dropdown => dropdown.classList.remove('slds-is-open'));
    }

    // Handle clicks outside of dropdowns
    handleDocumentClick() {
        this.closeAllDropdowns();
    }

    loadData() {
        this.isLoading = true;
        getData({
        }).then((result) => {
            this.afterload(result);
        }).catch((error) => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
        });
    }

    afterload(result) {
        try {
            if (result) {
                let parsedResult = JSON.parse(result);
                this.fieldsMap = parsedResult.fieldsMap;
                this.labels.GlobalLocation__c = {
                    CompanyName__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.CompanyName__c].label,
                    Address1__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Address1__c].label,
                    Address2__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Address2__c].label,
                    Address3__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Address3__c].label,
                    PostalCode__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.PostalCode__c].label,
                    City__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.City__c].label,
                    Country__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Country__c].label,
                    Phone1__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Phone1__c].label,
                    Phone2__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Phone2__c].label,
                    Identifier1__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier1__c].label,
                    Identifier2__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier2__c].label,
                    Identifier3__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier3__c].label,
                    Identifier4__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier4__c].label,
                    Identifier5__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier5__c].label,
                    Identifier6__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier6__c].label,
                    Identifier7__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier7__c].label,
                    Identifier8__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier8__c].label,
                    Identifier9__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier9__c].label,
                    Identifier10__c: parsedResult.fieldsMap[this.API_NAMES.GlobalLocation__c.objectApiName][this.API_NAMES.GlobalLocation__c.Identifier10__c].label
                };
                this.fieldOptions = [
                    { label: this.labels.GlobalLocation__c.CompanyName__c, value: this.API_NAMES.GlobalLocation__c.CompanyName__c, check: false },
                    { label: this.labels.GlobalLocation__c.Address1__c, value: this.API_NAMES.GlobalLocation__c.Address1__c, check: false },
                    { label: this.labels.GlobalLocation__c.Address2__c, value: this.API_NAMES.GlobalLocation__c.Address2__c, check: false },
                    { label: this.labels.GlobalLocation__c.Address3__c, value: this.API_NAMES.GlobalLocation__c.Address3__c, check: false },
                    { label: this.labels.GlobalLocation__c.PostalCode__c, value: this.API_NAMES.GlobalLocation__c.PostalCode__c, check: false },
                    { label: this.labels.GlobalLocation__c.City__c, value: this.API_NAMES.GlobalLocation__c.City__c, check: false },
                    { label: this.labels.GlobalLocation__c.Country__c, value: this.API_NAMES.GlobalLocation__c.Country__c, check: false },
                    { label: this.labels.GlobalLocation__c.Phone1__c, value: this.API_NAMES.GlobalLocation__c.Phone1__c, check: false },
                    { label: this.labels.GlobalLocation__c.Phone2__c, value: this.API_NAMES.GlobalLocation__c.Phone2__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier1__c, value: this.API_NAMES.GlobalLocation__c.Identifier1__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier2__c, value: this.API_NAMES.GlobalLocation__c.Identifier2__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier3__c, value: this.API_NAMES.GlobalLocation__c.Identifier3__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier4__c, value: this.API_NAMES.GlobalLocation__c.Identifier4__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier5__c, value: this.API_NAMES.GlobalLocation__c.Identifier5__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier6__c, value: this.API_NAMES.GlobalLocation__c.Identifier6__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier7__c, value: this.API_NAMES.GlobalLocation__c.Identifier7__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier8__c, value: this.API_NAMES.GlobalLocation__c.Identifier8__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier9__c, value: this.API_NAMES.GlobalLocation__c.Identifier9__c, check: false },
                    { label: this.labels.GlobalLocation__c.Identifier10__c, value: this.API_NAMES.GlobalLocation__c.Identifier10__c, check: false }
                ];
                if (parsedResult.stickersSettings) {
                    this.settings = this.transformToLocalManagement(parsedResult.stickersSettings);
                }
            }
            this.isLoading = false;
            if (this.cancel) {
                this.showNotification(this.labels.LBL_Success, this.labels.LBL_GLStickersMsgCancel, 'success');
                // this.addMessage('success', this.labels.LBL_GLStickersMsgCancel);
                this.cancel = false;
            }
        }
        catch (error) {
            console.error('afterload', JSON.stringify(error));
            this.showNotification(this.labels.LBL_Error, error.body?.message, 'error');
        }
    }

    handleFieldChange(event) {
        let dataIndex = event.currentTarget.dataset.index;
        let value = event.currentTarget.dataset.value;
        let field = event.currentTarget.dataset.field;
        let instance = this.settings[dataIndex];
        let updatedInstance = {};
        if (field === 'column') {
            if (instance.column === value) {
                return;
            }
            let updatedColumnOptions = [];
            this.columnOptions.forEach(option => {
                let copyOption = { ...option };
                if (copyOption.value === value) {
                    copyOption.check = true;
                }
                else {
                    copyOption.check = false;
                }
                updatedColumnOptions.push(copyOption);
            });
            updatedInstance = {
                ...instance,
                column: value,
                columnOptions: updatedColumnOptions,
                class: 'slds-is-edited',
                columnEmpty: false,
                isEdited: true,
            }
        }
        if (field === 'line') {
            if (instance.line === value) {
                return;
            }
            let updatedLineOptions = [];
            this.lineOptions.forEach(option => {
                let copyOption = { ...option };
                if (copyOption.value === value) {
                    copyOption.check = true;
                }
                else {
                    copyOption.check = false;
                }
                updatedLineOptions.push(copyOption);
            });
            updatedInstance = {
                ...instance,
                line: value,
                lineOptions: updatedLineOptions,
                class: 'slds-is-edited',
                lineEmpty: false,
                isEdited: true,
            }
        }
        if (field === 'fieldName') {
            if (instance.fieldName === value) {
                return;
            }
            let updatedFieldOptions = [];
            let fieldDisplayName = '';
            this.fieldOptions.forEach(option => {
                let copyOption = { ...option };
                if (copyOption.value === value) {
                    copyOption.check = true;
                    fieldDisplayName = copyOption.label;
                }
                else {
                    copyOption.check = false;
                }
                updatedFieldOptions.push(copyOption);
            });
            updatedInstance = {
                ...instance,
                fieldName: value,
                fieldDisplayName: fieldDisplayName,
                fieldNameOptions: updatedFieldOptions,
                class: 'slds-is-edited',
                fieldNameEmpty: false,
                isEdited: true,
            }
        }
        // update state
        let updatedSettings = [...this.settings];
        updatedSettings[dataIndex] = updatedInstance;
        // trigger rerender
        this.settings = updatedSettings;
        // message control
        // this.clearMessages('success');
        // required field control
        this.markEmptyFields();
    }

    validateDuplicates() {
        let isValid = true;
        let lineColumnOccurrences = {};

        // Validate line and column uniqueness
        for (let index = 0; index < this.settings.length; index++) {
            const row = this.settings[index];
            if (row.line && row.column) {
                const key = row.line + '-' + row.column;
                if (lineColumnOccurrences[key]) {
                    lineColumnOccurrences[key].push(index + 1);
                    isValid = false;
                } else {
                    lineColumnOccurrences[key] = [index + 1];
                }
            }
        }

        // Handle duplicate messages
        if (!isValid) {
            let duplicateGroups = '';
            Object.values(lineColumnOccurrences).forEach(arr => {
                if (arr.length > 1) {
                    const lineNumbers = arr.map(line => `${this.labels.LBL_Line} ${line}`).join(', ');
                    duplicateGroups += `(${lineNumbers}), `;
                }
            });

            if (duplicateGroups) {
                duplicateGroups = duplicateGroups.slice(0, -2); // Remove trailing comma and space
            }

            if (duplicateGroups) {
                // this.addMessage('error', '*' + this.labels.LBL_GLStickersMsgUnicityFields + ' ' + duplicateGroups);
                const errorMessage = '*' + this.labels.LBL_GLStickersMsgUnicityFields + ' ' + duplicateGroups;
                // this.addMessage('error', errorMessage);
                this.showNotification(this.labels.LBL_Error, errorMessage, 'error');
            }
        }

        return isValid;
    }

    validateRequiredFields() {
        let isValid = true;
        let missingFieldLines = [];
        this.markEmptyFields();
        this.settings.forEach((setting, index) => {
            let lineEmpty = !setting.line || setting.line === null || setting.line === '';
            let columnEmpty = !setting.column || setting.column === null || setting.column === '';
            let fieldEmpty = !setting.fieldName || setting.fieldName === null || setting.fieldName === '';

            // Update the boolean properties in each setting
            setting.lineEmpty = lineEmpty;
            setting.columnEmpty = columnEmpty;
            setting.fieldEmpty = fieldEmpty;

            // Check if any required fields are empty
            if (lineEmpty || columnEmpty || fieldEmpty) {
                isValid = false;

                // Add the line number to missingFieldLines if it's not already present
                const dataIndex = setting.lineNumber;
                if (!missingFieldLines.includes(dataIndex)) {
                    missingFieldLines.push(dataIndex);
                }
            }
        });

        // Update settings array to trigger reactivity
        this.settings = [...this.settings];

        // Handle missing field messages
        if (!isValid && missingFieldLines.length) {
            // Prepend LBL_Ligne to each missing field line number
            // const formattedLines = missingFieldLines.map(line => this.labels.LBL_Line + ' ' + line);
            // this.addMessage('error', '*' + this.labels.LBL_GLStickersMsgMandatoryFields + ' (' + formattedLines.join(', ') + ')');


            const formattedLines = missingFieldLines.map(line => this.labels.LBL_Line + ' ' + line);
            const errorMessage = '*' + this.labels.LBL_GLStickersMsgMandatoryFields + ' (' + formattedLines.join(', ') + ')';
            // this.addMessage('error', errorMessage);
            this.showNotification(this.labels.LBL_Error, errorMessage, 'error');
        }

        return isValid;
    }

    checkDeployementStatus(idDeployment) {
        this.isLoading = true;
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
                                this.isLoading = false;
                                this.hasDeletedRows = false;
                                this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                                // this.addMessage('success', this.labels.MSG_Successfully_Saved);
                                this.loadData();
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
                self.hasDeletedRows = false;
                self.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                // self.addMessage('success', this.labels.MSG_Successfully_Saved);
                self.loadData();
            }
        });
    }

    //ACTION HANDLERS
    handleAdd() {
        if (this.settings.length < 12) {
            // this.clearMessages('success');
            this.settings = [
                ...this.settings,
                {
                    lineNumber: this.settings.length + 1,
                    class: 'slds-is-edited',
                    fieldName: null,
                    line: null,
                    column: null,
                    columnOptions: this.columnOptions,
                    lineOptions: this.lineOptions,
                    fieldNameOptions: this.fieldOptions,
                    lineInputId: 'input-line-' + (this.settings.length + 1).toString(),
                    columnInputId: 'input-column-' + (this.settings.length + 1).toString(),
                    fieldNameInputId: 'input-fieldName-' + (this.settings.length + 1).toString(),
                    lineListBoxId: 'listbox-line-' + (this.settings.length + 1).toString(),
                    columnListBoxId: 'listbox-column-' + (this.settings.length + 1).toString(),
                    fieldNameListBoxId: 'listbox-fieldName-' + (this.settings.length + 1).toString(),
                    // fieldOptions: rowFieldOptions
                    showRemoveButton: true,
                    // removeButtonClass: 'slds-visible'
                    removeButtonClass: 'visible',
                    deleteButtonClass: 'hidden',
                    isEdited: true,
                    isnewRow: true,
                }
            ];
        }
    }

    handleSave() {
        this.markEmptyFields();
        const hasChanges = this.settings.some(setting => setting.isEdited || setting.isnewRow) || this.hasDeletedRows;
        let allFilled = this.validateRequiredFields();
        let noDuplicates = this.validateDuplicates();
        if (allFilled && noDuplicates) {
            if (hasChanges) {
                this.isLoading = true;
                let metadataItem = {
                    globalLocationStickerFields: this.transformToJSON(this.settings)
                };
                saveSettings({ orgSettingsJSON: JSON.stringify(metadataItem) })
                    .then(result => {
                        this.jobId = result;
                        this.checkDeployementStatus(result);
                    })
                    .catch(error => {
                        console.log('error: ' + error);
                        console.error(error?.message);
                        // this.showNotification(this.labels.LBL_Error, error?.body?.message, 'error');
                    });
            } else {
                this.showNotification(this.labels.LBL_Warning, this.labels.MSG_No_Changes_To_Save, 'warning');
            }
        } else {
            if (!allFilled) {
                // this.showNotification(this.labels.LBL_Error, this.labels.MSG_Required_Fields, 'error');
            }
            if (!noDuplicates) {
                // this.showNotification(this.labels.LBL_Error, this.labels.MSG_Duplicate_Entries, 'error');
            }
        }
    }

    handleRemove(event) {
        const dataIndex = event.target.dataset.index;
        this.settings.splice(dataIndex, 1);
        this.settings.forEach((setting, index) => {
            setting.lineNumber = index + 1;
        });
        this.settings = [...this.settings];
        // this.clearMessages();
    }

    handleDelete(event) {
        // this.clearMessages('success');
        const dataIndex = event.target.dataset.index;
        if (this.settings[dataIndex]) {
            const selectedLine = this.settings[dataIndex];
            if (selectedLine.original) {
                this.hasDeletedRows = true;
            }
            selectedLine.isEdited = true;
            this.settings.splice(dataIndex, 1);
            this.settings.forEach((setting, index) => {
                setting.lineNumber = index + 1;
            });
            this.settings = [...this.settings];
            this.selectedRowIndex = null;
            if (this.showDeleteWarning && selectedLine.original) {
                this.showNotification(this.labels.LBL_Warning, this.labels.LBL_GLStickersMsgDeleteWarning, 'warning');
                this.showDeleteWarning = false;
            }
        }
    }

    // UTILS
    transformToLocalManagement(settings) {
        let transformed = [];
        settings.forEach((rowSetting, rowIndex) => {
            let columnIndex = 1;  // Start column index from 1 for each row
            rowSetting.forEach((fieldName) => {
                if (fieldName && fieldName != '') {  // Skip empty objects {}
                    let updatedColumnOptions = [];
                    this.columnOptions.forEach(option => {
                        let copyOption = { ...option };
                        copyOption.check = (copyOption.value === columnIndex.toString());
                        updatedColumnOptions.push(copyOption);
                    });

                    let updatedLineOptions = [];
                    this.lineOptions.forEach(option => {
                        let copyOption = { ...option };
                        copyOption.check = (copyOption.value === (rowIndex + 1).toString());
                        updatedLineOptions.push(copyOption);
                    });

                    let updatedFieldOptions = [];
                    let fieldDisplayName = '';
                    this.fieldOptions.forEach(option => {
                        let copyOption = { ...option };
                        copyOption.check = (copyOption.value === fieldName);
                        if (copyOption.check) {
                            fieldDisplayName = copyOption.label;
                        }
                        updatedFieldOptions.push(copyOption);
                    });

                    transformed.push({
                        lineNumber: rowIndex + 1,
                        line: (rowIndex + 1).toString(),
                        column: columnIndex.toString(),  // Infer column number
                        fieldName: fieldName,
                        fieldDisplayName: fieldDisplayName,
                        original: true,
                        columnOptions: updatedColumnOptions,
                        lineOptions: updatedLineOptions,
                        fieldNameOptions: updatedFieldOptions,
                        lineInputId: 'input-line-' + (rowIndex + 1).toString(),
                        columnInputId: 'input-column-' + (rowIndex + 1).toString(),
                        fieldNameInputId: 'input-fieldName-' + (rowIndex + 1).toString(),
                        lineListBoxId: 'listbox-line-' + (rowIndex + 1).toString(),
                        columnListBoxId: 'listbox-column-' + (rowIndex + 1).toString(),
                        fieldNameListBoxId: 'listbox-fieldName-' + (rowIndex + 1).toString()
                    });

                    columnIndex++;  // Increment column index only for non-empty objects
                } else {
                    columnIndex++;
                }
            });
        });

        // Sort first by column, then by line
        transformed.sort((a, b) => {
            if (a.column === b.column) {
                return parseInt(a.line, 10) - parseInt(b.line, 10);
            }
            return parseInt(a.column, 10) - parseInt(b.column, 10);
        });
        return transformed.slice(0, 12); // Ensure the result contains a maximum of 12 entries
    }

    transformToJSON(localSettings) {
        // Initialize the output with 6 lines and 2 columns, defaulting to empty strings
        let transformed = Array.from({ length: 6 }, () => Array.from({ length: 2 }, () => ('')));

        // Populate the transformed array based on localSettings
        localSettings.forEach(setting => {
            let row = parseInt(setting.line, 10) - 1; // Convert 1-based index to 0-based
            let column = parseInt(setting.column, 10) - 1; // Convert 1-based index to 0-based

            // Ensure the row and column indices are within bounds
            if (row >= 0 && row < 6 && column >= 0 && column < 2) {
                transformed[row][column] = setting.fieldName;
            }
        });

        // Convert the 2D array to the desired JSON structure, replacing null with ''
        return transformed.map(row => row.map(cell => cell || ''));
    }

    get rows() {
        return this.settings.map((item, index) => {
            return {
                ...item,
                lineNumber: index + 1
            };
        });
    }

    showNotification(title, message, variant) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
            duration: 3000
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
                duration: 1
            }));
        }, 5000);
    }

    // Custom Combobox
    toggleDropdown(event) {
        // Get the element that triggered the event
        const targetElement = event.currentTarget;

        // Check if the dropdown is already open
        const isOpen = targetElement.classList.contains('slds-is-open');

        // Toggle the 'slds-is-open' class
        if (isOpen) {
            targetElement.classList.remove('slds-is-open');
        } else {
            // Close all other dropdowns before opening the current one
            this.closeAllDropdowns();

            targetElement.classList.add('slds-is-open');
        }

        // Stop the event from bubbling to the document click handler
        event.stopPropagation();
    }

    // Add focus class on hover
    handleMouseEnter(event) {
        const targetElement = event.currentTarget;
        targetElement.classList.add('slds-has-focus');
    }

    // Remove focus class on hover end
    handleMouseLeave(event) {
        const targetElement = event.currentTarget;
        targetElement.classList.remove('slds-has-focus');
    }

    markEmptyFields() {
        // Arrays to store ids for elements that need to be marked (empty values)
        let columnIdsToMark = [];
        let lineIdsToMark = [];
        let fieldNameIdsToMark = [];

        // Arrays to store ids for elements that need to be unmarked (valid values)
        let columnIdsToUnmark = [];
        let lineIdsToUnmark = [];
        let fieldNameIdsToUnmark = [];

        // Iterate through the settings
        this.settings.forEach((setting, index) => {
            // Check if column is empty or valid
            if (!setting.column) {
                columnIdsToMark.push(setting.columnInputId);
            } else {
                columnIdsToUnmark.push(setting.columnInputId);
            }

            // Check if line is empty or valid
            if (!setting.line) {
                lineIdsToMark.push(setting.lineInputId);
            } else {
                lineIdsToUnmark.push(setting.lineInputId);
            }

            // Check if fieldName is empty or valid
            if (!setting.fieldName) {
                fieldNameIdsToMark.push(setting.fieldNameInputId);
            } else {
                fieldNameIdsToUnmark.push(setting.fieldNameInputId);
            }
        });

        // Apply styles to column elements based on stored ids
        columnIdsToMark.forEach(columnId => {
            const columnElement = this.template.querySelector(`[id^='${columnId}']`);
            if (columnElement) {
                columnElement.style.borderWidth = '2px';
                columnElement.style.borderColor = 'red';
            } else {
                console.warn(`Column element not found for ID starting with: ${columnId}`);
            }
        });

        // Remove styles from column elements that have valid values
        columnIdsToUnmark.forEach(columnId => {
            const columnElement = this.template.querySelector(`[id^='${columnId}']`);
            if (columnElement) {
                columnElement.style.borderWidth = '';
                columnElement.style.borderColor = '';
            } else {
                console.warn(`Column element not found for ID starting with: ${columnId}`);
            }
        });

        // Apply styles to line elements based on stored ids
        lineIdsToMark.forEach(lineId => {
            const lineElement = this.template.querySelector(`[id^='${lineId}']`);
            if (lineElement) {
                lineElement.style.borderWidth = '2px';
                lineElement.style.borderColor = 'red';
            } else {
                console.warn(`Line element not found for ID starting with: ${lineId}`);
            }
        });

        // Remove styles from line elements that have valid values
        lineIdsToUnmark.forEach(lineId => {
            const lineElement = this.template.querySelector(`[id^='${lineId}']`);
            if (lineElement) {
                lineElement.style.borderWidth = '';
                lineElement.style.borderColor = '';
            } else {
                console.warn(`Line element not found for ID starting with: ${lineId}`);
            }
        });

        // Apply styles to fieldName elements based on stored ids
        fieldNameIdsToMark.forEach(fieldNameId => {
            const fieldNameElement = this.template.querySelector(`[id^='${fieldNameId}']`);
            if (fieldNameElement) {
                fieldNameElement.style.borderWidth = '2px';
                fieldNameElement.style.borderColor = 'red';
            } else {
                console.warn(`FieldName element not found for ID starting with: ${fieldNameId}`);
            }
        });

        // Remove styles from fieldName elements that have valid values
        fieldNameIdsToUnmark.forEach(fieldNameId => {
            const fieldNameElement = this.template.querySelector(`[id^='${fieldNameId}']`);
            if (fieldNameElement) {
                fieldNameElement.style.borderWidth = '';
                fieldNameElement.style.borderColor = '';
            } else {
                console.warn(`FieldName element not found for ID starting with: ${fieldNameId}`);
            }
        });

    }
}