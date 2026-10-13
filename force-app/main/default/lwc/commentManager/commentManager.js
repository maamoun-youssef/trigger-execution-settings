import { LightningElement, track } from 'lwc';
import { api } from 'lwc';
// import getData from "@salesforce/apex/CommentManagerCtrl.getData";
import saveData from "@salesforce/apex/CommentManagerCtrl.saveData";
import profilePic from '@salesforce/resourceUrl/ProfilePic';
import { labels, TrackAction_API } from './properties.js';
import { showNotification } from 'c/appHelper';

export default class CommentManager extends LightningElement {
    Labels = { ...labels }
    @api recordId;
    @api trackActionRecords;
    @api user;
    @api account;
    @api isportal;
    @api islegal;
    @api type;
    @api isbo;
    @api readOnly = false;
    @track records = [];
    @track firstRecord;
    @track newCommentText = '';
    @track showReply = false;
    @track showEdit = false;
    @track showMoreComments = true;
    @track showMoreCommentsSection = true;
    @track isLoading = true;
    @track isLegalToBO = false;
    @track totalRecords;
    @track trackPathAct = [];
    @track commentOrigin;
    commentContainerStyle = 'padding: 10px 12px;border-radius: 8px;background-color: #ffffff;border: 1px solid #eef1f6;';
    currentUser;
    currentSupplier;
    defaultPhoto = 'width:30px;height:30px; opacity: 0.5;background-image: url(' + profilePic + ');background-size: contain;background-position: left;background-repeat: no-repeat;'
    get showFirstRecord() {
        return this.records?.length >= 1;
    }
    get showSecondRecord() {
        return this.records?.length >= 2;
    }
    get moreComments() {
        return this.records?.slice(1);
    }
    get commentsSyleClass() {
        // return this.records.length == 0 ? '' : 'slds-feed__item-comments';
        return '';
    }

    connectedCallback() {
        this.initData();
    }

    initData() {
        if (this.islegal) {
            this.commentOrigin = 'Legal';
        } else if (this.isportal) {
            this.commentOrigin = 'Supplier';
        } else if (this.isbo) {
            this.commentOrigin = 'Business Owner';
        }
        if (this.islegal && this.type === 'portal') {
            this.isLegalToBO = true;
        }
        const records = [];
        const trackPathAct = [];
        this.trackActionRecords?.forEach(act => {
            const normalizedRecord = this.normalizeTrackAction(act);
            if (normalizedRecord.comment) {
                records.push(normalizedRecord);
            } else {
                trackPathAct.push(normalizedRecord);
            }
        });
        this.trackPathAct = trackPathAct;
        const filteredData = records.filter(record =>
            this.type === 'portal' ? record.isPortalPublished === true : record.isPortalPublished === false
        );
        this.records = filteredData;
        this.totalRecords = this.records.length;
        this.showReply = (this.totalRecords === 0 && !this.readOnly) ? true : false;
        this.showMoreCommentsSection = this.records.length > 2;
        this.firstRecord = this.records.length ? this.records[0] : null;
        this.isLoading = false;
    }
    normalizeTrackAction(record) {
        console.log('normalize trakck action:' + JSON.stringify(record));
        return {
            Id: record.Id,
            comment: record[TrackAction_API.Comment],
            assignee: record[TrackAction_API.Assignee],
            actionDate: record[TrackAction_API.ActionDate],
            parentId: record[TrackAction_API.ParentId],
            isPortalPublished: record[TrackAction_API.IsPortalPublished],
            assigneeIconUrl: record[TrackAction_API.AssigneeIconURL],
            record,
            isEdit: false,
            disableEditing: false,
            photoStyle: `width:30px;height:30px; opacity: 0.5;
                background-image: url(${record[TrackAction_API.AssigneeIconURL] || profilePic});
                background-size: contain;
                background-position: left;
                background-repeat: no-repeat;`,
            showEdit: record[TrackAction_API.Assignee] === this.user.Name && !this.readOnly,
            showDelete: !this.readOnly && record[TrackAction_API.Assignee] === this.user.Name
        };
    }
    handleAddReply() {
        this.newCommentText = '';
        this.showReply = !this.showReply;
    }
    handleEditAll() {
        const isOpening = !this.showEdit;
        this.showEdit = isOpening;
        this.newCommentText = isOpening ? this.records[0]?.comment || '' : '';
        this.records = this.records.map((record, index) => ({
            ...record,
            disableEditing: isOpening ? index !== 0 : false,
            isEdit: false
        }));
        this.firstRecord = this.records[0] || null;
    }
    handleCopyToClipboard(event) {
        const index = event.currentTarget.dataset.index;
        const text = index === undefined ? (this.firstRecord.record[TrackAction_API.Comment] || '') : (this.records[Number(index) + 1].record[TrackAction_API.Comment] || '');
        if (text) {
            navigator.clipboard.writeText(text).then(() => {
                showNotification(this, 'Success', this.Labels.LBL_Copy, 'success');
            }).catch(() => {
                showNotification(this, 'Error', 'Copy failed', 'error');
            });
        }
    }

