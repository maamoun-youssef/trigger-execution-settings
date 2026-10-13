import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import loadAllReminderRule from '@salesforce/apex/ReminderRuleSettingsController.loadAllReminderRule';
import save from '@salesforce/apex/ReminderRuleSettingsController.save';
// ---- Labels ----
import LBL_Save from '@salesforce/label/c.LBL_Save';
import LBL_Date from '@salesforce/label/c.LBL_Date';
import LBL_ReminderRuleSettings_Select_Page_Settings from '@salesforce/label/c.LBL_ReminderRuleSettings_Select_Page_Settings';
import LBL_ReminderRuleSettings_Select_Settings from '@salesforce/label/c.LBL_ReminderRuleSettings_Select_Settings';
import LBL_ReminderRuleSettings_Add_New_Settings from '@salesforce/label/c.LBL_ReminderRuleSettings_Add_New_Settings';
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Delete from '@salesforce/label/c.LBL_Delete';
// Month labels
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

export default class ReminderRuleSettings extends LightningElement {
  labels = {
    LBL_Save,
    LBL_Date,
    LBL_Cancel,
    LBL_Delete,
    LBL_ReminderRuleSettings_Select_Page_Settings,
    LBL_ReminderRuleSettings_Select_Settings,
    LBL_ReminderRuleSettings_Add_New_Settings,
    pageSettings: {
      Icon: 'Icon',
      HeaderBackground: 'Header Background'
    },
    ReminderRule__mdt: {
      ReminderDay1Label: '',
      ReminderMonth1Label: '',
      ReminderDay2Label: '',
      ReminderMonth2Label: '',
      ReminderDay3Label: '',
      ReminderMonth3Label: '',
      ReminderFlowLabel: ''
    }
  };

  @track loading = false;
  @track flows = [];
  @track profileOptions = [];
  @track selectedProfileName = null;
  @track newProfileName = '';
  @track prefix = '';
  @track mainData = '';
  @track saveStatus = false; 
  @track addNewRowProfile = false;
  @track newProfile = { name: '', description: '', icon: '', headerBackground: '' };
  @track deletePopup = { visibility: false, title: '', body: '' };

  @track REMINDER_RULE_API = {
    ReminderRuleSettings__mdt: 'ReminderRuleSettings__mdt',
    ReminderDay1__c: 'ReminderDay1__c',
    ReminderMonth1__c: 'ReminderMonth1__c',
    ReminderDay2__c: 'ReminderDay2__c',
    ReminderMonth2__c: 'ReminderMonth2__c',
    ReminderDay3__c: 'ReminderDay3__c',
    ReminderMonth3__c: 'ReminderMonth3__c',
    ReminderFlow__c:   'ReminderFlow__c'
  };

  @track rr = {
    reminderDay1: null,   reminderMonth1: null,
    reminderDay2: null,   reminderMonth2: null,
    reminderDay3: null,   reminderMonth3: null,
    reminderFlow: '',
  };

  get monthOptions() {
    return [
      { label: LBL_January,   value: '1'  },
      { label: LBL_February,  value: '2'  },
      { label: LBL_March,     value: '3'  },
      { label: LBL_April,     value: '4'  },
      { label: LBL_May,       value: '5'  },
      { label: LBL_June,      value: '6'  },
      { label: LBL_July,      value: '7'  },
      { label: LBL_August,    value: '8'  },
      { label: LBL_September, value: '9'  },
      { label: LBL_October,   value: '10' },
      { label: LBL_November,  value: '11' },
      { label: LBL_December,  value: '12' }
    ];
  }

  connectedCallback() { this.initData(); }

  get hasProfile() {
    return !!this.selectedProfileName && !!this.mainData?.reminderRuleSettings;
  }

