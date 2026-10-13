public with sharing class DataLoaderHelperCmpController {

    @AuraEnabled
    public static String processRestForExcel(String query, Id recordId, String restURL) {
        RestResponseBody restResponseBody;
        // Build endpoint
        // If first call, use query to build endpoint
        // else use restURL to build endpoint for nextRecordsUrl call
        String endpoint;
        if (String.isBlank(restURL)) {
            endpoint =  URL.getOrgDomainUrl().toExternalForm() +  '/services/data/v50.0/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        } else {
            endpoint = URL.getOrgDomainUrl().toExternalForm() + restURL;
        }

        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        httpReq.setMethod('GET');
        httpReq.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
        httpReq.setHeader('Sforce-Query-Options', 'batchSize=50');
        httpReq.setEndpoint(endpoint);
        
        if (!Test.isRunningTest()) {
            httpRes = http.send(httpReq);
            Map<String, String> resp = new Map<String, String>{'body' => httpRes.getBody()};
                System.debug('httpRes.getBody(): ' + JSON.serialize(httpRes.getBody()));
            if (httpRes.getStatusCode() == 400) {
                return JSON.serialize(new RestResponseBody(httpRes.getStatus()));
            }

            restResponseBody = (RestResponseBody) JSON.deserialize(resp.get('body'), RestResponseBody.class);         
            restResponseBody.error = null;
        }
        return JSON.serialize(restResponseBody);
	}

    public class RestResponseBody {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public List<SObject> records {get; set;}
        public String error {get; set;}
        public RestResponseBody (String error) {
            this.error = error;
        }
    }
}