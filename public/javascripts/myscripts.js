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
});