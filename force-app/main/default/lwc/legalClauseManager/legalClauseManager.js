import { LightningElement, api, track } from 'lwc';
import { Labels, RESOURCES, ICONS, LegalDoc_API, LegalDocClause_API, TrackAction_API, Supplier_API, GlobalLocation_API, COD_API, Contact_API } from './properties.js';
import { clauseBoFieldMap, docBoFieldMap, docBoFieldList } from './properties.js';
import { generatePdf, exportWord, formatDateForFilename } from './exportUtils.js';
import { loadScript } from 'lightning/platformResourceLoader';
import initData from '@salesforce/apex/LegalClauseManagerCtrl.initData';
import loadData from '@salesforce/apex/LegalClauseManagerCtrl.loadData';
import getMergeObjects from '@salesforce/apex/LegalClauseManagerCtrl.getMergeObjects';
import changeCommentStatus from '@salesforce/apex/LegalClauseManagerCtrl.changeCommentStatus';
import saveGlobalVariables from '@salesforce/apex/LegalClauseManagerCtrl.saveGlobalVariables';
import saveClauses from '@salesforce/apex/LegalClauseManagerCtrl.saveClauses';
import getFilteredSuppliers from '@salesforce/apex/LegalClauseManagerCtrl.getFilteredSuppliers';
import sendToSuppliers from '@salesforce/apex/LegalClauseManagerCtrl.sendToSuppliers';
import sendToBusinessOwner from '@salesforce/apex/LegalClauseManagerCtrl.sendToBusinessOwner';
import publishAllDrafts from '@salesforce/apex/LegalClauseManagerCtrl.publishAllDrafts';
import validateAllClauses from '@salesforce/apex/LegalClauseManagerCtrl.validateAllClauses';
import approveAllClauses from '@salesforce/apex/LegalClauseManagerCtrl.approveAllClauses';
import deleteLegalDocumentClauses from '@salesforce/apex/LegalClauseManagerCtrl.deleteLegalDocumentClauses';
import publishBOLegalComments from '@salesforce/apex/LegalClauseManagerCtrl.publishBOLegalComments';
import { showNotification } from 'c/appHelper';
export default class LegalClauseManager extends LightningElement {
    Labels = {
        ...Labels,
        LegalDoc__c: {},
        LegalDocClause__c: {},
    };
    ICONS = ICONS;
    jsPdfLoaded = false;
    isExportingPdf = false;
    docxLibLoaded = false;
    diffLibLoaded = false;
    dmp = null;
    clauseBoFieldMap = clauseBoFieldMap;
    docBoFieldMap = docBoFieldMap;
    docBoFieldList = docBoFieldList;
    LegalDoc_API = LegalDoc_API;
    LegalDocClause_API = LegalDocClause_API;
    @api recordId;
    @api isPortalUser;
    @track isLegal = false;
    // Data from wrapper
    @track legalDoc = {};
    @track clauses = [];
    @track allClauses = [];
    @track displayClauses = [];
    clausesVersions = [];
    @track selectedIdsToDelete = [];
    @track picklistValues = {};
    @track fieldLabels = {
        LegalDoc__c: {},
        LegalDocClause__c: {},
        Supplier__c: {},
        Contact: {}
    };

    @track acceptedByTwo = false;
    @track showBOCommentIcon = false;
    @track showSupCommentIcon = false;
    @track stopPortalFromPubslish = false;
    @track newClause = {};

    // UI State
    isLoading = true;
    isAddingNewClause = false;
    showSupplierModal = false;
    showContactModal = false;
    modalConfig = {
        isOpen: false,
        title: '',
        message: '',
        confirmLabel: '',
        onConfirmAction: null,
        onCloseAction: null
    };
    @track openChatterClauseId = null;
    @track selectedFieldInfo = null;
    selectedClauseToDelete = null;
    @track openChatterType = null;
    firstLoad = false;
    selectedClauseToSave = null;
    saveType = null; // 'full' or 'simple'
    @track isEditingNewVersionMap = {}; // Track edit mode per clause
    @track expandedClauseIds = []; // Array for multiple expanded clauses

    @track selectedCompareVersionIds = {}; // Track per clause 
    // Drag and drop state
    @track hasOrderChanged = false;
    @track originalOrder = [];
    draggedClauseId = null;
    clauseId = null;
    legalDocType = '';
    legalDocMarket = '';
    legalDocLanguage = '';
    @track allSuppliers = [];
    @track filteredSuppliers = [];
    @track filteredContacts = [];
    @track selectedSupplierIds = [];
    @track existingSupplierIds = [];
    @track hasSuppliers = false;
    @track hasContacts = false;
    supplierSearchTerm = '';
    contactSearchTerm = '';
    isLoadingSuppliers = false;
    @track contactGridSettings = {};
    @track supplierGridSettings = {};
    @track supplierGridFields = [];
    @track contactGridFields = [];
    @track userMap = [];
    @track notifType = {};
    @track selectedBusinessOwners = ['Legal'];
    noFilterValue = '__none__';
    @track pageFilters = {
        statusFilter: this.noFilterValue,
        commentFilter: this.noFilterValue,
        ownedByUser: true
    }

    @track trackActions = {};
    @track supplierAccount = '';
    @track currentUser = {};
    @track isBOUser = false;

    @track boType = '';
    @track totalSupplierCount = 0;
    @track legalDocStatusSteps = [];

    @track isMergeFieldModalOpen = false;
    @track activeClauseId;
    @track savedSelection;
    @track selectedObject = null;
    @track selectedField = null;
    @track selectedFieldInfo = null;
    @track mergeObjects = [];
    @track changedGlobalVariables = {};
    @track internalSignatoryInfo;
    @track supplierSignaotoryInfo;
    @track adminGL;
    @track showGlobalVariablesPopup = false;
    @track statusOptions = [];
    @track objectOptions = [];
    @track fieldOptions = [];
    commentFilterOptions = [
        { label: this.Labels.LBL_None, value: this.noFilterValue },
        { label: this.Labels.LBL_LD_OnlyWithComment, value: 'withComments' }
    ];
    STATUS_BADGE_MAP = {
        'draft': 'badge-draft',
        'published': 'badge-published-supplier',
        'supplier publishing': 'badge-published-supplier',
        'legal publishing': 'badge-published-legal',
        'validated': 'badge-validated',
        'approved': 'badge-approved',
        'open': 'badge-warning',
        'rejected': 'badge-rejected'
    };
    TEXT_TYPE_CLASS_MAP = {
        title: 'clause-text-title',
        subtitle: 'clause-text-subtitle',
        body: 'clause-text-body'
    };
    get allComments() {
        let all = [];
        this.displayClauses?.forEach(element => {
            element?.relatedActivities?.forEach(a => {
                all.push(a);
            });
        });
        return all;
    }

    // Lifecycle
    connectedCallback() {
        this.loadDiffLibrary();
        this.loadPdfLibrary();
        this.loadDocxLibrary();
        this.initData();
        const style = document.createElement('style');
        style.innerText = `
                .badge-published-legal.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                    background-color: #009688 !important;
                }
                .badge-draft.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #ff9800 !important;
                }
                .badge-published-supplier.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #9c27b0 !important;
                }
                .badge-validated.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #00bcd4 !important;
                }
                .badge-validated-supplier.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #3F51B5 !important;
                }
                .badge-approved.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #4caf50 !important;
                }
                .badge-rejected .slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #f44336 !important;
                }
                .badge-warning.slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #ffc107 !important;
                }
                .badge-default .slds-badge_lightest.slds-badge.slds-badge:not(.active-btn):not(.inactive-btn) {
                background-color: #9e9e9e !important;
                }
            `;
        document.body.appendChild(style);
    }

    async loadDiffLibrary() {
        if (this.diffLibLoaded) return;
        try {
            await loadScript(this, RESOURCES.DIFF_MATCH_PATCH);
            if (typeof diff_match_patch !== 'undefined') {
                this.dmp = new diff_match_patch();
                this.diffLibLoaded = true;
            }
        } catch (error) {
            console.error('Error loading diff_match_patch:', error);
        }
    }

    async loadDocxLibrary() {
        if (this.docxLibLoaded) return;
        try {
            await loadScript(this, RESOURCES.DOCX_LIB);
            this.docxLibLoaded = true;
        } catch (error) {
            console.error('Error loading docx library:', error);
        }
    }

    async loadPdfLibrary() {
        if (this.jsPdfLoaded) return;
        try {
            await loadScript(this, RESOURCES.JSPDF);
            this.jsPdfLoaded = true;
        } catch (error) {
            console.error('Error loading jsPDF:', error);
        }
    }
    initData() {
        this.isLoading = true;
        initData({ recordId: this.recordId })
            .then(result => {
                let data = JSON.parse(result);
                this.currentUser = data.currentUser;
                this.isBOUser = data.isBOUser;
                this.notifType = data.notifType;
                this.boType = data?.boType || 'Legal';
                this.isLegal = data.isLegal;
                this.picklistValues = data.objectPicklistMap;
                this.adminGL = data.adminGL;
                this.internalSignatoryInfo = data.internalSignatoryInfo;
                this.userMap = data.userMap;
                this.setupLabels(data.fieldsMap);
                this.statusOptions = [{ label: this.Labels.LBL_None, value: this.noFilterValue }];
                this.picklistValues[this.LegalDocClause_API.LegalDocClause__c][this.LegalDocClause_API.Status__c]?.forEach(option => (
                    this.statusOptions.push({
                        label: option.label,
                        value: option.value
                    }))
                );
                this.legalDocStatusSteps = this.picklistValues[LegalDoc_API.LegalDoc_c][LegalDoc_API.Status__c]?.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                this.clauseTypeOptions = this.picklistValues[this.LegalDocClause_API.LegalDocClause__c][LegalDocClause_API.ClauseType__c]?.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                this.businessOwnerOptions = this.picklistValues[this.LegalDocClause_API.LegalDocClause__c][LegalDocClause_API.BusinessOwners__c]?.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                if (data.contactGrid) {
                    this.contactGridSettings = data.contactGrid.gridSettings || {};
                    this.buildContactGridFields();
                    this.allContacts = this.buildContactData(data.contactGrid.cod || []);
                    this.filteredContacts = [...this.allContacts];
                } else {
                    this.allContacts = [];
                    this.filteredContacts = [];
                }
                if (this.isBOUser && !this.firstLoad) {
                    this.pageFilters.statusFilter = 'published';
                    this.pageFilters.ownedByUser = true;
                    this.firstLoad = true;
                }
                this.loadData();
            }).catch(error => {
                this.isLoading = false;
                console.error('Error init data: ' + error?.message || error);
                console.error('Error init data:', error?.message || error);
                console.error('Error body:' + error?.body?.message);
            })
    }
    loadData() {
        this.isLoading = true;
        this.allClauses = [];
        this.clauses = [];
        if (!this.recordId) {
            console.error('No recordId provided');
            this.isLoading = false;
            return;
        }
        let userType = this.isPortalUser ? 'portal' : (this.isBOUser ? 'businessowner' : 'legal');
        loadData({
            recordId: this.recordId,
            statusFilter: this.pageFilters.statusFilter === this.noFilterValue ? '' : this.pageFilters.statusFilter,
            userType: userType
        }).then(result => {
            const data = JSON.parse(result);
            this.supplierSignaotoryInfo = data.supplierSignaotoryInfo;
            let legalDocRecord = data.legalDoc;
            this.legalDoc = {
                ...legalDocRecord,
                createdByLink: '/' + legalDocRecord[LegalDoc_API.CreatedById],
                whoValidateLink: '/' + legalDocRecord?.[LegalDoc_API.WhoValidated__c],
                whoApprovedLink: '/' + legalDocRecord?.[LegalDoc_API.WhoApproved__c],
                HasNoSalesTerms: legalDocRecord?.[LegalDoc_API.HasNoSalesTerms__c] === 'true',
                get _Year__c() { return this[LegalDoc_API.Year__c]; },
                get _HasNoSalesTerms__c() { return this[LegalDoc_API.HasNoSalesTerms__c]; },
                get _LegalLastPublishDate__c() { return this[LegalDoc_API.LegalLastPublishDate__c]; },
                get _LegalLastModifyDate__c() { return this[LegalDoc_API.LegalLastModifyDate__c]; },
                get _LegalValidateDate__c() { return this[LegalDoc_API.LegalValidateDate__c]; },
                get _LegalApproveDate__c() { return this[LegalDoc_API.LegalApproveDate__c]; },
                get _BusinessOwnerValidateDate__c() { return this[LegalDoc_API.BusinessOwnerValidateDate__c]; },
                get _BusinessOwnerApproveDate__c() { return this[LegalDoc_API.BusinessOwnerApproveDate__c]; },
                get _DateSentToSupplier__c() { return this[LegalDoc_API.DateSentToSupplier__c]; },
                get _PartnerLastModifyDate__c() { return this[LegalDoc_API.PartnerLastModifyDate__c]; },
                get _PartnerLastPublishDate__c() { return this[LegalDoc_API.PartnerLastPublishDate__c]; },
                get _PartnerValidateDate__c() { return this[LegalDoc_API.PartnerValidateDate__c]; },
                get _WhoValidated__c() { return this[LegalDoc_API.WhoValidated__c]; },
                get _WhoValidatedName__c() { return this[LegalDoc_API.WhoValidated__r]?.Name; },
                get _BusinessOwnerLastModifyDate__c() { return this[LegalDoc_API.BusinessOwnerLastModifyDate__c]; },
                get _BusinessOwnerLastPublishDate__c() { return this[LegalDoc_API.BusinessOwnerLastPublishDate__c]; },
                get _DateSentToSupplier__c() { return this[LegalDoc_API.DateSentToSupplier__c]; },
                get _Status__c() { return this[LegalDoc_API.Status__c]; },
                get _LegalApproveDate__c() { return this[LegalDoc_API.LegalApproveDate__c]; },
                get _LegalValidateDate__c() { return this[LegalDoc_API.LegalValidateDate__c]; }
            }
            let typeOptions = this.picklistValues[LegalDoc_API.LegalDoc_c][LegalDoc_API.Type__c];
            let marketOptions = this.picklistValues[LegalDoc_API.LegalDoc_c][LegalDoc_API.Market__c];
            let langaugeOptions = this.picklistValues[LegalDoc_API.LegalDoc_c][LegalDoc_API.Language__c];
            this.legalDocType = typeOptions?.find(opt => opt.value === this.legalDoc?.[LegalDoc_API.Type__c])?.label || '';
            this.legalDocMarket = marketOptions?.find(opt => opt.value === this.legalDoc?.[LegalDoc_API.Market__c])?.label || '';
            this.legalDocLanguage = langaugeOptions?.find(opt => opt.value === this.legalDoc?.[LegalDoc_API.Language__c])?.label || '';
            if (!this.isPortalUser && !this.isLegal && !this.isBOUser) {
                this.isLegal = true;
            }
            this.showBOCommentIcon = this.isBOUser || this.isLegal;
            this.showSupCommentIcon = this.isPortalUser || this.isLegal || this.isBOUser;
            this.acceptedByTwo = this.legalDoc?.[LegalDoc_API.Status__c] === 'Approved' && this.legalDoc?.[LegalDoc_API.PartnerStatus__c] === 'Approved';
            this.supplierAccount = data?.legalDoc?.[LegalDoc_API.Supplier__r]?.[Supplier_API.Account__c] || '';
            this.trackActions = data.trackActionbyClause;
            this.allClauses = data.legalDocClauseList;
            console.log('Loaded clauses:', JSON.stringify(this.allClauses));
            this.clauses = this.buildClausesWrapper();
            this.applyClauseFilters();
            this.hasOrderChanged = false;
            this.originalOrder = [];
            this.loadMergeObjects();
            this.isLoading = false;
        }).catch(error => {
            this.isLoading = false;
            console.error('Error loading data: ' + error?.message || error);
            console.error('Error loading data:', error?.message || error);
            console.error('Error body:' + error?.body?.message);
            showNotification(this, this.Labels.LBL_Error, error.message, 'error');
            this.allClauses = [];
            this.clauses = [];
        }).finally(() => {
            this.isLoading = false;
        });
    }

