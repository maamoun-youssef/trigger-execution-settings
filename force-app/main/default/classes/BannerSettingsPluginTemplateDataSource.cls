global with sharing class BannerSettingsPluginTemplateDataSource extends VisualEditor.DynamicPickList {
    private VisualEditor.DesignTimePageContext context;

    global BannerSettingsPluginTemplateDataSource(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('', '-- None --');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows output = new VisualEditor.DynamicPickListRows();
        if (context == null || String.isBlank(context.entityName)) {
            return output;
        }
        for (BannerSetting__mdt item : [SELECT DeveloperName, MasterLabel, IsActive__c, ObjectAPIName__c
                                        FROM BannerSetting__mdt
                                        WHERE IsActive__c = true
                                        AND ObjectAPIName__c = :context.entityName
                                        ORDER BY MasterLabel
                                        LIMIT 1000]) 
    {
            output.addRow(new VisualEditor.DataRow(item.MasterLabel, item.DeveloperName));
        }
        return output;
    }
}