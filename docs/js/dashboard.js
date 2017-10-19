var dashboard = function() {
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
        $('#button-delete-user').click(deleteUserHandler);
        $('#button-start-dungeon').click(startDungeonHandler);
        $('#button-continue-dungeon').click(continueDungeonHandler);
    };

    var continueDungeonHandler = function() {
        redirect.redirect('dungeon');
    };

    var deleteUserHandler = function() {
        api.del({
            url: 'user'
        });
        api.logout();
        redirect.redirect('signup');
    };

    var startDungeonHandler = function() {
        api.post({
            url: 'dungeon'
        });
        redirect.redirect('dungeon');
    };

    var logoutHandler = function() {
        api.logout();
        redirect.redirect('login');
    };

    return {
        init: init,
        name: 'dashboard'
    };
}();

$(dashboard.init);
