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
            appendDungeonStatus(dungeonStatus);
        });
        $('#button-logout').click(logoutHandler);
        $('#button-end-dungeon').click(endDungeonHandler);
        $('#button-delete-user').click(deleteUserHandler);
        $('#button-attack').click(attackEnemyHandler);
        $('#button-search').click(searchHandler);
        $('#button-run').click(runHandler);
        $('#button-follow').click(followGateHandler);
    };
    
    var attackEnemyHandler = function (event) {
        const option = $('#fight-dialog')
            .children('form')
            .children('select#enemy-to-fight')
            .children('option')
            .remove()
            .clone();
        dungeonStatus.room.enemies.map(jsonEnemy => {
            return option.clone()
                .val(jsonEnemy.id)
                .text(jsonEnemy.name);
        }).forEach(htmlEnemy => {
            htmlEnemy.appendTo('#enemy-to-fight');
        });
        $('#fight-dialog').show();
        $('#fight-dialog #button-fight-cancel').click(() =>{
            $('#fight-dialog').hide();
        });
        $('#fight-dialog #button-fight-submit').click(() =>{
            const enemyToFight = $('#fight-dialog #enemy-to-fight').val();
            $('#fight-dialog').hide();
            api.post({
                url: `dungeon/enemy/${enemyToFight}`,
                success: fights => {
                    console.log(fights);
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
                    getDungeonStatus().then(dungeonStatus => {
                        updateEnemies(dungeonStatus)
                    });
                }
            });
        });
        event.preventDefault();
    };
    
    var updateEnemies = function (dungeonStatus) {
        const enemyTemplate = $('#templates').children('.enemy')
            .clone();
        $('#room-enemies > .enemy').remove();
        dungeonStatus.room.enemies.map(jsonEnemy => {
            const htmlEnemy = enemyTemplate.clone();
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
            $('#button-run').hide();
            $('#button-follow-gate').show();
        }
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

    var appendDungeonStatus = function(dungeonStatus) {
        const gateTemplate = $('#templates').children('.gate')
            .clone();
        const enemyTemplate = $('#templates').children('.enemy')
            .clone();
        const itemTemplate = $('#templates').children('.item')
            .clone();
        $('#room-description').text(dungeonStatus.room.description);
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
        dungeonStatus.room.enemies
            .map(jsonEnemy => {
                const htmlEnemy = enemyTemplate.clone();
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
            })
            .forEach(htmlEnemy => {
                htmlEnemy.appendTo('#room-enemies');
            });
        dungeonStatus.room.items
            .map(jsonItem => {
                const htmlItem = itemTemplate.clone();
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
        dungeonStatus.character.bag
            .map(jsonItem => {
                const htmlItem = itemTemplate.clone();
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

    return {
        init: init,
        name: 'dungeon'
    };
}();

$(dungeon.init);
