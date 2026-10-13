import { LightningElement, track } from 'lwc';
import iconResources from '@salesforce/resourceUrl/iconResources';
import JSZipLib from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const counter = {
  imageCounter: 0,
};

export default class ResourcesScreen extends LightningElement {
  @track iconSearchTerm = '';
  @track iconImages = [];
  @track filteredIconImages = [];
  @track selectedImage = null;
  @track selectedImageName = '';
  @track isFromZip = true;
  @track selectedIconFolder = 'ALL';
  @track iconFolderOptions = [{ label: 'ALL', value: 'ALL' }];
  @track selectedSize = 'medium';
  @track mainPanelHeight = '';
  loadingData = true;
  @track spriteWidth = 100;
  @track spriteHeight = 100;
  @track spritePosX = 0;
  @track spritePosY = 0;
  @track imageNaturalWidth = 0;
  @track imageRenderedWidth = 0;
  //added
  @track imageNaturalHeight = 0;
  @track imageRenderedHeight = 0;
  //
  @track selectionMarkerX = 0;
  @track selectionMarkerY = 0;
  jsZipLoaded = false;
  @track selectedVariantImage = null;

  //added
@track imageSizeVariants = [];


  connectedCallback() {
    window.addEventListener('resize', this.changeHeight);
    loadScript(this, JSZipLib)
      .then(() => {
        this.jsZipLoaded = true;
        this.loadIconResourcesImages();
      })
      .catch((error) => {
        console.error('Error during JSZip loading:', error);
      });
  }



  renderedCallback() {
    this.changeHeight();
    
    if (this.selectedImage && this.selectedSize === 'medium') {
      const mediumImg = this.template.querySelector('img.medium');
      if (mediumImg && !mediumImg.classList.contains('selected-size')) {
        mediumImg.classList.add('selected-size');
      }
    }
  }
  changeHeight = () => {
    const offset = 170;
    const height = window.innerHeight - offset;
    this.mainPanelHeight = `height: ${height}px;`;
  };


async loadIconResourcesImages() {
  this.loadingData = true;
  try {
    const response = await fetch(iconResources);
    const blob = await response.blob();
    const zip = await window.JSZip.loadAsync(blob);

    const imagePromises = [];
    const folderSet = new Set();

    zip.forEach((relativePath, zipEntry) => {
      if (!zipEntry.dir && /\.(png|jpe?g|svg)$/i.test(zipEntry.name)) {
        const fileName = zipEntry.name.split('/').pop();
       

        // Get first-level folder inside iconResources (assumed folder structure: iconResources/<first-level-folder>/...)
        const folderParts = zipEntry.name.split('/');
        // Use index 1 for first-level folder after 'iconResources'
        const mainFolder = folderParts.length > 1 ? folderParts[1] : 'root';
        folderSet.add(mainFolder);

        const folderPath = zipEntry.name.substring(0, zipEntry.name.lastIndexOf('/')) || 'root';

        const promise = zipEntry.async('base64').then((fileData) => {
          return {
            id: counter.imageCounter++,
            name: fileName,
            url: `data:image/${this.getFileType(fileName)};base64,${fileData}`,
            isZip: true,
            zipName: 'iconResources',
            zipFolder: folderPath,
            mainFolder,  // <-- add this property for filtering
            fileName,
            cssClass: `image-item${fileName === this.selectedImageName ? ' selected' : ''}`,
          };
        });

        imagePromises.push(promise);
      }
    });

    const result = await Promise.all(imagePromises);
    this.iconImages = result;

    // Create folder filter options from first-level folders only
    const folders = Array.from(folderSet).sort();
    this.iconFolderOptions = [
      { label: 'ALL', value: 'ALL' },
      ...folders.map((folder) => ({
        label: folder,
        value: folder,
      })),
    ];

    this.applyIconFilters();
  } catch (error) {
    console.error('Error loading iconResources ZIP:', error);
  }
  this.loadingData = false;
}


/*applyIconFilters() {
  const searchTerm = this.iconSearchTerm.trim().toLowerCase();
  this.filteredIconImages = this.iconImages.filter((image) => {
    const isMediumSize = image.name.includes('medium');
    
    const isSprite = image.zipFolder.toLowerCase().includes('sprites'); 

    const matchesSearch = image.name.toLowerCase().includes(searchTerm);
    const matchesFolder =
      this.selectedIconFolder === 'ALL' || image.mainFolder === this.selectedIconFolder;

    return (isMediumSize || isSprite) && matchesSearch && matchesFolder;
  });
}*/



applyIconFilters() {
  const searchTerm = this.iconSearchTerm.trim().toLowerCase();

  this.filteredIconImages = this.iconImages.filter((image) => {
    const nameParts = image.name.split('_');
    const lastPart = nameParts[nameParts.length - 1];
    const size = lastPart ? lastPart.split('.')[0].toLowerCase() : '';

    const isMediumSize = size === 'medium';
    const isSprite = image.zipFolder.toLowerCase().includes('sprites');
    const matchesSearch = image.name.toLowerCase().includes(searchTerm);
    const matchesFolder =
      this.selectedIconFolder === 'ALL' || image.mainFolder === this.selectedIconFolder;

    return (isMediumSize || isSprite) && matchesSearch && matchesFolder;
  });
}



