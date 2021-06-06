module.exports = {
    configureWebpack: {
      devServer: {
        host: process.env.VUE_APP_PRIVATE_IPV4_ADDRESS,
        https: true,
      }
    }
  };