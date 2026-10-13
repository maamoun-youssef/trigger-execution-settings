import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// APEX
import loadServiceStatementSettings from '@salesforce/apex/ServiceStatementSettingsController.loadServiceStatementSettings';
import listProfiles from '@salesforce/apex/ServiceStatementSettingsController.listProfiles';
import save from '@salesforce/apex/ServiceStatementSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/ServiceStatementSettingsController.checkDeploymentStatus';
import listReminderRules from '@salesforce/apex/ReminderRuleSettingsController.listProfiles';
import listFileDirectoryRecordTypes from '@salesforce/apex/ServiceStatementSettingsController.listFileDirectoryRecordTypes';
import listFileDirectorySubTypes from '@salesforce/apex/ServiceStatementSettingsController.listFileDirectorySubTypes';

// ---- Custom Labels ----
import LBL_Connect_SellInStatementInitializationParameters from '@salesforce/label/c.LBL_Connect_SellInStatementInitializationParameters';
import LBL_Connect_SellInStatementInitializationDescription from '@salesforce/label/c.LBL_Connect_SellInStatementInitializationDescription';
import LBL_ConnectSettings_SalesTermsStatementGenerationDescription from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsStatementGenerationDescription';
import LBL_ConnectSettings_SalesTermsStatementGenerationNote from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsStatementGenerationNote';
import LBL_ConnectSettings_SalesTermsSelfPublishWarning from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSelfPublishWarning';
import LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle';
import LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle';
import LBL_ConnectSettings_SalesTermsSubmissionRulesDescription from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesDescription';
import LBL_ConnectSettings_SalesTermsReponseRulesSectionTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsReponseRulesSectionTitle';
import LBL_ConnectSettings_SalesTermsResponseRulesSectionSubTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsResponseRulesSectionSubTitle';
import LBL_ConnectSettings_SalesTermsResponseRulesDescription from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsResponseRulesDescription';
import LBL_Save from '@salesforce/label/c.LBL_Save';
import LBL_January from '@salesforce/label/c.LBL_January';
import LBL_February from '@salesforce/label/c.LBL_February';
import LBL_March from '@salesforce/label/c.LBL_March';
import LBL_April from '@salesforce/label/c.LBL_April';
import LBL_May from '@salesforce/label/c.LBL_May';
import LBL_June from '@salesforce/label/c.LBL_June';
import LBL_July from '@salesforce/label/c.LBL_July';
import LBL_August from '@salesforce/label/c.LBL_August';
import LBL_September from '@salesforce/label/c.LBL_September';
import LBL_October from '@salesforce/label/c.LBL_October';
import LBL_November from '@salesforce/label/c.LBL_November';
import LBL_December from '@salesforce/label/c.LBL_December';
import LBL_RequestedDocuments from '@salesforce/label/c.LBL_RequestedDocuments';
import MSG_Information from '@salesforce/label/c.MSG_Information';
import MSG_Deploy_Last_Status from '@salesforce/label/c.MSG_Deploy_Last_Status';
import MSG_Request_Timed_Out from '@salesforce/label/c.MSG_Request_Timed_Out';
import MSG_Deploy_Ended_With_Status from '@salesforce/label/c.MSG_Deploy_Ended_With_Status';
import LBL_ServiceStatementSettings_Select_Page_Settings from '@salesforce/label/c.LBL_ServiceStatementSettings_Select_Page_Settings';
import LBL_ServiceStatementSettings_Select_Settings from '@salesforce/label/c.LBL_ServiceStatementSettings_Select_Settings';
import LBL_ServiceStatementSettings_Add_New_Settings from '@salesforce/label/c.LBL_ServiceStatementSettings_Add_New_Settings';
import LBL_PageSettings_Icon from '@salesforce/label/c.LBL_PageSettings_Icon';
import LBL_PageSettings_Header_Background from '@salesforce/label/c.LBL_PageSettings_Header_Background';
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Delete from '@salesforce/label/c.LBL_Delete';

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';

