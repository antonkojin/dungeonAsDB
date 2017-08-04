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

