THEOS_DEVICE_IP=192.168.1.10
SDKVERSION=8.1

include theos/makefiles/common.mk

TWEAK_NAME = StatusBarIp
StatusBarIp_FILES = Tweak.xm
StatusBarIp_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
