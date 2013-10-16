## Play controls directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwPlayControls', [ ->
    templateUrl: '../public/templates/directives/playControls.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "play controls directive"
  ]

