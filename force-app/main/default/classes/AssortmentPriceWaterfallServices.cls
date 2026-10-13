/**
 * @author ULiT
 * @date 3-6-2021
 * @Description helper class that handle the comparable Class to order the display order field
 * set status of price waterfals
*/
public class AssortmentPriceWaterfallServices {

    /*
     * Status management 
     */ 
    public static void setStatuses(Assortment_PriceWaterFall__c apwNego, Assortment_PriceWaterFall__c apwStatement,
                                   Assortment_PriceWaterFall__c exitAPWArgos, Assortment_PriceWaterFall__c exitAPWTemplate,
                                   /*NetPrice_Statement_Detail__c netPriceStatementDetail,*/
                                   Boolean isInit, Boolean isUpdateManual, Boolean isValidatedStatus, Boolean synchroNetPriceStatementToAPW, Boolean synchroAPWToNetPriceStatement, Boolean isPrint)
    {
        if(isInit) { // 1-Generer PWF
            apwNego.Acceptance_Status__c = 'Accepted';
            apwNego.Status__c = 'In preparation';
            apwNego.Extraction_Status__c = 'Extract';// A envoyer
            apwNego.Ext_Synchro_Status__c = null;
        } else if(isUpdateManual) {
            // update statement Acceptance_Status__c
            if (apwNego != null) {// update from trigger
                if(apwNego.Acceptance_Status__c == 'Accepted') {
                    apwNego.Extraction_Status__c = 'Extract';// A envoyer
                    apwNego.Ext_Synchro_Status__c = 'Extract';
                } else if(apwNego.Acceptance_Status__c == 'Refused') {
                    apwNego.Ext_Synchro_Status__c = 'Blocked';// Bloqué
                    apwNego.Extraction_Status__c = 'Blocked';
                }
            }
        } else if(isValidatedStatus) { // 6-Envoyer à Argos
            if(apwNego != null) {
                apwNego.Extraction_Status__c = 'Extracted';// Envoyé
                apwNego.Status__c = 'Validated';
                if(apwNego.Ext_Synchro_Status__c == null) {
                    apwNego.Ext_Synchro_Status__c = 'Extract';
                }
            }
            if(exitAPWArgos != null) {
                exitAPWArgos.Extraction_Status__c = 'History';// Historique
            }
        }
    }
    public static List<String> updateRelatedCommercialPlanDetails(List<Assortment_PriceWaterFall__c> updatedAPWs) {
        List<String> errorMessages = new List<String>();
        Map<Id, CommercialPlanDetail__c> CPDtoUpdateMap = new Map<Id, CommercialPlanDetail__c>();
        CommercialPlanDetail__c cpd;
        Set<Id> contractsIdSet = new Set<Id>();
        Set<Id> productsIdSet = new Set<Id>();
        Map<String, List<Assortment_PriceWaterFall__c>> PWFForRegularProductsMap = new Map<String, List<Assortment_PriceWaterFall__c>>();
        String key;
        for (Assortment_PriceWaterFall__c item : updatedAPWs) {
            if (item.Promo_Event_Detail__c != null && !CPDtoUpdateMap.containsKey(item.Promo_Event_Detail__c)) {
                cpd = new CommercialPlanDetail__c(Id = item.Promo_Event_Detail__c,
                                                  TariffCostPromo__c = item.New_CostPrice__c,
                                                  NetPriceWoTaxPromo__c = item.New_NetPrice_woTax__c,
                                                  NetPricePromo__c = item.New_NetPrice_wTax__c);
                CPDtoUpdateMap.put(item.Promo_Event_Detail__c, cpd);
            }
            if (item.Promo_Event_Detail__c == null) {
                contractsIdSet.add(item.Assortment_BU__r.Contract__c);
                productsIdSet.add(item.Product__c);
                key = item.Assortment_BU__r.Contract__c + '' + item.Product__c;
                if(!PWFForRegularProductsMap.containsKey(key)) PWFForRegularProductsMap.put(key, new List<Assortment_PriceWaterFall__c>());
                PWFForRegularProductsMap.get(key).add(item);
            }
        }
        for (CommercialPlanDetail__c item : [SELECT Id, Contract__c, Product__c, SellInBDate__c,
                                             NetPriceRegular__c, NetPriceWoTaxRegular__c
                                             FROM CommercialPlanDetail__c
                                             WHERE Contract__c IN :contractsIdSet
                                             AND Product__c IN :productsIdSet
                                             AND SellInBDate__c <> NULL])
        {
            if (!CPDtoUpdateMap.containsKey(item.Id)) {
                CPDtoUpdateMap.put(item.Id, item);
            }
            cpd = CPDtoUpdateMap.get(item.Id);
            key = item.Contract__c + '' + item.Product__c;
            if (PWFForRegularProductsMap.containsKey(key)) {
                List<Assortment_PriceWaterFall__c> APWList = PWFForRegularProductsMap.get(key);
                // Sync last Regular product to CPD
                for(Assortment_PriceWaterFall__c apw : APWList) {
                    if(apw.Movement_Date__c < item.SellInBDate__c) {
                        cpd.TariffCostRegular__c = apw.New_CostPrice__c;
                        cpd.NetPriceRegular__c = apw.New_NetPrice_wTax__c;
                        cpd.NetPriceWoTaxRegular__c = apw.New_NetPrice_woTax__c;                        
                    }
                }
            }
        }
        if (!CPDtoUpdateMap.isEmpty()) {
            List<Database.SaveResult> results = Database.update(CPDtoUpdateMap.values());
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    for (Database.Error err : result.getErrors()) {
                        String msg = '' + err.getStatusCode();
                        if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                            errorMessage += err.getMessage();
                        } else {
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        errorMessages.add(errorMessage);
                        System.debug('errorMessage >>> ' + errorMessage);
                    }
                }
            }
        }
        return errorMessages;
    }
    /**
     * @author ULiT
     * @date 13/02/2024
     * @description wrapper class used to serialize and deserialize active taxes on the level of Assortment BUs/Net Price Statement
     * Used in InitPriceWaterFallBatch_V2
    */
    public class StatementWrapper {
        // the Id of the Orga_Taxes__c record or the Pol_Com_Condition__c record
        public Id recordId {get; set;}
        // the name of the Orga_Taxes__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Orga_Taxes__c / 1-19 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        // statement type for discont statements (U, %)
        public String conditionMode {get; set;}
        // Rank for discount statements
        public Integer rank {get; set;}
        
        public StatementWrapper(Id recordId, String Name, Integer displayOrder, String conditionMode, Integer rank) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.conditionMode = conditionMode;
            this.rank = rank;
        }
        
        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this(recordId, Name, displayOrder, null, null);
        }
    }
}