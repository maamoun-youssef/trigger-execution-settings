import { LightningElement, track , api,wire} from 'lwc';
import iconResources from '@salesforce/resourceUrl/iconResources';
import JSZipLib from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOGOS from '@salesforce/resourceUrl/logos';
import getCMSImages from '@salesforce/apex/CMSController.getCMSImages';
import getAllLogos from '@salesforce/apex/BackblazeHelper.getAllLogos';


const counter = {
  imageCounter: 0,
};

//specified zip folders to load from 
const zipModules = {
    Icons: iconResources,
    Logos: LOGOS
};

export default class ResourcesScreen extends LightningElement {
  @track iconSearchTerm = '';
  @track iconImages = [];
  @track filteredIconImages = [];
  @track selectedImage = null;
  @track selectedImageName = '';
  @track selectedImageID='';
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
  @track imageNaturalHeight = 0;
  @track imageRenderedHeight = 0;
  @track selectionMarkerX = 0;
  @track selectionMarkerY = 0;
  jsZipLoaded = false;
  @track selectedVariantImage = null;
  @track imageSizeVariants = [];
  @track images = [];
  @track error;
  @track loading = true;
  @track iscms=false; 
  offset = 0;
  step = 140;

  
 connectedCallback() {
        window.addEventListener('resize', this.changeHeight);
        loadScript(this, JSZipLib)
            .then(() => {
                this.jsZipLoaded = true;
                this.loadImages();
            })
            .catch(error => console.error('JSZip load error:', error));
    }
          
    

