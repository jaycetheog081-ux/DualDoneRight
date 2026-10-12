TARGET := iphone:clang:latest:12.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = DualDoneRight

DualDoneRight_FILES = \
	src/main.mm \
	src/DualDoneRightApp.mm \
	src/DeviceCompatibility.mm \
	src/FirmwareManager.mm \
	src/BootManager.mm \
	src/RecoveryManager.mm

DualDoneRight_FRAMEWORKS = UIKit Foundation
DualDoneRight_CFLAGS = -fobjc-arc
DualDoneRight_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
