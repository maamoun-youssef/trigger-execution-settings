import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import loadData from '@salesforce/apex/TradeCollabsController.loadData';
import Documents_Center from '@salesforce/resourceUrl/DocumentsCenter';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
import headerImageTradeCollabs from "@salesforce/resourceUrl/headerImageTradeCollabs";
import ConnectHeaderForCollabs from "@salesforce/resourceUrl/ConnectHeaderForCollabs";

// OBJECT API NAMES
import NegoScope__c from "@salesforce/schema/NegoScope__c";
import Supplier__c from "@salesforce/schema/Supplier__c";


export default class TradeCollabs extends LightningElement {
    @api recordId;
    @track sectionWrappers = [];
    @track headerImageTradeCollabs = headerImageTradeCollabs;
    @track ConnectHeaderForCollabs = ConnectHeaderForCollabs;

    staticUrl = {
        defaultimageStyle: connect_defaults + '/modules_icons/Documents_Center.png',
        section: {
            'Tariff': Documents_Center + '/DocumentsCenter/PICTOS/1.DocumentsCenterSectionIcon-NegoPreparationDocuments.png',
        },
        theme: {
            'Sell-In Statement List': Documents_Center + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-Templates.png',
        }
    }

    /** ENV FLAGS */
    @track isLoading = true;
    isPortalUser = false;

    /* MODAL FLAGS */
    @track showScrollToTopButton = false;

    /** LABELS*/
    labels = {};

    /** IMAGES */
    // images = {
    //     headerImg: Documents_Center + '/DocumentsCenter/HEADER.png'
    // }

    /** STYLES */
    @track modalContainerStyle = '';
    @track modalContentStyle = '';
    /** CONST */
    scrollOffset = 150;
    scrollBehavior = {
        smooth: 'smooth'
    }
    toastEventMode = {
        dismissable: 'dismissable',
        sticky: 'sticky'
    }
    toastEventVariant = {
        error: 'error',
        success: 'success'
    }

    /**LIFE CYCLE */
    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        window.addEventListener('scroll', this.handleScroll);
        // this.template.addEventListener('resize', this.setPageHeight);
    }

    renderedCallback() {
        // this.setPageHeight()
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this.handleScroll);
    }

    handleScroll = () => {
        if (window.scrollY > 200) {
            this.showScrollToTopButton = true;
        } else {
            this.showScrollToTopButton = false;
        }
    };

    scrollToTop() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        try {
            if (pageRef) {
                this.recordId = pageRef.state.c__recordId != null ? pageRef.state.c__recordId : this.recordId;
                console.log('this.recordId: ' + this.recordId)
                this.init();
            }
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }

    init() {
        try {
            this.loadData();
        } catch (error) {
            this.handleError(error, 'init');
        }
    }

    loadData() {
        try {
            console.log('loading data')
            this.isLoading = true;
            loadData({ }).then((result) => {
                let parsedResult = JSON.parse(result);
                this.labels = { ...this.labels, ...parsedResult.fieldsLabel };
                console.log('parsedResult: ' + JSON.stringify(parsedResult));
                this.afterLoad(parsedResult);
                this.isLoading = false;
            }).catch(error => {
                this.handleError(error, 'loadData (apex)');
            });
        } catch (error) {
            this.handleError(error, 'loadData');
        }
    }

    afterLoad(parsedResult) {
        try {
            this.isPortalUser = parsedResult.isPortal;
            this.prefix = parsedResult.prefix;
            if (Array.isArray(parsedResult.sectionWrappers)) {
                parsedResult.sectionWrappers.sort((a, b) => {
                    return a.displayOrder - b.displayOrder;
                });
            }
            parsedResult.sectionWrappers.forEach(section => {
                // Handle section icon 
                if (!section.sectionIcon) {
                    if (Object.keys(this.staticUrl.section).includes(section.sectionTitle)) {
                        section.sectionIcon = this.staticUrl.section[section.sectionTitle];
                    } else {
                        section.sectionIcon = this.staticUrl.defaultimageStyle;
                    }
                }
                // Handle section themes
                section.themesSettings.forEach(theme => {
                    // Handle theme visibilty
                    theme.showTheme = this.isPortalUser ? theme.isPortalDisplayed : theme.isDisplayed;
                    // Handle theme icon
                    if (!theme.largeThemeImage) {
                        if (Object.keys(this.staticUrl.theme).includes(theme.theme)) {
                            theme.largeThemeImage = this.staticUrl.theme[theme.theme];
                        } else {
                            theme.largeThemeImage = this.staticUrl.defaultimageStyle;
                        }
                    }
                });
                // Handle section visibility
                section.showSection = section.themesSettings.some(theme => theme.showTheme);
            });

            this.sectionWrappers = parsedResult.sectionWrappers;

            console.log('this.sectionWrappers: ' + JSON.stringify(this.sectionWrappers))
            console.table(this.sectionWrappers);
        } catch (error) {
            this.handleError(error, 'afterLoad');
        }
    }


    /** HANDLERS */
    handleSectionBtnClick(event) {
        try {
            const sectionId = event.target.dataset.sectionId;
            const sections = this.template.querySelectorAll(`[data-section-target-id="${sectionId}"]`);
            if (sections.length > 0) {
                const sectionElement = sections[0];
                const rect = sectionElement.getBoundingClientRect();
                window.scrollTo({
                    top: rect.top + window.scrollY - this.scrollOffset,
                    behavior: this.scrollBehavior.smooth
                });
            }
        } catch (error) {
            this.handleError(error, 'handleSectionBtnClick');
        }
    }
    /** UTILS */
    showNotification(title, message, variant, mode) {
        try {
            let evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode ? mode : this.toastEventMode.dismissable
            });
            this.dispatchEvent(evt);
        } catch (error) {
            this.handleError(error, 'showNotification');
        }
    }

    handleError(error, location) {
        try {
            const errorMessage = error && typeof error === 'object'
                ? error?.body?.message || error?.message || JSON.stringify(error)
                : error;
            this.showNotification(this.labels.LBL_Error, errorMessage, this.toastEventVariant.error, this.toastEventMode.sticky);
            const logStyle = 'color: white; background-color: red; padding: 4px 8px; border-radius: 4px; font-weight: bold;';
            console.error('%cError: ' + location, logStyle, errorMessage);
        } catch (internalError) {
            console.error('Error in handleError: ' + internalError);
            console.error('Error in handleError: ' + JSON.stringify(internalError));
        }
    }

    // setPageHeight = () => {
    //     let header = this.template.querySelector('.header');
    //     let mainContainer = this.template.querySelector('.mainContainer');
    //     if (header != null && mainContainer != null) {
    //         let windowHeight = window.innerHeight -200;
    //         // let headerHeight = header.offsetHeight;
    //         let height = windowHeight;
    //         console.log("Window Height: ", windowHeight);
    //         // console.log("Header Height: ", headerHeight);
    //         console.log("Calculated Height for mainContainer: ", height);
    //         mainContainer.style.height = height + 'px';
    //         console.log("Applied height to mainContainer: ", mainContainer.style.height);
    //     }
    // };


}