### 免编译服务器集成环境LNSP,批量上站好帮手

1. LNSP是什么

LNSP (Linux Nginx SQLITE3 PHP),好羞愧 ^\_\^, LNSP原指:LABORATORY FOR NUCLEAR SECURITY AND POLICY(核安全与政策研究实验室,来自MIT)

LNSP是在linux上适用的nginx+php(支持sqlite3)的服务器架构环境,nginx版本:1.10.2,php版本:5.6.29

2. 我为什么要做这个集成环境?

`apachefriends.org`上提供一个服务器集成环境xampp,这个环境之所以好是因为它把我们常用的apache,mysql,php,phpmyadmin,proftpd这些软件集成在一起。安装过程非常简单,不需要编译,环境依赖都给我们搞好了,因此使用非常方便.

虽然原来xampp好用,但在我的实际使用中发现它有几方面的不足:
- xampp太臃肿,除了apache, php外它还有mysql,phpmyadmin,proftpd这些软件集成,而我平时比较喜欢使用轻量级,嵌入式sqlite数据库。
- apache+php性能问题,xampp编译的时候把php编译成apache模块,`--with-apxs2=/usr/local/apache/bin/apxs：基于apxs实现让php编译成apache模块`,让apache也能处理php请求.而nginx处理php请求是通过php-fpm这个fastcgi模块来处理的,处理完再返回给nginx,因此性能更高.(关于Nginx与apache的性能问题大家可以google了解)
- xampp安装包太大,接近1G,因此空间问题也不能小觑。

3. LNSP 有什么优点
- LNSP也是一键安装包,解压即可使用,当然需要一些简单的配置
- LNSP添加虚拟主机写成了shell script,命名为 `make.sh`,网站放到/opt/htdocs下,部署网站方便快捷
- LNSP占空间少,大概400M,打包压缩后只有126M,后期版本估计还可以减少一半左右
- LNSP仅有nginx与php,并且nginx与php我们不需要的模块(一些核心模块除外)都没有编译,相对于xampp来说非常mini.
- nginx+php,大家也许会想到国内一个高手做的lnmp,我原来也一直用,lnmp也是优化过一些参数,安装过程比较人性化,不过安装过程中需要编译,耗时长,并且它像xampp一样,安装了很多我们不需要的东西,因此不适合
- 正因为安装的仅有nginx与php,因些服务器安全性能高

4. LNSP有什么缺点
- LNSP目前只支持64位操作系统,目前已经测试通过的linux distributions有centos 6.x x86_64,centos 7.x x86_64,ubuntu 12.04.x x86_64, ubuntu 14.04.x x86_64,ubuntu 16.04.x x86_64,ubuntu 16.10.x x86_64 精力有限,以后可能会支持更多的distributions
- 功能有限,没有mysql,只支持sqlite,并且php的一些功能如GD库在这里是不支持的,注意这里nginx支持https加密传输

5. 如何部署LNSP

进入到linux下的opt目录,`wget http://139.162.117.46/lnsp-x64-1.0.tar.gz`,直接解压,然后`cd sources`执行`sh configure.sh`即可。

> 注意:在执行configure.sh之前要确定你的系统是Centos还是Ubuntu, Ubuntu使用dash作为默认的shell,需要修改成bash,执行dpkg-reconfigure dash,然后选择 no 确定即可把shell修改成bash


**这里configure.sh帮我们做了几件事**
1. 帮我们添加nginx,php-fpm运行时用户,这里指定为www,并修改www用户密码,上站就用www用户操作
2. 帮我们启动nginx,php-fpm
3. 帮我们添加开机自动启动脚本

> 注意:centos 7.x x86_64系统的开机启动变化很大,这里在configure.sh运行之后再执行 `chmod +x /etc/rc.d/rc.local`  即可设置开机启动


6. 如何部署网站

 在/opt/htdocs下的文件夹下建立自己的目录如 dealdot,再进入dealdot目录建立网站,如`mkdir apple.com`,然后在` /opt/htdocs`下运行 `sh make.sh`即可绑定虚拟主机
 
7. 如何过滤违禁词,敏感词

采用淘宝团队成员开发的模块`ngx_http_substitutions_filter_module `来实现过滤违禁词,敏感词
这里命名为subkeywords.conf,放置在 /opt/program/nginx/conf/下,比如我们网站上用了其它公司的名字,造成侵权之类的,只需要把该公司的名字放到subkeywords.conf里就可以在显示的时候过滤掉

8. 启动,停止,重启nginx,php-fpm

> 启动nginx `/opt/program/nginx/nginx`

> 停止nginx `/opt/program/nginx/nginx -s stop`

> 重新加载 `/opt/program/nginx/nginx -s reload`

> 启动php-fpm `/opt/program/php/sbin/php-fpm`

> 停止php-fpm `kill -INT PID`

> 平滑重启 `kill -USR2 PID`

注意: PID为php-fpm运行的master 进程 id,`shell下执行: ps aux|grep 'php-fpm: master'|grep -v 'grep' 查看`

9. 配置文件,日志文件

php配置文件php.ini 在`/opt/program/php/lib`下

php-fpm配置文件php-fpm.conf 在`/opt/program/php/etc`下

nginx日志文件在 `/opt/program/nginx/logs`下

php-fpm 日志文件在 `/opt/program/php/var/log`下,默认关闭了php的error log

附上网站不带www的跳到带www, 如 `mkdir apple.com`
```
server {
        listen 80;
        server_name www.apple.com apple.com;
        if ($host != 'www.apple.com') {
	 rewrite ^/(.*)$ http://www.apple.com/$1 permanent;
	}
        index index.html index.htm index.php default.html default.htm default.php;
        root  /opt/htdocs/example/apple.com;
        location ~ \.php$ {
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
}
```
