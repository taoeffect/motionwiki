define ['require', 'jquery', 'JSON', 'wiki/api', 'parseManager'], (require, $, JSON, api, parseManager)->
    console.log "hello world - main!"
    $('<div>').text('MotionWiki Loaded! Querying wiki...').appendTo('body > div')
    #api.query 'Wikipedia', 'revisions', (jqXHR, textStatus)->
    #    parseManager.parseData jqXHR, 'compare', textStatus
    api.query 'Wikipedia', 'revisions', (jqXHR, textStatus)->
    	parseManager.parseData jqXHR, 'diffs', textStatus		

    	
