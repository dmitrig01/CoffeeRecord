ActiveRecord in CoffeeScript. Under very heavy development.


```
require('coffee-script')

var models = require('CoffeeRecord')({ db: 'sqlite', file: 'test.sqlite' }, __dirname + '/models', function(models) {
    models.Post.find(1, function(post) {
        console.log(post);
    });
});
```