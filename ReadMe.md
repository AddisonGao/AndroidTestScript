#Read me
gaoqi


##launchTest


- 把被测安装包放到脚本同一路径下，命名为被测安装包的包名
- 首先需要输入的两个参数是：被测包名和被测包名的启动类
 - aapt 获取启动类：aapt dump badging +file_path.apk 
- 三种测试场景
 - 冷启动
 - 热启动
 - 首次安装启动
 
 
##应用启动的流程

Application的构造器方法——>attachBaseContext()——>onCreate()——>Activity的构造方法——>onCreate()——>配置主题中背景等属性——>onStart()——>onResume()——>测量布局绘制显示在界面上。

##什么是应用启动的时间

- 在上面这个启动流程中，任何一个地方有耗时操作都会拖慢我们应用的启动速度，而应用启动时间是用毫秒度量的，对于毫秒级别的快慢度量我们还是需要去精确的测量到到底应用启动花了多少时间，而根据这个时间来做衡量。
什么才是应用的启动时间

- 从点击应用的启动图标开始创建出一个新的进程直到我们看到了界面的第一帧，这段时间就是应用的启动时间。
我们要测量的也就是这段时间，测量这段时间可以通过adb shell命令的方式进行测量，这种方法测量的最为精确，命令在下面的原理里面。

##原理
adb shell am start -W [packageName]/[packageName.MainActivity]

- 执行成功后将返回三个测量到的时间：
 - ThisTime:一般和TotalTime时间一样，除非在应用启动时开了一个透明的Activity预先处理一些事再显示出主Activity，这样将比TotalTime小。 
 - TotalTime:应用的启动时间，包括创建进程+Application初始化+Activity初始化到界面显示。 
 - WaitTime:一般比TotalTime大点，包括系统影响的耗时。 

 
- 脚本取得是TotalTime






##减少应用启动时的耗时
针对冷启动时候的一些耗时，如上测得这个应用算是中型的app，在冷启动的时候耗时已经快700ms了，如果项目再大点在Application中配置了更多的初始化操作，这样将可能达到1s，这样每次启动都明显感觉延迟，所以在进行应用初始化的时候采取以下策略： 

- 在Application的构造器方法、attachBaseContext()、onCreate()方法中不要进行耗时操作的初始化，一些数据预取放在异步线程中，可以采取Callable实现。
- 对于sp的初始化，因为sp的特性在初始化时候会对数据全部读出来存在内存中，所以这个初始化放在主线程中不合适，反而会延迟应用的启动速度，对于这个还是需要放在异步线程中处理。
- 对于MainActivity，由于在获取到第一帧前，需要对contentView进行测量布局绘制操作，尽量减少布局的层次，考虑StubView的延迟加载策略，当然在onCreate、onStart、onResume方法中避免做耗时操作。

遵循上面三种策略可明显提高app启动速度。