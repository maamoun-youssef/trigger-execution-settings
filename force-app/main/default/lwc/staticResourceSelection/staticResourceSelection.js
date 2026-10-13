import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import JSZIP from '@salesforce/resourceUrl/jszip';
import getStaticResources from '@salesforce/apex/StaticResourceSelectionController.getStaticResources';

// File kind from a file name (inside a zip) or a content type (static resource)
const FILE_KINDS = {
    image: /\.(jpe?g|png|gif|webp|svg|bmp|ico|avif)$|^image\//i,
    video: /\.(mp4|webm|ogg|mov|m4v)$|^video\//i,
    zip: /\.zip$|^application\/.*zip/i
};
const kindOf = name => Object.keys(FILE_KINDS).find(kind => FILE_KINDS[kind].test(name));
const BATCH_SIZE = 60; // gallery tiles added each time the end of the grid scrolls into view
const NOT_SERVED = 'Not available: Salesforce cannot serve files from a zip inside a zip';

export default class StaticResourceSelection extends LightningElement {
    @api label = 'Search static resources...';
    @api isExplorer = false; // true: dropdown tree picker, false: gallery of every image
    @api height;             // gallery: optional fixed height (e.g. "40rem"); by default it fills the window

    root = { children: [] }; // its children are the static resources; reassigned to re-render the tree
    nodes = new Map();       // id -> node, to find what a clicked row or tile refers to
    blobUrls = [];           // urls of files inside nested zips, freed on destroy
    selected = null;
    loading = true;
    error;
    explorerSearch = '';
    isOpen = false;
    gallerySearch = '';
    folder = 'all';
    zipsDone = 0; // gallery progress; each change re-renders, so images appear zip by zip
    zipsTotal = 0;
    limit = BATCH_SIZE;
    tileSize = 112;
    previewSize = 128;
    windowHeight = 640; // gallery height (px) when no fixed height is given, updated on window resize

