fs            = require 'fs'
coffee_script = require 'coffee-script'
db            = require './database'
base          = require './Model'
_             = require 'underscore'

module.exports = (db_options, models_directory, callback) ->
    database = db.factory db_options
    model_list = fs.readdirSync models_directory
    models = [ base ]

    modelNames = (for filename in model_list
        s = filename.split('.').shift().split('/').pop()
        s.charAt(0).toUpperCase() + s.substring 1)
    index = 1

    # Pull some ninja moves to make all models accessible to each other.
    _coffee = require.extensions['.coffee']
    require.extensions['.coffee'] = (module, filename) ->
        if 0 == filename.indexOf models_directory
            args = ['Model']
            vars = ['_ref']
            i = 0
            for model in modelNames
                i++
                if i == index
                    args.push '__'
                    vars.push model_name = model
                else if i < index
                    vars.push model
                    args.push '__' + model.toLowerCase()
                else
                    args.push model
            i = 1
            nextArgs = ['Model']
            next = ''
            nextReturn = []
            for model in modelNames
                i++
                if i == index
                    nextArgs.push '__'
                    next = '__' + model.toLowerCase()
                    nextReturn.push model
                else if i < index
                    nextArgs.push '__' + model.toLowerCase()
                    nextReturn.push model
                else
                    nextArgs.push model

            # Wrap it so we can pass in the model superclass
            content = """
module.exports = (function(#{args.join(', ')}) {
var #{vars.join(', ')};
#{model_name} = """ + (coffee_script.compile fs.readFileSync(filename, 'utf8') + """

if #{model_name}?
    #{model_name}._name = #{model_name}.prototype._name = '#{model_name}'
    return #{model_name}""", { filename }) + "\n"
            if nextReturn.length
                content += "__ref = #{next}(#{nextArgs.join()});\n"
                content += "#{ret} = __ref.#{ret}\n" for ret in nextReturn
            nextReturn.push model_name
            content += "return {\n"
            content += "  '#{ret}': #{ret},\n" for ret in nextReturn
            content += "}\n});"

            module._compile content, filename
        else
            _coffee module, filename

    
    for model_name in model_list
        models.push(require models_directory + '/' + model_name)
        index++
    require.extensions['.coffee'] = _coffee
    model_list = models.pop().apply {}, models

    after = _.after models.length, -> callback model_list

    for name, model of model_list
        model.init database, model_list, model, ->
            model._name = model.prototype._name = name
            model_list[name] = model
            after()
