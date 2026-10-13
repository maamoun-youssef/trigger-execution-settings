/**
 * @author ULIT
 * @date 12/12/2020
 * @description apex datasource related to negOptim toggle widget LWC to populate picklist values of boolean fields,
 * used in xml metadata for the properties field1, field2 and field3
 * */
global with sharing class FieldsDatasource extends VisualEditor.DynamicPickList {

    VisualEditor.DesignTimePageContext context; // it contains entityName and pageType (HomePage/AppPage/RecordPage)

	global FieldsDatasource() {
		this(new VisualEditor.DesignTimePageContext());
	}

    global FieldsDatasource(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    // @description get the default value of the picklist to null
    global override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    // @description populate picklist rows with boolean fields' api names as values and fields' labels as label
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        if (this.context?.entityName != null) {
            Schema.DescribeSObjectResult describeSobjects = ((SObject) (Type.forName('Schema.' + this.context.entityName).newInstance())).getSObjectType().getDescribe();
            Map<String, Schema.SObjectField> myFields = describeSobjects.fields.getMap();
            for (String field : myFields.keySet()) {
                Schema.DescribeFieldResult currentField = myFields.get(field).getDescribe();
                if (currentField.getType() === Schema.DisplayType.BOOLEAN) {
                    myValues.addRow(new VisualEditor.DataRow(currentField.getLabel(), currentField.getName()));
                }
            }
        }
      return myValues;
    }

}