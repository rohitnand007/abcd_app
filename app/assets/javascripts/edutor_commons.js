/**
 * Created by harsha on 15/4/15.
 */
// This file requires jquery and jquery ui libraries

var attachSearchEvents = function () {
    $(".search_block").hover(function () {
        $("#search_content").slideDown(200)
    });
    $(".search_input").on("keydown", function () {
        $("#search_content").show();
    });
    $("#search_content").parent().on('mouseleave focusout', function () {
        $("#search_content").slideUp(200);
    });
}
var verifyPassword = function ($formObject, optionalMessageHtmlString) {
    var password = "";
    var validPassword = false;
    if (typeof(optionalMessageHtmlString) != 'string') {
        optionalMessageHtmlString = ""
    }
    $("<div style='color:#636363'>" + optionalMessageHtmlString + "<p>Please confirm your identity by entering your password again.</p><p><input type='password' id='pass'></p><input type='button' class='button' value='Submit'></input><p id='errorT' style='color:#ff0000;'></p></div>").dialog({
        title: "Password confirmation needed",
        width: "auto",
        modal: true,
        show: {
            effect: "clip",
            duration: 1000
        },
        hide: {
            effect: "explode",
            duration: 1000
        },
        close: function () {
            $(this).dialog('destroy');
        },
        open: function () {
            $this = $(this)
            $this.find(":button").click(function () {
                password = $("#pass").val();
                if (password != "") {
                    $.ajax({
                        url: "/users/authenticate_password.json",
                        data: {password: password},
                        success: function (data) {
                            //alert(JSON.stringify(data));
                            if (data.valid == true) {
                                validPassword = true;
                            }
                        },
                        type: "POST",
                        dataType: "JSON",
                        async: false
                    });
                }
                if (validPassword == true) {
                    $formObject.unbind("submit").submit();
                } else {
                    $('#errorT').text("Password is incorrect");
                    $("#pass").val('');
                    setTimeout(function () {
                        $('#errorT').empty();
                    }, 2000);
                }
            });
        }
    });
};
var active_header_block = localStorage.getItem('active_header_block');
if((active_header_block == null) || (active_header_block == 'null'))
    active_header_block = '#header_home';

var generateTable = function (header, records, style, table_attributes) {
    // caution: the number of columns in the header should match the number of columns in each record
    style = style || "width:100%;text-align:center;"
    table_attributes = table_attributes || ""
    table_attributes = table_attributes + " border='1px' cellpadding=10 cellspacing=0"
    html = "<table style='" + style + "' " + table_attributes + " " + ">"
    // adds header row
    headerHtml = "<thead><tr>"
    for (var j = 0; j < header.length; j++) {
        headerHtml = headerHtml + "<th>" + header[j] + "</th>"
    }
    headerHtml = headerHtml + "</tr></thead>"
    html = html + headerHtml + "<tbody>"
    // adds rows for each record
    for (var i = 0; i < records.length; i++) {
        record = records[i];
        recordHtml = "<tr>"
        for (var j = 0; j < record.length; j++) {
            recordHtml = recordHtml + "<td>" + record[j] + "</td>"
        }
        recordHtml = recordHtml + "</tr>"
        html = html + recordHtml;
    }
    html = html + "</tbody></table>"
    return html;
}