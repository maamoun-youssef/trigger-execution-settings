import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadSTSSettings from '@salesforce/apex/ServiceStatementSettingsController.loadSTSSettings';
import save from '@salesforce/apex/ServiceStatementSettingsController.save';
import checkDeploymentStatus from '@salesforce/apex/ServiceStatementSettingsController.checkDeploymentStatus';

// ---- Custom Labels (import individually, then expose as a single object) ----
import LBL_Connect_SellInStatementInitializationParameters from "@salesforce/label/c.LBL_Connect_SellInStatementInitializationParameters";
import LBL_Connect_SellInStatementInitializationDescription from "@salesforce/label/c.LBL_Connect_SellInStatementInitializationDescription";
import LBL_ConnectSettings_SalesTermsStatementGenerationDescription from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsStatementGenerationDescription';
import LBL_ConnectSettings_SalesTermsStatementGenerationNote from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsStatementGenerationNote';
import LBL_ConnectSettings_SalesTermsSelfPublishWarning from "@salesforce/label/c.LBL_ConnectSettings_SalesTermsSelfPublishWarning"
import LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle';
import LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle';
import LBL_ConnectSettings_SalesTermsSubmissionRulesDescription from '@salesforce/label/c.LBL_ConnectSettings_SalesTermsSubmissionRulesDescription';
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

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';
export default class StsSettings extends LightningElement {

  // Expose labels to the template
  labels = {
    LBL_ConnectSettings_SalesTermsStatementGenerationDescription,
    LBL_ConnectSettings_SalesTermsStatementGenerationNote,
    LBL_ConnectSettings_SalesTermsSubmissionRulesSectionTitle,
    LBL_ConnectSettings_SalesTermsSubmissionRulesSectionSubTitle,
    LBL_ConnectSettings_SalesTermsSubmissionRulesDescription,
    LBL_Connect_SellInStatementInitializationParameters,
    LBL_Connect_SellInStatementInitializationDescription,
    LBL_ConnectSettings_SalesTermsSelfPublishWarning,
    LBL_Save,
    LBL_RequestedDocuments,
    MSG_Information,
    MSG_Deploy_Last_Status,
    MSG_Request_Timed_Out,
    MSG_Deploy_Ended_With_Status,
    STS__mdt: {
      objectLabel: '',
      salesTermsGenerationModeLabel: '',
      salesTermsAutoPublishDayLabel: '',
      salesTermsAutoPublishMonthLabel: '',
      isSalesTermsNSLevelLabel: '',
      allowSalesTermsSelfSubmitLabel: '',
      salesTermsDescriptionFRLabel: '',
      salesTermsDescriptionENLabel: '',
      salesTermsAnnualClosingDayLabel: '',
      salesTermsAnnualClosingMonthLabel: '',
      salesTermsReminderRuleLabel: '',
      requestedDocumentTypeLabel: '',
      requestedDocumentSubTypeLabel: '',
      requestedDocumentNameLabel: '',
      salesTermsSubmissionFlowLabel: ''
    }
  };
  @track loading = false;
  // main payload
  @track fieldsMap = {};
  @track genModeOptions = [];





