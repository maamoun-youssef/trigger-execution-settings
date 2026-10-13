/**
 * @description BU Clustering screen.
 */
import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { showNotification } from 'c/appHelper';

// APEX
import initData from '@salesforce/apex/BUClusteringController.initData';
import loadData from '@salesforce/apex/BUClusteringController.loadData';
import saveData from '@salesforce/apex/BUClusteringController.saveData';
import saveStores from '@salesforce/apex/BUClusteringController.saveStores';

// OBJECTS
import BU__OBJECT from '@salesforce/schema/BusinessUnit__c';
import BU_Detail_OBJECT from '@salesforce/schema/BULink__c';

// BusinessUnit__c FIELDS
import Name from '@salesforce/schema/BusinessUnit__c.Name';
import Code__c from '@salesforce/schema/BusinessUnit__c.Code__c';
import Hierarchy__c from '@salesforce/schema/BusinessUnit__c.Hierarchy__c';
import ClientCategory__c from '@salesforce/schema/BusinessUnit__c.ClientCategory__c';
import AssortmentStrat__c from '@salesforce/schema/BusinessUnit__c.AssortmentStrat__c';
import OpeningDate__c from '@salesforce/schema/BusinessUnit__c.OpeningDate__c';
import ClosingDate__c from '@salesforce/schema/BusinessUnit__c.ClosingDate__c';
import IsMultipleComplementary__c from '@salesforce/schema/BusinessUnit__c.IsMultipleComplementary__c';
import SiteOfSalesNumber__c from '@salesforce/schema/BusinessUnit__c.SiteOfSalesNumber__c';
import SiteOfSalesNumberN1__c from '@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberN1__c';
import SiteOfSalesNumberP1__c from '@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP1__c';
import SiteOfSalesNumberP2__c from '@salesforce/schema/BusinessUnit__c.SiteOfSalesNumberP2__c';
import WeightedDistributionManual__c from '@salesforce/schema/BusinessUnit__c.WeightedDistributionManual__c';
import WeightedDistributionManualN1__c from '@salesforce/schema/BusinessUnit__c.WeightedDistributionManualN1__c';
import WeightedDistributionManualP1__c from '@salesforce/schema/BusinessUnit__c.WeightedDistributionManualP1__c';
import WeightedDistributionManualP2__c from '@salesforce/schema/BusinessUnit__c.WeightedDistributionManualP2__c';
import SellOutFact__c from '@salesforce/schema/BusinessUnit__c.SellOutFact__c';
import SellOutFactN1__c from '@salesforce/schema/BusinessUnit__c.SellOutFactN1__c';
import SellOutFactP1__c from '@salesforce/schema/BusinessUnit__c.SellOutFactP1__c';
import SellOutFactP2__c from '@salesforce/schema/BusinessUnit__c.SellOutFactP2__c';
import CURRENCY from '@salesforce/i18n/currency';

// BULink__c FIELDS
import BusinessUnitMaster__c from '@salesforce/schema/BULink__c.BusinessUnitMaster__c';
import BusinessUnitDetail__c from '@salesforce/schema/BULink__c.BusinessUnitDetail__c';
import ReferenceYear__c from '@salesforce/schema/BULink__c.ReferenceYear__c';

// LABELS
import LBL_First from '@salesforce/label/c.LBL_First';
import LBL_Previous from '@salesforce/label/c.LBL_Previous';
import LBL_Next from '@salesforce/label/c.LBL_Next';
import LBL_Last from '@salesforce/label/c.LBL_Last';
import LBL_Filter from '@salesforce/label/c.LBL_Filter';
import LBL_Search from '@salesforce/label/c.LBL_Search';
import LBL_BU_Clustering from '@salesforce/label/c.LBL_BU_Clustering';
import LBL_Cancel from '@salesforce/label/c.LBL_Cancel';
import LBL_Save from '@salesforce/label/c.LBL_Save';
import LBL_Weighted_Distribution from '@salesforce/label/c.LBL_Weighted_Distribution';
import LBL_close from '@salesforce/label/c.LBL_Close';
import LBL_Reset from '@salesforce/label/c.LBL_Reset';
import MSG_Successfully_Saved from '@salesforce/label/c.MSG_Successfully_Saved';
import LBL_Success from '@salesforce/label/c.LBL_Success';
import LBL_Error from '@salesforce/label/c.LBL_Error';
import LBL_WD from '@salesforce/label/c.LBL_WD';
import LBL_SellOutFact from '@salesforce/label/c.LBL_SellOutFact';
import LBL_No_Item_To_Display from '@salesforce/label/c.LBL_No_Item_To_Display';
import LBL_BuClustering_GlobalSearchPlaceHolder from '@salesforce/label/c.LBL_BuClustering_GlobalSearchPlaceHolder';

