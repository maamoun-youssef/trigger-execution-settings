import { LightningElement, api, track } from 'lwc';
//ICONS
import activeProtalIcon from "@salesforce/resourceUrl/activeProtalIcon";
import inactiveProtalIcon from "@salesforce/resourceUrl/inactiveProtalIcon";
import resetPassIcon from "@salesforce/resourceUrl/resetPassIcon";
import emptyIcon from "@salesforce/resourceUrl/emptyIcon";
import emailIcon from "@salesforce/resourceUrl/emailIcon";
import caseIcon from "@salesforce/resourceUrl/caseIcon";
import telephoneIcon from "@salesforce/resourceUrl/telephoneIcon";
import previewIcon from "@salesforce/resourceUrl/previewIcon";
import textMessageIcon from "@salesforce/resourceUrl/textMessageIcon";
import lockIcon from "@salesforce/resourceUrl/lockIcon";
import unlockIcon from "@salesforce/resourceUrl/unlockIcon";
import infoIcon from "@salesforce/resourceUrl/infoIcon";
import individualIcon from "@salesforce/resourceUrl/individualIcon";
import mailboxIcon from "@salesforce/resourceUrl/mailboxIcon";
import faxIcon from "@salesforce/resourceUrl/faxIcon";
import GlobalLocationFunctionsIcons from "@salesforce/resourceUrl/GlobalLocationFunctionsIcons";

export default class GlobalLocationSticker extends LightningElement {
    @api sticker;
    @api editMode;
    @api selectMode;
    @api index;
    @api isChecked;
    @api isDisabled;
    @track imageUrl;

    icons = {
        activeProtalIcon,
        inactiveProtalIcon,
        resetPassIcon,
        infoIcon,
        emptyIcon,
        telephoneIcon,
        caseIcon,
        lockIcon,
        unlockIcon,
        previewIcon,
        textMessageIcon,
        emailIcon,
        mailboxIcon,
        individualIcon,
        faxIcon,
        glAdministrativeIcon: GlobalLocationFunctionsIcons + '/GlobalLocationFunctionsIcons/Administrative.png',
        glGenericIcon: GlobalLocationFunctionsIcons + '/GlobalLocationFunctionsIcons/Default.png',
        glDeliverToIcon: GlobalLocationFunctionsIcons + '/GlobalLocationFunctionsIcons/Delivery.png',
        glInvoiceToIcon: GlobalLocationFunctionsIcons + '/GlobalLocationFunctionsIcons/Invoice.png'
    }

    connectedCallback() {
        this.editMode = this.editMode === 'true';
        this.selectMode = this.selectMode === 'true';
        if (this.sticker) {
            let imageUrlProfile = this.icons.glGenericIcon;
            this.imageUrl = "background-image: url(" + imageUrlProfile + ");";
        }
    }

    handleSelectGL(event) {
        try {
            const checkGLEvent = new CustomEvent('checkgl', {
                detail: {
                    value: event.target.dataset.id
                }
            });
            //Dispatch Event
            this.dispatchEvent(checkGLEvent);
        } catch(err) {
            console.error(err);
        }
    }

    handleEditSticker(event) {
        try {
            let stickerId = event.target.dataset.stickerid;
            if (stickerId) {
                const editGLEvent = new CustomEvent('editgl',{
                    detail: {
                        value: stickerId
                    }
                });
                //Dispatch Event
                this.dispatchEvent(editGLEvent);
            }
        } catch(err) {
            console.error(err);
        }
    }

    switchStickerStatus(event) {
        try {
            let stickerId = event.target.dataset.stickerid;
            let currentstatus = event.target.dataset.currentstatus;
            const isConfirmed = window.confirm('Are you sure you want to switch the status?');
            // If the user clicks "OK", proceed with the action
            if (isConfirmed) {
                const editGLEvent = new CustomEvent('switchstatus',{
                    detail: {
                        stickerid: stickerId,
                        index: this.index,
                        currentstatus: currentstatus
                    }
                });
                //Dispatch Event
                this.dispatchEvent(editGLEvent);
            }
        } catch(err) {
            console.error(err);
        }
    }
}