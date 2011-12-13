_ = require 'underscore'

exports.factory = (options) ->
    switch options.db
        when 'sqlite' then this.sqlite options

exports.sqlite = (options) ->
    sqlite = (require 'sqlite3').verbose()
    db = new sqlite.Database options.file

    {
        query: (options) ->
            query = "SELECT * FROM #{options.table}"
            values = []
            if options.where
                query += ' WHERE ' + (for where in options.where
                    values.push where.value
                    "#{where.key} #{where.op} ?").join ' AND '
            if options.limit?
                query += ' LIMIT ' + options.limit
            if options.offset?
                query += ' OFFSET ' + options.offset
            { query, values }

        each: (options, callback) ->
            callback ?= ->
            { query, values } = @query options
            db.each query, values, (err, row) ->
                if err then throw err
                callback row
        all: (options, callback) ->
            callback ?= ->
            { query, values } = @query options
            db.all query, values, (err, rows) ->
                if err then throw err
                callback rows
        save: (options, callback) ->
            callback()
        fields: (table, callback) ->
            types =
                INTEGER: 'int'
                TEXT: 'text'
            # Normally this would be subject to SQL injection but this is
            # from a trusted source, not to metion doing ? replacement in a
            # PRAGMA statement doesn't work for some reason.
            db.all "PRAGMA table_info(#{table})", (err, fields) ->
                if err then throw err
                finalFields = {}
                for field in fields
                    finalFields[field.name] = if field.pk then 'serial' else types[field.type]
                callback finalFields
    }