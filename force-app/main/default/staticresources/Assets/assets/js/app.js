// ---------------------------------------------------
// Global App javascript file for common use purpose
// ---------------------------------------------------

// Class for App common variables
var negoptimApp;
var App = (function () {
    function App(locale, decimalSeparator) {
        this.locale = locale.replace("_", "-");
        if(this.locale.indexOf('_') != -1) {
        	this.locale = this.locale.split('_')[0];
        }
        this.decimalSeparator = decimalSeparator;
    }
    App.prototype.test = function () {
        alert("Your Locale is " + this.locale);
    };
    // transform decimal numbers depending on decimal locale separator
    // for calculation
    App.prototype.stringToDecimal = function (str) {
        var d = str.toString().replace(/\s/g, "");
        if (this.decimalSeparator == ',') {
            d = d.replace(",", ".");
        }
        else {
            d = d.replace(/,/g, "");
        }
        if (!isNaN(d) && d.length !== 0)
            return parseFloat(d);
        return 0;
    };
    // format the currency depending on user locale
    App.prototype.formatCurrency = function (n) {
        var formatedNumber = new Number(n).toLocaleString(this.locale, {
            style: "decimal",
        });
        return formatedNumber;
    };
    return App;
}());


$(document).ready(function() {
	// add event click to apex page message to hide
	$(document).on("click", ".message[role='alert']", function() {
		$(this).fadeOut();
	});
});
// return correct decimal number if contain white spaces or a comma
function stringToDecimal(str) {
	var d = str.toString().replace(/\s/g, "").replace(/,/g, "");
    if (!isNaN(d) && d.length !== 0)
		return parseFloat(d);
	return 0;
}