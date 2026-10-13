/**
 * Apex REST Resource — NegOptim Case Handler
 *
 * Endpoint: POST /services/apexrest/negoptim/cases
 *
 * Called by Node.js middleware when a customer completes
 * the problem-reporting flow on WhatsApp or Facebook.
 *
 * Returns: { "caseId": "500xx0000000001AAA" }
 */
@RestResource(urlMapping='/negoptim/cases/*')
global class NegOptimCaseHandler {

    @HttpPost
    global static Map<String, String> createCase() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // ── Parse incoming JSON ──────────────────────────────────────
            Map<String, Object> body =
                (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            String externalRef  = (String) body.get('externalRef');
            String reportId     = externalRef.substring(0, 8);
            String channel      = (String) body.get('channel');       // 'whatsapp' | 'facebook'
            String userId       = (String) body.get('userId');        // Meta sender ID
            String contact      = (String) body.get('contact');       // name or account ref
            String category     = (String) body.get('category');
            String priority     = (String) body.get('priority');
            String description  = (String) body.get('description');
            String reportedAt   = (String) body.get('reportedAt');

            // ── Validate required fields ─────────────────────────────────
            if (String.isBlank(externalRef) || String.isBlank(description)) {
                res.statusCode = 400;
                return new Map<String, String>{
                    'error' => 'externalRef and description are required'
                };
            }

            // ── Prevent duplicate cases ──────────────────────────────────
            List<Case> existing = [
                SELECT Id FROM Case
                WHERE SP_External_Ref__c = :externalRef
                LIMIT 1
            ];
            if (!existing.isEmpty()) {
                res.statusCode = 409;
                return new Map<String, String>{
                    'error'  => 'Case already exists',
                    'caseId' => existing[0].Id
                };
            }

            // ── Map priority ─────────────────────────────────────────────
            String sfPriority = 'Medium';
            if (priority == 'critical' || priority == 'high') sfPriority = 'High';
            else if (priority == 'low')                        sfPriority = 'Low';

            // ── Map origin ───────────────────────────────────────────────
            String sfOrigin = (channel == 'whatsapp') ? 'Chat' : 'Web';

            // ── Create the Case ──────────────────────────────────────────
            Case newCase           = new Case();
            newCase.Subject        = '[' + channel.toUpperCase() + '] ' + category + ' – ' + contact;
            newCase.Description    = description;
            newCase.Origin         = sfOrigin;
            newCase.Priority       = sfPriority;
            newCase.Status         = 'New';

            // Custom fields (add these in Setup → Object Manager → Case → Fields):
            // SP_External_Ref__c    Text(255)  — Node.js report UUID
            // SP_Channel__c         Text(50)   — 'whatsapp' or 'facebook'
            // SP_Channel_User_Id__c Text(255)  — Meta sender ID
            // SP_Reported_At__c     DateTime   — when customer reported it
            newCase.SP_External_Ref__c    = externalRef;
            newCase.SP_Report_Id__c       = reportId;
            newCase.SP_Channel__c         = channel;
            newCase.SP_Channel_User_Id__c = userId;

            if (String.isNotBlank(reportedAt)) {
                try {
                    newCase.SP_Reported_At__c = (DateTime) JSON.deserialize(
                        '"' + reportedAt + '"', DateTime.class
                    );
                } catch (Exception e) { /* skip if date parse fails */ }
            }

            insert newCase;

            // ── Add internal note with full channel details ───────────────
            CaseComment note      = new CaseComment();
            note.ParentId         = newCase.Id;
            note.IsPublished      = false; // internal only
            note.CommentBody      =
                'Reported via: ' + channel      + '\n' +
                'Contact ref:  ' + contact      + '\n' +
                'Category:     ' + category     + '\n' +
                'Priority:     ' + priority     + '\n' +
                'User ID:      ' + userId       + '\n' +
                'Report ID:    ' + reportId    + '\n' +
                'Reported at:  ' + reportedAt;
            insert note;

            res.statusCode = 201;
            return new Map<String, String>{ 'caseId' => newCase.Id };

        } catch (Exception e) {
            res.statusCode = 500;
            return new Map<String, String>{
                'error'  => e.getMessage(),
                'detail' => e.getStackTraceString()
            };
        }
    }
}