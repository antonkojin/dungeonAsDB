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
        api.ifHasDungeon(function onYes() {
            $('#button-start-dungeon').hide();
            $('#button-continue-dungeon').show();
            $('#button-end-dungeon').show();
        }, function onNo() {
            $('#button-continue-dungeon').hide();
            $('#button-end-dungeon').hide();
            $('#button-start-dungeon').show();
        });
        $('#button-logout').click(logoutHandler);
        $('#button-delete-user').click(deleteUserHandler);
        $('#button-start-dungeon').click(startDungeonHandler);
        $('#button-continue-dungeon').click(continueDungeonHandler);
        $('#button-end-dungeon').click(endDungeonHandler);
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
        }); // TODO: add error handler
        redirect.redirect('dungeon');
    };

    var logoutHandler = function() {
        api.logout();
        redirect.redirect('login');
    };
    
    var endDungeonHandler = function() {
        api.del({
            url: 'dungeon'
        });
        $('#button-continue-dungeon').hide();
        $('#button-end-dungeon').hide();
        $('#button-start-dungeon').show();
    };

    return {
        init: init,
        name: 'dashboard'
    };
}();

$(dashboard.init);
