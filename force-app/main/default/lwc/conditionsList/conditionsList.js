import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initData from '@salesforce/apex/ConditionsListController.initData';
import calculateRecalculatedRate from '@salesforce/apex/ConditionsListController.calculateRecalculatedRate';
import LBL_Conditions_List from '@salesforce/label/c.LBL_Conditions_List';

const labels = {
  LBL_Conditions_List
};

export default class ConditionsList extends NavigationMixin(LightningElement) {
  labels = labels;
  _contractId;
  @api set contractId(v) { this._contractId = v; }
  get contractId() { return this._contractId || this.recordId; }
  @api recordId;
  @track displayedFields = [];
  @track records = [];
  @track columnsFromApex = [];
  @track allRecords = [];
  @track isLoading = true;
  @track error;
  @track prefix;
  get hasData() { return (this.records && this.records.length > 0); }
  get hasFields() { return (this.displayedFields?.length || 0) > 0; }
  
  connectedCallback() {
    this.initData();
  }

  navigateToConditionManager() {
    if (!this.contractId) return;
    const payload = {componentDef: 'c:conditionManager', attributes: { recordId: this.contractId }, state: { "c__componentName": "c:conditionManager" }};
    const encoded = btoa(JSON.stringify(payload));
    this[NavigationMixin.Navigate]({type: 'standard__webPage', attributes: { url: `/one/one.app#${encoded}` }});
  }

  initData() {
    this.isLoading = true;
    initData({ contractId: this.contractId })
      .then(result => {
        const response = JSON.parse(result || '{}');
        this.prefix = response.prefix;
        this.columnsFromApex = Array.isArray(response.fieldList) ? response.fieldList : [];
        this.allRecords = Array.isArray(response.records) ? response.records : [];
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
        fieldWrapper.headerStyle += 'text-align:right;';
        fieldWrapper.className = 'cl-num';
      } else if (fieldWrapper.isBoolean) {
        fieldWrapper.className = 'cl-bool';
      } else {
        fieldWrapper.className = 'cl-text';
      }
      this.displayedFields.push(fieldWrapper);
    }
    this.buildData();
  }

  async buildData() {
    const data = Array.isArray(this.allRecords) ? this.allRecords : [];
    const records = [];
    for (const item of data) {
      const record = await this.buildRecord(item);
      records.push(record);
    }
    this.records = records;
  }

  async buildRecord(discount) {
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
        link: '',
        isNameField: false,
        scale: field.scale,
        pickListValues: field.pickListValues || [],
        style: (field.style ? field.style : '') + 'word-wrap: break-word;white-space: break-spaces;',
        className: field.className,
        key: `${discount.Id}-${field.fieldName}`
      };

      // Handle calculated field
      if (field.fieldName === 'recalculatedRate') {
        try {
          fieldWrapper.fieldValue = await calculateRecalculatedRate({ discountId: discount.Id });
        } catch (e) {
          console.warn('Error calculating rate:', e);
          fieldWrapper.fieldValue = null;
        }
      } else {
        // Resolve value (supports: 'Lookup__c'  OR  'Lookup__r.Name')
        const path = field.fieldName.split('.');
        const isRef = field.fieldType === 'REFERENCE';

        let curr = discount;
        for (const seg of path) {
          if (curr == null) break;
          curr = curr[seg];
        }

        if (isRef) {
          fieldWrapper.fieldValue = (curr && typeof curr === 'object') ? curr.Name : (curr ?? '');
          const lookupApi = (path[0] || '').replace('__r', '__c');
          const idVal = discount?.[lookupApi];
          fieldWrapper.link = idVal ? '/' + idVal : '';
          if (field.fieldName === 'Condition_Type__r.Name') {
            fieldWrapper.link = '';
          }
        } else {
          fieldWrapper.fieldValue = curr;
        }
      }
      if (fieldWrapper.isPicklist) {
        fieldWrapper.fieldOutputValue = fieldWrapper.pickListValues.find(o => o.value === fieldWrapper.fieldValue)?.label;
      }
      recordWrapper.values.push(fieldWrapper);
    }
    return recordWrapper;
  }

  showNotification(title, message, variant) {
    const evt = new ShowToastEvent({title: title, message: message, variant: variant});
    this.dispatchEvent(evt);
  }
}