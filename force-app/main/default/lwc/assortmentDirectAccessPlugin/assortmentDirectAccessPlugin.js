import { LightningElement, wire, track, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//APEX
import initData from "@salesforce/apex/AssortmentDirectAccessPluginCtrl.initData";
import getAssortments from "@salesforce/apex/AssortmentDirectAccessPluginCtrl.getAssortments";
import sendEmail from '@salesforce/apex/AssortmentDirectAccessPluginCtrl.sendEmail';
//ASSORTMENT MATRIX FUNCTIONS
// import processRestForExcel from '@salesforce/apex/AssortmentMatrixCtrl.processRestForExcel';
//ASSORTMENT CHANNEL BUDGET FUNCTIONS

import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Last from "@salesforce/label/c.LBL_Last";

import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import Email_Form from "@salesforce/label/c.Email_Form";
import emailBcc from "@salesforce/label/c.emailBcc";
import emailCc from "@salesforce/label/c.emailCc";
import EmailTo from "@salesforce/label/c.EmailTo";
import Email_Body from "@salesforce/label/c.Email_Body";
import Subject from "@salesforce/label/c.Subject";
import Send from "@salesforce/label/c.Send";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Record_Type from "@salesforce/label/c.LBL_Record_Type";
import BUTarget from '@salesforce/schema/Assortment__c.BusinessUnitTarget__c';
import BUSource from '@salesforce/schema/Assortment__c.BusinessUnitSource__c';
import Hierarchy__c from '@salesforce/schema/Assortment__c.Hierarchy__c';
import RecordTypeId from '@salesforce/schema/Assortment__c.RecordTypeId';
import Year from '@salesforce/schema/Assortment__c.Year__c';
import isOnTop from '@salesforce/schema/Assortment__c.OnTop__c';
import isBreakingScenario from '@salesforce/schema/Assortment__c.IsBreakingScenario__c';
import OrgaBU from '@salesforce/schema/BusinessUnit__c';
import Hierarchy_OBJECT from '@salesforce/schema/Hierarchy__c';
import Assortment from '@salesforce/schema/Assortment__c';

export default class AssortmentDirectAccessPlugin extends NavigationMixin(LightningElement) {
    @api recordId;
    @api defaultRecordTypes;
    @track sortField = '';
    @track sortDirection = 'DESC';
    targetAddress = '';
    cc = '';
    bcc = '';
    subject = '';
    name = '';
    body = '';
    selectedId = '';
    assortmentName = '';
    @track labels = {
        LBL_No_Item_To_Display,
        LBL_Previous,
        LBL_Next,
        LBL_First,
        LBL_Last,
        Email_Form,
        emailBcc,
        emailCc,
        EmailTo,
        Email_Body,
        LBL_Cancel,
        Subject,
        Send,
        Year: '',
        BUTarget: '',
        BUSource: '',
        Hierarchy: '',
        RecordType: '',
        isOnTop: '',
        isBreakingScenario: '',
        LBL_Record_Type,
    }
    @track showPaginationSection = false;
    @track pageNumber = 1;
    totalPagesCount = 0;
    prefix;
    pageSizeOptions = [{ label: '10', value: 10, isSelected: false },
    { label: '25', value: 25, isSelected: false },
    { label: '50', value: 50, isSelected: true },
    { label: '75', value: 75, isSelected: false },
    { label: '100', value: 100, isSelected: false }];
    searchBUfields = ['Name'];
    searchHierarchyfields = ['Name'];
    gridSettingsManager = {};
    loading = false;
    isEmailPopup = false;
    tableLoading = false;
    stringifiedSelectedRecordType = '';
    records = [];
    orgaBUObject = OrgaBU.objectApiName;
    HierarchyObject = Hierarchy_OBJECT.objectApiName;
    Events = {
        handleChangeMultiRT: 'handlechangemultirt',
        selectbutarget: 'selectbutarget',
        selectbusource: 'selectbusource',
        selecthierarchy: 'selecthierarchy',
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    }
    filter = {
        year: (new Date()).getFullYear(),
        buTarget: '',
        buSource: '',
        hierarchy: '',
        recordTypes: []
    }
    @track displayedFields = [];
    @track yearsOptions = [];
    recordTypesOptions = [];
    picklistValuesMap = [];
    recordTypeInfos = {};
    stringifiedSelectedYears = '';

    @wire(getObjectInfo, { objectApiName: Assortment }) assortmentObj({ error, data }) {
        if (data) {
            this.recordTypesOptions = JSON.stringify(Object.values(data.recordTypeInfos).map(rt => ({ label: rt.name, value: rt.recordTypeId })));
            this.labels.Year = data.fields[Year.fieldApiName].label;
            this.labels.BUTarget = data.fields[BUTarget.fieldApiName].label;
            this.labels.BUSource = data.fields[BUSource.fieldApiName].label;
            this.labels.Hierarchy = data.fields[Hierarchy__c.fieldApiName].label;
            this.labels.RecordType = data.fields[RecordTypeId.fieldApiName].label;
            this.labels.isOnTop = data.fields[isOnTop.fieldApiName].label;
            this.labels.isBreakingScenario = data.fields[isBreakingScenario.fieldApiName].label;
        } else {
            console.log(error);
        }
    }

    get buTargetFilterToken() {
        let conditions = [];
        conditions.push('(SetAssortmentNegoBUTarget__c = TRUE OR SetAssortmentBudgetBUTarget__c = TRUE OR SetAssortmentTargetBUTarget__c = TRUE)');
        return conditions;
    }

    get buSourceFilterToken() {
        let conditions = [];
        conditions.push('(SetAssortmentBudgetBUSource__c = TRUE OR SetAssortmentNegoBUSource__c = TRUE OR SetAssortmentTargetBUSource__c = TRUE)');
        return conditions;
    }

    get hierarchyFilterToken() {
        let conditions = [];
        conditions.push('(SetAssortmentLevel__c = TRUE)');
        return conditions;
    }

    handleChangeMultiRT(event) {
        let values = [];
        console.log('event.detail.selOptions: ' + JSON.stringify(event.detail.selOptions))
        event.detail.selOptions.forEach(item => {
            if (item.hasOwnProperty('value')) {
                values.push(item.value);
            } else {
                values.push(item);
            }
        })
        console.log('this.stringifiedSelectedRecordType BEFORE: ' + JSON.stringify(this.stringifiedSelectedRecordType))
        this.stringifiedSelectedRecordType = JSON.stringify(values);
        console.log('this.stringifiedSelectedRecordType AFTER: ' + JSON.stringify(this.stringifiedSelectedRecordType))
        let wrapper = event;
        wrapper.target.value = '\'' + values.join('\',\'') + '\'';
        console.log('wrapper: ' + JSON.stringify(wrapper))
        this.filterTable(wrapper);
    }

    handleChangeEmail(event) {
        let field = event.target.dataset.field;
        let value = event.target.value;
        switch (field) {
            case "to":
                this.targetAddress = value;
                break;
            case "cc":
                this.cc = value;
                break;
            case "bcc":
                this.bcc = value;
                break;
            case "subject":
                this.subject = value;
                break;
            case "body":
                this.body = value;
                break;
        }
    }

    handleSend() {
        if (this.name == '') {
            this.name = this.assortmentName;
        }
        if (this.selectedId != '') {
            sendEmail({
                emailTo: this.targetAddress,
                Name: this.name,
                emailCc: this.cc,
                emailBcc: this.bcc,
                emailSubject: this.subject,
                emailBody: this.body,
                recordId: this.selectedId,
                assortmentName: 'assortmentTest'
            })
                .then(result => {
                    this.closeModal();
                })
                .catch(error => {
                    console.error(error); // Handle error
                });
        }
    }

    openModal(event) {
        let id = event.target.dataset.id;
        let name = event.target.dataset.name;
        this.assortmentName = name;
        this.selectedId = id;
        this.isEmailPopup = true;
    }

    closeModal() {
        this.targetAddress = '';
        this.cc = '';
        this.bcc = '';
        this.subject = '';
        this.name = '';
        this.body = '';
        this.assortmentName = '';
        this.isEmailPopup = false;
        // Logic to close the modal
    }

    handleExportExcel(event) {
        let id = event.target.dataset.id;
        let recordType = event.target.dataset.recordType;
        console.log('id: ' + id)
        console.log('recordType: ' + recordType)
        let exportURL;
        if (recordType == 'ChannelBudget') {
            exportURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentChannelBudget&a__recordId=' + id + '&a__isExportExcel=true';
        } else {
            exportURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + id + '&a__isExportExcel=true';

        }
        console.log('exportURL: ' + exportURL)
        window.open(exportURL);
    }
    handleSendEmail(event) {
        let id = event.target.dataset.id;
        let recordType = event.target.dataset.recordType;
        console.log('id: ' + id)
        console.log('recordType: ' + recordType)
        let exportURL;
        if (recordType == 'ChannelBudget') {
            exportURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentChannelBudget&a__recordId=' + id + '&a__isSendEmail=true';
        } else {
            exportURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + id + '&a__isSendEmail=true';

        }
        console.log('exportURL: ' + exportURL)
        window.open(exportURL);
    }
    @track pageSize = 50;
    @track pageNumber = 1;
    connectedCallback() {
        this.loading = true;
        window.addEventListener('resize', this.changeHeight);
        initData({}).then(result => {
            let parsedResult = JSON.parse(result);
            this.prefix = parsedResult.prefix || '';
            this.gridSettingsManager = parsedResult.gridSettingsManager;
            let selectedRTs = [];
            for (let rt of Object.keys(parsedResult.ASRecordTypes)) {
                if (!this.defaultRecordTypes || this.defaultRecordTypes == '' || this.defaultRecordTypes.toLowerCase().includes(rt.toLowerCase())) {
                    this.filter.recordTypes.push('\'' + parsedResult.ASRecordTypes[rt] + '\'');
                    selectedRTs.push(parsedResult.ASRecordTypes[rt]);
                }
            }
            this.stringifiedSelectedRecordType = JSON.stringify(selectedRTs);
            this.picklistValuesMap = this.gridSettingsManager.picklistValuesMap;
            this.displayedFields = this.gridSettingsManager.GRID_FIELDS;
            this.displayedFields.forEach(item => {
                item.style = item.style;
                item.sortedField = false;
                item.isNameField = item.fieldName == 'Name';
                item.isSkip = ((item.fieldName == isOnTop.fieldApiName || item.fieldName == isBreakingScenario.fieldApiName) && this.displayedFields.some(obj => obj.fieldName == 'Name'));
                if (item.fieldName.toLowerCase() == 'recordtypeid') {
                    item.fieldLabel = LBL_Record_Type;
                }
            });
            this.stringifiedSelectedYears = JSON.stringify(new Date().getFullYear() + '');
            const currentYear = new Date().getFullYear();
            this.yearsOptions = JSON.stringify([
                { label: '' + (currentYear + 1), value: '' + (currentYear + 1) },
                { label: '' + (currentYear), value: '' + currentYear },
                { label: '' + (currentYear - 1), value: '' + (currentYear - 1) }
            ])
            this.loadData();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });
    }
    loadData() {
        getAssortments({
            gridSettingsManagerSerialized: JSON.stringify(this.gridSettingsManager),
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            assortmentFilter: JSON.stringify(this.filter),
            sortField: this.sortField,
        }).then(assortments => {
            this.records = [];
            let data = JSON.parse(assortments)
            if (data.numberOfRecords != 0) {
                data.assortments.forEach(row => {
                    const wrapper = this.buildAssortmentInfo(row);
                    if (wrapper && wrapper.assortmentId) {
                        this.records.push(wrapper);
                    }
                });
            }
            this.totalPagesCount = Math.ceil((data.numberOfRecords / this.pageSize));
            this.showPaginationSection = this.totalPagesCount > 1;
            this.loading = false;
            this.tableLoading = false;
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        });

    }

    buildAssortmentInfo(assortmentInfo) {
        try {
            let assortmentWrapper = {
                assortmentDetail: assortmentInfo,
                assortmentId: assortmentInfo.Id,
                screenURL: '',
                assortmentName: assortmentInfo.Name,
                values: []

            }
            if (assortmentInfo.RecordType.Name == 'ChannelBudget') {
                assortmentWrapper.screenURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentChannelBudget&c__returnURL=' + window.location.href + '&a__recordId=' + assortmentInfo.Id;
            } else {
                assortmentWrapper.screenURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'AssortmentMatrix&a__recordId=' + assortmentInfo.Id;
                //assortmentWrapper.screenURL = '/apex/AssortmentMatrix?id=' + assortmentInfo.Id + '&showSubtotal=true';
            }
            console.log('assortmentWrapper.screenURL >>> ' + assortmentWrapper.screenURL);
            for (let field of this.displayedFields) {
                if (field.isSkip) {
                    continue;
                }
                let fieldObject = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: assortmentInfo[field.fieldName],
                    scale: field.scale,
                    style: field.style,
                    isLookUp: false,
                    isText: (field.fieldType == 'STRING' && field.fieldName != 'Name') || field.fieldType == 'REFERENCE' || field.fieldType == 'TEXTAREA' ? true : false,
                    isString: false,
                    isPicklist: field.fieldType == 'PICKLIST' || field.fieldType == 'MULTIPICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isNumber: field.fieldType == 'DOUBLE' || field.fieldType == 'PERCENT' || field.fieldType == 'NUMBER' || field.fieldType == 'CURRENCY' ? true : false,
                    isHTMLFormatted: field.isHTMLFormatted,
                    isNameField: field.fieldName == 'Name',
                    link: field.fieldName == 'Name' ? '/' + assortmentInfo.Id : ''
                }
                if (field.fieldName.includes('.')) {
                    let fields = field.fieldName.split('.');
                    let value = assortmentInfo[fields[0]];
                    for (let index = 1; index < fields.length; index++) {
                        value = value[fields[index]];
                    }
                    fieldObject.fieldValue = value;
                }
                if (fieldObject.isNumber) {
                    fieldObject.fieldValue = fieldObject.fieldValue == null ? 0 : fieldObject.fieldValue;
                    fieldObject.style += fieldObject.fieldName != Year.fieldApiName ? 'text-align:right;' : '';
                } else if (fieldObject.isPicklist) {
                    fieldObject.style += 'background-color:' + field.picklistColorsMap[fieldObject.fieldValue];
                } else if (fieldObject.isHTMLFormatted) {
                    fieldObject.style += 'justify-content: center;align-items: center;display: flex;'
                }
                switch (field.fieldType) {
                    case "REFERENCE":
                        fieldObject.fieldValue = assortmentInfo[field.fieldName.replace("__c", "__r").replace("Id", "")]?.Name;
                        break;
                    case "PICKLIST":
                        if (fieldObject.fieldValue != null) {
                            fieldObject.fieldValue = this.picklistValuesMap[field.fieldName][assortmentInfo[field.fieldName]];
                        }
                        break;
                }
                if (field.fieldName == 'Name') {
                    fieldObject.url = '/' + (assortmentInfo.Id || '');
                }
                assortmentWrapper.values.push(fieldObject);
                if (field.fieldName == 'Name') {
                    let fieldObject = {
                        isOntopandBreaking: true,
                        fieldLabel: this.labels.isOnTop + '+' + this.labels.isBreakingScenario,
                        isOnTop: assortmentInfo[isOnTop.fieldApiName],
                        isBreakingScenario: assortmentInfo[isBreakingScenario.fieldApiName]
                    }
                    assortmentWrapper.values.push(fieldObject);
                }
            }
            return assortmentWrapper;
        } catch (error) {
            console.log('>>>> %c' + error.message, 'color : red');
            console.log('>>>  %c' + error.body?.message, 'color : red');
        }
    }

    get colspan() {
        return this.displayedFields.map(field => !field.isSkip).length;
    }

    get isSortASC() {
        return this.sortDirection == 'ASC';
    }

    handleChangeSortField(event) {
        this.loading = true;
        let fieldName = event.target.dataset.field;
        if (this.sortField.startsWith(fieldName)) {
            if (this.sortDirection == 'ASC') {
                this.sortDirection = 'DESC';
            } else {
                this.sortDirection = 'ASC';
            }
        } else {
            this.sortDirection = 'ASC';
        }
        this.sortField = fieldName + ' ' + this.sortDirection;
        this.displayedFields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.sortedField = true;
                if (field.isReference && field.fieldName.endsWit('__c')) {
                    this.sortField = fieldName.replace('__c', '__r.Name') + ' ' + this.sortDirection;
                }
            } else {
                field.sortedField = false;
            }
        })
        this.loadData();
    }


    filterTable(event) {
        let field = event.target.dataset.field;
        let value;
        switch (field) {
            case "year":    
                const values = [];
                event?.detail?.selOptions?.forEach(item => {
                    if (item.hasOwnProperty('value')) {
                        values.push(item.value);
                    } else {
                        values.push(item);
                    }
                })
                if (values && values.length > 0) {
                    this.filter.year = values.join(',');
                    this.stringifiedSelectedYears = JSON.stringify(values);
                } else {
                    this.filter.year = new Date().getFullYear() + '';
                }
                break;
            case "buTarget":
                value = event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : '';
                this.filter.buTarget = value;
                /*if (value == '' || value == undefined) {
                    this.filter.Client = '';
                } else {
                    this.filter.Client = (BUTarget.fieldApiName) + ' = \'' + value + '\'';
                }*/
                break;
            case "buSource":
                value = event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : '';
                this.filter.buSource = value;
                /*if (value == '' || value == undefined) {
                    this.filter.BUSource = '';
                } else {
                    this.filter.BUSource = (BUSource.fieldApiName) + ' = \'' + value + '\'';
                }*/
                break;
            case "hierarchy":
                value = event.detail.selRecords && event.detail.selRecords.length > 0 ? event.detail.selRecords[0].recId : '';
                this.filter.hierarchy = value;
                break;
            case "recordTypes":
                value = event.target.value;
                this.filter.recordTypes = value.split(',');
                /*if (value == '' || value.length == 0 || value == null || value == '\'\'') {
                    this.filter.RecordType = '';
                } else {
                    this.filter.RecordType = 'RecordTypeId IN (' + value + ')';
                }*/
                break;
        }
        this.tableLoading = true;
        console.log('this.filters >>>> ' + JSON.stringify(this.filter))
        this.loadData();
    }

    openScreen(event) {
        let URL = event.target.dataset.url;
        console.log('URL >>> ' + URL);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: URL
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    navigateProduct(event) {
        let URL = event.target.dataset.url;
        if (URL != '' || URL != undefined) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: URL
                }
            }).then(generatedUrl => {
                window.open(generatedUrl);
            });
        }
    }
    //Pagination
    changePageSizeHandler(event) {
        this.pageSize = parseInt(event.target.value);
        for (let option of this.pageSizeOptions) {
            option.isSelected = option.value == this.pageSize;
        }
        this.pageNumber = 1;
        this.tableLoading = true;
        this.loadData();
    }

    handleChangePage(event) {
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
            this.tableLoading = true;
            this.loadData();
        } catch (error) {
            console.error(error)
        }
    }
    get previousDisabled() {
        return (this.pageNumber <= 1);
    }

    get nextDisabled() {
        return (this.pageNumber >= this.totalPagesCount);
    }

    renderedCallback() {
        this.changeHeight();
    }
    changeHeight = () => this.setTableDimension();

    setTableDimension() {
        if (!this.recordId) {
            let body = this.template.querySelector('.TableDiv');
            let emptyTableDiv = this.template.querySelector('.EmptyTableDiv');
            if (body) {
                if (this.showPaginationSection) {
                    body.style.height = (window.innerHeight - 255) + 'px';
                } else {
                    body.style.height = (window.innerHeight - 200) + 'px';
                }
                body.style.width = (this.template.querySelector('.mainContainer')?.style.width) + 'px';
            } else {
                if (emptyTableDiv) {
                    emptyTableDiv.style.height = (window.innerHeight - 255) + 'px';
                }
            }
        }
    }
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