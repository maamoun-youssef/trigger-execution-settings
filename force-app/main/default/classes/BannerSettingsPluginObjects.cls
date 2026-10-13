global class BannerSettingsPluginObjects extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    global BannerSettingsPluginObjects(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DynamicPickListRows values = getValues();
		if (values.size() > 0) {
			return values.get(0);
		}
		return null;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        values.addRow(new VisualEditor.DataRow('---', 'None'));
        List<EntityDefinition> sObj;
        if (context.entityName != null) {
            sObj = [SELECT QualifiedApiName, Label FROM EntityDefinition WHERE QualifiedApiName = :context.entityName ORDER BY Label ASC];
        } else {
            sObj = [SELECT QualifiedApiName, Label FROM EntityDefinition ORDER BY Label ASC];
        }
        for (EntityDefinition item : sObj) {
            values.addRow(new VisualEditor.DataRow(item.Label, item.QualifiedApiName));
        }
        return values;
    }
}