/**
 * @author ULiT
 * @date 13-03-2021
 * @description trigger handler for PriceListStatementDetail__c
*/
public class Trg_PriceListStatementDetail_Handler implements MethodUtils.MethodChecker {
    public static final Map<String, Id> priceListStatementRTIds = NegoptimHelper.getObjectRecordTypeMapIds(PriceListStatement__c.SObjectType);
    
    public static final List<String> methodList = new List<String> {
        'getMethodNames',
        'populateFields',
        'populateNetPriceTaxes',
        'stopUnitNeedProducts',
        'populateFieldsAfterProductSwitch',
        'calculateRate',
        'bottomUpValues'
    };
    
    public Boolean hasMethod(String methodName) {
        return methodList.contains(methodName);
    }
    
    public Object invoke(String methodName, List<Object> args) {
        List<PriceListStatementDetail__c> newList = args.size() > 0 ? (List<PriceListStatementDetail__c>) args[0] : null;
        Map<Id, PriceListStatementDetail__c> oldMap = args.size() > 1 ? (Map<Id, PriceListStatementDetail__c>) args[1] : null;
        switch on methodName {
            when 'getMethodNames' {
                return getMethodNames();
            }
            when 'populateFields' {
                populateFields(newList, oldMap); // BEFORE INSERT OR UPDATE
            }
            when 'populateNetPriceTaxes' {
                populateNetPriceTaxes(newList); // BEFORE INSERT
            }
            /*when 'stopUnitNeedProducts' {
                //stopUnitNeedProducts(newList, oldMap); // AFTER UPDATE
            }*/
            when 'populateFieldsAfterProductSwitch' {
                populateFieldsAfterProductSwitch(newList, oldMap); // AFTER INSERT OR UPDATE
            }
            when 'calculateRate' {
                calculateRate(newList, oldMap); // AFTER INSERT OR UPDATE OR DELETE
            }
            when 'bottomUpValues' {
                bottomUpValues(newList, oldMap); // AFTER INSERT OR UPDATE OR DELETE
            }
            when else {
                throw new IllegalArgumentException('Method not found: ' + methodName);
            }
        }
        return '';
    }
    
    public static List<String> getMethodNames() {
        Integer getMethodNamesIndex = methodList.indexOf('getMethodNames');
        methodList.remove(getMethodNamesIndex);
        return methodList;
    }

