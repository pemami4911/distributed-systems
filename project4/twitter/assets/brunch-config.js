exports.config = {
    files: {
      javascripts: {
        joinTo: "js/app.js"
      },
      stylesheets: {
        joinTo: "css/app.css",
        order: {
          after: ["../priv/static/css/app.css"] // concat app.css last
        }
      },
      templates: {
        joinTo: "js/app.js"
      }
    },
  
    conventions: {
      // This option sets where we should place non-css and non-js assets in.
      assets: /^(static)/
    },
  
    // Phoenix paths configuration
    paths: {
      // Dependencies and current project directories to watch
      watched: ["static", "css", "js"],
  
      // Where to compile files to
      public: "../priv/static"
    },
  
    // Configure your plugins
    plugins: {
      babel: {
        // Do not use ES6 compiler in vendor code
        ignore: [/node_modules/]
      },
      sass: {
        options: {
          includePaths: ["node_modules/bootstrap/dist/css", "node_modules/font-awesome/scss"], // tell sass-brunch where to look for files to @import
          precision: 8 // minimum precision required by bootstrap
        }
      }
    },
  
    modules: {
      autoRequire: {
        "js/app.js": ["js/app"]
      }
    },
  
    npm: {
      enabled: true,
        // in the npm section
        globals: { // Bootstrap JavaScript requires both '$', 'jQuery'
            $: 'jquery',
            jQuery: 'jquery',
            bootstrap: 'bootstrap' // require Bootstrap JavaScript globally too
        }
    }
};