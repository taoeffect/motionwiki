require ['require', 'jquery', 'angular'], (require, $, angular)->
    ##console.log "hello world - scout!"

    $('<button id="load" style="position:fixed; top: 100px; right:0">').text('Load!')
        .appendTo('body')
        .click(-> require ['motionwiki', 'bootstrap','css!motionwiki','nouislider'],
            $('body').wrapInner $("<div id=\"MOVEIT\"/>").css(
                        if('#mw-panel').lenth
                            "margin-left": 100
                            "margin-top": 145
                        else
                            "margin-left": 215
                            "margin-top": 145
                )
        )
