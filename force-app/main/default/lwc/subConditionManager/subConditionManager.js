import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { API_NAMES, SubDiscountWrapper, Labels } from './services.js';
import getAvailableSubPCCs from '@salesforce/apex/ConditionManagerCmpController.getAvailableSubPCCs';
import loadGridSettings from '@salesforce/apex/ConditionManagerCmpController.loadGridSettings';
const ERROR_VARIANT = 'error';
const WARNING_VARIANT = 'warning';
const calculationFields = [API_NAMES.Contract_Discount__c.Value_amt__c, API_NAMES.Contract_Discount__c.Value_per__c];
export default class ConditionListLWCSubdiscounts extends LightningElement {
    @track API_NAMES = API_NAMES;
    @track calculationFields;
    /**
     * Wires
     */
    // @api labels = Labels;
    @api labels;
    @api isReadOnly;
    @api discountPercentScale;
    @api parentDisc; // Parent discount for popup title
    @api gridSettings;
    @track displayedField = [];
    @track BUSearch = '';
    @track isRequired = false;
    @track buScopeList = [];
    @track showBUSelection = false;
    @track BUForSelection = [];
    @track isHandleChangeBU = false;
    @track currentSubDiscountIndex = null; // Track which subdiscount is being edited
    // Nego Scope Selection properties
    @track showNegoScopeSelection = false;
    @track negoScopeForSelection = [];
    @track negoScopeSearch = '';
    // Sub PCC Selection properties
    @track showSubPCCSelection = false;
    @track availableSubPCCs = [];
    @track selectedSubPCCs = [];
    @track subPCCSearch = '';
    @track gridSettings = null; // GridSettingsManager object with GRID_FIELDS configuration
    @track gridFieldsConfig = []; // Extracted grid field names for quick lookup

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    connectedCallback() {
        this.loadGridConfiguration();
        window.addEventListener('keyup', (event) => {
            let popups = this.popups;
            if (event.keyCode === 27) {
                Object.keys(popups).forEach(key => this.popups[key].isOpen = false);
            }
        });
    }

