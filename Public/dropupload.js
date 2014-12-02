
var drop = document.getElementById('droparea');


function cancel(e) {
	if (e.preventDefault)
		e.preventDefault();
	return false;
}


if (!window.FileReader)
	drop.innerHTML = 'Your browser does not support the HTML5 FileReader.';
else{

	addEventHandler(drop, 'dragover', cancel);

	//open modal
	addEventHandler(window, 'dragenter', function(e){
		cancel(e);
		$('#modal_upload_file').modal('show');
	});

	//hilight
	addEventHandler(drop, 'dragenter', function(e){
		cancel(e);
		$('#droparea').addClass("hover");
	});
	addEventHandler(drop, 'dragexit', function(e){
		cancel(e);
		$('#droparea').removeClass("hover");
	});

	//Upload file
	addEventHandler(drop, 'drop', function(e){
		e.preventDefault();
		
		var dt = e.dataTransfer;
		var files = dt.files;
		for(var i=0; i<files.length; i++){
			var file = files[i];
			console.log(file);
			
			var xhr = new XMLHttpRequest();
			xhr.open('POST', window.location.pathname);
			xhr.onload = function() {
				//result.innerHTML += this.responseText;
				$('#modal_upload_progress').modal('hide');
			};
			xhr.onerror = function() {
				//result.textContent = this.responseText;
				console.log("Upload error !: "+this.responseText);
				$('#modal_upload_progress').modal('hide');
			};

			xhr.upload.onprogress = function(event){
				var totalProgress = 0;
				var p = (100 * (totalProgress + event.loaded)/file.size).toFixed(2);
				$('#modal_upload_progress_bar').css("width", p+"%");
				$('#modal_upload_progress_bar').html(p+"%");
				
			}
			xhr.upload.onloadstart = function(event) {
				$('#modal_upload_file').modal('hide');
				$('#modal_upload_progress').modal('show');
			}

			// création de l'objet FormData
			var formData = new FormData(document.getElementById("form_upload_file"));
			formData.append('uploadedfile', file);
			xhr.send(formData);
		}

		return false;
	}, false);


	Function.prototype.bindToEventHandler = function bindToEventHandler(){
		var handler = this;
		var boundParameters = Array.prototype.slice.call(arguments);
		//create closure
		return function (e) {
			e = e || window.event; // get window.event if e argument missing (in IE)   
			boundParameters.unshift(e);
			handler.apply(this, boundParameters);
		}
	};
}



function addEventHandler(obj, evt, handler) {
  if (obj.addEventListener) {
    // W3C method
    obj.addEventListener(evt, handler, false);
  } else if (obj.attachEvent) {
    // IE method.
    obj.attachEvent('on' + evt, handler);
  } else {
    // Old school method.
    obj['on' + evt] = handler;
  }
}
