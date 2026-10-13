/**
 * @author ULiT
 * @date 11-11-2025
 * @Description helper class for E-Invoicing
*/ 
public class EInvoicingService {
    
    public static String sendUBLToPostman(String xmlData) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EInvoicing/uploadUBL');
        req.setMethod('POST');
        
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('Accept', 'application/json');
        // REQUIRED for Postman mock if body matching is on
        //req.setHeader('X-Mock-Match-Request-Body', 'true');

        req.setBody(xmlData);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Response: ' + res.getBody());
        return res.getBody();
    }
    
    /**
     * Sends a UBL or Reporting XML file to E-Invoicing platform
     * @param xmlString      The UBL or Reporting XML content as string
     * @param fileType       'INVOICE' or 'EREPORT'
     */
    public static EInvResponse sendEInvoice(String xmlString, String fileType) {
        EInvResponse resp = new EInvResponse();
        try {
            HttpRequest req = new HttpRequest();
            //req.setEndpoint('callout:EInvoicing/invoices/submit'); // Adjust endpoint
            req.setEndpoint('callout:EInvoicing/uploadUBL'); // Change path
            req.setMethod('POST');
            //req.setHeader('Content-Type', 'application/xml');
            req.setHeader('Content-Type', 'application/xml; charset=UTF-8');
            req.setHeader('Accept', 'application/json');
            //req.setHeader('File-Type', fileType);   // Optional - based on API
            req.setHeader('EFile-Type', fileType);   // or Invoice-Type / Document-Type; depends on API => EFile-Type: INVOICE (or EREPORT)
            req.setBody(xmlString);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response: ' + res.getBody());
            if(res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                resp.status     = (String)result.get('status');
                resp.message    = (String)result.get('message');
                resp.invoiceId  = (String)result.get('invoiceId');
                resp.trackingId = (String)result.get('trackingId');
            } else {
                resp.status = 'Error';
                resp.message = res.getBody();
            }
        } catch (Exception ex) {
            resp.status = 'Exception';
            resp.message = ex.getMessage();
        }

        return resp;
    }
    
    public static String uploadUBL(String ublXmlString, String fileName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EINV_Platform/invoices/upload');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('Accept', 'application/json');
        req.setBody(ublXmlString);
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
    
    public static String uploadEReporting(String jsonPayload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:EINV_Platform/reports/upload');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(jsonPayload);
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
    
    public class EInvResponse {
        public String status;
        public String message;
        public String invoiceId;
        public String trackingId;
    }
}