export default class ServiceStatementSettings extends LightningElement {
  labels = {
    LBL_ConnectSettings_SalesTermsStatementGenerationDescription,
    LBL_ConnectSettings_SalesTermsStatementGenerationNote,
    LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle,
    LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle,
    LBL_ConnectSettings_SalesTermsSubmissionRulesDescription,
    LBL_ConnectSettings_SalesTermsReponseRulesSectionTitle,
    LBL_ConnectSettings_SalesTermsResponseRulesSectionSubTitle,
    LBL_ConnectSettings_SalesTermsResponseRulesDescription,
    LBL_Connect_SellInStatementInitializationParameters,
    LBL_Connect_SellInStatementInitializationDescription,
    LBL_ConnectSettings_SalesTermsSelfPublishWarning,
    LBL_Save,
    LBL_RequestedDocuments,
    MSG_Information,
    MSG_Deploy_Last_Status,
    MSG_Request_Timed_Out,
    MSG_Deploy_Ended_With_Status,
    LBL_ServiceStatementSettings_Select_Page_Settings,
    LBL_ServiceStatementSettings_Select_Settings,
    LBL_ServiceStatementSettings_Add_New_Settings,
    LBL_Cancel,
    LBL_Delete,
    Cancel: LBL_Cancel,
    pageSettings: {
      Icon: LBL_PageSettings_Icon,
      HeaderBackground: LBL_PageSettings_Header_Background
    },
    ServiceStatementSettings__mdt: {
      objectLabel: '',
      generationModeLabel: '',
      autoPublishDayLabel: '',
      autoPublishMonthLabel: '',
      isNSLevelLabel: '',
      allowSelfSubmitLabel: '',
      descriptionFRLabel: '',
      descriptionENLabel: '',
      annualClosingDayLabel: '',
      annualClosingMonthLabel: '',
      creationFlowLabel: '',
      reminderFlowLabel: '',
      reminderRuleLabel: '',
      requestedDocumentsLabel: '',
      submissionFlowLabel: '',
      validationFlowLabel: '',
      addFrameworkAgreementTemplateLabel: '',
      addPurchasingTermsLabel: ''
    }
  };
  @track loading = false;
  @track profileOptions = [];
  @track selectedProfileName = null;
  @track newProfileName = '';
  @track addNewRowPageSettings = false;
  @track newPageSettings = { name: '', description: '', icon: '', headerBackground: '' };
  @track deletePopup = { visibility: false, title: '', body: '' };
  @track mainPanelHeight = '';
  @track fieldsMap = {};
  @track genModeOptions = [];
  @track flows = [];
  @track reminderRuleOptions = [];
  @track requestedDocs = [];
  @track fileDirectoryTypeOptions = [];
  @track fileDirectorySubTypeOptions = [];
  uid() { return `${Date.now()}_${Math.random().toString(36).slice(2)}`; }
  newDoc() { return { uid: this.uid(), type: '', subType: '', name: '', mandatory: true }; }
  @track prefix = '';
  @track mainData = '';
  @track SETTINGS_API = {
    ServiceStatementSettings__mdt: 'ServiceStatementSettings__mdt',
    GenerationMode__c: 'GenerationMode__c',
    AutoPublishDay__c: 'AutoPublishDay__c',
    AutoPublishMonth__c: 'AutoPublishMonth__c',
    IsNSLevel__c: 'IsNSLevel__c',
    AllowSelfSubmit__c: 'AllowSelfSubmit__c',
    DescriptionFR__c: 'DescriptionFR__c',
    DescriptionEN__c: 'DescriptionEN__c',
    AnnualClosingDay__c: 'AnnualClosingDay__c',
    AnnualClosingMonth__c: 'AnnualClosingMonth__c',
    CreationFlow__c: 'CreationFlow__c',
    ReminderFlow__c: 'ReminderFlow__c',
    ReminderRule__c: 'ReminderRule__c',
    RequestedDocuments__c: 'RequestedDocuments__c',
    SubmissionFlow__c: 'SubmissionFlow__c',
    ValidationFlow__c: 'ValidationFlow__c',
    AddFrameworkAgreementTemplate__c: 'AddFrameworkAgreementTemplate__c',
    AddPurchasingTerms__c: 'AddPurchasingTerms__c'
  };

