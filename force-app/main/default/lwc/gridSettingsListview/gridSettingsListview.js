import { api, LightningElement, track } from 'lwc';
import getObjects from "@salesforce/apex/GridSettingsListViewCmpController.getObjects";
import Templates from "@salesforce/apex/GridSettingsListViewCmpController.Templates";
import save from "@salesforce/apex/GridSettingsListViewCmpController.save";
import checkDeploymentStatus from "@salesforce/apex/GridSettingsListViewCmpController.checkDeploymentStatus";
import { Labels, toastInfo, toastError, toastSuccess, array_move_one_item, addToArrayIfDoesntExist, trimDeveloperName, trimRegex } from "c/gridSettingsHelper";

export default class GridSettingsListview extends LightningElement {
  Label = Labels;
  @api cancelEvent;
  @api saveEvent;
  @track objectName;
  @track listViews;
  @track showTemplates = false;
  @track loading = true;
  @track selectedTemplates = [];
  @track allTemplates = [];
  initSelected = [];
  templatesName = [];

  connectedCallback() {
    this.loading = true;
    getObjects()
      .then(result => {
        const parsedResult = JSON.parse(result);
        this.listViews = parsedResult.map(item => {
          return {
            label: item.label,
            value: item.value
          };
        });
        this.loading = false;
      }).catch(error => {
        console.log("🚀 ~ GridSettingsListview ~ handleShowObject ~ error:", error);
        this.loading = false;
      })
  }

  handleObjectChange(event) {
    this.objectName = event.detail.value;
    Templates({ objectName: this.objectName })
      .then(result => {
        this.allTemplates = [];
        this.selectedTemplates = [];
        this.initSelected = [];
        this.templatesName = JSON.parse(result).sort((a, b) => a.order - b.order);
        this.templatesName.forEach(template => {
          this.allTemplates.push({ label: template.label, value: template.name });
          if (template.isSelected) {
            this.selectedTemplates.push(template.name);
            this.initSelected.push(template.name);
          }
        })
        if (this.selectedTemplates.length > 0) {
          this.selectedTemplates.sort((a, b) => a.order - b.order);
        }
      }).catch(error => {
        console.log("🚀 ~ GridSettingsListview ~ handleObjectChange ~ error:", error)
      })
    this.showTemplates = true;
  }

  handleTemplatesChange(event) {
    this.selectedTemplates = event.detail.value;
  }

  saveHandler() {
    if (this.objectName == '' || this.objectName == null) {
      this.loading = false;
      toastInfo(this, this.Label.LBL_Select_an_Object);
    } else {
      let deselectedTemps = this.initSelected.filter(item => !this.selectedTemplates.includes(item));
      let selectedTemps = [];
      for (let i = 0; i < this.selectedTemplates.length; i++) {
        if (this.selectedTemplates[i] != this.initSelected[i]) {
          selectedTemps.push(this.selectedTemplates[i]);
        }
      }
      if (deselectedTemps.length > 0 || selectedTemps.length > 0) {
        save({
          objectName: this.objectName,
          noneSelectedTemplates: deselectedTemps,
          selectedTemplates: selectedTemps
        })
          .then(result => {
            let jobIds = JSON.parse(result);
            this.deploymentStatus(jobIds);
          }).catch(error => {
            console.log("🚀 ~ GridSettingsListview ~ saveHandler ~ error:", error)
          })
      } else {
        if (this.saveEvent) {
          const save = new CustomEvent(this.saveEvent);
          this.dispatchEvent(save);
        }
      }
    }
  }

  cancelHandler() {
    if (this.cancelEvent) {
      const cancel = new CustomEvent(this.cancelEvent);
      this.dispatchEvent(cancel);
    }
  }

  deploymentStatus(idDeployment) {
    if (!idDeployment || idDeployment.length === 0) {
      this.loading = false;
      toastError(this, this.Label.MSG_Error_Occurred);
      return;
    }

    this.loading = true;
    let completedCount = 0;
    let jobSuccess = true;
    const processJob = (index) => {
      if (index == idDeployment.length) {
        this.loading = false;
        if (jobSuccess) {
          if (this.saveEvent) {
            const save = new CustomEvent(this.saveEvent);
            this.dispatchEvent(save);
          }
          toastSuccess(this, this.Label.LBL_Save, this.Label.MSG_Save_Complete);
        } else {
          toastInfo(this, this.Label.MSG_Deploy_Ended_With_Status);
          if (this.saveEvent) {
            const save = new CustomEvent(this.saveEvent);
            this.dispatchEvent(save);
          }
        }
        return;
      }

      let jobId = idDeployment[index];
      const checkJobStatus = () => {
        checkDeploymentStatus({ idDeployment: jobId })
          .then((result) => {
            const deployResult = JSON.parse(result).deployResult;
            const { done, success, status } = deployResult;

            if (!done) {
              setTimeout(checkJobStatus, 3000);
            } else {
              completedCount++;
              if (!success) {
                jobSuccess = false;
              }
              processJob(index + 1);
            }
          })
          .catch((error) => {
            this.loading = false;
            toastError(this, error.message || this.Label.MSG_Error_Occurred);
          });
      };

      checkJobStatus();
    };
    processJob(0);
  }
}