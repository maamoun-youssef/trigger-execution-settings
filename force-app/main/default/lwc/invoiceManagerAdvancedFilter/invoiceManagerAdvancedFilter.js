import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfos, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import initData from '@salesforce/apex/InvoiceManagerAdvancedFilterController.initData';
import getCustomLabel from '@salesforce/apex/NegoptimLabels.getCustomLabel';
//IMPORTS
import { labels, API_NAMES, InvoiceFields, advancedFilterField, ReferenceTOMap, ReferenceFieldsLabels, TODAY, TOMORROW } from './properties.js';
export default class InvoiceManagerAdvancedFilter extends NavigationMixin(LightningElement) {
    @track Labels = labels;
    @track fields = [];
    @track isLoading = true;
    @track dataIsLoading = false;
    @track hasSelectedAction = false;
    @track showAppliedFilter = false;
    @track fieldsMap = {};
    @track selectedRecord;
    @track selectedRecords = [];
    @track selectedObject = '';
    @track selectedField = '';
    @track accDocOptions;
    @track defaultvaluesJSON = JSON.stringify([]);
    @track picklistFields = [];
    @track advancedFilterFields = [];
    @track activateAdvancedFilters = false;
    @track chooseAction = true;
    @track picklistFieldsMap = {};
    @track wireIsDone = {
        invoiceInfo: false,
        invoicePicklistValues: false,
        invoiceDetailPicklistValues: false,
        initData: false,
    }
    availableButtons = ['singleViewDetails', 'singlePreviewPdf', 'singleDownloadPrintedPdf'];
    scrollLoadMoreTimeOut;
    setPageSizeTimeOut;
    screenBig = true;
    isOnLoad = true;
    filterWrapper = {};
    invoicePicklistValues;
    selectedAction = '';
    @track invoiceManagerActions;
    @track invoiceManagerTopics = [];
    @track invoiceManagerActionsTopic = {};
    invoiceManagerActionsStatuses = {};
    invoiceManagerActionsAccDoc = {};
    @track topicsList = [];
    @track actionList = [];

