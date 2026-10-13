global class ProductDiscountStatementDataSource extends VisualEditor.DynamicPickList {
    
	VisualEditor.DesignTimePageContext context;

	global ProductDiscountStatementDataSource() {
		this(new VisualEditor.DesignTimePageContext());
	}

	global ProductDiscountStatementDataSource(VisualEditor.DesignTimePageContext context) {
		this.context = context;
	}

	global override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DynamicPickListRows values = getValues();
		return values.size() > 0 ? values.get(0) : null;
	}

	global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        List<Grid_Settings__mdt> gridLayouts = [SELECT DeveloperName, MasterLabel, Object_Name__c, Master_Object_Name__c
                                                FROM Grid_Settings__mdt
                                                WHERE Object_Name__c = :SObjectType.ProductDiscountStatement__c.Name
                                                ORDER BY DeveloperName limit 10000];
        for (Grid_Settings__mdt item : gridLayouts) {
            values.addRow(new VisualEditor.DataRow(item.MasterLabel + (item.Object_Name__c != null && item.Object_Name__c != '' ? ' [' + item.Object_Name__c + ']' : '')+(item.Master_Object_Name__c != null && item.Master_Object_Name__c != '' ? ' [' + item.Master_Object_Name__c + ']' : ''), item.DeveloperName));
        }
        return values;
	}

}