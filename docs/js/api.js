var api = function() {
    var apiUrl = function() {
        if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') {
            return 'http://localhost:8000';
        } else {
            return 'https://progetto-db.herokuapp.com';
        }
    }();
    var email = null;
    var nickname = null;
    var password = null;
    var logged = null;

    var ifHasCharacter = function(onYes, onNo) {
        ifLogged(function() {
            api.get({
                url: 'dices',
                statusCode: {
                    200: onNo,
                    404: onYes
                }
            });
        });
    };

    var ifLogged = function(callback) {
        if (logged == true) {
           callback();
        } else if (logged == null) {
            setTimeout(function() {ifLogged(callback), 100});
        }
    };

    var ifNotLogged = function(callback) {
        if (logged != null && logged == false) {
           callback();
        } else if (logged == null) {
            setTimeout(function() {ifNotLogged(callback), 100});
        }
    };

    var init = function() {
        var localEmail = localStorage.getItem('email');
        var localPassword = localStorage.getItem('password');
        if (localEmail && localPassword) {
            login(localEmail, localPassword, function(){ }, function(){ });
        } else {
            logout();
        }
    };

    var login = function (newEmail, newPassword, success, deny) {
        email = newEmail;
        password = newPassword;
        get({
            url: 'user',
            statusCode: {
                200: function(data) {
                    console.info('logged in');
                    nickname = data.nickname;
                    localStorage.setItem('email', email);
                    localStorage.setItem('password', password);
                    logged = true;
                    success();
                },
                401: function() {
                    logout();
                    deny();
                }
            }
        });
    };

    var ajax = function(options) {
        options.url = apiUrl + '/' + options.url;
        options.beforeSend = function(xhr) {
            if(email && password) {
                xhr.setRequestHeader(
                    "Authorization",
                    "Basic " + btoa(email + ":" + password)
                );
            }
        };
        console.info('ajax options: %o', options);
        $.ajax(options);
    };

    var get = function(options) {
        options.method = 'GET';
        ajax(options);
    };

    var post = function(options) {
        options.method = 'POST';
        ajax(options);
    };

    var logout = function() {
        localStorage.removeItem('email');
        localStorage.removeItem('password');
        logged = false;
        nickname = null;
    };

    return {
        init: init,
        name: 'api',
        login: login,
        logout: logout,
        email: function() { return email; },
        nickname: function() { return nickname; },
        get: get,
        post: post,
        ifLogged: ifLogged,
        ifNotLogged: ifNotLogged,
        ifHasCharacter: ifHasCharacter
    };
}();

$(api.init);

