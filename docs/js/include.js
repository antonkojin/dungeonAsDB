modules.push(function() {
    var init = function() {
        var includes = $('[include]')
        $.each(includes, function(){
            var include = $(this)
            var file = include.attr('include')
            $.get({
                url: file,
                success: function(data) {
                    include.replaceWith(data)
                }
            })
        })
    }

    return {
        name: 'include',
        init: init
    }
}())
