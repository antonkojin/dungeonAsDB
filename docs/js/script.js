var modules = []

jQuery(function() {
    modules.forEach(function(module) {
        console.info('loading module: %o', module)
        module.init()
    })
})

modules.push(function() {
    var apiUrl = 'https://progetto-db.herokuapp.com'

    var init = function() {
        var form = $("#form-register") // TODO: fattorizzare
        form.submit(submit_handler)
    }

    var submit_handler = function(event) {
        console.info('event: %o', event)
        var form = $("#form-register") // TODO: fattorizzare
        var email = form.find('#mail').val()
        var nickname = form.find('#nickname').val()
        var password = form.find('#password').val()
        $.post({
            url: apiUrl + '/user',
            data: {
                email: email,
                nickname: nickname,
                password: password 
            },
            success: function(data, textStatus, jqXHR) {},
            error: function(jqXHR, textStatus, errorThrown) {}
        })
        event.preventDefault()
    }

    return {
        name: 'sample module',
        init: init
    }
}())
