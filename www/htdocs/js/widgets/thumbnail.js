$(function() {
	$("body").append(
"<div id=\"thumb\" class=\"shadowed\"><img id=\"screenshot\" style=\"width: 240px; height: 180px;\" src=\"\" /></div>"
	);
	$("#thumb").css("position", "absolute");
	$("#thumb").css("display", "none");

	$(".thumbnail").mouseover(function() {
		var offset = $(this).offset();
		var height = $(this).height();
		var top = offset.top + height + 4;
		var left = offset.left;
		$("#thumb").css("left", left + "px");
		$("#thumb").css("top", top + "px");
		$("#thumb").fadeIn("fast");
                var src = "/slist/screenshots/" + $(this).attr("id");
                $("#screenshot").attr("src", src);
	});

	$(".thumbnail").mouseout(function() {
		$("#thumb").css("display", "none");
	});
});
