import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

// STATIC RESSOURCES
import ICON_RESOURCES from "@salesforce/resourceUrl/iconResources";
import JSZIP from "@salesforce/resourceUrl/jszip";

import { labels } from './properties.js';

const ALL_CATEGORIES = 'all';
const PREVIEW_SIZE = 'medium';
const SIZES = ['small', 'medium', 'large'];
const DEFAULT_SIZE = 'default';
const SIZE_LABELS = {
    small: labels.LBL_Connect_IconSizeSmall,
    medium: labels.LBL_Connect_IconSizeMedium,
    large: labels.LBL_Connect_IconSizeLarge
};
const IMAGE_FILE = /\.(png|jpe?g|gif|svg|webp)$/i;
// An SVG whose root is hidden is a sprite sheet (slds/symbols): its symbols only show when
// another page references them, so on its own it renders blank. Only large SVGs are read to check.
const SPRITE_SHEET_MIN_SIZE = 50000;
const HIDDEN_SVG = /<svg\b[^>]*\bdisplay="none"/;

// Shared by every picker opened on the page, so the zip is read once.
let iconListRequest;

// Salesforce serves a file inside a zip resource by its path but cannot list the zip, so the
// list is read from the zip itself with JSZip. Only the file names are read: no image is
// extracted, each one is loaded by its URL when it shows on screen.
export function loadIconList(component) {
    if (!iconListRequest) {
        iconListRequest = loadScript(component, JSZIP).then(() => fetch(ICON_RESOURCES)).then(response => {
            if (!response.ok) {
                throw new Error(ICON_RESOURCES + ' returned ' + response.status);
            }
            return response.arrayBuffer();
        }).then(data => window.JSZip.loadAsync(data)).then(buildIconList).catch(error => {
            iconListRequest = undefined;
            throw error;
        });
    }
    return iconListRequest;
}

// An icon is either a folder holding the same image in several sizes
// (iconResources/slds/account/account_small.svg, _medium, _large) or a single file directly
// in a category (iconResources/sprites/spritesheet.png).
function buildIconList(zip) {
    const icons = new Map();
    const hiddenChecks = [];
    Object.values(zip.files).forEach(entry => {
        const parts = entry.name.split('/');
        if (entry.dir || !IMAGE_FILE.test(entry.name) || parts.length < 3 || parts.length > 4) {
            return;
        }
        const fileName = parts[parts.length - 1];
        const category = parts[1];
        const name = parts.length === 4 ? parts[2] : fileName.replace(/\.[^.]+$/, '');
        const key = category + '/' + name;
        if (!icons.has(key)) {
            icons.set(key, { category: category, name: name, sizes: {} });
        }
        const sizes = icons.get(key).sizes;
        const size = sizeOf(fileName);
        if (!sizes[size]) {
            sizes[size] = entry.name;
        }
        const uncompressedSize = entry._data && entry._data.uncompressedSize;
        if (/\.svg$/i.test(fileName) && uncompressedSize > SPRITE_SHEET_MIN_SIZE) {
            hiddenChecks.push(entry.async('string').then(svg => {
                if (HIDDEN_SVG.test(svg.slice(0, 2000))) {
                    icons.delete(key);
                }
            }));
        }
    });
    return Promise.all(hiddenChecks).then(() =>
        Array.from(icons.values())
            .map(icon => ({
                category: icon.category,
                name: icon.name,
                sizes: [...SIZES, DEFAULT_SIZE].filter(size => icon.sizes[size])
                    .reduce((ordered, size) => ({ ...ordered, [size]: icon.sizes[size] }), {})
            }))
            .sort((a, b) => byName(a.category, b.category) || byName(a.name, b.name))
    );
}

function sizeOf(fileName) {
    const stem = fileName.replace(/\.[^.]+$/, '').toLowerCase();
    return SIZES.find(size => stem.endsWith('_' + size)) || DEFAULT_SIZE;
}

function byName(a, b) {
    const left = a.toLowerCase();
    const right = b.toLowerCase();
    return left < right ? -1 : left > right ? 1 : 0;
}

export default class IconResourcePicker extends LightningElement {
    //LABELS
    labels = labels;
    icons = [];
    iconsByKey = new Map();
    filteredIcons = [];
    selectedCategory = ALL_CATEGORIES;
    searchTerm = '';
    selectedIcon;
    isLoading = true;
    hasLoadError = false;
    hasFocusedSearch = false;

    //LIFECYCLE
    connectedCallback() {
        loadIconList(this).then(iconList => {
            this.icons = iconList.map(icon => {
                const sizes = Object.keys(icon.sizes).map(size => ({
                    name: size,
                    label: SIZE_LABELS[size] || size,
                    url: ICON_RESOURCES + '/' + icon.sizes[size]
                }));
                return {
                    key: icon.category + '/' + icon.name,
                    category: icon.category,
                    name: icon.name,
                    searchName: icon.name.toLowerCase(),
                    url: ICON_RESOURCES + '/' + (icon.sizes[PREVIEW_SIZE] || Object.values(icon.sizes)[0]),
                    sizes: sizes
                };
            });
            this.icons.forEach(icon => this.iconsByKey.set(icon.key, icon));
            this.applyFilters();
        }).catch(error => {
            console.log('%c' + error.message, 'color : red');
            this.hasLoadError = true;
        }).finally(() => {
            this.isLoading = false;
        });
    }

    renderedCallback() {
        if (this.showGrid && !this.hasFocusedSearch) {
            const searchInput = this.template.querySelector('lightning-input');
            if (searchInput) {
                searchInput.focus();
                this.hasFocusedSearch = true;
            }
        }
    }

    //GETTERS
    get showGrid() {
        return !this.isLoading && !this.hasLoadError && !this.selectedIcon;
    }

    get showSizes() {
        return !this.isLoading && !this.hasLoadError && !!this.selectedIcon;
    }

    get hasResults() {
        return this.filteredIcons.length > 0;
    }

    get categoryOptions() {
        const counts = {};
        this.icons.forEach(icon => {
            counts[icon.category] = (counts[icon.category] || 0) + 1;
        });
        const options = [{ name: ALL_CATEGORIES, label: this.labels.LBL_All + ' (' + this.icons.length + ')' }];
        Object.keys(counts).sort().forEach(category => {
            options.push({ name: category, label: category + ' (' + counts[category] + ')' });
        });
        return options.map(option => ({
            ...option,
            variant: option.name === this.selectedCategory ? 'brand' : 'neutral'
        }));
    }

    //EVENT HANDLERS
    handleSearch(event) {
        this.searchTerm = event.target.value || '';
        this.applyFilters();
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.target.dataset.category;
        this.applyFilters();
    }

    handleIconClick(event) {
        const icon = this.iconsByKey.get(event.currentTarget.dataset.key);
        if (icon.sizes.length > 1) {
            this.selectedIcon = icon;
        } else {
            this.selectIcon(icon.sizes[0].url);
        }
    }

    handleSizeSelect(event) {
        this.selectIcon(event.target.dataset.url);
    }

    handleBack() {
        this.selectedIcon = undefined;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.handleClose();
        }
    }

    //HELPERS
    applyFilters() {
        const term = this.searchTerm.trim().toLowerCase();
        this.filteredIcons = this.icons.filter(icon =>
            (this.selectedCategory === ALL_CATEGORIES || icon.category === this.selectedCategory)
            && (!term || icon.searchName.includes(term))
        );
    }

    selectIcon(url) {
        this.dispatchEvent(new CustomEvent('iconselect', {
            detail: { url: url }
        }));
    }
}