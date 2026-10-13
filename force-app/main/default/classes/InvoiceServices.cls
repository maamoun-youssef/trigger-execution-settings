/*
 * @author @ULIT
 * @description Generate Invoices/InvoiceDetails
 */
public with sharing class InvoiceServices {
    public static Map<String, Id> invoiceRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Invoice__c.SObjectType);
    private static List<InvoiceDetail__c> invoiceDetailsToInsert;
    private static Map<String, GlobalLocation__c> glMap = new Map<String, GlobalLocation__c>();
    private static Integer maxSequence;

    public static String generateInvoicesLines(String contract_Serialized, String condition_Serialized, List<InvoiceDetail__c> downPayments) {
        try {
            Contract__c contract = (Contract__c)JSON.deserialize(contract_Serialized, Contract__c.class);
            Contract_Discount__c condition = (Contract_Discount__c)JSON.deserialize(condition_Serialized, Contract_Discount__c.class);
            List<Date> invoicesDates = new List<Date>();
            if (!condition.Is_Manual_Invoicing_Planning__c) {
                invoicesDates = generateInvoicesDates(condition);
            }
            return fillInvoiceLines(contract, invoicesDates, condition, downPayments);
        } catch(Exception ex) {
            System.debug('ERROR >>> ' + ex.getMessage() + ' - ' + ex.getLineNumber());
            return null;
        }
    }

    private static List<Date> generateInvoicesDates(Contract_Discount__c discount) {
        List<Date> dateList = new List<Date>();
        Date selectedDate = discount.first_invoice_date__c != null ? discount.first_invoice_date__c : discount.Disc_Bdate__c ;
        Integer month = selectedDate.month();
        Integer year = selectedDate.year();
        Boolean isCustomPeriod = false;
        Integer day = 31;
        Boolean isManualInvoice = discount.Is_Manual_Invoicing_Planning__c;
        Integer closingDay = 31;
        Integer invoiceSequence;
        switch on discount.Invoice_period__c {
            when 'Month' {
                invoiceSequence = 1;
            }
            when 'Trimester' {
                invoiceSequence = 3;
            }
            when 'Semester' {
                invoiceSequence = 6;
            }
            when 'Year' {
                invoiceSequence = 12;
            }
        }
        if (discount.Invoice_period__c != null && discount.Invoice_period__c.contains('-')) {
            isCustomPeriod = true;
        } else if(invoiceSequence == 12 && selectedDate < Date.newInstance(year, 1, closingDay)) {
            year = year - 1;
        }
        if (invoiceSequence == null && !isCustomPeriod) {
            return dateList;
        }
        Integer invDay = selectedDate != null ? selectedDate.day() : (closingDay != null ? closingDay : NegoptimHelper.getLastDayOfMonth(year, month).day());
        if (!isCustomPeriod) {
            dateList = new List<Date>();
            if (!isManualInvoice) {
                Set<Integer> coveredMonths = new Set<Integer>();
                Date nextExpectedDate = invoiceSequence == 1 && selectedDate != null ? selectedDate : NegoptimHelper.getLastDayOfMonth(year, month);
                if (nextExpectedDate.day() > invDay) {
                    nextExpectedDate = Date.newInstance(year, month, invDay);
                }
                month = nextExpectedDate.month();
                coveredMonths.add(nextExpectedDate.month());
                Integer increment = invoiceSequence;
                if(discount.Invoice_sequence__c != null) {
                    increment = increment * Integer.valueOf(discount.Invoice_sequence__c);
                }
                while (nextExpectedDate <= discount.Disc_EDate__c) {
                    if (nextExpectedDate >= selectedDate && !dateList.contains(nextExpectedDate)) {
                        dateList.add(nextExpectedDate);
                        coveredMonths.add(nextExpectedDate.month());
                    }
                    Integer nextMonth = month + increment > 12 ? Math.Mod(month + increment, 12) : month + increment;
                    year = nextMonth <= month ? year + 1 : year;
                    nextExpectedDate = NegoptimHelper.getLastDayOfMonth(year, nextMonth);
                    if (nextExpectedDate.day() > invDay) {
                        nextExpectedDate = Date.newInstance(year, nextMonth, invDay);
                    }
                    month = nextMonth;
                }
            }
        } else {
            Date nextExpectedDate;
            Integer expYear, expMonth, expDay;
            expYear = selectedDate != null ? selectedDate.year() : selectedDate.year();
            expDay =  selectedDate != null ? selectedDate.day() : null;
            for (String customMonth : discount.Invoice_period__c.split('-')) {
                expMonth = Integer.valueOf(customMonth);
                if (expMonth > discount.Disc_EDate__c.month()) continue;
                if (expDay != null) {
                    nextExpectedDate = Date.newInstance(expYear, expMonth, expDay);
                } else {
                    nextExpectedDate = NegoptimHelper.getLastDayOfMonth(expYear, expMonth);
                }
                if (nextExpectedDate >= selectedDate && !dateList.contains(nextExpectedDate)) {
                    dateList.add(nextExpectedDate);
                }
            }
            if (dateList.isEmpty()) dateList.add(Date.newInstance(discount.Disc_EDate__c.year(), discount.Disc_EDate__c.month(), invDay));
        }
        return dateList;
    }

    private static String fillInvoiceLines(Contract__c contract, List<Date> invoicesDates, Contract_Discount__c condition, List<InvoiceDetail__c> downPayments) {
        Integer scale = 2;
        Pol_Sale_Condition_Exception__c saleConditionException;
        String roundingMethod;
        if (contract.Sales_Conditions_Exception__r != null && !contract.Sales_Conditions_Exception__r.isEmpty()) {
            saleConditionException = contract.Sales_Conditions_Exception__r[0];
        }
        // If Sales Conditions Exception exists for the contract
        if (saleConditionException != null) {
            roundingMethod = saleConditionException.Invoice_Rounding_Method__c;
            // Get Values from Sales Conditions Exception based on VAT Type
            if (condition.Condition_Type__r.VAT_Type__c == 'Service') {
                // Use Invoice_Rounding_Level_Service__c
                scale = saleConditionException.Invoice_Rounding_Level_Service__c != null ? Integer.valueOf(saleConditionException.Invoice_Rounding_Level_Service__c) : 0;
            } else if (condition.Condition_Type__r.VAT_Type__c == 'Rebate') {
                // Use Invoice_Rounding_Level_Rebate__c
                scale = saleConditionException.Invoice_Rounding_Level_Rebate__c != null ? Integer.valueOf(saleConditionException.Invoice_Rounding_Level_Rebate__c) : 0;
            }
        } else {
            // No Sales Conditions Exception found, use Default Sales Conditions
            Pol_Sale_Condition__c defaultCondition = condition.Contract__r.Default_Sales_Conditions__r;
            if (defaultCondition != null) {
                roundingMethod = defaultCondition.Invoice_Rounding_Method__c;
                if (condition.Condition_Type__r.VAT_Type__c == 'Rebate') {
                    scale = defaultCondition.Invoice_Rounding_Level_Rebate__c != null ? Integer.valueOf(defaultCondition.Invoice_Rounding_Level_Rebate__c) : 0;
                } else if (condition.Condition_Type__r.VAT_Type__c == 'Service') {
                    scale = defaultCondition.Invoice_Rounding_Level_Service__c != null ? Integer.valueOf(defaultCondition.Invoice_Rounding_Level_Service__c) : 0;
                }
            }
        }
        System.RoundingMode systemRound = System.RoundingMode.UP;
        // switch on condition.Contract__r.Default_Sales_Conditions__r.Invoice_Rounding_Method__c {
        switch on roundingMethod {
            when 'DOWN' {
                systemRound = System.RoundingMode.DOWN;
            }
            when 'HALF_UP' {
                systemRound = System.RoundingMode.HALF_UP;
            }
            when 'HALF_DOWN' {
                systemRound = System.RoundingMode.HALF_DOWN;
            }
        }
        List<Date> datesToEliminate = new List<Date>();
        Decimal alreadyInvoiced = 0;
        List<Decimal> sequences = new List<Integer>();
        for (Integer i = 1 ; i < 100 ; i++) {
            sequences.add(i);
        }
        List<Decimal> removedSequences = new List<Decimal> ();
        for (InvoiceDetail__c inv : downPayments) {
            if (inv.Invoice__r.Status__c != 'Generated') {
                datesToEliminate.add(inv.Invoice__r.invDate__c);
                removedSequences.add(inv.Invoice__r.SeqNumber__c);
                if (inv.Invoice__r.Status__c != 'Cancelled'){
                    alreadyInvoiced += (inv.DetailAmount__c != null ? inv.DetailAmount__c : 0);
                }
            }
        }
        for (Integer i = invoicesDates.size() - 1; i >= 0; i--) {
            if (datesToEliminate.contains(invoicesDates[i])) {
                invoicesDates.remove(i);
            }
        }
        for (Integer i = sequences.size() - 1; i >= 0; i--) {
            if (removedSequences.contains(sequences[i])) {
                sequences.remove(i);
            }
        }
        Integer totalNbOfDates = invoicesDates.size();
        Decimal YTD;
        List<Decimal> amountValues;
        Decimal YTDDownPayment = 0;
        if (condition.Invoice_base__c == 'Negotiated') {
            YTDDownPayment = condition.YTD_Nego__c != null ? condition.YTD_Nego__c : 0;
        } else if (condition.Invoice_base__c == 'Forecasted') {
            YTDDownPayment = condition.YTD_FX__c != null ? condition.YTD_FX__c : 0;
        } else if (condition.Invoice_base__c == 'ActualYTD') {
            YTDDownPayment = condition.YTDFact__c != null ? condition.YTDFact__c : 0;
        }
        Decimal YECoverage = condition.Down_Payment_YE_Coverage__c != null ? condition.Down_Payment_YE_Coverage__c : 0;
        YTDDownPayment = YTDDownPayment * YECoverage * 0.01;
        Decimal RestToPay = YTDDownPayment - alreadyInvoiced;
        ResultWrapper resultWrapper = new ResultWrapper();
        if (condition.Invoice_base__c == 'ActualYTD' || RestToPay > 0) {
            if (condition.Invoice_base__c == 'ActualYTD') {
                amountValues = new List<Decimal>();
                // decimal firstVal = RestToPay;
                // amountValues.add(firstVal);
                for (Integer i = 0 ; i < invoicesDates.size() ; i++) {
                    amountValues.add(0);
                }
            } else {
                Decimal Amount = RestToPay;
                amountValues = NegoptimHelper.smartDivision( Amount, invoicesDates.size(), scale, systemRound);
            }
            invoicesDates.sort();
            List<InvoicesInfoWrapper> invoiceDetails = new List<InvoicesInfoWrapper>();
            for (Integer i = 0; i < invoicesDates.size(); i++) {
                InvoicesInfoWrapper invoiceDetailWrapper = new InvoicesInfoWrapper();
                InvoiceWrapper invoiceWrapper = new InvoiceWrapper();
                // invoicewrap.AccDoc = 'DownPaymentInvoice';
                invoiceWrapper.AccDoc = condition.Condition_Type__r.Acc_Document_Type__c;
                invoiceWrapper.PrintDate = invoicesDates[i];
                invoiceWrapper.Status = 'Generated';
                invoiceWrapper.Sequence = sequences[i];
                invoiceDetailWrapper.invoice = invoiceWrapper;
                invoiceDetailWrapper.Amount = amountValues[i];
                invoiceDetails.add(invoiceDetailWrapper);
                resultWrapper.invoiceDetails = invoiceDetails;
            }
        } else {
            resultWrapper.invoiceDetails = new List<InvoicesInfoWrapper>();
        }
        resultWrapper.Amount = condition.YTDRestToInvoice__c;
        resultWrapper.YtdDownPayment = YTDDownPayment;
        resultWrapper.condition = condition;
        return JSON.serialize(resultWrapper);
    }

    public static Map<Id, Contract_Discount__c> calculateCDAlreadyInvoiced(Set<Id> discountIds) {
        Map<Id, Contract_Discount__c> discountsToUpdate = new Map<Id, Contract_Discount__c>();
        // Calculate Already_Invoiced_Edited__c
        if(!discountIds.isEmpty()) {
            for(Id discountId : discountIds) {
                Contract_Discount__c discount = new Contract_Discount__c(Id = discountId, Already_Invoiced__c = 0, Already_Invoiced_Edited__c = 0);
                discountsToUpdate.put(discountId, discount);
            }
            Set<String> alreadyInvoicedStatuses = new Set<String> { 'Deleted', 'inPreparation' };
            Set<String> alreadyInvoicedEditedStatuses = new Set<String> { 'Printed', 'Paid', 'PartiallyPaid', 'Gained', 'Loosed', 'Cancelled' };
            for (AggregateResult result : [SELECT DISCLineD__c DISCLineD__c, Invoice__r.Status__c Status__c, SUM(DetailAmount__c) DetailAmount__c
                                           FROM InvoiceDetail__c
                                           WHERE DISCLineD__c IN :discountIds
                                           AND Invoice__r.Status__c <> 'Deleted'
                                           GROUP BY DISCLineD__c, Invoice__r.Status__c])
            {
                Id discountId = (Id) result.get('DISCLineD__c');
                String status = String.valueOf(result.get('Status__c'));
                Decimal detailAmount = result.get('DetailAmount__c') != null ? (Decimal) result.get('DetailAmount__c') : 0;
                Contract_Discount__c discount = discountsToUpdate.get(discountId);
                if (!alreadyInvoicedStatuses.contains(status)) {
                    discount.Already_Invoiced__c += detailAmount;
                }
                if (alreadyInvoicedEditedStatuses.contains(status)) {
                    discount.Already_Invoiced_Edited__c += detailAmount;
                }
                discountsToUpdate.put(discountId, discount);
            }
        }
        return discountsToUpdate;
    }

    public static void generateDiscountInvoices(Map<Id, List<InvoicesInfoWrapper>> discInvoicesMap, Map<Id, Contract__c> contractsMap, Map<Id, Pol_Com_Condition__c> conditionTypeMap, Map<Id, Contract_Discount__c> discountsMap) {
        generateDiscountInvoices(discInvoicesMap, contractsMap, conditionTypeMap, discountsMap, false);
    }

    public static void generateDiscountInvoices(Map<Id, List<InvoicesInfoWrapper>> discInvoicesMap, Map<Id, Contract__c> contractsMap, Map<Id, Pol_Com_Condition__c> conditionTypeMap, Map<Id, Contract_Discount__c> discountsMap, Boolean isPreBalance) {
        invoiceDetailsToInsert = new List<InvoiceDetail__c>();

        // Contract scopes
        Set<Id> supplierSet = new Set<Id>();
        for (Contract__c contract : contractsMap.values()) {
            supplierSet.add(contract.Supplier__c);
        }

        List<GlobalLocation__c> globalLocations = [SELECT Id,  Name, Country__c, Functions__c, Status__c, BusinessUnit__c, Supplier__c,
                                                   BusinessUnit__r.SetInvoiceSeller__c, CompanyName__c, CurrencyIsoCode, PostalCode__c, City__c,
                                                   ReferenceLanguage__c, Address1__c, Address2__c, Address3__c, Phone1__c, Phone2__c,
                                                   Identifier1__c, Identifier2__c, Identifier3__c, Identifier4__c, Identifier5__c
                                                   FROM GlobalLocation__c
                                                   WHERE Functions__c INCLUDES ('InvoiceTo', 'Administrative')
                                                   AND Status__c = 'Open'
                                                   AND Supplier__c IN :supplierSet];

        for (GlobalLocation__c gl : globalLocations) {
            glMap.put(gl.Id, gl);
            if (gl.Functions__c != null) {
                if (gl.Functions__c.containsIgnoreCase('InvoiceTo')) {
                    glMap.put(gl.Supplier__c + 'InvoiceTo', gl);
                }
                if (gl.Functions__c.containsIgnoreCase('Administrative')) {
                    glMap.put(gl.Supplier__c + 'Administrative', gl);
                }
            }
        }

        Map<Id, List<Integer>> discountToSequencesMap = new Map <Id, List<Integer>>();
        Map<Id, Set<Date>> discountToExistingDatesMap = new Map<Id, Set<Date>>();
        List<Id> generatedOldInvoicesId = new List<Id>();
        List<InvoiceDetail__c> generatedOldInvoiceDetailsToBeDeleted = new List<InvoiceDetail__c>();
        List<InvoiceDetail__c> oldInvoiceDetails = [SELECT Id, DISCLineD__c, Invoice__c, Invoice__r.Status__c, Invoice__r.SeqNumber__c,
                                                    Invoice__r.InvDate__c,
                                                    DISCLineD__r.Condition_Type__r.Acc_Document_Type__c, invoice__r.AccDoc__c
                                                    FROM InvoiceDetail__c
                                                    WHERE DISCLineD__c IN :discountsMap.keySet()];
        for (InvoiceDetail__c inv : oldInvoiceDetails) {
            if (inv.Invoice__r.Status__c == 'Generated') {
                // Only delete Generated invoices
                generatedOldInvoicesId.add(inv.Invoice__c);
                generatedOldInvoiceDetailsToBeDeleted.add(inv);
            } else if (inv.Invoice__r.Status__c != 'Generated') {
                if (!discountToExistingDatesMap.containsKey(inv.DISCLineD__c)) {
                    discountToExistingDatesMap.put(inv.DISCLineD__c, new Set<Date>());
                }
                if (inv.Invoice__r.InvDate__c != null) {
                    discountToExistingDatesMap.get(inv.DISCLineD__c).add(inv.Invoice__r.InvDate__c);
                }
                if (inv.Invoice__r.SeqNumber__c != null) {
                    if (!discountToSequencesMap.containsKey(inv.DISCLineD__c)) {
                        discountToSequencesMap.put(inv.DISCLineD__c, new List<Integer>());
                    }
                    discountToSequencesMap.get(inv.DISCLineD__c).add(Integer.valueOf(inv.Invoice__r.SeqNumber__c));
                }
            }
        }

        // delete old Generated invoices
        if (!generatedOldInvoiceDetailsToBeDeleted.isEmpty()) {
            Database.delete(generatedOldInvoiceDetailsToBeDeleted, false);
        }
        if (!generatedOldInvoicesId.isEmpty()) {
            List<Invoice__c> generatedOldInvoices = [SELECT Id FROM Invoice__c WHERE Id IN :generatedOldInvoicesId];
            if (!generatedOldInvoices.isEmpty()) {
                Database.delete(generatedOldInvoices, false);
            }
        }
        List<Invoice__c> invoicesListToInsert = new List<Invoice__c>();
        Map<Id, List<Invoice__c>> invoicesDiscMap = new Map<Id, List<Invoice__c>>();
        Map<String, InvoicesInfoWrapper> invoiceDetailWrapperMap = new Map<String, InvoicesInfoWrapper>();

        for (Id discountId : discInvoicesMap.keyset()) {
            List<InvoicesInfoWrapper> invoiceDetailsWrapperList = discInvoicesMap.get(discountId);
            Contract_Discount__c discount = discountsMap.get(discountId);

            String accDocType;
            if (discount.Condition_Type__r == null && conditionTypeMap != null && conditionTypeMap.containsKey(discount.Condition_Type__c)) {
                accDocType = conditionTypeMap.get(discount.Condition_Type__c).Acc_Document_Type__c;
            } else {
                accDocType = discount.Condition_Type__r.Acc_Document_Type__c;
            }

            Contract__c contract = contractsMap.containsKey(discount.Contract__c) ? contractsMap.get(discount.Contract__c) : new Contract__c(Id = discount.Contract__c);
            List<Invoice__c> invoiceDiscListToInsert = new List<Invoice__c>();

            Integer invoiceDetailsCount = invoiceDetailsWrapperList.size();
            List<Integer> sequenceNumbers = new List<Integer>();

            for (Integer sequence = 1; sequence <= invoiceDetailsCount; sequence++) {
                if(discountToSequencesMap.containsKey(discountId) && discountToSequencesMap.get(discountId).contains(sequence)) continue;
                sequenceNumbers.add(sequence);
            }
            if(sequenceNumbers.size() < invoiceDetailsCount) {
                for (Integer sequence = sequenceNumbers.size() + 1; sequence <= invoiceDetailsCount; sequence++) {
                    sequenceNumbers.add(sequence);
                }
            }
            Set<Date> existingDates = discountToExistingDatesMap.containsKey(discountId)
                ? discountToExistingDatesMap.get(discountId)
                : new Set<Date>();
            Integer index = 0;
            for (InvoicesInfoWrapper invoiceDetailWrapper : invoiceDetailsWrapperList) {
                if (invoiceDetailWrapper.invoice.Status == 'Generated') {
                    Date invoiceDate = invoiceDetailWrapper.invoice.PrintDate;

                    if (existingDates.contains(invoiceDate)) {
                        System.debug(' Skipping invoice generation for ' + discountId + ' on ' + invoiceDate + ' - Invoice already exists (Printed/Validated)');
                        index++;
                        continue;
                    }
                    Invoice__c generatedInvoice = generateInvoice(
                        String.valueOf(invoiceDate),
                        accDocType,
                        discount,
                        contract,
                        (Integer) sequenceNumbers[index],
                        isPreBalance
                    );
                    invoiceDiscListToInsert.add(generatedInvoice);
                    invoicesListToInsert.add(generatedInvoice);
                    invoiceDetailWrapperMap.put(discountId + '' + index, invoiceDetailWrapper);
                    index++;
                }
            }

            invoicesDiscMap.put(discountId, invoiceDiscListToInsert);
        }

        List<Database.SaveResult> insertInvoicesResults = Database.insert(invoicesListToInsert);
        invoiceDetailsToInsert = new List<InvoiceDetail__c>();

        for (Id discountId : invoicesDiscMap.keySet()) {
            Contract_Discount__c discount = discountsMap.get(discountId);
            Contract__c contract = contractsMap.containsKey(discount.Contract__c) ? contractsMap.get(discount.Contract__c) : new Contract__c(Id = discount.Contract__c);
            List<Invoice__c> invoicesToInsert = invoicesDiscMap.get(discountId);

            Integer index = 0;
            for (Invoice__c inv : invoicesToInsert) {
                InvoicesInfoWrapper invoiceDetailWrapper = invoiceDetailWrapperMap.containsKey(discountId + '' + index) ? invoiceDetailWrapperMap.get(discountId + '' + index) : null;
                String detailAmount = invoiceDetailWrapper != null ? String.valueOf(invoiceDetailWrapper.Amount) : null;
                index++;
                generateInvoiceDetail(inv, discount, contract, detailAmount);
            }
        }

        if (!invoiceDetailsToInsert.isEmpty()) {
            Database.insert(invoiceDetailsToInsert, false);
        }
    }

    private static Invoice__c generateInvoice(String datekey, String accDocType, Contract_Discount__c disc, Contract__c contract, Integer seq) {
        return generateInvoice(datekey, accDocType, disc, contract, seq, false);
    }

    private static Invoice__c generateInvoice(String datekey, String accDocType, Contract_Discount__c disc, Contract__c contract, Integer seq, Boolean isPreBalance) {
        String invoiceRTId = NegoptimHelper.getObjectRecordTypeId(Invoice__c.SObjectType, 'TargetToSource');
        String documentType = ((accDocType == 'CreditNoteRequest' || accDocType == 'BalanceCreditNoteRequest') ? 'CreditNoteRequest' :
                               (accDocType == 'DebitNote') ? 'DebitNote' :
                               (accDocType == 'CreditNote') ? 'CreditNote' :
                               'Invoice');
        Date invoiceDate = String.isNotBlank(datekey) ? Date.valueOf(datekey) : null;
        if (isPreBalance && disc.DISC_Edate__c != null) { invoiceDate = disc.DISC_Edate__c.addDays(1); }
        Invoice__c invoice = new Invoice__c(RecordTypeId = invoiceRTId,
                                            Contract__c = disc.Contract__c,
                                            AgreementBDate__c = contract.Contract_Commercial_BDate__c,
                                            AgreementEDate__c = contract.Contract_Commercial_EDate__c,
                                            SupplierBuyer__c = contract.Supplier__c,
                                            invDate__c = invoiceDate,
                                            DueDate__c = (disc.Payment_Days__c != null && disc.Payment_Condition__c != null ?
                                                          NegoptimHelper.getDueDate(invoiceDate, Integer.valueOf(disc.Payment_Days__c), disc.Payment_Condition__c) : null),
                                            Status__c = 'Generated',
                                            AccDoc__c = accDocType,
                                            FiscalYear__c = contract.Reference_Year__c,
                                            AccDocType__c = documentType,
                                            SeqType__c = isPreBalance == true ? null : disc.Invoice_Period__c,
                                            SeqNumber__c = isPreBalance == true ? null : seq,
                                            IsUpdatedFromYTD__c = disc.Invoice_base__c == 'ActualYTD');
        if (isPreBalance && disc.INVDContractDiscount__r != null && !disc.INVDContractDiscount__r.isEmpty()) {
            invoice.SeqType__c = disc.INVDContractDiscount__r.get(0).Invoice__r.SeqType__c;
            Decimal maxSequenceNumber = null;
            for (InvoiceDetail__c invDetail : disc.INVDContractDiscount__r) {
                if (maxSequenceNumber == null || maxSequenceNumber < invDetail.Invoice__r.SeqNumber__c) {
                    maxSequenceNumber = invDetail.Invoice__r.SeqNumber__c;
                }
            }
            invoice.SeqNumber__c = maxSequenceNumber;
        }
        InvoiceServices.setInvoiceGL(invoice, contract, disc, glMap);
        InvoiceServices.setInvoiceGLCoordinates(invoice, contract, disc, glMap, null);
        return invoice;
    }

    private static void generateInvoiceDetail(Invoice__c invoice, Contract_Discount__c disc, Contract__c contract, String detailAmount) {
        InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(Invoice__c = invoice.Id,
                                                              BusinessUnitSellerDetail__c = contract.BusinessUnitContract__c,
                                                              DISCLineD__c = disc.Id,
                                                              DISCBudgetCode__c = disc.Condition_Type__c,
                                                              DISCNegoType__c = disc.Nego_Discount_Type__c,
                                                              DISCName__c = disc.Reference_condition__r?.Name,
                                                              DISCBDate__c = disc.Disc_BDate__c,
                                                              DISCEDate__c = disc.Disc_EDate__c,
                                                              DetailQty__c = 1,
                                                              LineId__c = 1,
                                                              DetailQtyUnit__c = 'C62',
                                                              DetailRebatePrice__c = 0);
        //if invoice base != actual
        if (detailAmount != null  && (disc.Is_Manual_Invoicing_Planning__c
                                      || disc.Invoice_base__c == 'Negotiated'
                                      || disc.Invoice_base__c == 'Forecasted'))
        {
            Decimal detailAmountScale = Decimal.valueOf(detailAmount).setScale(2, System.RoundingMode.HALF_UP);
            invoiceDetail.DetailAmount__c = detailAmountScale;
            invoiceDetail.DetailNetPrice__c = detailAmountScale;
            invoiceDetail.DetailGrossPrice__c = detailAmountScale;
        }
        invoiceDetailsToInsert.add(invoiceDetail);
    }

    public static Map<Id, Invoice__c> updateTaxes(List<InvoiceDetail__c> invoiceDetails, Map<Id, Invoice__c> invoicesMap, Boolean isUpdateInvoice) {
        invoicesMap = invoicesMap == null ? new Map<Id, Invoice__c>() : invoicesMap;
        List<InvoiceDetail__c> newInvoiceDetails = isUpdateInvoice ? new List<InvoiceDetail__c>() : invoiceDetails;
        Set<String> tariffConditionSet = new Set<String>();
        Set<String> detailZoneSet = new Set<String> {'None'};
        if(isUpdateInvoice) {
            for(Invoice__c item : invoicesMap.values()) {
                // clear all values
                item.TotalAmount__c = 0;
                item.TotalVATAmount__c = 0;
                item.TotalAmountwVAT__c = 0;
                for (Integer order = 1; order <= 8; order++) {
                    item.put('VATCode' + order + '__c', null);
                    item.put('VATRate' + order + '__c', null);
                    item.put('VATBaseAmount' + order + '__c', 0);
                    item.put('VATAmount' + order + '__c', 0);
                }
            }
            newInvoiceDetails = [SELECT Id, Invoice__c, BusinessUnitSellerDetail__c, DISCBudgetCode__c, DetailVATCode__c, DetailVATRate__c, DetailAmount__c
                                 FROM InvoiceDetail__c
                                 WHERE Invoice__c IN :invoicesMap.keySet()
                                 AND (DISCLineD__c = NULL OR DISCLineD__r.Status__c <> 'Deleted')];
        }
        for (InvoiceDetail__c item : newInvoiceDetails) {
            if(item.DISCBudgetCode__c != null) {
                tariffConditionSet.add(item.DISCBudgetCode__c);
            }
        }
        Set<Id> businessUnitSellerSet = new Set<Id>();
        for(Invoice__c item : invoicesMap.values()) {
            if(item.BusinessUnitSeller__c != null) {
                businessUnitSellerSet.add(item.BusinessUnitSeller__c);
            }
        }
        Map<Id, String> tariffConditionsMap = new Map<Id, String>();
        if(!tariffConditionSet.isEmpty()) {
            for(Pol_Com_Condition__c item : [SELECT Id, VAT_Type__c
                                             FROM Pol_Com_Condition__c
                                             WHERE Id IN :tariffConditionSet
                                             AND VAT_Type__c <> NULL])
            {
                tariffConditionsMap.put(item.Id, item.VAT_Type__c);
            }
        }
        Map<String, List<Tax__c>> taxesMap = new Map<String, List<Tax__c>>();
        if (!businessUnitSellerSet.isEmpty() && !tariffConditionsMap.isEmpty()) {
            for (Tax__c item : [SELECT Id, Code__c, TaxRate__c, ListingOrder__c, BusinessUnitVAT__c, Category__c, IsForeignSupplier__c,
                                Zone__c, TaxApplied__c, TaxApplied__r.Code__c, TaxApplied__r.TaxRate__c, TaxApplied__r.ListingOrder__c
                                FROM Tax__c
                                WHERE BusinessUnitVAT__c IN :businessUnitSellerSet
                                AND Category__c IN :tariffConditionsMap.values()
                                AND RecordType.DeveloperName = 'VATRule'
                                AND Zone__c <> NULL])
            {
                Boolean isForeignSupplier = item.IsForeignSupplier__c == null ? false : item.IsForeignSupplier__c;
                String key = String.valueOf(item.BusinessUnitVAT__c) + String.valueOf(item.Category__c) + String.valueOf(isForeignSupplier) + (item.Zone__c != null ? item.Zone__c : '');
                if(!taxesMap.containsKey(key)) taxesMap.put(key, new List<Tax__c>());
                Tax__c tax = new Tax__c(Id = item.TaxApplied__c, Code__c = item.TaxApplied__r.Code__c, TaxRate__c = item.TaxApplied__r.TaxRate__c, ListingOrder__c = item.TaxApplied__r.ListingOrder__c);
                taxesMap.get(key).add(tax);
            }
        }
        Map<String, Decimal> totalAmounts = new Map<String, Decimal>();
        Map<String, List<InvoiceDetail__c>> invoiceDetailsByVatCodeMap = new Map<String, List<InvoiceDetail__c>>();
        for (InvoiceDetail__c item : newInvoiceDetails) {
            Invoice__c invoice = invoicesMap.get(item.Invoice__c);
            Contract_Discount__c discount;
            if(invoice == null) continue;
            GlobalLocation__c glSeller = invoice.GlobalLocationSeller__r;
            GlobalLocation__c glBuyer = invoice.GlobalLocationBuyer__r;
            Id glSellerCountry = glSeller != null ? glSeller.Country__c : null;
            Id glBuyerCountry = glBuyer != null ? glBuyer.Country__c : null;
            String glBuyerZone = glBuyer != null ? glBuyer.Country__r.Zone__c : null;
            Boolean isForeignSupplier = glBuyerCountry != glSellerCountry;
            String zone = (!isForeignSupplier ? 'None' : (glBuyerZone != null ? glBuyerZone : ''));
            String key = (String.valueOf(item.BusinessUnitSellerDetail__c)
                          + (item.DISCBudgetCode__c != null && tariffConditionsMap.containsKey(item.DISCBudgetCode__c) ? tariffConditionsMap.get(item.DISCBudgetCode__c) : '')
                          + String.valueOf(isForeignSupplier)
                          + zone);
            List<Tax__c> taxesList = taxesMap.containsKey(key) ? taxesMap.get(key) : new List<Tax__c>();
            Tax__c tax;
            if (invoice.IsManualVAT__c) {
                if(!taxesList.isEmpty()) {
                    for(Tax__c taxItem : taxesList) {
                        if(taxItem.TaxRate__c == item.DetailVATRate__c) {
                            tax = taxItem;
                        }
                    }
                }
            } else {
                tax = !taxesList.isEmpty() ? taxesList[0] : null;
            }
            if(tax == null) {
                tax = new Tax__c(ListingOrder__c = '1', Code__c = 'VATERROR', TaxRate__c = 0);
            }
            if(!isUpdateInvoice) {
                item.CurrencyIsoCode = invoice.CurrencyIsoCode;
                item.DetailVATCode__c = tax.Code__c;
                item.DetailVATRate__c = tax.TaxRate__c;
            } else {
                if(!invoicesMap.containsKey(item.Invoice__c)) {
                    invoicesMap.put(item.Invoice__c, invoice.clone(false));
                }
                Invoice__c updatedInvoice = invoicesMap.get(item.Invoice__c);
                Decimal detailAmount = item.DetailAmount__c != null ? item.DetailAmount__c : 0;
                updatedInvoice.TotalAmount__c += detailAmount;
                String order = tax.ListingOrder__c;
                if(order != null && String.isNotBlank(item.DetailVATCode__c) && item.DetailVATRate__c != null) {
                    updatedInvoice.put('VATCode' + order + '__c', tax.Code__c);
                    updatedInvoice.put('VATRate' + order + '__c' , tax.TaxRate__c);
                    updatedInvoice.put('VATCode' + order + '__c', tax.Code__c);
                    updatedInvoice.put('VATRate' + order + '__c' , tax.TaxRate__c);
                    Decimal VATBaseAmount = (Decimal) updatedInvoice.get('VATBaseAmount' + order + '__c') + detailAmount;
                    updatedInvoice.put('VATBaseAmount' + order + '__c', VATBaseAmount);
                    Decimal currentVatAmount = (Decimal) updatedInvoice.get('VATBaseAmount' + order + '__c');
                    Decimal VATAmount = (Decimal) updatedInvoice.get('VATAmount' + order + '__c') + detailAmount * item.DetailVATRate__c * 0.01;
                    updatedInvoice.put('VATAmount' + order + '__c' , VATAmount);

                }
                invoicesMap.put(updatedInvoice.Id, updatedInvoice);
            }
        }
        if(isUpdateInvoice) {
            for(Invoice__c item : invoicesMap.values()) {
                for (Integer order = 1; order <= 8; order++) {
                    item.TotalVATAmount__c += item.get('VATAmount' + order + '__c') != null ? (Decimal) item.get('VATAmount' + order + '__c') : 0;
                }
                item.TotalAmountwVAT__c = item.TotalVATAmount__c + (item.TotalAmount__c != null ? item.TotalAmount__c : 0);
            }
        }
        return invoicesMap;
    }

    public static void setInvoiceGL(Invoice__c invoice, Contract__c contract, Contract_Discount__c disc, Map<String, GlobalLocation__c> glMap) {
        if (invoice.Id == null || disc != null) {
            // invoice.BusinessUnitSeller__c = null;
            // invoice.GlobalLocationSeller__c = null;
            // invoice.GlobalLocationPayee__c = null;
            // invoice.GlobalLocationBuyer__c = null;
            // invoice.GlobalLocationDelivery__c = null;
            if (contract != null && contract.BusinessUnitContract__r.SetInvoiceSeller__c && invoice.BusinessUnitSeller__c == null && invoice.RecordTypeId == invoiceRTIds.get('TargetToSource')) {
                invoice.BusinessUnitSeller__c = contract.BusinessUnitContract__c;
            }
            if (disc != null && disc.GlobalLocationSeller__c != null && invoice.GlobalLocationSeller__c == null) {
                invoice.GlobalLocationSeller__c = disc.GlobalLocationSeller__c;
            }
            if (disc != null && disc.GlobalLocationPayee__c != null && invoice.GlobalLocationPayee__c == null) {
                if (disc.GlobalLocationPayee__c != invoice.GlobalLocationSeller__c) {
                    invoice.GlobalLocationPayee__c = disc.GlobalLocationPayee__c;
                }
            }
            invoice.IsPayeeSameAsSeller__c = invoice.GlobalLocationPayee__c == null;
            Id buyerId = disc != null ? (disc.Product_Scope__r.GlobalLocationAccounting__c != null ? disc.Product_Scope__r.GlobalLocationAccounting__c : disc.Product_Scope__r.GlobalLocationAdministration__c) : null;
            if (buyerId != null && invoice.GlobalLocationBuyer__c == null) {
                invoice.GlobalLocationBuyer__c = buyerId;
            } else if (!glMap.isEmpty()) {
                Id supplierId = (contract != null ? contract.Supplier__c : invoice.SupplierBuyer__c);
                String keyInvoiceTo = supplierId + 'InvoiceTo';
                String keyAdministrative = supplierId + 'Administrative';
                GlobalLocation__c gl;
                if (glMap.containsKey(keyInvoiceTo)) {
                    gl = glMap.get(keyInvoiceTo);
                } else if (glMap.containsKey(keyAdministrative)) {
                    gl = glMap.get(keyAdministrative);
                }
                if (invoice.Id == null && gl != null && invoice.GlobalLocationBuyer__c == null) {
                    invoice.GlobalLocationBuyer__c = gl.Id;
                }
            }
            Id glAccountingId = disc != null && disc.Product_Scope__r.GlobalLocationAccounting__c != null ? disc.Product_Scope__r.GlobalLocationAccounting__c : null;
            Id deliveryId = disc != null ? (disc.Product_Scope__r.GlobalLocationDelivery__c != null ? disc.Product_Scope__r.GlobalLocationDelivery__c : disc.Product_Scope__r.GlobalLocationAdministration__c) : null;
            if (deliveryId != null) {
                if (deliveryId != glAccountingId && invoice.GlobalLocationDelivery__c == null) {
                    invoice.GlobalLocationDelivery__c = deliveryId;
                }
            }
            invoice.IsDeliverySameAsBuyer__c = invoice.GlobalLocationDelivery__c == null;
        }
    }
    public static void setInvoiceGLCoordinates(Invoice__c invoice, Contract__c contract, Contract_Discount__c disc, Map<String, GlobalLocation__c> glMap, Map<String, Boolean> updatedGLMap) {
        // Seller
        if(updatedGLMap == null || (updatedGLMap.containsKey(SObjectType.Invoice__c.fields.GlobalLocationSeller__c.Name)
                                    && updatedGLMap.get(SObjectType.Invoice__c.fields.GlobalLocationSeller__c.Name) == true))
        {
            if (invoice.GlobalLocationSeller__c != null && glMap.containsKey(invoice.GlobalLocationSeller__c)) {
                GlobalLocation__c gl = glMap.get(invoice.GlobalLocationSeller__c);
                invoice.SellerCompanyName__c = gl.CompanyName__c;
                invoice.SellerCommercialName__c = gl.Name;
                invoice.SellerAddress1__c = gl.Address1__c;
                invoice.SellerAddress2__c = gl.Address2__c;
                invoice.SellerAddress3__c = gl.Address3__c;
                invoice.SellerPostalCode__c = gl.PostalCode__c;
                invoice.SellerCity__c = gl.City__c;
                invoice.CountryListSeller__c = gl.Country__c;
                invoice.SellerPhone1__c = gl.Phone1__c;
                invoice.SellerPhone2__c = gl.Phone2__c;
                invoice.SellerIdentifier1__c = gl.Identifier1__c;
                invoice.SellerIdentifier2__c = gl.Identifier2__c;
                invoice.SellerIdentifier3__c = gl.Identifier3__c;
                invoice.SellerIdentifier4__c = gl.Identifier4__c;
                invoice.SellerIdentifier5__c = gl.Identifier5__c;
            } else if (invoice.GlobalLocationSeller__c == null) {
                invoice.SellerCompanyName__c = null;
                invoice.SellerCommercialName__c = null;
                invoice.SellerAddress1__c = null;
                invoice.SellerAddress2__c = null;
                invoice.SellerAddress3__c = null;
                invoice.SellerPostalCode__c = null;
                invoice.SellerCity__c = null;
                invoice.CountryListSeller__c = null;
                invoice.SellerPhone1__c = null;
                invoice.SellerPhone2__c = null;
                invoice.SellerIdentifier1__c = null;
                invoice.SellerIdentifier2__c = null;
                invoice.SellerIdentifier3__c = null;
                invoice.SellerIdentifier4__c = null;
                invoice.SellerIdentifier5__c = null;
            }
        }
        // Payee
        if(updatedGLMap == null || (updatedGLMap.containsKey(SObjectType.Invoice__c.fields.GlobalLocationPayee__c.Name)
                                    && updatedGLMap.get(SObjectType.Invoice__c.fields.GlobalLocationPayee__c.Name) == true))
        {
            if (invoice.GlobalLocationPayee__c != null && glMap.containsKey(invoice.GlobalLocationPayee__c)) {
                GlobalLocation__c gl = glMap.get(invoice.GlobalLocationPayee__c);
                invoice.PayeeCompanyName__c = gl.CompanyName__c;
                invoice.PayeeCommercialName__c = gl.Name;
                invoice.PayeeAddress1__c = gl.Address1__c;
                invoice.PayeeAddress2__c = gl.Address2__c;
                invoice.PayeeAddress3__c = gl.Address3__c;
                invoice.PayeePostalCode__c = gl.PostalCode__c;
                invoice.PayeeCity__c = gl.City__c;
                invoice.CountryListPayee__c = gl.Country__c;
                invoice.PayeePhone1__c = gl.Phone1__c;
                invoice.PayeePhone2__c = gl.Phone2__c;
                invoice.PayeeIdentifier1__c = gl.Identifier1__c;
                invoice.PayeeIdentifier2__c = gl.Identifier2__c;
                invoice.PayeeIdentifier3__c = gl.Identifier3__c;
                invoice.PayeeIdentifier4__c = gl.Identifier4__c;
                invoice.PayeeIdentifier5__c = gl.Identifier5__c;
            } else if (invoice.GlobalLocationPayee__c == null) {
                invoice.PayeeCompanyName__c = null;
                invoice.PayeeCommercialName__c = null;
                invoice.PayeeAddress1__c = null;
                invoice.PayeeAddress2__c = null;
                invoice.PayeeAddress3__c = null;
                invoice.PayeePostalCode__c = null;
                invoice.PayeeCity__c = null;
                invoice.CountryListPayee__c = null;
                invoice.PayeePhone1__c = null;
                invoice.PayeePhone2__c = null;
                invoice.PayeeIdentifier1__c = null;
                invoice.PayeeIdentifier2__c = null;
                invoice.PayeeIdentifier3__c = null;
                invoice.PayeeIdentifier4__c = null;
                invoice.PayeeIdentifier5__c = null;
            }
        }
        // Buyer
        if(updatedGLMap == null || (updatedGLMap.containsKey(SObjectType.Invoice__c.fields.GlobalLocationBuyer__c.Name)
                                    && updatedGLMap.get(SObjectType.Invoice__c.fields.GlobalLocationBuyer__c.Name) == true))
        {
            if (invoice.GlobalLocationBuyer__c != null && glMap.containsKey(invoice.GlobalLocationBuyer__c)) {
                GlobalLocation__c gl = glMap.get(invoice.GlobalLocationBuyer__c);
                invoice.BuyerCompanyName__c = gl.CompanyName__c;
                invoice.BuyerCommercialName__c = gl.Name;
                invoice.BuyerAddress1__c = gl.Address1__c;
                invoice.BuyerAddress2__c = gl.Address2__c;
                invoice.BuyerAddress3__c = gl.Address3__c;
                invoice.BuyerPostalCode__c = gl.PostalCode__c;
                invoice.BuyerCity__c = gl.City__c;
                invoice.CountryListBuyer__c = gl.Country__c;
                invoice.BuyerPhone1__c = gl.Phone1__c;
                invoice.BuyerPhone2__c = gl.Phone2__c;
                invoice.BuyerIdentifier1__c = gl.Identifier1__c;
                invoice.BuyerIdentifier2__c = gl.Identifier2__c;
                invoice.BuyerIdentifier3__c = gl.Identifier3__c;
                invoice.BuyerIdentifier4__c = gl.Identifier4__c;
                invoice.BuyerIdentifier5__c = gl.Identifier5__c;
                //Extra
                invoice.CurrencyIsoCode = gl.CurrencyIsoCode;
                invoice.ReferenceLanguage__c = gl.ReferenceLanguage__c;
            } else if (invoice.GlobalLocationBuyer__c == null) {
                invoice.BuyerCompanyName__c = null;
                invoice.BuyerCommercialName__c = null;
                invoice.BuyerAddress1__c = null;
                invoice.BuyerAddress2__c = null;
                invoice.BuyerAddress3__c = null;
                invoice.BuyerPostalCode__c = null;
                invoice.BuyerCity__c = null;
                invoice.CountryListBuyer__c = null;
                invoice.BuyerPhone1__c = null;
                invoice.BuyerPhone2__c = null;
                invoice.BuyerIdentifier1__c = null;
                invoice.BuyerIdentifier2__c = null;
                invoice.BuyerIdentifier3__c = null;
                invoice.BuyerIdentifier4__c = null;
                invoice.BuyerIdentifier5__c = null;
                invoice.CurrencyIsoCode = null;
                invoice.ReferenceLanguage__c = null;
            }
        }
        // Delivery
        if(updatedGLMap == null || (updatedGLMap.containsKey(SObjectType.Invoice__c.fields.GlobalLocationDelivery__c.Name)
                                    && updatedGLMap.get(SObjectType.Invoice__c.fields.GlobalLocationDelivery__c.Name) == true))
        {
            if (invoice.GlobalLocationDelivery__c != null && glMap.containsKey(invoice.GlobalLocationDelivery__c)) {
                GlobalLocation__c gl = glMap.get(invoice.GlobalLocationDelivery__c);
                invoice.DeliveryCompanyName__c = gl.CompanyName__c;
                invoice.DeliveryCommercialName__c = gl.Name;
                invoice.DeliveryAddress1__c = gl.Address1__c;
                invoice.DeliveryAddress2__c = gl.Address2__c;
                invoice.DeliveryAddress3__c = gl.Address3__c;
                invoice.DeliveryPostalCode__c = gl.PostalCode__c;
                invoice.DeliveryCity__c = gl.City__c;
                invoice.CountryListDelivery__c = gl.Country__c;
                invoice.DeliveryPhone1__c = gl.Phone1__c;
                invoice.DeliveryPhone2__c = gl.Phone2__c;
                invoice.DeliveryIdentifier1__c = gl.Identifier1__c;
                invoice.DeliveryIdentifier2__c = gl.Identifier2__c;
                invoice.DeliveryIdentifier3__c = gl.Identifier3__c;
                invoice.DeliveryIdentifier4__c = gl.Identifier4__c;
                invoice.DeliveryIdentifier5__c = gl.Identifier5__c;
            } else if (invoice.GlobalLocationDelivery__c == null) {
                invoice.DeliveryCompanyName__c = null;
                invoice.DeliveryCommercialName__c = null;
                invoice.DeliveryAddress1__c = null;
                invoice.DeliveryAddress2__c = null;
                invoice.DeliveryAddress3__c = null;
                invoice.DeliveryPostalCode__c = null;
                invoice.DeliveryCity__c = null;
                invoice.CountryListDelivery__c = null;
                invoice.DeliveryPhone1__c = null;
                invoice.DeliveryPhone2__c = null;
                invoice.DeliveryIdentifier1__c = null;
                invoice.DeliveryIdentifier2__c = null;
                invoice.DeliveryIdentifier3__c = null;
                invoice.DeliveryIdentifier4__c = null;
                invoice.DeliveryIdentifier5__c = null;
            }
        }
    }

    public static InvoiceToCancelResultWrapper cancelInvoices(List<Invoice__c> invoicesListToCanceled, Map<Id, InvoiceToCancelWrapper> invoiceToCancelMap) {
        InvoiceToCancelResultWrapper invoiceToCancelResultWrapper = new InvoiceToCancelResultWrapper();
        System.SavePoint sp = Database.setSavepoint();
        try {
            Set<Id> invoiceIds = new Set<Id>();
            Map<Integer, Invoice__c> invoicesToInsertMap = new Map<Integer, Invoice__c>();
            Map<Integer, Invoice__c> invoicesSupplierCreditNoteToInsertMap = new Map<Integer, Invoice__c>();
            Map<Integer, List<InvoiceDetail__c>> invoiceDetailsToInsertMap = new Map<Integer, List<InvoiceDetail__c>>();
            Map<Id, InvoiceDetail__c> invoiceDetailsListToCancelMap = new Map<Id, InvoiceDetail__c>();
            List<InvoiceLink__c> invoiceLinksToInsert = new List<InvoiceLink__c>();
            Map<Integer, Invoice__c> invoicesListToCanceledMap = new Map<Integer, Invoice__c>();
            Integer index = 0;
            if (!invoicesListToCanceled.isEmpty()) {
                // GET CancelInvoices
                Set<Id> invoicesFullCancelIds = new Set<Id>();
                Map<Id, Decimal> invoiceDetailAmountToCancelMap = new Map<Id, Decimal>();
                for (Invoice__c invoiceToCancel : invoicesListToCanceled) {
                    InvoiceToCancelWrapper invoiceToCancelWrapper = invoiceToCancelMap.get(invoiceToCancel.Id);
                    if(invoiceToCancelWrapper.isFullCancel) {
                        List<InvoiceDetail__c> invoiceDetailsListToCanceled = invoiceToCancel.INVDInvoice__r;
                        if (!invoiceDetailsListToCanceled.isEmpty()) {
                            for (InvoiceDetail__c invoiceDetailToCancel : invoiceDetailsListToCanceled) {
                                invoiceDetailAmountToCancelMap.put(invoiceDetailToCancel.Id, invoiceDetailToCancel.RestToPaidAmount__c);
                            }
                        }
                        invoicesFullCancelIds.add(invoiceToCancel.Id);
                    }
                }
                if(!invoicesFullCancelIds.isEmpty()) {
                    List<InvoiceDetail__c> cancelInvoiceDetails = [SELECT Id, InvoiceDetailLinked__c, DetailAmount__c
                                                                   FROM InvoiceDetail__c
                                                                   WHERE Invoice__c IN (SELECT Invoice__c
                                                                                        FROM InvoiceLink__c
                                                                                        WHERE InvoiceLinked__c IN :invoicesFullCancelIds
                                                                                        AND Invoice__r.AccDoc__c IN ('CNCancelRequest', 'BalanceCNCancelRequest', 'BalanceCreditNote', 'CreditNote')
                                                                                        AND Invoice__r.Status__c IN ('Generated', 'Validated', 'ReadyToPrint'))];
                    for(InvoiceDetail__c item : cancelInvoiceDetails) {
                        if(invoiceDetailAmountToCancelMap.containsKey(item.InvoiceDetailLinked__c)) {
                            Decimal amountToCancel = invoiceDetailAmountToCancelMap.get(item.InvoiceDetailLinked__c);
                            amountToCancel = (amountToCancel != null ? amountToCancel : 0) + (item.DetailAmount__c != null ? item.DetailAmount__c : 0);
                            invoiceDetailAmountToCancelMap.put(item.InvoiceDetailLinked__c, amountToCancel);
                        }
                    }
                }
                for (Invoice__c invoiceToCancel : invoicesListToCanceled) {
                    InvoiceToCancelWrapper invoiceToCancelWrapper = invoiceToCancelMap.get(invoiceToCancel.Id);
                    // create Invoice__c
                    Invoice__c newInvoice = invoiceToCancel.clone(false);
                    newInvoice.IsUpdatedFromYTD__c = false;
                    newInvoice.Status__c = 'Generated';
                    newInvoice.AccDoc__c = null;
                    switch on invoiceToCancel.AccDoc__c {
                        when 'CreditNoteRequest' {
                            newInvoice.AccDoc__c = 'CNCancelRequest';
                        }
                        when 'BalanceCreditNoteRequest' {
                            newInvoice.AccDoc__c = 'BalanceCNCancelRequest';
                        }
                        when 'BalanceInvoice' {
                            newInvoice.AccDoc__c = 'BalanceCreditNote';
                        }
                        when else /*when 'DownPaymentInvoice'*/ {
                            newInvoice.AccDoc__c = 'CreditNote';
                        }
                    }
                    newInvoice.InvDate__c = Date.today();
                    newInvoice.DueDate__c = newInvoice.InvDate__c;
                    // get payment days/payment conditions from first invoice detail
                    List<InvoiceDetail__c> invoiceDetailsListToCanceled = invoiceToCancel.INVDInvoice__r;
                    if (!invoiceDetailsListToCanceled.isEmpty()) {
                        InvoiceDetail__c firstInvoiceDetailToCancel = invoiceDetailsListToCanceled[0];
                        Integer paymentDays = firstInvoiceDetailToCancel.DISCLineD__r.Payment_Days__c != null ? Integer.valueOf(firstInvoiceDetailToCancel.DISCLineD__r.Payment_Days__c) : null;
                        String paymentCondition = firstInvoiceDetailToCancel.DISCLineD__r.Payment_Condition__c != null ? firstInvoiceDetailToCancel.DISCLineD__r.Payment_Condition__c : null;
                        if (paymentDays != null && paymentCondition != null) {
                            newInvoice.DueDate__c = NegoptimHelper.getDueDate(Date.valueOf(newInvoice.InvDate__c), paymentDays, paymentCondition);
                        }
                    }
                    newInvoice.PrintDate__c = null;
                    newInvoice.InvNumber__c = null;
                    newInvoice.NoteCode1__c = null;
                    newInvoice.Note1__c = null;
                    newInvoice.NoteCode2__c = null;
                    newInvoice.Note2__c = null;
                    newInvoice.NoteCode3__c = null;
                    newInvoice.Note3__c = null;
                    newInvoice.ExtId__c = null;
                    newInvoice.ExtractLDate__c = null;
                    newInvoice.ExtractLId__c = null;
                    newInvoice.ExtractLStatus__c = null;
                    newInvoice.t_HiddenForSearch__c = null;
                    newInvoice.IntegLId__c = null;
                    newInvoice.IntegLDate__c = null;
                    newInvoice.SupportBy__c = null;
                    newInvoice.SupportLDate__c = null;
                    newInvoice.SupportNote__c = null;
                    newInvoice.PaidVATAmount__c = null;
                    newInvoice.PaidAmountwVAT__c = null;
                    // Create Supplier Credit Note
                    Invoice__c newInvoiceSupplierCreditNote;
                    if(invoiceToCancelWrapper.isCreateSupplierCreditNote) {
                        newInvoiceSupplierCreditNote = invoiceToCancelWrapper.newInvoiceSupplierCreditNote;
                        newInvoiceSupplierCreditNote.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Invoice__c.SObjectType, 'SourceToTarget');
                        newInvoiceSupplierCreditNote.BusinessUnitSeller__c = null;
                        newInvoiceSupplierCreditNote.SupplierSeller__c = invoiceToCancel.Contract__r.Supplier__c;
                        newInvoiceSupplierCreditNote.GlobalLocationSeller__c = null;
                        newInvoiceSupplierCreditNote.BusinessUnitBuyer__c= invoiceToCancel.BusinessUnitSeller__c;
                        newInvoiceSupplierCreditNote.SupplierBuyer__c = null;
                        newInvoiceSupplierCreditNote.Status__c = 'Listed';
                        newInvoiceSupplierCreditNote.AccDocType__c = 'CreditNote';
                        newInvoiceSupplierCreditNote.AccDoc__c = 'CreditNote';
                        newInvoiceSupplierCreditNote.InvDate__c = Date.today();
                        newInvoiceSupplierCreditNote.DueDate__c = null;
                        newInvoiceSupplierCreditNote.PrintDate__c = Date.today();
                        newInvoiceSupplierCreditNote.FiscalYear__c = invoiceToCancel.FiscalYear__c;
                        newInvoiceSupplierCreditNote.SeqType__c = invoiceToCancel.SeqType__c;
                        newInvoiceSupplierCreditNote.SeqNumber__c = invoiceToCancel.SeqNumber__c;
                        newInvoiceSupplierCreditNote.Contract__c = invoiceToCancel.Contract__c;
                        newInvoiceSupplierCreditNote.AgreementBDate__c = invoiceToCancel.AgreementBDate__c;
                        newInvoiceSupplierCreditNote.AgreementEDate__c = invoiceToCancel.AgreementEDate__c;
                        newInvoiceSupplierCreditNote.CurrencyIsoCode = invoiceToCancel.CurrencyIsoCode;
                        newInvoiceSupplierCreditNote.ExchangeRate__c = invoiceToCancel.ExchangeRate__c;
                        newInvoiceSupplierCreditNote.VATRate1__c = null;
                        newInvoiceSupplierCreditNote.VATAmount1__c = null;
                        newInvoiceSupplierCreditNote.VATRate2__c = null;
                        newInvoiceSupplierCreditNote.VATAmount2__c = null;
                        newInvoiceSupplierCreditNote.VATRate3__c = null;
                        newInvoiceSupplierCreditNote.VATAmount3__c = null;
                        newInvoiceSupplierCreditNote.VATRate4__c = null;
                        newInvoiceSupplierCreditNote.VATAmount4__c = null;
                        newInvoiceSupplierCreditNote.VATRate5__c = null;
                        newInvoiceSupplierCreditNote.VATAmount5__c = null;
                        newInvoiceSupplierCreditNote.VATRate6__c = null;
                        newInvoiceSupplierCreditNote.VATAmount6__c = null;
                        newInvoiceSupplierCreditNote.VATRate7__c = null;
                        newInvoiceSupplierCreditNote.VATAmount7__c = null;
                        newInvoiceSupplierCreditNote.VATRate8__c = null;
                        newInvoiceSupplierCreditNote.VATAmount8__c = null;
                        newInvoiceSupplierCreditNote.TotalVATAmount__c = null;
                        newInvoiceSupplierCreditNote.TotalAmount__c = null;
                        newInvoiceSupplierCreditNote.TotalAmountwVAT__c = null;
                        newInvoiceSupplierCreditNote.IsEinvoicingOK__c = false;
                        newInvoiceSupplierCreditNote.NoteCode1__c = null;
                        newInvoiceSupplierCreditNote.Note1__c = null;
                        newInvoiceSupplierCreditNote.NoteCode2__c = null;
                        newInvoiceSupplierCreditNote.Note2__c = null;
                        newInvoiceSupplierCreditNote.NoteCode3__c = null;
                        newInvoiceSupplierCreditNote.Note3__c = null;
                        newInvoiceSupplierCreditNote.ExtId__c = null;
                        newInvoiceSupplierCreditNote.ExtractLDate__c = null;
                        newInvoiceSupplierCreditNote.ExtractLId__c = null;
                        newInvoiceSupplierCreditNote.ExtractLStatus__c = null;
                        newInvoiceSupplierCreditNote.t_HiddenForSearch__c = null;
                        newInvoiceSupplierCreditNote.IntegLId__c = null;
                        newInvoiceSupplierCreditNote.IntegLDate__c = null;
                        newInvoiceSupplierCreditNote.SupportBy__c = null;
                        newInvoiceSupplierCreditNote.SupportLDate__c = null;
                        newInvoiceSupplierCreditNote.SupportNote__c = null;
                        newInvoiceSupplierCreditNote.ReferenceLanguage__c = null;
                        //newInvoiceSupplierCreditNote.LastRecordedAction__c = null;
                        newInvoiceSupplierCreditNote.isUpdatedFromYTD__c = false;
                        newInvoiceSupplierCreditNote.PaidVATAmount__c = 0;
                        newInvoiceSupplierCreditNote.PaidAmountwVAT__c = 0;
                        newInvoiceSupplierCreditNote.IsManualVAT__c = true;
                    }
                    // create InvoiceDetail__c
                    List<InvoiceDetail__c> invoiceDetailsToInsert = new List<InvoiceDetail__c>();
                    List<InvoiceDetail__c> invoiceDetailsSupplierCreditNoteToInsert = new List<InvoiceDetail__c>();
                    if (!invoiceDetailsListToCanceled.isEmpty()) {
                        //Integer indexINVD = 0;
                        for (InvoiceDetail__c invoiceDetailToCancel : invoiceDetailsListToCanceled) {
                            if(!invoiceToCancelWrapper.isFullCancel && (invoiceToCancelWrapper.invoiceDetailAmountToCancelMap == null
                                                                        || !invoiceToCancelWrapper.invoiceDetailAmountToCancelMap.containsKey(invoiceDetailToCancel.Id))) continue;
                            InvoiceDetail__c newInvoiceDetail = invoiceDetailToCancel.clone(false);
                            //newInvoiceDetail.LineId__c = indexINVD++;
                            newInvoiceDetail.LineDesc__c = null;
                            newInvoiceDetail.LineNote__c = null;
                            Decimal amountToCancel;
                            if(invoiceToCancelWrapper.isFullCancel) {
                                //amountToCancel = invoiceDetailToCancel.RestToPaidAmount__c != null ? (invoiceDetailToCancel.RestToPaidAmount__c * -1) : 0;
                                amountToCancel = invoiceDetailAmountToCancelMap.containsKey(invoiceDetailToCancel.Id) ? invoiceDetailAmountToCancelMap.get(invoiceDetailToCancel.Id) * -1 : 0;
                            } else {
                                amountToCancel = invoiceToCancelWrapper.invoiceDetailAmountToCancelMap.get(invoiceDetailToCancel.Id);
                            }
                            if(amountToCancel == null || amountToCancel == 0) continue;
                            newInvoiceDetail.DetailAmount__c = amountToCancel;
                            newInvoiceDetail.DetailNetPrice__c = amountToCancel;
                            newInvoiceDetail.DetailGrossPrice__c = amountToCancel;
                            newInvoiceDetail.IntegLDate__c = null;
                            newInvoiceDetail.SupportBy__c = null;
                            newInvoiceDetail.SupportLDate__c = null;
                            newInvoiceDetail.ExtId__c = null;
                            newInvoiceDetail.ExtractLDate__c = null;
                            newInvoiceDetail.ExtractLId__c = null;
                            newInvoiceDetail.PaidVATAmount__c = 0;
                            newInvoiceDetail.PaidAmountwVAT__c = 0;
                            newInvoiceDetail.InvoiceDetailLinked__c = invoiceDetailToCancel.Id;
                            invoiceDetailsListToCancelMap.put(invoiceDetailToCancel.Id, newInvoiceDetail);
                            invoiceDetailsToInsert.add(newInvoiceDetail);
                            // Create Supplier Credit Note
                            if(invoiceToCancelWrapper.isCreateSupplierCreditNote) {
                                InvoiceDetail__c newInvoiceDetailSupplierCreditNote = new InvoiceDetail__c(BusinessUnitSellerDetail__c = invoiceDetailToCancel.BusinessUnitSellerDetail__c,
                                                                                                           LineId__c = invoiceDetailToCancel.LineId__c,
                                                                                                           LineDesc__c = invoiceDetailToCancel.LineDesc__c,
                                                                                                           LineNote__c = invoiceDetailToCancel.LineNote__c,
                                                                                                           //DISCLine__c = invoiceDetailToCancel.DISCLine__c,
                                                                                                           DISCLineD__c = invoiceDetailToCancel.DISCLineD__c,
                                                                                                           DISCNegoType__c = invoiceDetailToCancel.DISCNegoType__c,
                                                                                                           DISCBudgetCode__c = invoiceDetailToCancel.DISCBudgetCode__c,
                                                                                                           DISCRate__c = invoiceDetailToCancel.DISCRate__c,
                                                                                                           DISCName__c = invoiceDetailToCancel.DISCName__c,
                                                                                                           DISCBDate__c = invoiceDetailToCancel.DISCBDate__c,
                                                                                                           DISCEDate__c = invoiceDetailToCancel.DISCEDate__c,
                                                                                                           DetailAmount__c = invoiceDetailToCancel.DetailAmount__c,
                                                                                                           DetailVATCode__c = invoiceDetailToCancel.DetailVATCode__c,
                                                                                                           DetailVATRate__c = invoiceDetailToCancel.DetailVATRate__c,
                                                                                                           DetailQty__c = invoiceDetailToCancel.DetailQty__c,
                                                                                                           DetailQtyUnit__c = invoiceDetailToCancel.DetailQtyUnit__c,
                                                                                                           DetailNetPrice__c = invoiceDetailToCancel.DetailNetPrice__c,
                                                                                                           DetailGrossPrice__c = invoiceDetailToCancel.DetailGrossPrice__c,
                                                                                                           DetailRebatePrice__c = invoiceDetailToCancel.DetailRebatePrice__c,
                                                                                                           //DetailRebateAmount__c = invoiceDetailToCancel.DetailRebateAmount__c,
                                                                                                           IntegLDate__c = null,
                                                                                                           SupportBy__c = null,
                                                                                                           SupportLDate__c = null,
                                                                                                           Extid__c = null,
                                                                                                           ExtractLDate__c = null,
                                                                                                           ExtractLId__c = null,
                                                                                                           CurrencyIsoCode = invoiceDetailToCancel.CurrencyIsoCode,
                                                                                                           InvoiceDetailLinked__c = invoiceDetailToCancel.Id,
                                                                                                           PaidAmountwVAT__c = null,
                                                                                                           PaidVATAmount__c = null);
                                invoiceDetailsSupplierCreditNoteToInsert.add(newInvoiceDetailSupplierCreditNote);
                            }
                        }
                        invoiceDetailsToInsertMap.put(index, invoiceDetailsToInsert);
                    }
                    if(invoiceDetailsToInsertMap.containsKey(index) && !invoiceDetailsToInsertMap.get(index).isEmpty()) {
                        invoicesToInsertMap.put(index, newInvoice);
                        invoicesListToCanceledMap.put(index, invoiceToCancel);
                        index++;
                        if(invoiceToCancelWrapper.isCreateSupplierCreditNote) {
                            invoicesToInsertMap.put(index, newInvoiceSupplierCreditNote);
                            invoicesSupplierCreditNoteToInsertMap.put(index, newInvoiceSupplierCreditNote);
                            invoiceDetailsToInsertMap.put(index, invoiceDetailsSupplierCreditNoteToInsert);
                            index++;
                        }
                    }
                }
                // create Invoice__c
                if (!invoicesToInsertMap.isEmpty()) {
                    List<Database.SaveResult> results = Database.insert(invoicesToInsertMap.values(), false);
                    List<InvoiceDetail__c> invoiceDetailsToInsert = new List<InvoiceDetail__c>();
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Invoice__c newInvoice = invoicesToInsertMap.get(i);
                        Invoice__c invoiceToCancel;
                        if(invoicesListToCanceledMap.containsKey(i)) {
                            invoiceToCancel = invoicesListToCanceledMap.get(i);
                            invoiceToCancelResultWrapper.invoicesToCancel.add(invoiceToCancel);
                        }
                        if (result.isSuccess()) {
                            if (!invoiceDetailsToInsertMap.isEmpty() && invoiceDetailsToInsertMap.containskey(i)) {
                                for (InvoiceDetail__c item : invoiceDetailsToInsertMap.get(i)) {
                                    item.Invoice__c = newInvoice.Id;
                                    invoiceDetailsToInsert.add(item);
                                }
                            }
                            if(invoicesSupplierCreditNoteToInsertMap.containsKey(i)) {
                                invoiceToCancelResultWrapper.invoicesSupplierCreditNoteMap.put(newInvoice.Id, newInvoice);
                            }
                            // link the canceled invoice and the new invoice
                            if(invoiceToCancel != null) {
                                InvoiceLink__c invoiceLink = new InvoiceLink__c(Invoice__c = newInvoice.Id, InvoiceLinked__c = invoiceToCancel.Id);
                                invoiceLinksToInsert.add(invoiceLink);
                                invoiceToCancelResultWrapper.invoicesToCancelMap.put(invoiceToCancel.Id, newInvoice);
                            }
                        } else {
                            String errorMessage = newInvoice + '\n';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            invoiceToCancelResultWrapper.errorMessages.add(errorMessage);
                            if(invoiceToCancel != null) {
                                invoiceToCancelResultWrapper.failedInvoices.put(invoiceToCancel.Id, errorMessage);
                            }
                            System.debug('ERROR >>>' + errorMessage);
                        }
                    }
                    // create InvoiceLink__c
                    if (!invoiceLinksToInsert.isEmpty()) {
                        results = Database.insert(invoiceLinksToInsert, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = '';
                                Database.Error[] errs = result.getErrors();
                                for (Database.Error err : errs) {
                                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                                }
                                invoiceToCancelResultWrapper.errorMessages.add(errorMessage);
                                System.debug('ERROR >>>' + errorMessage);
                            }
                        }
                    }
                    // create InvoiceDetail__c
                    if (!invoiceDetailsToInsert.isEmpty()) {
                        results = Database.insert(invoiceDetailsToInsert, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            InvoiceDetail__c newInvoiceDetail = invoiceDetailsToInsert.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = newInvoiceDetail + '\n';
                                Database.Error[] errs = result.getErrors();
                                for (Database.Error err : errs) {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                invoiceToCancelResultWrapper.errorMessages.add(errorMessage);
                                System.debug('ERROR >>>' + errorMessage);
                            }
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            invoiceToCancelResultWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            invoiceToCancelResultWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        return invoiceToCancelResultWrapper;
    }
    /*
     * @description Creation des paiements de types Letterage sur la pièce d'annulation et la pièce de demande d'annulation
     *              lors de l'impression de la pièce d'annulation.
     * @params: Set<Id> List of invoice CreditNote Printed
     */
    public static List<String> generatePayments(Set<Id> invoiceCreditNoteIds) {
        List<String> errorMessages = new List<String>();
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<Integer, Payment__c> paymentsToInsertMap = new Map<Integer, Payment__c>();
            Map<Integer, List<PaymentDetail__c>> paymentDetailsToInsertMap = new Map<Integer, List<PaymentDetail__c>>();
            if (invoiceCreditNoteIds != null && !invoiceCreditNoteIds.isEmpty()) {
                Map<Id, Invoice__c> invoicesCanceledMap = new Map<Id, Invoice__c>();
                List<InvoiceLink__c> invoiceLinkedList = [SELECT Invoice__c, InvoiceLinked__c, InvoiceLinked__r.BusinessUnitSeller__c, InvoiceLinked__r.SupplierBuyer__c
                                                          FROM InvoiceLink__c
                                                          WHERE Invoice__c IN :invoiceCreditNoteIds];
                for(InvoiceLink__c item : invoiceLinkedList) {
                    invoicesCanceledMap.put(item.Invoice__c, item.InvoiceLinked__r);
                }
                // get Invoice__c and InvoiceDetail__c
                List<Invoice__c> invoicesList = [SELECT Id, ExchangeRate__c, CurrencyIsoCode, BusinessUnitSeller__c, SupplierBuyer__c, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c,
                                                 (SELECT Id, CurrencyIsoCode, DetailAmountwVAT__c, DetailVATAmount__c, RestToPaidAmountwVAT__c, RestToPaidVATAmount__c, InvoiceDetailLinked__c
                                                  FROM INVDInvoice__r)
                                                 FROM Invoice__c
                                                 WHERE Id IN :invoicesCanceledMap.keySet()];
                List<PaymentDetail__c> paymentDetailsToInsert = new List<PaymentDetail__c>();
                if(!invoicesList.isEmpty()) {
                    Integer index = 0;
                    for(Invoice__c item : invoicesList) {
                        // 1. Payment creation relative to the CreditNote record created
                        Payment__c newPayment = new Payment__c(EffectiveDate__c = Date.today(),
                                                               PaymentDate__c   = Date.today(),
                                                               PaymentType__c = 'Lettering',
                                                               Status__c = 'New',
                                                               ExchangeRate__c = item.ExchangeRate__c,
                                                               isOverdue__c = false,
                                                               CurrencyIsoCode = item.CurrencyIsoCode,
                                                               BusinessUnitSeller__c = item.BusinessUnitSeller__c,
                                                               SupplierBuyer__c = item.SupplierBuyer__c,
                                                               AmountwVAT__c = item.RestToPaidAmountwVAT__c,
                                                               VATAmount__c = item.RestToPaidVATAmount__c);
                        if (!item.INVDInvoice__r.isEmpty()) {
                            paymentDetailsToInsert = new List<PaymentDetail__c>();
                            for(InvoiceDetail__c invoiceDetail : item.INVDInvoice__r) {
                                PaymentDetail__c newPaymentDetail = new PaymentDetail__c(LetteringType__c = 'PaidInvoiceLettering',
                                                                                         Status__c = 'New',
                                                                                         CurrencyIsoCode = invoiceDetail.CurrencyIsoCode,
                                                                                         InvoiceDetail__c = invoiceDetail.Id,
                                                                                         AmountwVAT__c = invoiceDetail.RestToPaidAmountwVAT__c,
                                                                                         VATAmount__c = invoiceDetail.RestToPaidVATAmount__c);
                                paymentDetailsToInsert.add(newPaymentDetail);
                            }
                            paymentDetailsToInsertMap.put(index, paymentDetailsToInsert);
                        }
                        // check new PaymentDetail__c
                        if(paymentDetailsToInsertMap.containsKey(index) && !paymentDetailsToInsertMap.get(index).isEmpty()) {
                            paymentsToInsertMap.put(index, newPayment);
                            index++;
                        } else continue;
                        // 2. Payment creation relative to the ListOfDataToCancel.InvoiceID record
                        Invoice__c canceledInvoice = invoicesCanceledMap.get(item.Id);
                        newPayment = new Payment__c(EffectiveDate__c = Date.today(),
                                                    PaymentDate__c = Date.today(),
                                                    PaymentType__c = 'Lettering',
                                                    Status__c = 'New',
                                                    ExchangeRate__c = item.ExchangeRate__c,
                                                    isOverdue__c = false,
                                                    CurrencyIsoCode = item.CurrencyIsoCode,
                                                    BusinessUnitSeller__c = canceledInvoice.BusinessUnitSeller__c,
                                                    SupplierBuyer__c = canceledInvoice.SupplierBuyer__c,
                                                    AmountwVAT__c = item.RestToPaidAmountwVAT__c != null ? Math.abs(item.RestToPaidAmountwVAT__c) : null,
                                                    VATAmount__c = item.RestToPaidVATAmount__c != null ? Math.abs(item.RestToPaidVATAmount__c) : null,
                                                    InvoiceDocLinked__c = item.Id);
                        if (!item.INVDInvoice__r.isEmpty()) {
                            paymentDetailsToInsert = new List<PaymentDetail__c>();
                            for(InvoiceDetail__c invoiceDetail : item.INVDInvoice__r) {
                                PaymentDetail__c newPaymentDetail = new PaymentDetail__c(LetteringType__c = 'PaidInvoiceLettering',
                                                                                         Status__c = 'New',
                                                                                         CurrencyIsoCode = invoiceDetail.CurrencyIsoCode,
                                                                                         InvoiceDetail__c = invoiceDetail.InvoiceDetailLinked__c,
                                                                                         AmountwVAT__c = (invoiceDetail.RestToPaidAmountwVAT__c != null ? Math.abs(invoiceDetail.RestToPaidAmountwVAT__c) : null),
                                                                                         VATAmount__c = (invoiceDetail.RestToPaidVATAmount__c != null ? Math.abs(invoiceDetail.RestToPaidVATAmount__c) : null));
                                paymentDetailsToInsert.add(newPaymentDetail);
                            }
                            paymentDetailsToInsertMap.put(index, paymentDetailsToInsert);
                        }
                        if(paymentDetailsToInsertMap.containsKey(index) && !paymentDetailsToInsertMap.get(index).isEmpty()) {
                            paymentsToInsertMap.put(index, newPayment);
                            index++;
                        }
                    }
                }
                if (!paymentsToInsertMap.isEmpty()) {
                    List<Database.SaveResult> results = Database.insert(paymentsToInsertMap.values(), false);
                    paymentDetailsToInsert = new List<PaymentDetail__c>();
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Payment__c newPayment = paymentsToInsertMap.get(i);
                        if (result.isSuccess()) {
                            if (!paymentDetailsToInsertMap.isEmpty() && paymentDetailsToInsertMap.containskey(i)) {
                                for (PaymentDetail__c item : paymentDetailsToInsertMap.get(i)) {
                                    item.Payment__c = newPayment.Id;
                                    paymentDetailsToInsert.add(item);
                                }
                            }
                        } else {
                            String errorMessage = newPayment + '\n';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            errorMessages.add(errorMessage);
                            System.debug('ERROR >>>' + errorMessage);
                        }
                    }
                    if (!paymentDetailsToInsert.isEmpty()) {
                        results = Database.insert(paymentDetailsToInsert, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.SaveResult result = results.get(i);
                            PaymentDetail__c newPaymentDetail = paymentDetailsToInsert.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = newPaymentDetail + '\n';
                                Database.Error[] errs = result.getErrors();
                                for (Database.Error err : errs) {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                                errorMessages.add(errorMessage);
                                System.debug('ERROR >>>' + errorMessage);
                            }
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        return errorMessages;
    }

    /**
     * @description clone invoices
     */
    public static InvoicesToCloneWrapper cloneInvoices(List<Invoice__c> invoicesListToCloned) {
        InvoicesToCloneWrapper invoicesToCloneWrapper = new InvoicesToCloneWrapper();
        System.SavePoint sp = Database.setSavepoint();
        try {
            Map<Integer, Invoice__c> invoicesToInsertMap = new Map<Integer, Invoice__c>();
            Map<Integer, Invoice__c> invoicesToCloneMap = new Map<Integer, Invoice__c>();
            Map<Integer, List<InvoiceDetail__c>> invoiceDetailsToInsertMap = new Map<Integer, List<InvoiceDetail__c>>();
            Integer index = 0;
            if(!invoicesListToCloned.isEmpty()) {
                for (Invoice__c item : invoicesListToCloned) {
                    // create Invoice__c
                    Invoice__c newInvoice = item.clone(false);
                    newInvoice.Status__c = 'Generated';
                    newInvoice.PrintDate__c = null;
                    newInvoice.InvNumber__c = null;
                    newInvoice.PaidVATAmount__c = null;
                    newInvoice.PaidAmountwVAT__c = null;
                    newInvoice.ExtId__c = null;
                    newInvoice.ExtractLDate__c = null;
                    newInvoice.ExtractLId__c = null;
                    newInvoice.ExtractLStatus__c = null;
                    newInvoice.t_HiddenForSearch__c = null;
                    newInvoice.IntegLId__c = null;
                    newInvoice.IntegLDate__c = null;
                    newInvoice.SupportBy__c = null;
                    newInvoice.SupportLDate__c = null;
                    newInvoice.SupportNote__c = null;
                    newInvoice.t_Autonum__c = null;
                    newInvoice.InvNumberPrefix__c = null;
                    // create InvoiceDetail__c
                    if (item.INVDInvoice__r != null && !item.INVDInvoice__r.isEmpty()) {
                        List<InvoiceDetail__c> invoiceDetailsToInsert = new List<InvoiceDetail__c>();
                        for (InvoiceDetail__c invoiceDetail : item.INVDInvoice__r) {
                            InvoiceDetail__c newInvoiceDetail = invoiceDetail.clone(false);
                            newInvoiceDetail.PaidVATAmount__c = 0;
                            newInvoiceDetail.PaidAmountwVAT__c = 0;
                            newInvoiceDetail.IntegLDate__c = null;
                            newInvoiceDetail.SupportBy__c = null;
                            newInvoiceDetail.SupportLDate__c = null;
                            newInvoiceDetail.ExtId__c = null;
                            newInvoiceDetail.ExtractLDate__c = null;
                            newInvoiceDetail.ExtractLId__c = null;
                            invoiceDetailsToInsert.add(newInvoiceDetail);
                        }
                        invoiceDetailsToInsertMap.put(index, invoiceDetailsToInsert);
                    }
                    invoicesToCloneMap.put(index, item);
                    invoicesToInsertMap.put(index, newInvoice);
                    index++;
                }
            }
            // create Invoice__c
            if (!invoicesToInsertMap.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(invoicesToInsertMap.values(), false);
                List<InvoiceDetail__c> invoiceDetailsToInsert = new List<InvoiceDetail__c>();
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Invoice__c newInvoice = invoicesToInsertMap.get(i);
                    Invoice__c invoiceToClone = invoicesToCloneMap.get(i);
                    if (result.isSuccess()) {
                        invoicesToCloneWrapper.invoicesToCloneMap.put(invoiceToClone.Id, newInvoice.Id);
                        if (!invoiceDetailsToInsertMap.isEmpty() && invoiceDetailsToInsertMap.containskey(i)) {
                            for (InvoiceDetail__c item : invoiceDetailsToInsertMap.get(i)) {
                                item.Invoice__c = newInvoice.Id;
                                invoiceDetailsToInsert.add(item);
                            }
                        }
                    } else {
                        String errorMessage = newInvoice + '\n';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) {
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        invoicesToCloneWrapper.errorMessages.add(errorMessage);
                        System.debug('ERROR >>>' + errorMessage);
                    }
                }
                // create InvoiceDetail__c
                if (!invoiceDetailsToInsert.isEmpty()) {
                    results = Database.insert(invoiceDetailsToInsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        InvoiceDetail__c newInvoiceDetail = invoiceDetailsToInsert.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = newInvoiceDetail + '\n';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs) {
                                errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            invoicesToCloneWrapper.errorMessages.add(errorMessage);
                            System.debug('ERROR >>>' + errorMessage);
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            invoicesToCloneWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            invoicesToCloneWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        return invoicesToCloneWrapper;
    }

    public static InvoiceToDeleteResultWrapper deleteInvoices(List<Invoice__c> invoices) {
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        InvoiceToDeleteResultWrapper invoiceToDeleteResultWrapper = new InvoiceToDeleteResultWrapper();
        for (Invoice__c invoice : invoices) {
            invoice.Status__c = 'Deleted';
            invoicesToUpdate.add(invoice);
        }
        if (!invoicesToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(invoicesToUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                Invoice__c invoice = invoicesToUpdate.get(i);
                invoiceToDeleteResultWrapper.invoiceToDelete.add(invoice);
                if (!result.isSuccess()) {
                    String errorMessage = '';
                    Database.Error[] errs = result.getErrors();
                    for (Database.Error err : errs) {
                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                    }
                    invoiceToDeleteResultWrapper.errorMessages.put(invoice.Id, errorMessage);
                    System.debug('ERROR >>>' + errorMessage);
                }
            }
        }
        return invoiceToDeleteResultWrapper;
    }

    public static void updateDeletedRelatedRecords(Set<Id> invoiceIds) {
        if (!invoiceIds.isEmpty()) {
            List<InvoiceLink__c> invoiceLinksToUpdate = new List<InvoiceLink__c>();
            List<InvoiceLink__c> invoiceLinks = [SELECT Id, Status__c, Invoice__r.Status__c, InvoiceLinked__r.Status__c
                                                 FROM InvoiceLink__c
                                                 WHERE Invoice__c IN :invoiceIds
                                                 OR InvoiceLinked__c IN :invoiceIds];
            for (InvoiceLink__c item : invoiceLinks) {
                Boolean isDeleteRelatedRecords = item.Invoice__r.Status__c == 'Deleted' || item.InvoiceLinked__r.Status__c == 'Deleted';
                String newStatus = isDeleteRelatedRecords ? 'Deleted' : 'Open';
                if (item.Status__c != newStatus) {
                    item.Status__c = newStatus;
                    invoiceLinksToUpdate.add(item);
                }
            }
            if (!invoiceLinksToUpdate.isEmpty()) {
                Database.update(invoiceLinksToUpdate, false);
            }
        }
    }
/**
     * Update CommercialPlan__c/CommercialPlanDetail__c related to Deleted/Canceled Invoice__c
     */
    public static void updateCommercialPlanRelatedRecords(List<InvoiceDetail__c> invoiceDetails) {
        if (invoiceDetails != null && !invoiceDetails.isEmpty()) {
            Set<Id> commercialPlanIdSet = new Set<Id>();
            for (InvoiceDetail__c item : invoiceDetails) {
                if(item.CommercialPlan__c != null) {
                    commercialPlanIdSet.add(item.CommercialPlan__c);
                }
            }
            if (!commercialPlanIdSet.isEmpty()) {
                Map<Id, CommercialPlan__c> commercialPlansToUpdateMap = new Map<Id, CommercialPlan__c>();
                Map<Id, CommercialPlanDetail__c> commercialPlanDetailsToUpdateMap = new Map<Id, CommercialPlanDetail__c>();
                Set<Id> commercialPlanSellInIdSet = new Set<Id>();
                Set<Id> commercialPlanServicesIdSet = new Set<Id>();
                Set<Id> commercialPlanSellOutIdSet = new Set<Id>();
                Map<Id, CommercialPlan__c> commercialPlansMap = new Map<Id, CommercialPlan__c>([SELECT Id, PromoAgreementType__c, Pol_Com_Condition__r.Vat_Type__c,
                                                                                                SellInDiscountMassValueInvoice__c, ServicesDiscountMassValueInvoice__c, SellOutDiscMassValueContribInvoice__c
                                                                                                FROM CommercialPlan__c WHERE Id IN :commercialPlanIdSet]);
                for (CommercialPlan__c item : commercialPlansMap.values()) {
                    if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') { // SellIn
                        commercialPlanSellInIdSet.add(item.Id);
                    } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                        commercialPlanServicesIdSet.add(item.Id);
                    } else if (item.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                        commercialPlanSellOutIdSet.add(item.Id);
                    }
                }
                Map<Id, List<CommercialPlanDetail__c>> commercialPlanDetailsMap = new Map<Id, List<CommercialPlanDetail__c>>();
                Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>> commercialPlanDetailsByVATRatesMap = new Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>>();
                if(!commercialPlanSellInIdSet.isEmpty() || !commercialPlanServicesIdSet.isEmpty() || !commercialPlanSellOutIdSet.isEmpty()) {
                    String CPDQuery = 'SELECT Id, CommercialPlanSellIn__c, CommercialPlanSellOut__c, CommercialPlanServices__c, Product__r.VATRate__c,';
                    CPDQuery += ' SellInDiscountMassValueInvoice__c, ServicesDiscountMassValueInvoice__c, SellOutDiscMassValueContribInvoice__c';
                    CPDQuery += ' FROM CommercialPlanDetail__c WHERE Product__c <> NULL';
                    String CPDSellInQuery = CPDQuery;
                    if(!commercialPlanSellInIdSet.isEmpty()) {
                        CPDSellInQuery += ' AND (CommercialPlanSellIn__c IN (\'' + String.join(commercialPlanSellInIdSet, '\', \'') + '\') AND SellInDiscountMassValueInvoice__c NOT IN (0, NULL))';
                        CPDSellInQuery += ' ORDER BY SellInDiscountMassValueInvoice__c DESC';
                        System.debug('CPDSellInQuery >>> ' + CPDSellInQuery);
                        List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDSellInQuery);
                        for(CommercialPlanDetail__c item : commercialPlanDetails) {
                            if(item.Product__r.VATRate__c != null) {
                                Decimal vatRate = item.Product__r.VATRate__c;
                                if(item.CommercialPlanSellIn__c != null && commercialPlanSellInIdSet.contains(item.CommercialPlanSellIn__c)) {
                                    if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellIn__c))
                                        commercialPlanDetailsMap.put(item.CommercialPlanSellIn__c, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsMap.get(item.CommercialPlanSellIn__c).add(item);
                                    if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanSellIn__c))
                                        commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanSellIn__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                    if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).containsKey(vatRate))
                                        commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).get(vatRate).add(item);
                                }
                            }
                        }
                    }
                    String CPDSellOutQuery = CPDQuery;
                    if(!commercialPlanSellOutIdSet.isEmpty()) {
                        CPDSellOutQuery += ' AND (CommercialPlanSellOut__c IN (\'' + String.join(commercialPlanSellOutIdSet, '\', \'') + '\') AND SellOutDiscMassValueContribInvoice__c NOT IN (0, NULL))';
                        CPDSellOutQuery += ' ORDER BY SellOutDiscMassValueContribInvoice__c DESC';
                        System.debug('CPDSellOutQuery >>> ' + CPDSellOutQuery);
                        List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDSellOutQuery);
                        for(CommercialPlanDetail__c item : commercialPlanDetails) {
                            if(item.Product__r.VATRate__c != null) {
                                Decimal vatRate = item.Product__r.VATRate__c;
                                if(item.CommercialPlanSellOut__c != null && commercialPlanSellOutIdSet.contains(item.CommercialPlanSellOut__c)) {
                                    if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellOut__c))
                                        commercialPlanDetailsMap.put(item.CommercialPlanSellOut__c, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsMap.get(item.CommercialPlanSellOut__c).add(item);
                                    if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanSellOut__c))
                                        commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanSellOut__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                    if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).containsKey(vatRate))
                                        commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).get(vatRate).add(item);
                                }
                            }
                        }
                    }
                    String CPDServicesQuery = CPDQuery;
                    if(!commercialPlanServicesIdSet.isEmpty()) {
                        CPDServicesQuery += ' AND (CommercialPlanServices__c IN (\'' + String.join(commercialPlanServicesIdSet, '\', \'') + '\') AND ServicesDiscountMassValueInvoice__c NOT IN (0, NULL))';
                        CPDServicesQuery += ' ORDER BY ServicesDiscountMassValueInvoice__c DESC';
                        System.debug('CPDServicesQuery >>> ' + CPDServicesQuery);
                        List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDServicesQuery);
                        for(CommercialPlanDetail__c item : commercialPlanDetails) {
                            if(item.Product__r.VATRate__c != null) {
                                Decimal vatRate = item.Product__r.VATRate__c;
                                if(item.CommercialPlanServices__c != null && commercialPlanServicesIdSet.contains(item.CommercialPlanServices__c)) {
                                    if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanServices__c))
                                        commercialPlanDetailsMap.put(item.CommercialPlanServices__c, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsMap.get(item.CommercialPlanServices__c).add(item);
                                    if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanServices__c))
                                        commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanServices__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                    if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).containsKey(vatRate))
                                        commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).get(vatRate).add(item);
                                }
                            }
                        }
                    }
                }
                for (InvoiceDetail__c item : invoiceDetails) {
                    Decimal amount = (item.DetailAmount__c != null ? item.DetailAmount__c : 0);
                    Decimal vatRate = item.DetailVATRate__c;
                    if(item.CommercialPlan__c != null) {
                        CommercialPlan__c commercialPlan = commercialPlansMap.get(item.CommercialPlan__c);
                        // update CommercialPlan__c
                        if(commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellIn') { // SellIn
                            if(commercialPlan.SellInDiscountMassValueInvoice__c != null && commercialPlan.SellInDiscountMassValueInvoice__c >= amount ) {
                                commercialPlan.SellInDiscountMassValueInvoice__c -= amount;
                            }
                        } else if (commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                            if(commercialPlan.ServicesDiscountMassValueInvoice__c != null && commercialPlan.ServicesDiscountMassValueInvoice__c >= amount ) {
                                commercialPlan.ServicesDiscountMassValueInvoice__c -= amount;
                            }
                        } else if (commercialPlan.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                            if(commercialPlan.SellOutDiscMassValueContribInvoice__c != null && commercialPlan.SellOutDiscMassValueContribInvoice__c >= amount ) {
                                commercialPlan.SellOutDiscMassValueContribInvoice__c -= amount;
                            }
                        }
                        commercialPlansToUpdateMap.put(commercialPlan.Id, commercialPlan);
                        Boolean isClassicVAT = commercialPlan.Pol_Com_Condition__r.VAT_Type__c != 'Product';
                        List<CommercialPlanDetail__c> commercialPlanDetails = new List<CommercialPlanDetail__c>();
                        if(isClassicVAT) {
                            // update CommercialPlanDetail__c
                            if(commercialPlanDetailsMap.containsKey(commercialPlan.Id)) {
                                commercialPlanDetails = commercialPlanDetailsMap.get(commercialPlan.Id);
                            }
                        } else {
                           if(commercialPlanDetailsByVATRatesMap.containsKey(commercialPlan.Id) && commercialPlanDetailsByVATRatesMap.get(commercialPlan.Id).containsKey(vatRate)) {
                               commercialPlanDetails = commercialPlanDetailsByVATRatesMap.get(commercialPlan.Id).get(vatRate);
                           }
                        }
                        if(!commercialPlanDetails.isEmpty()) {
                            for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) {
                                if(amount == 0) break;
                                if(commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellIn') {
                                    Decimal initialValue = commercialPlanDetail.SellInDiscountMassValueInvoice__c;
                                    if(commercialPlanDetail.SellInDiscountMassValueInvoice__c <= amount) {
                                        commercialPlanDetail.SellInDiscountMassValueInvoice__c = 0;
                                        amount -= initialValue;
                                    } else {
                                        commercialPlanDetail.SellInDiscountMassValueInvoice__c -= amount;
                                        amount = 0;
                                    }
                                } else if (commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellOut') {
                                    Decimal initialValue = commercialPlanDetail.ServicesDiscountMassValueInvoice__c;
                                    if(commercialPlanDetail.ServicesDiscountMassValueInvoice__c <= amount) {
                                        commercialPlanDetail.ServicesDiscountMassValueInvoice__c = 0;
                                        amount -= initialValue;
                                    } else {
                                        commercialPlanDetail.ServicesDiscountMassValueInvoice__c -= amount;
                                        amount = 0;
                                    }
                                } else if (commercialPlan.PromoAgreementType__c == 'AgencyAgreement') {
                                    Decimal initialValue = commercialPlanDetail.SellOutDiscMassValueContribInvoice__c;
                                    if(commercialPlanDetail.SellOutDiscMassValueContribInvoice__c <= amount) {
                                        commercialPlanDetail.SellOutDiscMassValueContribInvoice__c = 0;
                                        amount -= initialValue;
                                    } else {
                                        commercialPlanDetail.SellOutDiscMassValueContribInvoice__c -= amount;
                                        amount = 0;
                                    }
                                }
                                commercialPlanDetailsToUpdateMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                            }
                        }
                    }
                }
                if (!commercialPlansToUpdateMap.isEmpty()) {
                    Database.update(commercialPlansToUpdateMap.values(), false);
                }
                if (!commercialPlanDetailsToUpdateMap.isEmpty()) {
                    Database.update(commercialPlanDetailsToUpdateMap.values(), false);
                }
            }
        }
    }

    public static void recalculateCommercialPlanInvoices(Set<Id> commercialPlanIdSet) {
        if (commercialPlanIdSet != null && !commercialPlanIdSet.isEmpty()) {
            Map<Id, Decimal> commercialPlanInvoicesMap = new Map<Id, Decimal>();
            Map<Id, Map<Decimal, Decimal>> commercialPlanInvoicesByVATRatesMap = new Map<Id, Map<Decimal, Decimal>>();
            List<InvoiceDetail__c> invoiceDetails = [SELECT Id, Invoice__c, DetailAmount__c, DetailVATRate__c, Invoice__r.Status__c, CommercialPlan__c
                                                     FROM InvoiceDetail__c
                                                     WHERE CommercialPlan__c IN :commercialPlanIdSet
                                                     AND Invoice__r.Status__c NOT IN ('Deleted', 'Cancelled')
                                                     AND DetailAmount__c NOT IN (NULL, 0)];
            Map<Id, List<InvoiceDetail__c>> invoicesDetailsForCPMap = new Map<Id, List<InvoiceDetail__c>>();
            Map<Id, Map<Decimal, List<InvoiceDetail__c>>> invoicesDetailsByVATRatesForCPMap = new Map<Id, Map<Decimal, List<InvoiceDetail__c>>>();
            for(InvoiceDetail__c item : invoiceDetails) {
                Decimal amount = (item.DetailAmount__c != null ? item.DetailAmount__c : 0);
                Decimal vatRate = item.DetailVATRate__c;
                if(!commercialPlanInvoicesMap.containsKey(item.CommercialPlan__c)) commercialPlanInvoicesMap.put(item.CommercialPlan__c, 0);
                Decimal oldAmount = commercialPlanInvoicesMap.get(item.CommercialPlan__c);
                commercialPlanInvoicesMap.put(item.CommercialPlan__c, oldAmount + amount);

                if(!commercialPlanInvoicesByVATRatesMap.containsKey(item.CommercialPlan__c)) commercialPlanInvoicesByVATRatesMap.put(item.CommercialPlan__c, new Map<Decimal, Decimal>());
                if(!commercialPlanInvoicesByVATRatesMap.get(item.CommercialPlan__c).containsKey(vatRate)) commercialPlanInvoicesByVATRatesMap.get(item.CommercialPlan__c).put(vatRate, 0);
                oldAmount = commercialPlanInvoicesByVATRatesMap.get(item.CommercialPlan__c).get(vatRate);
                commercialPlanInvoicesByVATRatesMap.get(item.CommercialPlan__c).put(vatRate, oldAmount + amount);

                if(!invoicesDetailsForCPMap.containsKey(item.CommercialPlan__c)) invoicesDetailsForCPMap.put(item.CommercialPlan__c, new List<InvoiceDetail__c>());
                invoicesDetailsForCPMap.get(item.CommercialPlan__c).add(item);

                if(!invoicesDetailsByVATRatesForCPMap.containsKey(item.CommercialPlan__c))
                    invoicesDetailsByVATRatesForCPMap.put(item.CommercialPlan__c, new Map<Decimal, List<InvoiceDetail__c>>());
                if(!invoicesDetailsByVATRatesForCPMap.get(item.CommercialPlan__c).containsKey(vatRate))
                    invoicesDetailsByVATRatesForCPMap.get(item.CommercialPlan__c).put(vatRate, new List<InvoiceDetail__c>());
                invoicesDetailsByVATRatesForCPMap.get(item.CommercialPlan__c).get(vatRate).add(item);
            }

            Map<Id, CommercialPlan__c> commercialPlansToUpdateMap = new Map<Id, CommercialPlan__c>();
            Map<Id, CommercialPlanDetail__c> commercialPlanDetailsToUpdateMap = new Map<Id, CommercialPlanDetail__c>();
            Set<Id> commercialPlanSellInIdSet = new Set<Id>();
            Set<Id> commercialPlanServicesIdSet = new Set<Id>();
            Set<Id> commercialPlanSellOutIdSet = new Set<Id>();
            Map<Id, CommercialPlan__c> commercialPlansMap = new Map<Id, CommercialPlan__c>([SELECT Id, PromoAgreementType__c, Pol_Com_Condition__r.Vat_Type__c,
                                                                                            SellInDiscountMassValueInvoice__c, ServicesDiscountMassValueInvoice__c, SellOutDiscMassValueContribInvoice__c
                                                                                            FROM CommercialPlan__c WHERE Id IN :commercialPlanIdSet]);
            for (CommercialPlan__c item : commercialPlansMap.values()) {
                Decimal invoiceValue;
                if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') { // SellIn
                    invoiceValue = (item.SellInDiscountMassValueInvoice__c != null ? item.SellInDiscountMassValueInvoice__c : 0);
                } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                    invoiceValue = item.ServicesDiscountMassValueInvoice__c;
                } else if (item.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                    invoiceValue = item.SellOutDiscMassValueContribInvoice__c;
                }
                if(commercialPlanInvoicesMap.containsKey(item.Id) && commercialPlanInvoicesMap.get(item.Id) == invoiceValue) {
                    continue;
                }
                if(item.PromoAgreementType__c == 'CallOffAgreementSellIn') { // SellIn
                    commercialPlanSellInIdSet.add(item.Id);
                } else if (item.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                    commercialPlanServicesIdSet.add(item.Id);
                } else if (item.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                    commercialPlanSellOutIdSet.add(item.Id);
                }
            }
            Map<Id, List<CommercialPlanDetail__c>> commercialPlanDetailsMap = new Map<Id, List<CommercialPlanDetail__c>>();
            Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>> commercialPlanDetailsByVATRatesMap = new Map<Id, Map<Decimal, List<CommercialPlanDetail__c>>>();
            if(!commercialPlanSellInIdSet.isEmpty() || !commercialPlanServicesIdSet.isEmpty() || !commercialPlanSellOutIdSet.isEmpty()) {
                String CPDQuery = 'SELECT Id, CommercialPlanSellIn__c, CommercialPlanSellOut__c, CommercialPlanServices__c, Product__r.VATRate__c,';
                CPDQuery += ' SellInDiscountMassValueInvoice__c, ServicesDiscountMassValueInvoice__c, SellOutDiscMassValueContribInvoice__c';
                CPDQuery += ' FROM CommercialPlanDetail__c WHERE Product__c <> NULL';
                String CPDSellInQuery = CPDQuery;
                if(!commercialPlanSellInIdSet.isEmpty()) {
                    CPDSellInQuery += ' AND (CommercialPlanSellIn__c IN (\'' + String.join(commercialPlanSellInIdSet, '\', \'') + '\') AND SellInDiscountMassValueInvoice__c NOT IN (0, NULL))';
                    CPDSellInQuery += ' ORDER BY SellInDiscountMassValueInvoice__c DESC';
                    System.debug('CPDSellInQuery >>> ' + CPDSellInQuery);
                    List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDSellInQuery);
                    for(CommercialPlanDetail__c item : commercialPlanDetails) {
                        if(item.Product__r.VATRate__c != null) {
                            Decimal vatRate = item.Product__r.VATRate__c;
                            if(item.CommercialPlanSellIn__c != null && commercialPlanSellInIdSet.contains(item.CommercialPlanSellIn__c)) {
                                if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellIn__c))
                                    commercialPlanDetailsMap.put(item.CommercialPlanSellIn__c, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsMap.get(item.CommercialPlanSellIn__c).add(item);
                                if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanSellIn__c))
                                    commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanSellIn__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).containsKey(vatRate))
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellIn__c).get(vatRate).add(item);
                            }
                        }
                    }
                }
                String CPDSellOutQuery = CPDQuery;
                if(!commercialPlanSellOutIdSet.isEmpty()) {
                    CPDSellOutQuery += ' AND (CommercialPlanSellOut__c IN (\'' + String.join(commercialPlanSellOutIdSet, '\', \'') + '\') AND SellOutDiscMassValueContribInvoice__c NOT IN (0, NULL))';
                    CPDSellOutQuery += ' ORDER BY SellOutDiscMassValueContribInvoice__c DESC';
                    System.debug('CPDSellOutQuery >>> ' + CPDSellOutQuery);
                    List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDSellOutQuery);
                    for(CommercialPlanDetail__c item : commercialPlanDetails) {
                        if(item.Product__r.VATRate__c != null) {
                            Decimal vatRate = item.Product__r.VATRate__c;
                            if(item.CommercialPlanSellOut__c != null && commercialPlanSellOutIdSet.contains(item.CommercialPlanSellOut__c)) {
                                if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanSellOut__c))
                                    commercialPlanDetailsMap.put(item.CommercialPlanSellOut__c, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsMap.get(item.CommercialPlanSellOut__c).add(item);
                                if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanSellOut__c))
                                    commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanSellOut__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).containsKey(vatRate))
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanSellOut__c).get(vatRate).add(item);
                            }
                        }
                    }
                }
                String CPDServicesQuery = CPDQuery;
                if(!commercialPlanServicesIdSet.isEmpty()) {
                    CPDServicesQuery += ' AND (CommercialPlanServices__c IN (\'' + String.join(commercialPlanServicesIdSet, '\', \'') + '\') AND ServicesDiscountMassValueInvoice__c NOT IN (0, NULL))';
                    CPDServicesQuery += ' ORDER BY ServicesDiscountMassValueInvoice__c DESC';
                    System.debug('CPDServicesQuery >>> ' + CPDServicesQuery);
                    List<CommercialPlanDetail__c> commercialPlanDetails = Database.query(CPDServicesQuery);
                    for(CommercialPlanDetail__c item : commercialPlanDetails) {
                        if(item.Product__r.VATRate__c != null) {
                            Decimal vatRate = item.Product__r.VATRate__c;
                            if(item.CommercialPlanServices__c != null && commercialPlanServicesIdSet.contains(item.CommercialPlanServices__c)) {
                                if(!commercialPlanDetailsMap.containsKey(item.CommercialPlanServices__c))
                                    commercialPlanDetailsMap.put(item.CommercialPlanServices__c, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsMap.get(item.CommercialPlanServices__c).add(item);
                                if(!commercialPlanDetailsByVATRatesMap.containsKey(item.CommercialPlanServices__c))
                                    commercialPlanDetailsByVATRatesMap.put(item.CommercialPlanServices__c, new Map<Decimal, List<CommercialPlanDetail__c>>());
                                if(!commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).containsKey(vatRate))
                                    commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).put(vatRate, new List<CommercialPlanDetail__c>());
                                commercialPlanDetailsByVATRatesMap.get(item.CommercialPlanServices__c).get(vatRate).add(item);
                            }
                        }
                    }
                }
            }
            for (InvoiceDetail__c item : invoiceDetails) {
                Decimal amount = (item.DetailAmount__c != null ? item.DetailAmount__c : 0);
                Decimal vatRate = item.DetailVATRate__c;
                if(item.CommercialPlan__c != null) {
                    CommercialPlan__c commercialPlan = commercialPlansMap.get(item.CommercialPlan__c);
                    // update CommercialPlan__c
                    if(commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellIn') { // SellIn
                        if(commercialPlan.SellInDiscountMassValueInvoice__c != null && commercialPlan.SellInDiscountMassValueInvoice__c >= amount ) {
                            commercialPlan.SellInDiscountMassValueInvoice__c -= amount;
                        }
                    } else if (commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellOut') { // Services
                        if(commercialPlan.ServicesDiscountMassValueInvoice__c != null && commercialPlan.ServicesDiscountMassValueInvoice__c >= amount ) {
                            commercialPlan.ServicesDiscountMassValueInvoice__c -= amount;
                        }
                    } else if (commercialPlan.PromoAgreementType__c == 'AgencyAgreement') { // SellOut
                        if(commercialPlan.SellOutDiscMassValueContribInvoice__c != null && commercialPlan.SellOutDiscMassValueContribInvoice__c >= amount ) {
                            commercialPlan.SellOutDiscMassValueContribInvoice__c -= amount;
                        }
                    }
                    commercialPlansToUpdateMap.put(commercialPlan.Id, commercialPlan);
                    Boolean isClassicVAT = commercialPlan.Pol_Com_Condition__r.VAT_Type__c != 'Product';
                    List<CommercialPlanDetail__c> commercialPlanDetails = new List<CommercialPlanDetail__c>();
                    if(isClassicVAT) {
                        // update CommercialPlanDetail__c
                        if(commercialPlanDetailsMap.containsKey(commercialPlan.Id)) {
                            commercialPlanDetails = commercialPlanDetailsMap.get(commercialPlan.Id);
                        }
                    } else {
                        if(commercialPlanDetailsByVATRatesMap.containsKey(commercialPlan.Id) && commercialPlanDetailsByVATRatesMap.get(commercialPlan.Id).containsKey(vatRate)) {
                            commercialPlanDetails = commercialPlanDetailsByVATRatesMap.get(commercialPlan.Id).get(vatRate);
                        }
                    }
                    if(!commercialPlanDetails.isEmpty()) {
                        for (CommercialPlanDetail__c commercialPlanDetail : commercialPlanDetails) {
                            if(amount == 0) break;
                            if(commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellIn') {
                                Decimal initialValue = commercialPlanDetail.SellInDiscountMassValueInvoice__c;
                                if(commercialPlanDetail.SellInDiscountMassValueInvoice__c <= amount) {
                                    commercialPlanDetail.SellInDiscountMassValueInvoice__c = 0;
                                    amount -= initialValue;
                                } else {
                                    System.debug('amount >>> ' + amount);
                                    System.debug('initialValue >>> ' + initialValue);
                                    commercialPlanDetail.SellInDiscountMassValueInvoice__c -= amount;
                                    amount = 0;
                                }
                            } else if (commercialPlan.PromoAgreementType__c == 'CallOffAgreementSellOut') {
                                Decimal initialValue = commercialPlanDetail.ServicesDiscountMassValueInvoice__c;
                                if(commercialPlanDetail.ServicesDiscountMassValueInvoice__c <= amount) {
                                    commercialPlanDetail.ServicesDiscountMassValueInvoice__c = 0;
                                    amount -= initialValue;
                                } else {
                                    commercialPlanDetail.ServicesDiscountMassValueInvoice__c -= amount;
                                    amount = 0;
                                }
                            } else if (commercialPlan.PromoAgreementType__c == 'AgencyAgreement') {
                                Decimal initialValue = commercialPlanDetail.SellOutDiscMassValueContribInvoice__c;
                                if(commercialPlanDetail.SellOutDiscMassValueContribInvoice__c <= amount) {
                                    commercialPlanDetail.SellOutDiscMassValueContribInvoice__c = 0;
                                    amount -= initialValue;
                                } else {
                                    commercialPlanDetail.SellOutDiscMassValueContribInvoice__c -= amount;
                                    amount = 0;
                                }
                            }
                            commercialPlanDetailsToUpdateMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                        }
                    }
                }
            }
            if (!commercialPlansToUpdateMap.isEmpty()) {
                Database.update(commercialPlansToUpdateMap.values(), false);
            }
            if (!commercialPlanDetailsToUpdateMap.isEmpty()) {
                Database.update(commercialPlanDetailsToUpdateMap.values(), false);
            }
        }
    }

    /**
     * @description populate Invoice__c.BuyerContact(i)__c/Invoice__c.BuyerEmail(i)__c
     */
    public static List<Invoice__c> fillContacts(List<Invoice__c> invoices) {
        Integer NB_BUYER_CONTACTS = 5;
        List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
        Map<Id, List<Invoice__c>> invoiceBySupplierMap = new Map<Id, List<Invoice__c>>();
        Map<String, List<Invoice__c>> invoiceByScopeMap = new Map<String, List<Invoice__c>>();
        Map<Id, Id> nsByContractMap = new Map<Id, Id>();
        for (Invoice__c item : invoices) {
            if (item.SupplierBuyer__c != null) {
                if (!invoiceBySupplierMap.containsKey(item.SupplierBuyer__c)) invoiceBySupplierMap.put(item.SupplierBuyer__c, new List<Invoice__c>());
                invoiceBySupplierMap.get(item.SupplierBuyer__c).add(item);
                if (item.Contract__c != null) {
                    nsByContractMap.put(item.Contract__c, null);
                }
                for (Integer i = 1; i <= NB_BUYER_CONTACTS; i++) {
                    item.put('BuyerContact' + i + '__c', null);
                    item.put('BuyerEmail' + i + '__c', null);
                }
                invoicesToUpdate.add(item);
            }
        }
        if (!nsByContractMap.isEmpty()) {
            for (Contract__c item : [SELECT Id, Supplier__c, Supplier_Nego_Scope__c
                                     FROM Contract__c
                                     WHERE Id IN :nsByContractMap.keySet()])
            {
                nsByContractMap.put(item.Id, item.Supplier_Nego_Scope__c);
            }
        }
        if (!invoiceBySupplierMap.isEmpty()) {
            Map<Id, List<Contact>> supplierContactsMap = new Map<Id, List<Contact>>();
            for (Contact item : [SELECT Id, Email, Supplier__c
                                 FROM Contact
                                 WHERE Type__c = 'Generic mailbox'
                                 AND IsInvoiceRecipient__c = TRUE
                                 AND IsDeleted = FALSE
                                 AND Supplier__c IN :invoiceBySupplierMap.keySet()
                                 ORDER BY CreatedDate DESC])
            {
                if (!supplierContactsMap.containsKey(item.Supplier__c)) supplierContactsMap.put(item.Supplier__c, new List<Contact>());
                supplierContactsMap.get(item.Supplier__c).add(item);
            }
            for (Invoice__c invoice : invoicesToUpdate) {
                if (supplierContactsMap.containsKey(invoice.SupplierBuyer__c)) {
                    for (Integer i = 0; i < supplierContactsMap.get(invoice.SupplierBuyer__c).size() && i < NB_BUYER_CONTACTS; i++) {
                        Contact contact = supplierContactsMap.get(invoice.SupplierBuyer__c).get(i);
                        Integer fieldIndex = i + 1;
                        if (invoice.get('BuyerContact' + fieldIndex + '__c') == null) {
                            invoice.put('BuyerContact' + fieldIndex + '__c', contact.Id);
                            invoice.put('BuyerEmail' + fieldIndex + '__c', contact.Email);
                        }
                    }
                }
            }
            Map<Id, List<ContactOperationalDirectory__c>> supplierCODsMap = new Map<Id, List<ContactOperationalDirectory__c>>();
            for (ContactOperationalDirectory__c item : [SELECT Id,
                                                               Supplier__c,
                                                               Negoscope__c,
                                                               Contact__c,
                                                               Contact__r.Email
                                                        FROM ContactOperationalDirectory__c
                                                        WHERE Supplier__c IN :invoiceBySupplierMap.keySet()
                                                        AND Negoscope__c IN :nsByContractMap.values()
                                                        AND IsDeleted = FALSE
                                                        AND IsInvoiceRecipient__c = TRUE
                                                        AND Contact__r.Type__c = 'Individual'
                                                        AND Contact__r.IsDeleted = FALSE
                                                        ORDER BY CreatedDate DESC])
            {
                if (!supplierCODsMap.containsKey(item.Supplier__c)) supplierCODsMap.put(item.Supplier__c, new List<ContactOperationalDirectory__c>());
                supplierCODsMap.get(item.Supplier__c).add(item);
            }
            for (Invoice__c invoice : invoicesToUpdate) {
                if (supplierCODsMap.containsKey(invoice.SupplierBuyer__c)) {
                    for (ContactOperationalDirectory__c cod : supplierCODsMap.get(invoice.SupplierBuyer__c)) {
                        if (invoice.Contract__c != null && nsByContractMap.containsKey(invoice.Contract__c) && cod.Negoscope__c == nsByContractMap.get(invoice.Contract__c)) {
                            for (Integer fieldIndex = 1; fieldIndex <= NB_BUYER_CONTACTS; fieldIndex++) {
                                Boolean foundContact = false;
                                if (invoice.get('BuyerContact' + fieldIndex + '__c') == null) {
                                    invoice.put('BuyerContact' + fieldIndex + '__c', cod.Contact__c);
                                    invoice.put('BuyerEmail' + fieldIndex + '__c', cod.Contact__r.Email);
                                    foundContact = true;
                                }
                                if (foundContact) {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        return invoicesToUpdate;
    }
    /**
     * @description populate Payment__c.MatchedAmountwVAT__c / Payment__c.MatchedVATAmount__c
     */
    public static Map<Id, Payment__c> calculatePayments(Set<Id> paymentIds) {
        Map<Id, Payment__c> paymentsToUpdateMap = new Map<Id, Payment__c>();
        if(!paymentIds.isEmpty()) {
            for(Id paymentId : paymentIds) {
                Payment__c payment = new Payment__c(Id = paymentId, MatchedAmountwVAT__c = 0, MatchedVATAmount__c = 0);
                paymentsToUpdateMap.put(paymentId, payment);
            }
            for (AggregateResult result : [SELECT Payment__c Payment__c,
                                                  SUM(AmountwVAT__c) AmountwVAT__c,
                                                  SUM(VATAmount__c) VATAmount__c
                                           FROM PaymentDetail__c
                                           WHERE Payment__c IN :paymentIds
                                           AND LetteringType__c = 'PaidInvoiceLettering'
                                           AND Status__c IN ('New', 'Validated')
                                           GROUP BY Payment__c])
            {
                Id paymentId = (Id) result.get('Payment__c');
                Decimal AmountwVAT = result.get('AmountwVAT__c') != null ? (Decimal) result.get('AmountwVAT__c') : 0;
                Decimal VATAmount = result.get('VATAmount__c') != null ? (Decimal) result.get('VATAmount__c') : 0;
                Payment__c payment = paymentsToUpdateMap.get(paymentId);
                payment.MatchedAmountwVAT__c += AmountwVAT;
                payment.MatchedVATAmount__c += VATAmount;
                paymentsToUpdateMap.put(paymentId, payment);
            }
        }
        return paymentsToUpdateMap;
    }
    /**
     * @description Calculate InvoiceDetail__c.PaidAmountwVAT__c / InvoiceDetail__c.PaidVATAmount__c
     */
    public static Map<Id, InvoiceDetail__c> calculateInvoiceDetailPayments(Set<Id> invoiceDetailIds) {
        Map<Id, InvoiceDetail__c> invoiceDetailsToUpdateMap = new Map<Id, InvoiceDetail__c>();
        if(!invoiceDetailIds.isEmpty()) {
            for(Id invoiceDetailId : invoiceDetailIds) {
                InvoiceDetail__c invoiceDetail = new InvoiceDetail__c(Id = invoiceDetailId, PaidAmountwVAT__c = 0, PaidVATAmount__c = 0);
                invoiceDetailsToUpdateMap.put(invoiceDetailId, invoiceDetail);
            }
            for (AggregateResult result : [SELECT InvoiceDetail__c InvoiceDetail__c,
                                                  SUM(AmountwVAT__c) AmountwVAT__c,
                                                  SUM(VATAmount__c) VATAmount__c
                                           FROM PaymentDetail__c
                                           WHERE InvoiceDetail__c IN :invoiceDetailIds
                                           AND Status__c IN ('New', 'Validated')
                                           GROUP BY InvoiceDetail__c])
            {
                Id invoiceDetailId = (Id) result.get('InvoiceDetail__c');
                Decimal AmountwVAT = result.get('AmountwVAT__c') != null ? (Decimal) result.get('AmountwVAT__c') : 0;
                Decimal VATAmount = result.get('VATAmount__c') != null ? (Decimal) result.get('VATAmount__c') : 0;
                InvoiceDetail__c invoiceDetail = invoiceDetailsToUpdateMap.get(invoiceDetailId);
                invoiceDetail.PaidAmountwVAT__c += AmountwVAT;
                invoiceDetail.PaidVATAmount__c += VATAmount;
                invoiceDetailsToUpdateMap.put(invoiceDetailId, invoiceDetail);
            }
        }
        return invoiceDetailsToUpdateMap;
    }
    /**
     * @description Calculate  Invoice__c.PaidAmountwVAT__c / Invoice__c.PaidVATAmount__c
     */
    public static Map<Id, Invoice__c> calculateInvoicePayments(Map<Id, Invoice__c> invoicesMap) {
        invoicesMap = invoicesMap == null ? new Map<Id, Invoice__c>() : invoicesMap;
        for(Invoice__c item : invoicesMap.values()) {
            // clear all values
            item.PaidAmountwVAT__c = 0;
            item.PaidVATAmount__c = 0;
        }
        for (AggregateResult result : [SELECT Invoice__c Invoice__c,
                                              SUM(PaidAmountwVAT__c) PaidAmountwVAT__c,
                                              SUM(PaidVATAmount__c) PaidVATAmount__c
                                       FROM InvoiceDetail__c
                                       WHERE Invoice__c IN :invoicesMap.keySet()
                                       GROUP BY Invoice__c])
        {
            Id invoiceId = (Id) result.get('Invoice__c');
            Decimal PaidAmountwVAT = result.get('PaidAmountwVAT__c') != null ? (Decimal) result.get('PaidAmountwVAT__c') : 0;
            Decimal PaidVATAmount = result.get('PaidVATAmount__c') != null ? (Decimal) result.get('PaidVATAmount__c') : 0;
            Invoice__c invoice = invoicesMap.get(invoiceId);
            invoice.PaidAmountwVAT__c += PaidAmountwVAT;
            invoice.PaidVATAmount__c += PaidVATAmount;
            invoicesMap.put(invoiceId, invoice);
        }
        return invoicesMap;
    }

    /**
     * @description validate invoices
     */
    public static InvoicesToValidateWrapper validateInvoices(Set<Id> recordIds) {
        InvoicesToValidateWrapper invoicesToValidateWrapper = new InvoicesToValidateWrapper();
        System.SavePoint sp = Database.setSavepoint();
        try {
            String query = buildQueryForInvoicesValidation(recordIds);
            if(String.isBlank(query)) return null;
            List<Invoice__c> invoicesToUpdate = Database.query(query);
            if(invoicesToUpdate != null && !invoicesToUpdate.isEmpty()) {
                for (Invoice__c invoice : invoicesToUpdate) {
                    invoice.Status__c = 'Validated';
                }
                List<Database.SaveResult> results = Database.update(invoicesToUpdate, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Invoice__c invoice = invoicesToUpdate.get(i);
                    invoicesToValidateWrapper.invoiceIdsToValidate.add(invoice.Id);
                    if (!result.isSuccess()) {
                        String errorMessage = invoice + '\n';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs) {
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        invoicesToValidateWrapper.errorMessages.add(errorMessage);
                        System.debug('ERROR >>>' + errorMessage);
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            invoicesToValidateWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            System.debug('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            Database.rollback(sp);
            invoicesToValidateWrapper.errorMessages.add('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
        }
        return invoicesToValidateWrapper;
    }

    public static String buildQueryForInvoicesValidation(Set<Id> recordIds) {
        String sobjectName;
        List<String> conditions = new List<String>();
        if(recordIds != null && !recordIds.isEmpty()) {
            Id recordId = new List<Id> (recordIds).get(0);
            sobjectName = recordId.getSObjectType().getDescribe().getName();
            if (sobjectName == SObjectType.Invoice__c.Name) {
                conditions.add('Id IN (\'' + String.join(recordIds, '\', \'') + '\')');
            } else if (sobjectName == SObjectType.Contract__c.Name) {
                conditions.add('Contract__c IN (\'' + String.join(recordIds, '\', \'') + '\')');
                //conditions.add('InvDate__c <= TODAY');
            } else if (sobjectName == SObjectType.Contract_Discount__c.Name) {
                String innerQuery = 'SELECT Invoice__c FROM InvoiceDetail__c';
                innerQuery += ' WHERE DISCLineD__c IN (\'' + String.join(recordIds, '\', \'') + '\')';
                innerQuery += ' AND Invoice__r.Status__c = \'Generated\'';
                innerQuery += ' AND Invoice__r.InvDate__c <= TODAY';
                conditions.add('Id IN (' + innerQuery + ')');
                //conditions.add('InvDate__c <= TODAY');
            }
        }
        if(String.isBlank(sobjectName)) return null;
        String query = 'SELECT Id, InvNumber__c, Contract__c, Status__c, InvDate__c, TotalAmountwVAT__c FROM Invoice__c';
        conditions.add('Status__c = \'Generated\'');
        conditions.add('InvDate__c <= TODAY');
        return query + (!conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '');
    }

    public class InvoicesInfoWrapper {
        public InvoiceDetail__c invoiceDetail {get; set;}
        public InvoiceWrapper invoice {get; set;}
        public Decimal Amount {get; set;}
        public InvoicesInfoWrapper() { }
        public InvoicesInfoWrapper(InvoiceDetail__c invoiceDetail) {
            this.invoiceDetail = invoiceDetail;
            this.invoice = new InvoiceWrapper(invoiceDetail?.Invoice__r) ;
            this.Amount = this.invoiceDetail?.DetailAmount__c;
        }
    }

    public class InvoiceWrapper {
        public Invoice__c invoice {get; set;}
        public string AccDoc {get; set;}
        public Date PrintDate {get; set;}
        public string Status {get; set;}
        public Decimal Sequence {get; set;}
        public InvoiceWrapper() {}
        public InvoiceWrapper(Invoice__c invoice) {
            this.invoice = invoice;
            this.AccDoc = this.invoice?.AccDoc__c;
            this.PrintDate = this.invoice?.InvDate__c;
            this.Status = this.invoice?.Status__c;
            this.Sequence = this.invoice?.SeqNumber__c;
        }
    }

    public class ResultWrapper {
        public List<InvoicesInfoWrapper> invoiceDetails {get; set;}
        public Decimal Amount {get; set;}
        public Decimal YtdDownPayment {get; set;}
        public List<Decimal> amountValues {get;set;}
        public Contract_Discount__c condition {get;set;}
    }

    public class InvoiceToCancelWrapper {
        public Id invoiceIdToCancel {get; set;}
        public Map<Id, Decimal> invoiceDetailAmountToCancelMap {get; set;}
        public Boolean isFullCancel {get; set;}
        public Boolean isCreateSupplierCreditNote {get; set;}
        public Invoice__c newInvoiceSupplierCreditNote {get; set;}
        public InvoiceToCancelWrapper(Id invoiceIdToCancel, Map<Id, Decimal> invoiceDetailAmountToCancelMap, Boolean isFullCancel) {
            this.invoiceIdToCancel = invoiceIdToCancel;
            this.invoiceDetailAmountToCancelMap = invoiceDetailAmountToCancelMap;
            this.isFullCancel = isFullCancel;
        }
        public InvoiceToCancelWrapper(Id invoiceIdToCancel, Map<Id, Decimal> invoiceDetailAmountToCancelMap, Boolean isFullCancel, Boolean isCreateSupplierCreditNote, Invoice__c newInvoiceSupplierCreditNote) {
            this.invoiceIdToCancel = invoiceIdToCancel;
            this.invoiceDetailAmountToCancelMap = invoiceDetailAmountToCancelMap;
            this.isFullCancel = isFullCancel;
            this.isCreateSupplierCreditNote = isCreateSupplierCreditNote;
            this.newInvoiceSupplierCreditNote = newInvoiceSupplierCreditNote;
        }
    }

    public class InvoiceToCancelResultWrapper {
        public List<Invoice__c> invoicesToCancel {get; set;}
        public Map<Id, Invoice__c> invoicesToCancelMap {get; set;}
        public Map<Id, Invoice__c> invoicesSupplierCreditNoteMap {get; set;}
        public List<String> errorMessages {get; set;}
        public Map<Id, String> failedInvoices {get; set;}
        public InvoiceToCancelResultWrapper() {
            this.invoicesToCancel = new List<Invoice__c>();
            this.invoicesToCancelMap = new Map<Id, Invoice__c>();
            this.invoicesSupplierCreditNoteMap = new Map<Id, Invoice__c>();
            this.errorMessages = new List<String>();
            this.failedInvoices = new Map<Id, String>();
        }
    }

    public class InvoiceToDeleteResultWrapper {
        public List<Invoice__c> invoiceToDelete {get; set;}
        public Map<Id, String> errorMessages {get; set;}
        public InvoiceToDeleteResultWrapper() {
            this.invoiceToDelete = new List<Invoice__c>();
            this.errorMessages = new Map<Id, String>();
        }
    }

    public class InvoicesToCloneWrapper {
        public Map<Id, Id> invoicesToCloneMap {get; set;}
        public List<String> errorMessages {get; set;}
        public InvoicesToCloneWrapper() {
            this.invoicesToCloneMap = new Map<Id, Id>();
            this.errorMessages = new List<String>();
        }
    }

    public class InvoicesToValidateWrapper {
        public Set<Id> invoiceIdsToValidate {get; set;}
        public List<String> errorMessages {get; set;}
        public InvoicesToValidateWrapper() {
            this.invoiceIdsToValidate = new Set<Id>();
            this.errorMessages = new List<String>();
        }
    }

    public enum PaymentMode {
        MassDeduct,
        CreditNotePayment
    }

    public enum GenerateInvoiceMode {
        FromContractDiscount,
        CancelInvoice,
        CommercialPlan
    }
}