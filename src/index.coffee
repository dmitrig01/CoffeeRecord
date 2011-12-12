fs            = require 'fs'
coffee_script = require 'coffee-script'
db            = require './database'
base          = require './Model'
_             = require 'underscore'

module.exports = (db_options, models_directory, callback) ->
    require.extensions['.coffee'] = (module, filename) ->
        if 0 == filename.indexOf models_directory
            # Take first part of filename and capitalize
            s = filename.split('.').shift().split('/').pop()
            model = do (s) -> s.charAt(0).toUpperCase() + s.substring 1
            # Wrap it so we can pass in the model superclass
            prefix = "module.exports = (function(Model) { var m = "
            suffix = "return m; });";

            content = prefix + (coffee_script.compile fs.readFileSync(filename, 'utf8') + "return #{model}", {filename}) + suffix
        else
            content = coffee_script.compile fs.readFileSync(filename, 'utf8'), {filename}

        module._compile content, filename

    database = db.factory(db_options)
    model_list = fs.readdirSync(models_directory)
    models = {}
    after = _.after model_list.length, ->
        callback models
    for model_name in model_list
        do (model_name) ->
            model_name
            model = (require models_directory + '/' + model_name) base 
            model.init database, model, ->
                models[model_name.split('.').shift()] = model
                after()
