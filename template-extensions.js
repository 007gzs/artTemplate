/*!
 * artTemplate - Syntax Extensions
 * https://github.com/aui/artTemplate
 * Released under the MIT, BSD, and GPL Licenses
 * Email: 1987.tangbin@gmail.com
 */
 
(function (exports) {

exports.openTag = '{';
exports.closeTag = '}';

exports.parser = function (code) {
    code = code.replace(/^\s/, '');
    
    var args = code.split(' ');
    var key = args.shift();
    var fuc = exports.keywords[key];
    
    if (fuc) {
        args = args.join(' ');
        code = fuc.call(code, args);
    } else {
        code = '=$escape(' + code + ')';
    }
    
    return code;
};


exports.keywords = {
    
    'if': function (code) {
        return 'if(' + code + '){';
    },
    
    'else': function (code) {
        code = code.split(' ');
        
        if (code.shift() === 'if') {
            code = ' if(' + code.join(' ') + ')';
        } else {
            code = '';
        }

        return '}else' + code + '{';
    },
    
    '/if': function () {
        return '}';
    },
    
    'each': function (code) {
        
        code = code.split(' ');
        
        var object = code[0] || '$data';
        var as     = code[1] || 'as';
        var value  = code[2] || '$value';
        var index  = code[3] || '$index';
        
        var args   = value + ',' + index;
        
        if (as !== 'as') {
            object = '[]';
        }
        
        return '$each(' + object + ',function(' + args + '){';
    },
    
    '/each': function () {
        return '});';
    },
    
    'echo': function (code) {
        return '=' + code;
    },
    
    'include': function (code) {
        code = code.split(' ');
    
        var id = code[0];
        var data = code[1];

        return '=include(' + id + ',' + data + ')';
    }

};


exports.helper('$each', function (data, callback) {
     
    if (_isArray(data)) {
        _forEach.call(data, callback);
    } else {
        for (var i in data) {
            callback.call(data, data[i], i);
        }
    }
    
});

exports.helper('$escape', (function () {

    var badChars = /&(?!\w+;)|[<>"']/g;
    var map = {
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#x27;",
        "&": "&amp;"
    };
  
    
    var fn = function (s) {
        return map[s] || s;
    };
    
    return function (content) {
        return typeof content === 'string'
        ? content.replace(badChars, fn)
        : content;
    };

})());

var _forEach = exports.helper('$forEach');
var _toString = Object.prototype.toString;
var _isArray = Array.isArray || function (obj) {
    return _toString.call(obj) === '[object Array]';
};


})(template);
