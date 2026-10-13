import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import CustomCss from "@salesforce/resourceUrl/CustomCss";
import NegoImages from "@salesforce/resourceUrl/NegoV2Images";
import NegoLogoImages from "@salesforce/resourceUrl/NegoLogoImages";
import VideoExample from "@salesforce/resourceUrl/VideoExample";
import getContactsInfoList from '@salesforce/apex/ConnectLayoutController.getContactsInfoList';
import isPageSettingActive from '@salesforce/apex/ConnectLayoutController.isPageSettingActive';
import getCustomLabel from '@salesforce/apex/NegoptimLabels.getCustomLabel';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
import initData from "@salesforce/apex/ConnectLayoutController.initData";
import ConnectPlayAnimation from "@salesforce/resourceUrl/ConnectPlayAnimation";
import ConnectMenuAvatar from "@salesforce/resourceUrl/ConnectMenuAvatar";
//LABELS
import LBL_Self_Onboarding_Video from "@salesforce/label/c.LBL_Self_Onboarding_Video";
//fields
import SelfOnboardingSteps__c from '@salesforce/schema/Contact.SelfOnboardingSteps__c';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import FILEDIRECTORY_OBJECT from '@salesforce/schema/FileDirectory__c';
//Subtype__c field from FileDirectory__c object
import SubType__c from '@salesforce/schema/FileDirectory__c.SubType__c';

import LANG from '@salesforce/i18n/lang';

const validateImageUrl = (url) => {
    return new Promise((resolve) => {
        const image = document.createElement('img');
        image.style.display = 'none';

        image.onload = () => {
            document.body.removeChild(image);
            resolve(true);
        };

        image.onerror = () => {
            document.body.removeChild(image);
            resolve(false);
        };

        image.src = url;
        document.body.appendChild(image);
    });
}
export default class ConnectBody extends NavigationMixin(LightningElement) {
    @track imageUrlNegoArc = `background-image:url('${NegoImages + '/negov2images/NegoAxe.png'}')`;
    @track imageUrlBibliothequeIcon = `background-image:url('${NegoImages + '/negov2images/BibliothequeIcon.png'}')`;
    @track imageDeclarationsIcon = `background-image:url('${NegoImages + '/negov2images/DeclarationsIcon.png'}')`;
    @track imageDeclarationsIcon2 = `background-image:url('${NegoImages + '/negov2images/DeclarationsIcon.png'}')`
    @track imageAppelsIcon = `background-image:url('${NegoImages + '/negov2images/AppelsIcon.png'}')`;
    @track imageMarketingIcon = `background-image:url('${NegoImages + '/negov2images/MarketingIcon.png'}')`;
    @track imageInfosIcon = `background-image:url('${NegoImages + '/negov2images/InfosIcon.png'}')`;
    @track imageProductsIcon = `background-image:url('${NegoImages + '/negov2images/ProductsIcon.png'}')`;
    @track imageTarifsIcon = `background-image:url('${NegoImages + '/negov2images/TarifsIcon.png'}')`;
    @track LogoCircle = `background-image: url('${NegoLogoImages + '/negologoimages/LogoCircle.png'}')`;
    @track LogoC = `background-image: url('${NegoLogoImages + '/negologoimages/LogoC.png'}');`;
    @track LogoPlay = `background-image: url('${NegoLogoImages + '/negologoimages/LogoPlay.png'}');position: absolute;top: 50%;left: 55%;translate: -50% -50% 0px;`;
    @track LogoOnnet = `transition: .5s ease all;background-image: url('${NegoLogoImages + '/negologoimages/LogoNego.png'}');top:6%;right:-55%`;
    @track LogoCBlack = `transition: opacity 1.5s ease, transform 0.3s ease;background-image: url('${NegoLogoImages + '/negologoimages/LogoCDark.png'}');right:-30%;opacity:0;`;
    @track ContactsInfo = {};
    @track VideoExample = VideoExample;
    @track ShowVideo = false;
    @api recordId;
    labels = {
        LBL_Self_Onboarding_Video,
    }
    // api names
    CONTACT_API_NAMES = {
        SelfOnboardingSteps__c: SelfOnboardingSteps__c.fieldApiName,
    }

