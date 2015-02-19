<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
		<meta name="viewport" content="width=device-width, initial-scale=1"/>

		<title>{{PAGE_TITLE}}</title>
		<link rel="stylesheet" href="/_served_pub/bootstrap/css/bootstrap.min.css" type="text/css"/>
		<link rel="stylesheet" href="/_served_pub/style.css" type="text/css"/>
	</head>
	<body>
		<nav class="navbar navbar-inverse navbar-fixed-top" role="navigation">
			<div class="container">
				<div class="navbar-header navbar-left">
					<a class="navbar-brand" href='https://github.com/CromFr/Served'>Served</a>
				</div>
				<div id="navbar" class="navbar-left navbar-collapse collapse">
					<ul class="nav navbar-nav">
						{{NAVBAR_PATH}}
					</ul>
				</div>
				<div class="navbar-right">
					<p class="navbar-text">{{USER}}</p>
					<button type="button" class="btn btn-primary navbar-btn">
						<div class="glyphicon glyphicon-log-in"></div> Login

						<div>
							<div id="popover_login" class="popover popover-html" data-trigger="click" data-placement="bottom" data-toggle="popover">
								<div class="arrow"></div>
								<div class="popover-content">
									<form id="form_login" role="form" enctype="multipart/form-data" method="POST">
										<input name="posttype" type="hidden" value="login"/>
										<label>Login</label>
										<input name="login" type="text" class="form-control" placeholder="Login"/>
										<label>Password</label>
										<input name="password" type="password" class="form-control" placeholder=""/>
										<input style="display:none" type="submit" value="Submit"/>
									</form>
								</div>
							</div>
						</div>
					</button>
				</div>
			</div>
		</nav>

		<div class="jumbotron">
			{{HEADER_INDEX}}
		</div>

		<div class="container">

			
			<nav class="navbar navbar-default" role="navigation">
				<div class="container">
					<button type="button" class="btn btn-primary navbar-btn" data-toggle="modal" data-target="#modal_upload_file">
						<div class="glyphicon glyphicon-upload"></div> Upload
					</button>
					<button type="button" class="btn btn-primary navbar-btn" data-toggle="modal" data-target="#modal_new_folder">
						<div class="glyphicon glyphicon-folder-open"></div> New folder
					</button>
				</div>
			</nav>

			<table class="table table-striped table-hover">
				<thead class="bg-primary">
					<tr><th></th><th width="85%">Name</th><th>Rights</th><th width="15%" colspan="2">Size</th></tr>
				</thead>
				<tbody>
					{{FILE_LIST}}
				</tbody>
			</table>
		</div>


		<div class="modal fade" id="modal_upload_file" tabindex="-1" role="dialog" aria-labelledby="modal_upload_file_label" aria-hidden="true">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal"><span>&times;</span><span class="sr-only">Close</span></button>
						<h4 class="modal-title" id="modal_upload_file_label">Drop file here</h4>
					</div>
					<div class="modal-body">
						<div id="droparea" class="well"><div class="glyphicon glyphicon-save" style="width: 50%"></div></div>
					</div>
					<div class="modal-footer">
						<form id="form_upload_file" role="form" class="form-inline" enctype="multipart/form-data" method="POST">
							<input  name="posttype" type="hidden" value="uploadfile"/>
							<input class="input-file" name="uploadedfile" type="file"/>
							<button class="btn btn-success" type="submit">Upload</button>
							<button class="btn btn-danger" data-dismiss="modal">Cancel</button>
						</form>
					</div>
				</div>
			</div>
		</div>

		<div id="modal_upload_progress" class="modal fade bs-example-modal-lg" tabindex="-1" role="dialog" data-backdrop="static" data-keyboard="false" aria-labelledby="modal_upload_progress_label" aria-hidden="true">
			<div class="modal-dialog modal-lg">
				<div class="modal-content">
					<div class="modal-header">
						<h4 id="modal_upload_progress_label" class="modal-title">Upload progress</h4>
					</div>
					<div class="modal-body">
						<div class="progress" style="margin: 0;">
							<div id="modal_upload_progress_bar" class="progress-bar progress-bar-info progress-bar-striped active" role="progressbar" style="">
							</div>
						</div>
					</div>
					<div class="modal-footer">
						<button class="btn btn-danger" type="button" onclick="abortUpload()">Cancel</button>
					</div>
				</div>
			</div>
		</div>



		<div id="modal_new_folder" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="modal_new_folder_label" aria-hidden="true">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<button type="button" class="close" data-dismiss="modal"><span>&times;</span><span class="sr-only">Close</span></button>
						<h4 class="modal-title" id="modal_new_folder_label">New folder</h4>
					</div>
					<form id="form_new_folder" role="form" enctype="multipart/form-data" method="POST">
						<input name="posttype" type="hidden" value="newfolder"/>
						<div class="modal-body">
							<div class="form-group">
								<label>Folder name</label>
								<input name="name" type="text" class="form-control" placeholder="Enter name">
							</div>
						</div>
						<div class="modal-footer">
								<button class="btn btn-success" type="submit">New</button>
								<button class="btn btn-danger" data-dismiss="modal">Cancel</button>
						</div>
					</form>
				</div>
			</div>
		</div>

		<footer class="spacer">
		</footer>


		<script src="/_served_pub/jquery/jquery.min.js"></script>
		<script src="/_served_pub/bootstrap/js/bootstrap.min.js"></script>
		<script src="/_served_pub/dropupload.js" type="text/javascript"></script>
		<script src="/_served_pub/popover.js" type="text/javascript"></script>
		<script src="/_served_pub/filedrag.js" type="text/javascript"></script>
	</body>
</html>