    setupLabels(fieldsMap) {
        // //SET UP LABELS
        let legalDocFields = fieldsMap[LegalDoc_API.LegalDoc_c];
        let legalDocClauseFields = fieldsMap[LegalDocClause_API.LegalDocClause__c];
        let supplierFields = fieldsMap[Supplier_API.Supplier__c];
        let contactFields = fieldsMap[Contact_API.Contact__c];
        this.fieldLabels.LegalDoc__c.CreatedById = legalDocFields[LegalDoc_API.CreatedById]?.label?.replace(/\bID\b/i, '').replace('c', 'C');
        this.Labels.LBL_LD_OwnProperty = legalDocClauseFields[this.LegalDocClause_API.OwnerId]?.label?.replace('ID', this.Labels.LBL_Name);
        this.fieldLabels.LegalDoc__c.Year__c = legalDocFields[LegalDoc_API.Year__c]?.label;
        this.fieldLabels.LegalDoc__c.Type__c = legalDocFields[LegalDoc_API.Type__c]?.label;
        this.fieldLabels.LegalDoc__c.Market__c = legalDocFields[LegalDoc_API.Market__c]?.label;
        this.fieldLabels.LegalDoc__c.Language__c = legalDocFields[LegalDoc_API.Language__c]?.label;
        this.fieldLabels.LegalDoc__c.Status__c = legalDocFields[LegalDoc_API.Status__c]?.label;
        this.fieldLabels.LegalDoc__c.PartnerStatus__c = legalDocFields[LegalDoc_API.PartnerStatus__c]?.label;
        this.fieldLabels.LegalDoc__c.Name = legalDocFields[LegalDoc_API.Name]?.label;
        this.fieldLabels.LegalDoc__c.CreatedDate = legalDocFields[LegalDoc_API.CreatedDate]?.label;
        this.fieldLabels.LegalDoc__c.LastModifiedDate = legalDocFields[LegalDoc_API.LastModifiedDate]?.label;
        this.fieldLabels.LegalDoc__c.Supplier__c = legalDocFields[LegalDoc_API.Supplier__c]?.label;
        this.fieldLabels.LegalDoc__c.DateSentToSupplier__c = legalDocFields[LegalDoc_API.DateSentToSupplier__c]?.label;
        this.fieldLabels.LegalDoc__c.LegalLastPublishDate__c = legalDocFields[LegalDoc_API.LegalLastPublishDate__c]?.label;
        this.fieldLabels.LegalDoc__c.PartnerLastModifyDate__c = legalDocFields[LegalDoc_API.PartnerLastModifyDate__c]?.label;
        this.fieldLabels.LegalDoc__c.PartnerLastPublishDate__c = legalDocFields[LegalDoc_API.PartnerLastPublishDate__c]?.label;
        this.fieldLabels.LegalDoc__c.PartnerValidateDate__c = legalDocFields[LegalDoc_API.PartnerValidateDate__c]?.label;
        this.fieldLabels.LegalDoc__c.PartnerApproveDate__c = legalDocFields[LegalDoc_API.PartnerApproveDate__c]?.label;
        this.fieldLabels.LegalDoc__c.LegalLastModifyDate__c = legalDocFields[LegalDoc_API.LegalLastModifyDate__c]?.label;
        this.fieldLabels.LegalDoc__c.LegalValidateDate__c = legalDocFields[LegalDoc_API.LegalValidateDate__c]?.label;
        this.fieldLabels.LegalDoc__c.LegalApproveDate__c = legalDocFields[LegalDoc_API.LegalApproveDate__c]?.label;
        this.fieldLabels.LegalDoc__c.BusinessOwnerLastModifyDate__c = legalDocFields[LegalDoc_API.BusinessOwnerLastModifyDate__c]?.label;
        this.fieldLabels.LegalDoc__c.BusinessOwnerLastPublishDate__c = legalDocFields[LegalDoc_API.BusinessOwnerLastPublishDate__c]?.label;
        this.fieldLabels.LegalDoc__c.BusinessOwnerValidateDate__c = legalDocFields[LegalDoc_API.BusinessOwnerValidateDate__c]?.label;
        this.fieldLabels.LegalDoc__c.BusinessOwnerApproveDate__c = legalDocFields[LegalDoc_API.BusinessOwnerApproveDate__c]?.label;
        this.fieldLabels.LegalDoc__c.HasNoSalesTerms__c = legalDocFields[LegalDoc_API.HasNoSalesTerms__c]?.label;
        this.fieldLabels.LegalDoc__c.WhoValidated__c = legalDocFields[LegalDoc_API.WhoValidated__c]?.label;
        this.fieldLabels.LegalDoc__c.ValidationDate__c = legalDocFields[LegalDoc_API.ValidationDate__c]?.label;
        this.fieldLabels.LegalDoc__c.WhoApproved__c = legalDocFields[LegalDoc_API.WhoApproved__c]?.label;
        this.fieldLabels.LegalDoc__c.ApproveDate__c = legalDocFields[LegalDoc_API.ApproveDate__c]?.label;
        this.fieldLabels.LegalDocClause__c.Status__c = legalDocClauseFields[this.LegalDocClause_API.Status__c]?.label;
        this.fieldLabels.LegalDocClause__c.LegalStatus__c = legalDocClauseFields[this.LegalDocClause_API.LegalStatus__c]?.label;
        this.fieldLabels.LegalDocClause__c.PartnerStatus__c = legalDocClauseFields[this.LegalDocClause_API.PartnerStatus__c]?.label;
        this.fieldLabels.LegalDocClause__c.BusinessStatus__c = legalDocClauseFields[this.LegalDocClause_API.BusinessStatus__c]?.label;
        this.fieldLabels.LegalDocClause__c.UpdateOrigin__c = legalDocClauseFields[this.LegalDocClause_API.UpdateOrigin__c]?.label;
        this.fieldLabels.LegalDocClause__c.ClauseType__c = legalDocClauseFields[this.LegalDocClause_API.ClauseType__c]?.label;
        this.fieldLabels.LegalDocClause__c.BusinessOwners__c = legalDocClauseFields[this.LegalDocClause_API.BusinessOwners__c]?.label;
        this.fieldLabels.LegalDocClause__c.Clause__c = legalDocClauseFields[this.LegalDocClause_API.Clause__c]?.label;
        this.fieldLabels.LegalDocClause__c.DisplayOrder__c = legalDocClauseFields[this.LegalDocClause_API.DisplayOrder__c]?.label;
        this.fieldLabels.LegalDocClause__c.IsNegotiable__c = legalDocClauseFields[this.LegalDocClause_API.IsNegotiable__c]?.label;
        this.fieldLabels.Supplier__c.Signatory__c = supplierFields[Supplier_API.Signatory__c]?.label;
        this.fieldLabels.Contact.MainFrameworkSignatory__c = contactFields[Contact_API.MainFrameworkSignatory__c]?.label;
    }
    buildClausesWrapper() {
        if (!this.allClauses || this.allClauses.length === 0) return [];
        let clausesToShow = [...this.allClauses];
        let olderVersionIds = new Set();
        clausesToShow.forEach(clause => {
            if (clause[LegalDocClause_API.Status__c]?.toLowerCase() === 'rejected') {
                olderVersionIds.add(clause.Id);
            }
            if (clause[LegalDocClause_API.LegalDocClauseP1__c]) {
                olderVersionIds.add(clause[LegalDocClause_API.LegalDocClauseP1__c]);
            }
            if (clause[LegalDocClause_API.LegalDocClauseField__c] && clause[LegalDocClause_API.LegalDocClauseField__c] !== clause.Id) {
                olderVersionIds.add(clause[LegalDocClause_API.LegalDocClauseField__c]);
            }
        });
        this.clausesVersions = olderVersionIds;
        clausesToShow = clausesToShow.filter(clause => !olderVersionIds.has(clause.Id));
        clausesToShow = clausesToShow.map(clause => {
            const status = (clause?.[LegalDocClause_API.Status__c] || '');
            const legalStatus = (clause?.[LegalDocClause_API.LegalStatus__c] || '');
            const isNegotiable = clause?.[LegalDocClause_API.IsNegotiable__c] === true;
            const businessOwners = clause?.[LegalDocClause_API.BusinessOwners__c]?.split(';') || [];
            const isAssignedBO = businessOwners.includes(this.boType);
            const isOwnBODraft = clause?.[LegalDocClause_API.UpdateOrigin__c] === 'BusinessOwner' && clause?.[LegalDocClause_API.Updatedby__c] === this.currentUser.Id;
            let isNotEditable = false;
            let boHasDraft = false;
            let validate = false;
            let showSimpleEdit = false;
            let isExpanded = false;
            let hasComments = false;
            let relatedComments = this.trackActions?.[clause.Id] || [];
            /* Editability */
            if (!this.isMyTurn) {
                isNotEditable = true;
            } else {
                if (this.isBOUser && (!isAssignedBO || !isOwnBODraft && clause?.[LegalDocClause_API.UpdateOrigin__c] === 'BusinessOwner')) {
                    isNotEditable = true;
                }
                else if (this.isLegal && legalStatus === 'approved') {
                    isNotEditable = true;
                }
                else if (this.hasSupplier && !isNegotiable && !this.isLegal) {
                    isNotEditable = true;
                } else if (status === 'approved') {
                    isNotEditable = true;
                }
            }
            if (!this.hasSupplier) {
                isNotEditable = false;
            }
            /* BO Draft Indicator */
            if (this.isBOUser && this.clauseBoFieldMap[this.boType] != null && !clause[this.clauseBoFieldMap[this.boType]]) {
                boHasDraft = true;
            }
            /* Validation */
            if (this.isMyTurn) {
                if (this.isPortalUser) {
                    validate = status === 'legal publishing';
                }
                else if (!this.isBOUser) {
                    validate = status === 'published';
                }
            }
            showSimpleEdit = !this.isPortalUser ? (!this.hasSupplier ? true : !isNegotiable) : false;
            if (this.isPortalUser) {
                relatedComments = relatedComments?.filter(activity => (activity[TrackAction_API.CommentOrigin__c] == 'Legal' && activity[TrackAction_API.CommentStatus__c] == 'Published') || activity[TrackAction_API.CommentOrigin__c] == 'Supplier');
            } else if (this.isBOUser) {
                relatedComments = relatedComments?.filter(activity => (activity[TrackAction_API.CommentOrigin__c] != 'Business Owner' && activity[TrackAction_API.CommentStatus__c] == 'Published') || (activity[TrackAction_API.CommentOrigin__c] == 'Business Owner' && !(activity[TrackAction_API.CommentStatus__c] === 'Draft' && activity.CreatedById && activity.CreatedById !== this.currentUser.Id)));
            } else if (this.isLegal) {
                relatedComments = relatedComments?.filter(activity => (activity[TrackAction_API.CommentOrigin__c] != 'Legal' && activity[TrackAction_API.CommentStatus__c] == 'Published') || activity[TrackAction_API.CommentOrigin__c] == 'Legal');
            }
            hasComments = relatedComments.length > 0;
            let hasSupplierComments = hasComments && relatedComments.some(activity => activity[TrackAction_API.IsPortalPublished__c] === true && activity[TrackAction_API.Comment__c]);
            let hasBOComments = hasComments && relatedComments.some(activity => !activity[TrackAction_API.IsPortalPublished__c] && activity[TrackAction_API.Comment__c]);
            // Compute version comparison data per clause
            let hasVersionsToCompare = this.computeHasVersionsToCompare(clause);
            let compareVersionOptions = this.computeCompareVersionOptions(clause);
            let selectedCompareVersionId =/* this.selectedCompareVersionIds[clause.Id] || */compareVersionOptions[1]?.value;
            // Compute version contents per clause
            let pastVersionContent = this.computePastVersionContent(clause, selectedCompareVersionId);
            let currentVersionContent = this.computeCurrentVersionContent(clause, selectedCompareVersionId);
            let newVersionContent = this.computeNewVersionContent(clause);
            let isMarkedForDeletion = !this.isPortalUser && this.selectedIdsToDelete.includes(clause.Id);
            let boCommentDisabled = isNotEditable;
            //const clauseIsDisabled = this.isBOUser ? (isNotEditable || isMarkedForDeletion || boHasDraft || !isNegotiable || status.toLowerCase() === 'approved' ) : ( isNotEditable || isMarkedForDeletion || !isNegotiable || status.toLowerCase() === 'approved');
            return {
                ...clause,
                isNotNegotiable: this.isBOUser ? (isNotEditable || isMarkedForDeletion || boHasDraft || (!clause[LegalDocClause_API.IsNegotiable__c]) || clause[LegalDocClause_API.Status__c] == 'Approved')
                    : (isNotEditable || isMarkedForDeletion) || (!clause[LegalDocClause_API.IsNegotiable__c] && this.hasSupplier && !this.isLegal) || clause[LegalDocClause_API.Status__c] == 'Approved',
                BusinessOwners: clause[LegalDocClause_API.BusinessOwners__c]?.split(';'),
                isExpanded: isExpanded,
                relatedActivities: relatedComments,
                hasComments: hasComments,
                isNotEditable: isNotEditable,
                boHasDraft: boHasDraft,
                showValidatedButton: validate,
                selectedCompareVersionId: selectedCompareVersionId,
                hasVersionsToCompare: hasVersionsToCompare,
                isCommentDisabled: this.isBOUser ? ((isNotEditable || isMarkedForDeletion || boHasDraft) && (this.legalDoc?.[LegalDoc_API.Status__c] !== 'Approved' && this.legalDoc?.[LegalDoc_API.Status__c] !== 'Ready To Sign')) : ((isNotEditable || isMarkedForDeletion) && (this.legalDoc?.[LegalDoc_API.Status__c] !== 'Approved' && this.legalDoc?.[LegalDoc_API.Status__c] !== 'Ready To Sign')),
                //boCommentDisabled: boCommentDisabled && this.legalDoc.Status__c !== 'Approved' && this.legalDoc.Status__c !== 'Ready To Sign',
                boCommentDisabled: ((isNotEditable || isMarkedForDeletion || boHasDraft) && (this.legalDoc?.[LegalDoc_API.Status__c] !== 'Approved' && this.legalDoc?.[LegalDoc_API.Status__c] !== 'Ready To Sign')),
                compareVersionOptions: compareVersionOptions,
                pastVersionContent: pastVersionContent,
                currentVersionContent: currentVersionContent,
                newVersionContent: newVersionContent,
                showSimpleEdit: showSimpleEdit,
                hasBOComments: hasBOComments,
                hasSupplierComments: hasSupplierComments,
                boCommentIconClass: hasBOComments ? 'edit-btn comment-btn comment-btn-bo has-comments-bo' : 'edit-btn comment-btn comment-btn-bo',
                supplierCommentIconClass: hasSupplierComments ? 'edit-btn comment-btn has-comments' : 'edit-btn comment-btn',
                statusClass: this.getStatusClass(clause[LegalDocClause_API.Status__c]?.toLowerCase(), clause[LegalDocClause_API.UpdateOrigin__c]?.toLowerCase()) + ' slds-badge_lightest',
                legalPublishDateClass: ((clause[LegalDocClause_API.LegalLastPublishDate__c] === this.legalDoc[LegalDoc_API.LegalLastPublishDate__c]) || this.legalDoc[LegalDoc_API.LegalLastPublishDate__c] == null) ? 'custom-badge' : '',
                showlegalPublishDate: (this.legalDoc[LegalDoc_API.Status__c] === 'Legal publishing' && clause[LegalDocClause_API.Status__c] === 'legal publishing' && clause[LegalDocClause_API.LegalLastPublishDate__c] && clause[LegalDocClause_API.IsNegotiable__c] && this.isPortalUser && clause[LegalDocClause_API.LegalLastPublishDate__c] === this.legalDoc[LegalDoc_API.LegalLastPublishDate__c]),
                supplierPublishDateClass: (clause[LegalDocClause_API.PartnerLastPublishDate__c] === this.legalDoc[LegalDoc_API.PartnerLastPublishDate__c]) ? 'custom-badge-supplier' : '',
                showSupplierPublishDate: (this.legalDoc[LegalDoc_API.Status__c] === 'Supplier publishing' && clause[LegalDocClause_API.Status__c] === 'published' && clause[LegalDocClause_API.PartnerLastPublishDate__c] && clause[LegalDocClause_API.IsNegotiable__c] && this.isLegal),
                isMarkedForDeletion: isMarkedForDeletion,
                itemClass: this.getClauseItemClass(clause),
                clauseTypeClass: this.TEXT_TYPE_CLASS_MAP[String(clause[LegalDocClause_API.ClauseType__c] ?? '').toLowerCase()] || 'clause-text-body',
                clauseTypeLabel: this.clauseTypeOptions.find(opt => opt.value === clause[LegalDocClause_API.ClauseType__c]),
                statusLabel: clause?.[LegalDocClause_API.Status__c] ? this.statusOptions.find(opt => opt.value === clause[LegalDocClause_API.Status__c]).label + ((clause?.[LegalDocClause_API.Version__c] != 0 || clause?.[LegalDocClause_API.UpdateOrigin__c] != '') ?
                    (clause[LegalDocClause_API.Updatedby__r]?.Name ? ' ' + this.Labels.LBL_LD_By + ' ' + clause[LegalDocClause_API.Updatedby__r]?.Name : ' ' + this.Labels.LBL_LD_By + ' ' + clause?.CreatedBy?.Name) : '') : '',
                businessOwnerList: clause[LegalDocClause_API.BusinessOwners__c]?.split(';').map(bo => this.picklistValues[this.LegalDocClause_API.LegalDocClause__c][this.LegalDocClause_API.BusinessOwners__c].find(p => p.value === bo.trim())?.label),
                businessOwnerValueList: clause[LegalDocClause_API.BusinessOwners__c]?.split(';'),
                boButtonClass: `edit-btn ${this.openChatterClauseId === clause.Id && this.openChatterType === 'bo' ? 'chatter-active' : ''}`,
                supplierButtonClass: `edit-btn ${this.openChatterClauseId === clause.Id && this.openChatterType === 'supplier' ? 'chatter-active' : ''}`,
                showBOCommentSection: false,
                showSUPCommentSection: false,
                showActions: true,
                get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
                get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
                get _Status__c() { return this[LegalDocClause_API.Status__c]; },
                get _SupplierLastPublishDate__c() { return this[LegalDocClause_API.PartnerLastPublishDate__c]; },
                get _LegalLastPublishDate__c() { return this[LegalDocClause_API.LegalLastPublishDate__c]; },
                editingClause: {
                    ...clause,
                    get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
                    get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
                    get _ClauseType__c() { return this[LegalDocClause_API.ClauseType__c]; },
                    get _IsNegotiable__c() { return this[LegalDocClause_API.IsNegotiable__c]; },
                    get _BusinessOwners__c() { return this[LegalDocClause_API.BusinessOwners__c]; }
                }
            }
        }).sort((a, b) => (a[LegalDocClause_API.DisplayOrder__c] || 0) - (b[LegalDocClause_API.DisplayOrder__c] || 0));
        return clausesToShow;
    }
    applyClauseFilters() {
        let clauses = [...this.clauses];
        const statusFilter = this.pageFilters.statusFilter === this.noFilterValue
            ? ''
            : this.pageFilters.statusFilter;
        const commentFilter = this.pageFilters.commentFilter === this.noFilterValue
            ? ''
            : this.pageFilters.commentFilter;
        if (statusFilter || commentFilter) {
            clauses = clauses.filter(clause => {
                let matchesCommentFilter = true;
                let matchesStatusFilter = true;
                if (commentFilter === 'withComments') {
                    const activities = this.trackActions?.[clause.Id] || [];
                    matchesCommentFilter = activities.some(activity => {
                        const hasComment = activity[TrackAction_API.Comment__c]?.trim();
                        const publishedCheck = this.isPortalUser ? activity[TrackAction_API.IsPortalPublished__c] === true : true;
                        return hasComment && publishedCheck;
                    });
                }
                if (statusFilter) {
                    matchesStatusFilter = clause[LegalDocClause_API.Status__c] === statusFilter;
                }
                return matchesCommentFilter && matchesStatusFilter;
            });
        }
        if (this.isBOUser && this.pageFilters.ownedByUser) {
            clauses = clauses.filter(clause => {
                const businessOwners = clause[LegalDocClause_API.BusinessOwners__c];
                return businessOwners?.split(';').includes(this.boType);
            });
        }
        this.displayClauses = clauses;
    }

