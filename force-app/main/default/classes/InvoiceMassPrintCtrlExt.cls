public class InvoiceMassPrintCtrlExt {
    public nTemplate.MultipleRecordsPrintController ctrl {get;set;}
    public InvoiceMassPrintCtrlExt(ApexPages.StandardSetController stdSetCtrl) {
        this.ctrl = new nTemplate.MultipleRecordsPrintController(stdSetCtrl);
    }
}