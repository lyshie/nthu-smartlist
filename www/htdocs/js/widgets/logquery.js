$(function() {
	$("#logquery").change(function() {
		var str = "";
		$("select#logquery option:selected").each(function () {
			str = $(this).val();
		});
                if (str == "all") {
                    $(".list").css("display", "");
                }
                else {
                    $(".list").css("display", "none");
                    $(".list").filter(function() {
                        return this.id.match(str);
                    }).css("display", "");
                }
	});
});
