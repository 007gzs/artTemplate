@if (0===0) @end/*
@echo off
call CScript.EXE "%~dpnx0" //Nologo //e:jscript %*
goto cmd
*//*!
 * Copyright (C) 2012 Tencent Inc.
 * Author  tangbin
 * Email   1987.tangbin@gmail.com
 */
 
var errorlevel = 0;

var $config = {
	openTag: '<%',
	closeTag: '%>',
	tag: /<script([^>]*?)>([\w\W]*?)<\/script>/ig,
	type: /type=("|')text\/html\1/i,
	id: /id=("|')([^"]+?)\1/i
};


 
if (!Array.prototype.forEach) {

    Array.prototype.forEach =  function(block, thisObject) {
        var len = this.length >>> 0;
        
        for (var i = 0; i < len; i++) {
            if (i in this) {
                block.call(thisObject, this[i], i, this);
            }
        }
        
    };
    
}

if (!String.prototype.trim) {

    String.prototype.trim = (function () {
        var trimLeft = /^\s+/, trimRight = /\s+$/;
        
        return function () {
			return this == null ?
				'' :
				this.toString().replace(trimLeft, '').replace(trimRight, '');
        };
    })();
    
}

/** ģ��ϲ� */
var merger = function (code) {
    
    var rtag = $config.tag;
    var rtype = $config.type;
    var rid = $config.id;
    
    var string = [];
    
    // ��ȡģ��Ƭ��
    while ((val = rtag.exec(code)) !== null) {
        if (rtype.test(val[1])) {
            string.push(merger.compress(val[1].match(rid)[2], val[2]));
        }
    }
    
    string = string.join('\r\n');
    
    if (!string) {
        string = merger.compress('id', code);
    }
    
    return string;
};

merger.compress = function (id, code) {
    
    var openTag = $config.openTag;
    var closeTag = $config.closeTag;
    
    if (typeof template !== 'undefined') {
        openTag = template.openTag;
        closeTag = template.closeTag
    }
    
    code = code
    // ȥ�� html �� js ����ע��
    .replace(/\/\*[^\*\/]*\*\/|<!--.*?-->/g, '')
    // ȥ�������Ʊ����TAB�����س���
    .replace(/\n/g, '')
    .replace(/[\r\t]/g, ' ')
    // "\" ת��
    .replace(/\\/g, "\\\\")
    // "'" ת��
    .replace(/'/g, "\\'");
    
    
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
    
    function html (text) {
        return text.replace(/\s+/g, ' ');
    };
    
    function logic (text) {
        return openTag + text.trim() + closeTag;
    };

    code = strings;
    
    
    // ANSI ת��
    var unicode = [], ansi;
    for (var i = 0 ; i < code.length; i ++) {
        ansi = code.charCodeAt(i);
        if (ansi > 255) {
            unicode.push('\\u' + ansi.toString(16));
        } else {
            unicode.push(code.charAt(i));
        } 
    }
    code = unicode.join('').trim();
    
    

	code = "template('" + id + "', '" + code + "');";
    
	return code;
};




/**
 * �ļ�����
 * @see http://code.google.com/p/naturaljs/source/browse/common/component.js
 */
var file = {

    /** 
     * ���ļ�����ȡ�����ݣ������ı��ĸ�ʽ��
     * @param	{String}	path		�ļ�·��
     * @param	{String}	sCharset	ָ���ַ���
     * @return	{Object} 	            �ļ�����
     */

    read: function (filename, sCharset) {
        var stream = new ActiveXObject('adodb.stream');
        var fileContent;

        with(stream) {
            type = 2; // 1�������ƣ�2���ı�
            mode = 3; // 1������2��д��3����д
            open();

            if (!sCharset) {
                try {
                    charset = "437"; // why try, cause some bug now
                } catch (e) {}
                loadFromFile(filename);

                // get the BOM(byte order mark) or escape(ReadText(2)) is fine?
                switch (escape(readText(2).replace(/\s/g, ''))) {
                case "%3Ca":
                case "%3Cd":
                case "%3C%3F":
                case "%u2229%u2557":
                    // 0xEF,0xBB => UTF-8
                    sCharset = "UTF-8";
                    break;
                case "%A0%u25A0":
                    // 0xFF,0xFE => Unicode
                case "%u25A0%A0":
                    // 0xFE,0xFF => Unicode big endian
                    sCharset = "Unicode";
                    break;
                default:
                    // �жϲ�������ʹ��GBK�����������ڴ�����������ȷ��������
                    sCharset = "GBK";
                }
                close();
                open();
            }
            charset = sCharset;
            loadFromFile(filename);
            fileContent = new String(readText());
            fileContent.charset = sCharset;
            close();
        }
        return fileContent;
    }

    /**
     * �����ݱ��浽�����ϡ���֧���ı����ݺͶ��������ݡ�
     * @param 	{String} 	path 		�ļ�·����
     * @param 	{String} 	data 		Ҫд������ݣ������Ƕ����ƶ���
     * @param 	{Boolean} 	isBinary	�Ƿ�Ϊ���������ݡ�
     * @param 	{Boolean} 	isMapPath	�Ƿ��������·����True �Ļ�������·����ԭΪ��ʵ�Ĵ���·����
     * @return 	{Boolean} 	True		��ʾ�����ɹ���
     */
     ,write: function (path, data, isBinary, chartset) {
        with(new ActiveXObject("Adodb.Stream")) {
            type = isBinary ? 1 : 2;
            if (!chartset && !isBinary) {
                charset = "utf-8";
            }
            if (chartset) {
                charset = "GB2312";
            }
            try {
                open();
                if (!isBinary) {
                    writeText(data);
                } else {
                    write(data);
                }
                saveToFile(path, 2);

                return true;
            } catch (e) {
                throw e;
            } finally {
                close();
            }
        }

        return true;
    }

};



var Arguments = WScript.Arguments;
var path = Arguments.length && Arguments(0);

var list = [];
for (var i = 0, len = Arguments.length; i < len; i ++) {
    list.push(Arguments(i));
}

list.forEach(function (path, i) {
    var data = file.read(path);
    
	path = path.replace(/\\/g, '/').split('/');
    
    var name = path.pop().replace(/\.\w+$/, '');
	var newPath = (path.join('/').lastIndexOf('/') < 0 ? '.' : path.join('/'))
    + '/template-' + name + '.js';
    
    data = merger(data);
    
    var ret = file.write(newPath, data, false);
    
    if (!ret) {
        errorlevel = 1;
        WScript.Echo('����: \r\n�ļ�д��ʧ�ܣ�' + newPath);
    }
});

if (!list.length) {
    errorlevel = 1;
    WScript.Echo('[ʹ�ð���]'
    + '\r\n\r\n��HTML�ļ��Ϸŵ��������ļ�ͼ���Ϻ��ɿ���������'
    + '\r\n\r\n��������ҳ���к��� type="text/html" �ű���ǩ���磺'
    + '\r\n\r\n    <script id="demo" type="text/html">'
    + '\r\n        [template code..]'
    + '\r\n    </script>'
    + '\r\n\r\n����ϲ�Ϊ�ⲿ js �ļ���');
}


WScript.Quit(errorlevel);

/*-----------------------------------------------*//*
:cmd
if %errorlevel% == 0 exit
pause>nul
*/