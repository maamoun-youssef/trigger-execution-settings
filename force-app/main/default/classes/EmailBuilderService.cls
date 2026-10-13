public with sharing class EmailBuilderService {
    public class ObjectFieldGroup {
        public String objectName { get; set; }
        public List<String> fieldLabels { get; set; }
        public List<String> fieldValues { get; set; }
    }
    public static Map<String, Map<String, String>> labels = new Map<String, Map<String, String>>{
        'en' => new Map<String, String>{
            'greeting' => 'Hello',
            'okTables' => 'ok tables',
            'koTables' => 'ko tables',
            'footer' => 'Best Regards</br> The NegOptim team'
        },
        'fr' => new Map<String, String>{
            'greeting' => 'Salut',
            'okTables' => 'Tables OK',
            'koTables' => 'Tables KO',
            'footer' => 'Cordialement,<br/>L’equipe NegOptim'
        }
    };
    public static Map<String, String> getLabels(String userLocale) {
        if (labels.containsKey(userLocale)) { return labels.get(userLocale); }
        return labels.get('en'); // default English
    }
    public static String buildFullEmailBody(User user, String customMessage, List<String> okTablesHtml, List<String> koTablesHtml) {

        System.debug('in build email body local language key: ' + user.LanguageLocaleKey);
        Map<String,String> labels = getLabels(user.LanguageLocaleKey);
        String emailBody = '';

        emailBody += '<div style="font-family:Arial,sans-serif;">';
        emailBody += '<p>' + labels.get('greeting') + ' ' + user.FirstName + ' ' + user.LastName + ',</p>';
        emailBody += '<p>' + customMessage + '</p>';

        if (!okTablesHtml.isEmpty()) {
            emailBody += '<h3>' + labels.get('okTables') + '</h3>';
            for (String tableHtml : okTablesHtml) {
                emailBody += tableHtml + '<br/>';
            }
        }
        if (!koTablesHtml.isEmpty()) {
            emailBody += '<h3>' + labels.get('koTables') + '</h3>';
            for (String tableHtml : koTablesHtml) {
                emailBody += tableHtml + '<br/>';
            }
        }
        emailBody += '<p>' + labels.get('footer') + '</p>';
        emailBody += '</div>';

        return emailBody;
    }

    public static String buildDynamicTable(List<ObjectFieldGroup> objectGroups, String status, String errorMessage){
        String html= '<table style="width:100%" border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
        html+='<tr>';
        for(ObjectFieldGroup objectGroup:objectGroups){
            html += '<th colspan='+objectGroup.fieldLabels.size()+'>'+objectGroup.objectName+'</th>';
        }
        html+='<th rowspan="2"> Status</th>';
        if(status =='Error'){
            html+='<th rowspan="2"> Error</th>';
        }
        html+='</tr><tr>';
        for(ObjectFieldGroup objgroup: objectGroups){
            for(String fieldname:objgroup.fieldLabels){
                html+='<th style="text-align:center;">'+fieldname+'</th>';
            }
        }
        html+='</tr><tr>';
        for(Integer objIndex = 0; objIndex<objectGroups.size();objIndex++){
            ObjectFieldGroup objGroup = objectGroups[objIndex];
            Integer totalFields = objGroup.fieldValues.size();
            Integer half = (totalFields + 1) / 2;
            for(Integer i=0; i<totalFields; i++){
            String align = i < half ? 'left' : 'right';
            String value = objGroup.fieldValues[i];
            
            if(objIndex == 0 && i == 0){
                System.debug('hello:'+value);
                html += '<td style="text-align:' + align + ';"><a href="#">' + value + '</a></td>';
                System.debug('hello again:'+'<td style="text-align:' + align + ';"><a href="#">' + value + '</a></td>');
            } else {
                html += '<td style="text-align:' + align + ';">' + value + '</td>';
            }
        }
        }
        html += '<td>' + status + '</td>';
        if (status == 'Error') {
            html += '<td>' + errorMessage + '</td>';
        }
        html += '</tr>';
        html+='</table>';
        return html;
    }

    //this method is without text alignment of the fields values
    // public static String buildDynamicTableWithoutAlignment(List<ObjectFieldGroup> objectGroups, String status, String errorMessage){
    //     String html= '<table style="width:100%" border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
    //     html+='<tr>';
    //     for(ObjectFieldGroup objectGroup:objectGroups){
    //         html += '<th colspan='+objectGroup.fieldLabels.size()+'>'+objectGroup.objectName+'</th>';
    //     }
    //     html+='<th rowspan="2"> Status</th>';
    //     if(status =='Error'){
    //         html+='<th rowspan="2"> Error</th>';
    //     }
    //     html+='</tr><tr>';
    //     for(ObjectFieldGroup objgroup: objectGroups){
    //         for(String fieldname:objgroup.fieldLabels){
    //             html+='<th>'+fieldname+'</th>';
    //         }
    //     }
    //     html+='</tr><tr>';
    //     for(ObjectFieldGroup objgroup: objectGroups){
    //         for(String fieldValue:objgroup.fieldValues){
    //             html+='<td>'+fieldValue+'</td>';
    //         }
    //     }
    //     html += '<td>' + status + '</td>';
    //     if (status == 'Error') {
    //         html += '<td>' + errorMessage + '</td>';
    //     }
    //     html += '</tr>';
    //     html+='</table>';
    //     return html;
    // }
}