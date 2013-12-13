define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers', 'Animation'], (require, _, $, JSON, api, directives, controllers, animate)->

    _.mixin stringify: JSON.stringify

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
    baseRevision = 4
    # Need to change San_Francisco to whatever page user is on

    randomDelimiterGenerator = () ->
        text = "ASDLIFJ"
        possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

        counter = 0
        while counter++ < 8
            text += possible.charAt(Math.floor(Math.random() * possible.length))
            counter++
        return text

    delimiter = randomDelimiterGenerator()
    textToParse = ""
    
    page = 'Constitution Party of Georgia'
    $.when(
        api.query(page, 'revisions'),
        api.getWikiTextContent(page, 'revisions', num:1, undefined)
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
                for revision in page.revisions
                   # console.log "revisions: #{revision.diff["*"]}"
                   diffsForRevisions.push $('<table>').html(revision.diff["*"]).children()

        #takes the title of the page as input, produces the body text of the wikipedia page at the current revision
        #split up line by line in an array called parsedRevisions
        do ([data, textStatus, jqXHR]=r2) ->
            for pageNum, page of jqXHR.responseJSON.query.pages
                for revision in page.revisions
                    wikiText = revision["*"].replace(/[\n]/g, delimiter).substring(0, 5000)

                # send this wikitext back
                api.parseToHTML wikiText, (jqXHR, textStatus)->
                    wikiHTML = jqXHR.responseJSON.parse.text["*"]
                    console.log "got back parsed html:\n#{wikiHTML}"
                    counter = 1
                    htmlLines = _(wikiHTML.split(delimiter)).map((line)-> "<div><b>LINE #{counter++}:</b> #{line}</div>").join('')
                    $("<div>").html(htmlLines).appendTo('body')





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
                        textLine = '<motionwiki line="' + line + '">' + textLine + '</motionwiki>'
                        $('<div>').html("line #{line}: #{textLine}").appendTo('body > div')
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
            #if our current revision diff text is equal to our baseRevision (the revision we are currently viewing animations for)
            if revIndex is baseRevision
                console.log "nextRev timestamp: #{revision[0][2]}"
                uniqueTagIdentifier = 0
                jQueryText = ""

                #for each row in our array of diffs
                for index in revision
                    doDelete = false
                    tagIndex = 0
                    tagIndex = index[0].indexOf(':')
                    tag = index[0].substring(0, tagIndex)
                    index[0] = index[0].substring(tagIndex+1, index[0].length)
                    greensockAnimationTag = ""
                    greensockAnimationArg = ""
                    doAnimation = false

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
                            #odifyToggle = false
                            console.log "Deleting line at #{line + numLinesToAdd}"
                            numTimesDeleted++

                        else
                            modifyToggle = true
                        
                        #delete line

                        jQueryText = parsedRevisions[revIndex][line + numLinesToAdd]

                        greensockAnimationTag = '<span id = "motionwikiDeletion' + uniqueTagIdentifier + '">' + parsedRevisions[revIndex][line + numLinesToAdd] + '</span>'
                        parsedRevisions[revIndex][line + numLinesToAdd] = greensockAnimationTag
                        greensockAnimationArg = 'motionwikiDeletion'
                        finalline = line + numLinesToAdd
                        finalline = finalline
                        console.log "line = #{line}, motionwiki[line=#{finalline}] = #{$("motionwiki[line=" + finalline + "]").text()}"
                        $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                        doAnimation = true
                        doDelete = true
                        
                        
                    #If modifyToggle is true, we know the last action to happen was a deletion.
                    if index[0] == 'diff-addedline'
                        #if it is not an inline modification
                        if modifyToggle is false
                            #numTimesDeleted--
                            console.log "Adding line at #{line + numLinesToAdd}"
                            jQueryText = parsedRevisions[revIndex][line + numLinesToAdd]
                            text = '<div id ="motionwikiAddition' + uniqueTagIdentifier + '">' + index[1] + "</div>"
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
                            $("motionwiki[line=" + finalline + "]").replaceWith(greensockAnimationTag)
                            modifyToggle = false
                            doAnimation = true
                            #parsedRevisions[revIndex][line +  numLinesToAdd] = text

                    


                    if doAnimation
                        greensockAnimationId = "#" + greensockAnimationArg
                        animate.doAnimate(greensockAnimationId, greensockAnimationArg.substring(0, greensockAnimationArg.length - 1))
                        console.log "greensockAnimationId = #{greensockAnimationId}, greensockAnimationArg = #{greensockAnimationArg}"

                    if doDelete
                        parsedRevisions[revIndex].splice(line + numLinesToAdd - numTimesDeleted, 1)

                    uniqueTagIdentifier++


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

    
        # for revision in parsedWikiText
        #     for line in revision
        #         line += delimiter
        #         textToParse += line
        ###

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

