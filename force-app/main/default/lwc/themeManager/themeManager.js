import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadAllData from '@salesforce/apex/ThemeSettingsController.loadAllData';
import save from '@salesforce/apex/ThemeSettingsController.save';
import generateThemeTokensPreview from '@salesforce/apex/ThemeSettingsController.generateThemeTokensPreview';
import { showNotification, checkDeploymentStatus } from 'c/appHelper';

const SUCCESS_VARIANT = 'success';
const ERROR_VARIANT = 'error';
const INFO_VARIANT = 'info';
const WARNING_VARIANT = 'warning';
const STICKY_VARIANT = 'sticky';

const FONT_OPTIONS = [
    // TrueType Core Fonts
    { label: 'Andale Mono',     value: "'Andale Mono', monospace" },
    { label: 'Arial',           value: "'Arial', sans-serif" },
    { label: 'Arial Black',     value: "'Arial Black', sans-serif" },
    { label: 'Comic Sans MS',   value: "'Comic Sans MS', cursive" },
    { label: 'Courier New',     value: "'Courier New', monospace" },
    { label: 'Georgia',         value: "'Georgia', serif" },
    { label: 'Impact',          value: "'Impact', sans-serif" },
    { label: 'Times New Roman', value: "'Times New Roman', serif" },
    { label: 'Trebuchet MS',    value: "'Trebuchet MS', sans-serif" },
    { label: 'Verdana',         value: "'Verdana', sans-serif" },
    { label: 'Webdings',        value: "'Webdings'" },
    // ClearType Fonts
    { label: 'Calibri',    value: "'Calibri', sans-serif" },
    { label: 'Cambria',    value: "'Cambria', serif" },
    { label: 'Candara',    value: "'Candara', sans-serif" },
    { label: 'Consolas',   value: "'Consolas', monospace" },
    { label: 'Constantia', value: "'Constantia', serif" },
    { label: 'Corbel',     value: "'Corbel', sans-serif" },
    // Salesforce / web fonts
    { label: 'Inter',            value: "'Inter', sans-serif" },
    { label: 'Salesforce Sans',  value: "'Salesforce Sans', Arial, sans-serif" },
    { label: 'Poppins',          value: "'Poppins', sans-serif" },
    { label: 'Roboto',           value: "'Roboto', sans-serif" },
    // Fallback
    { label: 'System Default',   value: "system-ui, -apple-system, sans-serif" }
];

const RADIUS_OPTIONS = [
    { label: 'Sharp (0px)', value: '0px' },
    { label: 'Subtle (2px)', value: '2px' },
    { label: 'Default (4px)', value: '4px' },
    { label: 'Rounded (8px)', value: '8px' },
    { label: 'Very Rounded (12px)', value: '12px' },
    { label: 'Pill (16px)', value: '16px' }
];

export default class ThemeManager extends LightningElement {
    @track loadingData = false;
    @track themes = [];
    @track initThemesList = [];
    @track searchTerm = '';
    @track selectedTheme; 
    @track newThemeName = '';
    @track addNewTheme = false;
    @track isSaving = false;
    @track showPreview = false;

    fontOptions = FONT_OPTIONS;
    radiusOptions = RADIUS_OPTIONS;

