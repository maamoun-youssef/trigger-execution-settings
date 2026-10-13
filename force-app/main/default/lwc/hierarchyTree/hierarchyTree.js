/**
* @author ULiT
* @date 07-07-2025
* @description Hierarchy Tree component for displaying and navigating through Hierarchy__c records and their children 
*******************************************************************************************************************************************
*/

import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//SCHEMA
import HIERARCHY_OBJECT from '@salesforce/schema/Hierarchy__c';

//APEX
import getChildrenHierarchy from '@salesforce/apex/HierarchyTreeCtrl.getChildrenHierarchy';
import initData from '@salesforce/apex/HierarchyTreeCtrl.initData';
import getHierarchyCount from '@salesforce/apex/HierarchyTreeCtrl.getHierarchyCount';

//LABELS
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import LBL_Error from "@salesforce/label/c.LBL_Error";

export default class HierarchyTree extends NavigationMixin(LightningElement) {
    @api recordId;
    @api columnsApi;
    @api showExpandCollapseButtons;
    @api loadFromRoot;
    @track methodsReady = {
        wiredObjectInfo: false,
        connectedCallback: false,
    }
    @track fieldsToDisplay = [];
    isLoading = true;
    objectInfo;

    labels = {
        LBL_No_Item_To_Display,
        LBL_Error
    }

    @track treeList = [];
    @track expandedNodes = new Set();
    @track loadEntireTree = false;
    @track columns = [];
    title = '';
    nameFieldLabel = '';
    currentHierarchy = null;
    currentLevel;

    @wire(getObjectInfo, { objectApiName: HIERARCHY_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfo = data;
            this.nameFieldLabel = this.objectInfo.fields.Name.label;
            this.methodsReady.wiredObjectInfo = true;
            this.init();
        } else if (error) {
            console.error('Error getting object info:', error);
        }
    }

    connectedCallback() {
        this.columns = (this.columnsApi || 'Name').split(',').map(value => value.trim());
        window.addEventListener('resize', this.setPageSize);
        console.log('recordId : ' + this.recordId);
        this.methodsReady.connectedCallback = true;
        this.init();
    }

    init() {
        if (Object.values(this.methodsReady).every(it => it)) {
            this.buildDisplayedField();
        }
    }

    loadAllTreeFromRoot() {
        let i = 0;
        while (i < this.treeList.length && this.treeList.length <= 100) {
            const node = this.treeList[i];
            node.expanded = true;
            node.ariaExpanded = true;
            this.expandedNodes.add(node.key);
            node.show = true;
            if (node.showChevronButton && !node.childrenLoaded) {
                this.loadChildren(node.key, node.key, node.level + 1, null, true, false);
            }
            i++;
        }
        // this.treeList = [...this.treeList];
    }

    handleCollapseAll() {
        for (const node of this.treeList) {
            if (node.level > 1) {
                node.show = false;
            }
            node.expanded = false;
            node.ariaExpanded = false;
            this.expandedNodes.delete(node.key);
            this.loadEntireTree = false;
        }
        this.treeList = [...this.treeList];
    }

    handleExpandAll() {
        this.loadAllTreeFromRoot();
    }

    buildDisplayedField() {
        for (let field of this.columns) {
            let fieldType = this.objectInfo.fields[field].dataType;
            let fieldWrapper = {
                fieldName: field,
                fieldLabel: this.objectInfo.fields[field].label,
                fieldType: fieldType,
                headerstyle: 'min-width: 150px;',
                isNumberField: fieldType == 'NUMBER' || fieldType == 'DOUBLE' || fieldType == 'INTEGER',
                isReference: (fieldType == 'REFERENCE' && !field.endsWith('RecordTypeId')) || field == 'Name',
                isDate: fieldType == 'DATE',
                isDateTime: fieldType == 'DATETIME',
                isPicklist: fieldType == 'PICKLIST',
                isBoolean: fieldType == 'BOOLEAN',
                isTextArea: fieldType == 'TEXTAREA',
                isHTMLFormatted: field.isHTMLFormatted,
                link: '',
                scale: field.scale,
                style: '',
            }
            fieldWrapper.isText = !fieldWrapper.isNumberField && !fieldWrapper.isReference && !fieldWrapper.isDate
                && !fieldWrapper.isDateTime && !fieldWrapper.isPicklist && !fieldWrapper.isBoolean && !fieldWrapper.isTextArea;
            if (fieldWrapper.isNumberField) {
                fieldWrapper.style += 'text-align:right;';
            }
            this.fieldsToDisplay.push(fieldWrapper);
        }
        this.loadInitialData();
    }

