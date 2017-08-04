var modules = []

$(function() {
    modules.forEach(function(module) {
        console.info('loading module: %s', module.name)
        module.init()
    })
})

