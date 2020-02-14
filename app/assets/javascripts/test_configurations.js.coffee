  $(document).ready ->
    $('#assessment_test_configurations_attributes_0_receiver_name').autocomplete
                 source: "/profile_users"
                 select: (event,ui) -> $("#assessment_test_configurations_attributes_0_recipient_id").val(ui.item.id)

    $('#test_configuration_receiver_name').autocomplete
                 source: "/profile_users"
                 select: (event,ui) -> $("#test_configuration_recipient_id").val(ui.item.id)