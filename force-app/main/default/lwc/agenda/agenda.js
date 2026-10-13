import { LightningElement, api, track, wire } from 'lwc';
import FilterIcon from "@salesforce/resourceUrl/FilterIcon";
import ProfilePic from "@salesforce/resourceUrl/ProfilePic";
import ContactIcon from "@salesforce/resourceUrl/ContactIcon";
import ContactIconBlue from "@salesforce/resourceUrl/ContactIconBlue";
import getTaskInfoList from '@salesforce/apex/AgendaController.getTaskInfoList';
import getTaskWrappers from '@salesforce/apex/AgendaController.getTaskWrappers';
import getTaskDetails from '@salesforce/apex/AgendaController.getTaskDetails';
import getCurrentMonthTasks from '@salesforce/apex/AgendaController.getCurrentMonthTasks';
import getLabels from '@salesforce/apex/AgendaController.getLabels';
import LBL_Upcoming_Tasks_List from '@salesforce/label/c.LBL_Upcoming_Tasks_List';
import LBL_Show_List from '@salesforce/label/c.LBL_Show_List';
import LBL_Upcoming_Days from '@salesforce/label/c.LBL_Upcoming_Days';
import LBL_Custom_Message_Today from '@salesforce/label/c.LBL_Custom_Message_Today';
import LBL_Custom_Message_All_Days from '@salesforce/label/c.LBL_Custom_Message_All_Days';
import LBL_Due_Next_Seven_Days from '@salesforce/label/c.LBL_Due_Next_Seven_Days';
import LBL_Due_Next_Thirty_Days from '@salesforce/label/c.LBL_Due_Next_Thirty_Days';
import LBL_Due_Next_Ninty_Days from '@salesforce/label/c.LBL_Due_Next_Ninty_Days';
import LBL_Due_Immediatly from '@salesforce/label/c.LBL_Due_Immediatly';
import LBL_All_Tasks from '@salesforce/label/c.LBL_All_Tasks';
import LBL_Placeholder from '@salesforce/label/c.LBL_Placeholder';
import LBL_Show_Selected_Task from '@salesforce/label/c.LBL_Show_Selected_Task';
import LBL_Jan from '@salesforce/label/c.LBL_Jan';
import LBL_Feb from '@salesforce/label/c.LBL_Feb';
import LBL_Mar from '@salesforce/label/c.LBL_Mar';
import LBL_Apr from '@salesforce/label/c.LBL_Apr';
import LBL_May from '@salesforce/label/c.LBL_May';
import LBL_Jun from '@salesforce/label/c.LBL_Jun';
import LBL_Jul from '@salesforce/label/c.LBL_Jul';
import LBL_Aug from '@salesforce/label/c.LBL_Aug';
import LBL_Sept from '@salesforce/label/c.LBL_Sept';
import LBL_Oct from '@salesforce/label/c.LBL_Oct';
import LBL_Nov from '@salesforce/label/c.LBL_Nov';
import LBL_Dec from '@salesforce/label/c.LBL_Dec';
import LBL_Sunday from '@salesforce/label/c.LBL_Sunday';
import LBL_Monday from '@salesforce/label/c.LBL_Monday';
import LBL_Tuesday from '@salesforce/label/c.LBL_Tuesday';
import LBL_Wednesday from '@salesforce/label/c.LBL_Wednesday';
import LBL_Thursday from '@salesforce/label/c.LBL_Thursday';
import LBL_Friday from '@salesforce/label/c.LBL_Friday';
import LBL_Saturday from '@salesforce/label/c.LBL_Saturday';
import LBL_Click_To_View_Details from '@salesforce/label/c.LBL_Click_To_View_Details';
import LBL_To_Do from '@salesforce/label/c.LBL_To_Do';
import Task from '@salesforce/schema/Task';
import Status from '@salesforce/schema/Task.Status';
import Priority from '@salesforce/schema/Task.Priority';
import Description from '@salesforce/schema/Task.Description';
import { NavigationMixin } from 'lightning/navigation';
import LANG from '@salesforce/i18n/lang';
const API_NAMES = {
    Task: {
        objectApiName: Task.objectApiName,
        Status: Status.fieldApiName,
        Priority: Priority.fieldApiName,
        Description: Description.fieldApiName
    }
}

