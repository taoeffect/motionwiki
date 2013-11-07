## History grapher

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_directives').directive 'mwHistoryGrapher', [ ->
    templateUrl: '/templates/directives/historyGrapher.html'
    restrict: 'E'
    link: (scope, element, attrs)->
      console.log "history grapher directive"
  ]

