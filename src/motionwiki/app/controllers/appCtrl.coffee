## App controller

define ['require', 'jquery'], (require, $)->
  
  angular.module('mw_controllers').controller 'AppCtrl', [
    '$scope',
    ($scope)->
      console.log "app controller"
  ]
