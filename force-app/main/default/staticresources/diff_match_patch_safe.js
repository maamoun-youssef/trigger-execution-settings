window.diff_match_patch = class diff_match_patch {
    constructor() {}

    diff_main(text1, text2) {
        const a = text1.split(/\n/);
        const b = text2.split(/\n/);
        const diffs = [];

        const maxLength = Math.max(a.length, b.length);
        for (let i = 0; i < maxLength; i++) {
            const lineA = a[i] || '';
            const lineB = b[i] || '';
            if (lineA === lineB) {
                diffs.push([0, lineA + '\n']); // 0 = equal
            } else {
                if (lineA) diffs.push([-1, lineA + '\n']); // -1 = removed
                if (lineB) diffs.push([1, lineB + '\n']); // 1 = added
            }
        }

        return diffs;
    }

    diff_cleanupSemantic(diffs) {
        // optional; do nothing for now
        return diffs;
    }
};
