import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import CustomCss from "@salesforce/resourceUrl/CustomCss";
import ProfilePic from "@salesforce/resourceUrl/ProfilePic";
import MessagesAddIcon from "@salesforce/resourceUrl/MessagesAddIcon";
import ChatterPhone from "@salesforce/resourceUrl/ChatterPhone";
import ChatterMail from "@salesforce/resourceUrl/ChatterMail";
import ChatterDataSharing from "@salesforce/resourceUrl/ChatterDataSharing";
import ChatterInvoice from "@salesforce/resourceUrl/ChatterInvoice";
import ChatterEmoji from "@salesforce/resourceUrl/ChatterEmoji";
import ChatterAttach from "@salesforce/resourceUrl/ChatterAttach";
import ChatterSendMessage from "@salesforce/resourceUrl/ChatterSendMessage";
import getConversations from "@salesforce/apex/ChatterAppCmpCtrl.getConversations";
import getConversation from "@salesforce/apex/ChatterAppCmpCtrl.getConversation";
import getUserConnectionData from "@salesforce/apex/ChatterAppCmpCtrl.getUserConnectionData";
import { labels } from './labels.js'
// import getCommunities from "@salesforce/apex/ChatterAppCmpCtrl.getCommunities";
import getUsers from "@salesforce/apex/ChatterAppCmpCtrl.getUsers";
// import getUser from "@salesforce/apex/ChatterAppCmpCtrl.getUser";
// import getFeedWithFeedElements from "@salesforce/apex/ChatterAppCmpCtrl.getFeedWithFeedElements";
// import getFeedDirectory from "@salesforce/apex/ChatterAppCmpCtrl.getFeedDirectory";
// import getFeed from "@salesforce/apex/ChatterAppCmpCtrl.getFeed";
// import getNetworkUrl from "@salesforce/apex/ChatterAppCmpCtrl.getNetworkUrl";
import sendMessage from "@salesforce/apex/ChatterAppCmpCtrl.sendMessage";
import processRest from "@salesforce/apex/ChatterAppCmpCtrl.processRest";
import processRestPost from "@salesforce/apex/ChatterAppCmpCtrl.processRestPost";
import UserId from "@salesforce/user/Id";
import communityId from '@salesforce/community/Id';
import Cometd from 'c/cometd';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { subscribe, unsubscribe, onError, isEmpEnabled, setDebugFlag } from 'lightning/empApi';
// const subscribeEvent = (self, eventName, callback, errorCallback) => {
//     isEmpEnabled().then(result => {
//         console.log(`🚀 -----------------------------------🚀`);
//         console.log(`🚀 ~ isEmpEnabled ~ result:`, result);
//         console.log(`🚀 -----------------------------------🚀`);
//         subscribe(eventName, -1, callback).then(response => {
//             console.log('Subscribed to: ', eventName);
//             self.subscriptions.push({ eventName: eventName, sub: response });
//         }).catch(error => {
//             if (errorCallback) errorCallback(error);
//         });
//     });
// }
const retriveConvo = function (self, conversationId, isNew, cUser, callback) {
    console.log('retriveConvo has been called>>>convId: ', conversationId);
    // console.log('retriveConvo has been called>>>convId: ', conversationId);
    //reset other user
    self.otherUser = {
        user: {},
        userPhotoStyle: `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
        displayName: ``,
        firstName: ``,
        lastName: ``,
        title: ``,
        companyName: ``,
        phoneNumbersList: [],
        email: ``
    }
    if (isNew) {
        if (cUser) {
            self.otherUser.user = cUser;
            self.otherUser.userPhotoStyle = cUser?.userPhotoStyle || `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
            self.otherUser.displayName = cUser?.displayName || '';
            self.otherUser.firstName = cUser?.firstName || '';
            self.otherUser.lastName = cUser?.lastName || '';
            self.otherUser.title = cUser?.title || '';
            self.otherUser.companyName = cUser?.companyName || '';
            // console.log('self.usersMap.hasOwnProperty(cUser.id)>>>', JSON.stringify(self.usersMap.hasOwnProperty(cUser.id)));
            if (self.usersMap.hasOwnProperty(cUser.id)) {
                let userInfo = self.usersMap[cUser.id];
                // console.log('userInfo>>>', JSON.stringify(userInfo));
                self.otherUser.phoneNumbersList = [];
                userInfo.phoneNumbers.forEach(phone => {
                    self.otherUser.phoneNumbersList.push({ label: phone?.label || '', phoneNumber: phone.phoneNumber });
                });

                self.otherUser.email = userInfo?.email || '';
                // console.log('self.otherUser>>>', JSON.stringify(self.otherUser));
            }
            self.chatMessages = [{ id: '', firstInDay: true, sentDate: self.today }];
            // self.chatMessages = [];
            if (callback) callback();
        }
    } else {

        getConversation({ conversationId: conversationId }).then(result => {
            result = JSON.parse(result);
            let conv = self.conversations?.find(item => item.id == conversationId);
            conv.unreadCount = conv.unreadCount || 0;
            let user = conv?.secondUser;
            self.otherUser.user = user;
            self.isUser = true;
            // console.log(`🚀 ------------------------------------------------------🚀`);
            // console.log(`🚀 ~ getConversation ~ conv:`, JSON.stringify(conv));
            // console.log(`🚀 ~ getConversation ~ self.otherUser:`, JSON.stringify(user));
            // console.log(`🚀 ------------------------------------------------------🚀`);
            self.otherUser.userPhotoStyle = conv?.userPhotoStyle || `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
            self.otherUser.displayName = user.displayName || '';
            self.otherUser.firstName = user.firstName || '';
            self.otherUser.lastName = user.lastName || '';
            self.otherUser.title = user.title || '';
            self.otherUser.companyName = user.companyName || '';
            // console.log('self.usersMap.hasOwnProperty(user.id)>>>', JSON.stringify(self.usersMap.hasOwnProperty(user.id)));
            if (self.usersMap.hasOwnProperty(user.id)) {
                let userInfo = self.usersMap[user.id];
                // console.log('userInfo>>>', JSON.stringify(userInfo));
                self.otherUser.phoneNumbersList = [];
                // userInfo.phoneNumbers.forEach(phone => {
                //     self.otherUser.phoneNumbersList.push({ label: phone?.label || '', phoneNumber: phone.phoneNumber });
                // });

                // self.otherUser.email = userInfo?.email || '';

                if (userInfo?.email) {
                    self.otherUser.email = userInfo?.email;
                    userInfo.phoneNumbers.forEach(phone => {
                        self.otherUser.phoneNumbersList.push({ label: phone?.label || '', phoneNumber: phone.phoneNumber });
                    });
                }
                // console.log('self.otherUser>>>', JSON.stringify(self.otherUser));
            }
            self.chatMessages = result.messages.messages.map((item, index) => {
                return {
                    firstInDay: ((index == (result.messages.messages.length - 1)) || ((new Date(item?.sentDate).getDate() != new Date(result.messages.messages[index + 1]?.sentDate).getDate()) && (new Date(item?.sentDate).getTime() > new Date(result.messages.messages[index + 1]?.sentDate).getTime()))),
                    otherUser: item.sender.id != UserId,
                    sameUser: item.sender.id == UserId,
                    message: item?.body?.text,
                    sentDate: item?.sentDate,
                    sender: item.sender,
                    userPhotoStyle: `background-image:url('${item.sender.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
                }
            }).reverse();
            if (callback) callback();
        }).then(error => {
            clearInterval(self.intervalRetrive);
        });
    }
}
const retriveFeed = function (self, recordId, callback) {
    if (recordId) {
        return _processRest(self, '/services/data/v59.0/connect/communities/' + communityId + '/chatter/feeds/record/' + recordId + '/feed-elements', null);
    }
}
const postFeedItem = function (self, recordId, message) {
    // console.log(`🚀 ---------------------------------------🚀`);
    // console.log(`🚀 ~ postFeedItem ~ recordId:`, recordId);
    // console.log(`🚀 ---------------------------------------🚀`);
    if (recordId) {
        return _processRestPost(self, '/services/data/v59.0/connect/communities/' + communityId + '/chatter/feed-elements', {
            body: JSON.stringify({
                body: {
                    messageSegments: [{
                        type: "Text",
                        text: message
                    }]
                },
                feedElementType: "FeedItem",
                subjectId: recordId,
                visibility: "AllUsers",
            })
        });
    }
}
// const retriveConvos = function (self, callback) {
//     getConversations({ communityId: communityId }).then(result => {
//         result = JSON.parse(result);
//         result.conversations.map(item => {
//             let secondUser = item.members.find(u => u.id != UserId);
//             return {
//                 isNew: false,
//                 isConversation: true,
//                 id: item.id,
//                 latestMessage: item.latestMessage?.body?.text,
//                 lastSentDate: item.latestMessage?.sentDate,
//                 secondUser: secondUser,
//                 userPhotoStyle: `background-image:url('${secondUser.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
//             };
//         }).forEach(item => {
//             self.conversationsPool[item.id] = item;
//         });
//         self.conversations = Object.values(self.conversationsPool).sort((a, b) => b.lastSentDate - a.lastSentDate);
//         self.allConversations = self.conversations;
//         // console.log('retriveConvos>>>getConversations>>>', JSON.stringify(result));
//         // self.allConversations = JSON.parse(JSON.stringify(self.conversations));
//         let latestConvo = self.conversations[0];
//         // console.log("latestconvo>>>", JSON.stringify(latestConvo));
//         if (latestConvo) {
//             retriveConvo(self, latestConvo.id, latestConvo.isNew, null, () => { });
//         }
//         if (callback) callback();
//     });
// }

