/**
 * @author ULiT
 * @description Handler for the trigger Trg_Product_Handler
 **/
public with sharing class Trg_Product_Handler {

    private static final Id productRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.getSObjectType(), 'Product');
    private static final Id userProfileId = UserInfo.getProfileId();
    public static Boolean isOrgCPG {
        get {
            if (isOrgCPG == null) {
                // load custom settings
                NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
                isOrgCPG = settings.sBusinessType != null && settings.sBusinessType.equals('CPG');
            }
            return isOrgCPG;
        }
        set;
    }

    public static void OnBeforeInsert(List<Product2> newProducts) {
        overrideProductNameWithAutoNum(newProducts);
        
    }
    
    public static void OnBeforeUpdate(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) {
        if(isOrgCPG) {
            // insert stop product introduction history
            insertProductIntroductionHistoryStop(newProducts, oldProductsMap);
        }
        validateConstraint(newProducts, oldProductsMap);
    }

    public static void OnBeforeDelete(Map<Id, Product2> oldProductsMap) {
        cleanUpRelatedList(oldProductsMap);
    }

    public static void OnAfterInsert(List<Product2> newProducts) {
        if(isOrgCPG) {
            // insert inno product introduction history
            //insertProductIntroductionHistoryInno(newProducts);
        }
    }

    public static void OnAfterUpdate(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) { }
    
    public static void OnAfterInsertOrUpdate(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) {
        // update ReferenceProductType
        updatedReferenceProducts(newProducts, oldProductsMap);
    }

    /**
     * @description insert "Stop" product introduction history when product is stopped
     * on Before Update
	*/
    private static void insertProductIntroductionHistoryStop(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) {
        Map<Id, Product2> newProductsMap = new Map<Id, Product2>(newProducts);
        // check allowed profile access to manage Record type(Product)
        List<String> allowedProfiles = GlobalSettingsManager.loadGlobalSettings().allowedProfilesToManageProducts;
        Boolean readOnlyUser = allowedProfiles == null || allowedProfiles.isEmpty() || !allowedProfiles.contains(userProfileId);
        Set<Id> stopedProductsIdSet = new Set<Id>();
        // Iterate over all products which are on update mode in order to fill the set of products.
        for (Product2 item : newProducts) {
            if (item.RecordTypeId == productRecordTypeId && readOnlyUser) {
                item.addError(String.format(Label.MSG_Insufficient_Permissions_To_Update_Product, new String[]{item.Name}));
                continue;
            }
            if (item.Market_End_of_Life_Date__c != null && oldProductsMap != null && oldProductsMap.get(item.Id).Market_End_of_Life_Date__c == null) {
                stopedProductsIdSet.add(item.id);
            }
        }

    }
    /**
     * @description check readonly user and validate the name
     * on Before Update
	 */
    private static void validateConstraint(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) {
        ProductSettings productSettings = ProductSettings.loadProductSettings();
        // check allowed profile access to manage Record type(Product)
        List<String> allowedProfiles = GlobalSettingsManager.loadGlobalSettings().allowedProfilesToManageProducts;
        Boolean readOnlyUser = allowedProfiles == null || allowedProfiles.isEmpty() || !allowedProfiles.contains(userProfileId);
        // Iterate over all products which are on update mode in order to fill the set of products.
        for (Product2 item : newProducts) {
            if (item.RecordTypeId == productRecordTypeId && readOnlyUser) {
                item.addError(String.format(Label.MSG_Insufficient_Permissions_To_Update_Product, new String[]{item.Name}));
                continue;
            }
            // only allow update on name when the settings allows it: if ProductSettings__c.IsAutoNumberProductName__c is true and product name has changed => throw error
            if (productSettings.isAutoNumberProductName
                && item.Name != oldProductsMap.get(item.Id).Name)
            {
                item.addError('La mise à jour du nom du produit n\'est pas autorisée lorsque '
                              + SObjectType.ProductSettings__c.fields.IsAutoNumberProductName__c.label
                              + ' est vrai dans la page Global Settings');
            }
        }
    }
    /**
     * @description clean up data
     * on Before Delete
	*/
    private static void cleanUpRelatedList(Map<Id, Product2> oldProductsMap) {
        // check allowed profile access to manage Record type(Product)
        List<String> allowedProfiles = GlobalSettingsManager.loadGlobalSettings().allowedProfilesToManageProducts;
        Boolean readOnlyUser = allowedProfiles == null || allowedProfiles.isEmpty() || !allowedProfiles.contains(userProfileId);
        Set<Id> productIdSet = System.Trigger.oldMap.keySet();
        for (Product2 item : oldProductsMap.values()) {
            if (item.RecordTypeId == productRecordTypeId && readOnlyUser) {
                item.addError(string.format(Label.MSG_Insufficient_Permissions_To_Delete_Product, new String[]{item.Name}), false);
                productIdSet.remove(item.Id);
            }
        }
        // check security on access CommercialPlanDetail__c fields
        String[] commercialPlanDetailFields = new String[] {
            SObjectType.CommercialPlanDetail__c.fields.Product__c.Name
        };
        if(NegoptimHelper.checkAccessibility(CommercialPlanDetail__c.SObjectType, commercialPlanDetailFields)) {
            // Check if Product has related Commercial_Plan_Detail__c
            List<AggregateResult> arList = [SELECT Product__c pId, COUNT(Id) c
                                            FROM CommercialPlanDetail__c
                                            WHERE Product__c IN :oldProductsMap.keySet()
                                            GROUP BY Product__c];
            for (AggregateResult item : arList) {
                Id pId = (Id)item.get('pId');
                if (Integer.valueOf(item.get('c')) > 0) {
                    oldProductsMap.get(pId).addError(String.format(Label.MSG_Cannot_Delete_Product_Linked_To_Commercial_Plan_Detail, new String[]{oldProductsMap.get(pId).Name }));
                    productIdSet.remove(pId);
                }
            }
        }
    }

    /**
     * @description update Product_Reference_Type__c
     * On After Insert or Update
	*/
    private static void updatedReferenceProducts(List<Product2> newProducts, Map<Id, Product2> oldProductsMap) {
        // Set of referenced Product Ids
        Set<Id> referenceProductsIdSet = new Set<Id>();
        // Set of Product Ids that are no longer referenced
        Set<Id> unreferenceProductsIdSet = new Set<Id>();
        // Set of referenced Product Ids of type switch
        Set<Id> switchProductsIdSet = new Set<Id>();
        // List of referenced Products
        List<Product2> referenceProducts = new List<Product2>();
        // Map referenced product Id the product referencing it
        Map<Id, Product2> referenceIdToProductMap = new Map<Id, Product2>();
        // check security on Product2 fields
        String[] productFields = new String[] {
            SObjectType.Product2.fields.Product_Reference_Type__c.Name
        };
        for (Product2 item : newProducts) {
            if (oldProductsMap == null || (oldProductsMap != null && item.Reference_Product__c != oldProductsMap.get(item.Id).Reference_Product__c)) {
                if (item.Reference_Product__c != null) {
                    referenceProductsIdSet.add(item.Reference_Product__c);
                    referenceIdToProductMap.put(item.Reference_Product__c, item);
                    // isSwitch or none are selected, then add to switchProductsIdSet to update Product_Reference_Type to switch in reference Products
                    if (item.isSwitch__c || (!item.isSwitch__c && !item.isRenovation__c)) {
                        switchProductsIdSet.add(item.Reference_Product__c);
                    }
                }
                if (oldProductsMap != null && oldProductsMap.get(item.Id).Reference_Product__c != null  && !referenceProductsIdSet.contains(oldProductsMap.get(item.Id).Reference_Product__c)) {
                    unreferenceProductsIdSet.add(oldProductsMap.get(item.Id).Reference_Product__c);
                }
            }
        }
        // update Product_Reference_Type__c
        if(!referenceProductsIdSet.isEmpty() || !unreferenceProductsIdSet.isEmpty()) {
            if(NegoptimHelper.checkAccessibility(Product2.SObjectType, productFields)) {
                for(Product2 item: [SELECT Product_Reference_Type__c From Product2 WHERE Id IN :referenceProductsIdSet OR Id IN :unreferenceProductsIdSet]) {
                    if(referenceProductsIdSet.contains(item.Id)) {
                        if (item.Product_Reference_Type__c == null) {
                            item.Product_Reference_Type__c = switchProductsIdSet.contains(item.Id) ? 'Switch' : 'Reno';
                            referenceProducts.add(item);
                        } else {
                            referenceIdToProductMap.get(item.id).addError('Invalid Reference Product');
                        }
                    } else if(unreferenceProductsIdSet.contains(item.Id)) {
                        item.Product_Reference_Type__c = null;
                        referenceProducts.add(item);
                    }
                }
            }
        }
        if (!referenceProducts.isEmpty()) {
            try {
                if(NegoptimHelper.checkUpdatibility(Product2.SObjectType, productFields)) {
                    update referenceProducts;
                }
            } catch (DMLException ex) { }
        }
    }
    /**
     * @description populates the field Name with an auto number sequence on creation of a product if and only if
     * global settings allows it (ProductSettings__c.IsAutoNumberProductName__c)
     * the auto number sequence is created by concatenating ProductSettings__c.Product_Name_Prefix__c and
     * ProductSettings__c.IsAutoNumberProductName__c padded with 0's until the name is 10 characters in length
     * After all products are renamed, the new auto number is saved in ProductSettings__c.IsAutoNumberProductName__c for the next use
    */
    private static void overrideProductNameWithAutoNum(List<Product2> newProducts) {
        ProductSettings productSettings = ProductSettings.loadProductSettings();
        // only override product name with autonum if settings allow it
        if (productSettings.isAutoNumberProductName) {
            Integer autoNum = productSettings.autoNumberLastValue == null ? productSettings.autoNumberLastValue = 0 : productSettings.autoNumberLastValue;
            String autoNumberPrefix = String.isBlank(productSettings.autoNumberPrefix) ? 'Prod' : productSettings.autoNumberPrefix;
            for (Product2 product: newProducts) {
                if (product.Name != null && product.Product_Name__c == null) {
                    product.Product_Name__c = product.Name;
                }
                product.Name = autoNumberPrefix + (String.valueOf(autoNum++)).leftPad(10, '0');
            }
            productSettings.autoNumberLastValue = autoNum;
            ProductSettings.save(productSettings);
        }
    }
}