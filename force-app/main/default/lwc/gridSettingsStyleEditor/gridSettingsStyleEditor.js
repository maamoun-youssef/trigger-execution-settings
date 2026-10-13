import { LightningElement, track, api } from 'lwc';

//labels
import { Labels } from "c/gridSettingsHelper"

export default class GridSettingsStyleEditor extends LightningElement {
    Label = Labels;

    borderStyleOptions = [
        { label: this.Label.LBL_Unset, value: ' ' },
        { label: this.Label.LBL_None, value: 'none' },
        { label: this.Label.LBL_Dotted, value: 'dotted' },
        { label: this.Label.LBL_Dashed, value: 'dashed' },
        { label: this.Label.LBL_Solid, value: 'solid' },
        { label: this.Label.LBL_Double, value: 'double' },
        { label: this.Label.LBL_Groove, value: 'groove' },
        { label: this.Label.LBL_Ridge, value: 'ridge' },
        { label: this.Label.LBL_Inset, value: 'inset' },
        { label: this.Label.LBL_Outset, value: 'outset' },
    ];

    @api apiFieldStyle;
    @api eventName;
    @api cancelEvent;
    @track isCenter = false;
    @track isRight = false;
    @track isLeft = false;
    @track fieldStyle = {
        isAdvanced: false,
        advancedStyle: '',
        textStyle: {
            isItalic: false,
            isCenter: false,
            isUnderLine: false,
            isStrikeThrought: false,
            color: '',
            size: '',
            align: '',
        },
        bgColor: '',
        width: '',
        borderStyle: { color: '', pattern: '', size: '' },
        style: '',
    };

    getFieldStyle() {
        let fieldStyle = JSON.parse(JSON.stringify(this.fieldStyle));
        if (fieldStyle.isAdvanced) {
            fieldStyle = { isAdvanced: true, advancedStyle: fieldStyle.advancedStyle, style: fieldStyle.style };
        } else {
            if (!fieldStyle.borderStyle)
                fieldStyle = { textStyle: fieldStyle.textStyle, bgColor: fieldStyle.bgColor, width: fieldStyle.width, style: fieldStyle.style };
            else
                fieldStyle = { textStyle: fieldStyle.textStyle, bgColor: fieldStyle.bgColor, width: fieldStyle.width, borderStyle: fieldStyle.borderStyle, style: fieldStyle.style };
        }
        return fieldStyle;
    }

    connectedCallback() {
        try {
            if (this.apiFieldStyle) {
                let apiFieldStyle = this.apiFieldStyle;
                if (apiFieldStyle.hasOwnProperty('advancedStyle') && apiFieldStyle.advancedStyle) {
                    this.fieldStyle.advancedStyle = apiFieldStyle.advancedStyle;
                }
                if (apiFieldStyle.hasOwnProperty('isAdvanced') && apiFieldStyle.isAdvanced) {
                    this.fieldStyle.isAdvanced = apiFieldStyle.isAdvanced;
                }
                if (apiFieldStyle.hasOwnProperty('textStyle') && apiFieldStyle.textStyle) {
                    this.fieldStyle.textStyle = apiFieldStyle.textStyle;
                }
                if (apiFieldStyle.hasOwnProperty('width') && apiFieldStyle.width) {
                    this.fieldStyle.width = apiFieldStyle.width;
                }
                if (apiFieldStyle.hasOwnProperty('bgColor') && apiFieldStyle.bgColor) {
                    this.fieldStyle.bgColor = apiFieldStyle.bgColor;
                }
                if (apiFieldStyle.hasOwnProperty('borderStyle') && apiFieldStyle.borderStyle && apiFieldStyle.borderStyle != null) {
                    this.fieldStyle.borderStyle = apiFieldStyle.borderStyle;
                }
                this.fieldStyle = JSON.parse(JSON.stringify(this.fieldStyle));
                this.isRight = this.fieldStyle && this.fieldStyle.textStyle && this.fieldStyle.textStyle.align == 'right';
                this.isLeft = this.fieldStyle && this.fieldStyle.textStyle && this.fieldStyle.textStyle.align == 'left';
                this.isCenter = this.fieldStyle && this.fieldStyle.textStyle && this.fieldStyle.textStyle.align == 'center';
            }
        } catch (error) {
            console.log(error);
        }
        this.refreshStyleValue();
    }

    notifyParent() {
        try {
            if (this.eventName) {
                const eventName = new CustomEvent(this.eventName, {
                    detail: { value: JSON.stringify(this.getFieldStyle()) },
                });
                this.dispatchEvent(eventName);
            }
        } catch (error) {
            console.log(error);
        }
    }

