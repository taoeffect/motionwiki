// https://github.com/gruntjs/grunt/wiki/Getting-started

module.exports = function(grunt) {

    grunt.initConfig({
        bowerful: {
            dist: {
                packages: {
                    "requirejs": "", // unspecified versions indicate most recent
                    "requirejs-text": "",
                    "requirejs-domready": "",
                    "bootstrap": "",
                    "html5shiv-dist": "",
                    "angular": ""
                },
                store: 'src/components'
            }
        },
        shell: {
            kango: {
                command: './extensions/kango/kango.py build extensions',
                options: {
                    stdout: true, stderr: true, failOnError: true
                }
            }
        },
        // requirejs: {
        //     compile: {
        //         options: {
        //             baseUrl: "path/to/base",
        //             mainConfigFile: "path/to/config.js",
        //             out: "path/to/optimized.js"
        //         }
        //     }
        // },

        pkg: grunt.file.readJSON('package.json')
    });
    
    grunt.loadNpmTasks('grunt-bowerful');
    grunt.loadNpmTasks('grunt-text-replace');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-shell');
    // grunt.registerTask('default', ['jshint', 'qunit', 'concat', 'uglify']);

};