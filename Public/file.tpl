<tr onclick="$('#file_popover_{{ID}}').popover('show')">

	<td class="text-nowrap">
		<div class="{{ICON}}"></div> <div class="{{ICON_LINK}}"></div>
	</td>

	<td class="text-forcewrap">
		<a href="{{LINK}}">{{NAME}}</a>
		<div width="0px" id="file_popover_{{ID}}" class="popover popover-html" data-trigger="click focus" data-placement="bottom" data-toggle="popover">
			<div class="arrow"></div>
			<h3 class="popover-title">{{NAME}}</h3>
			<div class="popover-content">
				<div class="input-group">
					<input type="text" class="form-control">
						<span class="input-group-btn">
						<button class="btn btn-default" type="button">Go!</button>
					</span>
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