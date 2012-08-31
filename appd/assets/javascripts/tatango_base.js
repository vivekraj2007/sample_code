var Tatango = {};
// register a variable for use within the tatango namespace
// there is an optional scope
// You may want to use the +js_var+ helper found in javascript_helper.rb
Tatango.register_variable = function(key, value, scope) {
    if (scope) {
        if (typeof Tatango[scope] === "undefined") Tatango[scope] = {};
        Tatango[scope][key] = value;
    } else {
        Tatango[key] = value;
    }
};
Tatango.reg = Tatango.register_variable;

Tatango.flash = function(text, theme) {
	var options = { theme: theme, life: 5 * 1000 };
	$.jGrowl( text, options );
};

