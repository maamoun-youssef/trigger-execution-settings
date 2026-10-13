import { api, LightningElement } from 'lwc';
import Documents_Center from '@salesforce/resourceUrl/DocumentsCenter';

export default class DocumentsCenterSection extends LightningElement {
    @api recordId;
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
            let themeName = event.currentTarget.dataset.themeName;
            let gridKey = this.settings.developerName + '-' + themeName;
            const eventDetail = {
                gridKey
            };
            const newEvent = new CustomEvent(this.themeClickEvent, { 
                detail: eventDetail,
                bubbles: true, // Allow the event to propagate up the DOM tree
                composed: true // Allow the event to cross shadow DOM boundaries
            });
            console.log('newEvent: ' + JSON.stringify(newEvent))
            this.dispatchEvent(newEvent);
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