package com.academically;

import android.net.Uri;
import androidx.annotation.Nullable;
import android.os.Bundle;
import android.os.Build;
import com.facebook.react.ReactActivity;
import com.facebook.react.ReactActivityDelegate;
import com.facebook.react.ReactRootView;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.Manifest;
import android.content.pm.PackageManager;
import com.zoontek.rnbootsplash.RNBootSplash;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.core.view.WindowInsetsCompat;

public class MainActivity extends ReactActivity {

  private static final int PERMISSION_REQUEST_CODE = 1;

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "Academically";
  }

  private void checkAndRequestPermissions() {
    // List of permissions to be requested
    String[] permissions = {
        Manifest.permission.ACCESS_NOTIFICATION_POLICY,
        Manifest.permission.WAKE_LOCK,
        // Add more permissions here as needed
    };

    // Check if the permissions are granted
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        boolean allPermissionsGranted = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                allPermissionsGranted = false;
                break;
            }
        }

        // Request permissions if not granted
        if (!allPermissionsGranted) {
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE);
        }
    }
}

// Override onRequestPermissionsResult to handle the permission request response
@Override
public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    if (requestCode == PERMISSION_REQUEST_CODE) {
        // Check if all permissions are granted
        boolean allPermissionsGranted = true;
        for (int grantResult : grantResults) {
            if (grantResult != PackageManager.PERMISSION_GRANTED) {
                allPermissionsGranted = false;
                break;
            }
        }

        // Handle permission grant or denial here
        if (allPermissionsGranted) {
            // Permissions granted
        } else {
            // Permissions denied
        }
    }
}

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // Enable edge-to-edge display
    WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
    
    // Configure the window insets
    WindowInsetsControllerCompat windowInsetsController = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
    windowInsetsController.setAppearanceLightStatusBars(true);
    windowInsetsController.setAppearanceLightNavigationBars(true);
    
    checkAndRequestPermissions();
    RNBootSplash.init(this);
    super.onCreate(savedInstanceState);
    Uri deepLinkUri = getIntent().getData();
    if (deepLinkUri != null) {
        // Handle the deep link data here
        String path = deepLinkUri.getPath();
        // ...
    }
  }

  /**
   * Returns the instance of the {@link ReactActivityDelegate}. There the RootView is created and
   * you can specify the renderer you wish to use - the new renderer (Fabric) or the old renderer
   * (Paper).
   */
  @Override
  protected ReactActivityDelegate createReactActivityDelegate() {
    return new MainActivityDelegate(this, getMainComponentName());
  }

  public static class MainActivityDelegate extends ReactActivityDelegate {
    public MainActivityDelegate(ReactActivity activity, String mainComponentName) {
      super(activity, mainComponentName);
    } 

    @Override
    protected ReactRootView createRootView() {
      ReactRootView reactRootView = new ReactRootView(getContext());
      // If you opted-in for the New Architecture, we enable the Fabric Renderer.
      reactRootView.setIsFabric(BuildConfig.IS_NEW_ARCHITECTURE_ENABLED);
      return reactRootView;
    }

    @Override
    protected boolean isConcurrentRootEnabled() {
      // If you opted-in for the New Architecture, we enable Concurrent Root (i.e. React 18).
      // More on this on https://reactjs.org/blog/2022/03/29/react-v18.html
      return BuildConfig.IS_NEW_ARCHITECTURE_ENABLED;
    }
  }
}
