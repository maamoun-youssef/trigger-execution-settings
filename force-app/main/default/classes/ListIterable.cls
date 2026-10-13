global with sharing class ListIterable implements Iterator<List<AggregateResult>> {
    // NOTE: 'Record' should be replaced with the API name of the object you want to have
    // pagination for.

    // The Iterator interface is used for pagination
    List<AggregateResult>InnerList {get; set;}
    // Holds all the values
    List<AggregateResult>ListRequested {get; set;}
    // Holds the value to be displayed on the Page
    Integer i {get; set;}
    public Integer setPageSize {get; set;}
    public Integer pageNumber {get; set;}

    // Constructor
    public ListIterable(List<AggregateResult> lstAccWr) {
        InnerList = new List<AggregateResult>();
        ListRequested = new List<AggregateResult>();
        InnerList = lstAccWr;
        setPageSize = 10;
        pageNumber = 0;
        i = 0;
    }

    global boolean hasNext() {
        if (i >= InnerList.size()) {
            return false;
        } else {
            return true;
        }
    }

    global boolean hasPrevious() {
        if (i <= setPageSize) {
            return false;
        } else {
            return true;
        }
    }

    global boolean getHasNext() {
        return hasNext();
    }

    global boolean getHasPrevious() {
        return hasPrevious();
    }

    global List<AggregateResult> first() {
        ListRequested = new List<AggregateResult>();
        i = 0;
        pageNumber = 0;
        return this.next();
    }

    global List<AggregateResult> next() {
        ListRequested = new List<AggregateResult>();
        Integer startNumber;
        Integer size = InnerList.size();
        if (hasNext()) {
            if (size <= (i + setPageSize)) {
                startNumber = i;
                i = size;
            } else {
                i = (i + setPageSize);
                startNumber = (i - setPageSize);
            }
            for (Integer start = startNumber; start < i; start++) {
                ListRequested.add(InnerList[start]);
            }
        }
        pageNumber++;
        return ListRequested;
    }

    global List<AggregateResult> previous() {
        ListRequested = new List<AggregateResult>();
        Integer size = InnerList.size();
        if (i == size) {
            if (math.mod(size, setPageSize) > 0) {
                i = size - math.mod(size, setPageSize);
            } else {
                i = (size - setPageSize);
            }
        } else {
            i = (i - setPageSize);
        }
        for(Integer start = (i - setPageSize); start < i; ++start) {
            ListRequested.add(InnerList[start]);
        }
        pageNumber--;
        return ListRequested;
    }

    global List<AggregateResult> last() {
        ListRequested = new List<AggregateResult>();
        while (this.hasNext()) {
            ListRequested = this.next();
        }
        return ListRequested;
    }

    global List<AggregateResult> setPageSize(Integer pageSize) {
        ListRequested = new List<AggregateResult>();
        setPageSize = pageSize;
        pageNumber = 0;
        i = 0;
        return this.next();
    }
}