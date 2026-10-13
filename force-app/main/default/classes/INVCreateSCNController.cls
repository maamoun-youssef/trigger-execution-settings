public with sharing class INVCreateSCNController {
@AuraEnabled
public static Id createSupplierCreditNote(String serializedInput) {
    Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(serializedInput);
    Map<String, Object> form = (Map<String, Object>) input.get('invoicedata');
    Id supplierId = (Id) input.get('supplierId');
    Id contractId = safeParseId(form.get('Contract__c'));
    Invoice__c inv = new Invoice__c();
    try{
    inv.RecordTypeId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('SourceToTarget').getRecordTypeId();
    inv.Status__c = 'Listed';
    inv.AccDoc__c = 'CreditNote';
    inv.AccDocType__c = 'CreditNote';
    inv.isManualVAT__c = true;
    inv.IsUpdatedFromYTD__c=false;
    inv.IsEinvoicingOK__c = false;
    inv.PaidVATAmount__c = 0;
    inv.PaidAmountwVAT__c = 0;

    inv.InvNumber__c = (String) form.get('InvNumber__c');
    inv.PrintDate__c = safeParseDate(form.get('InvDate__c'));
    inv.InvDate__c = safeParseDate(form.get('InvDate__c'));
    inv.CurrencyIsoCode = (String) form.get('CurrencyIsoCode');
    inv.ExchangeRate__c = parseDecimal(form.get('ExchangeRate__c'));
    inv.PaymentType__c = (String) form.get('PaymentType__c');
    inv.TotalAmount__c = parseDecimal(form.get('TotalAmount__c'));
    inv.TotalVATAmount__c = parseDecimal(form.get('TotalVATAmount__c'));
    inv.TotalAmountwVAT__c = parseDecimal(form.get('TotalAmountwVAT__c'));
    inv.VATRate1__c = parseDecimal(form.get('VATRate1__c'));   
    System.debug('in create credit note invoice method:'+inv);

    Contract__c relatedContract =(contractId!=null) ? fetchRelatedContract(contractId) : null;
    if(relatedContract != null){
        inv.SupplierSeller__c = relatedContract.Supplier__c;
        inv.BusinessUnitBuyer__c = relatedContract.BusinessUnitContract__c;
        inv.FiscalYear__c = relatedContract.Reference_Year__c;
        inv.Contract__c = relatedContract.Id;
        inv.AgreementBDate__c = relatedContract.Contract_Commercial_BDate__c;
        inv.AgreementEDate__c = relatedContract.Contract_Commercial_EDate__c;
    }

    insert inv;
}catch (AuraHandledException ahe) {
    throw ahe;
}catch (DmlException dmlEx) {
    throw new AuraHandledException('Could not save the invoice. ' + dmlEx.getDmlMessage(0));
}catch (Exception e) {
    System.debug('Unexpected error in createSupplierCreditNote: ' + e.getMessage());
    System.debug(e.getStackTraceString());
    throw new AuraHandledException('An unexpected error occurred. Please contact support.');
}
    return inv.Id;
}

private static Decimal parseDecimal(Object val) {
    if (val == null) {return 0;}
    if (val instanceof Decimal) {return (Decimal) val;}
    if (val instanceof Integer) {return Decimal.valueOf((Integer) val);}
    if (val instanceof Double) {return Decimal.valueOf((Double) val);}
    if (val instanceof Long) {return Decimal.valueOf((Long) val);}
    if (val instanceof String) {return Decimal.valueOf((String) val);}
    return 0;
}

private static Id safeParseId(Object val) {
    if (val == null){ return null;}
    String strVal = String.valueOf(val).trim();
    if (String.isEmpty(strVal)) {return null;}
    return (Id) strVal;
}

private static Date safeParseDate(Object val) {
    if (val == null) {return null;}
    String strVal = String.valueOf(val).trim();
    if (String.isEmpty(strVal)){ return null;}
    try {
        return Date.valueOf(strVal);
    } catch (Exception e) {
        return null;
    }
}


private static Contract__c fetchRelatedContract(Id contractId){
    if (contractId == null) {
        return null;
    }
    return [
        SELECT Id, Supplier__c, BusinessUnitContract__c, Reference_Year__c,
               Contract_Commercial_BDate__c, Contract_Commercial_EDate__c
        FROM Contract__c
        WHERE Id = :contractId
        LIMIT 1
    ];
}
@AuraEnabled(cacheable=true)
public static List<Contract__c> getSignedContracts(Id supplierId) {
    System.debug('Supplier Id :'+supplierId);
    return [
        SELECT Id, Name
        FROM Contract__c
        WHERE RecordType.Name = 'CON Signed'
                                 AND Supplier__c = :supplierId 
                                 AND BusinessUnitContract__r.SetInvoiceBuyer__c = true
        ORDER BY Name
    ];
}

}