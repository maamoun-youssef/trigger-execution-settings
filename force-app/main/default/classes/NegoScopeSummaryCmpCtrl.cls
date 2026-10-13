/*
 * @author ULiT
 * @date 17-07-2024
 * @description apex controller to Negoscope summary
 */ 
public with sharing class NegoScopeSummaryCmpCtrl {
    @AuraEnabled
    public static string getData(String recordId) {
        try {
            // Example SOQL query to retrieve the product attributes (adjust field and object names as per your schema)
            NegoScope__c negoScope = [SELECT Id, t_ProductAttributes__c FROM NegoScope__c WHERE Id = :recordId LIMIT 1];
            // Check if the product attributes field is null
            NegoScopeServices.ProductAttributeWrapper filterAttr = String.isNotBlank(negoScope.t_ProductAttributes__c) ? (NegoScopeServices.ProductAttributeWrapper) JSON.deserialize(negoScope.t_ProductAttributes__c, NegoScopeServices.ProductAttributeWrapper.class) : null;
            List<NegoScopeServices.ProductAttributeSettingWrapper> productAttributesList = filterAttr.productAttributes;
            List<String> nsFields = new List<String>(); 
            Map<String, List<Id>> productAttributeReferenceIdsMap = new Map<String, List<Id>>();
            Map<String, String> fieldToReferenceMap = new Map<String, String>();
            DescribeSObjectResult describeResultNegoScope = NegoScope__c.SObjectType.getDescribe();
            DescribeSObjectResult describeResultProduct = Product2.SObjectType.getDescribe();
            DescribeSObjectResult describeResultPG = PG__c.SObjectType.getDescribe();
            Boolean isReference = false;
            for (NegoScopeServices.ProductAttributeSettingWrapper item : productAttributesList) {
                if (String.isBlank(item.fieldName)) continue;
                if (item.isField && String.isNotBlank(item.fieldValue) && !nsFields.contains(item.fieldValue)) {
                    isReference = describeResultNegoScope.fields.getMap().get(item.fieldValue).getDescribe().getType() == Schema.DisplayType.REFERENCE;
                    Boolean isPicklist = describeResultNegoScope.fields.getMap().get(item.fieldValue).getDescribe().getType() == Schema.DisplayType.PICKLIST;
                    if (isReference) {
                        if (item.fieldValue.endsWith('Id')) {
                            nsFields.add((item.fieldValue.replace('Id', '.Name')));
                        } else {
                            nsFields.add((item.fieldValue.replace('__c', '__r.Name')));
                        }
                    } else if (isPicklist) {
                        nsFields.add('toLabel(' + item.fieldValue + ')');
                    } else {
                        nsFields.add(item.fieldValue);
                    }
                } else if (item.operationType == 'Value') {
                    String productAttributeReferenceField;
                    isReference = describeResultPG.fields.getMap().get(item.fieldName).getDescribe().getType() == Schema.DisplayType.REFERENCE;
                    if (isReference && item.fieldName.endsWith('__c')) {
                        String objectName = Id.valueOf(item.fieldValue).getSObjectType().getDescribe().getName();
                        if (!productAttributeReferenceIdsMap.containsKey(objectName)) {
                            productAttributeReferenceIdsMap.put(objectName, new List<Id>());
                        }
                        productAttributeReferenceIdsMap.get(objectName).add(item.fieldValue);
                    }
                }
            }
            // Query records based on IDs and object names
            Map<String, String> productAttributeReferenceValuesMap = new Map<String, String>();
            for (String objectName : productAttributeReferenceIdsMap.keySet()) {
                String referenceIds = '\'' + String.join(productAttributeReferenceIdsMap.get(objectName), '\',\'') + '\'';
                String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN (' + referenceIds + ')';
                List<SObject> records = Database.query(query);
                for (SObject record : records) {
                    String referenceId = (String) record.get('Id');
                    String referenceValue = (String) record.get('Name');
                    productAttributeReferenceValuesMap.put(referenceId, referenceValue);
                }
            }
            List<String> fieldsToCheck = new List<String> {
                SObjectType.NegoScope__c.fields.Supplier__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllBrands__c.Name,
                SObjectType.NegoScope__c.fields.IncludeNewBrands__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllProducts__c.Name,
                SObjectType.NegoScope__c.fields.IncludeNewProducts__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllHEs__c.Name,
                SObjectType.NegoScope__c.fields.t_ProductAttributes__c.Name
            };
            // Add missing fields
            for (String field : fieldsToCheck) {
                if (!nsFields.contains(field)) {
                    nsFields.add(field);
                }
            }
            String query = 'SELECT Id';
            if (!nsFields.isEmpty()) {
                query += ', ' + String.join(nsFields, ', ');
            }
            query += ' FROM NegoScope__c WHERE Id = \'' + recordId + '\' LIMIT 1';
            List<NegoScope__c> result = Database.query(query);
            negoScope = result[0];
            List<NSHE__c> includedHEs = [SELECT Id, Hierarchy__c, Hierarchy__r.Name, Hierarchy__r.Code__c, Hierarchy__r.Level__c, Hierarchy__r.Path__c, Choice__c,
                                         Hierarchy__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.Name, Hierarchy__r.HierarchyParent__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.HierarchyParent__r.Name, Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Name,Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Id
                                         FROM NSHE__c
                                         WHERE NegoScope__c = :recordId
                                         AND Choice__c = 'Include'
                                         AND Hierarchy__c <> NULL];
            List<NSHE__c> excludedHEs = [SELECT Id, Hierarchy__c, Hierarchy__r.Name, Hierarchy__r.Code__c, Hierarchy__r.Level__c,  Hierarchy__r.Path__c, Choice__c,
                                         Hierarchy__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.Name, Hierarchy__r.HierarchyParent__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.HierarchyParent__r.Name, Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Id,
                                         Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Name,Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.Id
                                         FROM NSHE__c WHERE NegoScope__c = :recordId
                                         AND Choice__c = 'Exclude'
                                         AND Hierarchy__c <> NULL];
            List<NSHE__c> NSHEList = new List<NSHE__c>();
            NSHEList.addAll(includedHEs);
            NSHEList.addAll(excludedHEs);
            List<NegoScopeServices.NSHEWrapper> NSHEWrapperList = new List<NegoScopeServices.NSHEWrapper>();
            for (NSHE__c item : NSHEList) {
                NSHEWrapperList.add(new NegoScopeServices.NSHEWrapper(item.Hierarchy__c, item.Hierarchy__r.Name, item.Hierarchy__r.HierarchyParent__c,
                                                                      item.Hierarchy__r.HierarchyParent__r.Name, item.Hierarchy__r.Code__c,
                                                                      item.Hierarchy__r.Path__c, Integer.valueOf(item.Hierarchy__r.Level__c), item.Choice__c));
            }
            List<NSBRA__c> includedBrands = [SELECT Id, Brand__c, Brand__r.Name
                                             FROM NSBRA__c
                                             WHERE NegoScope__c = :recordId
                                             AND Brand__c <> NULL];
            List<Id> brandIdList = new List<Id>();
            for (NSBRA__c NSBRA : includedBrands) {
                brandIdList.add(NSBRA.Brand__c);
            }
            // load products informations
            Integer excludedPGsFromFilter = 0, includedPGsHorsFilter = 0;
            ProductSettings productSettings = ProductSettings.loadProductSettings();
            NegoScopeServices.PGQueryConditionsWrapper pgQueryConditions = NegoScopeServices.buildPGQueryConditions(JSON.serialize(negoScope), null, negoScope.t_ProductAttributes__c, JSON.serialize(brandIdList), JSON.serialize(NSHEWrapperList), productSettings.productRecordTypes);
            List<String> respectFilterQueryConditions = new List<String>();
            respectFilterQueryConditions.addAll(pgQueryConditions.respectFilterQueryConditions);
            String whereClause = '';
            if (pgQueryConditions.filterAttributesConditions != null && !pgQueryConditions.filterAttributesConditions.isEmpty()) {
                if (String.isNotBlank(pgQueryConditions.filterAttributesLogic)) {
                    whereClause = pgQueryConditions.filterAttributesLogic;
                    for (Integer index = 1; index <= pgQueryConditions.filterAttributesConditions.size(); index++) {
                        whereClause = whereClause.replace('{' + String.valueOf(index) + '}', ' (' + pgQueryConditions.filterAttributesConditions[index - 1] + ')');
                    }
                } else {
                    whereClause = String.join(pgQueryConditions.filterAttributesConditions, ' AND ');
                }
                respectFilterQueryConditions.add('(' + whereClause + ')');
            }
            String excludedPGsFromFilterQuery = 'SELECT COUNT(Id) COUNTPG FROM PG__c';
            excludedPGsFromFilterQuery += ' WHERE (' + String.join(respectFilterQueryConditions, ' AND ') + ')';
            excludedPGsFromFilterQuery += ' AND Id NOT IN (SELECT PG__c FROM NSPG__c WHERE NegoScope__c = \'' + negoScope.Id + '\')';
            List<AggregateResult> results = Database.query(excludedPGsFromFilterQuery);
            if (!results.isEmpty()) {
                excludedPGsFromFilter = Integer.valueOf(results[0].get('COUNTPG'));
            }
            String includedPGsHorsFilterQuery = 'SELECT COUNT(Id) COUNTNSPG FROM NSPG__c';
            includedPGsHorsFilterQuery += ' WHERE NegoScope__c = \'' + negoScope.Id + '\'';
            includedPGsHorsFilterQuery += ' AND PG__c NOT IN (SELECT Id FROM PG__c WHERE (' + String.join(respectFilterQueryConditions, ' AND ') + '))';
            results = Database.query(includedPGsHorsFilterQuery);
            if (!results.isEmpty()) {
                includedPGsHorsFilter = Integer.valueOf(results[0].get('COUNTNSPG'));
            }
            return JSON.serialize(new Map<String, Object> {
                'includedCategories' => includedHEs,
                    'excludedCategories' => excludedHEs,
                    'brands' => includedBrands,
                    'negoscope' => negoScope,
                    'productAttributes' => productAttributesList,
                    'productAttributeReferenceValuesMap' => json.serialize(productAttributeReferenceValuesMap),
                    'excludedPGsFromFilter' => excludedPGsFromFilter,
                    'includedPGsHorsFilter' => includedPGsHorsFilter
                    });
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('ERROR: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
    }
}