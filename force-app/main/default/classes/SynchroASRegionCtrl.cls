/**
 * @author ULiT
 * @date 18/03/2025
 * Class to handle the functionalities of the screen synchro AS Region used in Assortment Matrix Actions
 **/
public class SynchroASRegionCtrl {
    
    @AuraEnabled
    public static string loadData(String assortmentId) {
        try {
            List<BUWrapper> wrapperList = new List<BUWrapper>();
            List<Assortment__c> currentAssortment = [SELECT Id, Name, RecordTypeId, Year__c, BusinessUnitSource__c,
                                                     BusinessUnitTarget__r.BusinessUnitCountryOrigin__c, BusinessUnitTarget__r.Format__c
                                                     FROM Assortment__c WHERE Id = :assortmentId];
            if (currentAssortment != null && !currentAssortment.isEmpty()) {
                List<BusinessUnit__c> BUs = [SELECt Id, Name, Format__c,
                                             (SELECT Id, Name
                                              FROM ASBusinessUnitTarget__r
                                              WHERE RecordTypeId = :currentAssortment.get(0).RecordTypeId
                                              AND Year__c = :currentAssortment.get(0).Year__c
                                              AND BusinessUnitSource__c = :currentAssortment.get(0).BusinessUnitSource__c)
                                             FROM BusinessUnit__c
                                             WHERE RecordType.DeveloperName = 'Region'
                                             AND BusinessUnitCountryOrigin__c = :currentAssortment.get(0).BusinessUnitTarget__r.BusinessUnitCountryOrigin__c
                                             AND Format__c = :currentAssortment.get(0).BusinessUnitTarget__r.Format__c
                                             AND Status__c <> 'Closed'];
                for (BusinessUnit__c bu : BUs) {
                    BUWrapper wrapper = new BUWrapper(bu, !bu.ASBusinessUnitTarget__r.isEmpty() ? bu.ASBusinessUnitTarget__r.get(0) : null);
                    wrapperList.add(wrapper);
                }
                return JSON.serialize(wrapperList);
            }
            return '';
        } catch (Exception e) {
            System.debug('Error load Data ::>>>' + e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class BUWrapper {
        public String linkBU {get;set;}
        public String buName {get;set;}
        public Assortment__c assortment {get;set;}
        public String linkAssortment {get;set;}
        
        public BUWrapper(BusinessUnit__c bu, Assortment__c assortment) {
            this.linkBU = '/' + bu.Id;
            this.buName = bu.Name;
            this.assortment = assortment;
            this.linkAssortment = assortment != null ? '/' + assortment.Id : '';
        }
    }

}