util = require 'util'
path = 'src/extensions/src/common/*.{js,json}'
regx = /\.js(on)?$/

module.exports = (grunt, options) ->
    util.log "option foo: #{grunt.option('foo')}"
    util.log('matches: ' + util.inspect grunt.file.expand(
        {filter: (src) -> regx.test src}, path
    ))
    util.log('without regx: ' + util.inspect grunt.file.expand path)

util.log "testing minimatch expansion of: #{path} + #{regx}"
