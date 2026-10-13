import { LightningElement, track, wire, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import cometdlwc from "@salesforce/resourceUrl/cometd";
import getSessionId from '@salesforce/apex/ConnectLayoutController.getSessionId';

export default class CommunicationManager extends LightningElement {

    @track sessionId;
    cometdInitialized = false;
    cometdLib;
    connectedCallback() {
        loadScript(this, cometdlwc)
            .then(() => {
                console.log('CometD loaded!');
                getSessionId()
                    .then((sessionId) => {
                        this.sessionId = sessionId;
                        return loadScript(this, cometdlwc);
                    })
                    .then(() => {
                        this.initializeCometd();
                    })
                    .catch((error) => {
                        console.error('CometD load/init error', error);
                    });
            })
            .catch(error => {
                console.error('Error loading CometD', error);
            });
    }

    initializeCometd() {
        try {
            if (this.cometdInitialized) return;
            this.cometdInitialized = true;
            this.cometdLib = new window.org.cometd.CometD();
            this.cometdLib.configure({
                url: window.location.protocol + '//' + window.location.hostname + '/cometd/57.0/',
                requestHeaders: { Authorization: 'Bearer ' + this.sessionId },
                appendMessageTypeToURL: false,
                logLevel: 'info'
            });
            this.cometdLib.websocketEnabled = false;
            this.cometdLib.handshake((status) => {
                if (status.successful) {
                    console.log('CometD handshake successful');
                    this.subscribeToStreamingChannels();
                } else {
                    console.error('CometD handshake failed', status);
                }
            });
        } catch (error) {
            console.error(' CometD initialization error:', error);
        }
    }

    subscribeToStreamingChannels() {
        const customNotificationChannel = '/s/notifications/notification';
        this._streamingSubscriptionCustomHandle = this.cometdLib.subscribe(
            customNotificationChannel,
            this.handleNotificationMessage.bind(this)
        );
        console.log('Subscribed to:', customNotificationChannel);
        console.log('Subscription handle:', this._streamingSubscriptionCustomHandle);
    }

    stopStreaming() {
        if (this._streamingSubscriptionNotificationsHandle) {
            this.cometdLib.unsubscribe(this._streamingSubscriptionNotificationsHandle);
            this._streamingSubscriptionNotificationsHandle = null;
        }
        console.log('Unsubscribed from CometD channels');
    }

    disconnectedCallback() {
        this.stopStreaming();
    }
}