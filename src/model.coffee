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

    # GENERAL METHODS
    @new: -> new @self

    @find: (id, callback) ->
        callback ?= ->
        @db.query { table: @table, filters: { id: [ id ] }, limit: 1 }, (rows) =>
            callback new @self rows[0]

    # INSTANCE METHODS
    save: (callback) ->
        @db.save @_dehydrate(), callback

    

###
For when more general methods are implemented, a way of chaining -- just need to extract proper keys at the end.
    @where: ->
        options = this
        options.foo = bar
        options
###
