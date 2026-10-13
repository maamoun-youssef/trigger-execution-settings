/**
* @author ULiT
* @date 22-08-2024
* @description CodManager
*******************************************************************************************************************************************
*/
import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
//APEX
import initData from '@salesforce/apex/CodManagerCtrl.getInitialData';
import loadData from '@salesforce/apex/CodManagerCtrl.loadData';
import saveData from '@salesforce/apex/CodManagerCtrl.saveData';
import saveCOD from '@salesforce/apex/CodManagerCtrl.saveCOD';
import saveRelatedData from '@salesforce/apex/CodManagerCtrl.saveRelatedData';
import saveUserData from '@salesforce/apex/CodManagerCtrl.saveUserData';
import isUsernameTaken from '@salesforce/apex/CodManagerCtrl.isUsernameTaken';
import resetPassword from '@salesforce/apex/CodManagerCtrl.resetPassword';
import sendEmailToValidate from '@salesforce/apex/CodManagerCtrl.sendEmailToValidate';
import checkContactDuplication from '@salesforce/apex/CodManagerCtrl.checkContactDuplication';
import deleteRecord from '@salesforce/apex/CodManagerCtrl.deleteRecord';
import getCodById from '@salesforce/apex/CodManagerCtrl.getCodById';
//STATIC RESOURCES
import FEMALE_PHOTO from '@salesforce/resourceUrl/PdPFemale';
import MALE_PHOTO from '@salesforce/resourceUrl/PdPMale';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LANGUAGE_FIELD from '@salesforce/schema/User.LanguageLocaleKey';
import LOCALE_FIELD from '@salesforce/schema/User.LocaleSidKey';
//OBJECTS
import ContactOperationalDirectory__c from '@salesforce/schema/ContactOperationalDirectory__c';
import Contact from '@salesforce/schema/Contact';
import User from '@salesforce/schema/User';
import Cometd from 'c/cometd';

import SUPPLIER_OBJECT from '@salesforce/schema/Supplier__c';
const PREFIX__ = SUPPLIER_OBJECT.objectApiName.replace(/Supplier__c/gi, '');
const PREFIX = PREFIX__.replace(/__/gi, '');
const COD_CHANNEL = `/event/${PREFIX__}ContactOperationalDirectoryEvent__e`;

import { labels, CONTACT_API_NAMES, COD_API_NAMES, SUPPLIER_API_NAMES, USER_API_NAMES, icons, NS_API_NAMES } from './properties'

export default class CodManager extends LightningElement {
    // @track CONNECT_SETTINGS_API_NAMES = {}
    USER_API_NAMES = USER_API_NAMES;
    CONTACT_API_NAMES = CONTACT_API_NAMES;
    COD_API_NAMES = COD_API_NAMES;
    NS_API_NAMES = NS_API_NAMES;
    SUPPLIER_API_NAMES = SUPPLIER_API_NAMES;
    icons = icons;
    cometdManager;
    @api recordId;
    @track labels = labels;
    @track prefix;
    //OBJECTS
    fieldsMap = {};
    picklistLabelsMap = {};
    @track currentUser = {};
    @track supplier = {};
    @track supplierLicenseQuota;
    connectSettings = {};
    @track licenseQuota;
    @track connectUserPermissionSetId;
    @track currentContact;
    @track connectUserPermissionSetId;
    @track currentContact;
    @track defaultLanguageLocaleKey;
    @track defaultLocaleSidKey;
    //LISTS
    @track contactList = [];
    @track salutationOptions;
    @track contactsBackupList;
    @track searchTerm = '';
    @track isPageLoaded = false;
    @track queuedSearch = null;
    @track user = {};

    //MAPS
    @track contactToUserMap = {};
    @track CodActivationStatusLabels = {
        RequestedCreation: '',
        RequestedModification: '',
        RequestedDeactivation: '',
        RequestedReactivation: '',
        InPreparation: '',
    };
    @track codBackupMap = {};
    //BOOLEANS
    isLoading = true;
    @track processing = false;
    @track showContactTypePanel = false;
    @track showAddMailboxContact = false;
    isEmpty = false;
    @track allowNewContact = false;
    @track isNonApproval = false;
    @track isManager = false;
    @track isApproval = false;
    @track isReadOnly = false;
    showtable1 = false;
    @track contactEditMode = false;
    sendNotification = false;
    @track directoryManager;
    @track contact = {};

    //STRINGS
    @track showUserNameValidationMsg = false;
    //STYLE
    @track cardStyle = '';
    //POPUPS
    @track confirmationPopUp = {
        title: '',
        message: '',
        action: () => { },
        show: false,
        close: this.closeConfirmationPopup
    }
    //negOptimCustomLookup(negoscope)
    Events = {
        selectNegoScopeAction: 'selectnegoscopeaction',
    }
    @track selectedNegoScopeId;
    @track selectedNegoScopeName;
    @track searchNegoScopeFields = ['Name'];
    @track negoscopeNames = {};
    @track popup = {
        visibility: false,
        title: '',
        body: '',
        subBody: '',
        submitBtnClass: '',
        submitBtn: '',
        cancelBtn: ''
    }
    @track languageOptions = [];
    @track localeOptions = [];
    contactFields = [];
    summaryFields = [];
    headerFields = [];
    additionalFields = [];
    roleOptions = [];
    signatoryOptions = [];
    reqAccountingRoleOptions = [];

    get contactFilter() {
        let supplierId = this.supplier?.Id || this.recordId;
        if (!supplierId) {
            return {}
        }
        return {
            criteria: [
                { fieldPath: CONTACT_API_NAMES.Supplier__c, operator: 'eq', value: supplierId }
            ]
        }
    }
    get panelContainerClass() {
        if (this.showContactPanel) {
            return 'contactPanelContainer';
        } else if (this.showAddIndividualContact) {
            // return 'addNewPanelContainer slds-scrollable';
            return 'addNewPanelContainer';
        }
        else if (this.showContactTypePanel || this.showAddMailboxContact) {
            return 'fullHeightContainer';
        }
    }

    get showCodTable() {
        return !this.showContactTypePanel && !this.showAddMailboxContact && (this.contact && !this.contact.isMailbox);
    }

    @wire(getObjectInfo, { objectApiName: 'User' })
    wiredUserObjectInfo({ data, error }) {
        if (data) {
            this.userObjectInfo = data;
        } else if (error) {
            console.error(' Error loading user object info:', error);
        }
    }

