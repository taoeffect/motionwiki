define ['require', 'lodash', 'jquery', 'JSON', 'wiki/api', 'directives', 'controllers', 'Animation', 'bootstrap_datepicker'], (require, _, $, JSON, api, directives, controllers, animate)->

    _.mixin stringify: JSON.stringify
    String::replaceAll = (s1, s2, i="")->
        @.replace(new RegExp(s1.replace(/([\,\!\\\^\$\{\}\[\]\(\)\.\*\+\?\|\<\>\-\&])/g, (c)->"\\" + c), "g"+i), s2)

    $('<div class="mw_wrapper motionwiki">').appendTo('body > div')
    $('<div ng-app="motion_wiki" ng-controller="AppCtrl" id="motionwiki" class="mw_main mw_main--wrapper motionwiki" >').appendTo('.mw_wrapper')
    $('<mw-timeline class="motionwiki mw_main--inner">').appendTo('div#motionwiki')

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
                    wikiText = revision["*"].replaceAll("\n", " #{delimiter}\n ").substring(0, 5000)

                # send this wikitext back
                api.parseToHTML wikiText, (jqXHR, textStatus)->
                    wikiHTML = jqXHR.responseJSON.parse.text["*"]
                    console.log "got back parsed html:\n#{wikiHTML}"
                    counter = 1
                    htmlLines = _(wikiHTML.split(delimiter)).map((line)-> "<b>LINE #{counter++}:</b> #{line}").join('')
                    $('#mw-content-text').html(htmlLines) # replace wiki
                    # $("<div>").html(htmlLines).appendTo('body')



    timeStampArray = []
###
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

