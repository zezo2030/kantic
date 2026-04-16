# Add project-specific ProGuard rules that keep Flutter and plugin entry
# points intact. For more details, see:
# https://developer.android.com/studio/build/shrink-code

# Flutter dependencies
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Preserve classes referenced by reflection or dynamic loading.
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler
-keep class * extends io.flutter.plugin.common.EventChannel$StreamHandler

# Ignore Play Core classes that Flutter references but we don't use
-dontwarn com.google.android.play.core.**

# Suppress optional runtime classes referenced by transitive libraries.
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.bouncycastle.jsse.BCSSLParameters
-dontwarn org.bouncycastle.jsse.BCSSLSocket
-dontwarn org.bouncycastle.jsse.provider.BouncyCastleJsseProvider
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# Uncomment to enable more verbose R8 diagnostics during troubleshooting.
#-printusage build/outputs/mapping/usage.txt
#-whyareyoukeeping class android.support.v7.app.AppCompatActivity

