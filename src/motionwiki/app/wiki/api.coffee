# sandbox: http://en.wikipedia.org/wiki/Special:ApiSandbox

define ['jquery', 'lodash'], ($,_) ->
    # just an example. this will return an object.
    # TEST FLAGS AND WRAPPERS TO PREVENT MULTIPLE AJAX CALLBACKS

    newQueryCall = true

    setNewQueryCallFalse: ->
        newQueryCall = false

    setNewQueryCallTrue: ->
        newQueryCall = true

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
                console.log "ajax complete"
                cb(jqXHR, textStatus) if cb
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

    getWikiTextContent: (titleOrTitles, prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus)->
                # do our pre-processing (if any)
                console.log "ajax complete"
                cb(jqXHR, textStatus) if cb
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'content'
                rvlimit          : '2'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }



#    Querying for timestamps is so fast we could make the
#    query before the second date is selected?
#    Also, since 500 timestamps is the maximum, we could black 
#    out dates on the calendar past the last timestamp in the range?
    queryRevisionsInDateRangeUsingStartDate: (titleOrTitles,prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus) ->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp|size'
                rvlimit          : 500
                rvstart          : datepicker1.date
                rvdir            : 'newer'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }

    queryRevisionsInDateRangeUsingEndingDate: (titleOrTitles,prop, [options]..., cb) =>
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = @merge(options)
        $.ajax @merge options.ajax, {
            complete: (jqXHR, textStatus) ->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp|size'
                rvlimit          : 500
                rvstart          : datepicker2.date
                rvdir            : 'newer'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }