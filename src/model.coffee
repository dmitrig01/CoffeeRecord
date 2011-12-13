_ = require 'underscore'

module.exports = class Model
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

    _hydrate: (values) ->
        values ?= {}
        for key, value of values
            this[key] = value

    _dehydrate: ->
        values = {}
        for field, _ of @fields
            values[field] = this[field]
        values

    save: (callback) ->
        @db.save @table, @_dehydrate(), (id) =>
            this.id = id
            callback this

    destroy: (callback) ->
        @db.destroy @id, callback
