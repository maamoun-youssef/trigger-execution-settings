import { LightningElement, api } from 'lwc';
import processRestForExcel from '@salesforce/apex/DataLoaderHelperCmpController.processRestForExcel';

export default class DataLoaderHelper extends LightningElement {
    @api query;
    @api recordId;

    isLoading = false;

  /**
   * Lance l'export: charge page1..N dans l'enfant puis emit success(allRecords)
   * @param {String|null} restURL - passer null pour démarrer à la page 1.
   */
    @api
  async startExcelExport(restURL = null) {
    this.isLoading = true;

    const allRecords = [];
    const MAX_PAGES = 2000; // safety breaker
    let page = 0;

    try {
      let nextUrl = restURL; // null => page 1 côté Apex

      while (true) {
        page += 1;
        if (page > MAX_PAGES) {
          throw new Error(`Pagination exceeded MAX_PAGES=${MAX_PAGES}.`);
        }

        console.log("🚀 ~ DataLoaderHelper ~ startExcelExport ~ this.query:", this.query)
        console.log("🚀 ~ DataLoaderHelper ~ startExcelExport ~ this.recordId:", this.recordId)
        const result = await processRestForExcel({
            query: this.query,
            recordId: this.recordId,
            restURL: nextUrl
        });

        const parsed = typeof result === 'string' ? JSON.parse(result) : result;

        if (!parsed) {
          throw new Error('Apex returned null/empty response.');
        }

        if (parsed.error) {
          throw new Error(parsed.error);
        }

        if (Array.isArray(parsed.records) && parsed.records.length) {
          allRecords.push(...parsed.records);
        }

        if (parsed.done === true) break;

        if (!parsed.nextRecordsUrl) {
          throw new Error('done=false but nextRecordsUrl is missing.');
        }

        nextUrl = parsed.nextRecordsUrl;
      }

      this.dispatchEvent(new CustomEvent('success', { detail: allRecords }));
    } catch (e) {
      this.dispatchEvent(new CustomEvent('error', { detail: this.normalizeError(e) }));
    } finally {
      this.isLoading = false;
    }
  }

  normalizeError(e) {
    return {
      message: e?.body?.message || e?.message || String(e)
    };
    }
}