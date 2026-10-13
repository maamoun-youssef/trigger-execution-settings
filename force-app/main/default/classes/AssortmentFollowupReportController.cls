/**
 * @author ULiT
 * @date 16-05-2024
 * @description: Controller class to the LWC AssortmentFollowupSummaryReport && AssortmentFollowupReport
 * */
public with sharing class AssortmentFollowupReportController {

    //Load data for the screen assortmentFollowupSummaryReport
    @AuraEnabled
    public static string loadData(Integer year, Integer pageNumber) {
        try {
            List<String> asdFields = new List<String>();
            List<String> asdDVFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_TargetGap__c.Name
            };
            List<String> asdRefFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseTarget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_TargetGap__c.Name
            };
            // pink part
            List<String> asdQtyFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.QtyBudget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyTarget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego_TargetGap__c.Name
            };
            // pink part
            List<String> asdKVolumeFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.KVolumeBudget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeTarget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_TargetGap__c.Name
            };
            // blue part
            List<String> asdSellInFields = new List<String> {
                // SObjectType.AssortmentDetail__c.fields.SellinBudget_NegoL4LP1Gap__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SellinTarget_NegoL4LP1Gap__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SellInNego_P1__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SellinNego_TargetGap.Name
            };
            // sellOutPart doest exist
            List<String> asdSellOutFields = new List<String> {
                // SObjectType.AssortmentDetail__c.fields.SelloutBudget_NegoL4LP1Gap__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SelloutTarget_NegoL4LP1Gap__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SelloutNego_NegoL4LP1Gap__c.Name,
                // SObjectType.AssortmentDetail__c.fields.SelloutNego_TargetGap__c.Name
            };
            // GP
            List<String> asdGPFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.GPBudget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPTarget_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPNego_TargetGap__c.Name
            };

            String asdQuery = 'SELECT Id, Assortment__r.OnTop__c, Assortment__r.RecordType.DeveloperName,';
            asdQuery += ' Assortment__r.BusinessUnitTarget__c, Assortment__r.BusinessUnitTarget__r.Name, Assortment__r.BusinessUnitSource__c, Assortment__r.BusinessUnitSource__r.Name, ';
            asdQuery += String.join(asdDVFields, ', '); //to add condition from assortment settings
            asdFields.addAll(asdDVFields);
            // if (asdDVFields.size() != 0) {
            //     asdQuery += ', ';
            //     asdQuery += String.join(asdDVFields, ', ');
            //     asdFields.addAll(asdDVFields);
            // }
             if (!asdRefFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdRefFields, ', ');
                asdFields.addAll(asdRefFields);
            }
            if (!asdQtyFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdQtyFields, ', ');
                asdFields.addAll(asdQtyFields);
            }
            if (!asdKVolumeFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdKVolumeFields, ', ');
                asdFields.addAll(asdKVolumeFields);
            }
            if (!asdSellInFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdSellInFields, ', ');
                asdFields.addAll(asdSellInFields);
            }
            if (!asdSellOutFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdSellOutFields, ', ');
                asdFields.addAll(asdSellOutFields);
            }
            if (!asdGPFields.isEmpty()) {
                asdQuery += ', ';
                asdQuery += String.join(asdGPFields, ', ');
                asdFields.addAll(asdGPFields);
            }
            asdQuery += ' FROM AssortmentDetail__c';
            asdQuery += ' WHERE Assortment__r.RecordType.DeveloperName = \'ChannelBudget\'';
            asdQuery += ' AND Assortment__r.Year__c = ' + year ;
            // asdQuery += ' AND Assortment__r.BusinessUnitSource__c = ' + ;
            // asdQuery += ' GROUP BY Assortment__r.BusinessUnitTarget__c';

            System.debug('asdQuery: ' + asdQuery);
            ApexPages.StandardSetController asdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(asdQuery));
            system.debug('pageNumber >>> ' + pageNumber);
            asdSetCtrl.setPageSize(1000);
            asdSetCtrl.setPageNumber(Integer.valueOf(pageNumber));
            List<AssortmentDetail__c> assortmentDetailsList = asdSetCtrl.getRecords();
            system.debug('assortmentDetailsList >>> ' + assortmentDetailsList.size());
            if(assortmentDetailsList.size() == 0)
                return '';
            return JSON.serialize(new ResultsASDWrapper(assortmentDetailsList, asdSetCtrl.getResultSize(), asdFields));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    //init data for the screen assortmentFollowupReport
    @AuraEnabled
    public static string initData(Integer year, Id channelId) {
        try {
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            List<ScopeWrapper> selectedScopes = new List<ScopeWrapper>();
            Set<String> productFieldsName = new Set<String>();
            Map<String, Schema.SObjectField> productFieldsMap = Schema.getGlobalDescribe().get('Product2').getDescribe().fields.getMap();
            Set<Integer> levels = new Set<Integer>();
            
            List<AssortmentSettings.ScopeWrapper> scopes = String.isNotBlank(assortSettings.scopeSettings) ? (List<AssortmentSettings.ScopeWrapper>) JSON.deserialize(assortSettings.scopeSettings, List<AssortmentSettings.ScopeWrapper>.class) : new List<AssortmentSettings.ScopeWrapper>();
            for (AssortmentSettings.ScopeWrapper scope : scopes) {
                if (scope.Name != null && scope.label != null && productFieldsMap.containsKey(scope.Name)) {
                    String fieldName = scope.Name;
                    productFieldsName.add(fieldName);
                    if (productFieldsMap.get(scope.Name).getDescribe().getType() == DisplayType.Reference) {
                        if (productFieldsMap.get(scope.Name).getDescribe().getReferenceTo().get(0).getDescribe().getName() == SObjectType.Hierarchy__c.Name) {
                            if (scope.level != null) {
                                fieldName = scope.Name.replace('__c', '__r') + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name;
                                levels.add(scope.level);
                            }
                        } else {
                            fieldName = scope.Name.replace('__c', '__r') + '.Name';
                        }
                        productFieldsName.add(fieldName);
                    }
                    selectedScopes.add(new ScopeWrapper(fieldName, isValidLabel(scope.label) ? NegoptimLabels.getCustomLabel(scope.label.remove('{').remove('}'), scope.label) : scope.label, scope.level));
                }  
            }
            if (selectedScopes.isEmpty()) {
                selectedScopes = new List<ScopeWrapper> {
                    new ScopeWrapper(SObjectType.Product2.fields.Brand_Parent__c.Name, SObjectType.Product2.fields.Brand_Parent__c.label, null),
                    new ScopeWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Brand__c.Name) + '.' + SObjectType.Brand__c.fields.Name.Name, SObjectType.Product2.fields.Brand__c.label, null),
                    new ScopeWrapper(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name, SObjectType.Product2.fields.Hierarchy__c.label, null)
                };
                productFieldsName.add(SObjectType.Product2.fields.Brand_Parent__c.Name);
                productFieldsName.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Brand__c.Name) + '.' + SObjectType.Brand__c.fields.Name.Name);  
                productFieldsName.add(NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name);  
            }
            // Product Fields
            List<String> productFields = new List<String> {
                SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.ProductCode.Name,
                SObjectType.Product2.fields.GTIN__c.Name
            };
            // Budget Fields
            List<String> dvrefBudgetFields = new List<String> {
               // SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_TargetGap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_TargetGap__c.Name
            };
            List<String> qtyvolumeBudgetFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeBudget__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego_TargetGap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_TargetGap__c.Name
            };
            List<String> sellgpBudgetFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.GPNego_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPBudget__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPNego__c.Name,
                //SObjectType.AssortmentDetail__c.fields.SelloutNego_NegoL4LP1Gap__c.Name,
                //SObjectType.AssortmentDetail__c.fields.SelloutNego_TargetGap__c.Name,
                //SObjectType.AssortmentDetail__c.fields.GPNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPNego_TargetGap__c.Name
            };
            // Target Fields
            List<String> dvrefTargetFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego_TargetGap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego_TargetGap__c.Name
            };
            List<String> qtyvolumeTargetFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.QtyNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.QtyNego_TargetGap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_NegoP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.KVolumeNego_TargetGap__c.Name
            };
            List<String> sellgptargetFields = new List<String> {
                //SObjectType.AssortmentDetail__c.fields.SelloutNego_NegoL4LP1Gap__c.Name,
                //SObjectType.AssortmentDetail__c.fields.SelloutNego_TargetGap__c.Name,
                //SObjectType.AssortmentDetail__c.fields.GPNego_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.GPNego_TargetGap__c.Name
            };
            String asdQuery = 'SELECT Id, BusinessUnitCluster__r.Name, Assortment__r.OnTop__c, Assortment__r.RecordType.DeveloperName,';
            asdQuery += ' Assortment__r.BusinessUnitTarget__c, Assortment__r.BusinessUnitTarget__r.Name, Assortment__r.BusinessUnitSource__c, Assortment__r.BusinessUnitSource__r.Name, ';
            asdQuery += String.join(dvrefBudgetFields, ', '); //to add condition from assortment settings
            asdQuery += ', ' + String.join(qtyvolumeBudgetFields, ', ');
            asdQuery += ', ' + String.join(sellgpBudgetFields, ', ');
            asdQuery += ', Product__r.' + String.join(productFieldsName, ', Product__r.');
            asdQuery += ', Product__r.ProductCode, Product__r.Name, Product__r.GTIN__c';
            asdQuery += ' FROM AssortmentDetail__c';
            asdQuery += ' WHERE ((Assortment__r.RecordType.DeveloperName = \'ChannelBudget\' AND Assortment__r.BusinessUnitTarget__c = \'' + channelId + '\')';
            asdQuery += ' OR (Assortment__r.RecordType.DeveloperName = \'Target\' AND Assortment__r.BusinessUnitSource__c = \'' + channelId + '\'))';
            asdQuery += ' AND Assortment__r.Year__c = ' + year ;
            List<Hierarchy__c> heList = new List<Hierarchy__c>();
            if (levels.size() > 0) {
                heList = [SELECT Name, Path__c FROM Hierarchy__c WHERE level__c IN :levels];
            }
            return JSON.serialize(new ResultsMainrapper(asdQuery, heList, productFields, dvrefBudgetFields, qtyvolumeBudgetFields, sellgpBudgetFields, dvrefTargetFields, qtyvolumeTargetFields, sellgptargetFields, selectedScopes));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    //Load data for the screen assortmentFollowupReport
    @AuraEnabled
    public static string loadTargetData(String asdQuery, Integer pageNumber) {
        try {
            ApexPages.StandardSetController asdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(asdQuery));
            asdSetCtrl.setPageSize(1000);
            asdSetCtrl.setPageNumber(Integer.valueOf(pageNumber));
            List<AssortmentDetail__c> assortmentDetailsList = asdSetCtrl.getRecords();
            if(assortmentDetailsList.size() == 0)
                return '';
            return JSON.serialize(new ResultsASDWrapper(assortmentDetailsList, asdSetCtrl.getResultSize()));
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Boolean isValidLabel(String input) {
        String regExp = '^\\{.*\\}$';
        Pattern regexPattern = Pattern.compile(regExp);
        Matcher matcher = regexPattern.matcher(input);
        return matcher.matches();
    }

    public class ResultsMainrapper {
        public String asdQuery {get;set;}
        public List<Hierarchy__c> heList {get;set;}
        public List<String> budgetFields {get; set;}
        public List<String> productFields {get; set;}
        // DV / #Ref
        public List<String> dvrefBudgetFields {get; set;}
        public List<String> dvrefTargetFields {get; set;}
        //Qty / KVolume
        public List<String> qtyvolumeBudgetFields {get; set;}
        public List<String> qtyvolumeTargetFields {get; set;}
        //Sell / GP
        public List<String> sellgpBudgetFields {get; set;}
        public List<String> sellgpTargetFields {get; set;}
        public List<ScopeWrapper> selectedScopes {get; set;}
        public AssortmentSettings AssortmentSettings {get; set;}
        public Map<String, List<String>> budgetFieldsMap {get; set;}
        public String prefix {get; set;}
        
        public ResultsMainrapper() {}

        public ResultsMainrapper(String asdQuery, List<Hierarchy__c> heList, List<String> productFields, List<String> dvrefBudgetFields, List<String> qtyvolumeBudgetFields, List<String> sellgpBudgetFields, List<String> dvrefTargetFields, List<String> qtyvolumeTargetFields, List<String> sellgpTargetFields, List<ScopeWrapper> selectedScopes) {
            this.asdQuery = asdQuery;
            this.heList = heList;
            this.productFields = productFields;
            this.dvrefBudgetFields = dvrefBudgetFields;
            this.qtyvolumeBudgetFields = qtyvolumeBudgetFields;
            this.sellgpBudgetFields = sellgpBudgetFields;
            this.dvrefTargetFields = dvrefTargetFields;
            this.qtyvolumeTargetFields = qtyvolumeTargetFields;
            this.sellgpTargetFields = sellgpTargetFields;
            this.selectedScopes = selectedScopes;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    
    public class ResultsASDWrapper {
        public List<AssortmentDetail__c> asdList {get;set;}
        public Integer totalSize {get;set;}
        public List<String> budgetFields {get; set;}
        public String prefix {get; set;}

        public ResultsASDWrapper() {}
        
        public ResultsASDWrapper(List<AssortmentDetail__c> asdList, Integer totalSize, List<String> budgetFields) {
            this.asdList = asdList;
            this.totalSize = totalSize;
            this.budgetFields = budgetFields;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
        public ResultsASDWrapper(List<AssortmentDetail__c> asdList, Integer totalSize) {
            this.asdList = asdList;
            this.totalSize = totalSize;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    
    public class ScopeWrapper {
        public String Name {get;set;}
        public String label {get;set;}
        public Integer level {get;set;}
        
        public ScopeWrapper(String Name, String label, Integer level) {
            this.Name = Name;
            this.label = label;
            this.level = level;
        }
    }
}