  @track flows = [];
  // requested documents UI model (front-end only; we map its 1st row to metadata on save)
  @track requestedDocs = [];
  uid() {
    return `${Date.now()}_${Math.random().toString(36).slice(2)}`;
  }
  newDoc() {
    return { uid: this.uid(), type: '', subType: '', name: '', mandatory: true };
  }
  @track sts = {
    salesTermsGenerationMode: 'Automatic',
    salesTermsAutoPublishDay: null,
    salesTermsAutoPublishMonth: null,
    isSalesTermsNSLevel: false,
    allowSalesTermsSelfSubmit: true,
    salesTermsDescriptionFR: '',
    salesTermsDescriptionEN: '',
    salesTermsAnnualClosingDay: null,
    salesTermsAnnualClosingMonth: null,
    salesTermsReminderRule: '',
    requestedDocumentType: '',
    requestedDocumentSubType: '',
    requestedDocumentName: '',
    salesTermsSubmissionFlow: ''
  };
  @track STS_SETTINGS_API = {
    STS__mdt: 'STS__mdt',
    AllowSalesTermsSelfSubmit__c: 'AllowSalesTermsSelfSubmit__c',
    SalesTermsAnnualClosingDay__c: 'SalesTermsAnnualClosingDay__c',
    SalesTermsAnnualClosingMonth__c: 'SalesTermsAnnualClosingMonth__c',
    SalesTermsDescriptionEN__c: 'SalesTermsDescriptionEN__c',
    SalesTermsDescriptionFR__c: 'SalesTermsDescriptionFR__c',
    RequestedDocumentName__c: 'RequestedDocumentName__c',
    SalesTermsGenerationMode__c: 'SalesTermsGenerationMode__c',
    SalesTermsReminderRule__c: 'SalesTermsReminderRule__c',
    SalesTermsAutoPublishDay__c: 'SalesTermsAutoPublishDay__c',
    SalesTermsAutoPublishMonth__c: 'SalesTermsAutoPublishMonth__c',
    IsSalesTermsNSLevel__c: 'IsSalesTermsNSLevel__c',
    RequestedDocumentSubType__c: 'RequestedDocumentSubType__c',
    SalesTermsSubmissionFlow__c: 'SalesTermsSubmissionFlow__c',
    RequestedDocumentType__c: 'RequestedDocumentType__c',
  }
  get monthOptions() {
    return [{ label: LBL_January, value: '1' },
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
    { label: LBL_December, value: '12' }];
  }
  get isAuto() {
    return this.mainData.stsSettings.salesTermsGenerationMode === 'Automatic';
  }

  connectedCallback() {
    this.initData();
  }

  @track prefix = '';
  @track mainData = '';
  initData() {
    this.loading = true;
    loadSTSSettings().then(result => {
      let parsedData = JSON.parse(result);
      this.prefix = parsedData.prefix;
      this.mainData = parsedData;
      this.fillFlowsOption(this.mainData.activeFlows);
      console.log('this.mainData  >>>> ' + JSON.stringify(this.mainData))
      this.setlabels(this.mainData.fieldsMap);
      this.loading = false;
    }).catch(error => {
      this.loading = false;
      console.log('error' + error)
      console.error(error)
    })
  }

  fillFlowsOption(activeFlows) {
    if (activeFlows) {
      let options = [];
      let parsedResult = JSON.parse(activeFlows);
      let flowRecords = JSON.parse(parsedResult.flowsSerialized);
      let flowDefinitionRecords = JSON.parse(parsedResult.flowDefinitionSerialized);
      let devNameMap = {}
      for (let flowDefinition of flowDefinitionRecords) {
        devNameMap[flowDefinition.ActiveVersionId] = flowDefinition.DeveloperName;
      }
      for (let flow of flowRecords) {
        options.push({ label: flow.MasterLabel, value: devNameMap[flow.Id] })
      }
      this.flows = options;
    }
  }

