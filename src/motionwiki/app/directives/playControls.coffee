## Play controls directive

define ['require', 'jquery'], (require, $)->

  angular.module('mw_directives').directive 'mwPlayControls', [ ->
    templateUrl: '/includes/templates/directives/playControls.html'
    restrict: 'A'
    link: (scope, element, attrs)->
      console.log "play controls directive"
      scope.active = false

      scope.play = ->
        alert "Play!!"
        scope.active = !scope.active
      scope.forward = ->
        alert "Forward!"
      scope.backward = ->
        alert "backward!!"

  ]

