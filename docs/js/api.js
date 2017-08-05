var api = function() {
    var apiUrl = 'https://progetto-db.herokuapp.com'
    //var apiUrl = 'http://localhost:8000'
    var email = null
    var nickname = null
    var password = null
    var logged = null

    var ifLogged = function(callback) {
        if (logged == true) {
           callback() 
        } else if (logged == null) {
            get({
                url: 'user',
                statusCode: {
                    200: callback
                }
            })
        }
    }

    var ifNotLogged = function(callback) {
        if (logged != null && logged == false) {
           callback() 
        } else if (logged == null) {
            get({
                url: 'user',
                statusCode: {
                    401: callback
                }
            })
        }
    }

    var init = function() {
        var localEmail = localStorage.getItem('email')
        var localPassword = localStorage.getItem('password')
        console.info('local: %s:%s', localEmail, localPassword)
        if (localEmail && localPassword) {
            login(localEmail, localPassword)
        }
    }

    var login = function (newEmail, newPassword) {
        email = newEmail
        password = newPassword
        ifLogged(function(data) {
                console.info('logged in')
                nickname = data.nickname
                localStorage.setItem('email', email)
                localStorage.setItem('password', password)
                logged = true
        })
    }

    var ajax = function(options) {
        options.url = apiUrl + '/' + options.url
        options.beforeSend = function(xhr) {
            xhr.setRequestHeader(
                "Authorization",
                "Basic " + btoa(email + ":" + password)
            )
        }
        console.info('ajax options: %o', options)
        $.ajax(options)
    }

    var get = function(options) {
        options.method = 'GET'
        ajax(options)
    }

    var post = function(options) {
        options.method = 'POST'
        ajax(options)
    }

    var logout = function() {
        localStorage.removeItem('email')
        localStorage.removeItem('password')
        logged = false
        nickname = null
    }

    return {
        init: init,
        name: 'api',
        login: login,
        logout: logout,
        email: function() { return email },
        nickname: function() { return nickname },
        get: get,
        post: post,
        ifLogged: ifLogged,
        ifNotLogged: ifNotLogged
    }
}()

$(api.init)

