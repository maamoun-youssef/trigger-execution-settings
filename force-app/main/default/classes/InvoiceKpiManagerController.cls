/**
 * @author ULiT
 * @date 01-03-2025
 * @description Apex controller class to manage the invoice kpi manager
 * */
public with sharing class InvoiceKpiManagerController {
    public Map<String, String> fieldsLabel { get; set; }
    public Boolean enableInvoiceKPICategory { get; set; }
    public List<KpiWrapper> kpiTable { get; set; }
    private static Map<String, String> internalLabelsMap = new Map<String, String>();
    private List<String> defaultLabels() {
        return new List<String> {
            'LBL_KpiTable_NbOfPiece',
            'LBL_KpiTable_TotalValue',
            'LBL_KpiTable_ShowDetail',
            'LBL_KpiTable_HideDetail',
            'LBL_KpiTable_ShowCategoryGuide',
            'LBL_KpiTable_HideCategoryGuide',
            'LBL_Connect_Invoice_NoActiveKPIActions'
        };
    }
    // labels value that used on this class (Description)
    static private List<String> getInternalLabelKeys() {
        return new List<String>{
            'LBL_To',
            'LBL_FROM'
        };
    }

    InvoiceKpiManagerController(List<KpiWrapper> kpiTable, Boolean enableInvoiceKPICategory) {
        this.kpiTable = kpiTable;
        Map<String, String> tempFieldsLabel = new Map<String, String>();
        for (String label : defaultLabels()) {
            String value = NegoptimLabels.getCustomLabel(label, '');
            tempFieldsLabel.put(label, value);
        }
        this.enableInvoiceKPICategory = enableInvoiceKPICategory;
        this.fieldsLabel = tempFieldsLabel;
    }

    @AuraEnabled
    public static String initData() {
        setInternalKeys();
        InvoiceSettings invoiceSettings = InvoiceSettings.loadInvoiceSettings();
        List<KpiWrapper> kpiWrapper = buildKpiTable(invoiceSettings);
        InvoiceKpiManagerController kpiTableCtrl = new InvoiceKpiManagerController(kpiWrapper, invoiceSettings.enableInvoiceKPICategory);
        return JSON.serialize(kpiTableCtrl);
    }

    private static List<KpiWrapper> buildKpiTable(InvoiceSettings invoiceSettings) {
        Date maxPrintedDate;
        List<Invoice__c> maxInvoices = [SELECT PrintDate__c FROM Invoice__c WHERE PrintDate__c != NULL ORDER BY PrintDate__c DESC LIMIT 1];
        if (!maxInvoices.isEmpty()) {
            maxPrintedDate = maxInvoices.get(0).PrintDate__c;
        }
        list<KpiWrapper> kpiList = new list<KpiWrapper>();
        // READY TO PRINT
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_ReadyToPrint')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_ReadyToPrint')
                                  && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_ReadyToPrint')))
                                ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_ReadyToPrint').replace(',', '\', \'') +'\''
                                : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator'=>'IN',
                'invDate' => '0',
                'invOperator' => '<=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_ReadyToPrint')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_ReadyToPrint') ?? 'InvoicesToPrint';
            kpiList.add(new KpiWrapper ('LBL_KpiTable_ReadyToPrint',
                                        gridLayout,
                                        '#14b3bb',
                                        filtersMap,
                                        maxPrintedDate,
                                        '"massPrint", "singleViewDetails", "singlePreviewPdf"'));
        }
        // NEXT 5 DAYS
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_Next5Days')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_Next5Days')
                                  && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_Next5Days')))
                                 ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_Next5Days').replace(',', '\', \'') + '\''
                                 : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator' => 'IN',
                'invDate' => '+5',
                'invOperator' => '<=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_Next5Days')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_Next5Days') ?? 'InvoicesToPrint';
            kpiList.add(new KpiWrapper('LBL_KpiTable_Next5Days',
                                       gridLayout,
                                       '#8cc58a',
                                       filtersMap,
                                       maxPrintedDate,
                                       '"massPrint", "singleViewDetails", "singlePreviewPdf"'));
        }
        // LAST GEN
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_LastGen')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_LastGen')
                                  && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_LastGen')))
                                 ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_LastGen').replace(',', '\', \'') + '\''
                                 : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator' => 'IN',
                'createdDate' => '-5',
                'creDateOperateor' => '>=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_LastGen')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_LastGen') ?? 'InvoicesToPrint';
            kpiList.add(new KpiWrapper('LBL_KpiTable_LastGen',
                                       gridLayout,
                                       '#bdd25a',
                                       filtersMap,
                                       maxPrintedDate,
                                       '"massPrint", "singleDownloadPrintedPdf", "singleViewDetails"'));
        }
        // LAST PRINT
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_LastPrint')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_LastPrint')
                                  && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_LastPrint')))
                                 ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_LastPrint').replace(',', '\', \'') + '\''
                                 : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator' => 'IN',
                'printDate' => '-1',
                'invOperator' => '>=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_LastPrint')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_LastPrint') ?? 'InvoicesDefault';
            kpiList.add(new KpiWrapper('LBL_KpiTable_LastPrint',
                                       gridLayout,
                                       '#bdd25a',
                                       filtersMap,
                                       maxPrintedDate,
                                       '"massEmail", "singleDownloadPrintedPdf", "singleViewDetails"'));
        }
        // INV VS PAID ISSUE 5 DAYS
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_InvVsPaidIssue5Days')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_InvVsPaidIssue5Days')
                                  && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_InvVsPaidIssue5Days')))
                                ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_InvVsPaidIssue5Days').replace(',', '\', \'') + '\''
                                : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator' => 'IN',
                'dueDate' => '+5',
                'dueDateOperator' => '<=',
                'dueDateSecond' => '0',
                'dueDateOperatorSecond' => '>=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_InvVsPaidIssue5Days')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_InvVsPaidIssue5Days') ?? 'InvoicesToPaid';
            kpiList.add(new KpiWrapper('LBL_KpiTable_InvVsPaidIssue5Days',
                                       gridLayout,
                                       '#4ec2a9',
                                       filtersMap,
                                       maxPrintedDate,
                                       '"massCancel", "massEmail", "singleDownloadPrintedPdf", "singleViewDetails"'));
        }
        // INV VS PAID
        if (invoiceSettings.invoiceManagerKpis.contains('LBL_KpiTable_InvVsPaid')) {
            String statusValue = (invoiceSettings.invoiceManagerKpisStatuses.containsKey('LBL_KpiTable_InvVsPaid')
                                   && !String.isBlank(invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_InvVsPaid')))
                                ? '\'' + invoiceSettings.invoiceManagerKpisStatuses.get('LBL_KpiTable_InvVsPaid').replace(',', '\', \'') + '\''
                                : '';
            Map<String, String> filtersMap = new Map<String, String> {
                'status' => statusValue,
                'statusOperator' => 'IN',
                'dueDate' => '0',
                'dueDateOperator' => '<=',
                'docsFiles' => invoiceSettings.invoiceManagerKpisAccDoc.get('LBL_KpiTable_InvVsPaid')
            };
            String gridLayout = invoiceSettings?.invoiceManagerKpisGrid?.get('LBL_KpiTable_InvVsPaid') ?? 'InvoicesToPaid';
            kpiList.add(new KpiWrapper('LBL_KpiTable_InvVsPaid',
                                       gridLayout,
                                       '#4ec2a9',
                                       filtersMap,
                                       maxPrintedDate,
                                       '"massCancel", "massEmail", "singleDownloadPrintedPdf", "singleViewDetails"'));
        }
        return kpiList;

    }

    private static void setInternalKeys() {
        // set the internal labels
        for (String label : getInternalLabelKeys()) {
            String value = NegoptimLabels.getCustomLabel(label, '');
            internalLabelsMap.put(label, value);
        }
        // invoice satus picklist Labels
        for (Schema.PicklistEntry entry : SObjectType.Invoice__c.fields.Status__c.getPicklistValues()) {
            internalLabelsMap.put(entry.getValue(), entry.getLabel());
        }
        for (Schema.PicklistEntry entry : SObjectType.Invoice__c.fields.AccDoc__c.getPicklistValues()) {
            internalLabelsMap.put(entry.getValue(), entry.getLabel());
        }
        Map<String, Schema.SObjectField> fieldsMap = SObjectType.Invoice__c.fields.getMap();
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult inovoiceFieldResult = fieldsMap.get(fieldName).getDescribe();
            String fieldLabel = inovoiceFieldResult.getLabel();
            internalLabelsMap.put(fieldName, fieldLabel);
        }
    }

    /* WRAPPERS */
    public class KpiWrapper {
        String header { get; set; }
        List<KpiValueWrapper> kpiValue { get; set; }
        String layoutName { get; set; }
        List<KpiCategoryWrapper> category { get; set; }
        String color { get; set; }
        String link { get; set; }
        List<String> kpiCategory { get; set; }
        String prefix { get; set; }
        Date maxPrintedDate { get; set; }

        public KpiWrapper(String headerLabel, String layoutName, String color, Map<String, String> queryCodition, Date maxPrintedDate, String availableButtons) {
            String header = NegoptimLabels.getCustomLabel(headerLabel, headerLabel);
            this.header = header;
            this.kpiValue = new List<KpiValueWrapper>();
            this.layoutName = layoutName;
            this.color = color;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
            this.category = new List<KpiCategoryWrapper>();
            // get the query condition
            QueryInfoWrapper queryInfo = new QueryInfoWrapper(queryCodition, maxPrintedDate);
            String linkParameters = String.join(queryInfo.linkParameter.values(), ', ');
            String filterDescription = String.join(queryInfo.filterDescriptions, ', ');
            String link = '{"filter":['+ linkParameters + '],"filterDescriptions":['+ filterDescription + '],"availableButtons":['+ availableButtons + '],"gridLayout":\"'+layoutName+'\"}';
            this.link = link;
            // Build the query
            String condition = String.join(queryInfo.queryConditions, ' AND ');
            String query = 'SELECT COUNT(Id), SUM(TotalAmount__c), Contract__r.Supplier_Nego_Scope__r.HierarchyPurchasing__c, Contract__r.Supplier_Nego_Scope__r.HierarchyPurchasing__r.Name category'
             + ' FROM Invoice__c'
             + ' WHERE ' + condition
            + ' GROUP BY Contract__r.Supplier_Nego_Scope__r.HierarchyPurchasing__c, Contract__r.Supplier_Nego_Scope__r.HierarchyPurchasing__r.Name'
            + ' LIMIT 10000';
            List<AggregateResult> results = Database.query(query);
            Integer nbOfPieces = 0 ;
            Decimal totalValue = 0.0;
            Set<String> groupByResult = new Set<String>();
            for (AggregateResult ar : results) {
                Integer count = (Integer) ar.get('expr0'); // COUNT(Id)
                Decimal sum = (Decimal) ar.get('expr1'); // SUM(TotalAmount__c)
                String groupBy = !String.isBlank((String) ar.get('category')) ? (String) ar.get('category') : '' ;
                groupByResult.add(groupBy);
                String categoryLink = '{"filter":['+ linkParameters +
                ', "Contract__r.Supplier_Nego_Scope__r.HierarchyPurchasing__r.Name = \'' + groupBy + '\'"'
                +'],"filterDescriptions":['+ filterDescription + '],"availableButtons":['+ availableButtons + '],"gridLayout":\"'+layoutName+'\"}';
                // set the category value
                List<KpiValueWrapper> categoryWrapper = new List<KpiValueWrapper>{
                    new KpiValueWrapper ('nbOfPieces', Decimal.valueOf(count), 'decimal'),
                    new KpiValueWrapper ('totalValue', sum, 'currency')
                };
                this.category.add(new KpiCategoryWrapper(categoryWrapper, groupBy, categoryLink));

                // sum the total value and nb of pieces
                nbOfPieces += count ==  null ? 0 : count;
                totalValue += sum == null ? 0 : sum ;
            }
            this.kpiCategory = new List<String>(groupByResult);
            // set the kpi value (total value and nb of pieces)
            this.kpiValue = new List<KpiValueWrapper>{
                new KpiValueWrapper ('nbOfPieces', nbOfPieces, 'decimal'),
                new KpiValueWrapper ('totalValue', totalValue, 'currency')
            };
        }
    }

    public class KpiValueWrapper {
        String header { get; set; }
        Decimal value { get; set; }
        String type { get; set; }


        public KpiValueWrapper(String header, Decimal value, String type) {
            this.header = header == null ? '0' : header;
            this.value = value == null ? 0 : value;
            this.type = type == null ? '' : type ;
        }

        public KpiValueWrapper() {
            this.header = '';
            this.value = 0.0;
            this.type = '';
        }
    }

    public class KpiCategoryWrapper {
        List<KpiValueWrapper> kpiValue;
        String groupBy { get; set; }
        string link { get; set; }

        public KpiCategoryWrapper(List<KpiValueWrapper> kpiValue, String groupBy, string link) {
            this.kpiValue = kpiValue;
            this.groupBy = groupBy == null ? '' : groupBy ;
            this.link = link;
        }

        public KpiCategoryWrapper() {
            this.kpiValue = new List<KpiValueWrapper>();
            this.groupBy = '';
            this.link = '';
        }
    }

    public class QueryInfoWrapper {
        Map<String, String> linkParameter { get; set; }
        list<String> queryConditions { get; set; }
        list<String> filterDescriptions { get; set; }

        /*
        * Get the date format
        * @param Integer additionalDays from today - can be negative or positive
        * @return String formattedDate format (yyyy-MM-dd)
        */
        private String getDateFormat(Integer additionalDays) {
            Date dateRef = additionalDays == 0 ? Date.today() : Date.today().addDays(additionalDays);
            String formattedDate = formatDate(dateRef);
            return formattedDate;
        }

        private String formatDate (Date dateRef) {
            return dateRef.year() + '-' +
            (dateRef.month() < 10 ? '0' + dateRef.month() : String.valueOf(dateRef.month())) + '-' +
            (dateRef.day() < 10 ? '0' + dateRef.day() : String.valueOf(dateRef.day()));
        }


        private String buildStatusDescription (String header, String statusOperator, String status) {
            // label
            header = NegoptimLabels.getCustomLabel(header, header);
            String operator = statusOperator.contains('NOT') ? '!=' : '=';
            status = status.replaceAll('\'', ''); // Remove single quotes
            String[] fields = status.split(',');

            // Use List to collect translated labels
            List<String> translatedFields = new List<String>();
            for (String field : fields) {
                String trimmedField = field.trim(); // Remove any extra spaces
                translatedFields.add(internalLabelsMap.get(trimmedField)); // Add translated label to the list
            }

            // Join the list with commas
            String body = String.join(translatedFields, ', ');
            return '"' + header + ' ' + operator + ' ' + ' (' +  body + ')' + '"' ; // format Status: = (ex...)
        }

        public QueryInfoWrapper(Map<String, String> conditions, Date maxPrintedDate) {
            Map<String, String> linkParameter = new Map<String, String>();
            list<String> queryConditions = new List<String>();
            list<String> filterDescriptions = new List<String>();
            // Build the query condition and the link parameter
            // queryConditions foramt : 'Status__c = 'Printed' AND InvDate__c <= 2021-09-01'
            // linkParameter format : "Status__c IN ('Printed')" , "InvDate__c <= 2025-01-03"
            for (String condition : conditions.keySet()) {
                switch on condition {
                    when 'status' {
                        if(String.isBlank(conditions.get('status')))
                            continue;
                        String statusOperator = conditions.get('statusOperator');
                        String linkParameterValue = SObjectType.Invoice__c.fields.Status__c.Name + ' ' + statusOperator +' (' + conditions.get('status') + ')';
                        linkParameter.put('status', '"' + linkParameterValue + '"');
                        queryConditions.add(linkParameterValue);
                        String description = buildStatusDescription('LBL_Status', statusOperator , conditions.get('status') );
                        filterDescriptions.add(description);
                        continue;
                    }
                    when 'invDate' {
                        Integer invDate = Integer.valueOf(conditions.get(condition));
                        String formattedDate = getDateFormat(invDate);
                        String linkParameterValue ='"' + SObjectType.Invoice__c.fields.InvDate__c.Name + ' ' + conditions.get('invOperator') +' ' + formattedDate +'"';
                        linkParameter.put('invDate', linkParameterValue);
                        queryConditions.add(SObjectType.Invoice__c.fields.InvDate__c.Name + ' ' + conditions.get('invOperator') + ' ' + formattedDate);
                        String operatorLabel = (conditions.get('invOperator') == '<=' ? internalLabelsMap.get('LBL_To') : internalLabelsMap.get('LBL_FROM'));
                        filterDescriptions.add('"' + internalLabelsMap.get(SObjectType.Invoice__c.fields.InvDate__c.Name.toLowerCase()) + ' ' + operatorLabel + ' ' +  formattedDate + '"');
                        continue;
                    }
                    when 'createdDate' {
                        Integer invDate = Integer.valueOf(conditions.get(condition));
                        String formattedDate = getDateFormat(invDate) + 'T00:00:00Z' ;
                        String linkParameterValue = '"CreatedDate ' + conditions.get('creDateOperateor') +' ' + formattedDate +'"';
                        linkParameter.put(condition, linkParameterValue);
                        queryConditions.add(SObjectType.Invoice__c.fields.CreatedDate.Name + ' '  + conditions.get('creDateOperateor') + ' ' + formattedDate );
                        String operatorLabel = (conditions.get('creDateOperateor') == '<=' ? internalLabelsMap.get('LBL_To') : internalLabelsMap.get('LBL_FROM'));
                        filterDescriptions.add('"' + internalLabelsMap.get('createddate') + ' ' + operatorLabel + ' ' + formattedDate + '"');
                        continue;
                    }
                    when 'printDate' {
                        if (maxPrintedDate != null) {
                            String formatedPrintDate = formatDate(maxPrintedDate);
                            String query = SObjectType.Invoice__c.fields.PrintDate__c.Name   + ' = ' + formatedPrintDate;
                            linkParameter.put(SObjectType.Invoice__c.fields.PrintDate__c.Name, '"' + query + '"');
                            queryConditions.add(query );
                            filterDescriptions.add('"' + internalLabelsMap.get(SObjectType.Invoice__c.fields.PrintDate__c.Name.toLowerCase()) +' = '+ formatedPrintDate + '"');
                        }
                        continue;
                    }
                    when 'dueDate' {
                        if (conditions.get('dueDateSecond') != null) {
                            Integer invDate = Integer.valueOf(conditions.get('dueDateSecond'));
                            String formattedDate = getDateFormat(invDate);
                            String linkParameterValue = '"' + SObjectType.Invoice__c.fields.DueDate__c.Name + ' ' + conditions.get('dueDateOperatorSecond') +' ' + formattedDate +'"';
                            linkParameter.put('dueDateSecond', linkParameterValue);
                            queryConditions.add(SObjectType.Invoice__c.fields.DueDate__c.Name + ' '  + conditions.get('dueDateOperatorSecond') + ' ' + formattedDate);
                            String operatorLabel = (conditions.get('dueDateOperatorSecond') == '<=' ? internalLabelsMap.get('LBL_To') : internalLabelsMap.get('LBL_FROM'));
                            filterDescriptions.add('"' + internalLabelsMap.get(SObjectType.Invoice__c.fields.duedate__c.Name.toLowerCase()) + ' ' + operatorLabel + ' ' + formattedDate + '"');
                        }
                        Integer invDate = Integer.valueOf(conditions.get(condition));
                        String formattedDate = getDateFormat(invDate);
                        String linkParameterValue = '"' + SObjectType.Invoice__c.fields.DueDate__c.Name + ' '+ conditions.get('dueDateOperator') +' ' + formattedDate +'"';
                        linkParameter.put(condition, linkParameterValue);
                        queryConditions.add(SObjectType.Invoice__c.fields.DueDate__c.Name + ' '  + conditions.get('dueDateOperator') + ' ' + formattedDate);
                        String operatorLabel = (conditions.get('dueDateOperator') == '<=' ? internalLabelsMap.get('LBL_To') : internalLabelsMap.get('LBL_FROM'));

                        filterDescriptions.add('"' + internalLabelsMap.get(SObjectType.Invoice__c.fields.duedate__c.Name.toLowerCase()) + ' ' + operatorLabel + ' ' + formattedDate + '"');
                        continue;
                    }
                    when 'docsFiles' {
                        List<string> docsFilesList = new List<String>();
                        if(!String.isBlank(conditions.get('docsFiles'))) {
                            docsFilesList  = conditions.get('docsFiles').split(',');
                        }
                        string formatDocsFiles = '\'' + String.join(docsFilesList, '\' ,\'') + '\'';
                        String linkParameterValue = SObjectType.Invoice__c.fields.AccDoc__c.Name + ' IN '  +' (' + formatDocsFiles + ')';
                        linkParameter.put('docsFiles', '"' + linkParameterValue + '"');
                        queryConditions.add(linkParameterValue);
                        String description = buildStatusDescription(SObjectType.Invoice__c.fields.AccDoc__c.Label, '=' , formatDocsFiles);
                        filterDescriptions.add(description);
                        continue;
                    }
                    when else {
                        continue;
                    }
                }
            }
            this.linkParameter = linkParameter;
            this.queryConditions = queryConditions;
            this.filterDescriptions = filterDescriptions;
        }
    }

}