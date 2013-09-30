require ['require', 'jquery'], (require, $)->
    console.log "hello world - scout!"
    $('<button id="load">').text('Load!')
        .appendTo('body > div')
        .click(-> require ['motionwiki'])