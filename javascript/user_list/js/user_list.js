// For a 'real' project with more time, I would choose likely choose to use a client-side MVC framework like Backbone.js, which lends
// itself nicely to single-page data-backed apps (in this case our data is our user list). But for simplicity and to save time I'll just
// manually handle the DOM, events, etc

// @NOTE also to save some time I'm not worrying too much about polluting the global scope with this; normally I would use either an
// anonymous function wrapper, an explicit namespace, or some other libary-provided mechanism, or whatever is recommended for the current
// project

// @NOTE I developed/tested this with the latest chrome browser

// @NOTE some time was spent learning the Citrix Web Libary, and I thought that the library would provide data table sorting out of the 
// box, but either it doesn't or I missed it. So I didn't leave myself time to implement the column sorting myself, I left  that to the end
// because I thought there would be library triggers.

/**
 * Show the specified notification with the specified string content
 * 
 * @param msgid: (string) the ID of the message template to show
 * @param content: (string) the content to be inserted into the span.template within the template
 */ 
var notify = function(msgid, content){
  var msg_template = $("#" + msgid);
  msg_template.find("span.template").text(content);
  msg_template.animateMessage("sheet");
};

/**
 * Add a user to the user list
 */
var add_user = function(e){
  e.preventDefault();

  // clear error area each time user tries again
  $('#errs').addClass('hide').find('p').remove();
  
  var new_first = $('#firstName').val();
  var new_last = $('#lastName').val();
  
  // check that both first name and last name have been entered
  // @NOTE the citrix online implementation of the placeholders causes a problem in that jQuery will think an empty 
  // input field showing a placeholder actually has a value of that placeholder text...I don't have time to figure out
  // the best way to workaround that limitation, so for now I am using an @HACK of checking for 'First Name' and 'Last Name'
  // special values, in addition to the fields being empty.
  var errors = false
  var error_msgs = []
  if (new_first == '' || new_first == 'First Name'){
    errors = true
    error_msgs.push('You must enter a first name!');
  }
  if (new_last == '' || new_last == 'Last Name'){
    errors = true
    error_msgs.push('You must enter a last name!');
  }
  if (errors){
    $.each(error_msgs, function(index, val){
      $('#errs div.form-row-column').append("<p class='err'>" + val + '</p>');
    });
    $('#errs').removeClass('hide');
    return false;
  }
  
  // add the user
  var new_user_row = $($('#user-row-template').html());
  new_user_row.find('span.fn').text(new_first);
  new_user_row.find('span.ln').text(new_last);
  $('#users-table ul.table-data-header').after(new_user_row);
  // @HACK this was not playing nice, didn't have too much time to spend on it; I could have tried for transitioning with the top position, etc
  // if I had more time
  setTimeout(function(){
    $('#users-table ul.table-data-row').css('height', '3em');
  }, 10)
  
  
  // update available licences
  $('#available-licenses').trigger('app:updated');
  
  // notify user
  notify('added-user-notify', new_first + ' ' + new_last);
  
  // clear the name fields, put focus back to first name for UX goodness
  $('#firstName').focus().val('');
  $('#lastName').val('');
};

/**
 * Remove the specified row from the table
 * 
 * @param row: jQuery object pointing to the row to be removed
 */
var remove_row = function(row){
  row.on('transitionend', function(){
    row.remove();
    $('#available-licenses').trigger('app:updated');
  });
  row.css('height', '0');
};

/**
 * Document ready...
 */
$(function(){
  // support the text input placeholders per the citrix online docs
  $("input[type='text']").clearField();
  
  // 'Add User' click
  $('#add-users').on('click', add_user);
  
  // hit enter on last name field
  $('#lastName').on('keydown', function(e){
    if (e.which == 13){
      add_user(e);
    }
  });
  
  // Available licenses, always show the count of users in the table; check for hiding add user form
  $('#available-licenses').on('app:updated', function(e){
    var count = $('#users-table ul.table-data-row').length;
    
    // update count
    $(this).text(count);
    
    // hide the user form if users == 10
    if (count == 10){
      $('form').addClass('hide');
    } else{
      $('form').removeClass('hide');
    }
  });
  $('#available-licenses').trigger('app:updated');
  
  
  // remove user ('X') button
  $('#users-table').on('click', 'a.remove-user', function(e){
    e.stopPropagation();
    var row = $(this).closest('ul.table-data-row'); 
    remove_row(row);
  });
  
  // clicking on user row opens modal
  $('#modal-user').modalWindow();
  $('#users-table').on('click', 'ul.table-data-row', function(e){
    var user_name = $(this).find('span.fn').text() + ' ' + $(this).find('span.ln').text()
    var pos = $(this).prevAll('ul.table-data-row').length
    $('#modal-user span.tmpl-name').text(user_name);
    $('#modal-user').data('pos', pos);
    $('#modal-user').dialog('open');
  })
  
  // user modal remove button; remove the row specified by data-nth 
  $('a#remove-user-modal').on('click', function(e){
    var row = $('#users-table ul.table-data-row').eq($('#modal-user').data('pos'));
    remove_row(row);
    $('#modal-user').dialog('close');
  })
});