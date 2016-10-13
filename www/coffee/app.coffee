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
  console.log "WxH: #{ window.innerWidth }x#{ window.innerHeight }"

.controller 'Annual', ($scope, $http, $ionicPopup, $timeout) ->
  # bar chart
  $scope.hide_chart = true
  $scope.sbarChart = { }
  $scope.sbarChart.title  = 'Bar chart title'
  $scope.sbarChart.width  = $scope.width
  $scope.sbarChart.height = $scope.height
  
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
      $scope.sbarChart.data   = $scope.sales
      $scope.sbarChart.labels = 'year'
      $scope.sbarChart.categories = ['joker', 'lotto']
          
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

.directive 'barChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.barChart.title   = attrs.title   if attrs.title?
      scope.barChart.width   = parseInt(attrs.width)   if attrs.width?
      scope.barChart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 10, bottom: 40, left: 60 }
      
      console.log "Title x-#{ scope.barChart.labels[Math.floor scope.barChart.labels.length/2] }"
      console.log "wxh: #{scope.barChart.width}x#{scope.barChart.height}"
      svg = d3.select el[0]
              .append 'svg'
              .attr 'width', scope.barChart.width + margin.left + margin.right
              .attr 'height', scope.barChart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"
      y = d3.scale.linear().rangeRound [scope.barChart.height, 0]
      yAxis = d3.svg.axis().scale(y)
                 .tickFormat (d) -> Math.round(d/10000)/100 + " M"
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.barChart.width], 0.1
      xAxis = d3.svg.axis().scale(x).orient 'bottom'

      y.domain [0, d3.max(scope.barChart.data)]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis
      x.domain scope.barChart.labels
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.barChart.height})"
         .call xAxis
     
      svg.append 'text'
         .attr 'x', x(scope.barChart.labels[Math.floor scope.barChart.labels.length/2])
         .attr 'y', y(20 + d3.max(scope.barChart.data))
         .attr 'dy', '-0.35em'
         .attr 'text-anchor', 'middle'
         .attr 'class', 'bar-chart-title'
         .text scope.barChart.title

      r = svg.selectAll '.bar'
         .data scope.barChart.data.map (d) -> Math.floor Math.random()*d
         .enter().append 'rect'
         .attr 'class', 'bar'
         .attr 'x', (d, i) -> x(scope.barChart.labels[i])
         .attr 'y', (d) -> y(d)
         .attr 'height', (d) -> scope.barChart.height - y(d)
         .attr 'width', x.rangeBand()
         .attr 'ng-touch', (d, i) -> "console.log(#{i})" #"{{ showPopup(#{scope.barChart.data[i]}) }}"
         .attr 'title', (d, i) -> scope.thou_sep(scope.barChart.data[i])

      r.transition().duration 1000
         .ease 'elastic'
         .attr 'y', (d, i) -> y(scope.barChart.data[i])
         .attr 'height', (d, i) -> scope.barChart.height - y(scope.barChart.data[i])
  }

.directive 'stackedBarChart', () ->
  {
    restrict: 'A'
    replace:  false
    link:     (scope, el, attrs) ->
      scope.sbarChart.title   = attrs.title             if attrs.title?
      scope.sbarChart.width   = parseInt(attrs.width)   if attrs.width?
      scope.sbarChart.height  = parseInt(attrs.height)  if attrs.height?
      margin = { top: 15, right: 10, bottom: 40, left: 60 }

      svg = d3.select el[0]
              .append 'svg'
              .attr 'width', scope.sbarChart.width + margin.left + margin.right
              .attr 'height', scope.sbarChart.height + margin.top + margin.bottom
              .append 'g'
              .attr 'transform', "translate(#{margin.left}, #{margin.top})"
      
      # scope.sbarChart.categories
      # ['lotto', 'joker']
      lab = scope.sbarChart.labels
      remapped = scope.sbarChart.categories.map (cat) ->
        scope.sbarChart.data.map (d, i) ->
          { x: d[lab], y: d[cat] }
      
      stacked = d3.layout.stack()(remapped)

      y = d3.scale.linear().rangeRound [scope.sbarChart.height, 0]
      yAxis = d3.svg.axis().scale(y)
                 .tickFormat (d) -> Math.round(d/10000)/100 + " M"
                 .orient 'left'

      x = d3.scale.ordinal().rangeRoundBands [0, scope.sbarChart.width], 0.1
      xAxis = d3.svg.axis().scale(x).orient 'bottom'

      x.domain stacked[0].map (d) -> d.x
      svg.append 'g'
         .attr 'class', 'x axis'
         .attr 'transform', "translate(0, #{scope.sbarChart.height})"
         .call xAxis

      y.domain [0, d3.max(stacked[-1..][0], (d) -> return d.y0 + d.y)]
      svg.append 'g'
         .attr 'class', 'y axis'
         .transition().duration 1000
         .call yAxis

      console.log "MAX: #{ d3.max(stacked[-1..][0], ((d) -> d.y0 + d.y)) }"
      console.log stacked[-1..]

      color = d3.scale.ordinal().range ['brown', 'stealblue']
      
      svg.selectAll '.bar'
         .data stacked
         .append 'rect'
         .attr 'class', 'bar'
         .attr 'x', (d) -> x(d.x)
         .attr 'y', (d) -> -y(d.y0) - y(d.y)
         .attr 'height', (d) -> y(d.y)
         .attr 'width', x.rangeBand()
         .style 'fill', (d, i) -> color(i)
         .attr 'title', (d, i) -> scope.thou_sep(scope.barChart.data[i])

      console.log "width: #{ x.rangeBand() }"
#             // Add a group for each column.
#             var valgroup = svg.selectAll("g.valgroup")
#             .data(stacked)
#             .enter().append("svg:g")
#             .attr("class", "valgroup")
#             .style("fill", function(d, i) { return z(i); })
#             .style("stroke", function(d, i) { return d3.rgb(z(i)).darker(); });
#  
#             // Add a rect for each date.
#             var rect = valgroup.selectAll("rect")
#             .data(function(d){return d;})
#             .enter().append("svg:rect")
#             .attr("x", function(d) { return x(d.x); })
#             .attr("y", function(d) { return -y(d.y0) - y(d.y); })
#             .attr("height", function(d) { return y(d.y); })
#             .attr("width", x.rangeBand());
  }
