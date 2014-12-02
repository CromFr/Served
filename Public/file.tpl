<tr onclick="$('#file_popover_{{ID}}').popover('show')">

	<td class="text-nowrap">
		<div class="{{ICON}}"></div> <div class="{{ICON_LINK}}"></div>
	</td>

	<td class="text-forcewrap">
		<a href="{{LINK}}">{{NAME}}</a>
		<div id="file_popover_{{ID}}" class="popover popover-html" data-trigger="click focus" data-placement="bottom" data-toggle="popover">
			<div class="arrow"></div>
			<h3 class="popover-title primary">{{NAME}}</h3>
			<div class="popover-content">
				<form id="form_new_folder" role="form" enctype="multipart/form-data" method="POST">
					<input name="posttype" type="hidden" value="rename"/>
					<input name="file" type="hidden" value="{{NAME}}"/>
					<label>Rename</label>
					<div class="input-group">
						<input name="name" type="text" class="form-control" placeholder="New name" value="{{NAME}}">
						<span class="input-group-btn">
							<button class="btn btn-primary" type="submit"><div class="glyphicon glyphicon-ok"></div></button>
						</span>
					</div>
				</form>
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