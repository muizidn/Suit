YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga/darwin*' | head -n 1)
echo "Using Yoga in: $YOGA_LIB_PATH"

echo "Generating xcconfig file..."
echo 'MACOSX_DEPLOYMENT_TARGET = 10.13' > macOS.xcconfig
echo 'ENABLE_TESTABILITY = YES' >> macOS.xcconfig
#printf prints without a linefeed
printf 'OTHER_LDFLAGS = $(OTHER_LDFLAGS) -lc++ ' >> macOS.xcconfig
echo "-L$YOGA_LIB_PATH" >> macOS.xcconfig

swift package generate-xcodeproj --xcconfig-overrides macOS.xcconfig