module.exports = {
  logConfig: {
    filename: '@PREFIX@/var/log/zwave-js-server/zwave-js-server',
    forceConsole: false,
    logToFile: true,
    level: 'error',
  },
  storage: {
    cacheDir: '@PREFIX@/var/cache/zwave-js-server',
    deviceConfigPriorityDir: '@PREFIX@/var/db/zwave-js-server',
  },
  securityKeys: require('./zwave-js-server.keys.js'),
};