  onIconFolderChange(event) {
    this.selectedIconFolder = event.detail.value;
    this.applyIconFilters();
  }

  getFileType(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    return ext === 'svg' ? 'svg+xml' : ext;
  }

  onIconSearchChange(event) {
    this.iconSearchTerm = event?.target?.value?.toLowerCase();
    this.applyIconFilters();
  }

  get leftPanelClass() {
    return this.selectedImage ? 'left-panel half-width' : 'left-panel full-width';
  }



 handleImageClick(event) {
    const imageName = event.currentTarget.querySelector('img').alt;
    const image = this.filteredIconImages.find((img) => img.name === imageName);

    // Check if the clicked image is already selected
    const isAlreadySelected = this.selectedImageName === imageName;

    // If already selected, deselect it
    if (isAlreadySelected) {
        
        event.currentTarget.classList.remove('selected');

        
        this.selectedImage = null;
        this.selectedImageName = null;
        this.isFromZip = false;
        this.selectedSize = null;
        this.selectedVariantImage = null;

        this.imageSizeVariants = [];

      
        return; 
    }

    // Otherwise, select the new image
    this.template.querySelectorAll('.selected').forEach((el) => el.classList.remove('selected'));
    event.currentTarget.classList.add('selected');

    if (image) {
        this.selectedImage = image;
        this.selectedImageName = image.name;
        this.isFromZip = true;
        this.selectedSize = 'medium'; // Default to medium size

       

        
this.imageSizeVariants = this.sizesOfSelectedImage;
        const mediumVariant = this.imageSizeVariants.find(v => v.size === 'medium');
    this.selectedVariantImage = mediumVariant || null;
    }
}

 



  get dynamicRendererTag() {
    if (!this.selectedImage) return '';
    const image= this.selectedVariantImage || this.selectedImage;
    const imageName= image.name;
   
    const folderName = this.selectedImage.zipFolder.toLowerCase().split('/').pop();
    const isSprite = folderName === 'sprites';
    if (isSprite) {
      return `&lt;c-logo-renderer
    image-name="${imageName}"
    sprite="true"
    width="${this.spriteWidth}"
    height="${this.spriteHeight}"
    pos-x="${this.spritePosX}"
    pos-y="${this.spritePosY}"&gt;&lt;/c-logo-renderer&gt;`;
    }
    //added size
    return `&lt;c-logo-renderer image-name="${imageName}"&gt;&lt;/c-logo-renderer&gt;`;
  }

  



  // get dynamicFormula() {
  //   if (!this.selectedImage) return '';
  //   const { zipName, zipFolder, fileName, name } = this.selectedImage;
  //   const sizeMap = {
  //     small: 50,
  //     medium: 100,
  //     large: 150,
  //   };
  //   const size = sizeMap[this.selectedSize] || 100;
  //   return `IMAGE("/resource/${zipName}/${zipFolder}/${fileName}", "${name}", ${size}, ${size})`;
  // }

get dynamicFormula() {
  const image = this.selectedVariantImage || this.selectedImage;
  if (!image) return '';

  const { zipName, zipFolder, fileName, name } = image;

  if (this.isSpriteImage) {
    return `&lt;div title="${name}" style="width:${this.spriteWidth}px; height:${this.spriteHeight}px; background-image:url('/resource/${zipName}/${zipFolder}/${fileName}'); background-repeat:no-repeat; background-position:${this.spritePosX}px ${this.spritePosY}px; display:inline-block;"&gt;&lt;/div&gt;`;
  }

  const sizeMap = {
    small: 50,
    medium: 100,
    large: 150,
  };
  const size = sizeMap[this.selectedSize] || 100;

  return `IMAGE("/resource/${zipName}/${zipFolder}/${fileName}", "${name}")`;
}

 handleSizeClick(event) {
  const clickedSize = event.currentTarget.dataset.size;

  
  const previewContainer = this.template.querySelector('.example-preview');
  if (!previewContainer) return;

  
  previewContainer.querySelectorAll('img').forEach((img) => {
    img.classList.remove('selected-size');

  });

  
  const clickedImg = event.currentTarget.querySelector('img');
  if (clickedImg) {
    clickedImg.classList.add('selected-size');
  }

  
  this.selectedSize = clickedSize;

   const imageName = event.currentTarget.dataset.name;
  const variant = this.imageSizeVariants.find(img => img.name === imageName);
  if (variant) {
    this.selectedVariantImage = variant;
  }
}

