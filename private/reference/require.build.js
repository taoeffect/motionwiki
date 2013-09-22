// Available Options: https://github.com/jrburke/r.js/blob/master/build/example.build.js

({
    // 'out' will contain optimized contents of:
    // - name (code in require.config.js), but will not inline its 'paths'
    //   however, it will inline the modules specified in the call to 'require' at the end
    // - the modules specified in 'include' here. these will be inlined too.
    out: "build/required.js",
    baseUrl: "lib",

    //If you only intend to optimize a module (and its dependencies), with
    //a single file as the output, you can specify the module options inline,
    //instead of using the 'modules' section above. 'exclude',
    //'excludeShallow', 'include' and 'insertRequire' are all allowed as siblings
    //to name. The name of the optimized file is specified by 'out'.
    name: "../require.config", // relative to baseUrl b/c it's a module
    mainConfigFile: "require.config.js", // relative to build file

    // Since "require" is a reserved dependency name, you create a
    // "requireLib" dependency and map it to the require.js file.
    include: ["requireLib"], // inlines require.js in the output

    paths: {
        requireLib: "require/require",
        // runtime ajax paths, do not include these in the optimized output
        jquery: "empty:",
        angular: "empty:"
    },
    //If shim config is used in the app during runtime, duplicate the config
    //here. Necessary if shim config is used, so that the shim's dependencies
    //are included in the build. Using "mainConfigFile" is a better way to
    //pass this information though, so that it is only listed in one place.
    //However, if mainConfigFile is not an option, the shim config can be
    //inlined in the build config.
    // shim: {},

    //Introduced in 2.1.2: If using "dir" for an output directory, normally the
    //optimize setting is used to optimize the build bundles (the "modules"
    //section of the config) and any other JS file in the directory. However, if
    //the non-build bundle JS files will not be loaded after a build, you can
    //skip the optimization of those files, to speed up builds. Set this value
    //to true if you want to skip optimizing those other non-build bundle JS
    //files.
    skipDirOptimize: true, // the only other js file(s) in the output dir should
                           // already be optimized by cljsbuild

    //How to optimize all the JS files in the build output directory.
    //Right now only the following values
    //are supported:
    //- "uglify": (default) uses UglifyJS to minify the code.
    //- "uglify2": in version 2.1.2+. Uses UglifyJS2.
    //- "closure": uses Google's Closure Compiler in simple optimization
    //mode to minify the code. Only available if running the optimizer using
    //Java.
    //- "closure.keepLines": Same as closure option, but keeps line returns
    //in the minified files.
    //- "none": no minification will be done.
    optimize: "uglify2"


    //If using UglifyJS for script optimization, these config options can be
    //used to pass configuration values to UglifyJS.
    //For possible values see:
    //http://lisperator.net/uglifyjs/codegen
    //http://lisperator.net/uglifyjs/compress
    // uglify2: {
    //     //Example of a specialized config. If you are fine
    //     //with the default options, no need to specify
    //     //any of these properties.
    //     output: {
    //         beautify: true
    //     },
    //     compress: {
    //         sequences: false,
    //         global_defs: {
    //             DEBUG: false
    //         }
    //     },
    //     warnings: true,
    //     mangle: false
    // },

    //Introduced in 2.1.2 and considered experimental.
    //If the minifier specified in the "optimize" option supports generating
    //source maps for the minfied code, then generate them. The source maps
    //generated only translate minified JS to non-minified JS, it does not do
    //anything magical for translating minfied JS to transpiled source code.
    //Currently only optimize: "uglify2" is supported when running in node or
    //rhino, and if running in rhino, "closure" with a closure compiler jar
    //build after r1592 (20111114 release).
    //The source files will show up in a browser developer tool that supports
    //source maps as ".js.src" files.
    // generateSourceMaps: true // incompatible with uglify's 'preserveLicenseComments'

})