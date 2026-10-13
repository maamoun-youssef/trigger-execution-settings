import { LightningElement, track, api } from 'lwc';
import initComponentData from '@salesforce/apex/ContractIndexesSummaryCmpCtrl.initComponentData';
import { loadStyle } from "lightning/platformResourceLoader";
import conditionManager_resources from "@salesforce/resourceUrl/conditionManager";
import Is_OnTop_Simulation__c from "@salesforce/schema/Contract__c.Is_OnTop_Simulation__c";
import LBL_Evoluation_Rate from '@salesforce/label/c.LBL_Evoluation_Rate';
import LBL_Index_Table from '@salesforce/label/c.LBL_Index_Table';
const API_NAMES = {
    Contract__c: {
        Is_OnTop_Simulation__c: Is_OnTop_Simulation__c.fieldApiName,
    }
};
export default class ContractIndexesSummary extends LightningElement {
    @track labels = {
        LBL_Evoluation_Rate,
        LBL_Index_Table
    }
    @api recordId;
    @track tableHeightCond;
    @track TimeZone;
    @track contract;
    @track contractsString;
    @track baseIndex;
    @track baseIndexParent;
    @track contractName;
    @track parentContractName;
    @track dataIndexes;
    contractId;
    connectedCallback() {
        Promise.all([
            loadStyle(this, conditionManager_resources + "/customStyle.css"),
        ]);
        try {
            window.addEventListener('resize', this.setSectionDimension);
        } catch (error) {
            console.error('Error parsing Apex data:', error);
        }
        this.contractId = this.recordId;
        initComponentData({
            contractId: this.contractId
        }).then(result => {
            try {
                const wMain = JSON.parse(result);
                console.log('JSON.parse(result)', JSON.parse(result));
                this.contract = wMain.contract;
                this.contractsString = wMain.contractsString;
                this.TimeZone = wMain.TimeZone;
                const contractData = JSON.parse(this.contractsString);
                this.baseIndex = contractData.baseIndex;
                this.baseIndexParent = contractData.baseIndexParent;
                this.contractName = contractData.contractName;
                this.parentContractName = contractData.parentContractName;
                this.dataIndexes = contractData.wIndexValues;
                let recordType = wMain.contract.RecordType.DeveloperName.replace(/_/g, "-").toLocaleLowerCase();
                console.log('recordType:', recordType);
                if (wMain.contract[API_NAMES.Contract__c.Is_OnTop_Simulation__c] && (recordType == "simulation" || recordType == "signed" || recordType == "to-be-signed")) {
                    recordType = "on-top";
                }
                this.customClass = 'contractIndexesSummary_' + recordType;
            } catch (error) {
                console.error('Error parsing Apex data:', error);
            }
        }).catch(error => {
            console.error('Apex call failed:', error);
        });
    }

    renderedCallback() {
        this.setSectionDimension();
    }

    setSectionDimension() {
        const tdIndHeight = this.template.querySelector('.tdIndHeight')?.getBoundingClientRect()?.height || 20;
        const headerIndHeight = this.template.querySelector('.headerIndHeight')?.getBoundingClientRect()?.height || 20;
        const baseHeaderHeight = this.template.querySelector('.baseHeader')?.getBoundingClientRect()?.height || 20;
        const totalHeight = (tdIndHeight * 7) + headerIndHeight + baseHeaderHeight + 20;
        this.tableHeightCond = `height:${totalHeight}px`;
    }

}