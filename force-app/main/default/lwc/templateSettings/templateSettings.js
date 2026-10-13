import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import loadTemplateSettings from '@salesforce/apex/TemplateSettingsCtrl.loadTemplateSettings';
import save from '@salesforce/apex/TemplateSettingsCtrl.save';
import checkDeploymentStatus from '@salesforce/apex/TemplateSettingsCtrl.checkDeploymentStatus';
import deleteTemplateSettings from '@salesforce/apex/TemplateSettingsCtrl.deleteTemplateSettings';
import { labels } from './properties.js';
import loadOptionsForObject from '@salesforce/apex/TemplateSettingsCtrl.loadOptionsForObject';
import Invoice_OBJECT from '@salesforce/schema/Invoice__c';
import getFirstSelectList from '@salesforce/apex/TemplateSettingsCtrl.getFirstSelectList';
const PREFIX = Invoice_OBJECT.objectApiName.replace(/Invoice__c/gi, '');
const classPrefix = `${PREFIX ? PREFIX + '-' : 'c-'}template-settings`;
export default class TemplateSettings extends LightningElement {
    //LABELS
    labels = labels;
    isLoading = false;
    FieldSetOptions = [];
    ObjectOptions = [];
    saveStatus = false;
    activePopupIndex = null;
    // static

    @track popup = {
        visibility: false,
        title: '',
        body: '',
    };
    // tracked properties
    @track settingsList = [];
    @track FieldSetOptions = {};
    @track ObjectOptions = {};
    @track allStatuses = [];
    @track mainPanelHeight;
    @track newThemes = [];
    @track isPopupOpen = false;
    @track popupColumns = [];
    sortSettingsList() {
        if (Array.isArray(this.settingsList)) {
            this.settingsList.sort((a, b) => {
                return a.displayOrder - b.displayOrder;
            });
        }
    }

    //LIFECYCLE
    connectedCallback() {
        Promise.all([]).then(() => {
            console.log('loading style success');
        }).catch(error => {
            console.log('error loading style');
        });
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
        loadTemplateSettings()
            .then(result => {
                let parsedResult = JSON.parse(result);
                console.log('parsedResult: ' + JSON.stringify(parsedResult))
                this.FieldSetOptions = Object.keys(parsedResult.FieldSetOptions).map(key => ({
                    value: key,
                    label: parsedResult.FieldSetOptions[key]
                }));
                this.ObjectOptions = Object.keys(parsedResult.ObjectOptions).map(key => ({
                    value: key,
                    label: parsedResult.ObjectOptions[key]
                }));



               /// this.fieldOptions = Object.keys(parsedResult.fieldOptions || {}).map(key => ({
                 //   value: key,
              //      label: parsedResult.fieldOptions[key]
               // }));

                this.afterload(parsedResult.settings);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.isLoading = false;
            })


    }

     afterload(data) {
        this.settingsList = [...data];
        this.sortSettingsList();

        this.settingsList.forEach(setting => {
            if (setting.ObjectName) {
                loadOptionsForObject({ ObjectName: setting.ObjectName })
                    .then(result => {
                        let parsed = JSON.parse(result);

                        // Build fieldsArray
                        setting.fieldsArray = Object.keys(parsed.fieldOptions || {}).map(key => ({
                            value: key,
                         label: parsed.fieldOptions[key]
                         }));

                        // Add saved value if missing
                        if (setting.FieldName) {
                            const exists = setting.fieldsArray.some(f => f.value === setting.FieldName);
                            if (!exists) {
                                setting.fieldsArray.push({
                                    value: setting.FieldName,
                                    label: setting.FieldLabel || setting.FieldName
                                });
                            }
                        }


                        console.log('label value ', setting.FieldLabel);
                        console.log('label value ', setting.FieldLabel);
                        console.log('this.settingsList after afterload: ', JSON.stringify(this.settingsList));
                    })
                    .catch(error => {
                        console.error('Error loading options for object: ', error);
                    });
            }
        });

        this.isLoading = false;
    }



