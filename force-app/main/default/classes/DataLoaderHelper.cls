/**
 * @author ULiT
 * @date 20/01/2026
 * @description Helper Methods for Rest API
 **/
public class DataLoaderHelper {

    /**
     * @description retrieving data for Excel exports, fetching large data in chunks
    */
    public static String processRestForExcel(String query, String restURL, String error, String objectName) {
        if (String.isNotBlank(error)) {
            return JSON.serialize(new RestResponseBody(error));
        }
        RestResponseBody restResponseBody = new RestResponseBody(null);
        // Build endpoint
        // If first call, use query to build endpoint
        // else use restURL to build endpoint for nextRecordsUrl call
        String endpoint;
        system.debug('query >>> ' + query);
        if (String.isBlank(restURL)) {
            query = addQueryPrefix(query, objectName);
            endpoint =  URL.getOrgDomainUrl().toExternalForm() +  '/services/data/v50.0/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        } else {
            endpoint = URL.getOrgDomainUrl().toExternalForm() + restURL;
        }
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        httpReq.setMethod('GET');
        httpReq.setHeader('Authorization', 'Bearer ' + NegoptimHelper.getSessionId());
        httpReq.setHeader('Sforce-Query-Options', 'batchSize=100');
        httpReq.setEndpoint(endpoint);
        
        if (!Test.isRunningTest()) {
            httpRes = http.send(httpReq);
            Map<String, String> resp = new Map<String, String>{'body' => httpRes.getBody()};
            if (httpRes.getStatusCode() == 400) {
                List<Object> errors = (List<Object>) JSON.deserializeUntyped(httpRes.getBody());
                String message = httpRes.getStatus();
                if (!errors.isEmpty()) {
                    Map<String, Object> errorResult = (Map<String, Object>) errors[0];
                    message = (String) errorResult.get('message');
                }
                return JSON.serialize(new RestResponseBody(message));
            }
            restResponseBody = (RestResponseBody) JSON.deserialize(resp.get('body'), RestResponseBody.class);         
            restResponseBody.error = null;
        }
        return JSON.serialize(restResponseBody);
	}
    
    private static String addQueryPrefix(String query, String objectName) {
        String prefix = NegoptimHelper.getPackagePrefix(true);
        Matcher fromM = Pattern.compile('(?i)\\bFROM\\s+([A-Za-z][A-Za-z0-9_]*__c)').matcher(query);
        if (fromM.find() && objectName != fromM.group(1)) {
            query = query.replaceFirst('(?i)\\bFROM\\s+' + fromM.group(1) + '\\b', 'FROM ' + objectName);
        }
        Map<String, Schema.SObjectField> rootFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        String regex = '(?<!' + prefix.toLowerCase() + ')[A-Za-z][A-Za-z0-9_]*(?:\\.[A-Za-z][A-Za-z0-9_]*)*';
        Matcher fieldsM = Pattern.compile(regex).matcher(query);
        String result = '';
        Integer lastEnd = 0;
        while (fieldsM.find()) {
            result += query.substring(lastEnd, fieldsM.start()) + prefixPath(fieldsM.group(), rootFields, prefix);
            lastEnd = fieldsM.end();
        }
        return result + query.substring(lastEnd);
    }

    private static String prefixPath(String fieldPath, Map<String, Schema.SObjectField> currentFields, String prefix) {
        List<String> splittedField = fieldPath.split('\\.');
        List<String> resolved = new List<String>();
        for (String segment : splittedField) {
            Boolean isRelationship = segment.endsWith('__r');
            String apiName = isRelationship ? segment.removeEnd('__r') + '__c' : segment;
            String fieldName = currentFields.containsKey((prefix + apiName).toLowerCase()) ? (prefix + apiName).toLowerCase() : apiName;
            resolved.add(isRelationship ? fieldName.removeEnd('__c') + '__r' : fieldName);
            if (isRelationship) {
                currentFields = getRefFields(currentFields.get(fieldName));
            }
        }
        return String.join(resolved, '.');
    }

    private static Map<String, Schema.SObjectField> getRefFields(Schema.SObjectField f) {
        List<Schema.SObjectType> refs = f.getDescribe().getReferenceTo();
        return refs.isEmpty() ? null : refs[0].getDescribe().fields.getMap();
    }


    public class RestResponseBody {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public List<SObject> records {get; set;}
        public String error {get; set;}
        public RestResponseBody (String error) {
            this.error = error;
            this.records = new List<SObject>();
        }
    }

}