//jQuery.ajaxSetup({
//  'beforeSend': function(xhr) { xhr.setRequestHeader("Accept", "text/html"); }
//});

$(document).ready(function(){
  restrict_keyword_name();
});

function restrict_keyword_name(){
  $('input.keyword_name_field').keypress(function(e){
  	c = String.fromCharCode(e.which);
	if(e.which == 8 || e.which == 0 || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9'))
		return true;
	else
		return false;
  });
}


function make_jgrowl() {
	var t = $(this),
		options = { theme: t[0].className };

	if (t.hasClass('sticky')) options.sticky = true;
	else options.life = 5 * 1000;
	
	$.jGrowl( t.text(), options);
	t.remove();
}

$(document).ready(function(){
  if(jQuery.validator) {
    jQuery.validator.addMethod("phoneUS", function(phone_number, element) {
      phone_number = phone_number.replace(/\s+/g, ""); 
      return this.optional(element) || phone_number.length > 9 && phone_number.match(/^[+]?1?[-.()\s]*([02-9]\d{2})\D*(\d{3})\D*(\d{4})\D*$/);
     }, "Please specify a valid phone number.");
    
    jQuery.validator.addMethod("alpha", function(field, element) {
      return this.optional(element) || field.match(/^[\w]+$/);
     }, "Alphanumeric characters only.");
    
    jQuery.validator.addMethod("fullname", function(field, element) {
      return this.optional(element) || field.match(/^[\w]+ [\w]+/);
     }, "Use your full name.");

    $('#new_account').validate({
      rules: {
        'account[name]': {
          minlength: 3,
          maxlength: 100,
    fullname: true
        },
        'account[username]': {
          minlength: 3,
          maxlength: 20,
          alpha: true,
          remote: '/account/username_available'
        },
        'account[password]': {
          minlength: 6,
          maxlength: 40
        },
        'account[number]': {
          phoneUS: true
        },
        'account[email]': {
          email: true
        }
      },
      messages: {
        'account[name]': {
          minlength: 'Name is too short.',
          maxlength: 'Name is too long.'
        },
        'account[username]': {
          minlength: 'Username is too short.',
          maxlength: 'Username is too long.',
          remote: 'This username is in use.'
        },
        'account[password]': {
          minlength: 'Password is too short.',
          maxlength: 'Password is too long.'
        },
        'account[email]': {
          remote: 'This e-mail is invalid or in use.'
        }
      },
      errorPlacement: function(error, element){
        error.appendTo($('.signupError', element.parent()));
      }
    });

    $('#account_plan').validate({
      rules: {
        'credit_card[zip]': {
          minlength: 5,
          maxlength: 5,
          number: true
        }
      },
      errorPlacement: function(error, element){
        error.appendTo($('.signupError', element.parent()));
      }
    });

    $('#contact_form').validate({
      rules: {
        'phone': {
          phoneUS: true
        },
        'email': {
          email: true
        }
      },
      errorPlacement: function(error, element){
        error.appendTo($('.signupError', element.parent()));
      }
    });
  }
});
