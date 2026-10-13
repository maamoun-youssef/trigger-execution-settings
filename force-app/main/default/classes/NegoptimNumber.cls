public with sharing class NegoptimNumber {

    public String decimalLabel {
        get {
            return formatDecimalValue();
        }
        set;
    }
    public String percentageLabel {
        get {
            return formatPercentageValue(true);
        }
        set;
    }
    public decimal value {get; set;}
    public Integer scale {get; set;}

    public NegoptimNumber(Integer scale) {
        this.value = 0;
        this.scale = scale;
    }
    /**
     * Return a string for a decimal with format.
     * */
    public String formatDecimalValue() {
        String rightValue = '';
        rightValue = rightValue.rightPad(scale, '0') + '1';
        String sValue = (value.setScale(scale) + Decimal.valueOf('0.' + rightValue)).format();
        return sValue.substring(0, sValue.length() -1);
    }
    /**
     * Return a string for a number with format percentage.
     * */
    public String formatPercentageValue(Boolean wildcard) {
        String decimalSeparator = getDecimalSeparator();
        String sPercent = value.setScale(scale).format();
        if (sPercent != null && sPercent.trim() != '' && !sPercent.contains(decimalSeparator)) {
            sPercent += decimalSeparator + '00';
        }
        else if(sPercent != null && sPercent.contains(decimalSeparator)) {
            decimalSeparator = decimalSeparator == '.' ? '\\.' : decimalSeparator;
            if (sPercent.split(decimalSeparator)[1].length() < 2) {
                sPercent += '0';
            }
        }
        if(wildcard) {
            sPercent += '%';
        }
        return sPercent;
    }
    /**
     * Return the separator of decimal number based on user locale.
     * */
    public static String getDecimalSeparator() {
        Decimal d = 1.98;
        String sD = d.format();
        return sD.contains(',') ? ',' : '.';
    }
}