  renderedCallback() {
    this.changeHeight();
    //if an image is selected find it's medium size and highlight it by defualt 
    if (this.selectedImage && this.selectedSize === 'medium') {
      const mediumImg = this.template.querySelector('img.medium');
      if (mediumImg && !mediumImg.classList.contains('selected-size')) {
        mediumImg.classList.add('selected-size');
      }
    }

    /*find the element of class .folder-container if exists call the
    checkOverflowSafe function to adjust UI*/
    
   const folderContainer = this.template.querySelector('.folder-container');
    if (folderContainer) {
        this.checkOverflowSafe();
    }
  }

  
// Recalculates the panel height using the current window height,
// subtracting a 170px offset to fit the layout.
  changeHeight = () => {
    const offset = 170;
    const height = window.innerHeight - offset;
    this.mainPanelHeight = `height: ${height}px;`;
  };




// Adapter that loads a ZIP file , extracts image files, builds metadata (folders, names, types..),
// converts each file to a Base64 data URL, and returns an array of image objects.
 async zipAdapter(zipUrl, zipName) {
        try {
            const response = await fetch(zipUrl);
            const blob = await response.blob();
            const zip = await window.JSZip.loadAsync(blob);
            const images = [];

            zip.forEach((relativePath, zipEntry) => {
                if (!zipEntry.dir && /\.(png|jpe?g|svg)$/i.test(zipEntry.name)) {
                    const fileName = zipEntry.name.split('/').pop();
                    const folderParts = zipEntry.name.split('/');
                    const mainFolder = folderParts.length > 1 ? folderParts[1] : 'root';
                    const folderPath = zipEntry.name.substring(0, zipEntry.name.lastIndexOf('/')) || 'root';
                    const baseName = fileName.replace(/\.[^/.]+$/, '').replace(/_(small|medium|large)$/i, '');

                    images.push(
                        zipEntry.async('base64').then(fileData => ({
                            id: counter.imageCounter++,
                            displayName: baseName,
                            name: fileName,
                            url: `data:image/${this.getFileType(fileName)};base64,${fileData}`,
                            isZip: true,
                            zipName,
                            zipFolder: folderPath,
                            mainFolder,
                            fileName,
                            cssClass: `image-item${fileName === this.selectedImageName ? ' selected' : ''}`
                           
                        }))
                    );
                }
            });

            return Promise.all(images);
        } catch (error) {
            console.error(`Error loading ZIP ${zipName}:`, error);
            return [];
        }
    }




// Cache for CDN (Backblaze) image results to avoid repeated fetches.
static bbCache = [];
  /*
  Fetches CDN images via Apex, converts them to standardized image objects
  (same format as ZIP adapter), caches the results, and returns the list.
   */
async cdnAdapterbb() {
    if (ResourcesScreen.bbCache.length) {
        return ResourcesScreen.bbCache;
    }
    try {
        const result = await getAllLogos();
        const mapped = result.map(img => {
            // Remove file extension and size suffix for display purposes
            const baseName = img.name
                .replace(/\.[^/.]+$/, '')        // Remove file extension
                .replace(/_(small|medium|large)$/i, ''); // Remove size suffix if present

            return {
                id: counter.imageCounter++,
                displayName: baseName, // use normalized name
                name: img.name,
                url: img.url,
                isZip: false,
                zipName: 'CDN',
                zipFolder: 'CDN',
                mainFolder: 'CDN',
                fileName: img.name,
                cssClass: `image-item${img.name === this.selectedImageName ? ' selected' : ''}`
            
            };
        });

        ResourcesScreen.bbCache = mapped; // cache it
        return mapped;
    } catch (error) {
        console.error('CDN Adapter Error:', error);
        return [];
    }
}

// Cache for CMS images to avoid repeated Apex calls.
static cmsCache = [];
 /*
  Fetches images from the CMS enhanced workspace via Apex, converts them into
  standardized image objects (like the ZIP and CDN adapters),
 caches the result, and returns the list of images.
 */
async cmsAdapter() {
    if (ResourcesScreen.cmsCache.length) {
 
        return ResourcesScreen.cmsCache;
    }
    try {
        const result = await getCMSImages();
        const mapped = result.map(img => ({
            id: counter.imageCounter++,
            displayName: img.title,
            name: img.urlName,
            url: img.imageUrl,
            isZip: false,
            zipName: 'CMS',
            zipFolder: 'CMS',
            mainFolder: 'CMS',
            fileName: `${img.urlName}.png`,
            cssClass: `image-item${img.urlName === this.selectedImageName ? ' selected' : ''}`
        
        }));
        ResourcesScreen.cmsCache = mapped; // cache it
         
        return mapped;
    } catch (error) {
        console.error('CMS Adapter Error:', error);
        return [];
    }
}


/*
 * Loads images from multiple sources (ZIP , CMS, CDN), combines them,
 * organizes them by main folder, and builds folder selection options for the UI.
 * The loaded images are stored in `iconImages`, and folder options are stored
 * in `iconFolderOptions`. Applies initial filters after loading.
 */
 async loadImages() {
        this.loadingData = true;
        const allImages = [];
        const folderSet = new Set();

        try {
            
            // Load ZIP images dynamically from zipModules map and collect main folders
            for (const [name, url] of Object.entries(zipModules)) {
                const images = await this.zipAdapter(url, name);
                images.forEach(img => folderSet.add(img.mainFolder));
                allImages.push(...images);
            }

            // Load CMS images and collect main folders (uses cached results)
             const cmsImages = await this.cmsAdapter();  
        cmsImages.forEach(img => folderSet.add(img.mainFolder));
        allImages.push(...cmsImages);


          
           // Load CDN images and collect main folders (uses cached results)
        const bbImages = await this.cdnAdapterbb();
bbImages.forEach(img => folderSet.add(img.mainFolder));
allImages.push(...bbImages);

           // Combine all images into `iconImages`
            this.iconImages = allImages;




           // Build folder menu options from collected folders
          const folders = Array.from(folderSet).sort((a, b) =>
    a.toLowerCase().localeCompare(b.toLowerCase())
);

            this.selectedIconFolder = 'ALL';
            this.iconFolderOptions = [
                { label: 'ALL', value: 'ALL', class: 'category-btn active' },
                ...folders.map(folder => ({
                    label: folder,
                    value: folder,
                    class: folder === this.selectedIconFolder ? 'category-btn active' : 'category-btn'
                }))
            ];
            

            this.applyIconFilters();
        } catch (err) {
            console.error('Error loading images:', err);
        } finally {
            this.loadingData = false;
        }
    } 






/*
 * Filters loaded images for display in the UI.
 * - Includes images that are medium-sized, sprites, or from CMS.
 * - Applies folder filter based on selected folder.
 * - Applies search filter based on the icon search term.
 * The result is stored in `filteredIconImages`.
 */

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

