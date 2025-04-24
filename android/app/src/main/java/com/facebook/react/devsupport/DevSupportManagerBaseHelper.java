/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package com.facebook.react.devsupport;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.os.Build;

/**
 * Helper class for DevSupportManagerBase to handle broadcast receiver registration
 * in a way that is compatible with all Android versions.
 */
public class DevSupportManagerBaseHelper {
  
  /**
   * Registers a broadcast receiver with the given filter, handling API level differences
   * for broadcast receiver registration.
   */
  public static void registerReceiver(
      Context context, BroadcastReceiver receiver, IntentFilter intentFilter) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      // Use RECEIVER_EXPORTED flag for Android 13+
      context.registerReceiver(receiver, intentFilter, Context.RECEIVER_EXPORTED);
    } else {
      // Use the regular registration method for older versions
      context.registerReceiver(receiver, intentFilter);
    }
  }
} 