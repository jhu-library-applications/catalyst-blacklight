const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

environment.plugins.prepend(
    'Provide',
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      jquery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default'],
      Rails: ['@rails/ujs'],
    })
)

environment.loaders.prepend('erb', {
  test: /\.erb$/,
  enforce: 'pre',
  use: [{
    loader: 'rails-erb-loader',
  }]
})

module.exports = environment
