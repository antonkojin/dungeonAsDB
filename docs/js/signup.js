var signup = function() {
    var init = function() {
        api.ifLogged(function() {
            redirect.redirect('dungeon')
        })
        $("#signup-form").submit(submit_handler)
    }

    var submit_handler = function(event) {
        var form = $("#signup-form")
        api.post({
            url: 'user',
            data: {
                email: form.find('#mail').val(),
                nickname: form.find('#nickname').val(),
                password: form.find('#password').val()
            },
            statusCode: {
                204: function() {
                   redirect.redirect('login') 
                },
                409: function() {
                   console.error('no conflict handler') 
                }
            }
        })
        event.preventDefault()
    }

    return {
        name: 'signup-form',
        init: init
    }
}()

$(signup.init)

