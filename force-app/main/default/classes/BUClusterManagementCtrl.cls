/**
 * @author ULiT
 * @date 17/05/2024
 * Class to handle the functionalities of the screen BU Cluster Management
 **/
public with sharing class BUClusterManagementCtrl {
    private static List<String> buFields = new List<String> {
            SObjectType.BusinessUnit__c.fields.Code__c.Name,
            SObjectType.BusinessUnit__c.fields.Name.Name,
            SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name,
            SObjectType.BusinessUnit__c.fields.Hierarchy__c.Name,
            SObjectType.BusinessUnit__c.fields.ClientCategory__c.Name,
            SObjectType.BusinessUnit__c.fields.Status__c.Name,
            SObjectType.BusinessUnit__c.fields.OpeningDate__c.Name,
            SObjectType.BusinessUnit__c.fields.ClosingDate__c.Name,
            SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP2__c.Name,
            SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP1__c.Name,
            SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
            SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP2__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM2__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM3__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM4__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM5__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM6__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM7__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM8__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM9__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM10__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM11__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionInnovRiseM12__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM2__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM3__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM4__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM5__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM6__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM7__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM8__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM9__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM10__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM11__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionSwitchRiseM12__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM1__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM2__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM3__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM4__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM5__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM6__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM7__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM8__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM9__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM10__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM11__c.Name,
            SObjectType.BusinessUnit__c.fields.WeightedDistributionStopRiseM12__c.Name
        };
    @AuraEnabled
    public static string loadCountries(String recordId, Integer pageNumber, String filterWrapper) {
        try {
            Id bannerId;
        
            FilterWrapper myFilter = (FilterWrapper)JSON.deserialize(filterWrapper, FilterWrapper.class);
            String buQuery = 'SELECT Id';
            buQuery += ' FROM BusinessUnit__c';
            buQuery += ' WHERE RecordType.DeveloperName IN (\'Country\')';
            if (String.isNotBlank(recordId)) {
                Id recId = Id.valueOf(recordId);
                String sObjName = recId.getSObjectType().getDescribe().getName();
                if (sObjName == SObjectType.BusinessUnit__c.Name) {
                    BusinessUnit__c bu = [SELECT Id, RecordType.DeveloperName, BusinessUnitCountryOrigin__c
                                          FROM BusinessUnit__c
                                          WHERE Id = :recId
                                          LIMIT 1];
                    if (bu.RecordType.DeveloperName == 'Country') {
                        buQuery += ' AND Id = \'' + bu.Id + '\'';
                    } else if (bu.RecordType.DeveloperName == 'Banner' && bu.BusinessUnitCountryOrigin__c != null) {
                        bannerId = recordId;
                        buQuery += ' AND Id = \'' + bu.BusinessUnitCountryOrigin__c + '\'';
                    } else {
                        buQuery += ' AND Id = NULL';
                    }
                } else if (sObjName == SObjectType.Supplier__c.Name) {
                    buQuery += ' AND Supplier__c = \'' + recordId + '\'';
                }
            }
            if (String.isNotBlank(myFilter.countryParam)) {
                buQuery += ' AND Id = \'' + myFilter.countryParam + '\'';
            }
            buQuery += ' ORDER BY Name';
            System.debug('buQuery: ' + buQuery);
            List<BusinessUnit__c> buList = new List<BusinessUnit__c>();
            ApexPages.StandardSetController buStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(buQuery));
            buStdSetCtrl.setPageSize(recordId != null && recordId != '' ? 100 : 5);
            buStdSetCtrl.setPageNumber(Integer.valueOf(pageNumber));
            buList = buStdSetCtrl.getRecords();
            return JSON.serialize(new ResultsWrapper(buList, buStdSetCtrl.getResultSize(), buFields, bannerId));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string loadData(String bannerId, List<Id> countryIds, String filterWrapper) {
        try {
            FilterWrapper myFilter = (FilterWrapper) JSON.deserialize(filterWrapper, FilterWrapper.class);
            String buQuery = 'SELECT Id, RecordType.DeveloperName, BusinessUnitCountryOrigin__r.RecordType.DeveloperName, Supplier__c, Supplier__r.Name, Hierarchy__r.Name, BusinessUnitCountryOrigin__c, BusinessUnitCountryOrigin__r.Name,';
            buQuery += String.join(buFields, ', ');
            if(String.isNotBlank(myFilter.categoryParam) || (String.isNotBlank(myFilter.clientCategParam)) || (String.isNotBlank(myFilter.StratParam))) {
                buQuery += ', (SELECT Id FROM BUBusinessUnitCountryOrigin__r WHERE RecordType.DeveloperName = \'AssortmentCluster\'';
                if (String.isNotBlank(myFilter.categoryParam)) buQuery += ' AND Hierarchy__c = \'' + String.escapeSingleQuotes(myFilter.categoryParam) + '\'';
                if (String.isNotBlank(myFilter.clientCategParam)) buQuery += ' AND ClientCategory__c LIKE \'%' + String.escapeSingleQuotes(myFilter.clientCategParam) + '%\'';
                if (String.isNotBlank(myFilter.StratParam)) buQuery += ' AND AssortmentStrat__c = \'' + String.escapeSingleQuotes(myFilter.StratParam) + '\'';
                buQuery += ')';
            }
            buQuery += ' FROM BusinessUnit__c';
            buQuery += ' WHERE RecordType.DeveloperName = \'Banner\'';
            System.debug('BannerId>>>> ' + bannerId);
            if (String.isNotBlank(bannerId)) {
                buQuery += ' AND Id = \'' + bannerId + '\'';
            } else {
                buQuery += ' AND BusinessUnitCountryOrigin__c IN (\'' + String.join(countryIds, '\', \'') + '\')';
            }
            if (String.isNotBlank(myFilter.bannerParam)) {
                buQuery += ' AND Id = \'' + myFilter.bannerParam + '\'';
            }
            buQuery += ' ORDER BY Name';
            System.debug('loadData (banners) >> ' + buQuery);
            return JSON.serialize(Database.query(buQuery));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string loadClusters(String bannerId, String filterWrapper) {
        try {
            FilterWrapper myFilter = (FilterWrapper) JSON.deserialize(filterWrapper, FilterWrapper.class);
            String buQuery = 'SELECT Id, RecordType.DeveloperName, BusinessUnitCountryOrigin__r.RecordType.DeveloperName, Supplier__c, Supplier__r.Name, Hierarchy__r.Name, BusinessUnitCountryOrigin__c, BusinessUnitCountryOrigin__r.Name,';
            buQuery += String.join(buFields, ', ');
            buQuery += ' FROM BusinessUnit__c';
            buQuery += ' WHERE RecordType.DeveloperName = \'AssortmentCluster\'';
            buQuery += ' AND BusinessUnitCountryOrigin__c = \'' + bannerId + '\'';
            if (String.isNotBlank(myFilter.categoryParam)) {
                buQuery += ' AND Hierarchy__c = \'' + myFilter.categoryParam + '\'';
            }
            if (String.isNotBlank(myFilter.clientCategParam)) {
                buQuery += ' AND ClientCategory__c LIKE \'%' + myFilter.clientCategParam + '%\'';
            }
            if (String.isNotBlank(myFilter.StratParam)) {
                buQuery += ' AND AssortmentStrat__c = \'' + myFilter.StratParam + '\'';
            }
            buQuery += ' ORDER BY Hierarchy__r.Name, ClientCategory__c, AssortmentStrat__c, Name';
            System.debug('loadClusters >> ' + buQuery);
            return JSON.serialize(Database.query(buQuery));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string insertCluster(String clusterListJSON) {
        try {
            List<BusinessUnit__c> clusterList = (List<BusinessUnit__c>) JSON.deserialize(clusterListJSON, List<BusinessUnit__c>.class);
            if (!clusterList.isEmpty()) {
                insert clusterList;
            }
            return '';
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveClusters(String clustersToSave) {
        try {
            List<BusinessUnit__c> clustersToUpdate = (List<BusinessUnit__c>) JSON.deserialize(clustersToSave, List<BusinessUnit__c>.class);
            System.debug(clustersToUpdate);
            if (!clustersToUpdate.isEmpty()) { 
                upsert clustersToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error save clusters ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResultsWrapper {
        public String prefix {get;set;}
        public List<BusinessUnit__c> countryList {get;set;}
        public List<String> BuFields {get; set;}
        public Integer totalNumbOfRecords {get; set;}
        public String assortmentClusterRT {get; set;}
        public String local {get; set;}
        public Id bannerId {get; set;}

        public ResultsWrapper() {
            this.assortmentClusterRT = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'AssortmentCluster');
        }

        public ResultsWrapper(List<BusinessUnit__c> countryList, Integer totalNumbOfRecords, List<String> buFields, Id bannerId) {
            this.countryList = countryList;
            this.totalNumbOfRecords = totalNumbOfRecords;
            this.BuFields = buFields;
            this.assortmentClusterRT = NegoptimHelper.getObjectRecordTypeId(BusinessUnit__c.SObjectType, 'AssortmentCluster');
            this.local = UserInfo.getLocale();
            this.bannerId = bannerId;
            this.prefix = negoptimHelper.getPackagePrefix(true);
        }
    }
    public class FilterWrapper {
        public String countryParam {get;set;}
        public String bannerParam {get;set;}
        public String categoryParam {get;set;}
        public String clientCategParam {get;set;}
        public String StratParam {get;set;}

        public FilterWrapper(String countryParam, String bannerParam, String categoryParam, String clientCategParam, String StratParam) {
            this.countryParam = countryParam;
            this.bannerParam = bannerParam;
            this.categoryParam = categoryParam;
            this.clientCategParam = clientCategParam;
            this.StratParam = StratParam;
        }

    }
}