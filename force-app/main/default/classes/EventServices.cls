public without sharing class EventServices {
    public static void sendNotification(Set<String> reciIds, Id recordId, CustomNotificationType notifType, String title, String body) {
        if (notifType == null || reciIds == null || reciIds.isEmpty()) return;
        List<Messaging.CustomNotification> notificationsToSend = new List<Messaging.CustomNotification>();
        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notifType.Id);
        notif.setTitle(title);
        notif.setBody(body);
        notif.setTargetId(recordId);
        notif.send(reciIds);
     }
    public static void sendNotification(Set<String> reciIds, Id recordId, CustomNotificationType notifType, String title, String body, Boolean sendEmail, String emailHeaderFR, String emailHeaderEN, Boolean isSentToPortal, Map<String, Map<String, String>> usersWithLabelMap) {
        if (notifType != null && reciIds != null && !reciIds.isEmpty()) {
            if (!usersWithLabelMap.isEmpty()) {
                for (String reciId : reciIds) {
                    if (usersWithLabelMap.containsKey(reciId)) {
                        Map<String, String> labelMap = usersWithLabelMap.get(reciId);
                        body = labelMap.containsKey('body') ? labelMap.get('body') : body;
                        title = labelMap.containsKey('title') ? labelMap.get('title') : title;
                        Messaging.CustomNotification notif = new Messaging.CustomNotification();
                        notif.setNotificationTypeId(notifType.Id);
                        notif.setTitle(title);  
                        notif.setBody(body);
                        notif.setTargetId(recordId);
                        notif.send(new Set<String>{reciId});
                    } else {
                        continue;
                    }
                }
            } else {
                Messaging.CustomNotification notif = new Messaging.CustomNotification();
                notif.setNotificationTypeId(notifType.Id);
                notif.setTitle(title);  
                notif.setBody(body);
                notif.setTargetId(recordId);
                notif.send(reciIds);
            }
        }
        if(sendEmail) {
            sendEmail(reciIds, recordId, title, body, emailHeaderFR, emailHeaderEN, isSentToPortal, usersWithLabelMap);
        }   
     }
    public static void sendEmail(Set<String> reciIds, Id recordId, String title, String body, String emailHeaderFR, String emailHeaderEN, Boolean isSentToPortal, Map<String, Map<String, String>> usersWithLabelMap) {
        String header = '', headerFR = '', headerEN = '', footer = '', domainURL, greetingMsg, closingMsg, loginMsg;
        List<String> letterHeadNames = new List<String>();
        if (String.isNotBlank(emailHeaderFR)) letterHeadNames.add(emailHeaderFR);
        if (String.isNotBlank(emailHeaderEN)) letterHeadNames.add(emailHeaderEN);
        letterHeadNames.add('Connect Footer');
        List<User> userList = [SELECT Id, Name, Email,ContactId , LanguageLocaleKey, FirstName, LastName FROM User WHERE Id IN :reciIds AND IsActive = true];      

        try {
            List<EnhancedLetterhead> ehs = [SELECT Name, LetterheadHeader, LetterheadFooter
                                            FROM EnhancedLetterhead
                                            WHERE Name IN :letterHeadNames];
            for (EnhancedLetterhead eh : ehs) {
                if (eh.Name == emailHeaderFR) headerFR = eh.LetterheadHeader;
                else if(eh.Name == emailHeaderEN) headerEN = eh.LetterheadHeader;
                // MAKE TWO FOOTERS EN AND FR LATER
                else if (eh.Name == 'Connect Footer') footer = eh.LetterheadFooter;
            }
        } catch (Exception e) {
            System.debug('EnhancedLetterhead not available: ' + e.getMessage());
        }
        
        Boolean currentUserLeng = UserInfo.getLanguage() == 'fr';
        if (isSentToPortal) {
            List<DomainSite> domainList = [SELECT Id, Domain.Domain, PathPrefix FROM DomainSite WHERE PathPrefix = '/NegoptimConnect' LIMIT 1];
            if (domainList.isEmpty()) return;
            DomainSite ds = domainList[0];
            domainURL = 'https://' + ds.Domain.Domain + ds.PathPrefix + '/legaldoc' + '/' + recordId;
        } else {
            domainURL = URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
        }
        // Org-wide email (don’t hard-crash if none exists)
        Id orgWideEmailId;
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE IsVerified = true LIMIT 1];
        if (!owea.isEmpty()) orgWideEmailId = owea[0].Id;        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        String emailBody = '';
        List<Task> taskList = new List<Task>();
        for (User recipient : userList) {
            if (!usersWithLabelMap.isEmpty()) {
                if (usersWithLabelMap.containsKey(recipient.Id)) {
                    Map<String, String> labelMap = usersWithLabelMap.get(recipient.Id);
                    body = labelMap.containsKey('body') ? labelMap.get('body') : body;
                    title = labelMap.containsKey('title') ? labelMap.get('title') : title;
                } else {
                    continue;
                }
            }
            Boolean userIsFrench = recipient.LanguageLocaleKey == 'fr';
            // greetingMsg = userIsFrench ? 'Cher ' : 'Dear ';
            greetingMsg = userIsFrench ? 'Bonjour ' : 'Hello ';
            header = userIsFrench ? headerFR : headerEN;
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            header = header.replace('src="/', 'src="' + baseUrl + '/');
            footer = footer.replace('src="/', 'src="' + baseUrl + '/');
            //closingMsg = userIsFrench ? 'Merci de votre collaboration,' : 'Thank you for your collaboration,';
            loginMsg = userIsFrench ? 'Merci de vous connecter à votre espace en cliquant ici' : 'Please log in to your account by clicking here';
            emailBody =  header +
                        '<p><br></p>' +
                        '<p>' +  greetingMsg + recipient.FirstName + ' ' + recipient.LastName + ',</p>' +
                        '<p><br></p>' +
                        '<p>' + body + '</p>' +
                        '<p>' +
                            '<a href="' + domainUrl + '" rel="noopener noreferrer" target="_blank">' +
                            '👉 ' + loginMsg +
                            '</a>' +
                        '</p>' +
                        '<p><br></p>' +
                        '<p><strong style="color: rgb(78, 194, 169);">' + (userIsFrench ? 'L’équipe Connect' : 'The Connect Team') +  '</strong></p>' +
                        '<p><br></p>' +
                        footer ;
            System.debug('>>>>>>>>>>>>>> emailBody :' + emailBody);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if(isSentToPortal){
                mail.setTargetObjectId(recipient.ContactId);
                mail.setSaveAsActivity(true);
                
            } else {
                mail.setTargetObjectId(recipient.Id);
                mail.setSaveAsActivity(false);
                Task t = new Task(
                    Subject = title,
                    WhatId = recordId,
                    Description = body,
                    Status = 'Completed'
                );
                taskList.add(t);
            }
            // mail.setToAddresses(new List<String>{recipient.Email});
            mail.htmlBody = emailBody;
            mail.setWhatId(recordId);
            mail.setSubject(title);
            mail.setOrgWideEmailAddressId(orgWideEmailId);
            emailList.add(mail);
        }
        try {
            sendEmail(emailList);
            insert taskList;
        } catch (Exception ex) {
            System.debug('Caught Exception: ' + ex.getMessage());
        }
    }

    public void sendEmail(List<String> toAddresses, String emailTemplateName, Id whatId, String customEmailSubject) {
        // check security on access EmailTemplate
        String[] emailTemplateFields = new String[] {
            SObjectType.EmailTemplate.fields.Id.Name,
            SObjectType.EmailTemplate.fields.DeveloperName.Name
        };
        Id emailTemplateId;
        if (String.isNotBlank(emailTemplateName)) {
            if (NegoptimHelper.checkAccessibility(EmailTemplate.SObjectType, emailTemplateFields)) {
                List<EmailTemplate> ets = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = :emailTemplateName LIMIT 1];
                if (!ets.isEmpty()) emailTemplateId = ets[0].Id;            }
        }
        Messaging.SingleEmailMessage mail;
        if (emailTemplateId != null) {
            mail = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), whatId);
        } else {
            mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(this.getFakeContactId());
        }
        mail.setSenderDisplayName('Negoptim By ULiT');
        mail.setReplyTo('no-reply@negoptim.com');
        mail.setToAddresses(toAddresses);
        try {
            if (whatId != null) mail.setWhatId(whatId);
            mail.setSaveAsActivity(true);
            mail.setSubject(customEmailSubject);
            sendEmail(mail);
        } catch (Exception ex) {
            System.debug('Caught Exception: ' + ex.getMessage());
        }
    }
    private void sendEmail(Messaging.SingleEmailMessage mail) {
        Integer used = Limits.getEmailInvocations();
        Integer emailLimit = Limits.getLimitEmailInvocations();

        if (used >= emailLimit) {
            System.debug('Email limit exceeded. Used=' + used + ' Limit=' + emailLimit);
            return;
        }
        try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                logEmailResults(results);
        } catch (System.EmailException ex) {
                System.debug('Caught Email Exception: ' + ex);
        }
    }

    private static void sendEmail(List<Messaging.SingleEmailMessage> emails) {
        if (emails == null || emails.isEmpty()) return;

        Integer used = Limits.getEmailInvocations();
        Integer emailLimit = Limits.getLimitEmailInvocations();

        if (used >= emailLimit) {
            System.debug('Email limit exceeded. Used=' + used + ' Limit=' + emailLimit);
            return;
        }
        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            logEmailResults(results);
        } catch (System.EmailException ex) {
            System.debug('Caught Email Exception: ' + ex);
        }
    }

    private static void logEmailResults(Messaging.SendEmailResult[] results) {
        if (results == null) return;
        for (Integer i = 0; i < results.size(); i++) {
            Messaging.SendEmailResult r = results[i];
            if (r != null && r.isSuccess()) {
                System.debug('Email[' + i + '] sent successfully.');
            } else if (r != null) {
                for (Messaging.SendEmailError err : r.getErrors()) {
                    System.debug('Email[' + i + '] failed: ' + err.getMessage());
                }
            }
        }
    }

    private Id getFakeContactId() {

        Contact fakeContact;
        id contactId;        
        String fakeContactName = '**DONT DELETE**';
        try {
            if (NegoptimHelper.checkAccessibility(Contact.SObjectType, new String[]{SObjectType.Contact.fields.Name.Name})) {
                fakeContact = [SELECT Id FROM Contact WHERE Name = :fakeContactName];
                contactId = fakeContact.Id;
                fakeContact.Email = UserInfo.getUserEmail();
            }
        } catch (Exception ex) {
            fakeContact = new Contact(FirstName='**DONT', LastName='DELETE**', Email=UserInfo.getUserEmail());
            contactId = fakeContact.Id;
        }
        // check security on Contact
        String[] contactFields = new String[] {
            SObjectType.Contact.fields.FirstName.Name,
            SObjectType.Contact.fields.LastName.Name,
            SObjectType.Contact.fields.Email.Name
        };
        if(NegoptimHelper.checkCreatibility(Contact.SObjectType, contactFields) && NegoptimHelper.checkUpdatibility(Contact.SObjectType, contactFields)) {
            upsert fakeContact;
        }
        return fakeContact.Id;
    }
}