
function cancel(e) {
	if (e.preventDefault)
		e.preventDefault();
	return false;
}

function onFileDrag(e){
	e.dataTransfer.setData("dragtype", "filerow");
	e.dataTransfer.setData("dragfilename", $(e.target).attr("data-filename"));
}



addEventHandler(document, "dragenter", function(e){

	var targettr = $(e.target).parent("tr");
	if(e.dataTransfer.getData("dragtype")=="filerow" && targettr.attr("data-isfolder")=="true"){
		cancel(e);
		targettr.addClass("hover");

		var evContainer = e.target;

		addEventHandler(evContainer, "dragover", function(e){
			cancel(e);
		});

		addEventHandler(evContainer, "dragexit", function(e){
			targettr.removeClass("hover");
			removeEventListener("drop", evContainer, true);
			removeEventListener("drop", evContainer, false);
		});
	}
});

addEventHandler(document, "drop", function(e){

	var targettr = $(e.target).parent("tr");
	if(e.dataTransfer.getData("dragtype")=="filerow" && targettr.attr("data-isfolder")=="true"){
		cancel(e);

		targettr.removeClass("hover");

		xhr = new XMLHttpRequest();
		xhr.open('POST', window.location.pathname);

		var formData = new FormData();
		formData.append('posttype', 'move');
		formData.append('file', e.dataTransfer.getData("dragfilename"));
		formData.append('destination', targettr.attr("data-filename"));
		xhr.send(formData);
		return false;
	}
});











function addEventHandler(obj, evt, handler) {
	if (obj.addEventListener)// W3C method
		obj.addEventListener(evt, handler, false);
	else if (obj.attachEvent)// IE method.
		obj.attachEvent('on' + evt, handler);
	else// Old school method.
		obj['on' + evt] = handler;
}