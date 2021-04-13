// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Blacklight.onLoad(function() {
    // Hide Online from format facet because it's really duplicated in Access facet
    $('#facets #facet-format .facet-values li:contains("Online")').hide();

    // Update selected field if target (search_field) is present in URL
    var selectedSearchField = $('.search-query-form.catalog-search input[name="search_field"]').val() || '';
    if(selectedSearchField.length > 0 && (selectedSearchField !== 'all_fields' && selectedSearchField !== 'advanced' && selectedSearchField !== 'oclcnum')){
        var search_field_label = $('.search-field-form-selector .dropdown-menu .dropdown-item[data-target="' +  $('.search-query-form.catalog-search input[name="search_field"]').val() + '"]')[0].innerHTML;
        $('#targetDropdownMenuButton').html(search_field_label);
    }

    // Update search field for catalog search
    $('.search-field-form-selector .dropdown-menu > .dropdown-item').on('click', function(e) {
        var search_field_label = $(this)[0].innerHTML;
        var search_field = $(this).data('target');

        // Relabel form selector button and set a form data attr
        $('#targetDropdownMenuButton').html(search_field_label);
        $('input[name="search_field"]').val(search_field);
    });

    $('#blacklight-modal').on('hidden.bs.modal', function () {
        $('#blacklight-modal .modal-content').html('');
    });
});
