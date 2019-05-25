const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

let browserConfig = {
  mode: process.env.NODE_ENV || 'development',
  stats: 'minimal',
  entry: {
    app: ['@babel/polyfill', './src/app.js'],
  },
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'bundle.js',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: { loader: 'babel-loader' },
      },
      {
        test: /\.(sa|sc|c)ss$/,
        use: [
          process.env.NODE_ENV === 'development' ? 'style-loader' : MiniCssExtractPlugin.loader,
          'css-loader',
          'sass-loader',
        ],
      },
      {
        test: /\.elm$/,
        use: {
          loader: 'elm-webpack-loader',
          options: {
            optimize: process.env.NODE_ENV === 'production',
          },
        },
      },
      {
        test: /\.(woff|ttf)$/,
        use: [
          {
            loader: 'url-loader',
          },
        ],
      },
      {
        test: /\.raw.*$/,
        use: 'raw-loader',
      },
    ],
  },
  plugins: [new MiniCssExtractPlugin()],
  devServer: {
    contentBase: path.join(__dirname, 'dist'),
    historyApiFallback: true,
    stats: 'minimal',
    host: '0.0.0.0',
  },
}

let workerConfig = {
  mode: process.env.NODE_ENV || 'development',
  stats: 'minimal',
  entry: ['@babel/polyfill', './src/match.worker.js'],
  target: 'webworker',
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'worker.js',
  },
  resolve: {
    alias: {
      logic:
        process.env.NODE_ENV === 'production'
          ? './frontend.js'
          : path.join(__dirname, '../logic/_build/default/frontend.js'),
    },
  },
  node: {
    fs: 'empty',
  },
}

module.exports = [browserConfig, workerConfig]
