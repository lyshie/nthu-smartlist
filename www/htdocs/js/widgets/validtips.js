$(function() {
	$("body").append(
"<div id=\"validbar\" class=\"shadowed\"><div class=\"validtips\"><b>驗證碼輸入提示</b><br /><img src=\"/slist/images/sample.png\" border=\"0\" alt=\"樣本\" /><br />樣本表示：0123456789</div></div>"
	);
	$("#validbar").css("position", "absolute");
	$("#validbar").css("display", "none");

	$("input#validtips").mouseover(function() {
		var offset = $(this).offset();
		var height = $(this).height();
		var top = offset.top + height + 4;
		var left = offset.left;
		$("#validbar").css("left", left + "px");
		$("#validbar").css("top", top + "px");
		$("#validbar").fadeIn("fast");
	});

	$("input#validtips").mouseout(function() {
		$("#validbar").css("display", "none");
	});
});
