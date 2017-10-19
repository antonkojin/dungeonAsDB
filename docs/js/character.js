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
        $('#create-character-form').submit(submitHandler);
        $('#button-delete-user').click(deleteUserHandler);
    };

    var getDices = function() {
        api.get({
            url: 'dices',
            success: function(rolls) {
                rolls.sort((a, b) => {
                    return b.dice_1 + b.dice_2 + b.dice_3 - a.dice_1 - a.dice_2 - a.dice_3;
                });
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
        var data = {
            name: form.find('#name').val(),
            description: form.find('#description').val(),
            strength: form.find('input[name=strength]:checked').val(),
            intellect: form.find('input[name=intellect]:checked').val(),
            dexterity: form.find('input[name=dexterity]:checked').val(),
            constitution: form.find('input[name=constitution]:checked').val(),
        };
        var invalid = function f ([head, ...tail]) {
            if (!tail.length) {
                return false;
            } else {
                return tail.indexOf(head) >= 0 || f(tail);
            }
        }([data.strength, data.constitution, data.dexterity, data.intellect]);
        if (invalid) {
            window.alert('you can\'t choice the same roll for two characteristics');
        } else {
            api.post({
                url: 'character',
                data: data,
                statusCode: {
                    201: function() {
                       redirect.redirect('dashboard');
                    },
                    409: function() {
                       console.error('no conflict handler');
                    }
                }
            });
        }
        event.preventDefault();
    };

    var deleteUserHandler = function() {
        api.del({
            url: 'user'
        });
        api.logout();
        redirect.redirect('signup');
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
