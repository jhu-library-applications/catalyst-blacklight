// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

Blacklight.onLoad(function() {
  // Sync article search query inputs
  $(".copy-input").keyup(function() {
    $(".copy-input").val($(this).val());
  });

  // Link option - onclick
  $('.blacklight-articles .dropdown-menu > .dropdown-item').on('click', function(e) {
    search_engine = $(this)[0].innerHTML;
    article_form = $(this).data('form');

    // Hide all search forms
    $('.form-display').collapse('hide');

    // Relabel form selector button and set a form data attr
    $('#article-form-selector').html(search_engine);
    $('#article-form-selector').data('form', article_form);
  });

  // Reverse toggle collapse on current form
  $('.form-display').on('hidden.bs.collapse', function () {
    $($('#article-form-selector').data('form')).collapse('show');
  })

  // Update JSTOR search destination URL and query
  $(document).on('submit', '#af-jstor form', function(){
      var $form = $(this);
      $form.find('input#jstor-dest').val('https://www.jstor.org/action/doBasicSearch?Query=' + $form.find('input[name="Query"]').val());
  });
});
