import { showNotification } from 'c/appHelper';
import { LegalDoc_API, LegalDocClause_API, TrackAction_API, Supplier_API, GlobalLocation_API } from './properties.js';
export function generatePdf(clauses, legalDoc, currentUser) {
    const { jsPDF } = window.jspdf;
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();
    const margin = 15;
    let yPosition = margin;
    const baseLineHeight = 5.5;
    const paragraphIndent = 12;
    const paragraphSpacing = 1.5;
    // Helper function to check page break
    const checkPageBreak = (neededSpace = 15) => {
        if (yPosition > pageHeight - margin - neededSpace) {
            pdf.addPage();
            yPosition = margin;
        }
    };
    // Helper: get plain text from a node (strips HTML)
    const getTextFromNode = (node) => {
        if (!node) return '';
        if (node.nodeType === Node.TEXT_NODE) return node.textContent || '';
        return Array.from(node.childNodes).map(getTextFromNode).join('');
    };

    // Remove tags with href="#MergeField{!...}" (unwrap, keep text)
    const stripMergeFieldLinks = (h) => {
        if (!h) return h;
        const div = document.createElement('div');
        div.innerHTML = h;
        div.querySelectorAll('a[href]').forEach(a => {
            const href = (a.getAttribute('href') || '').toLowerCase();
            if (href.includes('#mergefield')) {
                const span = document.createElement('span');
                span.innerHTML = a.innerHTML;
                a.parentNode.replaceChild(span, a);
            }
        });
        return div.innerHTML;
    };

    // Parse HTML into blocks (paragraphs, tables, images)
    const parseHtmlToBlocks = (html) => {
        const blocks = [];
        const temp = document.createElement('div');
        temp.innerHTML = stripMergeFieldLinks(html);

        // Process lists in document order when encountered (not deferred)
        const processList = (listNode) => {
            const isOrdered = listNode.tagName.toLowerCase() === 'ol';
            const listItems = listNode.querySelectorAll('li');
            let listIndex = 0;
            listItems.forEach(li => {
                let listLevel = 0;
                let parent = li.parentElement;
                while (parent && parent !== temp) {
                    const parentTag = parent.tagName ? parent.tagName.toLowerCase() : '';
                    if (parentTag === 'ul' || parentTag === 'ol') listLevel++;
                    parent = parent.parentElement;
                }
                const listIndent = 10 + (listLevel * 15);
                const listParagraph = { segments: [], center: false, right: false, indent: listIndent, isList: true, bulletPrefix: isOrdered ? `${++listIndex}. ` : '• ' };
                listParagraph.segments.push({ text: listParagraph.bulletPrefix, bold: false, italic: false, underline: false, strikethrough: false, subscript: false, superscript: false, fontSize: null, fontFamily: null, link: null });
                listParagraph.segments.push({ text: ' ', bold: false, italic: false, underline: false, strikethrough: false, subscript: false, superscript: false, fontSize: null, fontFamily: null, link: null });
                const walkListNode = (node, styles) => {
                    if (node.nodeType === Node.TEXT_NODE && node.textContent) {
                        listParagraph.segments.push({ text: node.textContent, bold: styles.bold, italic: styles.italic, underline: styles.underline, strikethrough: styles.strikethrough, subscript: styles.subscript || false, superscript: styles.superscript || false, fontSize: styles.fontSize || null, fontFamily: styles.fontFamily || null, link: styles.link || null });
                    } else if (node.nodeType === Node.ELEMENT_NODE) {
                        const newStyles = { ...styles };
                        const tag = node.tagName.toLowerCase();
                        const style = node.getAttribute('style') || '';
                        if (tag === 'strong' || tag === 'b') newStyles.bold = true;
                        if (tag === 'em' || tag === 'i') newStyles.italic = true;
                        if (tag === 'u') newStyles.underline = true;
                        if (tag === 'strike' || tag === 's' || tag === 'del') newStyles.strikethrough = true;
                        if (tag === 'sub') newStyles.subscript = true;
                        if (tag === 'sup') newStyles.superscript = true;
                        if (tag === 'a') { const h = node.getAttribute('href') || ''; newStyles.link = h && !/^(https?:|mailto:)/i.test(h) ? 'http://' + h : h; newStyles.underline = true; }
                        const fs = style.match(/font-size:\s*([\d.]+)(px|pt|em|%)/i);
                        if (fs) { const v = parseFloat(fs[1]), u = (fs[2] || 'px').toLowerCase(); let pt = u === 'pt' ? v : u === 'px' ? v * 0.75 : (styles.fontSize || 10) * (u === 'em' ? v : v / 100); newStyles.fontSize = Math.min(pt, 15); }
                        const ff = style.match(/font-family:\s*([^;]+)/i);
                        if (ff) newStyles.fontFamily = ff[1].trim().replace(/['"]/g, '').split(',')[0].trim();
                        if (/font-weight:\s*bold/i.test(style)) newStyles.bold = true;
                        if (/font-style:\s*italic/i.test(style)) newStyles.italic = true;
                        if (/text-decoration:[^;]*underline/i.test(style)) newStyles.underline = true;
                        if (/text-decoration:[^;]*line-through/i.test(style)) newStyles.strikethrough = true;
                        for (const c of node.childNodes) walkListNode(c, newStyles);
                    }
                };
                for (const c of li.childNodes) walkListNode(c, { bold: false, italic: false, underline: false, strikethrough: false, subscript: false, superscript: false, link: null });
                if (listParagraph.segments.length > 0) blocks.push({ type: 'paragraph', ...listParagraph });
            });
        };

        // Handle regular content
        let currentParagraph = { segments: [], center: false, right: false, indent: 0, isList: false };
        const walkNode = (node, styles, indentLevel = 0) => { // indentLevel in mm                
            if (node.nodeType === Node.TEXT_NODE) {
                const text = node.textContent || '';
                if (text) {
                    currentParagraph.segments.push({
                        text: text,
                        bold: styles.bold,
                        italic: styles.italic,
                        underline: styles.underline,
                        strikethrough: styles.strikethrough,
                        subscript: styles.subscript || false,
                        superscript: styles.superscript || false,
                        fontSize: styles.fontSize || null,
                        fontFamily: styles.fontFamily || null,
                        link: styles.link || null
                    });
                    if (styles.center) currentParagraph.center = true;
                    if (styles.right) currentParagraph.right = true;
                    currentParagraph.indent = typeof indentLevel === 'number' ? indentLevel : indentLevel * 0.264583;
                }
            } else if (node.nodeType === Node.ELEMENT_NODE) {
                const newStyles = { ...styles };
                const tagName = node.tagName.toLowerCase();
                const style = node.getAttribute('style') || '';

                const isBlock = ['p', 'center', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(tagName);
                const isList = tagName === 'ul' || tagName === 'ol' || tagName === 'li';
                const isBr = tagName === 'br';
                const isTable = tagName === 'table';
                const isImg = tagName === 'img';

                // Handle table: parse and add table block
                if (isTable) {
                    if (currentParagraph.segments.length > 0) {
                        blocks.push({ type: 'paragraph', ...currentParagraph });
                        currentParagraph = { segments: [], center: false, right: false, indent: indentLevel, isList: false };
                    }
                    const rows = [];
                    let headerRows = 0;
                    const thead = node.querySelector('thead');
                    const tbody = node.querySelector('tbody');
                    const tfoot = node.querySelector('tfoot');
                    const collectRows = (section, isHeader) => {
                        if (!section) return;
                        section.querySelectorAll('tr').forEach(tr => {
                            const cells = [];
                            tr.querySelectorAll('td, th').forEach(cell => cells.push(getTextFromNode(cell).trim()));
                            if (cells.length) rows.push(cells);
                            if (isHeader) headerRows++;
                        });
                    };
                    collectRows(thead, true);
                    if (tbody) collectRows(tbody, false);
                    else Array.from(node.children).filter(c => c.tagName && c.tagName.toLowerCase() === 'tr').forEach(tr => {
                        const cells = [];
                        tr.querySelectorAll('td, th').forEach(cell => cells.push(getTextFromNode(cell).trim()));
                        if (cells.length) rows.push(cells);
                    });
                    collectRows(tfoot, false);
                    if (rows.length) blocks.push({ type: 'table', rows, headerRows });
                    return;
                }

                // Handle img: add image block
                if (isImg) {
                    if (currentParagraph.segments.length > 0) {
                        blocks.push({ type: 'paragraph', ...currentParagraph });
                        currentParagraph = { segments: [], center: false, right: false, indent: indentLevel, isList: false };
                    }
                    const src = node.getAttribute('src') || '';
                    let w = parseFloat(node.getAttribute('width')) || null;
                    let h = parseFloat(node.getAttribute('height')) || null;
                    const style = node.getAttribute('style') || '';
                    const wMatch = style.match(/width:\s*([\d.]+)(px|%|em)/i);
                    const hMatch = style.match(/height:\s*([\d.]+)(px|%|em)/i);
                    if (!w && wMatch) w = parseFloat(wMatch[1]);
                    if (!h && hMatch) h = parseFloat(hMatch[1]);
                    if (src) blocks.push({ type: 'image', src, width: w, height: h });
                    return;
                }

                // Handle lists in place (document order)
                if (tagName === 'ul' || tagName === 'ol') {
                    if (currentParagraph.segments.length > 0) {
                        blocks.push({ type: 'paragraph', ...currentParagraph });
                        currentParagraph = { segments: [], center: false, right: false, indent: indentLevel, isList: false };
                    }
                    processList(node);
                    return;
                }
                if (tagName === 'li') return; // handled inside processList

                // Handle BR - treat as space (remove line break)
                if (isBr) {
                    currentParagraph.segments.push({
                        text: ' ',
                        bold: false,
                        italic: false,
                        underline: false,
                        strikethrough: false,
                        subscript: false,
                        superscript: false,
                        fontSize: null,
                        fontFamily: null,
                        link: null
                    });
                    return;
                }

                if (isBlock && currentParagraph.segments.length > 0) {
                    const isHeading = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(tagName);
                    blocks.push({ type: 'paragraph', ...currentParagraph, isHeading });
                    currentParagraph = { segments: [], center: false, right: false, indent: indentLevel, isList: false };
                }

                // Tag-based formatting
                if (tagName === 'strong' || tagName === 'b') newStyles.bold = true;
                if (tagName === 'em' || tagName === 'i') newStyles.italic = true;
                if (tagName === 'u') newStyles.underline = true;
                if (tagName === 'strike' || tagName === 's' || tagName === 'del') newStyles.strikethrough = true;
                if (tagName === 'sub') newStyles.subscript = true;
                if (tagName === 'sup') newStyles.superscript = true;
                if (tagName === 'center') newStyles.center = true;
                if (tagName === 'a') {
                    let href = node.getAttribute('href') || '';
                    if (href && !href.startsWith('http://') && !href.startsWith('https://') && !href.startsWith('mailto:')) {
                        href = 'http://' + href;
                    }
                    newStyles.link = href;
                    newStyles.underline = true;
                }

                // Handle indent/outdent from CSS class
                let newIndentLevel = indentLevel; // Keep current indent level
                const standardIndentMm = 12.7; // 0.5 inches = 12.7mm
                const classAttr = node.getAttribute('class') || '';
                if (classAttr) {
                    const classes = classAttr.split(/\s+/).map(c => c.trim().toLowerCase());
                    if (classes.includes('indent')) {
                        newIndentLevel = indentLevel + standardIndentMm;
                    } else if (classes.includes('outdent')) {
                        newIndentLevel = Math.max(0, indentLevel - standardIndentMm);
                    }
                }

                // Handle indent/outdent from style
                const marginLeftMatch = style.match(/margin-left:\s*([\d.]+)(px|pt|em|%)/i);
                const paddingLeftMatch = style.match(/padding-left:\s*([\d.]+)(px|pt|em|%)/i);
                const textIndentMatch = style.match(/text-indent:\s*([\d.]+)(px|pt|em|%)/i);

                // text-indent adds to the indent
                if (textIndentMatch) {
                    const value = parseFloat(textIndentMatch[1]);
                    const unit = (textIndentMatch[2] || 'px').toLowerCase();
                    let indentMm = 0;
                    if (unit === 'px') {
                        indentMm = value * 0.264583; // Convert px to mm (1px ≈ 0.264583mm)
                    } else if (unit === 'pt') {
                        indentMm = value * 0.352778; // Convert pt to mm (1pt ≈ 0.352778mm)
                    } else if (unit === 'em') {
                        indentMm = value * 4.233; // Approximate: 1em ≈ 16px ≈ 4.233mm
                    } else if (unit === '%') {
                        indentMm = (pageWidth * value) / 100;
                    }
                    newIndentLevel = indentLevel + indentMm;
                }

                // margin-left or padding-left sets the indent (absolute)
                if (marginLeftMatch || paddingLeftMatch) {
                    const match = marginLeftMatch || paddingLeftMatch;
                    const value = parseFloat(match[1]);
                    const unit = (match[2] || 'px').toLowerCase();
                    let indentMm = 0;
                    if (unit === 'px') {
                        indentMm = value * 0.264583; // Convert px to mm (1px ≈ 0.264583mm)
                    } else if (unit === 'pt') {
                        indentMm = value * 0.352778; // Convert pt to mm (1pt ≈ 0.352778mm)
                    } else if (unit === 'em') {
                        indentMm = value * 4.233; // Approximate: 1em ≈ 16px ≈ 4.233mm
                    } else if (unit === '%') {
                        // Percentage of page width
                        indentMm = (pageWidth * value) / 100;
                    }
                    newIndentLevel = indentMm;
                }

                // Parse font-size (cap to 1.5x base to prevent overlay/large inline text)
                const baseFontPt = 10;
                const maxInlineFont = baseFontPt * 1.5;
                const fontSizeMatch = style.match(/font-size:\s*([\d.]+)(px|pt|em|%)/i);
                if (fontSizeMatch) {
                    let size = parseFloat(fontSizeMatch[1]);
                    const unit = fontSizeMatch[2].toLowerCase();
                    let pt = baseFontPt;
                    if (unit === 'pt') pt = size;
                    else if (unit === 'px') pt = size * 0.75;
                    else if (unit === 'em') pt = (styles.fontSize || baseFontPt) * size;
                    else if (unit === '%') pt = (styles.fontSize || baseFontPt) * (size / 100);
                    newStyles.fontSize = Math.min(pt, maxInlineFont);
                }

                // Parse font-family
                const fontFamilyMatch = style.match(/font-family:\s*([^;]+)/i);
                if (fontFamilyMatch) {
                    const fontFamily = fontFamilyMatch[1].trim().replace(/['"]/g, '').split(',')[0].trim();
                    newStyles.fontFamily = fontFamily;
                }

                // Style-based formatting
                if (/font-weight:\s*bold/i.test(style)) newStyles.bold = true;
                if (/font-style:\s*italic/i.test(style)) newStyles.italic = true;
                if (/text-decoration:[^;]*underline/i.test(style)) newStyles.underline = true;
                if (/text-decoration:[^;]*line-through/i.test(style)) newStyles.strikethrough = true;
                if (/text-align:\s*center/i.test(style)) newStyles.center = true;
                if (/text-align:\s*right/i.test(style)) newStyles.right = true;

                if (isBlock && newStyles.center) currentParagraph.center = true;
                if (isBlock && newStyles.right) currentParagraph.right = true;
                if (isBlock) currentParagraph.indent = newIndentLevel;

                for (const child of node.childNodes) walkNode(child, newStyles, newIndentLevel);

                if (isBlock && currentParagraph.segments.length > 0) {
                    const isHeading = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(tagName);
                    blocks.push({ type: 'paragraph', ...currentParagraph, isHeading });
                    currentParagraph = { segments: [], center: false, right: false, indent: newIndentLevel, isList: false };
                }
            }
        };
        walkNode(temp, { bold: false, italic: false, underline: false, strikethrough: false, subscript: false, superscript: false, fontSize: null, fontFamily: null, center: false, right: false, link: null }, 0);
        if (currentParagraph.segments.length > 0) blocks.push({ type: 'paragraph', ...currentParagraph });

        return blocks;
    };
    // Render blocks (paragraphs, tables, images) with optional line callback for draft background
    const renderFormattedText = (
        addDocuSignAnchors = false,
        html,
        fontSize = 10,
        defaultBold = false,
        indent = 0,
        lineCallback = null,
        measureOnly = false,

    ) => {
        const startY = yPosition;
        pdf.setFontSize(fontSize);
        const blocks = parseHtmlToBlocks(html);
        let pendingDocuSignAnchor = null;
        if (!blocks.length) return 0;
        let isFirstParagraph = true;
        for (const block of blocks) {
            if (block.type === 'table') {
                if (!measureOnly) checkPageBreak(25);
                const tableFontSize = Math.min(fontSize, 9);
                pdf.setFontSize(tableFontSize);
                const tableWidth = pageWidth - margin * 2 - indent;
                const colCount = Math.max(1, ...block.rows.map(r => r.length));
                const colWidth = tableWidth / colCount;
                const cellHeight = 6;
                let tableY = yPosition;
                block.rows.forEach((row, ri) => {
                    if (!measureOnly && tableY > pageHeight - margin - 15) {
                        pdf.addPage();
                        yPosition = margin;
                        tableY = margin;
                    }
                    const isHeader = ri < block.headerRows;
                    if (isHeader) {
                        pdf.setFont('helvetica', 'bold');
                    }
                    row.forEach((cell, ci) => {
                        const cellX = margin + indent + ci * colWidth;
                        if (!measureOnly) {
                            pdf.setFillColor(
                                isHeader ? 240 : 255,
                                240,
                                240
                            );
                            pdf.rect(
                                cellX,
                                tableY - 4,
                                colWidth,
                                cellHeight + 2,
                                'FD'
                            );
                            pdf.setDrawColor(180, 180, 180);
                            pdf.rect(
                                cellX,
                                tableY - 4,
                                colWidth,
                                cellHeight + 2,
                                'S'
                            );
                            // ================================
                            // NORMAL CELL TEXT
                            // ================================
                            const cellText = (cell || '').replace(/\u00A0/g, ' ').replace(/\s+/g, ' ').trim().toLowerCase();
                            const wrapText = pdf.splitTextToSize(cell || '', colWidth - 4);
                            pdf.setTextColor(0, 0, 0);
                            pdf.text(
                                wrapText,
                                cellX + 2,
                                tableY + 2
                            );
                            // ================================
                            // DOCUSIGN to delete
                            // ================================
                            if (addDocuSignAnchors) {
                                let docuSignAnchor = null;
                                if (cellText.includes('pour le fournisseur') && cellText.includes('signature')) {
                                    console.log('SUPPLIER FOUND:', cellText);
                                    docuSignAnchor = '\\s2\\';
                                }
                                else if (cellText.includes('pour boulanger') && cellText.includes('signature')) {
                                    console.log('BOULANGER FOUND:', cellText);
                                    docuSignAnchor = '\\s1\\';
                                }
                                console.log('docuSignAnchor2: ' + docuSignAnchor)
                                if (docuSignAnchor) {
                                    pdf.setFont('helvetica', 'normal');
                                    // RED only while testing
                                    pdf.setFontSize(12);
                                    pdf.setTextColor(255, 0, 0);
                                    console.log('docuSignAnchor: ' + docuSignAnchor)
                                    pdf.text(docuSignAnchor, cellX + 2, tableY + 12);
                                    pdf.setTextColor(0, 0, 0);
                                    pdf.setFontSize(tableFontSize);
                                }
                            }
                        }
                    });
                    if (isHeader) {
                        pdf.setFont('helvetica', 'normal');
                    }
                    const rowHeight = cellHeight + 4;
                    tableY += rowHeight;
                });
                yPosition = tableY + 3;
                pdf.setFontSize(fontSize);
                isFirstParagraph = false;

                continue;
            }
            if (block.type === 'image') {
                if (!measureOnly) {
                    checkPageBreak(40);
                    try {
                        const imgW = block.width ? block.width * 0.264583 : 50;
                        const imgH = block.height ? block.height * 0.264583 : 30;
                        const fmt = (block.src || '').toLowerCase().includes('png') ? 'PNG' : 'JPEG';
                        pdf.addImage(block.src, fmt, margin + indent, yPosition, imgW, imgH);
                        yPosition += imgH + 3;
                    } catch (e) {
                        pdf.setTextColor(150, 150, 150);
                        pdf.text('[Image]', margin + indent, yPosition);
                        yPosition += 8;
                    }
                } else {
                    yPosition += 35;
                }
                isFirstParagraph = false;
                continue;
            }
            const para = block;
            if (!isFirstParagraph && !para.isList) {
                if (!para.isHeading) yPosition += paragraphSpacing;
            }
            isFirstParagraph = false;

            const paraIndent = (para.indent || 0) + indent;
            const bulletPrefix = para.isList && para.bulletPrefix ? para.bulletPrefix : '';
            const bulletWidth = bulletPrefix ? pdf.getTextWidth(bulletPrefix) + pdf.getTextWidth(' ') : 0;
            const maxWidthFirstLine = pageWidth - margin * 2 - paraIndent;
            const maxWidthContinuation = para.isList ? pageWidth - margin * 2 - paraIndent - bulletWidth : maxWidthFirstLine;

            let currentLine = [];
            let currentLineWidth = 0;
            const outputLines = [];
            let isFirstLine = true;
            const paragraphText = para.segments
                .map(segment => segment.text || '')
                .join(' ')
                // .replace(/\u00A0/g, ' ')
                .replace(/\s+/g, ' ')
                .trim()
                .toLowerCase();
            console.log('Paragraph1:', paragraphText);

            let docuSignAnchor = null;
            console.log('addDocuSignAnchors: ' + addDocuSignAnchors)
            // ========================================
            // DOCUSIGN: remember which signer is next
            // ========================================

            if (addDocuSignAnchors) {
                if (paragraphText.includes('pour le fournisseur')) {
                    console.log('Found supplier');
                    pendingDocuSignAnchor = '\\s2\\';
                }
                else if (paragraphText.includes('pour boulanger')) {
                    console.log('Found Boulanger');
                    pendingDocuSignAnchor = '\\s1\\';
                }
                // if (
                //     // paragraphText.includes('pour le fournisseur') &&
                //     pendingDocuSignAnchor &&
                //     paragraphText.includes('signature')
                // ) {
                //     console.log('hereee')
                //     docuSignAnchor = '\\s2\\';
                // }

                // else if (
                //     // paragraphText.includes('pour boulanger') &&
                //     paragraphText.includes('signature') &&
                //     docuSignAnchor
                // ) {
                //     console.log('hereee2')

                //     docuSignAnchor = '\\s1\\';
                // }
            }
            console.log('Paragraph:', paragraphText);
            for (const seg of para.segments) {
                const words = seg.text.split(/(\s+|\n)/);

                for (const word of words) {
                    if (!word) continue;

                    if (word === '\n') {
                        const spaceSeg = { ...seg, text: ' ', fontSize: seg.fontSize || fontSize, subscript: seg.subscript || false, superscript: seg.superscript || false };
                        const spW = pdf.getTextWidth(' ');
                        const maxW = isFirstLine ? maxWidthFirstLine : maxWidthContinuation;
                        if (currentLineWidth + spW > maxW && currentLine.length) {
                            outputLines.push([...currentLine]);
                            currentLine = [];
                            currentLineWidth = 0;
                            isFirstLine = false;
                        }
                        currentLine.push(spaceSeg);
                        currentLineWidth += spW;
                        continue;
                    }

                    const segFontSize = seg.fontSize || fontSize;
                    pdf.setFontSize(segFontSize);

                    let font = 'helvetica';
                    const fam = (seg.fontFamily || '').toLowerCase();
                    if (fam.includes('times')) font = 'times';
                    if (fam.includes('courier') || fam.includes('mono')) font = 'courier';

                    let style = 'normal';
                    if ((seg.bold || defaultBold) && seg.italic) style = 'bolditalic';
                    else if (seg.bold || defaultBold) style = 'bold';
                    else if (seg.italic) style = 'italic';

                    pdf.setFont(font, style);

                    const w = pdf.getTextWidth(word);
                    const maxW = isFirstLine ? maxWidthFirstLine : maxWidthContinuation;
                    if (currentLineWidth + w > maxW && currentLine.length) {
                        outputLines.push([...currentLine]);
                        currentLine = [];
                        currentLineWidth = 0;
                        isFirstLine = false;
                    }

                    currentLine.push({ ...seg, text: word, fontSize: segFontSize, subscript: seg.subscript || false, superscript: seg.superscript || false });
                    currentLineWidth += w;
                }
            }

            if (currentLine.length) outputLines.push(currentLine);

            outputLines.forEach((line, lineIndex) => {
                if (!measureOnly) {
                    checkPageBreak();
                }

                if (!line.length) return;

                let maxSize = fontSize;
                line.forEach(s => {
                    if ((s.fontSize || fontSize) > maxSize) {
                        maxSize = s.fontSize || fontSize;
                    }
                });

                const lineHeight = baseLineHeight * (maxSize / fontSize);

                let lineWidth = 0;
                line.forEach(s => {
                    pdf.setFontSize(s.fontSize || fontSize);
                    lineWidth += pdf.getTextWidth(s.text);
                });

                let x = margin + paraIndent;
                if (para.isList && lineIndex > 0) x = margin + paraIndent + bulletWidth;
                if (para.center) x = (pageWidth - lineWidth) / 2;
                if (para.right) x = pageWidth - margin - lineWidth;

                if (!measureOnly) {
                    if (lineCallback) lineCallback(x, yPosition, lineWidth, lineHeight);

                    for (const s of line) {
                        pdf.setFontSize(s.fontSize || fontSize);

                        let font = 'helvetica';
                        const fam = (s.fontFamily || '').toLowerCase();
                        if (fam.includes('times')) font = 'times';
                        if (fam.includes('courier') || fam.includes('mono')) font = 'courier';

                        let style = 'normal';
                        if (s.bold && s.italic) style = 'bolditalic';
                        else if (s.bold) style = 'bold';
                        else if (s.italic) style = 'italic';

                        pdf.setFont(font, style);

                        const segFontSize = s.fontSize || fontSize;
                        const subSupScale = 0.65;
                        const subSupOffset = segFontSize * 0.22;
                        const drawY = (s.subscript || s.superscript)
                            ? (s.subscript ? yPosition + subSupOffset : yPosition - subSupOffset)
                            : yPosition;
                        const drawSize = (s.subscript || s.superscript) ? Math.max(6, segFontSize * subSupScale) : segFontSize;
                        if (s.subscript || s.superscript) {
                            pdf.setFontSize(drawSize);
                        }
                        const w = pdf.getTextWidth(s.text);

                        if (s.link || /^www\./i.test(s.text)) {
                            const url = s.link || `http://${s.text}`;
                            pdf.setTextColor(0, 102, 204);
                            pdf.textWithLink(s.text, x, drawY, { url });
                        } else {
                            pdf.setTextColor(0, 0, 0);
                            pdf.text(s.text, x, drawY);
                        }
                        if (s.strikethrough) {
                            pdf.setDrawColor(0, 0, 0);
                            pdf.setLineWidth(0.2);
                            const strikeY = drawY - segFontSize * 0.2;
                            pdf.line(x, strikeY, x + w, strikeY);
                        }
                        if (s.underline) {
                            pdf.setDrawColor(0, 0, 0);
                            pdf.setLineWidth(0.15);
                            const underlineY = drawY + segFontSize * 0.15;
                            pdf.line(x, underlineY, x + w, underlineY);
                        }

                        if (s.subscript || s.superscript) pdf.setFontSize(segFontSize);
                        x += w;
                    }
                }

                yPosition += lineHeight;
            });
            if (pendingDocuSignAnchor && paragraphText === 'signature') {
                if (!measureOnly) {
                    // Space below "Signature"
                    // checkPageBreak(20);
                    const signatureAreaHeight = 17;
                    // Check BEFORE adding the extra space
                    checkPageBreak(signatureAreaHeight + 5);
                    // ========================================
                    // APPLY DRAFT BACKGROUND TO SIGNATURE AREA
                    // ========================================
                    if (lineCallback) {
                        lineCallback(
                            margin + paraIndent,
                            yPosition,
                            pageWidth - margin * 2,
                            signatureAreaHeight
                        );
                    }
                    yPosition += 12;
                    // Invisible text, but still present in PDF text layer
                    pdf.setFont('helvetica', 'normal');
                    pdf.setFontSize(8);
                    // pdf.setTextColor(255, 255, 255);
                    //to view the anchors
                    // pdf.setFontSize(12);
                    // pdf.setTextColor(255, 0, 0);
                    // If draft => same color as draft background
                    // Otherwise => white
                    if (lineCallback) {
                        pdf.setTextColor(255, 243, 224);
                    } else {
                        pdf.setTextColor(255, 255, 255);
                    }
                    pdf.text(
                        pendingDocuSignAnchor,
                        margin + paraIndent,
                        yPosition
                    );
                    // Restore normal text
                    pdf.setTextColor(0, 0, 0);
                    pdf.setFontSize(fontSize);

                    yPosition += 5;
                }
            }
        }

        return yPosition - startY;
    };

    // Process clauses
    pdf.setTextColor(0, 0, 0);
    if (clauses && clauses.length > 0) {
        for (let i = 0; i < clauses.length; i++) {
            const clause = clauses[i];
            const isLastClause = i === clauses.length - 1;
            checkPageBreak(20);
            const clauseType = (clause[LegalDocClause_API.ClauseType__c] || '').toLowerCase();
            const rawHtml = clause[LegalDocClause_API.Clause__c] || '';
            const isDraft = (clause[LegalDocClause_API.Status__c] || '').toLowerCase() === 'draft';
            const isTitle = clauseType.includes('titre') || clauseType.includes('title');
            if (isDraft) {
                const startY = yPosition;
                const draftLineCallback = (x, y, lineW, lineH) => {
                    pdf.setFillColor(255, 243, 224); // #fff3e0
                    pdf.rect(margin, y - 4, pageWidth - margin * 2, lineH + 4, 'F');
                };
                renderFormattedText(
                    isLastClause,
                    rawHtml,
                    isTitle ? 12 : 10,
                    isTitle,
                    isTitle ? 0 : paragraphIndent,
                    draftLineCallback
                );
                const endY = yPosition;
                pdf.setDrawColor(255, 152, 0);
                pdf.setLineWidth(1);
                pdf.line(margin, startY - 4, margin, endY + 4);
            } else {
                renderFormattedText(
                    isLastClause,
                    rawHtml,
                    isTitle ? 12 : 10,
                    isTitle,
                    isTitle ? 0 : paragraphIndent
                );
            }
            if (!isDraft) {
                yPosition += 3;
            }
        }
    } else {
        pdf.setTextColor(100, 100, 100);
        pdf.setFontSize(10);
        pdf.setFont('helvetica', 'italic');
        pdf.text('Aucune clause légale trouvée.', margin, yPosition);
    }
    // Add watermark if any draft clause exists; always add footer
    const hasAnyDraft = clauses && clauses.some(c => (c[LegalDocClause_API.Status__c] || '').toLowerCase() === 'draft');
    const totalPages = pdf.internal.getNumberOfPages();
    const docName = legalDoc?.Name || 'Document';
    const editionDate = new Date().toLocaleDateString('fr-FR');
    for (let i = 1; i <= totalPages; i++) {
        pdf.setPage(i);
        if (hasAnyDraft) {
            pdf.saveGraphicsState();
            const gState = new pdf.GState({ opacity: 0.30 });
            pdf.setGState(gState);
            pdf.setFont('helvetica', 'normal');
            pdf.setFontSize(120);
            pdf.setTextColor(200, 200, 200);
            const centerX = pageWidth / 2;
            const centerY = pageHeight / 2;
            pdf.text('DRAFT', centerX + 28, centerY + 30, { angle: 45, align: 'center', baseline: 'middle' });
            pdf.restoreGraphicsState();
        }
        // Footer
        pdf.setFontSize(8);
        pdf.setTextColor(120, 120, 120);
        pdf.setFont('helvetica', 'normal');
        let baseTitle = docName;
        let userDisplay = '';
        if (currentUser) {
            userDisplay = currentUser.Alias ? `${currentUser.Name} (${currentUser.Alias})` : currentUser.Name;
        }
        const fullFooterText = `${baseTitle} - ${editionDate} - ${userDisplay}     Page ${i} / ${totalPages}`;
        pdf.text(fullFooterText, pageWidth / 2, pageHeight - 10, { align: 'center' });
    }
    return pdf;
}
export function exportWord(clauses, legalDoc, currentUser) {
    try {
        const docxApi = window?.docx || globalThis?.docx;
        if (!docxApi) {
            throw new Error('DOCX library is not loaded.');
        }
        const { Document, Paragraph, TextRun, Footer, Header, PageNumber, AlignmentType, ExternalHyperlink, ImageRun, convertInchesToTwip, ShadingType, BorderStyle } = docxApi;
        const getAlignmentFromElement = (el) => {
            const style = el?.getAttribute?.('style') || '';
            if (/text-align\s*:\s*center/i.test(style)) return AlignmentType.CENTER;
            if (/text-align\s*:\s*right/i.test(style)) return AlignmentType.RIGHT;
            if (/text-align\s*:\s*left/i.test(style)) return AlignmentType.LEFT;
            return AlignmentType.JUSTIFIED;
        };
        /* ============================
        LOAD IMAGE DATA
        ============================ */
        const loadImageData = (src) => {
            try {
                // If it's a data URL (base64), extract the data
                if (src.startsWith('data:')) {
                    const base64Data = src.split(',')[1];
                    const binaryString = atob(base64Data);
                    const bytes = new Uint8Array(binaryString.length);
                    for (let i = 0; i < binaryString.length; i++) {
                        bytes[i] = binaryString.charCodeAt(i);
                    }
                    // Determine image type from data URL
                    const mimeMatch = src.match(/data:image\/(\w+);/);
                    const imageType = mimeMatch ? mimeMatch[1] : 'png';
                    return { data: bytes, type: imageType };
                }
                // For URLs, try to load via img element and canvas (works for same-origin and CORS-enabled images)
                // This is a synchronous approach that works in the browser
                try {
                    const img = document.createElement('img');
                    img.crossOrigin = 'anonymous';
                    img.src = src;

                    // If image is already loaded, convert it
                    if (img.complete && img.naturalWidth > 0) {
                        const canvas = document.createElement('canvas');
                        canvas.width = img.naturalWidth;
                        canvas.height = img.naturalHeight;
                        const ctx = canvas.getContext('2d');
                        ctx.drawImage(img, 0, 0);
                        const dataUrl = canvas.toDataURL('image/png');
                        const base64Data = dataUrl.split(',')[1];
                        const binaryString = atob(base64Data);
                        const bytes = new Uint8Array(binaryString.length);
                        for (let i = 0; i < binaryString.length; i++) {
                            bytes[i] = binaryString.charCodeAt(i);
                        }
                        return { data: bytes, type: 'png' };
                    }
                } catch (e) {
                    console.warn('Could not load image via canvas:', e);
                }
                return null;
            } catch (error) {
                console.error('Error loading image:', error);
                return null;
            }
        };
        /* ============================
        HTML → WORD PARAGRAPHS
        ============================ */
        const parseHtmlToParagraphs = (
            html,
            size = 22,
            forceBold = false,
            defaultAlignment = AlignmentType.JUSTIFIED,
            isDraft = false,
            color = '000000',
        ) => {
            const temp = document.createElement('div');
            temp.innerHTML = html || '';
            const paragraphs = [];
            const parseInline = (node, styles, runs) => {
                if (node.nodeType === Node.TEXT_NODE && node.textContent) {
                    // Use segment font size or default (docx uses half-points, so size 22 = 11pt)
                    const baseSizePt = size / 2; // Convert half-points to points
                    const segFontSizePt = styles.fontSize || baseSizePt;
                    const segFontSize = Math.round(segFontSizePt * 2); // Convert pt to half-points for docx
                    const segFontFamily = styles.fontFamily || 'Calibri';

                    runs.push(new TextRun({
                        text: node.textContent,
                        bold: styles.bold || forceBold,
                        italics: styles.italic,
                        underline: styles.underline ? {} : undefined,
                        strike: styles.strikethrough ? {} : undefined,
                        size: segFontSize,
                        font: segFontFamily,
                        color
                    }));
                }
                if (node.nodeType === Node.ELEMENT_NODE) {
                    const tag = node.tagName.toLowerCase();
                    const newStyles = { ...styles };
                    const style = node.getAttribute('style') || '';

                    // Handle BR tag as line break
                    if (tag === 'br') {
                        runs.push(new TextRun({
                            text: '\n',
                            bold: styles.bold || forceBold,
                            italics: styles.italic,
                            underline: styles.underline ? {} : undefined,
                            strike: styles.strikethrough ? {} : undefined,
                            size: Math.round((styles.fontSize || (size / 2)) * 2),
                            font: styles.fontFamily || 'Calibri',
                            color
                        }));
                        return;
                    }

                    if (tag === 'b' || tag === 'strong') newStyles.bold = true;
                    if (tag === 'i' || tag === 'em') newStyles.italic = true;
                    if (tag === 'u') newStyles.underline = true;
                    if (tag === 'strike' || tag === 's' || tag === 'del') newStyles.strikethrough = true;

                    // Parse font-size
                    const baseSizePt = size / 2; // Convert half-points to points
                    const fontSizeMatch = style.match(/font-size:\s*([\d.]+)(px|pt|em|%)/i);
                    if (fontSizeMatch) {
                        let sizeValue = parseFloat(fontSizeMatch[1]);
                        const unit = fontSizeMatch[2].toLowerCase();
                        if (unit === 'pt') {
                            newStyles.fontSize = sizeValue;
                        } else if (unit === 'px') {
                            newStyles.fontSize = sizeValue * 0.75; // Convert px to pt
                        } else if (unit === 'em') {
                            newStyles.fontSize = (styles.fontSize || baseSizePt) * sizeValue; // Relative to parent
                        } else if (unit === '%') {
                            newStyles.fontSize = (styles.fontSize || baseSizePt) * (sizeValue / 100);
                        }
                    }

                    // Parse font-family
                    const fontFamilyMatch = style.match(/font-family:\s*([^;]+)/i);
                    if (fontFamilyMatch) {
                        const fontFamily = fontFamilyMatch[1].trim().replace(/['"]/g, '').split(',')[0].trim();
                        newStyles.fontFamily = fontFamily;
                    }

                    // Style-based formatting
                    if (/font-weight:\s*bold/i.test(style)) newStyles.bold = true;
                    if (/font-style:\s*italic/i.test(style)) newStyles.italic = true;
                    if (/text-decoration:[^;]*underline/i.test(style)) newStyles.underline = true;
                    if (/text-decoration:[^;]*line-through/i.test(style)) newStyles.strikethrough = true;

                    if (tag === 'a') {
                        let href = node.getAttribute('href') || '';
                        if (href && !href.startsWith('http')) href = 'http://' + href;

                        const baseSizePt = size / 2;
                        const segFontSizePt = styles.fontSize || baseSizePt;
                        const segFontSize = Math.round(segFontSizePt * 2);
                        const segFontFamily = styles.fontFamily || 'Calibri';

                        runs.push(new ExternalHyperlink({
                            link: href,
                            children: [
                                new TextRun({
                                    text: node.textContent,
                                    style: 'Hyperlink',
                                    size: segFontSize,
                                    font: segFontFamily
                                })
                            ]
                        }));
                        return;
                    }
                    node.childNodes.forEach(child =>
                        parseInline(child, newStyles, runs)
                    );
                }
            };
            // Handle images first
            const images = temp.querySelectorAll('img');
            images.forEach(img => {
                const src = img.getAttribute('src') || '';
                if (src) {
                    const imageData = loadImageData(src);
                    if (imageData) {
                        const width = img.getAttribute('width') ? parseInt(img.getAttribute('width')) : 400;
                        const height = img.getAttribute('height') ? parseInt(img.getAttribute('height')) : 300;

                        paragraphs.push(new Paragraph({
                            children: [
                                new ImageRun({
                                    data: imageData.data,
                                    type: imageData.type,
                                    transformation: {
                                        width: width,
                                        height: height
                                    }
                                })
                            ],
                            alignment: getAlignmentFromElement(img) || AlignmentType.LEFT,
                            spacing: { after: 120 },
                            ...(isDraft ? { shading: draftShading, border: draftBorder } : {})
                        }));
                    }
                }
                img.remove(); // Remove from DOM so it's not processed as text
            });

            // Handle regular text blocks (p, div, h1-h4)
            const blocks = temp.querySelectorAll('p, div, h1, h2, h3, h4');

            (blocks.length ? blocks : [temp]).forEach(block => {
                // Skip if block contains a list or image (already processed)
                if (block.querySelector('ul, ol, img')) {
                    return;
                }

                // Calculate indent from style
                let indentLevel = 0;
                const style = block.getAttribute('style') || '';
                const marginLeftMatch = style.match(/margin-left:\s*(\d+)px/i);
                const paddingLeftMatch = style.match(/padding-left:\s*(\d+)px/i);
                if (marginLeftMatch || paddingLeftMatch) {
                    const pxValue = marginLeftMatch ? parseInt(marginLeftMatch[1]) : parseInt(paddingLeftMatch[1]);
                    indentLevel = Math.floor(pxValue / 20);
                }

                // Calculate indent level from CSS classes (indent/outdent)
                const calculateIndentLevel = (node) => {
                    let maxLevel = 0;
                    let currentLevel = 0;
                    const walk = (n) => {
                        if (n.nodeType === Node.ELEMENT_NODE) {
                            const classAttr = n.getAttribute ? n.getAttribute('class') : '';
                            if (classAttr) {
                                const classes = classAttr.split(/\s+/).map(c => c.trim().toLowerCase());
                                const levelBefore = currentLevel;
                                if (classes.includes('indent')) {
                                    currentLevel++;
                                    maxLevel = Math.max(maxLevel, currentLevel);
                                } else if (classes.includes('outdent')) {
                                    currentLevel = Math.max(0, currentLevel - 1);
                                }
                                // Walk through children
                                for (const child of n.childNodes) {
                                    walk(child);
                                }
                                // Restore level when exiting indent/outdent classes
                                if (classes.includes('indent') || classes.includes('outdent')) {
                                    currentLevel = levelBefore;
                                }
                            } else {
                                // Walk through children even if no class
                                for (const child of n.childNodes) {
                                    walk(child);
                                }
                            }
                        }
                    };
                    walk(node);
                    return maxLevel;
                };
                indentLevel += calculateIndentLevel(block);

                // Also check the block's own class attribute
                const blockClass = block.getAttribute('class') || '';
                if (blockClass) {
                    const classes = blockClass.split(/\s+/).map(c => c.trim().toLowerCase());
                    if (classes.includes('indent')) {
                        indentLevel++;
                    } else if (classes.includes('outdent')) {
                        indentLevel = Math.max(0, indentLevel - 1);
                    }
                }

                // Split content by <br> tags to preserve line breaks
                const processBlockContent = () => {
                    const runs = [];
                    const allRuns = [];

                    // Process nodes and split by <br> tags
                    const processNodes = (nodes) => {
                        for (const node of nodes) {
                            if (node.nodeType === Node.ELEMENT_NODE && node.tagName && node.tagName.toLowerCase() === 'br') {
                                // When we hit a <br>, save current runs and start new paragraph
                                if (runs.length > 0) {
                                    allRuns.push([...runs]);
                                    runs.length = 0;
                                } else {
                                    // Empty line - add empty paragraph
                                    allRuns.push([]);
                                }
                            } else {
                                parseInline(node, { bold: false, italic: false, underline: false, strikethrough: false, fontSize: null, fontFamily: null }, runs);
                            }
                        }
                        // Add remaining runs
                        if (runs.length > 0) {
                            allRuns.push([...runs]);
                        }
                    };

                    processNodes(block.childNodes);

                    // If no content at all (empty block), add empty paragraph to preserve spacing
                    if (allRuns.length === 0 && block.textContent.trim() === '') {
                        allRuns.push([]);
                    }

                    return allRuns;
                };

                const allRuns = processBlockContent();
                const indentInches = indentLevel > 0 ? (indentLevel * 0.25) : 0;

                // Create a paragraph for each set of runs (split by <br>)
                allRuns.forEach((runs, index) => {
                    if (runs.length > 0 || index === 0 || allRuns.length > 1) {
                        paragraphs.push(new Paragraph({
                            children: runs.length > 0 ? runs : [new TextRun({ text: '', size, font: 'Calibri', color })],
                            alignment: getAlignmentFromElement(block) || defaultAlignment,
                            spacing: { after: 120 },
                            indent: indentInches > 0 ? { left: convertInchesToTwip(indentInches) } : undefined,
                            ...(isDraft ? { shading: draftShading, border: draftBorder } : {})
                        }));
                    }
                });
            });

            // Handle lists (ul/ol) - process from innermost to outermost, AFTER blocks so ordering is: text then lists
            const getAllLists = (element) => {
                const allLists = [];
                const walk = (node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        const tag = node.tagName.toLowerCase();
                        if (tag === 'ul' || tag === 'ol') {
                            allLists.push({ element: node, level: 0 });
                        }
                        for (const child of node.childNodes) {
                            walk(child);
                        }
                    }
                };
                walk(element);
                // Calculate nesting levels
                allLists.forEach(list => {
                    let level = 0;
                    let parent = list.element.parentElement;
                    while (parent && parent !== temp) {
                        const parentTag = parent.tagName ? parent.tagName.toLowerCase() : '';
                        if (parentTag === 'ul' || parentTag === 'ol') {
                            level++;
                        }
                        parent = parent.parentElement;
                    }
                    list.level = level;
                });
                // Sort by level (deepest first) to process nested lists correctly
                return allLists.sort((a, b) => b.level - a.level);
            };

            const allLists = getAllLists(temp);
            allLists.forEach(({ element: list, level }) => {
                const isOrdered = list.tagName.toLowerCase() === 'ol';
                // Get direct child li elements only
                const listItems = [];
                for (const child of list.childNodes) {
                    if (child.nodeType === Node.ELEMENT_NODE && child.tagName && child.tagName.toLowerCase() === 'li') {
                        listItems.push(child);
                    }
                }

                listItems.forEach((li, index) => {
                    const runs = [];
                    const itemNumber = index + 1;

                    // Process all child nodes, but skip nested lists (they'll be handled separately)
                    for (const node of li.childNodes) {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            const tag = node.tagName ? node.tagName.toLowerCase() : '';
                            if (tag === 'ul' || tag === 'ol') {
                                // Nested list - will be handled separately by getAllLists
                                continue;
                            }
                        }
                        parseInline(node, { bold: false, italic: false, underline: false, strikethrough: false, fontSize: null, fontFamily: null }, runs);
                    }

                    if (runs.length > 0 || li.textContent.trim()) {
                        // For ordered lists, add number prefix manually
                        if (isOrdered) {
                            runs.unshift(new TextRun({
                                text: `${itemNumber}. `,
                                bold: false,
                                size,
                                font: 'Calibri',
                                color
                            }));
                        }

                        const indentLeft = 0.5 + (level * 0.5);
                        paragraphs.push(new Paragraph({
                            children: runs.length > 0 ? runs : [new TextRun({ text: li.textContent || '', size, font: 'Calibri', color })],
                            alignment: getAlignmentFromElement(li) || defaultAlignment,
                            spacing: { after: 80 },
                            indent: {
                                left: convertInchesToTwip(indentLeft),
                                hanging: convertInchesToTwip(0.25)
                            },
                            bullet: isOrdered ? undefined : {
                                level: level
                            },
                            ...(isDraft ? { shading: draftShading, border: draftBorder } : {})
                        }));
                    }
                });
                list.remove(); // Remove from DOM so it's not processed as text
            });

            return paragraphs;
        };

        /* ============================
        LINKIFY RAW URLS
        ============================ */
        const processContent = (html) => {
            const temp = document.createElement('div');
            temp.innerHTML = html || '';
            temp.querySelectorAll('a[href]').forEach(a => {
                const href = (a.getAttribute('href') || '').toLowerCase();
                if (href.includes('#mergefield')) {
                    const span = document.createElement('span');
                    span.innerHTML = a.innerHTML;
                    a.parentNode.replaceChild(span, a);
                }
            });

            const walk = (node) => {
                if (node.nodeType === Node.TEXT_NODE) {
                    const urlRegex = /((https?:\/\/|www\.)[^\s<]+)/gi;
                    if (urlRegex.test(node.nodeValue)) {
                        const span = document.createElement('span');
                        span.innerHTML = node.nodeValue.replace(urlRegex, m => {
                            const url = m.startsWith('www.') ? 'http://' + m : m;
                            return `<a href="${url}">${m}</a>`;
                        });
                        node.parentNode.replaceChild(span, node);
                    }
                } else if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'A') {
                    [...node.childNodes].forEach(walk);
                }
            };

            walk(temp);
            return temp.innerHTML;
        };

        /* ============================
        DOCUMENT BODY SETUP
        ============================ */
        const children = [];
        // Draft clause shading options
        const draftShading = {
            type: ShadingType.SOLID,
            color: 'FFF3E0', // Light orange background
            fill: 'FFF3E0'
        };
        // Draft clause border (left border)
        const draftBorder = {
            left: { style: BorderStyle.SINGLE, size: 24, color: 'FF9800' }
        };
        /* ============================
        ARTICLE HEADER DETECTION
        ============================ */
        const isArticleHeader = (html) => {
            if (!html) return false;
            const text = html.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim().toLowerCase();
            return /^article\s+\d+/.test(text);
        };

        /* ============================
        PROCESS CLAUSES
        ============================ */
        if (clauses?.length) {
            for (const clause of clauses) {
                const type = (clause[LegalDocClause_API.ClauseType__c] || '').toLowerCase();
                const html = processContent(clause[LegalDocClause_API.Clause__c] || '');
                const isDraft = (clause[LegalDocClause_API.Status__c] || '').toLowerCase() === 'draft';

                let paras;
                const articleHeader = isArticleHeader(html);

                if (type.includes('title') || type.includes('titre')) {
                    paras = parseHtmlToParagraphs(
                        html, 26, true, AlignmentType.JUSTIFIED, isDraft, '333333', true
                    );
                } else if (type.includes('subtitle') || type.includes('sous')) {
                    paras = parseHtmlToParagraphs(
                        html, 24, true, AlignmentType.JUSTIFIED, isDraft, '333333', true
                    );
                } else if (articleHeader) {
                    paras = parseHtmlToParagraphs(
                        html, 22, true, AlignmentType.JUSTIFIED, isDraft, '333333', false
                    );
                } else {
                    paras = parseHtmlToParagraphs(
                        html, 22, false, AlignmentType.JUSTIFIED, isDraft, '333333', false
                    );
                }

                children.push(...paras);
            }
        }
        // Create footer with document info and page numbers
        const footerParagraph = new Paragraph({
            children: [
                new TextRun({
                    text: `${legalDoc?.Name || 'Document'} - ${new Date().toLocaleDateString('fr-FR')} - ${currentUser?.Name || ''}`,
                    size: 18,
                    color: '999999',
                    font: 'Calibri'
                }),
                new TextRun({
                    text: '          Page ',
                    size: 18,
                    color: '999999',
                    font: 'Calibri'
                }),
                new TextRun({
                    children: [PageNumber.CURRENT],
                    size: 18,
                    color: '999999',
                    font: 'Calibri'
                }),
                new TextRun({
                    text: ' / ',
                    size: 18,
                    color: '999999',
                    font: 'Calibri'
                }),
                new TextRun({
                    children: [PageNumber.TOTAL_PAGES],
                    size: 18,
                    color: '999999',
                    font: 'Calibri'
                })
            ],
            alignment: AlignmentType.CENTER
        });

        const footer = new Footer({
            children: [footerParagraph]
        });

        // Create header with watermark (appears on every page)
        let header = undefined;

        // Create the document
        const doc = new Document({
            sections: [{
                properties: {
                    page: {
                        margin: {
                            top: convertInchesToTwip(0.79),
                            right: convertInchesToTwip(0.79),
                            bottom: convertInchesToTwip(0.98),
                            left: convertInchesToTwip(0.79)
                        }
                    }
                },
                headers: header ? {
                    default: header
                } : undefined,
                footers: {
                    default: footer
                },
                children: children
            }]
        });

        /* ============================
        DOWNLOAD
        ============================ */
        const fileName = `${legalDoc?.Name || 'LegalDoc'}_${formatDateForFilename(new Date())}.docx`;
        docxApi.Packer.toBlob(doc).then(blob => {
            const secureBlob = new Blob([blob], { type: 'application/octet-stream' });
            const docxUrl = URL.createObjectURL(secureBlob);
            const link = document.createElement('a');
            link.href = docxUrl;
            link.download = fileName;
            link.rel = 'noopener noreferrer';
            link.click();
            setTimeout(() => {
                URL.revokeObjectURL(docxUrl);
            }, 100);
        }).catch(err => {
            console.error('Error packaging docx details:', JSON.stringify(err, Object.getOwnPropertyNames(err)));
            showNotification(null, 'Erreur', 'Erreur lors de la création du fichier Word.', 'error');
        });
    } catch (e) {
        console.error(e);
        showNotification(null, 'Erreur', e.message, 'error');
    }

}
export function formatDateForFilename(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}${month}${day}`;
}