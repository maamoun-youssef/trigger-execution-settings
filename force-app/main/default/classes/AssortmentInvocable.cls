/**
 * Called from Flow to
 * Clone assortment details from Assortment Target
 * Valid for single clone
 * */
public class AssortmentInvocable {

    @InvocableMethod(label='Create Simulation ASD From Source Assortment' description='Create Simulation ASD From Source Assortment')
    public static void createSimulationDetailsFromSourceAssortment(List<AssortmentsWrapper> assortments) {
        AssortmentsWrapper itemWrapper = assortments[0];
        List<AssortmentDetail__c> assortmentDetailsToInsert = new List<AssortmentDetail__c>();
        if (itemWrapper.sourceId != null) {
            Map<String, Schema.SObjectField> fields = Schema.AssortmentDetail__c.sObjectType.getDescribe().fields.getMap();
            List<String> editableFields = new List<String>();
            for (Schema.SObjectField fieldRef : fields.values()) {
                Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
                if (fieldResult.isCreateable() || fieldResult.isUpdateable()) {
                    editableFields.add(fieldResult.getname());
                }
            }
            // get assortment details
            String query = 'SELECT Id, Assortment__r.RecordType.DeveloperName, ' + String.join(editableFields, ',');
            query += ' FROM AssortmentDetail__c';
            query += ' WHERE Version__c = NULL';
            query += ' AND RecordType.DeveloperName = \'Regular\'';
            query += ' AND Assortment__c = \'' + itemWrapper.sourceId +'\'';
            String[] assortmentDetailAccessFields = new String[] {
                SObjectType.AssortmentDetail__c.fields.Id.Name
            };
            Assortment__c sourceAssortment = [SELECT Id, Year__c, RecordType.DeveloperName FROM Assortment__c WHERE Id = :itemWrapper.sourceId];
            Assortment__c createdAssortment = [SELECT Id, Year__c, RecordType.DeveloperName, BDate__c, AssortmentNegotiationRef__c, AssortmentChannelBudgetRef__c, AssortmentTargetRef__c FROM Assortment__c WHERE Id = :itemWrapper.recordId];
            for (String str : editableFields) {
                if (!assortmentDetailAccessFields.contains(str)) {
                    assortmentDetailAccessFields.add(str);
                }
            }
            if (NegoptimHelper.checkAccessibility(AssortmentDetail__c.SObjectType, assortmentDetailAccessFields)) {
                List<AssortmentDetail__c> assortmentDetails = Database.query(query);
                for (AssortmentDetail__c item : assortmentDetails) {
                    // check create permission before creating a new record
                    if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, editableFields)) {
                        AssortmentDetail__c newAssortmentDetail = item.clone(false, true, true, false);
						newAssortmentDetail.Hierarchy__c = null;
                        newAssortmentDetail.Assortment__c = itemWrapper.recordId;
                        newAssortmentDetail.AssortmentDetailLHistory__c = null;
                        newAssortmentDetail.ExtId__c = null;
                        newAssortmentDetail.Status__c = itemWrapper.statusASD != null && itemWrapper.statusASD != '' ? itemWrapper.statusASD : 'InPreparation';
                        newAssortmentDetail.ProductLifeStatusAss__c = item.ProductLifeStatusAss__c;
                        if(createdAssortment.Year__c > sourceAssortment.Year__c) {
                            newAssortmentDetail.StartDate__c = createdAssortment.BDate__c;
                        }
                        if (createdAssortment.AssortmentNegotiationRef__c != null) {
                            if (/*(item.Assortment__r.RecordType.DeveloperName == 'Target') || */(sourceAssortment.Year__c != createdAssortment.Year__c && sourceAssortment.RecordType.DeveloperName == 'Negotiation' && createdAssortment.RecordType.DeveloperName == 'Simulation')) {
                                newAssortmentDetail.AssortmentDetailNegotiationRef__c = item.Id;
                            } else {
                                newAssortmentDetail.AssortmentDetailNegotiationRef__c = item.AssortmentDetailNegotiationRef__c;
                            }
                        } else {
                            newAssortmentDetail.AssortmentDetailNegotiationRef__c= null;
                        }
                        if (createdAssortment.AssortmentTargetRef__c != null) {
                            newAssortmentDetail.AssortmentDetailTargetRef__c = item.Assortment__r.RecordType.DeveloperName == 'Target' ? item.Id : item.AssortmentDetailTargetRef__c;
                        } else {
                            newAssortmentDetail.AssortmentDetailTargetRef__c = null;
                        }
                        if (createdAssortment.AssortmentChannelBudgetRef__c != null) {
                            newAssortmentDetail.AssortmentDetailBudgetRef__c = item.AssortmentDetailBudgetRef__c;
                        } else {
                            newAssortmentDetail.AssortmentDetailBudgetRef__c = null;
                        }
                        if (item.ProductLifeStatusAss__c == null || item.ProductLifeStatusAss__c == 'Complement' || item.ProductLifeStatusAss__c == 'Opportunity'
                            || (item.StartDate__c != null && createdAssortment.BDate__c <= item.StartDate__c))
                        {
                            newAssortmentDetail.ProductLifeStatusAss__c = item.ProductLifeStatusAss__c;
                        } else if (item.StartDate__c == null || createdAssortment.BDate__c > item.StartDate__c) {
                            if (item.ProductLifeStatusAss__c != 'Delist') {
                                newAssortmentDetail.ProductLifeStatusAss__c = 'Keep';
                            } else {
                                newAssortmentDetail.ProductLifeStatusAss__c = null;
                            }
                        }
                        assortmentDetailsToInsert.add(newAssortmentDetail);
                    }
                }
                if (!assortmentDetailsToInsert.isEmpty()) {
                    if (NegoptimHelper.checkCreatibility(AssortmentDetail__c.SObjectType, editableFields)) {
                        Database.SaveResult[] results = Database.insert(assortmentDetailsToInsert, false);
                        String errorMessages = '';
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            AssortmentDetail__c record = assortmentDetailsToInsert.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = String.valueOf(record);
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessages += ('\nProduct2 Id [' + record.Product__c + '] ' + err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage());
                                    System.debug(err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '\n');
                                }
                            }
                        }
                        if (String.isNotBlank(errorMessages)) {
                            throw new HandledException(errorMessages);
                        }
                    }
                }
            }
        }
    }

    public class AssortmentsWrapper {
        @InvocableVariable(label='record Id' description='Id of the Assortment' required=true)
        public Id recordId;
        @InvocableVariable(label='Source Id' description='Id of the Assortment when I want to get ASD')
        public Id sourceId;
        @InvocableVariable(label='ASDStatus' description='Status of ASD')
        public String statusASD;
    }

}