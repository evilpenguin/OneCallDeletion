include theos/makefiles/common.mk
TWEAK_NAME = OneCallDeletion
OneCallDeletion_FILES = Tweak.xm
OneCallDeletion_FRAMEWORKS = UIKit CoreFoundation
OneCallDeletion_LDFLAGS = -lsqlite3
include $(THEOS_MAKE_PATH)/tweak.mk
