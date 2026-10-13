import { LightningElement, track } from 'lwc';
import Toast from 'lightning/toast';
import getManagerInitData from '@salesforce/apex/BannerSettingsController.getManagerInitData';
import getObjectSetupData from '@salesforce/apex/BannerSettingsController.getObjectSetupData';
import getDetailFieldExplorerOptions from '@salesforce/apex/BannerSettingsController.getDetailFieldExplorerOptions';
import saveBannerSetting from '@salesforce/apex/BannerSettingsController.saveBannerSetting';
import uploadBannerImage from '@salesforce/apex/BannerSettingsController.uploadBannerImage';
import { Labels } from './properties.js';


export default class BannerSettingsManager extends LightningElement {
    labels = Labels;
    displayOptions = [
        { label: this.labels.LBL_ApiAboveValue, value: 'above' },
        { label: this.labels.LBL_APINextToValue, value: 'inline' }
    ];
    detailLabelModeOptions = [
        { label: this.labels.LBL_FieldLabel, value: 'fieldLabel' },
        { label: this.labels.LBL_CustomLabel, value: 'customLabel' },
        { label: this.labels.LBL_Icon, value: 'icon' }
    ];
    detailLabelIconSourceOptions = [
        { label: this.labels.LBL_Icon, value: 'icon' },
        { label: this.labels.LBL_UploadImage, value: 'uploaded' }
    ];
    iconSourceOptions = [
        { label: this.labels.LBL_StandardIcon, value: 'standard' },
        { label: this.labels.LBL_StaticResourceURL, value: 'staticResource' },
        { label: this.labels.LBL_UploadImage, value: 'uploaded' }
    ];
    redirectionOptions = [
        { label: 'Grid', value: 'Grid' },
        { label: 'URL', value: 'URL' },
        { label: 'Flow', value: 'Flow' },
        { label: 'Page', value: 'Page' }
    ];
    defaultColor = '#16325c';
    classPrefix = 'c-banner-settings-manager';

    @track form = {
        developerName: '',
        masterLabel: '',
        objectApiName: '',
        titleFieldApiName: '',
        subtitleFieldApiName: '',
        iconType: 'standard',
        iconValue: 'standard:record',
        iconSize: '30px',
        backgroundColor: '#ffffff',
        textColor: '#16325c',
        displayMode: 'horizontal',
        numberOfFieldsDisplay: 3,
        selectedActionApiNames: [],
        screenFlows: [],
        detailFields: [],
        isActive: true
    };
    @track objectOptions = [];
    @track fieldOptions = [];
    @track actionOptions = [];
    @track iconOptions = [];
    @track displayModeOptions = [];
    @track picklistValues = {};
    @track fieldLabels = {};
    @track savedSettings = [];
    @track searchTerm = '';
    @track isLoading = false;
    @track isSaving = false;
    @track selectedDeveloperName = '';
    @track selectedBannerLabel = '';
    @track showNewBannerModal = false;
    @track newBannerDraft = { masterLabel: '', objectApiName: '' };
    @track formBaseline = null;
    @track selectedAvailableActionApiNames = [];
    @track selectedChosenActionApiNames = [];
    @track detailAvailableOptions = [];
    @track detailSearchTerm = '';
    @track detailReferenceOptions = [];
    @track detailReferencePath = '';
    @track detailReferenceSearchTerm = '';
    @track isDetailReferenceLoading = false;
    @track selectedAvailableDetailValues = [];
    @track selectedReferenceDetailValues = [];
    @track selectedDetailFieldIndices = [];
    @track showDetailStyleModal = false;
    @track detailStyleDraft = {};
    @track editingDetailIndex = null;
    @track flowOptions = [];
    @track gridOptions = [];
    @track pageOptions = [];
    @track draftEditorActive = false;
    tabStyleApplied = false;

    sortOptionsByLabel(options = []) {
        return [...options].sort((firstItem, secondItem) =>
            String(firstItem?.label || '').localeCompare(String(secondItem?.label || ''), undefined, { sensitivity: 'base' })
        );
    }

    createDetailField(index = 0) {
        return {
            key: `field_${Date.now()}_${index}`,
            fieldApiName: '',
            color: this.defaultColor,
            bold: false,
            italic: false,
            underline: false,
            labelPosition: 'above',
            labelMode: 'fieldLabel',
            labelIconSource: 'icon',
            customLabel: '',
            labelIcon: 'utility:info'
        };
    }

    createDefaultForm() {
        return {
            developerName: '',
            masterLabel: '',
            objectApiName: '',
            titleFieldApiName: '',
            subtitleFieldApiName: '',
            iconType: 'standard',
            iconValue: 'standard:record',
            iconSize: '30px',
            backgroundColor: '#ffffff',
            textColor: '#16325c',
            displayMode: 'horizontal',
            numberOfFieldsDisplay: 3,
            selectedActionApiNames: [],
            screenFlows: [],
            detailFields: [this.createDetailField()],
            isActive: true
        };
    }

    connectedCallback() {
        if (!this.form.detailFields.length) {
            this.form = {
                ...this.form,
                detailFields: [this.createDetailField()]
            };
        }
        this.detailStyleDraft = this.createDetailField();
        this.applyConnectTabStyles();
        this.initialize();
    }

