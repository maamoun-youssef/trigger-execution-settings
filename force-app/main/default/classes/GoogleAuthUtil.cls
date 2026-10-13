public with sharing class GoogleAuthUtil {
    
    // Replace with your service account email and private key
    private static final String SERVICE_ACCOUNT_EMAIL = 'your-service-account@your-project.iam.gserviceaccount.com';
    private static final String PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\nMIIEv...IDAQAB\n-----END PRIVATE KEY-----\n';
    private static final String GOOGLE_OAUTH_TOKEN_URI = 'https://oauth2.googleapis.com/token';
    private static final String TARGET_AUDIENCE = 'https://example.com';

    public static String getGoogleIdToken() {
        String jwt = createSignedJwt();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(GOOGLE_OAUTH_TOKEN_URI);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + EncodingUtil.urlEncode(jwt, 'UTF-8'));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('id_token');
        } else {
            System.debug('Failed to get ID token: ' + res.getBody());
            return null;
        }
    }

    private static String createSignedJwt() {
        Long now = DateTime.now().getTime() / 1000;
        Long exp = now + 3600;

        Map<String, Object> header = new Map<String, Object>{
            'alg' => 'RS256',
            'typ' => 'JWT'
        };
        Map<String, Object> claims = new Map<String, Object>{
            'iss' => SERVICE_ACCOUNT_EMAIL,
            'sub' => SERVICE_ACCOUNT_EMAIL,
            'aud' => GOOGLE_OAUTH_TOKEN_URI,
            'iat' => now,
            'exp' => exp,
            'target_audience' => TARGET_AUDIENCE
        };

        String encodedHeader = ''; //EncodingUtil.base64Encode(JSON.serialize(header).getBytes('UTF-8')).replaceAll('=+$', '').replace('+', '-').replace('/', '_');
        String encodedClaims = ''; //EncodingUtil.base64Encode(JSON.serialize(claims).getBytes('UTF-8')).replaceAll('=+$', '').replace('+', '-').replace('/', '_');
        String unsignedJwt = encodedHeader + '.' + encodedClaims;

        Blob signature = Crypto.sign('RSA-SHA256', Blob.valueOf(unsignedJwt), parsePrivateKey(PRIVATE_KEY));
        String encodedSignature = EncodingUtil.base64Encode(signature).replaceAll('=+$', '').replace('+', '-').replace('/', '_');

        return unsignedJwt + '.' + encodedSignature;
    }

    private static Blob parsePrivateKey(String privateKeyPem) {
        // Remove header/footer and line breaks
        String privateKeyClean = privateKeyPem.replace('-----BEGIN PRIVATE KEY-----', '')
                                              .replace('-----END PRIVATE KEY-----', '')
                                              .replaceAll('\\s+', '');
        return EncodingUtil.base64Decode(privateKeyClean);
    }
}