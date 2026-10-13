//working version with named credential
public with sharing class CMSController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCMSImages() {
        List<Map<String, String>> finalResults = new List<Map<String, String>>();

        String namedCred = 'CMS_Named_Credential2'; //  Named Credential API Name
        String channelId = '0apQH000000ZcSDYA0'; // CMS channel ID

        Http http = new Http();

        try {
            // List endpoint using Named Credential
            String listEndpoint = 'callout:' + namedCred + 
                                  '/services/data/v65.0/connect/cms/delivery/channels/' + channelId + '/contents';

            HttpRequest listReq = new HttpRequest();
            listReq.setMethod('GET');
            listReq.setEndpoint(listEndpoint);

            HttpResponse listRes = http.send(listReq);
            if (listRes.getStatusCode() != 200) {
                System.debug('CMS LIST ERROR: ' + listRes.getBody());
                return finalResults;
            }

            Map<String, Object> listJson = (Map<String, Object>) JSON.deserializeUntyped(listRes.getBody());
            if (!listJson.containsKey('contents')) return finalResults;

            List<Object> items = (List<Object>) listJson.get('contents');

            for (Object obj : items) {
                Map<String, Object> item = (Map<String, Object>) obj;

                if (!item.containsKey('resourceUrl')) continue;
                String detailEndpoint = 'callout:' + namedCred + (String) item.get('resourceUrl');

                HttpRequest detailReq = new HttpRequest();
                detailReq.setMethod('GET');
                detailReq.setEndpoint(detailEndpoint);

                HttpResponse detailRes = http.send(detailReq);
                if (detailRes.getStatusCode() != 200) continue;

                Map<String, Object> detailJson = (Map<String, Object>) JSON.deserializeUntyped(detailRes.getBody());

                // --- Handle images ---
                String mediaUrl;
                if (detailJson.containsKey('contentBody') && ((Map<String, Object>) detailJson.get('contentBody')).containsKey('sfdc_cms:media')) {
                    Map<String, Object> media = (Map<String, Object>) ((Map<String, Object>) detailJson.get('contentBody')).get('sfdc_cms:media');

                    if (media.containsKey('url')) {
                        mediaUrl = (String) media.get('url');
                    } else if (media.containsKey('source')) {
                        Map<String, Object> source = (Map<String, Object>) media.get('source');
                        if (source.containsKey('ref') && detailJson.containsKey('managedContentId')) {
                            mediaUrl = '/cms/delivery/v65.0/' + channelId + '/contents/' + (String) detailJson.get('managedContentId');
                        }
                    }
                }

                if (String.isBlank(mediaUrl)) continue;

                String title = detailJson.containsKey('title') ? (String) detailJson.get('title') : '';
                String urlName = detailJson.containsKey('urlName') ? (String) detailJson.get('urlName') : '';

                Map<String, String> record = new Map<String, String>{
                    'title' => title,
                    'urlName' => urlName,
                    'imageUrl' => mediaUrl
                };
                finalResults.add(record);
            }

        } catch (Exception e) {
            System.debug('CMS EXCEPTION: ' + e.getMessage());
        }

        return finalResults;
    }
}