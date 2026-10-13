import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import CustomCss from "@salesforce/resourceUrl/CustomCss";
import HeaderScreenIcon from "@salesforce/resourceUrl/HeaderScreenIcon";
import HeaderNotificationIcon from "@salesforce/resourceUrl/HeaderNotificationIcon";
import ProfilePic from "@salesforce/resourceUrl/ProfilePic";
import getCurrentUser from '@salesforce/apex/ConnectLayoutController.getCurrentUser';
import getCommunityUrl from '@salesforce/apex/ConnectLayoutController.getCommunityUrl';
import isGuest from "@salesforce/user/isGuest";
// import basePath from "@salesforce/community/basePath";
import Id from '@salesforce/user/Id';
import searchBar from '@salesforce/apex/ConnectLayoutController.searchBar';
import getPortalSettings from '@salesforce/apex/ConnectLayoutController.getPortalSettings';
import getContactsInfoList from '@salesforce/apex/ConnectLayoutController.getContactsInfoList';
import LBL_Logout from '@salesforce/label/c.LBL_Logout';
import LBL_View_Profile from '@salesforce/label/c.LBL_View_Profile';
import LBL_Notifications from '@salesforce/label/c.LBL_Notifications';
import LBL_Close_Dialog from '@salesforce/label/c.LBL_Close_Dialog';
import LBL_Mark_All_As_Read from '@salesforce/label/c.LBL_Mark_All_As_Read';
import LBL_No_Items_Found from '@salesforce/label/c.LBL_No_Items_Found';
import LBL_Connect_UserGuideTitle from '@salesforce/label/c.LBL_Connect_UserGuideTitle';
import LBL_Connect_UserGuideDownload from '@salesforce/label/c.LBL_Connect_UserGuideDownload';
import connect_defaults from "@salesforce/resourceUrl/connect_defaults";
import SelfOnboardingSteps__c from '@salesforce/schema/Contact.SelfOnboardingSteps__c';
import Cometd from 'c/cometd';

/**
 * @slot customSearch
*/

import getNotifications from '@salesforce/apex/ConnectLayoutController.getNotifications';
import setNotificationRead from '@salesforce/apex/ConnectLayoutController.setNotificationRead';

const decodeHtml = (html) => {
    const txt = document.createElement('textarea');
    txt.innerHTML = html;
    let val = txt.value;
    txt.remove();
    return val;
}

const _setNotificationRead = (self, notificationId) => {
    setNotificationRead({ notificationId: notificationId }).then(data => {
        _getNotifications(self);
    });
}

