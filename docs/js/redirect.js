var redirect = function() {
    var redirect = function(url) {
        window.location.replace(url);
    };

    return {
        redirect: redirect,
        name: 'redirect'
    };
}();
