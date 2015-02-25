
var DRAGFILE_DATA;

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

	DRAGFILE_DATA=data;
	// e.dataTransfer.setData("text", JSON.stringify(data));
	e.dataTransfer.setData("text", "Fuck you browser");//A pinch of magic to make firefox start dragging the item
}



addEventHandler(document, "dragenter", function(e){
	var targettr = $(e.target).parent(".filerow");

	// if(targettr!=null && IsJson(e.dataTransfer.getData("text"))){
	if(targettr!=null && DRAGFILE_DATA!=null){
		// var data = JSON.parse(e.dataTransfer.getData("text"));
		var data = DRAGFILE_DATA;

		if(data.type=="filerowdrag" && data.file!=targettr.attr("data-filename") && targettr.attr("data-isfolder")=="true"){
			cancel(e);
			targettr.addClass("hover");

			var evContainer = e.target;

			addEventHandler(evContainer, "dragover", function(e){
				cancel(e);
			});

			addEventHandler(evContainer, "dragleave", function(e){
				targettr.removeClass("hover");
			});
		}
	}
});

addEventHandler(document, "drop", function(e){
	var targettr = $(e.target).parent(".filerow");

	// if(targettr!=null && IsJson(e.dataTransfer.getData("text"))){
	if(targettr!=null && DRAGFILE_DATA!=null){
		// var data = JSON.parse(e.dataTransfer.getData("text"));
		var data = DRAGFILE_DATA;

		if(data.type=="filerowdrag" && data.file!=targettr.attr("data-filename") && targettr.attr("data-isfolder")=="true"){
			cancel(e);

			targettr.removeClass("hover");

			xhr = new XMLHttpRequest();
			xhr.open('POST', window.location.pathname);

			var formData = new FormData();
			formData.append('posttype', 'move');
			formData.append('file', data.file);
			formData.append('destination', targettr.attr("data-filename"));
			xhr.send(formData);

			DRAGFILE_DATA = null;
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