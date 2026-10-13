import { LightningElement, api, track } from 'lwc';
import { Labels, Operations, evaluateExpression, getFieldOperationByType } from "c/gridSettingsHelper"

export default class GridSettingsExpressionEditor extends LightningElement {
    @api criteriasWrapperjson; //readOnlyCriteriasWrapperjson
    @api confirmEvent;
    @api closeEvent;
    @track fieldOptions = [];
    @track fieldsMap = {};
    @track readOnlyCriterias = [];
    get readOnlyCriteriasMap() {
        let rulesMap = {};
        for (let index = 0; this.readOnlyCriterias && index < this.readOnlyCriterias.length; index++) {
            rulesMap[index + 1] = this.readOnlyCriterias[index];
        }
        return rulesMap;
    }
    @track expression = '';
    @track Label = Labels;
    @track Operations = Operations;
    @track booleanValueOptions = [
        {
            label: Labels.LBL_True,
            value: 'true'
        },
        {
            label: Labels.LBL_False,
            value: 'false'
        }
    ];
    @api updateFields(criteriasWrapperjson) {
        this.criteriasWrapperjson = criteriasWrapperjson;
        this.setComponent();
    }
    connectedCallback() {
        this.setComponent();
    }
    setComponent() {
        try {
            if (this.criteriasWrapperjson) {
                let readOnlyCriteriasWrapper = JSON.parse(this.criteriasWrapperjson);
                let readOnlyCriterias = [];
                if (readOnlyCriteriasWrapper) {
                    if (readOnlyCriteriasWrapper.fieldsMap) {
                        this.fieldsMap = readOnlyCriteriasWrapper.fieldsMap;
                        let fieldOptions = [{ label: Labels.LBL_None, value: '' }];
                        Object.values(readOnlyCriteriasWrapper.fieldsMap).filter(item => item.isFilterable).sort((item1, item2) => item1.fieldLabel.localeCompare(item2.fieldLabel)).forEach(item => {
                            item.isRecordTypeId = item.fieldName.toLowerCase().includes('recordtypeid');
                            item.isText = item.fieldType === 'STRING' || item.fieldType === 'PICKLIST' || item.fieldType === 'MULTIPICKLIST';
                            item.isNumber = item.fieldType === 'DOUBLE'
                                || item.fieldType === 'INTEGER'
                                || item.fieldType === 'LONG'
                                || item.fieldType === 'PERCENT'
                                || item.fieldType === 'CURRENCY';
                            item.isCalculated = item.isCalculated || item.fieldLabel.includes('>') || item.fieldType == 'ID' || item.isCreateable == false || item.isUpdateable == false;;
                            item.isBoolean = item.fieldType === 'BOOLEAN';
                            item.isDate = item.fieldType === 'DATE';
                            item.isDateTime = item.fieldType === 'DATETIME';
                            item.isTime = item.fieldType === 'TIME';
                            item.isReference = item.fieldType === 'REFERENCE';
                            item.isNumberOrBoolean = item.isNumber || item.isBoolean;
                            item.isNumberOrBooleanOrTextOrRecordTypeId = item.isNumberOrBoolean || item.isText || item.isRecordTypeId;
                            fieldOptions.push({ label: item.fieldLabel, value: item.fieldName });
                        })
                        this.fieldOptions = fieldOptions;
                    }
                    if (readOnlyCriteriasWrapper.rulesMap) {
                        let keys = Object.keys(readOnlyCriteriasWrapper.rulesMap).sort((key1, key2) => key1.localeCompare(key2));
                        let fieldsMap = this.fieldsMap;
                        for (let index = 1; index <= keys[keys.length - 1]; index++) {
                            let item = {
                                operation: readOnlyCriteriasWrapper.rulesMap.hasOwnProperty(index) ? readOnlyCriteriasWrapper.rulesMap[index].operation : '',
                                fieldName: readOnlyCriteriasWrapper.rulesMap.hasOwnProperty(index) ? readOnlyCriteriasWrapper.rulesMap[index].fieldName : '',
                                value: readOnlyCriteriasWrapper.rulesMap.hasOwnProperty(index) ? readOnlyCriteriasWrapper.rulesMap[index].value : '',
                                get isBlankOrIsNull() { return this.operation == Operations.ISNULL || this.operation == Operations.ISBLANK },
                                get valueType() {
                                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                                        if (fieldsMap[this.fieldName].isNumber) {
                                            return 'number';
                                        } else if (fieldsMap[this.fieldName].isBoolean) {
                                            return 'checkbox';
                                        } else if (fieldsMap[this.fieldName].isDate) {
                                            return 'date';
                                        } else if (fieldsMap[this.fieldName].isDateTime) {
                                            return 'datetime';
                                        } else if (fieldsMap[this.fieldName].isTime) {
                                            return 'time';
                                        }
                                    }
                                    return 'text';
                                },
                                get operationOptions() {
                                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                                        return getFieldOperationByType(fieldsMap[this.fieldName]);
                                    }
                                    return [{ label: Labels.LBL_None, value: '' }];
                                },
                                get showpicklistvalues() {
                                    let picklistvalues = this.picklistvalues;
                                    return picklistvalues && picklistvalues.length;
                                },
                                get picklistvalues() {
                                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                                        if (fieldsMap[this.fieldName].isBoolean) {
                                            return [
                                                { label: Labels.LBL_True, value: 'true' },
                                                { label: Labels.LBL_False, value: 'false' },
                                            ];
                                        }
                                        return fieldsMap[this.fieldName].pickListValues || undefined;
                                    }
                                    return undefined;
                                },
                                index: index
                            };
                            readOnlyCriterias.push(item);
                        }
                    }
                }
                this.readOnlyCriterias = readOnlyCriterias;
                this.expression = readOnlyCriteriasWrapper.expression || readOnlyCriterias.map(item => item.index).join(' AND ');
            }
        } catch (error) {
            console.log(error);
        }
        this.addDefaultRule();
    }
    addDefaultRule() {
        let fieldsMap = this.fieldsMap;
        let readOnlyCriterias = this.readOnlyCriterias || [];
        if (readOnlyCriterias && !readOnlyCriterias.length) {
            if (!this.expression || !this.expression.trim()) {
                this.expression = 1;
            }
            let item = {
                operation: '',
                fieldName: '',
                value: '',
                get isBlankOrIsNull() { return this.operation == Operations.ISNULL || this.operation == Operations.ISBLANK },
                get valueType() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        if (fieldsMap[this.fieldName].isNumber) {
                            return 'number';
                        } else if (fieldsMap[this.fieldName].isBoolean) {
                            return 'checkbox';
                        } else if (fieldsMap[this.fieldName].isDate) {
                            return 'date';
                        } else if (fieldsMap[this.fieldName].isDateTime) {
                            return 'datetime';
                        } else if (fieldsMap[this.fieldName].isTime) {
                            return 'time';
                        }
                    }
                    return 'text';
                },
                get operationOptions() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        return getFieldOperationByType(fieldsMap[this.fieldName]);
                    }
                    return [{ label: Labels.LBL_None, value: '' }];
                },
                get showpicklistvalues() {
                    let picklistvalues = this.picklistvalues;
                    return picklistvalues && picklistvalues.length;
                },
                get picklistvalues() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        if (fieldsMap[this.fieldName].isBoolean) {
                            return [
                                { label: Labels.LBL_True, value: 'true' },
                                { label: Labels.LBL_False, value: 'false' },
                            ];
                        }
                        return fieldsMap[this.fieldName].pickListValues || undefined;
                    }
                    return undefined;
                },
                index: 1
            };
            readOnlyCriterias.push(item);
            this.readOnlyCriterias = readOnlyCriterias.map(item => item);
        }
    }
    handleExpressionChange(event) {
        let value = event.detail.value;
        this.expression = value;
        this.notifyParent();
    }
    checkExpressionValidity() {
        var inputCmp = this.template.querySelector('.expressionInput');
        let evalResult = evaluateExpression(this.expression, this.readOnlyCriterias.filter(item => item.fieldName && item.operation).map(item => item.index));
        if (inputCmp) {
            this.hasError = !evalResult.isSuccess;
            if (evalResult.error) {
                inputCmp.setCustomValidity(evalResult.error + (evalResult.expression ? " : " + evalResult.expression : ''));
            } else {
                inputCmp.setCustomValidity("");
            }
            inputCmp.reportValidity();
        }
    }
    deleteCriteriaHandler(event) {
        try {
            let elementIndex = event.target.dataset.index - 1;
            if (elementIndex != 0) {
                // let index = 0;
                this.readOnlyCriterias.splice(elementIndex, 1);
            } else {
                if (this.readOnlyCriterias.length > 0) {
                    this.readOnlyCriterias[0].operation = '';
                    this.readOnlyCriterias[0].fieldName = '';
                    this.readOnlyCriterias[0].value = '';
                }
            }
            let counter = 1;
            this.readOnlyCriterias = this.readOnlyCriterias.map(item => { item.index = counter++; return item; });
            this.addDefaultRule();
            this.notifyParent();
        } catch (error) {
            console.log(error);
        }
    }
    handleFieldChange(event) {
        try {
            let elementIndex = event.target.dataset.index - 1;
            let value = event.detail.value;
            this.readOnlyCriterias[elementIndex].fieldName = value;
            this.readOnlyCriterias = this.readOnlyCriterias.map(item => item);
            this.notifyParent();
        } catch (error) {
            console.log(error);
        }
    }
    handleOperationChange(event) {
        try {
            let elementIndex = event.target.dataset.index - 1;
            let value = event.detail.value;
            this.readOnlyCriterias[elementIndex].operation = value;
            this.readOnlyCriterias = this.readOnlyCriterias.map(item => item);
            this.notifyParent();
        } catch (error) {
            console.log(error);
        }
    }
    handleValuechange(event) {
        try {
            let elementIndex = event.target.dataset.index - 1;
            let value = event.detail.value;
            this.readOnlyCriterias[elementIndex].value = value;
            this.readOnlyCriterias = this.readOnlyCriterias.map(item => item);
            this.notifyParent();
        } catch (error) {
            console.log(error);
                        }
    }
    addCriteriaHandler() {
        try {
            let fieldsMap = this.fieldsMap;
            let newIndex = this.readOnlyCriterias.length;
            let readOnlyCriteria = {
                fieldName: '',
                operation: '',
                value: '',
                get isBlankOrIsNull() { return this.operation == Operations.ISNULL || this.operation == Operations.ISBLANK },
                get valueType() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        if (fieldsMap[this.fieldName].isNumber) {
                            return 'number';
                        } else if (fieldsMap[this.fieldName].isBoolean) {
                            return 'checkbox';
                        } else if (fieldsMap[this.fieldName].isDate) {
                            return 'date';
                        } else if (fieldsMap[this.fieldName].isDateTime) {
                            return 'datetime';
                        } else if (fieldsMap[this.fieldName].isTime) {
                            return 'time';
                        }
                    }
                    return 'text';
                },
                get operationOptions() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        return getFieldOperationByType(fieldsMap[this.fieldName]);
                    }
                    return [{ label: Labels.LBL_None, value: '' }];
                },
                get showpicklistvalues() {
                    let picklistvalues = this.picklistvalues;
                    return picklistvalues && picklistvalues.length;
                },
                get picklistvalues() {
                    if (fieldsMap.hasOwnProperty(this.fieldName)) {
                        if (fieldsMap[this.fieldName].isBoolean) {
                            return [
                                { label: Labels.LBL_True, value: 'true' },
                                { label: Labels.LBL_False, value: 'false' },
                            ];
                        }
                        return fieldsMap[this.fieldName].pickListValues || undefined;
                    }
                    return undefined;
                },
                index: newIndex + 1
            };
            if (this.expression) {
                let matched = this.expression.match ? this.expression.match(new RegExp('[0-9]+', 'gi')) : [];
                if (!matched || matched.includes('' + (newIndex + 1))) {
                    this.expression += ' AND ' + (newIndex + 1);
                }
            }
            let readOnlyCriterias = this.readOnlyCriterias.map(item => item);
            readOnlyCriterias.push(readOnlyCriteria);
            this.readOnlyCriterias = readOnlyCriterias;
            this.notifyParent();
        } catch (error) {
            console.log(error);
        }
    }
    notifyParent() {
        this.checkExpressionValidity();
        let readOnlyCriterias = {};
        let readOnlyCriteriasMap = this.readOnlyCriteriasMap;
        let hasError = this.hasError;
        let expression = this.expression;
        Object.keys(readOnlyCriteriasMap).filter(key => readOnlyCriteriasMap[key] && readOnlyCriteriasMap[key].fieldName).forEach(key => readOnlyCriterias[key] = { fieldName: readOnlyCriteriasMap[key].fieldName, operation: readOnlyCriteriasMap[key].operation, value: readOnlyCriteriasMap[key].value, });
        let value = JSON.stringify({ expression: expression, rulesMap: readOnlyCriterias });
        const confirmEvent = new CustomEvent(this.confirmEvent, { detail: { value: value, hasError: hasError, }, });
        this.dispatchEvent(confirmEvent);
    }
}