/**
 * @author ULiT
 * @description Handler for the trigger Trg_ServiceStatement_Ext
 **/
public class Trg_ServiceStatement_Ext_Handler {
    private static final String SALES_TERMS_RT = 'SalesTerms';
    private static final String STATUS_OPEN = 'Open';
    private static final String STATUS_CLOSED = 'Closed';

    public static void OnAfterInsertOrUpdate(List<TMP_ServiceStatement__c> newSS, Map<Id, TMP_ServiceStatement__c> oldSSMap) {
        executeOnValidation(newSS, oldSSMap);      
    }
    
    private static void executeOnValidation(List<TMP_ServiceStatement__c> newSS, Map<Id, TMP_ServiceStatement__c> oldSSMap) {
        Id salesTermsRtId = NegoptimHelper.getObjectRecordTypeId(TMP_ServiceStatement__c.SObjectType, SALES_TERMS_RT);
        if (salesTermsRtId == null || newSS == null || newSS.isEmpty()) return;

        Set<Id> supplierIds = new Set<Id>();
        Set<Integer> years = new Set<Integer>();
        Map<String, String> actionByPair = new Map<String, String>();
        
        for (TMP_ServiceStatement__c ss : newSS) {
            if (ss == null || ss.RecordTypeId != salesTermsRtId || ss.Supplier__c == null || ss.Year__c == null) continue;
            
            supplierIds.add(ss.Supplier__c);
            Integer yearVal = Integer.valueOf(ss.Year__c);
            years.add(yearVal);
            
            String pairKey = String.valueOf(ss.Supplier__c) + '-' + String.valueOf(yearVal);
            String statusL = (ss.Status__c == null) ? null : ss.Status__c.trim().toLowerCase();
            
            if (statusL == 'validate' || statusL == 'validated' || statusL == 'rejected') {
                actionByPair.put(pairKey, 'final'); 
            } else if (statusL == 'submitted') {
                if (!actionByPair.containsKey(pairKey)) actionByPair.put(pairKey, 'submitted');
            }
        }
        if (supplierIds.isEmpty() || years.isEmpty()) return;
        
        // Load existing BCF
        List<TMP_BusinessCanvaFollowup__c> existing = [SELECT Id, Supplier__c, ReferenceYear__c, Status__c,
                                                       UserStoryClosedInStep__c, BDate__c, EDate__c
                                                       FROM TMP_BusinessCanvaFollowup__c
                                                       WHERE Supplier__c IN :supplierIds
                                                       AND ReferenceYear__c IN :years];
        
        Map<String, TMP_BusinessCanvaFollowup__c> line2ByKey = new Map<String, TMP_BusinessCanvaFollowup__c>();
        Map<String, List<TMP_BusinessCanvaFollowup__c>> closedStep1ByKey = new Map<String, List<TMP_BusinessCanvaFollowup__c>>();
        
        for (TMP_BusinessCanvaFollowup__c b : existing) {
            Integer y = (b.ReferenceYear__c == null) ? null : Integer.valueOf(b.ReferenceYear__c);
            String k = String.valueOf(b.Supplier__c) + '-' + String.valueOf(y);
            
            if (b.Status__c == STATUS_OPEN && b.EDate__c == Date.newInstance(y, 1, 15)) {
                if (!line2ByKey.containsKey(k)) line2ByKey.put(k, b);
            }
            if (b.Status__c == STATUS_CLOSED && b.UserStoryClosedInStep__c == 1) {
                List<TMP_BusinessCanvaFollowup__c> lst = closedStep1ByKey.get(k);
                if (lst == null) {
                    lst = new List<TMP_BusinessCanvaFollowup__c>();
                    closedStep1ByKey.put(k, lst);
                }
                lst.add(b);
            }
        }
        
        Date today = Date.today();
        List<TMP_BusinessCanvaFollowup__c> toUpsert = new List<TMP_BusinessCanvaFollowup__c>();
        Set<String> processedPairs = new Set<String>();
        
        for (TMP_ServiceStatement__c ss : newSS) {
            if (ss == null || ss.RecordTypeId != salesTermsRtId || ss.Supplier__c == null || ss.Year__c == null) continue;
            
            Id supplierId = ss.Supplier__c;
            Integer yearVal = Integer.valueOf(ss.Year__c);
            String pairKey = String.valueOf(supplierId) + '-' + String.valueOf(yearVal);
            if (processedPairs.contains(pairKey)) continue;
            processedPairs.add(pairKey);
            
            TMP_BusinessCanvaFollowup__c l2 = line2ByKey.get(pairKey);
            if (l2 == null) {
                l2 = new TMP_BusinessCanvaFollowup__c();
                l2.Supplier__c = supplierId;
                l2.ReferenceYear__c = yearVal;
                l2.Status__c = STATUS_OPEN;
                l2.UserStoryClosedInStep__c = 1;                      
                l2.BDate__c = today;
                l2.EDate__c = Date.newInstance(yearVal, 1, 15); 
            } else {
                Integer prev = (l2.UserStoryClosedInStep__c == null) ? 0 : Integer.valueOf(l2.UserStoryClosedInStep__c);
                l2.UserStoryClosedInStep__c = prev + 1;              
            }
            
            String action = actionByPair.get(pairKey);
            if (action == 'final') {
                l2.Status__c = STATUS_CLOSED;
            }
            toUpsert.add(l2);
            
            List<TMP_BusinessCanvaFollowup__c> closedList = closedStep1ByKey.get(pairKey);
            if (closedList == null || closedList.isEmpty()) {
                TMP_BusinessCanvaFollowup__c rec6 = new TMP_BusinessCanvaFollowup__c();
                rec6.Supplier__c = supplierId;
                rec6.ReferenceYear__c = yearVal;
                rec6.Status__c = STATUS_CLOSED;
                rec6.UserStoryClosedInStep__c = 1;
                rec6.BDate__c = today;
                rec6.EDate__c = today;
                toUpsert.add(rec6);
                closedList = new List<TMP_BusinessCanvaFollowup__c>();
                closedList.add(rec6);
                closedStep1ByKey.put(pairKey, closedList);
            }
            if (action == 'submitted' || action == 'final') {
                TMP_BusinessCanvaFollowup__c l6 = closedList[0];
                l6.Status__c = STATUS_CLOSED;
                l6.UserStoryClosedInStep__c = 1;
                l6.EDate__c = today;
                toUpsert.add(l6);
            }
            if (action == 'submitted' || action == 'final') {
                if (closedList.size() < 2) {
                    TMP_BusinessCanvaFollowup__c rec7 = new TMP_BusinessCanvaFollowup__c();
                    rec7.Supplier__c = supplierId;
                    rec7.ReferenceYear__c = yearVal;
                    rec7.Status__c = STATUS_CLOSED;
                    rec7.UserStoryClosedInStep__c = 1;
                    rec7.BDate__c = today;
                    rec7.EDate__c = today;
                    toUpsert.add(rec7);
                    closedList.add(rec7);
                } else {
                    TMP_BusinessCanvaFollowup__c l7 = closedList[1];
                    l7.Status__c = STATUS_CLOSED;
                    l7.UserStoryClosedInStep__c = 1;
                    if (l7.BDate__c == null) l7.BDate__c = today;
                    l7.EDate__c = today;
                    toUpsert.add(l7);
                }
            }
        }
        
        if (!toUpsert.isEmpty()) upsert toUpsert; 
    }
}