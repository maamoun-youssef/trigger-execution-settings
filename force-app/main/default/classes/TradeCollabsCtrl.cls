/**
 * @author ULiT
 * @date 26/11/2024
 * @description Controller class to manage documentsCenter LWC
 * */
public with sharing class TradeCollabsCtrl {
    
    public static List<SectionWrapper> getAllSections() {
        List<SectionWrapper> sectionsWrappers = new List<SectionWrapper>();
        // Prepare Themes of Section 1
        List<ThemeWrapper> themes1 = new List<ThemeWrapper>();
        ThemeWrapper sellinList = new ThemeWrapper('Sell-In Statement List', '', '', '', true, true, 'sellIn');
        themes1.add(sellinList);
        // Prepare Section 1
        SectionWrapper section1 = new SectionWrapper('sellIn', 'Tariff', 'Declare your sellin statements', '', '#4B8BA1', 1, false);
        section1.themesSettings = themes1;
        // Add to section
        sectionsWrappers.add(section1);
        return sectionsWrappers;
    }

    @AuraEnabled(cacheable = true)
    public static String loadData() {
        try {
            List<SectionWrapper> sectionsWrappers = TradeCollabsCtrl.getAllSections();
            // get is portal
            User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
            // prepare return result
            ResultWrapper resultWrapper = new ResultWrapper(sectionsWrappers,
                                                            user.ContactId != null);
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }

    @AuraEnabled(cacheable = true)
    public static String loadSection(String sectionTitle) {
        try {
            SectionWrapper currentSectionSettings;
            List<SectionWrapper> sectionsWrappers = TradeCollabsCtrl.getAllSections();
            for (SectionWrapper settings : sectionsWrappers) {
                if (sectionTitle == settings.sectionTitle) {
                    currentSectionSettings = settings;
                    currentSectionSettings.sectionLabel = NegoptimLabels.getCustomLabel(extractLabel(settings.sectionTitle), settings.sectionTitle);
                    currentSectionSettings.sectionSubTitle = NegoptimLabels.getCustomLabel(extractLabel(settings.sectionSubTitle), settings.sectionSubTitle);
                    for (ThemeWrapper themeWrapper : currentSectionSettings.themesSettings) {
                        themeWrapper.themeLabel = NegoptimLabels.getCustomLabel(extractLabel(themeWrapper.theme), themeWrapper.theme);
                    }
                    break;
                }
            }
            System.debug('currentSectionSettings: ' + JSON.serialize(currentSectionSettings));
            User user = [SELECT Id, ContactId, AccountId, Contact.IsOrgAdmin__c, ProfileId, Account.Supplier__c FROM User WHERE Id = :UserInfo.getUserId()];
            ResultThemeWrapper resultWrapper = new ResultThemeWrapper(currentSectionSettings,
                                                            user.ContactId != null);
            return JSON.serialize(resultWrapper);
        } catch (Exception ex) {
            System.debug('ERROR>>>' + ex.getMessage() + '>>>' + ex.getLineNumber() + '>>>' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() + ' - Line ' + ex.getLineNumber());
        }
    }


    public static String extractLabel(String data) {
            // Validate the input
            if (String.isBlank(data)) {
                return '';
            }
            // Define the regular expression pattern
            Pattern regex = Pattern.compile('\\{\\!\\$Label\\.(.*?)\\}');
            Matcher matcher = regex.matcher(data);
            // Check if the pattern matches and return the captured group
            // Return null if no match is found
            return matcher.find() ? matcher.group(1) : '';
    }

    public class ResultWrapper {
        public List<SectionWrapper> sectionWrappers {get; set;}
        public String prefix {get; set;}
        public Boolean isPortal {get; set;}

        // Parameterized constructor
        public ResultWrapper(List<SectionWrapper> sectionWrappers, Boolean isPortal) {
            this.sectionWrappers = sectionWrappers;
            this.isPortal = isPortal;
            this.prefix = NegoptimHelper.getPackagePrefix(true);
        }
    }
    public class ResultThemeWrapper {
        public SectionWrapper sectionWrapper {get; set;}
        public Boolean isPortal {get; set;}

        // Parameterized constructor
        public ResultThemeWrapper(SectionWrapper sectionWrapper, Boolean isPortal) {
            this.sectionWrapper = sectionWrapper;
            this.isPortal = isPortal;
        }
    }

    public class SectionWrapper {
        public String developerName {get; set;}
        public String sectionTitle {get; set;}
        public String sectionLabel {get; set;}
        public String sectionSubTitle {get; set;}
        public String sectionIcon {get; set;}
        public String sectionColor {get; set;} 
        public Integer displayOrder {get; set;}
        public Boolean isDeleted {get; set;}
        public List<ThemeWrapper> themesSettings {get; set;} 
        public SectionWrapper(String developerName, String sectionTitle, String sectionSubTitle, String sectionIcon, String sectionColor, Integer displayOrder, Boolean isDeleted) {
            this.developerName = developerName;
            this.sectionTitle = sectionTitle;
            this.sectionLabel = NegoptimLabels.getCustomLabel(extractLabel(sectionTitle), sectionTitle);
            this.sectionSubTitle = NegoptimLabels.getCustomLabel(extractLabel(sectionSubTitle), sectionSubTitle);
            this.sectionIcon = sectionIcon;
            this.sectionColor = sectionColor;
            this.displayOrder = displayOrder;
            this.isDeleted = isDeleted;
        }
    }
    /**
     * Wrapper class for Theme settings.
     */
    public class ThemeWrapper {
        public String theme {get; set;}
        public String themeLabel {get; set;}
        public String gridSettingsName {get; set;}
        public String smallThemeImage {get; set;}
        public String largeThemeImage {get; set;}
        public Boolean isDisplayed {get; set;}
        public Boolean isPortalDisplayed {get; set;}
        public String relatedSection {get; set;}
        
        /**
         * Constructor for ThemeWrapper.
         *
         * @param theme - The name of the theme.
         * @param gridSettingsName - The name of the grid settings.
         * @param smallThemeImage - URL or identifier for the small theme image.
         * @param largeThemeImage - URL or identifier for the large theme image.
         * @param isDisplayed - Flag indicating if the theme is displayed.
         * @param isPortalDisplayed - Flag indicating if the theme is displayed in the portal.
         * @param relatedSection - The related section for the theme.
         */
        public ThemeWrapper(String theme, String gridSettingsName, String smallThemeImage, String largeThemeImage, Boolean isDisplayed, Boolean isPortalDisplayed, String relatedSection) {
            this.theme = theme;
            this.themeLabel = NegoptimLabels.getCustomLabel(extractLabel(theme), theme);
            this.gridSettingsName = gridSettingsName;
            this.smallThemeImage = smallThemeImage;
            this.largeThemeImage = largeThemeImage;
            this.isDisplayed = isDisplayed;
            this.isPortalDisplayed = isPortalDisplayed;
            this.relatedSection = relatedSection;
        }
    }

}