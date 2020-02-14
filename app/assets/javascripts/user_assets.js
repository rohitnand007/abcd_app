
function user_assets_tables() {
    $(document).ready(function () {
        $("#user_assets_list").dataTable({
            "aoColumns": [
                null, null, null, null,null,
                {"bSortable": false}
            ],
            "sDom": 'frtipl',
            "bAutoWidth": false, "aaSorting": [],// disable default auto sorting ex : [ 4, "desc" ] for 4th column
            "bPaginate": true,
            "sPaginationType":"full_numbers",
            "iDisplayLength": 10,
            "bFilter": true,
            "bInfo": true,
            "bRetrieve": true,
            "bDestroy": true,
            "oLanguage": {"sSearch": "Search Assets:"}

        });
    });

    $(document).ready(function () {
        $("#available_books_list").dataTable({
            "aoColumns": [
                null, null,null,null,
                {"bSortable": false}
            ],
            "sDom": 'frtipl',
            "bAutoWidth": false, "aaSorting": [],// disable default auto sorting ex : [ 4, "desc" ] for 4th column
            "bPaginate": true,
            "sPaginationType":"full_numbers",
            "iDisplayLength": 10,
            "bFilter": true,
            "bInfo": true,
            "bRetrieve": true,
            "bDestroy": true,
            "oLanguage": {"sSearch": "Search Books:"}

        });
    });

    $(document).ready(function () {
        $("#listing_content_deliveries").dataTable({
            "aoColumns": [
                null, null, null, null,null,null,null,null,null,
                {"bSortable": false}
            ],
            "sDom": 'frtipl',
            "bAutoWidth": false, "aaSorting": [],// disable default auto sorting ex : [ 4, "desc" ] for 4th column
            "bPaginate": true,
            "sPaginationType":"full_numbers",
            "iDisplayLength": 10,
            "bFilter": true,
            "bInfo": true,
            "bRetrieve": true,
            "bDestroy": true,
            "oLanguage": {"sSearch": "Published Assets:"}

        });

    });

}

user_assets_tables();




