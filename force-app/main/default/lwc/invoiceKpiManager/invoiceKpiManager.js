import { LightningElement, track } from 'lwc';
import initData from '@salesforce/apex/InvoiceKpiManagerController.initData';
import { NavigationMixin } from 'lightning/navigation';

import USER_LOCALE from '@salesforce/i18n/locale';
import USER_CURRENCY from '@salesforce/i18n/currency';

export default class InvoiceKpiManager extends NavigationMixin(LightningElement) {
  @track wrapper;
  @track label;
  @track category = [];
  @track showCategory = false;
  @track isLoading = true;
  @track enableInvoiceKPICategory = false;

  connectedCallback() {
    initData().then(result => {
      const parsedResult = JSON.parse(result);
      this.enableInvoiceKPICategory = parsedResult.enableInvoiceKPICategory;
      this.label = parsedResult.fieldsLabel;
      this.loadData(parsedResult.kpiTable);

    }).catch(error => {
      console.log('error ::::: ', error);
    });
  }

  loadData(wrapper) {



    // 2. Gather all unique groups in a Set
    let allGroups = new Set();
    for (const item of wrapper) {
      for (const grp of item.kpiCategory) {

        allGroups.add(grp);
      }
    }
    this.category = allGroups;
    let allGroupsArray = Array.from(allGroups);

    // 4. For each item, ensure it has a category entry for every group
    for (const item of wrapper) {

      const existingCategoryMap = new Map();
      for (const catObj of item.category) {
        existingCategoryMap.set(catObj.groupBy, catObj);
      }

      // Create a new categories array in the "global" order
      let newCategories = [];
      for (const groupName of allGroupsArray) {
        // If this item already has that group, just reuse it
        if (existingCategoryMap.has(groupName)) {
          const existingCategory = existingCategoryMap.get(groupName);
          const totalValueIndex = 1;
          existingCategory.kpiValue[totalValueIndex].Thousands = existingCategory.kpiValue[totalValueIndex].value >= 1000;

          existingCategory.kpiValue[totalValueIndex].smallValue = existingCategory.kpiValue[totalValueIndex].value >= 1000
            ? Intl.NumberFormat(USER_LOCALE, { notation: "compact", maximumFractionDigits: 2, style: 'currency', currency: USER_CURRENCY }).format(existingCategory.kpiValue[totalValueIndex].value)
            : existingCategory.kpiValue[totalValueIndex].value;
          newCategories.push(existingCategory);
        }
        // Otherwise, add the empty one
        else {
          newCategories.push({
            kpiValue: [
              {
                value: 0,
                type: "decimal",
                header: "nbOfPieces"
              },
              {
                value: 0,
                type: "currency",
                header: "totalValue"
              }
            ],
            groupBy: groupName
          });
        }
      }
      // Replace the old category array with our new one
      item.category = newCategories;
      const color = item.color;
      const getHeaderStyle = (color) => `background-color: ${color}; color: white;`;
      const getBodyStyle = (color) => `border-color: ${color}; color: ${color}; border: solid 2px; z-index: 0; padding: 10px`;
      item.headerStyle = getHeaderStyle(color);
      item.bodyStyle = getBodyStyle(color);
    }
    this.wrapper = wrapper;
    this.isLoading = false;
  }


  handleCategoryVisibility(event) {
    this.showCategory = !this.showCategory;

  }

  handleMouseEnter(event) {
    const target = event.target;
    const index = target.dataset.index;
    const color = this.wrapper[index].color;
    target.style.border = `2px solid ${color}`;
    target.style.transition = 'background-color 0.5s ease ';
    target.style.backgroundColor = color;

    target.style.color = 'white';
    const pTagt = target.querySelector('p');
    if (pTagt) {
      const formatNumber = new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency: USER_CURRENCY,
        useGrouping: true,
        maximumFractionDigits: 0
      }).format(target.dataset.large);
      pTagt.textContent = formatNumber;
    }
  }

  handleMouseLeave(event) {
    const target = event.target;
    const index = target.dataset.index;
    const pTagt = target.querySelector('p');
    if (pTagt) {
      const smallVlaue = target.dataset.small;
      pTagt.textContent = smallVlaue;
    }
    target.style.backgroundColor = '';
    target.style.color = this.wrapper[index].color;
  }

  b64EncodeUnicode(str) {
    // Encodes a JavaScript string as UTF-8, then Base64.
    return btoa(
      encodeURIComponent(str).replace(
        /%([0-9A-F]{2})/g,
        (match, p1) => String.fromCharCode('0x' + p1)
      )
    );
  }

  handleOpenLink(event) {
    const target = event.currentTarget;
    const index = target.dataset.index;
    const categoryIndex = target.dataset.field ? target.dataset.field : null;
    const url = categoryIndex == null ? this.wrapper[index].link : this.wrapper[index].category[categoryIndex].link;
    // Encode filters for the URL param
    const encodedFilters = encodeURIComponent(url);
    // Define component definition
    const compDefinition = {
      componentDef:this.wrapper[index].prefix + ':InvoiceManager',
      state: {
        c__componentName: this.wrapper[index].prefix + 'InvoiceManager',
        c__appliedfilters: url
      },
      attributes: {}
    };
    // Encode compDefinition safely with UTF-8–friendly Base64
    // Generate the URL and open it
    this[NavigationMixin.GenerateUrl]({
      type: 'standard__webPage',
      attributes: {
        url: `/lightning/n/` + this.wrapper[index].prefix + `InvoiceManager?c__appliedfilters=${encodedFilters}`,
      },
    }).then(() => {
      window.open(`/lightning/n/` + this.wrapper[index].prefix + `InvoiceManager?c__appliedfilters=${btoa(encodedFilters)}`);
    });
  }

  // Getter for the dynamic text
  get categoryToggleText() {
    return this.showCategory ? this.label.LBL_KpiTable_HideDetail : this.label.LBL_KpiTable_ShowDetail;
  }

  get categoryGuideText() {
    return this.showCategory ? this.label.LBL_KpiTable_ShowCategoryGuide : this.label.LBL_KpiTable_HideCategoryGuide;
  }

  get isAvailable() {
    return (this.wrapper && this.wrapper?.length > 0);
  }
  // get isLoaded() {
  //   return this.label
  // }
}