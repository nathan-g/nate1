#!/bin/sh
#
# Usage: install-bindist.sh [ServerRoot]
# This script installs the Apache binary distribution and
# was automatically created by binbuild.sh.
 
lmkdir()
{
  path=""
  dirs=`echo $1 | sed -e 's%/% %g'`
  mode=$2
 
  set -- ${dirs}
 
  for d in ${dirs}
  do
    path="${path}/$d"
    if test ! -d "${path}" ; then
      mkdir ${path}
      if test $? -ne 0 ; then
        echo "Failed to create directory: ${path}"
        exit 1
      fi
      chmod ${mode} ${path}
    fi
  done
}
 
lcopy()
{
  from=$1
  to=$2
  dmode=$3
  fmode=$4
 
  test -d ${to} || lmkdir ${to} ${dmode}
  (cd ${from} && tar -cf - *) | (cd ${to} && tar -xf -)
 
  if test "X${fmode}" != X ; then
    find ${to} -type f -print | xargs chmod ${fmode}
  fi
  if test "X${dmode}" != X ; then
    find ${to} -type d -print | xargs chmod ${dmode}
  fi
}
 
##
##  determine path to (optional) Perl interpreter
##
PERL=no-perl5-on-this-system
perls='perl5 perl'
path=`echo $PATH | sed -e 's/:/ /g'`
 
for dir in ${path} ;  do
  for pperl in ${perls} ; do
    if test -f "${dir}/${pperl}" ; then
      if `${dir}/${pperl} -v | grep 'version 5\.' >/dev/null 2>&1` ; then
        PERL="${dir}/${pperl}"
        break
      fi
    fi
  done
done
 
if [ .$1 = . ]
then
  SR=/usr/local/apache
else
  SR=$1
fi
echo "Installing binary distribution"
echo "into directory $SR ..."
lmkdir $SR 755
#lmkdir $SR/proxy 750
lmkdir $SR/logs 777
lcopy bindist/libexec $SR/libexec 755 644
lcopy bindist/include $SR/include 755 644
lcopy bindist/cgi-bin $SR/cgi-bin 750 750
lcopy bindist/bin $SR/bin 750 750
if [ -d $SR/conf ]
then
  echo "[Preserving existing configuration files.]"
  cp bindist/conf/*.default $SR/conf/
else
  lcopy bindist/conf $SR/conf 755 644
fi
cp ../ETS_4.8_Installation_Guide.pdf $SR
 
sed -e "s;^#!/.*;#!$PERL;" -e "s;\@prefix\@;$SR;" -e "s;\@sbindir\@;$SR/bin;" \
	-e "s;\@libexecdir\@;$SR/libexec;" -e "s;\@includedir\@;$SR/include;" \
	-e "s;\@sysconfdir\@;$SR/conf;" bindist/bin/apxs > $SR/bin/apxs
sed -e "s;^#!/.*;#!$PERL;" bindist/bin/dbmmanage > $SR/bin/dbmmanage
sed -e "s%/usr/local/apache%$SR%" $SR/conf/httpd.conf.default > $SR/conf/httpd.conf
sed -e "s%/usr/local/ETS%$SR%" $SR/conf/asis.conf.default > $SR/conf/asis.conf
sed -e "s%LD_LIBRARY_PATH=%LD_LIBRARY_PATH=$SR/%" -e "s%PIDFILE=%PIDFILE=$SR/%" -e "s%HTTPD=%HTTPD=\"$SR/%" -e "s%httpd$%httpd -d $SR -R $SR/libexec\"%" bindist/bin/apachectl > $SR/bin/apachectl
 
echo


