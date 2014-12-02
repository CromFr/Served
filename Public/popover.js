
//$('[data-toggle="popover"]').popover();

$(".popover-html").each(function() {
	var title = $(this).children(".popover-title").html();
	var content = $(this).children(".popover-content").html();

	$(this).parent().parent().popover({
		animation: $(this).attr("data-animation")==null ? true : $(this).attr("data-animation"),
		container: $(this).attr("data-container")==null ? false : $(this).attr("data-container"),
		content: content,
		delay: $(this).attr("data-delay")==null ? 0 : $(this).attr("data-delay"),
		html: true,
		placement: $(this).attr("data-placement")==null ? 'top' : $(this).attr("data-placement"),
		selector: $(this).attr("data-selector")==null ? false : $(this).attr("data-selector"),
		title: title,
		trigger: $(this).attr("data-trigger")==null ? 'hover focus' : $(this).attr("data-trigger")
	});
});