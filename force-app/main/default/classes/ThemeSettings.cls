global with sharing class ThemeSettings extends SettingsManager implements MethodUtils.MethodChecker {
    public String name {get; set;}
    public ThemeAttributeWrapper themeAttributes {get; set;}

    public ThemeSettings() {
        this.name = '';
        this.themeAttributes = new ThemeAttributeWrapper('', '', '', '');
    }

    public static List<ThemeSettings> loadAllThemeSettings() {
        return (List<ThemeSettings>) JSON.deserialize(JSON.serialize(loadAllCustomMetadataSettings(ThemeSettings__mdt.SObjectType, ThemeSettings.class.getName(), null)), List<ThemeSettings>.class);
    }

    global static String loadAllThemeSettingsSerialized() {
        return JSON.serialize(loadAllThemeSettings());
    }
    public static ThemeSettings loadThemeSettings(String developerName) {
        return (ThemeSettings) SettingsManager.loadCustomMetadataSettings(ThemeSettings__mdt.SObjectType, developerName, ThemeSettings.class.getName());
    }
    public static String save(ThemeSettings themeSettings) {
        if (themeSettings != null) {
            Map<String, Object> fieldsValueMap = new Map<String, Object> {
                SObjectType.ThemeSettings__mdt.fields.ThemeAttributes__c.Name => JSON.serialize(themeSettings.themeAttributes)
            };
            return saveCustomMetadataSettings(ThemeSettings__mdt.SObjectType, themeSettings.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
        }
        return null;
    }

    public static String save(List<ThemeSettings> themeSettings) {
        if(themeSettings != null) {
            Map<String, Map<String, Object>> metadataRecordsMap = new Map<String, Map<String, Object>>();
            for (ThemeSettings themeSetting : themeSettings) {
                if (themeSetting != null) {
                    Map<String, Object> fieldsValueMap = new Map<String, Object> {
                        SObjectType.ThemeSettings__mdt.fields.ThemeAttributes__c.Name => JSON.serialize(themeSetting.themeAttributes)
                    };
                    metadataRecordsMap.put(themeSetting.name.replaceAll('\\s+', '_').replaceAll('[^a-zA-Z0-9\\_]', '').replaceAll('[_]+', '_'), fieldsValueMap);
                }
            }
            return saveAllCustomMetadataSettings(ThemeSettings__mdt.SObjectType, metadataRecordsMap);
        }
        return null;
    }
    
    public ThemeSettings load(Object metadataRecord) {
        if (metadataRecord != null) {
            ThemeSettings__mdt themeSettingsRecord = (ThemeSettings__mdt) metadataRecord;
            this.name = String.isNotBlank(themeSettingsRecord.DeveloperName) ? themeSettingsRecord.DeveloperName : '';
            this.themeAttributes = String.isNotBlank(themeSettingsRecord.ThemeAttributes__c) ? (ThemeAttributeWrapper) JSON.deserialize(themeSettingsRecord.ThemeAttributes__c, ThemeAttributeWrapper.class) : new ThemeAttributeWrapper('', '', '', '');
        }
        return this;
    }
    
    public Boolean hasMethod(String methodName) {
        if (methodName == 'load') {
            return true;
        }
        return false;
    }
    
    public Object invoke(String methodName, List<Object> args) {
        if (methodName == 'load') {
            return load(args[0]);
        }
        throw new IllegalArgumentException('Method not found: ' + methodName);
    }

    public static String generateTokens(String themeSettingsName) {
        ThemeSettings themeSetting = loadThemeSettings(themeSettingsName);
        if (themeSetting == null) {
            throw new AuraHandledException('Theme settings not found for name: ' + themeSettingsName);
        }
        return generateTokens(themeSetting.themeAttributes);
    }

    public static String generateTokens(ThemeAttributeWrapper attributes) {
        if (attributes == null) {
            attributes = new ThemeAttributeWrapper('', '', '', '');
        }
        String brandColor = String.isBlank(attributes.brandColor) ? '#0176D3' : attributes.brandColor;
        String backgroundColor = String.isBlank(attributes.bgColor) ? '#ffffff' : attributes.bgColor;
        String fontFamily = String.isBlank(attributes.fontFamily) ? '\'Inter\', sans-serif' : attributes.fontFamily;
        String borderRadius = String.isBlank(attributes.borderRadius) ? '4px' : attributes.borderRadius;
        // Pre-compute contrast decisions once
        String onBrand = getContrastColor(brandColor);
        String onSurface = getContrastColor(backgroundColor);
        Boolean isDarkBg = onSurface == '#ffffff';

        Map<String, String> tokens = new Map<String, String>();

        // ── Brand base scale ──
        tokens.put('slds-g-color-brand-base-50', brandColor);
        tokens.put('slds-g-color-brand-base-60', shiftLightness(brandColor, -10));
        tokens.put('slds-g-color-brand-base-70', shiftLightness(brandColor, -20));

        // ── Accent scale ──
        tokens.put('slds-g-color-accent-1', brandColor);
        tokens.put('slds-g-color-accent-2', shiftLightness(brandColor, 10));
        tokens.put('slds-g-color-accent-3', shiftLightness(brandColor, 20));
        tokens.put('slds-g-color-accent-container-1', brandColor);
        tokens.put('slds-g-color-accent-container-2', shiftLightness(brandColor, -10));
        tokens.put('slds-g-color-accent-container-3', shiftLightness(brandColor, -20));
        tokens.put('slds-g-color-on-accent-1', onBrand);

        // ── Surfaces ──
        tokens.put('slds-g-color-surface-1', backgroundColor);
        tokens.put('slds-g-color-surface-2', shiftLightness(backgroundColor, -2));
        tokens.put('slds-g-color-surface-container-1', backgroundColor);
        tokens.put('slds-g-color-surface-container-2', shiftLightness(backgroundColor, -4));
        tokens.put('slds-g-color-surface-container-3', shiftLightness(backgroundColor, -8));

        // ── On-surface (text) ──
        tokens.put('slds-g-color-on-surface-1', onSurface);
        tokens.put('slds-g-color-on-surface-2', isDarkBg ? '#d1d5db' : '#374151');
        tokens.put('slds-g-color-on-surface-3', isDarkBg ? '#9ca3af' : '#6b7280');

        // ── Borders ──
        tokens.put('slds-g-color-border-1', isDarkBg ? '#374151' : '#e5e7eb');
        tokens.put('slds-g-color-border-2', isDarkBg ? '#6b7280' : '#9ca3af');
        tokens.put('slds-g-color-border-accent-1', shiftLightness(brandColor, 20));
        tokens.put('slds-g-color-border-accent-2', shiftLightness(brandColor, 10));
        tokens.put('slds-g-color-border-accent-3', brandColor);

        // ── Neutrals ──
        tokens.put('slds-g-color-neutral-base-10', isDarkBg ? '#f9fafb' : '#111827');
        tokens.put('slds-g-color-neutral-base-50', '#6b7280');
        tokens.put('slds-g-color-neutral-base-95', isDarkBg ? '#1f2937' : '#f9fafb');

        // ── Semantic: Error ──
        tokens.put('slds-g-color-error-1', '#dc2626');
        tokens.put('slds-g-color-error-container-1', isDarkBg ? '#450a0a' : '#fee2e2');
        tokens.put('slds-g-color-on-error-1', isDarkBg ? '#fca5a5' : '#7f1d1d');
        tokens.put('slds-g-color-border-error-1', '#dc2626');

        // ── Semantic: Success ──
        tokens.put('slds-g-color-success-1', '#16a34a');
        tokens.put('slds-g-color-success-container-1', isDarkBg ? '#052e16' : '#dcfce7');
        tokens.put('slds-g-color-on-success-1', isDarkBg ? '#86efac' : '#14532d');
        tokens.put('slds-g-color-border-success-1', '#16a34a');

        // ── Semantic: Warning ──
        tokens.put('slds-g-color-warning-1', '#d97706');
        tokens.put('slds-g-color-warning-container-1', isDarkBg ? '#451a03' : '#fef3c7');
        tokens.put('slds-g-color-on-warning-1', isDarkBg ? '#fcd34d' : '#78350f');

        // ── Semantic: Info ──
        tokens.put('slds-g-color-info-1', '#2563eb');
        tokens.put('slds-g-color-info-container-1', isDarkBg ? '#1e3a5f' : '#dbeafe');
        tokens.put('slds-g-color-on-info-1', isDarkBg ? '#93c5fd' : '#1e3a8a');

        // ── Disabled ──
        tokens.put('slds-g-color-disabled-1', isDarkBg ? '#4b5563' : '#9ca3af');
        tokens.put('slds-g-color-disabled-container-1', isDarkBg ? '#1f2937' : '#f3f4f6');
        tokens.put('slds-g-color-on-disabled-1', '#6b7280');
        tokens.put('slds-g-color-border-disabled-1', isDarkBg ? '#374151' : '#d1d5db');

        // ── Typography ──
        tokens.put('slds-g-font-family-base', fontFamily);
        tokens.put('slds-g-font-size-base', '16px');
        tokens.put('slds-g-font-scale-1', '12px');
        tokens.put('slds-g-font-scale-2', '14px');
        tokens.put('slds-g-font-scale-3', '16px');
        tokens.put('slds-g-font-scale-4', '20px');
        tokens.put('slds-g-font-weight-4', '400');
        tokens.put('slds-g-font-weight-7', '700');
        tokens.put('slds-g-font-lineheight-base', '1.5');

        // ── Radius ──
        tokens.put('slds-g-radius-border-1', '2px');
        tokens.put('slds-g-radius-border-2', borderRadius);
        tokens.put('slds-g-radius-border-3', '6px');
        tokens.put('slds-g-radius-border-4', '8px');
        tokens.put('slds-g-radius-circle', '50%');
        tokens.put('slds-g-radius-border-pill', '9999px');

        // ── Shadows ──
        tokens.put('slds-g-shadow-1', '0 1px 2px rgba(0,0,0,0.05)');
        tokens.put('slds-g-shadow-2', '0 2px 4px rgba(0,0,0,0.08)');
        tokens.put('slds-g-shadow-3', '0 4px 12px rgba(0,0,0,0.12)');
        tokens.put('slds-g-shadow-4', '0 12px 24px rgba(0,0,0,0.18)');

        // ── Spacing ──
        tokens.put('slds-g-spacing-1', '4px');
        tokens.put('slds-g-spacing-2', '8px');
        tokens.put('slds-g-spacing-3', '12px');
        tokens.put('slds-g-spacing-4', '16px');
        tokens.put('slds-g-spacing-5', '20px');
        tokens.put('slds-g-spacing-6', '24px');

        // ── Border sizing ──
        tokens.put('slds-g-sizing-border-1', '1px');
        tokens.put('slds-g-sizing-border-2', '2px');
        tokens.put('slds-g-sizing-border-3', '3px');
        tokens.put('slds-g-sizing-border-4', '4px');

        // ── Component: Button ──
        tokens.put('slds-c-button-color-background', backgroundColor);
        tokens.put('slds-c-button-color-border', isDarkBg ? '#6b7280' : '#9ca3af');
        tokens.put('slds-c-button-text-color', onSurface);
        tokens.put('slds-c-button-radius-border', borderRadius);
        tokens.put('slds-c-button-brand-color-background', brandColor);
        tokens.put('slds-c-button-brand-color-background-active', shiftLightness(brandColor, -20));
        tokens.put('slds-c-button-brand-color-border', brandColor);
        tokens.put('slds-c-button-brand-text-color', onBrand);
        tokens.put('slds-c-button-destructive-color-background', '#dc2626');
        tokens.put('slds-c-button-destructive-text-color', '#ffffff');
        tokens.put('slds-c-button-success-color-background', '#16a34a');
        tokens.put('slds-c-button-success-text-color', '#ffffff');
        tokens.put('slds-c-button-neutral-color-background', backgroundColor);
        tokens.put('slds-c-button-neutral-color-background-active', shiftLightness(backgroundColor, isDarkBg ? 12 : -8));
        tokens.put('slds-c-button-neutral-color-border', isDarkBg ? '#6b7280' : '#9ca3af');
        tokens.put('slds-c-button-neutral-text-color', onSurface);
        tokens.put('slds-c-button-neutral-radius-border', borderRadius);
        // Brand button hover
        tokens.put('slds-c-button-brand-color-background-hover', shiftLightness(brandColor, -10));
        tokens.put('slds-c-button-brand-color-border-hover', shiftLightness(brandColor, -10));
        tokens.put('slds-c-button-brand-text-color-hover', onBrand);

        // Neutral button hover
        tokens.put('slds-c-button-neutral-color-background-hover', shiftLightness(backgroundColor, isDarkBg ? 8 : -4));
        tokens.put('slds-c-button-neutral-text-color-hover', onSurface);

        // ── Component: Icon ──
        // Foreground = icon color (utility icons use this)
        // tokens.put('slds-c-icon-color-foreground', isDarkBg ? '#d1d5db' : '#374151');
        // tokens.put('slds-c-icon-color-foreground-default', isDarkBg ? '#9ca3af' : '#6b7280');
        // tokens.put('sds-c-icon-color-foreground', isDarkBg ? '#d1d5db' : '#374151');
        // tokens.put('sds-c-icon-color-foreground-default', isDarkBg ? '#9ca3af' : '#6b7280');
        // // Background = the colored tile behind standard/custom/action icons
        // tokens.put('slds-c-icon-color-background', brandColor);
        // tokens.put('sds-c-icon-color-background', brandColor);
        // // Radius of the tile
        // tokens.put('slds-c-icon-radius-border', borderRadius);
        // tokens.put('sds-c-icon-radius-border', borderRadius);

        // ── Component: Card ──
        tokens.put('slds-c-card-color-background', backgroundColor);
        tokens.put('slds-c-card-color-border', isDarkBg ? '#374151' : '#e5e7eb');
        tokens.put('slds-c-card-radius-border', borderRadius);
        tokens.put('slds-c-card-shadow', '0 2px 4px rgba(0,0,0,0.08)');
        tokens.put('slds-c-card-spacing-block-start', '16px');
        tokens.put('slds-c-card-spacing-block-end', '16px');
        tokens.put('slds-c-card-spacing-inline-start', '16px');
        tokens.put('slds-c-card-spacing-inline-end', '16px');
        tokens.put('slds-c-card-header-color-background', backgroundColor);
        tokens.put('slds-c-card-footer-color-background', shiftLightness(backgroundColor, -2));

        // ── Component: Input ──
        tokens.put('slds-c-input-color-background', backgroundColor);
        tokens.put('slds-c-input-color-background-focus', backgroundColor);
        tokens.put('slds-c-input-color-border', isDarkBg ? '#6b7280' : '#9ca3af');
        tokens.put('slds-c-input-color-border-focus', brandColor);
        tokens.put('slds-c-input-text-color', onSurface);
        tokens.put('slds-c-input-radius-border', borderRadius);

        // Focus shadow with brand color at 20% alpha
        String brandHex = brandColor.removeStart('#');
        Integer br = hexToInt(brandHex.substring(0, 2));
        Integer bg = hexToInt(brandHex.substring(2, 4));
        Integer bb = hexToInt(brandHex.substring(4, 6));
        tokens.put('slds-c-input-shadow',
            '0 0 0 3px rgba(' + br + ',' + bg + ',' + bb + ',0.2)');

        // ── Component: Badge ──
        tokens.put('slds-c-badge-color-background', isDarkBg ? '#451a03' : '#fef3c7');
        tokens.put('slds-c-badge-text-color', isDarkBg ? '#fcd34d' : '#78350f');
        tokens.put('slds-c-badge-radius-border', '9999px');

        // ── Component: Spinner ──
        tokens.put('slds-c-spinner-color-foreground', brandColor);

        // ── Component: Checkbox ──
        tokens.put('slds-c-checkbox-color-background', backgroundColor);
        tokens.put('slds-c-checkbox-color-background-checked', brandColor);
        tokens.put('slds-c-checkbox-color-border', isDarkBg ? '#6b7280' : '#9ca3af');
        tokens.put('slds-c-checkbox-mark-color-foreground', onBrand);
        tokens.put('slds-c-checkbox-radius-border', '2px');

        return JSON.serialize(tokens);
    }

    public class HSL {
        public Decimal h; // 0-360
        public Decimal s; // 0-100
        public Decimal l; // 0-100
        public HSL(Decimal h, Decimal s, Decimal l) {
            this.h = h;
            this.s = s;
            this.l = l;
        }
    }

    public static HSL hexToHsl(String hex) {
        hex = hex.removeStart('#');

        // Normalize each channel to 0.0 - 1.0
        Decimal r = hexToInt(hex.substring(0, 2)) / 255.0;
        Decimal g = hexToInt(hex.substring(2, 4)) / 255.0;
        Decimal b = hexToInt(hex.substring(4, 6)) / 255.0;

        Decimal maxVal = Math.max(r, Math.max(g, b));
        Decimal minVal = Math.min(r, Math.min(g, b));
        Decimal delta = maxVal - minVal;

        // Lightness is the midpoint between max and min channels
        Decimal l = (maxVal + minVal) / 2.0;
        Decimal h = 0;
        Decimal s = 0;

        if (delta != 0) {
            // Saturation formula differs based on lightness
            s = l > 0.5
                ? delta / (2.0 - maxVal - minVal)
                : delta / (maxVal + minVal);

            // Hue depends on which channel is dominant
            if (maxVal == r) {
                h = ((g - b) / delta) + (g < b ? 6 : 0);
            } else if (maxVal == g) {
                h = ((b - r) / delta) + 2;
            } else {
                h = ((r - g) / delta) + 4;
            }
            h *= 60; // convert from sector (0-6) to degrees (0-360)
        }

        return new HSL(h, s * 100, l * 100);
    }

    public static Integer hexToInt(String hex) {
        Integer result = 0;
        hex = hex.toUpperCase();
        for (Integer i = 0; i < hex.length(); i++) {
            Integer charCode = hex.charAt(i);
            Integer digit;
            if (charCode >= 48 && charCode <= 57) {
                // '0'-'9' → 0-9
                digit = charCode - 48;
            } else if (charCode >= 65 && charCode <= 70) {
                // 'A'-'F' → 10-15
                digit = charCode - 55;
            } else {
                digit = 0;
            }
            result = result * 16 + digit;
        }
        return result;
    }

    public static String toHexPair(Integer val) {
        val = Math.min(255, Math.max(0, val));
        String chars = '0123456789abcdef';
        Integer high = val / 16;
        Integer low = Math.mod(val, 16);
        return chars.substring(high, high + 1)
            + chars.substring(low, low + 1);
    }

    public static Decimal decimalMod(Decimal value, Decimal divisor) {
        Decimal quotient = value / divisor;
        Integer floored = quotient >= 0
            ? quotient.intValue()
            : quotient.intValue() - 1;
        return value - (floored * divisor);
    }

    public static String hslToHex(Decimal h, Decimal s, Decimal l) {
        // Normalize S and L from 0-100 to 0-1
        s = s / 100.0;
        l = l / 100.0;

        // Chroma: how "colorful" the color is at this lightness
        Decimal c = (1 - Math.abs(2 * l - 1)) * s;

        // Intermediate value based on hue position
        Decimal x = c * (1 - Math.abs(decimalMod(h / 60.0, 2) - 1));

        // Match value to add to all channels to achieve target lightness
        Decimal m = l - c / 2.0;

        // Assign R, G, B based on which 60° sector the hue falls into
        Decimal r = 0, g = 0, b = 0;
        if (h < 60)       { r = c; g = x; b = 0; }
        else if (h < 120) { r = x; g = c; b = 0; }
        else if (h < 180) { r = 0; g = c; b = x; }
        else if (h < 240) { r = 0; g = x; b = c; }
        else if (h < 300) { r = x; g = 0; b = c; }
        else              { r = c; g = 0; b = x; }

        // Add the match value and scale to 0-255
        Integer ri = Integer.valueOf(Math.round((r + m) * 255));
        Integer gi = Integer.valueOf(Math.round((g + m) * 255));
        Integer bi = Integer.valueOf(Math.round((b + m) * 255));

        return '#' + toHexPair(ri) + toHexPair(gi) + toHexPair(bi);
    }

    public static String shiftLightness(String hex, Decimal amount) {
        HSL hsl = hexToHsl(hex);
        Decimal newL = Math.min(100, Math.max(0, hsl.l + amount));
        return hslToHex(hsl.h, hsl.s, newL);
    }

    public static String adjustLightness(String hex, Decimal targetLightness) {
        HSL hsl = hexToHsl(hex);
        targetLightness = Math.min(100, Math.max(0, targetLightness));
        return hslToHex(hsl.h, hsl.s, targetLightness);
    }

    public static String getContrastColor(String hex) {
        hex = hex.removeStart('#');
        Decimal r = hexToInt(hex.substring(0, 2)) / 255.0;
        Decimal g = hexToInt(hex.substring(2, 4)) / 255.0;
        Decimal b = hexToInt(hex.substring(4, 6)) / 255.0;

        // Squared approximation of sRGB gamma correction.
        // Close enough for contrast decisions, avoids needing Math.pow.
        Decimal luminance = 0.2126 * r * r + 0.7152 * g * g + 0.0722 * b * b;
        // Threshold ~0.179 gives WCAG-aligned white-vs-dark decisions
        return luminance > 0.179 ? '#111827' : '#ffffff';
    }

    public class ThemeAttributeWrapper {
        public String brandColor {get; set;}
        public String bgColor {get; set;}
        public String fontFamily {get; set;}
        public String borderRadius {get; set;}
        public ThemeAttributeWrapper(String brandColor, String bgColor, String fontFamily, String borderRadius) {
            this.brandColor = brandColor;
            this.bgColor = bgColor;
            this.fontFamily = fontFamily;
            this.borderRadius = borderRadius;
        }
    }
}