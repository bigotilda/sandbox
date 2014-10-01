# OVERVIEW: contains various generic ajax and other functions that are used in a configuration area of a 
# Ruby On Rails web application.
#
# NOTE this was written before I had exposure to Backbone, Angular or other front end frameworks. Today
# I would happily use these fancy frameworks to cut back on the jQuery spaghetti that complex applications
# are otherwise generally comprised of.

# Place all the behaviors and hooks related to shared config logic here
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
  
# -------------------
# --- Datatables Functions ---
# -------------------

# set the dropdowns for datatables to use chosen
@dt_chosen = ->
  $("div.dataTables_length select").chosen()


# initialize the specified table as a datatable with common layout options, and table-specific aoColumnDefs
@datatable_init = (tableSelector,aoColumnDefs) ->
  # datatables
  commonOptions =
    "sDom": "<'row-fluid'<'span6'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "sPaginationType": "bootstrap",
    "oLanguage": { "sLengthMenu": "_MENU_ records per page" }
  
  commonOptions["aoColumnDefs"] = aoColumnDefs
    
  $(tableSelector).dataTable(commonOptions)
  
  # set the pager select to use chosen
  $("#{tableSelector}_length select").chosen()
  
  
# -------------------
# --- AJAX Shared/Generator Functions ---
# -------------------

# The always function, which runs always after an ajax creation or update, no matter if it fails or succeeds
@ajax_save_always = ->
  hide_ajax_loader()
  
  
# Generate a success function after AJAX save calls; it hides the specified modal and retrieves the specified JS which should update part of the page
# Options fields:
#   modal:  the ID of the modal that will be hidden
#   script: the URL of the JS script to retrieve and run
@ajax_save_success = (options) ->
  ->
    $("##{options.modal}").modal('hide')
    $.getScript(options.script)
    

# Generate a fail function for after AJAX save calls; the function takes a callback parameter, and it resets the specified save button click action to
# the callback parameter, retrieves the errors from the JSON response object, and displays them in the specified error div
# Options:
#   save_button: the id of the desired save button
#   error_div:   the id of the error div where error messages from the JSON object should be displayed 
#   error_info:  array of objects, one for each error field that should be reported on; each object has:
#                  field:  the name of the error field to check for
#                  prefix: the string prefix to use which is prepended to the rest of the error for the specified error field
@ajax_save_fail = (options) ->
  (save_click_callback) ->
    (jqXHR) ->
      # assign the callback back to the save button so we can try again (normally this function is a one-time event for the click)
      $("##{options.save_button}").one('click.powder', save_click_callback)
      
      # get the errors from rails and highlight appropriate UI fields
      errors = $.parseJSON(jqXHR.responseText)
      error_fields_to_check = []
      $.each(options.error_info, (index,err_obj) ->
        error_fields_to_check.push "errors.#{err_obj.field}")
      
      if eval(error_fields_to_check.join('||'))
        $("##{options.error_div}").empty()
        $.each(options.error_info, (index,err_obj) ->
          if errors[err_obj.field]
            $.each(errors[err_obj.field], (ind,err_msg) ->
              $("##{options.error_div}").append("<div>#{err_obj.prefix} #{err_msg}</div>")))
        $("##{options.error_div}").removeClass('hidden')
        
        
# Take a target URL, a specified params function, a success function, and a fail function, and generates a function that PUTs to that URL and utilizes
# the specified callbacks and params.
# Options:
#   url:     the target URL to PUT to
#   params:  the function to generate the desired params to send along with the request
#   success: the callback function to use for successful result
#   fail:    the callback function to use for a failure
@ajax_put = (options) ->
  this_function = ->
    show_ajax_loader()
    $.ajax(
      url: options.url
      type: 'PUT'
      data: options.params()
      dataType: 'json')
    
    .done(options.success)
    
    .fail(options.fail(this_function))
    
    .always(ajax_save_always)

    
