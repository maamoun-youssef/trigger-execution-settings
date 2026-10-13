/**
 * @author ULiT
 * @date 15-04-2025
 * @description apex class for Recalculate Already_Invoiced__c and Already_Invoiced_Edited__c fields
 **/
public with sharing class CDAlreadyInvoicedInvocable {
    @InvocableMethod(label='Calculate CDAlreadyInvoiced' description='Calculate CD Already Invoiced' category='CDAlreadyInvoiced')
    public static void calculateCDAlreadyInvoiced(List<ContractWrapper> contractWrapperList) {
        ContractWrapper contractWrapper = contractWrapperList[0];
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => CDAlreadyInvoicedInvocable.class.getName(),
            'contractIds' => new Set<Id>{contractWrapper.contractId},
            'year' => null
        };
        NegoptimBatch.executeBatch('CDAlreadyInvoicedBatch', paramsMap, 100);
    }
    
    public class ContractWrapper {
        @InvocableVariable(label='contract Id' description='Id of the contract' required=true)
        public Id contractId;
    }
}