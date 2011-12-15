_ = require 'underscore'
EventEmitter = require('events').EventEmitter

module.exports = class Model extends EventEmitter
    # INITIALIZATION METHODS

    @init: (db, self, callback) ->
        @self = self
        self.db = self.prototype.db = db
        self.prototype.table = self.table
        if self.fields
            self.prototype.fields = self.fields
            callback()
        else
            @db.fields self.table, (fields) ->
                self.fields = self.prototype.fields = fields
                callback()

    @has_many: (name, options = {}) ->
        @prototype._associations ?= {}
        @prototype._associations[name] = { type: 'has_many', options }

    @belongs_to: (name, options = {}) ->
        @prototype._associations ?= {}
        @prototype._associations[name] = { type: 'belongs_to', options }

    @has_one: (name, options = {}) ->
        @prototype._associations ?= {}
        @prototype._associations[name] = { type: 'has_one', options }

    @validates: (name, options = {}) ->
        @prototype._validations[name] = options

    # GENERAL METHODS

    @_extend: ->
        if !@_select
            options = _select: true
            options[key] = this[key] for key of this
            options
        else
            this
            
    @where: (key, value, op = '=') ->
        options = @_extend()
        if typeof key == 'object'
            options = @where.call options, k, v for k, v of key
        else
            options._where ?= []
            options._where.push { key, value, op }
        options

    @limit: (limit) ->
        options = @_extend()
        options._limit = limit
        options

    @offset: (offset) ->
        options = @_extend()
        options._offset = offset
        options

    @order: (field, direction = 'ASC') ->
        options = @_extend()
        options._order_field = field
        options._order_direction = direction
        options

    @_query: ->
        options = @_extend()
        fields = [ 'where', 'limit', 'offset', 'order_field', 'order_direction' ]
        final_options = table: @table
        final_options[field] = options['_' + field] for field in fields
        final_options

    @each: (callback) ->
        callback ?= ->
        @db.each @_query(), (row) =>
            callback new @self row

    @all: (callback) ->
        callback ?= ->
        @db.all @_query(), (rows) =>
            callback (new @self row for row in rows)

    @new: (options) -> new @self (options)

    @find: (id, callback) ->
        @where('id', id).limit(1).each callback

    @create: (options, callback) -> @new(options).save callback

    # INSTANCE METHODS
    constructor: (values) ->
        values ?= {}
        if typeof values == 'function'
            values this
        else
            @_hydrate values
        if @id
            for name, assoc of @_associations
                class_name = assoc.options.class_name ? do (name) -> name.charAt(0).toUpperCase() + name.substring 1
                if assoc.type == 'has_many'
                    this[name + 's'] = @_models[class_name].where(assoc.options.foreign_key ? @_name.toLowerCase() + '_id', @id)
                else if assoc.type == 'has_one'
                    this[name] = (cb) -> @_models[class_name].where(assoc.options.foreign_key ? @_name.toLowerCase() + '_id', @id).limit(1).each cb
                else if assoc.type == 'belongs_to'
                    this[name] = (cb) -> @_models[class_name].where('id', this[assoc.options.foreign_key ? @_name.toLowerCase() + '_id']).limit(1).each cb

    _hydrate: (values) ->
        values ?= {}
        for key, value of values
            this[key] = value

    _dehydrate: ->
        values = {}
        for field, _ of @fields
            values[field] = this[field]
        values

    valid: ->
        valid = true
        for key, validations of @_validations
            for name, options of validations
                if !_(options).isArray()
                    options = [options]
                valid = valid && @validations[name].call this, [this[key]].concat options
        valid

    save: (callback) ->
        @emit 'beforeSave', this
        @db.save @table, @_dehydrate(), (id) =>
            this.id = id
            @emit 'afterSave', this
            callback this

    destroy: (callback) ->
        @db.destroy @id, callback


    validations: {
        presence: (field, presence) ->
            ('' != field.replace /^\s+|\s+$/g, '') == presence
    }


