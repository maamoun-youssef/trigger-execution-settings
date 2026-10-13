import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { RefreshEvent } from 'lightning/refresh';
import getData from '@salesforce/apex/WorkflowLayoutViewCtrl.loadData';
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
import cloneTask from '@salesforce/apex/WorkflowLayoutViewCtrl.cloneTask';
import deleteTask from '@salesforce/apex/WorkflowLayoutViewCtrl.deleteTask';

export default class WorkflowLayoutView extends NavigationMixin(LightningElement) {
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
    //@track isLoading = false;
    //@track isManualEdit = false;
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
    @track theme;
    @track screenFlowOptions = [];
    @track gridSettings = [];
    @track settings;
    @track selectedObject;
    @track actionButtons = [];
    @track fieldConfig;
    @track buttons;
    @track tabs;
    @track activityFields = [];
    @track taskRecords = [];
    @track actRecords = [];
    @track hoveredTask;
    @track hoveredTaskFields = [];
    hideHoverPanelTimeout;
    @track recordId;
    @track currentRecord = {};
    @track editFlow;
    @track statusIconStyle = '';
    @track objectName;
    @track gridSettingsPlugin = gridSettingsPlugin;
    @track selectedFlow;
    @track selectedFlowLabel;
    @track inputs;
    @track newTaskFlow;
    makeKey(prefix, ...parts) {
        return `${prefix}-${parts.map((part) => String(part ?? '')).join('-')}`;
    }
    get hoveredTaskTitle() {
        if (!this.hoveredTask) {
            return 'Task details';
        }
        return this.hoveredTask.Subject || this.hoveredTaskFields?.[0]?.fieldValue || 'Task details';
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                this.recordId = pageRef.state.c__recordId != null ? pageRef.state.c__recordId : this.recordId;
                if (pageRef?.attributes?.recordId) {
                    this.recordId = pageRef.attributes.recordId;
                }
                console.log('this.recordId: ' + this.recordId)
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
        const wrappers = this.template.querySelectorAll('.theme-wrapper');
        const div1 = this.template.querySelector('.div1');
        if (wrappers.length && this.theme?.themeAttributes) {
            const brandColor = this.theme.themeAttributes.brandColor;
            div1.style.setProperty('background-color', this.theme.themeAttributes.bgColor);
            wrappers.forEach(wrapper => {
                wrapper.style.setProperty('--slds-g-color-brand-base-50', brandColor);
                wrapper.style.setProperty('--slds-c-button-brand-color-background', brandColor);
                wrapper.style.setProperty('--slds-c-button-brand-color-border', brandColor);
                wrapper.style.setProperty('--slds-c-input-color-border-focus', brandColor);
                wrapper.style.setProperty('--slds-c-button-brand-text-color', '#FFFFFF');
                wrapper.style.setProperty('--slds-c-button-brand-text-color-hover', '#FFFFFF');
            });
        }
    }
    @track leftSections = [];
    @track rightSections = [];
    @track mainSections = [];
    @track leftSectionFirstCard;
    loadData() {
        getData({ recordId: this.recordId, templateId: this.templateId }).then(result => {
            console.log('result: ' + result)
            let parsedResult = JSON.parse(result);
            this.isPortal = parsedResult.isPortal;
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
            this.parsedResult = parsedResult;
            this.settings = parsedResult.settings;
            this.theme = parsedResult.theme;
            console.log('this.settings: ' + JSON.stringify(this.settings))
            this.currentRecord = parsedResult.record;
            console.log(' this.currentRecord: ' + JSON.stringify(this.currentRecord))
            if (this.currentRecord == null || this.currentRecord == '') {
                this.showNotification('Error', 'Aucun enregistrement trouvé', 'error', 'sticky')
                return;
            }
            let leftSections = [];
            let rightSections = [];
            let mainSections = [];
            this.settings?.sections?.forEach(section => {
                console.log('section before: ' + JSON.stringify(section))
                this.buildSectionData(section);
                console.log('section before after: ' + JSON.stringify(section))
                if (section.region == 'sidebar') leftSections.push(section);
                if (section.region == 'right') rightSections.push(section);
                if (section.region == 'main') mainSections.push(section);
            });
            this.leftSections = [...leftSections].sort((a, b) => a.order - b.order).map((section, index) => ({
                ...section,
                showLabel: index !== 0,
                style: index === 0 ? 'background:#FFFFFF;' : '',
                fieldValueStyle: index === 0 ? 'color:#595959;font-weight:600;font-size:16px;' : 'color:#FFFFFF;font-weight:500;font-size:14px;',
                fieldLabelStyle: index === 0 ? '' : 'color:#FFFFFF;font-weight:600;font-size:17px;',
                linkStyle: index === 0 ? 'color:#595959;font-weight:600;font-size:17px;text-decoration:underline;' : 'color:#FFFFFF;font-weight:500;font-size:14px;text-decoration:underline;'
            }));
            this.rightSections = [...rightSections].sort((a, b) => a.order - b.order);
            this.mainSections = [...mainSections].sort((a, b) => a.order - b.order);
            console.log('this.leftSections: ' + JSON.stringify(this.leftSections))
            console.log('this.rightSections: ' + JSON.stringify(this.rightSections))
            console.log('this.mainSections: ' + JSON.stringify(this.mainSections))
            this.mainLoading = false;
            return;
        });
    }
    buildSectionData(section) {
        section.isFieldGroup = section.styleVariant === 'fieldGroup';
        section.isImageFields = section.styleVariant === 'imageFields';
        section.isActionBar = section.styleVariant === 'actionBar';
        section.isTabset = section.styleVariant === 'tabset';
        section.isStatusCard = section.styleVariant === 'statusCard';
        section.isTimelineCard = section.styleVariant === 'TimelineCard';
        section.isTaskList = section.styleVariant === 'taskList';
        section.isComponent = section.styleVariant === 'Component';
        section.isHeaderCard = section.styleVariant === 'HeaderCard';
        section.isAgregatesCard = section.styleVariant === 'AgregatesCard';
        section.sectionKey = `section-${section.region}-${section.order}-${Date.now()}`
        section?.icons?.forEach(icon => {
            icon.isPrimary = icon.type == 'primary';
            icon.isSecondary = icon.type == 'secondary';
            console.log('icon.contentType: ' + JSON.stringify(icon.contentType))
            icon.style = (icon.type == 'primary' ? 'width:80px;height:80px;' : 'width:40px;height:40px;') + 'opacity: 0.5;background-image: url(' + this.getIconValue(icon, this.currentRecord) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'

        });
        section.primaryIcon = section.icons.find(icon => icon.type == 'primary')
        section.secondaryIcon = section.icons.find(icon => icon.type == 'secondary')
        const styles = section.titleStyle?.split(';');
        const themeBg = this.theme?.themeAttributes?.bgColor || '';
        const themeBrand = this.theme?.themeAttributes?.brandColor || '';
        if (!section.titleStyle) {
            section.titleStyle = `background-color:${themeBg};color:white;`;
        } else {
            const bgMatch = section.titleStyle.match(/background-color\s*:\s*([^;]*)/i);
            const colorMatch = section.titleStyle.match(/(?:^|;)\s*color\s*:\s*([^;]*)/i);
            const bg = bgMatch?.[1]?.trim();
            const color = colorMatch?.[1]?.trim();
            const finalBg = bg || themeBg;
            const finalColor = color || 'white';
            section.titleStyle = `background-color:${finalBg};color:${finalColor};`;
        }
        
        if (section.isTimelineCard) {
            this.activityFields = [...this.parsedResult.fieldsMap.activityObject] || [];
            console.log('this.activityFields: ' + JSON.stringify(this.activityFields))
            this.actRecords = [...this.parsedResult.activityRecords] || [];
            this.actRecords?.forEach((activity, idx) => {
                let fields = [];
                this.activityFields?.forEach((f, fieldIndex) => {
                    console.log('fieldooo 1: ' + JSON.stringify(f))
                    let fieldwrapp = this.buildFieldWrapper(f);
                    f.fieldValue = activity[f.fieldName];
                    switch (fieldwrapp.fieldType) {
                        case "REFERENCE":
                            fieldwrapp.fieldValue = activity[f.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            fieldwrapp.link = '/' + activity[f.fieldName];
                            break;
                        case "PICKLIST":
                            if (activity[f.fieldName] != null) {
                                fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == activity[f.fieldName]).label;
                            }
                            break;
                    }
                    fields.push({
                        ...f,
                        ...fieldwrapp,
                        fieldKey: this.makeKey('activity-field', activity.Id, idx, fieldIndex, f.fieldName)
                    });
                });
                activity.fields = fields;
                activity.leftIconStyle = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + this.getIconValue(section.primaryIcon, activity) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'

                activity.rightIconStyle = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + this.getIconValue(section?.secondaryIcon, activity) + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
                activity.dashStyle = idx === this.actRecords.length - 1 ? 'padding-bottom:3rem;' : 'border-left: 1px dashed black;';
            });
        }
        if (section.isTaskList) {
            this.taskRecords = [...this.parsedResult.taskRecords] || [];
            this.taskRecords?.forEach((task, taskIndex) => {
                let fields = [];
                this.parsedResult.fieldsMap.taskObject?.forEach((f, fieldIndex) => {
                    let fieldCopy = { ...f, fieldValue: task[f.fieldName] };
                    let fieldwrapp = this.buildFieldWrapper(fieldCopy);
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
                        ...fieldCopy,
                        ...fieldwrapp,
                        fieldKey: this.makeKey('task-field', task.Id, taskIndex, fieldIndex, f.fieldName)
                    });
                });
                task.fields = fields;
            });
            section.fields = section.fields.flat().map(field => {
                const fieldMetadata = this.parsedResult.fieldsMap.taskObject?.find(
                    f => f.fieldName === field.fieldName
                );
                return {
                    ...field,
                    fieldLabel: fieldMetadata?.fieldLabel || field.fieldName,
                    fieldType: fieldMetadata?.fieldType || ''
                };
            });
            section.fieldsLength = section.fields.length + 1;
        }
        if (section.isFieldGroup) {
            section.fields.forEach((row, rowIndex) => {
                row.rowKey = this.makeKey('cfg-row', rowIndex);
                row.forEach((fieldObj, index) => {
                    let fieldd = this.parsedResult.fieldsMap.currentObject.find(f => f.fieldName == fieldObj.fieldName);
                    let fieldwrapp = this.buildFieldWrapper(fieldd);
                    fieldwrapp.fieldValue = this.currentRecord[fieldObj.fieldName];
                    switch (fieldwrapp.fieldType) {
                        case "REFERENCE":
                            fieldwrapp.fieldValue = this.currentRecord[fieldObj.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                            fieldwrapp.link = '/' + this.currentRecord[fieldObj.fieldName];
                            break;
                        case "PICKLIST":
                            if (this.currentRecord[fieldObj.fieldName] != null) {
                                fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == this.currentRecord[fieldObj.fieldName])?.label;
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
            console.log('group section.fields: ' + JSON.stringify(section.fields));
        }
        if (!section.isFieldGroup && !section.isTaskList && !section.isTimelineCard) {
            section.fields = section.fields.flat();
            console.log('section.isHeaderCard.fields: ' + JSON.stringify(section.isHeaderCard))
            console.log('section.fields: ' + JSON.stringify(section.fields))
            let fields = [...this.parsedResult.fieldsMap.currentObject]
            console.log('fields: ' + JSON.stringify(fields));
            section.fields?.forEach((field, index) => {
                let ff = fields?.find(f => f.fieldName == field.fieldName);
                let fieldwrapp = this.buildFieldWrapper(ff);
                //field.fieldValue = this.currentRecord[field.fieldName];
                switch (fieldwrapp.fieldType) {
                    case "REFERENCE":
                        fieldwrapp.fieldValue = this.currentRecord[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        fieldwrapp.link = '/' + this.currentRecord[field.fieldName];
                        break;
                    case "PICKLIST":
                        if (this.currentRecord[field.fieldName] != null) {
                            fieldwrapp.fieldValueTranslated = fieldwrapp?.pickListValues.find(p => p.value == this.currentRecord[field.fieldName]).label;
                            fieldwrapp.fieldValue = fieldwrapp?.pickListValues.find(p => p.value == this.currentRecord[field.fieldName]).label;
                        }
                        break;
                    default:
                        fieldwrapp.fieldValue = this.currentRecord[field.fieldName];
                        break;
                }
                console.log('fieldwrapp.fields:' + JSON.stringify(fieldwrapp));
                // if (index == 0) {
                //     field.class = 'titleClass fontSize1'
                // }
                // else if (index == 1) {
                //     field.class = 'bold2 fontSize1'
                // }
                // else if (index == 2) {
                //     field.class = 'titleClass fontSize1'
                // }
                // else {
                //     field.class = "titleClass fontSize3"
                // }
                section.fields[index] = {
                    ...ff,
                    ...fieldwrapp,
                    ...field,
                    fieldKey: this.makeKey('top-left', index, field.fieldName)
                };
                console.log('section.fields[index].fields:' + JSON.stringify(section.fields[index]));
            });
        }
        console.log('section.fields.fields:' + JSON.stringify(section.fields));
        if (section.isTabset) {
            this.tabs = section?.tabset;
            console.log('section?.tabset: ' + JSON.stringify(section?.tabset))
            section?.tabset?.forEach((tab, index) => {
                tab.props = tab.component.type === 'grid' ? { ...tab.component.params, templateName: tab.component.name, objectApiName: this.settings.objectApiName, recordId: this.recordId } : { recordId: this.recordId }
                console.log('tab.props: ' + JSON.stringify(tab.props))
                tab.isGrid = tab.component.type == 'grid';
                tab.isLWC = tab.component.type == 'page';
                tab.tabKey = this.makeKey('tab', index, tab.label, tab.component.type, tab.component.name);
                tab.cmp = tab.component.type === 'grid' ? this.gridSettingsPlugin : tab.component.name;
            });
            console.log('section?.tabset ' + JSON.stringify(section?.tabset))
        }
        if (section.components?.length) {
            section.components = section.components.map((component, index) => {
                return {
                    ...component,
                    props: component.type === 'grid' ? {
                        ...(component.params || {}),
                        templateName: component.name,
                        objectApiName: this.settings.objectApiName,
                        recordId: this.recordId
                    } : { recordId: this.recordId },
                    isGrid: component.type === 'grid',
                    isLWC: component.type === 'page',
                    cmp: component.type === 'grid' ? this.gridSettingsPlugin : component.name,
                    componentKey: this.makeKey(
                        'component',
                        index,
                        component.type,
                        component.name
                    )
                };
            });
            console.log('section.components:', JSON.stringify(section.components));
        }
        if (section.isAgregatesCard) {
            let key = `${section.region}-${section.order}`;
            section.aggregatesData = this.parsedResult.sectionsAgregates?.[key] || [];
        }
        if (section?.header?.fieldName != '') {
            section.headerField = this.parsedResult?.fieldsMap?.currentObject?.find(
                f => f.fieldName === section?.header?.fieldName
            );
            section.headerField = this.buildFieldWrapper(section.headerField)
            section.headerField.fieldValue = this.currentRecord[section.headerField.fieldName];
            switch (section.headerField.fieldType) {
                case "REFERENCE":
                    section.headerField.fieldValue = this.currentRecord[section.headerField.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                    section.headerField.link = '/' + this.currentRecord[section.headerField.fieldName];
                    break;
                case "PICKLIST":
                    if (this.currentRecord[section.headerField.fieldName] != null) {
                        section.headerField.fieldValueTranslated = section?.headerField?.pickListValues?.find(p => p.value == this.currentRecord[section.headerField.fieldName]).label;
                    }
                    break;
            }
        }
        console.log('section.headerField ????: ' + JSON.stringify(section.headerField));
        section.actions = (section.actions || [])
            .map((action, index) => ({
                id: `action_${index}`,
                label: action.label,
                iconName: action.icon,
                order: Number(action.order),
                isIcon: action.actionType === 'icon',
                isButton: action.actionType === 'button',
                isText: action.actionType === 'text',
                isOnClick: action.actionType === 'onclick',
                isFlow: action.redirectionType === 'flow',
                isUrl: action.redirectionType === 'url',
                color: action.color ? `background-color:${action.color};` : themeBrand ? `background-color:${themeBrand};` : '',
                redirectionValue: action.redirectionValue,
                redirectionType: action.redirectionType,
                displayValue: action.label,
                iconStyle: `opacity:0.5;
                    width:30px;
                    height:30px;
                    background-image:url(${action.icon});
                    background-size:contain;
                    background-position:left;
                    background-repeat:no-repeat;`
            }))
            .sort((a, b) => a.order - b.order);
        if (section.isImageFields || section.isHeaderCard) {
            const clickAction = section.actions?.find(action => action.isOnClick);
            section.clickAction = clickAction || {};
            section.isClickable = !!clickAction;
            section.sectionClass = `section ${clickAction?.redirectionValue != null ? 'clickable-section' : ''} slds-grid slds-p-top_medium slds-p-left_medium`;
            console.log('is image fields:' + JSON.stringify(section));
        }
        if (section.isFieldGroup || section.isTaskList) {
            if (section.actions.length) {
                section.isManualEdit = false;
                section.actions = section.actions?.[0] ?? null;
                section.isClickable = !!section.actions;
                section.sectionClass = `section ${section.actions ? 'clickable-section' : ''}`;
            } else {
                section.isManualEdit = true;
            }
        }
        console.log('this.leftSections: ' + JSON.stringify(this.leftSections))
    }
    buildFieldWrapper(fieldd) {
        let fieldObj = {};
        console.log('fieldd: ' + JSON.stringify(fieldd))
        fieldObj.fieldType = fieldd.fieldType;
        fieldObj.fieldName = fieldd.fieldName;
        fieldObj.isNumberField = fieldd.fieldType == 'DOUBLE' || fieldd.fieldType == 'PERCENT' || fieldd.fieldType == 'NUMBER' || fieldd.fieldType == 'CURRENCY' ? true : false;
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
        let val = icon.contentType != 'field' ? (this.isPortal ? '/sfsites/c' + icon?.name : icon?.name) : record[icon?.name];
        console.log('val: ' + val)
        return val;
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
        let name = event.currentTarget.dataset.name;
        let type = event.currentTarget.dataset.type;
        let title = event.currentTarget.dataset.title;
        console.log('name: ' + name);
        console.log('type: ' + type);
        if (type === 'flow') {
            this.selectedFlow = name;
            console.log('this.selectedFlow: ' + JSON.stringify(this.selectedFlow))
            this.selectedFlowLabel = title;
            this.popupFlow = true;
        }
        if (type === 'url' && name) {
            if (name.startsWith('/')) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: name
                    }
                });
            } else {
                window.open(name, '_blank');
            }
        }
    }
    handleStopPropagation(event) {
        event.stopPropagation();
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

    handleEditMode(event) {
        let sectionIndex = event.currentTarget.dataset.index;
        let region = event.currentTarget.dataset.region;
        let isManualEdit = event.currentTarget.dataset.ismanualedit === 'true';
        let flow = event.currentTarget.dataset.flow;
        console.log('>>>>>>>>>>>>>> isManualEdit: ' + isManualEdit);
        console.log('>>>>>>>>>>>>>> isManualEdit dataset: ' + event.currentTarget.dataset.ismanualedit === 'true');
        this.isEditMode = !this.isEditMode;
        if (!isManualEdit) {
            this.selectedFlow = flow;
            this.selectedFlowLabel = flow;
            this.popupFlow = true
        }
    }
    handleSectionsAction(event) {
        let sectionIndex = event.currentTarget.dataset.index;
        let action = event.currentTarget.dataset.action;

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
        this.mainLoading = true;
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
        this.mainLoading = true;
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