export default class BUClustering extends NavigationMixin(LightningElement) {
    //API
    @api recordId;
    // YEAR FIELDS (key = offset from the current year)
    SITE_OF_SALES_FIELDS = { '-2': SiteOfSalesNumberP2__c.fieldApiName, '-1': SiteOfSalesNumberP1__c.fieldApiName, 0: SiteOfSalesNumber__c.fieldApiName, 1: SiteOfSalesNumberN1__c.fieldApiName };
    WD_FIELDS = { '-2': WeightedDistributionManualP2__c.fieldApiName, '-1': WeightedDistributionManualP1__c.fieldApiName, 0: WeightedDistributionManual__c.fieldApiName, 1: WeightedDistributionManualN1__c.fieldApiName };
    SELL_OUT_FACT_FIELDS = { '-2': SellOutFactP2__c.fieldApiName, '-1': SellOutFactP1__c.fieldApiName, 0: SellOutFact__c.fieldApiName, 1: SellOutFactN1__c.fieldApiName };
    WD_INPUT_FIELDS = [SellOutFact__c.fieldApiName, SellOutFactN1__c.fieldApiName, WeightedDistributionManual__c.fieldApiName];
    // UI STATE
    pageLoading = true;
    optionsReady = false;
    isFilterOpen = false;
    isShowWeightedDistributionModal = false;
    isShowWD = false;
    isShowSellOutFact = false;
    nbOfFixedColumns = 2;
    tableHeight;
    // CONTEXT
    initDataWrapper = {};
    loadDataWrapper = {};
    currentBU;
    BUListDetailRecordType;
    isMultipleComplementary = false;
    currentYear = new Date().getFullYear();
    years = [this.currentYear - 2, this.currentYear - 1, this.currentYear, this.currentYear + 1];
    // FIELDS
    buFields = [];
    storesFields = [];
    wStoresFields = [];
    // DATA
    @track assortmentStoreData = [];
    @track wStoresList = [];
    // PENDING CHANGES
    BuDetailListToUpdate = [];
    BuDetailListToDelete = [];
    storesToSave = [];
    // FILTERS
    @track filters = { store: '', hierarchy: [], clientCategory: [] };
    clientCategoriesOptions = '';
    hierarchyOptions = '';
    selectedClientCategory = '';
    selectedHierarchy = '';
    selectedYears = [this.currentYear, this.currentYear + 1];
    selectedYearsJson = JSON.stringify([this.currentYear, this.currentYear + 1]);
    yearsOptions = JSON.stringify(this.years.map(year => ({ label: '' + year, value: year })));
    Events = {
        handleMultiYearSelection: 'handlemultiyearselection',
        handleClientCategoryChange: 'handleclientcategorychange',
        handleHierarchyChange: 'handlehierarchychange'
    };

    // PAGINATION
    @track pageNumber = 0;
    @track pageSize = 25;
    totalSize = 0;
    totalPagesCount = 0;
    pageSizeOptions = [
        { label: '5', value: 5, isSelected: false },
        { label: '10', value: 10, isSelected: false },
        { label: '25', value: 25, isSelected: false },
        { label: '50', value: 50, isSelected: false },
        { label: '75', value: 75, isSelected: false },
    ];