    public static void populateNetPriceTaxes(List<PriceListStatementDetail__c> newPriceListStatementDetails) {
        Map<Id, List<PriceListStatementDetail__c>> priceListMap = new Map<Id, List<PriceListStatementDetail__c>>();
        // PriceListStatement__c.Id => List<SupplierTax__c>
        Map<Id, List<SupplierTax__c>> priceListSupNSTaxesStatementsMap = new Map<Id, List<SupplierTax__c>>();
        Set<String> priceListStatementDetailFieldsSet = Schema.SObjectType.PriceListStatementDetail__c.fields.getMap().keyset();
        for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
            if(item.PriceListStatementDetailReference__c == null) {
                if (!priceListMap.containsKey(item.PriceListStatement__c)) {
                    priceListMap.put(item.PriceListStatement__c, new List<PriceListStatementDetail__c>());
                }
                priceListMap.get(item.PriceListStatement__c).add(item);
            }
        }
        if (!priceListMap.keySet().isEmpty()) {
            // check security on access SupplierTax__c fields
            String[] SupNSTaxesStatementFields = new String[] {
                SObjectType.SupplierTax__c.fields.Id.Name,
                SObjectType.SupplierTax__c.fields.PriceListStatement__c.Name,
                SObjectType.SupplierTax__c.fields.IsActive__c.Name,
                SObjectType.SupplierTax__c.fields.DisplayOrder__c.Name,
                /***SObjectType.SupplierTax__c.fields.Is_Inside_DiscountPrice__c.Name,***/
                SObjectType.SupplierTax__c.fields.IsNetPriceTax__c.Name,
                SObjectType.SupplierTax__c.fields.Rate__c.Name,
                SObjectType.SupplierTax__c.fields.Amt__c.Name,
                SObjectType.SupplierTax__c.fields.IsInvoiceFooterTax__c.Name
            };
            if (NegoptimHelper.checkAccessibility(SupplierTax__c.SObjectType, SupNSTaxesStatementFields)) {
                //  get Supplier NS Taxes Statements
                for (SupplierTax__c item : [SELECT Id, PriceListStatement__c, Tax__c, Tax__r.Name, IsActive__c, DisplayOrder__c, /***Is_Inside_DiscountPrice__c,***/
                                                       IsNetPriceTax__c, Rate__c, Amt__c, IsInvoiceFooterTax__c, IsGrossPriceTax__c
                                                       FROM SupplierTax__c
                                                       WHERE PriceListStatement__c IN :priceListMap.keySet()
                                                       AND DisplayOrder__c <> NULL
                                                       AND IsActive__c = TRUE
                                                       ORDER BY PriceListStatement__c, DisplayOrder__c])
                {
                    if (!priceListSupNSTaxesStatementsMap.containsKey(item.PriceListStatement__c)) {
                        priceListSupNSTaxesStatementsMap.put(item.PriceListStatement__c, new List<SupplierTax__c>());
                    }
                    priceListSupNSTaxesStatementsMap.get(item.PriceListStatement__c).add(item);
                }
            }
        }
        // Sync SupplierTax__c to PriceListStatementDetail__c
        for (Id priceListStatementId : priceListMap.keySet()) {
            List<SupplierTax__c> priceListTaxeStatements = priceListSupNSTaxesStatementsMap.containsKey(priceListStatementId) ?
                priceListSupNSTaxesStatementsMap.get(priceListStatementId) : new List<SupplierTax__c>();
            List<PriceListStatementDetail__c> priceListStatementDetails = priceListMap.containsKey(priceListStatementId) ?
            priceListMap.get(priceListStatementId) : new List<PriceListStatementDetail__c>();
            if (!priceListTaxeStatements.isEmpty() && !priceListStatementDetails.isEmpty()) {
                String activeTaxesDispalyOrder = '';
                String discountPriceTaxesDispalyOrder = '';
                String priceListTaxesDispalyOrder = '';
                String grossPriceTaxes = '';
                Map<Integer, StatementWrapper> activeTaxesMap = new Map<Integer, StatementWrapper>();
                Integer taxDisplayOrder = 1;
                for (SupplierTax__c item : priceListTaxeStatements) {
                    // active taxes on PriceList Statement Level
                    activeTaxesMap.put(taxDisplayOrder, new StatementWrapper(item.Tax__c, item.Tax__r.Name, taxDisplayOrder));
                    activeTaxesDispalyOrder += ('A' + taxDisplayOrder + '/');
                    /***if (item.Is_Inside_DiscountPrice__c) {
                        discountPriceTaxesDispalyOrder += ('D' + taxDisplayOrder + '/');
                    }***/
                    if (item.IsNetPriceTax__c) {
                        priceListTaxesDispalyOrder += ('N' + taxDisplayOrder + '/');
                    }
                    if (item.IsGrossPriceTax__c) {
                        grossPriceTaxes += ('G' + taxDisplayOrder + '/');
                    }
                    taxDisplayOrder++;
                }
                for (PriceListStatementDetail__c priceListStatementDetail : priceListStatementDetails) {
                    priceListStatementDetail.t_ActiveTaxes__c = activeTaxesDispalyOrder;
                    priceListStatementDetail.t_DiscountTaxes__c = discountPriceTaxesDispalyOrder;
                    priceListStatementDetail.t_NetPriceTaxes__c = priceListTaxesDispalyOrder;
                    if (priceListStatementDetailFieldsSet.contains('tmp_grossprice_taxes__c')) {
                        priceListStatementDetail.put('TMP_GrossPrice_Taxes__c', grossPriceTaxes);
                    }
                    String activeTaxesData = (!activeTaxesMap.isEmpty() ? JSON.serialize(activeTaxesMap.values()) : '[]');
                    if (priceListStatementDetailFieldsSet.contains('tmp_active_taxes_data__c')) {
                        priceListStatementDetail.put('TMP_Active_Taxes_Data__c', activeTaxesData);
                    }
                    taxDisplayOrder = 1;
                    for (SupplierTax__c taxStatement : priceListTaxeStatements) {
                        Decimal taxValue;
                        if (taxStatement.IsInvoiceFooterTax__c) {
                            taxValue = null;
                        } else {
                            taxValue = priceListStatementDetail.GrossPrice__c != 0 && priceListStatementDetail.GrossPrice__c != null && taxStatement.Rate__c != null ?
                                (taxStatement.Rate__c/100) * priceListStatementDetail.GrossPrice__c : 0;
                            taxValue += taxStatement.Amt__c != null ? taxStatement.Amt__c : 0;
                        }
                        if (priceListStatementDetail.get('Tax_' + taxDisplayOrder + '__c') == null) {
                            priceListStatementDetail.put('Tax_' + taxDisplayOrder + '__c', taxValue);
                        }
                        taxDisplayOrder++;
                    }
                }
            }
        }
    }

	/**
     * @description ON AFTER INSERT OR UPDATE
     * populate PriceListStatementDetailLastHistory__c in new Price list detail line and Is_Switched__c(true) Target_Product_Life_Status__c(Stop) in switched price list detail line
     */
    public static void populateFieldsAfterProductSwitch(List<PriceListStatementDetail__c> newPriceListStatementDetails, Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap) {
        /***Set<Id> priceListStatementIds = new Set<Id>();
        Set<String> productEans = new Set<String>();
        Map<Id, PriceListStatementDetail__c> updatedPriceListStatementDetailMap = new Map<Id, PriceListStatementDetail__c>();
        Map<String, PriceListStatementDetail__c> eanPriceListStatementDetailHitoryMap = new Map<String, PriceListStatementDetail__c>();

        for (PriceListStatementDetail__c item : newPriceListStatementDetails ) {
            if (String.isNotBlank(item.EAN_Switch_Proposal__c) && ((oldPriceListStatementDetailsMap == null)
                || ((oldPriceListStatementDetailsMap != null
                     && oldPriceListStatementDetailsMap.containsKey(item.Id)
                     && item.EAN_Switch_Proposal__c != oldPriceListStatementDetailsMap.get(item.Id).EAN_Switch_Proposal__c))))
            {
                eanPriceListStatementDetailHitoryMap.put(item.PriceListStatement__c + '' + item.EAN_Switch_Proposal__c, item);
                priceListStatementIds.add(item.PriceListStatement__c);
                productEans.add(item.EAN_Switch_Proposal__c);
            }
        }
        String query = 'SELECT Id, Name, Product_EAN__c, EAN_Switch_Proposal__c, PriceListStatement__c, PriceListStatementDetailLastHistory__c,';
        query += ' GrossPriceP1__c, GrossPricewNetTaxP1__c, Total_Taxes_P1__c';
        query += ' FROM PriceListStatementDetail__c ';
        query += ' WHERE PriceListStatement__c IN (\'' + String.join(new List<Id>(priceListStatementIds), '\', \'') + '\')';
        if (SObjectType.PriceListStatementDetail__c.fields.Product_EAN__c.isFilterable() ) {
            query += ' AND Product_EAN__c IN (\'' + String.join(new List<String>(productEans), '\', \'') + '\')';
        }
        if (!priceListStatementIds.isEmpty() && !productEans.isEmpty()) {
            for (PriceListStatementDetail__c item : Database.query(query)) {
                if (eanPriceListStatementDetailHitoryMap.containsKey(item.PriceListStatement__c + '' + item.Product_EAN__c)) {
                    PriceListStatementDetail__c histoRecord = eanPriceListStatementDetailHitoryMap.get(item.PriceListStatement__c + '' + item.Product_EAN__c);
                    item.Is_Switched__c = true;
                    item.Target_Product_Life_Status__c = 'Stop';
                    updatedPriceListStatementDetailMap.put(item.Id, item);
                    PriceListStatementDetail__c newRecord = updatedPriceListStatementDetailMap.containsKey(histoRecord.Id) ? updatedPriceListStatementDetailMap.get(histoRecord.Id) : new PriceListStatementDetail__c(Id = histoRecord.Id);
                    newRecord.PriceListStatementDetailLastHistory__c = item.Id;
                    newRecord.GrossPriceP1__c = item.GrossPriceP1__c;
                    newRecord.GrossPricewNetTaxP1__c = item.GrossPricewNetTaxP1__c;
                    newRecord.Total_Taxes_P1__c = item.Total_Taxes_P1__c;
                    updatedPriceListStatementDetailMap.put(newRecord.Id, newRecord);
                }
            }
            if (!updatedPriceListStatementDetailMap.isEmpty()) {
                update updatedPriceListStatementDetailMap.values();
            }
        }***/
    }

    /**
     * @description ON BEFORE INSERT OR UPDATE
     * Fill category in price list statement detail from additional product
     */
    public static void populateFields(List<PriceListStatementDetail__c> newPriceListStatementDetails, Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap) {
        for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
            if ((oldPriceListStatementDetailsMap == null)
                || (oldPriceListStatementDetailsMap != null && oldPriceListStatementDetailsMap.containsKey(item.Id) && (item.SellInRegularQty__c != oldPriceListStatementDetailsMap.get(item.Id).SellInRegularQty__c
                                                                                                                        || item.SellInPromoQty__c != oldPriceListStatementDetailsMap.get(item.Id).SellInPromoQty__c
                                                                                                                        || item.ProductTotalWeightCorrection__c != oldPriceListStatementDetailsMap.get(item.Id).ProductTotalWeightCorrection__c
                                                                                                                        || item.ProductTotalWeight__c != oldPriceListStatementDetailsMap.get(item.Id).ProductTotalWeight__c
                                                                                                                        || item.GrossPrice__c != oldPriceListStatementDetailsMap.get(item.Id).GrossPrice__c
                                                                                                                        || item.GrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).GrossPriceP1__c)))
            {
                item.SellInTotalQty__c = (item.SellInRegularQty__c != null ? item.SellInRegularQty__c : 0) + (item.SellInPromoQty__c != null ? item.SellInPromoQty__c : 0);
                item.UnitGrossPrice__c = (item.ProductTotalWeightCorrection__c != null && item.ProductTotalWeightCorrection__c != 0 && item.GrossPrice__c != null ? item.GrossPrice__c / item.ProductTotalWeightCorrection__c : (item.ProductTotalWeight__c != null && item.ProductTotalWeight__c != 0 && item.GrossPrice__c != null ? item.GrossPrice__c / item.ProductTotalWeight__c : 0));
                item.UnitGrossPriceP1__c = (item.ProductTotalWeightCorrection__c != null && item.ProductTotalWeightCorrection__c != 0 && item.GrossPriceP1__c != null ? item.GrossPriceP1__c / item.ProductTotalWeightCorrection__c : (item.ProductTotalWeight__c != null && item.ProductTotalWeight__c != 0 && item.GrossPriceP1__c != null ? item.GrossPriceP1__c / item.ProductTotalWeight__c : 0));
                //item.UnitGrossPricewNetTax__c = (item.ProductTotalWeightCorrection__c != null && item.ProductTotalWeightCorrection__c != 0 && item.GrossPricewNetTax__c != null ? item.GrossPricewNetTax__c / item.ProductTotalWeightCorrection__c : (item.ProductTotalWeight__c != null && item.ProductTotalWeight__c != 0 && item.GrossPricewNetTax__c != null ? item.GrossPricewNetTax__c / item.ProductTotalWeight__c : 0));
                item.UnitGrossPricewNetTaxP1__c = (item.ProductTotalWeightCorrection__c != null && item.ProductTotalWeightCorrection__c != 0 && item.GrossPricewNetTaxP1__c != null ? item.GrossPricewNetTaxP1__c / item.ProductTotalWeightCorrection__c : (item.ProductTotalWeight__c != null && item.ProductTotalWeight__c != 0 && item.GrossPricewNetTaxP1__c != null ? item.GrossPricewNetTaxP1__c / item.ProductTotalWeight__c : 0));
            }
        }
        /***List<PriceListStatementDetail__c> updatedPriceListStatementDetailList = new List<PriceListStatementDetail__c>();
        Set<Id> productsCompetitorIds = new Set<Id>();
        // loop over newPriceListStatements
        for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
            if (item.Id == null
                || (item.Id != null && oldPriceListStatementDetailsMap != null && item.Additionnal_Product__c != oldPriceListStatementDetailsMap.get(item.Id).Additionnal_Product__c))
            {
                if (item.Additionnal_Product__c != null) {
                    updatedPriceListStatementDetailList.add(item);
                    productsCompetitorIds.add(item.Additionnal_Product__c);
                } else if (item.Id != null && oldPriceListStatementDetailsMap != null && oldPriceListStatementDetailsMap.containsKey(item.Id)) {
                    item.Hierarchy__c = null;
                }
            }
        }
        if (!productsCompetitorIds.isEmpty()) {
            Map<Id, Product_Competitor__c> productsCompetitorMap = new Map<Id, Product_Competitor__c>([SELECT Id,
                                                                                                       Hierarchy__c,
                                                                                                       Orga_HE__r.SetPriceListStatementLevel__c,
                                                                                                       Orga_HE__r.HierarchyParent__c,
                                                                                                       Orga_HE__r.Parent_Element__r.SetPriceListStatementLevel__c,
                                                                                                       Orga_HE__r.Parent_Element__r.HierarchyParent__c,
                                                                                                       Orga_HE__r.Parent_Element__r.Parent_Element__r.SetPriceListStatementLevel__c,
                                                                                                       Orga_HE__r.Parent_Element__r.Parent_Element__r.HierarchyParent__c,
                                                                                                       Orga_HE__r.Parent_Element__r.Parent_Element__r.Parent_Element__r.SetPriceListStatementLevel__c,
                                                                                                       Orga_HE__r.Parent_Element__r.Parent_Element__r.Parent_Element__r.HierarchyParent__c
                                                                                                       FROM Product_Competitor__c
                                                                                                       WHERE Id IN :productsCompetitorIds]);
            for (PriceListStatementDetail__c item : updatedPriceListStatementDetailList) {
                if (productsCompetitorMap.containsKey(item.Additionnal_Product__c)) {
                    Product_Competitor__c competitor = productsCompetitorMap.get(item.Additionnal_Product__c);
                    if (competitor?.Orga_HE__r?.SetPriceListStatementLevel__c == true) {
                        item.Hierarchy__c = competitor.Hierarchy__c;
                    } else if (competitor?.Orga_HE__r?.Parent_Element__r?.SetPriceListStatementLevel__c == true) {
                        item.Hierarchy__c = competitor.Orga_HE__r.HierarchyParent__c;
                    } else if (competitor?.Orga_HE__r?.Parent_Element__r?.Parent_Element__r?.SetPriceListStatementLevel__c == true) {
                        item.Hierarchy__c = competitor.Orga_HE__r.Parent_Element__r.HierarchyParent__c;
                    } else if (competitor?.Orga_HE__r?.Parent_Element__r?.Parent_Element__r?.Parent_Element__r?.SetPriceListStatementLevel__c == true) {
                        item.Hierarchy__c = competitor.Orga_HE__r.Parent_Element__r.Parent_Element__r.HierarchyParent__c;
                    } else {
                        item.Hierarchy__c = competitor.Hierarchy__c;
                    }
                }
            }
        }***/
    }

    /**
     * @description ON AFTER UPDATE
     * calculate PriceEvolutionRateCalculated__c
     */
    public static void calculateRate(List<PriceListStatementDetail__c> newPriceListStatementDetails, Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap) {
        Boolean afterDelete = newPriceListStatementDetails == null;
        Set<Id> priceListStatementIdSet = new Set<Id>();
        Set<Id> riseRateRecordtypeIdSet = new Set<Id>();
        Set<Id> depreciationRateRecordtypeIdSet = new Set<Id>();
        Id tariff_RTId = priceListStatementRTIds.containsKey('Tariff') ? priceListStatementRTIds.get('Tariff') : null;
        Id tentative_RTId = priceListStatementRTIds.containsKey('SPITM_Rise_Rate_Tentative') ? priceListStatementRTIds.get('SPITM_Rise_Rate_Tentative') : null;
        riseRateRecordtypeIdSet.add(priceListStatementRTIds.get('RiseRate'));
        if (tariff_RTId != null) {
            riseRateRecordtypeIdSet.add(tariff_RTId);
        }
        if (tentative_RTId != null) {
            riseRateRecordtypeIdSet.add(tentative_RTId);
        }
        depreciationRateRecordtypeIdSet.add(priceListStatementRTIds.get('DepreciationRate'));

        List<PriceListStatement__c> updatedPriceListStatementList = new List<PriceListStatement__c>();
        // loop over newPriceListStatements
        if(!afterDelete) {
            for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
                if (oldPriceListStatementDetailsMap == null || (oldPriceListStatementDetailsMap.containsKey(item.Id) &&
                                                                (item.SellInTotalQtywUnitGrossPriceGap__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPriceGap__c ||
                                                                 item.SellInTotalQtywUnitGrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPriceP1__c ||
                                                                 item.SellInTotalQtywGrossPricewNetTaxGap__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywGrossPricewNetTaxGap__c ||
                                                                 item.SellInTotalQtywGrossPricewNetTaxP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywGrossPricewNetTaxP1__c ||
                                                                 item.SellInTotalQtyTaxesGap__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtyTaxesGap__c ||
                                                                 item.SellInTotalQtyTaxesP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtyTaxesP1__c ||
                                                                 item.SellInTotalQtywGrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywGrossPriceP1__c ||
                                                                 item.SellInTotalQtywUnitGrossPricewNetTaxGap__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPricewNetTaxGap__c ||
                                                                 item.SellInTotalQtywUnitGrossPricewNetTaxP1__c  != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPricewNetTaxP1__c
                                                                 )))
                {
                    priceListStatementIdSet.add(item.PriceListStatement__c);
                }
            }
        } else {
            for (PriceListStatementDetail__c item : oldPriceListStatementDetailsMap.values()) {
                priceListStatementIdSet.add(item.PriceListStatement__c);
            }
        }
        if (!priceListStatementIdSet.isEmpty()) {
            // check security on access PriceListStatementDetail__c fields
            String[] priceListStatementDetailsFields = new String[] {
                SObjectType.PriceListStatementDetail__c.fields.PriceListStatement__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPriceGap__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPriceP1__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywGrossPricewNetTaxGap__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywGrossPricewNetTaxP1__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPricewNetTaxP1__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywUnitGrossPricewNetTaxGap__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtyTaxesGap__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtyTaxesP1__c.Name,
                SObjectType.PriceListStatementDetail__c.fields.SellInTotalQtywGrossPriceP1__c.Name
            };
            // calculate Depreciation_Rate/Rise_Rate = SUM(SellIn * GrossPriceGap__c)/SUM(Sellin*GrossPriceP1__c)
            Map<Id, Map<String, List<Decimal>>> totalRatesMap = new Map<Id, Map<String, List<Decimal>>>();
            if (NegoptimHelper.checkAccessibility(PriceListStatementDetail__c.SObjectType, priceListStatementDetailsFields)) {
                List<AggregateResult> results = [SELECT PriceListStatement__c PriceListStatement__c,
                                                 SUM(SellInTotalQtywUnitGrossPriceGap__c) SellInTotalQtywUnitGrossPriceGap__c, SUM(SellInTotalQtywUnitGrossPriceP1__c) SellInTotalQtywUnitGrossPriceP1__c,
                                                 SUM(SellInTotalQtywGrossPricewNetTaxGap__c) SellInTotalQtywGrossPricewNetTaxGap__c, SUM(SellInTotalQtywGrossPricewNetTaxP1__c) SellInTotalQtywGrossPricewNetTaxP1__c,
                                                 SUM(SellInTotalQtywUnitGrossPricewNetTaxGap__c) SellInTotalQtywUnitGrossPricewNetTaxGap__c, SUM(SellInTotalQtywUnitGrossPricewNetTaxP1__c) SellInTotalQtywUnitGrossPricewNetTaxP1__c,
                                                 SUM(SellInTotalQtyTaxesGap__c) SellInTotalQtyTaxesGap__c, SUM(SellInTotalQtyTaxesP1__c) SellInTotalQtyTaxesP1__c, SUM(SellInTotalQtywGrossPriceP1__c) SellInTotalQtywGrossPriceP1__c
                                                 FROM PriceListStatementDetail__c
                                                 WHERE PriceListStatement__c IN :priceListStatementIdSet
                                                 AND (GrossPrice__c <> NULL AND GrossPrice__c <> 0)
                                                 GROUP BY PriceListStatement__c];
                for (AggregateResult item : results) {
                    Id priceListStatementId = (Id) item.get('PriceListStatement__c');
                    if (!totalRatesMap.containsKey(priceListStatementId)) {
                        totalRatesMap.put(priceListStatementId, new Map<String, List<Decimal>>());
                        totalRatesMap.get(priceListStatementId).put('Rise_PriceEvolutionRateCalculated__c', new List<Decimal>{0, 0});
                        totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                        totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name, new List<Decimal>{0, 0});
                        totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name, new List<Decimal>{0, 0});
                        //totalRatesMap.get(priceListStatementId).put(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name, new List<Decimal>{0, 0});
                    }
                    Map<String, List<Decimal>> totalsMap = totalRatesMap.get(priceListStatementId);
                    totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[0] += item.get('SellInTotalQtywUnitGrossPriceGap__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPriceGap__c') : 0;
                    totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[1] += item.get('SellInTotalQtywUnitGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPriceP1__c') : 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywGrossPricewNetTaxGap__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPricewNetTaxGap__c') : 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellInTotalQtywGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPricewNetTaxP1__c'): 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0] += item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPricewNetTaxGap__c') : 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1] += item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') != null ? (Decimal)item.get('SellInTotalQtywUnitGrossPricewNetTaxP1__c') : 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0] += item.get('SellInTotalQtyTaxesGap__c') != null ? (Decimal)item.get('SellInTotalQtyTaxesGap__c') : 0;
                    totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1] += item.get('SellInTotalQtyTaxesP1__c') != null ? (Decimal)item.get('SellInTotalQtyTaxesP1__c') : 0;
                    //totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name)[0] += item.get('SellInTotalQtywGrossPriceP1__c') != null ? (Decimal)item.get('SellInTotalQtywGrossPriceP1__c') : 0;
                    totalRatesMap.put(priceListStatementId, totalsMap);
                }
            }
            Map<Id, PriceListStatement__c> priceListStmtRefMap = new Map<Id, PriceListStatement__c>([SELECT Id, RecordTypeId, PriceEvolutionRateCalculated__c,
                                                                    PriceEvolutionRateInclTaxCalculated__c, TaxEvolutionRateCalculated__c, Comment__c, UnitPriceEvolutionRateInclTaxCalculated__c,
                                                                    PriceListStatementReference__c, PriceListStatementReference__r.RecordTypeId,
                                                                    PriceListStatementReference__r.PriceListStatementReference__r.RecordTypeId
                                                                    FROM PriceListStatement__c
                                                                    WHERE Id IN :totalRatesMap.keySet()]);
            updatedPriceListStatementList = priceListStmtRefMap.values();
            if (!updatedPriceListStatementList.isEmpty() && !totalRatesMap.isEmpty()) {
                for (PriceListStatement__c item : updatedPriceListStatementList) {
                    Map<String, List<Decimal>> totalsMap = totalRatesMap.get(item.Id);
                    Decimal sellInTotalUnitGap = 0, sellInTotalUnitP1 = 0, sellInTotalwNetTaxGap = 0, sellInTotalwNetTaxP1 = 0, sellInTotalUnitwNetTaxGap = 0, sellInTotalUnitwNetTaxP1 = 0, sellInTotalTaxesGap = 0, sellInTotalTaxesP1 = 0, SellInTotalwCostPriceP1 = 0;
                    sellInTotalUnitGap = totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[0];
                    sellInTotalUnitP1 = totalsMap.get('Rise_PriceEvolutionRateCalculated__c')[1];
                    sellInTotalwNetTaxGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[0];
                    sellInTotalwNetTaxP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name)[1];
                    sellInTotalUnitwNetTaxGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[0];
                    sellInTotalUnitwNetTaxP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name)[1];
                    sellInTotalTaxesGap = totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[0];
                    sellInTotalTaxesP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name)[1];
                    //SellInTotalwCostPriceP1 = totalsMap.get(SObjectType.PriceListStatement__c.fields.SellInTotalQtywGrossPriceP1__c.Name)[0];
                    Decimal riseDepreciationRateCalculated = sellInTotalUnitP1 != 0 ? (sellInTotalUnitGap/sellInTotalUnitP1)*100 : 0;
                    Decimal riseRateCostPricewNetTaxCalculated = sellInTotalwNetTaxP1 != 0 ? (sellInTotalwNetTaxGap/sellInTotalwNetTaxP1)*100 : 0;
                    Decimal riseRateCostPriceUnitwNetTaxCalculated = sellInTotalUnitwNetTaxP1 != 0 ? (sellInTotalUnitwNetTaxGap/sellInTotalUnitwNetTaxP1)*100 : 0;
                    Decimal riseRateTaxCalculated = sellInTotalTaxesP1 != 0 ? (sellInTotalTaxesGap/sellInTotalTaxesP1)*100 : 0;
                    Id refRecordTypeId = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.RecordTypeId;
                    Id refRef_RecordTypeId = priceListStmtRefMap.get(item.Id)?.PriceListStatementReference__r?.PriceListStatementReference__r?.RecordTypeId;
                    Boolean isRiseRate = riseRateRecordtypeIdSet.contains(item.RecordTypeId);
                    Boolean isDepreciationRate = depreciationRateRecordtypeIdSet.contains(item.RecordTypeId);
                    Boolean isoPartner_From_RiseRate = item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && riseRateRecordtypeIdSet.contains(refRecordTypeId);
                    Boolean isoPartner_From_Depreciation_Rate = item.RecordTypeId == priceListStatementRTIds.get('IsoPartner') && depreciationRateRecordtypeIdSet.contains(refRecordTypeId);
                    Boolean simulation_From_RiseRate = item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (riseRateRecordtypeIdSet.contains(refRef_RecordTypeId) || riseRateRecordtypeIdSet.contains(refRecordTypeId));
                    Boolean simulation_From_Depreciation_Rate = item.RecordTypeId == priceListStatementRTIds.get('Simulation') && (depreciationRateRecordtypeIdSet.contains(refRef_RecordTypeId) || depreciationRateRecordtypeIdSet.contains(refRecordTypeId));
                    if (isDepreciationRate || isoPartner_From_Depreciation_Rate || simulation_From_Depreciation_Rate) {
                        if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                            Integer commentLength =  Schema.SObjectType.PriceListStatement__c.fields.getMap().get(SObjectType.PriceListStatement__c.fields.Comment__c.Name).getDescribe().getLength();
                            item.Comment__c = item.Comment__c != null && item.Comment__c.Length() < (commentLength - 700) ? item.Comment__c + ' \n ' : '';
                            Decimal depTop = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                            item.PriceEvolutionRateCalculated__c = (riseDepreciationRateCalculated < depTop && riseDepreciationRateCalculated > -depTop) ? riseDepreciationRateCalculated : (riseDepreciationRateCalculated > 0 ? depTop - 1 : -depTop + 1);
                            if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                                item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to ' + item.PriceEvolutionRateCalculated__c + ' \n';
                            }
                        }
                    }
                    if (isRiseRate || isoPartner_From_RiseRate || simulation_From_RiseRate) {
                        Integer commentLength =  Schema.SObjectType.PriceListStatement__c.fields.getMap().get(SObjectType.PriceListStatement__c.fields.Comment__c.Name).getDescribe().getLength();
                        item.Comment__c = item.Comment__c != null && item.Comment__c.Length() < (commentLength - 700) ? item.Comment__c + ' \n ' : '';
                        Decimal top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                        if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                            item.PriceEvolutionRateCalculated__c = (riseDepreciationRateCalculated < top && riseDepreciationRateCalculated > -top) ? riseDepreciationRateCalculated : (riseDepreciationRateCalculated > 0 ? top - 1 : -top + 1);
                            if (item.PriceEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                                item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to ' + item.PriceEvolutionRateCalculated__c + ' \n';
                            }
                        }
                        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.scale);
                        if (item.PriceEvolutionRateInclTaxCalculated__c != riseRateCostPricewNetTaxCalculated) {
                            item.PriceEvolutionRateInclTaxCalculated__c = (riseRateCostPricewNetTaxCalculated < top && riseRateCostPricewNetTaxCalculated > -top) ? riseRateCostPricewNetTaxCalculated : (riseRateCostPricewNetTaxCalculated > 0 ? top - 1 : -top + 1);
                            if (item.PriceEvolutionRateInclTaxCalculated__c != riseRateCostPricewNetTaxCalculated) {
                                item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name + ') result : ' + String.valueOf(riseRateCostPricewNetTaxCalculated)  + ' Adjusted to with ' +item.PriceEvolutionRateInclTaxCalculated__c + ' \n';
                            }
                        }
                        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.precision - SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.scale);
                        if (item.UnitPriceEvolutionRateInclTaxCalculated__c != riseRateCostPriceUnitwNetTaxCalculated) {
                            item.UnitPriceEvolutionRateInclTaxCalculated__c = (riseRateCostPriceUnitwNetTaxCalculated < top && riseRateCostPriceUnitwNetTaxCalculated > -top) ? riseRateCostPriceUnitwNetTaxCalculated : (riseRateCostPriceUnitwNetTaxCalculated > 0 ? top - 1 : -top + 1);
                            if (item.UnitPriceEvolutionRateInclTaxCalculated__c != riseRateCostPriceUnitwNetTaxCalculated) {
                                item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.UnitPriceEvolutionRateInclTaxCalculated__c.Name + ') result : ' + String.valueOf(riseRateCostPriceUnitwNetTaxCalculated)  + ' Adjusted to with ' +item.UnitPriceEvolutionRateInclTaxCalculated__c + ' \n';
                            }
                        }
                        top = (10.0).pow(SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.precision - SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.scale);
                        if (item.TaxEvolutionRateCalculated__c != riseRateTaxCalculated) {
                            item.TaxEvolutionRateCalculated__c = (riseRateTaxCalculated < top && riseRateTaxCalculated > -top) ? riseRateTaxCalculated : (riseRateTaxCalculated > 0 ? top - 1 : -top + 1);
                            if (item.TaxEvolutionRateCalculated__c != riseDepreciationRateCalculated) {
                                item.Comment__c += system.now() + ' : ' + SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Label + ' (' + SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name + ') result : ' + String.valueOf(riseDepreciationRateCalculated)  + ' Adjusted to with ' + item.TaxEvolutionRateCalculated__c + ' \n';
                            }
                        }
                    }
                    //item.SellInTotalQtywGrossPriceP1__c = SellInTotalwCostPriceP1;
                }
                // check security on access PriceListStatement__c fields
                String[] priceListStatementDetailsUpdateFields = new String[] {
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.PriceEvolutionRateInclTaxCalculated__c.Name,
                    SObjectType.PriceListStatement__c.fields.TaxEvolutionRateCalculated__c.Name
                };
                if (NegoptimHelper.checkUpdatibility(PriceListStatement__c.SObjectType, priceListStatementDetailsUpdateFields)) {
                    Database.update(updatedPriceListStatementList);
                }
            }
        }
    }

    /**
     * @description ON AFTER UPDATE
     * calculate PriceEvolutionRateCalculated__c
     */
    public static void bottomUpValues(List<PriceListStatementDetail__c> newPriceListStatementDetails, Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap) {
        system.debug('bottomUpValues >>> ');
        Boolean afterDelete = newPriceListStatementDetails == null;
        Set<Id> priceListStatementIdSet = new Set<Id>();
        // loop over newPriceListStatements
        if(!afterDelete) {
            for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
                system.debug('bottomUpValues >>> ');
                if ((oldPriceListStatementDetailsMap == null && ((item.SellInTotalQtywUnitGrossPriceP1__c != null && item.SellInTotalQtywUnitGrossPriceP1__c != 0)
                                                                 || (item.SellInTotalQtywGrossPricewNetTaxP1__c != null && item.SellInTotalQtywGrossPricewNetTaxP1__c != 0)
                                                                 || (item.SellInTotalQtywUnitGrossPricewNetTaxP1__c != null && item.SellInTotalQtywUnitGrossPricewNetTaxP1__c != 0)
                                                                 || (item.SellInTotalQtyTaxesP1__c != null && item.SellInTotalQtyTaxesP1__c != 0)
                                                                 || (item.SellInTotalQtywGrossPriceP1__c != null && item.SellInTotalQtywGrossPriceP1__c != 0)))
                    || (oldPriceListStatementDetailsMap != null
                        && oldPriceListStatementDetailsMap.containsKey(item.Id)
                        && (item.SellInTotalQtywUnitGrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPriceP1__c
                            || item.SellInTotalQtywGrossPricewNetTaxP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywGrossPricewNetTaxP1__c
                            || item.SellInTotalQtywUnitGrossPricewNetTaxP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywUnitGrossPricewNetTaxP1__c
                            || item.SellInTotalQtyTaxesP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtyTaxesP1__c
                            || item.SellInTotalQtywGrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQtywGrossPriceP1__c
                            || item.GrossPriceProgress__c != oldPriceListStatementDetailsMap.get(item.Id).GrossPriceProgress__c
                            || item.GrossPrice__c != oldPriceListStatementDetailsMap.get(item.Id).GrossPrice__c
                            || item.GrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).GrossPriceP1__c
                            || item.TotalTaxes__c != oldPriceListStatementDetailsMap.get(item.Id).TotalTaxes__c
                            || item.TotalTaxesP1__c != oldPriceListStatementDetailsMap.get(item.Id).TotalTaxesP1__c
                            || item.UnitGrossPrice__c != oldPriceListStatementDetailsMap.get(item.Id).UnitGrossPrice__c
                            || item.UnitGrossPriceP1__c != oldPriceListStatementDetailsMap.get(item.Id).UnitGrossPriceP1__c
                            || item.SellInTotalQty__c != oldPriceListStatementDetailsMap.get(item.Id).SellInTotalQty__c
                            || item.SellInPromoQty__c != oldPriceListStatementDetailsMap.get(item.Id).SellInPromoQty__c)))
                {
                    system.debug('INNNN >>> ');
                    priceListStatementIdSet.add(item.PriceListStatement__c);
                }
            }
        } else {
            for (PriceListStatementDetail__c item : oldPriceListStatementDetailsMap.values()) {
                priceListStatementIdSet.add(item.PriceListStatement__c);
            }
        }
        if (!priceListStatementIdSet.isEmpty()) {
            Map<Id, PriceListStatement__c> priceListStmtRefMap = new Map<Id, PriceListStatement__c>([SELECT Id, PriceEvolutionRateCalculated__c,
                                                                                                     PriceEvolutionRateInclTaxCalculated__c,
                                                                                                     UnitPriceEvolutionRateCalculated__c,
                                                                                                     UnitPriceEvolutionRateInclTaxCalculated__c,
                                                                                                     TaxEvolutionRateCalculated__c
                                                                                                     FROM PriceListStatement__c
                                                                                                     WHERE Id IN :priceListStatementIdSet]);
            List<PriceListStatementDetail__c> priceListStatementDetails = (List<PriceListStatementDetail__c>) JSON.deserialize(JSON.serialize(newPriceListStatementDetails), List<PriceListStatementDetail__c>.class);
            for (PriceListStatementDetail__c item : priceListStatementDetails) {
                if (priceListStmtRefMap.containsKey(item.PriceListStatement__c)) {
                    item.PriceListStatement__r = priceListStmtRefMap.get(item.PriceListStatement__c);
                }
            }
            Map<Id, PriceListStatement__c> priceListStatements = new Map<Id, PriceListStatement__c>(PriceListStatementService.calculateSellInFields(priceListStmtRefMap.values()));
            system.debug('111priceListStatements >>> ' + JSON.serialize(priceListStatements));
            for (PriceListStatementDetail__c item : priceListStatementDetails) {
                if (priceListStatements.containsKey(item.PriceListStatement__c)) {
                    item.PriceListStatement__r = priceListStatements.get(item.PriceListStatement__c);
                }
            }
            system.debug('222priceListStatements >>> ' + JSON.serialize(priceListStatements));
            update priceListStatements.values();
            //System.Formula.recalculateFormulas(priceListStatementDetails);
            priceListStatements = new Map<Id, PriceListStatement__c>(PriceListStatementService.calculateEvolutions(priceListStmtRefMap.values()));
            system.debug('333priceListStatements >>> ' + JSON.serialize(priceListStatements));
            update priceListStatements.values();
        }
    }
    /**
     * @description ON AFTER UPDATE
     * Stop UN when Target_Product_Life_Status__c = Stop and the related product is Unit Need
     */
    // public static void stopUnitNeedProducts(List<PriceListStatementDetail__c> newPriceListStatementDetails, Map<Id, PriceListStatementDetail__c> oldPriceListStatementDetailsMap) {
    //     Set<Id> productsToStopId = new Set<Id>();
    //     for (PriceListStatementDetail__c item : newPriceListStatementDetails) {
    //         if (oldPriceListStatementDetailsMap?.get(item.Id)?.Target_Product_Life_Status__c != item.Target_Product_Life_Status__c && item.Target_Product_Life_Status__c == 'Stop' && item.PG__c != null) {
    //             productsToStopId.add(item.PG__c);
    //         }
    //     }
    //     if (!productsToStopId.isEmpty()) {
    //         String[] product2Fields = new String[] {
    //             SObjectType.Product2.fields.Id.Name,
    //             SObjectType.Product2.fields.isActive.Name,
    //             SObjectType.Product2.fields.RecordTypeId.Name,
    //             SObjectType.Product2.fields.Status__c.Name
    //         };
    //         if (NegoptimHelper.checkAccessibility(Product2.SObjectType, product2Fields)) {
    //             List<Product2> productsToStop = [SELECT Id
    //                                             FROM Product2
    //                                             WHERE Id IN :productsToStopId
    //                                             AND RecordType.DeveloperName = 'Unit_Need'
    //                                             AND (isActive = TRUE OR Status__c <> 'Closed')];
    //             for (Product2 item : productsToStop) {
    //                 item.IsActive = false;
    //                 item.Status__c = 'Closed';
    //                 item.Market_End_of_Life_Date__c = Date.today();
    //             }
    //             String[] product2UpdateFields = new String[] {
    //                 SObjectType.Product2.fields.IsActive.Name,
    //                 SObjectType.Product2.fields.Status__c.Name,
    //                 SObjectType.Product2.fields.Market_End_of_Life_Date__c.Name
    //             };
    //             if (NegoptimHelper.checkUpdatibility(Product2.SObjectType, product2UpdateFields)) {
    //                 update productsToStop;
    //             }
    //             String[] supplierPGMappingFields = new String[] {
    //                 SObjectType.PG__c.fields.Status__c.Name,
    //                 SObjectType.PG__c.fields.Product__c.Name
    //             };
    //             if (!productsToStop.isEmpty() && NegoptimHelper.checkAccessibility(PG__c.SObjectType, supplierPGMappingFields)) {
    //                 List<PG__c> supplierPgMappingToStop = [SELECT Id FROM PG__c WHERE Product__c IN :productsToStop AND Status__c <> 'Close'];
    //                 for (PG__c item : supplierPgMappingToStop) {
    //                     item.Status__c = 'Close';
    //                 }
    //                 String[] supplierPGMappingUpdateFields = new String[] {
    //                     SObjectType.PG__c.fields.Status__c.Name
    //                 };
    //                 if (!supplierPgMappingToStop.isEmpty() && NegoptimHelper.checkUpdatibility(PG__c.SObjectType, supplierPGMappingUpdateFields)) {
    //                     update supplierPgMappingToStop;
    //                 }
    //             }
    //         }
    //     }
    // }
    
    /**
     * @author ULiT
     * @date 05/04/2023
     * @description wrapper class used to serialize and deserialize active taxes on the level of Price Statement
    */
    public class StatementWrapper {
        // the Id of the Tax__c record or the Pol_Com_Condition__c record
        public Id recordId {get; set;}
        // the name of the Tax__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Tax__c / 1-19 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        
        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
        }
    }
}