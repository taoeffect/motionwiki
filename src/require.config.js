// nice example: https://github.com/tnajdek/angular-requirejs-seed/blob/master/app/js/main.js

requirejs.config({
    baseUrl: "/includes/js/lib",
    paths: {
        text: "require/text",
        domReady: "require/domReady",
        jquery: [
            "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min",
            "jquery.min"
        ],
        angular: [
            "//cdnjs.cloudflare.com/ajax/libs/angular.js/1.1.5/angular",
            "angular.min" // different version! we have 1.0.7!
        ],
        bootstrap: "bootstrap.min",
        three: "three/three.min"
    },
    // http://requirejs.org/docs/api.html#config-shim
    shim: {
        angular: {
            // angular doesn't have to depend on jquery, but it's best
            // that we load it before loading angular because it will
            // use jquery to wrap elements then. See:
            // http://docs.angularjs.org/api/angular.element
            "deps": ["jquery"],
            "exports": "angular"
        },
        three: {"exports": "THREE"},
        // http://stackoverflow.com/questions/13377373/shim-twitter-bootstrap-for-requirejs
        bootstrap: {
            "deps": ["jquery"],
            "exports": "$.fn.popover"
        }
    },
    enforceDefine: true
});

// these wil be inlined!
require(["text", "domReady"]);
