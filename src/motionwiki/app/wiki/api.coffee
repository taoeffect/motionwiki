# sandbox: http://en.wikipedia.org/wiki/Special:ApiSandbox

define ['jquery', 'lodash'], ($,_) ->
    # just an example. this will return an object.
    defaults =
        num : 5
        ajax: 
            url: 'https://en.wikipedia.org/w/api.php'
            dataType: 'jsonp'

    @merge = (o={}, def=defaults, rest...)-> _.defaults o, def, rest...

    # haven't tested 'compare'... it probably doesn't work
    compare: (title, [options]..., cb) =>
        options = @merge(options)
        $.ajax @merge options.ajax, complete: cb, data:
            action   : 'compare'
            fromtitle: title
            fromrev  : 1
            torev    : 2
    query: (titleOrTitles, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, complete: cb, data:
            action           : 'query'
            prop             : 'revisions'
            format           : 'json'
            rvprop           : 'ids|timestamp'
            rvlimit          : options.num
            # rvtoken          : 'rollback'
            rvcontentformat  : 'application/json'
            titles           : titleOrTitles