    // ─── LIFECYCLE ───
    connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        this.loadAllData();
    }

    renderedCallback() {
        if (this.template.querySelector('.main-header') && this.template.querySelector('.main-div')) {
            this.changeHeight();
        }
        const selectedName = this.selectedTheme?.name;
        for (var elem of this.template.querySelectorAll('.menuItem')) {
            if (!selectedName || elem.dataset.name !== selectedName) {
                elem.setAttribute('aria-current', false);
            } else {
                elem.setAttribute('aria-current', 'page');
            }
        }
    }

    // ─── LOAD ───
    loadAllData() {
        this.showPreview = false;
        this.themes = [];
        this.initThemesList = [];
        this.loadingData = true;
        try {
            loadAllData().then((result) => {
                this.themes = JSON.parse(result) || [];
                this.initThemesList = [...this.themes];
                this.sortThemes();
                this.loadingData = false;
            }).catch(error => {
                this.loadingData = false;
                console.error(error);
                showNotification(this, 'Error', error, ERROR_VARIANT, STICKY_VARIANT);
            });
        } catch (error) {
            this.loadingData = false;
            console.error(error);
            showNotification(this, 'Error', error, ERROR_VARIANT);
        }
    }

    sortThemes() {
        this.themes.sort((a, b) => {
            if (a.name === undefined) return -1;
            if (b.name === undefined) return 1;
            let aValue = a.name.toLowerCase();
            let bValue = b.name.toLowerCase();
            return aValue > bValue ? 1 : bValue > aValue ? -1 : 0;
        });
    }

    get filteredThemes() {
        const term = this.searchTerm.trim().toLowerCase();
        return this.themes
            .filter(t => !term || t.name.toLowerCase().includes(term))
            .map(t => {
                const font = t.themeAttributes?.fontFamily || '';
                const fontMatch = FONT_OPTIONS.find(o => o.value === font);
                return {
                    name: t.name,
                    fontFamily: font,
                    fontLabel: fontMatch ? fontMatch.label : 'Custom',
                    swatchStyle: `background: ${t.themeAttributes?.brandColor || '#ccc'};`
                };
            });
    }

    get hasSelectedTheme() {
        return !!(this.selectedTheme && this.selectedTheme.themeAttributes);
    }

    get disableName() {
        return !this.isNewTheme || this.isSaving;
    }

    // ─── SEARCH ───
    handleSearch(event) {
        this.searchTerm = event.detail.value;
    }

    // ─── SELECTION ───
    handleThemeCardClick(event) {
        const theme = this.themes.find(t => t.name === event.currentTarget.dataset.name);
        if (!theme) return;
        this.selectedTheme = theme;
        this.showPreview = false;
        console.log('Selected theme:', JSON.stringify(this.selectedTheme));
        this.isNewTheme = false;
    }

    toggleAddNewTheme() {
        this.addNewTheme = !this.addNewTheme;
    }

    handleAddNewTheme() {
        if(!this.newThemeName || !this.newThemeName.trim()) {
            showNotification(this, 'Missing name', 'Please enter a theme name.', WARNING_VARIANT);
            return;
        }
        this.showPreview = false;
        this.selectedTheme = {
            name: this.newThemeName,
            themeAttributes: {
                brandColor: '#0176D3',
                bgColor: '#ffffff',
                fontFamily: "'Inter', sans-serif",
                borderRadius: '4px'
            }
        }
        this.newThemeName = '';
        this.themes.push(this.selectedTheme);
        this.toggleAddNewTheme();
    }

    handleOnChangeNewTheme(event) {
        this.newThemeName = event.detail.value;
    }

    handleAttributeChange(event) {
        let attrName = event.target.dataset.attributeName;
        const value = event.detail.value;
        if(attrName == 'name'){
            this.selectedTheme.name = value;
            return;
        }
        if(attrName == 'brandColor'){
            this.selectedTheme.themeAttributes.brandColor = value; 
        }
        if(attrName == 'bgColor'){
            this.selectedTheme.themeAttributes.bgColor = value; 
        }
        if(attrName == 'fontFamily'){
            this.selectedTheme.themeAttributes.fontFamily = value; 
        }
        if(attrName == 'borderRadius'){
            this.selectedTheme.themeAttributes.borderRadius = value; 
        }
        this.applyPreview();
    }

    // ─── PREVIEW TOGGLE ───
    handlePreviewToggle(event) {
        if (event.target.checked && this.hasSelectedTheme) {
            this.applyPreview();
        } else {
            this.showPreview = false;
        }
    }

    // ─── PREVIEW ───
    applyPreview() {
        const { brandColor, bgColor, fontFamily, borderRadius } = this.selectedTheme.themeAttributes;
        return generateThemeTokensPreview({ brandColor:brandColor, 
                                            backgroundColor: bgColor, 
                                            fontFamily: fontFamily, 
                                            borderRadius: borderRadius }).then(tokensJson => {
                const tokens = JSON.parse(tokensJson);
                const scope = this.template.querySelector('[data-id="preview-scope"]');
                if (scope) {
                    Object.entries(tokens).forEach(([key, value]) => {
                        scope.style.setProperty(`--${key}`, value);
                    });
                }
                this.showPreview = true;
            }).catch(e => console.error('Preview failed:', e));
    }

    // ─── SAVE ───
    handleSave() {
        if (!this.selectedTheme.name || !this.selectedTheme.name.trim()) {
            showNotification(this, 'Missing name', 'Please enter a theme name.', WARNING_VARIANT);
            return;
        }
        this.loadingData = true;
        this.isSaving = true;
        try {
            save({ themeSettingsListJSON: JSON.stringify(this.selectedTheme)})
                .then((result) => {
                    checkDeploymentStatus(this, result, this.loadingData);
                    this.loadingData = false;
                    this.isSaving = false;
                    showNotification(this, 'Saved', `Theme "${this.selectedTheme.name}" saved successfully.`, SUCCESS_VARIANT, STICKY_VARIANT);
                    const sanitized = self.selectedTheme.name.replace(/\s+/g, '_').replace(/[^a-zA-Z0-9_]/g, '');
                    this.loadAllData();
                    this.selectedTheme.name = sanitized;
                })
                .catch(error => {
                    this.loadingData = false;
                    this.isSaving = false;
                    console.error(error);
                    showNotification(this, 'Error', error, ERROR_VARIANT, STICKY_VARIANT);
                });
        } catch (error) {
            this.loadingData = false;
            this.isSaving = false;
            console.error(error);
            showNotification(this, 'Error', error, ERROR_VARIANT);
        }
    }

    // ─── HEIGHT ───
    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.main-header')) {
            headerHeight = this.template.querySelector('.main-header').getBoundingClientRect().height;
        }
        let tableHeight = window.innerHeight - headerHeight - 160;
        if (this.template.querySelector('.main-div')) {
            this.template.querySelector('.main-div').style.height = tableHeight + 'px';
        }
    };
}