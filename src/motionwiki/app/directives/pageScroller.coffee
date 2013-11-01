## Page scroller directive

define ['require', 'jquery'], (require, $)->

	angular.module('mw_directives').directive 'mwPageScroller', [ ->
		templateUrl: '/templates/directives/pageScroller.html'
		restrict: 'E'
		link: (scope, element, attrs)->
			$("#ButtonForMap").click -> #lets assume you gave the button for the map the div id= ButtonForMap
				if $(this).val() is "ON"
					if $("#MAP").length
						$("#MAP").remove()  

					$mapSource = $("<script>")
					$mapSource.attr "src", "/includes/js/miniPageNav.js"
					$("#MyScript").append $mapSource
					$("body").wrapInner $("<div id=\"MOVEIT\"/>").css(
    					  "margin-left": 180
      				   	   
    				)
					$(this).val "OFF"
				else
    				$(this).val "ON"
    				$("#MOVEIT").css "margin-left": 0
    				$("#MAP").slideUp "slow",->
				

			
	]

