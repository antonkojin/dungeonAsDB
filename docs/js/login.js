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

