package ci.agnebytiassa.tourisme;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Base64;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.ScaleAnimation;
import android.widget.ImageView;

public class SplashActivity extends Activity {

    private static final long SPLASH_DURATION_MS = 1900L;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        ImageView logo = findViewById(R.id.splashLogo);
        try {
            byte[] decoded = Base64.decode(LogoData.BASE64, Base64.DEFAULT);
            Bitmap bitmap = BitmapFactory.decodeByteArray(decoded, 0, decoded.length);
            logo.setImageBitmap(bitmap);
        } catch (Exception ignored) {
            logo.setImageResource(R.drawable.ic_app_symbol);
        }

        ScaleAnimation scale = new ScaleAnimation(
                0.88f, 1.0f, 0.88f, 1.0f,
                Animation.RELATIVE_TO_SELF, 0.5f,
                Animation.RELATIVE_TO_SELF, 0.5f
        );
        scale.setDuration(750L);
        scale.setFillAfter(true);
        logo.startAnimation(scale);

        AlphaAnimation fade = new AlphaAnimation(0.35f, 1.0f);
        fade.setDuration(850L);
        findViewById(android.R.id.content).startAnimation(fade);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            startActivity(new Intent(SplashActivity.this, MainActivity.class));
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
            finish();
        }, SPLASH_DURATION_MS);
    }
}
