$(function() {
	$("a#zoom").click(function() {
		var h = $("a#zoom").data("href");
		var href = "";
		if (h) {
			href = h;
		}
		else {
			href = $("a#zoom").attr("href");
			$("a#zoom").data("href", href);
		}
		var width = parseInt($(window).width() * 0.9);
		var height = parseInt($(window).height() * 0.85);
		$("a#zoom").attr("href", href + "&amp;width=" + width + "&amp;height=" + height);
	});
});
