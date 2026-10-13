public class CPDAggregator {

    // 1. CPD → CP (SellIn, SellOut, Services)
    public static void aggregateToCPs(Set<Id> cpIds) {
        if (cpIds == null || cpIds.isEmpty()) return;

        List<CommercialPlan__c> cpToUpdate = new List<CommercialPlan__c>();

        for (Id cpId : cpIds) {
            Decimal siTarget = 0, siFact = 0, siFact2 = 0;
            Decimal soTarget = 0, soTargetTax = 0, soFact = 0, soFactTax = 0;
            Decimal svcTarget = 0, svcFact = 0;

            for (AggregateResult ar : [
                SELECT SUM(SellInDiscountMassValueTarget__c) target,
                       SUM(SellInDiscountMassValueFact__c) fact,
                       SUM(SellInDiscountMassValueFact2__c) fact2
                FROM CommercialPlanDetail__c
                WHERE CommercialPlan__c = :cpId
                  AND CommercialPlanSellIn__c != null
                GROUP BY CommercialPlanSellIn__c
            ]) {
                siTarget += (Decimal)ar.get('target') != null ? (Decimal)ar.get('target') : 0;
                siFact += (Decimal)ar.get('fact') != null ? (Decimal)ar.get('fact') : 0;
                siFact2 += (Decimal)ar.get('fact2') != null ? (Decimal)ar.get('fact2') : 0;
            }

            for (AggregateResult ar : [
                SELECT SUM(SellOutDiscMassValueContribTarget__c) target,
                       SUM(SellOutDiscMassValueContribTargetwTax__c) targetTax,
                       SUM(SellOutDiscMassValueContribFact__c) fact,
                       SUM(SellOutDiscMassValueContribFactwTax__c) factTax
                FROM CommercialPlanDetail__c
                WHERE CommercialPlan__c = :cpId
                  AND CommercialPlanSellOut__c != null
                GROUP BY CommercialPlanSellOut__c
            ]) {
                soTarget += (Decimal)ar.get('target') != null ? (Decimal)ar.get('target') : 0;
                soTargetTax += (Decimal)ar.get('targetTax') != null ? (Decimal)ar.get('targetTax') : 0;
                soFact += (Decimal)ar.get('fact') != null ? (Decimal)ar.get('fact') : 0;
                soFactTax += (Decimal)ar.get('factTax') != null ? (Decimal)ar.get('factTax') : 0;
            }

            for (AggregateResult ar : [
                SELECT SUM(ServicesDiscountMassValueTarget__c) target,
                       SUM(ServicesDiscountMassValueFact__c) fact
                FROM CommercialPlanDetail__c
                WHERE CommercialPlan__c = :cpId
                  AND CommercialPlanServices__c != null
                GROUP BY CommercialPlanServices__c
            ]) {
                svcTarget += (Decimal)ar.get('target') != null ? (Decimal)ar.get('target') : 0;
                svcFact += (Decimal)ar.get('fact') != null ? (Decimal)ar.get('fact') : 0;
            }

            cpToUpdate.add(new CommercialPlan__c(
                Id = cpId,
                SellInDiscountMassValueTarget__c = siTarget,
                SellInDiscountMassValueFact__c = siFact,
                SellInDiscountMassValueFact2__c = siFact2,
                SellOutDiscMassValueContribTarget__c = soTarget,
                SellOutDiscMassValueContribTargetwTax__c = soTargetTax,
                SellOutDiscMassValueContribFact__c = soFact,
                SellOutDiscMassValueContribFactwTax__c = soFactTax,
                ServicesDiscountMassValueTarget__c = svcTarget,
                ServicesDiscountMassValueFact__c = svcFact
            ));
        }

        if (!cpToUpdate.isEmpty()) {
            update cpToUpdate;
        }
    }

    // 2. CP → Parent CP
    public static void aggregateToParentCPs(Set<Id> parentCpIds) {
        if (parentCpIds == null || parentCpIds.isEmpty()) return;

        List<CommercialPlan__c> parentCPs = new List<CommercialPlan__c>();

        for (Id parentId : parentCpIds) {
            List<AggregateResult> childAggResults = [
                SELECT
                    SUM(SellInDiscountMassValueTarget__c) siTarget,
                    SUM(SellInDiscountMassValueFact__c) siFact,
                    SUM(SellInDiscountMassValueFact2__c) siFact2,
                    SUM(SellInDiscountMassValueInvoice__c) siInvoice,
                    SUM(SellInDiscountMassValueCN__c) siCN,
                    SUM(SellInDiscountMassValuePaid__c) siPaid,

                    SUM(SellOutDiscMassValueContribTarget__c) soTarget,
                    SUM(SellOutDiscMassValueContribTargetwTax__c) soTargetTax,
                    SUM(SellOutDiscMassValueContribFact__c) soFact,
                    SUM(SellOutDiscMassValueContribFactwTax__c) soFactTax,
                    SUM(SellOutDiscMassValueContribInvoice__c) soInvoice,
                    SUM(SellOutDiscMassValueContribCN__c) soCN,
                    SUM(SellOutDiscMassValueContribPaid__c) soPaid,

                    SUM(ServicesDiscountMassValueTarget__c) svcTarget,
                    SUM(ServicesDiscountMassValueFact__c) svcFact,
                    SUM(ServicesDiscountMassValueInvoice__c) svcInvoice,
                    SUM(ServicesDiscountMassValueCN__c) svcCN,
                    SUM(ServicesDiscountMassValuePaid__c) svcPaid

                FROM CommercialPlan__c
                WHERE CommercialPlanParent__c = :parentId
                GROUP BY CommercialPlanParent__c
            ];

            if (!childAggResults.isEmpty()) {
                AggregateResult ar = childAggResults[0];

                parentCPs.add(new CommercialPlan__c(
                    Id = parentId,
                    SellInDiscountMassValueTarget__c = (Decimal) ar.get('siTarget'),
                    SellInDiscountMassValueFact__c = (Decimal) ar.get('siFact'),
                    SellInDiscountMassValueFact2__c = (Decimal) ar.get('siFact2'),
                    SellInDiscountMassValueInvoice__c = (Decimal) ar.get('siInvoice'),
                    SellInDiscountMassValueCN__c = (Decimal) ar.get('siCN'),
                    SellInDiscountMassValuePaid__c = (Decimal) ar.get('siPaid'),

                    SellOutDiscMassValueContribTarget__c = (Decimal) ar.get('soTarget'),
                    SellOutDiscMassValueContribTargetwTax__c = (Decimal) ar.get('soTargetTax'),
                    SellOutDiscMassValueContribFact__c = (Decimal) ar.get('soFact'),
                    SellOutDiscMassValueContribFactwTax__c = (Decimal) ar.get('soFactTax'),
                    SellOutDiscMassValueContribInvoice__c = (Decimal) ar.get('soInvoice'),
                    SellOutDiscMassValueContribCN__c = (Decimal) ar.get('soCN'),
                    SellOutDiscMassValueContribPaid__c = (Decimal) ar.get('soPaid'),

                    ServicesDiscountMassValueTarget__c = (Decimal) ar.get('svcTarget'),
                    ServicesDiscountMassValueFact__c = (Decimal) ar.get('svcFact'),
                    ServicesDiscountMassValueInvoice__c = (Decimal) ar.get('svcInvoice'),
                    ServicesDiscountMassValueCN__c = (Decimal) ar.get('svcCN'),
                    ServicesDiscountMassValuePaid__c = (Decimal) ar.get('svcPaid')
                ));
            }
        }

        if (!parentCPs.isEmpty()) {
            update parentCPs;
        }
    }
}