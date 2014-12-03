
function cancel(e) {
	if (e.preventDefault)
		e.preventDefault();
	return false;
}

function onFileDrag(e){

	var data = {
		type: "filerowdrag",
		file: $(e.target).attr("data-filename")
	};

	e.dataTransfer.setData("url", JSON.stringify(data));
}



addEventHandler(document, "dragenter", function(e){
	var targettr = $(e.target).parent(".filerow");

	if(targettr!=null && IsJson(e.dataTransfer.getData("url"))){
		var data = JSON.parse(e.dataTransfer.getData("url"));

		if(data.type=="filerowdrag" && targettr.attr("data-isfolder")=="true"){
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
	}
	


});

addEventHandler(document, "drop", function(e){
	var targettr = $(e.target).parent(".filerow");

	if(targettr!=null && IsJson(e.dataTransfer.getData("url"))){
		var data = JSON.parse(e.dataTransfer.getData("url"));

		if(data.type=="filerowdrag" && targettr.attr("data-isfolder")=="true"){
			cancel(e);

			targettr.removeClass("hover");

			xhr = new XMLHttpRequest();
			xhr.open('POST', window.location.pathname);

			var formData = new FormData();
			formData.append('posttype', 'move');
			formData.append('file', data.file);
			formData.append('destination', targettr.attr("data-filename"));
			xhr.send(formData);
			return false;
		}
	}
});










function IsJson(str) {
	try{
		JSON.parse(str);
	}
	catch(e){
		return false;
	}
	return true;
}
function addEventHandler(obj, evt, handler) {
	if (obj.addEventListener)// W3C method
		obj.addEventListener(evt, handler, false);
	else if (obj.attachEvent)// IE method.
		obj.attachEvent('on' + evt, handler);
	else// Old school method.
		obj['on' + evt] = handler;
}