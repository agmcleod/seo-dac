// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
	var isShowing = false;
	$('#show-source').click(function() {
		if(!isShowing) {
			$(this).html('hide source');
			$('#source-code').css('display', 'inline');
			isShowing = true;
			return false;
		}
		else {
			$(this).html('show source');
			$('#source-code').css('display', 'none');
			isShowing = false;
			return false;
		}
	});
	// fix radio button checked bug in mozilla
	if($.browser.mozilla) $("form").attr("autocomplete", "off");
	
	if($('#report_url_type_single_page').is(':checked')) {
		$('#domain-type-warning').css({'display':'none'});
	}
	
	$('#report_url_type_domain').click(function() {
		$('#domain-type-warning').css({'display':'inline'});
	});
	$('#report_url_type_single_page').click(function() {
		$('#domain-type-warning').css({'display':'none'});
	});
	$('#tabs').tabs();
});