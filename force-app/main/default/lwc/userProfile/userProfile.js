import { LightningElement, track } from 'lwc';
import Toast from 'lightning/toast';
import getInitialData from '@salesforce/apex/UserProfileCtrl.getInitialData';
import updateUserData from '@salesforce/apex/UserProfileCtrl.updateUserData';
import uploadProfilePhoto from '@salesforce/apex/UserProfileCtrl.uploadProfilePhoto';
import deleteProfilePhoto from '@salesforce/apex/UserProfileCtrl.deleteProfilePhoto';
import USER_ID from '@salesforce/user/Id';
import basePath from "@salesforce/community/basePath";
import LBL_UserAccount_Title from '@salesforce/label/c.LBL_UserAccount_Title';
import LBL_UserAccount_Subtitle from '@salesforce/label/c.LBL_UserAccount_Subtitle';
import LBL_UserAccount_UpdateButton from '@salesforce/label/c.LBL_UserAccount_UpdateButton';
import LBL_UserAccount_UpdateSuccess from '@salesforce/label/c.LBL_UserAccount_UpdateSuccess';
import LBL_UserAccount_FieldFullName from '@salesforce/label/c.LBL_UserAccount_FieldFullName';
import LBL_Connect_CODEmailChangeConfirmation from '@salesforce/label/c.LBL_Connect_CODEmailChangeConfirmation';
import LBL_Connect_UPUpdateInformation from '@salesforce/label/c.LBL_Connect_UPUpdateInformation';
import LBL_Connect_UPDeletePhoto from '@salesforce/label/c.LBL_Connect_UPDeletePhoto';
import LBL_Connect_UPUploadPhoto from '@salesforce/label/c.LBL_Connect_UPUploadPhoto';
import LBL_Connect_UPPhotoDeletedOnSave from '@salesforce/label/c.LBL_Connect_UPPhotoDeletedOnSave';
import LBL_Connect_UPImageSizeError from '@salesforce/label/c.LBL_Connect_UPImageSizeError';
import LBL_Connect_UPPhotoExtensionError from '@salesforce/label/c.LBL_Connect_UPPhotoExtensionError';
import LBL_Connect_UPLanguageChangeLogout from '@salesforce/label/c.LBL_Connect_UPLanguageChangeLogout';
import LBL_Save from "@salesforce/label/c.LBL_Save";
import LBL_Cancel from "@salesforce/label/c.LBL_Cancel";
import LBL_Logout from "@salesforce/label/c.LBL_Logout";
import LBL_Error from "@salesforce/label/c.LBL_Error";
import LBL_Success from "@salesforce/label/c.LBL_Success";
import LBL_Info from "@salesforce/label/c.LBL_Info";
import userProfile from "@salesforce/resourceUrl/userProfile";
 
export default class UserProfile extends LightningElement {
    userId = USER_ID;
    @track loading = true;
    @track userData = null;
    @track isEmailDifferent = false;
    @track fieldsMap = {};
    @track userFieldsArray = [];
    @track isEditMode = false;
    @track editedData = {};
    @track labels = {};
    @track newPhotoFile = null;
    @track previewPhotoUrl = null;
    @track photoToDelete = false;
    @track showPhotoMenu = false;
    @track originalPhotoUrl = null;
    @track showLanguageLogoutModal = false;
    @track originalLanguage = null;
    @track communityUrl = '';
    @track photoChanged = false;
    @track hasCustomPhoto = false;

    icons = {
        language: `${userProfile}/userProfile/Language.png`,
        locale: `${userProfile}/userProfile/Locale.png`,
        name: `${userProfile}/userProfile/Name.png`,
        phone: `${userProfile}/userProfile/Phone.png`,
        profile: `${userProfile}/userProfile/Profile.png`,
        edit: `${userProfile}/userProfile/Edit.png`,
        role: `${userProfile}/userProfile/Role.png`,
        email: `${userProfile}/userProfile/Email.png`,
        defaultProfile: '/sfsites/c/profilephoto/005/F'
    };


    DISPLAY_FIELDS_ORDER = [
        'FirstName',
        'LastName',
        'Title',
        'Phone',
        'Email',
        'LanguageLocaleKey',
        'LocaleSidKey'
    ];

