require ['require', 'jquery', 'angular'], (require, $, angular)->
    ##console.log "hello world - scout!"

	$('<button id="load">').text('Load!')
		.appendTo('body > div')
		.click(-> require ['motionwiki', 'bootstrap','css!motionwiki','nouislider'],
			$('body').wrapInner $("<div id=\"MOVEIT\"/>").css(
					"margin-left": 185
					"margin-top": 175
				)
		)
