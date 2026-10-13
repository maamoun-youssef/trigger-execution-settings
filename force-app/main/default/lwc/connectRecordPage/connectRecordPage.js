import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { RefreshEvent } from 'lightning/refresh';
import getData from '@salesforce/apex/PageLayoutController.loadData';
import { loadScript } from 'lightning/platformResourceLoader';
import ExcelJSScript from '@salesforce/resourceUrl/ExcelJS';
import { Labels } from "c/gridSettingsHelper";
import gridSettingsPlugin from 'c/gridSettingsPlugin'
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import LBL_Status from '@salesforce/label/c.LBL_Status';
import LBL_Save from '@salesforce/label/c.LBL_Save';
import Cancel from '@salesforce/label/c.Cancel';
import LBL_RelatedInformations from '@salesforce/label/c.LBL_RelatedInformations';
import LBL_NextSteps from '@salesforce/label/c.LBL_NextSteps';
import LBL_RequestedDocuments from '@salesforce/label/c.LBL_RequestedDocuments';
import LBL_AddNewTask from '@salesforce/label/c.LBL_AddNewTask';
import LBL_NoTasksToDisplay from '@salesforce/label/c.LBL_NoTasksToDisplay';
import cloneTask from '@salesforce/apex/PageLayoutController.cloneTask';
import deleteTask from '@salesforce/apex/PageLayoutController.deleteTask';

