global with sharing class ObjectIterable implements Iterator<List<Object>> {
    // NOTE: 'Record' should be replaced with the API name of the object you want to have
    // pagination for.

    // The Iterator interface is used for pagination
    List<Object>InnerList {get; set;}
    // Holds all the values
    List<Object>ListRequested {get; set;}
    // Holds the value to be displayed on the Page
    Integer i {get; set;}
    global Integer setPageSize {get; set;}
    global Integer pageNumber {get; set;}

    // Constructor
    global ObjectIterable(List<Object> lstAccWr) {
        InnerList = new List<Object>();
        ListRequested = new List<Object>();
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

    global List<Object> first() {
        ListRequested = new List<Object>();
        i = 0;
        pageNumber = 0;
        return this.next();
    }

    global List<Object> next() {
        ListRequested = new List<Object>();
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

    global List<Object> previous() {
        ListRequested = new List<Object>();
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

    global List<Object> last() {
        ListRequested = new List<Object>();
        while (this.hasNext()) {
            ListRequested = this.next();
        }
        return ListRequested;
    }

    global List<Object> setPageSize(Integer pageSize) {
        ListRequested = new List<Object>();
        setPageSize = pageSize;
        pageNumber = 0;
        i = 0;
        return this.next();
    }
}