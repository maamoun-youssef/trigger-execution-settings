import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadData from '@salesforce/apex/PageSettingsPluginController.loadData';
import initData from '@salesforce/apex/PageSettingsPluginController.initData';
// USER
import LBL_Error from "@salesforce/label/c.LBL_Error";
import ConnectLogo from "@salesforce/resourceUrl/ConnectLogo";
import ConnectSectionAvatar from "@salesforce/resourceUrl/ConnectSectionAvatar";
import ConnectThemeAvatar from "@salesforce/resourceUrl/ConnectThemeAvatar";
import ConnectHeaderAvatar from "@salesforce/resourceUrl/ConnectHeaderAvatar";
import LANG from '@salesforce/i18n/lang';

export default class PageSettingsPlugin extends LightningElement {
    @api selectedMenu;
    @api templateName;
    @api recordId;
    @track pageSettings = {};
    @track isLoading = true;
    @track isPortal = false;
    @track isModalOpen = false;
    @track WireVariables = {
        getPageReference: false
    }

    @track labels = {
        LBL_Error,
    }
    @track prefix = '';
    @track showScrollToTopButton = false;

    staticUrl = {
        ConnectSectionAvatar: ConnectSectionAvatar,
        ConnectThemeAvatar: ConnectThemeAvatar,
        ConnectHeaderAvatar: ConnectHeaderAvatar,
        ConnectLogo: ConnectLogo
    }
    flowInput = {
        IsLaunchedFromConnect: { name: 'IsLaunchedFromConnect', type: 'Boolean' },
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this.handleScroll);
    }

    connectedCallback() {
        window.addEventListener('scroll', this.handleScroll);
    }

    get sortedSections() {
        return this.pageSettings.sections?.sort((a, b) => a.order - b.order) || [];
    }

    get showSectionButtons() {
        return (this.sortedSections?.filter(section => section.isActive).length || 0) > 1;
    }

    @track headerImageUrl = '';
    @track useBackgroundDiv = false;

    updateHeaderStyleBasedOnImageSize(imageUrl) {
        const img = new Image();

        img.onload = () => {
            const isSmall = img.naturalWidth < 50;
            this.useBackgroundDiv = isSmall;

            if (isSmall) {
                requestAnimationFrame(() => {
                    const bgDiv = this.template.querySelector('.background-style');
                    if (bgDiv) {
                        bgDiv.style.backgroundImage = `url("${imageUrl}")`;
                    }
                });
            } else {
                this.headerImageUrl = imageUrl;
            }
        };

        img.onerror = () => {
            this.headerImageUrl = this.staticUrl?.ConnectHeaderAvatar || '';
            this.useBackgroundDiv = false;
        };

        img.src = imageUrl;
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
                console.log('pageRef')
                console.log(JSON.stringify(pageRef))
                this.selectedMenu = pageRef.state.c__selectedMenu != null ? pageRef.state.c__selectedMenu : this.selectedMenu;
                this.templateName = pageRef.state.c__templateName != null ? pageRef.state.c__templateName : this.templateName;
                this.WireVariables.getPageReference = true;
                this.init();
            }
        } catch (error) {
            this.handleError(error, 'getPageReference');
        }
    }

    //LIFECYCLE
    init() {
        if (this.WireVariables.getPageReference) {
            this.initData();
        }
    }

    initData() {
        initData().then(result => {
            const data = JSON.parse(result);
            this.prefix = data.prefix;
            this.isPortal = data.currentSession.SessionType === 'ChatterNetworks';
            this.flowInputVariables = [
                {
                    name: this.flowInput?.IsLaunchedFromConnect?.name,
                    type: this.flowInput?.IsLaunchedFromConnect?.type,
                    value: this.isPortal
                },
            ];
            this.loadData();
        }).catch(error => {
            console.error('Error in initData:', error);
        });
    }

    loadData() {
        this.isLoading = true;
        try {
            loadData({ templateName: this.templateName, language: LANG }).then((result) => {
                this.pageSettings = JSON.parse(result);
                if (!this.selectedMenu) this.selectedMenu = this.pageSettings.name;
                this.validateImageUrl(this.pageSettings.headerBackground).then(value => {
                    if (!value) {
                        this.pageSettings.headerBackground = this.staticUrl.ConnectHeaderAvatar;
                    }
                    this.updateHeaderStyleBasedOnImageSize(this.pageSettings.headerBackground);
                })
                this.validateImageUrl(this.pageSettings.icon).then(value => {
                    if (!value) {
                        this.pageSettings.icon = this.staticUrl.ConnectLogo;
                    }
                })
                let sectionIndex = 0;
                this.pageSettings?.sections?.forEach(section => {
                    this.validateImageUrl(section.icon).then(value => {
                        if (!value) {
                            section.icon = this.staticUrl.ConnectSectionAvatar;
                        }
                    })
                    section.themes = this.pageSettings.themes.filter(theme => theme.sectionIndex == sectionIndex && theme.isActive && (this.isPortal ? theme.isPortalDisplay : theme.isInternalDisplay));
                    section.themes?.forEach(theme => {
                        this.validateImageUrl(theme.icon).then(value => {
                            if (!value) {
                                theme.icon = this.staticUrl.ConnectThemeAvatar;
                            }
                        })
                        theme.isURL = theme.redirectionType == 'URL';
                        theme.isGrid = theme.redirectionType == 'Grid';
                        theme.isLWC = theme.redirectionType == 'Page';
                        theme.isFlow = theme.redirectionType == 'Flow';
                        theme.overlayStyle = section.color ? `background-color: ${this.hexToRgba(section.color, 0.8)};` : '';
                    })
                    sectionIndex++;
                })
                this.isLoading = false;
            }).catch(error => {
                this.isLoading = false;
                console.error(error);
                this.showNotification(this.labels.LBL_Error, error?.body?.message || error?.message || error, 'error', 'sticky');
            });
        } catch (error) {
            this.isLoading = false;
            console.log('%c' + error.message ? error.message : error.body?.message);
            this.showNotification(this.labels.LBL_Error, error.message ? error.message : error.body?.message, 'error');
        }
    }

    validateImageUrl(url) {
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

    toggleModal() {
        this.isModalOpen = !this.isModalOpen;
    }
    handleExitFlow(event) {
        if (event.detail.status == 'FINISHED') {
            this.toggleModal();
        }
    }

    GoToSection(event) {
        try {
            const sectionIndex = event.target.dataset.sectionIndex;
            const sectionElement = this.template.querySelector(`[data-section-target-index="${sectionIndex}"]`);
            if (sectionElement) {
                const rect = sectionElement.getBoundingClientRect();
                const scrollOffset = 100;
                const scrollBehavior = 'smooth';
                window.scrollTo({
                    top: rect.top + window.scrollY - scrollOffset,
                    behavior: scrollBehavior
                });
            } else {
            }
        } catch (error) {
            this.showNotification(this.labels.LBL_Error, error.message || error.body?.message, 'error');
        }
    }

    handleThemeClick(event) {
        const sectionIndex = event.target.dataset.sectionIndex;
        const themeIndex = event.target.dataset.themeIndex;
        let theme = this.pageSettings.sections[sectionIndex].themes[themeIndex];
        if (theme.isURL) {
            window.open(theme.redirection, '_blank');
        } else {
            const templateName = encodeURIComponent(this.templateName);
            const componentNamespace = this.prefix ? this.prefix.replace('__', ':') : 'c:';
            if (this.isPortal) {
                const url = `/${this.prefix}NegoptimConnect/page-settings-plugin-theme-list?c__selectedSectionIndex=${sectionIndex}&c__selectedThemeIndex=${themeIndex}&c__templateName=${templateName}`;
                window.open(url, '_blank');
            } else {
                const url = `/apex/${this.prefix}NegoptimNavigator?` +
                    `c__componentName=${componentNamespace}pagesettingspluginthemeList` +
                    `&a__recordId=${this.recordId}&a__selectedSectionIndex=${sectionIndex}&a__selectedThemeIndex=${themeIndex}&a__templateName=${templateName}`;
                window.open(url, '_blank');
            }
        }
    }


    handleMouseEnterTheme(event) {
        try {
            const themeTitleOverlay = event.currentTarget.querySelector('.theme-title-overlay');
            if (themeTitleOverlay) {
                const sectionIndex = event.currentTarget.dataset.sectionIndex;
                const section = this.pageSettings.sections[sectionIndex];
                if (section && section.color) {
                    themeTitleOverlay.style.backgroundColor = this.hexToRgba(section.color, 1);
                }
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }

    handleMouseLeaveTheme(event) {
        try {
            const themeTitleOverlay = event.currentTarget.querySelector('.theme-title-overlay');
            if (themeTitleOverlay) {
                const sectionIndex = event.currentTarget.dataset.sectionIndex;
                const section = this.pageSettings.sections[sectionIndex];
                if (section && section.color) {
                    themeTitleOverlay.style.backgroundColor = this.hexToRgba(section.color, 0.8);
                }
            }
        } catch (error) {
            console.log('error: ' + JSON.stringify(error));
        }
    }

    //MISC
    showNotification(title, message, variant, mode) {
        let evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
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