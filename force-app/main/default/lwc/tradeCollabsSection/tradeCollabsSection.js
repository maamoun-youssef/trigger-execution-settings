import { api, LightningElement } from 'lwc';
import Documents_Center from '@salesforce/resourceUrl/DocumentsCenter';
import { NavigationMixin } from 'lightning/navigation';

export default class TradeCollabsSection extends NavigationMixin(LightningElement) {
    @api recordId;
    @api prefix;
    @api isPortal;
    @api settings = {};
    // Images
    images = {
        connectFilet: Documents_Center + '/DocumentsCenter/FILET.png'
    }
    // Styles
    themeTitleOverlayStyle = "";
    // Const
    themeClickEvent = 'themeclick';


    connectedCallback() {
        try {
            let sectionColor = this.settings.sectionColor;
            this.themeTitleOverlayStyle = sectionColor ? `background-color: ${this.hexToRgba(sectionColor, 0.8)};` : '';
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }

    handleMouseEnterTheme(event) {
        try {
            const themeTitleOverlay = event.currentTarget.querySelector('.theme-title-overlay');
            if (themeTitleOverlay) {
                themeTitleOverlay.style.backgroundColor = this.hexToRgba(this.settings.sectionColor, 1);
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }

    handleMouseLeaveTheme(event) {
        try {
            const themeTitleOverlay = event.currentTarget.querySelector('.theme-title-overlay');
            if (themeTitleOverlay) {
                themeTitleOverlay.style.backgroundColor = this.hexToRgba(this.settings.sectionColor, 0.8);
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }

    }

    handleThemeClick(event) {
        try {
            try {
                // Encode filters once
                console.log('this.settings.sectionTitle: ' + this.settings.sectionTitle)
                let activeTheme = event.currentTarget.dataset.theme;
                console.log('activeTheme: ' + activeTheme)
                const encodedSectionTitle = encodeURIComponent(btoa(this.settings.sectionTitle));
                const encodedActiveTheme = encodeURIComponent(btoa(activeTheme));
                // if (!this.isPortal) {
                // } else {
                //     window.open(`/NegoptimConnect/trade-collabs-theme?c__sectionTitle=${encodedSectionTitle}&c__activeTheme=${encodedActiveTheme}`);
                // }

                if (!this.isPortal) {
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__webPage',
                        attributes: {
                            url: `/lightning/n/${this.prefix}Trade_Collabs_Theme?c__sectionTitle=${encodedSectionTitle}&c__activeTheme=${encodedActiveTheme}`,
                        },
                    }).then(() => {
                        window.open(`/lightning/n/${this.prefix}Trade_Collabs_Theme?c__sectionTitle=${encodedSectionTitle}&c__activeTheme=${encodedActiveTheme}`);
                    });
                } else {
                    window.open(`/NegoptimConnect/trade-collabs-item?c__sectionTitle=${encodedSectionTitle}&c__activeTheme=${encodedActiveTheme}`);
                }
            } catch (e) {
                console.log('ERROR: ' + e);
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }

    hexToRgba(hex, opacity) {
        try {
            // Remove the `#` if present
            hex = hex.replace('#', '');
            // Handle shorthand hex format `#RGB`
            if (hex.length == 3) {
                hex = hex.split('').map(char => char + char).join('');
            }
            // Parse the R, G, and B values
            const r = parseInt(hex.substring(0, 2), 16);
            const g = parseInt(hex.substring(2, 4), 16);
            const b = parseInt(hex.substring(4, 6), 16);
            // Return the RGBA color
            return `rgba(${r}, ${g}, ${b}, ${opacity})`;
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }
}