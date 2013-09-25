# https://github.com/gruntjs/grunt/wiki/Getting-started

# == CoffeeScript Style Guidelines ==
# 
# 1. Long object definitions should have a top-level
#    surrounding bace! This helps code that follows "know where it is"

module.exports = (grunt) ->
    fs   = require 'fs'
    path = require 'path'
    util = require 'util'
    pkg  = grunt.file.readJSON 'package.json'
    
    G = # this newline is necessary to make the whole thing an object... :-\
        mode: ((_)-> (t)-> G[_ = t || _])('debug')
        cert: ((_)-> (t)-> return 'chrome.pem' if t is 'link'; "chrome.#{_= t || _}.pem")('fake')
        debug: 
            baseURL: "/includes/js"
            outDir: "<%= G.dir.dist %>/debug"
        release:
            baseURL: "/includes/js"
            outDir: "<%= G.dir.dist %>/release"
        deploy:
            baseURL: "https://d132jtbdykgh41.cloudfront.net/motionwiki/includes/js"
            outDir: "<%= G.dir.dist %>/deploy"
        dir:
            build: 'build'
            dist:  'dist'
            src:   'src'
            out:   '<%= G.mode().outDir %>/'
            js:
                libs: '<%= G.dir.src %>/components'
                ext:  '<%= G.dir.src %>/extensions'
            coffee:
                mw:   '<%= G.dir.src %>/motionwiki'
        tpl: grunt.template.process
    
    # initConfig!
    # ===========

    grunt.initConfig {
        G: G
        _: grunt.util._
        pkg: pkg

        # https://github.com/gyllstromk/grunt-bowerful
        bowerful: 
            dist: 
                packages: 
                    requirejs: "" # unspecified versions indicate most recent
                    "requirejs-domready": ""
                    "html5shiv-dist": ""
                store: G.dir.js.libs
        
        shell: 
            kango: 
                command: '<%= G.dir.js.ext %>/kango/kango.py <%= G.dir.build %> <%= G.dir.js.ext %>'
                options: 
                    stdout: true, stderr: true, failOnError: true
                    # https://github.com/sindresorhus/grunt-shell
                    callback: (err, stdout, stderr, cb) -> 
                        G.cert "fake"
                        if (err) 
                            grunt.log.error(err) # Safe, doesn't exit Grunt.
                            grunt.task.clearQueue() # Allows exit with cleanup
                            grunt.task.run('symlink') # re-add symlink task to queue
                         else
                            grunt.task.run('rename:kango')
                        cb() # must be called at end
                    
        rename: 
            kango: 
                src: '<%= G.dir.js.ext %>/output'
                dest: './dist/extensions'
        
        symlink: 
            cert: options: 
                # relativeTo: '<%= G.dir.js.ext %>/certificates'
                # link: '<%= G.cert 'link' %>'
                link: '<%= G.dir.js.ext %>/certificates/<%= G.cert("link") %>'
                target: '<%= G.cert() %>'
        
        replace:
            version: 
                src: [#'src/motionwiki/**/*.js'
                      # 'src/extensions/src/common/*.{js,json}'
                      'src/extensions/src/common/*.json'
                      '*.json']
                dest: 'tmp/' if not grunt.option('overwrite')
                overwrite: grunt.option('overwrite')
                replacements: [
                    from: grunt.option('from')
                    to: grunt.option('to')
                ]

        execute:
            playground:
                options:
                    module: true
                src: ['private/playground/*.js']

        coffee: {
            options: # these apply to all targets
                bare: true

            playground:
                files: [
                    expand: true
                    cwd: 'private/playground'
                    src: ['**/*.coffee']
                    dest: 'private/playground'
                    ext: '.js'
                ]

            motionwiki:
                options:
                    join: true
                    # sourceMap: true # not much point if we're later minifying?
                files:
                    'build/motionwiki.js': 'src/motionwiki/**/*.coffee'
        }

        watch:
            playground:
                files: ['private/playground/*.coffee']
                tasks: ['coffee:playground', 'execute:playground']
            coffee:
                files: ['src/motionwiki/**/*.coffee']
                tasks: ['coffee:src']

        clean: ["<%= G.dir.dist %>/*", "<%= G.dir.build %>/*"]

        connect: # this actually would work w/o braces, but it'd be confusing
            server: {options: {base: '<%= G.dir.out %>'} }
            homepage: {options: {base: 'public'} }
            options: {port: 8000, keepalive: true}
        
        # https://github.com/gruntjs/grunt-contrib-requirejs
        requirejs: {
            compile:
                options:
                    # 'out' will contain optimized contents of:
                    # - name (code in require.config.js), but will not inline its 'paths'
                    #   however, it will inline the modules specified in the call to 'require' at the end
                    # - the modules specified in 'include' here. these will be inlined too.
                    out: "<%= G.dir.out %>/required.js"
                    baseUrl: G.dir.js.libs # where modules are located in
                    mainConfigFile: "src/require.config.js" # relative to build file

                    # modules to optimize (as well as its dependencies)
                    modules: [
                        # modules are relative to baseUrl
                        {name: "../require.config"}
                        {name: "../build/"}
                    ]

                    # runtime ajax paths, do not include these in the optimized output
                    paths:
                        jquery: "empty:"
                        angular: "empty:"
                        bootstrap: "empty:"
                        underscore: "empty:"
                    
                    #A function that if defined will be called for every file read in the
                    #build that is done to trace JS dependencies.
                    onBuildRead: (moduleName, path, contents) -> 
                        contents.replace(/<%=.+?%>/g, G.tpl)
                    
                    #Introduced in 2.1.2: If using "dir" for an output directory, normally the
                    #optimize setting is used to optimize the build bundles (the "modules"
                    #section of the config) and any other JS file in the directory. However, if
                    #the non-build bundle JS files will not be loaded after a build, you can
                    #skip the optimization of those files, to speed up builds. Set this value
                    #to true if you want to skip optimizing those other non-build bundle JS
                    #files.
                    skipDirOptimize: true # the only other js file(s) in the output dir should
                                           # already be optimized by cljsbuild
                    #How to optimize all the JS files in the build output directory.
                    #Right now only the following values
                    #are supported:
                    #- "uglify": (default) uses UglifyJS to minify the code.
                    #- "uglify2": in version 2.1.2+. Uses UglifyJS2.
                    #- "closure": uses Google's Closure Compiler in simple optimization
                    #mode to minify the code. Only available if running the optimizer using
                    #Java.
                    #- "closure.keepLines": Same as closure option, but keeps line returns
                    #in the minified files.
                    #- "none": no minification will be done.
                    optimize: "uglify2"
        } # end requirejs
    } # end config  
    
    # https://github.com/gruntjs/grunt/wiki/Creating-tasks
    # http://chrisawren.com/posts/Advanced-Grunt-tooling
    # require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)
    for dep of pkg.devDependencies when dep.indexOf('grunt-') is 0
        # grunt.log.writeln "#{dep} : dep.indexOf: #{dep.indexOf 'grunt-'}"
        grunt.loadNpmTasks dep
    
    # all three grunt symlink plugins i could find sucked ass, so i made my own task.
    grunt.registerMultiTask 'symlink', -> 
        opts   = @options(relativeTo: null)
        base   = opts.relativeTo ? path.dirname(opts.link)
        link   = path.join(base, path.basename(opts.link))
        target = path.relative(base, path.join(base, opts.target))
        type   = if grunt.file.isDir(target) then 'dir' else 'file'

        if grunt.file.exists(link) && !grunt.file.isLink(link) 
            grunt.log.error "File exists already in place of link: #{link.cyan}"
            return false
        fs.unlinkSync(link)
        grunt.verbose.or.write "Creating symlink to #{target.cyan} at #{link.cyan} ..."
        fs.symlinkSync(target, link, type)
        grunt.verbose.or.ok()
    
    grunt.registerTask 'build', 'Debug build for local serving', ->
        grunt.task.run 'requirejs'
    
    grunt.registerTask 'build:release', 'Release build for local serving', ->
        G.mode "release"
        grunt.task.run 'requirejs'
    
    grunt.registerTask 'build:deploy', 'Deploy build for remote serving. Builds extension too.', ->
        G.mode "deploy"
        G.cert 'real' # we call symlink twice to prevent linking real cert
        grunt.task.run 'symlink','shell:kango','symlink','requirejs'
    
    grunt.registerTask 'server', ['connect:server']
    grunt.registerTask 'homepage', ['connect:homepage']
    grunt.registerTask 'release', ['build:release']
    grunt.registerTask 'deploy', ['build:deploy']
    grunt.registerTask 'default', ['build']