  copyFormula() {
    this.copyToClipboard(this.dynamicFormula.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  }

  copyRendererTag() {
    this.copyToClipboard(this.dynamicRendererTag.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  }

  get isSpriteImage() {
    if (!this.selectedImage) return false;
    const folderName = this.selectedImage.zipFolder.toLowerCase().split('/').pop();
    return folderName === 'sprites';
  }

  get spriteStyle() {
    if (!this.selectedImage) return '';
    return `
      width: ${this.spriteWidth}px;
      height: ${this.spriteHeight}px;
      background-image: url('${this.selectedImage.url}');
      background-repeat: no-repeat;
      background-position: ${this.spritePosX}px ${this.spritePosY}px;
      background-size: auto;
      display: inline-block;
    `;
  }

  handleSpriteInputChange(event) {
    const { name, value } = event.target;
    const numericValue = parseInt(value, 10) || 0;
    if (name === 'width') this.spriteWidth = numericValue;
    if (name === 'height') this.spriteHeight = numericValue;
    if (name === 'posX') this.spritePosX = numericValue;
    if (name === 'posY') this.spritePosY = numericValue;
    if (this.imageRenderedWidth && this.imageNaturalWidth) {
      const scaleX = this.imageNaturalWidth / this.imageRenderedWidth;
      const scaleY = scaleX;
      if (name === 'posX') {
        this.selectionMarkerX = -numericValue / scaleX -5 ;
      }
      if (name === 'posY') {
        this.selectionMarkerY = -numericValue / scaleY -5  ;
      }
    }
  }

  
 captureImageDimensions(event) {
  this.imageRenderedWidth = event.target.clientWidth;
  this.imageRenderedHeight = event.target.clientHeight; 
  this.imageNaturalWidth = event.target.naturalWidth;
  this.imageNaturalHeight = event.target.naturalHeight;  
}


  /*handleSpriteClick(event) {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const clickY = event.clientY - rect.top;
    this.selectionMarkerX = clickX - 5;
    this.selectionMarkerY = clickY - 5;
    const scaleX = this.imageNaturalWidth / this.imageRenderedWidth;
    const scaleY = scaleX;
    this.spritePosX = -Math.round(clickX * scaleX);
    this.spritePosY = -Math.round(clickY * scaleY);
  }
*/
handleSpriteClick(event) {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const clickY = event.clientY - rect.top;

    // Half of the sprite width and height (adjust these values to your actual sprite size)
    const spriteHalfWidth = this.spriteWidth / 2;  // example: 50 if width is 100
    const spriteHalfHeight = this.spriteHeight / 2; // example: 50 if height is 100

    // Calculate the top-left of the selection box, centering the click point
    const selectionX = clickX - spriteHalfWidth;
    const selectionY = clickY - spriteHalfHeight;

    // Adjust the marker position accordingly (optional offset if your marker is 10x10 px)
    this.selectionMarkerX = clickX - 5;
    this.selectionMarkerY = clickY - 5;

    // Now calculate the background position, scaling if necessary
    const scaleX = this.imageNaturalWidth / this.imageRenderedWidth;
    const scaleY = this.imageNaturalHeight / this.imageRenderedHeight;

    // The position should be the negative of selectionX and selectionY scaled, because
    // background position moves inversely to selection
    this.spritePosX = -Math.round(selectionX * scaleX);
    this.spritePosY = -Math.round(selectionY * scaleY);

    // Optional: clamp to avoid going outside the image boundaries (if needed)
    if (this.spritePosX > 0) this.spritePosX = 0;
    if (this.spritePosY > 0) this.spritePosY = 0;
}



  get selectionMarkerStyle() {
    return `
      top: ${this.selectionMarkerY}px;
      left: ${this.selectionMarkerX}px;
    `;
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

 handleexit(event) {
this.selectedImage= null;
event.querySelector('right-panel').classList.style.display = 'none';
event.querySelector('left-panel').className = 'left-panel full-width';

  }



get sizesOfSelectedImage(){
  if (!this.selectedImage || this.isSpriteImage) {
    return [];
  }
    const { name } = this.selectedImage;
    const baseName = name
  .replace(/\.[^/.]+$/, '')        // Remove file extension
  .replace(/_(small|medium|large)$/i, ''); // Remove size suffix if present

    const extension = name.split('.').pop();
    
    const sizeMap = [
      { label: 'small', class: 'small' },
      { label: 'medium', class: 'medium' },
      { label: 'large', class: 'large' }
    ];
     const variants = [];
for (const sizeData of sizeMap) {
  
       const variantName = `${baseName}_${sizeData.label}.${extension}`;
        //const variantImage = this.iconImages.find(img => img.name === variantName);
       const variantImage = this.iconImages.find(img => {
    const lastDotIndexImg = img.name.lastIndexOf('.');
    const lastDotIndexVariant = variantName.lastIndexOf('.');

    if (lastDotIndexImg === -1 || lastDotIndexVariant === -1) return false;

    const imgBase = img.name.substring(0, lastDotIndexImg);
    const imgExt = img.name.substring(lastDotIndexImg + 1);

    const variantBase = variantName.substring(0, lastDotIndexVariant);
    const variantExt = variantName.substring(lastDotIndexVariant + 1);

    return (
        imgBase === variantBase &&
        imgExt.toLowerCase() === variantExt.toLowerCase()
    );
});

//added above
  
if (variantImage) {
            variants.push({
                id: `${this.selectedImage.id}-${sizeData.label}`,
               // name: variantName,
               name:  variantImage.name,
                url: variantImage.url,
                cssClass: `preview-image ${sizeData.class}`,
                size: sizeData.label
            });
        }
    }

    return variants;

  }

}