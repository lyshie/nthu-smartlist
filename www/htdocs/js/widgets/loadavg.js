$(function() {
	$.timer(1000, function() {
		$.ajax({
			url: "/slist/cgi-bin/jquery/loadavg.cgi?time=" + (new Date).getTime(),
			type: "GET",
			dataType: "xml",
			success: function(xml) {
				$("#loadavg #avg1").text($(xml).find("loadavg avg1").text());
				$("#loadavg #avg5").text($(xml).find("loadavg avg5").text());
				$("#loadavg #avg15").text($(xml).find("loadavg avg15").text());
			}
		});
	});
});
