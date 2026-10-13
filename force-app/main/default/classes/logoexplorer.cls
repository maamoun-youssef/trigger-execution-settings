public with sharing class logoexplorer {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPrivateLogos() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://eurythmical-subbronchially-adeline.ngrok-free.dev/logos');
        req.setMethod('GET');
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to fetch logos: ' + res.getBody());
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (List<Map<String, Object>>) body.get('data');
    }
}