    optionss;
    searchFields = ['Name'];
    value = [''];
    statusValueLabelMap = new Map();
    accDocValueLabelMap = new Map();
    invoiceDetailValueLabelMap = new Map();
    Events = {
        handleChangeMultiPicklistValues: 'handlechangemultipicklistvalues',
    };
    get isAvailable() {
        return (this.invoiceManagerTopics && this.invoiceManagerActionsTopic && this.invoiceManagerActions && this.topicsList.length > 0);
    }
    get hasSearched() {
        return location.pathname.startsWith('/lightning/n/');
    }
    get isSearchingStage() {
        return location.pathname.startsWith('/lightning/page/home');
    }
    get filterList() {
        let filters = {};
        let filter = [];
        let filterDescriptions = [];
        let supplierValuesMap = {};
        try {
            let innerQueryConditions = [];
            const customDevPrefix = (this.selectedAction.label == this.Labels.LBL_InvoiceMng_InvoiceScheduler) ? API_NAMES.InvoiceDetail__c.Invoice__r + '.' : '';
            for (let field in this.filterWrapper) {
                if (this.filterWrapper[field].isSearchable) {
                    if (this.filterWrapper[field].type == 'reference' && Object.keys(this.filterWrapper[field]?.supplierValuesMap || {}).length > 0) {
                        supplierValuesMap = this.filterWrapper[field].supplierValuesMap;
                    }
                    if ((this.filterWrapper[field].type == 'text' || this.filterWrapper[field].type == 'reference') && this.filterWrapper[field].valuesList?.length != 0) {
                        if (this.filterWrapper[field].isInnerQueryCondition) {
                            let innerQueryCondition = this.filterWrapper[field].valuesList.map(item => ` ${field} LIKE '%${item.trim()}%' `).join(' OR ');
                            innerQueryConditions.push(`(${innerQueryCondition})`);
                        } else {
                            filter.push('(' + this.filterWrapper[field].valuesList.map(item => ` ${customDevPrefix}${field} LIKE '%${item.trim()}%' `).join(' OR ') + ')');
                        }
                        filterDescriptions.push(this.filterWrapper[field].fieldLabel + ' = ' + this.filterWrapper[field].valuesList.join(', '))
                    } else if (this.filterWrapper[field].type == 'picklist' && this.filterWrapper[field].valuesList?.length != 0) {
                        if (this.filterWrapper[field].isInnerQueryCondition) {
                            let innerQueryCondition = '' + field + ' IN (\'' + this.filterWrapper[field].valuesList.join('\',\'') + '\')';
                            innerQueryConditions.push(`(${innerQueryCondition})`);
                        } else {
                            filter.push('' + customDevPrefix + field + ' IN (\'' + this.filterWrapper[field].valuesList.map(it => it.trim()).join('\',\'') + '\')');
                        }
                        if (this.filterWrapper[field].valuesList?.length != this.picklistFieldsMap[field]?.length) {
                            let valueSet = [];
                            for (let valueList of this.filterWrapper[field].valuesList) {
                                let picklistFieldMap = this.picklistFieldsMap[field]?.find(value => value.value === valueList);
                                valueSet.push(picklistFieldMap.label)
                            }
                            filterDescriptions.push(this.filterWrapper[field].fieldLabel + ' = (' + valueSet.join(', ') + ')');
                        }
                    } else if (this.filterWrapper[field].type == 'number') {
                        let rangeMsg = this.filterWrapper[field].fieldLabel + ' = ';
                        let valuesdesc = [];
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + customDevPrefix + field + ' >= ' + this.filterWrapper[field].value1);
                            valuesdesc.push(this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + customDevPrefix + field + ' <= ' + this.filterWrapper[field].value2);
                            valuesdesc.push(this.filterWrapper[field].value2);
                        }
                        filterDescriptions.push(rangeMsg + valuesdesc?.join('/'));
                    } else if (this.filterWrapper[field].type == 'date') {
                        let rangeMsg = this.filterWrapper[field].fieldLabel + ' = ';
                        let valuesdesc = [];
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + customDevPrefix + field + ' >= ' + this.filterWrapper[field].value1);
                            valuesdesc.push(this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + customDevPrefix + field + ' <= ' + this.filterWrapper[field].value2);
                            valuesdesc.push(this.filterWrapper[field].value2);
                        }
                        filterDescriptions.push(rangeMsg + valuesdesc?.join('/'));
                    } else if (this.filterWrapper[field].type == 'datetime') {
                        let rangeMsg = this.filterWrapper[field].fieldLabel + ' = ';
                        let valuesdesc = [];
                        // YYYY-MM-DDThh:mm:ssZ
                        if (this.filterWrapper[field].value1 != null && this.filterWrapper[field].value1 != '') {
                            filter.push('' + customDevPrefix + field + ' >= ' + new Date(this.filterWrapper[field].value1).toISOString());
                            valuesdesc.push(this.filterWrapper[field].value1);
                        }
                        if (this.filterWrapper[field].value2 != null && this.filterWrapper[field].value2 != '') {
                            filter.push('' + customDevPrefix + field + ' <= ' + new Date(this.filterWrapper[field].value2).toISOString());
                            valuesdesc.push(this.filterWrapper[field].value2);
                        }
                        filterDescriptions.push(rangeMsg + valuesdesc?.join('/'));
                    } else if (field == API_NAMES.Invoice__c.AccDoc__c && this.filterWrapper[field]?.valuesList.length == 0) {
                        filter.push('' + customDevPrefix + field + ' IN (\'' + this.initAccDocsFilter?.valuesList.join('\',\'') + '\')');
                        filterDescriptions.push(this.filterWrapper[field].fieldLabel + ' = (' + this.initAccDocsFilter?.valuesList.join(', ') + ')');
                    } else if (field == API_NAMES.Invoice__c.Status__c && this.filterWrapper[field]?.valuesList.length == 0) {
                        filter.push('' + customDevPrefix + field + ' IN (\'' + this.initStatusFilter?.valuesList.join('\',\'') + '\')');
                        filterDescriptions.push(this.filterWrapper[field].fieldLabel + ' = (' + this.initStatusFilter?.valuesList.join(', ') + ')');
                    }
                }
            }
            if (innerQueryConditions && innerQueryConditions?.length) {
                if ((this.selectedAction.label == this.Labels.LBL_InvoiceMng_InvoiceScheduler)) {
                    filter.push(innerQueryConditions.join(' AND '));
                } else {
                    let innerQuery = '(Id IN (SELECT ' + API_NAMES.InvoiceDetail__c.Invoice__c + ' FROM ' + API_NAMES.InvoiceDetail__c.objectApiName + ' WHERE ';
                    innerQuery += innerQueryConditions.join(' AND ');
                    innerQuery += ')' + ')';
                    // console.log('innerQuery: ' + innerQuery)
                    filter.push(innerQuery);
                }
            }
        } catch (error) {
            console.log('%c' + (error?.body?.message || error?.message), 'color : red');
        }
        // return filter;
        filters.filter = [...filter];
        filters.availableButtons = [...this.availableButtons]
        filters.filterDescriptions = [...filterDescriptions];
        filters.gridLayout = this.selectedAction?.gridLayout;
        filters.orderBy = this.selectedAction?.orderBy;
        filters.supplierValuesMap = supplierValuesMap;
        filters.objectApiName = this.selectedAction?.objectApiName;
        return filters;
    }

    async resolveLabel(label) {
        if (!label) return '';
        const match = label.match(/^\{\!\$Label\.([A-Za-z0-9_]+)\}$/);
        if (match && match[1]) {
            try {
                const result = await getCustomLabel({ labelName: match[1], hardcodedLabel: '' });
                return result || match[1];
            } catch (error) {
                console.error('Label fetch failed for', label, error);
                return match[1];
            }
        }
        return label;
    }

    populateTopics() {
        return new Promise(async (resolve, reject) => {
            try {
                const activeTopics = this.invoiceManagerTopics?.filter(topic => topic.isActive) || [];
                const actionsList = [];
                for (const topic of activeTopics) {
                    try {
                        const topicLabel = await this.resolveLabel(topic.name);
                        const filteredActions = this.actionList.filter(action => {
                            return Number(action.topicIndex) === Number(topic.index);
                        });
                        if (filteredActions.length > 0) {
                            actionsList.push({
                                topicLabel,
                                topicIndex: topic.index,
                                actions: filteredActions.map(({ label, value }) => ({ label, value }))
                            });
                        }
                    } catch (topicError) {
                        console.error('Error processing topic', topic.name, topicError);
                    }
                }
                this.topicsList = actionsList.sort((a, b) => Number(a.topicIndex) - Number(b.topicIndex));
                resolve();
            } catch (e) {
                reject(e);
            }
        });
    }

    populateActions() {
        this.actionList = [];
        let invoiceManagerActionsStatuses = this.invoiceManagerActionsStatuses;
        let invoiceManagerActions = this.invoiceManagerActions;
        let invoiceManagerActionsTopic = this.invoiceManagerActionsTopic;
        if (invoiceManagerActions.includes('LBL_InvoiceMng_PrintToday')) {
            let filterWrapper = [
                {
                    fieldName: API_NAMES.Invoice__c.InvDate__c,
                    type: 'date',
                    isDate: true,
                    value1: null,
                    value2: TODAY,
                },
            ];
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_PrintToday']
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status];
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                },);
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_PrintToday']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_PrintToday,
                value: 'option1',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_PrintToday'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_PrintToday'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' ASC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            });
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_PrintFuture')) {
            let filterWrapper = [
                {
                    fieldName: API_NAMES.Invoice__c.InvDate__c,
                    type: 'date',
                    isDate: true,
                    value1: null,
                    value2: TOMORROW,
                },
            ]
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_PrintFuture'];
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                },);
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_PrintFuture']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_PrintFuture,
                value: 'option2',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_PrintFuture'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_PrintFuture'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' ASC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            });
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_ResendToSupplier')) {
            let filterWrapperList = [
                {
                    fieldName: API_NAMES.Invoice__c.PrintDate__c,
                    type: 'date',
                    isDate: true,
                    value1: null,
                    value2: TODAY,
                },
            ]
            if ((invoiceManagerActionsStatuses['LBL_InvoiceMng_ResendToSupplier'] && invoiceManagerActionsStatuses['LBL_InvoiceMng_ResendToSupplier'] != '')) {
                let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_ResendToSupplier'];
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status];
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapperList.unshift(
                    {
                        fieldName: API_NAMES.Invoice__c.Status__c,
                        isText: true,
                        type: 'picklist',
                        valuesList: valuesList,
                        valuesStr: status,
                        valuesTranslated: valuesTranslated
                    },
                );
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_ResendToSupplier']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_ResendToSupplier,
                value: 'option4',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_ResendToSupplier'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_ResendToSupplier'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' DESC',
                filterWrapper: filterWrapperList,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    { fieldName: API_NAMES.Invoice__c.PrintDate__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    }, { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            })
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_DeleteInvoice')) {
            let filterWrapper = []
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_DeleteInvoice'];
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                },)
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_DeleteInvoice']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_DeleteInvoice,
                value: 'option5',
                topicIndex: this.invoiceManagerActionsTopic?.['LBL_InvoiceMng_DeleteInvoice'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_DeleteInvoice'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' ASC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    }, { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            })
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_CancelOrCreateCreditNote')) {
            let filterWrapper = []
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_CancelOrCreateCreditNote'];
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                })
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_CancelOrCreateCreditNote']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_CancelOrCreateCreditNote,
                value: 'option6',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_CancelOrCreateCreditNote'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_CancelOrCreateCreditNote'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' DESC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    { fieldName: API_NAMES.Invoice__c.PrintDate__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    }, { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            })
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_AllocatePayment')) {
            let filterWrapper = [];
            let status = (invoiceManagerActionsStatuses['LBL_InvoiceMng_AllocatePayment']);
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                });
            }
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_AllocatePayment']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_AllocatePayment,
                value: 'option7',
                topicIndex: this.invoiceManagerActionsTopic?.['LBL_InvoiceMng_AllocatePayment'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_AllocatePayment'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' DESC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    }, { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            })
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_InvoiceDeduct')) {
            let _accDocs = this.invoiceManagerActionsAccDoc['LBL_InvoiceMng_InvoiceDeduct']?.trim();
            let accDocs = _accDocs ? _accDocs?.split(',') : [];
            let accDocOptions = accDocs.map(key => {
                return {
                    label: this.accDocValueLabelMap?.get(key),
                    value: key
                }
            });
            let filterWrapper = [
                {
                    fieldName: API_NAMES.Invoice__c.AccDoc__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: accDocs,
                    valuesTranslated: accDocs.map(value => this.accDocValueLabelMap?.get(value)?.trim() || '')
                        .filter(Boolean)
                        .join(', ')
                },
            ];
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_InvoiceDeduct'];
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                },);
            }
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_InvoiceDeduct,
                value: 'option8',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_InvoiceDeduct'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_InvoiceDeduct'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' ASC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                ],
            });
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_AllocateCreditNote')) {
            let filterWrapper = [
                {
                    fieldName: API_NAMES.Invoice__c.AccDoc__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: ['CreditNote'],
                    valuesTranslated: this.accDocValueLabelMap?.get("CreditNote")
                },
            ];
            let status = invoiceManagerActionsStatuses['LBL_InvoiceMng_AllocateCreditNote'];
            if (status) {
                let valuesList = Array.isArray(status?.split(',')) ? status.split(',') : [status]
                let valuesTranslated = valuesList.map(value => this.statusValueLabelMap?.get(value)?.trim() || '')
                    .filter(Boolean)
                    .join(', ');
                filterWrapper.unshift({
                    fieldName: API_NAMES.Invoice__c.Status__c,
                    isText: true,
                    type: 'picklist',
                    valuesList: valuesList,
                    valuesStr: status,
                    valuesTranslated: valuesTranslated
                },);
            }
            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_AllocateCreditNote,
                value: 'option3',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_AllocateCreditNote'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_AllocateCreditNote'],
                objectApiName: API_NAMES.Invoice__c.objectApiName,
                orderBy: API_NAMES.Invoice__c.InvDate__c + ' DESC',
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                ],
            });
        }
        if (invoiceManagerActions.includes('LBL_InvoiceMng_InvoiceScheduler')) {
            let filterWrapper = [];
            let statusOptions = this.picklistFieldsMap[API_NAMES.Invoice__c.Status__c];
            let accDocOptions = this.picklistFieldsMap[API_NAMES.Invoice__c.AccDoc__c];
            const orderList = [
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.FiscalYear__c + ' DESC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.SupplierBuyer__r + '.' + API_NAMES.Supplier__c.Name + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Supplier_Nego_Scope__r + '.' + API_NAMES.NegoScope__c.Name + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Name + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.Contract__r + '.' + API_NAMES.Contract__c.Reference_Year__c + ' DESC ',
                API_NAMES.InvoiceDetail__c.DISCLineD__r + '.' + API_NAMES.Contract_Discount__c.Nego_Discount_Type__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.DISCLineD__r + '.' + API_NAMES.Contract_Discount__c.Disc_BDate__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.DISCLineD__r + '.' + API_NAMES.Contract_Discount__c.Disc_EDate__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.DISCLineD__r + '.' + API_NAMES.Contract_Discount__c.Name + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.SeqNumber__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.InvDate__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.Invoice__r + '.' + API_NAMES.Invoice__c.DueDate__c + ' ASC ',
                API_NAMES.InvoiceDetail__c.Name + ' ASC ',
            ]

            this.actionList.push({
                label: this.Labels.LBL_InvoiceMng_InvoiceScheduler,
                value: 'option9',
                topicIndex: invoiceManagerActionsTopic?.['LBL_InvoiceMng_InvoiceScheduler'],
                gridLayout: this.invoiceManagerActionsGrid['LBL_InvoiceMng_InvoiceScheduler'],
                objectApiName: API_NAMES.InvoiceDetail__c.objectApiName,
                orderBy: orderList.join(' , '),
                filterWrapper: filterWrapper,
                complementaryFilters: [
                    { fieldName: API_NAMES.Invoice__c.BusinessUnitSeller__c },
                    { fieldName: API_NAMES.Invoice__c.SupplierBuyer__c },
                    {
                        fieldName:
                            API_NAMES.Invoice__c.Contract__r +
                            '.' +
                            API_NAMES.Contract__c.Supplier_Nego_Scope__c,
                        isNS: true,
                        isSearchable: true,
                    },
                    //{ fieldName: API_NAMES.Invoice__c.AccDocType__c },
                    { fieldName: API_NAMES.Invoice__c.InvDate__c },
                    {
                        fieldName: API_NAMES.Invoice__c.Status__c,
                        picklistOptions: statusOptions,
                        picklistOptionsStr: JSON.stringify(statusOptions),

                    },
                    {
                        fieldName: API_NAMES.Invoice__c.AccDoc__c,
                        picklistOptions: accDocOptions,
                        picklistOptionsStr: JSON.stringify(accDocOptions),

                    }, { fieldName: API_NAMES.Invoice__c.InvNumber__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCNegoType__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCBudgetCode__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.InvoiceDetail__c.DISCLineD__c, isInnerQueryCondition: true },
                    { fieldName: API_NAMES.Invoice__c.Contract__c },
                    { fieldName: API_NAMES.InvoiceDetail__c.CommercialPlan__c, isInnerQueryCondition: true },
                ],
            })
        }
    }

    get availableButtonsOptions() {
        return {
            option1: ["massPrint", "singleViewDetails", "singlePreviewPdf"],
            option2: ["massPrint", "singleViewDetails", "singlePreviewPdf"],
            option4: ["massEmail", "singleDownloadPrintedPdf", "singleViewDetails"],
            option5: ["massDelete", "singleViewDetails", "singlePreviewPdf"],
            option6: ["massCancel", "singleDownloadPrintedPdf", "singleViewDetails"],
            option7: ["invoicePayment", "singleDownloadPrintedPdf", "singleViewDetails"],
            option8: ["massDeduct", "singleDownloadPrintedPdf", "singleViewDetails"],
            option3: ["supplierCreditNote", "singleDownloadPrintedPdf", "singleViewDetails"],
            option9: [""]
        }
    }

    /*get actionOptions() {
        return (this.invoiceManagerTopics && this.invoiceManagerActionsTopic && this.invoiceManagerActions && this.topicsList) ? this.topicsList : [];
    }*/

    @wire(getObjectInfos, {
        objectApiNames: [
            API_NAMES.Invoice__c.objectApiName,
            API_NAMES.InvoiceDetail__c.objectApiName,
            API_NAMES.Hierarchy__c.objectApiName,
            API_NAMES.Pol_Com_Condition__c.objectApiName,
            API_NAMES.NegoScope__c.objectApiName
        ]
    })
    wiredObjectInfos({ error, data }) {
        try {
            if (data) {
                let objMap = {};
                data.results.forEach(item => {
                    objMap[item.result.apiName] = item.result;
                    if (Object.keys(ReferenceFieldsLabels).includes(item.result.apiName) && item.result.apiName != API_NAMES.Pol_Com_Condition__c.objectApiName) {
                        ReferenceFieldsLabels[item.result.apiName] = item.result.label;
                    }
                });
                let allFields = {};
                InvoiceFields.forEach((el, index) => {
                    let _field = objMap[API_NAMES.Invoice__c.objectApiName]?.fields[el];
                    if (!_field) {
                        _field = objMap[API_NAMES.InvoiceDetail__c.objectApiName]?.fields[el];
                    }
                    let dataType = _field.dataType;
                    let item = {};
                    dataType = dataType.toLocaleUpperCase();
                    item.fieldName = _field.apiName;
                    item.fieldLabel = _field.label;
                    item.scale = _field.scale;
                    item.dataType = dataType;
                    item.isNumber = ['PERCENT', 'DOUBLE', 'INTEGER', 'LONG'].includes(dataType);
                    item.isCurrency = ['CURRENCY'].includes(dataType);
                    item._isNumber = item.isCurrency || item.isNumber;
                    item.isPercent = ['PERCENT'].includes(dataType);
                    item.isPicklist = ['PICKLIST', 'MULTIPICKLIST'].includes(dataType);
                    item.isBoolean = ['BOOLEAN'].includes(dataType);
                    item.isDate = ['DATE'].includes(dataType);
                    item.isDateTime = ['DATETIME'].includes(dataType);
                    item._isDate = item.isDate || item.isDateTime;
                    item.isText = ['STRING'].includes(dataType) && item.apiForLabel !== "Name";
                    item.isReference = ['REFERENCE'].includes(dataType) || item.apiForLabel == "Name";
                    if (item.isPicklist) {
                        item.selectedValues = [];
                        item.picklistOptions = [];
                        this.picklistFields.push(_field.apiName)
                    }
                    if (item.isReference) {
                        item.referenceTo = _field.referenceToInfos[0].apiName;
                    }
                    item.isSearchable = _field.filterable;
                    allFields[el] = item;
                });
                this.fieldsMap = allFields;
                this.wireIsDone.invoiceInfo = true;
                this.checkIfWireIsDone();
            }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: API_NAMES.Invoice__c.objectApiName, recordTypeId: '012000000000000AAA' }) picklistValues({ error, data }) {
        try {
            if (data) {
                Object.keys(data.picklistFieldValues).forEach(fieldName => {
                    let picklistMap = data.picklistFieldValues[fieldName];
                    let options = [];
                    for (let key of picklistMap.values) {
                        options.push({ label: key.label, value: key.value });
                    }
                    this.picklistFieldsMap[fieldName] = options;
                });
                this.wireIsDone.invoicePicklistValues = true;
                this.checkIfWireIsDone();
            } else if (error) { console.log('ERROR'); }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: API_NAMES.InvoiceDetail__c.objectApiName, recordTypeId: '012000000000000AAA' }) detailPicklistValues({ error, data }) {
        try {
            if (data) {
                Object.keys(data.picklistFieldValues).forEach(fieldName => {
                    let picklistMap = data.picklistFieldValues[fieldName];
                    let options = [];
                    for (let key of picklistMap.values) {
                        options.push({ label: key.label, value: key.value });
                    }
                    this.picklistFieldsMap[fieldName] = options;
                });
                this.wireIsDone.invoiceDetailPicklistValues = true;
                this.checkIfWireIsDone();
            } else if (error) { console.log('ERROR'); }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    checkIfWireIsDone() {
        try {
            if (Object.values(this.wireIsDone).every(it => it)) {
                this.prepareTranslatedPicklist()
                this.populateActions();
                this.populateTopics().then(() => {
                    this.isLoading = false;
                    this.afterload();
                }).catch(e => {
                    console.error('Error in populateTopics:', e);
                });
            }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    @wire(initData)
    wiredInitData({ error, data }) {
        if (data) {
            try {
                let parsedResult = JSON.parse(data);
                this.invoiceManagerActions = parsedResult.invoiceManagerActions;
                this.invoiceManagerActionsStatuses = parsedResult.invoiceManagerActionsStatuses;
                this.invoiceManagerActionsGrid = parsedResult.invoiceManagerActionsGrid;
                this.invoiceManagerActionsAccDoc = parsedResult.invoiceManagerActionsAccDoc;
                this.invoiceManagerTopics = parsedResult.invoiceManagerTopics;
                this.invoiceManagerActionsTopic = parsedResult.invoiceManagerActionsTopic;
                this.wireIsDone.initData = true;
                this.checkIfWireIsDone();
            } catch (e) {
                console.error('JSON parsing error: ', e);
            }
        } else if (error) {
            console.error('Error retrieving data: ', error);
        }
    }

    connectedCallback() {
        try {
            addEventListener('resize', this.setPageSize);
            let tabStyle = document.createElement('style');
            tabStyle.innerText = '.slds-radio__label .slds-form-element__label{font-size :14px; }';
            document.body.appendChild(tabStyle);
        } catch (error) {
            this.isLoading = true;
        }
    }

    renderedCallback() {
        try {
            let self = this;
            clearTimeout(self.setPageSizeTimeOut);
            this.setPageSizeTimeOut = setTimeout(() => {
                self.template.querySelectorAll('.sessionTable tr').forEach(tr => {
                    let left = 0;
                    for (let i = 0; i < 2 && i < tr.children.length; i++) {
                        let node = tr.children[i];
                        node.style.position = 'sticky';
                        node.style.zIndex = node.nodeName == 'TH' ? 13 : 11;
                        node.style.left = left + 'px ';
                        left += node.offsetWidth;
                    }
                });
                self.setPageSize();
            }, 500);
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    setPageSize = () => {
        try {
            let mainContainer = this.template.querySelector(".mainContainer");
            let pageHeader = this.template.querySelector(".pageHeader");
            let pageBodyDiv = this.template.querySelector(".pageBody");
            if (pageHeader != null && mainContainer != null && pageBodyDiv != null) {
                pageBodyDiv.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight + "px";
            }
            if (pageHeader != null && pageHeader.offsetWidth < 1200) {
                this.screenBig = false;
            } else if (pageHeader != null && pageHeader.offsetWidth >= 1200) {
                this.screenBig = true;
            }
        } catch (error) {
            console.log('%c' + error.message, 'color : red');
            console.log('%c' + error.body?.message, 'color : red');
        }
    };

    afterload() {
        try {
            if (this.activateAdvancedFilters) {
                this.buildAdvancedFilterData()
                this.chooseAction = false;
            } else if (this.hasSelectedAction) {
                this.initialiseFilterWrapper();
                this.selectedAction = this.buildFilterData(this.selectedAction);
            } else {
                this.chooseAction = true;
                this.dataIsLoading = false;
            }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    prepareTranslatedPicklist() {
        let statusOptions = this.picklistFieldsMap[API_NAMES.Invoice__c.Status__c];
        statusOptions?.forEach(item => this.statusValueLabelMap.set(item.value, item.label));
        let accdocOptions = this.picklistFieldsMap[API_NAMES.Invoice__c.AccDoc__c];
        accdocOptions?.forEach(item => this.accDocValueLabelMap.set(item.value, item.label));
        let invoiceDetailOptions = this.picklistFieldsMap[API_NAMES.InvoiceDetail__c.DISCNegoType__c];
        invoiceDetailOptions?.forEach(item => this.invoiceDetailValueLabelMap.set(item.value, item.label));
    }

    buildFilterData(selectedAction) {
        try {
            selectedAction?.filterWrapper.forEach(action => {
                let fieldApiName = action.fieldName;
                let fieldInfo = this.fieldsMap[fieldApiName];
                action.fieldLabel = fieldInfo.fieldLabel;
                action.valuesListStr = action?.valuesList?.join(',');
            });
            let AccDocsOptions = this.selectedAction?.complementaryFilters?.find(item => item.fieldName === API_NAMES.Invoice__c.AccDoc__c);
            let AccDocsValues;
            if (AccDocsOptions) {
                AccDocsValues = AccDocsOptions?.picklistOptions?.map(item => item.value)
                this.filterWrapper[API_NAMES.Invoice__c.AccDoc__c] = {
                    valuesList: AccDocsValues,
                    fieldLabel: this.fieldsMap[API_NAMES.Invoice__c.AccDoc__c].fieldLabel,
                    type: "picklist",
                    isSearchable: true,
                }
                this.initAccDocsFilter = { ...this.filterWrapper[API_NAMES.Invoice__c.AccDoc__c] };
            }
            let statusOptions = this.selectedAction?.complementaryFilters?.find(item => item.fieldName === API_NAMES.Invoice__c.Status__c);
            if (statusOptions) {
                let statusValues = statusOptions?.picklistOptions?.map(item => item.value)
                this.filterWrapper[API_NAMES.Invoice__c.Status__c] = {
                    valuesList: statusValues,
                    fieldLabel: this.fieldsMap[API_NAMES.Invoice__c.Status__c].fieldLabel,
                    type: "picklist",
                    isSearchable: true,
                }
                this.initStatusFilter = { ...this.filterWrapper[API_NAMES.Invoice__c.Status__c] };
            }
            selectedAction?.complementaryFilters?.forEach(action => {
                let fieldApiName = action.fieldName;
                if (!action.isNS) {
                    let fieldInfo = this.fieldsMap[fieldApiName];
                    action.fieldLabel = fieldInfo.fieldLabel;
                    action._isNumber = fieldInfo._isNumber;
                    action.isPercent = fieldInfo.isPercent;
                    action.isPicklist = fieldInfo.isPicklist;
                    action.isBoolean = fieldInfo.isBoolean;
                    action._isDate = fieldInfo._isDate;
                    action.isText = fieldInfo.isText;
                    action.isReference = fieldInfo.isReference;
                    action.isSearchable = fieldInfo.isSearchable;
                    action.referenceTo = fieldInfo.referenceTo;
                    if (fieldApiName == API_NAMES.Invoice__c.AccDoc__c || fieldApiName == API_NAMES.Invoice__c.Status__c) {
                        action.value = JSON.stringify(['all']);
                    } else {
                        action.value = action.i
                    }
                    action.classSize = action._isDate ? 'slds-p-right--x-large slds-size--2-of-2 ' : 'slds-p-right--x-large slds-size--1-of-2 ';
                    action.selectedRecords = [];
                    if (fieldInfo.isPicklist) {
                        let options = this.picklistFieldsMap[fieldApiName];
                        if (fieldApiName !== API_NAMES.Invoice__c.AccDoc__c && fieldApiName !== API_NAMES.Invoice__c.Status__c) {
                            action.picklistOptions = options;
                            action.picklistOptionsStr = JSON.stringify(options);
                        }
                    }
                } else {
                    action.fieldLabel = 'Negoscope';
                    action.isReference = true;
                    action.referenceTo = API_NAMES.NegoScope__c.objectApiName;
                    action.selectedRecords = [];
                    action.classSize = 'slds-p-right--x-large slds-size--1-of-2'
                }
            });
            setTimeout(() => {
                this.showAppliedFilter = true;
                this.dataIsLoading = false;
            }, 400);
            return selectedAction;
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
            return null;
        }
    }

    buildAdvancedFilterData() {
        try {
            this.advancedFilterFields = [];
            advancedFilterField.forEach(fieldApiName => {
                let action = {};
                if (!Object.keys(ReferenceTOMap).includes(fieldApiName)) {
                    let fieldInfo = this.fieldsMap[fieldApiName];
                    action.fieldLabel = fieldInfo.fieldLabel;
                    action.fieldName = fieldInfo.fieldName;
                    action._isNumber = fieldInfo._isNumber;
                    action.isPercent = fieldInfo.isPercent;
                    action.isPicklist = fieldInfo.isPicklist;
                    action.isBoolean = fieldInfo.isBoolean;
                    action._isDate = fieldInfo._isDate;
                    action.isText = fieldInfo.isText;
                    action.isReference = fieldInfo.isReference;
                    action.isSearchable = fieldInfo.isSearchable;
                    action.referenceTo = fieldInfo.referenceTo;
                    action.selectedRecords = [];
                    if (fieldInfo.isPicklist) {
                        let options = this.picklistFieldsMap[fieldApiName];
                        action.picklistOptions = options;
                        action.picklistOptionsStr = JSON.stringify(options);
                    }
                    action.isInnerQueryCondition = [
                        API_NAMES.Pol_Com_Condition__c.Condition_Code__c,
                        API_NAMES.InvoiceDetail__c.DISCBudgetCode__c,
                        API_NAMES.InvoiceDetail__c.DISCLineD__c,
                        API_NAMES.InvoiceDetail__c.DISCNegoType__c,
                    ].includes(fieldApiName);
                } else {
                    action.fieldLabel = ReferenceFieldsLabels[ReferenceTOMap[fieldApiName]];
                    action.fieldName = fieldApiName != API_NAMES.Pol_Com_Condition__c.Condition_Code__c ? fieldApiName
                        : API_NAMES.InvoiceDetail__c.DISCLineD__r + '.' + API_NAMES.Contract_Discount__c.Condition_Type__r + '.' + API_NAMES.Pol_Com_Condition__c.Condition_Code__c;
                    action.isReference = fieldApiName != API_NAMES.Pol_Com_Condition__c.Condition_Code__c;
                    action.isText = fieldApiName == API_NAMES.Pol_Com_Condition__c.Condition_Code__c;
                    action.isInnerQueryCondition = [
                        API_NAMES.Pol_Com_Condition__c.Condition_Code__c,
                        API_NAMES.InvoiceDetail__c.DISCBudgetCode__c,
                        API_NAMES.InvoiceDetail__c.DISCLineD__c,
                        API_NAMES.InvoiceDetail__c.DISCNegoType__c,
                    ].includes(fieldApiName);
                    action.referenceTo = ReferenceTOMap[fieldApiName];
                    action.isSearchable = true;
                    action.selectedRecords = [];
                }
                this.advancedFilterFields.push(action);
            });
            setTimeout(() => {
                this.dataIsLoading = false;
            }, 400);
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    initialiseFilterWrapper() {
        try {
            this.filterWrapper = {};
            this.selectedAction.filterWrapper.forEach(fixedfilter => {
                let fieldName = fixedfilter.fieldName;
                if (this.filterWrapper[fieldName] == null) {
                    this.filterWrapper[fieldName] = {};
                }
                this.filterWrapper[fieldName].isInnerQueryCondition = fixedfilter.isInnerQueryCondition;
                this.filterWrapper[fieldName].isSearchable = true;
                this.filterWrapper[fieldName].type = fixedfilter.type;
                this.filterWrapper[fieldName].fieldLabel = this.fieldsMap[fieldName].fieldLabel;
                if (fixedfilter.type == 'picklist' && fixedfilter.valuesList.length != 0) {
                    this.filterWrapper[fieldName].valuesList = fixedfilter.valuesList;
                } else if (fixedfilter.type == 'date') {
                    if (fixedfilter.value1) {
                        this.filterWrapper[fieldName].value1 = fixedfilter.value1.toISOString().split('T')[0];
                    }
                    if (fixedfilter.value2) {
                        this.filterWrapper[fieldName].value2 = fixedfilter.value2.toISOString().split('T')[0];
                    }
                }
            });
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    handleChangeFilter(event) {
        try {
            let fieldName = event.target.dataset.field;
            let type = event.target.dataset.type;
            let value = event.target.value;
            let number = event.target.dataset.number;
            let field = this.hasSelectedAction ? this.selectedAction.complementaryFilters.find(field => field.fieldName === fieldName)
                : this.advancedFilterFields.find(field => field.fieldName === fieldName);
            if (!field) return;
            let fieldAPIName = field.fieldName;
            if (field.isReference) {
                if (field.fieldName.endsWith('Id')) {
                    fieldName = field.fieldName.replace('Id', '.Name');
                } else {
                    fieldName = field.fieldName.replace('__c', '__r.Name');
                }
            }
            if (this.filterWrapper[fieldName] == null) {
                this.filterWrapper[fieldName] = {};
            }
            if (type === 'text') {
                let valuesList = (value != null && value !== '') ? value.split(",") : [];
                this.filterWrapper[fieldName].valuesList = valuesList.map(it => it.trim());
                field.isFiltered = valuesList.length !== 0;
                field.fieldSearchValue = value;
            } else if (type === 'reference') {
                let values = [];
                let supplierValuesMap = {};
                if (event.detail && event.detail.selRecords && event.detail.selRecords.length > 0) {
                    event.detail.selRecords.forEach(item => {
                        values.push(item.recName);
                        if (fieldAPIName == API_NAMES.Invoice__c.SupplierBuyer__c) {
                            supplierValuesMap[item.recId] = item.recName;
                        }
                    });
                }
                this.filterWrapper[fieldName].valuesList = values;
                this.filterWrapper[fieldName].supplierValuesMap = supplierValuesMap;
                field.valuesList = values;
                field.supplierValuesMap = supplierValuesMap;
            } else if (type === 'picklist') {
                let values = [];
                if (event.detail?.selOptions[0]?.value !== 'all') {
                    event.detail.selOptions.forEach(item => {
                        values.push(item.value);
                    });
                }
                this.filterWrapper[fieldName].valuesList = values;
                field.valuesList = values;
            } else if (type === 'number' || type === 'date' || type === 'datetime') {
                if (type === 'datetime') {
                    let selectedDate = new Date(value);
                    if (number === '1') {
                        selectedDate.setUTCHours(0, 0, 0, 0);
                        field.fieldSearchValue1 = selectedDate.toISOString();
                    } else if (number === '2') {
                        selectedDate.setUTCHours(23, 59, 59, 999);
                        field.fieldSearchValue2 = selectedDate.toISOString();
                    }
                    this.filterWrapper[fieldName][`value${number}`] = selectedDate;
                } else {
                    field[`fieldSearchValue${number}`] = value;
                    this.filterWrapper[fieldName][`value${number}`] = value;
                }
                field.isFiltered = (field.fieldSearchValue1 != null && field.fieldSearchValue1 !== '') || (field.fieldSearchValue2 != null && field.fieldSearchValue2 !== '');
            }
            this.filterWrapper[fieldName].fieldLabel = field.fieldLabel;
            this.filterWrapper[fieldName].type = type;
            this.filterWrapper[fieldName].isSearchable = field.isSearchable;
            this.filterWrapper[fieldName].isInnerQueryCondition = field.isInnerQueryCondition;
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    handleAddAdvancedFilters(event) {
        try {
            this.dataIsLoading = true;
            this.hasSelectedAction = false;
            this.selectedAction = {};
            this.filterWrapper = {};
            this.activateAdvancedFilters = !this.activateAdvancedFilters;
            this.chooseAction = this.activateAdvancedFilters ? false : true;
            this.availableButtons = ['singleViewDetails', 'singlePreviewPdf', 'singleDownloadPrintedPdf'];
            this.afterload()
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    handleSearch(event) {
        try {
            let prefix = '';
            let parts = API_NAMES.Invoice__c.objectApiName.split('__');
            if (parts.length > 2) {
                prefix = parts[0] + '__';
            }
            // Encode filters once
            let encodedFilters = encodeURIComponent(JSON.stringify(this.filterList));
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: `/lightning/n/${prefix}InvoiceManager?c__appliedfilters=${encodedFilters}`,
                },
            }).then(() => {
                window.open(`/lightning/n/${prefix}InvoiceManager?c__appliedfilters=${btoa(encodedFilters)}`);
            });
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    handleChangeMultiPicklistValues(event) {
        try {
            let values = [];
            event.detail.selOptions.forEach(item => {
                values.push(item.value);
            });
        } catch (e) {
            console.log('ERROR: ' + e);
        }
    }

    handleActionChange(event) {
        try {
            this.selectedAction = {};
            this.dataIsLoading = true;
            this.hasSelectedAction = true;
            this.chooseAction = true;
            this.showAppliedFilter = false;
            this.activateAdvancedFilters = false;
            this.availableButtons = this.availableButtonsOptions[event.detail.value];
            this.selectedAction = this.actionList?.find(action => action?.value === event.detail.value);
            this.afterload();
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }
    }

    resetSessionFilters() {
        try {
            if (this.hasSelectedAction) {
                this.showAppliedFilter = false;
                this.initialiseFilterWrapper();
                this.dataIsLoading = true;
                setTimeout(() => {
                    this.showAppliedFilter = true;
                    this.dataIsLoading = false;
                }, 400);
            }
            else if (this.activateAdvancedFilters) {
                this.activateAdvancedFilters = false;
                this.dataIsLoading = true;
                setTimeout(() => {
                    this.activateAdvancedFilters = true;
                    this.dataIsLoading = false;
                }, 400);
            }
        } catch (e) {
            console.log('ERROR: ' + e + '  ' + e.stack);
        }

    }
    //Utility Methods
    /**
     * @description This Method to alert the user
     * @param {String} title message title
     * @param {String} message the message content
     * @param {String} variant the message type (success, warning, ..)
     */
    showToast(title, message, variant) {
        let errorMessage = message?.body?.message || message?.message || message;
        // create and show the alert
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: errorMessage,
            variant: variant
        }));
    }
}