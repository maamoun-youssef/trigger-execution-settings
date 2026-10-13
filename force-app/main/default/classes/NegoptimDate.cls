global with sharing class NegoptimDate {
    
    public class NegoptimDateException Extends Exception {}
    
    private static Map<String, Integer> monthsMap = new Map<String, Integer> {
        'JANUARY' => 1,
            'FEBRUARY' => 2,
            'MARCH' => 3,
            'APRIL' => 4,
            'MAY' => 5,
            'JUNE' => 6,
            'JULY' => 7,
            'AUGUST' => 8,
            'SEPTEMBER' => 9,
            'OCTOBER' => 10,
            'NOVEMBER' => 11,
            'DECEMBER' => 12
    };
    
    private static Map<String, Integer> monMap = new Map<String, Integer> {
        'JAN' => 1,
            'FEB' => 2,
            'MAR' => 3,
            'APR' => 4,
            'MAY' => 5,
            'JUN' => 6,
            'JUL' => 7,
            'AUG' => 8,
            'SEP' => 9,
            'OCT' => 10,
            'NOV' => 11,
            'DEC' => 12
	};
    
    /**
     * @author ULIT
     * Parses date strings and return a date object of the user's specific date format chosen from Global Settings
     * @param dateValue: date to be parsed 25-09-2018
     * @param dateFormat: dd-mm-yyyy
     */
    static global Date parseDate(String dateValue, String dateFormat) {
        if (dateValue == null || dateValue == '') {
            throw new negoptimDateException('SECOND PARAMETER NULL OR EMPTY');
        }
        if (dateFormat == null || dateFormat ==  '') {
            throw new negoptimDateException('FIRST PARAMETER NULL OR EMPTY');
        }
        Integer day, month, year;
        String separator;
        List<String> tokens = new List<String>();
        String separatorRegex;
        if(!dateFormat.containsIgnoreCase('mon') || dateFormat.endsWithIgnoreCase('mon') 
           || dateFormat.endsWithIgnoreCase('month')) { // 14-03-2018 or 03-14-2018 or 2018-14-march ...
               separatorRegex = '(?i)[dmy]{2,4}(.+?)(?i)[dmy]{2,4}';   
           } else {
               if(dateFormat.startsWithIgnoreCase('month')) { // march-14-2018
                   separatorRegex = '(?i)month(.+?)(?i)[dy]{2,4}';
               } else if (dateFormat.startsWithIgnoreCase('mon')) { //mar-14-2018
                   separatorRegex = '(?i)mon(.+?)(?i)[dy]{2,4}';
               } else {
                   separatorRegex = '(?i)[dy]{2,4}(.+?)(?i)mon';
               }
           }
        Pattern separatorPattern = Pattern.compile(separatorRegex);
        Matcher separatorMatcher = separatorPattern.matcher(dateFormat);
        if (separatorMatcher.find()){
            separator = separatorMatcher.group(1);
        } else {
            throw new NegoptimDateException('INVALID DATE FORMAT');
        }
        //add separator to end of dateFormat to capture last token
        dateFormat += separator;
        String regex = '(.+?)' + separator + '{1}';
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(dateFormat);
        while (m.find()){
            tokens.add(m.group(1));
        }
        String[] numbers = dateValue.split(separator); 
        if (numbers.size() == 3) {
            for (Integer index = 0; index < 3; index++){
                if (tokens[index].equalsIgnoreCase('dd')) {
                    day = Integer.valueOf(numbers[index]);
                }
                if (tokens[index].equalsIgnoreCase('mm')) {
                    month = Integer.valueOf(numbers[index]);
                }
                if (tokens[index].equalsIgnoreCase('mon') || tokens[index].equalsIgnoreCase('month')) {
                    month = convertMonthTextToNumber(numbers[index].toUpperCase());
                }
                if(tokens[index].equalsIgnoreCase('yyyy')) {
                    year = Integer.valueOf(numbers[index]);
                }
                if(tokens[index].equalsIgnoreCase('yy')) {
                    year = Integer.valueOf(numbers[index]) + 2000;
                }
            } 
        } else {
            throw new NegoptimDateException('INVALID DATE ACCORDING TO FORMAT');
        }
        if (isValidDate(day, month, year)) {
            Date parsedDate = Date.newInstance(year, month, day);
            return parsedDate;
        } else {
            throw new NegoptimDateException('INVALID DATE');
        }
    }
    
    /*
     * Get month numeric value from the month's name or abreviation
     * 
     * **/
    
    static global Integer convertMonthTextToNumber(String monthName){
        return monthName.length() == 3 ? monMap.get(monthName): monthsMap.get(monthName);
    }
    
    /*
     * Checks if date is valid
     * @param day:
     * between 1 and 30 for months 4 - 6 - 9 - 11
     * between 1 and 31 for months 1 - 3 - 5 -  7 - 8 - 10 - 12			
     * 28 if month 2 and leap year
     * 
     * @param month: between 1 and 12
     * 
     * */
    private static Boolean isValidDate(Integer day, Integer month, Integer year){
        Boolean valid = true;
        Integer[] month30 = new Integer[]{4, 6, 9, 11};
        Integer[] month31 = new Integer[]{1, 3, 5, 7, 8, 10, 12};
		
        if ((month == 2) && (day <= 29 && day >= 1) && isLeapYear(year)) {
            return true;
        } else if ((month == 2) && (day <=28 && day >= 1)) {
            return true;
        } else if ((month30.contains(month)) && (day <= 30 && day >= 1)) {
            return true;
        } else if ((month31.contains(month)) && (day <= 31 && day >= 1)) {
            return true;
        } else {
            return false;
        }
    }
    
    /*
     * Checks if year is Leap year (february has 29 days)
     * 
     * */
    static global Boolean isLeapYear(Integer year) {
        return (math.mod(year, 4) == 0 && math.mod(year, 100) != 0) || math.mod(year, 400) == 0;
    }

}