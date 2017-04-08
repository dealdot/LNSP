#! /bin/sh
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script"
    exit 1
fi

cur_dir=$(pwd)
declare -i filenum=0
for dirname in $(ls ${cur_dir}) 
do
        if [ -d "$dirname" ]; then
        subfilelist=`ls $dirname`
        filenum=$((`ls -l $dirname|grep "^d"|wc -l`+$filenum))
        for subfilename in $subfilelist
        do
	if [ ! -e /opt/program/nginx/conf/vhost/${subfilename}".conf" ];then
        cat >/opt/program/nginx/conf/vhost/${subfilename}".conf" << EOF
server {
        listen 80;
        server_name $subfilename;
        index index.html index.htm index.php default.html default.htm default.php;
        root  /opt/htdocs/$dirname/$subfilename;
        location ~ \.php$ {
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
        }

        location / {
        try_files \$uri \$uri/ /list.php;
    }
}
EOF
	fi
        done
        fi
done
#total file nums
echo "total websites:"$filenum
# reload the nginx
echo "reload nginx..."
sleep .3
/opt/program/nginx/nginx -s reload
echo "nginx reload done!"
unset cur_dir
unset filenum
