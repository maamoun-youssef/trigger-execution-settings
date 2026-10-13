var refTO;
// = {!IF(refTO != null, refTO, 0)};
function init(r) {
    refTO = r;
    $("input").focus(function() {
        $(this).select();
    });

    $("input").keypress(function(e) {
        if (e.keyCode == 13) {
            elementFocus = document.activeElement;
            computeAmount();
        }
        return e.keyCode !== 13;
    });

    if (elementFocus != null) {
        document.getElementById('' + elementFocus.id).focus();
    }

    $(document).on("change", ".input-field-purchase", function() {
        var val = negoptimApp.stringToDecimal($(this).val());
        if (refTO != 0) {
            var res = (val - refTO) / refTO;
            var html = '<span ';
            if (res < 0) {
                html += 'style="color:red;">';
            } else {
                html += 'style="color:green;">';
            }
            html += res.toLocaleString(negoptimApp.locale, {style: "percent", minimumFractionDigits: "2"}) + '</span>';
            $(this).next().html(html);
        }
    });
    $(".input-field-purchase").trigger('change');
}

function toggleCheckboxes(cb, id) {
    $("input:checkbox[id*=" + id + "]").prop("checked", false);
    $(cb).prop("checked", true);
}

 
function afterReRender() {
  showButtons();
}
var previousOnload = window.onload; 
window.onload = function() {
if (previousOnload) { previousOnload(); } 
  showButtons();
} 
function showButtons(){
   $('.negoscopeRadio').show();
   $('.btn').show();
   $('.btnDisabled').show();
}
// function onEnter(e) {
//   alert(e.keyCode);
//   if (e.keyCode == 13) {
//     return true;
//   } 
// }
