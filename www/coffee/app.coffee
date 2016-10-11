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
  
  # device width/height
  $scope.width  = window.innerWidth
  $scope.height = window.innerHeight
  console.log "WxH: #{ window.innerWidth }x#{ window.ainnerHeight }"

.controller 'Annual', ($scope, $http) ->
  # bar chart
  $scope.hide_chart = true
  $scope.bar_chart = { }
  $scope.bar_chart.title  = 'Bar chart title'
  $scope.bar_chart.width  = $scope.width
  $scope.bar_chart.height = $scope.height

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
      $scope.bar_chart.data   = $scope.sales.map (r) -> r.lotto
      $scope.bar_chart.labels = $scope.sales.map (r) -> r.year
          
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
  $scope.toggle = () ->
    $('#qq').append('<p>append</p>')

.directive 'barChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.bar_chart.title   = attrs.title   if attrs.title?
      scope.bar_chart.width   = parseInt(attrs.width)   if attrs.width?
      scope.bar_chart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 10, bottom: 40, left: 60 }
      
      console.log "Title x-#{ scope.bar_chart.labels[Math.floor scope.bar_chart.labels.length/2] }"
      console.log "wxh: #{scope.bar_chart.width}x#{scope.bar_chart.height}"
      svg = d3.select el[0]
              .append 'svg'
              .attr 'width', scope.bar_chart.width + margin.left + margin.right
              .attr 'height', scope.bar_chart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"
      y = d3.scale.linear().rangeRound [scope.bar_chart.height, 0]
      y_axis = d3.svg.axis().scale(y)
                 .tickFormat (d) -> Math.round(d/10000)/100 + " M"
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.bar_chart.width], 0.1
      x_axis = d3.svg.axis().scale(x).orient 'bottom'

      y.domain [0, d3.max(scope.bar_chart.data)]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call y_axis
      x.domain scope.bar_chart.labels
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.bar_chart.height})"
         .call x_axis
     
      svg.append 'text'
         .attr 'x', x(scope.bar_chart.labels[Math.floor scope.bar_chart.labels.length/2])
         .attr 'y', y(20 + d3.max(scope.bar_chart.data))
         .attr 'dy', '-0.35em'
         .attr 'text-anchor', 'middle'
         .text scope.bar_chart.title
      r = svg.selectAll '.bar'
         .data scope.bar_chart.data.map (d) -> Math.floor Math.random()*d
         .enter().append 'rect'
         .attr 'class', 'bar'
         .attr 'x', (d, i) -> x(scope.bar_chart.labels[i])
         .attr 'y', (d) -> y(d)
         .attr 'height', (d) -> scope.bar_chart.height - y(d)
         .attr 'width', x.rangeBand()
         .attr 'data-toggle', 'tooltip'
         .attr 'md-direction', 'top'
         .attr 'title', (d, i) -> scope.thou_sep(scope.bar_chart.data[i])

      r.transition().duration 1000
         .ease 'elastic'
         .attr 'y', (d, i) -> y(scope.bar_chart.data[i])
         .attr 'height', (d, i) -> scope.bar_chart.height - y(scope.bar_chart.data[i])

      # svg.selectAll '.bar'
      #    .data scope.bar_chart.data
      #    .enter()
      #    .append 'rect'
      #    .attr 'class', 'bar'
      #    .attr 'x', (d, i) -> x(scope.bar_chart.labels[i])
      #    .attr 'y', (d) -> y(d)
      #    .attr 'height', (d) -> scope.bar_chart.height - y(d)
      #    .attr 'width', x.rangeBand()
      #    .attr 'data-toggle', 'tooltip'
      #    .attr 'md-direction', 'top'
      #    .attr 'title', (d, i) -> scope.thou_sep(scope.bar_chart.data[i])

  }
