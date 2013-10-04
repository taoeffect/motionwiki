define ['require', 'jquery', 'JSON', 'wiki/api'], (require, $, JSON, api)->
    console.log "hello world - main!"
    $('<div>').text('MotionWiki Loaded! Querying wiki...').appendTo('body > div')
    api.query 'Wikipedia', (jqXHR, textStatus)->
        $('<div>').css('color',if jqXHR.status < 300 then 'green' else 'red')
            .html(textStatus + ": <pre style='width:400'>" + JSON.stringify(jqXHR,false,100) + "</pre>")
            .appendTo('body > div')