    handleEdit(event) {
        const commentIndex = Number(event.currentTarget.dataset.index ?? 0) + 1;
        const currentRecord = this.records[commentIndex];
        if (!currentRecord) { return; }
        const isOpening = !currentRecord.isEdit;
        this.newCommentText = isOpening ? currentRecord.comment || '' : '';
        this.records = this.records.map((record, index) => ({
            ...record,
            isEdit: index === commentIndex ? isOpening : false,
            disableEditing: isOpening ? index !== commentIndex : false
        }));
        this.firstRecord = this.records[0] || null;
    }
    handleShowAllComments() {
        this.showMoreComments = true;
    }
    handleHideAllComments() {
        this.showMoreComments = false;
    }

    handleSaveComment(event) {
        if (this.newCommentText == null || this.newCommentText.trim() === '') {
            showNotification(this, this.Labels.MSG_Warning, this.Labels.MSG_LDEmptyComment, 'warning');
            return;
        }
        const type = event.currentTarget.dataset.type;
        const editMode = event.currentTarget.dataset.edit;
        const firstComment = event.currentTarget.dataset.first != null;
        //const isEditing = editMode === 'full' || editMode === 'edit';
        try {
            let commentIndex = event.currentTarget.dataset.index;
            if (commentIndex != null) {
                commentIndex = firstComment ? Number(commentIndex) : Number(commentIndex) + 1;
            }
            const recordToUpdate = commentIndex != null ? this.records[commentIndex] : null;
            // Use the correct Id property (normalized objects use `Id`)
            console.log('recordToUpdate:' + JSON.stringify(recordToUpdate));
            const trackActionId = recordToUpdate?.Id || recordToUpdate?.record?.Id || null;
            this.isLoading = true;
            this.showReply = false;
            this.showEdit = false;
            this.firstRecord = this.records[0];
            const isPortalPublished = type == 'portal';
            saveData({
                recordId: this.recordId,
                comment: this.newCommentText,
                account: this.account ? this.account : null,
                currentUser: JSON.stringify(this.user),
                isPortalPublished: isPortalPublished,
                origin: this.commentOrigin,
                trackActionId: trackActionId
            }).then((data) => {
                const savedRecord = JSON.parse(data);
                if (trackActionId) {
                    const updatedComment = this.newCommentText;
                    this.records = this.records.map(record =>
                        record.Id === trackActionId
                            ? {
                                ...record,
                                comment: updatedComment,
                                record: {
                                    ...record.record,
                                    [TrackAction_API.Comment]: updatedComment
                                },
                                isEdit: false,
                                disableEditing: false
                            }
                            : record
                    );
                    this.firstRecord = this.records[0] || null;
                    this.newCommentText = '';
                    showNotification(this, 'Success', this.Labels.LBL_LD_CommentUpdated, 'success');
                    this.dispatchEvent(
                        new CustomEvent('trackactionupdated', {
                            detail: { clauseId: this.recordId, trackActionId, comment: updatedComment },
                            bubbles: true,
                            composed: true
                        })
                    );
                } else {
                    savedRecord[TrackAction_API.Assignee] = this.user.Name;
                    savedRecord[TrackAction_API.ParentId] = this.recordId;
                    console.log('savedRecord:' + JSON.stringify(savedRecord));
                    const normalizedRecord = this.normalizeTrackAction(savedRecord);
                    normalizedRecord.photoStyle = this.defaultPhoto;
                    normalizedRecord.isEdit = false;
                    normalizedRecord.showEdit = savedRecord[TrackAction_API.Assignee] === this.user.Name && !this.readOnly;
                    normalizedRecord.showDelete = !this.readOnly && savedRecord[TrackAction_API.Assignee] === this.user.Name;
                    this.records = [
                        ...this.records,
                        normalizedRecord
                    ];
                    console.log('this.records:' + JSON.stringify(this.records));
                    this.records = this.records.map(record => ({
                        ...record,
                        disableEditing: record.Id !== normalizedRecord.Id
                    }));
                    this.firstRecord = this.records[0];
                    this.newCommentText = '';
                    this.showReply = false;
                    this.showEdit = false;
                    this.isLoading = false;
                    this.dispatchEvent(
                        new CustomEvent('trackactioncreated', {
                            detail: {
                                clauseId: this.recordId,
                                newTrackAction: JSON.parse(data)
                            },
                            bubbles: true,
                            composed: true
                        })
                    );
                }
                this.isLoading = false;
            })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error retrieving data:', error);
                    console.error('Error retrieving data:', error.message);
                    console.error('Error retrieving data:', error.stack);
                    showNotification(this, 'Error', error.body?.message || error.message || 'Failed', 'error');
                });
        } catch (error) {
            console.error('Error save data:', error);
            console.error('Error save data:', error.message);
        }
    }
    handleAddCommentText(event) {
        this.newCommentText = event.target.value;
    }
    handleResolve(event) {
        let deleteAll = event.currentTarget.dataset.all ? true : false;
        let commentIndex = Number(event.currentTarget.dataset.index ?? 0) + 2;
        let commentId = event.currentTarget.dataset.id;
        this.dispatchEvent(
            new CustomEvent('resolve', { detail: { clauseId: this.recordId, type: this.type, resolveAll: deleteAll, commentIndex: commentIndex, commentId: commentId } })
        );
    }
    get editable() {
        return !this.readOnly;
    }
}