import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import getData from '@salesforce/apex/LegalClausesOverviewController.getData';
import saveClauses from '@salesforce/apex/LegalClausesOverviewController.saveClauses';
import getFilteredSuppliers from '@salesforce/apex/LegalClausesOverviewController.getFilteredSuppliers';
import sendToSuppliers from '@salesforce/apex/LegalClausesOverviewController.sendToSuppliers';
import deleteClause from '@salesforce/apex/LegalClausesOverviewController.deleteClause';
import EMAIL_REVIEW from '@salesforce/resourceUrl/EmailReview';
import DIFF_MATCH_PATCH from '@salesforce/resourceUrl/diff_match_patch';
import NEGOPTIM_ICONS from '@salesforce/resourceUrl/NegoptimIcons';
import LBL_Edit from "@salesforce/label/c.LBL_Edit";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Save from "@salesforce/label/c.LBL_Save";

import LBL_AddClause from "@salesforce/label/c.LBL_AddClause";
import LBL_SendToSupplier from "@salesforce/label/c.LBL_SendToSupplier";
import LBL_LatestSupplierComments from "@salesforce/label/c.LBL_LatestSupplierComments";
import LBL_LatestCommentsLegal from "@salesforce/label/c.LBL_LatestCommentsLegal";
import LBL_DateOFLegalValidation from "@salesforce/label/c.LBL_DateOFLegalValidation";
import LBL_OverviewLegalClauses from "@salesforce/label/c.LBL_OverviewLegalClauses";
import LBL_SaveOrder from "@salesforce/label/c.LBL_SaveOrder";
import MSG_SaveNewOrder from "@salesforce/label/c.MSG_SaveNewOrder";
import LBL_VersionComparison from "@salesforce/label/c.LBL_VersionComparison";
import LBL_PastVersion from "@salesforce/label/c.LBL_PastVersion";
import LBL_CurrentVersion from "@salesforce/label/c.LBL_CurrentVersion";

export default class LegalClausesOverviewCMP2 extends LightningElement {
    Labels = {
        LBL_Edit,
        LBL_AddClause,
        LBL_SendToSupplier,
        LBL_LatestSupplierComments,
        LBL_LatestCommentsLegal,
        LBL_DateOFLegalValidation,
        LBL_OverviewLegalClauses,
        LBL_SaveOrder,
        MSG_SaveNewOrder,
        LBL_VersionComparison,
        LBL_PastVersion,
        LBL_CurrentVersion,
        LBL_Cancel,
        LBL_Save,
        LBL_NewVersion: 'Nouvelle Version',
        LBL_Modify: 'Modify',
    }
    @api recordId = 'a1PQH00003fvXm52AE';
    
    _isPortalUser = false;
    
    @api
    get isPortalUser() {
        return this._isPortalUser;
    }
    set isPortalUser(value) {
        this._isPortalUser = value === true || value === 'true' || value === '1';
    }
    
    // Data from wrapper
    @track legalDoc = {};
    @track clauses = [];
    @track allClauses = [];
    @track picklistValues = {};
    @track fieldLabels = {};
    
    // Form data
    @track editingClauses = {}; // Object keyed by clause Id for multi-edit
    @track newClause = {};
    
    // UI State
    isLoading = true;
    showAddModal = false;
    showSupplierModal = false;
    selectedClauseType = null;
    @track clausesWithAddTabs = {}; // Track which clauses have add tabs visible
    showHeaderAddTabs = false; // Track if header add tabs are visible
    @track isEditingNewVersionMap = {}; // Track edit mode per clause
    @track expandedClauseIds = []; // Array for multiple expanded clauses
    @track clausesWithChatterVisible = {}; // Track which clauses have chatter visible
    @track clausesWithAdditionalInfoVisible = {}; // Track which clauses have additional info visible
    diffLibLoaded = false;
    dmp = null;
    @track selectedCompareVersionIds = {}; // Track per clause 
    
    // Drag and drop state
    @track hasOrderChanged = false;
    @track originalOrder = [];
    draggedClauseId = null;
    
    // Supplier selection state
    @track allSuppliers = [];
    @track filteredSuppliers = [];
    @track selectedSupplierIds = [];
    supplierSearchTerm = '';
    isLoadingSuppliers = false;
    @track supplierFieldLabels = {};
    @track supplierPicklistValues = {};

    // Business Owners selection for new clause
    @track selectedBusinessOwners = ['Legal'];

    // Chatter slide-in panel state
    @track openChatterClauseId = null; // Track which clause's chatter is open

    // Pagination state
    @track currentPage = 1;
    itemsPerPage = 7;

    // Filter state
    selectedStatusFilter = '';
    selectedClauseTypeFilter = '';

    // Lifecycle
    connectedCallback() {
        // this.isPortalUser = true;   
        this.loadDiffLibrary();
        this.loadData();
    }

    renderedCallback() {
        // Remove "actif" and "inactif" text from toggle switches completely
        const toggleInputs = this.template.querySelectorAll('lightning-input[type="toggle"]');
        toggleInputs.forEach(toggle => {
            // Remove all spans that contain "actif" or "inactif"
            const allSpans = toggle.querySelectorAll('span');
            allSpans.forEach(span => {
                const text = span.textContent || span.innerText || '';
                if (text.toLowerCase().includes('actif') || text.toLowerCase().includes('inactif')) {
                    span.remove();
                }
            });
            
            // Remove any abbr elements (often used for helper text)
            const abbrs = toggle.querySelectorAll('abbr');
            abbrs.forEach(abbr => {
                const text = abbr.textContent || abbr.innerText || '';
                if (text.toLowerCase().includes('actif') || text.toLowerCase().includes('inactif')) {
                    abbr.remove();
                }
            });
            
            // Remove helper text wrappers
            const helpWrappers = toggle.querySelectorAll('.slds-form-element__help-wrapper');
            helpWrappers.forEach(wrapper => {
                const text = wrapper.textContent || wrapper.innerText || '';
                if (text.toLowerCase().includes('actif') || text.toLowerCase().includes('inactif')) {
                    wrapper.remove();
                }
            });
            
            // Remove any elements after the checkbox container that might contain the text
            const checkboxContainer = toggle.querySelector('.slds-checkbox_faux_container');
            if (checkboxContainer) {
                let nextSibling = checkboxContainer.nextElementSibling;
                while (nextSibling) {
                    const text = nextSibling.textContent || nextSibling.innerText || '';
                    if (text.toLowerCase().includes('actif') || text.toLowerCase().includes('inactif')) {
                        const toRemove = nextSibling;
                        nextSibling = nextSibling.nextElementSibling;
                        toRemove.remove();
                    } else {
                        nextSibling = nextSibling.nextElementSibling;
                    }
                }
            }
        });
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
        
            getData({
                recordId: this.recordId
            }).then(result => {
            const data = JSON.parse(result);            
            this.legalDoc = data.legalDoc || {};
            this.legalDoc.createdByLink = '/' + this.legalDoc.CreatedById ;
            this.picklistValues = data.picklistMap || {};
            this.fieldLabels = data.fieldLabels || {};
            
            if (data.legalDocClauseList && data.legalDocClauseList.length > 0) {
                this.allClauses = data.legalDocClauseList.map(clause => ({
                    ...clause,
                    statusClass: this.getStatusClass(clause.Status__c),
                    isNotNegotiable: !clause.IsNegotiable__c || clause.Status__c == 'Approved',
                    editTooltip: clause.IsNegotiable__c ? this.Labels.LBL_Edit : 'Non modifiable',
                    isExpanded: false
                }));
                
                this.clauses = this.getLatestVersionClauses(this.allClauses);
                // Reset order tracking when data is refreshed
                this.hasOrderChanged = false;
                this.originalOrder = [];
                // Data refreshed
            } else {
                this.allClauses = [];
                this.clauses = [];
            }
        }).catch(error => {
            console.error('Error loading data:', error?.message || error);
            console.error('Error body:', error?.body?.message);
            this.showToast('Erreur', 'Erreur lors du chargement des données', 'error');
            this.allClauses = [];
            this.clauses = [];
        }).finally(() => {
            this.isLoading = false;
        });
    }

    // Load diff library
    async loadDiffLibrary() {
        if (this.diffLibLoaded) return;
        try {
            await loadScript(this, DIFF_MATCH_PATCH);
            if (typeof diff_match_patch !== 'undefined') {
                this.dmp = new diff_match_patch();
                this.diffLibLoaded = true;
            }
        } catch (error) {
            console.error('Error loading diff_match_patch:', error);
        }
    }

    // ==================== GETTERS ====================

    get illustrationUrl() {
        return EMAIL_REVIEW;
    }
    get addIconStyle() {
        return `background-image: url(${this.addIconUrl});`;
    }

