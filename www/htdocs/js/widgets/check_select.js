$(function() {
	$("input#ds").click(function() {
		var count = $("input:checked").length;
		if (count <= 0) {
			alert("您尚未選取任何一個電子報！");
			return false;
		}
	});

	$("input#cs").click(function() {
		var count = $("input:checked").length;
		if (count <= 0) {
			alert("您尚未選取任何一個電子報！");
			return false;
		}
	});
});
