import { LightningElement, api, track } from 'lwc';

export default class LwcToBeInjected extends LightningElement {
  @track value = '';
  @api buildDataStrategies;
  _built = false;
  _strategyKey;

  // Parent chooses which strategy to run
  @api
  get strategyKey() {
    return this._strategyKey;
  }
  set strategyKey(v) {
    if (this._strategyKey !== v) {
      this._strategyKey = v;
      this._built = false;
    }
  }

  renderedCallback() {
    if (this._built) return;
    this._built = true;
    // Prefer strategy by key; else use default
    const fn = this.buildDataStrategies && typeof this.buildDataStrategies[this._strategyKey] === 'function' ? this.buildDataStrategies[this._strategyKey] : this.buildData;
    console.log(`Using buildData from ${fn === this.buildData ? 'lwcToBeInjected (default)' : `strategy:${this._strategyKey}`}`);
    // Bind to CHILD so strategies can set this.value
    fn.call(this);
  }

  // Default behavior (in case mode is not 'pds' or 'pls')
  buildData() {
    this.value = 'LWC used (default)';
  }
}