//Status: Status.fieldApiName ==> Status.fieldApiName = Status
const _getTaskInfoList = (self, dueDate, selectedDate, searchTerm) => {
    self.closeFilterOptions();
    getTaskInfoList({
        dueDate: dueDate,
        selectedDate: selectedDate,
        searchTerm: searchTerm,
    }).then(result => {
        self.TaskInfoList = JSON.parse(JSON.stringify(result));
        self.taskInfoList = result.slice(0, 4);
        self.showViewAllLink = result.length > 4;
        self.TaskInfoList.forEach(item => {
            item.TaskClass = item[API_NAMES.Task.Status] === 'Completed' ? ' task-comp' : 'task-details';
            item.TaskClass = item[API_NAMES.Task.Status] === 'Completed' ? ' task-comp' : 'task-lil';
            item.IsCompleted = item[API_NAMES.Task.Status] === 'Completed'
        });
    }).catch(error => {
        console.error('Error fetching tasks:', error);
    });
}
export default class Agenda extends NavigationMixin(LightningElement) {

    handleDateClick(event) {
        this.showProfileUser = false;
        this.showSelectedDayMessage = true;
        this.showCustomMessage = false;
        this.dueDate = null;
        const selectedDay = event.currentTarget.dataset.day;
        const test = event.currentTarget.dataset.test;
        const formattedMonth = this.month + 1 < 10 ? '0' + (this.month + 1) : (this.month + 1);
        const formattedDay = selectedDay < 10 ? '0' + selectedDay : selectedDay;
        const selectedDate = this.year + '-' + formattedMonth + '-' + formattedDay;
        this.SelectedActivityDate = selectedDate;
        this.selectedDate = selectedDate;
        const existingCircles = this.template.querySelectorAll('.circle');
        existingCircles.forEach(circle => {
            circle.remove();
        });

        // Create and append a circle to the clicked date
        const clickedDateElement = event.currentTarget;
        const circle = document.createElement('div');
        circle.className = 'circle';
        // circle.style.backgroundColor = 'yellow';
        circle.style.border = '1px solid #00B7BC';
        circle.style.width = '30px';
        circle.style.height = '30px';
        circle.style.borderRadius = '50%';
        circle.style.position = 'absolute';
        circle.style.top = '50%';
        circle.style.left = '50%';
        circle.style.transform = 'translate(-50%, -50%)';
        clickedDateElement.appendChild(circle);
        _getTaskInfoList(this, null, selectedDate, this.searchTerm);
    }


    @wire(getTaskWrappers)
    wiredTaskWrappersJSON({ error, data }) {
        if (data) {
            this.taskWrappers = JSON.parse(data);
        } else if (error) {
            console.error(error);
        }
    }

    handleTaskDetailsClick(event) {
        const taskId = event.currentTarget.dataset.id;
        this.showProfileUser = true;

        const element = this.template.querySelector('.negoptim-mainprof');
        if (element) {
            const rect = element.getBoundingClientRect();
            const x = rect.left + window.scrollX;
            const y = rect.top + window.scrollY - 100;
            window.scrollTo(x, y);
        }

        getTaskDetails({ taskId })
            .then(result => {
                const { description, status, priority, ownerName, ownerTitle, fullPhotoUrl, accountName } = result;
                this.displayedTask.Priority = this.priorityPicklistMap[priority];
                this.displayedTask.Description = description;
                this.displayedTask.Status = this.statusPicklistMap[status];
                this.displayedTask.ownerName = ownerName;
                this.displayedTask.ownerTitle = ownerTitle;
                this.displayedTask.accountName = accountName;
                this.displayedTask.ProfilePic = `background-image:url('${fullPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px; position: absolute`;
            })
            .catch(error => {
                console.error(error);
            });
    }

