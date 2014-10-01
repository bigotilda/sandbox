# OVERVIEW: contains code for a configuration screen in a Ruby On Rails web application that deals with
# email mailer settings, etc.
#
# NOTE this was written before I had exposure to Backbone, Angular or other front end frameworks. Today
# I would happily use these fancy frameworks to cut back on the jQuery spaghetti that complex applications
# are otherwise generally comprised of.

# Place all the behaviors and hooks related to the config/general area here.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# -------------------
# --- Datatables Functions ---
# -------------------

@custom_fields_dt_init = ->
  aoColumnDefs = [
    { "aTargets": [1], "mRender": dt_fix_html_filtering },
    { "aTargets": [3], "bSortable": false, "bSearchable": false }
  ]
  datatable_init('#datatable-custom-fields', aoColumnDefs)
  
  
# -------------------
# --- Custom Field AJAX Functions ---
# -------------------

# return the custom field options that have been added/updated for this custom field as an object with a single JSON-serialized field:
#   cfo_data_json: a JSON-serialized array of objects (in document order which represents the order the user wants these options to be
#                  saved) with 'id' and 'name' keys representing the ID of the existing CFO (or 'NEW' if it is a new option) and its
#                  name, respectively.
added_custom_field_options = ->
  # get the list of custom field options in document order (could be a mix of existing and new cfo entries)
  cfo_divs =  $('div#custom-field-options div[id^=custom-field-option-], div#custom-field-options div.new-cfo')
  cfo_data = []
  cfo_divs.each ->
    cfo_data.push
      id: if $(this).hasClass('new-cfo') then 'NEW' else $(this).attr('id').split('-').pop()
      name: $(this).find('input').val()
    
  # return the object with JSON-serialized cfo array
  {cfo_data_json: JSON.stringify(cfo_data)}


# return the request_type_ids of the selected request types from the custom field request types div
added_request_types = ->
  # get the currently listed request type ids for this custom field
  request_types = $('div#custom-field-request-types div[id^=custom-field-request-type-]')
  request_type_ids = []
  request_types.each ->
    request_type_ids.push $(this).attr('id').split('-').pop()
  {request_type_ids: request_type_ids}


# return an object containing custom field modal values to be used as parameters for ajax calls for custom fields
custom_field_params = ->
  params =
    custom_field:
      name: $('#custom_field_name').val()
      field_type: $('#custom_field_field_type').val()
  $.extend(params, added_custom_field_options())
  $.extend(params, added_request_types())
  

# success action for AJAX custom field calls (op: the operation performed (optional))
custom_field_save_success = ajax_save_success {modal: 'modal-custom-field', script: '/config/general/custom_fields.js'}
  

# return a fail function for after a custom field fails to create or update, which sets the save click function back to the specified callback
custom_field_save_fail = ajax_save_fail
  save_button: 'custom-field-modal-save'
  error_div:   'custom-field-errors'
  error_info: [{field: 'name', prefix: 'Name'}, {field: 'field_type', prefix: 'Field Type'}, {field: 'base', prefix: ''},
               {field: 'custom_field_options', prefix: 'Custom Field Options'}]


