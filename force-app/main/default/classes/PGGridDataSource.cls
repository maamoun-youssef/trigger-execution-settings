/**
 * @author ULiT
 * @date 14/11/2024
 * Class to get the options of Layout of PG Object (used in LWC PGGrid in xml)
 **/
global class PGGridDataSource extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    
	global PGGridDataSource() {
		this(new VisualEditor.DesignTimePageContext());
	}

    global PGGridDataSource(VisualEditor.DesignTimePageContext context) {
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
        List<Grid_Settings__mdt> gridLayouts = new List<Grid_Settings__mdt>();
        Set<String> developerNamesSet = new Set<String>();
        List<Grid_Settings__mdt> gridLayoutsMaster = [SELECT DeveloperName, MasterLabel, Object_Name__c, Master_Object_Name__c
                                                      FROM Grid_Settings__mdt
                                                      WHERE Object_Name__c = :SobjectType.PG__c.Name
                                                      ORDER BY DeveloperName];
        for (Grid_Settings__mdt item : gridLayoutsMaster) {
            if (!developerNamesSet.contains(item.DeveloperName)) {
                developerNamesSet.add(item.DeveloperName);
                values.addRow(new VisualEditor.DataRow(item.DeveloperName + (item.Object_Name__c != null && item.Object_Name__c != '' ? ' [' + item.Object_Name__c + ']' : '')+(item.Master_Object_Name__c != null && item.Master_Object_Name__c != '' ? ' [' + item.Master_Object_Name__c + ']' : ''), item.DeveloperName));
            }
        }
        return values;
    }
}