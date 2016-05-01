#!/bin/bash
# author: gaoqi <gaoqi@changba.com>

case "$(uname -s)" in
	Darwin)
INFO(){ echo "$1"; }
WARNING(){ echo "$1"; }
ERROR(){ echo "$1"; }
;;
*)
INFO(){ echo "$1"; }
WARNING(){ echo "$1"; }
ERROR(){ echo "$1"; }
;;
esac

isCommandInPath(){
	which $1 &> /dev/null
	if [ $? -eq 0 ]; then
		echo "true"
	else
		echo "false"
	fi
}

if [[ `isCommandInPath adb` = "false" || `isCommandInPath aapt` = "false" ]]; then
	ERROR "please make sure you have added *tools*, *build-tools*, *platform-tools* dirs of android sdk in you PATH environment: $PATH"
	exit 1
fi




coldLaunch(){

	INFO "start cold launch 3 times" 

	for i in {1..3}
	do
		echo "-----第 $i 次冷启动测试-----"
		#first forcestop,launch others app，and launch test app
		#adb shell am force-stop com.tencent.karaoke
		adb shell am force-stop $PackageName
		adb shell am start -n com.android.browser/com.android.browser.BrowserActivity>/dev/null 2>&1
		#adb shell am start -W com.tencent.mm/com.tencent.mm.ui.LauncherUI>/dev/null 2>&1
		sleep 10s
		#TotalTime[i]=`adb shell am start -W com.tencent.karaoke/com.tencent.karaoke.module.splash.ui.SplashBaseActivity |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		TotalTime[i]=`adb shell am start -W $PackageName/$ActivityName |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		sleep 3s
		echo ${TotalTime[i]}
	done
	max=0
	for n in "${TotalTime[@]}"
	do
		((n>max)) && max=$n
	done
	echo "冷启动峰值:$max ms"

	avg=0
	sum=$((${TotalTime[1]} + ${TotalTime[2]} + ${TotalTime[3]}))
	avg=$[$sum/3]
	echo "冷启动均值:$avg ms"

}


warmLaunch(){
	INFO "start warm launch 3 times" 

	for i in {1..3}
	do
		echo "-----第 $i 次热启动测试-----"
		#first forcestop,launch others app，and launch test app
		#adb shell am force-stop com.tencent.karaoke
		adb shell am start -W $PackageName/$ActivityName>/dev/null 2>&1
		adb shell am start -n com.android.browser/com.android.browser.BrowserActivity>/dev/null 2>&1
		#adb shell am start -W com.tencent.mm/com.tencent.mm.ui.LauncherUI>/dev/null 2>&1
		sleep 10s
		#TotalTime[i]=`adb shell am start -W com.tencent.karaoke/com.tencent.karaoke.module.splash.ui.SplashBaseActivity |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		TotalTime[i]=`adb shell am start -W $PackageName/$ActivityName |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		sleep 3s
		echo ${TotalTime[i]}
	done
	max=0
	for n in "${TotalTime[@]}"
	do
		((n>max)) && max=$n
	done
	echo "热启动峰值:$max ms"

	avg=0
	sum=$((${TotalTime[1]} + ${TotalTime[2]} + ${TotalTime[3]}))
	avg=$[$sum/3]
	echo "热启动均值:$avg ms"
}


firstLaunch(){


	echo "start first launch 3 times"
	for i in {1..3}
	do
		echo "-----第 $i 次首次启动测试-----"
		uninsallApp
		installApp
		#first forcestop,launch others app，and launch test app
		#adb shell am force-stop com.tencent.karaoke
		#TotalTime[i]=`adb shell am start -W com.tencent.karaoke/com.tencent.karaoke.module.splash.ui.SplashBaseActivity |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		TotalTime[i]=`adb shell am start -W $PackageName/$ActivityName |grep TotalTime|awk -F ' ' '{print $2}'|tr -d "\r"`
		sleep 3s
		echo ${TotalTime[i]}
	done
	max=0
	for n in "${TotalTime[@]}"
	do
		((n>max)) && max=$n
	done
	echo "热启动峰值:$max ms"

	avg=0
	sum=$((${TotalTime[1]} + ${TotalTime[2]} + ${TotalTime[3]}))
	avg=$[$sum/3]
	echo "热启动均值:$avg ms"
}


installApp(){

	echo "----重新安装被测APP $PackageName ----"
	apps_dir=$(pwd)
	echo $apps_dir
	adb install $apps_dir/$PackageName.apk

}

uninsallApp(){
	echo "-----开始卸载被测App $PackageName-----"
	adb uninstall $PackageName
}



echo -n "请输入被测包名："
read PackageName
echo -n "请输入启动Activity："
read ActivityName

echo -e "-----请输入测试类型：----- \n 冷启动测试输入1 \n 热启动测试输入2 \n 首次安装启动时间输入3"
read testType

if [[ $testType -eq 1 ]]; then
	echo "-----冷启动测试-----"
	coldLaunch
elif [[ $testType -eq 2 ]]; then
	echo "-----热启动测试-----"
	warmLaunch
elif [[ $testType -eq 3 ]]; then
	echo "-----首次安装启动测试-----"
	firstLaunch
else
	ERROR "测试Tpye输入错误"
fi

echo "----测试结束----"
