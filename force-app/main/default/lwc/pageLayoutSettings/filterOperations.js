import LBL_PA_EQUALS from '@salesforce/label/c.LBL_PA_EQUALS';
import LBL_PA_NOT_EQUALS from '@salesforce/label/c.LBL_PA_NOT_EQUALS';
import LBL_PA_CONTAINS from '@salesforce/label/c.LBL_PA_CONTAINS';
import LBL_PA_DOESNT_CONTAIN from '@salesforce/label/c.LBL_PA_DOESNT_CONTAIN';
import LBL_PA_ISNULL from '@salesforce/label/c.LBL_PA_ISNULL';
import LBL_PA_ISBLANK from '@salesforce/label/c.LBL_PA_ISBLANK';
import LBL_PA_IS_NOT_NULL from '@salesforce/label/c.LBL_PA_IS_NOT_NULL';
import LBL_PA_IS_NOT_BLANK from '@salesforce/label/c.LBL_PA_IS_NOT_BLANK';

export const FilterOperations = {
    EQUALS: 'EQUALS',
    NOTEQUALS: 'NOTEQUALS',
    ISNULL: 'ISNULL',
    ISNOTNULL: 'ISNOTNULL',
    ISBLANK: 'ISBLANK',
    ISNOTBLANK: 'ISNOTBLANK',
    GREATER: 'GREATER',
    LESS: 'LESS',
    GREATER_OR_EQUALS: 'GREATER_OR_EQUALS',
    LESS_OR_EQUALS: 'LESS_OR_EQUALS',
    CONTAINS: 'CONTAINS',
    NOTCONTAINS: 'NOTCONTAINS',
};

const OPERATORS_BY_TYPE = {
    STRING: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_CONTAINS, value: FilterOperations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: FilterOperations.NOTCONTAINS },
        { label: LBL_PA_ISBLANK, value: FilterOperations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: FilterOperations.ISNOTBLANK },
    ],
    TEXTAREA: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_CONTAINS, value: FilterOperations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: FilterOperations.NOTCONTAINS },
        { label: LBL_PA_ISBLANK, value: FilterOperations.ISBLANK },
        { label: LBL_PA_IS_NOT_BLANK, value: FilterOperations.ISNOTBLANK },
    ],
    BOOLEAN: [{ label: LBL_PA_EQUALS, value: FilterOperations.EQUALS }],
    NUMBER: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: 'GREATER', value: FilterOperations.GREATER },
        { label: 'LESS', value: FilterOperations.LESS },
        { label: 'GREATER OR EQUALS', value: FilterOperations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: FilterOperations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    CURRENCY: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: 'GREATER', value: FilterOperations.GREATER },
        { label: 'LESS', value: FilterOperations.LESS },
        { label: 'GREATER OR EQUALS', value: FilterOperations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: FilterOperations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    DATE: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: 'GREATER', value: FilterOperations.GREATER },
        { label: 'LESS', value: FilterOperations.LESS },
        { label: 'GREATER OR EQUALS', value: FilterOperations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: FilterOperations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    DATETIME: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: 'GREATER', value: FilterOperations.GREATER },
        { label: 'LESS', value: FilterOperations.LESS },
        { label: 'GREATER OR EQUALS', value: FilterOperations.GREATER_OR_EQUALS },
        { label: 'LESS OR EQUALS', value: FilterOperations.LESS_OR_EQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    PICKLIST: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    MULTIPICKLIST: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    REFERENCE: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    EMAIL: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_CONTAINS, value: FilterOperations.CONTAINS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
    PHONE: [
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_CONTAINS, value: FilterOperations.CONTAINS },
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
    ],
};

export function getDefaultStringOperations() {
    return [
        { label: LBL_PA_ISNULL, value: FilterOperations.ISNULL },
        { label: LBL_PA_IS_NOT_NULL, value: FilterOperations.ISNOTNULL },
        { label: LBL_PA_EQUALS, value: FilterOperations.EQUALS },
        { label: LBL_PA_NOT_EQUALS, value: FilterOperations.NOTEQUALS },
        { label: LBL_PA_CONTAINS, value: FilterOperations.CONTAINS },
        { label: LBL_PA_DOESNT_CONTAIN, value: FilterOperations.NOTCONTAINS },
    ];
}

const FIELD_TYPE_ALIASES = {
    DOUBLE: 'NUMBER',
    INTEGER: 'NUMBER',
    LONG: 'NUMBER',
    PERCENT: 'NUMBER',
};

export function getOperationsBySubFieldType(dataType) {
    if (!dataType) {
        return getDefaultStringOperations();
    }
    const key = FIELD_TYPE_ALIASES[dataType.toUpperCase()] || dataType.toUpperCase();
    return OPERATORS_BY_TYPE[key] || getDefaultStringOperations();
}