    refreshStyleValue() {
        let fieldStyle = this.fieldStyle;
        let content = '';
        if (fieldStyle) {
            if (fieldStyle.isAdvanced) {
                content = fieldStyle.advancedStyle;
            } else {
                let textStyle = fieldStyle.textStyle;
                let borderStyle = fieldStyle.borderStyle;
                content += fieldStyle.width ? 'min-width: ' + fieldStyle.width + '; max-width: ' + fieldStyle.width + '; width: ' + fieldStyle.width + ';' : '';
                content += fieldStyle.bgColor ? 'background-color: ' + fieldStyle.bgColor + ';' : '';
                if (textStyle) {
                    content += textStyle.isItalic ? 'font-style: italic;' : '';
                    content += textStyle.isBold ? 'font-weight: bold;' : '';
                    content += textStyle.isUnderLine || textStyle.isStrikeThrought ? 'text-decoration:' + (textStyle.isUnderLine ? ' underline ' : '') + (textStyle.isStrikeThrought ? ' line-through ' : '') + ';' : '';
                    content += textStyle.color ? 'color: ' + textStyle.color + ';' : '';
                    content += textStyle.size ? 'font-size: ' + textStyle.size + ';' : '';
                    content += textStyle.align ? 'text-align: ' + textStyle.align + ';' : '';
                }
                if (borderStyle) {
                    content += borderStyle.size ? 'border-width: ' + borderStyle.size + ';' : '';
                    content += borderStyle.color ? 'border-color: ' + borderStyle.color + ';' : '';
                    content += borderStyle.pattern ? 'border-style: ' + borderStyle.pattern + ';' : '';
                    //content += borderStyle.style ? ' ' + borderStyle.style + ';' : '';
                }
            }
        }
        this.fieldStyle.style = content;
        this.notifyParent();
    }

    IsAdvancedChangeHandler(event) {
        this.fieldStyle.isAdvanced = event.target.checked;
        this.refreshStyleValue();
    }

    advancedStyleChangeHandler(event) {
        this.fieldStyle.advancedStyle = event.detail.value;
        this.refreshStyleValue();
    }

    textColorChangeHandler(event) {
        this.fieldStyle.textStyle.color = event.detail.value;
        this.refreshStyleValue();
    }

    textSizeChangeHandler(event) {
        this.fieldStyle.textStyle.size = event.detail.value;
        this.refreshStyleValue();
    }

    toggleIsItalic() {
        this.fieldStyle.textStyle.isItalic = !this.fieldStyle.textStyle.isItalic;
        this.refreshStyleValue();
    }

    toggleIsBold() {
        this.fieldStyle.textStyle.isBold = !this.fieldStyle.textStyle.isBold;
        this.refreshStyleValue();
    }

    toggleIsRight() {
        this.isRight = !this.isRight;
        this.isLeft = false;
        this.isCenter = false;
        this.fieldStyle.textStyle.align = this.isRight ? 'right' : '';
        this.refreshStyleValue();
    }

    toggleIsLeft() {
        this.isLeft = !this.isLeft;
        this.isRight = false;
        this.isCenter = false;
        this.fieldStyle.textStyle.align = this.isLeft ? 'left' : '';
        this.refreshStyleValue();
    }

    toggleIsCenter() {
        this.isCenter = !this.isCenter;
        this.isRight = false;
        this.isLeft = false;
        this.fieldStyle.textStyle.align = this.isCenter ? 'center' : '';
        this.refreshStyleValue();
    }

    toggleIsUnderLine() {
        this.fieldStyle.textStyle.isUnderLine = !this.fieldStyle.textStyle.isUnderLine;
        this.refreshStyleValue();
    }

    toggleIsStrikeThrought() {
        this.fieldStyle.textStyle.isStrikeThrought = !this.fieldStyle.textStyle.isStrikeThrought;
        this.refreshStyleValue();
    }

    widthChangeHandler(event) {
        this.fieldStyle.width = event.detail.value;
        this.refreshStyleValue();
    }

    backgroundColorChangeHandler(event) {
        this.fieldStyle.bgColor = event.detail.value;
        this.refreshStyleValue();
    }

    borderSizeChangeHandler(event) {
        this.fieldStyle.borderStyle.size = event.detail.value;
        this.refreshStyleValue();
    }

    borderPaternChangeHandler(event) {
        this.fieldStyle.borderStyle.pattern = event.detail.value;
        this.refreshStyleValue();
    }

    borderColorChangeHandler(event) {
        this.fieldStyle.borderStyle.color = event.detail.value;
        this.refreshStyleValue();
    }

}