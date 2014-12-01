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

		{{HEADER_INDEX}}

		<div class="container">
			<div class="table-responsive">
				<table class="table table-striped table-hover">
					<thead class="bg-primary">
						<tr><th></th><th>Name</th><th colspan="2">Size</th></tr>
					</thead>
					<tbody>
						{{FILE_LIST}}
					</tbody>
				</table>

				<form enctype="multipart/form-data" method="POST">
					<input type="hidden" name="FileUpload" value="1" />
					<input type="hidden" name="MAX_FILE_SIZE" value="100000" />
					Choose a file to upload: <input name="uploadedfile" type="file" /><br />
					<input type="submit" value="Upload File" />
				</form>
				<div id="dropzone" class="fade well"></div>
				<script src="/_served_pub/dropupload.js" type="text/javascript"></script>
			</div>
		</div>
		<script src="/_served_pub/jquery/jquery.min.js"></script>
		<script src="/_served_pub/bootstrap/js/bootstrap.min.js"></script>
	</body>
</html>