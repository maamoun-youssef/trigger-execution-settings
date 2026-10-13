/**
 * @author ULiT
 * @date 03/06/2024
 * Class to handle the functionalities of the screen assortment product Selection used in Assortment Channel Budget and Assortment Matrix screens
 **/
public with sharing class LinkAssortmentToContractCtrl {

    @AuraEnabled
    public static string loadData(String assortmentId) {
        try {
            List<Assortment__c> currentAssortment = [SELECT Id, Name, Contract__c, PWF__c, Year__c,
                                                               BusinessUnitTarget__c, BusinessUnitTarget__r.BusinessUnitCountryOrigin__c
                                                               FROM Assortment__c WHERE Id = :assortmentId];
            if (currentAssortment != null && !currentAssortment.isEmpty()) {
                List<Assortment_BU__c> PWFs = [SELECT Id, Name, Contract__c, Contract__r.Name, Contract__r.Contract_BDate__c,
                                                         Contract__r.Contract_EDate__c, Contract__r.Status__c,
                                                         toLabel(Contract__r.RecordType.Name)
                                                         FROM Assortment_BU__c
                                                         WHERE Contract__c <> NULL
                                                         AND Contract__r.Reference_Year__c = :currentAssortment.get(0).Year__c
                                                         AND Contract__r.RecordType.DeveloperName IN ('To_Be_Signed', 'Signed', 'Simulation')
                                                         AND (Contract__r.BusinessUnitContract__c = :currentAssortment.get(0).BusinessUnitTarget__c OR Contract__r.BusinessUnitContract__c = :currentAssortment.get(0).BusinessUnitTarget__r.BusinessUnitCountryOrigin__c)];
                List<FieldWrapper> displayedFields = new List<FieldWrapper>();
                displayedFields.add(new FieldWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Name.Name, SObjectType.Contract__c.fields.Name.Label));
                displayedFields.add(new FieldWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.RecordType.Name', System.Label.LBL_Record_Type));
                displayedFields.add(new FieldWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Status__c.Name, SObjectType.Contract__c.fields.Status__c.Label));
                displayedFields.add(new FieldWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_BDate__c.Name, SObjectType.Contract__c.fields.Contract_BDate__c.Label));
                displayedFields.add(new FieldWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment_BU__c.fields.Contract__c.Name) + '.' + SObjectType.Contract__c.fields.Contract_EDate__c.Name, SObjectType.Contract__c.fields.Contract_EDate__c.Label));
                displayedFields.add(new FieldWrapper(SObjectType.Assortment_BU__c.fields.Name.Name, SObjectType.Assortment_BU__c.fields.Name.Label));
                return JSON.serialize(new MainWrapper(currentAssortment.get(0), PWFs, displayedFields));
            }
            return '';
        } catch (Exception e) {
            System.debug('Error load Data ::>>>' + e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string updateAssortment(String assortmentId, Id selectedContract, Id selectedPWF) {
        String errorMessages = '';
        Assortment__c assortment = new Assortment__c(Id = assortmentId, Contract__c = selectedContract, PWF__c = selectedPWF);
        Database.SaveResult result = Database.update(assortment);
        if (!result.isSuccess()) {
            Database.Error[] errors = result.getErrors();
            for (Database.Error err : errors) {
                errorMessages += err.getMessage() + '\n';
            }
        }
        return errorMessages;
    }
    
    @AuraEnabled
    public static void executeSynchroPWF(String assortmentId) {
        Database.executeBatch(new APWToASDBatch(LinkAssortmentToContractCtrl.class.getName(), new Set<Id>{assortmentId}));
    }
    
    public class MainWrapper {
        public Assortment__c currentAssortment {get;set;}
        public List<Assortment_BU__c> PWFs {get;set;}
        public List<FieldWrapper> displayedFields {get;set;}
        
        public MainWrapper() {}
        
        public MainWrapper(Assortment__c currentAssortment, List<Assortment_BU__c> PWFs, List<FieldWrapper> displayedFields) {
            this.currentAssortment = currentAssortment;
            this.PWFs = PWFs;
            this.displayedFields = displayedFields;
        }
    }
    
    public class FieldWrapper {
        String fieldName {get;set;}
        String fieldLabel {get;set;}
        
        public FieldWrapper(String fieldName, String fieldLabel) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
        }
    }
}