define ['require', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers'], (require, $, JSON, api)->
    $('<div class="mw_wrapper">').appendTo('body > div')
    $('<div ng-app="motion_wiki" ng-controller="AppCtrl" id="motionwiki" class="mw_main" >').appendTo('.mw_wrapper')
    $('<mw-timeline>').appendTo('div#motionwiki')
    $('<mw-history-grapher>').appendTo('div#motionwiki')
    $('<mw-play-controls>').appendTo('div#motionwiki')

    # TODO: __DO NOT__ put paths in here like this! This is not portable!
    #       Should use templates to be filled in by Gruntfile for debug/release/deploy
    #       CSS should not be loaded like this either, use require-css!
    #       
    # TODO: /templates should be in /includes!
    $('<link rel="stylesheet" href="/includes/css/motionwiki.css">').appendTo('body')
    angular.module('motion_wiki', ['mw_directives','mw_controllers']).run [ '$rootScope' , ($rootScope)->
    	console.log $rootScope
    ]
    angular.bootstrap(document.getElementById('motionwiki'),['motion_wiki'])

    $('<div>').text('MotionWiki Loaded! Querying wiki...').appendTo('body > div')

    ###
    
    api.query 'Wikipedia', 'revisions', (jqXHR, textStatus)->

        for pageNum,page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                console.log "revision = #{JSON.stringify(revision, false, 100)}"
                $ourXML = $('<div>').html revision.diff["*"]
               # $ourXML.find('.diff-context > div').each -> console.log "ctx: #{$(@).html()}"
                
                $('<div>').css('color','blue').text("#{revision.diff.from} -> #{revision.diff.to}").appendTo('body > div')
                $('<div>').css('color', if jqXHR.status < 300 then 'green' else 'red')
                        .html(revision.diff["*"])
                        .appendTo('body > div')

    ###

    wikiText = ""
    parsedWikiText = []
    parsedWikiText.push "0-based accessor fix, ignore"

    # Need to change San_Francisco to whatever page user is on

    api.queryWikiTextContent 'San_Francisco', 'revisions', (jqXHR, textStatus)->
        for pageNum, page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                $('<div>').html(revision["*"]).appendTo('body > div')
                #$('<div>').html(JSON.stringify(revision["*"], false, 100)).appendTo('body > div')
                wikiText = revision["*"]

        #wikiText = JSON.stringify(revision["*"], false, 100)
        wikiText = 
        position = 0
        while position > -1
            position = wikiText.indexOf("\n")
            myStart = wikiText.substring(0, position)
            parsedWikiText.push myStart
            myEnd = wikiText.substring(position+1, wikiText.length)
            wikiText = myEnd
        
        console.log "outputing parsedWikiText"
        line = 0
        _wordcount = 0
        for textLine in parsedWikiText
            console.log "line #{line}: #{textLine}"
            _wordcount += textLine.split(" ").length
            line++

        console.log "wordcount = #{_wordcount}"

    timeStampArray = []

    # If user input is start date
    api.queryRevisionsinDateRangeUsingStartDate 'San_Francisco', 'revisions', (jqXHR, textStatus)->
        for pageNum, page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                timeStampArray.push revision["timestamp"]  

    
    # If user input is end date
    api.queryRevisionsinDateRangeUsingEndDate 'San_Francisco', 'revisions', (jqXHR, textStatus)->
        for pageNum, page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                timeStampArray.push revision["timestamp"]