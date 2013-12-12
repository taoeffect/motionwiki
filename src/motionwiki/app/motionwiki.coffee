define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers', 'bootstrap_datepicker'], (require, _, $, JSON, api)->

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
    angular.module('motion_wiki', ['mw_directives','mw_controllers']).run [ '$rootScope' , ($rootScope)->
    	console.log $rootScope
    ]
    angular.bootstrap(document.getElementById('motionwiki'),['motion_wiki'])

    parsedRevisions = []
    diffsForRevisions = []
    recreatedPages = []
    counter = 0
    console.log "diffsForRevisions.length = #{diffsForRevisions.length}"
    baseRevision = 4
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
                console.log "page.revisions.length = #{page.revisions.length}"
                counter = 0
                for revision in page.revisions
                    
                    #console.log "timestamp: #{revision.timestamp}, counter = #{counter}"
                    #$('<div>').html(revision.diff["*"]).appendTo('body > div')
                    diffHTML = "<table id='diffTable'>" + revision.diff["*"] + "<\\table>"
                    
                    position = 0
                    workingstring = ""
                    numTR = 0
                    table = $("diffTable")
                    #console.log "ok"

                    diffArray = []
                    if counter is baseRevision
                        $('<div>').html(diffHTML).appendTo('body > div')
                    $($(diffHTML).find("tr, span, .diff-addedline, .diffchange, .diff-context, .diff-deletedline, .diff-empty, .diff-lineno, .diff-marker, .diffchange diffchange-inline")).each (index) ->
                        
                        if $(@).prop('tagName') == "SPAN"
                           console.log "#{$(@).text()}"
                           
                           #myDiff.push
                        else
                            myDiff = [$(@).prop('class'), $(@).text(), revision.timestamp]
                            myDiff[0] = [$(@).prop('tagName')] + ":"  + myDiff[0]
                            diffArray.push myDiff
                        #console.log "diffsForREvisions.length = #{diffsForRevisions.length}"
                        
                        #diffsForRevisions[counter].push myDiff

                        
                        #console.log "myDiff = #{myDiff}"
                        
                        #Gives us the diff for every revision being evaluated in DESCENDING TIME ORDER
                    diffsForRevisions.push diffArray
                    #console.log "diffsForRevisions.length = #{diffsForRevisions.length}"
                    counter++
        
        do ([data, textStatus, jqXHR]=r2) ->
            # console.log "api.queryWikiTextContent: #{_(jqXHR).toJSON()}"
            for pageNum, page of jqXHR.responseJSON.query.pages
                # console.log "page: #{_(page).toJSON()}"

                counter = 0
                for revision in page.revisions
                    console.log "counter = #{counter}"
                    #console.log "jqXHR: #{JSON.stringify(revision, 100, false)}"
                    
                    console.log "timestamp = #{revision.timestamp}"
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
            console.log "parsedRevisions.length = #{parsedRevisions.length}"

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
        lastModifiedLine = ""
        lastLine = 0
        newline = ""
        wasDeleted = false
        revisionNumber = -1
        revIndex = -1
        modifyToggle = false

        for revision in diffsForRevisions
            diffMarkerMod = 0
            deletedAddLineToggle = false
            diffContextToggle = 0
            getDiffLineNo = false
            numLinesToAdd = -1
            revIndex++
            console.log "!revision.length = #{revision.length}"
            console.log "parsedRevisions[#{revIndex}].length = #{parsedRevisions[revIndex].length}"
            numTimesDeleted = 0
            if revIndex is baseRevision
                console.log "nextRev timestamp: #{revision[0][2]}"
                for index in revision
                    
                    tagIndex = 0
                    tagIndex = index[0].indexOf(':')
                    tag = index[0].substring(0, tagIndex)
                    index[0] = index[0].substring(tagIndex+1, index[0].length)

                    if getDiffLineNo is true
                        if tag is 'TR'
                            numLinesToAdd++

                    if index[0] == 'diff-lineno'
                        getDiffLineNo = true
                        index[1] = index[1].substring(5, index[1].indexOf(':'))
                        position = 0
                        numLinesToAdd = -1
                        while position > -1
                            position = index[1].indexOf(",")
                            myStart = index[1].substring(0, position)
                            myEnd = index[1].substring(position+1, index[1].length)
                            index[1] = myStart + myEnd
                        line = parseInt(index[1], 10)
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
                        if modifyToggle is true
                            #odifyToggle = false
                            console.log "Deleting line at #{line + numLinesToAdd}"
                            numTimesDeleted++
                        else
                            modifyToggle = true
                        
                        parsedRevisions[revIndex].splice(line + numLinesToAdd - numTimesDeleted, 1)
                        
                        #parsedRevisions[revIndex][line +  numLinesToAdd] = "DELETED"
                    if index[0] == 'diff-addedline'
                        if modifyToggle is false
                            #numTimesDeleted--
                            console.log "Adding line at #{line + numLinesToAdd}"
                            text = '<font color="green">' + index[1] + "</font>"
                            parsedRevisions[revIndex].splice(line + numLinesToAdd, 0, text)
                        else
                            console.log "Modifying line at #{line + numLinesToAdd}"
                            
                            text = '<font color="orange">' + index[1] + "</font>"
                            parsedRevisions[revIndex].splice(line + numLinesToAdd, 0, text)
                            modifyToggle = false
                            #parsedRevisions[revIndex][line +  numLinesToAdd] = text



        revIndex = 0
        for revision in parsedRevisions
                line = 0
                console.log "revision.length = #{revision.length}"
                if revIndex is baseRevision
                    console.log "revision[0] = #{revision[0]}"
                    for textLine in revision

                        #console.log "line = #{line}"
                        $('<div>').html("line #{line}: #{textLine}").appendTo('body > div')
                        #console.log "line #{line}: #{textLine}"
                        line++
                revIndex++

    delimiter = randomDelimiterGenerator()
    textToParse = ""

    for revision in parsedWikiText
        for line in revision
            line += delimiter
            textToParse.push line

randomDelimiterGenerator = () ->
        text = ""
        possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

        counter = 0
        while counter < 8
            text += possible.charAt(Math.floor(Math.random() * possible.length))
            counter++

        return text


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
