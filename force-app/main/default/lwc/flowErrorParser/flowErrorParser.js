import { LightningElement, api } from 'lwc';

// Cette erreur s’est produite lorsque le flux a tenté de créer les enregistrements : REQUIRED_FIELD_MISSING: Des champs obligatoires n'ont pas été remplis : [LastName]. Vous pouvez consulter les valeurs ExceptionCode dans le guide <a href='https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_concepts_core_data_objects.htm#'>SOAP API Developer Guide</a>.
// This error occurred when the flow tried to create records: REQUIRED_FIELD_MISSING: Required fields are missing: [LastName]. You can look up ExceptionCode values in the <a href='https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_concepts_core_data_objects.htm#'>SOAP API Developer Guide</a>.
// This error occurred when the flow tried to create records: FIELD_CUSTOM_VALIDATION_EXCEPTION: Test validation failure triggered. You can look up ExceptionCode values in the <a href='https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_concepts_core_data_objects.htm#'>SOAP API Developer Guide</a>.
// Cette erreur s’est produite lorsque le flux a tenté de créer les enregistrements : FIELD_CUSTOM_VALIDATION_EXCEPTION: Test validation failure triggered. Vous pouvez consulter les valeurs ExceptionCode dans le guide <a href='https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_calls_concepts_core_data_objects.htm#'>SOAP API Developer Guide</a>.

export default class FlowErrorParser extends LightningElement {
    @api faultMessage; 
    get displayMessage() {
        return this.parse(this.faultMessage);
    }
    parse(msg) {
        console.log(msg);
        if (!msg) return '';
        const text = String(msg);
        const codes = [
            { key: 'REQUIRED_FIELD_MISSING', prefix: '' },
            { key: 'FIELD_CUSTOM_VALIDATION_EXCEPTION', prefix: '' },
            { key: 'DUPLICATES_DETECTED', prefix: 'Duplicates Detected: ' },
        ];

        let result = text;
        for (const c of codes) {
            const marker = c.key + ': ';
            if (text.includes(marker)) { result = c.prefix + this.extract(text, marker); break; }
        }
        if (result === text && text.includes('_EXCEPTION: ')) {
            result = this.extract(text, '_EXCEPTION: ');
        }
        return result.replace(/<[^>]*>/g, '').trim();
    }
    extract(msg, marker) {
        const start = msg.indexOf(marker) + marker.length;
        let body = msg.substring(start);
        const ecIdx = body.indexOf('ExceptionCode');
        if (ecIdx !== -1) {
            const boundary = body.lastIndexOf('. ', ecIdx);
            if (boundary !== -1) body = body.substring(0, boundary);
        }
        return body.replace(/<[^>]*>/g, '').trim();
    }
}