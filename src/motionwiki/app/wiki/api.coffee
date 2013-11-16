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
    compare: (revid1, revid2, [options]..., cb) =>
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: cb
            data:
                action   : 'compare'
                fromid   : revid1
                toid     : revid2
        }
    query: (titleOrTitles, prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus)->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             :  prop
                format           : 'json'
                rvlimit          : options.num
                rvprop           : 'ids|timestamp'
                # rvprop           : 'ids|timestamp|content'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'application/json'
                rvdiffto         : 'prev'
                titles           : titleOrTitles
        }

    queryWikiTextContent: (titleOrTitles, prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus)->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'content'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }

    # Querying for timestamps is so fast we could make the
    # query before the second date is selected?
    queryRevisionsInDateRangeUsingStartDate: (titleOrTitles, prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus)->
                #do our pre-processing (if any)
                cb(jqXHR,textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp'
                rvlimit          : 500
                rvstart          : datePickerStartDate
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }

    queryRevisionsInDateRangeUsingEndDate: (titleOrTitles, prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus)->
                #do our pre-processing (if any)
                cb(jqXHR,textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp'
                rvlimit          : 500
                rvstart          : datePickerStartDate
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }