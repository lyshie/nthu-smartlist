$(function() {
	$("body").append(
"<div id=\"searchbar\" class=\"shadowed\"><div class=\"searchtips\"><b>搜尋提示</b><br />您可以使用加號(+)來做多個關鍵字的比對查詢，例如：<br />「電腦+軟體」<br />將可搜尋出包含「電腦」同時也包含「軟體」多個關鍵字的主旨。</div></div>"
	);
	$("#searchbar").css("position", "absolute");
	$("#searchbar").css("display", "none");

	$("input#searchtips").mouseover(function() {
		var offset = $(this).offset();
		var height = $(this).height();
		var top = offset.top + height + 4;
		var left = offset.left;
		$("#searchbar").css("left", left + "px");
		$("#searchbar").css("top", top + "px");
		$("#searchbar").fadeIn("fast");
	});

	$("input#searchtips").mouseout(function() {
		$("#searchbar").css("display", "none");
	});
});
