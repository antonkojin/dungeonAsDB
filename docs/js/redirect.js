var redirect = function() {
    var redirect = function(url) {
        window.location.replace(url + 'html');
    };

    return {
        redirect: redirect,
        name: 'redirect'
    };
}();