    applyConnectTabStyles() {
        if (this.tabStyleApplied) {
            return;
        }
        const tabStyle = document.createElement('style');
        tabStyle.innerText = `
            ${this.classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                background: white;
                color: #806BBF;
                height: 60px;
                width: 230px;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item {
                background: #806BBF;
                height: 60px;
                width: 230px;
                border-bottom: 2px solid white;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item .slds-icon {
                --slds-c-icon-color-foreground: white;
            }
            ${this.classPrefix} .slds-vertical-tabs__link {
                color: white;
                font-size: 14px;
                height: 60px;
                font-weight: 600;
            }
            ${this.classPrefix} .slds-vertical-tabs__link:hover {
                background: #806BBF;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item:hover {
                background: white;
                color: #806BBF;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item a:hover,
            ${this.classPrefix} .slds-vertical-tabs__nav-item a:focus {
                color: #806BBF;
                background: white;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav-item.slds-is-active:hover {
                background: white;
                color: #806BBF;
            }
            ${this.classPrefix} .slds-vertical-tabs {
                border-radius: 0px 0px 0px 5px;
                border: none;
            }
            ${this.classPrefix} .slds-vertical-tabs__left-icon {
                --slds-c-icon-color-foreground-default: white;
            }
            ${this.classPrefix} lightning-tab-bar {
                width: 230px;
                background: #806BBF;
                height: auto;
            }
            ${this.classPrefix} .slds-vertical-tabs__nav {
                width: var(--lwc-sizeXSmall, 12rem);
                border-right: var(--lwc-borderWidthThin, 1px) solid var(--slds-g-color-border-base-1, var(--lwc-colorBorder, rgb(229, 229, 229)));
                background: var(--slds-g-color-neutral-base-95, var(--lwc-colorBackground, rgb(243, 243, 243)));
            }
            @media screen and (max-width: 980px) {
                ${this.classPrefix} .slds-vertical-tabs__nav-item.slds-is-active {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${this.classPrefix} .slds-vertical-tabs__nav-item {
                    width: 190px;
                    font-size: 13px;
                    font-weight: 400;
                }
                ${this.classPrefix} .slds-vertical-tabs__link {
                    font-size: 13px;
                    font-weight: 400;
                    height: 60px;
                }
                ${this.classPrefix} lightning-tab-bar {
                    width: 190px;
                }
                ${this.classPrefix} .slds-vertical-tabs__nav {
                    border-right: none;
                    background: none;
                }
            }
        `;
        document.body.appendChild(tabStyle);

        const tabStyleHover = document.createElement('style');
        tabStyleHover.innerText = `
            ${this.classPrefix} .tab-set-style a:hover {
                color: #806BBF;
                background-color: white;
                text-decoration: none;
            }
            ${this.classPrefix} .tab-set-style a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${this.classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a {
                color: #806BBF;
                font-weight: 600;
            }
            ${this.classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
            ${this.classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover {
                color: #806BBF;
                background: white;
            }
            ${this.classPrefix} .tab-set-style .slds-vertical-tabs__nav-item.slds-is-active a:hover .slds-icon {
                --slds-c-icon-color-foreground: #806BBF;
            }
        `;
        document.body.appendChild(tabStyleHover);
        this.tabStyleApplied = true;
    }

    get filteredSettings() {
        const term = (this.searchTerm || '').trim().toLowerCase();
        if (!term) {
            return this.savedSettings;
        }
        return this.savedSettings.filter((item) => {
            return (
                (item.masterLabel || '').toLowerCase().includes(term) ||
                (item.developerName || '').toLowerCase().includes(term) ||
                (item.objectApiName || '').toLowerCase().includes(term)
            );
        });
    }

    get filteredSettingsView() {
        return this.filteredSettings.map((item) => ({
            ...item,
            itemClass:
                item.developerName === this.selectedDeveloperName
                    ? 'menuItem slds-split-view__list-item-action slds-grow slds-has-flexi-truncate saved-item saved-item_selected'
                    : 'menuItem slds-split-view__list-item-action slds-grow slds-has-flexi-truncate saved-item'
        }));
    }

    get headerTitle() {
        return this.selectedBannerLabel
            ? `${this.labels.LBL_BannerLayout} : ${this.selectedBannerLabel}`
            : this.labels.LBL_BannerLayout;
    }

    get shouldShowWorkspace() {
        return !!(this.selectedDeveloperName || this.draftEditorActive);
    }

    get showNewButton() {
        return !this.selectedDeveloperName && !this.draftEditorActive;
    }

    get isFormDirty() {
        if (this.formBaseline == null) {
            return false;
        }
        return this.serializeFormState() !== this.formBaseline;
    }

    get cannotSave() {
        return this.isSaving || !this.isFormDirty || !this.shouldShowWorkspace;
    }

    get showStandardIconPicker() {
        return this.form.iconType === 'standard';
    }

    get showStaticResourceInput() {
        return this.form.iconType === 'staticResource';
    }

    get showUploadInput() {
        return this.form.iconType === 'uploaded';
    }

    displayTypeOptions = [
        { label: 'Button', value: 'Button' },
        { label: 'Icon', value: 'Icon' },
        { label: 'Action', value: 'Action' }
    ];

    get selectedActionSet() {
        return new Set(this.form.selectedActionApiNames || []);
    }

    get availableActionOptions() {
        return (this.actionOptions || []).filter((item) => !this.selectedActionSet.has(item.value));
    }

    get chosenActionOptions() {
        return (this.actionOptions || []).filter((item) => this.selectedActionSet.has(item.value));
    }

    get filteredDetailAvailableOptions() {
        const term = (this.detailSearchTerm || '').trim().toLowerCase();
        if (!term) {
            return this.detailAvailableOptions || [];
        }
        return (this.detailAvailableOptions || []).filter((item) => String(item.label || '').toLowerCase().includes(term));
    }

    get iconPickerValue() {
        return this.form.iconValue || 'standard:record';
    }

    get showCustomLabelInput() {
        return this.detailStyleDraft && this.detailStyleDraft.labelMode === 'customLabel';
    }

    get showDetailLabelIconPicker() {
        return this.detailStyleDraft
            && this.detailStyleDraft.labelMode === 'icon'
            && this.detailStyleDraft.labelIconSource !== 'uploaded';
    }