    @api
    get value() {
        return this.selected?.url ?? null;
    }
    set value(path) {
        const url = path && (/\/resource\/|^blob:/.test(path) ? path : `/resource/${path.replace(/^\//, '')}`);
        if (url === this.selected?.url) return; // the parent echoing back our own selection
        this.selected = url && { name: decodeURIComponent(url.split('/').pop()), url, kind: kindOf(url), path: decodeURIComponent(url.replace(/^\/resource\//, '')) };
        this.explorerSearch = url || '';
    }

    async connectedCallback() {
        try {
            await loadScript(this, JSZIP);
            // Smallest first, so in the gallery icon packs show before big libraries finish downloading
            const resources = [...await getStaticResources()].sort((a, b) => a.BodyLength - b.BodyLength);
            for (const { Name, NamespacePrefix, ContentType } of resources) {
                const name = NamespacePrefix ? `${NamespacePrefix}__${Name}` : Name;
                const url = `/resource/${name}`;
                this.addNode(this.root, name, kindOf(ContentType), url, () => fetch(url).then(response => response.blob()));
            }
            if (this.isExplorer) return;
            // Gallery: opens every zip at every depth, in parallel. A broken zip is skipped.
            const unzipAll = nodes => Promise.all(nodes.map(async node => {
                if (node.kind === 'zip') {
                    this.zipsTotal++;
                    await this.unzip(node).catch(e => console.warn(`Cannot open ${node.name}`, e));
                    this.zipsDone++;
                }
                await unzipAll(node.children);
            }));
            await unzipAll(this.root.children);
        } catch (e) {
            this.error = e.body?.message || e.message;
        } finally {
            this.loading = false;
        }
    }

    disconnectedCallback() {
        this.blobUrls.forEach(url => URL.revokeObjectURL(url));
        this.observer?.disconnect();
        window.removeEventListener('resize', this.fitToWindow);
    }

    renderedCallback() {
        if (this.isExplorer) return;
        // Gallery fills the window from its top edge down (16px bottom margin, never below 320px).
        // Measured on first render, then again whenever the window is resized.
        if (!this.fitToWindow) {
            this.fitToWindow = () => {
                const top = this.refs.layout.getBoundingClientRect().top + window.scrollY;
                this.windowHeight = Math.max(320, window.innerHeight - top - 16);
            };
            window.addEventListener('resize', this.fitToWindow);
            this.fitToWindow();
        }
        // Watches the marker under the last tile. Re-observing after every render fires again
        // while the marker is still visible, so batches keep loading until the view is full.
        this.observer ??= new IntersectionObserver(([entry]) => entry.isIntersecting && (this.limit += BATCH_SIZE));
        this.observer.disconnect();
        if (this.refs.more) this.observer.observe(this.refs.more);
    }

    addNode(parent, name, kind, url = null, loadBlob = null) {
        const path = parent.path ? `${parent.path}/${name}` : name;
        const node = { id: String(this.nodes.size), name, kind, url, loadBlob, path, folder: parent.path || '/', children: [], expandable: kind === 'folder' || kind === 'zip' };
        this.nodes.set(node.id, node);
        parent.children.push(node);
        return node;
    }

    // Adds the images, videos and nested zips of a zip, creating its folders along the way
    async unzip(zipNode) {
        const zip = await window.JSZip.loadAsync(await zipNode.loadBlob());
        const folders = {}; // "a/b/" -> folder node
        for (const entry of Object.values(zip.files)) {
            const kind = kindOf(entry.name);
            if (entry.dir || !kind || entry.name.startsWith('__MACOSX')) continue;
            const folderNames = entry.name.split('/');
            const fileName = folderNames.pop();
            let parent = zipNode;
            let folderPath = '';
            for (const folderName of folderNames) {
                folderPath += `${folderName}/`;
                parent = folders[folderPath] ??= this.addNode(parent, folderName, 'folder');
            }
            // Salesforce serves files of a top-level zip directly; files of a nested zip get a blob url
            // (SVG needs its mime type). A nested zip itself has no url, it is read from its blob.
            let url = null;
            if (kind !== 'zip' && zipNode.url) {
                url = `${zipNode.url}/${entry.name.split('/').map(encodeURIComponent).join('/')}`;
            } else if (kind !== 'zip') {
                url = URL.createObjectURL(new Blob([await entry.async('blob')], { type: /\.svg$/i.test(fileName) ? 'image/svg+xml' : '' }));
                this.blobUrls.push(url);
            }
            this.addNode(parent, fileName, kind, url, () => entry.async('blob'));
        }
    }

    // Sets the selection, shows its url in the explorer input and tells the parent (null when cleared)
    select(node) {
        this.selected = node;
        this.explorerSearch = node?.url ?? '';
        this.dispatchEvent(new CustomEvent('optionselect', { detail: node && { name: node.name, url: node.url, path: node.path, type: node.kind } }));
    }

    // ---------- Explorer ----------

    // The tree flattened into rows, zips last in each level.
    // While searching, a node shows if its name matches or one of its (already opened) children does.
    get rows() {
        const term = this.explorerSearch === this.selected?.url ? '' : this.explorerSearch.trim().toLowerCase();
        const toRows = (nodes, level) => [...nodes]
            .sort((a, b) => (a.kind === 'zip') - (b.kind === 'zip'))
            .flatMap(node => {
                const childRows = node.expanded || term ? toRows(node.children, level + 1) : [];
                if (term && !childRows.length && !node.name.toLowerCase().includes(term)) return [];
                return [{
                    ...node,
                    icon: { folder: 'doctype:folder', zip: 'doctype:zip', video: 'doctype:video' }[node.kind],
                    isImage: node.kind === 'image',
                    chevron: node.expandable && !node.empty && (node.expanded || childRows.length ? 'utility:chevrondown' : 'utility:chevronright'),
                    style: `padding-left: ${level * 1.25 + 0.5}rem`,
                    css: node.url && node.url === this.selected?.url ? 'srs-row srs-row_selected' : 'srs-row'
                }, ...childRows];
            });
        return toRows(this.root.children, 0);
    }

    get isVideo() {
        return this.selected?.kind === 'video';
    }

    handleSearch(event) {
        this.explorerSearch = event.target.value;
        if (this.explorerSearch || !this.selected) {
            this.isOpen = true;
        } else {
            this.select(null); // the box was cleared
            setTimeout(() => (this.isOpen = false));
        }
    }

    // A file is selected; a folder or zip opens/closes, and a zip is unzipped the first time it opens
    async handleRowClick(event) {
        const node = this.nodes.get(event.currentTarget.dataset.id);
        if (node.empty) return;
        if (!node.expandable) {
            this.isOpen = false;
            this.select(node);
            return;
        }
        node.expanded = !node.expanded;
        if (node.kind === 'zip' && !node.loaded && !node.loading) {
            node.loading = true;
            this.root = { ...this.root };
            try {
                await this.unzip(node);
                node.loaded = true;
                node.empty = !node.children.length;
            } catch (e) {
                node.expanded = false;
                node.children = [];
                this.dispatchEvent(new ShowToastEvent({ title: `Cannot open ${node.name}`, message: e.message, variant: 'error' }));
            }
            node.loading = false;
        }
        this.root = { ...this.root };
    }

    // A click on the search box flips the list, leaving the box closes it
    toggleList(event) {
        this.isOpen = event.type !== 'blur' && !this.isOpen;
    }

    // Keeps the search box focused (and the list open) when a row is clicked
    keepFocus(event) {
        event.preventDefault();
    }

    // ---------- Gallery ----------

    // Every image matching the search and folder; only the first `limit` are rendered
    get matches() {
        const term = this.gallerySearch.trim().toLowerCase();
        return [...this.nodes.values()].filter(node => node.kind === 'image' && (this.folder === 'all' || node.folder === this.folder) && node.name.toLowerCase().includes(term));
    }

    get tiles() {
        return this.matches.slice(0, this.limit).map(node => ({
            ...node,
            css: `srs-tile slds-box slds-box_x-small${node.url === this.selected?.url ? ' slds-theme_shade srs-tile_selected' : ''}`
        }));
    }

    // Empty once everything is shown, which also hides the "load more" marker
    get countLabel() {
        const total = this.matches.length;
        return total > this.limit ? `Showing ${this.limit} of ${total}` : '';
    }

    get folderOptions() {
        const folders = new Set([...this.nodes.values()].filter(node => node.kind === 'image').map(node => node.folder));
        return [{ label: 'All', value: 'all' }, ...[...folders].sort().map(folder => ({ label: folder, value: folder }))];
    }

    get layoutStyle() {
        return `height: ${this.height || `${this.windowHeight}px`}`;
    }

    get galleryStyle() {
        return `grid-template-columns: repeat(auto-fill, minmax(${this.tileSize}px, 1fr))`;
    }

    get previewStyle() {
        return `width: ${this.previewSize}px; height: ${this.previewSize}px`;
    }

    // Copyable snippets. Files from nested zips only have a blob url, so no URL or formula for them.
    get snippets() {
        const { url, name, path } = this.selected;
        const served = !url.startsWith('blob:');
        return [
            { label: 'URL', value: served ? url : NOT_SERVED, disabled: !served },
            { label: 'Formula field', value: served ? `IMAGE("${url}", "${name}")` : NOT_SERVED, disabled: !served },
            { label: 'Component', value: `<c-logo-renderer path="${path}"></c-logo-renderer>` }
        ];
    }

    // Search box and folder picker set the field named by their name attribute, then the grid restarts at the top
    handleFilter(event) {
        this[event.target.name] = event.detail.value;
        this.limit = BATCH_SIZE;
        if (this.refs.gallery) this.refs.gallery.scrollTop = 0;
    }

    // A tile selects its image; the close button has no data-id, so it clears the selection
    handleSelect(event) {
        this.select(this.nodes.get(event.currentTarget.dataset.id) ?? null);
    }

    // Resize disabled for now (buttons are commented out in the HTML)
    // The - / + buttons: data-name is the field to change, data-step how much to add (32 to 224 px)
    // resize(event) {
    //     const { name, step } = event.currentTarget.dataset;
    //     this[name] = Math.min(224, Math.max(name === 'tileSize' ? 64 : 32, this[name] + Number(step)));
    // }

    async copy(event) {
        await navigator.clipboard.writeText(event.target.dataset.value);
        this.dispatchEvent(new ShowToastEvent({ title: 'Copied to clipboard', variant: 'success' }));
    }
}