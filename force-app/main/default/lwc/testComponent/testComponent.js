import { LightningElement, api, track } from 'lwc';

export default class TestComponent extends LightningElement {

    // countryOptionssearchable = [
    //     { label: 'Lebanon', value: 'LB' },
    //     { label: 'France', value: 'FR' },
    //     { label: 'Canada', value: 'CA' },
    //     { label: 'Germany', value: 'DE' }
    // ];

    // selectedValue = 'LB';

    // handlePicklistChangeSearchable(event) {
    //     console.log('Selected value:', event.detail.value);
    //     console.log('Selected label:', event.detail.label);
    //     this.selectedValue = event.detail.value; 
    // }

    //  countryOptions = JSON.stringify([
    //     { label: 'Lebanon', value: 'LB' },
    //     { label: 'France', value: 'FR' },
    //     { label: 'Canada', value: 'CA' },
    //     { label: 'Germany', value: 'DE' }
    // ]);

    // selectedValues = JSON.stringify(['LB']);

    // handlePicklistChange(event) {
    //     console.log('Selected Options:', event.detail.selOptions);
    // }
    // Single Select
    // @track selectedCountry = 'lb';
    // @track selectedCity = '';

    // @track selectedSkills = ['js', 'apex'];
    // @track selectedDepartments = [];

    // countryOptions = [
    //     { label: 'Lebanon', value: 'lb' },
    //     { label: 'France', value: 'fr' },
    //     { label: 'Canada', value: 'ca' },
    //     { label: 'Germany', value: 'de' }
    // ];

    // cityOptions = [
    //     { label: 'Beirut', value: 'beirut' },
    //     { label: 'Paris', value: 'paris' },
    //     { label: 'Montreal', value: 'montreal' },
    //     { label: 'Berlin', value: 'berlin' }
    // ];

    // skillOptions = [
    //     { label: 'JavaScript', value: 'js' },
    //     { label: 'Apex', value: 'apex' },
    //     { label: 'LWC', value: 'lwc' },
    //     { label: 'Java', value: 'java' },
    //     { label: 'SQL', value: 'sql' }
    // ];

    // departmentOptions = [
    //     { label: 'Sales', value: 'sales' },
    //     { label: 'Finance', value: 'finance' },
    //     { label: 'Support', value: 'support' },
    //     { label: 'IT', value: 'it' },
    //     { label: 'HR', value: 'hr' }
    // ];

    // handleCountryChange(event) {
    //     this.selectedCountry = event.detail.value;
    // }

    // handleCityChange(event) {
    //     this.selectedCity = event.detail.value;
    // }

    // handleSkillsChange(event) {
    //     this.selectedSkills = event.detail.values;
    // }

    // handleDepartmentsChange(event) {
    //     this.selectedDepartments = event.detail.values;
    // }

    // get skillsDisplay() {
    //     return this.selectedSkills.join(', ');
    // }

    // get departmentsDisplay() {
    //     return this.selectedDepartments.join(', ');
    // }
     @track selectedValues =  ['lebanon', 'france', 'ssss'];
    
    countryOptions = [
        { label: 'Lebanon', value: 'lebanon', iconName: 'standard:account'},
        { label: 'France', value: 'france' },
        { label: 'UAE', value: 'uae' }
    ];
    options = [
        { label: 'Account', value: 'account', iconName: 'standard:account' },
        { label: 'Contact', value: 'contact', iconName: 'standard:contact' }
    ];
    // options = [
    //     { label: 'User 1', value: 'u1', imgURL: '/resource/user1.png' },
    //     { label: 'User 2', value: 'u2', imgURL: '/resource/user2.png' }
    // ];
    defaultCountry = ['lebanon', 'france', 'ssss'];
    handleSubmit(event) {
        this.selectedValues = JSON.stringify(event.detail.value);
        console.log('values:' + JSON.stringify(this.selectedValues));
    }
    handleChange(event) {
        this.selectedValue = event.detail.value;
        const selectedLabel = event.detail.label;

        console.log('Value:', this.selectedValue);
        console.log('Label:', selectedLabel);
    }

    customPicklistoptions = JSON.stringify([
        { label: 'Option 1', value: 'opt1' },
        { label: 'Option 2', value: 'opt2' },
        { label: 'Option 3', value: 'opt3' }
    ]);

    customselectedValues = JSON.stringify(['opt1']);
    
    handleSelectionchange(event) {
        const selected = event.detail.selOptions;
        console.log('Selected options:', selected);
    }
    // @track name = '';
    // @track amount;

    // // combobox values
    // @track status;
    // @track tags = [];

    // // lookup
    // @track selectedAccount = [];

    // accountSearchFields = ['Name'];

    // // options for combobox
    // statusOptions = [
    //     { label: 'New', value: 'new' },
    //     { label: 'In Progress', value: 'progress' },
    //     { label: 'Closed', value: 'closed' }
    // ];

    // tagOptions = [
    //     { label: 'Important', value: 'important' },
    //     { label: 'VIP', value: 'vip' },
    //     { label: 'Follow Up', value: 'followup' }
    // ];

    // defaultTags = ['vip'];

    // handleChange(event) {
    //     const field = event.target.dataset.field;
    //     this[field] = event.target.value;
    // }

    // handleStatusChange(event) {
    //     this.status = event.detail.value;
    // }

    // handleTagsChange(event) {
    //     this.tags = event.detail.value;
    //     console.log('>>>>>>>>>>>>> selected values:' + JSON.stringify(this.tags));
    // }

    // handleAccountSelected(event) {
    //     this.selectedAccount = event.detail.selRecords;
    // }

    // handleSubmit() {
    //     const payload = {
    //         name: this.name,
    //         amount: this.amount,
    //         status: this.status,
    //         tags: this.tags,
    //         accountId: this.selectedAccount[0]?.recId
    //     };
    //     console.log('Payload:', JSON.stringify(payload));

    //     if (!this.name || !this.selectedAccount.length) {
    //         alert('Fill required fields');
    //         return;
    //     }
    // }
}