define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'wiki/data'], (require, _, $, JSON, api, data)->

    _.mixin toJSON: JSON.stringify

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

    parsedRevisions = []
    diffsForRevisions = [[]]
    recreatedPages = []
    counter = 0
    # Need to change San_Francisco to whatever page user is on
    
    $.when(
        api.query('San_Francisco', 'revisions'),
        api.getWikiTextContent('San_Francisco', 'revisions')
    ).done (r1, r2) ->
        # http://api.jquery.com/jQuery.when/
        #   a1 and a2 are arguments resolved for the page1 and page2 ajax requests, respectively.
        # Each argument is an array with the following structure: [ data, statusText, jqXHR ]
        console.log "DONE!"

        do ([data, textStatus, jqXHR]=r1) ->
            for pageNum, page of jqXHR.responseJSON.query.pages
                console.log "query page"
                for revision in page.revisions
                    counter = 0
                    console.log "query.revision"
                    diffHTML = revision.diff["*"]
                    $('<div>').html(revision.diff["*"]).appendTo('body > div')
                    position = 0
                    workingstring = ""
                    numDiffContext = 0

                    #console.log "jQuery = #{$(diffHTML).find(".diff-context")}"

                    $($(diffHTML).find(" .diff-addedline, .diffchange, .diff-context, .diff-deletedline, .diff-empty, .diff-lineno, .diff-marker, .diffchange diffchange-inline")).each (index) ->
                        diffsForRevisions[counter][index] = [$(@).prop('class'), $(@).text()]  
                        #console.log "#{index} :  #{$(@).prop('class')}, #{$(@).text()}"
                    counter++

                    for counter in diffsForRevisions
                        for index in counter
                            console.log index[0] + index[1]

                    #diffsForRevisions.push $($(diffHTML).find(" .diff-addedline, .diffchange, .diff-context, .diff-deletedline, .diff-empty, .diff-marker, .diffchange diffchange-inline"))
                    #diffMarker = $(diffHTML).find(".diff-context, .diff-marker").text()
                    #diffContext = $(diffHTML).find(".diff-context").text()

                    #console.log diffMarker


            # get Data and do stuff
            # wikiText = "success"
            # data.setDiffTextReturnToTrue()
            # console.log "api.query: #{_(jqXHR).toJSON()}"
        


        do ([data, textStatus, jqXHR]=r2) ->
            # console.log "api.queryWikiTextContent: #{_(jqXHR).toJSON()}"
            for pageNum, page of jqXHR.responseJSON.query.pages
                # console.log "page: #{_(page).toJSON()}"

                counter = 0
                for revision in page.revisions
                    console.log "counter = #{counter}"
                    if counter == 1
                        parsedWikiText = []
                        parsedWikiText.push "0-based accessor fix, ignore"
                        #$('<div>').html(revision["*"]).appendTo('body > div')
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
                    #console.log "counter = #{counter}"


            for revision in parsedRevisions
                line = 0
                _wordcount = 0
                for textLine in revision
                    console.log "line #{line}: #{textLine}"
                    _wordcount += textLine.split(" ").length
                    line++
            #data.setParsedWikiTextReturnToTrue()

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