    loadMergeObjects() {
        try {
            getMergeObjects()
                .then(result => {
                    this.mergeObjects = result;
                    this.mergeObjects.forEach(el => {
                        let record = {};
                        // Client/Supplier section
                        if (el.fieldValue.includes('Supplier')) {
                            record = this.supplierSignaotoryInfo;
                            const recordExists = record && Object.keys(record).length > 0;
                            el.wFieldWrapperList.forEach(f => {
                                f.fieldOrgValue = record && record[f.fieldAPI] ? record[f.fieldAPI] : '';
                                f.overrideValue = f.fieldOrgValue; // Initialize override with current value
                                // In portal, disable all Client/Supplier override fields (they are below Country Name)
                                f.isDisabled = this.isPortalUser ? true : !recordExists;
                            });
                        }
                        // Global Location section
                        if (el.fieldValue.includes('GlobalLocation__c')) {
                            record = this.adminGL;
                            const recordExists = record && Object.keys(record).length > 0;
                            el.wFieldWrapperList.forEach(f => {
                                f.fieldOrgValue = record && record[f.fieldAPI] ? record[f.fieldAPI] : '';
                                if (f.fieldValue.includes('Country__r.Name')) {
                                    // Country Name row: must be read‑only in portal
                                    f.fieldOrgValue = record?.[GlobalLocation_API.Country__r]?.Name || '';
                                    f.isDisabled = this.isPortalUser || !recordExists || !record?.[GlobalLocation_API.Country__r];
                                } else {
                                    // Fields above Country Name stay editable in portal if record exists
                                    f.isDisabled = !recordExists;
                                }
                                f.overrideValue = f.fieldOrgValue; // Initialize override with current value
                            });
                        }
                        // Internal Contact section
                        if (el.fieldValue.includes('Contact')) {
                            record = this.internalSignatoryInfo;
                            const recordExists = record && Object.keys(record).length > 0;
                            el.wFieldWrapperList.forEach(f => {
                                f.fieldOrgValue = record && record[f.fieldAPI] ? record[f.fieldAPI] : '';
                                f.overrideValue = f.fieldOrgValue; // Initialize override with current value
                                // In portal, internal contact fields (below Country Name) are read‑only
                                f.isDisabled = this.isPortalUser ? true : !recordExists;
                            });
                        }
                        // Legal Document section
                        if (el.fieldValue === LegalDoc_API.LegalDoc_c) {
                            record = this.legalDoc;
                            const recordExists = record && Object.keys(record).length > 0;
                            el.wFieldWrapperList.forEach(f => {
                                f.fieldOrgValue = record?.[f.fieldAPI] ?? '';
                                f.overrideValue = f.fieldOrgValue;
                                f.isDisabled = !recordExists;
                            });
                        }
                    });
                    this.objectOptions = this.mergeObjects.map((object) => {
                        let label = object.fieldLabel;
                        const value = object.fieldValue || '';
                        const normalizedValue = value.toLowerCase();
                        if (normalizedValue.includes('supplier')) {
                            //label = this.Labels.LBL_LegalDocument_Signatory;
                            label = this.fieldLabels?.Supplier__c.Signatory__c;
                        }
                        if (normalizedValue.includes('contact')) {
                            //label = this.Labels.LBL_LegalDocument_SupplierSignatory;
                            label = this.fieldLabels?.Contact.MainFrameworkSignatory__c;
                        }
                        return { label, value };
                    });
                    this.changedGlobalVariables = {};
                })
                .catch(error => {
                    console.error('Error loading merge objects', error);
                });
        } catch (error) {
            console.log('error in load merge objects:' + error.body);
        }

    }
    //TrackActions Management/Comments Management
    handleAddComment(event) {
        const clauseId = event.currentTarget.dataset.id;
        const supplierComment = event.currentTarget.dataset.type === 'supplier';
        const clause = this.displayClauses.find(c => c.Id === clauseId);
        const oldValue1 = clause.showBOCommentSection;
        const oldValue2 = clause.showSUPCommentSection;
        this.displayClauses.forEach(el => {
            el.showBOCommentSection = false;
            el.showSUPCommentSection = false;
        });
        if (supplierComment) {
            clause.showSUPCommentSection = !oldValue2;
        } else {
            clause.showBOCommentSection = !oldValue1;
        }
    }
    handleTrackActionCreated(event) {
        const { clauseId, newTrackAction } = event.detail;
        const current = this.trackActions?.[clauseId] ?? [];
        this.trackActions = { ...(this.trackActions ?? {}), [clauseId]: [...current, newTrackAction] };
        this.displayClauses = this.displayClauses.map(c => {
            if (c.Id !== clauseId) {
                return c;
            }
            let relatedActivities = this.trackActions?.[clauseId] || [];
            let shownComments = [];
            if (this.isPortalUser) {
                shownComments = relatedActivities.filter(activity => (activity[TrackAction_API.CommentOrigin__c] == 'Legal' && activity[TrackAction_API.CommentStatus__c] == 'Published') || activity[TrackAction_API.CommentOrigin__c] == 'Supplier');
            }
            if (this.isBOUser) {
                shownComments = relatedActivities.filter(activity => (activity[TrackAction_API.CommentOrigin__c] != 'Business Owner' && activity[TrackAction_API.CommentStatus__c] == 'Published') || (activity[TrackAction_API.CommentOrigin__c] == 'Business Owner' && !(activity[TrackAction_API.CommentStatus__c] === 'Draft' && activity.CreatedById && activity.CreatedById !== this.currentUser.Id)));
            }
            if (this.isLegal) {
                shownComments = relatedActivities.filter(activity => (activity[TrackAction_API.CommentOrigin__c] != 'Legal' && activity[TrackAction_API.CommentStatus__c] == 'Published') || activity[TrackAction_API.CommentOrigin__c] == 'Legal');
            }
            relatedActivities = [...shownComments];
            let hasComments = relatedActivities.length > 0;
            // Check for BO comments (IsPortalPublished__c = false or null)
            let hasBOComments = hasComments && relatedActivities.some(activity => !activity[TrackAction_API.IsPortalPublished__c] && activity[TrackAction_API.Comment__c]);
            // Check for Supplier comments (IsPortalPublished__c = true)
            let hasSupplierComments = hasComments && relatedActivities.some(activity => activity[TrackAction_API.IsPortalPublished__c] === true && activity[TrackAction_API.Comment__c]);
            let boCommentIconClass = hasBOComments ? 'edit-btn comment-btn comment-btn-bo has-comments-bo' : 'edit-btn comment-btn comment-btn-bo';
            let supplierCommentIconClass = hasSupplierComments ? 'edit-btn comment-btn has-comments' : 'edit-btn comment-btn';
            return {
                ...c,
                relatedActivities,
                hasComments,
                hasBOComments,
                hasSupplierComments,
                boCommentIconClass,
                supplierCommentIconClass
            };
        });
    }
    handleTrackActionUpdated(event) {
        const { clauseId, trackActionId, comment } = event.detail || {};
        if (!clauseId || !trackActionId) {
            return;
        }

        const updatedActivities = (this.trackActions?.[clauseId] || []).map(activity =>
            activity.Id === trackActionId
                ? { ...activity, [TrackAction_API.Comment__c]: comment }
                : activity
        );

        this.trackActions = {
            ...(this.trackActions || {}),
            [clauseId]: updatedActivities
        };

        this.displayClauses = this.displayClauses.map(clause =>
            clause.Id === clauseId
                ? {
                    ...clause,
                    relatedActivities: (clause.relatedActivities || []).map(activity =>
                        activity.Id === trackActionId
                            ? { ...activity, [TrackAction_API.Comment__c]: comment }
                            : activity
                    )
                }
                : clause
        );
    }
    handleResolveComments(event) {
        const { clauseId, type, resolveAll, commentId } = event.detail || {};
        let relatedActivities = this.trackActions?.[clauseId]?.filter(a => type == 'portal' ? a[TrackAction_API.IsPortalPublished__c] : !a[TrackAction_API.IsPortalPublished__c])
        if (!resolveAll) {
            let refComment = relatedActivities?.find(item => item.Id === commentId);
            relatedActivities = [refComment];
        }
        changeCommentStatus({ comments_serialized: JSON.stringify(relatedActivities) })
            .then(() => {
                showNotification(this, this.Labels.LBL_Success, this.Labels.MSG_LDCommentsResolved, 'success');
                this.loadData();
            })
            .catch(error => {
                console.error('Error changing comment status:', error);
            });
    }
    handlePdfPreview() {
        if (!this.jsPdfLoaded) {
            showNotification(this, this.Labels.LBL_Error, this.Labels.MSG_LegalDocument_PdfLibraryNotLoaded, 'error');
            return;
        }
        this.isExportingPdf = true;
        try {
            const pdf = generatePdf(this.clauses, this.legalDoc, this.currentUser);
            const pdfBlob = pdf.output('blob');
            const pdfUrl = URL.createObjectURL(pdfBlob);
            const a = document.createElement('a');
            a.href = pdfUrl;
            a.target = '_blank';
            a.click();
        } catch (error) {
            console.error('Error generating PDF preview:', error);
            showNotification(this, this.Labels.LBL_Error, error.message, 'error');
        } finally {
            this.isExportingPdf = false;
        }
    }
    handleExportWord() {
        if (!this.docxLibLoaded || !window?.docx) {
            showNotification(this, this.Labels.LBL_Error, this.Labels.MSG_LegalDocument_PdfLibraryNotLoaded, 'error');
            return;
        }
        exportWord(this.clauses, this.legalDoc, this.currentUser);
    }

    // ==================== VERSION COMPARISON (Business Rules) ====================
    computeHasVersionsToCompare(editingClause) {
        if (!editingClause || !editingClause.Id) return false;
        let versions = this.getClauseVersionChain(editingClause.Id);
        let otherVersions = versions.filter(v => v.Id !== editingClause.Id);
        return otherVersions.length > 0;
    }
    computeCompareVersionOptions(editingClause) {
        if (!editingClause || !editingClause.Id) return [];
        let versions = this.getClauseVersionChain(editingClause.Id);
        let options = versions
            .filter(v => v.Id !== editingClause.Id)
            .map(clause => {
                let version = clause[LegalDocClause_API.Version__c] || 0;
                let updatedBy = clause[LegalDocClause_API.Updatedby__r]?.Name || '';
                let label = `V${version}`;
                if (updatedBy) label += ` - ${updatedBy}`;
                return { label: label, value: clause.Id };
            })
            .sort((a, b) => {
                let vA = parseInt(a.label.match(/V(\d+)/)?.[1] || 0);
                let vB = parseInt(b.label.match(/V(\d+)/)?.[1] || 0);
                return vB - vA;
            });

        if (options.length > 0) {
            options.unshift({ label: this.Labels.MSG_LegalDocument_SelectVersion, value: '' });
        }
        return options;
    }

    computePastVersionContent(editingClause, selectedCompareVersionId) {
        try {
            if (selectedCompareVersionId && this.allClauses?.length > 0) {
                let selectedClause = this.allClauses.find(c => c.Id === selectedCompareVersionId);
                if (selectedClause?.[LegalDocClause_API.Clause__c]) {
                    return selectedClause[LegalDocClause_API.Clause__c];
                }
            }
            let pastClause = this.getPastVersionClauseFor(editingClause);
            if (pastClause?.[LegalDocClause_API.Clause__c]) {
                return pastClause[LegalDocClause_API.Clause__c];
            }
            if (editingClause?.[LegalDocClause_API.LegalDocClauseP1__c] && this.allClauses?.length > 0) {
                let prevClause = this.allClauses.find(c => c.Id === editingClause[LegalDocClause_API.LegalDocClauseP1__c]);
                if (prevClause) return prevClause[LegalDocClause_API.Clause__c] || '';
            }

            if (editingClause?.[LegalDocClause_API.LegalDocClauseField__c] && this.allClauses?.length > 0) {
                let originClause = this.allClauses.find(c => c.Id === editingClause[LegalDocClause_API.LegalDocClauseField__c]);
                if (originClause) return originClause[LegalDocClause_API.Clause__c] || '';
            }
            return `<p><em>${this.Labels.MSG_LegalDocument_NoPreviousVersion}</em></p>`;
        } catch (error) {
            return `<p><em>${this.Labels.MSG_LegalDocument_NoPreviousVersion}</em></p>`;
        }
    }

    computeCurrentVersionContent(editingClause, selectedCompareVersionId) {
        try {
            let currentClause = this.getCurrentVersionClauseFor(editingClause);
            let currentContent = currentClause?.[LegalDocClause_API.Clause__c] || editingClause?.[LegalDocClause_API.Clause__c] || '';
            let pastContent = '';
            if (selectedCompareVersionId && this.allClauses?.length > 0) {
                let selectedClause = this.allClauses.find(c => c.Id === selectedCompareVersionId);
                pastContent = selectedClause?.[LegalDocClause_API.Clause__c] || '';
            } else {
                let pastClause = this.getPastVersionClauseFor(editingClause);
                pastContent = pastClause?.[LegalDocClause_API.Clause__c] || '';
            }
            if (!this.stripHtmlTags(currentContent).trim()) {
                return `<p><em>${this.Labels.MSG_LegalDocument_NoContent}</em></p>`;
            }
            // If no past content, show current content as-is (no highlighting)
            if (!this.stripHtmlTags(pastContent).trim()) {
                return currentContent;
            }
            if (pastContent && this.dmp && this.diffLibLoaded) {
                return this.computeDiff(pastContent, currentContent);
            }
            return currentContent;
        } catch (error) {
            return editingClause?.[LegalDocClause_API.Clause__c] || '';
        }
    }

    computeNewVersionContent(editingClause) {
        try {
            let newClause = this.getNewVersionClauseFor(editingClause);
            let newContent = editingClause?.[LegalDocClause_API.Clause__c] || newClause?.[LegalDocClause_API.Clause__c] || '';
            let currentClause = this.getCurrentVersionClauseFor(editingClause);
            let currentContent = currentClause?.[LegalDocClause_API.Clause__c] || '';
            if (!this.stripHtmlTags(newContent).trim()) {
                return `<p><em>${this.Labels.MSG_LegalDocument_StartTypingNewVersion}</em></p>`;
            }
            // If no current content, show new content as-is (no highlighting)
            if (!this.stripHtmlTags(currentContent).trim()) {
                return newContent;
            }
            if (currentContent && this.dmp && this.diffLibLoaded) {
                return this.computeDiff(currentContent, newContent);
            }
            return newContent;
        } catch (error) {
            return editingClause?.[LegalDocClause_API.Clause__c] || '';
        }
    }