const retriveConvos = function (self, callback) {
    console.log('Retrieving conversations for communityId:', communityId);
    getConversations({ communityId: communityId }).then(result => {
        console.log('Received result:', result);

        result = JSON.parse(result);
        console.log('Parsed result:', result);

        result.conversations = result.conversations.filter(item =>
            item.members.some(u => u.id === UserId)
        );
        console.log('Filtered conversations:', result.conversations);

        result.conversations.map(item => {
            let secondUser = item.members.find(u => u.id !== UserId);
            console.log('Second user for conversation', item.id, secondUser);

            return {
                // isNew: false,
                // jana
                isNew: false,
                read: item.read || false,
                // jana
                isConversation: true,
                id: item.id,
                latestMessage: item.latestMessage?.body?.text,
                lastSentDate: item.latestMessage?.sentDate,
                secondUser: secondUser,
                userPhotoStyle: `background-image:url('${secondUser.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
            };
        }).forEach(item => {
            console.log('Adding conversation to pool with ID:', item.id);
            self.conversationsPool[item.id] = item;
        });

        console.log('Conversations pool:', self.conversationsPool);

        self.conversations = Object.values(self.conversationsPool).sort((a, b) => b.lastSentDate - a.lastSentDate);
        console.log('Sorted conversations:', self.conversations);

        self.allConversations = self.conversations;
        console.log('All conversations:', self.allConversations);

        let latestConvo = self.conversations[0];
        if (latestConvo) {
            console.log('Retrieving latest conversation with ID:', latestConvo.id);
            retriveConvo(self, latestConvo.id, latestConvo.isNew, null, () => { });
        }

        if (callback) {
            console.log('Executing callback');
            callback();
        }
    }).catch(error => {
        console.error('Error fetching conversations:', error);
    });
}

const _processRest = (self, requestUrl, params) => {
    return processRest({ requestUrl: requestUrl, ...params });
}
const _processRestPost = (self, requestUrl, params) => {
    return processRestPost({ requestUrl: requestUrl, ...params });
}
const CHATTER_CHANNEL = '/event/ChatterMessageChangeEvent__e';
const FEEDITEM_CHANNEL = '/event/FeedItemChangeEvent__e';
export default class ChatterApp extends LightningElement {
    @track labels = labels;
    @track firstRender = true;
    @track users = [];
    @track usersMap = {};
    @track conversations = [];
    @track allConversations = [];
    @track chatMessages = [];
    @track currentConversationId;
    @track currentMessage = '';
    @track isUser = false;
    @track isRecord = false;
    @track record = {};
    @track conversationsPool = {};
    @track otherUser = {
        user: {},
        userPhotoStyle: `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
        displayName: ``,
        firstName: ``,
        lastName: ``,
        title: ``,
        companyName: ``,
        phoneNumbersList: [],
        email: ``
    }
    @track loadChat = true;
    @track emojiVisibility = false;
    @track emojiMethods = {
        closeEmojiPanel() {
            this.emojiVisibility = false
        },
        openEmojiPanel() {
            this.emojiVisibility = true
        },
        ToggleEmojiPanel() {
            this.emojiVisibility = !this.emojiVisibility;
        }

    }
    insertEmoji(event) {
        const emoji = event.currentTarget.dataset.emoji;
        const messageInput = this.template.querySelector('.current-message-input');
        if (!messageInput) return;
        messageInput.value += emoji;
        this.emojiVisibility = false;
        messageInput.focus();
    }
    @track emojis = [
        '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆',
        '😉', '😊', '😋', '😎', '😍', '😘', '🥰', '😗',
        '😙', '😚', '🙂', '🤗', '🤩', '🤔', '🤨', '😐',
        '😑', '😶', '🙄', '😏', '😣', '😥', '😮', '🤐',
        // Add more emojis as needed
    ];
    otherUserLastName = '';
    @track today = new Date().toISOString();
    cometdManager;
    handleLabelClick(event) {
        const labels = this.template.querySelectorAll('.label');
        labels.forEach(label => {
            label.classList.remove('active');
        });
        event.target.classList.add('active');
        const label = event.target.dataset.label;
        this.selectedLabel = label;
        this.updateConversationsList();
    }

    loadConversations() {
        this.allConversations = this.allConversations.map(conv => {
            conv.showUnreadBadge = conv.unreadCount > 0 && conv.secondUser?.id !== UserId;
            return conv;
        });
        this.updateConversationsList();
    }
    updateConversationsList() {
        if (this.selectedLabel === 'unread') {
            this.conversations = this.allConversations.filter(conv =>
                conv.unreadCount > 0 && conv.secondUser?.id !== UserId
            );
        } else {
            this.conversations = [...this.allConversations];
        }
    }

    // @track otherUserPhotoStyle = `background-image:url('${item.sender.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;

    connectedCallback() {
        // console.log('Chatter app connected callback');
        // onError((error) => {
        //     console.log('Received error from server: ', JSON.stringify(error));
        //     // Error contains the server-side error
        // });
        let self = this;
        // }).catch(error => {
        //     console.log('error: ' + JSON.stringify(error))
        //     console.log(error.message);
        //     console.log(error.body?.message);
        // });
        // this.subscribeToEvent(self);
        _processRest(self, '/services/data/v59.0/connect/communities/' + communityId + '/chatter/feeds', null).then(result => {
            if (result) {
                result = JSON.parse(result);
                if (result?.feeds) {
                    Promise.all([...result.feeds].map(feed => {
                        return _processRest(self, feed.feedElementsUrl, null);
                    })).then(results => {
                        results = results.forEach(res => res && JSON.parse(res).elements && [...JSON.parse(res).elements].forEach(elm => {
                            let recordId = elm.parent.id;
                            let record = self.conversationsPool[recordId] = self.conversationsPool[recordId]
                                || {
                                isRecord: true,
                                id: recordId,
                                name: elm.parent.name,
                                userPhotoStyle: `background-image:url('${elm.parent.motif.smallIconUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
                                record: elm.parent,
                                messages: [], isRecord: true
                            };
                            let messages = {};
                            elm.isRecord = true;
                            messages[elm.id] = elm;
                            record.messages.forEach(msg => messages[msg.id] = msg);
                            record.messages = Object.values(messages).sort((a, b) => b?.createdDate - a?.createdDate);
                            let lastMessage = record.messages[record.messages.length - 1];
                            record.lastSentDate = lastMessage?.createdDate;
                            record.secondUser = lastMessage?.actor || {};
                            record.secondUser = lastMessage?.actor || {};
                            record.latestMessage = lastMessage?.body?.text;
                        }));
                        self.conversations = Object.values(this.conversationsPool).sort((a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate));
                        self.allConversations = JSON.parse(JSON.stringify(self.conversations));
                    });
                }
            }
        });
        // getCommunities().then(result => {
        //     result = JSON.parse(result);
        //     console.log(`🚀 --------------------------------------------------🚀`);
        //     console.log(`🚀 ~ ChatterApp ~ getCommunities ~ result:`, result);
        //     console.log(`🚀 --------------------------------------------------🚀`);
        // });
        getUsers({ communityId: communityId }).then(result => {

            result = JSON.parse(result);
            this.users = result.users.map(item => {
                item.userPhotoStyle = `background-image:url('${item.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                return item;
            });

            // Create usersMap with id as key and user object as value
            this.usersMap = this.users.reduce((map, user) => {

                if (!user?.email) {
                    getUserConnectionData({ targetId: user.id })
                        .then(res => {

                            const data = JSON.parse(res);
                            user.email = data.Email;
                            if (data.Phone) {
                                user.phoneNumbers.push({ label: 'Work', phoneNumber: data.Phone });
                            }
                            if (data.MobilePhone) {
                                user.phoneNumbers.push({ label: 'Mobile', phoneNumber: data.MobilePhone });
                            }

                        })
                }
                map[user.id] = user;
                return map;
            }, {});
            // console.log("this.users>>>", JSON.stringify(this.users));
            console.log("this.usersMap>>>", JSON.stringify(this.usersMap));
            this.loadChat = false
            retriveConvos(this);
        });


        // getFeedWithFeedElements({ communityId: communityId }).then(result => {
        //     result = JSON.parse(result);
        //     console.log(`🚀 --------------------------------------------🚀`);
        //     console.log(`🚀 ~ ChatterApp ~ getFeedWithFeedElements ~ result:`, JSON.stringify(result));
        //     console.log(`🚀 --------------------------------------------🚀`);
        // });
        // getFeedDirectory({ communityId: communityId }).then(result => {
        //     result = JSON.parse(result);
        //     console.log(`🚀 --------------------------------------------🚀`);
        //     console.log(`🚀 ~ ChatterApp ~ getFeedDirectory ~ result:`, JSON.stringify(result));
        //     console.log(`🚀 --------------------------------------------🚀`);
        // });
        // getFeed({ communityId: communityId }).then(result => {
        //     result = JSON.parse(result);
        //     let feedElements = [];
        //     console.log('result: ' + JSON.stringify(result));
        //     console.log('result.length: ' + result.length);
        //     Object.values(result).forEach(item => {
        //         console.log('item: ' + JSON.stringify(item));
        //         console.log(`🚀 -----------------------------------------------------------------------🚀`);
        //         console.log(`🚀 ~ ChatterApp ~ Object.values ~ item.feedElements:`, item.feedElements);
        //         console.log(`🚀 -----------------------------------------------------------------------🚀`);
        //         if (item.feedElements) {
        //             feedElements = [...feedElements, ...item.feedElements];
        //         }
        //     });
        //     console.log('finish');
        //     console.log('feedElements: ' + JSON.stringify(feedElements));
        //     console.log(`🚀 --------------------------------------------🚀`);
        //     console.log(`🚀 ~ ChatterApp ~ getFeed ~ result:`, feedElements);
        //     console.log(`🚀 ~ ChatterApp ~ getFeed ~ result:`, JSON.stringify(feedElements));
        //     console.log(`🚀 --------------------------------------------🚀`);
        // });
        this.cometdManager = new Cometd(this);
        this.cometdManager.initialize()
            .then(() => {
                this.cometdManager.subscribe(CHATTER_CHANNEL, this.handleNotificationMessage);
                this.cometdManager.subscribe(FEEDITEM_CHANNEL, this.handleNotificationFeedItem);
            });
    }

    handleNotificationMessage(message) {
        console.log('New notification message jana:', message);
        const payload = message?.data?.payload;
        if (!payload) return;
        console.log('this.conversations<<<', this.conversations);
        console.log('payload.ConversationId__c<<<', payload.ConversationId__c);
        console.log('this.user.Id<<<', UserId);
        console.log('payload.SenderId<<<', payload.SenderId);
        console.log('payload.SenderId !== this.user.Id && payload.ConversationId__c && this.conversations.find(c => c.id == payload.ConversationId__c)<<<', payload.SenderId !== UserId && payload.ConversationId__c && this.conversations.find(c => c.id == payload.ConversationId__c));
        // if (payload.SenderId !== UserId && payload.ConversationId__c && this.conversations.find(c => c.id == payload.ConversationId__c)) {
        if (payload.SenderId !== UserId && payload.ConversationId__c) {
            let conv = this.conversations.find(c => c.id == payload.ConversationId__c);
            if (conv) {
                conv.unreadCount = (conv.unreadCount || 0) + 1;
                conv.showUnreadBadge = conv.unreadCount > 0;
                conv.lastSentDate = new Date().toISOString();
                this.conversations = [...this.conversations].sort((a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate));
                this.allConversations = JSON.parse(JSON.stringify(this.conversations));
                this.loadChat = false;
            }
            console.log('conv<<<', conv);
            let userId = conv.secondUser.id;
            console.log('userId<<<', userId);
            let cUser = this.usersMap[userId];
            console.log('cUser<<<', cUser);
            this.isUser = true;
            console.log('this.isUser<<<', this.isUser);
            retriveConvo(this, payload.ConversationId__c, conv.isNew, cUser, () => { console.log('hiii jana from handleNotificationMessage') });
            if (!conv.isNew) {
                console.log('Retrieve jana conv.isNew')
                this.intervalRetrive = setInterval(() => {
                    retriveConvo(this, payload.ConversationId__c, conv.isNew);
                }, 5000);
            }
            this.loadChat = false;

        }
        this.loadConversations();
    }

    disconnectedCallback() {
        if (this.cometdManager) {
            // this.cometdManager.unsubscribeAll();
            this.cometdManager.unsubscribe(CHATTER_CHANNEL);
            this.cometdManager.unsubscribe(FEEDITEM_CHANNEL);
        }
    }
    handleNotificationFeedItem(message) {
        let self = this;
        console.log('New notification feed item:', message);
        const payload = message?.data?.payload;
        if (!payload) return;
        const conversationId = payload.ConversationId__c || null;
        const recordId = payload.RecordId__c || null;
        if (conversationId) {
            let conv = this.conversations.find(c => c.id === conversationId);

            if (conv) {
                if (payload.SenderId !== UserId) {
                    conv.unreadCount = (conv.unreadCount || 0) + 1;
                    conv.showUnreadBadge = conv.unreadCount > 0;
                }
                conv.lastSentDate = new Date().toISOString();
                this.conversations = [...this.conversations].sort(
                    (a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate)
                );
                this.allConversations = JSON.parse(JSON.stringify(this.conversations));
                if (this.currentConversationId === conversationId) {
                    retriveConvo(this, conversationId, conv.isNew, this.usersMap[conv.secondUser.id]);
                }
            }
        }
        if (recordId) {
            let record = this.conversationsPool[recordId];
            if (record) {
                if (this.currentRecordId === recordId) {
                    retriveFeed(this, recordId, () => { }).then(result => {
                        result = JSON.parse(result);
                        result.elements.forEach(elm => {
                            let recordId = elm.parent.id;
                            let messages = {};
                            elm.isRecord = true;
                            elm.userPhotoStyle = `background-image:url('${elm.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                            messages[elm.id] = elm;
                            record.messages.forEach(msg => messages[msg.id] = msg);
                            record.messages = Object.values(messages).sort((a, b) => new Date(a.createdDate) - new Date(b.createdDate));
                            let lastMessage = record.messages[record.messages.length - 1];
                            record.lastSentDate = lastMessage?.createdDate;
                            record.userPhotoStyle = `background-image:url('${elm.parent.motif.smallIconUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                            record.secondUser = lastMessage?.actor || {};
                            record.latestMessage = lastMessage?.body?.text;
                        });
                        self.chatMessages = record.messages.map((item, index) => {
                            return {
                                firstInDay: (index == 0) || ((new Date(item?.createdDate).getDate() != new Date(record.messages[index - 1].createdDate).getDate()) && (new Date(item?.createdDate).getTime() > new Date(record.messages[index - 1].createdDate).getTime())),
                                isRecord: true,
                                otherUser: item?.actor?.id != UserId,
                                sameUser: item?.actor?.id == UserId,
                                message: item?.body?.text,
                                sentDate: item?.createdDate,
                                sender: item.actor,
                                userPhotoStyle: `background-image:url('${item.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
                            }
                        });
                        self.isRecord = true;
                        self.record = record;
                        this.loadChat = false;
                        setTimeout(() => {
                            let chatContent = self.template?.querySelector('.chat-content');
                            if (chatContent) {
                                chatContent.scrollTop = chatContent.scrollHeight;
                            }
                        }, 1000);
                    }).catch(err => {
                        this.loadChat = false;
                    });
                }
            } else {
                retriveConvos(this, conversationId, conv.isNew, this.usersMap[conv.secondUser.id]);
            }
        }
    }

    @track ProfilePic = `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
    @track MessagesAddIcon = `top:-3px;max-width: 35px; height:45px; background-image: url('${MessagesAddIcon}'); background-position: right center;`;
    @track ChatterPhone = `max-width:60px; height:35px; background-image: url('${ChatterPhone}'); background-position: left center;`;
    @track ChatterMail = `max-width:60px; height:35px; background-image: url('${ChatterMail}'); background-position: left center;`;
    @track ChatterDataSharing = `max-width:70px; height:40px; background-image: url('${ChatterDataSharing}'); background-position: left center;`;
    @track ChatterInvoice = `max-width:70px; height:40px; background-image: url('${ChatterInvoice}'); background-position: left center;`;
    @track ChatterEmoji = `background-image: url('${ChatterEmoji}');`;
    @track ChatterAttach = `background-image: url('${ChatterAttach}');`;
    @track ChatterSendMessage = `background-image: url('${ChatterSendMessage}');`;
    @track ProfilePic2 = `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`

    renderedCallback() {
        Promise.all([
            loadStyle(this, CustomCss)
        ]).then(() => {
            // console.log('Files loaded');
        }).catch(error => {
            console.log(error.body.message);
        });
        const messagesContainer = this.template.querySelector('.chat-content');
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
        if (this.firstRender && this.conversations.length > 0) {
            const firstConvo = this.template.querySelector(`[data-conversation-id="${this.conversations[0].id}"]`);
            if (firstConvo) {
                const activeEl = this.template.querySelectorAll('.active-conv');
                if (activeEl.length != 0) activeEl[0].classList.remove('active-conv');
                firstConvo.classList.add('active-conv');
                this.template.querySelectorAll('.chat-body')[0].classList.remove('m_h');
                this.firstRender = false;
            }
        }
    }
    handleKeyUp(event) {
        if (event.key === 'Enter') {
            const message = event.target.value;
            this.sendMessage(message);
        }
    }
    sendMessage(event) {
        let self = this;
        let currentMessageInput = this.template?.querySelector('.current-message-input');
        // Check input empty
        if (currentMessageInput.value.trim().length === 0) return;
        // console.log('>>> ' + currentMessageInput);
        if (currentMessageInput) {
            let currentMessage = currentMessageInput?.value;
            currentMessageInput.value = '';
            if (this.isRecord) {
                let record = this.record;
                let recordId = this.record.id;
                // console.log(`🚀 --------------------------------------🚀`);
                // console.log(`🚀 ~ sendMessage ~ recordId:`, recordId);
                // console.log(`🚀 --------------------------------------🚀`);
                // postFeedItem(this, recordId, currentMessage).then(result => {
                processRestPost({
                    requestUrl: '/services/data/v59.0/connect/communities/' + communityId + '/chatter/feed-elements',
                    body: JSON.stringify({
                        body: {
                            messageSegments: [{
                                type: "Text",
                                text: currentMessage
                            }]
                        },
                        feedElementType: "FeedItem",
                        subjectId: recordId,
                        visibility: "AllUsers",
                    })
                }).then(result => {
                    // console.log(`🚀 -------------------------------------🚀`);
                    // console.log(`🚀 ~ //postFeedItem ~ result:`, result);
                    // console.log(`🚀 -------------------------------------🚀`);
                    let elm = JSON.parse(result);
                    let recordId = elm.parent.id;
                    let messages = {};
                    elm.isRecord = true;
                    elm.userPhotoStyle = `background-image:url('${elm.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                    messages[elm.id] = elm;
                    record.messages.forEach(msg => messages[msg.id] = msg);
                    record.messages = Object.values(messages).sort((a, b) => new Date(a.createdDate) - new Date(b.createdDate));
                    let lastMessage = record.messages[record.messages.length - 1];
                    record.lastSentDate = lastMessage?.createdDate;
                    record.userPhotoStyle = `background-image:url('${elm.parent.motif.smallIconUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                    record.secondUser = lastMessage?.actor || {};
                    record.latestMessage = lastMessage?.body?.text;
                    // console.log('record.messages >>>>: ' + JSON.stringify(record.messages));
                    self.chatMessages = record.messages.map((item, index) => {
                        // console.log('index: ' + index);
                        // console.log('index == 0: ' + (index == 0));
                        return {
                            firstInDay: (index == 0) || ((new Date(item?.createdDate).getDate() != new Date(record.messages[index - 1]?.createdDate).getDate()) && (new Date(item?.createdDate).getTime() > new Date(record.messages[index - 1]?.createdDate).getTime())),
                            isRecord: true,
                            otherUser: item?.actor?.id != UserId,
                            sameUser: item?.actor?.id == UserId,
                            message: item?.body?.text,
                            sentDate: item?.createdDate,
                            sender: item.actor,
                            userPhotoStyle: `background-image:url('${item.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
                        }
                    });
                    self.conversations = Object.values(self.conversations).sort((a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate));
                });
            }
            if (this.isUser) {
                let recipientUserId = this.otherUser?.user?.id;
                let chatMessages = this.chatMessages;
                this.chatMessages = [];
                if (!recipientUserId) return;
                sendMessage({ recipientUserId: recipientUserId, message: currentMessage }).then(result => {
                    result = JSON.parse(result);
                    let conversationId = result.conversationId;
                    let conv = this.conversations.find(item => item.secondUser.id == recipientUserId);
                    if (conv) {
                        delete this.conversationsPool[conv.id];
                        conv.id = conversationId;
                        conv.isNew = false; // Mark as not new
                        this.conversationsPool[conversationId] = conv; // Add with new ID
                        conv.latestMessage = currentMessage;
                    }

                    this.currentConversationId = conversationId;

                    // Clear any existing intervals
                    clearInterval(this.intervalRetrive);
                    if (conversationId) {
                        retriveConvo(this, conversationId, null, null, () => {
                            setTimeout(() => {
                                let chatContent = self.template?.querySelector('.chat-content');
                                if (chatContent) {
                                    chatContent.scrollTop = chatContent.scrollHeight;
                                }
                            }, 1000);
                        });
                        if (!conv.isNew) {
                            this.intervalRetrive = setInterval(() => {
                                retriveConvo(this, conversationId, null, null, () => {
                                    setTimeout(() => {
                                        let chatContent = self.template?.querySelector('.chat-content');
                                        if (chatContent) {
                                            chatContent.scrollTop = chatContent.scrollHeight;
                                        }
                                    }, 1000);
                                });
                            }, 5000);
                        }
                    }

                    // console.log('chatMessages.length: ' + chatMessages.length);
                    this.chatMessages = [...chatMessages, {
                        firstInDay: chatMessages.length == 0 || ((new Date(result?.sentDate).getDate() != new Date(chatMessages[chatMessages.length - 1].sentDate).getDate()) && (new Date(result?.sentDate).getTime() > new Date(chatMessages[chatMessages.length - 1].sentDate).getTime())),
                        otherUser: result.sender.id != UserId,
                        sameUser: result.sender.id == UserId,
                        message: result?.body?.text,
                        sentDate: result?.sentDate,
                        sender: result.sender,
                        userPhotoStyle: `background-image:url('${result.sender.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
                    }];
                    self.conversations.find(item => item.id == conversationId).lastSentDate = self.chatMessages[self.chatMessages.length - 1].sentDate;
                    self.conversations = Object.values(this.conversations).sort((a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate));
                    Promise.resolve().then(() => {
                        this.highlightConversationById(conversationId);
                    })
                });

            }

        }
        this.loadConversations();
    }
    handleUserProfile() {
        this.template.querySelectorAll('.chat-right-nav')[0].classList.remove('md_h');
    }
    handleCloseUserProfile() {
        this.template.querySelectorAll('.chat-right-nav')[0].classList.add('md_h');
    }
    handleSelectConversation(ev) {
        // console.log('handleSelectConversation has been called');
        const activeEl = this.template.querySelectorAll('.active-conv');
        if (activeEl.length != 0) activeEl[0].classList.remove('active-conv');
        ev.target.parentElement.classList.add('active-conv');
        this.template.querySelectorAll('.chat-body')[0].classList.remove('m_h');
    }
    handleBackToChats() {
        this.template.querySelectorAll('.chat-body')[0].classList.add('m_h');
    }
    openConversation(event) {
        console.log('clicked');
        this.loadChat = false;
        this.today = new Date().toISOString();
        // console.log('openConversation has been called');
        let self = this;
        this.isUser = false;
        this.isRecord = false;
        let conversationId = event?.target?.dataset?.conversationId || event?.target?.closest('.msg-effect')?.dataset?.conversationId;
        let recordId = event?.target?.dataset?.recordId || event?.target?.closest('.msg-effect')?.dataset?.recordId;
        this.currentConversationId = conversationId;
        this.currentRecordId = recordId;
        this.chatMessages = [];

        // jana
        let conv = this.conversations.find(c => c.id == conversationId);
        if (conv) {
            conv.read = true;
            conv.unreadCount = 0;
            conv.showUnreadBadge = false;
            this.conversations = [...this.conversations];
        }
        // jana

        clearInterval(this.intervalRetrive);
        // let userId;
        if (recordId) {
            // console.log(`🚀 --------------------------------------------------------------------🚀`);
            // console.log(`🚀 ~ ChatterApp ~ openConversation ~ recordId:`, recordId);
            // console.log(`🚀 --------------------------------------------------------------------🚀`);
            let record = this.conversationsPool[recordId];
            // userId = record.secondUser.id;
            retriveFeed(this, recordId, () => { }).then(result => {
                result = JSON.parse(result);
                result.elements.forEach(elm => {
                    let recordId = elm.parent.id;
                    let messages = {};
                    elm.isRecord = true;
                    elm.userPhotoStyle = `background-image:url('${elm.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                    messages[elm.id] = elm;
                    record.messages.forEach(msg => messages[msg.id] = msg);
                    record.messages = Object.values(messages).sort((a, b) => new Date(a.createdDate) - new Date(b.createdDate));
                    let lastMessage = record.messages[record.messages.length - 1];
                    // console.log(`🚀 --------------------------------------------------🚀`);
                    // console.log(`🚀 ~ ChatterApp ~ _processRest ~ messages:`, messages);
                    // console.log(`🚀 ~ ChatterApp ~ _processRest ~ lastMessage:`, lastMessage);
                    // console.log(`🚀 --------------------------------------------------🚀`);
                    record.lastSentDate = lastMessage?.createdDate;
                    record.userPhotoStyle = `background-image:url('${elm.parent.motif.smallIconUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                    record.secondUser = lastMessage?.actor || {};
                    record.latestMessage = lastMessage?.body?.text;
                });
                self.chatMessages = record.messages.map((item, index) => {
                    return {
                        firstInDay: (index == 0) || ((new Date(item?.createdDate).getDate() != new Date(record.messages[index - 1].createdDate).getDate()) && (new Date(item?.createdDate).getTime() > new Date(record.messages[index - 1].createdDate).getTime())),
                        isRecord: true,
                        otherUser: item?.actor?.id != UserId,
                        sameUser: item?.actor?.id == UserId,
                        message: item?.body?.text,
                        sentDate: item?.createdDate,
                        sender: item.actor,
                        userPhotoStyle: `background-image:url('${item.actor.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`
                    }
                });
                self.isRecord = true;
                self.record = record;
                this.loadChat = false;
                setTimeout(() => {
                    let chatContent = self.template?.querySelector('.chat-content');
                    if (chatContent) {
                        chatContent.scrollTop = chatContent.scrollHeight;
                    }
                }, 1000);
            }).catch(err => {
                this.loadChat = false;
            });
        }
        if (conversationId) {
            let conv = this.conversations.find(c => c.id == conversationId);
            let userId = conv.secondUser.id;

            let cUser = this.usersMap[userId];
            this.isUser = true;
            retriveConvo(this, conversationId, conv.isNew, cUser);
            if (!conv.isNew) {
                console.log('Retrieve conv.isNew')
                this.intervalRetrive = setInterval(() => {
                    retriveConvo(this, conversationId, conv.isNew);
                }, 5000);
            }
            this.loadChat = false;
        }

    }
    @track popUp = {
        newConversation: {
            isOpen: false,
            options: [],
            close(event) {
                this.popUp.newConversation.isOpen = false;
            },
            pick(event) {
                let uId = event?.target?.dataset?.userId || event?.target?.closest('.msg-effect')?.dataset?.userId;
                let newConversationUser = this.popUp.newConversation.options.find(u => u.id == uId);
                let newConv = {
                    isConversation: true,
                    isNew: true,
                    //temporary id
                    id: 'c-' + this.conversations.length,
                    latestMessage: '',
                    lastSentDate: '',
                    secondUser: newConversationUser,
                    userPhotoStyle: `background-image:url('${newConversationUser.photo.standardEmailPhotoUrl}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`,
                };
                let tempPool = {};
                tempPool[newConv.id] = newConv;

                this.conversationsPool = { ...tempPool, ...this.conversationsPool };
                // **Update allConversations**

                this.conversations = Object.values(this.conversationsPool).sort((a, b) => new Date(b.lastSentDate) - new Date(a.lastSentDate));
                this.allConversations = [...this.conversations];
                this.popUp.newConversation.isOpen = false;
                this.otherUser.user = newConversationUser;
                this.otherUser.userPhotoStyle = newConversationUser?.userPhotoStyle || `background-image:url('${ProfilePic}');border-radius:50px;top: 1.5px;left: 1.5px;right: 1.5px;bottom: 1.5px;`;
                this.otherUser.displayName = newConversationUser?.displayName || '';
                this.otherUser.firstName = newConversationUser?.firstName || '';
                this.otherUser.lastName = newConversationUser?.lastName || '';
                this.otherUser.title = newConversationUser?.title || '';
                this.otherUser.companyName = newConversationUser?.companyName || '';
                // console.log('self.usersMap.hasOwnProperty(cUser.id)>>>', JSON.stringify(self.usersMap.hasOwnProperty(cUser.id)));
                if (this.usersMap.hasOwnProperty(uId)) {
                    let userInfo = this.usersMap[uId];
                    // console.log('userInfo>>>', JSON.stringify(userInfo));
                    this.otherUser.phoneNumbersList = [];
                    userInfo.phoneNumbers.forEach(phone => {
                        this.otherUser.phoneNumbersList.push({ label: phone?.label || '', phoneNumber: phone.phoneNumber });
                    });
                    this.otherUser.email = userInfo?.email || '';
                    // console.log('self.otherUser>>>', JSON.stringify(self.otherUser));
                }
                this.chatMessages = [{ id: '', firstInDay: true, sentDate: this.today }];
                // this.chatMessages = [];
                clearInterval(this.intervalRetrive);
                Promise.resolve().then(() => {
                    this.highlightConversationById(newConv.id);
                    const divElement = this.template.querySelector(`.new-data`);
                    console.log(divElement)
                    console.log('click executed');
                    if (!divElement) return;

                    divElement.click();
                    console.log('click executed');
                })
            }
        }
    }
    highlightConversationById(conversationId) {
        // Remove the active-conv class from any previously highlighted conversation
        const activeEl = this.template.querySelectorAll('.active-conv');
        if (activeEl.length != 0) activeEl[0].classList.remove('active-conv');

        // Add the active-conv class to the new conversation
        const newConvEl = this.template.querySelector(`[data-conversation-id="${conversationId}"]`);
        if (newConvEl) {
            newConvEl.classList.add('active-conv');
        }

        // Make sure the chat body is visible
        this.template.querySelectorAll('.chat-body')[0].classList.remove('m_h');
    }

    openNewConversation(event) {
        let conversationsPool = this.conversationsPool;
        this.popUp.newConversation.options = this.users.filter(u => {
            return u.id !== UserId && !Object.values(conversationsPool).some(conv => conv.secondUser.id == u.id);
        });
        this.popUp.newConversation.isOpen = true;
    }
    @track intervalRetrive;
    @track searchTerm = '';
    handleSearch(event) {
        let value = event.target.value;
        this.searchTerm = value;
        if (value != null && value != '') {
            this.conversations = this.allConversations.filter(element => {
                const displayNameMatch = element.secondUser?.displayName?.toLowerCase().includes(value.toLowerCase());
                // const communityNicknameMatch = element.secondUser?.communityNickname?.toLowerCase().includes(value.toLowerCase());
                const nameMatch = element?.name?.toLowerCase().includes(value.toLowerCase())
                return nameMatch || displayNameMatch;
            });
        } else {
            this.conversations = JSON.parse(JSON.stringify(this.allConversations));
        }
    }
    // subscriptions = [];
    // async subscribeToEvent(self) {
    //     const empEnabled = await isEmpEnabled();
    //     if (empEnabled) {
    //         // console.log('EmpJs Streaming API is enabled.');
    //         // You can proceed with your streaming logic here
    //     } else {
    //         // console.log('EmpJs Streaming API is not enabled.');
    //         // Handle the case where streaming is not available
    //     }
    //     subscribeEvent(self, '/event/ChatterMessageChangeEvent__e',
    //         (response) => {
    //             // console.log('Received event: ', JSON.stringify(response));
    //             retriveConvos(self);
    //         },
    //         (error) => {
    //             console.error('Subscription error: ', JSON.stringify(error));
    //         }
    //     );
    //     onError(error => {
    //         console.error('Streaming API error: ', JSON.stringify(error));
    //     });
    // }
    disconnectedCallback() {
        // if (self.subscriptions) {
        //     self.subscriptions.forEach(({ eventName, sub }) => {
        //         unsubscribe(sub, response => {
        //             console.log('Unsubscribed from: ', eventName);
        //         });
        //     })
        // }
    }


}