//= require application
//= require jquery.dataTables
//= require jquery.DOMWindow
//= require jquery.dropdownPlain
//= require jquery.watermark
//= require jquery-ui-1.8.22.custom.min.js

if ( $.browser.msie ) {
  $(document).ready(function() {  
    $('textarea[maxlength]').keyup(function(){  
      var limit = parseInt($(this).attr('maxlength'));  
      var text = $(this).val();  
      var chars = text.length;  

      if(chars > limit){  
        var new_text = text.substr(0, limit);  

        $(this).val(new_text);  
      }  
    });  
  });  
}

var gsmSpace = new Array();
gsmSpace[0x0040] = 1; // COMMERCIAL AT
gsmSpace[0x00A3] = 1; // POUND SIGN
gsmSpace[0x0024] = 1; // DOLLAR SIGN
gsmSpace[0x00A5] = 1; // YEN SIGN
gsmSpace[0x00E8] = 1; // LATIN SMALL LETTER E WITH GRAVE
gsmSpace[0x00E9] = 1; // LATIN SMALL LETTER E WITH ACUTE
gsmSpace[0x00F9] = 1; // LATIN SMALL LETTER U WITH GRAVE
gsmSpace[0x00EC] = 1; // LATIN SMALL LETTER I WITH GRAVE
gsmSpace[0x00F2] = 1; // LATIN SMALL LETTER O WITH GRAVE
gsmSpace[0x00E7] = 1; // LATIN SMALL LETTER C WITH CEDILLA
gsmSpace[0x00D8] = 1; // LATIN CAPITAL LETTER O WITH STROKE
gsmSpace[0x00F8] = 1; // LATIN SMALL LETTER O WITH STROKE
gsmSpace[0x00C5] = 1; // LATIN CAPITAL LETTER A WITH RING ABOVE
gsmSpace[0x00E5] = 1; // LATIN SMALL LETTER A WITH RING ABOVE
gsmSpace[0x005F] = 1; // LOW LINE
gsmSpace[0x005E] = 2; // CIRCUMFLEX ACCENT
gsmSpace[0x007B] = 2; // LEFT CURLY BRACKET
gsmSpace[0x007D] = 2; // RIGHT CURLY BRACKET
gsmSpace[0x005C] = 2; // REVERSE SOLIDUS
gsmSpace[0x005B] = 2; // LEFT SQUARE BRACKET
gsmSpace[0x007E] = 2; // TILDE
gsmSpace[0x005D] = 2; // RIGHT SQUARE BRACKET
gsmSpace[0x007C] = 2; // VERTICAL LINE
gsmSpace[0x00C6] = 1; // LATIN CAPITAL LETTER AE
gsmSpace[0x00E6] = 1; // LATIN SMALL LETTER AE
gsmSpace[0x00DF] = 1; // LATIN SMALL LETTER SHARP S (German)
gsmSpace[0x00C9] = 1; // LATIN CAPITAL LETTER E WITH ACUTE
gsmSpace[0x0020] = 1; // SPACE
gsmSpace[0x0021] = 1; // EXCLAMATION MARK
gsmSpace[0x0022] = 1; // QUOTATION MARK
gsmSpace[0x0023] = 1; // NUMBER SIGN
gsmSpace[0x00A4] = 1; // CURRENCY SIGN
gsmSpace[0x0025] = 1; // PERCENT SIGN
gsmSpace[0x0026] = 1; // AMPERSAND
gsmSpace[0x0027] = 1; // APOSTROPHE
gsmSpace[0x0040] = 1; // COMMERCIAL AT
gsmSpace[0x00A3] = 1; // POUND SIGN
gsmSpace[0x0024] = 1; // DOLLAR SIGN
gsmSpace[0x00A5] = 1; // YEN SIGN
gsmSpace[0x00E8] = 1; // LATIN SMALL LETTER E WITH GRAVE
gsmSpace[0x00E9] = 1; // LATIN SMALL LETTER E WITH ACUTE
gsmSpace[0x00F9] = 1; // LATIN SMALL LETTER U WITH GRAVE
gsmSpace[0x00EC] = 1; // LATIN SMALL LETTER I WITH GRAVE
gsmSpace[0x00F2] = 1; // LATIN SMALL LETTER O WITH GRAVE
gsmSpace[0x00E7] = 1; // LATIN SMALL LETTER C WITH CEDILLA
gsmSpace[0x00D8] = 1; // LATIN CAPITAL LETTER O WITH STROKE
gsmSpace[0x00F8] = 1; // LATIN SMALL LETTER O WITH STROKE
gsmSpace[0x00C5] = 1; // LATIN CAPITAL LETTER A WITH RING ABOVE
gsmSpace[0x00E5] = 1; // LATIN SMALL LETTER A WITH RING ABOVE
gsmSpace[0x005F] = 1; // LOW LINE
gsmSpace[0x005E] = 2; // CIRCUMFLEX ACCENT
gsmSpace[0x007B] = 2; // LEFT CURLY BRACKET
gsmSpace[0x007D] = 2; // RIGHT CURLY BRACKET
gsmSpace[0x005C] = 2; // REVERSE SOLIDUS
gsmSpace[0x005B] = 2; // LEFT SQUARE BRACKET
gsmSpace[0x007E] = 2; // TILDE
gsmSpace[0x005D] = 2; // RIGHT SQUARE BRACKET
gsmSpace[0x007C] = 2; // VERTICAL LINE
gsmSpace[0x00C6] = 1; // LATIN CAPITAL LETTER AE
gsmSpace[0x00E6] = 1; // LATIN SMALL LETTER AE
gsmSpace[0x00DF] = 1; // LATIN SMALL LETTER SHARP S (German)
gsmSpace[0x00C9] = 1; // LATIN CAPITAL LETTER E WITH ACUTE
gsmSpace[0x0020] = 1; // SPACE
gsmSpace[0x0021] = 1; // EXCLAMATION MARK
gsmSpace[0x0022] = 1; // QUOTATION MARK
gsmSpace[0x0023] = 1; // NUMBER SIGN
gsmSpace[0x00A4] = 1; // CURRENCY SIGN
gsmSpace[0x0025] = 1; // PERCENT SIGN
gsmSpace[0x0026] = 1; // AMPERSAND
gsmSpace[0x0027] = 1; // APOSTROPHE
gsmSpace[0x0028] = 1; // LEFT PARENTHESIS
gsmSpace[0x0029] = 1; // RIGHT PARENTHESIS
gsmSpace[0x002A] = 1; // ASTERISK
gsmSpace[0x002B] = 1; // PLUS SIGN
gsmSpace[0x002C] = 1; // COMMA
gsmSpace[0x002D] = 1; // HYPHEN-MINUS
gsmSpace[0x002E] = 1; // FULL STOP
gsmSpace[0x002F] = 1; // SOLIDUS
gsmSpace[0x0030] = 1; // DIGIT ZERO
gsmSpace[0x0031] = 1; // DIGIT ONE
gsmSpace[0x0032] = 1; // DIGIT TWO
gsmSpace[0x0033] = 1; // DIGIT THREE
gsmSpace[0x0034] = 1; // DIGIT FOUR
gsmSpace[0x0035] = 1; // DIGIT FIVE
gsmSpace[0x0036] = 1; // DIGIT SIX
gsmSpace[0x0037] = 1; // DIGIT SEVEN
gsmSpace[0x0038] = 1; // DIGIT EIGHT
gsmSpace[0x0039] = 1; // DIGIT NINE
gsmSpace[0x003A] = 1; // COLON
gsmSpace[0x003B] = 1; // SEMICOLON
gsmSpace[0x003C] = 1; // LESS-THAN SIGN
gsmSpace[0x003D] = 1; // EQUALS SIGN
gsmSpace[0x003E] = 1; // GREATER-THAN SIGN
gsmSpace[0x003F] = 1; // QUESTION MARK
gsmSpace[0x00A1] = 1; // INVERTED EXCLAMATION MARK
gsmSpace[0x0041] = 1; // LATIN CAPITAL LETTER A
gsmSpace[0x0042] = 1; // LATIN CAPITAL LETTER B
gsmSpace[0x0392] = 1; // GREEK CAPITAL LETTER BETA
gsmSpace[0x0043] = 1; // LATIN CAPITAL LETTER C
gsmSpace[0x0044] = 1; // LATIN CAPITAL LETTER D
gsmSpace[0x0045] = 1; // LATIN CAPITAL LETTER E
gsmSpace[0x0046] = 1; // LATIN CAPITAL LETTER F
gsmSpace[0x0047] = 1; // LATIN CAPITAL LETTER G
gsmSpace[0x0048] = 1; // LATIN CAPITAL LETTER H
gsmSpace[0x0049] = 1; // LATIN CAPITAL LETTER I
gsmSpace[0x004A] = 1; // LATIN CAPITAL LETTER J
gsmSpace[0x004B] = 1; // LATIN CAPITAL LETTER K
gsmSpace[0x004C] = 1; // LATIN CAPITAL LETTER L
gsmSpace[0x004D] = 1; // LATIN CAPITAL LETTER M
gsmSpace[0x004E] = 1; // LATIN CAPITAL LETTER N
gsmSpace[0x004F] = 1; // LATIN CAPITAL LETTER O
gsmSpace[0x0050] = 1; // LATIN CAPITAL LETTER P
gsmSpace[0x0051] = 1; // LATIN CAPITAL LETTER Q
gsmSpace[0x0052] = 1; // LATIN CAPITAL LETTER R
gsmSpace[0x0053] = 1; // LATIN CAPITAL LETTER S
gsmSpace[0x0054] = 1; // LATIN CAPITAL LETTER T
gsmSpace[0x0055] = 1; // LATIN CAPITAL LETTER U
gsmSpace[0x0056] = 1; // LATIN CAPITAL LETTER V
gsmSpace[0x0057] = 1; // LATIN CAPITAL LETTER W
gsmSpace[0x0058] = 1; // LATIN CAPITAL LETTER X
gsmSpace[0x0059] = 1; // LATIN CAPITAL LETTER Y
gsmSpace[0x005A] = 1; // LATIN CAPITAL LETTER Z
gsmSpace[0x00C4] = 1; // LATIN CAPITAL LETTER A WITH DIAERESIS
gsmSpace[0x00D6] = 1; // LATIN CAPITAL LETTER O WITH DIAERESIS
gsmSpace[0x00D1] = 1; // LATIN CAPITAL LETTER N WITH TILDE
gsmSpace[0x00DC] = 1; // LATIN CAPITAL LETTER U WITH DIAERESIS
gsmSpace[0x00A7] = 1; // SECTION SIGN
gsmSpace[0x00BF] = 1; // INVERTED QUESTION MARK
gsmSpace[0x0061] = 1; // LATIN SMALL LETTER A
gsmSpace[0x0062] = 1; // LATIN SMALL LETTER B
gsmSpace[0x0063] = 1; // LATIN SMALL LETTER C
gsmSpace[0x0064] = 1; // LATIN SMALL LETTER D
gsmSpace[0x0065] = 1; // LATIN SMALL LETTER E
gsmSpace[0x0066] = 1; // LATIN SMALL LETTER F
gsmSpace[0x0067] = 1; // LATIN SMALL LETTER G
gsmSpace[0x0068] = 1; // LATIN SMALL LETTER H
gsmSpace[0x0069] = 1; // LATIN SMALL LETTER I
gsmSpace[0x006A] = 1; // LATIN SMALL LETTER J
gsmSpace[0x006B] = 1; // LATIN SMALL LETTER K
gsmSpace[0x006C] = 1; // LATIN SMALL LETTER L
gsmSpace[0x006D] = 1; // LATIN SMALL LETTER M
gsmSpace[0x006E] = 1; // LATIN SMALL LETTER N
gsmSpace[0x006F] = 1; // LATIN SMALL LETTER O
gsmSpace[0x0070] = 1; // LATIN SMALL LETTER P
gsmSpace[0x0071] = 1; // LATIN SMALL LETTER Q
gsmSpace[0x0072] = 1; // LATIN SMALL LETTER R
gsmSpace[0x0073] = 1; // LATIN SMALL LETTER S
gsmSpace[0x0074] = 1; // LATIN SMALL LETTER T
gsmSpace[0x0075] = 1; // LATIN SMALL LETTER U
gsmSpace[0x0076] = 1; // LATIN SMALL LETTER V
gsmSpace[0x0077] = 1; // LATIN SMALL LETTER W
gsmSpace[0x0078] = 1; // LATIN SMALL LETTER X
gsmSpace[0x0079] = 1; // LATIN SMALL LETTER Y
gsmSpace[0x007A] = 1; // LATIN SMALL LETTER Z
gsmSpace[0x00E4] = 1; // LATIN SMALL LETTER A WITH DIAERESIS
gsmSpace[0x00F6] = 1; // LATIN SMALL LETTER O WITH DIAERESIS
gsmSpace[0x00F1] = 1; // LATIN SMALL LETTER N WITH TILDE
gsmSpace[0x00FC] = 1; // LATIN SMALL LETTER U WITH DIAERESIS
gsmSpace[0x00E0] = 1; // LATIN SMALL LETTER A WITH GRAVE
gsmSpace[0x000A] = 1; // NEWLINE

var gsmCharCount = function(str){
  sum = 0;
  for(var i = 0; i < str.length; i++){
    if(gsmSpace[str.charCodeAt(i)])
      sum += gsmSpace[str.charCodeAt(i)];
    else
      sum += 1;
  }
  return sum;
};
