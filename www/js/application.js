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
        if (typeof c.v === 'string' && c.v.match(/^Date/)) {
          return eval('new ' + c.v);
        } else {
          return eval(c.v);
        }
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
  query = 'SELECT YEAR(B) ORDER BY YEAR(B) DESC LIMIT 1';
  $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    return $scope.lastYear = ($scope.eval_row(res.table.rows[0]))[0];
  });
  $scope.width = window.innerWidth;
  $scope.height = window.innerHeight;
  return console.log("WxH: " + window.innerWidth + "x" + window.innerHeight);
}).controller('Annual', function($scope, $http, $ionicPopup, $timeout) {
  var query;
  $scope.hideChart = true;
  $scope.sbarChart = {};
  $scope.sbarChart.title = 'Bar chart title';
  $scope.sbarChart.width = $scope.width;
  $scope.sbarChart.height = $scope.height;
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
        'лото': a[2],
        'џокер': a[3]
      };
    });
    $scope.sbarChart.data = $scope.sales;
    $scope.sbarChart.labels = 'year';
    return $scope.sbarChart.categories = ['лото', 'џокер'];
  });
}).controller('Weekly', function($scope, $http, $stateParams) {
  var query, queryYear;
  $scope.hideChart = true;
  $scope.lineChart = {};
  $scope.lineChart.width = $scope.width;
  $scope.lineChart.height = $scope.height;
  $scope.lineChart.hide = true;
  $scope.dow_to_mk = function(d) {
    switch (Math.floor(d)) {
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
    switch (Math.floor(d)) {
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
        return "*" + d + "*";
    }
  };
  $scope.year = parseInt($stateParams.year);
  queryYear = "SELECT A, dayOfWeek(B), \n       C, I, B, D, J\nWHERE YEAR(B) = " + $scope.year + "\nORDER BY A";
  $http.get($scope.qurl(queryYear)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.sales = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        draw: a[0],
        dow: a[1],
        lotto: a[2],
        joker: a[3],
        date: a[4],
        lx7: a[5],
        jx6: a[6]
      };
    });
    return $scope.buildSeries();
  });
  $scope.buildSeries = function() {
    var a, arr, i, j, len, ref, sale, series;
    arr = [[], [], [], [], [], [], [], []];
    ref = $scope.sales;
    for (j = 0, len = ref.length; j < len; j++) {
      sale = ref[j];
      arr[sale.dow].push({
        x: sale.date,
        y: sale.lotto
      });
    }
    series = [];
    for (i in arr) {
      a = arr[i];
      if (arr[i].length > 0) {
        series.push({
          name: $scope.dow_to_mk(i),
          data: arr[i]
        });
      }
    }
    return $scope.series = series;
  };
  query = "SELECT YEAR(B), COUNT(A) GROUP BY YEAR(B) ORDER BY YEAR(B)";
  $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.years = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        year: a[0],
        draws: a[1]
      };
    });
    return $scope.select = ($scope.years.filter(function(x) {
      return x.year === $scope.year;
    }))[0];
  });
  return $scope.newSelection = function(v) {
    $scope.lineChart.hide = true;
    $scope.select = v;
    $scope.year = $scope.select.year;
    queryYear = "SELECT A, dayOfWeek(B),\n       C, I, B, D, J\nWHERE YEAR(B) = " + $scope.year + "\nORDER BY A";
    return $http.get($scope.qurl(queryYear)).success(function(data, status) {
      var res;
      res = $scope.to_json(data);
      $scope.sales = res.table.rows.map(function(r) {
        var a;
        a = $scope.eval_row(r);
        return {
          draw: a[0],
          dow: a[1],
          lotto: a[2],
          joker: a[3],
          date: a[4],
          lx7: a[5],
          jx6: a[6]
        };
      });
      $scope.buildSeries();
      return $scope.lineChart.hide = true;
    });
  };
}).directive('barChart', function() {
  return {
    restrict: 'A',
    replace: false,
    link: function(scope, el, attrs) {
      var margin, r, svg, x, xAxis, y, yAxis;
      if (attrs.title != null) {
        scope.barChart.title = attrs.title;
      }
      if (attrs.width != null) {
        scope.barChart.width = parseInt(attrs.width);
      }
      if (attrs.height != null) {
        scope.barChart.height = parseInt(attrs.height);
      }
      margin = {
        top: 15,
        right: 10,
        bottom: 40,
        left: 60
      };
      svg = d3.select(el[0]).append('svg').attr('width', scope.barChart.width + margin.left + margin.right).attr('height', scope.barChart.height + margin.top + margin.bottom).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
      y = d3.scale.linear().rangeRound([scope.barChart.height, 0]);
      yAxis = d3.svg.axis().scale(y).tickFormat(function(d) {
        return Math.round(d / 10000) / 100 + " M";
      }).orient('left');
      x = d3.scale.ordinal().rangeRoundBands([0, scope.barChart.width], 0.1);
      xAxis = d3.svg.axis().scale(x).orient('bottom');
      y.domain([0, d3.max(scope.barChart.data)]);
      svg.append('g').attr('class', 'y axis').transition().duration(1000).call(yAxis);
      x.domain(scope.barChart.labels);
      svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, " + scope.barChart.height + ")").call(xAxis);
      svg.append('text').attr('x', x(scope.barChart.labels[Math.floor(scope.barChart.labels.length / 2)])).attr('y', y(20 + d3.max(scope.barChart.data))).attr('dy', '-0.35em').attr('text-anchor', 'middle').attr('class', 'bar-chart-title').text(scope.barChart.title);
      r = svg.selectAll('.bar').data(scope.barChart.data.map(function(d) {
        return Math.floor(Math.random() * d);
      })).enter().append('rect').attr('class', 'bar').attr('x', function(d, i) {
        return x(scope.barChart.labels[i]);
      }).attr('y', function(d) {
        return y(d);
      }).attr('height', function(d) {
        return scope.barChart.height - y(d);
      }).attr('width', x.rangeBand()).attr('title', function(d, i) {
        return scope.thou_sep(scope.barChart.data[i]);
      });
      return r.transition().duration(1000).ease('elastic').attr('y', function(d, i) {
        return y(scope.barChart.data[i]);
      }).attr('height', function(d, i) {
        return scope.barChart.height - y(scope.barChart.data[i]);
      });
    }
  };
}).directive('stackedBarChart', function() {
  return {
    restrict: 'A',
    replace: false,
    link: function(scope, el, attrs) {
      var color, g, lab, legend, margin, r, remapped, stacked, svg, tooltip, x, xAxis, xa, y, yAxis;
      if (attrs.title != null) {
        scope.sbarChart.title = attrs.title;
      }
      if (attrs.width != null) {
        scope.sbarChart.width = parseInt(attrs.width);
      }
      if (attrs.height != null) {
        scope.sbarChart.height = parseInt(attrs.height);
      }
      margin = {
        top: 15,
        right: 120,
        bottom: 40,
        left: 40
      };
      tooltip = d3.select(el[0]).append('div').attr('class', 'tooltip').style('opacity', 0);
      svg = d3.select(el[0]).append('svg').attr('width', scope.sbarChart.width + margin.left + margin.right).attr('height', scope.sbarChart.height + margin.top + margin.bottom).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
      lab = scope.sbarChart.labels;
      remapped = scope.sbarChart.categories.map(function(cat) {
        return scope.sbarChart.data.map(function(d, i) {
          return {
            x: d[lab],
            y: d[cat],
            cat: cat
          };
        });
      });
      stacked = d3.layout.stack()(remapped);
      y = d3.scale.linear().rangeRound([scope.sbarChart.height, 0]);
      yAxis = d3.svg.axis().scale(y).tickFormat(function(d) {
        return Math.round(d / 10000) / 100 + " M";
      }).orient('left');
      x = d3.scale.ordinal().rangeRoundBands([0, scope.sbarChart.width], 0.1);
      xAxis = d3.svg.axis().scale(x).orient('bottom');
      x.domain(stacked[0].map(function(d) {
        return d.x;
      }));
      svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, " + scope.sbarChart.height + ")").call(xAxis);
      y.domain([
        0, d3.max(stacked.slice(-1)[0], function(d) {
          return d.y0 + d.y;
        })
      ]);
      xa = svg.append('g').attr('class', 'y axis').transition().duration(1000).call(yAxis).selectAll('line').style("stroke-dasharray", "3, 3");
      color = d3.scale.category20c();
      svg.append('text').attr('x', x(stacked[0][Math.floor(stacked[0].length / 2)].x)).attr('y', y(20 + d3.max(stacked.slice(-1)[0], (function(d) {
        return d.y0 + d.y;
      })))).attr('dy', '-0.35em').attr('text-anchor', 'middle').attr('class', 'bar-chart-title').text(scope.sbarChart.title);
      g = svg.selectAll('g.vgroup').data(stacked).enter().append('g').attr('class', 'vgroup').style('fill', function(d, i) {
        return d3.rgb(color(i)).brighter(1.2);
      }).style('stroke', function(d, i) {
        return d3.rgb(color(i)).darker();
      });
      r = g.selectAll('rect').data(function(d) {
        return d;
      }).enter().append('rect').attr('id', function(d) {
        return d.cat + "-" + d.x;
      }).attr('x', function(d) {
        return x(d.x);
      }).attr('y', function(d) {
        return y(d.y + d.y0);
      }).attr('height', function(d) {
        return y(d.y0) - y(d.y + d.y0);
      }).attr('width', x.rangeBand()).on('click', function(d, i) {
        var t;
        d3.select("\#" + d.cat + "-" + d.x).style('opacity', 0.85).transition().duration(1500).ease('exp').style('opacity', 1);
        t = "<p style='text-align: center;'>\n  <b>" + d.cat + "</b><br />\n  <hr />\n  " + (scope.thou_sep(d.y)) + "\n</p>";
        tooltip.html('');
        tooltip.transition().duration(1000).style('opacity', 0.75);
        tooltip.html(t).style('left', d3.event.pageX + 'px').style('top', (d3.event.pageY - 60) + 'px').style('opacity', 1);
        return tooltip.transition().duration(3000).style('opacity', 0);
      }).append('title').html(function(d) {
        return "<strong>" + d.cat + "</strong>: " + (scope.thou_sep(d.y));
      });
      legend = svg.append('g').attr('class', 'legend');
      legend.selectAll('.legend-rect').data(scope.sbarChart.categories).enter().append('rect').attr('class', '.legend-rect').attr('width', 16).attr('height', 16).attr('x', scope.sbarChart.width + 2).attr('y', function(d, i) {
        return 20 * i;
      }).style('stroke', function(d, i) {
        return d3.rgb(color(i)).darker();
      }).style('fill', function(d, i) {
        return d3.rgb(color(i)).brighter(1.2);
      });
      return legend.selectAll('text').data(scope.sbarChart.categories).enter().append('text').attr('class', 'legend').attr('x', scope.sbarChart.width + 24).attr('y', function(d, i) {
        return 20 * i + 8;
      }).attr('dy', 4).text(function(d) {
        return d;
      });
    }
  };
}).directive('lineChart', function() {
  return {
    restrict: 'A',
    replace: false,
    link: function(scope, el, attrs) {
      var i, legend, line, margin, ref, s, svg, tooltip, x, xAxis, y, yAxis;
      if (attrs.title != null) {
        scope.lineChart.title = attrs.title;
      }
      if (attrs.width != null) {
        scope.lineChart.width = parseInt(attrs.width);
      }
      if (attrs.height != null) {
        scope.lineChart.height = parseInt(attrs.height);
      }
      margin = {
        top: 15,
        right: 120,
        bottom: 40,
        left: 40
      };
      tooltip = d3.select(el[0]).append('div').attr('class', 'tooltip').style('opacity', 0);
      svg = d3.select(el[0]).append('svg').attr('width', scope.lineChart.width + margin.left + margin.right).attr('height', scope.lineChart.height + margin.top + margin.bottom).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
      y = d3.scale.linear().rangeRound([scope.lineChart.height, 0]);
      yAxis = d3.svg.axis().scale(y).orient('left');
      y.domain([
        0, d3.max(scope.series.map(function(s) {
          return d3.max(s.data.map(function(d) {
            return d.y;
          }));
        }))
      ]);
      svg.append('g').attr('class', 'y axis').transition().duration(1000).call(yAxis);
      x = d3.time.scale().range([0, scope.lineChart.width]);
      xAxis = d3.svg.axis().scale(x).orient('bottom').tickFormat(d3.time.format("%W"));
      x.domain([
        d3.min(scope.series.map(function(s) {
          return s.data[0].x;
        })), d3.max(scope.series.map(function(s) {
          return s.data.slice(-1)[0].x;
        }))
      ]);
      svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, " + scope.lineChart.height + ")").call(xAxis);
      line = d3.svg.line().x(function(d) {
        return x(d.x);
      }).y(function(d) {
        return y(d.y);
      });
      ref = scope.series;
      for (i in ref) {
        s = ref[i];
        svg.append('path').datum(s.data).attr('class', 'line').attr('stroke', d3.scale.category10().range()[i]).attr('d', line);
      }
      legend = svg.append('g').attr('class', 'legend');
      return legend.selectAll('text').data(scope.series.map(function(s) {
        return s.name;
      })).enter().append('text').attr('class', 'legend').attr('x', scope.lineChart.width + 4).attr('y', function(d, i) {
        return 20 * i + 8;
      }).attr('dy', 4).style('fill', function(d, i) {
        return d3.rgb(d3.scale.category10().range()[i]).darker(0.5);
      }).text(function(d) {
        return d;
      });
    }
  };
});
