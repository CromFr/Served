var drop = document.getElementById('droparea');


//Display modal
document.addEventListener('dragenter', function(e){
	e.preventDefault();
	$('#modal_upload_file').modal();
}, false);

//Hilight drop area
drop.addEventListener('dragenter', function(e){
	e.preventDefault();

	if(drop.className.search(/\bhover\b/)==-1)
		drop.className = drop.className+" hover";
}, false);

//Un-hilight drop area
drop.addEventListener('dragexit', function(e){
	e.preventDefault();

	drop.className = drop.className.replace(/\bhover\b/,'');
}, false);

//Upload file
drop.addEventListener('drop', function(e){
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
		//handleComplete(file.size);
		};
		xhr.onerror = function() {
			//result.textContent = this.responseText;
			//handleComplete(file.size);
		};
		xhr.upload.onprogress = function(event){
			//var progress = totalProgress + event.loaded;
			//console.log(progress / totalSize);
		}
		xhr.upload.onloadstart = function(event) {
		}

		// création de l'objet FormData
		var formData = new FormData();
		formData.append('uploadedfile', file);
		xhr.send(formData);
	}
}, false);

//Un-hilight drop area
document.addEventListener('drop', function(e){
	e.preventDefault();

	drop.className = drop.className.replace(/\bhover\b/,'');
}, false);