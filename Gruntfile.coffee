# Author: Greg Slepak - https://github.com/taoeffect
# 
# https://github.com/gruntjs/grunt/wiki/Getting-started
# 
# == CoffeeScript Style Guidelines ==
# 
# 1. Long object definitions should have a top-level
#    surrounding bace! This helps code that follows "know where it is"
#    
# TODO: Link the kango extensions "main.js" to "scout.js"
# TODO: automatically create "empty:" paths from scout.js for requirejs paths
# TODO: Handle the fact that scout.js could change, and that CloudFront will cache the file!!!!
#       Even deleting the file won't reset the cache!!!

module.exports = (grunt) ->
    _    = require 'lodash' # grunt's lodash is really outdated and doesn't have zipObject
    fs   = require 'fs'
    path = require 'path'
    util = require 'util'
    pkg  = grunt.file.readJSON 'package.json'
    str  = grunt.util._.str
    hook = grunt.util.hooker.hook
    ovrd = grunt.util.hooker.override
    hflt = grunt.util.hooker.filter

    # just in case, do this after hooking the function...
    tpl  = grunt.template.process

    deps =
        grunt:
            f: (dep for dep of pkg.devDependencies)
            d: 'node_modules'
            t: 'shell:npm_install' # task
        bower:
            f: ['requirejs/require.js', "requirejs-domready/domReady.js", "html5shiv-dist/html5shiv.js"]
            d: '<%= G.in.d.libs %>'
            t: 'bowerful'
            rjs: (f)->
                p = path.join G.out.d.build, path.basename(_.find(deps.bower.f,(p)->str.include p, f))
                # grunt.log.writeln "!!!-> #{p.cyan}"
                "<%= modulePath('#{p}') %>"

    G = # this newline is necessary to make the whole thing an object... :-\
        cert: do (_='fake')-> (t)-> return 'chrome.pem' if t is 'link'; "chrome.#{_= t || _}.pem"
        mode: (t)-> G[G.modeName = t ? G.modeName]
        # default values
        modeName:       'debug'
        debug:
            baseURL:    '/includes/js/mw'
            outDir:     '<%= G.out.d.dist %>/debug'
        release:
            baseURL:    '<%= G.debug.baseURL %>' # same as debug! (for symlink:www)
            outDir:     '<%= G.out.d.dist %>/release'
        deploy:
            # baseURL:    'https://d132jtbdykgh41.cloudfront.net/motionwiki/includes/js/mw'
            baseURL:    'https://taoeffect.s3.amazonaws.com/js' # TODO: Update AWS to add above dirs and remove this!
            outDir:     '<%= G.out.d.dist %>/deploy'
        name:
            scout:      'scout'
            config:     'config'
            app:        'motionwiki'
        out:
            d:
                build:  'build'
                dist:   'dist'
                www:    'public'
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
                styles: '<%= G.in.d.src %>/styles'

    # initConfig!
    # ===========

    gConfig = {
        G: G
        _: _
        pkg: pkg
        path: path
        modulePath: (p)->
            path.relative(tpl('<%= requirejs.compile.options.baseUrl %>'),
                path.join(path.dirname(p),path.basename(p,'.js')))

        # https://github.com/gyllstromk/grunt-bowerful
        bowerful:
            dist:
                packages: _.object([f.split('/')[0],""] for f in deps.bower.f)
                store: deps.bower.d

        shell:
            options: stdout: true, stderr: true, failOnError: true
            kango:
                command: '<%= G.in.d.ext %>/kango/kango.py <%= G.out.d.build %> <%= G.in.d.ext %>'
                options:
                    # https://github.com/sindresorhus/grunt-shell
                    callback: (err, stdout, stderr, cb) ->
                        G.cert "fake"
                        if (err)
                            grunt.log.error(err) # Safe, doesn't exit Grunt.
                            grunt.task.clearQueue() # Allows exit with cleanup
                            grunt.task.run('symlink:kango') # re-add symlink task to queue
                         else
                            grunt.task.run('rename:kango')
                        cb() # must be called at end
            npm_install:
                command: 'npm install'
                    
        copy:
            components:
                files: [
                    expand:  true
                    flatten: true
                    cwd:     deps.bower.d
                    src:     deps.bower.f
                    dest:    '<%= G.out.d.build %>/'
                ]

        rename:
            kango:
                src : '<%= G.in.d.ext %>/output'
                dest: '<%= G.out.d.ext %>'

        symlink:
            kango: options:
                link  : '<%= G.in.d.ext %>/certificates/<%= G.cert("link") %>'
                target: '<%= G.in.d.ext %>/certificates/<%= G.cert() %>'
            www: options:
                link  : '<%= path.join(G.out.d.www, G.debug.baseURL) %>'
                target: '<%= G.mode().outDir %>'

        replace:
            version:
                src: [# 'src/extensions/src/common/*.{js,json}'
                      '<%= G.out.d.www %>/index.html'
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
                    cwd   : 'private/playground'
                    src   : ['**/*.coffee']
                    dest  : 'private/playground'
                    ext   : '.js'
                ]
            # anon objs in array: http://bit.ly/122g17v
            motionwiki:
                options:
                    join: true # concat before compiling (instead of after)
                    sourceMap: true
                expand: true
                src   : ['**/*.coffee']
                cwd   : '<%= G.in.d.app %>'
                dest  : '<%= G.out.d.build %>'
                ext   : '.js'

            scout:
                options:
                    join: true # concat before compiling (instead of after)
                    sourceMap: true
                files : [dest: '<%= G.out.f.scout %>', src: '<%= G.in.d.scout %>/**/*.coffee']
        }

        less: {
            development: 
                options: 
                    paths: ['<%= G.in.d.styles %>']
                files: 
                    "<%= G.out.d.www %>/includes/css/motionwiki.css": "<%= G.in.d.styles %>/motionwiki.less"
        }

        watch:
            playground:
                files: ['private/playground/*.coffee']
                tasks: ['coffee:playground', 'execute:playground']
            coffee:
                files: ['<%= G.in.d.src %>/**/*.coffee']
                tasks: ['coffee:motionwiki', 'coffee:scout', 'requirejs']
            less:
                files: ['<%= G.in.d.styles %>/**/*.less']
                tasks: ['less:development']

        clean:
            dist:  ["<%= G.out.d.dist  %>/*"]
            build: ["<%= G.out.d.build %>/*"]
            ext:   ['<%= G.out.d.ext   %>']

        connect: # this actually would work w/o braces, but it'd be confusing
            options:
                port: 8000
                base: ['.','<%= G.out.d.www %>'] # last one acts as "directory:"
            keepalive:
                options:
                    keepalive: true
            dev: {}

        # https://github.com/gruntjs/grunt-contrib-requirejs
        requirejs: {
            compile:
                options:
                    # 'dir' will contain optimized contents of:
                    # - name (code in config.js), but will not inline its 'paths'
                    #   however, it will inline the modules specified in the call to 'require' at the end
                    # - the modules specified in 'include' here. these will be inlined too.
                    dir: '<%= G.mode().outDir %>'
                    baseUrl: '<%= G.out.d.build %>' # where modules are located in
                    mainConfigFile: "<%= G.out.f.scout %>" # relative to build file

                    # modules to optimize (as well as its dependencies)
                    # Avoid optimization names that are outside the baseUrl !!
                    # http://requirejs.org/docs/optimization.html#pitfalls
                    modules: [ # modules are relative to baseUrl
                        name: '<%= G.name.scout %>'
                        # Since "require" is a reserved dependency name, create a
                        # "requireLib" dependency and map it to the require.js file.
                        include: ['requireLib', 'domReady', 'html5shiv']
                        # unfortunately, we have to override this value because if we don't,
                        # the extension banner that's added by onModuleBundleComplete won't be at the top
                        override: preserveLicenseComments: false
                        # create: true # creates the js file for this module if it doesn't exist
                       ,                         
                        name: '<%= G.name.app %>'
                    ]

                    paths:
                        # the requirejs task doesn't support templates in keys, so we'll
                        # evaluate and replace the template keys immediately after config definition
                        '<%= G.name.scout %>': '<%= modulePath(G.out.f.scout) %>'
                        '<%= G.name.app   %>': '<%= modulePath(G.out.f.app) %>'
                        requireLib           : deps.bower.rjs('requirejs')
                        domReady             : deps.bower.rjs('domReady')
                        html5shiv            : deps.bower.rjs('html5shiv')
                        jquery               : 'empty:'
                        angular              : 'empty:'
                        bootstrap            : 'empty:'
                        lodash               : 'empty:'
                        JSON                 : 'empty:'
                        greensock            : 'empty:'

                    keepBuildDir: false

                    # remove files that were combined into a build bundle from the output folder
                    removeCombined: true # just removes that *one* file, not the directory. :(

                    # A function that if defined will be called for every file read in the
                    # build that is done to trace JS dependencies.
                    onBuildRead: (moduleName, path, contents) ->
                        contents.replace(/<%=.+?%>/g, tpl)
                    
                    onModuleBundleComplete: ({name: bundlename, path: filepath})->
                        if bundlename == tpl(G.name.scout)
                            filepath = path.join(tpl('<%= requirejs.compile.options.dir %>'), filepath)
                            # grunt.log.writeln "bundle: #{bundlename}: #{filepath.cyan}"
                            contents = fs.readFileSync(filepath)
                            fs.writeFileSync filepath, """
                            // ==UserScript==
                            // @name MotionWiki
                            // @include http://*.wikipedia.org
                            // @include https://*.wikipedia.org
                            // ==/UserScript==

                            #{contents}
                            """

                    generateSourceMaps:true
                    preserveLicenseComments: false # if generateSouceMaps is true, this must be false

                    # More info: http://requirejs.org/docs/faq-advanced.html#rename
                    namespace: '<%= G.name.app %>Req'
                    skipDirOptimize: true
                    optimize: 'uglify2'
                    uglify2:                   # for an example see example.build.js
                        output:                # http://lisperator.net/uglifyjs/codegen
                            beautify: false    # <- this...
                            comments: /(UserScript|@(include|name))/
                        compress:              # http://lisperator.net/uglifyjs/compress
                            global_defs:
                                DEBUG: false   # <- ...this,
                        mangle: false          # <- and this, will be updated in the 'debug' task
                    

        } # end requirejs
    } # end config  
    
    # process templates in requirejs paths keys:
    rpaths = gConfig.requirejs.compile.options.paths
    for k,v of rpaths when k.indexOf('<%=') is 0
        delete rpaths[k]
        rpaths[tpl(k,data:gConfig)] = v

    grunt.initConfig gConfig

    # https://github.com/gruntjs/grunt/wiki/Creating-tasks
    # http://chrisawren.com/posts/Advanced-Grunt-tooling
    # require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)
    for dep in deps.grunt.f when dep.indexOf('grunt-') is 0
        # grunt.log.writeln "#{dep} : dep.indexOf: #{dep.indexOf 'grunt-'}"
        grunt.loadNpmTasks dep

    # all three grunt symlink plugins i could find sucked ass, so i made my own task.
    grunt.registerMultiTask 'symlink', ->
        opts   = @options(relativeTo: null)
        link   = opts.link
        base   = path.dirname(opts.link)
        target = path.relative(base, path.join(path.dirname(opts.target),path.basename(opts.target)))
        if grunt.file.isDir(opts.target) then type = 'dir' else type = 'file'

        # grunt.file.exists and fs.existsSync don't work when the link is there! :-O
        # console.log "existsSync? #{fs.existsSync(link)} lstat? #{fs.lstatSync(link)}"
        if fs.existsSync(link)
            grunt.log.writeln "Unliking #{link.cyan}..."
            if not fs.lstatSync(link).isSymbolicLink() # grunt.file.isLink doesn't work
                grunt.log.error "File exists already in place of link: #{link.cyan}"
                return false
            fs.unlinkSync(link)

        grunt.log.writeln "Creating #{type.cyan} symlink to #{target.cyan} at #{link.cyan} ..."
        fs.symlinkSync(target, link, type)
        grunt.verbose.or.ok()
 
    grunt.registerTask 'build:debug', 'Debug build for local serving', ->
        grunt.log.writeln "G.#{tpl(G.modeName).cyan}.outDir = #{tpl(G.mode().outDir)}"
        if G.modeName is 'debug' # TODO: move this to rjs_prefile like in 'ifs'
            grunt.config('requirejs.compile.options.uglify2.compress.global_defs.DEBUG', true)
            grunt.config('requirejs.compile.options.uglify2.output.beautify', true)
        else if G.modeName is 'deploy'
            grunt.config('requirejs.compile.options.uglify2.mangle', true)
        grunt.task.run 'coffee', 'compile'

    grunt.registerTask 'build:release', 'Release build for local serving', ->
        G.mode "release"
        grunt.task.run 'kango','build:debug'

    grunt.registerTask 'build:deploy', 'Deploy build for remote serving. Builds extension too.', ->
        G.mode "deploy"
        G.cert 'real' # we call symlink twice to prevent linking real cert
        grunt.task.run 'clean','symlink:kango','kango','symlink:kango','build:debug'

    grunt.registerTask 'checkdeps', 'checks to make sure dependencies are installed', ->
        for k,v of deps
            d = tpl(v.d)
            j = _.compose(_.partial(path.join, d), (f)->f.split('/')[0])
            missing = (j(f) for f in v.f when not grunt.file.exists j(f))
            # console.log "missing: #{util.inspect missing}"
            if missing = (j(f) for f in v.f when not grunt.file.exists j(f))?.toString()
                grunt.log.error "will attempt to install #{d}: #{missing}"
                grunt.task.run v.t

    grunt.registerTask 'rjs_postfight', 'Fix Windows path requirejs \\r bullshit', ->
        String::bs = String::valueOf

    # NOTE: this doens't work! we tried hard! many hours wasted! :-(
    WINHACK = false  # turn this to true if we ever figure out windows. :(
    grunt.registerTask 'rjs_prefight', 'Fix Windows path requirejs \\r bullshit', ->
        # String::bs = String::valueOf
        # support paths on M$ Windows. '\\' isn't good enough bc \\r -> \r
        if WINHACK and path.sep is '\\'
            # isURL = (s) -> s.indexOf('://') >= 0 # || s.indexOf('/') == 0
            # String::bs = -> if isURL(@) then @valueOf() else @replace(rgx,'/').replace(/\//g, '\\\\')
            # String::bs = -> @replace(/[\\]+/g,'/').replace(/\/r/g, '\\\\r')
            String::bs = -> @replace(/[\\/]r/g, '\\\\r')
            # for p,o of {join: path, relative: path, process: grunt.template}
            #     hook o, p, post: (s) -> ovrd s.bs() if s.bs? #template might return a function
            # TODO: only do this once! because of watch this might be done multiple times
            for p,o of {resolve: path}
                hook o, p, post: (s) -> ovrd s.bs()
            # for p,o of {openSync: fs}
            #     hook o, p, pre: (s, args...)-> hflt @, [].concat(s.bs(), args)
        if WINHACK
            grunt.task.run 'requirejs','rjs_postfight'
        else
            grunt.task.run 'requirejs'

    grunt.registerTask 'compile', ['copy:components', 'requirejs', 'symlink:www']
    grunt.registerTask 'kango', ['clean:ext', 'shell:kango']
    grunt.registerTask 'server', ['connect:keepalive']
    grunt.registerTask 'release', ['checkdeps', 'build:release']
    grunt.registerTask 'deploy', ['checkdeps', 'build:deploy']
    grunt.registerTask 'debug', ['checkdeps', 'build:debug']
    grunt.registerTask 'build', ['debug']
    grunt.registerTask 'dev', ['checkdeps','build:debug','connect:dev','watch']
    grunt.registerTask 'default', ['dev']
