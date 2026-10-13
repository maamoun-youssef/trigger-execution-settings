/**
 * @author ULiT
 * @date 26/11/2024
 * @description
 */
global class FileDirectoryDataSource extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    @TestVisible
    private static Grid_Settings__mdt testDefaultGrid;
    @TestVisible
    private static List<FileDirectorySettings> testFileDirectorySettings;
    global FileDirectoryDataSource() {
        this(new VisualEditor.DesignTimePageContext());
    }

    global FileDirectoryDataSource(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        Grid_Settings__mdt defaultGrid = testDefaultGrid;
        if (defaultGrid == null) {
            GridSettingsManager manager = new GridSettingsManager('','','');
            // defaultGrid = manager.loadTemplate('Default_Library_Grid');
        }
        // if (defaultGrid == null) {
        //     return new VisualEditor.DataRow('Default Library Grid', 'Default_Library_Grid');
        // }
        VisualEditor.DataRow defaultRow = new VisualEditor.DataRow(defaultGrid.MasterLabel, defaultGrid.developerName);
        return defaultRow;
    }

	global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows values = new VisualEditor.DynamicPickListRows();
        Grid_Settings__mdt defaultGrid = testDefaultGrid;
        if (defaultGrid == null) {
            GridSettingsManager manager = new GridSettingsManager('','','');
            //defaultGrid = manager.loadTemplate('Default_Library_Grid');
        }
        /*VisualEditor.DataRow defaultRow = defaultGrid != null
            ? new VisualEditor.DataRow(defaultGrid.MasterLabel, defaultGrid.developerName)
            : new VisualEditor.DataRow('Default Library Grid', 'Default_Library_Grid');
        values.addRow(defaultRow);*/
        List<FileDirectorySettings__mdt> gridLayouts = new List<FileDirectorySettings__mdt>();
        List<FileDirectorySettings.ThemeWrapper> themeList = new List<FileDirectorySettings.ThemeWrapper>();
        List<FileDirectorySettings> allSettings = testFileDirectorySettings != null ? testFileDirectorySettings : FileDirectorySettings.loadAllFileDirectorySettings();
        System.debug('>allSettings ' + JSON.serialize(allSettings));
        for (FileDirectorySettings item : allSettings) {
            List<FileDirectorySettings.ThemeWrapper> themes = item.themesSettings;
            for (FileDirectorySettings.ThemeWrapper theme : themes) {
                String relatedSectionLabel = theme.relatedSection;
                String sanitizeThemeName = theme.theme.replace('{!$Label.' , '').replace('}' , '');
                String themelabel = theme.theme;
                if (themelabel.startsWithIgnoreCase('{!$')) { themelabel = themelabel.replace('{!$Label.' , '').replace('}' , ''); themelabel = NegoptimLabels.getCustomLabel(themelabel, themelabel) ; }
                if (relatedSectionLabel.startsWithIgnoreCase('{!$')) { relatedSectionLabel = relatedSectionLabel.replace('{!$Label.' , '').replace('}' , ''); relatedSectionLabel = NegoptimLabels.getCustomLabel(relatedSectionLabel, relatedSectionLabel); }
                values.addRow(new VisualEditor.DataRow(relatedSectionLabel + ' - ' + themelabel , item.developerName  + ' - ' + sanitizeThemeName));
            }
        }
        return values;
    }
}