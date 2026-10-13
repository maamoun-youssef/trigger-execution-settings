import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Toast from 'lightning/toast';
import getBannerData from '@salesforce/apex/BannerSettingsPluginCmpController.getBannerData';
import getConfiguredBannerData from '@salesforce/apex/BannerSettingsPluginCmpController.getConfiguredBannerData';
import getObjectActions from '@salesforce/apex/BannerSettingsPluginCmpController.getObjectActions';

export default class BannerSettingsPlugin extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api titleFieldApiName = 'Name';
    @api detailFieldsApiNames = '';
    @api selectedActionApiNames = '';
    @api iconName = 'standard:record';
    @api templateName = '';
    @api showObjectActions;

    isLoading = true;
    titleValue = '';
    detailFields = [];
    subtitleField;
    objectLabel = '';
    actions = [];
    screenFlows = [];
    errorMessage = '';
    hasInitializedLoad = false;
    displayMode = 'horizontal';
    numberOfFieldsDisplay = 1;
    backgroundColor = '#ffffff';
    textColor = '#16325c';
    isActive = true;
    iconSize = '30px';

    connectedCallback() {
        this.tryLoadBannerData();
    }

    renderedCallback() {
        this.tryLoadBannerData();
    }

    get hasActions() {
        return this.showObjectActions !== false && (this.iconActions.length > 0 || this.buttonActions.length > 0);
    }

    get iconActions() {
        return (this.actions || []).filter((action) => action.type === 'screenFlow');
    }

    get buttonActions() {
        return (this.actions || []).filter((action) => action.type !== 'screenFlow');
    }

    get primaryActions() {
        return this.buttonActions.slice(0, 5);
    }

    get overflowActions() {
        return this.buttonActions.slice(5);
    }

    get hasOverflowActions() {
        return this.overflowActions.length > 0;
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

    get shouldRenderBanner() {
        return this.isActive !== false;
    }

    get headerStyle() {
        return `background-color:${this.backgroundColor || '#ffffff'}; color:${this.textColor || '#16325c'};`;
    }

    get detailFieldRows() {
        if (!this.hasDetailFields) {
            return [];
        }
        if (this.displayMode !== 'vertical') {
            return [{ key: 'row_0', fields: this.detailFields }];
        }
        const output = [];
        const perRow = Math.max(1, Number(this.numberOfFieldsDisplay) || 1);
        for (let index = 0; index < this.detailFields.length; index += perRow) {
            output.push({
                key: `row_${index}`,
                fields: this.detailFields.slice(index, index + perRow)
            });
        }
        return output;
    }

    get hasSubtitle() {
        return !!(this.subtitleField && this.subtitleField.value);
    }

    get resolvedIconName() {
        return this.isCustomIcon ? '' : this.iconName;
    }

    get isCustomIcon() {
        return this.iconName && !String(this.iconName).includes(':');
    }

    get normalizedIconSizePx() {
        const raw = String(this.iconSize || '').trim();
        if (!raw) {
            return '30px';
        }
        if (/^\d+$/.test(raw)) {
            return `${raw}px`;
        }
        return raw;
    }

    get mainIconImageStyle() {
        return `width:${this.normalizedIconSizePx};height:${this.normalizedIconSizePx};object-fit:contain;`;
    }

    get mainIconWrapperStyle() {
        return `width:${this.normalizedIconSizePx};height:${this.normalizedIconSizePx};display:inline-flex;align-items:center;justify-content:center;`;
    }

    get mainIconScaleStyle() {
        const numeric = parseFloat(String(this.normalizedIconSizePx).replace('px', ''));
        const scale = Number.isFinite(numeric) && numeric > 0 ? numeric / 16 : 1;
        return `transform:scale(${scale});`;
    }

    loadBannerData() {
        this.isLoading = true;
        this.errorMessage = '';
        const dataPromise = this.templateName
            ? getConfiguredBannerData({
                  recordId: this.recordId,
                  bannerConfigName: this.templateName
              })
            : getBannerData({
                  recordId: this.recordId,
                  objectApiName: this.objectApiName,
                  titleFieldApiName: this.titleFieldApiName,
                  detailFieldsApiNames: this.detailFieldsApiNames
              });

        dataPromise
            .then((payload) => {
                const result = payload ? JSON.parse(payload) : {};
                this.titleValue = result && result.titleValue ? result.titleValue : '';
                this.detailFields = this.normalizeDetailFields(result && result.detailFields ? result.detailFields : []);
                this.subtitleField = this.normalizeField(result && result.subtitleField ? result.subtitleField : null);
                this.objectLabel = result && result.objectLabel ? result.objectLabel : '';
                if (result && result.iconValue) {
                    this.iconName = this.normalizeBannerIconValue(result.iconType, result.iconValue);
                }
                if (result && result.selectedActionApiNames) {
                    this.selectedActionApiNames = result.selectedActionApiNames;
                }
                this.screenFlows = this.extractScreenFlows(result);
                if (result && result.objectApiName) {
                    this.objectApiName = result.objectApiName;
                }
                this.backgroundColor = result?.backgroundColor || '#ffffff';
                this.textColor = result?.textColor || '#16325c';
                this.isActive = result?.isActive !== false;
                this.iconSize = result?.iconSize || '30px';
                this.displayMode = result && result.displayMode ? String(result.displayMode).toLowerCase() : 'horizontal';
                this.numberOfFieldsDisplay =
                    result && result.numberOfFieldsDisplay ? Math.max(1, Number(result.numberOfFieldsDisplay) || 1) : 1;
            })
            .then(() => {
                if (this.showObjectActions === false) {
                    this.actions = [];
                    return;
                }
                const hasConfiguredQuickActions = this.parseCsv(this.selectedActionApiNames).length > 0;
                const hasConfiguredScreenFlows = Array.isArray(this.screenFlows) && this.screenFlows.length > 0;
                if (!hasConfiguredQuickActions && !hasConfiguredScreenFlows) {
                    this.actions = [];
                    return;
                }
                return getObjectActions({ objectApiName: this.objectApiName }).then((payload) => {
                    const parsed = payload ? JSON.parse(payload) : [];
                    const serverActions = this.withStandardActions(parsed || []);
                    const filteredActions = hasConfiguredQuickActions
                        ? this.prepareActions(this.filterActions(serverActions))
                        : [];
                    this.actions = [...this.mapScreenFlowsToActions(this.screenFlows), ...filteredActions];
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
        const requiresObjectApiName = !this.templateName;
        if (this.hasInitializedLoad || !this.recordId || (requiresObjectApiName && !this.objectApiName)) {
            return;
        }
        this.hasInitializedLoad = true;
        this.loadBannerData();
    }

    handleActionSelect(event) {
        const action = this.actions.find((item) => item.key === event.detail.value);
        this.executeAction(action);
    }

    handlePrimaryActionClick(event) {
        const action = this.actions.find((item) => item.key === event.currentTarget.dataset.actionKey);
        this.executeAction(action);
    }

    handleIconActionClick(event) {
        const action = this.actions.find((item) => item.key === event.currentTarget.dataset.actionKey);
        this.executeAction(action);
    }

    executeAction(action) {
        if (!action) {
            return;
        }
        if (action.type === 'screenFlow' && action.flowApiName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/flow/${encodeURIComponent(action.flowApiName)}`
                }
            });
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
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: { apiName: this.resolveQuickActionApiName(action) },
            state: { recordId: this.recordId }
        });
    }

    resolveStandardActionName(action) {
        const candidates = [this.normalizeToken(action.name), this.normalizeToken(action.apiName), this.normalizeToken(action.label)].filter(Boolean);
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
            attributes: { url: `/lightning/r/${this.objectApiName}/${this.recordId}/${actionName}` }
        });
    }

    filterActions(actions) {
        const selected = this.parseCsv(this.selectedActionApiNames);
        if (!selected.length) {
            return actions;
        }
        const selectedNormalized = selected.map((item) => this.normalizeToken(item));
        return selected.map((selectedToken, index) => {
            const match = actions.find((action) => this.isSelectedAction(action, [selectedNormalized[index]]));
            return match || this.buildFallbackSelectedAction(selectedToken);
        });
    }

    parseCsv(csv) {
        if (!csv) {
            return [];
        }
        return String(csv)
            .split(',')
            .map((item) => item.trim())
            .filter(Boolean);
    }

    normalizeDetailFields(fields) {
        return (fields || []).map((field) => {
            const labelMode = field.labelMode || 'fieldLabel';
            const customLabel = field.customLabel || '';
            const labelIcon = field.labelIcon || 'utility:info';
            return {
                ...field,
                hasLink: !!field.lookupRecordId,
                recordUrl: field.lookupRecordId ? `/${field.lookupRecordId}` : '',
                style: this.buildFieldStyle(field),
                isInline: field.labelPosition === 'inline',
                displayLabel: labelMode === 'customLabel' && customLabel ? customLabel : field.label,
                useIconLabel: labelMode === 'icon',
                useImageLabel: labelMode === 'icon' && !String(labelIcon).includes(':'),
                labelIcon
            };
        });
    }

    normalizeField(field) {
        if (!field) {
            return null;
        }
        return {
            ...field,
            hasLink: !!field.lookupRecordId,
            recordUrl: field.lookupRecordId ? `/${field.lookupRecordId}` : '',
            style: this.buildFieldStyle(field),
            isInline: field.labelPosition === 'inline'
        };
    }

    buildFieldStyle(field) {
        const styles = [];
        if (field?.color) styles.push(`color:${field.color}`);
        if (field?.bold) styles.push('font-weight:700');
        if (field?.italic) styles.push('font-style:italic');
        if (field?.underline) styles.push('text-decoration:underline');
        return styles.join(';');
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
            if (!exists && selected.includes(stdAction.name)) {
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

    mapScreenFlowsToActions(screenFlows) {
        return (screenFlows || [])
            .filter((item) => item)
            .map((item, index) => ({
                label: item.label || item.value || item.flowApiName || item.name || `Flow ${index + 1}`,
                name: `screen_flow_${index}`,
                type: 'screenFlow',
                flowApiName: item.value || item.flowApiName || item.name || '',
                displayType: item.displayType || 'Action',
                isIconDisplay: String(item.displayType || '').toLowerCase() === 'icon',
                iconName: item.icon && String(item.icon).includes(':') ? item.icon : 'utility:forward',
                iconUrl: item.icon && !String(item.icon).includes(':') ? item.icon : '',
                iconSize: String(item.displayType || '').toLowerCase() === 'icon' ? 'small' : 'x-small',
                iconImageStyle:
                    String(item.displayType || '').toLowerCase() === 'icon'
                        ? 'width:1.25rem;height:1.25rem;max-width:30px;max-height:30px;object-fit:contain;'
                        : 'width:1rem;height:1rem;max-width:30px;max-height:30px;object-fit:contain;',
                key: `screen_flow_${index}`
            }))
            .filter((item) => !!item.flowApiName);
    }

    extractScreenFlows(result) {
        if (Array.isArray(result?.screenFlows)) {
            return result.screenFlows;
        }
        const raw = result?.selectedActionsJson;
        if (!raw) {
            return [];
        }
        try {
            const parsed = JSON.parse(raw);
            return Array.isArray(parsed?.screenFlows) ? parsed.screenFlows : [];
        } catch (error) {
            return [];
        }
    }

    isSelectedAction(action, selectedNormalized) {
        const actionName = this.normalizeToken(action.name);
        const actionApiName = this.normalizeToken(action.apiName);
        const actionLabel = this.normalizeToken(action.label);
        const actionShortName = actionName.includes('.') ? actionName.split('.').pop() : actionName;
        const actionApiShortName = actionApiName.includes('.') ? actionApiName.split('.').pop() : actionApiName;
        return selectedNormalized.some(
            (token) => token === actionName || token === actionApiName || token === actionShortName || token === actionApiShortName || token === actionLabel
        );
    }

    resolveQuickActionApiName(action) {
        const apiName = String(action.apiName || action.name || '').trim();
        if (!apiName) {
            return '';
        }
        return apiName.includes('.') ? apiName : `${this.objectApiName}.${apiName}`;
    }

    resolveTargetUrl(targetUrl) {
        let url = String(targetUrl || '');
        if (!url) {
            return '';
        }
        url = url.replace(/\{\![^}]*Id\}/gi, this.recordId || '');
        return url.replace(/\{\!ID\}/gi, this.recordId || '');
    }

    buildFallbackSelectedAction(selectedToken) {
        const token = String(selectedToken || '').trim();
        const normalizedToken = this.normalizeToken(token);
        const label = this.humanizeToken(token);
        if (token.startsWith('/') || token.startsWith('http://') || token.startsWith('https://')) {
            return {
                label,
                name: normalizedToken || `selected_url_${Date.now()}`,
                type: 'detailButton',
                apiName: '',
                targetUrl: token
            };
        }
        if (['edit', 'delete', 'clone'].includes(normalizedToken.toLowerCase())) {
            return {
                label: this.humanizeToken(normalizedToken),
                name: normalizedToken,
                type: 'standard',
                apiName: normalizedToken,
                targetUrl: ''
            };
        }
        return {
            label,
            name: normalizedToken || token,
            type: 'selectedFallback',
            apiName: token,
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

    normalizeBannerIconValue(iconType, iconValue) {
        const raw = String(iconValue || '').trim();
        if (!raw) {
            return 'standard:record';
        }
        if (String(iconType || '').toLowerCase() !== 'staticresource') {
            return raw;
        }
        if (raw.startsWith('/resource/')) {
            return raw;
        }
        if (raw.startsWith('/resourceUrl/')) {
            return raw.replace('/resourceUrl/', '/resource/');
        }
        if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('/')) {
            return raw;
        }
        return `/resource/${raw}`;
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'Unexpected error while loading banner data.';
    }

    showToast(title, message, variant, mode = 'dismissable') {
        Toast.show({ label: title, message, variant, mode }, this);
    }
}