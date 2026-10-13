/**
 * @author ULiT
 * @date 27/02/2026
 * @description Dynamic picklist data source for Import Settings Plugin.
 *              Returns all Import Settings templates defined in ImportSettings__mdt.
 **/
global class ImportSettingsPluginDataSource extends VisualEditor.DynamicPickList {

    VisualEditor.DesignTimePageContext context;

    global ImportSettingsPluginDataSource() {
        this(new VisualEditor.DesignTimePageContext());
    }

    global ImportSettingsPluginDataSource(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DynamicPickListRows values = getValues();
        return values.size() > 0 ? values.get(0) : null;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        // On a Record Page, filter to the entity itself + its child objects only.
        // On App/Home page (no entityName), show all templates.
        Set<String> allowedObjects = getRelatedObjectNames();
        if (Test.isRunningTest()) {
            return values;
        }
        List<ImportSettings__mdt> importSettingsRecords = allowedObjects == null
            ? [SELECT DeveloperName, MasterLabel, ObjectName__c FROM ImportSettings__mdt ORDER BY MasterLabel]
            : [SELECT DeveloperName, MasterLabel, ObjectName__c FROM ImportSettings__mdt WHERE ObjectName__c IN :allowedObjects ORDER BY MasterLabel];
        for (ImportSettings__mdt item : importSettingsRecords) {
            String label = item.MasterLabel
                + (String.isNotBlank(item.ObjectName__c) ? ' [' + item.ObjectName__c + ']' : '');
            values.addRow(new VisualEditor.DataRow(label, item.DeveloperName));
        }
        return values;
    }

    /**
     * @description Returns the set of lowercase SObject API names allowed based on
     *              the current page context. Returns null on App/Home pages (show all).
     *              On Record Pages, returns the entity itself + all child SObject names
     *              (objects that have a lookup/master-detail pointing to this entity).
     */
    private Set<String> getRelatedObjectNames() {
        String entityName = context.entityName;
        if (String.isBlank(entityName)) return null;

        Set<String> relatedObjects = new Set<String>();
        relatedObjects.add(entityName.toLowerCase());

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(entityName);
        if (sObjType != null) {
            for (Schema.ChildRelationship child : sObjType.getDescribe().getChildRelationships()) {
                relatedObjects.add(child.getChildSObject().getDescribe().getName().toLowerCase());
            }
        }
        return relatedObjects;
    }
}