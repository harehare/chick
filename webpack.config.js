const path = require("path");
const webpack = require("webpack");
const BundleTracker = require("webpack-bundle-tracker");
const UglifyJSPlugin = require("uglifyjs-webpack-plugin");

const dist = path.resolve(__dirname + "/dist");
const DevPlugins = [
  new BundleTracker({
    filename: "./webpack-stats.json"
  }),
  new webpack.IgnorePlugin(/^(\.\/locale|app\.js)$/, /moment$/),
];

const ProPlugins = [
  new BundleTracker({
    filename: "./webpack-stats.json"
  }),
  new webpack.optimize.OccurrenceOrderPlugin(),
  new webpack.optimize.AggressiveMergingPlugin(),
  new UglifyJSPlugin({
    sourceMap: false,
    parallel: true,
    uglifyOptions: {
      compress: {
        drop_console: true
      }
    }
  }),
  new webpack.DefinePlugin({
    "process.env": {
      NODE_ENV: '"production"'
    }
  }),
  new webpack.IgnorePlugin(/^(\.\/locale|app\.js)$/, /moment$/),
];

module.exports = env => {
  env = env || {};
  const plugins = env.target === "production" ? ProPlugins : DevPlugins;
  const config = {
    resolve: {
      alias: {
        Common: path.resolve(__dirname, 'common/src/js/'),
        Chick: path.resolve(__dirname, 'clojure/compiled/'),
        Wasm: path.resolve(__dirname, 'wasm/'),
      }
    },
    entry: {
      background: ["./background/src/js/index.js"],
      content: ["./content/src/js/index.js"],
      popup: ["./popup/src/js/index.js"],
      option: ["./option/src/js/index.js"],
    },
    plugins,
    output: {
      path: dist,
      filename: "[name].js"
    },
    module: {
      rules: [{
          test: /\.(css|scss)$/,
          loader: "style-loader!css-loader"
        },
        {
          test: /\.html$/,
          exclude: /node_modules/,
          use: {
            loader: "file?name=[name].[ext]",
            options: {}
          }
        },
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: {
            loader: "elm-webpack-loader",
            options: {
              cwd: __dirname,
              files: [
                path.resolve(__dirname, "content/src/elm/Main.elm"),
                path.resolve(__dirname, "background/src/elm/BackGround.elm"),
                path.resolve(__dirname, "popup/src/elm/Popup.elm"),
                path.resolve(__dirname, "option/src/elm/Option.elm")
              ]
            }
          }
        },
        {
          test: /\.(jpg|png)$/,
          use: {
            loader: "url-loader"
          }
        },
        {
          test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
          use: {
            loader: "file-loader"
          }
        }
      ],
      noParse: /\.elm$/
    }
  };
  return config;
};