/**
 * @author ULiT
 * @date 26/03/2026
 * @description used for manage SynchroProductToPg
 **/

 //batch name + recordTypeName missing
public with sharing class SynchroProductToPgController {
    @AuraEnabled
    public static String initData() {
        try {
            List<String> safeStaticFields = new List<String> {SObjectType.product2.fields.Name.Name};
            GridSettingsManager gridSettingsManager = new GridSettingsManager(SObjectType.product2.Name, '', String.join(safeStaticFields, ', '), 'SynchroProductToPg');
            MainWrapper mainWrapper = new MainWrapper(gridSettingsManager);
            return JSON.serialize(mainWrapper);
        } catch (Exception e) {
            system.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String loadData(String gridSettings, Integer pageSize, Integer pageNumber) {
        try {
            GridSettingsManager gridSettingsManager = (GridSettingsManager) JSON.deserialize(gridSettings, GridSettingsManager.class);
            List<String> conditions = getConditions();
            String query = gridSettingsManager.buildQuery(null, conditions, null);
            System.debug('queryyyyy>>>> '+ query);
            ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            setController.setPageSize(pageSize == null ? gridSettingsManager.Default_Page_Size : pageSize);
            setController.setPageNumber(pageNumber);
            LoadWrapper loadWrapper = new LoadWrapper();
            loadWrapper.records = setController.getRecords();
            try {
                query = gridSettingsManager.buildCountQuery(conditions);
                loadWrapper.total = (Integer)(Database.query(query)[0].get('objectCount'));
                system.debug('Total Records: ' + loadWrapper.total);
            } catch(Exception ex) { loadWrapper.total = 0; }    
            return JSON.serialize(loadWrapper);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String ProductToPGBatch(Id supplierId, List<Id> productIds) {
        try {
            Set<Id> productIdSet = new Set<Id>(productIds);
            //NegoptimBatch.executeBatch(new ProductToPGBatchExt(SynchroProductToPgController.class.getName(),productIdSet,new Set<Id>{ supplierId }), 1);
            return 'Batch Job Started';
        } catch (Exception e) {
            System.debug('ProductToPGBatch error: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<String> getConditions() {
        List<String> conditions = new List<String>();
        //RecordType.DeveloperName = 'BGR_Produit' AND IsActive = true 
        conditions.add('RecordType.DeveloperName = \'BGR_Produit\'');
        conditions.add('IsActive = true ');
        return conditions;
    }

    public class MainWrapper {
        public GridSettingsManager gridSettingsManager {get; set;}
        public MainWrapper(GridSettingsManager gridSettingsManager) {
            this.gridSettingsManager = gridSettingsManager;
        }
    }

    public class LoadWrapper {
		public List<SObject> records;
		public Integer total;
	}
}