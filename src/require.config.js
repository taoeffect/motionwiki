// nice example: https://github.com/tnajdek/angular-requirejs-seed/blob/master/app/js/main.js

requirejs.config({
    baseUrl: "<%= G.mode.baseURL %>",
    paths: {
        // to be inlined
        // Since "require" is a reserved dependency name, create a
        // "requireLib" dependency and map it to the require.js file.
        requireLib: "requirejs/require",
        domReady: "requirejs-domready/domReady",
        html5shiv: "html5shiv-dist/html5shiv",
        // CDN
        jquery: "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min",
        angular: "//cdnjs.cloudflare.com/ajax/libs/angular.js/1.1.5/angular.min",
        bootstrap: "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.0/js/bootstrap.min.js",
        underscore: "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.5.2/underscore-min"
    },
    // http://requirejs.org/docs/api.html#config-shim
    shim: {
        html5shiv: {"exports": "html5"},
        angular: {
            // angular doesn't have to depend on jquery, but it's best
            // that we load it before loading angular because it will
            // use jquery to wrap elements then. See:
            // http://docs.angularjs.org/api/angular.element
            "deps": ["jquery"],
            "exports": "angular"
        },
        // http://stackoverflow.com/questions/13377373/shim-twitter-bootstrap-for-requirejs
        bootstrap: { "deps": ["jquery"], "exports": "$.fn.popover"},
        underscore: {"exports": "_"}
    },
    enforceDefine: true
});

// these wil be inlined! do not inline anything that depends on
// anything that loads from a CDN (e.g. jquery, etc.)!
// http://requirejs.org/docs/api.html#config
require(["requireLib", "domReady", "html5shiv"]);
