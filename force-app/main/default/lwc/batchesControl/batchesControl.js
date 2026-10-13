import { LightningElement, track, wire, api } from "lwc";

import getBatchSettings from "@salesforce/apex/BatchesControlCmpController.getBatchSettings";
import getAllBatchSettings from "@salesforce/apex/BatchesControlCmpController.getAllBatchSettings";
import getProfiles from "@salesforce/apex/BatchesControlCmpController.getAllProfiles";
import saveMetadata from "@salesforce/apex/BatchesControlCmpController.saveMetadata";
import getColumns from "@salesforce/apex/BatchesControlCmpController.getBatchSettingsFields";
import getOrganizationWideAddresses from "@salesforce/apex/BatchesControlCmpController.getOrganizationWideAddresses";
import getPackagePrefix from "@salesforce/apex/NegoptimHelper.getPackagePrefix";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//labels
import LBL_Batches_Control from '@salesforce/label/c.LBL_Batches_Control';
import LBL_Batch_Name from '@salesforce/label/c.LBL_Batch_Name';
import LBL_Allow_Sending_Email from '@salesforce/label/c.LBL_Allow_Sending_Email';
import LBL_Allow_Sending_Email_Technical from '@salesforce/label/c.LBL_Allow_Sending_Email_Technical';
import LBL_Allow_Sending_Notification from '@salesforce/label/c.LBL_Allow_Sending_Notification';
import LBL_Activate_All from '@salesforce/label/c.LBL_Activate_All';
import LBL_Deactivate_All from '@salesforce/label/c.LBL_Deactivate_All';
import LBL_Disallow_Sending_Email from '@salesforce/label/c.LBL_Disallow_Sending_Email';
import LBL_Disallow_Sending_Email_Technical from '@salesforce/label/c.LBL_Disallow_Sending_Email_Technical';
import LBL_Disallow_Sending_Notification from '@salesforce/label/c.LBL_Disallow_Sending_Notification';
import MSG_Successfully_Saved from '@salesforce/label/c.MSG_Successfully_Saved';
import LBL_Search from '@salesforce/label/c.LBL_Search';
import LBL_Profile from '@salesforce/label/c.LBL_Profile';
import LBL_Cancel from '@salesforce/label/c.Cancel';
import LBL_Save from '@salesforce/label/c.Save';
import LBL_Reset from '@salesforce/label/c.LBL_Reset';
import LBL_Previous from '@salesforce/label/c.Previous';
import LBL_Next from '@salesforce/label/c.Next';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_None from '@salesforce/label/c.LBL_None';

/*import DeveloperName from '@salesforce/schema/Batch_Settings__mdt.DeveloperName';
import MasterLabel from '@salesforce/schema/Batch_Settings__mdt.MasterLabel';
import Active__c from '@salesforce/schema/Batch_Settings__mdt.Active__c';
import Allow_Sending_Email__c from '@salesforce/schema/Batch_Settings__mdt.Allow_Sending_Email__c';
import Allow_Sending_Email_Technical__c from '@salesforce/schema/Batch_Settings__mdt.Allow_Sending_Email_Technical__c';
import Description__c from '@salesforce/schema/Batch_Settings__mdt.Description__c';
import Sender__c from '@salesforce/schema/Batch_Settings__mdt.Sender__c';*/

const SEARCH_DELAY = 500;

export default class batchesControl extends LightningElement {

  /**
   * @description all variables that are used for matrix view and default view
   ****************************************************************************************************** */

  Label = {
    LBL_Batches_Control,
    LBL_Allow_Sending_Email,
    LBL_Allow_Sending_Email_Technical,
    LBL_Allow_Sending_Notification,
    LBL_Search,
    LBL_Profile,
    LBL_Batch_Name,
    LBL_Activate_All,
    LBL_Deactivate_All,
    LBL_Disallow_Sending_Email,
    LBL_Disallow_Sending_Email_Technical,
    LBL_Disallow_Sending_Notification,
    MSG_Successfully_Saved,
    LBL_Save,
    LBL_Reset,
    LBL_Cancel,
    LBL_Previous,
    LBL_Next,
    LBL_Last,
    LBL_None
  };
  selectedCopyFromProfileId;
  selectedCopyToProfileId;
  selectedBatch; //The batch which the user is choosing the sender address for
  TableHeightOnly = "max-height:450px;";
  draftValuesMap = new Map();
  @track draftValues;
  @track activeLabel;
  @track allowEmailLabel;
  @track allowEmailTechnicalLabel;
  @track allowSendingNotificationLabel;
  @track descriptionLabel;
  @track senderLabel;
  @track classNameLabel;
  @track isMatrix = false;
  @track showMenu = false;
  @track searchTerm = "";
  @track showLoadingSpinner = false;
  @track profileOptions = [];
  @track pending = true;
  @track controlChanges = false;


  // @api BackColor;
  // @api TextColor;
  // @track TableHeight = 650;

  matrixViewLaoded = false;
  manyProfileChanges = false;
  batchMailSettingsAppliedToAllProfilesList = [];

  @track mailSettingsToAllProfiles = false;

  /**
   * @description all variables used for default view
   ***************************************************************************************************** */
  @track classes;
  allClasses = [];
  batchSettingsMap = {};
  @track columns;
  @track sortBy;
  @track sortDirection;
  @track selectedProfileId;
  @track senderOptions = [];
  @track chosenEmail;
  @track emailSubjectMsg;
  @track openCopyMetadataModel = false;
  @track openChooseSenderModel = false;

  /**
   * @description all variables used for matrix view 
   ************************************************************************************************** */
  allClassesMatrix = [];
  batchSettingsMatrixMap = {};
  limit = 10;
  offset = 0;
  total;
  selectedRecords = [];
  searchResult = [];
  isSearching = false;