    @track FilterIcon = `top: -1px;;max-width: 15px; height:17px; background-image: url('${FilterIcon}'); background-position: left center`;
    @track ContactIcon = `top: 1px;;max-width: 25px; height:36px; background-image: url('${ContactIcon}'); background-position: left center`;
    @track ContactIconBlue = `top: 1px;;max-width: 25px; height:36px; background-image: url('${ContactIconBlue}'); background-position: left center`;
    @track ProfilePic = `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px; position: absolute`;

    @track date = new Date();//gets the current date//
    @track year = this.date.getFullYear(); //gets the current year//
    @track month = this.date.getMonth(); //gets the current month (index based, 0-11)//
    @track calenderDates = [];
    @track TaskInfoList = [];
    @track searchTerm = '';
    @track selectedDate;
    @track showProfileUser = false;
    @track filterDay;
    @track customMessage = '';
    @track showViewAllLink = false;
    // taskActivityDates = [];
    taskWrappers = {};
    @track displayedTask = {
        Priority: '',
        Status: '',
        Description: '',
        ownerName: '',
        ownerTitle: '',
        ProfilePic: '',
        accountName: ''
    };

    @track showYearDropdown = false;
    yearOptions = [];
    currentMonthTasks = [];
    currentDate = '';
    previousMonth = '';
    currentMonth = '';
    nextMonth = '';
    dueDate;
    isNavigating = false;
    months = [
        LBL_Jan,
        LBL_Feb,
        LBL_Mar,
        LBL_Apr,
        LBL_May,
        LBL_Jun,
        LBL_Jul,
        LBL_Aug,
        LBL_Sept,
        LBL_Oct,
        LBL_Nov,
        LBL_Dec
    ]; // array of month names//

    filterDropdownClass = 'dropdown hidden'; // Initialize as hidden

