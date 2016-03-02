ARCHS = armv7 arm64
TARGET = iphone:clang:latest:8.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
THEOS_PACKAGE_DIR_NAME = debs
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = InstaPaper
InstaPaper_FILES = Tweak.xm $(wildcard lib/*.m)
InstaPaper_LDFLAGS = -lxml2
InstaPaper_CFLAGS=-I$(SYSROOT)/usr/include/libxml2
InstaPaper_LDFLAGS += -Wl,-segalign,4000
InstaPaper_FRAMEWORKS = UIKit Foundation CoreGraphics ImageIO Accelerate QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
include theos/makefiles/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += instapaperprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