    @track videoUrl;
    enableSelfOnBoarding = false;
    vid;
    @track action1 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action2 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action3 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action4 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action5 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action6 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action7 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    @track action8 = {
        name: '',
        style: '',
        disabled: false,
        isDisplayed: true,
    };
    get actionSectionClass() {
        let self = this;
        return `main-container menu-item-${[1, 2, 3, 4, 5, 6, 7, 8].filter(it => self[`action${it}`]?.isDisplayed).length}`;
    }
    staticUrl = {
        modules_icons: {
            0: connect_defaults + '/modules_icons/Documents_Center.png',
            1: connect_defaults + '/modules_icons/Trade_Collabs.png',
            2: connect_defaults + '/modules_icons/Marketing_Collabs.png',
            3: connect_defaults + '/modules_icons/Accounting_Collabs.png',
            4: connect_defaults + '/modules_icons/RFX.png',
            5: connect_defaults + '/modules_icons/Admin_Center.png',
        },
        ConnectPlayAnimation: ConnectPlayAnimation,
        ConnectMenuAvatar: ConnectMenuAvatar,
    }
    extractLabel(data) {
        // Define the regular expression to match the pattern and capture the data after "SLabel."
        const regex = /\{\!\$Label\.(.*?)\}/;

        // Apply the regex to the input string and extract the desired part
        const match = data.match(regex);

        // Check if there's a match and return the captured group
        return match ? match[1] : null;
    }
    negoscopePicklistValues;
    @wire(getObjectInfo, { objectApiName: FILEDIRECTORY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SubType__c })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.negoscopePicklistValues = data.values;
            console.log('>>>>Picklist values fetched:', this.negoscopePicklistValues);
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }
    connectedCallback() {
        let self = this;
        console.log('Language is: ' + LANG);
        this.language = LANG;

        initData().then(result => {
            const data = JSON.parse(result);
            this.prefix = data.prefix;
            this.isPortal = data.currentSession.SessionType == 'ChatterNetworks';
            if (result) {
                result = JSON.parse(result)?.connectSettings;
                if (result.enableSelfOnboarding) {
                    self.videoUrl = result.onboardingVideoUrl || this.staticUrl.ConnectPlayAnimation;
                    self.enableSelfOnBoarding = result.enableSelfOnboarding;
                }

                if (result.modulesConfiguration) {
                    const allModules = result.modulesConfiguration;
                    const settingsDeveloperNames = allModules
                        .filter(module => module.redirectionType === 'Settings' && module.redirection)
                        .map(module => module.redirection);

                    isPageSettingActive({ developerNames: settingsDeveloperNames }).then(activeSettingsMap => {
                        allModules.filter(module => {
                            const isURL = module.redirectionType === 'URL';
                            const isSettings = module.redirectionType === 'Settings' && module.redirection;
                            const isActiveSetting = isURL || (isSettings && activeSettingsMap[module.redirection]);
                            if (!isActiveSetting) {
                                module.isActive = false;
                            }
                            return module.isActive;
                        });
                        allModules.forEach((module, index) => {
                            // self[`action${index + 1}`].name = module.Name;
                            const extractedLabel = this.extractLabel(module.name);
                            const action = self[`action${index + 1}`];
                            action.class = `ov ${index < 3 ? 'ra' : 'la'} menu-circles menu-c0${index + 1} ${module.isActive ? '' : 'menu-circles-disabled'}`;
                            action.classmobile = `g_nm menu-circles-mobile menu-img-mobile ${module.isActive ? '' : 'menu-circles-mobile-disabled'}`;
                            action.redirection = module.redirection;
                            action.isURL = module.redirectionType === 'URL';
                            action.isSettings = module.redirectionType === 'Settings';
                            action.isDisplayed = index < 6 || module.isActive;
                            if (extractedLabel != null) {
                                // Call Apex method dynamically with extracted custom label
                                getCustomLabel({
                                    labelName: extractedLabel,
                                    hardcodedLabel: 'Invalid Data',
                                    language: LANG
                                }).then((res) => {
                                    // Set the action name to the response from the Apex method
                                    action.name = res;
                                }).catch((err) => {
                                    // Handle any errors, set a fallback action name
                                    action.name = err;
                                });
                            } else {
                                // If no label is extracted, fallback to module.Name
                                action.name = module.name;
                            }
                            action.url = module.url;
                            validateImageUrl(module.iconUrl).then(value => {
                                if (!value) {
                                    module.iconUrl = this.staticUrl.modules_icons[index] || this.staticUrl.ConnectMenuAvatar;
                                }
                                module.iconStyle = `background-image:url('${module.iconUrl}'); aspect-ratio: 1/1; width: 100%; background-size: cover;`;

                                action.style = ` ${module.iconStyle}; aspect-ratio: 1/1; background-size: cover; height: 40px; width: 40px;`;
                            })
                            action.disabled = !module.isActive;
                        });
                    }).catch(error => {
                        console.error('Error retrieving active settings map:', error);
                    });
                }
            } else {
                self.videoUrl = undefined;
                self.enableSelfOnBoarding = false;
                console.error('Video URL is empty.');
            }
        }).catch(error => {
            console.error('Error fetching video:', error);
        });
        Promise.all([
            loadStyle(this, CustomCss)
        ]).then(() => {
            // console.log('Files loaded');
        }).catch(error => {
            // console.log(error.body.message);
        });

    }
    renderedCallback() {
        if (!this.enableSelfOnBoarding || (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] == 'Completed')) {
            this.template?.querySelectorAll('.logo-class:not(.no-hover)')?.forEach(item => item.classList.add('no-hover'));
        }
    }

    playVideo(event) {
        if (this.enableSelfOnBoarding && (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] !== 'Completed')) {
            this.ShowVideo = true;
            setTimeout(() => {
                this.vid = this.template.querySelector('video');
                this.vid?.play();
            }, 20);
        }
    }
    handleMenu(event) {
        let activeMenu = this.template.querySelectorAll('.active');
        if (activeMenu.length != 0) activeMenu[0].classList.remove('active');
        event.target.parentElement.getElementsByClassName('menu-check')[0].classList.add('active')
    }
    navigateToDetailsPage(event) {
        const actionName = event.currentTarget.dataset.action;
        const action = this[actionName];
        if (!action.disabled) {
            if (action.isURL) {
                window.open(action.redirection);
            } else {
                const selectedMenu = encodeURIComponent(action.name);
                const templateName = encodeURIComponent(action.redirection);
                const componentNamespace = this.prefix ? this.prefix.replace('__', ':') : 'c:';
                if (this.isPortal) {
                    const customUrl = `/NegoptimConnect/page-settings-plugin?c__selectedMenu=${selectedMenu}&c__templateName=${templateName}`;
                    window.open(customUrl, '_blank');
                } else {
                    const customUrl = `/apex/${this.prefix}NegoptimNavigator?c__componentName=${componentNamespace}pagesettingsplugin&a__selectedMenu=${selectedMenu}&a__templateName=${templateName}`;
                    window.open(customUrl, '_blank');
                }
            }
        }
    }

    handleMouseOver(event) {
        if (!this.enableSelfOnBoarding || (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] == 'Completed')) {
            this.template?.querySelectorAll('.logo-class:not(.no-hover)')?.forEach(item => item.classList.add('no-hover'));
        }
        console.log(this?.ContactsInfo)
        if (this.enableSelfOnBoarding && (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] !== 'Completed')) {
            console.log('2')
            this.template.querySelectorAll('div:not(.no-hover) div.nego-logo, div:not(.no-hover) div.nego-logo-m').forEach(item => item.style.left = '-90%');
            this.template.querySelectorAll('div:not(.no-hover) div.connect-logo, div:not(.no-hover) div.connect-logo-m').forEach(item => item.style.right = '-115%');
            setTimeout(() => {
                this.template.querySelectorAll('div:not(.no-hover) div.c-letter').forEach(item => item.style.opacity = 0);
                this.template.querySelectorAll('div:not(.no-hover) div.play-icon, div:not(.no-hover) div.cletter-logo, div:not(.no-hover) div.cletter-logo-m').forEach(item => item.style.opacity = 1);
                console.log('3')
            }, 100);
        }
    }
    handleMouseOut(event) {
        if (!this.enableSelfOnBoarding || (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] == 'Completed')) {
            this.template?.querySelectorAll('.logo-class:not(.no-hover)')?.forEach(item => item.classList.add('no-hover'));
        }
        if (this.enableSelfOnBoarding && (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] !== 'Completed')) {
            this.template.querySelectorAll('div:not(.no-hover) div.nego-logo, div:not(.no-hover) div.nego-logo-m').forEach(item => item.style.left = '-55%');
            this.template.querySelectorAll('div:not(.no-hover) div.connect-logo, div:not(.no-hover) div.connect-logo-m').forEach(item => item.style.right = '-55%');
            setTimeout(() => {
                this.template.querySelectorAll('div:not(.no-hover) div.c-letter').forEach(item => item.style.opacity = 1);
                this.template.querySelectorAll('div:not(.no-hover) div.play-icon, div:not(.no-hover) div.cletter-logo, div:not(.no-hover) div.cletter-logo-m').forEach(item => item.style.opacity = 0);
            }, 100);
        }
    }

    @wire(getContactsInfoList)
    wiredContactsInfoList({ error, data }) {
        if (data) {
            this.ContactsInfo = data;
        } else if (error) {
            console.error(error);
        }
    }

    handleCloseDetails() {
        this.ShowVideo = false;
    }
}