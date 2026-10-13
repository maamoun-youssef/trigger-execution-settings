/**
 * Apex Class — CaseCommentHandler
 *
 * Called by CaseCommentTrigger.
 * Runs as a future method (async) so callouts are allowed
 * after a DML operation (insert CaseComment).
 *
 * Calls POST https://your-middleware.com/send-message
 * so Node.js can forward the agent reply to the customer
 * on their original channel (WhatsApp or Facebook).
 */
public class CaseCommentHandler {

    // Node.js middleware URL — store in Custom Metadata or Custom Setting
    // for easy config without code changes. Hardcoded here for simplicity.
    private static final String MIDDLEWARE_URL =
        'callout:NegOptim_Middleware/send-message';
        // OR use the direct URL:
        // 'https://your-middleware-domain.com/send-message'

    @future(callout=true)
    public static void notifyCustomers(List<Id> commentIds) {
        // Query comments with their parent Case channel fields
        List<CaseComment> comments = [
            SELECT  Id,
                    CommentBody,
                    Parent.SP_External_Ref__c,
                    Parent.SP_Channel__c,
                    Parent.SP_Channel_User_Id__c,
                    Parent.Subject,
                    CreatedBy.Name
            FROM    CaseComment
            WHERE   Id IN :commentIds
              AND   Parent.SP_Channel__c != null        // only channel-originated cases
              AND   Parent.SP_External_Ref__c != null   // must have the Node.js report ID
        ];

        for (CaseComment cc : comments) {
            try {
                // Build the payload for Node.js /send-message
                Map<String, String> payload = new Map<String, String>{
                    'externalRef' => cc.Parent.SP_External_Ref__c,
                    'message'     => cc.CommentBody,
                    'agentName'   => cc.CreatedBy.Name
                };

                HttpRequest req = new HttpRequest();
                //req.setEndpoint(MIDDLEWARE_URL); TODO: waiting to fix named credentials
                req.setEndpoint('https://poison-kettle-arguably.ngrok-free.dev/send-message');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('X-Middleware-Secret',
                    /*System.Label.Middleware_Secret*/ 'Middleware_Secret'); // Custom Label in SF
                req.setBody(JSON.serialize(payload));
                req.setTimeout(10000);

                HttpResponse res = new Http().send(req);

                if (res.getStatusCode() != 200) {
                    System.debug(LoggingLevel.ERROR,
                        'CaseCommentHandler: Node.js returned ' +
                        res.getStatusCode() + ' — ' + res.getBody()
                    );
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'CaseCommentHandler error for comment ' + cc.Id +
                    ': ' + e.getMessage()
                );
            }
        }
    }
}