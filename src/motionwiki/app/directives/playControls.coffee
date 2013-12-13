## Play controls directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwPlayControls', [ ->
    templateUrl: '/templates/directives/playControls.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "play controls directive"

      scope.play = ->
              alert "Play!!"
              fn.reload();
      scope.forward = ->
              alert "Forward!"
      scope.backward = ->
              alert "backward!!"

  ]

