import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initData from '@salesforce/apex/CockpitConditionListController.initData';
import LBL_CockpitConditionList_ConditionsList from '@salesforce/label/c.LBL_CockpitConditionList_ConditionsList';
import LBL_CockpitConditionList_OpenConditionManager from '@salesforce/label/c.LBL_CockpitConditionList_OpenConditionManager';
import LBL_No_Item_To_Display from '@salesforce/label/c.LBL_No_Item_To_Display';
import { loadStyle } from 'lightning/platformResourceLoader';
import conditionManager from '@salesforce/resourceUrl/conditionManager';

const RECORD_TYPES = new Set([
    'default','simulation','signed','to-be-signed','on-top','period-extension',
    'nego-base','safe-balance','proposal','target','landing',
    'nego-base-exit','nego-base-init','postnego-simulation','signed-copy'
]);

const labels = {
    LBL_CockpitConditionList_ConditionsList,
    LBL_CockpitConditionList_OpenConditionManager,
    LBL_No_Item_To_Display,
};

export default class CockpitConditionList extends NavigationMixin(LightningElement) {
    labels = labels;
    @api recordId;
    @track displayedFields = [];
    @track records = [];
    @track columnsFromApex = [];
    @track allRecords = [];
    @track isLoading = true;
    @track error;
    @track prefix;
    @track styleKey = 'default'; 
    @track themeClass = 'theme-default';

    connectedCallback() {
        Promise.resolve()
            .then(() => loadStyle(this, conditionManager + '/customStyle.css'))
            .catch((e) => {
                console.warn('conditionManager/customStyle.css failed to load:', e);
            })
            .finally(() => this.initData());
    }

    navigateToConditionManager() {
        if (!this.recordId) return;
        let screenURL = '/apex/' + this.prefix + 'NegoptimNavigator?c__componentName=' + (this.prefix ? this.prefix.replace('__', ':') : 'c:') + 'conditionManager&a__recordId=' + this.recordId;
        window.open(screenURL, '_blank');
    }

    initData() {
        this.isLoading = true;
        initData({ contractId: this.recordId })
            .then(result => {
                const response = JSON.parse(result || '{}');
                this.prefix = response.prefix;
                this.columnsFromApex = Array.isArray(response.fieldList) ? response.fieldList : [];
                this.allRecords = Array.isArray(response.records) ? response.records : [];
                // read/compute styling info
                const dev = response.recordTypeDeveloperName || '';
                const onTop = !!response.onTop;
                const rawKey = response.styleKey || this.deriveStyleKey(dev, onTop);
                this.styleKey = RECORD_TYPES.has(rawKey) ? rawKey : 'default';
                this.themeClass = `theme-${this.styleKey}`;
                this.buildDisplayedFields();
                this.isLoading = false;
                this.error = undefined;
            })
            .catch(error => {
                this.isLoading = false;
                this.error = error;
                console.error('Error loading data:', error);
                this.showNotification('Error', error?.body?.message || 'Failed to load conditions', 'error');
            });
    }

    deriveStyleKey(devName, onTop) {
        let key = (devName || '').toLowerCase().replace(/_/g,'-') || 'default';
        if (onTop === true && (key === 'simulation' || key === 'signed' || key === 'to-be-signed')) {
            key = 'on-top';
        }
        return key;
    }

    get containerClass() {
        return `cl-layout ${this.themeClass}`;
    }

    buildDisplayedFields() {
        this.displayedFields = [];
        for (const field of this.columnsFromApex) {
            const fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel.toUpperCase(),
                fieldType: field.fieldType,
                isNumberField: ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT'].includes(field.fieldType),
                isReference: field.fieldType === 'REFERENCE',
                isDate: field.fieldType === 'DATE',
                isDateTime: field.fieldType === 'DATETIME',
                isPicklist: field.fieldType === 'PICKLIST',
                isBoolean: field.fieldType === 'BOOLEAN',
                isTextarea: field.fieldType === 'TEXTAREA',
                scale: field.scale,
                style: '',
                headerStyle: '',
                pickListValues: Array.isArray(field.picklistValues) ? field.picklistValues.map(p => ({
                    label: p.getLabel ? p.getLabel() : (p.label ?? ''),
                    value: String(p.getValue ? p.getValue() : (p.value ?? '')),
                })) : [],
            };

            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;

            if (fieldWrapper.isNumberField) {
                fieldWrapper.style += 'text-align:right;';
            }
            this.displayedFields.push(fieldWrapper);
        }
        this.buildData();
    }

    buildData() {
        const data = Array.isArray(this.allRecords) ? this.allRecords : [];
        const records = [];
        for (const item of data) {
            const record = this.buildRecord(item);
            records.push(record);
        }
        this.records = records;
    }

    buildRecord(discount) {
        const recordWrapper = {
            id: discount.Id,
            _key: discount.Id,
            values: []
        };
        for (let field of this.displayedFields) {
            const fieldWrapper = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldValue: '',
                fieldOutputValue: '',
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextarea: field.isTextarea,
                isText: field.isText,
                link: field.fieldName === 'Name' ? '/' + discount.Id : '',
                isNameField: field.fieldName === 'Name',
                scale: field.scale,
                step: field.step,
                pickListValues: field.pickListValues || [],
                style: (field.style ? field.style : '') + 'word-wrap: break-word;white-space: break-spaces;',
            };
            let values = field.fieldName.split('.');
            for (let index = 0; index < values.length; index++) {
                let item = index == 0 ? discount : fieldWrapper.fieldValue;
                if (index == values.length - 1 && field.fieldType == 'REFERENCE') {
                    fieldWrapper.fieldValue = item[values[index]] ? item[values[index].replace('__c', '__r')].Name : '';
                    fieldWrapper.link = '/' + item[values[index]];
                } else {
                    fieldWrapper.fieldValue = item[values[index]];
                }
            }
            if (fieldWrapper.isPicklist) {
                fieldWrapper.fieldOutputValue = fieldWrapper.pickListValues.find(o => o.value == fieldWrapper.fieldValue)?.label;
            }
            recordWrapper.values.push(fieldWrapper);
        }
        return recordWrapper;
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({ title: title, message: message, variant: variant });
        this.dispatchEvent(evt);
    }
}