    @track label = {
        LBL_Upcoming_Tasks_List: LBL_Upcoming_Tasks_List,
        LBL_Show_List: LBL_Show_List,
        LBL_Upcoming_Days: LBL_Upcoming_Days,
        LBL_Due_Next_Seven_Days: LBL_Due_Next_Seven_Days,
        LBL_Due_Next_Thirty_Days: LBL_Due_Next_Thirty_Days,
        LBL_Due_Next_Ninty_Days: LBL_Due_Next_Ninty_Days,
        LBL_Due_Immediatly: LBL_Due_Immediatly,
        LBL_All_Tasks: LBL_All_Tasks,
        LBL_Sunday: LBL_Sunday,
        LBL_Monday: LBL_Monday,
        LBL_Tuesday: LBL_Tuesday,
        LBL_Wednesday: LBL_Wednesday,
        LBL_Thursday: LBL_Thursday,
        LBL_Friday: LBL_Friday,
        LBL_Saturday: LBL_Saturday,
        LBL_Placeholder: LBL_Placeholder,
        LBL_Show_Selected_Task: LBL_Show_Selected_Task,
        LBL_Click_To_View_Details: LBL_Click_To_View_Details,
        LBL_To_Do: LBL_To_Do,
    }
    statusPicklistMap = {};
    priorityPicklistMap = {};
    connectedCallback() {
        this.Agenda = true

        const dateElements = this.template.querySelectorAll('.calendar-dates .date');
        dateElements.forEach(date => {
            date.addEventListener('click', this.handleDateClick.bind(this));
        });

        getCurrentMonthTasks().then(result => {
            this.currentMonthTasks = result;
            this.handleCalender();
            this.setYearOptions();
        }).catch(error => {
            console.error('Error fetching all tasks:', error);
        });

        getLabels(LANG).then(result => {
            let parsedResult = JSON.parse(result);
            this.label = { ...this.label, ...parsedResult.fieldsLabel };
            let fieldsLabelsMap = parsedResult.fieldLabelsMap;
            this.statusPicklistMap = parsedResult.statusPicklistMap;
            this.priorityPicklistMap = parsedResult.priorityPicklistMap;
            this.label['LBL_Status'] = fieldsLabelsMap[API_NAMES.Task.Status];
            this.label['LBL_Priority'] = fieldsLabelsMap[API_NAMES.Task.Priority];
            this.label['LBL_Description'] = fieldsLabelsMap[API_NAMES.Task.Description];
            console.log('Labels loaded:', this.label);
        }).catch(error => {
            console.error('Error fetching all tasks:', error);
        });

        const selectedFilter = localStorage.getItem('selectedFilter');
        this.customMessage = localStorage.getItem('customMessage');
        this.filterDay = localStorage.getItem('filterDay');
        if (selectedFilter) {
            this.selectedDate = new Date().toISOString().split('T')[0];
            switch (selectedFilter) {
                case 'Next7Days':
                    this.dueDate = this.calculateDueDate(7);
                    this.filterDay = '7';
                    this.showCustomMessage = false;
                    this.showSelectedDayMessage = false;
                    break;
                case 'Next30Days':
                    this.dueDate = this.calculateDueDate(30);
                    this.filterDay = '30';
                    this.showCustomMessage = false;
                    this.showSelectedDayMessage = false;
                    break;
                case 'Next90Days':
                    this.dueDate = this.calculateDueDate(90);
                    this.filterDay = '90';
                    this.showCustomMessage = false;
                    this.showSelectedDayMessage = false;
                    break;
                case 'DueImmediately':
                    // Due immediately means today's date
                    this.dueDate = 'TODAY';
                    this.showCustomMessage = true;
                    this.customMessage = LBL_Custom_Message_Today;
                    this.showSelectedDayMessage = false;
                    break;
                case 'AllTasks':
                    this.dueDate = null;
                    this.selectedDate = null;
                    this.showCustomMessage = true;
                    this.customMessage = LBL_Custom_Message_All_Days;
                    this.showSelectedDayMessage = false;
                    break;
                default:
                    return;
            }
        } else {
            this.setFilterAndSave('AllTasks', null, LBL_Custom_Message_All_Days);
            this.getAllTasks();
            this.showCustomMessage = true;
            this.customMessage = LBL_Custom_Message_All_Days;
            this.showSelectedDayMessage = false;
            return;
        }
        // this.fetchFilteredTasks(selectedFilter);
        _getTaskInfoList(this, this.dueDate, this.selectedDate || null, this.searchTerm);
    }
    //Calendar Code//
    handleCalender() {
        // get the first day of the month//
        let dayone = new Date(this.year, this.month, 1).getDay();
        // get the last date of the month//
        let lastdate = new Date(this.year, this.month + 1, 0).getDate();
        // get the day of the last date of the month//
        let dayend = new Date(this.year, this.month, lastdate).getDay();
        // get the last date of the previous month //
        let monthlastdate = new Date(this.year, this.month, 0).getDate();
        // loop to add the last dates of the previous month//
        for (let i = dayone; i > 0; i--) {
            this.handleBuildDynamicCalender((monthlastdate - i + 1), this.month, 'previous')
        }
        // loop to add the dates of the current month//
        for (let i = 1; i <= lastdate; i++) {
            this.handleBuildDynamicCalender(i, (this.month + 1), 'current')
        }
        // loop to add the first dates of the next month//
        for (let i = dayend; i < 6; i++) {
            this.handleBuildDynamicCalender((i - dayend + 1), (this.month + 2), 'next')
        }

        // Calculate previous and next months
        let previousMonthIndex = this.month - 1;
        let currentMonthIndex = this.month;
        let nextMonthIndex = this.month + 1;
        let previousYear = this.year;
        let nextYear = this.year;

        // Adjust for previous and next year if necessary
        if (previousMonthIndex < 0) {
            previousMonthIndex = 11; // December
            previousYear = this.year - 1;
        }
        if (nextMonthIndex > 11) {
            nextMonthIndex = 0; // January
            nextYear = this.year + 1;
        }
        this.currentDate = `${this.year}`
        this.previousMonth = `${this.months[previousMonthIndex]}`
        this.currentMonth = `${this.months[currentMonthIndex]}`
        this.nextMonth = `${this.months[nextMonthIndex]}`
        // this.currentDate=`${this.months[this.month]} ${this.year}`
    }
    //function to create a calendar with every pin//
    handleBuildDynamicCalender(day, month, monthStatus) {
        let inactive = '';
        //if the date is from next month or the previous month,Add an inactive class to it //
        if (monthStatus == 'previous' || monthStatus == 'next') inactive = 'inactive';
        // Get the day of the week (0 for Sunday, 1 for Monday, ..., 6 for Saturday)
        let dayOfWeek = new Date(this.year, month - 1, day).getDay();

        // Define an array to hold the day abbreviations
        let dayAbbreviations = [
            LBL_Sunday,
            LBL_Monday,
            LBL_Tuesday,
            LBL_Wednesday,
            LBL_Thursday,
            LBL_Friday,
            LBL_Saturday
        ];
        //this variable holds the date of today//
        //

        // Check if the current calendar date matches any task date
        let hasTask = this.currentMonthTasks.some(task => {
            const taskDate = new Date(task.ActivityDate).getDate();
            const taskMonth = new Date(task.ActivityDate).getMonth() + 1;
            const taskYear = new Date(task.ActivityDate).getFullYear();
            return day === taskDate && month === taskMonth && this.year === taskYear;
        });

        // Add the circle class based on whether there are tasks due on this date
        let circleClass = '';
        if (hasTask) {
            circleClass = 'has-task';
        }

        let isToday = day === this.date.getDate() && month === new Date().getMonth() + 1 && this.year === new Date().getFullYear() ? "active" : ""

        // Construct the parent classes for the calendar date element
        let parentClasses = `ov cw circle-cal parent-circle ${circleClass} ${inactive}`;

        this.calenderDates.push({
            'nb': day,
            'parentClasses': parentClasses + isToday,
            'dayAbbr': dayAbbreviations[dayOfWeek] // Adding the day abbreviation
        })
    }


