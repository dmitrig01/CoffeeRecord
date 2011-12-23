fs            = require 'fs'
coffee_script = require 'coffee-script'
db            = require './database'
base          = require './Model'
_             = require 'underscore'

module.exports = (db_options, models_directory, callback) ->
    _coffee = require.extensions['.coffee']
    require.extensions['.coffee'] = (module, filename) ->
        if 0 == filename.indexOf models_directory
            # Take first part of filename and capitalize
            s = filename.split('.').shift().split('/').pop()
            model = s.charAt(0).toUpperCase() + s.substring 1
            # Wrap it so we can pass in the model superclass
            prefix = "module.exports = (function(Model) { var m = \n"
            suffix = "\nreturn m; });";

            content = prefix + (coffee_script.compile fs.readFileSync(filename, 'utf8') + "return #{model}", {filename}) + suffix
            module._compile content, filename
        else
            _coffee module, filename

    database = db.factory db_options
    model_list = fs.readdirSync models_directory
    models = {}
    after = _.after model_list.length, ->
        for name, model of models
            model._models = model.prototype._models = models
        callback models
    for model_name in model_list
        do (model_name) ->
            model_name
            model = (require models_directory + '/' + model_name) base 
            model.init database, model, ->
                model._name = model.prototype._name = model_name.split('.').shift()
                models[model_name.split('.').shift()] = model
                after()
