import { LightningElement, api, track } from 'lwc';

//LABELS
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_True from "@salesforce/label/c.LBL_True";
import LBL_False from "@salesforce/label/c.LBL_False";
import LBL_Number_Of_Fixed_Columns from "@salesforce/label/c.LBL_Number_Of_Fixed_Columns";

const SUPPORTED_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME', 'RECORDTYPE'];
const SUPPORTED_VALUES_TYPES = ['ID', 'STRING', 'REFERENCE', 'BOOLEAN', 'PICKLIST', 'MULTIPICKLIST', 'RECORDTYPE'];
const SUPPORTED_RANGE_TYPES = ['DOUBLE', 'INTEGER', 'LONG', 'CURRENCY', 'PERCENT', 'DATE', 'DATETIME', 'TIME'];

export default class DynamicFilterPanel extends LightningElement {

  @api filters;
  // set Sticky
  @api numberOfFixedColumns;
  @track fixedColumnsOptions = [];
  
  fieldsToFilterMap = {};
  @track fieldsToFilter = [];
  @track labels = {
    LBL_Reset,
    LBL_Filter,
    LBL_Apply,
    LBL_False,
    LBL_True,
    LBL_Number_Of_Fixed_Columns,
  }

  connectedCallback() {
    let filtersList = this.filters ? JSON.parse(this.filters) : [];
    console.log('this.filters >>>> ' + JSON.stringify(filtersList))
    this.populateFiltersMap(filtersList);
    
    this.fixedColumnsOptions = [
        { label: '0', value: 0 },
        { label: '1', value: 1 },
        { label: '2', value: 2 },
        { label: '3', value: 3 },
        { label: '4', value: 4 },
        { label: '5', value: 5 },
        { label: '6', value: 6 },
    ];
  }

  populateFiltersMap(fields) {
    this.fieldsToFilterMap = {};
    for (let field of fields) {
      let fieldToFilter = {};
      if (SUPPORTED_TYPES.includes(field.stringFieldType)
        || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)
        || field.hasOwnProperty('userFilterable')) {
        fieldToFilter.fieldLabel = field.fieldLabel;
        fieldToFilter.fieldName = field.fieldName;
        fieldToFilter.stringFieldType = field.stringFieldType;
        fieldToFilter.isMultiLevel = field.hasOwnProperty('isMultiLevel') ? field.isMultiLevel : false;
        if (field.hasOwnProperty('userFilterable')) fieldToFilter.userFilterable = field.userFilterable;
        if (field.stringFieldType == 'ID') {
          if (field.values) fieldToFilter.displayVal = field.values.join(';');
          fieldToFilter.isId = true;
        }
        fieldToFilter.isText = field.stringFieldType == 'STRING';
        fieldToFilter.isReference = field.stringFieldType == 'REFERENCE';
        fieldToFilter.isCheckboxGroup = field.stringFieldType == 'BOOLEAN' || ((field.stringFieldType == 'PICKLIST' || field.stringFieldType == 'MULTIPICKLIST' || field.stringFieldType == 'RECORDTYPE') && (field.pickListValues && field.pickListValues.length > 1));
        if (fieldToFilter.isCheckboxGroup) {
          fieldToFilter.options = field.stringFieldType == 'BOOLEAN' ? [{ label: this.labels.LBL_True, value: 'true' }, { label: this.labels.LBL_False, value: 'false' }] : field.pickListValues;
        }
        fieldToFilter.isNumber = field.stringFieldType == 'DOUBLE' || field.stringFieldType == 'INTEGER' || field.stringFieldType == 'LONG' || field.stringFieldType == 'CURRENCY' || field.stringFieldType == 'PERCENT';
        if (fieldToFilter.isNumber) {
          if (field.stringFieldType == 'DOUBLE') {
            fieldToFilter.formatter = 'decimal';
          }
          if (field.stringFieldType == 'CURRENCY') {
            fieldToFilter.formatter = 'currency';
          }
          if (field.stringFieldType == 'PERCENT') {
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
          || (field.stringFieldType == 'RECORDTYPE' && field.pickListValues && field.pickListValues.length > 1)) {
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
        .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType !== 'RECORDTYPE')
        .map(fieldName => { return filtersMap[fieldName]; });
      //get record type field
      var recordTypeField = Object.keys(filtersMap)
        .filter(fieldName => filtersMap[fieldName].isMultiLevel == false && filtersMap[fieldName].stringFieldType == 'RECORDTYPE')
        .map(fieldName => { return filtersMap[fieldName]; });
      //add record type fields always to the top
      if (recordTypeField && recordTypeField[0]) this.fieldsToFilter.unshift(recordTypeField[0]);
      this.multilevelFields = Object.keys(filtersMap)
        .filter(fieldName => filtersMap[fieldName].isMultiLevel == true)
        .map(fieldName => { return filtersMap[fieldName]; });
      this.fieldsToFilter.forEach(item => {
        if (item.isText || item.isReference) {
          item.value = item.values.length != 0 ? item.values[0] : '';
        }
      })
    }
  }

  setSelectedValues(event) {
    var value = event.detail.value;
    var fieldName = event.target.name;
    var modeValue = event.target.dataset.mode;
    if (this.fieldsToFilterMap[fieldName]) {
      let field = this.fieldsToFilterMap[fieldName];
      field.values = [];
      if (modeValue == 'multiple') {
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
    console.log('confirmFilter ??? ' + JSON.stringify(this.filters))
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
        }).filter(item => (item.hasOwnProperty('values') || item.hasOwnProperty('value1') || item.hasOwnProperty('value2') || item.hasOwnProperty('userFilterable')));
      console.log('2222 ???')
      let dynamicFilters = JSON.stringify(selection);
      console.log('2222 ???' + dynamicFilters)
      const applyFilterEvent = new CustomEvent('applyfilter', { detail: { dynamicFilters: dynamicFilters, numberOfFixedColumns: this.numberOfFixedColumns }});
      this.dispatchEvent(applyFilterEvent);
    } catch (error) {
      console.log(error);
    }
  }

  handleReset() {
    let dynamicFilters = '';
    const applyFilterEvent = new CustomEvent('applyfilter', { detail: { dynamicFilters: dynamicFilters, numberOfFixedColumns: 0} });
    this.dispatchEvent(applyFilterEvent);
    if (this.filters) {
      this.populateFiltersMap(JSON.parse(this.filters));
    }
  }

  toggleFilter() {
    const toggleFilterEvent = new CustomEvent('togglefilter', { detail: {} });
    this.dispatchEvent(toggleFilterEvent);
  }

  handleStickycolumnChanged(event) {
    this.numberOfFixedColumns = Number(event.target.value);
  }

}