    get showDetailLabelImageUpload() {
        return this.detailStyleDraft
            && this.detailStyleDraft.labelMode === 'icon'
            && this.detailStyleDraft.labelIconSource === 'uploaded';
    }

    initialize() {
        this.isLoading = true;
        getManagerInitData()
            .then((response) => {
                let initData = JSON.parse(response || '{}');
                this.objectOptions = this.sortOptionsByLabel(initData.objectOptions || []);
                this.iconOptions = initData.iconOptions || [];
                this.picklistValues = initData.picklistMap || {};
                this.fieldLabels = initData.fieldLabels || {};
                this.displayModeOptions = this.picklistValues.DisplayMode__c || initData.displayModeOptions || [];
                this.savedSettings = initData.savedSettings || [];
                this.gridOptions = this.sortOptionsByLabel(initData.gridOptions || []);
                this.pageOptions = this.sortOptionsByLabel(initData.pageOptions || []);
                this.applyScreenFlowOptions(initData.activeScreenFlows);
                if (this.form?.screenFlows?.length) {
                    this.refreshScreenFlowOptions();
                }
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'warning');
            })
            .finally(() => {
                this.isLoading = false;
                if (this.shouldShowWorkspace) {
                    this.captureFormBaseline();
                }
            });
    }

    serializeFormState() {
        const detailFields = (this.form.detailFields || []).map((item) => ({
            fieldApiName: item.fieldApiName || '',
            color: item.color || this.defaultColor,
            bold: !!item.bold,
            italic: !!item.italic,
            underline: !!item.underline,
            labelPosition: item.labelPosition || 'above',
            labelMode: item.labelMode || 'fieldLabel',
            customLabel: item.customLabel || '',
            labelIcon: item.labelIcon || 'utility:info'
        }));
        const selectedActionApiNames = [...(this.form.selectedActionApiNames || [])].sort();
        const screenFlows = (this.form.screenFlows || []).map((item) => ({
            value: item.value || '',
            label: item.label || '',
            redirectionType: item.redirectionType || 'Flow',
            displayType: item.displayType || 'Action',
            icon: item.icon || ''
        }));
        return JSON.stringify({
            developerName: this.form.developerName || '',
            masterLabel: this.form.masterLabel || '',
            objectApiName: this.form.objectApiName || '',
            titleFieldApiName: this.form.titleFieldApiName || '',
            subtitleFieldApiName: this.form.subtitleFieldApiName || '',
            iconType: this.form.iconType || 'standard',
            iconValue: this.form.iconValue || '',
            iconSize: this.form.iconSize || '30px',
            backgroundColor: this.form.backgroundColor || '#ffffff',
            textColor: this.form.textColor || '#16325c',
            displayMode: this.form.displayMode || 'horizontal',
            numberOfFieldsDisplay: Number(this.form.numberOfFieldsDisplay) || 1,
            isActive: this.form.isActive !== false,
            detailFields,
            selectedActionApiNames,
            screenFlows
        });
    }

    captureFormBaseline() {
        this.formBaseline = this.serializeFormState();
    }

    loadObjectDependencies(objectApiName) {
        if (!objectApiName) {
            this.fieldOptions = [];
            this.actionOptions = [];
            this.detailAvailableOptions = [];
            return;
        }
        return getObjectSetupData({ objectApiName, developerName: null }).then((response) => {
            const setupData = JSON.parse(response || '{}');
            this.fieldOptions = this.sortOptionsByLabel(setupData.fieldOptions || []);
            this.actionOptions = setupData.actionOptions || [];
            this.selectedAvailableActionApiNames = [];
            this.selectedChosenActionApiNames = [];
            return this.loadDetailFieldExplorer('');
        });
    }

    loadDetailFieldExplorer(currentPath = '') {
        if (!this.form.objectApiName) {
            this.detailAvailableOptions = [];
            this.detailReferenceOptions = [];
            this.detailReferencePath = '';
            return;
        }
        return getDetailFieldExplorerOptions({
            objectApiName: this.form.objectApiName,
            currentPath
        }).then((response) => {
            const parsed = JSON.parse(response || '{}');
            this.detailAvailableOptions = parsed.options || [];
            this.detailSearchTerm = '';
            this.selectedAvailableDetailValues = [];
            this.detailReferenceOptions = [];
            this.detailReferencePath = '';
            this.selectedReferenceDetailValues = [];
            this.detailReferenceSearchTerm = '';
        });
    }

    loadReferenceDetailFieldExplorer(currentPath) {
        if (!this.form.objectApiName || !currentPath) {
            this.detailReferenceOptions = [];
            this.detailReferencePath = '';
            return;
        }
        this.isDetailReferenceLoading = true;
        return getDetailFieldExplorerOptions({
            objectApiName: this.form.objectApiName,
            currentPath
        }).then((response) => {
            const parsed = JSON.parse(response || '{}');
            // Limit depth to one relationship hop (e.g. Contract_BU__r.Name).
            // Do not expose next-level relationship navigation in reference list.
            this.detailReferenceOptions = (parsed.options || []).filter((item) => !item.isNavigation);
            this.detailReferencePath = parsed.currentPath || currentPath;
            this.selectedReferenceDetailValues = [];
            this.detailReferenceSearchTerm = '';
        }).finally(() => {
            this.isDetailReferenceLoading = false;
        });
    }

    applyScreenFlowOptions(result) {
        if (!result) {
            this.flowOptions = [];
            return;
        }
        try {
            const parsedResult = JSON.parse(result || '{}');
            const flowRecords = JSON.parse(parsedResult.flowsSerialized || '[]');
            const flowDefinitionRecords = JSON.parse(parsedResult.flowDefinitionSerialized || '[]');
            const devNameMap = {};
            flowDefinitionRecords.forEach((item) => {
                devNameMap[item.ActiveVersionId] = `${item.NamespacePrefix ? `${item.NamespacePrefix}__` : ''}${item.DeveloperName}`;
            });
            this.flowOptions = flowRecords.map((flow) => ({
                label: flow.MasterLabel,
                value: devNameMap[flow.Id]
            }));
        } catch (error) {
            this.flowOptions = [];
        }
    }

    getOptionsByRedirectionType(redirectionType) {
        if (redirectionType === 'Grid') {
            return this.gridOptions || [];
        }
        if (redirectionType === 'Page') {
            return this.pageOptions || [];
        }
        if (redirectionType === 'Flow') {
            return this.flowOptions || [];
        }
        return [];
    }

    withRedirectionState(item, key) {
        const redirectionType = item?.redirectionType || 'Flow';
        const displayType = item?.displayType || 'Action';
        const isFlow = redirectionType === 'Flow';
        const isAction = isFlow && displayType === 'Action';
        const isIcon = isFlow && displayType === 'Icon';
        const isButton = isFlow && displayType === 'Button';
        const icon = item?.icon || (isAction ? 'utility:forward_up' : '');
        const hasSldsIcon = String(icon || '').includes(':');
        const hasImageIcon = !!icon && !hasSldsIcon;
        return {
            key,
            value: item?.value || '',
            label: item?.label || '',
            icon,
            redirectionType,
            displayType,
            isFlow,
            isAction,
            isIcon,
            isButton,
            isURL: redirectionType === 'URL',
            hasSldsIcon,
            hasImageIcon,
            options: this.getOptionsByRedirectionType(redirectionType)
        };
    }

    refreshScreenFlowOptions() {
        this.form = {
            ...this.form,
            screenFlows: (this.form.screenFlows || []).map((item, index) =>
                this.withRedirectionState(item, item.key || `flow_${Date.now()}_${index}`)
            )
        };
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleDetailSearchChange(event) {
        this.detailSearchTerm = event.target.value;
    }

    handleDetailReferenceSearchChange(event) {
        this.detailReferenceSearchTerm = event.target.value;
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        if (!field) {
            return;
        }
        const isCheckbox = event.target && event.target.type === 'checkbox';
        const rawValue = isCheckbox ? event.target.checked : event.detail.value;
        const value = field === 'numberOfFieldsDisplay' ? Number(rawValue) : rawValue;
        if (field === 'masterLabel') {
            const next = { ...this.form, masterLabel: value };
            if (this.draftEditorActive && !this.selectedDeveloperName) {
                next.developerName = value && String(value).trim() ? this.suggestDeveloperName(value) : '';
            }
            this.form = next;
            return;
        }
        this.form = {
            ...this.form,
            [field]: field === 'numberOfFieldsDisplay' && (!value || value < 1) ? 1 : value
        };
    }

    handleIconPickerChange(event) {
        this.form = {
            ...this.form,
            iconValue: event.detail.value
        };
    }

    resetIconHandler() {
        this.form = {
            ...this.form,
            iconValue: 'standard:record'
        };
    }

    handleObjectChange(event) {
        const objectApiName = event.detail.value;
        this.form = {
            ...this.form,
            objectApiName,
            titleFieldApiName: '',
            subtitleFieldApiName: '',
            selectedActionApiNames: [],
            screenFlows: [],
            detailFields: [this.createDetailField()]
        };
        this.isLoading = true;
        this.loadObjectDependencies(objectApiName)
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleAvailableActionsSelection(event) {
        this.selectedAvailableActionApiNames = Array.from(event.target.selectedOptions || []).map((option) => option.value);
    }

    handleChosenActionsSelection(event) {
        this.selectedChosenActionApiNames = Array.from(event.target.selectedOptions || []).map((option) => option.value);
    }

    addSelectedActionsHandler() {
        if (!this.selectedAvailableActionApiNames.length) {
            return;
        }
        const current = new Set(this.form.selectedActionApiNames || []);
        this.selectedAvailableActionApiNames.forEach((value) => current.add(value));
        this.form = {
            ...this.form,
            selectedActionApiNames: [...current]
        };
        this.selectedAvailableActionApiNames = [];
    }

    removeSelectedActionsHandler() {
        if (!this.selectedChosenActionApiNames.length) {
            return;
        }
        const removeSet = new Set(this.selectedChosenActionApiNames);
        this.form = {
            ...this.form,
            selectedActionApiNames: (this.form.selectedActionApiNames || []).filter((value) => !removeSet.has(value))
        };
        this.selectedChosenActionApiNames = [];
    }

    handleAddFlow() {
        const nextFlow = this.withRedirectionState(
            {
                value: '',
                label: '',
                icon: '',
                redirectionType: 'Flow',
                displayType: 'Action'
            },
            `flow_${Date.now()}_${(this.form.screenFlows || []).length}`
        );
        this.form = {
            ...this.form,
            screenFlows: [...(this.form.screenFlows || []), nextFlow]
        };
    }

    handleDeleteFlow(event) {
        const index = Number(event.currentTarget.dataset.index);
        this.form = {
            ...this.form,
            screenFlows: (this.form.screenFlows || []).filter((_, itemIndex) => itemIndex !== index)
        };
    }

    handleChangeFlow(event) {
        const index = Number(event.target.dataset.index);
        const field = event.target.dataset.field;
        if (Number.isNaN(index) || !field) {
            return;
        }
        const value = event.detail?.value ?? event.target?.value;
        const nextFlows = [...(this.form.screenFlows || [])];
        const current = {
            ...nextFlows[index],
            [field]: value
        };
        if (field === 'redirectionType') {
            current.redirectionType = value || 'Flow';
            current.value = '';
            if (current.redirectionType !== 'Flow') {
                current.displayType = 'Action';
                current.icon = '';
            } else {
                current.displayType = current.displayType || 'Action';
                if (current.displayType === 'Action' && !current.icon) {
                    current.icon = 'utility:forward_up';
                }
            }
        }
        if (field === 'displayType') {
            current.displayType = value || 'Action';
            if (current.displayType === 'Action' && !current.icon) {
                current.icon = 'utility:forward_up';
            }
            if (current.displayType === 'Icon') {
                current.icon = current.icon && current.icon.startsWith('http') ? current.icon : '';
            }
        }
        nextFlows[index] = this.withRedirectionState(current, current.key || `flow_${Date.now()}_${index}`);
        this.form = {
            ...this.form,
            screenFlows: nextFlows
        };
    }

    handleFlowIconUpload(event) {
        const index = Number(event.currentTarget.dataset.index);
        if (Number.isNaN(index)) {
            return;
        }
        const file = event.target.files && event.target.files[0];
        if (!file) {
            return;
        }
        this.readFileAsBase64(file)
            .then((base64Data) => {
                this.isLoading = true;
                return uploadBannerImage({
                    fileName: file.name,
                    base64Data
                });
            })
            .then((uploadedUrl) => {
                const nextFlows = [...(this.form.screenFlows || [])];
                const current = {
                    ...nextFlows[index],
                    icon: uploadedUrl,
                    displayType: 'Icon',
                    redirectionType: 'Flow'
                };
                nextFlows[index] = this.withRedirectionState(current, current.key || `flow_${Date.now()}_${index}`);
                this.form = {
                    ...this.form,
                    screenFlows: nextFlows
                };
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
                event.target.value = '';
            });
    }

    addDetailField() {
        this.form = {
            ...this.form,
            detailFields: [...this.form.detailFields, this.createDetailField(this.form.detailFields.length)]
        };
    }

    removeDetailField(event) {
        const index = Number(event.currentTarget.dataset.index);
        const next = this.form.detailFields.filter((item, itemIndex) => itemIndex !== index);
        this.form = {
            ...this.form,
            detailFields: next.length ? next : [this.createDetailField()]
        };
    }

    handleDetailFieldChange(event) {
        const index = Number(event.target.dataset.index);
        const field = event.target.dataset.field;
        const next = [...this.form.detailFields];
        next[index] = {
            ...next[index],
            [field]: event.target.type === 'checkbox' ? event.target.checked : event.target.value
        };
        this.form = {
            ...this.form,
            detailFields: next
        };
    }

    handleDetailFieldSelect(event) {
        let index = Number(event.target.dataset.index);
        if (Number.isNaN(index)) {
            return;
        }
        let next = [...(this.form.detailFields || [])];
        if (!next[index]) {
            return;
        }
        let apiPath = event.detail?.apiPath || '';
        if (apiPath === '') {
            next[index] = {
                ...next[index],
                fieldApiName: ''
            };
            this.form = {
                ...this.form,
                detailFields: next
            };
        } else {
            next[index] = {
                ...next[index],
                fieldApiName: apiPath
            };
            this.form = {
                ...this.form,
                detailFields: next
            };
        }
    }


    handleAvailableDetailFieldsSelection(event) {
        const values = Array.from(event.target.selectedOptions || []).map((option) => option.value);
        this.selectedAvailableDetailValues = values;
        if (values.length === 1) {
            const selected = (this.detailAvailableOptions || []).find((item) => item.value === values[0]);
            if (selected?.isNavigation) {
                this.loadReferenceDetailFieldExplorer(selected.value);
            }
        }
    }

    handleReferenceDetailFieldsSelection(event) {
        this.selectedReferenceDetailValues = Array.from(event.target.selectedOptions || []).map((option) => option.value);
    }

    handleSelectedDetailFieldsSelection(event) {
        this.selectedDetailFieldIndices = Array.from(event.target.selectedOptions || []).map((option) => Number(option.value));
    }

    handleDetailPathBack() {
        this.detailReferenceOptions = [];
        this.detailReferencePath = '';
        this.selectedReferenceDetailValues = [];
        this.detailReferenceSearchTerm = '';
    }

    addSelectedDetailFields() {
        const selectedValues = [...(this.selectedAvailableDetailValues || []), ...(this.selectedReferenceDetailValues || [])];
        if (!selectedValues.length) {
            return;
        }
        const allAvailable = [...(this.detailAvailableOptions || []), ...(this.detailReferenceOptions || [])];
        const selectedOptions = allAvailable.filter((item) => selectedValues.includes(item.value) && !item.isNavigation);
        if (!selectedOptions.length) {
            return;
        }
        const existing = new Set((this.form.detailFields || []).map((item) => item.fieldApiName));
        const newItems = selectedOptions
            .filter((item) => !existing.has(item.value))
            .map((item, index) => ({
                ...this.createDetailField(index),
                fieldApiName: item.value
            }));
        this.form = {
            ...this.form,
            detailFields: [...(this.form.detailFields || []), ...newItems]
        };
        this.selectedAvailableDetailValues = [];
        this.selectedReferenceDetailValues = [];
    }

    removeSelectedDetailFields() {
        if (!this.selectedDetailFieldIndices.length) {
            return;
        }
        const removeSet = new Set(this.selectedDetailFieldIndices);
        const next = (this.form.detailFields || []).filter((_, index) => !removeSet.has(index));
        this.form = {
            ...this.form,
            detailFields: next.length ? next : [this.createDetailField()]
        };
        this.selectedDetailFieldIndices = [];
    }

    moveSelectedDetailFieldsTop() {
        this.reorderSelectedDetailFields('top');
    }

    moveSelectedDetailFieldsUp() {
        this.reorderSelectedDetailFields('up');
    }

    moveSelectedDetailFieldsDown() {
        this.reorderSelectedDetailFields('down');
    }

    moveSelectedDetailFieldsBottom() {
        this.reorderSelectedDetailFields('bottom');
    }

    reorderSelectedDetailFields(direction) {
        const selected = [...this.selectedDetailFieldIndices].sort((a, b) => a - b);
        if (!selected.length) {
            return;
        }
        const items = [...(this.form.detailFields || [])];
        const selectedKeys = selected.map((index) => items[index]?.key).filter(Boolean);
        const selectedSet = new Set(selected);

        if (direction === 'top' || direction === 'bottom') {
            const picked = items.filter((_, index) => selectedSet.has(index));
            const rest = items.filter((_, index) => !selectedSet.has(index));
            const next = direction === 'top' ? [...picked, ...rest] : [...rest, ...picked];
            this.form = { ...this.form, detailFields: next };
            const start = direction === 'top' ? 0 : rest.length;
            this.selectedDetailFieldIndices = picked.map((_, i) => start + i);
            return;
        }

        if (direction === 'up') {
            for (let i = 0; i < items.length; i++) {
                if (selectedSet.has(i) && i > 0 && !selectedSet.has(i - 1)) {
                    [items[i - 1], items[i]] = [items[i], items[i - 1]];
                }
            }
        }
        if (direction === 'down') {
            for (let i = items.length - 1; i >= 0; i--) {
                if (selectedSet.has(i) && i < items.length - 1 && !selectedSet.has(i + 1)) {
                    [items[i + 1], items[i]] = [items[i], items[i + 1]];
                }
            }
        }
        this.form = { ...this.form, detailFields: items };
        const indexMap = new Map(items.map((item, index) => [item.key, index]));
        this.selectedDetailFieldIndices = selectedKeys.map((key) => indexMap.get(key)).filter((index) => index !== undefined);
    }

    openDetailStyleModal(event) {
        let index = this.selectedDetailFieldIndices.length ? this.selectedDetailFieldIndices[0] : null;
        if (event?.currentTarget?.dataset?.index !== undefined) {
            let parsedIndex = Number(event.currentTarget.dataset.index);
            index = Number.isNaN(parsedIndex) ? null : parsedIndex;
        }
        if (index == null) {
            this.showToast('Banner settings', 'Select at least one detail field first.', 'error');
            return;
        }
        const current = (this.form.detailFields || [])[index];
        if (!current) {
            return;
        }
        this.editingDetailIndex = index;
        this.detailStyleDraft = {
            labelMode: 'fieldLabel',
            labelIconSource: 'icon',
            customLabel: '',
            labelIcon: 'utility:info',
            ...current
        };
        if (!String(this.detailStyleDraft.labelIcon || '').includes(':')) {
            this.detailStyleDraft = {
                ...this.detailStyleDraft,
                labelIconSource: 'uploaded'
            };
        }
        this.showDetailStyleModal = true;
    }

    closeDetailStyleModal() {
        this.showDetailStyleModal = false;
        this.editingDetailIndex = null;
    }

    handleDetailStyleDraftChange(event) {
        const field = event.currentTarget.dataset.field;
        if (!field) {
            return;
        }
        const isCheckbox = event.target && event.target.type === 'checkbox';
        const value = isCheckbox ? event.target.checked : event.detail.value;
        this.detailStyleDraft = {
            ...this.detailStyleDraft,
            [field]: value
        };
        if (field === 'labelIconSource') {
            if (value === 'icon' && (!this.detailStyleDraft.labelIcon || !String(this.detailStyleDraft.labelIcon).includes(':'))) {
                this.detailStyleDraft = {
                    ...this.detailStyleDraft,
                    labelIcon: 'utility:info'
                };
            }
            if (value === 'uploaded' && String(this.detailStyleDraft.labelIcon || '').includes(':')) {
                this.detailStyleDraft = {
                    ...this.detailStyleDraft,
                    labelIcon: ''
                };
            }
        }
    }

    applyDetailStyleDraft() {
        if (this.editingDetailIndex == null) {
            this.closeDetailStyleModal();
            return;
        }
        const next = [...(this.form.detailFields || [])];
        next[this.editingDetailIndex] = {
            ...next[this.editingDetailIndex],
            color: this.detailStyleDraft.color || this.defaultColor,
            bold: !!this.detailStyleDraft.bold,
            italic: !!this.detailStyleDraft.italic,
            underline: !!this.detailStyleDraft.underline,
            labelPosition: this.detailStyleDraft.labelPosition || 'above',
            labelMode: this.detailStyleDraft.labelMode || 'fieldLabel',
            customLabel: this.detailStyleDraft.customLabel || '',
            labelIcon: this.detailStyleDraft.labelIcon || 'utility:info'
        };
        this.form = {
            ...this.form,
            detailFields: next
        };
        this.closeDetailStyleModal();
    }


    handleIconUpload(event) {
        const file = event.target.files && event.target.files[0];
        if (!file) {
            return;
        }
        this.readFileAsBase64(file)
            .then((base64Data) => {
                this.isLoading = true;
                return uploadBannerImage({
                    fileName: file.name,
                    base64Data
                });
            })
            .then((uploadedUrl) => {
                this.form = {
                    ...this.form,
                    iconType: 'uploaded',
                    iconValue: uploadedUrl
                };
                this.showToast('Banner settings', 'Image uploaded successfully.', 'success');
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleDetailLabelIconUpload(event) {
        const file = event.target.files && event.target.files[0];
        if (!file) {
            return;
        }
        this.readFileAsBase64(file)
            .then((base64Data) => {
                this.isLoading = true;
                return uploadBannerImage({
                    fileName: file.name,
                    base64Data
                });
            })
            .then((uploadedUrl) => {
                this.detailStyleDraft = {
                    ...this.detailStyleDraft,
                    labelIcon: uploadedUrl,
                    labelMode: 'icon'
                };
                this.showToast('Banner settings', 'Label image uploaded successfully.', 'success');
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
                event.target.value = '';
            });
    }

    handleOpenSetting(event) {
        const developerName = event.currentTarget.dataset.id;
        if (!developerName) {
            return;
        }
        this.loadSettingByDeveloperName(developerName);
    }

    loadSettingByDeveloperName(developerName) {
        this.isLoading = true;
        getObjectSetupData({ objectApiName: null, developerName })
            .then((response) => {
                const editorData = JSON.parse(response || '{}');
                const record = editorData.setting || {};
                this.draftEditorActive = false;
                this.fieldOptions = this.sortOptionsByLabel(editorData.fieldOptions || []);
                this.actionOptions = editorData.actionOptions || [];
                this.applyFormFromRecord(record);
                this.selectedDeveloperName = record.developerName || '';
                this.selectedBannerLabel = record.masterLabel || '';
                this.loadDetailFieldExplorer('');
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
                if (this.shouldShowWorkspace) {
                    this.captureFormBaseline();
                }
            });
    }

    handleNew() {
        this.newBannerDraft = { masterLabel: '', objectApiName: '' };
        this.showNewBannerModal = true;
    }

    cancelNewBannerModal() {
        this.showNewBannerModal = false;
    }

    handleCancelEdit() {
        this.selectedDeveloperName = '';
        this.selectedBannerLabel = '';
        this.form = this.createDefaultForm();
        this.draftEditorActive = false;
        this.selectedAvailableActionApiNames = [];
        this.selectedChosenActionApiNames = [];
        this.detailAvailableOptions = [];
        this.detailReferenceOptions = [];
        this.detailReferencePath = '';
        this.detailSearchTerm = '';
        this.selectedAvailableDetailValues = [];
        this.selectedReferenceDetailValues = [];
        this.detailReferenceSearchTerm = '';
        this.selectedDetailFieldIndices = [];
        this.captureFormBaseline();
    }

    handleNewBannerFieldChange(event) {
        const field = event.currentTarget.dataset.field;
        if (field !== 'masterLabel') {
            return;
        }
        this.newBannerDraft = {
            ...this.newBannerDraft,
            masterLabel: event.detail.value
        };
    }

    handleNewBannerObjectChange(event) {
        this.newBannerDraft = {
            ...this.newBannerDraft,
            objectApiName: event.detail.value || ''
        };
    }

    confirmNewBannerModal() {
        const label = (this.newBannerDraft.masterLabel || '').trim();
        const objectApiName = this.newBannerDraft.objectApiName || '';
        if (!label) {
            this.showToast('Banner settings', 'Banner label is required.', 'warning');
            return;
        }
        if (!objectApiName) {
            this.showToast('Banner settings', 'Object is required.', 'warning');
            return;
        }
        const developerName = this.suggestDeveloperName(label);
        if (!developerName) {
            this.showToast('Banner settings', 'Could not derive a developer name from the banner label.', 'warning');
            return;
        }
        this.isSaving = true;
        this.isLoading = true;
        saveBannerSetting({
            developerName,
            masterLabel: label,
            objectApiName,
            titleFieldApiName: '',
            subtitleFieldApiName: '',
            detailFieldsJson: '[]',
            selectedActionsJson: '[]',
            iconSource: 'standard',
            iconValue: 'standard:record',
            iconSize: '30px',
            backgroundColor: '#ffffff',
            textColor: '#16325c',
            displayMode: 'horizontal',
            numberOfFieldsDisplay: 3,
            type: 'Record',
            isActive: true
        })
            .then((jobId) => {
                this.form = {
                    ...this.createDefaultForm(),
                    masterLabel: label,
                    developerName,
                    objectApiName
                };
                const optimisticItem = {
                    developerName,
                    masterLabel: label,
                    objectApiName,
                    titleFieldApiName: '',
                    subtitleFieldApiName: '',
                    detailFieldsJson: '[]',
                    selectedActionsJson: '[]',
                    iconSource: 'standard',
                    iconValue: 'standard:record',
                    iconSize: '30px',
                    backgroundColor: '#ffffff',
                    textColor: '#16325c',
                    displayMode: 'horizontal',
                    numberOfFieldsDisplay: 3,
                    type: 'Record',
                    isActive: true
                };
                this.savedSettings = [
                    optimisticItem,
                    ...this.savedSettings.filter((item) => item.developerName !== developerName)
                ];
                this.selectedDeveloperName = developerName;
                this.selectedBannerLabel = label;
                this.draftEditorActive = false;
                this.showNewBannerModal = false;
                this.captureFormBaseline();
                this.showToast('Banner settings', `Banner created. Deployment job: ${jobId}`, 'success');
                return this.loadObjectDependencies(objectApiName);
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
                this.isLoading = false;
            });
    }

    suggestDeveloperName(label) {
        if (!label || !String(label).trim()) {
            return '';
        }
        const baseName = String(label).trim();
        let normalized = baseName.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '_').replace(/_+/g, '_');
        normalized = normalized.replace(/^_+|_+$/g, '');
        if (!normalized) {
            normalized = 'Banner_Setting';
        }
        if (!/^[A-Za-z]/.test(normalized)) {
            normalized = `B_${normalized}`;
        }
        return normalized.slice(0, 40);
    }

    handleSave() {
        if (!this.isFormDirty) {
            return;
        }
        if (!this.form.masterLabel || !this.form.objectApiName) {
            this.showToast('Banner settings', 'Banner name, object and title field are required.', 'error');
            return;
        }

        const detailFields = this.form.detailFields
            .filter((item) => !!item.fieldApiName)
            .map((item) => ({
                fieldApiName: item.fieldApiName,
                color: item.color,
                bold: !!item.bold,
                italic: !!item.italic,
                underline: !!item.underline,
                labelPosition: item.labelPosition || 'above',
                labelMode: item.labelMode || 'fieldLabel',
                customLabel: item.customLabel || '',
                labelIcon: item.labelIcon || 'utility:info'
            }));

        const selectedActionsPayload = {
            quickActions: this.form.selectedActionApiNames || [],
            screenFlows: (this.form.screenFlows || []).map((item) => ({
                value: item.value || '',
                label: item.label || '',
                redirectionType: item.redirectionType || 'Flow',
                icon: item.icon || '',
                displayType: item.displayType || 'Action'
            }))
        };

        this.isSaving = true;
        const resolvedDeveloperName = this.getResolvedDeveloperName();
        saveBannerSetting({
            developerName: this.form.developerName,
            masterLabel: this.form.masterLabel,
            objectApiName: this.form.objectApiName,
            titleFieldApiName: this.form.titleFieldApiName,
            subtitleFieldApiName: this.form.subtitleFieldApiName,
            detailFieldsJson: JSON.stringify(detailFields),
            selectedActionsJson: JSON.stringify(selectedActionsPayload),
            iconSource: this.form.iconType,
            iconValue: this.form.iconValue,
            iconSize: this.form.iconSize || '30px',
            backgroundColor: this.form.backgroundColor,
            textColor: this.form.textColor,
            type: 'Record',
            displayMode: this.form.displayMode,
            numberOfFieldsDisplay: Number(this.form.numberOfFieldsDisplay) || 1,
            isActive: this.form.isActive
        })
            .then((jobId) => {
                const optimisticItem = {
                    developerName: resolvedDeveloperName,
                    masterLabel: this.form.masterLabel,
                    objectApiName: this.form.objectApiName,
                    titleFieldApiName: this.form.titleFieldApiName,
                    subtitleFieldApiName: this.form.subtitleFieldApiName,
                    detailFieldsJson: JSON.stringify(detailFields),
                    selectedActionsJson: JSON.stringify(selectedActionsPayload),
                    iconSource: this.form.iconType,
                    iconValue: this.form.iconValue,
                    iconSize: this.form.iconSize || '30px',
                    backgroundColor: this.form.backgroundColor,
                    textColor: this.form.textColor,
                    displayMode: this.form.displayMode,
                    numberOfFieldsDisplay: Number(this.form.numberOfFieldsDisplay) || 1,
                    type: 'Record',
                    isActive: this.form.isActive
                };
                this.savedSettings = [
                    optimisticItem,
                    ...this.savedSettings.filter((item) => item.developerName !== resolvedDeveloperName)
                ];
                this.form = {
                    ...this.form,
                    developerName: resolvedDeveloperName
                };
                this.selectedDeveloperName = resolvedDeveloperName;
                this.selectedBannerLabel = this.form.masterLabel || '';
                this.draftEditorActive = false;
                this.captureFormBaseline();
                this.showToast('Banner settings', `Banner saved. Deployment job: ${jobId}`, 'success');
            })
            .catch((error) => {
                this.showToast('Banner settings', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    applyFormFromRecord(record) {
        const detailFields = JSON.parse(record.detailFieldsJson || '[]');
        const parsedActions = JSON.parse(record.selectedActionsJson || '[]');
        const selectedActions = Array.isArray(parsedActions)
            ? parsedActions
            : parsedActions?.quickActions || [];
        const rawScreenFlows = Array.isArray(parsedActions)
            ? []
            : parsedActions?.screenFlows || [];
        this.form = {
            developerName: record.developerName || '',
            masterLabel: record.masterLabel || '',
            objectApiName: record.objectApiName || '',
            titleFieldApiName: record.titleFieldApiName || '',
            subtitleFieldApiName: record.subtitleFieldApiName || '',
            iconType: record.iconSource || 'standard',
            iconValue: record.iconValue || 'standard:record',
            iconSize: record.iconSize || '30px',
            backgroundColor: record.backgroundColor || '#ffffff',
            textColor: record.textColor || '#16325c',
            displayMode: record.displayMode || 'horizontal',
            numberOfFieldsDisplay: Number(record.numberOfFieldsDisplay) || 1,
            selectedActionApiNames: selectedActions || [],
            screenFlows: (rawScreenFlows || []).map((item, index) =>
                this.withRedirectionState(
                    {
                        value: item.value || '',
                        label: item.label || '',
                        icon: item.icon || '',
                        redirectionType: item.redirectionType || 'Flow',
                        displayType: item.displayType || 'Action'
                    },
                    `saved_flow_${record.developerName || 'new'}_${index}`
                )
            ),
            detailFields:
                detailFields && detailFields.length
                    ? detailFields.map((item, index) => ({
                        key: `saved_${record.developerName || 'new'}_${index}`,
                        color: this.defaultColor,
                        bold: false,
                        italic: false,
                        underline: false,
                        labelPosition: 'above',
                        labelMode: 'fieldLabel',
                        customLabel: '',
                        labelIcon: 'utility:info',
                        ...item
                    }))
                    : [this.createDetailField()],
            isActive: record.isActive !== false
        };
        this.refreshScreenFlowOptions();
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const result = reader.result || '';
                resolve(String(result).split(',')[1] || '');
            };
            reader.onerror = () => reject(new Error('Unable to read file.'));
            reader.readAsDataURL(file);
        });
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'Unexpected error.';
    }

    getResolvedDeveloperName() {
        const baseName = (this.form.developerName || this.form.masterLabel || 'Banner_Setting').trim();
        return this.suggestDeveloperName(baseName) || 'Banner_Setting';
    }

  showToast(title, message, variant ='info', mode ='dismissable') {
        Toast.show({
            label: title,
            message: message,
            variant: variant,
            mode: mode
            },this);
    }

}