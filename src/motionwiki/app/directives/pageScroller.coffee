## Page scroller directive

define ['require', 'jquery'], (require, $)->

	angular.module('mw_directives').directive 'mwPageScroller', [ ->
		templateUrl: '/templates/directives/pageScroller.html'
		restrict: 'E'
		link: (scope, element, attrs)->
			$("#ButtonForMap").click -> #lets assume you gave the button for the map the div id= ButtonForMap
				if $(this).val() is "OFF"
					$(this).val "ON"
					#$("#MOVEIT").css "margin-left": 0
					$("#MAP").slideUp "slow",->
					#$("#MAP").remove() 
					
				else
					if $("#MAP").length
						$("#MAP").remove()  
					#$("#MOVEIT").css "margin-left": 185
					$mapSource = $("<script>")
					$mapSource.attr "src", "/includes/js/miniPageNav.js"
					$("body").append $mapSource
					$(this).val "OFF"



    				
				

			
	]