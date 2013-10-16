## Page scroller directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwPageScroller', [ ->
    templateUrl: '../public/templates/directives/pageScroller.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "page scroller directive"
  ]