    get sendIconStyle() {
        return `background-image: url(${this.sendIconUrl});`;
    }
    // Icons from static resource
    get addIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/PlusIconEmpty.png`;
    }

    get deleteIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/DeleteIcon.png`;
    }

    get sendIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/send.png`;
    }

    get viewIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/Eye_Icon 1.png`;
    }

    get validationIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/En cours de validation V2.png`;
    }

    get editIconUrl() {
        return `${NEGOPTIM_ICONS}/NegoptimIcons/edit.png`;
    }

    get legalDocName() {
        return this.legalDoc?.Name || '';
    }

    get legalDocYear() {
        return this.legalDoc?.Year__c || '';
    }

    get legalDocType() {
        let typeValue = this.legalDoc?.Type__c || '';
        if (!typeValue) return '';
        let typeOptions = this.picklistValues?.Type__c || [];
        let found = typeOptions.find(opt => opt.value === typeValue);
        return found ? found.label : typeValue;
    }

    get sendDate() {
        if (this.legalDoc?.DateSentToSupplier__c) {
            let date = new Date(this.legalDoc.DateSentToSupplier__c);
            return date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
        }
        return '';
    }

    get createdDate() {
        if (this.legalDoc?.CreatedDate) {
            return new Date(this.legalDoc.CreatedDate).toLocaleDateString('fr-FR');
        }
        return '';
    }

    get createdBy() {
        return this.legalDoc?.CreatedBy?.Name || '';
    }

    get lastUpdateDate() {
        if (this.legalDoc?.LastModifiedDate) {
            return new Date(this.legalDoc.LastModifiedDate).toLocaleDateString('fr-FR');
        }
        return '';
    }

    // Field Labels from Org
    get labelYear() {
        return this.fieldLabels?.Year__c || 'Année de référence';
    }

    get labelType() {
        return this.fieldLabels?.Type__c || 'Type de doc';
    }

    get labelCreatedDate() {
        return this.fieldLabels?.CreatedDate || 'Created date';
    }

    get labelCreatedBy() {
        return this.fieldLabels?.CreatedById || 'Created by';
    }

    get labelLastModifiedDate() {
        return this.fieldLabels?.LastModifiedDate || 'Last update date';
    }

    get labelSendDate() {
        return this.fieldLabels?.DateSentToSupplier__c || 'Date d\'envoi au fournisseur';
    }

    get labelLanguage() {
        return this.fieldLabels?.Language__c || 'Langue';
    }

    get legalDocLanguage() {
        let langValue = this.legalDoc?.Language__c || '';
        if (!langValue) return '';
        let langOptions = this.picklistValues?.Language__c || [];
        let found = langOptions.find(opt => opt.value === langValue);
        return found ? found.label : langValue;
    }

    get showFlowButton() {
        if (!this.legalDoc || !this.legalDoc.Id) return false;
        return !this.legalDoc.Supplier__c;
    }

    get hasSupplier() {
        return this.legalDoc && this.legalDoc.Supplier__c;
    }

    get hasClauses() {
        return this.clauses && this.clauses.length > 0;
    }
    get showEditButton() {
        if (this.isPortalUser) {
            return true;
        }
        return this.hasSupplier;
    }
    get showEditButtonForClause() {
        return true; 
    }

    get isDraggable() {
        // Disable drag and drop when editing any clause or in portal mode
        return !this.isPortalUser && this.expandedClauseIds.length === 0;
    }

    get statusFilterOptions() {
        const statuses = ['Draft', 'Validated', 'Published', 'Legal Publishing', 'Approved'];
        return [
            { label: 'All Statuses', value: '' },
            ...statuses.map(status => ({
                label: status,
                value: status
            }))
        ];
    }

    get clauseTypeFilterOptions() {
        return [
            { label: 'All Types', value: '' },
            { label: 'Chapter (Title)', value: 'Title' },
            { label: 'Article (Subtitle)', value: 'Subtitle' },
            { label: 'Clause (Body)', value: 'Body' }
        ];
    }

    get displayClauses() {
        
        if (!this.clauses || this.clauses.length === 0) return [];
        
        let filteredClauses = this.clauses;
        
        // Apply status filter
        if (this.selectedStatusFilter) {
            filteredClauses = filteredClauses.filter(clause => 
                (clause.Status__c || '').toLowerCase() === this.selectedStatusFilter.toLowerCase()
            );
        }
        
        // Apply clause type filter
        if (this.selectedClauseTypeFilter) {
            filteredClauses = filteredClauses.filter(clause => 
                clause.ClauseType__c === this.selectedClauseTypeFilter
            );
        }
        
        return filteredClauses.map(clause => {
            let isNotEditable = false;
            let editTooltip = this.Labels.LBL_Edit;
            
            let status = (clause.Status__c || '').toLowerCase();
            let clauseType = (clause.ClauseType__c || '').toLowerCase();
            let isNegotiable = clause.IsNegotiable__c === true;
            
            if (status === 'approved') {
                isNotEditable = true;
                editTooltip = 'Clause approuvée - Non modifiable';
            }
            else if (!this.hasSupplier) {
                isNotEditable = false;
                editTooltip = this.Labels.LBL_Edit;
            }
            else if (this.hasSupplier) {
                if (!this.isPortalUser) {
                    isNotEditable = false;
                    editTooltip = this.Labels.LBL_Edit;
                }
                else if (this.isPortalUser) {
                    // Portal users can only edit negotiable body clauses
                    if (clauseType !== 'body') {
                        isNotEditable = true;
                        editTooltip = 'Seules les clauses de type Body peuvent être modifiées';
                    } else if (!isNegotiable) {
                        isNotEditable = true;
                        editTooltip = 'Cette clause n\'est pas négociable';
                    } else {
                        isNotEditable = false;
                        editTooltip = this.Labels.LBL_Edit;
                    }
                }
            }
            
            let isExpanded = this.expandedClauseIds.includes(clause.Id);
            let editingData = this.editingClauses[clause.Id] || {};
            
         
            let showSimpleEdit = false;
            if (!this.isPortalUser) {
                showSimpleEdit = true; // Always show simple edit modal for all clause types
            }
            
            let showPublishButton = this.computeShowPublishButton(editingData);
            let showValidatedButton = this.computeShowValidatedButton(editingData);
            let showApprovedButton = this.computeShowApprovedButton(editingData);
            
            let hasVersionsToCompare = this.computeHasVersionsToCompare(editingData);
            let compareVersionOptions = this.computeCompareVersionOptions(editingData);
            let selectedCompareVersionId = this.selectedCompareVersionIds[clause.Id] || null;
            
            let pastVersionContent = this.computePastVersionContent(editingData, selectedCompareVersionId);
            let currentVersionContent = this.computeCurrentVersionContent(editingData, selectedCompareVersionId);
            let newVersionContent = this.computeNewVersionContent(editingData);
            
            // Explicitly preserve isNew flag from original clause
            let isNewClause = clause.isNew === true || (clause.Id && clause.Id.startsWith('new-clause-'));
            
            let clauseObj = {
                ...clause,
                isNew: isNewClause, // Explicitly preserve isNew flag
                isExpanded: isExpanded,
                editingClause: editingData,
                isEditingNewVersion: this.isEditingNewVersionMap[clause.Id] || false,
                selectedCompareVersionId: selectedCompareVersionId,
                showSimpleEdit: showSimpleEdit,
                showPublishButton: showPublishButton,
                showValidatedButton: showValidatedButton,
                showApprovedButton: showApprovedButton,
                hasVersionsToCompare: hasVersionsToCompare,
                compareVersionOptions: compareVersionOptions,
                pastVersionContent: pastVersionContent,
                currentVersionContent: currentVersionContent,
                newVersionContent: newVersionContent,
                clauseTypeClass: this.getClauseTypeClass(clause.ClauseType__c),
                clauseTypeLabel: this.getClauseTypeLabel(clause.ClauseType__c),
                statusLabel: this.getStatusLabel(clause.Status__c),
                isNotNegotiable: isNotEditable,
                editTooltip: editTooltip,
                showAddTabs: this.clausesWithAddTabs[clause.Id] || false,
                showAdditionalInfo: this.clausesWithAdditionalInfoVisible[clause.Id] || false,
                additionalInfoButtonLabel: this.clausesWithAdditionalInfoVisible[clause.Id] ? 'Hide Additional Information' : 'Additional Information',
                chatterButtonVariant: this.openChatterClauseId === clause.Id ? 'brand' : 'neutral',
                chatterButtonLabel: this.openChatterClauseId === clause.Id ? 'Hide Chatter' : 'Show Chatter',
                chatterActiveClass: this.openChatterClauseId === clause.Id ? 'chatter-active' : ''
            };
            
            // Calculate itemClass after building the object to ensure isNew is available
            clauseObj.itemClass = this.getClauseItemClass(clauseObj);
            
            // Add modal class property for new clauses
            clauseObj.modalClass = isNewClause ? 'clause-modal-new' : '';
            
            return clauseObj;
        }).sort((a, b) => {
            // Preserve isNew flag during sort
            let orderA = a.DisplayOrder__c || 0;
            let orderB = b.DisplayOrder__c || 0;
            return orderA - orderB;
        });
    }

    // ==================== PAGINATION ====================

    get paginatedClauses() {
        // Return all clauses without pagination
        return this.displayClauses || [];
    }

    get totalPages() {
        if (!this.displayClauses || this.displayClauses.length === 0) return 1;
        return Math.ceil(this.displayClauses.length / this.itemsPerPage);
    }

    get hasPreviousPage() {
        return this.currentPage > 1;
    }

    get hasNextPage() {
        return this.currentPage < this.totalPages;
    }

    get paginationInfo() {
        if (!this.displayClauses || this.displayClauses.length === 0) return '';
        const start = (this.currentPage - 1) * this.itemsPerPage + 1;
        const end = Math.min(this.currentPage * this.itemsPerPage, this.displayClauses.length);
        return `${start}-${end} sur ${this.displayClauses.length}`;
    }

    get pageNumbers() {
        const pages = [];
        const total = this.totalPages;
        const current = this.currentPage;
        
        // Show max 5 page numbers
        let startPage = Math.max(1, current - 2);
        let endPage = Math.min(total, startPage + 4);
        
        // Adjust start if we're near the end
        if (endPage - startPage < 4) {
            startPage = Math.max(1, endPage - 4);
        }
        
        for (let i = startPage; i <= endPage; i++) {
            pages.push({
                number: i,
                isActive: i === current,
                cssClass: i === current ? 'pagination-page-btn active' : 'pagination-page-btn'
            });
        }
        
        return pages;
    }

    get isPreviousPageDisabled() {
        return !this.hasPreviousPage;
    }

    get isNextPageDisabled() {
        return !this.hasNextPage;
    }

    handlePreviousPage() {
        if (this.hasPreviousPage) {
            this.currentPage--;
            this.scrollToTop();
        }
    }

    handleNextPage() {
        if (this.hasNextPage) {
            this.currentPage++;
            this.scrollToTop();
        }
    }

    handlePageChange(event) {
        const page = parseInt(event.currentTarget.dataset.page);
        if (page && page >= 1 && page <= this.totalPages) {
            this.currentPage = page;
            this.scrollToTop();
        }
    }

    scrollToTop() {
        // Scroll to top of clauses section
        setTimeout(() => {
            const clausesSection = this.template.querySelector('.clauses-section');
            if (clausesSection) {
                clausesSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }

    // Reset pagination when clauses change
    resetPagination() {
        this.currentPage = 1;
    }
    
    // ==================== COMPUTED METHODS FOR MULTI-EDIT ====================
    
    computeShowPublishButton(editingClause) {
        if (!editingClause || !editingClause.Id) return false;
        let status = (editingClause.Status__c || '').toLowerCase();
        let updateOrigin = (editingClause.UpdateOrigin__c || '').toLowerCase();
        
        if (this.isPortalUser) {
            return status === 'draft' && updateOrigin === 'supplier';
        } else {
            return status === 'draft' && updateOrigin === 'legal';
        }
    }
    
    computeShowValidatedButton(editingClause) {
        if (!this.isPortalUser) return false;
        if (!editingClause || !editingClause.Id) return false;
        let status = (editingClause.Status__c || '').toLowerCase();
        let partnerStatus = (editingClause.PartnerStatus__c || '').toLowerCase();
        
        return status === 'published' && partnerStatus === 'validated';
    }
    
    computeShowApprovedButton(editingClause) {
        if (!editingClause || !editingClause.Id) return false;
        let status = (editingClause.Status__c || '').toLowerCase();
        let legalStatus = (editingClause.LegalStatus__c || '').toLowerCase();
        let partnerStatus = (editingClause.PartnerStatus__c || '').toLowerCase();
        
        if (this.isPortalUser) {
            return (status === 'validated' && legalStatus === 'validated' && partnerStatus === 'validated');
        } else {
            // Non-portal (Legal) user can approve ONLY when partner has approved but legal hasn't yet
            return partnerStatus === 'approved' && legalStatus !== 'approved';
        }
    }
    
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
                let version = clause.Version__c || 0;
                let status = clause.Status__c || '';
                let origin = clause.UpdateOrigin__c || '';
                let label = `V${version}`;
                if (status) label += ` (${status})`;
                if (origin) label += ` - ${origin}`;
                return { label: label, value: clause.Id };
            })
            .sort((a, b) => {
                let vA = parseInt(a.label.match(/V(\d+)/)?.[1] || 0);
                let vB = parseInt(b.label.match(/V(\d+)/)?.[1] || 0);
                return vB - vA;
            });
        
        if (options.length > 0) {
            options.unshift({ label: '-- Sélectionner une version --', value: '' });
        }
        return options;
    }
    
    computePastVersionContent(editingClause, selectedCompareVersionId) {
        try {
            if (selectedCompareVersionId && this.allClauses?.length > 0) {
                let selectedClause = this.allClauses.find(c => c.Id === selectedCompareVersionId);
                if (selectedClause?.Clause__c) {
                    return selectedClause.Clause__c;
                }
            }
            
            let pastClause = this.getPastVersionClauseFor(editingClause);
            if (pastClause?.Clause__c) {
                return pastClause.Clause__c;
            }
            
            if (editingClause?.LegalDocClauseP1__c && this.allClauses?.length > 0) {
                let prevClause = this.allClauses.find(c => c.Id === editingClause.LegalDocClauseP1__c);
                if (prevClause) return prevClause.Clause__c || '';
            }
            
            if (editingClause?.LegalDocClause__c && this.allClauses?.length > 0) {
                let originClause = this.allClauses.find(c => c.Id === editingClause.LegalDocClause__c);
                if (originClause) return originClause.Clause__c || '';
            }
            return '<p><em>Aucune version précédente</em></p>';
        } catch (error) {
            return '<p><em>Aucune version précédente</em></p>';
        }
    }
    
    computeCurrentVersionContent(editingClause, selectedCompareVersionId) {
        try {
            let currentClause = this.getCurrentVersionClauseFor(editingClause);
            let currentContent = currentClause?.Clause__c || editingClause?.Clause__c || '';
            
            let pastContent = '';
            if (selectedCompareVersionId && this.allClauses?.length > 0) {
                let selectedClause = this.allClauses.find(c => c.Id === selectedCompareVersionId);
                pastContent = selectedClause?.Clause__c || '';
            } else {
                let pastClause = this.getPastVersionClauseFor(editingClause);
                pastContent = pastClause?.Clause__c || '';
            }
            
            if (!this.stripHtmlTags(currentContent).trim()) {
                return '<p><em>Aucun contenu</em></p>';
            }
            
            if (pastContent && this.dmp && this.diffLibLoaded) {
                let pastText = this.convertHtmlToTextPreserveBreaks(pastContent);
                let currentText = this.convertHtmlToTextPreserveBreaks(currentContent);
                let diffHtml = this.computeDiff(pastText, currentText);
                return diffHtml.replace(/\n/g, '</p><p>');
            }
            
            return currentContent;
        } catch (error) {
            return editingClause?.Clause__c || '';
        }
    }
    
    computeNewVersionContent(editingClause) {
        try {
            let newClause = this.getNewVersionClauseFor(editingClause);
            let newContent = editingClause?.Clause__c || newClause?.Clause__c || '';
            
            let currentClause = this.getCurrentVersionClauseFor(editingClause);
            let currentContent = currentClause?.Clause__c || '';
            
            if (!this.stripHtmlTags(newContent).trim()) {
                return '<p><em>Commencez à taper dans la nouvelle version</em></p>';
            }
            
            if (currentContent && this.dmp && this.diffLibLoaded) {
                let currentText = this.convertHtmlToTextPreserveBreaks(currentContent);
                let newText = this.convertHtmlToTextPreserveBreaks(newContent);
                if (this.stripHtmlTags(currentContent) !== this.stripHtmlTags(newContent)) {
                    let diffHtml = this.computeDiff(currentText, newText);
                    return diffHtml.replace(/\n/g, '</p><p>');
                }
            }
            
            return newContent;
        } catch (error) {
            return editingClause?.Clause__c || '';
        }
    }
    
    getCurrentVersionClauseFor(editingClause) {
        if (!editingClause) return null;
        let versions = this.getClauseVersionChain(editingClause.Id);
        for (let i = versions.length - 1; i >= 0; i--) {
            if (versions[i].Status__c?.toLowerCase() !== 'rejected') {
                return versions[i];
            }
        }
        return editingClause;
    }
    
    getPastVersionClauseFor(editingClause) {
        let currentVersion = this.getCurrentVersionClauseFor(editingClause);
        if (!currentVersion) return null;
        
        if (currentVersion.LegalDocClauseP1__c && this.allClauses?.length > 0) {
            return this.allClauses.find(c => c.Id === currentVersion.LegalDocClauseP1__c) || null;
        }
        if (currentVersion.LegalDocClause__c && this.allClauses?.length > 0) {
            return this.allClauses.find(c => c.Id === currentVersion.LegalDocClause__c) || null;
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
        if (lastVersion?.UpdateOrigin__c === 'Supplier' || lastVersion?.UpdateOrigin__c === 'supplier') {
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
        }
    }

    getClauseItemClass(clause) {
        let baseClass = 'clause-item-wrapper';
        let clauseType = (clause.ClauseType__c || '').toLowerCase();
        if (clauseType === 'title') {
            baseClass += ' clause-type-title';
        } else if (clauseType === 'subtitle') {
            baseClass += ' clause-type-subtitle';
        } else if (clauseType === 'body') {
            baseClass += ' clause-type-body';
        }
        
        // Add class for new clauses - check both isNew flag and temp ID pattern
        if (clause.isNew === true || (clause.Id && clause.Id.startsWith('new-clause-'))) {
            baseClass += ' clause-item-new';
        }
        
        // Only add draggable class if not in portal mode AND no clause is being edited
        if (!this.isPortalUser && this.expandedClauseIds.length === 0) {
            baseClass += ' draggable';
        }
        if (clause.Id === this.draggedClauseId) {
            baseClass += ' dragging';
        }
        return baseClass;
    }

    getClauseTypeClass(clauseType) {
        let type = (clauseType || '').toLowerCase();
        switch (type) {
            case 'title': return 'clause-text-title';
            case 'subtitle': return 'clause-text-subtitle';
            case 'body': return 'clause-text-body';
            default: return 'clause-text-body';
        }
    }

    getStatusLabel(statusValue) {
        if (!statusValue) return '';
        let statusOptions = this.picklistValues?.Status__c || [];
        let found = statusOptions.find(opt => opt.value === statusValue);
        if (found) return found.label;
        return statusValue;
    }

    getClauseTypeLabel(typeValue) {
        if (!typeValue) return '';
        let typeOptions = this.picklistValues?.ClauseType__c || [];
        let found = typeOptions.find(opt => opt.value === typeValue);
        if (found) return found.label;
        
        return typeValue;
    }

    // Helper method to map clause type label to picklist value
    getClauseTypeValue(clauseType) {
        if (!clauseType) return '';
        // If it's already a value, return it
        let typeOptions = this.picklistValues?.ClauseType__c || [];
        let found = typeOptions.find(opt => opt.value === clauseType);
        if (found) return found.value;
        
        // Try to find by label
        found = typeOptions.find(opt => opt.label === clauseType);
        if (found) return found.value;
        
        // Return as-is if not found
        return clauseType;
    }
    get clauseContentClass() {
        if (this.isPortalUser) {
            return 'slds-col slds-size_9-of-12 clause-content';
        }
        return this.hasSupplier 
            ? 'slds-col slds-size_7-of-1 clause-content' 
            : 'slds-col slds-size_9-of-12 clause-content';
    }

    // ==================== PORTAL MODE GETTERS ====================

    get legalDocStatusSteps() {
        let statusOptions = this.picklistValues?.LegalDocStatus__c || [];
        return statusOptions.map(option => ({
            label: option.label,
            value: option.value
        }));
    }

    get currentStatusValue() {
        return this.legalDoc?.Status__c || '';
    }

    get partnerComment() {
        if (this.clauses && this.clauses.length > 0) {
            let comment = this.clauses.find(c => c.PartnerComment__c);
            return comment?.PartnerComment__c || '';
        }
        return '';
    }
    get legalStatusText() {
        let status = this.legalDoc?.Status__c || '';
        if (status === 'Validated' || status === 'validées') {
            return 'Ces clauses légales ont été validées par le Juridique';
        }
        return `Statut: ${status}`;
    }

    // Legal validation date
    get legalValidationDate() {
        if (this.legalDoc?.LastModifiedDate) {
            let date = new Date(this.legalDoc.LastModifiedDate);
            return date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
        }
        return '';
    }

    // Legal comment
    get legalComment() {
        if (this.clauses && this.clauses.length > 0) {
            let comment = this.clauses.find(c => c.LegalComment__c);
            return comment?.LegalComment__c || '';
        }
        return '';
    }

    // ==================== PICKLIST OPTIONS ====================

    get statusOptions() {
        return this.picklistValues?.Status__c || [];
    }

    get clauseStatusOptions() {
        return this.picklistValues?.Status__c || [];
    }

    get legalStatusOptions() {
        return this.picklistValues?.LegalStatus__c || [];
    }

    get partnerStatusOptions() {
        return this.picklistValues?.PartnerStatus__c || [];
    }

    get businessStatusOptions() {
        return this.picklistValues?.BusinessStatus__c || [];
    }

    get updateOriginOptions() {
        let options = [{ label: '-- None --', value: '' }];
        let backendOptions = this.picklistValues?.UpdateOrigin__c || [];
        return options.concat(backendOptions);
    }

    get clauseTypeOptions() {
        return this.picklistValues?.ClauseType__c || [];
    }

    get businessOwnersOptions() {
        return this.picklistValues?.BusinessOwners__c || [];
    }

    get previousClauseOptions() {
        let options = [{ label: '-- None --', value: '' }];
        if (this.allClauses?.length > 0) {
            this.allClauses.forEach(clause => {
                if (clause) {
                    let version = clause.Version__c || 0;
                    let label = `V${version} - ${this.stripHtmlTags(clause.Clause__c || '').substring(0, 40)}...`;
                    options.push({ label: clause.Name || label, value: clause.Id });
                }
            });
        }
        return options;
    }

    // ==================== VERSION COMPARISON (Business Rules) ====================
    
    getClauseVersionChain(clauseId) {
        if (!this.allClauses || !clauseId) return [];
        
        let versions = [];
        let currentClause = this.allClauses.find(c => c.Id === clauseId);
        
        if (!currentClause) return [];
        
        versions.push(currentClause);
        
        let prevId = currentClause.LegalDocClauseP1__c;
        while (prevId) {
            let prev = this.allClauses.find(c => c.Id === prevId);
            if (prev) {
                versions.push(prev);
                prevId = prev.LegalDocClauseP1__c;
            } else {
                break;
            }
        }
        
        if (currentClause.LegalDocClause__c) {
            let origin = this.allClauses.find(c => c.Id === currentClause.LegalDocClause__c);
            if (origin && !versions.find(v => v.Id === origin.Id)) {
                versions.push(origin);
            }
        }
        
        let findChildren = (id) => {
            let children = this.allClauses.filter(c => c.LegalDocClauseP1__c === id);
            children.forEach(child => {
                if (!versions.find(v => v.Id === child.Id)) {
                    versions.push(child);
                    findChildren(child.Id);
                }
            });
        };
        findChildren(clauseId);
        
        // Filter out draft clauses from the other party:
        // - Legal users should not see supplier drafts (unpublished)
        // - Portal users should not see legal drafts (unpublished)
        let filteredVersions = versions.filter(clause => {
            let isDraft = clause.Status__c?.toLowerCase() === 'draft';
            let updateOrigin = (clause.UpdateOrigin__c || '').toLowerCase();
            
            if (isDraft) {
                if (!this.isPortalUser && updateOrigin === 'supplier') {
                    // Legal user should not see unpublished supplier drafts
                    return false;
                }
                if (this.isPortalUser && updateOrigin === 'legal') {
                    // Portal user should not see unpublished legal drafts
                    return false;
                }
            }
            return true;
        });
        
        return filteredVersions.sort((a, b) => (a.Version__c || 0) - (b.Version__c || 0));
    }

    // ==================== HELPER METHODS ====================

    getStatusClass(status) {
        if (!status) return 'badge-default';
        let statusLower = status.toLowerCase();
        switch (statusLower) {
            case 'validated': return 'badge-validated';
            case 'draft': return 'badge-draft';
            case 'published': return 'badge-published';
            case 'legal publishing':
            case 'legalpublishing': return 'badge-legal-publishing';
            case 'open': return 'badge-warning';
            case 'rejected': return 'badge-error';
            default: return 'badge-default';
        }
    }

    getLatestVersionClauses(allClauses) {
        if (!allClauses || allClauses.length === 0) return [];
        try {
            let clausesToShow = [...allClauses];
            let draftIdsToHide = new Set();
            
            allClauses.forEach(clause => {
                let isDraft = clause.Status__c?.toLowerCase() === 'draft';
                let updateOrigin = clause.UpdateOrigin__c?.toLowerCase() || '';
                
                if (isDraft) {
                    if (!this.isPortalUser) {
                        if (updateOrigin === 'supplier') {
                            draftIdsToHide.add(clause.Id);
                        }
                    } else {
                        
                        if (updateOrigin === 'legal') {
                            draftIdsToHide.add(clause.Id);
                        }
                    }
                }
            });
            
           
            clausesToShow = allClauses.filter(clause => !draftIdsToHide.has(clause.Id));
            let olderVersionIds = new Set();
            clausesToShow.forEach(clause => {
                
                if (clause.LegalDocClauseP1__c) {
                    olderVersionIds.add(clause.LegalDocClauseP1__c);
                }
                if (clause.LegalDocClause__c && clause.LegalDocClause__c !== clause.Id) {
                    olderVersionIds.add(clause.LegalDocClause__c);
                }
            });
            
            return clausesToShow.filter(clause => !olderVersionIds.has(clause.Id));
        } catch (error) {
            console.error('Error in getLatestVersionClauses:', error);
            return allClauses;
        }
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

    
    convertHtmlToTextPreserveBreaks(html) {
        try {
            if (!html) return '';
            let text = String(html);
            // Add newlines before closing block tags
            text = text.replace(/<\/p>/gi, '\n');
            text = text.replace(/<\/h[1-6]>/gi, '\n');
            text = text.replace(/<\/div>/gi, '\n');
            text = text.replace(/<br\s*\/?>/gi, '\n');
            text = text.replace(/<\/li>/gi, '\n');
            // Strip all remaining HTML tags
            let tmp = document.createElement('div');
            tmp.innerHTML = text;
            let result = tmp.textContent || tmp.innerText || '';
            // Clean up multiple newlines
            result = result.replace(/\n\s*\n/g, '\n').trim();
            return result;
        } catch (error) {
            return this.stripHtmlTags(html);
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

    computeDiff(text1, text2) {
        try {
            let cleanText = (text) => {
                if (!text) return '';
                return text.replace(/\r\n/g, '\n').replace(/[ \t]+/g, ' ').trim();
            };
            
            let oldText = cleanText(String(text1 || ''));
            let newText = cleanText(String(text2 || ''));
            
            if (!this.dmp || !this.diffLibLoaded) return newText;
            if (oldText === newText) return newText;
            
            let tokenize = (text) => text.match(/\s+|[^\s]+/g) || [];
            let oldTokens = tokenize(oldText);
            let newTokens = tokenize(newText);
            
            let tokenToChar = {};
            let charsToToken = [];
            let nextCharCode = 0xE000;
            
            let encodeTokens = (tokens) => {
                return tokens.map(token => {
                    if (!(token in tokenToChar)) {
                        tokenToChar[token] = String.fromCharCode(nextCharCode++);
                        charsToToken.push(token);
                    }
                    return tokenToChar[token];
                }).join('');
            };
            
            let oldEncoded = encodeTokens(oldTokens);
            let newEncoded = encodeTokens(newTokens);
            
            let diffs = this.dmp.diff_main(oldEncoded, newEncoded);
            this.dmp.diff_cleanupSemantic(diffs);
            
            let html = '';
            for (let i = 0; i < diffs.length; i++) {
                let diff = diffs[i];
                if (!diff || diff.length < 2) continue;
                
                let op = diff[0];
                let chars = diff[1] || '';
                let tokens = chars.split('').map(c => charsToToken[c.charCodeAt(0) - 0xE000] || '');
                let text = tokens.join('');
                let isOnlyWhitespace = !text.replace(/[\s\u00A0\r\n]+/g, '');
                
                if (op === 0) {
                    html += text;
                } else if (op === 1) {
                    html += isOnlyWhitespace ? text : `<span style="background-color: #c8e6c9; color: #1b5e20; font-weight: bold;">${text}</span>`;
                } else if (op === -1) {
                    if (!isOnlyWhitespace) {
                        html += `<span style="background-color: #ffcdd2; color: #b71c1c; text-decoration: line-through;">${text}</span>`;
                    }
                }
            }
            return html;
        } catch (error) {
            return String(text2 || '');
        }
    }

    initializeNewClause() {
        let defaultClauseType = this.picklistValues?.ClauseType__c?.[0]?.value || 'Title';
        // Reset selected business owners to default
        this.selectedBusinessOwners = ['Legal'];
        this.newClause = {
            LegalDoc__c: this.recordId,
            Version__c: 0,
            Status__c: 'Draft',
            LegalStatus__c: 'Draft',
            PartnerStatus__c: 'Draft',
            BusinessStatus__c: 'Draft',
            LegalDocClause__c: null,
            UpdateOrigin__c: null,
            Clause__c: '',
            DisplayOrder__c: this.clauses.length + 1,
            IsNegotiable__c: defaultClauseType === 'Body',
            ClauseType__c: defaultClauseType,
            BusinessOwners__c: 'Legal'
        };
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    saveClauseHelper(clause, previousClauseId, legalDocId, isPublish, isPortal, isValidated, isAccepted) {
        let clausesToSave = [];
        
        if (previousClauseId && (isPublish || isValidated || isAccepted)) {
            let previousClause = {
                Id: previousClauseId,
                Status__c: 'Rejected'
            };
            if (isPortal) {
                previousClause.PartnerStatus__c = 'Rejected';
            } else {
                previousClause.LegalStatus__c = 'Rejected';
            }
            clausesToSave.push(previousClause);
        }
        
        // Add the main clause
        clausesToSave.push(clause);
        
        return saveClauses({ clausesJson: JSON.stringify(clausesToSave) });
    }


    handleAddClause() {
        if (this.isPortalUser) return; 
        this.showHeaderAddTabs = !this.showHeaderAddTabs;
    }
    
    handleHeaderSelectClauseType(event) {
        event.stopPropagation();
        let clauseType = event.currentTarget.dataset.type;
        this.showHeaderAddTabs = false; 
        this.selectedClauseType = clauseType;
        
        let tempId = 'new-clause-' + Date.now();
        let clauseTypeValue = this.getClauseTypeValue(clauseType);
        let isNegotiable = (clauseTypeValue === 'Body' || clauseType.toLowerCase() === 'body');
        
        // Add at the end
        let displayOrder = this.clauses.length + 1;
        displayOrder = Math.floor(displayOrder);
        
        let newClause = {
            Id: tempId,
            LegalDoc__c: this.recordId,
            Clause__c: '',
            Version__c: 0,
            Status__c: 'Draft',
            LegalStatus__c: 'Draft',
            PartnerStatus__c: 'Draft',
            BusinessStatus__c: 'Draft',
            DisplayOrder__c: displayOrder,
            IsNegotiable__c: isNegotiable,
            ClauseType__c: clauseTypeValue,
            BusinessOwners__c: 'Legal',
            LegalDocClause__c: null,
            UpdateOrigin__c: null,
            isNew: true
        };
        
        // Remove isNew flag from all previously added clauses
        let clausesCopy = this.clauses.map(clause => {
            if (clause.isNew === true || (clause.Id && clause.Id.startsWith('new-clause-'))) {
                let updatedClause = { ...clause };
                delete updatedClause.isNew;
                return updatedClause;
            }
            return clause;
        });
        
        // Insert at the end
        clausesCopy.push(newClause);
        this.clauses = [...clausesCopy];
        
        if (this.expandedClauseIds.length > 0) {
            let previousExpandedIds = [...this.expandedClauseIds];
            let newEditingClauses = { ...this.editingClauses };
            let newEditingMap = { ...this.isEditingNewVersionMap };
            let newCompareMap = { ...this.selectedCompareVersionIds };
            
            previousExpandedIds.forEach(id => {
                delete newEditingClauses[id];
                delete newEditingMap[id];
                delete newCompareMap[id];
            });
            
            this.editingClauses = newEditingClauses;
            this.isEditingNewVersionMap = newEditingMap;
            this.selectedCompareVersionIds = newCompareMap;
        }
        
        this.expandedClauseIds = [tempId];
        this.editingClauses = {
            ...this.editingClauses,
            [tempId]: { 
                ...newClause, 
                originalClause: '', 
                IsNegotiable__c: isNegotiable,
                selectedBusinessOwners: ['Legal']
            }
        };
        this.isEditingNewVersionMap = { ...this.isEditingNewVersionMap, [tempId]: false };
        this.selectedCompareVersionIds = { ...this.selectedCompareVersionIds, [tempId]: null };
        
        // Navigate to the page containing the new clause
        // Scroll to the new clause
        setTimeout(() => {
            this.scrollToClauseModal(tempId);
        }, 100);
    }

    handleCloseAddModal() {
        this.showAddModal = false;
        this.newClause = {};
        this.selectedBusinessOwners = ['Legal'];
    }

    handleNewClauseFieldChange(event) {
        let field = event.currentTarget.dataset.field;
        let value = event.target.type === 'number' 
            ? parseFloat(event.target.value) 
            : (event.detail?.value !== undefined ? event.detail.value : event.target.value);
        this.newClause = { ...this.newClause, [field]: value };
    }

    handleNewClauseRichTextChange(event) {
        let value = event.target.value || event.detail?.value || '';
        this.newClause = { ...this.newClause, Clause__c: value };
    }

    handleClauseTypeChange(event) {
        let clauseType = event.detail.value;
        // Map to picklist value
        let clauseTypeValue = this.getClauseTypeValue(clauseType);
        // Set IsNegotiable: false for Title and Subtitle, true for Body
        let isNegotiable = (clauseTypeValue === 'Body' || clauseType.toLowerCase() === 'body');
        this.newClause = { 
            ...this.newClause, 
            ClauseType__c: clauseTypeValue,
            IsNegotiable__c: isNegotiable 
        };
    }

    handleNewClauseNegotiableChange(event) {
        let isNegotiable = event.target.checked || event.currentTarget.checked;
        this.newClause = { 
            ...this.newClause, 
            IsNegotiable__c: isNegotiable 
        };
    }

    handleToggleClick(event) {
        event.preventDefault();
        event.stopPropagation();
        let clauseId = event.currentTarget.dataset.id;
        if (clauseId) {
            const checkbox = this.template.querySelector(`input.custom-toggle-input[data-id="${clauseId}"]`);
            if (checkbox) {
                checkbox.checked = !checkbox.checked;
                checkbox.dispatchEvent(new Event('change'));
            }
        }
    }

    handleNewToggleClick(event) {
        event.preventDefault();
        event.stopPropagation();
        const checkbox = this.template.querySelector('#toggle-new-clause');
        if (checkbox) {
            checkbox.checked = !checkbox.checked;
            checkbox.dispatchEvent(new Event('change'));
        }
    }

    handleNewClauseBusinessOwnersChange(event) {
        // lightning-dual-listbox returns an array of selected values
        this.selectedBusinessOwners = event.detail.value;
        // Convert array to semicolon-separated string for multi-select picklist
        let businessOwnersValue = this.selectedBusinessOwners.join(';');
        this.newClause = { 
            ...this.newClause, 
            BusinessOwners__c: businessOwnersValue 
        };
    }

    handleSaveNewClause() {
        let clauseText = this.stripHtmlTags(this.newClause.Clause__c || '').trim();
        if (!clauseText) {
            this.showToast('Erreur', 'Veuillez saisir le texte de la clause', 'error');
            return;
        }
            // Map clause type to picklist value
            let clauseType = this.getClauseTypeValue(this.newClause.ClauseType__c || 'Title');
            
            let clauseToSave = {
                LegalDoc__c: this.recordId,
                Clause__c: this.newClause.Clause__c,
                Version__c: 0,
                Status__c: this.newClause.Status__c,
                LegalStatus__c: this.newClause.LegalStatus__c,
                PartnerStatus__c: this.newClause.PartnerStatus__c,
                BusinessStatus__c: this.newClause.BusinessStatus__c,
                DisplayOrder__c: this.newClause.DisplayOrder__c,
                IsNegotiable__c: this.newClause.IsNegotiable__c || false,
                LegalDocClause__c: this.newClause.LegalDocClause__c || null,
                UpdateOrigin__c: this.newClause.UpdateOrigin__c || null,
                ClauseType__c: clauseType,
                BusinessOwners__c: this.newClause.BusinessOwners__c || ''
            };
        this.saveClauseHelper(
            clauseToSave,
            null,
            this.recordId,
            false,
            false,
            false,
            false
        ).then(() => {
            this.showToast('Succès', 'Clause ajoutée avec succès', 'success');
            this.handleCloseAddModal();
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur lors de l\'ajout: ' + error.body?.message, 'error');
        });
    }

    handleExecuteFlow() {
        if (this.isPortalUser) return; // Disabled in portal mode
        this.showSupplierModal = true;
        this.loadSuppliers();
    }

    handleCloseSupplierModal() {
        this.showSupplierModal = false;
        this.allSuppliers = [];
        this.filteredSuppliers = [];
        this.selectedSupplierIds = [];
        this.supplierSearchTerm = '';
        this.supplierFieldLabels = {};
        this.supplierPicklistValues = {};
    }
    
    loadSuppliers() {
        this.isLoadingSuppliers = true;
        getFilteredSuppliers({ legalDoc: JSON.stringify(this.legalDoc) })
            .then(result => {
                let data = JSON.parse(result);
                this.supplierFieldLabels = data.fieldLabels || {};
                this.supplierPicklistValues = data.picklistValues || {};
                
                // Map suppliers with translated picklist values and selection state
                this.allSuppliers = (data.suppliers || []).map(supplier => ({
                    ...supplier,
                    isSelected: false,
                    recordUrl: '/' + supplier.Id,
                    OwnerName: supplier.Owner ? supplier.Owner.Name : '',
                    StatusLabel: this.getPicklistLabel('Status__c', supplier.Status__c),
                    SPBOUCorrectedStatusLabel: this.getPicklistLabel('SPBOUCorrectedStatus__c', supplier.SPBOUCorrectedStatus__c),
                    YearlyContractTypeLabel: this.getPicklistLabel('YearlyContractType__c', supplier.YearlyContractType__c),
                    MarketLabel: this.getPicklistLabel('Market__c', supplier.Market__c),
                    ReferenceLanguageLabel: this.getPicklistLabel('ReferenceLanguage__c', supplier.ReferenceLanguage__c)
                }));
                this.filteredSuppliers = [...this.allSuppliers];
            })
            .catch(error => {
                console.error('Error loading suppliers:', error);
                this.showToast('Erreur', 'Erreur lors du chargement des fournisseurs: ' + (error.body?.message || error.message), 'error');
                this.allSuppliers = [];
                this.filteredSuppliers = [];
            })
            .finally(() => {
                this.isLoadingSuppliers = false;
            });
    }
    
    getPicklistLabel(fieldName, value) {
        if (!value) return '';
        let options = this.supplierPicklistValues[fieldName] || [];
        let found = options.find(opt => opt.value === value);
        return found ? found.label : value;
    }
    
    handleSupplierSearch(event) {
        this.supplierSearchTerm = event.target.value.toLowerCase();
        if (this.supplierSearchTerm) {
            this.filteredSuppliers = this.allSuppliers.filter(supplier => {
                return (supplier.Name && supplier.Name.toLowerCase().includes(this.supplierSearchTerm)) ||
                       (supplier.Code__c && supplier.Code__c.toLowerCase().includes(this.supplierSearchTerm)) ||
                       (supplier.StatusLabel && supplier.StatusLabel.toLowerCase().includes(this.supplierSearchTerm));
            });
        } else {
            this.filteredSuppliers = [...this.allSuppliers];
        }
    }
    
    handleSupplierCheckboxChange(event) {
        let supplierId = event.target.dataset.id;
        let isChecked = event.target.checked;
        
        // Update allSuppliers
        this.allSuppliers = this.allSuppliers.map(supplier => {
            if (supplier.Id === supplierId) {
                return { ...supplier, isSelected: isChecked };
            }
            return supplier;
        });
        
        // Update filteredSuppliers
        this.filteredSuppliers = this.filteredSuppliers.map(supplier => {
            if (supplier.Id === supplierId) {
                return { ...supplier, isSelected: isChecked };
            }
            return supplier;
        });
        
        // Update selectedSupplierIds
        if (isChecked) {
            if (!this.selectedSupplierIds.includes(supplierId)) {
                this.selectedSupplierIds = [...this.selectedSupplierIds, supplierId];
            }
        } else {
            this.selectedSupplierIds = this.selectedSupplierIds.filter(id => id !== supplierId);
        }
    }
    
    handleSelectAllSuppliers(event) {
        let isChecked = event.target.checked;
        
        // Update all suppliers selection state
        this.allSuppliers = this.allSuppliers.map(supplier => ({
            ...supplier,
            isSelected: isChecked
        }));
        
        this.filteredSuppliers = this.filteredSuppliers.map(supplier => ({
            ...supplier,
            isSelected: isChecked
        }));
        
        // Update selectedSupplierIds
        if (isChecked) {
            this.selectedSupplierIds = this.filteredSuppliers.map(s => s.Id);
        } else {
            this.selectedSupplierIds = [];
        }
    }
    
    handleSendToSuppliers() {
        if (this.selectedSupplierIds.length === 0) {
            this.showToast('Attention', 'Veuillez sélectionner au moins un fournisseur', 'warning');
            return;
        }
        
        this.isLoadingSuppliers = true;
        sendToSuppliers({ legalDoc: JSON.stringify(this.legalDoc), supplierIds: this.selectedSupplierIds })
            .then(() => {
                this.showToast('Succès', `Document envoyé à ${this.selectedSupplierIds.length} fournisseur(s)`, 'success');
                this.handleCloseSupplierModal();
            this.loadData();
            })
            .catch(error => {
                console.error('Error sending to suppliers:', error);
                this.showToast('Erreur', 'Erreur lors de l\'envoi: ' + (error.body?.message || error.message), 'error');
            })
            .finally(() => {
                this.isLoadingSuppliers = false;
            });
    }
    
    // Getters for supplier modal
    get totalSupplierCount() {
        return this.allSuppliers.length;
    }
    
    get selectedSupplierCount() {
        return this.selectedSupplierIds.length;
    }
    
    get hasSuppliers() {
        return this.filteredSuppliers.length > 0;
    }
    
    get isSendDisabled() {
        return this.selectedSupplierIds.length === 0 || this.isLoadingSuppliers;
    }
    
    get isAllSuppliersSelected() {
        return this.filteredSuppliers.length > 0 && 
               this.filteredSuppliers.every(s => s.isSelected);
    }
    
    get supplierColumnLabels() {
        return [
            { fieldName: 'Code__c', label: this.supplierFieldLabels.Code__c || 'Code' },
            { fieldName: 'Name', label: this.supplierFieldLabels.Name || 'Nom Client/Fournisseur' },
            { fieldName: 'Status__c', label: this.supplierFieldLabels.Status__c || 'Statut' },
            { fieldName: 'SPBOUCorrectedStatus__c', label: this.supplierFieldLabels.SPBOUCorrectedStatus__c || 'TMP Corrected Status' },
            { fieldName: 'YearlyContractType__c', label: this.supplierFieldLabels.YearlyContractType__c || 'TMP Yearly Contract Type' },
            { fieldName: 'Market__c', label: this.supplierFieldLabels.Market__c || 'TMP Market' },
            { fieldName: 'ReferenceLanguage__c', label: this.supplierFieldLabels.ReferenceLanguage__c || 'Langage de référence' },
            { fieldName: 'OwnerName', label: 'Propriétaire' }
        ];
    }

    handleEditClause(event) {
        try {
            // Prevent edit if dragging is in progress
            if (this.draggedClauseId) {
                return;
            }
            
            // Check if disabled from data attribute
            let isDisabled = event.currentTarget.dataset.disabled === 'true';
            if (isDisabled) {
                return;
            }
            
            let clauseId = event.currentTarget.dataset.id;
            let clause = this.clauses.find(c => c.Id === clauseId);
            if (clause) {
                let status = (clause.Status__c || '').toLowerCase();
                let clauseType = (clause.ClauseType__c || '').toLowerCase();
                let partnerStatus = (clause.PartnerStatus__c || '').toLowerCase();
                
                if (status === 'approved') {
                    this.showToast('Info', 'Clause approuvée - Non modifiable', 'info');
                    return;
                }
                // Portal users cannot edit if partner status is approved
                if (this.hasSupplier && this.isPortalUser && partnerStatus === 'approved') {
                    this.showToast('Info', 'Cette clause a été approuvée - Non modifiable', 'info');
                    return;
                }
                if (this.hasSupplier && this.isPortalUser && clauseType !== 'body') {
                    this.showToast('Info', 'Seules les clauses de type Body peuvent être modifiées', 'info');
                    return;
                }
                if (this.hasSupplier && this.isPortalUser && !clause.IsNegotiable__c) {
                    this.showToast('Info', 'Cette clause n\'est pas négociable', 'info');
                    return;
                }
                
                if (this.expandedClauseIds.length > 0) {
                    let previousExpandedIds = [...this.expandedClauseIds];
                    let newEditingClauses = { ...this.editingClauses };
                    let newEditingMap = { ...this.isEditingNewVersionMap };
                    let newCompareMap = { ...this.selectedCompareVersionIds };
                    
                    previousExpandedIds.forEach(id => {
                        delete newEditingClauses[id];
                        delete newEditingMap[id];
                        delete newCompareMap[id];
                    });
                    
                    this.editingClauses = newEditingClauses;
                    this.isEditingNewVersionMap = newEditingMap;
                    this.selectedCompareVersionIds = newCompareMap;
                }
                
                this.expandedClauseIds = [clauseId];
                
                // Set IsNegotiable default based on clause type if not already set
                let editingClauseType = (clause.ClauseType__c || '').toLowerCase();
                let isNegotiable = clause.IsNegotiable__c;
                if (isNegotiable === undefined || isNegotiable === null) {
                    isNegotiable = (editingClauseType === 'body');
                }
                
                // Initialize selectedBusinessOwners from BusinessOwners__c (semicolon-separated string)
                let businessOwnersStr = clause.BusinessOwners__c || 'Legal';
                let selectedBusinessOwners = businessOwnersStr.split(';').filter(val => val.trim());
                if (selectedBusinessOwners.length === 0) {
                    selectedBusinessOwners = ['Legal'];
                }
                
                this.editingClauses = { 
                    ...this.editingClauses, 
                    [clauseId]: { 
                        ...clause, 
                        originalClause: clause.Clause__c, 
                        IsNegotiable__c: isNegotiable,
                        selectedBusinessOwners: selectedBusinessOwners
                    }
                };
                this.isEditingNewVersionMap = { ...this.isEditingNewVersionMap, [clauseId]: false };
                this.selectedCompareVersionIds = { ...this.selectedCompareVersionIds, [clauseId]: null };
            }
        } catch (error) {
            this.showToast('Erreur', error.body?.message, 'error');
        }
    }

    handleCloseInlineEdit(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            // Remove this clause from expanded list
            this.expandedClauseIds = this.expandedClauseIds.filter(id => id !== clauseId);
            
            // Clean up editing data for this clause
            let newEditingClauses = { ...this.editingClauses };
            delete newEditingClauses[clauseId];
            this.editingClauses = newEditingClauses;
            
            let newEditingMap = { ...this.isEditingNewVersionMap };
            delete newEditingMap[clauseId];
            this.isEditingNewVersionMap = newEditingMap;
            
            let newCompareMap = { ...this.selectedCompareVersionIds };
            delete newCompareMap[clauseId];
            this.selectedCompareVersionIds = newCompareMap;
            
            // Close add tabs for this clause
            let newTabsMap = { ...this.clausesWithAddTabs };
            delete newTabsMap[clauseId];
            this.clausesWithAddTabs = newTabsMap;
        }
    }

    handleDuplicateClause(event) {
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            this.showToast('Info', 'Fonctionnalité de duplication à implémenter', 'info');
        }
    }

    handleDeleteClause(event) {
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            // Show confirmation dialog
            if (confirm('Êtes-vous sûr de vouloir supprimer cette clause ?')) {
                this.isLoading = true;
                deleteClause({ clauseId: clauseId })
                    .then(() => {
                        this.showToast('Succès', 'Clause supprimée avec succès', 'success');
                        // Close chatter if it's open for this clause
                        if (this.openChatterClauseId === clauseId) {
                            this.openChatterClauseId = null;
                        }
                        // Reload data to refresh the list
                        this.loadData();
                    })
                    .catch(error => {
                        this.showToast('Erreur', 'Erreur lors de la suppression: ' + (error.body?.message || error.message), 'error');
                        console.error('Error deleting clause:', error);
                    })
                    .finally(() => {
                        this.isLoading = false;
                    });
            }
        }
    }

    handleMoveDownClause(event) {
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            let clausesCopy = [...this.clauses];
            let currentIndex = clausesCopy.findIndex(c => c.Id === clauseId);
            
            if (currentIndex !== -1 && currentIndex < clausesCopy.length - 1) {
                // Swap with next clause
                let temp = clausesCopy[currentIndex].DisplayOrder__c;
                clausesCopy[currentIndex].DisplayOrder__c = clausesCopy[currentIndex + 1].DisplayOrder__c;
                clausesCopy[currentIndex + 1].DisplayOrder__c = temp;
                
                // Swap positions in array
                [clausesCopy[currentIndex], clausesCopy[currentIndex + 1]] = [clausesCopy[currentIndex + 1], clausesCopy[currentIndex]];
                
                this.clauses = clausesCopy;
                this.hasOrderChanged = true;
            }
        }
    }

    handleMoveUpClause(event) {
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            let clausesCopy = [...this.clauses];
            let currentIndex = clausesCopy.findIndex(c => c.Id === clauseId);
            
            if (currentIndex !== -1 && currentIndex > 0) {
                // Swap with previous clause
                let temp = clausesCopy[currentIndex].DisplayOrder__c;
                clausesCopy[currentIndex].DisplayOrder__c = clausesCopy[currentIndex - 1].DisplayOrder__c;
                clausesCopy[currentIndex - 1].DisplayOrder__c = temp;
                
                // Swap positions in array
                [clausesCopy[currentIndex], clausesCopy[currentIndex - 1]] = [clausesCopy[currentIndex - 1], clausesCopy[currentIndex]];
                
                this.clauses = clausesCopy;
                this.hasOrderChanged = true;
            }
        }
    }

    handleShowAddClauseTabs(event) {
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.clauseId || event?.target?.dataset?.clauseId;
        if (clauseId) {
            // Toggle tabs for this specific clause
            this.clausesWithAddTabs = {
                ...this.clausesWithAddTabs,
                [clauseId]: !this.clausesWithAddTabs[clauseId]
            };
        }
    }

    handleToggleChatter(event) {
        event.preventDefault();
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            // Close Additional Information if it's open
            if (this.clausesWithAdditionalInfoVisible[clauseId]) {
                this.clausesWithAdditionalInfoVisible = {
                    ...this.clausesWithAdditionalInfoVisible,
                    [clauseId]: false
                };
            }
            // Toggle Chatter Sidebar - if same clause, close it; otherwise open new one
            if (this.openChatterClauseId === clauseId) {
                this.openChatterClauseId = null;
            } else {
                this.openChatterClauseId = clauseId;
            }
        }
    }

    handleToggleAdditionalInfo(event) {
        event.preventDefault();
        event.stopPropagation();
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            // Close Chatter if it's open
            if (this.clausesWithChatterVisible[clauseId]) {
                this.clausesWithChatterVisible = {
                    ...this.clausesWithChatterVisible,
                    [clauseId]: false
                };
            }
            // Toggle Additional Information
            this.clausesWithAdditionalInfoVisible = {
                ...this.clausesWithAdditionalInfoVisible,
                [clauseId]: !this.clausesWithAdditionalInfoVisible[clauseId]
            };
        }
    }

    handleChatterCommentChange(event) {
        // Store comment text temporarily - can be enhanced later
        const clauseId = event.currentTarget.dataset.id;
        const commentText = event.target.value;
        // You can store this in a reactive property if needed
    }

    handleChatterCancel(event) {
        const clauseId = event.currentTarget.dataset.id;
        // Clear comment input
        const input = this.template.querySelector(`.chatter-input[data-id="${clauseId}"] input`);
        if (input) {
            input.value = '';
        }
    }

    handleChatterSave(event) {
        const clauseId = event.currentTarget.dataset.id;
        const input = this.template.querySelector(`.chatter-input[data-id="${clauseId}"] input`);
        if (input && input.value.trim()) {
            // The negoptim-chatter component will handle saving
            // For now, just show a toast
            this.showToast('Info', 'Comment will be saved by the chatter component', 'info');
            input.value = '';
        }
    }

    // ==================== CHATTER SLIDE-IN PANEL HANDLERS ====================
    
    handleOpenChatter(event) {
        // Use same handler as handleToggleChatter
        this.handleToggleChatter(event);
    }

    handleCloseChatter() {
        this.openChatterClauseId = null;
    }

    handleActionButtonsClick(event) {
        // Prevent the clause card click event from firing when clicking action buttons
        event.stopPropagation();
    }

    get isChatterOpen() {
        return this.openChatterClauseId !== null;
    }

    get chatterClauseId() {
        return this.openChatterClauseId;
    }

    handleAdditionalInfoBusinessOwnersChange(event) {
        let clauseId = event.currentTarget.dataset.id;
        let selectedValues = event.detail.value || [];
        // Convert array to semicolon-separated string for multi-select picklist
        let businessOwnersValue = selectedValues.join(';');
        
        if (clauseId && this.editingClauses[clauseId]) {
            this.editingClauses = {
                ...this.editingClauses,
                [clauseId]: {
                    ...this.editingClauses[clauseId],
                    BusinessOwners__c: businessOwnersValue,
                    selectedBusinessOwners: selectedValues
                }
            };
        }
    }

    handleSelectClauseType(event) {
        event.stopPropagation();
        let clauseType = event.currentTarget.dataset.type;
        let parentClauseId = event.currentTarget.dataset.clauseId;
        
        this.selectedClauseType = clauseType;
        
        if (parentClauseId) {
            this.clausesWithAddTabs = {
                ...this.clausesWithAddTabs,
                [parentClauseId]: false
            };
        }
        
        let tempId = 'new-clause-' + Date.now();
        // Map clause type from data-type to picklist value
        // data-type values: Title, Subtitle, Body
        // Need to map to actual picklist values
        let clauseTypeValue = this.getClauseTypeValue(clauseType);
        let isNegotiable = (clauseTypeValue === 'Body' || clauseType.toLowerCase() === 'body');
        
        let parentIndex = -1;
        let insertIndex = this.clauses.length;
        let displayOrder = this.clauses.length + 1;
        
        if (parentClauseId) {
            parentIndex = this.clauses.findIndex(c => c.Id === parentClauseId);
            if (parentIndex !== -1) {
                insertIndex = parentIndex + 1;
                let parentOrder = this.clauses[parentIndex].DisplayOrder__c;
                if (parentOrder) {
                    displayOrder = Math.ceil(parentOrder) + 1;
                } else {
                    displayOrder = parentIndex + 2;
                }
                
                this.clauses.forEach((clause, idx) => {
                    if (idx > parentIndex) {
                        let clauseOrder = clause.DisplayOrder__c || (idx + 1);
                        if (clauseOrder >= displayOrder) {
                            clause.DisplayOrder__c = clauseOrder + 1;
                        }
                    }
                });
            }
        }
        
        // Ensure displayOrder is an integer
        displayOrder = Math.floor(displayOrder);
        
        let newClause = {
            Id: tempId,
            LegalDoc__c: this.recordId,
            Clause__c: '',
            Version__c: 0,
            Status__c: 'Draft',
            LegalStatus__c: 'Draft',
            PartnerStatus__c: 'Draft',
            BusinessStatus__c: 'Draft',
            DisplayOrder__c: displayOrder,
            IsNegotiable__c: isNegotiable,
            ClauseType__c: clauseTypeValue,
            BusinessOwners__c: 'Legal',
            LegalDocClause__c: null,
            UpdateOrigin__c: null,
            isNew: true // Flag to identify this as a new clause
        };
        
        // Remove isNew flag from all previously added clauses (only latest should be yellow)
        let clausesCopy = this.clauses.map(clause => {
            if (clause.isNew === true || (clause.Id && clause.Id.startsWith('new-clause-'))) {
                let updatedClause = { ...clause };
                delete updatedClause.isNew;
                return updatedClause;
            }
            return clause;
        });
        
        // Insert the new clause with isNew flag - ensure it's explicitly set
        newClause.isNew = true;
        clausesCopy.splice(insertIndex, 0, newClause);
        
        // Double-check: ensure the inserted clause has isNew flag
        let insertedClause = clausesCopy[insertIndex];
        if (insertedClause) {
            insertedClause.isNew = true;
        }
        
        // Force reactivity by creating a new array
        this.clauses = [...clausesCopy];
        
        if (this.expandedClauseIds.length > 0) {
            let previousExpandedIds = [...this.expandedClauseIds];
            let newEditingClauses = { ...this.editingClauses };
            let newEditingMap = { ...this.isEditingNewVersionMap };
            let newCompareMap = { ...this.selectedCompareVersionIds };
            
            previousExpandedIds.forEach(id => {
                delete newEditingClauses[id];
                delete newEditingMap[id];
                delete newCompareMap[id];
            });
            
            this.editingClauses = newEditingClauses;
            this.isEditingNewVersionMap = newEditingMap;
            this.selectedCompareVersionIds = newCompareMap;
        }
        
        this.expandedClauseIds = [tempId];
        // Preserve isNew flag in editingClauses
        let editingClauseData = { 
            ...newClause, 
            originalClause: '', 
            IsNegotiable__c: isNegotiable,
            selectedBusinessOwners: ['Legal']
        };
        editingClauseData.isNew = true; // Ensure isNew is preserved
        this.editingClauses = {
            ...this.editingClauses,
            [tempId]: editingClauseData
        };
        this.isEditingNewVersionMap = { ...this.isEditingNewVersionMap, [tempId]: false };
        this.selectedCompareVersionIds = { ...this.selectedCompareVersionIds, [tempId]: null };
        
        setTimeout(() => {
            this.scrollToClauseModal(tempId);
        }, 100);
    }
    
    scrollToClauseModal(clauseId) {
        // Find the modal element for this clause
        const modalElement = this.template.querySelector(`[data-clause-modal-id="${clauseId}"]`);
        if (modalElement) {
            const yOffset = -20;
            const y = modalElement.getBoundingClientRect().top + window.pageYOffset + yOffset;
            
            window.scrollTo({ 
                top: y, 
                behavior: 'smooth'
            });
        } else {
            // Fallback: try to find by clause item wrapper
            const clauseWrapper = this.template.querySelector(`[data-clause-id="${clauseId}"]`);
            if (clauseWrapper) {
                const modal = clauseWrapper.querySelector('.simple-edit-inline, .comparison-inline');
                if (modal) {
                    const yOffset = -20;
                    const y = modal.getBoundingClientRect().top + window.pageYOffset + yOffset;
                    window.scrollTo({ 
                        top: y, 
                        behavior: 'smooth'
                    });
                } else {
                    const yOffset = -20;
                    const y = clauseWrapper.getBoundingClientRect().top + window.pageYOffset + yOffset;
                    window.scrollTo({ 
                        top: y, 
                        behavior: 'smooth'
                    });
                }
            }
        }
    }

    handleToggleEditMode(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        if (clauseId) {
            this.isEditingNewVersionMap = { 
                ...this.isEditingNewVersionMap, 
                [clauseId]: !this.isEditingNewVersionMap[clauseId] 
            };
        }
    }

    handleNewVersionChange(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id || event?.currentTarget?.dataset?.clauseId;
        // For lightning-input-rich-text, value is in event.detail.value
        let newValue = event.detail?.value !== undefined ? event.detail.value : (event.target?.value || '');
        
        console.log('handleNewVersionChange - clauseId:', clauseId);
        console.log('handleNewVersionChange - event.detail:', event.detail);
        console.log('handleNewVersionChange - newValue:', newValue);
        
        if (clauseId && this.editingClauses[clauseId]) {
            this.editingClauses = { 
                ...this.editingClauses, 
                [clauseId]: { ...this.editingClauses[clauseId], Clause__c: newValue }
            };
        } else {
            console.warn('handleNewVersionChange - clauseId not found or editingClauses not set. clauseId:', clauseId);
        }
    }

    handleEditingClauseNegotiableChange(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let isNegotiable = event.target.checked || event.currentTarget.checked;
        if (clauseId && this.editingClauses[clauseId]) {
            this.editingClauses = { 
                ...this.editingClauses, 
                [clauseId]: { ...this.editingClauses[clauseId], IsNegotiable__c: isNegotiable }
            };
        }
    }

    handleSaveClause(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let editingClause = this.editingClauses[clauseId];
        if (!editingClause) return;
        
        // Check if this is a new clause
        let isNewClause = editingClause.isNew || clauseId.startsWith('new-clause-');
        
        if (isNewClause) {
            // Get the clause content - ensure we're using the latest value
            let clauseContent = editingClause.Clause__c || '';
            console.log('handleSaveClause - Saving new clause. clauseId:', clauseId);
            console.log('handleSaveClause - editingClause:', editingClause);
            console.log('handleSaveClause - clauseContent:', clauseContent);
            console.log('handleSaveClause - clauseContent length:', clauseContent.length);
            
            // Validate content for new clause
            let clauseText = this.stripHtmlTags(clauseContent).trim();
            console.log('handleSaveClause - clauseText after stripHtmlTags:', clauseText);
            if (!clauseText) {
                this.showToast('Erreur', 'Veuillez saisir le texte de la clause', 'error');
                return;
            }
            
            // Create new clause
            // Map clause type to picklist value
            let clauseTypeValue = this.getClauseTypeValue(editingClause.ClauseType__c);
            let clauseToSave = {
                LegalDoc__c: this.recordId,
                Clause__c: clauseContent, // Use the captured content
                Version__c: 0,
                Status__c: editingClause.Status__c || 'Draft',
                LegalStatus__c: editingClause.LegalStatus__c || 'Draft',
                PartnerStatus__c: editingClause.PartnerStatus__c || 'Draft',
                BusinessStatus__c: editingClause.BusinessStatus__c || 'Draft',
                DisplayOrder__c: editingClause.DisplayOrder__c || this.clauses.length + 1,
                IsNegotiable__c: editingClause.IsNegotiable__c || false,
                ClauseType__c: clauseTypeValue,
                BusinessOwners__c: editingClause.BusinessOwners__c || 'Legal',
                LegalDocClause__c: null,
                UpdateOrigin__c: null
            };
            
            // Store display order to find clause after reload
            const savedDisplayOrder = clauseToSave.DisplayOrder__c;
            
            this.saveClauseHelper(
                clauseToSave,
                null,
                this.recordId,
                false,
                this.isPortalUser,
                false,
                false
            ).then(() => {
                this.showToast('Succès', 'Clause ajoutée avec succès', 'success');
                this.closeEditingClause(clauseId);
                this.loadData();
                
                // After data reloads, scroll to the saved clause
                setTimeout(() => {
                    const displayClauses = this.displayClauses || [];
                    const savedClause = displayClauses.find(clause => clause.DisplayOrder__c === savedDisplayOrder);
                    
                    if (savedClause) {
                        // Scroll to the clause
                        setTimeout(() => {
                            this.scrollToClauseModal(savedClause.Id);
                        }, 200);
                    }
                }, 300);
            }).catch(error => {
                this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
            });
            return;
        }
        
        // Compare HTML content directly to detect formatting changes
        let originalContent = (editingClause.originalClause || '').trim();
        let newContent = (editingClause.Clause__c || '').trim();
            
            if (originalContent === newContent) {
                this.showToast('Info', 'Aucune modification détectée', 'info');
                return;
            }

        let originClauseId = editingClause.LegalDocClause__c || 
            (editingClause.Version__c === 0 ? editingClause.Id : null);
            
            // Map clause type to picklist value
            let clauseTypeValue = this.getClauseTypeValue(editingClause.ClauseType__c);
            let newClause = {
                LegalDoc__c: this.recordId,
            Clause__c: editingClause.Clause__c,
            DisplayOrder__c: editingClause.DisplayOrder__c,
            Status__c: editingClause.Status__c || 'Open',
            LegalStatus__c: editingClause.LegalStatus__c,
            PartnerStatus__c: editingClause.PartnerStatus__c,
            BusinessStatus__c: editingClause.BusinessStatus__c,
            ClauseL1__c: editingClause.ClauseL1__c,
            ClauseL2__c: editingClause.ClauseL2__c,
            ClauseType__c: clauseTypeValue,
            IsNegotiable__c: editingClause.IsNegotiable__c,
            Supplier__c : editingClause.Supplier__c
            };
            if (this.isPortalUser) {
            if (editingClause.UpdateOrigin__c == 'Supplier' && editingClause.Status__c ==  'Draft') {
                newClause.Id = editingClause.Id;
                } else {
                    newClause.Status__c =  'Draft';
                    newClause.LegalStatus__c = 'Open';
                    newClause.BusinessStatus__c = 'Open';
                    newClause.PartnerStatus__c = 'Draft';
                    newClause.UpdateOrigin__c = 'Supplier';
                newClause.LegalDocClauseP1__c = editingClause.Id;
                newClause.Version__c =  (editingClause.Version__c || 0) + 1;
                }
            } else {
            if (editingClause.UpdateOrigin__c == 'Legal' && editingClause.Status__c ==  'Draft') {
                newClause.Id = editingClause.Id;
                } else {
                    newClause.Status__c =  'Draft';
                    newClause.LegalStatus__c = 'Draft';
                    newClause.BusinessStatus__c = 'Open';
                    newClause.PartnerStatus__c = 'Open';
                    newClause.UpdateOrigin__c = 'Legal';
                    newClause.LegalDocClause__c = originClauseId;
                newClause.LegalDocClauseP1__c = editingClause.Id;
                newClause.Version__c =  (editingClause.Version__c || 0) + 1;
                }
            }
        this.saveClauseHelper(
            newClause,
            null,
            this.recordId,
            false,
            this.isPortalUser,
            false,
            false
        ).then(() => {
            this.showToast('Succès', `Nouvelle version (V${newClause.Version__c}) créée`, 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur: ' + error.body?.message, 'error');
        });
    }
    
    // Helper method to close a specific editing clause
    closeEditingClause(clauseId) {
        if (clauseId) {
            this.expandedClauseIds = this.expandedClauseIds.filter(id => id !== clauseId);
            let newEditingClauses = { ...this.editingClauses };
            delete newEditingClauses[clauseId];
            this.editingClauses = newEditingClauses;
            let newEditingMap = { ...this.isEditingNewVersionMap };
            delete newEditingMap[clauseId];
            this.isEditingNewVersionMap = newEditingMap;
            let newCompareMap = { ...this.selectedCompareVersionIds };
            delete newCompareMap[clauseId];
            this.selectedCompareVersionIds = newCompareMap;
        }
    }
    handlePublishClause(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let editingClause = this.editingClauses[clauseId];
        if (!editingClause) return;
            
            let newClause = {
            Id : editingClause.Id,
            Supplier__c : editingClause.Supplier__c
            };
            if (this.isPortalUser) {
                newClause.Status__c = 'published';
                newClause.PartnerStatus__c = 'Validated';
            } else {
                newClause.LegalStatus__c = 'Validated';
                newClause.Status__c = 'legal publishing';
            }
            
        this.saveClauseHelper(
            newClause,
            editingClause.LegalDocClauseP1__c,
            this.recordId,
            true,
            this.isPortalUser,
            false,
            false
        ).then(() => {
            this.showToast('Succès', 'Modifications publiées et envoyées pour validation', 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        });
    }
    handleValidateClause(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let editingClause = this.editingClauses[clauseId];
        if (!editingClause) return;
        
            let newClause = {
            Id : editingClause.Id,
            Supplier__c : editingClause.Supplier__c
            };
            if (this.isPortalUser) {
                newClause.Status__c = 'Validated';
                newClause.LegalStatus__c = 'Validated';
            }
            
        this.saveClauseHelper(
            newClause,
            editingClause.LegalDocClauseP1__c,
            this.recordId,
            false,
            this.isPortalUser,
            true,
            false
        ).then(() => {
            this.showToast('Succès', 'Modifications publiées et envoyées pour validation', 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        });
    }
    handleAcceptClause(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let editingClause = this.editingClauses[clauseId];
        if (!editingClause) return;
        
            let newClause = {
            Id : editingClause.Id,
            Supplier__c : editingClause.Supplier__c
            };
            if (this.isPortalUser) {
                newClause.PartnerStatus__c = 'Approved';
            } else {
                newClause.LegalStatus__c = 'Approved';
                newClause.Status__c = 'Approved';
            }
        this.saveClauseHelper(
            newClause,
            editingClause.LegalDocClauseP1__c,
            this.recordId,
            false,
            this.isPortalUser,
            false,
            true
        ).then(() => {
            this.showToast('Succès', 'Modifications publiées et envoyées pour validation', 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        });
    }

    // ==================== SIMPLE EDIT (No Supplier Mode) ====================

    handleSaveSimpleEdit(event) {
        let clauseId = event?.currentTarget?.dataset?.id || event?.target?.dataset?.id;
        let editingClause = this.editingClauses[clauseId];
        if (!editingClause) return;
        
        // Check if this is a new clause
        let isNewClause = editingClause.isNew || clauseId.startsWith('new-clause-');
        
        if (isNewClause) {
            // Validate content for new clause
            let clauseText = this.stripHtmlTags(editingClause.Clause__c || '').trim();
            if (!clauseText) {
                this.showToast('Erreur', 'Veuillez saisir le texte de la clause', 'error');
                return;
            }
            
            // Create new clause
            let clauseToSave = {
                LegalDoc__c: this.recordId,
                Clause__c: editingClause.Clause__c,
                Version__c: 0,
                Status__c: editingClause.Status__c || 'Draft',
                LegalStatus__c: editingClause.LegalStatus__c || 'Draft',
                PartnerStatus__c: editingClause.PartnerStatus__c || 'Draft',
                BusinessStatus__c: editingClause.BusinessStatus__c || 'Draft',
                DisplayOrder__c: editingClause.DisplayOrder__c || this.clauses.length + 1,
                IsNegotiable__c: editingClause.IsNegotiable__c || false,
                ClauseType__c: editingClause.ClauseType__c,
                BusinessOwners__c: editingClause.BusinessOwners__c || 'Legal',
                LegalDocClause__c: null,
                UpdateOrigin__c: null
            };
            
            this.saveClauseHelper(
                clauseToSave,
                null,
                this.recordId,
                false,
                false,
                false,
                false
            ).then(() => {
                this.showToast('Succès', 'Clause ajoutée avec succès', 'success');
                this.closeEditingClause(clauseId);
                this.loadData();
            }).catch(error => {
                this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
            });
        } else {
            // Update existing clause
        // Compare HTML content directly to detect formatting changes
        let originalContent = (editingClause.originalClause || '').trim();
        let newContent = (editingClause.Clause__c || '').trim();
        
        let originalClause = this.clauses.find(c => c.Id === editingClause.Id);
            let originalIsNegotiable = originalClause?.IsNegotiable__c || false;
        let newIsNegotiable = editingClause.IsNegotiable__c || false;
            
            if (originalContent === newContent && originalIsNegotiable === newIsNegotiable) {
                this.showToast('Info', 'Aucune modification détectée', 'info');
                return;
            }

            let clauseToSave = {
            Id: editingClause.Id,
            Clause__c: editingClause.Clause__c,
            IsNegotiable__c: editingClause.IsNegotiable__c || false
        };
        
        this.saveClauseHelper(
            clauseToSave,
            null,
            this.recordId,
            false,
            false,
            false,
            false
        ).then(() => {
            this.showToast('Succès', 'Clause modifiée avec succès', 'success');
            this.closeEditingClause(clauseId);
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        });
        }
    }

    // ==================== DRAG AND DROP HANDLERS ====================

    handleDragHandleClick(event) {
        // Stop propagation to prevent triggering edit when clicking drag handle
        event.stopPropagation();
    }

    handleDragStart(event) {
        if (this.isPortalUser) return;
        
        this.draggedClauseId = event.currentTarget.dataset.id;
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedClauseId);
        
        // Store original order if not already stored
        if (!this.hasOrderChanged) {
            this.originalOrder = this.clauses.map(c => ({ Id: c.Id, DisplayOrder__c: c.DisplayOrder__c }));
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
        
        if (draggedIndex === -1 || targetIndex === -1) return;
        
        let [draggedClause] = clausesCopy.splice(draggedIndex, 1);
        clausesCopy.splice(targetIndex, 0, draggedClause);
        
        clausesCopy.forEach((clause, index) => {
            clause.DisplayOrder__c = index + 1;
        });
        
        this.clauses = clausesCopy;
        this.hasOrderChanged = true;
    }

    handleStatusFilterChange(event) {
        this.selectedStatusFilter = event.detail.value || '';
    }

    handleClauseTypeFilterChange(event) {
        this.selectedClauseTypeFilter = event.detail.value || '';
    }

    handleStatusBadgeClick(event) {
        event.stopPropagation();
        const clauseId = event.currentTarget.dataset.id;
        const currentStatus = event.currentTarget.dataset.status;
        // Open a modal or dropdown to change status
        // For now, just show a toast - you can enhance this later
        this.showToast('Info', `Current status: ${currentStatus}. Status change functionality can be added here.`, 'info');
    }

    handleSaveOrder() {
        if (!this.hasOrderChanged) return;
        
            this.isLoading = true;
            let clausesToUpdate = this.clauses.map((clause, index) => ({
                Id: clause.Id,
                DisplayOrder__c: index + 1
            }));
            
        saveClauses({ 
            clausesJson: JSON.stringify(clausesToUpdate)
        }).then(() => {
            this.hasOrderChanged = false;
            this.originalOrder = [];
            this.showToast('Succès', 'L\'ordre des clauses a été sauvegardé', 'success');
            this.loadData();
        }).catch(error => {
            this.showToast('Erreur', 'Erreur lors de la sauvegarde: ' + (error.body?.message || error.message), 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }
}