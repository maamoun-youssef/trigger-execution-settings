import { LightningElement, track } from 'lwc';
import loadData from "@salesforce/apex/MetadataBridgeCmpController.loadData";
import initData from "@salesforce/apex/MetadataBridgeCmpController.initData";
import generateXML from "@salesforce/apex/MetadataBridgeCmpController.generateXML";
import importFiles from "@salesforce/apex/MetadataBridgeCmpController.importFiles";
import checkDeploymentStatus from "@salesforce/apex/MetadataBridgeCmpController.checkDeploymentStatus";

//labels
import LBL_No_selected_templates from "@salesforce/label/c.LBL_No_selected_templates";
import LBL_Import_File from "@salesforce/label/c.LBL_Import_File";
import LBL_Export_File from "@salesforce/label/c.LBL_Export_File";
import LBL_Metadata_Bridge from "@salesforce/label/c.LBL_Metadata_Bridge";
import LBL_Selected_Templates from "@salesforce/label/c.LBL_Selected_Templates";
import LBL_Selected from "@salesforce/label/c.LBL_Selected";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Upload_File from "@salesforce/label/c.LBL_Upload_File";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Search from "@salesforce/label/c.LBL_Search";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Filter from "@salesforce/label/c.LBL_Filter";
import LBL_Select_Object from "@salesforce/label/c.LBL_Select_Object";
import LBL_Type from "@salesforce/label/c.LBL_Type";
import LBL_Reset from "@salesforce/label/c.LBL_Reset";
import LBL_Apply from "@salesforce/label/c.LBL_Apply";
import LBL_Import from "@salesforce/label/c.LBL_Import";
import LBL_Export from "@salesforce/label/c.LBL_Export";
import MSG_Deploy_Ended_With_Status from "@salesforce/label/c.MSG_Deploy_Ended_With_Status";
import MSG_Information from "@salesforce/label/c.MSG_Information";
import MSG_Error from "@salesforce/label/c.MSG_Error";
import MSG_Error_Occurred from "@salesforce/label/c.MSG_Error_Occurred";
import MSG_Save_Complete from "@salesforce/label/c.MSG_Save_Complete";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MetadataBridge extends LightningElement {
    @track Labels = {
        LBL_No_selected_templates,
        LBL_Import_File,
        LBL_Export_File,
        LBL_Metadata_Bridge,
        LBL_Selected_Templates,
        LBL_Selected,
        LBL_Of,
        LBL_Save,
        LBL_Upload_File,
        LBL_Cancel,
        LBL_Search,
        LBL_No_Item_To_Display,
        LBL_Filter,
        LBL_Select_Object,
        LBL_Type,
        LBL_Reset,
        LBL_Apply,
        LBL_Import,
        LBL_Export,
        MSG_Deploy_Ended_With_Status,
        MSG_Information,
        MSG_Error,
        MSG_Error_Occurred,
        MSG_Save_Complete
    };
    @track objects = [];
    @track types = [ { label: 'Detail', value: 'Detail'}, { label: 'Master', value: 'Master'}, { label: 'Master-Detail', value: 'Master-Detail'}, { label: 'None-Master-Detail', value: 'None-Master-Detail'}, { label: 'Master-Detail-Lookup', value: 'Master-Detail-Lookup'},];
    @track displayedTemplates = [];
    @track wMain = {};
    @track resultWrapper = {};
    @track fieldWrapper = [];
    @track selectedTemplates = [];
    @track filesName = [];
    @track prefixValue = '';
    @track pageSize = '5';
    @track pageSizeOptions = [{ label: '5', value: '5' }, { label: '10', value: '10' }, { label: '25', value: '25' }, { label: '50', value: '50' }, { label: '75', value: '75' }, { label: '100', value: '100' },];
    @track isLoading = false;
    @track filterState = false;
    @track isFilterOpen = false;
    @track showImportPopup = false;
    @track showExportPopup = false;
    @track filters = {
        searchTerm: '',
        objectName: '',
        type: ''
    };
    filesData = {};
    pageNumber = 1;
    total;
    dataRes = [];

    toastError = (context, msg, stack) => {
        msg = msg && msg.hasOwnProperty('body') && msg.body.hasOwnProperty('message') ? msg.body.message : msg;
        if (msg) {
            console.error(msg);
        }
        if (stack) {
            console.error(stack);
        }
        const evt = new ShowToastEvent({
            title: MSG_Error,
            message: msg,
            variant: "error",
            mode: "dismissable"
        });
        context.dispatchEvent(evt);
    };
    toastSuccess = (context, title, msg) => {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: "success",
            mode: "dismissable"
        });
        context.dispatchEvent(evt);
    };
    toastInfo = (context, msg) => {
        const evt = new ShowToastEvent({
            title: MSG_Information,
            message: msg,
            variant: "info",
            mode: "dismissable"
        });
        context.dispatchEvent(evt);
    };

    get hasData() {
        return this.displayedTemplates && this.displayedTemplates.length > 0;
    }

    get previousDisabled() {
        return this.pageNumber == 1;
    }

    get nextDisabled() {
        const size = parseInt(this.pageSize, 10) || 5;
        const pages = Math.max(1, Math.ceil((this.total || 0) / size));
        return this.pageNumber >= pages;
    }

    get paginationBadge() {
        let pageSize = parseInt(this.pageSize);
        return (this.pageNumber * pageSize + 1 - pageSize < this.total ? this.pageNumber * pageSize + 1 - pageSize : this.total - this.displayedTemplates.length) + '-' + (this.pageNumber * pageSize > this.total ? this.total : this.pageNumber * pageSize) + ' ' + this.Labels.LBL_Of + ' ' + this.total;
    }

    get isAllSelected() {
        return this.hasData && this.displayedTemplates.length > 0 && this.displayedTemplates.every(template => template.gridList.every(item => item.isSelected));
    }

    get selectedBadge() {
        return this.selectedTemplates ? this.selectedTemplates.length + ' ' + this.Labels.LBL_Selected : '0 ' + this.Labels.LBL_Selected;
    }

    get tableStyle() {
        let height = this.template.querySelector('.initial-table')?.offsetHeight;
        return `height: ${height}px; min-height: 300px;`;
    }

    get filterPanelStyle() {
        let table = this.template.querySelector('.initial-table');
        let pageSize = parseInt(this.pageSize);
        let height = table && pageSize > 5 && this.filters.searchTerm == '' ? this.template.querySelector('.initial-table')?.offsetHeight : 300;
        return `height: ${height}px; overflow-y: auto;`;
    }

    get prefixOptions() {
        return [
            { label: 'Without a prefix', value: '' },
            { label: 'NegOptim', value: 'Negoptim__' },
            { label: 'nGrid', value: 'nGrid__' },
        ];
    }

    // get everything we need for initialization
    connectedCallback() {
        this.isLoading = true;
        initData()
            .then(result => {
                this.wMain = JSON.parse(result);
                this.objects = JSON.parse(this.wMain.displayedObjects);
                this.fieldWrapper = this.wMain.wFields;
                return this.displayData(); // no arbitrary delay
            })
            .catch(error => {
                console.log("🚀 ~ MetadataBridge ~ initData ~ error:", error);
                this.isLoading = false;
            });
    }

    // Fetches data from the server, processes it, and updates the grid display.
    displayData() {
        const size = parseInt(this.pageSize, 10) || 5;
        loadData({ filters: JSON.stringify(this.filters), pageSize: size, pageNumber: this.pageNumber })
        // loadData({ filters: JSON.stringify(this.filters), pageSize: this.pageSize, pageNumber: this.pageNumber })
            .then(result => {
                this.resultWrapper = JSON.parse(result);
                this.total = this.resultWrapper.total;
                this.dataRes = this.resultWrapper.records;
                let nGridRes = {};
                this.displayedTemplates = [];
                for (let res of this.dataRes) {
                    let newData = [];
                    newData = this.buildGridPageInfo(res);
                    const key = res.DeveloperName || res.Id;
                    nGridRes[key] = {
                        gridName: res.MasterLabel || key,
                        className: key,
                        gridList: []
                    };
                    nGridRes[key].gridList.push(newData);
                }
                this.displayedTemplates = Object.values(nGridRes);
                this.isLoading = false;
            }).catch(error => {
                console.log("🚀 ~ MetadataBridge ~ handleObjectChange ~ error:", error)
                this.isLoading = false;
            })
    }

    // Generates and downloads XML files for the given object names (single and mass export).
    xmlGenerator(objName) {
        generateXML({ layoutsName: JSON.stringify(objName), prefix: this.prefixValue })
            .then(result => {
                const xmlContent = result;
                for (let i = 0; i < xmlContent.length; i++) {
                    const blob = new Blob([xmlContent[i]], { type: 'text/plain' });
                    const link = document.createElement('a');
                    link.href = URL.createObjectURL(blob);
                    link.download = `${objName[i]}.xml`;
                    link.click();
                    URL.revokeObjectURL(link.href);
                }
            })
            .catch(error => {
                console.log("🚀 ~ MetadataBridge ~ xmlGenerator ~ error:", error)
            });
    }

    singleExport(event) {
        this.selectedTemplates = [];
        this.selectedTemplates.push(event.currentTarget.dataset.templatename);
        this.showExportPopup = true;
    }

    buildGridPageInfo(record) {
        try {
            let gridPage = {
                values: [],
                isSelected: false,
                templateName: ''
            }
            let i = 0;
            for (let field of this.fieldWrapper) {
                let fieldObject = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    fieldValue: record[field.fieldName],
                }
                if (fieldObject.fieldName == 'DeveloperName') {
                    gridPage.templateName = fieldObject.fieldValue;
                }
                gridPage.values.push(fieldObject);
            }
            return gridPage;
        } catch (error) {
            console.log("🚀 ~ MetadataBridge ~ buildGridPageInfo ~ error:", error)
        }
    }

    handleObjectChange(event) {
        this.filters.objectName = event.detail.value;
    }

    handleTypeChange(event) {
        this.filters.type = event.detail.value;
    }

    handlePageSize(event) {
        this.pageSize = event.detail.value;
        this.pageNumber = 1;
        this.isLoading = true;
        this.isFilterOpen = false;
        this.filterState = false;
        this.displayData();
    }

    // Handles file input changes (single and mass import)
    handleFileChange(event) {
        let files = event.target.files;
        this.filesName = [];
        this.filesData = {};
        let processedFiles = 0;
        if (files) {
            Array.from(files).forEach((file) => {
                let fName = file.name.replace(/\s*\([^)]*\)\s*/g, '').replace('.xml', '');
                this.filesName.push(fName);
                const reader = new FileReader();

                reader.onload = () => {
                    let content = reader.result;
                    content = content.replace(/<\/?values>/g, '');
                    content = content.replace(/<protected>.*?<\/protected>/g, '');
                    const fieldRegex = /<field>(.*?)<\/field>/g;
                    const valueRegex = /<value[^>]*>(.*?)<\/value>/g;
                    const labelRegex = /<label[^>]*>(.*?)<\/label>/g;

                    const innerMap = {};
                    let fieldMatch, valueMatch, labelMatch;

                    while ((labelMatch = labelRegex.exec(content))) {
                        const labelContent = labelMatch[1];
                        innerMap['label'] = labelContent;
                    }
                    while ((fieldMatch = fieldRegex.exec(content)) && (valueMatch = valueRegex.exec(content))) {
                        const fieldKey = fieldMatch[1];
                        const valueContent = valueMatch[1];
                        innerMap[fieldKey] = valueContent;
                    }
                    
                    this.filesData[fName] = innerMap;
                    processedFiles++;

                    if (processedFiles == files.length) {
                        this.showImportPopup = true;
                    }
                };

                reader.readAsText(file);
            });
        }
    }

    handleImport() {
        importFiles({ xmlFileContent: this.filesData, prefix: this.prefixValue })
            .then(result => {
                let jobIds = JSON.parse(result);
                this.deploymentStatus(jobIds);
            })
            .catch(error => {
                console.error("Error while importing files:", error);
            });
        this.showImportPopup = false;
    }

    // Checks the deployement status
    deploymentStatus(idDeployment) {
        if (!idDeployment || idDeployment.length === 0) {
            this.toastError(this, this.Labels.MSG_Error_Occurred);
            return;
        }

        this.isLoading = true;
        let jobSuccess = true;
        let deploymentStatusMessage = '';
        const processJob = (index) => {
            if (index == idDeployment.length) {
                if (jobSuccess) {
                    this.isLoading = false;
                    this.toastSuccess(this, this.Labels.LBL_Save, this.Labels.MSG_Save_Complete);
                } else {
                    this.isLoading = false;
                    this.toastInfo(this, this.Labels.MSG_Deploy_Ended_With_Status + ' ' + deploymentStatusMessage);
                }
                return;
            }

            let jobId = idDeployment[index];
            const checkJobStatus = () => {
                checkDeploymentStatus({ idDeployment: jobId })
                    .then((result) => {
                        console.log("🚀 ~ MetadataBridge ~ .then ~ result:", result)
                        const deployResult = JSON.parse(result).deployResult;
                        const { done, success, status } = deployResult;

                        deploymentStatusMessage = status;
                        if (!done) {
                            setTimeout(checkJobStatus, 3000);
                        } else {
                            if (!success) {
                                jobSuccess = false;
                            }
                            processJob(index + 1);
                        }
                    })
                    .catch((error) => {
                        this.isLoading = false;
                        console.log("🚀 ~ MetadataBridge ~ checkJobStatus ~ error:", error)
                        this.toastError(this, error.message || this.Labels.MSG_Error_Occurred);
                    });
            };

            checkJobStatus();
        };
        processJob(0);
    }

    changeSearchInputHandler(event) {
        this.filters.searchTerm = event.target.value;
    }

    // For all records
    toggleAllSelected(event) {
        this.selectedTemplates = [];
        let checked = event.detail.checked;
        if (checked) {
            this.displayedTemplates.forEach(template => {
                template.gridList.forEach(grid => {
                    grid.isSelected = true;
                    this.selectedTemplates.push(grid.templateName);
                });
            })
        } else {
            this.displayedTemplates.forEach(template => {
                template.gridList.forEach(grid => {
                    grid.isSelected = false;
                });
            })
            this.selectedTemplates = [];
        }
    }

    // Just for selected records
    toggleSelectedTemplates(event) {
        let gridName = event.target.dataset.gridname;
        let checked = event.detail.checked;
        if (checked) {
            this.displayedTemplates.forEach(template => {
                template.gridList.forEach(grid => {
                    if (grid.templateName === gridName) {
                        grid.isSelected = true;
                        this.selectedTemplates.push(grid.templateName);
                    }
                });
            })
        } else {
            this.displayedTemplates.forEach(template => {
                template.gridList.forEach(grid => {
                    if (grid.templateName === gridName) {
                        grid.isSelected = false;
                        this.selectedTemplates = this.selectedTemplates.filter(item => item != grid.templateName);
                    }
                });
            })
        }
    }

    massExport() {
        this.selectedTemplates = [];
        this.displayedTemplates.forEach(template => {
            template.gridList.forEach(grid => {
                if (grid.isSelected) {
                    this.selectedTemplates.push(grid.templateName);
                }
            })
        })
        if (this.selectedTemplates.length > 0) {
            this.showExportPopup = true;
        } else {
            this.toastInfo(this, this.Labels.LBL_No_selected_templates);
        }
    }

    searchInputChangeHandler(event) {
        this.filters.searchTerm = event.target.value;
        this.isLoading = true;
        this.displayData();
    }

    toggleFilter() {
        this.filterState = !this.filterState;
        this.isFilterOpen = !this.isFilterOpen;
    }

    submitSearchKeyPressHandler(event) {
        if (this.filters.searchTerm && (event.which == 13 || event.keyCode == 13)) {
            this.pageNumber = 1;
            this.isLoading = true;
            this.displayData();
            event.target.blur();
        }
    }

    prefixChangeHandler(event) {
        this.prefixValue = event.target.value;
    }

    // Handling Export (single and mass)
    handleExport() {
        this.xmlGenerator(this.selectedTemplates);
        this.showExportPopup = false;
    }

    handleCancel() {
        this.selectedTemplates = [];
        this.filesName = [];
        this.showExportPopup = false;
        this.showImportPopup = false;
        this.displayData();
    }

    resetFilter() {
        this.isLoading = true;
        this.filters.objectName = '';
        this.filters.type = '';
        this.toggleFilter();
        this.displayData();
    }

    applyChanges() {
        this.isLoading = true;
        this.toggleFilter();
        this.displayData();
    }

    // Pagination
    handleChangePage(event) {
        this.isLoading = true;
        try {
            let type = event.target.dataset.type;
            const size = parseInt(this.pageSize, 10) || 5;
            const pages = Math.max(1, Math.ceil((this.total || 0) / size));
            if (type === 'Previous') {
                this.pageNumber = Math.max(1, this.pageNumber - 1);
            } else if (type === 'Next') {
                this.pageNumber = Math.min(pages, this.pageNumber + 1);
            } else if (type === 'First') {
                this.pageNumber = 1;
            } else if (type === 'Last') {
                this.pageNumber = pages;
            }
            this.isFilterOpen = false;
            this.filterState = false;
            this.displayData();
        } catch (error) {
            console.error(error)
        }
    }

    selectedStaticResource = '/resource/BusinessOwnerIcon';
    handleStaticResourceChange(event) {
        this.selectedStaticResource = event.detail?.url ?? null;
        console.log('Selected static resource URL:', this.selectedStaticResource);
    }
}