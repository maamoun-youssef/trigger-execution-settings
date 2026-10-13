/**
 * @author ULiT
 * @date 13/05/2024
 * Class to handle the functionalities of the screen Assortment Channel Budget for the Assortment Object with RT = 'ChannelBudget'
 **/
public with sharing class AssortmentChannelBudgetCtrl {
    private static List<String> budgetAssAPIFields = new List<String> {
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name
    };
    private static Map<String, String> budgetASDFields = new Map<String, String> {
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name => System.Label.LBL_WDChannelBaseNegoL4L_P1,
        SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name => System.Label.LBL_WDChannelBasePanel_P1,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name => System.Label.LBL_WDChannelBaseBudget,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseBudget_NegoL4LP1Gap,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name => System.Label.LBL_PNChannelBaseBudget_NegoL4LP1Gap,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name => System.Label.LBL_WDChannelBaseTarget,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseTarget_NegoL4LP1Gap
    };
    private static List<String> negoAssAPIFields = new List<String> {
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name
    };
    private static Map<String, String> negoASDFields = new Map<String, String> {
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name => System.Label.LBL_WDChannelBaseNegoL4L_P1,
        SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name => SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Label,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name => System.Label.LBL_WDChannelBaseTarget,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseTarget_NegoL4LP1Gap
    };
    private static Set<String> fieldsToSumSet = new Set<String> {
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name
    };
    private static List<String> staticBannerFieldsList = new List<String> {
        SObjectType.AssortmentDetail__c.fields.Id.Name,
        SObjectType.AssortmentDetail__c.fields.Product__c.Name,
        SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + 'Id',
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + 'recordType.developerName',
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Hierarchy__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Product_EAN__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.IsInnovation__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Market_End_of_Life_Date__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Market_Introduction_Date__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Total_Weight__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Product2.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name
    };
    private static List<String> assortmentBUFields = new List<String> {
        SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
        SObjectType.Assortment__c.fields.Hierarchy__c.Name,
        SObjectType.Assortment__c.fields.Status__c.Name,
        SObjectType.Assortment__c.fields.Year__c.Name,
        SObjectType.Assortment__c.fields.RecordTypeId.Name
    };
    private static List<String> orgaBUFields = new List<String> {
        SObjectType.BusinessUnit__c.fields.Name.Name,
        SObjectType.BusinessUnit__c.fields.LayerBudgetDisplay__c.Name,
        SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
        SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name,
        SObjectType.BusinessUnit__c.fields.Format__c.Name
    };
    @AuraEnabled
	public static String processRestForExcel(String currentAssortmentJSON, String queryType, List<String> negoAssIds, String restURL) {
        String query = '';
        if (String.isBlank(restURL)) {
            AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
            String metadataDeveloperName = assortSettings.assortmentMatrixBudget;
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, null, null, SObjectType.AssortmentDetail__c.Name, null, String.join(staticBannerFieldsList, ','), metadataDeveloperName);
            Assortment__c currentAssortment = (Assortment__c) JSON.deserialize(currentAssortmentJSON, Assortment__c.class);
            if (String.isBlank(currentAssortment.Id)) {
                return DataLoaderHelper.processRestForExcel(query, restURL, 'No-Id', SObjectType.AssortmentDetail__c.Name);
            }
            if (queryType == 'budget') {
                query = buildBudgetAssQuery(currentAssortment.Id, gridSettingsManager.ALL_FIELDS, null);
            } else if (queryType == 'nego') {
                query = buildNegoAssQuery(negoAssIds, null);
                System.debug('query: ' + query);
            } else if (queryType == 'target') {
                query = buildTargetAssortmentsQuery(currentAssortment, null);
            }
        }
        return DataLoaderHelper.processRestForExcel(query, restURL, null, SObjectType.AssortmentDetail__c.Name);
	}
    @AuraEnabled
    public static string initData(String assortmentId) {
        List<BusinessUnit__c> assTargetList = new List<BusinessUnit__c>();
        Set<String> negoAssIds = new Set<String>();
        // load AssortmentSettings
        AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
        String metadataDeveloperName = assortSettings.assortmentMatrixBudget;
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, null, null, SObjectType.AssortmentDetail__c.Name, null, String.join(staticBannerFieldsList, ','), metadataDeveloperName);
        System.debug('assortmentId: ' + assortmentId);
        Assortment__c currentAss = [SELECT Id, Name, LongName__c, BusinessUnitTarget__c, BusinessUnitTarget__r.Name,
                                    Hierarchy__c, Hierarchy__r.Path__c, Year__c, Status__c
                                    FROM Assortment__c
                                    WHERE Id = :assortmentId];
        System.debug('currentAss: ' + JSON.serialize(currentAss));
        String negoAssortmentsQuery = 'SELECT Id, BusinessUnitTarget__c, BusinessUnitTarget__r.Name,';
        negoAssortmentsQuery += ' BusinessUnitTarget__r.WeightedDistributionManual__c, BusinessUnitTarget__r.WeightedDistributionManualN1__c';
        negoAssortmentsQuery += ' FROM Assortment__c';
        negoAssortmentsQuery += ' WHERE BusinessUnitSource__c = \'' + currentAss.BusinessUnitTarget__c + '\'';
        negoAssortmentsQuery += ' AND Hierarchy__c = \'' + currentAss.Hierarchy__c + '\'';
        negoAssortmentsQuery += ' AND Status__c = \'Validate\'';
        negoAssortmentsQuery += ' AND Year__c = ' + (currentAss.Year__c - 1);
        negoAssortmentsQuery += ' AND BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE';
        negoAssortmentsQuery += ' AND recordType.DeveloperName IN (\'Negotiation\', \'OnTopConso\')';
        negoAssortmentsQuery += ' ORDER BY BusinessUnitTarget__r.Name ASC';
        system.debug('negoAssortmentsQuery >>> ' + negoAssortmentsQuery);
        // check access to Assortment and Orga_BU and their fields
        if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)
            && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields))
        {
            List<Assortment__c> negoAssortmentsList = Database.query(negoAssortmentsQuery);
            System.debug('negoAssortmentsList: ' + JSON.serialize(negoAssortmentsList));
            for (Assortment__c item : negoAssortmentsList) {
                negoAssIds.add(item.Id);
                assTargetList.add(item.BusinessUnitTarget__r);
            }
        }

        List<FieldWrapper> mainFields = (List<FieldWrapper>) JSON.deserialize(JSON.serialize(gridSettingsManager.GRID_FIELDS), List<FieldWrapper>.class);
        //GET PRODUCTS WITH BUDGET DETAILS
        String budgetAssQuery = 'SELECT Product__c';
        budgetAssQuery += ' FROM AssortmentDetail__c';
        budgetAssQuery += ' WHERE Assortment__c = \'' + currentAss.Id + '\'';
        budgetAssQuery += ' AND Hierarchy__c <> NULL';
        System.debug('budgetAssQuery: ' + budgetAssQuery);
        List<AssortmentDetail__c> budgetDetails = Database.query(budgetAssQuery);
        System.debug('budgetDetails: ' + JSON.serialize(budgetDetails));
        Set<String> productIdSet = new Set<String>();
        for (AssortmentDetail__c detail : budgetDetails) {
            productIdSet.add(detail.Product__c);
        }
        System.debug('productIdSet: ' + JSON.serialize(productIdSet));
        System.debug('gridSettingsManager.ALL_FIELDS: ' + JSON.serialize(gridSettingsManager.ALL_FIELDS));
        //CALCULATE SUBTOTALS
        Map<String, Map<String, Decimal>> subTotalsMap = getSubTotals(currentAss, new List<String>(negoAssIds), new List<String>(productIdSet), null);
        System.debug('subTotalsMap: ' + JSON.serialize(subTotalsMap));
        Map<Id, BusinessUnit__c> clustersMap = new Map<Id, BusinessUnit__c>([SELECT Id, Name
                                                                              FROM BusinessUnit__c
                                                                              WHERE RecordType.DeveloperName = 'AssortmentCluster'
                                                                              AND AssortmentStrat__c <> NULL
                                                                              AND BusinessUnitCountryOrigin__c IN :assTargetList]);
        InitWrapper res = new InitWrapper();
        res.budgetAssortment = currentAss;
        res.negoAssIds = negoAssIds;
        res.mainFields = mainFields;
        res.budgetASDFields = budgetASDFields;
        res.budgetAssAPIFields = budgetAssAPIFields;
        res.negoASDFields = negoASDFields;
        res.negoAssAPIFields = negoAssAPIFields;
        res.assTargetList = assTargetList;
        res.picklistValuesMap = gridSettingsManager.picklistValuesMap;
        res.allFields = gridSettingsManager.ALL_FIELDS;
        res.productIdSet = productIdSet;
        res.subTotalsMap = subTotalsMap;
        res.clustersMap = clustersMap;
        return JSON.serialize(res);
    }
    @AuraEnabled
    public static string loadData(String currentAssJSON, List<String> negoAssIds, String filtersSerialized, List<String> allFields, Integer pageNumber, Integer pageSize, List<String> allProductsList) {
        try {
            System.debug('allProductsList: ' + JSON.serialize(allProductsList));
            System.debug('allFields: ' + JSON.serialize(allFields));
            if (String.isBlank(currentAssJSON)) {
                return 'no-assortment';
            }
            Assortment__c currentAss = (Assortment__c) JSON.deserialize(currentAssJSON, Assortment__c.class);
            FilterWrapper filters = String.isNotBlank(filtersSerialized) ? (FilterWrapper) JSON.deserialize(filtersSerialized, FilterWrapper.class) : new FilterWrapper();
            //GET BUDGET
            String budgetAssQuery = buildBudgetAssQuery(currentAss.Id, allFields, filters);
            List<AssortmentDetail__c> budgetASDList = new List<AssortmentDetail__c>();
            ApexPages.StandardSetController budgetAssCon = new ApexPages.StandardSetController(Database.getQueryLocator(budgetAssQuery));
            budgetAssCon.setPageSize(pageSize);
            budgetAssCon.setpageNumber(pageNumber);
            budgetASDList = budgetAssCon.getRecords();
            Set<String> currentPageProducts = new Set<String>();
            //GET CURRENT PAGE PRODUCTS
            for (AssortmentDetail__c detail : budgetASDList) {
                currentPageProducts.add(detail.Product__c);
            }
            //BUILD NEGO AND TARGET QUERIES
            System.debug('budgetAssQuery: ' + budgetAssQuery);
            String negoAssQuery = buildNegoAssQuery(negoAssIds, new List<String>(currentPageProducts));
            System.debug('negoAssQuery: ' + negoAssQuery);
            String targetAssortmentsQuery = buildTargetAssortmentsQuery(currentAss, new List<String>(currentPageProducts));
            System.debug('targetAssortmentsQuery: ' + targetAssortmentsQuery);
            //GET RECORDS
            List<AssortmentDetail__c> negoASDList = Database.query(negoAssQuery);
            List<AssortmentDetail__c> targetASDList = Database.query(targetAssortmentsQuery);
            //BUILD RESULTS WRAPPER

            ResultsWrapper res = new ResultsWrapper();
            res.numberOfRecords = budgetAssCon.getResultSize();
            res.budgetASDList = budgetASDList;
            res.negoASDList = negoASDList;
            res.targetASDList = targetASDList;
            system.debug('res >>>> ' + JSON.serialize(res));

            //RETURN RESULT
            return JSON.serialize(res);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException('loadData >>>>>>>>> ' + e.getMessage());
        }
    }
    public static Map<String, Map<String, Decimal>> getSubTotals(Assortment__c currentAss, List<String> negoAssIds, List<String> allProductsList, String categoryId) {
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        System.debug('currentAss: ' + JSON.serialize(currentAss));
        System.debug('negoAssIds: ' + JSON.serialize(negoAssIds));
        System.debug('allProductsList: ' + JSON.serialize(allProductsList));
        //BUILD QUERY
        String subTotalQuery = 'SELECT Hierarchy__c categoryId, Assortment__r.BusinessUnitTarget__c bu';
        for (String fieldName : fieldsToSumSet) {
            subTotalQuery += ', SUM(' + String.escapeSingleQuotes(fieldName) + ') ' + String.escapeSingleQuotes(fieldName);
        }
        subTotalQuery += ' FROM AssortmentDetail__c';
        subTotalQuery += ' WHERE Product__c IN (\'' + String.join(allProductsList, '\', \'') + '\')';
        subTotalQuery += ' AND Hierarchy__c <> NULL';
        if (categoryId != null) {
            subTotalQuery += ' AND Hierarchy__c = \'' + categoryId + '\'';
        }
        //BUDGET
        subTotalQuery += ' AND ((Assortment__c = \'' + currentAss.Id + '\')';
        //NEGO
        subTotalQuery += ' OR (Assortment__c IN (\'' + String.join(negoAssIds, '\', \'') + '\'))';
        //TARGET
        subTotalQuery += ' OR (Assortment__r.BusinessUnitSource__c = \'' + currentAss.BusinessUnitTarget__c + '\'';
        subTotalQuery += ' AND Assortment__r.Hierarchy__c = \'' + currentAss.Hierarchy__c + '\'';
        subTotalQuery += ' AND Assortment__r.AssortmentChannelBudgetRef__c = \'' + currentAss.Id + '\'';
        subTotalQuery += ' AND Version__c = NULL';
        subTotalQuery += ' AND Hierarchy__c <> NULL';
        subTotalQuery += ' AND Product__r.isActive = TRUE';
        subTotalQuery += ' AND Assortment__r.Year__c = ' + (currentAss.Year__c);
        subTotalQuery += ' AND Assortment__r.BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE';
        subTotalQuery += ' AND Assortment__r.RecordType.DeveloperName IN (\'Target\', \'TargetConso\')';
        subTotalQuery += ' AND Hierarchy__r.Path__c LIKE \'' + currentAss.Hierarchy__r.Path__c + '%\'))';
        subTotalQuery += ' GROUP BY Hierarchy__c, Assortment__r.BusinessUnitTarget__c';

        System.debug('subTotalQuery: ' + subTotalQuery);
        for (AggregateResult result : Database.query(subTotalQuery)) {
            String key = Id.valueOf(String.valueOf(result.get('categoryId')));
            if (result.get('bu') != null) {
                key += '-' + Id.valueOf(String.valueOf(result.get('bu')));
            }
            subTotalsMap.put(key, new Map<String, Decimal>());
            for (String fieldName : fieldsToSumSet) {
                Decimal newValue = result.get(fieldName) == null ? 0.0 : Decimal.valueOf(String.valueOf(result.get(fieldName)));
                subTotalsMap.get(key).put(fieldName, newValue);
            }
        }
        return subTotalsMap;
    }

    public static String buildBudgetAssQuery(Id assortmentId, List<String> fields, FilterWrapper filters) {
        System.debug('fields: ' + JSON.serialize(fields));
        String budgetAssQuery = 'SELECT ';
        if (!fields.isEmpty()) {
            budgetAssQuery += String.join(fields, ', ');
        } else {
            budgetAssQuery += 'Id ';
        }
        budgetAssQuery += ', ' + String.join(budgetASDFields.keySet(), ', ');
        budgetAssQuery += ' FROM AssortmentDetail__c';
        budgetAssQuery += ' WHERE Assortment__c = \'' + assortmentId + '\'';
        budgetAssQuery += ' AND Hierarchy__c <> NULL';
        if (filters != null) {
            if (filters.productGTIN != null && filters.productGTIN != '') {
                budgetAssQuery += ' AND ProductGTIN__c = \'' + filters.productGTIN + '\'';
            }
            if (filters.brand != null && filters.brand != '') {
                budgetAssQuery += ' AND ProductBrand__c = \'' + filters.brand + '\'';
            }
            if (filters.priority != null && filters.priority != '') {
                budgetAssQuery += ' AND ProductPriority__c = \'' + filters.priority + '\'';
            }
            if (filters.categories != null && !filters.categories.isEmpty()) {
                budgetAssQuery += ' AND Hierarchy__c IN (\'' + String.join(filters.categories, '\', \'') + '\')';
            }
        }
        budgetAssQuery += ' ORDER BY Product__r.Hierarchy__r.Name ASC';
        System.debug('budgetAssQuery: ' + budgetAssQuery);
        return budgetAssQuery;
    }
    public static String buildNegoAssQuery(List<String> negoAssIds, List<String> productIdList) {
        System.debug('negoAssIds: ' + JSON.serialize(negoAssIds));
        String negoAssQuery = 'SELECT Id, Product__c, Assortment__c, Assortment__r.BusinessUnitTarget__c, ProductCluster__c, BusinessUnitCluster__r.Name, ProductPriority__c, ';
        negoAssQuery += String.join(negoAssAPIFields, ', ');
        negoAssQuery += ' FROM AssortmentDetail__c';
        negoAssQuery += ' WHERE Assortment__c IN (\'' + String.join(negoAssIds, '\', \'') + '\')';
        negoAssQuery += ' AND Hierarchy__c <> NULL';
        if (productIdList != null) {
            negoAssQuery += ' AND Product__c IN (\'' + String.join(productIdList, '\', \'') + '\')';
        }
        negoAssQuery += ' AND Status__c = \'Validate\'';
        System.debug('negoAssQuery: ' + negoAssQuery);
        return negoAssQuery;
    }
    public static String buildTargetAssortmentsQuery(Assortment__c currentAss, List<String> productIdList) {
        // Target QUERIES
        String targetAssortmentsQuery = 'SELECT Id, Assortment__c, Assortment__r.Status__c, Product__c, Assortment__r.BusinessUnitTarget__c, ProductCluster__c, BusinessUnitCluster__c, BusinessUnitCluster__r.Name, WDChannelBaseTarget__c, ProductPriority__c, WDChannelBaseTarget_NegoL4LP1Gap__c ';
        targetAssortmentsQuery += ' FROM AssortmentDetail__c';
        targetAssortmentsQuery += ' WHERE Assortment__r.BusinessUnitSource__c = \'' + currentAss.BusinessUnitTarget__c + '\'';
        targetAssortmentsQuery += ' AND Assortment__r.Hierarchy__c = \'' + currentAss.Hierarchy__c + '\'';
        targetAssortmentsQuery += ' AND Assortment__r.AssortmentChannelBudgetRef__c = \'' + currentAss.Id + '\'';
        targetAssortmentsQuery += ' AND Version__c = NULL';
        targetAssortmentsQuery += ' AND Hierarchy__c <> NULL';
        targetAssortmentsQuery += ' AND Product__r.isActive = TRUE';
        targetAssortmentsQuery += ' AND Assortment__r.Year__c = ' + (currentAss.Year__c);
        targetAssortmentsQuery += ' AND Assortment__r.BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE';
        targetAssortmentsQuery += ' AND Assortment__r.RecordType.DeveloperName IN (\'Target\', \'TargetConso\')';
        targetAssortmentsQuery += ' AND Hierarchy__r.Path__c LIKE \'' + currentAss.Hierarchy__r.Path__c + '%\'';
        if (productIdList != null) {
            targetAssortmentsQuery += ' AND Product__c IN (\'' + String.join(productIdList, '\', \'') + '\')';
        }
        targetAssortmentsQuery += ' ORDER BY Assortment__r.BusinessUnitTarget__r.Name ASC';
        system.debug('targetAssortmentsQuery > >> ' + targetAssortmentsQuery);
        return targetAssortmentsQuery;
    }

    @AuraEnabled
    public static String save(String changesMapSerialized) {
        List<AssortmentDetail__c> assortmentDetailsToUpdate = (List<AssortmentDetail__c>) JSON.deserialize(changesMapSerialized, List<AssortmentDetail__c>.class);
        String errorMessage = '';
        if (!assortmentDetailsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(assortmentDetailsToUpdate, true);
            for (Database.SaveResult result : results) {
                errorMessage = '';
                if (!result.isSuccess()) {
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                    }
                }
            }
        }
        return errorMessage;
    }

    @AuraEnabled
    public static string fakeSave(String currentAssJSON, List<String> negoAssIds, List<String> allProductsList, String categoryId, String asdToUpdateJSON) {
        Assortment__c currentAss = (Assortment__c) JSON.deserialize(currentAssJSON, Assortment__c.class);
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        SavePoint sp = Database.setSavepoint();
        List<AssortmentDetail__c> updatedDetails = (List<AssortmentDetail__c>) JSON.deserialize(asdToUpdateJSON, List<AssortmentDetail__c>.class);
        List<Id> detailIds = new List<Id>();
        for (AssortmentDetail__c detail : updatedDetails) {
            detailIds.add(detail.Id);
        }
        try {
            update updatedDetails;
            String updatedDetailsQuery = 'SELECT Id ';
            updatedDetailsQuery += ', ' + String.join(budgetASDFields.keySet(), ', ');
            updatedDetailsQuery += ' FROM AssortmentDetail__c';
            updatedDetailsQuery += ' WHERE Id IN (\'' + String.join(detailIds, '\', \'') + '\')';


            updatedDetails = database.query(updatedDetailsQuery);
            System.debug(' updatedDetails >>> ' + JSON.serialize(updatedDetails));
            subTotalsMap = getSubTotals(currentAss, negoAssIds, allProductsList, categoryId);
            System.debug('subTotalsMap: ' + JSON.serialize(subTotalsMap));
            Database.rollback(sp);
        } catch (DmlException ex) {
            System.debug('Error ::>>>'+ ex.getDmlMessage(0));
            System.debug('Error ::>>>'+ ex.getDmlMessage(0) + ' - ' + ex.getStackTraceString());
            Database.rollback(sp);
        } catch (Exception ex) {
            System.debug('ERROR::>' + ex.getMessage() + '-' + ex.getStackTraceString());
            Database.rollback(sp);
        }
        FakeSaveResult fakeSaveResult = new FakeSaveResult();
        fakeSaveResult.assortmentDetailsList = updatedDetails;
        fakeSaveResult.subTotalsMap = subTotalsMap;
        return JSON.serialize(fakeSaveResult);
    }

    public class FakeSaveResult {
        public List<AssortmentDetail__c> assortmentDetailsList {get; set;}
        public Map<String, Map<String, Decimal>> subTotalsMap {get;set;}
    }
    @AuraEnabled
    public static String changeAssortmentStatus(String assortmentId, String status) {
        Database.SaveResult result = Database.update(new Assortment__c(Id = assortmentId, Status__c = status), false);
        String errorMessage = '';
        if (!result.isSuccess()) {
            Database.Error[] errors = result.getErrors();
            for (Database.Error err : errors) {
                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
            }
            throw new AuraHandledException(errorMessage);
        }
        return [SELECT LongName__c FROM Assortment__c WHERE Id = :assortmentId].LongName__c;
    }

    @AuraEnabled
    public static String buildTreeData(String assortmentCategoryId, String buTargetMapSerialized, String columnsSerialized, String valuesSerialized) {
        try {
            Map<String, String> buTargetMap = (Map<String, String>) JSON.deserialize(buTargetMapSerialized, Map<String, String>.class);
            Map<String, Map<String, String>> columns = (Map<String, Map<String, String>>) JSON.deserialize(columnsSerialized, Map<String, Map<String, String>>.class);
            Map<Id, Map<String, Decimal>> columnValues = (Map<Id, Map<String, Decimal>>) JSON.deserialize(valuesSerialized, Map<Id, Map<String, Decimal>>.class);
            HierarchyElementTree het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});
            Treebuilder tb = new Treebuilder();
            Hierarchy__c mainCateg = [SELECT Id, Level__c FROM Hierarchy__c WHERE Id = :assortmentCategoryId];
            String jsonHeadersTree = tb.buildHeadersTree(buTargetMap, columns);
            String jsonDataTree = tb.buildJSonTree(het.allElementsList, columnValues, mainCateg);
            TreeWrapper treeW = new TreeWrapper(jsonHeadersTree, jsonDataTree);
            return JSON.serialize(treeW);
        } catch (Exception e) {
            System.debug('Error buildTreeData ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string loadGridData(String assortmentId) {
        try {
            List<BusinessUnit__c> assTargetList = new List<BusinessUnit__c>();
            Set<String> negoAssIds = new Set<String>();

            Assortment__c currentAss = [SELECT Id, Name, LongName__c, BusinessUnitTarget__c, BusinessUnitTarget__r.Name, Hierarchy__c, Hierarchy__r.Path__c, Year__c, Status__c
                                        FROM Assortment__c
                                        WHERE Id = :AssortmentId];

            String negoAssortmentsQuery = 'SELECT Id, BusinessUnitTarget__c, BusinessUnitTarget__r.Name,';
            negoAssortmentsQuery += ' BusinessUnitTarget__r.WeightedDistributionManual__c, BusinessUnitTarget__r.WeightedDistributionManualN1__c';
            negoAssortmentsQuery += ' FROM Assortment__c';
            negoAssortmentsQuery += ' WHERE BusinessUnitSource__c = \'' + currentAss.BusinessUnitTarget__c + '\'';
            negoAssortmentsQuery += ' AND Hierarchy__c = \'' + currentAss.Hierarchy__c + '\'';
            negoAssortmentsQuery += ' AND Status__c = \'Validate\'';
            negoAssortmentsQuery += ' AND Year__c = ' + (currentAss.Year__c - 1);
            negoAssortmentsQuery += ' AND BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE';
            negoAssortmentsQuery += ' AND recordType.DeveloperName IN (\'Negotiation\', \'OnTopConso\')';
            negoAssortmentsQuery += ' ORDER BY BusinessUnitTarget__r.Name ASC';
           	system.debug('negoAssortmentsQuery >>> ' + negoAssortmentsQuery);

             // check access to Assortment and Orga_BU and their fields
            String[] assortmentBUFields = new String[] {
                SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
                SObjectType.Assortment__c.fields.Hierarchy__c.Name,
                SObjectType.Assortment__c.fields.Status__c.Name,
                SObjectType.Assortment__c.fields.Year__c.Name,
                SObjectType.Assortment__c.fields.RecordTypeId.Name
            };
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Name.Name,
                SObjectType.BusinessUnit__c.fields.LayerBudgetDisplay__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
                SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name,
                SObjectType.BusinessUnit__c.fields.Format__c.Name
            };
            if (NegoptimHelper.checkAccessibility(Assortment__c.SObjectType, assortmentBUFields)
                && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields))
            {
                List<Assortment__c> negoAssortmentsList = Database.query(negoAssortmentsQuery);
                for (Assortment__c item : negoAssortmentsList) {
                    negoAssIds.add(item.Id);
                    assTargetList.add(item.BusinessUnitTarget__r);
                }
            }
            List<String> budgetAssAPIFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name
            };
            Map<String, String> budgetASDFields = new Map<String, String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name => System.Label.LBL_WDChannelBaseNegoL4L_P1,
                SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel_P1__c.Name => System.Label.LBL_WDChannelBasePanel_P1,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget__c.Name => System.Label.LBL_WDChannelBaseBudget,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseBudget_NegoL4LP1Gap,
                SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget_NegoL4LP1Gap__c.Name => System.Label.LBL_PNChannelBaseBudget_NegoL4LP1Gap,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name => System.Label.LBL_WDChannelBaseTarget,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseTarget_NegoL4LP1Gap
            };

            String budgetAssQuery = 'SELECT Id, Product__c, Hierarchy__c, Hierarchy__r.Name, ProductPriority__c,';
            budgetAssQuery += String.join(budgetASDFields.keySet(), ', ');
            budgetAssQuery += ' FROM AssortmentDetail__c';
            budgetAssQuery += ' WHERE Assortment__c = \'' + AssortmentId + '\'';
            budgetAssQuery += ' AND Hierarchy__c <> NULL';

            List<String> negoAssAPIFields = new List<String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
                SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
                // SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name
            };
            Map<String, String> negoASDFields = new Map<String, String> {
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name => System.Label.LBL_WDChannelBaseNegoL4L_P1,
                SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name => SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Label,
                // SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c.Name => System.Label.LBL_WDChannelBaseTarget,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseTarget_NegoL4LP1Gap,
                SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name => System.Label.LBL_WDChannelBaseBudget_NegoL4LP1Gap
            };

            String negoAssQuery = 'SELECT Id, Product__c, Assortment__c, Assortment__r.BusinessUnitTarget__c, BusinessUnitCluster__r.Name, ProductPriority__c, ';
            negoAssQuery += String.join(negoAssAPIFields, ', ');
            negoAssQuery += ' FROM AssortmentDetail__c';
            negoAssQuery += ' WHERE Assortment__c IN (\'' + String.join(negoAssIds, '\', \'') + '\')';
            System.debug('negoAssQuery: ' + negoAssQuery);

            // Target QUERIES
            String targetAssortmentsQuery = 'SELECT Id, Assortment__c, Assortment__r.Status__c, Product__c, Assortment__r.BusinessUnitTarget__c, WDChannelBaseTarget__c, ProductPriority__c ';
            targetAssortmentsQuery += ' FROM AssortmentDetail__c';
            targetAssortmentsQuery += ' WHERE Assortment__r.BusinessUnitSource__c = \'' + currentAss.BusinessUnitTarget__c + '\'';
            targetAssortmentsQuery += ' AND Assortment__r.Hierarchy__c = \'' + currentAss.Hierarchy__c + '\'';
            targetAssortmentsQuery += ' AND Assortment__r.AssortmentChannelBudgetRef__c = \'' + currentAss.Id + '\'';
            targetAssortmentsQuery += ' AND Version__c = NULL';
            targetAssortmentsQuery += ' AND Hierarchy__c <> NULL';
            targetAssortmentsQuery += ' AND Product__r.isActive = TRUE';
            targetAssortmentsQuery += ' AND Assortment__r.Year__c = ' + (currentAss.Year__c);
            targetAssortmentsQuery += ' AND Assortment__r.BusinessUnitTarget__r.LayerBudgetDisplay__c = TRUE';
            targetAssortmentsQuery += ' AND Assortment__r.RecordType.DeveloperName IN (\'Target\', \'TargetConso\')';
            targetAssortmentsQuery += ' AND Hierarchy__r.Path__c LIKE \'' + currentAss.Hierarchy__r.Path__c + '%\'';
            targetAssortmentsQuery += ' ORDER BY Assortment__r.BusinessUnitTarget__r.Name ASC';
           	system.debug('negoAssortmentsQuery >>> ' + negoAssortmentsQuery);

            GridResultsWrapper res = new GridResultsWrapper();
            res.budgetAssortment = currentAss;
            res.budgetASDFields = budgetASDFields;
            res.budgetAssAPIFields = budgetAssAPIFields;
            res.negoASDFields = negoASDFields;
            res.negoAssAPIFields = negoAssAPIFields;
            res.assTargetList = assTargetList;
            res.budgetASDList = Database.query(budgetAssQuery);
            res.negoASDList = Database.query(negoAssQuery);
            res.targetASDList = Database.query(targetAssortmentsQuery);
            return JSON.serialize(res);
        } catch (Exception e) {
            System.debug(' >>> ' + e.getMessage() + '-' + e.getLineNumber());
            throw new AuraHandledException('loadData >>>>>>>>> ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static String loadTreeData(String assortmentCategoryId, String buTargetMapSerialized, String columnsSerialized, String valuesSerialized) {
        try {
            Map<String, String> buTargetMap = (Map<String, String>) JSON.deserialize(buTargetMapSerialized, Map<String, String>.class);
            Map<String, Map<String, String>> columns = (Map<String, Map<String, String>>) JSON.deserialize(columnsSerialized, Map<String, Map<String, String>>.class);
            Map<Id, Map<String, Decimal>> columnValues = (Map<Id, Map<String, Decimal>>) JSON.deserialize(valuesSerialized, Map<Id, Map<String, Decimal>>.class);
            HierarchyElementTree het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});
            Treebuilder tb = new Treebuilder();
            Hierarchy__c mainCateg = [SELECT Id, Level__c FROM Hierarchy__c WHERE Id = :assortmentCategoryId];
            String jsonHeadersTree = tb.buildHeadersTree(buTargetMap, columns);
            String jsonDataTree = tb.buildJSonTree(het.allElementsList, columnValues, mainCateg);
            TreeWrapper treeW = new TreeWrapper(jsonHeadersTree, jsonDataTree);
            return JSON.serialize(treeW);
        } catch (Exception e) {
            System.debug('Error buildTreeData ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ResultsWrapper {
        public Integer numberOfRecords {get; set;}
        public List<AssortmentDetail__c> budgetASDList {get; set;}
        public List<AssortmentDetail__c> negoASDList {get; set;}
        public List<AssortmentDetail__c> targetASDList {get; set;}
    }
    public class InitWrapper {
        public Assortment__c budgetAssortment {get;set;}
        public Set<String> negoAssIds {get;set;}
        public List<FieldWrapper> mainFields {get; set;}
        public Map<String, String> budgetASDFields {get; set;}
        public List<String> budgetAssAPIFields {get; set;}
        public Map<String, String> negoASDFields {get; set;}
        public List<String> negoAssAPIFields {get; set;}
        public Map<String, Map<String, String>> picklistValuesMap { get; set; }
        public List<String> allFields { get; set; }
        public List<BusinessUnit__c> assTargetList {get; set;}
        public Set<String> productIdSet {get; set;}
        public Map<String, Map<String, Decimal>> subTotalsMap {get; set;}
        public Map<Id, BusinessUnit__c> clustersMap {get; set;}
        public String prefix {get; set;}

        // product color indicators for introduction / stop dates
        public String INNO_INTRO_DATE_LESS_N {
            get {
                return NegoptimHelper.INNO_INTRO_DATE_LESS_N;
            }
        }
        public String INNO_INTRO_DATE_GREATER_N {
            get {
                return NegoptimHelper.INNO_INTRO_DATE_GREATER_N;
            }
        }
        public String STOP_DATE_LESS_N {
            get {
                return NegoptimHelper.STOP_DATE_LESS_N;
            }
        }
        public String STOP_DATE_GREATER_N {
            get {
                return NegoptimHelper.STOP_DATE_GREATER_N;
            }
        }
        public InitWrapper() {
            this.budgetAssortment = new Assortment__c();
            this.mainFields = new List<FieldWrapper>();
            this.budgetASDFields = new Map<String, String>();
            this.budgetAssAPIFields = new List<String>();
            this.negoASDFields = new Map<String, String>();
            this.negoAssAPIFields = new List<String>();
            this.assTargetList = new List<BusinessUnit__c>();
            this.picklistValuesMap = new Map<String, Map<String, String>>();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    public class FilterWrapper {
        List<String> categories {get; set;}
        String productGTIN {get; set;}
        String brand {get; set;}
        String priority {get; set;}

        public FilterWrapper() {
            this.categories = new List<String>();
            this.productGTIN = '';
            this.brand = '';
            this.priority = '';
        }
    }

    public class FieldWrapper {
		public String fieldName { get; set; }
		public String fieldLabel { get; set; }
        public String stringFieldType {get; set;}
        public Boolean isNumberField {get; set;}
		public String style { get; set; }
		public String widthStyle { get; set; }
        public String width { get; set; }
        public String objectName { get; set; }
        public String relationField { get; set; }
        public Boolean isRelationField { get; set; }

        public FieldWrapper() {
            this.fieldName = '';
            this.fieldLabel = '';
            this.stringFieldType = '';
            this.isNumberField = false;
            this.style = '';
            this.widthStyle = '';
            this.width = '';
            this.objectName = '';
            this.relationField = '';
            this.isRelationField = false;
        }

        public FieldWrapper(String fieldName, String fieldLabel, String stringFieldType, String objectName, String relationField, Boolean isRelationField) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.stringFieldType = stringFieldType;
            this.isNumberField = false;
            this.style = '';
            this.widthStyle = '';
            this.width = '';
            this.objectName = objectName;
            this.relationField = relationField;
            this.isRelationField = isRelationField;
        }
    }

    public class TreeWrapper {
		public String jsonHeadersTree { get; set; }
		public String jsonDataTree { get; set; }

        public TreeWrapper(String jsonHeadersTree, String jsonDataTree) {
            this.jsonHeadersTree = jsonHeadersTree;
            this.jsonDataTree = jsonDataTree;
        }
    }

    public class GridResultsWrapper {
        public Map<String,  Map<String,  Schema.DescribeFieldResult>> fieldsMap;
        public Assortment__c budgetAssortment {get;set;}
        public Map<String, String> budgetASDFields {get; set;}
        public List<String> budgetAssAPIFields {get; set;}
        public Map<String, String> negoASDFields {get; set;}
        public List<String> negoAssAPIFields {get; set;}
        public List<BusinessUnit__c> assTargetList {get; set;}
        public List<AssortmentDetail__c> budgetASDList {get; set;}
        public List<AssortmentDetail__c> negoASDList {get; set;}
        public List<AssortmentDetail__c> targetASDList {get; set;}

        public GridResultsWrapper() {
            this.fieldsMap = new Map<String,  Map<String,  Schema.DescribeFieldResult>> {
                SObjectType.Orga_BU__c.getName() => new Map<String,  Schema.DescribeFieldResult>(),
                SObjectType.Product2.getName() => new Map<String,  Schema.DescribeFieldResult>(),
                SObjectType.AssortmentDetail__c.getName() => new Map<String,  Schema.DescribeFieldResult>(),
                SObjectType.Assortment__c.getName() => new Map<String,  Schema.DescribeFieldResult>()
            };
            for (String objectName : this.fieldsMap.keySet()) {
                Map<String,  Schema.DescribeFieldResult> fieldMap = this.fieldsMap.get(objectName);
                for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
                    fieldMap.put(field.getDescribe().getName(),  field.getDescribe());
                }
            }
            this.budgetAssortment = new Assortment__c();
            this.budgetASDFields = new Map<String, String>();
            this.budgetAssAPIFields = new List<String>();
            this.negoASDFields = new Map<String, String>();
            this.negoAssAPIFields = new List<String>();
            this.assTargetList = new List<BusinessUnit__c>();
            this.budgetASDList = new List<AssortmentDetail__c>();
            this.negoASDList = new List<AssortmentDetail__c>();
            this.targetASDList = new List<AssortmentDetail__c>();
        }
    }
}