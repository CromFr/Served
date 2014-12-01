<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
		<meta name="viewport" content="width=device-width, initial-scale=1">

		<title>{{PAGE_TITLE}}</title>
		<link rel="stylesheet" href="/_served_pub/bootstrap/css/bootstrap.min.css" type="text/css"/>
		<link rel="stylesheet" href="/_served_pub/style.css" type="text/css"/>
	</head>
	<body>
		<nav class="navbar navbar-inverse navbar-fixed-top" role="navigation">
			<div class="container">
				<div class="navbar-header">
					<a class="navbar-brand" href='https://github.com/CromFr/Served'>Served</a>
				</div>
				<div id="navbar" class="navbar-collapse collapse">
					<ul class="nav navbar-nav">
						{{NAVBAR_PATH}}
					</ul>
				</div>
			</div>
		</nav>

		<div class="jumbotron">
			{{HEADER_INDEX}}
		</div>

		<div class="container">
			<table class="table table-striped table-hover">
				<thead class="bg-primary">
					<tr><th></th><th width="85%">Name</th><th width="15%" colspan="2">Size</th></tr>
				</thead>
				<tbody>
					{{FILE_LIST}}
				</tbody>
			</table>

			<button type="button" class="btn btn-primary btn-lg" data-toggle="modal" data-target="#modal_upload_file">
				<div class="glyphicon glyphicon-upload"></div> Upload file
			</button>
		</div>


		<div class="modal fade" id="modal_upload_file" tabindex="-1" role="dialog" aria-labelledby="modal_upload_file_label" aria-hidden="true">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal"><span>&times;</span><span class="sr-only">Close</span></button>
						<h4 class="modal-title" id="modal_upload_file_label">Drop file here</h4>
					</div>
					<div class="modal-body">
						<div id="dropzone" class="fade well"></div>
					</div>
					<div class="modal-footer">
						<form role="form" class="form-inline" enctype="multipart/form-data" method="POST">
								<input class="input-file" name="uploadedfile" type="file">
								<button class="btn btn-primary" type="submit">Upload</button>
							<input type="hidden" name="FileUpload" value="1" />
						</form>
					</div>
				</div>
			</div>
		</div>


		<script src="/_served_pub/jquery/jquery.min.js"></script>
		<script src="/_served_pub/bootstrap/js/bootstrap.min.js"></script>
		<script src="/_served_pub/dropupload.js" type="text/javascript"></script>
	</body>
</html>