# Take a target URL, a specified params function, a success function, and a fail function, and generates a function that POSTs to that URL and utilizes
# the specified callbacks and params.
# Options:
#   url:     the target URL to POST to
#   params:  the function to generate the desired params to send along with the request
#   success: the callback function to use for successful result
#   fail:    the callback function to use for a failure
@ajax_post = (options) ->
  this_function = ->
    show_ajax_loader()
    $.post(options.url, options.params(), null, 'json')
    .done(options.success)
    .fail(options.fail(this_function))
    .always(ajax_save_always)
    
    
# -------------------
# --- Shared Config Form Logic ---
# -------------------

# capture the enter key on the specified element, and have it submit the form by clicking the specified save button.
#   @param selector: jquery selector string or a jquery nodeset specifying the element(s) to receive this keydown event
#   @param button: (optional) the jquery selector string identifying the save button to be clicked when enter is pressed
#   @options: (optional) Object:
#               except: jquery selector string specifying a set of text fields for which the save button should not be clicked when
#                       enter key is pressed
@form_capture_enter = (selector, button = 'button.form-modal-saver', options = {}) ->
  $(selector).keydown (e) ->
    # if the enter key has been pressed, cancel the default (which is to try to submit a form) and instead
    # click the "save" button; HOWEVER do not do this for the chosen search fields
    if e.which == 13 && !($(e.target).parent('div.chzn-search').length)
      if !(options.except? && $.inArray($(e.target).get(0), $(options.except)) > -1)
        e.preventDefault()
        $(this).find(button).click()

      
# -------------------
# --- Shared Tab Logic ---
# -------------------
@tab_update_url = (tab_id, url) ->
  # make sure the browser has this function (it is HTML5)
  if window.history? && window.history.replaceState?
    $("a[data-toggle=tab][href=#{tab_id}]").on 'shown', ->
      window.history.replaceState('','',url)


# -------------------
# --- Error Handling ---
# -------------------

# Fill in the error area in the document with the specified notification and validation content
# Options fields:
#   header: the text that will be displayed as a pnotify message at the top of the screen
#   errors: an array of error message sentences that will be formatted as a list and shown as a hovering
#           validation error on the top right of the screen
@show_errors = (options) ->
  header_html = 
    """
    <div class="pnotify-popup-error">
      <p>#{options.header}</p>
    </div>
    """
  
  validation_html = 
    """
    <div class="pnotify-validation-error">
      <h3>#{options.errors.length} error#{if options.errors.length > 1 then 's' else ''} occurred:</h3>
      <ul>
    """
  validation_html += "<li>#{msg}</li>" for msg in options.errors
  validation_html +=
    """
      </ul>
    </div>
    """

  $('#error-area').html(header_html + validation_html)
  show_notifications()
    

# Clear the errors area
@clear_errors = ->
  $('#error-area').empty()
  clear_notifications()


# -------------------
# --- Document Ready ---
# -------------------
$(document).ready ->
  # chosen
  $('[data-form=chosen]').chosen()
  $('[data-form=chosen-full-width]').chosen({width: "100%"})
  $('[data-form=chosen-deselect]').chosen({allow_single_deselect:true, width: "100%"})

  
  # uniform
  $('[data-form=uniform]').uniform()
  
  
  # help labels
  $('label.extra-help').click ->
    target = $(this).attr('for') + '_help'
    $("##{target}").toggleClass('hidden')
  
    
  # -------------------
  # --- shared form modal logic ---
  # -------------------
  
  # any form modal being closed needs to clear out the save button click.powder event to avoid multiple calls to the event (because a new
  # click action gets set each time by the "new" buttons or the "edit" links)
  $('div.modal').on 'hide', ->
    $('.form-modal-saver').off('click.powder')
  
    
  # -------------------
  # --- shared misc config logic ---
  # -------------------
  
  # any info-icon should show a pnotify with its assigned informational message as the text on click
  $('body').on 'click', '.info-icon', ->
    msg = $(this).data('powder-msg')
    if !msg
      msg = 'Informational message.'
    js_notify('info', msg)
