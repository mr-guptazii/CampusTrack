# Firebase / Firestore model classes are accessed via reflection-free plain
# Dart JSON mapping, so no keep rules are required for models. Keep rules
# below cover the plugins that do rely on reflection.

-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
