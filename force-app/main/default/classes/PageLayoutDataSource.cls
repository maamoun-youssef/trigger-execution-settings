global with sharing class PageLayoutDataSource extends VisualEditor.DynamicPickList {
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('--None--', '');
        return defaultValue;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DataRow valueRow;
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        Map<String, PageLayoutSettings__mdt> ls = PageLayoutSettings__mdt.getAll();
        for(PageLayoutSettings__mdt item : ls.values()) {
            valueRow = new VisualEditor.DataRow(item.label, item.DeveloperName);
            myValues.addRow(valueRow); 
        }
        System.debug('myValues: ' + JSON.serialize(myValues));
        return myValues;
    }
    
}