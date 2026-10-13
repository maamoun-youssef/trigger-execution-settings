import { api } from 'lwc';
import GridSettingsPluginV3 from 'c/gridSettingsPluginV3';

export default class InjectionLWCv2 extends GridSettingsPluginV3 {

    @api templateName;

    connectedCallback() {
        if (!this.templateName) {
            this.templateName = 'AssortmentMatrixBudget';
        }
        super.connectedCallback();
    }

    loadData(sortConfig = []) {
        console.log('🔵 injectionLWCv2: loadData() called');
        console.log('🔵 injectionLWCv2: sortConfig =', JSON.stringify(sortConfig));
        console.log('🔵 injectionLWCv2: initDataWrapper exists?', !!this.initDataWrapper);
        console.log('🔵 injectionLWCv2: gridSettingsManager exists?', !!this.initDataWrapper?.gridSettingsManager);
        // Check if initDataWrapper is ready before injecting
        if (this.initDataWrapper && this.initDataWrapper.gridSettingsManager) {
            console.log('🔵 injectionLWCv2: initDataWrapper is ready, injecting filters');
            console.log('🔵 injectionLWCv2: FILTERS BEFORE injection:', JSON.stringify(this.initDataWrapper.gridSettingsManager.FILTERS));
            this.injectFilters();
            console.log('🔵 injectionLWCv2: FILTERS AFTER injection:', JSON.stringify(this.initDataWrapper.gridSettingsManager.FILTERS));
            console.log('🔵 injectionLWCv2: filtersFieldsMap AFTER injection:', JSON.stringify(this.filtersFieldsMap));
        } else {
            console.warn('🔴 injectionLWCv2: initDataWrapper not ready - cannot inject filters');
        }
        console.log('🔵 injectionLWCv2: Calling super.loadData()');
        super.loadData(sortConfig);
    }

    injectFilters() {
        console.log('🔵 injectionLWCv2: injectFilters() called');
        // Initialize the filters map if it doesn't exist
        if (!this.filtersFieldsMap) {
            this.filtersFieldsMap = {};
        }
        this.numberOfFixedColumns = 2;
        console.log('🔵 numberOfFixedColumns set to:', this.numberOfFixedColumns);
        const nameFilterValue = 'Mir Raviveur Laine3LLot2x3L"FormatFamilial"-COSTCO';
        console.log('🔵 Setting Product__c filter to:', nameFilterValue);
        this.filtersFieldsMap['Product__c'] = {
            fieldName: 'Product__c',
            fieldLabel: 'Product Name',
            stringFieldType: 'REFERENCE',
            values: [nameFilterValue],
            value: nameFilterValue,
            value1: nameFilterValue,
            objectName: 'AssortmentDetail__c'
        };
        console.log('🔵 filtersFieldsMap["Product__c"] =', JSON.stringify(this.filtersFieldsMap['Product__c']));
        // CRITICAL: Update the existing Product__c filter in gridSettingsManager.FILTERS
        if (this.initDataWrapper?.gridSettingsManager?.FILTERS) {
            console.log('🔵 gridSettingsManager.FILTERS is an array with length:', this.initDataWrapper.gridSettingsManager.FILTERS.length);
            // Find the existing Product__c filter
            const existingFilter = this.initDataWrapper.gridSettingsManager.FILTERS.find(f => f.fieldName === 'Product__c');
            if (existingFilter) {
                console.log('🔵 Found existing Product__c filter, updating it');
                existingFilter.values = [nameFilterValue];
                existingFilter.value1 = nameFilterValue;
            } else {
                console.log('🔵 No existing Product__c filter found, pushing new one');
                this.initDataWrapper.gridSettingsManager.FILTERS.push({
                    fieldName: 'Product__c',
                    fieldLabel: 'Product Name',
                    stringFieldType: 'REFERENCE',
                    values: [nameFilterValue],
                    value1: nameFilterValue,
                    isFilterable: true,
                    objectName: 'AssortmentDetail__c'
                });
            }
            console.log('🔵 gridSettingsManager.FILTERS after update:', JSON.stringify(this.initDataWrapper.gridSettingsManager.FILTERS));
        } else {
            console.error('🔴 gridSettingsManager.FILTERS does not exist!');
        }
    }
}