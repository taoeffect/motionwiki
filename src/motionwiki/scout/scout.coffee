require ['require', 'jquery', 'angular'], (require, $, angular)->
    ##console.log "hello world - scout!"

	$('<button id="load" style="position:fixed; top: 10px; right:0">').text('Load!')
		.appendTo('body')
		.click(-> require ['motionwiki'],
			$('body').wrapInner $("<div id=\"MOVEIT\"/>").css(
					"margin-left": 185
					"margin-top": 175
				)
		)