    label = {
        LBL_UserAccount_Title,
        LBL_UserAccount_Subtitle,
        LBL_UserAccount_UpdateButton,
        LBL_UserAccount_UpdateSuccess,
        LBL_UserAccount_FieldFullName,
        LBL_Connect_CODEmailChangeConfirmation,
        LBL_Connect_UPUpdateInformation,
        LBL_Connect_UPDeletePhoto,
        LBL_Connect_UPUploadPhoto,
        LBL_Connect_UPPhotoDeletedOnSave,
        LBL_Connect_UPImageSizeError,
        LBL_Connect_UPPhotoExtensionError,
        LBL_Connect_UPLanguageChangeLogout,
        LBL_Save,
        LBL_Cancel,
        LBL_Logout,
        LBL_Error,
        LBL_Success,
        LBL_Info
    };

    connectedCallback() {
        this.loadUserData();
        this.loadCommunityUrl();
    }

    loadUserData() {
        this.loading = true;
        getInitialData({
            userId: this.userId
        }).then(result => {
                const data = JSON.parse(result);
                this.userData = data.userData;
                const userEmail = this.userData?.Email;
                const contactEmail = this.userData?.Contact?.Email;
                this.contactInfo = contactEmail;
                this.isEmailDifferent = userEmail && contactEmail && userEmail.toLowerCase() !== contactEmail.toLowerCase();
                this.fieldsMap = data.userFields;
            this.originalLanguage = this.userData.LanguageLocaleKey;
            this.hasCustomPhoto = data.hasCustomPhoto || false;
                this.setLabels();
                this.buildFieldsArray();
                console.log('User data loaded:', JSON.stringify(this.userData));
                console.log('Fields array:', this.userFieldsArray);
                console.log('contactInfo:', this.contactInfo);
                this.loading = false;
        }).catch(error => {
                console.error('Error loading user data:', error);
                this.showNotification('Error', this.getErrorMessage(error), 'error');
                this.loading = false;
            });
    }

    loadCommunityUrl() {
        getCommunityUrl().then(url => {
            this.communityUrl = url;
        }).catch(error => {
            console.error('Error loading community URL:', error);
        });
    }

    setLabels() {
        this.labels.LBL_FirstName = this.fieldsMap['FirstName']?.label || 'FirstName';
        this.labels.LBL_LastName = this.fieldsMap['LastName']?.label || 'LastName';
        this.labels.LBL_Title = this.fieldsMap['Title']?.label || 'Title';
        this.labels.LBL_Phone = this.fieldsMap['Phone']?.label || 'Phone';
        this.labels.LBL_Email = this.fieldsMap['Email']?.label || 'Email';
        this.labels.LBL_LanguageLocaleKey = this.fieldsMap['LanguageLocaleKey']?.label || 'Language';
        this.labels.LBL_LocaleSidKey = this.fieldsMap['LocaleSidKey']?.label || 'Locale';
    }

    buildFieldsArray() {
        this.userFieldsArray = [];
        let index = 0;
        this.DISPLAY_FIELDS_ORDER.forEach(fieldApiName => {
            const fieldMetadata = this.fieldsMap[fieldApiName];
            if (fieldMetadata) {
                let fieldValue ;
                if (fieldApiName === 'Email') {
                    fieldValue = this.userData?.Contact?.Email;
                } else {
                    fieldValue = this.userData[fieldApiName];
                }
                let picklistValues = fieldMetadata.picklistValues;
                if (fieldApiName === 'LanguageLocaleKey') {
                    picklistValues = picklistValues.filter(opt => opt.value === 'en_US' || opt.value === 'fr');
                } if (fieldApiName === 'LocaleSidKey') {
                    picklistValues = picklistValues.filter(opt => opt.value === 'en_US' || opt.value === 'fr_FR');
                }
                const displayValue = picklistValues
                    ? this.getPicklistLabel(fieldApiName, fieldValue)
                    : fieldValue;
                if (fieldValue || fieldMetadata.updateable) {
                    this.userFieldsArray.push({
                        apiName: fieldApiName,
                        label: fieldMetadata.label,
                        value: fieldValue || '',
                        displayValue: displayValue || '',
                        type: fieldMetadata.type,
                        updateable: fieldMetadata.updateable,
                        required: fieldMetadata.required,
                        picklistValues: picklistValues,
                        iconClass: index % 2 === 0 ? 'icon-container' : 'icon-container',
                        isName: fieldApiName === 'FirstName' || fieldApiName === 'LastName',
                        isTitle: fieldApiName === 'Title',
                        isPhone: fieldApiName === 'Phone',
                        isEmail: fieldApiName === 'Email',
                        isLanguage: fieldApiName === 'LanguageLocaleKey',
                        isLocale: fieldApiName === 'LocaleSidKey',
                        showNotVerified: fieldApiName === 'Email' && this.isEmailDifferent
                    });
                    index++;
                }
            }
        });
    }
    get userFullName() {
        const first = this.userData?.FirstName || '';
        const last = this.userData?.LastName || '';
        return `${first} ${last}`.trim() || 'N/A';
    }

