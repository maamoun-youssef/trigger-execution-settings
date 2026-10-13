/**
 * Executive Summary for Simulation Contract
 * used for pdf and email because we got error
 * on generation of pdf when using same controller,
 * it seems rendered the same page that contains
 * non valid components for getContentAsPDF()
 * */
public class ExecutiveSummaryPDFController  {
    
    public ExecutiveSummaryController ctrlr {get; set;}
    
    ////public String documentURL = System.URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=';
    public String documentURL = System.URL.getOrgDomainUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=';
    ////public String assetsURL = System.URL.getOrgDomainUrl().toExternalForm() + NegoptimHelper.GetResourceURL('Assets') + '/assets/img/';
    List<Document> imagesDocumentList;
    public String imgLeft {
        get {
            return documentURL + getImageId('left');
        }
        set;
    }
    public String imgRight {
        get {
            return documentURL + getImageId('right') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'right-arrow.png';
        }
        set;
    }
    public String imgUp {
        get {
            return documentURL + getImageId('up') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'up-arrow.png';
        }
        set;
    }
    public String imgDown {
        get {
            return documentURL + getImageId('down') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'down-arrow.png';
        }
        set;
    }
    
    // Constructor
    public ExecutiveSummaryPDFController() {
        String selectedContractId = ApexPages.currentPage().getParameters().get('id');
        ApexPages.currentPage().getParameters().put('id', selectedContractId);
        ctrlr = new ExecutiveSummaryController();
        // check security on Document fields
        String[] documentFields = new String[] {
            SObjectType.Document.fields.Id.Name,
            SObjectType.Document.fields.Name.Name,
            SObjectType.Document.fields.FolderId.Name
        };
        // check security on Folder fields
        String[] folderFields = new String[] {
            SObjectType.Folder.fields.Name.Name
        };
        if (NegoptimHelper.checkAccessibility(Document.SObjectType, documentFields)
           && NegoptimHelper.checkAccessibility(Folder.SObjectType, folderFields)) {
            imagesDocumentList = [SELECT Id, Name from Document WHERE Folder.Name = 'Public' AND Name LIKE '%_arrow'];             
        }
        if(imagesDocumentList.size() == 0) {
            
        }
    }
    
    public String getImageId(String str) {
        for(Document item : imagesDocumentList) {
            if(item.Name.contains(str)) {
                return item.Id;
            }
        }
        return '';
    }
}