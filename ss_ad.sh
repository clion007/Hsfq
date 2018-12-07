#!/bin/sh
# Compile:by-lanse    2018-08-28
LOGTIME=$(date "+%m-%d %H:%M:%S")
route_vlan=`/sbin/ifconfig br0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " " `

if [ ! -d "/etc/storage/bin/hosts" ]; then
	echo -e "\e[1;36m 创建广告规则文件夹 \e[0m"
	echo -e "\n"
	mkdir -p -m 755 /etc/storage/bin/hosts
	echo "127.0.0.1 localhost" > /etc/storage/bin/hosts/hosts.conf && chmod 644 /etc/storage/bin/hosts/hosts.conf
fi
cp -f /tmp/hsfq_ssad.sh /etc/storage/bin/hsfq_ssad.sh

if [ -f "/etc/storage/cron/crontabs/$username" ]; then
	echo -e "\e[1;31m 添加定时计划更新任务 \e[0m"
	echo -e "\n"
	sed -i '/hsfq_ssad/d' /etc/storage/cron/crontabs/$username
	sed -i '$a 45 05 * * 2,4,6 /bin/sh /etc/storage/bin/hsfq_ssad.sh' /etc/storage/cron/crontabs/$username
	killall crond;/usr/sbin/crond
fi

echo -e "\e[1;36m HOSTS 去广告规则开始下载... \e[0m"
echo -e "\n"

# 下载 HOSTS 组合规则
echo -e "\033[41;37m 组合下载时间较长.请耐心等待……\033[0m"
echo -e "\n"
wget --no-check-certificate -t 30 -T 80 https://raw.githubusercontent.com/896660689/Hsfq/master/hsad -qO \
/tmp/ad.conf && sleep 2 && chmod +x /tmp/ad.conf && . /tmp/ad.conf

# 下载 '网络收集' HOSTS 规则
wget --no-check-certificate -t 30 -T 80 https://raw.githubusercontent.com/896660689/Hsfq/master/hsabd -qO \
/tmp/abd.conf && sleep 2 && chmod +x /tmp/abd.conf && . /tmp/abd.conf
sleep 2

# 合并 hosts 缓存
cat /tmp/ad /tmp/abd > /tmp/hosts_ad

# 删除 hosts 缓存
rm -rf /tmp/ad
rm -rf /tmp/ad.conf
rm -rf /tmp/abd
rm -rf /tmp/abd.conf

# 删除注释
sed -i '/::1/d' /tmp/hosts_ad

# 创建 hosts 规则文件
echo "##########################################################
## 自定义 hosts 设置 	【2017 by.lanse】		##
##########################################################
127.0.0.1 localhost
::1	localhost
::1	ip6-localhost
::1	ip6-loopback
# Example: hosts 设置例子:
# 192.168.2.80		Boo" > /tmp/hosts_ad.conf

# 去重排序规则
sort -n /tmp/hosts_ad | uniq | sed -E -e "/^$/d" -e "s/[[:space:]][[:space:]]*/ /g" >> /tmp/hosts_ad.conf
sleep 2
# 修饰结束
sed -i '$a # 修饰 hosts 结束' /tmp/hosts_ad.conf

# 删除 hosts 合并缓存
rm -rf /tmp/hosts_ad

echo " 更新 hosts_ad 规则."
echo -e "\n"
if [ -f /tmp/hosts_ad.conf ]; then
	[ -f "/tmp/hosts_ad.txt" ] && rm -f /tmp/hosts_ad.txt
	echo | awk '{print$0}' /tmp/hosts_ad.conf /etc/storage/bin/hosts/hosts.conf | sort | uniq -u > /tmp/hosts_ad.txt
	if [ $? -eq 0 ];then
		if [ ! -s "/tmp/hosts_ad.txt" ]; then
			logger -t "【$LOGTIME】" "Hosts 规则已为最新,无需更新..."
			echo -e "\e[1;33m Hosts 已为最新规则无需更新.\e[0m"
			echo -e "\n" && rm -f /tmp/hosts_ad.conf
		else
			echo
			mv -f /tmp/hosts_ad.conf /etc/storage/bin/hosts/hosts.conf
			if [ $? -eq 0 ]; then
				logger -t "【$LOGTIME】" "最新 Hosts 规则更新完成..."
				echo -e "\e[1;33m Hosts 最新 Hosts 规则更新完成.\e[0m"
				echo -e "\n" && rm -f /tmp/hosts_ad.conf
			else
				logger -t "【$LOGTIME】" "Hosts 更新失败，重新启动更新任务..."
				echo -e "\e[1;37m Hosts 更新失败，重新启动更新任务\e[0m"
				echo -e "\n" && /bin/sh /etc/storage/bin/hsfq_ssad.sh
			fi
		fi
	else
		logger -t "【$LOGTIME】" "Hosts 更新失败，重新启动更新任务..."
		echo
		echo -e "\e[1;37m Hosts 更新失败，重新启动更新任务\e[0m"
		echo -e "\n" && /bin/sh /etc/storage/bin/ss_ad.sh
	fi
fi


if [ -f "/etc/storage/dnsmasq/dnsmasq.conf" ]; then
	echo -e "\e[1;31m 添加自定义 hosts 启动路径 \e[0m"
	echo -e "\n"
	sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
	sed -i '$a addn-hosts=/etc/storage/bin/hosts' /etc/storage/dnsmasq/dnsmasq.conf
	sleep 2 && killall crond;/usr/sbin/crond
fi

# 删除临时文件
rm -f /tmp/hosts_ad.txt
rm -f /tmp/hsfq_ssad.sh
