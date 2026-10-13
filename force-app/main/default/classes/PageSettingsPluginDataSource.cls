global class PageSettingsPluginDataSource extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    global PageSettingsPluginDataSource() {
        this(new VisualEditor.DesignTimePageContext());
    }
    global PageSettingsPluginDataSource(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }
    
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DynamicPickListRows values = getValues();
        return values.size() > 0 ? values.get(0) : null;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        for (PageSettings__mdt item : [SELECT Name__c, DeveloperName FROM PageSettings__mdt WHERE isActive__c = true]) {
            values.addRow(new VisualEditor.DataRow(item.Name__c, item.DeveloperName));
        }
        return values;
    }
}