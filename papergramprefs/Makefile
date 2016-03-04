ARCHS = armv7 armv7s arm64
TARGET = iPhone:clang:latest:latest
CFLAGS = -fobjc-arc
LDFLAGS = -F$(THEOS)/frameworks

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PaperGramPrefs
PaperGramPrefs_FILES = PaperGramPrefs.mm $(shell find $(THEOS)/include/SettingsKit -name '*.m')
PaperGramPrefs_INSTALL_PATH = /Library/PreferenceBundles
PaperGramPrefs_FRAMEWORKS = UIKit MessageUI Social QuartzCore CoreGraphics
PaperGramPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)cp $(THEOS)/include/SettingsKit/Resources/*.png $(THEOS_STAGING_DIR)/Library/PreferenceBundles/PaperGramPrefs.bundle/$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PaperGramPrefs.plist$(ECHO_END)
