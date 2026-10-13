public with sharing class ContractIndexesSummaryCmpCtrl {
    @AuraEnabled()
    public static String initComponentData (String contractId) {
        MainWrapper wMain = new MainWrapper(contractId);
        wMain.contractsString = getContracts(contractId);
        wMain.TimeZone = getTimeZone();
        wMain.contract = getContract(contractId);
        return JSON.serialize(wMain);
    }

    public static String getContracts(String contractId) {
        Contract__c contract = getContract(contractId);
        Contract__c parentContract = new Contract__c();
        Contract__c currentContract = new Contract__c();
        Decimal baseIndex;
        Decimal baseIndexParent;
        List<String> fieldList = new List<String>{
            SObjectType.Contract__c.fields.Id.Name,
            SObjectType.Contract__c.fields.Name.Name,
            SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
            SObjectType.Contract__c.fields.Asynchron_Processing__c.Name,
            SObjectType.Contract__c.fields.Index1__c.Name,
            SObjectType.Contract__c.fields.Index2__c.Name,
            SObjectType.Contract__c.fields.Index3__c.Name,
            SObjectType.Contract__c.fields.Index4__c.Name,
            SObjectType.Contract__c.fields.Index5__c.Name,
            SObjectType.Contract__c.fields.Index6__c.Name,
            SObjectType.Contract__c.fields.Index7__c.Name,
            SObjectType.Contract__c.fields.index1_v2__c.Name,
            SObjectType.Contract__c.fields.index2_v2__c.Name,
            SObjectType.Contract__c.fields.index3_v2__c.Name,
            SObjectType.Contract__c.fields.index4_v2__c.Name,
            SObjectType.Contract__c.fields.index5_v2__c.Name,
            SObjectType.Contract__c.fields.index6_v2__c.Name,
            SObjectType.Contract__c.fields.index7_v2__c.Name,
            SObjectType.Contract__c.fields.TO1__c.Name,
            SObjectType.Contract__c.fields.TO2__c.Name,
            SObjectType.Contract__c.fields.TO3__c.Name,
            SObjectType.Contract__c.fields.TO4__c.Name,
            SObjectType.Contract__c.fields.TO5__c.Name,
            SObjectType.Contract__c.fields.TO6__c.Name,
            SObjectType.Contract__c.fields.TO7__c.Name,
            SObjectType.Contract__c.fields.TO8__c.Name,
            SObjectType.Contract__c.fields.TO9__c.Name,
            SObjectType.Contract__c.fields.TO10__c.Name,
            SObjectType.Contract__c.fields.TO11__c.Name,
            SObjectType.Contract__c.fields.TO12__c.Name,
            SObjectType.Contract__c.fields.Total_TO__c.Name,
            SObjectType.Contract__c.fields.Depreciation_Rate_YE__c.Name,
            SObjectType.Contract__c.fields.Rise_Rate_YE__c.Name,
            SObjectType.Contract__c.fields.Qty1__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Break__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Promo__c.Name,
            SObjectType.Contract__c.fields.Markdown_Rate_Theft__c.Name,
            SObjectType.Contract__c.fields.Qty2__c.Name,
            SObjectType.Contract__c.fields.Qty3__c.Name,
            SObjectType.Contract__c.fields.Qty4__c.Name,
            SObjectType.Contract__c.fields.Qty5__c.Name,
            SObjectType.Contract__c.fields.Qty6__c.Name,
            SObjectType.Contract__c.fields.Qty7__c.Name,
            SObjectType.Contract__c.fields.Qty8__c.Name,
            SObjectType.Contract__c.fields.Qty9__c.Name,
            SObjectType.Contract__c.fields.Qty10__c.Name,
            SObjectType.Contract__c.fields.Qty11__c.Name,
            SObjectType.Contract__c.fields.Qty12__c.Name,
            SObjectType.Contract__c.fields.Reference_Year__c.Name
        };
        fieldList.addAll(
            (NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Parent_Contract__c.Name) + '.'
            + String.join(fieldList, ',' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Parent_Contract__c.Name) + '.')
            ).split(',')
        );
        fieldList.add('toLabel(RecordType.Name)');
        fieldList.add('toLabel(' + NegoptimHelper.getFieldNameAsRelation(SObjectType.Contract__c.fields.Parent_Contract__c.Name) + '.RecordType.Name)');
        String query = 'SELECT ' + String.join(fieldList, ', ') + ' FROM Contract__c WHERE Id = :contractId';
        System.debug(query);
        List<Contract__c> contracts = Database.query(query);
        for(Contract__c item : contracts) {
            if (item.Id == contract.Id) {
                currentContract = item;
                parentContract = item.Parent_Contract__r;
            }
        }
        // base index
        ContractServices contractServiceCur = new ContractServices(currentContract, currentContract.Contract_Discounts__r);
        baseIndex = contractServiceCur.getContractBaseIndex();
        if(parentContract != null) {
            ContractServices contractServiceCurParent = new ContractServices(parentContract, parentContract.Contract_Discounts__r);
            baseIndexParent = contractServiceCurParent.getContractBaseIndex();
        }
        //index1,index2...
        Map<String, String> picklistMap = new Map<String, String>();
        List<PicklistEntry> picklistValues = Pol_Com_Condition__c.index__c.getDescribe().getPicklistValues();
        for (PicklistEntry picklistValue : picklistValues) {
            picklistMap.put(picklistValue.getValue(), picklistValue.getLabel());
        }
        String indexName;
        String contractName = contract.RecordType.Name;
        String parentContractName = parentContract?.RecordType?.Name;
        List<Decimal> indexValue = new List<Decimal>();
        List<indexValues> wIndexValues = new List<indexValues>();
        List<String> sortedKeys = new List<String>(picklistMap.keySet());
        sortedKeys.sort();
        for (String indexNumber: sortedKeys) {
            indexValue =  new List<Decimal>();
            indexName = picklistMap.get(indexNumber).replace('Indice ', '');
            Decimal indexValue1 = currentContract.get('' + indexNumber + '__c') != null ? (Decimal)currentContract.get('' + indexNumber + '__c') : 0;
            indexValue.add(indexValue1.setscale(2));
            Decimal indexValue2 = parentContract?.get('' + indexNumber + '__c') != null ? (Decimal)parentContract?.get('' + indexNumber + '__c') : null;
            indexValue.add(indexValue2?.setscale(2));
            Decimal curValue = currentContract.get('' + indexNumber + '__c') != null ? (Decimal)currentContract.get('' + indexNumber + '__c') : 0;
            Decimal parentValue = parentContract?.get('' + indexNumber + '__c') != null ? (Decimal)parentContract?.get('' + indexNumber + '__c') : 0;
            Decimal indexValue3 = parentValue != 0 ? (curValue - parentValue) / parentValue * 100 : null;
            indexValue.add(indexValue3?.setscale(2));
            wIndexValues.add(new indexValues(indexName, indexValue));
        }
        ContractIndexWrapper contractWrap = new ContractIndexWrapper(contractName, baseIndex, baseIndexParent, wIndexValues);
        contractWrap.baseIndex = baseIndex;
        contractWrap.baseIndexParent = baseIndexParent;
        contractWrap.parentContractName = parentContractName;
        System.debug('contractWrap: ' + JSON.serialize(contractWrap));
        return JSON.serialize(contractWrap);
    }

    public static Contract__c getContract(String contractId) {
        Contract__c contract = [SELECT Id, Name, Is_OnTop_Simulation__c, Status__c, RecordTypeId, toLabel(RecordType.Name), RecordType.DeveloperName, Is_Managed_By_ExternalSource__c, Asynchron_Processing__c,
                                               Supplier_Nego_Scope__c, Reference_Year__c, Supplier__c
                                               FROM Contract__c
                                               WHERE Id = :contractId];
        return contract;
    }

    public static String getTimeZone() {
        Organization org = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1];
        return org.TimeZoneSidKey;
    }

    public class MainWrapper {
        public Contract__c contract;
        public List<Contract__c> contracts;
        public String contractsString;
        public String contractId;
        public String TimeZone;
        public MainWrapper(String contractId) {
            this.contractId = contractId;
            Integer index = 0;
            index = 0;
        }
    }

    public class ContractIndexWrapper {
        public String contractName {get; set;}
        public String parentContractName {get; set;}
        public Decimal baseIndex {get; set;}
        public Decimal baseIndexParent {get; set;}
        public List<indexValues> wIndexValues {get; set;}
        public ContractIndexWrapper(String contractName, Decimal baseInde, Decimal baseIndexParent, List<indexValues> wIndexValues) {
            this.contractName = contractName;
            this.baseIndex = baseIndex;
            this.baseIndexParent = baseIndexParent;
            this.wIndexValues = wIndexValues;
        }
    }
    public class indexValues {
        public String indexName {get; set;}
        public List<Decimal> indexValue {get; set;}
        public indexValues(String indexName, List<Decimal> indexValue) {
            this.indexName = indexName;
            this.indexValue = indexValue;
        }
    }
}