    userObjectInfo;
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: LANGUAGE_FIELD
    })
    wiredLanguagePicklist({ error, data }) {
        if (data) {
            const allowed = ['en_US', 'fr'];
            this.languageOptions = data.values
                .filter(item => allowed.includes(item.value))
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
        } else if (error) {
            console.error('Error loading language picklist:', error);
        }
    }
    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: LOCALE_FIELD
    })
    wiredLocalePicklist({ error, data }) {
        if (data) {
            const allowed = ['en_US', 'fr_FR'];
            this.localeOptions = data.values.filter(item => allowed.includes(item.value)).map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading locale picklist:', error);
        }
    }


    selectNegoScopeAction(event) {
        try {
            let withApproval = event.target.dataset.withApproval;
            if (event?.detail?.selRecords?.length) {
                this.selectedNegoScopeName = event.detail.selRecords[0].recName;
                this.selectedNegoScopeId = event.detail.selRecords[0].recId;
                this.negoscopeNames[event.detail.selRecords[0].recId] = event.detail.selRecords[0].recName;
            } else {
                this.selectedNegoScopeName = '';
                this.selectedNegoScopeId = '';
            }
            let id = event.target.dataset.id;
            let field = event.target.dataset.field;
            let cod;
            if (this.changesMap.hasOwnProperty(id)) {
                cod = this.changesMap[id];
            } else {
                cod = {
                    id: id,
                    get _Negoscope__c() { return cod[COD_API_NAMES.Negoscope__c]; },
                    get _ContactRole__c() { return cod[COD_API_NAMES.ContactRole__c]; },
                    get _IsSignatory__c() { return cod[COD_API_NAMES.IsSignatory__c]; },
                    get _IsInvoiceRecipient__c() { return cod[COD_API_NAMES.IsInvoiceRecipient__c]; },
                    get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                    get _RequestedRole__c() { return cod[COD_API_NAMES.RequestedRole__c]; },
                    get _RequestedSignatoryRole__c() { return cod[COD_API_NAMES.RequestedSignatoryRole__c]; },
                    get _RequestedInvoiceRecipient__c() { return cod[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                    get _IsDeactivationRequested__c() { return cod[COD_API_NAMES.IsDeactivationRequested__c]; },
                    get _IsReactivationRequested__c() { return cod[COD_API_NAMES.IsReactivationRequested__c]; },
                    get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                }
            }
            const selectedCod = (this.contact.inPreparationCods?.find(item => item.id == id) || this.contact.codWrapList?.find(item => item.id == id) || {});
            cod[field] = this.selectedNegoScopeId;
            if (this.isManager) {
                if (field == COD_API_NAMES.Negoscope__c || this.isNonApproval) {
                    cod[COD_API_NAMES.RequestedNegoscope__c] = this.selectedNegoScopeId;
                    cod[COD_API_NAMES.Negoscope__c] = this.selectedNegoScopeId;
                    cod.negoScopeName = this.selectedNegoScopeName;
                    selectedCod.negoScopeName = this.selectedNegoScopeName;
                }
            }
            if (field == COD_API_NAMES.RequestedNegoscope__c) {
                cod.RequestedNegoScopeName = this.selectedNegoScopeName;
                selectedCod.RequestedNegoScopeName = this.selectedNegoScopeName;
                if (!selectedCod.hasRequest) {
                    cod[COD_API_NAMES.ActivationStatus__c] = 'Requested Modification';
                }
            }
            selectedCod.hasNegoscope = this.selectedNegoScopeName !== '';
            selectedCod.defaultNegoscopeValue = this.changesMap[id] = cod;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }

    }

    get NegoScopeFilter() {
        let filterToken = [];
        filterToken.push(' ' + NS_API_NAMES.Supplier__c + ' = \'' + this.supplier.Id + '\' ');
        const negoscopeIds = this.contact.codWrapList.map(item => item[COD_API_NAMES.Negoscope__c])
        filterToken.push("RecordType.DeveloperName IN ('Advanced', 'Regular')");
        if (negoscopeIds.length > 0) {
            filterToken.push(' ' + NS_API_NAMES.id + ' NOT IN (\'' + negoscopeIds.join('\', \'') + '\')');
        }
        return filterToken.join(' AND ');
    }

    closeConfirmationPopup() {
        this.confirmationPopUp = { ...this.confirmationPopUp, show: false };
    }

    confirmationPopupAction() {
        if (this.confirmationPopUp.context.includes('cod')) {
            const isInPreperation = this.confirmationPopUp.context === 'cod-inPreparation';
            this.handleDeactivate(isInPreperation);
        }
        else if (this.confirmationPopUp.context == 'user') {
            this.handlePortalActivation();
        }
        this.confirmationPopUp = { show: false };
    }

    //LIFECYCLE
    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        this.initData();
        this.cometdManager = new Cometd(this);
        let codEvents = [];
        let isConsumeInAction = false;
        let timer = null;
        let timerWrapper = () => {
            if (timer) clearTimeout(timer);
            timer = setTimeout(() => {
                consumeEvent();
            }, 1000);
        }
        let consumeEvent = () => {
            if (isConsumeInAction || !codEvents.length) {
                return;
            }
            isConsumeInAction = true;
            try {
                let item = codEvents.splice(0, 1)[0];
                const response = item?.data?.payload;
                if (response?.[`${PREFIX__}Supplier__c`] == this.supplier?.Id) {
                    const contactId = response?.[`${PREFIX__}Contact__c`];
                    const isDeleted = response?.[`${PREFIX__}Mode__c`] == 'Delete';
                    const isNew = response?.[`${PREFIX__}Mode__c`] == 'Insert';
                    const isUpdate = response?.[`${PREFIX__}Mode__c`] == 'Update';
                    const codId = response?.[`${PREFIX__}ContactOperationalDirectory__c`];
                    let contact = this.contactList?.find(c => c.id === contactId);
                    if (contact) {
                        contact.codWrapList = (contact.codWrapList || []).filter(x => x.Id !== codId && x.id !== codId);
                        contact.newRequestsList = (contact.newRequestsList || []).filter(x => x.Id !== codId && x.id !== codId);
                        contact.inPreparationCods = (contact.inPreparationCods || []).filter(x => x.Id !== codId && x.id !== codId);
                        contact.validatedCods = (contact.validatedCods || []).filter(x => x.Id !== codId && x.id !== codId);
                        contact.requestedCods = (contact.requestedCods || []).filter(x => x.Id !== codId && x.id !== codId);
                        if (isDeleted) {
                            contact.inPreparationCods = [...contact.inPreparationCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                            contact.validatedCods = [...contact.validatedCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                            contact.requestedCods = [...contact.requestedCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                            contact.codWrapList = [...contact.codWrapList].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                            contact.newRequestsList = [...contact.newRequestsList].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                            contact.hasCod = contact?.codWrapList?.length > 0;
                            contact.hasNewRequests = contact?.newRequestsList?.length > 0;
                            contact.hasrequestedCods = contact?.requestedCods?.length > 0;
                            contact.hasvalidatedCods = contact?.validatedCods?.length > 0;
                            contact.hasinPreparationCods = contact?.inPreparationCods?.length > 0;
                            let localcontactList = this.contactList;
                            let resetCurrentContact = this.contact.Id == contact.Id;
                            if (resetCurrentContact) {
                                this.contact = null;
                            }
                            this.contactList = [];
                            setTimeout(() => {
                                this.contactList = [...localcontactList];
                                contact.hasCod = contact?.codWrapList?.length > 0;
                                contact.hasNewRequests = contact?.newRequestsList?.length > 0;
                                contact.hasrequestedCods = contact?.requestedCods?.length > 0;
                                contact.hasvalidatedCods = contact?.validatedCods?.length > 0;
                                contact.hasinPreparationCods = contact?.inPreparationCods?.length > 0;
                                if (resetCurrentContact) {
                                    this.contact = contact;
                                }
                            }, 0);
                            isConsumeInAction = false;
                            timerWrapper();
                        } else {
                            getCodById({ codId: codId }).then(result => {
                                const codList = JSON.parse(result);
                                if (codList?.length) {
                                    const cod = codList[0];
                                    let codWrap = {
                                        Id: cod.Id,
                                        id: cod.Id,
                                        [COD_API_NAMES.ActivationStatus__c]: cod[COD_API_NAMES.ActivationStatus__c],
                                        [COD_API_NAMES.Supplier__c]: this.supplier.Id,
                                        [COD_API_NAMES.Negoscope__c]: cod[COD_API_NAMES.Negoscope__c],
                                        [COD_API_NAMES.ContactRole__c]: cod[COD_API_NAMES.ContactRole__c],
                                        [COD_API_NAMES.IsSignatory__c]: cod[COD_API_NAMES.IsSignatory__c],
                                        [COD_API_NAMES.SignatoryRole__c]: cod[COD_API_NAMES.SignatoryRole__c],
                                        [COD_API_NAMES.IsInvoiceRecipient__c]: cod[COD_API_NAMES.IsInvoiceRecipient__c],
                                        [COD_API_NAMES.RequestedSignatoryRole__c]: cod[COD_API_NAMES.RequestedSignatoryRole__c],
                                        [COD_API_NAMES.RequestedInvoiceRecipient__c]: cod[COD_API_NAMES.RequestedInvoiceRecipient__c],
                                        [COD_API_NAMES.RequestedNegoscope__c]: cod[COD_API_NAMES.RequestedNegoscope__c],
                                        [COD_API_NAMES.RequestedRole__c]: cod[COD_API_NAMES.RequestedRole__c],
                                        [COD_API_NAMES.RequestedAccountingRole__c]: cod[COD_API_NAMES.RequestedAccountingRole__c],
                                        [COD_API_NAMES.IsDeactivationRequested__c]: cod[COD_API_NAMES.IsDeactivationRequested__c],
                                        [COD_API_NAMES.IsReactivationRequested__c]: cod[COD_API_NAMES.IsReactivationRequested__c],
                                        activationStatusIcon: 'standard:incident',
                                        negoScopeName: '',
                                        negoScopeLink: '',
                                        roleOutput: '',
                                        signatoryOutput: '',
                                        RequestedNegoScopeName: '',
                                        RequestedNegoScopeLink: '',
                                        RequestedRoleOutput: '',
                                        RequestedSignatoryOutput: '',
                                        isActive: cod[COD_API_NAMES.ActivationStatus__c] === 'Validated Entry',
                                        isDeactivated: cod[COD_API_NAMES.ActivationStatus__c] === 'Deactivated',
                                        showActions: (cod[COD_API_NAMES.ActivationStatus__c] !== 'Deactivated' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Deactivation' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Modification' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Reactivation'),
                                        isRequesting: false,
                                        newRequest: false,
                                        hasNegoscope: (this.isManager && (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.Negoscope__c])) || (this.isApproval && cod[COD_API_NAMES.RequestedNegoscope__c]),
                                        canActivate: ['Deactivated'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' && !this.isNonApproval),
                                        canDeactivate: ['Validated Entry'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation' && !this.isNonApproval),
                                        canDelete: ['Deactivated', 'In Preparation'].includes(cod[COD_API_NAMES.ActivationStatus__c]),
                                        canCancelReq: cod[COD_API_NAMES.IsDeactivationRequested__c] || cod[COD_API_NAMES.IsReactivationRequested__c] || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation',
                                        get _Negoscope__c() { return codWrap[COD_API_NAMES.Negoscope__c]; },
                                        get _ContactRole__c() { return codWrap[COD_API_NAMES.ContactRole__c]; },
                                        get _IsSignatory__c() { return codWrap[COD_API_NAMES.IsSignatory__c]; },
                                        get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                                        get _IsInvoiceRecipient__c() { return codWrap[COD_API_NAMES.IsInvoiceRecipient__c]; },
                                        get _RequestedRole__c() { return codWrap[COD_API_NAMES.RequestedRole__c]; },
                                        get _RequestedSignatoryRole__c() { return codWrap[COD_API_NAMES.RequestedSignatoryRole__c]; },
                                        get _RequestedInvoiceRecipient__c() { return codWrap[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                                        get _IsDeactivationRequested__c() { return codWrap[COD_API_NAMES.IsDeactivationRequested__c]; },
                                        get _IsReactivationRequested__c() { return codWrap[COD_API_NAMES.IsReactivationRequested__c]; },
                                        get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                                    }

                                    //ONlY SHOW LINE IF IT HAS ANY ACTUAL DATA -- IF NOT JUST SHOW REQUEST ROW
                                    this.checkHasRequest(codWrap);
                                    //SET UP VALUES FOR DISPLAY
                                    codWrap.negoScopeName = cod[COD_API_NAMES.Negoscope__c.replace('__c', '__r')]?.Name;
                                    codWrap.negoScopeLink = '/' + cod[COD_API_NAMES.Negoscope__c];
                                    codWrap.RequestedNegoScopeName = cod[COD_API_NAMES.RequestedNegoscope__c.replace('__c', '__r')]?.Name;
                                    codWrap.RequestedNegoScopeLink = '/' + cod[COD_API_NAMES.RequestedNegoscope__c];
                                    codWrap.roleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c][codWrap[COD_API_NAMES.ContactRole__c]];
                                    codWrap.RequestedRoleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedRole__c][codWrap[COD_API_NAMES.RequestedRole__c]];
                                    codWrap.RequestedSignatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][codWrap[COD_API_NAMES.RequestedAccountingRole__c]];
                                    codWrap.signatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c][codWrap[COD_API_NAMES.SignatoryRole__c]];
                                    codWrap.activationStatusOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c][codWrap[COD_API_NAMES.ActivationStatus__c]];
                                    if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
                                        codWrap.activationStatusIcon = 'standard:incident';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                                        codWrap.activationStatusIcon = 'standard:record_create';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                                        codWrap.activationStatusIcon = 'standard:record_update';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
                                        codWrap.activationStatusIcon = 'standard:approval';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Deactivated') {
                                        codWrap.activationStatusIcon = 'standard:unmatched';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
                                        codWrap.activationStatusIcon = 'standard:resource_absence';
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
                                        codWrap.activationStatusIcon = 'standard:resource_absence';
                                    }
                                    if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
                                        //ak placeholder
                                        if (codWrap.hasRequest) {
                                            contact.inPreparationCods.push({ ...codWrap, readOnly: true });
                                            contact.inPreparationCods = [...contact.inPreparationCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                                        }
                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
                                        contact.validatedCods.push(codWrap);
                                        contact.validatedCods = [...contact.validatedCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));

                                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                                        contact.requestedCods.push(codWrap);
                                        contact.requestedCods = [...contact.requestedCods].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                                    }
                                    if (this.checkActualFields(codWrap)) {
                                        contact.codWrapList.push(codWrap);
                                        contact.codWrapList = [...contact.codWrapList].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                                    } else {
                                        contact.newRequestsList.push(codWrap);
                                        contact.newRequestsList = [...contact.newRequestsList].sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName));
                                    }
                                }
                                let localcontactList = this.contactList;
                                let resetCurrentContact = this.contact.Id == contact.Id;
                                if (resetCurrentContact) {
                                    this.contact = null;
                                }
                                this.contactList = [];
                                setTimeout(() => {
                                    this.contactList = [...localcontactList];
                                    contact.hasCod = contact?.codWrapList?.length > 0;
                                    contact.hasNewRequests = contact?.newRequestsList?.length > 0;
                                    contact.hasrequestedCods = contact?.requestedCods?.length > 0;
                                    contact.hasvalidatedCods = contact?.validatedCods?.length > 0;
                                    contact.hasinPreparationCods = contact?.inPreparationCods?.length > 0;
                                    if (resetCurrentContact) {
                                        this.contact = contact;
                                    }
                                }, 0);
                            }).catch(error => {
                                console.error('Error calling getCodById:', error);
                            }).finally(() => {
                                isConsumeInAction = false;
                                timerWrapper();
                            });
                        }
                    } else {
                        isConsumeInAction = false;
                        timerWrapper();
                    }
                } else {
                    isConsumeInAction = false;
                    timerWrapper();
                }
            } catch (err) {
                console.log(`🚀 -------------------------------------------------🚀`);
                console.log(`🚀 ~ :448 ~ CodManager ~ consumeEvent ~ err:`, err);
                console.log(`🚀 -------------------------------------------------🚀`);
            }
        }
        this.cometdManager.initialize().then(() => {
            this.cometdManager.subscribe(COD_CHANNEL, (item) => {
                codEvents.push(item);
                timerWrapper();
            });
        });

        if (!this.user.LanguageLocaleKey) {
            this.user.LanguageLocaleKey = this.defaultLanguageLocaleKey;
        }
        if (!this.user.LocaleSidKey) {
            this.user.LocaleSidKey = this.defaultLocaleSidKey;
        }
    }

    buildCodField(cod) {
        let codWrap;
        codWrap = {
            Id: cod.Id,
            id: cod.Id,
            [COD_API_NAMES.ActivationStatus__c]: cod[COD_API_NAMES.ActivationStatus__c],
            [COD_API_NAMES.Supplier__c]: this.supplier.Id,
            [COD_API_NAMES.Negoscope__c]: cod[COD_API_NAMES.Negoscope__c],
            [COD_API_NAMES.ContactRole__c]: cod[COD_API_NAMES.ContactRole__c],
            [COD_API_NAMES.IsSignatory__c]: cod[COD_API_NAMES.IsSignatory__c],
            [COD_API_NAMES.SignatoryRole__c]: cod[COD_API_NAMES.SignatoryRole__c],
            [COD_API_NAMES.IsInvoiceRecipient__c]: cod[COD_API_NAMES.IsInvoiceRecipient__c],
            [COD_API_NAMES.RequestedSignatoryRole__c]: cod[COD_API_NAMES.RequestedSignatoryRole__c],
            [COD_API_NAMES.RequestedInvoiceRecipient__c]: cod[COD_API_NAMES.RequestedInvoiceRecipient__c],
            [COD_API_NAMES.RequestedNegoscope__c]: cod[COD_API_NAMES.RequestedNegoscope__c],
            [COD_API_NAMES.RequestedRole__c]: cod[COD_API_NAMES.RequestedRole__c],
            [COD_API_NAMES.RequestedAccountingRole__c]: cod[COD_API_NAMES.RequestedAccountingRole__c],
            [COD_API_NAMES.IsDeactivationRequested__c]: cod[COD_API_NAMES.IsDeactivationRequested__c],
            [COD_API_NAMES.IsReactivationRequested__c]: cod[COD_API_NAMES.IsReactivationRequested__c],
            activationStatusIcon: 'standard:incident',
            negoScopeName: '',
            negoScopeLink: '',
            roleOutput: '',
            signatoryOutput: '',
            RequestedNegoScopeName: '',
            RequestedNegoScopeLink: '',
            RequestedRoleOutput: '',
            RequestedSignatoryOutput:'',
            isActive: cod[COD_API_NAMES.ActivationStatus__c] === 'Validated Entry',
            isDeactivated: cod[COD_API_NAMES.ActivationStatus__c] === 'Deactivated',
            showActions: (cod[COD_API_NAMES.ActivationStatus__c] !== 'Deactivated' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Deactivation' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Modification' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Reactivation'),
            isRequesting: false,
            newRequest: false,
            hasNegoscope: (this.isManager && (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.Negoscope__c])) || (this.isApproval && cod[COD_API_NAMES.RequestedNegoscope__c]),
            canActivate: ['Deactivated'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' && !this.isNonApproval),
            canDeactivate: ['Validated Entry'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation' && !this.isNonApproval),
            canDelete: ['Deactivated', 'In Preparation'].includes(cod[COD_API_NAMES.ActivationStatus__c]),
            canCancelReq: cod[COD_API_NAMES.IsDeactivationRequested__c] || cod[COD_API_NAMES.IsReactivationRequested__c] || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation',
            get _Negoscope__c() { return codWrap[COD_API_NAMES.Negoscope__c]; },
            get _ContactRole__c() { return codWrap[COD_API_NAMES.ContactRole__c]; },
            get _IsSignatory__c() { return codWrap[COD_API_NAMES.IsSignatory__c]; },
            get _IsInvoiceRecipient__c() { return codWrap[COD_API_NAMES.IsInvoiceRecipient__c]; },
            get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
            get _RequestedRole__c() { return codWrap[COD_API_NAMES.RequestedRole__c]; },
            get _RequestedSignatoryRole__c() { return codWrap[COD_API_NAMES.RequestedSignatoryRole__c]; },
            get _RequestedInvoiceRecipient__c() { return codWrap[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
            get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
            get _IsDeactivationRequested__c() { return codWrap[COD_API_NAMES.IsDeactivationRequested__c]; },
            get _IsReactivationRequested__c() { return codWrap[COD_API_NAMES.IsReactivationRequested__c]; },
        }
        //ONlY SHOW LINE IF IT HAS ANY ACTUAL DATA -- IF NOT JUST SHOW REQUEST ROW
        this.checkHasRequest(codWrap);
        //SET UP VALUES FOR DISPLAY
        codWrap.negoScopeName = cod[COD_API_NAMES.Negoscope__c.replace('__c', '__r')]?.Name;
        codWrap.negoScopeLink = '/' + cod[COD_API_NAMES.Negoscope__c];
        codWrap.RequestedNegoScopeName = cod[COD_API_NAMES.RequestedNegoscope__c.replace('__c', '__r')]?.Name;
        codWrap.RequestedNegoScopeLink = '/' + cod[COD_API_NAMES.RequestedNegoscope__c];
        codWrap.roleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c][codWrap[COD_API_NAMES.ContactRole__c]];
        codWrap.RequestedRoleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedRole__c][codWrap[COD_API_NAMES.RequestedRole__c]];
        codWrap.RequestedSignatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][codWrap[COD_API_NAMES.RequestedAccountingRole__c]];
        codWrap.signatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c][codWrap[COD_API_NAMES.SignatoryRole__c]];
        codWrap.activationStatusOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c][codWrap[COD_API_NAMES.ActivationStatus__c]];
        if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
            codWrap.activationStatusIcon = 'standard:incident';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
            codWrap.activationStatusIcon = 'standard:record_create';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
            codWrap.activationStatusIcon = 'standard:record_update';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
            codWrap.activationStatusIcon = 'standard:approval';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Deactivated') {
            codWrap.activationStatusIcon = 'standard:unmatched';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
            codWrap.activationStatusIcon = 'standard:resource_absence';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
            codWrap.activationStatusIcon = 'standard:resource_absence';
        }
        return codWrap;
    }

    disconnectedCallback() {
        if (this.cometdManager) {
            this.cometdManager.unsubscribe(COD_CHANNEL);
        }
    }

    renderedCallback() {
        this.adjustGridHeight();
    }

    setPageHeight() {
    }

    //LOAD
    initData() {
        try {
            this.isLoading = true;
            initData({
                supplierId: this.recordId,
            }).then((result) => {
                let parsedResult = JSON.parse(result);
                let connectSettings = parsedResult.connectSettings;
                this.summaryFields = [];
                this.headerFields = [];
                this.additionalFields = [];
                let selectedNonApprovalProfilesIds = [];
                let selectedApprovalProfilesIds = [];
                if (connectSettings.summaryFields) {
                    this.summaryFields = connectSettings.summaryFields;
                    let initCardHeight = 100;
                    if ((this.summaryFields?.length || 0) < 3) {
                        this.cardStyle = 'height: ' + (initCardHeight + (3 * 25)) + 'px';
                    } else {
                        this.cardStyle = 'height: ' + (initCardHeight + ((this.summaryFields?.length || 0) * 25)) + 'px';
                    }
                }
                if (connectSettings.cardHeaderFields) {
                    this.headerFields = connectSettings.cardHeaderFields;
                }
                if (connectSettings.additionalFields) {
                    this.additionalFields = connectSettings.additionalFields;
                }
                if (connectSettings.nonApprovalProfiles) {
                    selectedNonApprovalProfilesIds = connectSettings.nonApprovalProfiles;
                }
                if (connectSettings.approvalProfiles) {
                    selectedApprovalProfilesIds = connectSettings.approvalProfiles;
                }
                if (connectSettings.licenseQuotas) {
                    this.licenseQuota = connectSettings.licenseQuotas;
                }
                if (connectSettings.directoryManager) {
                    this.directoryManager = connectSettings.directoryManager;
                }
                this.connectSettings = connectSettings;
                //User Permission set id
                if (parsedResult.connectUserPermissionSetId != null) {
                    this.connectUserPermissionSetId = parsedResult.connectUserPermissionSetId;
                }
                this.defaultLanguageLocaleKey = parsedResult.defaultLanguageLocaleKey;
                this.defaultLocaleSidKey = parsedResult.defaultLocaleSidKey;
                this.fieldsMap = parsedResult.fieldsMap;
                this.setLabels();
                this.picklistLabelsMap = parsedResult.picklistLabelsMap;
                //SET OPTIONS
                this.setOptions();
                this.contactFields = [...new Set([...this.summaryFields, ...this.headerFields, ...this.additionalFields])];
                // Get the original object
                let CodActivationStatusLabels = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c];
                // Iterate through each key in the original object
                for (const key in CodActivationStatusLabels) {
                    if (CodActivationStatusLabels.hasOwnProperty(key)) {
                        // Remove spaces from the key
                        const modifiedKey = key.replace(/ /g, '');
                        // Add the modified key with the original value to the new object
                        this.CodActivationStatusLabels[modifiedKey] = CodActivationStatusLabels[key];
                    }
                }
                //SET ACCESS LEVEL
                this.currentUser = parsedResult.currentUser;
                let profileId = parsedResult.currentUser.ProfileId;
                let userId = parsedResult.currentUser.Id;
                let supplier = parsedResult.supplier;
                //TODO CHECK ORG PERMISSIONS TO SET CONTACT ON USER
                let isOrgAdmin = parsedResult.currentUser.ContactId ? parsedResult.currentUser.Contact?.[CONTACT_API_NAMES.IsOrgAdmin__c] : true;
                if (selectedNonApprovalProfilesIds.includes(profileId) && isOrgAdmin) {
                    this.isNonApproval = true;
                    this.allowAdd = true;
                    this.allowNewContact = true;
                    this.isManager = true;
                } else if (selectedApprovalProfilesIds.includes(profileId) && isOrgAdmin) {
                    this.isApproval = true;
                    this.allowAdd = true;
                    this.allowNewContact = true;
                } else {
                    this.isReadOnly = true;
                }
                supplier[SUPPLIER_API_NAMES.LicenseQuota__c] = supplier[SUPPLIER_API_NAMES.LicenseQuota__c] ?? 0;
                this.supplierLicenseQuota = supplier[SUPPLIER_API_NAMES.LicenseQuota__c];
                this.supplier = supplier;
                this.loadData();
            }).catch(error => {
                console.error(error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    setLabels() {
        this.labels.LBL_Activation_Status = this.fieldsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c].label;
        this.labels.LBL_Negoscopes = this.fieldsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.Negoscope__c].label;
        this.labels.LBL_Signatory_Role = this.fieldsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.IsSignatory__c].label;
        this.labels.LBL_Role = this.fieldsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c].label;
        this.labels.LBL_Invoice_Recipient = this.fieldsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.IsInvoiceRecipient__c].label;
        this.labels.LBL_FirstName = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.FirstName].label;
        this.labels.LBL_LastName = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.LastName].label;
        this.labels.LBL_Phone = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.Phone].label;
        this.labels.LBL_MobilePhone = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.MobilePhone].label;
        this.labels.LBL_OtherPhone = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.OtherPhone].label;
        this.labels.LBL_Email = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.Email].label;
        this.labels.LBL_Fax = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.Fax].label;
        this.labels.LBL_IsOrgAdmin__c = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.IsOrgAdmin__c].label;
        this.labels.LBL_ReportsToId = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.ReportsToId].label;
        this.labels.LBL_Salutation = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.Salutation].label;
        this.labels.LBL_Title = this.fieldsMap[Contact.objectApiName][CONTACT_API_NAMES.Title].label;

        this.labels.LBL_User_Name = this.fieldsMap[User.objectApiName][USER_API_NAMES.Name].label;
        this.labels.LBL_User_Title = this.fieldsMap[User.objectApiName][USER_API_NAMES.Title].label;
        this.labels.LBL_User_Email = this.fieldsMap[User.objectApiName][USER_API_NAMES.Email].label;
        this.labels.LBL_User_Phone = this.fieldsMap[User.objectApiName][USER_API_NAMES.Phone].label;
        this.labels.LBL_User_LanguageLocaleKey = this.fieldsMap[User.objectApiName][USER_API_NAMES.LanguageLocaleKey].label;
        this.labels.LBL_User_LocaleSidKey = this.fieldsMap[User.objectApiName][USER_API_NAMES.LocaleSidKey].label;
        this.labels.LBL_User_Username = this.fieldsMap[User.objectApiName][USER_API_NAMES.Username].label;
        this.labels.LBL_User_AccountId = this.fieldsMap[User.objectApiName][USER_API_NAMES.AccountId].label;
    }

    setOptions() {
        let roleOptions = []
        Object.keys(this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c]).forEach(option => {
            roleOptions.push({ value: option, label: this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c][option] })
        });
        roleOptions.sort((a, b) => a.label.localeCompare(b.label));
        this.roleOptions = roleOptions;

        let salutationOptions = [];
        Object.keys(this.picklistLabelsMap[Contact.objectApiName][COD_API_NAMES.Salutation]).forEach(option => {
            salutationOptions.push({ value: option, label: this.picklistLabelsMap[Contact.objectApiName][COD_API_NAMES.Salutation][option] })
        });
        this.salutationOptions = salutationOptions;

        let signatoryOptions = []
        Object.keys(this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c]).forEach(option => {
            signatoryOptions.push({ value: option, label: this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c][option]})
        });
        signatoryOptions.sort((a, b) => a.label.localeCompare(b.label));
        this.signatoryOptions = signatoryOptions;

        let reqAccountingRoleOptions = []
        Object.keys(this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c]).forEach(option => {
            reqAccountingRoleOptions.push({ value: option, label: this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][option]})
        });
        reqAccountingRoleOptions.sort((a, b) => a.label.localeCompare(b.label));
        this.reqAccountingRoleOptions = reqAccountingRoleOptions;
    }

    loadData() {
        this.processing = true;
        loadData({
            contactFields: this.contactFields,
            supplierId: this.recordId,
            filterMode: 'All',
            searchTerm: this.searchTerm
        }).then((result) => {
            let parsedResult = JSON.parse(result);
            this.afterLoad(parsedResult);
            this.processing = false;
            if (!this.isPageLoaded) {
                this.isPageLoaded = true;
                if (this.queuedSearch) {
                    this.loadData();
                    this.queuedSearch = null;
                }
            }
        }).catch(error => {
            console.error(error);
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.processing = false;
        });
    }

    afterLoad(dataWrapper) {
        try {
            this.contactToUserMap = dataWrapper.contactToUserMap;
            let contactList = [];
            this.isEmpty = dataWrapper.contactList.length === 0;
            if (this.isEmpty) {
                this.contactList = contactList;
                this.isLoading = false;
                return;
            }

            // Backup the original contact list
            this.contactsBackupList = dataWrapper.contactList;

            // Process the contact list
            for (let contact of dataWrapper.contactList) {
                let codList = dataWrapper.contactToCodMap[contact.Id];
                let contactInfo = this.fillContactInfo(contact, codList);
                contactList.push(contactInfo);
            }

            // Refresh the current contact
            if (this.contact.id != null) {
                contactList.forEach(contact => {
                    if (this.contact.id === contact.id) {
                        this.contact = contact;
                    }
                });
            }
            // Apply Filter based on `isActivated` field
            if (this.filterMode === 'Inactive') {
                contactList = contactList.filter(contact => !contact.isActivated);
            } else if (this.filterMode === 'Active') {
                contactList = contactList.filter(contact => contact.isActivated);
            }

            // Assign the filtered contact list
            this.contactList = contactList;
            if (this.isEditMode) {
                // this.isEditMode = false;
                if (this.contact.type == 'Individual') {
                    this.contact.codWrapList.forEach(element => {
                        // element.isEdit = false;
                        this.checkHasRequest(element);
                        element.isRequesting = false;
                        // element.newRequest = false;
                    });
                }
            }
            if (this.contact.type == 'Individual') {
                if (this.contact?.addedCodIdList?.length) {
                    // Remove items from this.contact.codWrapList array that match any ID in addedCodIdList
                    this.contact.codWrapList = this.contact.codWrapList.filter(
                        cod => !this.contact.addedCodIdList.includes(cod.id) // Replace `cod.id` with the correct property
                    );
                    this.contact.addedCodIdList = [];
                    this.isEditMode = false;
                }
                if (this.contact?.requestedCodIdList?.length) {
                    // Remove items from this.contact.inPreparationCods array that match any ID in requestedCodIdList
                    this.contact.inPreparationCods = this.contact.inPreparationCods.filter(
                        cod => !this.contact.requestedCodIdList.includes(cod.id) // Replace `cod.id` with the correct property
                    );
                    this.contact.requestedCodIdList = [];
                    this.isEditMode = false;
                }
                this.contact.hasinPreparationCods = this.contact?.inPreparationCods?.length ? true : false;
            }

            let contactIndex;
            let i;
            for (i = 0; i < (this.contactList?.length || 0); i++) {
                if (this.contactList[i].id === this.contact.id) {
                    contactIndex = i;
                }
            }
            this.contactList[contactIndex] = { ...this.contact };
            this.contactList = [...this.contactList];
            this.changesMap = {};
            this.isLoading = false;
            contactIndex = this.contactList.findIndex(item => item.name === this.selectedContactName || '');
            if (this.selectedContactName && this.selectedContactName != '' && contactIndex >= 0) {
                contactIndex = this.contactList.findIndex(item => item.name === this.selectedContactName);
                const event = {
                    target: {
                        dataset: {
                            index: contactIndex
                        }
                    }
                }
                this.openContactPanel(event);
            }
        } catch (error) {
            console.log('%c' + (error.message ? error.message : error.body?.message));
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    checkHasRequest(codWrap) {
        codWrap.hasRequest = (this.isApproval || this.isManager) && (
            codWrap[COD_API_NAMES.RequestedSignatoryRole__c] != codWrap[COD_API_NAMES.IsSignatory__c]
            || codWrap[COD_API_NAMES.RequestedInvoiceRecipient__c] != codWrap[COD_API_NAMES.IsInvoiceRecipient__c]
            || (codWrap[COD_API_NAMES.RequestedNegoscope__c] != null && codWrap[COD_API_NAMES.RequestedNegoscope__c] != codWrap[COD_API_NAMES.Negoscope__c])
            || (codWrap[COD_API_NAMES.RequestedRole__c] != null && codWrap[COD_API_NAMES.RequestedRole__c] != codWrap[COD_API_NAMES.ContactRole__c])
            || (codWrap[COD_API_NAMES.RequestedAccountingRole__c] != null && codWrap[COD_API_NAMES.RequestedAccountingRole__c] != codWrap[COD_API_NAMES.SignatoryRole__c]))
            && (['Requested Modification', 'In Preparation'].includes(codWrap[COD_API_NAMES.ActivationStatus__c]))
    }

    checkActualFields(codWrap) {
        return codWrap[COD_API_NAMES.Negoscope__c] != null || codWrap[COD_API_NAMES.ContactRole__c] != null || codWrap[COD_API_NAMES.IsSignatory__c] || codWrap[COD_API_NAMES.IsInvoiceRecipient__c] || codWrap[COD_API_NAMES.SignatoryRole__c] != null;
    }

    resetPassword() {

    }

    fillContactInfo(contact, codList) {
        try {
            let codWrapList = [];
            let newRequestsList = [];
            let inprepCods = [];
            let validatedCods = [];
            let reqCods = [];
            if (contact[CONTACT_API_NAMES.Type__c] === 'Individual') {
                codList.forEach(cod => {
                    let codWrap = {
                        Id: cod.Id,
                        id: cod.Id,
                        [COD_API_NAMES.ActivationStatus__c]: cod[COD_API_NAMES.ActivationStatus__c],
                        [COD_API_NAMES.Supplier__c]: this.supplier.Id,
                        [COD_API_NAMES.Negoscope__c]: cod[COD_API_NAMES.Negoscope__c],
                        [COD_API_NAMES.ContactRole__c]: cod[COD_API_NAMES.ContactRole__c],
                        [COD_API_NAMES.IsSignatory__c]: cod[COD_API_NAMES.IsSignatory__c],
                        [COD_API_NAMES.SignatoryRole__c]: cod[COD_API_NAMES.SignatoryRole__c],
                        [COD_API_NAMES.IsInvoiceRecipient__c]: cod[COD_API_NAMES.IsInvoiceRecipient__c],
                        [COD_API_NAMES.RequestedSignatoryRole__c]: cod[COD_API_NAMES.RequestedSignatoryRole__c],
                        [COD_API_NAMES.RequestedInvoiceRecipient__c]: cod[COD_API_NAMES.RequestedInvoiceRecipient__c],
                        [COD_API_NAMES.RequestedNegoscope__c]: cod[COD_API_NAMES.RequestedNegoscope__c],
                        [COD_API_NAMES.RequestedRole__c]: cod[COD_API_NAMES.RequestedRole__c],
                        [COD_API_NAMES.RequestedAccountingRole__c]: cod[COD_API_NAMES.RequestedAccountingRole__c],
                        [COD_API_NAMES.IsDeactivationRequested__c]: cod[COD_API_NAMES.IsDeactivationRequested__c],
                        [COD_API_NAMES.IsReactivationRequested__c]: cod[COD_API_NAMES.IsReactivationRequested__c],
                        activationStatusIcon: 'standard:incident',
                        negoScopeName: '',
                        negoScopeLink: '',
                        roleOutput: '',
                        signatoryOutput: '',
                        RequestedNegoScopeName: '',
                        RequestedNegoScopeLink: '',
                        RequestedRoleOutput: '',
                        RequestedSignatoryOutput: '',
                        isActive: cod[COD_API_NAMES.ActivationStatus__c] === 'Validated Entry',
                        isDeactivated: cod[COD_API_NAMES.ActivationStatus__c] === 'Deactivated',
                        showActions: (cod[COD_API_NAMES.ActivationStatus__c] !== 'Deactivated' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Deactivation' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Modification' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Reactivation'),
                        isRequesting: false,
                        newRequest: false,
                        hasNegoscope: (this.isManager && (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.Negoscope__c])) || (this.isApproval && cod[COD_API_NAMES.RequestedNegoscope__c]),
                        canActivate: ['Deactivated'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' && !this.isNonApproval),
                        canDeactivate: ['Validated Entry'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation' && !this.isNonApproval),
                        canDelete: ['Deactivated', 'In Preparation'].includes(cod[COD_API_NAMES.ActivationStatus__c]),
                        canCancelReq: cod[COD_API_NAMES.IsDeactivationRequested__c] || cod[COD_API_NAMES.IsReactivationRequested__c] || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation',
                        get _Negoscope__c() { return codWrap[COD_API_NAMES.Negoscope__c]; },
                        get _ContactRole__c() { return codWrap[COD_API_NAMES.ContactRole__c]; },
                        get _IsSignatory__c() { return codWrap[COD_API_NAMES.IsSignatory__c]; },
                        get _IsInvoiceRecipient__c() { return codWrap[COD_API_NAMES.IsInvoiceRecipient__c]; },
                        get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                        get _RequestedRole__c() { return codWrap[COD_API_NAMES.RequestedRole__c]; },
                        get _RequestedSignatoryRole__c() { return codWrap[COD_API_NAMES.RequestedSignatoryRole__c]; },
                        get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                        get _RequestedInvoiceRecipient__c() { return codWrap[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                        get _IsDeactivationRequested__c() { return codWrap[COD_API_NAMES.IsDeactivationRequested__c]; },
                        get _IsReactivationRequested__c() { return codWrap[COD_API_NAMES.IsReactivationRequested__c]; },
                    }
                    //ONlY SHOW LINE IF IT HAS ANY ACTUAL DATA -- IF NOT JUST SHOW REQUEST ROW
                    this.checkHasRequest(codWrap);
                    //SET UP VALUES FOR DISPLAY
                    codWrap.negoScopeName = cod[COD_API_NAMES.Negoscope__c.replace('__c', '__r')]?.Name;
                    codWrap.negoScopeLink = '/' + cod[COD_API_NAMES.Negoscope__c];
                    codWrap.RequestedNegoScopeName = cod[COD_API_NAMES.RequestedNegoscope__c.replace('__c', '__r')]?.Name;
                    codWrap.RequestedNegoScopeLink = '/' + cod[COD_API_NAMES.RequestedNegoscope__c];
                    codWrap.roleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c][codWrap[COD_API_NAMES.ContactRole__c]];
                    codWrap.RequestedRoleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedRole__c][codWrap[COD_API_NAMES.RequestedRole__c]];
                    codWrap.RequestedSignatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][codWrap[COD_API_NAMES.RequestedAccountingRole__c]];
                    codWrap.signatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c][codWrap[COD_API_NAMES.SignatoryRole__c]];
                    codWrap.activationStatusOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c][codWrap[COD_API_NAMES.ActivationStatus__c]];
                    if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
                        codWrap.activationStatusIcon = 'standard:incident';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                        codWrap.activationStatusIcon = 'standard:record_create';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                        codWrap.activationStatusIcon = 'standard:record_update';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
                        codWrap.activationStatusIcon = 'standard:approval';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Deactivated') {
                        codWrap.activationStatusIcon = 'standard:unmatched';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
                        codWrap.activationStatusIcon = 'standard:resource_absence';
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
                        codWrap.activationStatusIcon = 'standard:resource_absence';
                    }
                    if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
                        //ak placeholder
                        if (codWrap.hasRequest) {
                            inprepCods.push({ ...codWrap, readOnly: true });
                        }
                    } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
                        validatedCods.push(codWrap)
                    }
                    else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                        reqCods.push(codWrap)
                    }
                    if (this.checkActualFields(codWrap)) {
                        codWrapList.push(codWrap);
                    } else {
                        newRequestsList.push(codWrap);
                    }
                });
            }
            let imageUrlProfile;
            if (contact.PhotoUrl && !contact.PhotoUrl.includes('/services/images/photo/')) {
                imageUrlProfile = contact.PhotoUrl;
            } else {
                if (contact[CONTACT_API_NAMES.Type__c] === 'Generic mailbox') {
                    imageUrlProfile = icons.mailboxIcon;
                }
                else {
                    imageUrlProfile = MALE_PHOTO;
                    if (contact.hasOwnProperty('Salutation') && (contact.Salutation === 'Ms.' || contact.Salutation === 'Mrs.')) {
                        imageUrlProfile = FEMALE_PHOTO;
                    }
                }
            }
            let contactInfo = {
                id: contact.Id,
                Id: contact.Id,
                user: this.contactToUserMap[contact.Id],
                link: '/' + contact.Id,
                name: contact.Name,
                firstName: contact.FirstName,
                lastName: contact.LastName,
                [CONTACT_API_NAMES.Supplier__c]: contact[CONTACT_API_NAMES.Supplier__c],
                supplierAccount: contact[CONTACT_API_NAMES.Supplier__c.replace('__c', '__r')][SUPPLIER_API_NAMES.Account__c],
                title: contact.Title,
                fax: contact[CONTACT_API_NAMES.Fax],
                isInvoiceRecipient: contact[CONTACT_API_NAMES.IsInvoiceRecipient__c],
                [CONTACT_API_NAMES.IsOrgAdmin__c]: contact[CONTACT_API_NAMES.IsOrgAdmin__c],
                imageUrl: "background-image: url(" + imageUrlProfile + ");",
                email: contact.Email,
                isEmailVerified: (this.contactToUserMap[contact.Id] != null && this.contactToUserMap[contact.Id].Email == contact.Email) || this.contactToUserMap[contact.Id] == null,
                phone: contact.Phone,
                mobilePhone: contact.MobilePhone,
                summaryFields: [],
                headerFields: [],
                additionalFields: [],
                hasCod: true,
                codWrapList: codWrapList.sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName)),
                newRequestsList: newRequestsList.sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName)),
                hasNewRequests: newRequestsList.length > 0,
                isActivated: contact[CONTACT_API_NAMES.IsConnectUser__c],
                isRequested: contact[CONTACT_API_NAMES.IsConnectAccessRequested__c],
                editableFields: [],
                inPreparationCods: inprepCods.sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName)),
                validatedCods: validatedCods.sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName)),
                requestedCods: reqCods.sort((a, b) => (a.RequestedNegoScopeName || a.negoScopeName)?.localeCompare(b.RequestedNegoScopeName || b.negoScopeName)),
                hasinPreparationCods: inprepCods.length > 0,
                hasvalidatedCods: validatedCods.length > 0,
                hasrequestedCods: reqCods.length > 0,
                isMailbox: contact[CONTACT_API_NAMES.Type__c] == 'Generic mailbox',
                type: contact[CONTACT_API_NAMES.Type__c],
                requestedCodIdList: [],
                addedCodIdList: [],
            }
            let isFirst = true;
            if (this.summaryFields?.length) {
                for (let summaryField of this.summaryFields) {
                    contactInfo.summaryFields.push(this.buildFieldWrapper(contact, summaryField, isFirst));
                    isFirst = false;
                }
            }
            isFirst = true;
            contactInfo.editableFields.push(this.buildFieldWrapper(contact, 'FirstName', false));
            contactInfo.editableFields.push(this.buildFieldWrapper(contact, 'LastName', false));
            for (let headerField of this.headerFields) {
                contactInfo.headerFields.push(this.buildFieldWrapper(contact, headerField, isFirst));
                let foundIndex = contactInfo.editableFields.findIndex(element => element.fieldName === headerField);
                if (foundIndex === -1 && this.fieldsMap.Contact[headerField]?.updateable) {
                    contactInfo.editableFields.push(this.buildFieldWrapper(contact, headerField, isFirst));
                }
                isFirst = false;
            }
            for (let additionalField of this.additionalFields) {
                contactInfo.additionalFields.push(this.buildFieldWrapper(contact, additionalField, isFirst));
                let foundIndex = contactInfo.editableFields.findIndex(element => element.fieldName === additionalField);
                if (foundIndex === -1 && this.fieldsMap.Contact[additionalField]?.updateable) {
                    contactInfo.editableFields.push(this.buildFieldWrapper(contact, additionalField, isFirst));
                }
            }
            return contactInfo;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    fillCodInfo(cod, isNewRequest, withApproval, index, contact) {
        let codWrap = {
            id: cod.Id,
            Id: cod.Id,
            [COD_API_NAMES.ActivationStatus__c]: cod[COD_API_NAMES.ActivationStatus__c],
            [COD_API_NAMES.Supplier__c]: this.supplier.Id,
            [COD_API_NAMES.Negoscope__c]: cod[COD_API_NAMES.Negoscope__c],
            [COD_API_NAMES.ContactRole__c]: cod[COD_API_NAMES.ContactRole__c],
            [COD_API_NAMES.IsSignatory__c]: cod[COD_API_NAMES.IsSignatory__c],
            [COD_API_NAMES.SignatoryRole__c]: cod[COD_API_NAMES.SignatoryRole__c],
            [COD_API_NAMES.IsInvoiceRecipient__c]: cod[COD_API_NAMES.IsInvoiceRecipient__c],
            [COD_API_NAMES.RequestedSignatoryRole__c]: cod[COD_API_NAMES.RequestedSignatoryRole__c],
            [COD_API_NAMES.RequestedInvoiceRecipient__c]: cod[COD_API_NAMES.RequestedInvoiceRecipient__c],
            [COD_API_NAMES.RequestedNegoscope__c]: cod[COD_API_NAMES.RequestedNegoscope__c],
            [COD_API_NAMES.RequestedRole__c]: cod[COD_API_NAMES.RequestedRole__c],
            [COD_API_NAMES.RequestedAccountingRole__c]: cod[COD_API_NAMES.RequestedAccountingRole__c],
            [COD_API_NAMES.IsDeactivationRequested__c]: cod[COD_API_NAMES.IsDeactivationRequested__c],
            [COD_API_NAMES.IsReactivationRequested__c]: cod[COD_API_NAMES.IsReactivationRequested__c],
            activationStatusIcon: 'standard:incident',
            negoScopeName: '',
            negoScopeLink: '',
            roleOutput: '',
            signatoryOutput: '',
            RequestedNegoScopeName: '',
            RequestedNegoScopeLink: '',
            RequestedRoleOutput: '',
            RequestedSignatoryOutput: '',
            isActive: cod[COD_API_NAMES.ActivationStatus__c] === 'Validated Entry',
            showActions: (cod[COD_API_NAMES.ActivationStatus__c] !== 'Deactivated' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Deactivation' && cod[COD_API_NAMES.ActivationStatus__c] !== 'Requested Modification'),
            isRequesting: false,
            newRequest: false,
            readOnly: true,
            hasNegoscope: (this.isManager && (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.Negoscope__c])) || (this.isApproval && cod[COD_API_NAMES.RequestedNegoscope__c]),
            canActivate: ['Deactivated'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' && !this.isNonApproval),
            canDeactivate: ['Validated Entry'].includes(cod[COD_API_NAMES.ActivationStatus__c]) || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation' && !this.isNonApproval),
            canDelete: ['Deactivated', 'In Preparation'].includes(cod[COD_API_NAMES.ActivationStatus__c]),
            canCancelReq: cod[COD_API_NAMES.IsDeactivationRequested__c] || cod[COD_API_NAMES.IsReactivationRequested__c] || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation',
            get _Negoscope__c() { return codWrap[COD_API_NAMES.Negoscope__c]; },
            get _ContactRole__c() { return codWrap[COD_API_NAMES.ContactRole__c]; },
            get _IsSignatory__c() { return codWrap[COD_API_NAMES.IsSignatory__c]; },
            get _IsInvoiceRecipient__c() { return codWrap[COD_API_NAMES.IsInvoiceRecipient__c]; },
            get _RequestedRole__c() { return codWrap[COD_API_NAMES.RequestedRole__c]; },
            get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
            get _RequestedSignatoryRole__c() { return codWrap[COD_API_NAMES.RequestedSignatoryRole__c]; },
            get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
            get _RequestedInvoiceRecipient__c() { return codWrap[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
            get _IsDeactivationRequested__c() { return codWrap[COD_API_NAMES.IsDeactivationRequested__c]; },
            get _IsReactivationRequested__c() { return codWrap[COD_API_NAMES.IsReactivationRequested__c]; },

        }
        //ONlY SHOW LINE IF IT HAS ANY ACTUAL DATA -- IF NOT JUST SHOW REQUEST ROW
        this.checkHasRequest(codWrap);
        //SET UP VALUES FOR DISPLAY
        codWrap.negoScopeName = cod[COD_API_NAMES.Negoscope__r]?.[NS_API_NAMES.Name] || this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] || '';
        codWrap.negoScopeLink = '/' + cod[COD_API_NAMES.Negoscope__c];
        codWrap.RequestedNegoScopeName = cod[COD_API_NAMES.RequestedNegoscope__r]?.[NS_API_NAMES.Name] || this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] || '';
        codWrap.RequestedNegoScopeLink = '/' + cod[COD_API_NAMES.RequestedNegoscope__c];
        codWrap.roleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ContactRole__c][codWrap[COD_API_NAMES.ContactRole__c]];
        codWrap.RequestedRoleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedRole__c][codWrap[COD_API_NAMES.RequestedRole__c]];
        codWrap.RequestedSignatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][codWrap[COD_API_NAMES.RequestedAccountingRole__c]];
        codWrap.signatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.SignatoryRole__c][codWrap[COD_API_NAMES.SignatoryRole__c]];
        codWrap.activationStatusOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c][codWrap[COD_API_NAMES.ActivationStatus__c]];
        if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'In Preparation') {
            codWrap.activationStatusIcon = 'standard:incident';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
            codWrap.activationStatusIcon = 'standard:record_create';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
            codWrap.activationStatusIcon = 'standard:record_update';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Validated Entry') {
            codWrap.activationStatusIcon = 'standard:approval';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Deactivated') {
            codWrap.activationStatusIcon = 'standard:unmatched';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
            codWrap.activationStatusIcon = 'standard:resource_absence';
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
            codWrap.activationStatusIcon = 'standard:resource_absence';
        }
        //remove old cod
        if (isNewRequest) {
            if (!contact.requestedCods) {
                contact.requestedCods = [];
            }
            const listToModify = withApproval ? contact.inPreparationCods : contact.requestedCods;
            if (listToModify) {
                listToModify.splice(index, 1);
            }
        } else if (contact.codWrapList) {
            // Remove element from codWrapList
            contact.codWrapList.splice(index, 1);
        }
        this.checkHasRequest(codWrap);

        if (codWrap[COD_API_NAMES.ActivationStatus__c] === 'In Preparation') {
            if (!contact.inPreparationCods) {
                contact.inPreparationCods = [];
            }
            contact.inPreparationCods.splice(index, 0, codWrap); // Place at index in inPreparationCods
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] === 'Validated Entry') {
            if (!contact.validatedCods) {
                contact.validatedCods = [];
            }
            contact.validatedCods.splice(index, 0, codWrap); // Place at index in validatedCods
        } else if (codWrap[COD_API_NAMES.ActivationStatus__c] === 'Requested Creation') {
            if (!contact.requestedCods) {
                contact.requestedCods = [];
            }
            contact.requestedCods.splice(index, 0, codWrap); // Place at index in requestedCods
        }

        if (this.checkActualFields(codWrap)) {
            if (!contact.codWrapList) {
                contact.codWrapList = [];
            }
            isNewRequest ? contact.codWrapList.push(codWrap) : contact.codWrapList.splice(index, 0, codWrap);
        } else {
            if (!contact.newRequestsList) {
                contact.newRequestsList = [];
            }
            contact.newRequestsList.splice(index, 0, codWrap);
        }
    }

    buildFieldWrapper(contact, fieldName, isFirst) {
        let field = {
            isFirst: isFirst,
            fieldName: fieldName,
            fieldLabel: this.fieldsMap[Contact.objectApiName][fieldName].label,
            fieldValue: contact[fieldName],
            scale: this.fieldsMap[Contact.objectApiName][fieldName].scale,
            isEmail: this.fieldsMap[Contact.objectApiName][fieldName].type == 'email',
            isPhone: this.fieldsMap[Contact.objectApiName][fieldName].type == 'phone',
            isNumberField: this.fieldsMap[Contact.objectApiName][fieldName].type == 'number',
            isReference: this.fieldsMap[Contact.objectApiName][fieldName].type == 'reference',
            isDate: this.fieldsMap[Contact.objectApiName][fieldName].type == 'date' || this.fieldsMap[Contact.objectApiName][fieldName].type == 'datetime',
            isPicklist: this.fieldsMap[Contact.objectApiName][fieldName].type == 'picklist',
            isBoolean: this.fieldsMap[Contact.objectApiName][fieldName].type == 'boolean',
            isText: this.fieldsMap[Contact.objectApiName][fieldName].type == 'string',
            type: this.fieldsMap[Contact.objectApiName][fieldName].type,
            isRequired: !this.fieldsMap[Contact.objectApiName][fieldName].nillable && this.fieldsMap[Contact.objectApiName][fieldName].type != 'boolean' || fieldName == 'FirstName'
        }
        if (this.fieldsMap[Contact.objectApiName][fieldName].type == 'reference') {
            field.link = '/' + field.fieldValue;
            if (field.fieldName.endsWith('Id')) {
                let fieldName = field.fieldName.replace('Id', '');
                let output = contact[fieldName]?.Name;
                field.fieldValue = output;
            } else {
                field.fieldValue = contact[field.fieldName.replace('__c', '__r')]?.Name;
            }
            field.referenceTo = this.fieldsMap[Contact.objectApiName][fieldName].referenceTo[0];
            field.recordIdValue = contact[field.fieldName];
        }
        if (this.fieldsMap[Contact.objectApiName][fieldName].type == 'picklist') {
            field.fieldOutputValue = this.picklistLabelsMap['Contact'][field.fieldName][field.fieldValue];
            let options = [];
            for (let key in this.picklistLabelsMap['Contact'][fieldName]) {
                options.push({ label: key, value: this.picklistLabelsMap['Contact'][fieldName][key] })
            }
            field.fieldOptions = options;
        }
        return field;

    }
    //EVENT HANDLERS
    showContactPanel = false;
    showAddIndividualContact = false;
    get showSidePanel() {
        return this.showContactPanel || this.showAddIndividualContact || this.showContactTypePanel || this.showAddMailboxContact;
    }

    openContactPanel(event) {
        try {
            this.scrollToTop();
            this.changesMap = {};
            let contactIndex = event.target.dataset.index;
            this.contact = this.contactList[contactIndex];
            this.toggleContactPanel(event);
            // this.setPageHeight();
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    backToContactTypePanel() {
        this.showContactTypePanel = true;
        this.showContactPanel = false;
        this.showAddIndividualContact = false;
        this.showAddMailboxContact = false;
        this.contact = {};
    }

    handleNewContact() {
        this.showContactTypePanel = true;
        this.showContactPanel = false;
        this.showAddIndividualContact = false;
        this.showAddMailboxContact = false;
    }


    handleNewIndividualContact() {
        this.showAddIndividualContact = true;
        this.showContactPanel = false;
        this.showContactTypePanel = false;
        this.showAddMailboxContact = false;
        // this.refs?.tileContainer?.classList?.remove('slds-scrollable');
        let newContact = {
            hasCod: false,
            codWrapList: [],
            type: 'Individual',
            addedCodIdList: [],
            requestedCodIdList: []
        }
        this.contact = newContact;
    }

    handleNewMailboxContact() {
        this.showAddMailboxContact = true;
        this.showAddIndividualContact = false;
        this.showContactPanel = false;
        this.showContactTypePanel = false;
        // this.refs?.tileContainer?.classList?.remove('slds-scrollable');
        let newContact = {
            type: 'Generic mailbox'
        }
        this.contact = newContact;
    }

    handleContactTypeChoice(event) {
        if (event.target.dataset.contactType == "individual") {
            this.handleNewIndividualContact();
        } else {
            this.handleNewMailboxContact();
        }
    }

    toggleContactPanel() {
        try {
            if (this.showContactPanel) {
                this.closePanel();
            } else {
                this.showContactPanel = true;
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    closePanel() {
        this.selectedContactName = null;
        if (this.portalActivationPanel) {
            this.portalActivationPanel = false;
        }
        if (this.contactEditMode) {
            this.contactEditMode = false;
        }
        if (this.userInsertForm) {
            this.userInsertForm = false;
        }
        if (this.showUserNameValidationMsg) {
            this.showUserNameValidationMsg = false;
        }
        // this.refs.tileContainer.classList.add('slds-scrollable')
        if (this.isEditMode) {
            this.isEditMode = false;
            if (this.contact.type == 'Individual') {
                this.contact?.codWrapList?.forEach(element => {
                    element.isEdit = false;
                    this.checkHasRequest(element);
                    element.isRequesting = false;
                    // element.newRequest = false;
                });
            }
        }
        if (this.contact.type == 'Individual') {
            if (this.contact?.addedCodIdList?.length > 0) {
                // Remove items from this.contact.codWrapList array that match any ID in addedCodIdList
                this.contact.codWrapList = this.contact.codWrapList.filter(
                    cod => !this.contact.addedCodIdList.includes(cod.id) // Replace `cod.id` with the correct property
                );
                this.contact.addedCodIdList = [];
                this.isEditMode = false;
            }

            if (this.contact?.requestedCodIdList?.length > 0) {
                // Remove items from this.contact.inPreparationCods array that match any ID in requestedCodIdList
                this.contact.inPreparationCods = this.contact.inPreparationCods.filter(
                    cod => !this.contact.requestedCodIdList.includes(cod.id) // Replace `cod.id` with the correct property
                );
                this.contact.requestedCodIdList = [];
                this.isEditMode = false;
            }
            this.contact.hasinPreparationCods = this.contact?.inPreparationCods?.length ? true : false;
        }

        let contactIndex;
        let i;
        for (i = 0; i < (this.contactList?.length || 0); i++) {
            if (this.contactList[i].id === this.contact.id) {
                contactIndex = i;
            }
        }
        this.contactList[contactIndex] = { ...this.contact };
        this.contactList = [...this.contactList];
        // if (this.contact.originalCodWrapList) {
        //     this.contact.codWrapList = [...this.contact.originalCodWrapList];
        // }
        this.changesMap = {};
        this.showContactTypePanel = false;
        this.showContactPanel = false;
        this.showAddIndividualContact = false;
        this.showAddMailboxContact = false;
        this.portalActivationPanel = false;
        this.userInsertForm = false;
    }
    filterMode = 'All'
    toggleActive(event) {
        if (this.isLoading) return;
        let activeBtn = this.template.querySelector('.active-btn');
        if (this.filterMode == 'Active') {
            this.filterMode = 'All';
            activeBtn.style.backgroundColor = 'white';
            activeBtn.style.color = '#8cc58a';
        } else {
            this.filterMode = 'Active';
            activeBtn.style.backgroundColor = '#8cc58a';
            activeBtn.style.color = 'white';
            let inactiveBtn = this.template.querySelector('.inactive-btn');
            inactiveBtn.style.backgroundColor = 'white';
            inactiveBtn.style.color = '#ba0517';
        }
        this.loadData();
    }
    toggleInactive(event) {
        if (this.isLoading) return;
        let inactiveBtn = this.template.querySelector('.inactive-btn');
        if (this.filterMode == 'Inactive') {
            this.filterMode = 'All';
            inactiveBtn.style.backgroundColor = 'white';
            inactiveBtn.style.color = '#ba0517';
        } else {
            this.filterMode = 'Inactive';
            inactiveBtn.style.backgroundColor = '#ba0517';
            inactiveBtn.style.color = 'white';
            let activeBtn = this.template.querySelector('.active-btn');
            activeBtn.style.backgroundColor = 'white';
            activeBtn.style.color = '#8cc58a';
        }
        this.loadData();
    }

    portalActivationPanel = false;
    userInsertForm = false;
    togglePortalActivationScreen() {
        this.portalActivationPanel = !this.portalActivationPanel
    }

    handlePriorPortalActivation() {
        if (!this.processing && this.isManager) {
            if (this.currentUser.ContactId != this.contact.id) {
                if (this.contact.user) {
                    if (this.contact.isActivated || (!this.contact.isActivated && (!this.licenseQuota.activation || (this.licenseQuota.activation && this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c] > 0)))) {
                        if (this.contact.isActivated) {
                            this.confirmationPopUp = {
                                ...this.confirmationPopUp,
                                title: this.labels.LBL_Connect_Portal_Deactivation,
                                message: this.labels.MSG_Connect_Portal_Deactivation_Confirmation,
                                context: 'user',
                                action: this.confirmationPopupAction,
                                show: true
                            }
                        } else {
                            this.handlePortalActivation();
                        }
                    } else {
                        this.showNotification(this.labels.LBL_Warning, this.labels.MSG_Connect_License_Quota_Exceeded, 'warning');
                    }
                } else if (!this.licenseQuota.activation || (this.licenseQuota.activation && this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c] > 0)) {
                    this.userInsertForm = true;
                    this.user = {
                        attributes: {
                            'type': 'User'
                        },
                        Username: this.contact.email,
                        Alias: this.generateAlias(this.contact.firstName, this.contact.lastName),
                        LanguageLocaleKey: this.defaultLanguageLocaleKey,
                        LocaleSidKey: this.defaultLocaleSidKey
                    }
                } else {
                    this.showNotification(this.labels.LBL_Warning, this.labels.MSG_Connect_License_Quota_Exceeded, 'warning');
                }
            } else {
                this.showNotification(labels.LBL_Warning, labels.MSG_Connect_Cannot_Deactivate_Yourself, 'warning');
            }
        }
    }
    handlePortalActivation() {
        this.processing = true;
        let originalUser = { ...this.contact.user };
        let originalQuota = this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c];
        let userToUpsert = {
            attributes: {
                'type': 'User'
            },
            id: this.contact.user.Id,
        }
        let supplierToUpsert = {
            attributes: {
                'type': SUPPLIER_API_NAMES.Supplier__c
            },
            id: this.supplier.Id
        };
        let contactToUpsert = {
            attributes: {
                'type': 'Contact'
            },
            id: this.contact.id
        };
        //ACTIVATION
        let activating = this.contact.isActivated;
        userToUpsert[USER_API_NAMES.IsActive] = !activating;
        contactToUpsert[CONTACT_API_NAMES.IsConnectUser__c] = !activating;
        supplierToUpsert[SUPPLIER_API_NAMES.LicenseQuota__c] = activating ? (originalQuota + 1) : (originalQuota - 1);
        saveData({
            recordsToUpsertJSON: JSON.stringify([userToUpsert]),
            recordsToDeleteJSON: JSON.stringify([])
        }).then((result) => {
            let parsedResult = JSON.parse(result);
            if (parsedResult.errorMessage == 'SUCCESS') {
                saveData({
                    recordsToUpsertJSON: JSON.stringify([contactToUpsert, supplierToUpsert]),
                    recordsToDeleteJSON: null,
                }).then((result) => {
                    let callbackParsedResult = JSON.parse(result);
                    if (callbackParsedResult.errorMessage == 'SUCCESS') {
                        this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c] = activating ? (originalQuota + 1) : (originalQuota - 1);
                        this.supplierLicenseQuota = this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c];
                        this.supplier = {
                            ...this.supplier
                        }
                        let successMessage = activating ? this.labels.MSG_Connect_Portal_Access_Deactivated : this.labels.MSG_Connect_Portal_Access_Activated;
                        this.showNotification(this.labels.LBL_Success, successMessage, 'success');
                        this.contact.codWrapList.forEach(element => {
                            element.isEdit = false;
                        });
                        this.changesMap = {};
                        this.loadData();
                    } else {
                        saveData({
                            recordsToUpsertJSON: JSON.stringify([originalUser]),
                            recordsToDeleteJSON: null,
                        }).then(result => {
                            let rollbackParsedResult = JSON.parse(result);
                            if (rollbackParsedResult.errorMessage == 'SUCCESS') {
                                this.showNotification(this.labels.LBL_Error, this.labels.LBL_Connect_UserActivationFailed, 'error');
                                this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c] = originalQuota;
                                this.supplierLicenseQuota = this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c];
                                this.supplier = {
                                    ...this.supplier
                                }
                                this.contact.codWrapList.forEach(element => {
                                    element.isEdit = false;
                                });
                                this.changesMap = {};
                            } else {
                                this.showNotification(this.labels.LBL_Error, rollbackParsedResult.errorMessage, 'error', 'sticky');
                                this.processing = false;
                            }
                            this.loadData();
                        }).catch(error => {
                            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                            this.processing = false;
                            this.loadData();
                        });
                    }
                }).catch((error) => {
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                    this.processing = false;
                    this.loadData();
                });
            } else {
                this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error', 'sticky');
                this.processing = false;
                this.loadData();
            }
        }).catch(error => {
            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            this.processing = false;
            this.loadData();
        });

    }

    handleResetPassword() {
        if (this.isManager) {
            if (this.contact.user && this.contact.isActivated && !this.processing) {
                this.processing = true;
                resetPassword({ userId: this.contact.user.Id })
                    .then(() => {
                        this.showNotification(this.labels.LBL_Success, this.labels.MSG_Connect_Password_Reset_Confirmation, 'success');
                    })
                    .catch((error) => {
                        this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                    }).finally(() => {
                        this.processing = false;
                    });
            }
            if (!this.contact.isActivated) {
                this.showNotification(this.labels.LBL_Warning, this.labels.MSG_Connect_User_Must_Be_Active, 'warning');
            }
        }
    }

    handleEditUser(event) {
        try {
            let field = event.target.dataset.field;
            let value = event.target.value;
            this.user[field] = value;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleOnLoad(event) {
    }

    handleSaveUser(event) {
        if (!this.processing) {
            try {
                this.processing = true;
                event.preventDefault();
                let formFields = event.detail.fields;
                formFields.ProfileId = this.connectSettings.connectUserProfile;
                formFields.ContactId = this.contact.id;
                formFields.AccountId = this.contact.supplierAccount;
                formFields.FirstName = this.contact.firstName;
                formFields.LastName = this.contact.lastName;
                formFields.Email = this.contact.email;
                formFields.Title = this.contact.title;
                formFields.Alias = this.generateAlias(this.contact.firstName, this.contact.lastName);
                formFields.MobilePhone = this.contact.mobilePhone;
                formFields.Phone = this.contact.phone;
                this.user = { ...this.user, ...formFields };
                isUsernameTaken({
                    username: this.user.Username
                }).then(result => {
                    if (!result) {
                        this.showUserNameValidationMsg = false;
                        let groupMember;
                        if (this.connectSettings.connectUserGroup) {
                            let groupMember = {
                                attributes: {
                                    'type': 'GroupMember'
                                },
                                GroupId: this.connectSettings.connectUserGroup
                            }
                        }
                        saveUserData({
                            userJSON: JSON.stringify(this.user),
                            permissionSetGroupDeveloperName: this.connectSettings.connectUserPermissionSetGroup,
                            groupMemberJSON: groupMember ? JSON.stringify(groupMember) : null,
                        }).then((result) => {
                            let parsedResult = JSON.parse(result);
                            if (parsedResult.errorMessage == 'SUCCESS') {
                                this.contact.codWrapList.forEach(element => {
                                    element.isEdit = false;
                                });
                                this.changesMap = {};
                                try {
                                    let contactToUpsert = {
                                        attributes: {
                                            'type': 'Contact'
                                        },
                                        id: this.contact.id
                                    };
                                    contactToUpsert[CONTACT_API_NAMES.Username__c] = this.user.Username;
                                    contactToUpsert[CONTACT_API_NAMES.IsConnectUser__c] = true;
                                    let supplierToUpsert = {
                                        attributes: {
                                            'type': SUPPLIER_API_NAMES.Supplier__c
                                        },
                                        id: this.supplier.Id
                                    };
                                    supplierToUpsert[SUPPLIER_API_NAMES.LicenseQuota__c] = this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c] - 1;
                                    saveData({
                                        recordsToUpsertJSON: JSON.stringify([contactToUpsert, supplierToUpsert]),
                                        recordsToDeleteJSON: JSON.stringify([])
                                    }).then((result) => {
                                        let parsedResult = JSON.parse(result);
                                        if (parsedResult.errorMessage == 'SUCCESS') {
                                            this.showNotification(this.labels.LBL_Success, this.labels.MSG_Connect_Portal_Access_Activated, 'success');
                                            this.exitPortalActivation();
                                            this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c]--;
                                            this.supplierLicenseQuota = this.supplier[SUPPLIER_API_NAMES.LicenseQuota__c];
                                            this.supplier = { ...this.supplier };
                                        } else {
                                            if (parsedResult.errorMessage == "Error inserting user record: Insert failed. First exception on row 0; first error: LICENSE_LIMIT_EXCEEDED, License Limit Exceeded - Customer Community Plus: []")
                                                this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error', 'sticky');
                                        }
                                        this.loadData();
                                    }).catch(error => {
                                        this.processing = false;
                                        console.error(error);
                                        this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                                    });
                                } catch (error) {
                                    console.log('%c' + error.message ? error.message : error.body?.message);
                                    this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                                }
                            } else {
                                this.processing = false;
                                this.showNotification(this.labels.LBL_Error, parsedResult?.errorMessage || parsedResult, 'error', 'sticky');
                            }
                        }).catch(error => {
                            console.error(JSON.stringify(error));
                            this.processing = false;
                            this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                        });
                    }
                    else {
                        this.processing = false;
                        this.showUserNameValidationMsg = true;
                    }
                }).catch(error => {
                    this.processing = false;
                    this.showUserNameValidationMsg = false;
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                });
            } catch (error) {
                this.processing = false;
                console.log('%c' + error.message ? error.message : error.body?.message);
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            }
        }
    }
    exitPortalActivation() {
        this.userInsertForm = false;
        this.showUserNameValidationMsg = false;
        // this.changesMap = {};
    }

    searchContacts(event) {
        this.searchTerm = event.target.value;
        if (!this.isPageLoaded) {
            this.queuedSearch = this.searchTerm;
            return;
        }
        this.loadData();
    }

    get isSearchDisabled() {
        return !this.isPageLoaded;
    }

    //HANDLE COD EVENTS
    toggleEditMode(event) {
        try {
            let cod = this.contact.codWrapList[event.target.dataset.index];
            if (!cod.isEdit) {
                this.codBackupMap[cod.id] = { ...cod };
            } else {
                this.contact.codWrapList[event.target.dataset.index] = { ...this.codBackupMap[cod.id] };
                delete this.codBackupMap[cod.id];
            }
            cod.isEdit = !cod.isEdit;
            cod[COD_API_NAMES.Supplier__c] = this.contact[CONTACT_API_NAMES.Supplier__c];
            this.isEditMode = this.contact.codWrapList.some(cod => cod.isEdit);
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    changesMap = {};
    selectedCodId = '';

    handlePriorDeactivate(event) {
        let fieldType = event.target.dataset.fieldype;
        let withApproval = event.target.dataset.withApproval;
        this.selectedCodId = event.target.dataset.id || event.currentTarget.dataset.id;
        let isCodeDecativated;
        let isInPreparation = fieldType === "inPreparation";
        if (isInPreparation) {
            isCodeDecativated = this.contact.inPreparationCods.find(cod => cod.id === this.selectedCodId)[COD_API_NAMES.ActivationStatus__c] === 'Deactivated';
            if (isCodeDecativated) {
                this.showNotification(this.labels.LBL_Info, this.labels.LBL_Connect_CODDeactivationConfirmation, 'Info');
                return;
            }
        } else {
            isCodeDecativated = this.contact.codWrapList.find(cod => cod.id === this.selectedCodId)[COD_API_NAMES.ActivationStatus__c] === 'Requested Deactivation';
            if (isCodeDecativated) {
                this.showNotification(this.labels.LBL_Info, this.labels.LBL_Connect_RequestedDeactivationNotice, 'Info');
                return;
            }
        }
        if (withApproval) {
            this.handleDeactivate(isInPreparation)
        } else {
            this.confirmationPopUp = {
                ...this.confirmationPopUp,
                title: '',
                message: this.labels.MSG_Connect_Deactivation_Confirmation,
                context: 'cod' + (fieldType ? '-' + fieldType : ''),
                action: this.confirmationPopupAction,
                show: true
            };
        }
    }

    handleDeactivate(isInpreparation) {
        try {
            if (!this.processing) {
                this.processing = true;
                let index = -1;
                for (let i = 0; i < this.contact.codWrapList.length; i++) {
                    if (this.contact.codWrapList[i].id === this.selectedCodId) {
                        index = i;
                        break;
                    }
                }
                let inPreparationCod = this.contact.inPreparationCods.find(cod => cod.id == this.selectedCodId);
                if (!this.contact.requestedCods) {
                    this.contact.requestedCods = [];
                }
                let requestedCod = this.contact.requestedCods.find(cod => cod.id == this.selectedCodId);
                let codWrapListItem = this.contact.codWrapList.find(cod => cod.id == this.selectedCodId);
                let cod = inPreparationCod || requestedCod || codWrapListItem;
                if (cod) {
                    if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                        this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                    }
                    if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                        this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                    }
                    if (isInpreparation) {
                        cod[COD_API_NAMES.Negoscope__c] = cod[COD_API_NAMES.RequestedNegoscope__c];
                    }
                    if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                        cod.negoScopeName = cod.RequestedNegoScopeName || cod.negoScopeName;
                        cod.RequestedNegoScopeName = cod.RequestedNegoScopeName || cod.RequestedNegoScopeName;
                        cod[COD_API_NAMES.ContactRole__c] = cod[COD_API_NAMES.RequestedRole__c] || cod[COD_API_NAMES.ContactRole__c];
                        cod.roleOutput = cod.RequestedRoleOutput || cod.roleOutput;
                        cod[COD_API_NAMES.SignatoryRole__c] = cod[COD_API_NAMES.RequestedAccountingRole__c] || cod[COD_API_NAMES.SignatoryRole__c];
                        cod.signatoryOutput = cod.RequestedSignatoryOutput || cod.signatoryOutput;
                        cod[COD_API_NAMES.Negoscope__c] = cod[COD_API_NAMES.RequestedNegoscope__c] || cod[COD_API_NAMES.Negoscope__c];
                    }
                    cod[COD_API_NAMES.ActivationStatus__c] = this.isManager ? 'Deactivated' : this.isApproval ? 'Requested Deactivation' : null;
                    if (this.isApproval) {
                        cod[COD_API_NAMES.IsDeactivationRequested__c] = true;
                    } else {
                        cod[COD_API_NAMES.IsDeactivationRequested__c] = false;
                    }
                    //NORMALIZE IT FOR DML
                    let codToNormalize = cod;
                    let normalizedCod = this.normalizeCod(codToNormalize);
                    saveData({
                        recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                        recordsToDeleteJSON: JSON.stringify([])
                    }).then((result) => {
                        let parsedResult = JSON.parse(result);
                        if (parsedResult.errorMessage == 'SUCCESS') {
                            if (parsedResult.updatedRecords[0][COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
                                this.handleSendRequestNotification([parsedResult.updatedRecords[0].Id]);
                            }
                            this.fillCodInfo(parsedResult.updatedRecords[0], false, false, index, this.contact);
                            this.contact.requestedCods = [...this.contact.requestedCods];
                            this.contact.hasrequestedCods = this.contact.requestedCods.length > 0;
                            if (inPreparationCod) {
                                this.contact.inPreparationCods = this.contact.inPreparationCods.filter(cod => cod.id != this.selectedCodId)
                            }
                            if (requestedCod) {
                                if (!this.contact.requestedCods) {
                                    this.contact.requestedCods = [];
                                }
                                this.contact.requestedCods = this.contact.requestedCods.filter(cod => cod.id != this.selectedCodId)
                            }
                            this.processing = false;
                        } else {
                            this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                            this.processing = false;
                        }
                    }).catch(error => {
                        this.processing = false;
                        console.error(error);
                        this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                    });
                }
            }
        } catch (error) {
            this.processing = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
        }
    }

    syncRequestedCod(updatedCod) {
        if (!this.contact.requestedCods) {
            this.contact.requestedCods = [];
        }
        const exists = this.contact.requestedCods.find(c =>
            c.Id === updatedCod.Id || c.id === updatedCod.id
        );
        if (!exists) {
            this.contact.requestedCods.push({
                ...updatedCod,
                isRequesting: false,
                newRequest: false,
                isEdit: false
            });
        }
        this.contact.codWrapList = this.contact.codWrapList.filter(c => c.id !== updatedCod.id && c.Id !== updatedCod.Id);
        this.contact.inPreparationCods = this.contact.inPreparationCods.filter(c => c.id !== updatedCod.id && c.Id !== updatedCod.Id);
        this.contact.hasrequestedCods = this.contact.requestedCods.length > 0;
        this.contact = { ...this.contact };
    }

    handleActivate(event) {
        try {
            if (!this.processing) {
                this.processing = true;
                //GET THE REQUEST
                let index = event.target.dataset.index;
                let id = event.target.dataset.id || event.currentTarget.dataset.id;
                let cod = this.contact.codWrapList.find(cod => cod.id === id);
                if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
                    this.showNotification(this.labels.LBL_Info, this.labels.LBL_Connect_RequestedReactivationNotice, 'Info');
                    this.processing = false;
                    return;
                }
                if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                }
                if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                }
                // modify
                cod[COD_API_NAMES.ActivationStatus__c] = 'Validated Entry';
                if (cod[COD_API_NAMES.IsDeactivationRequested__c]) {
                    cod[COD_API_NAMES.IsDeactivationRequested__c] = false;
                }
                if (this.isApproval) {
                    cod[COD_API_NAMES.IsReactivationRequested__c] = true;
                    cod[COD_API_NAMES.ActivationStatus__c] = 'Requested Reactivation';
                } else {
                    cod[COD_API_NAMES.IsReactivationRequested__c] = false;
                }

                //NORMALIZE IT FOR DML
                let codToNormalize = cod;
                let normalizedCod = this.normalizeCod(codToNormalize);
                saveData({
                    recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                    recordsToDeleteJSON: JSON.stringify([])
                }).then((result) => {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.errorMessage == 'SUCCESS') {
                        // Remove the item
                        delete this.changesMap[event.target.dataset.index];
                        // Reassign to a new object to force reactivity
                        this.changesMap = { ...this.changesMap };
                        this.fillCodInfo(parsedResult.updatedRecords[0], false, false, index, this.contact);
                        this.contact.requestedCods = [...this.contact.requestedCods];
                        this.contact.hasrequestedCods = this.contact.requestedCods.length > 0;
                        this.contact = { ...this.contact };
                        this.contactList = [...this.contactList];
                        this.processing = false;
                    } else {
                        this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                        this.processing = false;
                    }
                }).catch(error => {
                    this.processing = false;
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
            }
        } catch (error) {
            this.processing = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
        }
    }

    handleValidateRequest(event) {
        if (!this.processing) {
            try {
                this.processing = true;
                let isNewRequest = event.target.dataset.newRequest;
                let cod;
                let index = event.target.dataset.index;
                if (isNewRequest) {
                    if (!this.contact.requestedCods) {
                        this.contact.requestedCods = [];
                    }
                    cod = this.contact.requestedCods[index]
                } else {
                    cod = this.contact.codWrapList[index]
                }
                let newCod = {
                    id: cod.id,
                    Id: cod.Id,
                    get _Negoscope__c() { return newCod[COD_API_NAMES.Negoscope__c]; },
                    get _ContactRole__c() { return newCod[COD_API_NAMES.ContactRole__c]; },
                    get _IsSignatory__c() { return newCod[COD_API_NAMES.IsSignatory__c]; },
                    get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                    get _IsInvoiceRecipient__c() { return newCod[COD_API_NAMES.IsInvoiceRecipient__c]; },
                    get _RequestedRole__c() { return newCod[COD_API_NAMES.RequestedRole__c]; },
                    get _RequestedSignatoryRole__c() { return newCod[COD_API_NAMES.RequestedSignatoryRole__c]; },
                    get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                    get _RequestedInvoiceRecipient__c() { return newCod[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                    get _IsDeactivationRequested__c() { return newCod[COD_API_NAMES.IsDeactivationRequested__c]; },
                    get _IsReactivationRequested__c() { return newCod[COD_API_NAMES.IsReactivationRequested__c]; },
                }
                if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                }
                if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                }

                if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation') {
                    newCod[COD_API_NAMES.ActivationStatus__c] = !cod[COD_API_NAMES.IsDeactivationRequested__c] ? 'Validated Entry' : 'Deactivated';
                } else if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation') {
                    newCod[COD_API_NAMES.ActivationStatus__c] = !cod[COD_API_NAMES.IsDeactivationRequested__c] ? 'Validated Entry' : 'Deactivated';
                } else {
                    newCod[COD_API_NAMES.ActivationStatus__c] = 'Validated Entry';
                }
                newCod[COD_API_NAMES.IsDeactivationRequested__c] = false;
                newCod[COD_API_NAMES.IsReactivationRequested__c] = false;
                newCod[COD_API_NAMES.Negoscope__c] = cod[COD_API_NAMES.RequestedNegoscope__c];
                newCod[COD_API_NAMES.ContactRole__c] = cod[COD_API_NAMES.RequestedRole__c];
                newCod[COD_API_NAMES.SignatoryRole__c] = cod[COD_API_NAMES.RequestedAccountingRole__c];
                newCod[COD_API_NAMES.IsSignatory__c] = cod[COD_API_NAMES.RequestedSignatoryRole__c];
                newCod[COD_API_NAMES.IsInvoiceRecipient__c] = cod[COD_API_NAMES.RequestedInvoiceRecipient__c];
                this.clearRequest(newCod);
                this.changesMap[cod.id] = newCod;
                let normalizedCod = this.normalizeCod(this.changesMap[cod.id]);
                saveData({
                    recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                    recordsToDeleteJSON: JSON.stringify([])
                }).then((result) => {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.errorMessage == 'SUCCESS') {
                        // Remove the item
                        delete this.changesMap[event.target.dataset.index];
                        // Reassign to a new object to force reactivity
                        this.changesMap = { ...this.changesMap };
                        //REMOVE THE INPUTS
                        this.fillCodInfo(parsedResult.updatedRecords[0], isNewRequest, false, index, this.contact);
                        this.contact.requestedCods = [...this.contact.requestedCods];
                        this.contact.hasrequestedCods = this.contact.requestedCods.length > 0;
                        this.processing = false;
                    } else {
                        this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                        this.processing = false;
                    }
                }).catch(error => {
                    this.processing = false;
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
                // this.handleSaveCod();
            } catch (error) {
                this.processing = false;
                console.log('%c' + error.message ? error.message : error.body?.message);
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
            }
        }
    }

    clearRequest(newCod) {
        newCod[COD_API_NAMES.RequestedNegoscope__c] = newCod[COD_API_NAMES.Negoscope__c];
        newCod[COD_API_NAMES.RequestedRole__c] = newCod[COD_API_NAMES.ContactRole__c];
        newCod[COD_API_NAMES.RequestedAccountingRole__c] = newCod[COD_API_NAMES.SignatoryRole__c];
        newCod[COD_API_NAMES.RequestedSignatoryRole__c] = newCod[COD_API_NAMES.IsSignatory__c];
        newCod[COD_API_NAMES.RequestedInvoiceRecipient__c] = newCod[COD_API_NAMES.IsInvoiceRecipient__c];
        newCod.hasRequest = false;
    }

    handleRejectRequest(event) {
        if (!this.processing) {
            try {
                this.processing = true;
                let index = event.target.dataset.index;
                let isNewRequest = event.target.dataset.newRequest;
                let cancel = event.target.dataset.cancel;
                let cod;
                if (isNewRequest) {
                    if (!this.contact.requestedCods) {
                        this.contact.requestedCods = [];
                    }
                    cod = this.contact.requestedCods[index];
                } else {
                    cod = this.contact.codWrapList[index];
                }
                let newCod = {
                    id: cod.id,
                    Id: cod.Id,
                    ...cod,
                    get _Negoscope__c() { return newCod[COD_API_NAMES.Negoscope__c]; },
                    get _ContactRole__c() { return newCod[COD_API_NAMES.ContactRole__c]; },
                    get _IsSignatory__c() { return newCod[COD_API_NAMES.IsSignatory__c]; },
                    get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                    get _IsInvoiceRecipient__c() { return newCod[COD_API_NAMES.IsInvoiceRecipient__c]; },
                    get _RequestedRole__c() { return newCod[COD_API_NAMES.RequestedRole__c]; },
                    get _RequestedSignatoryRole__c() { return newCod[COD_API_NAMES.RequestedSignatoryRole__c]; },
                    get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                    get _RequestedInvoiceRecipient__c() { return newCod[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                    get _IsDeactivationRequested__c() { return newCod[COD_API_NAMES.IsDeactivationRequested__c]; },
                    get _IsReactivationRequested__c() { return newCod[COD_API_NAMES.IsReactivationRequested__c]; },
                }
                if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                }
                if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                }
                if (isNewRequest) {
                    newCod = {
                        id: cod.id,
                        Id: cod.Id,
                        get _Negoscope__c() { return newCod[COD_API_NAMES.Negoscope__c]; },
                        get _ContactRole__c() { return newCod[COD_API_NAMES.ContactRole__c]; },
                        get _IsSignatory__c() { return newCod[COD_API_NAMES.IsSignatory__c]; },
                        get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
                        get _IsInvoiceRecipient__c() { return newCod[COD_API_NAMES.IsInvoiceRecipient__c]; },
                        get _RequestedRole__c() { return newCod[COD_API_NAMES.RequestedRole__c]; },
                        get _RequestedSignatoryRole__c() { return newCod[COD_API_NAMES.RequestedSignatoryRole__c]; },
                        get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
                        get _RequestedInvoiceRecipient__c() { return newCod[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
                        get _IsDeactivationRequested__c() { return newCod[COD_API_NAMES.IsDeactivationRequested__c]; },
                        get _IsReactivationRequested__c() { return newCod[COD_API_NAMES.IsReactivationRequested__c]; },
                    }
                }
                if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Deactivation' || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                    newCod[COD_API_NAMES.ActivationStatus__c] = 'Validated Entry';
                    newCod[COD_API_NAMES.Negoscope__c] = cod[COD_API_NAMES.Negoscope__c];
                    newCod[COD_API_NAMES.ContactRole__c] = cod[COD_API_NAMES.ContactRole__c];
                    newCod[COD_API_NAMES.SignatoryRole__c] = cod[COD_API_NAMES.SignatoryRole__c];
                    newCod[COD_API_NAMES.IsSignatory__c] = cod[COD_API_NAMES.IsSignatory__c];
                    newCod[COD_API_NAMES.IsInvoiceRecipient__c] = cod[COD_API_NAMES.IsInvoiceRecipient__c];
                    this.clearRequest(newCod);
                } else if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' || cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation') {
                    let isCreation = cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation';
                    if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Reactivation' || (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' && !cancel)) {
                        newCod[COD_API_NAMES.ActivationStatus__c] = 'Deactivated';
                        newCod.negoScopeName = isCreation ? cod.RequestedNegoScopeName : cod.negoScopeName;
                        newCod.RequestedNegoScopeName = isCreation ? cod.RequestedNegoScopeName : cod.RequestedNegoScopeName;
                        newCod[COD_API_NAMES.ContactRole__c] = isCreation ? cod[COD_API_NAMES.RequestedRole__c] : cod[COD_API_NAMES.ContactRole__c] || cod[COD_API_NAMES.RequestedRole__c];
                        newCod[COD_API_NAMES.RequestedRole__c] = isCreation ? cod[COD_API_NAMES.RequestedRole__c] : cod[COD_API_NAMES.RequestedRole__c];
                        newCod[COD_API_NAMES.SignatoryRole__c] = isCreation ? cod[COD_API_NAMES.RequestedAccountingRole__c] : cod[COD_API_NAMES.SignatoryRole__c] || cod[COD_API_NAMES.RequestedAccountingRole__c];
                        newCod[COD_API_NAMES.RequestedAccountingRole__c] = isCreation ? cod[COD_API_NAMES.RequestedAccountingRole__c] : cod[COD_API_NAMES.RequestedAccountingRole__c];
                        newCod.roleOutput = isCreation ? cod.RequestedRoleOutput : cod.roleOutput || cod.RequestedRoleOutput;
                        newCod.signatoryOutput = isCreation ? cod.RequestedSignatoryOutput : cod.signatoryOutput || cod.RequestedSignatoryOutput;
                        newCod.RequestedRoleOutput = isCreation ? cod.RequestedRoleOutput : cod.RequestedRoleOutput;
                        newCod.RequestedSignatoryOutput = isCreation ? cod.RequestedSignatoryOutput : cod.RequestedSignatoryOutput;
                        newCod[COD_API_NAMES.Negoscope__c] = isCreation ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.Negoscope__c] || cod[COD_API_NAMES.RequestedNegoscope__c];
                        newCod[COD_API_NAMES.RequestedNegoscope__c] = isCreation ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.RequestedNegoscope__c];
                        newCod[COD_API_NAMES.IsSignatory__c] = isCreation ? cod[COD_API_NAMES.IsSignatory__c] : cod[COD_API_NAMES.IsSignatory__c];
                        newCod[COD_API_NAMES.IsInvoiceRecipient__c] = isCreation ? cod[COD_API_NAMES.IsInvoiceRecipient__c] : cod[COD_API_NAMES.IsInvoiceRecipient__c];
                        newCod[COD_API_NAMES.IsSignatory__c] = isCreation ? cod[COD_API_NAMES.RequestedSignatoryRole__c] : cod[COD_API_NAMES.RequestedSignatoryRole__c];
                        newCod[COD_API_NAMES.RequestedSignatoryRole__c] = isCreation ? cod[COD_API_NAMES.RequestedSignatoryRole__c] : cod[COD_API_NAMES.RequestedSignatoryRole__c];
                        newCod[COD_API_NAMES.IsInvoiceRecipient__c] = isCreation ? cod[COD_API_NAMES.RequestedInvoiceRecipient__c] : cod[COD_API_NAMES.RequestedInvoiceRecipient__c];
                        newCod[COD_API_NAMES.RequestedInvoiceRecipient__c] = isCreation ? cod[COD_API_NAMES.RequestedInvoiceRecipient__c] : cod[COD_API_NAMES.RequestedInvoiceRecipient__c];
                        this.clearRequest(newCod);
                    }
                    if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Creation' && cancel) {
                        newCod[COD_API_NAMES.ActivationStatus__c] = 'In Preparation';
                        newCod.RequestedNegoScopeName = isCreation ? cod.RequestedNegoScopeName : cod.RequestedNegoScopeName;
                        newCod[COD_API_NAMES.RequestedRole__c] = isCreation ? cod[COD_API_NAMES.RequestedRole__c] : cod[COD_API_NAMES.RequestedRole__c];
                        newCod[COD_API_NAMES.RequestedAccountingRole__c] = isCreation ? cod[COD_API_NAMES.RequestedAccountingRole__c] : cod[COD_API_NAMES.RequestedAccountingRole__c];
                        newCod.RequestedRoleOutput = isCreation ? cod.RequestedRoleOutput : cod.RequestedRoleOutput;
                        newCod.RequestedSignatoryOutput = isCreation ? cod.RequestedSignatoryOutput : cod.RequestedSignatoryOutput;
                        newCod[COD_API_NAMES.RequestedNegoscope__c] = isCreation ? cod[COD_API_NAMES.RequestedNegoscope__c] : cod[COD_API_NAMES.RequestedNegoscope__c];
                        newCod[COD_API_NAMES.RequestedInvoiceRecipient__c] = isCreation ? cod[COD_API_NAMES.RequestedInvoiceRecipient__c] : cod[COD_API_NAMES.RequestedInvoiceRecipient__c];
                        newCod[COD_API_NAMES.RequestedSignatoryRole__c] = isCreation ? cod[COD_API_NAMES.RequestedSignatoryRole__c] : cod[COD_API_NAMES.RequestedSignatoryRole__c];
                    }
                }
                newCod[COD_API_NAMES.IsDeactivationRequested__c] = false;
                newCod[COD_API_NAMES.IsReactivationRequested__c] = false;
                this.changesMap[cod.id] = newCod;
                let normalizedCod = this.normalizeCod(this.changesMap[cod.id]);
                saveData({
                    recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                    recordsToDeleteJSON: JSON.stringify([])
                }).then((result) => {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.errorMessage == 'SUCCESS') {
                        // Remove the item
                        delete this.changesMap[event.target.dataset.index];
                        // Reassign to a new object to force reactivity
                        this.changesMap = { ...this.changesMap };
                        //REMOVE THE INPUTS
                        this.fillCodInfo(parsedResult.updatedRecords[0], isNewRequest, false, index, this.contact);
                        this.contact.requestedCods = [...this.contact.requestedCods];
                        this.contact.hasrequestedCods = this.contact.requestedCods.length > 0;
                        this.processing = false;
                    } else {
                        this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                        this.processing = false;
                    }
                }).catch(error => {
                    this.processing = false;
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
                // this.handleSaveCod();
            } catch (error) {
                this.processing = false;
                console.log('%c' + error.message ? error.message : error.body?.message);
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
            }
        }
    }

    handleActivateEditContact(event) {
        this.contactEditMode = !this.contactEditMode;
        this.currentContact = this.contactsBackupList.find(el => el.Id === this.contact.id);
        if (this.contact.user) {
            this.user = {
                ...this.contact.user,
                LanguageLocaleKey: this.contact.user.LanguageLocaleKey || this.defaultLanguageLocaleKey,
                LocaleSidKey: this.contact.user.LocaleSidKey || this.defaultLocaleSidKey
            };
        }
    }

    handleEditContactInfos(event) {
        try {
            let fieldName = event.target.dataset.fieldname;
            let fieldType = event.target.dataset.fieldtype;
            let value;
            if (fieldType == 'boolean') {
                value = event.detail.checked;
            }
            else if (fieldType == 'reference') {
                value = event.detail.recordId ? event.detail.recordId : event.target.value;
            }
            else {
                value = event.target.value;
            }
            if (fieldName === this.USER_API_NAMES.LanguageLocaleKey || fieldName === this.USER_API_NAMES.LocaleSidKey) {
                if (!this.user) {
                    this.user = { ...this.contact.user };
                }
                this.user[fieldName] = value;
            } else {
                if (fieldName === this.CONTACT_API_NAMES.Email) {
                    this.user[this.USER_API_NAMES.Email] = value;
                }
                this.currentContact[fieldName] = value;
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }

    }
    handleSaveContactInfoEdit(event) {
        let self = this;
        try {
            let recordsToUpsert = [];
            let checkDuplication = false;
            recordsToUpsert.push(self.currentContact);
            let requiredFields = self.template.querySelectorAll('.info-input');
            //callback
            let callback = (parsedResult) => {
                let updatedContact = parsedResult.updatedRecords[0];
                if (self.currentUser.ContactId && self.currentUser.ContactId == updatedContact.Id) {
                    //TODO CHECK ORG PERMISSIONS TO SET CONTACT ON USER
                    let isOrgAdmin = updatedContact[CONTACT_API_NAMES.IsOrgAdmin__c];
                    self.allowAdd = false;
                    self.allowNewContact = false;
                    self.isManager = false;
                    self.isReadOnly = false;
                    if (self.isNonApproval && isOrgAdmin) {
                        self.allowAdd = true;
                        self.allowNewContact = true;
                        self.isManager = true;
                    } else if (self.isApproval && isOrgAdmin) {
                        self.allowAdd = true;
                        self.allowNewContact = true;
                    } else {
                        self.isReadOnly = true;
                    }
                }
                if (self.contact.isActivated && self.user) {
                    self.processing = false;
                    self.dmlHandler(self, [self.user], [], () => {
                        self.showNotification(self.labels.LBL_Success, self.labels.MSG_Successfully_Saved, 'success');
                        self.loadData();
                        self.contactEditMode = false;
                    }, null);
                } else {
                    self.contactEditMode = false;
                    self.loadData();
                }
            }

            let allValid = true;
            for (let field of requiredFields) {
                try {
                    if (!(field?.checkValidity())) {
                        field.reportValidity(); // Show error message for the specific field
                        allValid = false;
                        break; // Exit the loop immediately if a field is invalid
                    }
                } catch (error) {
                    allValid = false;
                    console.error(JSON.stringify(error))
                }
            }
            if (allValid) {
                self.contactEditMode = false;
                if (self.contact.firstName != self.currentContact.FirstName
                    || self.contact.lastName != self.currentContact.LastName
                    || self.contact.email != self.currentContact.Email) {
                    checkDuplication = true;
                }
                if (checkDuplication) {
                    self.processing = true;
                    checkContactDuplication({
                        supplierId: self.supplier.Id,
                        firstName: self.currentContact.FirstName,
                        lastName: self.currentContact.LastName,
                        email: self.currentContact.Email,
                    }).then((result) => {
                        self.processing = false;
                        if (result) {
                            self.showNotification(self.labels.LBL_Error, self.labels.MSG_Connect_Duplicate_Contact_Found, 'error');
                        } else if (allValid) {
                            self.processing = false;
                            self.dmlHandler(self, recordsToUpsert, [], callback, null);
                        }
                    }).catch(error => {
                        self.showNotification(self.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
                        self.processing = false;
                    });
                } else {
                    if (allValid) {
                        self.processing = false;
                        self.dmlHandler(self, recordsToUpsert, [], callback, null);
                        self.contactEditMode = false;
                    }
                }
            }
        } catch (error) {
            console.error(JSON.stringify(error));
        }
    }
    handleCancelContactInfoEdit(event) {
        this.contactEditMode = false;
    }
    handleInputChange(event) {
        const fieldName = event.target.name;
        const value = event.detail.value;

        if (fieldName === this.USER_API_NAMES.LanguageLocaleKey ||
            fieldName === this.USER_API_NAMES.LocaleSidKey) {

            if (!this.user) {
                this.user = { ...this.contact.user };
            }

            this.user[fieldName] = value;
        }
    }

    handleFieldEdits(event) {
        try {
            let field = event.target.dataset.field;
            let id = event.target.dataset.id;
            let value;
            if (field == COD_API_NAMES.RequestedSignatoryRole__c
                || field == COD_API_NAMES.IsSignatory__c
                || field == COD_API_NAMES.RequestedInvoiceRecipient__c
                || field == COD_API_NAMES.IsInvoiceRecipient__c
                ) {
                value = event.detail.checked;
            } else {
                value = event.target.value ?? event.detail.recordId
            }
            let cod;
            if (this.changesMap.hasOwnProperty(id)) {
                cod = this.changesMap[id];
            } else {
                cod = this.contact.codWrapList.find(item => item.id === id);
            }
            cod[field] = value;
            if (this.isManager) {
                if (field == COD_API_NAMES.ContactRole__c) {
                    cod[COD_API_NAMES.RequestedRole__c] = value;
                }
                if (field == COD_API_NAMES.IsSignatory__c) {
                    cod[COD_API_NAMES.RequestedSignatoryRole__c] = value;
                }
                if (field == COD_API_NAMES.IsInvoiceRecipient__c) {
                    cod[COD_API_NAMES.RequestedInvoiceRecipient__c] = value;
                }
                if (field == COD_API_NAMES.SignatoryRole__c) {
                    cod[COD_API_NAMES.RequestedAccountingRole__c] = value;
                }
            } else {
                if (field == COD_API_NAMES.RequestedRole__c) {
                    cod.RequestedRoleOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedRole__c][cod[COD_API_NAMES.RequestedRole__c]];
                }
                if (field == COD_API_NAMES.RequestedAccountingRole__c) {
                    cod.RequestedSignatoryOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.RequestedAccountingRole__c][cod[COD_API_NAMES.RequestedAccountingRole__c]];
                }
            }
            this.changesMap[id] = cod;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    newIterator = 0;
    initializeCod(requestValidation) {
        let inPreparationOutput = requestValidation ? this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c]['In Preparation']
            : this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c]['Validated Entry'];
        let cod = {
            id: this.newIterator,
            [COD_API_NAMES.ActivationStatus__c]: requestValidation ? 'In Preparation' : 'Validated Entry',
            [COD_API_NAMES.Supplier__c]: this.supplier.Id,
            isNew: true,
            activationStatusOutput: inPreparationOutput,
            activationStatusIcon: requestValidation ? 'standard:incident' : 'standard:approval',
            rowClass: 'newRow',
            isEmpty: true,
            readOnly: false,
            isEditable: true,
            get _Negoscope__c() { return cod[COD_API_NAMES.Negoscope__c]; },
            get _ContactRole__c() { return cod[COD_API_NAMES.ContactRole__c]; },
            get _IsSignatory__c() { return cod[COD_API_NAMES.IsSignatory__c]; },
            get _SignatoryRole__c() { return cod[COD_API_NAMES.SignatoryRole__c]; },
            get _IsInvoiceRecipient__c() { return cod[COD_API_NAMES.IsInvoiceRecipient__c]; },
            get _RequestedRole__c() { return cod[COD_API_NAMES.RequestedRole__c]; },
            get _RequestedSignatoryRole__c() { return cod[COD_API_NAMES.RequestedSignatoryRole__c]; },
            get _RequestedAccountingRole__c() { return cod[COD_API_NAMES.RequestedAccountingRole__c]; },
            get _RequestedInvoiceRecipient__c() { return cod[COD_API_NAMES.RequestedInvoiceRecipient__c]; },
            get _IsDeactivationRequested__c() { return cod[COD_API_NAMES.IsDeactivationRequested__c]; },
            get _IsReactivationRequested__c() { return cod[COD_API_NAMES.IsReactivationRequested__c]; },
        }
        cod[COD_API_NAMES.Contact__c] = this.contact.id;
        cod[COD_API_NAMES.Supplier__c] = this.contact[COD_API_NAMES.Supplier__c];
        this.changesMap[this.newIterator] = cod;
        this.newIterator++;
        return cod;
    }
    handleAddNewRequest(event) {
        let isrequest = event.target.dataset.isRequest;
        let cod = this.initializeCod(true);
        this.contact.hasUnsentRequests = true;
        this.contact.hasCod = true;
        this.contact.hasNewRequests = true;
        this.isEditMode = true;
        cod.isRequesting = true;
        cod.newRequest = true;
        cod.hasRequest = true;
        cod.showActions = true;
        cod.hasNegoscope = false;
        cod.RequestedNegoScopeName = '';
        // if (isrequest === "true") {
        //     this.changesMap = {};
        //     this.changesMap[cod.id] = cod;
        //     this.contact.inPreparationCods = [];
        // }
        if (isrequest === "true") {
            // this.changesMap = {};
            this.changesMap[cod.id] = cod;
            this.changesMap = { ...this.changesMap };
            if (!this.contact.inPreparationCods) {
                this.contact.inPreparationCods = [];
            }
        }
        this.contact.inPreparationCods.push(cod);
        this.contact.hasinPreparationCods = this.contact?.inPreparationCods?.length > 0;
        this.contact.requestedCodIdList.push(cod.id);
        this.contact = { ...this.contact }
    }

    handleEditRequestInPreperation(event) {
        const id = event.target.dataset.id || event.currentTarget.dataset.id;
        const isEditable = event.target.dataset.editable ? true : false;
        const targetCod = this.contact.inPreparationCods.find(cod => cod.id === id);
        if (targetCod) {
            this.isEditMode = isEditable;
            this.contact.inPreparationCods = this.contact.inPreparationCods.map(cod =>
                cod.id === id
                    ? { ...cod, readOnly: !isEditable, isEditable: isEditable }
                    : cod
            );
        }
    }

    handleEditInPreparationValue(event) {
        const id = event.target.dataset.id || event.currentTarget.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        const inPreparationCod = this.contact.inPreparationCods.find(cod => cod.id === id);
        inPreparationCod[field] = value;
        this.changesMap[id] = {
            attributes: {
                type: COD_API_NAMES.ContactOperationalDirectory__c
            },
            id: id,
            [COD_API_NAMES.ActivationStatus__c]: inPreparationCod[COD_API_NAMES.ActivationStatus__c],
            [COD_API_NAMES.Supplier__c]: inPreparationCod[COD_API_NAMES.Supplier__c],
            [COD_API_NAMES.Contact__c]: inPreparationCod[COD_API_NAMES.Contact__c],
            [COD_API_NAMES.OwnerId]: inPreparationCod[COD_API_NAMES.OwnerId],
            [COD_API_NAMES.RequestedNegoscope__c]: inPreparationCod[COD_API_NAMES.RequestedNegoscope__c],
            [COD_API_NAMES.RequestedRole__c]: inPreparationCod[COD_API_NAMES.RequestedRole__c],
            [COD_API_NAMES.RequestedSignatoryRole__c]: inPreparationCod[COD_API_NAMES.RequestedSignatoryRole__c],
            [COD_API_NAMES.RequestedInvoiceRecipient__c]: inPreparationCod[COD_API_NAMES.RequestedInvoiceRecipient__c],
            [COD_API_NAMES.RequestedAccountingRole__c]: inPreparationCod[COD_API_NAMES.RequestedAccountingRole__c],
        };

    }
    handleAddNewCod() {
        try {
            this.isEditMode = true;
            let cod = this.initializeCod(false);
            cod.negoScopeName = '';
            cod.isEdit = true;
            this.contact.codWrapList.push(cod);
            this.contact.hasCod = true;
            this.contact.addedCodIdList.push(cod.id);
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleCloneCod(event) {
        try {
            this.isEditMode = true;
            let inPreparationOutput = this.picklistLabelsMap[ContactOperationalDirectory__c.objectApiName][COD_API_NAMES.ActivationStatus__c]['In Preparation']
            let index = event.target.dataset.index;
            let cod = this.contact.codWrapList[event.target.dataset.index];
            let codClone = {
                ...cod,
                Id: null,
                id: this.newIterator,
                isNew: true,
                isEdit: true,
                activationStatusOutput: inPreparationOutput,
                activationStatusIcon: 'standard:incident',
                rowClass: 'newRow'
            }
            codClone[COD_API_NAMES.Contact__c] = this.contact.id;
            codClone[COD_API_NAMES.Supplier__c] = this.contact[COD_API_NAMES.Supplier__c];
            this.contact.addedCodIdList.push(codClone.id);
            this.changesMap[this.newIterator] = codClone;
            this.contact.codWrapList.push(codClone);
            this.newIterator++;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleDeleteCod(event) {
        try {
            let id = event.target.dataset.id;
            let recordId = event.target.dataset.recordid;
            let targetCod = [...this.contact.inPreparationCods ?? [], ...this.contact.codWrapList ?? []]?.find(cod => recordId ? cod.Id == recordId : cod.id == id);
            if (targetCod && !targetCod.attributes) {
                targetCod.attributes = {
                    "type": COD_API_NAMES.ContactOperationalDirectory__c
                };
            }
            if (!targetCod.Id) {
                this.contact.inPreparationCods = this.contact?.inPreparationCods?.filter(cod => !(recordId ? cod.Id == recordId : cod.id == id));
                this.contact.codWrapList = this.contact?.codWrapList?.filter(cod => !(recordId ? cod.Id == recordId : cod.id == id));
                delete this.changesMap[id];
            } else {
                deleteRecord({
                    record: JSON.stringify(targetCod)
                }).then((result) => {
                    this.loadData();
                }).catch(error => {
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    handleAddRequest(event) {
        try {
            let index = event.target.dataset.index;
            // this.contact.codWrapList = [...this.contact.originalCodWrapList];
            let cod = this.contact.codWrapList[event.target.dataset.index];
            if (cod[COD_API_NAMES.Negoscope__c] && cod?.negoScopeName) {
                this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
            }
            if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod?.RequestedNegoScopeName) {
                this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
            }
            cod[COD_API_NAMES.RequestedNegoscope__c] = cod[COD_API_NAMES.RequestedNegoscope__c] ?? cod[COD_API_NAMES.Negoscope__c];
            cod[COD_API_NAMES.RequestedRole__c] = cod[COD_API_NAMES.RequestedRole__c] ?? cod[COD_API_NAMES.ContactRole__c];
            cod[COD_API_NAMES.RequestedAccountingRole__c] = cod[COD_API_NAMES.RequestedAccountingRole__c] ?? cod[COD_API_NAMES.SignatoryRole__c];
            cod[COD_API_NAMES.RequestedSignatoryRole__c] = cod[COD_API_NAMES.RequestedSignatoryRole__c] ?? cod[COD_API_NAMES.IsSignatory__c];
            cod[COD_API_NAMES.RequestedInvoiceRecipient__c] = cod[COD_API_NAMES.RequestedInvoiceRecipient__c] ?? cod[COD_API_NAMES.IsInvoiceRecipient__c];
            cod[COD_API_NAMES.ActivationStatus__c] = 'Requested Modification';
            cod.isRequesting = true;
            cod.newRequest = true;
            cod.hasRequest = true;
            this.isEditMode = true;
            this.changesMap[cod.id] = cod;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleConfirmRequest(event) {
        try {
            if (!this.processing) {
                this.processing = true;
                //GET THE REQUEST
                let isNewRequest = event.target.dataset.newRequest;
                let withApproval = event.target.dataset.withApproval;
                let cod;
                let index = event.target.dataset.index;
                if (isNewRequest) {
                    cod = withApproval ? this.contact.inPreparationCods[index] :
                        this.contact.newRequestsList[index]
                } else {
                    cod = this.contact.codWrapList[index]
                }
                if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                }
                if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                }
                //NORMALIZE IT FOR DML
                let codToNormalize = this.changesMap[cod.id];
                if ((this.isNonApproval && codToNormalize[COD_API_NAMES.Negoscope__c]) || (this.isApproval && codToNormalize[COD_API_NAMES.RequestedNegoscope__c])) {
                    if (codToNormalize[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                        codToNormalize[COD_API_NAMES.ActivationStatus__c] =
                            (codToNormalize[COD_API_NAMES.ContactRole__c] !== codToNormalize[COD_API_NAMES.RequestedRole__c] ||
                                codToNormalize[COD_API_NAMES.IsInvoiceRecipient__c] !== codToNormalize[COD_API_NAMES.RequestedInvoiceRecipient__c] ||
                                codToNormalize[COD_API_NAMES.IsSignatory__c] !== codToNormalize[COD_API_NAMES.RequestedSignatoryRole__c] ||
                                codToNormalize[COD_API_NAMES.SignatoryRole__c] !== codToNormalize[COD_API_NAMES.RequestedAccountingRole__c])
                                ? 'Requested Modification'
                                : 'Validated Entry';
                    }
                    let normalizedCod = this.normalizeCod(codToNormalize);
                    saveData({
                        recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                        recordsToDeleteJSON: JSON.stringify([])
                    }).then((result) => {
                        let parsedResult = JSON.parse(result);
                        if (parsedResult.errorMessage == 'SUCCESS') {
                            // Remove the item
                            delete this.changesMap[event.target.dataset.index];
                            // Reassign to a new object to force reactivity
                            this.changesMap = { ...this.changesMap };
                            //REMOVE THE INPUTS
                            if (parsedResult.updatedRecords[0][COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                                this.handleSendRequestNotification([parsedResult.updatedRecords[0].Id]);
                            }
                            this.fillCodInfo(parsedResult.updatedRecords[0], isNewRequest, withApproval, index, this.contact);
                            cod.isRequesting = false;
                            cod.newRequest = false;
                            cod.isEdit = false;
                            delete this.changesMap[cod.id];
                            this.contact.codWrapList = [...this.contact.codWrapList];
                            this.contact.inPreparationCods = [...this.contact.inPreparationCods];
                            this.isEditMode = false;
                            this.processing = false;
                        } else {
                            this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                            this.processing = false;
                        }
                    }).catch(error => {
                        this.processing = false;
                        console.error(error);
                        this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                    });
                } else {
                    this.processing = false;
                    this.showNotification(this.labels.LBL_Error, this.labels.MSG_Connect_Must_Add_Scope_Cod, 'error', 'dismissable');
                }
            }
        } catch (error) {
            this.processing = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error', 'dismissable');
        }
    }

    handleSendRequest(event) {
        try {
            if (!this.processing) {
                this.processing = true;
                let index = event.target.dataset.index;
                let cod = this.contact.inPreparationCods[index];
                cod[COD_API_NAMES.ActivationStatus__c] = 'Requested Creation';
                this.changesMap[cod.id] = cod;
                if (cod[COD_API_NAMES.Negoscope__c] && cod.negoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.Negoscope__c]] = cod.negoScopeName;
                }
                if (cod[COD_API_NAMES.RequestedNegoscope__c] && cod.RequestedNegoScopeName) {
                    this.negoscopeNames[cod[COD_API_NAMES.RequestedNegoscope__c]] = cod.RequestedNegoScopeName;
                }
                let normalizedCod = this.normalizeCod(this.changesMap[cod.id]);
                saveData({
                    recordsToUpsertJSON: JSON.stringify([normalizedCod]),
                    recordsToDeleteJSON: JSON.stringify([])
                }).then((result) => {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.errorMessage == 'SUCCESS') {
                        // Remove the item
                        delete this.changesMap[event.target.dataset.index];
                        // Reassign to a new object to force reactivity
                        this.changesMap = { ...this.changesMap };
                        //REMOVE THE INPUTS
                        cod.isRequesting = false;
                        cod.newRequest = false;
                        cod.isEdit = false;
                        delete this.changesMap[cod.id];
                        this.contact.codWrapList = [...this.contact.codWrapList];
                        this.contact.inPreparationCods = [...this.contact.inPreparationCods];
                        this.isEditMode = false;
                        this.fillCodInfo(parsedResult.updatedRecords[0], true, true, index, this.contact);
                        this.handleSendRequestNotification([parsedResult.updatedRecords[0].Id]);
                        this.processing = false;
                    } else {
                        this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error');
                        this.processing = false;
                    }
                }).catch(error => {
                    this.processing = false;
                    console.error(error);
                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error');
                });
                // this.handleSaveCod();
            }
            // //UPDATE THE REQUEST
            // this.dmlHandler([normalizedCod], []);
            // // REMOVE THE INPUTS
            // // cod.isRequesting = false;
            // this.checkHasRequest(cod);
        } catch (error) {
            this.processing = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    handleCancelRequest(event) {
        try {
            let id = event.target.dataset.id;
            let index = event.target.dataset.index;
            let isNewRequest = event.target.dataset.newRequest;
            let withApproval = event.target.dataset.withApproval;
            let cod = this.contact.inPreparationCods.find(it => it.id == id) || this.contact.newRequestsList.find(it => it.id == id) || this.contact.codWrapList.find(it => it.id == id);
            if (cod) {
                cod.isRequesting = false;
                cod.newRequest = false;
                if (cod[COD_API_NAMES.ActivationStatus__c] != 'Request Creation') {
                    cod[COD_API_NAMES.RequestedNegoscope__c] = cod[COD_API_NAMES.Negoscope__c];
                    cod[COD_API_NAMES.RequestedRole__c] = cod[COD_API_NAMES.ContactRole__c];
                    cod[COD_API_NAMES.RequestedAccountingRole__c] = cod[COD_API_NAMES.SignatoryRole__c];
                    cod[COD_API_NAMES.RequestedSignatoryRole__c] = cod[COD_API_NAMES.IsSignatory__c];
                    cod[COD_API_NAMES.RequestedInvoiceRecipient__c] = cod[COD_API_NAMES.IsInvoiceRecipient__c];
                } else {
                    cod[COD_API_NAMES.ActivationStatus__c] = 'In Preparation';
                }
                this.checkHasRequest(cod);
                if (!this.checkActualFields(cod)) {
                    delete this.changesMap[cod.id];
                    if (isNewRequest) {
                        withApproval ? this.contact?.inPreparationCods.splice(index, 1) : this.contact?.newRequestsList.splice(index, 1);
                    } else {
                        withApproval ? this.contact?.inPreparationCods.splice(index, 1) : this.contact?.codWrapList.splice(index, 1);
                    }
                    this.contact.hasCod = this.contact?.codWrapList?.length > 0 || this.contact?.inPreparationCods?.length > 0;
                    this.contact.hasNewRequests = this.contact?.newRequestsList?.length > 0 || this.contact?.inPreparationCods?.length > 0;
                } else {
                    delete this.changesMap[cod.id];
                }
                this.contact.hasinPreparationCods = this.contact?.inPreparationCods?.length > 0;
                let editMode = false;
                this.contact?.codWrapList?.forEach(cod => {
                    if (cod.isRequesting) {
                        editMode = true;
                        return;
                    }
                });
                this.contact?.inPreparationCods?.forEach(cod => {
                    if (cod.isRequesting && cod.newRequest) {
                        editMode = true;
                        return;
                    }
                });
                this.isEditMode = editMode;
                this.contactList = [...this.contactList];
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    normalizeCod(cod) {
        //SEND ONLY THE FOLLOWING FIELDS TO BE UPDATED
        //REMOVES ANY UNNECESSARY ATTRIBURES (EX: isNew)
        let record = {
            attributes: {
                'type': COD_API_NAMES.ContactOperationalDirectory__c
            },
            id: !cod.isNew ? cod.id : null,
            Id: cod.Id,
        }
        record[COD_API_NAMES.ActivationStatus__c] = cod[COD_API_NAMES.ActivationStatus__c];
        record[COD_API_NAMES.Negoscope__c] = cod[COD_API_NAMES.Negoscope__c];
        record[COD_API_NAMES.ContactRole__c] = cod[COD_API_NAMES.ContactRole__c];
        record[COD_API_NAMES.SignatoryRole__c] = cod[COD_API_NAMES.SignatoryRole__c];
        record[COD_API_NAMES.IsSignatory__c] = (cod[COD_API_NAMES.Negoscope__c] == '' && cod[COD_API_NAMES.RequestedNegoscope__c] == '') ? false : cod[COD_API_NAMES.IsSignatory__c];
        record[COD_API_NAMES.IsInvoiceRecipient__c] = cod[COD_API_NAMES.IsInvoiceRecipient__c];
        record[COD_API_NAMES.Supplier__c] = cod[COD_API_NAMES.Supplier__c];
        record[COD_API_NAMES.Contact__c] = cod[COD_API_NAMES.Contact__c];
        record[COD_API_NAMES.IsDeactivationRequested__c] = cod[COD_API_NAMES.IsDeactivationRequested__c];
        record.OwnerId = this.supplier.OwnerId;
        record[COD_API_NAMES.IsReactivationRequested__c] = cod[COD_API_NAMES.IsReactivationRequested__c];
        //REQUEST FIELDS
        record[COD_API_NAMES.RequestedNegoscope__c] = cod[COD_API_NAMES.RequestedNegoscope__c];
        record[COD_API_NAMES.RequestedRole__c] = cod[COD_API_NAMES.RequestedRole__c];
        record[COD_API_NAMES.RequestedAccountingRole__c] = cod[COD_API_NAMES.RequestedAccountingRole__c];
        if (cod[COD_API_NAMES.RequestedSignatoryRole__c] != null) {
            record[COD_API_NAMES.RequestedSignatoryRole__c] = cod[COD_API_NAMES.RequestedSignatoryRole__c];
        }
        if (cod[COD_API_NAMES.RequestedInvoiceRecipient__c] != null) {
            record[COD_API_NAMES.RequestedInvoiceRecipient__c] = cod[COD_API_NAMES.RequestedInvoiceRecipient__c];
        }
        return record;
    }

    handleSaveNewCod() {
        try {
            if (!this.processing) {
                let valid = true;
                let missingNS = false;
                Object.values(this.changesMap).forEach(cod => {
                    if ((this.isManager && !cod[COD_API_NAMES.Negoscope__c]) || (this.isApproval && !cod[COD_API_NAMES.RequestedNegoscope__c])) {
                        valid = false;
                        missingNS = true;
                        return;
                    }
                });
                if (valid) {
                    this.handleSaveCod();
                } else {
                    if (missingNS) {
                        this.showNotification(this.labels.LBL_Error, this.labels.MSG_Connect_Must_Add_Scope_Cod, 'error');
                    }
                }
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    handleSaveCod() {
        try {
            if (!this.processing) {
                this.sendNotification = Object.values(this.changesMap).some(
                    (obj) => obj[COD_API_NAMES.ActivationStatus__c] === 'Requested Modification'
                );
                Object.values(this.changesMap).forEach(cod => {
                    if (cod[COD_API_NAMES.ActivationStatus__c] == 'Requested Modification') {
                        if (cod[COD_API_NAMES.ContactRole__c] == cod[COD_API_NAMES.RequestedRole__c] && cod[COD_API_NAMES.IsSignatory__c] == cod[COD_API_NAMES.RequestedSignatoryRole__c] && cod[COD_API_NAMES.IsInvoiceRecipient__c] == cod[COD_API_NAMES.RequestedInvoiceRecipient__c] && cod[COD_API_NAMES.Negoscope__c] == cod[COD_API_NAMES.RequestedNegoscope__c] 
                            && cod[COD_API_NAMES.SignatoryRole__c] == cod[COD_API_NAMES.RequestedAccountingRole__c]
                        ) {
                            cod[COD_API_NAMES.ActivationStatus__c] = 'Validated Entry';
                        }
                    }
                })
                let callback = (parsedResult) => {
                    this.contact.addedCodIdList = [];
                    this.contact.requestedCodIdList = [];
                    this.contact.codWrapList = [];
                    if (this.sendNotification) {
                        let codIdList = [];
                        parsedResult.updatedRecords.forEach(cod => {
                            codIdList.push(cod.Id);
                        })
                        this.handleSendRequestNotification(codIdList);
                    }
                    this.loadData();
                }
                let recordsToUpsert = [];

                let changedRecords = Object.values(this.changesMap);
                changedRecords.forEach(element => {
                    // Note: this part is where we assign Id of exisitng cod (requested creation/in preparation)
                    //         if (this.isManager) {
                    //             this.contact.inPreparationCods.forEach(prepCod=>{
                    //                 if (prepCod[COD_API_NAMES.RequestedNegoscope__c] == element[COD_API_NAMES.Negoscope__c]) {
                    //                     element.id = prepCod.id;
                    //                     element[COD_API_NAMES.RequestedNegoscope__c] = element[COD_API_NAMES.Negoscope__c];
                    //                     element[COD_API_NAMES.RequestedRole__c] = element[COD_API_NAMES.ContactRole__c] ? element[COD_API_NAMES.ContactRole__c] : null;
                    //                     element[COD_API_NAMES.RequestedSignatoryRole__c] = element[COD_API_NAMES.IsSignatory__c] ? element[COD_API_NAMES.IsSignatory__c] : false;
                    //                     element[COD_API_NAMES.RequestedInvoiceRecipient__c] = element[COD_API_NAMES.IsInvoiceRecipient__c] ? element[COD_API_NAMES.IsInvoiceRecipient__c] : false;
                    //                     element.isNew = false;
                    //                 }
                    //             });
                    //             this.contact.requestedCods.forEach(prepCod=>{
                    //                 if (prepCod[COD_API_NAMES.RequestedNegoscope__c] == element[COD_API_NAMES.Negoscope__c]) {
                    //                     element.id = prepCod.id;
                    //                     element[COD_API_NAMES.ActivationStatus__c] = 'Validated Entry';
                    //                     element[COD_API_NAMES.RequestedNegoscope__c] = element[COD_API_NAMES.Negoscope__c];
                    //                     element[COD_API_NAMES.RequestedRole__c] = element[COD_API_NAMES.ContactRole__c] ? element[COD_API_NAMES.ContactRole__c] : null;
                    //                     element[COD_API_NAMES.RequestedSignatoryRole__c] = element[COD_API_NAMES.IsSignatory__c] ? element[COD_API_NAMES.IsSignatory__c] : false;
                    //                     element[COD_API_NAMES.RequestedInvoiceRecipient__c] = element[COD_API_NAMES.IsInvoiceRecipient__c] ? element[COD_API_NAMES.IsInvoiceRecipient__c] : false;
                    //                     element.isNew = false;
                    //                 }
                    //             });
                    //         }
                    recordsToUpsert.push(this.normalizeCod(element));
                });
                if (!this.processing) {
                    this.processing = true;
                    if (this.isNonApproval) {
                        recordsToUpsert.forEach(item => {
                            const id = this.contact?.inPreparationCods?.find(e => e[COD_API_NAMES.RequestedNegoscope__c] == item[COD_API_NAMES.Negoscope__c])?.Id;
                            if (id != null) {
                                item.Id = id;
                            }
                        })
                    }
                    saveCOD({
                        recordsToUpsertJSON: JSON.stringify(recordsToUpsert)
                    }).then((result) => {
                        let parsedResult = JSON.parse(result);
                        if (parsedResult.errorMessage == 'SUCCESS') {
                            this.showNotification(this.labels.LBL_Success, this.labels.MSG_Successfully_Saved, 'success');
                            this.contact.codWrapList.forEach(element => {
                                element.isEdit = false;
                            });
                            this.changesMap = {};
                            if (callback) {
                                callback(parsedResult);
                            } else {
                                this.loadData()
                            }
                            this.isEditMode = false;
                        } else {
                            this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error', 'sticky');
                        }
                        this.processing = false;
                    }).catch(error => {
                        this.processing = false;
                        console.error(error);
                        this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                    });
                }
                //this.dmlHandler(recordsToUpsert, [], callback);
            }
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    dmlHandler(self, recordsToUpsert, recordsToDelete, callback, displaySuccessNotificationCallback) {
        self = self || this;
        if (!self.processing) {
            self.processing = true;
            saveData({
                recordsToUpsertJSON: JSON.stringify(recordsToUpsert),
                recordsToDeleteJSON: JSON.stringify(recordsToDelete)
            }).then((result) => {
                let parsedResult = JSON.parse(result);
                if (parsedResult.errorMessage == 'SUCCESS') {
                    if (displaySuccessNotificationCallback) {
                        displaySuccessNotificationCallback();
                    }
                    self.contact.codWrapList.forEach(element => {
                        element.isEdit = false;
                    });
                    self.changesMap = {};
                    if (callback) {
                        callback(parsedResult);
                    } else {
                        self.loadData()
                    }
                    self.isEditMode = false;
                } else {
                    self.showNotification(self.labels.LBL_Error, parsedResult.errorMessage, 'error', 'sticky');
                }
                self.processing = false;
            }).catch(error => {
                self.processing = false;
                console.error(error);
                self.showNotification(self.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        }

    }

    handleEditContact(event) {
        try {
            let field = event.target.dataset.field;
            let value;
            if (field == CONTACT_API_NAMES.IsOrgAdmin__c || field == CONTACT_API_NAMES.IsInvoiceRecipient__c) {
                value = event.detail.checked;
            } else if (field == 'ReportsToId') {
                value = event.detail.recordId ? event.detail.recordId : event.target.value;
            }
            else {
                value = event.target.value;
            }
            this.contact[field] = value;
        } catch (error) {
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }
    handleEditCurrentContact(event) {
        let field = event.target.dataset.field;
        // value = event.detail.recordId;
        this.contact[field] = event.detail.recordId;
    }

    handleInsertContact() {
        this.popup.visibility = false;
        if (!this.processing) {
            try {
                this.processing = true;
                let valid = true;
                let message = '';

                const onSubmit = (save) => {
                    let inputFields = this.template.querySelectorAll('.info-input');
                    for (let field of inputFields) {
                        try {
                            if (!(field?.checkValidity())) {
                                field.reportValidity(); // Show error message for the specific field
                                valid = false;
                                // break; // Exit the loop immediately if a field is invalid
                            }
                        } catch (error) {
                            valid = false;
                            console.error(JSON.stringify(error))
                        }
                    }
                    // Validate duplicates
                    if (valid) {
                        checkContactDuplication({
                            supplierId: this.supplier.Id,
                            firstName: this.contact.FirstName,
                            lastName: this.contact.LastName,
                            email: this.contact.Email,
                        }).then(result => {
                            if (result) {
                                valid = false;
                                message = this.labels.MSG_Connect_Duplicate_Contact_Found;
                            }
                            // Validate cod
                            if (valid && this.contact.type === 'Individual') {
                                if (this.contact.codWrapList.length != 0) {
                                    let existingNegoscopes = [];
                                    this.contact.codWrapList.forEach(cod => {
                                        if (!cod[COD_API_NAMES.Negoscope__c]) {
                                            valid = false;
                                            message = this.labels.MSG_Connect_Must_Add_Scope_Cod;
                                            return;
                                        } else if (existingNegoscopes.includes(cod[COD_API_NAMES.Negoscope__c])) {
                                            valid = false;
                                            message = this.labels.LBL_Connect_DuplicateCODError;
                                            return;
                                        } else {
                                            existingNegoscopes.push(cod[COD_API_NAMES.Negoscope__c]);
                                        }
                                    });
                                } else {
                                    if (this.contact.inPreparationCods && this.contact.inPreparationCods.length != 0) {
                                        this.contact.inPreparationCods.forEach(cod => {
                                            if (!cod[COD_API_NAMES.RequestedNegoscope__c]) {
                                                valid = false;
                                                message = this.labels.MSG_Connect_Must_Add_Scope_Cod;
                                                return;
                                            }
                                        });
                                    }
                                }
                            }
                            if (valid) {
                                let contactToUpsert = {
                                    attributes: {
                                        'type': 'Contact'
                                    },
                                    AccountId: this.supplier[SUPPLIER_API_NAMES.Account__c],
                                };
                                //ADD CHECK VALIDITY
                                // if (this.contact.type === 'Individual' && ((this.isNonApproval && !this.contact.hasCod) || (this.isApproval && !this.contact.hasNewRequests))) {
                                //     this.showNotification(this.labels.LBL_Error, this.labels.MSG_Connect_Must_Add_Cod, 'error');
                                //     this.processing = false;
                                //     return;
                                // }
                                //Prepare the parent: Contact
                                if ((this.contact.type == "Generic mailbox" || this.contact.FirstName) && this.contact.LastName && this.contact.Email) {
                                    contactToUpsert[CONTACT_API_NAMES.Supplier__c] = this.supplier.Id;
                                    contactToUpsert[CONTACT_API_NAMES.FirstName] = this.contact[CONTACT_API_NAMES.FirstName];
                                    contactToUpsert[CONTACT_API_NAMES.LastName] = this.contact[CONTACT_API_NAMES.LastName];
                                    contactToUpsert[CONTACT_API_NAMES.Fax] = this.contact[CONTACT_API_NAMES.Fax];
                                    contactToUpsert[CONTACT_API_NAMES.IsInvoiceRecipient__c] = this.contact[CONTACT_API_NAMES.IsInvoiceRecipient__c];
                                    contactToUpsert[CONTACT_API_NAMES.Phone] = this.contact[CONTACT_API_NAMES.Phone];
                                    contactToUpsert[CONTACT_API_NAMES.MobilePhone] = this.contact[CONTACT_API_NAMES.MobilePhone];
                                    contactToUpsert[CONTACT_API_NAMES.OtherPhone] = this.contact[CONTACT_API_NAMES.OtherPhone];
                                    contactToUpsert[CONTACT_API_NAMES.Email] = this.contact[CONTACT_API_NAMES.Email];
                                    contactToUpsert[CONTACT_API_NAMES.IsOrgAdmin__c] = this.contact[CONTACT_API_NAMES.IsOrgAdmin__c];
                                    contactToUpsert[CONTACT_API_NAMES.Title] = this.contact[CONTACT_API_NAMES.Title];
                                    contactToUpsert[CONTACT_API_NAMES.Salutation] = this.contact[CONTACT_API_NAMES.Salutation];
                                    contactToUpsert[CONTACT_API_NAMES.ReportsToId] = this.contact[CONTACT_API_NAMES.ReportsToId];
                                    contactToUpsert[CONTACT_API_NAMES.Username__c] = this.contact.Email;
                                    contactToUpsert[CONTACT_API_NAMES.Type__c] = this.contact.type;
                                    contactToUpsert.OwnerId = this.supplier.OwnerId;
                                }
                                //Prepare the children: COD
                                if (this.contact.type === 'Individual' && this.contact.hasCod) {
                                    if (this.contact.codWrapList.length != 0) {
                                        this.contact.codWrapList.forEach(cod => {
                                            cod[COD_API_NAMES.Supplier__c] = this.supplier.Id;
                                            cod[COD_API_NAMES.RequestedSignatoryRole__c] = cod[COD_API_NAMES.IsSignatory__c];
                                            cod[COD_API_NAMES.RequestedInvoiceRecipient__c] = cod[COD_API_NAMES.IsInvoiceRecipient__c];
                                        });
                                    } else {
                                        this.contact.inPreparationCods.forEach(cod => {
                                            cod[COD_API_NAMES.Supplier__c] = this.supplier.Id;
                                        });
                                    }
                                }

                                //Normalize the cods
                                let codToUpsert = [];
                                if (this.contact.type === 'Individual' && this.contact.hasCod) {
                                    let changedRecords = Object.values(this.changesMap);
                                    if (!save && this.isApproval) {
                                        changedRecords.forEach(cod => {
                                            cod[COD_API_NAMES.ActivationStatus__c] = 'Requested Creation'
                                        });
                                    }
                                    changedRecords.forEach(element => {
                                        codToUpsert.push(this.normalizeCod(element));
                                    });
                                }
                                saveRelatedData({
                                    parentRecordJSON: JSON.stringify(contactToUpsert),
                                    childRecordsToUpsertJSON: JSON.stringify(codToUpsert),
                                    childRelationFieldName: COD_API_NAMES.Contact__c,
                                }).then((result) => {
                                    let parsedResult = JSON.parse(result);
                                    if (parsedResult.errorMessage == 'SUCCESS') {
                                        this.closePanel();
                                        this.newContact = {};
                                        this.selectedContactName = this.contact.FirstName + ' ' + this.contact.LastName;
                                        this.searchTerm = '';
                                        this.loadData();
                                    } else {
                                        this.processing = false;
                                        this.showNotification(this.labels.LBL_Error, parsedResult.errorMessage, 'error', 'sticky');
                                    }
                                }).catch(error => {
                                    this.processing = false;
                                    console.error(error);
                                    console.log('%c' + error.message ? error.message : error.body?.message);
                                    this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
                                });
                            } else {
                                this.showNotification(this.labels.LBL_Error, message, 'error');
                                this.processing = false;
                            }
                        }).catch(error => {
                            this.processing = false;
                            valid = false;
                            message = error?.body?.message || error?.message || error;
                            console.log('error>>>', message);
                        });
                    }
                    else {
                        this.processing = false;
                        this.showNotification(this.labels.LBL_Error, message, 'error');
                    }

                }
                if (this.isApproval && Object.keys(this.changesMap).length > 0) {
                    this.popup.body = this.labels.LBL_Connect_WithRFASave;
                    this.popup.submitBtn = this.labels.LBL_Save;
                    this.popup.submitBtnClass = 'slds-button slds-button_neutral';
                    this.popup.cancelBtn = this.labels.LBL_Send;
                    this.popup.visibility = true;
                    this.popupNotification().then(save => {
                        this.popup.visibility = false;
                        this.popup.visibility = onSubmit(save);
                    })
                } else {
                    onSubmit(false);
                }

            } catch (error) {
                this.processing = false;
                console.log('%c' + error.message ? error.message : error.body?.message);
                this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
            }

        }
    }

    handleSendRequestNotification(codIdList) {
        try {
            sendEmailToValidate({
                codIdList: [...codIdList],
                sendToSupplier: this.directoryManager == 'SupplierOwner'
            }).then((result) => {
                this.sendNotification = false;
            }).catch((error) => {
                console.log('error: ' + error);
                this.sendNotification = false;
            })
        }
        catch (error) {
            this.sendNotification = false;
            console.log('error: ' + error);
        }
    }
    //MISC
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode ? mode : 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    generateAlias(firstName, lastName) {
        // Handle null or undefined values for firstName and lastName
        firstName = firstName ? firstName : '';
        lastName = lastName ? lastName : '';

        // Take 2 letters from firstName and as much as possible from lastName to fit 8 characters
        let alias = '';

        if (firstName.length >= 2) {
            alias += firstName.substring(0, 2);  // Take the first 2 letters of the first name
        } else {
            alias += firstName;  // Take whatever is available
        }

        // Fill the rest with characters from the last name, keeping the total length at 8 characters
        const remainingLength = 8 - alias.length;
        alias += lastName.substring(0, Math.min(remainingLength, lastName.length));

        return alias.toLowerCase();  // Convert to lowercase for consistency
    }

    adjustGridHeight() {
        // Get the side panel and grid elements
        // const sidePanel = this.template.querySelector('.contactPanelContainer') ;
        const sidePanel = this.template.querySelector('.contactPanelContainer') ? this.template.querySelector('.contactPanelContainer') : this.template.querySelector('.addNewPanelContainer');
        const sidePanel2 = this.template.querySelector('.sidePanel');
        const container = this.template.querySelector('.mainContainer');
        const modal = this.template.querySelector('.modal');
        const sidePanelTransparent = this.template.querySelector('.sidePanelTransparent');
        // const tableContainer = this.template.querySelector('.tableContainer');
        const tableDiv = this.template.querySelector('.tableDiv');
        const panelHeader = this.template.querySelector('.panelHeader');
        const pageBody = this.template.querySelector('.pageBody');
        const pageHeader = this.template.querySelector('.pageHeader');
        const mainDiv = this.template.querySelector('.mainDiv');
        const codContainer = this.template.querySelector('.cod-container')
        // if (codContainer) {
        //     codContainer.style.height = (mainDiv.offsetHeight - panelHeader.offsetHeight - 30) + 'px';
        // }

        // if(tableContainer){
        //     tableContainer.style.height = container.offsetHeight - sidePanel.offsetHeight + 'px';
        // }
        if (mainDiv) {
            mainDiv.style.minHeight = `${pageBody.offsetHeight + pageHeader.offsetHeight + 20}px`;
        }
        if (modal) {
            modal.style.minHeight = `${pageBody.offsetHeight + pageHeader.offsetHeight + 20}px`;
        }
        if (container && modal && sidePanel && tableDiv) {
            const panelHeaderHeight = panelHeader.offsetHeight;
            const tableDivHeight = tableDiv.offsetHeight;
            // modal.style.height = panelHeaderHeight + tableDivHeight + 20 + 'px';
            // container.style.height = panelHeaderHeight + tableDivHeight + 20 + 'px';
            // sidePanel.style.height = panelHeaderHeight + tableDivHeight ;

            // tableContainer.style.height = container.offsetHeight - sidePanel.offsetHeight + 'px';
            if (sidePanelTransparent) {
                const sidePanelHeight = sidePanel.offsetHeight;
                sidePanelTransparent.style.height = `${sidePanelHeight}px`;
            }

        }
        else if (!sidePanel) {
            if (container) {
                container.style.height = `100%`;
                if (sidePanelTransparent) {
                    sidePanelTransparent.style.height = `100%`;
                }
            }
        }
    }

    scrollToTop() {
        const el = this.template.querySelector('.mainDiv');
        const offset = 240;
        if (el) {
            const top = el.getBoundingClientRect().top + window.scrollY - offset;
            window.scrollTo({
                top: Math.max(0, Math.round(top)),
                behavior: 'smooth'
            });
        }
    }

    // popup
    popupNotification() {
        return new Promise((resolve, reject) => {
            this._PopupResolve = resolve
        });
    }

    submitPopUp(event) {
        const state = event.target.dataset.id == 'confirm' ? true : false;
        this._PopupResolve(state)
    }

}