        // Always include CMS images regardless of size
        const isCMSImage = image.zipName === 'CMS';

        return (isMediumSize || isSprite || isCMSImage) && matchesSearch && matchesFolder;
    });
}





/*
 * Handles folder selection changes in the UI.
 * - Updates `selectedIconFolder` based on the clicked option.
 * - Re-applies image filters to reflect the selected folder.
 * - Updates folder option classes so the active folder button is highlighted.
 */
onIconFolderChange(event) {
    const value = event.detail?.value || event.currentTarget.dataset.value;
    this.selectedIconFolder = value;
    this.applyIconFilters();

    this.iconFolderOptions = this.iconFolderOptions.map(folder => ({
        ...folder,
        class: folder.value === this.selectedIconFolder ? 'category-btn active' : 'category-btn'
    }));
}



  getFileType(fileName) {
    const ext = fileName.split('.').pop().toLowerCase();
    return ext === 'svg' ? 'svg+xml' : ext;
  }


/*
 * Updates the search term based on user input in the search bar
 * and re-applies icon filters to update the displayed images.
 */
  onIconSearchChange(event) {
    this.iconSearchTerm = event?.target?.value?.toLowerCase();
    this.applyIconFilters();
  }

 /*
 * Returns the CSS class for the left panel.
 * - If an image is selected, the panel is half-width.
 * - If no image is selected, the panel is full-width.
 */
  get leftPanelClass() {
    return this.selectedImage ? 'left-panel half-width' : 'left-panel full-width';
  }





//assign the clicked image to selected and opens a right panel preparing its variant imgs 
 handleImageClick(event) {
    const imageName = event.currentTarget.querySelector('img').alt;
    const image = this.filteredIconImages.find((img) => img.name === imageName);

    // Check if the clicked image is already selected
    const isAlreadySelected = this.selectedImageName === imageName;
      
    // If already selected, deselect it
    if (isAlreadySelected) {
        
        event.currentTarget.classList.remove('selected');

        // and clears all related state
        this.selectedImage = null;
        this.selectedImageName = null;
  
        this.isFromZip = false;
        this.selectedSize = null;
        this.selectedVariantImage = null;

        this.iscms = false;
        this.imageSizeVariants = [];

      
        return; 
    }

    // Otherwise, mark the new image as selected 
    this.template.querySelectorAll('.selected').forEach((el) => el.classList.remove('selected'));
    event.currentTarget.classList.add('selected');
     //Update component state
    if (image) {
        this.selectedImage = image;
        
         this.selectedImageName = image.name;
      
        this.isFromZip = true;
        this.selectedSize = 'medium'; // Default to medium size

       

        //Prepare size variants and sets the default selected variant to 'medium'
        this.imageSizeVariants = this.sizesOfSelectedImage;
        const mediumVariant = this.imageSizeVariants.find(v => v.size === 'medium');
        this.selectedVariantImage = mediumVariant || null;

       //Sets `iscms` if the image comes from the CMS source
        this.iscms = image.zipName === 'CMS';
    }
}

 




 /*
 * Generates a string of <c-logo-renderer> markup for the selected image, which can be copied and used anywhere
 * Handles sprite images with size/position attributes; otherwise, just includes the image name.
 */

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
    
    return `&lt;c-logo-renderer image-name="${imageName}"&gt;&lt;/c-logo-renderer&gt;`;
  }

  




 /*
 * Generates a dynamic string for the selected image:
 * - HTML <div> for sprites with background-position and size
 * - IMAGE() formula string for normal images
 * Returns empty string if no image is selected.
 */

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



/*
 * Updates the selected size and variant image when a size option is clicked.
 * Updates CSS classes to highlight the selected size.
 */

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

