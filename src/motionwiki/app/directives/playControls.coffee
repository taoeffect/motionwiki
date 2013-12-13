## Play controls directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwPlayControls', [ ->
    templateUrl: '/templates/directives/playControls.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "play controls directive"

<<<<<<< HEAD
  
=======
>>>>>>> presentationfix
      $('body').keyup (e) ->
          alert "Play!!" if e.keyCode is 80     #p for pause/play
          alert "Forward!" if e.keyCode is 37   #left arrow
          alert "backward!!" if e.keyCode is 39 #right arrow
<<<<<<< HEAD
     
=======

>>>>>>> presentationfix
      scope.play = ->
      	alert "Play!!"
      scope.forward = ->
      	alert "Forward!"
      scope.backward = ->
      	alert "backward!!"


  ]