  devKey(name) {
    const base = (name || '').trim() || 'ReminderRuleSettings';
    return base.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '').replace(/_+/g, '_');
  }

  normalizeFromApex(obj) {
    if (!obj) return {};
    const map = {
      ReminderDay1: 'reminderDay1',     ReminderMonth1: 'reminderMonth1',
      ReminderDay2: 'reminderDay2',     ReminderMonth2: 'reminderMonth2',
      ReminderDay3: 'reminderDay3',     ReminderMonth3: 'reminderMonth3',
      ReminderFlow: 'reminderFlow'
    };
    const out = {};
    for (const [k, v] of Object.entries(obj)) {
      out[map[k] || k] = v;
    }
    return out;
  }

  async initData(processName) {
    try {
      this.loading = true;
      const json = await loadAllReminderRule({ processName: processName ? this.devKey(processName) : null });
      const wrapper = JSON.parse(json);
      this.prefix = wrapper.prefix;
      this.mainData = wrapper;
      if (wrapper?.activeFlows) {
        this.fillFlowsOption(wrapper.activeFlows);
      } else if (Array.isArray(wrapper?.activeScreenFlows)) {
        this.flows = wrapper.activeScreenFlows.map(f => ({ label: f.label, value: f.value }));
      } else {
        this.flows = [];
      }

      if (wrapper.fieldsMap) {
        this.setlabels(wrapper.fieldsMap);
      }
      if (Array.isArray(wrapper.profiles)) {
        this.profileOptions = wrapper.profiles.map(p => ({ label: p.label || p.value, value: p.value || p.label })).sort((a, b) => a.label.localeCompare(b.label));
      } else if (Array.isArray(wrapper.names)) {
        this.profileOptions = wrapper.names.map(n => ({ label: n, value: n })).sort((a, b) => a.label.localeCompare(b.label));
      }
      if (!this.selectedProfileName && wrapper.processName) {
        this.selectedProfileName = wrapper.processName;
      }

      if (wrapper.reminderRuleSettings) {
        // Accept either PascalCase or lower-camel from Apex
        const s = this.normalizeFromApex(wrapper.reminderRuleSettings);
        // Make months string for combobox selection
        ['reminderMonth1','reminderMonth2','reminderMonth3'].forEach(k => {
          if (s[k] !== null && s[k] !== undefined) s[k] = String(s[k]);
        });
        this.rr = { ...this.rr, ...s };
        this.saveStatus = false;
      }
    } catch (e) {
      this.toast('Error', e?.body?.message || e?.message, 'error');
    } finally {
      this.loading = false;
    }
  }

  setlabels(fieldsMap) {
    const obj = this.REMINDER_RULE_API.ReminderRuleSettings__mdt;
    const map = (fieldsMap && fieldsMap[obj]) ? fieldsMap[obj] : {};
    const get = (api) => (map && map[api]) ? map[api] : null;
    this.labels.ReminderRule__mdt.ReminderDay1Label   = get(this.REMINDER_RULE_API.ReminderDay1__c)?.label   || 'Reminder Day 1';
    this.labels.ReminderRule__mdt.ReminderMonth1Label = get(this.REMINDER_RULE_API.ReminderMonth1__c)?.label || 'Reminder Month 1';
    this.labels.ReminderRule__mdt.ReminderDay2Label   = get(this.REMINDER_RULE_API.ReminderDay2__c)?.label   || 'Reminder Day 2';
    this.labels.ReminderRule__mdt.ReminderMonth2Label = get(this.REMINDER_RULE_API.ReminderMonth2__c)?.label || 'Reminder Month 2';
    this.labels.ReminderRule__mdt.ReminderDay3Label   = get(this.REMINDER_RULE_API.ReminderDay3__c)?.label   || 'Reminder Day 3';
    this.labels.ReminderRule__mdt.ReminderMonth3Label = get(this.REMINDER_RULE_API.ReminderMonth3__c)?.label || 'Reminder Month 3';
    this.labels.ReminderRule__mdt.ReminderFlowLabel   = get(this.REMINDER_RULE_API.ReminderFlow__c)?.label   || 'Reminder Flow';
  }

  fillFlowsOption(activeFlows) {
    try {
      const parsedResult = JSON.parse(activeFlows);
      const flowRecords = JSON.parse(parsedResult.flowsSerialized || '[]');
      const flowDefinitionRecords = JSON.parse(parsedResult.flowDefinitionSerialized || '[]');
      const devNameMap = {};
      for (const fd of flowDefinitionRecords) {
        devNameMap[fd.ActiveVersionId] = fd.DeveloperName;
      }
      const options = [];
      for (const flow of flowRecords) {
        options.push({ label: flow.MasterLabel, value: devNameMap[flow.Id] });
      }
      this.flows = options;
    } catch {
      this.flows = [];
    }
  }

  handleInput(e) {
    const raw = e.target.dataset.field;
    const field = raw ? raw.charAt(0).toLowerCase() + raw.slice(1) : raw;
    let val = e.target.value;
    if (/Day\d$/.test(field)) {
      const n = Number(val);
      if (!Number.isNaN(n)) val = n;
    } else if (/Month\d$/.test(field)) {
      val = String(val);
    }
    this.rr = { ...this.rr, [field]: val };
  }

  async handleSave() {
    try {
      if (!this.selectedProfileName) {
        this.toast('Error', 'Select or create a settings profile first.', 'error', 'sticky');
        return;
      }
      this.saveStatus = true;
      this.loading = true;
      const s = this.rr || {};
      const toInt = (v) => (v === '' || v === null || v === undefined ? null : parseInt(v, 10));      
      const payload = {
        ...s,
        processName: this.selectedProfileName || s.processName || 'ReminderRuleSettings',
        reminderDay1:   toInt(s.reminderDay1),
        reminderMonth1: toInt(s.reminderMonth1),
        reminderDay2:   toInt(s.reminderDay2),
        reminderMonth2: toInt(s.reminderMonth2),
        reminderDay3:   toInt(s.reminderDay3),
        reminderMonth3: toInt(s.reminderMonth3),
        reminderFlow:   s.reminderFlow || ''
      };
      await save({ reminderRuleSettingsJSON: JSON.stringify(payload) });
      this.toast(this.labels.LBL_Save, 'Settings saved', 'success');
    } catch (e) {
      this.toast('Error', e?.body?.message || e?.message, 'error', 'sticky');
    } finally {
      this.loading = false;
      this.saveStatus = false;
    }
  }

  handleProfileChange(e) {
    this.selectedProfileName = e.detail.value;
    this.initData(this.selectedProfileName);
  }

  handleNewProfileName(e) {
    this.newProfileName = e.target.value;
  }

  useOrCreateProfile() {
    const name = (this.newProfileName || '').trim();
    if (!name) {
      this.toast('Error', 'Please enter a profile name.', 'error', 'sticky');
      return;
    }
    this.selectedProfileName = name;
    if (!this.profileOptions.find(o => o.value === name)) {
      this.profileOptions = [...this.profileOptions, { label: name, value: name }].sort((a, b) => a.label.localeCompare(b.label));
    }
    this.newProfileName = '';
    this.rr = {
      ...this.rr,
      reminderDay1: null, reminderMonth1: null,
      reminderDay2: null, reminderMonth2: null,
      reminderDay3: null, reminderMonth3: null,
      reminderFlow: ''
    };
    this.initData(name);
  }

  handleCancel() {
    // Go back to profile chooser only (hide form), discard in-form edits
    this.selectedProfileName = null;
    this.mainData = {};
    this.rr = {
      ...this.rr,
      reminderDay1: null, reminderMonth1: null,
      reminderDay2: null, reminderMonth2: null,
      reminderDay3: null, reminderMonth3: null,
      reminderFlow: ''
    };
    // optional UX: ensure the chooser is visible
    try { this.template.host.scrollTop = 0; } catch(e) {}
  }

  togglePopupAddProfile = () => {
    this.addNewRowProfile = !this.addNewRowProfile;
    if (!this.addNewRowProfile) {
      this.newProfile = { name: '', description: '', icon: '', headerBackground: '' };
    }
  };

  handleChangeNewProfile = (e) => {
    const field = e?.target?.dataset?.field;
    if (!field) return;
   if (field === 'icon' || field === 'headerBackground') {
      this.newProfile = { ...this.newProfile, [field]: 'data:image/png;base64,stub' };
    } else {
      this.newProfile = { ...this.newProfile, [field]: e.target.value };
    }
  };

  handleAddNewProfile = () => {
    const name = (this.newProfile?.name || '').trim();
    if (!name) {
      this.toast('Error', 'Please enter a profile name.', 'error', 'sticky');
      return;
    }
    this.selectedProfileName = name;
    if (!this.profileOptions.find(o => o.value === name)) {
      this.profileOptions = [...this.profileOptions, { label: name, value: name }]
        .sort((a, b) => a.label.localeCompare(b.label));
    }
    this.togglePopupAddProfile();
    this.rr = {
      ...this.rr,
      reminderDay1: null, reminderMonth1: null,
      reminderDay2: null, reminderMonth2: null,
      reminderDay3: null, reminderMonth3: null,
      reminderFlow: ''
    };
    this.initData(name);
  };

  toast(title, message, variant, mode) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
  }
}