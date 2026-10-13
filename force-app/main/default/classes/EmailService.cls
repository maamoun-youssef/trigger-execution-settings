public with sharing class EmailService {

    public static void sendEmail(String recipientEmail, String recipientName, String subject, String recordId, String templateId) {
        PageReference previewPage = Page.nTemplate__PreviewDoc;
        previewPage.getParameters().put('rid', recordId);
        previewPage.getParameters().put('tid', templateId);
        previewPage.getParameters().put('preview', 'true');
        String content = previewPage.getContent().toString();
        content = content.substringBetween('<body>', '</body>');
        sendEmail(recipientEmail, recipientName, subject, content);
    }

    public static void sendEmail(String recipientEmail, String recipientName, String subject, String customBody) {
        if (String.isBlank(recipientEmail)) {
            throw new EmailException('Recipient email is not set.');
        }

        Map<String, String> labels = getLabels();
        Map<String, String> logos = getHeaderFooterLogoUrls();

        String body = buildFullEmail(recipientName, customBody, labels, logos);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { recipientEmail });
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    private static String buildFullEmail(String recipientName,String customEmailBody,Map<String, String> labels,Map<String, String> clientLogos) {
        String body = '<div style="font-family:Arial,sans-serif;">';
        body+='<img src="'+clientLogos.get('headerLogo')+'" alt="Logo" style="display: block; margin-top: 10px; width: 200px;"/>';
        body += '<p>' + labels.get('greeting')+'<strong>' + ' ' + recipientName +'</strong>,</p>';
        body += '<p><br></p>';
        body += customEmailBody;
        body += '<p><br></p>';
        body += '<p>' + labels.get('bestRegards') + ',</br>' + labels.get('theNegOptimTeam') + ',</p>';
        body+='<p><br></p>';
        body+='<p><img src="'+clientLogos.get('footerLogo')+'" alt="Logo" style="display: block; margin-top: 10px; width: 200px;"/></p>';
        body += '</div>';
        return body;
    }

    private static Map<String,String> getLabels() {
        return new Map<String,String>{
            'greeting' => NegoptimLabels.getCustomLabel('LBL_Greeting', 'Hello'),
            'bestRegards' => NegoptimLabels.getCustomLabel('LBL_Best_Regards', 'Best Regards'),
            'theNegOptimTeam' => NegoptimLabels.getCustomLabel('LBL_Negoptim_Team', 'The NegOptim team')
        };
    }

    public static Map<String, String> getHeaderFooterLogoUrls() {
        Map<String, String> result = new Map<String, String>{
            'headerLogo' => null,
            'footerLogo' => null
        };
        List<Document> docs = [
            SELECT Id, Name
            FROM Document
            WHERE Name IN ('Client_Logo', 'negOptim_by_ULiT_Logo')
        ];
        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String orgId = UserInfo.getOrganizationId();

        for (Document d : docs) {
            if (d.Name == 'Client_Logo') {
                result.put('headerLogo', baseUrl + '/servlet/servlet.ImageServer?id=' + d.Id + '&oid=' + orgId);
            } else if (d.Name == 'negOptim_by_ULiT_Logo') {
                result.put('footerLogo', baseUrl + '/servlet/servlet.ImageServer?id=' + d.Id + '&oid=' + orgId);
            }
        }
        return result;
    }

    public class EmailException extends Exception {}
}