    getPicklistLabel(fieldApiName, value) {
        const fieldMetadata = this.fieldsMap[fieldApiName];
        if (fieldMetadata && fieldMetadata.picklistValues) {
            const option = fieldMetadata.picklistValues.find(opt => opt.value === value);
            return option ? option.label : value;
        }
        return value;
    }

    get userTitle() {
        return this.userData?.Title || 'N/A';
    }

    get userPhotoUrl() {
        return this.userData?.FullPhotoUrl || '';
    }

    get displayPhotoUrl() {
        if (this.previewPhotoUrl) {
            return this.previewPhotoUrl;
        }
        if (this.userPhotoUrl) {
            return this.userPhotoUrl;
        }
        return this.icons.defaultProfile;
    }

    get filteredUserFieldsArray() {
        return this.userFieldsArray.filter(
            f => f.apiName !== 'FirstName' && f.apiName !== 'LastName'
        );
    }
    get userFieldsArrayWithIcons() {
        return this.userFieldsArray
            .filter(f => f.apiName !== 'FirstName' && f.apiName !== 'LastName')
            .map(f => {
                return {
                    ...f,
                    isEmail: f.apiName === 'Email',
                    isPhone: f.apiName === 'Phone',
                    isName: f.apiName === 'FirstName' || f.apiName === 'LastName',
                    isTitle: f.apiName === 'Title',
                    isLanguage: f.apiName === 'LanguageLocaleKey',
                    isLocale: f.apiName === 'LocaleSidKey',
                    iconClass: 'icon-container'
                };
            });
    }


    handleEdit() {
        this.editedData = { ...this.userData };
        this.originalPhotoUrl = this.userData.FullPhotoUrl;
        this.originalLanguage = this.userData.LanguageLocaleKey;
        this.isEditMode = true;
        this.showPhotoMenu = false;
    }

    handleCancel() {
        this.editedData = {};
        this.isEditMode = false;
        this.newPhotoFile = null;
        this.previewPhotoUrl = null;
        this.photoToDelete = false;
        this.showPhotoMenu = false;
        this.photoChanged = false;
        if (this.originalPhotoUrl !== null) {
            this.userData.FullPhotoUrl = this.originalPhotoUrl;
        }
        this.originalPhotoUrl = null;
        this.originalLanguage = this.userData.LanguageLocaleKey;
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value;
        this.editedData[fieldName] = value;
        console.log('Field changed:', fieldName, value);
    }

