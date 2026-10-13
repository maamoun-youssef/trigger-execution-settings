import { loadScript } from 'lightning/platformResourceLoader';
import cometdResourceUrl from "@salesforce/resourceUrl/cometd";
import getInternalSessionId from '@salesforce/apex/NegoptimHelper.getInternalSessionId';

export default class Cometd {

    constructor(component) {
        this.component = component;
        this.sessionId = null;
        this.cometdInitialized = false;
        this.cometdLib = null;
        this.subscriptionHandles = {};
    }

    initialize() {
        return loadScript(this.component, cometdResourceUrl).then(() => getInternalSessionId()).then((sessionId) => {
            this.sessionId = sessionId;
            return this.initializeCometd();
        }).catch((error) => {
            console.error('CometD initialization error:', error);
        });
    }

    initializeCometd() {
        if (this.cometdInitialized) return Promise.resolve();
        this.cometdInitialized = true;

        this.cometdLib = new window.org.cometd.CometD();
        this.cometdLib.configure({
            url: `${window.location.protocol}//${window.location.hostname}/cometd/57.0/`,
            requestHeaders: {
                Authorization: `OAuth ${this.sessionId}`
            },
            appendMessageTypeToURL: false,
            logLevel: 'info'
        });
        this.cometdLib.websocketEnabled = false;
        return new Promise((resolve, reject) => {
            this.cometdLib.handshake((status) => {
                if (status.successful) {
                    console.log('CometD handshake successful');
                    resolve();
                } else {
                    console.error('CometD handshake failed', status);
                    reject(status);
                }
            });
        });
    }

    /**
     * @param {string} channel - The event channel name.
     * @param {function} handler - The handler function.
     */
    subscribe(channel, handler) {
        if (!this.cometdInitialized) {
            console.warn('CometD is not initialized. Call initialize() first.');
            return;
        }

        if (this.subscriptionHandles[channel]) {
            console.warn(`Already subscribed to ${channel}`);
            return;
        }

        const handle = this.cometdLib.subscribe(
            channel,
            handler.bind(this.component)
        );

        this.subscriptionHandles[channel] = handle;
        console.log(`Subscribed to: ${channel}`);
    }

    /**
     * @param {string} channel - The event channel name.
     */
    unsubscribe(channel) {
        const handle = this.subscriptionHandles[channel];
        if (handle) {
            this.cometdLib.unsubscribe(handle);
            delete this.subscriptionHandles[channel];
            console.log(`Unsubscribed from: ${channel}`);
        } else {
            console.warn(`No subscription found for channel: ${channel}`);
        }
    }

    unsubscribeAll() {
        for (const [channel, handle] of Object.entries(this.subscriptionHandles)) {
            if (handle) {
                this.cometdLib.unsubscribe(handle);
                console.log(`Unsubscribed from: ${channel}`);
            }
        }
        this.subscriptionHandles = {};
    }
}