    getCurrentVersionClauseFor(editingClause) {
        if (!editingClause) return null;
        let versions = this.getClauseVersionChain(editingClause.Id);
        for (let i = versions.length - 1; i >= 0; i--) {
            if (versions[i][LegalDocClause_API.Status__c]?.toLowerCase() !== 'rejected') {
                return versions[i];
            }
        }
        return editingClause;
    }

    getPastVersionClauseFor(editingClause) {
        let currentVersion = this.getCurrentVersionClauseFor(editingClause);
        if (!currentVersion) return null;
        if (currentVersion[LegalDocClause_API.LegalDocClauseP1__c] && this.allClauses?.length > 0) {
            return this.allClauses.find(c => c.Id === currentVersion[LegalDocClause_API.LegalDocClauseP1__c]) || null;
        }
        if (currentVersion[LegalDocClause_API.LegalDocClauseField__c] && this.allClauses?.length > 0) {
            return this.allClauses.find(c => c.Id === currentVersion[LegalDocClause_API.LegalDocClauseField__c]) || null;
        }
        return null;
    }

    getNewVersionClauseFor(editingClause) {
        if (!editingClause) return editingClause;
        let versions = this.getClauseVersionChain(editingClause.Id);
        let lastVersion = versions.length > 0 ? versions[versions.length - 1] : editingClause;
        let currentVersion = this.getCurrentVersionClauseFor(editingClause);

        if (currentVersion?.Id === lastVersion?.Id) {
            return editingClause;
        }
        if (lastVersion?.[LegalDocClause_API.UpdateOrigin__c] === 'Supplier' || lastVersion?.[LegalDocClause_API.UpdateOrigin__c] === 'supplier') {
            return lastVersion;
        }
        return this.getPastVersionClauseFor(editingClause) || editingClause;
    }

    handleCompareVersionChange(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let selectedValue = event.detail.value;
        if (clauseId) {
            this.selectedCompareVersionIds = {
                ...this.selectedCompareVersionIds,
                [clauseId]: selectedValue
            };
            let selectedCompareVersionId = this.selectedCompareVersionIds[clauseId];
            this.displayClauses = this.displayClauses.map(c => c.Id === clauseId ?
                {
                    ...c,
                    pastVersionContent: this.computePastVersionContent(c, selectedCompareVersionId),
                    currentVersionContent: this.computeCurrentVersionContent(c, selectedCompareVersionId),
                    selectedCompareVersionId: selectedCompareVersionId,
                    newVersionContent: this.computeNewVersionContent(c),
                    itemClass: this.getClauseItemClass(c)
                } : c);
        }
    }
    getClauseVersionChain(clauseId) {
        if (!this.allClauses || !clauseId) return [];

        let versions = [];
        let currentClause = this.allClauses.find(c => c.Id === clauseId);

        if (!currentClause) return [];
        versions.push(currentClause);
        let prevId = currentClause[LegalDocClause_API.LegalDocClauseP1__c];
        while (prevId) {
            let prev = this.allClauses.find(c => c.Id === prevId);
            if (prev) {
                versions.push(prev);
                prevId = prev[LegalDocClause_API.LegalDocClauseP1__c];
            } else {
                break;
            }
        }
        if (currentClause[LegalDocClause_API.LegalDocClauseField__c]) {
            let origin = this.allClauses.find(c => c.Id === currentClause[LegalDocClause_API.LegalDocClauseField__c]);
            if (origin && !versions.find(v => v.Id === origin.Id)) {
                versions.push(origin);
            }
        }
        let findChildren = (id) => {
            let children = this.allClauses.filter(c => c[LegalDocClause_API.LegalDocClauseP1__c] === id);
            children.forEach(child => {
                if (!versions.find(v => v.Id === child.Id)) {
                    versions.push(child);
                    findChildren(child.Id);
                }
            });
        };
        
        findChildren(clauseId);
        let filteredVersions = versions.filter(clause => {
            let isDraft = clause[LegalDocClause_API.Status__c]?.toLowerCase() === 'draft';
            let updateOrigin = (clause[LegalDocClause_API.UpdateOrigin__c] || '').toLowerCase();
            let isOwner = clause[LegalDocClause_API.UpdatedById] === this.currentUser.Id;
            if (isDraft) {
            if (!this.isPortalUser && updateOrigin === 'supplier') {
                return false;
            }
            if (this.isPortalUser && updateOrigin === 'legal') {
                return false;
            }
                if (!isOwner) {
                    return false;
                }
            }
            return true;
        });
        return filteredVersions.sort((a, b) => (a[LegalDocClause_API.Version__c] || 0) - (b[LegalDocClause_API.Version__c] || 0));
    }

    getLatestVersionClauses(allClauses) {
        if (!allClauses || allClauses.length === 0) return [];
        try {
            let clausesToShow = [...allClauses];
            let draftIdsToHide = new Set();
            allClauses.forEach(clause => {
                let isDraft = clause[LegalDocClause_API.Status__c]?.toLowerCase() === 'draft';
                let isRejected = clause[LegalDocClause_API.Status__c]?.toLowerCase() === 'rejected';
                let isBOPublishing = clause[LegalDocClause_API.Status__c]?.toLowerCase() === 'business owner publishing';
                let updateOrigin = clause[LegalDocClause_API.UpdateOrigin__c]?.toLowerCase() || '';
                let updatedBy = clause[LegalDocClause_API.Updatedby__c];
                if (isRejected) {
                    draftIdsToHide.add(clause.Id);
                }
                if (isDraft) {
                    if (this.isPortalUser) {
                        if (updateOrigin === 'legal' || updateOrigin === 'businessowner') {
                            draftIdsToHide.add(clause.Id);
                        }
                    } else if (this.isBOUser) {
                        if (updateOrigin === 'supplier' || updateOrigin === 'legal' || (updateOrigin === 'businessowner' && updatedBy !== this.currentUser.Id)) {
                            draftIdsToHide.add(clause.Id);
                        }
                    } else {
                        if (updateOrigin === 'supplier' || updateOrigin === 'businessowner') {
                            draftIdsToHide.add(clause.Id);
                        }
                    }
                }
                if (isBOPublishing) {
                    if (this.isPortalUser) {
                        if (updateOrigin === 'legal' || updateOrigin === 'businessowner') {
                            draftIdsToHide.add(clause.Id);
                        }
                    }
                    if (this.isBOUser && (this.pageFilters.statusFilter || '').toLowerCase() === 'published') {
                        draftIdsToHide.add(clause.Id);
                    }
                }
            });
            clausesToShow = allClauses.filter(clause => !draftIdsToHide.has(clause.Id));
            let olderVersionIds = new Set();
            clausesToShow.forEach(clause => {
                if (clause[LegalDocClause_API.LegalDocClauseP1__c]) {
                    olderVersionIds.add(clause[LegalDocClause_API.LegalDocClauseP1__c]);
                }
                if (clause[LegalDocClause_API.LegalDocClauseField__c] && clause[LegalDocClause_API.LegalDocClauseField__c] !== clause.Id) {
                    olderVersionIds.add(clause[LegalDocClause_API.LegalDocClauseField__c]);
                }
            });

            return clausesToShow.filter(clause => !olderVersionIds.has(clause.Id));
        } catch (error) {
            console.error('Error in getLatestVersionClauses:', error);
            return allClauses;
        }
    }

    computeDiff(text1, text2) {
        try {
            const clean = (text) => {
                if (!text) return '';
                return text.replace(/\r\n/g, '\n');
            };

            const oldHtml = clean(text1);
            const newHtml = clean(text2);

            // If both are identical, return new content without any highlighting
            if (oldHtml === newHtml) {
                return newHtml;
            }

            // Extract plain text (strip HTML) for text-level comparison
            const stripTags = (html) => {
                if (!html) return '';
                let tmp = document.createElement('div');
                tmp.innerHTML = html;
                return tmp.textContent || tmp.innerText || '';
            };
            const normalizeForCompare = (s) => (s || '')
                .replace(/\u00A0/g, ' ')
                .replace(/\s+/g, ' ')
                .trim();
            const oldPlainText = stripTags(oldHtml);
            const newPlainText = stripTags(newHtml);
            const textIsSame = normalizeForCompare(oldPlainText) === normalizeForCompare(newPlainText);
            const htmlIsDifferent = oldHtml !== newHtml;
            if (textIsSame && htmlIsDifferent && oldPlainText.trim()) return `<span style="background-color: #fff3cd; border-bottom: 2px solid #ffc107;" title="Style changed">${newHtml}</span>`;
            const extractWordStyles = (html) => {
                const wordStyles = new Map();
                let tmp = document.createElement('div');
                tmp.innerHTML = html;
                const walkNode = (node, styles) => {
                    if (node.nodeType === Node.TEXT_NODE) {
                        const words = (node.textContent || '').match(/[\p{L}\p{N}]+/gu) || [];
                        words.forEach(word => {
                            const key = word.toLowerCase();
                            const styleKey = [...styles].sort().join('|');
                            if (!wordStyles.has(key)) wordStyles.set(key, new Set());
                            wordStyles.get(key).add(styleKey);
                        });
                    } else if (node.nodeType === Node.ELEMENT_NODE) {
                        const newStyles = new Set(styles);
                        const tagName = node.tagName.toLowerCase();
                        if (tagName === 'strong' || tagName === 'b') newStyles.add('bold');
                        if (tagName === 'em' || tagName === 'i') newStyles.add('italic');
                        if (tagName === 'u') newStyles.add('underline');
                        if (tagName === 's' || tagName === 'strike' || tagName === 'del') newStyles.add('strikethrough');
                        if (tagName === 'sub') newStyles.add('subscript');
                        if (tagName === 'sup') newStyles.add('superscript');
                        const style = node.getAttribute('style') || '';
                        if (/font-weight:\s*(bold|[6-9]\d{2})/i.test(style)) newStyles.add('bold');
                        if (/font-style:\s*italic/i.test(style)) newStyles.add('italic');
                        if (/text-decoration:[^;]*underline/i.test(style)) newStyles.add('underline');
                        if (node.style) {
                            if (node.style.fontWeight === 'bold' || parseInt(node.style.fontWeight) >= 700) newStyles.add('bold');
                            if (node.style.fontStyle === 'italic') newStyles.add('italic');
                            if (node.style.textDecoration?.includes('underline')) newStyles.add('underline');
                        }
                        node.childNodes.forEach(child => walkNode(child, newStyles));
                    }
                };
                walkNode(tmp, new Set());
                return wordStyles;
            };
            const oldWordStyles = extractWordStyles(oldHtml);
            const newWordStyles = extractWordStyles(newHtml);
            const styleChangedWords = new Set();
            oldWordStyles.forEach((oldStyles, word) => {
                if (newWordStyles.has(word)) {
                    const newStyles = newWordStyles.get(word);
                    const oldStyleArr = [...oldStyles].sort().join(',');
                    const newStyleArr = [...newStyles].sort().join(',');
                    if (oldStyleArr !== newStyleArr) {
                        styleChangedWords.add(word);
                    }
                }
            });
            const tokenize = (text) => { return text.match(/[\p{L}\p{N}]+|[^\p{L}\p{N}\s]+|\s+/gu) || []; };
            const oldTokens = tokenize(oldPlainText);
            const newTokens = tokenize(newPlainText);
            const tokenToChar = {};
            const charsToToken = [];
            let nextCharCode = 0xE000;
            const encodeTokens = (tokens) => {
                return tokens.map(token => {
                    if (!(token in tokenToChar)) {
                        tokenToChar[token] = String.fromCharCode(nextCharCode++);
                        charsToToken.push(token);
                    }
                    return tokenToChar[token];
                }).join('');
            };
            const oldEncoded = encodeTokens(oldTokens);
            const newEncoded = encodeTokens(newTokens);
            const diffs = this.dmp.diff_main(oldEncoded, newEncoded);
            this.dmp.diff_cleanupSemantic(diffs);
            this.dmp.diff_cleanupEfficiency(diffs);
            const charStatus = new Array(newPlainText.length).fill('keep');
            const deletionsAtPosition = new Map();
            let newTextPos = 0;
            for (const d of diffs) {
                const tokens = Array.from(d[1]).map(c => charsToToken[c.charCodeAt(0) - 0xE000] || c);
                const text = tokens.join('')
                if (d[0] === 0) {
                    let pos = newTextPos;
                    for (const token of tokens) {
                        const isWord = /^[\p{L}\p{N}]+$/u.test(token);
                        if (isWord && styleChangedWords.has(token.toLowerCase())) {
                            for (let j = 0; j < token.length; j++) {
                                charStatus[pos + j] = 'style';
                            }
                        }
                        pos += token.length;
                    }
                    newTextPos += text.length;
                } else if (d[0] === 1) {
                    const isOnlyWhitespace = /^[\s]*$/.test(text);
                    if (!isOnlyWhitespace) {
                        for (let j = 0; j < text.length; j++) {
                            charStatus[newTextPos + j] = 'insert';
                        }
                    }
                    newTextPos += text.length;
                } else if (d[0] === -1) {
                    const isOnlyWhitespace = /^[\s]*$/.test(text);
                    if (!isOnlyWhitespace) {
                        const existing = deletionsAtPosition.get(newTextPos) || '';
                        deletionsAtPosition.set(newTextPos, existing + text);
                    }
                }
            }
            const getDeletedHtml = (pos) => {
                const deleted = deletionsAtPosition.get(pos);
                if (deleted) {
                    const escaped = deleted
                        .replace(/&/g, '&amp;')
                        .replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;');
                    return `<span class="diff-delete" style="background-color: #f2f6de; color: #b71c1c; text-decoration: line-through;">${escaped}</span>`;
                }
                return '';
            };
            const getEntityLength = (html, pos) => {
                if (html[pos] !== '&') return 0;
                const semicolonPos = html.indexOf(';', pos);
                if (semicolonPos === -1 || semicolonPos - pos > 10) return 0;
                const entity = html.substring(pos, semicolonPos + 1);
                if (/^&([a-zA-Z]+|#[0-9]+|#x[0-9a-fA-F]+);$/.test(entity)) return entity.length;
                return 0;
            };
            let result = '';
            let plainTextIndex = 0;
            let i = 0;
            result += getDeletedHtml(0);
            while (i < newHtml.length) {
                if (newHtml[i] === '<') {
                    let tagEnd = newHtml.indexOf('>', i);
                    if (tagEnd !== -1) {
                        result += newHtml.substring(i, tagEnd + 1);
                        i = tagEnd + 1;
                        continue;
                    }
                }
                const entityLen = getEntityLength(newHtml, i);
                if (entityLen > 0) {
                    const entity = newHtml.substring(i, i + entityLen);
                    const status = charStatus[plainTextIndex] || 'keep';
                    if (status === 'insert') result += `<span class="diff-insert" style="background-color: #dcf3ee; color: #1b5e20;">${entity}</span>`;
                    else if (status === 'style') result += `<span style="background-color: #fff3cd; border-bottom: 2px solid #ffc107;">${entity}</span>`;
                    else result += entity;
                    plainTextIndex++;
                    result += getDeletedHtml(plainTextIndex);
                    i += entityLen;
                } else {
                    const status = charStatus[plainTextIndex] || 'keep';
                    let runEnd = i + 1;
                    let runPlainEnd = plainTextIndex + 1;
                    while (runEnd < newHtml.length) {
                        if (newHtml[runEnd] === '<') break;
                        if (getEntityLength(newHtml, runEnd) > 0) break;
                        const nextStatus = charStatus[runPlainEnd] || 'keep';
                        if (nextStatus !== status) break;
                        if (deletionsAtPosition.has(runPlainEnd)) break;
                        runEnd++;
                        runPlainEnd++;
                    }
                    const textRun = newHtml.substring(i, runEnd);
                    if (status === 'insert') result += `<span class="diff-insert" style="background-color: #dcf3ee; color: #1b5e20;">${textRun}</span>`;
                    else if (status === 'style') result += `<span style="background-color: #fff3cd; border-bottom: 2px solid #ffc107;">${textRun}</span>`;
                    else result += textRun;
                    result += getDeletedHtml(runPlainEnd);
                    plainTextIndex = runPlainEnd;
                    i = runEnd;
                }
            }

            return result;
        } catch (error) {
            console.error('Error in computeDiff:', error);
            return String(text2 || '');
        }
    }

    sanitizeHtml(html) {
        if (!html) return '';
        return html.replace(/style="([^"]*)"/gi, (m, styles) => {
            return ('style="' + styles.split(';').map(s => s.trim()).filter(Boolean).sort().join(';') + '"');
        })
            .replace(/\u00A0/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
    }

