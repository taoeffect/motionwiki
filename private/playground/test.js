var path, regx, util;

util = require('util');

path = 'src/extensions/src/common/*.{js,json}';

regx = /\.js(on)?$/;

module.exports = function(grunt, options) {
  util.log("option foo: " + (grunt.option('foo')));
  util.log('matches: ' + util.inspect(grunt.file.expand({
    filter: function(src) {
      return regx.test(src);
    }
  }, path)));
  return util.log('without regx: ' + util.inspect(grunt.file.expand(path)));
};

util.log("testing minimatch expansion of: " + path + " + " + regx);
