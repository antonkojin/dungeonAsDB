var character = function() {
    var init = function() {
        api.ifNotLogged(() => redirect.redirect('login'));
        getDices();
        $('#button-logout').click(logoutHandler);
        $('#button-create').submit(submitHandler);
    };

    var getDices = function() {
        api.get({
            url: 'dices',
            statusCode: {
                200: function(rolls) {
                    $('#create-character-form')
                        .find('div')
                        .each(function(i, div) {
                            div.find('div').each(function(i, radiosGroup) {
                                radiosGroup.each(function(i, radio) {
                                    radio.find('label').text(
                                        rolls[i]['dice_1'] + 
                                        rolls[i]['dice_2'] + 
                                        rolls[i]['dice_3']
                                    );
                                    radio.find('radio').val(data[i]['id']);
                                })
                            });
                        });
                },
                404: function() {
                    redirect.redirect('dungeon');
                }
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
