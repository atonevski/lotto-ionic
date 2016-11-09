angular.module('app', ['ionic', 'app.util']).config(function($stateProvider, $urlRouterProvider) {
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
  }).state('stats', {
    url: '/stats',
    templateUrl: 'views/stats/home.html'
  }).state('lotto-stats', {
    url: '/stats/lotto',
    templateUrl: 'views/stats/lfreqs.html',
    controller: 'LottoStats'
  }).state('joker-stats', {
    url: '/stats/joker',
    templateUrl: 'views/stats/jfreqs.html',
    controller: 'JokerStats'
  }).state('winners-stats', {
    url: '/stats/winners',
    templateUrl: 'views/stats/winners.html',
    controller: 'WinnersStats'
  }).state('upload', {
    url: '/upload',
    templateUrl: 'views/upload/upload.html',
    controller: 'Upload'
  }).state('about', {
    url: '/about',
    templateUrl: 'views/about/about.html',
    controller: 'About'
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
}).controller('Main', function($scope, $rootScope, $http) {
  var eval_row, q, query, to_json;
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
  $rootScope.uploadNeeded = false;
  $scope.KEY = '1R5S3ZZg1ypygf_fpRoWnsYmeqnNI2ZVosQh2nJ3Aqm0';
  $scope.URL = "https://spreadsheets.google.com/";
  $scope.RE = /^([^(]+?\()(.*)\);$/g;
  $scope.to_json = to_json;
  $scope.eval_row = eval_row;
  $scope.nextDraw = function(d) {
    var date, tm;
    if (!((d.draw != null) || (d.date != null))) {
      throw "Not a valid draw: " + d;
    }
    tm = d.date.getTime() - d.date.getTimezoneOffset() * 60 * 1000;
    date = (function() {
      switch (d.date.getDay()) {
        case 3:
          return new Date(tm + 3 * 24 * 60 * 60 * 1000);
        case 6:
          return new Date(tm + 4 * 24 * 60 * 60 * 1000);
        default:
          throw "Invalid draw date: " + d.date;
      }
    })();
    if (date.getFullYear() === d.date.getFullYear()) {
      return {
        draw: d.draw + 1,
        date: date
      };
    } else {
      return {
        draw: 1,
        date: date
      };
    }
  };
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
  console.log("WxH: " + window.innerWidth + "x" + window.innerHeight);
  $scope.checkUpload = function() {
    var nextd, yesterday;
    if ($rootScope.lastDraw == null) {
      $rootScope.uploadNeeded = false;
      return false;
    }
    yesterday = (Date.parse((new Date()).toISOString().slice(0, 10))) - 1 * 24 * 60 * 60 * 1000;
    nextd = $scope.nextDraw($rootScope.lastDraw);
    console.log("yesterday: " + yesterday);
    console.log("next draw date: " + nextd.date);
    return $rootScope.uploadNeeded = nextd.date < yesterday;
  };
  $rootScope.checkUpload = $scope.checkUpload;
  q = 'SELECT A, B ORDER BY B DESC LIMIT 1';
  return $http.get($scope.qurl(q)).success(function(data, status) {
    var r, res;
    res = $scope.to_json(data);
    r = $scope.eval_row(res.table.rows[0]);
    $scope.lastDraw = {
      draw: r[0],
      date: r[1]
    };
    $rootScope.lastDraw = $scope.lastDraw;
    $rootScope.checkUpload();
    console.log($scope.lastDraw);
    return console.log("Upload needed: " + $scope.uploadNeeded);
  });
}).controller('Annual', function($scope, $http, $ionicPopup, $timeout, $ionicLoading) {
  var query;
  $scope.hideChart = true;
  $scope.sbarChart = {};
  $scope.sbarChart.title = 'Bar chart title';
  $scope.sbarChart.width = $scope.width;
  $scope.sbarChart.height = $scope.height;
  query = "SELECT YEAR(B), COUNT(A), SUM(C), SUM(I), SUM(D) GROUP BY YEAR(B) ORDER BY YEAR(B)";
  $ionicLoading.show();
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
        'џокер': a[3],
        x7: a[4]
      };
    });
    $scope.sbarChart.data = $scope.sales;
    $scope.sbarChart.labels = 'year';
    $scope.sbarChart.categories = ['лото', 'џокер'];
    return $ionicLoading.hide();
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат годишните податоци. Пробај подоцна.",
      duration: 3000
    });
  });
}).controller('Weekly', function($scope, $http, $stateParams, $timeout, $ionicLoading, $ionicPosition, $ionicScrollDelegate) {
  var query, queryYear;
  $scope.bubbleVisible = false;
  $scope.bubble = d3.select('#weekly-list').append('div').attr('class', 'bubble bubble-left').attr('id', 'weekly-bubble').on('click', function() {
    $scope.bubble.transition().duration(1000).style('opacity', 0);
    return $scope.bubbleVisible = false;
  }).style('opacity', 0);
  $scope.showBubble = function(event, idx) {
    var el, new_top, offset, t;
    if ($scope.bubbleVisible) {
      return;
    }
    event.stopPropagation();
    $scope.bubbleVisible = true;
    t = "<div class='row row-no-padding'>\n  <div class='col col-offset-80 text-right positive'>\n    <small><i class='ion-close-round'></i></small>\n  </div>\n</div>\n<dl class='dl-horizontal'>\n  <dt>Коло:</dt>\n  <dd>" + $scope.sales[idx].draw + "</dd>\n  <dt>Дата:</dt>\n  <dd>" + ($scope.sales[idx].date.toISOString().slice(0, 10).split('-').reverse().join('.')) + "</dd>\n  <hr />\n  <dt>Лото:</dt><dd></dd>\n  <hr />\n  <dt>Уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.sales[idx].lotto)) + "</dd>";
    t += "<dt>Добитници:</dt>\n<dd>\n  " + ($scope.sales[idx].lx7 > 0 ? $scope.sales[idx].lx7 + 'x7' : '') + "\n  " + ($scope.sales[idx].lx6p > 0 ? $scope.sales[idx].lx6p + 'x6<sup><strong>+</strong></sup>' : '') + " \n  " + ($scope.sales[idx].lx6 > 0 ? $scope.sales[idx].lx6 + 'x6' : '') + " \n  " + ($scope.sales[idx].lx5 > 0 ? $scope.thou_sep($scope.sales[idx].lx5 + 'x5') : '') + " \n  " + ($scope.sales[idx].lx4 > 0 ? $scope.thou_sep($scope.sales[idx].lx4 + 'x4') : '') + " \n</dd>";
    t += "<dt>Доб. комбинација:</dt>\n<dd>\n  " + ($scope.sales[idx].lwcol.slice(0, 7).sort(function(a, b) {
      return +a - +b;
    }).join(' ')) + "\n  <span style='color: steelblue'>" + $scope.sales[idx].lwcol[7] + "</span>\n  <br />\n  [ " + ($scope.sales[idx].lwcol.slice(0, 7).join(' ')) + "\n  <span style='color: steelblue'>" + $scope.sales[idx].lwcol[7] + "</span> ]\n</dd>";
    t += "<hr />\n<dt>Џокер:</dt><dd></dd>\n<hr />\n<dt>Уплата:</dt>\n<dd>" + ($scope.thou_sep($scope.sales[idx].joker)) + "</dd>";
    t += "<dt>Добитници:</dt>\n<dd>\n  " + ($scope.sales[idx].jx6 > 0 ? $scope.sales[idx].jx6 + 'x6' : '') + "\n  " + ($scope.sales[idx].jx5 > 0 ? $scope.sales[idx].jx5 + 'x5' : '') + " \n  " + ($scope.sales[idx].jx4 > 0 ? $scope.sales[idx].jx4 + 'x4' : '') + " \n  " + ($scope.sales[idx].jx3 > 0 ? $scope.thou_sep($scope.sales[idx].jx3 + 'x3') : '') + " \n  " + ($scope.sales[idx].jx2 > 0 ? $scope.thou_sep($scope.sales[idx].jx2 + 'x2') : '') + " \n  " + ($scope.sales[idx].jx1 > 0 ? $scope.thou_sep($scope.sales[idx].jx1 + 'x1') : '') + " \n</dd>";
    t += "<dt>Доб. комбинација:</dt>\n<dd>\n  " + ($scope.sales[idx].jwcol.split('').join(' ')) + "\n</dd>";
    t += "</dl>";
    el = angular.element(document.querySelector("\#draw-" + $scope.sales[idx].draw));
    offset = $ionicPosition.offset(el);
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top;
    return $scope.bubble.html(t).style('left', (event.pageX + 10) + 'px').style('top', (new_top - 100) + 'px').style('opacity', 1);
  };
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
  queryYear = "SELECT A, dayOfWeek(B), \n       C, I, B, D, E, F, G, H,\n       J, K, L, M, N, O,\n       P, Q, R, S, T, U, V, W,\n       X\nWHERE YEAR(B) = " + $scope.year + "\nORDER BY A";
  $ionicLoading.show();
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
        lx6p: a[6],
        lx6: a[7],
        lx5: a[8],
        lx4: a[9],
        lwcol: a.slice(16, 24),
        jx6: a[10],
        jx5: a[11],
        jx4: a[12],
        jx3: a[13],
        jx2: a[14],
        jx1: a[15],
        jwcol: a[24]
      };
    });
    $scope.buildSeries();
    return $ionicLoading.hide();
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат податоци за " + $sope.year + " година. Пробај подоцна.",
      duration: 3000
    });
  });
  $scope.buildSeries = function() {
    var a, arr, i, j, len, ref, sale, series;
    arr = [[], [], [], [], [], [], [], []];
    ref = $scope.sales;
    for (j = 0, len = ref.length; j < len; j++) {
      sale = ref[j];
      arr[sale.dow].push({
        x: sale.date,
        y: sale.lotto,
        lx7: sale.lx7,
        draw: sale.draw
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
    queryYear = "SELECT A, dayOfWeek(B), \n        C, I, B, D, E, F, G, H,\n        J, K, L, M, N, O,\n        P, Q, R, S, T, U, V, W,\n        X\nWHERE YEAR(B) = " + $scope.year + "\nORDER BY A";
    $ionicLoading.show();
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
          lx6p: a[6],
          lx6: a[7],
          lx5: a[8],
          lx4: a[9],
          lwcol: a.slice(16, 24),
          jx6: a[10],
          jx5: a[11],
          jx4: a[12],
          jx3: a[13],
          jx2: a[14],
          jx1: a[15],
          jwcol: a[24]
        };
      });
      $scope.buildSeries();
      $scope.lineChart.hide = true;
      return $ionicLoading.hide();
    }).error(function(err) {
      return $ionicLoading.show({
        template: ("Не може да се вчитаат податоци за " + $sope.year + " година.") + " Пробај подоцна.",
        duration: 3000
      });
    });
  };
}).controller('LottoStats', function($scope, $http, $ionicLoading) {
  var $buildLottoFreqs, query;
  $scope.hideChart = true;
  $scope.sbarChart = {};
  $scope.sbarChart.title = 'Bar chart title';
  $scope.sbarChart.width = $scope.width;
  $scope.sbarChart.height = $scope.height;
  query = "SELECT A, B, P, Q, R, S, T, U, V, W\nORDER BY B";
  $ionicLoading.show();
  $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winColumns = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        draw: a[0],
        date: a[1],
        lotto: [a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9]]
      };
    });
    $buildLottoFreqs();
    return $ionicLoading.hide();
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат добитните комбинации. Пробај подоцна.",
      duration: 3000
    });
  });
  return $buildLottoFreqs = function() {
    var a, arr, i, j, k, l, len, n, ref, ref1, results, results1, row;
    arr = (function() {
      results = [];
      for (j = 0; j <= 34; j++){ results.push(j); }
      return results;
    }).apply(this).map(function(e) {
      return [0, 1, 2, 3, 4, 5, 6, 7].map(function() {
        return 0;
      });
    });
    ref = $scope.winColumns;
    for (k = 0, len = ref.length; k < len; k++) {
      row = ref[k];
      ref1 = row.lotto;
      for (i in ref1) {
        n = ref1[i];
        arr[n][i]++;
      }
    }
    for (i in arr) {
      a = arr[i];
      arr[i].push(a.reduce(function(t, e) {
        return t + e;
      }));
    }
    $scope.freqs = arr.slice(1).map(function(a, i) {
      return {
        number: i + 1,
        '1ви': a[0],
        '2ри': a[1],
        '3ти': a[2],
        '4ти': a[3],
        '5ти': a[4],
        '6ти': a[5],
        '7ми': a[6],
        'доп.': a[7],
        total: a[8]
      };
    });
    $scope.sbarChart.data = $scope.freqs;
    $scope.sbarChart.labels = 'number';
    $scope.sbarChart.labVals = (function() {
      results1 = [];
      for (l = 1; l <= 34; l++){ results1.push(l); }
      return results1;
    }).apply(this).filter(function(v) {
      return v % 2 !== 0;
    });
    return $scope.sbarChart.categories = ['1ви', '2ри', '3ти', '4ти', '5ти', '6ти', '7ми', 'доп.'];
  };
}).controller('JokerStats', function($scope, $http, $ionicLoading) {
  var $buildJokerFreqs, query;
  $scope.hideChart = true;
  $scope.sbarChart = {};
  $scope.sbarChart.title = 'Bar chart title';
  $scope.sbarChart.width = $scope.width;
  $scope.sbarChart.height = $scope.height;
  query = "SELECT A, B, X\nORDER BY B";
  $ionicLoading.show();
  $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winColumns = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        draw: a[0],
        date: a[1],
        joker: a[2].split('')
      };
    });
    $buildJokerFreqs();
    return $ionicLoading.hide();
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат добитните комбинации. Пробај подоцна.",
      duration: 3000
    });
  });
  return $buildJokerFreqs = function() {
    var a, arr, i, j, len, n, ref, ref1, row;
    arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(function(e) {
      return [0, 1, 2, 3, 4, 5].map(function() {
        return 0;
      });
    });
    ref = $scope.winColumns;
    for (j = 0, len = ref.length; j < len; j++) {
      row = ref[j];
      ref1 = row.joker;
      for (i in ref1) {
        n = ref1[i];
        arr[n][i]++;
      }
    }
    for (i in arr) {
      a = arr[i];
      arr[i].push(a.reduce(function(t, e) {
        return t + e;
      }));
    }
    $scope.freqs = arr.map(function(a, i) {
      return {
        number: i,
        '1ви': a[0],
        '2ри': a[1],
        '3ти': a[2],
        '4ти': a[3],
        '5ти': a[4],
        '6ти': a[5],
        total: a[6]
      };
    });
    $scope.sbarChart.data = $scope.freqs;
    $scope.sbarChart.labels = 'number';
    return $scope.sbarChart.categories = ['1ви', '2ри', '3ти', '4ти', '5ти', '6ти'];
  };
}).controller('WinnersStats', function($scope, $http, $ionicLoading, $ionicPosition, $ionicScrollDelegate) {
  var query, qx6, qx6p, qx7;
  $scope.bubbleVisible = false;
  $scope.bubble = d3.select('#stats-list').append('div').attr('class', 'bubble bubble-left').attr('id', 'winners-bubble').on('click', function() {
    $scope.bubble.transition().duration(1000).style('opacity', 0);
    return $scope.bubbleVisible = false;
  }).style('opacity', 0);
  $scope.showBubble = function(event, idx) {
    var el, new_top, offset, t;
    if ($scope.bubbleVisible) {
      return;
    }
    event.stopPropagation();
    $scope.bubbleVisible = true;
    t = "<div class='row row-no-padding'>\n  <div class='col col-offset-80 text-right positive'>\n    <small><i class='ion-close-round'></i></small>\n  </div>\n</div>\n<dl class='dl-horizontal'>\n  <dt>Година:</dt>\n  <dd>" + $scope.winners[idx].year + "</dd>\n  <dt>Вкупно кола:</dt>\n  <dd>" + $scope.winners[idx].draws + "</dd>\n  <hr />\n  <dt>Лото:</dt><dd></dd>\n  <hr />\n  <dt>Најмала уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].min)) + "</dd>\n  <dt>Просечна уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].avg)) + "</dd>\n  <dt>Најголема уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].max)) + "</dd>\n  <hr />\n  <dt>Џокер:</dt><dd></dd>\n  <hr />\n  <dt>Најмала уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].jmin)) + "</dd>\n  <dt>Просечна уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].javg)) + "</dd>\n  <dt>Најголема уплата:</dt>\n  <dd>" + ($scope.thou_sep($scope.winners[idx].jmax)) + "</dd>\n</dl>";
    el = angular.element(document.querySelector("\#winners-" + $scope.winners[idx].year));
    offset = $ionicPosition.offset(el);
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top;
    return $scope.bubble.html(t).style('left', (event.pageX + 10) + 'px').style('top', (new_top - 60) + 'px').style('opacity', 1);
  };
  $ionicLoading.show();
  qx7 = "SELECT\n  YEAR(B), COUNT(D)\nWHERE D > 0\nGROUP BY YEAR(B)\nORDER BY YEAR(B)";
  $http.get($scope.qurl(qx7)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winX7 = {};
    return res.table.rows.forEach(function(r) {
      var a;
      a = $scope.eval_row(r);
      return $scope.winX7[a[0]] = a[1];
    });
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат добитници x7. Пробај подоцна.",
      duration: 3000
    });
  });
  qx6p = "SELECT\n  YEAR(B), COUNT(E)\nWHERE E > 0\nGROUP BY YEAR(B)\nORDER BY YEAR(B)";
  $http.get($scope.qurl(qx6p)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winX6p = {};
    return res.table.rows.forEach(function(r) {
      var a;
      a = $scope.eval_row(r);
      return $scope.winX6p[a[0]] = a[1];
    });
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат добитници x6+1. Пробај подоцна.",
      duration: 3000
    });
  });
  qx6 = "SELECT\n  YEAR(B), COUNT(F)\nWHERE F > 0\nGROUP BY YEAR(B)\nORDER BY YEAR(B)";
  $http.get($scope.qurl(qx6)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winX6 = {};
    return res.table.rows.forEach(function(r) {
      var a;
      a = $scope.eval_row(r);
      return $scope.winX6[a[0]] = a[1];
    });
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчитаат добитници x6. Пробај подоцна.",
      duration: 3000
    });
  });
  query = "SELECT \n   YEAR(B), COUNT(A), MIN(C), MAX(C), AVG(C),\n   SUM(D), SUM(E), AVG(F), AVG(G), AVG(H),\n   MIN(I), MAX(I), AVG(I)\nGROUP BY YEAR(B)\nORDER BY YEAR(B)";
  return $http.get($scope.qurl(query)).success(function(data, status) {
    var res;
    res = $scope.to_json(data);
    $scope.winners = res.table.rows.map(function(r) {
      var a;
      a = $scope.eval_row(r);
      return {
        year: a[0],
        draws: a[1],
        min: a[2],
        max: a[3],
        avg: Math.round(a[4]),
        jmin: a[10],
        jmax: a[11],
        javg: Math.round(a[12]),
        x7: a[5],
        'x6+1': a[6],
        x6: Math.round(a[7]),
        x5: Math.round(a[8]),
        x4: Math.round(a[9])
      };
    });
    return $ionicLoading.hide();
  }).error(function(err) {
    return $ionicLoading.show({
      template: "Не може да се вчита статистика на добитници. Пробај подоцна.",
      duration: 3000
    });
  });
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
      var color, g, lab, legend, margin, r, remapped, stacked, svg, tooltip, x, xAxis, y, yAxis;
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
        top: 35,
        right: 120,
        bottom: 30,
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
        if (d > 100000.0) {
          return Math.round(d / 10000) / 100 + " M";
        } else {
          return scope.thou_sep(d);
        }
      }).orient('left');
      x = d3.scale.ordinal().rangeRoundBands([0, scope.sbarChart.width], 0.3, 0.2);
      xAxis = d3.svg.axis().scale(x).orient('bottom');
      if (scope.sbarChart.labVals != null) {
        xAxis.tickValues(scope.sbarChart.labVals);
      }
      x.domain(stacked[0].map(function(d) {
        return d.x;
      }));
      svg.append('g').attr('class', 'x axis').attr('transform', "translate(0, " + scope.sbarChart.height + ")").call(xAxis);
      y.domain([
        0, d3.max(stacked.slice(-1)[0], function(d) {
          return d.y0 + d.y;
        })
      ]);
      svg.append('g').attr('class', 'y axis').transition().duration(1000).call(yAxis).selectAll('line').style("stroke-dasharray", "3, 3");
      color = d3.scale.category20();
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
        t = "<p style='text-align: center;'>\n  <b>" + d.cat + "/" + d.x + "</b>\n  <hr /></p>\n<p style='text-align: center'>  \n  " + (scope.thou_sep(d.y)) + "\n</p>";
        tooltip.html('');
        tooltip.transition().duration(1000).style('opacity', 0.75);
        tooltip.html(t).style('left', (d3.event.pageX + 10) + 'px').style('top', (d3.event.pageY - 75) + 'px').style('opacity', 1);
        return tooltip.transition().duration(3000).style('opacity', 0);
      }).append('title').html(function(d) {
        return "<strong>" + d.cat + "/" + d.x + "</strong>: " + (scope.thou_sep(d.y));
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
      var d, i, j, legend, len, line, margin, ref, s, svg, tooltip, w, win, ww, x, xAxis, y, yAxis, ymax;
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
        top: 35,
        right: 120,
        bottom: 30,
        left: 40
      };
      tooltip = d3.select(el[0]).append('div').attr('class', 'tooltip').style('opacity', 0);
      svg = d3.select(el[0]).append('svg').attr('width', scope.lineChart.width + margin.left + margin.right).attr('height', scope.lineChart.height + margin.top + margin.bottom).append('g').attr('transform', "translate(" + margin.left + ", " + margin.top + ")");
      y = d3.scale.linear().rangeRound([scope.lineChart.height, 0]);
      yAxis = d3.svg.axis().scale(y).orient('left');
      ymax = d3.max(scope.series.map(function(s) {
        return d3.max(s.data.map(function(d) {
          return d.y;
        }));
      }));
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
      svg.append('text').attr('x', scope.lineChart.width / 2).attr('y', y(20 + ymax)).attr('dy', '-0.35em').attr('text-anchor', 'middle').attr('class', 'line-chart-title').text(scope.lineChart.title);
      line = d3.svg.line().interpolate("monotone").x(function(d) {
        return x(d.x);
      }).y(function(d) {
        return y(d.y);
      });
      win = [];
      ref = scope.series;
      for (i in ref) {
        s = ref[i];
        svg.append('path').datum(s.data).attr('class', 'line').attr('stroke', d3.scale.category10().range()[i]).attr('d', line);
        win[i] = s.data.filter(function(d) {
          return d.lx7 > 0;
        });
      }
      for (i in win) {
        w = win[i];
        for (j = 0, len = w.length; j < len; j++) {
          ww = w[j];
          d = [
            {
              x: ww.x,
              y: 0,
              draw: ww.draw
            }, ww
          ];
          svg.append('path').datum(d).attr('id', "draw-" + ww.draw).attr('class', 'line').attr('stroke', d3.scale.category10().range()[i]).attr('stroke-dasharray', '0.8 1.6').on('click', function(d, i) {
            var t;
            t = "<p style='text-align: center;'>\n  <b>коло: " + d[1].draw + "</b><br />\n</p>";
            tooltip.html(t);
            tooltip.transition().duration(1000).style('opacity', 0.75);
            tooltip.html(t).style('left', d3.event.pageX + 'px').style('top', (d3.event.pageY - 60) + 'px').style('opacity', 1);
            return tooltip.transition().duration(3500).style('opacity', 0);
          }).attr('d', line).append('title').html(function(d, i) {
            return "<strong>коло: " + d[1].draw + "</strong>";
          });
        }
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

angular.module('app.util', []).controller('Upload', function($scope, $rootScope, $ionicPopup, $state, $timeout, $ionicLoading, $http) {
  var popup;
  $scope.dateToDMY = function(d) {
    return (new Date(d.getTime() - d.getTimezoneOffset() * 60 * 1000)).toISOString().slice(0, 10).split('-').reverse().join('.');
  };
  $scope.nextd = $scope.nextDraw($rootScope.lastDraw);
  $scope.URL = "http://test.lotarija.mk/Results/" + "WebService.asmx/GetDetailedReport";
  $scope.appendURL = "https://script.google.com/macros/s/" + "AKfycbxn66xXetBH2YV1WI0FnvdqFPL6Jpkvx6xzmnCBGhGz-_BGFHw/exec";
  $scope.getDraw = function(year, draw, fn) {
    var req;
    req = {
      url: $scope.URL,
      method: 'POST',
      data: {
        godStr: year.toString(),
        koloStr: draw.toString()
      },
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };
    return $http(req).success(function(data, status) {
      var res;
      res = $scope.parseDraw(data.d);
      res.draw = draw;
      console.log(res);
      if (fn) {
        return fn(res);
      }
    }).error(function(data, status) {
      return console.log("Error: " + status);
    });
  };
  $scope.serialize = function(rec) {
    return ("draw=" + rec.draw) + ("&date=" + rec.date) + ("&lsales=" + rec.lsales) + ("&x7=" + rec.x7 + "&x6p=" + rec.x6p + "&x6=" + rec.x6) + ("&x5=" + rec.x5 + "&x4=" + rec.x4) + ("&jsales=" + rec.jsales) + ("&jx6=" + rec.jx6 + "&jx5=" + rec.jx5 + "&jx4=" + rec.jx4) + ("&jx3=" + rec.jx3 + "&jx2=" + rec.jx2 + "&jx1=" + rec.jx1) + ("&l1=" + rec.lwcol[0] + "&l2=" + rec.lwcol[1]) + ("&l3=" + rec.lwcol[2] + "&l4=" + rec.lwcol[3]) + ("&l5=" + rec.lwcol[4] + "&l6=" + rec.lwcol[5]) + ("&l7=" + rec.lwcol[6] + "&lp=" + rec.lwcol[7]) + ("&jwcol=" + rec.jwcol);
  };
  $scope.toYMD = function(s) {
    var match, re;
    re = /^(\d\d).(\d\d).(\d\d\d\d)$/;
    match = re.exec(s);
    if (!match) {
      throw "toYMD(): invalid format " + s;
    }
    return match.slice(1, 4).reverse().join('-');
  };
  $scope.strip = function(s) {
    var match, re;
    re = /([\d.]*)/;
    match = re.exec(s);
    return match[1].replace(/\./g, '');
  };
  $scope.parseDraw = function(text) {
    var match, re, res, t, tab;
    res = {};
    re = /<th>Датум на извлекување:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>/m;
    match = re.exec(text);
    res.date = $scope.toYMD(match[1]);
    re = /<p>Редослед на извлекување:\s*([\d,]+)\.?\s*<\/p>/m;
    match = re.exec(text);
    if (!match) {
      throw "can't extract lotto winning column!";
    }
    res.lwcol = match[1].split(/\s*,\s*/).map(function(e) {
      return parseInt(e);
    });
    re = /<div\s+id="joker">\s*(\d+)\s*<\/div>/m;
    match = re.exec(text);
    if (!match) {
      throw "can't extract joker winning column!";
    }
    res.jwcol = match[1];
    re = /<th>Уплата:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>(.*)/m;
    match = re.exec(text);
    if (!match) {
      throw "can't extract lotto sales!";
    }
    res.lsales = parseInt($scope.strip(match[1]));
    t = match[2];
    re = /<th>Уплата:<\/th>\s*<td[^>]*>([^>]*)\s*<\/td>/m;
    match = re.exec(t);
    if (!match) {
      throw "can't extract joker sales!";
    }
    res.jsales = parseInt($scope.strip(match[1]));
    re = /<table\s+class="nl734"\s*>(.*?)<\/table>/gm;
    tab = text.match(re);
    if (!tab) {
      raise("can't extract lotto winners!");
    }
    tab = tab[1];
    re = /<tbody>\s*(.*?)\s*<\/tbody>/m;
    tab = re.exec(tab);
    re = /<tr>\s*<th>\s*(.*?)\s*<\/th>\s*<td>\s*(.*?)\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<\/tr>(.*)/m;
    match = re.exec(tab[1]);
    while (match) {
      switch (match[1]) {
        case "7 погодоци":
          res.x7 = parseInt(match[2]);
          break;
        case "6+1 погодоци":
          res.x6p = parseInt(match[2]);
          break;
        case "6 погодоци":
          res.x6 = parseInt(match[2]);
          break;
        case "5 погодоци":
          res.x5 = parseInt(match[2]);
          break;
        case "4 погодоци":
          res.x4 = parseInt(match[2]);
      }
      tab = match[4];
      match = re.exec(tab);
    }
    re = /<table\s+class="j734"\s*>(.*?)<\/table>/gm;
    tab = text.match(re);
    if (!tab) {
      raise("can't extract joker winners!");
    }
    tab = tab[1];
    re = /<tbody>\s*(.*?)\s*<\/tbody>/m;
    tab = re.exec(tab);
    re = /<tr>\s*<th>\s*(.*?)\s*<\/th>\s*<td>\s*.*?\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<\/tr>(.*)/m;
    match = re.exec(tab[1]);
    while (match) {
      switch (match[1]) {
        case "6 погодоци":
          res.jx6 = parseInt(match[2]);
          break;
        case "5 погодоци":
          res.jx5 = parseInt(match[2]);
          break;
        case "4 погодоци":
          res.jx4 = parseInt(match[2]);
          break;
        case "3 погодоци":
          res.jx3 = parseInt(match[2]);
          break;
        case "2 погодоци":
          res.jx2 = parseInt(match[2]);
          break;
        case "1 погодок":
          res.jx1 = parseInt(match[2]);
      }
      tab = match[4];
      match = re.exec(tab);
    }
    return res;
  };
  popup = {
    title: 'Освежи',
    cssClass: 'upload',
    template: "Додади податоци за <strong>" + $scope.nextd.draw + "</strong>\nколо од " + ($scope.dateToDMY($scope.nextd.date)),
    cancelText: 'Откажи',
    cancelType: 'button-assertive',
    okText: 'Додади',
    okType: 'button-positive'
  };
  return $ionicPopup.confirm(popup).then(function(res) {
    var draw, year;
    console.log("Confirmed, res = " + res);
    if (res) {
      $ionicLoading.show();
      draw = $scope.nextd.draw;
      year = $scope.nextd.date.getFullYear();
      return $scope.getDraw(year, draw, function(rec) {
        var req;
        req = {
          url: $scope.appendURL,
          method: 'POST',
          data: $scope.serialize(rec),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json'
          }
        };
        return $http(req).success(function(data, status) {
          console.log("Success: " + data);
          $ionicLoading.hide();
          $rootScope.lastDraw = $scope.nextd;
          $rootScope.uploadNeeded = $rootScope.checkUpload();
          $rootScope.$apply;
          console.log("Root scope");
          console.log("last draw: ", $rootScope.lastDraw);
          console.log("upload needed: ", $rootScope.uploadNeeded);
          return $state.go('home');
        }).error(function(err) {
          console.log("Error: " + err);
          $ionicLoading.show({
            template: "Не може да се вчитаат податоци",
            duration: 3000
          });
          return $state.go('home');
        });
      });
    } else {
      return $state.go('home');
    }
  });
}).controller('About', function($scope, $http) {});
