# Agora's native RTC engine reaches back into these classes via JNI by
# name — R8 must not rename or strip them, or voice calls silently break
# in release builds despite compiling/installing fine. Per Agora's own
# guidance: https://docs.agora.io (Android release build setup).
-keep class io.agora.** { *; }
-dontwarn io.agora.**
