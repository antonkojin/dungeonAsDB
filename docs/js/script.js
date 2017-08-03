var modules = []

$(function() {
    modules.forEach(function(module) {
        console.info('loading module: %s', module.name)
        module.init()
    })
})

var api = function() {
    var apiUrl = 'https://progetto-db.herokuapp.com'
    var email = null
    var nickname = null
    var password = null
    var logged = false

    var init = function() {}

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

modules.push(function() {
    var init = function() {
        var form = $("#signup-form") // TODO: fattorizzare
        form.submit(submit_handler)
    }

    var submit_handler = function(event) {
        console.info('event: %o', event)
        var form = $("#signup-form") // TODO: fattorizzare
        api.post(
            '/user',
            {
                email: form.find('#mail').val(),
                nickname: form.find('#nickname').val(),
                password: form.find('#password').val()
            },
            function(data, textStatus, XHR) {
                console.info('success data: %o status: %s', data, textStatus)
            },
            function(XHR, textStatus, errorThrown) {
                console.error('error error: %o status: %s', errorThrown, textStatus)
            }
        )
        event.preventDefault()
    }

    return {
        name: 'signup-form',
        init: init
    }
}())

modules.push(function() {
    var init = function() {
        var form = $("#login-form") // TODO: fattorizzare
        form.submit(submit_handler)
    }

    var submit_handler = function(event) {
        console.info('event: %o', event)
        var form = $("#login-form") // TODO: fattorizzare
        var email = form.find('#mail').val()
        var password = form.find('#password').val()
        var result = api.login(email, password)
        event.preventDefault()
    }

    return {
        name: 'login-form',
        init: init
    }
}())

modules.push(function() {
    var init = function() {
        var includes = $('[include]')
        $.each(includes, function(){
            var include = $(this)
            var file = include.attr('include')
            $.get({
                url: file,
                success: function(data) {
                    include.replaceWith(data)
                }
            })
        })
    }

    return {
        name: 'include',
        init: init
    }
}())
