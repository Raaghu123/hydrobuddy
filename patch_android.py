"""CI helper: inject permissions + core desugaring into fresh flutter-create output."""
import pathlib
import re

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

for name in ['android/app/build.gradle', 'android/app/build.gradle.kts']:
    p = pathlib.Path(name)
    if not p.exists():
        continue
    s = p.read_text()
    if 'desugar_jdk_libs' in s:
        print(name, 'already has desugaring')
        continue
    if name.endswith('.kts'):
        if 'isCoreLibraryDesugaringEnabled' not in s:
            s, n = re.subn(
                r'(sourceCompatibility\s*=\s*JavaVersion\.VERSION_\S+)',
                r'\1\n        isCoreLibraryDesugaringEnabled = true',
                s, count=1)
            print('flag added:', n)
        s, n = re.subn(
            r'(dependencies\s*\{)',
            r'\1\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
            s, count=1)
        print('dep added:', n)
    else:
        if 'coreLibraryDesugaringEnabled' not in s:
            s, n = re.subn(
                r'(sourceCompatibility\s+JavaVersion\.VERSION_\S+)',
                r'\1\n        coreLibraryDesugaringEnabled true',
                s, count=1)
            print('flag added:', n)
        s, n = re.subn(
            r'(dependencies\s*\{)',
            r"\1\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'",
            s, count=1)
        print('dep added:', n)
    p.write_text(s)
