import MSG_LDEmptyComment from "@salesforce/label/c.MSG_LDEmptyComment";
import LBL_Copy from "@salesforce/label/c.LBL_Copy";
import LBL_LDComment from "@salesforce/label/c.LBL_LDComment";
import LBL_LD_CommentUpdated from "@salesforce/label/c.LBL_LD_CommentUpdated";
import LBL_LDCommentResolve from "@salesforce/label/c.LBL_LDCommentResolve";
import LBL_LDWriteComment from "@salesforce/label/c.LBL_LDWriteComment";
import MSG_Warning from "@salesforce/label/c.MSG_Warning";
import LBL_Delete from "@salesforce/label/c.LBL_Delete";
import LBL_Edit from "@salesforce/label/c.LBL_Edit";

import TrackAction__c from '@salesforce/schema/TrackAction__c';
import Comment__c from '@salesforce/schema/TrackAction__c.Comment__c';
import Assignee__c from '@salesforce/schema/TrackAction__c.Assignee__c';
import AssigneeIconURL__c from '@salesforce/schema/TrackAction__c.AssigneeIconURL__c';
import ActionDate__c from '@salesforce/schema/TrackAction__c.ActionDate__c';
import ParentId__c from '@salesforce/schema/TrackAction__c.ParentId__c';
import IsPortalPublished__c from '@salesforce/schema/TrackAction__c.IsPortalPublished__c';

const labels = {
    LBL_Edit,
    LBL_Delete,
    MSG_Warning,
    LBL_LDWriteComment,
    LBL_LDCommentResolve,
    LBL_LD_CommentUpdated,
    LBL_Copy,
    MSG_LDEmptyComment
}
const TrackAction_API = {
    TrackAction__c: TrackAction__c.objectApiName,
    Comment: Comment__c.fieldApiName,
    Assignee: Assignee__c.fieldApiName,
    AssigneeIconURL: AssigneeIconURL__c.fieldApiName,
    ActionDate: ActionDate__c.fieldApiName,
    ParentId: ParentId__c.fieldApiName,
    IsPortalPublished: IsPortalPublished__c.fieldApiName
};
export {labels, TrackAction_API}