  setlabels(fieldsMap) {
    let settingsApiName = this.STS_SETTINGS_API.STS__mdt.replace('__c', '__mdt');
    this.labels.STS__mdt.salesTermsGenerationModeLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsGenerationMode__c].label;
    this.labels.STS__mdt.salesTermsAutoPublishDayLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsAutoPublishDay__c].label;
    this.labels.STS__mdt.salesTermsAutoPublishMonthLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsAutoPublishMonth__c].label;
    this.labels.STS__mdt.isSalesTermsNSLevelLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.IsSalesTermsNSLevel__c].label;
    this.labels.STS__mdt.allowSalesTermsSelfSubmitLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.AllowSalesTermsSelfSubmit__c].label;
    this.labels.STS__mdt.salesTermsDescriptionFRLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsDescriptionFR__c].label;
    this.labels.STS__mdt.salesTermsDescriptionENLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsDescriptionEN__c].label;
    this.labels.STS__mdt.salesTermsAnnualClosingDayLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsAnnualClosingDay__c].label;
    this.labels.STS__mdt.salesTermsAnnualClosingMonthLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsAnnualClosingMonth__c].label;
    this.labels.STS__mdt.salesTermsReminderRuleLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsReminderRule__c].label;
    this.labels.STS__mdt.requestedDocumentTypeLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.RequestedDocumentType__c].label;
    this.labels.STS__mdt.requestedDocumentSubTypeLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.RequestedDocumentSubType__c].label;
    this.labels.STS__mdt.requestedDocumentNameLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.RequestedDocumentName__c].label;
    this.labels.STS__mdt.salesTermsSubmissionFlowLabel = fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsSubmissionFlow__c].label;
    // FILL Options
    this.genModeOptions = []
    let options = [];
    for (let picklist of fieldsMap[settingsApiName][this.STS_SETTINGS_API.SalesTermsGenerationMode__c].picklistValues) {
      options.push({ label: picklist.label, value: picklist.value });
    }
    this.genModeOptions = options;
  }

  handleFieldEdits(event) {
    let value = event.target.value;
    let field = event.target.dataset.field;
    this.mainData.stsSettings[field] = value;
  }

  // ---------- Requested Docs handlers ----------
  handleDocInput(e) {
    const idx = Number(e.target.dataset.idx);
    const field = e.target.dataset.field;
    const isToggle = e.target.type === 'checkbox';
    const value = isToggle ? e.target.checked : e.target.value;
    const next = [...this.requestedDocs];
    next[idx] = { ...next[idx], [field]: value };
    this.requestedDocs = next;
  }

  //   addRequestedDoc() {
  //     this.requestedDocs = [...this.requestedDocs, { type: '', subType: '', name: '', mandatory: true }];
  //   }

  addRequestedDoc() {
    this.requestedDocs = [...this.requestedDocs, this.newDoc()];
  }

  deleteRequestedDoc(e) {
    const idx = Number(e.currentTarget.dataset.idx);
    const next = this.requestedDocs.slice(0, idx).concat(this.requestedDocs.slice(idx + 1));
    this.requestedDocs = next.length ? next : [this.newDoc()];
  }

  handleSave() {
    console.log('JSON.stringify(this.mainData.stsSettings) >>>> ' + JSON.stringify(this.mainData.stsSettings));
    save({ stsSettingsJSON: JSON.stringify(this.mainData.stsSettings) }).then(result => {
      this.checkDeployementStatus(result);
    }).catch(error => {
      this.isLoading = false;
    })
  }

  checkDeployementStatus(idDeployment) {
    let self = this;
    let counter = 0;
    let status;
    checkDeploymentStatus({
      'idDeployment': idDeployment,
    }).then(fresult => {
      let fdone = JSON.parse(fresult).deployResult.done;
      status = JSON.parse(fresult).deployResult.status;
      if (!fdone) {
        let interval = setInterval(() => {
          if (counter > 10) {
            self.loading = false;
            clearInterval(interval);
            self.dispatchEvent(new ShowToastEvent({
              title: self.labels.MSG_Information,
              message: self.labels.MSG_Request_Timed_Out + ' ' + self.labels.MSG_Deploy_Last_Status + ' ' + status,
              variant: INFO_VARIANT,
              mode: STICKY_VARIANT
            }));
          }
          checkDeploymentStatus({
            'idDeployment': idDeployment,
          }).then(result => {
            let done = JSON.parse(result).deployResult.done;
            let success = JSON.parse(result).deployResult.success;
            status = JSON.parse(result).deployResult.status;
            if (done) {
              self.loading = false;
              clearInterval(interval);
              if (success) {
                self.dispatchEvent(new ShowToastEvent({
                  title: self.labels.LBL_Save,
                  message: self.labels.MSG_Save_Complete,
                  variant: SUCCESS_VARIANT,
                  mode: STICKY_VARIANT
                }));
              } else {
                self.dispatchEvent(new ShowToastEvent({
                  title: self.labels.MSG_Information,
                  message: self.labels.MSG_Deploy_Ended_With_Status + ' ' + status,
                  variant: INFO_VARIANT,
                  mode: STICKY_VARIANT
                }));
              }
            }
          });
          counter++;
        }, 5000);
      } else {
        self.loading = false;
        self.dispatchEvent(new ShowToastEvent({
          title: self.labels.LBL_Save,
          message: self.labels.MSG_Save_Complete,
          variant: SUCCESS_VARIANT,
          mode: STICKY_VARIANT
        }));
      }
    });
  }

  //   handleAddDoc() {
  //     this.toast('Info', 'Multi-document support coming soon. This row maps to the current metadata fields.', 'info');
  //   }

  handleAddDoc() {
    this.addRequestedDoc();
  }

  toast(title, message, variant, mode) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
  }
}