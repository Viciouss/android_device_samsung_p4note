/*
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.p4note.keyhandler;

import android.app.ActivityManager;
import android.app.KeyguardManager;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.UserHandle;
import android.provider.Settings;
import android.util.Log;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;

/**
 * Handles the keyboard dock keys that have no AOSP keycode or no useful AOSP
 * behaviour. Loaded into system_server by PhoneWindowManager through
 * config_deviceKeyHandlerLibs/config_deviceKeyHandlerClasses.
 *
 * Runs on the input path, so actions are posted to the main looper.
 */
public class KeyHandler implements DeviceKeyHandler {
    private static final String TAG = "P4noteKeyHandler";

    /*
     * Show/hide keyboard key of the keyboard dock (KEY_F17, SIP_ON_OFF in the
     * stock firmware). It is not in sec_keyboard.kl, so it arrives as
     * KEYCODE_UNKNOWN with only the scancode set.
     */
    private static final int SCANCODE_TOGGLE_IME = 187;

    /*
     * Launcher3 opens all apps with the search field focused on this action,
     * and closes it again if all apps is already open.
     */
    private static final String ACTION_ALL_APPS_TOGGLE =
            "launcher.intent_action_all_apps_toggle";

    private final Context mContext;
    private final Handler mHandler;
    private final PowerManager mPowerManager;
    private final KeyguardManager mKeyguardManager;

    public KeyHandler(Context context) {
        mContext = context;
        mHandler = new Handler(Looper.getMainLooper());
        mPowerManager = context.getSystemService(PowerManager.class);
        mKeyguardManager = context.getSystemService(KeyguardManager.class);
    }

    @Override
    public KeyEvent handleKeyEvent(KeyEvent event) {
        final Runnable action;

        if (event.getKeyCode() == KeyEvent.KEYCODE_UNKNOWN
                && event.getScanCode() == SCANCODE_TOGGLE_IME) {
            action = this::toggleImeWithHardKeyboard;
        } else if (event.getKeyCode() == KeyEvent.KEYCODE_SEARCH) {
            // Leave the key alone where the launcher can't be shown.
            if (!mPowerManager.isInteractive() || mKeyguardManager.isKeyguardLocked()) {
                return event;
            }
            action = this::toggleAllApps;
        } else {
            return event;
        }

        // Consume both down and up, act once per press.
        if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            mHandler.post(action);
        }
        return null;
    }

    /* Flips "Show on-screen keyboard" of the physical keyboard settings. */
    private void toggleImeWithHardKeyboard() {
        final ContentResolver resolver = mContext.getContentResolver();
        final boolean show = Settings.Secure.getIntForUser(resolver,
                Settings.Secure.SHOW_IME_WITH_HARD_KEYBOARD, 0,
                UserHandle.USER_CURRENT) != 0;

        Settings.Secure.putIntForUser(resolver,
                Settings.Secure.SHOW_IME_WITH_HARD_KEYBOARD, show ? 0 : 1,
                UserHandle.USER_CURRENT);
    }

    /* Sends the all apps toggle to the current home app, like Quickstep does. */
    private void toggleAllApps() {
        final Intent homeIntent = new Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME);
        final ResolveInfo home = mContext.getPackageManager().resolveActivityAsUser(
                homeIntent, PackageManager.MATCH_DEFAULT_ONLY,
                ActivityManager.getCurrentUser());
        if (home == null || home.activityInfo == null) {
            Log.w(TAG, "No home activity to open all apps in");
            return;
        }

        final Intent intent = homeIntent
                .setAction(ACTION_ALL_APPS_TOGGLE)
                .setComponent(new ComponentName(home.activityInfo.packageName,
                        home.activityInfo.name))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            mContext.startActivityAsUser(intent, UserHandle.CURRENT);
        } catch (ActivityNotFoundException e) {
            Log.w(TAG, "Could not open all apps", e);
        }
    }
}