# -------------------
# --- Document Ready ---
# -------------------
$(document).ready ->

  # -------------------
  # --- Email Settings ---
  # -------------------

  # set the URL to update when this tab is selected
  tab_update_url('#tab-email','/config/general/email')
  
      
  # email settings save button
  $('#email-save').click ->
    # clear out the errors area so it is reset for future transactions
    clear_errors()
    
    # get the settings from the form
    email_params = 
      mailer:
        default_from: $('#mailer_default_from').val()
        send_emails: if $('#mailer_send_emails').prop('checked') then '1' else '0'
      
    # ajax PUT request to update the email settings
    target = $(this).attr('data-powder-target')
    show_ajax_loader()
    $.ajax(
      url: "#{target}.json"
      type: 'PUT'
      data: email_params
      dataType: 'json'
    )
    .done(->
      js_notify('success', 'Email settings successfully updated.')
    )
    .fail((jqXHR) ->
      show_errors
        header: 'There were errors while trying to update the email settings!'
        errors: $.parseJSON(jqXHR.responseText)
    )
    .always(ajax_save_always)
    
  
  # -------------------
  # --- Custom Fields ---
  # -------------------
  
  # set the URL to update when this tab is selected
  tab_update_url('#tab-custom','/config/general/custom_fields')
    
        
  # field type select on click, hide/show the custom field options area as appropriate
  $('#custom_field_field_type').on 'change', ->
    types_requiring_options = $('#option-field-type-keys').text().split(',')
    if $.inArray($(this).val(), types_requiring_options) > -1
      $('#custom-field-options-container').removeClass('hidden')
    else
      $('#custom-field-options-container').addClass('hidden')
        
    
  # print out the html for a custom field option row and give the input focus
  # (the template contents are defined by print_removal_list_text_field() in configuration_helper.rb)
  print_custom_field_option_row = (name, id=null, after=null) ->
    new_row = $('#custom-field-option-template').clone()
    the_input = new_row.find('input') # should only be one in the template
    the_input_div = the_input.parent()
    
    if id
      the_input_div.attr('id', the_input_div.attr('id').replace('_id_', id))
    else
      # if an id was not specified, this is a new row, and we need to remove the template ID so we don't have possibly multiple entries
      # with the same template ID, and we also need to indicate this is a new entry via the 'new-cfo' class (see added_custom_field_options() above)
      the_input_div.removeAttr('id')
      the_input_div.addClass('new-cfo')
      
    the_input.attr('value', name) # for some reason doing the_input.val(name) was not working
      
    if after
      after.after(new_row.html())
      after.next().find('input').focus()
    else
      $('#custom-field-options').append(new_row.html()).find('input').focus()
    
    
  # update the custom field options list with the specified data (array of  objects with 'id' and 'name' keys)
  show_custom_field_options = (options_data) ->
    $('#custom-field-options').empty()
    if options_data.length
      $.each options_data, (index, option_data) ->
        print_custom_field_option_row(option_data.name, option_data.id)
        
    
  # print out the html for a row for a custom_field request type entry
  # (the template contents are defined by print_removal_list_div() in configuration_helper.rb)
  print_custom_field_request_type_row = (full_name, id) ->
    $('#custom-field-request-types').append($('#custom-field-request-type-template').html().replace('_id_',id))
    $("#custom-field-request-type-#{id}").text(full_name)
    
    
  # update the custom field request types list with the specified request types data (array of objects with 'full_name' and 'id' keys)
  show_custom_field_request_types = (request_types_data) ->
    $('#custom-field-request-types').empty()
    if request_types_data.length
      $.each request_types_data, (index, rq_data) ->
        print_custom_field_request_type_row(rq_data.full_name, rq_data.id)

      
  # the custom field edit link click (use 'on' so this event handler stays registered even as dataTables adds and removes
  # actual rows from the DOM)
  $('#tab-custom').on 'click', '#datatable-custom-fields tr[id^=custom_field]>td:nth-child(2)>a', (e) ->
    # we do not want the link to actually reload a page
    e.preventDefault()
    
    # compute the target custom field
    target_custom_field = $(this).attr('href')
    
    # grab the JSON for target custom field
    $.getJSON(target_custom_field, (custom_field_data) ->
      # set modal title
      $('#modal-custom-field-label').text('Edit Custom Field')
      
      # set modal form fields with values from retrieved custom field
      $('#custom_field_name').val(custom_field_data.name)
      $('#custom_field_field_type').val(custom_field_data.field_type).trigger('liszt:updated').trigger('change')
      show_custom_field_options(custom_field_data.options_data)
      $('#add-request-type-select').val('').trigger('liszt:updated')
      show_custom_field_request_types(custom_field_data.request_types_data)
      $('#custom-field-errors').empty()
      $('#custom-field-errors').addClass('hidden')
      
      # give the 'Save changes' button the proper click behavior
      $('#custom-field-modal-save').one('click.powder', ajax_put({
        url: target_custom_field,
        params: custom_field_params,
        success: custom_field_save_success,
        fail: custom_field_save_fail
      }))
      
      # show the modal
      $('#modal-custom-field').modal('show')
    )
    .fail(->
      alert "Failed to retrieve custom field ##{target_custom_field.split('/').pop()}")
  
  
  # init custom fields datatable
  custom_fields_dt_init()
    
  
  # the new custom field button
  $('#new-custom-field-modal-button').click ->
    # reset header label
    $('#modal-custom-field-label').text('Create New Custom Field')
    
    # reset form fields
    $('#custom_field_name').val('')
    $('#custom_field_field_type').val('').trigger('liszt:updated').trigger('change')
    show_custom_field_options([])
    $('#add-request-type-select').val('').trigger('liszt:updated')
    show_custom_field_request_types([])
    $('#custom-field-errors').empty()
    $('#custom-field-errors').addClass('hidden')
    
    # set the save changes button action
    $('#custom-field-modal-save').one('click.powder', ajax_post({
      url: '/config/general/custom_fields.json',
      params: custom_field_params,
      success: custom_field_save_success,
      fail: custom_field_save_fail
    }))
    
  
  # custom field modal on-shown focus on name field
  $('#modal-custom-field').on 'shown', ->
    $('#custom_field_name').focus()
    
  
  # add custom field option button click: add a new empty field to the end of the list
  $('#add-custom-field-option-button').click (e) ->
    e.preventDefault()
    print_custom_field_option_row('')
    
    
  # remove custom field option button click: remove the corresponding custom field entry from the list
  $('#custom-field-options').on 'click', 'i.remover', ->
    $(this).closest('div.row-fluid').remove()
    
    
  # custom field option text field enter key: insert new row after this row
  $('#custom-field-options').on 'keydown', 'input.custom-field-option', (e) ->
    if e.which == 13
      print_custom_field_option_row('', null, $(this).closest('div.row-fluid'))
    
    
  # custom field option move up button click: swap this entry with the one above it in the DOM (this DOM is defined in 
  # helpers/configuration_helper.rb print_removal_list_text_field() )
  $('#custom-field-options').on 'click', 'a.move-up', (e) ->
    e.preventDefault()
    this_entry = $(this).closest('div.row-fluid')
    
    # only do something if there is a previous entry
    prev_entry = this_entry.prev()
    if prev_entry.length
      this_entry.after(prev_entry)
      
      
  # custom field option move down button click: swap this entry with the one below it in the DOM (this DOM is defined in 
  # helpers/configuration_helper.rb print_removal_list_text_field() )
  $('#custom-field-options').on 'click', 'a.move-down', (e) ->
    e.preventDefault()
    this_entry = $(this).closest('div.row-fluid')
    
    # only do something if there is a following entry
    next_entry = this_entry.next()
    if next_entry.length
      this_entry.before(next_entry)
  
    
  # add request type button click: add the currently selected request type to the list of request types for this custom field
  $('#add-request-type-button').click (e) ->
    e.preventDefault()
    rq_select = $('#add-request-type-select')
    id = rq_select.val()
    if id && !$("#custom-field-request-type-#{id}").length
      full_name = rq_select.find("option[value=#{id}]").text()
      print_custom_field_request_type_row(full_name, id)
      
      
  # remove custom field request type button click: remove the corresponding request type entry from the list
  $('#custom-field-request-types').on 'click', 'i.remover', ->
    $(this).closest('div.row-fluid').remove()

      
  # -------------------
  # --- final initializations ---
  # -------------------
  
  # open a modal now on document ready if necessary (the appropriate button is given this class by the rails controller/template)
  $('.click-on-load').click()
  
  
  # activate chosen for datatables
  dt_chosen()
  
    
  # capture enter key for various forms (email save and other modal forms)
  form_capture_enter 'form[action^=\\/config\\/general]', '#email-save'
  form_capture_enter 'form[action^=\\/config\\/general\\/]', 'button.form-modal-saver', {except: 'div#custom-field-options input.custom-field-option'}