  @track classesMatrix;
  @track checkboxValues;
  @track limitOptions = [
    { label: 5, value: 5 },
    { label: 10, value: 10 },
    { label: 15, value: 15 }
  ];
  @track selectedLimit = 10;
  @track isNextDisabled = true;
  @track isLastDisabled = true;
  @track isPreviousDisabled = true;
  @track isFirstDisabled = true;
  normalizedAPIFields;

  connectedCallback() {
    this.showLoadingSpinner = true;
    let self = this;
    getPackagePrefix({ includeUnderscore: true }).then(result => {
      let prefix = result;
      self.normalizedAPIFields = {
        DeveloperName: 'DeveloperName',
        MasterLabel: 'MasterLabel',
        Active__c: prefix + 'Active__c',
        Allow_Sending_Email__c: prefix + 'Allow_Sending_Email__c',
        Allow_Sending_Email_Technical__c: prefix + 'Allow_Sending_Email_Technical__c',
        Allow_Sending_Notification__c: prefix + 'Allow_Sending_Notification__c',
        Description__c: prefix + 'Description__c',
        Sender__c: prefix + 'Sender__c',
        Email_Subject__c: prefix + 'Email_Subject__c',
        Profile_Id__c: prefix + 'Profile_Id__c',
      };

      addEventListener('resize', this.setPageSize);
    }).catch(error => {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: error.body.message,
        variant: 'error'
      }));
    });
    this.loadProfiles();
    this.loadBatchSettings();
    this.loadColumns();
    this.showLoadingSpinner = false;

  }
  renderedCallback() {
    try {
      this.setPageSize();
    } catch (error) {
      console.log('%c' + error.message, 'color : red');
      console.log('%c' + error.body?.message, 'color : red');
      // this.loading = true;
    }
  }
  setPageSize = () => {
    try {
      let mainContainer = this.template.querySelector(".mainContainer");
      // this.mainContainer = mainContainer;
      let pageHeader = this.template.querySelector(".headerDiv");
      let pagenormalViewTable = this.template.querySelector(".tableDiv");
      let tableDivContent = this.template.querySelector(".tableDivContent");
      let dataTableDivContent = this.template.querySelector(".dataTableDivContent");
      console.log('mainContainer: ' + mainContainer.offsetHeight);
      console.log('pageHeader: ' + pageHeader.offsetHeight);
      // console.log('pagenormalViewTable: ' + pagenormalViewTable.offsetHeight);
      // console.log('pageMatrixViewTable: ' + pageMatrixViewTable);
      if (
        mainContainer != null &&
        pageHeader != null

      ) {
        if (pagenormalViewTable != null) {
          pagenormalViewTable.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 20 + 'px';
          console.log('pagenormalViewTable:2 ' + pagenormalViewTable.offsetHeight);
        }
        if (dataTableDivContent != null) {
          dataTableDivContent.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 20 + 'px';
          console.log('dataTableDivContent:2 ' + dataTableDivContent.offsetHeight);
        }

        if (tableDivContent != null) {
          tableDivContent.style.height = mainContainer.offsetHeight - pageHeader.offsetHeight - 65 + 'px';
          console.log('tableDivContent:2 ' + tableDivContent.offsetHeight);
        }

      }

    } catch (error) {
      console.log('%c' + error.message, 'color : red');
      console.log('%c' + error.body?.message, 'color : red');
    }
  }
  disconnectedCallback() {
    this.showLoadingSpinner = false;
  }

  switchToMatrix() {
    this.isMatrix = !this.isMatrix;
    if (this.isMatrix) this.loadBatchSettings();
    this.controlChanges = false;
  }

  loadColumns() {
    getColumns().then(result => {
      var res = JSON.parse(JSON.stringify(result));
      this.classNameLabel = res[0];
      this.activeLabel = res[1];
      this.allowEmailLabel = res[2];
      this.descriptionLabel = res[3];
      this.allowEmailTechnicalLabel = res[4];
      this.allowSendingNotificationLabel = res[5];
      this.senderLabel = res[6];
      this.columns = [
        { label: this.classNameLabel, fieldName: 'MasterLabel', type: "text", sortable: "true" },
        { label: this.activeLabel, fieldName: 'Active', type: "boolean", sortable: "true", editable: "true" },
        { label: this.allowEmailLabel, fieldName: 'AllowSendingEmail', type: "boolean", sortable: "true", editable: "true" },
        { label: this.allowEmailTechnicalLabel, fieldName: 'AllowSendingEmailTechnical', type: "boolean", sortable: "true", editable: "true" },
        { label: this.allowSendingNotificationLabel, fieldName: 'AllowSendingNotification', type: "boolean", sortable: "true", editable: "true" },
        { label: this.descriptionLabel, fieldName: 'Description', type: "text", editable: "true" },
        { label: this.senderLabel, fieldName: 'Sender', type: "email" },
        {
          label: "", type: "button-icon", typeAttributes: {
            iconName: "utility:email",
            name: "chooseSender",
            disabled: false,
            value: "handleOpenChooseSenderModel"
          }, editable: "true"
        }
      ];
    }).catch(error => {
      this.toastMessage("error", "Error", error.message, "dismissable");
    });
    this.showLoadingSpinner = false;
  }

  /**
   * @matrixView
   * @description loads the batch settings from the apex class for matrix view
   * @var classesMatrix all the batch classes returned
   * @var allClassesMatrix all the batch classes returned (to compare to the original list when saving and searching)
   * @var checkboxValues array for the checkboxes inside the table
   * @var batchSettingsMap map for batch settings: key = developerName, value = BatchSettingsWrapper
   * BatchSettingsWrapper: key = className, value = batchSettings value, total = number of batches returned
   */
  loadBatchSettings() {
    var self = this;
    if (this.isMatrix) {
      self.showLoadingSpinner = true;
      if (!self.matrixViewLaoded) {
        getAllBatchSettings({ datalimit: 0, offset: 0 }).then(result => {
          self.allClassesMatrix = JSON.parse(JSON.stringify(result));
          if (Object.getOwnPropertyNames(self.draftValuesMap).length > 0) {
            self.allClassesMatrix = self.allClassesMatrix.map(item => {
              item.value = item.value.map(item2 => {
                if (self.draftValuesMap[item2.DeveloperName] != undefined) {
                  let batch = self.draftValuesMap[item2.DeveloperName];
                  item2 = Object.assign(JSON.parse(JSON.stringify(item2)), batch);
                }
                return item2;
              });
              return item;
            });
          }
          self.total = self.allClassesMatrix.length;
          self.getClasses();
          self.batchSettingsMap = {};
          self.checkboxValues = [];
          for (var index = 0; index < self.allClassesMatrix.length; index++) {
            self.batchSettingsMap[self.allClassesMatrix[index].key] = self.allClassesMatrix[index].value;
            var ck = { className: self.allClassesMatrix[index].key, checked: false };
            self.checkboxValues.push(ck);
            for (var index2 = 0; index2 < self.allClassesMatrix[index].value.length; index2++) {
              self.batchSettingsMatrixMap[self.allClassesMatrix[index].value[index2].DeveloperName] = self.allClassesMatrix[index].value[index2];
            }
          }
          self.handlePagination(self.total);
          self.search();
          self.matrixViewLaoded = true;
          self.showLoadingSpinner = false;
        }).catch(error => {
          self.toastMessage("error", "Error", error.message, "dismissable");
          console.log("error: " + error);
          self.showLoadingSpinner = false;
        });

      } else {
        self.showLoadingSpinner = false;
      }
    }
  }

  handlePagination(total) {
    /* Pagination:  */
    let remainder = total % this.selectedLimit;
    let totalPages;
    if (remainder > 0) {
      totalPages = parseInt(total / this.selectedLimit, 10) + 1;
    } else {
      totalPages = parseInt(total / this.selectedLimit, 10);
    }
    let page = parseInt(this.offset / this.selectedLimit, 10) + 1;
    if (totalPages === 0) {
      totalPages++;
    }
    this.message = (((page - 1) * this.selectedLimit) + 1) + " - " + ((page) * this.selectedLimit < total ? (page) * this.selectedLimit : total) + " of " + total;
    this.isPreviousDisabled = true;
    this.isNextDisabled = true;
    this.isLastDisabled = true;
    this.isFirstDisabled = true;
    if (page === totalPages && page > 1) {
      this.isPreviousDisabled = false;
      this.isFirstDisabled = false;
      this.isNextDisabled = true;
      this.isLastDisabled = true;
    } else if (totalPages > page && page === 1) {
      this.offset = 0;
      this.isNextDisabled = false;
      this.isLastDisabled = false;
    } else if (totalPages > page && page > 1) {
      this.isPreviousDisabled = false;
      this.isNextDisabled = false;
      this.isLastDisabled = false;
      this.isFirstDisabled = false;
    } else if (totalPages === page && page === 1) {
      this.isPreviousDisabled = true;
      this.isNextDisabled = true;
      this.isLastDisabled = true;
      this.isFirstDisabled = true;
    }
  }

  getClasses() {
    if (this.isSearching) {
      this.classesMatrix = this.searchResult.slice(this.offset, this.selectedLimit + this.offset);
    } else {
      this.classesMatrix = this.allClassesMatrix.slice(this.offset, this.selectedLimit + this.offset);
    }
    //this.classesMatrix = this.allClassesMatrix.slice(this.selectedLimit);
  }

  /**
   * @allViews
   * @description loads profiles from apexclass
   * @var profileOptions the options in all the comboboxes and the profile column in the matrix view
   */
  loadProfiles() {
    if (this.profileOptions.length == 0) {
      var self = this;
      getProfiles().then(result => {
        let options = [];
        for (var j in result) {
          options.push({ label: result[j].Name, value: result[j].Id });
        }
        self.profileOptions = options;
      });
    }
  }

  /**
   * @defaultView
   * @description loads the batchSettings from the apex class of a selected profile for default view
   * @var batchSettingsMap map for batch settings: key = developerName, value = values of the batchSettings
   * @var profileId the selected profile
   * @var classes all the batch classes returned
   * @var allClasses all the batch classes returned (to compare to the original list when searching and saving)
   */
  handleProfileChange(event) {
    this.showLoadingSpinner = true;
    this.batchSettingsMap = {};
    this.selectedProfileId = event.detail.value;
    var self = this;
    getBatchSettings({ profileId: self.selectedProfileId }).then(result => {
      self.classes = JSON.parse(JSON.stringify(result));
      self.allClasses = JSON.parse(JSON.stringify(result));
      for (var index = 0; index < self.allClasses.length; index++) {
        self.batchSettingsMap[self.allClasses[index].DeveloperName] = self.allClasses[index];
      }
      if (self.searchTerm != null || self.searchTerm != '') {
        self.search();
      }
      self.sortData('MasterLabel', 'asc');
    }).catch(error => {
      self.toastMessage("error", "Error", error.body.message, "dismissable");
    });
    self.showLoadingSpinner = false;
  }

  /**
   * @defaultView
   * @description loads all the OrganizationWideAddresses from the apex class
   * @var senderOptions the options that holds the email addresses for the combobox
   */
  loadEmails() {
    if (this.senderOptions.length == 0) {
      var self = this;
      getOrganizationWideAddresses().then(result => {
        let options = [];
        for (var j in result) {
          options.push({ label: result[j].Address, value: result[j].Address });
        }
        self.senderOptions = options;
        self.senderOptions.unshift({ label: this.Label.LBL_None, value: '' });
      });
    }
  }

  /**
   * @allViews
   * @description handle search for matrix and default view 
   */
  handleSearchChange(event) {
    var self = this;
    this.searchTerm = event.target.value;
    this.delayTimeout = setTimeout(() => {
      self.search();
      this.sortData('MasterLabel', 'asc');
    }, SEARCH_DELAY);
  }

  /**
   * @allViews
   * @description get the batch classes of the input searchTerm
   */
  search() {
    var self = this;
    this.showLoadingSpinner = true;
    if (this.isMatrix) {
      if (this.searchTerm == "" || this.searchTerm == null) {
        this.isSearching = false;
        this.getClasses();
        this.handleFirst();
        //this.handlePagination(this.total);
      } else {
        self.isSearching = true;
        self.searchResult = self.allClassesMatrix.filter(function (item) {
          return ((item.key && item.key.toLowerCase().includes(self.searchTerm.toLowerCase())));
        });
        self.getClasses();
        this.handlePagination(this.searchResult.length);
      }
      self.showLoadingSpinner = false;
    } else {
      if (this.searchTerm == "" || this.searchTerm == null) {
        this.classes = this.allClasses;
      }
      self.classes = self.allClasses.filter(function (item) {
        return ((item.MasterLabel && item.MasterLabel.toLowerCase().includes(self.searchTerm.toLowerCase())) ||
          (item.Description && item.Description.toLowerCase().includes(self.searchTerm.toLowerCase())));
      });
      this.showLoadingSpinner = false;
    }
  }

  /**
   * @defaultView
   * @description to save the changes of datatable
   */
  save(event) {
    this.selectedRecords = [];
    this.template.querySelector('lightning-datatable').selectedRows = [];
    this.saveData();
    this.draftValuesMap = {};
    this.refreshDraftValues();
  }

  /**
   * @defaultView
   * @description to reset the changes of datatable
   */
  reset() {
    let self = this;
    self.showLoadingSpinner = true;
    setTimeout(function () {
      self.selectedRecords = [];
      self.template.querySelector('lightning-datatable').selectedRows = [];
      self.draftValuesMap = {};
      self.refreshDraftValues();
      this.batchSettingsMap = {};
      getBatchSettings({ profileId: self.selectedProfileId }).then(result => {
        self.classes = JSON.parse(JSON.stringify(result));
        self.allClasses = JSON.parse(JSON.stringify(result));
        for (var index = 0; index < self.allClasses.length; index++) {
          self.batchSettingsMap[self.allClasses[index].DeveloperName] = self.allClasses[index];
        }
        self.sortData('MasterLabel', 'asc');
      }).catch(error => {
        self.toastMessage("error", "Error", error.message, "dismissable");
      });
      self.draftValues = [];
      self.showLoadingSpinner = false;
    }, 250);
  }

  /**
   * @matrixView
   * @description to put the the selected batchSetings inside selectedRecords
   * @var selectedRecords list for all the edited records
   */
  onchangeChecked(event) {
    let className = event.currentTarget.dataset.recordid;
    let checked = event.currentTarget.checked;
    if (checked) {
      for (var i in this.batchSettingsMap[className]) {
        this.selectedRecords.push(this.batchSettingsMap[className][i]);
      }
    } else {
      for (var i in this.batchSettingsMap[className]) {
        let index = this.selectedRecords.indexOf(this.batchSettingsMap[className][i]);
        this.selectedRecords.splice(index, 1);
      }
    }
  }

  /**
   * @matrixView
   * @description to get the the batchSetings in which active is checked
   */
  onchangeActiveChecked(event) {
    this.controlChanges = true;
    var batch = this.batchSettingsMatrixMap[event.currentTarget.dataset.recordid];
    let newObj = {};
    newObj.DeveloperName = batch.DeveloperName;
    newObj.Active = !batch.Active;
    let oldObj = this.draftValuesMap.hasOwnProperty(batch.DeveloperName) ? this.draftValuesMap[batch.DeveloperName] : {};
    this.draftValuesMap[batch.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
    this.refreshDraftValues();
    this.allClassesMatrix.forEach(item => {
      if (item.key == batch.MasterLabel) {
        item.value.forEach(item2 => {
          if (item2.DeveloperName == batch.DeveloperName) {
            item2.Active = !batch.Active;
          }
        });
      }
    });
  }

  /**
   * @matrixView
   * @description to get the the batchSetings in which email is checked
   */
  onchangeEmailChecked(event) {
    this.controlChanges = true;
    var batch = this.batchSettingsMatrixMap[event.currentTarget.dataset.recordid];
    let newObj = {};
    newObj.DeveloperName = batch.DeveloperName;
    newObj.AllowSendingEmail = !batch.AllowSendingEmail;
    let oldObj = this.draftValuesMap.hasOwnProperty(batch.DeveloperName) ? this.draftValuesMap[batch.DeveloperName] : {};
    this.draftValuesMap[batch.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
    this.refreshDraftValues();
    this.allClassesMatrix.forEach(item => {
      if (item.key == batch.MasterLabel) {
        item.value.forEach(item2 => {
          if (item2.DeveloperName == batch.DeveloperName) {
            item2.AllowSendingEmail = !batch.AllowSendingEmail;
          }
        });
      }
    });
  }

  /**
   * @matrixView
   * @description to get the batchSetings in which email technical is checked
   */
  onchangeEmailTechnicalChecked(event) {
    this.controlChanges = true;
    var batch = this.batchSettingsMatrixMap[event.currentTarget.dataset.recordid];
    let newObj = {};
    newObj.DeveloperName = batch.DeveloperName;
    newObj.AllowSendingEmailTechnical = !batch.AllowSendingEmailTechnical;
    let oldObj = this.draftValuesMap.hasOwnProperty(batch.DeveloperName) ? this.draftValuesMap[batch.DeveloperName] : {};
    this.draftValuesMap[batch.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
    this.refreshDraftValues();
    this.allClassesMatrix.forEach(item => {
      if (item.key == batch.MasterLabel) {
        item.value.forEach(item2 => {
          if (item2.DeveloperName == batch.DeveloperName) {
            item2.AllowSendingEmailTechnical = !batch.AllowSendingEmailTechnical;
          }
        });
      }
    });
  }

  /**
   * @matrixView
   * @description to get the batchSetings in which notification is checked
   */
  onchangeSendingNotificationChecked(event) {
    this.controlChanges = true;
    var batch = this.batchSettingsMatrixMap[event.currentTarget.dataset.recordid];
    let newObj = {};
    newObj.DeveloperName = batch.DeveloperName;
    newObj.AllowSendingNotification = !batch.AllowSendingNotification;
    let oldObj = this.draftValuesMap.hasOwnProperty(batch.DeveloperName) ? this.draftValuesMap[batch.DeveloperName] : {};
    this.draftValuesMap[batch.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
    this.refreshDraftValues();
    this.allClassesMatrix.forEach(item => {
      if (item.key == batch.MasterLabel) {
        item.value.forEach(item2 => {
          if (item2.DeveloperName == batch.DeveloperName) {
            item2.AllowSendingNotification = !batch.AllowSendingNotification;
          }
        });
      }
    });
  }

  /**
   * @allViews
   * @description to activate all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings 
   */
  handleActivateSelected() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (!item.Active || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('Active') && !this.draftValuesMap[item.DeveloperName].Active)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.Active = true;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || self.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (!item2.Active) {
                    item2.Active = true;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to deactivate all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleDeactivateSelected() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (item.Active || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('Active') && this.draftValuesMap[item.DeveloperName].Active)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.Active = false;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (item2.Active) {
                    item2.Active = false;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to allow email for all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleAllowEmailSelected() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (!item.AllowSendingEmail || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingEmail') && !this.draftValuesMap[item.DeveloperName].AllowSendingEmail)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingEmail = true;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (!item.AllowSendingEmail) {
                    item2.AllowSendingEmail = true;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to disallow all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleDisallowEmailSelected() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (item.AllowSendingEmail || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingEmail') && this.draftValuesMap[item.DeveloperName].AllowSendingEmail)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingEmail = false;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (item.AllowSendingEmail) {
                    item2.AllowSendingEmail = false;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to allow technical email for all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleAllowEmailSelectedDev() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (!item.AllowSendingEmailTechnical || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingEmailTechnical') && !this.draftValuesMap[item.DeveloperName].AllowSendingEmailTechnical)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingEmailTechnical = true;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (!item.AllowSendingEmailTechnical) {
                    item2.AllowSendingEmailTechnical = true;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to disallow technical email all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleDisallowEmailSelectedDev() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (item.AllowSendingEmailTechnical || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingEmailTechnical') && this.draftValuesMap[item.DeveloperName].AllowSendingEmailTechnical)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingEmailTechnical = false;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (item.AllowSendingEmailTechnical) {
                    item2.AllowSendingEmailTechnical = false;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to allow technical email for all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleAllowSendingNotification() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (!item.AllowSendingNotification || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingNotification') && !this.draftValuesMap[item.DeveloperName].AllowSendingNotification)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingNotification = true;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (!item.AllowSendingNotification) {
                    item2.AllowSendingNotification = true;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @allViews
   * @description to disallow technical email all the selected batchSettings
   * @var selectedRecords list for all the selected batchSettings
   */
  handleDisallowSendingNotification() {
    let self = this;
    if (this.selectedRecords && this.selectedRecords.length > 0) {
      this.selectedRecords.forEach(item => {
        if (item.AllowSendingNotification || (this.draftValuesMap.hasOwnProperty(item.DeveloperName) && this.draftValuesMap[item.DeveloperName].hasOwnProperty('AllowSendingNotification') && this.draftValuesMap[item.DeveloperName].AllowSendingNotification)) {
          let newObj = {};
          newObj.DeveloperName = item.DeveloperName;
          newObj.AllowSendingNotification = false;
          let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
          self.draftValuesMap[item.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
          if (this.isMatrix || this.allClassesMatrix != null) {
            this.allClassesMatrix.forEach(item1 => {
              if (item1.key == item.MasterLabel) {
                item1.value.forEach(item2 => {
                  if (item.AllowSendingNotification) {
                    item2.AllowSendingNotification = false;
                    this.draftValuesMap[item2.DeveloperName] = Object.assign(JSON.parse(JSON.stringify(oldObj)), newObj);
                  }
                });
              }
            });
            this.controlChanges = true;
            this.getClasses();
          }
        }
      });
      this.refreshDraftValues();
    } else {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    }
  }

  /**
   * @defaultView
   * @description to get all the selected rows in the datatable
   * @var selectedRecords list for all the selected batchSettings
   */
  getSelectedRecords(event) {
    if (this.isMatrix && this.selectedRecord == []) {
      this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
    } else {
      // getting selected rows
      this.selectedRecords = [];
      const selectedRows = event.detail.selectedRows;
      for (var i = 0; i < selectedRows.length; i++) {
        this.selectedRecords.push(selectedRows[i]);
      }
    }
  }

  /**
   * @matrixView
   * @description to save all the changes inside the table
   */
  handleSave(event, error) {
    this.saveDataMatrix();
    if (error) {
      console.log(error.message);
      this.toastMessage("error", "Error", error.message, "dismissable");
    }
    this.controlChanges = false;
  }

  /**
   * @matrixView
   * @description to cancel all the changes inside the table
   */
  handleCancel(event, error) {
    let self = this;
    // setTimeout(function () {
    self.classesMatrix = [];
    self.allClassesMatrix = [];
    self.selectedRecords = [];
    self.draftValuesMap = {};
    self.refreshDraftValues();
    self.draftValues = [];
    self.showLoadingSpinner = true;
    getAllBatchSettings({ datalimit: 0, offset: 0 }).then(result => {
      self.allClassesMatrix = JSON.parse(JSON.stringify(result));
      self.getClasses();
      self.showLoadingSpinner = false;
      self.controlChanges = false;
    });
    //}, 250);
    if (error) {
      console.log(error.message);
      this.toastMessage("error", "Error", error.message, "dismissable");
      this.controlChanges = false;
    }
  }

  handleSortdata(event) {
    if (this.selectedProfileId == null) {

    } else {
      // field name
      this.sortBy = event.detail.fieldName;
      // sort direction
      this.sortDirection = event.detail.sortDirection;
      // calling sortdata function to sort the data based on direction and selected field
      this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
  }

  sortData(fieldname, direction) {
    if (this.isMatrix) {

    } else {
      // serialize the data before calling sort function
      let parseData = JSON.parse(JSON.stringify(this.classes));
      // Return the value stored in the field
      let keyValue = a => {
        return a[fieldname];
      };
      // cheking reverse direction
      let isReverse = direction === "asc" ? 1 : -1;
      // sorting data
      parseData.sort((x, y) => {
        x = keyValue(x) ? keyValue(x) : ""; // handling null values
        y = keyValue(y) ? keyValue(y) : "";
        // sorting values based on direction
        return isReverse * ((x > y) - (y > x));
      });
      // set the sorted data to data table data
      this.classes = parseData;
    }

  }

  /**
   * @defaultView
   * @description to save all the changes to the database
   * @var batchSettingsMap the map of all the batchSettings before the changes
   */
  saveData() {
    let self = this;
    this.showLoadingSpinner = true;
    let saveBatchSettingsList = [];
    //let classesNames = this.allClasses.map(obj => obj.MasterLabel);
    if (this.manyProfileChanges) {
      //console.log('batchMailSettingsAppliedToAllProfilesList >>>>> ' + this.batchMailSettingsAppliedToAllProfilesList);
      //classesNames.forEach(item => {
      this.batchMailSettingsAppliedToAllProfilesList.forEach(item => {
        let settings = self.allClassesMatrix.filter(obj => obj.key == item);
        if (settings.length > 0) {
          let oldObjs = settings[0].value;
          for (var setting of oldObjs) {
            if (this.draftValuesMap.hasOwnProperty(setting.DeveloperName)) {
              let newObj = JSON.parse(JSON.stringify(this.draftValuesMap[setting.DeveloperName]));
              newObj = Object.assign(JSON.parse(JSON.stringify(setting)), newObj);
              if (JSON.stringify(setting) != JSON.stringify(newObj)) {
                saveBatchSettingsList.push(newObj);
              }
            }
          }
        }
      }
      )
    } else {
      this.allClasses.forEach(item => {
        if (self.draftValuesMap.hasOwnProperty(item.DeveloperName)) {
          let newObj = JSON.parse(JSON.stringify(self.draftValuesMap[item.DeveloperName]));
          newObj = Object.assign(JSON.parse(JSON.stringify(item)), newObj);
          if (JSON.stringify(item) != JSON.stringify(newObj)) {
            saveBatchSettingsList.push(newObj);
          }
        }
      });
    }

    if (this.allClassesMatrix.length > 0) {
      this.allClassesMatrix.forEach(batchList => {
        batchList.value.forEach(item => {
          if (self.draftValuesMap.hasOwnProperty(item.DeveloperName)) {
            item.Active = self.draftValuesMap[item.DeveloperName].Active != undefined ? self.draftValuesMap[item.DeveloperName].Active : item.Active;
            item.AllowSendingEmail = self.draftValuesMap[item.DeveloperName].AllowSendingEmail != undefined ? self.draftValuesMap[item.DeveloperName].AllowSendingEmail : item.AllowSendingEmail;
            item.AllowSendingEmailTechnical = self.draftValuesMap[item.DeveloperName].AllowSendingEmailTechnical != undefined ? self.draftValuesMap[item.DeveloperName].AllowSendingEmailTechnical : item.AllowSendingEmailTechnical;
            item.AllowSendingNotification = self.draftValuesMap[item.DeveloperName].AllowSendingNotification != undefined ? self.draftValuesMap[item.DeveloperName].AllowSendingNotification : item.AllowSendingNotification;
          }
        });
      });
    }

    this.showLoadingSpinner = false;
    this.manyProfileChanges = false;
    this.batchMailSettingsAppliedToAllProfilesList = [];
    // save batch settings
    var jsonBatchesSettings = JSON.stringify(saveBatchSettingsList);
    saveMetadata({ jsonBatchesSettings: jsonBatchesSettings })
      .then(result => {
        var key;
        var key2;
        //modify the lists to the new batchSettings
        for (key in self.allClasses) {
          for (key2 in saveBatchSettingsList) {
            if (self.allClasses[key].DeveloperName == saveBatchSettingsList[key2].DeveloperName) {
              self.allClasses[key] = saveBatchSettingsList[key2];
              self.batchSettingsMap[self.allClasses[key].DeveloperName] = saveBatchSettingsList[key2];
            }
          }
        }
        self.search();
        this.sortData('MasterLabel', 'asc');
        self.toastMessage("success", "Success", MSG_Successfully_Saved, "dismissable");
      })
      .catch(error => {
        self.toastMessage("error", "Error", error.message, "dismissable");
        console.error(error.message);
      })
      .finally(() => {
        this.pending = false
      });
    /*
  } else {
  this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
  }*/
  }

  /**
   * @matrixView
   * @description to save all the changes to the database
   * @var batchSettingsMatrixMap the map of all the batchSettings before the changes
   */
  saveDataMatrix() {
    let self = this;
    this.showLoadingSpinner = true;
    let saveBatchSettingsList = [];
    this.allClassesMatrix.forEach(batchList => {
      batchList.value.forEach(item => {
        if (self.draftValuesMap.hasOwnProperty(item.DeveloperName)) {
          let newObj = JSON.parse(JSON.stringify(self.draftValuesMap[item.DeveloperName]));
          newObj = Object.assign(JSON.parse(JSON.stringify(item)), newObj);
          saveBatchSettingsList.push(newObj);
        }
      });
    });
    this.showLoadingSpinner = false;
    // save batch settings
    var jsonBatchesSettings = JSON.stringify(saveBatchSettingsList);
    saveMetadata({ jsonBatchesSettings: jsonBatchesSettings }).then(result => {
      var key;
      var key2;
      var ind = 0;
      for (key in self.allClassesMatrix) {
        for (key2 in saveBatchSettingsList) {
          ind++;
          if (self.allClassesMatrix[key].value.DeveloperName == saveBatchSettingsList[key2].DeveloperName) {
            self.allClassesMatrix[key].value = saveBatchSettingsList[key2];
            self.batchSettingsMatrixMap[self.allClassesMatrix[key].key] = saveBatchSettingsList[key2];
          }
        }
      }
      self.search();
      this.sortData('MasterLabel', 'asc');
      self.toastMessage("success", "Success", MSG_Successfully_Saved, "dismissable");
    }).catch(error => {
      self.toastMessage("error", "Error", error.message, "dismissable");
      console.log(error.message);
    }).finally(() => {
      this.pending = false
    });
    /* } else {
       this.toastMessage("info", "Info", "Please select at least one record", "dismissable");
     }*/
    this.showLoadingSpinner = false;
  }

  /**
   * @defaultView
   * @description open the model to choose the sender for a batchSetting
   * @var selectedBatch the batch for which the sender is selected
   */
  handleOpenChooseSenderModel(event) {
    this.openChooseSenderModel = true;
    this.selectedBatch = event.detail.row;
    if (this.selectedBatch.hasOwnProperty('Sender')) {
      this.chosenEmail = this.selectedBatch['Sender'];
    }
    this.emailSubjectMsg = this.selectedBatch.hasOwnProperty('EmailSubject') ? this.selectedBatch['EmailSubject'] : '';
    this.loadEmails();
  }

  /**
   * @defaultView
   * @description get the selected sender
   * @var chosenEmail the selected sender
   */
  handleSenderEmailSelected(event) {
    this.chosenEmail = event.detail.value;
    this.selectedBatch.Sender = this.chosenEmail;
  }

  handleEmailSubjectChanged(event) {
    this.emailSubjectMsg = event.detail.value;
    this.selectedBatch.EmailSubject = this.emailSubjectMsg;
  }

  handleApplyMailSettingsToAllProfile(event) {
    this.mailSettingsToAllProfiles = !this.mailSettingsToAllProfiles;
  }

  closeChooseSender() {
    this.openChooseSenderModel = false;
    this.emailSubjectMsg = '';
    this.chosenEmail = '';
    this.mailSettingsToAllProfiles = false;
  }

  /**
   * @defaultView
   * @description save the selected sender 
   */
  saveEmailMetadata() {
    this.selectedBatch.Sender = this.chosenEmail;
    this.selectedBatch.EmailSubject = this.emailSubjectMsg;
    if (this.mailSettingsToAllProfiles) {
      if (this.allClassesMatrix.length == 0) {
        getAllBatchSettings({ datalimit: 0, offset: 0 }).then(result => {
          this.allClassesMatrix = JSON.parse(JSON.stringify(result));
        })
      }
      this.manyProfileChanges = this.mailSettingsToAllProfiles;
      this.batchMailSettingsAppliedToAllProfilesList.push(this.selectedBatch.MasterLabel);
      this.applyMailSettingsToAllProfiles(this.selectedBatch.DeveloperName.replace(this.selectedBatch.ProfileId, ''));
    }
    var batch = this.selectedBatch;
    var newObj = {};
    newObj.DeveloperName = this.selectedBatch.DeveloperName;
    newObj.Sender = this.selectedBatch.Sender;
    newObj.EmailSubject = this.selectedBatch.EmailSubject
    let oldObj = this.draftValuesMap.hasOwnProperty(newObj.DeveloperName) ? this.draftValuesMap[newObj.DeveloperName] : {};
    this.draftValuesMap[newObj.DeveloperName] = Object.assign(oldObj, newObj);
    this.refreshDraftValues();
    this.openChooseSenderModel = false;
    this.chosenEmail = '';
    this.emailSubjectMsg = '';
    this.mailSettingsToAllProfiles = false;
  }

  applyMailSettingsToAllProfiles(batch) {
    let profileIds = this.profileOptions.map(obj => obj.value);
    try {
      for (var profile of profileIds) {
        var newObj = {};
        newObj.DeveloperName = batch + '' + profile;
        newObj.Sender = this.chosenEmail;
        newObj.EmailSubject = this.emailSubjectMsg;
        let oldObj = this.draftValuesMap.hasOwnProperty(newObj.DeveloperName) ? this.draftValuesMap[newObj.DeveloperName] : {};
        this.draftValuesMap[newObj.DeveloperName] = Object.assign(oldObj, newObj);
      }
      this.refreshDraftValues();
    } catch (error) {
      console.log('exception    >>> ' + JSON.stringify(error));
    }
  }

  handleOpenCopyMetadataModel() {
    this.openCopyMetadataModel = true;
    this.loadProfiles();
  }

  handleCopyFromSelected(event) {
    this.selectedCopyFromProfileId = event.detail.value;
  }

  handleCopyToSelected(event) {
    this.selectedCopyToProfileId = event.detail.value;
  }

  closeCopyMetadataModel() {
    this.openCopyMetadataModel = false;
  }

  saveCopyMetadata() {
    alert('save method invoked');
    var copyFromBatchSettings = [];
    var copyToBatchSettings = [];
    var copyFromBatchSettingsMap = {};
    var copyToBatchSettingsMap = {};
    var self = this;
    getBatchSettings({ profileId: this.selectedCopyFromProfileId }).then(result => {
      copyFromBatchSettings = JSON.parse(JSON.stringify(result));
      for (var index = 0; index < copyFromBatchSettings.length; index++) {
        copyFromBatchSettingsMap[copyFromBatchSettings[index].DeveloperName] = copyFromBatchSettings[index];
      }
      getBatchSettings({ profileId: this.selectedCopyToProfileId }).then(result => {
        copyToBatchSettings = JSON.parse(JSON.stringify(result));
        for (var index = 0; index < copyToBatchSettings.length; index++) {
          copyToBatchSettingsMap[copyToBatchSettings[index].DeveloperName] = copyToBatchSettings[index];
        }
        var key;
        var key2;
        for (key in copyToBatchSettings) {
          for (key2 in copyFromBatchSettings) {
            var newObj = {};
            newObj.DeveloperName = copyToBatchSettings[key].DeveloperName;
            if (copyToBatchSettings[key].MasterLabel == copyFromBatchSettings[key2].MasterLabel) {
              if (copyFromBatchSettings[key2].Active != copyToBatchSettings[key].Active) {
                copyToBatchSettings[key].Active = copyFromBatchSettings[key2].Active;
                newObj.Active = copyFromBatchSettings[key2].Active;
              }
              if (copyFromBatchSettings[key2].Sender != copyToBatchSettings[key].Sender) {
                copyToBatchSettings[key].Sender = copyFromBatchSettings[key2].Sender;
                newObj.Sender = copyFromBatchSettings[key2].Sender;
              }
              if (copyFromBatchSettings[key2].AllowSendingEmail != copyToBatchSettings[key].AllowSendingEmail) {
                copyToBatchSettings[key].AllowSendingEmail = copyFromBatchSettings[key2].AllowSendingEmail;
                newObj.AllowSendingEmail = copyFromBatchSettings[key2].AllowSendingEmail;
              }
              if (copyFromBatchSettings[key2].AllowSendingEmailTechnical != copyToBatchSettings[key].AllowSendingEmailTechnical) {
                copyToBatchSettings[key].AllowSendingEmailTechnical = copyFromBatchSettings[key2].AllowSendingEmailTechnical;
                newObj.AllowSendingEmailTechnical = copyFromBatchSettings[key2].AllowSendingEmailTechnical;
              }
              let oldObj = this.draftValuesMap.hasOwnProperty(newObj.DeveloperName) ? this.draftValuesMap[newObj.DeveloperName] : {};
              this.draftValuesMap[newObj.DeveloperName] = Object.assign(oldObj, newObj);
            }
          }
          this.refreshDraftValues();
          this.closeCopyMetadataModel();
        }
      }).catch(error => {
        this.toastMessage("error", "Error", error.message, "dismissable");
      });
    }).catch(error => {
      this.toastMessage("error", "Error", error.message, "dismissable");
    });
  }


  toggleMenu() {
    this.showMenu = !this.showMenu;
  }

  handleLimit(event) {
    this.selectedLimit = parseInt(event.target.value, 10);
    this.selectedLimit = parseInt(this.selectedLimit, 10);
    this.offset = 0;
    //this.loadBatchSettings();
    this.getClasses();
    this.handlePagination(this.total);
  }

  handlePrevious(event) {
    if (parseInt(this.offset - this.selectedLimit, 10) >= 0) {
      this.offset -= parseInt(this.selectedLimit, 10);
      this.getClasses();
      this.handlePagination(this.total);
    }
  }

  handleFirst(event) {
    this.offset = 0;
    this.getClasses();
    this.handlePagination(this.total);
  }

  handleLast(event) {
    let remainder = this.total % this.selectedLimit;
    let totalPages;
    if (remainder > 0) {
      totalPages = parseInt(this.total / this.selectedLimit, 10);
    } else {
      totalPages = parseInt(this.total / this.selectedLimit, 10) - 1;
    }
    this.offset = parseInt(this.selectedLimit * totalPages, 10);
    //this.loadBatchSettings();
    this.getClasses();
    this.handlePagination(this.total);
  }

  handleNext(event) {
    let next = parseInt(this.offset + this.selectedLimit, 10);
    if (next < this.total) {
      this.offset += parseInt(this.selectedLimit, 10);
      //this.loadBatchSettings();
      this.getClasses();
      this.handlePagination(this.total);
    }
  }

  toastMessage(messageType, title, message, mode) {
    this.showLoadingSpinner = false;
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: messageType,
      mode: mode
    });
    this.dispatchEvent(evt);
  }

  // get mainTableInlineCss() {
  //   let style = '';
  //   if (this.BackColor) {
  //     style = style + "background-color:" + this.BackColor + ";";
  //   }
  //   if (this.TextColor) {
  //     style = style + "color:" + this.TextColor + ";";
  //   }
  //   return style;
  // }

  // get textColorInlineCss() {
  //   let style = '';
  //   if (this.TextColor) {
  //     style = style + "color: " + this.TextColor + ";";
  //   }
  //   return style;
  // }

  // get tableHeightInlineCss() {
  //   let style = '';
  //   if (this.TableHeight) {
  //     style = style + "height: " + this.TableHeight + "px;";
  //     var size = this.TableHeight - 150;
  //     this.TableHeightOnly = "max-height:" + size + "px;";
  //   }
  //   return style;
  // }

  // get tableHeight() {
  //   return this.TableHeightOnly;
  // }

  genericChangeHandler(event) {
    let self = this;
    event.detail.draftValues.forEach(item => {
      let newObj = item;
      let oldObj = self.draftValuesMap.hasOwnProperty(item.DeveloperName) ? self.draftValuesMap[item.DeveloperName] : {};
      self.draftValuesMap[item.DeveloperName] = Object.assign(oldObj, newObj);
    });
    this.refreshDraftValues();
  }

  refreshDraftValues() {
    this.draftValues = Object.keys(this.draftValuesMap).map(key => {
      return this.draftValuesMap[key];
    });
  }
}