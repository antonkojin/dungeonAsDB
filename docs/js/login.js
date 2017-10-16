var loginForm = function() {
    var init = function() {
        console.log(location);
        api.ifLogged(function() {
            api.ifHasCharacter(function() {
                redirect.redirect('dungeon');
            }, function() {
                redirect.redirect('character');
            });
        });
        $("#login-form").submit(submit_handler);
    };

    var submit_handler = function(event) {
        var form = $("#login-form");
        var email = form.find('#mail').val();
        var password = form.find('#password').val();
        success = function() {
            api.ifHasCharacter(function() {
                redirect.redirect('dungeon');
            }, function() {
                redirect.redirect('character');
            });
        };
        deny = function() {
            console.warn("undefined callback on login fail!!!");
        };
        api.login(email, password, success, deny);
        event.preventDefault();
    };

    return {
        name: 'login-form',
        init: init
    };
}();

$(loginForm.init);
