# flutter_local_notifications stores scheduled notifications as JSON via Gson,
# which needs generic type info and the model classes kept under R8.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Play Core is referenced by Flutter's deferred components but not used.
-dontwarn com.google.android.play.core.**
