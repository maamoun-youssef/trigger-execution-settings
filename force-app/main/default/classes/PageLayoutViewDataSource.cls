global with sharing class PageLayoutViewDataSource extends VisualEditor.DynamicPickList {
     global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('--None--', '');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DataRow valueRow;
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        Map<String, LayoutSettings__mdt> ls = LayoutSettings__mdt.getAll();
        for(LayoutSettings__mdt item : ls.values()) {
            valueRow = new VisualEditor.DataRow(item.label, item.DeveloperName);
            myValues.addRow(valueRow); 
        }
        System.debug('myValues: ' + JSON.serialize(myValues));
        return myValues;
    }
}