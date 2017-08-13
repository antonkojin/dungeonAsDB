var dungeon = function() {
    var init = function() {
        api.ifNotLogged(function () {
            redirect.redirect('login');
        });
        $('#button-logout').click(logoutHandler);
    };

    var logoutHandler = function() {
        api.logout();
        redirect.redirect('login');
    };

    return {
        init: init,
        name: 'dungeon'
    };
}();

$(dungeon.init);
