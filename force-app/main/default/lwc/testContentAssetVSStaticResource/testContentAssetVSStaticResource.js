import { LightningElement, track } from 'lwc';
import StaticLogos from "@salesforce/resourceUrl/StaticLogos";
import Sent_Icon from "@salesforce/resourceUrl/Sent_Icon";

export default class TestContentAssetVSStaticResource extends LightningElement {
    @track nestedAssetUrl = StaticLogos + '/StaticLogos/Copie_de_BBloc_Orange_HQ2png.png';
    @track Sent_IconURL = Sent_Icon;
}