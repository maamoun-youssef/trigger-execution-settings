import { LightningElement, track } from 'lwc';
import getImageResources from '@salesforce/apex/IconController.getImageResources';
import getZipImageResources from '@salesforce/apex/IconController.getZipImageResources';
import getSessionKeys from '@salesforce/apex/IconController.getSessionKeys';
import JSZipLib from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const counter = {
  imageCounter: 0,
}
export default class IconsScreen extends LightningElement {
  @track searchTerm = '';
  @track images = [];
  @track selectedImage = null;
  @track isFromZip = false;
  @track sessionKeys;
  @track selectedImageName = '';
  @track filteredImages = [];
  jsZipLoaded = false;
  connectedCallback() {
    getSessionKeys().then((keys) => {
      this.sessionKeys = keys;
      return loadScript(this, JSZipLib);
    }).then(() => {
      this.jsZipLoaded = true;
      this.loadResources();
    }).catch((error) => {
      console.error('Error during initialization:', error);
    });
  }
  async loadResources() {
    try {
      const data = await getImageResources();
      const staticImages = data.map((res) => ({
        id: counter.imageCounter++,
        name: res.name,
        url: res.url,
        isZip: false,
        cssClass: `image-item${res.name === this.selectedImageName ? ' selected' : ''}`,
      }));
      this.images = [...this.images, ...staticImages];
      if (this.searchTerm && staticImages.name.toLowerCase().includes(this.searchTerm)) {
        this.filteredImages.push(staticImages);
      }
    } catch (error) {
      console.error('Error loading standard images:', error);
    }
    try {
      const zipList = await getZipImageResources();
      for (const zip of zipList) {
        const zipName = zip.name;
        const response = await fetch(zip.fetchUrl, {
          headers: {
            Authorization: `Bearer ${this.sessionKeys.KeyPageWSubstring}`,
          },
          method: 'GET',
        });
        const blob = await response.blob();
        const JSZip = await window.JSZip.loadAsync(blob);
        JSZip.forEach(async (relativePath, zipEntry) => {
          if (!zipEntry.dir && /\.(png|jpe?g|svg)$/i.test(zipEntry.name)) {
            const fileData = await zipEntry.async('base64');
            const folderPath = zipEntry.name.substring(0, zipEntry.name.lastIndexOf('/'));
            const fileName = zipEntry.name.split('/').pop();
            const image = {
              id: counter.imageCounter++,
              name: fileName,
              url: `data:image/${this.getFileType(fileName)};base64,${fileData}`,
              isZip: true,
              zipName,
              zipFolder: folderPath,
              fileName,
              cssClass: `image-item${fileName === this.selectedImageName ? ' selected' : ''}`,
            };
            this.images.push(image);
            if (!this.searchTerm || image.name.toLowerCase().includes(this.searchTerm)) {
              this.filteredImages = [...this.filteredImages, image];
            }
          }
        });
      }
    } catch (error) {
      console.error('Error loading ZIPs:', error);
    }
  }
  getFileType(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    return ext === 'svg' ? 'svg+xml' : ext;
  }
  onSearchChange(event) {
    try {
      let searchTerm = event?.target?.value?.toLowerCase();
      this.searchTerm = searchTerm;
      console.log('1');
      let images = this.images;
      console.log(`🚀 ---------------------------------------------------🚀`);
      console.log(`🚀 ~ IconsScreen ~ onSearchChange ~ images:`, images);
      console.log(`🚀 ---------------------------------------------------🚀`);
      if (searchTerm) {
        console.log('2');
        this.filteredImages = [...images.filter((image) => image.name.toLowerCase().includes(searchTerm))];
        console.log('3');
      } else {
        console.log('4');
        this.filteredImages = [...images];
        console.log('5');
      }
      console.log('6');
    } catch (error) {
      console.error('Error occurred during search:', error);
    }
  }
  get leftPanelClass() {
    return this.selectedImage ? 'left-panel half-width' : 'left-panel full-width';
  }
  handleImageClick(event) {
    const imageName = event.currentTarget.querySelector('img').alt;
    const image = this.filteredImages.find((img) => img.name === imageName);
    this.template.querySelectorAll('.selected').forEach(it => it.classList.remove('selected'));
    event.currentTarget.classList.add('selected');
    if (image) {
      this.selectedImage = image;
      this.selectedImageName = image.name;
      this.isFromZip = image.isZip || false;
      setTimeout(() => {
        const section = this.template.querySelector('[data-id="code-section"]');
        if (section) {
          section.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }, 0);
    }
  }
  get dynamicHtml() {
    if (!this.selectedImage) return '';
    const cleanName = this.selectedImage.name
      .replace(/\.[^/.]+$/, '')
      .replace(/[-_.]/g, '');
    if (this.isFromZip) {
      return (
        `&lt;div class="logo-class" style={${cleanName}}&gt;&lt;/div&gt;`
      );
    } else {
      return (
        `&lt;img src={${this.selectedImage.name}} alt="${this.selectedImage.name}" class="example-image" /&gt;`
      );
    }
  }
  get dynamicJs() {
    if (!this.selectedImage) return '';
    const cleanName = this.selectedImage.name
      .replace(/\.[^/.]+$/, '')
      .replace(/[-_.]/g, '');
    if (this.isFromZip) {
      const { zipName, zipFolder, fileName } = this.selectedImage;
      return (
        `import ${zipName} from '@salesforce/resourceUrl/${zipName}';
    export default class Example extends LightningElement {
      @track ${cleanName} = \`background-image: url('\${${zipName} + '/${zipFolder}/${fileName}'}')\`;
    }`
      );
    } else {
      return (
        `import ${this.selectedImage.name} from '@salesforce/resourceUrl/${this.selectedImage.name}';
    export default class Example extends LightningElement {
      imageUrl = ${this.selectedImage.name};
    }`
      );
    }
  }
  get dynamicCss() {
    return this.isFromZip
      ? `.logo-class {\n  width: 100px;\n  height: 100px;\n  background-size: contain;\n  background-repeat: no-repeat;\n  border: 1px solid #ddd;\n  border-radius: 4px;\n  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);\n}`
      : `.example-image {\n  max-width: 100px;\n  border: 1px solid #ddd;\n  border-radius: 4px;\n  padding: 4px;\n  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);\n}`;
  }
  copyHtml() {
    this.copyToClipboard(this.dynamicHtml.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  }
  copyJs() {
    this.copyToClipboard(this.dynamicJs);
  }
  copyCss() {
    this.copyToClipboard(this.dynamicCss);
  }
  copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Copied!',
        message: 'Code has been copied to clipboard.',
        variant: 'success',
      })
    );
  }
}