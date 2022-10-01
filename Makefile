BUNDLE := com.hoahuynh.navi

.PHONY: all clean

all: clean
	xcodebuild clean build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO PRODUCT_BUNDLE_IDENTIFIER="$(BUNDLE)" -sdk iphoneos -scheme NaVi -configuration Release -derivedDataPath build
	ln -sf build/Build/Products/Release-iphoneos Payload
	rm -rf Payload/Navi.app/Frameworks
	zip -r9 NaVi.ipa Payload/Navi.app

clean:
	rm -rf build Payload NaVi.ipa
	
