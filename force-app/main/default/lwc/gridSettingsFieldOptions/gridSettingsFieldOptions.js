import { LightningElement, track, api } from 'lwc';
//labels
import { Labels, toastInfo, toastError, toastSuccess } from "c/gridSettingsHelper"
export default class GridSettingsFieldOptions extends LightningElement {
    @api fieldswrapperjson;
    @api iconNamePicklist;
    @track fieldWrapper;
    @track Loading;
    @track operation;
    @track value1;
    @track value2;
    @track formatingRuleStyle;
    @track newLabel;
    @track formatingRuleOppositeStyle;
    @track editting = false;
    @track urlOptions = [{ label: Labels.LBL_Display_Full_URL, value: 'FullURL' },
    { label: Labels.LBL_Replace_With_Text, value: 'TextReplace' },
    { label: Labels.LBL_Replace_With_Icon, value: 'IconReplace' }];
    edittingIndex = -1;
    @track currentExternalCriteria = { expression: '', rulesMap: {}, fieldsMap: {}, };
    @track externalCriteriaHasError = false;
    @track conditionalRules = [];
    @track externalCriteriasJSON = JSON.stringify({ expression: '', rulesMap: {}, fieldsMap: {}, });
    @track showInputOne = false;
    @track showInputTwo = false;
    @track picklistvalues;
    picklistvaluesMap;
    picklistColorsList;
    @api picklistvaluesjson;
    @api cancelEvent;
    @api confirmEvent;
    @api currentFieldsSettingsLabel;
    @api relationshipname;
    @api refobjectfields;
    @api objectfields;
    @api fieldsMap;
    @track currentFieldsMap;
    @track showpicklistvalues = false;
    @track defaultObjectSelected = '';
    @track defaultValue = '';
    @track defaultExpression = '';
    @track displayControleMessage = false;
    @track displayFullURL;
    @track replaceWithIcon;
    @track replaceWithText;
    @track iconPicklist = [];
    @api objectname;
    get isBigObject() {
        return this.objectname != null && this.objectname != "" && this.objectname.endsWith("__b");
    }
    @track controlOptions = [
        { label: Labels.LBL_Disable, value: 'DISABLE' },
        { label: Labels.LBL_Message_Error, value: 'ERROR_MESSAGE' },
        { label: Labels.LBL_Message_Warning, value: 'WARNING_MESSAGE' },
        { label: Labels.LBL_Message_Info, value: 'INFO_MESSAGE' },
        { label: Labels.LBL_Message_Success, value: 'SUCCESS_MESSAGE' },
    ];
    currentRule = {
        style: {},
        oppositeStyle: {},
        operation: '',
        value1: '',
        value2: '',
    };
    Label = Labels;
    @track defaultType = 'text';
    Events = {
        nonConditional: 'nonconditional',
        newLabel: 'newlabel',
        formatingRuleStyle: 'formatingrulestyle',
        formatingRuleOppositeStyle: 'formatingruleoppositestyle',
        cancelEditor: 'canceleditor',
        cancelExternalCriteriaExpressionEditor: 'cancelexternalcriteriaexpressioneditor',
        confirmExternalCriteriaExpressionEditor: 'confirmexternalcriteriaexpressioneditor',
    }
    borderStyleOptions = [
        { label: this.Label.LBL_Unset, value: ' ' },
        { label: this.Label.LBL_None, value: 'none' },
        { label: this.Label.LBL_Dotted, value: 'dotted' },
        { label: this.Label.LBL_Dashed, value: 'dashed' },
        { label: this.Label.LBL_Solid, value: 'solid' },
        { label: this.Label.LBL_Double, value: 'double' },
        { label: this.Label.LBL_Groove, value: 'groove' },
        { label: this.Label.LBL_Ridge, value: 'ridge' },
        { label: this.Label.LBL_Inset, value: 'inset' },
        { label: this.Label.LBL_Outset, value: 'outset' },
    ];
    booleanOptions = [
        { label: this.Label.LBL_True, value: 'true' },
        { label: this.Label.LBL_False, value: 'false' }
    ];
    // personalisedFieldTypeOptions = [
    //     { label: this.Label.LBL_Button, value: 'Button' },
    //     { label: this.Label.LBL_Link, value: 'Link' },
    // ];
    connectedCallback() {
        this.iconPicklist.push({ label: 'None', value: '' });
        for (let item of this.iconNamePicklist) {
            this.iconPicklist.push(item);
        }
        let currentFieldsMap = {};
        for (let field of Object.values(this.fieldsMap)) {
            if (!field.fieldLabel.includes('>') && !field.fieldName.includes('.')) {
                currentFieldsMap[field.fieldName] = field;
            }
        }
        this.currentFieldsMap = currentFieldsMap;
        let currentExternalCriteria = { expression: '', rulesMap: {}, fieldsMap: currentFieldsMap, };
        let externalCriteriasJSON = JSON.stringify(currentExternalCriteria);
        this.currentExternalCriteria = currentExternalCriteria;
        this.externalCriteriasJSON = externalCriteriasJSON;
        if (this.picklistvaluesjson) {
            this.picklistvalues = JSON.parse(this.picklistvaluesjson);
            this.showpicklistvalues = this.picklistvalues.length > 0;
            this.picklistvaluesMap = {};
            this.picklistColorsList = [];
            this.picklistvalues.forEach(item => {
                this.picklistvaluesMap[item.value] = item.label;
                this.picklistColorsList.push({ value: item.value, label: item.label, color: '' });
            });
        } else {
            this.showpicklistvalues = false;
            this.picklistvalues = undefined;
        }
        let fieldWrapper = {};
        let fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        let fieldType;
        this.Loading = true;
        if (!this.fieldswrapperjson) {
            this.Loading = false;
            toastError(this, this.Label.MSG_Application_Error);
            return;
        }
        if (fieldsWrapperList.length == 1) {
            fieldWrapper = fieldsWrapperList[0];
            this.defaultType = fieldWrapper.defaultType;
            this.defaultValue = fieldWrapper.defaultValue;
            this.defaultExpression = fieldWrapper.defaultExpression;
            if (fieldWrapper.conditionalRules) {
                this.conditionalRules = fieldWrapper.conditionalRules.map(item => {
                    let newItem = {
                        description: item.description,
                        criteria: item.criteria,
                        action: item.action,
                        message: item.message,
                        get criteriasList() {
                            let listRules = [];
                            for (var key of Object.keys(item.criteria.rulesMap)) {
                                listRules.push({
                                    fieldName: item.criteria.rulesMap[key].fieldName,
                                    operation: item.criteria.rulesMap[key].operation,
                                    value: item.criteria.rulesMap[key].value,
                                });
                            }
                            return listRules;
                        }
                    };
                    return newItem;
                });
            }
            if (fieldWrapper.picklistColorsMap) {
                if (this.picklistColorsList) {
                    this.picklistColorsList.forEach(item => {
                        if (fieldWrapper.picklistColorsMap.hasOwnProperty(item.value)) {
                            item.color = fieldWrapper.picklistColorsMap[item.value] || '';
                        }
                    });
                }
            }
            fieldType = fieldWrapper.fieldType;
            fieldWrapper.isRecordTypeId = fieldWrapper.key.toLowerCase().includes('recordtypeid');
            fieldWrapper.isText = fieldType === 'STRING' || fieldType === 'PICKLIST' || fieldType === 'MULTIPICKLIST';
            fieldWrapper.isPicklist = fieldType === 'PICKLIST';
            fieldWrapper.isMultiPicklist = fieldType === 'MULTIPICKLIST';
            fieldWrapper.isDate = fieldType === 'DATE';
            fieldWrapper.isDateTime = fieldType === 'DATETIME';
            fieldWrapper.isNumber = fieldType === 'DOUBLE'
                || fieldType === 'INTEGER'
                || fieldType === 'LONG'
                || fieldType === 'PERCENT'
                || fieldType === 'CURRENCY';
            fieldWrapper.isCalculated = fieldWrapper.isCalculated || fieldWrapper.fieldLabel.includes('>') || fieldType == 'ID' || fieldWrapper.isCreateable == false || fieldWrapper.isUpdateable == false;
            fieldWrapper.isBoolean = fieldType === 'BOOLEAN';
            fieldWrapper.isURL = fieldType === 'URL';
            if (fieldWrapper.isURL) {
                this.displayFullURL = fieldWrapper.URLOption == "FullURL";
                this.replaceWithIcon = fieldWrapper.URLOption == "IconReplace";
                this.replaceWithText = fieldWrapper.URLOption == "TextReplace";
            }
            fieldWrapper.isNumberOrBoolean = fieldWrapper.isNumber || fieldWrapper.isBoolean;
            fieldWrapper.isFilterable = fieldWrapper.isFilterable;
            fieldWrapper.hasTotal = fieldWrapper.isNumberOrBoolean && !fieldWrapper.value.includes('.');
            fieldWrapper.isNumberOrBooleanOrTextOrRecordTypeId = fieldWrapper.isNumberOrBoolean || fieldWrapper.isText || fieldWrapper.isRecordTypeId;
            fieldWrapper.isSeparator = fieldWrapper.fieldLabel.includes('Separator');
            fieldWrapper.isPersonalised = fieldWrapper.isPersonalised && fieldWrapper.isPersonalised == true;
            fieldWrapper.someIsPersonalized = fieldWrapper.allIsPersonalised = fieldWrapper.isPersonalised;
            if (fieldWrapper.isSeparator) {
                fieldWrapper.separatorSettings = fieldWrapper.separatorSettings ? fieldWrapper.separatorSettings : {};
                fieldWrapper.separatorSettings.size = fieldWrapper.separatorSettings.size ? fieldWrapper.separatorSettings.size : '1px';
                fieldWrapper.separatorSettings.color = fieldWrapper.separatorSettings.color ? fieldWrapper.separatorSettings.color : '#000000';
                fieldWrapper.separatorSettings.pattern = fieldWrapper.separatorSettings.pattern ? fieldWrapper.separatorSettings.pattern : 'solid';
            }
            fieldWrapper.isMultiple = false;
            if (fieldWrapper.formattingRulesList) {
                fieldWrapper.hasConditionalFormating = fieldWrapper.formattingRulesList.length > 0;
                for (let index = 0; index < fieldWrapper.formattingRulesList.length; index++) {
                    if (this.picklistvaluesMap.hasOwnProperty(fieldWrapper.formattingRulesList[index].value1)) {
                        fieldWrapper.formattingRulesList[index].displayValue = this.picklistvaluesMap[fieldWrapper.formattingRulesList[index].value1];
                    } else {
                        fieldWrapper.formattingRulesList[index].displayValue = fieldWrapper.formattingRulesList[index].value1;
                        if (fieldWrapper.formattingRulesList[index].value2 && fieldWrapper.formattingRulesList[index].value2 != '') {
                            fieldWrapper.formattingRulesList[index].displayValue += ' ' + this.Label.LBL_And + ' ' + fieldWrapper.formattingRulesList[index].value2;
                        }
                    }
                }
            } else {
                fieldWrapper.hasConditionalFormating = false;
                fieldWrapper.formattingRulesList = [];
            }
            fieldWrapper.isBooleanWithOneFormatingRuleStyle = fieldWrapper.isBoolean && fieldWrapper.formattingRulesList && fieldWrapper.formattingRulesList.length > 0;
            this.fieldWrapper = fieldWrapper;
            this.fieldWrapper.showInTotal = this.fieldWrapper.showInTotal != false ? true : false;
            this.fieldWrapper.newLabel = fieldWrapper.newLabel;
            if (fieldWrapper.newLabel) {
                this.newLabel = this.fieldWrapper.newLabel;
            }
            this.fieldWrapper.internallyCalculated = this.fieldWrapper.internallyCalculated != false ? true : false;
            if (this.fieldWrapper.showInTotal && this.totalTypeOptions.length > 0 && !this.fieldWrapper.totalType) {
                this.fieldWrapper.totalType = this.totalTypeOptions[0].value;
            }
            if (!this.fieldWrapper.nonConditional) {
                this.fieldWrapper.nonConditional = {
                    isAdvanced: false,
                    advancedStyle: '',
                    textStyle: {
                        isItalic: false,
                        isCenter: false,
                        isUnderLine: false,
                        isStrikeThrought: false,
                        color: '',
                        size: '',
                        align: '',
                    },
                    bgColor: this.fieldWrapper.bgColor,
                    width: '',
                    borderStyle: { color: '', pattern: '', size: '' }
                };
            } else if (!this.fieldWrapper.nonConditional.bgColor) {
                this.fieldWrapper.nonConditional.bgColor = this.fieldWrapper.bgColor;
            }
            if (!this.fieldWrapper.headerStyle) {
                this.fieldWrapper.headerStyle = {
                    bgColor: '',
                    color: '',
                    style: ''
                }
            }
        } else {
            this.fieldWrapper = {};
            this.fieldWrapper.isInputField = true;
            this.fieldWrapper.isNumber = true;
            this.fieldWrapper.isBoolean = true;
            this.fieldWrapper.showInTotal = true;
            this.fieldWrapper.internallyCalculated = true;
            for (let index = 0; index < fieldsWrapperList.length; index++) {
                fieldType = fieldsWrapperList[index].fieldType;
                fieldsWrapperList[index].isText = fieldType === 'STRING' ||
                    fieldType === 'PICKLIST' ||
                    fieldType === 'MULTIPICKLIST';
                fieldsWrapperList[index].isNumber = fieldType === 'DOUBLE'
                    || fieldType === 'INTEGER'
                    || fieldType === 'LONG'
                    || fieldType === 'PERCENT'
                    || fieldType === 'CURRENCY';
                fieldsWrapperList[index].isBoolean = fieldType === 'BOOLEAN';
                this.fieldWrapper.isInputField = this.fieldWrapper.isInputField && fieldsWrapperList[index].isInputField;
                this.fieldWrapper.isNumber = this.fieldWrapper.isNumber && fieldsWrapperList[index].isNumber;
                this.fieldWrapper.isBoolean = this.fieldWrapper.isBoolean && fieldsWrapperList[index].isBoolean;
                this.fieldWrapper.isPicklist = this.fieldWrapper.isPicklist && fieldsWrapperList[index].isPicklist;
                this.fieldWrapper.isMultiPicklist = this.fieldWrapper.isMultiPicklist && fieldsWrapperList[index].isMultiPicklist;
                this.fieldWrapper.isDate = this.fieldWrapper.isDate && fieldsWrapperList[index].isDate;
                this.fieldWrapper.isDateTime = this.fieldWrapper.isDateTime && fieldsWrapperList[index].isDateTime;
                this.fieldWrapper.showInTotal = this.fieldWrapper.showInTotal && fieldsWrapperList[index].showInTotal != false;
                this.fieldWrapper.internallyCalculated = this.fieldWrapper.internallyCalculated && fieldsWrapperList[index].internallyCalculated != false;
                this.fieldWrapper.someIsPersonalized = this.fieldWrapper.someIsPersonalized || fieldsWrapperList[index].isPersonalised != false;
                this.fieldWrapper.allIsPersonalised = this.fieldWrapper.allIsPersonalised && fieldsWrapperList[index].isPersonalised != false;
            }
            this.fieldWrapper.isMultiple = true;
            this.fieldWrapper.isNumberOrBoolean = this.fieldWrapper.isNumber || this.fieldWrapper.isBoolean;
            if (!this.fieldWrapper.headerStyle) {
                this.fieldWrapper.headerStyle = {
                    bgColor: '',
                    color: '',
                    style: ''
                }
            }
        }
        this.Loading = false;
    }
    handleDeleteExternalControl(event) {
        let controlIndex = event.target.dataset.id;
        this.conditionalRules = this.conditionalRules.filter((item, index) => index != controlIndex);
    }
    handlePickListItemColorChanged(event) {
        let target = event.target;
        let pickVal = target.dataset.id;
        this.picklistColorsList = this.picklistColorsList.filter(obj => {
            if (obj.value == pickVal) {
                obj.color = target.value;
            }
            return obj;
        });
    }
    closeSettings() {
        if (this.cancelEvent) {
            const cancelEvent = new CustomEvent(this.cancelEvent);
            this.dispatchEvent(cancelEvent);
        }
    }
    confirmSettings() {
        if (this.defaultExpression) {
            const fields = this.defaultExpression.match(/(?<=\{\!).+?(?=\})/g);
            for (const fieldName of fields) {
                const fieldData = this.objectfields.find(objField => objField.value === fieldName);
                if (!fieldData) {
                    toastError(this, this.Label.MSG_Invalid_Field.replace('{0}', fieldName));
                    return;
                }
                if (this.fieldWrapper.isNumber) {
                    const isNumber = fieldData?.type === 'DOUBLE'
                        || fieldData?.type === 'INTEGER'
                        || fieldData?.type === 'LONG'
                        || fieldData?.type === 'PERCENT'
                        || fieldData?.type === 'CURRENCY';
                    if (!isNumber) {
                        toastError(this, this.Label.MSG_Invalid_Field_Type.replace('{0}', fieldName));
                        return;
                    }
                }
            }
        }
        if (this.fieldWrapper.isPersonalised && (!this.fieldWrapper.value || !this.fieldWrapper.stringFieldType || (!this.fieldWrapper.action && this.fieldWrapper.rerender))) {
            toastError(this, this.Label.MSG_Fill_Required_Fields);
            return;
        }
        const confirmEvent = new CustomEvent(this.confirmEvent, {
            detail: { value: this.fieldsWrapperJSONDetail },
        });
        this.dispatchEvent(confirmEvent);
    }
    get valueType() {
        if (this.fieldWrapper.isNumber) {
            return 'number';
        } else if (this.fieldWrapper.isBoolean) {
            return 'checkbox';
        }
        return 'text';
    }
    get operationOptions() {
        if (this.fieldWrapper.isNumber) {
            return [
                { label: 'EQUALS', value: 'EQUALS' },
                { label: 'NOT EQUALS', value: 'NOT_EQUALS' },
                { label: 'GREATER', value: 'GREATER' },
                { label: 'GREATER OR EQUALS', value: 'GREATER_OR_EQUALS' },
                { label: 'LESS', value: 'LESS' },
                { label: 'LESS OR EQUALS', value: 'LESS_OR_EQUALS' },
                { label: 'BETWEEN', value: 'BETWEEN' },
            ];
        }
        if (this.fieldWrapper.isText) {
            return [
                { label: 'ISNULL', value: 'ISNULL' },
                { label: 'ISBLANK', value: 'ISBLANK' },
                { label: 'EQUALS', value: 'EQUALS' },
                { label: 'NOT EQUALS', value: 'NOT_EQUALS' },
                { label: 'CONTAINS', value: 'CONTAINS' },
                { label: 'DOESNT CONTAINS', value: 'NOT_CONTAINS' },
            ];
        }
        if (this.fieldWrapper.isRecordTypeId) {
            return [
                { label: 'ISNULL', value: 'ISNULL' },
                { label: 'ISBLANK', value: 'ISBLANK' },
                { label: 'EQUALS', value: 'EQUALS' },
                { label: 'NOT EQUALS', value: 'NOT_EQUALS' },
            ];
        }
        if (this.fieldWrapper.isBoolean) {
            return [
                { label: 'EQUALS', value: 'EQUALS' },
                { label: 'NOT EQUALS', value: 'NOT_EQUALS' },
            ];
        }
        return [];
    }
    get valueOptions() {
        return [
            { label: 'True', value: 'true' },
            { label: 'False', value: 'false' },
        ];
    }
    get totalTypeOptions() {
        if (this.fieldWrapper.isBoolean) {
            return [
                { label: 'COUNT', value: 'COUNT' },
            ];
        }
        if (this.fieldWrapper.isNumber) {
            return [
                { label: 'SUM', value: 'SUM' },
                { label: 'AVG', value: 'AVG' },
                { label: 'MIN', value: 'MIN' },
                { label: 'MAX', value: 'MAX' },
            ];
        }
        return [];
    }
    /*
        showStyleEditor(event) {
            let editorFieldName = event.currentTarget.dataset.fieldName;
            this['show' + editorFieldName + 'Edit'] = true;
        }
    */
    personalisedFieldNameChangeHandler(event) {
        this.fieldWrapper.value = event.detail.value;
    }
    personalisedFieldTypeChangeHandler(event) {
        this.fieldWrapper.stringFieldType = event.detail.value;
    }
    personalisedActionChangeHandler(event) {
        this.fieldWrapper.action = event.detail.value;
    }
    personalisedRerenderChangeHandler(event) {
        this.fieldWrapper.rerender = event.detail.value;
    }
    handleIsInputFieldChange(event) {
        this.fieldWrapper.isInputField = event.target.checked;
        if (!this.fieldWrapper.isInputField) {
            this.fieldWrapper.isMassUpdate = false;
        }
    }
    // Handle Formula Changes
    handleFormulaChange(event) {
        const field = event.target.dataset.field;
        const newValue = event.detail.value;
        this.fieldWrapper[field] = newValue.trim();
        if (field == 'fieldLabel') {
            this.fieldWrapper.label = newValue.trim();
        }
    }
    handleInternallyCalculatedFieldChange(event) {
        var fieldsWrapperList;
        this.fieldWrapper.internallyCalculated = event.target.checked;
        if (this.fieldWrapper.internallyCalculated) {
            this.fieldWrapper.isMassUpdate = false;
            this.defaultValue = null;
            this.defaultExpression = null;
            this.defaultType = null;
        }
        fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        for (let index = 0; index < fieldsWrapperList.length; index++) {
            fieldsWrapperList[index].internallyCalculated = this.fieldWrapper.internallyCalculated;
        }
        this.fieldswrapperjson = JSON.stringify(fieldsWrapperList);
    }
    handleIsHiddenFieldChange(event) {
        this.fieldWrapper.isHidden = event.target.checked;
    }
    handleisNotExportableFieldChange(event) {
        this.fieldWrapper.isNotExportable = event.target.checked;
    }
    handleIsSortableFieldChange(event) {
        this.fieldWrapper.isSortable = event.target.checked;
    }
    handleIsMassUpdateFieldChange(event) {
        this.fieldWrapper.isMassUpdate = event.target.checked;
    }
    handleClearOnCloneChange(event) {
        this.fieldWrapper.clearOnClone = event.target.checked;
    }
    genericChangeHandlerSeperator(event) {
        let name = event.currentTarget.dataset.name;
        let value = event.detail.value;
        this.fieldWrapper.separatorSettings[name] = value;
    }
    // customJSChangeHandler(event) {
    //     let value = event.detail.value;
    //     this.fieldWrapper.customJS = value;
    // }
    handlehasConditionalFormatingChange(event) {
        var fieldsWrapperList;
        this.fieldWrapper.hasConditionalFormating = event.target.checked;
        fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        for (let index = 0; index < fieldsWrapperList.length; index++) {
            fieldsWrapperList[index].hasConditionalFormating = this.fieldWrapper.hasConditionalFormating;
        }
        this.fieldswrapperjson = JSON.stringify(fieldsWrapperList);
    }
    handleshowInTotalChange(event) {
        var fieldsWrapperList;
        this.fieldWrapper.showInTotal = event.target.checked;
        if (event.target.checked && this.totalTypeOptions.length > 0 && !this.fieldWrapper.totalType) {
            this.fieldWrapper.totalType = this.totalTypeOptions[0].value;
        }
        fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        for (let index = 0; index < fieldsWrapperList.length; index++) {
            fieldsWrapperList[index].showInTotal = this.fieldWrapper.showInTotal;
        }
        this.fieldswrapperjson = JSON.stringify(fieldsWrapperList);
    }
    handleChangeScale(event) {
        this.fieldWrapper.scale = event.detail.value;
    }
    handleHasInputFileChange(event) {
        this.fieldWrapper.hasFileInput = event.target.checked;
    }
    handleDisplayFullURLChanged(event) {
        //this.fieldWrapper.displayFullURL = event.target.checked;
        this.fieldWrapper.replaceURLWith = '';
        this.fieldWrapper.URLOption = event.target.value;
        this.displayFullURL = this.fieldWrapper.URLOption == 'FullURL';
        this.replaceWithText = this.fieldWrapper.URLOption == 'TextReplace';
        this.replaceWithIcon = this.fieldWrapper.URLOption == 'IconReplace';
    }
    handleReplaceURLWithChanged(event) {
        this.fieldWrapper.replaceURLWith = event.target.value;
    }
    handleOperationChange(event) {
        this.operation = event.detail.value;
        this.currentRule.operation = this.operation
        if (this.operation == 'ISNULL') {
            this.showInputOne = false;
            this.showInputTwo = false;
            this.value1 = '';
            this.value2 = '';
        } else if (this.operation == 'ISBLANK') {
            this.showInputOne = false;
            this.showInputTwo = false;
            this.value1 = '';
            this.value2 = '';
            delete this.currentRule.value1;
            delete this.currentRule.value2;
        } else if (this.operation != 'BETWEEN') {
            this.showInputOne = true;
            this.showInputTwo = false;
            this.value2 = '';
            delete this.currentRule.value2;
            this.currentRule.displayValue = this.value1;
        } else {
            this.showInputOne = false;
            this.showInputTwo = true;
        }
    }
    handleTotalTypeChange(event) {
        this.fieldWrapper.totalType = event.detail.value;
    }
    handleFormatRuleValuechange(event) {
        this[event.currentTarget.dataset.recordid] = event.detail.value;
        if (this.picklistvaluesMap.hasOwnProperty(this.value1)) {
            this.currentRule.displayValue = this.picklistvaluesMap[this.value1];
        } else {
            this.currentRule.displayValue = this.value1;
            if (this.value2 && this.value2 != '') {
                this.currentRule.displayValue += ' ' + this.Label.LBL_And + ' ' + this.value2;
            }
        }
        this.currentRule[event.currentTarget.dataset.recordid] = this[event.currentTarget.dataset.recordid];
    }
    handleFormatRuleStylechange(event) {
        this.formatingRuleStyle = JSON.parse(event.detail.value);
        this.currentRule.style = this.formatingRuleStyle;
        ////this.showformatingRuleStyleEdit = false;
    }
    handleFormatRuleOppositeStylechange(event) {
        this.formatingRuleOppositeStyle = JSON.parse(event.detail.value);
        ////this.fieldWrapper.formattingRulesList[this.edittingIndex].oppositeStyle = this.formatingRuleOppositeStyle;
        this.currentRule.oppositeStyle = this.formatingRuleOppositeStyle;
        ////this.showformatingRuleOppositeStyleEdit = false;
    }
    handlenonConditionalchange(event) {
        let fieldStyle = JSON.parse(event.detail.value);
        if (!this.fieldWrapper.nonConditional) {
            this.fieldWrapper.nonConditional = {};
        }
        this.fieldWrapper.nonConditional.style = fieldStyle.style;
        this.fieldWrapper.nonConditional.textStyle = fieldStyle.textStyle;
        this.fieldWrapper.nonConditional.borderStyle = fieldStyle.borderStyle;
        this.fieldWrapper.nonConditional.bgColor = fieldStyle.bgColor;
        this.fieldWrapper.nonConditional.widthStyle = fieldStyle.width;
        this.fieldWrapper.nonConditional.width = fieldStyle.width;
        this.fieldWrapper.nonConditional.isAdvanced = fieldStyle.isAdvanced;
        this.fieldWrapper.nonConditional.advancedStyle = fieldStyle.advancedStyle;
        this.fieldWrapper.newLabel = fieldStyle.newLabel;
        if (fieldStyle.hasOwnProperty('textStyle') && fieldStyle.textStyle) {
            this.fieldWrapper.nonConditional.textStyle.isItalic = fieldStyle.textStyle.isItalic;
            this.fieldWrapper.nonConditional.textStyle.isCenter = fieldStyle.textStyle.isCenter;
            this.fieldWrapper.nonConditional.textStyle.isUnderLine = fieldStyle.textStyle.isUnderLine;
            this.fieldWrapper.nonConditional.textStyle.isStrikeThrought = fieldStyle.textStyle.isStrikeThrought;
            this.fieldWrapper.nonConditional.textStyle.color = fieldStyle.textStyle.color;
            this.fieldWrapper.nonConditional.textStyle.size = fieldStyle.textStyle.size;
            this.fieldWrapper.nonConditional.textStyle.align = fieldStyle.textStyle.align;
            this.fieldWrapper.nonConditional.textStyle.isBold = fieldStyle.textStyle.isBold;
        }
        if (fieldStyle.hasOwnProperty('borderStyle') && fieldStyle.borderStyle) {
            this.fieldWrapper.nonConditional.borderStyle.size = fieldStyle.borderStyle.size;
            this.fieldWrapper.nonConditional.borderStyle.pattern = fieldStyle.borderStyle.pattern;
            this.fieldWrapper.nonConditional.borderStyle.color = fieldStyle.borderStyle.color;
        }
        ///this.shownonConditioalEdit = false;
    }
    mergeNonConditionalStyles(existingStyle, incomingStyle) {
        const base = existingStyle ? JSON.parse(JSON.stringify(existingStyle)) : {};
        if (!incomingStyle) return base;
        const incoming = JSON.parse(JSON.stringify(incomingStyle));
        const pick = (obj, key) => (obj && obj[key] !== undefined && obj[key] !== '' ? obj[key] : undefined);
        base.textStyle = { ...(base.textStyle || {}), ...(incoming.textStyle || {}) };
        const existingBorder = base.borderStyle || {};
        const incomingBorder = incoming.borderStyle || {};
        base.borderStyle = {
            ...existingBorder,
            ...(pick(incomingBorder, 'color') ? { color: incomingBorder.color } : {}),
            ...(pick(incomingBorder, 'pattern') ? { pattern: incomingBorder.pattern } : {}),
            ...(pick(incomingBorder, 'size') ? { size: incomingBorder.size } : {}),
        };
        if (pick(incoming, 'bgColor')) base.bgColor = incoming.bgColor;
        if (pick(incoming, 'width')) base.width = incoming.width;
        if (pick(incoming, 'widthStyle')) base.widthStyle = incoming.widthStyle;
        if (incoming.isAdvanced !== undefined) base.isAdvanced = incoming.isAdvanced;
        if (pick(incoming, 'advancedStyle')) base.advancedStyle = incoming.advancedStyle;
        if (pick(incoming, 'style')) base.style = incoming.style;
        return base;
    }
    mergeHeaderStyles(existingHeaderStyle, incomingHeaderStyle) {
        const base = existingHeaderStyle ? JSON.parse(JSON.stringify(existingHeaderStyle)) : {};
        if (!incomingHeaderStyle) return base;
        const incoming = JSON.parse(JSON.stringify(incomingHeaderStyle));
        const pick = (obj, key) => (obj && obj[key] !== undefined && obj[key] !== '' ? obj[key] : undefined);
        if (pick(incoming, 'bgColor')) base.bgColor = incoming.bgColor;
        if (pick(incoming, 'color')) base.color = incoming.color;
        let content = '';
        content += base.bgColor ? 'background-color: ' + base.bgColor + ';' : '';
        content += base.color ? 'color: ' + base.color + ';' : '';
        base.style = content;
        return base;
    }
    handleDeleteFormatingRule(event) {
        var self = this;
        var index = event.currentTarget.dataset.recordid;
        var temp = this.fieldWrapper.formattingRulesList;
        temp.splice(index, 1);
        this.fieldWrapper.formattingRulesList = JSON.parse(JSON.stringify(temp));
        this.fieldWrapper.isBooleanWithOneFormatingRuleStyle = self.fieldWrapper.isBoolean && self.fieldWrapper.formattingRulesList && self.fieldWrapper.formattingRulesList.length > 0;
    }
    handleEditFormatingRule(event) {
        var edittingIndex = event.currentTarget.dataset.recordid;
        var rule = JSON.parse(JSON.stringify(this.fieldWrapper.formattingRulesList[edittingIndex]));
        this.currentRule = rule;
        this.editting = true;
        this.edittingIndex = edittingIndex;
        this.operation = rule.operation;
        this.formatingRuleStyle = rule.style;
        this.formatingRuleOppositeStyle = rule.oppositeStyle;
        this.value1 = rule.value1;
        this.value2 = rule.value2;
        if (this.operation == 'ISNULL') {
            this.showInputOne = false;
            this.showInputTwo = false;
            this.value1 = '';
            this.value2 = '';
        } else if (this.operation == 'ISBLANK') {
            this.showInputOne = false;
            this.showInputTwo = false;
            this.value1 = '';
            this.value2 = '';
            this.currentRule.value1;
            this.currentRule.value2;
        } else if (this.operation != 'BETWEEN') {
            this.showInputOne = true;
            this.showInputTwo = false;
            this.value2 = '';
            this.currentRule.displayValue = this.value1;
        } else {
            this.showInputOne = false;
            this.showInputTwo = true;
        }
    }
    /*
        handleToggleFormatingRuleStyle(event) {
            var skipIndex = event.currentTarget.dataset.recordid;
            var index;
            this.fieldWrapper.formattingRulesList[skipIndex].showStyle = !this.fieldWrapper.formattingRulesList[skipIndex].showStyle;
            for (index = 0; index < this.fieldWrapper.formattingRulesList.length; index++) {
                if (index != skipIndex) {
                    this.fieldWrapper.formattingRulesList[index].showStyle = false;
                }
            }
        }*/
    handleAddFormatingRule() {
        //this.handleEditFormatingRule = true;
        var edittingIndex;
        var rule = {};
        this.currentRule = rule;
        if (!this.fieldWrapper.formattingRulesList) {
            this.fieldWrapper.formattingRulesList = [];
        }
        edittingIndex = this.fieldWrapper.formattingRulesList.length;
        this.edittingIndex = edittingIndex;
        this.operation = rule.operation || '';
        this.formatingRuleStyle = rule.style || '';
        this.formatingRuleOppositeStyle = rule.oppositeStyle || '';
        this.value1 = rule.value1 || '';
        this.value2 = rule.value2 || '';
        if (this.operation == 'ISBLANK') {
            this.showInputOne = false;
            this.showInputTwo = false;
            this.value1 = '';
            this.value2 = '';
            delete this.currentRule.value1;
            delete this.currentRule.value2;
        } else if (this.operation != 'BETWEEN') {
            this.showInputOne = true;
            this.showInputTwo = false;
            this.value2 = '';
            delete this.currentRule.value2;
            this.currentRule.displayValue = this.value1;
        } else {
            this.showInputOne = false;
            this.showInputTwo = true;
        }
        this.fieldWrapper.isBooleanWithOneFormatingRuleStyle = this.fieldWrapper.isBoolean && this.fieldWrapper.formattingRulesList && this.fieldWrapper.formattingRulesList.length > 0;
        this.editting = true;
    }
    handleCancelFormatingRule() {
        this.fieldWrapper.isBooleanWithOneFormatingRuleStyle = this.fieldWrapper.isBoolean && this.fieldWrapper.formattingRulesList && this.fieldWrapper.formattingRulesList.length > 0;
        this.operation = undefined;
        this.formatingRuleStyle = undefined;
        this.formatingRuleOppositeStyle = undefined;
        this.value1 = undefined;
        this.value2 = undefined;
        this.showInputOne = false;
        this.showInputTwo = false;
        this.edittingIndex = null;
        this.currentRule = undefined;
        this.editting = false;
    }
    handleSaveFormatingRule() {
        if (!this.operation || (this.operation != 'ISBLANK' && this.operation != 'ISNULL' && !this.value1) || (this.operation == 'BETWEEN' && (!this.value1 || !this.value2))) {
            toastInfo(this, this.Label.MSG_Fill_Required_Fields);
            return;
        }
        if (this.value1 && this.showInputTwo && this.value2 && Number(this.value1) >= Number(this.value2)) {
            toastError(this, this.Label.MSG_Between_Value_Error);
            return;
        }
        if (this.defaultValue == null || this.defaultValue == '') {
            this.defaultType = null;
        }
        if (this.defaultExpression == null || this.defaultExpression == '') {
            this.defaultExpression = null;
        }
        if (this.currentRule) {
            this.currentRule.stylePreview = '' + (this.currentRule.style && this.currentRule.style.style ? this.Label.LBL_Style + '\n' + this.currentRule.style.style : '') + (this.currentRule.oppositeStyle && this.currentRule.oppositeStyle.style ? this.Label.LBL_Opposite_Style + '\n' + this.currentRule.oppositeStyle.style : '');
            if ((this.edittingIndex == 0 || this.edittingIndex) && this.fieldWrapper && this.fieldWrapper.formattingRulesList && this.edittingIndex == this.fieldWrapper.formattingRulesList.length) {
                this.fieldWrapper.formattingRulesList.push(this.currentRule);
            } else if ((this.edittingIndex == 0 || this.edittingIndex) && this.fieldWrapper && this.fieldWrapper.formattingRulesList) {
                this.fieldWrapper.formattingRulesList[this.edittingIndex] = this.currentRule;
            }
            this.fieldWrapper.formattingRulesList = JSON.parse(JSON.stringify(this.fieldWrapper.formattingRulesList));
        }
        this.fieldWrapper.isBooleanWithOneFormatingRuleStyle = this.fieldWrapper.isBoolean && this.fieldWrapper.formattingRulesList && this.fieldWrapper.formattingRulesList.length > 0;
        this.operation = undefined;
        this.formatingRuleStyle = undefined;
        this.formatingRuleOppositeStyle = undefined;
        this.value1 = undefined;
        this.value2 = undefined;
        this.showInputOne = false;
        this.showInputTwo = false;
        this.edittingIndex = null;
        this.editting = false;
        this.currentRule = undefined;
    }
    get fieldsWrapperJSONDetail() {
        var fieldWrapper = this.fieldWrapper;
        var fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        if (this.editting) {
            this.handleSaveFormatingRule();
        }
        fieldWrapper.picklistColorsMap = {};
        if (this.picklistColorsList) {
            this.picklistColorsList.forEach(item => {
                fieldWrapper.picklistColorsMap[item.value] = item.color || '';
            });
        }
        if (fieldWrapper.isMultiple) {
            for (let index1 = 0; index1 < fieldsWrapperList.length; index1++) {
                fieldsWrapperList[index1].isInputField = fieldWrapper.isInputField ? fieldWrapper.isInputField : fieldsWrapperList[index1].isInputField;
                fieldsWrapperList[index1].newLabel = fieldWrapper.newLabel; //__
                fieldsWrapperList[index1].showInTotal = fieldWrapper.showInTotal ? fieldWrapper.showInTotal : fieldsWrapperList[index1].showInTotal;
                fieldsWrapperList[index1].internallyCalculated = fieldWrapper.internallyCalculated ? fieldWrapper.internallyCalculated : fieldsWrapperList[index1].internallyCalculated;
                fieldsWrapperList[index1].totalType = fieldWrapper.totalType ? fieldWrapper.totalType : fieldsWrapperList[index1].totalType;
                fieldsWrapperList[index1].nonConditional = this.mergeNonConditionalStyles(fieldsWrapperList[index1].nonConditional, fieldWrapper.nonConditional);
                fieldsWrapperList[index1].headerStyle = this.mergeHeaderStyles(fieldsWrapperList[index1].headerStyle, fieldWrapper.headerStyle);
            }
            return JSON.stringify(fieldsWrapperList);
        } else {
            fieldWrapper.scale = fieldWrapper.scale != '' ? fieldWrapper.scale : 0;
            fieldWrapper.defaultValue = this.defaultValue;
            fieldWrapper.defaultType = this.defaultType ? this.defaultType : null;
            fieldWrapper.defaultExpression = this.defaultExpression ? this.defaultExpression : null;
            fieldWrapper.conditionalRules = this.conditionalRules ? this.conditionalRules : null;
        }
        if (fieldWrapper.hasConditionalFormating && fieldWrapper.formattingRulesList && fieldWrapper.formattingRulesList.length > 0) {
            ////delete (fieldWrapper.nonConditional);
            let isOneFieldEmpty = fieldWrapper.formattingRulesList.some(item => (!item.operation || (item.operation != 'ISBLANK' && item.operation != 'ISNULL' && !item.value1)) || (item.operation == 'BETWEEN' && (!item.value1 || !item.value2)));
            if (isOneFieldEmpty) {
                toastInfo(this, this.Label.MSG_Fill_Required_Fields);
                return JSON.stringify([]);
            }
            fieldWrapper.formattingRulesList.forEach(item => {
                delete (item.displayValue);
            });
        } else {
            delete (fieldWrapper.hasConditionalFormating);
            delete (fieldWrapper.formattingRulesList);
        }
        return JSON.stringify([fieldWrapper]);
    }
    get defaultExpressionPlaceHolder() {
        if (this.fieldWrapper.isNumber) {
            return '{!field1__c} + {!field2__c} - {!field3__c} * {!field4__c} / {!field5__c}';
        } else if (this.fieldWrapper.isText) {
            return '{!field1__c} + {!field2__c}';
        }
    }
    get isTextPredefinedValue() {
        return (this.fieldWrapper.isText && !this.fieldWrapper.isPicklist && !this.fieldWrapper.isMultiPicklist);
    }
    get defaultValuesOptions() {
        let options = [];
        options.push({ label: this.Label.LBL_Predefined_Value, value: 'text' });
        if (this.fieldWrapper.isNumber || (this.fieldWrapper.isText && !this.fieldWrapper.isPicklist && !this.fieldWrapper.isMultiPicklist)) {
            options.push({ label: this.Label.LBL_Expression, value: 'expression' });
        }
        options.push({ label: this.Label.LBL_Dependant_On_Another_Field, value: 'current' });
        if (this.relationshipname) {
            options.push({ label: this.Label.LBL_Dependant_On_Field_From_Relation, value: 'master' });
        }
        return options;
    }
    get isDefaultText() {
        return this.defaultType == 'text';
    }
    get isFieldRef() {
        let selectedField = JSON.parse(this.fieldswrapperjson)[0];
        return selectedField.fieldType == 'REFERENCE';
    }
    get isDefaultCurrent() {
        return this.defaultType == 'current';
    }
    get isDefaultExpression() {
        return this.defaultType == 'expression';
    }
    get isDefaultParent() {
        return this.defaultType == 'master';
    }
    handleChangeDefaultValueType(event) {
        this.defaultValue = '';
        this.defaultExpression = '';
        this.defaultType = event.detail.value;
    }
    handleChangeDefaultField(event) {
        this.defaultValue = event.detail.value;
    }
    handleChangeExpressionField(event) {
        this.defaultExpression = event.detail.value;
    }
    get matchingRefObjectFields() {
        let selectedField = JSON.parse(this.fieldswrapperjson)[0];
        let options = [];
        for (let item of this.refobjectfields) {
            if (item.type == selectedField.fieldType && !item.label.includes('>')) {
                options.push(item);
            }
        }
        options.unshift({ label: '--None--', value: '' });
        return options;
    }
    get matchingObjectFields() {
        let selectedField = JSON.parse(this.fieldswrapperjson)[0];
        let options = [];
        for (let item of this.objectfields) {
            if (item.type == selectedField.fieldType && !item.label.includes('>') && item.value != selectedField.value) {
                options.push(item);
            }
        }
        options.unshift({ label: '--None--', value: '' });
        return options;
    }
    get hasDefaultValue() {
        try {
            let selectedField = JSON.parse(this.fieldswrapperjson)[0];
            return !selectedField.isMultiple && !selectedField.value.includes('.') && this.fieldWrapper.isCreateable && this.fieldWrapper.isUpdateable && !this.fieldWrapper.internallyCalculated;
        } catch (error) {
        }
        return false;
    }
    controlOptionsChange(event) {
        this.displayControleMessage = event.detail.value.includes('_MESSAGE');
    }
    closeExternalCriteriaExpressionEditor(event) {

    }
    confirmExternalCriteriaExpressionEditor(event) {
        let externalCriteriasJSON = event.detail.value;
        this.currentExternalCriteria = JSON.parse(externalCriteriasJSON);
        this.externalCriteriaHasError = event.detail.hasError;
        this.externalCriteriasJSON = externalCriteriasJSON;
    }
    handleSaveControl(event) {
        if (this.externalCriteriaHasError) return;
        let currentExternalCriteria = JSON.parse(JSON.stringify(this.currentExternalCriteria));
        let controlActionType = this.template.querySelector(".controlActionType");
        let controlActionName = this.template.querySelector(".controlActionName");
        let message = this.template.querySelector(".message");
        if (!this.conditionalRules) this.conditionalRules = [];
        if (controlActionType && controlActionType.value && controlActionName && controlActionName.value) {
            let newControl = {
                description: controlActionName.value,
                criteria: currentExternalCriteria,
                action: controlActionType.value,
                message: message && message.value ? message.value : undefined,
                get criteriasList() {
                    let listRules = [];
                    let self = this;
                    for (var key of Object.keys(this.criteria.rulesMap).sort((i1, i2) => i1 - i2)) {
                        listRules.push({
                            fieldName: self.criteria.rulesMap[key].fieldName,
                            operation: self.criteria.rulesMap[key].operation,
                            value: self.criteria.rulesMap[key].value,
                        });
                    }
                    return listRules;
                }
            };
            this.conditionalRules.push(newControl);
            controlActionType.value = "";
            controlActionName.value = "";
            if (message) {
                message.value = "";
            }
            this.currentExternalCriteria.rulesMap = {};
            this.currentExternalCriteria.expression = '1';
            this.externalCriteriasJSON = JSON.stringify(this.currentExternalCriteria);
            let gridSettingsExpressionEditorComp = this.template.querySelector("[data-comp='externalCriteriaExpressionEditor']");
            if (gridSettingsExpressionEditorComp) {
                gridSettingsExpressionEditorComp.updateFields(this.externalCriteriasJSON);
            }
            toastSuccess(this, null, 'Controle added');
        }
    }
    headerBackgroundColorChangeHandler(event) {
        this.fieldWrapper.headerStyle.bgColor = event.detail.value;
        this.refreshStyleValue();
    }
    headerColorChangeHandler(event) {
        this.fieldWrapper.headerStyle.color = event.detail.value;
        this.refreshStyleValue();
    }
    refreshStyleValue() {
        let fieldStyle = this.fieldWrapper.headerStyle;
        let content = '';
        let bgColor = fieldStyle.bgColor;
        let color = fieldStyle.color;
        content += bgColor ? 'background-color: ' + bgColor + ';' : '';
        content += color ? 'color: ' + color + ';' : '';
        this.fieldWrapper.headerStyle.style = content;
    }
    handleNewLabelChange(event) {
        this.fieldWrapper.newLabel = event.detail.value;
        let fieldsWrapperList = JSON.parse(this.fieldswrapperjson);
        for (let index = 0; index < fieldsWrapperList.length; index++) {
            fieldsWrapperList[index].newLabel = event.detail.value;
        }
        this.fieldswrapperjson = JSON.stringify(fieldsWrapperList);
    }
}