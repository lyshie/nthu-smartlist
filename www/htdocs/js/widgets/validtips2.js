$(function() {
	$("body").append(
"<div id=\"validbar2\" class=\"shadowed\"><div class=\"validtips\"><b>驗證碼輸入提示</b><br /><img src=\"/slist/images/sample.png\" border=\"0\" alt=\"樣本\" /><br />樣本表示：0123456789</div></div>"
	);
	$("#validbar2").css("position", "absolute");
	$("#validbar2").css("display", "none");

	$("input#validtips2").mouseover(function() {
		var offset = $(this).offset();
		var height = $(this).height();
		var top = offset.top + height + 4;
		var left = offset.left;
		$("#validbar2").css("left", left + "px");
		$("#validbar2").css("top", top + "px");
		$("#validbar2").fadeIn("fast");
	});

	$("input#validtips2").mouseout(function() {
		$("#validbar2").css("display", "none");
	});
});
