import { LightningElement, api, track, wire } from 'lwc';

export default class TestParams extends LightningElement {
    @api testParam;
    @api TestParam2;
    @api PDSGridSettingsTemplate1;
    @api RegularPDSDGridSettingsTemplate;
    @api PromoPDSDGridSettingsTemplate;
    @api OtherPDSDGridSettingsTemplate;
    connectedCallback(){
        console.log('this.testParam >>>> ' + this.testParam);
    }
    renderedCallback(){
        console.log('REnder >> this.testParam >>>> ' + this.testParam);
        console.log('REnder >> this.testParam >>>> ' + this.TestParam2);
        console.log('this.PDSGridSettingsTemplate1 >>>> ' + this.PDSGridSettingsTemplate1)
        console.log('this.RegularPDSDGridSettingsTemplate >>>> ' + this.RegularPDSDGridSettingsTemplate)
        console.log('this.PromoPDSDGridSettingsTemplate >>>> ' + this.PromoPDSDGridSettingsTemplate)
        console.log('this.OtherPDSDGridSettingsTemplate >>>> ' + this.OtherPDSDGridSettingsTemplate)
    }

}