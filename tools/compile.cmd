@if (0===0) @end/*
:: ----------------------------------------------------------
:: artTemplate - Tools
:: https://github.com/aui/artTemplate
:: Released under the MIT, BSD, and GPL Licenses
:: Email: 1987.tangbin@gmail.com
:: ----------------------------------------------------------

@echo off
call CScript.EXE "%~dpnx0" //Nologo //e:jscript %*
title artTemplateģ����빤��
goto cmd
*/

include('../template.js', 'UTF-8');
include('../extensions/template-syntax.js', 'UTF-8');
include('../test/js/beautify.js', 'UTF-8');

// ���ô������ģ�����
var $charset = 'UTF-8';

// ����ģ����Ŀ¼
var $path = './compile-test/';


var OS = {
	
	file: {
	
		/** 
		 * �ļ���ȡ
		 * @param	{String}		�ļ�·��
		 * @param	{String}		ָ���ַ���
		 * @param 	{Boolean} 		�Ƿ�Ϊ����������. Ĭ��false
		 * @return	{String} 	    �ļ�����
		 */
		read: function (path, charset, isBinary) {
			charset = charset || 'UTF-8';
			var stream = new ActiveXObject('adodb.stream');
			var fileContent;

			stream.type = isBinary ? 1 : 2;
			stream.mode = 3;
			stream.open();
			stream.charset = charset;
			try {
				stream.loadFromFile(path);
			} catch (e) {
				OS.console.log(path);
				throw e;
			}
			fileContent = new String(stream.readText());
			fileContent.charset = charset;
			stream.close();
			return fileContent.toString();
		},

		/**
		 * �ļ�д��
		 * @param 	{String} 		�ļ�·��
		 * @param 	{String} 		Ҫд�������
		 * @param	{String}		ָ���ַ���. Ĭ��'UTF-8'
		 * @param 	{Boolean} 		�Ƿ�Ϊ����������. Ĭ��false
		 * @return 	{Boolean} 		�����Ƿ�ɹ�
		 */
		 write: function (path, data, charset, isBinary) {
			var stream = new ActiveXObject('adodb.stream');
			
			stream.type = isBinary ? 1 : 2;

			if (charset) {
				stream.charset = charset;
			} else if (!isBinary) {
				stream.charset = 'UTF-8';
			}
			
			try {
				stream.open();
				if (!isBinary) {
					stream.writeText(data);
				} else {
					stream.write(data);
				}
				stream.saveToFile(path, 2);

				return true;
			} catch (e) {
				throw e;
			} finally {
				stream.close();
			}

			return true;
		},
		
		/**
		 * ö��Ŀ¼�������ļ���(������Ŀ¼�ļ�)
		 * @param	{String}	Ŀ¼
		 * @return	{Array}		�ļ��б�
		 */
		get: (function (path) {
			var fso = new ActiveXObject('Scripting.FileSystemObject');
			var listall = function (infd) {
			
				var fd = fso.GetFolder(infd + '\\');
				var fe = new Enumerator(fd.files);
				var list = [];
				
				while(!fe.atEnd()) { 
					list.push(fe.item() + '');
					fe.moveNext();
				}
				
				var fk = new Enumerator(fd.SubFolders);
				for (; !fk.atEnd(); fk.moveNext()) {
					list = list.concat(listall(fk.item()));
				}
				
				return list;
			};
			
			return function (path) {
				var list = [];
				try {
					list = listall(path);
				} catch (e) {
				}
				return list;
			}
		})()
	},
	
	app: {
	
		/**
		 * ��ȡ���в���
		 * @return	{Array}			�����б�
		 */
		getArguments: function () {
			var Arguments = WScript.Arguments;
			var length = Arguments.length;
			var args = [];
			
			if (length) {
				for (var i = 0; i < length; i ++) {
					args.push(Arguments(i));
				}
			}
			
			return args;
		},
		
		quit: function () {
			WScript.Quit(OS.app.errorlevel);
		},
		
		errorlevel: 0
	},
	
	// ����̨
	console: {
		error: function (message) {
			OS.app.errorlevel = 1;
			WScript.Echo(message);
		},
		log: function (message) {
			WScript.Echo(message);
		}
	}
};

var Global = this;
var console = OS.console;
var log = console.log;
var error = console.error;

function include (path, charset) {
	this.$dependencies = this.$dependencies || [];
	this.$dependencies.push(arguments);
}

this.$dependencies = this.$dependencies || [];
for (var i = 0; i < this.$dependencies.length; i ++) {
	Global.eval(OS.file.read(this.$dependencies[i][0], this.$dependencies[i][1]));
}


/*-----*/


if (!Array.prototype.forEach) {
  // ES5 15.4.4.18
  // https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/array/foreach
  Array.prototype.forEach = function(fn, context) {
    for (var i = 0, len = this.length >>> 0; i < len; i++) {
      if (i in this) {
        fn.call(context, this[i], i, this);
      }
    }
  }; 
}

if (!String.prototype.trim) {
String.prototype.trim = (function() {

    // http://perfectionkills.com/whitespace-deviations/
    var whiteSpaces = [

      '\\s',
      '00A0', // 'NO-BREAK SPACE'
      '1680', // 'OGHAM SPACE MARK'
      '180E', // 'MONGOLIAN VOWEL SEPARATOR'
      '2000-\\u200A',
      '200B', // 'ZERO WIDTH SPACE (category Cf)
      '2028', // 'LINE SEPARATOR'
      '2029', // 'PARAGRAPH SEPARATOR'
      '202F', // 'NARROW NO-BREAK SPACE'
      '205F', // 'MEDIUM MATHEMATICAL SPACE'
      '3000' //  'IDEOGRAPHIC SPACE'

    ].join('\\u');

    var trimLeftReg = new RegExp('^[' + whiteSpaces + ']+');
    var trimRightReg = new RegExp('[' + whiteSpaces + ']+$');

    return function() {
      return String(this).replace(trimLeftReg, '').replace(trimRightReg, '');
    }

  })();
}



