# Ionic Starter App

# angular.module is a global place for creating, registering and retrieving Angular modules
# 'starter' is the name of this angular module example (also set in a <body> attribute in index.html)
# the 2nd parameter is an array of 'requires'
angular.module 'app', ['ionic']
.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state 'home', {
      url:          '/home'
      templateUrl:  'views/home/home.html'
    }
    .state 'root', {
      url:          '/'
      templateUrl:  'views/home/home.html'
    }
    .state 'annual', {
      url:          '/annual'
      templateUrl:  'views/annual/annual.html'
      controller:   'Annual'
    }
    .state 'weekly', {
      url:          '/weekly/:year'
      templateUrl:  'views/weekly/weekly.html'
      controller:   'Weekly'
    }
  $urlRouterProvider.otherwise '/home'
.run ($ionicPlatform) ->
  $ionicPlatform.ready () ->
    if window.cordova && window.cordova.plugins.Keyboard
      # Hide the accessory bar by default (remove this to
      # show the accessory bar above the keyboard
      # for form inputs)g
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

      # Don't remove this line unless you know what you are doing. It stops the viewport
      # from snapping when text inputs are focused. Ionic handles this internally for
      # a much nicer keyboard experience.
      cordova.plugins.Keyboard.disableScroll true
    if window.StatusBar
      StatusBar.styleDefault()

.controller 'Main', ($scope, $http) ->
  $scope.thou_sep = (n) ->
    n = n.toString()
    n = n.replace /(\d+?)(?=(\d{3})+(\D|$))/g, '$1,'
    return n unless arguments.length > 1
    if arguments[1] is 'mk'
      n = n.replace /\./g, ';'
      n = n.replace /,/g, '.'
      n = n.replace /;/g, ','
    n # return this value

  to_json = (d) -> # convert google query response to json
    re =  /^([^(]+?\()(.*)\);$/g
    match = re.exec d
    JSON.parse match[2]

  # res.table.row[i]; string/text values are not eval-ed
  eval_row = (r) -> r.c.map (c)-> if c.f? then eval(c.v) else c.v

  $scope.KEY ='1R5S3ZZg1ypygf_fpRoWnsYmeqnNI2ZVosQh2nJ3Aqm0'
  $scope.URL = "https://spreadsheets.google.com/"
  $scope.RE  =  /^([^(]+?\()(.*)\);$/g
  $scope.to_json  = to_json
  $scope.eval_row = eval_row
  $scope.qurl = (q) -> "#{ $scope.URL }tq?tqx=out:json&key=#{ $scope.KEY }" +
                "&tq=#{ encodeURI q }"
  query = 'SELECT YEAR(B), COUNT(A), SUM(C), SUM(I) GROUP BY YEAR(B) ORDER BY YEAR(B)'
  # query spreadsheet
  # $http.get $scope.qurl(query)
  #   .success (data, status) ->
  #     re = /^([^(]+?\()(.*)\);$/g
  #     match = re.exec data
  #     res = JSON.parse match[2]
  #     
  #     for row in res.table.rows
  #       console.log $scope.eval_row(row)
  #   .error (data, status) ->
  #     console.log "Error loading lotto data (#{ status })"

.controller 'Annual', ($scope, $http) ->
  query = 'SELECT YEAR(B), COUNT(A), SUM(C), SUM(I) GROUP BY YEAR(B) ORDER BY YEAR(B)'
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:   a[0]
          draws:  a[1]
          lotto:  a[2]
          joker:  a[3]
        }
          
.controller 'Weekly', ($scope, $http, $stateParams) ->
  $scope.dow_to_mk = (d) ->
    switch d
      when 1 then 'недела'
      when 2 then 'понеделник'
      when 3 then 'вторник'
      when 4 then 'среда'
      when 5 then 'четврток'
      when 6 then 'петок'
      when 7 then 'сабота'
      else ''

  $scope.dow_to_en = (d) ->
    switch d
      when 1 then 'Sunday'
      when 2 then 'Monday'
      when 3 then 'Tuesday'
      when 4 then 'Wednesday'
      when 5 then 'Thursday'
      when 6 then 'Friday'
      when 7 then 'Saturday'
      else ''

  $scope.year = parseInt $stateParams.year
  query = "SELECT A, dayOfWeek(B), C, I WHERE YEAR(B) = #{ $scope.year } ORDER BY A"
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          draw:   a[0]
          dow:    a[1]
          lotto:  a[2]
          joker:  a[3]
        }
