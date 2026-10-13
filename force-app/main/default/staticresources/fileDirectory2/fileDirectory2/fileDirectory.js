window.openFileDirectoryUpload = (event) => {
    let fdirrecordid = event?.target?.dataset?.recordid;
    console.log(`🚀 -------------------------------------🚀`);
    console.log(`🚀 ~ :3 ~ fdirrecordid:`, fdirrecordid);
    console.log(`🚀 -------------------------------------🚀`);
    let cmpPrefix = [
        'negoptim-file-directory-manager',
        'c-file-directory-manager'
    ]
    try {

        // let _elms = document.querySelectorAll(cmpPrefix?.map(it => `${it} lightning-file-upload[data-recordid="${fdirrecordid}"]`)?.join(','));
        let _elms = document.body.querySelectorAll(cmpPrefix?.map(it => `lightning-file-upload[data-recordid="${fdirrecordid}"]`)?.join(','));
        console.log(`🚀 ------------------------🚀`);
        console.log(`🚀 ~ :13 ~ _elms:`, _elms);
        console.log(`🚀 ~ :13 ~ _elms.length:`, _elms.length);
        console.log(`🚀 ------------------------🚀`);
        let elms = document.querySelectorAll(cmpPrefix?.map(it => `${it} lightning-file-upload[data-recordid="${fdirrecordid}"] .slds-file-selector__input`)?.join(','));
        console.log(`🚀 ----------------------🚀`);
        console.log(`🚀 ~ :12 ~ elms:`, elms);
        console.log(`🚀 ~ :12 ~ elms.length:`, elms.length);
        console.log(`🚀 ----------------------🚀`);
        elms?.forEach(elm => {
            console.log(elm);
            elm?.click?.();
        });
    } catch (err) {
        console.error(err);
    }
}