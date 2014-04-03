/*!
 * artTemplate - Template Engine
 * https://github.com/aui/artTemplate
 * Released under the MIT, BSD, and GPL Licenses
 */
 
(function (global) {

'use strict';


/**
 * 模板引擎
 * @name    template
 * @param   {String}            模板名
 * @param   {Object, String}    数据。如果为字符串则编译并缓存编译结果
 * @return  {String, Function}  渲染好的HTML字符串或者渲染方法
 */
var template = function (filename, content) {

    if (typeof content === 'string') {
        return cacheStore[filename] = template.compile(content, {
            filename: filename
        });
    } else {
        
        return template.renderByFilename(filename, content);
    }
};


template.version = '3.0.0';



/*template.defaults.openTag = '<%';    // 设置逻辑语法开始标签
template.defaults.closeTag = '%>';   // 设置逻辑语法结束标签
template.defaults.escape = true;     // HTML字符编码输出开关
template.defaults.compress = false;  // 剔除渲染后HTML多余的空白开关
template.defaults.parser = null;     // 语法格式器*/
template.defaults = {
    openTag: '<%',    // 逻辑语法开始标签
    closeTag: '%>',   // 逻辑语法结束标签
    escape: true,     // HTML字符编码输出开关
    compress: false,  // 剔除渲染后HTML多余的空白开关
    parser: null      // 语法格式器
}



/**
 * 渲染模板
 * @name    template.render
 * @param   {String}    模板
 * @param   {Object}    数据
 * @return  {String}    渲染好的字符串
 */
template.render = function (source, options) {
    options = options || {};
    var fn;

    if (options.cache) {
        var filename = options.filename;
        if (filename) {
            fn = cacheStore[filename]
            || (cacheStore[filename] = template.compile(source, options));
        } else {
            throw new Error('"cache" option requires "filename".');
        }
    } else {
        fn = template.compile(source, options);
    }

    return fn(options);
};



/**
 * 渲染模板(根据模板名)
 * @name    template.render
 * @param   {String}    模板名
 * @param   {Object}    数据
 * @return  {String}    渲染好的字符串
 */
template.renderByFilename = function (filename, data) {
    var fn = template.get(filename) || showDebugInfo({
        filename: filename,
        name: 'Render Error',
        message: 'Template not found'
    });
    return fn(data); 
}


/**
 * 编译模板
 * 2012-6-6 @TooBug: define 方法名改为 compile，与 Node Express 保持一致
 * @name    template.compile
 * @param   {String}    模板字符串
 * @param   {Object}    编译选项
 *
 *      - openTag       {String}
 *      - closeTag      {String}
 *      - filename      {String}
 *      - escape        {Boolean}
 *      - compress      {Boolean}
 *      - debug         {Boolean}
 *      - cache         {Boolean}
 *      - parser        {Function}
 *
 * @return  {Function}  渲染方法
 */
template.compile = function (source, options) {
    
    options = options || {};

    var filename = options.filename || '';

    try {
        
        var Render = compiler(source, options);
        
    } catch (e) {
    
        e.filename = filename;
        e.name = 'Syntax Error';

        return showDebugInfo(e);
        
    }
    
    
    // 对编译结果进行一次包装

    function render (data) {
        
        try {
            
            return new Render(data, filename) + '';
            
        } catch (e) {
            
            // 运行时出错后自动开启调试模式重新编译
            if (!options.debug) {
                options.debug = true;
                return template.compile(source, options)(data);
            }
            
            return showDebugInfo(e)();
            
        }
        
    }
    

    render.prototype = Render.prototype;
    render.toString = function () {
        return Render.toString();
    };

    
    return render;

};



var cacheStore = template.cache = {};




// ------ 辅助方法 ------

var toString = function (value, type) {

    if (typeof value !== 'string') {

        type = typeof value;
        if (type === 'number') {
            value += '';
        } else if (type === 'function') {
            value = toString(value.call(value));
        } else {
            value = '';
        }
    }

    return value;

};


var escapeMap = {
    "<": "&#60;",
    ">": "&#62;",
    '"': "&#34;",
    "'": "&#39;",
    "&": "&#38;"
};


var escapeFn = function (s) {
    return escapeMap[s];
};

var escapeHTML = function (content) {
    return toString(content)
    .replace(/&(?![\w#]+;)|[<>"']/g, escapeFn);
};


var isArray = Array.isArray || function (obj) {
    return ({}).toString.call(obj) === '[object Array]';
};


var each = function (data, callback) {           
    if (isArray(data)) {
        for (var i = 0, len = data.length; i < len; i++) {
            callback.call(data, data[i], i, data);
        }
    } else {
        for (i in data) {
            callback.call(data, data[i], i);
        }
    }
};

var helpers = template.helpers = {

    $include: template.renderByFilename,

    $string: toString,

    $escape: escapeHTML,

    $each: each
    
};




/**
 * 添加模板辅助方法
 * @name    template.helper
 * @param   {String}    名称
 * @param   {Function}  方法
 */
template.helper = function (name, helper) {
    helpers[name] = helper;
};




/**
 * 模板错误事件（可由外部重写此方法）
 * @name    template.onerror
 * @event
 */
template.onerror = function (e) {
    var message = 'Template Error\n\n';
    for (var name in e) {
        message += '<' + name + '>\n' + e[name] + '\n\n';
    }
    
    if (global.console) {
        console.error(message);
    }
};




/**
 * 获取编译缓存（可由外部重写此方法）
 * @param   {String}    模板名
 * @param   {Function}  编译好的函数
 */
template.get = function (filename) {

    var cache;
    
    if (cacheStore.hasOwnProperty(filename)) {
        // 查找缓存
        cache = cacheStore[filename];
    } else {
        // 加载模板并编译
        var source = template.loadTemplate(filename);
        if (typeof source === 'string') {
            cache = cacheStore[filename] = template.compile(source, {
                filename: filename
            });
        }
    }

    return cache;
};



/**
 * 加载模板源文件（可由外部重写此方法）
 * 如果使用文件路径来表示模板名，通常还需要
 * 复写 template.helpers.$include 方法进行绝对路径转换
 * @see     node-template.js
 * @param   {String}    模板名
 * @return  {String}    模板内容
 */
template.loadTemplate = function (filename) {
    if ('document' in global) {
        var elem = document.getElementById(filename);
        
        if (elem) {
            return (elem.value || elem.innerHTML)
            .replace(/^\s*|\s*$/g, '');
        }
    }
};



// 模板调试器
var showDebugInfo = function (e) {

    template.onerror(e);
    
    return function () {
        return '{Template Error}';
    };
};



// ------ 编译器 ------



// 数组迭代
var forEach = helpers.$each;


// 静态分析模板变量
var KEYWORDS =
    // 关键字
    'break,case,catch,continue,debugger,default,delete,do,else,false'
    + ',finally,for,function,if,in,instanceof,new,null,return,switch,this'
    + ',throw,true,try,typeof,var,void,while,with'

    // 保留字
    + ',abstract,boolean,byte,char,class,const,double,enum,export,extends'
    + ',final,float,goto,implements,import,int,interface,long,native'
    + ',package,private,protected,public,short,static,super,synchronized'
    + ',throws,transient,volatile'

    // ECMA 5 - use strict
    + ',arguments,let,yield'

    + ',undefined';

var REMOVE_RE = /\/\*[\w\W]*?\*\/|\/\/[^\n]*\n|\/\/[^\n]*$|"(?:[^"\\]|\\[\w\W])*"|'(?:[^'\\]|\\[\w\W])*'|[\s\t\n]*\.[\s\t\n]*[$\w\.]+/g;
var SPLIT_RE = /[^\w$]+/g;
var KEYWORDS_RE = new RegExp(["\\b" + KEYWORDS.replace(/,/g, '\\b|\\b') + "\\b"].join('|'), 'g');
var NUMBER_RE = /^\d[^,]*|,\d[^,]*/g;
var BOUNDARY_RE = /^,+|,+$/g;


// 获取变量
var getVariable = function (code) {
    return code
    .replace(REMOVE_RE, '')
    .replace(SPLIT_RE, ',')
    .replace(KEYWORDS_RE, '')
    .replace(NUMBER_RE, '')
    .replace(BOUNDARY_RE, '')
    .split(/^$|,+/);
};



var compiler = function (source, options) {

    // 合并默认配置
    var defaults = template.defaults;
    for (var name in defaults) {
        if (options[name] === undefined) {
            options[name] = defaults[name];
        }
    }

    
    var filename = options.filename;
    var debug = options.debug;
    var openTag = options.openTag;
    var closeTag = options.closeTag;
    var parser = options.parser;
    var compress = options.compress;
    var escape = options.escape;
    

    var code = source;
    var tempCode = '';
    var line = 1;
    var uniq = {$data:1,$filename:1,$helpers:1,$out:1,$line:1};
    var prototype = {};

    
    var variables = "var $helpers=this,"
    + (debug ? "$line=0," : "");

    var isNewEngine = ''.trim;// '__proto__' in {}
    var replaces = isNewEngine
    ? ["$out='';", "$out+=", ";", "$out"]
    : ["$out=[];", "$out.push(", ");", "$out.join('')"];

    var concat = isNewEngine
        ? "$out+=text;return $out;"
        : "$out.push(text);";
          
    var print = "function(text){" + concat + "}";

    //print = "function(){$out.push.apply($out,arguments)}";
    //print = "function(){$out=$out.concat.apply($out,arguments);return $out}"

    var include = "function(filename,data){"
    +     "data=data||$data;"
    +     "var text=$helpers.$include(filename,data,$filename);"
    +     concat
    + "}";
    
    
    // html与逻辑语法分离
    forEach(code.split(openTag), function (code) {
        code = code.split(closeTag);
        
        var $0 = code[0];
        var $1 = code[1];
        
        // code: [html]
        if (code.length === 1) {
            
            tempCode += html($0);
         
        // code: [logic, html]
        } else {
            
            tempCode += logic($0);
            
            if ($1) {
                tempCode += html($1);
            }
        }
        

    });
    
    
    
    code = tempCode;
    
    
    // 调试语句
    if (debug) {
        code = "try{" + code + "}catch(e){"
        +       "throw {"
        +           "filename:$filename,"
        +           "name:'Render Error',"
        +           "message:e.message,"
        +           "line:$line,"
        +           "source:" + stringify(source)
        +           ".split(/\\n/)[$line-1].replace(/^[\\s\\t]+/,'')"
        +       "};"
        + "}";
    }
    
    
    code = variables + replaces[0] + code
    + "return new String(" + replaces[3] + ");";
    
    
    try {
        
        var Render = new Function("$data", "$filename", code);
        Render.prototype = prototype;

        return Render;
        
    } catch (e) {
        e.temp = "function anonymous($data,$filename) {" + code + "}";
        throw e;
    }



    
    // 处理 HTML 语句
    function html (code) {
        
        // 记录行号
        line += code.split(/\n/).length - 1;

        // 压缩多余空白与注释
        if (compress) {
            code = code
            .replace(/[\n\r\t\s]+/g, ' ')
            .replace(/<!--.*?-->/g, '');
        }
        
        if (code) {
            code = replaces[1] + stringify(code) + replaces[2] + "\n";
        }

        return code;
    }
    
    
    // 处理逻辑语句
    function logic (code) {

        var thisLine = line;
       
        if (parser) {
        
             // 语法转换插件钩子
            code = parser(code);
            
        } else if (debug) {
        
            // 记录行号
            code = code.replace(/\n/g, function () {
                line ++;
                return "$line=" + line +  ";";
            });
            
        }
        
        
        // 输出语句. 转义: <%=value%> 不转义:<%=#value%>
        // <%=#value%> 等同 v2.0.3 之前的 <%==value%>
        if (code.indexOf('=') === 0) {

            var isEscape = !/^=[=#]/.test(code);

            code = code.replace(/^=[=#]?|[\s;]*$/g, '');

            if (isEscape && escape) {

                // 转义处理，但排除辅助方法
                var name = code.replace(/\s*\([^\)]+\)/, '');
                if (
                    !helpers.hasOwnProperty(name)
                    && !/^(include|print)$/.test(name)
                ) {
                    code = "$escape(" + code + ")";
                }

            } else {
                code = "$string(" + code + ")";
            }
            

            code = replaces[1] + code + replaces[2];

        }
        
        if (debug) {
            code = "$line=" + thisLine + ";" + code;
        }
        
        getKey(code);
        
        return code + "\n";
    }
    
    
    // 提取模板中的变量名
    function getKey (code) {
        
        code = getVariable(code);
        
        // 分词
        forEach(code, function (name) {
         
            // 除重
            // TODO: name 可能在低版本的安卓浏览器中为空值，这里后续需要改进 getVariable 方法
            // @see https://github.com/aui/artTemplate/issues/41#issuecomment-29985469
            if (name && !uniq.hasOwnProperty(name)) {
                setValue(name);
                uniq[name] = true;
            }
            
        });
        
    }
    
    
    // 声明模板变量
    // 赋值优先级:
    // 内置特权方法(include, print) > 私有模板辅助方法 > 数据 > 公用模板辅助方法
    function setValue (name) {

        var value;

        if (name === 'print') {

            value = print;

        } else if (name === 'include') {
            
            prototype["$include"] = helpers['$include'];
            value = include;
            
        } else {

            value = "$data." + name;

            if (helpers.hasOwnProperty(name)) {

                prototype[name] = helpers[name];

                if (name.indexOf('$') === 0) {
                    value = "$helpers." + name;
                } else {
                    value = value
                    + "===undefined?$helpers." + name + ":" + value;
                }
            }
            
            
        }
        
        variables += name + "=" + value + ",";
    }


    // 字符串转义
    function stringify (code) {
        return "'" + code
        // 单引号与反斜杠转义
        .replace(/('|\\)/g, '\\$1')
        // 换行符转义(windows + linux)
        .replace(/\r/g, '\\r')
        .replace(/\n/g, '\\n') + "'";
    }
    
    
};


// RequireJS && SeaJS
if (typeof define === 'function') {
    define(function() {
        return template;
    });

// NodeJS
} else if (typeof exports !== 'undefined') {
    module.exports = template;
} else {
    global.template = template;
}




})(this.window || global);

/*
修改历史：

接口变更：template.render(id, data) 修改为 template.render(source, data)
兼容解决方案：使用 template(id, data) 代替 template.render(id, data)

template.defaults.*
template.isEscape 变更为 template.defaults.escape
template.isCompress 变更为 template.defaults.compress
*/
