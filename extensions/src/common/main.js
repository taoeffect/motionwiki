// ==UserScript==
// @name MotionWiki
// @include http://*.wikipedia.org
// @include https://*.wikipedia.org
// ==/UserScript==

// For allowed values to UserScript header see:
// http://kangoextensions.com/docs/general/content-scripts.html

(function () {
    'use strict';

    // deps:
    // 
    // jquery
    // angularjs
    // bootstrap
    // underscore

    var s = document.createElement('script');
    s.src = '//cdnjs.cloudflare.com/ajax/libs/require.js/2.1.8/require.min.js';
    document.body.appendChild(s);
    
    {/* Use code folding in your editor to hide this ugly section. 
        // Scout file info:
        // - http://alexsexton.com/blog/2013/03/deploying-javascript-applications/
        // Inject CSS notes:
        // - http://requirejs.org/docs/faq-advanced.html#css
        // - http://pastie.org/379693
        // If we want to simultaneously start loading some data
        // then we can uncomment the stuff below:
        // Start loading the data that you know you can grab right away JSONP is small and easy to kick off for this.
        var dataScript = document.createElement('script');
        // Create a JSONP Url based on some info we have. We'll assume localstorage for this example though a cookie or url param might be safer.
        window.appInitData = function (initialData) {
          // Get it to the core application when it eventually loads or if it's already there. A global is used here for ease of example
          window.comeGetMe = initialData; };
        dataScript.src = '//api.mysite.com' +
                         document.location.pathname +
                         '?userid=' +
                         localStorage.getItem('userid') +
                         '&callback=appInitData;';
        fScript.parentNode.insertBefore(dataScript, fScript);
    */}
}());