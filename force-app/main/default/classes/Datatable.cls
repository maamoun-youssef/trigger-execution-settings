/**
 * @author ULiT
 * @date 15/10/2025
 * @description Render sObject records to html table
 * */
global virtual class Datatable {

    public List<String> headers;
    public List<SObjectType> sobjectTypesList;
    public List<List<String>> fieldApiNames = new List<List<String>>();
    public List<TableRow> rows {get; set;}
    public Boolean isSuccessTable;

    public Boolean hasRows() {
        return this.rows != null && !this.rows.isEmpty();
    }

    public Datatable(List<SObjectType> sobjectTypesList, List<List<String>> fieldApiNames, Boolean isSuccessTable) {
        this(null, sobjectTypesList, fieldApiNames, isSuccessTable);
    }

    public Datatable(List<String> headers, List<SObjectType> sobjectTypesList, List<List<String>> fieldApiNames, Boolean isSuccessTable) {
        if (sobjectTypesList == null || sobjectTypesList.isEmpty()) {
            throw new ArgumentCanNotBeNullException('first argument can not be null');
        }
        if (fieldApiNames == null || fieldApiNames.isEmpty()) {
            throw new ArgumentCanNotBeNullException('second argument can not be null');
        }
        if (sobjectTypesList.size() != fieldApiNames.size()) {
            throw new SObjectFieldsSObjectTypeMissmatchException('first and second argument must have the same size');
        }
        for (Integer i = 0; i < sobjectTypesList.size(); i++) {
            SObjectType sobjType = sobjectTypesList.get(i);
            Map<String, Schema.SObjectField> fieldsMap = sobjType.getDescribe().fields.getMap();
            for(String fieldApiName : fieldApiNames.get(i)) {
                if (!fieldsMap.containsKey(fieldApiName)) {
                    throw new SObjectFieldsSObjectTypeMissmatchException(fieldApiName + ' is not a field of ' + sobjType);
                }
            }
        }
        this.rows = new List<TableRow>();
        this.headers = headers;
        this.sobjectTypesList = sobjectTypesList;
        this.fieldApiNames = fieldApiNames;
        this.isSuccessTable = isSuccessTable;
    }

    public void addRow(List<SObject> sObjects, String status, String message) {
        if (sObjects == null || sObjects.size() != this.sobjectTypesList.size()) {
            throw new WrongSObjectTypeException('The number of SObjects must match the number of SObject types defined for the table.');
        }
        for(Integer i = 0; i < sObjects.size(); i++) {
            if (sObjects.get(i).getSObjectType() != this.sobjectTypesList.get(i)) {
                throw new WrongSObjectTypeException('SObject at index ' + i + ' has wrong SObjectType. Expected ' + this.sobjectTypesList.get(i) + ', but got ' + sObjects.get(i).getSObjectType());
            }
        }
        TableRow row = new TableRow(sObjects, status, message);
        row.fieldApiNames = this.fieldApiNames;
        row.sobjectTypesList = this.sobjectTypesList;
        if(this.isSuccessTable) {
            row.setIsSuccess(true);
        } else {
            row.setIsSuccess(false);
        }
        this.rows.add(row);
    }

    public String renderToHtml() {
        Integer maxHtmlLength = Schema.SObjectType.Log__c.fields.SuccessResultSummary__c.getLength();
        String content = '';
        String endOfTable = '</tbody></table><br/>';
        content += '<table style="border-collapse:collapse;width:100%" border="1" cellpadding="5" cellspacing="0">';
        content += '<thead>';
        content += '<tr>';
        for(Integer i = 0; i < this.sobjectTypesList.size(); i++) {
            SObjectType sobjType = this.sobjectTypesList.get(i);
            List<String> fieldsApiNames = this.fieldApiNames.get(i);
            if(this.headers != null) {
                content += '<th colspan="' + fieldsApiNames.size() + '" rowspan="1" style="text-align:center">'
                    + this.headers.get(i) + '</th>';
            } else {
                content += '<th colspan="' + fieldsApiNames.size() + '" rowspan="1" style="text-align:center">'
                    + sobjType.getDescribe().getLabel() + '</th>';
            }
        }
        content += '<th colspan="1" rowspan="2" style="text-align:center">' + Label.LBL_LogResultsStatus + '</th>';
        if(!this.isSuccessTable) {
            content += '<th colspan="1" rowspan="2" style="text-align:center">' + Label.LBL_LogResultsMessage + '</th>';
        }
        content += '</tr>';
        content += '<tr>';
        for(Integer i=0; i < this.fieldApiNames.size(); i++) {
            List<String> fieldsApiNames = this.fieldApiNames.get(i);
            SObjectType sobjType = this.sobjectTypesList.get(i);
            for (String fieldName : fieldsApiNames) {
                SObjectField sField = sobjType.getDescribe().fields.getMap().get(fieldName);
                String fieldLabel = sField.getDescribe().getLabel();
                content += '<th scope="col">' + fieldLabel + '</th>';
            }
        }
        content += '</tr>';
        content += '</thead>';
        content += '<tbody>';
        for (TableRow row : this.rows) {
            content += row.renderToHtml();
        }
        content += endOfTable;
        return content;
    }

    public class TableRow {
        private List<sObject> sObjectsInstances;
        private Boolean isSuccess;
        private String status;
        private String message;
        private List<List<String>> fieldApiNames;
        private List<sObjectType> sobjectTypesList;

        public TableRow() { }

        public TableRow(List<SObject> sObjects, String status, String message) {
            this.sObjectsInstances = sObjects;
            this.status = status;
            this.message = message;
        }

        public void addSObject(SObject sObjt) {
            SObjectType sobjType = this.sobjectTypesList.get(this.sObjectsInstances.size() - 1);
            if (sobjType == sObjt.getSObjectType()) {
                this.sObjectsInstances.add(sObjt);
            } else {
                throw new WrongSObjectTypeException(sObjt.getSObjectType() + ' is not of type : ' + sobjType);
            }
        }

        public void setIsSuccess(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public void setStatus(String status) {
            this.status = status;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public String renderToHtml() {
            String content = '<tr>';
            for (Integer i = 0; i < this.sObjectsInstances.size(); i++) {
                SObject sObjt = this.sObjectsInstances.get(i);
                SObjectType sobjType = this.sobjectTypesList.get(i);
                List<String> fieldsApiNames = this.fieldApiNames.get(i);
                List<FieldsDescriptor> fieldDescriptors = getFieldsDescriptor(sobjType, fieldsApiNames);
                Integer totalFieldsNumber = fieldsApiNames.size();
                Integer halfFieldNumber = (totalFieldsNumber + 1) / 2;
                for (Integer j = 0; j < totalFieldsNumber; j++) {
                    FieldsDescriptor fd = fieldDescriptors[j];
                    String align = j < halfFieldNumber ? 'left' : 'right';
                    Object value = sObjt.get(fd.fieldName);
                    String displayValue = '';
                    if (value != null) {
                        if (fd.isPicklist) {
                            displayValue = fd.picklistLabels.get((String)value);
                        } else if (fd.isReference) {
                            SObject relatedRecord = (SObject) sObjt.getSObject(fd.fieldName.replace('__c', '__r'));
                            displayValue = String.valueOf(relatedRecord.get('Name'));
                        } else {
                            displayValue = String.valueOf(value);
                        }
                    }
                    if (fd.fieldName == 'Name') {
                        String recordLink = System.URL.getOrgDomainUrl().toExternalForm() + '/' + sObjt.Id;
                        displayValue = '<a href="' + recordLink + '" target="_blank">' + displayValue + '</a>';
                    }
                    content += '<td colspan="1" rowspan="1" style="text-align:' + align + ';">' + (displayValue != null ? displayValue : '') + '</td>';
                }
            }
            //green the status if succes red if failure
            String statusColor = isSuccess ? 'green' : 'red';
            content += '<td colspan="1" rowspan="1" style="color:'+ statusColor +';">' + status + '</td>';
            content += '</td>';
            if(!this.isSuccess) {
                content += '<td colspan="1" rowspan="1">';
                content += this.message;
                content += '</td>';
            }
            content += '</tr>';
            return content;
        }

        public List<FieldsDescriptor> getFieldsDescriptor(SObjectType sObjectType, List<String> FieldsApiNames) {
            List<FieldsDescriptor> fieldsDescriptorList = new List<FieldsDescriptor>();
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            for (String fieldApiName : FieldsApiNames) {
                if (!fieldMap.containsKey(fieldApiName)) {
                    throw new Datatable.WrongSObjectFieldException(fieldApiName + ' is not a field of ' + sObjectType);
                }
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldApiName).getDescribe();
                FieldsDescriptor fd = new FieldsDescriptor();
                fd.fieldName = fieldApiName;
                fd.fieldLabel = fieldDesc.getLabel();
                fd.fieldType = String.valueOf(fieldDesc.getType());
                fd.isNumberField = isNumberFieldType(fieldDesc.getType());
                fd.isDate = fieldDesc.getType() == Schema.DisplayType.DATE;
                fd.isDateTime = fieldDesc.getType() == Schema.DisplayType.DATETIME;
                fd.isPicklist = fieldDesc.getType() == Schema.DisplayType.PICKLIST;
                fd.isBoolean = fieldDesc.getType() == Schema.DisplayType.BOOLEAN;
                fd.isTextArea = fieldDesc.getType() == Schema.DisplayType.TextArea;
                fd.isReference = fieldDesc.getType() == Schema.DisplayType.REFERENCE && !fieldApiName.endsWith('RecordTypeId');
                if (fd.isPicklist) {
                    for (Schema.PicklistEntry entry : fieldDesc.getPicklistValues()) {
                        fd.picklistValues.add(entry.getValue());
                        fd.picklistLabels.put(entry.getValue(), entry.getLabel());
                    }
                }
                fieldsDescriptorList.add(fd);
            }
            return fieldsDescriptorList;
        }

        private Boolean isNumberFieldType(Schema.DisplayType type) {
            return type == Schema.DisplayType.CURRENCY
                || type == Schema.DisplayType.DOUBLE
                || type == Schema.DisplayType.INTEGER
                || type == Schema.DisplayType.LONG
                || type == Schema.DisplayType.PERCENT;
        }
    }

    public class FieldsDescriptor {
        public String fieldName { get; set; }
        public String fieldLabel { get; set; }
        public String fieldType { get; set; }
        public List<String> picklistValues { get; set; }
        public Map<String, String> picklistLabels { get; set; }
        public Boolean isNumberField { get; set; }
        public Boolean isDate { get; set; }
        public Boolean isDateTime { get; set; }
        public Boolean isReference { get; set; }
        public Boolean isPicklist { get; set; }
        public Boolean isBoolean { get; set; }
        public Boolean isTextArea { get; set; }

        public FieldsDescriptor() {
            this.picklistValues = new List<String>();
            this.picklistLabels = new Map<String, String>();
        }
    }

    public class WrongSObjectTypeException extends Exception {}
    public class WrongSObjectFieldException extends Exception {}
    public class SObjectFieldsSObjectTypeMissmatchException extends Exception {}
    public class ArgumentCanNotBeNullException extends Exception {}
}