var index = function() {
    var init = function() {
        api.ifLogged(function() {
            redirect.redirect('dungeon')
        })
        api.ifNotLogged(function() {
            redirect.redirect('login')
        })
    }

    return {
        init: init,
        name: 'index'
    }
}()

$(index.init)