var compileTemplate = (function () {


// ��װ��SeaJSģ��
var toAMD = function (code) {

    template.onerror = function (e) {
        throw e;
    };

    var render = template.compile(code);
    var prototype = render.prototype;

    render = render.toString().replace(/^function\s+(anonymous)/, 'function');

    // ��ȡincludeģ��
    // @see https://github.com/seajs/seajs/blob/master/src/util-deps.js
    //var REQUIRE_RE = /"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|\/\*[\S\s]*?\*\/|\/(?:\\\/|[^/\r\n])+\/(?=[^\/])|\/\/.*|\.\s*include|(?:^|[^$])\binclude\s*\(\s*(["'])(.+?)\1\s*\)/g; //"
    var REQUIRE_RE = /"(?:\\"|[^"])*"|'(?:\\'|[^'])*'|\/\*[\S\s]*?\*\/|\/(?:\\\/|[^/\r\n])+\/(?=[^\/])|\/\/.*|\.\s*include|(?:^|[^$])\binclude\s*\(\s*(["'])(.+?)\1\s*(,\s*(.+?)\s*)?\)/g; //"
	var SLASH_RE = /\\\\/g

    function parseDependencies(code) {
      var ret = []

      code.replace(SLASH_RE, "")
          .replace(REQUIRE_RE, function(m, m1, m2) {
            if (m2) {
              ret.push(m2)
            }
          })

      return ret
    };

    var dependencies = [];
    parseDependencies(render).forEach(function (id) {
        dependencies.push('"' + id + '": ' + 'require("' + id + '")');
    });
    var isDependencies = dependencies.length;
    dependencies = '{' + dependencies.join(',') + '}';


    var helpers = [];
    for (var name in prototype) {
        if (name !== '$render') {
            helpers.push('"' + name + '": ' + prototype[name].toString());
        }
    }
    helpers = '{' + helpers.join(',') + '}';


    code = 'define(function (require, exports, module) {\n'
         +      (isDependencies ? 'var dependencies = ' + dependencies + ';' : '')
         +      'var helpers = ' + helpers + ';\n'
         +      (isDependencies ? 'helpers.$render = function (id, data) {'
         +          'return dependencies[id](data);'
         +      '};' : '')
         +      'var Render = ' + render  + ';\n'
         +      'Render.prototype = helpers;'
         +      'return function (data) {\n'
         +          'return (new Render(data)).template;'
         +      '};\n'
         + '});';
    
    
    return code;
};


// ��ʽ��js
var beautify = function (code) {
    
    if (typeof js_beautify !== 'undefined') {
        var config = {
            indent_size: 4,
            indent_char: ' ',
            preserve_newlines: true,
            braces_on_own_line: false,
            keep_array_indentation: false,
            space_after_anon_function: true
        };
        code = js_beautify(code, config);
    }
    return code;
};


// ѹ��ģ��
var compress = function (code) {
    
    var openTag = template.openTag;
    var closeTag = template.closeTag;
    
    if (typeof template !== 'undefined') {
        openTag = template.openTag;
        closeTag = template.closeTag
    }
    
    code = code
    // ȥ�� html �� js ����ע��
    .replace(/\/\*(.|\n)*?\*\/|\/\/[^\n]*\n|\/\/[^\n]*$|<!--.*?-->/g, '')
    // ȥ�������Ʊ����TAB�����س���
    .replace(/\n/g, '')
    .replace(/[\r\t]/g, ' ')
    // "\" ת��
    .replace(/\\/g, "\\\\");

    function html (text) {
        return text.replace(/\s+/g, ' ');
    };
    
    function logic (text) {
        return openTag + text.trim() + closeTag;
    };

    // �﷨����
    var strings = '';
    code.split(openTag).forEach(function (text, i) {
        text = text.split(closeTag);
        
        var $0 = text[0];
        var $1 = text[1];
        
        // text: [html]
        if (text.length === 1) {
            
            strings += html($0);
         
        // text: [logic, html]
        } else {
                   
            strings += logic($0);    
            
            if ($1) {
                strings += html($1);
            }
        }
        

    });

    code = strings;

    // ANSI ת��
    /*var unicode = [], ansi;
    for (var i = 0 ; i < code.length; i ++) {
        ansi = code.charCodeAt(i);
        if (ansi > 255) {
            unicode.push('\\u' + ansi.toString(16));
        } else {
            unicode.push(code.charAt(i));
        } 
    }
    code = unicode.join('').trim();*/
    
    return code;
};

return function (source) {
    return beautify(toAMD(compress(source)));
}

})();

var args = OS.app.getArguments();
var list = args.length ? args : OS.file.get($path);

log('$charset = ' + $charset);
log('$path = ' + $path);
log('-----------------------');

list.forEach(function (path) {
	var rname = /\.(html|htm)$/i;
	if (!rname.test(path)) {
		return;
	}
	log('����: ' + path);
	var source = OS.file.read(path, $charset);
	var code = compileTemplate(source);
	var target = path.replace(rname, '.js');
	OS.file.write(target, code, $charset);
	log('���: ' + target);
});

OS.app.quit();

/*-----------------------------------------------*//*
:cmd
::if %errorlevel% == 0 exit
pause>nul
exit
*/





