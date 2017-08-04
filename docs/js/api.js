var api = function() {
    var apiUrl = 'https://progetto-db.herokuapp.com'
    var email = null
    var nickname = null
    var password = null
    var logged = false

    var init = function() {
        var sessionEmail = sessionStorage.getItem('email')
        var sessionPassword = sessionStorage.getItem('password')
        if (sessionEmail && sessionPassword) {
            login(sessionEmail, sessionPassword)
        }
    }

    var ajax = function(method, endpoint, data, success, error) {
        $.ajax({
            method: method,
            url: apiUrl + '/' + endpoint,
            data: data,
            beforeSend: function(xhr) {
                if (logged) {
                    xhr.setRequestHeader(
                        "Authorization",
                        "Basic " + btoa(email + ":" + password)
                    )
                }
            },
            success: success,
            error: error
        })
    }

    var get = function(endpoint, data, success, error) {
        ajax('GET', endpoint, data, success, error)
    }

    var post = function(endpoint, data, success, error) {
        ajax('POST', endpoint, data, success, error)
    }

    var login = function(newEmail, newPassword) {
        email = newEmail
        password = newPassword
        logged = true
        get(
            '/user',
            null,
            function(data, textStatus, XHR) {
                if (XHR.status == 200) {
                    console.info('logged in')
                    nickname = data.nickname
                    sessionStorage.setItem('email', email)
                    sessionStorage.setItem('password', password)
                }
            },
            function(XHR, textStatus, errorThrown) {
                logout()
                console.info('logged out')
            }
        )
        return logged
    }

    var logout = function() {
        sessionStorage.removeItem('email')
        sessionStorage.removeItem('password')
        logged = false
        nickname = null
    }

    return {
        init: init,
        name: 'api',
        login: login,
        logout: logout,
        logged : function() { return logged },
        email: function() { return email },
        nickname: function() { return nickname },
        get: get,
        post: post
    }
}(); modules.push(api)

