public class MockHttpResponseGenerator implements HttpCalloutMock {
    HttpResponse mockResponse;
    public MockHttpResponseGenerator(HttpResponse r) { this.mockResponse = r; }
    
    /*public HTTPResponse respond(HTTPRequest req) {
        return mockResponse;
    }*/
    
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"status":"Accepted","trackingId":"TRK123"}');
        return res;
    }
}