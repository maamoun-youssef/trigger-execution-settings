public class GridLayoutsDataSourceByObject extends VisualEditor.DynamicPickList {
	VisualEditor.DesignTimePageContext context;
	public GridLayoutsDataSourceByObject() {
		this(new VisualEditor.DesignTimePageContext());
	}
	public GridLayoutsDataSourceByObject(VisualEditor.DesignTimePageContext context) {
		this.context = context;
	}

	public override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DynamicPickListRows values = getValues();
		return values.size() > 0 ? values.get(0) : null;
	}

	public override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
		List<Grid_Settings__mdt> gridLayouts = new List<Grid_Settings__mdt>();
		if (context?.entityName != null) {
            Set<String> developerNamesSet = new Set<String>();
            List<Grid_Settings__mdt> gridLayoutsMaster = new List <Grid_Settings__mdt>();
            if (Test.isRunningTest()) {
                gridLayoutsMaster.add(gridSettingsManager.loadTemplate('Account_Contact'));
            } else {
                gridLayoutsMaster = [SELECT DeveloperName, MasterLabel, Object_Name__c, Master_Object_Name__c FROM Grid_Settings__mdt WHERE Object_Name__c = :context.entityName ORDER BY DeveloperName];
            }
            for (Grid_Settings__mdt item : gridLayoutsMaster) {
                if (!developerNamesSet.contains(item.DeveloperName)) {
                    developerNamesSet.add(item.DeveloperName);
					values.addRow(new VisualEditor.DataRow(item.MasterLabel + (item.Object_Name__c != null && item.Object_Name__c != '' ? ' [' + item.Object_Name__c + ']' : '')+(item.Master_Object_Name__c != null && item.Master_Object_Name__c != '' ? ' [' + item.Master_Object_Name__c + ']' : ''), item.DeveloperName));
				}
			}
        }
		return values;
	}
}