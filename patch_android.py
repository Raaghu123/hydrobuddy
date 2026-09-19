"""CI helper: inject permissions into fresh flutter-create output.

NOTE: desugaring intentionally NOT enabled — we pin
flutter_local_notifications to v16 which doesn't need it.
"""
import pathlib

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
if not m.exists():
    print('manifest missing, skipping (run flutter create first)')
    raise SystemExit(0)
t = m.read_text()
perms = (
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
    '    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>\n'
    '    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>\n'
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
    '    <uses-permission android:name="android.permission.VIBRATE"/>\n'
    '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'
    '    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>\n'
    '    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>\n'
)
if 'POST_NOTIFICATIONS' not in t:
    t = t.replace('<application', perms + '<application', 1)
    m.write_text(t)
    print('permissions injected')
else:
    print('permissions already present')
