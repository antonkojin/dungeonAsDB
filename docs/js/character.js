var character = function() {
    var init = function() {
        api.ifNotLogged(function(){
            redirect.redirect('login');
        });
        api.ifHasCharacter(function() {
            redirect.redirect('dungeon');
        }, function() {
            // do nothing
        });
        getDices();
        $('#button-logout').click(logoutHandler);
        $('#button-create').submit(submitHandler);
    };

    var getDices = function() {
        $('#create-character-form').children('div').each(function(i, formGroup) {
            $(formGroup).children('div').each(function(i, radios) {
                $(radios).children('input').each(function(i, radio) {
                    console.log(radio)})})})
        api.get({
            url: 'dices',
            success: function(rolls) {
                $('#create-character-form')
                    .children('div')
                    .each(function(i, formGroup) {
                        $(formGroup).children('div').each(function(i, radiosDiv) {
                            $(radiosDiv).children('div').each(function(i, radioDiv){
                                $(radioDiv).children('label').text(
                                    rolls[i]['dice_1'] + 
                                    rolls[i]['dice_2'] + 
                                    rolls[i]['dice_3']
                                );
                                $(radioDiv).children('input').val(rolls[i]['id']);
                            })
                        });
                    });
                }
            });
    };

    var submitHandler = function(event) {
        var form = $("#create-character-form");
        api.post({
            url: 'character',
            data: {
                name: form.find('#name').val(),
                description: form.find('#description').val(),
                strength: form.find('#strength').val(),
                intellect: form.find('#intellect').val(),
                dexterity: form.find('#dexterity').val(),
                constitution: form.find('#constitution').val(),
            },
            statusCode: {
                201: function() {
                   redirect.redirect('dungeon');
                },
                409: function() {
                   console.error('no conflict handler');
                }
            }
        });
        event.preventDefault();
    };

    var logoutHandler = function() {
        api.logout();
        redirect.redirect('login');
    };

    return {
        init: init,
        name: 'character'
    };
}();

$(character.init);