    handleChangeMonth(event) {
        let id = event.target.dataset.id;
        if (this.isNavigating) return;
        this.isNavigating = true;
        if (id === "calendar-prev") {
            this.month -= 1;
            if (this.month < 0) {
                this.month = 11;
                this.year -= 1;
            }
        } else if (id === "calendar-next") {
            this.month += 1;
            if (this.month > 11) {
                this.month = 0;
                this.year += 1;
            }

        }
        this.calenderDates = [];
        getCurrentMonthTasks({ year: this.year, month: this.month + 1 })
            .then(result => {
                this.currentMonthTasks = result;
                this.handleCalender();
                // this.setYearOptions();
                this.isNavigating = false;
            })
            .catch(error => {
                console.error('Error fetching all tasks:', error);
                this.isNavigating = false;
            });
    }

    setYearOptions() {
        const currentYear = new Date().getFullYear();
        const range = 5; // Number of years before and after the current year
        const startYear = currentYear - range;
        const endYear = currentYear + range;

        for (let year = startYear; year <= endYear; year++) {
            this.yearOptions.push(year);
        }
    }

    toggleYearDropdown() {
        this.showYearDropdown = !this.showYearDropdown;
    }

    closeyouroption() {
        this.showYearDropdown = false;
    }

    handleYearChange(event) {
        const selectedYear = parseInt(event.target.value);
        this.year = selectedYear;
        this.calenderDates = [];
        this.handleCalender();
        this.showYearDropdown = false;
        this.calenderDates = [];
        getCurrentMonthTasks({ year: this.year, month: this.month + 1 })
            .then(result => {
                this.currentMonthTasks = result;
                this.handleCalender();
            })
            .catch(error => {
                console.error('Error fetching all tasks:', error);
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        _getTaskInfoList(this, this.dueDate, this.selectedDate || null, this.searchTerm);
    }


    closeFilterOptions() {
        this.filterDropdownClass = 'dropdown hidden';
    }
    toggleFilterOptions() {
        this.filterDropdownClass = this.filterDropdownClass.includes('hidden') ? 'dropdown' : 'dropdown hidden';
    }

    handleFilterOptionSelect(event) {
        this.showProfileUser = false;
        const selectedFilter = event.target.dataset.filter;
        this.selectedDate = new Date().toISOString().split('T')[0];
        switch (selectedFilter) {
            case 'Next7Days':
                this.dueDate = this.calculateDueDate(7);
                this.filterDay = '7';
                this.setFilterAndSave(selectedFilter, '7');
                this.showCustomMessage = false;
                this.showSelectedDayMessage = false;
                break;
            case 'Next30Days':
                this.dueDate = this.calculateDueDate(30);
                this.filterDay = '30';
                this.setFilterAndSave(selectedFilter, '30');
                this.showCustomMessage = false;
                this.showSelectedDayMessage = false;
                break;
            case 'Next90Days':
                this.dueDate = this.calculateDueDate(90);
                this.filterDay = '90';
                this.setFilterAndSave(selectedFilter, '90');
                this.showCustomMessage = false;
                this.showSelectedDayMessage = false;
                break;
            case 'DueImmediately':
                // Due immediately means today's date
                this.dueDate = 'TODAY';
                this.showCustomMessage = true;
                this.setFilterAndSave(selectedFilter, null, LBL_Custom_Message_Today);
                this.customMessage = LBL_Custom_Message_Today;
                this.showSelectedDayMessage = false;
                break;
            case 'AllTasks':
                this.dueDate = null;
                this.selectedDate = null;
                this.showCustomMessage = true;
                this.setFilterAndSave(selectedFilter, null, LBL_Custom_Message_All_Days);
                this.customMessage = LBL_Custom_Message_All_Days;
                this.showSelectedDayMessage = false;
                break;
            default:
                return;
        }
        _getTaskInfoList(this, this.dueDate, this.selectedDate || null, this.searchTerm);
    }

    setFilterAndSave(selectedFilter, filterDay, customMessage) {
        // Save the selected filter and its corresponding value in localStorage
        localStorage.setItem('selectedFilter', selectedFilter);
        localStorage.setItem('filterDay', filterDay);
        localStorage.setItem('customMessage', customMessage);
        // Update component's tracked property
        this.filterDay = filterDay;
        this.customMessage = customMessage;
    }

    calculateDueDate(days) {
        const currentDate = new Date();
        currentDate.setDate(currentDate.getDate() + days);
        return currentDate.toISOString().split('T')[0];
    }

    getAllTasks() {
        this.dueDate = null;
        _getTaskInfoList(this, null, null, null);
    }

    handleViewAllClick() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: sRecordId,
                objectApiName: 'Task',
                url: '/all-tasks-community-page',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }


    handleActiveClass(event) {
        // Remove "activeclicked" class from all negoptim-container elements
        const allContainers = this.template.querySelectorAll('.negoptim-container');
        if (allContainers) {
            allContainers.forEach(container => {
                container.classList.remove('activeclicked');
            });
        }
        // Get the clicked negoptim-container
        // const negoptimcontainer = event.currentTarget.closest('.negoptim-container');
        // const negoptimcontainer = event.target.parentElement;
        const negoptimcontainer = event.target.closest('.negoptim-container');
        // Add "activeclicked" class to the clicked negoptim-container
        if (negoptimcontainer) {
            negoptimcontainer.classList.add('activeclicked');
        }
    }


}