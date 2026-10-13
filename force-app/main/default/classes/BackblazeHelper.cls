public with sharing class BackblazeHelper {


    // private static final String KEY_ID = '0052cbc419ba3c30000000001';

    // private static final String APP_KEY = 'K005lu2XikRvxJTsU1Vz/AtpHCiWEqE';

    // private static final String BUCKET_ID = 'b2ac0b9c2471b9eb9a930c13';

    // private static final String BUCKET_NAME = 'logos-explorer';




    //  private static final String KEY_ID = '005b8023dcfd2e10000000003';

    // private static final String APP_KEY = 'K005HVFyD2BnW3TXdv5v29ikuQORN1g';

    // private static final String BUCKET_ID = 'db68c0a233bd3caf9da20e11';

    // private static final String BUCKET_NAME = 'logosicons';

    // private static final Integer EXPIRATION = 3600;



    
     private static final String KEY_ID = '0057c2a254a9a420000000001';

    private static final String APP_KEY = 'K005tbXQ3O5/j9WQm4/FoYJS3gp9zLQ';

    private static final String BUCKET_ID = '174c121a22e5d49a99aa0412';

    private static final String BUCKET_NAME = 'sflogos';

    private static final Integer EXPIRATION = 3600;


    public class AuthResult {

        public String apiUrl;

        public String downloadUrl;

        public String authorizationToken;

    }


    private static String getBasicAuthHeader() {

        String combo = KEY_ID + ':' + APP_KEY;

        return 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(combo));

    }


    @AuraEnabled(cacheable=true)

    public static String getPublicUrl(String fileName) {

        AuthResult auth = authorize();

        String downloadAuth = getDownloadAuth(auth, fileName);

        return buildUrl(auth.downloadUrl, fileName, downloadAuth);

    }


    @AuraEnabled(cacheable=true)

    public static List<String> getMultipleLogos(List<String> fileNames) {

        List<String> urls = new List<String>();

        for(String fileName : fileNames){

            urls.add(getPublicUrl(fileName));

        }

        return urls;

    }


    
















    @AuraEnabled(cacheable=true)

    public static List<Map<String, String>> getAllLogos() {

    AuthResult auth = authorize();


    HttpRequest req = new HttpRequest();

    req.setEndpoint(auth.apiUrl + '/b2api/v2/b2_list_file_names');

    req.setMethod('POST');

    req.setHeader('Authorization', auth.authorizationToken);

    req.setHeader('Content-Type', 'application/json');


    Map<String, Object> body = new Map<String, Object>{

        'bucketId' => BUCKET_ID,

        'maxFileCount' => 1000 

    };


    req.setBody(JSON.serialize(body));


    HttpResponse res = new Http().send(req);


    if(res.getStatusCode() != 200){

        throw new AuraHandledException('Failed to list files: ' + res.getBody());

    }


    Map<String,Object> data = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

    List<Object> files = (List<Object>) data.get('files');


    List<Map<String, String>> logos = new List<Map<String,String>>();


    for(Object f : files){

        Map<String,Object> fileObj = (Map<String,Object>) f;

        String fileName = (String) fileObj.get('fileName');

        String url = buildUrl(auth.downloadUrl, fileName, getDownloadAuth(auth, fileName));

        logos.add(new Map<String,String>{ 'name' => fileName, 'url' => url });

    }


    return logos;

    }














    private static AuthResult authorize() {


        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.backblazeb2.com/b2api/v2/b2_authorize_account');

        req.setMethod('GET');

        req.setHeader('Authorization', getBasicAuthHeader());


        HttpResponse res = new Http().send(req);


        if (res.getStatusCode() != 200) {

            throw new AuraHandledException('Auth failed: ' + res.getBody());

        }


        Map<String, Object> data =

            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());


        AuthResult result = new AuthResult();

        result.apiUrl = (String) data.get('apiUrl');

        result.downloadUrl = (String) data.get('downloadUrl');

        result.authorizationToken = (String) data.get('authorizationToken');

        return result;

    }


    private static String getDownloadAuth(AuthResult auth, String fileName) {


        HttpRequest req = new HttpRequest();

        req.setMethod('POST');

        req.setEndpoint(auth.apiUrl + '/b2api/v2/b2_get_download_authorization');

        req.setHeader('Authorization', auth.authorizationToken);

        req.setHeader('Content-Type', 'application/json');


        Map<String, Object> body = new Map<String, Object>{

            'bucketId' => BUCKET_ID,

            'fileNamePrefix' => fileName,

            'validDurationInSeconds' => EXPIRATION

        };


        req.setBody(JSON.serialize(body));


        HttpResponse res = new Http().send(req);


        if (res.getStatusCode() != 200) {

            throw new AuraHandledException('DownloadAuth failed: ' + res.getBody());

        }


        Map<String, Object> data =

            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());


        return (String) data.get('authorizationToken');

    }


    private static String buildUrl(String downloadUrl, String fileName, String token) {

        String encoded = EncodingUtil.urlEncode(fileName, 'UTF-8');

        return downloadUrl + '/file/' + BUCKET_NAME + '/' + encoded + '?Authorization=' + token;

    }


    @AuraEnabled

    public static String testAuth() {

        AuthResult a = authorize();

        return JSON.serializePretty(a);

    }

}