#!/bin/bash

# Fix AutoLayoutView.kt
FILE="node_modules/@shopify/flash-list/android/src/main/kotlin/com/shopify/reactnative/flash_list/AutoLayoutView.kt"
if [ -f "$FILE" ]; then
  sed -i '' 's/override fun dispatchDraw(canvas: Canvas?) {/override fun dispatchDraw(canvas: Canvas) {/g' "$FILE"
  echo "Fixed $FILE"
fi

# Fix ScreenStack.kt
FILE="node_modules/react-native-screens/android/src/main/java/com/swmansion/rnscreens/ScreenStack.kt"
if [ -f "$FILE" ]; then
  sed -i '' 's/override fun dispatchDraw(canvas: Canvas) {/override fun dispatchDraw(canvas: Canvas?) {/g' "$FILE"
  sed -i '' 's/override fun drawChild(canvas: Canvas, child: View, drawingTime: Long): Boolean {/override fun drawChild(canvas: Canvas?, child: View, drawingTime: Long): Boolean {/g' "$FILE"
  echo "Fixed $FILE"
fi 