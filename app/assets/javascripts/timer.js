(function(){

    var _time_set, _time_passed = 0, _time_current = 0, interval;

    Timer = function (time1, time2) {
        return new Timer.fn.init(time1, time2);
    };

    Timer.fn = Timer.prototype = {
        constructor: Timer,
        init: function(time1, time2){
            _time_set = time1*60*60*1000;
            if(time1==0)
                _time_set = 60*60*60*60*1000;
            if (time2 != undefined) {_time_current = time_reverse_parser(time2)};
            return Timer.fn;
        },
        getSetTime: function(){
            return _time_set;
        },
        getTime: function(){
//            var pass_time = time_parser(_time_current);
            return _time_current;//pass_time;
        },
        getReverseTime: function(time){
//            var pass_time = time_parser(_time_passed);
            return _time_passed;//pass_time;
        },
        pauseTime: function(){
            clearInterval(interval);
        },
        startTime: function(){
            interval = setInterval(function(){
                _time_current = _time_current + 1000;
                _time_passed = _time_set - _time_current;
            }, 1000);
        },
        displayUpTime: function(){
            var text_node = time_parser(_time_current); //this.getTime();
            return text_node;
        },
        displayDownTime: function(){
            var text_node = time_parser(_time_passed); //this.getReverseTime();
            return text_node;
        }
    };
    function time_parser(time){
        var d = new Date(time - 19800000 );
        var a = d.toTimeString();
        return a.slice(0,8);
    }
    function time_reverse_parser(time){
        var d = time.split(":");
        return d[0]*60*60*1000 + d[1]*60*1000 + d[2]*1000;
    }
})();