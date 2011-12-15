ActiveRecord in CoffeeScript. Under very heavy development.

Examples:

```
require('CoffeeRecord')({ db: 'sqlite', file: 'test.sqlite' }, __dirname + '/models', function(models) {
    models.Post.find(1, function(post) {
        post.comments.all(function(comments) {
            // Do something here with these...
        });
    });
});
```

models/Post.coffee

```
class Post extends Model
    @has_many 'comment'
```