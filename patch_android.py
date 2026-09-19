"""CI helper: inject permissions + core desugaring into fresh flutter-create output.

Desugaring is APPENDED as extra blocks (Gradle merges duplicate blocks),
so it works regardless of template formatting — no fragile regex.
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

# flutter_local_notifications v17+ needs core library desugaring.
groovy = pathlib.Path('android/app/build.gradle')
kts = pathlib.Path('android/app/build.gradle.kts')
if kts.exists():
    s = kts.read_text()
    if 'desugar_jdk_libs' not in s:
        with kts.open('a') as f:
            f.write(
                '\n// HydroBuddy: core desugaring for flutter_local_notifications\n'
                'android {\n'
                '    compileOptions {\n'
                '        isCoreLibraryDesugaringEnabled = true\n'
                '    }\n'
                '}\n'
                'dependencies {\n'
                '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
                '}\n'
            )
        print('desugaring appended to build.gradle.kts')
    else:
        print('kts already has desugaring')
elif groovy.exists():
    s = groovy.read_text()
    if 'desugar_jdk_libs' not in s:
        with groovy.open('a') as f:
            f.write(
                '\n// HydroBuddy: core desugaring for flutter_local_notifications\n'
                'android {\n'
                '    compileOptions {\n'
                '        coreLibraryDesugaringEnabled true\n'
                '    }\n'
                '}\n'
                'dependencies {\n'
                "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
                '}\n'
            )
        print('desugaring appended to build.gradle')
    else:
        print('groovy already has desugaring')
else:
    print('WARNING: no app build file found')
