import { LightningElement, track } from 'lwc';
import { api } from 'lwc';
import getData from "@salesforce/apex/NegoptimChatterCtrl.getData";
import saveData from "@salesforce/apex/NegoptimChatterCtrl.saveData";
import profilePic from '@salesforce/resourceUrl/ProfilePic';

export default class NegoptimChatter extends LightningElement {
    @api recordId;
    @track records = [];
    @track firstRecord = this.records?.[0];
    @track newCommentText = '';
    @track currentUser;
    @track currentSupplier;
    @track account;

    get showFirstRecord() {
        return this.records?.length >= 1;
    }
    get showSecondRecord() {
        return this.records?.length >= 2;
    }
    get moreComments() {
        return this.records?.slice(1);
    }
    @track showReply = false;
    @track showMoreComments = true;
    @track showMoreCommentsSection = true;
    @track isLoading = true;
    @track totalRecords;
    @track trackPathAct = [];
    // @track commentsSyleClass = 'slds-feed__item-comments';
    get commentsSyleClass() {
        return this.records.length == 0 ? '' : 'slds-feed__item-comments';
    }
    defaultPhoto = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + profilePic + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
    
    connectedCallback() {
        console.log('negoptimChatter connectedCallback - recordId:', this.recordId);
        if (this.recordId) {
            this.loadData();
        } else {
            console.warn('No recordId provided to negoptimChatter component');
            this.isLoading = false;
        }
    }

    loadData() {
        console.log('Loading data for clause ID:', this.recordId);
        this.isLoading = true;
        
        getData({ recordId: this.recordId })
            .then((data) => {
                console.log('Data retrieved from Apex:', data);
                const result = JSON.parse(data);
                console.log('Parsed result:', result);
                
                // Store current user and supplier for saving comments
                this.currentUser = result.currentUser;
                this.currentSupplier = result.currentSupplier;
                this.account = result.currentSupplier?.Account__c || null;
                
                // Process track activities (comments)
                const trackActivities = result.trackActivities || [];
                this.processTrackActivities(trackActivities);
                
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error loading data:', error);
                this.isLoading = false;
            });
    }

    processTrackActivities(trackActivities) {
        // Reset arrays
        this.records = [];
        this.trackPathAct = [];
        
        trackActivities.forEach((act, idx, list) => {
            console.log('Processing track action record:', act);
            const url = act?.AssigneeIconURL__c || profilePic;
            const photoStyle = `width:30px;height:30px; opacity:0.5;
                                background-image:url(${url});
                                background-size:contain;
                                background-position:left;
                                background-repeat:no-repeat;`;

            const act2 = {
                ...act,
                photoStyle,
                leftIconStyle: `width:30px;height:30px; opacity:0.5;
                                background-image:url(${act.StatusIconURL__c || profilePic});
                                background-size:contain;
                                background-position:left;
                                background-repeat:no-repeat;`,
                rightIconStyle: photoStyle,
                dashStyle: idx === list.length - 1
                    ? 'padding-bottom:3rem;'
                    : 'border-left:1px dashed black;'
            };

            // Separate comments from track path activities
            if (act?.Comment__c != null && act?.Comment__c !== '') {
                this.records.push(act2);
            } else {
                this.trackPathAct.push(act2);
            }
        });

        console.log('Processed records (comments):', this.records);
        console.log('Processed trackPathAct:', this.trackPathAct);

        this.totalRecords = this.records.length;
        
        this.showReply = true;
        
        if (this.records.length <= 2) {
            this.showMoreCommentsSection = false;
        }
        
        this.firstRecord = this.showFirstRecord ? this.records[0] : null;
    }
    handleAddReply() {
        this.showReply = !this.showReply;
    }
    handleShowAllComments() {
        this.showMoreComments = true;
    }
    handleHideAllComments() {
        this.showMoreComments = false;
    }
    handleSaveComment() {
        console.log('handleSaveComment - START');
        console.log('recordId (clause ID):', this.recordId);
        console.log('newCommentText:', this.newCommentText);
        console.log('currentUser:', this.currentUser);
        console.log('account:', this.account);
        
        if (!this.newCommentText || this.newCommentText.trim() === '') {
            console.warn('Cannot save empty comment');
            return;
        }
        
        if (!this.recordId) {
            console.error('No recordId (clause ID) available');
            return;
        }
        
        this.showReply = false;
        const commentText = this.newCommentText.trim();
        this.newCommentText = ''; // Clear textarea immediately
        
        // Save to database via Apex
        saveData({ 
            recordId: this.recordId, // This is the clause ID
            comment: commentText, 
            account: this.account || null, 
            currentUser: JSON.stringify(this.currentUser) 
        })
            .then((data) => {
                console.log('Comment saved successfully, refreshing data...');
                // Reload data to get the saved comment from the database
                this.loadData();
            })
            .catch((error) => {
                console.error('Error saving comment:', error);
                // Show error to user (you might want to add toast notification here)
                alert('Error saving comment: ' + (error.body?.message || error.message || 'Unknown error'));
            });
    }
    handleAddCommentText(event) {
        this.newCommentText = event.target.value;
    }
    handleCancelComment() {
        this.newCommentText = '';
    }
}