// Copies the dynamic IMAGE() formula string to the clipboard,
//  converting HTML entities back to actual < and > characters.
  copyFormula() {
    this.copyToClipboard(this.dynamicFormula.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  }

// Copies the dynamic <c-logo-renderer> markup string to the clipboard,
//  converting HTML entities to actual < and > characters.
  copyRendererTag() {
    this.copyToClipboard(this.dynamicRendererTag.replace(/&lt;/g, '<').replace(/&gt;/g, '>'));
  }

// Returns true if the selected image comes from a 'sprites' folder,
//  indicating it should be treated as a sprite image.
  get isSpriteImage() {
    if (!this.selectedImage) return false;
    const folderName = this.selectedImage.zipFolder.toLowerCase().split('/').pop();
    return folderName === 'sprites';
  }

// Returns a CSS style string to correctly display the selected sprite image,
//  including size, background position
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


/*
 * Handles input changes for sprite properties (width, height, posX, posY).
 * - Updates the corresponding sprite property based on the input field name.
 * - Recalculates the selection marker coordinates to reflect the new sprite position,
 *   accounting for scaling between the rendered and natural image dimensions.
 * - Ensures the preview stays in sync with user input.
 */
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

/*
 * Captures the dimensions of the currently displayed image.
 *
 * - `imageRenderedWidth` / `imageRenderedHeight` store the size of the image as it appears on screen.
 * - `imageNaturalWidth` / `imageNaturalHeight` store the image's original, actual size.
 * - These values are used for scaling calculations, e.g., positioning sprite selection markers accurately.
 */
 captureImageDimensions(event) {
  this.imageRenderedWidth = event.target.clientWidth;
  this.imageRenderedHeight = event.target.clientHeight; 
  this.imageNaturalWidth = event.target.naturalWidth;
  this.imageNaturalHeight = event.target.naturalHeight;  
}



 //Handles user clicks on a sprite image to select a portion of it.
handleSpriteClick(event) {
    // Get the position of the click relative to the sprite container
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const clickY = event.clientY - rect.top;

    // Half of the sprite width/height to center the selection box on the click
    const spriteHalfWidth = this.spriteWidth / 2;  
    const spriteHalfHeight = this.spriteHeight / 2;

    // Calculate the top-left corner of the selection box
    const selectionX = clickX - spriteHalfWidth;
    const selectionY = clickY - spriteHalfHeight;

    // Update marker position for the preview (offset by 5px for marker alignment)
    this.selectionMarkerX = clickX - 5;
    this.selectionMarkerY = clickY - 5;

    // Scale factors between rendered and natural image dimensions
    const scaleX = this.imageNaturalWidth / this.imageRenderedWidth;
    const scaleY = this.imageNaturalHeight / this.imageRenderedHeight;

    // Set sprite background position (negative because background position moves inversely to selection)
    this.spritePosX = -Math.round(selectionX * scaleX);
    this.spritePosY = -Math.round(selectionY * scaleY);

    // Clamp to avoid moving background outside the image bounds
    if (this.spritePosX > 0) this.spritePosX = 0;
    if (this.spritePosY > 0) this.spritePosY = 0;
}




  get selectionMarkerStyle() {
    return `
      top: ${this.selectionMarkerY}px;
      left: ${this.selectionMarkerX}px;
    `;
  }


// Copies the provided text to the user's clipboard and shows a success toast.
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



  // Handles closing the right panel when the exit button is clicked.
 handleexit(event) {
// Clears the selected image.
this.selectedImage= null;
// Hides the right panel.
event.querySelector('right-panel').classList.style.display = 'none';
// Expands the left panel to full width.
event.querySelector('left-panel').className = 'left-panel full-width';
  }




  // Returns all size variants (small, medium, large) of the currently selected image
get sizesOfSelectedImage() {
    // Early return if no image is selected or the selected image is a sprite
    if (!this.selectedImage || this.isSpriteImage) {
        return [];
    }

    const { name } = this.selectedImage;

    // get the base name
    const baseName = name
        .replace(/\.[^/.]+$/, '')              // Remove file extension
        .replace(/_(small|medium|large)$/i, ''); // Remove size suffix if present

    const extension = name.split('.').pop(); // Extract the file extension (png, jpg, etc.)

    // Define the standard size variants
    const sizeMap = [
        { label: 'small', class: 'small' },
        { label: 'medium', class: 'medium' },
        { label: 'large', class: 'large' }
    ];

    const variants = [];

    // Iterate over each size and try to find a matching image in iconImages
    for (const sizeData of sizeMap) {
        const variantName = `${baseName}_${sizeData.label}.${extension}`; // Construct expected variant name

        // Find the image object that matches this size variant
        const variantImage = this.iconImages.find(img => {
            const lastDotIndexImg = img.name.lastIndexOf('.');
            const lastDotIndexVariant = variantName.lastIndexOf('.');

            if (lastDotIndexImg === -1 || lastDotIndexVariant === -1) return false;

            // Split image names into base and extension for comparison
            const imgBase = img.name.substring(0, lastDotIndexImg);
            const imgExt = img.name.substring(lastDotIndexImg + 1);

            const variantBase = variantName.substring(0, lastDotIndexVariant);
            const variantExt = variantName.substring(lastDotIndexVariant + 1);

            // Return true if base names match and extensions are equal (case-insensitive)
            return (
                imgBase === variantBase &&
                imgExt.toLowerCase() === variantExt.toLowerCase()
            );
        });

        // If a variant exists, add it to the variants array with relevant metadata
        if (variantImage) {
            variants.push({
                id: `${this.selectedImage.id}-${sizeData.label}`, // Unique ID per size variant
                name: variantImage.name,                          // Name of the variant image
                url: variantImage.url,                            // URL of the variant image
                cssClass: `logo-item ${sizeData.class}`,          // CSS class for styling by size
                size: sizeData.label                              // Size label (small, medium, large)
            });
        }
    }

    // Return the array of available size variants
    return variants;
}


 
/*
 * Groups filtered images by their main folder.
 *
 * - Iterates over `filteredIconImages`.
 * - Uses `mainFolder` as the grouping key, defaults to 'root' if not specified.
 * - Returns an array of objects, each containing:
 *     - `folderName`: the folder name
 *     - `images`: an array of images in that folder
 */
  get groupedFilteredImages() {
    const groups = {};
        // Sort by folder name alphabetically ignoring case
    const sortedImages = this.filteredIconImages.slice().sort((a, b) =>
        a.mainFolder.toLowerCase().localeCompare(b.mainFolder.toLowerCase())
    );



//     this.filteredIconImages.forEach(img => {
//         const folder = img.mainFolder || 'root';
//         if (!groups[folder]) groups[folder] = [];
//         groups[folder].push(img);
//     });
//     return Object.keys(groups).map(folderName => ({
//         folderName,
//         images: groups[folderName],
//     }));
// }


    sortedImages.forEach(img => {
        const folder = img.mainFolder || 'root';
        if (!groups[folder]) groups[folder] = [];
        groups[folder].push(img);
    });

    return Object.keys(groups).map(folderName => ({
        folderName,
        images: groups[folderName],
    }));
}


// handle > icon click to show more folders
handleMoreClick() {
  const container = this.template.querySelector('.folder-container');
  container.scrollLeft += this.step;

  
}



// handle < icon click to show previous folders
handlelessClick() {
  const container = this.template.querySelector('.folder-container');
  container.scrollLeft -= this.step;


}


//shows or hides the arrows based on the overflow of the folder container
checkOverflowSafe() {
    const container = this.template.querySelector('.folder-container');
    const moreBtn = this.template.querySelector('.more-btn');
    const lessBtn = this.template.querySelector('.less-btn');

    if (!container || !moreBtn || !lessBtn) {
        return;
    }

    const hasOverflow = container.scrollWidth > container.clientWidth;

    // Show both arrows if there's horizontal overflow
    if (hasOverflow) {
        moreBtn.style.display = 'block';
        lessBtn.style.display = 'block';
    } else {
        moreBtn.style.display = 'none';
        lessBtn.style.display = 'none';
    }


}



}