define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers', 'Animation'], (require, _, $, JSON, api, directives, controllers, animate)->

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
    diffsForRevisions = []
    recreatedPages = []
    animations = []
    counter = 0
    console.log "diffsForRevisions.length = #{diffsForRevisions.length}"
    baseRevision = 3
    # Need to change San_Francisco to whatever page user is on

    delimiter = randomDelimiterGenerator()
    textToParse = ""
    
    page = 'Florida'
    $.when(
        api.query(page, 'revisions'),
        api.getWikiTextContent(page, 'revisions')
    ).done (r1, r2) ->
        # http://api.jquery.com/jQuery.when/
        #   a1 and a2 are arguments resolved for the page1 and page2 ajax requests, respectively.
        # Each argument is an array with the following structure: [ data, statusText, jqXHR ]
        console.log "DONE!"

        #takes page title as input, generates the diffArray for the last 5 revisions of the corresponding page
        #splits up the diffArray by line for each html element generated
        do ([data, textStatus, jqXHR]=r1) ->
            for pageNum, page of jqXHR.responseJSON.query.pages
                console.log "page.revisions.length = #{page.revisions.length}"
                counter = 0
                for revision in page.revisions
                    
                    #console.log "timestamp: #{revision.timestamp}, counter = #{counter}"
                    #$('<div>').html(revision.diff["*"]).appendTo('body > div')
                    diffHTML = "<table id='diffTable'>" + revision.diff["*"] + "<\\table>"
                    #diffHTML = revision.diff["*"]
                    
                    position = 0
                    workingstring = ""
                    numTR = 0
                    table = $("diffTable")
                    #console.log "ok"

                    diffArray = []
                    #if counter is baseRevision
                        #$('<div>').html(diffHTML).appendTo('body > div')
   
                    $($(diffHTML).find("tr, span, .diff-addedline, .diffchange, .diff-context, .diff-deletedline, .diff-empty, .diff-lineno, .diff-marker, .diffchange diffchange-inline")).each (index) ->
                        
                        if $(@).prop('tagName') == "SPAN"
                           #console.log "#{$(@).text()}"
                           
                           #myDiff.push
                        #Add all of the entries for each diff block, separated by tag
                        else
                            myDiff = [$(@).prop('class'), $(@).text(), revision.timestamp]
                            myDiff[0] = [$(@).prop('tagName')] + ":"  + myDiff[0]
                            console.log "Adding tag: #{$(@).prop('tagName')}"
                            diffArray.push myDiff
                        #console.log "diffsForREvisions.length = #{diffsForRevisions.length}"
                        
                        #diffsForRevisions[counter].push myDiff

                        
                        #console.log "myDiff = #{myDiff}"
                        
                        #Gives us the diff for every revision being evaluated in DESCENDING TIME ORDER
                    diffsForRevisions.push diffArray
                    #console.log "diffsForRevisions.length = #{diffsForRevisions.length}"
                    counter++
        
        #takes the title of the page as input, produces the body text of the wikipedia page at the current revision
        #split up line by line in an array called parsedRevisions
        do ([data, textStatus, jqXHR]=r2) ->

            
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

                    


                    #wikiText = revision["*"]


                #wikiText = JSON.stringify(revision["*"], false, 100)
                    position = 0



                    while position > -1
                        position = wikiText.indexOf("\n")
                        myStart = wikiText.substring(0, position)
                        parsedWikiText.push myStart
                        myEnd = wikiText.substring(position+1, wikiText.length)
                        wikiText = myEnd
                        parsedWikiText = parsedWikiText
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
        


        revIndex = 0
        for revision in parsedRevisions
                line = 0
                console.log "revision.length = #{revision.length}"
                if revIndex is baseRevision
                    html = ""
                    console.log "revision[0] = #{revision[0]}"
                    for textLine in revision
                        html += textLine
                        #console.log "line = #{line}"
                        textLine = '<motionwiki line="' + line + '">' + textLine + '</motionwiki>'
                        $('<div>').html(textLine).appendTo('body > div')
                        #console.log "line #{line}: #{textLine}"
                        line++
                    #console.log "html = #{html}"
                    #api.parseToHTML html, (jqXHR) ->
                    #    console.log "jqXHR = #{jqXHR}"
                revIndex++

        console.log "after callback block"
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

        

        #Wraps each added or deleted line in an animation tag for greensock (right now, just wrapped as html tags)
        #Goes through each diff text
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
            pureDelete = false
            lastGreensockAnimationTag = ""
            lastGreensockAnimationArg = ""
            lastline = 0
            lastUniqueTagIdentifier = 
            #if our current revision diff text is equal to our baseRevision (the revision we are currently viewing animations for)
            if revIndex is baseRevision
                console.log "nextRev timestamp: #{revision[0][2]}"
                uniqueTagIdentifier = 0
                jQueryText = ""


                #for each row in our array of diffs
                for index in revision
                    _continue = true
                    doDelete = false
                    tagIndex = 0
                    tagIndex = index[0].indexOf(':')
                    tag = index[0].substring(0, tagIndex)
                    index[0] = index[0].substring(tagIndex+1, index[0].length)
                    greensockAnimationTag = ""
                    greensockAnimationArg = ""
                    doAnimation = false
                    wasDelete = false
                    

                    #if we are inside the diff block
                    if getDiffLineNo is true
                        if tag is 'TR'
                            #get to the correct line
                            numLinesToAdd++
                            console.log "numLinesToAdd = #{numLinesToAdd}"

                    #get starting line number for diff
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

                    #useless
                    if index[0] == 'diff-marker'
                        if index[1] == '&#160' 
                            diffType = 'Context'
                            
                        else if index[1] = '+'
                            diffType = 'Add'
                            
                        else 
                            diffType = '\\u2212'
                            
                    #useless
                    if index[0] == 'diff-context'
                        diffContextLine = index[1]
                        #console.log "context line #{line}: #{diffContextLine}"
                    #if we are deleting a line
                    if index[0] == 'diff-deletedline'
                        #if it is not an inline modification
                        if modifyToggle is true
                            if pureDelete is true
                                pureDelete = false
                                console.log "PureDeleting line at #{lastline}"
                                numTimesDeleted++
                                greensockAnimationTag = lastGreensockAnimationTag
                                parsedRevisions[revIndex][lastline] = greensockAnimationTag
                                greensockAnimationArg = 'motionwikiDeletion'
                                finalline = lastline
                                console.log "line = #{finalline}, motionwiki[line=#{finalline}] = #{$("motionwiki[line=" + finalline + "]").text()}"
                                $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                                greensockAnimationId = "#" + greensockAnimationArg + lastUniqueTagIdentifier
                                console.log "uniqueTagIdentifier = #{lastUniqueTagIdentifier}"
                                animate.doAnimate(greensockAnimationId, greensockAnimationArg.substring(0, greensockAnimationArg.length ), $('span[id="' + greensockAnimationArg + lastUniqueTagIdentifier + '"]'), true)
                                console.log "greensockAnimationId = #{greensockAnimationId}, greensockAnimationArg = #{greensockAnimationArg}"

                                uniqueTagIdentifier++



                                lastGreensockAnimationTag = ""
                                lastGreensockAnimationArg = ""
                                lastline = 0

                            #odifyToggle = false
                            console.log "Deleting line at #{line + numLinesToAdd}"
                            numTimesDeleted++
                            greensockAnimationTag = '<span id = "motionwikiDeletion' + uniqueTagIdentifier + '">' + parsedRevisions[revIndex][line + numLinesToAdd] + '</span>'
                            parsedRevisions[revIndex][line + numLinesToAdd] = greensockAnimationTag
                            greensockAnimationArg = 'motionwikiDeletion'
                            finalline = line + numLinesToAdd
                            finalline = finalline
                            console.log "line = #{line}, motionwiki[line=#{finalline}] = #{$("motionwiki[line=" + finalline + "]").text()}"
                            $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                            doAnimation = true
                            wasDelete = true

                        else
                            modifyToggle = true
                            pureDelete = true
                        
                        #delete line

                        #jQueryText = parsedRevisions[revIndex][line + numLinesToAdd]

                        lastGreensockAnimationTag = '<span id = "motionwikiDeletion' + uniqueTagIdentifier + '">' + parsedRevisions[revIndex][line + numLinesToAdd] + '</span>'
                        lastline = line + numLinesToAdd
                        lastUniqueTagIdentifier = uniqueTagIdentifier
                        lastGreensockAnimationArg = 'motionwikiDeletion'
                        doDelete = true
                        
                        
                    #If modifyToggle is true, we know the last action to happen was a deletion.
                    if index[0] == 'diff-addedline'
                        #if it is not an inline modification
                        if modifyToggle is false
                            #numTimesDeleted--
                            console.log "Adding line at #{line + numLinesToAdd}"
                            jQueryText = parsedRevisions[revIndex][line + numLinesToAdd]
                            addedLineText = ""
                            if index[1] == ""
                                addedLineText = "(ADDED LINE)"

                            text = '<span id ="motionwikiAddition' + uniqueTagIdentifier + '">' + index[1] + "</span>"
                            greensockAnimationArg = 'motionwikiAddition'
                            greensockAnimationTag = text
                            parsedRevisions[revIndex].splice(line + numLinesToAdd, 0, text)
                            finalline = line + numLinesToAdd
                            finalline = finalline
                            console.log "motionwiki[line=#{finalline}] = #{$("motionwiki[line=" + finalline + "]").text()}"
                            $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                            doAnimation = true
                        #if it is an inline modification
                        else
                            console.log "Modifying line at #{line + numLinesToAdd}"
                            jQueryText = parsedRevisions[revIndex][line + numLinesToAdd]
                            text = '<span id="motionwikiModification' + uniqueTagIdentifier + '">' + index[1] + "</span>"
                            greensockAnimationArg = 'motionwikiModification'
                            greensockAnimationTag = text
                            parsedRevisions[revIndex].splice(line + numLinesToAdd, 0, text)
                            finalline = line + numLinesToAdd
                            finalline = finalline
                            console.log "line = #{line}, numLinesToAdd = #{numLinesToAdd}, motionwiki[line=#{finalline}] = #{$("motionwiki[line=" + finalline + "]").text()}"
                            console.log "typeof $() = #{typeof($("motionwiki[line=" + finalline + "]"))}"
                            $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                            modifyToggle = false
                            doAnimation = true
                            #parsedRevisions[revIndex][line +  numLinesToAdd] = text

                    


                    ###DO ANIMATIONS HERE###
                    if doAnimation is true
                        greensockAnimationId = "#" + greensockAnimationArg + uniqueTagIdentifier
                        if wasDelete is true
                            _continue = false
                            animate.doAnimate(greensockAnimationId, greensockAnimationArg.substring(0, greensockAnimationArg.length ),  $('span[id="' + greensockAnimationArg + lastUniqueTagIdentifier + '"]'), false, () ->
                                console.log "greensockAnimationId = #{greensockAnimationId}, greensockAnimationArg = #{greensockAnimationArg}"
                                if doDelete
                                    parsedRevisions[revIndex].splice(line + numLinesToAdd - numTimesDeleted, 1)

                                
                                _continue = true
                                )
                            console.log "After animations"
                        else
                            console.log "greensockAnimationId = #{greensockAnimationId}, greensockAnimationArg = #{greensockAnimationArg}, uniqueTagIdentifier = #{uniqueTagIdentifier}"
                            console.log "$() = #{typeof($('span[id=' + greensockAnimationArg + uniqueTagIdentifier + "]"))}"
                            animate.doAnimate(greensockAnimationId, greensockAnimationArg.substring(0, greensockAnimationArg.length ),  $('span[id="' + greensockAnimationArg + uniqueTagIdentifier + '"]'), false, () ->
                                console.log "animation callback"
                                if doDelete
                                    parsedRevisions[revIndex].splice(line + numLinesToAdd - numTimesDeleted, 1)

                                
                                _continue = true
                                console.log "_continue = true"
                                )
                            console.log "After animations"

                    console.log "after callback"
                    uniqueTagIdentifier++
                    ###
                    if doDelete
                        parsedRevisions[revIndex].splice(line + numLinesToAdd - numTimesDeleted, 1)

                    uniqueTagIdentifier++
                    ###


        revIndex = 0
        for revision in parsedRevisions
                line = 0
                console.log "revision.length = #{revision.length}"
                if revIndex is baseRevision
                    html = ""
                    console.log "revision[0] = #{revision[0]}"
                    for textLine in revision
                        html += textLine
                        #console.log "line = #{line}"
                        $('<div>').html("line #{line}: #{textLine}").appendTo('body > div')
                        #console.log "line #{line}: #{textLine}"
                        line++
                    #console.log "html = #{html}"
                    #api.parseToHTML html, (jqXHR) ->
                    #    console.log "jqXHR = #{jqXHR}"
                revIndex++

    
        ###
        for revision in parsedWikiText
            for line in revision
                line += delimiter
                textToParse += line
        ###

randomDelimiterGenerator = () ->
        text = ""
        possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

        counter = 0
        while counter++ < 8
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

