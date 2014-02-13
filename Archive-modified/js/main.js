(function(){

    var elems, prv,
        demoFormVisible = false,
        special = jQuery.event.special,
        uid1 = 'D' + (+new Date()),
        uid2 = 'D' + (+new Date() + 1),
        autoScroll = true,
        topMargin = 88, // header height without bottom border
        scrollDuration = 400,
        sectionLineColor = {
           "section-1": "#007dab",
           "section-2": "#a0a1a4",
           "section-3": "#ff9c00",
           "section-4": "#a0a1a4",
           "section-5": "#ed1c24",
           "section-6": "#a0a1a4",
           "section-7": "#a0a1a4",
           "section-8": "#a0a1a4",
           "section-9": "#007dab"
        }
    ;

    prv = {

        init: function() {
            prv.init = function(){};
            elems = {
                mailingText: $("#mailingEmail"),
                mailingBtn: $("#mailingBtn"),
                requestDemoBtn: $(".mcrd-request-btn"),
                requestDemoForm: $(".mcrd-request-box"),
                requestDemoFieldName: $(".mcrd-request-box .box-content input[name='name']"),
                requestDemoFieldEmail: $(".mcrd-request-box .box-content input[name='email']"),
                requestDemoFieldPhone: $(".mcrd-request-box .box-content input[name='phone']"),
                requestDemoFieldCity: $(".mcrd-request-box .box-content input[name='city']"),
                requestDemoSubmitBtn: $(".mcrd-request-box .request-submit-btn"),
                $sections: $("[id].section"),
                $header: $(".mcrd-header"),
                $homeCorner: $(".mcrd-home-corner"),
                $homeCornerLink: $(".mcrd-home-corner>a")
            };

            // scrolling to section after scroll event
            $(window).on("scrollstop", prv.scrollSection);

            // change header bottom line
            $(window).on("scroll", prv.changeHeaderBottomLine);

            // display or hide home corner
            $(window).on("scroll", prv.showHideHomeCorner);

            // scroll to top section
            elems.$homeCornerLink.on("click", function(event){
                prv.scrollToHash("section-1");
                event.stopPropagation();
            });

            // add email to mailing list
            elems.mailingBtn.on("click", function(event){
                prv.addToMailingList(elems.mailingText.val());
                event.stopPropagation();
            });

            // opens request demo form
            elems.requestDemoBtn.on("click", function(event){
                demoFormVisible = !demoFormVisible;
                if (demoFormVisible) {
                    elems.requestDemoForm.show();
                    elems.requestDemoFieldName.focus();
                    $(window).on("scroll", prv.hideRequestDemoForm);
                } else {
                    elems.requestDemoForm.hide();
                }
                event.stopPropagation();
            });

            // hides request demo form if user clicks outside of it
            $(document).on("click", function(event){
                var elem = $(event.target).parentsUntil(elems.requestDemoForm).last()[0];
                if (elem && elem.tagName === "HTML") {
                    prv.hideRequestDemoForm();
                }
            });

            // submits request demo form
            elems.requestDemoSubmitBtn.on("click", function(event){
                prv.validateDemoForm("email", elems.requestDemoFieldEmail.val());
                if (elems.requestDemoForm.find(".input-invalid").length > 0) {
                    return;
                }
                prv.requestDemo({
                    name: elems.requestDemoFieldName.val(),
                    email: elems.requestDemoFieldEmail.val(),
                    phone: elems.requestDemoFieldPhone.val(),
                    city: elems.requestDemoFieldCity.val()
                });
                event.stopPropagation();
            });

            elems.requestDemoSubmitBtn.on("blur", function(){
                elems.requestDemoFieldName.focus();
            });

            // validates request demo field on change
            elems.requestDemoForm.find("input[type='text']").on("change", function(event){
                prv.validateDemoForm(event.target.name, event.target.value);
                event.stopPropagation();
            });
        },

        validateDemoForm: (function(){
            var emailPattern = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/i,
                phonePattern = /^[\+]{0,1}[0-9\- ]*$/,
                cityPatern = /^[A-Za-z ]*$/;
            return function(field, value) {
                var  v = true;
                switch(field) {
                    case "email":
                        v = emailPattern.test(value);
                        break;
                    case "name":
                        break;
                    case "phone":
                        v =phonePattern.test(value);
                        break;
                    case "city":
                        v = cityPatern.test(value);
                        break;
                    default:
                        v = false;
                }
                field = field.charAt(0).toUpperCase()+field.slice(1);
                elems["requestDemoField"+field].parent()[v ? "removeClass" : "addClass"]("input-invalid");
                return v;
            };
        })(),

        addToMailingList: function(email) {
            $.post("/api/newsletter",
                { email: email },
                function(){
                    elems.mailingText.val("");
                }, "json");
        },

        requestDemo: function(data) {
            $.post("/api/demo",
                data,
                function(){
                    prv.hideRequestDemoForm();
                    elems.requestDemoFieldName.val("");
                    elems.requestDemoFieldEmail.val("");
                    elems.requestDemoFieldPhone.val("");
                    elems.requestDemoFieldCity.val("");
                }, "json");
        },

        hideRequestDemoForm: function() {
            elems.requestDemoForm.hide();
            demoFormVisible = false;
            $(window).off("scroll", prv.hideRequestDemoForm);
        },

        scrollSection: function(event) {
            // user scrolling is stopped, now should scroll to hash by js
            autoScroll = true;
            // need to be calculated where to scroll
            //prv.scrollToHash("section-2");
        },

        changeHeaderBottomLine: function() {
            var sectionId = prv.getCurrentSection();
                lineColor = sectionLineColor[sectionId];
            elems.$header.css({"border-bottom": "5px solid " + lineColor});
        },

        showHideHomeCorner: function() {
            var sectionId = prv.getCurrentSection();

            if (sectionId !== "section-1") {
                elems.$homeCorner.fadeIn("fast");
            } else {
                elems.$homeCorner.fadeOut("fast");
            }
        },

        getCurrentSection: function() {
            var i, sectionScrollTop, section, sectionHeight, lineColor, sectionId,
                scrollPosition = $(window).scrollTop(),
                sectionsCount = elems.$sections.length;

            for (i=0; i < sectionsCount; i++) {
                section = elems.$sections[i];
                sectionHeight = section.clientHeight;
                sectionScrollTop = $(section).offset().top + sectionHeight - scrollPosition - topMargin;

                if (sectionScrollTop > 0) {
                    sectionId = $(section).attr("id");
                    break;
                }
            }
            return sectionId;
        },

        cancelAutoScroll: function() {
            //autoScroll = false;
        },

        scrollToHash: function(hash) {

            var element, offset,
                hash = hash || null;

            if (hash === null) {
                return false
            }

            $element = $('#' + hash);
            offset = $element.offset();

            if ($element && offset) {
                $(window).scrollAnimate({
                    scrollTop: offset.top - topMargin
                }, scrollDuration );
            }

        }
    };

    special.scrollstart = {
        setup: function() {
            var timer,
                handler =  function(evt) {
                    var _self = this,
                        _args = arguments;

                    if (timer) {
                        clearTimeout(timer);
                    } else {
                        evt.type = 'scrollstart';
                        $.event.dispatch.apply(_self, _args);
                    }

                    timer = setTimeout( function(){
                        timer = null;
                    }, special.scrollstop.latency);
                };
            $(this).bind('scroll', handler).data(uid1, handler);
        },

        teardown: function(){
            $(this).unbind( 'scroll', $(this).data(uid1) );
        }
    };

    special.scrollstop = {
        latency: 600,
        setup: function() {
            var timer,
                    handler = function(evt) {
                    var _self = this,
                        _args = arguments;

                    if (timer) {
                        clearTimeout(timer);
                    }

                    timer = setTimeout( function(){
                        timer = null;
                        evt.type = 'scrollstop';
                        $.event.dispatch.apply(_self, _args);
                    }, special.scrollstop.latency);
                };
            $(this).bind('scroll', handler).data(uid2, handler);
        },

        teardown: function() {
            $(this).unbind( 'scroll', $(this).data(uid2) );
        }
    };

    // Polyfill for event listeners
    var addEventListener = null;
    var removeEventListener = null;

    if ('addEventListener' in window) {
        addEventListener = function (element, type, listener) {
            element.addEventListener(type, listener, false); // always bubbling
        };
        removeEventListener = function (element, type, listener) {
            element.removeEventListener(type, listener, false); // always bubbling
        };
    } else if ('attachEvent' in window) {
        addEventListener = function (element, type, listener) {
            element.attachEvent('on' + type, listener);
        };
        removeEventListener = function (element, type, listener) {
            element.detachEvent('on' + type, listener);
        };
    } else {
        addEventListener = function (element, type, listener) {
            element['on' + type] = listener;
        };
        removeEventListener = function (element, type, listener) {
            element['on' + type] = null;
        };
    }

    // Polyfill requestAnimationFrame
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];

    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame =
        window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame) {
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() {
              callback(currTime + timeToCall);
            }, timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };
    }

    if (!window.cancelAnimationFrame) {
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
    }

    /** Custom animate function to animate scroll position of element.
    * @param {object} Object which contains end scroll position.
    * @param {number} Time in milliseconds.
    **/
    $.fn.scrollAnimate = function(data,duration) {
        var data = data || {},
            currentScrollTop = this.scrollTop(),
            scrollTo = data.scrollTop || 0,
            frameDuration, step,
            diff = currentScrollTop - scrollTo,
            duration = duration || 400,
            that = this[0],
            start = +new Date(),
            prev = start,
            speed = diff / duration,
            sum = 0,
            result, excess, now, absSum, absDiff;
        var loop = function () {
            if (autoScroll === false) {
                return false;
            }
            now = +new Date();
            frameDuration = now - prev;
            step = frameDuration * speed;
            prev = now;
            sum+=step;
            // Checking last frame
            absSum = Math.abs(sum);
            absDiff = Math.abs(diff);

            if (absSum > absDiff) {
                excess = absSum - absDiff;
                if (diff > 0) {
                    sum = sum - excess;
                } else {
                    sum = sum + excess;
                }
            }
            // Scrolling element here
            that.scrollTo(0, currentScrollTop - sum);

            if (now - start < duration) {
                requestAnimationFrame(loop);
            }
      };
      loop();
    };
    $(prv.init);
})();
