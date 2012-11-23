# Jakefiles 编写辅助工具
a collection of some useful functions for using [Jake][1]

  [1]: https://github.com/isaacs/node-jake

```javascript
var jt = require('jake-tools');
```

## JakeTools.run(cmd, [cb = null], [instantPrint = true])
运行系统命令

* cmd: 命令行
* cb: 执行完成后callback `function(returnCode, stdout, stderr){}`
* instantPrint: true不捕获stdout/stderr, false捕获stdout/stderr

```javascript
jt.run('ls $PWD'); // simple async run
// run and get stdout/stderr
jt.run('ls $PWD', function(code, stdout, stderr){
  if (code === 0) {
    console.log('run success');
  } else {
    console.log('run fail);
  };
  console.log('stdout:')
  stdout.forEach(function(chunk){
    process.stdout.write(chunk)
  });
  console.log('stderr:')
  stderr.forEach(function(chunk){
    process.stderr.write(chunk)
  });
}, false);
```

## JakeTools.httpGet(url, file, cb)
发起http请求, 并将响应存储至指定文件

* url: 请求地址
* file: 存储文件路径
* cb: 保存完成后callback `function (err) {}`

```javascript
jt.httpGet('http://some.host/jquery.js', 'out/jquery.js', function(err) {
  if (err) {
    console.log(err);
  } else {
    console.log('success');
  }
})
```

## JakeTools.mocha(includes, [excludes], [report="spec"], [cb])
运行mocha, 进行单元测试 (支持coffeescript)

* includes: 测试文件, 或测试文件列表, 支持glob语法
* excludes: 排除文件, 或排除文件列表, 支持glob语法
* report: 测试报告类型
* cb: 测试完成后callback `function(returnCode, stdout, stderr){}`

```javascript
jt.mocha("test/test-*.js");
jt.mocha(["test/test-*.js", "test/**/test-*.coffee"]);
jt.mocha("test/test-*.js", "test/test-not-me.js");
jt.mocha(["test/test-*.js", "test/**/test-*.coffee"], ["test/test-not-me.js", "test/test-not-me.coffee"]);
jt.mocha("test/test-*.js", function(code, out, err) {
  // after test done
});
```

## JakeTools.coverage(dirs, includes, [excludes], [cb])
运行mocha, 进行单元测试, 并统计代码覆盖率 (支持coffeescript)

* dirs: 需统计覆盖率的文件所在目录
* includes: 测试文件, 或测试文件列表, 支持glob语法 (与JakeTools.mocha中定义相同)
* excludes: 排除文件, 或排除文件列表, 支持glob语法 (与JakeTools.mocha中定义相同)
* cb: 测试完成后callback `function(code, jsonReport){}` (与JakeTools.mocha中定义相同)

```javascript
jt.coverage('./lib', "test/test-*.js", [], function(jsonReport) {
  if (code) {
  	throw new Error('test fail');
  }
  console.log(jsonReport.stats);
});
```

## JakeTools.testResult(jsonReport)
stdout输出测试结果

* jsonReport 测试结果json数据


```javascript
jt.coverage('./lib', "test/test-*.js", [], function(jsonReport) {
  if (code) {
  	throw new Error('test fail');
  }
  jt.testResult(jsonReport);
});
```

## JakeTools.testReport(name, jsonReport, tpl, file)
生成完整html测试报告

* name: 报告名称
* jsonReport: 测试结果json数据
* tpl: 报告摸板路径 (jade模版)
* file: 输出文件路径


```javascript
jt.coverage('./lib', "test/test-*.js", [], function(jsonReport) {
  if (code) {
  	throw new Error('test fail');
  }
  jt.testReport('Some Module Name', jsonReport, './report/tpl/main.jade', );
});
```

## JakeTools.coffee(includes, excludes)
编译coffeescript

* includes: coffeescript文件, 或coffeescript文件列表, 支持glob语法
* excludes: 排除文件, 或排除文件列表, 支持glob语法

```javascript
jt.coffee("**/*.coffee");
jt.coffee("**/*.coffee", "./not-me.coffee");
```

## JakeTools.print(name, args...)
显示提示信息

* name: 标题
* args...: 提示信息

## JakeTools.error(name, args...)
显示错误信息

* name: 标题
* args...: 错误信息

## JakeTools.list(includes, excludes)
生成文件列表

* includes: 包含文件, 或包含文件列表, 支持glob语法
* excludes: 排除文件, 或排除文件列表, 支持glob语法

## JakeTools.mkdirp(dir, [mode="0755"])
递归建立目录

## JakeTools.listDelete(to, includes, excludes)
拷贝文件列表

* to: 目标目录
* includes: 包含文件, 或包含文件列表, 支持glob语法
* excludes: 排除文件, 或排除文件列表, 支持glob语法

## JakeTools.listCopy(includes, excludes)
删除文件列表

* includes: 包含文件, 或包含文件列表, 支持glob语法
* excludes: 排除文件, 或排除文件列表, 支持glob语法

## JakeTools.treeDelete(dir)
删除目录及其下所有文件

