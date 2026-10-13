import { api, LightningElement, track } from 'lwc';

const toastEvent = {
    variant : {
        error: 'error',
        success: 'success',
        warning: 'warning'
    },
    title : {
        error: 'Error',
        success: 'Success',
        warning: 'Warning'
    },
    eventIcon : {
        error: 'utility:error',
        success: 'utility:success',
        warning: 'utility:warning'
    },
    themeColor : {
        error: 'slds-theme--error',
        success: 'slds-theme--success',
        warning: 'slds-theme--warning'
    },
    mode :{
        dismissible: 'dismissible',
        pester: 'pester',
        sticky: 'sticky'
    },
    duration : {
        dismissible: 5000,
        pester: 5000,
        sticky: 0
    }
}

export default class ToastDispatcher extends LightningElement {
    @track toastContainer = [];
    currentId = 0;
    @api addNewToast(toast) {
        toast.id = this.currentId;
        toast.mode = toast.mode && toastEvent.mode[toast.mode] ? toast.mode : toastEvent.mode.sticky;
        toast.themeColor = toastEvent.themeColor[toast.variant] + ' slds-notify slds-notify_toast notify_toast';
        toast.eventIcon = toastEvent.eventIcon[toast.variant];
        toast.title = toastEvent.title[toast.variant];
        toast.manualDismiss = toast.mode !== toastEvent.mode.pester
        toast.duration = (toast.duration && Number.isInteger(toast.duration)) ? toast.duration : toastEvent.duration[toast.mode];
        this.toastContainer.push(toast);
        const div = this.template.querySelector(`[data-key="${toast.id}"]`);
        if (div) {
            div.classList.add('slds-fade-in-open');
        }
        if (toast.mode !== toastEvent.mode.sticky) {
            setTimeout(() => {
                this.toastContainer = this.toastContainer.filter(item => item.id !== toast.id);
            }, toast.duration);
        }
        this.currentId++;
    }

    closeToast(event) {
        const toastId = event.currentTarget.dataset.id;
        this.toastContainer = this.toastContainer.filter(item => item.id != toastId);
    }



    
}