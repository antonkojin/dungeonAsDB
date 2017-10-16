var index = function() {
    var init = function() {
        api.ifNotLogged(function() {
            redirect.redirect('login');
        });
        api.ifHasCharacter(function() {
            redirect.redirect('dungeon');
        }, function() {
            redirect.redirect('character');
        });
    };

    return {
        init: init,
        name: 'index'
    };
}();

$(index.init);
