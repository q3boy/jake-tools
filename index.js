if (require.extensions['.coffee']) {
  module.exports = require('./jake-tools.coffee');
} else {
  module.exports = require('./jake-tools.js');
}
