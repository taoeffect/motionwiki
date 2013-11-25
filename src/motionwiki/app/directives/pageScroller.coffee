## Page scroller directive

define ['require', 'jquery'], (require, $)->

	angular.module('mw_directives').directive 'mwPageScroller', [ ->
		templateUrl: '/includes/templates/directives/pageScroller.html'
		restrict: 'E'
		link: (scope, element, attrs)->
			#this next part is where i made a test button. It will be commented out during integration
			# var locationtoaddbutton= document.getElementById('baseNav');
			# var testbutton= document.createElement('input');

			# testbutton.type= 'button';
			# testbutton.id= 'ButtonForMap';
			# testbutton.value= 'ON';

			# locationtoaddbutton.appendChild(testbutton);
			#testbutton.onclick= showthemap;
			#$("#ButtonForMap").click(function(){alert();});
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
<<<<<<< HEAD
					$("body").append $mapSource
					$(this).val "OFF"



    				
				

			
	]
=======
					$("#MyScript").append $mapSource
					$(this).val "OFF"
				else
					$(this).val "ON"
					$("#MAP").slideUp "slow", ->


			(($) -> #i'm working on a reload function that should be called eveytime an animation happens. not done yet
				$.fn.reloadMap = ->
					$("#MAP").remove()
			) jQuery
	]

>>>>>>> merge
