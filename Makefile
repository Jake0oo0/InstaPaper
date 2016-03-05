DEBUG = 0
ARCHS = armv7 armv7s arm64
TARGET = iphone:clang:latest:8.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
THEOS_PACKAGE_DIR_NAME = debs
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PaperGram
PaperGram_FILES = Tweak.xm PaperGramHelper.m $(wildcard lib/*.m)
PaperGram_LDFLAGS = -lxml2
PaperGram_CFLAGS=-I$(SYSROOT)/usr/include/libxml2
PaperGram_LDFLAGS += -Wl,-segalign,4000
PaperGram_FRAMEWORKS = UIKit Foundation CoreGraphics ImageIO Accelerate QuartzCore SystemConfiguration

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS)/makefiles/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += papergramprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
