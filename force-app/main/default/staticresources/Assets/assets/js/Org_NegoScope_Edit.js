
	
$(document).ready(function() {

  selectHighlightedElement();

});

/*
* trigger save action on enter key press 
*/
function submitByEnterKey(ev)  {
	if (window.event && window.event.keyCode == 13 || ev.which == 13) {
		saveNego();
		return false;
	} else {
		return true;
	}
}
			
function selectHighlightedElement(){
	
	$( "#all_include_product" ).click(function() {
		event.preventDefault();
		$("table#product-table tr input").prop("checked", false);
	    $("tr.highlighted input").prop("checked", true);
	});	
}
/**
  hightlight product group when we select a related brand
 */
function highlight() {

    productGroupHihtlightOnLoad();
}

	/*
 * Hightlight produt group based on brand when user load the page
 */
function productGroupHihtlightOnLoad() {
 
	
	$('.pg').removeClass('highlighted');
	var depArr = [];
	var secArr = [];
	var heExistArr = [];
	var brandInclude = []; 
	var brandExclude = [];
	var isRootExist = false;
	var strutureElementTableObj=$('#selected-structure-element-table tr');
	var brandTableInputCheckbox =$('#brand-table #BrandInput input');
	var pgTable =$('#product-table tr');
	
	brandTableInputCheckbox.each(function() { // lop on brand table 
		var brandId = $(this).parent().parent().attr('id');
		
		if ($(this).prop('checked') == true) { // check if brand is checked
   			brandInclude.push(brandId);
		}else{
		    brandExclude.push(brandId);
		}
	});


	strutureElementTableObj.each(function() { // loop on Structure element table
		if ($(this).attr('id') != null) {
			var elemId = $(this).attr('id').split("-");
			$('#addRoot-'+elemId[1]).hide(); 
			if(elemId[2]==0){ // check element level 
				$('.pg').addClass('highlighted'); 
			}
		}
	});


	strutureElementTableObj.each(function() { //loop on Structure element table
		
		if ($(this).attr('id') != null) {
		    var elemId = $(this).attr('id').split("-");
				// add he in 2 objects to seprate them by level 
				heExistArr.push(elemId[1]);
		 		 if(elemId[2] == 1){
		 		 	var depObj = new Object();
		 			 depObj.status = elemId[0];
		 			 depObj.id = elemId[1];
		 			 depArr.push(depObj);
		 		 }
		 		 if(elemId[2] == 2){    
		 		 	 var secObj = new Object();
		 		 	 secObj.status = elemId[0];
		 			 secObj.id = elemId[1];
		 			 secArr.push(secObj);
		 		 }	
		 		 if(elemId[2] == 0){   
		 		 	 isRootExist = true;
		 		 } 
		}
	});

	if($('input.allhecheckobx').prop('checked') == false){
	 // hightlight product based on he 
		
	  	for (i = 0; i < depArr.length; i++) { 

			if(depArr[i].status == 'Include'){
			    $('.dep-' + depArr[i].id).parent().addClass('highlighted');
			}else{
				$('.dep-' + depArr[i].id).parent().removeClass('highlighted');
			}
		}	
		for (i = 0; i < secArr.length; i++) { 

			if(secArr[i].status == 'Include'){
				$('.sec-' + secArr[i].id).parent().addClass('highlighted');
			}else{
				$('.sec-' + secArr[i].id).parent().removeClass('highlighted');
			}
		}	
	}
	
	
	
	if($('input.allbrandcheckbox').prop('checked') == false){
		// hightlight products based on checked brands 

		for (index = 0; index < brandInclude.length; index++) {
	 		$('.pg-' + brandInclude[index]).addClass('highlighted');
	 			
	 		
		 			for (i = 0; i < depArr.length; i++) { 
			 		  	if(depArr[i].status == 'Exclude'){
			 		 	 	$('.pg-' + brandInclude[index] + ' .dep-' + depArr[i].id).parent().removeClass('highlighted');
			 		  	}	
			 		  	if(depArr[i].status == 'Include'){
			 		 	 	$('.pg-' + brandInclude[index] + ' .dep-' + depArr[i].id).parent().addClass('highlighted');
			 		  	}	
			 		 
		 		  	}
		 			for (i = 0; i < secArr.length; i++) { 
			 		  	if(secArr[i].status == 'Exclude'){
			 		 	 	$('.pg-' + brandInclude[index] + ' .sec-' + secArr[i].id).parent().removeClass('highlighted');
			 		  	}		
			 		  	if(secArr[i].status == 'Include'){
			 		 	 	$('.pg-' + brandInclude[index] + ' .sec-' + secArr[i].id).parent().addClass('highlighted');
			 		  	}	
			 		  	
		 		  	}
		}
	
	   for (index = 0; index < brandExclude.length; index++) {
	 		$('.pg-' + brandExclude[index]).removeClass('highlighted');
		}
		
	}
	
	var i = 0;
	// check on he when we have root not included
	if($('input.allhecheckobx').prop('checked') == false){	  
		pgTable.each(function() { // loop on product table 
			var heDepId  = $(this).find('td:eq(2)').attr('class');
			var heSecId  = $(this).find('td:eq(3)').attr('class');
			i++;
			if(typeof heSecId !== 'undefined'){	
				var heDepIdArr = heDepId.split("-");
				var heSecIdArr = heSecId.split("-");
				if(isRootExist == false && heExistArr.indexOf(heDepIdArr[1])==-1 && heExistArr.indexOf(heSecIdArr[1])==-1){ 
						$(this).removeClass('highlighted');	
				}

			}	  
		});
   }
	
	
	// hightlight all products if all he and brand are checked 
	if($('input.allbrandcheckbox').prop('checked') == true && $('input.allhecheckobx').prop('checked') == true){
		$('.pg').addClass('highlighted');
	
	}
	
}


/*
 * Loop on choice dropdown and attach an onchange event
 */
function structureElementOnChangeEventLoad() {
	 productGroupHihtlightOnLoad();
}


/*
 * @param {string} cases : string to check a specifique case of process  
 */
 
function afterReRender(cases) {
	$('#elementslisttable').footable();
	$("#selected-structure-element-table").footable();
	$('#brand-table').footable();	
	productGroupHihtlightOnLoad();
	structureElementOnChangeEventLoad();
	selectHighlightedElement();
	if(cases == 'addroot'){
		$('a[id*=addRoot]').hide();
	}
	if(cases == 'focus'){
		$('.negoscopeName').focus();
	}

}

	
/**
 * 
 * @param {string}
 *            elementId
 */
function onDeleteSructureElement(elementId) {
	/*
	if(elementId!=''){	
		$('addRoot-'+elementId).show();
		$('.dep-' + elementId).parent().removeClass('highlighted');
		$('.sec-' + elementId).parent().removeClass('highlighted');
	}
	*/
}
