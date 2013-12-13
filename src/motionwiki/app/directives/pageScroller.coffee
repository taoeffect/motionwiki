## Page scroller directive

define ['require', 'jquery'], (require, $)->

	angular.module('mw_directives').directive 'mwPageScroller', [ ->
		templateUrl: '/templates/directives/pageScroller.html'
		restrict: 'E'
		link: (scope, element, attrs)->
			# $mapSource = $("<script>")
			# $mapSource.attr "src", "/includes/js/miniPageNav.js"
			# $("body").append $mapSource
			$("#ButtonForMap").click -> #lets assume you gave the button for the map the div id= ButtonForMap
				if $(this).val() is "OFF"
					$(this).val "ON"
					#$("#MOVEIT").css "margin-left": 0
					$("#MAP").slideUp "slow",->
					#$("#MAP").remove() 
					$("#mw-panel").css opacity: 1
					
				else
					if $("#MAP").length
						$("#MAP").remove()  
					#$("#MOVEIT").css "margin-left": 185
					$mapSource = $("<script>")
					$mapSource.attr "src", "/includes/js/miniPageNav.js"
					$("body").append $mapSource
					$("#mw-panel").css opacity: 0
					$(this).val "OFF"


			(($) -> #i'm working on a reload function that should be called eveytime an animation happens. not done yet
				$.fn.reloadMap = ->
					if $("#MAP").length
						$("#MAP").remove()  
					$mapSource = $("<script>")
					$mapSource.attr "src", "/includes/js/miniPageNav.js"
					$("body").append $mapSource
			) jQuery
    				
				

			
	]
