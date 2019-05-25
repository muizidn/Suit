if [[ "$OSTYPE" == "linux-gnu" ]]; then
  export YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga/linux*' | head -n 1)
  echo "Using Yoga in: $YOGA_LIB_PATH"
  swift test -Xlinker -lxcb-util -Xlinker -lxcb -Xlinker -lstdc++ -Xswiftc -L$YOGA_LIB_PATH -Xswiftc -L../CClipboard/Sources/CClipboard
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH
  YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga/darwin*' | head -n 1)
  echo "Using Yoga in: $YOGA_LIB_PATH"
  swift test --generate-linuxmain -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
  swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
  #$YOGA_LIB_PATH
else
  echo "Error: unsupported platform."
fi