    handleAddClause() {
        if (this.isPortalUser) return;
        let defaultClauseType = this.picklistValues[this.LegalDocClause_API.LegalDocClause__c][this.LegalDocClause_API.ClauseType__c]?.[0]?.value || 'Title';
        this.selectedBusinessOwners = ['Legal'];
        this.newClause = {
            [LegalDocClause_API.LegalDoc__c]: this.recordId,
            [LegalDocClause_API.Version__c]: 0,
            [LegalDocClause_API.Status__c]: defaultClauseType === 'Body' ? 'legal publishing' : null,
            [LegalDocClause_API.LegalStatus__c]: 'Draft',
            [LegalDocClause_API.PartnerStatus__c]: 'Draft',
            [LegalDocClause_API.BusinessStatus__c]: 'Open',
            [LegalDocClause_API.LegalDocClauseField__c]: null,
            [LegalDocClause_API.UpdateOrigin__c]: null,
            [LegalDocClause_API.Clause__c]: '',
            [LegalDocClause_API.DisplayOrder__c]: this.clauses.length + 1,
            [LegalDocClause_API.IsNegotiable__c]: defaultClauseType === 'Body',
            [LegalDocClause_API.ClauseType__c]: defaultClauseType,
            [LegalDocClause_API.BusinessOwners__c]: 'Legal',
            get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
            get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
            get _ClauseType__c() { return this[LegalDocClause_API.ClauseType__c]; },
            get _IsNegotiable__c() { return this[LegalDocClause_API.IsNegotiable__c]; },
            get _BusinessOwners__c() { return this[LegalDocClause_API.BusinessOwners__c]; }
        };
        //this.initializeNewClause();
        this.isAddingNewClause = true;
        // Scroll to the new clause form after it renders
        setTimeout(() => {
            const el = this.template.querySelector('.clause-new-inline');
            if (el) {
                el.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }
    handleCancelNewClauseInline() {
        this.isAddingNewClause = false;
        this.newClause = {};
        this.selectedBusinessOwners = ['Legal'];
    }
    handleNewClauseFieldChange(event) {
        const field = event.currentTarget.dataset.field;
        let value;
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else if (event.target.type === 'number') {
            value = parseFloat(event.target.value);
        } else if (field === LegalDocClause_API.BusinessOwners__c) {
            this.selectedBusinessOwners = event.detail.value;
            value = this.selectedBusinessOwners.join(';');
        } else {
            value = event.detail?.value !== undefined ? event.detail.value : event.target.value;
        }
        if (field === LegalDocClause_API.ClauseType__c) {
            this.newClause = {
                ...this.newClause,
                [LegalDocClause_API.IsNegotiable__c]: value === 'Body'
            }
        }
        this.newClause = {
            ...this.newClause,
            [field]: value,
            get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
            get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
            get _ClauseType__c() { return this[LegalDocClause_API.ClauseType__c]; },
            get _IsNegotiable__c() { return this[LegalDocClause_API.IsNegotiable__c]; },
            get _BusinessOwners__c() { return this[LegalDocClause_API.BusinessOwners__c]; }
        };
    }

    handleSaveNewClause() {
        let clauseText = this.stripHtmlTags(this.newClause[LegalDocClause_API.Clause__c] || '').trim();
        if (!clauseText) {
            showNotification(this, this.Labels.LBL_Error, this.Labels.MSG_LegalDocument_EnterClauseText, 'error');
            return;
        }
        let data = [];
        let clauseType = this.newClause[LegalDocClause_API.ClauseType__c] || 'Title';
        let clauseToSave = {
            [LegalDocClause_API.LegalDoc__c]: this.recordId,
            [LegalDocClause_API.Clause__c]: this.newClause[LegalDocClause_API.Clause__c],
            [LegalDocClause_API.Version__c]: 0,
            [LegalDocClause_API.Status__c]: 'Draft',
            [LegalDocClause_API.BusinessStatus__c]: this.newClause[LegalDocClause_API.BusinessStatus__c],
            [LegalDocClause_API.DisplayOrder__c]: this.newClause[LegalDocClause_API.DisplayOrder__c],
            [LegalDocClause_API.IsNegotiable__c]: this.newClause[LegalDocClause_API.IsNegotiable__c] || false,
            [LegalDocClause_API.LegalDocClauseField__c]: this.newClause[LegalDocClause_API.LegalDocClauseField__c] || null,
            [LegalDocClause_API.UpdateOrigin__c]: 'Legal',
            [LegalDocClause_API.ClauseType__c]: clauseType,
            [LegalDocClause_API.BusinessOwners__c]: this.newClause[LegalDocClause_API.BusinessOwners__c] || ''
        };
        clauseToSave[LegalDocClause_API.PartnerStatus__c] = 'Open';
        clauseToSave[LegalDocClause_API.LegalStatus__c] = 'Draft';

        clauseToSave[LegalDocClause_API.Supplier__c] = this.legalDoc[LegalDoc_API.Supplier__c];
        data.push(clauseToSave);
        saveClauses({
            clausesJson: JSON.stringify(data),
            cloneComments: false,
            relatedCommentsJson: JSON.stringify([])
        }).then(() => {
            showNotification(this, this.Labels.LBL_Success, this.Labels.MSG_LegalDocument_ClauseAddedSuccessfully, 'success');
            this.isAddingNewClause = false;
            this.newClause = {};
            this.selectedBusinessOwners = ['Legal'];
            this.loadData();
        }).catch(error => {
            showNotification(this, this.Labels.LBL_Error, error.body?.message, 'error');
        });
    }

    openContactModal() {
        this.showContactModal = true;
    }
    handleCloseContactModal() {
        this.showContactModal = false;
    }
    handleShowGlobalVariablesPopup() {
        this.showGlobalVariablesPopup = true;
    }
    handleCloseGlobalVariablesPopup() {
        this.showGlobalVariablesPopup = false;
    }
    openDeletePopUp(event) {
        this.selectedClauseToDelete = event.currentTarget.dataset.id;
        try {
            let clause = this.clauses.find(c => c.Id === this.selectedClauseToDelete);
            if (!clause) { return; }
            this.openModal({
                title: this.Labels.LBL_LD_DeleteConfirmation,
                message: this.Labels.MSG_LD_RemoveClause,
                confirmLabel: this.Labels.LBL_Delete,
                onConfirmAction: () => this.handleDeleteClause()
            });
        } catch (error) {
            console.log('error open delete popup :' + error.message);
        }
    }
    //generic modal handling
    openModal({ title, message, confirmLabel, onConfirmAction, onCloseAction }) {
        this.modalConfig = {
            isOpen: true,
            title,
            message,
            confirmLabel,
            onConfirmAction,
            onCloseAction
        };
    }
    closeModal() {
        if (this.modalConfig.onCloseAction) {
            this.modalConfig.onCloseAction();
        }
        this.modalConfig = {
            isOpen: false,
            title: '',
            message: '',
            confirmLabel: '',
            onConfirmAction: null,
            onCloseAction: null,
            isOpen: false
        };
    }
    handleConfirm() {
        if (this.modalConfig.onConfirmAction) {
            this.modalConfig.onConfirmAction();
        }
        this.closeModal();
    }
    handleCloseSupplierModal() {
        this.showSupplierModal = false;
        this.allSuppliers = [];
        this.filteredSuppliers = [];
        this.selectedSupplierIds = [];
        this.existingSupplierIds = [];
        this.supplierSearchTerm = '';
        this.supplierGridSettings = {};
        this.supplierGridFields = [];
    }
    handleLoadSuppliers() {
        if (this.isPortalUser) return;
        this.showSupplierModal = true;
        this.loadSuppliers();
    }

    loadSuppliers() {
        this.isLoadingSuppliers = true;
        getFilteredSuppliers({ legalDoc: JSON.stringify(this.legalDoc) })
            .then(result => {
                let data = JSON.parse(result);
                this.supplierGridSettings = data.gridSettings;
                this.existingSupplierIds = data.existingSupplierIds || [];
                let gridFields = this.supplierGridSettings.GRID_FIELDS || [];
                this.supplierGridFields = gridFields.map(field => {
                    let fieldType = field.fieldType || field.stringFieldType;
                    // Treat as reference: REFERENCE type, Name field, Id field, or relationship fields like Owner.Name
                    let isReference = fieldType === 'REFERENCE'
                        || field.fieldName === 'Name'
                        || field.fieldName === 'Id'
                        || field.fieldName.endsWith('.Name')  // Relationship fields like Owner.Name
                        || field.fieldName.endsWith('Id');    // Lookup fields like OwnerId
                    return {
                        fieldName: field.fieldName,
                        fieldLabel: field.fieldLabel?.toUpperCase() || field.fieldName,
                        fieldType: fieldType,
                        isNumberField: field.isNumberField || false,
                        isReference: isReference,
                        isDate: fieldType === 'DATE',
                        isDateTime: fieldType === 'DATETIME',
                        isPicklist: fieldType === 'PICKLIST' && !isReference,
                        isBoolean: fieldType === 'BOOLEAN',
                        isText: !isReference && !['DATE', 'DATETIME', 'PICKLIST', 'BOOLEAN', 'DOUBLE', 'INTEGER', 'CURRENCY', 'PERCENT'].includes(fieldType),
                        headerStyle: field.stringHeaderStyle || field.headerStyle || '',
                        style: field.style || '',
                        scale: field.scale || 0,
                        pickListValues: field.pickListValues || []
                    };
                });
                this.allSuppliers = this.buildSupplierData(data.suppliers || []);
                this.totalSupplierCount = this.allSuppliers.length
                this.filteredSuppliers = [...this.allSuppliers];
            })
            .catch(error => {
                console.error('Error loading suppliers:', error);
                showNotification(this, this.Labels.LBL_Error, (error.body?.message || error.message), 'error');
                this.allSuppliers = [];
                this.filteredSuppliers = [];
            })
            .finally(() => {
                this.isLoadingSuppliers = false;
            });
    }

    buildSupplierData(suppliers) {
        const existingIds = new Set(this.existingSupplierIds);
        return suppliers.map(supplier => {
            const isDisabled = existingIds.has(supplier.Id);
            return {
                Id: supplier.Id,
                Name: supplier.Name,
                isSelected: false,
                isDisabled,
                disabledTooltip: isDisabled ? this.Labels.MSG_LegalDocument_SupplierAlreadyHasDocument : '',
                rowClass: isDisabled ? 'slds-hint-parent supplier-row-disabled' : 'slds-hint-parent',
                values: this.supplierGridFields.map(field => {
                    const wrapper = {
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
                        isText: field.isText,
                        isNumber: field.isNumberField,
                        link: '',
                        style: field.style,
                        scale: field.scale,
                        pickListValues: field.pickListValues
                    };
                    const parts = field.fieldName.split('.');
                    let value = supplier;
                    let refId = null;
                    for (let i = 0; i < parts.length && value; i++) {
                        let part = parts[i];
                        if (i < parts.length - 1) {
                            if (part.endsWith('__c')) {
                                refId = value[part];
                                part = part.replace('__c', '__r');
                            } else if (part.endsWith('Id')) {
                                refId = value[part];
                                part = part.replace('Id', '');
                            } else if (part === 'Owner') refId = value.OwnerId;
                        } else if (part === 'Id') refId = value[part];
                        value = value[part];
                    }
                    wrapper.fieldValue = value || '';
                    wrapper.fieldOutputValue = value || '';
                    if (wrapper.isReference) {
                        if (field.fieldName === 'Name' || field.fieldName === 'Id') {
                            wrapper.link = '/' + supplier.Id;
                            if (field.fieldName === 'Id') wrapper.fieldOutputValue = supplier.Name || supplier.Id;
                        } else if (field.fieldName.endsWith('.Name')) {
                            const parentId = supplier[field.fieldName.split('.')[0] + 'Id'];
                            if (parentId) wrapper.link = '/' + parentId;
                        } else if (field.fieldName.endsWith('Id')) {
                            const lookupId = supplier[field.fieldName];
                            if (lookupId) {
                                wrapper.link = '/' + lookupId;
                                const rel = field.fieldName.replace('Id', '');
                                if (supplier[rel]?.Name) wrapper.fieldOutputValue = supplier[rel]?.Name;
                            }
                        } else if (refId) wrapper.link = '/' + refId;
                    }
                    if (wrapper.isPicklist && wrapper.fieldValue) {
                        const opt = wrapper.pickListValues?.find(
                            o => o.value === wrapper.fieldValue
                        );
                        if (opt) wrapper.fieldOutputValue = opt.label;
                    }
                    return wrapper;
                })
            };
        });
    }

    handleSupplierSearch(event) {
        const term = event.target.value.toLowerCase();
        this.supplierSearchTerm = term;
        this.filteredSuppliers = term ? this.allSuppliers.filter(supplier =>
            supplier.Name?.toLowerCase().includes(term) || supplier.values.some(v =>
                String(v.fieldOutputValue || v.fieldValue || '').toLowerCase().includes(term))) : [...this.allSuppliers];
    }

    handleSupplierCheckboxChange(event) {
        const { id } = event.target.dataset;
        const { checked } = event.target;
        const updateSelection = s => s.Id === id ? { ...s, isSelected: checked } : s;
        this.allSuppliers = this.allSuppliers.map(updateSelection);
        this.filteredSuppliers = this.filteredSuppliers.map(updateSelection);
        this.selectedSupplierIds = checked ? this.selectedSupplierIds.includes(id) ? this.selectedSupplierIds : [...this.selectedSupplierIds, id] : this.selectedSupplierIds.filter(sid => sid !== id);
    }

    handleSelectAllSuppliers(event) {
        let isChecked = event.target.checked;
        this.allSuppliers = this.allSuppliers.map(supplier => ({
            ...supplier,
            isSelected: supplier.isDisabled ? false : isChecked
        }));
        this.filteredSuppliers = this.filteredSuppliers.map(supplier => ({
            ...supplier,
            isSelected: supplier.isDisabled ? false : isChecked
        }));
        if (isChecked) {
            this.selectedSupplierIds = this.filteredSuppliers
                .filter(s => !s.isDisabled)
                .map(s => s.Id);
        } else this.selectedSupplierIds = [];
    }

    handleSendToSuppliers() {
        if (this.selectedSupplierIds.length === 0) {
            showNotification(this, this.Labels.LBL_Warning, this.Labels.MSG_LegalDocument_SelectAtLeastOneSupplier, 'warning');
            return;
        }
        this.isLoadingSuppliers = true;
        sendToSuppliers({
            legalDoc: JSON.stringify(this.legalDoc),
            supplierIds: this.selectedSupplierIds,
            notifType_serialized: JSON.stringify(this.notifType)
        })
            .then(() => {
                const message = this.Labels.MSG_LegalDocument_SentToSuppliersDocument.replace('{0}', this.selectedSupplierIds.length);
                showNotification(this, this.Labels.LBL_Success, message, 'success');
                this.handleCloseSupplierModal();
                this.loadData();
            })
            .catch(error => {
                console.error('Error sending to suppliers:', error);
                showNotification(this, this.Labels.LBL_Error, (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.isLoadingSuppliers = false;
            });
    }

    buildContactGridFields() {
        let gridFields = this.contactGridSettings.GRID_FIELDS || [];
        this.contactGridFields = gridFields.map(field => {
            let fieldType = field.fieldType || field.stringFieldType;
            let isReference = field.fieldName.endsWith('.Name');
            return {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                fieldType,
                isReference,
                isText: !isReference,
                headerStyle: field.fieldName === 'Name' ? 'width: 250px; max-width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;' : (field.headerStyle || ''),
                style: field.fieldName === 'Name' ? 'max-width: 250px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;' : (field.style || '')
            };
        });
    }

    handleContactSearch(event) {
        this.contactSearchTerm = event.target.value.toLowerCase();
        if (this.contactSearchTerm) {
            this.filteredContacts = this.allContacts.filter(contact =>
                contact.values.some(val =>
                    (val.fieldOutputValue || '')
                        .toString()
                        .toLowerCase()
                        .includes(this.contactSearchTerm)
                )
            );
        } else this.filteredContacts = [...this.allContacts];
    }

    buildContactData(contacts) {
        return contacts.map(contact => {
            let wrapper = { Id: contact.Id, values: [] };
            for (let field of this.contactGridFields) {
                let value = this.getNestedValue(contact, field.fieldName) || '';
                let fieldWrapper = {
                    fieldName: field.fieldName,
                    fieldOutputValue: value,
                    isReference: field.isReference,
                    isText: field.isText,
                    link: field.isReference && contact[COD_API.Contact__c] ? '/' + contact[COD_API.Contact__c] : '',
                    style: field.style
                };
                wrapper.values.push(fieldWrapper);
            }
            return wrapper;
        });
    }

    handleEditClause(event) {
        let clause;
        let clauseId;
        try {
            this.openChatterClauseId = null;
            this.openChatterType = null;
            clauseId = event.currentTarget.dataset.id;
            clause = this.allClauses.find(c => c.Id === clauseId);
            if (!clause) return;
            this.openClauseEditor(clause);
        } catch (error) {
            showNotification(this, this.Labels.LBL_Error, error.body?.message, 'error');
            if (clause) {
                this.openClauseEditor(clause);
            }
        }
    }
    openClauseEditor(clause) {
        const clauseId = clause.Id;
        // Add to expanded clauses if not already expanded
        if (!this.expandedClauseIds.includes(clauseId)) {
            this.expandedClauseIds = [...this.expandedClauseIds, clauseId];
        }
        this.displayClauses = this.displayClauses.map(c => c.Id === clauseId ?
            {
                ...c,
                isExpanded: true,
                editingClause: {
                    ...c,
                    get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
                    get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
                    get _ClauseType__c() { return this[LegalDocClause_API.ClauseType__c]; },
                    get _IsNegotiable__c() { return this[LegalDocClause_API.IsNegotiable__c]; },
                    get _BusinessOwners__c() { return this[LegalDocClause_API.BusinessOwners__c]; }
                },
            } : c);

        this.selectedBusinessOwners = clause[LegalDocClause_API.BusinessOwners__c] ? clause[LegalDocClause_API.BusinessOwners__c]?.split(';') : ['Legal'];
        this.isEditingNewVersionMap = { ...this.isEditingNewVersionMap, [clauseId]: false };
        this.selectedCompareVersionIds = { ...this.selectedCompareVersionIds, [clauseId]: null };
    }
    handleDeleteClause() {
        this.isLoading = true;
        let clause = this.clauses.find(c => c.Id === this.selectedClauseToDelete);
        try {
            if (this.isPortalUser) {
                let originClauseId = clause[LegalDocClause_API.LegalDocClauseField__c];
                let newClause = {
                    [LegalDocClause_API.LegalDoc__c]: this.recordId,
                    [LegalDocClause_API.Clause__c]: null, // Set clause content to null
                    [LegalDocClause_API.DisplayOrder__c]: clause[LegalDocClause_API.DisplayOrder__c],
                    [LegalDocClause_API.Status__c]: 'Draft', // Set status to Draft
                    [LegalDocClause_API.LegalStatus__c]: 'Open',
                    [LegalDocClause_API.PartnerStatus__c]: 'Draft',
                    [LegalDocClause_API.BusinessStatus__c]: 'Open',
                    [LegalDocClause_API.ClauseL1__c]: clause[LegalDocClause_API.ClauseL1__c],
                    [LegalDocClause_API.ClauseL2__c]: clause[LegalDocClause_API.ClauseL2__c],
                    [LegalDocClause_API.ClauseType__c]: clause[LegalDocClause_API.ClauseType__c],
                    [LegalDocClause_API.IsNegotiable__c]: clause[LegalDocClause_API.IsNegotiable__c],
                    [LegalDocClause_API.Supplier__c]: this.legalDoc[LegalDoc_API.Supplier__c],
                    [LegalDocClause_API.LegalDocClauseP1__c]: clause.Id,
                    [LegalDocClause_API.LegalDocClauseField__c]: originClauseId,
                    [LegalDocClause_API.BusinessOwners__c]: clause[LegalDocClause_API.BusinessOwners__c],
                    [LegalDocClause_API.UpdateOrigin__c]: 'Supplier',
                    [LegalDocClause_API.Version__c]: (clause[LegalDocClause_API.Version__c] || 0) + 1
                };
                saveClauses({
                    clausesJson: JSON.stringify([newClause]),
                    cloneComments: false,
                    relatedCommentsJson: JSON.stringify([])
                }).then(() => {
                    showNotification(this, this.Labels.LBL_Success, this.Labels.MSG_LegalDocument_ClauseMarkedForDeletion, 'success');
                    this.loadData();
                }).catch(error => {
                    console.error('Erreur lors de la suppression de la clause:', error);
                    showNotification(this, this.Labels.LBL_Error, (error.body?.message || error.message), 'error');
                    this.isLoading = false;
                });
            } else {
                if (this.legalDoc.RecordType.DeveloperName === 'Regular') {
                    deleteLegalDocumentClauses({ clausesIds: [clause.Id] })
                        .then(() => {
                            showNotification(this, this.Labels.LBL_Success, this.Labels.MSG_LegalDocument_ClauseDeleted, 'success');
                            this.loadData();
                        }).catch(error => {
                            console.error('Erreur lors de la suppression de la clause:', error);
                            showNotification(this, this.Labels.LBL_Error, (error.body?.message || error.message), 'error');
                            this.isLoading = false;
                        });
                } else {
                    this.selectedIdsToDelete.push(this.selectedClauseToDelete);
                    this.displayClauses = this.displayClauses.map(c => c.Id === this.selectedClauseToDelete ?
                        {
                            ...c,
                            isMarkedForDeletion: !this.isPortalUser && this.selectedIdsToDelete.includes(c.Id),
                            itemClass: this.getClauseItemClass(c),
                        } : c);
                }
                this.isLoading = false;
            }
        } catch (e) {
            console.log('error delete clause :' + e);
            console.log('error delete clause :' + e.message);
        }
    }

    handleToggleEditMode(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            this.isEditingNewVersionMap = {
                ...this.isEditingNewVersionMap,
                [clauseId]: !this.isEditingNewVersionMap[clauseId]
            };

            const clause = this.clauses.find(c => c.Id === clauseId);
            if (!clause) return;
            if (this.isEditingNewVersionMap[clauseId] && !clause.editingClause) {
                clause.editingClause = { ...clause };
            }
            this.displayClauses = this.displayClauses.map(c => c.Id === clauseId ?
                {
                    ...c,
                    isEditingNewVersion: this.isEditingNewVersionMap[clauseId],
                    itemClass: this.getClauseItemClass(c)
                } : c);
            this.clauses = [...this.clauses];
        }
    }
    handleEditClauseChange(event) {
        const clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        const field = event?.currentTarget?.dataset?.field || event?.target?.dataset?.field;
        if (!clauseId || !field /*|| !this.editingClauses?.[clauseId]*/) {
            return;
        }
        let newValue;
        if (event.target.type === 'checkbox') {
            newValue = event.target.checked;
        } else if (Array.isArray(event.detail?.value)) {
            newValue = event.detail.value.join(';');
        } else {
            newValue = event.detail?.value ?? event.target.value ?? '';
        }
        if (field === LegalDocClause_API.BusinessOwners__c && Array.isArray(event.detail?.value)) {
            this.selectedBusinessOwners = event.detail.value;
        }
        this.displayClauses = this.displayClauses.map(c =>
            c.Id === clauseId
                ? {
                    ...c,
                    editingClause: {
                        ...c.editingClause,
                        [field]: newValue,
                        get _Clause__c() { return this[LegalDocClause_API.Clause__c]; },
                        get _DisplayOrder__c() { return this[LegalDocClause_API.DisplayOrder__c]; },
                        get _ClauseType__c() { return this[LegalDocClause_API.ClauseType__c]; },
                        get _IsNegotiable__c() { return this[LegalDocClause_API.IsNegotiable__c]; },
                        get _BusinessOwners__c() { return this[LegalDocClause_API.BusinessOwners__c]; }
                    },
                    isEditingNewVersion: this.isEditingNewVersionMap[c.Id]
                }
                : c
        );
    }
    hasClauseChanges(clauseId) {
        let editingClause = this.displayClauses.find(c => c.Id === clauseId);
        if (!editingClause) return false;
        let originalHtml = (editingClause[LegalDocClause_API.Clause__c] || '').trim();
        let currentHtml = (editingClause.editingClause[LegalDocClause_API.Clause__c] || '').trim();
        if (originalHtml !== currentHtml) {
            return true;
        }
        let originalIsNegotiable = editingClause[LegalDocClause_API.IsNegotiable__c] || false;
        let newIsNegotiable = editingClause.editingClause[LegalDocClause_API.IsNegotiable__c] || false;
        if (originalIsNegotiable !== newIsNegotiable) {
            return true;
        }
        let originalBusinessOwners = editingClause[LegalDocClause_API.BusinessOwners__c] || '';
        let newBusinessOwners = editingClause.editingClause[LegalDocClause_API.BusinessOwners__c] || '';
        if (originalBusinessOwners !== newBusinessOwners) {
            return true;
        }
        return false;
    }
    handleSaveClause(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let type = event?.currentTarget?.dataset?.type || event?.target?.dataset?.type;
        //let editingClause = this.expandedClauseIds[clauseId];
        if (!this.expandedClauseIds.includes(clauseId)) return;
        if (!this.hasClauseChanges(clauseId)) {
            showNotification(this, this.Labels.LBL_Warning, this.Labels.MSG_LegalDocument_NoChangesMade, 'warning');
            return;
        }
        // Show confirmation modal
        this.selectedClauseToSave = clauseId;
        this.saveType = type;
        this.openModal({
            title: this.Labels.LBL_Confirm,
            message: this.Labels.LBL_LD_confirmationMessage,
            confirmLabel: this.Labels.LBL_Save,
            onConfirmAction: () => this.handleConfirmSave()
        });
    }
    handleConfirmSave() {
        // if (!this.selectedClauseToSave && this.clauseId) {
        //     this.selectedClauseToSave = this.clauseId;
        // }
        let editingClause = this.displayClauses.find(c => c.Id === this.selectedClauseToSave).editingClause;
        if (!editingClause) {
            return;
        }
        if (this.saveType === 'full') {
            this.proceedWithSaveClause(this.selectedClauseToSave, editingClause);
        } else if (this.saveType === 'simple') {
            this.proceedWithSaveSimpleEdit(this.selectedClauseToSave, editingClause);
        }
        this.clauseId = null;
    }
    // ==================== SIMPLE EDIT (No Supplier Mode) ====================
    proceedWithSaveSimpleEdit(clauseId, editingClause) {
        let clauseToSave = {
            Id: editingClause.Id,
            [LegalDocClause_API.Clause__c]: editingClause[LegalDocClause_API.Clause__c],
            [LegalDocClause_API.IsNegotiable__c]: editingClause[LegalDocClause_API.IsNegotiable__c] || false,
            [LegalDocClause_API.BusinessOwners__c]: editingClause[LegalDocClause_API.BusinessOwners__c]
        };
        let data = [];
        data.push(clauseToSave);
        saveClauses({
            clausesJson: JSON.stringify(data), cloneComments: false,
            relatedCommentsJson: JSON.stringify([])
        }).then(() => {
            this.selectedClauseToSave = null;
            this.saveType = null;
            showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_ClauseUpdatedSuccessfully, 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            showNotification(this, this.Labels.LBL_Error, 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
            this.selectedClauseToSave = null;
            this.saveType = null;
        });
    }

    // ==================== full EDIT (Supplier Mode) ====================
    proceedWithSaveClause(clauseId, editingClause) {
        let createNew = false;
        let originalHtml = (editingClause.originalClause || '').trim();
        let currentHtml = (editingClause[LegalDocClause_API.Clause__c] || '').trim();
        if (originalHtml !== currentHtml) {
            createNew = true;
        }
        let cloneComments = false;
        let relatedComments = this.trackActions?.[clauseId] || [];
        let originClauseId = editingClause[LegalDocClause_API.LegalDocClauseField__c];
        let newClause = {
            [LegalDocClause_API.LegalDoc__c]: this.recordId,
            [LegalDocClause_API.Clause__c]: editingClause[LegalDocClause_API.Clause__c],
            [LegalDocClause_API.DisplayOrder__c]: editingClause[LegalDocClause_API.DisplayOrder__c],
            [LegalDocClause_API.Status__c]: editingClause[LegalDocClause_API.Status__c] || 'Open',
            [LegalDocClause_API.LegalStatus__c]: editingClause[LegalDocClause_API.LegalStatus__c],
            [LegalDocClause_API.PartnerStatus__c]: editingClause[LegalDocClause_API.PartnerStatus__c],
            [LegalDocClause_API.BusinessStatus__c]: editingClause[LegalDocClause_API.BusinessStatus__c],
            [LegalDocClause_API.ClauseL1__c]: editingClause[LegalDocClause_API.ClauseL1__c],
            [LegalDocClause_API.ClauseL2__c]: editingClause[LegalDocClause_API.ClauseL2__c],
            [LegalDocClause_API.ClauseType__c]: editingClause[LegalDocClause_API.ClauseType__c],
            [LegalDocClause_API.IsNegotiable__c]: editingClause[LegalDocClause_API.IsNegotiable__c],
            [LegalDocClause_API.Supplier__c]: this.legalDoc[LegalDoc_API.Supplier__c],
            [LegalDocClause_API.LegalDocClauseP1__c]: editingClause.Id,
            [LegalDocClause_API.LegalDocClauseField__c]: originClauseId,
            [LegalDocClause_API.BusinessOwners__c]: editingClause[LegalDocClause_API.BusinessOwners__c],

        };
        if (this.isPortalUser) {
            if (editingClause[LegalDocClause_API.UpdateOrigin__c] == 'Supplier' && editingClause[LegalDocClause_API.Status__c] == 'Draft') {
                newClause.Id = editingClause.Id;
                newClause[LegalDocClause_API.LegalDocClauseP1__c] = editingClause[LegalDocClause_API.LegalDocClauseP1__c];
                newClause[LegalDocClause_API.LegalDocClauseField__c] = editingClause[LegalDocClause_API.LegalDocClauseField__c];
            } else {
                newClause[LegalDocClause_API.Status__c] = 'Draft';
                newClause[LegalDocClause_API.LegalStatus__c] = 'Open';
                newClause[LegalDocClause_API.BusinessStatus__c] = 'Open';
                newClause[LegalDocClause_API.PartnerStatus__c] = 'Draft';
                newClause[LegalDocClause_API.UpdateOrigin__c] = 'Supplier';
                newClause[LegalDocClause_API.Version__c] = (editingClause[LegalDocClause_API.Version__c] || 0) + 1;
                cloneComments = true;
            }
        } else if (this.isLegal) {
            if (editingClause[LegalDocClause_API.UpdateOrigin__c] == 'Legal' && editingClause[LegalDocClause_API.Status__c] == 'Draft') {
                newClause.Id = editingClause.Id;
                newClause[LegalDocClause_API.LegalDocClauseP1__c] = editingClause[LegalDocClause_API.LegalDocClauseP1__c];
                newClause[LegalDocClause_API.LegalDocClauseField__c] = editingClause[LegalDocClause_API.LegalDocClauseField__c];
            } else {
                if (!createNew) {
                    newClause.Id = editingClause.Id;
                    newClause[LegalDocClause_API.LegalDocClauseP1__c] = editingClause[LegalDocClause_API.LegalDocClauseP1__c];
                    newClause[LegalDocClause_API.LegalDocClauseField__c] = editingClause[LegalDocClause_API.LegalDocClauseField__c];
                } else {
                    newClause[LegalDocClause_API.Status__c] = 'Draft';
                    newClause[LegalDocClause_API.LegalStatus__c] = 'Draft';
                    newClause[LegalDocClause_API.BusinessStatus__c] = 'Open';
                    newClause[LegalDocClause_API.PartnerStatus__c] = 'Open';
                    newClause[LegalDocClause_API.UpdateOrigin__c] = 'Legal';
                    newClause[LegalDocClause_API.Version__c] = (editingClause[LegalDocClause_API.Version__c] || 0) + 1;
                    cloneComments = true;
                }
            }
        } else {
            if (editingClause[LegalDocClause_API.UpdateOrigin__c] == 'BusinessOwner' && editingClause[LegalDocClause_API.Status__c] == 'Draft') {
                newClause.Id = editingClause.Id;
                newClause[LegalDocClause_API.LegalDocClauseP1__c] = editingClause[LegalDocClause_API.LegalDocClauseP1__c];
                newClause[LegalDocClause_API.LegalDocClauseField__c] = editingClause[LegalDocClause_API.LegalDocClauseField__c];
            } else {
                newClause[LegalDocClause_API.Status__c] = 'Draft';
                newClause[LegalDocClause_API.LegalStatus__c] = 'Open';
                newClause[LegalDocClause_API.BusinessStatus__c] = 'Draft';
                newClause[LegalDocClause_API.PartnerStatus__c] = 'Open';
                newClause[LegalDocClause_API.UpdateOrigin__c] = 'BusinessOwner';
                newClause[LegalDocClause_API.Version__c] = (editingClause[LegalDocClause_API.Version__c] || 0) + 1;
                cloneComments = true;
            }
        }
        let data = [];
        data.push(newClause);
        saveClauses({
            clausesJson: JSON.stringify(data),
            cloneComments: cloneComments,
            relatedCommentsJson: JSON.stringify(relatedComments)
        }).then(() => {
            let version = newClause?.[LegalDocClause_API.Version__c] ? newClause?.[LegalDocClause_API.Version__c] : editingClause[LegalDocClause_API.Version__c];
            this.selectedClauseToSave = null;
            this.saveType = null;
            const newVersionLabel = this.Labels.MSG_LegalDocument_NewVersionCreated.replace('{0}', version);
            showNotification(this, this.Labels.LBL_Success, newVersionLabel, 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            showNotification(this, this.Labels.LBL_Error, 'Erreur: ' + error.body?.message, 'error');
            this.selectedClauseToSave = null;
            this.saveType = null;
        });
    }
    handleCloseInlineEdit(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let saveType = event?.currentTarget?.dataset?.type || event?.target?.dataset?.type;
        if (!this.hasClauseChanges(clauseId)) {
            this.clauseId = clauseId;
            this.closeCancelEditModel();
            return;
        }
        this.selectedClauseToSave = clauseId;
        this.clauseId = clauseId;
        this.saveType = saveType;
        this.openModal({
            title: this.Labels.LBL_Confirm,
            message: this.Labels.LBL_LD_confirmationMessage,
            confirmLabel: this.Labels.LBL_Close,
            onConfirmAction: () => this.handleConfirmSave(),
            onCloseAction: () => this.closeCancelEditModel()
        });
    }
    closeCancelEditModel(event) {
        try {
            if (this.clauseId) {
                this.expandedClauseIds = this.expandedClauseIds.filter(id => id !== this.clauseId);

                let newEditingMap = { ...this.isEditingNewVersionMap };
                delete newEditingMap[this.clauseId];
                this.isEditingNewVersionMap = newEditingMap;

                let newCompareMap = { ...this.selectedCompareVersionIds };
                delete newCompareMap[this.clauseId];
                this.selectedCompareVersionIds = newCompareMap;
                this.selectedBusinessOwners = ['Legal'];
                this.displayClauses = this.displayClauses.map(c => c.Id === this.clauseId ?
                    {
                        ...c,
                        isExpanded: false,
                        editingClause: {},
                        isEditingNewVersion: this.isEditingNewVersionMap[c.Id]
                    } : c);
            }
            this.saveType = null;
        } catch (error) {
            console.log('error close edit modal:' + error);
            console.log('error close edit modal:' + error.message);
        }

    }
    // Helper method to close a specific editing clause
    closeEditingClause(clauseId) {
        if (clauseId) {
            this.expandedClauseIds = this.expandedClauseIds.filter(id => id !== clauseId);
            let newEditingMap = { ...this.isEditingNewVersionMap };
            delete newEditingMap[clauseId];
            this.isEditingNewVersionMap = newEditingMap;
            let newCompareMap = { ...this.selectedCompareVersionIds };
            delete newCompareMap[clauseId];
            this.selectedCompareVersionIds = newCompareMap;
        }
    }
    // ==================== GLOBAL ACTION HANDLERS ====================
    //publishing management
    publishAllClauses() {
        let hasdraftComments = !this.isPortalUser ? this.allComments?.some(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && act[TrackAction_API.Comment__c] && !act[TrackAction_API.IsPortalPublished__c]) : false;
        if (hasdraftComments) {
            this.openModal({
                title: this.Labels.LBL_Confirm,
                message: this.Labels.MSG_LD_BOPublishClauses_Alert,
                confirmLabel: this.Labels.LBL_Proceed,
                onConfirmAction: () => this.handlePublishAllCmntsAndDrafts()
            });
        } else {
            this.handlePublishAllCmntsAndDrafts();
        }
    }
    handlePublishAllCmntsAndDrafts() {
        this.isLoading = true;
        let userType = this.isPortalUser ? 'Supplier' : this.isLegal ? 'Legal' : this.isBOUser ? 'Business Owner' : null;
        let draftCmnts = [];
        if (this.isLegal) {
            draftCmnts = this.allComments?.filter(act => (act[TrackAction_API.CommentStatus__c] == 'Draft' || (act[TrackAction_API.CommentOrigin__c] == 'Business Owner' && act[TrackAction_API.IsPortalPublished__c])) && act[TrackAction_API.Comment__c]);
        }
        else {
            draftCmnts = this.allComments?.filter(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && act[TrackAction_API.Comment__c] && (!this.isBOUser || act[TrackAction_API.IsPortalPublished__c] === true));
        }
        let sendNotifLegalToBO = this.allComments?.some(c => !c[TrackAction_API.IsPortalPublished__c] && c[TrackAction_API.Comment__c] && c[TrackAction_API.CommentStatus__c] == 'Draft' && c[TrackAction_API.CommentOrigin__c] == 'Legal');
        let sendNotifLegalToSup = this.allComments?.some(c => c[TrackAction_API.IsPortalPublished__c] && c[TrackAction_API.Comment__c] && ((c[TrackAction_API.CommentStatus__c] === 'Draft' && c[TrackAction_API.CommentOrigin__c] == 'Legal') || c[TrackAction_API.CommentOrigin__c] == 'Business Owner'));
        let parentClauses = [...new Set(
            draftCmnts.map(c => c[TrackAction_API.ParentId__c])
        )];
        let draftClauses = this.allClauses.filter(clause =>
            (this.isBOUser ? (clause[LegalDocClause_API.Status__c] === 'Draft' && clause[LegalDocClause_API.Updatedby__c] === this.currentUser.Id) : clause[LegalDocClause_API.Status__c] === 'Draft'
            ) ||
            (this.isLegal && clause[LegalDocClause_API.Status__c] === 'Business owner publishing' && clause[LegalDocClause_API.UpdateOrigin__c]?.toLowerCase() === 'businessowner')
        );
        publishAllDrafts({
            legalDocId: this.recordId,
            userType: userType,
            draftClauses_serialized: JSON.stringify(draftClauses),
            notifType_serialized: JSON.stringify(this.notifType),
            user_serialized: JSON.stringify(this.userMap),
            parentClauseIds_serialized: JSON.stringify(parentClauses),
            draftCmnts_serialized: JSON.stringify(draftCmnts),
            sendNotifLegalToBO: sendNotifLegalToBO,
            sendNotifLegalToSup: sendNotifLegalToSup,
            selectedIdsToDelete_serialized: JSON.stringify(this.selectedIdsToDelete)
        }).then((result) => {
            if (result.includes('ERR'))
                showNotification(this, this.Labels.LBL_Error, result, 'error');
            else if (result.includes('Success')) {
                showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_AllClausesAndCommentsPublished, 'success');
            } else {
                showNotification(this, 'Info', result, 'info');
            }
            this.loadData();
        }).catch(error => {
            showNotification(this, this.Labels.LBL_Error, 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handlePublishAllBoCmnts() {
        this.isLoading = true;
        try {
            let draftCmnts = [];
            if (this.isLegal) {
                //draftCmnts = this.allComments?.filter(act => (act[TrackAction_API.CommentStatus__c] == 'Draft' || (act[TrackAction_API.CommentOrigin__c] == 'Business Owner' && act[TrackAction_API.IsPortalPublished__c])) && act[TrackAction_API.Comment__c]);
                draftCmnts = this.allComments?.filter(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && act[TrackAction_API.Comment__c] && !act[TrackAction_API.IsPortalPublished__c] && act[TrackAction_API.CommentOrigin__c] == 'Legal');
            }
            else {
                draftCmnts = this.allComments?.filter(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && act[TrackAction_API.Comment__c] && !act[TrackAction_API.IsPortalPublished__c] && act[TrackAction_API.CommentOrigin__c] == 'Business Owner');
            }
            let parentClauses = [...new Set(
                draftCmnts.map(c => c[TrackAction_API.ParentId__c])
            )];
            publishBOLegalComments({
                legalDocId: this.recordId,
                userType: this.isLegal ? 'Legal' : this.isBOUser ? 'Business Owner' : null,
                draftComments_serialized: JSON.stringify(draftCmnts),
                parentClauseIds_serialized: JSON.stringify(parentClauses),
                sendNotifLegalToBO: this.isLegal,
                notifType_serialized: JSON.stringify(this.notifType)
            }).then((result) => {
                if (result.includes('ERR'))
                    showNotification(this, this.Labels.LBL_Error, result, 'error');
                else if (result.includes('Success')) {
                    showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_AllCommentsPublished, 'success');
                } else {
                    showNotification(this, 'Info', result, 'info');
                }
                this.loadData();
            })
        } catch (e) {
            showNotification(this, this.Labels.LBL_Error, `${this.Labels.LBL_Error}: ` + (error.body?.message || error.message || this.Labels.LBL_Error), 'error');
        }

    }
    checkBOHasDraftsOrPublishing() {
        let hasDraftOrPublishing = false;
        if (this.isLegal) {
            hasDraftOrPublishing = this.allClauses.some(clause => {
                let status = clause[LegalDocClause_API.Status__c]?.toLowerCase() || '';
                if (status === 'rejected') {
                    return false;
                }
                let hasDraftClauses = false;
                let hasDraftComments = false;
                let updateOrigin = clause[LegalDocClause_API.UpdateOrigin__c]?.toLowerCase() || '';
                hasDraftClauses = updateOrigin === 'businessowner' && (status === 'draft' || status === 'business owner publishing');
                let trackActions = this.trackActions?.[clause.Id];
                hasDraftComments = trackActions?.some(act => {
                    let commentOrigin = act[TrackAction_API.CommentOrigin__c]?.toLowerCase() || '';
                    let status = act[TrackAction_API.CommentStatus__c]?.toLowerCase() || '';
                    let isPortalPublished = act[TrackAction_API.IsPortalPublished__c];
                    return commentOrigin === 'business owner' && (status === 'draft' || status === 'published') && isPortalPublished;
                })
                return hasDraftClauses || hasDraftComments;
            });
        }
        return hasDraftOrPublishing;
    }

    ValidateClauses(event) {
        let type = event.currentTarget.dataset.type;
        if (type === 'singlevalidate') {
            let clauseId = event.currentTarget.dataset.id;
            // let clause = this.allClauses.find(c => c.Id === clauseId);
            // if (!clause) {
            //     return;
            // }
            // let clauseList = [clause];
            this.handleValidateAll(clauseId);
        } else if (type === 'validateall') {
            let isDraft = this.checkDraftCmntsAndClauses();
            let isBOHasDraftsOrPublishing = false;
            if (this.isLegal) {
                isBOHasDraftsOrPublishing = this.checkBOHasDraftsOrPublishing();
            }
            if (isDraft || isBOHasDraftsOrPublishing) {
                //this.openValidateModal();
                this.openModal({
                    title: this.Labels.LBL_Confirm,
                    message: this.Labels.MSG_LD_ValidateClause,
                    confirmLabel: this.Labels.LBL_Proceed,
                    onConfirmAction: () => this.handleValidateAll(null)
                });
                return;
            }
            this.handleValidateAll(null);
        }
    }
    handleValidateAll(clauseId) {
        this.isLoading = true;
        let clauses;
        if (!clauseId) {
            const clauseIds = new Set(this.clauses.map(c => c.Id));
            clauses = this.allClauses.filter(clause => {
                if (!clauseIds.has(clause.Id)) {
                    return false;
                }
                const status = clause[LegalDocClause_API.Status__c];
                const origin = clause[LegalDocClause_API.UpdateOrigin__c];
                if (this.isPortalUser) {
                    return clause[LegalDocClause_API.IsNegotiable__c] === true
                        && status !== 'Draft'
                        && status !== 'published'
                        && (status !== 'Validated' || (status === 'Validated' && origin !== 'Supplier'));
                }
                return clause[LegalDocClause_API.IsNegotiable__c] === true
                    && status !== 'Draft'
                    && status !== 'legal publishing'
                    && status !== 'Business owner publishing'
                    && (status !== 'Validated' || (status === 'Validated' && origin !== 'Legal'));
            });
        } else {
            let clause = this.allClauses.find(c => c.Id === clauseId);
            clauses = [clause];
        }
        validateAllClauses({
            legalDocId: this.recordId,
            isPortal: this.isPortalUser,
            notifType_serialized: JSON.stringify(this.notifType),
            user_serialized: JSON.stringify(this.userMap),
            clauseId: clauseId,
            clausesToValidate_serialized: JSON.stringify(clauses),
        }).then(() => {
            showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_AllClausesValidated, 'success');
            //this.handleCloseValidatePopup();
            this.loadData();
        }).catch(error => {
            showNotification(this, this.Labels.LBL_Error, `${this.Labels.LBL_Error}: ` + (error.body?.message || error.message || 'Unknown error'), 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }
    //approve process
    handleApproveAll() {
        let isDraft = this.checkDraftCmntsAndClauses();
        if (isDraft) {
            //this.openApproveModal();
            this.openModal({
                title: this.Labels.LBL_Confirm,
                message: this.Labels.MSG_LD_ValidateClause,
                confirmLabel: this.Labels.LBL_Proceed,
                onConfirmAction: () => this.proceedWithApproveAll()
            });
            return;
        }
        this.proceedWithApproveAll();
    }

    proceedWithApproveAll() {
        this.isLoading = true;
        let clauses;
        const clauseIds = new Set(this.clauses.map(c => c.Id));
        if ((this.isPortalUser && this.legalDoc[LegalDoc_API.PartnerStatus__c] === 'Validated') || (!this.isPortalUser && this.legalDoc[LegalDoc_API.PartnerStatus__c] === 'Approved')) {
            clauses = this.allClauses.filter(clause =>
                clauseIds.has(clause.Id)
            );
        }
        approveAllClauses({
            legalDocId: this.recordId,
            clausesToApprove_serialized: JSON.stringify(clauses),
            notifType_serialized: JSON.stringify(this.notifType),
            user_serialized: JSON.stringify(this.userMap),
        }).then(() => {
            showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_AllClausesApproved, 'success');
            this.loadData();
        })
            .catch(error => {
                showNotification(this, this.Labels.LBL_Error, `${this.Labels.LBL_Error}: ` + (error.body?.message || error.message || 'Unknown error'), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    // ==================== DRAG AND DROP HANDLERS ====================
    handleDragStart(event) {
        const status = (this.legalDoc?.[LegalDoc_API.Status__c] || '').trim().toLowerCase();
        if (this.isPortalUser || status === 'approved' || status === 'ready to sign') return;
        this.draggedClauseId = event.currentTarget.dataset.id;
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedClauseId);
        // Store original order if not already stored
        if (!this.hasOrderChanged) {
            this.originalOrder = this.clauses.map(c => ({
                Id: c.Id,
                [LegalDocClause_API.DisplayOrder__c]: c[LegalDocClause_API.DisplayOrder__c]
            }));
        }
        setTimeout(() => {
            event.currentTarget.classList.add('dragging');
        }, 0);
    }

    handleDragOver(event) {
        if (this.isPortalUser) return;
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDragEnter(event) {
        if (this.isPortalUser) return;
        event.preventDefault();
        let targetElement = event.currentTarget;
        if (targetElement.dataset.id !== this.draggedClauseId) {
            targetElement.classList.add('drag-over');
        }
    }

    handleDragLeave(event) {
        if (this.isPortalUser) return;
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        if (this.isPortalUser) return;
        event.preventDefault();

        let targetElement = event.currentTarget;
        targetElement.classList.remove('drag-over');

        let targetClauseId = targetElement.dataset.id;

        if (targetClauseId && this.draggedClauseId && targetClauseId !== this.draggedClauseId) {
            this.reorderClauses(this.draggedClauseId, targetClauseId);
        }
    }

    handleDragEnd(event) {
        if (this.isPortalUser) return;
        event.currentTarget.classList.remove('dragging');
        this.draggedClauseId = null;
        let allItems = this.template.querySelectorAll('.clause-item-wrapper');
        allItems.forEach(item => item.classList.remove('drag-over', 'dragging'));
    }

    reorderClauses(draggedId, targetId) {
        let clausesCopy = [...this.clauses];
        let draggedIndex = clausesCopy.findIndex(c => c.Id === draggedId);
        let targetIndex = clausesCopy.findIndex(c => c.Id === targetId);
        if (draggedIndex === -1 || targetIndex === -1) {
            return;
        }
        let [draggedClause] = clausesCopy.splice(draggedIndex, 1);
        clausesCopy.splice(targetIndex, 0, draggedClause);
        clausesCopy.forEach((clause, index) => {
            clause[LegalDocClause_API.DisplayOrder__c] = index + 1;
        });
        this.clauses = [...clausesCopy];
        this.hasOrderChanged = true;
        this.applyClauseFilters();
    }

    handleGlobalVariableChange(event) {
        const fieldKey = event.target.dataset.fieldKey;
        const originalValue = event.target.dataset.originalValue || '';
        const newValue = event.detail.value;
        this.mergeObjects = this.mergeObjects.map(section => ({
            ...section,
            wFieldWrapperList: section.wFieldWrapperList.map(field => {
                if (field.fieldValue === fieldKey) {
                    return { ...field, overrideValue: newValue };
                }
                return field;
            })
        }));
        if (newValue !== originalValue) {
            this.changedGlobalVariables = {
                ...this.changedGlobalVariables,
                [fieldKey]: newValue
            };
        } else {
            const { [fieldKey]: removed, ...rest } = this.changedGlobalVariables;
            this.changedGlobalVariables = rest;
        }
        this.objectOptions = this.mergeObjects.map((object) => {
            let label = object.fieldLabel;
            const value = object.fieldValue || '';
            const normalizedValue = value.toLowerCase();
            if (normalizedValue.includes('supplier')) {
                //label = this.Labels.LBL_LegalDocument_Signatory;
                label = this.fieldLabels?.Supplier__c.Signatory__c;
            }
            if (normalizedValue.includes('contact')) {
                //label = this.Labels.LBL_LegalDocument_SupplierSignatory;
                label = this.fieldLabels?.Contact.MainFrameworkSignatory__c;
            }
            return { label, value };
        });
    }

    confirmSaveGlobalVariables() {
        this.showGlobalVariablesPopup = false;
        this.isLoading = true;
        let userType = 'Legal';
        if (this.isPortalUser) {
            userType = 'Supplier';
        } else if (this.isBOUser && !this.isLegal) {
            userType = 'BusinessOwner';
        }
        // Build object IDs map
        let objectIds = {};
        if (this.adminGL?.Id) {
            objectIds.GlobalLocationId = this.adminGL.Id;
        }
        if (this.internalSignatoryInfo?.Id) {
            objectIds.ContactId = this.internalSignatoryInfo.Id;
        }
        if (this.supplierSignaotoryInfo?.Id) {
            objectIds.SignatoryUserId = this.supplierSignaotoryInfo.Id;
        }
        const clauseIds = new Set(this.clauses.map(c => c.Id));
        let clauses = this.allClauses.filter(clause => clauseIds.has(clause.Id));
        saveGlobalVariables({
            legalDocId: this.recordId,
            updatedFieldsJson: JSON.stringify(this.changedGlobalVariables),
            userType: userType,
            objectIdsJson: JSON.stringify(objectIds),
            clausesJson: JSON.stringify(clauses)
        }).then(result => {
            const newClauses = JSON.parse(result);
            if (newClauses.length > 0) {
                showNotification(this, Labels.LBL_Success, `${newClauses.length}` + Labels.MSG_LegalDocument_DraftClausesUpdated, 'success');
            } else {
                showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_GlobalVariablesSavedNoClauseAffected, 'success');
            }
            this.changedGlobalVariables = {};
            this.initData();
        })
            .catch(error => {
                console.error('Error saving global variables:', error);
                showNotification(this, Labels.LBL_Error, (error.body?.message || error.message || 'Unknown error'), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSaveOrder() {
        if (!this.hasOrderChanged) return;
        this.isLoading = true;
        const clausesToUpdate = this.clauses.map(clause => ({
            Id: clause.Id,
            [LegalDocClause_API.DisplayOrder__c]:
                clause[LegalDocClause_API.DisplayOrder__c]
        }));
        saveClauses({
            clausesJson: JSON.stringify(clausesToUpdate), cloneComments: false,
            relatedCommentsJson: JSON.stringify([])
        }).then(() => {
            this.hasOrderChanged = false;
            this.originalOrder = [];
            showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_ClauseOrderSaved, 'success');
            this.loadData();
        }).catch(error => {
            showNotification(this, Labels.LBL_Error, (error.body?.message || error.message), 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }
    handlePageFiltersChange(event) {
        const type = event.target.dataset.type;
        const value = type === 'ownedByUser'
            ? event.target.checked
            : event.detail.value;
        this.pageFilters = {
            ...this.pageFilters,
            [type]: value
        };
        this.applyClauseFilters();
    }
    // Business owner
    sendReminderToBusinessOwner() {
        this.isLoading = true;
        const clauseIds = new Set(this.clauses.map(c => c.Id));
        clauses = this.allClauses.filter(clause =>
            clauseIds.has(clause.Id)
        );
        sendToBusinessOwner({
            legalDocId: this.legalDoc.Id,
            clauses: JSON.stringify(clauses),
            notifType_serialized: JSON.stringify(this.notifType)
        }).then(() => {
            showNotification(this, Labels.LBL_Success, Labels.MSG_LegalDocument_SendToBusinessOwner, 'success');
            this.loadData();
        }).catch(error => {
            this.isLoading = false;
            showNotification(this, this.Labels.LBL_Error, (error.body?.message || error.message), 'error');
        })
    }
    openMergeFieldModal(event) {
        this.activeClauseId = event.currentTarget.dataset.id;
        const selection = window.getSelection();
        if (selection && selection.rangeCount > 0) {
            this.savedSelection = selection.getRangeAt(0);
        } else {
            if (!this.activeClauseId || this.activeClauseId === '') {
                try {
                    const richTextEditor = this.template.querySelector('.clause-rich-text-editor');
                    if (richTextEditor) {
                        const iframe = richTextEditor.shadowRoot?.querySelector('iframe');
                        if (iframe && iframe.contentWindow) {
                            const iframeSelection = iframe.contentWindow.getSelection();
                            if (iframeSelection && iframeSelection.rangeCount > 0) {
                                this.savedSelection = iframeSelection.getRangeAt(0);
                            }
                        }
                    }
                } catch (e) {
                    console.warn('Could not access rich text editor selection:', e);
                }
            }
        }
        this.isMergeFieldModalOpen = true;
    }

    closeMergeFieldModal() {
        this.isMergeFieldModalOpen = false;
        this.savedSelection = null;
        this.activeClauseId = null;
        this.selectedField = null;
        this.selectedFieldInfo = null;
        this.selectedObject = null;
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedField = null;
        this.selectedFieldInfo = null;
        try {
            const obj = this.mergeObjects.find(o => o.fieldValue === this.selectedObject);
            this.fieldOptions = (obj?.wFieldWrapperList || []).map((field) => ({
                label: field.fieldLabel,
                value: field.fieldValue
            }));
        } catch (error) {
            console.warn('Error while setting field options');
            console.error(error.message);
        }
    }

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
        const obj = this.mergeObjects.find(o => o.fieldValue === this.selectedObject);
        const fieldInfo = obj?.wFieldWrapperList.find(f => f.fieldValue === this.selectedField);
        if (!fieldInfo) {
            this.selectedFieldInfo = null;
            return;
        }
        let suffix = '';
        if (this.selectedObject?.toLowerCase().includes('supplier')) {
            //suffix = this.Labels.LBL_LegalDocument_Signatory;
            suffix = this.fieldLabels?.Supplier__c.Signatory__c;
        } else if (this.selectedObject?.toLowerCase().includes('contact')) {
            //suffix = this.Labels.LBL_LegalDocument_SupplierSignatory;
            suffix = this.fieldLabels?.Contact.MainFrameworkSignatory__c;
        }
        this.selectedFieldInfo = {
            ...fieldInfo,
            fieldLabel: fieldInfo.fieldLabel + (suffix ? ` ${this.Labels.LBL_Of} ${suffix}` : '')
        };
    }
    insertSelectedMergeFields() {
        if (!this.selectedField) return;
        this.proceedWithInsertMergeFields();
    }

    proceedWithInsertMergeFields() {
        const html = `<span class="merge-field" data-field="${this.selectedField}" contenteditable="false">{!${this.selectedField}}</span>&nbsp;`;
        if (!this.activeClauseId || this.activeClauseId === '') {
            const currentValue = this.newClause[LegalDocClause_API.Clause__c] || '';
            let updatedValue;
            if (this.savedSelection && this.savedSelection.toString() !== '') {
                updatedValue = currentValue + html;
            } else {
                updatedValue = currentValue + html;
            }
            this.newClause = {
                ...this.newClause,
                [LegalDocClause_API.Clause__c]: updatedValue,
                get _Clause__c() { return this[LegalDocClause_API.Clause__c]; }
            };
        } else {
            if (!this.savedSelection) {
                showNotification(this, Labels.LBL_LegalDocument_CursorRequired, Labels.MSG_LegalDocument_CursorRequired, 'warning');
                this.closeMergeFieldModal();
                return;
            }
            const richTextInput = this.template.querySelector(`.simple-edit-editor[data-id="${this.activeClauseId}"]`);
            if (!richTextInput) return;
            richTextInput.focus();
            if (this.savedSelection) {
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(this.savedSelection);
            }
            document.execCommand('insertHTML', false, html);
        }
        this.closeMergeFieldModal();
    }
    // ==================== GETTERS ====================
    get isGlobalVariablesSaveDisabled() {
        return Object.keys(this.changedGlobalVariables).length === 0;
    }
    get readOnlyChat() {
        return this.legalDoc[LegalDoc_API.Status__c] === 'Approved' || this.legalDoc[LegalDoc_API.Status__c] === 'Ready To Sign';
    }
    get noRecordsToDisplay() {
        return !this.clauses.length && !this.isAddingNewClause;
    }
    get hasSupplier() {
        return this.legalDoc && this.legalDoc[LegalDoc_API.Supplier__c];
    }
    get showDeleteClauseButton() {
        return this.isLegal || this.isPortalUser;
    }
    get showValidateAllButton() {
        if (this.isMyTurn && !this.isBOUser && this.hasSupplier) {
            if (this.isPortalUser && this.legalDoc?.[LegalDoc_API.Status__c]?.toLowerCase() === 'validated by legal') return true;
            if (this.isLegal && (this.legalDoc?.[LegalDoc_API.Status__c]?.toLowerCase() === 'validated by supplier' || this.legalDoc?.[LegalDoc_API.Status__c]?.toLowerCase() === 'validated')) return false;
            return true;
        }
        return false;
    }
    get showBusinessOwnerButton() {
        if (!this.clauses || this.clauses.length === 0) return false;
        if (!this.isPortalUser) {
            let doc = this.legalDoc;
            let hasAnyBOAsPlayer = this.docBoFieldList.some(f => doc[f] === true);
            if (!hasAnyBOAsPlayer) return false;
            return this.clauses.some(c =>
                (c[LegalDoc_API.Status__c] || '').toLowerCase() === 'published'
            );
        }
    }
    get showApproveAllButton() {
        if (!this.isMyTurn || this.isBOUser) return false;
        const hasDraftComment = (this.allComments || []).some(c => c[TrackAction_API.CommentStatus__c] === 'Draft' && c[TrackAction_API.Comment__c]);
        const hasDraftClause = (this.clauses || []).some(c => (c[LegalDoc_API.Status__c] || '').toLowerCase() === 'draft');
        if (hasDraftComment || hasDraftClause) return false;
        if (this.isLegal && this.legalDoc?.[LegalDoc_API.Status__c]?.toLowerCase() === 'validated by supplier') return true;
        return false;
    }
    get showEditButton() {
        if (this.isPortalUser) {
            return true;
        }
        return this.hasSupplier;
    }
    get isDraggable() {
        const status = (this.legalDoc?.[LegalDoc_API.Status__c] || '').trim().toLowerCase();
        return (!this.isPortalUser && this.expandedClauseIds.length === 0 && status !== '' && status !== 'approved' && status !== 'ready to sign');
    }
    get isExportDisabled() {
        return this.isExportingPdf || this.isLoading || !this.jsPdfLoaded;
    }

    get clauseContentClass() {
        if (this.isPortalUser) { return 'slds-col slds-size_9-of-12 clause-content'; }
        return this.hasSupplier ? 'slds-col slds-size_9-of-12 clause-content' : 'slds-col slds-size_9-of-12 clause-content';
    }

    get headerCountLabel() {
        return this.Labels.LBL_LD_HeaderCount
            .replace('{1}', this.selectedSupplierIds.length)
            .replace('{2}', this.totalSupplierCount)
            .replace('{3}', this.selectedSupplierIds.length);
    }
    get showPublishCmntsAndDrafts() {
        return this.isPortalUser ? this.isMyTurn && this.hasSupplier /*&& this.legalDoc[LegalDoc_API.Status__c] !== 'Validated by legal'*/ : this.isMyTurn && this.hasSupplier;
    }
    get showPublishDraftBOChatter() {
        let hasDraftComments = false;
        hasDraftComments = this.allComments?.some(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && !act[TrackAction_API.IsPortalPublished__c] && act[TrackAction_API.Comment__c]);
        const isRetailerTurn = this.isMyTurn || (this.isBOUser && this.legalDoc[LegalDoc_API.LegalIsPlayer__c]);
        return isRetailerTurn && !this.isPortalUser && this.hasSupplier && hasDraftComments;
    }
    get isSendDisabled() {
        return this.selectedSupplierIds.length === 0 || this.isLoadingSuppliers;
    }

    get isAllSuppliersSelected() {
        let selectableSuppliers = this.filteredSuppliers.filter(s => !s.isDisabled);
        return selectableSuppliers.length > 0 &&
            selectableSuppliers.every(s => s.isSelected);
    }
    get isMyTurn() {
        const doc = this.legalDoc;
        if (!doc || !doc.Id) return false;
        if (this.isPortalUser) return doc[LegalDoc_API.PartnerIsPlayer__c] === true;
        if (this.isLegal) return doc[LegalDoc_API.LegalIsPlayer__c] === true;
        if (this.isBOUser && this.boType) {
            const field = this.docBoFieldMap[this.boType];
            return field ? doc[field] === true : false;
        }
        return false;
    }
    get isChatterOpen() { return this.openChatterClauseId !== null; }

    get chatterType() { return this.openChatterType; }
    get canEditGlobalVariables() { return this.hasSupplier && this.isMyTurn && !this.isBOUser}
    get clausesListClass() { return this.isChatterOpen ? 'clauses-list chatter-active' : 'clauses-list'; }
    get isFieldDisabled() {
        return !this.selectedObject;
    }
    //================================== helpers =================================
    getStatusClass(status, updateOrigin) {
        switch (status?.toLowerCase()) {
            case 'draft': return 'badge-draft';
            case 'published':
            case 'supplier publishing': return 'badge-published-supplier';
            case 'legal publishing': return 'badge-published-legal';
            case 'validated':
                if (updateOrigin === 'supplier') return 'badge-validated-supplier';
                return 'badge-validated';
            case 'approved': return 'badge-approved';
            case 'open': return 'badge-warning';
            case 'rejected': return 'badge-rejected';
            default: return 'badge-default';
        }
    }
    getClauseItemClass(clause) {
        const classes = ['clause-item-wrapper'];
        if (this.isChatterOpen && this.openChatterClauseId === clause.Id) classes.push('chatter-open', 'shift-left');
        const type = (clause[LegalDocClause_API.ClauseType__c] || '').toLowerCase();
        const typeMap = {
            title: 'clause-type-title',
            subtitle: 'clause-type-subtitle',
            body: 'clause-type-body'
        };
        if (typeMap[type]) classes.push(typeMap[type]);
        const status = (clause[LegalDocClause_API.Status__c] || '').toLowerCase();
        const legalStatus = (clause[LegalDocClause_API.LegalStatus__c] || '').toLowerCase();
        const origin = (clause[LegalDocClause_API.UpdateOrigin__c] || '').toLowerCase();
        if (status === 'draft') {
            classes.push(origin === 'supplier' ? 'clause-status-draft-supplier' : origin === 'legal' ? 'clause-status-draft-legal' : 'clause-status-draft');
        } else {
            const statusMap = {
                'published': 'clause-status-published-supplier',
                'supplier publishing': 'clause-status-published-supplier',
                'legal publishing': 'clause-status-published-legal',
                'validated': 'clause-status-validated',
                'approved': 'clause-status-approved',
                'rejected': 'clause-status-rejected'
            };
            if (statusMap[status]) classes.push(statusMap[status]);
        }
        if (!this.isPortalUser && this.expandedClauseIds.length === 0) classes.push('draggable');
        if (clause.Id === this.draggedClauseId) classes.push('dragging');
        if (!this.isPortalUser && this.selectedIdsToDelete?.includes(clause.Id)) classes.push('clause-marked-for-deletion');
        if (this.hasSupplier && legalStatus === 'draft' && (status === 'draft' || status === '') && (clause[LegalDocClause_API.Version__c] === 0 || clause[LegalDocClause_API.Version__c] == null)) classes.push('clause-newly-created');
        return classes.join(' ');
    }
    checkDraftCmntsAndClauses() {
        let hasDraftComments = this.checkDraftComments();
        let hasDraftClauses = this.displayClauses.some(item => item[LegalDocClause_API.Status__c] === 'Draft');
        if (hasDraftComments || hasDraftClauses) {
            return true;
        }
        return false;
    }
    checkDraftComments() {
        let hasdraftComments = false;
        if (this.isLegal) {
            hasdraftComments = this.allComments?.some(act => (act[TrackAction_API.CommentStatus__c] == 'Draft' || (act[TrackAction_API.CommentOrigin__c] == 'Business Owner' && act[TrackAction_API.IsPortalPublished__c])) && act[TrackAction_API.Comment__c]);
        }
        else {
            hasdraftComments = this.allComments?.some(act => act[TrackAction_API.CommentStatus__c] == 'Draft' && act[TrackAction_API.Comment__c]);
        }
        return hasdraftComments;
    }
    stripHtmlTags(html) {
        try {
            if (!html) return '';
            let tmp = document.createElement('div');
            tmp.innerHTML = String(html);
            return tmp.textContent || tmp.innerText || '';
        } catch (error) {
            return String(html || '');
        }
    }
    escapeHtml(text) {
        try {
            if (!text) return '';
            let div = document.createElement('div');
            div.textContent = String(text);
            return div.innerHTML.replace(/\n/g, '<br/>');
        } catch (error) {
            return String(text || '');
        }
    }
    getNestedValue(obj, path) {
        return path
            .split('.')
            .reduce((acc, part) => acc && acc[part], obj);
    }
}