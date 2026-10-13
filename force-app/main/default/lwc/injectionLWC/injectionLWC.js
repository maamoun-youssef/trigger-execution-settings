import { LightningElement } from 'lwc';

export default class InjectionLWC extends LightningElement {
  pdsInjection = [
    {
      afterFieldName: 'Name',
      fieldName: '__inject_pds_matrix__',
      headerStyle: 'width:40px;border-left:none;',
      type: 'icon-link',
      iconName: 'utility:table',
      title: 'Open PDS Matrix',
      urlTemplate: '/apex/NegoptimNavigator?c__componentName=c:ProductDiscountStatementMatrix&a__recordId={Id}'
    }
  ];
}