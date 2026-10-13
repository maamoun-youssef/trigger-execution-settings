/**
 * @author ULiT
 * @date 6/6/2023
 * @description Custom controller that uses the standard Assortment_BU__c controller
 * and includes the Assortment BU Matrix logic for the corresponding view.
 * It provides the following initial functionalities:
 * 1- Display all assortment details for all assortment head + Filter.
 * 2- Display the assorment details for a single assortment head + Filter.
 * 3- GOAL: Optimising the ASSORTMENT of PRODUCTS you plan to stock &
 * then ARRANGING those products on the shelves for MAXIMUM impact.
 **/

 public with sharing class AssortmentMatrixCtrl {
    public static List<String> fieldNames = new List<String> {
        SObjectType.Assortment__c.fields.Name.Name,
        SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
        SObjectType.Assortment__c.fields.Hierarchy__c.Name,
        SObjectType.Assortment__c.fields.BDate__c.Name,
        SObjectType.Assortment__c.fields.EDate__c.Name,
        SObjectType.Assortment__c.fields.Status__c.Name,
        SObjectType.Assortment__c.fields.Year__c.Name,
        SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name
    };
        
    public static List<String> staticFieldsList = new List<String> {
        'RecordType.DeveloperName',
        /*SObjectType.AssortmentDetail__c.fields.Name.Name,
        SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name,
        SObjectType.AssortmentDetail__c.fields.ClientCategory__c.Name,
        SObjectType.AssortmentDetail__c.fields.Product__c.Name,
        SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
        SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
        SObjectType.AssortmentDetail__c.fields.ProductCluster__c.Name,
        SObjectType.AssortmentDetail__c.fields.Status__c.Name,
        SObjectType.AssortmentDetail__c.fields.Assortment__c.Name,
        SObjectType.AssortmentDetail__c.fields.RecordDate__c.Name,
        SObjectType.AssortmentDetail__c.fields.Version__c.Name,
        SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
        //Start ak
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNChannelBaseBudget__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNClientBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNClientBaseNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.PNClientBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseBudget_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.NDChannelBaseBudget_NegoL4LP1Gap__c.Name,

        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDClientBaseNegoL4L__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDClientBaseNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDClientBaseTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.NDChannelBaseBudget__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDchannelBasebudget__c.Name,
        
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseTarget__c .Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseFact__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBasePanel__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDClientBaseNegoL4L_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.WDChannelBaseNegoL4L_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.SOSNumberTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.AvgWeeklySalesClient__c.Name,
        SObjectType.AssortmentDetail__c.fields.AvgWeeklySalesChannel__c.Name,
        SObjectType.AssortmentDetail__c.fields.StartDate_W__c.Name,
        SObjectType.AssortmentDetail__c.fields.KVolumeNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name,
        SObjectType.AssortmentDetail__c.fields.QtyNego_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.SOSNumberNego_NegoL4LP1Gap__c.Name,
        SObjectType.AssortmentDetail__c.fields.RetailPriceTarget__c.Name,
        SObjectType.AssortmentDetail__c.fields.SPCCEP_CAMHClient__c.Name,
        SObjectType.AssortmentDetail__c.fields.SPCCEP_CAMHChannel__c.Name,
        SObjectType.AssortmentDetail__c.fields.SelloutNego_P1__c.Name,
        SObjectType.AssortmentDetail__c.fields.SPCCEP_SelloutNego_NegoP1GapReport__c.Name,
        SObjectType.AssortmentDetail__c.fields.SelloutNego_NegoP1Gap__c.Name,
        //End ak
        SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name,*/
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Level__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name) + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.LongName__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.Level__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.HierarchyParent__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.BDate__c.Name,
            //Start AK
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP2__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitSource__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP2__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualN1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManual__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.WeightedDistributionManualP2__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberN1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumber__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP1__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.BusinessUnitTarget__c.Name) +'.'+SObjectType.BusinessUnit__c.fields.SiteOfSalesNumberP2__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.QtyNego__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.WD_Marketbased_Low_Limit__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.TotalKWeight__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.VATRate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.RecordType.' + SObjectType.RecordType.fields.DeveloperName.Name,
            //End AK
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.EDate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.Hierarchy__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.Year__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.LastModifiedDate.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.AssortmentNegotiationRef__c.Name)
            + '.' + SObjectType.Assortment__c.fields.EDate__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.Hierarchy__c.Name)
            + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.ProductCluster__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name)
            + '.' + SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name)
            + '.' + SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.ProductCluster__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.AssortmentStrat__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Product_Reference_Type__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Market_End_of_Life_Date__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Market_Introduction_Date__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.IsRenovation__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.IsInnovation__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.RecordType.' + SObjectType.RecordType.fields.DeveloperName.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailLHistory__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.Product__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.AssortmentDetailNegotiationRef__c.Name) + '.' + SObjectType.AssortmentDetail__c.fields.Status__c.Name,
            
        NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Assortment__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Assortment__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Path__c.Name
    };
    
    @AuraEnabled
    public static string initData(String assortmentId, String gridLayout) {
        Assortment__c currentAssortment = [SELECT Id, Name, LongName__c, Year__c, BusinessUnitTarget__c, BusinessUnitTarget__r.IsMultipleComplementary__c,
                                           BusinessUnitTarget__r.SetASRegionSynchro__c, BusinessUnitTarget__r.t_SalesCannibalizationRates__c, Hierarchy__c, Status__c,
                                           RecordType.DeveloperName, EDate__c, ExtId__c, AssortmentNegotiationRef__c
                                           FROM Assortment__c WHERE Id = :assortmentId];  
        // load custom settings
        NegoptimSettings settings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
        if (!System.Test.isRunningTest() && (settings.sBusinessType == null || settings.sBusinessType == '')) {
            return null;
        }
        // CalculationWrapper
        CalculationWrapper calculationWrapper = new CalculationWrapper();
        //asdFieldsMetadata
        Map<String, String> asdFieldsMetadata = new Map<String, String>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(SObjectType.AssortmentDetail__c.Name);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = objDescribe.fields.getMap();
        Map<String, List<String>> formulaFieldsReferencedMap = new Map<String, List<String>>();
        Map<String, List<String>> formulaDependencies = new Map<String, List<String>>();
        Map<String, List<String>> filteredFormulaFieldsDependencies = new Map<String, List<String>>();
        Map<String, Object> formulasMetadata = new Map<String, Object>();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            // Formula Expression
            String formulaExpression = fieldDescribe.getCalculatedFormula();
            if (fieldDescribe.getName() != 'Id' && !staticFieldsList.contains(fieldDescribe.getName())) {
                staticFieldsList.add(fieldDescribe.getName());
            }
            if (formulaExpression != null && formulaExpression != '') {
                formulasMetadata.put(fieldDescribe.getName(), formulaExpression);
                // Formula Referenced Fields
                FormulaEval.FormulaInstance formulaInstance = Formula.builder().withReturnType(mapReturnTypeToEnum(fieldDescribe.getType().name()))
                                                                                .withType(objType)
                                                                                .withFormula(formulaExpression)
                                                                                .build();
                for (String refField : (Set<String>) formulaInstance.getReferencedFields()) {
                    if (!formulaFieldsReferencedMap.containsKey(refField)) {
                        formulaFieldsReferencedMap.put(refField, new List<String>());
                    }
                    formulaFieldsReferencedMap.get(refField).add(fieldDescribe.getName());
                    if (!formulaDependencies.containsKey(fieldDescribe.getName())) {
                        formulaDependencies.put(fieldDescribe.getName(), new List<String>());
                    }
                    formulaDependencies.get(fieldDescribe.getName()).add(refField);
                    if (!staticFieldsList.contains(refField)) {
                        staticFieldsList.add(refField);
                    }
                    if (refField.contains('.')) {
                        String fieldType = analyzeFieldType(SObjectType.AssortmentDetail__c.Name, refField);
                        asdFieldsMetadata.put(refField, fieldType);
                    }
                }
            }
            asdFieldsMetadata.put(fieldDescribe.getName(), String.valueOf(fieldDescribe.getType()));
        }
        system.debug('staticFieldsList >>> ' + JSON.serialize(staticFieldsList));
        String staticFields = String.join(staticFieldsList, ',');
        String masterStaticFields = String.join(fieldNames, ',');
        AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
        String assortmentMatrixGridLayout = gridLayout == null ? (currentAssortment.RecordType.DeveloperName == 'Target' ? assortSettings.assortmentMatrixTarget : assortSettings.assortmentMatrixNego) : gridLayout;
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, '', masterStaticFields, SObjectType.AssortmentDetail__c.Name, '', staticFields, assortmentMatrixGridLayout, true);
        Boolean isTargetMatrix = assortmentMatrixGridLayout == assortSettings.assortmentMatrixTarget;
        List<String> matrixProfiles = isTargetMatrix ? settings.assortmentMatrixTargetProfile : settings.assortmentMatrixProfile;
        Boolean isReadOnly = (matrixProfiles == null || matrixProfiles.isEmpty() || !matrixProfiles.contains(UserInfo.getProfileId()))
            || (currentAssortment.EDate__c < Date.today() && currentAssortment.Status__c == CommonConstants.PLV_ASSORTMENT_BU_STATUS_CLOSED)
            || (gridSettingsManager.isReadOnly);
        
        // Handle of Strat / Cplt available for the currentAssortment
        AssortmentServices assortmentServices = new AssortmentServices((new Map<Id, AssortmentDetail__c>([SELECT Id FROM AssortmentDetail__c WHERE Assortment__c = :currentAssortment.Id])).keySet());
        AssortmentServices.ResultWrapper rw = assortmentServices.getResultWrapperForAssortment(currentAssortment.BusinessUnitTarget__c);
        Map<Id, Map<String, BusinessUnit__c>> assortmentClustersMap = new Map<Id, Map<String, BusinessUnit__c>>();
        Map<Id, Map<String, BusinessUnit__c>> assortmentClustersCpltMap = new Map<Id, Map<String, BusinessUnit__c>>();
        Map<Id, Map<String, BusinessUnit__c>> assortmentClustersRefMap = new Map<Id, Map<String, BusinessUnit__c>>();
        Map<Id, Map<String, BusinessUnit__c>> assortmentClustersCpltRefMap = new Map<Id, Map<String, BusinessUnit__c>>();
        if (rw != null) {
            assortmentClustersMap = rw.categoryClientCategoryStratMap;
            assortmentClustersCpltMap = rw.categoryClientCategoryCpltMap;
            assortmentClustersRefMap = rw.categoryClientCategoryStratRefMap;
            assortmentClustersCpltRefMap = rw.categoryClientCategoryCpltRefMap;
        }
        system.debug('assortmentServices >>>> ' + JSON.serialize(assortmentServices));
        Set<Id> keysSet = new Set<Id>();
        keysSet.addAll(assortmentClustersMap.keySet());
        keysSet.addAll(assortmentClustersRefMap.keySet());
        Map<Id, List<BUClusterWrapper>> categoryBUClustersMap = new Map<Id, List<BUClusterWrapper>>(); // categoryId => list of clusters
        Map<Id, List<BUClusterWrapper>> categoryBUCpltMap = new Map<Id, List<BUClusterWrapper>>(); // categoryId => list of complements
        Map<Id, List<BUClusterWrapper>> categoryBUClustersRefMap = new Map<Id, List<BUClusterWrapper>>();
        Map<Id, List<BUClusterWrapper>> categoryBUCpltRefMap = new Map<Id, List<BUClusterWrapper>>();
        for (Id key : keysSet) {
            categoryBUClustersMap.put(key, new List<BUClusterWrapper>());
            categoryBUCpltMap.put(key, new List<BUClusterWrapper>());
            categoryBUClustersRefMap.put(key, new List<BUClusterWrapper>());
            categoryBUCpltRefMap.put(key, new List<BUClusterWrapper>());
            // Cluster
            if (assortmentClustersMap.get(key) != null) {
                for (BusinessUnit__c cluster : assortmentClustersMap.get(key).values()) {
                    categoryBUClustersMap.get(key).add(new BUClusterWrapper(cluster));
                }
            }
            // Cplt
            if (assortmentClustersCpltMap.get(key) != null) {
                for (BusinessUnit__c cluster : assortmentClustersCpltMap.get(key).values()) {
                    categoryBUCpltMap.get(key).add(new BUClusterWrapper(cluster));
                }
            }
            // Ref Cluster
            if (assortmentClustersRefMap.get(key) != null) {
                for (BusinessUnit__c cluster : assortmentClustersRefMap.get(key).values()) {
                    categoryBUClustersRefMap.get(key).add(new BUClusterWrapper(cluster));
                }
            }
            // Ref Cplt
            if (assortmentClustersCpltRefMap.get(key) != null) {
                for (BusinessUnit__c cluster : assortmentClustersCpltRefMap.get(key).values()) {
                    categoryBUCpltRefMap.get(key).add(new BUClusterWrapper(cluster));
                }
            }
        }
        //CALCULATE SUBTOTALS
        //GET NUMBER FIELDS
        List<String> fieldsToSum = new List<String>();
        
        // asdFieldsCalculationMap
        Map<String, List<Object>> asdFieldsCalculationMap = new Map<String, List<Object>>();
        // iterate grid fields
        for (GridSettingsManager.FieldWrapper fw : gridSettingsManager.GRID_FIELDS) {
            if (fw.isNumberField || fw.fieldType == DisplayType.BOOLEAN) {
                fieldsToSum.add(fw.fieldName);
            }
            if (formulaFieldsReferencedMap.containsKey(fw.fieldName)) {
                asdFieldsCalculationMap.put(fw.fieldName, formulaFieldsReferencedMap.get(fw.fieldName));
            }
            if (formulaFieldsReferencedMap.containsKey(fw.fieldName)) {
                for (String formulaField : formulaFieldsReferencedMap.get(fw.fieldName)) {
                    filteredFormulaFieldsDependencies.put(formulaField, formulaDependencies.get(formulaField));
                }
            }
        }
        system.debug('formulaDependencies >>> '  + JSON.serialize(formulaDependencies));
        system.debug('filteredFormulaFieldsDependencies >>> '  + JSON.serialize(filteredFormulaFieldsDependencies));
        // fill the calculation wrapper
        FormulaFieldSorter sorter = new FormulaFieldSorter(filteredFormulaFieldsDependencies);
        calculationWrapper.executionFormulaFieldOrder = sorter.getExecutionOrder();
        calculationWrapper.formulasMetadata = formulasMetadata;
        calculationWrapper.asdFieldsType = asdFieldsMetadata;
        calculationWrapper.asdFieldsCalculationMap = formulaFieldsReferencedMap;
        //HypothesisReport
        Map<String, Decimal> hypothesisReportMap = new Map<String, Decimal>();
        if (String.isNotBlank(currentAssortment.BusinessUnitTarget__r?.t_SalesCannibalizationRates__c)) {
            List<AssortmentSettings.SalesCannibalizationRatesWrapper> hypothesisReportWrapperList = String.isNotBlank(currentAssortment.BusinessUnitTarget__r.t_SalesCannibalizationRates__c) ? (List<AssortmentSettings.SalesCannibalizationRatesWrapper>) JSON.deserialize(currentAssortment.BusinessUnitTarget__r.t_SalesCannibalizationRates__c, List<AssortmentSettings.SalesCannibalizationRatesWrapper>.class) : new List<AssortmentSettings.SalesCannibalizationRatesWrapper>();
            for (AssortmentSettings.SalesCannibalizationRatesWrapper hypothesisReport : hypothesisReportWrapperList) {
                hypothesisReportMap.put(hypothesisReport.api + '' + currentAssortment.Id,
                                        String.isNotBlank(hypothesisReport.clientPerc) ? Decimal.ValueOf(hypothesisReport.clientPerc) : 
                                        (String.isNotBlank(hypothesisReport.stdPerc) ? Decimal.ValueOf(hypothesisReport.stdPerc) : null));
            }
        }
        System.debug('hypothesisReportMap: ' + JSON.serialize(hypothesisReportMap));
        //----------------------------------------------------End AK---------------------------------------------------------------
        SubTotalWrapper subTotalWrapper = new SubTotalWrapper();
        subTotalWrapper = getSubTotals(currentAssortment.Id, fieldsToSum);
        MainWrapper mainWrapper = new MainWrapper(currentAssortment, gridSettingsManager, isTargetMatrix,
                                                  isReadOnly, currentAssortment.BusinessUnitTarget__r.IsMultipleComplementary__c, categoryBUClustersMap, categoryBUCpltMap,
                                                  categoryBUClustersRefMap, categoryBUCpltRefMap, subTotalWrapper);
        if (currentAssortment.RecordType.DeveloperName == 'Negotiation') {
            List<Assortment__c> linkedAssortments = [SELECT Id FROM Assortment__c WHERE AssortmentNegotiationRef__c = :currentAssortment.Id LIMIT 1];
            mainWrapper.hasLinkedAssortments = !linkedAssortments.isEmpty();
        }
        // get all similar assortment (same year, same BU target)
        mainWrapper.relatedAssortments  = [SELECT Id, Name, LongName__c, Year__c, BusinessUnitTarget__c, BusinessUnitTarget__r.IsMultipleComplementary__c,
                                           Hierarchy__c, Status__c, RecordType.DeveloperName, EDate__c, ExtId__c
                                           FROM Assortment__c
                                           WHERE Year__c = :currentAssortment.Year__c
                                           AND BusinessUnitTarget__c = :currentAssortment.BusinessUnitTarget__c
                                           AND Id != :currentAssortment.Id];
        for(Assortment__c item : mainWrapper.relatedAssortments) {
            if(item.RecordType.DeveloperName == 'Simulation') {
                mainWrapper.relatedSimulations.add(item);
            }
        }
        mainWrapper.availableImportFields = (List<ImportFieldWrapper>)JSON.deserialize(assortSettings.availableImportFields, List<ImportFieldWrapper>.class);
        mainWrapper.calculationWrapper = calculationWrapper;
        mainWrapper.applyCalcFullYearQty_P1 = assortSettings.applyCalcFullYearQty_P1;
        mainWrapper.hypothesisReportMap = hypothesisReportMap;
        // getting all the products having ASD HLP
        List<Id> productsHavingASDHLP = new List<Id>();
        List<AggregateResult> hlpDetails = [SELECT Product__r.Consumer_Trade_Item__c productId
                                            FROM AssortmentDetail__c
                                            WHERE Product__r.Consumer_Trade_Item__c <> NULL
                                            AND Assortment__c = :assortmentId
                                            AND Version__c = NULL
                                            AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENTDETAIL_HIGHER_LEVEL_PACKAGING
                                            GROUP BY Product__r.Consumer_Trade_Item__c];
        if (hlpDetails != null && !hlpDetails.isEmpty()) {
            for (AggregateResult hlp : hlpDetails) {
                productsHavingASDHLP.add((Id) hlp.get('productId'));
            }
        }
        mainWrapper.productsHavingASDHLP = productsHavingASDHLP;
        // getting all the products having HLP
        List<Id> productsHavingHLP = new List<Id>();
        List<Product2> productsHLP = [SELECT Id, (SELECT Id FROM Produits1__r)
                                     FROM Product2
                                     WHERE Id IN (SELECT Product__c FROM AssortmentDetail__c
                                                  WHERE Assortment__c = :assortmentId
                                                  AND Version__c = NULL
                                                  AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENTDETAIL_REGULAR)];
        if (productsHLP != null && !productsHLP.isEmpty()) {
            for (Product2 product : productsHLP) {
                if (product.Produits1__r != null && !product.Produits1__r.isEmpty()) {
                    productsHavingHLP.add(product.Id);
                }
            }
        }
        mainWrapper.productsHavingHLP = productsHavingHLP;
        return JSON.serialize(mainWrapper);
    }
    
    public static String analyzeFieldType(String objectName, String fieldPath) {
        // Split the relationship chain based on '.'
        List<String> fieldChain = fieldPath.split('\\.');
        // Start with the initial object
        Schema.SObjectType currentObject = Schema.getGlobalDescribe().get(objectName);
        
        // Iterate over each field in the chain to reach the final field
        for (Integer i = 0; i < fieldChain.size(); i++) {
            String fieldName = fieldChain[i];
            if (fieldName.endsWith('__r')) {
                fieldName = fieldName.replace('__r', '__c');
            } else if (i != fieldChain.size() - 1) {
                fieldName = fieldName + 'Id';
            }
            
            // Get the fields map of the current object
            Map<String, Schema.SObjectField> fieldMap = currentObject.getDescribe().fields.getMap();
            
            if (fieldMap.containsKey(fieldName)) {
                // Describe the current field
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
                
                // If it's the last field in the chain, print its type
                if (i == fieldChain.size() - 1) {
                    return String.valueOf(fieldDesc.getType());
                } else if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                    // If it's a reference field, get the referenced object
                    List<Schema.SObjectType> referenceTo = fieldDesc.getReferenceTo();
                    if (!referenceTo.isEmpty()) {
                        // Use the first referenced object (if multiple, you can handle it accordingly)
                        currentObject = referenceTo[0];
                    } else {
                        return null;
                    }
                } else {
                    return null;
                }
            } else {
                return null;
            }
        }
        return null;
    }
        
    @AuraEnabled
    public static string initTreeGridData(String assortmentId, String gridLayout) {
        //GET ASSORTMENT
        Assortment__c currentAssortment = [SELECT Id, Name, LongName__c, Year__c, BusinessUnitTarget__c,
                                                     Hierarchy__c, Status__c, RecordType.DeveloperName, EDate__c, AssortmentNegotiationRef__c
                                                     FROM Assortment__c WHERE Id = :assortmentId];
        //GET GRIDSETTINGS
        AssortmentSettings assortSettings = AssortmentSettings.loadAssortmentSettings();
        String assortmentMatrixGridLayout = gridLayout == null ? (currentAssortment.RecordType.DeveloperName == 'Target' ? assortSettings.assortmentMatrixTarget : assortSettings.assortmentMatrixNego) : gridLayout;
        System.debug('assortmentMatrixGridLayout: ' + assortmentMatrixGridLayout);
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.Assortment__c.Name, '', '', SObjectType.AssortmentDetail__c.Name, '', '', assortmentMatrixGridLayout);
        //RESULT WRAPPER
        InitTreeGridWrapper initTreeGridWrapper = new InitTreeGridWrapper();
        initTreeGridWrapper.gridSettingsManager = gridSettingsManager;
        initTreeGridWrapper.currentAssortment = currentAssortment;
        return JSON.serialize(initTreeGridWrapper);
    }    
    
    @AuraEnabled
    public static String loadTreeGridData(String currentAssortmentJSON, List<String> fieldsToSum) {
        System.debug('fieldsToSum: ' + JSON.serialize(fieldsToSum));
        Assortment__c currentAssortment = (Assortment__c) JSON.deserialize(currentAssortmentJSON, Assortment__c.class);
        System.debug('currentAssortment: ' + JSON.serialize(currentAssortment));
        //GET TOTALS
        Id budgetHEId = String.isBlank(currentAssortment.Hierarchy__c) ? NegoptimHelper.getRootId() : currentAssortment.Hierarchy__c;
        
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {budgetHEId});
        
        Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
        Map<Id, Hierarchy__c> parentCategories = new Map<Id, Hierarchy__c>();
        Set<Id> relatedCategoryIds = new Set<Id>();
        Map<Id, Id> parentChildMap = new Map<Id, Id>();
        // navigate inversely from top level
        Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
        for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
            Hierarchy__c item = het.allElementsList.get(i);
            CategoryTreeWrapper node = new CategoryTreeWrapper(fieldsToSum);
            CategoryTreeWrapper parentNode = hierarchyTree.get(item.HierarchyParent__c);
            node.title = item.LongName__c;
            node.key = item.Id;
            node.folder = item.Level__c <= rootLevel + 1;
            if (parentNode != null) {
                node.path = parentNode.path + '' + item.Id;
                node.parentId = item.HierarchyParent__c;
            } else {
                node.path = item.Id;
                categoryTreeMap.put(item.Id, node);
            }
            hierarchyTree.put(item.Id, node);
        }
        for (Hierarchy__c item : het.allElementsList) {
            if (hierarchyTree.containsKey(item.HierarchyParent__c)) {
                hierarchyTree.get(item.HierarchyParent__c).children.add(hierarchyTree.get(item.Id));
            }
        }
        System.debug('categoryTreeMap: ' + JSON.serialize(categoryTreeMap));
        DataTreeGridWrapper dataWrapper = new DataTreeGridWrapper();
        //BUILD SUM TOTALS MAP
        List<String> conditions = new List<String>();
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        conditions.add('Hierarchy__c <> null');
        conditions.add('Assortment__c = \'' + String.escapeSingleQuotes(currentAssortment.Id) + '\'');
        conditions.add('Version__c = NULL');
        
        System.debug('conditions: ' + JSON.serialize(conditions));
        System.debug('fieldsToSum: ' + JSON.serialize(fieldsToSum));
        System.debug('currentAssortment.Id: ' + currentAssortment.Id);
        Map<String, Map<String, Decimal>> subTotalsMap = getTotalsMap(fieldsToSum, conditions);
        System.debug('subTotalsMap: ' + JSON.serialize(subTotalsMap));
        dataWrapper.subTotalsMap = subTotalsMap;
        dataWrapper.categoryTreeMap = categoryTreeMap;
        return JSON.serialize(dataWrapper);
    }
    
    @AuraEnabled
    public static String saveData(String recordsToUpsertJSON, String recordsToDeleteJSON) {
        String recordUpsertError = 'SUCCESS';
        String recordsToDeleteError = 'SUCCESS';
        if (recordsToUpsertJSON != '[]') {
            List<SObject> recordsToUpsert = new List<SObject>();
            List<SObject> recordsList = (List<SObject>) JSON.deserialize(recordsToUpsertJSON, List<SObject>.class);
            for (SObject record : recordsList) {
                recordsToUpsert.add(record);
            }
            recordUpsertError = upsertWithErrors(recordsToUpsert);
            if (recordUpsertError != 'SUCCESS') {
                return recordUpsertError;
            }
        }
        if (recordsToDeleteJSON != '[]') {
            List<SObject> recordsToDelete = (List<SObject>) JSON.deserialize(recordsToDeleteJSON, List<SObject>.class);
            recordsToDeleteError = deleteWithErrors(recordsToDelete, 'Id');
            if (recordsToDeleteError != 'SUCCESS') {
                return recordsToDeleteError;
            }
        }
        return 'SUCCESS';
    }
    
    public static String upsertWithErrors(List<SObject> sObjectList) {
        String errorMessage = 'SUCCESS';
        List<Database.UpsertResult> Results = Database.upsert(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.UpsertResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    
    public static String deleteWithErrors(List<SObject> sObjectList, String identifier) {
        String errorMessage = 'SUCCESS';
        List<Database.DeleteResult> Results = Database.delete(sObjectList, false);
        for (Integer j = 0; j < Results.size(); j++) {
            Database.DeleteResult sObjectListResult = Results.get(j);
            if (!sObjectListResult.isSuccess()) {
                String sObjectIdentifier = (String) sObjectList[j]?.get(identifier);
                errorMessage = '';
                Database.Error[] errors = sObjectListResult.getErrors();
                for (Database.Error err : errors) {
                    String msg = '' + err.getStatusCode();
                    if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        errorMessage += err.getMessage()  + ', ';
                    } else {
                        System.debug('errorMessage: ' + errorMessage);
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ',\n';
                    }
                }
            }
        }
        errorMessage = errorMessage.removeEnd(', ');
        return errorMessage;
    }
    /**
    * 
    * @description maps the String representation of the type of a formula field to its equivalent in the FormulaEval namespace
    * @return FormulaEval.FormulaReturnType
    */
    public static FormulaEval.FormulaReturnType mapReturnTypeToEnum(String returnType) {
        switch on returnType {
            when 'BOOLEAN' {
                return FormulaEval.FormulaReturnType.BOOLEAN;
            }
            when 'DATE' {
                return FormulaEval.FormulaReturnType.DATE;
            }
            when 'DATETIME' {
                return FormulaEval.FormulaReturnType.DATETIME;
            }
            when 'DECIMAL' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'DOUBLE' {
                return FormulaEval.FormulaReturnType.DOUBLE;
            }
            when 'ID' {
                return FormulaEval.FormulaReturnType.ID;
            }
            when 'INTEGER' {
                return FormulaEval.FormulaReturnType.INTEGER;
            }
            when 'LONG' {
                return FormulaEval.FormulaReturnType.LONG;
            }
            when 'CURRENCY' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'PERCENT' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'NUMBER' {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when 'STRING' {
                return FormulaEval.FormulaReturnType.STRING;
            }
            when 'TIME' {
                return FormulaEval.FormulaReturnType.TIME;
            }
            when else {
                // Default to STRING if the returnType doesn't match any known types
                return FormulaEval.FormulaReturnType.STRING;
            }
        }
    }

    @AuraEnabled
    public static String checkLogs() {
        List<Log__c> logs = [SELECT Id, 
                                       Name, 
                                       Class_Name__c, 
                                       NumberOfErrors__c, 
                                       NumberOfWarnings__c, 
                                       Status_Detail__c, 
                                       toLabel(Status__c),
                                       TotalJobItems__c, 
                                       Submitted_Date__c,
                                       Owner.Name
                                       FROM Log__c
                                       WHERE Class_Name__c = 'ASDImportBatch'
                                       ORDER BY CreatedDate DESC
                                       LIMIT 15];
        return JSON.serialize(logs);
    }

    @AuraEnabled
    public static Boolean checkCompletedBatches(String batchJobId){ 
        List<AsyncApexJob> batchJobList = [SELECT Id, Status FROM AsyncApexJob
                                           WHERE Id = :batchJobId LIMIT 1];
        if (batchJobList != null && !batchJobList.isEmpty() && batchJobList[0].Status == 'Completed') { 
            return true;
        }
        return false;
    }
    
    @AuraEnabled
    public static Id importAssortmentDetails(String batchIndex, String dataJson, String assortmentExtIdsJson) {
        system.debug('dataJson >>> ' + dataJson);
        Map<String, Object> importWrappersMap = (Map<String, Object>)JSON.deserializeUntyped(dataJson);
        Set<String> assortmentExtIds = (Set<String>)JSON.deserialize(assortmentExtIdsJson, Set<String>.class);
        system.debug('importWrappersMap >>> ' + importWrappersMap);
        Set<String> productEanSet = importWrappersMap != null ? importWrappersMap.keySet() : null;
        return Database.executeBatch(new ASDImportBatch(AssortmentMatrixCtrl.class.getName(), batchIndex, importWrappersMap, assortmentExtIds), 10);
    }
    
    @AuraEnabled
    public static void uploadFile(String fileName, String base64Data, String fileType, List<Id> assortmentIds) {
        try {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
            insert contentVersion;
            contentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            ContentDocument cd = [SELECT Id, Title FROM ContentDocument WHERE Id = :contentVersion.ContentDocumentId LIMIT 1];
            ContentDistribution contentDistribution = new ContentDistribution(ContentVersionId = contentVersion.Id, PreferencesPasswordRequired = false, Name = contentVersion.Title);
            insert contentDistribution;
            
            contentDistribution = [SELECT Id, Name, Password, ContentDocumentId, DistributionPublicUrl FROM ContentDistribution WHERE Id = :contentDistribution.Id];
            List<FileDirectory__c> fileDirectoryList = new List<FileDirectory__c>();
            for (Id assortmentId : assortmentIds) {
                FileDirectory__c fileDirectory = new FileDirectory__c(DocumentName__c = ContentVersion.Title,
                                                                 ContentDocumentId__c = contentDistribution.ContentDocumentId,
                                                                 DownloadURL__c = contentDistribution.DistributionPublicUrl,
                                                                 Comment__c = contentDistribution.Password,
                                                                      Assortment__c = assortmentId,
                                                                 RecordTypeId = NegoptimHelper.getObjectRecordTypeId(FileDirectory__c.SObjectType, 'Template'),
                                                                      SubType__c = 'Pre-Populated Template');
                fileDirectoryList.add(fileDirectory);
            }
            insert fileDirectoryList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * 
    * @description constructs a query to fetch assortment details based on filters
    * @return String the query
    */
    private static String buildAssortmentDetailQuery(Assortment__c currentAssortment, GridSettingsManager gridSettingsManager, String filtersJSON, String sortField) {
        List<String> conditions = getConditions(currentAssortment, filtersJSON);
        String hierarchyNameFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Hierarchy__c.Name) + '.Name';
        String versionFieldName = SObjectType.AssortmentDetail__c.fields.Version__c.Name;
        String clientCategoryField = SObjectType.AssortmentDetail__c.fields.ClientCategory__c.Name;
        String orderBy = versionFieldName + ' DESC'+ ', ' + clientCategoryField + ' NULLS LAST, ' + hierarchyNameFieldName;
        if (String.isNotBlank(sortField)) {
            orderBy += ', ' + sortField;
        } else {
            String productNameFieldName = NegoptimHelper.getFieldNameAsRelation(SObjectType.AssortmentDetail__c.fields.Product__c.Name) + '.Name';
            orderBy += ', ' + productNameFieldName + ' ASC';
        }
        String query = gridSettingsManager.buildQuery(null, conditions, orderBy);
        system.debug('query >>>> ' + query);
        return query;
     }
     
    private static List<String> getConditions(Assortment__c currentAssortment, String filtersJSON) {
        System.debug('filtersJSON: ' + filtersJSON);
        Id assortmentCategoryId = currentAssortment.Hierarchy__c == null ? NegoptimHelper.getRootIdByRT('Product') : currentAssortment.Hierarchy__c;
        // Check if het is null because we put it null in getHiearrchies method to reduce the view state
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});
        List<String> conditions = new List<String>();
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        conditions.add('Hierarchy__c <> null');
        conditions.add('Assortment__c = \'' + String.escapeSingleQuotes(currentAssortment.Id) + '\'');
        FilterWrapper filter = (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class);
        List<FilterSettings> filterSettings = new List<FilterSettings>();
        if (filter.dynamicSearch != '[]' && filter.dynamicSearch != null && filter.dynamicSearch != '') {
            Object filterObject = JSON.deserializeUntyped(filter.dynamicSearch);
            List<Object> filtersObjectsList = (List<Object>)filterObject;
            for (Object objt : filtersObjectsList) {
                Map<String, Object> item = (Map<String, Object>)objt;
                String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
                if (fieldName != null) {
                    String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                    String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                    boolean isEncrypted = item.containsKey('isEncrypted') ? Boolean.valueOf(item.get('isEncrypted')) : null;
                    String stringFieldType = item.containsKey('stringFieldType') ? String.valueOf(item.get('stringFieldType')) : null;
                    List<String> values = new List<String>();
                    if(item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                        List<Object> tempValues = (List<Object>) item.get('values');
                        for (Object val : tempValues) {
                            values.add(String.valueOf(val));
                        }
                    }
                    Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                    if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                        filterSettings.add(new FilterSettings(fieldName, null, isEncrypted, stringFieldType, null, value1, value2, values, userFilterable));
                    }
                }
            }
        }
        if (filter != null) {
            if (filter.searchValue != null && filter.searchValue != '') {
                String searchString = String.escapeSingleQuotes(filter.searchValue);
                String condition = '(Product__r.Name LIKE \'%' + searchString + '%\'';
                condition += ' OR Product__r.ProductCode LIKE \'%' + searchString + '%\'';
                if (SObjectType.Product2.fields.GTIN__c.isFilterable()) {
                    if (!SObjectType.Product2.fields.GTIN__c.isEncrypted()) {
                        condition += ' OR Product__r.GTIN__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'';
                    } else {
                        condition += ' OR Product__r.GTIN__c = \'' + String.escapeSingleQuotes(searchString) + '\'';
                    }
                }
                condition += ' OR Product__r.VIP__c LIKE \'%' + searchString + '%\'';
                condition += ' OR Hierarchy__r.Name LIKE \'%' + searchString + '%\')';
                conditions.add(condition);
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings) {
                    conditions.addAll(item.getQueryConditions());
                }
            }
            if (filter.hideBlankStatus) {
                if (filter.showIntroProducts) {
                    conditions.add('(Product__r.IsInnovation__c = TRUE OR Product__r.RecordType.DeveloperName = \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\' OR (ProductLifeStatusAss__c != NULL AND Product__r.IsInnovation__c = FALSE AND Product__r.RecordType.developerName <> \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\'))');
                } else {
                    conditions.add('ProductLifeStatusAss__c != NULL');
                }
            }
            if (filter.onlyShowIntroProducts) {
                System.debug('currentAssortment.Year__c: ' + currentAssortment.Year__c);
                conditions.add('(Product__r.RecordType.DeveloperName = \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\' OR CALENDAR_YEAR(Product__r.Market_Introduction_Date__c) = ' + Integer.valueOf(currentAssortment.Year__c) + ')');
            }
            if (!filter.isShowHistory) {
                conditions.add('Version__c = NULL');
            }
            if (filter.productLifeStatus != null && !filter.productLifeStatus.isEmpty()) {
                conditions.add('ProductLifeStatusAss__c IN (\'' + String.join(filter.productLifeStatus, '\', \'') + '\')');
            }
            if (filter.productTypes != null && !filter.productTypes.isEmpty()) {
                Boolean isStop = filter.productTypes.contains('Stop');
                if (isStop) {
                    filter.productTypes.remove(filter.productTypes.indexOf('Stop'));
                }
                String condition = '';
                if (!filter.productTypes.isEmpty()) {
                    condition = '(';
                    condition += '(Product__r.Market_End_of_Life_Date__c = NULL OR CALENDAR_YEAR(Product__r.Market_End_of_Life_Date__c) > ' + Integer.valueOf(currentAssortment.Year__c) + ')';
                    condition += ' AND Product__r.Product_Reference_Type__c IN (\'' + String.join(filter.productTypes, '\', \'') + '\')';
                    condition += ')';
                }
                if (isStop) {
                    condition += (filter.productTypes.isEmpty() ? '' : ' OR ') + ' (CALENDAR_YEAR(Product__r.Market_End_of_Life_Date__c) <= ' + Integer.valueOf(currentAssortment.Year__c) + ')';
                }
                system.debug('condition >>> ' + condition);
                conditions.add('(' + condition + ')');
            }
        }
        return conditions;
    }
    
    //LOAD ASSORTMENT FOR EXCEL DOWNLOAD
    @AuraEnabled
	public static String processRestForExcel(String assortmentId, String gridsettingsJSON, String restURL) {
        String detailQuery = '';
        if (String.isBlank(restURL)) {
            if (String.isBlank(assortmentId)) {
                return DataLoaderHelper.processRestForExcel(detailQuery, restURL, 'No-Id', SObjectType.AssortmentDetail__c.Name);
            }
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
            Assortment__c currentAssortment = [SELECT Id, Hierarchy__c FROM Assortment__c WHERE Id = :assortmentId];
            System.debug('currentAssortment: ' + JSON.serialize(currentAssortment));
            FilterWrapper filterWrapper = new FilterWrapper();
            filterWrapper.searchValue = '';
            filterWrapper.dynamicSearch = '';
            filterWrapper.productLifeStatus = new List<String>();
            filterWrapper.productTypes = new List<String>();
            filterWrapper.hideBlankStatus = false;
            filterWrapper.showIntroProducts = false;
            filterWrapper.onlyShowIntroProducts = false;
            filterWrapper.isShowHistory = false;
            detailQuery = buildAssortmentDetailQuery(currentAssortment, gridSettingsManager, JSON.serialize(filterWrapper), null);
        }
        String result = DataLoaderHelper.processRestForExcel(detailQuery, restURL, null, SObjectType.AssortmentDetail__c.Name);
        DataLoaderHelper.RestResponseBody resultWrapper = (DataLoaderHelper.RestResponseBody) JSON.deserialize(result, DataLoaderHelper.RestResponseBody.class);
        List<AssortmentDetailWrapper> asdList = new List<AssortmentDetailWrapper>();
        if (resultWrapper.records != null && !resultWrapper.records.isEmpty()) {
            List<AssortmentDetail__c> assortmentDetails = (List<AssortmentDetail__c>) resultWrapper.records;
        for (AssortmentDetail__c detail : assortmentDetails) {
            AssortmentDetailWrapper asdW = new AssortmentDetailWrapper(detail);
            asdList.add(asdW);
        }
        }
        return JSON.serialize(new ProcessRestResult(resultWrapper.totalSize, resultWrapper.done, resultWrapper.nextRecordsUrl, resultWrapper.error, asdList));
    }
    //LOAD ASSORTMENT BU DATA
    @AuraEnabled
    public static String loadData(String currentAssortmentJSON, Integer pageSize, Integer pageNumber, String gridsettingsJSON, String filtersJSON, String sortField, Boolean includeAllStatuses) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
            System.debug('gridSettingsManager: ' + JSON.serialize(gridSettingsManager));
            Assortment__c currentAssortment = (Assortment__c) JSON.deserialize(currentAssortmentJSON, Assortment__c.class);
            String query = buildAssortmentDetailQuery(currentAssortment, gridSettingsManager, filtersJSON, sortField);
            system.debug('query >>>> ' + query);
            ApexPages.StandardSetController assortmentDetailStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            assortmentDetailStdSetCtrl.setPageSize(Integer.valueOf(pageSize));
            assortmentDetailStdSetCtrl.setPageNumber(pageNumber);
            Map<Id, AssortmentDetailWrapper> asdWMap = new Map<Id, AssortmentDetailWrapper>();
            Set<Id> categorySet = new Set<Id>();
            if (assortmentDetailStdSetCtrl.getResultSize() != 0) {
                List<AssortmentDetail__c> assortmentDetails = assortmentDetailStdSetCtrl.getRecords();
                for (AssortmentDetail__c item : assortmentDetails) {
                    AssortmentDetailWrapper asdW;
                    categorySet.add(item.Hierarchy__c);
                    if (!asdWMap.containsKey(item.Product__c)) {
                        asdW = new AssortmentDetailWrapper(item);
                    } else {
                        asdW = asdWMap.get(item.Product__c);
                        if (item.Version__c != null) {
                            asdW.historyList.add(item);
                        }
                    }
                    asdWMap.put(item.Product__c, asdW);
                }
            }
            return JSON.serialize(new DataWrapper(asdWMap.values(), assortmentDetailStdSetCtrl.getResultSize()));
        } catch (Exception ex) {
            System.debug('Error load data ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public static Map<String, Map<String, Decimal>> getTotalsMap(List<String> fieldsToSum, List<String> conditions) {
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        System.debug('fieldsToSum: ' + JSON.serialize(fieldsToSum));
        //BUILD AGGREGATE QUERY
        String subTotalQuery = 'SELECT Hierarchy__c categoryId, Assortment__c assortmentId';
        for (String fieldName : fieldsToSum) {
            subTotalQuery += ', SUM(' + String.escapeSingleQuotes(fieldName) + ') ' + String.escapeSingleQuotes(fieldName.replace('.', ''));
        }
        subTotalQuery += ' FROM AssortmentDetail__c';
        subTotalQuery += ' WHERE ' + String.join(conditions, ' AND ');
        subTotalQuery += ' GROUP BY Hierarchy__c, Assortment__c';
        System.debug('subTotalQuery: ' + subTotalQuery);
        //ORGANIZE SUB TOTAL MAP
        for (AggregateResult result : Database.query(subTotalQuery)) {
            String key = Id.valueOf(String.valueOf(result.get('categoryId')));
            subTotalsMap.put(key, new Map<String, Decimal>());
            for (String fieldName : fieldsToSum) {
                    Decimal newValue = result.get(fieldName.replace('.', '')) == null ? 0.0 : Decimal.valueOf(String.valueOf(result.get(fieldName.replace('.', ''))));
                    subTotalsMap.get(key).put(fieldName.replace('.', ''), newValue);
            }
        }
        return subTotalsMap;
    }
    
    public static SubTotalWrapper getSubTotals(Id assortmentId, List<String> fieldsToSum) {
        SubTotalWrapper subTotalWrapper = new SubTotalWrapper();
        List<String> clientStatusToExcludeFromTotals = new List<String>{'ProbablyDeleted', 'Opportunity', ''};
        List<String> conditions = new List<String>();
        conditions.add('RecordType.DeveloperName = \'Regular\'');
        conditions.add('Hierarchy__c <> null');
        conditions.add('Assortment__c = \'' + String.escapeSingleQuotes(assortmentId) + '\'');
        conditions.add('Version__c = NULL');
        //BUILD STRAT COUNT MAP
        String countQuery = 'SELECT Hierarchy__c, ProductCluster__c, ProductClusterASDNego__c, ClientCategory__c, ProductLifeStatusAss__c ';
        if (!fieldsToSum.isEmpty()) {
            countQuery += ',' + String.join(fieldsToSum, ',');
        }
        countQuery += ' FROM AssortmentDetail__c';
        countQuery += ' WHERE ' + String.join(conditions, ' AND ');
        Map<Id, Map<String, Integer>> stratCountMap = new Map<Id, Map<String, Integer>>();
        List<AssortmentDetail__c> details = Database.query(countQuery); 
        subTotalWrapper.details = details;
        return subTotalWrapper;
    }
    
    @AuraEnabled
    public static String changeAssortmentStatus(String assortmentId, String status) {
        String errorMessage = '';
        Assortment__c assortment = [SELECT Id, Status__c, RecordType.DeveloperName FROM Assortment__c WHERE Id = :assortmentId LIMIT 1];
        // Existing behavior
        if (assortment.Status__c != status) {
            Database.SaveResult result = Database.update(new Assortment__c(Id = assortmentId, Status__c = status), false);
            if (!result.isSuccess()) {
                Database.Error[] errors = result.getErrors();
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
        // New behavior only for Negotiation
        } else if (assortment.RecordType.DeveloperName == 'Negotiation' && status == 'Validate') {
            List<AssortmentDetail__c> asdToUpdate = [SELECT Id, Status__c FROM AssortmentDetail__c WHERE Assortment__c = :assortmentId AND Version__c = NULL AND Status__c = 'InPreparation'];
            for (AssortmentDetail__c asd : asdToUpdate) {
                asd.Status__c = 'Validate';
            }
            if (!asdToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(asdToUpdate, false);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        for (Database.Error err : result.getErrors()) {
                            errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                    }
                }
            }
        }
        return errorMessage;
    }
    
    @AuraEnabled
    public static String save(String dataToSave) {
        System.debug('dataToSave: ' + dataToSave);
        List<AssortmentDetail__c> ASDToUpdate = (List<AssortmentDetail__c>) JSON.deserialize(dataToSave, List<AssortmentDetail__c>.class);
        List<Database.SaveResult> results = Database.update(ASDToUpdate, false);
        String errorMessage = '';
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                Database.Error[] errors = result.getErrors();
                for (Database.Error err : errors) {
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
        }
        return errorMessage;
    }
    
    @AuraEnabled
    public static String fakeSave(String assortmentDetailJSON, List<String> fieldsToSum) {
        AssortmentDetail__c assortmentDetail = (AssortmentDetail__c) JSON.deserialize(assortmentDetailJSON, AssortmentDetail__c.class);
        SavePoint sp = Database.setSavepoint();
        String[] assortmentDetailFields = new String[] {
            SObjectType.AssortmentDetail__c.fields.ProductLifeStatusAss__c.Name,
            SObjectType.AssortmentDetail__c.fields.BusinessUnitCluster__c.Name,
            SObjectType.AssortmentDetail__c.fields.StartDate__c.Name,
            SObjectType.AssortmentDetail__c.fields.Status__c.Name,
            SObjectType.AssortmentDetail__c.fields.KeyNote__c.Name,
            SObjectType.AssortmentDetail__c.fields.RecordDate__c.Name,
            SObjectType.AssortmentDetail__c.fields.ReleaseDate__c.Name,
            SObjectType.AssortmentDetail__c.fields.SOSNumberNego__c.Name
        };
        if (NegoptimHelper.checkUpdatibility(AssortmentDetail__c.SObjectType, assortmentDetailFields)) {
            Database.SaveResult result = Database.update(assortmentDetail, false);
            String errorMessage = '';
                if (!result.isSuccess()) {
                    Database.Error[] errors = result.getErrors();
                    for (Database.Error err : errors) {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
            }
            if (!String.isBlank(errorMessage)) {
                return 'ERROR: ' + errorMessage;
            }
        }
        String query = 'SELECT Id, Product__c, Hierarchy__c, Assortment__c, ProductCluster__c, ProductLifeStatusAss__c';
        if (!fieldsToSum.isEmpty()) {
            query += ',' + String.join(fieldsToSum, ',');
        }
        query += ' FROM AssortmentDetail__c';
        query += ' WHERE Id = \'' + assortmentDetail.Id + '\'';
        assortmentDetail = Database.query(query);
        Database.rollback(sp);

        return JSON.serialize(assortmentDetail);
    }
    
    @AuraEnabled
    public static String getSwitchProducts(Id productId) {
        List<SwitchProductWrapper> switchProductsList = new List<SwitchProductWrapper>();
        // check security on access product fields
        String[] productFields = new String[] {
            SObjectType.Product2.fields.Name.Name,
            SObjectType.Product2.fields.Reference_Product__c.Name,
            SObjectType.Product2.fields.Category__c.Name
        };
                    // check security on access Hierarchy__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Hierarchy__c.fields.Name.Name
        };
        if (NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields)
            && NegoptimHelper.checkAccessibility(Hierarchy__c.SObjectType, orgaHEFields))
        {
            for (Product2 item : [SELECT Name, Reference_Product__c, Reference_Product__r.Name
                                FROM Product2
                                WHERE Reference_Product__c = :productId
                                ORDER BY Category__r.Name, Name ASC])
            {
                switchProductsList.add(new SwitchProductWrapper(item.Reference_Product__r, item));
            }
        }
        return JSON.serialize(switchProductsList);
    }
    
    @AuraEnabled
    public static String getHLPProducts(Id assortmentId, Id productId) {
        List<HigherLevelPackagingWrapper> higherLevelPackagingWrapperList = new List<HigherLevelPackagingWrapper>();
        List<AssortmentDetail__c> asdList = [SELECT Id, Product__r.Name, ProductLifeStatusAss__c,  Status__c, IsNewProduct__c, StartDate__c, BusinessUnitCluster__c,
                                             Assortment__c
                                             FROM AssortmentDetail__c
                                             WHERE Product__c = :productId
                                             AND Assortment__c = :assortmentId
                                             AND Version__c = NULL
                                             AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENTDETAIL_REGULAR
                                             LIMIT 1];
        if (!asdList.isEmpty()) {
            NegoptimSettings settings = (NegoptimSettings) JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
            for (Product2 productHLP : [SELECT Id, Name, GTIN__c, ProductCode, IsMaster_Higher_Level_Packaging__c,
                                        Element_nb__c, toLabel(PCB__c), PCBElementNb__c,
                                        (SELECT Id
                                         FROM ASDProduct__r
                                         WHERE Assortment__c = :assortmentId
                                         AND Version__c = NULL
                                         AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENTDETAIL_HIGHER_LEVEL_PACKAGING
                                         LIMIT 1)
                                        FROM Product2
                                        WHERE Consumer_Trade_Item__c = :productId
                                        AND RecordTypeId = :settings.higherLevelPackagingRecordTypeId
                                        ORDER BY IsMaster_Higher_Level_Packaging__c DESC, Name])
            {
                HigherLevelPackagingWrapper hlpw = new HigherLevelPackagingWrapper(productHLP);
                higherLevelPackagingWrapperList.add(hlpw);
            }
        }
        return JSON.serialize(higherLevelPackagingWrapperList);
    }
    
    public class MainWrapper {
        public Assortment__c currentAssortment {get; set;}
        public GridSettingsManager gridSettingsManager {get;set;}
        public Boolean isTargetMatrix {get;set;}
        public Boolean isReadOnly {get;set;}
        public Boolean isAdmin {get;set;}
        public Boolean multipleComplementary {get;set;}
        public Boolean applyCalcFullYearQty_P1 {get;set;}
        public Map<Id, List<BUClusterWrapper>> categoryBUClustersMap {get;set;}
        public Map<Id, List<BUClusterWrapper>> categoryBUCpltMap {get;set;}
        public Map<Id, List<BUClusterWrapper>> categoryBUClustersRefMap {get;set;}
        public Map<Id, List<BUClusterWrapper>> categoryBUCpltRefMap {get;set;}
        public String HLPRecordType {get;set;}
        public List<String> fieldsToImport {get;set;}
        public SubTotalWrapper subTotalWrapper {get;set;}
        public List<ImportFieldWrapper> availableImportFields {get; set;}
        public List<Id> productsHavingASDHLP {get; set;}
        public List<Id> productsHavingHLP {get; set;}
        public List<Assortment__c> relatedAssortments {get; set;}
        public List<Assortment__c> relatedSimulations {get; set;}
        public CalculationWrapper calculationWrapper {get;set;}
        public Map<String, Decimal> hypothesisReportMap {get;set;}
        public String prefix {get; set;}
        public Boolean hasLinkedAssortments {get; set;}
        
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
        
        public MainWrapper(Assortment__c currentAssortment, GridSettingsManager gridSettingsManager, Boolean isTargetMatrix, Boolean isReadOnly, Boolean multipleComplementary,
                        Map<Id, List<BUClusterWrapper>> categoryBUClustersMap, Map<Id, List<BUClusterWrapper>> categoryBUCpltMap,
                        Map<Id, List<BUClusterWrapper>> categoryBUClustersRefMap, Map<Id, List<BUClusterWrapper>> categoryBUCpltRefMap, SubTotalWrapper subTotalWrapper)
        {
            this.subTotalWrapper = subTotalWrapper;
            this.currentAssortment = currentAssortment;
            this.gridSettingsManager = gridSettingsManager;
            this.isTargetMatrix = isTargetMatrix;
            this.isReadOnly = isReadOnly;
            this.isAdmin = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name.contains('Admin');
            this.multipleComplementary = multipleComplementary;
            this.categoryBUClustersMap = categoryBUClustersMap;
            this.categoryBUCpltMap = categoryBUCpltMap;
            this.categoryBUClustersRefMap = categoryBUClustersRefMap;
            this.categoryBUCpltRefMap = categoryBUCpltRefMap;
            this.HLPRecordType = Schema.SObjectType.AssortmentDetail__c.getRecordTypeInfosByName().get('HigherLevelPackaging').getRecordTypeId();
            this.fieldsToImport = new List<String> {
                SObjectType.AssortmentDetail__c.fields.ProductGTIN__c.Name,
                SObjectType.AssortmentDetail__c.fields.AvgWeeklySalesClient__c.Name,
                SObjectType.AssortmentDetail__c.fields.StartDate__c.Name
            };
            this.availableImportFields = new List<ImportFieldWrapper>();
            this.relatedAssortments = new List<Assortment__c>();
            this.relatedSimulations = new List<Assortment__c>();
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.hasLinkedAssortments = false;
        }
    }
    
    public class ImportFieldWrapper {
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        public Boolean isAdmin {get; set;}
        public Boolean isUser {get; set;}
        
        public ImportFieldWrapper(String name, String label, Boolean admin, Boolean user) {
            this.fieldName = name;
            this.fieldLabel = label;
            this.isAdmin = admin;
            this.isUser = user;
        }
    }
    
    public class DataWrapper {
        public List<AssortmentDetailWrapper> assortmentDetails {get; set;}
        public Integer totalSize {get;set;}

        public DataWrapper(List<AssortmentDetailWrapper> assortmentDetails, Integer totalSize) {
            this.assortmentDetails = assortmentDetails;
            this.totalSize = totalSize;
        }
    }
    
    //ASSORTMENT DETAIL WRAPPER
    public class AssortmentDetailWrapper {
        
        public AssortmentDetail__c detail {get; set;}
        public List<AssortmentDetail__c> historyList {get; set;}
        
        public AssortmentDetailWrapper() {
            this.detail = new AssortmentDetail__c();
            this.historyList = new List<AssortmentDetail__c>();
        }
        
        public AssortmentDetailWrapper(AssortmentDetail__c detail) {
            this.detail = detail;
            this.historyList = new List<AssortmentDetail__c>();
        }
    }
    
    //CLUSTER WRAPPER
    public class BUClusterWrapper {
        public BusinessUnit__c cluster {get; set;}
        public Integer index {get; set;}
        public String clientCategory {get; set;}
        // Specified for the strat and cplt that's closed
        public Boolean isDisabled {get; set;}
        public Boolean hasHistory {get; set;}
        
        public BUClusterWrapper(BusinessUnit__c cluster) {
            this.cluster = cluster;
            this.clientCategory = cluster.ClientCategory__c;
            this.index = cluster == null ? 0 : Integer.valueOf(cluster.AssortmentStrat__c.replace('Strat', '').replace('Cplt', ''));
        }
    }
    
    public class FilterWrapper {
        public String searchValue {get;set;}
        public String dynamicSearch {get;set;}
        public List<String> productLifeStatus {get;set;}
        public List<String> productTypes {get;set;}
        public Boolean hideBlankStatus {get;set;}
        public Boolean showIntroProducts {get;set;}
        public Boolean onlyShowIntroProducts {get;set;}
        public Boolean isShowHistory {get;set;}
    }
    
    public class FilterSettings {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public Boolean isEncrypted { get; set; }
        public String stringFieldType { get; set; }
        public List<SelectOption> pickListValues { get; set; }
        public String value1 { get; set; }
        public String value2 { get; set; }
        public List<String> values { get; set; }
        Boolean userFilterable { get; set; }
        public List<String> getQueryConditions() {
            try {
                List<String> conditions = new List<String>();
                if (values != null && !values.isEmpty()) {
                    if (stringFieldType == 'REFERENCE') {
                        if (fieldName.toLowerCase() == 'recordtypeid') {
                            List<String> stringifiedValues = (List<String>) JSON.deserialize(JSON.serialize(values), List<String>.class);
                            List<String> escapedStringifiedValues = new List<String>();
                            for (String value : stringifiedValues) {
                                value = value == 'Principal' || value == 'Master' ? '' : value;
                                escapedStringifiedValues.add(String.escapeSingleQuotes(value).trim());
                            }
                            conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.DeveloperName IN (\'' + String.join(escapedStringifiedValues, '\', \'') + '\')');
                        } else {
                            if (isEncrypted == null || isEncrypted) {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                            } else {
                                conditions.add((fieldName.endsWithIgnoreCase('__c') ? fieldName.replace('__c', '__r') : fieldName.replace('Id', '').replace('id', ''))+'.Name LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                            }
                        }
                    }
                    if (stringFieldType == 'ID') {
                        List<Id> fieldpicklistValues = new List<Id>();
                        for (Object item : values) {
                            try {
                                fieldpicklistValues.add(Id.valueOf(String.escapeSingleQuotes(String.valueOf(item).trim())));
                            } catch (Exception ex) {
                            }
                        }
                        conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                    }
                    if (stringFieldType == 'PICKLIST' || stringFieldType == 'MULTIPICKLIST' || stringFieldType == 'COMBOBOX' || stringFieldType == 'RECORDTYPE' || stringFieldType == 'BOOLEAN') {
                        List<String> fieldpicklistValues = new List<String>();
                        for (Object item : values) {
                            fieldpicklistValues.add(String.escapeSingleQuotes(String.valueOf(item)));
                        }
                        if (stringFieldType == 'BOOLEAN') {
                            conditions.add(fieldName + ' IN (' + String.join(fieldpicklistValues, ', ')+')');
                        } else if (stringFieldType == 'RECORDTYPE') {
                            conditions.add('RecordType.DeveloperName IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else if (stringFieldType == 'PICKLIST' || stringFieldType == 'COMBOBOX') {
                            conditions.add(fieldName + ' IN (\'' + String.join(fieldpicklistValues, '\',\'')+'\')');
                        } else {
                            conditions.add(fieldName + ' INCLUDES (\'' + String.join(fieldpicklistValues, ';')+'\')');
                        }
                    }
                    if (stringFieldType == 'STRING') {
                        if (isEncrypted == null || isEncrypted) {
                            conditions.add(fieldName + ' = \'' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'\'');
                        } else {
                            conditions.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(String.valueOf(values[0])).trim()+'%\'');
                        }
                    }
                }
                if (value1 != null || value2 != null) {
                    if (stringFieldType == 'CURRENCY' || stringFieldType == 'INTEGER' || stringFieldType == 'DOUBLE' || stringFieldType == 'LONG' || stringFieldType == 'PERCENT') {
                        if (value1 != null) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (value2 != null) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                    if (stringFieldType == 'DATETIME') {
                        if (value1 != null) {
                            List<String> splitedDate = String.valueOf(value1).split('-');
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                        if (value2 != null) {
                            List<String> splitedDate = String.valueOf(value2).split('-');
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.newInstance(Integer.valueOf(splitedDate[0]), Integer.valueOf(splitedDate[1]), Integer.valueOf(splitedDate[2]))).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                        }
                    }
                    if (stringFieldType == 'DATE') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + ((Datetime)Date.valueOf(String.valueOf(value1))).formatGMT('yyyy-MM-dd'));
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + ((Datetime)Date.valueOf(String.valueOf(value2))).formatGMT('yyyy-MM-dd'));
                        }
                    }
                    if (stringFieldType == 'TIME') {
                        if (String.isNotBlank(value1)) {
                            conditions.add(fieldName + ' >= ' + value1);
                        }
                        if (String.isNotBlank(value2)) {
                            conditions.add(fieldName + ' <= ' + value2);
                        }
                    }
                }
                return conditions;
            }catch (Exception ex) {
                System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
                throw new AuraHandledException(ex.getMessage());
            }
        }
        public FilterSettings(String fieldName, String fieldLabel, Boolean isEncrypted, String stringFieldType, List<SelectOption> pickListValues, String value1, String value2, List<String> values, Boolean userFilterable) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.isEncrypted = isEncrypted;
            // Get the SObject Describe for the object
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.AssortmentDetail__c.Name).getDescribe();
            // Get the field describe for the specified field
            Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();
            // Get the data type of the field
            Schema.DisplayType fieldType = fieldDescribe.getType();
            system.debug('fieldName is '+fieldName);
            this.stringFieldType = fieldType + '';
            system.debug('stringFieldType is '+this.stringFieldType);
            this.pickListValues = pickListValues;
            this.value1 = value1;
            this.value2 = value2;
            this.values = values;
            this.userFilterable = userFilterable;
        }
    }
    
    public class SwitchProductWrapper {
        public Product2 currentProduct {get; set;}
        public Product2 newProduct;
        
        public SwitchProductWrapper(Product2 currentProduct, Product2 newProduct) {
            this.currentProduct = currentProduct;
            this.newProduct = newProduct;
        }
    }
    
    public class NegoptimSettings {
        public String sBusinessType {get; set;}
        // Grid Settings
        public String assortmentMatrixGridLayout {get; set;}
        public String assortmentMatrixTargetGridLayout {get; set;}
        
        // Grid Settings Profiles
        public String[] assortmentMatrixProfile {get; set;}
        public String[] assortmentMatrixTargetProfile {get; set;}
        
        // Page Settings
        public Boolean openPagesFilterSectionByDefault {get; set;} // controls if the filter section is open or closed by default in all pages and components of the app
        public Boolean manageAssortByPersonalizedCategory {get; set;}
        // higer level packaging Id
        public Id higherLevelPackagingRecordTypeId {get; set;}
    }
    
    public class HigherLevelPackagingWrapper {
        public Product2 productHLP {get; set;}
        public AssortmentDetail__c asdHLP {get; set;}
        public Boolean isSelected {get; set;}
        
        public HigherLevelPackagingWrapper(Product2 productHLP) {
            this.productHLP = productHLP;
            this.asdHLP = productHLP.ASDProduct__r.isEmpty() ? null : productHLP.ASDProduct__r[0];
            this.isSelected = this.asdHLP != null;
        }
    }
    
     public class CalculationWrapper {
         public Map<String, String> asdFieldsType {get; set;}
         public Map<String, List<Object>> asdFieldsCalculationMap {get; set;}
         public List<String> executionFormulaFieldOrder {get; set;}
         public Map<String, Object> formulasMetadata {get; set;}
    }
    
    public class ProcessRestResult {
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public String nextRecordsUrl {get; set;}
        public String error {get; set;}
        public List<AssortmentDetailWrapper> records {get; set;}
        
        public ProcessRestResult(Integer totalSize, Boolean done, String nextRecordsUrl, String error, List<AssortmentDetailWrapper> records) {
            this.totalSize = totalSize;
            this.done = done;
            this.nextRecordsUrl = nextRecordsUrl;
            this.error = error;
            this.records = records;
        }
     }
    
    //MAP : <CATEGORY --> <FIELD --> VALUE>>
    public class SubTotalWrapper {
        public Map<String, Map<String, Decimal>> subTotalsMap {get;set;}
        public List<AssortmentDetail__c> details {get;set;}
    }
    
    public class InitTreeGridWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public Assortment__c currentAssortment {get; set;}
        public String assortmentObjLabel {get; set;}
        public InitTreeGridWrapper() {
            this.assortmentObjLabel = SObjectType.Assortment__c.getLabel();
        }
    }

    
    public class DataTreeGridWrapper {
        public Map<String, Map<String, Decimal>> subTotalsMap {get; set;}
        public Map<Id, CategoryTreeWrapper> categoryTreeMap {get; set;}
        public DataTreeGridWrapper() {

        }
    }
    
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Decimal> sums {get; set;}

        public CategoryTreeWrapper(List<String> fieldNames) {
            this.children = new List<CategoryTreeWrapper>();
            this.sums = new Map<String, Decimal>();
            for (String fieldName : fieldNames) {
                this.sums.put(fieldName, 0);
            }
        }
    }
    public class FormulaFieldSorter {
        // A map of formula fields and their dependencies
        Map<String, List<String>> formulaDependencies;
        
        public FormulaFieldSorter(Map<String, List<String>> dependencies) {
            formulaDependencies = dependencies;
        }
        
        public List<String> getExecutionOrder() {
            List<String> sortedOrder = new List<String>();
            Set<String> visited = new Set<String>();
            Set<String> recursionStack = new Set<String>();
            
            for (String formulaField : formulaDependencies.keySet()) {
                if (!visited.contains(formulaField)) {
                    if (!topologicalSort(formulaField, visited, recursionStack, sortedOrder)) {
                        throw new AuraHandledException('Cyclic dependency found in formula fields.');
                    }
                }
            }
            return sortedOrder;
        }
        
        private Boolean topologicalSort(String formulaField, Set<String> visited, Set<String> recursionStack, List<String> sortedOrder) {
            if (recursionStack.contains(formulaField)) {
                return false; // Cyclic dependency
            }
            
            if (!visited.contains(formulaField)) {
                visited.add(formulaField);
                recursionStack.add(formulaField);
                
                if (formulaDependencies.containsKey(formulaField)) {
                    for (String dependency : formulaDependencies.get(formulaField)) {
                        if (!topologicalSort(dependency, visited, recursionStack, sortedOrder)) {
                            return false; // Cyclic dependency
                        }
                    }
                }
                
                recursionStack.remove(formulaField);
                sortedOrder.add(formulaField);
            }
            
            return true;
        }
    }

}