public with sharing class CommercialPlanSimulationCtrlLWC {
    
    public static GridSettingsManager initGridSettings(NegoptimSettings settings, String templateName) {
        List<String> staticBannerFieldsList = new List<String> {
            SObjectType.CommercialPlan__c.fields.Id.Name,
            SObjectType.CommercialPlan__c.fields.Name.Name,
            SObjectType.CommercialPlan__c.fields.Hierarchy__c.Name,
            SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.CommercialPlan__c.fields.BusinessUnitSource__c.Name,
            SObjectType.CommercialPlan__c.fields.Supplier__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.BusinessUnitTarget__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Code__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Code__c.Name
        };
        List<String> staticDetailsFieldsList = new List<String>{
            SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.Product__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.Status__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.BudgetType__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellOutDiscountType__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.Hierarchy__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.ConsumerTradeItemPromoDetail__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.PowerofAttornayURL__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SellOutDiscountValue__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.OpName__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.ContractPromoURL__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.InvoiceDocumentURL__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.Agreement__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.CommercialPlanDetail__c.fields.SalesExecutionRateFact__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.BusinessUnitTarget__c.Name) + '.' + SObjectType.BusinessUnit__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Hierarchy__c.Name) + '.' + SObjectType.Hierarchy__c.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.Product__c.Name) + '.' + SObjectType.Product2.fields.Hierarchy__c.Name,
            NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name) + '.' + NegoptimHelper.getFieldNameAsRelation(SObjectType.CommercialPlan__c.fields.Supplier__c.Name) + '.' + SObjectType.Supplier__c.fields.Code__c.Name
        };
        String metadataDeveloperName = '';
        if (templateName == '') {
            metadataDeveloperName = settings.commercialPlanGridLayout;
        } else {
            metadataDeveloperName = templateName;
        }
        GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.CommercialPlan__c.Name, '', String.join(staticBannerFieldsList, ','), SObjectType.CommercialPlanDetail__c.Name, '', String.join(staticDetailsFieldsList, ','), metadataDeveloperName, null, true);
        return gridSettingsManager;
    }
    
    public static CommercialPlan__c getCommercialPlan(Id recordId, List<String> fields) {
        try {
            String query = 'SELECT ';
            if (fields.isEmpty()) {
                query += 'Id';
            } else {
                query += '' + String.join(fields, ',');
            }
            query += ' FROM ' + SObjectType.CommercialPlan__c.Name;
            query += ' WHERE Id = :recordId';
            List<CommercialPlan__c> commercialPlans = Database.query(query);
            if (!commercialPlans.isEmpty()) {
                return commercialPlans[0];
            }
            return null;
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getCommercialPlanDetails(String commercialPlanJSON, String gridsettingsJSON, Integer pageNumber, Integer pageSize, String filtersJSON) {
        CommercialPlan__c commercialPlan = (CommercialPlan__c) JSON.deserialize(commercialPlanJSON, CommercialPlan__c.class);
        GridSettingsManager gridsettings = (GridSettingsManager) JSON.deserialize(gridsettingsJSON, GridSettingsManager.class);
        //Handle filters
        FilterWrapper filter = new FilterWrapper(null, null);
        if (filtersJSON != null) {
            filter = (FilterWrapper) JSON.deserialize(filtersJSON, FilterWrapper.class);
        }
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
        Id commercialPlanId = commercialPlan.id;
        List<String> whereClause = new List<String>();
        whereClause.add(SObjectType.CommercialPlanDetail__c.fields.CommercialPlan__c.Name + ' = :commercialPlanId');
        whereClause.add(SObjectType.CommercialPlanDetail__c.fields.ConsumerTradeItemPromoDetail__c.Name + ' = NULL');
        if (filter != null) {
            if (filter.searchValue != null && filter.searchValue != '') {
                whereClause.add('(' + SObjectType.CommercialPlanDetail__c.fields.Product__c.Name.replace('__c','__r') + '.' + SObjectType.Product2.fields.Hierarchy__c.Name.replace('__c','__r') + '.' + SObjectType.Hierarchy__c.fields.Name.Name + ' LIKE \'%' + String.escapeSingleQuotes(filter.searchValue) + '%\' OR ' + SObjectType.CommercialPlanDetail__c.fields.Product__c.Name.replace('__c','__r') + '.' + SObjectType.Product2.fields.Brand__c.Name.replace('__c','__r') + '.' + SObjectType.Brand__c.fields.Name.Name + ' LIKE \'%' + String.escapeSingleQuotes(filter.searchValue) + '%\' OR '  + SObjectType.CommercialPlanDetail__c.fields.Product__c.Name.replace('__c','__r') + '.' + SObjectType.Product2.fields.GTIN__c.Name + ' LIKE \'%' + String.escapeSingleQuotes(filter.searchValue) + '%\' OR ' + SObjectType.CommercialPlanDetail__c.fields.Product__c.Name.replace('__c','__r') + '.' + SObjectType.Product2.fields.ProductCode.Name + ' LIKE \'%' + String.escapeSingleQuotes(filter.searchValue) + '%\')');
            }
            if (filterSettings != null && !filterSettings.isEmpty()) {
                for(FilterSettings item : filterSettings){
                    whereClause.addAll(item.getQueryConditions());
                }
            }
        }
        system.debug('whereClause >> '+JSON.serialize(whereClause));
        Map<String, FilterSettings> filtersMap = new Map<String, FilterSettings>();
        Object filtersd = JSON.deserializeUntyped(gridsettings.gridLayout.Filters__c);
        List<Object> filters = (List<Object>)filtersd;
        for (Object objt : filters) {
            Map<String, Object> item = (Map<String, Object>)objt;
            system.debug('item >> '+JSON.serialize(item));
            String fieldName = item.containsKey('fieldName') ? String.valueOf(item.get('fieldName')) : null;
            if (fieldName != null) {
                String value1 = item.containsKey('value1') && item.get('value1') != null ? String.valueOf(item.get('value1')) : null;
                String value2 = item.containsKey('value2') && item.get('value2') != null ? String.valueOf(item.get('value2')) : null;
                List<String> values = new List<String>();
                if(item.containsKey('values') && String.isNotBlank(String.valueOf(item.get('values')))) {
                    List<Object> tempValues = (List<Object>) item.get('values');
                    for (Object val : tempValues) {
						values.add(String.valueOf(val));
					}
                }
                Boolean userFilterable = item.containsKey('userFilterable') ? (Boolean)item.get('userFilterable') : false;
                system.debug('fieldName >> '+fieldName);
                if ((values != null && !values.isEmpty()) || (value1 != null || value2 != null)) {
                    whereClause.add(String.join((new FilterSettings(fieldName, null, null, null, null, value1, value2, values, userFilterable)).getQueryConditions(), ' AND '));
                }
            }
        }
        String orderBy = '';
        for (GridSettingsManager.FieldWrapper field : gridsettings.GRID_FIELDS) {
            if (field.isDefaultSortable != null && field.isDefaultSortable) {
                orderBy += field.fieldName + ' ' + field.DefaultSortDirection;
            }
        }
        String query = gridsettings.buildQuery(null, whereClause, orderBy);
        System.debug('query is '+query);
        //StandardSetController to handle pagination
        //Get the parent/non-children commercial plans first
        ApexPages.StandardSetController comCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        if (pageSize != 0) {
            comCon.setPageSize(pageSize);
            comCon.setpageNumber(pageNumber);
        } else {
            comCon.setPageSize(1000);
            comCon.setpageNumber(1);
        }
        List<CommercialPlanDetail__c> commercialPlanDetails = comCon.getRecords();
        //Get the ids of parents to get
        Set<Id> notChildrenSet = new Set<Id>();
        for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) {
            notChildrenSet.add(commercialPlanDetail.Id);
        }
        //Build query of children with the same fields as the parents
        String childrenQuery = '';
        childrenQuery += 'SELECT ';
        childrenQuery +=  String.join(gridsettings.ALL_FIELDS, ',') ;
        childrenQuery += ' FROM ' + SObjectType.CommercialPlanDetail__c.Name;
        childrenQuery += ' WHERE ' + SObjectType.CommercialPlanDetail__c.fields.ConsumerTradeItemPromoDetail__c.Name + ' IN :notChildrenSet';
        system.debug('children query '+childrenQuery);
        List<CommercialPlanDetail__c> childrenComPlanDetails = Database.query(childrenQuery);
        Map<Id,List<CommercialPlanDetail__c>> parentToChildrenMap = new Map<Id,List<CommercialPlanDetail__c>>();
        for (CommercialPlanDetail__c child : childrenComPlanDetails) {
            if (!parentToChildrenMap.containsKey(child.ConsumerTradeItemPromoDetail__c)) {
                parentToChildrenMap.put(child.ConsumerTradeItemPromoDetail__c, new List<CommercialPlanDetail__c>{child});
            } else {
                parentToChildrenMap.get(child.ConsumerTradeItemPromoDetail__c).add(child);
            }
        }

        List<CommercialPlanDetailWrapper> commercialPlanDetailsWrapperList = new List<CommercialPlanDetailWrapper>();
        for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) { 
            CommercialPlanDetailWrapper CommercialPlanDetailWrapper = new CommercialPlanDetailWrapper(commercialPlanDetail, parentToChildrenMap.get(commercialPlanDetail.Id));
            commercialPlanDetailsWrapperList.add(CommercialPlanDetailWrapper);
        }
        CPDPagesWrapper pagesWrapper = new CPDPagesWrapper(commercialPlanDetailsWrapperList, comCon.getResultSize());
        return JSON.serialize(pagesWrapper);
    }

    @AuraEnabled
    public static string loadSimulation(String commercialPlanId, Integer pageSize, Integer pageNumber, String templateName) {
        try {
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            GridSettingsManager gridsettings = initGridSettings(settings, templateName);
            String FiltersJSON = JSON.serialize(gridSettings.FILTERS);
            gridSettings.FILTERS.clear(); // Will cause Apex Type Error while deserialize in getCommercialPlanDetails method
            CommercialPlan__c commercialPlan = getCommercialPlan(commercialPlanId, gridsettings.ALL_BANNER_FIELDS);
            CPDPagesWrapper pagesWrapper = (CPDPagesWrapper)JSON.deserialize(getCommercialPlanDetails(JSON.serialize(commercialPlan), JSON.serialize(gridsettings), pageNumber, pageSize, null), CPDPagesWrapper.class); 
            List<CommercialPlanDetailWrapper> commercialPlanDetails = pagesWrapper.commercialPlanDetailsWrapperList;
            Integer numberOfRecords = pagesWrapper.numberOfRecords;
            List<String> cpdChildrenInputFields = new List<String> {
                SObjectType.CommercialPlanDetail__c.fields.RetailPricePromowTax__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SalesExecutionRateTarget__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.VolumeTarget__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.VolumeFact__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.VolumeValidate__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Product__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.AgreementLine1__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.InvoiceDocumentURL__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.BusinessUnitTarget__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.BudgetType__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.PowerofAttornayURL__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellOutDiscountValue__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.ContractPromoURL__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Note__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.Status__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellInDiscountUAmtNego__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellOutDiscountType__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.AgreementLine1__c.Name,
                SObjectType.CommercialPlanDetail__c.fields.SellInDiscountMassValueNego__c.Name
            };
            List<String> BUFieldLabels = new List<String>{
                Schema.getGlobalDescribe().get(SObjectType.BusinessUnit__c.Name).getDescribe().fields.getMap().get(SObjectType.BusinessUnit__c.fields.Name.Name).getDescribe().getLabel(),
                Schema.getGlobalDescribe().get(SObjectType.BusinessUnit__c.Name).getDescribe().fields.getMap().get(SObjectType.BusinessUnit__c.fields.Code__c.Name).getDescribe().getLabel()
            };
            List<String> categoryFieldLabels = new List<String>{
                Schema.getGlobalDescribe().get(SObjectType.Hierarchy__c.Name).getDescribe().fields.getMap().get(SObjectType.Hierarchy__c.fields.Name.Name).getDescribe().getLabel(),
                Schema.getGlobalDescribe().get(SObjectType.Hierarchy__c.Name).getDescribe().fields.getMap().get(SObjectType.Hierarchy__c.fields.Code__c.Name).getDescribe().getLabel(),
                Schema.getGlobalDescribe().get(SObjectType.Hierarchy__c.Name).getDescribe().fields.getMap().get(SObjectType.Hierarchy__c.fields.LongName__c.Name).getDescribe().getLabel()
            };
                                                            
            CommercialPlanWrapper CommercialPlanWrapper = new CommercialPlanWrapper(commercialPlan, commercialPlanDetails, numberOfRecords);
            LabelsWrapper labels = new LabelsWrapper(BUFieldLabels, categoryFieldLabels);
            CommercialPlanSimulationWrapper CommercialPlanSimulation = new CommercialPlanSimulationWrapper(CommercialPlanWrapper, gridsettings, FiltersJSON, cpdChildrenInputFields, labels, numberOfRecords, CommercialPlanDetail__c.SObjectType.getDescribe().isDeletable());
            CommercialPlanSimulation.discountPercentScale = settings.discountPercentScale;
            return JSON.serialize(CommercialPlanSimulation);
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, List<MyPickListInfo>> getFieldDependencies(String controllingField, String dependentField) {
        Map<String, List<MyPickListInfo>> controllingInfo = new Map<String, List<MyPickListInfo>>();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(SObjectType.CommercialPlanDetail__c.Name);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues) {
            controllingInfo.put(currControllingValue.getValue(), new List<MyPickListInfo>());
        }
        
        for(Schema.PicklistEntry currDependentValue : dependentValues) {
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for(Integer curr : hexString.getChars()) {
                Integer val = 0;
                
                if(curr >= 65) {
                    val = curr - 65 + 10;
                } else {
                    val = curr - 48;
                }
                if((val & 8) == 8) {
                    controllingInfo.get(controllingValues[baseCount + 0].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));
                }
                if((val & 4) == 4) {
                    controllingInfo.get(controllingValues[baseCount + 1].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                if((val & 2) == 2) {
                    controllingInfo.get(controllingValues[baseCount + 2].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                if((val & 1) == 1) {
                    controllingInfo.get(controllingValues[baseCount + 3].getValue()).add(new MyPickListInfo(currDependentValue.getValue(), currDependentValue.getLabel()));                    
                }
                baseCount += 4;
            }            
        }
        return controllingInfo;
    }
    
    @AuraEnabled
    public static string saveSimulation(String wCommercialPlanDetailListJson) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<CommercialPlanDetailWrapper> updatedwCPDS = (List<CommercialPlanDetailWrapper>)JSON.deserialize(wCommercialPlanDetailListJson, List<CommercialPlanDetailWrapper>.class);
            handleSaveCalculations(updatedwCPDS);
            List<CommercialPlanDetail__c> updatedCommercialPlanDetails = new List<CommercialPlanDetail__c>();
            List<CommercialPlanDetail__c> newCommercialPlanDetails = new List<CommercialPlanDetail__c>();
            if (!updatedwCPDS.isEmpty()) {
                for (CommercialPlanDetailWrapper wItem : updatedwCPDS) {
                    if (wItem.commercialPlanDetail.Id != null) {
                        updatedCommercialPlanDetails.add(wItem.CommercialPlanDetail);
                        
                    } else {
                        newCommercialPlanDetails.add(wItem.CommercialPlanDetail);
                    }
                }
            }
            if (!updatedCommercialPlanDetails.isEmpty()) {
                update updatedCommercialPlanDetails;
            }
            if (!newCommercialPlanDetails.isEmpty()) {
                insert newCommercialPlanDetails;
            }
            updatedCommercialPlanDetails.clear();
            newCommercialPlanDetails.clear();
            for (CommercialPlanDetailWrapper wItem : updatedwCPDS) {
                if (wItem.commercialPlanDetailChildren != null) {
                    for (CommercialPlanDetail__c child : wItem.commercialPlanDetailChildren) {
                        if (child.Id != null) {
                            updatedCommercialPlanDetails.add(child);
                        } else {
                            child.ConsumerTradeItemPromoDetail__c = wItem.CommercialPlanDetail.Id;
                            newCommercialPlanDetails.add(child);
                        }
                    }
                }
            }
            if (!updatedCommercialPlanDetails.isEmpty()) {
                update updatedCommercialPlanDetails;
            }
            if (!newCommercialPlanDetails.isEmpty()) {
                insert newCommercialPlanDetails;
            }
            return '';
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            return e.getMessage() + ' -- ' + e.getLineNumber();
        }
    }
    
    public static void handleSaveCalculations(List<CommercialPlanDetailWrapper> updatedwCPDS) {
        try {
            for (CommercialPlanDetailWrapper cpdw : updatedwCPDS) {
                Set<String> fieldsToBeTaken = new Set<String>{'Rejected DC','Rejected Client','Canceled','StandBY'};
                Set<String> doChildCalculations = new Set<String>{/*'Rejected DC','Rejected Client','Canceled','StandBY',*/'Attempt'};
                Set<String> rejectedStatus = new Set<String>{'Rejected DC','Rejected Client','Canceled'};
                Map<String,Integer> statusHierarchy = new Map<String,Integer>{
                    'Demande de capa' => 1,
                    'Validated Capa' => 2,
                    'Request for approval' => 3,
                    'Validated' => 4,
                    'Realized' => 5,
                    'Invoiced' => 6
                };
                String highestStatus = null;
                Boolean takeStatusFromChildren = true;
                String statusToTake = cpdw.commercialPlanDetailChildren != null ? cpdw.commercialPlanDetailChildren[0].Status__c : null;
                Double sumVolumePrev = 0;
                Double sumVolumeReached = 0;
                Double sumVolumeValid = 0;
                Double sumCoutFactHT = 0;
                Double numTauxRemontePrev = 0;
                Double denoTauxRemontePrev = 0;
                Double numTauxRemonteReel = 0;
                Double denoTauxRemonteReel = 0;
                cpdw.commercialPlanDetail.Hierarchy__c = cpdw.commercialPlanDetail.Product__r.Hierarchy__c;
                cpdw.commercialPlanDetail.Hierarchy__r = cpdw.commercialPlanDetail.Product__r.Hierarchy__r;
                if (cpdw.commercialPlanDetailChildren != null && !cpdw.commercialPlanDetailChildren.isEmpty()) {
                    for (CommercialPlanDetail__c childCPD : cpdw.commercialPlanDetailChildren) {
                        if (!fieldsToBeTaken.contains(childCPD.Status__c) || childCPD.Status__c != cpdw.commercialPlanDetailChildren[0].Status__c) {
                            takeStatusFromChildren = false;
                        }
                        if (statusHierarchy.keySet().contains(childCPD.Status__c) && (highestStatus == null || statusHierarchy.get(childCPD.Status__c) > statusHierarchy.get(highestStatus))) {
                            highestStatus = childCPD.Status__c;
                        }
                        if (cpdw.commercialPlanDetail.BudgetType__c == 'FG') {
                            // not found in sheet
                            // childCPD.TMP_Cout_Facture_HT__c = 0;
                        }
                        if (childCPD.BusinessUnitTarget__c == null) {
                            childCPD.BusinessUnitTarget__c = cpdw.commercialPlanDetail.BusinessUnitTarget__c;
                        }
                        // Prev Parent Calculation
                        numTauxRemontePrev += childCPD.SalesExecutionRateTarget__c != null && childCPD.VolumeTarget__c != null ? childCPD.SalesExecutionRateTarget__c * childCPD.VolumeTarget__c : 0;
                        denoTauxRemontePrev += childCPD.VolumeTarget__c != null ? childCPD.VolumeTarget__c : 0;
                        // Reel Parent Calculation
                        numTauxRemonteReel += childCPD.SalesExecutionRateFact__c != null && childCPD.VolumeFact__c != null ? childCPD.SalesExecutionRateFact__c * childCPD.VolumeFact__c : 0;
                        denoTauxRemonteReel += childCPD.VolumeFact__c != null ? childCPD.VolumeFact__c : 0;
                        if (!doChildCalculations.contains(childCPD.Status__c) && childCPD.Status__c != null) {
                            sumVolumePrev += childCPD.VolumeTarget__c != null ? childCPD.VolumeTarget__c : 0;
                        }
                        sumVolumeReached += childCPD.VolumeFact__c != null ? childCPD.VolumeFact__c : 0;
                        sumVolumeValid += childCPD.VolumeValidate__c != null ? childCPD.VolumeValidate__c : 0;
                        childCPD.OpType__c = cpdw.commercialPlanDetail.OpType__c;
                        childCPD.SellOutEDate__c = cpdw.commercialPlanDetail.SellOutEDate__c;
                        childCPD.SellOutBDate__c = cpdw.commercialPlanDetail.SellOutBDate__c;
                        childCPD.SellInPreOrderBDate__c = cpdw.commercialPlanDetail.SellInPreOrderBDate__c;
                        childCPD.SellOutDiscountValue__c = cpdw.commercialPlanDetail.SellOutDiscountValue__c;
                        childCPD.TradeOpType__c = cpdw.commercialPlanDetail.TradeOpType__c;
                        childCPD.OpName__c = cpdw.commercialPlanDetail.OpName__c;
                        childCPD.Hierarchy__c = childCPD.Product__r.Hierarchy__c;
                        childCPD.Hierarchy__r = childCPD.Product__r.Hierarchy__r;
                    }
                    if (takeStatusFromChildren) {
                        cpdw.commercialPlanDetail.Status__c = statusToTake;
                    }
                    if (highestStatus != null) {
                        cpdw.commercialPlanDetail.Status__c = highestStatus;
                    }
                    cpdw.commercialPlanDetail.RetailPricePromowTax__c = 0;
                    cpdw.commercialPlanDetail.Product__c = null;
                    Double calcTauxRemontePrev = denoTauxRemontePrev != 0 ?  numTauxRemontePrev / denoTauxRemontePrev : 0;
                    Double calcTauxRemonteReel = denoTauxRemonteReel != 0 ?  numTauxRemonteReel / denoTauxRemonteReel : 0;
                    CommercialPlanDetail__c cpd = cpdw.commercialPlanDetail;
                    if (cpdw.commercialPlanDetail.SalesExecutionRateTarget__c != calcTauxRemontePrev
                        || cpdw.commercialPlanDetail.VolumeTarget__c != sumVolumePrev
                        || cpdw.commercialPlanDetail.VolumeFact__c != sumVolumeReached
                        || cpdw.commercialPlanDetail.VolumeValidate__c != sumVolumeValid) {
                            cpd.SalesExecutionRateTarget__c = Decimal.valueOf(calcTauxRemontePrev).setScale(2);
                            cpd.VolumeTarget__c = Decimal.valueOf(sumVolumePrev).setScale(2);
                            cpd.VolumeFact__c = Decimal.valueOf(sumVolumeReached).setScale(2);
                            cpd.VolumeValidate__c = Decimal.valueOf(sumVolumeValid).setScale(2);
                        }
                    if (cpd.Id == null
                        && cpd.VolumeTarget__c != null
                        && cpd.VolumeTarget__c != 0
                        && cpd.BudgetType__c != 'CTN gratuits'
                        && cpd.SellInPreOrderBDate__c >= Date.newInstance(2022, 11, 1)) {
                            cpd.ExtractStatus__c = 'Extract';
                        }
                }
            }
        } catch (Exception e) {
            System.debug('handleSaveCalculations ' + e.getMessage() + ' -- ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String getProductsRecords(String commPlanCategoryId, String productFilter, Integer pageSize, Integer pageNumber) {
        ProductFilterWrapper filter = (ProductFilterWrapper)JSON.deserialize(productFilter, ProductFilterWrapper.class);
        String productNameSearch = filter.generalSearch;
        //Deserialize the Commercial Plan recieved from JS
        List<Grid_Settings__mdt> gridMetadata = [SELECT Columns__c FROM Grid_Settings__mdt WHERE DeveloperName = 'CommercialPlanProductSelection' ORDER BY DeveloperName LIMIT 1];
        List<String> productFieldsSet = new List<String>();
        List<FieldWrapper> fieldsList = new List<FieldWrapper>();
        Boolean containsId = false;
        Boolean containsName = false;
        if (!gridMetadata.isEmpty() && gridMetadata[0].Columns__c != '' && gridMetadata[0].Columns__c != '[]') {
            fieldsList = (List<FieldWrapper>)JSON.deserialize(gridMetadata[0].Columns__c, List<FieldWrapper>.class);
            for (FieldWrapper field : fieldsList) {
                if (field.fieldName == 'Id') {
                    containsId = true;
                }
                if (field.fieldName == 'Name') {
                    containsName = true;
                }
                productFieldsSet.add(field.fieldName);
            }
            if (!containsName) {
                productFieldsSet.add(0, 'Name');
            }
        } else {
            productFieldsSet = new List<String> {
                SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.ProductCode.Name,
                SObjectType.Product2.fields.GTIN__c.Name,
                SObjectType.Product2.fields.Market_Introduction_Date__c.Name,
                SObjectType.Product2.fields.Hierarchy__c.Name,
                SObjectType.Product2.fields.Brand__c.Name,
                SObjectType.Product2.fields.Family.Name,
                SObjectType.Product2.fields.Animation__c.Name,
                //SObjectType.Product2.fields.Market__c.Name,
                'RecordTypeId'
            };
            containsName = true;
        }
        Map<String,Schema.SObjectField> productSobjectFieldsMap = Schema.getGlobalDescribe().get('Product2').getDescribe().fields.getMap();
        List<FieldWrapper> productsFieldsInfo = new List<FieldWrapper>();
        List<String> fieldsToQuery = new List<String>();
        FieldWrapper productInfo;
        String fieldType;
        String label;
        for (String field : productFieldsSet) {
            if (field.contains('.')) {
                List<String> splittedField = field.split('\\.');
                // describe of your lookup field
                Schema.DescribeFieldResult f = productSobjectFieldsMap.get(splittedField[0].endswith('__r') ? splittedField[0].replace('__r', '__c') : splittedField[0] + 'Id').getDescribe();
                Schema.DescribeSObjectResult sobjectDescribe = f.getReferenceTo()[0].getDescribe();
                label = sobjectDescribe.fields.getMap().get(splittedField[1]).getDescribe().getLabel();
                fieldType = sobjectDescribe.fields.getMap().get(splittedField[1]).getDescribe().getType().toString();
                productInfo = new FieldWrapper(field, label, fieldType, splittedField[0], splittedField[1], true);
            } else {
                label = productSobjectFieldsMap.get(field).getDescribe().getLabel();
                fieldType = productSobjectFieldsMap.get(field).getDescribe().getType().toString();
                productInfo = new FieldWrapper(field, label, fieldType, '', '', false);
            }
            productsFieldsInfo.add(productInfo);
            if (fieldType == 'PICKLIST' || fieldType == 'MULTIPICKLIST') {
                fieldsToQuery.add('toLabel(' + field + ')');                
            } else if (fieldType == 'REFERENCE') {
                fieldsToQuery.add(field);
                if (field.endsWith('Id')) {
                    fieldsToQuery.add('toLabel(' + field.replace('Id', '.Name') + ')');
                } else {
                    fieldsToQuery.add(field.replace('__c', '__r.Name'));
                }
            } else {
                fieldsToQuery.add(field);
            }
        }
        String productQuery = 'SELECT '+ (containsId ? '' : 'Id, ') + (containsName ? '' : 'Name ') + (productFieldsSet.isEmpty() ? '' : containsName ? '' : ', ') + String.join(new List<String>(fieldsToQuery), ', ') + ' FROM Product2';
        String whereClause = ' RecordType.DeveloperName <> \'Secondary\' ';
        if (commPlanCategoryId != null) {
            whereClause += ' AND (Hierarchy__c = \'' + commPlanCategoryId + '\'';
            whereClause += ' OR Hierarchy__r.HierarchyParent__c = \'' + commPlanCategoryId + '\'';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__c = \'' + commPlanCategoryId + '\'';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + commPlanCategoryId + '\'';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + commPlanCategoryId + '\')';
        } else {
            whereClause += ' AND Hierarchy__c = NULL';
        }
        if (filter.categories != null && !filter.categories.isEmpty()) {
            whereClause += ' AND (Hierarchy__c IN (\'' + String.join(filter.categories, '\', \'') + '\')';
            whereClause += ' OR Hierarchy__r.HierarchyParent__c IN (\'' + String.join(filter.categories, '\', \'') + '\')';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__c IN (\'' + String.join(filter.categories, '\', \'') + '\')';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c IN (\'' + String.join(filter.categories, '\', \'') + '\')';
            whereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c IN (\'' + String.join(filter.categories, '\', \'') + '\'))';
        }
        if (filter.brands != null && !filter.brands.isEmpty()) {
            whereClause += ' AND Brand__c IN (\'' + String.join(filter.brands, '\', \'') + '\')';
        }
        /*if (filter.market != '') {
            whereClause += ' AND Market__c = \'' + filter.market + '\'';
        }*/
        if (filter.family != '') {
            whereClause += ' AND Family = \'' + filter.family + '\'';
        }
        if (filter.animation != '') {
            whereClause += ' AND Animation__c = \'' + filter.animation + '\'';
        }
        if (String.isNotBlank(productNameSearch)) {
            whereClause += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\' ';
            whereClause += ' OR ProductCode LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\' ';
            //whereClause += ' OR Market__c  LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\' ';
            whereClause += ' OR Hierarchy__r.Name LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\' ';
            whereClause += ' OR GTIN__c LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\' ';
            whereClause += ' OR RecordType.Name LIKE \'%' + String.escapeSingleQuotes(productNameSearch) + '%\')';
        }
        if (filter.recordType != null && filter.recordType != '') {
            List<String> recordTypeIds = filter.recordType.split(',');
            whereClause += ' AND RecordTypeId IN (\'' + String.join(recordTypeIds, '\',\'') + '\')';
        }
        whereClause += ' AND isActive = True';
        productQuery += String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '';
        
        ApexPages.StandardSetController productsCon = new ApexPages.StandardSetController(Database.getQueryLocator(productQuery));
        productsCon.setPageSize(pageSize);
        productsCon.setpageNumber(pageNumber);
        List<Product2> productsList = productsCon.getRecords();
        ProductWrapper productResult = new ProductWrapper(productsList, productsFieldsInfo, productsCon.getResultSize());
        return JSON.serialize(productResult);
    }
    
    @AuraEnabled
    public static String getBUsRecords(String commPlanJSON, String BUNameSearch) {
        CommercialPlan__c commPlan = (CommercialPlan__c)JSON.deserialize(commPlanJSON, CommercialPlan__c.class);
        String BUQuery = 'SELECT Id, Name, Code__c FROM BusinessUnit__c';
        String whereClause = '';
        if (commPlan != null) {
            Id supplierId = commPlan.Supplier__c ;
            if (supplierId != null) {
                whereClause += ' Supplier__c = \'' + supplierId + '\' ';
            } else {
                whereClause += ' Supplier__c = NULL';
            }
        }
        //whereClause += ' AND RecordType.DeveloperName = \'Banner\'';
        if (String.isNotBlank(BUNameSearch)) {
            whereClause += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(BUNameSearch) + '%\' ';
            whereClause += ' OR Code__c LIKE \'%' + String.escapeSingleQuotes(BUNameSearch) + '%\' )';
        }
        BUQuery += String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '';
        BUQuery += ' LIMIT 20';
        List<BusinessUnit__c> BUs = Database.query(BUQuery);
        return JSON.serialize(BUs);
    }
    
    @AuraEnabled
    public static String getCategoriesRecords(String commPlanJSON, String categoryNameSearch) {
        CommercialPlan__c commPlan = (CommercialPlan__c)JSON.deserialize(commPlanJSON, CommercialPlan__c.class);
        String categoryQuery = 'SELECT Id, Name, Code__c, LongName__c FROM Hierarchy__c ';
        String productQuery = 'SELECT Hierarchy__c FROM Product2 ';
        String whereClause = '';
        String productWhereClause = ' RecordType.DeveloperName <> \'Secondary\' ';
        if (commPlan != null) {
            Id categoryId = commPlan.Hierarchy__c;
            if (categoryId != null) {
                whereClause += ' (Id = \'' + categoryId + '\'';
                whereClause += ' OR HierarchyParent__c = \'' + categoryId + '\'';
                whereClause += ' OR HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\'';
                whereClause += ' OR HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\'';
                whereClause += ' OR HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\'';
                whereClause += ' OR HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\')';
                productWhereClause += ' AND (Hierarchy__c = \'' + categoryId + '\'';
                productWhereClause += ' OR Hierarchy__r.HierarchyParent__c = \'' + categoryId + '\'';
                productWhereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\'';
                productWhereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\'';
                productWhereClause += ' OR Hierarchy__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__r.HierarchyParent__c = \'' + categoryId + '\')';
            }
            productWhereClause += productWhereClause != '' ? ' AND Status__c IN (\'Open\',\'On sale\') ' : 'Status__c IN (\'Open\',\'On sale\') ';
        }
        if (String.isNotBlank(categoryNameSearch)) {
            whereClause +=  (String.isNotBlank(whereClause) ? ' AND ' : '' ) + ' (Name LIKE \'%' + String.escapeSingleQuotes(categoryNameSearch) + '%\' ';
            whereClause += ' OR Code__c LIKE \'%' + String.escapeSingleQuotes(categoryNameSearch) + '%\' ';
            whereClause += ' OR LongName__c LIKE \'%' + String.escapeSingleQuotes(categoryNameSearch) + '%\' )';
        }
        productQuery += String.isNotBlank(productWhereClause) ? ' WHERE ' + productWhereClause : '';
        whereClause += whereClause != '' ? ' AND Id IN ( ' + productQuery + ') ' : 'Id IN ( ' + productQuery + ')' ;
        categoryQuery += String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '';
        categoryQuery += ' LIMIT 20';
        system.debug('Category query is '+categoryQuery);
        List<Hierarchy__c> categories = Database.query(categoryQuery);
        return JSON.serialize(categories);
    }
    
    @AuraEnabled
    public static String getProductsOfCategory(String commPlanJSON, Id categoryId, Id BuId) {
        try {
            CommercialPlan__c commPlan = (CommercialPlan__c)JSON.deserialize(commPlanJSON, CommercialPlan__c.class);
            String productQuery = 'SELECT id, name, Hierarchy__c FROM Product2';
            List<String> conditions = new List<String>();
            conditions.add('Hierarchy__c = \'' + categoryId + '\'');
            conditions.add('RecordType.DeveloperName <> \'Secondary\'');
            productQuery += !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
            List<Product2> products = Database.query(productQuery);
            return JSON.serialize(products);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            return e.getMessage() + ' -- ' + e.getLineNumber();
        }
    }
    
    @AuraEnabled
    public static String createNewDetail(String commPlanJSON) { 
        try {
            CommercialPlan__c commPlan = (CommercialPlan__c)JSON.deserialize(commPlanJSON, CommercialPlan__c.class);
            CommercialPlanDetail__c newInlineCPD = new CommercialPlanDetail__c(CommercialPlan__c = commPlan.Id, BusinessUnitTarget__c = commPlan.BusinessUnitTarget__c,  BusinessUnitTarget__r = commPlan.BusinessUnitTarget__r);
            CommercialPlanDetailWrapper newCPDWrapper = new CommercialPlanDetailWrapper(newInlineCPD, null);
            newCPDWrapper.hasChanged = true;
            return JSON.serialize(newCPDWrapper);
        } catch (Exception e) {
            System.debug(e.getMessage() + ' -- ' + e.getLineNumber());
            return e.getMessage() + ' -- ' + e.getLineNumber();
        }
    }
    
    @AuraEnabled
    public static void deleteCPDs(String CPDtoDelete_JSON) {
        List<CommercialPlanDetail__c> CPDsToDelete = (List<CommercialPlanDetail__c>) JSON.deserialize(CPDtoDelete_JSON, List<CommercialPlanDetail__c>.class);
        try {
            if (!CPDsToDelete.isEmpty()) {
                delete CPDsToDelete;
            }
        } catch (DMLException ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        } catch (Exception ex) {
            System.debug('Error ::>>>'+ ex.getMessage() + '--' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public class CommercialPlanDetailWrapper { 
        public CommercialPlanDetail__c commercialPlanDetail {get; set;}
        public List<CommercialPlanDetail__c> commercialPlanDetailChildren {get; set;}
        public Integer JSIndex;
        public Boolean hasChanged;
        public String CPDLink {get {
            return this.commercialPlanDetail.Id != null ? '/' + this.commercialPlanDetail.Id : '';
        } set;}
        public CommercialPlanDetailWrapper(CommercialPlanDetail__c commercialPlanDetail, List<CommercialPlanDetail__c> commercialPlanDetailChildren) { 
            this.commercialPlanDetail = commercialPlanDetail;
            this.commercialPlanDetailChildren = commercialPlanDetailChildren;
        }
    }
    
    public class FieldWrapper {
        public String fieldName {get;set;}
        public String fieldLabel {get;set;}
        public String fieldType {get;set;}
        public String objectName {get;set;}
        public String relationField {get;set;}
        public Boolean isRelationField {get;set;}
        
        public FieldWrapper(String fieldName, String fieldLabel, String fieldType, String objectName, String relationField, Boolean isRelationField) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.objectName = objectName;
            this.relationField = relationField;
            this.isRelationField = isRelationField;
        }
    }
    
    public class CommercialPlanWrapper {
        public CommercialPlan__c commercialPlan {get; set;}
        public List<CommercialPlanDetailWrapper> commercialPlanDetails {get; set;}
        public Map<Integer, CommercialPlanDetailWrapper> newcommercialPlanDetail {get; set;}
        public Integer numberOfRecords {get; set;}
        public CommercialPlanWrapper(CommercialPlan__c commercialPlan, List<CommercialPlanDetailWrapper> commercialPlanDetails, Integer numberOfRecords) {
            this.commercialPlan = commercialPlan;
            this.commercialPlanDetails = commercialPlanDetails;
            this.numberOfRecords = numberOfRecords;
            this.newcommercialPlanDetail = new Map<Integer, CommercialPlanDetailWrapper>();
        }
    }
    
    public class CommercialPlanSimulationWrapper {
        public CommercialPlanWrapper CommercialPlanWrapper {get; set;}
        public GridSettingsManager gridSettings{get; set;}
        public String FiltersJSON {get; set;}
        public List<String> cpdChildrenInputFields{get; set;}
        public Integer numberOfPages {get; set;}
        public LabelsWrapper labels {get; set;}
        public Boolean profileDeleteAccess {get; set;}
        public Integer discountPercentScale {get; set;}
        public CommercialPlanSimulationWrapper(CommercialPlanWrapper CommercialPlanWrapper, GridSettingsManager gridSettings, String FiltersJSON, List<String> cpdChildrenInputFields, LabelsWrapper labels, Integer numberOfPages, Boolean profileDeleteAccess) {
            this.CommercialPlanWrapper = CommercialPlanWrapper;
            this.FiltersJSON = FiltersJSON;
            this.gridSettings = gridSettings;
            this.cpdChildrenInputFields = cpdChildrenInputFields;
            this.labels = labels;
            this.numberOfPages = numberOfPages;
            this.profileDeleteAccess = profileDeleteAccess;
        }
    }
    
    public class LabelsWrapper {
        public List<String> BUFieldLabels {get; set;}
        public List<String> categoryFieldLabels {get; set;}
        public LabelsWrapper (List<String> BUFieldLabels, List<String> categoryFieldLabels) {
            this.BUFieldLabels = BUFieldLabels;
            this.categoryFieldLabels = categoryFieldLabels;
        }
    }
    
    public class CPDPagesWrapper {
        public List<CommercialPlanDetailWrapper> commercialPlanDetailsWrapperList {get; set;}
        public Integer numberOfRecords {get; set;}
        public CPDPagesWrapper (List<CommercialPlanDetailWrapper> commercialPlanDetailsWrapperList, Integer numberOfRecords) {
            this.commercialPlanDetailsWrapperList = commercialPlanDetailsWrapperList;
            this.numberOfRecords = numberOfRecords;
        }
    }
    
    public class FilterWrapper {
        public String searchValue {get;set;}
        public String dynamicSearch {get;set;}
        public FilterWrapper (String searchValue, String dynamicSearch) {
            this.searchValue = searchValue;
            this.dynamicSearch = dynamicSearch;
        }
    }
    
    public class ProductWrapper {
        public List<Product2> products {get;set;}
        public List<FieldWrapper> productsFieldsInfo {get;set;}
        public Integer numberOfRecords {get;set;}
        
        public ProductWrapper (List<Product2> products, List<FieldWrapper> productsFieldsInfo, Integer numberOfRecords) {
            this.products = products;
            this.productsFieldsInfo = productsFieldsInfo;
            this.numberOfRecords = numberOfRecords;
        }
    }
    
    public class ProductFilterWrapper {
        public String generalSearch {get;set;}
        public List<String> categories {get;set;}
        public List<String> brands {get;set;}
        public String market {get;set;}
        public String family {get;set;}
        public String animation {get;set;}
        public String recordType {get;set;}
        
        public ProductFilterWrapper() {
            this.generalSearch = '';
            this.categories = new List<String>();
            this.brands = new List<String>();
            this.market = '';
            this.family = '';
            this.animation = '';
            this.recordType = '';
        }
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
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(SObjectType.CommercialPlanDetail__c.Name).getDescribe();
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
    
    public class MyPickListInfo {
        public String validFor;
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String label {get;set;}
        public MyPickListInfo(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}