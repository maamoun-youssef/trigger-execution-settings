import { LightningElement, api, track } from 'lwc';
import iconResources from '@salesforce/resourceUrl/iconResources';
import JSZipLib from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import LOGOS from '@salesforce/resourceUrl/logos';

import getAllLogos from '@salesforce/apex/BackblazeHelper.getAllLogos';
import getCMSImages from '@salesforce/apex/CMSController.getCMSImages';

export default class LogoRenderer extends LightningElement {
  @api imageName;

  @api sprite = false;
  @api width = 100;
  @api height = 100;
  @api posX = 0;
  @api posY = 0;

  @track imageUrl;
  @track error = '';

  jsZipLoaded = false;
  
  cmsImages = [];
  cdnImages = [];

 // ---------- Static caches to share across instances ----------
  static imageCache = {};
    static cdnCache = [];   
    static cmsCache = [];   


  connectedCallback() {
    this.loadImage();
    
  }

  getMimeType(fileName) {
        const ext = fileName.split('.').pop().toLowerCase();
        return ext === 'svg' ? 'svg+xml' : ext;
    }


    async loadImage() {
        if (!this.imageName) {
            this.error = 'No image name provided.';
            return;
        }

        const cleanName = this.imageName.replace(/\.[^/.]+$/, '');

        //  Return cached image if already loaded
        if (LogoRenderer.imageCache[this.imageName]) {
            this.imageUrl = LogoRenderer.imageCache[this.imageName];
            return;
        }

        let found = false;

        try {
            // ---------- Load JSZip only once ----------
            if (!this.jsZipLoaded) {
                await loadScript(this, JSZipLib);
                this.jsZipLoaded = true;
            }

            // ---------- Load ZIP images ----------
            const zipUrls = [iconResources, LOGOS];
            const zipPromises = zipUrls.map(async url => {
                const res = await fetch(url);
                const blob = await res.blob();
                return window.JSZip.loadAsync(blob);
            });

            const zips = await Promise.all(zipPromises);

            for (const zip of zips) {
                for (const path of Object.keys(zip.files)) {
                    const file = zip.files[path];
                    const fileName = file.name.split('/').pop();
                    if (!file.dir && fileName === this.imageName) {
                        const fileData = await file.async('base64');
                        const mimeType = this.getMimeType(fileName);
                        const url = `data:image/${mimeType};base64,${fileData}`;
                        this.imageUrl = url;
                        LogoRenderer.imageCache[this.imageName] = url;
                        found = true;
                        break;
                    }
                }
                if (found) break;
            }

            // ---------- Load CDN (Backblaze) images ----------
            if (!found) {
                if (!LogoRenderer.cdnCache.length) {
                    const cdnData = await getAllLogos(); // Apex call once
                    LogoRenderer.cdnCache = cdnData.map(img => ({
                        name: img.name.replace(/\.[^/.]+$/, ''),
                        url: img.url
                    }));
                }

                const cdnMatch = LogoRenderer.cdnCache.find(img => img.name === cleanName);
                if (cdnMatch) {
                    this.imageUrl = cdnMatch.url;
                    LogoRenderer.imageCache[this.imageName] = cdnMatch.url;
                    found = true;
                }
            }

            // ---------- Load CMS images ----------
            if (!found) {
                if (!LogoRenderer.cmsCache.length) {
                    const cmsData = await getCMSImages(); // Apex call once
                    LogoRenderer.cmsCache = cmsData.map(img => ({
                        name: img.urlName,
                        url: img.imageUrl
                    }));
                }

                const cmsMatch = LogoRenderer.cmsCache.find(img => img.name === cleanName);
                if (cmsMatch) {
                    this.imageUrl = cmsMatch.url;
                    LogoRenderer.imageCache[this.imageName] = cmsMatch.url;
                    found = true;
                }
            }

            // ---------- Fallback ----------
            if (!found) {
                this.error = `Image "${this.imageName}" not found in ZIPs, CDN, or CMS.`;
            }

        } catch (err) {
            console.error('Error loading image:', err);
            this.error = 'Error loading image.';
        }
    }


  get isSprite() {
    return this.sprite === true || this.sprite === 'true';
  }

  get spriteStyle() {
    return `
      width: ${this.width}px;
      height: ${this.height}px;
      background-image: url('${this.imageUrl}');
      background-repeat: no-repeat;
      background-position: ${this.posX}px ${this.posY}px;
      background-size: auto;
      display: inline-block;
    `;
  }
}