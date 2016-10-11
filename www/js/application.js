angular.module('app', ['ionic']).config(function($stateProvider, $urlRouterProvider) {
  $stateProvider.state('home', {
    url: '/home',
    templateUrl: 'views/home/home.html'
  }).state('root', {
    url: '/',
    templateUrl: 'views/home/home.html'
  }).state('annual', {
    url: '/annual',
    templateUrl: 'views/annual/annual.html',
    controller: 'Annual'
  }).state('weekly', {
    url: '/weekly/:year',
    templateUrl: 'views/weekly/weekly.html',
    controller: 'Weekly'
  });
  return $urlRouterProvider.otherwise('/home');
}).run(function($ionicPlatform) {
  return $ionicPlatform.ready(function() {
    if (window.cordova && window.cordova.plugins.Keyboard) {
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
      cordova.plugins.Keyboard.disableScroll(true);
    }
    if (window.StatusBar) {
      return StatusBar.styleDefault();
    }
  });
}).controller('Main', function($scope, $http) {
  var eval_row, query, to_json;
  $scope.thou_sep = function(n) {
    n = n.toString();
    n = n.replace(/(\d+?)(?=(\d{3})+(\D|$))/g, '$1,');
    if (!(arguments.length > 1)) {
      return n;
    }
    if (arguments[1] === 'mk') {
      n = n.replace(/\./g, ';');
      n = n.replace(/,/g, '.');
      n = n.replace(/;/g, ',');
    }
    return n;
  };
  to_json = function(d) {
    var match, re;
    re = /^([^(]+?\()(.*)\);$/g;
    match = re.exec(d);
    return JSON.parse(match[2]);
  };
  eval_row = function(r) {
    return r.c.map(function(c) {
      if (c.f != null) {
        return eval(c.v);
      } else {
        return c.v;
      }
    });
  };
  $scope.KEY = '1R5S3ZZg1ypygf_fpRoWnsYmeqnNI2ZVosQh2nJ3Aqm0';
  $scope.URL = "https://spreadsheets.google.com/";
  $scope.RE = /^([^(]+?\()(.*)\);$/g;
  $scope.to_json = to_json;
  $scope.eval_row = eval_row;
  $scope.qurl = function(q) {
    return ($scope.URL + "tq?tqx=out:json&key=" + $scope.KEY) + ("&tq=" + (encodeURI(q)));
  };
  query = 'SELECT YEAR(B), COUNT(A), SUM(C), SUM(I) GROUP BY YEAR(B) ORDER BY YEAR(B)';
  $scope.width = window.innerWidth;
  $scope.height = window.innerHeight;
  return console.log("WxH: " + window.innerWidth + "x" + window.ainnerHeight);
}).controller('Annual', function($scope, $http) {
  var query;
  $scope.hide_chart = true;
  $scope.bar_chart = {};
  $scope.bar_chart.title = 'Bar chart title';
  $scope.bar_chart.width = $scope.width;
  $scope.bar_chart.height = $scope.height;
  query = 'SELECT YEAR(B), COUNT(A), SUM(C), SUM(I) GROUP BY YEAR(B) ORDER BY YEAR(B)';
  return $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.sales = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        year: a[0],
        draws: a[1],
        lotto: a[2],
        joker: a[3]
      };
    });
    $scope.bar_chart.data = $scope.sales.map(function(r) {
      return r.lotto;
    });
    return $scope.bar_chart.labels = $scope.sales.map(function(r) {
      return r.year;
    });
  });
}).controller('Weekly', function($scope, $http, $stateParams) {
  var query;
  $scope.dow_to_mk = function(d) {
    switch (d) {
      case 1:
        return 'недела';
      case 2:
        return 'понеделник';
      case 3:
        return 'вторник';
      case 4:
        return 'среда';
      case 5:
        return 'четврток';
      case 6:
        return 'петок';
      case 7:
        return 'сабота';
      default:
        return '';
    }
  };
  $scope.dow_to_en = function(d) {
    switch (d) {
      case 1:
        return 'Sunday';
      case 2:
        return 'Monday';
      case 3:
        return 'Tuesday';
      case 4:
        return 'Wednesday';
      case 5:
        return 'Thursday';
      case 6:
        return 'Friday';
      case 7:
        return 'Saturday';
      default:
        return '';
    }
  };
  $scope.year = parseInt($stateParams.year);
  query = "SELECT A, dayOfWeek(B), C, I WHERE YEAR(B) = " + $scope.year + " ORDER BY A";
  $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    return $scope.sales = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        draw: a[0],
        dow: a[1],
        lotto: a[2],
        joker: a[3]
      };
    });
  });
  return $scope.toggle = function() {
    return $('#qq').append('<p>append</p>');
  };
}).directive('barChart', function() {
  return {
    restrict: 'A',
    replace: false,
    link: function(scope, el, attrs) {
      var margin, r, svg, x, x_axis, y, y_axis;
      if (attrs.title != null) {
        scope.bar_chart.title = attrs.title;
      }
      if (attrs.width != null) {
        scope.bar_chart.width = parseInt(attrs.width);
      }
      if (attrs.height != null) {
        scope.bar_chart.height = parseInt(attrs.height);
      }
      margin = {
        top: 15,
        right: 10,
        bottom: 40,
        left: 60
      };
      console.log("Title x-" + scope.bar_chart.labels[Math.floor(scope.bar_chart.labels.length / 2)]);
      console.log("wxh: " + scope.bar_chart.width + "x" + scope.bar_chart.height);
      svg = d3.select(el[0]).append('svg').attr('width', scope.bar_chart.width + margin.left + margin.right).attr('height', scope.bar_chart.height + margin.top + margin.bottom).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
      y = d3.scale.linear().rangeRound([scope.bar_chart.height, 0]);
      y_axis = d3.svg.axis().scale(y).tickFormat(function(d) {
        return Math.round(d / 10000) / 100 + " M";
      }).orient('left');
      x = d3.scale.ordinal().rangeRoundBands([0, scope.bar_chart.width], 0.1);
      x_axis = d3.svg.axis().scale(x).orient('bottom');
      y.domain([0, d3.max(scope.bar_chart.data)]);
      svg.append('g').attr('class', 'y axis').transition().duration(1000).call(y_axis);
      x.domain(scope.bar_chart.labels);
      svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, " + scope.bar_chart.height + ")").call(x_axis);
      svg.append('text').attr('x', x(scope.bar_chart.labels[Math.floor(scope.bar_chart.labels.length / 2)])).attr('y', y(20 + d3.max(scope.bar_chart.data))).attr('dy', '-0.35em').attr('text-anchor', 'middle').text(scope.bar_chart.title);
      r = svg.selectAll('.bar').data(scope.bar_chart.data.map(function(d) {
        return Math.floor(Math.random() * d);
      })).enter().append('rect').attr('class', 'bar').attr('x', function(d, i) {
        return x(scope.bar_chart.labels[i]);
      }).attr('y', function(d) {
        return y(d);
      }).attr('height', function(d) {
        return scope.bar_chart.height - y(d);
      }).attr('width', x.rangeBand()).attr('data-toggle', 'tooltip').attr('md-direction', 'top').attr('title', function(d, i) {
        return scope.thou_sep(scope.bar_chart.data[i]);
      });
      return r.transition().duration(1000).ease('elastic').attr('y', function(d, i) {
        return y(scope.bar_chart.data[i]);
      }).attr('height', function(d, i) {
        return scope.bar_chart.height - y(scope.bar_chart.data[i]);
      });
    }
  };
});
