
var drop = document.getElementById('droparea');
var xhr;

function abortUpload(){
	xhr.abort();
}

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
		
		$('#droparea').removeClass("hover");
		
		var dt = e.dataTransfer;
		var files = dt.files;
		for(var i=0; i<files.length; i++){
			var file = files[i];
			console.log(file);
			
			xhr = new XMLHttpRequest();
			xhr.open('POST', window.location.pathname);
			xhr.onload = function(){
				$('#modal_upload_progress_bar').addClass("progress-bar-success");
				setTimeout(location.reload(), 1000);
			};
			xhr.onerror = function(e){
				$('#modal_upload_progress_bar').addClass("progress-bar-danger");
				
				setTimeout(location.reload(), 5000);
			};
			xhr.onabort = function(){
				$('#modal_upload_progress').modal('hide');
			};

			xhr.upload.onprogress = function(e){
				var p = (100 * e.loaded/file.size).toFixed(2);
				$('#modal_upload_progress_bar').css("width", p+"%");
				$('#modal_upload_progress_bar').html(p+"%");
				
			}
			xhr.upload.onloadstart = function(e){
				$('#modal_upload_file').modal('hide');
				$('#modal_upload_progress_bar').removeClass("progress-bar-danger");
				$('#modal_upload_progress_bar').removeClass("progress-bar-success");
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
