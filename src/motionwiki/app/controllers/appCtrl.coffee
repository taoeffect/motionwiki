## App controller

define ['require', 'jquery'], (require, $)->

	angular.module('mw_controllers').controller 'AppCtrl', [
		'$scope',
		($scope)->
			$scope.datepicker1 = {date: new Date()};
			$scope.datepicker2 = {date: new Date()};

			$('.mw_datepicker').datepicker() 
	]
