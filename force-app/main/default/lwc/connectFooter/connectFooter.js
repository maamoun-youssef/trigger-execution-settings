import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import CustomCss from "@salesforce/resourceUrl/CustomCss";
import FooterLogo from "@salesforce/resourceUrl/FooterLogo";
import FooterHeartIcon from "@salesforce/resourceUrl/FooterHeartIcon";
import FooterLinkedInIcon from "@salesforce/resourceUrl/FooterLinkedInIcon";
import FooterHeartLink from "@salesforce/resourceUrl/FooterHeartLink";
import FooterSalesForceIcon from "@salesforce/resourceUrl/FooterSalesForceIcon";
import NegoImages from "@salesforce/resourceUrl/NegoV2Images";
import LBL_All_Right_Reserved from '@salesforce/label/c.LBL_All_Right_Reserved';
import LBL_My_Data from '@salesforce/label/c.LBL_My_Data';
import LBL_Useful_Links from '@salesforce/label/c.LBL_Useful_Links';
import LBL_Cookie_Policy from '@salesforce/label/c.LBL_Cookie_Policy';
import LBL_Confidentiality_Notice from '@salesforce/label/c.LBL_Confidentiality_Notice';
import LBL_Technicall_Prerequisites from '@salesforce/label/c.LBL_Technicall_Prerequisites';
import LBL_T_And_C from '@salesforce/label/c.LBL_T_And_C';
import LBL_Contacts from '@salesforce/label/c.LBL_Contacts';
import LBL_ULiT from '@salesforce/label/c.LBL_ULiT';
export default class ConnectFooter extends LightningElement {
    @track imageUrlFooter = `max-width:200px; height:50px; background-image: url('${FooterLogo}'); background-position: left center;`;
    @track imageUrlHeartIcon = `width:150px;height:150px;background-image: url('${FooterHeartIcon}');`;
    @track imageUrlLinkedLink = `max-width: 35px; height:40px; background-image: url('${FooterLinkedInIcon}'); background-position: left center`;
    @track imageUrlHeartLink = `max-width: 35px; height:40px; background-image: url('${FooterHeartLink}'); background-position: left center`;
    @track imageUrlSalesForceIcon = `max-width: 35px; height:40px; background-image: url('${FooterSalesForceIcon}'); background-position: left center`;
    @track CursorIcon = `cursor: url('${NegoImages + '/negov2images/Cursor.png'}'), auto`;

    @track urls = {
        URL_Cookie_Policy: "/NegoptimConnect/cookie-policy",
        URL_Confidentiality_Notice: "/NegoptimConnect/confidentiality-notice",
        URL_Technicall_Prerequisites: "https://help.salesforce.com/s/articleView?id=sf.getstart_browsers_sfx.htm&type=5",
        URL_T_And_C: "/NegoptimConnect/terms-and-conditions",
        URL_Ulit: "https://usersloveit.com/wp/",
        URL_LinkedIn: "https://www.linkedin.com/company/users-love-it",
        URL_Ulit_Team: "https://usersloveit.com/wp/lequipe/",
        URL_appexchange: "https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FMfLNUA1",
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, CustomCss)
        ]).then(() => {
            console.log('Files loaded');
        }).catch(error => {
            console.log(error.body.message);
        });

    }
    get currentYear() {
        return new Date().getFullYear();
    }

    get formattedCopyrightText() {
        let label = this.label.LBL_All_Right_Reserved;
        return this.formatString(label, [this.currentYear]);
    }
    formatString(string, args) {
        return string.replace(/{(\d+)}/g, (match, number) => {
            return typeof args[number] !== 'undefined' ? args[number] : match;
        });
    }

    @track label = {
        LBL_All_Right_Reserved: LBL_All_Right_Reserved,
        LBL_My_Data: LBL_My_Data,
        LBL_Useful_Links: LBL_Useful_Links,
        LBL_Cookie_Policy: LBL_Cookie_Policy,
        LBL_Confidentiality_Notice: LBL_Confidentiality_Notice,
        LBL_Technicall_Prerequisites: LBL_Technicall_Prerequisites,
        LBL_T_And_C: LBL_T_And_C,
        LBL_Contacts: LBL_Contacts,
        LBL_ULiT
    }
}