define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers'], (require, _, $, JSON, api)->

    _.mixin toJSON: JSON.stringify

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
    

    parsedRevisions = []
    diffsForRevisions = [[]]
    recreatedPages = []
    counter = 0
    # Need to change San_Francisco to whatever page user is on
    
    page = 'Florida'
    $.when(
        api.query(page, 'revisions'),
        api.getWikiTextContent(page, 'revisions')
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
                    console.log "timestamp: #{revision.timestamp}"
                    diffHTML = "<table id='diffTable'>" + revision.diff["*"] + "<\\table>"
                    #$('<div>').html(revision.diff["*"]).appendTo('body > div')
                    position = 0
                    workingstring = ""
                    numTR = 0
                    table = $("diffTable")
                    #console.log "jQuery = #{$(diffHTML).find(".diff-context")}"
                    #$.proxy(-> $("tr"), diffHTML)          
                    #list = $(diffHTML).getElementsByTagName ("tr") ->
                    $($(diffHTML).find("tr, .diff-addedline, .diffchange, .diff-context, .diff-deletedline, .diff-empty, .diff-lineno, .diff-marker, .diffchange diffchange-inline")).each (index) ->
                       diffsForRevisions[counter][index] = [$(@).prop('class'), $(@).text()]  
                    #  console.log "#{index} :  #{$(@).prop('tagName')}#{$(@).prop('class')}#{$(@).text()}"
                    counter++
                    #console.log list
                    #for counter in diffsForRevisions
                    #    for index in counter
                    #        console.log index[0] + index[1]

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
            console.log "parsedRevisions.length = #{parsedRevisions[0].length}"

            # for revision in parsedRevisions
            #     line = 0
            #     _wordcount = 0
            #     for textLine in revision
            #         #console.log "line = #{line}"
            #         #$('<div>').html("line #{line}: #{textLine}").appendTo('body > div')
            #         _wordcount += textLine.split(" ").length
            #         line++
        
        line = 0
        diffType = ""
        diffContextLine = ""
        diffDeletedLine = ""
        diffAddedLine = ""
        lastModifiedLine = 0

        for counter in diffsForRevisions
            diffMarkerMod = 0
            deletedAddLineToggle = false
            diffContextToggle = 0
            for index in counter
                
                if index[0] == 'diff-lineno'
                    index[1] = index[1].substring(5, index[1].indexOf(':'))
                    postition = 0
                    while position > -1
                        position = index[1].indexOf(",")
                        myStart = index[1].substring(0, position)
                        myEnd = index[1].substring(position+1, index[0].length)
                        index[1] = myStart + myEnd
                    line = parseInt(index[1], 10)
                    continue
                if index[0] == 'diff-marker'
                    if index[1] == '&#160' 
                        diffType = 'Context'
                        continue
                    else if index[1] = '+'
                        diffType = 'Add'
                        continue
                    else 
                        diffType = '\\u2212'
                        continue
                if index[0] == 'diff-context'
                    diffContextLine = index[1]
                    #console.log "context line #{line}: #{diffContextLine}"

                if index[0] == 'diff-deletedline'
                    diffDeletedLine = index[1]
                    #console.log "deleted line #{line}: #{diffDeletedLine}"
                    newline = parsedRevisions[0][line]
                    newline = "<font color='red'>" + newline + "</font>"
                    
                    parsedRevisions[0][line] = newline
                    if deletedAddLineToggle is false
                        lastModifiedLine = line
                        deletedAddLineToggle = true
                    else if lastModifiedLine = line
                        console.log "modified line at #{lastModifiedLine}"
                        deletedAddLineToggle = false
                        #line++
                    else
                        console.log "deleted line at #{lastModifiedLine}"
                        deletedAddLineToggle = false
                        #line++

                if index[0] == 'diff-addedline'
                    diffAddedLine = index[1]
                    newline = parsedRevisions[0][line]
                    newline = "<font color='green'>" + diffAddedLine + "</font>"
                    parsedRevisions[0][line] = newline
                    lastModifiedLine = line
                    if deletedAddLineToggle is false
                        lastModifiedLine = line
                        deletedAddLineToggle = true
                    else if lastModifiedLine = line
                        console.log "modified line at #{lastModifiedLine}"
                        deletedAddLineToggle = false
                        #line++
                    else
                        console.log "added line at #{lastModifiedLine}"
                        deletedAddLineToggle = false
                        #line++

        for revision in parsedRevisions
                line = 0
                for textLine in revision
                    #console.log "line = #{line}"
                    $('<div>').html("line #{line}: #{textLine}").appendTo('body > div')
                    line++




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