  get monthOptions() {
    return [
      { label: LBL_January, value: '1' },
      { label: LBL_February, value: '2' },
      { label: LBL_March, value: '3' },
      { label: LBL_April, value: '4' },
      { label: LBL_May, value: '5' },
      { label: LBL_June, value: '6' },
      { label: LBL_July, value: '7' },
      { label: LBL_August, value: '8' },
      { label: LBL_September, value: '9' },
      { label: LBL_October, value: '10' },
      { label: LBL_November, value: '11' },
      { label: LBL_December, value: '12' }
    ];
  }

  get isAuto() {
    return this.mainData?.serviceStatementSettings?.generationMode === 'Automatic';
  }

  // PageSettings-style getters used in the template
  get selectedPageSettingsName() {
    return this.selectedProfileName;
  }
  get pageSettingsOptions() {
    return this.profileOptions;
  }
  get saveStatus() {
    return false; // keep Save enabled; wire your own validation if needed
  }

  connectedCallback() {
    this.bootstrapProfiles();
    window.addEventListener('resize', this.changeHeight);
    this.changeHeight();
  }

  disconnectedCallback() {
    window.removeEventListener('resize', this.changeHeight);
  }

  async bootstrapProfiles() {
    this.loading = true;
    try {
      const res = await listProfiles();
      const parsed = this.safeParse(res);
      let names = [];
      if (Array.isArray(parsed)) {
        names = parsed;
      } else if (parsed && Array.isArray(parsed.names)) {
        names = parsed.names;
      }
      this.profileOptions = names
        .sort((a,b) => a.localeCompare(b))
        .map(n => ({ label: n, value: n }));
    } catch (e) {
      this.toast('Error', e?.body?.message || e?.message || 'Failed to load profiles', ERROR_VARIANT, STICKY_VARIANT);
    } finally {
      this.loading = false;
    }
  }

  async loadReminderRuleProfiles() {
    try {
      const res = await listReminderRules();
      const parsed = this.safeParse(res);
      const names = Array.isArray(parsed) ? parsed : (parsed && parsed.names ? parsed.names : []);
      this.reminderRuleOptions = (names || [])
        .sort((a,b) => a.localeCompare(b))
        .map(n => ({ label: n, value: n }));
    } catch (e) {
      // Non-fatal; just leave the list empty
      // eslint-disable-next-line no-console
      console.warn('Failed to load Reminder Rules profiles', e);
      this.reminderRuleOptions = [];
    }
  }

  get hasProfile() {
    return !!this.selectedProfileName && !!this.mainData?.serviceStatementSettings;
  }

  initData(processName) {
    this.loading = true;
    const key = this.devKey(processName);
    loadServiceStatementSettings({ processName: key })
      .then(result => {
        const parsedData = JSON.parse(result);
        this.prefix = parsedData.prefix;
        this.mainData = parsedData;
        if (this.mainData?.serviceStatementSettings) {
          this.mainData.serviceStatementSettings.processName = this.selectedProfileName || processName;
        }
        this.fillFlowsOption(this.mainData.activeFlows);
        this.loadFileDirectoryTypes();
        this.loadFileDirectorySubTypes();
        this.loadReminderRuleProfiles();
        this.setlabels(this.mainData.fieldsMap);
        this.normalizeUiTypes();
        this.inflateRequestedDocs(this.mainData?.serviceStatementSettings?.requestedDocuments);
        this.clearValidityFor(['autoPublishDay','autoPublishMonth']);
        this.loading = false;
      })
      .catch(error => {
        this.loading = false;
        this.toast('Error', (error && error.body && error.body.message) || 'Failed to load settings', ERROR_VARIANT, STICKY_VARIANT);
        console.error(error);
      });
  }

