	// Load the pdf 
	function loadPDF(inputFile){
		var success = new PDFObject({ url: inputFile }).embed("documentContainer");
	};

	
	
	// function toggle_visibility(id) {
	//    var e = document.getElementById(id);
	//    if(e.style.display == 'block'){
	// 	  e.style.display = 'none';
	// 	  document.getElementById("documentContainer").className="documentContainer";
	// 	}
	//    else{
	// 	  e.style.display = 'block';
	// 	  document.getElementById("documentContainer").className="documentContainerCondensed";
	// 	}
	// };
	// function make_invisible(id) {
	// 	var e = document.getElementById(id);
	// 	e.style.display = 'none';
	// }
	// function toggle_menu_visibility(id1,id2) {
	//    var e1 = document.getElementById(id1);
	//    var e2 = document.getElementById(id2);
	//    e1.style.display = 'block';
	// 	e2.style.display = 'none';
	// };
	
	
	// menu_status = new Array();
	// function showHide(theid){
	// 	if (document.getElementById) {
	// 		var switch_id = document.getElementById(theid);

	// 		if(menu_status[theid] != 'show') {
	// 		switch_id.className = 'show';
	// 		menu_status[theid] = 'show';
	// 		}
	// 		else{
	// 		switch_id.className = 'hide';
	// 		menu_status[theid] = 'hide';
	// 		}
	// 	}
	// }
	
	// function showOrganism(showDivID, divArray){
	// 	for(var i=0; i < divArray.length; i++){
	// 		document.getElementById(divArray[i]).className = 'hide';
	// 	}
	// 	document.getElementById(showDivID).className = 'annotationContainer show';
	// }
	
	// function getInputType(){
	// 	var urlRE = /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/;
	// 	var inputString = document.getElementById("txtSearchTerms");
	// 	if ( urlRE.test(inputString)) 
	// 	{
	// 		var page = "DisplayAnnotation.pl?url=";
	// 		var destination = page.concat(inputString);
	// 		window.location = destination; 
	// 		console.log("logging:" + inputString);
	// 	}
		
	// 	else 
	// 	{
	// 		window.location = "search.pl"; 
	// 	}
	// }
	
	// function handleCheckBoxClick(cb) {
	// 	var detailContainer = 'geneDetailContainer' + cb.value;
	// 	var tabHeader = 'tabHeader' + cb.value;
	// 	if(cb.checked) {
	// 		//Show the container
	// 		document.getElementById(tabHeader).className = "tabHeader";
	// 		document.getElementById(detailContainer).className = "annotationContainer show";
	// 		//Emulate the onclick event of the element
	// 		var headerElement = document.getElementById(tabHeader);
	// 		headerElement.onclick.apply(headerElement);
	// 	}
	// 	else {
	// 		document.getElementById(tabHeader).className = "hide";
	// 		document.getElementById(detailContainer).className = "hide";
	// 	}
	// }