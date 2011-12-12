exports.factory = (options) ->
    switch options.db
        when 'sqlite' then this.sqlite options

exports.sqlite = (options) ->
    sqlite = (require 'sqlite3').verbose()
    db = new sqlite.Database options.file

    {
        query: (options, callback) ->
            db.all "SELECT * FROM #{options.table} WHERE id = ?", [ options.filters.id[0] ], (err, rows) ->
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