## Timeline Directive

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwTimeline', [ ->
    templateUrl: '/includes/templates/directives/timeline.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "timeline directive"
  ]