export default class ConnectRecordPage extends NavigationMixin(LightningElement) {
    Labels = {
        ...Labels,
        LBL_Status,
        LBL_Save,
        Cancel,
        LBL_RelatedInformations,
        LBL_NextSteps,
        LBL_RequestedDocuments,
        LBL_AddNewTask,
        LBL_NoTasksToDisplay
    };
    mainLoading = true;
    @track isManualEdit = false;
    @track cmpIsReady = false;
    @track popupFlow = false;
    @track isEditMode = false;
    @track showHeaderField = true;
    @track isPortal = false;
    @api templateId;
    @track headerField = { fieldName: '', isMandatory: false, isReadOnly: false };
    @track headerFieldValue;
    @track headerFieldDisplayType = '';
    @track customObjects = [];
    @track searchedObjects = [];
    @track screenFlowOptions = [];
    @track gridSettings = [];
    @track settings;
    @track selectedObject;
    @track actionButtons = [];
    @track fieldConfig;
    @track buttons;
    @track tabs;
    @track topLeftCornerfields = [];
    @track topRightCornerfields = [];
    @track bottomLeftCornerfields = [];
    @track bottomRightCornerfields = [];
    @track activityFields = [];
    @track taskRecords = [];
    @track actRecords = [];
    @track hoveredTask;
    @track hoveredTaskFields = [];
    hideHoverPanelTimeout;
    @track recordId;
    @track currentRecord = {};
    @track editFlow;
    @track p1Style = '';
    @track p2Style = '';
    @track p3Style = '';
    @track p4Style = '';
    @track statusIconStyle = '';
    @track objectName;
    @track cmp = gridSettingsPlugin;
    @track selectedFlow;
    @track selectedFlowLabel;
    @track inputs;
    @track newTaskFlow;
    @track relatedInformations;
    // @track relatedInformationsLabel = '';
    // @track relatedInformationsValue = '';
    sentDocumentCount = 0;
    globalLocationsCount = 0;
    contactsCount = 0;
    makeKey(prefix, ...parts) {
        return `${prefix}-${parts.map((part) => String(part ?? '')).join('-')}`;
    }
    get taskFieldsLength() {
        return (this.bottomRightCornerfields.length + 2);
    }
    get fileDirectoryManagerTabValue() {
        return this.tabs?.length + 1;
    }
    get hoveredTaskTitle() {
        if (!this.hoveredTask) {
            return 'Task details';
        }
        return this.hoveredTask.Subject || this.hoveredTaskFields?.[0]?.fieldValue || 'Task details';
    }
    get hasHeaderField() {
        return this.showHeaderField && !!this.headerField?.fieldName;
    }
    get isHeaderDate() {
        return this.headerFieldDisplayType === 'DATE' || this.headerFieldDisplayType === 'DATETIME';
    }
    get isHeaderReference() {
        return this.headerFieldDisplayType === 'REFERENCE';
    }
    get editFormKey() {
        return this.makeKey('edit-form', this.recordId, this.settings?.objectApiName);
    }
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                console.log('pageRef: ' + JSON.stringify(pageRef))
                this.recordId = pageRef.state.c__recordId != null ? pageRef.state.c__recordId : this.recordId;
                console.log('this.recordId1: ' + this.recordId)
                if (pageRef?.attributes?.recordId) {
                    this.recordId = pageRef.attributes.recordId;
                }
                console.log('this.recordId2: ' + this.recordId)
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error))
        }
    }

    connectedCallback() {
        try {
            loadScript(this, ExcelJSScript).then(() => {
            }).catch(error => {
                console.log(error.message);
                console.log(error.body?.message);
            });
            console.log('templateId: ' + JSON.stringify(this.templateId))
            addEventListener('resize', this.setPageSize);
            const inputAligncenter = document.createElement('style');
            inputAligncenter.innerText = '.input-text-align_right input{ text-align: right!important; }';
            document.body.appendChild(inputAligncenter);
            this.mainLoading = true;
            this.loadData();
            this.inputs = [{
                name: "recordId",
                type: "String",
                value: this.recordId
            }];
        } catch (error) {
            console.error(error);
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    renderedCallback() {
        this.setPageSize();
    }

    loadData() {
        getData({ recordId: this.recordId, templateId: this.templateId }).then(result => {
            console.log('result: ' + result)
            let parsedResult = JSON.parse(result);
            this.sentDocumentCount = parsedResult.sentDocuments;
            this.globalLocationsCount = parsedResult.globalLocations;
            this.contactsCount = parsedResult.contacts;
            this.isPortal = parsedResult.isPortal;
            this.relatedInformations = parsedResult.relatedInformations || [];
            console.log('>this.sentDocumentCount ' + this.sentDocumentCount);
            
            const style = document.createElement('style');
            if (this.isPortal) {
                style.innerText = `
                    .slds-modal.slds-fade-in-open.slds-modal_medium {
                        top: 45px !important;
                    }
                    .slds-modal.slds-fade-in-open.custom-modal {
                        margin-top: 70px !important;
                        justify-content: center;
                    }
                `;
            } else {
                style.innerText = `
                    .slds-modal.slds-fade-in-open.slds-modal_medium {
                        top: 200px !important;
                    }
                    .slds-modal.slds-fade-in-open.custom-modal {
                        margin-top: 214px !important;
                        justify-content: center;
                    }
                `;
            }
            document.body.appendChild(style);

            console.log('Query >>>>: ' + parsedResult.query)
            this.settings = parsedResult.settings;
            console.log('this.settings: ' + JSON.stringify(this.settings))
            this.currentRecord = parsedResult.record;
            console.log(' this.currentRecord: ' + JSON.stringify(this.currentRecord))
            if (this.currentRecord == null || this.currentRecord == '') {
                this.showNotification('Error', 'Aucun enregistrement trouvé', 'error', 'sticky')
                return;
            }
            this.p1Style = 'width:80px;height:80px;background-image: url(' + this.getIconValue(this.settings?.topLeftCornerLogo1, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
            this.p2Style = 'width:35px;height:35px;background-image: url(' + this.getIconValue(this.settings?.topLeftCornerLogo2, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
            this.p3Style = 'width:60px;height:60px;background-image: url(' + this.getIconValue(this.settings?.bottomLeftCornerLogo1, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;';
            this.p4Style = 'width:60px;height:60px;background-image: url(' + this.getIconValue(this.settings?.bottomLeftCornerLogo2, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;';
            this.statusIconStyle = 'width:60px;height:60px;background-image: url(' + this.getIconValue(this.settings?.statusIcon, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;';
            //this.recordStatus = parsedResult?.statusOptions?.find(p => p.value == this.currentRecord.Status__c)?.label;
            console.log('>>>>>>>>>>>>>>>>>>>>>>>>> this.currentRecord:' + JSON.stringify(this.currentRecord));
            console.log('>>>>>>>>>>>>>>>>>>>>>>>>> this.this.settings?.statusField:' + JSON.stringify(this.settings?.statusField));
            this.recordStatusValue = this.currentRecord[this.settings?.statusField];
            this.recordStatusLabel =  parsedResult.fields?.find(f => f.fieldName == this.settings?.statusField).fieldLabel;
            this.editFlow = this.settings?.selectedFlow;
            this.isManualEdit = !this.settings.isFlowMode;
            this.headerField = {
                ...(this.settings?.headerField || {}),
                fieldKey: this.makeKey('header-field', this.settings?.headerField?.fieldName)
            };
            this.showHeaderField = this.settings?.showHeaderField !== false
                && this.settings?.headerField?.showHeaderField !== false;
            console.log('this.headerField: ' + this.headerField)
            const headerFieldMetadata = parsedResult.fields?.find(f => f.fieldName == this.headerField?.fieldName);
            this.headerFieldDisplayType = headerFieldMetadata?.fieldType || '';
            if (this.headerFieldDisplayType === 'Date' || this.headerFieldDisplayType === 'DateTime') {
                this.headerFieldValue = new Date(this.currentRecord[this.headerField?.fieldName]);
            } else {
                this.headerFieldValue = this.currentRecord[this.headerField?.fieldName];
            }
            console.log('this.headerFieldValue: ' + JSON.stringify(this.headerFieldValue))
            this.fieldConfig = this.settings?.fieldsConfiguration;
            console.log('this.fieldConfig: ' + JSON.stringify(this.fieldConfig))
            this.newTaskFlow = this.settings?.newTaskFlow;	
            this.buttons = this.settings?.actionButtons;
            this.tabs = this.settings?.tabs;
            this.tabs.forEach((tab, index) => {
                tab.props = {...tab.params,templateName: tab.content, objectApiName: this.settings.objectApiName, recordId: this.recordId }
                tab.isGrid = tab.contentType == 'grid';
                tab.isLWC = tab.contentType == 'page';
                tab.tabKey = this.makeKey('tab', index, tab.label, tab.contentType, tab.content);
            });
            console.log('this.tabs: ' + JSON.stringify(this.tabs))
            this.fieldConfig.forEach((row, rowIndex) => {
                row.rowKey = this.makeKey('cfg-row', rowIndex);
                row.forEach((fieldObj, index) => {
                    let fieldd = parsedResult.fields.find(f => f.fieldName == fieldObj.fieldName);
                    let fieldwrapp = this.buildFieldWrapper(fieldd);
                    fieldwrapp.fieldValue = parsedResult.record[fieldObj.fieldName];
                    switch (fieldwrapp.fieldType) {
                        case "REFERENCE":
                            fieldwrapp.fieldValue = parsedResult.record[fieldObj.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            fieldwrapp.link = '/' + parsedResult.record[fieldObj.fieldName];
                            break;
                        case "PICKLIST":
                            if (parsedResult.record[fieldObj.fieldName] != null) {
                                fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == parsedResult.record[fieldObj.fieldName])?.label;
                            }
                            break;
                    }
                    if (row.length == 1) {
                        fieldwrapp.style = 'width:100%';
                    }
                    if (row.length == 3) {
                        fieldwrapp.style = 'width:33.33%';
                    }
                    if (row.length == 2) {
                        fieldwrapp.style = 'width:50%';
                    }
                    row[index] = {
                        ...fieldObj,
                        ...fieldwrapp,
                        fieldKey: this.makeKey('cfg-field', rowIndex, index, fieldObj.fieldName)
                    };
                });
            });
            console.log(' this.fieldConfig: ' + JSON.stringify(this.fieldConfig))
            parsedResult.topLeftCornerfields?.forEach((f, index) => {
                let fieldwrapp = this.buildFieldWrapper(f);
                f.fieldValue = parsedResult.record[f.fieldName];
                switch (fieldwrapp.fieldType) {
                    case "REFERENCE":
                        fieldwrapp.fieldValue = parsedResult.record[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        fieldwrapp.link = '/' + parsedResult.record[f.fieldName];
                        break;
                    case "PICKLIST":
                        console.log('testtt: ' + parsedResult.record[f.fieldName])
                        if (parsedResult.record[f.fieldName] != null) {
                            fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == parsedResult.record[f.fieldName]).label;
                        }
                        break;
                }
                if (index == 0) {
                    f.class = 'titleClass fontSize1'
                }
                else if (index == 1) {
                    f.class = 'bold2 fontSize1'
                }
                else if (index == 2) {
                    f.class = 'titleClass fontSize1'
                }
                else {
                    f.class = "titleClass fontSize3"
                }
                parsedResult.topLeftCornerfields[index] = {
                    ...f,
                    ...fieldwrapp,
                    fieldKey: this.makeKey('top-left', index, f.fieldName)
                };

            });
            this.topLeftCornerfields = [...parsedResult.topLeftCornerfields];
            console.log('this.topLeftCornerfields : ' + JSON.stringify(this.topLeftCornerfields))

            parsedResult.bottomLeftCornerfields?.forEach((f, index) => {
                let fieldwrapp = this.buildFieldWrapper(f);
                f.fieldValue = parsedResult.record[f.fieldName];
                switch (fieldwrapp.fieldType) {
                    case "REFERENCE":
                        fieldwrapp.fieldValue = parsedResult.record[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        fieldwrapp.link = '/' + parsedResult.record[f.fieldName];
                        break;
                    case "PICKLIST":
                        if (parsedResult.record[f.fieldName] != null) {
                            fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == parsedResult.record[f.fieldName]).label;
                        }
                        break;
                }
                if (index == 0) {
                    f.class = 'bold2 fontSize3'
                }
                else {
                    f.class = "titleClass fontSize3"
                }
                parsedResult.bottomLeftCornerfields[index] = {
                    ...f,
                    ...fieldwrapp,
                    fieldKey: this.makeKey('bottom-left', index, f.fieldName)
                };
            });
            this.bottomLeftCornerfields = [...parsedResult.bottomLeftCornerfields];
            console.log('this.bottomLeftCornerfields: ' + JSON.stringify(this.bottomLeftCornerfields))
            parsedResult.topRightCornerfields?.forEach((f, index) => {
                let fieldwrapp = this.buildFieldWrapper(f);
                f.fieldValue = parsedResult.record[f.fieldName];
                switch (fieldwrapp.fieldType) {
                    case "REFERENCE":
                        fieldwrapp.fieldValue = parsedResult.record[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        fieldwrapp.link = '/' + parsedResult.record[f.fieldName];
                        break;
                    case "PICKLIST":
                        if (parsedResult.record[f.fieldName] != null) {
                            fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == parsedResult.record[f.fieldName]).label;
                        }
                        break;
                }
                parsedResult.topRightCornerfields[index] = {
                    ...f,
                    ...fieldwrapp,
                    fieldKey: this.makeKey('top-right', index, f.fieldName)
                };
            });
            this.topRightCornerfields = [...parsedResult.topRightCornerfields];
            console.log('this.topRightCornerfields: ' + JSON.stringify(this.topRightCornerfields))
            let buttons = [];
            for (let index = 0; index < this.buttons?.length; index++) {
                const btn = this.buttons[index];
                let nbtn = {
                    key: this.makeKey('btn', index, btn?.flow, btn?.label),
                    label: btn?.label,
                    color: btn?.color,
                    flow: btn?.flow,
                    style: `background: ${btn?.color}; color: #fff;`
                }
                buttons.push(nbtn);
            }
            this.actionButtons = [...buttons];
            console.log('this.actionButtons: ' + JSON.stringify(this.actionButtons));
            this.bottomRightCornerfields = [...parsedResult.bottomRightCornerfields] || [];
            this.bottomRightCornerfields = this.bottomRightCornerfields.map((field, index) => ({
                ...field,
                fieldKey: this.makeKey('bottom-right', index, field.fieldName)
            }));
            console.log('this.bottomRightCornerfields: ' + JSON.stringify(this.bottomRightCornerfields))
            this.taskRecords = [...parsedResult.taskRecords] || [];
            this.mainLoading = false;
            this.taskRecords?.forEach((task, taskIndex) => {
                let fields = [];
                this.bottomRightCornerfields?.forEach((f, fieldIndex) => {
                    let fieldwrapp = this.buildFieldWrapper(f);
                    f.fieldValue = task[f.fieldName];
                    switch (fieldwrapp.fieldType) {
                        case "REFERENCE":
                            fieldwrapp.fieldValue = task[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            fieldwrapp.link = '/' + task[f.fieldName];
                            break;
                        case "PICKLIST":
                            if (task[f.fieldName] != null) {
                                fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == task[f.fieldName]).label;
                            }
                            break;
                    }
                    fields.push({
                        ...f,
                        ...fieldwrapp,
                        fieldKey: this.makeKey('task-field', task.Id, taskIndex, fieldIndex, f.fieldName)
                    });
                });
                task.fields = fields;
            });
            console.log('this.taskRecords: ' + JSON.stringify(this.taskRecords))
            this.activityFields = [...parsedResult.activityFields] || [];
            console.log('this.activityFields: ' + JSON.stringify(this.activityFields))
            this.actRecords = [...parsedResult.activityRecords] || [];
            this.actRecords?.forEach((task, idx) => {
                let fields = [];
                this.activityFields?.forEach((f, fieldIndex) => {
                    let fieldwrapp = this.buildFieldWrapper(f);
                    f.fieldValue = task[f.fieldName];
                    switch (fieldwrapp.fieldType) {
                        case "REFERENCE":
                            fieldwrapp.fieldValue = task[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            fieldwrapp.link = '/' + task[f.fieldName];
                            break;
                        case "PICKLIST":
                            if (task[f.fieldName] != null) {
                                fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == task[f.fieldName]).label;
                            }
                            break;
                    }
                    fields.push({
                        ...f,
                        ...fieldwrapp,
                        fieldKey: this.makeKey('activity-field', task.Id, idx, fieldIndex, f.fieldName)
                    });
                });
                const index = fields.findIndex(f => f.fieldName === 'Status__c');
                if (index > -1) {
                    const [statusField] = fields.splice(index, 1); // remove it
                    statusField.class = 'titleClass';
                    fields.unshift(statusField); // put it at the beginning
                }
                task.fields = fields;
                task.leftIconStyle = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + this.getIconValue(this.settings?.activityLeftIcon, task) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
                //let lookupIcon = this.settings?.activityRightIcon?.value?.split('.');
                // iconUrl = lookupIcon?.length == 1 ? task?.[lookupIcon[0]] :  task?.[lookupIcon[0]]?.[lookupIcon[1]];
                // let iconUrl = lookupIcon?.reduce((obj, key) => obj?.[key], task);
                task.rightIconStyle = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + this.getIconValue(this.settings?.activityRightIcon, task) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
                task.dashStyle = idx === this.actRecords.length - 1 ? 'padding-bottom:3rem;' : 'border-left: 1px dashed black;';
            });
            console.log('this.actRecords: ' + JSON.stringify(this.actRecords))
        });
    }

    buildFieldWrapper(fieldd) {
        let fieldObj = {};
        fieldObj.fieldType = fieldd.fieldType;
        fieldObj.fieldName = fieldd.fieldName;
        fieldObj.isNumberField = fieldd.fieldType == 'DOUBLE' || fieldd.fieldType == 'PERCENT' || fieldd.fieldType == 'NUMBER' || fieldd.fieldType == 'CURRENCY' ? true : false;
        // fieldObj.isReference = (fieldd.fieldType == 'REFERENCE' && !fieldd.fieldName.endsWith('RecordTypeId')) || fieldd.fieldName == 'Name';
        fieldObj.isReference = (fieldd.fieldType == 'REFERENCE' && !fieldd.fieldName.endsWith('RecordTypeId'));
        fieldObj.isUrl = fieldd.fieldType == 'URL';
        fieldObj.isDate = fieldd.fieldType == 'DATE';
        fieldObj.isDateTime = fieldd.fieldType == 'DATETIME';
        fieldObj.isPicklist = fieldd.fieldType == 'PICKLIST';
        fieldObj.isBoolean = fieldd.fieldType == 'BOOLEAN';
        fieldObj.isTextArea = fieldd.fieldType == 'TEXTAREA';
        fieldObj.isHtmlFormatted = fieldd.isHtmlFormatted && !fieldd.isBoolean;
        fieldObj.isText = !fieldObj.isNumberField && !fieldObj.isReference && !fieldObj.isDate
            && !fieldObj.isDateTime && !fieldObj.isPicklist && !fieldObj.isBoolean && !fieldObj.isUrl;
        fieldObj.scale = fieldd.scale;
        fieldObj.fieldLabel = fieldd.fieldLabel;
        fieldObj.pickListValues = fieldd.picklistValues;
        return fieldObj;
    }

    getIconValue(icon, record) {
        return icon?.isStaticRessource  ? (this.isPortal ? '/sfsites/c' + icon?.value : icon?.value) : record[icon?.value];
    }

    handleSuccess(event) {
        this.formIsLoading = false; // hide spinner
        this.isEditMode = false; // close edit mode if you are toggling edit/view
        this.showNotification('Success', 'Enregistrement mis à jour avec succès!', 'success', '');
        this.loadData();
    }

    handleReset() {
        this.popupFlow = false;
        this.isEditMode = false;
    }

    handleSecondTab(evt) {
        console.log('evt.target.dataset: ' + JSON.stringify(evt.target.dataset))
        let grid = evt.target.dataset.grid;
        if (grid) {
            this.cmpIsReady = true;
        }
    }

    handleRecordCall(event) {
        let name = event.target.dataset.name;
        console.log('name: ' + name)
        let task = event.target.dataset.task;
        if (name) {
            this.selectedFlow = name;
            console.log('this.selectedFlow: ' + JSON.stringify(this.selectedFlow))
            this.selectedFlowLabel = task ? this.Labels.LBL_AddNewTask : this.actionButtons?.find(f => f.flow == this.selectedFlow)?.label;
            this.popupFlow = true;
        }
    }

    handleFlowStatusChange(event) {
        console.log(JSON.stringify(event.detail));
        //TODO : store the output values (event.detail.outputVariables)
        console.log('event.detail.status: ' + event.detail.status)
        if (/* event.detail.status === "ERROR" ||  */event.detail.status === "FINISHED" || event.detail.status == undefined) {
            if (event.detail.status === "FINISHED") {
                this.mainLoading = true;
                this.loadData();
            }
            this.popupFlow = false;
            this.dispatchEvent(new RefreshEvent());

        }
        this.isEditMode = false;
    }

    handleEditMode() {
        this.isEditMode = !this.isEditMode;
        if (!this.isManualEdit) {
            this.selectedFlow = this.editFlow;
            this.selectedFlowLabel = this.editFlow;
            this.popupFlow = true
        }
    }

    handleFormLoaded() {
        if (this.isEditMode) {
            this.setPageSize();
        }
    }

    handleTaskMouseEnter(event) {
        if (this.hideHoverPanelTimeout) {
            clearTimeout(this.hideHoverPanelTimeout);
            this.hideHoverPanelTimeout = null;
        }
        const taskId = event.currentTarget.dataset.taskId;
        if (!taskId) {
            return;
        }
        const task = this.taskRecords?.find(item => item.Id === taskId);
        if (!task) {
            return;
        }
        this.hoveredTask = task;
        this.hoveredTaskFields = (task.fields || []).filter(
            (field) => field.fieldValue !== null && field.fieldValue !== undefined && field.fieldValue !== ''
        );
    }

    handleTaskMouseLeave() {
        this.hideHoverPanelTimeout = setTimeout(() => {
            this.hoveredTask = null;
            this.hoveredTaskFields = [];
        }, 160);
    }

    handleHoverPanelMouseEnter() {
        if (this.hideHoverPanelTimeout) {
            clearTimeout(this.hideHoverPanelTimeout);
            this.hideHoverPanelTimeout = null;
        }
    }

    handleHoverPanelMouseLeave() {
        this.hoveredTask = null;
        this.hoveredTaskFields = [];
    }

    handleDeleteTask(event) {
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.taskId;
        if (!taskId) {
            return;
        }
        this.isLoading = true;
        deleteTask({ taskId })
            .then(() => {
                this.showNotification('Success', 'Task deleted successfully.', 'success', '');
                this.hoveredTask = null;
                this.hoveredTaskFields = [];
                this.loadData();
            })
            .catch((error) => {
                this.showNotification('Error', error?.body?.message || 'Error while deleting task.', 'error', 'sticky');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCloneTask(event) {
        event.stopPropagation();
        const taskId = event.currentTarget.dataset.taskId;
        if (!taskId) {
            return;
        }
        this.isLoading = true;
        cloneTask({ taskId })
            .then(() => {
                this.showNotification('Success', 'Task cloned successfully.', 'success', '');
                this.loadData();
            })
            .catch((error) => {
                this.showNotification('Error', error?.body?.message || 'Error while cloning task.', 'error', 'sticky');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    //HANDLE TOGGLES
    toggleDiv1(event) {
        console.log('toggleDiv1')
        let div3 = this.template.querySelector('.div3');
        let div1 = this.template.querySelector('.div1');
        let div1Toggle = this.template.querySelector('.div1Toggle');
        let div3Toggle = this.template.querySelector('.div3Toggle');
        this.showElement(div1);
        this.showElement(div3Toggle);
        this.hideElement(div3);
        this.hideElement(div1Toggle);
    }

    toggleDiv3(event) {
        console.log('toggleDiv3')
        let div3 = this.template.querySelector('.div3');
        let div1 = this.template.querySelector('.div1');
        let div1Toggle = this.template.querySelector('.div1Toggle');
        let div3Toggle = this.template.querySelector('.div3Toggle');
        this.showElement(div3);
        this.showElement(div1Toggle);
        this.hideElement(div1);
        this.hideElement(div3Toggle);
    }

    showElement(element) {
        element.classList.add('dinline');
        element.classList.remove('dnone');
    }
    hideElement(element) {
        element.classList.add('dnone');
        element.classList.remove('dinline');
    }

    // handleAddTask() {
    //     const defaultValues = encodeDefaultFieldValues({
    //         WhatId: this.recordId
    //     });

    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__objectPage',
    //         attributes: {
    //             objectApiName: 'Task',
    //             actionName: 'new'
    //         },
    //         state: {
    //             defaultFieldValues: defaultValues
    //         }
    //     });
    // }

    //LIFECYCLE
    setPageSize = () => {
        try {
            let fieldsConfigurationDiv = this.template.querySelector(".fieldsConfigurationDiv");
            let buttonGroupContainer = this.template.querySelector(".buttonGroupContainer");
            let statusTitle = this.template.querySelector(".statusTitle");
            let statusList = this.template.querySelector(".statusList");
            if (
                fieldsConfigurationDiv != null &&
                buttonGroupContainer != null &&
                statusTitle != null &&
                statusList != null
            ) {
                statusList.style.height = (buttonGroupContainer.offsetHeight + fieldsConfigurationDiv.offsetHeight) - statusTitle.offsetHeight - 12 + "px";
            }
            let tabSetClass = this.template.querySelector(".tabSetClass");
            let div2 = this.template.querySelector(".div2");
            if (
                tabSetClass != null &&
                div2 != null
            ) {
                tabSetClass.style.width = div2.offsetWidth + "px";
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    }

    //MISC
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}