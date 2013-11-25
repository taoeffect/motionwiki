# nice example: https://github.com/tnajdek/angular-requirejs-seed/blob/master/app/js/main.js

requirejs.config {
    baseUrl: "<%= G.mode().baseURL %>"
    enforceDefine: true
    paths: 
        # CDN
        jquery: "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min"
        angular: "//cdnjs.cloudflare.com/ajax/libs/angular.js/1.1.5/angular.min"
        bootstrap: "//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.0/js/bootstrap.min"
        lodash: "//cdnjs.cloudflare.com/ajax/libs/lodash.js/2.1.0/lodash.min"
        JSON: "//cdnjs.cloudflare.com/ajax/libs/json3/3.2.5/json3.min"
        angular_strap: "//cdnjs.cloudflare.com/ajax/libs/angular-strap/0.7.4/angular-strap.min"
        bootstrap_datepicker: "//cdnjs.cloudflare.com/ajax/libs/bootstrap-datepicker/1.2.0/js/bootstrap-datepicker.min"
    
    # http://requirejs.org/docs/api.html#config-shim
    shim: 
        jquery: exports: "jQuery"
        html5shiv: exports: "html5"
        angular: 
            # angular doesn't have to depend on jquery, but it's best
            # that we load it before loading angular because it will
            # use jquery to wrap elements then. See:
            # http://docs.angularjs.org/api/angular.element
            deps: ["jquery"]
            exports: "angular"
        # http://stackoverflow.com/questions/13377373/shim-twitter-bootstrap-for-requirejs
        bootstrap: deps: ["jquery"], exports: "$.fn.popover"
        bootstrap_datepicker: deps:["jquery"], exports: "$.fn.datepicker"
        lodash: exports: "_" 
        JSON: exports: "JSON"
        #angular_strap: exports: "$strap"
} # end config

# these wil be inlined! do not inline anything that depends on
# anything that loads from a CDN (e.g. jquery, etc.)!
# http://requirejs.org/docs/api.html#config
# require ["domReady", "html5shiv"]
# require ['requirejs/require.js', 'requirejs-domready/domReady.js', 'html5shiv-dist/html5shiv.js']
