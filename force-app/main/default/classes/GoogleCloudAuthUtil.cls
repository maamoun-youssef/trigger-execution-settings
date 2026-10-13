public class GoogleCloudAuthUtil {
    private static final String TOKEN_URI = 'https://oauth2.googleapis.com/token';
    
    public class TokenResponse {
        public String id_token;
    }

    public static String getIdToken(String clientEmail, String privateKey, String targetAudience) {
        String jwt = createJwt(clientEmail, privateKey, targetAudience);

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(TOKEN_URI);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt);

        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            TokenResponse tokenResp = (TokenResponse) JSON.deserialize(response.getBody(), TokenResponse.class);
            return tokenResp.id_token;
        } else {
            System.debug('Failed to get ID token: ' + response.getBody());
            return null;
        }
    }

    private static String createJwt(String clientEmail, String privateKey, String targetAudience) {
        Long issuedAt = DateTime.now().getTime() / 1000;
        Long expiry = issuedAt + 3600;

        Map<String, Object> jwtHeader = new Map<String, Object>{
            'alg' => 'RS256',
            'typ' => 'JWT'
        };

        Map<String, Object> jwtClaimSet = new Map<String, Object>{
            'iss' => clientEmail,
            'sub' => clientEmail,
            'aud' => TOKEN_URI,
            'iat' => issuedAt,
            'exp' => expiry,
            'target_audience' => targetAudience
        };

        String encodedHeader = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtHeader))).replaceAll('=','').replaceAll('\\+','-').replaceAll('/','_');
        String encodedClaims = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(jwtClaimSet))).replaceAll('=','').replaceAll('\\+','-').replaceAll('/','_');
        
        String unsignedJwt = encodedHeader + '.' + encodedClaims;

        // Sign the JWT using your service account's private key
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey); // Assuming base64 encoded key
        Blob signature = Crypto.sign('RSA-SHA256', Blob.valueOf(unsignedJwt), privateKeyBlob);
        String encodedSignature = EncodingUtil.base64Encode(signature).replaceAll('=','').replaceAll('\\+','-').replaceAll('/','_');

        return unsignedJwt + '.' + encodedSignature;
    }
}