var dungeon = function() {
    var dungeonStatus;

    var init = function() {
        api.ifNotLogged(function () {
            redirect.redirect('login');
        });
        api.ifHasCharacter(function() {
            // do nothing
        }, function() {
            redirect.redirect('character');
        });
        api.ifHasDungeon(function() {
            // do nothing
        }, function(){
            redirect.redirect('dashboard');
        });
        getDungeonStatus().then(dungeonStatus => {
            updateDungeonStatus(dungeonStatus);
        });
        $('#button-logout').click(logoutHandler);
        $('#button-end-dungeon').click(endDungeonHandler);
        $('#button-delete-user').click(deleteUserHandler);
        $('#button-attack').click(attackEnemyHandler);
        $('#button-search').click(searchHandler);
        $('#button-pick').click(pickItemHandler);
        $('#button-use').click(useItemHandler);
        $('#button-run').click(followGateHandler);
        $('#button-follow-gate').click(followGateHandler);
    };
    
    var pickItemHandler = function (event) {
        const option = $('#options-dialog > form > select > option')
            .remove()
            .first().clone();
        dungeonStatus.room.items.map(jsonItem => {
            return option.clone()
                .val(jsonItem.id)
                .text(`
                    id: ${jsonItem.id},
                    name: ${jsonItem.name}
                `);
        }).forEach(htmlItem => {
            htmlItem.appendTo('#options-dialog select');
        });
        $('#options-dialog').show();
        $('#options-dialog #button-dialog-cancel')
            .off('click') // clear click event's handlers queue
            .click(e => {
                $('#options-dialog').hide();
                e.preventDefault();
            });
        $('#options-dialog #button-dialog-submit')
            .off('click') // clear click event's handlers queue
            .click(e => {
                const itemToPick = $('#options-dialog select').val();
                $('#options-dialog').hide();
                api.post({
                    url: `dungeon/item/${itemToPick}`,
                    success: () => {
                        getDungeonStatus().then(dungeonStatus => {
                            updateCharacterBag(dungeonStatus);
                            updateRoomItems(dungeonStatus);
                        });
                    }
                });
            e.preventDefault();
        });
        event.preventDefault();
    };
    
    var useItemHandler = function (event) {
        const option = $('#options-dialog > form > select > option')
            .remove()
            .first().clone();
        dungeonStatus.character.bag.map(jsonItem => {
            return option.clone()
                .val(jsonItem.id)
                .text(`
                    id: ${jsonItem.id},
                    name: ${jsonItem.name}
                `);
        }).forEach(htmlItem => {
            htmlItem.appendTo('#options-dialog select');
        });
        $('#options-dialog').show();
        $('#options-dialog #button-dialog-cancel')
            .off('click') // clear click event's handlers queue
            .click(e => {
                $('#options-dialog').hide();
                e.preventDefault();
            });
        $('#options-dialog #button-dialog-submit')
            .off('click') // clear click event's handlers queue
            .click(e => {
                const itemToUse = $('#options-dialog select').val();
                $('#options-dialog').hide();
                api.post({
                    url: `dungeon/bag/${itemToUse}`,
                    success: () => {
                        getDungeonStatus().then(dungeonStatus => {
                            updateCharacterBag(dungeonStatus);
                            updateCharacter(dungeonStatus);
                        });
                    }
                });
            e.preventDefault();
        });
        event.preventDefault();
    };
    
    var searchHandler = function (event) {
        api.get({
            url: 'dungeon/search',
            success: data => {
                getDungeonStatus().then(s => {
                    updateCharacter(s);
                    updateCharacterBag(s);
                    updateGates(s);
                });
                window.alert(`
                    roll: ${data.roll}
                    id: ${data.id}
                    type: ${data.type}
                `);
            }
        });
        event.preventDefault();
    };
    
    var followGateHandler = function (event) {
        const option = $('#options-dialog')
            .children('form')
            .children('select')
            .children('option')
            .remove()
            .first()
            .clone();
        dungeonStatus.room.gates.map(jsonGate => {
            return option.clone()
                .val(jsonGate.id)
                .text(`gate: ${jsonGate.id}, room: ${jsonGate.room}`);
        }).forEach(htmlGate => {
            htmlGate.appendTo('#options-dialog select');
        });
        $('#options-dialog').show();
        $('#options-dialog #button-dialog-cancel')
            .off('click') // clear click event's handlers queue
            .click(e => {
                $('#options-dialog').hide();
                e.preventDefault();
            });
        $('#options-dialog #button-dialog-submit')
            .off('click') // clear click event's handlers queue
            .click(e => {
                const gateToRunTo = $('#options-dialog select').val();
                $('#options-dialog').hide();
                api.get({
                    url: `dungeon/gate/${gateToRunTo}`,
                    success: () => {
                        getDungeonStatus().then(dungeonStatus => {
                            updateDungeonStatus(dungeonStatus);
                        });
                    }
                });
            e.preventDefault();
        });
        event.preventDefault();
    };
    
    var attackEnemyHandler = function (event) {
        const option = $('#options-dialog')
            .children('form')
            .children('select')
            .children('option')
            .remove()
            .first()
            .clone();
        dungeonStatus.room.enemies.map(jsonEnemy => {
            return option.clone()
                .val(jsonEnemy.id)
                .text(jsonEnemy.name);
        }).forEach(htmlEnemy => {
            htmlEnemy.appendTo('#options-dialog select');
        });
        $('#options-dialog').show();
        $('#options-dialog #button-dialog-cancel').click(() =>{
            $('#options-dialog').hide();
        });
        $('#options-dialog #button-dialog-submit').click(e =>{
            const enemyToFight = $('#options-dialog select').val();
            $('#options-dialog').hide();
            api.post({
                url: `dungeon/enemy/${enemyToFight}`,
                success: fights => {
                    getDungeonStatus().then(dungeonStatus => {
                        updateEnemies(dungeonStatus);
                        updateCharacter(dungeonStatus);
                    });
                    window.alert(fights.map(fight => {
                        return `
                            type: ${fight.type}
                            hit: ${fight.hit}
                            value: ${fight.value}
                            dice: ${fight.dice}
                            id: ${fight.id}
                            damage: ${fight.damage}
                        `;
                    }));
                }
            });
            e.preventDefault();
        });
        event.preventDefault();
    };
    
    var updateEnemies = function (dungeonStatus) {
        const enemyTemplate = $('#templates').children('.enemy')
            .clone();
        $('#room-enemies > .enemy').remove();
        dungeonStatus.room.enemies.map(jsonEnemy => {
            const htmlEnemy = enemyTemplate.clone();
            htmlEnemy.children('.enemy-id')
                .text(jsonEnemy.id);
            htmlEnemy.children('.enemy-name')
                .text(jsonEnemy.name);
            htmlEnemy.children('.enemy-description')
                .text(jsonEnemy.description);
            htmlEnemy.children('.enemy-attack')
                .text(jsonEnemy.attack);
            htmlEnemy.children('.enemy-defence')
                .text(jsonEnemy.defence);
            htmlEnemy.children('.enemy-hit-points')
                .text(jsonEnemy.hit_points);
            htmlEnemy.children('.enemy-damage')
                .text(jsonEnemy.damage);
            return htmlEnemy;
        }).forEach(htmlEnemy => {
            htmlEnemy.appendTo('#room-enemies');
        });
        if (dungeonStatus.room.enemies.length == 0) {
            $('#button-attack').hide();
            $('#button-search').show();
            $('#button-pick').show();
            $('#button-run').hide();
            $('#button-follow-gate').show();
        } else {
            $('#button-attack').show();
            $('#button-search').hide();
            $('#button-pick').hide();
            $('#button-run').show();
            $('#button-follow-gate').hide();
        }
    };
    
    var updateCharacter = function (dungeonStatus) {
        $('#character-name')
            .text(dungeonStatus.character.name);
        $('#character-description')
            .text(dungeonStatus.character.description);
        $('#character-attack')
            .text(dungeonStatus.character.attack);
        $('#character-defence')
            .text(dungeonStatus.character.defence);
        $('#character-wisdom')
            .text(dungeonStatus.character.wisdom);
        $('#character-hit-points')
            .text(dungeonStatus.character.hit_points);
        const htmlEquippedAttackItem = $('#character-equipped-attack-item');
        const equippedAttackItem = dungeonStatus.character.bag.find(i => {
            return i.id === dungeonStatus.character.equipped_attack_item
        });
        htmlEquippedAttackItem.children('.item-id')
            .text(equippedAttackItem.id);
        htmlEquippedAttackItem.children('.item-name')
            .text(equippedAttackItem.name);
        htmlEquippedAttackItem.children('.item-description')
            .text(equippedAttackItem.description);
        htmlEquippedAttackItem.children('.item-attack')
            .text(equippedAttackItem.attack);
        htmlEquippedAttackItem.children('.item-defence')
            .text(equippedAttackItem.defence);
        htmlEquippedAttackItem.children('.item-wisdom')
            .text(equippedAttackItem.wisdom);
        htmlEquippedAttackItem.children('.item-hit-points')
            .text(equippedAttackItem.hit_points);
        htmlEquippedAttackItem.children('.item-category')
            .text(equippedAttackItem.category);
        const htmlEquippedDefenceItem = $('#character-equipped-defence-item');
        const equippedDefenceItem = dungeonStatus.character.bag.find(i => {
            return i.id === dungeonStatus.character.equipped_defence_item
        });
        htmlEquippedDefenceItem.children('.item-id')
            .text(equippedDefenceItem.id);
        htmlEquippedDefenceItem.children('.item-name')
            .text(equippedDefenceItem.name);
        htmlEquippedDefenceItem.children('.item-description')
            .text(equippedDefenceItem.description);
        htmlEquippedDefenceItem.children('.item-attack')
            .text(equippedDefenceItem.attack);
        htmlEquippedDefenceItem.children('.item-defence')
            .text(equippedDefenceItem.defence);
        htmlEquippedDefenceItem.children('.item-wisdom')
            .text(equippedDefenceItem.wisdom);
        htmlEquippedDefenceItem.children('.item-hit-points')
            .text(equippedDefenceItem.hit_points);
        htmlEquippedDefenceItem.children('.item-category')
            .text(equippedDefenceItem.category);
        $('#character-room-attack-bonus')
            .text(dungeonStatus.character.room_attack_bonus);
        $('#character-room-defence-bonus')
            .text(dungeonStatus.character.room_defence_bonus);
        $('#character-room-wisdom-bonus')
            .text(dungeonStatus.character.room_wisdom_bonus);
        $('#character-room-hit-points-bonus')
            .text(dungeonStatus.character.room_hit_points_bonus);
    };
    
    var updateCharacterBag = function (dungeonStatus) {
        const itemTemplate = $('#templates > .item').clone();
        $('#character-bag > .item').remove();
        dungeonStatus.character.bag
            .map(jsonItem => {
                const htmlItem = itemTemplate.clone();
                htmlItem.children('.item-id').text(jsonItem.id);
                htmlItem.children('.item-name').text(jsonItem.name);
                htmlItem.children('.item-description').text(jsonItem.description);
                htmlItem.children('.item-attack').text(jsonItem.attack);
                htmlItem.children('.item-defence').text(jsonItem.defence);
                htmlItem.children('.item-wisdom').text(jsonItem.wisdom);
                htmlItem.children('.item-hit-points').text(jsonItem.hit_points);
                htmlItem.children('.item-category').text(jsonItem.category);
                return htmlItem;
            })
            .forEach(htmlItem => {
                htmlItem.appendTo('#character-bag');
            });
    };
    
    var updateGates = function (dungeonStatus) {
        const gateTemplate = $('#templates > .gate').clone();
        $('#room-gates > .gate').remove();
        dungeonStatus.room.gates
            .map(jsonGate => {
                const htmlGate = gateTemplate.clone();
                htmlGate.children('.gate-id')
                    .text(jsonGate.id);
                htmlGate.children('.room-id')
                    .text(jsonGate.room);
                return htmlGate;
            })
            .forEach(htmlGate => {
                htmlGate.appendTo('#room-gates');
            });
    };
    
    var updateRoomItems = function (dungeonStatus) {
        const itemTemplate = $('#templates > .item').clone();
        $('#room-items > .item').remove();
        dungeonStatus.room.items
            .map(jsonItem => {
                const htmlItem = itemTemplate.clone();
                htmlItem.children('.item-id')
                    .text(jsonItem.id);
                htmlItem.children('.item-name')
                    .text(jsonItem.name);
                htmlItem.children('.item-description')
                    .text(jsonItem.description);
                htmlItem.children('.item-attack')
                    .text(jsonItem.attack);
                htmlItem.children('.item-defence')
                    .text(jsonItem.defence);
                htmlItem.children('.item-hit-points')
                    .text(jsonItem.hit_points);
                htmlItem.children('.item-category')
                    .text(jsonItem.category);
                return htmlItem;
            })
            .forEach(htmlItem => {
                htmlItem.appendTo('#room-items');
            });
    };
    
    var updateRoom = function (dungeonStatus) {
        $('#room-id').text(dungeonStatus.room.id);
        $('#room-description').text(dungeonStatus.room.description);
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

    var getDungeonStatus = function() {
        return api.get({
            url: 'dungeon',
            success: (data => {
                dungeonStatus = data;
            })
        });
    };

    var updateDungeonStatus = function(dungeonStatus) {
        updateRoom(dungeonStatus);
        updateGates(dungeonStatus);
        updateEnemies(dungeonStatus);
        updateRoomItems(dungeonStatus);
        updateCharacter(dungeonStatus);
        updateCharacterBag(dungeonStatus);
    };

    return {
        init: init,
        name: 'dungeon'
    };
}();

$(dungeon.init);
