exports.config = {
  // See http://brunch.io/#documentation for docs.
  files:
  {
    javascripts:
    {
      joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //   "js/app.js": /^js/,
      //   "js/vendor.js": /^(?!js)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "vendor/js/jquery-2.1.1.js",
      //     "vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets:
    {
      joinTo: "css/app.css"
    },
    templates:
    {
      joinTo: "js/app.js"
    }
  },

  conventions:
  {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths:
  {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor", "elm"],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins:
  {
    elmBrunch:
    {
      elmFolder: "elm",
      mainModules: ["src/Elm.elm"],
      outputFolder: "../vendor"
    },
    babel:
    {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    copyfilemon:
    {
      "fonts": ["fonts"],
      "js": ["node_modules/bootstrap-notify/bootstrap-notify.min.js",
             "node_modules/bootstrap/dist/js/bootstrap.min.js",
             "node_modules/bootstrap-tokenfield/dist/bootstrap-tokenfield.min.js",
             "node_modules/dropzone/dist/dropzone.js",
             "node_modules/jquery/dist/jquery.min.js",
             "node_modules/jquery/external/sizzle/dist/sizzle.min.js",
             "node_modules/jquery/external/sizzle/dist/sizzle.min.map"],
      "css": ["node_modules/bootstrap/dist/css/bootstrap.min.css",
              "node_modules/bootstrap/dist/css/bootstrap-theme.min.css",
              "node_modules/bootstrap/dist/css/bootstrap.min.css.map",
              "node_modules/bootstrap/dist/css/bootstrap-theme.min.css.map",
              "node_modules/bootstrap-tokenfield/dist/css/bootstrap-tokenfield.min.css",
              "node_modules/dropzone/dist/min/dropzone.min.css",
              "node_modules/dropzone/dist/min/basic.min.css"]
    }
  },

  modules:
  {
    autoRequire:
    {
      "js/app.js": ["js/app"]
    }
  },

  npm:
  {
    enabled: true
  }
};