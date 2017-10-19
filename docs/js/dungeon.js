var dungeon = function() {
    var init = function() {
        api.ifNotLogged(function () {
            redirect.redirect('login');
        });
        api.ifHasCharacter(function() {
            // do nothing
        }, function() {
            redirect.redirect('character');
        });
        $('#button-logout').click(logoutHandler);
        $('#button-end-dungeon').click(endDungeonHandler);
        $('#button-delete-user').click(deleteUserHandler);
    };

    var deleteUserHandler = function() {
        api.del({
            url: 'user'
        });
        api.logout();
        redirect.redirect('signup');
    };

    var endDungeonHandler = function() {
        api.del({
            url: 'dungeon'
        });
        redirect.redirect('dashboard');
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
