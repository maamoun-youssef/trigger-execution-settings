@isTest
private class NegoptimDateTest {
    @isTest static void main(){
        Date parsedDate = Date.newInstance(2018, 3, 14);
        System.assertEquals(parsedDate, NegoptimDate.parseDate('03-14-2018', 'mm-dd-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-03-2018', 'dd-mm-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018-03-14', 'yyyy-mm-dd'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018-14-03', 'yyyy-dd-mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('03/14/2018', 'mm/dd/yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14/03/2018', 'dd/mm/yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/03/14', 'yyyy/mm/dd'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/14/03', 'yyyy/dd/mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/14/03', 'yyyy/DD/mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/14/03', 'YyYy/DD/mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/14/03', 'yyyy/DD/Mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018/14/03', 'YYYY/dD/mm'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-03-2018', 'dD-mM-yyYy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-03-2018', 'dd-MM-yYYy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-mar-2018', 'dd-mon-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-march-2018', 'dd-mOnth-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-mar-2018', 'dd-Mon-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-march-2018', 'dd-moNtH-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('mar-14-2018', 'moN-dd-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('march-14-2018', 'month-dd-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('march-14-2018', 'mOnTh-dd-yyyy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018-14-march', 'yyyy-dd-month'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('2018-march-14', 'yyyy-month-dd'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('18-march-14', 'yy-month-dd'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-march-18', 'dD-month-yy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('14-mar-18', 'dd-Mon-yy'));
        System.assertEquals(parsedDate, NegoptimDate.parseDate('18-mar-14', 'yy-mon-dd'));
        
        Integer[] leapYears = new Integer[] {2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096};
        Integer[] nonLeapYears = new Integer[] {
            2001, 2002, 2003, 2057, 2005, 2006,2007,2031, 2038,2034
            } ;  
                
        for (Integer year : leapYears){
            System.assertEquals(true, NegoptimDate.isLeapYear(year), year);
        }
        for (Integer year : nonLeapYears){
            System.assertEquals(false, NegoptimDate.isLeapYear(year), year);
        }

    }
}