    handleAddSection() {
        let newSection = {};
        newSection.isNew = true;
        console.log('newSection: ' + newSection);
        newSection.displayOrder = String(this.settingsList.length + 1);
        this.settingsList.push(newSection);
        console.log(this.settingsList)
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
            await deleteTemplateSettings({ developerName: this.settingsList[index].developerName })
                .then(res => {
                    this.settingsList.splice(index, 1);
                    this.popup.visibility = false;
                }).catch(error => {
                    this.showNotification('Error', error.body?.message, 'error');
                    this.popup.visibility = false;

                })
        }
    }

    handleSave() {
        // Step 1: Check for duplicates
        let seen = new Set();
        let duplicates = [];

        this.settingsList.forEach(row => {
            if (seen.has(row.FieldSetName)) {
                duplicates.push(row.FieldSetName);
            } else {
                seen.add(row.FieldSetName);
            }
        });

        // Step 2: Notify user if duplicates exist
        if (duplicates.length > 0) {
            this.showNotification(
                'Error',
                'Duplicate field sets detected: ' + duplicates.join(', '),
                'error'
            );
            return; // Stop the save
        }
        save({
            FileDirectorySettingsJSON: JSON.stringify(this.settingsList)
        }).then(result => {
            console.log('Save result: ', result);
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
    handleFieldSetChange(event) {
        const index = event.target.dataset.index;  // index of the row
        const key = event.target.dataset.id;      // e.g., 
        const value = event.target.value;
        this.settingsList[index][key] = value;
    }

    handleObjectChange(event) {
        const index = event.target.dataset.index;
        const selectedObject = event.target.value;

        this.settingsList[index].ObjectName = selectedObject;

        loadOptionsForObject({ ObjectName: selectedObject })
            .then(result => {
                let parsed = JSON.parse(result);
                console.log('the value of parsed:' + parsed);
                this.settingsList[index].fieldsArray = Object.keys(parsed.fieldOptions).map(key => ({
                    value: key,
                    label: parsed.fieldOptions[key]
                }));

            })
            .catch(error => {
                console.error('Error loading options for object: ', error);
            });

    }

    handleBlurInput() {
        this.saveStatus = false;
    }

    handleFieldChange(event) {
        const index = event.target.dataset.index;
        const fieldKey = event.target.dataset.id;
        const selectedValue = event.target.value;

        this.settingsList[index][fieldKey] = selectedValue;
        this.popupColumns = [];

        // Remember which row opened the popup
        this.activePopupIndex = index; // <-- minimal addition

        // Check if field is lookup
        const fieldObj = this.settingsList[index].fieldsArray.find(f => f.value === selectedValue);
        if (!fieldObj) return;

        let refObjectName = null;
        if (fieldObj.label.includes('(')) {
            refObjectName = fieldObj.label.match(/\(([^)]+)\)/)[1];
        } else if (selectedValue.includes(':reference')) {
            refObjectName = fieldObj.relatedObject || selectedValue.split(':')[0];
        }

        if (refObjectName) {
            this.loadPopupFields(refObjectName, 0);
        }
    }


    // Load popup fields from Apex
    loadPopupFields(sObjectApiName, columnIndex) {
        getFirstSelectList({ objectApiName: sObjectApiName })
            .then(result => {
                const parsed = JSON.parse(result);

                const fields = parsed.fieldsMapKeyList.map(label => {
                    const value = parsed.fieldsMap[label];
                    const relatedObject = parsed.referenceMap[value] || null;

                    return {
                        label,
                        value,
                        type: value.includes(':reference') ? 'reference' : 'normal',
                        relatedObject
                    };
                });

                this.popupColumns = [
                    ...this.popupColumns,
                    {
                        index: columnIndex,
                        sObjectApiName: parsed.sObjectApiName,
                        fields,
                        selectedValue: null
                    }
                ];
                this.isPopupOpen = true;
            })
            .catch(err => console.error('Error loading popup fields:', err));
    }
    handlePopupFieldSelect(event) {
        const colIndex = parseInt(event.target.dataset.index, 10);
        const selectedOptions = Array.from(event.target.selectedOptions).map(opt => opt.value);

        // Update selected value for this column
        this.popupColumns = this.popupColumns.map(col => {
            if (col.index === colIndex) {
                return { ...col, selectedValue: selectedOptions };
            }
            return col;
        });

        // Only process the last selected option
        const lastSelected = selectedOptions[selectedOptions.length - 1];
        if (!lastSelected) return;

        // Determine if selected field is a lookup
        let fieldObj = this.popupColumns[colIndex].fields.find(f => f.value === lastSelected);
        let relatedObject = null;

        if (fieldObj && fieldObj.type === 'reference') {
            relatedObject = fieldObj.relatedObject;
        } else if (lastSelected.includes(':reference')) {
            relatedObject = lastSelected.split(':')[0];
        }

        if (relatedObject) {
            // --- RULES ---
            // 1. If the table is not the last one, remove all tables after this one
            if (colIndex < this.popupColumns.length - 1) {
                this.popupColumns = this.popupColumns.slice(0, colIndex + 1);
            }

            // 2. If next table already exists, replace it
            const nextIndex = colIndex + 1;
            if (this.popupColumns[nextIndex] && this.popupColumns[nextIndex].sObjectApiName === relatedObject) {
                // Already loaded with same object, do nothing
                return;
            } else {
                // Remove any existing next table before adding
                this.popupColumns = this.popupColumns.slice(0, nextIndex);
            }

            // 3. Load new related table
            this.loadPopupFields(relatedObject, nextIndex);
        }
    }


    // --- Popup control ---
    showPopups() {
        this.isPopupOpen = true;
    }

    closePopup() {
        this.isPopupOpen = false;
        this.popupColumns = [];
        this.activePopupUid = null;
    }
    insertSelectedFields() {
        if (this.popupColumns.length === 0) return;

        let fullValue = '';
        let fullLabel = ''; // store label chain

        this.popupColumns.forEach(col => {
            if (col.selectedValue && col.selectedValue.length > 0) {
                const lastSelected = col.selectedValue[col.selectedValue.length - 1];

                // Keep API chain for backend
                fullValue += (fullValue ? '.' : '') + lastSelected.split(':')[0];

                // Build label chain for display using >
                const fieldObj = col.fields.find(f => f.value === lastSelected);
                if (fieldObj) {
                    fullLabel += (fullLabel ? ' > ' : '') + fieldObj.label.replace(' >', '');
                }
            }
        });

        if (fullValue) {
            const index = this.activePopupIndex;
            if (index != null) {
                // Ensure combo options include the full value
                if (!this.settingsList[index].fieldsArray.some(f => f.value === fullValue)) {
                    this.settingsList[index].fieldsArray = [
                        ...this.settingsList[index].fieldsArray,
                        { value: fullValue, label: fullLabel } // <-- store label with >
                    ];
                    console.log('full label =  ' + fullLabel);
                    console.log('full value =   ' + fullValue);
                }

                // Save API name for backend
                this.settingsList[index].FieldName = fullValue;

                // Save label chain for frontend display
                this.settingsList[index].FieldLabel = fullLabel;
            }
        }

        this.closePopup();
    }
}