    renderedCallback() {
        try {
            setTimeout(() => {
                this.setPageSize();
            }, 200);
        } catch (error) {
            console.error('Rendered callback error:', error);
            this.showNotification(this.labels.LBL_Error, error.message, 'error');
        }
    }

    setPageSize = () => {
        try {
            let pageBody = this.template.querySelector(".pageBody");
            if (pageBody) {
                pageBody.style.maxHeight = '70vh';
            }
        } catch (error) {
            console.error('SetPageSize error:', error);
        }
    }

    loadInitialData() {
        this.isLoading = true;
        getHierarchyCount({
            recordId: this.recordId,
            loadFromRoot: this.loadFromRoot
        }).then(totalCount => {
            this.showExpandCollapseButtons = this.showExpandCollapseButtons && totalCount <= 100;
        });
        initData({ recordId: this.recordId, columns: this.columns, loadFromRoot: this.loadFromRoot })
            .then((result) => {
                if (result) {
                    this.processInitialData(result);
                } else {
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.error('Initial data load error:', error);
                this.showNotification(this.labels.LBL_Error, error.message || error.body?.message, 'error');
                this.isLoading = false;
            });
    }
    
    processInitialData(result) {
        let data = typeof result === 'string' ? JSON.parse(result) : result;
        if (Array.isArray(data) && data.length > 0) {
            this.currentHierarchy = data[0];
            this.currentLevel = data[0].currentLevel;
            const objectLabel = this.objectInfo.label || 'Hierarchy';
            this.title = objectLabel + ': ' + this.currentHierarchy.Name;
            this.createRootNode();

        } else {
            this.isLoading = false;
        }
    }

    // Creates the root node of the hierarchy tree and auto-expands it to show direct children
    createRootNode() {
        const rootNode = {
            key: this.currentHierarchy.Id,
            Id: this.currentHierarchy.Id,
            Name: this.currentHierarchy.Name,
            values: [],
            level: 1,
            parentKey: null,
            showChevronButton: this.currentHierarchy.hasChildren,
            show: true,
            expanded: true,
            ariaExpanded: true,
            childrenLoaded: false,
        };
        for (let field of this.fieldsToDisplay) {
            let fieldValue = {
                fieldName: field.fieldName,
                fieldLabel: field.fieldLabel,
                isNumberField: field.isNumberField,
                isReference: field.isReference,
                isDate: field.isDate,
                isDateTime: field.isDateTime,
                isPicklist: field.isPicklist,
                isBoolean: field.isBoolean,
                isTextArea: field.isTextArea,
                isText: field.isText,
                isHTMLFormatted: field.isHTMLFormatted,
                scale: field.scale,
                link: '',
                value: this.currentHierarchy[field.fieldName],
            }
            if (fieldValue.fieldName == 'Name') {
                fieldValue.link = '/' + rootNode.Id;
            }
            rootNode.values.push(fieldValue)
        }

        this.treeList = [rootNode];
        this.expandedNodes.add(rootNode.key);
        // if (this.loadEntireTree) {
        //     this.loadAllTreeFromRoot();
        // } else {
        this.loadChildren(rootNode.key, rootNode.key, 2, 0, false, this.loadFromRoot);
        // }
    }

    // Processes children data from the Hierarchy Tree Apex Controller response and creates tree nodes
    processChildrenData(result, parentKey, level, loadChildren, expandHierarchyLevel) {
        let data = typeof result === 'string' ? JSON.parse(result) : result;
        if (!Array.isArray(data)) {
            return;
        }

        let newNodes = [];
        data.forEach(item => {
            let node = {
                key: item.Id,
                Id: item.Id,
                Name: item.Name,
                title: item.Name,
                values: [],
                level: level,
                dataLevel: item.Level__c,
                parentKey: parentKey,
                showChevronButton: item.hasChildren === true,
                show: level === 1 || (parentKey && this.expandedNodes.has(parentKey)),
                expanded: false,
                ariaExpanded: false,
                childrenLoaded: false,
            };
            for (let field of this.fieldsToDisplay) {
                let fieldValue = {
                    fieldName: field.fieldName,
                    fieldLabel: field.fieldLabel,
                    isNumberField: field.isNumberField,
                    isReference: field.isReference,
                    isDate: field.isDate,
                    isDateTime: field.isDateTime,
                    isPicklist: field.isPicklist,
                    isBoolean: field.isBoolean,
                    isTextArea: field.isTextArea,
                    isText: field.isText,
                    isHTMLFormatted: field.isHTMLFormatted,
                    scale: field.scale,
                    link: '',
                    value: item[field.fieldName],
                }
                if (fieldValue.fieldName == 'Name') {
                    fieldValue.link = '/' + node.Id;
                }
                node.values.push(fieldValue)
            }
            if (expandHierarchyLevel && node.showChevronButton && !node.childrenLoaded && node.dataLevel <= this.currentLevel) {
                node.expanded = true;
                node.ariaExpanded = true;
                this.expandedNodes.add(node.key);
                node.show = true;
                this.loadChildren(node.key, node.key, node.level + 1, null, true, true);
            } else if (!expandHierarchyLevel && loadChildren && node.showChevronButton && !node.childrenLoaded) {
                node.expanded = true;
                node.ariaExpanded = true;
                this.expandedNodes.add(node.key);
                node.show = true;
                this.loadChildren(node.key, node.key, node.level + 1, null, loadChildren, false);
            }
            newNodes.push(node);
        });

        if (parentKey) {
            let parentIndex = this.treeList.findIndex(node => node.key === parentKey);
            if (parentIndex !== -1) {
                this.treeList.splice(parentIndex + 1, 0, ...newNodes);
                this.treeList[parentIndex].showChevronButton = newNodes.length > 0;
                this.treeList[parentIndex].childrenLoaded = true;
            }
        } else {
            this.treeList = [...newNodes];
        }
        // this.checkChildrenForNewNodes(newNodes);
        // this.treeList = [...this.treeList];
        this.isLoading = false;
    }

    expandAndCollapse(event) {
        const nodeKey = event.currentTarget.dataset.recordid;
        const nodeIndex = this.treeList.findIndex(node => node.key === nodeKey);

        if (nodeIndex === -1) return;

        const node = this.treeList[nodeIndex];
        const isExpanding = !node.expanded;

        if (isExpanding) {
            this.expandedNodes.add(nodeKey);
            node.expanded = true;
            node.ariaExpanded = true;
            if (!node.childrenLoaded) {
                this.loadChildren(nodeKey, nodeKey, node.level + 1, nodeIndex, false);
            } else {
                this.showHideChildren(nodeKey, true);
            }
        } else {
            this.expandedNodes.delete(nodeKey);
            node.expanded = false;
            node.ariaExpanded = false;
            this.showHideChildren(nodeKey, false);
        }
        this.treeList = [...this.treeList];
    }

    loadChildren(hierarchyId, parentKey, level, parentIndex, loadChildren, expandHierarchyLevel) {
        this.isLoading = true;
        getChildrenHierarchy({ hierarchyId: hierarchyId, columns: this.columns })
            .then((result) => {
                if (result) {
                    const data = typeof result === 'string' ? JSON.parse(result) : result;
                    if (Array.isArray(data) && data.length > 0) {
                        this.processChildrenData(result, parentKey, level, loadChildren, expandHierarchyLevel);
                    } else {
                        if (parentIndex !== undefined && this.treeList[parentIndex]) {
                            this.treeList[parentIndex].showChevronButton = false;
                            this.treeList[parentIndex].expanded = false;
                            this.treeList[parentIndex].ariaExpanded = false;
                            this.treeList[parentIndex].childrenLoaded = true;
                            this.expandedNodes.delete(parentKey);
                            this.treeList = [...this.treeList];
                        }
                        this.isLoading = false;
                    }
                    console.log('this.treeList >>> ' + JSON.stringify(this.treeList))
                }
            })
            .catch((error) => {
                console.error('Load children error:', error);
                this.showNotification(this.labels.LBL_Error, error.message || error.body?.message, 'error');
                this.isLoading = false;
            });
    }

    showHideChildren(parentKey, show) {
        const parentLevel = this.treeList.find(node => node.key === parentKey)?.level || 0;
        for (const element of this.treeList) {
            const node = element;

            if (this.isChildOf(node, parentKey, parentLevel)) {
                if (show) {
                    const directParent = this.findDirectParent(node);
                    node.show = directParent ? directParent.expanded : true;
                } else {
                    node.show = false;
                    node.expanded = false;
                    node.ariaExpanded = false;
                    this.expandedNodes.delete(node.key);
                }
            }
        }
    }

    isChildOf(node, parentKey, parentLevel) {
        return node.level > parentLevel && this.hasAncestor(node, parentKey);
    }

    hasAncestor(node, ancestorKey) {
        let current = node;
        while (current.parentKey) {
            if (current.parentKey === ancestorKey) {
                return true;
            }
            current = this.treeList.find(n => n.key === current.parentKey);
            if (!current) break;
        }
        return false;
    }

    findDirectParent(node) {
        return this.treeList.find(n => n.key === node.parentKey);
    }

    navigateToHierarchy(event) {
        const hierarchyId = event.currentTarget.dataset.recordid;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: hierarchyId,
                objectApiName: 'Hierarchy__c',
                actionName: 'view'
            }
        });
    }

    showNotification(title, message, variant, mode = 'dismissable') {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}