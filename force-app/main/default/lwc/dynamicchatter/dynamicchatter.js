import { LightningElement, api, track, wire } from 'lwc';
import askAboutScreen from '@salesforce/apex/Dynamicchattercontroller.askAboutScreen';
import getScreenConfig from '@salesforce/apex/Dynamicchattercontroller.getScreenConfig';

const MAX_HISTORY_TURNS = 6;

export default class DynamicChatter extends LightningElement {
    @api label = 'Ask AI';
    @api heading;
    @api screenKey = '';
    @api liveData = {};
    @api placeholder = 'Ask about what you see on this screen…';
    @api
    get suggestions() { return this._suggestions; }
    set suggestions(value) { this._suggestions = Array.isArray(value) ? value : []; }
    _suggestions = [];

    @track messages = [];
    isOpen = false;
    inputValue = '';
    isLoading = false;
    _msgCounter = 0;
    _config = {};

    @wire(getScreenConfig, { screenKey: '$screenKey' })
    wiredConfig({ data }) {
        if (data) this._config = data;
    }

    get hasMessages() { return this.messages.length > 0; }
    get sendDisabled() { return !this.inputValue.trim() || this.isLoading; }
    get resolvedHeading() { return this.heading || this._config.heading || 'Ask about this screen'; }

    get emptyStateText() {
        return 'Ask me anything about this screen — what you are seeing, or why something is missing.';
    }

    get suggestedQuestions() {
        if (this._suggestions.length) return this._suggestions;
        if (Array.isArray(this._config.suggestions) && this._config.suggestions.length) {
            return this._config.suggestions;
        }
        return [
            'What am I looking at on this screen?',
            'Why is nothing showing here?',
            'What decides which rows appear?'
        ];
    }

    handleOpen() { this.isOpen = true; }
    handleClose() { this.isOpen = false; }
    handleBackdropClick() { this.handleClose(); }
    stopPropagation(event) { event.stopPropagation(); }
    handleClear() { this.messages = []; }

    handleInputChange(event) {
        this.inputValue = event.target.value;
        const ta = event.target;
        ta.style.height = 'auto';
        ta.style.height = Math.min(ta.scrollHeight, 120) + 'px';
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            this.handleSend();
        }
    }

    handleSuggestion(event) {
        this.inputValue = event.currentTarget.dataset.q;
        this.handleSend();
    }

    async handleSend() {
        const question = this.inputValue.trim();
        if (!question || this.isLoading) return;

        this.inputValue = '';
        this.isLoading = true;
        const userId = String(++this._msgCounter);
        const aiId = String(++this._msgCounter);
        const historyString = this._buildHistoryString();

        this.messages = [
            ...this.messages,
            { id: userId, wrapClass: 'dc-msg-wrap dc-msg-wrap_user', bubbleClass: 'dc-bubble dc-bubble_user', text: question },
            { id: aiId, wrapClass: 'dc-msg-wrap dc-msg-wrap_ai', bubbleClass: 'dc-bubble dc-bubble_ai', isLoading: true }
        ];
        this._scrollToBottom();

        try {
            const result = await askAboutScreen({
                screenKey: this.screenKey,
                liveDataJson: JSON.stringify(this.liveData || {}),
                conversationHistory: historyString,
                userQuestion: question
            });
            const hasError = !!result.error;
            const text = hasError ? result.error : result.answer;
            this._replace(aiId, {
                bubbleClass: hasError ? 'dc-bubble dc-bubble_ai dc-bubble_error' : 'dc-bubble dc-bubble_ai',
                hasError,
                text,
                isRich: !hasError,
                html: hasError ? '' : this._toHtml(text)
            });
        } catch (error) {
            this._replace(aiId, {
                bubbleClass: 'dc-bubble dc-bubble_ai dc-bubble_error',
                hasError: true,
                text: 'I could not reach the assistant. Please try again.',
                isRich: false
            });
        } finally {
            this.isLoading = false;
            this._scrollToBottom();
        }
    }

    _replace(id, patch) {
        this.messages = this.messages.map(m => m.id !== id ? m : {
            id,
            wrapClass: 'dc-msg-wrap dc-msg-wrap_ai',
            isLoading: false,
            ...patch
        });
    }

    _toHtml(text) {
        if (!text) return '';
        const esc = String(text)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        const lines = esc.split('\n');
        let html = '';
        let inList = false;
        for (const raw of lines) {
            const line = raw.trim();
            const bullet = /^[-*•]\s+/.test(line);
            if (bullet) {
                if (!inList) { html += '<ul>'; inList = true; }
                html += '<li>' + line.replace(/^[-*•]\s+/, '') + '</li>';
            } else {
                if (inList) { html += '</ul>'; inList = false; }
                if (line) html += '<p>' + line + '</p>';
            }
        }
        if (inList) html += '</ul>';
        return html
            .replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
            .replace(/`(.+?)`/g, '<b>$1</b>');
    }

    _buildHistoryString() {
        const turns = [];
        const msgs = this.messages;
        for (let i = 0; i < msgs.length; i++) {
            if (msgs[i].wrapClass === 'dc-msg-wrap dc-msg-wrap_user') {
                const next = msgs[i + 1];
                const aiText = next && !next.isLoading ? next.text : '';
                turns.push(`User: ${msgs[i].text}\nAssistant: ${aiText}`);
            }
        }
        return turns.slice(-MAX_HISTORY_TURNS).join('\n');
    }

    _scrollToBottom() {
        setTimeout(() => {
            const body = this.template.querySelector('.dc-popup-body');
            if (body) body.scrollTop = body.scrollHeight;
        }, 50);
    }
}