    // LABELS
    @track label = {
        First: LBL_First,
        Previous: LBL_Previous,
        Next: LBL_Next,
        Last: LBL_Last,
        LBL_Filter,
        LBL_Search,
        LBL_BU_Clustering,
        LBL_Cancel,
        LBL_Save,
        LBL_Weighted_Distribution,
        LBL_close,
        LBL_Reset,
        MSG_Successfully_Saved,
        LBL_Success,
        LBL_Error,
        LBL_WD,
        LBL_SellOutFact,
        LBL_No_Item_To_Display,
        LBL_BuClustering_GlobalSearchPlaceHolder,
        clientCategory: '',
        year: '',
        hierarchy: ''
    };

    get isFirstDisabled() {
        return this.pageNumber <= 1;
    }

    get isPreviousDisabled() {
        return this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.pageNumber >= this.totalPagesCount;
    }

    get displayTotal() {
        return this.isShowSellOutFact || this.isShowWD;
    }

    get hasData() {
        return this.loadDataWrapper?.storeList?.length > 0;
    }

    @wire(getObjectInfos, { objectApiNames: [BU__OBJECT.objectApiName, BU_Detail_OBJECT.objectApiName] })
    wiredObjectInfos({ error, data }) {
        if (error) console.error('wiredObjectInfos', error);
        if (!data) return;
        const buFieldsInfo = data.results[0].result.fields;
        this.storesFields = [Name, Code__c, SellOutFactP2__c, SellOutFactP1__c, SellOutFact__c, SellOutFactN1__c, WeightedDistributionManual__c]
            .map(field => buFieldsInfo[field.fieldApiName])
            .filter(fieldInfo => fieldInfo);
        this.buFields = [Code__c, Name].map(field => ({ fieldLabel: buFieldsInfo[field.fieldApiName]?.label, style: 'min-width: 100px; width: 100px;' }));
        this.label.clientCategory = buFieldsInfo[ClientCategory__c.fieldApiName]?.label;
        this.label.hierarchy = buFieldsInfo[Hierarchy__c.fieldApiName]?.label;
        this.label.year = data.results[1].result.fields[ReferenceYear__c.fieldApiName]?.label;
        this.initData();
    }

    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
    }

    renderedCallback() {
        this.setFixedLayout();
        if (this.template.querySelector('.outter-table') && this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.changeHeight);
    }

    initData() {
        this.pageLoading = true;
        this.pageNumber = 1;
        console.log('CURRENCY>>>>> ' + CURRENCY);
        initData({ BUId: this.recordId }).then(result => {
            this.initDataWrapper = JSON.parse(result);
            if (this.initDataWrapper.errorMessages?.length > 0) {
                showNotification(this, this.label.LBL_Error, this.initDataWrapper.errorMessages.join('\n'), 'error', 'sticky');
                this.pageLoading = false;
                return;
            }
            const { categoriesOptions, hierarchyOptions } = this.initDataWrapper.filterOptions;
            this.currentBU = this.initDataWrapper.currentBU;
            this.BUListDetailRecordType = this.initDataWrapper.BUListDetailRecordType;
            this.isMultipleComplementary = this.currentBU[IsMultipleComplementary__c.fieldApiName];
            this.clientCategoriesOptions = JSON.stringify(categoriesOptions);
            this.hierarchyOptions = JSON.stringify(hierarchyOptions);
            // everything is selected by default
            this.selectedClientCategory = JSON.stringify(['all', ...categoriesOptions.map(option => option.value)]);
            this.selectedHierarchy = JSON.stringify(['all', ...hierarchyOptions.map(option => option.value)]);
            this.optionsReady = true;
            this.loadData();
        }).catch(error => {
            showNotification(this, this.label.LBL_Error, error.body?.message || error.message, 'error', 'sticky');
            this.pageLoading = false;
        });
    }

    loadData() {
        this.pageLoading = true;
        loadData({
            BUId: this.currentBU.Id,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            filters: JSON.stringify(this.filters)
        }).then(result => {
            this.loadDataWrapper = JSON.parse(result);
            const { storeList = [], clusters = [], totalNumbOfRecords } = this.loadDataWrapper;
            this.totalSize = totalNumbOfRecords;
            this.totalPagesCount = Math.ceil(this.totalSize / this.pageSize);
            // WD / Sell Out Fact columns visibility is persisted in localStorage
            this.isShowWD = localStorage.getItem('ShowWDValues') == 'true';
            this.isShowSellOutFact = localStorage.getItem('ShowSellOutFactValues') == 'true';
            this.assortmentStoreData = this.buildData(storeList, clusters);
            // Weighted Distribution modal
            this.wStoresFields = this.storesFields.map(field => field.label);
            this.wStoresList = storeList.map(store => ({
                storeId: store.Id,
                fields: this.storesFields.map(field => ({
                    fieldName: field.label || '',
                    fieldApiName: field.apiName || '',
                    fieldValue: store[field.apiName] || 0,
                    isInput: this.WD_INPUT_FIELDS.includes(field.apiName),
                    isDouble: field.dataType == 'Double',
                    isPercent: field.dataType == 'Percent',
                    isCurrency: field.dataType == 'Currency',
                    currencyCode: store.CurrencyIsoCode || CURRENCY,
                    isText: ['String', 'Textarea'].includes(field.dataType) && field.apiName != Code__c.fieldApiName,
                    isLink: field.apiName == Code__c.fieldApiName,
                    storeLink: '/' + store.Id
                }))
            }));
            this.pageLoading = false;
        }).catch(error => {
            showNotification(this, this.label.LBL_Error, error.body?.message || error.message, 'error', 'sticky');
            this.pageLoading = false;
        });
    }

    // Groups the clusters by hierarchy > client category > year and builds one row per store in each client category
    buildData(storeList, clusters) {
        try {
            let hierarchyMap = new Map();
            let clientCategoryMap = new Map();
            let activeYears = new Set();
            for (let cluster of clusters) {
                const hierarchyId = cluster[Hierarchy__c.fieldApiName];
                const clientCategoryName = cluster[ClientCategory__c.fieldApiName] || '';
                if (!hierarchyMap.has(hierarchyId)) {
                    hierarchyMap.set(hierarchyId, {
                        hierarchyId: hierarchyId,
                        hierarchyName: cluster[Hierarchy__c.fieldApiName.replace(/__c$/, '__r')]?.Name ?? '',
                        hierarchyIndex: hierarchyMap.size,
                        clientCategories: []
                    });
                }
                const hierarchy = hierarchyMap.get(hierarchyId);
                // composite key: a client category lives under one hierarchy
                const clientCategoryKey = hierarchyId + clientCategoryName;
                if (!clientCategoryMap.has(clientCategoryKey)) {
                        const clientCategory = {
                            clientCategoryId: clientCategoryKey,
                            clientCategoryName: clientCategoryName,
                            hasClientCategoryName: clientCategoryName.trim().length > 0,
                            clientCategoryIndex: hierarchy.clientCategories.length,
                            hierarchyIndex: hierarchy.hierarchyIndex
                        };
                    hierarchy.clientCategories.push(clientCategory);
                    clientCategoryMap.set(clientCategoryKey, { clientCategory: clientCategory, clustersPerYear: this.years.map(() => []) });
                }
                // a cluster belongs to a year when it is opened before (or during) that year and not closed yet
                // parseInt keeps the year of a 'YYYY-MM-DD' date and gives NaN for an empty date
                const openingYear = parseInt(cluster[OpeningDate__c.fieldApiName]);
                const closingYear = parseInt(cluster[ClosingDate__c.fieldApiName]);
                this.years.forEach((year, yearIndex) => {
                    if (openingYear <= year && (isNaN(closingYear) || closingYear >= year)) {
                        clientCategoryMap.get(clientCategoryKey).clustersPerYear[yearIndex].push(cluster);
                        activeYears.add(year);
                    }
                });
            }
            // a year is displayed when it has clusters and is selected in the filter (no selection = all years)
            const displayedYears = this.years.filter(year => activeYears.has(year) && (this.selectedYears.length == 0 || this.selectedYears.some(selectedYear => selectedYear == year)));
            for (let { clientCategory, clustersPerYear } of clientCategoryMap.values()) {
                // header: one group per year, one column per cluster (each column also carries what the store cells need)
                clientCategory.clientCategoryClusters = clustersPerYear.map((yearClusters, yearIndex) => {
                    const year = this.years[yearIndex];
                    const yearOffset = year - this.currentYear;
                    return {
                        year: year,
                        yearIndex: yearIndex,
                        isDisplayed: displayedYears.includes(year),
                        hasCluster: yearClusters.length > 0,
                        totals: { weightedDistribution: this.label.LBL_WD, sellOutFact: this.label.LBL_SellOutFact },
                        colSpan: Math.max(yearClusters.length + (this.isShowWD ? 1 : 0) + (this.isShowSellOutFact ? 1 : 0), 1),
                        Clusters: yearClusters.map((cluster, clusterIndex) => {
                            const isLastColumn = clusterIndex == yearClusters.length - 1;
                            const borderStyle = isLastColumn ? ' border-right: 1.5mm ridge rgb(137 122 122 / 58%);border-left : 0px;' : ' border-right: 0px;border-left : 0px;';
                            const assortmentStrat = cluster[AssortmentStrat__c.fieldApiName] || '';
                            const isCplt = assortmentStrat.includes('Cplt');
                            return {
                                clustId: cluster.Id,
                                clusterName: cluster.Name,
                                clusterLink: '/' + cluster.Id,
                                clusterSiteOfSalesNumb: cluster[this.SITE_OF_SALES_FIELDS[yearOffset]] || 0,
                                clusterWD: cluster[this.WD_FIELDS[yearOffset]] || 0,
                                clusterSelloutFact: cluster[this.SELL_OUT_FACT_FIELDS[yearOffset]] || 0,
                                currencyCode: cluster.CurrencyIsoCode || CURRENCY,
                                clusterStyle: 'border-bottom: 0px; text-align: center; min-width: 100px;' + borderStyle,
                                borderStyle: borderStyle,
                                assortmentStrat: assortmentStrat,
                                isCplt: isCplt,
                                isDisabled: year == this.currentYear - 2,
                                BUIndex: clusterIndex,
                                BUClass: (clusterIndex == 0 ? ' slds-border_left' : '') + (isLastColumn ? ' slds-border_right' : ''),
                                BUstyle: 'text-align: center; min-width: 100px;' + (isCplt ? '' : ' background-color : ' + (year < this.currentYear ? '#E2F3EC' : '#FAF2A0') + ';') + borderStyle
                            };
                        })
                    };
                });
                clientCategory.stores = storeList.map((store, storeIndex) => this.buildRow(store, storeIndex, clientCategory.clientCategoryClusters));
                // footer: WD / Sell Out Fact totals per cluster
                clientCategory.stratTotal = clientCategory.clientCategoryClusters.map(({ year, yearIndex, isDisplayed, hasCluster, Clusters }) => ({
                    year, yearIndex, isDisplayed, hasCluster,
                    strats: Clusters.map((column, clusterIndex) => ({
                        ...this.calculateTotals(clientCategory.stores.map(store => store.details[yearIndex].Clusters[clusterIndex])),
                        stratStyle: 'text-align: center; padding: 2px;' + column.borderStyle
                    }))
                }));
            }
            return Array.from(hierarchyMap.values());
        } catch (error) {
            console.log('buildData: %c' + error.message, 'color : red');
            return [];
        }
    }

    // One store row: a checkbox cell per cluster column and per year, checked when the store is linked to the cluster
    buildRow(store, storeIndex, clientCategoryClusters) {
        const storeLinks = store.BULNKBusinessUnitDetail__r?.records || [];
        return {
            storeId: store.Id,
            storeIndex: storeIndex,
            storeBuCode: store[Code__c.fieldApiName],
            storeBuName: store.Name,
            storeLink: '/' + store.Id,
            details: clientCategoryClusters.map(({ year, yearIndex, isDisplayed, hasCluster, Clusters }) => {
                const cells = Clusters.map(column => {
                    const linkId = storeLinks.find(link => link[BusinessUnitMaster__c.fieldApiName] == column.clustId && link[ReferenceYear__c.fieldApiName] == year)?.Id ?? null;
                    // saved link not flagged for deletion, or checked but not saved yet
                    const isSelected = (linkId != null && !this.BuDetailListToDelete.includes(linkId)) || this.pendingLinkIndex(store.Id, column.clustId, year) != -1;
                    return { ...column, id: linkId, isSelected: isSelected };
                });
                return { year, yearIndex, isDisplayed, hasCluster, Clusters: cells, totals: this.calculateTotals(cells) };
            })
        };
    }

    // WD / Sell Out Fact totals of the selected cells (+ the texts shown in the footer helptext)
    calculateTotals(cells) {
        let totals = { weightedDistribution: 0, sellOutFact: 0 };
        for (let cell of cells) {
            if (cell.isSelected) {
                totals.weightedDistribution += Number(cell.clusterWD || 0);
                totals.sellOutFact += Number(cell.clusterSelloutFact || 0);
            }
        }
        const wdText = this.label.LBL_WD + ' : ' + totals.weightedDistribution;
        const sofText = this.label.LBL_SellOutFact + ' : ' + totals.sellOutFact;
        totals.weightedDistributionStr = totals.weightedDistribution ? wdText : '';
        totals.sellOutFactStr = ' ' + sofText;
        totals.sellOutFactWDStr = wdText + ' ' + sofText;
        return totals;
    }

    // Index of a link queued for insert, -1 when there is none
    pendingLinkIndex(storeId, clusterId, year) {
        return this.BuDetailListToUpdate.findIndex(link =>
            link[BusinessUnitDetail__c.fieldApiName] == storeId &&
            link[BusinessUnitMaster__c.fieldApiName] == clusterId &&
            link[ReferenceYear__c.fieldApiName] == year
        );
    }

    // CLUSTER SELECTION
    handlecheckBoxes(event) {
        try {
            const { hierarchyIndex, clientCategoryIndex, storeIndex, yearIndex, buIndex, storeid: storeId } = event.target.dataset;
            const year = Number(event.target.dataset.year);
            const clientCategory = this.assortmentStoreData[hierarchyIndex].clientCategories[clientCategoryIndex];
            const yearDetail = clientCategory.stores[storeIndex].details[yearIndex];
            const clickedCell = yearDetail.Clusters[buIndex];
            const unselectCell = (cell) => {
                const pendingIndex = this.pendingLinkIndex(storeId, cell.clustId, year);
                if (pendingIndex != -1) {
                    this.BuDetailListToUpdate.splice(pendingIndex, 1);
                } else if (cell.id && !this.BuDetailListToDelete.includes(cell.id)) {
                    this.BuDetailListToDelete.push(cell.id);
                }
                cell.isSelected = false;
            };
            if (event.target.checked) {
                // one strategy per type (Cplt / non Cplt) unless the BU allows multiple complementary ones
                if (!clickedCell.isCplt || !this.isMultipleComplementary) {
                    yearDetail.Clusters
                        .filter(cell => cell.isSelected && cell.isCplt === clickedCell.isCplt && cell.assortmentStrat != clickedCell.assortmentStrat)
                        .forEach(unselectCell);
                }
                if (clickedCell.id) {
                    // re-checking a saved link only cancels its deletion
                    this.BuDetailListToDelete = this.BuDetailListToDelete.filter(id => id != clickedCell.id);
                } else {
                    this.BuDetailListToUpdate.push({
                        attributes: { type: BU_Detail_OBJECT.objectApiName },
                        RecordTypeId: this.BUListDetailRecordType,
                        [BusinessUnitDetail__c.fieldApiName]: storeId,
                        [BusinessUnitMaster__c.fieldApiName]: clickedCell.clustId,
                        [ReferenceYear__c.fieldApiName]: year
                    });
                }
                clickedCell.isSelected = true;
            } else {
                unselectCell(clickedCell);
            }
            // refresh the store total of that year and the cluster totals in the footer
            yearDetail.totals = this.calculateTotals(yearDetail.Clusters);
            clientCategory.stratTotal[yearIndex].strats.forEach((clusterTotal, clusterIndex) => {
                Object.assign(clusterTotal, this.calculateTotals(clientCategory.stores.map(store => store.details[yearIndex].Clusters[clusterIndex])));
            });
        } catch (error) {
            console.log('handlecheckBoxes: %c' + error.message, 'color : red');
        }
    }

    // SAVE / CANCEL
    handleSave() {
        this.pageLoading = true;
        saveData({
            detailToUpdate: JSON.stringify(this.BuDetailListToUpdate),
            detailToDelete: JSON.stringify(this.BuDetailListToDelete)
        }).then(() => {
            showNotification(this, this.label.LBL_Success, this.label.MSG_Successfully_Saved, 'success', 'sticky');
            this.BuDetailListToUpdate = [];
            this.BuDetailListToDelete = [];
            this.loadData();
        }).catch(error => {
            showNotification(this, this.label.LBL_Error, error.body?.message || error.message, 'error', 'sticky');
            this.pageLoading = false;
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.recordId, actionName: 'view' }
        });
    }

    // WEIGHTED DISTRIBUTION MODAL
    toggleWeightedDistributionModal() {
        this.isShowWeightedDistributionModal = !this.isShowWeightedDistributionModal;
    }

    handleStoresEdit(event) {
        const { storeId, field } = event.target.dataset;
        let store = this.storesToSave.find(item => item.Id == storeId);
        if (!store) {
            store = { attributes: { type: BU__OBJECT.objectApiName }, Id: storeId };
            this.storesToSave.push(store);
        }
        store[field] = event.target.value;
    }

    handleSaveWeighted() {
        this.toggleWeightedDistributionModal();
        this.pageLoading = true;
        saveStores({ storesToSave: JSON.stringify(this.storesToSave) }).then(() => {
            this.storesToSave = [];
            this.loadData();
        }).catch(error => {
            showNotification(this, this.label.LBL_Error, error.body?.message || error.message, 'error', 'sticky');
            this.pageLoading = false;
        });
    }

    // FILTERS
    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }

    fillFilterData(event) {
        this.filters.store = event.target.value;
    }

    handleHierarchyChange(event) {
        const values = event.detail.selOptions.map(option => option.value);
        this.selectedHierarchy = JSON.stringify(values);
        this.filters.hierarchy = values.filter(value => value != 'all');
    }

    showClientCategoryPicklist = true;

    handleClientCategoryChange(event) {
        const allOptions = this.initDataWrapper.filterOptions.categoriesOptions.map(option => option.value);
        const values = event.detail.selOptions.map(option => option.value).filter(value => value != 'all');
        if (values.length > 0) {
            this.selectedClientCategory = JSON.stringify(values);
            this.filters.clientCategory = values.length == allOptions.length ? [] : values;
            return;
        }
        this.selectedClientCategory = JSON.stringify(['all', ...allOptions]);
        this.filters.clientCategory = [];
        this.showClientCategoryPicklist = false;
        setTimeout(() => { this.showClientCategoryPicklist = true; }, 0);
    }

    handleMultiYearSelection(event) {
        this.selectedYears = event.detail.selOptions.map(option => option.value);
        this.selectedYearsJson = JSON.stringify(this.selectedYears);
    }

    showWD() {
        localStorage.setItem('ShowWDValues', !this.isShowWD);
    }

    showSellOutFact() {
        localStorage.setItem('ShowSellOutFactValues', !this.isShowSellOutFact);
    }

    // resets the filter panel with the options already loaded by initData, then reloads the grid
    handleReset() {
        const { categoriesOptions, hierarchyOptions } = this.initDataWrapper.filterOptions;
        this.filters = { store: '', hierarchy: [], clientCategory: [] };
        this.selectedClientCategory = JSON.stringify(['all', ...categoriesOptions.map(option => option.value)]);
        this.selectedHierarchy = JSON.stringify(['all', ...hierarchyOptions.map(option => option.value)]);
        this.selectedYears = [this.currentYear, this.currentYear + 1];
        this.selectedYearsJson = JSON.stringify([this.currentYear, this.currentYear + 1]);
        localStorage.setItem('ShowWDValues', false);
        localStorage.setItem('ShowSellOutFactValues', false);
        this.pageNumber = 1;
        this.loadData();
    }

    // PAGINATION
    handleChangePage(event) {
        const type = event.target.dataset.type;
        if (type == 'First') {
            this.pageNumber = 1;
        } else if (type == 'Previous') {
            this.pageNumber--;
        } else if (type == 'Next') {
            this.pageNumber++;
        } else if (type == 'Last') {
            this.pageNumber = this.totalPagesCount;
        }
        this.loadData();
    }

    handleChangePageSize(event) {
        try {
            this.pageSize = parseInt(event.target.value);
            for (let option of this.pageSizeOptions) {
                option.isSelected = option.value == this.pageSize;
            }
            this.pageNumber = 1;
            this.loadData();
        }
        catch (error) {
            console.error('error: ' + error);
        }
    }

    // LAYOUT
    changeHeight = () => {
        const header = this.template.querySelector('.header');
        const mainPanel = this.template.querySelector('.main-panel');
        const mainHeight = window.innerHeight - (header ? header.getBoundingClientRect().height : 0) - 167;
        this.tableHeight = 'background-color: #FFFFFF !important;width:100%; height:' + (mainHeight - parseInt(mainHeight * 0.09)) + 'px;';
        if (mainPanel) {
            mainPanel.style.height = mainHeight + 'px';
        }
    };

    // Pins the hierarchy band, each client category band, the two header rows and the frozen columns
    setFixedLayout() {
        try {
            const outerTable = this.template.querySelector('.outter-table');
            const stick = (cell, { left, top, zIndex, backgroundColor }) => {
                cell.style.position = 'sticky';
                if (left !== undefined) cell.style.left = left + 'px';
                if (top !== undefined) cell.style.top = top + 'px';
                cell.style.zIndex = String(zIndex);
                cell.style.backgroundColor = cell.style.backgroundColor || backgroundColor;
            };
            let hierarchyBandHeight = 0;
            if (outerTable) {
                const hierarchyCells = outerTable.querySelectorAll('tr.hierarchy-band > td');
                hierarchyBandHeight = hierarchyCells.length ? hierarchyCells[0].offsetHeight : 0;
                hierarchyCells.forEach(cell => stick(cell, { left: 0, top: 0, zIndex: 11, backgroundColor: '#0d807d' }));
            }
            this.template.querySelectorAll('.inner-table').forEach(table => {
                const thead = table.tHead;
                if (!thead) return;
                // the client category band is the first header row when the category has a name
                const bandRow = thead.rows[0]?.classList.contains('client-category-band') ? thead.rows[0] : null;
                if (bandRow) {
                    stick(bandRow.cells[0], { top: hierarchyBandHeight, zIndex: 10, backgroundColor: '#5aa9a6' });
                }
                const start = bandRow ? 1 : 0;
                const headerRow = thead.rows[start];
                if (!headerRow) return;
                const secondRow = thead.rows[start + 1] || null;
                const topOffset = hierarchyBandHeight + (bandRow ? bandRow.offsetHeight : 0);
                const fixedLefts = [];
                let left = 0;
                for (let index = 0; index < this.nbOfFixedColumns && index < headerRow.cells.length; index++) {
                    fixedLefts.push(left - index);
                    left += headerRow.cells[index].offsetWidth;
                }
                for (const row of table.rows) {
                    const isHeader = row.parentNode.tagName === 'THEAD';
                    if (isHeader && row !== headerRow && row !== secondRow) continue;
                    // the frozen columns span both header rows, so nothing is frozen on the left of the second one
                    const lefts = row === secondRow ? [] : fixedLefts;
                    const top = row === headerRow ? topOffset : row === secondRow ? topOffset + headerRow.offsetHeight : undefined;
                    for (let index = 0; index < row.cells.length; index++) {
                        const cell = row.cells[index];
                        const isFrozenColumn = index < lefts.length;
                        if (!isHeader && !isFrozenColumn) continue;
                        stick(cell, {
                            left: isFrozenColumn ? lefts[index] : undefined,
                            top: top,
                            zIndex: isHeader ? (isFrozenColumn ? 6 : 4) : 3,
                            backgroundColor: '#ffffff'
                        });
                    }
                }
            });
        } catch (error) {
            console.log('setFixedLayout: %c' + error.message, 'color : red');
        }
    }
}