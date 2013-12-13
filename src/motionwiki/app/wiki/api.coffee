# sandbox: http://en.wikipedia.org/wiki/Special:ApiSandbox

define ['jquery', 'lodash'], ($,_) ->
    # just an example. this will return an object.
    # TEST FLAGS AND WRAPPERS TO PREVENT MULTIPLE AJAX CALLBACKS

    newQueryCall = true

    # randInt = (min=10, max=10000000) -> Math.floor(Math.random() * (max - min + 1) + min)

    setNewQueryCallFalse: ->
        newQueryCall = false

    setNewQueryCallTrue: ->
        newQueryCall = true

    defaults =
        num : 5
        ajax: 
            url: 'https://en.wikipedia.org/w/api.php'
            dataType: '<%= G.mode().jsonType %>'
            # cache: true

    console.log "Using json type: #{defaults.ajax.dataType}"

    # haven't tested 'compare'... it probably doesn't work
    compare: (revid1, revid2, [options]..., cb) ->
        options = $.extend {}, defaults, options or {}
        $.ajax $.extend {}, options.ajax, {
            complete: cb
            data:
                action   : 'compare'
                fromid   : revid1
                toid     : revid2
        }
    query: (titleOrTitles, prop, [options]..., cb) ->
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = $.extend {}, defaults, options or {}
        $.ajax $.extend {}, options.ajax, {
            complete: (jqXHR, textStatus)->
                # do our pre-processing (if any)
                # console.log "ajax complete"
                #console.log "api.query: #{_(jqXHR).stringify()}"
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
                rvdiffto         : 'next'
                titles           : titleOrTitles
                # "_"              : randInt()
        }

    getWikiTextContent: (titleOrTitles, prop, [options]..., cb) ->
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = $.extend {}, defaults, options or {}
        console.log "getWikiTextContent options: " + _(options).stringify()
        $.ajax $.extend {}, options.ajax, {
            complete: (jqXHR, textStatus)->
                # do our pre-processing (if any)
                # console.log "ajax complete"
                #console.log "api.queryWikiTextContent: #{_(jqXHR).stringify()}"
                cb(jqXHR, textStatus) if cb
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'content|timestamp'
                rvlimit          : options.num
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
                # "_"              : randInt()
        }

    parseToHTML: (inputText, [options]..., cb) ->
        options = $.extend {}, defaults, options or {}
        $.ajax $.extend {}, options.ajax, {
            type: 'POST'
            complete: (jqXHR, textStatus) ->
                # do our pre-processing (if any)
                # console.log "ajax complete"
                #console.log "api.queryWikiTextContent: #{_(jqXHR).stringify()}"
                cb(jqXHR, textStatus) if cb
            data:
                action           : 'parse'
                format           : 'json'
                text             : inputText
                prop             : 'text'
                rvcontentformat  : 'text/x-wiki'
        }

#    Querying for timestamps is so fast we could make the
#    query before the second date is selected?
#    Also, since 500 timestamps is the maximum, we could black 
#    out dates on the calendar past the last timestamp in the range?
    queryRevisionsInDateRangeUsingStartDate: (titleOrTitles,prop, [options]..., cb) ->
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = $.extend {}, defaults, options or {}
        $.ajax $.extend {}, options.ajax, {
            complete: (jqXHR, textStatus) ->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp|size'
                rvlimit          : "500"
                rvstart          : datepicker1.date
                rvdir            : 'newer'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }

    queryRevisionsInDateRangeUsingEndingDate: (titleOrTitles,prop, [options]..., cb) ->
        titleOrTitles = titleOrTitles.join('|') if typeof titleOrTitles != 'string'
        options = $.extend {}, defaults, options or {}
        $.ajax $.extend {}, options.ajax, {
            complete: (jqXHR, textStatus) ->
                # do our pre-processing (if any)
                cb(jqXHR, textStatus)
            data:
                action           : 'query'
                prop             : prop
                format           : 'json'
                rvprop           : 'timestamp|size'
                rvlimit          : "500"
                rvstart          : datepicker2.date
                rvdir            : 'newer'
                # rvexpandtemplates: true
                # rvtoken          : 'rollback'
                rvcontentformat  : 'text/x-wiki'
                titles           : titleOrTitles
        }