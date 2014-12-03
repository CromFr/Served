<tr class="filerow" onclick="$('#file_popover_{{ID}}').popover('show')" data-filename="{{NAME}}" data-isfolder="{{IS_FOLDER}}" draggable="true" ondragstart="onFileDrag(event)">




	<td class="text-nowrap">
		<div class="{{ICON}}"></div> <div class="{{ICON_LINK}}"></div>
	</td>

	<td class="text-forcewrap">
		<a href="{{LINK}}">{{NAME}}</a>
		<div id="file_popover_{{ID}}" class="popover popover-html" style="max-width: 350px;" data-trigger="click focus" data-placement="bottom" data-toggle="popover">
			<div class="arrow"></div>
			<div class="popover-content">

				<label>Full rights</label>
				<div class="btn-group btn-group-justified" role="group">
					<a type="button" class="btn btn-default {{RIGHT_USER_STYLE}}"><b>{{USER}}</b><br/>{{RIGHT_USER}}</a>
					<a type="button" class="btn btn-default {{RIGHT_GROUP_STYLE}}"><b>{{GROUP}}</b><br/>{{RIGHT_GROUP}}</a>
					<a type="button" class="btn btn-default {{RIGHT_OTHER_STYLE}}"><b>other</b><br/>{{RIGHT_OTHER}}</a>
				</div>
				<br/>
				<form id="form_rename_{{ID}}" role="form" enctype="multipart/form-data" method="POST">
					<input name="posttype" type="hidden" value="rename"/>
					<input name="file" type="hidden" value="{{NAME}}"/>
					<label>Rename</label>
					<div class="input-group">
						<input name="name" type="text" class="form-control" placeholder="New name" value="{{NAME}}"/>
						<span class="input-group-btn">
							<button class="btn btn-primary" type="submit"><div class="glyphicon glyphicon-ok"></div></button>
						</span>
					</div>
				</form>
				<br/>
				<label>Remove/hide file</label>
				<div class="btn-group-justified" role="group">
					<form id="form_remove_{{ID}}" class="btn-group" role="form" enctype="multipart/form-data" method="POST">
						<button class="btn btn-danger" type="submit"><div class="glyphicon glyphicon-trash"></div> Remove</button>
						<input name="posttype" type="hidden" value="remove"/>
						<input name="file" type="hidden" value="{{NAME}}"/>
					</form>
					<form id="form_remove_{{ID}}" class="btn-group" role="form" enctype="multipart/form-data" method="POST">
						<input name="posttype" type="hidden" value="rename"/>
						<input name="file" type="hidden" value="{{NAME}}"/>
						<input name="name" type="hidden" value=".{{NAME}}"/>
						<button class="btn btn-warning" type="submit"><div class="glyphicon glyphicon-lock"></div> Hide</button>
					</form>
				</div>
			</div>
		</div>
	</td>

	<td class="text-nowrap"><kbd>{{RIGHTS}}</kbd></td>

	<td class="text-right text-nowrap">
		<samp>{{SIZE_PRETTY}}</samp>
	</td>
	<td style="min-width: 50px; width:100%;">
		<div class="progress" style="margin: 0;">
			<div class="progress-bar progress-bar-info progress-bar-striped" role="progressbar" style="width: {{SIZE_PERCENT}}%">
			</div>
		</div>
	</td>

</tr>