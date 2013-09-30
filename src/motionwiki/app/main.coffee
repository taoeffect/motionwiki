define ['require', 'jquery'], (require, $)->
    console.log "hello world - main!"
    $('<div>').text('MotionWiki Loaded! Woohoo!!').appendTo('body > div')