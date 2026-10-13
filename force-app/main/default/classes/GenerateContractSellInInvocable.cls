/**
 * @author ULiT
 * @date 18-02-2025
 * @description apex class for Generate ContractSellIn
 **/
public with sharing class GenerateContractSellInInvocable {
    @InvocableMethod(label='Generate ContractSellIn' description='Generate ContractSellIn' category='ContractSellIn')
    public static void generateContractSellIn(List<ContractSellInWrapper> contractSellInWrapperList) {
        ContractSellInWrapper contractSellInWrapper = contractSellInWrapperList[0];
        Map<String, Object> paramsMap = new Map<String, Object> {
            'startedFrom' => GenerateContractSellInInvocable.class.getName(),
            'contractIds' => new Set<Id>{contractSellInWrapper.contractId}
        };
        NegoptimBatch.executeBatch('InitContractSellInBatch', paramsMap, 100);
    }
    
    public class ContractSellInWrapper {
        @InvocableVariable(label='contract Id' description='Id of the contract' required=true)
        public Id contractId;
    }
}