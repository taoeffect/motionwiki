require ['require', 'jquery', 'angular'], (require, $, angular)->
    ##console.log "hello world - scout!"

	$('<button id="load">').text('Load!')
		.appendTo('body > div')
		.click(-> require ['motionwiki'],
<<<<<<< HEAD
			$("body").wrapInner $("<div id=\"MOVEIT\"/>").css(
    					  "margin-left": 185
    					  "margin-top": 175
    	 	)
   			#$mapSource = $("<script>")
			# $mapSource.attr "src", "/includes/js/miniPageNav.js"
			# $("body").append $mapSource
=======
			$('body').wrapInner $("<div id=\"MOVEIT\"/>").css(
					"margin-left": 185
					"margin-top": 175
				)
>>>>>>> presentationfix
		)