    handlePhotoChange(event) {
        const file = event.target.files[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) {
                this.showNotification(this.label.LBL_Error, this.label.LBL_Connect_UPImageSizeError, 'error');
                return;
            }
            const allowedExtensions = ['jpg', 'jpeg', 'png'];
            const allowedMimeTypes = ['image/jpeg', 'image/png'];
            const extension = file.name.split('.').pop().toLowerCase();
            const mimeType = file.type;
            if (
                !allowedExtensions.includes(extension) ||
                !allowedMimeTypes.includes(mimeType)
            ) {
                this.showNotification(
                    this.label.LBL_Error,
                    this.label.LBL_Connect_UPPhotoExtensionError,
                    'error'
                );
                event.target.value = null;
                return;
            }

            this.newPhotoFile = file;
            this.photoChanged = true;
            const reader = new FileReader();
            reader.onload = (e) => {
                this.previewPhotoUrl = e.target.result;
            };
            reader.readAsDataURL(file);
            this.showPhotoMenu = false;
        }
    }

    async handleSave() {
        this.loading = true;
        const languageChanged = this.originalLanguage !== this.editedData.LanguageLocaleKey;

        try {
            if (this.photoToDelete && !this.newPhotoFile) {
                const deleteResult = await deleteProfilePhoto({ userId: this.userId });
                const deleteResponse = JSON.parse(deleteResult);
                if (deleteResponse.success) {
                    this.userData.FullPhotoUrl = null;
                } else {
                    throw new Error(deleteResponse.errorMessage);
                }
            }
            if (this.newPhotoFile) {
                await this.uploadPhoto();
            }
        const userToUpdate = {
            Id: this.userId,
            ...this.editedData
        };

            const result = await updateUserData({ userDataJSON: JSON.stringify(userToUpdate) });
                const response = JSON.parse(result);

                if (response.errorMessage === 'SUCCESS') {
                this.showNotification(this.label.LBL_Success, this.label.LBL_UserAccount_UpdateSuccess, 'success');
                    this.userData = response.updatedUser;
                this.hasCustomPhoto = true;
                    const userEmail = this.userData?.Email;
                    const contactEmail = this.userData?.Contact?.Email;
                    this.contactInfo = contactEmail;
                    this.isEmailDifferent = userEmail && contactEmail && userEmail.toLowerCase() !== contactEmail.toLowerCase();
                    if (this.isEmailDifferent) {
                        this.showNotification('Info', this.label.LBL_Connect_CODEmailChangeConfirmation, 'info');
                    }
                    this.buildFieldsArray();
                    this.isEditMode = false;
                    this.editedData = {};
                this.newPhotoFile = null;
                this.previewPhotoUrl = null;
                if (this.photoChanged) {
                    window.location.reload();
                    return;
                }
                if (languageChanged) {
                    this.showLanguageLogoutModal = true;
                }
                } else {
                    this.showNotification('Error', response.errorMessage, 'error');
                }
        } catch (error) {
                console.error('Error updating user data:', error);
                this.showNotification('Error', this.getErrorMessage(error), 'error');
        } finally {
                this.loading = false;
        }
    }

    get logoutLink() {
        const sitePrefix = basePath.replace("/", "");
        return `/${sitePrefix}/secur/logout.jsp`;
    }

    async uploadPhoto() {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = async () => {
                try {
                    const base64 = reader.result.split(',')[1];
                    const result = await uploadProfilePhoto({
                        userId: this.userId,
                        base64Data: base64,
                        fileName: this.newPhotoFile.name
                    });
                    const response = JSON.parse(result);
                    if (response.success) {
                        this.userData.FullPhotoUrl = response.photoUrl;
                        resolve();
                    } else {
                        reject(new Error(response.errorMessage));
                    }
                } catch (error) {
                    reject(error);
                }
            };
            reader.onerror = () => reject(new Error('Error reading file'));
            reader.readAsDataURL(this.newPhotoFile);
        });
    }

    handleDeletePhoto() {
        this.photoToDelete = true;
        this.photoChanged = true;
        this.previewPhotoUrl = null;
        this.newPhotoFile = null;
        this.userData.FullPhotoUrl = null;
        this.showPhotoMenu = false;
        this.showNotification(this.label.LBL_Info, this.label.LBL_Connect_UPPhotoDeletedOnSave, 'info');
    }

    togglePhotoMenu() {
        this.showPhotoMenu = !this.showPhotoMenu;
    }

    getErrorMessage(error) {
        if (error.body) {
            if (error.body.message) {
                return error.body.message;
            } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                return error.body.pageErrors[0].message;
            }
        }
        return error.message || 'Unknown error occurred';
    }

    showNotification(title, message, variant) {
        Toast.show({
            label: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
    }
}