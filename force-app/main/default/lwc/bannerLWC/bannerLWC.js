import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Toast from 'lightning/toast';
import getBannerData from '@salesforce/apex/RecordBannerCtrl.getBannerData';
import getObjectActions from '@salesforce/apex/RecordBannerCtrl.getObjectActions';

export default class BannerLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api titleFieldApiName = 'Name';
    @api detailFieldsApiNames = '';
    @api selectedActionApiNames = '';
    @api iconName = 'standard:record';
    @api showObjectActions;

    isLoading = true;
    titleValue = '';
    detailFields = [];
    objectLabel = '';
    actions = [];
    errorMessage = '';
    hasInitializedLoad = false;

    connectedCallback() {
        this.tryLoadBannerData();
    }

    renderedCallback() {
        this.tryLoadBannerData();
    }

    get hasActions() {
        return this.shouldShowObjectActions && this.actions.length > 0;
    }

    get primaryActions() {
        return (this.actions || []).slice(0, 2);
    }

    get overflowActions() {
        return (this.actions || []).slice(2);
    }

    get hasOverflowActions() {
        return this.overflowActions.length > 0;
    }

    get shouldShowObjectActions() {
        return this.showObjectActions !== false;
    }

    get bannerActions() {
        return this.overflowActions.map((action) => ({
            label: action.label,
            value: action.key
        }));
    }

    get hasDetailFields() {
        return this.detailFields && this.detailFields.length > 0;
    }

    loadBannerData() {
        this.isLoading = true;
        this.errorMessage = '';

        getBannerData({
            recordId: this.recordId,
            objectApiName: this.objectApiName,
            titleFieldApiName: this.titleFieldApiName,
            detailFieldsApiNames: this.detailFieldsApiNames
        })
            .then((result) => {
                this.titleValue = result && result.titleValue ? result.titleValue : '';
                this.detailFields = this.normalizeDetailFields(result && result.detailFields ? result.detailFields : []);
                this.objectLabel = result && result.objectLabel ? result.objectLabel : '';
            })
            .then(() => {
                if (!this.shouldShowObjectActions) {
                    this.actions = [];
                    return;
                }
                return getObjectActions({ objectApiName: this.objectApiName }).then((result) => {
                    const serverActions = this.withStandardActions(result || []);
                    this.actions = this.prepareActions(this.filterActions(serverActions));
                });
            })
            .catch((error) => {
                this.errorMessage = this.getErrorMessage(error);
                this.showToast('Banner', this.errorMessage, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    tryLoadBannerData() {
        if (this.hasInitializedLoad) {
            return;
        }
        if (!this.recordId || !this.objectApiName) {
            return;
        }
        this.hasInitializedLoad = true;
        this.loadBannerData();
    }

    handleActionSelect(event) {
        const actionKey = event.detail.value;
        if (!actionKey) {
            return;
        }
        const action = this.actions.find((item) => item.key === actionKey);
        this.executeAction(action);
    }

    handlePrimaryActionClick(event) {
        const actionKey = event.currentTarget.dataset.actionKey;
        if (!actionKey) {
            return;
        }
        const action = this.actions.find((item) => item.key === actionKey);
        this.executeAction(action);
    }

    executeAction(action) {
        if (!action) {
            return;
        }
        const standardActionName = this.resolveStandardActionName(action);
        if (standardActionName) {
            this.navigateToStandardActionUrl(standardActionName);
            return;
        }
        if (action.targetUrl) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.resolveTargetUrl(action.targetUrl)
                }
            });
            return;
        }
        const apiName = this.resolveQuickActionApiName(action);
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                apiName: apiName
            },
            state: {
                recordId: this.recordId
            }
        });
    }

    resolveStandardActionName(action) {
        const candidates = [
            this.normalizeToken(action.name),
            this.normalizeToken(action.apiName),
            this.normalizeToken(action.label)
        ].filter((value) => !!value);

        // if (this.matchesStandardAction(candidates, 'delete')) {
        //     return 'delete';
        // }
        if (this.matchesStandardAction(candidates, 'edit')) {
            return 'edit';
        }
        if (this.matchesStandardAction(candidates, 'clone')) {
            return 'clone';
        }
        return '';
    }

    matchesStandardAction(candidates, target) {
        return candidates.some((value) => value === target || value.endsWith(`.${target}`) || value.endsWith(`_${target}`));
    }

    navigateToStandardActionUrl(actionName) {
        if (!this.recordId || !this.objectApiName || !actionName) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/lightning/r/${this.objectApiName}/${this.recordId}/${actionName}`
            }
        });
    }

    filterActions(actions) {
        const selected = this.parseCsv(this.selectedActionApiNames);
        if (selected.length === 0) {
            return actions;
        }
        const selectedNormalized = selected.map((item) => this.normalizeToken(item));
        const selectedOrderedActions = [];
        selected.forEach((selectedToken, index) => {
            const match = actions.find((action) => this.isSelectedAction(action, [selectedNormalized[index]]));
            if (match) {
                selectedOrderedActions.push(match);
                return;
            }
            selectedOrderedActions.push(this.buildFallbackSelectedAction(selectedToken));
        });
        return selectedOrderedActions;
    }

    parseCsv(csv) {
        if (!csv) {
            return [];
        }
        return String(csv)
            .split(',')
            .map((item) => item.trim())
            .filter((item) => !!item);
    }

    normalizeDetailFields(fields) {
        return (fields || []).map((field) => {
            const recordId = field.lookupRecordId;
            return {
                ...field,
                hasLink: !!recordId,
                recordUrl: recordId ? `/${recordId}` : ''
            };
        });
    }

    withStandardActions(actions) {
        const output = [...(actions || [])];
        const selected = this.parseCsv(this.selectedActionApiNames).map((item) => item.toLowerCase());
        const base = [
            { label: 'Edit', name: 'edit', type: 'standard' },
            { label: 'Clone', name: 'clone', type: 'standard' },
            { label: 'Delete', name: 'delete', type: 'standard' }
        ];
        base.forEach((stdAction) => {
            const exists = output.some((action) => this.normalizeToken(action.name) === this.normalizeToken(stdAction.name));
            const requested = selected.includes(stdAction.name);
            if (!exists && requested) {
                output.push(stdAction);
            }
        });
        return output;
    }

    prepareActions(actions) {
        return (actions || []).map((action, index) => ({
            ...action,
            key: `${action.name || 'action'}_${index}`
        }));
    }

    isSelectedAction(action, selectedNormalized) {
        const actionName = this.normalizeToken(action.name);
        const actionApiName = this.normalizeToken(action.apiName);
        const actionLabel = this.normalizeToken(action.label);
        const actionShortName = actionName.includes('.') ? actionName.split('.').pop() : actionName;
        const actionApiShortName = actionApiName.includes('.') ? actionApiName.split('.').pop() : actionApiName;
        return selectedNormalized.some(
            (token) =>
                token === actionName ||
                token === actionApiName ||
                token === actionShortName ||
                token === actionApiShortName ||
                token === actionLabel
        );
    }

    resolveQuickActionApiName(action) {
        const apiName = String(action.apiName || action.name || '').trim();
        if (!apiName) {
            return '';
        }
        if (apiName.includes('.')) {
            return apiName;
        }
        return `${this.objectApiName}.${apiName}`;
    }

    resolveTargetUrl(targetUrl) {
        let url = String(targetUrl || '');
        if (!url) {
            return '';
        }
        url = url.replace(/\{\![^}]*Id\}/gi, this.recordId || '');
        url = url.replace(/\{\!ID\}/gi, this.recordId || '');
        return url;
    }

    buildFallbackSelectedAction(selectedToken) {
        const token = String(selectedToken || '').trim();
        const normalizedToken = this.normalizeToken(token);
        const label = this.humanizeToken(token);
        if (token.startsWith('/') || token.startsWith('http://') || token.startsWith('https://')) {
            return {
                label: label,
                name: normalizedToken || `selected_url_${Date.now()}`,
                type: 'detailButton',
                apiName: '',
                targetUrl: token
            };
        }
        const lower = normalizedToken.toLowerCase();
        if (lower === 'edit' || lower === 'delete' || lower === 'clone') {
            return {
                label: this.humanizeToken(lower),
                name: lower,
                type: 'standard',
                apiName: lower,
                targetUrl: ''
            };
        }
        return {
            label: label,
            name: normalizedToken || token,
            type: 'selectedFallback',
            apiName: token,
            // Detail-button style fallback. Works for many VF button scenarios.
            targetUrl: `/apex/${token.replace(/[^a-zA-Z0-9_]/g, '')}?id=${this.recordId || ''}`
        };
    }

    humanizeToken(token) {
        return String(token || '')
            .replace(/[_-]+/g, ' ')
            .replace(/\s+/g, ' ')
            .trim();
    }

    normalizeToken(value) {
        return String(value || '')
            .trim()
            .toLowerCase()
            .replace(/[^a-z0-9_\.]/g, '');
    }

    getErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        if (error && error.message) {
            return error.message;
        }
        return 'Unexpected error while loading banner data.';
    }

    showToast(title, message, variant, mode = 'dismissable') {
        Toast.show(
            {
                label: title,
                message: message,
                variant: variant,
                mode: mode
            },
            this
        );
    }
}