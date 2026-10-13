public with sharing class Trg_Supplier_Handler {
	
    private static String key;
    
    public static void OnBeforeInsertOrUpdate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
    	setStatusToClose(nSuppliers, oSupplierMap);
    }
    
    public static void OnBeforeInsert(List<Supplier__c> nSuppliers) {
        checkDupCodeCountryOriginOnInsert(nSuppliers);
        // Create Account before create Supplier
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        if (negoSettings.Allow_Insert_Account_On_Insert_Supplier){
            insertAccountForSupplier(nSuppliers);
        }
        ConnectSettings connectSettings = ConnectSettings.loadConnectSettings();
        if (connectSettings != null) {
            Boolean activation = connectSettings.licenseQuotas.activation;
            Integer licensePerSupplier = connectSettings.licenseQuotas.licensePerSupplier;
            if (activation == true) {
                setLicenseQuota(nSuppliers, licensePerSupplier);
            }
        }
    }
    
    public static void OnBeforeUpdate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        checkDupCodeCountryOriginOnUpdate(nSuppliers, oSupplierMap);
        // Set Supplier's EDate__c to system.today()
        setStatusEndDate(nSuppliers, oSupplierMap);
        // Update relevant GlobalLocation CurrencyIsoCode and ReferenceLanguage__c fields
        updateGlobalLocationsFromSuppliers(nSuppliers, oSupplierMap);
    }
    
    public static void OnAfterInsert(List<Supplier__c> nSuppliers) {
        insertDefaultNS(nSuppliers);
    }
    
    public static void OnAfterUpdate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        // setNegoScopeAddresses(nSuppliers, oSupplierMap);
        // Rename the Supplier's account when Supplier Renamed
        renameAccount(nSuppliers, oSupplierMap);
        // Deactivate the Supplier's account's Users when Supplier deactivated
        deactivateUsers(nSuppliers, oSupplierMap);
    }
    
    public static void OnAfterInsertOrUpdate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        updateAccountOfSupplier(nSuppliers, oSupplierMap);
    }
    /*
	 * Insert default NS.
     * @param List<Sup_Supplier__c> nSuppliers
     * On After Insert.
     **/
    private static void insertDefaultNS(List<Supplier__c> nSuppliers) {
        List<NegoScope__c> negoScopes = new List<NegoScope__c>();
       for(Supplier__c supplier : nSuppliers) {
           if(supplier.t_CreateDefaultNegoScope__c) {
               String negoscopeName = System.Label.LBL_Default_NegoScope + ' - ' + supplier.Name;
               //Creation of default NS
               NegoScope__c negoScope = new NegoScope__c(Name = negoscopeName,
                                                         CurrencyIsoCode = supplier.CurrencyIsoCode,
                                                         OwnerId = UserInfo.getUserId(),
                                                         Supplier__c = supplier.Id,
                                                         IncludeAllBrands__c = true,
                                                         IncludeAllHEs__c = true,
                                                         IncludeAllProducts__c = true);
                negoScopes.add(negoScope);
            }
        }
        if (negoScopes.size() > 0) {
            String[] negoscopeFields = new String[] {
                SObjectType.NegoScope__c.fields.Name.Name,
                SObjectType.NegoScope__c.fields.CurrencyIsoCode.Name,
                SObjectType.NegoScope__c.fields.OwnerId.Name,
                SObjectType.NegoScope__c.fields.Supplier__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllBrands__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllHEs__c.Name,
                SObjectType.NegoScope__c.fields.IncludeAllProducts__c.Name
            };
            if (NegoptimHelper.checkCreatibility(NegoScope__c.SObjectType, negoscopeFields)) {
                insert negoScopes;
            }
        }
    }
    private static void checkDupCodeCountryOriginOnInsert(List<Supplier__c> nSuppliers) {
    	String errMsg1 = System.Label.MSG_Code_With_CountryOrigin_Already_Exist;
    	Map<String, Supplier__c> codeCountryOriginMap = new Map<String, Supplier__c>();
	    Map<String, Supplier__c> supplierMapCode = new Map<String, Supplier__c>();
	    Map<String, Supplier__c> supplierMapCountryOrigin1 = new Map<String, Supplier__c>();
	    for (Supplier__c supplier : nSuppliers) {
	    	key = supplier.Code__c + '' + supplier.BusinessUnitOrigin__c;
	    	// Check Code__c// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
     		if (codeCountryOriginMap.containsKey(key)) {
         		supplier.addError(errMsg1);
         	} else {
         		codeCountryOriginMap.put(key, supplier);
         		supplierMapCode.put(supplier.Code__c, supplier);
         		supplierMapCountryOrigin1.put(supplier.BusinessUnitOrigin__c, supplier);  
     		}
     		
	    }
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.Code__c.Name,
            SObjectType.Supplier__c.fields.BusinessUnitOrigin__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)) {
            for (Supplier__c supplier : [SELECT Code__c, BusinessUnitOrigin__c
                                         FROM Supplier__c
                                         WHERE Code__c IN :supplierMapCode.KeySet()
                                         AND BusinessUnitOrigin__c IN :supplierMapCountryOrigin1.KeySet()])
            {
                key = supplier.Code__c + '' + supplier.BusinessUnitOrigin__c;
                Supplier__c newSupplier = codeCountryOriginMap.get(key);
                if (newSupplier != null) {
                   newSupplier.Code__c.addError(errMsg1);
                }
            }
        }
    }
    
    private static void checkDupCodeCountryOriginOnUpdate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
    	String errMsg1 = System.Label.MSG_Code_With_CountryOrigin_Already_Exist;
    	Map<String, Supplier__c> codeCountryOriginMap = new Map<String, Supplier__c>();
	    Map<String, Supplier__c> supplierMapCode = new Map<String, Supplier__c>();
	    Map<String, Supplier__c> supplierMapCountryOrigin1 = new Map<String, Supplier__c>();
	    for (Supplier__c supplier : nSuppliers) {
	    	key = supplier.Code__c + '' + supplier.BusinessUnitOrigin__c;
	    	// Check Code__c
            if (supplier.Code__c != oSupplierMap.get(supplier.Id).Code__c ||
         		supplier.BusinessUnitOrigin__c != oSupplierMap.get(supplier.Id).BusinessUnitOrigin__c) {
         		// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         		if (codeCountryOriginMap.containsKey(key)) {
             		supplier.addError(errMsg1);
             	} else {
             		codeCountryOriginMap.put(key, supplier);
             		supplierMapCode.put(supplier.Code__c, supplier);
             		supplierMapCountryOrigin1.put(supplier.BusinessUnitOrigin__c, supplier);  
         		}
     		}
	    }
        String[] supplierFields = new String[] {
            SObjectType.Supplier__c.fields.Code__c.Name,
            SObjectType.Supplier__c.fields.BusinessUnitOrigin__c.Name
        };
        if (NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)) {
            for (Supplier__c supplier : [SELECT Code__c, BusinessUnitOrigin__c
                                             FROM Supplier__c
                                             WHERE Code__c IN :supplierMapCode.KeySet()
                                             AND BusinessUnitOrigin__c IN :supplierMapCountryOrigin1.KeySet()])
            {
                key = supplier.Code__c + '' + supplier.BusinessUnitOrigin__c;
                Supplier__c newSupplier = codeCountryOriginMap.get(key);
                if (newSupplier != null) {
                    newSupplier.Code__c.addError(errMsg1);
                }
            }
        }
    }

    /*
	 * When supplier status end date__c is greater than the current date, and status is close, then status = active.
     * @param List<Sup_Supplier__c> nSuppliers
     * On Before Insert Or Update.
     **/
    private static void setStatusToClose(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
    	// When supplier status end date is greater than the current date, and status is close, then status = active.
    	for (Supplier__c supplier : nSuppliers) {
    		if (supplier.Id == null || (supplier.Id != null && supplier.EDate__c != oSupplierMap.get(supplier.Id).EDate__c)) {
	            if (supplier.EDate__c > system.today() && supplier.Status__c == 'Closed') {
	            	supplier.Status__c = 'Active';
	            }
	        }
    	}
    }

        /*
	 * Set Supplier's LicenseQuota__c to ConnectSettings.LicenseQuotas.licensePerSupplier in case of ConnectSettings.LicenseQuotas.activation is true
     * @param List<Sup_Supplier__c> nSuppliers
     * On Before Insert
     **/
    private static void setLicenseQuota(List<Supplier__c> nSuppliers, Integer licensePerSupplier) {
        for (Supplier__c supplier : nSuppliers) {
            supplier.LicenseQuota__c = licensePerSupplier;
        }
    }
    
      /*
	 * Create Account after create Supplier
     * @param List<Sup_Supplier__c> nSuppliers
     * On before Insert
     **/
    private static void insertAccountForSupplier(List<Supplier__c> nSuppliers) {
        // Map of Account To Insert Supplier as key and Account as value
        Map<Integer, Supplier__c> supplierMap = new Map<Integer, Supplier__c>();
        Map<Integer, Account> accountMap = new Map<Integer, Account>();
        List<Supplier__c> supplierErrorList = new List<Supplier__c>();
        Integer i = 0;
        for (Supplier__c supplier : nSuppliers) {
            // Create Account for new supplier haven't Account
            if (supplier.Account__c == null) {
                if(supplier.name == null){
                    supplierErrorList.add(supplier);
                    supplier.addError('Supplier Name is Empty - ' + JSON.serialize(supplier));
                    continue;
                }
                Account account = new Account();
                account.CurrencyIsoCode = supplier.CurrencyIsoCode;
                account.Name = supplier.Name;
                // populate maps
                supplierMap.put(i, supplier);
                accountMap.put(i, account);
                i++;
            }
        }
        // check security on Account fields
        String[] AccountFields = new String [] { 
            SObjectType.Account.fields.CurrencyIsoCode.Name,
            SObjectType.Account.fields.Name.Name
        };
        if (!accountMap.values().isEmpty()) {
            if (NegoptimHelper.checkCreatibility(Account.SObjectType, AccountFields)) {
                System.debug('accountMap:' + accountMap);
                List<Database.SaveResult> saveResultList = Database.insert(accountMap.values());
                for (Integer j : supplierMap.keySet()) {
                    if (accountMap.get(j).Id != null) {
                        supplierMap.get(j).Account__c = accountMap.get(j).Id;
                    }
                }
                Integer index = 0;
                for (Database.SaveResult saveResult : saveResultList) {
                    if (!saveResult.getErrors().isEmpty()) {
                        accountMap.values().get(index).addError(saveResult.getErrors()[0].getMessage());
                    }
                    index++;
                }
            }
        }
    }
    
    /*
	 * Rename the Supplier's account when Supplier Renamed
     * @param List<Sup_Supplier__c> nSuppliers
     * @param Map<Id, Sup_Supplier__c> oSupplierMap
     * On After Update
     **/
    private static void renameAccount(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        // List Of Account To Update
        List<Account> accountListToUpdate = new List<Account>();
        // Map of Supplier Renamed, Account Id as Key and Sup_Supplier__c as Value
        Map<Id, Supplier__c> accountForSupplier = new Map<Id, Supplier__c>();
        for (Supplier__c supplier : nSuppliers) {
            // get All Account from Renamed Suppliers
            if (!supplier.Name.equals(oSupplierMap.get(supplier.Id).Name) && supplier.Account__c != null) {
                accountForSupplier.put(supplier.Account__c, supplier);
            }
        }
        for (Id accountId : accountForSupplier.keySet()) {
            Account account = new Account(Id = accountId, Name = accountForSupplier.get(accountId).Name);
            accountListToUpdate.add(account);
        }
        // check security on Account fields
        String[] AccountFields = new String [] { 
            SObjectType.Account.fields.Name.Name
        };
        if (!accountListToUpdate.isEmpty()) {
            if (NegoptimHelper.checkUpdatibility(Account.SObjectType, AccountFields)) {
                List<Database.SaveResult> saveResultList = Database.update(accountListToUpdate);
                Integer index = 0;
                for (Database.SaveResult saveResult : saveResultList) {
                    if (!saveResult.getErrors().isEmpty()) {
                        accountListToUpdate.get(index).addError(saveResult.getErrors()[0].getMessage());
                    }
                    index++;
                }
            }
        }
    }
    
    /*
	 * Deactivate the Supplier's account's Users when Supplier deactivated
     * @param List<Sup_Supplier__c> nSuppliers
     * @param Map<Id, Sup_Supplier__c> oSupplierMap
     * On After Update
     **/
    private static void deactivateUsers(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        // List of Supplier to update EDate__c
        // Set Of Account Id To get all related Users
        Set<Id> accountIdsSet = new Set<Id>();
        for (Supplier__c supplier : nSuppliers) {
            // get All Deactivated Supplier
            if (supplier.Status__c != null
				&& !supplier.Status__c.equals(oSupplierMap.get(supplier.Id).Status__c)
				&& supplier.Status__c.equals('Closed')
				&& supplier.Account__c != null)
			{
                accountIdsSet.add(supplier.Account__c);
            }
        }		
        if (!accountIdsSet.isEmpty()) {
			deactivateUsers(accountIdsSet);
		}
    }
    
    /*
	 * Deactivate the Supplier's account's Users when Supplier deactivated
     * @param List<Sup_Supplier__c> nSuppliers
     * @param Map<Id, Sup_Supplier__c> oSupplierMap
     * On After Update
     **/
    @future
    private static void deactivateUsers(Set<Id> accountIdsSet) {
        if (!accountIdsSet.isEmpty()) {
            // check security on User fields
            String[] UserFields = new String [] { 
                SObjectType.User.fields.Id.Name,
                SObjectType.User.fields.IsActive.Name,
                SObjectType.User.fields.accountId.Name
            };
            if (NegoptimHelper.checkAccessibility(User.SObjectType, UserFields)) {
                List<User> usersList = [SELECT Id, IsActive, accountId 
                                        FROM User
                                        WHERE accountId IN:accountIdsSet];
                for (User user : usersList) {
                    user.IsActive = false;
                }
                if (!accountIdsSet.isEmpty()) {
                    // check security on User fields
                    String[] UserFieldsForUpdate = new String [] { 
                        SObjectType.User.fields.IsActive.Name
                    };
                    if (NegoptimHelper.checkUpdatibility(User.SObjectType, UserFieldsForUpdate)) {
                        List<Database.SaveResult> saveResultList = Database.update(usersList);
                        Integer index = 0;
                        for (Database.SaveResult saveResult : saveResultList) {
                            if (!saveResult.getErrors().isEmpty()) {
                                usersList.get(index).addError(saveResult.getErrors()[0].getMessage());
                            }
                            index++;
                        }
                    }
                }
            }
        }
    }
    
    /*
	 * Set Supplier's EDate__c to system.today() after the supplier deactivated
     * @param List<Sup_Supplier__c> nSuppliers
     * @param Map<Id, Sup_Supplier__c> oSupplierMap
     * On Before Update
     **/
    private static void setStatusEndDate(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        for (Supplier__c supplier : nSuppliers) {
            if (!supplier.Status__c.equals(oSupplierMap.get(supplier.Id).Status__c) && supplier.Status__c.equals('Closed')) {
                supplier.EDate__c = system.today();
            }
        }
    }
    /*
     * Verifies if GlobalLocation__c.ReferenceLanguage__c and 
     * GlobalLocation__c.CurrencyIsoCode match the corresponding 
     * fields of their suppliers' ReferenceLanguage__c and CurrencyIsoCode. 
     * If a match is found, updates the global location with the new values.
     * @param List<Sup_Supplier__c> nSuppliers
     * @param Map<Id, Sup_Supplier__c> oSupplierMap
     * On Before Update
     **/
    private static void updateGlobalLocationsFromSuppliers(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        // Transform the new supplier list into a map
        Map<Id, Supplier__c> nSupplierMap = new Map<Id, Supplier__c>();
        for (Supplier__c supplier : nSuppliers) {
            if (oSupplierMap != null
               && oSupplierMap.containsKey(supplier.Id)
               && (supplier.ReferenceLanguage__c != oSupplierMap.get(supplier.Id).ReferenceLanguage__c
                  || supplier.CurrencyIsoCode != oSupplierMap.get(supplier.Id).CurrencyIsoCode))
            {
                nSupplierMap.put(supplier.Id, supplier);  
            }
        }
        if (!nSupplierMap.isEmpty()) {
            // Retrieve and group global locations by supplier
            String[] glFields = new String[] {
                SObjectType.GlobalLocation__c.fields.ReferenceLanguage__c.Name,
                SObjectType.GlobalLocation__c.fields.CurrencyIsoCode.Name,
                SObjectType.GlobalLocation__c.fields.Supplier__c.Name
            };
            if (NegoptimHelper.checkAccessibility(GlobalLocation__c.SObjectType, glFields)) {
                List<GlobalLocation__c> globalLocationList = [SELECT Id, Name, Supplier__c,ReferenceLanguage__c, CurrencyIsoCode
                                                              FROM GlobalLocation__c
                                                              WHERE Supplier__c in :oSupplierMap.keySet()];
                System.debug(globalLocationList);
                Map<Id, List<GlobalLocation__c>> globalLocationsBySupplier = new Map<Id, List<GlobalLocation__c>>();
                for (GlobalLocation__c globalLocation : globalLocationList) {
                    if (!globalLocationsBySupplier.containsKey(globalLocation.Supplier__c)) {
                        globalLocationsBySupplier.put(globalLocation.Supplier__c, new List<GlobalLocation__c>());
                    }
                    globalLocationsBySupplier.get(globalLocation.Supplier__c).add(globalLocation);
                }
                System.debug(globalLocationsBySupplier);
                // For each group of global location retrieve the supplier and check if the ReferenceLanguage__c and CurrencyIsoCode
                // match the corresponding fields of the supplier. If not, update the global location.
                List<GlobalLocation__c> globalLocationsToUpdate = new List<GlobalLocation__c>();
                for (Id supplierId : globalLocationsBySupplier.keySet()) {
                    Supplier__c nSupplier = nSupplierMap.get(supplierId);
                    for (GlobalLocation__c globalLocation: globalLocationsBySupplier.get(supplierId)) {
                        Boolean requiresUpdate = false;
                        GlobalLocation__c globalLocationToUpdate = globalLocation;
                        if (nSupplier.ReferenceLanguage__c != globalLocation.ReferenceLanguage__c) {
                            globalLocationToUpdate.ReferenceLanguage__c = nSupplier.ReferenceLanguage__c;
                            requiresUpdate = true;
                        }
                        if (nSupplier.CurrencyIsoCode != globalLocation.CurrencyIsoCode) {
                            globalLocationToUpdate.CurrencyIsoCode = nSupplier.CurrencyIsoCode;
                            requiresUpdate = true;
                        }
                        
                        if (requiresUpdate == true) {
                            globalLocationsToUpdate.add(globalLocationToUpdate);
                        }
                    }
                }
                
                if (!globalLocationsToUpdate.isEmpty()) {
                    System.debug('globalLocationsToUpdate>>>' + globalLocationsToUpdate);
                    update globalLocationsToUpdate;
                }
            }
        }
    }
    
    /*
	 * update supplier in account after assign an account to supplier 
     * @param List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap
     * On after Insert or Update
     **/
    private static void updateAccountOfSupplier(List<Supplier__c> nSuppliers, Map<Id, Supplier__c> oSupplierMap) {
        Map<Id, Id> SupplierAccountMap = new Map<Id, Id>(); // Id:Account, Id: Supplier
        Set<Id> accountToRemoveSupllier = new Set<Id>();
        List<Account> accountSupToUpdate = new List<Account>();
        String[] AccountFields = new String[]{SObjectType.Account.fields.Supplier__c.Name};
        for (Supplier__c supplier : nSuppliers) {
            if (supplier.Account__c != null
                && (oSupplierMap == null
                    || !oSupplierMap.containsKey(supplier.Id)
                    || (oSupplierMap.containsKey(supplier.Id) && supplier.Account__c != oSupplierMap.get(supplier.Id).Account__c)))
            {
                SupplierAccountMap.put(supplier.Account__c, supplier.Id);
                if (supplier.Id != null && oSupplierMap != null && oSupplierMap.get(supplier.Id).Account__c != null) {
                    accountToRemoveSupllier.add(oSupplierMap.get(supplier.Id).Account__c);
                }
            } else if (supplier.Account__c == null && oSupplierMap != null && oSupplierMap.get(supplier.Id).Account__c != null) {
                accountToRemoveSupllier.add(oSupplierMap.get(supplier.Id).Account__c);
            }
        }
        if (NegoptimHelper.checkUpdatibility(Account.SObjectType, AccountFields)) {
            Set<Id> allAccountsSet = new Set<Id>();
            allAccountsSet.addAll(SupplierAccountMap.keySet());
            allAccountsSet.addAll(accountToRemoveSupllier);
            for (Account acc : [SELECT Id
                                FROM Account
                                WHERE Id IN :allAccountsSet])
            {
                if (SupplierAccountMap.containsKey(acc.Id)) {
                    acc.Supplier__c = SupplierAccountMap.get(acc.Id);
                    accountSupToUpdate.add(acc);
                } else if (accountToRemoveSupllier.contains(acc.Id)) {
                    acc.Supplier__c = null;
                    accountSupToUpdate.add(acc);
                }
            }
            if (!accountSupToUpdate.isEmpty()) {
                List<Database.SaveResult> saveResultList = Database.update(accountSupToUpdate);
                Integer index = 0;
                for (Database.SaveResult saveResult : saveResultList) {
                    if (!saveResult.getErrors().isEmpty()) {
                        accountSupToUpdate.get(index).addError(saveResult.getErrors()[0].getMessage());
                    }
                    index++;
                }
            }
        }
    }

}