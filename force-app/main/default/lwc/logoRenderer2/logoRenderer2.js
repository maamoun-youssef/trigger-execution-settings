import { LightningElement, api } from 'lwc';

const VIDEO = /\.(mp4|webm|ogg|mov|m4v)$/i;

// Hosts that are always internal Salesforce (Lightning, Visualforce), never a site
const INTERNAL_HOST = /\.(lightning|vf|visual)\.force\.com$/i;
// Paths that are internal pages even on a my.salesforce.com host
const INTERNAL_PATH = /^\/(lightning|flow|apex|one)(\/|$)/i;

const safeDecode = part => {
    try {
        return decodeURIComponent(part);
    } catch {
        return part;
    }
};

// The prefixes static resources can be served under, most likely first.
// The @salesforce/community imports are not used on purpose: they throw in flows outside a site.
//   Internal Lightning:   /resource/...
//   Aura site:            /{site}/s/page        -> /{site}/sfsites/c/resource/...
//   LWR site:             /{site}/page          -> /{site}/sfsites/c/resource/...
//   Site on a root domain:                      -> /sfsites/c/resource/...
const prefixes = () => {
    const { hostname, pathname } = window.location;
    if (INTERNAL_HOST.test(hostname) || INTERNAL_PATH.test(pathname)) return [''];

    const candidates = [];
    const aura = pathname.match(/^(.*?)\/s(\/|$)/);
    if (aura) candidates.push(`${aura[1]}/sfsites/c`);
    const firstSegment = pathname.match(/^\/[^/]+/);
    if (firstSegment) candidates.push(`${firstSegment[0]}/sfsites/c`);
    candidates.push('/sfsites/c', ''); // root-domain site, then internal as a last resort
    return [...new Set(candidates)];
};

export default class LogoRenderer extends LightningElement {
    @api alt;  // defaults to the file name
    @api size; // optional: a number (px) or any CSS length, e.g. "3rem"

    attempt = 0; // index of the prefix being tried; moves on each time the file fails to load
    _path;

    // Accepts a resource path ("MyIcons/logos/acme.png"), a /resource/ url (internal or portal),
    // or a full / blob: / data: url, which is used as is
    @api
    get path() {
        return this._path;
    }
    set path(value) {
        this._path = value;
        this.attempt = 0; // a new path starts again from the most likely prefix
    }

    get value() {
        return (this._path || '').trim();
    }

    get isAbsolute() {
        return /^(blob:|data:|https?:)/i.test(this.value);
    }

    get candidates() {
        return this.isAbsolute ? [''] : prefixes();
    }

    get url() {
        const value = this.value;
        if (!value) return null;
        if (this.isAbsolute) return value;

        // Keep only what comes after /resource/, whatever prefix was passed (/resource/, /sfsites/c/resource/, /site/...)
        const index = value.indexOf('/resource/');
        const rest = index >= 0 ? value.slice(index + '/resource/'.length) : value.replace(/^\//, '');

        // Decode then encode each segment, so both "my logo.png" and "my%20logo.png" work
        const encoded = rest.split('/').map(part => encodeURIComponent(safeDecode(part))).join('/');
        return `${this.candidates[this.attempt]}/resource/${encoded}`;
    }

    get showMedia() {
        return this.url && this.attempt < this.candidates.length;
    }

    get isVideo() {
        return VIDEO.test((this.url || '').split(/[?#]/)[0]);
    }

    get altText() {
        return this.alt || safeDecode((this._path || '').split('/').pop());
    }

    get style() {
        if (!this.size) return '';
        const size = /^\d+$/.test(String(this.size)) ? `${this.size}px` : this.size;
        return `width: ${size}; height: ${size}`;
    }

    // Tries the next prefix; once all have failed, showMedia turns false and nothing is shown
    handleError() {
        this.attempt++;
    }
}