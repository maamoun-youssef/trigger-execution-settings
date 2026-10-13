public with sharing class LookupValue
{

	public String label {get;set;}
	public String value {get;set;}
	public Boolean multiSelect {get;set;}

    public LookupValue() {
	}

	public LookupValue(Boolean multiSelect) {
        this.multiSelect = multiSelect;
	}

	public LookupValue(String label, String value, Boolean multiSelect) {
		this.label = label;
		this.value = value;
        this.multiSelect = multiSelect;
	}
}