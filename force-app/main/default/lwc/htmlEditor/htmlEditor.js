import { LightningElement, track, api } from 'lwc';
export default class htmlEditor extends LightningElement {
    //@api htmlContent; // Input content passed from the parent component
    //activeButtons = new Map(); // Track active formatting buttons
    @track content = ''; // Holds the editor content
    @track showBalloon = false; // Whether the balloon toolbar is visible
    @track balloonStyle = ''; // Inline style for balloon positioning
    //@track activeCommands = new Set(); // Stores active formatting commands
    @track arrowPhase = 'center'; // Balloon arrow position: 'left', 'center', or 'right'
    @track savedSelection; // Stores the selection range for later use
    @track selectedText = ''; // The selected text
    @track showLinkBalloon = false;
    @track linkBalloonStyle = '';
    @track showSource = false;
    @track sourceCode = '';
    @track savedRange = null;
    currentFontSize = '3'; // corresponds to 12px
    currentFontFamily = '';// Track current font family
    textColor = '#000000';      // default black
    backgroundColor = '#ffffff'; // default white
    renderedCallback() {
        const editor = this.template.querySelector('.editor');
        if (!this.dropdownInitialized) {
           //  Set dropdown to default font size
            const fontSelect = this.template.querySelector('.font-size-select');
            if (fontSelect) {
                Array.from(fontSelect.options).forEach(option => {
                    option.selected = option.value === this.currentFontSize;
                });
            }

            this.dropdownInitialized = true;
        }

        if (editor && !this.caretListenerAdded) {
            // Attach caret change listeners (keyboard/mouse)
            editor.addEventListener('keyup', () => this.handleCaretChange());
            editor.addEventListener('mouseup', () => this.handleCaretChange());
            this.caretListenerAdded = true; // Prevent multiple attachments
        }
    }
    // Execute formatting command
    execCommand(command, value = null) {
        document.execCommand(command, false, value);
    }
    handleCaretChange() {
        // Commands to monitor for active state
        const commands = ['bold', 'italic', 'underline', 'insertOrderedList', 'insertUnorderedList'];

        commands.forEach(cmd => {
            // Select all toolbar and balloon buttons with this command
            const buttons = this.template.querySelectorAll(`button[data-cmd="${cmd}"]`);
            const isActive = document.queryCommandState(cmd); // Check if command is active

            buttons.forEach(button => {
                if (isActive) {
                    button.classList.add('active-btn'); // Highlight active buttons
                } else {
                    button.classList.remove('active-btn'); // Remove highlight
                }
            });
        });
      this.updateCaretDropdowns();
    }

updateCaretDropdowns() {
        const selection = window.getSelection();
        if (!selection.rangeCount) return;

        let node = selection.focusNode;
        if (node.nodeType === Node.TEXT_NODE) {
            node = node.parentNode;
        }
        const editor = this.template.querySelector('.editor');
        let foundHeading = null;
        let foundSize = null;
        let foundFont = null;

        // Traverse up to find heading, font size, and font family
        while (node && node !== editor) {
            const tag = node.nodeName;
            // Only compute style if this is an element
    let style = null;
    if (node.nodeType === Node.ELEMENT_NODE) {
        style = window.getComputedStyle(node);
    }

            // Check heading
            if (!foundHeading && ['H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'P', 'BLOCKQUOTE'].includes(tag)) {
                foundHeading = tag;
            }

            // Check font size
            if (!foundSize && tag === 'FONT' && node.hasAttribute('size')) {
                foundSize = node.getAttribute('size');
            }

            // Check font family
            if (!foundFont && style && style.fontFamily) {
                foundFont = style.fontFamily.replace(/["']/g, "");
            }

            node = node.parentNode;
        }

        // Update heading dropdown
        this.currentHeading = foundHeading || this.currentHeading;
        const headingSelect = this.template.querySelector('.heading-select');
        if (headingSelect) {
            Array.from(headingSelect.options).forEach(option => {
                option.selected = option.value === this.currentHeading;
            });
        }

        // Update font size dropdown
        this.currentFontSize = foundSize || this.currentFontSize;
        const sizeSelect = this.template.querySelector('.font-size-select');
        if (sizeSelect) {
            Array.from(sizeSelect.options).forEach(option => {
                option.selected = option.value === this.currentFontSize;
            });
        }

        // Update font family dropdown
        this.currentFontFamily = foundFont || this.currentFontFamily;
        const fontSelect = this.template.querySelector('.font-family-select');
        if (fontSelect) {
            Array.from(fontSelect.options).forEach(option => {
                option.selected = option.value === this.currentFontFamily;
            });
        }
    }
    toggleButton(event, command) {
        const editor = this.template.querySelector('.editor');
        editor.focus();
        document.execCommand(command, false, null);
        this.handleCaretChange();
    }
    // Handle user changing font
    changeFontFamily(event) {
        this.focusEditor();
        const value = event.target.value;
        if (value) {
            this.execCommand('fontName', value);
        }
    }
    // Called when dropdown changes
    changeFontSize(event) {
        this.focusEditor();
        const value = event.target.value;
        if (value) {
            this.execCommand('fontSize', value);
        }
    }
    changeHeading(event) {
        const value = event.target.value;
        if (value) {
            this.execCommand('formatBlock', `<${value}>`);
        }
    }
    undo() { this.execCommand('undo'); }
    redo() { this.execCommand('redo'); }
    boldText(event) { this.toggleButton(event, 'bold'); }
    italicText(event) { this.toggleButton(event, 'italic'); }
    underlineText(event) { this.toggleButton(event, 'underline'); }
    // Updated color change handlers
    changeTextColor(event) {
        this.restoreSelection();       // restore previous selection
        this.applyColorSafely('foreColor', event.target.value);
        this.textColor = event.target.value;
    }

    changeBackgroundColor(event) {
        this.restoreSelection();
        this.applyColorSafely('hiliteColor', event.target.value);
        this.backgroundColor = event.target.value;
    }
    // Save selection when user interacts with color inputs
    saveSelection() {
        const selection = window.getSelection();
        if (selection.rangeCount > 0) {
            this.savedRange = selection.getRangeAt(0).cloneRange();
        }
    }

    // Restore the saved selection
    restoreSelection() {
        if (this.savedRange) {
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(this.savedRange);
        }
    }
    // --------------------
    // Apply color safely
    // --------------------
    applyColorSafely(command, color) {
        const editor = this.template.querySelector('.editor');
        if (!editor) return;
        editor.focus();
        const selection = window.getSelection();
        if (!selection.rangeCount) return;

        const range = selection.getRangeAt(0);

        // If text is selected, apply color directly
        if (!range.collapsed) {
            document.execCommand(command, false, color);
            selection.collapseToEnd();
            this.saveSelection();
            return;
        }

        // Collapsed range: prepare a span with the new style
        let container = range.startContainer;
        if (container.nodeType === 3) container = container.parentNode;

        const isTextColor = command === 'foreColor';
       // const lastAppliedColor = isTextColor ? this.textColor : this.backgroundColor;

        // Only insert a new span if necessary (avoid redundant empty spans)
        const currentColor = container.style && (isTextColor ? container.style.color : container.style.backgroundColor);
        if (container.nodeName !== 'SPAN' || currentColor !== color) {
            const span = document.createElement('span');
            if (isTextColor) span.style.color = color;
            else span.style.backgroundColor = color;

            // Use zero-width space to prevent empty span issues
            const textNode = document.createTextNode('\u200B');
            span.appendChild(textNode);
            range.insertNode(span);
            // Move caret inside the new span
            range.setStart(textNode, 0);
            range.collapse(true);
            selection.removeAllRanges();
            selection.addRange(range);
        }

        document.execCommand(command, false, color);
        this.saveSelection();
    }
    focusEditor() {
        const editor = this.template.querySelector('.editor');
        if (editor) {
            editor.focus(); // Focus editor programmatically
        }
    }

    updateButtonStates() {
        try {
            // Sync formatting states
            this.isBold = document.queryCommandState('bold');
            this.isItalic = document.queryCommandState('italic');
            this.isUnderline = document.queryCommandState('underline');
            this.olActive = document.queryCommandState("insertOrderedList");
            this.ulActive = document.queryCommandState("insertUnorderedList");
        } catch (e) {
            console.warn('queryCommandState not supported', e);
        }
    }

    // Button classes (applied when active)
    get boldClass() {
        return this.isBold ? 'active-btn' : '';
    }
    get italicClass() {
        return this.isItalic ? 'active-btn' : '';
    }
    get underlineClass() {
        return this.isUnderline ? 'active-btn' : '';
    }
    get olButtonClass() {
        return this.olActive ? 'active-btn' : '';
    }
    get ulButtonClass() {
        return this.ulActive ? 'active-btn' : '';
    }
    get textColorStyle() {
        return `background-color: ${this.textColor}; border-radius: 3px;`;
    }
    get backgroundColorStyle() {
        return `background-color: ${this.backgroundColor}; border-radius: 3px;`;
    }
    get balloonClass() {
        return 'toolbar-balloon' + this.arrowPhase; // Dynamic balloon CSS class
    }
    get linkBalloonClass() {
        return 'link-balloon' + this.arrowPhase; // 'link-balloon left', 'link-balloon center', 'link-balloon right'
    }
    get lineNumbers() {
        return this.sourceCode.split('\n').map((_, i) => i + 1);
    }
    @api
    getContent() { 
        return this.template.querySelector('.editor').innerHTML;
    }
    connectedCallback() {
        // Listen for selection changes
        document.addEventListener('selectionchange', this.handleSelectionChangeDebounced.bind(this));
        document.addEventListener('selectionchange', this.updateButtonStates.bind(this));
        // Hide balloon when clicking anywhere outside
    }
    // Debounce selection changes to avoid flicker
    handleSelectionChangeDebounced(event) {
        const selection = window.getSelection();
        if (selection.isCollapsed) {
            this.showBalloon = false; // Hide balloon if no text selected
            return;
        }
        this.savedRange = selection.getRangeAt(0).cloneRange();
        if (this.selectionTimer) clearTimeout(this.selectionTimer);

        this.selectionTimer = setTimeout(() => {
            this.handleSelectionChange();
        }, 150); // Delay to wait for stable selection
    }

    isSelectionInsideEditor(selection) {
        if (!selection || !selection.rangeCount) return false;

        const editor = this.template.querySelector('.editor');
        if (!editor) return false;

        const range = selection.getRangeAt(0);

        // Walk up the DOM tree to check if a node belongs to the editor
        const isNodeInsideEditor = (node) => {
            while (node) {
                if (node === editor) return true;
                node = node.parentNode;
            }
            return false;
        };

        // Ensure both start and end are inside the editor
        return isNodeInsideEditor(range.startContainer) && isNodeInsideEditor(range.endContainer);
    }
    handleSelectionChange() {
        const selection = window.getSelection();
        if (!this.isSelectionInsideEditor(selection)) {
            // Save selection for later use, hide balloon
            this.showBalloon = false;
            return;
        }

        // Build a range for positioning
        const range = document.createRange();
        range.setStart(selection.focusNode, selection.focusOffset);
        range.setEnd(selection.focusNode, selection.focusOffset);

        const rect = range.getBoundingClientRect();
        if (!rect) return;

        const balloonWidth = 227;
        const pageWidth = document.body.clientWidth;
        const top = rect.bottom + window.scrollY - 90;
        let left;

        // Position balloon and adjust arrow phase
        if (rect.left < balloonWidth / 2) {
            left = rect.left - 30;
            this.arrowPhase = 'left';
        } else if (rect.right + balloonWidth / 2 > pageWidth) {
            left = rect.right - balloonWidth + 10;
            this.arrowPhase = 'right';
        } else {
            left = (rect.left + rect.width / 2 - balloonWidth / 2) - 10;
            this.arrowPhase = 'center';
        }

        // Set balloon style dynamically
        this.balloonStyle = `
        position: absolute;
        top: ${top}px;
        left: ${left}px;
        width: ${balloonWidth}px;
        background: #fff;
        border: 1px solid #ccc;
        padding: 4px;
        border-radius: 6px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.2);
        z-index: 1000;
    `;

        this.showBalloon = true; // Show balloon
    }

    handleContentChange() {
        const editorDiv = this.template.querySelector('.editor');
        this.content = editorDiv.innerHTML;

        this.dispatchEvent(new CustomEvent('contentchange', {
            detail: { value: this.content }
        }));

        // this.updateToolbarState();
    }
    // Lists
    numberedList() {
        this.focusEditor();
        this.toggleButton(event, 'insertOrderedList');
    }
    bulletedList(event) {
        this.toggleButton(event, 'insertUnorderedList');
    }

    insertLink() {
        const selection = window.getSelection();
        this.showBalloon = false;

        if (selection.rangeCount && this.isSelectionInsideEditor(selection)) {
            this.savedSelection = selection.getRangeAt(0).cloneRange();
            this.selectedText = selection.toString(); // drives text input

            // Check if selection is inside an existing link
            let container = selection.focusNode;
            if (container.nodeType === Node.TEXT_NODE) container = container.parentNode;

            let linkNode = null;
            let node = container;
            const editor = this.template.querySelector('.editor');

            while (node && node !== editor) {
                if (node.nodeName === 'A') {
                    linkNode = node;
                    break;
                }
                node = node.parentNode;
            }

            // inside insertLink()
            if (linkNode) {
                let href = linkNode.getAttribute('href'); // get raw value instead of linkNode.href
                this.preFilledURL = href || '';          // use this to prefill the input
            } else {
                this.preFilledURL = '';
            }


        } else if (this.savedSelection) {
            selection.removeAllRanges();
            selection.addRange(this.savedSelection);
            this.selectedText = selection.toString();
            this.preFilledURL = '';
        } else {
            return;
        }

        this.showLinkBalloon = false;
        requestAnimationFrame(() => {
            this.showLinkBalloon = true;
            this.updateLinkBalloonPosition();
            if (!this.isOutsideClickListenerAdded) {
                window.addEventListener('click', this.handleOutsideClick);
                this.isOutsideClickListenerAdded = true;
            }
        });
    }

    handleConfirmLink() {
        const textInput = this.template.querySelector('.link-text').value || 'Link';
        const url = this.template.querySelector('.link-url').value;

        if (!url) {
            alert('Please enter a valid URL');
            return;
        }

        const editor = this.template.querySelector('.editor');
        editor.focus();

        const selection = window.getSelection();
        if (!selection.rangeCount) return;

        // Restore the saved selection
        selection.removeAllRanges();
        if (this.savedSelection) {
            selection.addRange(this.savedSelection);
        }

        const range = selection.getRangeAt(0);

        // Check if selection is inside an existing link
        let container = range.startContainer;
        if (container.nodeType === 3) container = container.parentNode; // text node → parent

        let linkNode = null;
        if (container.nodeName === 'A') {
            linkNode = container;
        } else {
            // traverse up in case nested inside other elements
            let node = container;
            while (node && node !== editor) {
                if (node.nodeName === 'A') {
                    linkNode = node;
                    break;
                }
                node = node.parentNode;
            }
        }

        const safeText = textInput.replace(/\n/g, '<br>');

        if (linkNode) {
            // Update link URL
            linkNode.href = url;
            linkNode.target = '_blank';

            // Replace only the selected text inside the link
            range.deleteContents();

            const fragment = document.createDocumentFragment();
            const textNode = document.createTextNode(safeText);
            fragment.appendChild(textNode);
            range.insertNode(fragment);

            // Move caret after inserted text
            const newRange = document.createRange();
            newRange.setStartAfter(textNode);
            newRange.collapse(true);

            const sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(newRange);
        } else {
            // Insert new link
            const linkHTML = `<a href="${url}" target="_blank">${safeText}</a>`;
            document.execCommand('insertHTML', false, linkHTML);
        }


        this.showLinkBalloon = false;
        this.savedSelection = null;
    }

    closeLinkBalloon() {
        this.showLinkBalloon = false;

        if (this.isOutsideClickListenerAdded) {
            window.removeEventListener('click', this.handleOutsideClick);
            this.isOutsideClickListenerAdded = false;
        }
    }

    // This runs whenever a click happens
    handleOutsideClick = (event) => {
        const balloon = this.template.querySelector('.link-balloon');

        // Only close if click is outside the balloon
        if (balloon && !balloon.contains(event.target)) {
            this.closeLinkBalloon();
        }
    }

    // Prevent the balloon from closing if clicked inside
    handleBalloonClick(event) {
        event.stopPropagation(); // stops click from bubbling to window
    }

    updateLinkBalloonPosition() {
        const selection = window.getSelection();
        if (!selection.rangeCount) return;

        //const range = selection.getRangeAt(0);
        const range = document.createRange();
        range.setStart(selection.focusNode, selection.focusOffset);
        range.setEnd(selection.focusNode, selection.focusOffset);

        let rect = range.getBoundingClientRect();
        if (rect.width === 0 && rect.height === 0) {
            const tempSpan = document.createElement('span');
            tempSpan.textContent = '\u200B';
            range.insertNode(tempSpan);
            rect = tempSpan.getBoundingClientRect();
            tempSpan.remove();
            selection.removeAllRanges();
            selection.addRange(range);
        }

        // If rect is empty (width or height is 0), try fallback
        const pageWidth = document.body.clientWidth;
        const balloonWidth = 220;

        let left;
        if (rect.left < balloonWidth / 2) {
            left = rect.left - 30;
            this.arrowPhase = 'left';
        } else if (rect.right + balloonWidth / 2 > pageWidth) {
            left = rect.right - balloonWidth + 10;
            this.arrowPhase = 'right';
        } else {
            left = (rect.left + rect.width / 2 - balloonWidth / 2) - 10;
            this.arrowPhase = 'center';
        }

        const top = rect.bottom + window.scrollY - 90;
        this.linkBalloonStyle = `
        position: absolute;
        top: ${top}px;
        left: ${left}px;
        width: ${balloonWidth}px;
    `;
    }

    toggleSource() {
        const editor = this.template.querySelector('.editor');
        this.showSource = !this.showSource;
        this.showBalloon = false;
        if (this.showSource && editor) {
            this.sourceCode = this.formatCleanHTML(editor.innerHTML);

        }
    }

    formatCleanHTML(rawHTML) {
        const container = document.createElement('div');
        container.innerHTML = rawHTML;

        container.querySelectorAll('b').forEach(el => {
            const strong = document.createElement('strong');
            strong.innerHTML = el.innerHTML;
            el.replaceWith(strong);
        });
        Array.from(container.childNodes).forEach(node => {
            if (
                (node.nodeType === Node.TEXT_NODE && node.textContent.trim() !== '') ||
                node.nodeName === 'DIV' ||
                node.nodeName === 'STRONG'
            ) {
                const p = document.createElement('p');
                p.innerHTML = node.nodeType === Node.TEXT_NODE ? node.textContent : node.outerHTML;
                node.replaceWith(p);
            }
        });

        return this.indentHTML(container.innerHTML);
    }


    indentHTML(html) {
        const tab = '    ';
        let result = '';
        let indent = '';

        html.split(/>\s*</).forEach(element => {
            if (!element.trim()) return;
            let clean = element.replace(/^</, '').replace(/>$/, '');
            if (clean.match(/^\/\w/)) indent = indent.substring(tab.length);
            result += indent + '<' + clean + '>\n';
            if (clean.match(/^<?\w[^>]*[^\/]$/)) indent += tab;
        });

        return result.trim();
    }
    // --------------------
    // Save source code
    // --------------------
    saveSource() {
        const editor = this.template.querySelector('.editor');
        if (!editor) return;

        const temp = document.createElement('div');
        temp.innerHTML = this.sourceCode || '';

        // Remove empty text nodes
        const walker = document.createTreeWalker(temp, NodeFilter.SHOW_TEXT, null, false);
        const removeTextNodes = [];
        while (walker.nextNode()) {
            const t = walker.currentNode;
            if (!/\S/.test(t.nodeValue)) removeTextNodes.push(t);
        }
        removeTextNodes.forEach(t => t.parentNode && t.parentNode.removeChild(t));

        // Remove empty spans, paragraphs, divs
        temp.querySelectorAll('span,p,div').forEach(el => {
            if (!el.textContent.trim() && !el.querySelector('img,br,iframe,video,svg')) {
                el.remove();
            }
        });

        temp.normalize(); // merge adjacent text nodes

        const htmlToInsert = temp.innerHTML.trim();

        // Insert cleaned HTML using execCommand (LWS-safe)
        editor.focus();
        const selection = window.getSelection();
        selection.removeAllRanges();
        const range = document.createRange();
        range.selectNodeContents(editor);
        selection.addRange(range);

        document.execCommand('insertHTML', false, htmlToInsert);
        selection.collapseToEnd();

        this.showSource = false;
    }

    cancelSource() {
        this.showSource = false;
    }

    handleSourceBackdropClick() {
        this.cancelSource();
    }

    handleSourceInput(event) {
        this.sourceCode = event.target.value;
    }

    handleTextareaScroll(event) {
        const lineNumbers = this.template.querySelector('.line-numbers');
        if (lineNumbers) {
            lineNumbers.scrollTop = event.target.scrollTop;
        }
    }

}