define ['require', 'jquery', 'JSON', 'wiki/api', 'wiki/data', this], (require, $, JSON, api, data, _this)->
    $('<div class="mw_wrapper">').appendTo('body > div')
    ###
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
    ###

    

    # Need to change San_Francisco to whatever page user is on
    


    api.query 'San_Francisco', 'revisions', (jqXHR, textStatus) ->
            # get Data and do stuff
        wikiText = "success"
        data.setDiffTextReturnToTrue()
        console.log "api.query callback complete"
    
    console.log "api.query complete"

    

    parsedRevisions = []
    
    api.getWikiTextContent 'San_Francisco', 'revisions', (jqXHR, textStatus) ->
        console.log "api.queryWikiTextContent"
        for pageNum, page of jqXHR.responseJSON.query.pages
            counter = 0
            for revision in page.revisions
                console.log "counter = #{counter}"
                if counter == 1
                    parsedWikiText = []
                    parsedWikiText.push "0-based accessor fix, ignore"
                    $('<div>').html(revision["*"]).appendTo('body > div')
                    #$('<div>').html(JSON.stringify(revision["*"], false, 100)).appendTo('body > div')
                    wikiText = revision["*"]

                #wikiText = JSON.stringify(revision["*"], false, 100)
                    position = 0
                    while position > -1
                        position = wikiText.indexOf("\n")
                        myStart = wikiText.substring(0, position)
                        parsedWikiText.push myStart
                        myEnd = wikiText.substring(position+1, wikiText.length)
                        wikiText = myEnd
                    parsedRevisions.push parsedWikiText
                counter++
                console.log "counter = #{counter}"

        for revision in parsedRevisions
            line = 0
            _wordcount = 0
            for textLine in revision
                console.log "line #{line}: #{textLine}"
                _wordcount += textLine.split(" ").length
                line++
        data.setParsedWikiTextReturnToTrue()
            
    ###
    
    

    timeStampArray = []

    # If user input is start date
    # Gets timestamps and byte counts for 500 revisions after start date
    api.queryRevisionsinDateRangeUsingStartDate 'San_Francisco', 'revisions', (jqXHR, textStatus)->
        for pageNum, page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                timeStampArray.push [revision["timestamp"], revision["size"]]

        counter = 0

        for timeStamp in timeStampArray
            if timeStamp[0] <= datepicker2.date
                counter++
            else
                break

        timeStampArray = timeStampArray[0...counter]

    # If user input is end date
    # Gets timestamps and byte counts for 500 revisions before end date
    api.queryRevisionsinDateRangeUsingEndDate 'San_Francisco', 'revisions', (jqXHR, textStatus)->
        for pageNum, page of jqXHR.responseJSON.query.pages
            for revision in page.revisions
                timeStampArray.push [revision["timestamp"], revision["size"]]

        counter = 0

        for timeStamp in timeStampArray
            if timeStamp[0] < datepicker1.date
                counter++
            else
                break

        timeStampArray = timeStampArray[counter...timeStampArray.length]

    ###