const _markAllAsRead = (self) => {
    const notificationIds = self.notificationsConfig.notificationList
        .filter(notification => !notification.read)
        .map(notification => notification.id);
    notificationIds.forEach(notifId => {
        _setNotificationRead(self, notifId);
    });
};
const _getNotifications = (self) => {
    getNotifications().then(data => {
        const parsedData = JSON.parse(data || '{}');
        const notifications = parsedData.notifications || [];
        let notificationList = notifications.map(it => {
            it.messageTitle = decodeHtml(it.messageTitle);
            it.messageBody = decodeHtml(it.messageBody);
            return it;
        });
        console.log(`🚀 ------------------------------------------------------------------------------------------------🚀`);
        console.log(`🚀 ~ :52 ~ _getNotifications ~ JSON.parse(data)?.notifications:`, JSON.parse(data)?.notifications);
        console.log(`🚀 ------------------------------------------------------------------------------------------------🚀`);
        let notificationsConfig = self.notificationsConfig;
        notificationsConfig.notificationList = notificationList || [];
        notificationsConfig.notificationList.forEach(notification => {
            notification.NotificationClass = notification.read ? 'slds-notification__body read-notification' : 'slds-notification__body negoptim-notfcolor';
        });
        notificationsConfig.unreadNotificationCount = notificationList?.reduce((prev, cur) => prev + (cur.read ? 0 : 1), 0) || 0;
        notificationsConfig.hasUnreadNotifications = notificationsConfig.unreadNotificationCount != 0;
        self.notificationsConfig = { ...self.notificationsConfig };
    });
};
const NOTIFICATION_CHANNEL = '/s/notifications/notification';
const DYNAMIC_IMPORTS = {
    imports: [
        {
            _import: '@salesforce/community/basePath',
            _var: 'basePath',
        }
    ],
    basePath: '',
};
export default class ConnectHeader extends NavigationMixin(LightningElement) {
    @track HeaderScreenIcon = `max-width: 55px; height:33px; background-image: url('${HeaderScreenIcon}'); background-position: left center;`
    @track HeaderNotificationIcon = `max-width: 40px; height:33px; background-image: url('${HeaderNotificationIcon}'); background-position: left center;`
    @track ProfilePic = `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
    @track showProfileUser = false;
    @track ShowSearchResult = false;
    @track showHeaderScreenIcon = false;
    @track ShowHeaderNotificationIcon = false;
    @track searchTerm = '';
    @track PortalFavIcon;
    @track comunityLogInUrl;
    @track guideDocUrl;
    @api disableCustomSearch;
    @api noItemsFounds;
    searchableObjects = [];
    //labels
    labels = {
        LBL_View_Profile,
        LBL_Mark_All_As_Read,
        LBL_Notifications,
        LBL_Close_Dialog,
        LBL_Logout,
        LBL_No_Items_Found,
        LBL_Connect_UserGuideTitle,
        LBL_Connect_UserGuideDownload
    }
    cometdManager;
    // api names
    CONTACT_API_NAMES = {
        SelfOnboardingSteps__c: SelfOnboardingSteps__c.fieldApiName,
    }

    staticUrl = {
        PortalFavIcon: connect_defaults + '/connect_logo/connect_default_logo.png',
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
    renderedCallback() {
        let showDiv = this.template.querySelector('.shadow');
        if (showDiv) {
            showDiv.style.height = this.template?.querySelector('.fixed-header')?.clientHeight + 'px';
        }
    }

    profilePictureUrl;
    @wire(getCurrentUser)
    wiredUser({ error, data }) {
        if (data) {
            // this.username = data.Name;
            this.profilePictureUrl = data.FullPhotoUrl;
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    handleUserProfileClick() {
        this.showProfileUser = !this.showProfileUser;
    }

    @track isUserGuest = false;
    @track allSearches = [];
    @track notificationsConfig = {
        isOpen: false,
        hasUnreadNotifications: false,
        unreadNotificationCount: 0,
        notificationList: [],
        open(event) {
            this.notificationsConfig.isOpen = true;
        },
        openNotification(event) {
            let notification = event.target.closest('[data-notification-id]');
            if (notification) {
                let notificationId = notification.dataset.notificationId;
                let target = notification.dataset.target;
                let targetPageRefJSON = notification.dataset.targetPageRef;
                if (notificationId) {
                    _setNotificationRead(this, notificationId);
                    notification.classList.add('read-notification');
                }
                if (targetPageRefJSON) {
                    try {
                        targetPageRefJSON = this.decodeHtmlEntities(targetPageRefJSON);
                        let targetPageRef = JSON.parse(targetPageRefJSON);
                        this[NavigationMixin.Navigate](targetPageRef);
                        this.notificationsConfig.isOpen = false;
                    } catch (error) {
                        console.log('ERROR: ' + error?.body?.message || error?.message || error);
                    }
                } else if (target) {
                    let baseUrl = this.comunityLogInUrl;
                    let targetUrl = `${baseUrl}${target}`;
                    window.open(targetUrl, '_blank');
                    this.notificationsConfig.isOpen = false;
                }
            }
        },
        markAllAsRead(event) {
            _markAllAsRead(this);
        },
        toggleNotificationPanel(event) {
            this.closeYourNotificationTimeout = setTimeout(() => {
                this.notificationsConfig.isOpen = false;
            }, 0);
        }
    };

    connectedCallback() {
        DYNAMIC_IMPORTS.imports.forEach(imp => {
            try {
                DYNAMIC_IMPORTS[imp._var] = import(imp._import);
            } catch (ex) {
                console.log('Exception >>', ex);
            }
        });

        let self = this;
        Promise.all([
            loadStyle(this, CustomCss)
        ]).then(() => {
        }).catch(error => {
            console.log(error.body.message);
        });
        this.isUserGuest = isGuest;
        getCommunityUrl().then(res => {
            this.comunityLogInUrl = res;
        }).catch(error => {
            console.error('Error getting url:', error);
        });
        _getNotifications(this);
        getPortalSettings().then(result => {
            if (result) {
                result = JSON.parse(result);
                this.guideDocUrl = result?.guideDocUrl || '';
                this.validateImageUrl(result.connectLogoIcon).then(value => {
                    this.searchableObjects = result.searchableObjects;
                    if (!value) {
                        this.PortalFavIcon = `max-width:150px; height:50px; background-image: url('${this.staticUrl.PortalFavIcon}'); background-position: left center;`;
                    } else {
                        this.PortalFavIcon = `max-width:150px; height:50px; background-image: url('${result.connectLogoIcon}'); background-position: left center;`;
                    }
                })
                this.showHeaderScreenIcon = true;
            } else {
                console.error('Video URL is empty.');
            }
            if (this.enableSelfOnBoarding && (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] !== 'Completed')) {
                this.showHeaderScreenIcon = true;
            }
        }).catch(error => {
            console.error('Error fetching video:', error);
        });
        this.cometdManager = new Cometd(this);
        this.cometdManager.initialize().then(() => {
            self.cometdManager.subscribe(NOTIFICATION_CHANNEL, () => {
                _getNotifications(self);
            });
        });
    }


    disconnectedCallback() {
        if (this.cometdManager) {
            this.cometdManager.unsubscribe(NOTIFICATION_CHANNEL);
        }
    }

    get logoutLink() {
        const sitePrefix = DYNAMIC_IMPORTS.basePath.replace("/", "");
        return `/${sitePrefix}/secur/logout.jsp`;
    }
    get profileLink() {
        const sitePrefix = DYNAMIC_IMPORTS.basePath.replace("/", "");
        return `/${sitePrefix}/userProfile/${Id}`;
    }

    handleSearch(event) {
        this.ShowSearchResult = false;
        this.noItemsFounds = false;
        this.searchTerm = event.target.value;
        if (this.searchTerm != null && this.searchTerm.length > 0) {
            searchBar({ searchTerm: this.searchTerm, searchableObjects: this.searchableObjects }).then(result => {
                this.ShowSearchResult = true;
                if (result.length == 0) {
                    this.noItemsFounds = true;
                    return;
                }
                this.allSearches = JSON.parse(JSON.stringify(result)).map(item => {
                    item.displayText = item.CallObject || item.Name;
                    item.recordUrl = `/s/detail/${item.Id}`;
                    return item;
                });
            }).catch(error => {
                console.error('Error fetching Search values:', error);
            });
        }
    }

    closeYourProfile() {
        this.closeYourProfileTimeout = setTimeout(() => {
            this.showProfileUser = false;
        }, 1000);

    }
    cancelCloseYourProfile() {
        clearTimeout(this.closeYourProfileTimeout);
    }

    closeYourSearch() {
        this.closeYourSearchTimeout = setTimeout(() => {
            this.ShowSearchResult = false;
        }, 1000);

    }
    cancelCloseYourSearch() {
        clearTimeout(this.closeYourSearchTimeout);
    }

    decodeHtmlEntities(encodedString) {
        const parser = new DOMParser();
        const decoded = parser.parseFromString(encodedString, 'text/html').documentElement.textContent;
        return decoded;
    }

    navigateToHomePage() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    closeYourNotification() {
        this.closeYourNotificationTimeout = setTimeout(() => {
            this.notificationsConfig.isOpen = false;
        }, 2000);

    }
    cancelCloseYourNotification() {
        clearTimeout(this.closeYourNotificationTimeout);
    }

    enableSelfOnBoarding = false;
    videoUrl;
    @track ContactsInfo = {};

    @wire(getContactsInfoList)
    wiredContactsInfoList({ error, data }) {
        if (data) {
            this.ContactsInfo = data;
            if (this.enableSelfOnBoarding && (this?.ContactsInfo?.Contact && this.ContactsInfo.Contact[this.CONTACT_API_NAMES.SelfOnboardingSteps__c] !== 'Completed')) {
                this.showHeaderScreenIcon = true;
            }
        } else if (error) {
            console.error(error);
        }
    }

    @track isGuidePopoverOpen = false;
    guidePopoverTimeout;

    toggleGuidePopover() {
        this.isGuidePopoverOpen = !this.isGuidePopoverOpen;
    }

    closeGuidePopover() {
        this.guidePopoverTimeout = setTimeout(() => {
            this.isGuidePopoverOpen = false;
        }, 1000);
    }

    cancelCloseGuidePopover() {
        clearTimeout(this.guidePopoverTimeout);
    }

}