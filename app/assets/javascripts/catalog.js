// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Blacklight.onLoad(function() {
    // Update selected field on page load if target (search_field) is present in URL
    selectedSerachField = $('.search-query-form.catalog-search input[name="search_field"]').val() || '';
    if(selectedSerachField.length > 0 && selectedSerachField != 'any_fields'){
        search_field_label = $('.search-field-form-selector .dropdown-menu .dropdown-item[data-target="' +  $('.search-query-form.catalog-search input[name="search_field"]').val() + '"]')[0].innerHTML;
        $('#targetDropdownMenuButton').html(search_field_label);
    }

    // Update search field for catalog search
    $('.search-field-form-selector .dropdown-menu > .dropdown-item').on('click', function(e) {
        search_field_label = $(this)[0].innerHTML;
        search_field = $(this).data('target');

        // Relabel form selector button and set a form data attr
        $('#targetDropdownMenuButton').html(search_field_label);
        $('input[name="search_field"]').val(search_field);
    });

    $('body').on('click', '[data-toggle="modal"]', function(){
        $($(this).data('target')+' .modal-body').load($(this).attr('href'));
    });
});
