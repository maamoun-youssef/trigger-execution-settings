/**
 * @author ULiT
 * @date 23-06-2023
 * @description Consolide the contracts PT and TOP for generate contracts Landing/NB/NBI
******************************************************************************************************************************************* */
public with sharing class ConsolidateContractQueueable implements Queueable {

    private String startedFrom;
    private List<Id> supplierBUIds;
    private List<Id> supplierIds;
    private List<Id> negoScopeIds;
    private List<Id> contractBUIds;
    public Integer negoYear;
    public Boolean isConsoNegoBase;
    public Boolean isConsoLanding;
    private List<String> consoRecordTypes;
    public ConsolidateContractQueueable() {}
    // Constructor.
    public ConsolidateContractQueueable(String startedFrom, List<Id> supplierBUIds, List<Id> supplierIds, List<Id> negoScopeIds, List<Id> contractBUIds, Integer year,
                                        List<String> consoRecordTypes)
    {
        this.startedFrom = startedFrom;
        this.supplierBUIds = supplierBUIds;
        this.supplierIds = supplierIds;
        this.negoScopeIds = negoScopeIds;
        this.contractBUIds = contractBUIds;
        this.negoYear = year == null ? System.today().year() : year;
        this.consoRecordTypes = consoRecordTypes;
        this.isConsoNegoBase = this.consoRecordTypes.contains('Nego_Base');
        this.isConsoLanding = this.consoRecordTypes.contains('Landing');
    }
    // Execute
    public void execute(QueueableContext context) {
        List<String> errorMessages = ContractServices.consolidateContract(this.supplierBUIds, this.supplierIds, this.negoScopeIds, this.contractBUIds, this.negoYear, null, false, false, false, this.consoRecordTypes);
        if(!this.isConsoLanding && !Test.isRunningTest()) {
            System.enqueueJob(new ConsolidateContractQueueable(ConsolidateContractQueueable.class.getName(), supplierBUIds, supplierIds, negoScopeIds, contractBUIds, this.negoYear, new List<String>{'Landing'}));
        }
        system.debug('errorMessages >>> ' + errorMessages);
        Log__c log = new Log__c (
            Class_Name__c = ConsolidateContractQueueable.class.getName(),
            Started_From__c = this.startedFrom,
            JobItemsProcessed__c = 0,
            JobType__c = 'ApexToken',
            MethodName__c = '',
            NumberOfWarnings__c = 0,
            TraceLog__c = '',
            Submitted_Date__c = System.now(),
            CompletedDate__c = System.now()
        );
        log.Status__c = 'Completed';
        if (!errorMessages.isEmpty()) {
            log.NumberOfWarnings__c = 1;
            for (String err : errorMessages) {
                 log.TraceLog__c += err + '\n';
            }
            log.Status__c = 'Failed';
        }
        insert log;
    }
}