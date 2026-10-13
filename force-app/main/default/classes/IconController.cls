public with sharing class IconController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getImageResources() {
        List<StaticResource> resources = [
            SELECT Id, Name, ContentType
            FROM StaticResource
            WHERE ContentType LIKE 'image/%'
            ORDER BY Name
        ];

        List<Map<String, String>> result = new List<Map<String, String>>();

        for (StaticResource res : resources) {
            result.add(new Map<String, String>{
                'name' => res.Name,
                'url' => URL.getOrgDomainUrl().toExternalForm() + '/resource/' + res.Name
            });
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getZipImageResources() {
        List<StaticResource> zipResources = [
            SELECT Id, Name, ContentType, Body
            FROM StaticResource
            WHERE ContentType LIKE 'application/%zip%'
        ];

        List<Map<String, String>> result = new List<Map<String, String>>();
        for (StaticResource res : zipResources) {
            result.add(new Map<String, String>{
                'name' => res.Name,
                'url' => URL.getOrgDomainUrl().toExternalForm() + '/resource/' + res.Name,
                'fetchUrl' => URL.getOrgDomainUrl().toExternalForm() + '/services/data/v56.0/sobjects/StaticResource/' + res.Id + '/Body'
            });
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, String> getSessionKeys() {
        String sessionId = NegoptimHelper.getSessionId();
        Map<String, String> keys = new Map<String, String>{
            'KeyPageWSubstring' => !String.isBlank(sessionId) ? sessionId.substring(15) : '',
            'BASEURL' => URL.getOrgDomainUrl().toExternalForm(),
            'URL' => URL.getOrgDomainUrl().toExternalForm() + '/services/data/v56.0/query/?q='
        };
        return keys;
    }


}