/**
* Controller for the page Duplicate PriceListStatement__c
**/
public with sharing class DuplicatePriceListStatementController extends NegoptimBaseController {
    
    public String recordId;
    public PriceListStatement__c priceListSatement {get; set;}
    public List<String> errors {get; set;}
    public List<SelectOption> sellInRuleOptions {get; set;}
    public String selectedSellInRule {get; set;}
    public Boolean showManualSellInRulePopup {get; set;}
    public WrapperSellInRuleManual wrapperSellInRuleManual {get; set;}
    public Map<Integer, List<Integer>> manualSellInRulesMap;
    public List<PriceListStatement__c> priceListSatementSimulationList { get; set; }
    public Boolean isPollerActive {get; set;}
    
    // Constructor
    public DuplicatePriceListStatementController(ApexPages.StandardController stdController) {
        // add fields to standard controller to be used in excel files
        String[] fieldNames = new String[] {
            SObjectType.PriceListStatement__c.fields.Name.Name,
            SObjectType.PriceListStatement__c.fields.Supplier__c.Name,
            SObjectType.PriceListStatement__c.fields.BusinessUnitTarget__c.Name,
            SObjectType.PriceListStatement__c.fields.NegoScope__c.Name,
            SObjectType.PriceListStatement__c.fields.ReferenceYear__c.Name,
            SObjectType.PriceListStatement__c.fields.Status__c.Name
        };
        // add fields only if test is not running
        if (!System.Test.isRunningTest()) stdController.addFields(fieldNames);
        try {
            this.errors = new List<String>();
            this.recordId = stdController.getId();
            this.priceListSatement = (PriceListStatement__c) stdController.getRecord();
            this.wrapperSellInRuleManual = new WrapperSellInRuleManual(this.priceListSatement);
            this.manualSellInRulesMap = new Map<Integer, List<Integer>>();
            this.priceListSatementSimulationList = new List<PriceListStatement__c>();
            // fill SellInRule__c
            this.sellInRuleOptions = new List<SelectOption>();
            for (Schema.PicklistEntry pickListVal : PriceListStatement__c.SellInRule__c.getDescribe().getPicklistValues()) {
                this.sellInRuleOptions.add(new SelectOption(pickListVal.value, pickListVal.label));
                if(this.selectedSellInRule == null) this.selectedSellInRule = pickListVal.value;
            }
            getPriceListSatementSimulations();
            this.isPollerActive = false;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + ' - ' + e.getLineNumber()));
        }
    }
    
    // Get list of conditions with specified dates
    public void getPriceListSatementSimulations() {
        // check security on PriceListStatement__c fields
        String[] priceListSatementFields = new String[] {
            SObjectType.PriceListStatement__c.fields.Id.Name,
            SObjectType.PriceListStatement__c.fields.Name.Name,
            /***SObjectType.PriceListStatement__c.fields.SellIn_Manual__c.Name,***/
            SObjectType.PriceListStatement__c.fields.SellInRule__c.Name
         };
        if (checkAccessibility(PriceListStatement__c.SObjectType, priceListSatementFields)) {
            this.priceListSatementSimulationList = [SELECT Id, Name, /***SellIn_Manual__c,***/ SellInRule__c, OnTop__c, Version__c,
                                                    (SELECT Id, Name, PG__c, SellInRegularQty__c, SellInPromoQty__c
                                                     FROM PLSDPriceListStatement__r)
                                                    FROM PriceListStatement__c
                                                    WHERE PriceListStatementReference__c = :this.recordId
                                                    AND RecordType.DeveloperName = 'Simulation'
                                                    ORDER BY Version__c DESC];
        }
    }
    
    // refresh data
    public PageReference refresh() {
        this.isPollerActive = false;
        getPriceListSatementSimulations();
        // check access AsyncApexJob fields
        String[] apexJobFields = new String[] {
            SObjectType.AsyncApexJob.fields.Id.Name,
                SObjectType.AsyncApexJob.fields.CreatedDate.Name,
                SObjectType.AsyncApexJob.fields.Status.Name,
                SObjectType.AsyncApexJob.fields.JobType.Name,
                SObjectType.AsyncApexJob.fields.ApexClassId.Name
                };
        // check access ApexClass fields        
        String[] apexClassFields = new String[] {
            SObjectType.ApexClass.fields.Name.Name
        };
        List<AsyncApexJob> batchJob = new List<AsyncApexJob>();
        if (checkAccessibility(AsyncApexJob.SObjectType, apexJobFields) && checkAccessibility(ApexClass.SObjectType, apexClassFields)) {
            batchJob = [SELECT Id, Status FROM AsyncApexJob
                        WHERE ApexClass.Name = :DuplicatePriceListStatementBatch.class.getName()
                        AND JobType != 'BatchApexWorker'
                        ORDER BY CreatedDate DESC LIMIT 20];
        }
        // Activate the poller if theare are a job holding or in process
        for(AsyncApexJob job : batchJob) {
            if(job.Status != 'Completed' && job.Status != 'Aborted' && job.Status != 'Failed') {
                this.isPollerActive = true;
                break;
            }
        }
        return null;
    }
    
    // Button Duplicate Action
    public PageReference duplicate() {
        if(String.isNotBlank(this.recordId)) {
            Set<Id> priceListStatementIdSet = new Set<Id>{this.recordId};
            // Call DuplicatePriceListStatementBatch Class
            Map<String, Object> paramsMap = new Map<String, Object>{
                'startedFrom' => 'DuplicatePriceListStatementController',
                'priceListStatementSet' => priceListStatementIdSet,
                'selectedSellInRule' => this.selectedSellInRule,
                'manualSellInRulesMap' => this.manualSellInRulesMap,
                'isSimulation' => true
            };
            Id batchInstanceId = NegoptimBatch.executeBatch('DuplicatePriceListStatementBatch', paramsMap, 200);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'DuplicatePriceListStatementBatch', (String)batchInstanceId})));
        }
        return refresh();
    }
    
    /**
     * Manage Manual SellInRule Popup
     */
    public void displayManualSellInRulePopUp() {
        try {
            this.showManualSellInRulePopup = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
    
    public void closeManualSellInRulePopup() {
        ////this.wrapperSellInRuleManual = new WrapperSellInRuleManual(this.priceListSatement);
        this.showManualSellInRulePopup = false;
    }
    
    public void saveManualSellInRulePopup() {
        try {
            // Save Manual SellInRule
            this.manualSellInRulesMap = new Map<Integer, List<Integer>>();
            this.manualSellInRulesMap.put(this.wrapperSellInRuleManual.P2, new List<Integer>());
            this.manualSellInRulesMap.put(this.wrapperSellInRuleManual.P1, new List<Integer>());
            this.manualSellInRulesMap.put(this.wrapperSellInRuleManual.N, new List<Integer>());
            for(Integer i = 1; i <= 12; i++) {
                if(this.wrapperSellInRuleManual.P2Map.get(i) == true) {
                    this.manualSellInRulesMap.get(this.wrapperSellInRuleManual.P2).add(i);
                }
                if(this.wrapperSellInRuleManual.P1Map.get(i) == true) {
                    this.manualSellInRulesMap.get(this.wrapperSellInRuleManual.P1).add(i);
                }
                if(this.wrapperSellInRuleManual.NMap.get(i) == true) {
                    this.manualSellInRulesMap.get(this.wrapperSellInRuleManual.N).add(i);
                }
            }
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        closeManualSellInRulePopup();
    }
    
    /* Wrapper Class for SellInRule. */
    public class WrapperSellInRuleManual {
        Public Integer P2 {get; set;}
        Public Integer P1 {get; set;}
        Public Integer N {get; set;}
        public Map<Integer, Boolean> P2Map {get; set;}
        public Map<Integer, Boolean> P1Map {get; set;}
        public Map<Integer, Boolean> NMap {get; set;}
        public List<Integer> months {get; set;}
        
        public WrapperSellInRuleManual(PriceListStatement__c priceListStatement) {
            this.P2 = Integer.valueOf(priceListStatement.ReferenceYear__c) - 2;
            this.P1 = Integer.valueOf(priceListStatement.ReferenceYear__c) - 1;
            this.N = Integer.valueOf(priceListStatement.ReferenceYear__c);
            this.P2Map = new Map<Integer, Boolean>();
            this.P1Map = new Map<Integer, Boolean>();
            this.NMap = new Map<Integer, Boolean>();
            this.months = new List<Integer>();
            for(Integer i = 1; i <= 12; i++) {
                this.P2Map.put(i, false);
                this.P1Map.put(i, false);
                this.NMap.put(i, false);
                this.months.add(i);
            }
        }
    }
}