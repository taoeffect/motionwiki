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
            outDir: "<%= G.out.d.dist %>/debug"
        release:
            baseURL: "/includes/js"
            outDir: "<%= G.out.d.dist %>/release"
        deploy:
            baseURL: "https://d132jtbdykgh41.cloudfront.net/motionwiki/includes/js"
            outDir: "<%= G.out.d.dist %>/deploy"
        name:
            scout:  'scout'
            config: 'config'
            app:    'motionwiki'
        out:
            d:
                build:  'build'
                dist:   'dist'
                ext:    '<%= G.out.d.dist %>/extensions'
            f:
                scout:  '<%= G.out.d.build %>/<%= G.name.scout %>.js'
                app:    '<%= G.out.d.build %>/<%= G.name.app %>.js'
        in:
            d:
                src:    'src'
                libs:   '<%= G.in.d.src %>/components'
                ext:    '<%= G.in.d.src %>/extensions'
                app:    '<%= G.in.d.src %>/<%= G.name.app %>/app'
                scout:  '<%= G.in.d.src %>/<%= G.name.app %>/scout'
        tpl: grunt.template.process

    # initConfig!
    # ===========

    grunt.initConfig {
        G: G
        _: grunt.util._
        pkg: pkg
        modulePath: (p)->
            path.relative(G.tpl('<%= requirejs.compile.options.baseUrl %>'),
                path.join(path.dirname(p),path.basename(p,'.js')))

        # https://github.com/gyllstromk/grunt-bowerful
        bowerful:
            dist:
                packages:
                    requirejs: "" # unspecified versions indicate most recent
                    "requirejs-domready": ""
                    "html5shiv-dist": ""
                store: '<%= G.in.d.libs %>'

        shell:
            kango:
                command: '<%= G.in.d.ext %>/kango/kango.py <%= G.out.d.build %> <%= G.in.d.ext %>'
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
                src: '<%= G.in.d.ext %>/output'
                dest: '<%= G.out.d.ext %>'

        symlink:
            cert: options:
                # relativeTo: '<%= G.in.d.ext %>/certificates'
                # link: '<%= G.cert 'link' %>'
                link: '<%= G.in.d.ext %>/certificates/<%= G.cert("link") %>'
                target: '<%= G.cert() %>'

        replace:
            version:
                src: [# 'src/extensions/src/common/*.{js,json}'
                      '<%= G.in.d.ext %>/src/common/*.json'
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
                    '<%= G.out.f.app %>':   '<%= G.in.d.app %>/**/*.coffee'
                    '<%= G.out.f.scout %>': '<%= G.in.d.scout %>/**/*.coffee'
        }

        watch:
            playground:
                files: ['private/playground/*.coffee']
                tasks: ['coffee:playground', 'execute:playground']
            coffee:
                files: ['<%= G.in.d.src %>/**/*.coffee']
                tasks: ['build']

        clean:
            dist:  ["<%= G.out.d.dist %>/*"]
            build: ["<%= G.out.d.build %>/*"]
            ext:   ['<%= G.out.d.ext %>']

        connect: # this actually would work w/o braces, but it'd be confusing
            server: {options: {base: '<%= G.mode().outDir %>'} }
            homepage: {options: {base: 'public'} }
            options: {port: 8000, keepalive: true}

        # https://github.com/gruntjs/grunt-contrib-requirejs
        requirejs: {
            compile:
                options:
                    # 'dir' will contain optimized contents of:
                    # - name (code in config.js), but will not inline its 'paths'
                    #   however, it will inline the modules specified in the call to 'require' at the end
                    # - the modules specified in 'include' here. these will be inlined too.
                    dir: '<%= G.mode().outDir %>'
                    baseUrl: '<%= G.in.d.libs %>' # where modules are located in
                    mainConfigFile: "<%= G.out.f.scout %>" # relative to build file

                    # modules to optimize (as well as its dependencies)
                    # !! Avoid optimization names that are outside the baseUrl !!
                    # http://requirejs.org/docs/optimization.html#pitfalls
                    modules: [
                        # modules are relative to baseUrl
                        {
                            name: "<%= G.name.scout %>"
                            # Since "require" is a reserved dependency name, create a
                            # "requireLib" dependency and map it to the require.js file.
                            include: ['requireLib']
                        }
                        {name: "<%= G.name.app %>"}
                    ]
                    paths:
                        # we'll convert the template keys immediately after config definition
                        "<%= G.name.scout %>": "<%= modulePath(G.out.f.scout) %>"
                        "<%= G.name.app %>":   "<%= modulePath(G.out.f.app) %>"
                        requireLib: "requirejs/require"
                        # runtime ajax paths, do not include these in the optimized output
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
    
    # process templates in requirejs paths keys:
    rpaths = 'requirejs.compile.options.paths'
    for k,v of grunt.config(rpaths) when k.indexOf('<%=') is 0
        grunt.config(rpaths+'.'+G.tpl(k),v)

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
        grunt.task.run 'coffee', 'requirejs'

    grunt.registerTask 'build:release', 'Release build for local serving', ->
        G.mode "release"
        grunt.task.run 'build'

    grunt.registerTask 'build:deploy', 'Deploy build for remote serving. Builds extension too.', ->
        G.mode "deploy"
        G.cert 'real' # we call symlink twice to prevent linking real cert
        grunt.task.run 'symlink','kango','symlink','build'

    grunt.registerTask 'kango', ['clean:ext', 'shell:kango']
    grunt.registerTask 'server', ['connect:server']
    grunt.registerTask 'homepage', ['connect:homepage']
    grunt.registerTask 'release', ['build:release']
    grunt.registerTask 'deploy', ['clean', 'build:deploy']
    grunt.registerTask 'dev', ['build','watch']
    # TODO: run server task too! (with keepalive false)
    grunt.registerTask 'default', ['dev']
