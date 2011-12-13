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
                    if _(where.value).isArray()
                        qs = []
                        for i in where.value
                            values.push i
                            qs.push '?'
                        "#{where.key} IN (" + qs.join(', ') + ')'
                    else
                        values.push where.value
                        "#{where.key} #{where.op} ?").join ' AND '
            if options.limit?
                query += ' LIMIT ' + options.limit
            if options.offset?
                query += ' OFFSET ' + options.offset

            query: query
            values: values

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
        save: (table, fields, callback) ->
            values = []
            if fields.id
                query = "UPDATE #{table} SET " +
                (for key, value of fields when key != 'id'
                    values.push value
                    "#{key} = ?").join(', ') +
                ' WHERE id = ?'
                values.push fields.id
            else
                keys = []
                qs = []
                values = []
                for key, value of fields when value?
                    keys.push key
                    values.push value
                    qs.push '?'
                query = "INSERT INTO #{table} (" + keys.join(', ') + ') VALUES (' + qs.join(', ') + ')'
            console.log query
            console.log values
            db.run query, values, -> 
                callback this.lastID
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