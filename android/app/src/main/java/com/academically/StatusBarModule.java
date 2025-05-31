package com.academically;

import android.app.Activity;
import android.os.Build;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.core.view.WindowInsetsCompat;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.UiThreadUtil;

public class StatusBarModule extends ReactContextBaseJavaModule {
    private final ReactApplicationContext reactContext;

    public StatusBarModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "StatusBarModule";
    }

    @ReactMethod
    public void setBarStyle(final String style) {
        UiThreadUtil.runOnUiThread(() -> {
            Activity activity = getCurrentActivity();
            if (activity != null) {
                WindowInsetsControllerCompat windowInsetsController = 
                    WindowCompat.getInsetsController(activity.getWindow(), activity.getWindow().getDecorView());
                
                boolean isDark = "dark-content".equals(style);
                windowInsetsController.setAppearanceLightStatusBars(isDark);
            }
        });
    }

    @ReactMethod
    public void setTranslucent(final boolean translucent) {
        UiThreadUtil.runOnUiThread(() -> {
            Activity activity = getCurrentActivity();
            if (activity != null) {
                WindowCompat.setDecorFitsSystemWindows(activity.getWindow(), !translucent);
            }
        });
    }

    @ReactMethod
    public void setHidden(final boolean hidden) {
        UiThreadUtil.runOnUiThread(() -> {
            Activity activity = getCurrentActivity();
            if (activity != null) {
                WindowInsetsControllerCompat windowInsetsController = 
                    WindowCompat.getInsetsController(activity.getWindow(), activity.getWindow().getDecorView());
                
                if (hidden) {
                    windowInsetsController.hide(WindowInsetsCompat.Type.statusBars());
                } else {
                    windowInsetsController.show(WindowInsetsCompat.Type.statusBars());
                }
            }
        });
    }
} 