  devKey(name) {
    const base = (name || '').trim() || 'ServiceStatementSettings';
    return base.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '').replace(/_+/g, '_');
  }

  normalizeUiTypes() {
    const s = this.mainData?.serviceStatementSettings;
    if (!s) return;
    if (s.autoPublishMonth !== null && s.autoPublishMonth !== undefined) {
      s.autoPublishMonth = String(s.autoPublishMonth);
    }
    if (s.annualClosingMonth !== null && s.annualClosingMonth !== undefined) {
      s.annualClosingMonth = String(s.annualClosingMonth);
    }
    const toBool = (v) => v === true || v === 'true';
    s.isNSLevel = toBool(s.isNSLevel);
    s.allowSelfSubmit = toBool(s.allowSelfSubmit);
    if ('addFrameworkAgreementTemplate' in s) s.addFrameworkAgreementTemplate = toBool(s.addFrameworkAgreementTemplate);
    if ('addPurchasingTerms' in s) s.addPurchasingTerms = toBool(s.addPurchasingTerms);
  }

  inflateRequestedDocs(list) {
    const rows = Array.isArray(list) ? list : [];
    this.requestedDocs = rows.map(d => ({
      uid: this.uid(),
      type: d?.documentType || '',
      subType: d?.documentSubType || '',
      name: d?.documentName || '',
      mandatory: d?.isMandatory === true || d?.isMandatory === 'true'
    }));
  }
  deflateRequestedDocs() {
    return (this.requestedDocs || [])
      .filter(r => (r.type || r.subType || r.name))
      .map(r => ({
        documentType: r.type || '',
        documentSubType: r.subType || '',
        documentName: r.name || '',
        isMandatory: !!r.mandatory
      }));
  }

  fillFlowsOption(activeFlows) {
    if (!activeFlows) return;
    const options = [];
    const parsedResult = JSON.parse(activeFlows);
    const flowRecords = JSON.parse(parsedResult.flowsSerialized);
    const flowDefinitionRecords = JSON.parse(parsedResult.flowDefinitionSerialized);
    const devNameMap = {};
    for (const fd of flowDefinitionRecords) {
      devNameMap[fd.ActiveVersionId] = fd.DeveloperName;
    }
    for (const flow of flowRecords) {
      options.push({ label: flow.MasterLabel, value: devNameMap[flow.Id] });
    }
    this.flows = options;
  }

  async loadFileDirectoryTypes() {
    try {
      const res = await listFileDirectoryRecordTypes();
      const data = this.safeParse(res);
      const arr = Array.isArray(data) ? data : (data && data.items ? data.items : []);
      this.fileDirectoryTypeOptions = (arr || []).map(x => ({ label: x.label || x.Name, value: x.value || x.DeveloperName }));
    } catch (e) {
      this.fileDirectoryTypeOptions = [];
      console.warn('Failed to load FileDirectory record types', e);
    }
  }
  async loadFileDirectorySubTypes() {
    try {
      const res = await listFileDirectorySubTypes();
      const data = this.safeParse(res);
      const arr = Array.isArray(data) ? data : (data && data.items ? data.items : []);
      // expect [{label, value}]
      this.fileDirectorySubTypeOptions = (arr || []).map(x => ({ label: x.label || x.Value || x.value, value: x.value || x.Value }));
    } catch (e) {
      this.fileDirectorySubTypeOptions = [];
      // eslint-disable-next-line no-console
      console.warn('Failed to load FileDirectory SubType picklist', e);
    }
  }

  setlabels(fieldsMap) {
    const obj = this.SETTINGS_API.ServiceStatementSettings__mdt;
    this.labels.ServiceStatementSettings__mdt.generationModeLabel     = fieldsMap[obj][this.SETTINGS_API.GenerationMode__c].label;
    this.labels.ServiceStatementSettings__mdt.autoPublishDayLabel     = fieldsMap[obj][this.SETTINGS_API.AutoPublishDay__c].label;
    this.labels.ServiceStatementSettings__mdt.autoPublishMonthLabel   = fieldsMap[obj][this.SETTINGS_API.AutoPublishMonth__c].label;
    this.labels.ServiceStatementSettings__mdt.isNSLevelLabel          = fieldsMap[obj][this.SETTINGS_API.IsNSLevel__c].label;
    this.labels.ServiceStatementSettings__mdt.allowSelfSubmitLabel    = fieldsMap[obj][this.SETTINGS_API.AllowSelfSubmit__c].label;
    this.labels.ServiceStatementSettings__mdt.descriptionFRLabel      = fieldsMap[obj][this.SETTINGS_API.DescriptionFR__c].label;
    this.labels.ServiceStatementSettings__mdt.descriptionENLabel      = fieldsMap[obj][this.SETTINGS_API.DescriptionEN__c].label;
    this.labels.ServiceStatementSettings__mdt.annualClosingDayLabel   = fieldsMap[obj][this.SETTINGS_API.AnnualClosingDay__c].label;
    this.labels.ServiceStatementSettings__mdt.annualClosingMonthLabel = fieldsMap[obj][this.SETTINGS_API.AnnualClosingMonth__c].label;
    if (fieldsMap[obj][this.SETTINGS_API.CreationFlow__c]) {
      this.labels.ServiceStatementSettings__mdt.creationFlowLabel = fieldsMap[obj][this.SETTINGS_API.CreationFlow__c].label;
    }
    if (fieldsMap[obj][this.SETTINGS_API.ReminderFlow__c]) {
      this.labels.ServiceStatementSettings__mdt.reminderFlowLabel = fieldsMap[obj][this.SETTINGS_API.ReminderFlow__c].label;
    }
    if (fieldsMap[obj][this.SETTINGS_API.ReminderRule__c]) {
      this.labels.ServiceStatementSettings__mdt.reminderRuleLabel = fieldsMap[obj][this.SETTINGS_API.ReminderRule__c].label;
    }
    this.labels.ServiceStatementSettings__mdt.requestedDocumentsLabel = fieldsMap[obj][this.SETTINGS_API.RequestedDocuments__c].label;
    this.labels.ServiceStatementSettings__mdt.submissionFlowLabel     = fieldsMap[obj][this.SETTINGS_API.SubmissionFlow__c].label;
    // New labels
    if (fieldsMap[obj][this.SETTINGS_API.ValidationFlow__c]) {
      this.labels.ServiceStatementSettings__mdt.validationFlowLabel = fieldsMap[obj][this.SETTINGS_API.ValidationFlow__c].label;
    }
    if (fieldsMap[obj][this.SETTINGS_API.AddFrameworkAgreementTemplate__c]) {
      this.labels.ServiceStatementSettings__mdt.addFrameworkAgreementTemplateLabel =
        fieldsMap[obj][this.SETTINGS_API.AddFrameworkAgreementTemplate__c].label;
    }
    if (fieldsMap[obj][this.SETTINGS_API.AddPurchasingTerms__c]) {
      this.labels.ServiceStatementSettings__mdt.addPurchasingTermsLabel =
        fieldsMap[obj][this.SETTINGS_API.AddPurchasingTerms__c].label;
    }
    const options = [];
    for (const pick of fieldsMap[obj][this.SETTINGS_API.GenerationMode__c].picklistValues) {
      options.push({ label: pick.label, value: pick.value });
    }
    this.genModeOptions = options;
  }

  clearValidityFor(fields = []) {
    fields.forEach((f) => {
      const el = this.template.querySelector(`[data-field="${f}"]`);
      if (el && typeof el.setCustomValidity === 'function') {
        el.setCustomValidity('');
        el.reportValidity();
      }
    });
  }
  invalidateField(field, message) {
    const el = this.template.querySelector(`[data-field="${field}"]`);
    if (el && typeof el.setCustomValidity === 'function') {
      el.setCustomValidity(message);
      el.reportValidity();
    }
  }
  validateBeforeSave() {
    const s = this.mainData?.serviceStatementSettings || {};
    this.clearValidityFor(['autoPublishDay','autoPublishMonth']);
    if (s.generationMode === 'Automatic') {
      const dayRaw = s.autoPublishDay;
      const monthRaw = s.autoPublishMonth;
      if (dayRaw === '' || dayRaw === null || dayRaw === undefined) {
        this.invalidateField('autoPublishDay', 'Required when Generation Mode is Automatic');
      }
      if (monthRaw === '' || monthRaw === null || monthRaw === undefined) {
        this.invalidateField('autoPublishMonth', 'Required when Generation Mode is Automatic');
      }
      if (dayRaw === '' || dayRaw === null || dayRaw === undefined || monthRaw === '' || monthRaw === null || monthRaw === undefined) {
        this.toast('Error', 'For Automatic generation, both publish Day and Month are required.', 'error', 'sticky');
        return false;
      }
      const day = parseInt(dayRaw, 10);
      const month = parseInt(monthRaw, 10);
      let invalid = false;
      if (isNaN(day) || day < 1 || day > 31) {
        this.invalidateField('autoPublishDay', 'Enter a day between 1 and 31');
        invalid = true;
      }
      if (isNaN(month) || month < 1 || month > 12) {
        this.invalidateField('autoPublishMonth', 'Select a month 1–12');
        invalid = true;
      }
      if (invalid) {
        this.toast('Error', 'Please correct the highlighted fields.', 'error', 'sticky');
        return false;
      }
    } else {
      this.clearValidityFor(['autoPublishDay','autoPublishMonth']);
    }
    return true;
  }

  handleFieldEdits(event) {
    const t = event.target;
    const isToggle = t.type === 'toggle' || t.type === 'checkbox';
    const value = isToggle
      ? (event.detail && typeof event.detail.checked !== 'undefined'
          ? event.detail.checked
          : !!t.checked)
      : t.value;
    const field = event.target.dataset.field;
    this.mainData.serviceStatementSettings[field] = value;
    if (field === 'autoPublishDay' || field === 'autoPublishMonth') {
      this.clearValidityFor([field]);
    }
    if (field === 'generationMode') {
      this.clearValidityFor(['autoPublishDay','autoPublishMonth']);
    }
  }

  handleProfileChange(e) {
    this.selectedProfileName = e.detail.value;
    this.initData(this.selectedProfileName);
  }

  // alias for the new template
  handleChangePageSettings(e) {
    this.handleProfileChange(e);
  }
  handleCancel() {
    this.selectedProfileName = null;
    this.mainData = '';
    this.requestedDocs = [];
  }
  togglePopupAddPageSettings() {
    this.addNewRowPageSettings = !this.addNewRowPageSettings;
    if (this.addNewRowPageSettings) {
      this.newPageSettings = { name: '', description: '', icon: '', headerBackground: '' };
    }
  }
  handleChangeNewPageSettings(e) {
    const field = e.target.dataset.field;
    if (field === 'icon' || field === 'headerBackground') {
      this.handleAssetPick(field);
    } else {
      this.newPageSettings = { ...this.newPageSettings, [field]: e.target.value };
    }
  }
  handleAssetPick(field) {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.onchange = (evt) => {
      const file = evt.target.files && evt.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onloadend = () => {
        this.newPageSettings = { ...this.newPageSettings, [field]: reader.result };
      };
      reader.readAsDataURL(file);
    };
    input.click();
  }
  handleAddNewPageSettings() {
    this.newProfileName = this.newPageSettings?.name || '';
    this.useOrCreateProfile();
    this.togglePopupAddPageSettings();
  }
  handlePopupAction = (evt) => {
    // simple closer; wire your own confirm logic if you later use deletePopup
    this.deletePopup = { visibility: false, title: '', body: '' };
  }
  changeHeight = () => {
    const h = window.innerWidth < 980 ? window.innerHeight - 213 : window.innerHeight - 183;
    this.mainPanelHeight = 'height:' + h + 'px';
  };

  handleNewProfileName(e) {
    this.newProfileName = e.target.value;
  }

  useOrCreateProfile() {
    const name = (this.newProfileName || '').trim();
    if (!name) {
      this.toast('Error', 'Please enter a profile name.', ERROR_VARIANT, STICKY_VARIANT);
      return;
    }
    this.selectedProfileName = name;
    if (!this.profileOptions.find(o => o.value === name)) {
      this.profileOptions = [...this.profileOptions, { label: name, value: name }].sort((a, b) => a.label.localeCompare(b.label));
    }
    this.newProfileName = '';
    this.requestedDocs = [];
    this.initData(name);
  }

  handleDocInput(e) {
    const idx = Number(e.target.dataset.idx);
    const field = e.target.dataset.field;
    const isToggle = e.target.type === 'toggle' || e.target.type === 'checkbox';
    const value = isToggle
      ? (e.detail && typeof e.detail.checked !== 'undefined' ? e.detail.checked : !!e.target.checked)
       : e.detail && typeof e.detail.value !== 'undefined' ? e.detail.value : e.target.value;
    const next = [...this.requestedDocs];
    next[idx] = { ...next[idx], [field]: value };
    this.requestedDocs = next;
  }

  addRequestedDoc() { this.requestedDocs = [...this.requestedDocs, this.newDoc()]; }

  deleteRequestedDoc(e) {
    const idx = Number(e.currentTarget.dataset.idx);
    const next = this.requestedDocs.slice(0, idx).concat(this.requestedDocs.slice(idx + 1));
    this.requestedDocs = next.length ? next : [this.newDoc()];
  }

  safeParse(maybeJson) {
    if (maybeJson && typeof maybeJson === 'object') return maybeJson;
    if (typeof maybeJson === 'string') {
      try { return JSON.parse(maybeJson); } catch (e) { return null; }
    }
    return null;
  }

  normalizeDeploymentId(result) {
    // Accept either raw id "0Af..." or a JSON like {"idDeployment":"0Af..."}
    if (typeof result === 'string') {
      // quick reject for obvious HTML
      if (result.trim().startsWith('<')) return null;
      try {
        const obj = JSON.parse(result);
        if (obj && obj.idDeployment) return obj.idDeployment;
      } catch(e) { /* result was a plain id string */ }
      return result;
    }
    if (result && typeof result === 'object' && result.idDeployment) return result.idDeployment;
    return null;
  }

  handleSave() {
    const name = (this.newProfileName || '').trim();
    if (!name && !this.selectedProfileName) {
      this.toast('Error', 'Please enter a profile name.', ERROR_VARIANT, STICKY_VARIANT);
      return;
    }
    if (!this.selectedProfileName) {
      this.toast('Error', 'Select or create a settings profile first.', 'error', 'sticky');
      return;
    }
    if (!this.validateBeforeSave()) {
      this.loading = false;
      return;
    }
    this.loading = true;
    const src = this.mainData.serviceStatementSettings || {};
    const toInt = (v) => (v === '' || v === null || v === undefined ? null : parseInt(v, 10));
    const rawName = this.selectedProfileName || name || src.processName || 'ServiceStatementSettings';
    const key = this.devKey(rawName);
    const payload = {
      ...src,
      processName: this.selectedProfileName || src.processName || 'ServiceStatementSettings',
      autoPublishDay:     toInt(src.autoPublishDay),
      autoPublishMonth:   toInt(src.autoPublishMonth),  
      annualClosingDay:   toInt(src.annualClosingDay),
      annualClosingMonth: toInt(src.annualClosingMonth), 
      isNSLevel:                     src.isNSLevel === true || src.isNSLevel === 'true',
      allowSelfSubmit:               src.allowSelfSubmit === true || src.allowSelfSubmit === 'true',
      addFrameworkAgreementTemplate: src.addFrameworkAgreementTemplate === true || src.addFrameworkAgreementTemplate === 'true',
      addPurchasingTerms:            src.addPurchasingTerms === true || src.addPurchasingTerms === 'true',
      requestedDocuments:            this.deflateRequestedDocs()
    };

    save({ serviceStatementSettingsJSON: JSON.stringify(payload), processName: key })
      .then((result) => {
        const id = this.normalizeDeploymentId(result);
        if (!id) {
          throw new Error('Invalid response from save() – no deployment id.');
        }
        this.checkDeployementStatus(id);
      })
      .catch((err) => {
        this.loading = false;
        const msg = err?.body?.message || err?.message || 'Save failed.';
        this.toast('Error', msg, ERROR_VARIANT, STICKY_VARIANT);
      });
  }

  checkDeployementStatus(idDeployment) {
    let self = this;
    let counter = 0;
    let status;
    checkDeploymentStatus({ idDeployment })
      .then((fresult) => {
        const parsed = self.safeParse(fresult);
        if (!parsed || !parsed.deployResult) {
          throw new Error('checkDeploymentStatus() did not return JSON.');
        }
        let fdone = parsed.deployResult.done;
        status = parsed.deployResult.status;
        if (!fdone) {
          const interval = setInterval(() => {
            if (counter > 10) {
              self.loading = false;
              clearInterval(interval);
              self.dispatchEvent(new ShowToastEvent({
                title: self.labels.MSG_Information,
                message: `${self.labels.MSG_Request_Timed_Out} ${self.labels.MSG_Deploy_Last_Status} ${status}`,
                variant: INFO_VARIANT,
                mode: STICKY_VARIANT
              }));
            }
            checkDeploymentStatus({ idDeployment }).then((result) => {
              const parsedTick = self.safeParse(result);
              if (!parsedTick || !parsedTick.deployResult) {
                throw new Error('checkDeploymentStatus() polling returned non-JSON.');
              }
              let done = parsedTick.deployResult.done;
              let success = parsedTick.deployResult.success;
              status = parsedTick.deployResult.status;
              if (done) {
                self.loading = false;
                clearInterval(interval);
                if (success) {
                  self.dispatchEvent(new ShowToastEvent({
                    title: self.labels.LBL_Save,
                    message: 'Save complete.',
                    variant: SUCCESS_VARIANT,
                    mode: STICKY_VARIANT
                  }));
                } else {
                  self.dispatchEvent(new ShowToastEvent({
                    title: self.labels.MSG_Information,
                    message: `${self.labels.MSG_Deploy_Ended_With_Status} ${status}`,
                    variant: INFO_VARIANT,
                    mode: STICKY_VARIANT
                  }));
                }
              }
            }).catch((e) => {
              self.loading = false;
              clearInterval(interval);
              const msg = e?.body?.message || e?.message || 'Status check failed.';
              self.toast('Error', msg, ERROR_VARIANT, STICKY_VARIANT);
            });
            counter++;
          }, 5000);
        } else {
          self.loading = false;
          self.dispatchEvent(new ShowToastEvent({
            title: self.labels.LBL_Save,
            message: 'Save complete.',
            variant: SUCCESS_VARIANT,
            mode: STICKY_VARIANT
          }));
        }
      })
      .catch((e) => {
        self.loading = false;
        const msg = e?.body?.message || e?.message || 'Status check failed.';
        self.toast('Error', msg, ERROR_VARIANT, STICKY_VARIANT);
      });
  }

  toast(title, message, variant, mode) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
  }
}