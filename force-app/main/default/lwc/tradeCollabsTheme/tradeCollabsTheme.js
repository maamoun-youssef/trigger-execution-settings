import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import Documents_Center from '@salesforce/resourceUrl/DocumentsCenter';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
// Apex
import loadSection from "@salesforce/apex/TradeCollabsController.loadSection";
// Custom labels
import LBL_Connect_DocumentsCenter_Menu from "@salesforce/label/c.LBL_Connect_DocumentsCenter_Menu";

export default class TradeCollabsTheme extends LightningElement {
    //BOOLEANS
    loadingData = false;
    //OBJECTS
    @track labels = {
        LBL_Connect_DocumentsCenter_Menu
    }
    @track API_NAMES = {
    }
    @track currentSectionSettings;
    @track headerClass;
    //STRINGS
    @track mainPanelHeight;
    @track activeTheme;
    @track recordId;
    @wire(CurrentPageReference)
    pageRef;

    staticUrl = {
        defaultimageStyle: connect_defaults + '/modules_icons/Documents_Center.png',
        section: {
            'Tariff': Documents_Center + '/DocumentsCenter/PICTOS/1.DocumentsCenterSectionIcon-NegoPreparationDocuments.png',
        },
        theme: {
            'Sell-In Statement List': Documents_Center + '/DocumentsCenter/VIGNETTES/1.DocumentsCenterTile-Templates.png',
        }
    }

    connectedCallback() {
        Promise.all([
            // loadStyle(this, negoptimColor),
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style')
        });
        window.addEventListener('resize', this.changeHeight);
        const tabStyle = document.createElement('style');
        tabStyle.innerText = '.slds-vertical-tabs__nav-item.slds-is-active{background :white; color: #2B4C44 !important; height: 60px; width: 230px; text-decoration:none !important;}';
        tabStyle.innerText += '.slds-vertical-tabs__nav-item{background : #2B4C44; height: 60px; width: 230px; right: 40px; } .slds-vertical-tabs {border-radius: 0px 0px 0px 5px; border: none} ';
        tabStyle.innerText += '.slds-vertical-tabs__left-icon { --slds-c-icon-color-foreground-default: white;}';
        tabStyle.innerText += '.slds-vertical-tabs__link { color: white !important; font-size: 14px; height: 60px; text-decoration: none !important;}';
        tabStyle.innerText += '.slds-vertical-tabs__nav-item.slds-is-active .slds-vertical-tabs__link { color: #2B4C44 !important;}';
        tabStyle.innerText += '.slds-vertical-tabs__link:hover { text-decoration: none !important; background-color: #2B4C44;}';
        tabStyle.innerText += '.slds-vertical-tabs__nav-item.slds-is-active .slds-vertical-tabs__link:hover {color: #2B4C44 !important; text-decoration:none !important;}';
        tabStyle.innerText += 'lightning-tab-bar { width: 230px; margin: 10px; background: #2B4C44; border-radius: 10px; padding-top: 10px; text-decoration:none !important; color: #2B4C44 !important; height: fit-content; padding-bottom: 10px;}';
        document.body.appendChild(tabStyle);
        const tabStyleHover = document.createElement('style');
        document.body.appendChild(tabStyleHover);
        this.loadData();
    }
    renderedCallback() {
        if (this.template.querySelector('.header')) {
            this.changeHeight();
        }
    }

    changeHeight = () => {
        let headerHeight = 0;
        if (this.template.querySelector('.header') != null) {
            headerHeight = this.template.querySelector('.header').getBoundingClientRect().height;
        }
        let mainPanelHeight = window.innerHeight - headerHeight - 130;
        this.mainPanelHeight = 'height:' + mainPanelHeight + 'px';
    };
    //LOAD DATA
    loadData() {
        this.loadingData = true;
        let sectionTitle;
        if (this.pageRef) {
            const { state } = this.pageRef;
            if (state.c__sectionTitle) {
                sectionTitle = decodeURIComponent(atob(state.c__sectionTitle));
                sectionTitle = sectionTitle != 'undefined' ? sectionTitle : '';
            }
            console.log('state.c__activeTheme: ' + state.c__activeTheme)
            if (state.c__activeTheme) {
                this.activeTheme = decodeURIComponent(atob(state.c__activeTheme));
                console.log('this.activeTheme: ' + this.activeTheme)
                this.activeTheme = this.activeTheme != 'undefined' ? this.activeTheme : '';
            }
        }
        console.log('recordId: ' + this.recordId)
        loadSection({sectionTitle: sectionTitle})
            .then(result => {
                console.log('result: ' + result)
                let parsedResult = JSON.parse(result);
                this.afterLoad(parsedResult);
            }).catch(error => {
                console.log('%c' + error.message, 'color : red');
                console.log('%c' + error.body?.message, 'color : red');
                this.loadingData = false;
            })
    }
    afterLoad(mainWrapper) {
        try {
            this.currentSectionSettings = mainWrapper.sectionWrapper;
            console.log('this.currentSectionSettings: ' + JSON.stringify(this.currentSectionSettings))
            this.labels.sectionLabel = this.currentSectionSettings.sectionLabel;
            this.labels.sectionSubTitle = this.currentSectionSettings.sectionSubTitle;
            this.headerClass = 'color: white !important; background-color: ' + this.currentSectionSettings.sectionColor;
            if (!this.currentSectionSettings.sectionIcon) {
                if (Object.keys(this.staticUrl.section).includes(this.currentSectionSettings.sectionTitle)) {
                    this.currentSectionSettings.sectionIcon = this.staticUrl.section[this.currentSectionSettings.sectionTitle];
                } else {
                    this.currentSectionSettings.sectionIcon = this.staticUrl.defaultimageStyle;
                }
            }
            // Handle section themes
            this.currentSectionSettings.themesSettings.forEach(theme=>{
                // fill grid key
                theme.gridKey = this.currentSectionSettings.developerName + '-' + theme.themeLabel;
                // Handle theme visibilty
                theme.showTheme = mainWrapper.isPortal? theme.isPortalDisplayed : theme.isDisplayed;
                // Handle theme icon
                if (!theme.smallThemeImage) {
                    if (Object.keys(this.staticUrl.theme).includes(theme.theme)) {
                        theme.smallThemeImage = this.staticUrl.theme[theme.theme];
                    } else {
                        theme.smallThemeImage = this.staticUrl.defaultimageStyle;
                    }
                }
            });
            this.loadingData = false;
            console.log('this.currentSectionSettings: ' + JSON.stringify(this.currentSectionSettings))
        } catch (error) {
            console.log(error);
        }
    }

    //NOTIFICATIONS
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    //NOTIFICATIONS
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
            duration: 3000
        });
        this.dispatchEvent(evt);
        setTimeout(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
                duration: 1
            }));
        }, 5000);
    }
}