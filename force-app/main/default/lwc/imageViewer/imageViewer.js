/**
* @author ULiT
* @date 13-11-2024
* @description NegoptimDisplayImage - Enhanced with auto-detection and base URL fix
*******************************************************************************************************************************************
*/
import { LightningElement, api } from 'lwc';
import getContentUrl from '@salesforce/apex/AssetLibraryImagesDataSource.getContentUrl';
export default class imageViewer extends LightningElement {
    @api width = '100';
    @api height = '100';
    @api resourceType = ''; // Empty = auto-detect, or 'StaticResource'/'ContentAsset'
    @api logo; // Image name (Static Resource name or ContentAsset name)
    @api alignment = 'center'; // 'left', 'center', 'right'
    isLwrSite = false;
    imageUrl;
    errorMessage;
    isLoading = true;
    triedStaticResource = false;

    connectedCallback() {
        try {
            import('@salesforce/community/Id').then(communityId => {
                this.isLwrSite = communityId ? true : false;
            }).catch(error => {
                this.isLwrSite = false;
            }).finally(() => {
                this.loadImage();
            });
        } catch (error) {
        } finally {
            this.loadImage();
        }
    }

    async loadImage() {
        if (!this.logo) {
            this.errorMessage = 'No image name provided';
            this.isLoading = false;
            return;
        }

        // If resourceType is explicitly specified, use it directly
        if (this.resourceType && this.resourceType.trim() !== '') {
            if (this.resourceType === 'StaticResource') {
                this.imageUrl = this.getStaticResourceUrl();
                this.isLoading = false;
            } else if (this.resourceType === 'ContentAsset') {
                try {
                    const contentAssetUrl = await getContentUrl({ assetName: this.logo });
                    this.imageUrl = contentAssetUrl;
                    this.isLoading = false;
                } catch (error) {
                    console.error('Error loading ContentAsset:', error);
                    this.errorMessage = `ContentAsset "${this.logo}" not found`;
                    this.isLoading = false;
                }
            }
        } else {
            // Auto-detect: try Static Resource first
            this.imageUrl = this.getStaticResourceUrl();
            this.triedStaticResource = true;
            this.isLoading = false;
        }
    }

    // Handle image load success
    handleImageLoad() {
        this.isLoading = false;
        this.errorMessage = null;
    }

    // Handle image load error -  ContentAsset fallback
    async handleImageError() {
        // Only try fallback if we're in auto-detect mode
        if (this.triedStaticResource && (!this.resourceType || this.resourceType.trim() === '')) {
            // if Static Resource failed, try ContentAsset
            this.isLoading = true;
            this.triedStaticResource = false;

            try {
                const contentAssetUrl = await getContentUrl({ assetName: this.logo });
                this.imageUrl = contentAssetUrl;
                this.isLoading = false;
            } catch (error) {
                console.error('Error loading image:', error);
                this.errorMessage = `Image "${this.logo}" not found as Static Resource or ContentAsset`;
                this.isLoading = false;
                this.imageUrl = null;
            }
        } else {
            // Resource type was specified but failed, or ContentAsset also failed
            this.errorMessage = `Image "${this.logo}" not found`;
            this.isLoading = false;
            this.imageUrl = null;
        }
    }

    getStaticResourceUrl() {
        return this.isLwrSite ? `/sfsites/c/resource/${this.logo}` : `/resource/${this.logo}`;
    }

    get containerClass() {
        return `image-container align-${this.alignment.toLowerCase()}`;
    }

    get imageStyle() {
        let units = [
            'px',
            '%',
            'em',
            'rem'
        ];
        // If no unit specified, default to px
        const widthValue = this.width && units.some(unit => this.width.includes(unit)) ? this.width : `${this.width}px`;
        const heightValue = this.height && units.some(unit => this.height.includes(unit)) ? this.height : `${this.height}px`;
        return `max-width: ${widthValue}; max-height: ${heightValue};`;
    }
}