    // Builds the grid column definitions (displayed fields) from Apex data.
    @api buildDisplayedFields(subDiscounts_JSON) {
        try {
            this.displayedFields = [];
            for (let field of this.gridSettings.GRID_FIELDS) {
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel.toUpperCase(),
                    fieldType: field.fieldType,
                    isNumberField: field.isNumberField,
                    isReference: field.fieldType == 'REFERENCE',
                    isDate: field.fieldType == 'DATE',
                    isDateTime: field.fieldType == 'DATETIME',
                    isPicklist: field.fieldType == 'PICKLIST',
                    isBoolean: field.fieldType == 'BOOLEAN',
                    isTextarea: field.fieldType == 'TEXTAREA',
                    link: '',
                    scale: field.scale,
                    step: '',
                    isInputField: field.isInputField,
                    style: field.style,
                    headerStyle: field.stringHeaderStyle,
                    pickListValues: field.pickListValues,
                    isSortable: field.isSortable,
                    isFilterable: field.isFilterable,
                    isEncrypted: field.isEncrypted,
                    filterValue: '',
                    sortedField: false,
                    picklistColorsMap: field.picklistColorsMap,
                }
                fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextarea;
                // Flag BU Scope and Nego Scope fields for custom popup handling (not standard lookups)
                fieldWrapper.isBUScope = field.fieldName === 'BusinessUnitScope__c';
                fieldWrapper.isNegoScope = field.fieldName === 'Product_Scope__c';
                if (fieldWrapper.isNumberField) {
                    fieldWrapper.style += 'text-align:right;';
                }
                if (fieldWrapper.scale) {
                    let step = '.';
                    for (let i = 0; i < fieldWrapper.scale; i++) {
                        if (i == fieldWrapper.scale - 1) {
                            step += '1';
                            break;
                        }
                        step += '0';
                    }
                    fieldWrapper.step = step;
                }
                this.displayedFields.push(fieldWrapper);
            }
            this.buildData(subDiscounts_JSON);
        } catch (error) {
            this.showError(error.body?.message || error.message || 'Error in buildDisplayedFields');
            console.log('buildDisplayedFields: %c' + error.message, 'color : red');
            console.log('buildDisplayedFields: %c' + error.body?.message, 'color : red');
        }
    }

    // Builds and formats the data rows for the grid display.
    buildData(subDiscounts_JSON) {
        let data = JSON.parse(subDiscounts_JSON);
        try {
            console.log('this.displayedFields >>>  + ' + JSON.stringify(this.displayedFields))
            let records = [];
            for (let item of data) {
                let conditionWrapper = {
                    Name: item.Name,
                    Id: item.Id,
                    link: '/' + item.Id,
                    values: [],
                    // Preserve discount-level properties
                    isDraft: item.isDraft || (!item.Id),
                    isBlocked: item.isBlocked || false,
                    isValidSubCondition: item.isValidSubCondition !== false,
                    isSelected: item.isSelected !== false,
                    discount: item.discount,
                    // Compute row class based on state
                    get rowClass() {
                        if (!this.isValidSubCondition) {
                            return 'invalid-row';
                        }
                        if (this.isBlocked) {
                            return 'blocked-row';
                        }
                        if (this.isDraft || !this.Id) {
                            return 'draft-row';
                        }
                        return '';
                    }
                }
                let fieldIndex = 0;
                for (let field of this.displayedFields) {
                    let fieldWrapper = {
                        Id: item.Id,
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
                        scale: field.scale,
                        step: field.step,
                        isInputField: field.isInputField,
                        pickListValues: [],
                        style: (field.style ? field.style : '') + 'word-wrap: break-word;',
                        isFirstField: fieldIndex === 0,
                        // Flag BU Scope and Nego Scope for popup handling
                        isBUScope: field.fieldName === 'BusinessUnitScope__c',
                        isNegoScope: field.fieldName === 'Product_Scope__c',
                    }
                    fieldIndex++;
                    let values = field.fieldName.split('.');
                    for (let index = 0; index < values.length; index++) {
                        let val = index == 0 ? item : fieldWrapper.fieldValue;
                        if (val) {
                            if (index == values.length - 1 && fieldWrapper.isReference) {
                                fieldWrapper.fieldOutputValue = val[values[index].replace(/__c$/, '__r').replace(/Id$/, '')]?.Name;
                                fieldWrapper.link = fieldWrapper.fieldName.endsWith('RecordTypeId') ? null : '/' + val[values[index]];
                            } else {
                                fieldWrapper.fieldOutputValue = val[values[index]];
                            }
                            fieldWrapper.fieldValue = val[values[index]];
                        }
                    }
                    if (fieldWrapper.isPicklist) {
                        for (let pickVal of field.pickListValues) {
                            fieldWrapper.pickListValues.push({ label: pickVal.label, value: pickVal.value, isSelected: fieldWrapper.fieldValue == pickVal.value });
                            if (fieldWrapper.fieldValue == pickVal.value) {
                                fieldWrapper.fieldOutputValue = pickVal.label;
                            }
                        }
                        fieldWrapper.pickListValues.unshift({
                            label: '--None--', value: '', isSelected: fieldWrapper.fieldValue == ''
                        })
                    }
                    conditionWrapper.values.push(fieldWrapper);
                }
                records.push(conditionWrapper);
            }
            this.isLoading = false;
            this.subdiscountlist = records;
        } catch (error) {
            this.showError(error.body?.message || error.message || 'Error in buildData');
            console.log('buildData: %c' + error.message, 'color : red');
            console.log('buildData: %c' + error.body?.message, 'color : red');
        }
    }

    async loadGridConfiguration() {
        try {
            if (!this.currentjsdiscountwrapper?.contract?.Id) {
                console.log('SubConditionManager: Waiting for contract data before loading grid settings');
                return;
            }
            // Load GridSettingsManager for the subdiscount grid template
            const result = await loadGridSettings({
                contractId: this.currentjsdiscountwrapper.contract.Id,
                contract_JSON: JSON.stringify(this.currentjsdiscountwrapper.contract)
            });

            if (result) {
                const data = JSON.parse(result);
                this.gridSettings = data.gridSettings;
                // Extract field names from GRID_FIELDS for quick lookup
                if (this.gridSettings && this.gridSettings.GRID_FIELDS) {
                    this.gridFieldsConfig = this.gridSettings.GRID_FIELDS.map(field => field.fieldName);
                    console.log('SubConditionManager: Loaded grid configuration with fields:', this.gridFieldsConfig);
                } else {
                    console.warn('SubConditionManager: No GRID_FIELDS found in gridSettings');
                    this.gridFieldsConfig = [];
                }
            }
        } catch (error) {
            console.error('Error loading grid configuration:', error);
            // Fall back to showing all columns if configuration fails
            this.gridFieldsConfig = [];
        }
    }

    renderedCallback() {
    }

    @api
    reloadGridConfiguration() {
        this.loadGridConfiguration();
    }

    get discPercentStep() {
        if (this.discountPercentScale) {
            let step = '.';
            for (let i = 0; i < this.discountPercentScale; i++) {
                if (i == this.discountPercentScale - 1) {
                    step += '1';
                    break;
                }
                step += '0';
            }
            return step;
        }
    }
    /**
    * Variables
    */
    // Public
    @api tableheader = null;
    @api conditionpage = null;
    @api bu = [];
    @api negoscopes = [];
    @api currentjsdiscountwrapper;
    @api pageSettings = {
        mainGridSettings: 'Condition_Grid',
        subDiscountGridSettings: '',
        showSubDiscountColumn: false
    };
    @api setPercentAndAmount(percent, amount) {
        try {
            this.totalValues.percent = +(percent.toFixed(this.discountPercentScale));
            this.totalValues.amount = +(amount);
            if (this.subdiscountlist.length > 0) {
                this.calculateSubs();
            } else {
                this.calculationStatus.amount = 0;
                this.calculationStatus.percent = 0;
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    get hasData() {
        return this.subdiscountlist && this.subdiscountlist.length > 0;
    }
    @api setSubdiscounts(subDiscounts_JSON) {
        try {
            let subdiscountlistResponse = JSON.parse(subDiscounts_JSON);
            for (let subWrapperIndex in subdiscountlistResponse) {
                let subWrapper = subdiscountlistResponse[subWrapperIndex];
                // if (subWrapper.isSelected == false) {
                //     // this.messages.subDiscountChecked = 'the sub discount must be checked';
                //     this.messages.subDiscountChecked = Labels.MSG_Checked_Subdiscount;
                //     this.showWarning(this.messages.subDiscountChecked);
                // }
                if (subWrapper.discount[API_NAMES.Contract_Discount__c.all_BU__c] == true) {
                    subWrapper.isCheckedAllBU = true;
                } else {
                    subWrapper.isCheckedAllBU = false;
                }
                if (subWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r][API_NAMES.Pol_Com_Condition__c.Is_Contract_Unicity_Requiered__c]) {
                    subWrapper.unicityRequired = true;
                } else {
                    subWrapper.unicityRequired = false;
                }
                Object.defineProperties(subWrapper, {
                    index: {
                        value: subWrapperIndex
                    },
                    hasBUScope: {
                        get: () => {
                            return subWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] != null;
                        }
                    },
                    buScopeLink: {
                        get: () => {
                            return '/' + subWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c];
                        }
                    },
                    getIsSelected: {
                        get: () => {
                            return '/' + subWrapper.isSelected;
                        }
                    },
                    getKey: {
                        get: () => {
                            return `${subWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]}-${subWrapper.index}`;
                        }
                    },
                    getRecordPage: {
                        get: () => {
                            return '/' + subWrapper.discount.Id
                        }
                    },
                    getTariffLink: {
                        get: () => {
                            return '/' + subWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__c]
                        }
                    },
                    getNegoScopeLink: {
                        get: () => {
                            return '/' + subWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__c]
                        }
                    },
                    getEnableSubValues: {
                        get: () => {
                            if (subWrapper.enableSubValues) {
                                return 'slds-text-align_center';
                            } else {
                                return 'slds-text-align_center slds-theme_alert-texture';
                            }
                        }
                    },
                    rowClass: {
                        get: () => {
                            if (!subWrapper.isValidSubCondition) {
                                return 'invalid-row';
                            }
                            if (subWrapper.isBlocked) {
                                return 'blocked-row';
                            }
                            if (subWrapper.isDraft || !subWrapper.discount.Id) {
                                return 'draft-row';
                            }
                            return '';
                        }
                    },
                    color: {
                        get: () => {
                            if (!subWrapper.isValidSubCondition) {
                                return 'background: #F9BBB9';
                            }
                            if (subWrapper.isBlocked) {
                                return 'background: #ececec';
                            }
                            if (subWrapper.discount.Id == null) {
                                return 'background: rgb(250, 255, 189)'
                            }
                            return '';
                        }
                    },
                    discountTerms: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] : '';
                        }
                    },
                    ProofCounterpartyDescription: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] : '';
                        }
                    },
                    allBU: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.all_BU__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.all_BU__c] : '';
                        }
                    },
                    allItems: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.all_items__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.all_items__c] : '';
                        }
                    },
                    valuePer: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Value_per__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.Value_per__c] : '';
                        }
                    },
                    valueAmt: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.Value_amt__c] : '';
                        }
                    },
                    proofCounterPartyTotal: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] ? subWrapper.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c] : '';
                        }
                    },
                    conditionTypeName: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r]?.Name ? subWrapper.discount[API_NAMES.Contract_Discount__c.Condition_Type__r].Name : '';
                        }
                    },
                    productScopeName: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__r]?.Name ? subWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__r].Name : '';
                        }
                    },
                    buScopeName: {
                        get: () => {
                            return subWrapper.discount && subWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r]?.Name ? subWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r].Name : '';
                        }
                    }
                });
            }
            this.hasSubDiscounts = true;
            this.loading = false;
            this.subdiscountlist = subdiscountlistResponse;
            if (this.subdiscountlist.length > 0) {
                this.hasSubDiscounts = true;
            } else {
                this.hasSubDiscounts = false;
            }

            // Load grid configuration if contract is available and not already loaded
            if (this.currentjsdiscountwrapper?.contract?.Id && !this.gridSettings) {
                this.loadGridConfiguration();
            }

            // Load available sub PCCs for adding new sub discounts
            this.loadAvailableSubPCCs();
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }

    loadAvailableSubPCCs() {
        try {
            if (!this.currentjsdiscountwrapper?.discount?.Id) {
                console.warn('No parent discount ID available to load sub PCCs');
                return;
            }

            const parentDiscountId = this.currentjsdiscountwrapper.discount.Id;
            const contractId = this.currentjsdiscountwrapper.discount[API_NAMES.Contract_Discount__c.Contract__c];

            console.log('Loading available sub PCCs for parent discount:', parentDiscountId, 'contract:', contractId);

            getAvailableSubPCCs({
                parentDiscountId: parentDiscountId,
                contractId: contractId
            })
                .then(result => {
                    console.log('Raw Apex result:', result);
                    const parsed = JSON.parse(result);
                    console.log('Parsed available sub PCCs:', parsed);
                    this.availableSubPCCs = parsed;
                    console.log('Available sub PCCs count:', this.availableSubPCCs.length);
                })
                .catch(error => {
                    console.error('Error loading available sub PCCs:', error);
                    console.error('Error details:', JSON.stringify(error));
                    this.showError('Failed to load available sub discounts: ' + (error.body?.message || error.message));
                });
        } catch (error) {
            console.error('Error in loadAvailableSubPCCs:', error);
        }
    }

    @api setLoading(loading) {
        try {
            this.loading = loading;
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    @api declareOverflow(type) {
        try {
            this.calculationStatus[type] = 1;
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    @api declareEquality(type) {
        try {
            this.calculationStatus[type] = 0;
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    @api declareInequality(type) {
        try {
            this.calculationStatus[type] = -1;
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    @api sbusinesstype;
    @api showaspopup;
    @api updatesubdiscount;
    // Private
    @track currentPageReference;
    @track headerLabel;
    @track subdiscountlist;
    @track hasSubDiscounts = false;
    @track loading;
    /**
    * Rich Text
    */
    @track richTextEditedValue;
    @track richTextFieldToEdit;
    /**
    * Rich Text
    */
    @track longTextEditedValue;
    @track longTextFieldToEdit;
    @track subDiscountJSWrapper;
    @track calculations = {
        sumPercent: 0,
        sumAmount: 0,
        remainingPercent: 0,
        remainingAmount: 0
    }
    @track calculationStatus = {
        percent: 0,
        amount: 0
    }
    @track totalValues = {
        percent: 0,
        amount: 0
    }
    fields = {
        'Proof_counterparty_description__c': API_NAMES.Contract_Discount__c.Proof_counterparty_description__c,
        'Discount_Terms__c': API_NAMES.Contract_Discount__c.Discount_Terms__c,
        'all_BU__c': API_NAMES.Contract_Discount__c.all_BU__c,
        'Is_Contract_Unicity_Requiered__c': API_NAMES.Pol_Com_Condition__c.Is_Contract_Unicity_Requiered__c,
        'BusinessUnitScope__c': API_NAMES.Contract_Discount__c.BusinessUnitScope__c,
        'Proof_counterparty_number_total__c': API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c,
        'all_items__c': API_NAMES.Contract_Discount__c.all_items__c,
        'Value_amt__c': API_NAMES.Contract_Discount__c.Value_amt__c,
        'Value_per__c': API_NAMES.Contract_Discount__c.Value_per__c
    }
    messages = {
        amount: '',
        percent: '',
        subDiscountChecked: ''
    }
    /**
    * Getter
    */
    get headersLoaded() {
        try {
            return this.tableheader != null && this.conditionpage != null;
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    // get percentStatus() {
    //     // eslint-disable-next-line default-case
    //     try {
    //         switch (this.calculationStatus.percent) {
    //             /* case -1:
    //             return {
    //             style : 'background-color: var(--lwc-colorBackgroundWarning,rgb(254, 147, 57)); color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //             tdStyle : 'width :6rem;background-color: var(--lwc-colorBackgroundWarning,rgb(254, 147, 57)); color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //             inputStyle : '',
    //             showIcon : true,
    //             icon : 'utility:warning'
    //             } */
    //             case 0:
    //                 return {
    //                     style: 'width :6rem;',
    //                     inputStyle: '',
    //                     showIcon: false,
    //                     icon: ''
    //                 }
    //             default:
    //                 return {
    //                     style: 'color: var(--lwc-colorTextInverse,rgb(255, 255, 255)); background-color: var(--lwc-colorBackgroundToastError,rgb(234, 0, 30));',
    //                     tdStyle: 'width :6rem;color: var(--lwc-colorTextInverse,rgb(255, 255, 255)); background-color: var(--lwc-colorBackgroundToastError,rgb(234, 0, 30));',
    //                     inputStyle: 'color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //                     showIcon: true,
    //                     icon: 'utility:error'
    //                 }
    //         }
    //     } catch (error) {
    //         console.error(error?.body?.message || error?.message || error);
    //         console.error(error);
    //     }Condition Manager Page Configuration
    // }
    // get amountStatus() {
    //     try {
    //         switch (this.calculationStatus.amount) {
    //             /* case -1:
    //             return {
    //             style : 'background-color: var(--lwc-colorBackgroundWarning,rgb(254, 147, 57)); color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //             tdStyle : 'width :6rem;background-color: var(--lwc-colorBackgroundWarning,rgb(254, 147, 57)); color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //             inputStyle : '',
    //             showIcon : true,
    //             icon : 'utility:warning'
    //             } */
    //             case 0:
    //                 return {
    //                     style: 'width :6rem;',
    //                     inputStyle: '',
    //                     showIcon: false,
    //                     icon: ''
    //                 }
    //             default:
    //                 return {
    //                     style: 'color: var(--lwc-colorTextInverse,rgb(255, 255, 255)); background-color: var(--lwc-colorBackgroundToastError,rgb(234, 0, 30));',
    //                     tdStyle: 'width :6rem;color: var(--lwc-colorTextInverse,rgb(255, 255, 255)); background-color: var(--lwc-colorBackgroundToastError,rgb(234, 0, 30));',
    //                     inputStyle: 'color: var(--lwc-colorTextDefault,rgb(24, 24, 24));',
    //                     showIcon: true,
    //                     icon: 'utility:error'
    //                 }
    //         }
    //     } catch (error) {
    //         console.error(error?.body?.message || error?.message || error);
    //         console.error(error);
    //     }
    // }
    /**
    * Methods
    */
    calculateSubs() {
        try {
            let sumPer = 0, sumAmount = 0;
            let hasEnabledSubs = false;
            for (let item of this.subdiscountlist) {
                if (item.isSelected) {
                    sumPer += +(item.discount[API_NAMES.Contract_Discount__c.Value_per__c] || 0);
                    sumAmount += +(item.discount[API_NAMES.Contract_Discount__c.Value_amt__c] || 0);
                }
                if (item.isBlocked || !item.isValidSubCondition) {
                    item.enableSubValues = false;
                }
                if (item.enableSubValues) {
                    item.enableSubValues = true;
                    // hasEnabledSubs = true;
                }
            }
            this.calculations.sumPercent = sumPer;
            this.calculations.sumAmount = sumAmount;
            this.calculations.remainingPercent = +(this.totalValues.percent - sumPer);
            this.calculations.remainingAmount = this.totalValues.amount - sumAmount;
            let percentError, amountError;
            let percentWarning, amountWarning;
            if (hasEnabledSubs) {
                switch (true) {
                    case ((this.calculations.remainingPercent < 0) || (this.calculations.remainingPercent > 0 && this.sbusinesstype != 'CPG')):
                        this.calculationStatus.percent = 1;
                        percentError = true;
                        break;
                    case (this.calculations.remainingPercent > 0):
                        this.calculationStatus.percent = -1;
                        percentWarning = true;
                        break;
                    default:
                        this.calculationStatus.percent = 0;
                        break;
                }
                switch (true) {
                    case (this.calculations.remainingAmount < 0 || (this.calculations.remainingAmount > 0 && this.sbusinesstype != 'CPG')):
                        this.calculationStatus.amount = 1;
                        amountError = true;
                        break;
                    case (this.calculations.remainingAmount > 0):
                        this.calculationStatus.amount = -1;
                        amountWarning = true;
                        break;
                    default:
                        this.calculationStatus.amount = 0;
                        break;
                }
                let errorMessage = Labels.MSG_Error_Subdiscounts_Out_Of_Scope;
                let warningMessage = Labels.MSG_Warning_Subdiscounts_Out_Of_Scope;
                let errors = [];
                // let errors = [];
                if (percentError) {
                    let errorM = errorMessage;
                    if (errorM.includes('{0}')) {
                        errorM = errorM.replaceAll('{0}', this.labels.object.Contract_Discount__c.Value_per__c);
                    }
                    this.messages.percent = errorM;
                    errors.push(errorM);
                } else if (percentWarning) {
                    let warningM = warningMessage;
                    if (warningM.includes('{0}')) {
                        warningM = warningM.replaceAll('{0}', this.labels.object.Contract_Discount__c.Value_per__c);
                    }
                    this.messages.percent = warningM;
                } else {
                    this.messages.percent = '';
                }
                if (amountWarning) {
                    let warningM = warningMessage;
                    if (warningM.includes('{0}')) {
                        warningM = warningM.replaceAll('{0}', this.labels.object.Contract_Discount__c.Value_amt__c);
                    }
                    this.messages.amount = warningM;
                } else if (amountError) {
                    let errorM = errorMessage;
                    if (errorM.includes('{0}')) {
                        errorM = errorM.replaceAll('{0}', this.labels.object.Contract_Discount__c.Value_amt__c);
                    }
                    this.messages.amount = errorM;
                    errors.push(errorM);
                } else {
                    this.messages.amount = '';
                }
                if (errors.length > 0) {
                    this.fireOverFlowEvent(errors);
                } else {
                    this.fireEqualityEvent();
                }
            } else {
                this.calculationStatus.percent = 0;
                this.calculationStatus.amount = 0;
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    handleFieldEdits(event) {
        try {
            // let id = event.target.dataset.id;
            // let errorMessage2 = 'The sub discount must be checked';
            let index = event.target.dataset.index;
            let field = event.target.dataset.field;
            let selection = event.target.dataset.selection;
            let value = event.detail.value;
            this.subDiscountJSWrapper = this.subdiscountlist[index];
            if (field == API_NAMES.Contract_Discount__c.all_BU__c && event.target.checked) {
                this.subDiscountJSWrapper.isCheckedAllBU = true;
            } else if (field == API_NAMES.Contract_Discount__c.all_BU__c && !event.target.checked) {
                this.subDiscountJSWrapper.isCheckedAllBU = false;
            }
            if (field == API_NAMES.Contract_Discount__c.BusinessUnitScope__c) {
                this.subDiscountJSWrapper = this.subdiscountlist[index];
            }
            if (selection) {
                this.subDiscountJSWrapper.isSelected = event.detail.checked;
            } else {
                this.subDiscountJSWrapper.discount[field] = event.detail.value || event.detail.value == '' ? event.detail.value : event.detail.checked;
            }
            this.subdiscountlist = [...this.subdiscountlist];
            if (calculationFields.includes(field) || selection) {
                this.calculateSubs();
            }
            this.fireEqualityEvent();
            this.fireChangeEvent(this.subDiscountJSWrapper);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    fireChangeEvent(subWrapper) {
        try {
            // Creates the event with the contact ID data.
            const selectedEvent = new CustomEvent('updatesubdiscount', { detail: JSON.stringify(subWrapper) });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    togglepopup(subWrapper) {
        try {
            // Creates the event with the contact ID data.
            const togglepopupEvent = new CustomEvent('togglepopup');
            // Dispatches the event.
            this.dispatchEvent(togglepopupEvent);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    fireOverFlowEvent(message) {
        try {
            // Creates the event with the contact ID data.
            const overFlowEvent = new CustomEvent('overflow', { detail: JSON.stringify(message) });
            // Dispatches the event.
            this.dispatchEvent(overFlowEvent);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    fireEqualityEvent() {
        try {
            // Creates the event with the contact ID data.
            const equalityFlowEvent = new CustomEvent('equality', {});
            // Dispatches the event.
            this.dispatchEvent(equalityFlowEvent);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    showPerMessages(event) {
        try {
            if (this.percentStatus.icon && this.percentStatus.icon.includes(ERROR_VARIANT)) {
                this.showError(this.messages.percent);
            } else if (this.percentStatus.icon && this.percentStatus.icon.includes(WARNING_VARIANT)) {
                this.showWarning(this.messages.percent);
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    showAmtMessages(event) {
        try {
            if (this.amountStatus.icon && this.amountStatus.icon.includes(ERROR_VARIANT)) {
                this.showError(this.messages.amount);
            } else if (this.amountStatus.icon && this.amountStatus.icon.includes(WARNING_VARIANT)) {
                this.showWarning(this.messages.amount);
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    showError(message) {
        const evt = new ShowToastEvent({
            title: Labels.LBL_Error,
            message: message,
            variant: ERROR_VARIANT,
            mode: 'sticky',
        });
        this.dispatchEvent(evt);
    }
    showWarning(message) {
        const evt = new ShowToastEvent({
            title: Labels.LBL_Warning,
            message: message,
            variant: WARNING_VARIANT,
            mode: 'sticky',
        });
        this.dispatchEvent(evt);
    }
    
    filterBUs(event) {
        this.BUSearch = event.target.value;
        let filteredOptions = [];
        let regex = new RegExp(this.BUSearch, "i");
        //
        for (let option of this.bu) {
            if (regex.test(option.BUName)) {
                filteredOptions.push(option);
            }
        }
        this.BUForSelection = filteredOptions;
    }
    handleBUChanges(event) {
        try {
            let buId = event.target.dataset.id;
            console.log('BU Selection - Click detected, buId:', buId);
            console.log('BU array:', JSON.stringify(this.bu));
            
            // Find the selected BU from the BU array by ID
            let selectedBU = this.bu.find(buItem => {
                console.log('Checking BU item:', buItem);
                return buItem.Id === buId || buItem.BU?.Id === buId;
            });
            
            console.log('Selected BU:', selectedBU);
            
            if (selectedBU) {
                // Update the subdiscount using the wrapper reference
                this.subDiscountJSWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__c] = buId;
                this.subDiscountJSWrapper.discount[API_NAMES.Contract_Discount__c.BusinessUnitScope__r] = selectedBU.BU || selectedBU;
                
                console.log('Updated subdiscount:', this.subDiscountJSWrapper);
                
                // Refresh the list to trigger reactivity
                this.subdiscountlist = [...this.subdiscountlist];
                
                // Fire change events
                this.fireEqualityEvent();
                this.fireChangeEvent(this.subDiscountJSWrapper);
            } else {
                console.error('BU not found for ID:', buId);
            }
            
            this.closeBUSelection();
        } catch (error) {
            console.error('Error in handleBUChanges:', error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    openBUs(event) {
        try {
            let index = event.target.dataset.index;
            this.currentSubDiscountIndex = parseInt(index);
            this.subDiscountJSWrapper = this.subdiscountlist[index];
            this.showBUSelection = true;
            this.BUForSelection = this.bu || [];
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    
    closeBUSelection() {
        this.showBUSelection = false;
        this.BUForSelection = this.bu || [];
        this.currentSubDiscountIndex = null;
    }

    // Nego Scope Selection Popup Methods
    openNegoScope(event) {
        try {
            let index = event.target.dataset.index;
            this.currentSubDiscountIndex = parseInt(index);
            this.subDiscountJSWrapper = this.subdiscountlist[index];
            this.showNegoScopeSelection = true;
            this.negoScopeForSelection = this.negoscopes || [];
        } catch (error) {
            console.error('Error opening Nego Scope popup:', error);
        }
    }

    filterNegoScope(event) {
        try {
            let searchValue = event.target.value || '';
            this.negoScopeSearch = searchValue;
            if (searchValue === '') {
                this.negoScopeForSelection = this.negoscopes || [];
            } else {
                let searchLower = searchValue.toLowerCase();
                this.negoScopeForSelection = (this.negoscopes || []).filter(nego => {
                    return (nego.Name || '').toLowerCase().includes(searchLower);
                });
            }
        } catch (error) {
            console.error('Error filtering Nego Scope:', error);
        }
    }

    handleNegoScopeChange(event) {
        try {
            let negoId = event.target.dataset.id;
            let negoIndex = event.target.dataset.index;
            
            // Find the selected nego from the full array using the index
            let selectedNego = this.negoscopes[negoIndex];
            if (!selectedNego) {
                // Fallback: search by ID if index doesn't work
                selectedNego = this.negoScopeForSelection.find(n => n.Id === negoId);
            }
            
            if (selectedNego) {
                // Update the subdiscount using the wrapper reference
                this.subDiscountJSWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__c] = negoId;
                this.subDiscountJSWrapper.discount[API_NAMES.Contract_Discount__c.Product_Scope__r] = selectedNego;
                
                // Refresh the list to trigger reactivity
                this.subdiscountlist = [...this.subdiscountlist];
                
                // Fire change events
                this.fireEqualityEvent();
                this.fireChangeEvent(this.subDiscountJSWrapper);
            }
            
            this.closeNegoScopeSelection();
        } catch (error) {
            console.error('Error handling Nego Scope change:', error);
        }
    }

    closeNegoScopeSelection() {
        this.showNegoScopeSelection = false;
        this.negoScopeForSelection = this.negoscopes || [];
        this.currentSubDiscountIndex = null;
        this.negoScopeSearch = '';
    }

    // closePopupsEsc = (event) => {
    //     if (event.keyCode === 27) {
    //         if (this.showBUSelection) {
    //             this.closeBUSelection();
    //         }
    //     }
    // };
    handleSubDiscountClone(event) {
        try {
            let index = event.target.dataset.index;
            let newIndex = this.subdiscountlist.length;
            let subdiscountInitial = this.subdiscountlist[index];
            let buildJSWrapper = SubDiscountWrapper(subdiscountInitial, newIndex);
            delete buildJSWrapper.discount.Id;
            this.subdiscountlist.push(buildJSWrapper);
            buildJSWrapper.isInline = true;
            this.fireChangeEvent(buildJSWrapper);
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    handleSubDiscountDelete(event) {
        try {
            let index = event.target.dataset.index;
            this.subdiscountlist.splice(index, 1);
            // Reindex remaining items
            this.subdiscountlist.forEach((item, idx) => {
                item.index = idx;
            });
            this.subdiscountlist = [...this.subdiscountlist];
            this.calculateSubs();
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    openSubPCCSelection() {
        try {
            console.log('Opening Sub PCC selection popup');
            console.log('Current availableSubPCCs:', this.availableSubPCCs);
            console.log('Available PCCs count:', this.availableSubPCCs?.length || 0);

            this.showSubPCCSelection = true;
            // Initialize selection state
            this.selectedSubPCCs = [];

            // Reload available PCCs to ensure fresh data
            this.loadAvailableSubPCCs();
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    closeSubPCCSelection() {
        this.showSubPCCSelection = false;
        this.subPCCSearch = '';
    }
    filterSubPCCs(event) {
        this.subPCCSearch = event.target.value;
    }
    handleSubPCCSelection(event) {
        try {
            let pccId = event.target.dataset.id;
            let pccIndex = this.selectedSubPCCs.findIndex(item => item.id === pccId);

            if (event.target.checked) {
                if (pccIndex === -1) {
                    this.selectedSubPCCs.push({
                        id: pccId,
                        quantity: 1
                    });
                }
            } else {
                if (pccIndex !== -1) {
                    this.selectedSubPCCs.splice(pccIndex, 1);
                }
            }
            this.selectedSubPCCs = [...this.selectedSubPCCs];
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    handleSubPCCQuantityChange(event) {
        try {
            let pccId = event.target.dataset.id;
            let quantity = parseInt(event.target.value) || 1;
            let pccIndex = this.selectedSubPCCs.findIndex(item => item.id === pccId);

            if (pccIndex !== -1) {
                this.selectedSubPCCs[pccIndex].quantity = quantity;
                this.selectedSubPCCs = [...this.selectedSubPCCs];
            }
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    addSelectedSubPCCs() {
        try {
            // Add selected PCCs to the grid - add exact quantity specified by user
            this.selectedSubPCCs.forEach(selectedPCC => {
                // Find the PCC details from available list
                const pccDetails = this.availableSubPCCs.find(pcc => pcc.id === selectedPCC.id);
                if (!pccDetails) return;

                // Add the exact quantity specified, regardless of existing rows
                for (let i = 0; i < selectedPCC.quantity; i++) {
                    // Create new sub discount line as draft
                    let newSubDiscount = {
                        discount: {
                            [API_NAMES.Contract_Discount__c.Condition_Type__c]: pccDetails.id,
                            [API_NAMES.Contract_Discount__c.Condition_Type__r]: {
                                Name: pccDetails.name,
                                [API_NAMES.Pol_Com_Condition__c.Long_Name__c]: pccDetails.description,
                                [API_NAMES.Pol_Com_Condition__c.Is_Contract_Unicity_Requiered__c]: pccDetails.unicityRequired || false
                            },
                            Parent_Discount__c: this.currentjsdiscountwrapper?.discount?.Id,
                            Nego_Discount_Type__c: this.currentjsdiscountwrapper?.discount?.Nego_Discount_Type__c,
                            [API_NAMES.Contract_Discount__c.all_BU__c]: false,
                            [API_NAMES.Contract_Discount__c.all_items__c]: false,
                            [API_NAMES.Contract_Discount__c.Value_per__c]: 0,
                            [API_NAMES.Contract_Discount__c.Value_amt__c]: 0,
                            [API_NAMES.Contract_Discount__c.Proof_counterparty_number_total__c]: 0,
                            [API_NAMES.Contract_Discount__c.Product_Scope__c]: this.currentjsdiscountwrapper?.discount[API_NAMES.Contract_Discount__c.Product_Scope__c],
                            [API_NAMES.Contract_Discount__c.Product_Scope__r]: this.currentjsdiscountwrapper?.discount[API_NAMES.Contract_Discount__c.Product_Scope__r],
                            [API_NAMES.Contract_Discount__c.Contract__c]: this.currentjsdiscountwrapper?.discount[API_NAMES.Contract_Discount__c.Contract__c]
                        },
                        isSelected: true,
                        isDraft: true,
                        isBlocked: false,
                        isValidSubCondition: true,
                        enableSubValues: true,
                        enableDiscountTermsEdit: true,
                        enableProofTotalEdit: true,
                        enableProofDescriptionEdit: true,
                        unicityRequired: pccDetails.unicityRequired || false,
                        isCheckedAllBU: false
                    };
                    let newIndex = this.subdiscountlist.length;
                    let buildJSWrapper = SubDiscountWrapper(newSubDiscount, newIndex);
                    this.subdiscountlist.push(buildJSWrapper);
                }
            });

            this.subdiscountlist = [...this.subdiscountlist];
            this.hasSubDiscounts = this.subdiscountlist.length > 0;
            this.subdiscountlist.forEach((subWrapper, index) => {
                if (subWrapper.isDraft || !subWrapper.discount.Id) {
                    subWrapper.index = index;
                    this.fireChangeEvent(subWrapper);
                }
            });

            this.closeSubPCCSelection();
            this.calculateSubs();
        } catch (error) {
            console.error(error?.body?.message || error?.message || error);
            console.error(error);
        }
    }
    get filteredSubPCCs() {
        if (!this.subPCCSearch) {
            return this.availableSubPCCs;
        }
        let regex = new RegExp(this.subPCCSearch, 'i');
        return this.availableSubPCCs.filter(pcc => regex.test(pcc.name || pcc.description));
    }
    get selectedPCCCount() {
        let count = this.selectedSubPCCs.length;
        let totalRows = this.selectedSubPCCs.reduce((sum, pcc) => sum + pcc.quantity, 0);
        return `${count} selected (${totalRows} rows)`;
    }

    isPCCSelected(pccId) {
        return this.selectedSubPCCs.some(item => item.id === pccId);
    }

    getPCCQuantity(pccId) {
        const selected = this.selectedSubPCCs.find(item => item.id === pccId);
        return selected ? selected.quantity : 1;
    }

    get isAddSelectedDisabled() {
        return !this.selectedSubPCCs || this.selectedSubPCCs.length === 0;
    }
    get hasSubDiscountsOrDrafts() {
        return this.subdiscountlist && this.subdiscountlist.length > 0;
    }

    // Control grid visibility based on settings
    get shouldShowGrid() {
        if (this.pageSettings?.showSubDiscountColumn) {
            return true;
        }
        return this.hasSubDiscountsOrDrafts;
    }

    // Grid template column visibility getters
    get gridTemplate() {
        return this.pageSettings?.subDiscountGridSettings;
    }

    // Helper to check if a field is in the grid configuration
    isFieldInGridConfig(fieldName) {
        if (!this.gridFieldsConfig || this.gridFieldsConfig.length === 0) {
            return true;
        }
        return this.gridFieldsConfig.includes(fieldName);
    }

    // Column visibility based on grid template configuration
    get showAllBUColumn() {
        return this.isFieldInGridConfig('all_BU__c');
    }

    get showBUScopeColumn() {
        return this.isFieldInGridConfig('BusinessUnitScope__c');
    }

    get showDiscountTermsColumn() {
        return this.isFieldInGridConfig('Discount_Terms__c');
    }

    get showCounterpartyTotalColumn() {
        return this.isFieldInGridConfig('Proof_counterparty_number_total__c');
    }

    get showValuePercentColumn() {
        return this.isFieldInGridConfig('Value_per__c');
    }

    get showValueAmountColumn() {
        return this.isFieldInGridConfig('Value_amt__c');
    }

    get showCounterpartyDescriptionColumn() {
        return this.isFieldInGridConfig('Proof_counterparty_description__c');
    }

    get showAllItemsColumn() {
        return this.isFieldInGridConfig('all_items__c');
    }

    get showProductScopeColumn() {
        return this.isFieldInGridConfig('Product_Scope__c');
    }

    get showActionsColumn() {
        return !this.isReadOnly;
    }

    get showCounterpartyDescriptionColumn() {
        return this.isFieldInGridConfig('Proof_counterparty_description__c');
    }

    get showAllItemsColumn() {
        return this.isFieldInGridConfig('all_items__c');
    }

    get showProductScopeColumn() {
        return this.isFieldInGridConfig('Product_Scope__c');
    }

    get showActionsColumn() {
        return true;
    }

    get popupTitle() {
        if (!this.currentjsdiscountwrapper) return '';
        const titleLabel = this.labels.LBL_Condition_Manager_Sub_Discount_Popup_Title || 'Sub Discounts Management';
        const conditionTypeName = this.currentjsdiscountwrapper?.conditionTypeName || '';
        const discountName = this.currentjsdiscountwrapper?.discount?.Name || '';
        return `${titleLabel} - ${conditionTypeName} (${discountName})`;
    }
    @track popups = {
        Discount_Terms__c: {
            isOpen: false,
            value: '',
            title: '',
            subDiscount: undefined,
            open(event) {
                let index = event.target.dataset.index;
                this.popups.Discount_Terms__c.subDiscount = this.subdiscountlist[index];
                this.popups.Discount_Terms__c.value = this.popups.Discount_Terms__c.subDiscount.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c];
                this.popups.Discount_Terms__c.title = this.conditionpage.objectsInfo.Contract_Discount__c.fields[API_NAMES.Contract_Discount__c.Discount_Terms__c].label;
                this.popups.Discount_Terms__c.isOpen = true;
            },
            confirm(event) {
                let value = this.popups.Discount_Terms__c.value;
                this.popups.Discount_Terms__c.subDiscount.discount[API_NAMES.Contract_Discount__c.Discount_Terms__c] = value;
                this.popups.Discount_Terms__c.isOpen = false;
                this.fireChangeEvent(this.popups.Discount_Terms__c.subDiscount);
            },
            handleValueChange(event) {
                this.popups.Discount_Terms__c.value = event.detail.value;
            },
            close(event) {
                this.popups.Discount_Terms__c.isOpen = false;
            },
        },
        Proof_counterparty_description__c: {
            isOpen: false,
            value: '',
            title: '',
            subDiscount: undefined,
            open(event) {
                let index = event.target.dataset.index;
                this.popups.Proof_counterparty_description__c.subDiscount = this.subdiscountlist[index];
                this.popups.Proof_counterparty_description__c.value = this.popups.Proof_counterparty_description__c.subDiscount.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c];
                this.popups.Proof_counterparty_description__c.title = this.conditionpage.objectsInfo.Contract_Discount__c.fields[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c].label;
                this.popups.Proof_counterparty_description__c.isOpen = true;
            },
            confirm(event) {
                let value = this.popups.Proof_counterparty_description__c.value;
                this.popups.Proof_counterparty_description__c.subDiscount.discount[API_NAMES.Contract_Discount__c.Proof_counterparty_description__c] = value;
                this.popups.Proof_counterparty_description__c.isOpen = false;
                this.fireChangeEvent(this.popups.Proof_counterparty_description__c.subDiscount);
            },
            handleValueChange(event) {
                this.popups.Proof_counterparty_description__c.value = event.detail.value;
            },
            close(event) {
                this.popups.Proof_counterparty_description__c.isOpen = false;
            },
        },
    };
}