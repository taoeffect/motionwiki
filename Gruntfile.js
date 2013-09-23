// https://github.com/gruntjs/grunt/wiki/Getting-started

var fs   = require('fs'),
    path = require('path');


module.exports = function(grunt) {
    var G = {
        debug: {
            baseURL: "/includes/js",
            outDir: "dist/debug"
        },
        release: {
            baseURL: "/includes/js",
            outDir: "dist/release"
        },
        deploy: {
            baseURL: "https://d132jtbdykgh41.cloudfront.net/motionwiki/includes/js",
            outDir: "dist/deploy"
        },
        cert: 'chrome.fake.pem',
        bowerLibs: 'src/components',
        extensions: 'src/extensions',
        tpl: grunt.template.process
    };
    G.mode = G.debug; // debug by default

    grunt.initConfig({
        G: G,
        _: grunt.util._,
        // https://github.com/gyllstromk/grunt-bowerful
        bowerful: {
            dist: {
                packages: {
                    "requirejs": "", // unspecified versions indicate most recent
                    "requirejs-domready": "",
                    "html5shiv-dist": ""
                },
                store: G.bowerLibs
            }
        },
        shell: {
            kango: {
                command: '<%= G.extensions %>/kango/kango.py build <%= G.extensions %>',
                options: {
                    stdout: true, stderr: true, failOnError: true,
                    // https://github.com/sindresorhus/grunt-shell
                    callback: function (err, stdout, stderr, cb) {
                        G.cert = 'chrome.fake.pem';
                        if (err) {
                            grunt.log.error(err); // Safe, doesn't exit Grunt.
                            grunt.task.clearQueue(); // Allows exit with cleanup
                            grunt.task.run('symlink'); // re-add symlink task to queue
                        } else
                            grunt.task.run('rename:kango');
                        cb(); // must be called at end
                    }
                }
            },
        },
        rename: {
            kango: {
                src: '<%= G.extensions %>/output',
                dest: './dist/extensions'
            }
        },
        symlink: {
            cert: { options: {
                // relativeTo: '<%= G.extensions %>/certificates',
                // link: 'chrome.pem',
                link: '<%= G.extensions %>/certificates/chrome.pem',
                target: '<%= G.cert %>'
            }}
        },
        clean: ["dist/*"],
        connect: {
            server: {options: {base: '<%= G.mode.outDir %>'} },
            homepage: {options: {base: 'public'} },
            options: {port: 8000, keepalive: true}
        },
        // https://github.com/gruntjs/grunt-contrib-requirejs
        requirejs: {
            compile: {
                options: {
                    // 'out' will contain optimized contents of:
                    // - name (code in require.config.js), but will not inline its 'paths'
                    //   however, it will inline the modules specified in the call to 'require' at the end
                    // - the modules specified in 'include' here. these will be inlined too.
                    out: "<%= G.mode.outDir %>/required.js",
                    baseUrl: G.bowerLibs, // where modules are located in
                    // 'name' tells the optimizer what module to optimize (as well as its dependencies)
                    name: "../require.config", // relative to baseUrl b/c it's a module
                    mainConfigFile: "src/require.config.js", // relative to build file
                    // runtime ajax paths, do not include these in the optimized output
                    paths: {
                        jquery: "empty:",
                        angular: "empty:",
                        bootstrap: "empty:",
                        underscore: "empty:"
                    },
                    //A function that if defined will be called for every file read in the
                    //build that is done to trace JS dependencies.
                    onBuildRead: function (moduleName, path, contents) {
                        return contents.replace(/<%=.+?%>/g, G.tpl);
                    },
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
                }
            }
        },
        pkg: grunt.file.readJSON('package.json')
    });
    // https://github.com/gruntjs/grunt/wiki/Creating-tasks
    // http://chrisawren.com/posts/Advanced-Grunt-tooling
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);
    
    // all three grunt symlink plugins i could find sucked ass, so i made my own task.
    grunt.registerMultiTask('symlink', function () {
        var opts   = this.options({relativeTo: false});
        var link   = opts.link;
        var base   = opts.relativeTo ? opts.relativeTo : path.dirname(link);
        var target = path.relative(base, path.join(base, opts.target));
        link       = path.join(base, path.basename(link));
        var type = grunt.file.isFile(target) ? 'file' : 'dir';
        if ( grunt.file.exists(link) && !grunt.file.isLink(link) ) {
            grunt.log.error('File exists already in place of link: ' + link.cyan);
            return false;
        }
        fs.unlinkSync(link);
        grunt.verbose.or.write('Creating symlink to ' + target.cyan + ' at ' + link.cyan + '...');
        fs.symlinkSync(target, link, type);
        grunt.verbose.or.ok();
    });

    grunt.registerTask('build', 'Debug build for local serving', function () {
        grunt.task.run('requirejs');
    });
    grunt.registerTask('build:release', 'Release build for local serving', function () {
        G.mode = G.release;
        grunt.task.run('requirejs');
    });
    grunt.registerTask('build:deploy', 'Deploy build for remote serving. Builds extension too.', function () {
        G.mode = G.deploy;
        G.cert = 'chrome.real.pem'; // we call symlink twice to prevent linking real cert
        grunt.task.run('symlink','shell:kango','symlink','requirejs');
    });
    grunt.registerTask('server', ['connect:server']);
    grunt.registerTask('homepage', ['connect:homepage']);
    grunt.registerTask('release', ['build:release']);
    grunt.registerTask('deploy', ['build:deploy']);
    grunt.registerTask('default', ['build']);
};